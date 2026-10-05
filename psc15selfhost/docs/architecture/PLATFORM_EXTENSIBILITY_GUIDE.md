# ProofScript platform and extensibility guide

**Status:** forward post-bootstrap platform guide. It preserves the small semantic/core/kernel design while allowing libraries, tactics, FFI, plugins, async/resources, and ecosystem tooling to grow rapidly above it.

## 1. Extension decision rule

For every proposed capability, ask in this order:

```text
Can an ordinary library express it?
  yes -> library
  no
  |
  v
Is it target-specific or foreign?
  yes -> InterfaceIR / FFI / capability
  no
  |
  v
Is it only syntax/ergonomics over existing semantics?
  yes -> frontend desugaring
  no
  |
  v
Can a controlled plugin express it without new semantic authority?
  yes -> versioned plugin API
  no
  |
  v
Does it require genuinely new Core semantic power?
  yes -> explicit Core proposal
  no -> redesign the feature
  |
  v
Does the Core change require a new kernel rule?
  yes -> explicit kernel proposal + conformance/proof plan
```

Kernel change is the last option.

## 2. Growth model

Target growth rates:

```text
source language       changes slowly
Core semantics        changes very slowly
pskernel              changes extremely slowly

stdlib                 grows rapidly
proof/math libraries   grows rapidly
tactics                grows rapidly
FFI ecosystem          grows rapidly
plugins/tooling        grows rapidly
```

ProofScript should gain application reach and proof reach by growing above the semantic core, not by importing all TypeScript/Lean features into PSC2.

## 3. Meta and tactic API

Tactics are untrusted proof-producing programs.

```text
goal
 -> tactic / automation / AI
 -> candidate proof term
 -> pskernel
```

The Meta API may expose controlled operations around:

```text
Expr
Level
Name
Environment
LocalContext
Goal/MVar

inferType
whnf
isDefEq
mkApp
mkLambda
mkForall
instantiate
abstract
freshMVar
assignMVar
synthInstance
checkTerm
```

The Meta API does not create an alternate admission path.

A buggy tactic can fail or generate a rejected proof; it cannot compromise theorem soundness.

## 4. Plugin classes

Keep plugin categories distinct.

### Syntax/desugaring

New surface syntax lowers to existing PSC syntax/Core semantics.

### Derive/code generation

Generates ordinary declarations, implementations, and proofs.

### Meta/tactic

Constructs candidate terms through the controlled Meta API.

### Backend

Consumes validated VerifiedIR and introduces target-specific IR below the portable boundary.

### Tooling

Formatter/docs/LSP/editor/build integrations with no semantic authority.

Every plugin declares API versions, determinism, compatibility, capabilities, and target restrictions.

## 5. Capability worlds

Foreign/host operations require explicit capabilities rather than ambient authority.

Examples:

```text
FileSystem
Network
Clock
Random
Process
Environment
Console
```

A package/plugin “world” is the set of imported capabilities and exported services.

This model should be compatible in spirit with Wasm Component/WIT worlds without making WIT the PSC type system.

## 6. InterfaceIR

`InterfaceIR` is the target-neutral foreign/API description layer.

```text
.d.ts --------\
WIT -----------+--> InterfaceIR --> PSC bindings / host shims
rustdoc -------+
future C IDL --/
```

InterfaceIR is not VerifiedIR.

Recommended forms:

- primitives;
- list/tuple;
- records;
- variants/enums;
- option/result;
- functions/constants;
- modules/interfaces;
- resources/handles;
- owned/borrowed resource policy;
- errors;
- sync/async/future/stream;
- capability requirements;
- target set;
- ABI/profile identity.

If machine-readable authoritative interface metadata exists, generated bindings should derive from it rather than human/AI guesswork.

## 7. Safe foreign boundaries

Do not import these host semantics into portable PSC merely for interoperability:

- unrestricted TypeScript `any`;
- JavaScript prototype semantics;
- JavaScript `this`;
- arbitrary structural assignability;
- declaration merging/module augmentation;
- implicit JS number coercions;
- arbitrary host object identity;
- Rust ownership/lifetime syntax;
- WIT/WASI physical layout;
- OS resource semantics.

Wrap difficult host behavior into explicit safe PSC APIs and contracts.

## 8. Task, Stream, and structured concurrency

Async is a library/platform semantic contract before it is syntax.

Candidate abstractions:

```text
Task A
Stream A
Scope
spawn
join
cancel
race
timeout
```

Required laws/behavior:

- child lifetime is structured;
- cancellation propagation is specified;
- error propagation is specified;
- scheduler details do not leak into portable semantics;
- supported backends agree on observable behavior within declared capabilities.

Backend mappings remain private:

```text
PSC Task/Stream
 -> JS Promise/AsyncIterable/scheduler adapter
 -> Rust Future/Stream/executor adapter
 -> Wasm Component/WASI async adapter
```

Only add `async`/`await` syntax after the semantic contract is stable.

## 9. Resource safety

Define deterministic cleanup as a library contract before RAII-like syntax.

Candidate API:

```text
Resource A
acquire
release
bracket
withResource
```

Required laws:

- release after successful acquire;
- release on normal completion;
- release on error;
- release on cancellation where cancellation exists;
- exactly-once release;
- deterministic nested-release order.

Future `using`/`defer` syntax must desugar to this semantic model.

## 10. Safe reflection

Prefer bounded compile-time semantic reflection:

```text
DeclarationInfo
StructureInfo
FieldInfo
ConstructorInfo
TypeInfo
```

Use it for:

- deriving;
- codecs;
- documentation;
- schema generation;
- FFI bindings.

Reflection cannot create unchecked admitted terms.

## 11. External solver and certificate boundary

Integrate SAT/SMT/CAS/external provers/AI as untrusted producers:

```text
PSC goal
 -> external system
 -> proof term or checkable certificate
 -> pskernel / small certificate checker
```

Prefer checkable certificates over adding external solvers to the kernel.

## 12. Semantic package metadata

Packages using extensibility should declare:

```text
language/profile
Core/kernel/CheckedCore/VerifiedIR contracts
InterfaceIR version
PluginAPI version
required capabilities
target availability
runtime ABI
exported interface identity
proof/evidence identity
```

This metadata is part of compatibility and build identity, not merely documentation.

## 13. Compiler service for tools

LSP/editor/web IDE/docs/AI use the same compiler service:

```text
parse
check
typeOf
hover
definition
references
rename
completionCandidates
goalState
safe reflection
```

Do not implement independent name resolution/type checking in each tool.

## 14. Extensibility security policy

Before enabling a plugin/capability:

1. classify plugin kind;
2. identify required semantic API;
3. declare capability imports;
4. define deterministic status;
5. define resource budgets;
6. define input/output contract versions;
7. decide sandbox/process boundary;
8. prove it cannot forge CheckedCore;
9. record compatibility in package metadata;
10. add conformance/adversarial tests.

## 15. Post-bootstrap sequencing

Recommended broad order:

```text
stable self-host + CheckedCore/VerifiedIR contracts
  ->
stdlib law/test/property infrastructure
  ->
Meta/tactic + safe reflection
  ->
controlled plugin API
  ->
InterfaceIR + generated FFI
  ->
Task/Stream + Resource semantics
  ->
large ecosystem expansion
```

Independent work may overlap, but none of these should be retroactively declared a prerequisite for the smallest compiler fixed point.
