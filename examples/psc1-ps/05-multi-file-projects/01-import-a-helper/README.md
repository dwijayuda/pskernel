# Import a helper module

Keep a reusable function in a separate source module, then call it from Main. The result is 42.

This example should finish as **Checked** in PSC1 editor 0.1.1.

## Concepts

import, module order, namespace.

## Open the example

Open this folder in VS Code, or open `Main.ps` from the top-level examples workspace. Keep all listed files together; `proofscript.json` supplies the exact dependency order. Use **ProofScript: Show Infoview** to inspect current declarations and messages.

## Source files

- [lib/Numbers.ps](lib/Numbers.ps) — module `Numbers`.
- [Main.ps](Main.ps) — module `Main`.

## Expected exported values

- `result` = `42`.

These values are checked by executing the emitted JavaScript in the archive qualification. The Infoview displays types and verification status; it does not evaluate expressions as a REPL.

[Back to the complete index](../../INDEX.md).
