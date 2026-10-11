# Native PSCV0 v7 development

Develop the portable compiler in `.lean` and run the current sources through the
official Lean native compiler. The native host checks compiler-produced declarations
with the official RC4 kernel before emitting TypeScript. It does not use Lean's
frontend as a fallback for unsupported PSCV0 syntax or semantics.

## Fast loop

From this directory on the Linux development runner:

```sh
lake build pscv0_native
.lake/build/bin/pscv0_native --check path/to/Application.ps
.lake/build/bin/pscv0_native --emit path/to/Application.ps path/to/Application.ts
```

`--check` accepts several independent input files in one process. It initializes
the checked prelude once and isolates each input from all earlier inputs, including
failed ones. It does not implement project imports yet: imports fail explicitly
with `PSCV0-NATIVE-MODULE-IMPORTS-PENDING`. This is the existing bounded v7 frontend
connected to the existing portable semantics, not complete v7 language coverage.

The emitted TypeScript uses the existing backend and pinned TypeScript 7.0.2
profile. The CLI emits TypeScript; use the pinned target compiler for JavaScript.
An input is an application fixture, never generated compiler source.

## Rich terms and shared elaboration

The v7 term tree retains named/positional call arguments, empty invocation,
type ascriptions and inference placeholders. Lambda binders can obtain their
types from the expected Pi telescope. Positional and named calls share one
ordered application engine with implicit insertion and pending instance solving.
Scopes restore lexical visibility while preserving constraints and fresh IDs.

Ordered programs retain `namespace`, `section`, `end`, `open`, typed `variable`,
`include` and `omit` commands. Namespace ancestors and opened namespaces are
resolved before term elaboration; local binders shadow globals, `_root_` bypasses
that lookup, and ambiguous opened names fail explicitly. Scope exit restores
opens/variables/inclusions while retaining checked declarations.

Section parameters are selected from header/body dependencies for definitions,
and from the header plus explicit inclusions for theorems. Dependencies precede
their users in the original variable order; eligible instance variables are
retained. A theorem proof cannot silently enlarge its public signature.
Annotations and defaults are resolved at their declaration site.

Explicit defaults use the checked `optParam` definition from Lean RC4's
`Init.Prelude`. The default is part of the Core parameter type, closed over prior
binders; ordinary instantiation substitutes actual preceding arguments. Named,
positional and empty calls use the same telescope engine. Expected function types
preserve partial applications. Empty calls complete declared defaults and, when
needed, exactly one required `Unit` argument. A final `function f()` group lowers
to that required Unit binder.

Basic owns inference/checking and global/projection lookup; Binders owns ordered
telescopes and lexical scopes; Application owns argument consumption; Term owns
dispatch and existing control/patterns. Scope owns capture-aware syntax traversal
and section dependencies; Command owns ordered scope transitions and declaration
admission. All are portable source modules, without host elaborator imports.

Selected limitations remain explicit: no rebinding an active section variable,
no universe commands, scoped notation/open modifiers, expected-type overload disambiguation,
general CoeFun, autoParam or full native binder grammar. Named recursive self-calls and
recursive calls under a shadowed captured section parameter remain unsupported.
The declaration-only source translation API refuses scope commands and empty
calls rather than dropping scope or inventing typed completion. Full project
imports/visibility and full v7 conformance remain later milestones.

Quantified types accept `forall`/`∀`, native lambdas accept `fun`/`λ`
and `=>`/`↦`, and strict implicit binders accept `{{...}}`/`⦃...⦄`.
A callback-based binder reader is shared by declaration parameters, variables,
lambdas, quantifiers and explicit dependent arrows. It uses the v7 annotation
reader throughout, while retaining declaration-only comma groups and defaults.
Anonymous `[ClassTerm]` binders receive inaccessible source-local names and
participate in the existing local instance search and section generalization.
Printers retain their anonymous form.

Native explicit, implicit and strict implicit groups retain all names and one
annotation in the AST, including bare `forall A B : Type, ...`. Name resolution
visits the annotation before adding any of those names. Elaboration checks a
concrete annotation in that same outer context, then introduces all group names
with the resulting Core type. Inferred `_` domains consume expected types per
name, including heterogeneous inferred lambda parameters.

