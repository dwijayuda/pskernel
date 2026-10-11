# PSC0 v7 — next readable compiler-source migration candidates

**Source review:** 2026-10-11, source tree inherited at commit `8603f7dcf6af6295335c4e11912a10aac86c85a4` (unchanged 69 qualified old compiler source files). This is *planning based on inspected code*, not a claim of converted sources or a new full self-host fixed point.

## Selection constraints

Only [PSCV0 v7](../PSCV0_LANGUAGE_REFERENCE.md) defines future `.ps` language semantics. The selected portable source subset currently implements bounded `Except do` and preserves full source intent only for the forms it knows. Former PSC1/SH/1 input profiles are historical bootstraps, not a compatibility target. Reusing historical source parser algorithms for explicitly v7-selected constructs is allowed; fallback from rejected v7 code to an old parser is not.

A candidate should be migrated only when (1) its actual source features have portable lowering through the generated previous-stage compiler, (2) named definitions/types/first-error and evaluation-order semantics are preserved, (3) comments/docstrings and meaningful source spans survive, and (4) new source/admission/target evidence is bound to its identity. These requirements are not fulfilled by a native-Lean-only pretty-printer.

## Inspected source inventory

| Existing module | Current physical lines | Explicit `def` declarations | Observed implementation constraints | Priority |
|---|---:|---:|---|---|
| `Ps.Syntax.Translate.lean` | 63 | 4 | Four nested `Except` propagation APIs; already replaced by a 40-line candidate `Translate.ps`; no original comment lines | **M1, first candidate already underway** |
| `Ps.Foundation.List.lean` | 66 | 10 | Small no-comment generic traversal/recursion library; old self-host recursive helper patterns still need semantic validation under v7 | Small/no-comment **second-module feasibility study**, not automatic promotion |
| `Ps.Compiler.Api.lean` | 321 | 27 | Numerous nested error propagation and API orchestration branches, about eight full-line comments; bounded `Except do` is high-value but needs comment anchoring | **High-value M2** after comment/source-span support |
| `Ps.Syntax.PrintLean.lean` | 732 | 24 | Large formatter with repetitive `Except` propagation and recursive printers; high regression risk for source grouping and canonical output | Follow-on after smaller pure traversal and type-printing cases |
| `Ps.Elab.Term.lean` | 3,155 | 127 | Deep typed elaboration, expected-type handling and recursion/pattern edge cases; too large for first iterative migration | Later, after representative source and semantic fixtures |

*Counts above are measured from the inspected source text, not equivalent compiler-complexity scores. The `Except` patterns are not necessarily independent branches, and source-length reduction is not a semantic-correctness argument.*

## Cheapest next work after current candidate

1. **Complete M1 rather than accumulating unqualified source.** Require a generated 20-module bridge containing the actual `Translate.ps`, successful generated JS tests and Windows/RC4 checks. A passing 19-module predecessor bridge is not a substitute.
2. **Measure a tiny independent module before broad automation.** Try `Foundation.List` under a narrow source-only read/print/lower gate without changing the shipping compiler source manifest. If its recursion/match lowering is unsupported, keep the specific refusal and implement the minimum reusable typed capability—not a private compatibility dialect.
3. **Implement source trivia and origins as first-class syntax representation.** `PsPscv0ReplayOriginal` already preserves full source, but canonical formatting with comments intentionally returns `PSCV0-TRIVIA-PRINT-PENDING`. Do not delete comments or claim two-way authoritative conversion until anchors exist. Same for source diagnostics currently pointing into generated lowered Lean.
4. **Target `Ps.Compiler.Api` as the first high-value multi-function rewrite.** It has many semantically straightforward `Except` bind chains, but review recovery/error-construction, evaluation order, and concrete API types function by function. Avoid a blind replacement of every `match` into `do`.
5. **Use `Ps.Syntax.PrintLean` for a *family-wide* traversal/printing refactor later.** Reuse existing pure helper(s), preserve first failure, names, syntax ownership and source identity; compare generated Lean/PS printers and canonical admissions under actual typed fixtures.
6. **Keep metatheory and kernel changes independent.** Small source syntax sugar belongs in `syntax` and `elab`; the kernel admission API and checker authority remain unchanged.

## Release/nonclaim register

No new package split, runtime checker change, kernel proof, broad v7 language conformance, verified target output, installed-source fixed point or main branch merge follows from this feasibility ranking. The new v7 Standard environment registry/digest, exported module interfaces, `Std.WP` contract semantics and P1 effect registrations still require actual pinned RC4 differentiation.
