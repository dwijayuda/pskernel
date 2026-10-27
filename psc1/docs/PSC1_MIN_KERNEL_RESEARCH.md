# PSC1 MinKernel: research and initial design decision

Inspected 2026-10-27 through primary upstream sources and GitHub APIs. These are source findings, not new upstream build or benchmark results. No third-party implementation is vendored by the initial design.

## Decision and evidence boundary

Select **A: a direct semantic proof for a deliberately restricted executable checker** as the initial complete fragment. Use a simply typed lambda calculus (STLC) with an empty type, natural-number type and function types, and a sequential checked definition environment. Prove acceptance implies an interpretation of each accepted term at its claimed type, then derive that a closed term of the empty type is never accepted. The proof must import the actual executable checker; a second simplified checker or an abstract relation with no acceptance bridge is insufficient.

The fragment has no dependent Pi types, universe polymorphism, user inductives or recursors. Consequently it does **not** cover the full PSC1 self-hosting declaration closure. Extending it to dependent core and imported foundations requires further executable support and new proofs. This is an attainable initial proof milestone, not evidence that the remaining work is impossible and not qualification of compiler self-hosting. No production admission should accept the fragment's result for a wider profile.

The selected calculus can be interpreted directly in Lean types, with the empty type interpreted by `Empty` and arrows by functions. It needs no new set-theory existence hypothesis. Lean checking the proof and executing the checker, the source-to-executable compiler, runtime and any outer transport remain distinct trust boundaries. Fuel and input-size limits should reject exhaustion; their absence must never be interpreted as acceptance.

Proof sources remain outside the runtime source graph. Official Lean native and Wasm retain the broader independent-checking responsibility while the small fragment is developed. Any separate JavaScript/PSC1 implementation needs a proved implementation bridge before the Lean-source theorem can be attributed to it.

## Alternatives

| Option | Size and engineering | Proof complexity | Runtime and self-hosting | Trust boundary |
| --- | --- | --- | --- | --- |
| A. Direct small semantic model | Smallest initial source and dependency closure; new dependent features increase scope. | Complete STLC proof is manageable. Dependent universes, conversion and inductive elimination require substantial new lemmas. | Bounded, pure code can be designed for the actual PSC1 subset. Performance must be measured locally to this implementation in Linux CI. | The theorem must consume the real acceptance result, including the checked environment and foundation. |
| B. Restricted con-leche | Existing semantic architecture is valuable, but unmodified upstream is much larger than a minimal runtime. Pruning requires dependency analysis. | A wrapper narrowing unmodified `checkDecls .verified` may reuse its theorem. Modified or translated code does not automatically inherit it. | Full Lean features, computed fields, generated inductive models and caches are not shown to compile under PSC1. Upstream speed is not a PSC1 benchmark. | Conditional on an abstract set-theory model, plus compiler/runtime and outer IO. |
| C. Selected PSKernel-Core subset | May reduce executable engineering through existing representations and algorithms. Actual source reuse depends on measured closure. | Existing syntactic or reduction lemmas do not establish a complete acceptance-to-model theorem. The selected executable subset and foundation require a bridge. | Best prospect for existing adapters and representations; self-hosting must still be demonstrated for the real runtime sources. | No consistency claim transfers merely from the package name or testing history. |
| D. Verified reduction to another checker | Potentially small runtime, but adds an explicit translation artifact. | Need a theorem that this acceptance implies the proved checker's acceptance with the intended declaration identities and semantics. | An independent checker with a useful theorem may use a source language outside PSC1's subset. | Reference agreement or delegation is validation, not formal reduction. Official Lean acceptance alone is not an existing machine-checked executable consistency theorem. |

## con-leche

