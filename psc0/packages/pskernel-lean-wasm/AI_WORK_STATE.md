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
