import 'package:flutter/material.dart';
import 'package:loggy/loggy.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:intiface_central/intiface_central_app.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var spec = Pubspec.parse(await rootBundle.loadString('pubspec.yaml'));
  if (const String.fromEnvironment('SENTRY_DSN').isNotEmpty) {
    await SentryFlutter.init((options) {
      //options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.sampleRate = 1.0;
      options.release = "intiface_central@${spec.version}";
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
    }, appRunner: () async => runApp(await IntifaceCentralApp.create()));
  } else {
    try {
      runApp(await IntifaceCentralApp.create());
    } catch (e) {
      logError("Error while running app! $e");
    }
  }
}
