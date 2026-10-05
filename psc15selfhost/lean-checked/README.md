# PSC2 checked compiler bootstrap

The generated bootstrap is compiler-only. No kernel implementation is in its source
closure. The default checked provider is now `lean434-wasm`, provided by the bundled
`@proofscript/pskernel-lean-wasm` package pinned to Lean 4.34.0.

| Selector | Implementation | Role |
| --- | --- | --- |
| lean434-wasm | Lean 4.34.0 kernel in WebAssembly | Default checked provider |
| lean434 | Native Lean 4.34.0 kernel | Explicit native reference alternative |
| pskernel-core.old3 | PSC-generated owned JavaScript | Explicit experimental alternative; off-bootstrap |

No rejection, timeout, exhaustion or provider error selects another checker. The
selected provider is recorded in every checked-build receipt.

The compiler bootstrap entry is `packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean`
and contains only the TypeScript compiler composition root. Kernel checking happens
after canonical admissions are produced; it is not compiled into the self-hosted
compiler.

The default checked profile uses the bundled `pskernel-lean-wasm` launcher/module.
The package verifies those bytes against `PREBUILT_WASM_MANIFEST.json` before the
default invocation and verifies protocol/provider/Lean/profile identity in every
result. A provider failure is an error, never a fallback.

Native Lean remains selectable explicitly with `--kernel lean434`. For source
checkouts it requires a freshly built current-semantic provider under
`lean-checked/.lake/build/bin`, `packages/pskernel-lean/.lake/build/bin`, or an
explicit `PSC_LEAN_KERNEL_PROVIDER_BIN`. The older committed native prebuilts are
not silently substituted.

Run the default checked profile:

    node lean-checked/psc.mjs bootstrap
    node lean-checked/psc.mjs fixed-point

Use the native reference alternative explicitly with:

    node lean-checked/psc.mjs fixed-point --kernel lean434

Use the experimental owned checker explicitly with:

    node lean-checked/psc.mjs fixed-point --kernel pskernel-core.old3

Outputs are isolated under `dist/checked/<selector>/`. A successful checked fixed
point means the generated compiler is repeatedly checked by the selected external
kernel and reproduces canonical source and TypeScript output. It is a compiler
self-hosting claim, not an owned-kernel or joint compiler/kernel self-hosting claim.

The current default choice is intentionally provisional: the provider-neutral checked
session/build protocol should allow `pskernel-core` to become the default later only
after its declared kernel-readiness gates close, without changing erasure or backend
semantics.
