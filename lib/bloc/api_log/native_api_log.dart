import 'dart:async';
import 'dart:convert';

import 'package:intiface_central/bloc/engine/engine_messages.dart';
import 'package:intiface_central/src/rust/api/util.dart';
import 'package:loggy/loggy.dart';

class NativeApiLog {
  static final NativeApiLog _instance = NativeApiLog._internal();
  late Stream<String> _logStream;
  final StreamController<EngineLogMessage> _logMessageStream = StreamController();

  factory NativeApiLog() {
    return _instance;
  }

  NativeApiLog._internal() {
    _logStream = setupLogging();
    _logStream.listen((element) {
      try {
        var logMsg = EngineLogMessage.fromJson(jsonDecode(element));
        _logMessageStream.add(logMsg);
      } catch (e, s) {
        logError("Error adding message to stream: $e");
        logError(s);
      }
    });
  }

  Stream<EngineLogMessage> get logMessageStream => _logMessageStream.stream;
}
