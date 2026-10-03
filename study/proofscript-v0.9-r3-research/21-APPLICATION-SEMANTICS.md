# r3 Standard Application Semantics

Status: **normative semantic architecture for ps-0.9-r3; library implementation pending**

Application semantic profile:

~~~text
psc-app-v1
~~~

## 1. Purpose

This document fixes the semantic relationships among App, Exit, Fiber, Resource, Stream, Capability, native Lean IO/Task, and foreign Promise/future/stream without adding new kernel rules.

The exact library encoding can evolve only if it preserves this semantic profile or selects a new profile identity.

## 2. Core types

Conceptually:

~~~text
App Caps E A
Exit E A
Fiber Caps E A
Resource Caps E A
Stream Caps E A
Capability
RuntimeFault
CancelReason
~~~

Caps is a normalized finite capability set/type-level description.

The concrete Lean representation can use ordinary structures, inductives, functions, typeclasses, transformers, or another ordinary library encoding.

No new primitive type theory is introduced.

## 3. App is cold

**Decision:** constructing an App Caps E A value does not start external/application effects.

It is a reusable computation description.

Therefore constructing:

~~~text
let work := makeRequest(...)
~~~

does not itself start the request merely because work is constructed.

Execution starts only through an explicit application-runtime operation such as root run or scoped fork.

This distinguishes PSC App from an already-running foreign Promise.

## 4. Root execution

Conceptually:

~~~text
run : Runtime Caps -> App Caps E A -> RunOutcome E A
~~~

where:

~~~text
RunOutcome E A :=
  | completed (Exit E A)
  | runtimeFault RuntimeFault
  | resourceLimit ResourceLimit
  | hostTerminated HostTermination
~~~

The ordinary typed application result is:

~~~text
Exit E A :=
  | success A
  | failure E
  | cancelled CancelReason
~~~

## 5. Typed failure versus runtime fault

failure E is an expected/recoverable typed domain/application failure.

RuntimeFault is outside the ordinary typed error channel.

Examples can include:

- an unclassified foreign exception;
- a violated runtime invariant;
- impossible adapter state;
- target/runtime failure not modeled by E.

Ordinary catch handles typed failure E, not RuntimeFault.

A future low-level recovery profile may expose runtime-fault handling explicitly, but Standard code does not silently treat arbitrary host exceptions as values of E.

## 6. Capabilities

Every Standard application computation has an explicit capability upper bound Caps.

Examples of capability identities:

~~~text
Console
Clock
Random
FileSystem
Network
Process
Environment
Storage
Dom
~~~

A capability may be parameterized/namespaced in the concrete library.

The type-level Caps set and the package/runtime manifest must agree.

A package manifest alone does not make an individual function's effect requirements inspectable; the App Caps E A type, or an equivalent ordinary Lean encoding, carries the local upper bound.

## 7. Capability subtyping/composition

A computation requiring capability set C1 can be used in a context providing C2 only when the selected capability relation establishes:

~~~text
C1 subset-of C2
~~~

or an explicit adapter implements the missing capability.

No hidden ambient target global expands Caps.

## 8. Pure functions versus App

An ordinary function A -> B has no application effects.

An ordinary function may construct an App value without executing it.

This separation allows pure domain transitions and theorem proofs to remain independent of runtime effects.

## 9. Relationship to native Lean IO

Native Lean IO and Task remain inherited low-level/native abstractions.

r3 Standard layering is:

~~~text
Lean IO / Task
      |
      | implementation substrate / adapter boundary
      v
PSC runtime adapters
      |
      v
App / Fiber / Resource / Stream
      |
      v
ordinary ps-standard application APIs
~~~

Rules:

- ordinary ps-standard application libraries SHOULD expose App, not raw target/native IO, for portable capabilities;
- low-level runtime-adapter packages MAY use native IO under an explicit implementation capability/profile;
- ps-lean-extensible may use native IO/Task directly according to its environment;
- a theorem about App semantics does not automatically prove a native IO adapter correct.

## 10. Fiber is hot/started

A Fiber Caps E A denotes a started child computation.

Conceptually:

~~~text
fork : App Caps E A -> App Caps F (Fiber Caps E A)
join : Fiber Caps E A -> App Caps F (Exit E A)
cancel : Fiber Caps E A -> App Caps F Unit
~~~

The exact additional error type F for runtime/scope operations is a library-level design detail; ordinary child application failure remains inside Exit E A.

## 11. Structured concurrency

By default, fibers belong to the lexical/runtime scope that created them.

A scope cannot successfully finish while an owned child is silently left running.

On scope exit:

1. unfinished children receive cancellation requests;
2. required cleanup runs;
3. the scope waits for child terminal outcomes subject to explicit resource limits;
4. child failures/cleanup failures are combined according to the selected cause policy;
5. only an explicit detach operation transfers ownership elsewhere.

Detached/background work requires an explicit API/capability.

## 12. Cancellation state machine

Conceptually:

~~~text
Running
  |
cancel requested
  v
Cancelling
  |
  +--> Success A
  +--> Failure E
  +--> Cancelled reason
  +--> RuntimeFault (runtime reporting layer)
~~~

A cancellation request is not a terminal state.

A computation can complete normally after the request if the selected race point observes completion before cancellation takes effect.

