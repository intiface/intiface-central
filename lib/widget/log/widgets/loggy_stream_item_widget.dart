import 'package:flutter/material.dart';
import 'package:loggy/loggy.dart';

final List<LogRecord> _shownRecords = <LogRecord>[];

class LoggyItemStackWidget extends StatefulWidget {
  const LoggyItemStackWidget(this.record, {super.key});

  final LogRecord record;

  @override
  LoggyItemStackWidgetState createState() => LoggyItemStackWidgetState();
}

class LoggyItemStackWidgetState extends State<LoggyItemStackWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.record.stackTrace == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.only(top: 12.0),
      child: GestureDetector(
        key: ValueKey<DateTime>(widget.record.time),
        onTap: () {
          setState(() {
            if (_shownRecords.contains(widget.record)) {
              _shownRecords.remove(widget.record);
            } else {
              _shownRecords.add(widget.record);
            }
          });
        },
        child: Container(
          color: Colors.transparent,
          child: Column(
            children: [
              Divider(color: Colors.grey.shade600),
              _CollapsableButton(widget.record),
              AnimatedCrossFade(
                firstChild: SizedBox(
                  width: MediaQuery.of(context).size.width,
                ),
                secondChild: _StackList(widget.record),
                duration: const Duration(milliseconds: 250),
                crossFadeState:
                    _shownRecords.contains(widget.record) ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StackList extends StatelessWidget {
  const _StackList(this.record, {super.key});

  final LogRecord record;

  @override
  Widget build(BuildContext context) {
    final List<String> stackLines = record.stackTrace.toString().split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: stackLines.map(
        (String stackTraceLine) {
          final List<String> value = stackTraceLine.replaceAll(RegExp(' +'), '  ').replaceAll(')', '').split('(');

          /// Lines that have no connection to the app will be different color.
          final bool isFlutter = (value.last).startsWith('package:flutter') || (value.last).startsWith('dart:');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                value.first,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.headline6!.copyWith(
                      color: isFlutter ? Colors.blueGrey : Colors.redAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 16.0,
                    ),
              ),
              Text(
                value.last,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.subtitle1!.copyWith(
                      color: isFlutter ? Colors.blueGrey : Colors.redAccent,
                      fontWeight: FontWeight.w400,
                      fontSize: 12.0,
                    ),
              ),
              const SizedBox(
                height: 4.0,
              ),
            ],
          );
        },
      ).toList(),
    );
  }
}

class _CollapsableButton extends StatelessWidget {
  const _CollapsableButton(this.record, {super.key});

  final LogRecord record;

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: SizedBox(
        height: 32.0,
        child: Center(
          child: Text(
            '▼ ${MaterialLocalizations.of(context).collapsedIconTapHint.toUpperCase()} ▼',
            style: Theme.of(context).textTheme.bodyText2!.copyWith(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 16.0,
                ),
          ),
        ),
      ),
      secondChild: SizedBox(
        height: 32.0,
        child: Center(
          child: Text(
            '▲ ${MaterialLocalizations.of(context).expandedIconTapHint.toUpperCase()} ▲',
            style: Theme.of(context).textTheme.bodyText2!.copyWith(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 16.0,
                ),
          ),
        ),
      ),
      duration: const Duration(milliseconds: 250),
      crossFadeState: _shownRecords.contains(record) ? CrossFadeState.showSecond : CrossFadeState.showFirst,
    );
  }
}
