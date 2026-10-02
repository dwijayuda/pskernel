# PSC3 Full Applications and JavaScript Ecosystem

Status: **application-platform design draft**

PSC3 is intended to build complete applications, not only proof libraries.

JavaScript ecosystem integration is therefore a primary product requirement.

## 1. Deployment goals

A PSC3 developer should be able to build:

~~~text
CLI
Node/Bun/Deno service
browser application
npm library
UI application
worker/serverless function
Wasm component
mixed JS/PSC application
~~~

without rewriting the application shell in TypeScript merely because ProofScript lacks standard platform APIs.

## 2. Primary JavaScript artifact

The preferred JS backend emits:
- deterministic modern ESM JavaScript;
- source maps;
- generated .d.ts for public runtime APIs;
- an assurance/provenance manifest;
- optional metadata for runtime validators/codecs.

The generated JavaScript should be readable enough for debugging and ecosystem integration.

Readability is not a proof property, but it is an adoption property.

## 3. ESM-first module strategy

Native PSC packages map to explicit ESM exports.

Example conceptual package:

~~~text
src/
  index.ps
  http.ps
proofscript.json
proofscript.lock

build/
  index.js
  index.d.ts
  http.js
  http.d.ts
  assurance.json
~~~

Generated package metadata should use modern package exports/imports rather than relying on filesystem accidents.

CommonJS is an interoperability target, not the native PSC module model.

## 4. npm compatibility

PSC3 should consume npm packages through binding packages.

Three binding sources are useful:

### Generated .d.ts binding

~~~text
package .d.ts
    |
    v
PSC binding generator
    |
    v
typed foreign declarations
~~~

Generated typings establish a static interface mapping.

They do not establish runtime validation or logical truth.

### Hand-authored adapter

Used when:
- runtime representation differs;
- API overloads are complex;
- exceptions must become Result;
- callbacks/resources need semantic adaptation;
- specifications are added.

### Verified/modeled adapter

The strongest form provides evidence connecting the foreign model/adapter to the contract used by PSC code.

A foreign library itself may remain an assumption.

## 5. Advanced TypeScript declarations

A .d.ts importer will encounter:
- overloads;
- structural interfaces;
- unions/intersections;
- conditional types;
- mapped types;
- keyof/indexed access;
- template literal types;
- declaration merging;
- globals/ambient modules.

PSC3 should not force all of these into native types.

The importer may:
- normalize a supported construct into PSC types;
- generate a wrapper;
- expose a bounded dynamic/foreign representation;
- reject unsupported declarations with diagnostics.

Interop completeness and native-language simplicity are separate objectives.

## 6. Boundary validation

A TypeScript declaration does not enforce values at runtime.

PSC3 should make runtime codecs/validators standard at untrusted boundaries.

Example:

~~~proofscript
const raw: JsValue = ...
const user: Result DecodeError User = User.decode(raw)
~~~

Generated API/schema support should make this cheap.

Potential standard derivations:
- JSON codec;
- schema;
- runtime validator;
- stable wire representation;
- TypeScript declaration.

Generated code still passes through ordinary checking.

## 7. Runtime/platform profiles

### Browser

Capabilities:
- fetch/network;
- URL;
- DOM;
- storage;
- timers;
- crypto;
- workers;
- streams.

DOM identity/mutation is a foreign capability model, not ordinary immutable structure semantics.

### Node

Capabilities:
- filesystem;
- process;
- network;
- environment;
- streams;
- workers;
- package interop.

### Bun

Treat Bun as a JS runtime/toolchain profile.

PSC semantics remain unchanged.

### Deno

Treat Deno as a capability/runtime profile with explicit npm and permission/environment integration.

### Edge/serverless

Expose only the platform's declared capabilities.

Do not make ambient globals part of portable PSC source semantics.

## 8. Package manifest philosophy

PSC3 should have one small canonical project manifest.

**CANDIDATE names:**

