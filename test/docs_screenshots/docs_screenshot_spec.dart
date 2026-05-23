import 'dart:convert';
import 'dart:io';
import 'dart:ui';

enum DocsScreenshotMode {
  widget,
  integration,
  manual;

  static DocsScreenshotMode parse(String value, String source) {
    return switch (value) {
      'widget' => DocsScreenshotMode.widget,
      'integration' => DocsScreenshotMode.integration,
      'manual' => DocsScreenshotMode.manual,
      _ => throw FormatException(
        'Unsupported screenshot mode "$value" in $source',
      ),
    };
  }
}

enum DocsScreenshotPresentation {
  card,
  window;

  static DocsScreenshotPresentation parse(String? value, String source) {
    return switch (value) {
      null || 'card' => DocsScreenshotPresentation.card,
      'window' => DocsScreenshotPresentation.window,
      _ => throw FormatException(
        'Unsupported screenshot presentation "$value" in $source',
      ),
    };
  }
}

enum DocsCalloutPlacement {
  left,
  right,
  top,
  bottom;

  static DocsCalloutPlacement parse(String value, String source) {
    return switch (value) {
      'left' => DocsCalloutPlacement.left,
      'right' => DocsCalloutPlacement.right,
      'top' => DocsCalloutPlacement.top,
      'bottom' => DocsCalloutPlacement.bottom,
      _ => throw FormatException(
        'Unsupported callout placement "$value" in $source',
      ),
    };
  }
}

class DocsScreenshotSpec {
  DocsScreenshotSpec({
    required this.sourcePath,
    required this.id,
    required this.title,
    required this.mode,
    required this.viewport,
    required this.theme,
    required this.presentation,
    required this.window,
    required this.entrypoint,
    required this.fixture,
    required this.callouts,
  }) {
    _validate();
  }

  final String sourcePath;
  final String id;
  final String title;
  final DocsScreenshotMode mode;
  final Size viewport;
  final String theme;
  final DocsScreenshotPresentation presentation;
  final Size? window;
  final String entrypoint;
  final Map<String, Object?> fixture;
  final List<DocsCalloutSpec> callouts;

  static List<DocsScreenshotSpec> loadAll(String directoryPath) {
    final directory = Directory(directoryPath);
    if (!directory.existsSync()) {
      throw FileSystemException(
        'Screenshot source directory does not exist',
        directoryPath,
      );
    }

    final files =
        directory
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    return files.map(DocsScreenshotSpec.fromFile).toList();
  }

  factory DocsScreenshotSpec.fromFile(File file) {
    final source = file.path;
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map) {
      throw FormatException('Screenshot spec must be a JSON object', source);
    }
    final json = Map<String, Object?>.from(decoded);

    final viewportJson = _requiredMap(json, 'viewport', source);
    final windowJson = _optionalMapOrNull(json, 'window');
    final fixtureJson = _optionalMap(json, 'fixture');
    final calloutJson = _optionalList(json, 'callouts');

    return DocsScreenshotSpec(
      sourcePath: source,
      id: _requiredString(json, 'id', source),
      title: _requiredString(json, 'title', source),
      mode: DocsScreenshotMode.parse(
        _requiredString(json, 'mode', source),
        source,
      ),
      viewport: Size(
        _requiredNumber(viewportJson, 'width', source),
        _requiredNumber(viewportJson, 'height', source),
      ),
      theme: _requiredString(json, 'theme', source),
      presentation: DocsScreenshotPresentation.parse(
        _optionalString(json, 'presentation', source),
        source,
      ),
      window: windowJson == null
          ? null
          : Size(
              _requiredNumber(windowJson, 'width', source),
              _requiredNumber(windowJson, 'height', source),
            ),
      entrypoint: _requiredString(json, 'entrypoint', source),
      fixture: fixtureJson,
      callouts: calloutJson
          .map(
            (value) => DocsCalloutSpec.fromJson(
              _asMap(value, 'callout', source),
              source,
            ),
          )
          .toList(),
    );
  }

  void _validate() {
    if (id.trim().isEmpty) {
      throw FormatException('Screenshot id cannot be empty', sourcePath);
    }
    if (!RegExp(r'^[a-z0-9][a-z0-9-]*$').hasMatch(id)) {
      throw FormatException(
        'Screenshot id "$id" must be lowercase kebab case',
        sourcePath,
      );
    }
    if (theme != 'light') {
      throw FormatException(
        'Only the light screenshot theme is currently supported',
        sourcePath,
      );
    }
    if (viewport.width <= 0 || viewport.height <= 0) {
      throw FormatException('Viewport dimensions must be positive', sourcePath);
    }
    if (window != null && (window!.width <= 0 || window!.height <= 0)) {
      throw FormatException('Window dimensions must be positive', sourcePath);
    }
    if (presentation == DocsScreenshotPresentation.card && window != null) {
      throw FormatException(
        'Window dimensions are only valid for window presentation',
        sourcePath,
      );
    }
    if (presentation == DocsScreenshotPresentation.window &&
        window != null &&
        (window!.width > viewport.width || window!.height > viewport.height)) {
      throw FormatException(
        'Window dimensions must fit inside the viewport',
        sourcePath,
      );
    }
    if (callouts.length > 5) {
      throw FormatException(
        'Screenshots support at most five callouts',
        sourcePath,
      );
    }
    for (final callout in callouts) {
      if (callout.label.length > 80 && !callout.manualReview) {
        throw FormatException(
          'Callout "${callout.id}" label is longer than 80 characters',
          sourcePath,
        );
      }
    }
  }

  static String _requiredString(
    Map<String, Object?> json,
    String key,
    String source,
  ) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Missing required string "$key"', source);
  }

  static String? _optionalString(
    Map<String, Object?> json,
    String key,
    String source,
  ) {
    final value = json[key];
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Expected non-empty string "$key"', source);
  }

  static double _requiredNumber(
    Map<String, Object?> json,
    String key,
    String source,
  ) {
    final value = json[key];
    if (value is num) return value.toDouble();
    throw FormatException('Missing required number "$key"', source);
  }

  static double? _optionalNumber(
    Map<String, Object?> json,
    String key,
    String source,
  ) {
    final value = json[key];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    throw FormatException('Expected number "$key"', source);
  }

  static Map<String, Object?> _requiredMap(
    Map<String, Object?> json,
    String key,
    String source,
  ) {
    final value = json[key];
    if (value is Map<String, Object?>) return value;
    if (value is Map) return Map<String, Object?>.from(value);
    throw FormatException('Missing required object "$key"', source);
  }

  static Map<String, Object?> _optionalMap(
    Map<String, Object?> json,
    String key,
  ) {
    final value = json[key];
    if (value == null) return const {};
    if (value is Map<String, Object?>) return value;
    if (value is Map) return Map<String, Object?>.from(value);
    throw FormatException('Expected object "$key"');
  }

  static Map<String, Object?>? _optionalMapOrNull(
    Map<String, Object?> json,
    String key,
  ) {
    final value = json[key];
    if (value == null) return null;
    if (value is Map<String, Object?>) return value;
    if (value is Map) return Map<String, Object?>.from(value);
    throw FormatException('Expected object "$key"');
  }

  static List<Object?> _optionalList(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) return const [];
    if (value is List<Object?>) return value;
    if (value is List) return List<Object?>.from(value);
    throw FormatException('Expected list "$key"');
  }

  static Map<String, Object?> _asMap(
    Object? value,
    String label,
    String source,
  ) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) return Map<String, Object?>.from(value);
    throw FormatException('Expected object for $label', source);
  }
}

