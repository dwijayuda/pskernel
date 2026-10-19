# PSC1 native DirectJS, Rust and Wasm — qualified checkpoint

Date: 2026-10-20 (Asia/Jakarta). Development branch: `psc1/direct-multibackend-v1`.

## Exact evidence and independent scope

- Latest **qualified executable/test commit**: `0fe083959474b231450b379a5ca4cff9063e80d3`.
- [PSC1 Linux multi-backend run #39313057156](https://github.com/dwijayuda/pskernel/actions/runs/39313057156): **SUCCESS** (backend libraries, PSC1 Lean CLI, executable multi-backend artifact smoke). This is not a complete language conformance/proof-of-preservation result.
- Earlier accepted components: [run #39311486346](https://github.com/dwijayuda/pskernel/actions/runs/39311486346), [actual Wasmtime component execution #39311904887](https://github.com/dwijayuda/pskernel/actions/runs/39311904887), [component Boolean parameter and both source grammar cases #39312354188](https://github.com/dwijayuda/pskernel/actions/runs/39312354188).
- Branch descends from main `7d3e220e495f5d82178a3e66f191255045862bd5`, with original PSC1 snapshot from historical PSC0 commit `5a9c0a42a3ab28e3e0607242c4efcc3aab629a4c`.
- Source and compilation remain on **Lean 4.34.0**, separate from PSC0 v7.2's Lean 4.35.0. The old PSC1 source grammar is not silently renamed or promoted to full v7.2.

## What works in the qualified subset

1. Native Lean CLI: `lake exe psc1 build Main.ps --target js --out Main.js` emits **`.js`, `.d.ts`, `.js.map` directly** (not TypeScript-transpiled JS). Node executes the emitted checked-IR program. Source-map v3 segments refer to original entry-source declaration spans, with actual final printed JS coordinates and UTF-16 source columns; Unicode/surrogate-pair offset test passes.
2. `lake exe psc1 build Main.ps --target rust --out Main.rs` emits Rust from shared IR. The qualified sample builds with Cargo and **num-bigint = 0.4.6** and **num-traits = 0.2.19**, then its exported `idNat` executes correctly. `Cargo.toml` auto-emission is not implemented.
3. `lake exe psc1 build Main.ps --target wasm-core --out Main.wasm` emits a **real WebAssembly GC core binary**, validated and instantiated by Node. `lake exe psc1 wat Main.wasm --out Main.wat` prints actual binary text with SHA-pinned wasm-tools rather than trying the incompatible WABT GC decoder. `wasm-tools parse` roundtrip passes.
4. `lake exe psc1 build Main.ps --target wasm-component --export answer --out Main.wasm` emits the validated **component** `Main.wasm`, text `Main.wat`, WIT `Main.wit`, and underlying `Main.core.wasm`/`Main.core.wat`. The host derives a single explicit entry-source export's interface from typed IR; `wasm-tools component embed/new/validate/print/wit` connects the WIT and binary. **Wasmtime 49.0.4** invokes `answer()` and `idbool(true)`/`idbool(false)` correctly.
5. Refusals: an ill-typed source cannot publish DirectJS, unsupported unbounded `Nat` cannot be exposed as a WIT scalar, and an unknown or non-entry export cannot publish a component. Emission is staged and validated before official files are moved into place; filesystem commit across multiple paths is not crash-atomic.

## Toolchain and implementation

- `.wat` is obtained from the final binary with Bytecode Alliance `wasm-tools 1.254.0`, Linux SHA256 `d0efb16c9c859137b7ab3e99151c299cd47caee106ed4594561002f7a04945bd`.
- Wasmtime CLI `v49.0.4` Linux SHA256 `6561abd54bdf941b6519cce883e0857cc9bce94d92c65287ed838d895a27f5a9`.
- `psc1/packages/compiler-ir/src/Ps/CompilerIr/Validate.lean` provides a *bounded type/IR check*, not independent kernel certification.
- `psc1/host/src/Ps/Host/DirectBackend.lean` owns JS/Rust/Wasm-core output, `DirectSourceMap.lean` owns source positions; `WasmComponent.lean` owns selected WIT/component emission and staging. `psc1/packages/cli/src/Main.lean` is the tested Lean CLI. The npm-side `psc1/npm-cli/psc.js` still uses the historical TypeScript-mediated path.
- The bootstrap composition remains compiler-only. Backend libraries are optional independent Lake libraries and do not become part of the fixed-point closure.

## Explicit limitations and remaining work

- Native PSC1 CLI's admission-ready/typed IR path is **not** equivalent to a fresh, independent PSKernel provider admission; no global kernel soundness, erasure, specialization, or backend-preservation theorem is claimed. Preserve fail-closed unsupported-refusal behavior. Before verified/release publication, wire a real checked-module authority and cross-backend soundness/conformance gates.
- DirectJS declarations are restricted to representable scalar public signatures; data-type API declarations, generic result/type signatures, and original source expression-level mapping are not complete. Multi-file source origins and module graph mapping are not yet qualified.
- WIT is **one explicit entry-source function export**, restricted to the recognized fixed-width scalar/Bool type family; Boolean signatures are the currently executed end-to-end component subset. Dependent/generic/function/recursive values, `Nat`, `Int`, `String`, canonical aggregate adapters, resource ownership and multi-export projects require explicit further work.
- Core Wasm GC values must not be mistaken for stable JS numeric ABI values. Component adapters use only explicitly selected scalar boundaries. All C0–C4b PSC0 backend conformance receipts are separate from PSC1 receipts.
- Full source language v7.2, multi-backend semantic parity over the entire Core Standard, stable npm packaging, deterministic versioned artifacts, atomic multi-file publication, full project/module imports, self-host, and target runtime preservation are **not finished**.

## Priority continuation

1. Expand same-source positive/refusal/runtime fixtures (types, recursion, records, closures and imports) across DirectJS/Rust/CoreWasm/component, maintaining one accepted source/IR graph.
2. Integrate a real independent checked-module kernel admission authority before treating PSC1 outputs as verified production executables.
3. Define the public API / target names / Canonical ABI independently of core semantics; add safe multi-export WIT, tested aggregates and real memory/ownership layouts.
4. Complete DirectJS `.d.ts` aggregate/generic declarations, fine-grained source maps and multi-module resolution with exhaustive target diagnostics.
5. Wire public npm CLI/distribution to the qualified native backend source and CI gates; keep TypeScript 7 as an explicit alternate backend, never as silent DirectJS fallback. Self-host remains last.

GitHub/cloud Linux only. Refresh HEAD, preserve unrelated PSC0/main, use non-force expected-head writes. Do not infer correctness from a passing build alone.
