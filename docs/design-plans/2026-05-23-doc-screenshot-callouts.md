# Documentation Screenshot Callouts Design

## Summary

Create a repeatable documentation screenshot pipeline for Intiface Central that can capture deterministic Flutter UI states, add numbered callouts, and write reviewable image artifacts for docs. The pipeline should be agent-led for routine regeneration and maintenance, but keep explicit manual gates for product judgment: which workflows deserve screenshots, whether callout text is clear, whether visual output matches the current docs story, and whether platform-specific screenshots represent real user behavior.

The implementation builds on the existing Flutter test infrastructure and the simulated-device integration harness. Component screenshots should come from deterministic widget/golden tests. Journey screenshots should come from integration tests that drive the real app test bootstrap and simulated devices. Callouts should be generated from a small manifest so agents can update screenshots without hand-editing pixels or relying on fragile absolute coordinates.

## Goals

- Generate docs-ready UI screenshots from source-controlled specs.
- Add consistent numbered callouts, labels, arrows, and highlight boxes without manual image editing.
- Support both deterministic component states and realistic full-app journeys.
- Let agents create, update, and validate screenshot specs as part of documentation work.
- Keep human review responsible for content quality, brand fit, accessibility, and final docs selection.
- Avoid screenshot drift by tying screenshots to stable widget keys, semantics labels, and test fixtures.

## Non-Goals

- Replacing golden visual regression tests for UI correctness.
- Building a general-purpose screenshot editor.
- Fully automating product documentation judgment.
- Real-hardware screenshot automation.
- Capturing platform permission dialogs as a first milestone.
- Guaranteeing pixel-identical output across all host platforms. CI should pin one screenshot platform.

## Current State

The repository already has most of the runtime pieces needed for a docs screenshot pipeline:

- `flutter_test`, `integration_test`, `bloc_test`, and `mocktail` are active dev dependencies.
- `test/helpers/pump_app.dart` can render widgets with mocked BLoCs/Cubits and a fixed `MediaQuery` size.
- `integration_test/app_test.dart` initializes `IntegrationTestWidgetsFlutterBinding`.
- `integration_test/flows/device_connect_test.dart` already drives a realistic simulated-device journey.
- `docs/design-plans/2026-05-22-gui-test-system.md` already recommends golden tests for deterministic component states.

Missing pieces:

- A docs-specific screenshot spec format.
- A screenshot runner that writes named artifacts.
- A callout renderer.
- Stable screenshot target identifiers on all UI elements that documentation wants to point at.
- A manual review checklist and artifact approval workflow.

## Architecture Decision

Use a repo-local Flutter-first screenshot system rather than a browser or external desktop screenshot tool.

Three reasons:

1. Intiface Central is a Flutter app, not a web app.
2. Widget tests already provide deterministic render trees, fixed viewports, fake state, and inspectable element bounds.
3. Integration tests already drive realistic app journeys with the real Rust engine and simulated devices.

External tools such as Snagit, CleanShot, Shottr, or Flameshot can remain useful for one-off manual documentation edits, but they should not be the source of truth for maintained screenshots. Browser-first tools such as Playwright or Heroshot are only appropriate if a future docs/demo surface renders the same UI through Flutter Web.

## Artifact Model

Generated files should live under a dedicated docs artifact directory:

```
docs/assets/screenshots/
├── generated/
│   ├── device-list-connected.png
│   ├── device-list-connected-callouts.png
│   └── engine-control-running-callouts.png
└── sources/
    ├── device-list-connected.yaml
    └── engine-control-running.yaml
```

The `sources/` files are the source of truth. The `generated/` files are committed only when they are used by docs pages or release notes.

## Screenshot Spec

Each screenshot spec describes what to render, how to capture it, and what callouts to draw.

Example shape:

```yaml
id: device-list-connected
title: Device list with a connected simulated device
mode: widget
viewport:
  width: 1280
  height: 800
theme: light
entrypoint: deviceList
fixture:
  engine: running
  devices:
    - id: simulated-1vibe
      displayName: Test Domi
      connected: true
callouts:
  - id: start-stop-control
    target:
      key: docs.engineControlButton
    label: Start or stop the Intiface server
    placement: right
  - id: connected-device
    target:
      text: Test Domi
    label: Connected devices appear at the top of the list
    placement: bottom
```

