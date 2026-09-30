# PSC2 KernelCore Phase 12 Acceptance

Status: **ACCEPTED**

Date: 2026-09-30

Execution branch: `psc2/kernel-core-phase12-recursive-recursor`

Accepted permanent-assurance SHA:

```text
5a33460e6987736516f1b4ab87ad373977daec5d
```

Corrected focused semantic/test evidence SHA:

```text
27731b835ff5dd0187d1db0db7b6ae3f78b07f16
```

Phase 11 accepted branch baseline:

```text
c42481c7cf514fee800ca7876057b09600483dc9
```

## Exact acceptance evidence

Corrected focused Phase 12 workflow after the differential-oracle audit:

```text
workflow: PSC2 KernelCore Phase 12 work
workflow file: .github/workflows/psc2-kernel-core-phase12-work.yml
run: 36685273030
job: 109789577191
head: 27731b835ff5dd0187d1db0db7b6ae3f78b07f16
conclusion: success
Lean: 4.34.0
```

Final permanent acceptance workflow:

```text
workflow: PSC2 KernelCore Phase 12 acceptance
workflow file: .github/workflows/psc2-kernel-core-phase12-acceptance.yml
run: 36690404216
job: 109805998234
head: 5a33460e6987736516f1b4ab87ad373977daec5d
conclusion: success
Lean: 4.34.0
```

The final permanent workflow passed, on the same SHA:

1. `lake build PsKernelCore PSC1KernelReferenceFoundations`
2. `npm run assurance:kernel-core:phase12`
3. independent repository-wide `npm run check`

Between the corrected focused semantic/test SHA and the final permanent-assurance SHA, the branch contains only acceptance-workflow/documentation commits. No trusted KernelCore semantic source changed after the corrected focused run. The previously created acceptance document was updated here so the durable record points to the final corrected permanent run rather than the earlier permanent rerun.

## Accepted Phase 12 scope

Phase 12 extends the accepted Phase 10 ordinary-recursor path across the bounded recursive-inductive surface accepted in Phase 11.

Accepted behavior includes:

- single-family recursive recursor admission for the bounded Phase 11 shapes;
- direct recursive fields;
- multiple direct recursive fields;
- the explicitly supported strictly-positive functional recursive fields;
- the explicitly supported indexed recursive fields;
- recursive induction hypotheses derived from admitted constructor shapes;
- IHs pinned in classifier-derived recursive-field order;
- functional IH telescopes reconstructed from the accepted recursive field shape;
- indexed IHs using each recursive field's own classifier-derived indices;
- canonical recursive self-calls checked structurally instead of accepted merely because they typecheck;
- caller-supplied recursive-family flags re-derived from constructor analysis;
- recursive rule validation in a provisional immutable environment containing the recursor itself;
- transactional admission: failure leaves the caller's original environment unchanged;
- recursive iota computation through the already-existing KernelCore reducer.

`Ps.KernelCore.Reduce` required **no Phase 12 semantic change**. The existing reducer was already sufficient after admitted recursor rules were required to contain the canonical recursive self-calls.

## Trusted implementation surface

The Phase 12 trusted semantic additions are concentrated in:

```text
packages/pskernel-core/src/Ps/KernelCore/RecursiveRecursor.lean
packages/pskernel-core/src/Ps/KernelCore/IndexedRecursiveRecursor.lean
packages/pskernel-core/src/Ps/KernelCore/Recursor.lean
packages/pskernel-core/src/Ps/KernelCore.lean   (aggregate import only)
```

The implementation reuses the Phase 11 recursive-field classifier instead of introducing a second positivity checker. It does not add persistent recursive-field metadata or change the existing `PsKernelCoreRecursorInfo` / `PsKernelCoreRecursorRule` declaration schema.

The trusted core remains PSC1-subset source. The final permanent run reports:

```text
KERNEL_CORE_SOURCE_PROFILE: PASS (23 PSC1-subset, self-host-checkable modules)
```

This includes actual flattened PSC1 self-host/source checking of both new Phase 12 trusted modules, the recursor dispatch module, and the aggregate `Ps.KernelCore` module.

## Positive assurance matrix

The final permanent acceptance run passed all Phase 12 markers:

```text
PSC2_KERNEL_CORE_PHASE12_RECURSIVE_RECURSOR_ADMISSION: PASS
PSC2_KERNEL_CORE_PHASE12_RECURSIVE_RECURSOR_REJECTION: PASS
PSC2_KERNEL_CORE_PHASE12_REJECTION_MATRIX: PASS
PSC2_KERNEL_CORE_PHASE12_FUNCTIONAL_RECURSOR_ADMISSION: PASS
PSC2_KERNEL_CORE_PHASE12_FUNCTIONAL_RECURSOR_REJECTION: PASS
PSC2_KERNEL_CORE_PHASE12_INDEXED_RECURSOR_ADMISSION: PASS
PSC2_KERNEL_CORE_PHASE12_INDEXED_RECURSOR_REJECTION: PASS
PSC2_KERNEL_CORE_PHASE12_MULTI_RECURSIVE_FIELDS: PASS
PSC2_KERNEL_CORE_PHASE12_RECURSIVE_IOTA: PASS
PSC2_KERNEL_CORE_PHASE12_REFERENCE_PARITY: PASS
```

