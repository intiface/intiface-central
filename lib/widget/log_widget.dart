import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/util/error_notifier_cubit.dart';
import 'package:intiface_central/widget/log/widgets/loggy_stream_widget.dart';

class LogWidget extends StatelessWidget {
  static final DateTime appStartTime = DateTime.now();

  const LogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<ErrorNotifierCubit>(context).clearError();
    return Expanded(child: LoggyStreamWidget(appStartTime: appStartTime));
  }
}
