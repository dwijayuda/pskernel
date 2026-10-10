# @proofscript/stdlib

Optional PSC0 source-only standard library. The existing canonical sources remain under `psc0/stdlib/ProofScript`; the npm distribution stages these unchanged Lean sources or the supported Lean-to-PS translations as `src/ProofScript/...`. Consumers explicitly install and register the library in `package.json` with `proofscript.libraries.ProofScript = "@proofscript/stdlib"`.

Not installed by `npm install -g proofscript`. This package is currently experimental; source conformance and stable module ABI have not been claimed.
