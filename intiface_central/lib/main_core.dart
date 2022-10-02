import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_loggy/flutter_loggy.dart';
import 'package:intiface_central/asset_cubit.dart';
import 'package:intiface_central/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/engine/engine_control_bloc.dart';
import 'package:intiface_central/engine/engine_repository.dart';
import 'package:intiface_central/intiface_central_app.dart';
import 'package:intiface_central/navigation_cubit.dart';
import 'package:intiface_central/network_info_cubit.dart';
import 'package:intiface_central/update/update_bloc.dart';
import 'package:intiface_central/update/update_repository.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:loggy/loggy.dart';

// From https://github.com/infinum/floggy/issues/50
class MultiPrinter extends LoggyPrinter {
  const MultiPrinter();

  final LoggyPrinter devPrinter = const PrettyDeveloperPrinter();
  final LoggyPrinter consolePrinter = const PrettyPrinter();
  //final LoggyPrinter filePrinter;

  @override
  void onLog(LogRecord record) {
    //filePrinter.onLog(record);
    devPrinter.onLog(record);

    if (!kReleaseMode) {
      consolePrinter.onLog(record);
    }
  }
}

  Loggy.initLoggy(
    logPrinter: StreamPrinter(
      const MultiPrinter(),
    ),
    logOptions: const LogOptions(
      LogLevel.all,
      stackTraceLevel: LogLevel.error,
    ),
  );
  logInfo("Intiface Central Starting...");

  await IntifacePaths.init();

  var networkCubit = await NetworkInfoCubit.create();

  engineRepo.messageStream.forEach((message) {
    if (message.engineLog != null) {
      // TODO Turn level into an enum
      var level = message.engineLog!.message!.level;
      if (level == "DEBUG") {
        logDebug(message.engineLog!.message!.fields["message"]);
      } else if (level == "INFO") {
        logInfo(message.engineLog!.message!.fields["message"]);
      } else if (level == "ERROR") {
        logError(message.engineLog!.message!.fields["message"]);
      } else if (level == "WARN") {
        logWarning(message.engineLog!.message!.fields["message"]);
      } else if (level == "TRACE") {
        // TODO Implement trace logging level for loggy
        //log(message.engineLog!.message!.fields["message"]);
      }
    }
  });

  var assetCubit = await AssetCubit.create();

  // Set up Update/Configuration Pipe/Cubit.
  var updateBloc = UpdateBloc(UpdateRepository(configCubit.currentNewsVersion, configCubit.currentDeviceConfigVersion));

  updateBloc.stream.forEach((state) async {
    if (state is NewsUpdateRetrieved) {
      configCubit.currentNewsVersion = state.version;
      await assetCubit.update();
    }
    if (state is DeviceConfigUpdateRetrieved) {
      configCubit.currentDeviceConfigVersion = state.version;
    }
  });

  runApp(MultiBlocProvider(providers: [
    BlocProvider(create: (context) => EngineControlBloc(engineRepo)),
    BlocProvider(create: (context) => NavigationCubit()),
    BlocProvider(create: (context) => updateBloc),
    BlocProvider(create: (context) => assetCubit),
    BlocProvider(create: (context) => configCubit),
    BlocProvider(create: (context) => networkCubit),
  ], child: const IntifaceCentralView()));
}
