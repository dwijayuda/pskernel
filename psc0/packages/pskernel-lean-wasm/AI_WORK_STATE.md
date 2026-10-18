# PSKernel-Lean-Wasm-GC work state

Base: `psc0/pscv0-v7-native-lean-v1`, SHA
`5785ada4d0521eaa910a57adc8569dbe95d4c5fe`.
Work branch: `feature/psc0-v72-pskernel-lean-wasm-gc-v1`.

Lean: 4.35.0 `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
Language: PSCV0 v7.2.
Target: genuine PSC0 Wasm-GC core (no linear memory).
Source of kernel admission authority: official native Lean kernel.

New source-stage deliverables: clean package tree replacing legacy
PSC2 4.34 Emscripten provider, portable GC probe, fail-closed host API,
Linux source/GC runtime qualification workflow, and precise trust disclosure.

P0 source changes are not runtime qualification.
P1 GC build/execute is a prerequisite but not a functioning Lean kernel.
P2/P3 Lean kernel compatibility and native-vs-GC proof parity are OPEN.
P4 VSIX integration is OPEN and MUST NOT bundle probe as checker.

Avoid touching ongoing M3+B work or original PR109. Use GitHub Linux CI
for all builds/tests. No Desktop Commander, local builds or force pushes.

Binary distribution (pending CI): stage and hash a real PSC0-emitted
`wasm/gc-probe.core.wasm` into Git via a successful, same-SHA cloud CI
job only. The binary must remain explicitly named PROBE, not KERNEL.
