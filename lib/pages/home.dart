import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ffi.dart';
import 'dart:convert';
import 'package:vector_graphics/vector_graphics.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:blinking_text/blinking_text.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? currentChain;
  int? currentBlock;
  int lastDbSnapshot = 0;
  final NumberFormat _numberFormat = NumberFormat.decimalPattern();
  StreamSubscription<String>? responseSub$;
  SharedPreferences? sharedPreferences;

  @override
  void initState() {
    super.initState();

    debugPrint('[HomePage] api.initLogger');
    api.initLogger().listen((event) {
      debugPrint(
          '${event.level} [${event.tag}]: ${event.msg}(rust_time=${event.timeMillis})');
    });
    debugPrint('[HomePage] api.initLightClient');
    api.initLightClient();

    onChainSelected("polkadot");
  }

  @override
  void dispose() {
    debugPrint('[HomePage] dispose: ${responseSub$}');
    responseSub$?.cancel();
    responseSub$ = null;
    super.dispose();
  }

  void onChainSelected(String chainName) async {
    if (chainName.isEmpty) {
      return;
    }

    sharedPreferences ??= await SharedPreferences.getInstance();

    debugPrint('[HomePage] onChainSelected: $chainName');

    if (currentChain != null && currentChain!.isNotEmpty) {
      debugPrint('[HomePage] api.stopChainSync: $currentChain');
      await api.stopChainSync(chainName: currentChain!);
      responseSub$?.cancel();
      responseSub$ = null;
      currentChain = null;
      currentBlock = null;
      lastDbSnapshot = 0;
    }

    debugPrint('[HomePage] loading chainspec: $chainName');
    var sub = await rootBundle
        .loadString("assets/chainspecs/$chainName.json")
        .then((spec) async {
      debugPrint('[HomePage] api.startChainSync: $chainName');
      var database = sharedPreferences!.getString(chainName);
      await api.startChainSync(
          chainName: chainName, chainSpec: spec, database: database ?? "");

      debugPrint('[HomePage] api.sendJsonRpcRequest: $chainName');

      await api.sendJsonRpcRequest(
          chainName: chainName,
          req:
              "{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"chain_subscribeNewHeads\",\"params\":[]}");

      debugPrint('[HomePage] api.listenJsonRpcResponses: $chainName');
      return api
          .listenJsonRpcResponses(chainName: chainName)
          .listen((response) async {
        if (currentChain == null) {
          return;
        }

        final decodedData = jsonDecode(response);
        final id = pick(decodedData, 'id').asIntOrNull();
        final method = pick(decodedData, 'method').asStringOrNull();
        switch (method) {
          case "chain_newHead":
            final int? block =
                pick(decodedData, 'params', 'result', 'number').asIntOrNull();
            if (block != null) {
              if ((block - lastDbSnapshot) >= 10) {
                await api.sendJsonRpcRequest(
                    chainName: currentChain!,
                    req:
                        "{\"id\":2,\"jsonrpc\":\"2.0\",\"method\":\"chainHead_unstable_finalizedDatabase\",\"params\":[]}");
                setState(() {
                  currentBlock = block;
                  lastDbSnapshot = block;
                });
              } else {
                setState(() {
                  currentBlock = block;
                });
              }
            }
            break;
          default:
            if (id == 2) {
              // Handle chainHead_unstable_finalizedDatabase result
              final String? database =
                  pick(decodedData, 'result').asStringOrNull();
              if (database != null) {
                debugPrint('[HomePage] Saving $chainName database');
                sharedPreferences!.setString(currentChain!, database);
              }
            }
        }
      });
    });

    setState(() {
      currentChain = chainName;
      responseSub$ = sub;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.title),
          titleTextStyle: Theme.of(context)
              .textTheme
              .titleLarge!
              .copyWith(color: Colors.white, fontFamily: 'Syncopate-Bold')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Chain:'),
            Text(currentChain ?? 'No chain selected',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Colors.black, fontFamily: 'Syncopate-Bold')),
            const SizedBox(height: 20),
            if (currentBlock != null) ...[
              const Text(
                'Best block:',
              ),
              Text(
                _numberFormat.format(currentBlock ?? 0),
                style: Theme.of(context).textTheme.displaySmall!.copyWith(
                    color: Colors.black, fontFamily: 'Syncopate-Bold'),
              ),
            ] else ...[
              const BlinkText('Syncing', duration: Duration(seconds: 1)),
            ],
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              // height: Theme.of(context).platform == TargetPlatform.android
              //     ? 96
              //     : 64,
              height: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
              child: DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.pink,
                ),
                child: Text('Chains',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Colors.white, fontFamily: 'Syncopate-Bold')),
              ),
            ),
            ListTile(
              leading: const SvgPicture(
                AssetBytesLoader("assets/images/logos/polkadot.svg.vec"),
                semanticsLabel: 'Polkadot Logo',
                height: 42,
                width: 42,
                fit: BoxFit.fitWidth,
              ),
              title: Text('Polkadot',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Colors.black, fontFamily: 'Syncopate-Bold')),
              onTap: () {
                onChainSelected("polkadot");
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Image(
                image: AssetImage("assets/images/logos/kusama.png"),
                semanticLabel: 'Kusama Logo',
                height: 42,
                width: 42,
                fit: BoxFit.fitWidth,
              ),
              // const SvgPicture(
              //   AssetBytesLoader("assets/images/logos/kusama.png"),
              //   semanticsLabel: 'Kusama Logo',
              //   height: 42,
              //   width: 42,
              //   fit: BoxFit.fitWidth,
              // ),
              title: Text('Kusama',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Colors.black, fontFamily: 'Syncopate-Bold')),
              onTap: () {
                onChainSelected("kusama");
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
