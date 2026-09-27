# PSC2 KernelCore Phase 5 Acceptance

Status date: 2026-09-27

Execution branch: `psc2/kernel-core-phase5-defeq-work`

Reviewed branch: `psc2/kernel-core-phase5-defeq`

Accepted implementation/assurance SHA:

```text
5a68f16a98b5d4765bd1560e3b167c240dba9ddd
```

Exact acceptance evidence:

```text
GitHub Actions workflow: PSC2 minimal kernel
run: 36311250827
job: 108597471818
conclusion: success
Lean: 4.34.0
```

The acceptance record itself is intentionally committed after the tested implementation/assurance SHA. No semantic or CI change is included in this documentation-only acceptance commit.

## Accepted Phase 5 scope

Phase 5 adds the smallest accepted PSC1-self-hostable **definitional-equality foundation** on top of the previously accepted reduction and infer-only layers.

Trusted semantic additions are:

```text
Ps.KernelCore.DefEq
```

plus the structural-expression equality prerequisite added to `Ps.KernelCore.Expr`.

The primary accepted equality entry point is:

```text
psKernelCoreIsDefEq :
  Nat ->
  PsKernelCoreEnvironment ->
  PsKernelCoreLocalContext ->
  PsKernelCoreExpr ->
  PsKernelCoreExpr ->
  PsKernelCoreResult String Bool
```

The accepted Phase-5 equality surface includes:

- structural expression equality as a fast path;
- WHNF retry on both sides;
- universe equivalence for sorts;
- literal equality;
- same-name constant equality with universe-level equivalence;
- free-variable equality;
- application comparison;
- lambda and forall domain/body comparison under a shared fresh local;
- proof irrelevance for inferred propositions;
- function eta in both directions;
- explicit total comparison budget;
- conservative unsupported-residual behavior;
- explicit fail-closed residual projection behavior until trusted inductive metadata exists.

Phase 5 does not import the remaining mature-checker semantic islands into the TCB merely to broaden coverage.

## Structural equality prerequisite

`Ps.KernelCore.Expr` now provides the structural helpers required by the DefEq fast path:

```text
psKernelCoreBoolEq
psKernelCoreLiteralEq
psKernelCoreLevelListEq
psKernelCoreExprEq
```

The accepted structural equality intentionally reflects semantic representation choices already pinned by differential fixtures. In particular, lambda/forall display names and binder-info presentation do not determine expression identity for the supported structural fast path, while semantic children, metadata payloads, projection payloads, literals, names, and constant universe lists are compared according to the accepted KernelCore representation.

The structural helper was introduced through a RED/GREEN differential gate before trusted DefEq code depended on it.

## DefEq implementation shape

The final trusted implementation deliberately avoids importing mature stateful checker machinery. It uses small first-order planner helpers and keeps recursive equality execution in the explicit budget-recursive entry point.

The internal first-order planning layer includes:

```text
PsKernelCoreDefEqPlan
psKernelCoreDefEqDoneError
psKernelCoreDefEqDoneBool
psKernelCoreDefEqCompareBinderPlan
psKernelCoreDefEqEtaLeftPlan
psKernelCoreDefEqEtaRightPlan
psKernelCoreDefEqApplicationPlan
psKernelCoreDefEqAfterProofPlan
psKernelCoreDefEqFallbackPlan
psKernelCoreDefEqReducedPlan
```

This shape is significant for PSC1 self-hostability: earlier semantically-correct forms using large higher-order helper bodies exposed pathological PSC1 elaboration time. The final accepted version keeps helper APIs first-order and small while preserving the same differential behavior.

## Direct DefEq evidence

The exact acceptance run reports:

```text
PSC2_KERNEL_CORE_DEFEQ_PARITY: PASS
```

The Phase-5 differential fixture compares the supported surface directly with the mature `PSC1Kernel.isDefEq` oracle and pins, among other cases:

- reflexivity;
- metadata transparency;
- universe equivalence;
- beta reduction;
- zeta/local-let reduction;
- delta unfolding through the accepted bounded reduction substrate;
- applications;
- lambda binders;
- forall binders;
- proof irrelevance;
- eta in both directions;
- opaque unequal constants;
- negative inequality cases;
- budget exhaustion;
- lower-layer error propagation;
- projection fail-closed behavior.

The trusted budget boundary remains explicit:

```text
budget 0 -> "defeq budget exhausted"
```

Residual projection comparison remains explicitly unavailable before trusted inductive/projection metadata:

```text
"projection definitional equality unavailable before inductive metadata"
```

The budget is a small-core totality/resource boundary; it is not a claim of exact Lean recursion-depth or heartbeat accounting.

## Trusted closure and actual PSC1 self-host evidence

The exact tested head reports:

```text
KERNEL_CORE_SOURCE_PROFILE: PASS (12 PSC1-subset, self-host-checkable modules)
```

Trusted files:

```text
packages/pskernel-core/src/Ps/KernelCore.lean
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

Every trusted entry is flattened through the trusted KernelCore-only import closure and checked by the actual PSC1 compiler. The Phase-5 source gate now builds `psc1` once and invokes the resulting compiler binary directly for each flattened closure.

The source restrictions were **not weakened** during Phase 5. The harness was hardened only after a demonstrated indefinite check hang: it now emits per-entry progress and fails closed on build/check timeout or process error. Static restrictions on implementation imports, unsafe features, macros/elaborators, IO, namespaces, mutual definitions, termination machinery, and other forbidden trusted-source conveniences remain in force.

The final implementation is comfortably inside the fail-closed bound. In the fresh acceptance run:

```text
DefEq.lean START: 10:03:55.6588810Z
DefEq.lean PASS:  10:03:57.8110596Z

