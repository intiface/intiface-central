import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_loggy/flutter_loggy.dart';
import 'package:loggy/loggy.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:rxdart/rxdart.dart';

class RecordMetadata {
  //final Map<String, String> _tags = {};
  final double _elapsed;

  RecordMetadata(this._elapsed);

  double get elapsed => _elapsed;
}

/// Stream printer will take another [LoggyPrinter] as it's [childPrinter] all logs will
/// pass through [childPrinter] as well.
///
/// This allows [LoggyStreamWidget] to display logs as well.
class IntifaceStreamPrinter extends LoggyPrinter {
  static final DateTime _appStartTime = DateTime.now();

  IntifaceStreamPrinter(this.childPrinter) : super();

  final LoggyPrinter childPrinter;
  final BehaviorSubject<List<LogRecord>> logRecord = BehaviorSubject<List<LogRecord>>.seeded(<LogRecord>[]);

  @override
  void onLog(LogRecord record) {
    late List<LogRecord> existingRecord;
    try {
      existingRecord = logRecord.value;
    } on ValueStreamError {
      existingRecord = <LogRecord>[];
    }

    LogRecord newRecord = LogRecord(
        record.level,
        record.message,
        record.loggerName,
        record.error,
        record.stackTrace,
        record.zone,
        RecordMetadata(DateTime.now().difference(_appStartTime).inMilliseconds / 1000.0),
        record.callerFrame);

    childPrinter.onLog(newRecord);
    logRecord.add(<LogRecord>[
      newRecord,
      ...existingRecord,
    ]);
  }

  void dispose() {
    logRecord.close();
  }
}

// From https://github.com/infinum/floggy/issues/50
class FileOutput extends LoggyPrinter {
  static final DateTime _appStartTime = DateTime.now();

  FileOutput() : super() {
    _sink = IntifacePaths.logFile.openWrite(
      mode: FileMode.writeOnly,
      encoding: utf8,
    );
  }
  IOSink? _sink;

  @override
  void onLog(LogRecord record) async {
    var logString =
        "${DateTime.now().difference(_appStartTime).inMilliseconds / 1000.0} : [${record.level.toString().substring(0, 1)}] : ${record.message}";
    _sink?.writeln(logString);
  }
}

class ErrorNotifier extends LoggyPrinter {
  ErrorNotifier() : super();

  final StreamController<LogRecord> _errorStream = StreamController();

  Stream<LogRecord> get stream => _errorStream.stream;

  @override
  void onLog(LogRecord record) async {
    if (record.level == LogLevel.error) {
      if (_errorStream.hasListener) {
        _errorStream.add(record);
      }
    }
  }
}

class MultiPrinter extends LoggyPrinter {
  MultiPrinter(ErrorNotifier errorNotifier) {
    _printers.add(errorNotifier);
    if (!kReleaseMode) {
      _printers.add(const PrettyPrinter());
    }
  }

  final List<LoggyPrinter> _printers = [];

  void addFilePrinter() {
    _printers.add(FileOutput());
  }

  @override
  void onLog(LogRecord record) {
    for (var printer in _printers) {
      printer.onLog(record);
    }
  }
}

void initLogging(MultiPrinter multiPrinter) {
  Loggy.initLoggy(
    logPrinter: IntifaceStreamPrinter(multiPrinter),
    logOptions: const LogOptions(
      LogLevel.all,
      stackTraceLevel: LogLevel.error,
    ),
  );
}
