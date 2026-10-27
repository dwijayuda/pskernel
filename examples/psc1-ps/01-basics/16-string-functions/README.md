# String parameters and admitted operations

Build a greeting using the exact String operations exposed by the current compiler fixtures, and inspect its length. The greeting is Hello, Ada!.

This example should finish as **Checked** in PSC1 editor 0.1.1.

## Concepts

String, string parameters, String.Internal.append, String.Internal.length.

## Open the example

Open this folder in VS Code, or open `Main.ps` from the top-level examples workspace. Keep all listed files together; `proofscript.json` supplies the exact dependency order. Use **ProofScript: Show Infoview** to inspect current declarations and messages.

## Source files

- [Main.ps](Main.ps) — module `Main`.

## Expected exported values

- `result` = `"Hello, Ada!"`.

These values are checked by executing the emitted JavaScript in the archive qualification. The Infoview displays types and verification status; it does not evaluate expressions as a REPL.

[Back to the complete index](../../INDEX.md).
