import 'package:flutter/material.dart';

class FormPanel extends StatelessWidget {
  final List<Widget> children;
  final double maxWidth;

  const FormPanel({super.key, required this.children, this.maxWidth = 600});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Align(
        alignment: Alignment.topCenter,
        // Inside a scroll view the vertical axis is unbounded; heightFactor
        // makes Align size to the child instead of trying to fill infinity.
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
