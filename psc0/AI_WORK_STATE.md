## M3+B exact qualification: open Nat.sub strict-child slice accepted (16 October 2026)

**Accepted compiler/test:** `721b97038926db5f34e2da1cf7157c68c18234ff`. All five exact same-commit
runs SUCCESS: native `38931145719` (33/33 steps), F1 `38931145674`,
F2 `38931145639`, F3/F4 `38931145711`, focused `38931145641`.
See `psc0/docs/PSCV0_M3_NAT_SUB_QUALIFICATION_2026-10-16.md`.
The pinned `Nat.sub a 0 ≡ a` conversion is checked for open terms,
with native oracle, source `rfl` equation, two scalar runtime inputs in
JS/TS/Rust/GC/Wasmtime and a phase-correct non-child subtraction refusal.
The previous **candidate pending-native** text remains historical.

**Next in-flight test-only candidate:** `3a2fbdfa` checks ordinary HAdd infix
`k + 0` and refuses `k + 1`; it must pass its own focused workflow
`38933071884` and does not by itself produce a new compiler qualification.
Entire M3+B **remains OPEN** for indexed/nested/mutual data, broad
elimination/well-founded total recursion and selected P0/P1.
No extra logical assumptions, unverified execution, benchmark relaxation or
performance speedup. Continue v7.2 only for .ps, native portable .lean,
GitHub/cloud CI, both handoffs and PR draft/open.

## Latest M3+B candidate: open Nat.sub strict child (not yet fully accepted)

