# A generic Maybe type and reusable fallback

Define a polymorphic optional container and instantiate its generic getOr function for Nat and Bool.

This example should finish as **Checked** in PSC1 editor 0.1.1.

## Concepts

type parameters, implicit binders, polymorphism, generic inductive, module imports.

## Open the example

Open this folder in VS Code, or open `Main.ps` from the top-level examples workspace. Keep all listed files together; `proofscript.json` supplies the exact dependency order. Use **ProofScript: Show Infoview** to inspect current declarations and messages.

## Source files

- [Data.ps](Data.ps) — module `Data`.
- [Main.ps](Main.ps) — module `Main`.

## Expected exported values

- `sample` = `7`.

These values are checked by executing the emitted JavaScript in the archive qualification. The Infoview displays types and verification status; it does not evaluate expressions as a REPL.

[Back to the complete index](../../INDEX.md).
