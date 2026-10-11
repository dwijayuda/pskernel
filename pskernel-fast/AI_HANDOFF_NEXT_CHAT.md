# PSKernel-Fast continuation handoff — P1h and beyond
**Updated October 11, 2026 after independently verified P1g source+CI.**
This is the user's public open-source compiler/kernel correctness, Lean semantics, formal-model research and safe differential/conformance testing; no offensive-security work.

## Exact ownership and work boundaries

- Repository: https://github.com/dwijayuda/pskernel
- **ONLY development branch:** `research/pskernel-fast-clean-v3-20261011`. Never touch, merge, delete or force-update existing branches/PRs (including PR #89) without the user's express instruction.
- GitHub connector and GitHub Actions/cloud CI ONLY. No Desktop Commander, local checkout, build or tests. Before EACH write fetch live HEAD and relevant blob SHAs; preserve concurrent changes with non-force expected-HEAD fast-forward commits.
- Exact compatibility target `leanprover/lean4` `v4.35.0-rc4`, source `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
- Follow `pskernel-fast/AI_WORK_STATE.md`, `ARCHITECTURE_POLICY.json`, `PSKERNEL_FAST_SOUNDNESS_CONTRACT_V1.md`, `P1F_TAGGED_MODEL_EVIDENCE.md`, and now **`P1G_TAGGED_INTERPRETATION_EVIDENCE.md` / JSON**.
- Last source/CI green when this handoff was authored: **`8cc2d41aee99ec82fc2fbcd265c11875d4581590`**, [run 38133327235](https://github.com/dwijayuda/pskernel/actions/runs/38133327235), job `114451991620`: **96 Lake build jobs, 44 independent Lean source modules, 129 reviewed exact theorem-assumption receipts, all G1–G4.3b focused regressions GREEN**, pinned rc4. Documentation and architecture-policy commits may follow; LIVE HEAD and exact CI always govern.

## Mission and intellectual priorities

PSKernel-Fast targets exceptionally high **actual Lean kernel throughput**, semantic fidelity to official Lean 4.35.0-rc4, a small independently auditable trusted kernel, implementation/refinement metatheory, and eventually a **CONDITIONAL model-based relative consistency theorem**. Performance/correctness override old kernel/proof shape preservation. Proof-only mathematics must never enlarge runtime acceptance authority. Avoid arbitrary counterexample patches, test-fix hunting, false quotient/model axioms, unreviewed native_decide and unsupported consistency claims.

### Established scope (independently green)

- G1–G3: independent AST, scope preflight and evaluated beta/closure/DAG experiments. Beta experiments do not measure real kernel performance.
- G4.0: positive-sound but INCOMPLETE symbolic universe equality. G4.3b running six-rule restricted Sort/bvar/Pi/lam/app/let checker with exact syntactic application and restricted let; proof admission CLOSED, admitted declarations 0.
- P1a–P1c: independent scope/context/erasure, bounded subject reduction and typing, NOT general typed dependent substitution.
- P1d–P1e: provisional P1d `True={empty}` model fails proof-point disjointness; P1e V2 point equals a writable Kuratowski pair. Old provisional `sortSet/propPi/interpProp` and their proof receipts remain compiled as HISTORY, not endorsed as a final semantics.
- P1f: independent `SetTheoryBasis V`-conditional new tag `{empty,{{empty}}}`, point `{tag}`, `True={point}`, `Prop=power(True)`. Proven exclusion from exact Kuratowski pairs, graphs, finite von Neumann numerals and proposition truth values. Pair closure from Tarski's size law, tagged point and Prop∈Type1, tagged successor Sort. IMPORTANT NEGATIVE: arbitrary images and unconstrained quotient constructions **CAN** equal the point. No blanket quotient-freshness axiom.
- **P1g just proved:** new **single canonical tagged model tier for NEW source proofs** in `Spec/TaggedPropSemantics.lean`, using P1f carrier/tower and one `taggedPropPi/interpTaggedProp` over existing source-independent `PropInterpTerm`. Separately proved valid semantic fibres for false `∀P:Prop,P` and true `∀P:Prop,P→P`. `Proof/TaggedPropModelBridge.lean` confirms actual G4.3b successes, source-certified Prop Pi annotations, precise erasure/imax and NEW tagged false/true denotations. Model false has no inhabitant; true has only distinguished pt. The general annotated tagged Pi theorem STILL REQUIRES separately validated semantic fibre evidence. 19 added exact theorem receipts; now 129 total. Existing provisional P1e interpreter NOT YET fully retired.
- **All ambitious flags STILL FALSE**: constructed `SetTheoryBasis` instance, full WellDenoted, proof-term irrelevance, general dependent Type graph Pi/app/eta, typed guarded quotient model, general executable checker denotational soundness, complete typed WHNF/DefEq, complete immutable checked declarations/model extension, `model_exists`, `no_derived_False`, full Lean/Mathlib compatibility, proof admission, and real kernel-only CPU/RSS/allocations comparisons.

### P1h and later: do in mathematical dependency order

1. Read LIVE HEAD/CI + P1g source & evidence, then inspect current `CheckedPropAnnotation`, `GeneralPiRule`, erased AST and `TaggedPropPiFibresValid`. Design **hereditary `WellDenoted`** relating source contexts/environments/types to the TAGGED model. Prove real binder-fibre validity from source judgments where possible; do not simply restate it as a trusted hypothesis.
2. Check source-relevant Sort and bound-variable semantic laws, and dependent proposition Pi. Keep exact symbolic imax and checked binder classification; prove extension/weakening/substitution denotation where the current restricted fragment supports it. Existing two source examples are a positive regression baseline, NOT a general induction theorem.
3. Independently build **Type-valued dependent graph Pi**, graph membership and typed application/beta/eta from concrete SetTheoryBasis closure. Separate proof-erasure/irrelevance and protected writable slots for typed quotient terms. Preserve P1f's formal negative unrestricted-image proof.
4. Only after semantic closure: typed WHNF/DefEq that is positive sound with resource outcomes, exact Lean universe/inductive/quotient rules, immutable `FullyChecked` declarations and model-preserving folds, conditional no-False consistency from actual model existence assumptions, full official differential conformance and **real kernel-only benchmarks**.
5. Never turn a result requiring `[SetTheoryBasis V]` into a claimed model-existence proof. Maintain proof-only `Spec` and `Proof` separate from the runtime authority `Core`. Reject caches/plugins/untrusted annotations as proof admission authority.

## Iteration and evidence rules

- Architecture, invariants and proof obligations first; exact cloud CI second. The workflow `.github/workflows/pskernel-fast-v3.yml` now explicitly builds tagged model/proof files and **streams** theorem-audit compiler diagnostics, avoiding a masked-error failure from the first P1g attempt.
- On code/proof changes, ensure the exact commit completed GitHub Actions; audit `pskernel-fast/scripts/audit_axioms.py` reviews exactly 129 theorems (update its reviewed set if genuinely adding #print axioms). Allowed `propext`, `Classical.choice`, `Quot.sound` only. `SetTheoryBasis V` is a caller-supplied substantial mathematical model assumption and **not** an additional #print-axioms token.
- Check LIVE HEAD + blob SHAs before writes and use serial non-force, expected-HEAD updates. Update AI_WORK_STATE and policy only with actually qualified proof-status booleans and exact CI; keep honest records of intermediate failures.
- Preserve all historical branches/PRs. Work autonomously through meaningful proof slices while the conversation/tools permit. If close to chat limit, refresh these handoff/state docs for the next chat.

**First action for the next chat:** read LIVE source, work state, updated P1g evidence and CI. Design and implement a small hereditary `WellDenoted` P1h theorem slice, with real checked-source and tagged-model premises, and verify exact cloud CI. Do not reintroduce the provisional truth carrier as the canonical semantics.
