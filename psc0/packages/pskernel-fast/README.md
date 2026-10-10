# PSKernel-Fast — New-generation kernel research

**Current implementation status: G0–G2 focused representation and toy closure prototype, cloud-validated under Lean 4.35-rc4.** It cannot type-check a Lean expression, verify a theorem, or accept a declaration. No performance gains or soundness proofs have been established.

This is an independent greenfield project. Its design **is not constrained by preserving** the old `pskernel-core` implementation, existing metatheory proof interfaces, old self-host source restrictions or old checked provider implementation. Existing branches and proof documents are archived references only.

Read [ARCHITECTURE_V3.md](ARCHITECTURE_V3.md) for the canonical performance-and-correctness-first decisions and [AI_WORK_STATE.md](AI_WORK_STATE.md) for actual qualifications.

The G0/G1 seed defines a simplified raw expression language including **symbolic universe syntax** (zero/succ/max/imax/param/mvar), and a hash-consed array of nodes with exact collision-checked lookup, bounded decoding, and raw-scope validation. Universe *equivalence and typing* are not implemented. Those operations will support a future fast kernel; they do not establish typing or soundness.

Native Lean 4.35-rc4 development commands:

~~~bash
cd psc0/packages/pskernel-fast
lake build pskernel_fast_mvp
lake exe pskernel_fast_mvp
~~~

The cloud workflow `.github/workflows/pskernel-fast-v3.yml` performs these checks on the isolated research branch. Future progress must state precisely which full Lean 4.35 core rules, negative tests, resource outcomes and model obligations are implemented and verified. Self-hosting is a future qualification, not an architecture-preservation constraint.

G2 research adds a **toy lazy closure view** in `PSKernelFast/EvalPrototype.lean` for simple beta/let/neutral evaluation. It cannot establish Lean type correctness, equivalence, or proof acceptance. All G2 tests are representation/evaluator behavior only.

G3 extends raw expression syntax toward Lean 4.35 (`Name`, symbolic levels, literal, binder info, local/metavariable syntax, metadata and projections), and fails closed at the closed-export syntax boundary. This remains an independent **syntax/interner** experiment; typing, universe equality and proof admission are NOT implemented. Metadata is presently an opaque string placeholder rather than exact Lean MData interchange.
