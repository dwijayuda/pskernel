# PSCV0 v7 — AI work state

## Current F0 implementation/audit slice — 14 October 2026

Verified last full-green executable: `34ff236b6fe9f936d7d44b8ace1c70612c7cc66e`, Linux [38515443060](https://github.com/dwijayuda/pskernel/actions/runs/38515443060), selected /61 1516 declarations / 23 classes / 153 instances and 426 shared runtime observations. Draft PR 109 remains open. Do not call F0 or M2+A complete.

New F0 design/inventory checkpoint: [Float logical/runtime boundary plan](docs/PSCV0_FLOAT_LOGICAL_RUNTIME_BOUNDARY_PLAN_2026-10-14.md), updated at `5675dafa`. Explicitly separates existing Float/Float32 name and IR scaffolding from the absent checked Standard logical families. Audits pinned Lean 4.35.0 Model/Float, Model/Float32, bits, IEEE-vs-structural equality, scientific literals and runtime/ABI proof obligations. No new source Float support is claimed.

New executable F0 *read-only closure discovery* at `64a79a738d279e973839c624468fbec222212eb5` expands the existing native `--audit-standard-closure` to both Float wrappers, bit transports, BEq and OfScientific. Linux qualification [38521251051](https://github.com/dwijayuda/pskernel/actions/runs/38521251051) was launched: **verify its actual result before relying on it**. This does not import, assume, or emit floating declarations. Next, select a complete closed Lean logical model F0 candidate and replay it in the official kernel with strict assumptions/snapshot boundaries; then implement F1–F4 in dependency order. Preserve no C5/self-hosting/pskernel-core scope, no new assumptions, and existing cross-target baseline.

## Post-/61 research checkpoint — Float/Float32 semantic closure

Reviewed pinned Lean 4.35.0 `Init/Data/Float/{Float,Float32,Model/Float}.lean`, `Init/Data/OfScientific.lean` and the upstream floating conformance tests. The new [Float logical/runtime boundary plan](docs/PSCV0_FLOAT_LOGICAL_RUNTIME_BOUNDARY_PLAN_2026-10-14.md) pins canonical NaN bits, Boolean vs propositional equality, signed zero, f32 rounding, exact scientific literals, cross-target runtime/ABI responsibilities and negative conformance. **Research only: no Float implementation or new proof assurance is claimed.** Next dependency order is F0 selected Core closure, F1 bits/classification, F2 arithmetic/BEq, F3 conversion/literals, F4 all-target qualification. /61 remains last green executable at `34ff236b`, CI `38515443060`.


## New qualified /61 checkpoint — 14 October 2026

Executable commit `34ff236b6fe9f936d7d44b8ace1c70612c7cc66e` passed the full Linux workflow
[38515443060](https://github.com/dwijayuda/pskernel/actions/runs/38515443060).
Profile `pscv0-v7-native-bounded/61` is **green for its declared selected scope**; this
does NOT mean M2+A, all v7, C5, full compiler metatheory, or formal backend preservation
are complete. Standard selected 1516 declarations / 23 classes / 153 instances, FNV
`fnv1a64:6333670853941549394`; SHA candidate
`sha256:ebf02f5f8dfecf3769cbaeaa52e39dac3ba9c8dc034ea5284655da324bc75d60`.
426 shared cross-target runtime observations passed for TypeScript, JS and Rust;
Wasm GC/Wasmtime component, linked projects, parser/negative conformance, official kernel,
asset regeneration and performance gates passed. These are bounded runtime observations,
not a proof that every possible backend program preserves Lean semantics.

Resolution: the official Lean 4.35.0 `Init/Prelude.lean` defines
`Unit : Type := PUnit` and `Unit.unit := PUnit.unit`, but PSC0's APP-03
empty-call path rejected a fresh *universe metavariable* in the
`PUnit` argument domain before checked unification. The source check
now distinguishes unresolved term types (still refused) from the known
Unit/PUnit family, solves the universe using ordinary checked unification,
then rechecks definitional equality and inserts an ordinary typed Unit inhabitant.
All positive APP-03 cases (including `PUnit`) and the existing negatives passed.
No new axiom, untrusted cast, permissive fallback or relaxation of source/kernel
acceptance. Previous historical /61 failures and /60 baseline below remain for
audit but are superseded by this independently qualified executable checkpoint.

Further upstream sources studied for preceding /61 root fixes:
`src/runtime/interrupt.cpp` (thread-local heartbeats),
`src/kernel/environment.cpp` (checked `lean_add_decl`),
`src/Lean/Environment.lean` (`Kernel.Environment` checked replay),
`src/Lean/Declaration.lean` (kernel reducibility hints),
`src/Init/Data/UInt/Basic.lean`, `src/Init/Data/Hashable.lean`,
and `src/Init/Data/String/Defs.lean`.
Use pinned commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
Upstream licensing is acknowledged in the adapted source and
`psc0/THIRD_PARTY_NOTICES.md`.

Next: make `/61` the qualified baseline, update the latest frozen snapshot and
milestone status documentation consistently, audit hot-path performance/resource
telemetry, and continue the remaining M2+A language/standard exit criteria
without starting C5 or self-hosting.


Checkpoint: 14 October 2026. This file and [AI_CONTINUE_PROMPT.md](AI_CONTINUE_PROMPT.md)
are the active handoff. **Update both after every milestone slice**, as requested
by the user because usage is low. Record the exact code revision, CI evidence,
remaining work and next action before beginning another slice.

## Latest continuation: kernel-only replay, awaiting qualification

Run [38479812733](https://github.com/dwijayuda/pskernel/actions/runs/38479812733)
at `15cea236` passed build, quotient probes, frozen regeneration and GetElem
erasure. It failed later on a malformed new List.foldl fixture; it also exposed
AsyncConsts collisions between distinct imported private names.
The next code commit moves standalone checking/replay to official
`Lean.Kernel.Environment.addDeclCore` at trust zero, preserving full names and
all kernel checks. It fixes the fixture's APP-03 argument order and compiles the
provider Admission module to validate the changed API. No new assumptions.
The earlier quotient/Unit failure descriptions below are historical diagnoses.
Fetch the new run and inspect complete results; /60 remains the last full green.

## Active repair slice — implemented, awaiting CI

The next code commit after checkpoint `85b35cd` implements quotient group
admission once with per-descriptor validation, shared nullary literal handling
before definition lookup, normalized PUnit's unit carrier, and removal of the
temporary cache fallback. The existing quotient probe covers repeated/reversed
descriptors, forged existing signatures and provider collisions.
[Design and pinned source references](docs/PSCV0_M2_A_SCALAR_COMPLETION_2026-10-14.md).
These changes are **not yet qualified**. Fetch live HEAD and its native workflow;
record results in both handoff files. Historical failure details below identify
the causes addressed by this slice, not a new observed result.

## Current state: M2+A incomplete; /61 qualification pending

- Repository: `dwijayuda/pskernel`; branch: `psc0/pscv0-v7-native-lean-v1`.
- Existing draft [PR 109](https://github.com/dwijayuda/pskernel/pull/109).
- Latest code: **`1f54142c6225020c39265254a582860bd4169937`**.
  A documentation-only checkpoint follows this revision; fetch live HEAD.
- Latest [Linux run 38478159236](https://github.com/dwijayuda/pskernel/actions/runs/38478159236),
  job `115573914577`: **completed, failure**.
- Profile `pscv0-v7-native-bounded/61` is **under qualification**.
  Build, asset regeneration and strict registry digest checks passed; source
  checking failed in erasure. Native/backend integration was not reached.
- Failure: `PSCV0-ERASURE: unknown constant Unit.unit (in PsStandard.instInhabitedUnit)`.
- The same log contains repeated **PANIC: duplicate normalized declaration name
  Quot vs. Quot**, from official Lean environment admission. These panics are
  unresolved even though execution continued.
- No new full-green result, M2+A completion, formal runtime equivalence or
  performance parity is claimed.

The user **explicitly approved exactly Lean 4.35.0's `propext` and `Quot.sound`**
for the audited foundation. Approval is already published. **Do not ask again.**
All dependent proof declarations still require official Lean kernel checking.
No other additional assumptions were approved.

## Execution contract and source of truth

Use GitHub connector source reads/writes and Linux Actions only; no local
checkout, shell/build or Desktop Commander. Work natively in portable `.lean`.
No `pskernel-core`, self-hosting tests or compiler-source `.ps` migration yet.
Wasm GC internally; linear memory only at explicit ABI boundaries.

Fetch live remote HEAD and relevant CI before writes. Preserve concurrent work
with expected-HEAD, non-force updates. Keep PR 109; do not merge.
Do not weaken acceptance, fabricate axioms, add unchecked kernel fallbacks or
hide runtime representation errors with arbitrary casts.

Study corresponding official **Lean 4.35.0** source and tests before feature
design/implementation/redesign, at commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
Record semantics, algorithms, invariants, data structures and justified
simplifications. Preserve attribution/licensing when adapting code.
Prefer coherent shared mechanisms, then focused validation and existing
integration gates. Preserve required behavior, not obsolete internals.

Canonical references:

- [Language reference](PSCV0_LANGUAGE_REFERENCE.md)
- [M0–M5 architecture](docs/PSCV0_NATIVE_LEAN_GRADE_ARCHITECTURE_REDESIGN_V1.md)
- [Phase A–E exit gates](docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md)
- [Readable-output audit](docs/PSCV0_READABLE_OUTPUT_AUDIT_2026-10-13.md)
- [Pinned Lean migration](docs/PSCV0_LEAN_435_PIN_2026-10-14.md)
- [Active scalar design and source study](docs/PSCV0_M2_A_SCALAR_COMPLETION_2026-10-14.md)
- [Format/Repr/Hashable design and qualification](docs/PSCV0_A_FORMAT_REPR_2026-10-14.md)

## Last fully qualified boundary: /60

Executable **`d72fc7779b2e8d130915dfe4ace339634ba0addd`**;
[green Linux 38466179341](https://github.com/dwijayuda/pskernel/actions/runs/38466179341),
job `115533442925`.

- 399 shared runtime observations and four panic contracts.
- 217 portable / 227 native modules.
- Standard: 672 declarations / 23 classes / 109 instances.
- FNV: `fnv1a64:10680386315174967875`.
- SHA: `sha256:9a54d5747d3047abff68e3bd872b791f3489f719cf83e8aba6776d342f045cc0`.

Official kernel, independent pinned native oracle, semantic/refusal/search,
strict IR, JS/TS/Rust, V8/Wasmtime GC, WIT/WAT/component/ABI, projects and
existing performance gates passed at that boundary.

Qualified: ToFormat/Repr and selected nonrecursive deriving; UInt/BitVec
construction/conversions; unsigned Canonical ABI widths; Hashable class,
17 checked instances and selected nonrecursive deriving; native-compatible pair
and UTF-8 string hashes. Hash runtime algorithms are audited implementations
of checked opaque declarations, not formally proved equivalent.

Shared Int.rec erasure evaluates its sign discriminator once. Generic calls
retain original declaration binder masks when Sort parameters specialize to
Prop; irrelevant carriers/proof slots use Unit. Complete-spine WHNF and
reflexivity-before-evaluation repairs remain. Frozen proof assets regenerate
exactly. The /60 qualification predates the newly approved two-axiom /61 closure.

## Implemented /61 slice, with limited qualification

### Checked unsigned operation asset and dictionaries

Commit `e9fde4e3ff88b1e83c8c59e7b531403f6eb5d154` admitted
`packages/environment/src/Ps/Environment/StandardUnsignedOperationsData.lean`:

- 803 declarations; 49,978 shared typed source nodes; 6,457,592 UTF-8 bytes.
- Source SHA256:
  `b33dc2e256f17da29a3236a24c2d8267bf04de4338d73c568cafc44ee686f2de`.
- Exactly the two approved axioms and four kernel-generated quotient descriptors.
- UInt8/16/32/64 add/sub/mul/div/mod/neg/complement/land/lor/xor/shiftLeft/shiftRight
  (48 operations), and the actual Nat.div logical model.
- Six former axiom declarations replaced by native checked definitions:
  Nat.decEq, Bool.decEq, Unit.unit, Unit, Nat.blt and Nat.div.
- `StandardUnsignedOperations.lean` adds 24 explicit HAdd/HSub/HMul/HDiv/HMod/Neg
  dictionaries. Logical proof dependencies do not enter runtime support.
- Frozen `psSelfHostProdHashPreludeEnvironment` feeds the operation stage.
  Export boundary is `psStandardUnsignedOperationsBoundary`; source sharing is
  enabled and definition-to-axiom replacement is disabled.
- Both new portable Lake roots are registered. Primitive audit covers all 48.
- Isolated quotient probes deliberately use the pre-admission Hash stage.
- Fifteen observations were added to the existing shared native/all-target
  harness: width vectors, higher-order shift, generic wrapping addition and
  exact UInt32 maximum-times-maximum multiplication. They are **not yet fully
  qualified**. Temporary artifact transport jobs were removed; regeneration
  compares admitted and fresh sources byte-for-byte.

Earlier /61 work also includes native two-universe Prod and product dictionaries;
alpha-renamed/normalized universe signature audit; right-discriminating Bool.beq;
native List.foldl telescope and List.reverseAux equations; 16 UInt default/display
dictionaries; general logical iota beneath recursive function telescopes; quotient
descriptors and lift/ind reduction. Product/display observations also await full
integration. Unsigned div/mod/shifts use shared IR plus ECMA/Rust/Wasm plans,
including exact UInt32 multiplication, UInt64 BigInt, zero guards and width-masked
shifts; this does not enable signed/platform/Float support.

[Run 38476108793](https://github.com/dwijayuda/pskernel/actions/runs/38476108793)
compiled 220 portable / 231 native modules; all four frozen assets regenerated
exactly; 803 candidate declarations were kernel checked and 33 recursor rules
compared. Its old /60 snapshot deliberately refused the changed registry.
Do not interpret the kernel receipt as proof that repeated quotient admission
is clean: the later production replay exposed the duplicate-registration panic.

### Reviewed strict digests and faster native validation

Commit `1f54142c6225020c39265254a582860bd4169937` pins the new payload values
independently reported by the previous Nat-arithmetic implementation:

- FNV: `fnv1a64:16613033526791726173`.
- SHA: `sha256:8aea3c6be714db09f4a5a442e9fab57a40bdf13c11d86e811c2574165d55b04d`.

The checksum implementation now uses UInt64 FNV, UInt32 SHA-256 and packed
ByteArray storage; joint validation serializes the canonical payload once.
Digest/padding semantics and strict drift refusal remain unchanged. No hash
FFI, new assumptions or automatic snapshot acceptance.

Latest run passed the full-payload strict checks. Existing four SHA known-answer
vectors remain, but their later `projectBoundaries` gate was not reached because
erasure failed first.

Bounded CI measurements: previous cold build 222,087 ms, warm 595 ms; latest
native rebuild 12,317 ms, warm 561 ms. Audit/export commands fell from roughly
73 seconds each to 2–5 seconds; unsigned regeneration was approximately 4.95
seconds including startup versus 75 seconds. This is evidence for this workload,
not a full parity claim.

Cache keys now use OS/architecture/toolchain hashes; Lake's traces track module
changes. The exact old-key fallback in
`.github/workflows/psc0-pscv0-native-v7.yml` was temporary migration scaffolding.
The latest run saved the new cache; remove that fallback in the next code slice.

## Next slice: fix two shared boundary invariants

### 1. Admit the quotient group once; validate every descriptor

Owner: `packages/pskernel-lean/provider/PsKernelLean/Prelude.lean`.

`toLeanPreludeDeclaration` converts each of Quot, Quot.mk, Quot.lift and Quot.ind
to the same generative Lean `.quotDecl`. `tryPreludeDeclaration` unconditionally
calls `env.addDeclCore 2000000 20000 converted none true`, then validates the
member's kind/type/universe metadata. Each descriptor and replay retry therefore
tries to generate all four constants again. Lean's AsyncConsts uniqueness
invariant panics on the repeated declaration.

Study pinned `src/kernel/quot.cpp`, `src/Lean/Environment.lean`,
`src/Lean/Declaration.lean`, `tests/elab/quotInd.lean` and locate the
`kernelQuotNameCollision.lean` test before editing.

Design direction: separate **ensure the kernel quotient group exists once**
from **validate this supplied member**. Inspect the checked environment for the
group; generate it once when absent, otherwise validate exact existing kernel
quotient kinds/types/level parameters without re-adding. Reject partial groups,
collisions and forged metadata. Share member validation across both paths.
Do not introduce general name-based duplicate skipping for other declarations.
Use this same mechanism for candidate authoring and production prelude replay.
Retain the isolated Hash-stage signature/collision refusal probes.

### 2. Resolve builtin runtime identities before ordinary definitions

Owner: `packages/erasure/src/Ps/Erasure/Expr.lean` and shared erasure helpers.

Unit.unit was formerly an axiom, so the late nullary-literal fallback handled it.
Its admitted native definition now resolves as an ordinary runtime entry first;
it is intentionally absent from runtime support, so lookup fails before reaching
the existing fallback. Adding its proof closure to runtime would fix the symptom,
not the invariant.

Inspect the complete constant/application/eta-completion paths, especially
`psErasureSpecialEntry`, `psEraseSpecialBoundary`, `psEraseGeneralApplication`
and `psErasureResolveEntry`. Centralize existing builtin literal/runtime identity
classification before ordinary definition lookup, consistently for constants and
applications. Check the related Bool.true/Bool.false/Nat.zero family; preserve
arity and overapplication refusal. Native Unit is an alias to PUnit.
Keep logical checked definitions separate from their audited runtime treatment.

After implementing both coherent fixes, run existing focused official-kernel/
erasure gates and the full native workflow. Check logs for panics explicitly,
not just process exit status. Re-run remaining checksum vectors and all-target
observations through that workflow. Do not call /61 qualified before the complete
matrix passes. Update both handoff files with exact evidence at this slice.

## Next unsigned-interface slice (design only, not published)

A prior session prepared parser buffers in memory only. They were **not applied,
compiled or published**; no future chat should depend on those transient stores.
The branch contains all other active code described above. Reconstruct the design
from pinned sources rather than assuming a missing working-tree patch exists.

After /61 qualification:

- Export a separate frozen native comparison/conversion interface stage against
  the unsigned-operation boundary, with no new assumptions.
- Study UInt decEq/decLt/decLe, native LT/LE instances, all twelve cross-width
  conversions, Nat.toUInt aliases, GE.ge/GT.gt and DecidableLT/LE.
- Register actual checked class/instance metadata separately from proof data.
  Existing LT/LE and Nat instances are present in scalar data but absent from the
  curated source class roster. HAnd/HOr/HXor/HShiftLeft/HShiftRight/Complement
  declarations already occur in the operation proof asset.
- Reuse the existing typed machine comparison plan; comparison proof fields erase.
  Evaluate width-conversion composition against an explicit typed cast for
  correctness and performance; this decision is not implemented yet.
- Study native priority-500 `instBEqOfDecidableEq` and generic Pi search/runtime
  support before reusing it.
- Parser plan: one bounded longest-adjacent-token reader shared by prefix/infix,
  at most three existing lexer tokens; preserve spans, reject gap fusion and
  never consume empty EOF. Ordinary class applications own semantics.
  Relations at precedence 50, nonassociative; bitwise OR 55, XOR 58, AND 60;
  shifts 75 left-associative; complement prefix 100.
- Relevant PSC0 owners:
  `packages/syntax/src/Ps/Syntax/Pscv0/Operators.lean`,
  `packages/syntax/src/Ps/Syntax/Pscv0/TermRead.lean`.
  Pinned references: Init/Prelude, UInt/Basic, UInt/BasicAux, Init/Notation,
  Lean/Parser/Basic tokenFnAux; tests bv_uint, uint_fold, uintMatch, fold_uint.
- Validate a compact set of boundaries, generic and partial applications through
  the existing conformance table. Keep proof closure out of runtime support.

Checksum source study also covered pinned
`src/Lean/Compiler/LCNF/ExtractClosed.lean`,
`src/Lean/Compiler/NeverExtractAttr.lean`,
`src/Init/Data/ByteArray/Basic.lean`, UInt Basic/BasicAux and
[NIST FIPS 180-4](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.180-4.pdf)
sections 4.1.2 and 6.2.

## Roadmap and preserved architecture

Interleave **M2+A → M3+B → M4+C/D → M5/E**. M1's selected checked
GetElem/Fin/List/Array/optional-lawfulness closure is complete.
Recursive/indexed/dependent deriving belongs with M3's data/transport/termination
mechanisms. Effects/specifications/VCs belong to M4/C-D.
Collect E evidence and measured M5 improvements throughout.

Remaining M2+A includes unsigned comparisons/conversions/dictionaries,
signed/platform words, Float/Float32/scientific, expanded BitVec/bytes/selected
library APIs, the comprehensive cryptographic module/public/import/notation/
handler/class/instance/tactic/effect/axiom manifest, broader scope/depth/resource
evidence and C5 semantic retention. A declaration snapshot is not the complete
manifest. Do not move incomplete gates merely to declare M2+A finished.

Shared instance search uses generator/consumer tables, exact checked keys,
fresh term/universe answer templates and independent budgets. Only an answer
owner adopts its speculative context; consumers instantiate/recheck in their own
contexts. Closed identical local signatures are required for sharing. Output
preferences reconcile after selection without lower-priority backtracking.
Limits remain 4096 generators/candidates/answers, 32768 transitions, height 64.

One transactional synthetic queue handles Core constraints, saved syntax,
tactics/defaults/numeral fallback and expected-term adaptation. Ordinary work
quiesces before defaults; declarations drain pending work. Defaults use checked
opaque holes, failed retries roll back lexical authority, and reducibility
policy remains explicit. Genuine OfNat and direct Coe/CoeFun/CoeSort use shared
typed application; no coercion chains/auto-lifting, and APP-03 stays strict.
The SynthInstance facade must not acquire another retry engine.

See [instance graph](docs/PSCV0_M2_INSTANCE_GRAPH_2026-10-13.md),
[generalized constraints](docs/PSCV0_M2_GENERALIZED_CONSTRAINTS_2026-10-13.md),
[postponed elaboration](docs/PSCV0_M2_POSTPONED_ELABORATION_2026-10-13.md),
[coercions](docs/PSCV0_M2_DIRECT_COERCIONS_2026-10-13.md),
[deriving](docs/PSCV0_M2_A_DERIVING_2026-10-13.md) and
[equality/defaults](docs/PSCV0_M2_A_EQUALITY_DEFAULTS_2026-10-13.md).

Parameter/universe-aware Inhabited/BEq/DecidableEq share family/field/recursor
mechanisms. Selected deriving handles non-indexed/nonrecursive families with
independent computational fields. Proof-only fields erase; dependent runtime
existentials and general higher-rank dictionaries remain explicit refusals.
Do not bypass unknown-type IR checks.

Readable JS/TS/Rust/WAT/WIT are implemented for the qualified subset; extend the
shared plans. Historical bounded Lean/PS printers are reusable, not complete C5.
Retain checked pre-erasure binder/resolution/implicit/default/occurrence semantics
during M2–M4; publish reconstruction/correspondence under M5/E. Coarse declaration
maps or source replay do not establish reconstruction, and two checked outputs
are not a proof of equivalence.
