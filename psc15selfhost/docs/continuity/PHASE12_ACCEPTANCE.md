# PSC2 KernelCore Phase 12 Acceptance

Status: **ACCEPTED**

Date: 2026-09-30

Execution branch: `psc2/kernel-core-phase12-recursive-recursor`

Accepted permanent-assurance SHA: `4308230eba25f8c5d81e9bf6acc771f789a2a998`

Audited semantic/test parent SHA: `27731b835ff5dd0187d1db0db7b6ae3f78b07f16`

Phase 11 accepted baseline: `64455c816e04e6113ff9cc4a8b4a2981812876a9`

## Acceptance evidence

Focused Phase 12 workflow after the differential-oracle audit:

- run: `36685273030`
- job: `109789577191`
- head: `27731b835ff5dd0187d1db0db7b6ae3f78b07f16`
- result: **success**

Permanent acceptance workflow:

- workflow: `.github/workflows/psc2-kernel-core-phase12-acceptance.yml`
- run: `36685682651`
- job: `109790876390`
- head: `4308230eba25f8c5d81e9bf6acc771f789a2a998`
- result: **success**
- Lean: `4.34.0`

The permanent workflow passed, on the same SHA:

1. `lake build PsKernelCore PSC1KernelReferenceFoundations`
2. `npm run assurance:kernel-core:phase12`
3. `npm run check`

The acceptance SHA differs from the audited semantic/test parent only by the acceptance-workflow comment used to trigger the permanent run.

## Accepted Phase 12 scope

Phase 12 extends the accepted Phase 10 ordinary-recursor path across the bounded recursive-inductive surface accepted in Phase 11.

Accepted behavior includes:

- single-family recursive recursor admission for the bounded Phase 11 shapes,
- direct recursive fields,
- multiple direct recursive fields,
- supported functional recursive fields,
- supported indexed recursive fields,
- recursive hypotheses derived from the admitted constructor shape,
- recursive hypotheses pinned in constructor recursive-field order,
- canonical recursive self-calls checked structurally rather than accepted only because they typecheck,
- caller-supplied recursive-family flags re-derived from constructor analysis,
- recursor validation in a provisional immutable environment containing the recursor itself,
- transactional admission: failure does not mutate the original environment,
- recursive iota reduction through the existing KernelCore reducer.

`Ps.KernelCore.Reduce` required no Phase 12 semantic change. The existing reducer was sufficient once admitted recursor rules contained the canonical recursive calls.

## Trusted implementation surface

The Phase 12 trusted semantic changes are concentrated in:

- `packages/pskernel-core/src/Ps/KernelCore/RecursiveRecursor.lean`
- `packages/pskernel-core/src/Ps/KernelCore/IndexedRecursiveRecursor.lean`
- `packages/pskernel-core/src/Ps/KernelCore/Recursor.lean`

The trusted core remains PSC1-subset source. The final permanent run reported:

- `KERNEL_CORE_SOURCE_PROFILE: PASS (23 PSC1-subset, self-host-checkable modules)`

This includes actual PSC1 self-host/source checking of the Phase 12 recursive-recursion modules and the aggregate `Ps.KernelCore` module.

## Positive assurance matrix

The permanent acceptance run passed all Phase 12 markers:

- `PSC2_KERNEL_CORE_PHASE12_RECURSIVE_RECURSOR_ADMISSION: PASS`
- `PSC2_KERNEL_CORE_PHASE12_RECURSIVE_RECURSOR_REJECTION: PASS`
- `PSC2_KERNEL_CORE_PHASE12_REJECTION_MATRIX: PASS`
- `PSC2_KERNEL_CORE_PHASE12_FUNCTIONAL_RECURSOR_ADMISSION: PASS`
- `PSC2_KERNEL_CORE_PHASE12_FUNCTIONAL_RECURSOR_REJECTION: PASS`
- `PSC2_KERNEL_CORE_PHASE12_INDEXED_RECURSOR_ADMISSION: PASS`
- `PSC2_KERNEL_CORE_PHASE12_INDEXED_RECURSOR_REJECTION: PASS`
- `PSC2_KERNEL_CORE_PHASE12_MULTI_RECURSIVE_FIELDS: PASS`
- `PSC2_KERNEL_CORE_PHASE12_RECURSIVE_IOTA: PASS`
- `PSC2_KERNEL_CORE_PHASE12_REFERENCE_PARITY: PASS`

Phase 10 ordinary-recursor guards and Phase 11 recursive-inductive guards also remained green in the focused workflow.

## Rejection and fail-closed evidence

The accepted negative matrix covers the bounded Phase 12 contract, including rejection of:

- forged or inconsistent recursive-family metadata,
- malformed recursive minor types,
- missing recursive hypotheses,
- extra recursive hypotheses,
- recursive hypotheses in the wrong order,
- wrong IH motives,
- wrong indexed IH arguments,
- recursive calls targeting the wrong recursor/family shape,
- missing recursive self-calls,
- extra recursive self-calls,
- reordered self-calls for constructors with multiple recursive fields,
- unsupported or malformed recursive-field shapes.

