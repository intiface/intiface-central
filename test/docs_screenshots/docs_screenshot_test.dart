import 'package:flutter_test/flutter_test.dart';

import 'docs_screenshot_capture.dart';
import 'docs_screenshot_fonts.dart';
import 'docs_screenshot_spec.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadDocsScreenshotFonts);

  final specs = DocsScreenshotSpec.loadAll('docs/assets/screenshots/sources');
  final widgetSpecs = specs
      .where((spec) => spec.mode == DocsScreenshotMode.widget)
      .toList();

  group('docs screenshot specs', () {
    test('include at least one widget-mode screenshot', () {
      expect(widgetSpecs, isNotEmpty);
    });

    for (final spec in widgetSpecs) {
      testWidgets('generates ${spec.id}', (tester) async {
        await DocsWidgetScreenshotGenerator(spec).generate(tester);
      });
    }
  });
}
