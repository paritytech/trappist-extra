use anyhow::Context;
use core::iter;
use flutter_rust_bridge::StreamSink;
use lazy_static::lazy_static;
use log::debug;
use parking_lot::RwLock;
use std::sync::Mutex;

use crate::logger;

pub struct LogEntry {
    pub time_millis: i64,
    pub level: i32,
    pub tag: String,
    pub msg: String,
}

pub fn init_logger(log_stream_sink: StreamSink<LogEntry>) -> anyhow::Result<()> {
    // The `smoldot_light` library uses the `log` crate to emit logs.
    // We need to register some kind of logs listener, in this example `env_logger`.
    // See also <https://docs.rs/log>.
    logger::init_logger();
    logger::SendToDartLogger::set_stream_sink(log_stream_sink);
    Ok(())
}

// Inspired by https://github.com/paritytech/smoldot/blob/5b30f5e4c4f677f7c8ff4188c0440789ba3c1adb/bin/wasm-node/rust/src/lib.rs
lazy_static! {
    static ref CLIENT: Mutex<Option<smoldot_light::Client<smoldot_light::platform::async_std::AsyncStdTcpWebSocket>>> =
        Mutex::new(None);
    static ref JSON_RPC_RESPONSE_STREAM_SINK: RwLock<Option<StreamSink<String>>> =
        RwLock::new(None);
}

pub fn init_light_client() -> anyhow::Result<()> {
    let mut client_lock = CLIENT.lock().unwrap();
    assert!(client_lock.is_none());

    // Initialize the client. This does nothing except allocate resources.
    // The `Client` struct requires a generic parameter that provides platform bindings. In this
    // example, we provide `AsyncStdTcpWebSocket`, which are the "plug and play" default platform.
    // Any advance usage, such as embedding a client in WebAssembly, will likely require a custom
    // implementation of these bindings.
    let mut client = smoldot_light::Client::<
        smoldot_light::platform::async_std::AsyncStdTcpWebSocket,
    >::new(smoldot_light::ClientConfig {
        // The smoldot client will need to spawn tasks that run in the background. In order to do
        // so, we need to provide a "tasks spawner".
        tasks_spawner: Box::new(move |_name, task| {
            async_std::task::spawn(task);
        }),
        system_name: env!("CARGO_PKG_NAME").into(),
        system_version: env!("CARGO_PKG_VERSION").into(),
    });

    // Ask the client to connect to a chain.
    let smoldot_light::AddChainSuccess {
        chain_id: _chain_id,
        json_rpc_responses,
    } = client
        .add_chain(smoldot_light::AddChainConfig {
            // The most important field of the configuration is the chain specification. This is a
            // JSON document containing all the information necessary for the client to connect to said
            // chain.
            specification: include_str!("../polkadot.json"),

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
        .unwrap();

    // The chain is now properly initialized.

    // `json_rpc_responses` can only be `None` if we had passed `disable_json_rpc: true` in the
    // configuration.
    let mut json_rpc_responses = json_rpc_responses.unwrap();

    *client_lock = Some(client);
    drop(client_lock);

    // Now block the execution forever and forward responses received on the channel of JSON-RPC responses
    // to the registered (if any) response stream sink (towards the Dart side).
    async_std::task::block_on(async move {
        loop {
            let response = json_rpc_responses.next().await.unwrap();
            debug!("JSON-RPC response: {}", response);
            if let Some(sink) = &*JSON_RPC_RESPONSE_STREAM_SINK.read() {
                sink.add(response);
            }
        }
    })
}

pub fn json_rpc_send(chain_id: usize, req: String) -> anyhow::Result<()> {
    // Send a JSON-RPC request to the chain.
    // The example here asks the client to send us notifications whenever the new best block has
    // changed.
    // Calling this function only queues the request. It is not processed immediately.
    // An `Err` is returned immediately if and only if the request isn't a proper JSON-RPC request
    // or if the channel of JSON-RPC responses is clogged.
    let mut client_lock = CLIENT.lock().unwrap();
    assert!(client_lock.is_some());

    let client = client_lock.as_mut().unwrap();
    client
        .json_rpc_request(req, chain_id.into())
        .map_err(|e| anyhow::Error::msg(e))
        .with_context(|| {
            format!(
                "Failed to enqueue JSON-RPC request to chain with ID {}.",
                chain_id
            )
        })
}

pub fn set_json_rpc_response_sink(
    json_rpc_response_stream_sink: StreamSink<String>,
) -> anyhow::Result<()> {
    let mut response_stream_sink_guard = JSON_RPC_RESPONSE_STREAM_SINK.write();
    assert!(response_stream_sink_guard.is_none());

    *response_stream_sink_guard = Some(json_rpc_response_stream_sink);

    Ok(())
}

pub fn add(left: usize, right: usize) -> usize {
    left + right
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        let result = add(2, 2);
        assert_eq!(result, 4);
    }
}
