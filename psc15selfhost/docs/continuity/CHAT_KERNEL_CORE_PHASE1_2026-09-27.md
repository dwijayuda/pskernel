# Chat Continuity — PSC2 Minimal Kernel Core Phase 1

Date: 2026-09-27

## Branch ownership

This document belongs to branch:

`psc2/kernel-core-phase1`

This branch was created from commit:

`ef7e9bddf0ec47f8c8408ff0ff46bbcf60d182c0`

The original shared branch was:

`psc2/minimal-selfhost-psc15`

At the time this branch was split, the shared branch had already advanced independently to:

`72f32ac718ae75725ca3d63aa28477bccf897927`

Therefore **do not treat `psc2/minimal-selfhost-psc15` and `psc2/kernel-core-phase1` as interchangeable**. Another chat/agent was actively writing to the shared branch. Future work from this chat should continue only on `psc2/kernel-core-phase1` until an intentional reconciliation/merge is performed.

## What this chat is about

The user asked whether the `PSC1Kernel` inside `psc15selfhost` could be made materially smaller while retaining Lean 4 compatible capabilities.

The agreed architectural answer was:

- preserve the existing `PSC1Kernel` as the mature Lean-4.34 compatibility/reference oracle;
- build a sibling `pskernel-core` as the smaller trusted semantic kernel;
- reduce TCB size by removing replay, JSON, native-map, host/runtime, cache/session and other non-semantic machinery from the trusted core;
- move source-language conveniences and complex lowering above the kernel where possible;
- keep the kernel independently validating primitive semantic forms;
- do not remove foundational semantics such as universes, dependent functions, definitional equality, inductives/positivity, recursors and Quot merely to reduce line count;
- do not claim full Lean 4 equivalence without evidence;
- retain differential parity against the mature `PSC1Kernel` throughout the migration.

The user then approved implementation and explicitly required:

> use PSC1 subset `.lean`, make it self host able

That is a non-negotiable constraint for this branch.

## Architecture decision

The intended layering is:

```text
PSC2 source language
        |
        v
parser / elaborator / lowering / tactics / plugins
        |
        v
canonical primitive core
        |
        v
---------------- TRUST BOUNDARY ----------------
        |
        v
pskernel-core
  Name / Level / Expr / substitution
  declarations / environment
  inference / reduction / defeq
  Quot
  primitive inductive validation
        |
        v
CheckedCore
```

The old `PSC1Kernel` remains the compatibility oracle until parity evidence is strong enough to switch admission providers.

## Documents already created by this chat

The branch contains the design and implementation plan:

- `docs/superpowers/specs/2026-09-27-psc2-minimal-kernel-design.md`
- `docs/superpowers/plans/2026-09-27-psc2-minimal-kernel-phase1.md`

There is also a broader continuity packet under:

- `psc15selfhost/docs/continuity/PSC2_MINIMAL_SELFHOST_CONTEXT.md`
- `psc15selfhost/docs/continuity/PSC2_KERNEL_CORE_DECISIONS.md`
- `psc15selfhost/docs/continuity/PSC2_NEXT_SESSION_CHECKLIST.md`

This file is the chat-specific supplement and records the later branch split.

## Phase 1 scope

Phase 1 is intentionally limited to foundational semantics:

```text
packages/pskernel-core/
  Data
  Name
  Level
  Expr
  Subst / Instantiate
```

It must remain:

- `bootstrap: false` for now;
- `portable: true`;
- outside the PSC2 minimal self-host bootstrap closure until later integration;
- free of `Lean.*`, `Std.*`, `IO`, `unsafe`, custom macros/elaborators and other non-PSC1 portable conveniences;
- compilable through the actual PSC1 self-host compiler path, not merely accepted by Lean 4.

## Important discovery: PSC1-subset constraints are stricter than Lean syntax

The implementation work repeatedly demonstrated that "Lean code that looks small" is not enough.

The real PSC1 compiler currently imposes constraints such as:

- no `namespace` convenience in the trusted portable source;
- no `partial` trusted definitions if they cannot reach the admission-ready path;
- no convenient multi-scrutinee/nested pattern forms that the PSC1 parser/elaborator does not support;
- recursive definitions must satisfy PSC1 structural-recursion analysis;
- non-recursive explicit arguments may need to remain invariant across recursive calls;
- host `List` matching can be unsuitable for the self-host closure, so tiny kernel-local data carriers are preferable.

The rule for this branch is therefore:

> A trusted KernelCore module is not complete until both Lean parity tests and `psc1 check` succeed on the flattened module closure.

Do not weaken this requirement to make implementation easier.

## Current KernelCore implementation status at branch split

### Package boundary

`psc15selfhost/packages/pskernel-core` exists as a sibling of the existing reference `pskernel` package.

It is intentionally excluded from the active PSC2 bootstrap closure.

### Tiny local data carriers

`Ps.KernelCore.Data` defines small self-host-friendly generic carriers:

- `PsKernelCoreOption`
- `PsKernelCoreList`

These avoid importing a broader host/runtime data layer into the trusted core.

### Name

`Ps.KernelCore.Name` exists and covers:

