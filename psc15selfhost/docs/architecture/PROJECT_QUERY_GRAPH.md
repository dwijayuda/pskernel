# Project Query Graph and Module-Interface Invalidation

## Status

This document describes the first project-query-graph slice introduced by
`Ps.Project.QueryGraph`.

The current implementation is a pure invalidation engine. It does **not** yet
persist artifacts, hash files, or bypass parsing, elaboration, admission,
erasure, VerifiedIR validation, or backend emission.

## Goal

Avoid rebuilding a dependent module merely because an imported module's source
changed when the imported module's downstream-observable semantic interface did
not change.

The intended red/green rule is:

```text
source changed
    |
    v
recompute module
    |
    +-- semantic interface key unchanged --> dependent may remain green
    |
    +-- semantic interface key changed ----> dependent becomes red
```

This is different from timestamp-based or source-file-only invalidation.

## Pure model

`Ps.Project.QueryGraph` uses opaque identity strings supplied by a host layer:

- `sourceKey` — identity of the inputs that determine a module computation.
- `interfaceKey` — identity of the module semantics observable by importers.

A prior successful module record stores:

- module name;
- source key;
- interface key;
- ordered imported module names and the interface key observed for each import.

A module is green only when all of the following hold:

1. a previous successful record exists;
2. the source key is unchanged;
3. the import shape is unchanged;
4. every dependency has already been committed in the current topological
   evaluation;
5. every current dependency interface key equals the key recorded by the
   previous module result.

Otherwise the module is red and must be recomputed.

After a red module is recomputed, its new interface key is committed before
dependents are evaluated. Therefore a source-only implementation change whose
semantic interface key remains stable does not propagate invalidation.

## Required evaluation order

The query engine assumes dependencies are committed before their dependents.

The existing `Ps.Project.ModuleGraph` topological build plan is the canonical
ordering mechanism for a future host adapter. A missing current dependency
interface is a fail-closed query error rather than an invitation to reuse stale
state.

## Interface-key correctness requirement

The future interface-key algorithm must cover **all semantics that an importing
module can observe**.

It is not sufficient to hash only declaration names and type signatures if
downstream elaboration, reduction, typeclass/instance synthesis, attributes,
generated recursors, or other imported behavior can observe additional
declaration data.

The exact canonical interface serialization is intentionally not frozen by this
first slice. Until that serialization is defined and validated, callers should
treat `interfaceKey` as an opaque trusted input to the pure invalidation model,
not as a claim that a safe persistent cache already exists.

## Source-key correctness requirement

Likewise, a production source key must bind every input capable of changing the
computed module result. At minimum the future host adapter needs to account for
source content and relevant compiler/profile/toolchain/runtime configuration.
The pure project layer deliberately does not choose a hashing algorithm or
filesystem policy.

## Trust boundaries

Red/green reuse must not weaken existing authority boundaries.

A future reusable artifact must remain bound to the relevant identities and
contracts, including the language/profile and any checked/admission/runtime
contracts needed by that artifact class. Reuse must never convert
`AdmissionReady` into checked state, bypass `ErasedIR -> VerifiedIR`
validation, or silently substitute an artifact produced under a different
semantic contract.

The current query graph stores no trusted executable artifact, so none of those
authority transitions are implemented here.

## Current failure behavior

The pure engine rejects or marks red on:

- no previous module record;
- changed source key;
- changed import shape;
- missing current dependency interface;
- changed dependency interface key;
- duplicate record insertion;
- rebuilding a module before all dependency interfaces are available.

## Validation

The focused `psc1_project_query_graph_tests` corpus covers:

- unchanged module reuse;
- source changes becoming red;
- source change + stable rebuilt interface stopping propagation;
- changed rebuilt interface invalidating a dependent;
- import-shape invalidation;
- missing dependency invalidation;
- fail-closed dependency capture;
- duplicate commit rejection;
- direct interface-change detection.

The PSC15 cloud workflow builds `PsProject` and runs this corpus.

## Next integration slice

The next bounded step is host-side snapshot plumbing:

1. represent per-module successful results separately from the current
   cumulative `PsHostProjectState`;
2. execute modules in `Ps.Project.ModuleGraph` order;
3. feed source/interface identities into the pure query engine;
4. reuse only artifacts whose authority/configuration identities match;
5. keep persistence and canonical interface serialization separate until their
   contracts are explicitly defined.

This sequencing keeps invalidation semantics testable independently from
filesystem caching and artifact serialization.
