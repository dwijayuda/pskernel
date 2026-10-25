# Checked local rename candidates

Qualification status: bounded R2b passes focused and whole-compiler integration
in 40219590598, genuine current-source Wasm G1 in 40218467242, and the terminal
ordinary source gate recorded in the
[exact receipt](PSC1_SOURCE_BINDINGS_QUALIFICATION_2026-10-26.json).
This qualifies the explicit scope below; complete tracing and broader edits remain
unsupported. Preserved R1/R2a/R3 and frozen npm results retain their source identities.

## What the tool does

The production elaborator records actual local allocations and resolved term
bases when the host explicitly enables source tracing. Normal compilation keeps
tracing disabled. A declaration-local event number distinguishes allocations even
when a restored scope reuses a raw local ID. The host binds each event to the
actual member, declaration origin, module and immutable lexical snapshot.

This adds side tables to the existing compiler. It does not interpret source
names with a second resolver. Source metadata cannot select tools or checkers.

The first rename boundary covers one source-backed local binder in the body of
one stable definition. It edits that binder token and references whose actual
local targets identify that binder. Exact unaffected bytes, comments, strings,
whitespace and other modules are retained. A projected reference changes only
its local base; this is not a field-declaration rename. PsSyntaxName retains an
optional exact lexical sourceSpan separately from its legacy term/group/diagnostic
span. Generated names keep their diagnostic anchor with no lexical edit span.
Grouping preserves lexical name provenance and the original adjacency semantics.

Both original and candidate closures pass the same production preparation,
strict IR validation and independent official Lean 4.35.0 admission. The host
checks the source/member/binder/reference correspondence, including unchanged
targets for unrelated references. This detects both an edited use captured by
another local and a new local name capturing an existing global use.

A native comparison then requires exactly one selected definition, the exact
public name, levels and type, and exact other Core declarations. Its value alone
may differ under the existing Core alpha-equality routine. It compares the actual
checked graphs; neither independent admission is performed on a normalized or
substituted comparison graph. Ordinary logical/body pairing remains required.
R3 conversion continues to require literal private admission and strict-IR bytes.

## API

Import the factories from host-tools/source-refactoring.mjs:

~~~js
const lexical = createLosslessSourceTool({ executable: lexer, sha256: lexerHash });
const ownership = createSourceOwnershipTool({
  lexicalTool: lexical, executable: helper, sha256: helperHash,
  checkerExecutable: checker, checkerSha256: checkerHash,
});
const bindings = createSourceBindingTool({ ownershipTool: ownership });
const snapshots = [lexical.capture({
  module: 'Example.Main', grammar: 'lean', bytes: sourceBytes,
})];
const index = bindings.analyze({
  snapshots, entry: 'Example.Main', assurance: 'checked',
});
const binder = index.modules[0].bindings[0].traces[0].binders.find(
  item => item.sourceBacked && item.region === 'body' && item.name[0]?.[1] === 'value',
);
const report = bindings.rename({ index, snapshots, binder, newName: 'nextValue' });
const candidateBytes = bindings.readCandidate(report, 'Example.Main');
~~~

Application selection should use exact module/member identity and byte location;
the example name predicate is only a convenient selection within an already
genuine trace. Duplicate or unsuitable selections must refuse.

Indices, binders and reports are immutable capabilities belonging to their factory
instance. A JSON copy, object spread, foreign-factory object or binder from a
different index grants no edit authority. Candidate byte readers return copies.
Use assertCurrent(index, snapshots) or assertCandidateCurrent(report, snapshots)
before consuming a candidate. candidateSnapshots and candidateIndex return the
already checked candidate capabilities. Source changes require a new index.

A bindings array has one entry per actual declaration origin. Its coverage is
recorded-term-bases or not-recorded; the latter is explicit for batches without
source traces. Traces identify the source-elaboration-before-lifts phase.
A trace's complete flag describes that recorded execution; it is not a promise
that every syntactic form, generated declaration or IDE query is covered.

Native records retain allocation types with their local context. The host wire
does not present those open expressions as independently closed, checked types.
Metadata is not a proof certificate.

## Developer command

Use the same trusted psc1-source-tools/1 manifest as checked conversion, with
absolute executable paths and SHA-256 identities for lexical, ownership and
independent checker tools. The manifest is host configuration, never source-package
metadata. Install/build tools separately; source input cannot request installation.

