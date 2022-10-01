import 'package:flutter/material.dart';
import 'package:flutter_loggy/flutter_loggy.dart';
import 'package:intiface_central/asset_cubit.dart';
import 'package:intiface_central/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/engine/engine_repository.dart';
import 'package:intiface_central/intiface_central_app.dart';
import 'package:intiface_central/network_info_cubit.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:loggy/loggy.dart';

Future<void> mainCore(IntifaceConfigurationCubit configCubit, EngineRepository engineRepo) async {
  Loggy.initLoggy(
    logPrinter: StreamPrinter(
      const PrettyDeveloperPrinter(),
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

  runApp(IntifaceCentralApp(
      engineRepo: engineRepo, configCubit: configCubit, assetCubit: assetCubit, networkCubit: networkCubit));
}
