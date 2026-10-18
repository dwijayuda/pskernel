# Lean 4.34 → Lean 4.35.0 Wasm kernel migration: verified evidence

This document summarizes repository-owned, reproducible evidence for
`psc0/packages/pskernel-lean-wasm`. Do not confuse standalone wasm32 static
archives with a linked checker or the exploratory GC probe.

## Historical successful baseline

The old package `@proofscript/pskernel-lean-wasm` built from Lean 4.34.0
commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b` and Emscripten
6.0.9. Its `PREBUILT_WASM_MANIFEST.json` records a 2,177,471-byte Wasm
binary with SHA-256
`ca6bbb58ea5bafe2d5fbc9fa0fce083933ae0dd5e06a2cbe475077b7d71e9428`
and a 69,410-byte Emscripten Node launcher.

The retained history
`psc15selfhost/docs/continuity/WASM_FULL_COMPILER_ADMISSION_2026-10-02.md`
records a *real* 9,891,566-byte, 1,205-admission compiler payload accepted
by the old Lean 4.34 Wasm kernel in 14,679 ms, and a deliberately invalid
1,204th admission rejected as a kernel type mismatch. This was a runtime
conformance check, not independent mathematical proof of correctness.

## Build strategy preserved

1. Fetch and verify the exact Lean source commit.
2. Use a native i386 stage0 Lean compiler (`-m32 -msse2 -mfpmath=sse`) for
   wasm32-compatible scalar literals, oleans and generated C.
3. Cross-build wasm32 stage1 Lean Init/Std/Lean libraries using Emscripten.
4. Link the official Lean C++ runtime/kernel archives plus **current PSC0**
   canonical admission decoder and Standard environment.
5. Run actual Node/Emscripten `--health`, accept, reject, malformed-input,
   and native-versus-Wasm comparison tests.
6. Commit only same-source-commit bytes guarded by digest and transport checks.

All upstream compatibility edits are exact, pinned and fail closed, rather
than patching a released Wasm binary or performing unchecked proof admission.

## New Lean 4.35.0 evidence

- Official Lean pinned commit
  `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
- `src/kernel` file inventory unchanged at 37 entries, with differences
  in `type_checker.cpp` and `environment.cpp`. Native semantic parity
  must therefore use 4.35.0, not 4.34.0.
- GitHub Actions [#39129247395](https://github.com/dwijayuda/pskernel/actions/runs/39129247395):
  actual Emscripten 6.0.9 wasm32 `libleanrt.a` and `libleancpp_1.a`
  successfully compiled, including Lean 4.35 `type_checker.cpp`.
- [#39128469062](https://github.com/dwijayuda/pskernel/actions/runs/39128469062):
  static audit verified 149 C++ exported signatures in eight libuv
  interface/implementation pairs after pinned compatibility rewriting.
- [#39121931430](https://github.com/dwijayuda/pskernel/actions/runs/39121931430):
  128 live PSC0 provider-source modules resolved without PSC2 snapshots.
- [#39122290519](https://github.com/dwijayuda/pskernel/actions/runs/39122290519):
  full cross-build reached `leanrt` and failed on no-libuv fallback
  `lean_uv_os_get_group` argument signature; corrected in commit
  `6713d423e3a498b1c2ab5b4085e71fd4e15c58bb`.
- [#39128818265](https://github.com/dwijayuda/pskernel/actions/runs/39128818265):
  native Lean 4.35 admission executable built 259/259 jobs; the test
  harness itself failed at an undefined JavaScript fixture `v` before
  actually checking admissions. This is a harness defect, **not** a Lean
  proof-checking regression.

## Publication and assurance policy

Every executable, including the native standalone oracle, must verify the
exact Lean commit, C++ kernel identity and PSC0 v7.2 protocol.

The 11-case shared corpus exercises good definitions, ill-typed bodies,
malformed requests, protocol violations, duplicate declarations, missing
constants, theorem and opaque declaration rejection, and refusal of axiom
injection. Both native and Wasm must agree. Corpus and artifact hashes are
bound to the same-source qualification receipt.

A successful linked kernel with 11 passing cases earns an
`admission-smoke` development qualification only. It **does not** earn
`productionReady:true`; broader current PSC0 Standard, large compiler
workloads, resource-limit behavior and compatibility tests remain required.
The host must fail closed for all missing, altered or mismatched binaries.

This package uses WebAssembly **linear memory**, not Wasm GC. The VSIX
integration and the unrelated active PSC0 compiler development lane are
deliberately out of scope.
