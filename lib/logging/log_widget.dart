import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_loggy/flutter_loggy.dart';
import 'package:intiface_central/bloc/util/error_notifier_cubit.dart';

class LogWidget extends StatelessWidget {
  const LogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<ErrorNotifierCubit>(context).clearError();
    return const Expanded(child: LoggyStreamWidget());
  }
}