The first implementation can support YAML or JSON. YAML is more pleasant for docs authors; JSON is easier to parse without adding a dependency. If YAML is used, add a small Dart or script dependency intentionally rather than parsing it by hand.

## Target Resolution

Callout targets should resolve through stable Flutter identifiers in this order:

1. `ValueKey` or `Key` values reserved for docs/test targeting.
2. Semantics labels that already serve accessibility.
3. Existing text or tooltip finders.
4. Explicit bounding boxes only as a last resort.

Documentation-specific keys should be centralized to avoid string drift, for example:

```dart
class DocsScreenshotKeys {
  static const engineControlButton = ValueKey('docs.engineControlButton');
  static const deviceList = ValueKey('docs.deviceList');
  static const deviceListCardPrefix = 'docs.deviceListCard.';
}
```

Use keys sparingly. Prefer adding keys to durable interaction points, not decorative layout nodes.

## Capture Modes

### Widget Mode

Widget mode renders a focused component or page using `pumpApp()` and fake state.

Best for:

- Control widget states.
- Device list states.
- Settings panels.
- Error and empty states.
- Callouts explaining static UI concepts.

Properties:

- Fast.
- Deterministic.
- Does not require Rust or simulated-device startup.
- Best default for docs screenshots unless a full journey is necessary.

### Integration Mode

Integration mode launches the test app bootstrap, creates simulated devices through FFI, drives the UI, and captures screenshots after named steps.

Best for:

- Engine start and stop flow.
- Device discovery flow.
- Connected-device controls.
- Screenshots where real async Rust-originated state matters.

Properties:

- Slower.
- Higher fidelity.
- More timing-sensitive.
- Should use `pumpUntilFound()` / `pumpUntil()` helpers rather than fixed sleeps.

### Manual Mode

Manual mode documents screenshots that cannot yet be reliably automated.

Best for:

- Native permission dialogs.
- App store or OS-level surfaces.
- Real-device-only Bluetooth or USB behavior.
- Temporary launch screenshots before automation exists.

Manual-mode screenshots must still have a source record that explains:

- Platform and OS version.
- App version or commit.
- Device type.
- Required setup.
- Exact manual steps.
- Whether the screenshot can be replaced by automation later.

## Callout Rendering

Callouts should be rendered programmatically after the screenshot target bounds are known.

Initial renderer options:

1. Flutter overlay renderer: render the UI and callout overlay in one widget tree, then capture the composed image.
2. Post-processing renderer: capture the raw screenshot, then use Dart image APIs to draw callout circles, lines, boxes, and labels.

Choose Flutter overlay first. It reuses Flutter text rendering, themes, layout, and device pixel ratio behavior. It also avoids adding an image-editing dependency in the first milestone.

Callout style:

- Numbered circular markers.
- Thin leader lines.
- Light translucent target highlight rectangles.
- Label boxes with short text.
- Consistent color token, stroke width, font size, and padding.
- Labels placed outside the target when possible.

Callout constraints:

- No labels should overlap the target, app navigation, or another label.
- No more than five callouts per screenshot.
- Callout text should be sentence case and under 80 characters unless manual review approves an exception.
- Screenshots used in docs should include alt text next to the image reference.

## Agent-Led Workflow

The agent lead owns the mechanical screenshot workflow:

1. Read the docs task and identify required UI states.
2. Choose widget mode unless full-app behavior is necessary.
3. Add or update screenshot specs under `docs/assets/screenshots/sources/`.
4. Add stable keys or semantics labels only where current finders are brittle.
5. Add or update fixture builders for the states being captured.
6. Run the screenshot generator.
7. Inspect generated images for missing assets, blank captures, clipping, overlap, and stale UI.
8. Update docs image references and alt text if requested.
9. Report changed specs, generated files, validation commands, and any screenshots requiring manual review.

Agent guardrails:

- Do not manually edit generated PNGs.
- Do not add broad production refactors just to make a screenshot easier.
- Do not use real user data in screenshots.
- Do not capture timestamps, machine-specific paths, local IPs, or serial numbers unless intentionally documented.
- Do not silently replace a manual-mode screenshot with automation if the behavior differs.
- Keep screenshot specs small and specific; one spec per docs image.

