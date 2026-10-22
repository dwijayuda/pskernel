# Finite-controller implementation evidence

The complete qualified baseline remains source 65fa8766 and run 39683701190.
Later source changes require their own full exact-commit qualification.

- 4c316c93 / 39688891189: eager iterator continuations exhaust JS/TS heaps.
- 003873e / 39691432898: total Unit-thunk folds pass native conversion and
  once-only argument checks; the combined bundle reaches its fixed build ceiling.
- 1731fa71 / 39693605851: huge-range immediate return passes; complete traversal
  overflows JS through callbacks outside the recursive driver.
- bef6343 / 39694885609: JS/TS traversal passes. JS 1000001 mutual calls use
  58664 KiB RSS, under the original 262144-KiB bound. Corpus compilation reveals
  3145709 nodes in the semantic wrapper and 138242867 admission bytes.
- e076fe0 / 39695880402 and f1a3384b / 39696850523: source sharing alone and
  unification reflexivity alone are insufficient. The size probe/capture still
  times out; neither native size probe completed.
- 2919c7b9 / 39758498052: local-let inference plus conversion reflexivity preserves
  sharing. Native/kernel/IR size probes and original controls pass. The wrapper
  has 430 nodes, admissions 374615 bytes, measured pipeline 360 ms versus 39238 ms.
  Rust debug execution specifically aborts with stack overflow at the unchanged
  streaming true case; immediate return and previous cases pass.

The next correction lifts finite Nat controllers into concrete total recursor
helpers, preserving source evaluation and capture. Each has an erased theorem
requiring official conversion equality with the original checked fold. Existing
worker fusion and backend tail lowering then apply to those concrete bodies.
No new logical axiom or partial helper is introduced. The whole source matrix,
all targets, negative boundaries and full release contract still must pass.
