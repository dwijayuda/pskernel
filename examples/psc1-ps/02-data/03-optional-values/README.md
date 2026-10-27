# Optional values and an explicit default

Handle an optional membership discount with Option.none and Option.some before calculating a price.

This example should finish as **Checked** in PSC1 editor 0.1.1.

## Concepts

Option, constructor inference, missing values, pattern matching, Nat subtraction.

## Open the example

Open this folder in VS Code, or open `Main.ps` from the top-level examples workspace. Keep all listed files together; `proofscript.json` supplies the exact dependency order. Use **ProofScript: Show Infoview** to inspect current declarations and messages.

## Source files

- [Main.ps](Main.ps) — module `Main`.

## Expected exported values

- `memberPrice` = `25`.
- `visitorPrice` = `40`.

These values are checked by executing the emitted JavaScript in the archive qualification. The Infoview displays types and verification status; it does not evaluate expressions as a REPL.

[Back to the complete index](../../INDEX.md).
