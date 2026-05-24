import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/bloc/util/asset_cubit.dart';
import 'package:intiface_central/widget/body_widget.dart';
import 'package:intiface_central/widget/control_widget.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;

import '../helpers/fake_blocs.dart';
import '../helpers/mocks.dart';
import '../helpers/pump_app.dart';
import 'docs_screenshot_spec.dart';

const _artifactDirectory = 'docs/assets/screenshots/generated';
const _calloutColors = [
  Color(0xff0f6cbd),
  Color(0xffb45309),
  Color(0xff0f766e),
  Color(0xff7c3aed),
  Color(0xffbe123c),
];
const _calloutTextStyle = TextStyle(
  color: Color(0xff17202a),
  fontFamily: 'Roboto',
  fontSize: 18,
  fontWeight: FontWeight.w600,
  height: 1.25,
);
const _defaultStartupNewsMarkdown = '''
# Intiface News

Welcome to Intiface Central. News and update notes appear here.
''';

class DocsWidgetScreenshotGenerator {
  DocsWidgetScreenshotGenerator(this.spec);

  final DocsScreenshotSpec spec;

  Future<void> generate(WidgetTester tester) async {
    if (spec.mode != DocsScreenshotMode.widget) {
      throw TestFailure(
        'Spec ${spec.id} is ${spec.mode.name}, not widget mode',
      );
    }

    _setViewport(tester);

    final rawBoundaryKey = GlobalKey();
    await _pumpSpec(tester, rawBoundaryKey, const []);
    await _writeBoundaryPng(
      tester,
      rawBoundaryKey,
      p.join(_artifactDirectory, '${spec.id}.png'),
      pixelRatio: spec.pixelRatio,
    );

    if (spec.callouts.isEmpty) return;

    final targetRects = _resolveCalloutTargets(tester);
    final laidOutCallouts = _layoutCallouts(targetRects);

    final calloutBoundaryKey = GlobalKey();
    await _pumpSpec(tester, calloutBoundaryKey, laidOutCallouts);
    await _writeBoundaryPng(
      tester,
      calloutBoundaryKey,
      p.join(_artifactDirectory, '${spec.id}-callouts.png'),
      pixelRatio: spec.pixelRatio,
    );
  }

