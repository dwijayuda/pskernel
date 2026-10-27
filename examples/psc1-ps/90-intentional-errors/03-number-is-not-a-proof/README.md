# Intentional error: a number cannot prove an arbitrary proposition

The theorem claims a proof of arbitrary P but supplies the Nat literal 0. Repair by accepting a premise of type P and returning it.

**This example is intentionally invalid.** A compiler diagnostic is the expected result. Read the source comments for the repair; this folder is excluded from the positive examples.

## Concepts

intentional error, proof refusal, Prop, type mismatch.

## Open the example

Open this folder in VS Code, or open `Main.ps` from the top-level examples workspace. Keep all listed files together; `proofscript.json` supplies the exact dependency order. Use **ProofScript: Show Infoview** to inspect current declarations and messages.

## Source files

- [Main.ps](Main.ps) — module `Main`.

Expected compiler phase: `elaboration`. No accepted proof is claimed for this source.

[Back to the complete index](../../INDEX.md).
