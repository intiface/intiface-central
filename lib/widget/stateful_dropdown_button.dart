import 'package:flutter/material.dart';

class StatefulDropdownButton<T> extends StatefulWidget {
  final List<T> values;
  final String label;
  final ValueNotifier<T> valueNotifier;
  final bool enabled;
  const StatefulDropdownButton({
    super.key,
    required this.label,
    required this.values,
    required this.valueNotifier,
    this.enabled = true,
  });

  @override
  State<StatefulDropdownButton<T>> createState() =>
      _StatefulDropdownButtonState<T>();
}

class _StatefulDropdownButtonState<T> extends State<StatefulDropdownButton<T>> {
  T? dropdownValue;

  _StatefulDropdownButtonState();

  T? _valueIfPresent(T value) {
    return widget.values.contains(value) ? value : null;
  }

  void _onNotifierChanged() {
    final value = _valueIfPresent(widget.valueNotifier.value);
    if (value == dropdownValue) return;
    setState(() {
      dropdownValue = value;
    });
  }

  @override
  void initState() {
    super.initState();
    dropdownValue = _valueIfPresent(widget.valueNotifier.value);
    widget.valueNotifier.addListener(_onNotifierChanged);
  }

  @override
  void didUpdateWidget(StatefulDropdownButton<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valueNotifier != widget.valueNotifier) {
      oldWidget.valueNotifier.removeListener(_onNotifierChanged);
      widget.valueNotifier.addListener(_onNotifierChanged);
      dropdownValue = _valueIfPresent(widget.valueNotifier.value);
    } else if (!widget.values.contains(dropdownValue)) {
      dropdownValue = null;
    }
  }

  @override
  void dispose() {
    widget.valueNotifier.removeListener(_onNotifierChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        enabled: widget.enabled,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: dropdownValue,
          isExpanded: true,
          isDense: true,
          onChanged: widget.enabled
              ? (T? value) {
                  setState(() {
                    dropdownValue = value as T;
                  });
                  widget.valueNotifier.value = value as T;
                }
              : null,
          items: widget.values.map<DropdownMenuItem<T>>((T value) {
            return DropdownMenuItem<T>(
              value: value,
              child: Text(value.toString()),
            );
          }).toList(),
        ),
      ),
    );
  }
}
