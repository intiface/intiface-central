# Documentation Screenshots

This directory contains source-controlled screenshot specs and generated image
artifacts for documentation.

- `sources/` contains editable JSON specs and manual capture records. These are
  the source of truth.
- `generated/` contains PNGs produced by the screenshot tests. Do not edit these
  images by hand.

Widget-mode screenshots are regenerated with:

```bash
flutter test test/docs_screenshots --update-goldens
```

Generated PNGs may be exported to another documentation assets repository. When
that is the case, commit the source specs here and move the generated assets to
the destination repository after review.

Integration-mode screenshots use the real test app bootstrap and simulated
devices. They are intentionally separate from the normal integration suite:

```bash
flutter drive \
  --driver=test_driver/docs_screenshots.dart \
  --target=integration_test/docs_screenshots_test.dart \
  -d macos
```

Public docs should reference generated images only after human review. Every
referenced image needs matching alt text in the consuming docs page.

## Spec Schema

Specs currently use JSON to avoid a parser dependency in the app. The supported
top-level fields are:

- `id`: output basename under `generated/`.
- `title`: human-readable review title.
- `mode`: `widget`, `integration`, or `manual`.
- `viewport`: `{ "width": number, "height": number }`.
- `pixelRatio`: optional raster scale for widget-mode PNG output, defaults to
  `1`; use `2` for crisper docs images while keeping layout dimensions stable.
- `theme`: currently `light`.
- `presentation`: optional `card` or `window`, defaults to `card`.
- `background`: optional `solid` or `transparent`, defaults to `solid`.
- `window`: optional `{ "width": number, "height": number }` for `window`
  presentation.
- `entrypoint`: renderer name, such as `controlWidget`.
- `fixture`: deterministic state for the renderer.
- `callouts`: up to five callout objects.

Widget-mode fixtures currently support engine state, deterministic news content,
simulated device-list entries, advanced device manager entries, simple tap
actions, text/key-based scroll actions with optional `alignment`, and selected
configuration values such as
`useSideNavigationBar`, `useCompactDisplay`, `appMode`, websocket host/port
display, log panel expansion/messages, and app version strings.

Callout targets resolve in this order when the field is present: `key`, `text`,
`tooltip`, `semanticsLabel`, then explicit `bounds`.

Callouts use distinct colors by order. The optional `highlightPadding` field
defaults to `8`; set it to `0` or a negative value for adjacent region callouts
whose highlight boxes should not overlap. Set `markerOnly` to `true` to draw
the numbered marker and target highlight without rendering a callout text box.

## Manual Review Checklist

- The screenshot shows the current UI for the target release.
- Callout labels are accurate and not overloaded.
- No secrets, local paths, personal device names, local IP addresses, or
  accidental debug text are visible.
- The image is readable at the intended docs display width.
- The screenshot has matching alt text in the docs page.
- The source spec or manual capture record exists.
- The generated image was produced from the latest spec.
