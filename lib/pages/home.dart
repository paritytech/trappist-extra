import 'package:flutter/material.dart';
import 'package:trappist_extra/models/chain.dart';
import 'package:trappist_extra/pages/status.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  final String title;

  const HomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(title),
            titleTextStyle: Theme.of(context)
                .textTheme
                .titleLarge!
                .copyWith(color: Colors.white, fontFamily: 'Syncopate-Bold')),
        body: Center(
            child: Consumer<Chains>(
                builder: (context, chains, child) => const ChainSyncStatus())),
        drawer: Drawer(
            child: TextButtonTheme(
                data: TextButtonThemeData(
                  style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.zero,
                      foregroundColor: Colors.grey.shade300),
                ),
                child: ListView(padding: EdgeInsets.zero, children: [
                  SizedBox(
                      height: MediaQuery.of(context).padding.top +
                          kToolbarHeight +
                          8,
                      child: DrawerHeader(
                        decoration: const BoxDecoration(
                          color: Colors.pink,
                        ),
                        child: Text('Chains',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(
                                    color: Colors.white,
                                    fontFamily: 'Syncopate-Bold')),
                      )),
                  // Add configured chains from provider
                  ...context.read<Chains>().chains.map((e) => ExpansionTile(
                        title: TextButton.icon(
                          icon: e.logo,
                          label: Text(e.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                      color: Colors.black,
                                      fontFamily: 'Syncopate-Bold')),
                          onPressed: () async {
                            // Select the chain
                            await context.read<Chains>().select(e);
                            // Then close the drawer
                            Navigator.pop(context);
                          },
                        ),
                        initiallyExpanded: true,
                        children: e.parachains
                            .map((e) => ListTile(
                                  leading: e.logo,
                                  title: Text(e.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(
                                              color: Colors.black,
                                              fontFamily: 'Syncopate-Bold')),
                                  contentPadding:
                                      const EdgeInsets.only(left: 25),
                                  onTap: () async {
                                    // Select the chain
                                    await context.read<Chains>().select(e);
                                    // Then close the drawer
                                    Navigator.pop(context);
                                  },
                                ))
                            .toList(),
                      ))
                ]))));
  }
}
