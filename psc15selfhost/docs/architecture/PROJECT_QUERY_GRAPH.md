# Project Query Graph and Module-Interface Invalidation

## Status

The current implementation has two layers:

1. `Ps.Project.QueryGraph` — a pure, host-independent red/green invalidation engine.
2. `Ps.Host.ProjectQuery` — an opt-in, same-process in-memory snapshot adapter for the existing project loader.

The existing cold `psHostLoadProject` path is unchanged.

No snapshot is persisted to disk yet. No cached cumulative environment is reused.

## Goal

Avoid rebuilding a dependent module merely because an imported module's source
changed when the imported module's downstream-observable semantic interface did
not change.

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

This is semantic red/green invalidation, not timestamp-only invalidation.

## Pure query model

`Ps.Project.QueryGraph` uses opaque identity strings:

- `sourceKey` — identity of inputs that determine a module computation.
- `interfaceKey` — identity of semantics observable by importers.

A prior successful module record stores:

- module identity;
- source key;
- interface key;
- ordered dependency identities and the interface key observed for each dependency.

A module is green only when:

1. a previous successful record exists;
2. its source key is unchanged;
3. its import shape is unchanged;
4. every dependency has already been committed in the current evaluation;
5. every current dependency interface key equals the key recorded previously.

Otherwise it is red.

After a red module is recomputed, its new interface key is committed before
dependents are evaluated. A source-only implementation change whose interface
key remains stable therefore stops invalidation propagation.

## In-memory host adapter

`Ps.Host.ProjectQuery` intentionally keeps the first integration conservative.

### Source identity

For the same-process snapshot adapter, `sourceKey` is the exact source text
read from the module file.

This avoids choosing a hashing algorithm prematurely. It also means a warm
snapshot cannot incorrectly reuse a module whose bytes changed.

### Module identity

The current host adapter maps each resolved source path to an opaque `PsName`
query identity. Import paths are resolved before the query decision, so the
query graph compares resolved dependencies rather than unresolved import text.

### Interface identity

For a rebuilt module, the current in-memory `interfaceKey` is the complete
canonical checked-admission serialization of that module's **own declaration
batch** produced by `psEncodeCheckedAdmissionsCanonical`.

This is deliberately conservative. It includes definition/theorem values and
inductive/constructor/recursor declaration data instead of hashing only public
type signatures. A body change may therefore propagate even when a more refined
future interface model could prove that change unobservable. False-red rebuilds
are acceptable in this phase; false-green reuse is not.

Dependency interface identities are tracked separately, so a module-local
canonical admission key does not need to inline dependency declarations.

### Artifact boundary

A reusable `PsHostModuleArtifact` contains only:

- resolved module path;
- the module's own elaborated declarations.

It does **not** contain:

- a cumulative `PsEnvironment`;
- dependency declarations;
- checked-kernel session state;
- erased or VerifiedIR artifacts;
- backend artifacts.

On a green reuse, dependency modules are processed first and their declarations
are already present in the current environment. The reused module's own
declarations are then re-added through `psAddDeclarationList`.

This reconstructs the current environment rather than trusting a stale cached
environment.

### Missing artifacts fail safe

A green query decision without a corresponding prior module artifact falls back
to rebuilding the module. It never treats missing cached state as reusable.

## Ordering

Dependencies must be committed before dependents.

The current host adapter obtains this property from the existing recursive
dependency loader. `Ps.Project.ModuleGraph` remains the project-level
topological planning primitive for a future graph-wide scheduler.

A missing current dependency interface is a fail-closed query condition.

## Trust boundaries

Red/green reuse must not weaken existing authority boundaries.

The current in-memory adapter reuses only elaborated declarations. It does not
turn `AdmissionReady` into checked state, does not reuse a checked session,
does not bypass `ErasedIR -> VerifiedIR` validation, and does not reuse backend
emission artifacts.

The canonical-admission string is used here only as a conservative semantic
identity. It is not itself a checked-session receipt.

## Persistent-cache requirements

The current snapshot API is same-process only. Before snapshots or artifacts can
be persisted across compiler executions, the serialized format must bind all
inputs that can change meaning, including at least:

- query/snapshot schema version;
- language/source profile identity;
- compiler identity;
- relevant runtime-semantics identity;
- checked-kernel contract/provider identity when persisted artifacts cross that boundary;
- canonical interface-serialization version.

Persistent reuse must reject identity mismatches rather than silently reuse an
artifact produced under another semantic contract.

## Failure behavior

The pure/query layers mark red or reject on:

- no previous module record;
- changed source key;
- changed import shape;
- missing current dependency interface;
- changed dependency interface key;
- duplicate query record insertion;
- committing a rebuilt module before dependency interfaces are available.

The host layer also rebuilds if a query record is green but its corresponding
module artifact is absent.

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

The `psc1_host_project_query_tests` corpus runs a real two-module fixture twice
in one process:

1. the cold run rebuilds both modules;
2. the warm run consumes the returned snapshot;
3. both modules are reused;
4. canonical declarations from cold and warm results are equal.

Both corpora are wired into the PSC15 cloud workflow.

## Next bounded slice

The next step after these in-memory semantics are green is **not** immediate
filesystem persistence.

First define and version the persistent snapshot/artifact envelope and the
identity bindings above. Then add a host serializer/deserializer that rejects
mismatched identities. Only after that boundary is tested should project builds
load snapshots across processes.
