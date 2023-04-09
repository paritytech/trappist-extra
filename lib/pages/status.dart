import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trappist_extra/models/chain.dart';
import 'package:blinking_text/blinking_text.dart';
import 'package:intl/intl.dart';

class ChainSyncStatus extends StatelessWidget {
  static final NumberFormat _numberFormat = NumberFormat.decimalPattern();

  const ChainSyncStatus({super.key});

  @override
  Widget build(BuildContext context) {
    var chain = context.watch<Chains>().selected;
    return ChangeNotifierProvider.value(
        value: chain,
        child: Consumer<Chain>(
            builder: (context, chain, child) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: buildChain(context, chain))));
  }

  List<Widget> buildChain(BuildContext context, Chain chain) {
    if (chain is Parachain) {
      return <Widget>[
        // Relay chain
        const Text('Relay Chain:'),
        Text(chain.relayChain.name,
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(color: Colors.black, fontFamily: 'Syncopate-Bold')),
        const SizedBox(height: 10),
        if (chain.relayChain.currentBlock != null) ...[
          const Text(
            'Best block:',
          ),
          Text(
            _numberFormat.format(chain.relayChain.currentBlock ?? 0),
            style: Theme.of(context)
                .textTheme
                .displaySmall!
                .copyWith(color: Colors.black, fontFamily: 'Syncopate-Bold'),
          ),
        ] else ...[
          const BlinkText('Syncing', duration: Duration(seconds: 1)),
        ],
        const SizedBox(height: 10),
        ...buildPeers(context, chain.relayChain),
        const SizedBox(height: 50),
        // Parachain
        const Text('Parachain:'),
        Text(chain.name,
            style: Theme.of(context)
                .textTheme
                .titleLarge!
                .copyWith(color: Colors.black, fontFamily: 'Syncopate-Bold')),
        const SizedBox(height: 10),
        if (chain.currentBlock != null) ...[
          const Text(
            'Best block:',
          ),
          Text(
            _numberFormat.format(chain.currentBlock ?? 0),
            style: Theme.of(context)
                .textTheme
                .displaySmall!
                .copyWith(color: Colors.black, fontFamily: 'Syncopate-Bold'),
          ),
        ] else ...[
          const BlinkText('Syncing', duration: Duration(seconds: 1)),
        ],
        const SizedBox(height: 10),
        ...buildPeers(context, chain)
      ];
    }

    return <Widget>[
      const Text('Chain:'),
      Text(chain.name,
          style: Theme.of(context)
              .textTheme
              .titleLarge!
              .copyWith(color: Colors.black, fontFamily: 'Syncopate-Bold')),
      const SizedBox(height: 20),
      if (chain.currentBlock != null) ...[
        const Text(
          'Best block:',
        ),
        Text(
          _numberFormat.format(chain.currentBlock ?? 0),
          style: Theme.of(context)
              .textTheme
              .displaySmall!
              .copyWith(color: Colors.black, fontFamily: 'Syncopate-Bold'),
        ),
      ] else ...[
        const BlinkText('Syncing', duration: Duration(seconds: 1)),
      ],
      const SizedBox(height: 20),
      ...buildPeers(context, chain)
    ];
  }

  List<Widget> buildPeers(BuildContext context, Chain chain) {
    return <Widget>[
      const Text('Peers:'),
      Text(chain.peers.toString(),
          style: Theme.of(context)
              .textTheme
              .titleLarge!
              .copyWith(color: Colors.black, fontFamily: 'Syncopate-Bold')),
    ];
  }
}
