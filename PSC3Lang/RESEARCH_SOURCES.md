# PSC3 Research Sources

Status: **dated research snapshot, 3 October 2026**

This document records external references that informed the PSC3 design draft.

The references are evidence and precedent, not certifications of PSC3.

## TypeScript

### TypeScript 7.0

Official TypeScript announcement and documentation.

Key design signals:
- TypeScript 7 is implemented in native Go;
- major full-build speed improvements are reported;
- editor/language-service latency and large-codebase scale are explicit priorities;
- TypeScript remains distributed through normal npm workflows.

Source:
https://devblogs.microsoft.com/typescript/announcing-typescript-7/

### TypeScript 6.0

Signals:
- ESM/bundler workflows are normal;
- tsconfig usage is widespread;
- stricter typing continues to gain adoption.

Source:
https://devblogs.microsoft.com/typescript/announcing-typescript-6-0/

### TypeScript Handbook

Topics inspected:
- narrowing/control-flow analysis;
- discriminated unions and never/exhaustiveness;
- object types and optional/readonly properties;
- functions/generics/default/rest parameters;
- modules;
- type compatibility;
- conditional/mapped/template literal types.

Sources:
https://www.typescriptlang.org/docs/handbook/2/narrowing.html
https://www.typescriptlang.org/docs/handbook/2/object-types.html
https://www.typescriptlang.org/docs/handbook/2/functions.html
https://www.typescriptlang.org/docs/handbook/2/types-from-types.html
https://www.typescriptlang.org/docs/handbook/type-compatibility.html
https://www.typescriptlang.org/docs/handbook/modules/introduction.html

## JavaScript ecosystem

### State of JS 2025

Used as ecosystem survey evidence, with the survey's own representativeness limitations.

Signals considered:
- strong TypeScript usage among respondents;
- large share of code passing through build tooling;
- widespread Vite/React/Express/Jest/Next/Vitest use;
- common language features such as nullish coalescing and dynamic imports;
- recurring desire for static typing, better standard library/error handling, pattern matching and Result/Option-like facilities.

Sources:
https://2025.stateofjs.com/
https://2025.stateofjs.com/en-US/usage/
https://2025.stateofjs.com/en-US/features/
https://2025.stateofjs.com/en-US/libraries/

### GitHub Octoverse

Signal considered: TypeScript's continuing growth and scale in the GitHub ecosystem.

Source:
https://github.blog/news-insights/octoverse/

## Node, Bun and Deno

### Node package/modules documentation

Signals:
- ESM is a standard module system;
- package exports/imports are important public API tools;
- package encapsulation and conditional exports are normal ecosystem mechanisms.

Source:
https://nodejs.org/api/packages.html

### Node TypeScript support

Signal:
- modern Node can strip erasable TypeScript syntax directly, highlighting a useful distinction between type-only TS and TS constructs with runtime transforms.

Source:
https://nodejs.org/api/typescript.html

### Bun

Signal:
- developers value integrated runtime/package/test/bundling workflows and direct TypeScript/JSX ergonomics.

Source:
https://bun.sh/docs

### Deno

Signal:
- workspace and npm-compatible workflows are useful cross-runtime expectations.

Source:
https://docs.deno.com/runtime/fundamentals/workspaces/

## UI / JSX ecosystem

### React TypeScript documentation

Signals:
- TS/TSX is normal in React applications;
- component props, events and hooks are important typed surfaces.

Source:
https://react.dev/learn/typescript

### Svelte TypeScript documentation

Signal:
- UI frameworks can support TypeScript while restricting syntax that requires runtime transformation; type-only integration is a useful precedent.

Source:
https://svelte.dev/docs/typescript

### ReScript

Important precedent:
- sound typed language compiling to readable JavaScript;
- strong npm/React interoperability;
- generated TypeScript types;
- built-in formatting/tooling;
- gradual project adoption;
- JSX as a transform mechanism rather than necessarily React semantics.

