# r3 Application Effects, Errors, Resources and Async

Status: recommended application-model candidate; implementation pending.

## Decision

Use ordinary Lean-compatible library/runtime definitions rather than new kernel effects. The candidate standard concepts are:

~~~text
App error result
Exit error result
Fiber error result
Resource error value
Stream error item
Capability capabilityId
~~~

Names can still change, but their required semantics are fixed by this research direction.

## Pure functions

Ordinary functions remain pure with respect to application effects. A Standard-profile pure function cannot perform hidden filesystem, network, clock, random, process, DOM, or similar effects through ambient target globals.

## Execution outcomes

Application execution distinguishes:

~~~text
Success value
Failure typedError
Cancelled reason
Panic unexpectedRuntimeFailure
~~~

Typed failure is not the same as an arbitrary JS exception or Promise rejection.

## Capabilities

Effects require declared capabilities such as filesystem, network, clock, random, process, environment, storage, console, and DOM.

A package manifest records required capabilities. Availability of a host global does not grant a PSC capability automatically.

## Resource

Resource means deterministic acquisition/release, independent of garbage collection finalizers.

After successful acquisition, release is attempted exactly once on normal success, typed failure, and cancellation, subject to explicitly reported fatal runtime limitations.

If body and cleanup both fail, preserve both causes rather than silently discard one.

## Structured concurrency

Fiber is a started child computation owned by a scope.

Default rule: children do not silently outlive their parent scope.

Scope completion:

1. requests cancellation of unfinished children;
2. waits for terminal outcomes or an explicit resource-limit result;
3. releases child-owned resources;
4. combines failures according to a documented cause policy.

Detached work requires an explicit API/capability.

## Cancellation

Cancellation is a request followed by a terminal outcome; the request itself is not completion.

Foreign adapters state whether external work is actually cancellable. Cancelling a local wait does not prove a remote side effect was reversed.

## Race and timeout

Race selects the first terminal outcome observed by the scheduler trace, requests cancellation of losers, and waits for required cleanup before the scope completes.

Timeout is a race with an explicit clock/deadline computation. Clock assumptions and late effects remain visible.

## Stream

Stream is an asynchronous sequence with explicit completion, typed failure, cancellation, resource lifetime, and backpressure/demand semantics.

JS AsyncIterable and ReadableStream, and Wasm stream/future mechanisms, are adapters rather than the definition of PSC Stream.

## Callbacks

A foreign callback binding records whether invocation is synchronous/reentrant or deferred, one-shot or repeated, retained or immediate, allowed after disposal, and how errors/cancellation are propagated.

## Mutable state

Native local mutation in do remains native elaboration. Shared mutable identity uses explicit reference/state abstractions.

## JS mapping

A JS runtime may implement:

~~~text
App      -> explicit runtime state machine plus Promise machinery
Fiber    -> handle plus cancellation token/controller
Resource -> bracket/finally helper
Stream   -> PSC stream runtime plus adapters
~~~

Promise semantics do not define PSC App/Fiber semantics.

## Wasm mapping

Prefer versioned Component Model/WASI capabilities where they preserve the required behavior. Map typed outcomes to variants/results and resources to explicit host resources. A weaker target must use a separately named weaker profile or reject.

## Contracts

Application specifications range over outcomes, state, and observable traces. A total pure theorem is not automatically a theorem about asynchronous IO behavior.

## Syntax policy

Do not add async, await, using, or other convenience syntax first. Prove and use the library semantics with ordinary functions/do. Add syntax only after the model and usability evidence justify it.

## Required conformance traces

The cross-target suite must cover success, typed failure, panic, cancellation timing, timeout, races, child failure, detach, cleanup on every outcome, cleanup failure, stream backpressure, and late callbacks after disposal.

## Evidence status

Semantic model: recommended.
Exact library encoding: not frozen.
JS runtime prototype: not built.
Direct Wasm mapping: not built.
Cross-target conformance: not executed.
Program-logic proof: pending.
