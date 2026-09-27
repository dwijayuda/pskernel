# PSC2 KernelCore Phase 8 Acceptance

Status: accepted

Date: 2026-09-28

Execution branch: `psc2/kernel-core-phase8-inductive-work`

Planning/review branch: `psc2/kernel-core-phase8-inductive`

Accepted implementation/assurance SHA:

```text
381b610861035c4f092c6a60f58b5d0b0f4fa2bc
```

Exact acceptance evidence:

```text
GitHub Actions workflow: PSC2 minimal kernel
run: 36341472781
job: 108682295314
head: 381b610861035c4f092c6a60f58b5d0b0f4fa2bc
conclusion: success
Lean: 4.34.0
```

This record is documentation-only relative to the accepted implementation/assurance SHA above.

## Accepted Phase 8 scope

Phase 8 adds the smallest trusted non-recursive inductive/constructor admission slice required to represent Lean equality as genuine inductive metadata.

Trusted semantic additions:

```text
Ps.KernelCore.Inductive
```

`Ps.KernelCore.Declaration` is extended with bounded `inductInfo` and `ctorInfo` metadata. The accepted family shape is intentionally restricted to a single, non-recursive, non-nested, non-reflexive inductive family. Recursive constructor occurrences are rejected rather than relying on a general strict-positivity checker.

The central accepted compatibility target is genuine `Eq` / `Eq.refl` metadata and admission. Phase 8 does not generate recursors and does not add iota reduction.

## Exact green gate evidence

The exact accepted head passed all workflow steps below in run `36341472781`:

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
Existing PSC2 regression gate
```

Every listed step concluded `success` on the exact accepted head. No prior aggregate was weakened to make Phase 8 pass.

`assurance:kernel-core:phase8` also runs `scripts/report-kernel-core-size.mjs`; therefore the size reporter executed successfully on the accepted head. This closeout deliberately does not copy an unverified numeric reporter transcript from a different run.

## Accepted semantic behavior

The Phase-8 design contract and accepted tests pin the following bounded behavior:

- represent inductive metadata and constructor metadata inside `PsKernelCoreConstantInfo`;
- admit a single non-recursive inductive family and its constructors through a separate trusted path;
- validate fresh names, constructor ordering/index metadata, parameter counts, field counts, result-head shape, family metadata, universe closure and ordinary declaration well-formedness on the covered surface;
- reject recursive occurrences instead of claiming general positivity support;
- preserve purely functional failure semantics: rejected admission does not mutate the caller's original environment;
- store a valid equality family as genuine `inductInfo` / `ctorInfo` entries;
- preserve the existing linear semantic environment and existing ordinary admission path.

## Source/TCB boundary

All trusted Phase-8 implementation remains subject to the existing actual PSC1 source/self-host gate. The phase does not add host hash tables, caches, replay/session state, IO, unsafe trusted implementations, macros or Lean/Std implementation dependencies to KernelCore.

The compiler bootstrap closure remains isolated from `pskernel-core`; Phase 8 does not make KernelCore the authoritative compiler `CheckedCore` provider.

## Scope review

Relative to accepted Phase 7 (`3a6611c63fa75f243960f3d6650265400eac1bf2`), the Phase-8 implementation/assurance range is limited to:

```text
Phase-8 design/plan documentation
Phase-8 workflow/package/Lake assurance wiring
Declaration metadata extension
Ps/KernelCore/Inductive.lean
Phase-8 metadata/shape/admission/rejection/Eq tests
KernelCore aggregate export
```

No Quot implementation, recursor generation/validation, iota reduction, projection computation, structure eta, recursive/mutual/nested inductive support, compiler cutover or backend work is part of the accepted semantic slice.

## Allowed claims

After this acceptance it is valid to claim:

- KernelCore has a PSC1-self-hostable, fail-closed non-recursive inductive/constructor admission slice for the explicitly tested surface.
- `Eq` and `Eq.refl` can be represented and admitted as genuine inductive/constructor metadata on that surface.
- all Phase-1 through Phase-8 aggregate assurance plus the existing full PSC2 regression gate are green on the exact accepted implementation head.
- Phase 8 establishes the equality-family dependency needed for a separately gated Quot phase.

## Explicit non-claims

This acceptance must **not** be used to claim:

- general Lean inductive support;
- strict positivity;
- recursive, mutual or nested inductives;
- recursor generation or validation;
- iota reduction;
- projection computation or structure eta;
- Quot declaration bootstrap or Quot computation;
- complete Lean primitive reduction;
- compiler CheckedCore provider cutover;
- replacement/removal of mature `PSC1Kernel`;
- full or formal equivalence to Lean 4.34.

The strongest valid summary is:

> KernelCore now has a PSC1-self-hostable, fail-closed non-recursive inductive admission slice with genuine `Eq` / `Eq.refl` representation and exact CI-backed differential/self-host/regression evidence; recursive/positive/recursor/iota/Quot and compiler-cutover semantics remain separately gated.

## Next phase

The preferred next architectural slice is Phase 9 Quot:

1. validate the already-admitted genuine `Eq` / `Eq.refl` shape;
2. install the trusted quotient declarations (`Quot`, `Quot.mk`, `Quot.lift`, `Quot.ind`) without widening the inductive phase;
3. preserve `quotInitialized` semantics and idempotence/error behavior;
4. add only the bounded quotient computation rule needed by reduction/DefEq;
5. keep all Phase-1 through Phase-8 assurance, PSC1 source/self-host gates and full repository regression green.
