# PSC2 KernelCore Phase 6 Acceptance

Status: accepted

Date: 2026-09-27

Execution branch: `psc2/kernel-core-phase6-admission-work`

Reviewed branch: `psc2/kernel-core-phase6-admission`

Accepted implementation/assurance SHA:

```text
d51edfd519f8b050f6a31b3549af32a85ca7fa4c
```

Exact acceptance evidence:

```text
GitHub Actions workflow: PSC2 minimal kernel
run: 36316555109
job: 108612234497
conclusion: success
Lean: 4.34.0
```

This acceptance record is intentionally committed after the exact tested implementation/assurance SHA. The acceptance commit contains documentation only relative to the accepted semantic head except for the already-tested review regression/workflow wiring that is part of `d51edfd...`.

## Accepted Phase 6 scope

Phase 6 adds the first PSC1-self-hostable **checked-expression** layer and **ordinary non-inductive declaration admission** on top of the accepted infer-only and DefEq layers.

Trusted semantic additions:

```text
Ps.KernelCore.Check
Ps.KernelCore.Admission
```

Primary checked-expression entry point:

```text
psKernelCoreCheck :
  Nat ->
  PsKernelCoreEnvironment ->
  PsKernelCoreLocalContext ->
  PsKernelCoreDefinitionSafety ->
  PsKernelCoreExpr ->
  PsKernelCoreResult String PsKernelCoreExpr
```

Primary ordinary-admission entry points:

```text
psKernelCoreAddAxiom
psKernelCoreAddDefinition
psKernelCoreAddTheorem
psKernelCoreAddOpaque
```

Phase 6 deliberately keeps accepted `Ps.KernelCore.Infer` semantics unchanged.

## Checked-expression evidence

The exact acceptance run reports:

```text
PSC2_KERNEL_CORE_CHECK_PARITY: PASS
PSC2_KERNEL_CORE_CHECK_ORDERING: PASS
```

The differential fixture compares the supported checked surface with `PSC1Kernel.check` and covers the explicitly selected non-inductive overlap: sorts, locals, constants and universe instantiation, literals, metadata, applications, lambdas, foralls, lets, safety restrictions, malformed terms, lower-layer error propagation, projection fail-closed behavior and explicit KernelCore budget boundaries.

The accepted safety matrix is:

```text
safe context    : safe only
partial context : safe + partial, but not unsafe
unsafe context  : safe + partial + unsafe
```

### Final-review ordering correction

The final whole-branch self-review found one Important semantic-ordering gap that the initial Phase-6 parity fixture did not pin.

For an unsafe polymorphic constant referenced with the wrong universe arity from a safe context, the first candidate checked safety before universe arity. The mature checker and approved Phase-6 specification require universe-arity validation first.

The finding received its own TDD cycle:

```text
RED:   KernelCoreCheckOrderingTests.lean failed on the pre-fix candidate
GREEN: PSC2_KERNEL_CORE_CHECK_ORDERING: PASS
fix:   d51edfd519f8b050f6a31b3549af32a85ca7fa4c
```

The accepted constant-validation order is:

1. declaration lookup;
2. universe arity / level instantiation validation;
3. unsafe restriction;
4. partial restriction;
5. successful instantiated type.

## Ordinary declaration-admission evidence

The exact acceptance run reports:

```text
PSC2_KERNEL_CORE_ADMISSION_PARITY: PASS
```

The differential fixture compares the supported admission surface with:

```text
PSC1Kernel.Kernel.addAxiom
PSC1Kernel.Kernel.addDefinition
PSC1Kernel.Kernel.addTheorem
PSC1Kernel.Kernel.addOpaque
```

The covered admission surface includes ordinary axiom/definition/theorem/opaque success and failure cases; duplicate names and universe parameters; expression/universe metavariables; free variables; undefined universe parameters including nested occurrences; declared-type well-formedness; definition/proof/opaque body compatibility; safety restrictions; immutable rejected-environment behavior; `quotInitialized` preservation; and bounded unsafe single-definition self-reference through a temporary work environment.

Admission remains pure and functional. A rejected declaration does not mutate the caller's original environment.

## Trusted source and PSC1 self-host evidence

The exact acceptance run reports:

```text
KERNEL_CORE_SOURCE_PROFILE: PASS (14 PSC1-subset, self-host-checkable modules)
```

Trusted files:

```text
packages/pskernel-core/src/Ps/KernelCore.lean
packages/pskernel-core/src/Ps/KernelCore/Admission.lean
packages/pskernel-core/src/Ps/KernelCore/Check.lean
packages/pskernel-core/src/Ps/KernelCore/Data.lean
packages/pskernel-core/src/Ps/KernelCore/Declaration.lean
packages/pskernel-core/src/Ps/KernelCore/DefEq.lean
packages/pskernel-core/src/Ps/KernelCore/Environment.lean
packages/pskernel-core/src/Ps/KernelCore/Expr.lean
packages/pskernel-core/src/Ps/KernelCore/Infer.lean
packages/pskernel-core/src/Ps/KernelCore/Level.lean
packages/pskernel-core/src/Ps/KernelCore/LocalContext.lean
packages/pskernel-core/src/Ps/KernelCore/Name.lean
packages/pskernel-core/src/Ps/KernelCore/Reduce.lean
packages/pskernel-core/src/Ps/KernelCore/Subst.lean
```

The hardened Phase-5 source-profile contract remains unchanged: build PSC1 once, flatten each trusted closure, invoke the actual PSC1 compiler on each closure, emit per-entry progress, and fail closed on compiler/process timeout or failure.

No source restriction or timeout was weakened for Phase 6. On the accepted run, the new `Admission.lean`, `Check.lean`, and aggregate closure all completed comfortably below the existing 120-second per-entry bound.

