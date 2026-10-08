# PSC0 self-host language: findings and decisions

Status: historical research baseline with a working implementation, 2026-10-08. The bounded recursion capability is compiler-qualified at `e91b9558d665879871b8bf0893915ae64b27c7fe`, and its exact admissions passed the pinned provider. Foundation.List at `70d6010ddccbdd6b4939f2fb3c088bfe4e607de0` has passed its own C2/C3 fixed point and exact-stream provider acceptance in run 37840481558. [IMPLEMENTATION.md](IMPLEMENTATION.md) documents the implemented commands and boundaries; [qualification-evidence.json](qualification-evidence.json) records exact results. Strict runtime profile enforcement remains pending.

The audit and its source citations below describe the immutable baseline, not a claim that implementation is still absent. Later implementation evidence is recorded separately; the historical 55-module inventory remains unchanged.

Baseline: `dwijayuda/pskernel@37f63c39d4a07189938046c64152bba25d789450`, specifically `psc0/`. The later `pscv0/` implementation was not used as evidence of capabilities present in PSC0.

## Decision

Adopt one proposed authoring contract, **PSC0-SH/1**, implemented by the portable PSC compiler and initially written in the existing PSC1-compatible `.lean` syntax. Keep the old canonical `.ps` representation and the historical seed reproducible while the compiler learns to normalize ordinary structural recursion with changing state. Add further conveniences only after their complete path through parsing, lowering, elaboration, admission, erasure and generated execution is demonstrated.

This is a bounded PSC implementation language, not a second general-purpose compiler project. The current handwritten worker/closure encodings should become compiler implementation details. The practical bottlenecks are frontend recognition and bootstrap discipline; the names of the profiles do not themselves solve either problem.

Read [SPEC.md](SPEC.md) for the proposed language and lowering obligations, [MIGRATION.md](MIGRATION.md) for the implementation sequence and development workflow, [proposal.json](proposal.json) for the machine-readable capability plan, and [baseline-evidence.json](baseline-evidence.json) for the immutable source inventory.

## 1. Correct the premise for this directory

PSC0's root configuration and original 12-package compiler closure do **not** select `PSC1-selfhost-stable/1` or `PSC1-portable-selfhost/1`. Its root has neither corresponding profile manifest. Its configuration says implementation `PSC1`, accepted language `PSC2-bootstrap`, version `0.7`, with `Ps.Bootstrap.SelfHost` as entry.[CFG]

There is an important exception in the same directory: the copied JS, Rust and Wasm package manifests explicitly declare `PSC1-portable-selfhost/1`, while marking themselves `bootstrap:false`. These metadata came with the later packages; they are not evidence that the old PSC0 compiler implements that profile or includes those packages in its fixed point.[MANJS], [MANRS], [MANWASM] This mixture of an older compiler and newer copied packages makes the profile labels particularly confusing.

PSC0 nevertheless has the same underlying kind of restriction: its own parser, elaborator, recursion recognizer, primitive prelude and backend cover less than the host Lean compiler. Being valid PSC1-compatible Lean source, or passing a broad forbidden-API check, is insufficient to establish that the generated PSC compiler can consume that source.

The architecture already describes the right bootstrap discipline: implement new language features in the previous stable implementation language, dogfood them after a fixed point, and initially keep handwritten `.lean` authoritative while `.ps` is generated. Changing source authority is explicitly a later source/semantic/self-host parity decision.[A]

### The preserved baseline

| Item | Evidence at the pinned commit |
| --- | --- |
| Entry closure | 55 modules, 127 import edges, 12 bootstrap package groups |
| Handwritten closure size | 25,484 lines and 950,480 Git blob bytes |
| Full source inventory in those 12 packages | 60 source modules; five are outside the entry closure |
| Historical declaration count | 1,916, from the October 3 receipt |
| Historical lane | Compiler-only PSC source and TS/JS fixed point |
| Current generated backend in that closure | TypeScript, compiled by TypeScript 5.8.3 to JavaScript |
| Source provenance | All 12 whole-package Git trees exactly match historical `d4298a7...` |
| Kernel claim | A new checked current-source fixed point is not established by those preserved source identities |

