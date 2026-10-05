import 'dart:async';
import 'dart:collection';

import 'package:bloc/bloc.dart';
import 'package:intiface_central/bloc/engine/engine_messages.dart';

typedef ObservationClock = Duration Function();
typedef ObservationTimerFactory =
    Timer Function(Duration interval, void Function() callback);

class ObservationSample {
  final Duration timestamp;
  final double value;

  const ObservationSample({required this.timestamp, required this.value});
}

class ObservationState {
  final List<ObservationSample> samples;
  final Duration windowEnd;

  const ObservationState({required this.samples, required this.windowEnd});

  double get currentValue => samples.isEmpty ? 0.0 : samples.last.value;

  double secondsFromWindowEnd(ObservationSample sample) {
    return (sample.timestamp - windowEnd).inMicroseconds /
        Duration.microsecondsPerSecond;
  }
}

class ObservationCubit extends Cubit<ObservationState> {
  static const Duration historyWindow = Duration(seconds: 10);
  static const Duration presentationInterval = Duration(microseconds: 16667);
  static const int maxHistorySamples = 1200;

  final int deviceIndex;
  final int featureIndex;
  final int minSteps;
  final int maxSteps;
  final ObservationClock _clock;
  final ObservationTimerFactory _timerFactory;
  final Queue<ObservationSample> _history = Queue<ObservationSample>();
  StreamSubscription<DeviceOutputObservation>? _subscription;
  Timer? _tickTimer;
  Duration _lastTimestamp = Duration.zero;
  double _currentValue = 0.0;

  ObservationCubit({
    required this.deviceIndex,
    required this.featureIndex,
    this.minSteps = 0,
    required this.maxSteps,
    required Stream<DeviceOutputObservation> observationStream,
    ObservationClock? clock,
    ObservationTimerFactory? timerFactory,
  }) : _clock = clock ?? _createClock(),
       _timerFactory = timerFactory ?? _createTimer,
       super(const ObservationState(samples: [], windowEnd: Duration.zero)) {
    final now = _now();
    _history
      ..add(
        ObservationSample(timestamp: now - historyWindow, value: _currentValue),
      )
      ..add(ObservationSample(timestamp: now, value: _currentValue));
    _emitState(now);

    _subscription = observationStream
        .where(
          (obs) =>
              obs.deviceIndex == deviceIndex &&
              obs.featureIndex == featureIndex,
        )
        .listen(_onObservation);

    _tickTimer = _timerFactory(presentationInterval, _tick);
  }

  void _onObservation(DeviceOutputObservation obs) {
    if (isClosed) return;

    final normalized = maxSteps > 0 ? obs.value / maxSteps : 0.0;
    _currentValue = normalized.clamp(minValue, 1.0);
  }

  static ObservationClock _createClock() {
    final stopwatch = Stopwatch()..start();
    return () => stopwatch.elapsed;
  }

  static Timer _createTimer(Duration interval, void Function() callback) {
    return Timer.periodic(interval, (_) => callback());
  }

  void _tick() {
    if (isClosed) return;

    final now = _now();
    _history.add(ObservationSample(timestamp: now, value: _currentValue));
    _pruneHistory(now);
    _emitState(now);
  }

  Duration _now() {
    final timestamp = _clock();
    if (timestamp < _lastTimestamp) {
      return _lastTimestamp;
    }
    _lastTimestamp = timestamp;
    return timestamp;
  }

  void _pruneHistory(Duration now) {
    final cutoff = now - historyWindow;
    while (_history.length > 2 && _history.elementAt(1).timestamp < cutoff) {
      _history.removeFirst();
    }
    while (_history.length > maxHistorySamples) {
      if (_history.first.timestamp < cutoff) {
        // Keep the window-edge sample so the line still reaches the left edge.
        _history.remove(_history.elementAt(1));
      } else {
        _history.removeFirst();
      }
    }
  }

  void _emitState(Duration now) {
    if (isClosed) return;
    emit(
      ObservationState(
        samples: List<ObservationSample>.unmodifiable(_history),
        windowEnd: now,
      ),
    );
  }

  double get minValue =>
      maxSteps > 0 ? (minSteps / maxSteps).clamp(-1.0, 0.0) : 0.0;

  @override
  Future<void> close() async {
    _tickTimer?.cancel();
    await _subscription?.cancel();
    await super.close();
  }
}
