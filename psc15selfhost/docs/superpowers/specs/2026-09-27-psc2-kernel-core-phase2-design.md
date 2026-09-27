# PSC2 KernelCore Phase 2 Design

Status: proposed architectural design awaiting review
Date: 2026-09-27
Branch: `psc2/kernel-core-phase2`
Base: Phase 1 accepted at `27e12a3979ed0acf23d2ba70d5daf58658b892ac`

## Purpose

Phase 2 extends the minimal trusted `pskernel-core` from the Phase 1 foundation (`Data`, `Name`, `Level`, `Expr`, `Subst`) with the smallest declaration and environment substrate needed before reduction, inference and definitional equality can be implemented.

The design must preserve the main goals of the minimal kernel effort:

- trusted source remains written in the PSC1-compatible `.lean` subset;
- every trusted module must pass the actual PSC1 self-host compiler check, not only Lean compilation;
- semantic behavior is compared directly with the mature `PSC1Kernel` reference;
- replay, JSON transport, host IO, caches, hash indexes and runtime optimization remain outside the trusted semantic core;
- Phase 1 remains frozen as an accepted baseline;
- full Lean 4 equivalence is not claimed unless separately proven.

## Context

The mature reference has three relevant modules:

- `PSC1Kernel/Declaration.lean`: declaration metadata and semantic declaration variants;
- `PSC1Kernel/Environment.lean`: semantic environment operations plus a 256-bucket derived lookup index and hashing machinery;
- `PSC1Kernel/LocalContext.lean`: local declarations and local context operations.

The reference environment intentionally mixes semantic behavior with an optimization layer. Copying that module directly would enlarge the trusted core with arrays, hashing, fixed bucket counts, derived index maintenance, fallback synchronization logic and replacement bookkeeping.

Phase 2 therefore separates semantic meaning from runtime optimization.

## Chosen architecture

The trusted Phase 2 core grows to:

```text
Ps.KernelCore
├── Data
├── Name
├── Level
├── Expr
├── Subst
├── Declaration
├── Environment
└── LocalContext
```

The trusted environment uses simple structural storage:

```text
Environment {
  constants : PsKernelCoreList PsKernelCoreConstantInfo
  quotInitialized : Bool
}
```

Lookup is newest-first linear structural `Name` comparison.

This is intentionally slower than the mature reference implementation. Runtime performance is not part of semantic meaning. A later optimized runtime environment may maintain hash buckets or other indexes provided differential gates prove it preserves the same observable lookup semantics.

## Explicitly outside the Phase 2 trusted core

The following must not be introduced into trusted `pskernel-core` source during Phase 2:

- `Array`-backed declaration indexes;
- bucket hashing;
- string hashing;
- cache structures;
- replay protocols;
- JSON codecs;
- file/process/IO integration;
- host cancellation or resource policy;
- backend/compiler imports;
- `Lean.*` or `Std.*` implementation dependencies;
- `unsafe`, `partial`, custom macros or elaborators;
- host `List` or host `Option` in trusted data structures;
- namespace-based convenience if it is outside the accepted PSC1 source profile.

## Phase 2A: declaration model

Phase 2A starts with only the declaration forms needed by the next semantic phases.

### Initial trusted declaration forms

```text
DefinitionSafety
  unsafeDef
  safe
  partialDef

ReducibilityHints
  opaqueHint
  abbrevHint
  regular(height)

ConstantBase
  name
  levelParams
  type

AxiomInfo
DefinitionInfo
TheoremInfo
OpaqueInfo

ConstantInfo
  axiomInfo
  defnInfo
  thmInfo
  opaqueInfo
```

### Initial trusted accessors

The first declaration slice implements only semantic accessors needed by future reduction and checking:

```text
base
name
levelParams
type
deltaValue?
hints?
isUnsafe
isPartial
isDefinition
definition?
```

`DefinitionSafety` and `ReducibilityHints` retain the mature reference behavior, including reducibility ordering semantics needed by later delta reduction.

### Deferred declaration forms

These are deliberately postponed until their own semantic admission phases:

- `InductiveInfo`;
- `ConstructorInfo`;
- `RecursorRule`;
- `RecursorInfo`;
- `QuotInfo` and `QuotKind`.

This keeps Phase 2 from preloading inductive and quotient machinery before it is semantically used.

When these forms are later added, they must be independently validated by the kernel rather than trusted merely because an elaborator/lowering stage produced them.

## Phase 2B: semantic environment

Phase 2B adds the minimal declaration environment.

### Trusted representation

```text
PsKernelCoreEnvironment {
  constants : PsKernelCoreList PsKernelCoreConstantInfo
  quotInitialized : Bool
}
```

### Trusted operations

```text
empty
find?
contains
size
addUnchecked
replaceUnchecked
add
markQuotInitialized
```

The observable semantics must match the mature reference for the supported declaration forms.

### Duplicate checks

`add` must remain fail-closed for:

- duplicate constant names;
- duplicate universe parameter names.

Required list operations are implemented on `PsKernelCoreList`, using existing structural `PsKernelCoreName` equality.

### No trusted lookup index

The Phase 2 trusted core does not include:

