# PSKernel Self-Host Architecture and Development Guardrails

This document is normative project guidance for `packages/pskernel-core`.
It exists to prevent development drift after the portable self-host milestone.

`PSKERNEL_REFERENCE.md` is adopted as the canonical **target architecture and
migration reference**. This document retains the non-negotiable product and
semantic guardrails. If a target-architecture idea conflicts with these
guardrails, Lean-4.34 compatibility, PSC1 portability, or fail-closed checking,
the guardrail wins until an explicit architecture review changes it.

## Development authority

GitHub is the canonical development state. Follow
`GITHUB_FIRST_WORKFLOW.md` before starting or integrating work on this branch.
Local worktrees are optional execution caches only and must not become hidden
project state.

## 1. Product goal

Build one readable, self-hostable Lean-4.34-compatible kernel implementation
whose source is accepted by the PSC1 portable subset and has two primary
execution paths:

```text
Ps.KernelCore/*.lean
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
   Production promotion continues to rely on exact theory mapping, source
   review, Lean-4.34 conformance, differential tests, portable-source self-host
   checks, and provider-parity gates. The Assurance Plane described in
   `PSKERNEL_REFERENCE.md` is a long-term strengthening track; it must not
   block current architecture/readability/performance work unless a specific
   assurance milestone is explicitly promoted to a release gate.

3. **Compatibility is defined by rules, not by project size.**
   The normative feature-completeness source is
   `LEAN_4_34_COMPATIBILITY.json`.

4. **The semantic source must stay PSC1-self-hostable.**
   Every theory/runtime refactor must remain accepted by:
   - the shared portable source profile;
   - `psc1 check`;
   - canonical `.lean -> .ps` generation and recheck.

   Generated compiler/kernel fixed-point reproduction is optional/manual and is
   not a normal development gate.

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

The canonical target is the Execution Plane in `PSKERNEL_REFERENCE.md`.
The current source may retain migration-era paths while it moves there
incrementally, but there remains exactly one production semantic implementation.

```text
Ps.KernelCore
|
+-- Core
|   Name / Level / Expr / Declaration / substitution
|
+-- Environment
|   semantic declarations + derived lookup structures
|
+-- Checker
|   context / state / inference / reduction / recursor / defeq
|   one explicit recursive wiring owner (Checker/Knot)
|
+-- Admission
|   declarations / Quot / ordinary + mutual + nested inductives
|
+-- Runtime/Acceleration
|   caches / indexes / derived metadata
|
+-- Runtime/Capability
|   explicit target-specific trusted capabilities
|
+-- API
|   KernelContract-v1 / checked sessions / provider-neutral boundary
|
'-- SelfHost
    canonical portable semantic root
```

The distinctions are:

```text
Semantic rules:
    answer "what does Lean 4.34 mean?"

Acceleration:
    makes the same judgment faster and must preserve answers

Trusted capability:
    can affect acceptance and therefore extends the TCB

Assurance tooling:
    validates the production implementation but is outside its semantic closure
```

The long-term Assurance Plane (formal specification/refinement, external
oracles, adversarial corpora, fuzzing and receipts) lives outside the production
semantic root and never becomes a fallback semantic implementation.

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

Preferred final ownership examples:

```text
Checker/DefEq/
    LazyDelta.lean
    FinalRules.lean

Runtime/Acceleration/
    Cache.lean
    CachePolicy.lean
    EnvironmentIndex.lean

Runtime/Capability/
    Lean434NativeReduction.lean
```

During migration, existing `Theory/*` and top-level compatibility paths may
remain as temporary forwarding/import layers, but canonical source must not
depend on those shims.

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
Lean-native build/tests: green
```

Generated source/artifact fixed points may be run manually for bootstrap
releases, but they do not block readability or performance work.

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

The provider is a target-specific trusted capability. The final target path is
`Runtime/Capability/Lean434NativeReduction.lean` (the current
`Runtime/NativeReduction.lean` path may remain during migration). It is not
ordinary cache/index acceleration and it is not core type theory.

## 11. Optional generated-bootstrap evidence

`SELFHOST_EVIDENCE.json` records a historical/promoted generated fixed-point
checkpoint. It remains useful for release/bootstrap auditing, but normal kernel
development does not regenerate it after every semantic, readability, or
performance commit.

Run `.github/workflows/psc1kernel-core-fixed-point.yml` manually when a
release or bootstrap checkpoint specifically needs regenerated source/artifact
fixed-point evidence.

## 12. Change review checklist

Before promoting any kernel change, ask:

1. Does it preserve Lean 4.34 semantics?
2. Does it remain PSC1 portable?
3. What is its semantic role: rule, acceleration, trusted capability, adapter,
   or assurance-only?
4. If it is acceleration, can changing/removing it change a semantic answer?
   If yes, the refinement invariant is broken and the change must not be
   promoted as an acceleration-only change.
5. Does it preserve fail-closed behavior on error/exhaustion?
6. Does the compatibility matrix need updating?
7. Does `KERNEL_THEORY.md` need updating?
8. Is there a focused differential/conformance test?
9. Does canonical `.ps` still recheck?
10. If the change touches backend emission/bootstrap policy, does the optional
    generated-kernel smoke/fixed-point workflow still make sense?

For ordinary theory/readability/performance work, items 1-9 are the mandatory
promotion checks.

## 13. Anti-drift rules

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
> portable-source self-host preservation
> explainability
> compatibility evidence
> performance
> convenience
```
