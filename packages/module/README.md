# @proofscript/module

Status: **MVP / private**  
Trust: **untrusted support layer**

Portable deterministic module artifact support for pskernel / ProofScript.

## MVP representation

Version 1 deliberately uses a canonicalized `lean4export` 3.1.0 NDJSON declaration stream as its logical payload.

This is a transport choice, **not** a new trusted declaration semantics. Loading an artifact always replays the declaration stream through pskernel.

The format records:

- module name
- module-format version
- Lean semantic compatibility version
- pskernel API compatibility version
- dependency module/integrity pairs
- canonical declaration payload
- SHA-256 payload integrity
- SHA-256 whole-artifact integrity
- optional untrusted metadata

CRLF and LF declaration streams normalize to identical artifact bytes/hashes.

## Trust model

```text
.psmodule artifact
      |
      v
@proofscript/module
  verify hashes/deps
      |
      v
Lean4ExportReplay
      |
      v
pskernel admission
      |
      v
Environment
```

The serializer/transport is not trusted to declare a proof valid.

## Development

The root kernel must be built first.

```bash
npm run build
cd packages/module
npm install
npm test
```

## Deliberate limitations of v1

- payload is Lean4export NDJSON rather than a native ProofScript declaration codec
- dependency identity is supplied explicitly by the caller
- no trusted fast-load/snapshot mode
- no compiler IR/source map semantics
- no npm workspace wiring yet

A future payload version can add a ProofScript-native declaration codec without changing the trust rule: declarations are still replayed through the kernel.

## ProofScript compiler integration note

The mixed-source ProofScript compiler now uses `@proofscript/project`
`BuildCache` plus dependency-integrity keys for **in-process** checked-module
reuse. This does not yet create `.psmodule` files.

Module artifact v1 requires a canonical Lean4Export NDJSON payload. The current
ProofScript elaborator produces checked-core admissions directly and no
checked-core -> Lean4Export serializer exists. Persistent compiler artifacts
must therefore wait for either:

1. a correct serializer into the existing replayable payload; or
2. a versioned ProofScript-native payload whose loader still rechecks every
   declaration through pskernel.

Do not encode checked admissions as fake Lean4Export records merely to reuse
the v1 container.
