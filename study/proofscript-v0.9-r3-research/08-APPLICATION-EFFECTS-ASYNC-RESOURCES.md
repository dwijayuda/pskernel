# r3 Application Effects, Errors, Resources and Async

Status: **accepted r3 application-semantics direction; library/runtime implementation pending.**

## Decision

Use ordinary Lean-compatible library/runtime definitions rather than new kernel effects. The accepted semantic model is conceptually:

~~~text
App (caps : CapabilitySet) (err : Type) (result : Type)
Fiber (caps : CapabilitySet) (err : Type) (result : Type)
Exit err result
  | success result
  | failure err
  | cancelled CancelReason

RuntimeFault

Resource (caps : CapabilitySet) (err : Type) value
Stream   (caps : CapabilitySet) (err : Type) item
~~~

The exact Lean library encoding may use equivalent ordinary definitions, but it must preserve these relationships.

## Cold versus started computations

`App caps err result` is **cold**: constructing, copying, storing, or reusing an App value does not by itself start external work.

Work starts only through an explicit execution/start operation such as `run` or `fork`.

Each `run`/`fork` starts a distinct execution; `App` does not imply memoization. Re-executing an App that captures a stateful/foreign resource remains subject to that resource's explicit validity/lifetime semantics.

`Fiber caps err result` denotes already-started work and records the capability set of the child computation.

Conceptually:

~~~text
run  : CapEnv caps -> App caps err a -> native IO (Exit err a)
fork : App childCaps err a -> App parentCaps parentErr (Fiber childCaps err a)
join : Fiber childCaps err a -> App parentCaps parentErr (Exit err a)
cancel : Fiber childCaps err a -> App parentCaps parentErr Unit
~~~

The final library types may refine parent/child capability/error relationships, but they may not change the cold/start distinction.

## Pure functions

Ordinary functions remain pure with respect to application effects. A Standard-profile pure function cannot perform hidden filesystem, network, clock, random, process, DOM, or similar effects through ambient target globals.

## Execution outcomes

Ordinary recoverable application execution has exactly these terminal outcomes:

~~~text
Exit err result
  | success result
  | failure err
  | cancelled CancelReason
~~~

Unexpected host/runtime failures are represented separately as `RuntimeFault`.

A root runtime may therefore report a wider `RunOutcome` such as:

~~~text
completed (Exit err result)
runtimeFault RuntimeFault
resourceLimit ResourceLimit
hostTerminated HostTermination
~~~

without pretending those runtime outcomes inhabit the typed application error `err`.

A `RuntimeFault` is **not** catchable by ordinary typed-error handlers. A foreign/runtime adapter may explicitly translate selected faults into the declared typed error channel, and that translation is part of the adapter contract.

This avoids pretending every arbitrary JS throw, engine trap, process failure, or corrupted host condition inhabits the application's declared error type.

## Capabilities

Effects require declared capabilities such as filesystem, network, clock, random, process, environment, storage, console, and DOM.

Capabilities are visible in the application type through `App caps err result`, not only in package metadata.

`CapabilitySet` is a canonical finite type-level capability set. Its concrete Lean encoding may be a normalized list/set index, but equivalent sets must have a deterministic canonical identity for manifests/caches.

A computation requiring capability set `C1` can execute in an environment `C2` only when the selected capability relation establishes `C1 ⊆ C2` or an explicit adapter implements the missing capability.

A package manifest aggregates the capabilities reachable from its exported/runtime entry points. Availability of a host global does not grant a PSC capability automatically.

## Resource

`Resource caps err a` describes acquisition and deterministic release.

After successful acquisition, release is attempted exactly once on normal success, typed failure, and cancellation, subject only to explicitly reported fatal runtime limitations.

Once required deterministic cleanup begins, ordinary cooperative cancellation is **shielded/masked** until cleanup reaches a terminal result. This prevents cancellation from recursively interrupting release and silently leaking an owned resource.

Cleanup may still encounter an explicitly modeled timeout, typed release failure, RuntimeFault, resource limit, or host termination according to the selected runtime profile.

### Body/cleanup failure combination

The Standard semantics never silently drops one cause when both body and cleanup fail.

Conceptually the final cause relation distinguishes at least:

~~~text
body failure
release failure
body + release failure
cancellation + release failure
~~~

The exact public Lean datatype/API name can be chosen during library implementation, but preservation of both causes is normative.

### Cancellation

Cancellation is cooperative and two-phase:

~~~text
Running
  -> cancellation requested