The graph and size figures were computed from GitHub source and tree objects, not from a compiler run. Lines include comments and blank lines, excluding the phantom empty line after a terminal newline. Bytes are Git blob sizes, not JavaScript string lengths. The historical hashes and declaration count come from the existing receipt.[R], [S], [C] The five excluded source files are explicitly recorded in the JSON inventory; in particular, `CompilerIr/Specialize.lean` being present does not make it part of the 55-module bootstrap.

| Package | Modules in entry closure | Source lines |
| --- | ---: | ---: |
| foundation | 3 | 188 |
| syntax | 12 | 7,836 |
| bridge | 2 | 2,023 |
| core | 8 | 899 |
| environment | 7 | 2,069 |
| meta | 6 | 1,967 |
| elab | 4 | 4,784 |
| compiler-ir | 1 | 254 |
| erasure | 6 | 3,693 |
| compiler | 1 | 231 |
| backend-ts | 4 | 1,535 |
| bootstrap | 1 | 5 |

These are closure totals, not the total size of the repository or all copied packages.

The closure's declaration inventory contains **1,205 ordinary defs, 47 inductives and 100 structures**, with zero partial definitions, theorems or axioms. A lexical token inventory outside comments/strings also finds no direct Array, fixed-width integer or floating-point type uses; Nat and Int remain required. These are source-inventory facts, not the historical elaborated declaration count. Compiler strings and generated target code do mention arrays/machine types: implementation-language restrictions must not remove the compiler's ability to compile those user programs.

## 2. Why ordinary source fails

### 2.1 A small owned frontend is doing the work

The syntax AST has definitions, partial definitions, theorems, inductives and structures. It has typed lambda binders and flat constructor patterns. It has no general source declaration for classes or instances, no arbitrary macro expansion system, and no recursive pattern tree. The presence of instance synthesis modules does not create source syntax that the parser lacks.[AST]

PSC0's `.ps` parser uses `def`, `partial def`, `theorem`, `inductive` and `structure`; definitions require a final semicolon. Its call parser distinguishes adjacent `f(` and even rewrites empty `f()` to application to Unit. A later `function`/brace-oriented PSC syntax must not be pasted into this codebase and described as an already accepted language.[PP], [PARSECALL]

This is an implementation boundary, not a fundamental requirement that a self-hosted language be awkward. An ergonomic surface can compile into a much smaller core.

### 2.2 Recursion recognition enforces a handwritten normal form

`psElabStructuralRecursionFromSource` discovers recursion only when the declaration body is directly a match on a named explicit parameter. A let or other wrapper around the match can prevent discovery. It does not perform Lean's general recursion elaboration.[DECL]

`psElabValidateStructuralCallWorker` requires the recursive argument to resolve to a registered smaller field and every other explicit argument to resolve to the same original local variable. An incremented index, updated accumulator, rebuilt context, or other expression in those positions raises `structuralRecursionInvariantArgument`. Calls also have to match the recorded explicit arity.[TERM]

Consequently, an ordinary operation shaped like `scan tail (index + 1) updatedState` is often written as a structurally recursive worker returning a function, followed by application to changing state. PSC0's own validator uses exactly that technique: it recurses over the argument list, returning a function of context, recursion state, index and hypothesis state, then applies those values after obtaining the smaller result.[TERM]

The existing list library demonstrates that this is a usable encoding: reverse, append, take and zip already use function-valued recursion. It also already provides map, mapExcept, length and any; there is no need to invent a new walker for every call site.[LIST]

**Root cause:** the current elaborator makes authors perform a transformation that a bounded compiler pass can perform systematically. Generalizing changing parameters into the recursion motive is the highest-value first language improvement.

