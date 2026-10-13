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

Last qualified executable: `35e239193e69cc466b81ac57282df1b1500f4927`;
[green 38433276797](https://github.com/dwijayuda/pskernel/actions/runs/38433276797).
293 shared runtime observations, four panic contracts, 188 portable/196 native
modules, profile /51. Standard 308/18/54:
FNV `fnv1a64:1901246055571366448`;
SHA `sha256:799539fdf6557760d1c9134439ac6ea811915c7c6b054164310c11aa3e017136`.

Latest qualified changes: shared postponed source/Core/expected-term work,
indexed instance lookup, genuine OfNat and direct Coe/CoeFun/CoeSort,
type-only field erasure, explicit instance-search transparency and
module-preserved reducibility. Flexible inference retains original checked
types before delta reduction. Reference/native audits and all backend gates
passed. Full M2+A and v7 remain incomplete.

Current new implementation is checked character/string quoting, needed by Repr:
read [its design/status](docs/PSCV0_A_STRING_QUOTING_2026-10-13.md), inspect live
source/run, finish strict digest review and cross-target qualification.
Then continue faithful Std.Format/Repr, UInt64/mixHash/Hashable, remaining
selected scalar/library APIs, the comprehensive manifest and C5 semantic
retention. Keep indexed/dependent/recursive deriving with M3's general machinery.

Understand each subsystem and its invariants before editing. Implement coherent
features, validate at architectural boundaries, fix shared causes, remove obsolete
workarounds and update current status with exact-source evidence. No fabricated
proofs, opaque substitutes for missing semantics, unsafe IR casts or changed
acceptance criteria. Do not stop simply to report a smaller checkpoint.
