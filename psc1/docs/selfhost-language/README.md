# PSC0 self-host language: findings and decisions

## Current strict SH/1 disposition

The declared bounded PSC0-SH/1 source, runtime and TypeScript target are qualified at [compiled source `1fa5559a72b293defc56ef7e7020cf82d4b44b79`](https://github.com/dwijayuda/pskernel/commit/1fa5559a72b293defc56ef7e7020cf82d4b44b79). The [release qualification record](strict/release-qualification.json) binds the exact compiler evidence, eight independently reviewed source and composition argument packets, all **33 correspondence dispositions** and **27 stage dispositions**, and separate provider acceptance.

[Original run 38015134511](https://github.com/dwijayuda/pskernel/actions/runs/38015134511) remains cancelled; it owns the retained completed native/N1/C1 evidence and named successful prerequisite gates. [Continuation 38021634599](https://github.com/dwijayuda/pskernel/actions/runs/38021634599), orchestrated at `43fa000c4adbc9d4754e20c213595c1449f00961`, completed C2/C3 and their conformance gates using the same compiled source and unchanged 48-file recipe, then failed on native IR pass-marker extraction in the evidence binder. Its failure and skipped provider remain recorded.

[Evidence-completion run 38027413274](https://github.com/dwijayuda/pskernel/actions/runs/38027413274), orchestrated at `719f5ec4225baf51d1969cc3b5e4cbc6959fad4a`, authenticated both archives and all 446 imported files, applied the reviewed `slice(pass.length)` binder correction as a separate evidence producer, and completed the original qualification construction without rebuilding any generation or repeating conformance. The compiled checkout and its original 48 recipe inputs remained unchanged. Compiler job `114141103218` completed evidence binding and the complete 135-file catalog with 24 exact returned JSON values. Independent provider job `114141265302` accepted all four deduplicated admission streams covering eight C2/C3 roles. The complete four-product C2/C3 tuple matches, and N1/C2/C3 TypeScript and JavaScript agree. Final 33/27 dispositions are explicitly bound to these exact receipts and their declared source arguments in the release record.

Qualification applies to the explicit `psCompilerSh1TypeScriptSources` entry and the recorded strict development/qualification lane. Generic compiler APIs do not implicitly select strict SH/1, and `selectedByPsconfig` remains false. Reviewed source arguments retain their declared canonical-input, primitive, platform and successful-allocation premises. Finite conformance, original-IR typing, fixed-point equality and provider admission retain their separate meanings; `generalPreservationProven` and the original narrow producer flags remain false.

R remains selected. Handwritten `.lean` remains authoritative through the owned frontend, current `.ps` uses only the `ps-0.9-r3` bounded subset, and current development/recovery uses TypeScript 7.0.2. Node 22.23.3, Lean 4.34.0 and the independently pinned provider are unchanged. Earlier attempt requests and pending statuses below describe their recorded historical checkpoints; they do not restart completed work. The linked release record defines the current strict disposition.

## Earlier research and practical checkpoints

Initial F application: [`9ee0b1fd38dd1456a187d4675f9027440a989f2d`](https://github.com/dwijayuda/pskernel/commit/9ee0b1fd38dd1456a187d4675f9027440a989f2d). This is the initial attempt identity; any qualifying revision and its evidence are recorded separately below.

Start with [CURRENT.md](CURRENT.md) for the current source forms, daily commands,
qualification boundary and remaining limits. This file retains the research
baseline and its evidence.

Historical practical status, recorded 2026-10-09: R2's new-only grammar and parameter-projection repair
are **compiler-qualified and independently provider-accepted**. Cold source
recovery is verified, and the exact R successor is explicitly selected by
[selection commit e65606397fb679d7cb96f4f0e92700a6cf0944a6](https://github.com/dwijayuda/pskernel/commit/e65606397fb679d7cb96f4f0e92700a6cf0944a6).
The finite F source migration is **compiler-qualified and independently
provider-accepted** at `fcd875c8f38db4b0524090bd10c7c2fd5024053d`, with its own [F run 37947341800](https://github.com/dwijayuda/pskernel/actions/runs/37947341800).
R remains the authenticated selected authoring seed. The chosen practical-v1
source migration is complete; broader language and strict-profile work remain separate.
Foundation.List B, helper migration H and recursive generic-erasure repair E
retain their original qualification receipts. The M6 portable runtime IR checker
and current TypeScript 7.0.2 integration are now separately qualified, including
their exact-stream provider checks. Full strict SH/1 and profile activation
remain separate unfinished contracts.

The earlier completed TypeScript 7 integration source is
`99786185f77edf952f11989d4c9bc44028f22f11`
([run 37910429506](https://github.com/dwijayuda/pskernel/actions/runs/37910429506)).
Its portable M6 implementation was independently qualified under TypeScript
5.8.3 at `1b5fd12382c920944924c9d03e0851984293caa2`
([run 37906602597](https://github.com/dwijayuda/pskernel/actions/runs/37906602597)).
Current PSC0 and repository-root development use TypeScript 7.0.2. Selected-R
cache-miss recovery uses the separately proven native Lean plus TypeScript 7
route. S0/A's original TypeScript 5.8.3 identities and recipes remain archived
evidence. [TYPESCRIPT7.md](TYPESCRIPT7.md) records the active commands and proof
boundaries; [TYPESCRIPT7_CHECKPOINT.md](TYPESCRIPT7_CHECKPOINT.md) preserves the
earlier two-toolchain measurements.

[IMPLEMENTATION.md](IMPLEMENTATION.md) documents installed behavior and commands;
[qualification-evidence.json](qualification-evidence.json) records exact results.
The audit and its source citations below describe the immutable baseline. Later
implementation evidence is separate; the historical 55-module inventory is unchanged.

The implementation accepts bounded ordinary-parameter recursion and has migrated
Foundation.List plus three compiler helpers. E repaired ordered generic arguments
in recursive erasure. M6 now checks complete current IR compositionally and checks
the same IR before emission. E's historical 244 unfinished call-expression typing
obligations remain evidence of that earlier inventory; current portable reports
have their own accepted/completeness results and identities.

Baseline: `dwijayuda/pskernel@37f63c39d4a07189938046c64152bba25d789450`, specifically `psc0/`. The later `pscv0/` implementation was not used as evidence of capabilities present in PSC0.

## Decision

Keep **PSC0-SH/1** as the bounded authoring capability contract, implemented by the portable PSC compiler with handwritten PSC1-compatible `.lean` still authoritative. The current `.ps` frontend and canonical printer move together to the **new-only `ps-0.9-r3` bounded self-host subset**. Current `.ps` source must use that edition; there is no legacy parser mode. Historical S0/A source, toolchains and artifacts remain recoverable at their immutable revisions. Ordinary structural recursion with supported changing state is already qualified. Grammar/projection checkpoint R and source migration F each require their own exact-source evidence; F does not select or qualify its prerequisite seed.

This is a bounded PSC implementation language, not a second general-purpose compiler project. The current handwritten worker/closure encodings should become compiler implementation details. The practical bottlenecks are frontend recognition and bootstrap discipline; the names of the profiles do not themselves solve either problem.

Read [SPEC.md](SPEC.md) for the language contract and remaining obligations, [MIGRATION.md](MIGRATION.md) for completed milestones and the development workflow, [RUNTIME_IR_PLAN.md](RUNTIME_IR_PLAN.md) for the installed checker and remaining strict contracts, [proposal.json](proposal.json) for the capability ledger, and [baseline-evidence.json](baseline-evidence.json) for the immutable source inventory.

## Current source grammar checkpoint

The source grammar change follows the user's explicit new-version-only decision. [PS_GRAMMAR_ADOPTION.md](PS_GRAMMAR_ADOPTION.md) pins the supplied reference by SHA-256, records its internal errata and maps the implemented subset to the reference. The current configuration records `languageVersion: 0.9-r3` and a `sourceGrammar` identity with edition `ps-0.9-r3`, mode `new-only`, support `bounded-selfhost-subset` and the supplied reference digest.

The checkpoint replaces semicolon sequences with newline sequences, uses a single typed comma group in declaration and constructor headers, retains native typed lambda binder sequences, and preserves adjacent call groups separately from whitespace applications. It supports annotated parameterless `const` and positive-arity `function` aliases. `f()` remains an explicit empty call in the syntax tree and is refused during elaboration until completion semantics are implemented; `f(())` passes Unit. General `do`, omitted required annotations, defaults, named arguments, tuples and unsupported source constructs fail closed. The canonical printer and active fixtures change in the same checkpoint.

R2 source `fe2560aba0f347b1caf8d000d371464642d44f23` passed compiler qualification in [run 37925722635](https://github.com/dwijayuda/pskernel/actions/runs/37925722635) and separate exact-stream provider acceptance. Its 61-module captured closure passed the new-PS canonical round trip, and all four declared C2/C3 products agree. [IMPLEMENTATION.md](IMPLEMENTATION.md#r2-compiler-and-provider-evidence) records the exact source/closure and jobs. Cold recovery is verified by [its exact receipt](grammar-migration-cold-recovery.json), SHA-256 `2aa93517b848da1493386ab9be50527275fe1a7a1c7e12f422d8d8431d8d9f1d`. R is the selected authoring seed at [selection commit e65606397fb679d7cb96f4f0e92700a6cf0944a6](https://github.com/dwijayuda/pskernel/commit/e65606397fb679d7cb96f4f0e92700a6cf0944a6); F has its own completed source/runtime qualification, recorded below. Neither checkpoint establishes full Standard or PSCV conformance, activates strict SH/1, or upgrades the Lean 4.34.0 provider.

## F checkpoint: finite worker migration

F implements the twelve workers frozen in [migration-backlog.json](migration-backlog.json): four fresh-name workers and eight preparation, elaboration, erasure and symbol-map workers now use ordinary state parameters instead of handwritten returned-function adapters. It also removes exactly three typed projection aliases in `CompilerIr/Check.lean`, using the projection behavior supplied by R. The compiler remains authored in `.lean`; current `.ps` keeps the same new-only `ps-0.9-r3` grammar.

Complete public types and argument order are preserved. The candidate retains each worker's distinct fuel-exhaustion policy, collision order, accumulator reversal, first-error behavior and wrappers. Seven related source guards change their obsolete spelling requirements while keeping their other checks. This finite migration does not include the remaining locator inventory.

F qualification passed against its exact source. The shared API gate passed 87 explicit behavior cases per compared compiler: 51 for F1 and 36 for F2. A separate ABI hook reads the already prepared declarations and exact IR, compares full public Core types and ordered runtime signatures, and elaborates a small isolated signature/typed-partial module. It does not rebuild the baseline closure or add probe declarations to the compiler. Existing runtime partial-application checks remain separate.

The coherent F qualification used authenticated selected R and recorded paired R/F behavior, all twelve public Core/IR signatures, current C2/C3 products, checked original IR and separate exact provider decisions. [IMPLEMENTATION.md](IMPLEMENTATION.md#f-checkpoint-ordinary-worker-parameters) and [MIGRATION.md](MIGRATION.md#current-f-checkpoint-implemented-candidate-qualification-pending) describe the integration. No unrestricted PSC1, strict SH/1, full PSCV or measured runtime-speedup claim follows from these source rewrites.

## 1. Correct the premise for the historical baseline

At the pinned research baseline, PSC0's root configuration and original 12-package compiler closure did **not** select `PSC1-selfhost-stable/1` or `PSC1-portable-selfhost/1`. Its root had neither corresponding profile manifest. That historical configuration said implementation `PSC1`, accepted language `PSC2-bootstrap`, version `0.7`, with `Ps.Bootstrap.SelfHost` as entry.[CFG] Those are historical configuration facts; the current source grammar identity is described above.

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
| Historical generated backend in that closure | TypeScript, compiled by TypeScript 5.8.3 to JavaScript |
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

Historical scope: this section describes the pinned research baseline
[`37f63c39d4a07189938046c64152bba25d789450`](https://github.com/dwijayuda/pskernel/tree/37f63c39d4a07189938046c64152bba25d789450/psc0).
Its elaborator restrictions and IR gaps are historical findings, not a list of
post-F current defects. Current implemented capabilities and actual qualification
status are recorded in [CURRENT.md](CURRENT.md) and [IMPLEMENTATION.md](IMPLEMENTATION.md).

### 2.1 A small owned frontend is doing the work

The syntax AST has definitions, partial definitions, theorems, inductives and structures. It has typed lambda binders and flat constructor patterns. It has no general source declaration for classes or instances, no arbitrary macro expansion system, and no recursive pattern tree. The presence of instance synthesis modules does not create source syntax that the parser lacks.[AST]

The historical `.ps` parser used `def`, `partial def`, `theorem`, `inductive` and `structure`; definitions required a final semicolon. It distinguished adjacent `f(` and rewrote empty `f()` to application to Unit.[PP], [PARSECALL] The new-only source grammar replaces these historical rules through owned lexer/parser/printer changes and migrated fixtures. Its bounded acceptance and refusal contract is in [PS_GRAMMAR_ADOPTION.md](PS_GRAMMAR_ADOPTION.md); the supplied reference alone grants no implementation or semantic capability.

This is an implementation boundary, not a fundamental requirement that a self-hosted language be awkward. An ergonomic surface can compile into a much smaller core.

### 2.2 Recursion recognition enforces a handwritten normal form

`psElabStructuralRecursionFromSource` discovers recursion only when the declaration body is directly a match on a named explicit parameter. A let or other wrapper around the match can prevent discovery. It does not perform Lean's general recursion elaboration.[DECL]

`psElabValidateStructuralCallWorker` requires the recursive argument to resolve to a registered smaller field and every other explicit argument to resolve to the same original local variable. An incremented index, updated accumulator, rebuilt context, or other expression in those positions raises `structuralRecursionInvariantArgument`. Calls also have to match the recorded explicit arity.[TERM]

Consequently, an ordinary operation shaped like `scan tail (index + 1) updatedState` is often written as a structurally recursive worker returning a function, followed by application to changing state. PSC0's own validator uses exactly that technique: it recurses over the argument list, returning a function of context, recursion state, index and hypothesis state, then applies those values after obtaining the smaller result.[TERM]

The existing list library demonstrates that this is a usable encoding: reverse, append, take and zip already use function-valued recursion. It also already provides map, mapExcept, length and any; there is no need to invent a new walker for every call site.[LIST]

**Root cause at the pinned baseline:** its elaborator made authors perform a transformation that a bounded compiler pass can perform systematically. Generalizing changing parameters into the recursion motive is the highest-value first language improvement.

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

### Historical baseline commands were coarser than the desired workflow

`build:psc` really does read the current handwritten entry, emit a `.ps` workspace, emit a Lean replay, then compile the generated workspace. It is more useful than blindly reusing an old dist tree. It does **not** run the resulting candidate compiler on its own current source or prove equality between candidate generations.[BUILD]

`selfhost-generation.mjs` also unconditionally emits Lean replay. The top-level `fixed-point` script starts with the full bootstrap chain, and nested scripts repeat source/closure checks. `compare-selfhost.mjs` compares the two paths supplied to it; the configured compiler comparison is TS equality, not a general all-artifact proof.[GEN], [PKG], [COMPARE]

At the pinned research baseline there was no resident compiler/session cache or start/step/finish preparation API. Its driver required aggregate `psCompilerPrepareSources` and imported a compiler for each invocation. The baseline `build:auto` only checked whether the expected generated JS file existed; it did not authenticate source provenance. `clean` deleted dist.[DRIVER], [AUTO], [CLEAN] The current implementation now has authenticated resident preparation and the bounded native development route described in [CURRENT.md](CURRENT.md). Recoverable seed identity remains independent of mutable dist output.

### Module invalidation requires more than import edges

The compiler prepares an ordered list of sources with a shared environment and a reverse declaration accumulator. A changed early declaration can affect later elaboration, reduction, resolution or generated names. Rebuilding only direct reverse importers is not automatically safe.[API]

The initial incremental design called for caching parsing per source and resuming preparation from the first changed module; the current resident implementation supplies that conservative boundary. It should invalidate the semantic suffix until equality of the complete incoming state is established. That state includes environment, declaration accumulator/provenance, prelude, source kind, compiler implementation identity and relevant limits. Dependency-driven finer invalidation can follow once actual semantic dependencies are recorded.

### Native checking is a separate performance workstream

At the historical research baseline, main's old `--kernel pskernel-core` route imported a legacy generated provider rather than the copied kernel-core source.[WORKER], [IDENTITY] The then-active branch `psc0/native-core-selfhost-v1` was implementing native integration. At the inspected `b109be0...` snapshot, its checked fixed-point workflow failed full-corpus acceptance; passing bounded provider tests did not establish a checked full compiler.[NATIVE], [RUN]

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

The initial research phase used GitHub source/tree/history/workflow reads and primary compiler documentation. That initial audit did not run a local checkout, build, compiler, benchmark or new CI qualification; its specification files alone granted no language support. The later implementation used GitHub branches and cloud qualification, with actual compiler/provider outcomes recorded in [IMPLEMENTATION.md](IMPLEMENTATION.md) and [qualification-evidence.json](qualification-evidence.json). The baseline analysis and citations above retain their original scope.

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
