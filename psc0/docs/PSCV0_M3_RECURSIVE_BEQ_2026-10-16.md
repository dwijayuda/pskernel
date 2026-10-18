# M3 direct-recursive BEq — implementation candidate

16 October 2026. **Implementation and focused fixtures added; exact qualification is pending. M3+B remains OPEN.** Base is accepted Repr compiler4501164e / documentationad47b42f. The v7.2 stage-entry prompt was reapplied; accepted M2, runtime, partial-logical, Hashable and Repr work is preserved.

## Reference and scope

Sole forward `.ps` reference: PSCV0_LANGUAGE_REFERENCE_v7.2.md, blob694115223777599ba28ee175e14bb642b7b6aa4b / SHA256c65487eccbd2829d1d9e5e1be3bc7f4cb37849b841ab3257ea0dd47665b8a30e. Selected deriving is governed by PSCV0-DERIVE-01 and the existing data/recursion rules. No old grammar mode or change to host `.lean` semantics.

Studied pinned Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc `src/Lean/Elab/Deriving/BEq.lean`, especially mkMatchOld/mkMatchNew: matching constructors, recursive child comparison, independent field dictionaries, proof skipping and field-order conjunction. `tests/elab/3740.lean` demonstrates upstream dependent fields; it is evidence of a broader upstream capability, not a claim that this narrower slice supports it. The upstream partial fallback and dependent-field transport are not copied into this slice.

PSC0 owners inspected: DerivingBEq, shared DerivingContext/Hashable, Meta.Recursor, Erasure.Recursion and the recursor/minor handling in Erasure.Expr. Existing checked induction validates the motive, constructor result and each child hypothesis. The candidate reuses those checks without changing the Core theory, recursor metadata, erasure, ABI or backends.

## Implementation

A field plan now distinguishes erased proof fields, independently resolved comparison dictionaries, and direct recursive fields. This avoids overloading a missing dictionary as recursion. The family is validated completely before constructing the method; only uniform nonindexed direct recursion is enabled.

The left recursor has result family -> Bool. Its child hypotheses therefore compare the corresponding left child against a supplied right value. The right recursor is case analysis: its child hypotheses are deliberately unused. Comparisons consume the checked left hypotheses by fresh field ID and apply them to matching right children. Different constructors return false. Independent fields use their actual BEq dictionary, not pointer identity or a LawfulBEq assumption. Structures retain direct projections. Source field order and proof skipping are unchanged.

The existing preparation/erasure hypothesis-use boundary must qualify on the actual generated program. Logical success alone must not be promoted into a runtime claim, nor should an unused right hypothesis cause an unintended extra traversal. No source-name optimization or backend-specific equality implementation is added.

## Focused evidence required

Reuse Pscv0M3RecursiveDeriving and its existing workflow rather than adding a test executable. The native oracle derives BEq independently on the existing universe-polymorphic binary tree. Two Bool-selected Nat/Bool comparison masks check equal structures, deep-right changes, left changes and constructor mismatch in both directions. A non-reflexive field dictionary checks that recursive BEq does not assume reflexivity or substitute pointer equality. A source `rfl` theorem checks the recursive constructor equation.

Existing Hashable/Repr observations and six refusals remain. Three BEq refusals cover unsupported nested/indexed families and missing independent field dictionaries, requiring the exact elaboration rule. The VM driver only adds the three equality exports to the existing exact Bool-to-UInt64 ABI checks. All JS/strict TS/Rust/V8 GC/Wasmtime lanes remain mandatory; original timings, checksums, budgets and pins are unchanged.

Do not call this qualified until the candidate's native, F1, F2, F3/F4/platform and focused deriving workflows pass and their exact receipts are recorded. Recursive DecidableEq, nested/indexed/mutual data, general elimination/patterns, total recursion, P0 executable assurance and P1 fixedpoints remain open. Every partial executable still fails shared admission. No new speedup or general preservation theorem is claimed.
