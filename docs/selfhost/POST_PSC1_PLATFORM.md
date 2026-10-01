# ProofScript post-PSC1 platform architecture

Status: **planned, deliberately non-blocking for PSC1 self-host closure**

This document defines the platform work that follows the first stable PSC1
JavaScript self-host fixed point and `.ps` source transition. It does **not**
expand the REQUIRED PSC1 source language, does **not** add new SH7 completion
gates, and does **not** authorize weakening the current source-closure,
pskernel, CheckedCore, erasure or VerifiedIR invariants.

The long-term goal is to let ProofScript gain most useful capabilities normally
associated with large languages and ecosystems through libraries, controlled
extensions and foreign interfaces while keeping the semantic core and trusted
kernel small.

The architectural rule is:

> If a capability can be a library, make it a library. If it is target-specific,
> put it behind FFI. If it is only ergonomic syntax, desugar it. If it needs
> controlled compiler participation, use a versioned plugin API. Change Core or
> pskernel only when the capability genuinely cannot be represented above them.

## Concentric architecture

```text
┌────────────────────────────────────────────────────────┐
│                    ECOSYSTEM                           │
│ npm / React / web / databases / WASI / native APIs    │
└──────────────────────────┬─────────────────────────────┘
                           │
                    FFI / InterfaceIR
                           │
┌──────────────────────────▼─────────────────────────────┐
│                    LIBRARIES                           │
│ stdlib / Task / Stream / Resource / math / tactics     │
│ parsers / codecs / HTTP / test / property testing      │
└──────────────────────────┬─────────────────────────────┘
                           │
                     ordinary PSC
                           │
┌──────────────────────────▼─────────────────────────────┐
│              FRONTEND / EXTENSIBILITY                  │
│ parser / resolver / elaborator / Meta API              │
│ syntax sugar / deriving / tactic API / plugins         │
└──────────────────────────┬─────────────────────────────┘
                           │
                          Core
                           │
┌──────────────────────────▼─────────────────────────────┐
│                  TRUSTED SEMANTICS                     │
│ universes / Pi / lambda / inductives / Prop / Eq       │
│ reduction / recursors / declaration checking           │
│                         pskernel                       │
└──────────────────────────┬─────────────────────────────┘
                           │
                      CheckedCore
                           │
                         Erasure
                           │
                      VerifiedIR
                  ┌────────┼────────┐
                  ▼        ▼        ▼
                 TS       Rust     Wasm
```

The existing semantic pipeline remains authoritative:

```text
source -> Meta/Elab -> pskernel -> CheckedCore -> Erasure -> VerifiedIR
                                                     /       |       \
                                                    TS      Rust     Wasm
```

Nothing in this document creates a second semantic checker or an alternate
portable compiler IR.

## PSC1 freeze boundary

PSC1 remains the smallest practical language that can express the compiler and
preserve the required dependent semantics. The following platform work is
**post-PSC1 unless a current self-host blocker proves otherwise**:

- general Meta/tactic APIs;
- controlled compiler/plugin APIs;
- InterfaceIR and broad FFI generation;
- general async/task/stream abstractions;
- deterministic resource abstractions;
- large mathematical/tactic libraries;
- reflection/deriving infrastructure;
- package semantic manifests beyond what self-host closure already requires.

Do not promote any item above into PSC1 merely because TypeScript, Lean, Rust,
Go or another language has an analogous feature.

## 1. Versioned semantic contracts

The current separation between source syntax, CheckedCore, erasure and
VerifiedIR must become an explicit versioned compatibility surface.

The platform should independently version at least:

```text
Source Language
Core format
Kernel contract
CheckedCore format
VerifiedIR
InterfaceIR
Plugin API
FFI capability contract
Semantic package manifest
```

A language version bump must not be required for an unrelated plugin, package
metadata or foreign-interface revision.

`Core`, `CheckedCore` and `VerifiedIR` have different jobs:

- **Core** is the elaborated kernel-facing semantic term/declaration language;
- **CheckedCore** is Core admitted by pskernel and suitable for trusted erasure;
- **VerifiedIR** is the target-neutral executable contract after proof/type-only
  information has been removed.

