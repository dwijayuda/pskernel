# M2+A Array.filter

This is a selected P0 API completion within the existing roadmap, not a new milestone sequence. Implementation is prepared for qualification; no runtime qualification is claimed by this design note.

## Pinned reference

Lean 4.35.0, commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc:
src/Init/Data/Array/Basic.lean defines filter as a left fold with an initially empty array and conditional push. Its documented examples fix start-inclusive/stop-exclusive slicing, retention order and empty cases. Relevant tests inspected: tests/elab/array1.lean (map/fold/filterMap and persistent updates), cbv_array.lean (kernel-checked indexing) and filter.lean (large filtering). No upstream test axioms or sorry terms are imported.

## Invariants and implementation

The public checked Core declaration preserves the element universe, predicate-first order and dependent optParam defaults: start = 0, stop = the actual input size. Its body composes the existing checked Array.foldl/emptyWithCapacity/push model and Bool elimination. It introduces no axiom, instance or alternate checker. The environment extension follows the frozen platform-word stage so no earlier native asset becomes its own replay input.

Erasure owns one arrayFilter intrinsic with one element type and four runtime operands. Partial applications use the existing special-application completion path. The IR checker requires an element-to-Bool callback, Array element, Nat start and Nat stop. All operands are captured/evaluated through the established call machinery.

JS/TS use the shared structured ECMAScript generator path, preserving callback trampolining. Rust uses a safe Vec builder over a bounded range and preserves the input Rc vector. GC Wasm allocates a temporary buffer no larger than the selected range, writes retained elements once, and copies the retained prefix into one exact-size result. It never implements filtering by repeated persistent push. Empty/reversed ranges skip the predicate. Inputs remain persistent; each selected element is tested once in increasing index order. All algorithms are linear in the selected range, with linear output/temporary storage and no new linear-memory boundary.

The retained legacy TS printer and callback purity classification include the same intrinsic. No unchecked shape, unknown IR type, host word-width choice or source-to-runtime proof payload is introduced.

## Focused qualification

One fixture adds eleven shared observations to the existing JS/TS/Rust/Wasm/core/component corpus: whole/default ranges, explicit start or stop, no matches, empty input, partial callback application, captured predicate, higher element universe, preserved input, reversed and huge bounds. A compact independent native Lean oracle checks slice/order results; a source theorem checks the selected logical model through the official kernel. Existing checks, budgets and observations remain.

Strict Standard hashes must be independently observed and reviewed before selecting this extra declaration. Runtime conformance plus checked model admission is not a general backend-preservation theorem. The broader M2+A manifest, UTF-8 and solver/retention exit work remains separate.
