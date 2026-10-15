# PSCV0 v7.2 — iterative language-reference research and consistency audit

**Date:** October 16, 2026  
**Repository:** [dwijayuda/pskernel](https://github.com/dwijayuda/pskernel)  
**Branch:** `psc0/pscv0-v7-native-lean-v1`  
**Current standalone reference:** [`psc0/PSCV0_LANGUAGE_REFERENCE_v7.2.md`](../PSCV0_LANGUAGE_REFERENCE_v7.2.md)  
**Audited reference Git blob SHA:** `694115223777599ba28ee175e14bb642b7b6aa4b`  
**Baseline (preserved):** [v7.1](../PSCV0_LANGUAGE_REFERENCE_v7.1.md), blob `a109a0a85d0c4fb0976d8b3ee30c331ef8438231`  
**Normative upstream source:** **Lean 4.35.0**, commit [`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`](https://github.com/leanprover/lean4/commit/eb6cafb7290e8bd5f2937522d8d804f58f02bafc).  
**Evidence classification:** completed **documentation and pinned-source review**, not executed Lean/PSC0 conformance, kernel validation, formal backend simulation or CI acceptance.

## Executive outcome

A new, complete and standalone v7.2 Markdown edition is committed while v7.1, v7, and the existing Git history remain intact. The review found **two genuine documentation/grammar inconsistencies** requiring source-text correction and a **document presentation/traceability improvement** justified by the preference for usable Markdown.

- **Confirmed D01 (normative-versus-historical grammar statement):** historical v3 commentary still stated that all current declaration-value variants used `psTermination?`, contradicting v7.1's active function `psRecursionSuffix` (total `psTermination` or proof-friendly `partial_fixpoint`) and its distinct total-only `psConstVal`.
- **Confirmed D02 (schematic grammar-category ownership):** several older `do` examples defined the whole `psDoItem` as a small fragment, and one used an undefined `selectedLeanDoItem` placeholder. The active grammar has the explicit four-arm union `psBaseDoItem | psVerifiedDoItemP0 | psStagedDoItemP1 | psDivergentDoItemP2`.
- **Editorial improvement (not a language defect):** 80 paired HTML tables and 14 additional comparison tables with HTML preformatted cells were converted into copyable, labelled Markdown fenced code examples. The two remaining preformatted fixture cells and three HTML `code` cells were also converted. Their sample source contents were preserved except for the four intentionally corrected `do` grammar fragments.

**Stopping outcome:** After two further whole-document passes and pinned-Lean cross-checks, **no additional independently supported specification inconsistency was found**. This is a bounded source/document claim, **not** a claim that the language, compiler, proof checker, runtime or backends are complete or flawless.

## Pass 1 — baseline and exact Lean 4.35.0 implementation

Confirmed the branch's active v7.1 source, prior [v7.1 revision re-audit](PSCV0_V71_REVISION_REAUDIT_2026-10-16.md), and the stable source commit, without changing the original reference or trusting a moving Lean documentation page for normative semantics.

| Pinned authoritative source | Cross-checked invariant | Reference consequence |
|---|---|---|
| [`src/Lean/Parser/Command.lean`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Command.lean#L94-L121) | Declaration modifier ordering and special `unsafe`/`partial` heads | Keep PSCV's finite, explicitly more restrictive modifier strategy matrix |
| [`Command.declValSimple`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Command.lean#L188-L205) | Body → termination/fixpoint suffix → optional `where` | Function `psRecursionSuffix` and separate total-only `psConstVal` stay in the correct positions |
| [`src/Lean/Parser/Term.lean`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Term.lean#L620-L709) | `partial_fixpoint` is a suffix, not a prefix or proof hole | Require its checked construction and permitted equations, not an unrestricted recursion theorem |
| [`PreDefinition/Main.lean`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/PreDefinition/Main.lean#L298-L337) | Unsafe, opaque partial, and checked fixed-point recursion take distinct elaboration paths | Reject conflicting source strategies and keep verified-behavior obligations independent of typing |
| [`PartialFixpoint/Main.lean`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/PreDefinition/PartialFixpoint/Main.lean#L76-L112) | CCPO/inhabitation and possible `Classical.ofNonempty` fallback | Require approved logical-axiom closure and checked monotonicity/equations |
| [`Contract.lean`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/Tactic/Do/Contract.lean#L86-L154) | Native contracts generate a separate checked `f.spec` theorem | A generated logical theorem alone does not certify an opaque partial or unsafe runtime implementation |
| [`src/Lean/Parser/Do.lean`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Do.lean#L188-L216) and [loop parser](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Do.lean#L333-L337) | Native loop syntax selects optional invariant/decreasing forms | Preserve distinct ordinary typed, total verified, and separately staged trace-verified `while` forms |

No change to Lean's kernel or type theory was introduced by this document revision.

## Pass 2 — finding D01: historical grammar comment contradicts active source

**Evidence:** In original v7.1, §14.3A C04 said the *current* grammar had three occurrences of `psTermination?`. But §0B, §2 and §5 actually used `psDeclVal ::= ":=" psDeclTerm psRecursionSuffix? psWhere?` for selected function declarations and `psConstVal ::= ":=" psDeclTerm psTermination? psWhere?` for `const`. That language-correctness distinction was introduced after the v3 erratum; the historical comment was stale.

**Resolution:** The v7.2 C04/C05 notes are expressly historical and now cross-reference the **actual** active grammar without introducing a new parser category. The earlier `const` total-recursion capability is retained. This resolves the contradiction without silently admitting `partial_fixpoint` on `const` or reducing function expressivity.

**Why the distinction matters:** `partial_fixpoint` can generate checked logical equations under permitted monotonicity/axiom assumptions, whereas ordinary `termination_by` proves total recursion. Treating the two as interchangeable would confuse typing, proof search and runtime guarantees.

## Pass 3 — finding D02: non-authoritative `do` examples looked authoritative

**Evidence:** Previous v7.1 sections illustrated base `let`/bind syntax, mutable assignment and formal `assert` by writing standalone `psDoItem ::= ...` productions. One said `psDoItem ::= "assert" term | selectedLeanDoItem`, but `selectedLeanDoItem` had no defined closed source selection. Read in isolation these sketches could override or broaden the declared four-arm grammar.

**Resolution:** All four misleading sketches now name the owned arm they illustrate: `psBaseDoItem` or `psVerifiedDoItemP0`. The exact `psDoItem` union remains defined in §0B, §7B and §11.7, with:
- ordinary typed `while` in the base arm;
- proof-capable mutable state, total loops and checked assertions in P0;
- typed errors under P1 environment registration;
- invariant-only potentially divergent loops only under the separately justified P2 trace model.

**No behavioral change:** Nothing previously forbidden is unbanned by this naming correction; a verified request with open obligations still emits no artifact.

## Pass 4 — standalone Markdown conversion and source-code preservation

The original v7.1 had **80 raw HTML comparison tables**, **14 Markdown tables containing paired HTML-preformatted example rows**, two multiline acceptance-case HTML preformatted cells, and three inline HTML code cells.

The v7.2 document now provides the comparison content using explicit Markdown labels and `lean`, `proofscript`, or `text` fenced source blocks. The conversion was validated against the original code segments (including numeric/quoted HTML entities), and all original source examples are still present **except four schematic grammar fragments intentionally corrected for D02**. These four edits are explicitly documented rather than incorrectly reported as byte-for-byte unchanged code.

All original **206** positive/negative fixture IDs were retained with identical order and no duplicates. Existing intentional user choices (call punctuation, native proof language, one selected braced-body convention, type foundations and module visibility) were not redesigned for formatting convenience.

## Pass 5 — full revised-document structural and reference audit

The final post-edit full-document scan checked:

- Fenced code delimiter pairing; ordinary Markdown table column counts; all former HTML presentation tags outside code fences; heading and version markers.
- All 206 acceptance/rejection fixture IDs and their order against v7.1.
- Selected recursion modifier/suffix rules; `const` totality; the four `do` arms; grammar-category ownership; `partial_fixpoint` proof dependencies; `unsafe` model/implementation correspondence; contract admission; loop totality versus finite-trace safety.
- Rejected proof holes, `sorryAx`, disallowed source axioms and computational noncomputable dependencies.
- Assurance-grade distinction (ordinary, closed verified, qualified verified), no downgrade when a verified build fails, and explicit target-specific behavior/refinement requirements.
- Stable Lean pin and the separation of pinned source from moving explanatory documentation links.

**Measured document checks for the final reference:**

| Check | Result |
|---|---|
| Full document | **4,348 lines**; approx. **337,022 UTF-16 code units** |
| Fenced Markdown code | **476 delimiters**, correctly paired |
| Conventional Markdown tables | **52**, no column-count discrepancies in the independent whole-document scan |
| Raw HTML presentation tags outside code blocks | **0** |
| Fixture IDs | **206 distinct IDs**, **0 duplicates or deletions** |
| Lean semantic pin | Exact commit **eb6cafb7290e8bd5f2937522d8d804f58f02bafc** |
| Stale `selectedModifiers`, `selectedLeanDoItem`, obsolete three-arm root grammar or prerelease label | **0 active occurrences** |
| Executable Lean/PSC0/kernel/CI conformance tests during this documentation task | **Not run**; no passing evidence claimed |

## Pass 6 — independent reanalysis after correcting D02

Re-ran the complete Markdown table, code-fence, fixture-identity and active-rule checks **after** the category corrections. Independently re-read the relevant stable Lean 4.35.0 parser, recursion dispatcher, contract elaborator and `do` parser and verified that the normative v7.2 distinctions continue to match their roles.

**Result:** no further *independently supported* language-reference contradiction or specification defect was found in this bounded documentation review. Historical errata marked as historical, intentional smaller source subsets, and staged P1/P2 capabilities were **not** converted into manufactured problems.

## Significant preserved design and assurance choices

1. **Only verified evidence licenses a verified artifact.** Mandatory coverage, proof terms, assumptions, frame/effects, erasure, operational modeling and target correspondence must be resolved; no fallback to ordinary output.
2. **Ordinary programs remain a separate explicitly requested outcome**, type-checked and subject to proof-hole closure but not represented as behaviorally certified. If a project requires behavioral proof before **any** executable, it must choose an enforced verified-only build policy, not relabel ordinary output.
3. **`partial def` stays logically opaque.** An executable-body refinement proof is required for claims about its actual behavior.
4. **`partial_fixpoint` establishes only the appropriate logical construction.** Generated equations do not by themselves prove termination, returned values for diverging executions, runtime adequacy or FFI behavior.
5. **Unsafe/foreign operations remain explicitly modeled trust boundaries.** A closed assurance identity requires actual implementation-refinement evidence. An approved external assumption, when the policy permits it, produces only a separate disclosed boundary-qualified identity.
6. **Potential nontermination is compatible with formal verification**, but partial correctness of returned values does not replace finite-prefix safety or explicitly promised progress/fairness proofs.
7. **The original selected language capabilities are preserved:** no new logic, unchecked casts, arbitrary user axioms, proof-hole acceptance, alternative `.ps` grammar mode or relaxation of original Lean-fidelity constraints.

## Unresolved items — implementation/evidence dependencies, not newly confirmed textual contradictions

These remain independently necessary before declaring PSCV0 v7.2 *implemented* or a closed-end-to-end verified compiler:

- Freeze and audit the Lean 4.35.0 source/environment, imported axiom/instance/tactic/deriving identities, verified-effect model and runtime replacement manifests with actual digests.
- Execute the language's complete positive/negative source fixtures under PSC0 and the pinned Lean parser/elaborator/kernel, including multi-file contracts, mutual/local recursion, and proof-hole rejection.
- Specify and prove a safe operational/trace interpretation and body-refinement path for certified opaque partial functions, registered unsafe functions and foreign implementation boundaries.
- Implement and validate trace-based `while` invariants and any promised liveness/fairness under a precisely scoped environmental model.
- Establish or accurately qualify target-specific backend semantics and proof obligations for JS, TypeScript, Wasm and Rust (including traps, stack exhaustion, error paths, concurrency and host/FFI effects).
- Validate erased-state noninterference, distinct ordinary/closed/qualified output identities, assumption closure and exact fail-closed artifact-emission behavior in CI.
- Mark unrun examples as **design fixtures** rather than passing acceptance cases.

These are not reasons to invent further documentary defects. They are explicit and testable implementation requirements.

## Stopping statement

The research–revision–reanalysis loop stopped after repeated full-reference passes yielded **no additional genuine, independently supported issue**. That conclusion is bounded by the evidence inspected: document text, immutable Lean 4.35.0 source, code-example preservation, consistency and fixture checks. It does **not** establish exhaustive absence of defects, formal completeness, compiler correctness, or successful independent verification.
