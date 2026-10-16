## M3+B candidate — group runtime and checked Nat-measure recursion

This checkpoint combines the retained atomic inductive-group implementation
with typed companion-worker execution and selected total well-founded
recursion. It is a **compiler candidate requiring all five gates on its own
exact SHA**, not a full M3+B acceptance claim.

Initial cloud compilation of `68a14501dc670142aa61c2bee4eae05fe7f68ac5`
failed in all five gates before runtime qualification: the three built-in
`PsRuntimeInductiveInfo.mk` calls omitted the new optional group argument,
and `Ps.Elab.WellFounded` referenced a name helper outside its import closure.
The following repair supplies explicit singleton `none` arguments and uses
ordinary Core name construction. No expected values or acceptance checks
change; all five gates must run again on the repaired compiler SHA.

The next build, `ec22f4437e9f0d346af0a0da6d7981788760f6fb`, compiled those
owners and found two detached `.mapError` continuations in
`Ps.Erasure.WellFounded`. They are joined to their parenthesized calls, along
with two analogous fixture continuations identified before that fixture could
compile. This is a Lean syntax repair; runtime results remain unqualified.

The group runtime path constructs one ordinary checked definition per family
from the actual complete recursor application. All workers retain the same
capture telescope, levels, parameters, motives and minor arguments; only the
family's own indices and major vary. A small names/capture-count record locates
these definitions. Before erasure, their complete retained equations and
runtime declaration identities are revalidated. Cross-family recursive calls
reuse ordinary typed call erasure, including erased slots and distinct result
types. No sidecar record grants proof or kernel authority. Native group syntax
does not expand v7.2's def/function-only source mutual grammar.

A total `termination_by` declaration now retains its measure and optional
`decreasing_by by { ... }` proof, scope and source spans. The selected executable
slice has one explicit Nat argument and Nat result. Its real logical body uses
the already checked `WellFounded.Nat.fix`; each source recursive call creates
a scoped decrease goal, and one proof sequence handles all goals in creation
order. The source-owned batch also contains a checked `f.eq_def` theorem from
`WellFounded.Nat.fix_eq`. This is exact fixedpoint unfolding; constructor
branch equations reduce, while broader open-match equation normalization is
not claimed. Runtime lowering recognizes that actual typed construction and
erases its checked decrease proof through the ordinary function ABI.

Focused evidence adds a parametric group fold with captured state, differing
family index counts/result types, and rejection of a well-typed stale worker
equation. The independent well-founded fixture covers arithmetic decrease,
multiple ordered proof goals, a nonidentity measure, default proof, source
ownership/private scope, a checked successor equation, and semantic refusals.
Both execute scalar observations across JS, compiled TS, Rust, V8 GC and
Wasmtime using the existing pinned tools. Original workloads, iteration counts,
checksums and budgets are unchanged.

Earlier group production `c16d16be58efbf4b40a467af25db59c88c648a10` passed F1
`38956942775`, F2 `38956942665`, F3/F4 `38956942889` and full native
`38956942787`. The corrected independent
group oracle on test-only `0179354359c9e75de3e7b6f74d7e86835232dff6` passed
focused `38958044907`, including the P0 captured recursive closure and existing
deriving target matrix. The earlier focused failures were test import,
parameter-spelling and direct mutual-recursor code-generation issues, not
relaxed expectations. These results span SHAs and do not establish same-commit
integration acceptance.

Latest fully accepted baseline at preparation remains
`a7c6dade87a9d8df74d5248e8276623e7870078c`. P1 remains fail-closed:
pinned `Lean.Order.fix` / `CCPO.csup` and generated equations require
unapproved `Classical.choice`; the independent oracle observes this exact
dependency outside the admitted Standard. Approved assumptions remain only
`propext` and `Quot.sound`.