`PSC1Kernel.Kernel`, `Quot`, checker-session, and stateful checker modules used by Lake/reference tests remain **test-oracle dependencies only** and are not imported by the trusted KernelCore implementation.

## Preserved assurance evidence

The exact accepted implementation SHA passed:

```text
PSC2_KERNEL_CORE_BOUNDARY: PASS
PSC2_KERNEL_CORE_NAME_PARITY: PASS
PSC2_KERNEL_CORE_LEVEL_PARITY: PASS
PSC2_KERNEL_CORE_EXPR_PARITY: PASS
PSC2_KERNEL_CORE_SUBST_PARITY: PASS
PSC2_KERNEL_CORE_DECLARATION_PARITY: PASS
PSC2_KERNEL_CORE_ENVIRONMENT_PARITY: PASS
PSC2_KERNEL_CORE_LOCAL_CONTEXT_PARITY: PASS
PSC2_KERNEL_CORE_REDUCTION_PARITY: PASS
PSC2_KERNEL_CORE_INFER_PARITY: PASS
PSC2_KERNEL_CORE_DEFEQ_PARITY: PASS
PSC2_KERNEL_CORE_CHECK_PARITY: PASS
PSC2_KERNEL_CORE_CHECK_ORDERING: PASS
PSC2_KERNEL_CORE_ADMISSION_PARITY: PASS
PSC2_BOOTSTRAP_CLOSURE: PASS
KERNEL_CORE_SOURCE_PROFILE: PASS (14 PSC1-subset, self-host-checkable modules)
Phase 1 aggregate assurance: success
Phase 2 aggregate assurance: success
Phase 3 aggregate assurance: success
Phase 4 aggregate assurance: success
Phase 5 aggregate assurance: success
Phase 6 aggregate assurance: success
Existing PSC2 regression gate (`npm run check`): success
```

No prior phase aggregate command was weakened or redefined to make Phase 6 pass.

The compiler bootstrap closure remains isolated from `pskernel-core`. Phase 6 does not make KernelCore the compiler's active `CheckedCore` provider.

## Exact size evidence

From the exact accepted implementation/assurance SHA:

```text
KERNEL_CORE_SIZE_REPORT: PASS
KernelCore trusted .lean file count: 14
KernelCore trusted source bytes: 113534
KernelCore trusted nonblank/noncomment LOC: 2664
PSC1Kernel comparable .lean file count: 22
PSC1Kernel comparable semantic-source bytes: 306641
PSC1Kernel comparable nonblank/noncomment LOC: 7403
KernelCore/reference byte ratio: 0.3703
KernelCore/reference LOC ratio: 0.3599
```

Reference exclusions remain:

```text
Test/**
Replay.lean
ReplayJson.lean
NativeMap.lean
```

These numbers measure the currently accepted Phase-6 semantic slice only. They are not a prediction for the final complete kernel.

## Review/process evidence

The final whole-branch review was a **self-review because this harness has no subagent-dispatch tool**. This is weaker than an independent fresh-context reviewer and must not be represented otherwise.

During execution, another worker advanced the same Phase-6 work branch while this chat was waiting on the initial RED gate. The branch was not overwritten. The incoming implementation was reconciled against the approved Phase-6 specification/plan and fresh exact-head CI. The self-review then found the universe-arity-before-safety issue documented above; that finding received an observed RED→GREEN regression and a complete green suite before acceptance.

## Allowed claims

After this acceptance it is valid to claim:

- KernelCore has a PSC1-self-hostable checked-expression layer for the explicitly covered non-inductive Phase-6 surface.
- KernelCore can validate and functionally admit the explicitly covered axiom, definition, theorem and opaque declarations.
- Phase-6 application, let and declaration-body compatibility uses the accepted Phase-5 DefEq layer.
- safe/unsafe/partial constant-use restrictions are enforced on the explicitly covered checked surface.
- ordinary admission validates the covered closure, universe-parameter, declared-type well-formedness and body/proof/value compatibility conditions.
- unsafe single-definition self-reference is supported through the explicitly tested temporary-environment behavior.
- all 14 trusted Phase-6 KernelCore `.lean` modules pass the actual PSC1 self-host checker.
- Phase-1 through Phase-6 assurance and the full existing repository regression are green on the exact accepted implementation/assurance SHA.

## Explicit non-claims

This acceptance must **not** be used to claim:

- complete Lean 4.34 declaration admission;
- inductive, constructor or recursor admission;
- strict positivity;
- projection inference/computation;
- iota reduction;
- structure eta;
- Quot admission or computation;
- mutual-definition admission;
- nested/mutual inductive support;
- complete Nat/String primitive reduction;
- native evaluation;
- exact Lean `maxNatSize`, recursion-depth or heartbeat behavior;
- checker cache/session equivalence;
- K7/K8 corpus parity through KernelCore;
- compiler `CheckedCore` provider cutover;
- replacement or removal of mature `PSC1Kernel`;
- formal equivalence to Lean 4.34;
- complete behavioral equivalence to Lean 4.34;
- executable PSC2 KernelCore fixed-point self-hosting;
- that the current size ratios predict the completed kernel's final size.

The strongest valid Phase-6 summary is:

> KernelCore now has a PSC1-self-hostable checked-expression layer and ordinary non-inductive declaration admission with direct differential evidence for the explicitly covered Phase-6 surface; primitive/resource, Quot, inductive/recursor, corpus and compiler-cutover semantics remain separately gated.

## Recommended next phase

The expected next dependency-ordered architectural slice is **primitive/resource handling** required by mature checking/reduction before broader corpus parity, while keeping native evaluation, Quot and inductive/recursor semantics separately gated unless the Phase-7 design proves a tighter dependency is necessary.
