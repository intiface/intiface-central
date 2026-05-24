---
name: intiface-doc-screenshots
description: Generate and maintain Intiface Central documentation screenshots from prompts by clarifying exact UI states, creating source specs, rendering widget or integration screenshots, adding callouts, and validating generated artifacts. Use when the user asks to create, update, regenerate, review, or plan docs screenshots or screenshot callouts for Intiface Central.
---

# Intiface Docs Screenshots

Use this skill for screenshot work in the Intiface Central repo. The source of
truth is `docs/assets/screenshots/sources/`; generated PNGs live in
`docs/assets/screenshots/generated/`.

## Start By Grilling The User

Before writing specs or generating images, pin down exactly what the screenshot
must communicate. Ask direct questions until the capture intent is clear.
Prefer small batches of questions, but do not proceed with vague capture goals.

Clarify:

- Which UI workflow, page, component, or state should be shown?
- Is the screenshot a deterministic component state or a real app journey?
- What exact data should appear, including fake device names and server/client
  states?
- What must not appear, such as local IPs, machine paths, timestamps, personal
  device names, serials, or debug text?
- Which callouts are required, including target, label text, and rough
  placement?
- Whether raw screenshots, callout screenshots, or both are needed.
- Target docs context: intended page, image width, and required alt text.
- Platform expectations: desktop/mobile, OS-specific behavior, or manual-only
  capture requirements.

If the user provides enough detail up front, restate the capture contract
briefly and proceed.

## Workflow

1. Read `docs/assets/screenshots/README.md` and the relevant source specs.
2. Choose `widget` mode by default. Use `integration` only when the screenshot
   needs engine/device lifecycle behavior from the real test app.
3. Add or update a small JSON spec in `docs/assets/screenshots/sources/`.
4. Prefer existing text, tooltip, semantics, or durable keys for callout targets.
   Add `DocsScreenshotKeys` only when existing finders are brittle.
5. Keep callout labels short, sentence case, and under 80 characters unless the
   user explicitly approves an exception.
6. Generate widget screenshots:

   ```bash
   flutter test test/docs_screenshots --update-goldens
   ```

7. For integration screenshots, use the docs-specific driver:

   ```bash
   flutter drive \
     --driver=test_driver/docs_screenshots.dart \
     --target=integration_test/docs_screenshots_test.dart \
     -d macos
   ```

8. Visually inspect generated PNGs. Check for blank captures, Ahem/font blocks,
   missing Material icons, clipped UI, offscreen labels, label/target overlap,
   stale copy, and accidental local or personal data.
9. Run focused validation:

   ```bash
   flutter test test/docs_screenshots --update-goldens
   git diff --exit-code -- docs/assets/screenshots/generated
   test -z "$(git status --porcelain -- docs/assets/screenshots/generated)"
   ```

10. Report changed specs, generated files, validation commands, and any manual
    review gates or unverified integration captures.

## Manual Capture Records

Use `docs/assets/screenshots/sources/manual-capture-template.md` when automation
is not realistic, such as native permission dialogs, real hardware behavior, or
OS-level surfaces. Manual records must include platform, OS version, app version
or commit, setup, exact steps, and why automation is not used.

## Guardrails

- Do not manually edit generated PNGs.
- Do not use real user data.
- Do not add broad production refactors just to make a screenshot easier.
- Do not silently replace manual screenshots with automation if behavior differs.
- Do not add more than five callouts to one screenshot unless the user approves.
- Public docs screenshots need human-approved alt text.
