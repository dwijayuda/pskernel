# PSKernel-C0 — Phase B nested-inductive reduction architecture

## 2026-10-15 — General app/right-lambda eta defect and requalification

**Native-fixed at [6a1f7898](https://github.com/dwijayuda/pskernel/commit/6a1f7898811aaa60b7d3189eb8b56e05ef5ae390)**, [full native CI 38641430078](https://github.com/dwijayuda/pskernel/actions/runs/38641430078) success with 58 passes, zero failures. Actual pinned [Init diagnostic 38639778343](https://github.com/dwijayuda/pskernel/actions/runs/38639778343) confirms official Lean accepts 86,383 records; C0 at the earlier source differed only on Eq's two app/function vs λ η-expanded arguments, NOT the Pi type or Eq head. `Checker/DefEq/FullShape.lean` was missing a source algorithmic η-right dispatch on left applications. The new general rule follows official Lean 4.35 after application congruence; regression checks local-function η, reverse comparison, unrelated functions and verified source checking. No theorem special case, unchecked equality or new trusted assumption.

**The current exact 86,383-record C0 acceptance survey is a distinct, mandatory gate, not yet claimed here.** [8d38b00d](https://github.com/dwijayuda/pskernel/commit/8d38b00d3a4568de93b08cf3b58420b9a5084631) requires a *positive* C0 verdict on the same official 4.35 source bytes with 4096 fuel, independent of the optional full-file diagnostic. Do not increase the source acceptance count until that gate passes; incomplete/unsupported/resource outcomes never count as rejection or acceptance. Later actual Init/Std/Mathlib, whole-library performance and independent metatheory remain open.


## Verified superseding checkpoint — 2026-10-13

The nested performance bottleneck described below **has been resolved in the current source**. [Native CI 38383818618](https://github.com/dwijayuda/pskernel/actions/runs/38383818618) and [real Init CI 38383848731](https://github.com/dwijayuda/pskernel/actions/runs/38383848731) passed on the precise pinned 4.35.0 exporter and checker. C0 accepted the **79,416-record** real `Init` prefix including `Lean.Syntax` using default 4,096 fuel. The general correction recognizes a checked irreducible inductive head after at most one valid delta step; it keeps target-bearing, unknown and longer reducible chains on the full original checking route. Exported recursors remain subject to independently generated exact metadata checks, never trusted as axioms.

The next real corpus divergence is at **record 86,383**, theorem `Std.PRange.UpwardEnumerable.succMany?_add`: C0 returns `application type mismatch`, while official Lean accepts. Both C0's wide-application optimization and its historical syntax-directed checking reject the proof under the same source session; [diagnostic CI 38393365781](https://github.com/dwijayuda/pskernel/actions/runs/38393365781) qualified that distinction. The current investigation is therefore shared type inference, definitional equality and recursor semantics. Phase B is still **incomplete**, and no full `Init`, Std, or Mathlib C0 acceptance has been established.

The older nested bottleneck descriptions below are retained as historical root-cause evidence, not current blocking status.

**Status:** engineering investigation, **not Phase B acceptance**  
**Target:** native Lean 4.35.0 (`leanprover/lean4:v4.35.0`)  
**Scope:** C0's checked importer, inference, WHNF and inductive admission only. No original `pskernel-core`, compiler, Rust, self-hosting or metatheory changes.

## Verified source baseline

- The pinned `lean4export` output for real `Init` and transitive dependencies is 345,690,182 bytes, 6,452,982 NDJSON records, SHA256 `c1b2071a6d2132ace8c4711499f078aab2117d925213d5a222a1fe843a59a179`.
- Official stable Lean `leanchecker --from-export` accepts the exact source. This is **not** evidence that C0 accepts all 57,919 declarations.
- C0 accepts the first **12,244** real records, including `Functor`, since the source-level correction to distribute `succ^k (max a b)` across the branches of the maximum ([source commit `ee6bdd3f`](https://github.com/dwijayuda/pskernel/commit/ee6bdd3f12636cdd357d00c5b951cbc42db6d65d)).
- At record **79,416**, `Lean.Syntax` is the first nested-inductive group in real `Init`. Upstream accepts it; native C0's flattened mutual-inductive constructor analysis has exhausted the reduction budget at **4,096, 16,384, and 65,536** fuel. Larger fuel alone has therefore **not** qualified the implementation.
- The current native C0 stage diagnostics attribute the exhaustion to the **transformed mutual-inductive constructor field** family. The progressive typed labels separate whole constructor admission, field WHNF, field-domain checking, sort checking and recursive-argument analysis. Each new diagnosis must be confirmed by its own matching CI run.

## Soundness and compatibility constraints

The trusted acceptance operation remains the native checker. Exported constructors and recursors are **never admitted as axioms**. Every emitted inductive, constructor, recursor type, parameter, index, and computation rule must match independently constructed checked metadata.

Lean 4.35 `src/kernel/inductive.cpp` checks constructor fields with `ensure_type` and `check_positivity`. The latter normalizes the argument domain, tests occurrences of freshly introduced inductives, and handles `Pi` and valid recursive applications. Any shortcut that avoids this normalization needs an explicit proof that no recursive occurrence can emerge through `delta`, `beta`, `zeta`, local values, or a known recursor computation in its supported source subset. A syntactic absence of the target name alone is **not yet a qualified justification** for weakening this procedure.

Lean `src/kernel/level.cpp` is the source-of-truth for universe constraints; the correction for max successor offsets must not be reverted.

Resource exhaustion is a typed **inconclusive computational limit**, never a negative theorem result, and is distinct from unsupported input and rejection of a malformed proof. Diagnostic wrappers preserve the underlying typed resource class. No amount of retrying with an increasing fuel figure counts as correctness evidence.

## Root-cause isolation sequence

1. Determine the first failing constructor and stage under a fixed reproducible real prefix. Preserve the environment prefix and exact failed exported declaration bytes.
2. If WHNF: identify whether the budget is spent in a repeating delta/WHNF cycle, unfolding an unchanged head, beta-substitution explosion, redundant application-spine reconstruction, or resource-charged traversal of already weak-head-normal source. Compare against official Lean's reduction ordering.
3. If field inference: examine the checked application path, Pi instantiation, local environment, and repeated type inference on the same expression under the same immutable semantic context.
4. If recursive analysis: verify that detection of direct inductive applications, nested transformations and positivity checks is complete and uses the same normalized domain as the official kernel.
5. Choose one general correction for the entire family, not a `Lean.Syntax` special case. Preserve exact rejection and resource outcomes on negative as well as accepted input.
6. Re-run the actual first 79,416 records, followed by the whole official `Init` stream. Qualify dependent Std/Mathlib export only after native `Init` acceptance and reproducible resource bounds.

## Architecture candidates

**A. Existing immutable checked expression engine.** Improve memoization and structural sharing inside a single checked session, but never blindly carry WHNF/DefEq caches across environment extensions: provisional mutually declared constants may change reducibility or recursor availability.

**B. Indexed two-lifetime term arena.** Only promote an indexed execution path after canonical source/target denotation, handle provenance, cache invalidation, fuel and checker-error equivalence are established. Existing verified root promotion is a syntax test, **not** a checked verdict.

**C. Closure/value WHNF engine.** Evaluate delayed beta and local bindings with shareable closures and a stable head/spine machine; reify into kernel expressions only at the checked boundary. Derive semantic equivalence, resource policy, and regression obligations before integrating into the acceptance authority.

Candidates must be compared on identical complete checked workloads, not syntax-only microbenchmarks. Report p50/p95, wall time, allocation events/bytes, peak memory, and resource exhaustion separately; never infer broad competitiveness from one synthetic batch.

## Explicit phase exit conditions

- All supported exact same-byte positive/negative official fixtures agree, and *no false acceptance* is permitted.
- `Init` (57,919 declarations) is independently accepted by **C0** on the pinned export; optional rejections, malformed inputs and resource failures do not count as acceptance.
- A tested strategy exists for Quot and ordinary, mutual and nested families, including generated recursor exactness.
- Proper resource and error classification is retained on all paths.
- Later real Std/Mathlib compatibility work is qualified separately.
- No compilation artifact or checked proof receipt is emitted from unresolved unsupported/failed source.

**Current verdict: Phase B remains incomplete until these gates pass.**
