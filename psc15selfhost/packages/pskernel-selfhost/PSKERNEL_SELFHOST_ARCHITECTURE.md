# PSKernel Self-Host Architecture and Development Guardrails

This document is normative project guidance for `packages/pskernel-selfhost`.
It exists to prevent development drift after the portable self-host milestone.

## 1. Product goal

Build one readable, self-hostable Lean-4.34-compatible kernel implementation
whose source is accepted by the PSC1 portable subset and has two primary
execution paths:

```text
Ps.KernelSelfHost/*.lean
        |
        +-- PSC compiler / backend-ts --> TypeScript / JavaScript
        |
        +-- Lean 4 compiler -----------> native executable/library
```

There is one semantic source of truth.

## 2. Decisions that are intentionally fixed

Unless a new architecture review explicitly replaces this document:

1. **No second hand-maintained kernel implementation.**
   - no Rust kernel rewrite;
   - no C++ kernel rewrite;
   - no separately maintained WASM kernel source;
   - no duplicated `spec/reference/fast` semantic implementations.

2. **No formal-verification project is required for the production milestone.**
   Assurance comes from exact theory mapping, source review, Lean-4.34
   conformance, differential tests, and self-host fixed-point evidence.

3. **Compatibility is defined by rules, not by project size.**
   The normative feature-completeness source is
   `LEAN_4_34_COMPATIBILITY.json`.

4. **The semantic source must stay PSC1-self-hostable.**
   Every theory/runtime refactor must remain accepted by:
   - the shared portable source profile;
   - `psc1 check`;
   - canonical `.lean -> .ps` generation and recheck;
   - generated fixed-point tooling.

5. **Performance data structures are non-semantic.**
   Caches and indexes may accelerate an existing judgment, but must never
   create a semantic fact or change declaration acceptance.

6. **Lean 4.34 behavior is the compatibility authority.**
   Target version:
   - Lean 4.34.0
   - commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`

7. **The generated kernel is not the default authority until provider parity is
   explicitly accepted.**
   `lean434-wasm` remains the default checker during hardening.

## 3. Source architecture

The direction is one semantic implementation with theory/runtime separation.

```text
Ps.KernelSelfHost
|
+-- core data
|   Name / Level / Expr / Instantiate / Declaration
|
+-- theory-facing algorithms
|   inference / reduction / definitional equality
|   Quot / ordinary inductives / mutual / nested
|
+-- admission
|   declarations / theorem / opaque / mutual definitions / inductives
|
+-- runtime-only acceleration
    Runtime/EnvironmentIndex
    Runtime/Cache
    Runtime/NativeReduction
```

The distinction is:

```text
Theory-facing modules:
    answer "what does Lean mean?"

Runtime modules:
    answer "how do we make that same result fast?"
```

## 4. Self-host coding discipline

Prefer coding patterns already proven by the compiler self-host closure:

- flat package-prefixed declarations;
- explicit algebraic data;
- explicit `Except` errors;
- structural recursion;
- curried workers when changing arguments would violate structural recursion;
- explicit fuel only when structural recursion is insufficient;
- no fallback after failed checking;
- no semantic patching of generated JavaScript;
- no hidden host dependency in semantic modules;
- explicit host capabilities for optional runtime behavior.

If ordinary source syntax is not accepted by PSC1, adapt the source to an
already-proven portable coding pattern before extending the compiler.

## 5. Theory readability policy

The kernel should be teachable from its source.

Every major rule should eventually provide:

- stable rule ID;
- short mathematical judgment or semantic statement;
- one-paragraph explanation;
- exact Lean 4.34 implementation locator;
- pskernel implementation symbol;
- conformance/differential test reference.

Large files should be split by theory concept, not by arbitrary line count.

Preferred examples:

```text
Theory/DefEq/
    LazyDelta.lean
    FinalRules.lean

Runtime/
    Cache.lean
    EnvironmentIndex.lean
    NativeReduction.lean
