# Three-module calculation pipeline

Compose a transitive dependency chain: Units -> Invoice -> Main. The final total is 950 cents.

This example should finish as **Checked** in PSC1 editor 0.1.1.

## Concepts

transitive imports, project manifest, reuse.

## Open the example

Open this folder in VS Code, or open `Main.ps` from the top-level examples workspace. Keep all listed files together; `proofscript.json` supplies the exact dependency order. Use **ProofScript: Show Infoview** to inspect current declarations and messages.

## Source files

- [src/Units.ps](src/Units.ps) — module `Units`.
- [src/Invoice.ps](src/Invoice.ps) — module `Invoice`.
- [Main.ps](Main.ps) — module `Main`.

## Expected exported values

- `result` = `950`.

These values are checked by executing the emitted JavaScript in the archive qualification. The Infoview displays types and verification status; it does not evaluate expressions as a REPL.

[Back to the complete index](../../INDEX.md).