The corrected focused workflow also reran and preserved the Phase 10 ordinary-recursor admission/forged-minor guards and the Phase 11 recursive-inductive admission/rejection guards.

## Recursive rule / IH contract

For the accepted bounded surface, the trusted validator reconstructs the minor/IH contract from already-admitted constructor types.

For each constructor it requires:

1. ordinary constructor fields in constructor order;
2. exactly one IH for every classifier-recursive field, after the ordinary fields;
3. IHs in recursive-field order;
4. direct IH target `motive indices recursiveField`;
5. functional IH telescope matching the recursive field argument telescope and ending in the corresponding motive application;
6. indexed IHs using the recursive field's own indices;
7. final branch result matching the motive applied to the constructor result;
8. rule RHS selecting the correct minor and applying all ordinary fields followed by exactly the classifier-derived recursive calls;
9. each recursive self-call targeting the same recursor with the correct field, index arguments, fixed arguments and order.

Rule RHS type checking occurs only after structural rule validation, using a provisional immutable environment containing the already-validated recursor declaration. Failure does not replace the caller environment.

## Rejection and fail-closed evidence

The accepted Phase 12 negative matrix includes dedicated regression evidence for rejection of:

- forged or inconsistent recursive-family metadata;
- malformed recursive minor types;
- missing IHs;
- extra IHs;
- IHs in the wrong recursive-field order;
- wrong IH motives;
- wrong indexed IH arguments, including structurally noncanonical index expressions;
- functional IHs with missing, extra or wrong argument telescope structure;
- a type-correct recursive rule targeting a different same-typed constant/recursor;
- recursive calls using the wrong recursive field or indices;
- missing recursive self-calls;
- extra recursive self-calls;
- reordered self-calls for constructors with multiple recursive fields;
- unsupported recursive-field shapes;
- failed recursive-recursion admission that would otherwise mutate/replace the environment.

Binder names and binder annotations that are intentionally ignored by kernel expression equality are not treated as semantic differences; the functional negative fixture was corrected to reject genuinely different telescope domains instead of elaboration-only binder metadata.

## Recursive iota evidence

The Phase 12 recursive-iota fixture uses a nested recursive value more than one constructor deep and a minor whose result depends on the recursive result.

The fixture passes without changing `Reduce.lean`, proving for the bounded tested surface that ordinary recursor-rule reduction exposes the validated rule RHS and then evaluates the embedded canonical recursive calls to WHNF as required.

This does not claim arbitrary recursive/nested/mutual computation beyond the explicitly admitted surface.

## Corrected mature-reference differential evidence

`KernelCoreRecursiveRecursorReferenceParityTests.lean` was audited during acceptance because its first form only showed that mature `PSC1Kernel` supported the target shapes.

The corrected accepted fixture now evaluates corresponding semantic contracts on **both** KernelCore and mature `PSC1Kernel` in the same test and requires equality plus success for:

- direct recursive families;
- multiple recursive fields;
- functional recursive fields;
- indexed recursive fields.

Concretely, the final fixture requires:

```text
(psP12KernelDirect == psP12RefDirect) && psP12KernelDirect
(psP12KernelMulti == psP12RefMulti) && psP12KernelMulti
(psP12KernelFunctional == psP12RefFunctional) && psP12KernelFunctional
(psP12KernelIndexed == psP12RefIndexed) && psP12KernelIndexed
```

The mature reference also retains a direct recursive-reduction smoke test. KernelCore recursive-recursor admission, structural negative validation, and recursive iota are independently exercised by the dedicated KernelCore fixtures.

This is bounded differential assurance for the tested overlap. It is not a formal proof or a claim of complete implementation equivalence.

## Aggregate regression evidence

`npm run assurance:kernel-core:phase12` passed on the final permanent SHA and recursively preserved the Phase 1 through Phase 11 assurance stack before running all Phase 12 fixtures, the PSC1 source/self-host gate, and the deterministic size reporter.

The independent repository-wide `npm run check` then also passed on the same SHA. Notable final markers include:

```text
PSC1_WORKSPACE_SHAPE: PASS (20 workspaces)
PSC1_SOURCE_PROFILE: PASS (all-portable; 111 portable modules across 17 source roots)
KERNEL_CORE_SOURCE_PROFILE: PASS (23 PSC1-subset, self-host-checkable modules)
PSC2_LAYOUT_DRIFT: PASS
PSC2_BOOTSTRAP_CLOSURE: PASS (60 modules; ...)
PSC_IR_NEUTRALITY_PASS
PSC2_MINIMAL_SELFHOST_PASS: admission-ready boundary
PSC2_MINIMAL_SELFHOST_PASS: prepared core -> VerifiedIR
PSC2_MINIMAL_SELFHOST_PASS: forged admission-ready artifact rejected
```

The full regression also passes the existing PSC1 bootstrap/regression suites and the TypeScript, WASM and Rust backend/source test suites.

