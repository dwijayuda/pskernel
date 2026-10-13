# PSCV0 v7 — Complete remaining M2+A

## Pinned Lean reference rule (14 October 2026)

Current pin: **Lean 4.35.0**, `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
[Migration and source comparison](docs/PSCV0_LEAN_435_PIN_2026-10-14.md).
Before any feature design, implementation or redesign, study the corresponding
official implementation and relevant tests at this pin. Record algorithms,
data structures, semantics, invariants, optimizations and the comparison with
PSC0; justify simplifications and validate against Lean where applicable.
Retain licensing/attribution when adapting code. This applies to M0–M5,
A–E, C5 and all future development; do not preserve obsolete internals merely
for compatibility.


Continue autonomously until M2+A is completed. Keep the compiler native,
portable `.lean`, clean and extensible. Minimal meaningful tests; no
pskernel-core, self-hosting or compiler-source `.ps` migration.

Read [current work state](AI_WORK_STATE.md), [canonical v7](PSCV0_LANGUAGE_REFERENCE.md),
[architecture](docs/PSCV0_NATIVE_LEAN_GRADE_ARCHITECTURE_REDESIGN_V1.md),
[roadmap/exit gates](docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md) and
[readable-output audit](docs/PSCV0_READABLE_OUTPUT_AUDIT_2026-10-13.md).
Follow **M2+A → M3+B → M4+C/D → M5/E**. Do not add another milestone track,
repeat qualified work or weaken the full M2+A exit gate.

Verify live GitHub HEAD and CI on `dwijayuda/pskernel`,
`psc0/pscv0-v7-native-lean-v1`, existing draft PR109. Use connector source
operations, expected-HEAD non-force pushes and Linux Actions only. No local
checkout/build/desktop automation. Preserve Wasm GC internally and ABI-only
linear memory.

Latest qualified executable and evidence

Executable `a2bcf0375c5f9acfa0d50847d44253657d5cd3cd`;
[green Linux 38443246672](https://github.com/dwijayuda/pskernel/actions/runs/38443246672).
**313 shared runtime observations**, four panic contracts, **198 portable /
206 native modules**, profile `pscv0-v7-native-bounded/55`.
Official **Lean 4.35.0** at `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`;
independent oracle, official kernel, semantic/refusal and graph gates, strict IR,
JS/TS/Rust, V8/Wasmtime GC, WIT/WAT/component/ABI, project and existing performance
gates passed. These measurements do not establish performance parity.

Standard: **394 declarations /18 classes /54 instances**, canonical v2:
FNV `fnv1a64:17804548636281664114`;
SHA `sha256:ec394b9e9c70bf92cb829060fcfee1e36aaf38f1f5e92b198a646c553ff259b1`.
The pure Std.Format algebra, measurement and renderer are ordinary checked
definitions over the shared IR, including hard-line/fill behavior, Unicode
columns, signed nesting, alignment and initial column. No formatting axiom,
backend formatter or new runtime primitive. WAT constructor discriminator names
are allocated separately from payload fields; physical indices are unchanged.

Quoting and checked Int.toNat remain qualified. Quoting comparisons use native
evaluation because upstream String.Internal.append is kernel-opaque; they are
not kernel equality proofs. Int runtime conversion preserves arbitrary precision.
Historical RC4 receipts retain their original identities.

Full M2+A is **not complete**. Next: ToFormat/Repr and remaining A/M2.


Pure Format is qualified. Continue ToFormat/Repr, UInt64/mixHash/Hashable,
remaining selected scalar/library APIs, the comprehensive manifest and C5
semantic retention. Keep indexed/dependent/recursive deriving with M3's general
machinery. The remaining A–E exits are unchanged.

Understand each subsystem and its invariants before editing. Implement coherent
features, validate at architectural boundaries, fix shared causes, remove obsolete
workarounds and update current status with exact-source evidence. No fabricated
proofs, opaque substitutes for missing semantics, unsafe IR casts or changed
acceptance criteria. Do not stop simply to report a smaller checkpoint.