### 2.3 Recognition guards have become refactoring constraints

The broad source checker masks strings/comments and rejects host-dependent APIs and unsupported commands. That is useful policy, but it does not prove parse, elaboration or runtime support.[CHECK]

Separate function-specific scripts check exact text: a particular worker signature, helper names, typed lambda spellings, an identifier called `smaller`, and explicit Option constructors. One gate explicitly rejects changed-index recursion and even shorter constructor spelling. Another requires a private reverse helper and rejects ordinary reverse calls.[G], [G2]

These scripts preserved known working source during bootstrapping. They also make routine refactors fail independently of semantics. Deleting them first would lose evidence; keeping them permanently would undermine the new language. Replace each family only after reusable capability checks and focused positive/negative semantic fixtures cover its actual invariant.

### 2.4 Syntax acceptance is only the first boundary

A source term must also fit the prelude, elaborator, proof admission protocol, erasure and runtime representations. The core can contain type-level material that does not have an executable representation. Conversely, the IR enum can list a primitive without establishing support for every operation or every backend.

PSC0 returns a raw `PsVerifiedIrModule` after erasure. It has no later `PsValidatedIrModule` wrapper on this path, and TS prints `.unknown` as TypeScript `unknown`.[API], [IR], [TYPE] The class name “Verified” must not be treated as evidence that all runtime invariants have been independently checked.

SH/1 therefore needs an explicit post-erasure capability check, first in report mode against the old closure and then enforced for newly promoted source. It should verify scopes, arities, constructor/record layouts, supported primitive signatures and absence of unresolved runtime types. It must retain legitimate scoped type parameters; generic programming is not the same as an unresolved type.

### 2.5 Portable does not mean “every copied backend already works”

The newly copied JS, Rust, Wasm and kernel-core packages are outside the first bootstrap closure. The original IR lacks wrapper types and entry points referenced by those newer backends. Examples include `PsValidatedIrModule`, `PsSpecializedIrModule`, `PsUniformSpecializedIrModule`, `Ps.CompilerIr.Validate`, and the JS printer's `Ps.Foundation.Text`. The Lake configuration and source resolver also do not integrate them as a coherent PSC0 backend set.[JSLOWER], [JSP], [WASMLOWER], [RSMOD], [LAKE]

The correct first target remains the original TS-to-JS lane. Cross-backend conformance is an additional, explicitly earned target capability. Do not shrink the language to the accidental intersection of incompatible copied code, or import the entire later IR architecture merely to rename a profile.

## 3. Why iteration is expensive

### Current commands are coarser than the desired workflow

`build:psc` really does read the current handwritten entry, emit a `.ps` workspace, emit a Lean replay, then compile the generated workspace. It is more useful than blindly reusing an old dist tree. It does **not** run the resulting candidate compiler on its own current source or prove equality between candidate generations.[BUILD]

`selfhost-generation.mjs` also unconditionally emits Lean replay. The top-level `fixed-point` script starts with the full bootstrap chain, and nested scripts repeat source/closure checks. `compare-selfhost.mjs` compares the two paths supplied to it; the configured compiler comparison is TS equality, not a general all-artifact proof.[GEN], [PKG], [COMPARE]

There is no current-source resident compiler/session cache or start/step/finish preparation API on main PSC0. The driver requires aggregate `psCompilerPrepareSources` and imports a compiler for an invocation. `build:auto` only checks whether the expected generated JS file exists; it does not authenticate its source provenance. `clean` deletes dist. An immutable, recoverable seed must live outside mutable dist or be fetched by digest.[DRIVER], [AUTO], [CLEAN]

### Module invalidation requires more than import edges

The compiler prepares an ordered list of sources with a shared environment and a reverse declaration accumulator. A changed early declaration can affect later elaboration, reduction, resolution or generated names. Rebuilding only direct reverse importers is not automatically safe.[API]

