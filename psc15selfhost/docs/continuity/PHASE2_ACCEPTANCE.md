# PSC2 KernelCore Phase 2 Acceptance

Date: 2026-09-27

## Status

PSC2 KernelCore Phase 2 semantic substrate is accepted on the isolated execution branch:

`psc2/kernel-core-phase2-work`

The exact implementation and assurance commit accepted by this record is:

`2bc0f71533b395149ecfcf789ac8f161a8618514`

That commit was verified by GitHub Actions workflow `PSC2 minimal kernel`, run:

`36284056463`

Run URL:

`https://github.com/dwijayuda/pskernel/actions/runs/36284056463`

The workflow concluded `success` on the exact accepted implementation SHA above.

This document is intentionally committed after the verified implementation head. Its own documentation-only commit is not substituted for the tested implementation SHA.

The approved Phase-2 planning branch remains:

`psc2/kernel-core-phase2`

This work branch should be reconciled into that branch deliberately; do not force-push or replace either branch blindly.

## Toolchain

- Lean: `4.34.0`
- Node: `22`
- Trusted source profile: PSC1-compatible `.lean`
- Self-host acceptance path: actual `psc1 check` through `scripts/check-kernel-core-source.mjs`

## Accepted scope

Phase 2 extends the accepted Phase-1 foundations with the smallest declaration, global-environment, and local-context substrate needed before reduction and type checking.

The trusted KernelCore remains intentionally simple and semantic rather than optimized.

### Trusted modules

The accepted trusted source set contains 9 `.lean` files:

1. `packages/pskernel-core/src/Ps/KernelCore.lean`
2. `packages/pskernel-core/src/Ps/KernelCore/Data.lean`
3. `packages/pskernel-core/src/Ps/KernelCore/Declaration.lean`
4. `packages/pskernel-core/src/Ps/KernelCore/Environment.lean`
5. `packages/pskernel-core/src/Ps/KernelCore/Expr.lean`
6. `packages/pskernel-core/src/Ps/KernelCore/Level.lean`
7. `packages/pskernel-core/src/Ps/KernelCore/LocalContext.lean`
8. `packages/pskernel-core/src/Ps/KernelCore/Name.lean`
9. `packages/pskernel-core/src/Ps/KernelCore/Subst.lean`

### New Phase-2 semantic surface

`Declaration.lean` adds only the initial four global declaration forms:

- axiom;
- definition;
- theorem;
- opaque declaration.

It also carries definition safety, reducibility hints, shared constant metadata, and the minimal semantic accessors/classifiers required by the environment.

`Environment.lean` adds a trusted global environment with:

- newest-first structural lookup;
- containment;
- size;
- unchecked insertion;
- first/newest matching replacement;
- checked insertion with duplicate-name and duplicate-universe-parameter rejection;
- Quot-initialization state tracking.

`LocalContext.lean` adds:

- local declarations;
- let declarations;
- name, user-name, type, value, and binder-info accessors;
- newest-first local lookup;
- monotone local declaration indices.

`Data.lean` adds only the tiny `PsKernelCoreResult` carrier needed by checked environment insertion.

## Trusted Environment architecture

The trusted environment is deliberately linear and structural.

It does **not** contain:

- hash tables;
- derived name indexes;
- arrays for semantic storage;
- caches;
- buckets;
- synchronization/fallback index logic;
- host/runtime lookup machinery.

This is intentional. Performance-oriented indexes or caches may be added outside the trusted semantic core later, provided they cannot change accepted semantics and the kernel still validates the primitive result independently.

## Differential parity gates

The exact accepted implementation head passed all of these differential/semantic gates:

- `PSC2_KERNEL_CORE_BOUNDARY: PASS`
- `PSC2_KERNEL_CORE_NAME_PARITY: PASS`
- `PSC2_KERNEL_CORE_LEVEL_PARITY: PASS`
- `PSC2_KERNEL_CORE_EXPR_PARITY: PASS`
- `PSC2_KERNEL_CORE_SUBST_PARITY: PASS`
- `PSC2_KERNEL_CORE_DECLARATION_PARITY: PASS`
- `PSC2_KERNEL_CORE_ENVIRONMENT_PARITY: PASS`
- `PSC2_KERNEL_CORE_LOCAL_CONTEXT_PARITY: PASS`

The Phase-2 fixtures compare the new trusted semantics against the mature `PSC1Kernel` reference for the admitted Phase-2 surface.

Important pinned behaviors include:

