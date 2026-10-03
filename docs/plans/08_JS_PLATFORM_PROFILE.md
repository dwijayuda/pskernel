# PSC JavaScript Platform Profile v1

**Status:** planned platform profile; not a ProofScript source-language profile

**Profile identity:** \`psc-js-platform-v1\`

**Language prerequisite:** \`psc2-standard-language-v1\`

**Interop prerequisite:** InterfaceIR v1 or a compatible successor

**Application-semantics prerequisite:** the accepted \`App\` / \`Fiber\` / \`Exit\` / \`Resource\` / \`Stream\` model

This document defines the platform capabilities required before ProofScript can reasonably claim to replace TypeScript for ordinary JavaScript-ecosystem development.

It deliberately does **not** enlarge \`psc2-language-v1\`.

The guiding equation is:

~~~text
TypeScript replacement
=
adequate ProofScript language
+ JavaScript/npm interoperability
+ application/runtime libraries
+ package publication
+ first-class tooling
~~~

The PSC2 language itself remains small and Lean-compatible.

---

# 1. Design principles

## 1.1 Keep the language small

Do not add a TypeScript feature to ProofScript core merely because a \`.d.ts\` file uses it.

Prefer this ownership order:

~~~text
ordinary library
-> generated binding
-> runtime adapter
-> InterfaceIR normalization
-> official extension
-> controlled plugin
-> new language syntax only when unavoidable
~~~

## 1.2 Preserve Lean semantics

Foreign JavaScript and TypeScript declarations do not redefine ProofScript type theory.

No foreign declaration file is proof evidence.

No JavaScript runtime behavior silently becomes a theorem.

## 1.3 Fail closed

Unsupported foreign shapes reject or require an explicit adapter.

They never degrade to native \`any\`.

## 1.4 Go-like platform philosophy

Prefer a small number of orthogonal language mechanisms and move ecosystem breadth into packages, generated bindings, and explicit host adapters.

---

# 2. Profile boundary

\`psc-js-platform-v1\` is a platform/product capability profile.

It is not:

- a new trusted logical theory;
- a new kernel profile;
- a replacement for \`psc2-language-v1\`;
- permission to add arbitrary TypeScript syntax to \`.ps\`;
- a promise of full JavaScript dynamic behavior inside native ProofScript.

A toolchain claiming \`psc-js-platform-v1\` must satisfy the acceptance gates in this document.

---

# 3. Module and package interoperability

## 3.1 Native ProofScript module API

Current PSC2 language rules remain:

~~~proofscript
import Internal.Module
public import Public.Module
~~~

Ordinary top-level declarations are public unless \`private\`.

\`public import\` is the core language re-export mechanism.

No TypeScript-style export-list syntax is required in PSC2 core.

## 3.2 JavaScript host-module consumption

The platform profile must support foreign bindings for at least:

- ESM named imports;
- ESM default exports;
- ESM namespace objects;
- package subpaths;
- package export maps;
- conditional exports;
- package import maps where the target runtime supports them;
- Node built-in modules;
- browser ESM;
- CommonJS through an explicit adapter/resolution mode;
- dynamic module loading through an application/runtime API.

These need not become native PSC2 import syntax.

Generated binding packages may expose ordinary ProofScript APIs while host-binding metadata records the actual foreign module form.

## 3.3 Resolver identity

Foreign package resolution must bind enough information to reproduce the chosen runtime and type surfaces, including:

- package name;
- exact package version where required by the selected reproducibility policy;
- requested subpath;
- package.json identity;
- runtime export condition trace;
- type/declaration condition trace;
- target runtime/platform;
- TypeScript resolver version/profile;
- selected runtime entry;
- selected declaration entry;
- declaration-file identities.

The existing InterfaceIR resolution identity is the baseline.

## 3.4 CommonJS

CommonJS support is a platform adapter concern.

Do not add CommonJS semantics to ProofScript core.

The adapter must state:

- default-export projection policy;
- named-export discovery policy;
- live-binding vs snapshot behavior;
- callable/constructable module behavior;
- \`module.exports\` / \`exports\` assumptions;
- failure conditions.

Unsupported or ambiguous CJS shapes reject or require handwritten bindings.

## 3.5 Dynamic import

Dynamic import should be exposed through ordinary application/runtime APIs rather than adding JavaScript's exact dynamic-import semantics to the core language.

The result must preserve:

- typed failure;
- capability requirements;
- module identity;
- runtime fault separation.

---

# 4. TypeScript declaration ingestion

The platform must consume real \`.d.ts\` packages through InterfaceIR or a compatible normalized representation.

Every imported feature is classified as one of:

~~~text
native
specialized
runtime-adapter
opaque-handle
import-normalization
unsupported
~~~

Unsupported never means native \`any\`.

---

# 5. Required foreign type coverage

## 5.1 Primitive values

Required coverage:

- string;
- boolean;
- number;
- bigint;
- null;
- undefined;
- missing/optional property state;
- symbol where needed by supported APIs.

Mappings must be explicit.

For example, JavaScript \`number\` is not silently equivalent to \`Nat\` or \`Int\`.

## 5.2 unknown and any

Foreign \`unknown\` / \`any\` map to an opaque/dynamic foreign value abstraction.

They require explicit:

- validation;
- decoding;
- type refinement;
- or an explicit foreign assumption.

They do not become native ProofScript \`any\`.

## 5.3 Arrays and tuples

Support:

- mutable JS arrays through explicit mutable/adapter semantics;
- readonly arrays;
- fixed tuples;
- optional tuple entries where present;
- rest tuple entries where supported by the importer.

Native immutable/logical collection semantics remain distinct from foreign identity/mutation semantics.

## 5.4 Structural object types

Foreign structural object types must be imported as one of:

- generated nominal wrapper;
- validated native record;
- opaque foreign handle;
- raw structural InterfaceIR node consumed through an adapter.

Do not make ProofScript structures structurally assignable merely to match TypeScript.

## 5.5 Optional properties

The importer must preserve the distinction among:

~~~text
missing
undefined
null
value
~~~

A generated adapter may collapse states only under an explicit presence policy.

## 5.6 readonly

TypeScript \`readonly\` is foreign static metadata.

It does not automatically imply a deep runtime immutability theorem.

## 5.7 Literal and discriminated unions

Finite discriminated unions should normalize to generated inductive/variant representations where exact discrimination is available.

Ambiguous structural unions require runtime validation or remain unsupported.

## 5.8 Intersection types

Intersections should be normalized only where a sound finite representation exists.

Otherwise they require a generated wrapper/validator or reject.

They do not become a native PSC intersection-type operator.

## 5.9 Branded types

Map to one of:

- validated wrapper;
- opaque brand handle;
- explicit foreign assumption.

A brand declaration alone is not proof.

---

# 6. TypeScript type computation

The importer must handle common declaration-only type computation without adding those operators to ProofScript source.

## 6.1 keyof

Finite \`keyof\` computations may normalize at import time.

No native PSC2 \`keyof\` operator is required.

## 6.2 Indexed access

Finite indexed-access types may normalize to an ordinary generated PSC type.

## 6.3 Conditional types

Supported finite conditional types should normalize during import.

Open-ended or undecidable cases reject.

## 6.4 Mapped types

Supported finite mapped types should normalize to generated record/interface descriptions.

## 6.5 Template literal types

Finite resolvable template-literal types may normalize to literal unions or validators.

Unbounded cases may remain unsupported.

---

# 7. Generic APIs

Support ordinary parametric TypeScript generics where they can map soundly to ProofScript polymorphism or finite specialization.

Examples:

~~~text
Array<T>
Promise<T>
Map<K,V>
Result<T,E>-style declarations
~~~

Importer behavior may be:

- native parametric mapping;
- generated specialization;
- runtime adapter;
- unsupported.

Do not copy TypeScript's entire generic constraint/type-operator model into PSC core.

---

# 8. Functions

Foreign function bindings must describe:

- type parameters;
- parameters;
- optional parameters;
- rest parameters;
- result;
- receiver/\`this\`;
- sync/async kind;
- throw policy;
- capabilities/effects;
- overload group;
- callback lifetime behavior where relevant.

---

# 9. Optional parameters

Optional foreign parameters should map to an explicit generated wrapper policy.

Possible wrapper forms include:

- PSC default parameter;
- \`Option\`;
- presence descriptor;
- multiple generated wrappers.

The choice must preserve the foreign call distinction.

---

# 10. Rest and variadic parameters

Rest parameters are a foreign binding concern.

Generated native wrapper example:

~~~proofscript
function logMany(values: Array String): App caps err Unit := ...
~~~

An official convenience extension may later offer variadic call sugar, but it is not required by \`psc2-language-v1\`.

---

# 11. Overloads

TypeScript overload groups should become:

- specialized wrapper functions;
- an explicit generated sum/dispatch wrapper;
- or unsupported.

Prefer distinct ProofScript names when that makes the API clearer.

Do not add TypeScript overload-resolution semantics to PSC2 core.

---

# 12. Callable and constructable objects

The binding layer must support foreign values that have:

- call signatures;
- construct signatures;
- properties plus call signatures;
- receiver requirements.

Use explicit wrapper operations.

Do not add implicit object-to-function coercion to ProofScript.

---

# 13. JavaScript classes and objects

Foreign JS class instances and DOM objects should normally be opaque identity-bearing handles.

Generated bindings expose:

- constructors;
- methods;
- properties;
- static operations;
- disposal/lifetime rules.

Native ProofScript \`class\` remains a typeclass abstraction, not JavaScript OO class semantics.

---

# 14. Receiver / this

Foreign methods with \`this\` requirements must record the receiver explicitly.

Generated wrappers must preserve receiver binding.

Do not reinterpret ProofScript generalized field notation as dynamic JavaScript \`this\` dispatch.

---

# 15. Callbacks

Callback bindings must record at least:

- synchronous vs deferred invocation;
- reentrant vs non-reentrant;
- one-shot vs repeated;
- retained vs immediate;
- invocation after disposal;
- thread/event-loop assumptions where relevant;
- typed error propagation;
- runtime fault propagation;
- cancellation relation.

A callback is an ordinary ProofScript function value plus foreign lifetime/effect metadata.

No arrow-lambda syntax is required in PSC2 core.

---

# 16. Promise interoperability

JavaScript Promise is a foreign asynchronous mechanism.

It does not define ProofScript application semantics.

Required adapters map Promise behavior into the accepted application model.

At minimum distinguish:

~~~text
foreign promise started/running handle
typed adapter failure
runtime rejection/fault classification
cancellation limitations
~~~

A Promise normally maps to the started/foreign-async side, not to the definition of cold \`App\`.

---

# 17. Iterable

Foreign \`Iterable<T>\` should adapt to an iterator/collection library interface.

No native \`yield\` syntax is required.

---

# 18. AsyncIterable and streams

Foreign \`AsyncIterable<T>\` and supported stream APIs should adapt to:

~~~text
Stream caps err T
~~~

only when the adapter specifies:

- demand/backpressure;
- cancellation;
- cleanup;
- terminal error mapping;
- late callback behavior.

---

# 19. Typed predicates and assertion signatures

TypeScript type predicates and assertion signatures are not proof by declaration.

A generated adapter may provide a runtime refinement function.

To obtain a theorem, a separately justified correspondence proof/specification is required.

---

# 20. Declaration merging and module augmentation

Do not add TypeScript declaration merging to ProofScript semantics.

Instead:

~~~text
TypeScript declarations
+ augmentations
+ merged module view
      ↓
import normalization
      ↓
InterfaceIR
      ↓
ordinary generated ProofScript declarations
~~~

Unsupported dynamic augmentation rejects.

---

# 21. Application effect model

Portable application code should use ordinary library semantics centered on:

~~~text
App caps err result
Fiber caps err result
Exit err result
RuntimeFault
Resource caps err value
Stream caps err item
~~~

These are library/runtime semantics, not kernel primitives.

---

# 22. Capabilities

Effects such as the following require explicit capability representation:

- filesystem;
- network;
- clock;
- random;
- process;
- environment;
- console;
- storage;
- DOM;
- worker/thread facilities;
- dynamic module loading.

Ambient host globals do not automatically grant capabilities to portable Standard code.

---

# 23. Typed errors and runtime faults

Keep distinct:

~~~text
typed application failure
runtime/host fault
cancellation
resource-limit/host termination
~~~

Arbitrary JavaScript \`throw\` values do not automatically inhabit a declared PSC typed error.

Adapters may explicitly classify selected throws.

---

# 24. Resource management

Use \`Resource\`-style deterministic acquisition/release semantics.

Required properties:

- exactly-once required release after successful acquisition;
- cleanup on success;
- cleanup on typed failure;
- cleanup on cancellation;
- shielded cleanup from ordinary cooperative cancellation;
- preservation of both body and cleanup failures.

A future \`using\`/\`defer\` syntax extension may lower to these semantics.

---

# 25. Structured concurrency

\`Fiber\` denotes started work.

Required operations/relations include:

- fork/start;
- join;
- cancellation request;
- terminal observation;
- race;
- timeout;
- owned child scopes;
- explicit detach policy if provided.

Do not define these through JavaScript Promise alone.

---

# 26. Mutable identity

Native logical data remains value-oriented.

Shared mutable identity requires explicit state/reference abstractions.

Foreign objects with identity remain opaque handles or adapter-managed references.

Do not import JavaScript aliasing semantics into structures.

---

# 27. Standard JavaScript platform bindings

Before claiming \`psc-js-platform-v1\`, the distribution should provide broad maintained bindings for the relevant target environments.

## 27.1 ECMAScript built-ins

Representative families:

- Object;
- String;
- Number;
- BigInt;
- Math;
- JSON;
- RegExp;
- Date where supported by target policy;
- Map;
- Set;
- WeakMap/WeakSet as opaque identity structures where appropriate;
- Array;
- typed arrays;
- ArrayBuffer/DataView;
- Promise adapters;
- Intl where targeted.

## 27.2 Node platform

Representative families:

- filesystem;
- paths;
- URLs;
- process/environment;
- console;
- buffers;
- streams;
- events;
- HTTP/HTTPS;
- fetch where available;
- crypto;
- timers;
- child processes;
- workers;
- DNS/networking;
- compression;
- module/package utilities.

## 27.3 Browser/Web platform

Representative families:

- DOM;
- events;
- fetch;
- URL;
- WebSocket;
- Streams;
- AbortController/AbortSignal;
- storage;
- workers;
- File/Blob;
- canvas;
- forms;
- timers;
- history/location;
- crypto;
- selected media APIs where maintained;
- optional WebGPU profile when mature enough.

These should be packages/bindings, not core language constructs.

---

# 28. UI ecosystem

React/Vue/Svelte-style frameworks should be supported through packages and plugins.

A future \`.psx\` dialect may provide UI syntax.

That dialect must remain separately versioned and lower to ordinary ProofScript/library semantics.

JSX/TSX parity is not required in \`psc2-language-v1\`.

---

# 29. Package publication

ProofScript packages targeting JS consumers should be able to publish:

~~~text
JavaScript artifacts
generated .d.ts declarations
package.json exports
source maps
runtime metadata
ProofScript semantic artifacts where applicable
~~~

A normal TypeScript/JavaScript consumer should not need ProofScript tooling merely to consume the emitted JS package unless ProofScript-specific proof artifacts are explicitly requested.

---

# 30. .d.ts generation

Generated declaration files must describe the runtime-facing public JS API.

They must not claim stronger semantics than the emitted runtime actually provides.

Logical ProofScript propositions/contracts may be exported separately as ProofScript metadata/specifications; they should not be encoded as misleading TypeScript runtime guarantees.

---

# 31. Source maps and debugging

The platform profile requires source mapping sufficient for:

- runtime stack traces;
- debugger stepping;
- breakpoints;
- JS artifact diagnostics;
- generated binding diagnostics.

Where transformations pass through TypeScript or another intermediate target, mappings must compose back to ProofScript source as accurately as practical.

---

# 32. Build-system integration

Required production integrations should include at least a clear path for:

- npm;
- workspaces/monorepos;
- Node;
- browser builds;
- common ESM bundlers;
- watch mode;
- test runners;
- CI.

Support for pnpm, Yarn, Bun, Deno, Vite, Rollup, esbuild, webpack or similar tools may be delivered through packages/plugins rather than core compiler behavior.

The profile should define minimum supported integrations per release.

---

# 33. Language service

Before a TypeScript-replacement claim, editor tooling should provide:

- diagnostics;
- completion;
- hover/type information;
- go to definition;
- find references;
- rename;
- document/workspace symbols;
- auto-import;
- module navigation;
- formatting;
- code actions;
- source-kind awareness for \`.ps\` and supported \`.lean\`;
- foreign-binding navigation where generated bindings retain provenance.

---

# 34. Formatter

Formatting must be deterministic for Standard source.

It must preserve:

- CallGap ownership;
- braced single-term definition bodies;
- structure/class separator rules;
- match/inductive bars;
- instance/where semicolons;
- native nested category meaning.

---

# 35. Package corpus gate

Interop should be tested against a representative package corpus rather than toy declarations.

The corpus should cover:

- simple ESM utilities;
- default exports;
- namespace exports;
- class-heavy APIs;
- callback-heavy APIs;
- Promise-heavy APIs;
- stream/AsyncIterable APIs;
- overload-heavy APIs;
- advanced generic declarations;
- mapped/conditional/template literal types;
- declaration merging/module augmentation;
- Node packages;
- browser packages;
- UI framework declarations;
- database/client libraries;
- validation/schema libraries.

Each unsupported case must fail explicitly and document the required adapter.

---

# 36. Reference application gate

At least these application classes should be implemented primarily in ProofScript source:

- CLI tool;
- Node service;
- browser application;
- npm library consumed from TypeScript;
- ProofScript application consuming ordinary npm packages;
- callback-heavy integration;
- async/resource-heavy integration;
- UI application through the selected UI package/dialect when that profile exists.

The goal is to validate the platform, not merely syntax.

---

# 37. Security and trust boundary

Foreign bindings must clearly separate:

- logical axioms;
- runtime assumptions;
- package-resolution assumptions;
- validator/decoder evidence;
- generated wrapper code;
- runtime faults;
- host permissions/capabilities.

A \`.d.ts\` declaration is never proof of runtime behavior.

---

# 38. Non-goals

\`psc-js-platform-v1\` does not require:

- adding native \`any\`;
- TypeScript structural assignability;
- TypeScript conditional/mapped/template types in ProofScript source;
- JS prototype inheritance as native semantics;
- JavaScript truthiness;
- ambient null/undefined;
- JavaScript automatic semicolon insertion;
- Promise as PSC async semantics;
- JavaScript statement blocks;
- TypeScript overload resolution in PSC core;
- declaration merging in PSC core;
- native JS decorators;
- universal support for every dynamically generated/proxy-based npm API without adapters.

---

# 39. Relationship to future official extensions

Useful later extensions may include:

~~~text
psc-iteration-v1
psc-async-syntax-v1
psc-patterns-v2
psc-verify-v2
psc-psx-v1
~~~

These are ergonomic layers.

They must not be prerequisites for the correctness of the underlying platform semantics.

---

# 40. Acceptance gates

A toolchain may claim \`psc-js-platform-v1\` only when all required gates are met.

## J1 — module/package resolution

Demonstrate deterministic resolution for the supported ESM/CJS/package-export surface.

## J2 — declaration ingestion

Import the required InterfaceIR feature matrix from a representative \`.d.ts\` corpus.

## J3 — runtime adapters

Conformance tests for:

- callbacks;
- Promises;
- AsyncIterable/streams;
- classes/handles;
- typed throws/faults;
- presence states;
- mutable arrays/objects.

## J4 — standard platform packages

Ship supported Node and browser/Web bindings for the declared target set.

## J5 — publication

Publish a ProofScript-authored package consumable from JavaScript and TypeScript with generated \`.d.ts\`.

## J6 — application semantics

Pass cross-runtime application traces for:

- success;
- typed failure;
- RuntimeFault;
- cancellation;
- timeout;
- race;
- resource cleanup;
- stream backpressure;
- late callbacks.

## J7 — tooling

Meet the minimum LSP/formatter/source-map/watch-mode expectations defined by the release.

## J8 — reference apps

Complete the required application corpus without introducing ad hoc language syntax to bypass platform gaps.

---

# 41. Final rule

Do not grow \`psc2-language-v1\` merely to satisfy \`psc-js-platform-v1\`.

If a JavaScript ecosystem problem can be solved by:

~~~text
binding
adapter
library
generator
extension
plugin
tooling
~~~

it should stay there.

The target architecture is:

~~~text
JS frameworks / npm ecosystem
            |
            v
    psc-js-platform-v1
  InterfaceIR + bindings
 App/Resource/Stream adapters
            |
            v
 psc2-standard-language-v1
            |
            v
     psc2-language-v1
            |
            v
Lean-compatible logical foundation
~~~

This profile is the recommended place to finish the TypeScript-replacement goal while keeping the ProofScript language small, predictable, Lean-faithful, and Go-like in philosophy.
