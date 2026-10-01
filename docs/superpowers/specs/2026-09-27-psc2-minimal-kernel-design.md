# PSC2 Minimal Trusted Kernel Design

Status: proposed architecture for `psc2/minimal-selfhost-psc15`.

Date: 2026-09-27

## Purpose

Shrink the eventual ProofScript trusted kernel substantially without throwing away the mature Lean 4.34 compatibility work already present in `psc15selfhost/packages/pskernel/PSC1Kernel`.

The project MUST preserve two distinct assets:

1. the existing PSC1Kernel as a mature compatibility/reference implementation and differential oracle;
2. a new, smaller trusted semantic core that PSC2 can eventually use as its actual checked-core admission provider.

The goal is capability preservation, not source-code identity with Lean's kernel implementation.

## Success criteria

The minimal kernel effort succeeds only when all of the following are true:

- the trusted semantic implementation is materially smaller and easier to audit than the current PSC1Kernel package;
- PSC2 retains the ability to support the useful expressive capabilities of Lean 4 through elaboration/lowering into the small core;
- foundational observable behavior remains aligned with the pinned final Lean 4.34 semantics covered by the existing K2-K8 evidence;
- complex source features such as mutual/nested inductives are moved above the trusted core where possible, but their lowered artifacts are independently validated by the small kernel;
- replay, JSON parsing, corpus tooling, host I/O, native-result maps, optimization caches and other assurance/runtime machinery do not enlarge the trusted semantic core;
- the existing PSC1Kernel remains available as a differential oracle until the small core passes the required parity gates;
- no claim of full Lean 4.34 equivalence is made unless separately proven.

## Non-goals

This refactor does NOT initially:

- delete or rewrite the mature PSC1Kernel implementation;
- put the new core into the PSC2 self-host bootstrap closure immediately;
- make Rust or Wasm part of the kernel bootstrap requirement;
- prove formal equivalence with Lean 4.34;
- reproduce every Lean runtime optimization or host resource-control mechanism inside the semantic core;
- force all Lean source syntax or elaboration conveniences into the trusted kernel.

## Current state

`psc15selfhost/packages/pskernel` currently combines several classes of functionality:

- foundational syntax and semantic structures: Name, Level, Expr, declarations, environment, local context;
- substitution/instantiation;
- type inference, WHNF/reduction and definitional equality;
- declaration admission;
- quotient behavior;
- ordinary, mutual and nested inductive processing;
- stateful checker/session/caching-oriented machinery;
- replay and NDJSON decoding;
- native-result map support;
- extensive oracle and regression infrastructure.

The current package is intentionally marked as a bounded assurance reference rather than a portable bootstrap dependency. That separation should be preserved while the small core is developed.

## Architectural decision

Create a sibling package rather than shrinking the mature reference implementation in place.

```text
psc15selfhost/packages/

  pskernel/
    PSC1Kernel/...              # frozen/mature Lean-4.34 reference + oracle

  pskernel-core/
    src/Ps/KernelCore/...       # new minimal trusted semantic kernel

  pskernel-compat/              # later, if needed
    Lean/replay/lowering adapters
```

Initially `pskernel-core` MUST NOT enter the self-host fixed-point dependency closure. It should mature under differential gates first. Once parity is strong enough, a separate milestone may wire it between `AdmissionReadyModule` and erasure.

## Trusted semantic boundary

The new trusted core should contain only functionality that cannot safely be delegated to an untrusted elaborator/lowering layer without independent checking.

### Keep inside the trusted core

The intended trusted semantic surface is:

```text
Name / identifiers needed by core terms
Universe Level representation and comparison
Core Expr representation
substitution / lifting / instantiation
Declaration representation
immutable Environment lookup/publication rules
LocalContext required by checking
WHNF/core reduction required by typing
Type inference/checking
Definitional equality
proof irrelevance and required eta behavior
projection and recursor computation
Quot primitive admission/computation
primitive inductive admission and positivity validation
recursor/computation-rule validation
closed declaration admission
small explicit checker configuration
```

Observable semantic behavior already covered by PSC1Kernel K2-K8 must not be weakened merely to reduce line count.

### Move outside the trusted core

The following MUST remain outside the minimal TCB unless later evidence demonstrates that they are foundationally unavoidable:

```text
Replay.lean
ReplayJson.lean
lean4export protocol state
NDJSON decoding
corpus fixture handling
oracle/test code
NativeMap provider implementation
filesystem/process/environment access
heartbeat/cancellation/stack/memory host controls
TypeScript/Rust/Wasm backend logic
source parser/elaborator logic
compiler project traversal
performance-only memoization/caches
```

Complex source-level inductive conveniences should also move upward when possible:

```text
mutual-inductive source preprocessing
nested-inductive source preprocessing/restoration
structure/source sugar
recursive-function source lowering
```