- anonymous names;
- string components;
- numeric components;
- structural equality;
- membership;
- duplicate detection;
- UTF-8-safe string comparison.

A key fix was rewriting string equality to satisfy PSC1 structural-recursion rules instead of using `partial` or changing several recursive arguments.

### Level

`Ps.KernelCore.Level` exists and covers the current Phase-1 universe operations including:

- `zero`, `succ`, `max`, `imax`, `param`, `mvar`;
- structural equality;
- normalization helpers;
- semantic equivalence cases used by the parity suite;
- parameter substitution through a small kernel-local substitution spine;
- metavariable detection.

A key fix was rewriting level equivalence into a PSC1-friendly curried structural-recursion shape rather than carrying a changing `(fuel,left,right)` argument set.

### Verified green checkpoint before Expr

At commit `f8879a697e144ea6e5f361d58d7b6f87177fd328`, CI showed:

- KernelCore boundary: PASS
- Name parity vs `PSC1Kernel`: PASS
- Level parity vs `PSC1Kernel`: PASS
- bootstrap closure isolation: PASS
- KernelCore PSC1 source/self-host profile: PASS

This is the first point where `Name + Level` were not merely Lean-compilable but were accepted by the actual PSC1 compiler path.

## Expr TDD state

The next Phase-1 task is the core expression representation.

A RED differential fixture was added before production code, covering the reference semantic surface:

- binder info variants;
- Nat and String literals;
- `bvar`;
- `fvar`;
- `mvar`;
- `sort`;
- `const`;
- `app`;
- `lam`;
- `forallE`;
- `letE`;
- `lit`;
- `mdata`;
- `proj`.

The RED test failed for the intended reason:

`Ps.KernelCore.Expr` did not yet exist.

The last intentional commit from this chat before branch separation is:

`ef7e9bddf0ec47f8c8408ff0ff46bbcf60d182c0`

Its purpose is the `Expr` RED-test checkpoint.

## Next exact task

Continue TDD on `psc2/kernel-core-phase1`:

1. Add `packages/pskernel-core/src/Ps/KernelCore/Expr.lean`.
2. Use only PSC1-subset `.lean`.
3. Keep the first implementation representational only:
   - binder info;
   - literals;
   - metadata as the minimal compatible representation;
   - all 12 reference expression constructors;
   - use `PsKernelCoreList PsKernelCoreLevel` rather than host `List` for constant universe arguments if needed for self-hostability.
4. Import `Ps.KernelCore.Expr` from `Ps.KernelCore.lean`.
5. Run the expression parity test.
6. Run all earlier Name/Level/boundary gates.
7. Run `scripts/check-kernel-core-source.mjs` so the same source is checked through PSC1.
8. Only after Expr is green should `Subst/Instantiate` begin.

Do not add inference, WHNF, defeq, Quot or inductive checking in this slice.

## Merge/reconciliation rule

Because another chat was simultaneously modifying `psc2/minimal-selfhost-psc15`:

- never force-push either branch;
- do not blindly merge the shared branch into this one;
- compare branches first;
- reconcile by semantic area/file ownership;
- preserve all green gates from both branches;
- if both branches touched the same KernelCore files, review line-by-line rather than choosing the newest version automatically;
- only merge after the combined branch passes the full KernelCore parity + PSC1 self-host gates.

## Notable checkpoints from this chat

Not exhaustive, but important known commits include:

- `a7243d04d13d5bfe27611bca0b1be5805cf2497f` — minimal kernel design
- `8d671644c30391933fb1c817b5291f88cdc99546` — Phase-1 implementation plan
- `a41a9aa01e2fefafe18ca81fd3c303fe85bce4e8` — PSC1-friendly structurally recursive string equality
- `f8879a697e144ea6e5f361d58d7b6f87177fd328` — PSC1-friendly level equivalence; Name+Level subsequently passed the self-host gate
- `3af4627051bfd9a37d42bd4de4c828b3662046d0` — Expr RED fixture added
- `313e3fbf343d7ab30758676986ff36dcb6d8bf59` — Expr parity target wired into Lake
- `ef7e9bddf0ec47f8c8408ff0ff46bbcf60d182c0` — Expr RED target wired into CI; this is the split point for `psc2/kernel-core-phase1`

## Core non-negotiables for future agents

1. Repository state is source of truth.
2. Preserve existing `PSC1Kernel` as oracle until replacement parity is demonstrated.
3. Trusted KernelCore source must stay PSC1-subset `.lean`.
4. "Lean builds" is insufficient; the actual PSC1 self-host compiler must accept it.
5. Do not weaken semantic/parity gates.
6. Do not add host/runtime/replay machinery to `pskernel-core`.
7. Prefer a smaller pure semantic implementation even if slower; optimized runtime implementations can live outside the minimal TCB.
8. Do not claim full Lean 4 equivalence from Phase 1.
9. Keep `pskernel-core` outside the active PSC2 bootstrap closure until an explicit later integration milestone.
10. This chat owns `psc2/kernel-core-phase1`; do not resume writes on `psc2/minimal-selfhost-psc15` without an intentional reconciliation step.
