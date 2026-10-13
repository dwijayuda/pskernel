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

Latest qualified executable: e565bbe6bab75baf4fa511640e1f82744f400032;
Linux38451656694 passed with 341 shared observations/four panic contracts,
204 portable/212 native modules, Standard460/22/88, profile/56.
See AI_WORK_STATE for exact digests. ToFormat/Repr and selected deriving are
qualified; full M2+A is incomplete.

Next: inspect the native-only StandardClosure audit output for Nat.mod_lt,
BitVec/UInt64, mixHash/String.hash and Float/scientific. Choose the smallest
correct checked logical-library closure. Existing portable names are collisions,
not compatible imports. Implement the real UInt64 foundation then Hashable,
remaining selected scalar/library APIs, comprehensive manifest and remaining M2/C5
retention. Do not stop at another small milestone or call bounded CI full M2+A.
Keep M2+A → M3+B → M4+C/D → M5/E, with recursive/indexed/dependent deriving in M3.
Wasm GC internally; linear memory only at explicit ABI boundaries.