  void _setViewport(WidgetTester tester) {
    tester.view.physicalSize = spec.viewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> _pumpSpec(
    WidgetTester tester,
    GlobalKey boundaryKey,
    List<DocsLaidOutCallout> callouts,
  ) async {
    await pumpApp(
      tester,
      windowSize: spec.viewport,
      child: DocsScreenshotFrame(
        boundaryKey: boundaryKey,
        viewport: spec.viewport,
        presentation: spec.presentation,
        background: spec.background,
        window: spec.window,
        callouts: callouts,
        child: _buildEntrypoint(),
      ),
      engineControlBloc: _engineBlocForFixture(),
      configCubit: _configCubitForFixture(),
      assetCubit: _assetCubitForFixture(),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Widget _buildEntrypoint() {
    return switch (spec.entrypoint) {
      'controlWidget' => const ControlWidget(),
      'desktopStartup' || 'mobileStartup' => const Scaffold(
        body: Column(
          children: [
            ControlWidget(),
            Divider(height: 2),
            Expanded(child: BodyWidget()),
          ],
        ),
      ),
      _ => throw TestFailure(
        'Unsupported widget screenshot entrypoint "${spec.entrypoint}" '
        'in ${spec.sourcePath}',
      ),
    };
  }

  EngineControlBloc _engineBlocForFixture() {
    final engineBloc = MockEngineControlBloc();
    final engineFixture = spec.fixture['engine'] as String? ?? 'stopped';

    final EngineControlState state;
    final bool isRunning;
    switch (engineFixture) {
      case 'stopped':
        state = EngineStoppedState();
        isRunning = false;
      case 'starting':
        state = EngineStartingState();
        isRunning = true;
      case 'running':
        state = EngineStartedState();
        isRunning = true;
      case 'clientConnected':
        state = ClientConnectedState(
          spec.fixture['clientName'] as String? ?? 'Test App',
        );
        isRunning = true;
      default:
        throw TestFailure(
          'Unsupported engine fixture "$engineFixture" in ${spec.sourcePath}',
        );
    }

    when(() => engineBloc.state).thenReturn(state);
    when(() => engineBloc.isRunning).thenReturn(isRunning);
    return engineBloc;
  }

  IntifaceConfigurationCubit _configCubitForFixture() {
    final configCubit = MockIntifaceConfigurationCubit();
    stubConfigurationCubit(
      configCubit,
      useCompactDisplay: spec.fixture['useCompactDisplay'] as bool? ?? false,
      useSideNavigationBar:
          spec.fixture['useSideNavigationBar'] as bool? ?? true,
      websocketServerAllInterfaces:
          spec.fixture['websocketServerAllInterfaces'] as bool? ?? false,
      websocketServerPort: spec.fixture['websocketServerPort'] as int? ?? 12345,
      currentAppVersion:
          spec.fixture['currentAppVersion'] as String? ?? '3.0.0',
      latestAppVersion: spec.fixture['latestAppVersion'] as String? ?? '3.0.0',
      appMode: _appModeForFixture(),
    );
    return configCubit;
  }

  AppMode _appModeForFixture() {
    return switch (spec.fixture['appMode'] as String? ?? 'engine') {
      'engine' => AppMode.engine,
      'repeater' => AppMode.repeater,
      'restApi' => AppMode.restApi,
      final value => throw TestFailure(
        'Unsupported appMode fixture "$value" in ${spec.sourcePath}',
      ),
    };
  }

  AssetCubit _assetCubitForFixture() {
    final newsMarkdown =
        spec.fixture['newsMarkdown'] as String? ?? _defaultStartupNewsMarkdown;
    final aboutMarkdown = spec.fixture['aboutMarkdown'] as String? ?? '';
    return AssetCubit(newsMarkdown, aboutMarkdown);
  }

  List<Rect> _resolveCalloutTargets(WidgetTester tester) {
    final screenRect = Offset.zero & spec.viewport;

    return spec.callouts.map((callout) {
      final rect = _resolveTargetRect(tester, callout);
      if (rect.isEmpty || !rect.overlaps(screenRect)) {
        throw TestFailure(
          'Callout "${callout.id}" in ${spec.sourcePath} resolved offscreen '
          'or empty target ${callout.target.description}: $rect',
        );
      }
      return rect;
    }).toList();
  }

  Rect _resolveTargetRect(WidgetTester tester, DocsCalloutSpec callout) {
    if (callout.target.bounds != null) return callout.target.bounds!;

    final finder = _finderForTarget(callout.target);
    final matches = finder.evaluate().toList();
    if (matches.length != 1) {
      throw TestFailure(
        'Callout "${callout.id}" in ${spec.sourcePath} target '
        '${callout.target.description} resolved ${matches.length} widgets; '
        'expected exactly one.',
      );
    }
    return tester.getRect(finder);
  }

  Finder _finderForTarget(DocsCalloutTarget target) {
    if (target.key != null) {
      return find.byKey(ValueKey<String>(target.key!));
    }
    if (target.text != null) return find.text(target.text!);
    if (target.tooltip != null) return find.byTooltip(target.tooltip!);
    if (target.semanticsLabel != null) {
      return find.bySemanticsLabel(target.semanticsLabel!);
    }
    throw TestFailure('Explicit bounds target does not need a Finder');
  }

  List<DocsLaidOutCallout> _layoutCallouts(List<Rect> targetRects) {
    final labels = <Rect>[];
    final laidOut = <DocsLaidOutCallout>[];

    for (var index = 0; index < spec.callouts.length; index += 1) {
      final callout = spec.callouts[index];
      final targetRect = targetRects[index];
      final labelSize = _measureLabel(callout.label);
      final labelRect = _placeLabel(targetRect, labelSize, callout);

      if (_isOffscreen(labelRect)) {
        throw TestFailure(
          'Callout "${callout.id}" in ${spec.sourcePath} placed label '
          'outside the viewport: $labelRect',
        );
      }
      if (labelRect.overlaps(targetRect.inflate(8))) {
        throw TestFailure(
          'Callout "${callout.id}" in ${spec.sourcePath} label overlaps '
          'its target.',
        );
      }
      for (final previousLabel in labels) {
        if (labelRect.inflate(8).overlaps(previousLabel.inflate(8))) {
          throw TestFailure(
            'Callout "${callout.id}" in ${spec.sourcePath} label overlaps '
            'another callout label.',
          );
        }
      }

      labels.add(labelRect);
      laidOut.add(
        DocsLaidOutCallout(
          number: index + 1,
          label: callout.label,
          placement: callout.placement,
          targetRect: targetRect,
          highlightPadding: callout.highlightPadding,
          labelRect: labelRect,
          markerCenter: _markerCenter(targetRect, callout.placement),
          leaderEnd: _leaderEnd(labelRect, callout.placement),
          color: _calloutColors[index % _calloutColors.length],
        ),
      );
    }

    return laidOut;
  }

  Size _measureLabel(String label) {
    const horizontalPadding = 28.0;
    const verticalPadding = 18.0;
    final painter = TextPainter(
      text: TextSpan(text: label, style: _calloutTextStyle),
      textDirection: TextDirection.ltr,
    );
    painter.layout(maxWidth: 272);

    final width = math.max(220.0, painter.width + horizontalPadding);
    return Size(math.min(320.0, width), painter.height + verticalPadding);
  }

  Rect _placeLabel(Rect targetRect, Size labelSize, DocsCalloutSpec callout) {
    const gap = 70.0;
    double left;
    double top;

    switch (callout.placement) {
      case DocsCalloutPlacement.left:
        left = targetRect.left - gap - labelSize.width;
        top = targetRect.center.dy - labelSize.height / 2;
      case DocsCalloutPlacement.right:
        left = targetRect.right + gap;
        top = targetRect.center.dy - labelSize.height / 2;
      case DocsCalloutPlacement.top:
        left = targetRect.center.dx - labelSize.width / 2;
        top = targetRect.top - gap - labelSize.height;
      case DocsCalloutPlacement.bottom:
        left = targetRect.center.dx - labelSize.width / 2;
        top = targetRect.bottom + gap;
    }

    const margin = 24.0;
    if (labelSize.width > spec.viewport.width - margin * 2 ||
        labelSize.height > spec.viewport.height - margin * 2) {
      throw TestFailure(
        'Callout "${callout.id}" in ${spec.sourcePath} label is too large '
        'for the viewport.',
      );
    }

    left = _clamp(left, margin, spec.viewport.width - margin - labelSize.width);
    top = _clamp(top, margin, spec.viewport.height - margin - labelSize.height);
    return Rect.fromLTWH(left, top, labelSize.width, labelSize.height);
  }

  Offset _markerCenter(Rect targetRect, DocsCalloutPlacement placement) {
    const markerGap = 22.0;
    return switch (placement) {
      DocsCalloutPlacement.left => Offset(
        targetRect.left - markerGap,
        targetRect.center.dy,
      ),
      DocsCalloutPlacement.right => Offset(
        targetRect.right + markerGap,
        targetRect.center.dy,
      ),
      DocsCalloutPlacement.top => Offset(
        targetRect.center.dx,
        targetRect.top - markerGap,
      ),
      DocsCalloutPlacement.bottom => Offset(
        targetRect.center.dx,
        targetRect.bottom + markerGap,
      ),
    };
  }

  Offset _leaderEnd(Rect labelRect, DocsCalloutPlacement placement) {
    return switch (placement) {
      DocsCalloutPlacement.left => Offset(labelRect.right, labelRect.center.dy),
      DocsCalloutPlacement.right => Offset(labelRect.left, labelRect.center.dy),
      DocsCalloutPlacement.top => Offset(labelRect.center.dx, labelRect.bottom),
      DocsCalloutPlacement.bottom => Offset(labelRect.center.dx, labelRect.top),
    };
  }

  bool _isOffscreen(Rect rect) {
    const margin = 0.5;
    return rect.left < margin ||
        rect.top < margin ||
        rect.right > spec.viewport.width - margin ||
        rect.bottom > spec.viewport.height - margin;
  }

  double _clamp(double value, double min, double max) {
    return value.clamp(min, max).toDouble();
  }
}

class DocsScreenshotFrame extends StatelessWidget {
  const DocsScreenshotFrame({
    super.key,
    required this.boundaryKey,
    required this.viewport,
    required this.presentation,
    required this.background,
    required this.window,
    required this.callouts,
    required this.child,
  });

  final GlobalKey boundaryKey;
  final Size viewport;
  final DocsScreenshotPresentation presentation;
  final DocsScreenshotBackground background;
  final Size? window;
  final List<DocsLaidOutCallout> callouts;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenshotTheme = theme.copyWith(
      textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
      primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Roboto'),
    );

    return Theme(
      data: screenshotTheme,
      child: RepaintBoundary(
        key: boundaryKey,
        child: SizedBox.fromSize(
          size: viewport,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (background == DocsScreenshotBackground.solid)
                const ColoredBox(color: Color(0xfff5f7fb)),
              _buildPresentedChild(context, screenshotTheme),
              if (callouts.isNotEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: DocsCalloutPainter(callouts)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresentedChild(BuildContext context, ThemeData screenshotTheme) {
    return switch (presentation) {
      DocsScreenshotPresentation.card => Center(
        child: SizedBox(
          width: 720,
          child: Material(
            color: screenshotTheme.colorScheme.surface,
            elevation: 2,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: screenshotTheme.colorScheme.outlineVariant,
                ),
              ),
              child: Padding(padding: const EdgeInsets.all(32), child: child),
            ),
          ),
        ),
      ),
      DocsScreenshotPresentation.window => Center(
        child: SizedBox.fromSize(
          size: window ?? viewport,
          child: Material(
            color: screenshotTheme.colorScheme.surface,
            elevation: 3,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: screenshotTheme.colorScheme.outlineVariant,
                ),
              ),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(size: window ?? viewport),
                child: child,
              ),
            ),
          ),
        ),
      ),
    };
  }
}

