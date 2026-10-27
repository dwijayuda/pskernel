# Reflexivity of explicitly defined Leibniz equality

For every predicate, a proof at n is already a proof at n; this establishes Same(n, n). Same is defined locally, not the built-in Eq.

This example should finish as **Checked** in PSC1 editor 0.1.1.

## Concepts

Leibniz equality, reflexivity, predicate, dependent function.

## Open the example

Open this folder in VS Code, or open `Main.ps` from the top-level examples workspace. Keep all listed files together; `proofscript.json` supplies the exact dependency order. Use **ProofScript: Show Infoview** to inspect current declarations and messages.

## Source files

- [Support.ps](Support.ps) — module `Support`.
- [Main.ps](Main.ps) — module `Main`.

## Expected exported values

- `exampleNumber` = `14`.

These values are checked by executing the emitted JavaScript in the archive qualification. The Infoview displays types and verification status; it does not evaluate expressions as a REPL.

[Back to the complete index](../../INDEX.md).
