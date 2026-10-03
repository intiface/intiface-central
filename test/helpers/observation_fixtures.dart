import 'dart:async';

class ObservationHarness {
  Duration now = Duration.zero;
  ManualObservationTimer? timer;
  Duration? timerInterval;

  Duration readClock() => now;

  Timer createTimer(Duration interval, void Function() callback) {
    timerInterval = interval;
    return timer = ManualObservationTimer(callback);
  }

  void advance(Duration duration) {
    now += duration;
    timer!.fire();
  }
}

class ManualObservationTimer implements Timer {
  final void Function() _callback;
  bool _isActive = true;
  int _tick = 0;

  ManualObservationTimer(this._callback);

  void fire() {
    if (!_isActive) return;
    _tick++;
    _callback();
  }

  @override
  void cancel() {
    _isActive = false;
  }

  @override
  bool get isActive => _isActive;

  @override
  int get tick => _tick;
}
