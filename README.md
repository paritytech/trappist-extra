# Trappist Extra

![Trappist Extra](trappist-extra.png)

**Trappist Extra** is a sample mobile decentralized app that demonstrates the integration of a [light client node](https://www.parity.io/blog/introducing-substrate-connect), which enables the app to connect, quickly sync and interact with any [Substrate-based blockchains](https://github.com/paritytech/substrate/), including the [Polkadot Network](https://polkadot.network/), in a fully trustless and decentralized way.

The app is built with [Flutter](https://flutter.dev/), the multi-platform app development framework; [smoldot](https://github.com/paritytech/smoldot/), a cross-platform light client node implementation written in Rust; and the [flutter_rust_bridge](https://cjycode.com/flutter_rust_bridge/), a library and code generator which enable seamless integration of native rust code in a Flutter app.

### Why "Trappist Extra" ?

This project is related to the [Trappist](https://github.com/paritytech/trappist) project, a web3 developer playground built for experimenting with [cross-chain applications and services](https://polkadot.network/cross-chain-communication/) built on the technologies spearheaded by the [Polkadot Network](https://polkadot.network/).

The term **Trappist** refers to a [style of beers](https://en.wikipedia.org/wiki/Trappist_beer) brewed in Abbeys by Trappist monks, and is generally associated with authenticity, craftsmanship, integrity and tradition. Aside from any religious consideration, we like to think we put as much care in crafting Blockchain software as monks brewing high-quality beer 🍺.

The added **Extra** term (also named [Enkel, Single or Gold](https://en.wikipedia.org/wiki/Trappist_beer#Enkel)) is usually used by a brewery to describe its **lightest beer**. As this project is a showcase application for **light clients**, we found the name to be a natural fit.

As Trappist breweries are not intended to be profit-making ventures, this project is non-commercial, open-source software focused solely on experimentation and knowledge sharing with people interested in learning about decentralized technologies.

## Getting Started

### Rust Setup

First, complete the [basic Rust setup instructions](./docs/rust-setup.md). Then, follow the detailed instructions below.

### Platform setup

Depending on the device you want to deploy on either choose [Linux & Android on Linux](./docs/linux-instructions.md) or [macOS, iOS & Android on macOS](./docs/macos-instructions.md).

## Current limitations

This is an early stage sample application, with a number of known limitations:
- Compilation of the `smoldot-flutter` library to `x86_64-linux-android` & `x86_64-apple-ios` targets currently fails. This prevents to run the app in an Android & IOS emulator. Investigation is ongoing to address this shortcoming (PR welcome).
- Integration that has been tested with the Android app, Linux, MacOS and IOS. The last step would be to ensure it works on Windows as well. No effort will be put into the Web target though, as the [Substrate Connect](https://github.com/paritytech/substrate-connect) project is already addressing this use case by embedding a WASM light client into a web-based decentralized application.
- The code of the embedded `smoldot-flutter` library is very rough, and currently contain some hard-coded parts (e.g. connection to the Polkadot network) which should be parameterized, and made more generic for reuse in other projects.

## License

Trappist Extra is licensed under [Apache 2](LICENSE).
