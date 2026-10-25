# Checked source conversion candidates (R3)

This developer tool converts the supported Lean/ProofScript grammars using the
existing parser and printers. It returns candidate source and a declaration
origin map for review. It never rewrites a project file.

## Required correspondence

The caller supplies an actual R2a ownership index and its exact lexical snapshots.
The converter refuses forged, cross-tool or stale capabilities. It converts the
complete dependency closure and independently admits and strictly validates the
candidate through the existing production pipeline.

Before returning, it requires literal equality of the privately retained canonical
admission strings and original strict-IR bytes, unchanged ordinary partial names,
and identical ordered source/declaration/member ownership. Public names, tagged
Core identities, generated roles and normalization-worker ownership must agree.
SHA-256 fields identify these bytes in the public receipt; they do not replace
the in-process byte comparison.

Ordinary checked preparation includes the exact executable-body/logical pairing.
A checked inhabitant without its matching ordinary implementation is insufficient.
A different well-typed and independently accepted body must still refuse.

This is a finite compiler-mediated relation, not a formal proof of source
preservation, behavioral equivalence or compiler correctness. Existing compiler,
independent checker, runtime, IR, ABI and publication assurance boundaries remain.

The translation helper supplies an unaccepted parsed declaration-layout preview,
using the same frontend. The host validates its closed schema, ordered declaration
names, scalar-boundary offsets and line/column positions before restoring comments.
Only the final candidate receives a lexical snapshot and full ownership/admission
pass. This avoids a redundant provisional capture and check; it never substitutes
layout metadata for final elaboration, strict IR or independent checking.

## Comments, layout and origin maps

Raw line and nested-block comments retain their bytes and order. Canonical source
conversion changes whitespace, literal spelling, BOM/layout and exact source IDs.
It does not promise identical formatting or original comment positions.

The default preserve policy handles boundary comments and refuses comments inside
declaration bodies. Explicit owner-notes retains those comments as leading notes
of the owning source declaration. Header comments remain leading; boundary notes
follow their declaration ownership. Review comment movement in the candidate.
No policy silently discards a comment.

Every returned declaration map records before/after source IDs, source and name
spans, and exact member identities/roles. It is not a complete binder/reference
map. Alpha rename remains R2b work and is never granted by this API.

## Host API

Use createCheckedSourceConverter({ ownershipTool }) from
host-tools/source-refactoring.mjs with a genuine createSourceOwnershipTool result.

- convert({ index, snapshots, targetGrammar, commentPolicy }) produces an opaque,
  deeply frozen report. targetGrammar is lean or ps. Same-grammar canonicalization
  uses the same checks. commentPolicy is preserve or explicit owner-notes.
- readCandidate(report, module) returns copied bytes.
- candidateIndex(report) and candidateSnapshots(report) permit checked chaining.
- assertCurrent(report, freshlyCapturedSnapshots) refuses changed source identity.

The complete closure currently uses one grammar. Mixed-grammar conversion refuses
explicitly; existing mixed-source native compilation is not changed.

## Developer CLI

Build the pinned native tools on a qualified Linux development machine:

    lake build psc1_lossless_source psc1_source_ownership psc1_independent_checker

Provide a trusted host-owned tools manifest with schema psc1-source-tools/1 and
exact lexical, ownership and checker objects. Each has an absolute path and its
SHA-256. Pin binaries from your trusted build or verified artifact; input source
does not select tools or configuration.

    node scripts/refactor-source.mjs --manifest /absolute/tools.json \
      --entry Example.Main --grammar lean --to ps \
      --source Example.Library=/absolute/Library.lean \
      --source Example.Main=/absolute/Main.lean

Sources are supplied in dependency order. Add --assurance ordinary-checked for
existing explicit partial code, or --comments owner-notes for deliberate comment
relocation. The command writes one candidate JSON object to stdout after every
check succeeds. Failure emits an error to stderr, with no candidate stdout.
It works outside the repository cwd and never writes source paths.

This command is Linux developer tooling. It is not added to the slim npm root,
does not publish source or package artifacts, and has no editor transaction API.
The default npm kernel and frozen self-hosted executors remain unchanged.

## Validation and bounds

Focused tests cover malformed layout previews, same-grammar conversion, both directions, namespaces, shadowing, data declarations,
normalized workers, ordinary partial pairing, Unicode/string/comment boundaries,
stale/forged handles, malicious-but-well-typed candidates and outside-cwd CLI use.
Full qualification additionally converts a real CLI/JSON/file application and
the entire compiler closure in both directions.

Qualification is in progress. Passing source/ownership checks do not alone
qualify runtime application behavior, final distribution or all remaining work.

Compiler/helper requests remain 240 seconds, the independent checker 120 seconds,
with the same fuel and helper memory/stack envelopes. The aggregate test job grows
only to accommodate more independent suites. Exact-source native build caches
retain Lake dependency validation; documentation-only pushes avoid expensive runs.