Sources:
https://rescript-lang.org/
https://rescript-lang.org/docs/manual/latest/typescript-integration
https://rescript-lang.org/docs/manual/latest/jsx
https://rescript-lang.org/docs/manual/latest/interop2

### Gleam

Important precedent:
- small/simple language;
- JavaScript target;
- pattern matching and Result-style errors;
- explicit external functions;
- foreign functions are a trust/safety boundary rather than magically verified.

Sources:
https://gleam.run/
https://tour.gleam.run/advanced-features/external-functions/

## Lean

### Lean stable releases

PSC3 initial research profile uses stable Lean 4.34.1.

Lean 4.35 release candidates are research inputs only until a stable release is intentionally adopted.

Sources:
https://github.com/leanprover/lean4/releases
https://lean-lang.org/doc/reference/latest/releases/

### Lean language reference

Areas studied:
- kernel/proof validation;
- type classes/instance synthesis;
- coercions;
- recursive and partial definitions;
- elaboration/compilation;
- IO;
- Tasks/threads;
- macros/elaborators;
- Lake/package tooling.

Source:
https://lean-lang.org/doc/reference/latest/

## Go language engineering

### Go at Google

Design signals:
- large-scale compilation and dependency costs matter;
- explicit dependencies improve software engineering;
- regular syntax and toolability are first-class concerns.

Source:
https://go.dev/talks/2012/splash.article

### Go FAQ

Signal:
- avoid unnecessary complexity and overlapping mechanisms.

Source:
https://go.dev/doc/faq

### Simplicity is Complicated

Signal:
- simplicity is the right set of orthogonal/predictable features, not merely a small feature count.

Source:
https://go.dev/talks/2015/simplicity-is-complicated.slide

### Go modules

Signal:
- explicit modules/version selection and reproducible dependency reasoning are language-platform concerns.

Source:
https://go.dev/ref/mod

## Verification and language precedents

### Verus

Studied:
- separation of exec/spec/proof code;
- contracts;
- relationship/equivalence support between executable and specification views.

Source:
https://verus-lang.github.io/verus/guide/

### F*

Studied:
- dependent types;
- total logical core;
- effects;
- SMT-assisted proof;
- program extraction;
- metaprogramming.

Sources:
https://fstar-lang.org/
https://fstar-lang.org/tutorial/

### Koka

Studied as an alternative effect-system design:
- effect types;
- handlers;
- exceptions/async abstractions.

PSC3 does not currently adopt general effect handlers as a core design.

Source:
https://koka-lang.github.io/koka/doc/book.html

## WebAssembly

### WebAssembly Component Model

Signals:
- typed interface definitions through WIT;
- records/variants/resources;
- cross-language component composition.

Sources:
https://component-model.bytecodealliance.org/
https://component-model.bytecodealliance.org/design/wit.html

### WASI 0.3

Signal:
- Component Model/WASI now includes native asynchronous primitives, making a future structured direct-Wasm application profile more plausible.

Source:
https://bytecodealliance.org/articles/WASI-0.3

### WebAssembly core/JS embedding

Source:
https://webassembly.github.io/spec/core/
https://developer.mozilla.org/en-US/docs/WebAssembly

## Research methodology

### PLIERS

User-centered programming-language design methodology used as a process reference.

Source:
https://arxiv.org/abs/1912.04719

## Repository evidence

PSC3 also builds directly on:
- PSC1 language/grammar/runtime documents;
- PSC2 language reference/profile;
- PSC2 feature research;
- PSC2 contract/verification design;
- PSC2 self-hosting and kernel-provider architecture;
- current ProofScript compiler/backend experiments.

Repository:
https://github.com/dwijayuda/pskernel

## Research caveat

Ecosystem surveys and repository-search counts are directional evidence.

They are not universal measurements of all TypeScript/JavaScript developers.

PSC3 feature acceptance requires interaction analysis, real programs, usability evidence and executable conformance—not popularity alone.