## Trusted-size evidence

The final permanent acceptance run reports:

```text
KERNEL_CORE_SIZE_REPORT: PASS
KernelCore trusted .lean file count: 23
KernelCore trusted source bytes: 302994
KernelCore trusted nonblank/noncomment LOC: 6721
PSC1Kernel comparable .lean file count: 22
PSC1Kernel comparable semantic-source bytes: 306641
PSC1Kernel comparable nonblank/noncomment LOC: 7403
KernelCore/reference byte ratio: 0.9881
KernelCore/reference LOC ratio: 0.9079
Reference exclusions: Test/**, Replay.lean, ReplayJson.lean, NativeMap.lean
```

Under the repository's current comparable-source policy, Phase 12 KernelCore is therefore about **98.81% of the reference bytes** and **90.79% of the reference LOC**. These numbers are accounting evidence only; they do not establish complete feature equivalence or prove the trusted core has reached its minimum possible size.

## Scope review

Relative to the accepted Phase 11 baseline, Phase 12 adds the recursive-recursor design/plan, focused/permanent CI wiring, Phase 12 fixtures, package assurance wiring, and the trusted recursive-recursion validation modules/dispatch described above.

No Phase 12 semantic change was made to:

```text
Ps.KernelCore.Reduce
existing declaration-schema representation
compiler provider semantics
TypeScript backend semantics
Rust backend semantics
WASM backend semantics
mutual-inductive machinery
nested-inductive machinery
```

The branch commits after the corrected focused semantic/test SHA and before the permanent acceptance SHA change only acceptance workflow/documentation material; they do not alter trusted semantic source.

## Allowed claims after Phase 12

It is now supported to say:

- KernelCore has a PSC1-self-hostable bounded single-family recursive-recursor validation path for the recursive-inductive shapes accepted in Phase 11;
- direct, multi-field, explicitly covered functional and explicitly covered indexed recursive recursors are admitted by the trusted path;
- recursive IH obligations are independently reconstructed from admitted constructor shapes;
- canonical recursive self-calls are structurally validated and cannot be replaced by merely type-correct alternate calls;
- forged/missing/extra/reordered/wrong-motive/wrong-index/wrong-self-call cases in the accepted matrix fail closed;
- failed recursive-recursor admission preserves the prior environment;
- recursive iota evaluates embedded recursive calls for the tested bounded surface using the existing reducer;
- corrected overlapping KernelCore/reference contracts agree for direct, multi-field, functional and indexed family shapes;
- all 23 trusted KernelCore modules pass the actual PSC1 source/self-host gate;
- Phase 1 through Phase 12 aggregate assurance and the independent full repository regression are green on the exact final permanent-assurance SHA.

## Explicit non-claims

Phase 12 does **not** establish:

- mutual-inductive admission/recursors inside trusted KernelCore;
- nested-inductive admission/recursors inside trusted KernelCore;
- arbitrary higher-order positivity beyond the bounded Phase 11 classifier surface;
- general recursor declaration synthesis/generation inside KernelCore;
- broad K-recursor conversion expansion;
- general structure-eta or projection expansion beyond existing accepted behavior;
- complete Lean primitive-reduction coverage;
- full K7/K8 replay;
- full Lean environment replay;
- compiler-native parity for every Lean declaration;
- compiler `CheckedCore` provider cutover;
- replacement or removal of mature `PSC1Kernel`;
- formal or full semantic equivalence to Lean 4.34.

## Recommended Phase 13

The highest-leverage next step is a bounded **KernelCore `CheckedCore` provider integration** for the minimal PSC2 bootstrap path, rather than immediately widening trusted KernelCore with mutual/nested induction.

Current compiler flow still effectively ends trusted preparation at the admission-ready artifact:

```text
Elaborated Core
  -> AdmissionReadyModule
  -> existing environment/admission preparation
  -> Erasure
  -> VerifiedIR
```

The recommended next architecture is:

```text
Elaborated Core
  -> AdmissionReadyModule
  -> bounded adapter / source lowering above the TCB
  -> KernelCore admission + checking
  -> CheckedCore artifact
  -> Erasure
  -> VerifiedIR
```

Phase 13 should begin as a shadow/differential provider integration rather than immediately deleting the old path:

1. define the smallest adapter from the compiler's elaborated/admission-ready declarations into KernelCore declarations for the existing bootstrap subset;
2. run KernelCore admission/checking in parallel with the existing canonical-admission path;
3. define a concrete `CheckedCore` artifact whose downstream erasure input is tied to successful KernelCore validation;
4. pin accept/reject and normalized metadata parity between the old provider and KernelCore on the bootstrap corpus;
5. preserve mutual/nested source lowering above the trust boundary;
6. preserve mature `PSC1Kernel` as a differential oracle during migration;
7. require bootstrap, self-host/fixed-point, backend, PSC1-source and full repository gates before considering an authoritative cutover;
8. remove or bypass the old provider only in a later, separately reviewed cutover after shadow parity is green.

Phase 12 is therefore the accepted recursive-semantic prerequisite for beginning that bounded provider-integration work.