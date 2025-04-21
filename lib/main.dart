import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:intiface_central/intiface_central_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  if (const String.fromEnvironment('SENTRY_DSN').isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        //options.dsn = const String.fromEnvironment('SENTRY_DSN');
        options.sampleRate = 1.0;
        options.release = "intiface_central@${packageInfo.version}+${packageInfo.buildNumber}";
        // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
        // We recommend adjusting this value in production.
        options.tracesSampleRate = 0.0;
        options.beforeSend = (event, hint) {
          for (var proc in IntifaceCentralApp.eventProcessors) {
            if (!proc(event, hint: hint)) {
              return null;
            }
          }
          return event;
        };
      },
      appRunner: () async => runApp(await IntifaceCentralApp.create()),
    );
  } else {
    runApp(await IntifaceCentralApp.create());
  }
}