An initial incremental implementation should cache parsing per source and resume preparation from the first changed module. It should invalidate the semantic suffix until equality of the complete incoming state is established. That state includes environment, declaration accumulator/provenance, prelude, source kind, compiler implementation identity and relevant limits. Dependency-driven finer invalidation can follow once actual semantic dependencies are recorded.

### Native checking is a separate performance workstream

On main, the old `--kernel pskernel-core` route imports a legacy generated provider, not the newly copied kernel-core source.[WORKER], [IDENTITY] An active branch, `psc0/native-core-selfhost-v1`, is implementing native integration. At the inspected `b109be0...` snapshot, its checked fixed-point workflow failed full-corpus acceptance; passing bounded provider tests did not establish a checked full compiler.[NATIVE], [RUN]

That branch already has a 12-package source-tree lock, an opt-in fast path, scoped CI and Lake caching. Its fast path skips broad regression only when the preserved package trees match; it still runs the checked pipeline. It is not a cache of provider acceptance, and its tree lock alone does not cover host/config/provider/toolchain identity. Reuse its accepted work instead of duplicating it in the language branch.[NATIVELOCK], [NATIVECHECK]

A reduction-budget failure is not evidence that changing PSC source syntax will solve kernel performance. The language plan can proceed with parser, elaborator and TS evidence while provider correctness/performance work remains explicit.

## 4. What should actually become simpler

The core SH/1 goal is ordinary total compiler code:

- Explicitly typed public definitions; inferred locals and expected-type lambda parameters where unambiguous.
- Algebraic data types, structures, pattern matching and rank-1 parametric helpers.
- Structural recursion on one designated constructor field or predecessor, with independently changing ordinary value parameters.
- Pure state records and explicit Except/Option results.
- A small shared foundation library and explicit runtime semantics.

It does not require arbitrary Lean metaprogramming, source type-class authoring, unrestricted recursion, runtime dependent values, host IO, mutable references, or all backends at once. These have much larger elaboration/runtime surfaces and are not prerequisites for implementing this compiler.

The minimal promotion unit is the accumulator-recursion capability. Nested patterns, expected-type lambdas and constrained effect syntax are separately gated capabilities under the same language family. This avoids creating several competing dialects or making all convenience work block the first useful improvement.

## 5. Efficiency: distinguish four outcomes

| Outcome | Primary intervention | Evidence required |
| --- | --- | --- |
| Less authoring/refactoring effort | Compiler-owned normalizer and shared helpers | Fewer handwritten worker adapters and shape guards; actual migrated functions |
| Lower edit/build latency | Stage-aware checks, current-source provenance, preparation snapshots | Cold/no-change/leaf/core edit timings and recomputation counts |
| Faster checked acceptance | Native provider work and honest admission caching | Full corpus acceptance, exact provider identity and measured phase timings |
| Faster generated compiler | Preserve/extend existing TS optimizations after profiling | Same semantics, emitted optimization shape, runtime and memory measurements |

PSC0 already tries count-loop and monomorphic tail-loop emission before its general generator path. The tail-loop route excludes generic declarations. Its general execution uses a trampoline; the source's closure-shaped worker alone does not prove JavaScript call-stack growth.[MOD] Arrays also currently copy on push and update.[EXPR]

Accordingly, neither “replace workers with normal recursion” nor “replace lists with arrays” is a justified speed claim. Preserve existing loop opportunities, measure which functions miss them, and optimize demonstrated hot paths after semantic migration.

## 6. Research basis and limits

Lean's documentation explains how structural recursion becomes recursor applications; a small source recognizer is a choice, not a requirement that authors expose recursors themselves.[LEAN] Lean's compiler also uses a distinct lower representation to make transformations practical while retaining useful runtime typing.[LCNF]

Rust's bootstrap guide distinguishes development-stage builds from later same-result tests and ties source feature use to what the bootstrap compiler understands.[RUST] Its incremental guide motivates dependency tracking and checking whether recomputation actually changed a result.[INC] These are design precedents, not claims that PSC0 already implements Lean's recursion machinery or Rust's query engine.

