# PSC2 KernelCore Phase 10 Acceptance

Status: accepted

Date: 2026-09-29

Execution branch: `psc2/kernel-core-phase10-recursor-work`

Planning/review branch: `psc2/kernel-core-phase10-recursor`

Accepted implementation/assurance SHA:

```text
525452a87261036e63d2e2a4215e0049c96bcd71
```

Exact permanent acceptance evidence:

```text
GitHub Actions workflow: PSC2 minimal kernel
workflow: .github/workflows/psc2-minimal-kernel.yml
run: 36535529388
job: 109298577446
head: 525452a87261036e63d2e2a4215e0049c96bcd71
conclusion: success
Lean: 4.34.0
```

Corroborating focused Phase-10 evidence:

```text
GitHub Actions workflow: PSC2 KernelCore Phase 10 work
workflow: .github/workflows/psc2-kernel-core-phase10-work.yml
run: 36535529333
job: 109298577277
head: 525452a87261036e63d2e2a4215e0049c96bcd71
conclusion: success
Lean: 4.34.0
```

This record is documentation-only relative to the accepted implementation/assurance SHA above.

## Accepted Phase 10 scope

Phase 10 adds the smallest trusted ordinary-recursor slice for the explicitly bounded Phase-8 single-family, non-recursive inductive profile. Canonical recursor generation remains outside KernelCore. The trusted core validates supplied recursor metadata, stores accepted `.recInfo`, and performs bounded direct-constructor iota reduction.

Trusted semantic additions cover:

```text
recursor metadata in Ps.KernelCore.Declaration
canonical minor/constructor validation in Ps.KernelCore.RecursorCanonical
recursor validation/admission in Ps.KernelCore.Recursor
bounded direct-constructor iota in Ps.KernelCore.Reduce
```

Phase 10 does not widen the trusted kernel into general recursive-inductive or elaborator/generator machinery.

## Trust-boundary hardening found during review

Final review found an important fail-closed issue before acceptance: rule-RHS checking originally derived its expected branch type from the supplied recursor minor binder. A coordinated forged recursor type could therefore make a wrong minor binder and matching rule appear self-consistent.

The accepted implementation closes that gap by independently tying each supplied minor to the already-admitted constructor metadata before rule-RHS validation:

1. open the canonical recursor prefix with fresh variables;
2. reuse those parameter variables when instantiating the admitted constructor telescope;
3. compare constructor-field binders against the supplied minor field telescope;
4. recover the constructor result indices from admitted constructor metadata;
5. reconstruct the expected result `motive indices (Ctor params fields)`;
6. require the supplied minor result to match that canonical reconstruction;
7. only then run the existing closedness, universe, type-checking and trusted DefEq validation for the rule RHS.

A dedicated regression, `KernelCoreRecursorForgedMinorRejectionTests.lean`, proves that the previously self-consistent forged-minor shape is rejected. This regression is included in `assurance:kernel-core:phase10`, so the permanent aggregate cannot silently omit it.

## Exact green gate evidence

