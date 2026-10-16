# M2+A platform ABI signature qualification

## Observed failure, not a compiler diagnosis

Native run38823906652 at implementation3405c32a7a0fdadb930b8f72c8c95f7ff7c31f53 completed FAILURE. Compilation, all preceding frozen logical assets, checked source/Standard and three-module emission passed. GC/component qualification reached explicit32-bit WIT emission and stopped at `psc0-native-platform.mjs:30`: the assertion expected `echo-unsigned: func(value: u32) -> u32`, but actual valid WIT contained `export %echo-unsigned: func(%value: u32) -> u32;`. Subsequent execution/performance gates were skipped. This was not a missing `checkToIS` export and not an observed width-value mismatch.

The read-only cloud diagnostic at commit0ee750ee71e5264cc1fa53c3b878a8689a588d3c/run38827243885/job116737445701 extracted the exact assertion and generated signature from the original completed job. It changes no compiler or qualification gate. Original native logs are large; use the compact diagnostic rather than repeatedly importing generated-source dumps into a chat.

## Authoritative reference and correction

The Component Model WIT specification explicitly permits both bare and percent-prefixed identifiers, including parameters. See https://github.com/WebAssembly/component-model/blob/main/design/mvp/WIT.md#WIT-Identifiers (inspected16 October2026). The pinned qualification tool remains wasm-tools1.261.0; its existing parse/reprint step accepts the emitted WIT. Lean semantics are not changed by this harness-only correction; compiler source remains native `.lean` pinned to Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc.

Reuse the existing scalar `exportsOf` normalization after wasm-tools parses/reprints the WIT. Require the exact tuples `(echo-unsigned, value:u32/u64, u32/u64)` and `(echo-signed, value:s32/s64, s32/s64)` for their respective profiles, instead of asserting incidental text spelling. The pre-existing complete WIT-vs-binary export-signature comparison is unchanged. No general WIT parser is introduced; this is the existing scalar-fixture projection over tool-validated WIT.

This retains required export names, argument count/name/type, signedness, target width and return type. Missing exports, swapped signedness, wrong widths or extra arguments still fail. Existing V8/Wasmtime Boolean observations, boundary echoes, WAT/binary round trips, memory checks and all later native gates remain unchanged. No extra test corpus or changed expected runtime result is needed.

## Qualification boundary

The correction requires a fresh native run; this document does not declare it passed. Independent F3/F4/platform38823906736 already passed implementation3405c32a; the harness fix does not alter those logical assets. M2+A remains OPEN until complete research qualification, exit reconciliation, history-preserving integration and exact-integration qualification. See the exit review and both handoffs.
