# ADR 0006 — Hermetic content-addressed production builds

**Status:** Accepted design direction; current content-addressed self-host caches are the first implementation step.

## Context

The current developer/bootstrap environment may discover tools through PATH, node_modules, and environment overrides. This is convenient but not a complete reproducible release contract.

The resident self-host cache already demonstrates content hashing and red/green semantic reuse.

## Decision

Production/release builds use:

- explicit build actions;
- canonical action identities;
- content-addressed artifacts;
- explicit toolchain manifests;
- semantic lockfiles;
- declared environment/capabilities;
- deterministic scheduling/order;
- content verification on remote/cache boundaries.

Developer mode may retain convenient tool discovery but must not claim hermetic release reproducibility.

## Consequences

- local/remote caching becomes safe and predictable;
- incremental invalidation is based on semantic/interface identity rather than mtime;
- release builds can run locked/offline;
- toolchain changes are explicit build inputs;
- supply-chain provenance can bind actual action/artifact identities.

## Security rule

A remote cache is untrusted storage. Every fetched artifact is content-verified before use.
