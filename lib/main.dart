import 'package:flutter/material.dart';
import 'ffi.dart';
import 'dart:convert';
import 'package:deep_pick/deep_pick.dart';
import 'package:blinking_text/blinking_text.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trappist Extra',
      theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.pink,
          fontFamily: 'Syncopate'),
      home: const MyHomePage(title: 'Trappist Extra'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future client_init;
  int? _block = null;
  NumberFormat _numberFormat = NumberFormat.decimalPattern();

  @override
  void initState() {
    super.initState();
    api.initLogger().listen((event) {
      debugPrint(
          '${event.level} [${event.tag}]: ${event.msg}(rust_time=${event.timeMillis})');
    });
    api.setJsonRpcResponseSink().listen((response) {
      final decodedData = jsonDecode(response);
      final int? number =
          pick(decodedData, 'params', 'result', 'number').asIntOrNull();
      if (number != null) {
        setState(() {
          _block = number;
        });
      }
      debugPrint('JSON-RPC response: $response');
    });
    client_init = api.initLightClient();
    api.jsonRpcSend(
        chainId: 0,
        req:
            "{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"chain_subscribeNewHeads\",\"params\":[]}");
  }

  Future<void> _incrementCounter() async {
    // int result = await api.add(left: _counter, right: 1);
    // setState(() {
    //   // This call to setState tells the Flutter framework that something has
    //   // changed in this State, which causes it to rerun the build method below
    //   // so that the display can reflect the updated values. If we changed
    //   // _counter without calling setState(), then the build method would not be
    //   // called again, and so nothing would appear to happen.
    //   _counter = result;
    // });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
          titleTextStyle: Theme.of(context)
              .textTheme
              .headline6!
              .copyWith(color: Colors.white, fontFamily: 'Syncopate-Bold')),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Chain:'),
            Text('Polkadot',
                style: Theme.of(context).textTheme.headline6!.copyWith(
                    color: Colors.black, fontFamily: 'Syncopate-Bold')),
            const SizedBox(height: 20),
            if (_block != null) ...[
              const Text(
                'Best block:',
              ),
              Text(
                _numberFormat.format(_block),
                style: Theme.of(context).textTheme.headline2!.copyWith(
                    color: Colors.black, fontFamily: 'Syncopate-Bold'),
              ),
            ] else ...[
              const BlinkText('Syncing', duration: Duration(seconds: 1)),
            ],
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 64.0,
              child: DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.pink,
                ),
                child: Text('Chains',
                    style: Theme.of(context).textTheme.headline6!.copyWith(
                        color: Colors.white, fontFamily: 'Syncopate-Bold')),
              ),
            ),
            ListTile(
              leading: const FlutterLogo(),
              title: const Text('Polkadot'),
              onTap: () {
                // Update the state of the app
                // ...
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const FlutterLogo(),
              title: const Text('Statemint'),
              onTap: () {
                // Update the state of the app
                // ...
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
