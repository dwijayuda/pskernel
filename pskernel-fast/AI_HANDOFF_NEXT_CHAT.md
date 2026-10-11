# Continue PSKernel-Fast — P1n/P1o source-certified six-form model green

Repository `dwijayuda/pskernel`; ONLY branch `research/pskernel-fast-clean-v3-20261011`. Public open-source compiler/kernel correctness and formal-methods work. GitHub connector + cloud Actions ONLY; no Desktop Commander, local repository checkout/files/builds/tests. Preserve other branches, PR #89 and concurrent work. Read live HEAD/affected blobs before each write; use serial non-force expected-HEAD updates.

## Read first

Read `AI_WORK_STATE.md`, `P1N_P1O_SOURCE_MODEL_EVIDENCE.md`/JSON and `ARCHITECTURE_POLICY.json`, then:

- `src/PSKernelFast/Spec/AnnotatedSubstitution.lean`
- `src/PSKernelFast/Proof/SourceSubstitutionModel.lean`
- `src/PSKernelFast/Proof/SourceModelTyping.lean`
- `src/PSKernelFast/Proof/SourceModelExecution.lean`
- `src/PSKernelFast/TypedNormalization.lean`

Pinned target: Lean **4.35.0-rc4**, upstream `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.

Last qualified SOURCE at authoring: **`84c27f8c953e3c3aed8ae7fc047a37437ce06d19`**, [Actions38152604792](https://github.com/dwijayuda/pskernel/actions/runs/38152604792), job114508960699, completed SUCCESS. Full job log inspected:62 audited source files; five disjoint exact gates157+17+28+18+12=**232** receipts; all earlier regressions/native differential15/2/1 pass. Focused46 and old109 Lake invocations overlap; do NOT add them. Docs/policy may follow; verify live matching CI.

## What is genuinely proved

P1n all-depth annotated semantic lifting/substitution covers all six constructors and commutes with source-matched erasure. `source_annotated_instantiate` uses the actual `KExpr.instantiateBVar` erasure theorem, not a toy source operation. Dependent `AnnotatedContextValid` interprets stored domain at index i in `dropModelEnv(i+1) env`; extension and actual lifted-domain lookup are proved, including non-Sort and proof-variable domains. The P1m embedding preserves model meaning.

P1o `SourceModelTyping` is a SOURCE-ONLY proof relation: actual terms/types, levels/valuation, context lookup, annotations. It contains NO V, model values or semantic-fibre assumptions. It supports Sort/bvar/Pi/lam/app/let. Lambda requires typing the body TYPE at the annotated sort, so the Prop/Type rank is justified. The source typing/erasure theorems and general semantic membership induction cover all six forms; exact raw GeneralPiRule type uniqueness connects actual inferred output.

`sourceModelTyping_beta` DERIVES the semantic fibre/body/arg premises from source certificates, then proves actual beta-step erasures and denotation preservation. `SourceModelExecution` certifies actual beta/let programs, proves real inference and G4.4b join equations by `rfl`, and obtains model membership/equal denotations via the general theorem. Actual Prop/Type polymorphic identity lambda programs similarly instantiate it, including proof variables x:P.

`sourceModelTyping_no_false` proves a **conditional no-inhabitant result for this SOURCE-CERTIFIED fragment**, empty contexts, literal `forall P:Prop,P`, canonical `.pi0(.sort0)(.bvar0)` annotation, assuming a supplied SetTheoryBasis. Do not call this full kernel consistency or native False/declaration soundness. The relation is nonvacuous (generic identity certificates), but is not proved synthesized for ALL checker successes.

## Next work — coverage/coherence, not another semantic substitution theorem

Prove source-certificate weakening/substitution closure and annotation coherence, then construct certificates from actual checker evidence. The semantic all-depth substitution theorem already exists; do NOT recreate it under another syntax. General raw G4.3b typing regularity/body-type sort evidence must be derived when proving certificate coverage, not smuggled in as a semantic premise.

Connect coherent source interpretation and preserved certificates to arbitrary runtime beta/zeta/function-spine reductions. Only a genuine theorem for those sources discharges the old `TypedSteps.denotation_preserved` stepSound premise. Its `A : Type` is still universe0; generalize as needed. Specific beta/let join examples are not a universal conversion proof.

Then broader conversion, exact levels, proof irrelevance/eta, environment/transparency, quotients/inductives/primitives, protected immutable FullyChecked declaration-model folds, modeled axioms and relative no-False capstone, and representative official-kernel CPU/RSS/allocations. Avoid false universal quotient freshness and preserve runtime architecture freedom.

## Safety/evidence boundaries

Unchanged SetTheoryBasis V is a substantial caller-supplied hypothesis, not a constructed model. Allowed global axioms remain propext/Classical.choice/Quot.sound; exact audits reject missing/extra/duplicate/sorryAx receipts. Keep every earlier gate enabled. Public admission remains disabled, zero admitted declarations. No new runtime optimization, size or speed result here; G4.4a timings do not describe G4.4b/full kernel.

Concurrent P1n work was preserved. This continuation fixed a dependent-match lookup proof, then repaired one new P1o build's reserved identifier/erasure proof issue without weakening a theorem or assumption. The final source/execution commit was first-run green; the whole continuation was NOT all-first-run green. Existing warnings remain.

Prior current work-state/handoff are archived byte-for-byte under `history/*THROUGH_P1M.md`. New canonical state is intentionally current rather than a long repetition of obsolete checkpoints.
