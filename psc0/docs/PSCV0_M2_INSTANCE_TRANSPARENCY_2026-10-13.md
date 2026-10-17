# M2: explicit instance-search transparency

## Design and invariants

Pinned upstream: Lean 4.35.0-rc4, c29b6dda4f7c20e3eeaa717c4e565663c5cfa364.
Reference implementation:
- src/Lean/ReducibilityAttrs.lean defines the five statuses.
- src/Lean/Meta/SynthInstance.lean selects instance transparency.
- Native PrimitiveAudit records and verifies every selected definition whose
  identity exists upstream. Portable helper identities are labelled separately.

Core expression/declaration identity is unchanged. A persistent bucket index
holds reducibility metadata; explicit policy parameters govern the shared
reducer, congruence and unifier. Ordinary kernel-style checking retains full
definition conversion. Instance target preparation, candidate preparation,
candidate matching and generator-key comparison use instance transparency.
Checking a selected witness remains ordinary type checking, as does checking
a mandatory default. Speculative failures still roll back all assignments.

Source abbreviations are reducible; registered instances are instance-reducible.
Ordinary definitions are semireducible. Opaque bodies remain unavailable regardless
of metadata. Public interfaces preserve metadata alongside existing body exposure.
The ordered selected declarations' statuses enter the canonical v2 Standard payload.
Cached index shape is not hashed. No per-query environment copy or body deletion.

Numeral elaboration also checks the Nat fast path at instance transparency:
a hidden ordinary alias cannot bypass OfNat search merely because it reduces
under full conversion. Explicitly typed Nat terms still use ordinary checked
conversion where the source requests it.

## Validation and status

Implementation pending qualification. One compact boundary covers abbreviations,
local dictionaries, ordinary aliases, explicit conversion, imported abbreviation
metadata and digest drift. The independent pinned source oracle checks the same
positive/refusal boundary. All existing graph, runtime and backend gates remain.

Current last qualified executable is 35641f810e31f3c9d309c01028acd53ebe4112d9,
Linux run 38430940757, 293 shared observations. The intentional metadata payload
change must be reviewed and both expected digests repinned only after the strict
guard reports them. This is not full M2+A or v7 completion.

## Reviewed payload update

Native compilation and independent source oracle passed at
5cb1352d201506f93131cecdd6c0b4b864e94380, Linux 38431987071.
PrimitiveAudit checked the selected native definition statuses successfully.
The strict production guard then refused the old digest, as intended:
FNV `fnv1a64:1901246055571366448`,
SHA `sha256:799539fdf6557760d1c9134439ac6ea811915c7c6b054164310c11aa3e017136`.

Review: the v2 payload adds declaration-ordered reducibility records. Core
declarations, class/instance order and aliases are unchanged: 308/18/54.
The 36 upstream nondefault statuses are explicit; registered portable helper
instances use instanceReducible, all other portable definitions use semireducible.
No new axiom, primitive or assumption. Both expected hashes are now repinned;
full runtime qualification remains pending.

The existing synthetic diamond used `Id Nat` as its convertible duplicate.
RC4 marks Id implicit-reducible, above instance-search transparency. That old
expectation was incorrect. The same cycle/diamond/growth acceptance assertions
now use the genuinely reducible `optParam Nat 0`; a separate source-oracle
and graph refusal retain coverage of Id at the restricted policy. No resource,
sharing, replay or evidence-height assertion was weakened.

Expected-type propagation must preserve the original checked term, even when
a reduced view is used to inspect its shape. The shared unifier now attempts
typed flexible-head assignment before delta reduction. This keeps
`?A := Hidden` rather than silently changing it to `?A := Nat` before search.
Failed assignment attempts remain transactional and can fall back to ordinary
conversion. This also avoids unnecessary reduction on successful inference.

## Qualification complete

Executable `35e239193e69cc466b81ac57282df1b1500f4927`,
[Linux 38433276797](https://github.com/dwijayuda/pskernel/actions/runs/38433276797).
All **293 shared runtime observations**, four panic contracts, official RC4
kernel and independent oracle, graph/refusal tests, strict IR, JS/TS/Rust,
GC-Wasm V8/Wasmtime, WIT/WAT/components, project and performance gates passed.
**188 portable / 196 native modules**, profile `pscv0-v7-native-bounded/51`.
Standard remains 308 declarations / 18 classes / 54 instances; reviewed v2
digests above. Full M2+A remains open.
