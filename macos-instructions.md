```shell
# install required packages, following additional instructions in resulting caveats for each package
brew install openjdk@17 llvm flutter

# TARGET: Android
# add the required target
rustup target install aarch64-linux-android
# install android command line tools
mkdir -p ~/android/cmdline-tools
curl -o commandlinetools.zip https://dl.google.com/android/repository/commandlinetools-mac-9477386_latest.zip
unzip commandlinetools.zip && rm -f commandlinetools.zip
mv cmdline-tools ~/android/cmdline-tools/latest
# update paths
fish_add_path /opt/homebrew/opt/openjdk@17/bin
fish_add_path /opt/homebrew/opt/llvm/bin
fish_add_path ~/android/cmdline-tools/latest/bin
# install android native development kit and accept licenses (remaining packages are auto-installed later)
sdkmanager "ndk;25.1.8937393" "platform-tools" "build-tools;30.0.3" "platforms;android-33"
sdkmanager --licenses
# configure environment
export ANDROID_HOME="$HOME/android"
export NDK_HOME="$ANDROID_HOME/ndk/25.1.8937393"
export ANDROID_NDK_HOME="$NDK_HOME"
# configure flutter and check results
flutter config --android-sdk "$ANDROID_HOME"
flutter doctor -v # Xcode and Android Studio can be ignored
# install flutter rust bridge code generator and ndk
cargo install flutter_rust_bridge_codegen
cargo install cargo-ndk
# configure gradle for apk build
mkdir -p ~/.gradle
echo "ANDROID_NDK=$NDK_HOME" > ~/.gradle/gradle.properties
# build & run app
flutter pub get
flutter_rust_bridge_codegen -r smoldot-flutter/src/api.rs -d lib/bridge_generated.dart
flutter build apk # allow the impellerc and font-subset files within system, privacy & security, general; repeat until build successful
# finally connect device, allow access and run
flutter run --release

# TARGET: MACOS
# install xcode: https://developer.apple.com/xcode
# install cargo-xcode (note note https://github.com/fzyzcjy/flutter_rust_bridge/issues/870#issuecomment-1420279892)
cargo install cargo-xcode
flutter_rust_bridge_codegen \
    -r smoldot-flutter/src/api.rs \
    -d lib/bridge_generated.dart \
    -c ios/Runner/bridge_generated.h \
    -e macos/Runner/
flutter run --release

# TARGET: iOS
rustup target add aarch64-apple-ios
# open ios/Runner.xcodeproj and set signing certificate under Signing and Capabilities
# amend bundle identifier to something unique
# connect device, allow access and run
flutter run # or 'flutter run --release' for deployment to device which runs without being connected in debug mode
```