M3+B stays OPEN. Approximately 40% was fully qualified before this candidate
(30–50% engineering uncertainty); do not count candidate code as accepted
coverage. Source group Match/deriving, broader nested traversal, broader total
and mutual-recursion strategies remain critical work. No M4 verification,
effect, general preservation or new performance claim is made. PR #109 remains
draft/open/unmerged. Preserve the historical checkpoints and receipts below.

## M3+B candidate — atomic groups, portable reduction and ordinary closures (17 October 2026)

The native `psElabInductiveGroup` entry point now stages all family headers,
checks compatible common parameters and result universes, elaborates every
constructor in the common environment, and constructs all group motives and
constructor minors. Existing singleton source declarations use the same
mechanism. `Ps.Core.InductiveGroup` owns ordered group shape;
`Ps.Bridge.CheckedAdmissions` resolves unique retained records and emits one
canonical official-Lean inductive batch. Duplicate/conflicting descriptors,
incomplete retained group recursors and reordered membership refuse.

This is a **new compiler candidate, not an acceptance receipt**. The focused
workflow includes independent Lean declarations, canonical group admission,
whole retained recursor-signature witnesses, cross-family reduction, indexed
and Prop elimination checks, and explicit unsupported-consumer refusals.
Portable iota selects the target family's global minor segment and each
recursive field's actual family recursor with its own indices. Independent
native and canonical kernel equations are compared with portable reduction;
malformed group metadata, ordinals and major families remain stuck. Source
match/deriving/runtime consumers and nested auxiliaries remain unfinished. The v7.2
`.ps` mutual grammar still selects def/function groups; it is not expanded to
mutual inductive syntax by this native API change.

The preceding P0 assurance and P1 source-strategy candidate is included.
A finite P0 fixture passes a recursive closure with changing captured state
through a higher-order function for comparison on every target lane.
Its parser indentation failure was corrected in
`ef47dee3de4de6298de276322a30b2bac3af0a73`; qualification must be read from
actual runs, never inferred from its successful compiler build. Its focused,
F1, F2 and F3/F4 gates passed; its native run was superseded/cancelled. The
first group builds found missing portable Lake registration and a Data record
indentation error; both are corrected without weakening checks. P1 remains
unavailable because pinned `Lean.Order.fix` and its equations transitively
require unapproved `Classical.choice`. Only `propext` and `Quot.sound` remain
approved; the isolated oracle observes that blocker without changing policy.

Require all five gates on this new compiler SHA. Latest fully accepted
baseline at preparation remains `a7c6dade87a9d8df74d5248e8276623e7870078c`.
M3+B stays OPEN, approximately 40% qualified (30–50% engineering uncertainty).
PR #109 remains draft/open/unmerged. Preserve the full history below.

## M3+B candidate — P0 assurance identities and retained P1 source strategy (17 October 2026)

This commit is a **new, unqualified compiler checkpoint** on top of live source
`9cf5a9a90e736ab1172bdf7b3107169cedf78ec1`. The latest fully accepted compiler
remains `a7c6dade87a9d8df74d5248e8276623e7870078c` and its five-gate nested
shared-model receipt. The newer P0 candidate's full native run
`38948302333` failed only at the stale expectation that all partial runtime
targets refuse; its focused/F1/F2/F3-F4 gates passed. Do not accept that
candidate from focused evidence alone.

The integration boundary now requires explicit ordinary partial artifacts,
exact targets and nonempty bundles, actual typed body identity, logical
opacity, generic-library refusal, and both verified-grade refusals including
imported dependencies. The native CLI propagates `--assurance` through both
single-source and project requests; saved origins use the returned assurance
identity. Original performance workloads, iteration counts and checksums are
unchanged.

A valid `partial_fixpoint` suffix is retained as its own source declaration
through source lowering and scope resolution. It is no longer misdiagnosed
as a declaration prefix. P1 elaboration remains unavailable under the
unchanged approved assumptions: the required pinned `Lean.Order.fix`
construction uses `CCPO.csup` and `Classical.choice`. An isolated official
Lean oracle inspects actual Unit/Option fixpoints and generated-equation
axiom closures; it is outside the compiler's admitted Standard environment.
No P1 executable, new logical assumption, equation, or verified fallback
is enabled.

