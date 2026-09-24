# Dual-source ProofScript / Lean-subset interoperability plan

Status: **DS6 editor MVP complete through DS6.6 importer diagnostic refresh; later navigation/index optimizations remain; subordinate to the canonical checked-core architecture**

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

Status: **complete for the canonical Lean subset currently emitted by psc**

Landed checkpoints:

- a separate `lean-subset` parser reads canonical Lean `def`, `theorem`,
  `structure`, `class`, `instance`, and `inductive` declarations into
  the shared v0.6.1 AST;
- native explicit/implicit/strict-implicit/instance binders reuse the shared
  binder/type representation where the canonical ProofScript printer can also
  round-trip them;
- canonical named application, literals, unary/binary terms, `fun`, `let`,
  `if`, record values, `match`, synthetic holes, and the current theorem
  tactic subset are accepted;
- canonical Lean `where` declarations parse with token-bounded local bodies,
  including multiline match bodies, without creating a second expression AST;
- structure/class fields use an opt-in line-boundary type parse mode so
  newline-separated Lean fields do not get mistaken for whitespace
  application;
- unsupported commands/forms remain fail-closed, including namespaces/macros,
  custom elaboration, explicit inductive constructor result types, and binder
  shapes that cannot yet round-trip through canonical ProofScript;
- the integrated syntax gate covers:
  `ProofScript -> Lean -> Lean-subset AST -> Lean` idempotence and canonical
  ProofScript equivalence across the full currently emitted subset;
- the `lean-subset` SourceFrontend remains exported but deliberately
  unregistered by default. DS3 owns CLI acceptance.

DS2 exit condition is met for the current emitted surface. Future language
features must extend both source frontends or remain source-kind gated until
their Lean subset parser/printer coverage lands.

### DS3 — CLI convergence

Status: **complete**

Landed checkpoints:

- the default source frontend registry registers both `proofscript` and the
  bounded `lean-subset` frontend;
- `check/build/run` and `emit-lean` select only the parser from the entry
  extension; both source kinds continue into the same selected semantic
  pipeline;
- a verified filesystem regression runs canonical `.lean` through
  Lean-subset parse -> shared Meta/Elab -> pskernel -> checked core -> IR ->
  TypeScript -> JavaScript -> runtime;
- build stems strip either `.ps` or `.lean` cleanly;
- reports/manifests record `sourceKind`;
- `psc translate <file> --to ps|lean` performs source frontend -> canonical
  AST -> target printer conversion without implying proof/check authority;
- `emit-lean` remains a compatible convenience workflow;
- verified and legacy source parsing compute a SHA-256
  `canonicalSourceHash` from canonical ProofScript printing of the shared
  surface AST;
- semantically equivalent canonical `.ps` and supported `.lean` inputs are
  gated to produce the same canonical-source hash.

DS3 is closed. Source kind now affects parsing/printing and reporting, never the
checked-core semantics or backend selection.

### DS4 — semantic round trips

Status: **landed for the canonical supported subset**

The integration gate now exercises a representative corpus containing:

- a generic structure;
- a class and named global instance;
- an inductive;
- match;
- acyclic `where`;
- Nat arithmetic;
- a theorem using bounded `exact?`.

It checks all three routes:

```text
ProofScript source -> checked core / verified IR
ProofScript -> canonical Lean -> Lean-subset -> checked core / verified IR
Lean-subset -> canonical ProofScript -> checked core / verified IR
```

Required equalities are executable:

- identical `canonicalSourceHash`;
- identical checked-core admission fingerprints, i.e. the declarations and
  inductive/structure/class/instance metadata replayed through pskernel;
- identical verified compiler IR after erasure;
- identical generated TypeScript;
- identical generated JavaScript;
- identical generated `.d.ts`.

The same gate asserts an unsupported Lean command fails with the documented
Lean-subset diagnostic before checked-core admission.

Differential execution against an external Lean 4.34 executable remains useful
assurance where available, but it is separate from the internal dual-source
equivalence claim: both psc frontends already converge into the same
pskernel-checked semantics.

### DS5 — mixed modules

Status: **MVP landed with semantic metadata, cache/integrity, and configured source roots; persistent artifacts remain**

Landed DS5.1/DS5.2:

- both ProofScript and the bounded Lean subset parse canonical leading
  `import Foo.Bar` headers into the same module AST;
- both target printers preserve the logical import list;
- logical module names resolve below the entry source directory as
  `Foo/Bar.ps` or `Foo/Bar.lean`;
- if both source kinds exist for the same imported logical module, resolution
  fails with `PS_PROJECT_SOURCE_AMBIGUITY`;
- the existing project graph provides deterministic topological ordering plus
  missing-dependency/cycle rejection;
- verified project elaboration gives each module **only its transitive imported
  admissions**, preventing unrelated sibling modules from leaking into scope;
- all local admissions are replayed in deterministic topo order into one final
  pskernel-checked project, then the existing erasure -> verified IR ->
  TypeScript -> JavaScript backend compiles the bundle;
- filesystem regressions execute
  `main.ps -> Data.lean -> Core.ps` and the reverse Lean-entry/ProofScript-
  dependency direction;
- project reports expose module order/count and per-module source kind/path/
  canonical hash;