The exact accepted head passed the permanent workflow run `36535529388`, job `109298577446`, including:

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
Phase 10 recursor metadata
Phase 10 recursor admission parity
Phase 10 recursor rejection matrix
Phase 10 direct-constructor iota parity
Phase 10 Eq direct-iota compatibility
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
Phase 10 aggregate assurance
Existing PSC2 regression gate
```

Every listed permanent step concluded `success` on the exact accepted implementation/assurance SHA.

The Phase-10 aggregate assurance includes the dedicated forged-minor rejection regression and the existing KernelCore size-reporting path. This closeout intentionally does not copy numeric size output unless tied directly to the exact accepted transcript.

The focused work run `36535529333`, job `109298577277`, independently passed the more detailed Phase-10 development gates on the same SHA, including admission diagnostics, rejection diagnostics, the explicit forged-minor rejection test, reduction parity, Eq compatibility and the PSC1 source profile.

## Accepted semantic behavior

The accepted design/tests pin this bounded behavior:

- represent canonical recursor rules and recursor metadata as trusted declaration metadata;
- admit `.recInfo` only for exactly one already-admitted Phase-8 single non-recursive/non-nested/non-reflexive family;
- require matching parameter/index counts, exactly one motive, one minor/rule per constructor, constructor order, field counts, safety and declaration freshness;
- reject `k = true` in this phase;
- independently validate supplied minor branch shapes against admitted constructor metadata rather than trusting the supplied recursor type alone;
- reject malformed, missing, foreign, non-constructor and inconsistent constructor metadata fail-closed;
- reject duplicate/uncovered universe parameters and mvar/fvar leakage according to the admitted surface;
- preserve the original immutable semantic environment when admission fails;
- weak-head reduce the recursor major under the existing explicit resource/budget path;
- fire ordinary iota only when the major reduces to an admitted direct constructor with a matching rule;
- instantiate recursor universe parameters in the selected rule RHS;
- apply parameters, motive and minors before constructor fields;
- take the final `nFields` constructor arguments as fields, so constructor parameters are not spuriously passed as fields;
- use indices to locate the major but do not separately pass them to the rule RHS on this covered surface;
- preserve/reapply trailing outer application arguments;
- keep underapplied, wrong-head, unknown-constructor and wrong-universe-arity recursor applications residual rather than widening the reduction rule;
- reduce an explicitly admitted equality recursor on an actual admitted `Eq.refl` constructor through the ordinary direct-constructor iota rule, without a special K path.

## Source/TCB boundary

The exact focused acceptance run reports:

```text
KERNEL_CORE_SOURCE_PROFILE: PASS (20 PSC1-subset, self-host-checkable modules)
```

The new trusted `RecursorCanonical.lean` and the rest of the Phase-10 trusted closure pass the actual flattened PSC1 source/self-host path. Phase 10 does not add trusted `partial`, trusted `unsafe`, IO, Lean/Std implementation dependencies, custom macros/elaborators, mutual trusted definitions, host semantic caches/sessions/replay state, or recursor generation inside the kernel.

The compiler bootstrap closure remains isolated from `pskernel-core`; Phase 10 does not make KernelCore the authoritative compiler `CheckedCore` provider and does not remove the mature `PSC1Kernel` reference oracle.

## Scope review

Relative to accepted Phase 9, the semantic work is limited to the separately gated recursor/iota surface:

```text
Phase-10 design/plan documentation
Phase-10 workflow/package assurance wiring
recursor declaration metadata
canonical recursor-minor validation
bounded recursor admission
bounded direct-constructor iota reduction
Phase-10 metadata/admission/rejection/forgery/reduction/Eq fixtures
KernelCore aggregate export/wiring required by that surface
```

No recursive induction hypotheses, recursive/mutual/nested inductive admission, strict positivity, K conversion, structure eta, literal-to-constructor recursor conversion, projection computation, compiler provider cutover or backend semantics are part of this acceptance.

## Allowed claims

After this acceptance it is valid to claim:

- KernelCore has a PSC1-self-hostable recursor-metadata admission path for the explicitly bounded Phase-8 non-recursive family profile.
- supplied minor branches are independently tied to admitted constructor metadata, including rejection of the reviewed forged-minor attack shape.
- KernelCore has bounded ordinary direct-constructor iota reduction on the explicitly tested surface.
- genuine Phase-8 `Eq` / `Eq.refl` can participate in the ordinary direct-iota path without introducing K conversion.
- all permanent Phase-1 through Phase-10 aggregate gates plus the existing PSC2 regression gate are green on the exact accepted implementation/assurance SHA.

## Explicit non-claims

This acceptance must **not** be used to claim:

- recursive induction hypotheses;
- general recursive inductive admission;
- strict positivity;
- mutual or nested inductives;
- general recursor generation inside KernelCore;
- K recursor conversion or constructor synthesis;
- structure eta or projection computation;
- Nat/String literal-to-constructor recursor conversion;
- complete Lean primitive reduction;
- broader K7/K8 corpus parity through KernelCore;
- compiler `CheckedCore` provider cutover;
- replacement/removal of mature `PSC1Kernel`;
- full or formally proven equivalence to Lean 4.34.

The strongest valid summary is:

> KernelCore has a PSC1-self-hostable recursor-metadata admission path for the explicitly bounded Phase-8 non-recursive family profile plus direct-constructor iota reduction, with canonical minor branches independently tied to admitted constructor metadata and exact differential/source/self-host/regression evidence; recursive-inductive/IH, K, structure/literal conversion and compiler-cutover semantics remain separately gated.

## Next phase

The next semantic phase must remain separately designed and gated. Primitive support for strictly-positive single-family recursive inductives is the strongest architectural candidate before any mutual/nested lowering work. Recursive recursor/induction-hypothesis semantics should remain a separate subsequent gate unless a new reviewed design justifies combining them.
