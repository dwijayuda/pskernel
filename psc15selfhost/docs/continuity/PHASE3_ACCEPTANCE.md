# PSC2 KernelCore Phase 3 Acceptance — Basic Reduction / WHNF

Date: 2026-09-27

## Status

**Accepted for the bounded Phase-3 scope described below.**

Phase 3 adds a small, pure, PSC1-self-hostable **basic/core WHNF** substrate to `pskernel-core`. It does not establish full Lean 4.34 WHNF parity and does not complete the kernel.

## Branch and evidence identity

Execution branch:

`psc2/kernel-core-phase3-reduce-work`

Reviewed spec/plan branch:

`psc2/kernel-core-phase3-reduce`

Reviewed plan head from which execution started:

`f16e8fcb88ad1ed925783d68323945249e7a2961`

Exact implementation + assurance commit tested by the acceptance run:

`4e080e2a3ddbf2a99a02bbcd4ef69ef8db55e31c`

GitHub Actions workflow:

- workflow: `PSC2 minimal kernel`
- run ID: `36300372094`
- job ID: `108566781241`
- tested checkout SHA: `4e080e2a3ddbf2a99a02bbcd4ef69ef8db55e31c`
- result: `success`

This acceptance document is committed after the tested implementation head. Its commit is documentation-only relative to `4e080e2a3ddbf2a99a02bbcd4ef69ef8db55e31c`; that delta must be verified separately before treating this record as final.

## Accepted semantic scope

The new trusted module is:

`psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Reduce.lean`

Phase 3 accepts only the following reduction behavior:

1. easy weak-head forms remain residual/unchanged;
2. `mdata` metadata is stripped and reduction continues on its body;
3. local `letDecl` free variables unfold to their values;
4. ordinary local free variables remain residual;
5. `letE` performs capture-safe zeta reduction using the already accepted substitution semantics;
6. an application reduces its function position only;
7. a lambda in function position beta-reduces using the untouched argument;
8. application arguments are not eagerly normalized merely because they are arguments;
9. ordinary `defnInfo` declarations may delta-unfold;
10. theorem, opaque, axiom, and missing constants remain non-delta-reducible in this phase;
11. definition universe parameters are instantiated through the unfolded expression;
12. universe-parameter arity mismatch fails closed by leaving the constant residual;
13. projection computation remains residual/deferred;
14. reduction recursion is structurally total through an explicit deterministic `Nat` budget.

The exact budget-exhaustion error accepted by this phase is:

`reduction budget exhausted`

The explicit budget is a KernelCore totality/resource mechanism. It is not claimed to be Lean 4.34's public WHNF resource API.

## Trusted Phase-3 entry point

The semantic entry point introduced for later checker phases is:

```text
psKernelCoreWhnf
  : Nat
  -> PsKernelCoreEnvironment
  -> PsKernelCoreLocalContext
  -> PsKernelCoreExpr
  -> PsKernelCoreResult String PsKernelCoreExpr
```

Supporting universe-instantiation helpers remain pure trusted helpers inside the same minimal semantic boundary.

## Differential evidence

`KernelCoreReductionParityTests.lean` compares the bounded overlap to the mature `PSC1Kernel.whnf` oracle with sufficient KernelCore budget.

The accepted fixture covers:

- easy value WHNF;
- metadata stripping;
- zeta reduction;
- simple beta reduction;
- nested beta reduction;
- capture-safe beta under an inner binder;
- application-argument laziness;
- local-let fvar unfolding;
- ordinary local fvar residual behavior;
- direct delta unfolding;
- delta in function position enabling beta;
- direct universe substitution in a delta body;
- deep universe substitution through binder/application/let/metadata/projection children and constant level lists;
- universe arity mismatch residual behavior;
- theorem residual behavior;
- opaque residual behavior;
- axiom residual behavior;
- missing constant residual behavior;
- residual projection behavior for this phase.

