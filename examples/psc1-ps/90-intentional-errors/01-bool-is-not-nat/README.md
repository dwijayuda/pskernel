# Intentional error: Bool supplied where Nat is required

The value true has type Bool, so it cannot initialize a Nat. Repair by replacing true with 42.

**This example is intentionally invalid.** A compiler diagnostic is the expected result. Read the source comments for the repair; this folder is excluded from the positive examples.

## Concepts

intentional error, type mismatch, Bool, Nat.

## Open the example

Open this folder in VS Code, or open `Main.ps` from the top-level examples workspace. Keep all listed files together; `proofscript.json` supplies the exact dependency order. Use **ProofScript: Show Infoview** to inspect current declarations and messages.

## Source files

- [Main.ps](Main.ps) — module `Main`.

Expected compiler phase: `elaboration`. No accepted proof is claimed for this source.

[Back to the complete index](../../INDEX.md).
