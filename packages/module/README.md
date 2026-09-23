# @proofscript/module

Status: **checked-admission artifact v2 / private**  
Trust: **untrusted support layer**

Portable deterministic module artifacts for pskernel / ProofScript.

## Artifact versions

### Version 1 — Lean4Export compatibility

`proofscript-module@1` keeps the original canonical Lean4Export 3.1.0 NDJSON
payload. Loading replays that stream with `Lean4ExportReplay`.

### Version 2 — native checked admissions

`proofscript-module@2` stores canonical JSON produced by the versioned
`@proofscript/checked-core` admission codec.

The payload can contain the current checked-core admission forms:

- definitions and theorems;
- inductive declarations;
- structures and classes plus validated source metadata;
- instances plus validated class metadata.

Codec v1 rejects unresolved state rather than serializing it:

- free variables;
- expression metavariables;
- universe metavariables;
- expression `mdata`.

Loading v2 checks artifact/payload/dependency integrity and pinned kernel
compatibility, decodes the payload, then calls
`admitCheckedCoreAdmissions`. Serialized declarations are never trusted proof
evidence.

## Trust model

```text
.psmodule v2
    |
    +-> verify content/dependency hashes
    |
    +-> decode closed checked admissions
    |
    +-> caller-supplied base/dependency Environment
    |
    +-> admitCheckedCoreAdmissions
    |
    v
  pskernel
```

Artifact integrity proves the bytes have not changed. It does **not** prove that
those bytes were derived from a particular source file: a different
kernel-valid artifact can be created and self-hashed.

For that reason the verified compiler currently:

1. parses/elaborates source normally;
2. creates a v2 artifact from the resulting local admissions;
3. immediately replay-gates the artifact against its checked dependency
   environment;
4. writes it below `dist/.proofscript/modules/` during verified builds.

It does **not** yet trust a disk artifact to skip source elaboration. That
future optimization requires a trusted expected artifact hash/lockfile or
derivation certificate, and an explicit pinned base-environment identity.

## Dependency identity

Artifact dependency records contain logical module names plus exact dependency
artifact integrities. The container normalizes dependency order.

The compiler's existing source/dependency cache key remains a separate value.
It is included only as untrusted artifact metadata so source-kind-neutral build
identity and artifact byte identity are not conflated.

## Compatibility

Version 1 remains readable. Version 2 is the native ProofScript persistence
path; no checked admissions are encoded as fake Lean4Export records.

## Development

The root kernel and checked-core package must be built first.

```bash
npm run build
cd packages/module
npm test
```
