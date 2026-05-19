import 'dart:async';
import 'dart:collection';
import 'package:bloc/bloc.dart';
import 'package:intiface_central/bloc/engine/engine_messages.dart';

class ObservationState {
  final List<double> values;

  ObservationState(this.values);
}

class ObservationCubit extends Cubit<ObservationState> {
  static const int bufferSize = 100;

  final int deviceIndex;
  final int featureIndex;
  final int maxSteps;
  final Queue<double> _buffer = Queue.of(List.filled(bufferSize, 0.0));
  StreamSubscription<DeviceOutputObservation>? _subscription;
  Timer? _tickTimer;
  double _lastValue = 0.0;

  ObservationCubit({
    required this.deviceIndex,
    required this.featureIndex,
    required this.maxSteps,
    required Stream<DeviceOutputObservation> observationStream,
  }) : super(ObservationState(List.filled(bufferSize, 0.0))) {
    _subscription = observationStream
        .where((obs) =>
            obs.deviceIndex == deviceIndex &&
            obs.featureIndex == featureIndex)
        .listen(_onObservation);

    _startTimer();
  }

  void _onObservation(DeviceOutputObservation obs) {
    final normalized = maxSteps > 0 ? obs.value / maxSteps : 0.0;
    _lastValue = normalized.clamp(0.0, 1.0);
    _push(_lastValue);
    _restartTimer();
  }

  void _startTimer() {
    _tickTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _tick(),
    );
  }

  void _restartTimer() {
    _tickTimer?.cancel();
    _startTimer();
  }

  void _tick() {
    if (isClosed) return;
    _push(_lastValue);
  }

  void _push(double value) {
    if (isClosed) return;
    _buffer.removeLast();
    _buffer.addFirst(value);
    emit(ObservationState(List.unmodifiable(_buffer.toList())));
  }

  @override
  Future<void> close() {
    _tickTimer?.cancel();
    _subscription?.cancel();
    return super.close();
  }
}