```text
environmentBucketCount
stringBucketHashCore
stringBucketHash
Name.bucketHash
EnvironmentIndex
insertEnvironmentIndex
buildEnvironmentIndex
```

These are performance implementation details and do not define kernel meaning.

## Phase 2C: local context

Phase 2C adds local declarations required by future type checking.

### Local declarations

```text
LocalDecl
  localDecl(index, name, userName, type, binderInfo)
  letDecl(index, name, userName, type, value)
```

Semantic accessors:

```text
name
userName
type
value?
binderInfo
```

### Local context

```text
LocalContext {
  decls : PsKernelCoreList PsKernelCoreLocalDecl
  nextIndex : Nat
}
```

Operations:

```text
empty
find?
addLocal
addLet
```

The implementation must remain structurally recursive and PSC1-self-hostable.

## PSC1 source discipline

Every trusted Phase 2 module is source of the future self-hosted kernel and therefore must compile unchanged through the current PSC1 compiler path.

The dedicated source gate must reject or fail on constructs unsupported by the current PSC1 bootstrap language. Phase 1 already demonstrated that Lean-accepted syntax is not sufficient evidence of portability.

Phase 2 trusted source therefore follows these rules:

1. no `partial`;
2. structural total recursion only;
3. no host `List` / `Option` representation dependencies;
4. no `IO`;
5. no `Lean` / `Std` imports;
6. no `unsafe`, `extern`, `implemented_by`;
7. no custom syntax/macros/elaborators;
8. no hidden backend/compiler dependencies;
9. no performance-only state in the semantic model;
10. every module must pass actual `psc1 check`.

## TDD and parity strategy

Each Phase 2 subphase follows the same RED → GREEN pattern established by Phase 1.

### Phase 2A declaration gate

RED tests first import the missing `Ps.KernelCore.Declaration` and exercise:

- all initial declaration constructors;
- `DefinitionSafety` classification;
- `ReducibilityHints` ordering and regular detection;
- base/name/type/level parameter accessors;
- definition delta value extraction;
- reducibility hint extraction;
- unsafe/partial/definition classification.

Expected results are compared to equivalent values in `PSC1Kernel.Declaration`.

### Phase 2B environment gate

Differential cases include:

- empty lookup;
- newest-first lookup;
- add unique declaration;
- reject duplicate constant name;
- reject duplicate universe parameter names;
- replace existing declaration;
- environment size;
- Quot initialization flag transition.

The trusted implementation may use a different representation from `PSC1Kernel.Environment`; observable behavior must match for the supported declaration subset.

### Phase 2C local-context gate

Differential cases include:

- empty context;
- insertion order;
- incrementing local indices;
- local lookup;
- let lookup;
- binder-info behavior;
- let value extraction.

## Gate layering

A Phase 2 subphase is not complete until all applicable gates pass:

```text
Lean compilation
        ↓
direct differential parity vs PSC1Kernel
        ↓
KernelCore boundary/isolation tests
        ↓
actual PSC1 self-host source check
        ↓
Phase 2 aggregate assurance
        ↓
existing full `npm run check`
```

No regression gate may be weakened to make Phase 2 pass.

## Size discipline

Phase 2 continues the Phase 1 size report.

Track at minimum:

- trusted `.lean` file count;
- bytes;
- nonblank/noncomment LOC;
- dependency closure;
- new semantic entry points;
- host/runtime dependencies, expected to remain zero.

There is no arbitrary LOC target. The objective is minimum semantic surface while retaining required behavior.

## Integration boundary

Phase 2 does not yet make `pskernel-core` the compiler's live admission provider.

The compiler path remains:

```text
source
  -> parse / resolve / elaborate
  -> AdmissionReadyModule
  -> erasure
  -> VerifiedIR
```

The later integration milestone remains:

```text
AdmissionReadyModule
  -> pskernel-core
  -> CheckedCore / CheckedModule
  -> erasure
  -> VerifiedIR
```

Do not rename existing canonical encoding validation to `CheckedCore` before genuine kernel admission exists.

## Deferred Phase 3+ work

Not part of this Phase 2 implementation:

- WHNF/reduction;
- inference/checking;
- definitional equality;
- proof irrelevance/eta;
- recursor reduction;
- Quot primitive checking;
- inductive positivity/admission;
- mutual/nested-inductive lowering;
- runtime caching;
- compiler admission integration.

## Acceptance criteria

Phase 2 is accepted only when:

1. Declaration, Environment and LocalContext trusted modules exist in `pskernel-core`;
2. their trusted implementations use PSC1-subset `.lean` and pass actual `psc1 check`;
3. direct parity tests pass against the mature reference for the implemented semantic surface;
4. the trusted environment contains no hashing/index/caching machinery;
5. Phase 1 gates remain green;
6. full existing repository regression checks remain green;
7. size/evidence reporting is updated;
8. an acceptance document records exactly what is and is not established.

## Non-claims

Successful Phase 2 acceptance will not by itself prove:

- formal equivalence with Lean 4;
- complete Lean 4 kernel compatibility;
- complete declaration admission correctness;
- inductive or Quot correctness;
- reduction/defeq correctness;
- compiler checked-core integration.

It establishes only that the minimal trusted declaration/environment/local-context substrate matches the mature reference over the tested supported boundary and is self-host-source-compatible with PSC1.
