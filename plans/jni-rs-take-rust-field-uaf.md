# jni-rs issue draft: `take_rust_field` use-after-free when `try_lock` fails

Status: draft, not yet filed. Target repo: https://github.com/jni-rs/jni-rs
Affects: jni 0.22.4 (verified in `src/env.rs`); likely all versions with the
current `take_rust_field` implementation.

## Title

`Env::take_rust_field` frees the boxed `Mutex` when `try_lock` fails,
causing a use-after-free when a `get_rust_field` guard is outstanding

## Body

`Env::take_rust_field` attempts to avoid consuming the boxed `Mutex` while a
guard from `get_rust_field` is outstanding:

```rust
let mbox = unsafe {
    let ptr = env
        .get_field_unchecked(&obj, field_id, ReturnType::Primitive(Primitive::Long))?
        .j()? as *mut Mutex<T>;

    null_check!(ptr, "rust value from Java")?;
    Box::from_raw(ptr)
};

// attempt to acquire the lock. This prevents us from consuming the
// mutex if there's an outstanding lock. No one else will be able to
// get a new one as long as we're in the guarded scope.
drop(mbox.try_lock()?);
```

If `try_lock` fails because another thread holds a guard obtained via
`get_rust_field`, the `TryLockError` propagates out of the `?` operator. The
local `mbox: Box<Mutex<T>>` is dropped by that early return, which frees the
heap `Mutex` while the other thread's `MutexGuard` still points into it.
Afterwards the outstanding guard dereferences freed memory, and any later
`get_rust_field`/`take_rust_field` on the same object dereferences the pointer
that the field still holds (the field is only zeroed on the success path).

The comment above the `try_lock` suggests the intent was to leave the value
intact and fail cleanly; the failure path instead destroys it.

### Reproducer sketch

1. Thread A: `env.get_rust_field::<_, _, T>(&obj, "data")` and hold the guard
   (e.g. sleep while holding it).
2. Thread B: `env.take_rust_field::<_, _, T>(&obj, "data")` concurrently.
3. `take_rust_field` returns `Err(TryLockError)`, frees the `Mutex`, and
   leaves `data` non-zero; thread A's guard now points at freed memory, and
   the next field access uses a dangling pointer.

### Found in the wild

btleplug's Android backend (`droidplug`) wraps Rust closures in Java
`FnAdapter` objects this way, and Android's Bluetooth binder threads call
`FnAdapter.call` while the poll thread calls `FnAdapter.close` on the same
object. This produced the dominant native crash in production
(SIGSEGV/SIGBUS in `fn_adapter_call_internal`, plus panics from
`lock().unwrap()` on freed memory surfacing through `throw_unwind`).

### Suggested fix

Make the failure path non-destructive: if `try_lock` fails, hand ownership
back instead of dropping the box, e.g.

```rust
let guard = match mbox.try_lock() {
    Ok(guard) => guard,
    Err(_) => {
        std::mem::forget(mbox); // ownership stays with the Java field
        return Err(/* try-lock error */);
    }
};
drop(guard);
```

`std::mem::forget` (or `Box::into_raw`) leaves the allocation owned by the
Java field exactly as the success path's `set_field_unchecked(obj, 0)`
accounting expects, and the field is left untouched on failure so later calls
keep working.

For reference, btleplug now avoids the boxed-`Mutex` scheme for its adapters
entirely: it stores `Arc::into_raw(ptr)` in the field and pairs
monitor-protected read-and-increment (call) with monitor-protected
read-and-zero (close), which is sound regardless of Java-side concurrency.

## Filing checklist

- [ ] Confirm behavior against jni-rs master (0.22.4 verified locally).
- [ ] Check for existing issues (related but distinct: #219, #535).
- [ ] File with the reproducer sketch and suggested fix.
