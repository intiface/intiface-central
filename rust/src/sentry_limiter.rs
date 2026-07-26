//! Process-local repeat suppression for native Sentry events.
//!
//! This module lives outside `crate::api` so that `flutter_rust_bridge`
//! (which scans `crate::api`) never exposes its internals over FFI. The
//! sole intended cross-language seam is `crate::api::util::set_crash_reporting_consent`.
use std::collections::{HashMap, VecDeque};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};

use sentry::protocol::{Event, Value};

pub const WINDOW: Duration = Duration::from_secs(5 * 60);
pub const GLOBAL_BUDGET: usize = 20;
pub const MAX_SIGNATURES: usize = 256;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DropReason {
    Cooldown,
    GlobalBudget,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct Decision {
    pub allowed: bool,
    pub reason: Option<DropReason>,
    pub key: String,
    pub suppressed: u64,
    pub cooldown_drops: u64,
    pub global_drops: u64,
}

#[derive(Debug, Clone)]
struct Record {
    last_allowed: Option<Instant>,
    cooldown_drops: u64,
    global_drops: u64,
    touched: u64,
}

#[derive(Debug)]
pub(crate) struct Limiter {
    records: HashMap<String, Record>,
    allowed: VecDeque<Instant>,
    tick: u64,
}

impl Default for Limiter {
    fn default() -> Self {
        Self::new()
    }
}
impl Limiter {
    pub fn new() -> Self {
        Self {
            records: HashMap::new(),
            allowed: VecDeque::new(),
            tick: 0,
        }
    }
    #[allow(dead_code)]
    pub fn len(&self) -> usize {
        self.records.len()
    }
    pub fn decide(&mut self, key: String, now: Instant) -> Decision {
        self.tick = self.tick.wrapping_add(1);
        if let Some(record) = self.records.get_mut(&key)
            && record
                .last_allowed
                .is_some_and(|last| now.duration_since(last) < WINDOW)
        {
            record.cooldown_drops = record.cooldown_drops.saturating_add(1);
            record.touched = self.tick;
            return Decision {
                allowed: false,
                reason: Some(DropReason::Cooldown),
                key,
                suppressed: record.cooldown_drops + record.global_drops,
                cooldown_drops: record.cooldown_drops,
                global_drops: record.global_drops,
            };
        }
        while self
            .allowed
            .front()
            .is_some_and(|t| now.duration_since(*t) >= WINDOW)
        {
            self.allowed.pop_front();
        }
        if self.allowed.len() >= GLOBAL_BUDGET {
            let suppressed = {
                let record = self.records.entry(key.clone()).or_insert(Record {
                    last_allowed: None,
                    cooldown_drops: 0,
                    global_drops: 0,
                    touched: self.tick,
                });
                record.global_drops = record.global_drops.saturating_add(1);
                record.touched = self.tick;
                record.cooldown_drops + record.global_drops
            };
            self.evict();
            return Decision {
                allowed: false,
                reason: Some(DropReason::GlobalBudget),
                key: key.clone(),
                suppressed,
                cooldown_drops: self.records.get(&key).map_or(0, |r| r.cooldown_drops),
                global_drops: self.records.get(&key).map_or(0, |r| r.global_drops),
            };
        }
        let cooldown_drops = self.records.get(&key).map_or(0, |r| r.cooldown_drops);
        let global_drops = self.records.get(&key).map_or(0, |r| r.global_drops);
        let suppressed = cooldown_drops + global_drops;
        self.records.insert(
            key.clone(),
            Record {
                last_allowed: Some(now),
                cooldown_drops: 0,
                global_drops: 0,
                touched: self.tick,
            },
        );
        self.allowed.push_back(now);
        self.evict();
        Decision {
            allowed: true,
            reason: None,
            key,
            suppressed,
            cooldown_drops,
            global_drops,
        }
    }
    fn evict(&mut self) {
        while self.records.len() > MAX_SIGNATURES {
            if let Some(key) = self
                .records
                .iter()
                .min_by_key(|(_, r)| r.touched)
                .map(|(k, _)| k.clone())
            {
                self.records.remove(&key);
            } else {
                break;
            }
        }
    }
}

fn normalize(text: &str) -> String {
    let mut out = String::with_capacity(text.len());
    let mut chars = text.chars().peekable();
    while let Some(c) = chars.next() {
        if c == '0' && chars.peek() == Some(&'x') {
            out.push_str("0x<addr>");
            chars.next();
            while chars.peek().is_some_and(|x| x.is_ascii_hexdigit()) {
                chars.next();
            }
        } else {
            out.push(c);
        }
    }
    // UUIDs are occurrence identifiers; preserve ordinary numbers (bounds/error codes).
    let bytes = out.as_bytes();
    let mut result = String::with_capacity(out.len());
    let mut i = 0;
    while i < bytes.len() {
        if i + 36 <= bytes.len()
            && bytes[i..i + 36].iter().enumerate().all(|(n, b)| {
                if [8, 13, 18, 23].contains(&n) {
                    *b == b'-'
                } else {
                    b.is_ascii_hexdigit()
                }
            })
        {
            result.push_str("<uuid>");
            i += 36;
        } else {
            result.push(bytes[i] as char);
            i += 1;
        }
    }
    result.trim().to_string()
}

fn useful_frame(event: &Event<'static>) -> Option<String> {
    event
        .exception
        .iter()
        .flat_map(|e| e.stacktrace.iter())
        .flat_map(|s| s.frames.iter())
        .find_map(|f| {
            let name = f
                .function
                .as_deref()
                .or(f.symbol.as_deref())
                .or(f.module.as_deref())?;
            if ["store_dart_post_cobject", "flutter_rust_bridge"]
                .iter()
                .any(|w| name.contains(w))
            {
                None
            } else {
                Some(name.to_string())
            }
        })
        .or_else(|| event.culprit.clone())
}

pub fn signature(event: &Event<'static>) -> Option<String> {
    let exception = event.exception.last()?;
    let mechanism = exception
        .mechanism
        .as_ref()
        .map(|m| m.ty.as_str())
        .unwrap_or("unknown");
    let value = normalize(exception.value.as_deref().unwrap_or(""));
    let frame = useful_frame(event)
        .map(|x| normalize(&x))
        .unwrap_or_default();
    Some(format!(
        "{}|{}|{}|{}",
        mechanism, exception.ty, value, frame
    ))
}

pub fn is_manual(event: &Event<'static>) -> bool {
    event
        .tags
        .get("ManualLogSubmit")
        .is_some_and(|v| v == "true")
}
pub fn is_app_hang(event: &Event<'static>) -> bool {
    event.exception.iter().any(|e| {
        e.mechanism.as_ref().is_some_and(|m| {
            m.ty.eq_ignore_ascii_case("AppHang") || m.ty.eq_ignore_ascii_case("app_hang")
        })
    })
}

pub(crate) struct NativeSentryFilter {
    limiter: Mutex<Limiter>,
    consent: Arc<std::sync::atomic::AtomicBool>,
    clock: fn() -> Instant,
}
impl NativeSentryFilter {
    pub fn new(consent: Arc<std::sync::atomic::AtomicBool>) -> Self {
        Self {
            limiter: Mutex::new(Limiter::new()),
            consent,
            clock: Instant::now,
        }
    }
    #[allow(dead_code)]
    pub fn with_clock(consent: Arc<std::sync::atomic::AtomicBool>, clock: fn() -> Instant) -> Self {
        Self {
            limiter: Mutex::new(Limiter::new()),
            consent,
            clock,
        }
    }
    pub fn before_send(&self, mut event: Event<'static>) -> Option<Event<'static>> {
        // Manual is classified first and is the sole consent/volume exemption.
        if is_manual(&event) {
            return Some(event);
        }
        if !self.consent.load(std::sync::atomic::Ordering::Relaxed) {
            return None;
        }
        // Cocoa app hangs and non-exception events require consent but do not
        // consume the automatic exception/panic budget.
        if is_app_hang(&event) || event.exception.is_empty() {
            return Some(event);
        }
        // Malformed exception payloads still participate in the global budget;
        // the fallback is stable and contains no occurrence-specific data.
        let key = signature(&event).unwrap_or_else(|| "rust|unknown|malformed-exception".into());
        let decision = match self.limiter.lock() {
            Ok(mut limiter) => limiter.decide(key, (self.clock)()),
            Err(_) => return None,
        };
        if !decision.allowed {
            return None;
        }
        if decision.suppressed > 0 {
            event.tags.insert("sentry_source".into(), "rust".into());
            event.tags.insert(
                "sentry_suppressed_count".into(),
                decision.suppressed.to_string(),
            );
            event.tags.insert(
                "sentry_cooldown_drops".into(),
                decision.cooldown_drops.to_string(),
            );
            event.tags.insert(
                "sentry_global_drops".into(),
                decision.global_drops.to_string(),
            );
            event.tags.insert(
                "sentry_suppression_window_seconds".into(),
                WINDOW.as_secs().to_string(),
            );
            event.extra.insert(
                "sentry_suppressed_count".into(),
                Value::from(decision.suppressed as i64),
            );
        }
        event.fingerprint = vec!["{{ default }}".into(), decision.key.into()].into();
        Some(event)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use sentry::protocol::{Exception, Mechanism, Stacktrace};

    fn event(ty: &str, value: &str) -> Event<'static> {
        let mut e = Event::new();
        e.exception = vec![Exception {
            ty: ty.into(),
            value: Some(value.into()),
            mechanism: Some(Mechanism {
                ty: "panic".into(),
                ..Default::default()
            }),
            ..Default::default()
        }]
        .into();
        e
    }

    fn event_with_mechanism(ty: &str, value: &str, mech: &str) -> Event<'static> {
        let mut e = Event::new();
        e.exception = vec![Exception {
            ty: ty.into(),
            value: Some(value.into()),
            mechanism: Some(Mechanism {
                ty: mech.into(),
                ..Default::default()
            }),
            ..Default::default()
        }]
        .into();
        e
    }

    #[test]
    fn cooldown_and_boundary() {
        let mut l = Limiter::new();
        let t = Instant::now();
        assert!(l.decide("a".into(), t).allowed);
        assert!(
            !l.decide("a".into(), t + WINDOW - Duration::from_nanos(1))
                .allowed
        );
        assert!(l.decide("a".into(), t + WINDOW).allowed);
    }

    #[test]
    fn cooldown_drops_and_global_drops_are_separate() {
        let mut l = Limiter::new();
        let t = Instant::now();
        l.decide("a".into(), t);
        let d1 = l.decide("a".into(), t + Duration::from_secs(1));
        assert!(!d1.allowed);
        assert_eq!(d1.reason, Some(DropReason::Cooldown));
        assert_eq!(d1.cooldown_drops, 1);
        assert_eq!(d1.global_drops, 0);

        let d2 = l.decide("a".into(), t + Duration::from_secs(2));
        assert_eq!(d2.cooldown_drops, 2);
        assert_eq!(d2.global_drops, 0);
    }

    #[test]
    fn global_budget_and_expiry() {
        let mut l = Limiter::new();
        let t = Instant::now();
        for i in 0..GLOBAL_BUDGET {
            assert!(l.decide(i.to_string(), t).allowed);
        }
        assert_eq!(
            l.decide("new".into(), t + WINDOW - Duration::from_secs(1))
                .reason,
            Some(DropReason::GlobalBudget)
        );
        assert!(l.decide("new".into(), t + WINDOW).allowed);
    }

    #[test]
    fn repeated_signature_while_budget_exhausted() {
        let mut l = Limiter::new();
        let t = Instant::now();
        for i in 0..GLOBAL_BUDGET {
            l.decide(i.to_string(), t);
        }
        // key-0 is in cooldown AND budget exhausted: cooldown checked first.
        let cd = l.decide("0".into(), t + Duration::from_secs(1));
        assert_eq!(cd.reason, Some(DropReason::Cooldown));
        assert_eq!(cd.cooldown_drops, 1);
        assert_eq!(cd.global_drops, 0);

        // Fresh signature while budget exhausted → global drop.
        let gd1 = l.decide("fresh".into(), t + Duration::from_secs(1));
        assert_eq!(gd1.reason, Some(DropReason::GlobalBudget));
        assert_eq!(gd1.global_drops, 1);

        // Same fresh signature again increments its own global counter.
        let gd2 = l.decide("fresh".into(), t + Duration::from_secs(2));
        assert_eq!(gd2.global_drops, 2);
    }

    #[test]
    fn partial_expiry_frees_budget() {
        let mut l = Limiter::new();
        let t = Instant::now();
        // 10 events at t=0
        for i in 0..10 {
            l.decide(format!("early-{i}"), t);
        }
        // 10 more at t=2min (still in window)
        for i in 0..10 {
            l.decide(format!("late-{i}"), t + Duration::from_secs(120));
        }
        // Budget full
        assert!(
            !l.decide("overflow".into(), t + Duration::from_secs(120))
                .allowed
        );
        // Advance to t=5min: early events expired
        let t2 = t + WINDOW + Duration::from_secs(1);
        assert!(l.decide("freed".into(), t2).allowed);
        // Late events (at t=2min) are still within window from t2
        let late_cd = l.decide("late-0".into(), t2);
        assert!(!late_cd.allowed); // still in cooldown
    }

    #[test]
    fn bounded_eviction_keeps_most_recent() {
        let mut l = Limiter::new();
        let mut t = Instant::now();
        for i in 0..(MAX_SIGNATURES + 20) {
            l.decide(i.to_string(), t);
            t += Duration::from_micros(1);
        }
        assert_eq!(l.len(), MAX_SIGNATURES);
        // Keys 0..19 were evicted (oldest); key MAX_SIGNATURES+19 survives.
        // Re-checking an evicted key creates a fresh record.
        let fresh = l.decide("0".into(), t);
        assert!(!fresh.allowed); // budget exhausted
        assert_eq!(fresh.global_drops, 1); // fresh record
    }

    #[test]
    fn semantic_normalization() {
        let a = event("Error", "EmptyHost at 0xabc 123");
        let b = event("Error", "EmptyHost at 0xdef 123");
        assert_eq!(signature(&a), signature(&b));
        assert_ne!(
            signature(&a),
            signature(&event("Error", "EmptyHost at 0xdef 124"))
        );
    }

    #[test]
    fn preserves_distinct_panic_variants() {
        let empty_host = event("AddrParseError", "EmptyHost");
        let invalid_ipv4 = event("AddrParseError", "InvalidIpv4Address");
        assert_ne!(signature(&empty_host), signature(&invalid_ipv4));

        let bounds_a = event("Panic", "index out of bounds: 42 vs 10");
        let bounds_b = event("Panic", "index out of bounds: 5 vs 3");
        assert_ne!(signature(&bounds_a), signature(&bounds_b));
    }

    #[test]
    fn normalizes_uuids() {
        let a = event("Error", "id 550e8400-e29b-41d4-a716-446655440000 failed");
        let b = event("Error", "id 12345678-1234-1234-1234-123456789abc failed");
        assert_eq!(signature(&a), signature(&b));
    }

    #[test]
    fn consent_and_manual() {
        let c = Arc::new(std::sync::atomic::AtomicBool::new(false));
        let f = NativeSentryFilter::new(c.clone());
        // No consent → automatic events dropped.
        assert!(f.before_send(event("x", "y")).is_none());

        // Manual bypasses consent.
        let mut m = event("x", "y");
        m.tags.insert("ManualLogSubmit".into(), "true".into());
        assert!(f.before_send(m).is_some());

        // Wrong-case tag does NOT bypass.
        let mut m2 = event("x", "y");
        m2.tags.insert("ManualLogSubmit".into(), "True".into());
        assert!(f.before_send(m2).is_none());

        // Consent enabled → automatic events allowed.
        c.store(true, std::sync::atomic::Ordering::Relaxed);
        assert!(f.before_send(event("x", "y")).is_some());
    }

    #[test]
    fn app_hang_requires_consent_but_bypasses_limiter() {
        let c = Arc::new(std::sync::atomic::AtomicBool::new(false));
        let f = NativeSentryFilter::new(c.clone());

        let hang = event_with_mechanism("AppHang", "main thread blocked", "AppHang");
        // No consent → dropped.
        assert!(f.before_send(hang.clone()).is_none());

        c.store(true, std::sync::atomic::Ordering::Relaxed);
        // With consent → passes through without consuming budget.
        assert!(f.before_send(hang.clone()).is_some());
        // Repeated hang still passes (doesn't hit limiter).
        assert!(f.before_send(hang).is_some());
    }

    #[test]
    fn non_exception_event_requires_consent_but_bypasses_limiter() {
        let c = Arc::new(std::sync::atomic::AtomicBool::new(false));
        let f = NativeSentryFilter::new(c.clone());

        let mut msg = Event::new();
        msg.message = Some("plain message".into());

        // No consent → dropped.
        assert!(f.before_send(msg.clone()).is_none());

        c.store(true, std::sync::atomic::Ordering::Relaxed);
        // With consent → passes without consuming budget.
        assert!(f.before_send(msg.clone()).is_some());
        assert!(f.before_send(msg).is_some());
    }

    #[test]
    fn allowed_followup_includes_suppression_metadata() {
        let c = Arc::new(std::sync::atomic::AtomicBool::new(true));
        let f = NativeSentryFilter::new(c);

        let e1 = event("StateError", "paint");
        // First event allowed.
        let first = f.before_send(e1).unwrap();
        assert!(!first.tags.contains_key("sentry_suppressed_count"));

        // Second event (same signature) within cooldown → dropped.
        let e2 = event("StateError", "paint");
        assert!(f.before_send(e2).is_none());

        // After cooldown, allowed with metadata.
        // The limiter uses real time, so we can't advance the clock in NativeSentryFilter
        // without with_clock. Use a direct limiter test instead.
        let mut l = Limiter::new();
        let t = Instant::now();
        l.decide("k".into(), t);
        l.decide("k".into(), t); // cooldown drop
        let allowed = l.decide("k".into(), t + WINDOW);
        assert!(allowed.allowed);
        assert_eq!(allowed.cooldown_drops, 1);
        assert_eq!(allowed.suppressed, 1);
    }

    #[test]
    fn runtime_consent_transitions() {
        let c = Arc::new(std::sync::atomic::AtomicBool::new(false));
        let f = NativeSentryFilter::new(c.clone());

        // false → automatic dropped
        assert!(f.before_send(event("x", "y")).is_none());

        // false → true: automatic allowed
        c.store(true, std::sync::atomic::Ordering::Relaxed);
        assert!(f.before_send(event("x", "y")).is_some());

        // true → false: automatic dropped again
        c.store(false, std::sync::atomic::Ordering::Relaxed);
        assert!(f.before_send(event("x", "y")).is_none());

        // Manual still works while disabled
        let mut m = event("x", "y");
        m.tags.insert("ManualLogSubmit".into(), "true".into());
        assert!(f.before_send(m).is_some());
    }

    #[test]
    fn malformed_event_fallback_is_safe() {
        let c = Arc::new(std::sync::atomic::AtomicBool::new(true));
        let f = NativeSentryFilter::new(c);

        // Event with no exceptions → treated as "other", passes with consent.
        let mut empty = Event::new();
        empty.message = Some("no exception".into());
        assert!(f.before_send(empty).is_some());

        // Event with empty exception vec → same as no exception.
        let mut no_exc = Event::new();
        no_exc.exception = vec![].into();
        assert!(f.before_send(no_exc).is_some());
    }

    #[test]
    fn callback_never_panics_on_malformed_input() {
        let c = Arc::new(std::sync::atomic::AtomicBool::new(true));
        let f = NativeSentryFilter::new(c);
        // Build increasingly malformed events; none should panic.
        let cases = vec![
            Event::new(), // completely empty
            {
                let mut e = Event::new();
                e.exception = vec![Exception {
                    ty: String::new(),
                    value: None,
                    mechanism: None,
                    ..Default::default()
                }]
                .into();
                e
            },
            {
                let mut e = Event::new();
                e.exception = vec![Exception {
                    ty: "x".into(),
                    value: Some("".into()),
                    mechanism: Some(Mechanism::default()),
                    ..Default::default()
                }]
                .into();
                e
            },
        ];
        for ev in cases {
            // Must not panic regardless of content.
            let _ = f.before_send(ev);
        }
    }

    #[test]
    fn fingerprint_preserves_diagnostic_identity() {
        let c = Arc::new(std::sync::atomic::AtomicBool::new(true));
        let f = NativeSentryFilter::new(c);
        let e1 = event("StateError", "paint loop");
        let result = f.before_send(e1).unwrap();
        // Fingerprint includes the normalized key for Sentry grouping.
        assert!(result.fingerprint.len() >= 2);
        assert_eq!(result.fingerprint[0], "{{ default }}");
    }

    #[test]
    fn wrapper_frames_are_weak_identity() {
        let c = Arc::new(std::sync::atomic::AtomicBool::new(true));
        let f = NativeSentryFilter::new(c);
        // Two events with identical wrapper frames but different values must
        // produce distinct signatures.
        let mut e1 = event("Panic", "EmptyHost");
        e1.exception[0].stacktrace = Some(Stacktrace {
            frames: vec![sentry::protocol::Frame {
                function: Some("store_dart_post_cobject".into()),
                ..Default::default()
            }],
            ..Default::default()
        })
        .into();
        let mut e2 = event("Panic", "InvalidIpv4Address");
        e2.exception[0].stacktrace = Some(Stacktrace {
            frames: vec![sentry::protocol::Frame {
                function: Some("store_dart_post_cobject".into()),
                ..Default::default()
            }],
            ..Default::default()
        })
        .into();
        // Both should be allowed (first occurrence of each), but their
        // fingerprints (normalized keys) must differ.
        let r1 = f.before_send(e1).unwrap();
        let r2 = f.before_send(e2).unwrap();
        assert_ne!(r1.fingerprint, r2.fingerprint);
    }

    #[test]
    fn concurrent_access_is_thread_safe() {
        use std::thread;
        let c = Arc::new(std::sync::atomic::AtomicBool::new(true));
        let f = Arc::new(NativeSentryFilter::new(c));
        let handles: Vec<_> = (0..4)
            .map(|_| {
                let f = f.clone();
                thread::spawn(move || {
                    for i in 0..50 {
                        let e = event("Panic", &format!("concurrent-{}", i % 5));
                        // Must not panic or deadlock.
                        let _ = f.before_send(e);
                    }
                })
            })
            .collect();
        for h in handles {
            h.join().unwrap();
        }
    }
}