Compiler/test `721b97038926db5f34e2da1cf7157c68c18234ff` implements exact pinned Lean 4.35.0
`Nat.sub a 0 ≡ a` reduction in shared native `Ps.Meta.NatReduce`.
The independent Lean oracle, checked .ps unfolding equation, 15 scalar
exports × 2 inputs across JS/strict TS/Rust/V8 GC/Wasmtime, and a
`Nat.sub(k,1)` non-child refusal now pass the **focused** workflow
[38931145641](https://github.com/dwijayuda/pskernel/actions/runs/38931145641).
Independent F1 [38931145674](https://github.com/dwijayuda/pskernel/actions/runs/38931145674),
F2 [38931145639](https://github.com/dwijayuda/pskernel/actions/runs/38931145639),
F3/F4/platform [38931145711](https://github.com/dwijayuda/pskernel/actions/runs/38931145711)
all SUCCESS on this exact code commit. The full native workflow
[38931145719](https://github.com/dwijayuda/pskernel/actions/runs/38931145719)
was **still IN PROGRESS when this checkpoint was committed**. Re-read its
final result before accepting. No old 4/5 green results establish
full integrated 5/5 success.

Fully accepted previous M3 prefix-recursion compiler `8f8aa47f`, with
five same-commit green workflows and final receipt
`psc0/docs/PSCV0_M3_PREFIX_RECURSION_QUALIFICATION_2026-10-16.md`,
remains the acceptance baseline. M2+A remains complete for original
bounded profile. v7.2 alone is future .ps; native .lean semantics unrestricted.
No source axiom/sorry/new classical assumption, pskernel-core, self-hosting,
unchecked totality, runtime performance-parity or completed M3 claim.

## Accepted M3+B prefix recursion / normalized evolving state — 16 October 2026

**Implementation/test commit `8f8aa47fc3b742488bd1ce4ad15024a63c0b6d4f`: all five same-commit gates
SUCCESS**. Native 38928344482 (job 117065962490: 33/33 steps, none
skipped); F1 38928344465; F2 38928344501; F3/F4/platform 38928344471;
focused 38928344644, including pinned Lean oracle, JavaScript, strict TS,
Rust, V8 GC, Wasmtime. Exact artifacts and digests:
[qualification](docs/PSCV0_M3_PREFIX_RECURSION_QUALIFICATION_2026-10-16.md).
The preceding pending-run and false-negative fixture notes are *history*
superseded by this evidence, not current blockers. PR #109 remains draft/open.

The admitted subset: a computed recursive major after pure unchanged
binder references, justified by read-only Core definitional equality to an
existing strict constructor field and IH; and separately qualified evolving
prefix state using the already checked worker-normalization machinery.
Defining equations, a changed-prefix state execution oracle, and a
nondecreasing *later* major refusal passed. **No general computed
discriminants, nested/mutual recursion, arbitrary decrease, P0 executable
partial or P1 fixedpoint admission is implied. M3+B remains OPEN.**

# PSCV0 — M3 structural strict-child accepted; M3+B continues

## Accepted M3+B structural strict-child slice — 16 October 2026

Selected compiler/test `8e7f18885a3e917fbdf000d7d108842b2cc1f067` passed all five exact same-commit gates:
native 38923349115 (33/33 steps), F1 38923349086, F2 38923349001,
F3/F4/platform 38923349042, focused 38923349138 (JS, compiled TS, Rust, V8 GC, Wasmtime).
See [structural child qualification](docs/PSCV0_M3_STRUCTURAL_CHILD_QUALIFICATION_2026-10-16.md).
It admits first-position computed children only by checked definitional equality
to an existing strict IH field. `Nat.add k 0` canonical conversion succeeds;
infix `k + 0`, non-first computed majors and general arithmetic decreases are
not yet qualified. The nondecreasing-successor negative rejects as intended.
Older pending-candidate notes below are **historical**, not live qualification blockers.
M3+B **remains OPEN** for nested/indexed/mutual data and deriving, more
elimination/motives, broader total recursion, source strategy matrix,
selected P0/P1 obligations, and cross-stage acceptance. Continue v7.2 only,
native portable .lean, pinned 4.35.0, no pskernel-core/self-hosting, no
weakened gates, same prior accepted M2+A and other evidence.

Updated 16 October 2026. **The selected direct-recursive DecidableEq slice is COMPLETE; M3+B remains OPEN.** v7.2 only for forward .ps development, no legacy modes or native .lean grammar restrictions. Reapply the attached user prompt and docs/PSCV0_V72_STAGE_DIRECTIVE_2026-10-16.md before each coherent slice; inspect fresh HEAD/CI/both handoffs/relevant v7.2 clauses/pinned sources.

## Exact accepted compiler

**3fc077fd836e32b0d4250ea7b21183bb06897eab**, tree52d39bde0d280342e4ccadf5ba483ea88e5e2ca3. This handoff is a documentation-only child, not a new compiler qualification.

All FIVE same-commit workflows passed: native38910660953, F1 38910660803, F2 38910660921, F3/F4/platform38910661102, focused recursive deriving38910660969. Native job117005717235 reports all33 steps passed, including setup/cleanup, none skipped. Read docs/PSCV0_M3_RECURSIVE_DECEQ_QUALIFICATION_2026-10-16.md; these final metadata-derived IDs supersede intermediate summaries. Full source/Standard, modules, GC/components, TypeScript/Rust, repeated native Wasmtime/post-return, unchanged measurement and publication passed.

The final fix aligns RecursorLift root eligibility with erasure's raw forall/lambda entry boundary. A function hidden behind a reduced result alias uses existing checked capture-preserving helper lifting. No new class-name special case, call arity, weakened erasure refusal or budget. Existing restoration/alpha-equality/official checking remain. The focused equality fixture includes native Nat/Bool decisions, independence from non-reflexive BEq, scalar-dependent proof fields with recursion, checked equations and exact refusals. This is the selected direct-recursive family, not all recursive/dependent equality.

Historical cc499 invalid oracle proof and2407 erasure failure are preserved in the design/history. Do not restart those repaired candidates or repeat the now-complete five-run gate. The source design and recursor-entry note retain their dated candidate history; the new qualification receipt supersedes their pending state.

## Next implementation

Continue broader M3 data/elimination/recursion mechanisms: nested/indexed/mutual families, motives/pattern matrices, structural/well-founded recursion, strategy ownership and selected P0/P1. No implementation beyond the accepted DecEq baseline is claimed by this handoff. Inspect actual source owners before choosing the next coherent slice; do not infer absence from an old roadmap or enable a guard without full downstream support.

Partial independent inhabitant/public opaque/private actual-body marker remains in the prepared graph. Every shared partial executable admission still fails. Never run the witness, drop the marker, invent body equations/totality, add Classical/Nonempty fallback or downgrade verified requests. P0 execution/assurance and P1 fixedpoints remain open.

## Preserved acceptance, authority and performance

BEq058fb67f accepted native38905476639, F1 38905476304, F2 38905476313, F3/F4/platform38905476451 and focused38905476153. Hashable/Repr4501164e/docsad47b42f and original M2 profile73integration2a707206/acceptance280e1e4e remain accepted with unchanged historical receipts. Never relabel them full v7.2.

v7.2blob694115223777599ba28ee175e14bb642b7b6aa4b/SHA256c65487eccbd2829d1d9e5e1be3bc7f4cb37849b841ab3257ea0dd47665b8a30e. Runtime133af061/paired38840337837/artifact12021226623 retain9.25–10.11xfromList, smaller indexing gains and unresolved deep-list/reversal. No new speedup, production parity or global preservation claim.

## Contract

GitHub/cloud Linux ONLY; no local files/checkouts/shell/build/tests/Desktop Commander. Native portable .lean; official4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc; onlypropext/Quot.sound. No pskernel-core/self-hosting/compiler-source migration/C5/sorry/unchecked admission/weaker gates/larger budgets. GC internally; linear memory explicit ABI. Fresh expected-HEAD/non-force writes, preserve concurrent history, BOTH handoffs each slice. PR109 draft/open/originalbase psc0/pscv0-v7-m1-parser-ownership-v1, never merge. Continue M3+B -> M4+C/D -> M5+E; no fabricated qualification or percentages.


## Candidate: definitionally equal strict-child recursion — qualification pending

A first-position recursive argument may now be inferred and compared by read-only
definitional equality to an existing, checked strict constructor child and IH.
The term is elaborated only once and checked against the dependent child telescope
and invariant arguments; arbitrary arithmetic decreases and computed non-first
majors remain unavailable. The independent pinned Lean oracle and one new
Bool-to-UInt64 observation in each existing target lane await same-commit
native/F1/F2/F3-F4/focused qualification. This does not close M3+B.
The unrelated fixed-discriminant cloud preparation commit 9f15ef1 failed
invariant validation. Its code and logs are preserved as an unqualified
experiment. No erasure gates, assumptions or performance budgets changed.

### M3 structural-child candidate correction — pending qualification
Focused run 38921593998 at 80d0654 built native Lean and the oracle but
rejected the new .ps example at recursive major selection. The shared
NatReduce converter only recognized closed binary arithmetic literals.
Official pinned Init/Prelude.lean defines Nat.add a 0 by reduction on the
second operand. This child patch adds only that exact definitional rule,
not zero-add, arbitrary arithmetic decreasing, a new IH or proof axiom.
The candidate still requires its own exact-commit five-workflow replay.

### Focused explicit-Nat conversion qualification pending
The pinned kernel equation Nat.add a 0 reduces even with open a. The new
computed-child fixture now spells this as Nat.add(k, 0), testing the direct
canonical constant before generalized infix HAdd dictionary normalization.
Previous infix k + 0 tests still fail in the selected PSC0 elaboration path;
do not claim full infix definitional-equivalence parity from this case.
The proof and target observations remain unchanged. Native and focused
qualification on this commit are required for acceptance.

### Fixed structural-child qualification and refusal
Focused run 38922907562 passed on f560a1df, including native oracle and
JavaScript, TypeScript, Rust, GC and Wasmtime for the explicit Nat.add(k, 0)
case. Full same-commit integration replays were not triggered by that fixture-
only child. This new candidate adds the intended-phase refusal for a
nondecreasing successor argument and documents that infix HAdd projections
require separately checked instance unfolding. Exact native/F1/F2/F3-F4
and focused runs on this commit are pending before formal slice acceptance.

## M3+B candidate — computed major after fixed invariant prefix (qualification pending)

Against exact accepted strict-child baseline 8e7f1888 / documentation 1cf46bc5,
shared native `Term.lean` now permits an elaborated computed recursive major
at a non-first explicit parameter position only if **every preceding
argument is the unchanged corresponding local binder reference**. This
prevents reordering any evaluated prefix expression. The prechecked major
is cached with its actual telescope position, reused only once and
revalidated against the selected strict child and dependent invariants.
No new arithmetic heuristic, IH, trust principle or erasure shortcut is added.

One independent pinned-Lean `laterChild(flag, n)` oracle, selected .ps
defining equation and one scalar Bool→UInt64 cross-backend observation are
added to the existing focused suite. A changing prefix `Bool.not(flag)`
must reject at the structural invariant rule in elaboration. Prior
Pos/Neg cases and all original budgets remain intact.

This is a candidate only. Require exact same-commit native, F1, F2,
F3/F4/platform and focused JS/TS/Rust/V8-GC/Wasmtime qualification
before acceptance. Nested/mutual data, dependent motives, well-founded
recursion, P0 ordinary execution, P1 fixedpoints and entire M3+B remain open.

### Focused qualification correction: changing parameters can be total
The focused 38927587017 candidate compiled and accepted the newly written
`badPrefix(flag, n)` negative, because its changed flag is permitted through
the existing checked changing-argument worker normalization; termination
is controlled by the strictly decreasing structural n, not invariant flag.
Therefore this was a *false negative expectation*, not unsound acceptance.
Do **not** outlaw legitimate changing state to satisfy this fixture.
The same focused suite instead checks `badLaterMajor(flag, Nat.succ(k))`
with an unchanged prefix but a nondecreasing recursive major at a later
argument position; that must reject by the same strict-child rule. Actual
typed-elaboration and proof gates remain intact. Qualification pending.

### Candidate positive evidence — evolving prefix state
The prior `badPrefix` refusal was invalid: recursion may change a prefix
state parameter while strictly decreasing a later major through the
existing checked worker-normalization. Focused 38927983884 successfully
qualified the corrected nondecreasing-later-major refusal at 6fe169bf.
This candidate adds `m3flipPrefix(flag,n)`, an independent pinned-Lean
structural proof, one exact Bool→UInt64 observation for each flag across
existing JS/TS/Rust/GC/Wasmtime lanes, and a checked source equation.
It preserves the conservative once-only computed-major prefix path as
a distinct supported case and leaves unsupported dependent/nested/mutual
recursion unchanged. The full five-gate exact-commit acceptance is pending.


## Latest exact CI checkpoint for fixed/evolving-prefix recursion
Compiler/test `8f8aa47fc3b742488bd1ce4ad15024a63c0b6d4f`: F1 **SUCCESS** run 38928344465,
F2 **SUCCESS** run 38928344501, F3/F4/platform **SUCCESS**
run 38928344471, focused **SUCCESS** run 38928344644
(JS, strict TS, Rust, V8 GC, Wasmtime; artifact 12057652697;
SHA256 6810c1bb993307f038cf0ad950e1eb77850a7b1df0d235efdea5d841f3c80c3f).
**Native run 38928344482 was still in progress in Wasmtime embedding when
this snapshot was written**. Recheck its conclusion; do not claim all five
green before it finishes. The candidate is not yet formally accepted.

An independently reviewed next native `Nat.sub a 0` reduction candidate
is prepared as **unattached blobs only**, not source branch changes:
`psc0/packages/meta/src/Ps/Meta/NatReduce.lean` = ce55c61324d6993f50c83c0e58e91108db9fac21,
`psc0/test/Pscv0M3RecursiveDeriving.lean` = 0caefd5276d56f461fa6e39facc4a0477e93947b,
`psc0/scripts/pscv0-m3-recursive-deriving.mjs` = 48e0b456c199dce2c0f6099c2800227a33c83188.
The code is based on pinned Lean 4.35.0 `Init/Prelude.lean`,
whose `Nat.sub a 0` equation is definitional. Do not advance this
unqualified candidate to the main development branch until exact native
qualification of the current recursion compiler has resolved. When
admitting it, build a new tree on fresh HEAD using these blobs, validate
a native oracle and negative `Nat.sub(k,1)` strict-child refusal, and
rerun all five gates. No runtime speedup is claimed.

## New v7.2 M3 total recursion conversion candidate — exact CI pending
This descendant of accepted compiler `8f8aa47f` and docs `88931aa3`
extends the shared, portable `Ps.Meta.NatReduce` conversion with **exact**
open `Nat.sub a 0 ↝ a` (stable Lean 4.35.0 `Init/Prelude.lean`).
It is a definitional right-zero equation, not an arithmetic decreasing
heuristic, and does not admit `Nat.sub k 1` as a structural subterm.

The existing focused independent pinned-Lean oracle and generated application
now exercise `normalizedSubChild`, a checked source unfolding equation and
one additional Bool→UInt64 output per flag in all previously supported lanes.
The new `badSubMajor(Nat.sub(k,1))` negative must reject at the structural
major rule. Existing strict-child, fixed/evolving-prefix, direct-recursive
deriving, benchmark, module, proof, erasure and runtime cases are preserved.
Five exact-commit native/F1/F2/F3-F4/focused workflows are REQUIRED before
admission. No new speedup or entire M3+B closure is claimed.

## Experimental M3 HAdd-infix computed-child conformance (focused qualification pending)

Prior Nat.sub compiler/test `721b97038926db5f34e2da1cf7157c68c18234ff`
still awaits exact native run `38931145719`; the four independent
gate results are green. This **fixture-only** candidate does not modify
compiler code. It tests `k + 0` through checked HAdd Nat instance
resolution against an existing strict-child IH, and a separate `k + 1`
negative that must reject at the structural elaboration rule.
The native Lean 4.35 oracle checks the equation by rfl; one additional
Bool-to-UInt64 source observation is compared on the existing
JS/strict TS/Rust/V8 GC/Wasmtime lanes.

The focused workflow must pass before claiming source infix conformance.
This is not automatic arithmetic termination, general well-founded
recursion, executable partial P0, P1 fixedpoints or full M3+B.
No new axiom, weakened original test or performance claim.

## M3+B candidate: child-typed computed operator majors (qualification pending)

The fixture-only `3a2fbdfa3ec4c63e6134792892b6c1a26028c25e`
failed focused run `38933071884`: `m3infixChild(k + 0)` rejected at
`PSCV0-RECURSION: recursive major must be a direct recursive field`.
Native Lean 4.35.0 accepts the same strict-child expression by definitional
equality. This candidate adds a **shared expected-type hint** for computed
recursive arguments: only when all actual constructor-recursive field types
are read-only definitionally equal is that common checked child type supplied
to the ordinary term elaborator. Varied indexed child types fall back to the
previous inference route. It still chooses an *existing checked IH* only
after exact Core definitional equality; no new termination heuristic or
trust principle is introduced. No source-specific HAdd rewrite or changed
backend semantics. The existing infix `k+0` positive and nondecreasing
`k+1` refusal demand their intended phases in the focused suite.
Five exact same-commit native/F1/F2/F3-F4/focused replays are required.
Full M3+B remains open; old Nat.sub all-five receipt is unaffected.
