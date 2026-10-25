# Read-only source ownership (R2a)

R2a connects the qualified R1 source snapshots to actual elaboration output.
It identifies which source declaration owns each produced Core member. It does
not resolve all references, identify every local binder, rename code or publish
edits. The compiler frontend, elaborator and backend implementations are reused.

## Data flow

1. A caller pins the native lexical helper and captures exact source bytes with
   createLosslessSourceTool. Snapshots are opaque, immutable capabilities.
2. The caller pins the ownership helper and independent official Lean checker.
   createSourceOwnershipTool accepts only a genuine lexical tool from this module.
3. analyze receives a dependency-ordered exact closure of those snapshots. The
   existing compiler request decoder and exact-closure checker retain missing,
   reordered, duplicate, extra-module and unsupported-assurance refusals.
4. For each module, psCompilerPreparationStepParsedWithOrigins supplies both the
   next preparation state and actual declaration origins from one elaboration.
   The adapter checks complete member-name coverage against that output batch.
5. Existing checked or ordinary checked preparation and strict IR validation run.
   The host independently admits the exact logical graph before returning an index.

The index ties modules, grammar/profile and exact-byte snapshot IDs to source
ordinals, source/name spans, token-piece IDs, Core names, member roles and
normalization ownership. Tagged numeric and string Core-name components remain
distinct. IDs belong to exact snapshots, not all future versions of a declaration.
A member's source declaration owner is not necessarily that member's own editable
token: constructors, fields, recursors and synthesized workers need later tracing.

## API

The developer API lives in host-tools/source-refactoring.mjs:

- createLosslessSourceTool retains its existing capture, reconstruct and
  stageTextEdits API.
- createSourceOwnershipTool accepts lexicalTool, executable, sha256,
  checkerExecutable and checkerSha256, selected only by trusted host code.
- analyze({ snapshots, entry, assurance }) returns a deeply frozen ownership index
  after independent admission. assurance is checked by default; ordinary-checked
  uses the existing logical/body pairing for explicit ordinary partial code.
- assertCurrent(index, snapshots) refuses a forged, cross-tool, reordered or
  changed source identity. The caller must capture actual current bytes first;
  no filesystem lock or protection against later writers is claimed.

Each closure currently uses one grammar, lean or ps. Mixed-grammar ownership
requests refuse explicitly. Existing mixed-source native compilation is unchanged.
This is Linux developer tooling, outside the slim npm root and every portable
compiler import closure. There is no installed refactoring CLI in this slice.

## Bounds and assurance

The adapter uses the existing 240-second standard supervisor profile, 4 GiB virtual
address-space envelope and 8 MiB main-process stack with no Lean task workers.
Individual sources remain bounded to 1 MiB; a closure has at most 256 modules.
Request, index, admissions and original-IR files each have a 32 MiB finite envelope.
The separate official checker retains 120 seconds and all original proof budgets.
No compiler/checker fuel, stack, memory or self-hosting profile is increased.

Source input cannot choose tools, paths, checkers, policies or plugins. Exact-key
wire checks, source/token span correspondence, ordered ordinals, complete ownership
coverage, duplicate Core identities, role checks and normalization-worker linkage
refuse malformed metadata. Failed execution or admission returns no index.

Independent admission means that the exact logical graph is accepted by the
official Lean 4.35.0 kernel under the existing protocol. It is not a proof of
source-to-Core preservation, behavioral equivalence, safe rename or publication.
An ordinary partial body's logical pairing retains its existing assurance boundary.

## Qualification and next step

Qualification is in progress. Actual results, exact commits, source identities
and measurements must be recorded before claiming R2a complete. Tests compare
canonical admission and original strict-IR bytes with the unchanged production
capture path, exercise both source grammars and the complete compiler closure,
and require real official acceptance/refusal plus stale/forged/malformed negatives.

R2b must trace local binders and resolved references at actual elaboration sites.
Context-local numeric IDs and rendered names cannot substitute for source-bound
binding identities. Rename then needs capture avoidance, whole affected-closure
elaboration, independent before/after admission and explicit API/Core correspondence.
The [roadmap](PSC1_DEVELOPMENT_ROADMAP.md) owns the remaining dependency queue.
