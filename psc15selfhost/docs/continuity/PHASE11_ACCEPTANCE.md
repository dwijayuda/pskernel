# PSC2 KernelCore Phase 11 Acceptance

Status: accepted

Date: 2026-09-30

Execution branch: `psc2/kernel-core-phase11-recursive-inductive-work`

Planning/review branch: `psc2/kernel-core-phase11-recursive-inductive`

Accepted implementation/permanent-assurance SHA:

```text
9478e4b6b78387be9006aafac937b944cbb6fd60
```

Latest focused-assurance SHA:

```text
64455c816e04e6113ff9cc4a8b4a2981812876a9
```

The later focused-assurance SHA differs from the permanent-assurance SHA only by the Phase-11 focused workflow refinement. No trusted semantic source changed between those SHAs.

Exact permanent acceptance evidence:

```text
GitHub Actions workflow: PSC2 minimal kernel
workflow: .github/workflows/psc2-minimal-kernel.yml
run: 36607955041
job: 109541723866
head: 9478e4b6b78387be9006aafac937b944cbb6fd60
conclusion: success
Lean: 4.34.0
```

Corroborating focused Phase-11 evidence:

```text
GitHub Actions workflow: PSC2 KernelCore Phase 11 work
workflow: .github/workflows/psc2-kernel-core-phase11-work.yml
run: 36608017865
job: 109541938512
head: 64455c816e04e6113ff9cc4a8b4a2981812876a9
conclusion: success
Lean: 4.34.0
```

This acceptance record is documentation-only relative to both green assurance SHAs above.

## Accepted Phase 11 scope

Phase 11 adds the smallest trusted single-family recursive-inductive admission slice on top of the accepted Phase-8 inductive metadata/admission path and Phase-10 ordinary recursor path.

The trusted addition is concentrated in:

```text
packages/pskernel-core/src/Ps/KernelCore/RecursiveInductive.lean
```

with only the corresponding aggregate import added to `Ps.KernelCore`.

The phase accepts a deliberately bounded strictly-positive recursive surface and derives recursion metadata from the trusted classifier instead of trusting caller-provided recursive flags.

Accepted covered shapes include:

- direct structurally recursive fields, such as a List-like constructor containing the family directly;
- multiple direct recursive fields, such as a binary-tree-like constructor;
- the explicitly tested strictly-positive functional-recursion shape, such as a field ending in the family through a function codomain while the family does not occur negatively in the function domain;
- the explicitly tested indexed recursive-family shape with canonical parameter/universe/result application discipline.

Phase 11 does **not** add recursive recursor generation, recursive induction hypotheses, or recursive iota reduction. Those remain separately gated.

## Trusted classifier and derived metadata

The accepted implementation performs bounded recursive-field analysis inside KernelCore and derives the recursive family metadata from constructor types.

For the accepted surface it:

1. recognizes canonical direct occurrences of the family at the expected parameter/index application shape;
2. weak-head reduces field types through the existing resource/budget path before classifying them;
3. follows `forall` codomains for the explicitly admitted strictly-positive functional shape;
4. rejects any occurrence of the target family in a function domain;
5. rejects target occurrences that remain nested in unsupported heads/containers;
6. preserves parameter, index and universe discipline from the Phase-8 single-family validator;
7. derives `isRec` from accepted recursive-field evidence;
8. derives `isReflexive` for the covered functional-recursion shape instead of trusting caller-provided metadata;
9. inserts the family and constructors transactionally only after all trusted checks succeed.

The classifier is PSC1-source compatible and does not introduce trusted `partial`, `unsafe`, IO, Lean/Std implementation APIs, custom elaborators, or host-side semantic caches.

## Exact accepted rejection matrix

The Phase-11 rejection fixture pins fail-closed behavior for at least:

- negative recursive occurrence;
- unsupported/nested recursive occurrence;
- invalid recursive result/index shape;
- recursive-index misuse outside the admitted indexed shape;
- nonuniform parameter application;
- wrong constructor arity/field count;
- wrong universe or constructor parameter metadata;
- forged/inconsistent recursion flags and inductive metadata;
- constructor metadata inconsistent with its admitted family;
- transactional admission failure, leaving the original environment unmodified.

Where mature `PSC1Kernel.addSimpleInductive` covers the same canonical input shape, the Phase-11 parity fixture compares accept/reject behavior and accepted family/constructor metadata against that reference oracle.

## Exact green gate evidence