Require this checkpoint's **own** native, F1, F2, F3/F4 and focused workflows.
M3+B remains OPEN; approximately 40% qualified (30–50% engineering
uncertainty), not a measured language-conformance percentage. Group-aware
data/elimination, broader total/WF recursion, P0 closure coverage and the
P1 assumption incompatibility remain. PR #109 stays draft/open/unmerged.


## M3+B current candidate: selected P0 ordinary partial body execution (NOT qualified)

A new explicit `PsV7Native.Assurance` request/response distinguishes
`ordinary-checked` from unimplemented verified grades; verified
requests must fail without ordinary downgrade. After the **original**
canonical `partial` logical/core body is kernel-checked, the native
host's selected ordinary path alone pairs opaque public `f` with the
unique separately checked private `f.0` body (matching universes/type)
for runtime erasure, retaining the original logical graph untouched.
Generic library erasure still rejects partial markers. The focused
suite adds an independent pinned-Lean nonrecursive `partial` body
oracle, scalar two-input JS/TS/Rust/GC/Wasmtime runtime observations,
and explicit verified refusal. Detailed candidate contract:
`psc0/docs/PSCV0_M3_PARTIAL_P0_RUNTIME_CANDIDATE_2026-10-17.md`.

**Unqualified until own five exact same-commit gates.** Not general
partial recursion, model/body/target correctness, P1, effects, M4
verified assurance or full M3+B. Pinned v7.2/Lean 4.35.0,
no new assumptions, pskernel-core or selfhosting.

## Accepted common nested container ownership — 17 October 2026

Exact implementation `a7c6dade87a9d8df74d5248e8276623e7870078c` passed all five same-commit workflows:
native `38946629082` (33/33), F1 `38946629149`, F2 `38946629024`,
F3/F4 `38946629155`, focused `38946629090`.
Read `psc0/docs/PSCV0_M3_NESTED_SHARED_MODEL_QUALIFICATION_2026-10-17.md`.
`Ps.Core.Nested` now owns selected List/Option/Array/Prod field
shapes used by both source-positivity checks and checked canonical
recursor bridging; check-only Option/Prod oracles pass. Actual nested
recursive traversal/mutual/indexed group expansion is not closed.

The next **unqualified** P0 candidate will connect an independently
kernel-checked logical opaque `partial` declaration with its private
actual-body executable view *only for explicitly ordinary-checked builds*.
Verified requests must reject rather than downgrade. Preserve the
current partial blocker in generic compiler library entry points and the
canonical checking stream. This does **not** establish P1, verified
runtime correspondence, M4 effects or full M3+B.

## Accepted Array nested constructor adaptation — current checkpoint

**Compiler `8f217a80a6010b5db83affb5f608d494521b44bf`**: native
`38943289653` (33/33), F1 `38943289504`, F2 `38943289694`,
F3/F4 `38943289454`, focused `38943289601` all **SUCCESS**.
The subsequent test-only source SHA `59fa293d587e83c3c5fe6d9572debb82a385a30a`
passed focused `38943635308` including pinned native Lean oracle,
JS, compiled TS, Rust, V8 GC and Wasmtime for shallow `Array Rose`.
Read `psc0/docs/PSCV0_M3_ARRAY_NESTED_QUALIFICATION_2026-10-17.md`.
This is **not** nested recursion traversal, all-family deriving, P0/P1,
or full M3+B; old candidate-pending paragraphs are historical.
Next architecture priority: one common positive-container shape owner
across `Ps.Elab.Data` and `Ps.Bridge.CheckedAdmissions`, preserving
the exact pinned checked constructor fields and fail-closed boundaries.
M3+B remains OPEN; native portable .lean, no pskernel-core or self-hosting.

