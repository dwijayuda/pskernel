# M3 direct-recursive DecidableEq — implementation candidate

16 October 2026. **Implementation and focused fixtures are added; exact qualification is pending. M3+B remains OPEN.** This follows the accepted BEq compiler058fb67f; its five green workflows do not qualify this new compiler.

## Stage entry and references

The user's attached stage prompt was reapplied. Fresh branch/CI/both handoffs, v7.2's selected deriving/data/recursion boundary and corresponding pinned sources were reviewed. Sole forward reference: PSCV0_LANGUAGE_REFERENCE_v7.2.md, blob694115223777599ba28ee175e14bb642b7b6aa4b, SHA256c65487eccbd2829d1d9e5e1be3bc7f4cb37849b841ab3257ea0dd47665b8a30e. Native Lean syntax is unchanged.

Official Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc: `src/Lean/Elab/Deriving/DecEq.lean` was studied for constructor matching, actual field decisions, injection/refutation and positive constructor proof transport. `tests/elab/derivingDecidableEq2.lean` covers recursive lists, indexed vectors and mutual trees and also exposes limitations of dependent elimination. Its broader indexed/mutual behavior is not claimed by this narrower slice. No upstream proof hole, recovery or unchecked recursive implementation is adopted.

Local owners reviewed: DerivingDecEq, DerivingContext, Equality's psElabIndexFunction and Eq.rec/congruence builders, and the checked Decision environment. The existing index/projection helper already opens every actual constructor field plus recursive hypothesis and closes the whole telescope. A separate new trusted injection primitive is unnecessary.

## Shared implementation

The field decision plan distinguishes erased proofs, independently checked DecidableEq dictionaries and direct recursive fields. Uniform nonindexed admissibility remains owned by psElabDeriveFieldsWithRecursion, including field independence, parameter/universe alignment, constructor result and exact recursive metadata checks.

Left induction now produces actual hypotheses of type forall right, Decidable (leftChild = right). Each recursive field applies its checked hypothesis to the matching right child. Inner right constructor analysis ignores its own hypotheses. Nonrecursive field decisions come from their independent dictionaries, not BEq or an assumed LawfulBEq instance.

The existing positive proof producer remains: collect field equalities, use dependent-context substitution/transport, then checked reflexivity. Negative decisions use checked homogeneous projection and congruence; different constructors use the existing True/False discriminator with Eq.rec. Proof fields are not runtime comparisons. Later field decisions stay inside the positive branch, retaining evaluation order. No self-instance assumption, source-name shortcut, new axiom, partial helper, backend-specific semantics or erasure change is introduced.

## Focused qualification

Reuse the existing Pscv0M3RecursiveDeriving executable and workflow. The independently compiled native tree derives DecidableEq. Portable source adds four Bool-to-UInt64 observations: Nat/Bool decision masks, actual equality under a deliberately non-reflexive BEq dictionary, and a recursive chain carrying a proof about its recursive child. Closed equal/different rfl equations check the actual decisions. All existing Hashable/Repr/BEq observations and nine refusals remain; three DecidableEq intended-rule refusals cover nested/indexed families and missing field dictionaries. Recursive data stays internal to each runtime.

Portable calls use the already-qualified `Decidable.decide(self := decEq(a, b))` API. The native oracle retains native `decide (a = b)`. These are explicit spellings for the same requested observation, not a new source feature. All eleven exports must pass JS, strict compiled TS, locked Rust, V8 GC and Wasmtime.

One obsolete direct-recursive DecidableEq negative becomes `next: List Bad`, an unsupported nested family. Successful cloud preparation38907346583/job116994153657 verifies originalnativeblob44338bb06e8f633d8b27c6413cbd3c9b5c684979 -> d4cee482039aa24575b476292c42cc30e28f09ff and exact focusedfixtureblobbcdd812511353892c43a3946230db446a5d7d3f6. The native suite's assertion/phase/other cases/budgets are unchanged. The temporary preparation workflow is removed with this candidate. No prepared blob or native-oracle source is counted as an executed compiler qualification.

## Acceptance boundary

Require all five native/F1/F2/F3-F4-platform/focused workflows on one exact candidate commit. Fix any genuine motive, transport, erasure or target defect without weakening proof obligations, case expectations or budgets. Until those results are recorded, this remains a candidate.

Broader nested/indexed/mutual data/deriving, general motives/pattern matrices, total recursion, P0 executable/assurance and P1 fixedpoints remain open. Every partial executable remains refused; no witness execution, logical body equation, Classical/Nonempty fallback or verified downgrade. Approved assumptions remain propext/Quot.sound only. No new speedup is claimed; earlier paired performance evidence and unresolved deep-list paths remain unchanged.
