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

Executable `0c6b7ee6896524b69858d3524356d7a30a4c7272`;
[green Linux 38437704653](https://github.com/dwijayuda/pskernel/actions/runs/38437704653).
**298 shared runtime observations**, four panic contracts, **189 portable /
197 native modules**, profile `pscv0-v7-native-bounded/53`.
Official **Lean 4.35.0** at `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`;
independent oracle, semantic/refusal and graph gates, strict IR,
JS/TS/Rust, V8/Wasmtime GC, WIT/WAT/component/ABI, project and performance gates passed.

Standard: **313 declarations /18 classes /54 instances**, canonical v2:
FNV `fnv1a64:723655421381520752`;
SHA `sha256:41b2e17bbe8468c04e69a11df63e1656603e88ecd67b9965ffcc3e2953769e8e`.
Character and Unicode string quoting use five checked definitions and existing
scalar/string operations; no added axiom or primitive. Quoting is independently
compared through native evaluation because upstream String.Internal.append
is kernel-opaque. Historical RC4 receipts retain their original identities.

Full M2+A is **not complete**. Next: checked Int constructors/recursor/toNat
with typed runtime conversion, then faithful Std.Format/Repr and remaining A/M2.


Finish the checked Int conversion qualification/digest review; read its design
and live CI. Then continue faithful Std.Format/Repr, UInt64/mixHash/Hashable,
remaining selected scalar/library APIs, the comprehensive manifest and C5
semantic retention. Keep indexed/dependent/recursive deriving with M3's general
machinery. The remaining A–E exits are unchanged.

Understand each subsystem and its invariants before editing. Implement coherent
features, validate at architectural boundaries, fix shared causes, remove obsolete
workarounds and update current status with exact-source evidence. No fabricated
proofs, opaque substitutes for missing semantics, unsafe IR casts or changed
acceptance criteria. Do not stop simply to report a smaller checkpoint.