## M3 nested parameter validation — qualified; Array bridge candidate pending

Compiler `e3c3f8b6b9b2231b4bf69f4ae37bd2aa234b1cf9`: five exact same-SHA runs SUCCESS — native
`38941232123` (33/33 steps), F1 `38941232184`, F2 `38941232130`,
F3/F4 `38941232155`, focused `38941232165`. Receipt:
`psc0/docs/PSCV0_M3_NESTED_UNIFORM_QUALIFICATION_2026-10-17.md`.
Every nested family occurrence now checks the same Core uniform parameters
as a direct occurrence; nonuniform `BadNested(A)` under `List` refuses
at elaboration. Separate check-only `bde3dccd` and runtime `eb227eb6`
focused runs passed for one zero-parameter `List Rose` shallow
elimination case. This is NOT nested recursive traversal or deriving.

Current new candidate extends the checked nested recursor bridge for
`Array α` using Lean 4.35's exact `List α` backing field, with an
independent check-only `Array Rose` source/oracle. No assumption,
kernel-admission bypass, erasure shortcut or runtime speed claim.
**Candidate requires its own native/F1/F2/F3-F4/focused qualification.**
Current M3+B remains OPEN; continue canonical `psc0/ARCHITECTURE.md`,
v7.2-only .ps, native .lean, minimal tests, no pskernel-core/selfhost.

## Active architecture consolidation — 17 October 2026

`psc0/ARCHITECTURE.md` is now the single active native v7.2 architecture document for current implementation, target mechanisms, later-track non-goals and Lean 4.35 comparison; historical PSC2 text is preserved exactly in `psc0/docs/history/PSC2_MINIMAL_SELFHOST_ARCHITECTURE_SNAPSHOT.md`. Continue the six unchanged M3+B exits from the roadmap, beginning with one group-aware data/recursion validation owner. Source/CI receipts above remain independent; this doc commit makes no implementation or new qualification claim.

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

# Continue v7.2 M3+B — accepted structural child baseline

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

Reapply the attached user stage prompt and docs/PSCV0_V72_STAGE_DIRECTIVE_2026-10-16.md before each coherent slice. Fresh HEAD/CI/both handoffs, relevant v7.2 clauses and pinned Lean source/tests. v7.2 only for .ps; no legacy modes or native .lean restrictions. M3+B remains OPEN.

Accepted compiler **3fc077fd836e32b0d4250ea7b21183bb06897eab**, tree52d39bde0d280342e4ccadf5ba483ea88e5e2ca3. This receipt is a documentation-only child. All five exact runs SUCCESS: native38910660953/job117005717235/all33steps including setup/cleanup, F1 38910660803, F2 38910660921, F3/F4/platform38910661102, focused38910660969. Read docs/PSCV0_M3_RECURSIVE_DECEQ_QUALIFICATION_2026-10-16.md for accepted scope and previous failure history. Do not repeat completed qualification or use stale intermediate IDs.

Direct-recursive equality uses actual checked child decisions, constructor discrimination/congruence/proof transport, and no assumed self-instance/LawfulBEq/BEq-to-equality axiom/backend-specific primitive. The final RecursorLift fix keeps root eligibility on the raw forall/lambda entry prefix, matching erasure. Hidden alias-returned functions use the existing checked capture-preserving helper route. The native and focused gates now pass without changed assertions/budgets. Previous invalid oracle and erased-local failures are historical.

Next implement broader shared data/elimination/recursion: inspect existing nested/indexed/mutual support, motives/pattern matrices, structural/well-founded recursion and selected P0/P1. Do not claim all M3 from a completed deriving slice. All partial executable admission remains rejected; retain the independent inhabitant/public opaque/private actual-body marker. Never execute the witness, drop the marker, invent equations/totality, add Classical/Nonempty fallback, or downgrade verified requests.

