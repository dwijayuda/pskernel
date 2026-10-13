# PSCV0 v7 — Continue remaining M2+A

Read AI_WORK_STATE.md and the linked canonical specification, architecture,
roadmap and design receipts. Work on dwijayuda/pskernel branch
psc0/pscv0-v7-native-lean-v1, preserving draft PR109 and expected-HEAD history.
GitHub connector source operations and Linux Actions only. Native portable
.lean, official Lean 4.35.0; no pskernel-core, local build, self-hosting or
compiler-source migration.

Study pinned upstream source and relevant tests before each substantial feature.
Prefer coherent shared mechanisms, minimal validation at architectural milestones,
no fabricated axioms, weakened acceptance or backend-specific semantic patches.

Latest qualified executable: d72fc7779b2e8d130915dfe4ace339634ba0addd;
Linux38466179341 passed with 399 shared observations/four panic contracts,
217 portable/227 native modules, Standard672/23/109, profile/60.
See AI_WORK_STATE for exact digests. ToFormat/Repr, selected Hashable instances
and nonrecursive deriving, UInt/BitVec construction/conversions and typed unsigned
Canonical ABI widths are qualified. Shared Int elimination and declaration-stable
Sort/Prop erased calls passed the whole matrix. Runtime hash correspondence is
tested against pinned native Lean, not formally proved.

Next: review the native-only unsigned-operation candidate export, which selects
all four widths' arithmetic/bitwise/shifts and the actual Nat.div logical model.
Do not admit unreviewed generated assets. See scalar completion design for
dependencies and Float's checked canonical-NaN/signed-zero semantics.
Continue signed/platform words, Float/scientific, BitVec/selected APIs,
comprehensive manifest and remaining M2/C5 retention. Full M2+A remains incomplete.
Do not stop at another small milestone or call bounded CI full completion.
Keep M2+A → M3+B → M4+C/D → M5/E, with recursive/indexed/dependent deriving in M3.
Wasm GC internally; linear memory only at explicit ABI boundaries.
