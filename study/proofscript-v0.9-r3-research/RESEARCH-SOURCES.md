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

The official Lean function-application reference states that core functions are unary/curried while the high-level application elaborator handles positional, named, implicit, instance, strict-implicit, optional and automatic parameters as one application unit.

It also documents the native application ellipsis form:

~~~lean
f ..
~~~

and states that optional parameters use optParam and automatic parameters use autoParam.

Source:
https://lean-lang.org/doc/reference/latest/Terms/Function-Application/

r3 consequence:
- nonempty parenthesized calls lower to one native high-level application object;
- empty parenthesized calls lower to a native ellipsis application and then apply the r3 rule that forbids omission of ordinary required explicit parameters;
- zero-source-argument function sugar lowers to an optional Unit binder with default ();
- default-only functions can therefore be called with f() without introducing JavaScript undefined.

### Lean field-notation adjacency

The official Lean function-application reference states that generalized field notation uses a dot not separated by spaces from the receiver.

Source:
https://lean-lang.org/doc/reference/latest/Terms/Function-Application/

r3 consequence:
users.map(render) is supported; users .map(render) is not added by r3.

### Lean syntax/elaborator extensibility

Official Lean documentation states that:

- macros extend syntax by translation;
- elaborators can use the same machinery as Lean's own features;
- command elaborators can modify global environment tables and use IO;
- low-level parser extensions can even alter token/whitespace rules or replace concrete syntax.

Sources:
https://lean-lang.org/doc/reference/latest/Notations-and-Macros/
https://lean-lang.org/doc/reference/latest/Notations-and-Macros/Elaborators/

r3 consequence:
ps-standard has a fixed/versioned registration closure, while ps-lean-extensible carries declared extension identities/order/options/host permissions.

### TypeScript optional/default parameters

Current TypeScript function documentation confirms that JavaScript/TypeScript default-initialized parameters can be omitted at a call and that JavaScript missing parameters otherwise become undefined.

Sources:
https://www.typescriptlang.org/docs/handbook/2/functions.html
https://www.typescriptlang.org/docs/handbook/functions

r3 consequence:
f() must not be Unit-only when the callable has native optional/default parameters. PSC uses Lean optParam/autoParam insertion and never introduces JavaScript undefined into native semantics.

### TypeScript compatibility

Official TypeScript documentation describes structural compatibility and deliberate unsoundness tradeoffs made to model JavaScript practice.

Source:
https://www.typescriptlang.org/docs/handbook/type-compatibility.html

r3 consequence:
npm/d.ts interoperability remains an explicit InterfaceIR/adapter boundary rather than a new structural native PSC type system.

### Node package exports and conditions

Current Node package documentation specifies main/exports, subpath exports, conditional exports, condition ordering, import/require distinctions, custom conditions and the community types condition.

Source:
https://nodejs.org/api/packages.html

r3 consequence:
InterfaceIR binding identity records package.json bytes/hash, export subpath, condition trace, selected runtime entry and runtime module mode.

### TypeScript package/module resolution

Current TypeScript module-reference documentation states that node16/nodenext/bundler resolution follows package exports when enabled, adds types/default and versioned types conditions, supports custom conditions, and can use different import/require branches.

Source:
https://www.typescriptlang.org/docs/handbook/modules/reference

r3 consequence:
InterfaceIR separately records runtime and declaration resolution traces, TypeScript resolver/profile identity, selected type entry and selected runtime entry. A package name plus one d.ts path is insufficient identity.

### Stateful frames

Dafny's current reference gives explicit requires/ensures specifications and read/write frame concepts, including modifies clauses that bound which memory locations a method may change.

Source:
https://dafny.org/dafny/DafnyRef/DafnyRef

r3 consequence:
psc-contract-core-v1 carries normalized effect/read/write frames even though base r3 freezes only requires/ensures surface clauses. Effect/frame semantics can therefore constrain unrelated side effects without prematurely adding a large clause syntax.

### Higher-order contracts

Verus documents generic pre/post specification predicates for callable values through call_requires and call_ensures.

Sources:
https://verus-lang.github.io/verus/guide/exec_funs_as_values.html
https://verus-lang.github.io/verus/guide/reference-signature-fnonce.html

r3 consequence:
PSC defines its own ordinary logical callable relations: callRequires, callEnsures, callEffects, callReads and callWrites. These are PSC semantics, not imported Verus kernel primitives.

### WASI 0.3 async

WASI 0.3 was ratified in June 2026. Current Component Model documentation exposes async func, future<T>, and stream<T> as Canonical ABI primitives, with host/runtime scheduling.

Sources:
https://bytecodealliance.org/articles/WASI-0.3
https://component-model.bytecodealliance.org/design/async.html
https://component-model.bytecodealliance.org/advanced/canonical-abi.html

r3 consequence:
these primitives are target mechanisms for implementing psc-app-v1. They do not define PSC App/Fiber/Stream semantics.

### Methodological conclusion

The completion pass therefore freezes:
- exact r2-delta authority;
- exact r3 call/brace grammar;
- closed Standard profile;
- semantic bundles;
- narrow contract core plus frames/higher-order relations;
- cold App / hot Fiber application semantics;
- InterfaceIR v1 with deterministic package/runtime/type identity;
- pre-stable evidence gates.

No external system's proof or runtime behavior is assumed to transfer automatically to PSC.


### Lean lexical whitespace and structural emptiness

The official Lean source-file reference states that ordinary lexical whitespace consists of spaces, newline sequences, or comments; tabs are not ordinary Lean whitespace.

Source:
https://lean-lang.org/doc/reference/latest/Source-Files-and-Modules/

The current structure declaration reference and source description show `structFields` as a repeated field sequence, and Lean's structure implementation explicitly accounts for structures with no fields.

Sources:
https://lean-lang.org/doc/reference/latest/The-Type-System/Inductive-Types/
https://github.com/leanprover/lean4/blob/master/src/Lean/Elab/Structure.lean

r3 consequence:
- CallGap does not introduce tab-as-whitespace as a one-off lexical exception;
- structural structure/class bodies permit zero fields where native semantics permits them;
- the exact r3 grammar also permits zero constructors for native-valid empty inductive declarations and zero instance fields where native semantics permits them.

The pinned Lean 4.34 source in the repository remains normative over current-master implementation detail.
