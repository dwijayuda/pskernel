# PSC2 checked compiler bootstrap

The generated bootstrap is compiler-only. No kernel implementation is in its source
closure. The default host-side checker is now `lean434`, provided by the native
`@proofscript/pskernel-lean` provider pinned to Lean 4.34.0.

| Selector | Implementation | Role |
| --- | --- | --- |
| lean434 | Native Lean 4.34.0 kernel | Default host-side checker |
| lean434-wasm | Lean 4.34.0 kernel in WebAssembly | Explicit portable alternative |
| pskernel-core | PSC-generated owned JavaScript | Explicit experimental alternative; off-bootstrap |

No rejection, timeout, exhaustion or provider error selects another checker. The
selected provider is recorded in every checked-build receipt.

The compiler bootstrap entry is `packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean`
and contains only the TypeScript compiler composition root. Kernel checking happens
after canonical admissions are produced; it is not compiled into the self-hosted
compiler.

For source checkouts, the default native checked profile requires a freshly built
current-semantic provider under `lean-checked/.lake/build/bin`,
`packages/pskernel-lean/.lake/build/bin`, or an explicit
`PSC_LEAN_KERNEL_PROVIDER_BIN`. The checked profile deliberately does not fall back
to the older committed multi-platform native prebuilts while those are awaiting a
fresh five-platform regeneration.

Run:

    node lean-checked/psc.mjs bootstrap
    node lean-checked/psc.mjs fixed-point

Use the portable alternative explicitly with:

    node lean-checked/psc.mjs fixed-point --kernel lean434-wasm

Outputs are isolated under `dist/checked/<selector>/`. A successful checked fixed
point means the generated compiler is repeatedly checked by the selected external
kernel and reproduces canonical source and TypeScript output. It is a compiler
self-hosting claim, not an owned-kernel or joint compiler/kernel self-hosting claim.
