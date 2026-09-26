# PSCKernel Literal PSC1 Lean Port Design

Date: 2026-09-26
Status: approved design, implementation not started
Branch: `selfhost/psckernel-fresh-port`
Base: `selfhost/psc1-lean-bootstrap` at `20c44dec16de2aacfaaba8447ad7c3c5ed4cc972`

## Purpose

Create a fresh, independent PSC1-compatible `.lean` rewrite of the existing handwritten `lean-ts-kernel` package, named **PSCKernel**, inside the self-host workspace.

The new package is intentionally a literal structural port rather than a redesign. It should follow the existing TypeScript kernel's files, folders, public responsibilities, and algorithms as closely as PSC1-compatible Lean permits.

The goal is to obtain a second independently authored kernel implementation that can eventually become the production/self-host kernel while the current TypeScript kernel remains an independent differential oracle.

## Semantic authority and references

Three sources have distinct roles:

1. **Lean 4.34 final kernel semantics** are the semantic authority.
2. **`lean-ts-kernel`** is the structural, API, algorithmic, and behavioral port target.
3. **The existing `psc1-kernel` implementation** is comparison/test evidence only. Its source is not copied into PSCKernel.

If the TypeScript kernel and pinned Lean 4.34 behavior disagree, PSCKernel follows Lean 4.34 and records the discrepancy with a regression test.

No claim of full Lean 4.34 equivalence may be made merely because the PSCKernel parity gates pass.

## Package identity

Path:

```text
selfhost/packages/psckernel/
```

Package name:

```text
@proofscript/psckernel
```

Role:

```text
trusted-kernel
```

Primary source language:

```text
PSC1-compatible .lean
```

The package participates in the existing self-host npm workspace and Lake build. It must remain portable enough to pass the PSC1 source audit and later follow the ordinary self-host path:

```text
.lean -> canonical .ps -> shared IR -> TS/JS
```

## Deliberate independence

PSCKernel is a fresh port. It does not reuse the self-host `@proofscript/core` or `@proofscript/environment` implementation for its kernel representation.

Duplication is intentional for this package:

```text
lean-ts-kernel Name         -> PSCKernel Name
lean-ts-kernel Level        -> PSCKernel Level
lean-ts-kernel Expr         -> PSCKernel Expr
lean-ts-kernel Environment  -> PSCKernel Environment
lean-ts-kernel LocalContext -> PSCKernel LocalContext
lean-ts-kernel TypeChecker  -> PSCKernel TypeChecker
lean-ts-kernel Kernel       -> PSCKernel Kernel
```

This preserves implementation independence and makes TypeScript <-> PSCKernel differential testing meaningful.

PSCKernel must not depend on the existing standalone `psc1-kernel` source implementation.

## Package/file layout

The default rule is file parity:

```text
foo.ts -> Foo.lean
```

The initial package layout mirrors `lean-ts-kernel`:

```text
selfhost/packages/psckernel/
├── package.json
└── src/
    └── Ps/
        ├── PSCKernel.lean
        └── PSCKernel/
            ├── Core/
            │   ├── Checks.lean
            │   ├── Declaration.lean
            │   ├── Environment.lean
            │   ├── Expr.lean
            │   ├── Instantiate.lean
            │   ├── Level.lean
            │   ├── LocalContext.lean
            │   └── Name.lean
            │
            ├── Kernel/
            │   ├── Kernel.lean
            │   ├── Names.lean
            │   ├── PrimitiveNames.lean
            │   ├── Primitive.lean
            │   ├── Quotient.lean
            │   ├── State.lean
            │   ├── TypeChecker.lean
            │   ├── Inductive/
            │   │   ├── Ordinary.lean
            │   │   └── Nested.lean
            │   ├── Primitive/
            │   │   ├── Bitwise.lean
            │   │   ├── Condition.lean
            │   │   ├── Fuel.lean
            │   │   └── Wf.lean
            │   └── Reduction/
            │       ├── Literals.lean
            │       ├── Nat.lean
            │       ├── Native.lean
            │       ├── Quot.lean
            │       └── Recursor.lean
            │
            └── Integration/
                ├── ExactJson.lean
                └── Lean4Export.lean
```

The correspondence is intentionally close to the TypeScript package:

