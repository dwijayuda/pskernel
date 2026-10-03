# AI Prompt — ProofScript r3 Specification Completion Pass

You are the lead programming-language designer and specification editor for ProofScript / PSC in `dwijayuda/pskernel`.

Work only on documentation/specification research. Do not modify compiler, kernel, runtime, backend, bootstrap, or toolchain code. Do not run implementation experiments unless explicitly authorized later.

## Baseline

- Accepted design: `ps-0.9-r3`
- Semantic pin: Lean 4.34.0, commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`
- r2 baseline SHA-256: `d29c0b2d5780e6cdb08a4c9ac00cc7442a64b1c8133b51c5f0c0e9a343b11b8d`
- Native `.lean` syntax is unchanged.
- `.ps` may differ only through explicitly specified surface ownership/lowering.
- Fail closed on unsupported, ambiguous, incompatible, incomplete, exhausted, or failed conditions.

## Mission

Complete r3 as an implementable language specification by resolving these ten items:

1. Make r3 a complete r2 delta with exact inheritance/override authority, or a standalone reference. Prefer the complete-delta model if it avoids accidental semantic transcription errors.
2. Resolve empty calls versus optional/default parameters. Avoid a TypeScript-looking `f()` whose meaning is silently “pass Unit” when the callee is actually default-callable.
3. Define exact r3 grammar and feature registry, including horizontal-whitespace/comment ownership, newline boundaries, tuple grouping, structural braces, category separators, and committed errors.
4. Preserve native Lean dot adjacency. Remove `users .map(...)` unless a distinct field-notation feature is explicitly specified.
5. Freeze `ps-standard`: exact syntax/tactic/extension policy, exact rejection of dynamic syntax mutation, and a versioned semantic-bundle import format for consuming Extensible libraries without importing parser/meta effects.
6. Narrow the stable contract core to what is actually defined. Specify pure requires/ensures completely; define frame/effect semantics; define a higher-order callable contract model; keep uncompleted state/loop/async clauses explicitly staged rather than pretending they are fully normative.
7. Freeze the application semantic model: App is cold; Fiber is started; define start/join/cancel, structured scope, cancellation shielding during cleanup, typed failure versus runtime fault, capabilities, and the relation to native Lean IO/Task.
8. Make InterfaceIR v1 a real versioned schema with a module-resolution identity that binds package version, package.json, export subpath, ordered conditions, TypeScript resolver/version, runtime entry, type entry, target, and declaration identities.
9. Restore all unchanged r2 primitive/runtime/module/compiler-assurance rules through exact inheritance. Do not drop Nat/Int semantics, source identity, module uniqueness, transactional admission, source maps, erasure, primitive matrices, artifact binding, resource limits, evidence manifests, etc.
10. Keep usability/formal/application studies as pre-stable/1.0 evidence gates. Do not claim those studies or proofs are complete.

## Required concrete decisions

### Empty call

Define `f()` as a complete empty source-level invocation, distinct from `f(())`.

- Insert native implicit and instance parameters as usual.
- Insert optional/default and automatic parameters as usual.
- If the next required explicit parameter is definitionally `Unit`, synthesize exactly one `()` for the empty-call sugar, then continue inserting trailing implicit/default/automatic parameters.
- If any required non-Unit explicit parameter remains unsatisfied, reject the empty call rather than eta-abstract it.
- `f(())` is an ordinary explicit Unit argument and may participate in native partial application.
- `function f()` lowers to a function with one explicit Unit binder.
- Thus `function f(x : Nat := 1)` may be invoked as `f()`, while `function f(x : Nat)` may not.
- Preserve native partial application for nonempty applications and for using the function value without parentheses.

### Call gap

For r3 parenthesized-call ownership, horizontal spaces/tabs and comments that contain no line terminator may occur between the completed callable head and `(`.

A physical line terminator breaks r3 parenthesized-call ownership. Multiline arguments are allowed after the opening parenthesis.

Therefore:

```
f (x)             -- r3 call
f/- comment -/(x) -- r3 call if comment has no newline
f
(x)               -- not one r3 parenthesized call
```

This avoids hidden do/tactic/local-declaration crossing.

### Field notation

Keep native Lean field-notation adjacency:

```
users.map(render)  -- allowed
users .map(render) -- not added by r3
```

### Structural braces

- structure/class fields: commas between fields, no trailing field comma;
- constructors/match alternatives: leading `|`;
- instance/local-where brace sequences: explicit native semicolon separators, optional trailing semicolon only where that native sequence admits it;
- braced conditional: exactly one term per branch;
- native `do` and tactic blocks retain their own category grammar;
- indentation inside an r3-owned outer brace sequence is formatting, not member delimitation.

## Contract core

Normative r3 contracts initially cover total pure functions:

- `requires P`
- `ensures result => Q`
- exact implementation identity
- exact specification dependency closure
- axiom policy
- assumption report

Define `FrameSpec` semantically even when surface syntax is staged:

- read capabilities/locations
- write/modify capabilities/locations
- foreign effects

For pure functions, frame is empty.

Define a higher-order `CallableSpec` model with ordinary predicates analogous to:

```
callRequires(f, args)
callEnsures(f, args, result)
```

Do not make these kernel primitives.

Stateful/loop/async contract surface syntax remains reserved until the program logic is specified.

## Application model

Freeze conceptually:

```
App (caps : CapabilitySet) (err : Type) (result : Type)
Fiber err result
Exit err result = success result | failure err | cancelled CancelReason
RuntimeFault -- outside ordinary recoverable Exit
Resource caps err a
Stream caps err a
```

- App is cold; constructing/reusing App does not start work.
- Starting occurs through run/fork.
- Fiber denotes started work.
- join observes terminal Exit.
- cancel requests cancellation; it is not itself a terminal state.
- lexical scopes own child fibers; detach is explicit.
- cleanup is shielded from ordinary cooperative cancellation once release begins.
- runtime faults are not catchable through ordinary typed-error handlers unless an explicit adapter converts them.
- `ps-standard` application APIs expose App; native IO/Task remain the low-level Lean substrate and are allowed directly only in explicitly nonportable/adapter contexts.

## InterfaceIR

Create a JSON Schema and normative prose. Bind resolution identity to:

- InterfaceIR schema version
- TypeScript version
- TypeScript moduleResolution mode
- custom conditions
- ordered package export conditions
- package name/version
- package.json hash
- export subpath
- selected runtime entry and format
- selected declaration entry
- declaration file hashes
- target/runtime profile

Classify every imported construct as native mapping, specialized mapping, runtime adapter, opaque handle, import-time normalization, or unsupported.

Never map unsupported TypeScript machinery to native `any`.

## ps-standard

Freeze a machine-readable registry identity.

Standard source/dependencies may not dynamically add parser categories, notation, macros, term/command/tactic elaborators, or low-level parser extensions.

Standard may consume an Extensible library through a semantic bundle containing checked declarations, dependency identities, axiom/assumption data, and optional runtime exports, but no syntax/meta registrations.

## Output

Update/create:

- `ProofScript_Language_Reference_v0.9.0_r3.md`
- `R3-AUTHORITY-AND-DELTA.md`
- `R3-R2-INHERITANCE-MATRIX.md`
- `R3-GRAMMAR-AND-FEATURE-REGISTRY.md`
- `FEATURE-REGISTRY-r3.json`
- `PS-STANDARD-REGISTRY-r3.json`
- `SEMANTIC-BUNDLE-v1.md`
- `SEMANTIC-BUNDLE-v1.schema.json`
- `INTERFACEIR-v1.md`
- `INTERFACEIR-v1.schema.json`
- existing topic documents, decision ledger, manifest, open questions and acceptance record.

Do not touch r2 historical content except to vendor an immutable baseline copy under the r3 research directory.

## Evidence discipline

Design acceptance is not implementation, proof, human study, backend preservation, or full-app evidence. Preserve those distinctions everywhere.
