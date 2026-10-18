# Linear-memory PSKernel-Lean-Wasm work state

Branch: feature/psc0-v72-pskernel-lean-wasm-linear-v1
Base: psc0/pscv0-v7-native-lean-v1 at
33676076bcda7b0de5ec1f9803f49b8b1d28a058
Lean: 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc
Language: PSCV0 v7.2.
Kernel: official Lean C++ via Emscripten, wasm32 **linear memory**.
Compiler: current native PSC0 packages. No duplicated PSC2 source.
Previous wasm-gc experiment remains preserved on separate branch.
No VSIX work.

Checkpoint: Clean source/build/host integration candidate.
Not qualified until real Linux cloud build, positive/negative differential
kernel checks, and byte-identical checked prebuilt manifest are green.
Wasm runtime and independent kernel equivalence must not be inferred from
successful source or host-only tests.

Immediate next: inspect workflow execution, repair verified toolchain/ABI
failures without bypassing any check, stage actual Lean 4.35 Wasm bytes.
Then expand conformance to full Standard and Lean Arena; benchmark startup,
memory, real declaration workload. Never publish an unchecked artifact.

## 2026-10-18: Stage1 wasm32 runtime blocker

CI #39122290519: source closure, Elan, Emscripten, i386 bootstrap and stage1 libc/uv progressed; compilation failed at `src/runtime/uv/system.cpp` no-libuv `lean_uv_os_get_group` signature mismatch against its header. This is the *first real* C++ stage1 error, not a parity failure. The exact narrow fallback signature fix and an early upstream-runtime source preflight have been prepared. The complete wasm kernel remains unbuilt and unqualified until Linux CI plus native/Wasm differential tests pass. No VSIX work.

## 2026-10-19: Four-hour cross-build anomaly — confirmed size comparison

- The still-running full GitHub CI #39128012190 began at 2026-10-18 12:36:48 UTC. Its combined Emscripten/full-kernel build step provides no downloadable in-progress job log via the connected GitHub API. Runner timeout is 360 minutes. A long elapsed time does not prove a deadlock.
- Three old genuine Lean 4.34 end-to-end Wasm build CI runs (#36933019836, #36931145518, #36933643176) took approximately 41, 47, and 52 minutes total, including genuine positive and negative admission tests.
- Old source-snapshot environment: 7 Lean files, 51,649 bytes; old source closure: 19 explicit provider modules. Source checkpoint 1b21b2483df7e8de7542873c24eaff2501539b1b.
- Current PSC0 environment: 101 Lean files, 23,654,198 bytes; dynamic import closure: 128 modules. This directory has roughly 458x the old source bytes. Its largest files are StandardFloatOperationsData.lean (11,179,796 bytes) and StandardUnsignedOperationsData.lean (6,457,592 bytes). This does not imply CPU cost scales linearly.
- The new full build performs native i386 Lean C emission for all 128 modules, followed by sequential -O3 Emscripten compilation of each C file. Very large generated C/data translation units are a plausible bottleneck, but the exact stalled stage is not yet verified.
- Independent GitHub CI #39129247395 successfully compiled Lean 4.35 official C++ kernel and runtime into wasm32 archives. C++ kernel compilation feasibility is confirmed.
- This cache branch now prints UTC BEGIN/PASS/FAIL and elapsed seconds for the bootstrap, stage1, every Lean-to-C module, every C-to-Wasm module and final link. Generated C bytes are reported. No proof checker, compiler optimization, or kernel policy is changed. GitHub fast validation CI #39150066365 passed.

Next: preserve the 360-minute job log, identify the exact slow module or stalled stage, use cryptographically verified stage1 caching, and optimize large source compilation only under identical native/Wasm kernel admission tests. Do not stage an unqualified binary or touch VSIX.