- reducibility ordering, including equal-height regular hints;
- exact definition-safety classification;
- exact absence/presence of delta values and reducibility hints;
- duplicate global declaration rejection;
- non-adjacent duplicate universe parameter rejection such as `[u, v, u]`;
- newest-first environment lookup;
- first/newest matching environment replacement;
- Quot-initialization idempotence;
- local declaration indices and accessors;
- newest-first local-context shadowing.

## PSC1 self-host evidence

The accepted implementation head passed the actual PSC1 source/self-host gate for every trusted module:

`KERNEL_CORE_SOURCE_PROFILE: PASS (9 PSC1-subset, self-host-checkable modules)`

Each of the 9 trusted files independently reported:

`KERNEL_CORE_SELFHOST_CHECK: PASS`

This is stronger than merely compiling under official Lean: the flattened trusted closure is accepted by the current PSC1 parser/elaborator/admission path.

Two portability issues were discovered and fixed without weakening the gate:

1. Lean-valid `>` syntax in reducibility ordering was replaced with a PSC1-native structurally recursive Nat comparison.
2. A parenthesized postfix structure projection rejected by PSC1 was rewritten through a local binding before field projection.

## Aggregate assurance

The accepted implementation commit passed:

`npm run assurance:kernel-core:phase2`

The command runs, in order:

1. KernelCore PSC1 source/self-host gate;
2. Phase-1 boundary parity;
3. Name parity;
4. Level parity;
5. Expr parity;
6. substitution parity;
7. Declaration parity;
8. Environment parity;
9. LocalContext parity;
10. trusted source size report.

The existing Phase-1 assurance command remains unchanged.

The accepted implementation commit also passed the full existing repository regression command:

`npm run check`

That included workspace shape, all-portable source validation, KernelCore self-host checking, layout drift, bootstrap closure isolation, IR neutrality, bootstrap tests, regression tests, TypeScript backend tests, Rust backend tests, and Wasm backend tests.

## Size evidence

The accepted Phase-2 size report recorded:

| Measure | KernelCore | Comparable PSC1Kernel | Ratio |
| --- | ---: | ---: | ---: |
| Trusted/comparable `.lean` files | 9 | 22 | — |
| Semantic source bytes | 36,773 | 306,641 | 0.1199 |
| Nonblank/noncomment LOC | 966 | 7,403 | 0.1305 |

Reference comparison excludes:

- `Test/**`;
- `Replay.lean`;
- `ReplayJson.lean`;
- `NativeMap.lean`.

The current trusted substrate is therefore about 12.0% of the comparable reference byte count and about 13.1% of its comparable semantic LOC. This is a size comparison only, not a claim that Phase 2 already implements all behavior present in the larger reference kernel.

## Bootstrap boundary

`pskernel-core` remains outside the active PSC2 bootstrap closure in Phase 2.

The existing bootstrap closure gate remained green:

`PSC2_BOOTSTRAP_CLOSURE: PASS`

This phase does not switch the compiler admission provider and does not make `pskernel-core` the active compiler kernel yet.

## Deferred semantic work

The following remain explicitly outside Phase 2 and must not be implied by this acceptance record:

- weak-head reduction / reduction semantics;
- expression inference and checking;
- definitional equality;
- Quot semantics/admission;
- primitive inductive admission and positivity checking;
- constructor and recursor validation;
- mutual/nested inductive lowering/validation integration;
- compiler `CheckedCore` / real kernel-provider integration.

Those should be introduced in later phases using the same RED -> GREEN differential parity and actual PSC1 self-host acceptance discipline.

## What this acceptance does not claim

Phase 2 does **not** establish:

- full Lean 4 equivalence;
- complete Lean 4 kernel compatibility;
- full `PSC1Kernel` feature parity;
- inductive correctness;
- Quot correctness;
- reduction correctness;
- definitional-equality correctness;
- a completed kernel replacement;
- a completed PSC2 self-host kernel switch.

`PSC1Kernel` remains the mature compatibility/differential oracle.

## Next architectural step

The next kernel phase should begin from this accepted semantic substrate rather than broadening Phase 2 retroactively.

A sensible next dependency order is:

1. minimal reduction/WHNF substrate;
2. inference/checking substrate;
3. definitional equality;
4. Quot and primitive inductive admission;
5. only then compiler-side checked-core/kernel-provider integration.

Every new trusted slice must continue to pass both:

- differential parity against the reference behavior for that slice; and
- actual PSC1 self-host source acceptance.
