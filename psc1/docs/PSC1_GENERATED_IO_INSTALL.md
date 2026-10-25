# Install the unpublished generated IO toolchain

Use the exact qualified artifact and SHA256 identities in the dated generated IO
receipt. The root is proofscript 0.1.0-psc1.5. Nothing here publishes to npm.
Use Node 22.23.3. Extract the complete artifact ZIP, preserving its directories.

From the directory containing the tarballs:

```sh
npm install --ignore-scripts ./proofscript-0.1.0-psc1.5.tgz
npx --no-install psc --identity
npx --no-install psc check Main.lean
npx --no-install psc compile Main.ps --engine ts
```

The root includes genuine self-hosted JS and TS executors and the official Lean
4.35.0 C++/Emscripten linear-memory Wasm kernel. No native SDK or install script is
needed. An executor selects how the compiler runs; the checked compile API still
emits JS. The explicit candidate API exposes JS/TS/Rust/Wasm output mappings with
no admission or publication authority.

Install optional compiler execution payloads explicitly:

```sh
# Compiler Wasm retains its existing GC architecture.
npm install --ignore-scripts ./proofscript-compiler-wasm-0.1.0-psc1.5.tgz
# Rust compiler execution is currently qualified for Linux x64/glibc only.
npm install --ignore-scripts ./proofscript-compiler-rust-linux-x64-0.1.0-psc1.5.tgz
# Native checking is optional; the default never silently falls back to it.
npm install --ignore-scripts ./proofscript-pskernel-lean-4.35.0.tgz
```

The separate Wasm kernel tarball is also included for direct API consumers.
Python/PHP remain optional providers in the preserved native distribution.
The root does not embed them or download unrelated tools.

Read [generated IO applications](PSC1_GENERATED_IO_APPLICATIONS.md) for explicit
IO ABI selection, public `proofscript/io` configuration and checked build examples.
Actual IO execution and transactional build publication currently require Linux;
other platforms retain explicit unsupported-ABI refusals for those operations.
Cross-platform npm metadata is not full platform release qualification. Prior
kernel five-platform evidence remains separate and unchanged.

Installed source-only packages are data: the acceptance suite loads captured,
dependency-ordered sources explicitly and never executes their JavaScript.
Automatic npm source dependency resolution is not implemented or claimed.

The [roadmap](PSC1_DEVELOPMENT_ROADMAP.md) tracks portable publication, checked
non-JS publication, final platform replay and the original 240-second selfcompile
performance target. Independent admission, strict IR and all resource limits
remain required. No merge or registry publication is authorized.