```

Target: a reader familiar with dependent type theory should be able to learn
Lean kernel behavior by following `KERNEL_THEORY.md` and the source modules.

## 6. Feature-completeness definition

"Feature complete" means all required rows in
`LEAN_4_34_COMPATIBILITY.json` are implemented and tested.

It does **not** mean:

- the kernel is large;
- one demo succeeded;
- Mathlib happened to compile;
- every Lean frontend feature exists in pskernel.

Required completion gate:

```text
compatibility matrix: no required missing rules
conformance/differential suite: green
PSC1 source closure: green
canonical .ps closure: green
generated source fixed point: green
generated artifact fixed point: green
generated runtime smoke: green
```

## 7. Conformance policy

Do not require an enormous Mathlib replay as a prerequisite.

Maintain a finite, rule-complete Lean-4.34 conformance suite. Every rule should
have at least:

- positive case;
- negative case;
- edge case where meaningful.

High-risk areas should have multiple adversarial cases:

- universe equivalence;
- lazy delta ordering;
- non-transitive defeq cache behavior;
- proof irrelevance;
- structure eta;
- projections from Prop;
- Quot reduction;
- indexed inductive positivity/elimination;
- mutual recursors;
- nested flatten/restore.

## 8. Performance policy

Optimize representations before theory algorithms.

Priority order:

1. indexed environment lookup;
2. indexed expression/inference/WHNF/defeq caches;
3. cached expression metadata/hash;
4. sharing/interning only if profiling justifies it;
5. algorithmic shortcuts only after the above.

Every performance change must preserve the same semantic result.

Never replace Lean's non-transitive successful/failed pair caches with
union-find/equivalence closure.

## 9. Backend policy

The same portable source serves both supported execution paths.

### JavaScript

```text
portable Lean-subset source
        -> PSC compiler
        -> backend-ts
        -> TypeScript / JavaScript
```

Purpose:

- Node;
- browser;
- npm;
- easy embedding;
- bootstrap/self-host artifact.

### Native

```text
same .lean source
        -> Lean 4 compiler
        -> native executable/library
```

Purpose:

- large proof checking;
- CI;
- servers;
- performance-sensitive builds.

Do not manually fork semantics by backend.

## 10. Native-reduction trust boundary

Lean 4.34's deprecated `Lean.reduceBool` / `Lean.reduceNat` path extends the
TCB to a compiler/interpreter.

PSKernel models this as an optional runtime capability.

No provider:

```text
native reduction step unavailable
-> continue ordinary kernel reduction
```

Provider installed:

```text
Lean.reduceBool / Lean.reduceNat marker
-> provider evaluates closed target constant
-> kernel receives Bool/Nat result
```

The provider belongs in `Runtime/NativeReduction`, not in core type theory.

## 11. Change review checklist

Before promoting any kernel change, ask:

1. Does it preserve Lean 4.34 semantics?
2. Does it remain PSC1 portable?
3. Is it theory or runtime?
4. If runtime, can it change acceptance? If yes, redesign it.
5. Does it preserve fail-closed behavior on error/exhaustion?
6. Does the compatibility matrix need updating?
7. Does `KERNEL_THEORY.md` need updating?
8. Is there a focused differential/conformance test?
9. Does canonical `.ps` still recheck?
10. Does fixed-point generation still converge?

If any answer is unknown, the change is not ready for promotion.

## 12. Anti-drift rules

Do not:

- add a new backend merely because it is interesting;
- add language features to the kernel package that belong in the compiler;
- optimize by changing observable defeq order;
- hide fallback behavior behind caches/indexes;
- treat self-host fixed point as proof of semantic correctness;
- treat one successful project replay as proof of feature completeness;
- patch generated JavaScript to fix semantic problems;
- change the target Lean version silently.

If priorities conflict, use this order:

```text
semantic correctness
> self-host preservation
> explainability
> compatibility evidence
> performance
> convenience
```
