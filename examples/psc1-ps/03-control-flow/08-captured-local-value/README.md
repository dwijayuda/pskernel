# A closure captures the current value

A closure keeps the value present when it is created. Updating the later local binding does not change the captured value; the result is 7.

This example should finish as **Checked** in PSC1 editor 0.1.1.

## Concepts

closure capture, mutable local, lexical scope.

## Open the example

Open this folder in VS Code, or open `Main.ps` from the top-level examples workspace. Keep all listed files together; `proofscript.json` supplies the exact dependency order. Use **ProofScript: Show Infoview** to inspect current declarations and messages.

## Source files

- [Main.ps](Main.ps) — module `Main`.

## Expected exported values

- `result` = `7`.

These values are checked by executing the emitted JavaScript in the archive qualification. The Infoview displays types and verification status; it does not evaluate expressions as a REPL.

[Back to the complete index](../../INDEX.md).