Cancelling
  -> terminal Success | Failure | Cancelled
~~~

`cancel fiber` requests cancellation. It is not itself proof that the fiber is terminal.

Cancellation requests are idempotent at the semantic level. A cancellation request after terminal completion does not alter the already selected terminal result.

`join fiber` observes the terminal `Exit`; it does not restart the computation. Repeated joins observe the same terminal `Exit` (subject only to separately reported runtime faults/resource limits in the joining operation itself).

A normal completion or typed failure may race with a cancellation request according to the scheduler trace; the terminal outcome is whichever the semantic scheduler relation selects.

Foreign adapters state whether external work is actually cancellable. Cancelling a local wait does not prove a remote side effect was reversed.

## Race and timeout

Race selects the first terminal outcome observed by the scheduler trace, requests cancellation of losers, and waits for required loser cleanup before the race scope completes.

If the scheduler model admits nondeterminism, the specification reports the set/relation of permitted outcomes rather than inventing deterministic wall-clock ordering.

Timeout is a race with an explicit clock/deadline computation. Clock assumptions and late effects remain visible.

## Stream

`Stream caps err item` is **cold** until a consumer subscribes/starts consumption.

A subscription creates an owned running scope.

Stream semantics distinguishes:

~~~text
item
normal end
typed failure
cancelled
runtime fault at the runtime-reporting layer
~~~

The model includes backpressure/demand: an unbounded push producer is not assumed unless a separately named buffering policy says so.

Cancelling/closing a subscription triggers the same deterministic/shielded resource-cleanup discipline as other owned scopes.

JS `AsyncIterable` / `ReadableStream` and Wasm stream/future mechanisms are adapters rather than the definition of PSC Stream.

## Callbacks

A foreign callback binding records whether invocation is synchronous/reentrant or deferred, one-shot or repeated, retained or immediate, allowed after disposal, and how errors/cancellation are propagated.

## Mutable state

Native local mutation in do remains native elaboration. Shared mutable identity uses explicit reference/state abstractions.

## Native Lean IO/Task relationship

Native Lean `IO` and `Task` remain the low-level pinned substrate.

Portable `ps-standard` application APIs expose `App`, `Fiber`, `Resource`, and `Stream`.

Direct native `IO`/`Task` use is permitted only in modules explicitly marked as nonportable/native-adapter modules (or in `ps-lean-extensible`), and its capabilities/assumptions are reflected in the module/runtime manifest.

Thus the Standard model does not redefine Lean IO, but ordinary portable application code does not accidentally bypass capability/error/resource semantics through arbitrary native IO.

## JS mapping

A JS runtime may implement:

~~~text
App      -> cold PSC runtime description/state machine
run/fork -> Promise/event-loop machinery that starts work
Fiber    -> started handle plus cancellation controller/token
Resource -> bracket/finally runtime helper with cleanup shielding
Stream   -> PSC stream runtime plus adapters
~~~

A JavaScript Promise is normally already an eventual/running foreign handle and therefore adapts to the started/foreign-async side, not to the definition of cold `App`.

Promise rejection maps only through explicit failure/fault classification.

## Wasm mapping

Prefer versioned Component Model/WASI capabilities where they preserve the required behavior. WASI 0.3's `async func`, `future<T>`, and `stream<T>` are target mechanisms for implementing PSC's already-defined App/Fiber/Stream relations, not their source definition.

Map typed outcomes to variants/results and resources to explicit host resources. A weaker target must use a separately named weaker profile or reject.

## Contracts

Application specifications range over outcomes, state, and observable traces. A total pure theorem is not automatically a theorem about asynchronous IO behavior.

## Syntax policy

Do not add async, await, using, or other convenience syntax first. Prove and use the library semantics with ordinary functions/do. Add syntax only after the model and usability evidence justify it.

## Required conformance traces

The cross-target suite must cover success, typed failure, RuntimeFault, cancellation timing, timeout, races, child failure, detach, cleanup on every outcome, combined body/cleanup failure, stream backpressure, and late callbacks after disposal.

## Evidence status

Application semantic model (cold App, started Fiber, typed Exit, separate RuntimeFault, capability-indexed effects, structured scope, shielded Resource cleanup, Stream relation, native-IO boundary): **accepted for r3**.

Exact Lean library encoding: **not yet implemented/frozen at API-name level**.
JS runtime implementation/evidence: **not claimed by this documentation baseline**.
Direct Wasm implementation/evidence: **not claimed**.
Cross-target conformance: **not executed**.
Program-logic proof: **pending**.
