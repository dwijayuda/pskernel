# M3 direct-recursive DecidableEq — candidate and fixture correction

16 October 2026. **Implementation is awaiting exact qualification. M3+B remains OPEN.** Accepted BEq compiler058fb67f and its five green workflows do not qualify this new compiler. This record supersedes the invalid proof-field example in the first candidate design; the original candidate and failure remain in Git history.

## Stage entry and references

The attached stage prompt was reapplied, including fresh HEAD/CI/both handoffs and corresponding pinned sources. Sole forward `.ps` reference: PSCV0_LANGUAGE_REFERENCE_v7.2.md, blob694115223777599ba28ee175e14bb642b7b6aa4b, SHA256c65487eccbd2829d1d9e5e1be3bc7f4cb37849b841ab3257ea0dd47665b8a30e. No legacy modes or changes to native Lean grammar.

Studied official Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc `src/Lean/Elab/Deriving/DecEq.lean` for constructor matching, recursive/independent field decisions, injection/refutation and positive proof transport. `tests/elab/derivingDecidableEq2.lean` covers recursive lists, indexed vectors and mutual trees and documents dependent-elimination boundaries. Its wider capabilities are not claimed by this selected direct uniform nonindexed slice.

Local owners reviewed: DerivingDecEq, DerivingContext, Equality's psElabIndexFunction and Eq.rec/congruence builders, and the checked Decision environment. The existing projection/discriminator helper opens every actual constructor field and recursive hypothesis, then closes the full telescope. No new trusted injection primitive is needed.

## Implementation

Field decision plans distinguish erased proofs, independent checked dictionaries and direct recursive fields. Uniform nonindexed admissibility remains owned by psElabDeriveFieldsWithRecursion, preserving parameter/universe alignment, field independence, constructor result and recursive metadata checks.

Left induction produces actual hypotheses `forall right, Decidable (leftChild = right)`. Each recursive field applies its checked hypothesis to the matching right child; inner right constructor analysis ignores its own hypotheses. Independent decisions use actual DecidableEq dictionaries, not BEq or a LawfulBEq assumption.

Positive proof production collects field equalities, transports dependent contexts and closes by checked reflexivity. Negative decisions use homogeneous projection and congruence. Different constructors use the existing True/False discriminator and Eq.rec. Proof fields are not runtime comparisons. Later field decisions remain inside the positive branch. No assumed self instance, new axiom, partial helper, backend-specific semantics or erasure change is introduced.

## Actual first-candidate failure and correction

Candidate **cc49934afc3d8a83cac0f0de59325ba5c59c3cea** compiled the changed DerivingDecEq module and native compiler. Focused **38908391093/job116997689233** failed while building the independent native fixture at Pscv0M3RecursiveDeriving.lean:20: the proposed field `(certificate : next = next)` referred to a recursive child and caused pinned Lean's kernel error `invalid nested inductive datatype 'Eq', nested inductive datatypes parameters cannot contain local variables`. The later stuck Decidable instance was a consequence. No portable equality execution was reached; this is not qualification.

The valid replacement is `(certificate : value = value)` for the scalar Nat field of the same recursive chain. It still tests equality transport and erasure for a dependent proof field alongside recursive data, without assuming the invalid nested type is admitted. Both native and `.ps` versions are changed together. Constructor shapes, recursion depth, scalar inputs, expected decision values, assertions and budgets are unchanged. The compiler's only additional source edit documents that inductive formation still owns positivity and nested-parameter validity; no executable algorithm changes in this correction.

Successful cloud preparation **38908918009/job116999487600**, at83cacc46c6be7d1236ecf708718505cd2f64de6a, verified focused originalblobbcdd812511353892c43a3946230db446a5d7d3f6 -> **40a4e4496319d0361bc43693294382ac87c80615** and compiler originalblobbe40b861f75e211f903fde9cf85fa765e5869d04 -> **686f49440c47321c6f3b93117fc24053492a77dd**. It printed the exact diffs and independently calculated Git blob SHAs. Connector applies these exact blobs with expected-HEAD/non-force update and removes the completed temporary workflow. Preparation itself changed no branch, commit, tracked file or PR.

## Focused qualification required

Reuse Pscv0M3RecursiveDeriving and its existing target workflow. The independently compiled native tree derives DecidableEq. Four new Bool-to-UInt64 observations check Nat/Bool decision masks, actual equality under deliberately non-reflexive BEq, and a recursive chain with a scalar-dependent proof field. Closed equal/different rfl equations check actual decisions. Existing Hashable/Repr/BEq observations and nine refusals remain; three DecidableEq refusals cover nested/indexed families and missing dictionaries at the intended elaboration rule. Recursive data remains internal.

Portable calls use qualified `Decidable.decide(self := decEq(a, b))`; the native oracle keeps native `decide (a = b)`. All eleven exports must pass direct JS, strict compiled TS, locked Rust, V8 GC and Wasmtime. The single obsolete direct-recursive DecidableEq negative was migrated to `next: List Bad` with original rejection assertion/phase unchanged; prepared nativefixtureblobd4cee482039aa24575b476292c42cc30e28f09ff is retained.

All five native/F1/F2/F3-F4-platform/focused workflows must pass the exact corrected compiler/test commit. Pending, prior focused failure and preparation success are not substitutes. Broader nested/indexed/mutual data/deriving, general motives/pattern matrices, total recursion, P0 executable assurance and P1 fixedpoints remain open.

All partial executable admission remains refused. No witness execution, invented body equations/totality, Classical/Nonempty fallback, verified downgrade, weaker gates or larger budgets. Native portable .lean; only propext/Quot.sound; no pskernel-core, self-hosting, compiler-source migration or immediate C5. No new performance gain is claimed; previous paired evidence and unresolved deep-list paths remain unchanged.
