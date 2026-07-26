import 'package:flutter/material.dart';
import 'package:loggy/loggy.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:intiface_central/intiface_central_app.dart';
import 'package:intiface_central/util/sentry_repeat_limiter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var spec = Pubspec.parse(await rootBundle.loadString('pubspec.yaml'));
  final prefs = await SharedPreferences.getInstance();
  final reporting = SentryReportingController()
    ..setConsent(prefs.getBool('crashReporting2') ?? false);
  final limiter = SentryRepeatLimiter();
  final options = IntifaceCentralBootstrapOptions(
    reportingController: reporting,
  );
  if (const String.fromEnvironment('SENTRY_DSN').isNotEmpty) {
    await SentryFlutter.init(
      (sentryOptions) {
        sentryOptions.dsn = const String.fromEnvironment('SENTRY_DSN');
        sentryOptions.sampleRate = 1.0;
        sentryOptions.release = "intiface_central@${spec.version}";
        // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
        // We recommend adjusting this value in production.
        sentryOptions.tracesSampleRate = 0.0;
        sentryOptions.beforeSend = (event, hint) {
          return applySentryRepeatLimiter(
            event,
            limiter,
            consent: reporting.consent,
          );
        };
      },
      appRunner: () async =>
          runApp(await IntifaceCentralApp.create(options: options)),
    );
  } else {
    try {
      runApp(await IntifaceCentralApp.create(options: options));
    } catch (e) {
      logError("Error while running app! $e");
    }
  }
}
