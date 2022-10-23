import 'package:flutter/cupertino.dart';
import 'package:flutter_loggy/flutter_loggy.dart';

class LogWidget extends StatelessWidget {
  const LogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Expanded(child: LoggyStreamWidget());
  }
}
