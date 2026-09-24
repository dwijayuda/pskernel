# ProofScript self-hosting foundation plan

Status: **highest-priority ProofScript execution plan**

This plan supersedes the previous package/infrastructure-first ordering for
ProofScript work on `main`. The objective is to finish one stable language and
runtime foundation that can express the ProofScript compiler itself, first in a
bounded Lean-compatible `.lean` subset and then in native `.ps`, without
rewriting compiler infrastructure again after self-hosting starts.

Kernel conformance work is intentionally separate. The TypeScript Lean 4.34
kernel remains an independent checker and continues on the dedicated
`kernel/lean434-study-hardening` branch. ProofScript foundation work must not
modify kernel semantics merely to unblock a compiler feature.

## Priority override

Until the self-hosting foundation gates in this document are closed:

1. **Stop unrelated ProofScript infrastructure expansion.**
2. Do not add new LSP/editor/package-manager/browser/build-system features
   unless they are required to implement, exercise, or diagnose the
   self-hosting foundation.
3. Do not broaden tactics, macros, Lean compatibility, npm interoperability, or
   additional backends merely because the feature exists in Lean or
   TypeScript.
4. Add a language/runtime feature only when it is required by an identified
   compiler module or by a prerequisite standard-library abstraction.
5. Keep one semantic path:
   source -> Meta/Elab -> pskernel -> checked core -> erasure -> verified IR
   -> TypeScript -> JavaScript.
6. No second software checker, alternate IR, or automatic fallback may be
   introduced.
7. Host integration may stay TypeScript when it is genuinely a Node/npm/VS
   Code/TypeScript-API capability rather than ProofScript semantics.

## Reference workload

The implementation workload is derived from the pinned Lean 4.34 sources under:

- `study/lean4-4.34.0/src/Lean/Parser/`
- `study/lean4-4.34.0/src/Lean/Elab/`
- `study/lean4-4.34.0/src/Lean/Meta/`
- `study/lean4-4.34.0/src/Lean/Compiler/`

Lean is the reference for semantics and for evidence about what facilities are
useful when implementing a serious dependently typed compiler. It is **not** a
requirement to accept or reproduce all Lean implementation conveniences.

The study inventory shows recurrent use of:

- functions, lambdas, higher-order functions and parametric polymorphism;
- structures, inductives, pattern matching and dependent function types;
- direct, mutual and partial recursion;
- `List`, `Array`, `Option`, maps/sets and persistent collections;
- `String`, `Char` and source positions;
- `StateT`, `ReaderT`, `ExceptT`, `OptionT`, `EStateM` and `do`;
- explicit environments, name tables and metavariable state;
- IO/host capabilities at the outer boundary;
- Lean-specific macros, quotations, attributes, environment extensions,
  `unsafe`, `implemented_by`, and other facilities that are not automatically
  required by ProofScript.

ProofScript must implement the smallest coherent subset needed by its own
compiler, not clone every facility in that list.

## Foundation completion rule

A runtime language feature is complete only when it executes through:

```text
.ps or supported .lean
-> canonical source AST
-> Lean-compatible Meta/Elab
-> pskernel admission
-> CheckedCoreModule
-> erasure
-> verified compiler IR
-> TypeScript
-> tsc
-> JavaScript
```

A parser-only or backend-only implementation does not close a foundation gate.

## SH0 — remove the legacy semantic lane

This gate is promoted ahead of all new foundation work.

Required:

- `psc check/build/run` use the checked-core path unconditionally;
- delete the legacy `@proofscript/language` software checker;
- delete legacy software-HIR lowering from compiler IR;
- delete legacy software TypeScript emitters;
- remove unverified CLI result/report paths;
- retain source parsing/printing only through the shared frontends;
- architecture gates reject reintroduction of a second semantic checker or
  software IR.

Exit condition:

> There is exactly one ProofScript semantic compiler path on `main`.

## SH1 — executable text foundation

Finish Lean-compatible executable support for:

- `Char`;
- `String` traversal and character access;
- length/position operations;
- slicing/substrings;
- comparison;
- concatenation and an efficient builder strategy;
- character classification needed by a lexer;
- source-position/span data.

Exit test: a nontrivial lexer utility can be authored in supported `.lean`
and `.ps` and run through verified JavaScript emission.

## SH2 — compiler collections

Provide verified, generic:

- `Array α`;
- `Map K V`;
- `Set α`;
- the already-landed Option/Result/List APIs needed by compiler code.

The first Array profile needs at least empty, size, get/get?, push, set, map,
fold, any/all and find?. Map/Set may initially use a persistent tree
implementation in ProofScript; a faster runtime representation may be added
later without changing their semantic API.

Exit test: AST/name-table transformations use no TypeScript collection
semantics.

## SH3 — controlled effects

Implement the compiler-oriented effect foundation:

- `Except` / error propagation;
- `State` / `StateT`;
- `Reader` / `ReaderT`;
- usable Lean-compatible `do` notation;
- bind/pure sequencing;
- `OptionT` or additional transformers only when an actual compiler module
  requires them.