Preserve BEq058fb67f, Repr/Hashable4501164e/docsad47, and M2 originalprofile73integration2a707206/docs280e receipts. v7.2blob694115223777599ba28ee175e14bb642b7b6aa4b/SHA256c65487eccbd2829d1d9e5e1be3bc7f4cb37849b841ab3257ea0dd47665b8a30e. Runtime133af061/paired38840337837 evidence9.25–10.11xfromList; deep-list/reversal remain unresolved. No new speed claim.

GitHub/cloud Linux ONLY; no local files/checkouts/shell/build/tests/Desktop Commander. Native portable .lean, official4.35.0eb6cafb7290e8bd5f2937522d8d804f58f02bafc; onlypropext/Quot.sound. No pskernel-core/self-hosting/compiler-source migration/C5/sorry/unchecked admission/weaker tests/larger budgets. GC internally/explicitABI. Fresh expected-HEAD/non-force writes, preserve concurrent histories, BOTH handoffs and exact receipts per slice. PR109 draft/open/originalbase, never merge. Continue M3+B -> M4+C/D -> M5+E without fabricated completion.


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

## In-flight HAdd infix conversion candidate: progress only admitted constraints

Candidate `bdd9cde559a2b9bc457b752c4d0685c9a172615c` built
native Lean, but focused `38933591612` still rejected `m3infixChild(k + 0)`
at the strict recursive child rule after adding a common checked-IH type
hint. The operator elaborator can leave ordinary instance/metavariable
constraints queued under postponement. This correction invokes the
existing `psElabProgressPending` **non-default** queue solver after
elaborating a computed major, then compares its Core term only with
actual strict constructor fields and their checked IHs. It does **not**
run final default-instance selection, force suspended source resolution,
replace the read-only definitional equality criterion, or expand the
logical foundation. The pinned oracle, equation, `k+1` negative and
runtime targets are unchanged. Both full native and focused same-commit
replays are required; this is NOT yet accepted or full M3+B.

## HAdd infix strict-child candidate: WIT export identity correction (qualification pending)

The prior `40b216a09fa20e737cfe2e02d78f28f5e86a4064`
candidate focused run `38934185882` reached native checked source
and passed direct JS, strict compiled TS and locked Rust execution.
Its only focused failure was the new fixture's mixed-case export
`m3infixOutput`: WIT correctly converted it to `m3infix-output`
and the exact unchanged ABI assertion expected the camel-case name.
The new export is now consistently **`m3infixoutput`** across native
oracle JSON, selected PSC source, generated JS/TS/Rust and WIT/GC/
Wasmtime comparison. This corrects fixture ownership, NOT compiler
semantics, and does NOT relax or remove the ABI assertion.
The computed-major synthetic-constraint queue is skipped when
empty; when work exists, it still uses the original non-default
`psElabProgressPending` solver before strict-child/IH validation.
Previously accepted Nat.sub and prefix-recursion receipts are intact.
Five exact-commit native/F1/F2/F3-F4/focused gates must all pass.
Overall M3+B remains OPEN; no self-hosting or pskernel-core.

## Next M3+B pattern-matrix qualification — two discriminants (focused only pending)

The current checked HAdd computed-major compiler `33c569e0` has
F1/F2/F3-F4 and focused green on its own SHA while its full native
workflow `38934640403` is in progress. Preserve this qualification
boundary. This **test-only descendant** adds one independent pinned
Lean 4.35.0 `Bool × Nat` multi-discriminant match oracle, selected
PSCV0 `m3matrixSelect` with native checked equation, and one
Bool→UInt64 observation for each input across existing
JS/TS/Rust/V8 GC/Wasmtime lanes. A deliberately nonexhaustive
two-column function must be refused at `PSCV0-MATCH: missing feasible
constructor branch` during elaboration. It reuses existing common
`Ps.Elab.PatternMatrix`/typed eliminator; no compiler implementation
is changed or positive result claimed before the focused run.
If the probe fails, fix the actual typed motive/pattern owner without
accepting erroneous branches or weakening refusal. M3+B remains OPEN.