## Manual Requirements

Human/manual work remains required for:

- Deciding which screenshots belong in public docs.
- Approving callout text and visual emphasis.
- Verifying that screenshots match the current documentation narrative.
- Checking brand-sensitive presentation, including app name, icons, and visible copy.
- Validating accessibility concerns: alt text, contrast, and callout readability.
- Capturing or approving OS/native screenshots that automation cannot produce.
- Running real-device checks when a screenshot claims hardware or platform behavior.

Manual review checklist for every committed docs screenshot:

- The screenshot shows the current UI for the target release.
- Callout labels are accurate and not overloaded.
- No secrets, local paths, personal device names, local IP addresses, or accidental debug text are visible.
- The image is readable at the intended docs display width.
- The screenshot has matching alt text in the docs page.
- The source spec or manual capture record exists.
- The generated image was produced from the latest spec.

## Implementation Phases

### Phase 1: Screenshot Spec and Directory Layout

Goal: establish the source-of-truth format and output locations.

Tasks:

- Create `docs/assets/screenshots/sources/`.
- Create `docs/assets/screenshots/generated/`.
- Add a short `README.md` explaining generated vs source files.
- Define the first screenshot spec schema.
- Add one widget-mode spec for `ControlWidget` stopped/running state.

Acceptance criteria:

- A developer or agent can tell which files are editable sources and which are generated outputs.
- The schema supports viewport, theme, capture mode, fixture, and callout entries.

Suggested agent split:

- Small worker agent can create directory structure and README.
- Parent agent owns the schema decision.

### Phase 2: Widget Screenshot Runner

Goal: render deterministic widget-mode screenshots from specs.

Tasks:

- Add a Flutter test or Dart entrypoint for docs screenshot generation.
- Reuse `pumpApp()` for provider setup.
- Add fixture builders for initial supported screenshots.
- Pin viewport, text scale, theme, and animation state.
- Write raw screenshot PNGs to `docs/assets/screenshots/generated/`.

Acceptance criteria:

- Running one command regenerates the first widget-mode screenshot.
- Output is deterministic on the pinned local/CI platform.
- The command fails when a target finder cannot be resolved.

Suggested command shape:

```bash
flutter test test/docs_screenshots/ --update-goldens
```

or:

```bash
dart run tool/docs_screenshots generate
```

Prefer the Flutter test path first because it has direct access to `WidgetTester`.

### Phase 3: Callout Overlay Renderer

Goal: generate annotated screenshot variants.

Tasks:

- Resolve target bounds from keys, semantics, text, or tooltip finders.
- Render callout markers, lines, labels, and highlight boxes.
- Add collision checks for label boxes.
- Generate both raw and `-callouts` images.
- Fail the generation command when a callout target is missing or offscreen.

Acceptance criteria:

- The first callout image is generated without manual pixel editing.
- Target highlights align with the intended UI elements.
- The generator catches missing targets and obvious label overflow.

### Phase 4: Integration Journey Captures

Goal: capture realistic app states that require engine/device lifecycle.

Tasks:

- Add a docs-specific integration screenshot flow, separate from assertion-focused integration tests.
- Reuse `createTestApp()`, `TestAppEnvironment`, `addTestDevice()`, and `pumpUntilFound()`.
- Capture named steps such as engine stopped, engine running, device discovered, device detail controls.
- Keep generated test devices and names deterministic.

Acceptance criteria:

- The flow can generate at least one full-app screenshot with a simulated device.
- The flow cleans up RustLib, temp paths, and simulated devices after execution.
- Integration screenshots do not rely on fixed sleeps.

### Phase 5: Documentation Integration

Goal: make screenshots consumable by docs authors and release work.

Tasks:

- Add docs guidance for referencing generated images.
- Add alt-text requirements near image references.
- Add a regeneration command to contributor docs or the screenshot README.
- Decide whether generated screenshots are always committed or only committed when referenced by docs.

Acceptance criteria:

- A docs update can include a source spec, generated image, and alt text in one reviewable change.
- Reviewers can reproduce the screenshot locally or in CI.

### Phase 6: CI and Review Gates

Goal: prevent stale screenshots without making normal PRs too expensive.

Tasks:

