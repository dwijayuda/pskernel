# @proofscript/pskernel-lean-wasm — Lean 4.35.0 / PSC0 v7.2

**Implementation target:** full official Lean C++ proof kernel in WebAssembly
**linear memory** (not WebAssembly GC).

**Qualification:** pending successful cross-build and runtime tests. Do not
confuse build scripts, a GC test binary or a native-only source check with a
qualified `wasm/pskernel-lean.wasm` checker.

This package intentionally *replaces* the historical PSC2 4.34 provider and
the exploratory `pskernel-lean-wasm-gc` probe. It targets **current PSC0**:
the provider decoder `PsKernelLean.Protocol`, selected Standard prelude, and
the ordinary canonical-admissions v2 bridge; it does not copy PSC0 sources.

The `src/PsKernelLeanWasm/Main.lean` executable checks all user declarations
with Lean's official `Kernel.Environment.addDeclCore`, not an alternative
implementation. The only shipped binary, once CI qualifies one, is built from
upstream Lean 4.35.0 sources and Emscripten 6.0.9.

## API

```js
import {createKernel, checkCanonicalAdmissions, kernelStatus} from
  '@proofscript/pskernel-lean-wasm';

if (!kernelStatus().checkerReady) throw new Error('kernel not qualified');
const checker = await createKernel();
const result = await checker.checkCanonicalAdmissions(canonicalAdmissionsJson);
if (!result.accepted) console.error(result.errorKind, result.message);
```

The Node API verifies SHA-256 and provider identity on every request. It fails
closed with `KernelNotReadyError` until `PREBUILT_WASM_MANIFEST.json` and
corresponding exact binary are present. A missing kernel is **not** a rejected
proof. This package does not add a fallback checker.

## Build and artifacts

See [BUILDING.md](BUILDING.md) for GitHub Linux commands, toolchain pins, the
i386/wasm32 bootstrap, and CI provenance. The expected generated files are:

```text
wasm/pskernel-lean.cjs
wasm/pskernel-lean.wasm
PREBUILT_WASM_MANIFEST.json
```

No VSIX integration or browser worker is part of this branch. Executable
conformance and integrity qualification are required before claiming readiness.

## Qualification levels

A cryptographically matched `admission-smoke` manifest may enable a **development** checker after the exact 11-case native-vs-Wasm parity suite passes. `kernelStatus().productionReady` remains `false`; this does **not** establish complete Lean 4.35 kernel parity, PSC0 v7.2 backend equivalence, or general production readiness. Treat `KernelNotReadyError` as transport/build unavailability, never as a semantic rejection. The larger current Standard and Lean Arena suites remain required for production promotion.

## Upstream source licensing

The official Lean C++ kernel/runtime incorporated into the Wasm executable derives from `leanprover/lean4` at the pinned 4.35.0 commit and is licensed Apache-2.0. `LEAN_LICENSE` retains the upstream license text. The top-level package's `UNLICENSED` designation does not override the license of the Lean-derived portions of the binary. See `MIGRATION_EVIDENCE_4_34_TO_4_35.md` for source and CI provenance.
