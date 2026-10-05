# Device Tab Redesign

## Summary

Replace the flat, expandable-card device tab with a two-level navigation system: a clean main list of device cards (name, status, feature icons) that push to a dedicated device detail page via `Navigator.push`, plus a two-page "Add Device" wizard flow. No BLoC or Rust FFI changes required — this is a widget/navigation restructure only.

## Definition of Done

The device tab is replaced with a two-level navigation system: a clean main device list with card-based entries showing name, connection status, and feature summary icons (connected devices sorted to top, otherwise alphabetical), and a Navigator push/pop device detail page showing all configuration and controls. A global banner and per-device badges indicate when allow-mode filtering is active. An "Add New Device" wizard button (disabled during engine run) provides a tree-driven flow for adding websocket and serial devices. Device controls only appear on the detail page when connected. Configuration fields are read-only during engine run. Existing BLoC state management, Rust FFI layer, and engine lifecycle are not modified.

## Acceptance Criteria

### device-tab-redesign.AC1: Main Device List

- **device-tab-redesign.AC1.1** (success): All known devices appear as cards on the main device tab, showing display name (or default name), connection status indicator, and per-feature-type icons.
- **device-tab-redesign.AC1.2** (success): Connected devices sort to the top of the list; remaining devices are sorted alphabetically by display name.
- **device-tab-redesign.AC1.3** (success): Tapping a device card pushes a DeviceDetailPage via `Navigator.of(context).push(MaterialPageRoute(...))`.
- **device-tab-redesign.AC1.4** (success): Per-device badges show allow/deny status on the card.
- **device-tab-redesign.AC1.5** (success): A global banner appears at the top of the device list when any device has the allow flag set, indicating that filtering is active.
- **device-tab-redesign.AC1.6** (failure): No expandable card content appears on the main device list — all detail is on the detail page.

### device-tab-redesign.AC2: Device Detail Page

- **device-tab-redesign.AC2.1** (success): Detail page displays device info: default hardware name, display name, address, index.
- **device-tab-redesign.AC2.2** (success): Detail page shows configuration fields: display name (editable), message delay (integer input), "Connect to this device" (deny toggle), "Only connect to this device" (allow toggle).
- **device-tab-redesign.AC2.3** (success): All configuration fields are read-only when the engine is running.
- **device-tab-redesign.AC2.4** (success): "Forget device" button removes device config and pops back to main list.
- **device-tab-redesign.AC2.5** (success): When the device is connected, a controls section appears with output sliders/controls and input read/subscribe buttons, reusing existing DeviceOutputCubit/DeviceInputBloc logic.
- **device-tab-redesign.AC2.6** (success): When the device is disconnected, no controls section is rendered.
- **device-tab-redesign.AC2.7** (success): Feature output configuration (min/max limits, reverse, etc.) is shown per-feature using expandable cards.
- **device-tab-redesign.AC2.8** (success): Back button (Android hardware back, AppBar back arrow) pops back to the main device list.

### device-tab-redesign.AC3: Add Device Wizard

- **device-tab-redesign.AC3.1** (success): "Add New Device" button appears at the bottom of the main device list.
- **device-tab-redesign.AC3.2** (success): Button is disabled when the engine is running.
- **device-tab-redesign.AC3.3** (success): Tapping the button pushes a device type choice page (Websocket / Serial Port).
- **device-tab-redesign.AC3.4** (success): Serial Port option is only shown on desktop platforms.
- **device-tab-redesign.AC3.5** (success): Selecting Websocket pushes a websocket configuration page with protocol dropdown and address input.
- **device-tab-redesign.AC3.6** (success): Selecting Serial pushes a serial configuration page with protocol dropdown, port selector (combo box with discovered ports + free text), baud rate, data bits, parity, stop bits.
- **device-tab-redesign.AC3.7** (success): Completing the wizard adds the device via UserDeviceConfigurationCubit and pops back to the main list.
- **device-tab-redesign.AC3.8** (failure): Wizard is not accessible while the engine is running.

### device-tab-redesign.AC4: Widget Migration

- **device-tab-redesign.AC4.1** (success): `connected_devices_widget.dart` and `disconnected_devices_widget.dart` are removed; their logic is replaced by the unified device list.
- **device-tab-redesign.AC4.2** (success): `advanced_device_config_widget.dart` is removed; replaced by the Add Device wizard.
- **device-tab-redesign.AC4.3** (success): `device_control_widget.dart`, `device_config_widget.dart`, and `feature_output_config_widget.dart` are refactored into the DeviceDetailPage.
- **device-tab-redesign.AC4.4** (success): `expandable_card_widget.dart` is retained and reused for feature cards on the detail page.
- **device-tab-redesign.AC4.5** (success): No changes to any BLoC, Cubit, or Rust FFI code.

## Architecture

### Navigation Pattern

The app currently uses `NavigationCubit` (BLoC state machine) for tab switching. No `Navigator.push` is used for page navigation anywhere. This redesign introduces `Navigator.push(MaterialPageRoute(...))` for the first time, specifically for:

1. Device list card tap → `DeviceDetailPage`
2. Add Device button → `AddDeviceTypePage` (choice)
3. Device type selection → `AddWebsocketDevicePage` or `AddSerialDevicePage`

This works because the `MaterialApp` at the root provides a `Navigator` that the device tab widgets can access via `Navigator.of(context)`. The existing tab system continues to use `NavigationCubit` — these are orthogonal.

### Widget Tree: Main Device List (Redesigned DevicePage)

```
DevicePage (rewritten)
└── BlocBuilder<EngineControlBloc>
    └── BlocBuilder<DeviceManagerBloc>
        └── BlocBuilder<UserDeviceConfigurationCubit>
            └── Column
                ├── AllowModeBanner (conditional — shown when any device has allow=true)
                ├── Row [Start/Stop Scanning button]
                └── Expanded → ListView
                    ├── DeviceListCard × N (sorted: connected first, then alphabetical)
                    │   ├── Leading: connection status indicator
                    │   ├── Title: display name or default name
                    │   ├── Trailing: feature type icons (vibrate, rotate, etc.)
                    │   ├── Badge: allow/deny indicator
                    │   └── onTap → Navigator.push(DeviceDetailPage)
                    └── AddDeviceButton (disabled during engine run)
                        └── onTap → Navigator.push(AddDeviceTypePage)
```

### Widget Tree: Device Detail Page (New)

```
DeviceDetailPage(identifier, definition, [deviceCubit?])
└── Scaffold
    ├── AppBar (title: device name, automatic back button)
    └── SingleChildScrollView
        └── Column
            ├── Device Info Section
            │   ├── Hardware name (read-only)
            │   ├── Display name (editable when engine stopped)
            │   ├── Address (read-only)
            │   └── Index (read-only)
            ├── Device Config Section
            │   ├── Message delay input (editable when engine stopped)
            │   ├── "Connect to this device" toggle (deny flag, inverted)
            │   └── "Only connect to this device" toggle (allow flag)
            ├── Device Controls Section (ONLY when connected)
            │   ├── Output controls per feature (sliders, position+duration)
            │   └── Input controls per feature (read/subscribe buttons, values)
            ├── Feature Config Section
            │   └── ExpandableCardWidget per feature
            │       ├── Output type config (min/max, reverse, etc.)
            │       └── Input type info
            └── Forget Device Button
                └── onTap → remove config, Navigator.pop()
```

### Widget Tree: Add Device Wizard (New)

```
Page 1: AddDeviceTypePage
└── Scaffold
    ├── AppBar (title: "Add New Device", back button)
    └── Column
        ├── ListTile("Websocket Device") → Navigator.push(AddWebsocketDevicePage)
        └── ListTile("Serial Port Device") → Navigator.push(AddSerialDevicePage)
            (only shown on desktop — Platform.isWindows || Platform.isLinux || Platform.isMacOS)

Page 2a: AddWebsocketDevicePage (refactored from add_websocket_device_widget.dart)
└── Scaffold
    ├── AppBar (title: "Add Websocket Device", back button)
    └── Form
        ├── Protocol dropdown
        ├── Address text field
        ├── Existing websocket devices table (protocol, name, delete)
        └── "Add Device" button → addWebsocketDeviceName(), Navigator.pop() x2

Page 2b: AddSerialDevicePage (refactored from add_serial_device_widget.dart)
└── Scaffold
    ├── AppBar (title: "Add Serial Device", back button)
    └── Form
        ├── Protocol dropdown
        ├── Port selector (combo box: discovered ports + free text)
        ├── Baud rate, data bits, parity, stop bits
        ├── Existing serial devices table
        └── "Add Device" button → addSerialPort(), Navigator.pop() x2
```

## Existing Patterns Followed

### Material 3 Theming
All new widgets use `Theme.of(context).colorScheme` tokens (`onSurfaceVariant`, `surfaceContainerLow`, `surfaceContainerHighest`, `outlineVariant`) matching the existing codebase style.

### BLoC State Management
The redesign reuses all existing BLoCs without modification:
- `DeviceManagerBloc` — device lifecycle, scanning (lib/bloc/device/device_manager_bloc.dart)
- `DeviceCubit` — per-device state wrapper (lib/bloc/device/device_cubit.dart)
- `DeviceOutputCubit` / `DeviceInputBloc` — feature I/O (lib/bloc/device/device_output_cubit.dart, device_input_cubit.dart)
- `UserDeviceConfigurationCubit` — persistent config CRUD (lib/bloc/device_configuration/user_device_configuration_cubit.dart)
- `EngineControlBloc` — engine run state (lib/bloc/engine/engine_control_bloc.dart)
- `GuiSettingsCubit` — UI expansion state (lib/bloc/util/gui_settings_cubit.dart)

### Card Styling
The `ExpandableCardWidget` (lib/widget/expandable_card_widget.dart) is retained for feature cards on the detail page. New `DeviceListCard` follows the same Material 3 card styling (12px radius, `outlineVariant` border, `surfaceContainerHighest` header).

### flutter_settings_ui
The existing `device_config_widget.dart` uses `flutter_settings_ui` for settings-style configuration. The device detail page config section reuses this pattern.

## Implementation Phases