Section dependency selection retains only used names from a group, with their
shared annotation and dependencies. Recursion preserves group scope and splits
parameters only after their annotations have been renamed to internal identities.
Native term printers keep groups intact; the declaration-only PSC printer refuses
a multi-name explicit group requiring scope-preserving lowering rather than
silently expanding it. Declaration explicit parameters still require comma entries.

Structures and ordinary inductives now use the v7 data reader. Headers and
constructors share the declaration telescope reader, including interleaved
explicit/nonexplicit groups, grouped native parameters and explicit defaults.
Structure fields retain newline separation and native named binder groups;
all field and constructor annotations use the rich term reader. The existing
scope, telescope, record/projection and recursor machinery performs elaboration,
without a second data-specific elaborator.

Lambda result annotations, pattern binders and automatic insertion of omitted
implicit lambda binders remain pending. Data support remains limited to simple
nonindexed types in `Type`; constructor result annotations, deriving, structure
field methods/defaults and inheritance remain pending.

## Boundaries

- Implementation authority is shared `.lean` source during language growth.
- `packages/compiler/src/Ps/Compiler/Pscv0.lean` owns the portable v7 frontend entry.
- `host/src/Ps/Host/NativeV7.lean` owns native IO/timing and official kernel checks.
- `packages/pskernel-core` is excluded from source resolution, CI checkout,
  targets and tests. `Ps.Core` remains the compiler's expression data model.
- The separate RC4 toolchain does not change the parent 4.34 bootstrap pin or
  published provider identities. The historical provider's canonical decoder and
  prelude builder are reused as implementation code; its 4.34 metadata is not
  used as this host's identity.
- Canonical bridge normalization is preserved, including nested recursion.
  The same immutable prepared value survives checking and emission.
- No compiler `.ps` generation, generated frontend rebuild, full fixed point,
  independent kernel test suite, or Windows tests belong to this fast loop.

## Small checks and evidence

```sh
node ../scripts/pscv0-native-profile.mjs
lake build pscv0_native pscv0_native_checks
.lake/build/bin/pscv0_native_checks
```

The source inventory walks imports rather than a hand-maintained module list.
It rejects host dependencies and partial/unsafe definitions in the selected
portable roots. This is an initial import/source guard, not a complete authoring
profile verifier or a final runtime-library manifest.

The executable retains 28 parser cases (the named-call case now accepts its
newly implemented syntax) and a compact semantic batch. One composite application
covers expected lambdas, captures/shadowing, named dependent calls, inferred
arguments, ascriptions, namespace resolution, section generalization, theorem
inclusions, dependent defaults, partial application and Unit completion. Focused
refusals protect scope restoration, ambiguity, theorem signatures, default type
checking and required arguments. Quantified polymorphic values, Unicode binder aliases and anonymous local
instances extend those same programs. Grouped binders additionally exercise local
and global shadowing, dependent arrows, heterogeneous inference, selective section
capture, implicit kinds and changing-state structural recursion. Focused refusals
protect binder category ownership, unknown annotation names and duplicate section
variables. The same composite also covers grouped structure fields with an outer
annotation scope, quantified field types, interleaved inductive/constructor
parameters, constructor defaults, record projections and constructor matching.
Three data refusals protect adjacent explicit groups, nullary constructors and
field separators. Selected Except do and request isolation remain covered. The Linux workflow additionally checks CLI output and runs the emitted
application. Phase times and source hashes are artifacts.
A successful result claims official-kernel acceptance under the current PSC
prelude; it does not claim full v7 conformance or verified runtime behavior.

Ordinary edits use incremental Lake builds with toolchain/configuration-specific
cache keys. The old M1 generation and closure workflows are manual-only here.
Measured evidence and exact source commits are recorded in ../AI_WORK_STATE.md.

## Next semantic milestones

1. Rich source representation and shared parser category ownership.
2. Shared scopes, ordered applications, expected types and small proof goals.
3. Dependent data/patterns, classes and structural/WF recursion.
4. General typed do/control and exact runtime/library semantics.
5. Selected proof automation, contracts and verified-effect closure.
6. Complete the concrete Standard/P1 environment and capability ledger.
7. Only then translate the actual implementation closure to readable v7 `.ps`
   and perform final source/semantic and compiler-generation qualification.

Keep native-only kernel/host services outside that final portable closure.
Never imply that native Lean elaborator availability proves portable coverage.
