use anyhow::{anyhow, Context};
use core::iter;
use flutter_rust_bridge::StreamSink;
use lazy_static::lazy_static;
use log::debug;
use parking_lot::RwLock;
use smoldot_light::*;
use std::{collections::HashMap, sync::Mutex};

use crate::logger;

// Inspired by https://github.com/paritytech/smoldot/blob/5b30f5e4c4f677f7c8ff4188c0440789ba3c1adb/bin/wasm-node/rust/src/lib.rs
lazy_static! {
    static ref CLIENT: Mutex<Option<smoldot_light::Client<smoldot_light::platform::async_std::AsyncStdTcpWebSocket>>> =
        Mutex::new(None);
    static ref CHAINS: RwLock<HashMap<String, ChainInfo>> = RwLock::new(HashMap::new());
    static ref RPC_RESPONSE_STREAMS: RwLock<HashMap<String, JsonRpcResponses>> =
        RwLock::new(HashMap::new());
}

pub struct LogEntry {
    pub time_millis: i64,
    pub level: i32,
    pub tag: String,
    pub msg: String,
}

struct ChainInfo {
    pub chain_id: ChainId,
    // pub rpc_responses: JsonRpcResponses,
}

pub fn init_logger(log_stream_sink: StreamSink<LogEntry>) -> anyhow::Result<()> {
    // The `smoldot_light` library uses the `log` crate to emit logs.
    // We need to register some kind of logs listener, in this example `env_logger`.
    // See also <https://docs.rs/log>.
    logger::init_logger();
    logger::SendToDartLogger::set_stream_sink(log_stream_sink);
    Ok(())
}

pub fn init_light_client() -> anyhow::Result<()> {
    let mut client_lock = CLIENT.lock().unwrap();
    assert!(client_lock.is_none());

    // Initialize the client. This does nothing except allocate resources.
    // The `Client` struct requires a generic parameter that provides platform bindings. In this
    // example, we provide `AsyncStdTcpWebSocket`, which are the "plug and play" default platform.
    let client =
        smoldot_light::Client::<smoldot_light::platform::async_std::AsyncStdTcpWebSocket>::new(
            smoldot_light::ClientConfig {
                // The smoldot client will need to spawn tasks that run in the background. In order to do
                // so, we need to provide a "tasks spawner".
                tasks_spawner: Box::new(move |_name, task| {
                    async_std::task::spawn(task);
                }),
                system_name: env!("CARGO_PKG_NAME").into(),
                system_version: env!("CARGO_PKG_VERSION").into(),
            },
        );

    *client_lock = Some(client);

    Ok(())
}

pub fn start_chain_sync(chain_name: String, chain_spec: String) -> anyhow::Result<()> {
    let mut client_lock = CLIENT.lock().unwrap();
    assert!(client_lock.is_some());

    let client = client_lock.as_mut().unwrap();

    // Ask the client to connect to a chain.
    let smoldot_light::AddChainSuccess {
        chain_id,
        json_rpc_responses,
    } = client
        .add_chain(smoldot_light::AddChainConfig {
            // The most important field of the configuration is the chain specification. This is a
            // JSON document containing all the information necessary for the client to connect to said
            // chain.
            specification: &chain_spec,

            // If `true`, the chain will not be able to handle JSON-RPC requests. This can be used
            // to save up some resources.
            disable_json_rpc: false,

            // This field is necessary only if adding a parachain.
            potential_relay_chains: iter::empty(),

            // After a chain has been added, it is possible to extract a "database" (in the form of a
            // simple string). This database can later be passed back the next time the same chain is
            // added again.
            // A database with an invalid format is simply ignored by the client.
            // In this example, we don't use this feature, and as such we simply pass an empty string,
            // which is intentionally an invalid database content.
            database_content: "",

            // The client gives the possibility to insert an opaque "user data" alongside each chain.
            // This avoids having to create a separate `HashMap<ChainId, ...>` in parallel of the
            // client.
            // In this example, this feature isn't used. The chain simply has `()`.
            user_data: (),
        })
        .map_err(anyhow::Error::msg)
        .with_context(|| format!("Failed to start syncing chain '{:?}'.", chain_name))?;

    // The chain is now properly initialized.

    // `json_rpc_responses` can only be `None` if we had passed `disable_json_rpc: true` in the
    // configuration.
    let rpc_responses = json_rpc_responses.unwrap();

    let mut chains_guard = CHAINS.write();
    chains_guard.insert(chain_name.clone(), ChainInfo { chain_id });

    let mut rpc_response_streams_guard = RPC_RESPONSE_STREAMS.write();
    rpc_response_streams_guard.insert(chain_name, rpc_responses);

    Ok(())
}

pub fn stop_chain_sync(chain_name: String) -> anyhow::Result<()> {
    let chains_guard = CHAINS.upgradable_read();
    if !chains_guard.contains_key(&chain_name) {
        return Err(anyhow!("Unknown chain '{:?}'.", chain_name));
    }

    let mut client_lock = CLIENT.lock().unwrap();
    assert!(client_lock.is_some());
    let client = client_lock.as_mut().unwrap();

    // Upgrade read lock to write lock
    let mut chains_write_guard =
        parking_lot::lock_api::RwLockUpgradableReadGuard::<'_, _, _>::upgrade(chains_guard);
    if let Some(ChainInfo { chain_id: id, .. }) = chains_write_guard.remove(&chain_name) {
        // This should end the JSON-RPC response stream
        let _: () = client.remove_chain(id);

        let mut rpc_response_streams_guard = RPC_RESPONSE_STREAMS.write();
        rpc_response_streams_guard.remove(&chain_name);
    }
    Ok(())
}

pub fn send_json_rpc_request(chain_name: String, req: String) -> anyhow::Result<()> {
    let chains_guard = CHAINS.read();
    if let Some(ChainInfo { chain_id: id, .. }) = chains_guard.get(&chain_name) {
        // Send a JSON-RPC request to the chain.
        // Calling this function only queues the request. It is not processed immediately.
        // An `Err` is returned immediately if and only if the request isn't a proper JSON-RPC request
        // or if the channel of JSON-RPC responses is clogged.
        let mut client_lock = CLIENT.lock().unwrap();
        assert!(client_lock.is_some());
        let client = client_lock.as_mut().unwrap();

        client
            .json_rpc_request(req, *id)
            .map_err(anyhow::Error::msg)
            .with_context(|| {
                format!(
                    "Failed to enqueue JSON-RPC request to chain '{:?}'.",
                    chain_name
                )
            })?;
        Ok(())
    } else {
        Err(anyhow!("Unknown chain '{:?}'.", chain_name))
    }
}

pub fn listen_json_rpc_responses(
    chain_name: String,
    rpc_responses_sink: StreamSink<String>,
) -> anyhow::Result<()> {
    let mut rpc_response_streams_guard = RPC_RESPONSE_STREAMS.write();
    if let Some(rpc_responses) = rpc_response_streams_guard.get_mut(&chain_name) {
        // Spawn an async task and block thread and forward responses received on the channel of JSON-RPC responses
        // to the response stream sink (towards the Dart side).
        async_std::task::block_on(async move {
            while let Some(response) = rpc_responses.next().await {
                debug!(
                    "JSON-RPC response for chain '{:?}': {}",
                    chain_name, response
                );
                rpc_responses_sink.add(response);
            }
            debug!(
                "JSON-RPC response stream for chain '{:?}' has ended.",
                chain_name
            );
            Ok(())
        })
    } else {
        Err(anyhow!("Unknown chain '{:?}'.", chain_name))
    }
}
