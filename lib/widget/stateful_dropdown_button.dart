import 'package:flutter/material.dart';

class StatefulDropdownButton<T> extends StatefulWidget {
  final List<T> values;
  final String label;
  final ValueNotifier<T> valueNotifier;
  final bool enabled;
  const StatefulDropdownButton(
      {super.key, required this.label, required this.values, required this.valueNotifier, this.enabled = true});

  @override
  State<StatefulDropdownButton> createState() => _StatefulDropdownButtonState();
}

class _StatefulDropdownButtonState<T> extends State<StatefulDropdownButton<T>> {
  T? dropdownValue;

  _StatefulDropdownButtonState();

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T>(
      value: dropdownValue,
      hint: Text(widget.label),
      icon: const Icon(Icons.arrow_downward),
      elevation: 16,
      style: const TextStyle(color: Colors.deepPurple),
      underline: Container(
        height: 2,
        color: Colors.deepPurpleAccent,
      ),
      onChanged: widget.enabled
          ? (T? value) {
              // This is called when the user selects an item.
              setState(() {
                dropdownValue = value!;
              });
              widget.valueNotifier.value = value!;
            }
          : null,
      items: widget.values.map<DropdownMenuItem<T>>((T value) {
        return DropdownMenuItem<T>(
          value: value,
          child: Text(value.toString()),
        );
      }).toList(),
    );
  }
}
