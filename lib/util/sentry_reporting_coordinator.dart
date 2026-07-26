import 'sentry_repeat_limiter.dart';

/// Coordinates Dart reporting consent with the independently initialized native
/// Sentry client. This class contains no Flutter/widget or FFI dependencies.
class SentryReportingCoordinator {
  final SentryReportingController controller;
  final bool initializeSentry;
  final String dsn;
  final Future<void> Function(String dsn) nativeInit;
  final void Function(bool enabled) nativeConsent;
  bool _nativeInitialized = false;

  SentryReportingCoordinator({
    required this.controller,
    required this.initializeSentry,
    required this.dsn,
    required this.nativeInit,
    required this.nativeConsent,
  });

  Future<void> applyInitialConsent(bool enabled) async {
    controller.setConsent(enabled);
    if (!initializeSentry) return;
    nativeConsent(enabled);
    if (enabled) await _initializeNativeIfNeeded();
  }

  Future<void> applyConsentChange(bool enabled) async {
    controller.setConsent(enabled);
    if (!initializeSentry) return;
    nativeConsent(enabled);
    if (enabled) await _initializeNativeIfNeeded();
  }

  Future<void> _initializeNativeIfNeeded() async {
    if (_nativeInitialized || dsn.isEmpty) return;
    _nativeInitialized = true;
    try {
      await nativeInit(dsn);
    } catch (_) {
      _nativeInitialized = false;
      rethrow;
    }
  }
}
