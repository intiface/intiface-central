import 'package:sentry/sentry.dart';

const sentryRepeatWindow = Duration(minutes: 5);
const sentryAutomaticEventBudget = 20;
const sentryMaximumSignatures = 256;

class SentryLimiterResult {
  final bool allowed;
  final String reason;
  final String? signature;
  final int suppressed;
  final int cooldownDrops;
  final int globalDrops;
  final Duration window;

  const SentryLimiterResult({
    required this.allowed,
    required this.reason,
    this.signature,
    this.suppressed = 0,
    this.cooldownDrops = 0,
    this.globalDrops = 0,
    this.window = sentryRepeatWindow,
  });
}

class _SignatureRecord {
  DateTime? lastAllowed;
  int cooldownDrops = 0;
  int globalDrops = 0;
  DateTime touched;
  _SignatureRecord(this.touched);
}

/// Process-local limiter for automatically generated exception events.
class SentryRepeatLimiter {
  final Duration window;
  final int budget;
  final int maximumSignatures;
  final DateTime Function() now;
  final Map<String, _SignatureRecord> _records = {};
  final List<DateTime> _allowed = [];

  SentryRepeatLimiter({
    this.window = sentryRepeatWindow,
    this.budget = sentryAutomaticEventBudget,
    this.maximumSignatures = sentryMaximumSignatures,
    DateTime Function()? clock,
  }) : now = clock ?? (() => DateTime.now().toUtc());

  int get signatureCount => _records.length;

  SentryLimiterResult check(String signature) {
    final current = now();
    var record = _records[signature];
    if (record != null &&
        record.lastAllowed != null &&
        current.difference(record.lastAllowed!) < window) {
      record.cooldownDrops++;
      record.touched = current;
      return SentryLimiterResult(
        allowed: false,
        reason: 'cooldown',
        signature: signature,
        suppressed: record.cooldownDrops + record.globalDrops,
        cooldownDrops: record.cooldownDrops,
        globalDrops: record.globalDrops,
      );
    }

    // Contract order: cooldown is checked before pruning global timestamps.
    _expireAllowed(current);
    record ??= _SignatureRecord(current);
    _records[signature] = record;
    record.touched = current;
    if (_allowed.length >= budget) {
      record.globalDrops++;
      _evictIfNeeded();
      return SentryLimiterResult(
        allowed: false,
        reason: 'global_budget',
        signature: signature,
        suppressed: record.cooldownDrops + record.globalDrops,
        cooldownDrops: record.cooldownDrops,
        globalDrops: record.globalDrops,
      );
    }

    final priorCooldown = record.cooldownDrops;
    final priorGlobal = record.globalDrops;
    record.cooldownDrops = 0;
    record.globalDrops = 0;
    record.lastAllowed = current;
    _allowed.add(current);
    _evictIfNeeded();
    return SentryLimiterResult(
      allowed: true,
      reason: 'allowed',
      signature: signature,
      suppressed: priorCooldown + priorGlobal,
      cooldownDrops: priorCooldown,
      globalDrops: priorGlobal,
    );
  }

  void _expireAllowed(DateTime current) {
    _allowed.removeWhere(
      (timestamp) => current.difference(timestamp) >= window,
    );
  }

  void _evictIfNeeded() {
    while (_records.length > maximumSignatures) {
      final oldest = _records.entries.reduce(
        (a, b) => a.value.touched.isBefore(b.value.touched) ? a : b,
      );
      _records.remove(oldest.key);
    }
  }
}

class SentryReportingController {
  bool _consent = false;
  bool get consent => _consent;
  void setConsent(bool value) => _consent = value;
}

bool isManualSentryEvent(SentryEvent event) =>
    event.tags?['ManualLogSubmit'] == 'true';

bool isAutomaticExceptionSentryEvent(SentryEvent event) =>
    event.exceptions?.isNotEmpty == true;

bool isAppHangSentryEvent(SentryEvent event) {
  final type = event.type?.toLowerCase() ?? '';
  if (type.contains('app_hang') || type.contains('app-hang')) return true;
  return event.exceptions?.any((exception) {
        final mechanism = (exception.mechanism?.type ?? '').toLowerCase();
        return mechanism.contains('app_hang') ||
            mechanism.contains('app-hang') ||
            mechanism == 'apphang';
      }) ??
      false;
}

String normalizeSentryValue(String value) {
  return value
      .replaceAll(RegExp(r'0x[0-9a-fA-F]+'), '0xADDR')
      .replaceAll(RegExp(r'\b[0-9a-fA-F]{8}-[0-9a-fA-F-]{27,}\b'), '<UUID>')
      .trim();
}

String sentryEventSignature(SentryEvent event) {
  final exception = event.exceptions?.isNotEmpty == true
      ? event.exceptions!.last
      : null;
  final frames = exception?.stackTrace?.frames;
  final frame = frames == null || frames.isEmpty
      ? null
      : frames.reversed.firstWhere(
          (frame) => frame.function != null || frame.fileName != null,
          orElse: () => frames.last,
        );
  final mechanism = exception?.mechanism?.type ?? 'event';
  final type = exception?.type ?? event.type ?? 'message';
  final value = normalizeSentryValue(
    exception?.value ?? event.message?.formatted ?? '',
  );
  final location = frame == null
      ? ''
      : '${frame.function ?? ''}:${frame.fileName ?? ''}';
  return '$mechanism|$type|$value|$location';
}

SentryEvent? applySentryRepeatLimiter(
  SentryEvent event,
  SentryRepeatLimiter limiter, {
  required bool consent,
  String source = 'dart',
}) {
  // Classification order is intentional: only the exact serialized manual tag
  // bypasses consent. App hangs and all other event types require consent, then
  // bypass the automatic exception limiter.
  if (isManualSentryEvent(event)) return event;
  if (!consent) return null;
  if (isAppHangSentryEvent(event) || !isAutomaticExceptionSentryEvent(event)) {
    return event;
  }

  final result = limiter.check(sentryEventSignature(event));
  if (!result.allowed) return null;
  if (result.suppressed > 0) {
    final tags = Map<String, String>.from(event.tags ?? const {});
    tags['SentryRepeatSuppressed'] = result.suppressed.toString();
    tags['SentryRepeatCooldownDrops'] = result.cooldownDrops.toString();
    tags['SentryRepeatGlobalDrops'] = result.globalDrops.toString();
    tags['SentryRepeatWindowSeconds'] = result.window.inSeconds.toString();
    tags['SentryRepeatSource'] = source;
    event.tags = tags;
  }
  return event;
}
