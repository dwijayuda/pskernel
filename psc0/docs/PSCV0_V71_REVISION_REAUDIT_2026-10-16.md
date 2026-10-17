# PSCV0 v7.1 — iterative revision and final source-consistency re-audit

**Date:** 2026-10-16  
**Repository:** [dwijayuda/pskernel](https://github.com/dwijayuda/pskernel)  
**Branch:** `psc0/pscv0-v7-native-lean-v1`  
**Complete revised reference:** [`psc0/PSCV0_LANGUAGE_REFERENCE_v7.1.md`](../PSCV0_LANGUAGE_REFERENCE_v7.1.md)  
**Exact re-audited document Git blob SHA:** `a109a0a85d0c4fb0976d8b3ee30c331ef8438231`  
**Lean semantic pin:** stable **4.35.0**, Git commit [`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`](https://github.com/leanprover/lean4/commit/eb6cafb7290e8bd5f2937522d8d804f58f02bafc)  
**Status:** source-level revisions and repeated consistency audits completed; **not** an executed compiler, kernel, VC, CI or backend conformance certification.

## 1. Result

The v7.1 reference is again a **standalone**, integrated Markdown language-design document, not a supplement that needs v7 to interpret its normative rules. It retains the original language goals: a selected Lean 4 semantic subset, ergonomic `.ps` syntax, one logical type foundation, ordinary checked output and fail-closed verified output. It selectively admits qualified `partial`, `partial_fixpoint`, and restricted `unsafe` without turning executable bodies into proof authority.

The previous [v7.1 audit](PSCV0_V71_ITERATIVE_CONSISTENCY_AUDIT_2026-10-16.md) identified **seven confirmed document/grammar defects**, **ten semantic/evidence underspecifications**, and **five documentation/fixture-quality items**. This revision addresses the seven confirmed inconsistencies, makes the semantic acceptance requirements explicit, and distinguishes operational implementation work from specification correctness. Some evidence-dependent features remain staged rather than silently declared implemented.

**Latest review outcome:** the last two independent whole-document structural, cross-category, fixture, release-pin and original-v7 compatibility passes found **no additional independently supported defect**. This is a bounded document-audit conclusion, **not a claim of complete language/compiler correctness**.

## 2. Original confirmed defects and applied resolutions

| ID | Original defect | Resolution in revised v7.1 |
|---|---|---|
| C01 | Undefined `selectedModifiers` used in recursion declarations | One selected `psModifiers` + `psFeatureModifier` grammar, with a concrete exclusive modifier matrix; no undefined alias |
| C02 | Competing `psDeclVal` and `partial_fixpoint` suffix grammars, incorrect `where` ownership | Unified body → recursion suffix → optional `where` order, sourced from pinned `Command.declValSimple` and `Termination.suffix` |
| C03 | Staged `psWhilePartial` omitted from selected `psDoItem` | Explicit P2 `psDivergentDoItemP2` selection and separately gated trace verifier |
| C04 | Plain ordinary `while` described as available but not selected by grammar | Explicit base `psWhileOrdinary` without behavioral-correctness claim; verified requests still require adequate proofs |
| C05 | Conflicting `unsafe`, `partial`, and fixed-point combinations not formally rejected | `PSCV0-REC-STRATEGY-01` strategy table and exclusion rules, with negative regression cases |
| C06 | Native contract `f.spec` could be misread as proof of opaque partial/unsafe runtime behavior | `PSCV0-CONTRACT-SCOPE-01` defines separate safe models, checked correspondence and no proof authority from unsafe/opaque bodies |
| C07 | §11 declaration summary omitted owned `psDefDecl` | §11.3 now includes it explicitly; no unrestricted Lean-head escape from selected binder rules |

## 3. Additional issues found during revision and resolved

These were established by reviewing the *revised* document rather than mechanically repeating the prior report.

1. **Duplicate nullable grammatical options.** `psModifiers` and `psContractSeq` were already nullable, but surrounding productions made them optional again. Eliminated the duplicate empty derivations while keeping normal definitions/empty prefixes valid.
2. **Secondary `do` grammar inconsistency.** An intrinsic-effects comparison still listed three do-item arms after the authoritative union adopted four. Aligned all active fragments.
3. **Markdown table grammar escaping.** An initial document transformation inserted unescaped grammar-alternative pipes into five registry rows; an overbroad formatting attempt was detected and corrected by reconstructing from the exact prior revision, touching **only those five rows**. A subsequent full-table scan found no malformed conventional tables.
4. **Unintended v7 language-capability regression for `const`.** The initial new `psConstVal` inadvertently excluded v7's selected **total `psTermination` suffix** for a function-valued `const`. Restored the v7 total strategy, conditional on actual Lean elaboration; new `partial`, `unsafe`, and `partial_fixpoint` strategies are not automatically added to `const`.
5. **Stable-release provenance and explanatory references.** Corrected the stale prerelease description of Lean 4.35.0. Deep versioned reference URLs inaccessible during review were changed to current explanatory chapter links, **explicitly subordinate to the immutable pinned Lean source**; working top-level versioned URLs remain.
6. **Interaction test coverage.** Added phase-specific cross-feature cases for incompatible modifiers/fixpoints, source suffix placement, local definitions, unsafe/partial contracts, divergent loops, approved classical dependencies, target traps, erasure, explicit assurance grades and no silent downgrade.
7. **Assurance-grade ambiguity.** Specified two broad families with three distinguishable identities: ordinary checked, closed verified, and verified with approved disclosed runtime-boundary assumptions.

No production grammar feature was intentionally removed to simplify these repairs.

## 4. Significant semantic decisions retained

- **Soundness boundary:** `partial def` remains opaque in Lean logic. `partial_fixpoint` may establish logically justified equations but does not automatically certify compiled behavior. Theorems do not materialize from runtime typing alone.
- **Only proven verified output:** all required contracts, assumptions, effects, erased-state noninterference, source-model adequacy, runtime representation and backend correspondence obligations must be resolved; otherwise **emit no artifact** under the requested verified identity and never silently downgrade to ordinary.
- **Ordinary versus verified:** explicitly requested ordinary type-checked code remains a **nonbehaviorally-certified** output, consistent with the inherited one-language/two-assurance design. If a project demands behavioral proof for *all* output, it must select a verified-only policy; an ordinary artifact must never be presented as a verified result.
- **Unsafe and external behavior:** an unsafe/foreign implementation requires a separate checked safe model and verified implementation relationship for closed claims. A named approved boundary assumption permits only a **distinct boundary-qualified** result, and can be forbidden by a stricter project policy.
- **Nontermination:** distinguish normal return, typed throw, runtime trap and divergence, plus finite effect traces. Partial correctness alone cannot certify server safety; verify finite-prefix invariants and any explicitly promised liveness/progress.
- **Imported/erased/noncomputable material:** maintain distinct proof/logical, runtime and erased dependency closures. Approved foundational axioms (including classical use when present) must have exact provenance, and computational dependence on proof-only `noncomputable` values must not leak into emitted code.
- **Stable baseline:** use Lean 4.35.0 source at `eb6caf...`, not historical RC4 or moving `/latest/` documentation as the semantic authority.

## 5. Source research grounding

Relevant immutable Lean 4.35.0 reference implementations:

- [Declaration modifiers and contract syntax](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Command.lean)
- [Termination/fixpoint suffix and `where` grammar](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Term.lean)
- [Predefinition recursion strategy dispatch](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/PreDefinition/Main.lean)
- [Partial-fixpoint construction and CCPO/inhabitation](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/PreDefinition/PartialFixpoint/Main.lean)
- [Intrinsic contract theorem elaborator](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/Tactic/Do/Contract.lean)
- [Published Lean 4.35.0 release](https://lean-lang.org/doc/reference/latest/releases/v4.35.0/)

The language reference does not claim its proposed PSCV-only braced source syntax or cross-backend operational model has already been validated as conforming.

## 6. Iterative validation record

| Pass | Review scope | Outcome |
|---|---|---|
| 1 | Read the full v7.1 document and prior audit; compare pinned Lean source | Reconfirmed grammar/contract/root-policy defects before revision |
| 2 | Rebuild declaration/recursion suffix ownership, modifier combinations, contracts and `do` loop categories | Initial grammar/root-problem fixes committed |
| 3 | Recheck cross-section grammar and full Markdown structural integrity | Discovered and resolved registry table-pipe formatting and a stale three-arm `do` comparison |
| 4 | Recheck generated proof semantics, ordinary/verified identities and runtime/axiom/erasure boundaries | Added precise requirements and conformance fixtures; no proof outcomes fabricated |
| 5 | Compare complete revised source with original v7 for accidental capability loss | Found and repaired function-valued `const` total-recursion regression |
| 6 | Full revised-document table/code-fence/fixture/grammar-reference/release-pin scan | Fixed double-nullable modifiers and misleading current-link labels |
| 7 | Full-document cross-reference, baseline source, negative policy and acceptance-corpus re-audit | No further independently supported inconsistency detected |

**Final mechanical checks on the committed document:**

- **3,412 lines**, approximately **351,187 UTF-16 code units** of standalone Markdown.
- **78 fenced-code delimiters**, correctly paired.
- **80 HTML comparison tables**, correctly paired (retained from historical v7; valid Markdown with embedded HTML).
- **66 conventional Markdown tables**, no inconsistent unescaped separator counts in the full-document scan.
- **206 unique positive/negative fixture IDs**, **0 duplicate IDs**; **27 `P-V71-`/`N-V71-` cross-feature cases**.
- No remaining `selectedModifiers`, duplicate-optional `psModifiers?`/`psContractSeq?` paths, obsolete three-arm `do` union, unsupported global `partial` rejection or stale **prerelease** label in active rules.
- Original v7 source retained unchanged; PR #109 remains in the user's development branch.

## 7. Outstanding dependencies — **not new confirmed document contradictions**

**Evidence still required before any claim of a completed/verified language implementation:**

1. A frozen stable Lean/PSCV0 environment and exact approved axiom, instance, notation, tactic, deriving, proof/FFI and runtime dependency manifest.
2. Executable conformance for all relevant grammar/typing/effect/theorem examples and differential testing against stable Lean 4.35.0, including proof terms and mutual/local fixpoints.
3. A proven safe operational interpretation/refinement for arbitrary `partial` bodies where used in verified output, and for any selected unsafe, foreign, host-runtime or substitute implementation.
4. A supported finite-trace effect verification rule for partial/ongoing loops and declared liveness/fairness requirements.
5. Target-specific executable semantics and soundness evidence for relevant JS/TS, Wasm and Rust output, including explicitly modeled/qualified traps, resource constraints, external effects and concurrency.
6. Actual compiler/kernel/CI runs on the **revised v7.1 implementation**, not documentation-only positive/negative fixtures.
7. Optional editorial normalization of retained HTML tables if a pure-Markdown-only documentation style becomes a project requirement. This is **not a language-spec semantic defect**.

The fact that some features are deliberately staged and evidence is pending is recorded candidly; inventing a source-level contradiction from that implementation gap would not improve the specification.

## 8. Stopping statement

After repeated full-document passes, **no further independently supported source-document inconsistency or contradiction was found** in the final reviewed revision. This is a justified stopping point for the present research–revision loop, **not proof that no possible issue exists**. Changes should resume when specific new Lean-source evidence, a failing conformance case, a real implementation discrepancy, or a newly identified internal contradiction warrants them.