KernelCore-specific budget tests additionally pin:

- budget `0` => exact exhaustion error;
- a selected reducible expression fails at the insufficient positive budget;
- the same expression succeeds at the next sufficient budget.

The workflow output records:

`PSC2_KERNEL_CORE_REDUCTION_PARITY: PASS`

## Required green gates on the exact tested head

GitHub Actions run `36300372094`, job `108566781241`, completed successfully with all of the following steps green:

```text
KernelCore boundary                         PASS
Name parity                                 PASS
Level parity                                PASS
Expr parity                                 PASS
Substitution parity                         PASS
Declaration parity                          PASS
Environment parity                          PASS
LocalContext parity                         PASS
Basic reduction/WHNF parity                 PASS
Bootstrap closure isolation                 PASS
Actual PSC1 KernelCore source profile       PASS
Phase-1 aggregate assurance                 PASS
Phase-2 aggregate assurance                 PASS
Phase-3 aggregate assurance                 PASS
Full existing npm run check                 PASS
```

The same job also reported:

`PSC2_BOOTSTRAP_CLOSURE: PASS (60 modules; backend-ts, bootstrap, bridge, compiler, compiler-ir, core, elab, environment, erasure, foundation, meta, stdlib, syntax)`

and the full repository gate included:

`PSC1_SOURCE_PROFILE: PASS (all-portable; 98 portable modules across 17 source roots)`

No existing semantic or regression gate was weakened for Phase 3.

## Actual PSC1 self-host source evidence

The trusted-source checker runs the actual PSC1 compiler over every flattened KernelCore module closure.

The acceptance run reported all ten trusted modules as self-host-checkable, including the new reducer:

```text
KERNEL_CORE_SELFHOST_CHECK: PASS packages/pskernel-core/src/Ps/KernelCore.lean
KERNEL_CORE_SELFHOST_CHECK: PASS packages/pskernel-core/src/Ps/KernelCore/Data.lean
KERNEL_CORE_SELFHOST_CHECK: PASS packages/pskernel-core/src/Ps/KernelCore/Declaration.lean
KERNEL_CORE_SELFHOST_CHECK: PASS packages/pskernel-core/src/Ps/KernelCore/Environment.lean
KERNEL_CORE_SELFHOST_CHECK: PASS packages/pskernel-core/src/Ps/KernelCore/Expr.lean
KERNEL_CORE_SELFHOST_CHECK: PASS packages/pskernel-core/src/Ps/KernelCore/Level.lean
KERNEL_CORE_SELFHOST_CHECK: PASS packages/pskernel-core/src/Ps/KernelCore/LocalContext.lean
KERNEL_CORE_SELFHOST_CHECK: PASS packages/pskernel-core/src/Ps/KernelCore/Name.lean
KERNEL_CORE_SELFHOST_CHECK: PASS packages/pskernel-core/src/Ps/KernelCore/Reduce.lean
KERNEL_CORE_SELFHOST_CHECK: PASS packages/pskernel-core/src/Ps/KernelCore/Subst.lean
KERNEL_CORE_SOURCE_PROFILE: PASS (10 PSC1-subset, self-host-checkable modules)
```

This matters because Lean compilation alone is not sufficient evidence for the trusted source profile.

## Size evidence from the exact tested head

The same acceptance run emitted:

```text
KERNEL_CORE_SIZE_REPORT: PASS
KernelCore trusted .lean file count: 10
KernelCore trusted source bytes: 43586
KernelCore trusted nonblank/noncomment LOC: 1116
PSC1Kernel comparable .lean file count: 22
PSC1Kernel comparable semantic-source bytes: 306641
PSC1Kernel comparable nonblank/noncomment LOC: 7403
KernelCore/reference byte ratio: 0.1421
KernelCore/reference LOC ratio: 0.1507
```

Reference exclusions used by the existing reporter:

