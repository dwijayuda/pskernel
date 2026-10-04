# ADR 0002 — CheckedCore is a kernel authority capability

**Status:** Accepted design direction; current bootstrap still uses an honest AdmissionReady staging type.

## Context

The current compiler can canonicalize admissions and validate codec support before erasure. That is useful bootstrap evidence but is weaker than actual kernel admission.

Renaming such a staging value to CheckedCore would blur the trusted boundary.

## Decision

`CheckedCore` / `CheckedModule` means exactly:

> admitted by the designated kernel provider under a named kernel contract.

Only the kernel provider may construct checked artifacts or checked handles.

Production erasure accepts CheckedCore, not arbitrary elaborated declarations or a frontend Boolean/flag.

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
