import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/configuration/intiface_configuration_repository.dart';
import 'package:intiface_central/control_widget.dart';
import 'package:intiface_central/engine/engine_control_bloc.dart';
import 'package:intiface_central/engine/engine_repository.dart';

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
    return MultiRepositoryProvider(
        providers: [RepositoryProvider(create: (_) => _configRepo), RepositoryProvider(create: (_) => _engineRepo)],
        child: const IntifaceCentralView());
  }
}

class IntifaceCentralView extends StatelessWidget {
  const IntifaceCentralView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Intiface Central',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: BlocProvider(
            create: (context) => EngineControlBloc(RepositoryProvider.of(context)),
            child: const IntifaceCentralPage()));
  }
}

class IntifaceCentralPage extends StatelessWidget {
  const IntifaceCentralPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(mainAxisSize: MainAxisSize.max, children: const [
      ControlWidget(),
      /*
      Row(children: const [
        Expanded(
          child: SizedBox(),
        )
      ])
      */
    ]));
  }
}
