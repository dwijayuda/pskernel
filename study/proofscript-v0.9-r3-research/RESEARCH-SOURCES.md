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
