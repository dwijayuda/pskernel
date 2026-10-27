# Intentional error: unparenthesized comparison chain

The selected comparison operators do not associate, so 1 < 2 < 3 is refused. A simple repair is an if condition containing one comparison.

**This example is intentionally invalid.** A compiler diagnostic is the expected result. Read the source comments for the repair; this folder is excluded from the positive examples.

## Concepts

intentional error, parse error, nonassociative operators.

## Open the example

Open this folder in VS Code, or open `Main.ps` from the top-level examples workspace. Keep all listed files together; `proofscript.json` supplies the exact dependency order. Use **ProofScript: Show Infoview** to inspect current declarations and messages.

## Source files

- [Main.ps](Main.ps) — module `Main`.

Expected compiler phase: `parse`. No accepted proof is claimed for this source.

[Back to the complete index](../../INDEX.md).