Backend-specific representations remain below VerifiedIR. In particular,
VerifiedIR must not acquire JS `number`/`bigint` conventions, Rust ownership,
borrowing, lifetimes or containers, or Wasm value types/opcodes/GC/WASI layout.

### Compatibility requirements

- every compiled package records the semantic contract versions it was built
  against;
- fingerprints are computed over normalized CheckedCore and VerifiedIR;
- incompatible contract versions fail closed instead of silently coercing;
- source syntax may evolve without changing Core semantics when the change is
  pure desugaring.

## 2. Explicit effects and capabilities

Portable PSC computation must remain pure unless effects are visible through
an explicit semantic abstraction or capability.

Do not introduce an unrestricted host `IO` escape that makes arbitrary foreign
behavior look like ordinary pure PSC code. Prefer library-level capabilities
such as:

```text
FileSystem
Network
Clock
Random
Process
Environment
Console
```

and effectful result types/combinators such as:

```text
Result E A
Task A
Resource A
```

The exact final source API is not frozen here. The required invariant is that a
foreign or target-specific operation declares enough information for the
compiler/package system to reason about its effect boundary.

A foreign capability description should eventually cover at least:

```text
target set
purity/effect class
sync / async
blocking / nonblocking
deterministic / nondeterministic
error model
resource behavior
cancellation behavior
thread/executor requirements where relevant
encoding / ABI profile where relevant
```

The PSC1 freeze still requires a normative purity/effect classification and
sequencing contract for host/FFI capabilities. The larger capability library
is post-PSC1.

## 3. Meta API and tactic platform

Lean-level practical proof automation should grow above pskernel rather than by
adding tactics to the trusted kernel.

After PSC1 stabilizes, define a small, versioned Meta API around concepts such
as:

```text
Expr
Level
Name
Environment
LocalContext
Goal / MVarId
```

with controlled operations in the family of:

```text
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

The final API must expose only semantics already owned by the elaborator/kernel
boundary; it must not create a second admission path.

Tactics are then ordinary untrusted programs/libraries:

```text
goal
  -> tactic / automation / AI
  -> candidate proof term
  -> pskernel
```

A buggy `simp`, arithmetic tactic, solver integration or AI prover may fail to
produce a proof, but it must not compromise soundness because pskernel remains
the final admission authority.

Candidate libraries include:

```text
rewrite / simp
exact? / apply?
cases / induction
ring-like normalization
omega/linarith-like arithmetic
aesop-style search
external SAT/SMT certificate checkers
AI proof search
```

## 4. Controlled plugin API

Ordinary libraries should remain the default extension mechanism. When compiler
participation is genuinely necessary, use a narrow versioned plugin API instead
of exposing arbitrary compiler internals.

Planned plugin classes:

1. **syntax/desugaring plugins** — new surface forms lower into existing PSC
   syntax/Core semantics;
2. **derive/code-generation plugins** — generate ordinary PSC declarations,
   implementations and proofs;
3. **meta/tactic plugins** — construct candidate terms through the Meta API but
   cannot admit them;
4. **backend plugins** — consume VerifiedIR and introduce target-specific IR
   strictly below the portable boundary;
5. **tooling plugins** — formatter/docs/LSP/build/editor integrations with no
   semantic authority.

Plugin manifests should be versioned and capability-scoped. A semantic plugin
should declare permissions such as:

```text
kind
plugin API version
language/Core compatibility
meta access
filesystem access
network access
process access
deterministic = true/false
```

Deterministic semantic plugins should normally have filesystem/network/process
access disabled. Host/tooling plugins may request broader capabilities without
becoming part of the trusted semantic path.

## 5. InterfaceIR and generated FFI

Do not make TypeScript structural typing, JavaScript object semantics, Rust
ownership, or WIT/WASI representation part of PSC's portable type system just
to gain ecosystem interoperability.

Add a separate **InterfaceIR** whose only job is to describe foreign APIs.

```text
TypeScript .d.ts ----\
rustdoc JSON ---------+--> InterfaceIR --> generated PSC bindings / host shims
WIT -----------------/
future C/native IDL -/
```

InterfaceIR is distinct from VerifiedIR:

```text
InterfaceIR = foreign API description
VerifiedIR  = executable semantics of checked PSC code
```

InterfaceIR should be able to describe, as required by foreign ecosystems:

```text
modules
functions
constants
records/structures
variants/enums
resources/handles
parameters/returns
errors
async behavior
effect/capability requirements
ownership/resource policy
target set
version/ABI profile
```

Target-specific dialect information may exist inside InterfaceIR adapters, but
must not leak into portable PSC semantics. Difficult JavaScript features such
as structural records, overloads, optional properties, callable objects,
Promises, `unknown`/`any` or host object identity should be represented at an
explicit JS boundary and wrapped into safe PSC APIs when practical.

Bindings should be machine-derived from authoritative interface metadata when
possible. AI or humans may improve adapters, docs and effect annotations, but
must not invent a foreign signature when a machine-readable one exists.

## 6. Backend-neutral Task/Stream and Resource semantics

Async and deterministic cleanup are post-PSC1 platform abstractions. Define
semantics before adding convenience syntax such as `async`, `await`, `using`,
`defer` or RAII-like forms.

### Structured async

Investigate a small backend-neutral abstraction in the family of:

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

The exact names are not frozen. The semantic requirements are:

- structured lifetime of spawned work;
- defined cancellation propagation;
- defined error propagation;
- no backend-specific scheduler semantics in portable code;
- equivalent observable behavior across supported backends where the target
  provides the required capabilities.

Possible backend mappings remain private to each target:

```text
PSC Task/Stream
  -> TS/JS Promise, AsyncIterable and scheduler adapters
  -> Rust Future/Stream/executor adapters
  -> Wasm Component Model/WASI async facilities
