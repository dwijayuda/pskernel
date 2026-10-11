# PSCV0 v7 — Second self-host compiler-source candidate

**Work branch:** psc0/pscv0-compiler-fast-loop-v1. **Status:** experimental source migration with strict compiler-only differential gate, **not promoted** into the shipping compiler source manifest. **Normative language:** solely [PSCV0 v7](../PSCV0_LANGUAGE_REFERENCE.md), no old .ps syntax fallback.

## Source selection

The next source-owner candidate is **Ps.Foundation.List**, original **packages/foundation/src/Ps/Foundation/List.lean** (66 physical lines; 10 definitions). Source candidate **packages/foundation/src-ps/Ps/Foundation/List.ps** expresses the ten identical intended functions using v7 explicit typed parameter groups, nonexplicit binders, comma calls, braced matches and conditional syntax. The first version is a mechanical, conservative transliteration, *not* a claim of fewer lines or improved algorithms. The source is independent of kernel implementation and has no comments that would trigger the existing unfinished trivia-anchoring feature.

The functions are psListLength, psListIsEmpty, psListAny, psListReverseAcc, psListReverse, psListAppend, psListMap, psListMapExcept, psListTake and psListZip. Their implementation contains structural recursion and exact first-error behavior. Replacing the entire family with an unchecked short JavaScript implementation, retaining an older ProofScript parser mode, or rewriting the checker is not permitted.

## Cheap acceptance

The [fast compiler-only differential probe](../tools/abi/foundation-list-probe.mjs) exercises the **same generated PSCV0 JavaScript frontend** and the **same retained original PSC0 compiler** as the previously qualified first-module build. It parses both source kinds intentionally (new v7 ProofScript and old immutable Lean baseline as separate historical source type). It validates the v7 AST against the closed versioned source schema, then passes the reconstructed recipient-owned syntax directly to the retained compiler's unchanged elaboration/preparation path.

Compare exact canonical compiler-admission text, exact TypeScript 7 output and relevant source/target SHA-256 on both sides. Any disagreement is a **real conformance investigation**, not an invitation to weaken expected tests or silently choose the baseline Lean parser for v7 input. Run no independent PSKernel checker in this inexpensive inner loop. The explicit full compiler/checked-assurance gate remains later and has a different source identity.

A green structural/semantic differential establishes only that the selected module preserves those concrete compiler-generated products under that retained toolchain, **not full v7 correctness or a proof of arbitrary source code**. Additional performance/readability refactoring (especially error-return do lowering), multi-module import/provenance and source spans should follow only after initial feature-family acceptance. The historical original Lean source must remain immutable until deliberate source-authority promotion, with fresh full generated bridge and fixed-point evidence.

**Current status when this note was written:** new candidate and probe have been authored; the actual cloud result is not yet observed and must be reported separately in AI_WORK_STATE.
