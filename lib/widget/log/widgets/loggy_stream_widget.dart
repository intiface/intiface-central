import 'package:flutter/material.dart';
import 'package:flutter_loggy/flutter_loggy.dart';
import 'package:intiface_central/util/logging.dart';
import 'package:loggy/loggy.dart';

class WrongPrinterException implements Exception {
  WrongPrinterException();

  @override
  String toString() {
    return 'ERROR: Loggy printer is not set as StreamPrinter!\n\n';
  }
}

/// This widget will display log from Loggy in a widget.
/// Widget needs [StreamPrinter] set as printer on loggy.
///
/// ```dart
/// Loggy.initLoggy(
///   logPrinter: StreamPrinter(PrettyDeveloperPrinter()),
/// );
/// ```
class LoggyStreamWidget extends StatelessWidget {
  const LoggyStreamWidget({
    this.logLevel = LogLevel.all,
    super.key,
  });

  final LogLevel? logLevel;

  @override
  Widget build(BuildContext context) {
    final IntifaceStreamPrinter? printer =
        Loggy.currentPrinter is IntifaceStreamPrinter ? Loggy.currentPrinter as IntifaceStreamPrinter? : null;

    if (printer == null) {
      throw WrongPrinterException();
    }

    return Column(
      children: <Widget>[
        Expanded(
          child: StreamBuilder<List<LogRecord>>(
            stream: printer.logRecord,
            builder: (BuildContext context, AsyncSnapshot<List<LogRecord>> records) {
              if (!records.hasData) {
                return Container();
              }

              return ListView(
                reverse: true,
                children: records.data!
                    .where((LogRecord record) => record.level.priority >= logLevel!.priority)
                    .map((LogRecord record) => _LoggyItemWidget(record))
                    .toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LoggyItemWidget extends StatelessWidget {
  const _LoggyItemWidget(this.record, {super.key});

  final LogRecord record;

  @override
  Widget build(BuildContext context) {
    final Color logColor = _getLogColor();
    final Color dividerColor = ThemeData.dark().dividerColor;
    return Container(
      color: Colors.transparent,
      //padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: logColor),
                    ),
                  )),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: FittedBox(
                      alignment: Alignment.topLeft,
                      child: Text(
                        (record.object! as RecordMetadata).elapsed.toStringAsFixed(3),
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: logColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.0,
                            ),
                        //),
                      ))),
              Expanded(
                child: Text(
                  record.message,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: _getTextWeight(),
                        fontSize: 12.0,
                      ),
                ),
              ),
            ],
          ),
          //const SizedBox(height: 12.0),
          //LoggyItemStackWidget(record),
          Divider(color: dividerColor),
        ],
      ),
    );
  }

  FontWeight _getTextWeight() {
    switch (record.level) {
      case LogLevel.error:
        return FontWeight.w700;
      case LogLevel.debug:
        return FontWeight.w300;
      case LogLevel.info:
        return FontWeight.w400;
      case LogLevel.warning:
        return FontWeight.w500;
    }

    return FontWeight.w300;
  }

  Color _getLogColor() {
    switch (record.level) {
      case LogLevel.error:
        return Colors.redAccent;
      case LogLevel.debug:
        return Colors.lightBlue;
      case LogLevel.info:
        return Colors.lightGreen;
      case LogLevel.warning:
        return Colors.yellow;
    }

    return Colors.white;
  }
}