```

### Deterministic resources

Define a library abstraction in the family of:

```text
Resource A
acquire
release
bracket
withResource
```

with normative laws/gates covering at least:

- release after successful acquire;
- release on normal completion;
- release on error;
- release on cancellation where cancellation exists;
- exactly-once release;
- deterministic nested-release ordering.

Only after the semantics are stable may source sugar such as `using` or
`defer` be considered. Such syntax must desugar to the existing Resource
semantics rather than create a second cleanup model.

## 7. Semantic package manifests and conformance/law infrastructure

ProofScript packages need machine-readable semantic information in addition to
ordinary npm/workspace metadata.

The package format should eventually record at least:

```text
language version
Core / kernel contract version
CheckedCore version
VerifiedIR version
InterfaceIR/plugin versions when used
supported targets
required capabilities/effects
exported declarations/theorems
proof artifacts or proof fingerprints
CheckedCore fingerprint
VerifiedIR fingerprint
```

The precise serialization format is deferred. `package.json` may remain the
npm/workspace manifest with a `proofscript` field, or a generated adjacent
semantic manifest may be used, provided there is one authoritative schema.

### Standard-library quality contract

Large ecosystem growth should happen through libraries, not by enlarging the
kernel. Organize the portable standard library in layers such as:

```text
foundation/
data/
collections/
text/
codec/
algebra/
effects/
async/
resource/
test/
proof/
```

Important libraries should carry explicit laws where practical, for example:

```text
List.ps
List.Laws.ps

Map.ps
Map.Laws.ps

JSON.ps
JSON.Laws.ps
```

A library feature may require a combination of:

```text
unit tests
property tests
proofs
fuzzing
benchmarks
TS/Rust/Wasm differential tests
```

Portable library completion means more than "all backends compile". Where
observable behavior is defined portably, the backends must agree on results,
error classification, scalar semantics, resource semantics and async semantics.

## Stable compiler-service API

LSPs, editors, web IDEs, documentation tools and AI agents must not become
second semantic implementations. Expose one compiler-service API over the
canonical frontend and checked pipeline.

Candidate service operations include:

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
checkedCore
verifiedIr
```

The exact API is post-PSC1. The invariant is that all tools obtain semantic
truth from the compiler rather than reproducing name resolution, elaboration or
type checking independently.

## Safe compile-time reflection

A bounded reflection API may later expose semantic information such as:

```text
DeclarationInfo
StructureInfo
FieldInfo
ConstructorInfo
TypeInfo
```

