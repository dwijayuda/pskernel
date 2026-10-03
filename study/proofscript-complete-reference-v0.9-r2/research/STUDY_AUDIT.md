# Coverage, adaptation and evidence audit

**3 October 2026.** This records content processing and bounded validation, not a compiler or soundness certificate.

## Exact inputs

Repository `dwijayuda/pskernel`, source commit `65369c75c7b63124f1ba7f2289e573181db281f0`, reference subtree `fb6add969b65756fb656780690c8153f4c524a8f`. The existing cache was re-read and each of the 222 selected HTML files was verified using the Git blob SHA-1 construction. Source material was previously retrieved through the authorized repository workflow; this pass did not infer unseen pages from headings alone.

The root mirror reports upstream manual commit `3558cf290c8c5f832ddd0dbaf807c0c03ad22bd0`; its introduction says Lean 4.34.0-rc2. The stable semantic authority remains Lean 4.34.0 at `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`. See LEAN_4_34_STABLE_DELTA.md. This is not a complete rc2-to-stable API equivalence audit.

The approved v0.9-r2 reference attachment has SHA-256 `d29c0b2d5780e6cdb08a4c9ac00cc7442a64b1c8133b51c5f0c0e9a343b11b8d`. This collection does not revise that grammar.

## Coverage

| Measure | Count | Meaning |
|---|---:|---|
| Mirrored HTML paths | 222 | Every path represented in COVERAGE.json. |
| Substantive reference articles | 218 | Full article content adapted, not only a heading map. |
| Nonarticle paths | 4 | Identical upstream Page not found placeholders; no invented text. |
| Source headings | 1591 | Headings retained from substantive articles. |
| Named reference blocks | 3661 | API/syntax/tactic reference entries, including repeated documentation. |
| Distinct extracted named API identifiers | 3016 | Not a claim of implemented compiler features. |
| Source code/signature displays | 7885 | Not 7885 runnable standalone tests. |
| Grammar annotations retained separately | 317 | Tooltip text removed from grammar productions, then preserved as explanatory displays. |
| Native diagnostic displays | 650 | Historical/source output, not newly executed outcomes. |
| Native proof-state displays | 826 | Separated from program text. |
| Source diagrams | 8 | Retained as sanitized SVG, with original native meaning. |
| Source editor screenshots | 3 | Retrieved and Git-blob-verified; no relabeling as PSC editor evidence. |

Four placeholder paths: `const-ABC.html`, `const-Array.html`, `const-List.html`, and `const-Std.Iter.html`. All have blob `04b53ab9f45a9a12e803f15ab660a9bb9d252035`.

## Authorship and transformation

The writing guidance is newly authored for ProofScript. The detailed article bodies are an attributed Apache-2.0 adaptation of the Lean manual, not a claim to have independently rewritten or re-proved every paragraph. Native names, signatures, grammar, toolchain commands, historical releases and intentional failures retain their identity.

All articles were structurally extracted and reviewed for coverage. Close semantic review focused on category boundaries, layout/semicolons, calls and binders, dependent data, proofs, effects, runtime/foreign distinctions and the stable-pin conflict. An automated complete extraction is not the same as independent line-by-line semantic auditing of every API entry.

The presentation pass changed only suitable definition-head keywords to const/function in 444 occurrences across 369 blocks. It skipped quoted syntax and unsupported headers. PRESENTATION_EDITS.json retains the original/candidate text, hashes and exact edits. Every edit sequence was reversed and checked for exact text recovery. This is an integrity test, not a general parser, hygiene or semantic-preservation proof. Other native examples remain inherited notation.

Decorative navigation, duplicate narrow-screen signature copies and tooltip wrappers were removed. Grammar tooltip prose, messages and proof states were preserved separately so they cannot masquerade as source tokens. Original token anchors were retained around code blocks; the anchor audit reports any article-level fallback locations. Website JavaScript and font files are not redistributed. Mathematical source notation is retained without importing the original website runtime.

## Actual native execution



```text
Lean (version 4.34.0, x86_64-w64-windows-gnu, commit 293d5d0c0c3f3dded4688b3ccd6a33939ac5102b, Release)
```


A newly authored canonical Lean file containing 18 theorem declarations was accepted. Six negative fixtures were rejected: false proof, invalid dependent update, extra top-level semicolon, numeric truthiness, tuple arity and a tactic sequence leaving a goal open. All seven file-level outcomes matched their expectations.

The printed axiom dependencies are retained in NATIVE_TEST_RESULTS.json: equalityChain depends on propext, Classical.choice and Quot.sound; totalExample depends on propext. Do not relabel these as assumption-free proofs. The new examples did not run a production PSC parser, lowerer, independent kernel or target backend.

## Limitations

No all-library closure proof, full snippet execution, frontend equivalence, kernel implementation theorem, runtime equivalence or app-readiness result is claimed. Some inherited examples are deliberately erroneous or require their original context. Some old descriptions are superseded by the stable pin. The source mirror has genuine missing pages. A standalone compiler must reject unsupported capabilities; this complete documentation inventory does not enlarge its accepted subset.
