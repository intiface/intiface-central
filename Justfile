set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

default:
    @just --list

deps-local:
    test -d ../buttplug/crates/intiface_engine
    mkdir -p .cargo
    cp .cargo/config.local.toml .cargo/config.toml
    cargo fetch --manifest-path rust/Cargo.toml

deps-crates:
    rm -f .cargo/config.toml
    cargo fetch --manifest-path rust/Cargo.toml
