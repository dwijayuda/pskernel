# PSC3 Standard Library, Packages and FFI

Status: **platform design draft**

A general-purpose language does not become practical through syntax alone.

PSC3 needs a deliberate standard platform that makes ordinary application development possible without continually crossing into handwritten JavaScript.

## 1. Standard-library principle

The kernel remains small.

The standard library may be substantial.

Library size does not imply logical trust when declarations/proofs are checked through ordinary mechanisms.

PSC3 standardization should distinguish:
- language-prelude essentials;
- portable standard library;
- platform capability libraries;
- optional official packages;
- foreign ecosystem bindings.

## 2. Prelude

The prelude should remain small and stable.

Candidate contents:
- Bool;
- Nat/Int and scalar interfaces;
- Unit;
- Option;
- Result;
- basic equality/order/typeclass interfaces;
- List/Array essentials;
- String/Char essentials;
- foundational effect interfaces needed by ordinary syntax.

Avoid importing large IO/network/UI stacks implicitly.

## 3. Portable standard library

A serious PSC3 standard distribution should cover:

### Data
- List;
- Array;
- Vector/bounded array where useful;
- Option;
- Result;
- tuples/products;
- ordered Map/Set;
- hash map/set through explicit hash contracts;
- Queue/Deque;
- immutable collection helpers.

### Text and bytes
- String/Text;
- Char;
- Bytes/ByteArray;
- UTF conversions;
- builders;
- parsing utilities.

### Numeric
- exact Nat/Int;
- fixed-width integer utilities;
- Float/Float32;
- checked conversions;
- decimal or arbitrary precision decimal package where application demand justifies it.

### Encoding/data interchange
- JSON;
- codecs;
- schemas;
- Base64;
- URL encoding;
- binary codec primitives.

### Time
- Duration;
- Instant;
- civil date/time;
- timezone integration through explicit data/provider.

Do not expose JavaScript Date as PSC's source semantics.

### Algorithms
- sorting/searching;
- iterators/folds;
- collections;
- parser combinators;
- common functional utilities.

### Testing
- assertions;
- table tests;
- property testing;
- golden/snapshot helpers;
- fuzz inputs;
- theorem/spec tests.

## 4. Platform libraries

These require declared capabilities.

### Filesystem

Typed path/file/resource APIs with deterministic cleanup.

### Network

TCP/UDP where supported, HTTP client/server abstractions, TLS adapter.

### Process

Explicit subprocess and environment capabilities.

### Clock/randomness

Separate deterministic logical interfaces from runtime nondeterminism.

### Console/logging

Structured logging should be a library/platform concern.

### Browser

DOM, fetch, URL, storage, workers, crypto and events through typed adapters.

## 5. Application effect

PSC3 should study whether one conventional application effect improves usability.

Conceptually:

~~~text
App A
~~~

could provide a standardized composition context for declared capabilities and typed failure.

It must not become an unrestricted "anything can happen" IO token that hides dependencies.

A program/package manifest should still expose required capabilities.

This remains a **CANDIDATE**, not a frozen semantic construct.

## 6. Task and Resource

Task is the standard asynchronous abstraction.

Resource/bracket is the standard deterministic lifetime abstraction.

Both should be libraries with limited source sugar unless evidence shows foundational semantics is required.

## 7. Package model

A package has:
- name;
- version;
- PSC edition;
- source/profile requirements;
- dependencies;
- public exports;
- capability requirements;
- target requirements;
- build/test/doc tasks;
- optional plugin declarations;
- optional assurance policy.

Package resolution is deterministic and lockfile-backed.

## 8. Package namespaces

Use an ecosystem-friendly convention without making npm's registry layout the semantic namespace.

Possible source specifiers:

~~~text
@proofscript/http
@proofscript/json
github:owner/project
./local/module
~~~

Exact syntax and registry policy require separate package-manager design.

## 9. npm packages

npm is a primary ecosystem source.

PSC tooling should support:

~~~text
psc add npm:package
psc bind npm:package
~~~

or equivalent commands.

The tool:
1. resolves the package/version;
2. reads export metadata;
3. reads .d.ts when available;
4. generates a PSC binding package;
5. identifies unsupported/dynamic pieces;
6. records runtime/effect/trust metadata.

Generated bindings are reproducible artifacts.

## 10. Binding generation

A binding generator should produce three layers where useful:

