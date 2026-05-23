import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

Future<void> loadDocsScreenshotFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null || flutterRoot.isEmpty) {
    throw StateError('FLUTTER_ROOT is required to load docs screenshot fonts.');
  }

  final loader = FontLoader('Roboto')
    ..addFont(_loadFont(flutterRoot, 'Roboto-Regular.ttf'))
    ..addFont(_loadFont(flutterRoot, 'Roboto-Medium.ttf'))
    ..addFont(_loadFont(flutterRoot, 'Roboto-Bold.ttf'));
  await loader.load();

  final materialIconsLoader = FontLoader('MaterialIcons')
    ..addFont(_loadFont(flutterRoot, 'MaterialIcons-Regular.otf'));
  await materialIconsLoader.load();
}

Future<ByteData> _loadFont(String flutterRoot, String fileName) async {
  final bytes = await File(
    p.join(flutterRoot, 'bin/cache/artifacts/material_fonts', fileName),
  ).readAsBytes();
  return ByteData.sublistView(Uint8List.fromList(bytes));
}
