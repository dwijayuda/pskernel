# PSC1 self-host architecture map

This document is the implementation map for the Lean-first ProofScript
self-host workspace.

The rule is **responsibility parity, not file parity**.

- The current TypeScript implementation is the behavioral oracle and a source
  of tested algorithms.
- Lean 4.34 is the semantic/compiler-architecture reference for dependent
  elaboration, environments, metavariables and kernel-facing terms.
- The new PSC1 compiler is allowed to split, merge, rename or delete modules
  when that gives a smaller and clearer architecture.
- Do not port a TypeScript file line-by-line.
- Do not reproduce a Lean file merely because Lean has one.
- Portable modules must remain expressible in the frozen PSC1 language.

## Chosen package graph

```text
foundation
   |\
   | \-> syntax
   |       |
   |       v
   |    project/resolver
   |
   +----> core
           | \
           |  \-> environment
           |          |
           |          v
           +-------> meta
                       |
                       v
                     elab
                       |
                       v
                    checked
                       |
                       v
                      ir
                       |
                       v
                  backend-ts
                       |
                       v
                   compiler
```

Host adapters sit outside this graph and may remain TypeScript.

## Package responsibilities and references

### foundation

Owns:
- hierarchical names;
- UTF-8 source positions/spans;
- diagnostics;
- small cross-package value types.

Harvest from current TS:
- `packages/syntax/src/source.ts`;
- name helpers currently scattered across kernel/frontend code.

Learn from Lean:
- `Lean.Name` representation and deterministic hierarchical identity;
- source-position discipline.

Do not copy:
- Lean environment extensions;
- rich message formatting framework;
- host filesystem path types.

Current self-host modules:
- `Ps.Foundation.Name`;
- `Ps.Foundation.Source`;
- `Ps.Foundation.Diagnostic`.

### syntax

Owns:
- tokens/trivia needed by PSC1;
- canonical source AST;
- lexer;
- parser;
- canonical printers/translators.

Harvest from current TS:
- `packages/syntax/src/lexer.ts`;
- `parser-core.ts`;
- v0.6.1/v0.7 AST and conformance tests;
- dual-source canonicalization behavior.

Learn from Lean:
- explicit parser state;
- source-position/error recovery discipline;
- parser and syntax tree separation.

Do not copy:
- arbitrary parser extensions;
- custom syntax categories;
- quotations/macros;
- runtime grammar mutation.

### project / resolver

Owns:
- logical module graph;
- deterministic import ordering;
- package/module identity;
- name resolution;
- duplicate/ambiguity diagnostics.

Harvest from current TS:
- `@proofscript/project` build graph;
- sourceRoots resolution semantics;
- checked module dependency integrity.

Learn from TypeScript:
- Program/project graph as a first-class phase;
- binding/name-index construction before semantic checking.

Learn from Lean:
- hierarchical names and explicit environment lookup.

Do not copy:
- JavaScript/Node resolution semantics into language semantics;
- Lean alias/environment-extension machinery unless later required.

### core

Owns:
- universe levels;
- binder information;
- literals;
- kernel-facing expressions;
- declaration forms.

Harvest from current implementation:
- pskernel expression/declaration codecs and invariants.

Learn strongly from Lean:
- `Lean.Level`;
- `Lean.Expr`;
- declaration-kind distinctions.

Do not copy:
- cached expression implementation fields;
- pointer/hash optimizations;
- metadata nodes unless a concrete PSC1 feature requires them.

Current self-host modules:
- `Ps.Core.Level`;
- `Ps.Core.Expr`;
- `Ps.Core.Declaration`.

### environment

Owns:
- immutable declaration environment;
- deterministic lookup;
- duplicate rejection;
- later class/instance indexes required by PSC1.

Harvest from current TS:
- `packages/environment`;
- imported checked-core metadata behavior.

Learn from Lean:
- kernel-facing environment is explicit and persistent;
- declaration admission changes environment state rather than hidden globals.

Do not copy:
- asynchronous environment branches;
- arbitrary environment extensions;
- dynamic libraries;
- attribute registries.

Current self-host module:
- `Ps.Environment.Basic`.

### meta

Owns:
- expression/universe metavariable state;
- local contexts;
- assignments;
- snapshots/rollback;
- WHNF/definitional-equality requests;
- bounded unification;
- bounded instance synthesis.

