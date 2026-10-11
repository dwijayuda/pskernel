# Continue PSKernel-Fast — P1l/P1m model and source-Pi bridge green

Repository `dwijayuda/pskernel`; ONLY branch `research/pskernel-fast-clean-v3-20261011`. Public open-source compiler/kernel correctness and formal-methods work. GitHub connector + cloud Actions only; no Desktop Commander, local repository checkout/files/builds/tests. Preserve every other branch and PR #89. Refresh live HEAD/affected blobs before each write and use non-force expected-HEAD commits.

## Read first

Read live `pskernel-fast/AI_WORK_STATE.md`, `P1L_P1M_PI_MODEL_EVIDENCE.md`/JSON and `ARCHITECTURE_POLICY.json`, then:

- `src/PSKernelFast/Spec/GraphApplication.lean`
- `src/PSKernelFast/Spec/TaggedDependentPi.lean`
- `src/PSKernelFast/Proof/SourcePiModelBridge.lean`
- `src/PSKernelFast/TypedNormalization.lean`

Target: official Lean **4.35.0-rc4**, upstream `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.

Last fully qualified CODE checkpoint at authoring: **`e95c0b5e381e4ee5a0d47001fad6c69494261683`**, [Actions 38143764809](https://github.com/dwijayuda/pskernel/actions/runs/38143764809), job `114482754713`, SUCCESS. Full log inspected: 58 independent Lean sources; exact assumption gates157+17+28=**202** distinct enumerated receipts; old native differential15 supported equalities,2 rejection controls,1 equality gap all passed. Focused42 and existing109 Lake invocation jobs overlap, so do NOT add them. Docs/policy may follow; fetch live matching CI.

## Newly established

P1l proves concrete Kuratowski pair injectivity and graph functionality, presentation-independent graph lookup, and graph beta/eta/intro/elim/extensionality for P1k's SAME-universe graph carrier. No new set basis laws or model axioms.

The unified `modelPi`/`modelLam`/`modelApp` algebra handles tagged proof-valued and graph-valued functions. Application depends ONLY on f,x; the existing proof-point-vs-graph noncollision theorem validates its branch. Exact numeric imax formation adds no extra Pi universe shift. Intro/elim/beta/eta and on-domain lambda/Pi congruence are proved. These are proof-only mathematical operations; universe inclusion/model extensionality do NOT grant new source conversion.

P1m `SourcePiAnnotation` contains source constraints, not semantic-fibre premises. It covers Sort, variables with actual syntactic Sort binder domains and Pi with arbitrary codomain rank. Source induction derives all fibres and modeled membership; separate proofs recover actual G4.3b typing, source erasure and the EXACT syntactic inferred Sort. `sourcePiAnnotation_executed_model` connects actual closed checker success to this guarded model theorem.

The symbolic example family `forall (A : Sort u), A -> A` has actual Prop/Type Pi-formation equations proved by `rfl` and an executed Type-case model bridge. This checks formation of the type/proposition, NOT an identity-function term or proof admission. A proof variable x:P is excluded by the current Sort-domain variable guard; it must not be mislabeled as P:Prop.

The original runtime checker, G4.4b reducer, basis, old157 audit and prior17 audit are unchanged. New audit `scripts/audit_graph_model.py` enumerates28 names. Allowed global assumptions remain propext/Classical.choice/Quot.sound. `[SetTheoryBasis V]` is STILL an explicit substantial hypothesis; no instance/model existence is constructed.

One intermediate run (`38142864676`) failed on a Pi-congruence simplifier step. `8421bc44580808f795788be4be2d6eba4bc5eef9` fixed it by composing existing equations, with no weakened statement/assumption; run38143138914 green. Do not claim this entire continuation first-run green. Latest source bridge was first-run green. Existing warnings remain.

## Next work: actual source term semantics and substitution

Extend OR REPLACE the proof-only annotation representation to cover source lambda/app/let and general dependent-context lookup. Do not bend the runtime architecture to preserve transitional proof syntax. Derive semantic context extension/weakening/substitution against real `KExpr.instantiateBVar`, reusing the existing source/erased substitution correspondence. Track codomain-sort annotations from actual typing rather than frontend metadata or assumed semantic validity.

Use the now-proved `modelPi_beta` only AFTER the source substitution/interpretation bridge is established to prove source beta/zeta preservation. `TypedSteps.denotation_preserved` STILL assumes `stepSound`; no full source theorem yet discharges it. Generalize its `A : Type` to a universe-polymorphic carrier as needed. Graph beta and guarded source-Pi formation do NOT equal full term soundness.

After the source bridge: richer typed conversion, exact symbolic universes, typed proof irrelevance/eta, protected immutable environment/transparency identity, quotient/inductive/primitive rules, FullyChecked declaration-model folds, relative no-False and representative kernel benchmarks. No blanket quotient freshness: arbitrary images can equal the point.

Smallness/performance/correctness outrank old proofs. One accepting semantic authority, no plugin votes, new global axioms or acceptance whitelists. Public admission remains disabled; admitted declarations=0. No matched official speed/RSS result and no new runtime optimization here; G4.4a timings do NOT describe G4.4b. Prior work-state/handoff were preserved byte-for-byte in `history/*THROUGH_P1K.md`.