## Next M3+B code candidate — uniform parameters through positive nested containers

At compiler HEAD, `Ps.Elab.Data` previously validated uniform parameters
on direct recursive fields only; its nested List/Option/Array/Prod acceptance
walker could encounter the same family with changed parameters without
applying `psElabDataIndices`. This change replaces that permissive boolean
walker with one bounded, common checked-occurrence validator. It reuses the
same universe/family/parameter telescope check for **every nested recursive
occurrence**, including both sides of `Prod`. Nonrecursive fields remain
unchanged. Indexed nested cases and unsupported variance still reject;
no nested IH, positivity axiom, new recursor, or new runtime capability is
invented. Official Lean 4.35 kernel checking remains authoritative.

The existing nested-family `deriving Hashable` refusal already traverses
a positively nested family, and its phase/rule are unchanged; one additional
deliberately nonuniform nested family must reject at the precise
`constructor parameters must remain uniform` elaboration rule. Minimal
focused CI and all native/F1/F2/F3-F4 gates are required before accepting
this bounded validation improvement. It is NOT complete general
mutual/nested recursion, deriving, M3+B, P0 or P1.

## Focused M3+B probe: check-only nested one-family elimination

After the preceding native `.lean` nested uniform-parameter validator
candidate, the inspected canonical admission bridge showed a bounded,
zero-parameter/zero-index nested adapter (`psCheckedNestedWrapper`) for
List/Option/Prod, distinct from the portable recursive deriving machinery.
This test-only child asks the **existing official native host** to check a
zero-parameter, strictly positive two-constructor `Rose` with a
`List Rose` field and a shallow `match`; the independently checked
pinned Lean oracle constructs an equivalent family and equation.
No target artifacts are requested: passing establishes only logical
inductive/recursor admission, not executable nested recursion/IR/ABI.
The initial actual recursive deriving/target runtime fixture and every
earlier exact-phase negative remain unchanged, with only a positive
batch request and its indexing added. Native kernel rejects imply
the bridge or recursor requires architectural work, never a gate bypass.
Full M3+B remains open; nested indexed/mutual groups, runtime/deriving,
P0/P1 and verified target behavior are not claimed.

## M3 bounded nested family runtime probe — qualification pending

The check-only `M3NestedRose` / `List M3NestedRose` source plus
shallow constructor match passed the focused kernel replay on
`bde3dccd` (run `38941701921`). This next fixture-only child
adds the same strictly positive no-parameter family to the existing
compiled multi-target source and exports `m3nestedoutput`, comparing
`leaf` and `node(List.nil)` against the independent pinned Lean
4.35.0 oracle for both Bool inputs. It tests Core admission, typed
erasure, IR checks, JS/strict TS/Rust/V8-GC/Wasmtime without adding
backend-specific recursion shortcuts. The bound is *one-level shallow
elimination over a nested field*, NOT general nested recursive functions,
nested deriving, indexed/mutual types, P0 or P1.
Original negatives and other runtime observations are unchanged.
If the existing erasure/runtime refuses, inspect the actual shared
runtime representation and report the unsupported boundary instead of
loosening an unrelated checker.

## Candidate: Array-nested shallow runtime (focused-only test, pending)

Following the successful check-only `Array Rose` admission on
`8f217a80` focused run `38943289601`, this **test-only** child
adds the same monomorphic `M3NestedArrayRose` to the existing selected
executable source and one `Bool → UInt64` observation:
`m3nestedarrayoutput`. For false it constructs `node(#[])`,
for true it constructs `leaf`. An independent pinned Lean oracle
computes both results; existing JS, strict TS, Rust, V8 GC core and
Wasmtime exact-output scripts check the new export without widening
ABI or weakening original assertions. A fully qualified check-only
inductive does not automatically mean its backend representation is
safe; any failure must be traced through shared erasure and IR instead
of inventing a backend value. This is shallow elimination, **not**
nested recursive traversal/deriving or the complete M3+B exit.