Harvest from current TS:
- `expr-meta.ts`;
- `level-meta.ts`;
- transactional assignment regressions.

Learn strongly from Lean:
- `MetavarContext`;
- `Meta.Basic`;
- `Meta.WHNF`;
- `Meta.InferType`;
- `Meta.SynthInstance`.

Do not copy:
- full tactic-facing Meta API;
- discrimination trees until workload proves they are needed;
- full higher-order unification;
- transformer-stack complexity merely for parity.

Current self-host module:
- `Ps.Meta.Context`.

### elab

Owns:
- expected-type-directed term elaboration;
- implicit insertion;
- local context management;
- construction of core terms;
- bounded class/instance and Decidable use;
- declaration elaboration.

Harvest from current TS:
- semantic regressions and working elaboration rules from `packages/elab`.

Learn strongly from Lean:
- elaboration produces kernel-checkable terms;
- expected type is explicit state/input;
- Meta operations are transactional;
- no second trusted type checker after elaboration.

Do not preserve the current one-file-per-small-rule TS layout automatically.
Prefer a smaller set such as:
- `Context`;
- `Type`;
- `Term`;
- `Declaration`;
- `Inductive`;
- optional proof/tactic frontend.

### checked

Owns:
- the fact that declarations/modules were admitted by pskernel;
- replayable checked artifacts;
- no independent semantic checker.

Harvest from:
- current `@proofscript/checked-core`.

This package is intentionally ProofScript-specific; Lean is not the template.

### ir

Owns:
- the small executable representation after erasure;
- no proof authority;
- target-neutral runtime semantics.

Harvest from:
- `@proofscript/compiler-ir`.

Keep smaller than the source language.

### backend-ts

Owns:
- deterministic IR -> TypeScript emission;
- TypeScript annotation strategy;
- no semantic checking authority.

Harvest from:
- current verified TS emitter.

Do not make TypeScript's type system part of ProofScript semantics.

### compiler

Owns:
- the portable public compiler API;
- source-kind dispatch for Lean-subset and ProofScript source;
- canonical `.lean <-> .ps` translation;
- parse/elaborate/check composition;
- checked-admission serialization;
- erasure and IR -> TypeScript composition;
- no filesystem or process execution.

Current self-host modules:
- `Ps.Compiler` — package entry/barrel, analogous to a JS package `index.ts`;
- `Ps.Compiler.Api` — portable API consumed by both bootstrap and generated JS hosts.

The generated compiler package is emitted as
`dist/<generation>/packages/compiler/index.js`, not as a special handwritten
`compiler.js` source file.

### cli

Owns:
- command-line argument parsing and user-facing command names only;
- no parser, elaborator, erasure or backend semantics.

Current entries:
- `packages/cli/src/Main.lean` — Lean/Lake bootstrap CLI;
- `packages/cli/bin/psc.mjs` — normal generated-JS CLI front door.

### host/tooling

Host adapters are deliberately outside the portable compiler:
- filesystem/path/process;
- project source loading;
- npm package discovery;
- `tsc` invocation;
- LSP/editor transport;
- browser adapters.

The bootstrap host is currently Lean where that is cheapest; the post-bootstrap
host is Node/JavaScript. Both call the same portable `Ps.Compiler.Api`.
Move portable algorithms out of host/tooling whenever self-hosting needs them.

## File-structure rule

A package may use fewer, better modules than its TypeScript predecessor.

For example, the current `packages/elab/src` has many narrowly split
`v061-*-elab.ts` files. The self-host implementation should not reproduce
that list mechanically. If `Term.lean/.ps` plus `Declaration.lean/.ps` and
a few focused helpers are clearer, use those.

Likewise, do not force Lean's very large `Lean/Meta/*` tree onto PSC1.

## Migration rule

For any migrated responsibility:

```text
current TS behavior/tests
        |
        v
design smaller PSC1 interface
        |
        +---- consult Lean architecture/semantics
        |
        v
author .lean
        |
        v
Lake / official Lean kernel
        |
        v
canonical .ps
        |
        v
same checked semantics
        |
        v
generated .ts/.js
        |
        v
differential tests against old TS behavior
```

Only after this closes should the old handwritten semantic TypeScript be
retired.
