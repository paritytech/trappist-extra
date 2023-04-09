import 'dart:async';
import 'dart:convert';
import 'package:deep_pick/deep_pick.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../ffi.dart';

class Chains extends ChangeNotifier {
  late Chain selected;
  final List<RelayChain> chains;

  Chains(this.chains) {
    // Initialise logging
    debugPrint('[Chain] api.initLogger');
    api.initLogger().listen((event) {
      debugPrint(
          '${event.level} [${event.tag}]: ${event.msg}(rust_time=${event.timeMillis})');
    });
    // Initialise light client
    debugPrint('[Chain] api.initLightClient');
    api.initLightClient();
    // Start current chain sync automatically
    selected = chains.first;
    selected.startSync();
  }

  // Selects the supplied chain.
  select(Chain chain) async {
    if (chain == selected) {
      return;
    }
    // Stop sync of current chain
    await selected.stopSync();
    // Start sync of selected chain
    selected = chain;
    await selected.startSync();
    notifyListeners();
  }
}

abstract class Chain extends ChangeNotifier {
  String _chainSpec;
  int? _currentBlock;
  Timer? _health;
  bool _initialised = false;
  int _lastDbSnapshot = 0;
  int _peers = 0;
  Stream<String>? _stream;
  StreamSubscription<String>? _streamSubscription;

  final String name;
  final Widget logo;

  static final Future<SharedPreferences> _sharedPreferences =
      SharedPreferences.getInstance();

  Chain(this.name, this._chainSpec, this.logo);

  set currentBlock(int? currentBlock) {
    _currentBlock = currentBlock;
    notifyListeners();
  }

  int? get currentBlock {
    return _currentBlock;
  }

  int get lastDbSnapshot {
    return _lastDbSnapshot;
  }

  set peers(int? peers) {
    if (peers != null && peers != _peers) {
      _peers = peers;
      notifyListeners();
    }
  }

  int get peers {
    return _peers;
  }

  Stream<String>? get stream {
    return _stream;
  }

  startSync() async {
    debugPrint('[Chain] start: $name');

    if (!_initialised) {
      // Initialise chain spec
      debugPrint('[Chain] loading chain spec: $name');
      _chainSpec = await rootBundle.loadString(_chainSpec);
      _initialised = true;
    }

    // Start chain sync
    debugPrint('[Chain] api.startChainSync: $name');
    var database = (await _sharedPreferences).getString(name);
    await _startChainSync(database);

    // Subscribe to best header
    debugPrint('[Chain] api.sendJsonRpcRequest: $name');
    await api.sendJsonRpcRequest(
        chainName: name,
        req:
            "{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"chain_subscribeNewHeads\",\"params\":[]}");

    debugPrint('[Chain] api.listenJsonRpcResponses: $name');
    _stream = api.listenJsonRpcResponses(chainName: name).asBroadcastStream();

    // Subscribe to broadcast stream internally to track state updates
    _streamSubscription = _stream!.listen((response) async {
      _processResponse(response);
    });

    // Start periodic health check
    _health = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkHealth();
    });
  }

  _startChainSync(String? database) async {
    await api.startChainSync(
        chainName: name, chainSpec: _chainSpec, database: database ?? "");
  }

  _checkHealth() async {
    await api.sendJsonRpcRequest(
        chainName: name,
        req:
            "{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"system_health\",\"params\":[]}");
  }

  _processResponse(String response) async {
    final decodedData = jsonDecode(response);
    final id = pick(decodedData, 'id').asIntOrNull();
    final method = pick(decodedData, 'method').asStringOrNull();
    switch (method) {
      case "chain_newHead":
        final int? block =
            pick(decodedData, 'params', 'result', 'number').asIntOrNull();
        if (block != null) {
          if ((block - _lastDbSnapshot) >= 10) {
            await api.sendJsonRpcRequest(
                chainName: name,
                req:
                    "{\"id\":2,\"jsonrpc\":\"2.0\",\"method\":\"chainHead_unstable_finalizedDatabase\",\"params\":[]}");
            _lastDbSnapshot = block;
            currentBlock = block;
          } else {
            currentBlock = block;
          }

          // Manually set first peer (as block received) until periodic health check
          if (peers == 0) {
            peers = 1;
          }
        }
        break;
      default:
        switch (id) {
          case 1:
            {
              peers = pick(decodedData, 'result', 'peers').asIntOrNull();
              break;
            }
          case 2:
            {
              // Handle chainHead_unstable_finalizedDatabase result
              final String? database =
                  pick(decodedData, 'result').asStringOrNull();
              if (database != null) {
                debugPrint('[Chain] Saving $name database');
                (await _sharedPreferences).setString(name, database);
              }
            }
        }
    }
  }

  stopSync() async {
    debugPrint('[Chain] api.stopChainSync: $name');
    await api.stopChainSync(chainName: name);
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _lastDbSnapshot = 0;
    currentBlock = null;
    _health?.cancel();
    _health = null;
    _peers = 0;
  }

  @override
  void dispose() {
    if (_streamSubscription != null) {
      debugPrint('[Chain] dispose: $_streamSubscription');
      _streamSubscription?.cancel();
      _streamSubscription = null;
    }
    super.dispose();
  }
}

class RelayChain extends Chain {
  late List<Parachain> parachains;

  RelayChain(String name, String chainSpec, Widget logo)
      : super(name, chainSpec, logo) {
    parachains = List.empty(growable: true);
  }

  RelayChain addParachain(String name, String chainSpec, Widget logo) {
    parachains.add(Parachain(name, chainSpec, logo, this));
    return this;
  }
}

class Parachain extends Chain {
  final RelayChain relayChain;

  Parachain(String name, String chainSpec, Widget logo, this.relayChain)
      : super(name, chainSpec, logo) {
    relayChain.addListener(() => notifyListeners());
  }

  @override
  _startChainSync(String? database) async {
    // Ensure relay chain sync started
    await relayChain.startSync();
    // Start parachain sync
    await api.startChainSync(
        chainName: name,
        chainSpec: _chainSpec,
        database: database ?? "",
        relayChain: relayChain.name);
  }

  @override
  stopSync() async {
    // Stop relay/parachain sync
    await super.stopSync();
    await relayChain.stopSync();
  }
}
