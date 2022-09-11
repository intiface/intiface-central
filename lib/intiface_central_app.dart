import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/body_widget.dart';
import 'package:intiface_central/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/configuration/intiface_configuration_repository.dart';
import 'package:intiface_central/control_widget.dart';
import 'package:intiface_central/engine/engine_control_bloc.dart';
import 'package:intiface_central/engine/engine_repository.dart';
import 'package:intiface_central/navigation_cubit.dart';

class IntifaceCentralApp extends StatelessWidget {
  const IntifaceCentralApp(
      {super.key, required IntifaceConfigurationRepository configRepo, required EngineRepository engineRepo})
      : _configRepo = configRepo,
        _engineRepo = engineRepo;

  final IntifaceConfigurationRepository _configRepo;
  final EngineRepository _engineRepo;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(providers: [
      BlocProvider(create: (context) => EngineControlBloc(_engineRepo)),
      BlocProvider(create: (context) => NavigationCubit()),
      BlocProvider(create: (context) => IntifaceConfigurationCubit(_configRepo))
    ], child: const IntifaceCentralView());
  }
}

class IntifaceCentralView extends StatelessWidget {
  const IntifaceCentralView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IntifaceConfigurationCubit, IntifaceConfigurationState>(
        buildWhen: (previous, current) => current is UseLightThemeState,
        builder: (context, state) => MaterialApp(
            title: 'Intiface Central',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.blue,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.blue,
            ),
            themeMode:
                BlocProvider.of<IntifaceConfigurationCubit>(context).useLightTheme ? ThemeMode.light : ThemeMode.dark,
            home: const IntifaceCentralPage()));
  }
}

class IntifaceCentralPage extends StatelessWidget {
  const IntifaceCentralPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
            mainAxisSize: MainAxisSize.max, children: [const ControlWidget(), const Divider(height: 2), BodyWidget()]));
  }
}