class DocsLaidOutCallout {
  DocsLaidOutCallout({
    required this.number,
    required this.label,
    required this.placement,
    required this.targetRect,
    required this.highlightPadding,
    required this.labelRect,
    required this.markerCenter,
    required this.leaderEnd,
    required this.color,
  });

  final int number;
  final String label;
  final DocsCalloutPlacement placement;
  final Rect targetRect;
  final double highlightPadding;
  final Rect labelRect;
  final Offset markerCenter;
  final Offset leaderEnd;
  final Color color;
}

class DocsCalloutPainter extends CustomPainter {
  DocsCalloutPainter(this.callouts);

  final List<DocsLaidOutCallout> callouts;

  @override
  void paint(Canvas canvas, Size size) {
    final labelFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final labelStroke = Paint()
      ..color = const Color(0xffcbd5e1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final callout in callouts) {
      final highlightRect = callout.targetRect.inflate(
        callout.highlightPadding,
      );
      final highlightPaint = Paint()
        ..color = callout.color.withValues(alpha: 0.10)
        ..style = PaintingStyle.fill;
      final highlightStroke = Paint()
        ..color = callout.color.withValues(alpha: 0.80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final leaderPaint = Paint()
        ..color = callout.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      final highlight = RRect.fromRectAndRadius(
        highlightRect,
        const Radius.circular(12),
      );
      canvas.drawRRect(highlight, highlightPaint);
      canvas.drawRRect(highlight, highlightStroke);
      canvas.drawLine(callout.markerCenter, callout.leaderEnd, leaderPaint);

      final labelRRect = RRect.fromRectAndRadius(
        callout.labelRect,
        const Radius.circular(8),
      );
      canvas.drawShadow(Path()..addRRect(labelRRect), Colors.black, 4, false);
      canvas.drawRRect(labelRRect, labelFill);
      canvas.drawRRect(labelRRect, labelStroke);

      final labelPainter = TextPainter(
        text: TextSpan(text: callout.label, style: _calloutTextStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: callout.labelRect.width - 28);
      labelPainter.paint(
        canvas,
        callout.labelRect.topLeft + const Offset(14, 9),
      );

      canvas.drawCircle(
        callout.markerCenter,
        19,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        callout.markerCenter,
        16,
        Paint()..color = callout.color,
      );

      final numberPainter = TextPainter(
        text: TextSpan(
          text: '${callout.number}',
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      numberPainter.paint(
        canvas,
        callout.markerCenter -
            Offset(numberPainter.width / 2, numberPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(DocsCalloutPainter oldDelegate) {
    return oldDelegate.callouts != callouts;
  }
}

Future<void> _writeBoundaryPng(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String outputPath, {
  required double pixelRatio,
}) async {
  final context = boundaryKey.currentContext;
  if (context == null) {
    throw TestFailure('Screenshot boundary was not mounted for $outputPath');
  }

  final boundary = context.findRenderObject();
  if (boundary is! RenderRepaintBoundary) {
    throw TestFailure('Screenshot boundary is not a RepaintBoundary');
  }

  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw TestFailure('Unable to encode screenshot PNG $outputPath');
    }

    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(byteData.buffer.asUint8List());
  });
}
