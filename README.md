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

Follow the steps below to setup your local development environment, and then build and run the mobile app on an Android device:

### Rust Setup

First, complete the [basic Rust setup instructions](./docs/rust-setup.md). Then, follow the detailed instructions below.

### Install Rust Android targets

Install the Android targets for your Rust toolchain using rustup:

```
rustup target add aarch64-linux-android
rustup target add x86_64-linux-android
```

### Install Java JDK & JRE


```
sudo apt install openjdk-11-jdk openjdk-11-jre
```

Configure the following environment variable (e.g. in your shell initialization file):
```
# Java
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
```

Note: the project has been tested and is known to work with this specific version of the Java JDK & JRE (v11). It might also work with a more recent version.

### Install the Android NDK, SDK & tools

If you don't already have the Android SDK, NDK & tools installed (from a prior mobile development environment), follow these steps:

Create an 'android' folder in your home folder.
```
mkdir ~/android
```

Download the [Android NDK version 21.4.7075529 (r21e)](https://dl.google.com/android/repository/android-ndk-r21e-linux-x86_64.zip), and unzip it in its own folder inside the android folder previously created:
```
wget -P ~/android https://dl.google.com/android/repository/android-ndk-r21e-linux-x86_64.zip
cd ~/android && unzip android-ndk-r21e-linux-x86_64.zip
rm android-ndk-r21e-linux-x86_64.zip
```

Note: the project has been tested and is known to work with this specific version of the Android NDK (r21e). Using more recent versions of the Android NDK with Rust is currently not so seamless, see this [issue](https://github.com/rust-lang/rust/issues/103673#user-content-fn-7-7531e3f8887b1ffc75952e25210dd077) for more information.

Configure the following environment variables (e.g. in your shell initialization file):
```
# Android
export ANDROID=$HOME/android

# Android NDK
export NDK_HOME=$ANDROID/android-ndk-r21e
export ANDROID_NDK=$NDK_HOME
export PATH=$PATH:$NDK_HOME
```

Download the Android Command Line Tools, and unzip them into a new android-sdk folder inside the android folder previously created:
```
mkdir ~/android/android-sdk
wget -P ~/android/android-sdk https://dl.google.com/android/repository/commandlinetools-linux-9123335_latest.zip
cd ~/android/android-sdk && unzip commandlinetools-linux-9123335_latest.zip
rm commandlinetools-linux-9123335_latest.zip
```

Configure the following environment variables (e.g. in your shell initialization file):
```
# Android
export ANDROID=$HOME/Dev/android
export ANDROID_SDK=$ANDROID/android-sdk
export PATH=$ANDROID_SDK:$PATH
export PATH=$ANDROID_SDK/cmdline-tools/latest:$PATH
export PATH=$ANDROID_SDK/cmdline-tools/latest/bin:$PATH
export PATH=$ANDROID_SDK/platform-tools:$PATH
```

Now we can download the Android SDK components, and accept the licenses:
```
sdkmanager "system-images;android-29;default;x86_64"
sdkmanager "platforms;android-29"
sdkmanager "platforms-tools;29.0.3"
sdkmanager "build-tools;29.0.3"
sdkmanager "patcher;v4"
sdkmanager --licenses
```

Configure the following environments variables (e.g. in your shell initialization file):
```
# Rust compile flags
export CFLAGS_aarch64_linux_android="-std=gnu11 -fPIC -D OS_ANDROID -D ANDROID"
export CXXFLAGS_aarch64_linux_android="-std=gnu++11 -fPIC -fexceptions -frtti -static-libstdc++ -D OS_ANDROID -D ANDROID" 
export CXXSTDLIB_aarch64_linux_android=""
export AR_aarch64_linux_android=$NDK_HOME/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin/aarch64-linux-android-ar
export CC_aarch64_linux_android=$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android29-clang
export CXX_aarch64_linux_android=$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android29-clang++

export CFLAGS_x86_64_linux_android="-std=gnu11 -fPIC -D OS_ANDROID -D ANDROID"
export CXXFLAGS_x86_64_linux_android="-std=gnu++11 -fPIC -fexceptions -frtti -static-libstdc++ -D OS_ANDROID -D ANDROID"
export CXXSTDLIB_x86_64_linux_android=""
export AR_x86_64_linux_android=$NDK_HOME/toolchains/x86_64-4.9/prebuilt/linux-x86_64/bin/x86_64-linux-android-ar
export CC_x86_64_linux_android=$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android29-clang
export CXX_x86_64_linux_android=$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android29-clang++
```

Configure the Rust compilation environment to point to the Android NDK. Create or replace your `~/.cargo/config` file to contain the following:
```
[target.aarch64-linux-android]
linker = "$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android29-clang"
rustflags = [
    "-C", "link-arg=-L$NDK_HOME/platforms/android-29/arch-arm64/usr/lib/",
    "-C", "link-arg=-L$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/lib/gcc/aarch64-linux-android/4.9.x/",
    "-C", "link-arg=-lc++_static", "-C", "link-arg=-lc++abi"
]

[target.x86_64-linux-android]
linker = "$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin//x86_64-linux-android29-clang"
rustflags = [
    "-C", "link-arg=-L$NDK_HOME/platforms/android-29/arch-x86_64/usr/lib64",
    "-C", "link-arg=-L$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/lib/gcc/x86_64-linux-android/4.9.x/",
    "-C", "link-arg=-lc++_static", "-C", "link-arg=-lc++abi"
]
```

### Install Flutter

Download the Flutter SDK version 3.3.10, and unzip it in its own flutter folder inside the android folder previously created:

```
wget -P ~/android https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.3.10-stable.tar.xz
cd ~/android && tar xvf flutter_linux_3.3.10-stable.tar.xz
rm flutter_linux_3.3.10-stable.tar.xz
```

Configure the following environment variables (e.g. in your shell initialization file):
```
# Flutter
export FLUTTER=$ANDROID/flutter
export PATH=$FLUTTER/bin:$PATH
```

Configure the path to the Android SDK for Flutter:
```
flutter config --android-sdk ~/android/android-sdk
```

Run Flutter doctor to verify the development setup:
```
flutter doctor -v
```

If all went well, Flutter Doctor should display green marks for all items (except for Android Studio which we didn't install, so this can be safely ignored).

Note: this documentation borrows heavily from the following guide: [How to install Flutter without Android Studio on Ubuntu](https://ksrk.medium.com/install-flutter-without-android-studio-on-ubuntu-a14a66a88f9f). 

### Install the Flutter Rust Bridge code generator

Install the Flutter Rust Bridge code generator that will generate the glue code between the Rust library and the Dart (Flutter) project:
```
cargo install flutter_rust_bridge_codegen
```

Next, we install the [cargo-ndk](https://github.com/bbqsrc/cargo-ndk) tool which will be used during the build phase of the Flutter project to build the rust code to an Android library, and copy the resulting libs to 
```
cargo install cargo-ndk
```

Lastly, we need to configure an environment variable for the Gradle build tool. Create or replace a `~/.gradle/gradle.properties` file to contain the following
```
ANDROID_NDK=$NDK_HOME
```
### Build & run the Flutter Android app

To re-generate the rust-to-flutter glue code (bridge), run the following command:
```
flutter_rust_bridge_codegen -r smoldot-flutter/src/api.rs -d lib/bridge_generated.dart
```
To build the Android deployment package (apk), run the following command:
```
flutter build apk
```
To run the Android application on a connected Android device, run:
```
flutter run
```
Note: your Android phone must have the **Developer Mode** activated, and **USB debugging** (or **Wireless debugging**) must be active.

## Current limitations
This is an early stage sample application, with a number of known limitations:
- Compilation of the `smoldot-flutter` library to `x86_64-linux-android` target currently fails. This prevents to run the app in an Android emulator. Investigation is ongoing to address this shortcoming (PR welcome).
- The only integration that has been tested is with the Android app. A natural next step would be to ensure it works on iOS as well, and then on desktop OSes (Linux, MacOS, Windows). No effort will be put into the Web target though, as the [Substrate Connect](https://github.com/paritytech/substrate-connect) project is already addressing this use case by embedding a WASM light client into a web-based decentralized application.
- The code of the embedded `smoldot-flutter` library is very rough, and currently contain some hard-coded parts (e.g. connection to the Polkadot network) which should be parameterized, and made more generic for reuse in other projects.

## License

Trappist Extra is licensed under [Apache 2](LICENSE).
