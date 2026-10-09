# Strict SH/1 correspondence: enabled TS/JS lane

This document records the remaining semantic correspondence work for the current
PSC0 source-owned TypeScript/JavaScript path. **Strict SH/1 and general semantic
preservation remain unqualified.** The companion
[33-rule ledger](correspondence-obligations.json) gives the exact enabled rule
families, source definitions, assumptions, local arguments, per-compilation
checks and remaining obligations.

The source inspection baseline is
[`ed5d00aca0743bde583b45fe7756dd494ac3960f`](https://github.com/dwijayuda/pskernel/commit/ed5d00aca0743bde583b45fe7756dd494ac3960f).
Candidate strict-boundary modules and runtime guards have their own blob
identities in the ledger. Those identities describe proposed implementation
inputs; they are not execution receipts. Native/generated qualification must
record its actual source, compiler, IR, toolchain and product identities.

## Reviewed implementation update

The current integration is recorded in
[the exact implementation manifest](reviewed-candidates/strict-implementation-batch.json).
It retains source/normalization origins and one source-owned preparation result,
repairs computed Nat and partial-application demand, and implements both empty
inductives/elimination and inhabited zero-field structures. Its conformance
receipts must come from the exact subsequent cloud run; source review is not an
execution result.

The preceding attempt at `05f37fc04e52bfaed70389291a0fcdeda819f71f`
passed native development and the selected-R C1 gate, then exhausted the heap
during C2. [Its retained evidence](qualification-attempts.json) and authenticated
archive inspection establish that no C2 files were retained. The reviewed
one-encoding path and measured 8 GiB old-space policy are not yet evidence that
the next generation succeeds. All 33 general correspondence rules remain open.

## 1. Assurance boundary

[SPEC.md](../SPEC.md), especially sections 2, 4, 6, 7 and 8, remains normative.
Its MUSTs include source origins, supported normalization, the closed runtime
contract and preservation of evaluation, capture and representation. This
document does not reduce those requirements to a finite test suite or rewrite
them as a promise about only the existing compiler corpus.

Several useful facts have different meanings:

| Evidence | What it establishes | What it does not establish |
| --- | --- | --- |
| Portable source admission | Actual parsed input obeys the implemented capability and module policy | Correctness of every accepted normalization |
| Preparation/admission-ready Core | The current preparation checks succeeded for the actual source | Independent selected-provider acceptance or runtime preservation |
| Complete original-IR typing | The same IR has supported, coherent runtime types, layouts, scopes and call groups | Correct source erasure, scalar laws or evaluation preservation |
| Target admission | The actual emitted names, private namespaces and conservative initialization order meet the declared target policy | A correct earlier Core-to-IR binding/layout map |
| Native/generated observations | The explicitly listed cases produced their recorded results | A theorem for arbitrary accepted programs |
| Fixed point and exact product hashes | The stated generations reproduced the specified artifacts | General compiler correctness |
| Provider receipt | The separately selected provider accepted its exact admission stream | JavaScript runtime semantics |
| Rule argument or proof | Only the stated relation under its explicit assumptions | Any unmentioned capability or host behavior |

The ledger contains code-grounded arguments for each rule, but **none of its
33 general preservation obligations is marked discharged**. The existing
implementation checks can close concrete local admission obligations.
Correspondence still needs a complete value/environment/evaluation relation and
a justification covering every enabled rule and recognized optimization.
A bounded example, successful checker report or stable compiler output cannot
stand in for that general argument.

The supported target remains the current pinned TypeScript **7.0.2** CLI/profile
and JavaScript runtime. Handwritten PSC1-compatible `.lean`, parsed by PSC0's
own frontend, remains the compiler source authority. Generated `.ps` retains
the new-only `ps-0.9-r3` grammar. This work changes neither source authority nor
the selected authoring seed.

## 2. The artifacts that must correspond

The relevant sequence is original source and spans, resolved/normalized prepared
Core, the same erased original IR, emitted TypeScript, and the pinned
TypeScript-produced JavaScript. The relation must account for values,
constructor/field meanings, lexical captures, function parameter groups,
evaluation order and demand, and the declared errors/faults.

The atomic source backend can retain actual `parsedModules`, actual
`prepared`, the `originalIr` it obtained once, and the accepted check/source/
target reports. This prevents a caller from supplying unrelated IR or a report
as the authority for a source compilation. It is valuable provenance, but it
does not fill in a missing transformation proof.

In particular, **`parsedModules` plus `prepared` alone does not establish a
transformation relation**. The reviewed origin path additionally retains actual
source ordinals/names/spans, Core member identities and roles, and successful
normalization-plan metadata. Erasure scopes contain actual runtime/type/erased
local maps, expression substitutions and source/projection/layout identities.
A complete source argument can quantify over those reachable structures; a
checked per-compilation association witness is another possible method.
Neither method may infer identity from generated display names or assume its
own invariant. SPEC requires the full preservation argument and truthful
origins; it does not mandate a particular serialized Core-to-IR certificate.
The current retained observations do not themselves discharge that argument.

A practical value relation must keep Nat and Int distinct despite their shared
bigint carrier, Char and String distinct despite their shared string carrier,
and `Function([A], Function([B], R))` distinct from
`Function([A, B], R)`. It must also state how closures capture environments and
how immutable records, tagged constructors and Arrays relate to source values.
Arbitrary cyclic, mutated or foreign JavaScript objects and arbitrary host
callbacks do not enter that relation simply because JavaScript accepts them.

The primitive domains and laws are owned by
[enabled-runtime-contract.json](enabled-runtime-contract.json) and explained in
[ENABLED_RUNTIME.md](ENABLED_RUNTIME.md): six primitive types, Array and
45 enabled operations. The companion candidate's 186 observations are finite
evidence. Array capacity behavior is conditional on successful allocation; no
equal memory use, allocation behavior, wall time or implementation step count is
claimed.

## 3. Complete finite rule inventory

The ledger enumerates nine erasure/layout rules, four normalization rules,
all eleven original-IR expression constructors, and nine backend/runtime rules.
Its `relatedObligations` are cross-references, not an asserted acyclic proof
graph: call, closure and trampoline arguments must use one mutually consistent
simulation relation.

### S3 — prepared Core to runtime IR and layout

| Rule | Required correspondence | General status |
| --- | --- | --- |
| `ER-01` | Declaration identity, prelude and ordered module erasure | Open; local checks/argument recorded |
| `ER-02` | Closed runtime types and rank-1 schemes | Open; local checks/argument recorded |
| `ER-03` | Proof/type omission and runtime independence | Open; local checks/argument recorded |
| `ER-04` | Application telescopes, generic order and partial application | Open; local checks/argument recorded |
| `ER-05` | Structure fields and projections | Open; local checks/argument recorded |
| `ER-06` | Regular inductives and constructor layout | Open; local checks/argument recorded |
| `ER-07` | Recursors, induction hypotheses and Nat demand | Open; local checks/argument recorded |
| `ER-08` | Structure recursor lowering | Open; local checks/argument recorded |
| `ER-09` | Opening binders, local identities and emitted names | Open; local checks/argument recorded |

The current structure/inductive preparation accepts supported type parameters
and **runtime-only constructor fields**. Proof/type constructor fields are
refused; they are not silently omitted. Function/proof/type erasure has separate
supported rules. This distinction matters when defining the relation and when
reporting profile coverage.

Original-IR layout validation checks declared ownership, instantiation, field
sets/types, constructor order and match bindings. It cannot prove that those
layouts are the correct source layouts. A future per-compilation witness can
reuse the actual erasure metadata, but the witness and checker also need an
explicit argument for the property being checked.

### S4 — normalization and expression evaluation

| Rule | Required correspondence | General status |
| --- | --- | --- |
| `N-01` | Resolved recursion identity, hygiene and source origins | Open; local checks/argument recorded |
| `N-02` | Structural major and generalized domain restrictions | Open; local checks/argument recorded |
| `N-03` | Function-valued motive and simultaneous state | Open; local checks/argument recorded |
| `N-04` | Public wrapper and full calling contract | Open; local checks/argument recorded |
| `EV-01` | Literal evaluation | Open; local checks/argument recorded |
| `EV-02` | Lexical and global variables | Open; local checks/argument recorded |
| `EV-03` | Enabled intrinsic evaluation | Open; local checks/argument recorded |
| `EV-04` | Lambda closure and captured environment | Open; local checks/argument recorded |
| `EV-05` | Callee and application evaluation | Open; local checks/argument recorded |
| `EV-06` | Let initializer, shadowing and body | Open; local checks/argument recorded |
| `EV-07` | Conditional control | Open; local checks/argument recorded |
| `EV-08` | Record construction | Open; local checks/argument recorded |
| `EV-09` | Field projection | Open; local checks/argument recorded |
| `EV-10` | Constructor value and ordered fields | Open; local checks/argument recorded |
| `EV-11` | Match scrutinee, tag and branch bindings | Open; local checks/argument recorded |

For ordinary changing-parameter recursion, the supported transformation builds
a function-valued structural motive. Invariant parameters remain captured;
the selected changing state is applied to the recursive result. The planner
checks supported domains and actual recursion identities, and ordinary
elaboration checks the worker and public wrapper. The complete public type,
parameter order and grouping remain authoritative.

Those checks do not establish the computational equation for every admitted
definition. The corresponding argument must explain binding substitution,
simultaneous state, old-scope argument evaluation, captures and the wrapper's
meaning. The previously qualified finite worker signatures and 87 worker
observations remain evidence about their stated revisions and cases.

**The concrete repeated Nat-major lowering is repaired in the reviewed source.**
`psEraseNatRecursorAlternatives` now places a computed major in one fresh typed
IR let before zero testing and predecessor formation. Variables and literals
are already values. The related partial-application repair similarly captures
a computed callee and already supplied computed operands in ordered typed lets
before returning the completion lambda. Both changes have a frozen shared
source-evaluation fixture; execution on the integrated source is still required.

The general recursor, substitution, grouped-call and capture relations remain
open. These local sequencing corrections do not prove those relations for all
accepted programs. Structure-recursion majors, ordinary matches and zero-branch
matches have their own once-only lowering paths and associated proof premises.

### S5 — emitted TS/JS and runtime machinery

| Rule | Required correspondence | General status |
| --- | --- | --- |
| `TS-01` | Binding/property syntax, fresh names and namespace capture | Open; local checks/argument recorded |
| `TS-02` | Brand/tag and public constructor-object representation | Open; local checks/argument recorded |
| `TS-03` | General expression templates and observable order | Open; local checks/argument recorded |
| `TS-04` | General declarations, generator trampoline and closures | Open; local checks/argument recorded |
| `TS-05` | Eta inlining | Open; local checks/argument recorded |
| `TS-06` | Specialized count loop | Open; local checks/argument recorded |
| `TS-07` | Tail-loop lowering and simultaneous updates | Open; local checks/argument recorded |
| `TS-08` | Global initialization and function registration order | Open; local checks/argument recorded |
| `TS-09` | TypeScript 7 emission to JavaScript and runtime boundary | Open; local checks/argument recorded |

The backend has three distinct optimization families—restricted eta inlining,
a recognized constructor-count loop, and monomorphic tail-loop lowering—before
or alongside the general generator emitter. Each recognizer success needs its
own preservation argument. A recognizer failure follows the unchanged general
path; it must not be reported as an optimization proof.

The target representation uses private brand/tag symbols, interfaces or tagged
unions, and an exported object of constructor members. **Constructor labels are
properties of that object, not separate global bindings.** Monomorphic
nullary constructors are stored objects; other constructors are factories.
Their argument order and immutable use are part of the representation relation.

The generator runtime exposes synchronous public functions. Its registry,
invocation requests and pending-computation stack need a simulation argument
that preserves arguments, result/error propagation and closure capture.
The presence of an unregistered-function fallback in the runtime does not
enable portable foreign IO or an unspecified host callback ABI.

## 4. Portable target admission

The candidate
[Sh1Target.lean](../../../packages/backend-ts/src/Ps/BackendTs/Sh1Target.lean)
adds a local admission boundary for the source-owned backend:

```lean
psSh1CheckTarget
  (maxSteps : Nat) (module : PsVerifiedIrModule) :
  Except PsSh1TargetError PsSh1TargetReport
```

The atomic source route calls it **after complete original-IR typing and before
emitting that same IR**. It returns the policy
`psc0-sh1-ts-target/1`, acceptance, traversal completion and visited task count,
or an explicit code/detail/owner/path error. There is no caller-supplied
acceptance token or bypass flag. Calling this lower-level validator directly on
handcrafted IR does not turn that IR into admitted strict source.

### Names and actual emitter scopes

The validator checks the actual emitted ASCII identifier domain produced by
the current erasure sanitizer. It treats binding names and property names
separately: a field named `do` is valid, while a binding named `do` is refused.
Quoted constructor keys are permitted, except `__proto__`; that key and
unquoted data fields with the same spelling are rejected because object-literal
prototype semantics do not supply the intended ordinary field.

The check protects the exact helper names, builtins and generated private
names used by the enabled templates. It does not blacklist every
`__ps`-prefixed name. For example, a source local `__ps_a` is valid because
the intrinsic IIFE's similarly named parameter scopes its implementation body;
the source operand is evaluated as a call argument outside that scope.

The check also distinguishes namespaces that original IR represents
separately:

- A local generic cannot capture the builtin `Array` or an actual module
  layout name used in emitted type positions.
- A constructor expression cannot use an inductive namespace captured by a
  runtime local. This follows the actual
  `InductiveName[quotedConstructor]` expression template.
- Ordinary runtime local shadowing of an ordinary global declaration stays
  legal, and a local matching an inductive name is allowed when no constructor
  expression under that scope uses the namespace.
- A local generic named `Generator` remains legal. Authored generator return
  annotations use `__ps$Computation`; its `Generator` definition is outside
  that local generic scope.

For a source-owned module, the policy conservatively requires one distinct
public name per layout/declaration. Some interface/value overlaps would be legal
in TypeScript's separate namespaces; they are outside this conservative source
policy. A layout with an emitted value plus an ordinary declaration of the
same name is an actual duplicate emitted binding. Core source declaration
identity is already unique, so this policy does not require a new source
dialect.

### Initialization and lexical scope

The original IR checker predeclares signatures; that supports typing recursion
but does not establish runtime initialization. Target admission therefore
checks each runtime variable under the actual emitted declaration order. It
must be a lexical local, an earlier runtime declaration, or the current
positive-runtime-arity function.

The walk includes nested lambdas and all branches. This deliberately refuses
some safe deferred forward references, avoiding an unproved termination or
call-demand analysis. A nongeneric declaration with no runtime parameters is
an eager value, even if its result is a function; its self-reference is refused.
Positive-arity self is allowed because that declaration emits a callable
function. This admission says nothing about termination of a deliberately
handcrafted recursive body.

A let initializer is walked in the old scope, then its body under the new
binding. Match binders and lambda parameters are scoped precisely. Layout
constructors and runtime helpers are emitted before authored declaration
bodies, so their availability is checked through their actual namespace and
layout rules, rather than inventing ordinary earlier-variable entries.

Static compatibility inspection found that normalized worker/public batches
are ordered worker first, preparation preserves the batches, and erasure
preserves the surviving declaration order. Erasure sanitizes local names and
avoids declaration/runtime local output names. The runtime prelude emits
List/Option/Except plus Prod layouts; Array is its declared runtime/type entry,
not an emitted layout global. These facts support the design; only an actual
qualification run establishes target acceptance of the complete current
source closure.

### Freshness and bounded work

The policy protects the exact first match temporary `__ps$match$0`, current
brand/tag candidates, implementation names, and the count/tail helpers that are
actually emitted. Expression/type depth is at most 4096. Lambda parameter
weighting additionally accounts for the possible eta-to-let expansion before
the bounded name scan. Within that admitted domain, the existing fresh-name
search can choose its first protected candidate without relying on its
overflow fallback.

One worklist task consumes one unit of `maxSteps`; identifier characters are
visited through tasks too. Remaining tasks at zero allowance cause
`target-fuel-exhausted`. Depth exhaustion also refuses explicitly.
`accepted=true` and `traversalComplete=true` are returned only after the
whole task list finishes.

The existing persistent name index and String/Nat primitives have separate
finite costs. `visitedSteps` does not count every hashing, bucket-scan or
allocation operation. No whole-program time, memory or stack guarantee follows
from this counter. The complete existing IR input check and host carrier
boundary remain required before arbitrary generated values enter the atomic
path.

The proposed T01–T29 target cases exercise acceptance, name/capture collisions,
forward/self initialization and explicit exhaustion. They are independent
admission cases, not implementations of a second compiler. Deep stress may be
target-only and must say so; ordinary refusal witnesses should also establish
their complete original-IR typing. Their executed receipts belong to the
actual qualifying source and compiler.

## 5. Existing models and proofs that can be reused

The [Core model](../../../packages/core/src/Ps/Core/Expr.lean) and
[original IR model](../../../packages/compiler-ir/src/Ps/CompilerIr/Model.lean)
are useful foundations. Their current names do not make either object a
preservation certificate. The bounded
[Meta.Reduce implementation](../../../packages/meta/src/Ps/Meta/Reduce.lean)
is a WHNF operation with its own limits; it is not a complete source/runtime
evaluator to use as an oracle.

The sibling
[Refinement proof at the inspected revision](https://github.com/dwijayuda/pskernel/blob/ed5d00aca0743bde583b45fe7756dd494ac3960f/pscv0/packages/pscv-theory/proof/Ps/Theory/Refinement.lean)
establishes conditional top-level proof omission, reflexive conversion and one
fixed specialization example. The omission statement assumes the supplied
classifier says true. It does not prove classifier correctness, nested proof
independence, PSC0 erasure, generator semantics or the whole enabled language.
The sibling cursor proof establishes its list/cursor invariant only.
The existing erasure contract still records a global unproved target.

These sources can supply definitions or narrowly applicable lemmas. The
strict work must not cite them as a theorem for a different compiler, relation
or source revision. No kernel, provider, definitional-equality, cache or theory
implementation change is needed to retain and check source-owned provenance
or to introduce the local target admission boundary.

## 6. Finite completion sequence and stopping criteria

The practical sequence is recorded in the JSON ledger:

1. Freeze the enabled value/runtime/source domains and explicit refusals.
2. Compose portable source admission, preparation, one erasure, same-IR typing,
   target admission and that same emitter.
3. Qualify the exact current path through native/generated compilers and keep
   independent provider receipts and actual product hashes.
4. Retain truthful normalization origins and establish the actual reachable
   binder/layout invariant by a complete source argument or a correct checked
   association witness.
5. Define the common value/environment/evaluation relation, including closures,
   grouped calls, faults and demand, and relate the generator machine to it.
6. Discharge the normalization and erasure families, including the general
   demand, substitution and capture arguments around the repaired local rules.
7. Discharge the eleven expression rules, three optimization families, name/
   initialization arguments and explicit TS/JS toolchain assumptions.
8. Reconcile every mandatory normative coverage requirement before activation.

The first three phases are concrete, bounded implementation/evidence work and
can be completed without pretending that the later proof obligations have
already passed. Each later phase must address a recorded obligation rather
than create a continuing cycle of undirected test fixes.

Optional fixed-width/floating scalars, additional targets, foreign ABI support,
nested patterns, omitted-domain inference and a new total-array authoring
library are excluded only on their existing optional/deferred terms.
**Existing Array intrinsic obligations are included.** Empty layouts/matches
and inhabited zero-field structures are now implemented in the reviewed batch.
Their raw-source, grammar, native, original-IR and emitted-type gates remain
mandatory, together with general regular-data preservation. Their absence
from the compiler's own source corpus does not remove that obligation.

The completion criterion is a fully reconciled mandatory ledger with its
general arguments/evidence and one immutable exact-source qualification.
Until then, compiler-qualified implementation milestones are useful results
with their own scope, and `strictSh1Qualified` and
`semanticContractQualified` remain false.
