# PSC2 KernelCore Phase 6 Acceptance

Status date: 2026-09-27

Execution branch: `psc2/kernel-core-phase6-admission-work`

Reviewed branch: `psc2/kernel-core-phase6-admission`

Accepted implementation/assurance SHA:

```text
1a29d021b2fff626c08373fd32f245fcff8bca0b
```

Exact acceptance evidence:

```text
GitHub Actions workflow: PSC2 minimal kernel
run: 36315698085
job: 108609861841
conclusion: success
Lean: 4.34.0
```

This acceptance record is intentionally committed after the exact tested implementation/assurance SHA. The acceptance commit must contain documentation only.

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
psKernelCoreAddAxiom :
  Nat -> PsKernelCoreEnvironment -> PsKernelCoreAxiomInfo ->
  PsKernelCoreResult String PsKernelCoreEnvironment

psKernelCoreAddDefinition :
  Nat -> PsKernelCoreEnvironment -> PsKernelCoreDefinitionInfo ->
  PsKernelCoreResult String PsKernelCoreEnvironment

psKernelCoreAddTheorem :
  Nat -> PsKernelCoreEnvironment -> PsKernelCoreTheoremInfo ->
  PsKernelCoreResult String PsKernelCoreEnvironment

psKernelCoreAddOpaque :
  Nat -> PsKernelCoreEnvironment -> PsKernelCoreOpaqueInfo ->
  PsKernelCoreResult String PsKernelCoreEnvironment
```

Phase 6 deliberately keeps accepted `Ps.KernelCore.Infer` semantics unchanged.

## Checked-expression evidence

The exact acceptance run reports:

```text
PSC2_KERNEL_CORE_CHECK_PARITY: PASS
```

The differential fixture compares the supported checked surface with `PSC1Kernel.check` and covers:

- sorts, locals, monomorphic and polymorphic constants;
- Nat and String literal typing on the bounded ordinary surface;
- metadata transparency;
- ordinary and dependent applications;
- lambda-domain checking;
- forall domain/codomain checking;
- let declared-type/value checking;
- Phase-5 DefEq for application and let compatibility;
- safe/unsafe/partial constant-use restrictions;
- malformed applications, domains, codomains, lets, unknown names and universe arity;
- loose bound variables and expression metavariables;
- explicit budget boundaries and lower-layer error propagation;
- fail-closed projection behavior before trusted inductive metadata.

Stable Phase-6 boundary errors include:

```text
check budget exhausted
safe declaration uses unsafe constant
safe declaration uses partial constant
application type mismatch
let value type mismatch
projection checking unavailable before inductive metadata
```

The accepted safety matrix is:

```text
safe context    : safe only
partial context : safe + partial, but not unsafe
unsafe context  : safe + partial + unsafe
```

## Ordinary declaration-admission evidence

The exact acceptance run reports:

```text
PSC2_KERNEL_CORE_ADMISSION_PARITY: PASS
```

The differential fixture compares the supported surface with:

```text
PSC1Kernel.Kernel.addAxiom
PSC1Kernel.Kernel.addDefinition
PSC1Kernel.Kernel.addTheorem
PSC1Kernel.Kernel.addOpaque
```

Accepted overlap includes:

- safe and unsafe axioms;
- ordinary safe definitions;
- polymorphic safe definitions;
- theorem admission when the declared type is a proposition and the proof type is compatible;
- opaque declaration admission;
- bounded unsafe single-definition self-reference through a temporary work environment.

Rejected overlap includes:

- duplicate declaration names;
- adjacent and non-adjacent duplicate universe parameters;
- expression metavariables;
- universe metavariables;
- free variables;
- undefined universe parameters, including nested occurrences;
- declaration types that are not themselves types;
- definition body mismatch;
- safe definitions using unsafe or partial dependencies;
- malformed unsafe self-reference;
- theorem type that is not a proposition;
- theorem proof mismatch or forbidden dependency;
- opaque body mismatch or forbidden dependency even when `OpaqueInfo.isUnsafe` is set.

Admission owns trusted structural closure/universe validation rather than trusting an unchecked host adapter.

## Functional environment behavior

Admission remains pure and functional.

The fixture pins that rejected admission leaves the caller's original environment unchanged, including:

```text
size
pre-existing membership
absence of the rejected declaration name
quotInitialized
```

Unsafe single-definition admission uses the mature reference boundary:

1. validate the header against the original environment under unsafe checking context;
2. add the complete definition to a temporary work environment;
3. check the body in that work environment so bounded self-reference is visible;
4. return the work environment only on success.

A failed unsafe definition does not mutate or replace the caller's original environment.

Safe and ordinary single partial definitions are checked before they are added to the returned environment, matching the selected mature ordinary-definition overlap.

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

No source restriction or timeout was weakened for Phase 6.

`PSC1Kernel.Kernel`, `Quot`, `CheckerSession`, and the stateful checker modules added to the Lake reference root set are **test-oracle dependencies only**. They are not imported by or trusted inside `pskernel-core`.

## Preserved assurance evidence

The exact acceptance SHA passes all direct lower-layer gates plus:

```text
PSC2_KERNEL_CORE_CHECK_PARITY: PASS
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

The compiler bootstrap closure remains isolated from `pskernel-core`. Phase 6 does not make KernelCore the compiler's active `CheckedCore` provider.

## Exact size evidence

From the exact accepted implementation/assurance SHA:

```text
KERNEL_CORE_SIZE_REPORT: PASS
KernelCore trusted .lean file count: 14
KernelCore trusted source bytes: 114418
KernelCore trusted nonblank/noncomment LOC: 2680
PSC1Kernel comparable .lean file count: 22
PSC1Kernel comparable semantic-source bytes: 306641
PSC1Kernel comparable nonblank/noncomment LOC: 7403
KernelCore/reference byte ratio: 0.3731
KernelCore/reference LOC ratio: 0.3620
```

Reference exclusions remain:

```text
Test/**
Replay.lean
ReplayJson.lean
NativeMap.lean
```

The current accepted trusted slice is therefore approximately 37.31% of the comparable reference bytes and 36.20% of its nonblank/noncomment LOC. These are measurements of the current Phase-6 slice, not predictions for the final completed kernel.

## Allowed claims

After this acceptance it is valid to claim:

- KernelCore has a PSC1-self-hostable checked-expression layer for the explicitly covered non-inductive Phase-6 surface.
- KernelCore can validate and functionally admit the explicitly covered axiom, definition, theorem and opaque declarations.
- Phase-6 application, let and declaration-body compatibility uses the accepted Phase-5 DefEq layer.
- safe/unsafe/partial constant-use restrictions are enforced on the explicitly covered checked surface.
- ordinary admission validates closure, universe-parameter use, declared-type well-formedness and body/proof/value compatibility for the explicitly covered cases.
- unsafe single-definition self-reference is supported through the explicitly tested temporary-environment behavior.
- all trusted Phase-6 source passes the actual PSC1 self-host checker.
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

The next dependency-ordered architectural slice should be selected from the remaining mature semantic islands based on corpus/dependency pressure.

The expected Phase 7 is **primitive/resource handling**: explicit bounded behavior needed for the mature checker/reducer's Nat/resource and related primitive surface, while keeping native evaluation, Quot and inductive/recursor semantics separately gated unless the Phase-7 design proves a tighter dependency is necessary.