class DocsCalloutSpec {
  DocsCalloutSpec({
    required this.id,
    required this.target,
    required this.label,
    required this.placement,
    required this.highlightPadding,
    required this.manualReview,
  });

  final String id;
  final DocsCalloutTarget target;
  final String label;
  final DocsCalloutPlacement placement;
  final double highlightPadding;
  final bool manualReview;

  factory DocsCalloutSpec.fromJson(Map<String, Object?> json, String source) {
    return DocsCalloutSpec(
      id: DocsScreenshotSpec._requiredString(json, 'id', source),
      target: DocsCalloutTarget.fromJson(
        DocsScreenshotSpec._requiredMap(json, 'target', source),
        source,
      ),
      label: DocsScreenshotSpec._requiredString(json, 'label', source),
      placement: DocsCalloutPlacement.parse(
        DocsScreenshotSpec._requiredString(json, 'placement', source),
        source,
      ),
      highlightPadding:
          DocsScreenshotSpec._optionalNumber(
            json,
            'highlightPadding',
            source,
          ) ??
          8,
      manualReview: json['manualReview'] == true,
    );
  }
}

class DocsCalloutTarget {
  DocsCalloutTarget({
    this.key,
    this.text,
    this.tooltip,
    this.semanticsLabel,
    this.bounds,
  }) {
    if (key == null &&
        text == null &&
        tooltip == null &&
        semanticsLabel == null &&
        bounds == null) {
      throw const FormatException(
        'Callout target must define key, text, tooltip, semanticsLabel, or bounds',
      );
    }
  }

  final String? key;
  final String? text;
  final String? tooltip;
  final String? semanticsLabel;
  final Rect? bounds;

  String get description {
    if (key != null) return 'key "$key"';
    if (text != null) return 'text "$text"';
    if (tooltip != null) return 'tooltip "$tooltip"';
    if (semanticsLabel != null) return 'semantics label "$semanticsLabel"';
    return 'explicit bounds $bounds';
  }

  factory DocsCalloutTarget.fromJson(Map<String, Object?> json, String source) {
    final boundsJson = json['bounds'];
    return DocsCalloutTarget(
      key: _optionalString(json, 'key', source),
      text: _optionalString(json, 'text', source),
      tooltip: _optionalString(json, 'tooltip', source),
      semanticsLabel: _optionalString(json, 'semanticsLabel', source),
      bounds: boundsJson == null
          ? null
          : _boundsFromJson(
              DocsScreenshotSpec._asMap(boundsJson, 'bounds', source),
              source,
            ),
    );
  }

  static String? _optionalString(
    Map<String, Object?> json,
    String key,
    String source,
  ) {
    final value = json[key];
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Expected non-empty string "$key"', source);
  }

  static Rect _boundsFromJson(Map<String, Object?> json, String source) {
    return Rect.fromLTWH(
      DocsScreenshotSpec._requiredNumber(json, 'x', source),
      DocsScreenshotSpec._requiredNumber(json, 'y', source),
      DocsScreenshotSpec._requiredNumber(json, 'width', source),
      DocsScreenshotSpec._requiredNumber(json, 'height', source),
    );
  }
}
