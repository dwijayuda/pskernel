# Dual-source ProofScript / Lean-subset interoperability plan

Status: **DS1 complete; DS2 bounded Lean-subset parser next; subordinate to the canonical checked-core architecture**

## Objective

`psc` should accept both ProofScript and a deliberately bounded Lean 4
surface while preserving one semantic pipeline:

```text
foo.ps   --\
          +-> canonical surface -> Meta/Elab -> pskernel -> checked core
foo.lean --/                                      |
                                                   +-> erasure -> IR -> .ts -> .js
```

The same canonical surface can also be printed as either supported source form:

```text
.ps   -> canonical surface -> .lean
.lean -> canonical surface -> .ps
```

This does not mean full Lean source compatibility. The supported `.lean`
language is the intersection of Lean syntax/semantics that psc explicitly
owns.

## Architecture rule

A separate Lean-to-TypeScript compiler would duplicate name resolution,
elaboration, theorem checking, erasure, and backend semantics. That would
drift. Source-specific behavior must end at the frontend.

The repository already has the downstream foundation:

- pskernel as proof/type authority;
- verified checked-core -> TypeScript/JavaScript compilation;
- canonical ProofScript -> Lean lowering;
- language-service and VS Code layers outside the TCB;
- module/project foundations.

The missing work is a Lean-subset frontend, a ProofScript printer, source-kind
dispatch, mixed-source project resolution, and dual-source tooling.

## Frontend interface

Conceptually:

```ts
type SourceKind = 'proofscript' | 'lean-subset'

interface SourceFrontend {
  kind: SourceKind
  parse(source: string): CanonicalSurfaceModule
  print(module: CanonicalSurfaceModule): string
}
```

The frontend owns source recognition, parsing, spans, canonical lowering,
printing, and frontend diagnostics.

It does not own proof acceptance, type theory, pskernel admission, erasure,
runtime semantics, or TypeScript/JavaScript emission.

## CLI contract

Target UX:

```text
psc check main.ps
psc check Main.lean

psc build main.ps
psc build Main.lean

psc run main.ps
psc run Main.lean

psc translate main.ps --to lean
psc translate Main.lean --to ps

psc emit-lean main.ps
# retained as a convenience/backward-compatible alias
```

The entry extension selects only the frontend. It never selects a weaker
checker or a different compiler backend.

## Supported Lean subset policy

Start from constructs already admitted by the ProofScript checked path and map
their canonical Lean forms back into the shared surface representation.

Initial candidates, only where downstream semantics already exist:

- `def`, `theorem`, and supported function declarations;
- explicit/implicit/instance binders;
- supported structures/classes/instances;
- supported inductives and constructors;
- lambdas, lets, applications, literals, if, and match;
- currently implemented proof tactics;
- supported primitive operations and type applications.

Initially reject:

- user-defined `syntax`, `macro`, `elab`, or custom parser extensions;
- arbitrary notation not explicitly registered by psc;
- Lean metaprogramming;
- unsupported commands or attributes;
- unsupported tactics;
- namespace/open/section behavior until name resolution explicitly owns it;
- constructs depending on unsupported termination, effects, or compiler
  extensions.

Every rejection should identify the unsupported Lean-subset feature.

## Round-trip contract

Source conversion is canonicalization, not source preservation.

Allowed initially:

- formatting changes;
- normalized parentheses;
- normalized binder spelling;
- normalized supported syntactic sugar.

Not promised initially:

- comment preservation;
- exact whitespace;
- macro spelling;
- arbitrary notation spelling;
- byte-identical round trips.

Required semantic gates:

1. `.ps -> canonical Lean -> parse Lean subset -> pskernel` preserves the
   admitted declaration meaning.
2. `.lean -> canonical ProofScript -> parse ProofScript -> pskernel`
   preserves the admitted declaration meaning.
3. Executable declarations lower to equivalent verified compiler IR.
4. Unsupported features fail closed before checked core.

## Mixed-source module interop

The project graph is source-kind independent.

Example:

```text
app.ps
  imports Data

Data.lean
  imports Logic

Logic.ps
```

All modules elaborate into the same pskernel environment.

Resolution rules:

- one logical module name maps to exactly one source file;
- if both `Data.ps` and `Data.lean` claim the same module and configuration
  does not disambiguate, fail with an ambiguity diagnostic;
- cache keys include source content, source kind, ProofScript version, Lean
  semantic version, and imported module integrity.

A `.lean` module does not gain access to full Lean features merely because it
is imported from `.ps`.

## LSP and VS Code

The language-service snapshot gains a source kind and uses the same frontend
registry as `psc`.

After frontend lowering, the existing shared semantic services continue to
provide kernel status, diagnostics, proof goals, completion, navigation, hover,
and symbols.

`.ps` remains the native `proofscript` language. For `.lean`, the
extension should not unconditionally steal the association from the official
Lean extension. Prefer either an explicit `proofscript-lean` mode or a
workspace-aware opt-in that attaches ProofScript providers only inside a
ProofScript project.

## Implementation phases

### DS1 — frontend abstraction

Landed checkpoints:

- source-kind detection and deterministic frontend registration;
- the `proofscript` frontend owns both parsing and canonical ProofScript
  printing through `SourceFrontend.parse/print`;
- canonical ProofScript printing covers the complete current v0.6.1 AST,
  normalizes owned D/E syntax, and is parse/print idempotent;
- `.lean` is recognized as `lean-subset` but remains unavailable until DS2
  registers a bounded Lean parser.

Canonical Lean lowering intentionally remains a separate target printer for
now. It must not be registered as a Lean source frontend until a DS2 parser can
read the emitted subset back. This prevents output capability from being
misreported as input compatibility.

Final DS1 checkpoint:

- translation targets are registered independently as user-facing `ps` and
  `lean` printers;
- `psc emit-lean` now demonstrates source frontend selection and target
  printer selection as two independent decisions;
- canonical Lean output support still does not register a Lean source
  frontend.

DS1 is complete with no semantic acceptance changes. DS2 must now add a
bounded fail-closed Lean parser before any command accepts `.lean` input.

### DS2 — Lean-subset parser

- declarations/binders/types;
- ordinary terms;
- inductives/structures/classes/instances;
- theorem tactic subset;
- precise unsupported-feature diagnostics.

### DS3 — CLI convergence

- `check/build/run` accept both source kinds;
- `translate --to ps|lean`;
- `emit-lean` remains compatible;
- manifests record input source kind and canonical-source hashes.

### DS4 — semantic round trips

- PS -> Lean -> checked-core equivalence corpus;
- Lean -> PS -> checked-core equivalence corpus;
- verified-IR equivalence corpus;
- differential checks against pinned Lean 4.34 where practical.

### DS5 — mixed modules

- source-kind-independent imports;
- deterministic mixed-source build graph;
- module artifact/cache integration;
- cross-language definition/reference resolution.

### DS6 — editor support

- source-kind-aware document snapshots;
- both frontends in the language service;
- VS Code opt-in Lean-subset mode;
- cross-language navigation;
- source conversion code actions after CLI conversion stabilizes.

## Non-goals

- compiling arbitrary Lean projects to JavaScript;
- implementing every Lean macro/elaborator in TypeScript;
- replacing the official Lean language server for full Lean;
- claiming `.lean` compatibility outside the documented psc subset;
- making translated source textually identical to its input.

## Acceptance statement

The intended claim is:

> ProofScript and the documented psc Lean subset are two source syntaxes for
> the same pskernel-checked language subset, and either may compile to the same
> TypeScript/JavaScript backend or translate canonically into the other.

That claim is realistic and testable. "psc supports all Lean source" is not.
