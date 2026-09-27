# PSC2 KernelCore Phase 1 Acceptance

Status: ACCEPTED

Branch: `psc2/kernel-core-phase1`

Accepted evidence head: `08b6091510dfca1e2679baabe749f403b56eac82`

GitHub Actions run: `36281345847` (`PSC2 minimal kernel`, run 71)

Result: PASS

## Purpose

Phase 1 establishes the smallest self-hostable trusted foundation for a future PSC2 kernel without replacing or weakening the mature `PSC1Kernel` reference implementation.

The existing `PSC1Kernel` remains the compatibility/oracle implementation. `packages/pskernel-core` is a sibling trusted-core experiment whose source must stay inside the PSC1-compatible `.lean` subset and must be accepted by the actual PSC1 compiler pipeline.

Phase 1 intentionally does **not** implement a complete kernel.

## Accepted trusted source

The Phase 1 trusted source closure contains six PSC1-subset `.lean` modules:

- `packages/pskernel-core/src/Ps/KernelCore.lean`
- `packages/pskernel-core/src/Ps/KernelCore/Data.lean`
- `packages/pskernel-core/src/Ps/KernelCore/Name.lean`
- `packages/pskernel-core/src/Ps/KernelCore/Level.lean`
- `packages/pskernel-core/src/Ps/KernelCore/Expr.lean`
- `packages/pskernel-core/src/Ps/KernelCore/Subst.lean`

The implementation deliberately avoids relying on broader Lean implementation machinery for trusted semantics. The core owns the tiny data carriers required for self-hostable structural recursion instead of pulling host containers into the trusted closure.

## Phase 1 semantic scope

Phase 1 covers:

1. foundational local data carriers;
2. Lean-compatible names used by the kernel representation;
3. universe levels and normalization/equivalence behavior needed by the foundational layer;
4. core expression representation, including binder information, literals, and the reference expression constructors;
5. de Bruijn lifting/substitution and expression instantiation behavior needed for later reduction and checking phases.

The substitution layer is semantic, not optimization-oriented: it intentionally omits changed-bit/DAG-sharing/cache machinery that does not affect observable kernel meaning.

## Required gates and evidence

All of the following passed on the accepted evidence head.

### Trusted-boundary gate

`PSC2_KERNEL_CORE_BOUNDARY: PASS`

The new package remains a separate sibling reference/trusted-core candidate rather than silently entering the PSC2 bootstrap compiler closure.

### Differential parity gates

- `PSC2_KERNEL_CORE_NAME_PARITY: PASS`
- `PSC2_KERNEL_CORE_LEVEL_PARITY: PASS`
- `PSC2_KERNEL_CORE_EXPR_PARITY: PASS`
- `PSC2_KERNEL_CORE_SUBST_PARITY: PASS`

These compare the Phase 1 observable behavior against the mature `PSC1Kernel` foundations.

### PSC1 source/self-host gate

Every trusted module passed the actual PSC1 source/admission pipeline:

`KERNEL_CORE_SOURCE_PROFILE: PASS (6 PSC1-subset, self-host-checkable modules)`

This is stronger than a textual source-profile claim. Phase 1 trusted modules are required to remain compilable/checkable by PSC1 itself.

### Bootstrap isolation

`PSC2_BOOTSTRAP_CLOSURE: PASS`

`pskernel-core` is still excluded from the first PSC2 compiler fixed-point closure. Kernel-provider integration remains a later explicit milestone.

### Aggregate Phase 1 assurance

`npm run assurance:kernel-core:phase1` passed.

The aggregate includes the PSC1 source gate, boundary test, all four differential parity tests, and the reproducible size report.

### Existing PSC2 regression gate

The complete existing `npm run check` gate passed on the accepted head after repairing stale test fixtures and preserving the intended bootstrap/Lake boundary.

This includes workspace shape, portable-source checks, layout, bootstrap closure, IR neutrality, bootstrap tests, regression tests, and extension tests covered by that command.

## Measured trusted-source size

The reproducible size reporter produced:

- KernelCore trusted `.lean` files: 6
- KernelCore trusted source bytes: 23,284
- KernelCore trusted nonblank/noncomment LOC: 633
- comparable PSC1Kernel semantic `.lean` files: 22
- comparable PSC1Kernel semantic-source bytes: 306,641
- comparable PSC1Kernel nonblank/noncomment LOC: 7,403
- byte ratio: 0.0759
- LOC ratio: 0.0855

Reference baseline exclusions are explicit: `Test/**`, `Replay.lean`, `ReplayJson.lean`, and `NativeMap.lean`.

These numbers only compare the current Phase 1 foundation against the broader reference-kernel semantic source. They do **not** imply that a complete future KernelCore will remain at this ratio.

## Important bootstrap boundary learned during Phase 1

`Ps.Bootstrap.SelfHost.lean` is a PSC1 bootstrap composition/source-closure root, not an ordinary Lean library root.

Portable `ProofScript.*` bootstrap modules may intentionally redeclare foundational names such as `Prod`, `Option`, `Ordering`, or `Except`. They belong to the PSC1 source translation/self-host path and must not be forced into a normal Lake library alongside Lean's own prelude.

Therefore:

- PSC1 bootstrap source/import closure remains owned by the PSC1 translator/self-host path;
- Lean/Lake smoke tests import the actual Lean-hosted compiler/backend modules they exercise;
- the bootstrap composition source remains unchanged for `.lean -> canonical .ps` generation.

This separation is part of the accepted architecture.

## Claims this acceptance permits

It is valid to say:

- Phase 1 of the smaller PSC2 KernelCore is complete;
- the Phase 1 trusted source is written in the PSC1-compatible `.lean` subset;
- the six-module trusted foundation is accepted by PSC1 itself;
- Name, Level, Expr representation, and substitution/instantiation behavior pass the current direct differential evidence against `PSC1Kernel`;
- the Phase 1 foundation is substantially smaller than the comparable mature reference-kernel source;
- existing PSC2 regression gates are green on the accepted evidence head.

## Claims this acceptance does NOT permit

Do **not** claim from Phase 1 alone that:

- `pskernel-core` is a complete kernel;
- `pskernel-core` is formally equivalent to Lean 4.34;
- all malformed/raw Lean kernel inputs are accepted/rejected identically;
- full type inference is implemented;
- WHNF/reduction is complete;
- definitional equality is implemented;
- declaration/environment admission is complete;
- inductive positivity/recursor validation is complete;
- Quot is implemented;
- PSC2 is already using `pskernel-core` as its checked-core provider.

Those are later phases and must earn their own gates.

## Phase 2 entry conditions

Phase 2 may begin only from a green Phase 1 baseline and should continue the same rules:

1. preserve `PSC1Kernel` as the oracle/reference implementation;
2. keep new trusted source in the PSC1-compatible `.lean` subset;
3. introduce behavior with RED differential tests before implementation;
4. require the actual PSC1 self-host/source gate for every new trusted module;
5. do not add caches, replay transport, Node IO, JSON, or other assurance/runtime machinery to the TCB merely for convenience;
6. keep the PSC2 compiler bootstrap closure separate until an explicit checked-core provider milestone;
7. retain full existing regression gates.

The next semantic area should be the smallest dependency-ordered slice of declaration/environment support needed before reduction, inference, and definitional equality—not a wholesale copy of the mature reference kernel.
