# PSC2 checked compiler bootstrap

The generated bootstrap is compiler-only. No kernel implementation is in its source
closure. The default host-side checker is `lean434-wasm`, provided by
`@proofscript/pskernel-lean-wasm` and pinned to Lean 4.34.0.

| Selector | Implementation | Role |
| --- | --- | --- |
| lean434-wasm | Lean 4.34.0 kernel in WebAssembly | Default host-side checker |
| pskernel-core | PSC-generated owned JavaScript | Explicit experimental alternative; off-bootstrap |
| lean434 | Native Lean 4.34.0 kernel | Explicit native alternative |

No rejection, timeout, exhaustion or provider error selects another checker. The
selected provider is recorded in every checked-build receipt.

The compiler bootstrap entry is `packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean`
and contains only the TypeScript compiler composition root. Kernel checking happens
after canonical admissions are produced; it is not compiled into the self-hosted
compiler.

Run:

    node lean-checked/psc.mjs bootstrap
    node lean-checked/psc.mjs fixed-point

Outputs are isolated under `dist/checked/<selector>/`. A successful checked fixed
point means the generated compiler is repeatedly checked by the selected external
kernel and reproduces canonical source and TypeScript output. It is a compiler
self-hosting claim, not an owned-kernel or joint compiler/kernel self-hosting claim.
