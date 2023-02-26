# macOS Instructions
Instructions to deploy macOS, iOS or Android app built on macOS.

## Install Packages
Install required packages, making sure to follow additional instructions in resulting caveats for each package:
```shell
brew install openjdk@17 llvm flutter
```

## Android
The following sections provide the steps required to build and run the app on a connected Android device.
### Install Rust Android target
```shell
rustup target install aarch64-linux-android
```
### Install Android command line tools
```shell
mkdir -p ~/android/cmdline-tools
curl -o commandlinetools.zip https://dl.google.com/android/repository/commandlinetools-mac-9477386_latest.zip
unzip commandlinetools.zip && rm -f commandlinetools.zip
mv cmdline-tools ~/android/cmdline-tools/latest
```
### Update paths
Update your paths. The below commands are for the fish shell and should be replaced with those of your shell.
```shell
fish_add_path /opt/homebrew/opt/openjdk@17/bin
fish_add_path /opt/homebrew/opt/llvm/bin
fish_add_path ~/android/cmdline-tools/latest/bin
```
### Install Packages
Install the required packages and accept licenses (remaining packages are auto-installed later)
```shell
sdkmanager "ndk;25.1.8937393" "platform-tools" "build-tools;30.0.3" "platforms;android-33"
sdkmanager --licenses
```
### Configure Environment
```shell
export ANDROID_HOME="$HOME/android"
export NDK_HOME="$ANDROID_HOME/ndk/25.1.8937393"
export ANDROID_NDK_HOME="$NDK_HOME"
```
### Configure Flutter and check results
```shell
flutter config --android-sdk "$ANDROID_HOME"
flutter doctor -v # Xcode and Android Studio can be ignored
```
### Install Flutter Rust bridge code generator and Cargo NDK
```shell
cargo install flutter_rust_bridge_codegen
cargo install cargo-ndk
```
### Configure Gradle for APK build
```shell
mkdir -p ~/.gradle
echo "ANDROID_NDK=$NDK_HOME" > ~/.gradle/gradle.properties
```
### Build app
```shell
flutter pub get
flutter_rust_bridge_codegen -r smoldot-flutter/src/api.rs -d lib/bridge_generated.dart
flutter build apk # allow the impellerc and font-subset files within system, privacy & security, general; repeat until build successful
```
### Run app
Finally connect device, allow access and run:
```shell
flutter run --release
```

## macOS / iOS
The following sections provide the steps required to build and run the app on a macOS desktop or on a connected iOS device.
### Install Xcode
Required for both macOS and iOS.
https://developer.apple.com/xcode
### Install Rust iOS target
Required for iOS only.
```shell
rustup target add aarch64-apple-ios
```
### Install Cargo-Xcode 
```shell
cargo install cargo-xcode
```

### Additional iOS settings
Open `ios/Runner.xcodeproj` and set the signing certificate under the **Signing and Capabilities**. 
Amend bundle identifier to something unique. Connect device and allow access, developer mode etc.

### Build & run the Flutter app
```shell
flutter pub get
flutter_rust_bridge_codegen \
    -r smoldot-flutter/src/api.rs \
    -d lib/bridge_generated.dart \
    -c ios/Runner/bridge_generated.h \
    -e macos/Runner/
flutter run --release
```
Note: `flutter run` (without `--release`)  launches in debug mode, showing smoldot output within your terminal for connected iOS devices.