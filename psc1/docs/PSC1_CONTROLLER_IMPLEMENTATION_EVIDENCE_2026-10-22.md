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


- 749f72bc / 39763819545: native tests and source census pass. Rust diagnostic
  prints the admitted concrete helper and owner; no worker companion exists,
  and the true path still overflows at 100000 iterations.
- Current descendant extends fusion to already evaluated local callable leaves
  using the checked curried result type. The paired baseline/fused IR fixture
  requires a four-argument companion and 100000-step exact observation.
  Linux validation remains pending; the emitted Rust must demonstrate the fix.


The initial general curried-local fallback in 3da91ece is superseded: it could
move intermediate callback divergence after a later argument. The replacement
admits only a single checked application layer and adds a real deadline test
where that callback must diverge before a later argument throws. Known source
base lambda values are instead expanded before total helper capture, under the
existing official-conversion theorem. All original strict computations stay.


Rust path inspection corrects the earlier missing-worker interpretation:
DirectBackend emitted the original validated module without invoking fusion.
The Rust host now applies the strictly rechecked fusion pass before deriving
public type closure, generated code and runtime plan. Rust's supported generic
declarations are preserved; no monomorphizing plan is forced on that target.
Source execution and the full release gates remain the authority for success.
