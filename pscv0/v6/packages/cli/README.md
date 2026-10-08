# @proofscript/pscv-cli

The development executable is deliberately named psc-core, **not** psc, to prevent confusing the current incomplete tool with a certified compiler.

Commands: capabilities; inspect file.ps (hash, not parse); check-admissions file.json [native|wasm] (kernel admission only). No build or verify action is permitted. The final psc CLI will be a standalone Lean-built native executable with an optional npm launcher.
