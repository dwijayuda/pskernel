# PSCV0 v7 — Continue remaining M2+A

Read AI_WORK_STATE.md first and the linked canonical specification, architecture,
roadmap and design receipts. Work on dwijayuda/pskernel branch
psc0/pscv0-v7-native-lean-v1, preserving draft PR109 and expected-HEAD history.
GitHub connector source operations and Linux Actions only. Native portable
.lean, official Lean 4.35.0; no pskernel-core, local build, self-hosting or
compiler-source migration.

Study pinned upstream source and relevant tests before each substantial feature.
Prefer coherent shared mechanisms, minimal validation at architectural milestones,
no fabricated axioms, weakened acceptance or backend-specific semantic patches.

Latest qualified executable: fd554c4612d14ff154bced721a4ea6e5dd16df64;
Linux38463484850 passed with 359 shared observations/four panic contracts,
211 portable/221 native modules, Standard637/22/92, profile/59.
See AI_WORK_STATE for exact digests. ToFormat/Repr and selected deriving are
qualified, as are checked elementary arithmetic, ite and the genuine Nat.mod_lt
proof closure. Complete-spine WHNF and reflexivity-before-evaluation reduced
Wasm observation elaboration from 536228ms to 172ms. Full M2+A is incomplete.

Next: qualify the implemented Hashable /60 logical foundation, ordinary checked
instances/deriving, typed IR and JS/TS/Rust/GC-Wasm runtime. The strict snapshot
awaits independent native observation and source review. Unsigned conversions
and typed Canonical ABI widths are already qualified. Continue
remaining selected scalar/library APIs, comprehensive manifest and remaining M2/C5
retention. Do not stop at another small milestone or call bounded CI full M2+A.
Keep M2+A → M3+B → M4+C/D → M5/E, with recursive/indexed/dependent deriving in M3.
Wasm GC internally; linear memory only at explicit ABI boundaries.
