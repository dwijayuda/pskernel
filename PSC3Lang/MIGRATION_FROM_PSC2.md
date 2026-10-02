# Migration from PSC2 and earlier PSC3 drafts

**Proposed migration policy · v0.7 syntax repair.** [ProofScript v0.7](SYNTAX_AND_GRAMMAR_V07.md) governs syntax/grammar. No compiler or application-source migration was executed by this documentation change.

## 1. Edition and reference boundary

PSC3 is a platform/language iteration whose base surface follows the v0.7 reference; it is not a silent replacement with stock-Lean-only source or newly invented TS grammar. Record platform edition, source-reference version, library profile and extension version separately.

Existing PSC1/PSC2 source keeps its declared meaning. A migrator parses the original grammar and preserves or explicitly transforms the AST and module identity. Global replacement of braces, semicolons or calls is unsafe. The v0.7 adjacent-call discriminator and protected native neighbors remain active, not obsolete. [Reference §§5–10](../study/proofscript-language-reference-v0.7.0/ProofScript_Language_Reference_v0.7.0_authoritative_draft.md)

## 2. Required corrections and retained forms

| Existing source/design | Corrected PSC3 policy | Migration/evidence requirement |
|---|---|---|
| Valid v0.7 `def`, `const`, `function` | Retain canonical definition and both constrained aliases. | Do not force a blanket rewrite to `def`; enforce alias parameter rules. |
| `f(x,y)` | Retain adjacent two-argument curried-call decoration. | Canonical Lean is `f x y`; preserve original meaning. |
| `f((x,y))` / `f (x,y)` | Retain one-tuple semantics and distinct parser ownership. | Never normalize by removing/adding a space without AST knowledge. |
| Registered braced data/match/where syntax | Retain exact v0.7 categories and lowering. | Keep `where`, `with`, separators and native pattern rules. |
| Earlier byte-identical `.ps`/`.lean` proposal | Withdraw; `.ps` lowers to Lean/core, `.lean` stays native. | Check lowered artifacts and source correspondence rather than rename files. |
| Earlier bare function block or TS arrow examples | Not admitted v0.7; rewrite using `:= ...;` and `fun`. | Review source AST; do not call these implemented features. |
| Braced namespaces/sections or ESM source imports | Not admitted replacements; use native commands. | Target ESM export metadata remains a separate build concern. |
| `const x = ...` or record fields using `=` | Use `:=` for binding/definition/update in the proper category. | Preserve propositional equality as `=`. |
| `.some(x)` as a pattern | Use native `.some x`. | Constructor-term/header decoration is not pattern decoration. |
| Experimental intrinsic contracts | Exact supported inherited grammar or ordinary theorem. | Recheck chosen pin/imports/options; no invented repeated clauses or final-proof grammar. |
| Result order inconsistencies | Keep native `Except ε α`; reference-style user `Result α ε` is separately defined. | Do not swap type parameters by name or silently rename data types. |
| Proposed portable Task model | Native Task unchanged; separate `Psc.Async` library. | Runtime model/adapters need evidence, not a keyword rewrite. |
| `.psx` target-specific boundary | Retain explicit boundary; UI is an opt-in versioned dialect. | Do not automatically reinterpret existing `.psx` files as UI or verified `.ps`. |
| TS/Rust/direct JS/direct Wasm strategies | Preserve existing routes and independently gate proposed ones. | No compiler dependency or bootstrap change is implied by this syntax repair. |

## 3. Lean reference and upgrade candidate

The controlling v0.7 reference selects Lean 4.34.0 at `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`. Earlier PSC3 work proposed 4.34.1; retain its source/tag research as an upgrade candidate, not current source authority. Existing runtime/toolchain pins are unchanged.

An actual upgrade requires an explicit reference/profile revision, source/category audit, positive/negative replay, logical checking and runtime conformance. Do not mix prebuilt artifacts from different pins under one identity. A patch number alone establishes no compatibility theorem.

## 4. Specification compatibility

Retain actual program/specification statements or establish the appropriate equivalence/refinement under a reviewed migration plan. Changes to input domains, errors, resources, assumptions or numeric operations are semantic changes even when names stay the same.

Proof-script repair differs from weakening a statement. Report API, behavior, proof and assumption changes separately. When an earlier proposal is underspecified, identify the ambiguity instead of fabricating an equivalence proof to a newly chosen rule.

## 5. Generated source and artifacts

Do not hand-maintain diverging compiler sources while claiming canonical correspondence. The bootstrap implementation subset and public source capability set remain separate.

A `.ps` source may be translated to canonical `.lean` through the v0.7 lowerer. Native source may be printed as `.ps` only using admitted forms with preserved meaning. These are semantic/category-aware transformations, not extension renaming or regex deletion of punctuation.

Hash equality establishes identical bytes, not equivalence between different source programs. Old proof reports are not automatically valid for changed source, runtime or compiler artifacts. Recheck the actual dependency-bound statements and output.

## 6. Rollout

Retain or explicitly migrate legacy profiles where needed. Produce reports listing retained v0.7 syntax, genuine changed semantics, renamed library operations, target restrictions and review items. Build source/canonical examples in their declared environments and replay evidence.

Do not modify active compiler/bootstrap source or merge workstreams merely to apply these documentation corrections. Source/lowering and fixed-point gates remain separate implementation tasks.