- `Test/**`
- `Replay.lean`
- `ReplayJson.lean`
- `NativeMap.lean`

The size figures mean only that the **current bounded trusted KernelCore slice** is much smaller than the reporter's comparable mature-reference baseline. They do not imply that a completed future kernel will preserve the same ratio.

## Trusted boundary preserved

Phase 3 keeps the trusted reducer free of the machinery intentionally excluded from the small TCB:

- no `partial` trusted recursion;
- no `unsafe`;
- no `extern` / `implemented_by`;
- no `IO`;
- no `Lean.*` or `Std.*` implementation dependency;
- no custom syntax/macros/elaborators;
- no host hash/index/cache/session machinery;
- no replay/JSON/filesystem/process dependencies;
- no inference or defeq callback cycle;
- no native evaluator/runtime provider.

The reducer uses the kernel-local semantic data carriers and an explicit decreasing budget instead of copying the reference checker's stateful/partial implementation structure.

## Bootstrap / compiler status

`pskernel-core` remains intentionally outside the active PSC2 bootstrap admission closure in Phase 3.

The existing compiler still uses its current `AdmissionReadyModule` preparation boundary. Phase 3 does **not** rename or promote that boundary to `CheckedCore`, and no plugin/backend can be claimed to be protected by the new KernelCore provider yet.

Compiler-provider integration remains a later explicit milestone after the required semantic parity layers exist.

## Explicitly deferred semantics

The following are not implemented or accepted as part of Phase 3:

- type inference/checking;
- definitional equality;
- proof irrelevance;
- function/structure eta;
- lazy-delta ordering used by full defeq;
- inductive declaration admission/positivity;
- constructor metadata validation;
- recursor metadata/computation-rule validation;
- recursor/iota computation;
- constructor-based projection computation;
- Quot admission or reduction;
- primitive Nat reduction;
- String literal constructor/reduction behavior;
- native reduction/provider behavior;
- Lean-compatible recursion-depth/resource model beyond this phase's explicit basic budget;
- corpus/K7/K8 replay parity through the new KernelCore;
- compiler `CheckedCore` provider integration.

## Allowed claims

The evidence supports these claims:

- Phase 3 adds a small trusted basic-WHNF substrate to KernelCore.
- The new trusted reducer is written in the PSC1-compatible source subset and passes the actual PSC1 self-host checker.
- The trusted closure now contains 10 self-host-checkable `.lean` modules.
- The explicitly covered beta/zeta/metadata/local-let/delta subset agrees with the mature `PSC1Kernel.whnf` oracle on the direct differential fixtures under sufficient explicit budget.
- Universe-parameter substitution for the covered delta path is differentially exercised, including nested expression positions.
- Phase-1 and Phase-2 semantic gates remain green.
- The full existing PSC2/PSC1 repository regression suite remains green on the exact tested implementation head.

## Non-claims

This acceptance must **not** be used to claim:

- full Lean 4.34 WHNF parity;
- a complete type checker;
- complete definitional equality;
- full recursor/projection/Quot semantics;
- full Lean 4.34 kernel equivalence;
- formal equivalence to Lean 4.34;
- complete replacement of `PSC1Kernel`;
- readiness to make KernelCore the active compiler admission provider;
- that the current 14.21% byte / 15.07% LOC ratios predict the final completed-kernel ratio.

The strongest valid Phase-3 summary is:

> KernelCore now has a small PSC1-self-hostable basic WHNF substrate with differential parity against PSC1Kernel for the explicitly covered beta/zeta/metadata/local-let/delta subset, under sufficient explicit reduction budget.

## Recommended next semantic phase

The next dependency-ordered slice is **minimal inference/checking built on this accepted basic WHNF**. It should remain a separate architectural phase with its own spec, RED differential gates, PSC1-source verification, and acceptance record. Definitional equality should follow as its own phase rather than being smuggled into inference merely to enlarge fixture coverage.