### Raw foreign layer

Close mapping of foreign API.

### Safe adapter

Converts:
- null/undefined -> Option;
- thrown/rejected errors -> Result/Task failure;
- JS values -> validated PSC values;
- callbacks/resources -> explicit PSC effects.

### Specification layer

Optional theorems/contracts/models describing the adapter/API.

Only this layer can support stronger verified client claims.

## 11. FFI declaration model

Every external declaration should specify:

~~~text
foreign identity
target/platform
runtime representation
purity/effect
synchronous/asynchronous
failure behavior
resource behavior
cancellation behavior
trust status
optional logical specification
~~~

Illustrative source:

~~~proofscript
extern js "@scope/pkg" {
  function parse(input: String): Foreign JsonValue
    effect ForeignCall
}
~~~

Exact syntax is not frozen.

## 12. Trust statuses

Suggested statuses:

~~~text
unverified-external
runtime-validated
modeled-external
verified-adapter
trusted-assumption
~~~

The language/tooling should never convert one status to a stronger one because a TypeScript declaration exists.

## 13. Dynamic JavaScript

Some JS APIs are too dynamic for direct static binding.

PSC3 may expose a bounded foreign dynamic value type in the JS interop layer.

Operations on it are explicit and remain outside strict verification until validated/refined.

This must not become a backdoor equivalent of native any.

## 14. Callbacks

Foreign callbacks require specified:
- argument conversion;
- lifetime;
- reentrancy;
- error propagation;
- async behavior.

A callback that can be retained by JS is not equivalent to an ordinary immediate higher-order call unless the adapter proves/models that behavior.

## 15. Objects and identity

Foreign JavaScript object identity may be represented by an opaque handle/reference type.

It is distinct from PSC structural/logical equality.

Adapters can expose stable logical models where appropriate.

## 16. Exceptions and rejected promises

Foreign adapters catch known recoverable failures and convert them to declared PSC error channels.

Unexpected host exceptions may become a separate ForeignPanic/runtime failure class.

Do not silently treat arbitrary thrown values as a typed domain error.

## 17. WebAssembly interfaces

PSC package public APIs should be translatable to WIT/Component Model interfaces for the supported Wasm profile.

Where a PSC type is not representable directly:
- generate an adapter;
- reject the export;
- use an explicit resource/opaque interface.

The mapping is versioned.

## 18. Database ecosystem

PSC3 does not need an ORM in the language.

Official/community packages can provide:
- SQL drivers;
- query builders;
- schema/code generation;
- migrations;
- transaction abstractions;
- verified/query contracts where practical.

Transactions are effect/resource semantics, not ordinary mutable variables.

## 19. Web frameworks

HTTP/router/framework packages should remain libraries.

Language support should provide enough:
- async;
- patterns;
- codecs;
- modules;
- resources;
- capability interfaces;

that frameworks do not need compiler-private magic.

Controlled build plugins may generate routes/assets/types.

## 20. Library design standards

Official PSC packages should:
- use explicit Result/Option;
- expose deterministic behavior where promised;
- document complexity where important;
- report effects/capabilities;
- include examples/tests;
- avoid unnecessary macros/plugins;
- expose specification theorems for critical operations where useful.

## 21. Package assurance

A package build may publish:
- source identity;
- CheckedCore identity;
- assumptions;
- target artifacts;
- dependency lock identity;
- target/runtime profile;
- proof status;
- compiler-preservation status.

Consumers choose assurance policy.

## 22. Security/update model

Package signatures/integrity and lockfiles protect provenance, not semantics.

Supply-chain tooling should be integrated, but a cryptographically authentic package may still contain incorrect or malicious code.

Verification claims remain explicit and scoped.

## 23. Standard-library growth rule

A new standard API should require evidence that:
- it is broadly needed;
- interoperability benefits from standardization;
- multiple competing semantics would fragment the ecosystem;
- it can remain stable.

Specialized frameworks belong in packages rather than the core distribution.

## 24. Initial standard-platform roadmap

Priority:

1. collections/text/bytes/result/option;
2. JSON/codecs/schema;
3. filesystem/process/console;
4. HTTP/URL;
5. Task/Resource/clock/random;
6. testing/property testing;
7. browser/DOM/fetch;
8. npm binding generator;
9. database packages;
10. UI framework adapters.

Full applications depend at least as much on this roadmap as on new syntax.