```text
src/index.ts                     -> Ps/PSCKernel.lean
src/core/*                       -> Ps/PSCKernel/Core/*
src/kernel/*                     -> Ps/PSCKernel/Kernel/*
src/kernel/inductive/*           -> Ps/PSCKernel/Kernel/Inductive/*
src/kernel/primitive/*           -> Ps/PSCKernel/Kernel/Primitive/*
src/kernel/reduction/*           -> Ps/PSCKernel/Kernel/Reduction/*
src/integration/*                -> Ps/PSCKernel/Integration/*
```

A module may diverge from exact line-level translation when required by Lean/PSC1 syntax or ownership rules, but responsibility and observable behavior stay close to the TS counterpart.

## Public surface

`Ps.PSCKernel` is the public barrel analogous to `src/index.ts`.

The PSC1/Lean public surface should expose corresponding kernel-owned concepts where implemented:

- `Environment`
- kernel error/result types
- declaration types
- `Name`
- `Level`
- `Expr`
- instantiation helpers
- `LocalContext`
- `Kernel`
- `TypeChecker`
- `KernelLimits`
- inductive admission
- primitive admission
- native evaluator boundary
- Lean4Export replay integration

API shape should remain recognizable relative to `lean-ts-kernel`, while idiomatic Lean structures/namespaces replace JavaScript classes and mutation syntax.

## Translation rules from TypeScript to PSC1 Lean

### Classes and methods

TypeScript classes become structures plus namespaced functions. Public method behavior should remain close to the TS API.

Example pattern:

```text
class Kernel { addDefinition(...) }
```

becomes conceptually:

```text
structure Kernel where ...
namespace Kernel
  def addDefinition ...
end Kernel
```

### Mutable state

JavaScript mutation must become explicit state transitions.

Where the TS implementation mutates:

- environment contents;
- revision counters;
- local contexts;
- type-checker caches;
- recursion depth;
- temporary checking state;

PSCKernel uses explicit values/state structures. Transactional TS behavior must remain transactional: failed declaration admission must not partially commit semantic state.

### Identity and caches

JS object identity must not become semantic behavior in the port.

Caches are implementation details. They may use PSC1-friendly representations or be omitted initially if omission changes only performance, not observable semantics. Any cache whose behavior affects correctness must be modeled explicitly.

### Errors

PSCKernel owns a typed kernel error/result boundary. Exact JavaScript stack text is not semantic.

Differential tests normalize errors and compare at least:

- accept vs reject;
- semantic rejection category;
- declaration/term involved where relevant;
- important error payload when relied upon by consumers.

### Native reduction

Native reduction remains an injected and fail-closed provider boundary.

The portable trusted kernel must not invoke Node, npm, TypeScript APIs, arbitrary JavaScript, or compiler IR directly. If no supported native evaluator is supplied, the relevant native reduction step does not silently succeed through a weaker path.

### Host/runtime limits

Deterministic semantic/resource checks modeled by the TS kernel and Lean 4.34, such as kernel recursion-depth and Nat-size checks, are preserved where they are part of current kernel behavior.

OS/process cancellation, stack probing, memory monitoring, filesystem access, and similar host policy remain outside the portable semantic kernel unless the TS package currently makes them part of the stable kernel API.

## Dependency rule

PSCKernel is a trusted leaf below higher compiler packages. It must not depend on:

- `meta`
- `elab`
- `checked-core`/checked compiler layers
- `compiler`
- `backend-ts`
- `backend-rust`
- `backend-wasm`
- Node host adapters
- TypeScript compiler APIs

The package may depend only on bootstrap facilities that do not import another semantic kernel implementation.

No dependency may be introduced from PSCKernel to the existing TS kernel at runtime. TS interaction belongs only in differential tests/tooling.

## Self-host integration

Add a Lake library for PSCKernel in `selfhost/lakefile.lean`, with roots corresponding to the package modules.

The package must participate in:

1. workspace validation;
2. PSC1 source audit;
3. Lake build;
4. kernel unit tests;
5. differential tests;
6. later `.lean -> .ps` emission;
7. later generated TS/JS compilation;
8. later self-host generations and fixed-point verification.

The first implementation phase does not switch production kernel authority. The current TypeScript kernel remains the production/oracle implementation until later provider/cutover work is separately gated.

## Port order

Port in dependency order rather than alphabetically:

1. `Core/Name`
2. `Core/Level`
3. `Core/Expr`
4. `Core/Instantiate`
5. `Core/Checks`
6. `Core/Declaration`
7. `Core/LocalContext`
8. `Core/Environment`
9. `Kernel/Names`
10. `Kernel/PrimitiveNames`
11. `Kernel/State`
12. `Kernel/Reduction/*`
13. `Kernel/Primitive/*`
14. `Kernel/Primitive`
15. `Kernel/Quotient`
16. `Kernel/TypeChecker`
17. `Kernel/Inductive/Ordinary`
18. `Kernel/Inductive/Nested`
19. `Kernel/Kernel`
20. `Integration/ExactJson`
21. `Integration/Lean4Export`
22. public `Ps/PSCKernel.lean` barrel

Each slice should compile and carry tests before moving semantic complexity upward.

## Test strategy

### Per-module tests

For each ported slice:

1. translate/re-express relevant `lean-ts-kernel` unit tests;
2. add PSC1/Lake tests;
3. compare observable behavior with the TS kernel;
4. compare subtle semantics with pinned Lean 4.34 source/behavior;
5. add a regression before fixing any discovered discrepancy.

### Progressive parity gates

Grow assurance in this order:

```text
core representation parity
-> name/level/expr operations
-> substitution/instantiation parity
-> reduction parity
-> inference/check parity
-> WHNF parity
-> definitional-equality parity
-> declaration admission parity
-> primitive parity
-> quotient parity
-> ordinary inductive parity
-> nested/mutual inductive parity
-> native-provider parity
-> Lean4Export replay parity
-> bounded real-corpus replay
```

### Differential harness

The TS kernel and PSCKernel remain independently executable implementations.

A differential fixture should serialize the same inputs to both checkers and compare normalized results. It must not share checker implementation code between the two sides.

The existing standalone PSC1 kernel may be added as a third comparison implementation, but PSCKernel acceptance cannot depend solely on agreeing with it.

### Lean 4.34 oracle checks

Where behavior is subtle or disagreement appears, compare with final pinned Lean 4.34 semantics, especially:

- universe normalization/equality;
- infer/check behavior;
- WHNF;
- definitional equality reduction ordering;
- theorem/opaque reducibility;
- unsafe/partial declaration rules;
- recursors;
- projections;
- Quot;
- primitive Nat operations;
- native markers;
- ordinary/mutual/nested inductives;
- resource bounds represented in the checker.

## Acceptance definition

A file is not complete merely because it compiles.

A ported unit is complete when:

- its corresponding TS responsibility is implemented;
- PSC1 source audit passes;
- Lake compilation passes;
- relevant unit tests pass;
- relevant differential tests pass;
- known semantic deviations from TS are justified by pinned Lean 4.34 and regression-gated.

The whole fresh port reaches feature parity only when every exported stable TS-kernel responsibility has either:

- a corresponding PSCKernel implementation with passing parity evidence, or
- an explicit documented exclusion justified as host-only/non-semantic and absent from the trusted portable API.

## Non-goals for the fresh-port phase

The initial port does not:

- delete or weaken `lean-ts-kernel`;
- replace production kernel authority;
- merge code from the existing `psc1-kernel` implementation;
- redesign the frontend/compiler architecture;
- make TS/Rust/Wasm backends kernel-shaped;
- claim formal or full Lean 4.34 equivalence;
- require a fixed-point self-host claim before the kernel implementation itself is complete.

Those are later migration/assurance milestones.

## Cutover relation to later self-hosting

After PSCKernel reaches broad parity, a separate provider/cutover phase may make it authoritative:

```text
initial:
  production = lean-ts-kernel
  differential = psckernel

parity phase:
  production = lean-ts-kernel
  shadow = psckernel

cutover:
  production = psckernel
  oracle = lean-ts-kernel

final self-host architecture:
  PSC1/PSCKernel source -> generated target implementation
  independently authored TS kernel -> differential oracle only
```

No automatic semantic fallback from PSCKernel to the TS kernel is allowed after authority flips.

## Completion reporting

Progress reports distinguish:

- files structurally ported;
- files compiling;
- semantic test coverage;
- TS differential parity;
- Lean 4.34 oracle coverage;
- real-corpus replay status;
- `.lean -> .ps` source readiness;
- generated JS kernel readiness;
- production cutover status;
- self-host/fixed-point status.

Do not collapse these into one percentage when they measure different milestones.
