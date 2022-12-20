/*
use lib_flutter_rust_bridge_codegen::{
  config_parse, frb_codegen, get_symbols_if_no_duplicates, RawOpts,
};
use std::env;

/// Path of input Rust code
const RUST_INPUT: &str = "src/api.rs";

/// Path of output generated Dart code
const ANDROID_DART_OUTPUT: &str = "../lib/bridge_generated_android.dart";

const IOS_DART_OUTPUT: &str = "../lib/bridge_generated_ios.dart";

const IOS_HEADER_OUTPUT: &str = "../example/ios/Runner/bridge_generated.h";

fn main() {
  // TODO Uncomment this once we can ignore files in codegen
  //
  // Until then we're stuck running codegen by hand because codegen brings in EVERYTHING it can find
  // in the crate and reexports all pub symbols, which means we get JNI calls in the iOS code.

  let target_os = env::var("CARGO_CFG_TARGET_OS").expect("CARGO_CFG_TARGET_OS should be set by cargo");

  // Tell Cargo that if the input Rust code changes, to rerun this build script.
  println!("cargo:rerun-if-changed={}", RUST_INPUT);
  // Options for frb_codegen
  let raw_opts = if target_os.contains("ios") {
    RawOpts {
      // Path of input Rust code
      rust_input: vec![RUST_INPUT.to_string()],
      // Path of output generated Dart code
      dart_output: vec![IOS_DART_OUTPUT.to_string()],
      c_output: Some(vec![IOS_HEADER_OUTPUT.to_string()]),
      dart_format_line_length: 120,
      // for other options use defaults
      ..Default::default()
    }
  } else if target_os.contains("android") {
    RawOpts {
      // Path of input Rust code
      rust_input: vec![RUST_INPUT.to_string()],
      // Path of output generated Dart code
      dart_output: vec![ANDROID_DART_OUTPUT.to_string()],
      dart_format_line_length: 120,
      // for other options use defaults
      ..Default::default()
    }
  } else {
    panic!("Cannot build for platforms other than ios/android.");
  };
  // get opts from raw opts
  let configs = config_parse(raw_opts);

  // generation of rust api for ffi
  let all_symbols = get_symbols_if_no_duplicates(&configs).unwrap();
  for config in configs.iter() {
      frb_codegen(config, &all_symbols).unwrap();
  }

}  */

fn main() {}