~~~text
proofscript.json
proofscript.lock
~~~

The manifest should cover:
- package identity/version;
- source roots;
- dependencies;
- PSC edition/profile;
- targets;
- capabilities;
- public exports;
- test/build tasks;
- assurance policy.

Avoid a large compiler-option matrix.

Provide named profiles with explicit semantic consequences.

Generated package.json/Cargo-like metadata is output/adaptation, not the primary source of PSC project meaning.

## 9. Dependency model

Dependencies must be explicit and versioned.

The lockfile should capture:
- exact package versions;
- integrity;
- binding-generation identity;
- semantic profile requirements;
- optional assurance metadata.

Dependency installation must not silently add compiler macros or trusted kernel behavior.

Plugins are explicit dependencies with declared capabilities.

## 10. Full server application example

Conceptual PSC app:

~~~proofscript
import { HttpServer } from "@proofscript/http"
import { Json } from "@proofscript/json"
import { Users } from "./users"

export async function main(): App Unit {
  using server <- HttpServer.listen(port: 8080) {
    await server.route("/users/:id", async request => {
      const id = try UserId.parse(request.param("id"))
      const user = await Users.load(id)

      match user {
        | .ok(value) => HttpResponse.json(value)
        | .error(.notFound) => HttpResponse.notFound()
        | .error(err) => HttpResponse.serverError(err)
      }
    })

    await server.run()
  }
}
~~~

The exact syntax is illustrative.

The important point is that PSC3 platform libraries must make this application feasible without dropping into JavaScript for basic IO/control flow.

## 11. Full browser app

A browser application should combine:
- .ps modules;
- optional .psx components;
- generated bindings for npm packages;
- direct JS output;
- bundler/dev-server integration;
- source maps;
- optional Wasm components for selected modules.

The language should integrate with Vite-like workflows rather than require its own browser ecosystem from day one.

## 12. Bundler/tool integration

PSC output should be ordinary modern modules usable by existing tools.

PSC should not require a custom bundler to be usable.

Integration adapters should support:
- Vite;
- esbuild-compatible ecosystems;
- Rollup;
- webpack where needed;
- framework CLIs.

The compiler must define which post-processing transformations are inside or outside a claimed compiler-preservation profile.

## 13. React and framework integration

React should be an important library target, not a semantic dependency.

A React adapter can provide:
- Component/Element types;
- hooks/effect adapters;
- event types;
- prop codecs;
- .psx lowering target.

Other adapters can target:
- Preact;
- DOM;
- server-rendered HTML;
- custom UI runtimes.

## 14. Ecosystem adoption strategy

A realistic adoption path:

~~~text
1. npm consumer of PSC-generated library
2. PSC module inside existing TS app
3. PSC business/domain layer
4. PSC server/browser application
5. selected contracts/proofs
6. optional Wasm target for suitable modules
~~~

Developers do not need to rewrite everything to benefit.

## 15. JavaScript escape hatch policy

PSC3 needs interop, not an invisible unsound escape.

Foreign JS calls must have declared:
- types;
- effects;
- failure mapping;
- platform;
- trust status.

A deliberately untyped dynamic escape may exist only in an explicitly unverified/foreign profile and cannot silently flow into verified claims without validation/assumptions.

## 16. Performance

To compete with TypeScript:
- compiler/editor feedback must be fast;
- emitted JS should avoid unnecessary runtime abstraction;
- whole-program proof machinery must not be required for ordinary builds;
- verification caches should be incremental;
- proof-only content should erase;
- runtime representations should be optimized behind proved/validated semantic interfaces.

Performance claims must be measured on representative application corpora.

## 17. Definition of full-app readiness

PSC3 should not call itself full-app ready until the standard platform can build, test and package:
- a CLI;
- an HTTP service;
- a browser app;
- an npm library;
- a database/network application;
- an async/resource-heavy application;

with no essential JavaScript implementation file except explicit foreign bindings/adapters.