- imports are verified-only in this checkpoint; the transitional legacy lane
  fails closed instead of silently ignoring dependency semantics.
- dependency closure replay now also seeds imported structure/class/global-
  instance elaborator metadata from the already pskernel-validated checked
  module. Cross-module record construction/projection and instance synthesis
  therefore use the same metadata model as same-file elaboration.
- in-process verified builds now cache each module's local checked admissions
  using `BuildCache`. The SHA-256 cache/integrity key includes pinned kernel
  compatibility, logical module, canonical source hash, and direct dependency
  integrity keys. Project integrity covers the deterministic ordered module
  integrity list. Final project admission is still replayed through pskernel
  on cache hits.
- `psconfig.json` now accepts project-relative `sourceRoots`. Empty/unset
  preserves entry-directory lookup; configured roots are searched together,
  and exactly one `.ps` or `.lean` candidate must exist for each logical
  import. Verified reports expose the resolved absolute root list.

Current resolution rule:

```text
# default, when sourceRoots is empty/unset
entry directory/
  Foo/Bar.ps
  Foo/Bar.lean

# configured
psconfig.json
sourceRoots: ["src", "vendor"]
  -> search each configured project-relative root for Foo/Bar.ps|.lean
```

Exactly one candidate may exist for logical module `Foo.Bar` across all
searched roots and both source kinds. Multiple matches are an ambiguity error;
there is no first-root-wins precedence.

Remaining DS5 work:

- define a real persistent `@proofscript/module` payload path for
  ProofScript-produced checked admissions. Artifact v1 currently requires
  Lean4Export NDJSON, and no checked-core -> Lean4Export serializer exists;
- define package import resolution beyond the landed project-relative
  sourceRoots search;
- emit/cache canonical persistent per-module artifacts once that payload path
  exists, instead of only a bundled runtime output and entry-source Lean
  artifact;
- then expose cross-language definition/reference resolution to DS6 tooling.

### DS6 — editor support

Status: **DS6.6 importer diagnostic refresh landed; editor MVP complete**

Landed DS6.1:

- language-service snapshots carry `proofscript` or `lean-subset` source
  kind;
- analyzer parsing uses the same registered source frontends as `psc`;
- LSP `didOpen` maps `proofscript` / `proofscript-lean` documents to that
  source kind and preserves it across edits;
- document status reports source kind alongside parser/kernel status;
- VS Code contributes an explicit `proofscript-lean` manual language mode
  **without** associating `.lean` globally;
- `proofscript.leanSubset.enable` defaults false. When enabled in an active
  ProofScript workspace, providers may attach to `.lean` documents while the
  existing Lean language ownership remains unchanged;
- provider callbacks and document synchronization remain guarded by that
  opt-in/manual-source check.

Landed DS6.2:

- the language service accepts an injected project source host and composes
  transitive imports through the shared @proofscript/project graph;
- imported admissions are replayed through checked core/pskernel before entry
  analysis, with imported structure/class/global-instance metadata seeded into
  elaboration;
- same-document declarations elaborate sequentially in source order;
- open imported buffers override host-provided source text, and any document
  edit invalidates project-aware analysis caches;
- unresolved/ambiguous project context fails closed instead of labeling the
  entry verified without its imports.

Landed DS6.3:

- @proofscript/project/node now owns sourceRoots validation/expansion and exact
  logical .ps/.lean source resolution;
- psc and the LSP both consume that resolver instead of carrying separate
  ambiguity/missing-module rules;
- the LSP finds the nearest psconfig.json for file:// entry documents and
  falls back to the entry directory when no config exists;
- psc preserves its established PS_CLI_CONFIG_SOURCE_ROOTS diagnostic at the
  CLI boundary while sharing the underlying resolver semantics.

Landed DS6.4:

- completion includes declarations from the checked transitive project closure;
- definition lookup can jump from a ProofScript use to a supported Lean
  declaration and vice versa;
- references scan the checked project source set across both source kinds;
- the navigation layer remains an untrusted lexical editor aid and is not used
  by elaboration, proof checking, or kernel admission;
- open-buffer edits invalidate semantic/navigation caches together.

Landed DS6.5:

- language service conversion uses the same source frontend registry and
  translation target printer registry as psc translate;
- LSP protocol v2 exposes proofscript/translateDocument;
- VS Code offers refactor actions to convert ProofScript to the supported Lean
  subset or supported Lean to ProofScript;
- conversion opens a new untitled target-language document and never overwrites
  the original source in place;
- translation is explicitly source transformation, not proof verification.

Landed DS6.6:

- opening, changing, or closing a managed document invalidates all project-aware
  semantic/navigation caches;
- the LSP republishes diagnostics for every remaining managed open document, so
  importers immediately reflect edits to open dependencies;
- closing a dependency first clears its diagnostics, then importers are
  reanalyzed using the shared project host (including the on-disk fallback);
- refresh-all is deliberately conservative for correctness. Dependency-specific
  refresh is a later performance optimization.

DS6 editor MVP is complete for the documented subset. Future editor work may
improve lexical references with scope-aware indexing and narrow diagnostic
refresh sets, but neither optimization moves name-binding or proof authority out
of elaboration/pskernel.

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