## M3+B candidate: one selected nested-container model (qualification pending)

New portable native `Ps.Core.Nested` is the sole owner of the
pinned Lean 4.35.0 List/Option/Array/Prod constructor-field shapes
and positive nested child positions. `Ps.Elab.Data` and the canonical
`Ps.Bridge.CheckedAdmissions` adapter now consume this same view,
rather than independently recognizing or encoding the containers.
The elaborator still checks uniform family parameters for each
occurrence and the official kernel checks all generated declarations.
No new constructor shape, induction hypothesis, axiom, recursion
strategy, erasure privilege, target ABI or benchmark budget was added.

The existing focused native-oracle and five-target fixture still tests
the accepted shallow List/Array runtime work. Two small, separately
check-only Option/Prod family requests and corresponding pinned-Lean
equations exercise previously untested bridge shapes, while all
existing phase-specific negatives and outputs remain unchanged.
Selected nested *shallow* checking is not nested recursive
traversal, deriving, indexed/mutual group support, P0/P1 or M3 exit.
Full native/F1/F2/F3-F4/focused same-commit gates are required
before acceptance. Preserve older qualified receipts and PR #109.

## Candidate: actual recursively calling partial runtime body — focused qualification pending

Original selected P0 ordinary host candidate `e6a14c86b11ee50570554ae75d371628d3759e0b`
passed focused/native Lean oracle/JS/strict TS/Rust/GC/Wasmtime
`38948302365` and F1/F2/F3-F4 on the exact code SHA. Full
native `38948302333` is still in progress; **not yet all-five accepted**.
This *test-only* descendant keeps the same compiler implementation
and adds pinned Lean `partialCount(n)` with a real recursive call on
a strict Nat predecessor, and source `partial function
m3partialCount(n)` plus two `Bool → UInt64` output observations.
Unlike the earlier nonrecursive partial body, this directly exercises
public source self-calls being bound to the actual executable body,
not the independent logical inhabitant. The logical declaration
remains opaque, no defining equation is admitted as proof, and the
explicit verified request still fails without ordinary downgrade.

Focus uses unchanged selected JS, TS, Rust, V8 GC and Wasmtime
paths and all previous phase-specific failures/budgets. The new
case validates only these bounded finite runs, not arbitrary
termination, diverging behavior, trace safety, partial_fixpoint P1,
model/body/target refinement, or full M3+B. Require its own focused
qualification before counting it; do not relabel the older native
run as belonging to this test-only descendant.

## Test-only next M3 data slice: shallow Option/Prod target representation

After accepted shared List/Option/Array/Prod `Ps.Core.Nested`
shape ownership and successful check-only Option/Prod family fixtures,
this child adds actual `Option.none` and `Prod.mk` nested
constructor values under a monomorphic self-family, then a shallow
checked match and two `Bool → UInt64` observations for each target.
Both outputs are compared against independent pinned Lean 4.35
`M3NestedOptionRose`/`M3NestedProdRose` oracles through existing
JS/strict TS/Rust/V8 GC/Wasmtime checkers, retaining prior scalar
observations, ABI and all phase-specific negatives.

This is source/IR/runtime evidence for shallow constructors, NOT
nested recursive traversal/deriving, parameterized indexed/mutual
groups, general effect/partial trace/refinement semantics or full
M3+B. The earlier P0 ordinary partial compiler `e6a14c86`
continues its own native qualification; focused recursive P0
`77f5fe75` passed independently. This test-only descendant
requires its own focused qualification and does not inherit the
earlier full native result. No new compiler semantic implementation,
kernel, assumptions, backend special cases or performance budget.