The exact permanent acceptance head passed workflow run `36607955041`, job `109541723866`, including:

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
Phase 11 recursive inductive shape
Phase 11 recursive inductive admission parity
Phase 11 recursive inductive rejection matrix
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
Phase 11 aggregate assurance
Existing PSC2 regression gate
```

Every listed permanent step concluded `success`, including the final full repository `npm run check` regression gate.

The focused Phase-11 run independently passed:

```text
PSC2_KERNEL_CORE_PHASE11_RECURSIVE_SHAPE: PASS
PSC2_KERNEL_CORE_PHASE11_RECURSIVE_ADMISSION: PASS
PSC2_KERNEL_CORE_PHASE11_RECURSIVE_REJECTION: PASS
PSC2_KERNEL_CORE_INDUCTIVE_ADMISSION_PARITY: PASS
PSC2_KERNEL_CORE_INDUCTIVE_REJECTIONS: PASS
PSC2_KERNEL_CORE_EQ_INDUCTIVE: PASS
PSC2_KERNEL_CORE_RECURSOR_REJECTION: PASS
PSC2_KERNEL_CORE_RECURSOR_FORGED_MINOR_REJECTION: PASS
PSC2_KERNEL_CORE_EQ_RECURSOR_COMPATIBILITY: PASS
```

This preserves the Phase-8 non-recursive/Eq path and the Phase-10 recursor hardening while adding recursive admission.

## Source/self-host evidence

The exact focused-assurance head reports:

```text
KERNEL_CORE_SOURCE_PROFILE: PASS (21 PSC1-subset, self-host-checkable modules)
```

The new `RecursiveInductive.lean` module itself passes the flattened PSC1 source/self-host path, and the complete `Ps.KernelCore.lean` aggregate also passes.

The bootstrap compiler closure remains isolated from `pskernel-core`. Phase 11 does not make KernelCore the authoritative compiler `CheckedCore` provider and does not remove the mature `PSC1Kernel` reference oracle.

## Trusted-size evidence

The exact focused-assurance head reports:

```text
KERNEL_CORE_SIZE_REPORT: PASS
KernelCore trusted .lean file count: 21
KernelCore trusted source bytes: 237502
KernelCore trusted nonblank/noncomment LOC: 5414
PSC1Kernel comparable .lean file count: 22
PSC1Kernel comparable semantic-source bytes: 306641
PSC1Kernel comparable nonblank/noncomment LOC: 7403
KernelCore/reference byte ratio: 0.7745
KernelCore/reference LOC ratio: 0.7313
Reference exclusions: Test/**, Replay.lean, ReplayJson.lean, NativeMap.lean
```

These numbers describe the current Phase-11 trusted source under the repository's deterministic comparable-source policy. They are not a claim of complete Lean-kernel feature equivalence.

## Scope review

Relative to the accepted Phase-10 head, the Phase-11 diff is limited to:

```text
Phase-11 design/plan documentation
Phase-11 focused workflow
permanent Phase-11 workflow/package assurance wiring
one new trusted RecursiveInductive module
one KernelCore aggregate import
Phase-11 recursive shape fixture
Phase-11 recursive admission parity fixture
Phase-11 recursive rejection fixture
```

No trusted changes were made to:

```text
Recursor.lean
Reduce.lean
existing declaration-schema semantics
compiler/provider semantics
TypeScript/Rust/Wasm backend semantics
mutual-inductive machinery
nested-inductive machinery
```

The focused-workflow-only commit after the permanent accepted SHA does not alter trusted semantic source.

## Allowed claims

After this acceptance it is valid to claim:

- KernelCore has a PSC1-self-hostable bounded strict-positive single-family recursive-inductive admission path for the explicitly tested Phase-11 surface.
- direct, multiple-field, explicitly covered functional-positive, and explicitly covered indexed recursive constructor shapes are admitted with differential reference evidence where the mature oracle overlaps.
- recursive-family flags are derived by trusted analysis rather than accepted blindly from callers.
- negative, unsupported nested, malformed indexed/nonuniform, wrong-universe/arity, forged-metadata and transactional-failure cases are fail-closed by dedicated regression tests.
- the previously accepted Phase-8 non-recursive/Eq and Phase-10 ordinary recursor paths remain green.
- all permanent Phase-1 through Phase-11 aggregate gates and the full existing PSC2 regression gate are green on the exact permanent accepted implementation/assurance SHA.

## Explicit non-claims

This acceptance must **not** be used to claim:

- recursive recursor generation inside KernelCore;
- recursive induction-hypothesis validation;
- recursive-constructor iota reduction;
- arbitrary higher-order/nested positivity beyond the explicitly admitted classifier surface;
- mutual inductive admission;
- nested inductive admission;
- source-level mutual/nested lowering inside the trusted kernel;
- general Lean structure/projection computation;
- K recursor conversion;
- complete Lean primitive reduction;
- full K7/K8 or full Lean environment replay parity through KernelCore;
- compiler `CheckedCore` provider cutover;
- replacement/removal of mature `PSC1Kernel`;
- full or formally proven equivalence to Lean 4.34.

The strongest valid summary is:

> KernelCore now has a PSC1-self-hostable, bounded strict-positive single-family recursive-inductive admission path with trusted derived recursion metadata, differential/reference coverage for the admitted surface, fail-closed positivity/shape regressions, and a fully green Phase-1-through-Phase-11 permanent assurance plus repository regression gate; recursive recursors/IHs/iota, mutual/nested induction and compiler cutover remain separately gated.

## Recommended Phase 12

The next semantic phase should be **recursive recursor / induction-hypothesis validation plus recursive iota**, built on the accepted Phase-11 classifier.

Phase 12 should not duplicate positivity analysis. It should consume the trusted recursive-field summaries produced by Phase 11 to determine exactly where induction hypotheses are required and how constructor fields map into recursive recursor minors.

Recommended Phase-12 order:

1. design the canonical recursive-minor/IH contract from the admitted Phase-11 field summaries;
2. RED fixtures for List-like, multi-recursive-field, functional-recursive and indexed recursive recursors;
3. trusted validation of supplied recursive recursor metadata against admitted constructors and derived recursive-field summaries;
4. fail-closed forged-IH/minor tests analogous to Phase 10's forged-minor hardening;
5. bounded recursive-constructor iota reduction using the already validated rule/IH layout;
6. reference differential tests against mature `PSC1Kernel` where the same surface overlaps;
7. actual PSC1 source/self-host gate, permanent Phase-12 aggregate and full repository regression before acceptance.

Mutual/nested inductive support and compiler-provider cutover should remain later, separately reviewed phases.
