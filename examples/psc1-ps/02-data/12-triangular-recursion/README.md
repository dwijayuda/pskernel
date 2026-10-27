# Structural recursion over natural numbers

Compute a triangular number by matching on Nat.zero and Nat.succ and recursing on the predecessor.

This example should finish as **Checked** in PSC1 editor 0.1.1.

## Concepts

Nat constructors, structural recursion, recursive sum, total definition.

## Open the example

Open this folder in VS Code, or open `Main.ps` from the top-level examples workspace. Keep all listed files together; `proofscript.json` supplies the exact dependency order. Use **ProofScript: Show Infoview** to inspect current declarations and messages.

## Source files

- [Main.ps](Main.ps) — module `Main`.

## Expected exported values

- `sample` = `21`.

These values are checked by executing the emitted JavaScript in the archive qualification. The Infoview displays types and verification status; it does not evaluate expressions as a REPL.

[Back to the complete index](../../INDEX.md).