Failed admission remains transactional: the original environment is unchanged when validation fails.

## Mature-reference differential evidence

`KernelCoreRecursiveRecursorReferenceParityTests.lean` was audited before acceptance because its earlier form only demonstrated that the mature `PSC1Kernel` oracle supported the target shapes.

The final accepted fixture now evaluates corresponding contracts on both KernelCore and the mature `PSC1Kernel` reference in the same test for:

- direct recursive families,
- multiple recursive fields,
- functional recursive fields,
- indexed recursive fields.

It compares the overlapping family/constructor semantic contract and requires both sides to succeed. The mature reference also retains a direct recursive-reduction smoke test. KernelCore recursor admission, negative validation, and recursive iota behavior are independently exercised by the dedicated Phase 12 KernelCore fixtures.

This is differential assurance for the supported overlap; it is not a proof of full implementation equivalence.

## Aggregate regression evidence

`npm run assurance:kernel-core:phase12` passed and recursively preserved the accepted Phase 1 through Phase 11 assurance stack.

The independent repository-wide `npm run check` also passed on the same accepted SHA. Notable final markers include:

- `PSC1_WORKSPACE_SHAPE: PASS (20 workspaces)`
- `PSC1_SOURCE_PROFILE: PASS (all-portable; 111 portable modules across 17 source roots)`
- `KERNEL_CORE_SOURCE_PROFILE: PASS (23 PSC1-subset, self-host-checkable modules)`
- `PSC2_LAYOUT_DRIFT: PASS`
- `PSC2_BOOTSTRAP_CLOSURE: PASS (60 modules; ...)`
- `PSC_IR_NEUTRALITY_PASS`
- PSC1 bootstrap/regression tests: PASS
- TypeScript backend tests: PASS
- WASM backend tests/smoke: PASS
- Rust backend/source tests: PASS

## Trusted-size evidence

The final permanent acceptance run reported:

- KernelCore trusted `.lean` files: **23**
- KernelCore trusted source bytes: **302,994**
- KernelCore trusted nonblank/noncomment LOC: **6,721**
- comparable `PSC1Kernel` files: **22**
- comparable `PSC1Kernel` semantic-source bytes: **306,641**
- comparable `PSC1Kernel` nonblank/noncomment LOC: **7,403**
- byte ratio: **0.9881**
- LOC ratio: **0.9079**

Reference exclusions remain `Test/**`, `Replay.lean`, `ReplayJson.lean`, and `NativeMap.lean` under the existing reporter rule.

These numbers describe the current trusted-source accounting. They are not a claim that the final KernelCore has reached its minimum possible size.

## Allowed claims after Phase 12

It is now supported to say:

- the PSC1-self-hostable KernelCore validates bounded single-family recursive recursors for the recursive-inductive shapes accepted in Phase 11;
- recursive hypotheses are derived from admitted constructor shapes and checked in recursive-field order;
- canonical recursive self-calls are structurally validated;
- the accepted direct, multi-field, functional, and indexed positive shapes pass;
- the Phase 12 forged/missing/extra/reordered/wrong-motive/wrong-index/wrong-self-call cases fail closed;
- failed recursive-recursor admission leaves the prior environment unchanged;
- recursive iota computes embedded recursive self-calls using the existing reducer;
- mature-reference overlapping contracts are checked in the same differential fixture;
- all 23 trusted KernelCore modules pass the actual PSC1 self-host/source gate;
- the Phase 1 through Phase 12 aggregate assurance and the full repository regression gate are green on the accepted SHA.

## Explicit non-claims

Phase 12 does **not** establish:

- mutual-inductive support inside the trusted KernelCore,
- nested-inductive support inside the trusted KernelCore,
- arbitrary higher-order positivity beyond the bounded Phase 11 surface,
- general recursor synthesis/generation inside KernelCore,
- a broad K-recursor conversion expansion,
- structure-eta or projection expansion beyond existing accepted behavior,
- complete Lean primitive-reduction coverage,
- full K7/K8 replay,
- full Lean environment replay,
- compiler-native parity for every Lean declaration,
- compiler `CheckedCore` provider cutover,
- replacement or removal of `PSC1Kernel`,
- formal or full semantic equivalence to Lean 4.34.

## Recommended next phase

The highest-leverage next step is a bounded **KernelCore `CheckedCore` provider integration** for the minimal PSC2 bootstrap path, rather than immediately widening the trusted core with mutual/nested induction.

Target direction:

```text
Elaborated Core
  -> AdmissionReadyModule
  -> bounded adapter/lowering
  -> KernelCore admission/check
  -> CheckedCore
  -> Erasure
  -> VerifiedIR
```

During that transition:

- keep mutual/nested source lowering outside the TCB,
- keep the existing canonical-admission path and mature `PSC1Kernel` as differential/fail-safe oracles,
- do not remove the old provider until provider parity and bootstrap/fixed-point evidence are independently green,
- preserve the PSC1-subset/self-host gate for every trusted addition.

Phase 12 is therefore accepted as the recursive-recursor semantic prerequisite for that bounded provider-integration phase.