KernelCore.lean START: 10:04:00.9290542Z
KernelCore.lean PASS:  10:04:03.0780805Z
```

Both complete in roughly 2.15 seconds, far below the 120-second per-entry cap. This demonstrates that the final first-order split-planner refactor removed the earlier PSC1 elaboration pathology rather than hiding it behind a larger timeout.

## Preserved lower-layer and aggregate evidence

The exact acceptance run reports success for:

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
PSC2_BOOTSTRAP_CLOSURE: PASS
KERNEL_CORE_SOURCE_PROFILE: PASS (12 PSC1-subset, self-host-checkable modules)
KERNEL_CORE_SIZE_REPORT: PASS
Phase 1 aggregate assurance: success
Phase 2 aggregate assurance: success
Phase 3 aggregate assurance: success
Phase 4 aggregate assurance: success
Phase 5 aggregate assurance: success
Existing PSC2 regression gate (`npm run check`): success
```

The fresh full repository regression also reports, among other existing gates:

```text
PSC1_WORKSPACE_SHAPE: PASS (20 workspaces)
PSC1_SOURCE_PROFILE: PASS (all-portable; 100 portable modules across 17 source roots)
PSC2_LAYOUT_DRIFT: PASS
PSC_IR_NEUTRALITY_PASS
```

Bootstrap, regression, TypeScript, Wasm, Rust, bridge, erasure, IR-specialization, and minimal-self-host test groups all completed successfully on the exact accepted implementation/assurance SHA.

The compiler bootstrap closure remains isolated from `pskernel-core`; Phase 5 does not make KernelCore the active compiler admission/CheckedCore provider.

## Exact size evidence

From the exact acceptance head:

```text
KERNEL_CORE_SIZE_REPORT: PASS
KernelCore trusted .lean file count: 12
KernelCore trusted source bytes: 78497
KernelCore trusted nonblank/noncomment LOC: 1916
PSC1Kernel comparable .lean file count: 22
PSC1Kernel comparable semantic-source bytes: 306641
PSC1Kernel comparable nonblank/noncomment LOC: 7403
KernelCore/reference byte ratio: 0.2560
KernelCore/reference LOC ratio: 0.2588
```

Reference exclusions are unchanged:

```text
Test/**
Replay.lean
ReplayJson.lean
NativeMap.lean
```

The current accepted trusted slice is therefore approximately 25.60% of the comparable reference bytes and 25.88% of the comparable reference LOC, or approximately 74.12% smaller by the reported LOC measure. These are measurements of the current Phase-5 slice only. They must not be presented as a prediction for the final completed kernel.

## Allowed claims

The evidence supports these claims:

- KernelCore now contains a small PSC1-self-hostable bounded definitional-equality foundation on top of the accepted reduction and infer-only substrates.
- The trusted closure consists of 12 PSC1-subset `.lean` modules and every trusted closure passes the actual PSC1 compiler check.
- The explicitly covered Phase-5 structural/WHNF/universe/application/binder/proof-irrelevance/function-eta cases agree with the mature `PSC1Kernel.isDefEq` oracle under a sufficient explicit small-core budget.
- DefEq errors from accepted lower layers propagate through the trusted equality path.
- Residual projection equality remains fail-closed until trusted inductive/projection metadata exists.
- The Phase-5 source-check harness is fail-closed on stalled checks and the final accepted DefEq source completes far below its timeout.
- Phase-1/2/3/4 semantic and aggregate gates remain green.
- The complete existing PSC2/PSC1 repository regression suite remains green on the exact accepted implementation/assurance SHA.

## Explicit non-claims

This acceptance must **not** be used to claim:

- full Lean 4.34 kernel equivalence;
- formal equivalence to Lean 4.34;
- complete Lean-compatible definitional equality;
- exact equivalence for malformed raw Lean inputs;
- recursor or iota definitional equality;
- inductive, constructor, or recursor admission correctness;
- Quot admission, reduction, or definitional equality;
- structure eta;
- projection computation or trusted projection metadata semantics;
- native evaluation parity;
- lazy-delta ordering, lazy-delta caches, session-state behavior, or mature-checker performance parity;
- complete primitive Nat/String/native kernel behavior;
- exact Lean resource/heartbeat/depth accounting;
- a complete type checker or closed declaration checker;
- compiler `CheckedCore` provider integration;
- replacement of `PSC1Kernel` as the current assurance oracle/provider;
- executable PSC2 KernelCore fixed-point self-hosting;
- that the current 25.60% byte / 25.88% LOC ratios predict the final completed-kernel size.

The strongest valid Phase-5 summary is:

> KernelCore now has a PSC1-self-hostable bounded definitional-equality foundation with direct differential parity against `PSC1Kernel.isDefEq` for the explicitly covered Phase-5 surface, including structural/WHNF equality, binder comparison, proof irrelevance, and symmetric function eta, while recursor/Quot/projection/structure-specific semantics, full checking/admission, compiler cutover, and full Lean 4.34 equivalence remain deferred.

## Next-phase boundary

Phase 6 and later work may add the remaining semantic islands one at a time, but only through the same dependency-ordered RED/GREEN process:

1. add a direct failing differential or fail-closed boundary fixture first;
2. implement the smallest trusted semantic slice;
3. preserve actual PSC1 self-host source acceptance;
4. preserve all lower-layer parity and aggregate gates;
5. preserve the full repository regression suite;
6. record exact accepted claims and non-claims before moving on.

Potential future islands include inductive/constructor/recursor metadata validation, iota/recursor reduction, projection computation, Quot, structure eta, primitive/native behavior, lazy-delta/performance machinery outside the semantic core where possible, and eventual checked declaration/admission integration.

**No Phase-6 semantic work is part of this acceptance.**