### Phase 1: Device List Card and Main Page Restructure
Create `DeviceListCard` widget and rewrite `DevicePage` to show a unified, sorted device list. Remove the connected/disconnected section split. Include the allow-mode banner and per-device badges. Wire up `onTap` to push placeholder detail pages. Remove imports of `connected_devices_widget.dart` and `disconnected_devices_widget.dart`.

**Files created:** `lib/widget/device_list_card_widget.dart`
**Files modified:** `lib/page/device_page.dart`
**Files deleted:** `lib/widget/connected_devices_widget.dart`, `lib/widget/disconnected_devices_widget.dart`

### Phase 2: Device Detail Page — Info and Config
Create `DeviceDetailPage` with device info section and configuration section (display name, message delay, allow/deny toggles, forget button). Refactor relevant logic from `device_config_widget.dart`. Wire up the `Navigator.push` from `DeviceListCard`. Ensure read-only during engine run.

**Files created:** `lib/page/device_detail_page.dart`
**Files modified:** `lib/page/device_page.dart` (wire up navigation)
**Files deleted:** `lib/widget/device_config_widget.dart` (after extraction)

### Phase 3: Device Detail Page — Controls (Connected Only)
Add the device controls section to `DeviceDetailPage`, rendered only when the device is connected. Refactor output sliders and input controls from `device_control_widget.dart`. Reuse `DeviceOutputCubit` and `DeviceInputBloc` directly.

**Files modified:** `lib/page/device_detail_page.dart`
**Files deleted:** `lib/widget/device_control_widget.dart` (after extraction)

### Phase 4: Device Detail Page — Feature Output Config
Add feature output configuration section using expandable cards. Refactor from `feature_output_config_widget.dart`. Show per-feature, per-output-type configuration with min/max sliders.

**Files modified:** `lib/page/device_detail_page.dart`
**Files deleted:** `lib/widget/feature_output_config_widget.dart` (after extraction)

### Phase 5: Add Device Wizard
Create `AddDeviceTypePage` (choice page), `AddWebsocketDevicePage`, and `AddSerialDevicePage`. Refactor from existing `add_websocket_device_widget.dart` and `add_serial_device_widget.dart`. Wire up the "Add New Device" button on the main list. Remove `AdvancedDeviceConfigWidget`.

**Files created:** `lib/page/add_device_type_page.dart`, `lib/page/add_websocket_device_page.dart`, `lib/page/add_serial_device_page.dart`
**Files modified:** `lib/page/device_page.dart` (add button)
**Files deleted:** `lib/widget/advanced_device_config_widget.dart`, `lib/widget/add_websocket_device_widget.dart`, `lib/widget/add_serial_device_widget.dart`

### Phase 6: Cleanup and Polish
Remove unused imports and dead code. Verify all navigation flows work correctly (push, pop, back button). Test allow-mode banner logic. Ensure scanning button state is correct. Clean up any remaining `GuiSettingsCubit` expansion keys that are no longer used.

**Files modified:** Various cleanup across touched files

## Additional Considerations

### Feature Type Icons
A mapping from output/input types to Material icons is needed for the device list cards. Suggested mapping:
- Vibrate → `Icons.vibration`
- Rotate → `Icons.rotate_right`
- Oscillate → `Icons.swap_vert`
- Constrict → `Icons.compress`
- Temperature → `Icons.thermostat`
- LED → `Icons.light`
- Spray → `Icons.water_drop`
- Position → `Icons.straighten`
- PositionWithDuration → `Icons.timer`
- Sensor/Input → `Icons.sensors`

### Data Passing to Detail Page
`DeviceDetailPage` needs both the `ExposedUserDeviceIdentifier` and `ExposedServerDeviceDefinition` from `UserDeviceConfigurationCubit`, plus optionally a `DeviceCubit` if the device is connected. The connected device list from `DeviceManagerBloc` can be matched by index to provide the `DeviceCubit`.

### Platform Gating
The "Serial Port Device" option in the Add Device wizard must be gated to desktop platforms only (`Platform.isWindows || Platform.isLinux || Platform.isMacOS`), matching the existing behaviour in `AdvancedDeviceConfigWidget`.

### State Freshness on Pop
When popping back from the detail page to the main list after config changes (e.g., display name change, forget device), the `UserDeviceConfigurationCubit` state should already be updated since config changes call `updateDefinition()` synchronously. The `BlocBuilder` on the main page will rebuild automatically.

## Glossary

- **Device List Card**: New compact card widget for the main device tab, showing device name, connection status, and feature icons.
- **Device Detail Page**: New full-page view pushed via Navigator, containing all device information, configuration, controls, and feature settings.
- **Add Device Wizard**: Two-page Navigator flow for adding websocket or serial devices.
- **Allow Mode**: When one or more devices have the "allow" flag set, only those devices will be connected. Other devices are ignored.
- **Deny Flag**: Per-device flag that prevents automatic connection to a specific device.
- **Feature Icons**: Small Material icons representing device capability types (vibrate, rotate, etc.) shown on device list cards.
- **Allow-Mode Banner**: Global indicator shown at the top of the device list when allow-mode filtering is active.
