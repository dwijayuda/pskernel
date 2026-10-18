# M3 proof/spec-only noncomputable definitions — 18 October 2026

## Reference and selected semantics

The primary implementation reference is Lean 4.35.0, commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc:

- [NoncomputableAttr](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Compiler/NoncomputableAttr.lean) records a declaration tag separate from kernel definitions.
- [PreDefinition/Basic](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/PreDefinition/Basic.lean) preserves logical declarations and skips executable compilation for the selected modifier.
- [MutualDef](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/MutualDef.lean) checks the original main modifiers before partitioning and propagates noncomputable intent to local helpers.
- [LCNF/ToLCNF](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Compiler/LCNF/ToLCNF.lean) rejects computational uses while allowing contexts erased by the compiler.
- Native controls: [usesOfNoncomputable](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/tests/elab/usesOfNoncomputable.lean), [isNoncomputable](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/tests/elab/isNoncomputable.lean), and [noncomputableUnused](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/tests/elab/noncomputableUnused.lean).

PSCV0 v7.2 §0B and §5 allow exactly one feature modifier on selected def/function heads, prohibit competing recursion suffixes on a noncomputable head, and distinguish logical dependencies from executable computational dependencies. This slice adds no unsafe profile, source axiom, runtime choice implementation or extra logical assumption.

## Architecture and invariants

1. Syntax retains the modifier as a source declaration kind through scope/capture preparation. Both source printers preserve it. The existing typed predefinition owner constructs ordinary checked logical definitions and equations. No second elaborator or new Core kind is introduced.
2. An environment tag index records execution policy. Every declaration owned by a noncomputable source block, including its helpers, inherits the tag. Pinned mutual modifier compatibility is checked on all original mains before SCC splitting.
3. Module interfaces retain tags for visible identities; the assembled project retains tags for all actual declarations, including private definitions. Prepared modules preserve this metadata independently of their unchanged canonical logical admissions. Reconstructed environments restore it.
4. Executable recursor preparation leaves tagged bodies intact. They need no runtime workers. Erasure omits their entry layouts and definitions but retains their logical Core types and bodies in the checking environment.
5. The shared runtime expression visitor checks a retained computational head before projection expansion or backend lowering. Proof, type and index argument roles are already determined by checked erasure mechanisms; these paths do not inspect erased computational payloads. An actual runtime use fails even if the noncomputable definition happens to have a constructive body. There is no syntactic scan of all proof dependencies and no per-backend exception.
6. Explicitly requesting a tagged executable export also fails. Native requests report PSCV0-NONCOMPUTABLE-EXEC at assurance and emit nothing. Existing verified requests continue to fail for their missing model/refinement evidence; this work does not certify noninterference or target correctness.

The selected language does not expose Lean's arbitrary macro_inline mechanism. Native noncomputableUnused is a reference for why runtime-role classification, rather than textual constant occurrence, is required; it is not permission to invent source inlining or erase an observable argument.

## Qualification boundary

One consolidated native fixture checks metadata and approved choice closure, generic section/helper ownership, source-print retention, unchanged logical definition kind, omission from executable IR, proof/type-only uses, direct/transitive/imported computational refusals, explicit export refusal, mixed-main and suffix ownership, and verified no-downgrade. The same ordinary source emits all five target bundles. One Bool-to-UInt64 observer requires ten comparisons across JavaScript, strict TypeScript, Rust, V8 GC and Wasmtime.

This is an implementation candidate, not successful CI evidence. The official kernel still checks the full logical source graph before any target emission. The foundation remains exactly propext, Quot.sound and Classical.choice. All existing acceptance cases and budgets remain required. M3+B closure still requires the six-exit ledger and Native/M3/F1/F2/F3 success on one exact SHA.
