import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/widget/control_widget.dart';

import '../helpers/mocks.dart';
import '../helpers/pump_app.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(EngineControlEventStop());
  });

  group('ControlWidget', () {
    testWidgets('shows Start Server tooltip when engine stopped', (
      tester,
    ) async {
      await pumpApp(tester, child: const ControlWidget());
      expect(find.byTooltip('Start Server'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('shows Stop Server tooltip when engine started', (
      tester,
    ) async {
      final engineBloc = MockEngineControlBloc();
      when(() => engineBloc.state).thenReturn(EngineStartedState());
      when(() => engineBloc.isRunning).thenReturn(true);

      await pumpApp(
        tester,
        child: const ControlWidget(),
        engineControlBloc: engineBloc,
      );
      expect(find.byTooltip('Stop Server'), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);
    });

    testWidgets('shows status text for stopped state', (tester) async {
      await pumpApp(tester, child: const ControlWidget());
      expect(find.text('Engine not running'), findsOneWidget);
    });

    testWidgets('shows status text for started state', (tester) async {
      final engineBloc = MockEngineControlBloc();
      when(() => engineBloc.state).thenReturn(EngineStartedState());
      when(() => engineBloc.isRunning).thenReturn(true);

      await pumpApp(
        tester,
        child: const ControlWidget(),
        engineControlBloc: engineBloc,
      );
      expect(find.text('Engine running, waiting for client'), findsOneWidget);
    });

    testWidgets('shows client name when client connected', (tester) async {
      final engineBloc = MockEngineControlBloc();
      when(() => engineBloc.state).thenReturn(ClientConnectedState('Test App'));
      when(() => engineBloc.isRunning).thenReturn(true);

      await pumpApp(
        tester,
        child: const ControlWidget(),
        engineControlBloc: engineBloc,
      );
      expect(find.text('Test App connected'), findsOneWidget);
    });

    testWidgets('shows starting text when engine starting', (tester) async {
      final engineBloc = MockEngineControlBloc();
      when(() => engineBloc.state).thenReturn(EngineStartingState());
      when(() => engineBloc.isRunning).thenReturn(true);

      await pumpApp(
        tester,
        child: const ControlWidget(),
        engineControlBloc: engineBloc,
      );
      expect(find.text('Engine starting...'), findsOneWidget);
    });

    testWidgets('stop button dispatches EngineControlEventStop', (
      tester,
    ) async {
      final engineBloc = MockEngineControlBloc();
      when(() => engineBloc.state).thenReturn(EngineStartedState());
      when(() => engineBloc.isRunning).thenReturn(true);

      await pumpApp(
        tester,
        child: const ControlWidget(),
        engineControlBloc: engineBloc,
      );

      await tester.tap(find.byTooltip('Stop Server'));
      verify(
        () => engineBloc.add(any(that: isA<EngineControlEventStop>())),
      ).called(1);
    });

    testWidgets('shows server address when in engine mode', (tester) async {
      await pumpApp(tester, child: const ControlWidget());
      expect(find.text('Server Address:'), findsOneWidget);
      expect(find.text('ws://localhost:12345'), findsOneWidget);
    });

    testWidgets('shows port in use dialog on engine error', (tester) async {
      final engineBloc = MockEngineControlBloc();
      when(() => engineBloc.state).thenReturn(EngineStartedState());
      when(() => engineBloc.isRunning).thenReturn(true);
      whenListen(
        engineBloc,
        Stream<EngineControlState>.fromIterable([
          EnginePortInUseState(
            'Port already in use',
            port: 12345,
            address: '127.0.0.1',
          ),
        ]),
        initialState: EngineStartedState(),
      );

      await pumpApp(
        tester,
        child: const ControlWidget(),
        engineControlBloc: engineBloc,
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Port in use'), findsOneWidget);
      expect(find.text('Open Troubleshooting'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('Port already in use'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('127.0.0.1'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('Port: 12345'),
        ),
        findsOneWidget,
      );
    });
  });
}
