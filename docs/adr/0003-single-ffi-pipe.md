# ADR 0003: Single FFI Pipe with Dart-Side Routing

## Status

Accepted

## Context

The Rust engine communicates with the Flutter frontend via `flutter_rust_bridge`. The engine produces multiple categories of messages: lifecycle events (started, stopped, error), device events (added, removed), and high-frequency data (output observations at up to 60fps per feature). These have very different frequencies and consumers.

The question is whether to use one FFI stream for everything or multiple streams for different message types.

## Alternatives Considered

**Multiple FFI streams:** Separate `StreamSink` per message category (lifecycle, devices, observations). Each stream is typed at the FFI boundary. Consumers subscribe only to what they need. Trade-off: more FFI surface to manage, more lifecycle coordination (each stream needs setup/teardown), more generated bridge code, and the Rust side needs to know about the routing taxonomy.

**Single FFI stream, route in Dart:** One `StreamSink<String>` carries all JSON-serialized engine messages. The Dart-side Gateway (EngineRepository) deserializes and fans out to typed broadcast streams. Trade-off: all messages share bandwidth, Dart does the routing work, and there's a JSON deserialization cost for every message regardless of consumer interest.

## Decision

Single `StreamSink<String>` for all engine-to-Dart communication. The Gateway deserializes and routes messages to typed streams on the Dart side.

## Consequences

- **Minimal FFI surface.** One stream to set up, one to tear down, one lifecycle to manage. Cross-language bugs concentrate in one well-understood channel rather than spreading across multiple.
- **Routing complexity lives in Dart** where Flutter tooling (hot reload, debugger, logging) makes it easy to inspect and change. Adding a new message category means updating the Gateway's routing logic, not the FFI bridge.
- **Shared bandwidth.** High-frequency observations share the pipe with low-frequency lifecycle events. At observed volumes (300 messages/sec with 5 features at 60fps) this is well within the StreamSink's capacity. If volumes grow by an order of magnitude, this decision should be revisited.
- **JSON overhead.** Every message is serialized to a JSON string on the Rust side and deserialized on the Dart side, even if no consumer cares about that message type. The cost is negligible at current volumes but is a known inefficiency.
- **Shutdown simplicity.** One pipe to close. The Gateway absorbs the close event and propagates stream-done to all consumers.