However, moving these upward does NOT allow trusting their output. They must lower to a canonical primitive representation that the small kernel validates independently.

## Inductive strategy

This is the highest-value semantic simplification.

Preferred architecture:

```text
PSC2 / Lean-compatible source
          |
          v
elaborator + inductive lowering
  - structures
  - mutual groups
  - nested occurrences
  - source conveniences
          |
          v
canonical primitive inductive declaration
          |
          v
---------------- TRUST BOUNDARY ----------------
          |
          v
pskernel-core
  - validates headers/universes
  - validates constructor result shapes
  - validates strict positivity / recursive occurrences
  - derives or validates recursor metadata
  - validates computation rules
  - publishes only checked declarations
```

The lowering layer may be wrong without becoming a soundness problem: invalid lowered declarations must be rejected by `pskernel-core`.

The current `MutualInductive.lean` and `NestedInductive.lean` remain reference/oracle implementations during this migration. Their semantics and existing differential fixtures should guide the lowering contract rather than being deleted early.

## Quotient strategy

Keep Lean-compatible quotient primitives in the trusted core.

Quot behavior is small relative to the cost and risk of translating quotient semantics into a different foundation. The new core should preserve the observable Quot admission and reduction behavior already covered by PSC1Kernel's direct regressions.

## Definitional equality strategy

Do not reduce capability by weakening definitional equality.

The small core must preserve required observable behavior including, where covered by the pinned Lean 4.34 baseline:

- beta/zeta/iota/projection reduction;
- proof irrelevance;
- function eta;
- required structure eta/unit-like behavior;
- lazy delta ordering semantics;
- recursor reduction;
- quotient reduction;
- literal normalization paths that affect checking;
- deterministic recursion-depth behavior.

The implementation can be simpler than the current optimized/stateful organization, but the semantics cannot be casually simplified.

## Reference checker vs executable checker

Use two layers if that makes the trusted semantics easier to audit:

```text
KernelCore.Reference
  simple, direct, pure semantic implementation
           |
           | differential/parity gates
           v
KernelCore.Runtime
  optional optimized implementation
  caches/sessions/performance machinery
```

Optimization MUST NOT define semantics. Cache keys, scope and ordering must be regression-tested if an optimized implementation is introduced.

The first implementation should prefer the smallest clear reference checker over performance.

## Host policy boundary

Keep deterministic checker configuration explicit and portable:

- `maxRecDepth` semantics may remain an explicit kernel configuration because current PSC1Kernel already differentially models Lean's deterministic rule;
- `maxNatSize` may remain explicit configuration so the kernel stays pure and portable;
- heartbeat accounting, cancellation transport, native stack checks and process-memory checks remain host/runtime policy;
- native reduction stays behind an optional fail-closed provider interface rather than embedding compiler/runtime internals into the kernel.

The provider implementation is outside the TCB. The core only defines the narrow behavior needed to consume an optional result safely.

## Package staging

### Stage A - introduce the small-core package

Add `psc15selfhost/packages/pskernel-core` with:

```text
package.json
src/Ps/KernelCore/
  Name.lean
  Level.lean
  Expr.lean
  Subst.lean
  Declaration.lean
  Environment.lean
  LocalContext.lean
  Reduce.lean
  DefEq.lean
  Infer.lean
  Quot.lean
  Inductive.lean
  Kernel.lean
```

Exact module factoring may change, but package responsibility must remain small and semantic.

Initial package metadata:

```json
{
  "proofscript": {
    "bootstrap": false,
    "portable": true,
    "role": "minimal-trusted-kernel"
  }
}
```

`bootstrap` remains false until the new kernel passes its parity gates and is intentionally wired into the PSC2 checked-core path.

### Stage B - reference parity adapters

Add test-only/reference adapters capable of presenting the same normalized declarations/terms to PSC1Kernel and KernelCore.

Do not make KernelCore depend on Replay/ReplayJson. The assurance side may depend on both kernels.

### Stage C - semantic parity

Port behavior in the following order:

1. Name/Level/Expr and substitution;
2. declaration/environment/local context;
3. type inference and core WHNF;
4. definitional equality;
5. Quot;
6. primitive inductive admission and recursor computation;
7. resource/configuration boundaries.

Each step is accepted only after direct differential tests agree with the mature PSC1Kernel and, where already available, the pinned Lean 4.34 oracle.

### Stage D - lower complex inductives outside the TCB

Introduce an untrusted compatibility lowering path for mutual/nested source forms into KernelCore's canonical primitive inductive representation.

The resulting primitive declaration must be revalidated completely by KernelCore.

### Stage E - corpus/replay parity

Run existing K7/K8 corpora through an assurance adapter so both the reference kernel and KernelCore receive equivalent declaration streams.

The new core is not mature enough for integration until representative positive and adversarial corpora agree.

### Stage F - compiler integration

Only after the parity threshold is met:

