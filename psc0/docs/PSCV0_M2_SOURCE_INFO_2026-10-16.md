# M2: source-owned elaboration information

Status: implementation checkpoint, awaiting native compilation and cloud qualification. No C5 source reconstruction, compiler-source translation or self-hosting is enabled.

## Pinned Lean study

Lean 4.35.0 `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`:
- `src/Lean/Elab/InfoTree/Types.lean`: CommandContextInfo owns final metavariable assignments; TermInfo retains syntax, local context, expected type and expression.
- `src/Lean/Elab/InfoTree/Main.lean`: scoped context capture and information ownership.
- `tests/elab/info_trees.lean`, `binopInfoTree.lean`, `infoFromFailure.lean`: binder/occurrence positions, operator ownership and speculative outcomes.

Lean's complete interactive tree, widgets and diagnostic traces are unnecessary for this selected compiler. PSC0 retains a flat ordered immutable event stream for successful elaboration, plus a final assignment context per declaration/constructor. This is metadata, never proof authority.

## Ownership and invariants

- Binder elaboration records each source group once, after its shared annotation is elaborated and its ordered fresh local identities are introduced.
- Reference elaboration records the selected global/local identity and projection path at the source occurrence, before scopes are discarded.
- The existing application owner records omitted defaults and implicit/strict-implicit/instance arguments. Numeric/condition/coercion owners record their synthetic dictionary selections.
- Events carry persistent local contexts. A declaration/constructor receipt carries the final metavariable context; consumers instantiate against that context rather than guessing names or closing against a later telescope. Declaration universe generalization remains the existing `psElabGeneralizeExpr` operation.
- Immutable elaborator contexts provide rollback. Saved lexical continuations retain the source span but never snapshot the event stream or assignments. Leaving a scope preserves successful events while restoring lexical authority.
- Constructor receipts use independent meta contexts/owners. The preliminary structure-universe scan suppresses events; the actual checked constructor pass owns field events. Normalized workers/public wrappers retain distinct receipts and existing batch-parent provenance.
- Batch origins carry receipts into existing project origins. Core declarations, canonical admission encoding, hashes and typed IR contain no source-information fields. Metadata does not select an instance or affect a type check.

There is no new registry, solver, mutable global log or compatibility path. The event list adds constant-time recording per event; saved local lists and meta contexts share immutable structure. The existing compiler performance gate still applies.

## Validation

One compact metadata fixture checks multi-name groups, a dependent omitted default, inferred implicits, a resolved global reference, constructor field ownership and a projection resumed after a later argument fixes its type. It checks local-identity containment under final assignments and requires exactly one successful postponed projection occurrence. Full existing source/kernel, module, solver, backend and performance qualification remains required. This is an M2 retention prerequisite only, not C5 round-trip or semantic-preservation evidence.
