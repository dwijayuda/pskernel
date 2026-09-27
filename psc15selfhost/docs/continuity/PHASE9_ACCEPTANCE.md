# PSC2 KernelCore Phase 9 Acceptance

Status: accepted

Date: 2026-09-28

Execution branch: `psc2/kernel-core-phase9-quot-work`

Planning/review branch: `psc2/kernel-core-phase9-quot`

Accepted implementation/assurance SHA:

```text
09e4d6d3794816a0025f4b3339219cccde47af33
```

Exact acceptance evidence:

```text
GitHub Actions workflow: PSC2 minimal kernel
workflow: .github/workflows/psc2-minimal-kernel.yml
run: 36349138129
job: 108704240786
head: 09e4d6d3794816a0025f4b3339219cccde47af33
conclusion: success
Lean: 4.34.0
```

This record is documentation-only relative to the accepted implementation/assurance SHA above.

## Accepted Phase 9 scope

Phase 9 adds the smallest trusted quotient bootstrap and computation island needed on the explicitly covered Lean 4.34-compatible surface. It depends on Phase 8's genuinely admitted `Eq` / `Eq.refl` metadata rather than accepting ordinary declarations that merely use those names.

Trusted semantic additions cover:

```text
Quot metadata in Ps.KernelCore.Declaration
Quot bootstrap/admission in Ps.KernelCore.Quot
bounded Quot.lift / Quot.ind computation in KernelCore reduction
```

The accepted bootstrap installs the reserved quotient declarations `Quot`, `Quot.mk`, `Quot.lift`, and `Quot.ind`, preserves the semantic environment's `quotInitialized` protocol, and keeps failure functional. The computation slice is intentionally bounded: it fires only for the covered initialized quotient eliminator shape whose major argument weak-head reduces to `Quot.mk`.

## Exact green gate evidence

The exact accepted head passed every workflow step below in run `36349138129`, job `108704240786`:

```text
Boundary test
Name parity test
Level parity test
Expr parity test
Substitution parity test
Declaration parity test
Environment parity test
Local context parity test
Resource parity test
Mandatory Nat primitive parity test
Configured primitive/resource integration test
Basic reduction parity test
Minimal inference parity test
Minimal DefEq parity test
Checked inference parity test
Checked inference ordering regression
Ordinary admission parity test
Phase 8 inductive metadata
Phase 8 inductive shape
Phase 8 inductive admission parity
Phase 8 inductive rejection matrix
Phase 8 Eq inductive compatibility
Phase 9 Quot metadata
Phase 9 Quot admission parity
Phase 9 Quot rejection matrix
Phase 9 Quot reduction parity
Bootstrap closure remains isolated
KernelCore PSC1 source profile
Phase 1 aggregate assurance
Phase 2 aggregate assurance
Phase 3 aggregate assurance
Phase 4 aggregate assurance
Phase 5 aggregate assurance
Phase 6 aggregate assurance
Phase 7 aggregate assurance
Phase 8 aggregate assurance
Phase 9 aggregate assurance
Existing PSC2 regression gate
```

Every listed step concluded `success` on the exact accepted semantic head. No earlier aggregate gate was removed from the permanent workflow to make Phase 9 pass.

The Phase-9 aggregate assurance includes the existing KernelCore size-reporting path. This closeout intentionally does not copy numeric size output unless it is tied to the exact accepted run transcript.

## Accepted semantic behavior

The Phase-9 design contract and accepted tests pin the following bounded behavior:

- represent the four quotient declaration kinds as trusted quotient metadata while keeping them non-delta-reducible;
- expose quotient declarations through the existing constant accessors and conservative declaration classifications;
- require genuine Phase-8 `Eq` inductive metadata and matching `Eq.refl` constructor metadata before first quotient initialization;
- reject malformed equality prerequisites and collisions with each reserved quotient name;
- install exactly `Quot`, `Quot.mk`, `Quot.lift`, and `Quot.ind` with the covered universe/type metadata;
- set `quotInitialized` only after successful installation;
- make repeated initialization idempotent once the semantic environment is already marked quotient-initialized;
- preserve the caller's original semantic environment on failed initialization;
- reduce the covered initialized `Quot.lift` / `Quot.ind` applications when their major argument weak-head reduces to the expected `Quot.mk` application;
- extract the represented value, apply the eliminator's function/proof argument, and preserve covered trailing arguments;
- keep malformed, underapplied, wrong-head, and uninitialized quotient applications residual rather than widening the reduction rule;
- thread the existing explicit reduction/resource configuration rather than bypassing it through a default-resource path.

## Source/TCB boundary

All trusted Phase-9 implementation remains subject to the actual PSC1 KernelCore source/self-host profile. The accepted phase does not add `partial`, trusted `unsafe`, IO, Lean/Std implementation dependencies, macros/elaborators, host semantic hash/index/cache/session/replay machinery, or general recursor infrastructure to the trusted slice.

The compiler bootstrap closure remains isolated from `pskernel-core`; Phase 9 does not make KernelCore the authoritative compiler `CheckedCore` provider and does not remove the mature `PSC1Kernel` reference oracle.

## Scope review

Relative to accepted Phase 8, the Phase-9 semantic work is limited to the separately gated quotient surface:

```text
Phase-9 design/plan documentation
Phase-9 workflow/package/Lake assurance wiring
Quot declaration metadata extension
trusted quotient bootstrap/admission
bounded Quot.lift / Quot.ind reduction
Phase-9 metadata/admission/rejection/reduction parity tests
KernelCore aggregate export/wiring required by that surface
```

No general recursor generation/validation, ordinary-inductive iota machinery, recursive/mutual/nested inductive support, strict positivity, projection computation, structure eta, native/eager reduction, compiler provider cutover, or backend work is part of the accepted semantic slice.

## Allowed claims

After this acceptance it is valid to claim:

- KernelCore has a PSC1-self-hostable Quot bootstrap tied to genuine Phase-8 `Eq` / `Eq.refl` metadata on the explicitly tested surface.
- KernelCore has the bounded tested `Quot.lift` / `Quot.ind` computation rule for initialized quotient environments.
- malformed prerequisites and unsupported quotient reduction shapes fail closed or remain residual according to the tested contract.
- all permanent Phase-1 through Phase-9 workflow gates plus the existing PSC2 regression gate are green on the exact accepted implementation/assurance SHA.

## Explicit non-claims

This acceptance must **not** be used to claim:

- general Lean inductive or recursor support;
- strict positivity;
- recursive, mutual or nested inductives;
- general recursor generation or validation;
- ordinary inductive iota reduction;
- projection computation or structure eta;
- complete Lean primitive reduction;
- K7/K8 full corpus parity through KernelCore;
- compiler `CheckedCore` provider cutover;
- replacement/removal of mature `PSC1Kernel`;
- full or formally proven equivalence to Lean 4.34.

The strongest valid summary is:

> KernelCore now has a PSC1-self-hostable Quot bootstrap tied to genuine Phase-8 equality metadata plus the bounded `Quot.lift` / `Quot.ind` computation rule, with exact differential/source/self-host/regression evidence on the explicitly covered surface; general recursor/iota/recursive-inductive and compiler-cutover semantics remain separately gated.

## Next phase

The next semantic phase must remain separately designed and gated. The strongest architectural candidate is the smallest recursor metadata/validation plus ordinary-inductive iota slice needed to advance beyond Phase 8's non-recursive inductive representation without widening directly into recursive/mutual/nested inductives. Existing Phase-1 through Phase-9 assurance and the PSC1 source/self-host boundary remain non-negotiable.