Do not add arbitrary JavaScript statement semantics merely to mimic
TypeScript mutation.

Exit test: parser state and a small name-resolution pass are written without
host-language mutation semantics.

## SH4 — recursion closure

Finish the executable recursion forms needed by compiler algorithms:

- mutual recursive definitions;
- recursive local `where` / `let rec` groups;
- multiple structural recursive parameters where Lean semantics justify them;
- Lean-faithful executable `partial def` for algorithms whose termination is
  intentionally outside proof computation.

Structural recursion remains preferred. `partial` must never become a route
for manufacturing trusted proof evidence.

Exit test: mutually recursive expression/type parsing and a fixed-point-style
compiler utility run through the verified backend.

## SH5 — names, environments and bootstrap data model

Provide stable ProofScript-authored models for:

- qualified names;
- source spans;
- tokens;
- syntax/AST nodes used by the bounded compiler;
- diagnostics;
- explicit environments and compiler state.

Avoid Lean implementation-only mechanisms such as environment extensions when
ordinary explicit data structures are sufficient.

## SH6 — host capability boundary

Keep host-specific effects thin and explicit.

The bootstrap compiler may call typed host capabilities for:

- file reads/writes;
- path operations;
- process arguments;
- npm/Node resolution where required;
- TypeScript Compiler API invocation.

These adapters may remain TypeScript. They are runtime assumptions, never
proof evidence, and must not own language semantics.

## SH7 — freeze the Lean bootstrap subset

Before writing the compiler, freeze the exact `.lean` subset accepted for
bootstrap source.

It should include every construct used by the compiler and intentionally omit
unneeded Lean implementation machinery such as arbitrary user syntax,
macros/quotations, custom elaborators, environment extensions, broad
attributes, and unsafe casts.

Gate every supported bootstrap construct through the same `.lean` and `.ps`
frontends and checked-core path.

Exit condition:

> A complete ProofScript compiler implementation can be expressed in the
> frozen supported Lean subset without adding another semantic pipeline.

## SH8 — implement the compiler in .lean

Implement compiler-owned semantics in bounded Lean source, in approximately
this dependency order:

1. Name / SourcePos / Span / diagnostics;
2. canonical AST/data model;
3. verified compiler IR model;
4. pretty printer and TypeScript source builder;
5. erasure/lowering;
6. TypeScript emitter;
7. lexer;
8. parser;
9. environment/name resolution;
10. Meta;
11. elaboration;
12. compiler orchestration.

The TypeScript pskernel remains the independent admission authority. Node,
filesystem, TypeScript-API and similar host adapters remain outside the
self-hosted semantic compiler.

## SH9 — bootstrap in JavaScript

Let PSC0 denote the current TypeScript implementation.

Required bootstrap:

```text
compiler.lean --PSC0--> compiler.ts --tsc--> PSC1.js
compiler.lean --PSC1--> compiler.ts --tsc--> PSC2.js
```

Require equality of checked-core/IR fingerprints and normalized generated
TypeScript. With a pinned toolchain, byte-stable JavaScript is preferred when
practical.

Do not claim self-hosting merely because PSC1 executes.

## SH10 — move the compiler to .ps

Use the dual-source frontend/translation machinery to convert the frozen
bootstrap implementation to canonical ProofScript, then maintain/refactor the
compiler primarily in `.ps`.

The target condition is:

```text
compiler.ps --PSC1--> PSC2
compiler.ps --PSC2--> PSC3
```

with the same semantic/bootstrap equivalence gates.

## SH11 — verified self-hosting

After ordinary self-hosting is stable, add proofs/specifications for
semantics-preserving compiler transformations where they provide real
assurance.

This milestone must not block SH1-SH10.

## Deferred until the foundation closes

Unless demanded by an SH gate, defer:

- new backends beyond the current TypeScript/JavaScript path;
- broad React/Next.js integration;
- new browser/LSP/editor features;
- extra package-manager features;
- full Lean syntax/macros/metaprogramming;
- tactic breadth unrelated to compiler verification;
- broad npm binding generation;
- kernel rewrite in ProofScript.

## Branch policy

- `main`: ProofScript self-hosting foundation and non-kernel changes needed
  for SH0-SH11.
- `kernel/lean434-study-hardening`: independent TypeScript kernel assurance
  and Lean 4.34 conformance work.
- Kernel changes merge to `main` only when they are independently justified by
  kernel compatibility, never solely to make a ProofScript compiler test pass.

## Anti-drift decision test

Before accepting any ProofScript infrastructure task, ask:

1. Which SH milestone does it close?
2. Which concrete compiler module is blocked without it?
3. Can the need be satisfied as a ProofScript library instead of a language
   primitive?
4. Can host-specific behavior remain a thin TypeScript adapter?
5. Does the change preserve the single checked-core semantic path?

If there is no concrete answer to (1) or (2), defer the work.
