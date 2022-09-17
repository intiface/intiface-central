# Homebrew installs LLVM in a place that is not visible to ffigen.
# This explicitly specifies the place where the LLVM dylibs are kept.
llvm_path := if os() == "macos" {
    "--llvm-path /usr/local/opt/llvm"
} else {
    ""
}


REPO_DIR := env_var('PWD')

default: gen lint

gen:
    cd / && flutter_rust_bridge_codegen {{llvm_path}} \
        --rust-input {{REPO_DIR}}/native/src/api.rs \
        --dart-output {{REPO_DIR}}/lib/bridge_generated.dart \
        --c-output {{REPO_DIR}}/ios/Classes/BtleplugTestPlugin.h
    # --llvm-compiler-opts=-I/usr/lib/clang/version/include
    # cp ios/Runner/bridge_generated.h macos/Runner/bridge_generated.h

build-dev:
    cd native && cargo build

build-release:
    cd native && cargo build --release

build-android:
    cd native && cargo make build-android
    cp native/target/aarch64-linux-android/release/libnative.so android/src/main/jniLibs/arm64-v8a

build-ios:
    cd native && cargo make build-ios
    cp native/target/aarch64-apple-ios/release/libnative.a ios/Runner/libnative.a

lint:
    cd native && cargo fmt
    dart format .

clean:
    flutter clean
    cd native && cargo clean

watch:
    cd native && cargo watch -s "cd .. && just gen" -w src/api.rs

update:
    cd native && cargo update

run-example:
    cd example && flutter run
