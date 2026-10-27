# Research guide: choosing the next PSC1 MinKernel architecture

Prepared 2026-10-27 for continuation with GPT-6.1 Sol High. This is a decision and experiment guide grounded in inspected source. It does not claim that any of the proposed experiments has already passed. Run all builds, tests, proof checks and benchmarks in Linux GitHub Actions. Do not use local builds or Desktop Commander.

## 1. Preserve the qualified starting point

The inspected PSC1 checkpoint is [`d6bebd230bcaadf35a254bfbc5a26a17228db55f`](https://github.com/dwijayuda/pskernel/tree/d6bebd230bcaadf35a254bfbc5a26a17228db55f), on `research/psc1-minkernel-consistency-selfhost-20261027`. Re-read the live branch HEAD, dedicated work state, terminal CI results and source hashes before another write. Use non-force, expected-HEAD updates; preserve concurrent history. Do not merge or publish packages without the user's authorization.

At this checkpoint the runtime source is a 93-line, one-module **object-language STLC checker**, with separate full-Lean proofs. Its types are Empty, Unit, Nat and simple arrows; terms are variables, checked positional constants, literals, annotated lambdas and applications. The actual acceptance theorem rules out a closed `PsMinTy.empty` query after successful `psMinCheckEnvironment`. It is not a theorem about arbitrary Lean `False`, dependent Core, imported axioms, or compiler correctness.

Start from the [actual checker](https://github.com/dwijayuda/pskernel/blob/d6bebd230bcaadf35a254bfbc5a26a17228db55f/psc1/packages/pskernel-min/src/Ps/MinKernel/Check.lean), [actual proof](https://github.com/dwijayuda/pskernel/blob/d6bebd230bcaadf35a254bfbc5a26a17228db55f/psc1/proofs/pskernel-min/MainTheorem.lean), [proof status](https://github.com/dwijayuda/pskernel/blob/d6bebd230bcaadf35a254bfbc5a26a17228db55f/psc1/docs/PSC1_MIN_KERNEL_PROOF_STATUS.md) and [work state](https://github.com/dwijayuda/pskernel/blob/d6bebd230bcaadf35a254bfbc5a26a17228db55f/psc1/docs/PSC1_MIN_KERNEL_WORK_STATE.md). Re-query live CI before repeating their qualification claims.

The exact compiler census currently records 124 source modules, 4,742 source Core members, 4,747 logical members, 3,465 canonical admission records and 308 inductive groups. It observes 230,478 application nodes, 12,986 forall nodes, 7,168 projection nodes, 2,862 Nat literals and 5,875 String literals. These are occurrence counts, not dynamic inference/reduction profiles or a classification of dependent versus nondependent binders.

The 115-declaration replayed foundation contains 60 axioms, 14 constructors, 25 definitions, nine inductives and seven recursors. Only 34 axioms are directly referenced by compiler expressions; **all 60 are still replayed**. A direct-reference count is not a transitive dependency analysis and cannot justify dropping the other declarations.

The small runtime's *own elaborated source* already produces three inductive groups and nine definitions; its vector module adds four definitions. The 16-record source-compilation example is therefore a dependent canonical graph outside STLC. Compiling and running this source under PSC1 does not show that this checker checks itself. Full compiler coverage, minimal-checker G1/G2/G3 and Practical Core qualification remain open.

## 2. Make the next batch a bounded architecture experiment

Do not respond to the large census by implementing every missing kernel rule. First compare two concrete proof paths on the same small, real canonical graphs:

1. A **native reference experiment around unmodified con-leche**, to discover exact translation/foundation obstacles and prove a thin wrapper theorem.
2. A **direct-model extension**, optionally reusing selected PSKernel-Core utilities, to measure the cost of a useful dependent rule and its real executable bridge.

Use the current checker-source graph and a dependency-closed compiler slice as pilots. Record exactly which source declarations each pilot covers. An invented monomorphic test language is useful as a lemma test but is not evidence of canonical graph coverage. Keep canonical `min` and `dual` refusing until a supported canonical domain and its bridge are both proved and qualified.

The first decisive question is **how to realize the foundation and its computation**, not which parser syntax to implement. A JSON conversion alone cannot solve this.

## 3. What can actually be reused from con-leche

Use exact upstream revision [`0d2f467bbe576f21e42ea861d246abef718f1c13`](https://github.com/leanprover/con-leche/tree/0d2f467bbe576f21e42ea861d246abef718f1c13). It uses [Lean v4.35.0](https://github.com/leanprover/con-leche/blob/0d2f467bbe576f21e42ea861d246abef718f1c13/lean-toolchain), matching PSC1's current release version. Its [license is Apache-2.0](https://github.com/leanprover/con-leche/blob/0d2f467bbe576f21e42ea861d246abef718f1c13/LICENSE). Preserve attribution and license if source is copied; prefer a pinned experimental dependency while measuring feasibility.

### 3.1 Actual API and theorem

The declaration-level front door is [`ConLeche.Cached.checkDecls`](https://github.com/leanprover/con-leche/blob/0d2f467bbe576f21e42ea861d246abef718f1c13/ConLeche/Cached/Installed.lean):

```lean
checkDecls (mode : CheckMode) (pins : List NatOpPinSet)
  (ds : Array Declaration) : Except (CheckError × Nat) Env
```

It starts from `Env.empty`, installs declarations and records pending body checks, then checks **every** pending declaration against its proper environment prefix. Taking an intermediate installed environment, checking only a header, or checking only one body is not this API's accepted result. Its `FullyChecked` and `fullyChecked_checkDecls` interfaces are useful if a driver needs to retain evidence while scheduling work; they do not authorize skipping checks.

The proved capstone in [`ConLeche.MainTheorem`](https://github.com/leanprover/con-leche/blob/0d2f467bbe576f21e42ea861d246abef718f1c13/ConLeche/MainTheorem.lean) is:

```lean
theorem model_exists (V : Type w) [SetTheory V]
  (pins : List NatOpPinSet) (ds : Array Declaration) (env : Env)
  (accepted : checkDecls .verified pins ds = .ok env) :
  Nonempty (Model V env)
```

The premise is the actual verified fold's success equation. The theorem quantifies over every pin list; an empty list is sound but declines unsupported Nat-operation definitions. It does **not** assert completeness, arbitrary frontend correctness, performance, PSC1 compilation correctness or self-hostability.

Import `ConLeche.MainTheorem`, not `ConLeche.Challenge`. The latter is a deliberately separate statement/challenge module containing `sorry`; the [Lake configuration](https://github.com/leanprover/con-leche/blob/0d2f467bbe576f21e42ea861d246abef718f1c13/lakefile.toml) explains this distinction. Upstream also has a separate whitepaper fragment with its own syntax and theorem: proving something there does not prove a modified production checker.

### 3.2 Model assumptions must remain visible

[`SetTheory V`](https://github.com/leanprover/con-leche/blob/0d2f467bbe576f21e42ea861d246abef718f1c13/ConLeche/SetTheory/Core.lean) assumes membership with extensionality, pairing, union, power set, regularity, replacement for Lean-level functions and an omega chain of Grothendieck universes. Existence of such a model is not proved in the main package. The theorem is relative to that hypothesis, with meta-level choice supplied by Lean.

[Axiom guards](https://github.com/leanprover/con-leche/blob/0d2f467bbe576f21e42ea861d246abef718f1c13/tests/ConLecheTests/Axioms.lean) report `propext`, `Classical.choice`, `Quot.sound`; they do not list theorem premises such as `[SetTheory V]`. Do not add `axiom hasSetTheory` to conceal the hypothesis. The separate Mathlib/lean4lean-model bridge is not needed to reuse the conditional theorem; investigate its toolchain/dependencies independently before importing it. The independent [`lean4lean-model` consistency target](https://github.com/digama0/lean4lean-model/blob/27fb3b656c0d536469f6817cf277904dee8eb5ca/README.md) remains explicitly `sorry`ed at its inspected revision and uses v4.32.2; it is not a completed substitute for this theorem.

This would strengthen PSC1's covered language while changing the claim from the small STLC model to a stronger **relative** model assumption. State that trade explicitly.

### 3.3 Import closure and self-hosting obstacles

A source import walk at this pin, stripping nested Lean comments and following ordinary `import`/`public import` edges, found:

| Root | Reachable ConLeche `.lean` files | Source bytes |
| --- | ---: | ---: |
| `ConLeche.Cached.Installed` | 56 | 985,813 |
| `ConLeche.MainTheorem` | 534 | 10,199,225 |

These are reproducible source measurements against [the pinned recursive tree](https://api.github.com/repos/leanprover/con-leche/git/trees/0d2f467bbe576f21e42ea861d246abef718f1c13?recursive=1), not generated executable sizes or complete Lean dependency closure sizes. The runtime-root walk has direct non-ConLeche imports `Init.Util`, `Std.Data.HashMap`, `Std.Data.HashSet`. The theorem closure, which stays outside self-hosting, additionally reaches model/proof and Lean metaprogramming modules. It does not import `ConLeche.Challenge`.

Crucially, ordinary-import counts are **not** the complete build footprint. [`BasisGen`](https://github.com/leanprover/con-leche/blob/0d2f467bbe576f21e42ea861d246abef718f1c13/ConLeche/Kernel/BasisGen.lean) uses `public meta import Lean`, command elaboration, and elaboration-time unsafe evaluation wrappers to splice kernel-checked literal basis definitions. [`NatOpPins`](https://github.com/leanprover/con-leche/blob/0d2f467bbe576f21e42ea861d246abef718f1c13/ConLeche/Kernel/NatOpPins.lean) meta-imports [`PinGen.Dump`](https://github.com/leanprover/con-leche/blob/0d2f467bbe576f21e42ea861d246abef718f1c13/ConLeche/PinGen/Dump.lean), which imports Lean, and `#load_natop_pins` includes three committed JSON files totaling **1,982,078 bytes**. Generated declarations are not represented by the short loader source's line count. Passing `pins := []` does not remove that static source import.

The checker also uses computed fields, proof-justified `csimp` substitutions, typeclasses, module features, memo tables and source patterns beyond PSC1's present portable profile. The elaboration-time unsafe machinery is not evidence of an unsafe checking rule; generated definitions and their proofs are kernel checked. It is nevertheless a concrete obstacle to compiling the **same source** with PSC1. Do not silently erase generators, computed fields or optimizations and then attribute the unchanged theorem to different executable code.

Thus unmodified con-leche is immediately plausible as a **pinned native research/reference checker**, but not already a PSC1-self-hostable MinKernel. A small wrapper around a large external executable is not a small kernel implementation.

## 4. Why literal canonical translation will decline

[`ConLeche.Declaration`](https://github.com/leanprover/con-leche/blob/0d2f467bbe576f21e42ea861d246abef718f1c13/ConLeche/Kernel/Env.lean) accepts definitions, theorems, checked opaques, inductive blocks and narrowly recognized basis/quotient cases. Its axiom branch in [`Cached.ParsedC`](https://github.com/leanprover/con-leche/blob/0d2f467bbe576f21e42ea861d246abef718f1c13/ConLeche/Cached/ParsedC.lean) declines arbitrary axioms. Exceptions are exact standard-axiom pins and tightly specified compiler-trust scaffolding; ignored `sorryAx` declarations install nothing and uses decline. Do not broaden this arm to admit PSC1's 60 axioms and keep claiming the upstream theorem.

The current foundation still declares `Eq`, `Bool`, `Bool.true`, `Bool.false`, `Bool.decEq`, `Unit`, `Unit.unit`, `Char`, `String`, `Array`, primitive operations and several scalar carriers as axioms. Conversely, Int/its constructors, Decidable/ite and List/Option/Prod replacements are not all axioms: inspect the final exported prelude, not the original Prelude file alone. The providers reconstruct real inductives and Lean generates recursors; separate recursor metadata is not blindly admitted by the official checker.

Relevant mismatch classes:

| Source feature | Concrete target obstacle | Required evidence |
| --- | --- | --- |
| Arbitrary carrier/function axioms | con-leche refuses them | A checked realization of the source signature and a semantic bridge; not a whitelist of arbitrary axioms |
| Source `Eq` axiom | target equality is a pinned basis with semantic equality | A realization mapping to that basis, preserving the source type and intended equality boundary |
| Nat operations | target literal acceleration requires checked recurrence/type certificates; div/mod use supported definition pins | Exact checked definitions/certificates or an explicitly smaller domain; type-compatible arbitrary witnesses do not justify reduction equations |
| String literals | target `strLitSupported` requires `String.ofList`, List constructor and Char operation shapes | Checked realizations and a literal interpretation/translation theorem; PSC1's existing String-operation axioms alone are insufficient |
| Inductive admission group | target `.indDecl` includes `ConstantInfo` with recursor information and declared parameter count | Deterministic generation/checking of matching recursors and semantic correspondence, including positivity and elimination restrictions |
| Primitive projections | target has checked projection tables and restricted frontend rewriting | Owner/index/type and reduction preservation; unsupported shapes must decline |
| Partial logical/executable pairing | canonical `ordinary-checked` separates constructive opaque witness from retained executable body | Preserve both identities and existing pairing checks; model consistency of the logical witness does not prove runtime termination or executable correctness |
| Universes/binders/names | representations differ; target erases binder names/info and has its own name/level/Expr types | Scope, structured-name injectivity, level substitution/evaluation and binder preservation proofs |

The relevant target literal and primitive gates are in [`CoreDefs`](https://github.com/leanprover/con-leche/blob/0d2f467bbe576f21e42ea861d246abef718f1c13/ConLeche/Kernel/CoreDefs.lean) and [`DeclCheck`](https://github.com/leanprover/con-leche/blob/0d2f467bbe576f21e42ea861d246abef718f1c13/ConLeche/Kernel/DeclCheck.lean). A function of the correct type can still violate a primitive computation rule, so realizability of a signature alone is insufficient when the checker reduces those functions by name.

There is a specific universe-shape conflict to test early: PSC1's [`SelfHostPrelude`](https://github.com/dwijayuda/pskernel/blob/d6bebd230bcaadf35a254bfbc5a26a17228db55f/psc1/packages/environment/src/Ps/Environment/SelfHostPrelude.lean) installs `List`, `List.nil` and `List.cons` with **empty level-parameter lists**, and uses `List` with zero universe arguments at `Type`. Its recursor separately has a motive universe parameter. Con-leche's String-literal guard requires a **one-universe-parameter** `List.{p} : Type p -> Type p`, with matching polymorphic constructors, and expands strings through `List.{0}`. Supplying the existing monomorphic List unchanged will fail that guard, even after arbitrary-axiom refusal is solved. Replacing a zero-parameter declaration with a polymorphic one requires changing its uses and proving that translation; it is not a metadata-only adjustment.

One concrete candidate to compare is a protected target namespace for translated source declarations, plus separate verified target helper declarations for String's polymorphic List representation. Source `List` could remain monomorphic under its translated name while the target's literal machinery uses its own `List`. This requires an injective source-name map, collision refusal for the helper namespace, correct projection-owner mapping and a source-to-target denotation theorem. Another candidate is a proved lift from source List to the target List instantiated at universe zero. Neither candidate is implemented or proved here. Keep the experiment small enough to establish which map is actually simpler before translating the whole compiler graph.

One candidate for an otherwise ordinary source axiom is a target **checked opaque** with a supplied inhabitant: con-leche checks the witness and subsequently stores an opaque constant. This is an experiment, not a blanket solution. Reserved names, primitive gates, universe parameters, literal shapes and required definitional equations may prohibit it. If the source axiom is replaced by a definition/inductive/basis, retain the original source identity and separately name the realized target identity; prove the realization. Never rewrite the source manifest and call it an unchanged declaration.

## 5. What a proof-carrying adapter must prove

Separate the following layers; a green test at one layer is not a theorem for the next:

1. **Bounded decoding:** raw bytes decode to the intended canonical syntax; malformed, duplicate, unknown and over-budget forms refuse. Preserve exact source/manifest/admission bytes and hashes.
2. **Structural translation:** an injective structured-name map; levels and substitutions commute; binders/scopes, types, bodies and declaration order correspond; unsupported constructors refuse rather than disappear. Erasing binder names/info needs an explicit semantic irrelevance lemma.
3. **Foundation realization:** target checked declarations interpret every permitted source foundation declaration, with exactly the computation equations used by inference/conversion. No arbitrary target axiom gate.
4. **Admission preservation:** wrapper acceptance actually implies `checkDecls .verified pins translated = .ok env` for the complete translated stream, including all generated auxiliaries and pending checks.
5. **Source semantic meaning:** the target model induces a model of the original canonical environment, and the source contradiction/query maps to the intended target empty proposition. A target-model theorem alone is not this claim.
6. **Execution:** the source-to-generated-checker semantics or its explicit trusted compiler/runtime assumptions. Compilation and vectors are useful empirical checks, not the missing preservation theorem.

A first wrapper theorem can be deliberately narrower: “this wrapper's success yields a con-leche model of these translated declarations.” That is useful and relatively direct by case analysis on the wrapper and `model_exists`. Name it **target-model preservation** until layers 2–5 are established; do not call it PSC1 canonical consistency.

Use a Lean subtype/structure whose success is constructed from the actual checker equation, or the existing upstream `FullyChecked` interface. An externally supplied JSON `accepted: true`, copied receipt or erased JavaScript field must never construct this authority. Host-controlled modes and checker identities remain required.

For an initial diagnostic export, official Lean may replay the original canonical stream and expose generated recursor metadata. This is allowed in the explicitly labeled reference experiment. It would be a hidden fallback if used inside a supposedly standalone `min` acceptance path. The eventual minimal executable must independently construct/check the required data, with its bridge proved.

## 6. Direct model extension: credible work and traps

The STLC proof's `Denote : PsMinTy -> Type` cannot simply add arbitrary `Sort`, dependent Pi, polymorphic inductives and definitional equality. A semantic type universe, dependent environments/substitution and conversion-preservation invariants are needed. Full symbolic universe parameters introduce an unbounded valuation problem absent from STLC; adding a small finite tag does not solve it.

Two credible semantic strategies to investigate are:

- A **bounded universe/profile** model, if the actual accepted declarations can be restricted accordingly, with an explicit theorem justifying every permitted instantiation. Checking only some ground uses of a universally parameterized source declaration is not admission of that declaration.
- A **graded/annotated set model** following con-leche's proof idea: coherent binder-sort annotations make a total semantic interpretation and preservation arguments possible. Reuse ideas or licensed lemmas with attribution, but prove the new executable checker’s annotations/acceptance bridge. A theorem for con-leche's separate whitepaper fragment is not automatically that bridge.

Do not assume syntactic preservation, normalization, decidable conversion or an arbitrary general inductive metatheory will be easy. Choose the semantic invariant first and require a proof for the actual rule before expanding acceptance. Omit caches initially; after a correct baseline, prove cached acceptance refines it.

A useful direct-model pilot should admit a **real selected canonical family**, including its generated declarations and relevant foundation, not merely add another STLC constructor. Select the smallest dependency-closed family from the artifact inventory. Candidate families to compare are a record/projection group and a List/Option-style strictly positive family with the actual recursor motive. If a restricted nondependent recursor is used, report that restriction and do not claim coverage of the general source recursor declaration.

The first success criterion is one complete new semantic admission slice with a passing theorem and negative cases. A growing pile of unproved dependent checker code is a failed experiment, even if it parses many compiler declarations.

## 7. Selected PSKernel-Core reuse

The active [portable source root](https://github.com/dwijayuda/pskernel/blob/d6bebd230bcaadf35a254bfbc5a26a17228db55f/psc1/packages/pskernel-core/src/Ps/KernelCore/SelfHost.lean) contains 79 canonical source modules, **827,143 source bytes** at the inspected package tree. It is closer to PSC1's source profile than con-leche, but not a completed consistency proof. The [TCB inventory](https://github.com/dwijayuda/pskernel/blob/d6bebd230bcaadf35a254bfbc5a26a17228db55f/psc1/packages/pskernel-core/PSKERNEL_TCB.json) explicitly marks its semantic closure trusted and its caches/indexes invariant-tested, not formally proved.

The actual [target identity](https://github.com/dwijayuda/pskernel/blob/d6bebd230bcaadf35a254bfbc5a26a17228db55f/psc1/packages/pskernel-core/src/Ps/KernelCore/API/KernelContractV1.lean) is Lean 4.35.0 at `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`; several historical architecture/contract documents still discuss 4.34. Treat those as evidence to reconcile, not authorization to restore historical native reduction. The current public provider disables that capability.

Prioritize reusable owners in this order:

1. `Core/Name.lean`, `Core/Level.lean`, `Core/Expr.lean`, `Core/Substitution/*`: prove representation, equality and substitution lemmas for the **actual functions**.
2. `Checker/Inference/Core.lean` and restricted reduction/projection/recursor rules: relate them to the chosen model under explicit environment invariants.
3. [`Checker/Knot.lean`](https://github.com/dwijayuda/pskernel/blob/d6bebd230bcaadf35a254bfbc5a26a17228db55f/psc1/packages/pskernel-core/src/Ps/KernelCore/Checker/Knot.lean): prove the fuel/callback induction and full-check versus infer-only obligations for every participating entry point.
4. [`Admission/Declaration/Validation.lean`](https://github.com/dwijayuda/pskernel/blob/d6bebd230bcaadf35a254bfbc5a26a17228db55f/psc1/packages/pskernel-core/src/Ps/KernelCore/Admission/Declaration/Validation.lean) and [`Admission.lean`](https://github.com/dwijayuda/pskernel/blob/d6bebd230bcaadf35a254bfbc5a26a17228db55f/psc1/packages/pskernel-core/src/Ps/KernelCore/Admission/Declaration/Admission.lean): prove environment extension, including the restricted axiom policy.

The existing generic `psKernelAddAxiom` checks a type and then installs the axiom. That is valid for a general-purpose kernel, but is not a consistency-preserving policy for arbitrary inputs. A consistency-qualified restricted wrapper must admit only a modeled foundation/realized declarations, and its theorem must consume that wrapper's actual acceptance. Merely selecting the existing public API does not discharge the axiom problem.

Do not begin by copying all ordinary/mutual/nested-inductive admission and all DefEq shortcuts. Those are large semantic commitments. If code is copied into the research package, record exact originating commits and establish a single maintained semantic owner or a reproducible generated subset. Avoid a second drifting hand-maintained kernel. Historical conformance/fixed-point receipts and proof work on different branches do not prove this selected executable subset.

## 8. Minimal Linux Actions experiments and stop/go criteria

Create separate manual/branch-scoped experiment jobs; do not broaden production authority. Preserve failure artifacts. Pin repository commits, Lean, Node/TypeScript and any dependency sources. Collect cold build/size data separately from steady-state checker timings.

| Experiment | Concrete work | Go criterion | Stop or change direction |
| --- | --- | --- | --- |
| E0: refresh baseline | Rebuild existing proof and vectors at fresh HEAD; re-run current compiler/foundation audit; retain original and transformed strict IR identities | Existing milestone remains green, exact receipts complete | Repair baseline first; do not hide drift in an extension |
| E1: classify real obligations | Build per-declaration dependency/SCC inventory from canonical compiler plus all prelude records; distinguish direct/transitive axiom use; classify recursor/projection/level forms and actual used conversion rules | A smallest real pilot graph and named feature/foundation obligations, tied to hashes | Syntax counts alone cannot select a sound profile; no “unused axiom” deletion |
| E2: pin upstream theorem | In an isolated full-Lean proof project, depend on exact con-leche pin, import `MainTheorem`, prove the thin target-model wrapper, print axioms and run upstream trust/layering gates relevant to the built executable | Native wrapper theorem and exact dependency/TCB record pass on v4.35.0 | Any modified axiom gate, `Challenge` import, new arbitrary axiom or `sorry` is a stop |
| E3: literal translation probe | Translate a bounded real pilot stream structurally, without deleting/replacing foundation declarations; retain target records and every decline reason | Reproducible mismatch taxonomy confirms what translation alone can and cannot do | Expected arbitrary-axiom/String/recursor declines are findings, not reasons for permissive fallback |
| E4: one foundation realization | Choose the first blocking family from E3; construct checked witnesses/inductives/definitions and prove source-signature plus computation correspondence; include original/realized identities separately | Actual target checker accepts the pilot and the realization/identity theorem passes | If only signature inhabitation or test parity is achieved, the source consistency bridge remains incomplete |
| E5: direct-model pilot | For the same real pilot, implement only required restricted rules and prove actual acceptance-to-model; selectively reuse Core utilities where this reduces proved code | Complete new slice theorem, nonvacuous accepted examples and malformed/invalid/unsupported negatives | Expanding acceptance faster than proof coverage is a stop; prefer a smaller complete slice |
| E6: source-profile feasibility | In Actions, probe precise upstream/runtime source constructs against current PSC1; record generated-module and pin assets; assess whether a proved extraction/refinement is required | Concrete portable runtime plan with bounded source closure and named proof obligations | Native con-leche success is not PSC1 self-hostability; unproved stripping/porting cannot satisfy this gate |
| E7: choose and document | Compare E4/E5/E6 proof results, covered real declarations, source/build/generated size, timings and trust assumptions | Written decision chooses a verified extension path and exact next slice | If neither path has the bridge, keep min/dual refusing and document the unresolved mathematics; do not claim full kernel completion |

Use the [pinned Kernel Arena cases](https://github.com/leanprover/lean-kernel-arena/tree/bbd9636b9c667f57c4f4d78c05f8813ef6afeeac/tests) only when the pilot supports their declared features. Relevant failures include incorrect universe arity/imax, forged recursor K/rules, missing induction hypotheses and non-structure projections. Declining an unsupported case is correct. Arena fixtures, official-Lean parity and randomized tests supplement the proof; they do not replace it.

Benchmark the **same canonical graph and realized profile** on each checker. A native official source-admission time, a generated STLC vector loop and a con-leche whole-Init replay are different workloads and must not be divided into a “speedup” number. Report parser/translation/foundation setup/checking separately, with cold/warm timings, payload/source/dependency sizes, memory and timeout/refusal counts. WHNF/DefEq rule-hit profiling must identify instrumentation and commit; do not infer it from Expr tags.

## 9. Acceptance gates after an architecture is chosen

Before enabling any successful canonical `min` or `dual` response, require the exact supported profile, modeled foundation, identity-preserving decoder/translation and executable acceptance theorem. Unsupported input must reject/decline explicitly. Source metadata may not grant authority. Keep official Lean Wasm as default; native/Wasm official compatibility and compiler-Wasm GC versus official Emscripten linear-memory architecture remain unchanged.

Then require the generated minimal checker to check the **entire current compiler executable source closure**, with fallback/cached-receipt bypass disabled and the real generated checker identity retained. Only after that gate should genuine G1/G2/G3 runs attempt the existing exact fixed-point criteria. Keep current-source and frozen-release results separate. The checker compiling as a PSC1 program, target-checker agreement on a pilot, and one complete semantic theorem are distinct milestones.

Every continuation batch should leave: exact parent/implementation SHA, files and theorem names, printed axioms and hypotheses, accepted/refused domain, source and generated hashes, terminal Linux CI links, unresolved proof obligations, and the next minimal command/job. A future model should be able to resume without guessing what was proved or silently broadening the profile.

## 10. Auxiliary upstream choices

[`con-ron` at 053ceb8803a870fbb972caa665c84f786294e899](https://github.com/leanprover/con-ron/tree/053ceb8803a870fbb972caa665c84f786294e899) is Apache-2.0 and offers a real Lean-twin/Aeneas Rust-refinement chain. Its [capstone assumptions](https://github.com/leanprover/con-ron/blob/053ceb8803a870fbb972caa665c84f786294e899/OVERVIEW.md#31-what-the-theorems-assume) retain driver-order, byte-source/worker-coverage, translator, external-model and execution assumptions; embedded-pin variants have an additional constant-definition axiom. It is a useful diversity/reference option, not a PSC1-generated Rust correctness theorem. Reusing its Rust implementation does not put its source in PSC1's self-hosting cycle.

[`lean4lean` at 67f63b0c818920dfaed2ad07ccff187a6a8fe1e3](https://github.com/digama0/lean4lean/tree/67f63b0c818920dfaed2ad07ccff187a6a8fe1e3) is Apache-2.0 and provides implementation-to-syntactic-theory work, but do not conflate that with the separate unfinished model-consistency target. Its C++ derivation and current version-specific differences need review before treating it as an independent oracle. These alternatives are references to compare after the named bridge obligations are understood, not shortcuts around them.