~~~sh
node /absolute/psc1/scripts/refactor-source.mjs \
  --manifest /absolute/tools.json \
  --operation bindings --entry Example.Main --grammar lean \
  --source Example.Main=/absolute/Main.lean

node /absolute/psc1/scripts/refactor-source.mjs \
  --manifest /absolute/tools.json \
  --operation rename --entry Example.Main --grammar lean \
  --source Example.Main=/absolute/Main.lean \
  --module Example.Main --offset 42 --new-name nextValue
~~~

The offset is the UTF-8 byte start of the selected source binder, not a character
or UTF-16 column. The command selects exactly one genuine source-backed binder.
Imports require the complete dependency-ordered source list. Use grammar ps for
actual ProofScript input and assurance ordinary-checked when needed by an
otherwise supported ordinary closure.

Bindings mode returns a read-only JSON view. Rename mode returns candidate JSON
with a checked report and module texts. Neither command writes project sources.
Refusal writes diagnostics to stderr and no candidate to stdout. Existing
conversion flags and behavior remain supported.

## Deliberate refusals

Public header binders, declaration/field renames, partial definitions, normalized
workers/wrappers, generated-only/unlocated binders and ambiguous source aliases
are outside this first edit boundary. Mutables and their synthesized SSA/join
aliases do not acquire a fabricated source-family identity from raw local IDs.
Structural self-call argument paths that bypass ordinary term tracing mark their
trace incomplete. Data and normalization batches without trace attribution remain
explicitly not-recorded.

Invalid or stale snapshots, forged handles, incomplete traces, unexpected event
coverage, invalid spans, changed target identities, changed public API, unrelated
Core changes, checker rejection, changed tools and exhausted limits all refuse.
A valid candidate is not a formal whole-source preservation theorem and grants
no publication or host/FFI authority. Effectful/partial/foreign simplification
still requires the separate R4 behavioral obligations.

## Resource and evidence boundary

Linux tools retain the existing 240-second request deadline, 4 GiB address-space
and 8 MiB stack limits; the independent checker retains its 120-second deadline.
Source inputs are at most 1 MiB each, 256 modules and 32 MiB request/response.
Native transport uses the closed psc1-source-bindings-compact/2 encoding.
Binder rows retain event index, raw local ID, tagged name, parent and optional
source span; reference rows retain event index, tagged name, diagnostic anchor,
base segment count, actual target and optional lexical source span. Six-cell spans
retain both endpoints' byte/line/column coordinates. The host reconstructs readable
immutable objects and validates every event/name/target/span. Compact transport
does not omit records or raise the response cap. Shared token range handling uses
[start, stop), excluding zero-width EOF from an actual source-name range.

The closed trace wire permits at most 262,144 events per declaration and R1 limits
edits to 4,096. Event and name/span validation happens before a candidate is exposed.

Focused tests exercise real elaboration and official admission, shadowing, reused
IDs, lambdas, branches, Unicode, root/namespace/imported names and capture refusal.
Transport/tool/checker/CLI tests and full before/after backend/compiler integration
have separate actual run evidence. CI readiness must be reported from terminal
jobs, not inferred from implementation or a configured workflow.

## Actual finite integration evidence

Focused 40219590598/job 121248430355 passes 23 checked renames and 62 refusals.
The full integration job 121249317325 executes28 artifacts:before/after under both
grammars across JS, TS, Rust,Wasm-core,Wasm-component,Python and PHP. The fixture uses
a projected local reference. It also checks the complete122-module/4735-member
compiler under each grammar, including exact traced/untraced admission and strict
IR identity. Each actual index records 2928 traces, 2163 complete recorded traces,
42269 binder events and 108032 references; incomplete/unrecorded cases remain
explicitly labeled. The complete count is not a whole-language coverage claim.

A body binder in Ps.Elab.SourceTrace.psElabSourceTraceWithLocals is renamed from
pruned to retainedTrace as a checked candidate for each whole compiler closure.
Both actual endpoints pass official independent checking, strict IR and the exact
native/host relation above. No compiler source file is replaced. Per-endpoint tool,
source,admission and IR identities are in the SHA-pinned integration artifact.
The receipt distinguishes this new source from frozen four-engine npm generations.
