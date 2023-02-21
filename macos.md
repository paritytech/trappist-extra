```shell
# install xcode

# install cargo-xcode, assuming xcode is already installed
cargo install cargo-xcode
# note https://github.com/fzyzcjy/flutter_rust_bridge/issues/870#issuecomment-1420279892

flutter_rust_bridge_codegen \
    -r smoldot-flutter/src/api.rs \
    -d lib/bridge_generated.dart \
    -c ios/Runner/bridge_generated.h \
    -e macos/Runner/

flutter run
```