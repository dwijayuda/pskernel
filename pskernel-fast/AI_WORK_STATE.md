# PSKernel-Fast V3 work state

## Scope and authority

New-generation PSKernel-Fast independent architecture. **Performance and semantic correctness take precedence over preserving old checker or old proof work.** V3 is canonical at [architecture](PSKERNEL_FAST_ARCHITECTURE_V3.md). Lean target: 4.35.0-rc4; source commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.

Working branch: `research/pskernel-fast-clean-v3-20261011`. Source ancestor: V2 research commit `80f198c41fe7e3a8bd96a910672f26f5ddd94882`. Active kernel proof branch, its prior evidence and draft PR #89 are **not dependencies and are not modified**.

## Completed document decisions

- V3 architecture document created with full freedom for a new kernel implementation, compact DAG / closure/NbE alternatives, formal method target, benchmark gates and clean architecture.
- V2 document on THIS research branch explicitly marked superseded.
- No V1/V2 checker integration, migration theorem or old self-host source profile is required to select V3's implementation.

## Prototype state

The first G1 term-store experiment consists of:
- `src/PSKernelFast/TermStore.lean`: tiny closed AST, total scope-validating encoder, collision-checked interning, capped allocation, fuel-limited decoder;
- `src/PSKernelFast/Smoke.lean`: narrow safety smoke cases;
- standalone pinned Lean 4.35 Lake configuration and GitHub Actions focused workflow.

**Evidence status at authoring:** source committed once the associated commit is created; CI outcome **not yet known**. No kernel checker/admission implementation, executable proof soundness theorem or measured speedup. Do not upgrade to passed/verified unless the completed cloud CI job and exact commit are inspected.

## Next steps

1. Inspect workflow outcomes and fix any real Lean compiler errors in the coherent term-store slice; no proof shortcut.
2. Prove exact interning/encoding/scope invariants on the current implementation (not an unrelated reference model).
3. Add exact Name/Level/Expr representations and scope/level checks toward full Lean 4.35 syntax.
4. Build two comparable WHNF engines (eager DAG vs lazy closure) behind the same input/output contract and profile on controlled corpus.
5. Only after correct reduction/typing gates, add a checked inference/DefEq engine and declaration admission; keep fail-closed error types.
6. Track actual source LOC, trusted runtime dependencies, CI, mem/RSS and the current open formal-obligation ledger on every milestone.

## Operating rules

GitHub and cloud CI only, no local checkout or Desktop Commander. Re-read live HEAD before write; preserve branch history and concurrent work; no force update. Use small fast tests for ordinary changes and budgeted broad Init/Std/Mathlib only at stated release gates. Do not claim green CI, self-host, Lean-compatibility or consistency without matching evidence.

## Cloud CI evidence, October 11, 2026

