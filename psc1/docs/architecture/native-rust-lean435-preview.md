# Native Rust PSC1 + official Lean 4.35 native checker: scoped developer preview

Branch: `feat/psc1-native-rust-lean435-20261031`, stacked on PR #216.
This builds a **genuine generated Rust-native G1 compiler** from the current source
closure and pairs it with the **actual official Lean 4.35 native checker** through
the unchanged PSC1 checked host. Node 22 is retained as the trusted transport,
strict IR/target consumer and transactional publication orchestration. The compiler
and kernel are native binaries; this is **not** yet an entirely Node-free CLI.

## Linux Actions build

`.github/workflows/psc1-native-rust-lean435.yml` uses the pinned official
Lean 4.35 toolchain and Rust 1.90, validates the complete owned Rust unified
source closure, builds `psc1_unified_service_seed` and
`psc1_independent_checker`, then invokes the existing

```sh
node scripts/generated-target-qualification.mjs rust --g1-only performance-240s unified
```

This emits a genuine native binary in
`dist/generated-unified-rust-compiler/G1-service/service.bin`, verified via
`artifact.json` and the successful `qualification.json`. The existing
G1 test matrix executes the four JS/TS/Rust/Wasm outputs and refusals, with
independent native Lean admission and strict IR checks.

Once G1 has passed, exercise a small checked application:

```sh
node scripts/native-psc-preview.mjs compile Main.ps
node scripts/native-psc-preview.mjs build Main.ps dist/native-app
```

The preview currently emits **JS only**, to retain the exact checked-target
consumer and avoid introducing SDKs into the developer path. It supports source
file `.ps` and the supported `.lean` subset. Compilation invokes the Rust
binary with exact SHA-256 identity via the existing bounded Rust guard, and the
official Lean native checker executable. Then it reuses the unchanged
`createGeneratedJsCompilerSession` for source/IR/origin binding, fresh independent
admission, JS syntax and public-API checks, and transactional publication.
No source, request, or wire data supplies a trusted executable path.

CI measures cold, isolated CLI calls for both grammars, captures compiler and
kernel phase times, verifies actual JS syntax, rejects invalid typed source,
and checks preservation of the prior publication after an invalid build.
All results are written to `dist/native-psc-preview/qualification.json`.

## Trust and release boundaries

- **G1 only:** no current-source Rust G2/G3/fixed-point or 240-second full
  self-compilation performance result is claimed.
- This is a distinct producer from the current 134-unit modular JS/TS release
  cohort. The new Rust binary is not silently substituted into the npm root.
- Official Lean 4.35.0 commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`
  is unchanged; no custom kernel or unchecked `sorry` is introduced.
- No cache of proof admissions, no resource/fuel increase, no node removal claim,
  no npm publication, no merge into `main`.
- For fast development, the Rust executable uses the existing measured
  `opt-level=0` / 256 codegen units build policy. A higher Rust optimization
  level previously exceeded the four-minute build budget. Compare compile
  + execute time before changing this production choice.
- The first priority after this G1 benchmark is profiling current-source Rust
  G2 and reusable immutable module/IR work; only a newly qualified matching
  Rust G2/G3 can enter the current distributed root.

This file is a development plan and does not itself imply the workflow passed.
The Actions result and checked artifact receipt are the qualification authority.
