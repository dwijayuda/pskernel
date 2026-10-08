# ADR 0002 — CheckedCore is a kernel authority capability

**Status:** Accepted design direction; current bootstrap still uses an honest AdmissionReady staging type.

## Context

The current compiler can canonicalize admissions and validate codec support before erasure. That is useful bootstrap evidence but is weaker than actual kernel admission.

Renaming such a staging value to CheckedCore would blur the trusted boundary.

## Decision

`CheckedCore` / `CheckedModule` means exactly:

> admitted by the designated kernel provider under a named kernel contract.

For the current hardening phase, the designated default provider is the pinned Lean 4.34 WebAssembly provider `@proofscript/pskernel-lean-wasm` (`lean434-wasm`). Native Lean is an explicit reference alternative. The owned `pskernel-core` remains the intended long-term authority but is not the default until its readiness gates close.

Only the selected kernel provider may create the checked-session capability for a prepared module.

Production erasure accepts the checked capability, not arbitrary elaborated declarations or a frontend Boolean/flag. Provider failure/rejection never triggers another provider.

## Consequences

- plugins/frontends cannot forge checked artifacts;
- kernel provider changes become explicit compatibility changes;
- checked artifact identity can bind Core hash, kernel contract, and receipt;
- bootstrap compatibility adapters may coexist temporarily but remain visibly weaker.

## Implementation guidance

If generated-language visibility cannot make the checked value strongly opaque, use a provider-owned handle containing:

```text
session identity
opaque handle
checkedCoreHash
kernelContract
receipt/evidence identity
```

The handle is capability evidence, not merely metadata.