- Add a CI job that validates screenshot specs and target resolution.
- Optionally regenerate screenshots in CI and compare against committed outputs.
- Run widget-mode screenshot validation on PRs.
- Run integration-mode screenshot validation nightly or on docs-labelled PRs.

Acceptance criteria:

- PRs fail when a committed screenshot spec no longer resolves.
- Expensive integration screenshots do not slow every code PR unless intentionally enabled.
- CI output names the failing spec and missing target.

## Acceptance Criteria

### doc-screenshot-callouts.AC1: Source-Controlled Specs

- **doc-screenshot-callouts.AC1.1 Success:** Screenshot specs exist under `docs/assets/screenshots/sources/`.
- **doc-screenshot-callouts.AC1.2 Success:** Specs define mode, viewport, fixture, output id, and callouts.
- **doc-screenshot-callouts.AC1.3 Failure:** A spec with a missing target fails generation with a useful error.

### doc-screenshot-callouts.AC2: Deterministic Widget Captures

- **doc-screenshot-callouts.AC2.1 Success:** At least one widget-mode screenshot is generated from a fixed viewport and theme.
- **doc-screenshot-callouts.AC2.2 Success:** The widget screenshot uses fake deterministic state, not live engine state.
- **doc-screenshot-callouts.AC2.3 Success:** Re-running the generator on the same platform produces the same image.

### doc-screenshot-callouts.AC3: Annotated Output

- **doc-screenshot-callouts.AC3.1 Success:** Callout overlays are generated from spec data.
- **doc-screenshot-callouts.AC3.2 Success:** Callouts align with resolved Flutter widget bounds.
- **doc-screenshot-callouts.AC3.3 Failure:** Overlapping or offscreen labels fail generation or are explicitly marked for manual review.

### doc-screenshot-callouts.AC4: Integration Captures

- **doc-screenshot-callouts.AC4.1 Success:** At least one integration-mode screenshot is generated from a simulated-device journey.
- **doc-screenshot-callouts.AC4.2 Success:** Integration mode reuses the existing test app bootstrap and cleanup helpers.
- **doc-screenshot-callouts.AC4.3 Success:** Integration screenshots use deterministic device names and settings.

### doc-screenshot-callouts.AC5: Manual Review Gates

- **doc-screenshot-callouts.AC5.1 Success:** Every committed generated screenshot has either a source spec or manual capture record.
- **doc-screenshot-callouts.AC5.2 Success:** Public-docs screenshots include human-approved alt text.
- **doc-screenshot-callouts.AC5.3 Success:** Manual-only screenshots document platform, app version/commit, setup, and reproduction steps.

## Subagent Coordination Plan

Use subagents for bounded write sets only. The parent agent should keep ownership of schema, visual style, docs integration, and final review.

Recommended sequence:

1. Parent: define schema and first screenshot targets.
2. Worker A: create directories, README, and starter specs.
3. Worker B: implement widget-mode capture runner.
4. Parent: review generated output and target stability.
5. Worker C: implement callout overlay renderer.
6. Parent: approve visual style and collision behavior.
7. Worker D: add integration-mode capture flow.
8. Parent: connect docs references, manual review checklist, and CI decisions.

Delegation rules:

- Do not assign two workers to the same screenshot runner files.
- Tell workers the repo may be dirty and they must not revert unrelated changes.
- Worker agents should not change public UI copy unless the parent explicitly asks.
- Worker agents should list changed files, generated screenshots, and validation commands.
- Parent agent reviews every generated PNG before marking the work complete.

## Manual Capture Record Template

Use this when automation is not yet possible:

```markdown
# Manual Screenshot Capture: <id>

- Output: `docs/assets/screenshots/generated/<id>.png`
- App commit:
- App version:
- Platform:
- OS version:
- Device:
- Display scale:
- Setup:
- Steps:
- Reason automation is not used:
- Replacement automation issue:
- Reviewer:
- Review date:
```

## Open Questions

- Should generated screenshots be committed for every spec, or only when referenced by docs?
- Should callouts be drawn in Flutter only, or should a post-processing renderer be added for cropped/manual images?
- Should documentation screenshot validation run on every PR or only docs-labelled PRs?
- Should docs screenshot keys live in production code, test-only wrappers, or both?
- What external docs repository consumes these images, and should this repo export them into that tree?
