# PSKernel Lean Wasm GC — PSC0 v7.2 clean rebuild

**Status: GC-native compiler/protocol foundation, NOT a kernel checker.**

This is the clean-start replacement of the historical PSC2 / Lean 4.34.0
Emscripten provider. It follows the current PSC0 v7.2 compiler sources and
is pinned to stable Lean **4.35.0** at
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.

## Why a rewrite is necessary

The official Lean C++ kernel compiled using Emscripten executes inside Wasm
**linear memory**. It cannot be changed to GC-native Lean objects by enabling
a compiler flag. The previous 4.34 wasm binary is therefore explicitly
deleted, together with its vendored kernel, PSC2 compiler snapshots, native
i386 bootstrap, Emscripten patches, launcher and stale manifests.

PSC0's `backend-wasm` emits actual Wasm-GC arrays/structs for selected
portable v7.2 source. Its existing source → elaboration → canonical admissions →
**official native Lean 4.35.0 kernel check** → erasure → checked IR →
Wasm-GC backend is reused by this development package. This does **not**
mean the resulting executable itself contains the official Lean kernel.

## What is implemented in this checkpoint

- A fresh v7.2 `.lean` GC record and function probe;
- a new versioned target/Lean/assurance contract with no PSC2 inputs;
- a Node API that explicitly refuses all proof admission until the checker exists;
- a GitHub Linux CI gate that invokes the real PSC0 compiler, emits native
  Wasm-GC, checks absence of linear memory, and executes the probe under Node;
- no Emscripten dependency, vendored Lean source, C++ kernel files,
  old `wasm/` binaries, or old `source/` snapshots.

Run (GitHub Linux runner, never on local development machines):

```sh
cd psc0/v7-native
lake build pscv0_native
cd ..
node packages/pskernel-lean-wasm/scripts/verify-source.mjs
node packages/pskernel-lean-wasm/scripts/test.mjs
v7-native/.lake/build/bin/pscv0_native --check packages/pskernel-lean-wasm/src/PsKernelLeanWasmGc/Probe.lean
mkdir -p packages/pskernel-lean-wasm/dist
v7-native/.lake/build/bin/pscv0_native --emit-wasm-core packages/pskernel-lean-wasm/src/PsKernelLeanWasmGc/Probe.lean packages/pskernel-lean-wasm/dist/gc-probe
node packages/pskernel-lean-wasm/scripts/test-probe.mjs
```

The resulting `dist/gc-probe.core.wasm` is **only a test artifact**.
Do not bundle it into a VSIX as a kernel. The package remains private and
the exported `createKernel` / `checkCanonicalAdmissions` APIs report
unavailability rather than a fake acceptance or an invalid-proof verdict.

## Remaining critical work

Implement a *real* Lean 4.35.0-compatible kernel in portable Lean supported
by PSC0's GC emitter, or provide an independently qualified alternative
architecture if full native Wasm-GC implementation is impractical.
Use the current PSC0 canonical admission decoder and selected Standard
environment, not the PSC2 4.34 provider protocol. Recheck the exact
Lean assumption inventory: propext, Quot.sound, Classical.choice.
Qualify complete Lean kernel rules, dependent/inductive/mutual/quotient
behavior, prelude identity, test corpus, and native-vs-GC acceptance/rejection
parity before enabling a `ready` status. Only then build a persistent
Web Worker/VSIX API, run performance/resource gates, bundle artifacts and
consider releasing an npm package.

**No unqualified proof checking and no fallback that silently accepts proofs.**
See [ARCHITECTURE.md](ARCHITECTURE.md).
