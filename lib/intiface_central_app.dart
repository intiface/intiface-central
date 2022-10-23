import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/asset_cubit.dart';
import 'package:intiface_central/body_widget.dart';
import 'package:intiface_central/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/control_widget.dart';
import 'package:intiface_central/engine/engine_control_bloc.dart';
import 'package:intiface_central/engine/engine_repository.dart';
import 'package:intiface_central/navigation_cubit.dart';
import 'package:intiface_central/network_info_cubit.dart';
import 'package:intiface_central/util/intiface_util.dart';

class IntifaceCentralApp extends StatelessWidget {
  const IntifaceCentralApp(
      {super.key,
      required IntifaceConfigurationCubit configCubit,
      required EngineRepository engineRepo,
      required AssetCubit assetCubit,
      required NetworkInfoCubit networkCubit})
      : _configCubit = configCubit,
        _engineRepo = engineRepo,
        _assetCubit = assetCubit,
        _networkCubit = networkCubit;

  final IntifaceConfigurationCubit _configCubit;
  final EngineRepository _engineRepo;
  final AssetCubit _assetCubit;
  final NetworkInfoCubit _networkCubit;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(providers: [
      BlocProvider(create: (context) => EngineControlBloc(_engineRepo)),
      BlocProvider(create: (context) => NavigationCubit()),
      BlocProvider(create: (context) => _assetCubit),
      BlocProvider(create: (context) => _configCubit),
      BlocProvider(create: (context) => _networkCubit)
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
            theme: ThemeData(brightness: Brightness.light, primarySwatch: Colors.blue, useMaterial3: true),
            darkTheme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.blue, useMaterial3: true),
            themeMode:
                BlocProvider.of<IntifaceConfigurationCubit>(context).useLightTheme ? ThemeMode.light : ThemeMode.dark,
            home: const IntifaceCentralPage()));
  }
}

class IntifaceCentralPage extends StatelessWidget {
  const IntifaceCentralPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: BlocBuilder<IntifaceConfigurationCubit, IntifaceConfigurationState>(
            buildWhen: (previous, current) => current is UseCompactDisplay,
            builder: (context, state) {
              var useCompactDisplay = BlocProvider.of<IntifaceConfigurationCubit>(context).useCompactDisplay;
              List<Widget> widgets = [const ControlWidget()];
              if (isDesktop()) {
                widgets.addAll([
                  const Divider(height: 2),
                  Row(
                    children: [
                      Expanded(
                          child: IconButton(
                              onPressed: () {
                                BlocProvider.of<IntifaceConfigurationCubit>(context).useCompactDisplay =
                                    !useCompactDisplay;
                              },
                              icon: useCompactDisplay
                                  ? const Icon(Icons.arrow_drop_down)
                                  : const Icon(Icons.arrow_drop_up)))
                    ],
                  )
                ]);
                if (!useCompactDisplay) {
                  widgets.addAll(const [Divider(height: 2), BodyWidget()]);
                }
              } else {
                // Always render body on mobile.
                widgets.addAll(const [Divider(height: 2), BodyWidget()]);
              }
              return Scaffold(body: Column(mainAxisSize: MainAxisSize.max, children: widgets));
            }));
  }
}