```text
AdmissionReadyModule
        |
        v
pskernel-core provider
        |
        v
CheckedCore / CheckedModule
        |
        v
erasure
        |
        v
VerifiedIR
```

At this milestone erasure must accept only the checked artifact. The current codec-validation preparation boundary must not simply be renamed to CheckedCore.

## Compatibility definition

There are two different compatibility targets and documentation MUST keep them separate.

### PSC2 capability compatibility

PSC2 should retain the ability to express and verify the useful Lean capabilities after elaboration/lowering into the core.

This is the primary product requirement.

### Lean 4.34 kernel behavioral parity

For declaration streams within the supported normalized compatibility boundary:

```text
Lean 4.34 accepts  <=> KernelCore accepts
Lean 4.34 rejects  <=> KernelCore rejects
```

This remains an engineering/differential target until formally proven. Existing PSC1Kernel evidence is an oracle and regression baseline, not a mathematical proof of equivalence.

## Required gates before integration

The following gates are mandatory before KernelCore can replace the current admission-ready placeholder in PSC2:

1. **Source discipline**
   - all KernelCore modules pass the intended PSC1-compatible source profile or a stricter documented portable subset;

2. **Foundational direct parity**
   - Level, Expr substitution/instantiation, WHNF, infer and defeq differential tests against PSC1Kernel;

3. **Lean direct oracle parity**
   - reuse existing pinned-Lean-4.34 direct cases where they apply;

4. **Quot parity**
   - positive reduction/admission and collision/adversarial behavior;

5. **Inductive parity**
   - ordinary/indexed/recursive/Prop-elimination/recursor cases;
   - malformed/non-uniform/non-positive cases fail closed;

6. **Complex-inductive lowering parity**
   - mutual/nested source forms lower outside KernelCore and then pass KernelCore validation;
   - invalid lowerings are rejected;

7. **K7/K8 assurance adapter**
   - canonical Init.Prelude and existing representative corpora agree under the bounded acceptance matrix;

8. **Adversarial parity**
   - current soundness regressions remain closed;

9. **Portable compilation**
   - unchanged KernelCore source compiles through the PSC1/PSC2 portable pipeline to TypeScript/JavaScript;

10. **Compiler integration gate**
   - PSC2 compiler can route AdmissionReadyModule -> KernelCore -> CheckedCore -> erasure without a bypass path.

## Size discipline

Do not optimize for an arbitrary LOC target. Optimize for trusted semantic surface.

Track at least:

- trusted source modules;
- trusted source bytes/LOC;
- dependency closure size;
- number of semantic entry points;
- number of host/runtime dependencies;
- K2-K8 parity coverage retained.

A shrink is valid only if the trusted surface decreases while semantic/capability gates remain green.

## Migration rules

1. Never delete mature PSC1Kernel behavior before KernelCore proves parity for that behavior.
2. Never weaken an existing adversarial regression to make the smaller core pass.
3. Keep the pinned Lean 4.34 source/behavior as semantic authority for compatibility work.
4. Keep reference/oracle code out of KernelCore dependencies.
5. Keep compiler/backend code out of KernelCore dependencies.
6. Prefer elaboration/lowering or libraries over adding trusted core features.
7. When a source feature can be expressed as canonical core plus a checked lowering, keep it above the kernel.
8. Kernel changes require an explicit semantic justification and a regression.
9. No plugin may bypass KernelCore admission or manufacture CheckedCore directly.
10. Do not claim full Lean equivalence from bounded parity gates.

## First implementation slice

The first code slice should deliberately be small:

```text
pskernel-core package scaffold
+ Name
+ Level
+ Expr
+ substitution/instantiation
+ direct differential tests against PSC1Kernel
```

This slice proves the package boundary, source discipline and differential-testing architecture before type checking or inductive admission is copied.

Only after this slice is green should the implementation move to inference/reduction/defeq.

## End state

The desired long-term architecture is:

```text
PSC2 source language
  TS-like ergonomics + Lean-style proofs
                |
                v
parser / resolver / elaborator / tactics / plugins
                |
                v
complex-feature lowering
(mutual/nested/structures/recursion/contracts/etc.)
                |
                v
canonical Core
                |
                v
+-------------------------------------------+
| pskernel-core                              |
| tiny trusted semantic checker             |
| universes / Pi / Prop / defeq / Quot /    |
| primitive inductives / recursors           |
+-------------------------------------------+
                |
                v
CheckedCore
                |
                v
erasure -> VerifiedIR
                |
      +---------+---------+
      |         |         |
      v         v         v
     TS        Rust      Wasm

Assurance side (outside TCB):
PSC1Kernel reference <-> Lean 4.34 oracle <-> replay/corpora/adversarial gates
                    ^
                    |
             differential tests
                    |
               pskernel-core
```

This design preserves the expensive Lean-compatibility knowledge already accumulated while giving PSC2 a substantially smaller permanent trusted computing base.