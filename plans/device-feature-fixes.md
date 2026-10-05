# Device Feature Fixes: Name Fallback + Disabled Toggle

## Context

The device tab redesign (branch `device-dialog-update`) added feature configuration cards to the device detail page, but two things are missing:

1. Features with empty `description` fields show "Feature: " with no useful name
2. Output properties have a `disabled` field in the FFI layer that isn't exposed in the UI

## Fix 1: Feature Name Fallback

**When `feature.description` is empty, derive a name from the output or input type.**

### Step 1A — Rust FFI: expose input types

**File:** `rust/src/api/device_config.rs`

`ExposedServerDeviceFeatureInput` is currently fully opaque (no public methods). Add an `impl` block with an `input_types()` getter that returns `Vec<InputType>`.

```rust
impl ExposedServerDeviceFeatureInput {
  #[frb(sync, getter)]
  pub fn input_types(&self) -> Vec<InputType> {
    self.input.iter().map(|i| i.variant_key()).collect()
  }
}
```

Import additions on existing lines:
- Line 3: `use buttplug_core::message::{InputType, OutputType};`
- Line 5: `use buttplug_core::util::small_vec_enum_map::{SmallVecEnumMap, VariantKey};`

### Step 1B — Regenerate FFI bindings

```bash
flutter_rust_bridge_codegen generate
```

### Step 1C — Dart: feature name fallback in `_FeatureCard`

**File:** `lib/page/device_detail_page.dart`

Add a `_featureName()` helper to `_FeatureCard` that:
1. Returns `feature.description` if non-empty
2. Otherwise checks output types (vibrate → "Vibrate", rotate → "Rotate", etc.)
3. Otherwise checks input types via the new `input.inputTypes` getter (battery → "Battery", etc.)
4. Falls back to "Unknown"

Update line 649 to use `_featureName(feature)` instead of `feature.description`.

## Fix 2: Disabled Toggle for Output Properties

**Confirmed:** `disabled` is the correct field name in buttplug's `ServerDeviceFeatureOutputValueProperties`, `ServerDeviceFeatureOutputPositionProperties`, and `ServerDeviceFeatureOutputPositionWithDurationProperties`. The FFI already exposes `props.disabled` getter and setter.

### Step 2 — Dart: add disabled toggle to all three builder methods

**File:** `lib/page/device_detail_page.dart`

In each of `_buildValueSlider()`, `_buildPositionSlider()`, `_buildPositionWithDurationSlider()`:

1. Add a `CheckboxListTile` for "Disabled" before the slider widgets
2. When toggled, set `props.disabled` and call `_updateOutputProps()`
3. Disable slider/checkbox `onChanged` when `props.disabled` is true (same pattern as `engineRunning`)

## Files Modified

| File | Change |
|------|--------|
| `rust/src/api/device_config.rs` | Add imports, add `input_types()` getter |
| `lib/src/rust/api/device_config.dart` | Auto-regenerated (gains `inputTypes` on `ExposedServerDeviceFeatureInput`) |
| `lib/page/device_detail_page.dart` | `_featureName()` helper + disabled toggles in all builder methods |

## Commit Plan

1. **Commit 1:** Rust FFI change + regenerated bindings (step 1A + 1B)
2. **Commit 2:** Dart UI changes — name fallback + disabled toggle (step 1C + step 2)

## Verification

- `cargo clippy` in `rust/` — no new warnings
- `flutter analyze` — clean
- Manual test: connect a device with unnamed features, verify fallback names appear
- Manual test: toggle disabled on an output, verify it persists and dims the sliders
- Manual test: verify disabled toggle is locked when engine is running
