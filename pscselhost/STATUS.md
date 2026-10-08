# PSC2 minimal self-host status

Status (2026-10-03): the project uses a **compiler-only bootstrap**. The generated compiler closure contains **55 source modules** and no kernel package. `@proofscript/pskernel-lean-wasm` (Lean 4.34.0 WASM) is the default host-side checker.

The canonical compiler fixed point now passes:

- PSC1 semantic check: **1,916 declarations**
- compiler-only bootstrap closure: **55 modules**
- canonical source fixed point: **PASS**
- canonical closure SHA-256: `ee6dd22f1b74b97113cc1a5e36aadad3cceecb2b152653f2c0dc26dd07aa22f7`
- generated TypeScript fixed point: **PASS**
- TypeScript SHA-256: `fb173a348d1555d1ff224b9977f6fee68591b79f781a6b292c2572648415b033`
- generated JavaScript SHA-256: `74dcebb7b296d81924d92987e99146b5d1c5ff9fbe3d8076ca591952d2ef7f76`
- TypeScript compiler pin: **5.8.3**

The generated owned `@proofscript/pskernel-core` checker.14 work is preserved as a private experimental alternative, with historical evidence intact, but it is not a bootstrap dependency and is not the default checker. No fallback is performed between checker implementations.

The remaining completion gate for this workstream is the **default Lean-WASM checked fixed point**: bootstrap, selfhost and repeat generations must all be accepted by the default `lean434-wasm` provider and retain source/compiler parity. This target is compiler self-hosting only; it does not claim owned-kernel or joint compiler/kernel self-hosting.
