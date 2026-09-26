# 12. Validating Proofs and Assurance Claims

"Verified" can describe several different properties.

PSC1 keeps them separate.

## Kernel validation

Strongest ordinary logical claim:

> pskernel accepted the closed elaborated declaration/proof term under the
> recorded environment and semantic version.

## Source validation

The parser/elaborator may be tested against:

- canonical source round trips;
- official Lean reference behavior for the supported common subset;
- positive/negative conformance corpora;
- differential tests.

These improve confidence in frontend correctness but do not replace kernel
checking.

## Checked admission replay

Serialized CheckedCore/admission data must be replayed through pskernel when it
is admitted.

A stored JSON object is not a proof certificate by identity alone.

## Axiom tracking

Proofs may depend on explicit axioms/opaque assumptions.

Assurance output should expose that dependency rather than calling the result
unconditionally assumption-free.

## Runtime extern tracking

FFI/runtime dependencies are a different assumption category from logical
axioms.

They affect executable trust and reproducibility, not theorem proof evidence.

## Compiler assurance

Separate claims are needed for:

- erasure preservation;
- VerifiedIR lowering;
- backend emission;
- target compiler/toolchain behavior;
- runtime ABI.

## Differential backend testing

A useful executable assurance gate is:

```text
same checked program
-> independent backend builds
-> same defined observable behavior
```

This is evidence for compiler/runtime conformance, not a formal proof unless the
transformation itself has been proved.

## Self-host fixed point

Self-hosting adds assurance when independently generated compiler generations
stabilize and pass semantic parity gates.

A self-hosted compiler is not automatically correct simply because it compiles
itself.

## Claim wording

Prefer precise statements such as:

- "pskernel-checked theorem";
- "canonical Lean differential passed";
- "TS/Rust/Wasm differential passed";
- "compiler generation reached fixed-point artifact equality."

Avoid an undifferentiated "formally verified" label when only one layer is
proved.
