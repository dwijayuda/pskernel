# 8. Axioms, Computation, and Trust

Theorem proving is meaningful only if the trust boundary is explicit.

PSC1 separates kernel-checked proof from assumptions and runtime behavior.

## Kernel-checked declarations

A theorem is accepted only after pskernel verifies its elaborated type and proof
term against the checked environment.

This is the strongest ordinary PSC1 claim.

## Axioms

An axiom/opaque external assumption may add a constant of a proposition/type
without constructing its proof internally.

That assumption must remain visible in trust/assurance metadata.

A theorem depending on an axiom is valid **relative to that axiom**.

## Runtime externals

PSC1's npm FFI declares runtime behavior such as:

```proofscript
extern function hostShout(value: String): String
  from "host-lib"
  import shout;
```

The logical constant/signature may be admitted as an opaque assumption, but the
kernel never executes JavaScript to validate a theorem.

Host behavior is therefore outside proof evidence.

## Computation in proofs

Kernel reduction may establish definitional equality.

That is fundamentally different from compiling arbitrary code and trusting the
compiled result as a proof.

PSC1 keeps compiler/runtime evaluation out of the small proof-checking TCB.

## Proof erasure

After a theorem or proof argument has been checked, it may erase from runtime
code.

Erasure does not weaken the theorem; the checking already happened.

## Compiler correctness is separate

Even if pskernel validates every source theorem, a buggy backend could still
miscompile executable code.

PSC1 therefore distinguishes:

- logical soundness of checked declarations;
- correctness/assurance of erasure;
- correctness/assurance of VerifiedIR;
- backend conformance;
- host/FFI assumptions.

## Trust manifests

Build outputs should expose important assumptions such as:

- axioms/opaque admissions;
- runtime externals;
- semantic/kernel version;
- backend/toolchain identity;
- relevant integrity fingerprints.

An artifact hash proves identity, not logical validity.

## No proof-by-host shortcut

PSC1 should reject designs equivalent to:

```text
run JS
if result is true
admit theorem
```

unless the result is explicitly represented as an axiom/trusted oracle with a
correspondingly weaker claim.

## Next

Continue to
[Proof Feedback and Debugging](./09-proof-feedback-and-debugging.md).
