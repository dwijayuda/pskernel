# Native direct Wasm implementation

C3 checkpoint under development; qualification is pending. C4/C4b are not
complete. The approved architecture remains PSCV0_DIRECT_JS_WASM_ARCHITECTURE.md.

The native v7 pipeline retains official Lean checking and complete runtime-IR
admission. The new backend reuses PsWasmModule, the existing portable binary
encoder, and independent structural/stack typing. Source lowering, WAT layout,
foreign-interface planning and component wiring are separate modules. Binary
and readable WAT serialize the same retained target module. WIT and canonical
lifts derive from one explicit interface plan.

The C3 source profile admits scalar Bool/Char/Unit computation; unsupported
bigints, aggregates, closures, imports and generic computation fail closed.
The component profile exposes Bool/Char parameters and results, or a void Unit
result, with at most 16 flat parameters. Retained Unit/proof parameter slots are
not a safe foreign API. The JSON export manifest explicitly selects semantic
declaration names. The CLI emits all files only after planning succeeds:

- --emit-wasm-core application.ps output-stem
- --emit-wasm application.ps output-stem exports.json

The component bundle includes .wit, readable .wat, direct .wasm, plus standalone
.core.wat/.core.wasm. The companion manifest identifies core/component target
and bounded capability profile. The C3 component subset requires no linear
memory because every admitted foreign parameter/result is scalar.

Qualification pins: Node 22.23.3 (V8 recorded at execution), Wasmtime 49.0.2
(Cranelift), wasm-tools 1.261.0. Downloaded validator/engine release archives
are SHA-256 checked. Production emission invokes none of them.
Core reference: WebAssembly/spec 7e9fb78c63d65018cc111422f657947b3df80d7b.
Component reference: WebAssembly/component-model
6c48079bbc808bb3bdeb9554f338ab3a5b187388, synchronous binary version 0x0d.
Only selected GC/function-reference and synchronous canonical scalar features
are admitted; proposed GC-native Canonical ABI is not required.

One executed GC allocation/read inside a canonically lifted component is the
early compatibility gate. Independent tools validate binaries, reassemble WAT,
compare stripped core bytes, parse WIT and compare extracted scalar contracts.
Both core engines execute the compact scalar case. This is not C4's 142-case
runtime parity claim or C4b's aggregate/lifetime qualification.

The repository's older Wasm runtime/lowering is not in this new native closure:
it represents Nat as one GC node per bit and relies on an older specialization
and validation boundary. C4 will retain useful algorithms while implementing
the planned limb-array representation and clean lowering responsibilities.
No compiler .ps translation, pskernel-core, local build or self-hosting is used.
