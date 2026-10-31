# PSC1 AI work state

Updated 2026-10-31 Asia/Jakarta. Active work: Windows-native compiler + native kernel, installable native npm packages, requested by the user. Branch `feat/psc1-native-npm-windows-20261031` starts at exactly `297081f852d7f16facc1300922d0f353c14ec3ef` (PR217 native Linux delivery).

Connected GitHub and Linux Actions only. Preserve expected-HEAD single-parent non-force history, fuel4096, fresh admission, strict IR and existing request deadlines. No main merge or npm registry publication.

## Last completed milestone (unchanged)

Rust G1 and native Lean checked preview passed [41177075940](https://github.com/dwijayuda/pskernel/actions/runs/41177075940), job124466784147, at `a3013ea35c48fde083f9efa0a8a4a963e6a3fcb5`. The133-module compiler source digest is `67ce17c1a92b893af8ce7bb915a64164236cedd31ed256f7952fc95dc52565ad`. Native Rust G2/G3 is NOT qualified by G1.

Native Linux delivery passed [41179915274](https://github.com/dwijayuda/pskernel/actions/runs/41179915274), job124475029582, artifact13034039084, tested implementation `2d4edd272577f2b44a3fde41b1a0b927b822e413`. The inner archive SHA256 is `7637b93e42cf297056f92bf9d0f8f3d37e846be8f7f855e08b11cac489695c7d`. Tiny-program paired median1505.64->1308.45ms,13.1% reduction; not full-self-build or Rust-vs-JS evidence. Original details, source/runtime pin identities, negative tests, and prior history are preserved byte-for-byte in [the previous work state](docs/history/AI_WORK_STATE_BEFORE_NATIVE_NPM_WINDOWS_2026-10-31.md).

## Current implementation — qualification pending

See [native npm work record](docs/PSC1_NATIVE_NPM_WINDOWS_WORK_STATE.md).

The new Ubuntu workflow reuses exact admitted Rust G1 `main.rs`/Cargo inputs, cross-compiles Windows x64 with Rust1.90.0/MinGW and the existing opt0/256-codegen-unit policy, and reuses the actual qualified Lean4.35 native package. No compiler or kernel source semantics are changed.

Windows transport uses a compiled Job Object supervisor with kill-on-close, parent PID/creation-time binding, assignment before resume and240-second deadlines. The existing Linux transport remains unchanged. Windows publication uses existing portable-atomic rather than Linux-only durability mechanisms.

The root `proofscript@0.1.0-psc1-native.1` npm tarball bundles platform-specific `@proofscript/compiler-rust-linux-x64`, `@proofscript/compiler-rust-win32-x64` and original `@proofscript/pskernel-lean@4.35.0`. Separate tarballs are also emitted. No installation-time SDKs, builds, downloads or registry accesses are intended. Real offline local/global npm installs and actual psc shims must pass before delivery is called qualified.

All builds and tests use Linux Actions. Windows compatibility tests run genuine Windows Node/npm and native Windows executables under Wine. A Wine pass must NEVER be presented as native Windows-host qualification. Tests cover both grammars, five actual corpus programs with exact source/IR/admission identity,14 kernel fixtures, damaged payload rejection, failed-publication retention and Windows process-tree cancellation.

No successful Windows build/install result is claimed until the new workflow's exact-commit reports complete. The last qualified Linux delivery remains available separately.

## Scope and next work

Compiler and kernel are native, but Node remains the trusted checked host. This npm preview exposes checked JS output only. Native G2/G3, full-self-compilation latency, four-minute performance acceptance, Node-free CLI, broader output SDK consumers and real Windows-host testing remain separate work.

The modular JS/TS .10 universal distribution, default Wasm kernel, seven output backends, optional Python/PHP, compiler source, kernel source and resource/fuel policies remain unchanged. PSKernel-Min remains independent research. Do not transfer CI success between these distinct source/package/environment identities.