Initial source commit `0a4f0ce48aa421be8df92fdc09ed6f6c204f80d5`: [run 38093827666](https://github.com/dwijayuda/pskernel/actions/runs/38093827666), job 114335503566 **failed during lean-action configuration** because this new package had no `lake-manifest.json` and the workflow used `auto-config: false`. **No source compilation, smoke or kernel proof checking ran.** The next workflow sets `auto-config: true` so Lake may generate the manifest. It also exposes a top-level `main` for the executable. The corrected revision must be validated by its own completed workflow; do not convert the first failure into a pass.

**Second workflow outcome:** corrected source commit `b712bc5109ecce5da2752e5de8a551e267fd7b9e`, [run 38093919479](https://github.com/dwijayuda/pskernel/actions/runs/38093919479), job 114335774523, **failed before compilation** for the same missing `lake-manifest.json` because `lean-action@v1` checks it even with `auto-config: true`. The next CI uses direct pinned elan installation followed by `lake update` and `lake build`. Both failures are **CI configuration blockers only; the prototype has not yet compiled or run**.

**Third workflow outcome:** source commit `6a13b87ecea0b37300ec51c4a47eb2f5b279dd76`, [run 38093991215](https://github.com/dwijayuda/pskernel/actions/runs/38093991215), job 114335993755, **reached Lean compilation** after `lake update`; failed on a malformed opening doc comment terminator in `TermStore.lean:7` (`-/-` instead of `-/`). Correct the syntax in one coherent source edit. The smoke executable never ran in that attempt. Next workflow also uses sparse checkout to avoid loading unrelated legacy files; it remains native G1 only.

## Green standalone source checkpoint, October 11, 2026

**Validated source and workflow:** commit `6fd4d9f5d7a3ec2277e2f194dab77db8a106763c`. [GitHub Actions run 38094070233](https://github.com/dwijayuda/pskernel/actions/runs/38094070233), job `114336229075`: **passed**. The cloud log shows pinned Lean 4.35.0-rc4 at `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`, all **6 standalone build targets** built and executable output `PSKernel-Fast V3 term-store prototype: focused safety smoke passed`. This proves a successful build and finite focused tests for the tiny representation prototype only. It is **not a proof checker, full Lean 4.35 conformance, source-soundness theorem, or performance benchmark**.

After this green source, the next changes add a machine-readable policy and independent-import CI fence without modifying TermStore or Smoke. Record CI outcome for that exact follow-up commit separately; do not retroactively relabel this green checkpoint.

**Policy-fenced CI checkpoint:** commit `d4c76b9380bfe5c6b41da2b61bc493c5712f0034`, [run 38094158324](https://github.com/dwijayuda/pskernel/actions/runs/38094158324), job 114336483209 **passed** audit stage, six native Lean 4.35 build jobs and focused smoke. A source review immediately afterward found that the audit's optional `sorry/axiom` regular expression had one excess escape, so that specific safeguard was **not fully effective** in this run, although the legacy import fence and compiled representation smoke ran. The next commit corrects the regex and adds an explicit self-test of the placeholder matcher. This is a CI policy checker correction, not a kernel semantic change.

## Latest fully green V3 checkpoint — October 11, 2026

**Source + audit commit:** `7704ba2503fc2206755535f6259292c6dc5834d9`; [GitHub Actions run 38094207080](https://github.com/dwijayuda/pskernel/actions/runs/38094207080), job `114336626851`: **success**. The completed log records `V3 architecture fence PASS: 2 independent Lean source files`, exact Lean `4.35.0-rc4` commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`, **all 6 build jobs passed**, and focused runtime output `PSKernel-Fast V3 term-store prototype: focused safety smoke passed`. The audit includes a self-test of the forbidden `axiom/sorry` matcher. The workflow uses sparse checkout and no legacy kernel import. 

**Qualification scope:** tiny structurally scoped, hashed DAG representation **only**. Not a theorem checker, not an accepting DefEq algorithm, not full Lean compatibility, not formally proved roundtrip, not a performance comparison and not self-hosted JS/Wasm. The project's V3 correctness and performance score remain **unmeasured/unqualified**. The next substantive work is G1 exact proof of representation invariants plus G2 matched eager/closure WHNF experiments. Maintain independent sources and no old proof-preservation constraint.

**Workflow housekeeping in this docs commit:** narrow CI trigger paths to standalone Lean source, package config, audit policy/script and workflow; ordinary documentation/evidence-only commits do not waste native CI time. This housekeeping commit itself should be checked before calling its workflow qualified.

## G2 evaluation prototype — candidate, awaiting cloud evidence

Designed on live V3 head `f372677cd5cf72d4a7798f70522518d61813f5b4`, independent of current PSKernel proof/core code. Introduces **two prototype beta WHNF executors over identical decoded closed terms**:

- **Eager**: leftmost weak-head beta contractions using capture-avoiding de Bruijn instantiation, bounded by beta contraction count.
- **Lazy**: call-by-name closure/environment machine; inert neutral sorts and a pending argument spine; bounded scan and separate readback with binder-depth-aware quotation.

Both share the same `RawExpr` obtained by encoding + decoding the G1 interned DAG. **This is not yet direct handle-based DAG evaluation, not full NbE, not Lean 4.35 DefEq and not theorem admission.** The eager contraction budget and lazy transition budget measure different operations; equal fuel values have no semantic compatibility claim. One-pass exploratory timing is not fair general performance evidence; benchmark matches terminal values and explicitly discloses scope.

Test families include capture avoidance, shadowing, multi-beta, inert neutral application (does not evaluate argument), duplication, long identity chains, omega fuel exhaustion and invalid store handles. Every agreed result is also checked against a specific expected raw WHNF, so mutual agreement alone cannot disguise an incorrect reference result.

Next: inspect the exact cloud run for this candidate; if green, profile multiple runs/hot cases, add work counters, refine representations and begin a formal reduction specification. **No quantitative speedup claim before cloud evidence.**

## G2 stronger evidence — candidate, pending CI

Previous **green** G2 source commit `557f30c6be7675c92ddd3c6045193e2565168193` passed [GitHub Actions run 38107251428](https://github.com/dwijayuda/pskernel/actions/runs/38107251428), job `114375255032`: **14 native build targets**, existing G1 smoke and named G2 differential corpus passed. Initial exploratory, non-repeat timing for **700** closed beta WHNF samples: eager **18 ms**, lazy + readback **1 ms**. **Not a Lean kernel benchmark or validated speedup** (tiny untyped source subset, different resource budgets, one runner).

This candidate makes the **actual eager reduction step proof-carrying**: `HeadBeta` is a new small-step specification and `eagerHeadStepCertified` returns the exact one-step witness; `eagerHeadStep_sound` states successful actual step implies `HeadBeta` (proof must compile in CI). No old proofs imported. It also runs a deterministic bounded generated corpus plus fixed expected regressions and measures **5 interleaved runs** with matched decoded DAG inputs, warmup and digest parity. The lazy evaluator remains differentially checked, not formally refined. Full Lean 4.35 kernel semantics remain future.

## G2 certified-step and repeated timing — confirmed green

**Validated source:** `059fc77ef9863ac71da4f42b5e7caeb71ffbe4e8`, [run 38107425028](https://github.com/dwijayuda/pskernel/actions/runs/38107425028), job `114375775716`: **success**. **14 native Lean build jobs**, V3 source fence, G1 smoke and G2 named+generated differential smoke passed. The actual executing eager step is now derived from `eagerHeadStepCertified`, with a small-step `HeadBeta` relation and compiling theorem `eagerHeadStep_sound`. This only proves the one-step beta/head-context relation for the prototype, **not the lazy implementation, WHNF normalization, Lean DefEq, or general proof soundness**.

Finite generated corpus: **92 additional closed raw expressions** yielded identical eager and lazy weak-head results; **zero paired resource exhaustion** among these generated cases. The omega case still separately tests independent resource exhaustion. Benchmark: **5 repetitions of 5,040 matched beta-only evaluations per strategy**, eager elapsed [67,71,69,69,68] ms (median **69ms**), lazy with full result readback [4,3,3,4,3] ms (median **3ms**). These measurements exclude input encoding/decoding, are one cloud runner, have millisecond granularity and concern a tiny untyped beta calculus; not a measured 23x Lean kernel speedup.

**New correctness concern and fix candidate:** while `decode` checks handle bounds and structural fuel, a hostile but in-range Store could decode into a raw term with escaped bvars. Add an independent `RawScoped` predicate, a structurally recursive `isScoped` validator, a direct `isScoped_sound` theorem, and fail-closed scope validation in `decodeForEvaluation` for all G2 entry points. Add malformed in-range and nested binder tests. Their CI outcome is pending this follow-up commit; do not report validated until the completed job passes.

## G2 third-engine candidate: evaluate compact DAG handles directly

The follow-up architecture experiment implements `DagReduction.lean`, using a call-by-name closure machine over **interned Store node handles**, with a separate exact de Bruijn readback. It does not reconstruct a RawExpr during head evaluation; it traverses the DAG and allocates only closure environments/spines. The **public prototype entry** `dagWHNFFromCheckedInput` first invokes `decodeForEvaluation` for full fuel/scopedness validation; a lower-level `dagWHNFOnValidatedGraph` is for benchmark inputs prepared and checked beforehand and is **not a proof-authoritative API**.

G2 named and generated differential tests now compare **eager raw substitution, lazy tree closures and lazy DAG handles** against fixed expectations or each other, plus malformed DAG, capture-avoidance and omega resource tests. The benchmark rotates strategy order over 5 repeats of 5,040 inputs per engine, with encoding/decoding excluded from timed sections for all 3. It prints separate timings. **No win is assumed**; the DAG lookup overhead may dominate this tiny workload. The CI evidence for this candidate is pending.

**First direct-DAG experiment cloud result:** source `3b173aa0748c0b8e520e9ec2df666e591c08a89f`, [run 38107686483](https://github.com/dwijayuda/pskernel/actions/runs/38107686483), job `114376557389`: **failed before smoke**. The new `DagReduction.lean` module and 15 of 16 available targets built, but `ReductionSmoke.lean:79` split a `throw (IO.userError String)` expression across lines in a way Lean interpreted as application returning `IO.Error`. This is a syntax error in the test harness, **not a failed evaluator semantic case**. The next commit makes the exceptional branch one expression, then reruns full focused smoke and benchmark. Do not count this run as a pass.

## G2 three-engine validated architectural checkpoint — October 11, 2026

**Latest G2 checked source:** `3ed28be5834078d5cd33a762cb183cf9693a2520`, [run 38107735958](https://github.com/dwijayuda/pskernel/actions/runs/38107735958), job `114376707944`: **success**, all **16 native build jobs**, independent import audit, G1 smoke, three-engine named+92 generated differential checks, and repeated benchmark. The first direct-DAG attempt `3b173aa` failed for a Lean test-harness `throw` layout error, not a demonstrated evaluator soundness defect; corrected in the green source. See [G2 evidence](G2_EVALUATION_EVIDENCE.md) and [machine-readable record](G2_EVIDENCE.json).

Five repeated medians for equal-output beta-only WHNF, 5,040 evaluations per strategy per repetition, prepared validated inputs: eager **121 ms**, lazy tree **7 ms**, lazy DAG **7 ms**. NO Lean kernel speedup, peak memory, universal lazy soundness or self-host inference. **Architecture finding:** keep closure laziness as a candidate; DAG traversal has no advantage for this tiny corpus, and must be justified by larger sharing/memory analysis before promotion.

**Next:** move to G3 real Lean 4.35 expression/universe/constant and graded checker infrastructure with independent semantic spec and explicit resource/error rules. Avoid further ratio-chasing on toy beta-only code. Preserve V3 independence and do not make old proofs a constraint.

## G3 independent Lean 4.35 semantic syntax candidate — CI pending

Source added from official Lean 4.35 kernel `level.h`, `expr.h`, `type_checker.cpp` and `Lean/Level.lean`. V3-owned `KName`, `ULevel`, `KExpr` and binder/literal structures cover core constructor *shapes*; exact closed structural preflight rejects undeclared level parameters, level metavariables, escaped bound variables and free/metavariables, with proper Pi/lambda/let binder depth. Ground numerical `imax` is tested against official `Lean.Nat.imax` over a small grid. **Not symbolic universe equivalence or a type checker.** `mdata` uses a temporary opaque tag, explicitly unqualified for full interchange. See [G3 spec](G3_STRUCTURAL_SPEC.md).

The existing G2 `RawExpr`/DAG/closure code remains experimental, **not the required eventual logical representation**. The V3 architecture is free to replace it. Cloud CI outcome for this candidate must be inspected before any validation claim.

## G3 formal structural-preflight candidate — pending cloud verification

The initial G3 source commit `a66038fcbd1beed02f8b4c29d208be4e55c50bf1` passed [run 38107993641](https://github.com/dwijayuda/pskernel/actions/runs/38107993641), job `114377475907`: **21 native build jobs**, V3 import fence, original G1/G2 checks and G3 smoke (400 ground `imax` comparisons with `Lean.Nat.imax`, binder/parameter/metadata shape). Scope remains **structural only**, not proof checking.

This follow-up introduces a **separate declarative structural judgment** `ULevel.WellFormed` and `KExpr.StructurallyValid`; validator parameter membership uses `decide (name ∈ params)` and derives decidable KName equality. Proved theorem targets `ULevel.validParams_sound`, `KExpr.validAt_sound`, `KExpr.closedInput_sound` directly connect actual executable structural preflight to these predicates. No `sorry`, imported old proofs or axiom shortcuts. **The proofs are candidates until their compiled cloud job succeeds.**

**First G3 proof candidate failed preflight compilation:** commit `f4029025c2dd4051d1d161a1fdca634252933aa4`, [run 38108103946](https://github.com/dwijayuda/pskernel/actions/runs/38108103946), job `114377796507`: the executable `decide (name ∈ params)` requires `LawfulBEq KName`, because Lean 4.35 list membership's Decidable instance uses `BEq + LawfulBEq`, **not just `DecidableEq`**. This is an architectural correctness contract: the runtime boolean parameter test must agree with logical equality. The fix adds explicitly derived `ReflBEq` and `LawfulBEq` for the recursively structured KName. Do not weaken back to unproved boolean membership. This CI failed before the new proofs compiled; preserve the failed record and qualify the corrected source separately.

**Second G3 proof candidate compile outcome:** source `04a22f71e5ec07043c7f656545a4c2830b1a463d`, [run 38108219462](https://github.com/dwijayuda/pskernel/actions/runs/38108219462), job `114378140064`: `CoreSyntax.lean` compiled with structurally **lawful boolean equality**, but two theorem elaborations in `CoreSyntaxProofs.lean` left a definitional wrapper (`WellFormed (.param name)` / `StructurallyValid (.bvar index)`) unexposed before calling `of_decide_eq_true`. Explicitly `change` the goal to logical membership and binder inequality; no theorem assumption or statement weakening. Test separately in the next pinned cloud run. Previous run failed compilation; no proof success was claimed.

## Fully green G3 structural proof checkpoint — October 11, 2026

**Validated source:** `f767415fc1d1824ae50ab83b73f67e8cd8b21e21`. [GitHub Actions run 38108276674](https://github.com/dwijayuda/pskernel/actions/runs/38108276674), job `114378309523`: **success**. Cloud log: V3 audit passed for **9 independent Lean files**, exact Lean 4.35.0-rc4 at `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`, all **23 build jobs** passed (including `CoreSyntaxProofs.lean`), and G1/G2/G3 smoke tests succeeded. Ground `imax` uses 20×20 numeric cases, not symbolic universe equivalence. See [G3 evidence](G3_EVIDENCE.md).

**Actual theorem scope:** `ULevel.validParams_sound` proves successful executable level-parameter preflight implies logical `WellFormed` (no meta levels / members of declared parameter list), with KName `ReflBEq`/`LawfulBEq` derived to align runtime equality with logical membership. `KExpr.validAt_sound` and `KExpr.closedInput_sound` prove successful executable structural validation implies independent binder and universe well-formedness predicates. These are **structural theorems only**. Constant existence, param arity, typed inference, symbolic DefEq, recursors, quotient, declaration admission, full kernel consistency and runtime proof acceptance are **unimplemented**.

**Next execution directive:** implement G4 only after a precise symbolic universe/typed checked-result contract and versioned negative test matrix; don't reuse the old kernel/proofs as constraints. Avoid claiming completeness by counting syntax constructors. See [G4 checker plan](G4_CHECKER_PLAN.md). All old proof branches and PR #89 remain separate.

## Final G2/G3 evidence checkpoint, October 11, 2026

**Document/evidence manifest commit:** `cc24fabb10e2cea58fadb68c902f26c3f57ae73c`, [GitHub Actions run 38108394736](https://github.com/dwijayuda/pskernel/actions/runs/38108394736), job `114378657293`: **PASS**. Cloud log: audit boundary PASS for **9 independent V3 Lean source files**, exact Lean `v4.35.0-rc4` commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`, **23 native build jobs** successful, G1 representation and G2 three-engine regression tests, generated 92 cases, G3 structural preflight and compiled structural-soundness theorems all passed. Latest toy beta-only timing medians were eager **121 ms**, lazy tree **7 ms**, lazy DAG **7 ms** (five × 5040 samples; not kernel checking performance). Run includes machine-readable G2/G3 evidence and independent G4 checker plan. The run validates **no actual proof acceptance**.

**Implementation completion status:** G1 representation prototype, G2 untyped beta WHNF research and G3 structural Lean 4.35 expression/universe skeleton are complete **in their bounded declared scopes**. G4 symbolic universe equality, typed checking, environment validation, DefEq, recursors/quotients, public admission, complete model soundness, full library replay and JS/Wasm self-host have **not started**. Do not translate a source/build proof into claims of kernel soundness.

This checkpoint is documentation-only; the CI source/evidence SHA above remains the latest **validated** implementation. Continue next with [G4_CHECKER_PLAN.md](G4_CHECKER_PLAN.md), beginning G4.0 symbolic level semantics and an exact official differential negative/positive corpus before any unchecked proof acceptance.

## G4.0 symbolic universe positive-equivalence implementation — candidate, CI pending

On live branch baseline `cd86d76ede52e5af4c452441208d6e4721509bd8`, introduced independent `SymbolicLevel.lean` (total structural normalizer, exact maximum/imax local simplifications, collision-safe *ordering* only, positive-only tri-state compare); `SymbolicLevelProofs.lean` (denotational semantics under ALL symbolic universe assignments, local rewrite preservation, `normalize_denote`, `positiveEquivalent_sound`, `compare_equal_sound`); and oracle-only `SymbolicLevelSmoke.lean` (pinned `Lean.Level.isEquiv` checks as independent test authority, not imported into accepting implementation). This is a soundness-first *subset* of official `level.cpp::normalize` and does NOT pretend unknown/not-normalized is semantically unequal.

The smoke matrix reports both explicit positive cases and the number of official positives not yet recognized. **Cloud proof compilation and all acceptance claims pending.** No full Lean kernel, checked inference or theorem admission has been implemented. Next investigate canonical max flattening/canonical offsets as guided by the official mismatches, maintaining proofs.

**First G4.0 cloud result:** source `e65d807425dc76c6865c5af57b77cd9b34ddefad`, [run 38109048473](https://github.com/dwijayuda/pskernel/actions/runs/38109048473), job `114380582190`: **failed before new proofs ran** at `SymbolicLevel.lean` with a parser complaint on adjacent `deriving instance` declarations. The correction derives `DecidableEq` and `Hashable` as part of the original `ULevel` definition in `CoreSyntax`, removing the redundant declarations from `SymbolicLevel`. This changes representation instance wiring, not semantic rules. Await the next completed workflow before claiming any G4.0 result.

**Second G4.0 CI outcome:** source `c6363e34b18c1cb470c32ea0c32ff69cc55b808c`, [run 38109126100](https://github.com/dwijayuda/pskernel/actions/runs/38109126100), job `114380812279`: the syntax core and G3 proofs compiled, but `SymbolicLevel.lean:25` still failed because a standalone Lean **doc comment** `/-- ... -/` was no longer attached to a declaration after moving deriving instances. This is purely a documentation-command placement error, not an evaluator correctness failure. Removing the dangling comment lets Lean check the actual normalization/proof implementation next. No G4.0 acceptance claimed.

**Third G4.0 CI status:** source `2b7e858d7332fc2fdaa57a2753526a08483ecb14`, [run 38109189710](https://github.com/dwijayuda/pskernel/actions/runs/38109189710), job `114381000942`, **failed in proof elaboration only**. `SymbolicLevel.lean`, `CoreSyntax` and other existing modules built; `SymbolicLevelProofs.lean` uses `split_ifs` which is **not available** in this standalone Lean 4.35 package. The proof implementation is being replaced by standard `by_cases` over literal equalities/order choices and explicit constructor cases. No theorem statement, executable normalization condition or acceptance rule has been weakened. The subsequent CI must validate each case before any positive-universe soundness claim.

**Fourth G4.0 run:** source `40d5ce9173d273e1a3d5c0424bc45de0493c168c`, [run 38109264059](https://github.com/dwijayuda/pskernel/actions/runs/38109264059), job `114381223574`: symbolic normalizer compiled; proof module got through all rewritten cases except `smartIMax_denote`'s zero-left branch, where the simplifier was not unfolding the *denotation of zero* when using the numeric helper lemma. Add `ULevel.denote` to the explicit simplification; do not change the theorem statement or positive equality decision rule. This run did not pass the full build/smoke.

**G4.0 oracle coverage extension — CI pending:** after [first green positive-soundness run 38109322957](https://github.com/dwijayuda/pskernel/actions/runs/38109322957) at source `99613fd0fec6648db9e4ae3823e7ac4a1f11a7d6` (30 build jobs, structural/model proof modules compiled, 27 positive / 0 unresolved official positives in 13-expression matrix), expand the official-Lean comparison to a **36-expression (1,296 ordered pair)** stress set including nested/max-associative, shifted successors, and symbolic imax boundaries. The implementation and positive soundness proof stay exactly the same. The goal is to measure *completeness gaps* before algorithm selection, not pretend all math-valid expressions are recognized. Source commit/run evidence pending.

**G4.0 normalization family upgrade — candidate, CI pending.** The green expanded [run 38109450733](https://github.com/dwijayuda/pskernel/actions/runs/38109450733) at `ae846d141b2f9dc35ea057b4f2cf4323740fd2cc` exercised **1,296 official-Lean comparisons**: 84 recognized equality pairs, zero false-positive pairs, **22 official-positive pairs unresolved**. Source and semantic-proof changes now add full rewrite families `imax 1 x = x` and `succ(max u v) = max(succ u)(succ v)`, each accompanied by a denotational soundness lemma and direct official comparison fixtures. The normalization design remains conservative and independent; numeric valuation sampling is never an equality authority. Cloud validation pending before any resolved-count claim.

**G4.0 rewrite attempt source `98aa314316c493dcfa5f1661a27039c42ad62519`:** [run 38109575642](https://github.com/dwijayuda/pskernel/actions/runs/38109575642), job `114382158655`, failed in Lean proof elaboration after the runtime normalizer compiled. The `Nat.succ_max_succ` proof lemma lives in `Init.Data.Nat.Lemmas` and was not in the proof module's import closure; add explicit import. In the `imax 1 b` branch an earlier `a ≠ b` premise must also be supplied to the simplifier to remove the preceding equality guard. The runtime algorithm and theorems are unchanged. Do not claim a new proven rule until CI is green.

**Second G4.0 rewrite proof attempt:** source `3b127eadbd1bb883e2108a15caf43fd21cf18c41`, [run 38109640349](https://github.com/dwijayuda/pskernel/actions/runs/38109640349), job `114382352575`: only proof compile failed because the new `imax_one_left` lemma referenced `Nat.max_succ_succ` instead of the actual Lean 4.35 lemma `Nat.succ_max_succ` (used already by `smartSucc_denote`). Correct the lemma name; executable normalization and the 4.35 theorem statements are unchanged. No source was promoted while failing.

## G4.0 symbolic soundness and matrix expansion — fully green, October 11, 2026

**Validated executable source:** `4c37b7f4a0cc287dbba77d004dd33ffd6f10dd8b`; [run 38109715920](https://github.com/dwijayuda/pskernel/actions/runs/38109715920), job `114382566956`: **PASS**. V3 independent source fence **12 files**, exact pinned Lean 4.35.0-rc4, **30 native build jobs**, all G1/G2/G3/G4.0 focused tests and repeated toy beta benchmark succeeded. All positive-denotational rewrite and normalized equality theorems compiled. The prior identity rewrite attempt `98aa314` failed because its proof file referenced a nonexistent `Nat.max_succ_succ` lemma; the corrected source uses official `Nat.succ_max_succ` from Lean `Init.Data.Nat.Lemmas` and adds the precise `imax` guard hypothesis.

**G4.0 oracle metrics (same 36-expression / 1296-pair matrix):** before rewrite `ae846d1` yielded 84 positives, 22 official-positive undecided, zero observed positive mismatches; new `4c37b7f` yields **98 positives, 8 undecided, zero observed positive mismatches**. Theorem `compare_equal_sound` proves an affirmative result is Nat-denotationally sound under all symbolic valuations—separate from official algorithmic parity and complete kernel consistency. See [G4_LEVEL_EVIDENCE.md](G4_LEVEL_EVIDENCE.md) and [G4_LEVEL_EVIDENCE.json](G4_LEVEL_EVIDENCE.json). No theorem admission capability was created.
