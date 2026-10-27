# Recursion with an invariant parameter

Compute natural powers while decreasing the exponent and preserving the base argument across recursive calls.

This example should finish as **Checked** in PSC1 editor 0.1.1.

## Concepts

multiple arguments, structural recursion, invariant parameter, natural powers.

## Open the example

Open this folder in VS Code, or open `Main.ps` from the top-level examples workspace. Keep all listed files together; `proofscript.json` supplies the exact dependency order. Use **ProofScript: Show Infoview** to inspect current declarations and messages.

## Source files

- [Main.ps](Main.ps) — module `Main`.

## Expected exported values

- `fifthPowerOfTwo` = `32`.
- `cubeOfThree` = `27`.

These values are checked by executing the emitted JavaScript in the archive qualification. The Infoview displays types and verification status; it does not evaluate expressions as a REPL.

[Back to the complete index](../../INDEX.md).
