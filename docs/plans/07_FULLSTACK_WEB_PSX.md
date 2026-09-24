# ProofScript full-stack web / PSX plan

Status: **active feature plan on `feature/fullstack-web-psx`**

Date established: 2026-09-24

This plan is subordinate to:

- `docs/PROOFSCRIPT_ARCHITECTURE.md`
- `docs/STUDY_REFERENCE_POLICY.md`
- `docs/plans/00_MASTER_PLAN.md`
- `docs/plans/03_COMPILER_RUNTIME_BACKENDS.md`
- `docs/plans/05_LANGUAGE_COMPLETION.md`

## Objective

Make it practical to author a complete modern web application using only
ProofScript source:

```text
.ps   — modules, domain logic, APIs, proofs, server code
.psx  — ProofScript modules that additionally allow JSX expressions
```

The first flagship platforms are:

1. React;
2. React + Vite;
3. Next.js App Router;
4. standard Web APIs used by Node/browser/framework hosts.

The developer-facing completion target is:

> A representative full-stack Next.js App Router application can be authored
> without hand-written `.ts` or `.tsx`, while every logical guarantee remains
> subject to the existing pskernel trust boundary and every framework/runtime
> dependency is reported as an explicit external assumption.

This is an **authored-source** target, not a claim that React, Next.js, Node,
the browser, the DOM, the database, or generated JavaScript are themselves
formally verified.

## Why this is architecturally compatible

PSX does not add JSX, React, DOM, or Next.js concepts to pskernel.

The intended path is:

```text
.ps / .psx / supported .lean
          |
          v
source frontend
          |
          v
canonical ProofScript surface
          |
          v
Lean-compatible Meta / Elab
          |
          v
pskernel admission
          |
          v
checked core
          |
          v
verified erasure
          |
          v
compiler IR
          |
          +----------------------+
          |                      |
          v                      v
ordinary TS/JS             JSX/runtime calls
          |                      |
          +-----------+----------+
                      v
             React / Next / Vite
```

Framework execution is downstream of proof acceptance. Runtime values coming
from React/Next/Node/DOM/DB/network boundaries are not proof evidence.

### Branch protection rule

Normal work on this branch MUST NOT change:

- `src/core/**`;
- `src/kernel/**`;
- Lean4Export trusted replay semantics.

If web work appears to require a kernel change, stop and isolate a standalone
Lean-4.34 semantic bug with a kernel regression first. Do not broaden the
kernel merely to make React/Next integration convenient.

## Trust and correctness model

The project must report separate assurance claims.

### Kernel-owned

May be kernel checked where expressible:

- types and dependent terms;
- propositions and proofs;
- pure domain/business logic;
- state-machine invariants;
- pre/postconditions represented as propositions;
- component prop/index invariants;
- authorization/business rules;
- transformations over checked data.

### Compiler-owned but outside the logical TCB

Requires differential/translation-validation evidence until formally related:

- proof/type erasure;
- verified runtime IR lowering;
- JSX lowering;
- TypeScript/JavaScript emission;
- source maps and bundler adapter output.

### External/runtime assumptions

Must never be silently presented as proven:

- React runtime;
- `react/jsx-runtime`;
- React DOM;
- Next.js;
- Vite/Turbopack;
- Node/Bun/Deno;
- browser/DOM APIs;
- network;
- database engines/drivers;
- third-party npm packages.

The existing checked-core/source-FFI rule remains mandatory: an external
runtime implementation may not manufacture proof evidence. Runtime externals
that could directly produce `Prop` proofs or otherwise bypass kernel proof
construction must fail closed.

## Source model

### `.psx` is not a second ProofScript semantics

`.psx` means:

> ProofScript source with JSX expression parsing enabled.

It reuses the same ProofScript source kind, declaration grammar, elaborator,
checked core, theorem prover, module system, erasure rules, and compiler. File
extension only enables the JSX lexical/parser mode and framework tooling.

Conceptually:

```ts
interface ProofScriptFrontendOptions {
  jsx: boolean
}
```

Do not create an independent PSX type system, checker, or compiler lane.

### JSX is frontend syntax

The syntax layer may represent nodes such as:

- element;
- fragment;
- intrinsic tag;
- component tag;
- attribute;
- spread attribute;
- expression child;
- text child.

Those nodes must lower to ordinary typed executable terms before checked-core
handoff. pskernel never receives a JSX AST.

### JSX runtime policy

Prefer the modern automatic JSX runtime model. React-specific emission should
target the host contract represented by `react/jsx-runtime` / development
runtime rather than requiring a global `React` value.

The TypeScript study corpus already documents `react-jsx`,
`react-jsxdev`, `jsxImportSource`, and preserve/classic alternatives.
ProofScript should own one explicit canonical runtime profile first and add
alternatives only when required by a supported framework.

## Package plan

New packages are planned outside the TCB:

### `@proofscript/jsx`

Framework-neutral JSX semantic/lowering support.

Responsibilities:

- typed JSX lowering;
- element/fragment/child normalization;
- component application lowering;
- intrinsic-element registry interface;
- runtime-factory profile interface;
- fail-closed handling of unsupported spreads/children/shapes.

It must not contain React-specific hooks or Next routing semantics.

### `@proofscript/react`

React runtime bindings and React-specific checks.

Initial responsibilities:

- opaque/runtime `ReactNode` / element boundary;
- component-call ABI;
- automatic JSX runtime binding;
- Fragment;
- basic hook bindings;
- React component purity/rules diagnostics where statically enforceable;
- framework-assumption metadata.

React APIs remain runtime externals, not proof constructors.

### `@proofscript/react-dom`

DOM-facing intrinsic JSX metadata.

Initial responsibilities:

- bounded HTML intrinsic elements;
- common attributes;
- event-handler signatures;
- DOM/browser value boundaries.

Start with a deliberately bounded checked set. Do not silently delegate source
type acceptance to arbitrary TypeScript declarations.

### `@proofscript/web`

Standard Web Platform host bindings useful across frameworks:

- `Request`;
- `Response`;
- `Headers`;
- `URL`;
- `URLSearchParams`;
- `fetch` / Promise-like async boundary as supported by the effect model.

This package should be preferred by framework adapters whenever a standard Web
API exists.

### `@proofscript/vite`

Vite/Rolldown integration.

Responsibilities:

- transform `.ps` / `.psx` to JavaScript/JSX-runtime-compatible modules;
- source maps;
- dependency/watch integration;
- React Fast Refresh compatibility where possible;
- development diagnostics routed back to ProofScript spans.

The first implementation should use Vite's documented custom-file transform
hook rather than inventing a separate dev server.

### `@proofscript/next`

Next.js App Router integration.

Responsibilities:

- configure `.ps` / `.psx` resolution without requiring authored TS/TSX;
- integrate through supported Turbopack loader/rule and extension mechanisms;
- preserve App Router file conventions;
- preserve module directives such as `"use client"` and `"use server"`;
- Route Handler integration using Web `Request`/`Response`;
- server/client module-graph diagnostics;
- generated/runtime assumption reporting.

Do not reimplement Next.js routing or RSC transport.

## Module directives

The web branch may add a bounded module directive prologue for exact host
directives required by supported frameworks, initially:

```text
"use client";
"use server";
"use cache";
```

These are source/frontend/compiler metadata, not propositions and not kernel
declarations.

Rules:

1. directives occur only in the leading module prologue;
2. exact supported spellings are preserved in generated host modules;
3. unsupported arbitrary string directives fail closed or remain ordinary
   unsupported syntax;
4. directive selection may affect host bundling/effects, never proof
   acceptance;
5. certification reports record server/client/runtime boundaries.

## React rules as static diagnostics

React currently requires components and hooks to obey rules including:

- Components and Hooks should be pure during render;
- ordinary Hooks are called only at the top level;
- Hooks are called only from React components or custom Hooks;
- props/state are immutable snapshots.

ProofScript should exploit its structured AST to diagnose obvious violations
before handing code to React.

This is a framework correctness layer, not kernel soundness. Diagnostics must
not be advertised as a formal proof of React runtime behavior.

A future effect system may strengthen these checks by distinguishing pure render
computation from State/DOM/IO/Network effects.

## Next.js model

Target the App Router first.

Important host properties to preserve:

- page/layout modules are Server Components by default;
- `"use client"` defines the client-module boundary;
- client code may use state, events, effects, and browser-only APIs;
- Route Handlers use Web `Request`/`Response`;
- file-system conventions remain owned by Next.js;
- Turbopack is the normal current Next bundler and exposes custom extension /
  loader rules.

ProofScript should map to these boundaries instead of inventing an alternative
routing or RSC model.

## Implementation sequence

### PSX0 — architecture and anti-drift lock

This document plus master-plan/architecture/reference-policy updates.

Exit:

- branch exists from current `main`;
- no kernel semantic changes;
- trust boundaries and package ownership are explicit.

### PSX1 — source recognition + parser

Add `.psx` recognition as ProofScript-with-JSX.

Minimum syntax:

- intrinsic element;
- component element;
- self-closing element;
- fragment;
- string/text child;
- `{expr}` child;
- simple named attributes;
- expression attributes.

Keep initially unsupported:

- spread attributes;
- namespace tags;
- arbitrary JSX syntax extensions;
- exotic attribute names;
- framework-specific directives inside JSX.

Required gates:

- canonical parse/print/parse;
- `.ps` behavior unchanged;
- unsupported JSX fails before checked core.

### PSX2 — typed JSX/component lowering

Add framework-neutral JSX lowering.

Target source shape:

```proofscript
structure GreetingProps where {
  name : String;
}

function Greeting(props : GreetingProps) : JSX.Element :=
  <h1>Hello {props.name}</h1>;
```

Requirements:

- component attributes elaborate as ordinary checked arguments/records;
- component return type is a runtime type, not `Prop`;
- child normalization is deterministic;
- checked-core contains no JSX syntax;
- proof terms cannot be sourced from JSX/runtime externals.

### REACT1 — React automatic runtime

Implement `@proofscript/react` and bounded `@proofscript/react-dom`.

Exit:

- generated module executes a static React component;
- fragments work;
- bounded DOM props are typechecked;
- React runtime dependencies appear in assurance output;
- no kernel changes.

### REACT2 — client interactivity

Add bounded:

- event handlers;
- `useState`;
- `useReducer`;
- selected context/hooks only as demanded by real examples.

Add static Rules-of-Hooks diagnostics for the owned subset.

Exit example:

- counter/form application entirely authored in `.psx`;
- invalid conditional/top-level Hook usage receives a ProofScript diagnostic.

### VITE1 — development loop

Implement `@proofscript/vite`.

Exit:

- React/Vite app authored only with `.ps`/`.psx`;
- `vite dev` or `psc dev` starts the app;
- edits recompile with useful source-mapped diagnostics;
- production build succeeds;
- no generated TS/TSX needs to be hand edited.

### WEB1 — standard host APIs and async/effect boundary

Implement the minimum `@proofscript/web` surface required for server/API work.

Do not smuggle JavaScript Promise/IO behavior into proof reduction. Runtime
effects must remain explicit.

### NEXT1 — App Router pages/layouts

Implement `@proofscript/next` integration for:

- `app/**/page.psx`;
- `app/**/layout.psx`;
- imports of ordinary `.ps` modules;
- Server Component default;
- client component directive preservation.

Prefer supported Next/Turbopack configuration and loader hooks over a fork.

### NEXT2 — Route Handlers

Support:

```text
app/api/**/route.ps
```

with bounded exports for:

- GET;
- POST;
- PUT;
- PATCH;
- DELETE;
- HEAD;
- OPTIONS.

Use `@proofscript/web` Request/Response boundaries.

### NEXT3 — server/client boundary and effects

Add diagnostics that distinguish:

- server-only imports/effects;
- client-only React/browser effects;
- values crossing the server/client serialization boundary.

Do not claim formal RSC protocol verification.

### WEBAPP1 — no-authored-TypeScript reference app

Required reference application:

```text
examples/next-fullstack/
  app/
    layout.psx
    page.psx
    dashboard/page.psx
    api/items/route.ps
  components/
    Counter.psx
    ItemForm.psx
  domain/
    Item.ps
    State.ps
  proofs/
    StateProofs.ps
  psconfig.json
  package.json
  next.config.*
```

Acceptance:

1. no authored application `.ts` or `.tsx`;
2. `psc check --verified` checks owned logical code;
3. Next dev starts;
4. Next production build succeeds;
5. server page renders;
6. client component hydrates and handles events;
7. Route Handler executes;
8. domain theorem/invariant suite passes;
9. assurance report lists React/Next/Node/browser/npm assumptions separately;
10. no `axiom`/`admit`/unsafe proof escape is introduced merely for web support.

### WEBAPP2 — AI-agent full-app benchmark

After WEBAPP1 is stable, add an agent benchmark:

> Generate/modify a small full-stack application from an accepted formal
> specification while the specification is locked.

Measure:

- compile success;
- proof obligations discharged;
- spec modifications attempted;
- runtime assumptions introduced;
- framework-boundary violations;
- tests/differential checks;
- iterations and token/cost metrics.

This connects the web target to the planned agent/spec-driven workflow without
putting AI in the TCB.

## Compiler strategy

For Vite and Next integration, two host strategies are permitted:

### A. direct loader/plugin transformation — preferred developer experience

```text
.psx
 -> ProofScript compiler
 -> generated JS/JSX-runtime module + source map
 -> Vite/Turbopack
```

Advantages:

- source tree remains purely ProofScript;
- framework file conventions can recognize configured `.psx`/`.ps`;
- no hand-managed shadow tree.

### B. generated shadow host tree — fallback/diagnostic mode

```text
.psx/.ps
 -> deterministic generated .tsx/.ts/.js tree
 -> ordinary framework build
```

Keep this as a debugging/reference path if loader APIs are insufficient or to
compare direct-plugin output against ordinary host tooling.

The two paths must converge on the same ProofScript checked-core/IR result.
Host-loader differences may not select different logical semantics.

## Framework version policy

Do not pin ProofScript language semantics to one React/Next/Vite release.

Each adapter should declare a tested compatibility range and capture exact
installed runtime versions in build/assurance metadata.

Framework upgrades require:

1. integration tests against the new version;
2. review of changed host contracts;
3. no change to pskernel semantics solely because a framework changed;
4. explicit adapter/profile versioning when runtime behavior changes.

## Research basis recorded 2026-09-24

Repository study evidence:

- `study/typescriptlang/docs/handbook/jsx.html` documents JSX modes including
  `react-jsx` and `react-jsxdev`;
- the authoritative ProofScript v0.7 study reference currently has no PSX/JSX
  surface, so `.psx` is an explicit repository design extension rather than a
  claim of v0.7 syntax conformance;
- existing source FFI/checked-core architecture already separates runtime
  external assumptions from proof authority.

External official references used for host-integration design:

- React Rules / Rules of Hooks:
  https://react.dev/reference/rules
- React Hooks:
  https://react.dev/reference/react/hooks
- React Compiler:
  https://react.dev/learn/react-compiler
- Vite Plugin API:
  https://vite.dev/guide/api-plugin
- Vite JSX/features:
  https://vite.dev/guide/features
- Next.js App Router docs:
  https://nextjs.org/docs
- Next Server and Client Components:
  https://nextjs.org/docs/app/getting-started/server-and-client-components
- Next Route Handlers:
  https://nextjs.org/docs/app/getting-started/route-handlers
- Next pageExtensions:
  https://nextjs.org/docs/app/api-reference/config/next-config-js/pageExtensions
- Next Turbopack configuration:
  https://nextjs.org/docs/app/api-reference/config/next-config-js/turbopack

External framework documentation defines host interoperability only. It does not
override Lean-compatible proof semantics, pskernel admission, or the
ProofScript language's logical meaning.

## Merge policy

This branch should be merged only in bounded milestones, not as one giant
framework dump.

Preferred sequence:

```text
PSX0/PSX1
 -> PSX2
 -> REACT1
 -> REACT2
 -> VITE1
 -> WEB1
 -> NEXT1
 -> NEXT2
 -> NEXT3
 -> WEBAPP1
```

Each milestone must keep existing kernel and verified compiler gates green.

The intended end state is not a permanent separate web compiler. Once mature,
the framework-neutral PSX/compiler pieces should merge into the normal
ProofScript architecture, while React/Vite/Next remain optional adapter
packages.