The scheduler/trace model records the deciding event.

## 13. Cleanup shielding

**Decision:** once deterministic resource cleanup begins because a scope/body is leaving, ordinary cooperative cancellation is masked/shielded until that cleanup reaches a terminal result.

This prevents:

~~~text
cancel body
 -> start release
 -> cancel release
 -> silently leak resource
~~~

A fatal host termination/resource-limit outcome can still interrupt cleanup and must be reported as an external/runtime outcome.

Cleanup code may itself use explicitly permitted timeout/failure policies, but not implicit ordinary cancellation.

## 14. Resource

Conceptually a resource contains acquisition and release semantics:

~~~text
acquire : App Caps E A
release : A -> Exit E B -> App Caps ReleaseError Unit
~~~

or an equivalent ordinary abstraction.

A scoped use operation:

1. acquires;
2. if acquisition succeeds, records ownership;
3. executes the body;
4. starts shielded cleanup exactly once;
5. combines body/cleanup outcomes without silently dropping either cause.

Garbage collection/finalizers can be safety nets but are not the semantic cleanup mechanism.

## 15. Cleanup failure combination

The Standard model preserves both body and cleanup causes when both fail.

Conceptually:

~~~text
Cause E R :=
  | bodyFailure E
  | releaseFailure R
  | bodyAndRelease E R
  | cancellationAndRelease CancelReason R
~~~

The exact library type can differ, but information loss is not allowed by the Standard semantics.

## 16. race

race(a,b) starts both computations in one structured scope.

The winner is the first terminal outcome selected by the modeled scheduler trace.

Then:

1. request cancellation of loser;
2. run/wait for loser cleanup;
3. complete the race scope only after required cleanup;
4. report cleanup failure according to the cause policy.

The model does not promise deterministic wall-clock winner ordering when the scheduler relation is nondeterministic.

## 17. Timeout

timeout(d, app) is defined through an explicit monotonic-clock capability and a race/deadline model.

Timeout:

- selects a local deadline outcome;
- requests child cancellation;
- waits for required cleanup;
- does not imply rollback of already-observed external effects.

A clock/profile assumption is part of the runtime model.

## 18. Stream

Stream Caps E A is **cold** until subscribed/consumed through a runtime operation.

A subscription creates an owned running scope.

A stream has distinct outcomes:

~~~text
item A*
normal end
typed failure E
cancelled
runtime fault (runtime layer)
~~~

The Standard stream model includes backpressure/demand: producers may not be assumed to push unbounded values independently of consumer demand unless a separately named buffered policy says so.

Closing/cancelling a subscription triggers shielded resource cleanup.

Late foreign callback events after terminal close are ignored/reported according to the adapter contract and cannot revive the stream.

## 19. Foreign Promise adaptation

A JavaScript Promise is potentially already started.

Therefore the boundary distinguishes conceptually:

~~~text
ForeignPromise A
App Caps E A
Fiber Caps E A
~~~

Attaching to a Promise does not make it a cold App.

An adapter must state:

- whether work already started;
- rejection classification;
- AbortSignal/cancellation support;
- behavior after local cancellation;
- late completion;
- cleanup/retained callback behavior.

## 20. WASI 0.3 adaptation

WASI 0.3 / Component Model async func, future<T>, and stream<T> are target ABI primitives.

They can implement PSC async/stream boundaries, but do not define PSC source semantics.

A backend profile states the relation between:

~~~text
App/Fiber/Stream
and
async func / future<T> / stream<T>
~~~

including ownership, cancellation, terminal-error, and cleanup behavior.

A target that cannot preserve the Standard relation rejects that capability or uses a separately named weaker runtime profile.

## 21. Callback semantics

Every retained foreign callback adapter states:

- immediate versus deferred;
- possible reentrancy;
- one-shot versus repeated;
- retention lifetime;
- cancellation/disposal;
- execution/scheduler context;
- allowed calls after disposal;
- error/result translation.

A retained callback is a resource/lifetime relationship, not merely a pure function value.

## 22. Effect/frame traces

Application execution is modeled with an observable abstract trace sufficient for contracts/preservation work.

Trace events identify at least:

~~~text
capability operation identity
logical resource/region identity when relevant
start/finish/cancel boundaries
resource acquire/release boundaries
stream demand/item/end
foreign adapter boundary events
~~~

Target-specific incidental allocations/pointers are not source trace events unless the selected semantics makes them observable.

## 23. No async/await/using syntax in r3 base

r3 freezes semantics first.

The base does not add:

~~~text
async function
await
using
~~~

Ordinary do, functions, and library combinators remain sufficient to express the model.

A future syntax revision can lower to psc-app-v1 without changing its semantic profile.

## 24. Conformance requirements

A future implementation must test at least:

- cold App construction;
- start through run/fork;
- join;
- typed failure;
- runtime fault separation;
- cancellation before/during work;
- completion/cancellation race;
- child scope exit;
- detach;
- shielded cleanup;
- cleanup failure combinations;
- timeout;
- stream demand/backpressure;
- stream cancellation;
- late callback after disposal;
- Promise adapter late completion;
- WASI async/future/stream mapping where supported.

These tests are planned evidence, not claimed by this document.
