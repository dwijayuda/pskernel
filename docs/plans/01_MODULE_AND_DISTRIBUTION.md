# Module and distribution plan

Status: MVP implemented; format intentionally provisional.

Lean 4.34 analogues:
- `Lean.Environment.ModuleData`
- module import/finalization
- `src/library/module.cpp`

## Goal

Define a portable, deterministic, npm-friendly artifact for checked ProofScript/Lean-compatible declarations.

## Trust model

The module format is outside the logical TCB when every loaded declaration is replayed through pskernel.

A future fast trusted-load mode, if ever added, must be explicitly separate.

## MVP format

A module manifest should contain:

- format/version
- logical module name
- kernel compatibility identifier
- dependencies + integrity hashes
- deterministic declaration stream
- module content hash
- optional auxiliary sections

Auxiliary sections may include:
- source maps
- docs
- pretty names
- compiler IR
- diagnostics/index metadata

They must never alter logical declaration meaning.

## Required APIs

- encode checked module
- decode module
- deterministic canonical bytes
- hash module/declarations
- stream declarations into an existing Environment
- verify dependency identities
- inspect manifest without loading declarations
- pack/unpack via CLI

## Initial encoding

Prefer a simple deterministic representation first. JSON is acceptable for MVP if canonicalization is explicit. CBOR or a compact binary format can be evaluated later.

Do not use `.olean` runtime-image serialization as the primary JS ecosystem format.

## Acceptance gates

- round-trip stability
- deterministic hash across platforms
- corrupted dependency/hash rejection
- duplicate/reordered declaration rejection where order is semantically significant
- loaded declarations pass normal pskernel admission
- fixture tests for Windows/Linux/macOS byte identity where feasible

## Non-goals

- parser/elaborator metadata semantics
- package-manager replacement
- trusted fast loading
- arbitrary executable JavaScript inside trusted declaration payloads


## MVP implementation note

`@proofscript/module` format v1 currently uses canonical `lean4export` 3.1.0 NDJSON as its declaration payload. This is deliberately a transport representation, not a second declaration semantics.

Implemented:
- canonical JSON envelope
- CRLF/LF normalization
- SHA-256 payload integrity
- SHA-256 whole-artifact integrity
- canonical dependency ordering and dependency integrity checks
- replay loading through pskernel
- JSON Schema
- CLI pack/verify/inspect/check integration

Deferred:
- ProofScript-native declaration payload codec
- browser/WebCrypto hashing
- trusted fast loading
- package-manager dependency resolution
