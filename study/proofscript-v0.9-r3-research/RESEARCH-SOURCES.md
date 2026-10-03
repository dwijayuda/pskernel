# r3 Research Sources and Current Web Checks

Status: research bibliography; source popularity is not a language-design proof.

## Repository baseline

Main baseline used by the r3 branch:

~~~text
65369c75c7b63124f1ba7f2289e573181db281f0
~~~

Primary local material:
- ProofScript v0.9-r2;
- ProofScript v0.7 lineage and conformance material;
- study/lean4-language-reference;
- study/lean4-4.34.0 parser/source;
- study/www.typescriptlang.org;
- Lean4Lean divergence notes;
- theorem-proving and functional-programming references.

## Current official checks

### Lean function application

Official Lean reference confirms that ordinary application is juxtaposition, core functions are unary/curried, and high-level application performs named/implicit/default argument handling as one elaboration process.

Source:
https://lean-lang.org/doc/reference/latest/Terms/Function-Application/

r3 consequence:
parenthesized-call syntax must lower into the native application object rather than implement an independent TypeScript argument-matching algorithm.

### Lean syntax extensibility

Official Lean macro/notation documentation confirms that Lean can add syntax, macros, elaborators, and low-level parser extensions.

Sources:
https://lean-lang.org/doc/reference/latest/Notations-and-Macros/
https://lean-lang.org/doc/reference/latest/Notations-and-Macros/Macros/

r3 consequence:
ps-standard needs an explicit closed/versioned syntax environment; ps-lean-extensible records extension identities and environment order.

### TypeScript function conventions

Official TypeScript documentation covers optional/default/rest parameters and overloads. JavaScript/TypeScript omission and undefined behavior differ from PSC native named/default argument semantics.

Source:
https://www.typescriptlang.org/docs/handbook/2/functions.html

r3 consequence:
PSC default parameters keep Lean elaboration semantics rather than copying undefined substitution.

### TypeScript compatibility

Official TypeScript documentation states that compatibility is structurally based and documents deliberate unsoundness tradeoffs made to model JavaScript practice.

Source:
https://www.typescriptlang.org/docs/handbook/type-compatibility.html

r3 consequence:
npm/d.ts interoperability belongs at an explicit InterfaceIR/adapter boundary rather than redefining PSC as a structurally typed system.

### WebAssembly Component Model / WASI async

Current Component Model documentation describes WASI 0.3 async func, stream<T>, and future<T> as Canonical ABI primitives.

Sources:
https://component-model.bytecodealliance.org/design/async.html
https://component-model.bytecodealliance.org/design/component-model-concepts.html

r3 consequence:
direct-Wasm async mapping is plausible, but those target primitives are adapters to PSC application semantics rather than the definition of App/Fiber/Stream.

## Methodological precedents

The design continues to use:
- Go language engineering for simplicity/tooling/dependency discipline;
- ReScript/Gleam as examples of typed JS-targeting ecosystems;
- F*, Verus, and Dafny for verification architecture comparisons;
- Koka for effect-system alternatives;
- compiler-preservation and translation-validation literature for backend assurance.

These precedents inform alternatives; no external system's proof transfers automatically to PSC.


## Specification-completion research (October 2026)

### Lean application/default arguments

Official Lean function-application documentation states that high-level application is elaborated as one unit; optional parameters are encoded with `optParam`, automatic parameters with `autoParam`, and omitted optional/automatic arguments are inserted by the application elaborator.

Source:
https://lean-lang.org/doc/reference/latest/Terms/Function-Application/

r3 consequence:
`f()` is specified as an empty source-level invocation that can use native optional/default/automatic insertion, with one special Unit synthesis for Unit-callable functions. Missing required non-Unit parameters make the empty call fail rather than eta-abstract.

### Lean field-notation adjacency

The same official reference states that generalized field notation is a term followed by `.` and an identifier **not separated by spaces**.

Source:
https://lean-lang.org/doc/reference/latest/Terms/Function-Application/

r3 consequence:
`users.map(render)` is supported; `users .map(render)` is not added by r3.

### Lean elaborator power

Lean's official elaborator reference states that term/command elaborators can access the same machinery used by Lean itself; command elaborators can mutate environment tables and use IO.

Source:
https://lean-lang.org/doc/reference/latest/Notations-and-Macros/Elaborators/

r3 consequence:
the Standard parser/extension environment is fixed by `PS-STANDARD-REGISTRY-r3.json`; package imports cannot silently mutate parser/elaborator tables.

### Node and TypeScript package resolution

Node's current package documentation defines conditional `exports`, ordered condition matching, package `type`, subpath exports and import/require distinctions.

Source:
https://nodejs.org/api/packages.html

TypeScript's current module-resolution reference says modern `node16`, `nodenext`, and `bundler` modes consult package `exports`; TypeScript additionally considers `types`, versioned `types@` conditions and configured custom conditions while prioritizing type files after runtime-style resolution.

Source:
https://www.typescriptlang.org/docs/handbook/modules/reference

r3 consequence:
InterfaceIR v1 binds TypeScript version/resolver mode, conditions, package.json identity, export subpath, selected runtime entry and selected type entry. A package name plus one `.d.ts` path is insufficient identity.

### Stateful frames

Dafny's current reference uses explicit read/modify frame specifications to bound heap effects.

Source:
https://dafny.org/dafny/DafnyRef/DafnyRef

r3 consequence:
PSC contract semantics now includes a `FrameSpec` concept even though only pure `requires`/`ensures` surface syntax is frozen in base r3.

### Higher-order contracts

Verus documents generic pre/post predicates for function values through `call_requires` and `call_ensures`.

Sources:
https://verus-lang.github.io/verus/guide/exec_funs_as_values.html
https://verus-lang.github.io/verus/guide/reference-signature-fnonce.html

r3 consequence:
PSC defines its own ordinary logical `CallableSpec`, `callRequires`, and `callEnsures` model for future higher-order verification; these are not kernel primitives.

### WASI 0.3 async

WASI 0.3 was ratified in June 2026. Current Component Model documentation exposes `async func`, `future<T>`, and `stream<T>` as Canonical ABI primitives.

Sources:
https://bytecodealliance.org/articles/WASI-0.3
https://component-model.bytecodealliance.org/design/async.html

r3 consequence:
these are target mechanisms for implementing the already-defined PSC App/Fiber/Stream model, not the source semantics of those abstractions.
