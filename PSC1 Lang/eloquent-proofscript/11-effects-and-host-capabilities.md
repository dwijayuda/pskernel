# 11. Effects, Waiting, and Host Capabilities

Real programs interact with things that are slower, mutable, external, or
unpredictable.

JavaScript exposes those concerns through callbacks, promises, async functions,
events, and host APIs.

PSC1 does not copy those mechanisms into its core semantics.

## Pure code first

A portable pure function:

```proofscript
function next(x: Nat): Nat :=
  x + 1;
```

has no hidden file, network, clock, or process interaction.

That makes:

- testing easier;
- equational reasoning stronger;
- compiler optimization safer;
- backend portability clearer.

## The compiler still needs effects

A compiler needs:

- context;
- mutable logical state;
- recoverable errors;
- fresh IDs;
- speculative rollback.

PSC1's self-host profile therefore requires one concrete reader/state/error
effect.

## Sequencing

The semantic building blocks are:

```text
pure
bind
do
```

Exact library names/source sugar are frozen by the active compiler-effect
profile.

The important point is that sequencing is explicit in the language semantics.

## Waiting for external work

Filesystem/network/process work belongs to host capabilities.

A JavaScript adapter might internally use a Promise.

A Rust adapter might use a different async runtime.

A Wasm/WASI adapter might use component or host calls.

Those mechanisms are target implementations, not portable PSC1 source
semantics.

## No hidden Promise meaning

An `extern function` does not automatically mean:

```text
Promise-returning JS function
```

The current FFI profile is intentionally first-order and bounded.

Richer asynchronous host capabilities require an explicit contract before they
can be portable PSC1 APIs.

## Failure channel

Expected host failure should enter PSC1 through a declared typed failure/effect
channel.

An arbitrary rejected Promise or thrown host exception cannot silently define
the language's error model.

## Concurrency

PSC1 does not need a concurrency model in PSC1 core merely because JavaScript
has an event loop or Wasm/Rust can run threads.

Concurrency semantics require an explicit future design if/when compiler or
application workloads justify them.

## Exercises

1. Classify each capability as pure or effectful: integer addition, reading a
   file, getting current time, parsing an already-provided String, generating a
   fresh compiler ID.
2. Explain why wrapping `fetch` in an `extern function` without specifying
   failure/sequencing is not enough to define a portable PSC1 network API.
3. Sketch a typed Result-based file-read adapter without choosing a JS/Rust/Wasm
   implementation.
