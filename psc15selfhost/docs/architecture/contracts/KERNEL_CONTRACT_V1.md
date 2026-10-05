# KernelContract-v1

**Status:** frozen checked-provider host contract for the current production-hardening phase.

Machine identity:

```text
proofscript-kernel-contract/1
```

The executable reference identity is defined by `scripts/kernel-contract.mjs`.

## Purpose

`KernelContract-v1` separates the compiler's checked-session semantics from any concrete kernel implementation.

Current provider:

```text
lean434-wasm
@proofscript/pskernel-lean-wasm
Lean 4.34.0
```

Explicit alternatives:

```text
lean434       native Lean reference provider
pskernel-core experimental owned provider
```

All providers selected for a checked build must implement the same contract. Rejection, timeout, unsupported input, malformed responses, or provider failure never selects another provider.

## Request contract

The provider receives UTF-8 JSON text with the envelope:

```text
format   = proofscript-checked-admissions
version  = 2
admissions = array
```

The host validates this envelope before provider invocation.

The admissions payload is produced from the exact prepared compiler value that remains alive across checking and emission. The host does not reread or re-elaborate source after acceptance.

## Decision contract

A provider response must be an object containing:

```text
accepted : Bool
```

For rejection:

```text
accepted  = false
errorKind : String
```

Provider-specific identity fields are checked separately from the kernel contract.

An accepted result means only that the selected provider admitted the submitted canonical admissions under its declared provider identity/profile. It is not by itself a proof of erasure or backend semantic preservation.

## Checked-session capability

The host checked session:

1. prepares source once;
2. freezes the prepared object graph;
3. derives canonical admissions;
4. validates the KernelContract-v1 envelope;
5. invokes exactly one selected provider;
6. checks provider identity and the contract decision;
7. creates a non-transferable in-process checked handle;
8. permits emission only through that handle;
9. re-derives admissions from the same prepared object before emission and rejects any change.

A serialized checked-build receipt is an audit record. It is not a transferable checked capability.

## Contract identity

The canonical contract identity text is:

```text
proofscript-kernel-contract/1
admissions=proofscript-checked-admissions/2
decision=accepted-boolean
failClosed=true
```

Its SHA-256 is:

```text
37e10db37db56d80a8731b39d5813cb82494ec5a433063c295958fef434f8379
```

The executable guard exposes the same value as `kernelContractV1Sha256`. Build receipts schema v4 carry both the contract object and the provider/kernel descriptor.

## Compatibility

A future contract is not silently accepted as v1.

A change to any of these requires a new contract version or explicit compatible extension policy:

- admissions envelope format/version;
- acceptance decision semantics;
- fail-closed behavior;
- capability/handle authority semantics.

Changing the concrete provider while preserving this contract does not require changing erasure or backend semantics.

## Long-term migration

The intended future provider is `pskernel-core` after its readiness gates close.

The migration target is:

```text
same CandidateCore/admissions
same KernelContract-v1-compatible checked session
different selected provider
same downstream CheckedCore/erasure/backend architecture
```

If `pskernel-core` requires a genuinely different semantic contract, that change must be explicit rather than hidden behind provider selection.
