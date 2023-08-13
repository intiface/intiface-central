import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_loggy/flutter_loggy.dart';
import 'package:loggy/loggy.dart';
import 'package:intiface_central/util/intiface_util.dart';

// From https://github.com/infinum/floggy/issues/50
class FileOutput extends LoggyPrinter {
  FileOutput() : super() {
    _sink = IntifacePaths.logFile.openWrite(
      mode: FileMode.writeOnly,
      encoding: utf8,
    );
  }
  IOSink? _sink;

  @override
  void onLog(LogRecord record) async {
    _sink?.writeln(record.toString());
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

  void addGUIPrinter() {
    _printers.add(const PrettyDeveloperPrinter());
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
    logPrinter: StreamPrinter(multiPrinter),
    logOptions: const LogOptions(
      LogLevel.all,
      stackTraceLevel: LogLevel.error,
    ),
  );
}
