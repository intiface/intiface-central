import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:intiface_central/util/sentry_repeat_limiter.dart';
import 'package:intiface_central/util/sentry_reporting_coordinator.dart';
import 'package:sentry/sentry.dart';

void main() {
  group('SentryRepeatLimiter cooldown', () {
    test(
      'first event allowed, same signature within window dropped, at boundary allowed',
      () {
        var time = DateTime.utc(2025, 1, 1);
        final limiter = SentryRepeatLimiter(clock: () => time);

        // First event passes through.
        expect(limiter.check('a').allowed, isTrue);

        // Same signature just before the boundary is dropped (cooldown).
        time = time.add(
          const Duration(minutes: 5) - const Duration(microseconds: 1),
        );
        final dropped = limiter.check('a');
        expect(dropped.allowed, isFalse);
        expect(dropped.reason, 'cooldown');
        expect(dropped.cooldownDrops, 1);
        expect(dropped.globalDrops, 0);

        // At exactly the boundary (>= window), the event is allowed again.
        time = DateTime.utc(2025, 1, 1).add(const Duration(minutes: 5));
        final allowed = limiter.check('a');
        expect(allowed.allowed, isTrue);
        expect(allowed.suppressed, 1); // reports prior cooldown drops
        expect(allowed.cooldownDrops, 1);
        expect(allowed.globalDrops, 0);
      },
    );

    test('cooldown drops and global drops are separate counters', () {
      var time = DateTime.utc(2025, 1, 1);
      final limiter = SentryRepeatLimiter(clock: () => time);

      limiter.check('a');
      // Two cooldown drops.
      final cd1 = limiter.check('a');
      expect(cd1.cooldownDrops, 1);
      final cd2 = limiter.check('a');
      expect(cd2.cooldownDrops, 2);
      expect(cd2.globalDrops, 0);
    });
  });

  group('SentryRepeatLimiter global budget', () {
    test('20 unique signatures allowed, 21st dropped, at boundary allowed', () {
      var time = DateTime.utc(2025, 1, 1);
      final limiter = SentryRepeatLimiter(clock: () => time);

      for (var i = 0; i < 20; i++) {
        expect(limiter.check('key-$i').allowed, isTrue);
      }

      // Budget exhausted — new signature is globally dropped.
      final dropped = limiter.check('new');
      expect(dropped.allowed, isFalse);
      expect(dropped.reason, 'global_budget');
      expect(dropped.globalDrops, 1);
      expect(dropped.cooldownDrops, 0);

      // At exactly the boundary, capacity is available.
      time = DateTime.utc(2025, 1, 1).add(const Duration(minutes: 5));
      expect(limiter.check('new').allowed, isTrue);
    });

    test(
      'repeated signature while budget exhausted counts global drops separately from cooldown',
      () {
        var time = DateTime.utc(2025, 1, 1);
        final limiter = SentryRepeatLimiter(clock: () => time);

        // Exhaust the global budget with unique signatures.
        for (var i = 0; i < 20; i++) {
          limiter.check('key-$i');
        }

        // Now send an already-cooling signature. It should be cooldown-dropped,
        // not global-dropped, because cooldown is checked first.
        final cdDrop = limiter.check('key-0');
        expect(cdDrop.allowed, isFalse);
        expect(cdDrop.reason, 'cooldown');
        expect(cdDrop.cooldownDrops, 1);
        expect(cdDrop.globalDrops, 0);

        // A fresh signature while budget exhausted gets global drop.
        final globalDrop = limiter.check('fresh');
        expect(globalDrop.reason, 'global_budget');
        expect(globalDrop.globalDrops, 1);
        expect(globalDrop.cooldownDrops, 0);

        // Same fresh signature dropped again increments its own global counter.
        final globalDrop2 = limiter.check('fresh');
        expect(globalDrop2.globalDrops, 2);
      },
    );

    test('partial expiry frees some but not all budget slots', () {
      var time = DateTime.utc(2025, 1, 1);
      final limiter = SentryRepeatLimiter(clock: () => time);

      // Allow 10 events at t=0.
      for (var i = 0; i < 10; i++) {
        limiter.check('early-$i');
      }
      // Allow 10 more at t=2min (still within window of t=0).
      time = time.add(const Duration(minutes: 2));
      for (var i = 0; i < 10; i++) {
        limiter.check('late-$i');
      }
      // Budget is now full (20).
      expect(limiter.check('overflow').allowed, isFalse);

      // Advance to t=5min1s: the first 10 (at t=0) are now expired, but the
      // 10 at t=2min are not.
      time = DateTime.utc(
        2025,
        1,
        1,
      ).add(const Duration(minutes: 5, seconds: 1));
      // One slot is freed.
      expect(limiter.check('freed-1').allowed, isTrue);
      // Second slot.
      expect(limiter.check('freed-2').allowed, isTrue);
      // By now all 10 early slots expired, 10 late still there + 2 freed = 12...
      // Actually only 10 early expire. So 10 remaining + 2 freed = 12. Budget is 20, so still room.
      for (var i = 3; i <= 8; i++) {
        expect(limiter.check('freed-$i').allowed, isTrue);
      }
      // Now 10 late + 8 freed = 18. Still room.
      expect(limiter.check('freed-9').allowed, isTrue);
      expect(limiter.check('freed-10').allowed, isTrue);
      // 10 late + 10 freed = 20. Full again.
      expect(limiter.check('over').allowed, isFalse);
    });
  });

  group('SentryRepeatLimiter bounded eviction', () {
    test('never exceeds 256 records, evicts least-recently-touched', () {
      var time = DateTime.utc(2025, 1, 1);
      final limiter = SentryRepeatLimiter(clock: () => time);

      for (var i = 0; i < 300; i++) {
        limiter.check('key-$i');
        time = time.add(const Duration(microseconds: 1));
      }
      expect(limiter.signatureCount, 256);

      // key-44 (the 45th key touched) is the oldest surviving record.
      // It was global-dropped (budget exhausted), so lastAllowed is null;
      // re-checking it should still find it in records and drop it by budget.
      time = time.add(const Duration(microseconds: 1));
      final result = limiter.check('key-44');
      expect(result.allowed, isFalse);
      // It exists in records so global_drops increments.
      expect(result.globalDrops, greaterThanOrEqualTo(1));

      // key-299 (the newest) is definitely still in records.
      final result299 = limiter.check('key-299');
      expect(result299.allowed, isFalse);
      expect(result299.globalDrops, greaterThanOrEqualTo(1));

      // key-0 (the oldest) was evicted, so it re-enters as a fresh record.
      final result0 = limiter.check('key-0');
      expect(result0.allowed, isFalse);
      expect(result0.globalDrops, 1); // fresh record, first global drop
    });
  });

  group('manual event bypass', () {
    final limiter = SentryRepeatLimiter();

    test('exact ManualLogSubmit=true bypasses consent and limiter', () {
      final event = SentryEvent(tags: {'ManualLogSubmit': 'true'});
      expect(
        applySentryRepeatLimiter(event, limiter, consent: false),
        same(event),
      );
    });

    test('wrong-case ManualLogSubmit=True does not bypass', () {
      final event = SentryEvent(tags: {'ManualLogSubmit': 'True'});
      expect(applySentryRepeatLimiter(event, limiter, consent: false), isNull);
    });

    test('ManualLogSubmit=false does not bypass', () {
      final event = SentryEvent(tags: {'ManualLogSubmit': 'false'});
      expect(applySentryRepeatLimiter(event, limiter, consent: false), isNull);
    });

    test('empty ManualLogSubmit does not bypass', () {
      final event = SentryEvent(tags: {'ManualLogSubmit': ''});
      expect(applySentryRepeatLimiter(event, limiter, consent: false), isNull);
    });

    test('missing tag does not bypass', () {
      final event = SentryEvent(tags: {'OtherTag': 'value'});
      expect(applySentryRepeatLimiter(event, limiter, consent: false), isNull);
    });
  });

  group('app-hang classification', () {
    final limiter = SentryRepeatLimiter();

    test('app_hang event requires consent but bypasses limiter', () {
      final hang = SentryEvent(type: 'app_hang');
      // Without consent, dropped.
      expect(applySentryRepeatLimiter(hang, limiter, consent: false), isNull);
      // With consent, passes through without consuming budget.
      expect(
        applySentryRepeatLimiter(hang, limiter, consent: true),
        same(hang),
      );
    });

    test('app-hang mechanism type bypasses limiter with consent', () {
      final hang = SentryEvent(
        exceptions: [
          SentryException(
            type: 'AppHang',
            value: 'main thread blocked',
            mechanism: Mechanism(type: 'AppHang'),
          ),
        ],
      );
      expect(
        applySentryRepeatLimiter(hang, limiter, consent: true),
        same(hang),
      );
      // Same hang again should still pass — it doesn't consume the limiter.
      expect(
        applySentryRepeatLimiter(hang, limiter, consent: true),
        same(hang),
      );
    });
  });

  group('other event classification', () {
    final limiter = SentryRepeatLimiter();

    test(
      'non-exception message event requires consent but bypasses limiter',
      () {
        final msg = SentryEvent(message: SentryMessage('something happened'));
        // No consent → dropped.
        expect(applySentryRepeatLimiter(msg, limiter, consent: false), isNull);
        // With consent → passes without consuming budget.
        expect(
          applySentryRepeatLimiter(msg, limiter, consent: true),
          same(msg),
        );
      },
    );
  });

  group('automatic exception limiter integration', () {
    test('allowed followup includes suppression metadata', () {
      var time = DateTime.utc(2025, 1, 1);
      final limiter = SentryRepeatLimiter(clock: () => time);
      final event = SentryEvent(
        exceptions: [SentryException(type: 'StateError', value: 'paint')],
      );
      // First event allowed, no metadata.
      final first = applySentryRepeatLimiter(event, limiter, consent: true)!;
      expect(first.tags, isNull);

      // Second event within cooldown, dropped.
      expect(applySentryRepeatLimiter(event, limiter, consent: true), isNull);

      // After cooldown, allowed with metadata.
      time = time.add(const Duration(minutes: 5));
      final followup = SentryEvent(
        exceptions: [SentryException(type: 'StateError', value: 'paint')],
      );
      final result = applySentryRepeatLimiter(
        followup,
        limiter,
        consent: true,
      )!;
      expect(result.tags?['SentryRepeatSuppressed'], '1');
      expect(result.tags?['SentryRepeatWindowSeconds'], '300');
      expect(result.tags?['SentryRepeatSource'], 'dart');
    });

    test('first allowed event has no suppression metadata', () {
      final limiter = SentryRepeatLimiter();
      final event = SentryEvent(
        exceptions: [SentryException(type: 'StateError', value: 'boom')],
      );
      final result = applySentryRepeatLimiter(event, limiter, consent: true)!;
      expect(result.tags, isNull);
    });
  });

  group('SentryReportingController', () {
    test('runtime consent transitions are honored immediately', () {
      final controller = SentryReportingController();
      expect(controller.consent, isFalse);

      controller.setConsent(true);
      expect(controller.consent, isTrue);

      controller.setConsent(false);
      expect(controller.consent, isFalse);
    });

    test('consent false drops automatic events, true allows them', () {
      final controller = SentryReportingController();
      final limiter = SentryRepeatLimiter();
      final event = SentryEvent(
        exceptions: [SentryException(type: 'Error', value: 'x')],
      );

      controller.setConsent(false);
      expect(
        applySentryRepeatLimiter(event, limiter, consent: controller.consent),
        isNull,
      );

      controller.setConsent(true);
      expect(
        applySentryRepeatLimiter(event, limiter, consent: controller.consent),
        isNotNull,
      );
    });
  });

  group('reporting coordinator', () {
    test(
      'disabled consent never initializes and still updates native consent',
      () async {
        final controller = SentryReportingController();
        var initCalls = 0;
        final consents = <bool>[];
        final coordinator = SentryReportingCoordinator(
          controller: controller,
          initializeSentry: true,
          dsn: 'dsn',
          nativeInit: (_) async => initCalls++,
          nativeConsent: consents.add,
        );
        await coordinator.applyInitialConsent(false);
        await coordinator.applyConsentChange(false);
        expect(initCalls, 0);
        expect(consents, [false, false]);
      },
    );

    test(
      'enabled consent initializes once and runtime opt-out is forwarded',
      () async {
        final controller = SentryReportingController();
        var initCalls = 0;
        final consents = <bool>[];
        final coordinator = SentryReportingCoordinator(
          controller: controller,
          initializeSentry: true,
          dsn: 'dsn',
          nativeInit: (_) async => initCalls++,
          nativeConsent: consents.add,
        );
        await coordinator.applyInitialConsent(true);
        await coordinator.applyConsentChange(true);
        await coordinator.applyConsentChange(false);
        await coordinator.applyConsentChange(true);
        expect(initCalls, 1);
        expect(consents, [true, true, false, true]);
        expect(controller.consent, isTrue);
      },
    );

    test(
      'initializeSentry false does not initialize or update native consent',
      () async {
        final controller = SentryReportingController();
        var initCalls = 0;
        final consents = <bool>[];
        final coordinator = SentryReportingCoordinator(
          controller: controller,
          initializeSentry: false,
          dsn: 'dsn',
          nativeInit: (_) async => initCalls++,
          nativeConsent: consents.add,
        );
        await coordinator.applyInitialConsent(true);
        await coordinator.applyConsentChange(false);
        expect(initCalls, 0);
        expect(consents, isEmpty);
      },
    );

    test(
      'failed native initialization is retried on the next opt-in',
      () async {
        final controller = SentryReportingController();
        var initCalls = 0;
        final coordinator = SentryReportingCoordinator(
          controller: controller,
          initializeSentry: true,
          dsn: 'dsn',
          nativeInit: (_) async {
            initCalls++;
            if (initCalls == 1) throw StateError('first init failed');
          },
          nativeConsent: (_) {},
        );

        await expectLater(
          coordinator.applyConsentChange(true),
          throwsStateError,
        );
        await coordinator.applyConsentChange(true);
        expect(initCalls, 2);
      },
    );

    test(
      'opt-out is forwarded while native initialization is in flight',
      () async {
        final controller = SentryReportingController();
        final initStarted = Completer<void>();
        final finishInit = Completer<void>();
        final consents = <bool>[];
        final coordinator = SentryReportingCoordinator(
          controller: controller,
          initializeSentry: true,
          dsn: 'dsn',
          nativeInit: (_) async {
            initStarted.complete();
            await finishInit.future;
          },
          nativeConsent: consents.add,
        );

        final optIn = coordinator.applyConsentChange(true);
        await initStarted.future;
        await coordinator.applyConsentChange(false);
        expect(controller.consent, isFalse);
        expect(consents, [true, false]);
        finishInit.complete();
        await optIn;
        expect(controller.consent, isFalse);
      },
    );
  });

  group('normalization', () {
    test('memory addresses are canonicalized', () {
      expect(normalizeSentryValue('error at 0x7fffabc1234'), 'error at 0xADDR');
    });

    test('UUIDs are canonicalized', () {
      expect(
        normalizeSentryValue('id 550e8400-e29b-41d4-a716-446655440000 end'),
        'id <UUID> end',
      );
    });

    test('ordinary numbers (bounds, error codes) are preserved', () {
      expect(
        normalizeSentryValue('index out of bounds: 42 vs 10'),
        'index out of bounds: 42 vs 10',
      );
    });

    test('semantic error names preserved', () {
      expect(normalizeSentryValue('EmptyHost'), 'EmptyHost');
      expect(normalizeSentryValue('InvalidIpv4Address'), 'InvalidIpv4Address');
    });

    test('empty stack frames do not throw or alter signature extraction', () {
      final event = SentryEvent(
        exceptions: [
          SentryException(
            type: 'StateError',
            value: 'empty frames',
            stackTrace: SentryStackTrace(frames: const []),
          ),
        ],
      );
      expect(sentryEventSignature(event), 'event|StateError|empty frames|');
    });
  });
}