Pinned source: [`0d2f467bbe576f21e42ea861d246abef718f1c13`](https://github.com/leanprover/con-leche/tree/0d2f467bbe576f21e42ea861d246abef718f1c13), live default-branch HEAD when inspected. [Toolchain](https://github.com/leanprover/con-leche/blob/0d2f467bbe576f21e42ea861d246abef718f1c13/lean-toolchain): `leanprover/lean4:v4.35.0`. [License](https://github.com/leanprover/con-leche/blob/0d2f467bbe576f21e42ea861d246abef718f1c13/LICENSE): Apache-2.0.

The [actual main theorem](https://github.com/leanprover/con-leche/blob/0d2f467bbe576f21e42ea861d246abef718f1c13/ConLeche/MainTheorem.lean) is `model_exists`: for every `V` implementing `SetTheory`, every Nat-operation pin list and declaration array, acceptance by `ConLeche.Cached.checkDecls .verified` yields `Nonempty (Model V env)`. The model assigns every stored constant a member of its type's interpretation, interprets the built-in `False` by the empty set, and pins equality to set equality. This theorem connects an actual executable declaration fold with its semantics, rather than only proving an abstract model consistent.

The [set-theory interface](https://github.com/leanprover/con-leche/blob/0d2f467bbe576f21e42ea861d246abef718f1c13/ConLeche/SetTheory/Core.lean) supplies extensionality, pairing, union, power set, regularity, replacement for Lean-level functions, and an omega chain of Grothendieck universes. Infinity is derived. Choice is supplied through the Lean meta-logic. Existence of a model of this interface is a theorem premise, not a discharged fact and not a declaration listed by `#print axioms`. The separate bridge relates it to the omega-many-inaccessible-cardinals hypothesis used by Carneiro's model analysis.

[Axiom guards](https://github.com/leanprover/con-leche/blob/0d2f467bbe576f21e42ea861d246abef718f1c13/tests/ConLecheTests/Axioms.lean) pin the logical dependency list to `propext`, `Classical.choice`, `Quot.sound`. The same file explicitly explains why those guards cannot detect runtime compiler escapes such as `implemented_by`; a separate trust-surface audit is needed.

The separate `no_False_declaration` corollary covers input chunks satisfying one specified JSON template (`jsonWithTheoremFalse`). Declaration-stream guarantees, generic parser faithfulness and arbitrary frontend translations must not be conflated. `--trusted` skips certification work and is outside these guarantees. Binder annotations and runtime validation of their coherence support the direct semantic proof. Ordinary non-mutual inductives have native modelling; mutual/nested blocks use generated models. Projection rewriting and declaration reordering are additional frontend boundaries. These details make unrestricted code removal or a fresh PSC1 translation a new verification project.

The [proof-idea document](https://leanprover.github.io/con-leche/con-leche-proof-idea.html) identifies its revision as [`24980d94f2614fbc05299a745e3320c1d411efd5`](https://github.com/leanprover/con-leche/tree/24980d94f2614fbc05299a745e3320c1d411efd5), 2026-10-23. It is an explanatory, AI-written account; theorem source is the authority.

### Reproducible size lower bounds

Using [the recursive Git tree](https://api.github.com/repos/leanprover/con-leche/git/trees/0d2f467bbe576f21e42ea861d246abef718f1c13?recursive=1), selecting blob paths ending in `.lean`, and summing GitHub's `size` fields gives:

| Path selection | Modules | Source bytes |
| --- | ---: | ---: |
| All `.lean` files (includes proofs, tests, whitepaper and auxiliary material) | 915 | 12,896,363 |
| `ConLeche/Kernel/` and `ConLeche/Cached/` `.lean` files only | 59 | 1,007,633 |

The second row excludes frontend code and other imported runtime dependencies, so it is a **lower bound**, not a measured runtime dependency closure or executable payload. Neither row is a line count. These measurements establish that wholesale reuse is not a tiny implementation; they do not estimate the size of a verified restriction.

## con-ron

Pinned source: [`053ceb8803a870fbb972caa665c84f786294e899`](https://github.com/leanprover/con-ron/tree/053ceb8803a870fbb972caa665c84f786294e899), live default-branch HEAD when inspected. [License](https://github.com/leanprover/con-ron/blob/053ceb8803a870fbb972caa665c84f786294e899/LICENSE): Apache-2.0.

The [human-written README](https://github.com/leanprover/con-ron/blob/053ceb8803a870fbb972caa665c84f786294e899/README.md) describes a real two-part refinement chain: an arena-based Lean twin refines con-leche's pure checker, and an Aeneas-generated Rust model refines that twin. [Capstone theorems](https://github.com/leanprover/con-ron/blob/053ceb8803a870fbb972caa665c84f786294e899/proof/ConRon/Capstone.lean) compose these into model-existence and no-False results. This is stronger than an unverified hand translation or differential tests.

The [explicit assumptions](https://github.com/leanprover/con-ron/blob/053ceb8803a870fbb972caa665c84f786294e899/OVERVIEW.md#31-what-the-theorems-assume) include the set-theory model, the actual driver executing the extracted stages in the specified order from the intended empty state, a chunk source reading the bytes in order, verified mode, and successful worker runs whose index lists cover every pending record. Main IO and scheduling control flow remain trusted obligations. `--trusted` is outside the theorem, as are pin-list CLI paths that bypass the proved decoder.

The base capstones use explicit decoded-pin premises and report only con-leche's three logical axioms. Embedded-pin variants incur an extra Aeneas axiom for the embedded constant's definition. Aeneas/Charon translation correctness, external hand-written models, Rust compiler, allocator/runtime and numeric implementation remain execution assumptions. The README explicitly does not describe this as a high-assurance verification effort because the Rust-to-Lean translator is relied upon. Representation-specific caches and DAG sharing are useful later optimizations, not a substitute for an initial proved baseline.

## lean4lean and lean4lean-model

Correct checker repository: [`digama0/lean4lean`](https://github.com/digama0/lean4lean), pinned live HEAD [`67f63b0c818920dfaed2ad07ccff187a6a8fe1e3`](https://github.com/digama0/lean4lean/tree/67f63b0c818920dfaed2ad07ccff187a6a8fe1e3), Apache-2.0. Its [README](https://github.com/digama0/lean4lean/blob/67f63b0c818920dfaed2ad07ccff187a6a8fe1e3/README.md) distinguishes runtime library/tool, abstract theory, and implementation verification targets. The checker derives from the official C++ implementation, so it is not algorithmically independent in the same sense as an independently designed checker. Its separation of executable and proof targets is a useful layout precedent.

[`digama0/lean4lean-model`](https://github.com/digama0/lean4lean-model/tree/27fb3b656c0d536469f6817cf277904dee8eb5ca), pinned live HEAD `27fb3b656c0d536469f6817cf277904dee8eb5ca`, has a [README](https://github.com/digama0/lean4lean-model/blob/27fb3b656c0d536469f6817cf277904dee8eb5ca/README.md) explicitly stating that its consistency target is `sorry`ed pending model construction. It uses v4.32.2 and an omega-many-inaccessibles hypothesis. GitHub's repository metadata returned no recognized license. Do not treat this model as a completed consistency theorem or vendor it without resolving licensing.

## Official Lean 4.35 and declaration export

The assignment's Lean SHA is [`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`](https://github.com/leanprover/lean4/tree/eb6cafb7290e8bd5f2937522d8d804f58f02bafc); the PSC1 branch pin must also be checked independently before implementation. At this SHA, [C++ environment admission](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/kernel/environment.cpp) checks types, bodies and conversion before installing declarations. The separate `lean_add_decl_without_checking` entry point must not appear on an independent checking path. The [type checker](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/kernel/type_checker.cpp) covers universe instances, projections, safe/partial/unsafe references, reduction and conversion.

[lean4export](https://github.com/leanprover/lean4export) exports selected declarations plus transitive dependencies in its NDJSON format. It erases metadata by default and can include unsafe declarations under an explicit option. Export closure selection and transformations have a separate correctness boundary from the destination checker. An official-Lean native/Wasm verifier must retain exact canonical declaration identities and check required imported declarations rather than relying on an unverified arbitrary imported environment. No claim here requires or suggests converting the C++/Emscripten checker to Wasm GC.

## Lean Kernel Arena

Pinned source: [`bbd9636b9c667f57c4f4d78c05f8813ef6afeeac`](https://github.com/leanprover/lean-kernel-arena/tree/bbd9636b9c667f57c4f4d78c05f8813ef6afeeac), live HEAD when inspected, Apache-2.0. Its [con-leche entry](https://github.com/leanprover/lean-kernel-arena/blob/bbd9636b9c667f57c4f4d78c05f8813ef6afeeac/checkers/con-leche.yaml) pins `0d2f467bbe576f21e42ea861d246abef718f1c13` and runs verified mode with four workers.

The [bug corpus](https://github.com/leanprover/lean-kernel-arena/tree/bbd9636b9c667f57c4f4d78c05f8813ef6afeeac/tests/bugs) supplies relevant adversarial patterns: constant universe counts, `imax` normalization, projections of non-structures, missing recursor induction hypotheses, and lying K/nat recursor rules. The [performance corpus](https://github.com/leanprover/lean-kernel-arena/tree/bbd9636b9c667f57c4f4d78c05f8813ef6afeeac/tests/perf) includes beta ladders, let ladders, shared subterms, repeated subproblems and shift cascades. Use cases within the declared fragment and explicitly reject/decline unsupported constructs.

The [arena contract](https://github.com/leanprover/lean-kernel-arena/blob/bbd9636b9c667f57c4f4d78c05f8813ef6afeeac/README.md) distinguishes accept, reject, unsupported and error, and documents that tests assume any supplied `Init.Prelude` comes from an official release. Arena testing is empirical correctness/performance evidence; that prelude convention cannot justify an arbitrary custom admitted foundation. No arena score or upstream performance claim is a benchmark of the new PSC1 implementation.

## Expansion obligations

Before widening `min` beyond the initial fragment, measure the actual elaborated compiler closure and prove support for the constructs it uses. In particular, surface-language simplicity does not remove dependent types, generated structures/projections, recursors or imported primitive equations from elaborated Core. Preserve a coverage report that separates surface syntax, kernel expressions, executable IR, imported declarations and proof assumptions.

Each widening needs: a semantic interpretation; actual checker acceptance lemmas; environment preservation including primitive/foundation checks; explicit unsupported/resource refusal; exact transport and identity checks; meaningful negative tests; official-Lean agreement on the common domain; and Linux CI evidence. Self-host qualification additionally requires the generated checker actually checking the full source closure and genuine G1/G2/G3 fixed points. None of the upstream evidence discharges those PSC1-specific obligations.