for deriving, codecs, documentation, schema generation and FFI. Prefer
compile-time semantic reflection over unrestricted dynamic runtime reflection.
Reflection must not provide an unchecked term-admission path.

## External solver/certificate boundary

SAT/SMT systems, computer algebra, external provers and AI are untrusted tools.
The preferred integration is:

```text
PSC goal
  -> external solver / AI
  -> proof term or checkable certificate
  -> pskernel / small certificate checker
```

Do not add a solver to the trusted kernel when an independently checkable
certificate can provide the same assurance.

## Extension decision ladder

Every proposal for a new language/platform capability must answer these
questions in order:

```text
Can an ordinary library express it?
  yes -> library
  no
  |
  v
Is it target-specific or foreign?
  yes -> FFI / InterfaceIR
  no
  |
  v
Is it only surface ergonomics over existing semantics?
  yes -> desugaring/frontend sugar
  no
  |
  v
Can a controlled plugin express it without new semantic authority?
  yes -> plugin
  no
  |
  v
Does it require genuinely new Core semantic power?
  yes -> Core proposal
  no -> redesign the proposal
  |
  v
Does that Core change genuinely require new kernel rules?
  yes -> explicit pskernel proposal and conformance plan
```

A pskernel change is the last option, not the default response to a missing
convenience.

## Things deliberately not imported from TypeScript/JavaScript

Access to npm does not require PSC to adopt JavaScript's semantic model. Do not
add the following merely for ecosystem parity:

```text
unrestricted any
JavaScript prototype semantics
JavaScript `this`
arbitrary structural assignability
declaration merging
module augmentation
host-number coercion semantics
dynamic object identity as portable semantics
```

Represent host-specific behavior through InterfaceIR/FFI and safe wrappers.

## Things deliberately not imported wholesale from Lean

Lean remains a semantic/reference implementation source, not a requirement to
clone every extension surface. Do not add these merely for feature parity:

```text
arbitrary parser-category extension
unrestricted macros/quotations
custom elaborators with unchecked authority
broad mutable environment-extension APIs
unrestricted unsafe escape hatches
```

ProofScript may later expose narrower syntax, derive and Meta/plugin APIs when
real workloads require them. Generated terms remain subject to pskernel.

## Possible future Core generalization

PSC1 intentionally implements only the dependent machinery required by the
frozen compiler/language subset. A future large proof/math ecosystem may reveal
real requirements for broader semantic facilities. Candidates to investigate,
not commitments, include:

```text
more general universe polymorphism
general dependent inductive families/dependent elimination
mutual inductives
well-founded recursion
broader instance synthesis
opaque/reduction-control facilities
quotient semantics
```

Promote one only after a real library/formalization demonstrates that the need
cannot be met reasonably by existing Core semantics, ordinary libraries or
Meta-level tooling.

## Platform sequencing after self-host closure

The preferred post-PSC1 order is:

```text
PSC1 JavaScript fixed point + `.ps` source transition
  |
  v
P1  versioned Core / CheckedCore / VerifiedIR contracts
  |
  v
P2  standard-library law/test/property infrastructure
  |
  v
P3  Meta API + tactic API + safe reflection
  |
  v
P4  controlled plugin API
  |
  v
P5  InterfaceIR + generated .d.ts / WIT / Rust FFI
  |
  v
P6  Task/Stream + Resource semantics and backend conformance
  |
  v
P7  large math/tactic/FFI/ecosystem expansion
```

Some independent work may overlap after PSC1 is stable, but none of P1-P7 is a
retroactive PSC1 completion gate.

## Long-term success criterion

The desired growth pattern is:

```text
PSC source language:          changes slowly
Core semantics:               changes very slowly
pskernel:                     changes extremely slowly

stdlib:                       grows rapidly
math/proof libraries:         grows rapidly
tactic libraries:             grows rapidly
FFI ecosystem:                grows rapidly
plugins/tooling:              grows rapidly
AI-assisted ecosystem work:   grows rapidly
```

ProofScript should approach the practical application reach of TypeScript and
the proof/library reach of Lean by growing **above** the small semantic core,
not by merging both languages' surface features into PSC1.