This investigation used GitHub source/tree/history/workflow reads and primary compiler documentation. No local checkout, build, compiler execution, benchmark, CI dispatch or new fixed-point run was performed. The proposed files are a reviewable solution specification; their existence is not language support or performance evidence.

[A]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/ARCHITECTURE.md
[R]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/README.md
[S]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/STATUS.md
[C]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/docs/continuity/COMPILER_FIXED_POINT_2026-10-03.md
[CFG]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/psconfig.json
[AST]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/syntax/src/Ps/Syntax/Ast.lean
[PP]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/syntax/src/Ps/Syntax/ParseProofScript.lean#L1229-L1302
[DECL]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/elab/src/Ps/Elab/Declaration.lean#L56-L102
[TERM]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/elab/src/Ps/Elab/Term.lean#L2706-L2824
[G]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/scripts/check-elab-validate-structural-call-selfhost-source-syntax.mjs#L32-L70
[G2]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/scripts/check-elab-declaration-structural-recursion-selfhost-source-syntax.mjs
[CHECK]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/check-psc1-source.mjs
[LIST]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/foundation/src/Ps/Foundation/List.lean
[API]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/compiler/src/Ps/Compiler/Api.lean
[IR]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/compiler-ir/src/Ps/CompilerIr/Model.lean
[TYPE]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/backend-ts/src/Ps/BackendTs/Type.lean
[EXPR]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/backend-ts/src/Ps/BackendTs/Expr.lean
[MOD]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/backend-ts/src/Ps/BackendTs/Module.lean
[BUILD]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/scripts/build-current.mjs
[GEN]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/scripts/selfhost-generation.mjs
[PKG]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/package.json
[COMPARE]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/scripts/compare-selfhost.mjs
[WORKER]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/scripts/checked-owned-kernel-worker.mjs
[IDENTITY]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/scripts/checked-kernel-identity.mjs
[AUTO]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/scripts/build-auto.mjs
[CLEAN]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/scripts/clean.mjs
[DRIVER]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/scripts/compile-with-generated.mjs
[NATIVE]: https://github.com/dwijayuda/pskernel/tree/b109be0075630dd17b791e3b0c5fcad016df53e8/psc0
[RUN]: https://github.com/dwijayuda/pskernel/actions/runs/37823400738
[LEAN]: https://lean-lang.org/doc/reference/latest/Definitions/Recursive-Definitions/
[RUST]: https://rustc-dev-guide.rust-lang.org/building/bootstrapping/what-bootstrapping-does.html
[INC]: https://rustc-dev-guide.rust-lang.org/queries/incremental-compilation-in-detail.html
[LCNF]: https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/Lean/Compiler/LCNF/Types.lean
[MANJS]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/backend-js/package.json
[MANRS]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/backend-rust/package.json
[MANWASM]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/backend-wasm/package.json
[PARSECALL]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/syntax/src/Ps/Syntax/ParseProofScript.lean#L122-L175
[JSLOWER]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/backend-js/src/Ps/BackendJs/Lower.lean#L1575-L1618
[JSP]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/backend-js/src/Ps/BackendJs/Print.lean
[WASMLOWER]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/backend-wasm/src/Ps/BackendWasm/Lower.lean#L1-L3
[RSMOD]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/backend-rust/src/Ps/BackendRust/Module.lean#L1265-L1268
[LAKE]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/lakefile.lean
[NATIVECHECK]: https://github.com/dwijayuda/pskernel/blob/b109be0075630dd17b791e3b0c5fcad016df53e8/psc0/scripts/checked-selfhost.mjs
[NATIVELOCK]: https://github.com/dwijayuda/pskernel/blob/b109be0075630dd17b791e3b0c5fcad016df53e8/psc0/scripts/selfhost-baseline.mjs
