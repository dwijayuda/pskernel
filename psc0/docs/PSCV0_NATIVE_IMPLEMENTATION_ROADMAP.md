## Authoritative current checkpoint — own-binder result families accepted, 2026-10-17

Accepted compiler/test SHA: `0e2f5c461d30457caee322b8135293597f55ac4b`.
All five gates completed successfully at that exact SHA. The accepted focused
total remains **960 actual comparisons**, and the weighted engineering estimate
remains **78/100**. The containing checkpoint changes documentation only.

The [result-family qualification receipt](PSCV0_M3_RESULT_FAMILY_QUALIFICATION_2026-10-17.md) records the
bounded inference rule, resource ownership, exact source/native cases, all
gates and artifacts, four failed host-build attempts and their repairs.
The [generic P0 receipt](PSCV0_M3_GENERIC_P0_RUNTIME_QUALIFICATION_2026-10-17.md) retains the preceding accepted
`82b248a3ee2cd9246756690db23b7dffd612e022` / 960 baseline. The
[independent WF receipt](PSCV0_M3_INDEPENDENT_WF_QUALIFICATION_2026-10-17.md) records the preceding 940 checkpoint.

### Complete same-SHA qualification

| Gate | Run | Job | Result |
| --- | --- | --- | --- |
| Native Linux | [39040588006](https://github.com/dwijayuda/pskernel/actions/runs/39040588006) | `117419140165` | SUCCESS; all 34 reported steps |
| Focused M3 | [39040587989](https://github.com/dwijayuda/pskernel/actions/runs/39040587989) | `117419139972` | SUCCESS; all 15 reported steps |
| F1 canonical model | [39040587981](https://github.com/dwijayuda/pskernel/actions/runs/39040587981) | `117419139877` | SUCCESS; all 10 reported steps |
| F2 logical operations | [39040588008](https://github.com/dwijayuda/pskernel/actions/runs/39040588008) | `117419139837` | SUCCESS; all 9 reported steps |
| F3/F4/platform | [39040587982](https://github.com/dwijayuda/pskernel/actions/runs/39040587982) | `117419140082` | SUCCESS; all 11 reported steps |

Native/focused completed logs contain 4,476,633 /
8,264,521 characters. Focused artifact 12103214519 has
286 files / 3,038,443 bytes, SHA-256
`31119835fc1aef644509103d290cf118f20577158864b03223327524da773ac8`.
Native artifact 12103729665 has 6,797,268 bytes,
SHA-256 `09a19655357ca975337902a831a3c7b86f9a4390ecca91676ae7aecec957aad1`.
All metadata matches completed upload receipts. Artifact ZIP contents were
not independently reopened.

### Newly accepted source behavior

An omitted result can now depend on a declaration's own resolved binders.
The result is a natural family in the enclosing scope, applied to the original
arguments. Body inference and checked caller constraints reach the same
family. The complete own telescope is resolved before peer headers enter;
explicit main result holes retain their distinct refusal, while selected
local explicit holes can use body inference.

The unifier applies the rule only to a marked, natural, unassigned,
non-delayed metavariable at its exact full argument spine. Distinct actual
bindings can be abstracted in application order. A constant approximation must
fit the family creation scope and its declared type. Both paths retain type,
occurs and scope checks and retry the complete original equality before
committing. Scope-argument metadata survives template export/replay.

An unresolved index retains its full saved creation scope. A blocked family
cannot fall through to application congruence and guess R := Fin / index := n.
Failed comparisons restore term/universe assignments, declaration/allocation
state and delayed state. Ordinary conversion can still unblock a family.

Application, lambda, record, tactic and fixed-index match owners recognize a
full unknown family. Caller constraints, defaults, saved scopes, dependent
context refusal and final checked recursor construction remain. Solved
families are beta-reduced before capture closure. Every final type/body and
official-kernel check is retained.

Actual resource failures propagate through the migrated instance, synthetic,
checked-queue and elaborator owners. A checked queue stops before another
item/default, restoring original context and pending order while retaining
consumed attempt counts. Existing compatibility wrappers and low-level fuel
policies remain; this is not a global resource-policy rewrite.

### Actual source and native evidence

The focused source step compiled 668 jobs and ran 14 outer fixture commands.
The result-inference fixture compiled 19 independent pinned native equality
examples and checked 19 source theorems, 18 closed total definitions and the
original three opaque/private partial pairs. Its source-only successful request
produces no executable artifacts; six negative requests fail at their exact
elaborate-phase owners.

Cases include direct Fin(n + 1), forward application at n + 1, a qualified
helper without unused parent capture, explicit Nat observation, saved tactic,
caller-directed OfNat producing token value 23, fixed-index matching, record
resumption and an own Type u binder. Original defaults, solved headers,
closures, mutual total/partial bodies, captured parameters and source printing
remain. Native partial controls return 4/4/6. The main Where request batch retains
seven requests (one five-target success, six refusals); its separate inherited
partial-hint batch retains eight (one source-only success, seven refusals).

Native adds 151 lines with its prior source byte-for-byte preserved. Actual
completed output confirms checked family/universe assignment; a blocked
pending index without scope pruning or speculative assignments; checked
resumption; a productive equality control and full later-failure rollback.
A real zero-fuel inference error survives postponement and checked draining,
while preassigning the same default permits the same continuation to succeed.

The four initial matrices failed during host compilation. Repairs addressed
record-field alignment, an outdented conditional and an annotation branch's
enclosing early return. The comma-only first repair was insufficient.
No source fixture, assertion, oracle, workflow or resource budget was weakened.

### Retained source, trust and runtime evidence

All 56 retained runtime PASS markers match the accepted P0 baseline exactly:
26 scalar ECMA, 13 scalar Rust, 13 scalar Wasm, plus 2/1/1 for original deriving.
Each scalar suite runs both flags; each Wasm marker covers V8 core and
Wasmtime components. The total remains 72 scalar exports / 720 comparisons
plus 24 original deriving exports / 240 comparisons: 96 exports across five
execution modes, 960 observed comparisons.

Generic P0 retains both entries at Nat/Bool with dictionaries and seeds in
one module, Nat false/true 2947/4123 and Bool false/true 12/21. Both verified
requests refuse without executable artifacts; ordinary observations grant no
partial-body logical equation or verified backend correspondence. The shared
runtime runner and all emitted fixture sources are unchanged in this slice.

The original WF fixture retains 21 requests (two positive, 19 exact refusals)
and 38 printed approved assumption closures. All 10 Where closures are also
approved. The P0 generic native closure check and P1 Classical.choice refusal
remain. Independent WF capture and checked-equation construction stay covered.

Native retained the Standard at 3,633 declarations/41 classes/359 instances,
FNV 4990397000639020696 and Standard SHA-256
5e96678b7ca94ac8dcb63d36cee81c5997287f507ce8c0c26d28321b37ce97d7.
The real three-module application, 1,069 shared observations in direct JS,
compiled TS and Rust, repeated Wasmtime calls/post-return, 100,000/50,000
generic Nat/Bool steps and M1 JSON sourceSha at the accepted commit all pass.

### Engineering estimate and next bounded source cell

The accepted rubric stays data 25/30, source 14/15, total recursion 16/20,
P0 13/15, P1 1/10 and integration 9/10, totaling 78/100. The earlier source point
already grouped optional result inference with inherited-partial hint fidelity.
No additional point is awarded for syntax repairs, regressions or source-only
examples.

The next concrete source obligation is unused-hint diagnostic parity for a
checked nonrecursive Where helper. The current ordinary-unused-unknown-measure
fixture still refuses an unknown measure in a nonrecursive helper body.
WhereScope scopes the suffix before the typed PreDefinition component graph
can establish nonrecursion. Pinned Lean Main processes a nonrecursive member
first and TerminationHints.ensureNone warns without elaborating the unused
hint. Reconcile those existing owners while retaining raw suffixes/spans,
checked header/body dependencies, capture closure, active recursive
measure/proof checks and original-main compatibility. Do not infer
nonrecursion from a superficial source-name scan.

This inference remains bounded. Checked constant approximation is eager;
arbitrary application inversion, general higher-order completeness and new
scheduling/backtracking remain outside its acceptance. Some dependent or
ambiguous callers may require annotations. Broader indexed binary deriving,
nested/source induction, larger changing WF packs, arbitrary measure
telescopes, general mutual WF and the full P0 matrix remain open.

### Fixed authority and continuation policy

M3+B, M4 and M5 remain open. Only propext and Quot.sound are approved.
P1 stays unavailable because of its audited Classical.choice dependency.
Lean remains 4.35.0 `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
The sole forward authority is psc0/PSCV0_LANGUAGE_REFERENCE_v7.2.md,
blob `694115223777599ba28ee175e14bb642b7b6aa4b`.

Use connected GitHub and cloud Linux only. Verify live HEAD before each write
and use expected-HEAD non-force updates. Let healthy Native CI finish before
another compiler/test push. Every new compiler/test candidate needs all five
gates at one exact SHA. PR #109 stays draft/open/unmerged on its original base.

## Historical checkpoints — superseded by the checkpoint above

The retained material below records earlier candidates and decisions.
Old current/pending/accepted-SHA statements are historical; the current
candidate and the qualified baseline are explicitly distinguished above.

## Current checkpoint — active foundation replay preserved, next matrix pending

[Native 39000431708](https://github.com/dwijayuda/pskernel/actions/runs/39000431708)
at `3c5f51a2ffdc9cabfe386ab6fd1c7a1bb82e6ff5` completed successfully:
all 34 reported steps passed. The independent audit confirms all 34 foundation
additions active, no candidate axioms, three checked recursor rules, 3,633
declarations, 41 classes and 359 ordinary instances. Observed FNV, declaration
SHA-256 and surface SHA-256 exactly match the independently measured activation
pins. Original source/Standard, modules, GC/components, TypeScript, Rust, repeated
Wasmtime and measurements all passed. Native artifact `12088873997` is
6,797,540 bytes, digest `sha256:ea7b06cce1a363b24de67f9a9441531ab93121e1b69cbaddc2adfa32085af7f4`.
The [foundation receipt](https://github.com/dwijayuda/pskernel/blob/psc0/pscv0-v7-native-lean-v1/psc0/docs/PSCV0_M3_WELL_FOUNDED_FOUNDATION_AUDIT_2026-10-17.md)
now records both the proposed audit and this completed activated replay.

F1, F2 and F3/F4 also passed at `3c5f51a2`. The focused suite compiled all
668 jobs and passed the previous source checks, result inference, generic
lexicographic fix/equations and indexed Inhabited. Its sole failure was the
empty-producer fixture's bare-variable guard pattern; the compiler correctly
retains its checked Boolean equality decision in raw IR. The exact pattern is
corrected without production changes; no five-target parity is credited yet.

The next combined candidate retains separate linear commits for dependent
argument packing (`dea57c8d`), inherited-partial hint scoping (`af5bf403`)
and the empty guard fixture repair (`ebf6e8c1`). Independent implementation
reviews and exact file/hash reconciliations are complete. Run all five gates at
the final combined compiler/test SHA, investigate any concrete failure and record
acceptance only when every required gate passes there. The current failed matrix
is not accepted, and the already completed native result is preserved.

Accepted compiler/test remains
`03000e7b0c257fb8f8d2e2b387b7b65a53e8f504`, weighted **74/100**, M3+B open.
The source authority, Lean 4.35.0 commit, approved `propext`/`Quot.sound`,
P1 `Classical.choice` block, cloud-only execution and PR 109 draft/open/unmerged
status remain fixed. Historical preparation entries below retain their status
at the time they were written.

## Current focused fixture repair and next combined qualification — 2026-10-17

At `3c5f51a2ffdc9cabfe386ab6fd1c7a1bb82e6ff5`, F1
[39000431683](https://github.com/dwijayuda/pskernel/actions/runs/39000431683), F2
[39000431695](https://github.com/dwijayuda/pskernel/actions/runs/39000431695) and F3/F4
[39000431730](https://github.com/dwijayuda/pskernel/actions/runs/39000431730) passed.
Native [39000431708](https://github.com/dwijayuda/pskernel/actions/runs/39000431708),
job `117302002147`, remains active at this preparation; the activated
foundation audit, admitted Standard and module checks have passed.

Focused [39000431684](https://github.com/dwijayuda/pskernel/actions/runs/39000431684),
job `117302001981`, compiled all 668 jobs. It passed the existing source suites,
result inference, real Nat/generic lexicographic fix and public equations,
indexed Inhabited construction and refusals. The last empty-dictionary fixture
failed its raw producer-body assertion; target runtime comparisons were skipped.

The failure is an exact fixture-shape mismatch. `Ps.Elab.Conditional` constructs
`Bool.decEq flag Bool.true` for a Boolean source condition.
`Ps.Erasure.Expr.psEraseDecisionApplication` preserves the actual decision as
`.intrinsic .boolEq [] [.var flag, .literal (.bool true)]`, and
`psCompilerVerifiedIrFromPrepared` returns that raw erasure before backend
optimization. The fixture previously expected a bare variable. This repair
requires the exact existing equality guard, the original runtime parameter and
both correctly named empty-record branches. It changes no production owner,
native oracle, export, refusal or nominal-value/evaluation contract.

The separately reviewed two-dependent-argument packing and inherited-partial
hint-scoping changes precede this fixture repair as distinct commits. Their
construction, fixtures and limits are recorded below. They remain unqualified;
the former adds ten target comparisons, and the latter adds eight nested
source-only requests while preserving every existing Where export.

After preserving the completed native result, qualify the combined candidate
through all five cloud gates at one compiler/test SHA. No partial source success,
audit step or reviewed implementation adds accepted points before that matrix.
This groups a demonstrated fixture-only repair with the reviewed next slices;
the current failed matrix is not promoted to acceptance.

Accepted compiler/test remains
`03000e7b0c257fb8f8d2e2b387b7b65a53e8f504`, weighted **74/100**, M3+B open.
Only `propext`/`Quot.sound` remain approved; P1's `Classical.choice`
block, Lean 4.35.0 pin, cloud-only execution and draft/open/unmerged PR 109 remain.

## Prepared inherited-partial hint scoping repair — 2026-10-17

The existing scope pass resolved a local `termination_by` measure before choosing
the helper's inherited partial strategy. That incorrectly rejected an unknown
measure name even when every original main declaration was compatibly partial and
the pinned native compiler would leave the local suffix unused.

`Ps.Elab.Command` now applies the existing original-main modifier check after
duplicate/private-name preparation and before member scoping. Only after that
check succeeds does it pass inherited partial intent. `Ps.Elab.WhereScope`
uses a default-false flag to preserve the exact raw local total suffix while
collecting no used names from it in that bounded case. Main/local headers,
local bodies, parent termination clauses, ordinary hint scoping, later strategy
checks and actual capture dependency closure retain their existing owners.

The pinned native sequence is documented by
[MutualDef.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/MutualDef.lean),
[PreDefinition/Main.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/PreDefinition/Main.lean)
and
[TerminationHint.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/PreDefinition/TerminationHint.lean):
validate original main modifiers, inherit partial intent, choose partial before
termination-hint elaboration, then issue unused-hint warnings without name resolution.

The existing Where fixture adds eight nested source-only requests: one positive
and seven phase-specific controls. Its original seven requests, six exports and
runtime batch remain; the outer fixture count stays 14. The positive checks two
recursive helpers and a disconnected partial peer, unknown measure/proof names,
native values 33 and 50, real base captures and original public binder order,
four closed opaque/private-body pairs, recursive self references, no invented
`eq_def`, and local provenance. It compares retained measure/proof text and
byte/line/column spans and excludes hint-only used names.

The seven controls retain unknown active measures, unknown active decreasing
proofs, an ordinary nonrecursive unknown measure, unknown local/main headers,
an unknown local body, and mixed original-main modifiers. Active proof names are
re-scoped by `GoalSource.psProofSource` in the actual goal context; the expected
error is `PSCV0-SCOPE: unknown name missingProof`. Ordinary nonrecursive hint
parity is explicitly outside this bounded repair.

The three exact candidate files were independently reviewed and reconstructed from
verified canonical GitHub blobs after a scratch transport outage. Root separately
matched all byte counts, SHA-256 and Git blob identities before preparation:

| File | Bytes | SHA-256 | Git blob |
| --- | ---: | --- | --- |
| `psc0/packages/elab/src/Ps/Elab/Command.lean` | 29542 | `93dc5244adb21f97a6b65c486cfe3d13dc9929cf2873a56b6ba40b45da39d2ef` | `d51fdee11c8e92e069b216cbff3783316f01a2f8` |
| `psc0/packages/elab/src/Ps/Elab/WhereScope.lean` | 7681 | `54479332ce1bb8da9958a80d1d20e0f1123808f44dd1fc02762be119ebe7a3af` | `02ee7700560453efe1084ec6a43f5462d734c8c8` |
| `psc0/test/Pscv0M3Where.lean` | 46173 | `08c5536cbf5a550fa3eed948c809f03c6798123a73a560ee250d37af9721ae05` | `73c5176b0ce9af6695d0d8cca83e4388298e2e0b` |

This changes source fidelity within existing P0 behavior; it introduces no runtime
mechanism, new logical assumption or P0 closure. Full cloud compilation and the
same-SHA five-gate matrix remain required. At this preparation, the separately
reviewed dependent packing commit is also an unqualified candidate.

Accepted compiler/test SHA remains
`03000e7b0c257fb8f8d2e2b387b7b65a53e8f504`, weighted **74/100**, M3+B open.
The pinned Lean/toolchain, approved `propext`/`Quot.sound`, P1
`Classical.choice` refusal and PR 109 draft/open/unmerged boundaries remain fixed.

## Prepared dependent argument packing candidate — 2026-10-17

This candidate follows the activated generic relation implementation. It extends
the selected single-function WF route to exactly two dependency-ordered changing
header binders, when the second binder's type depends on the first and the explicit
fixed-codomain measure requires that pair. Fixed parameters and captures stay
outside the pack. First-only measures keep their established unary dependent-state
route. Independent tuples, a third changing binder, mutual PSum packing and
changing measure codomains remain refused.

The logical owner constructs and checks the actual one-layer `PSigma` type,
constructor and eliminator, real `WellFounded.fix` and `fix_eq`, and public
curried equation. A nested user PSigma field is not flattened. Callback equality
eliminates the actual pair and retains the entire dependent proof-binder function
inside the motive before existing checked `funext`, `congrArg` and `Eq.trans`.
There is no pair-eta assumption or new conversion rule.

Typed erasure recognizes only the same fully checked root/fix/domain/constructor
and two distinct original header IDs in source order. Its shared exact adapter
view checks the complete dependent callback type, capture closure and entry result
before replacing that adapter with the same-typed curried public-self callback.
It requires at least one replacement and refuses any remaining raw callback.
Arguments retain original header positions, including interleaved fixed parameters,
single evaluation and the explicit erased proof slot. Ordinary runtime beta
reduction and backend layouts are unchanged.

The existing WF fixture retains every prior request/export and adds native/source
packed examples, including dependent Fin results, open public equations, actual
Core proof/adapter checks, and malformed reversed/duplicated/foreign pack-field
refusals. Its batch becomes 21 requests (two positives and 19 refusals), with the
fourteenth export `m3wfpackedoutput`: ten additional comparisons over two Boolean
inputs and five targets. Three-changing-argument and varying-codomain source
refusals remain explicit; the previously blocked dependent-domain example now
reaches its actual false-decrease obligation and remains refused there.

The original independently reviewed seven-file patch has SHA-256
`0dfb9d68393fb9b707e0d27ec71d84e40da8d3222eec8b7c8d3e82c882e0afe7`.
All frozen base/candidate byte counts, SHA-256 and Git blob identities were
independently reconciled before this preparation. This candidate carries forward
the cloud-proven generic syntax repair from `3c5f51a2`: reserved `meta`
binders are renamed to `metaContext`, including the three new packing helpers,
and the shared returned record fields are explicitly aligned. The frozen source
hash is historical; the prepared candidate's Meta bytes therefore differ.

At preparation, F1, F2 and F3/F4 passed at
`3c5f51a2ffdc9cabfe386ab6fd1c7a1bb82e6ff5`; native and focused qualification
were still running. This staged packing implementation has not been compiled or
executed. Full same-SHA five-gate success remains required before acceptance.
The separate partial-hint scoping patch has completed static review and integrity
reconciliation but is not included in this packing commit.

Accepted compiler/test remains
`03000e7b0c257fb8f8d2e2b387b7b65a53e8f504`, weighted **74/100**, M3+B open.
P1 remains blocked by `Classical.choice`; only `propext` and `Quot.sound`
are approved. Lean 4.35.0, cloud-only execution and PR 109 draft/open/unmerged
status remain fixed.

## Current compilation follow-up — 2026-10-17

The activated relation candidate `25ceded396878ce16b5effc25886b069c5ee0238`
failed all five gates during compilation.
[Native 39000205978](https://github.com/dwijayuda/pskernel/actions/runs/39000205978),
job `117301338195`, and
[focused 39000205972](https://github.com/dwijayuda/pskernel/actions/runs/39000205972),
job `117301338355`, report two source syntax defects in the new shared Meta
relation owner: the reserved `meta` token was used as a binder, and two
multiline returned structures had insufficient field indentation. This follow-up
renames the binder to `metaContext` and writes the record fields explicitly.
The typed construction, evidence checks, requests, oracles and observed
foundation pins are unchanged. Runtime qualification has not run at this candidate.
A fresh full same-SHA matrix is required.

Accepted compiler/test SHA remains
`03000e7b0c257fb8f8d2e2b387b7b65a53e8f504`, weighted **74/100**, M3+B open.
The completed foundation audit at `078fb1e2` remains valid evidence for its
proposed identities. PR 109 remains draft/open/unmerged.

## Current checkpoint — audited WF activation candidate, 2026-10-17

This checkpoint supersedes the historical status entries below. The latest fully
accepted compiler/test SHA is still
`03000e7b0c257fb8f8d2e2b387b7b65a53e8f504`, weighted **74/100**, M3+B open.

Native [38998692067](https://github.com/dwijayuda/pskernel/actions/runs/38998692067)
at `078fb1e2c22f79e7f4eae2f21863e2cad4fa1434` is now complete:
all 34 reported steps succeeded, including exact WF asset regeneration,
initialized independent metadata/kernel audit and every original native workload.
F1, F2 and F3/F4 also passed at that SHA. Focused
[38998692088](https://github.com/dwijayuda/pskernel/actions/runs/38998692088)
failed at one native indexed parent-pattern refinement; its generalized observer
repair is the linear commit `75be0cabaa4885e98362712b61b88be5fd0cd5d5`.

The following relation-selection commit
`490a4dfcac81e42a56eeb6121112c3e20e2731e2` adds actual fixed-codomain
`WellFoundedRelation` synthesis, typed generic fix/equation construction and
matching erasure, with native/source lexicographic left/right evidence and ten
additional target comparisons. Its existing unary changing-argument boundary
remains. Separate dependent argument packing is not included.

This activation extends the selected Standard from its unchanged frozen pre-WF
input. It uses exactly the completed independent audit's observed pins:

- FNV: `fnv1a64:4990397000639020696`.
- Declaration SHA-256: `sha256:5e96678b7ca94ac8dcb63d36cee81c5997287f507ce8c0c26d28321b37ce97d7`.
- Surface SHA-256: `sha256:7a996cfc6253693799d43fdcf78dd7f30eb0713a3eb31831daa9d804faf818c6`.

The audited extension has 3,633 declarations, 41 classes and 359 ordinary
instances, with 34 added declarations, zero candidate axioms and three checked
recursor rules. At the audit SHA, none of those additions was active.
The audit's `runtimeQualified: false` does not count as activated runtime
qualification. The [foundation audit receipt](https://github.com/dwijayuda/pskernel/blob/psc0/pscv0-v7-native-lean-v1/psc0/docs/PSCV0_M3_WELL_FOUNDED_FOUNDATION_AUDIT_2026-10-17.md)
records the exact JSON, native artifact, frozen boundary and evidence limits.

Next: run all five gates at the final activated compiler/test SHA, repair concrete
failures, and record acceptance only after every gate succeeds there. The
result-inference, indexed Inhabited, nominal empty dictionary and generic relation
changes remain cumulative candidates until that matrix passes. Then integrate
the separately reviewed dependent packing patch
`0dfb9d68393fb9b707e0d27ec71d84e40da8d3222eec8b7c8d3e82c882e0afe7`
and qualify again. The source partial-hint scoping follow-up is independently
under review and is not part of this activation.

Lean 4.35.0 and its pinned commit, the forward v7.2 authority, only approved
`propext`/`Quot.sound`, P1's `Classical.choice` block, cloud-only execution and
PR 109 draft/open/unmerged status remain fixed.

## Historical implementation checkpoints

## Latest compiler build follow-up

The candidate `e9b2075e9898ffd2e7561e6f4faafae95ff96cfa` failed all five
cloud gates during compilation. [Native 38997375085](https://github.com/dwijayuda/pskernel/actions/runs/38997375085)
and [focused 38997375006](https://github.com/dwijayuda/pskernel/actions/runs/38997375006)
report one error in DerivingInhabited: an immutable `value` shadows its mutable
accumulator. This follow-up names that accumulator `constructorValue`; the
algorithm, requests, assertions, native oracles and runtime exports are unchanged.
The indexed/default fixtures and initialized metadata audit have not yet run at
this candidate. A fresh complete matrix is required. The accepted compiler/test
SHA remains `03000e7b0c257fb8f8d2e2b387b7b65a53e8f504`, **74/100**.

## Current M3+B candidate — indexed defaults, empty dictionaries and metadata audit repair

Latest fully accepted compiler/test remains
`03000e7b0c257fb8f8d2e2b387b7b65a53e8f504`, engineering estimate **74/100**.
All five complete gates at one compiler/test SHA are required for any new
acceptance. M3+B remains open.

### Last completed matrix

At `8456aa25ba3320baf9394185436a536563f79483`:

| Gate | Run | Result |
| --- | --- | --- |
| Native Linux | [38993828912](https://github.com/dwijayuda/pskernel/actions/runs/38993828912) | FAILURE in the proposed foundation metadata audit; later default-success workloads skipped |
| F1 | [38993828876](https://github.com/dwijayuda/pskernel/actions/runs/38993828876) | SUCCESS |
| F2 | [38993828857](https://github.com/dwijayuda/pskernel/actions/runs/38993828857) | SUCCESS |
| F3/F4 | [38993828873](https://github.com/dwijayuda/pskernel/actions/runs/38993828873) | SUCCESS |
| Focused M3 | [38993828837](https://github.com/dwijayuda/pskernel/actions/runs/38993828837) | SUCCESS, including result inference and every existing target lane |

The missing Lake roots and fixture typing failures are resolved. Focused job
117281812142 prints `PSCV0_M3_RESULT_INFERENCE: PASS`: omission/main-hole/local-hole
ownership, printing, closed total/partial headers, captures and exact refusals.
All 13 original outer fixtures passed. This is evidence, not an accepted SHA.

Native job 117281812537 regenerated the exact foundation asset: 34 declarations,
zero candidate axioms, three native recursor rules, 2,329 shared source nodes and
466,947 bytes. SHA-256:
`b6bd56c4ab6378905d1d3ac2f0155eb5bc4742be3e19e684d64ac1a3007716f3`.
The byte comparison and 34 native Core/reducibility comparisons passed; the
next check reported `WF foundation class metadata differs: SizeOf`.

### Three separate linear implementation changes

1. **Metadata audit initialization.** Pinned
   [Lean.Environment](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Environment.lean)
   documents that `importModules` defaults to `loadExts := false`: declarations
   remain available, but class/instance extensions retain initial state. The
   host-only audit now uses the documented initializer lifecycle and
   `loadExts := true`. Exact class/out-parameter/output-level, instance priority,
   synthesis, Core, reducibility and kernel comparisons remain. No absent
   metadata is defaulted away. The active Standard and every pin remain fixed.

2. **Indexed Inhabited.** The existing owner opens the complete constructor field
   telescope as typed metavariables, unifies its result with the requested
   family, then fills remaining fields with checked defaults. Native constructor
   order, two passes, uniform-parameter-only requirements, ordered registration,
   final type checking and closure are preserved. The new helper has four
   indexed native/portable families, four instances, four complete recursor
   signatures, four generic equations, eight kernel output equations, four paired
   refusals and four scalar exports on two inputs; it requires zero workers.
   Existing GroupProof retains six instances, thirteen signatures, two groups
   with two workers and three captures each, and four exports. An obsolete
   direct-member Inhabited refusal is replaced by the same-origin full-group
   arbitrary-index refusal with paired native evidence. Seven effective
   refusals and six existing exports remain; BEq/DecidableEq checks are intact.

3. **Nominal empty dictionaries.** The ordinary definition filter retains a
   dictionary producer only when its actual return family has an already
   prepared, matching, fully applied boxed structure layout with zero retained
   fields. Existing nominal types, records, producer/forwarding/initializer
   calls, argument slots and typed IR own execution. Nonempty specialization,
   proof/type erasure, foreign restrictions and backend representations remain.
   The new executable has three host requests: a five-target positive program,
   an incorrect-proof refusal and a validating-adapter refusal for foreign
   proof-bearing dictionary results. Four exports cover relation dictionaries,
   closed initializers, an ordinary empty structure and a nonempty control.

All original 13 outer source invocations are retained; the empty fixture makes
14. Indexed and empty outputs require 80 additional scalar comparisons across
five targets. These changes have independent static review and still require
their actual complete cloud matrix.

### Next work and fixed boundaries

Use only a successful audit's observed Standard FNV, declaration SHA-256 and
surface SHA-256 to activate the foundation. The separately reviewed generic
relation candidate then constructs the actual dictionary inverse image and
Nat/generic fix/equation through one typed owner; its unary changing-argument
boundary and existing dependent-state route remain. It is not integrated by
this checkpoint. Checked PSigma packing for two dependent measured arguments is
being implemented separately with original curried calls and source equations.

Broader indexed binary deriving, positive/function containers, dependent/mutual
WF exits, remaining P0 work and final integration remain. P1 is still blocked by
Classical.choice; only propext and Quot.sound are approved. M4+C/D and M5+E stay
open. Connected GitHub and pinned cloud execution remain canonical. The user
has explicitly authorized GitHub access going forward. PR109 stays draft, open
and unmerged on its original base, with history preserved.

## Current build correction — foundation roots and fixture typing

The predecessor `4f31ce951d4d599b52a08fc4b607fb63fb8e5298` failed all five
cloud gates during compilation. [Native run 38993252190](https://github.com/dwijayuda/pskernel/actions/runs/38993252190)
reported that `Ps.Environment.StandardWellFounded` had no built object.
[Focused run 38993252168](https://github.com/dwijayuda/pskernel/actions/runs/38993252168)
also reported two underconstrained patterns in the new result-inference fixture.

This follow-up registers both prepared Environment modules in the parent Lake
library's explicit roots and gives the fixture's parsed declaration projection
and batch result patterns their concrete existing types. The production
optional-result modules compiled at the predecessor. These repairs change no
source request, assertion, oracle, runtime export or admission policy.
The proposed Standard remains inactive and its identity observations have not
yet run. A fresh complete same-SHA matrix is required.

The accepted compiler/test SHA remains
`03000e7b0c257fb8f8d2e2b387b7b65a53e8f504`, score **74/100**.
The prior checkpoint below retains its accepted receipt and candidate design;
its earlier pending build observation is superseded by this correction.

## M3+B current roadmap checkpoint — source/deriving accepted; foundation audit and main inference pending

Latest fully accepted compiler/test:
`03000e7b0c257fb8f8d2e2b387b7b65a53e8f504`.
All five gates passed at that exact SHA:

| Gate | Run | Result |
| --- | --- | --- |
| Native Linux | [38991805487](https://github.com/dwijayuda/pskernel/actions/runs/38991805487) | SUCCESS, all 34 reported steps |
| F1 | [38991805477](https://github.com/dwijayuda/pskernel/actions/runs/38991805477) | SUCCESS |
| F2 | [38991805491](https://github.com/dwijayuda/pskernel/actions/runs/38991805491) | SUCCESS |
| F3/F4 | [38991805538](https://github.com/dwijayuda/pskernel/actions/runs/38991805538) | SUCCESS |
| Focused M3 | [38991805453](https://github.com/dwijayuda/pskernel/actions/runs/38991805453) | SUCCESS, all 15 reported steps |

The exact receipt is
`docs/PSCV0_M3_SOURCE_GROUP_DERIVING_QUALIFICATION_2026-10-17.md`.
It qualifies the accumulated shared predefinitions, source-local where/capture/
SCC work, nested Repr/BEq and direct mutual DecidableEq/ordered group Inhabited.
The original native workloads, 13 outer source fixtures, exact worker invariants,
open checked equations, native strings and every five-target lane passed.

The accepted M3+B engineering estimate is now **74/100**, approximately **70–75%**.
Contributions are data 24/30, source 13/15, total recursion 14/20, P0 13/15,
P1 1/10 and integration 9/10. This is not measured language coverage.
M3+B, M4+C/D and M5+E remain open. Neither candidate below adds accepted points.

### Current candidate lineage and reviewed changes

This compiler/test candidate descends from preparation commit
[`ff97dd3d`](https://github.com/dwijayuda/pskernel/commit/ff97dd3d904f824da9c097491571dbdb7f9240e7),
whose parent is the accepted `03000e7b`. The preparation and main-inference
changes are separate linear commits; their combined tip requires the full
five-gate matrix. Fetch fresh PR #109 HEAD before every subsequent write.

The WF preparation imports the exact **34-declaration**, **466,947-byte** asset,
SHA-256 `b6bd56c4ab6378905d1d3ac2f0155eb5bc4742be3e19e684d64ac1a3007716f3`.
`StandardWellFounded` assembles a proposed logical environment with the two
actual classes, four ordinary instances, native priorities/reducibility and
the `sizeOf` export alias. `Nat.lt_wfRel` and `emptyWf` are named reducible
dictionaries, not instance registrations; `instSizeOfDefault` is an ordinary
low-priority instance, not a `default_instance`.

The existing authoring step now compares regenerated data byte-for-byte and
runs `--check-well-founded-foundation`. The audit independently reexports
every stored declaration from pinned native Lean, compares full Core and
metadata, exercises real instance selection, replays the strict kernel and
three actual recursor rules, and reports prospective FNV/declaration/surface
fingerprints through their existing owners. Active Standard, all expected
identity pins and runtime selection remain unchanged. Successful preparation
must report `activeFoundationDeclarations: 0`. Do not guess prospective pins.

Optional main results now have declaration-only `.omittedType` syntax,
distinct from an explicit `:_`. Selected def/function/const and partial
heads route omission through the existing typed predefinition owner; generic
term elaboration does not manufacture an inference hole from the marker.
The known result metavariable is allocated before the main's own binders.
An own-binder-dependent inferred codomain still needs an annotation.

Pinned `MutualDef.elabHeaders` requires unresolved term holes in explicit
main headers to be solved before the body; `LetRec` has the distinct local
boundary. Direct and shared main header owners now enforce that distinction,
while local `:_` inference remains. A later-binder constraint may still solve
an earlier header hole. Both declaration printers and the corresponding
narrow Lean reader preserve omission rather than printing `:_`.

The new `Pscv0M3ResultInference` check is invoked inside Where. It adds exactly
**six source-only requests** (one positive and five refusals), eight omitted
total heads, three omitted partial heads, one header-solved regression, nine
native total equations and three native partial scalar checks. Original Where
seven-request/six-export and all 13 outer invocation contracts remain.
The original native semantic corpus still has four successes and 92 refusals.
Its `declared` fixture now writes `Nat` explicitly, retaining the name/value
12; the paired native `def explicitHole : _ := 12` rejection guard must pass
before this semantic correction is qualified. No new portable runtime result
is claimed from the source-only inference batch.

Optional abbrev results retain their existing registration limitation; opaque
and theorem headers remain explicit in the selected source grammar. Broader
dependent result inference, legacy direct-module inference, P1 support and
runtime WF dictionaries are not supplied by this slice.

### Next executable work

Inspect all five automatically triggered runs at the combined candidate HEAD.
Repair any actual failure without changing the expected values or gates.
If all five pass, record the exact source acceptance and independently observed
WF audit JSON. Activate `psStandardWellFoundedExtend` after the frozen
`psSelfHostProdPreWellFoundedPreludeEnvironment` boundary, using only the
reported FNV, declaration SHA-256 and surface SHA-256 in their existing owners;
then qualify that active Standard at one SHA.

Three further independent candidates are under preparation/review:
constructor-directed indexed Inhabited through result-first unification;
checked nominal empty dictionary definitions through existing layouts; and
typed generic relation selection/fix construction at the current one-changing-
argument boundary. They remain unqualified. Dependent unary packing, broader
mutual WF, indexed binary deriving, remaining P0 and final integration remain.

P1 still fails closed: pinned `Lean.Order.CCPO.csup`, `Lean.Order.fix` and
the native Unit/Option equations require `Classical.choice`. Only
`propext` and `Quot.sound` remain approved. Preserve the exact dependency audit.

Native Lean 4.35.0 / `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`;
language v7.2 blob `694115223777599ba28ee175e14bb642b7b6aa4b`.
Use connected GitHub and cloud CI; no local compiler execution or clone.
PR #109 remains open/draft/unmerged on its original base; use fresh non-force
expected-HEAD updates and preserve concurrent history.

---

## M3+B preceding roadmap checkpoint — nested Repr binder and Boolean demand observation

Compiler/test parent: `8390cdc647ce0f5e5bd45678f000795ea5afb93c`.
Latest fully accepted compiler/test remains
`fbbc5271419dde8b183be723f07ff1f75a462013`.
M3+B remains open at the existing accepted weighted estimate of 67/100;
this repair adds no accepted points until all five gates pass at one SHA.

At the parent, native [38987840319](https://github.com/dwijayuda/pskernel/actions/runs/38987840319),
F1 [38987840312](https://github.com/dwijayuda/pskernel/actions/runs/38987840312),
F2 [38987840405](https://github.com/dwijayuda/pskernel/actions/runs/38987840405)
and F3/F4 [38987840305](https://github.com/dwijayuda/pskernel/actions/runs/38987840305)
passed. Focused [38987840331](https://github.com/dwijayuda/pskernel/actions/runs/38987840331)
(job 117263334273) passed Where and the original GroupProof worker invariant,
then rejected nested Repr during closed minor inference.

The exact failed term for the outer Prod minor contains
`ihRight (List.cons Format (ihLeft 0) $39)` without its required
`fun tail : List Format => ...`. The orphan accumulator is subsequently
looked up as the reopened `fst : Display` binder, explaining the reported
List Format versus Display argument mismatch. The actual constructor,
closed motives, field order and checked IH ownership are consistent.

The cause is the two `return` expressions inside the bound
`let body ← if ...` in `psElabDeriveReprContainerBranch`. Pinned Lean
4.35.0's `Lean/Elab/BuiltinDo/Basic.lean:elabDoIdDecl` elaborates that RHS
with the enclosing return continuation; `BuiltinDo/Jump.lean:elabDoReturn`
invokes that continuation instead of the binder's success continuation.
Thus both recursive-right branches could leave the function before
`psLogicLam` closes the accumulator. The old elaborator's
`Do/Legacy.lean:doLetArrowToCode` and flattened `doNested` agree.
Source pin: `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.

Both branches now yield with `pure`, matching the independent tuple
dictionary branch, so all successful paths construct the same tail lambda.
The correction covers both a nested Prod right IH and a non-Prod right IH.
It changes only Repr term construction; no recursor, unifier, runtime,
assumption or acceptance owner is changed. Existing native strings,
source/equation checks, target outputs, worker invariants and all workloads
remain unchanged. The existing failure already provides the regression case.

### Follow-up at the Repr repair SHA

Compiler/test `e85012f5f6d5a9e702779c0b13372e46eac1af0f` passed
native [38990964855](https://github.com/dwijayuda/pskernel/actions/runs/38990964855),
F1 [38990964834](https://github.com/dwijayuda/pskernel/actions/runs/38990964834),
F2 [38990964835](https://github.com/dwijayuda/pskernel/actions/runs/38990964835)
and F3/F4 [38990964874](https://github.com/dwijayuda/pskernel/actions/runs/38990964874).
Focused [38990964814](https://github.com/dwijayuda/pskernel/actions/runs/38990964814)
(job 117273057497) passed the previously rejected Repr construction and reached
`check comparison order: native List/Array comparison order changed`.

The next failure is the fixture's observation of a blocked Bool recursor:
`psReduceIota` reduces its major to select a constructor, but returns `none`
when that major is a free variable. `psWhnfSpineWithTransparencyFuel` then
preserves the original recursor application, including the unreduced major.
The old assertion compared that raw argument with the expected free variable.
It now separately WHNF-reduces the observed major before the same exact
alpha-equality check. Bounded failure diagnostics retain both forms.
This changes no production reducer or BEq construction.

Pinned Lean `Init/Data/List/Basic.lean` compares the first element first;
`Init/Data/Array/Basic.lean:isEqvAux` checks equal lengths and compares the
last element first. Those exact expected variables, native oracles, unequal
length refusal, second-demand check and both open kernel-checked equations
are preserved. The correction still awaits all five gates at one SHA.

Next: inspect all five automatically triggered qualification gates for this
repair at the same compiler/test SHA; repair any actual remaining failure.
Then integrate the highest-priority reviewed M3+B slice. Optional main-result
inference is being independently reconstructed/reviewed; WF foundation,
relation selection, empty dictionaries, dependent packing and indexed
deriving remain unqualified staged obligations. No P1 support is claimed
beyond its existing fail-closed Classical.choice audit.

---

## M3+B preceding roadmap checkpoint — precise nested recursor failure trace

Latest fully accepted compiler/test: `fbbc5271419dde8b183be723f07ff1f75a462013`.
All five gates passed at that SHA: native 38976283998 (33/33 reported steps),
F1 38976284003, F2 38976283981, F3/F4 38976283973 and focused 38976283967
(15/15). The receipt is
`docs/PSCV0_M3_NESTED_ELIMINATION_TYPED_RECURSION_QUALIFICATION_2026-10-16.md`.
It qualifies the accumulated typed-WF/direct-mutual-structural changes and
complete selected nested elimination/Hashable, including all existing outputs
on all five targets. The original native workloads and measurement step pass.

M3+B remains OPEN at approximately 65–70% (weighted estimate 67/100;
55–75% engineering uncertainty). All six weights remain data 30, source 15,
total recursion 20, P0 15, P1 10 and integration 10; accepted contributions
are 21, 10, 14, 13, 1 and 8. Unqualified local candidates add no points.

### Complete nested recursor failure evidence

Compiler/test `77d8578984e7a640c3c1d922cd90e9341466027e` passed
native [38986515634](https://github.com/dwijayuda/pskernel/actions/runs/38986515634)
(job 117259146722, all 34 reported steps), F1
[38986515562](https://github.com/dwijayuda/pskernel/actions/runs/38986515562),
F2 [38986515545](https://github.com/dwijayuda/pskernel/actions/runs/38986515545)
and F3/F4 [38986515520](https://github.com/dwijayuda/pskernel/actions/runs/38986515520).
Native artifact 12082764468 contains 6,796,399 bytes, SHA-256
`c0c2e3840f5f25ebea93c70600339324b6c3f4032ae02352b6f86250bbe55c6e`.
The complete original native workloads, repeated components and measurements
remain passing.

Focused [38986515599](https://github.com/dwijayuda/pskernel/actions/runs/38986515599)
(job 117259146484) now passes GroupProof with its original two two-member
worker groups and three-capture invariant. Where also remains passing.
The sole remaining source fixture failure is
`derive M3NestedDisplay.Repr: PSCV0-ELABORATION: application argument type mismatch (in Prod.mk) (in M3NestedDisplay.rec_4)`.
Target execution was skipped, so this is still not five-gate acceptance.

The reported rec_4 is the outer `Prod Display (Prod Branch Display)`
specialization. Both fields use actual checked IHs: the left returns
`Nat -> Format`, and the right is the inner tuple accumulator
`List Format -> List Format`. This minor does not use a separately
synthesized tuple dictionary. Static inspection has not established a
semantic correction. The actual failed check must determine the repair.

An optional identity-default diagnostic callback now carries the existing
failed check's stage, actual context, expected type, generated term and
already inferred type when available. It distinguishes cursor opening,
argument construction, specialized constructor-value inference, closed
argument inference and argument-type unification. The normal public handler
retains identity behavior. Only the existing fixture's replay of an already
failed Repr member installs the diagnostic callback. Its bounded renderer
and first-failing-application walk delegate to the existing Core inference,
sort/forall, local-scope and definitional-equality owners. They print actual
function/argument/expected/actual types and local IDs, and never manufacture
a term, change the acceptance result or run on a successful derivation.

This checkpoint changes three elaborator modules and that failure replay,
plus both handoffs, architecture and roadmap. The successful generated
terms, check order, native oracles, source requests, outputs, exports,
budgets, pins and all logical/runtime policies are unchanged. Continue from
the next cloud failure payload, repair its actual owner, then qualify all
five gates at one compiler/test SHA before accepting the accumulated slice.

The reviewed WF foundation/relation/empty-dictionary and omitted-result
candidates remain staged. The indexed-dependent-case fixture has been
corrected against the actual prepared representation: two mutual worker
groups plus a separately typed singleton Vec helper, with all previous
positive source/equation/output evidence preserved. Dependent unary packet
construction and exact curried-adapter cancellation now have a frozen draft
and independent native fixture pending review; indexed constructor-directed
Inhabited is being implemented in isolation. None adds accepted percentage.

### Right-case induction scope and generated-argument diagnostics

Compiler/test `bfede05f9e6e8f4444b5d0539b59b74e9acd23cf` passed
native [38985507691](https://github.com/dwijayuda/pskernel/actions/runs/38985507691)
(job 117255929670, all 34 reported steps), F1
[38985507686](https://github.com/dwijayuda/pskernel/actions/runs/38985507686),
F2 [38985507695](https://github.com/dwijayuda/pskernel/actions/runs/38985507695)
and F3/F4 [38985507705](https://github.com/dwijayuda/pskernel/actions/runs/38985507705).
Native artifact 12083525971 contains 6,795,650 bytes; its archive SHA-256 is
`e80b981ba2734b2d0a7c227184cf7e2df4ff5228d5b3f02bc4652350436d5bfb`.
This includes the original source/Standard, module, GC/component,
TypeScript, Rust, repeated Wasmtime and measurement gates. The prior
`6a8bc71c` native run 38984039232 also completed all 34 steps successfully.

Focused [38985507703](https://github.com/dwijayuda/pskernel/actions/runs/38985507703)
(job 117255929507) compiled all fixtures and passed Where's complete source,
capture/SCC, local-WF and emission checks. It then reported
`derive M3NestedDisplay.Repr: PSCV0-ELABORATION: application argument type mismatch`
and the unchanged GroupProof left-IH worker invariant. Target execution
was skipped. Four passing gates therefore do not accept this compiler.

The concrete GroupProof cause is unused right-side induction hypotheses
remaining in the context consumed by equality substitution. Self-recursive
right IH types mention the right child; dependency reopening consequently
reapplies those unused IHs inside the proof, making recursor lifting retain
extra workers. The right-case callback now removes only the actual right-IH
local IDs from its proof-construction context. Their complete real lambda
binders remain in the enclosing checked minor. All left IHs, actual fields,
family parameters and checked target remain unchanged. The removed IHs
were opened after the fields/captures and cannot be dependencies of those
earlier declarations. No recursion, erasure or worker-count policy changes.
The fixture still requires exactly two two-member worker groups with three
captures, and reports actual worker/recursor identities on failure.

The nested Repr cause is not yet established. The shared actual-recursor
argument walker now accepts an optional error decorator, defaulting to
identity; it decorates only its existing ensure-forall, generation, inference
and unification failures. Deriving supplies the actual slot recursor and,
for minors, the actual constructor identity. Final method checking retains
the selected recursor context. The successful checked terms, processing
order and inferences are identical; the next cloud log must identify the
failing argument before a semantic correction is selected.

This coherent checkpoint changes three elaborator modules, one diagnostic
fixture and the four handoff/architecture/roadmap records. No expected value,
source fixture, request count, output/export, budget, pin, Core/kernel policy
or backend behavior is changed. Qualify all five gates at one exact new
compiler/test SHA. The accepted baseline and weighted estimate above remain
unchanged. Reviewed WF foundation/relation/empty-dictionary, omitted-result
inference and indexed dependent-case candidates remain separate unqualified
work; dependent unary argument packing is being prepared in isolation.

### Source qualification repair and precise failure context

Compiler/test `6a8bc71c4916fe753e1c8c20a739428df725b757` compiled all
focused fixtures and passed the first ten independent source checks,
including the repaired native guards and complete PreDefinitions checks.
F1 [38984039237](https://github.com/dwijayuda/pskernel/actions/runs/38984039237),
F2 [38984039188](https://github.com/dwijayuda/pskernel/actions/runs/38984039188)
and F3/F4 [38984039301](https://github.com/dwijayuda/pskernel/actions/runs/38984039301)
passed. Focused [38984039160](https://github.com/dwijayuda/pskernel/actions/runs/38984039160)
(job 117251226237) then reported three elaboration failures. Target lanes
were skipped, so the accumulated source/deriving candidate remains unqualified.

- Where's generic local-body fixture used bare `default`; the selected
  Standard registers the actual method `Inhabited.default`. The portable
  source now names that method. The independent native `default` oracle,
  actual local dictionary, all-kind captures, seven requests, six exports
  and sixteen local-origin assertions are unchanged.
- The two generic required-default equations omitted every explicit use of
  their section type parameters. Source scope consequently retained neither
  A/B nor the dependent `Inhabited A` dictionary. Named `A := A, B := B`
  arguments now state the intended generic equations. Their native witnesses,
  actual dictionary requirements, kernel checks and output values remain.
- NestedDeriving returned only `application argument type mismatch`.
  No semantic correction is claimed for that error yet. Failure-only context
  now identifies the public family/handler, actual source command/name/byte
  span, registration, slot plan or checked pipeline stage. Successful calls,
  source text, complete native strings, comparison-order checks, six exports
  and all expected values are unchanged. The next cloud log must identify
  the failing owner before a production repair is selected.

Native [38984039232](https://github.com/dwijayuda/pskernel/actions/runs/38984039232)
(job 117251226673) had passed source/Standard, modules, GC/components,
compiled TypeScript and locked Rust, and was running the repeated Wasmtime
embedding at the last pre-commit observation. It is not an acceptance
receipt. All five required gates must pass at one exact compiler/test SHA.

The reviewed WF asset/relation/empty-dictionary and omitted-result/dependent
case drafts remain separate unqualified work. This commit changes only the
three focused fixtures and the four handoff/architecture/roadmap records.
Production semantics, original workloads, budgets and pins are unchanged.

### Native oracle qualification correction

At compiler/test `cfe86ea64da3d34683974e09bf4cda76861f2e54`, F1
38982453387, F2 38982453388 and F3/F4 38982453392 passed.
Focused 38982453396 (job 117246201593) failed while building two native
oracles. Production modules compiled, including the current recursion
and deriving owners; focused source and target execution had not started.

The Where rejection must include Lean's full diagnostic prefix:
"invalid mutually recursive definitions, cannot mix partial and non-partial
definitions". The isolated correction changes only that native guard text.

The PreDefinitions cyclic Nat / Type-u component was incorrectly described
as a native positive. Pinned PreDefinition.Main partitions SCCs first
(lines 296–324), then Basic.checkCodomainsLevel (309–322) rejects differing
actual result universes in a recursive total component. The fixture now
asserts that actual native refusal and removes the two impossible native
rfl witnesses. Its disconnected same-signature functions remain the positive
control. The entire portable namespace is unchanged, including the existing
PSCV0-MUTUAL-TOTAL-SORT refusal and all requests, values and atomicity checks.
No source-wide universe gate or production change is introduced by this repair.

Native Linux 38982453386 (job 117246201628) finished SUCCESS with all
34 reported steps, including checked source/Standard, real three-module
emission, GC/components, strict compiled TypeScript, locked Rust, repeated
Wasmtime embedding and the original measurement step. The tip therefore
has four successful gates and one failed focused gate; it is not accepted.
Its native artifact 12082645231 is 6,796,096 bytes, SHA256
`d88c29d724d209ba5faa608009599e11cda4675112b7ec89780e1b7b4be27727`.
All five gates must pass at one exact compiler/test SHA after these fixture
corrections.

### Qualification repair: original main modifiers and real deriving refusals

The combined source/deriving/authoring tip
`ef8e3bb697861b65cfcc172d8372dfd9d2c3896b` is not accepted:

| Gate | Run | Result |
| --- | --- | --- |
| Native Linux | 38981566559 | FAILURE in checked source/module qualification |
| F1 | 38981566602 | SUCCESS |
| F2 | 38981566562 | SUCCESS |
| F3/F4 | 38981566550 | SUCCESS |
| Focused | 38981566596 | FAILURE while building source fixtures |

The native compiler, all new deriving production modules, and the new
nested/proof deriving fixtures compiled. Focused job 117243385545 stopped
before executing its source checks: pinned Lean rejected mixed partial and
non-partial original main declarations in the Where and MutualPartial
oracles. It also found an unregistered imported PreDefinitions fixture and
an untyped optionalType pattern. No five-target candidate qualification was
reached by that job.

Pinned MutualDef.checkModifiers/check (75–111) compares original main
headers before body elaboration or SCC partition. Main's later anyPartial
dispatch and getModifiersForLetRecs do not permit incompatible source main
modifiers, even when those mains are disconnected. v7.2
PSCV0-TERM-02/PSCV0-REC-STRATEGY-01 require the native group rule.

One shared original-main modifier predicate now guards both the source
preparation owner and retained typed-block validation. Local helpers are
excluded from that main-header check. A valid all-partial block still gives
plain recursive helpers its operational strategy; nonrecursive inherited
helpers remain ordinary, and unused hints add no captured header argument.
Explicit source partial opacity remains the v7.2 P0 policy, including when
native Main takes its nonrecursive-first path for its own declaration.

The independent Where evidence now uses a compatible two-main partial block
and a separate ordinary WF/P1 block. Exact native and portable mixed-main
refusals cover disconnected headers. The mutual fixture covers connected,
disconnected and body-error precedence, then reuses the same names in an
all-partial recovery with exact logical/body/provenance checks. A retained
source-kind/strategy corruption must fail at the shared whole-block gate.
The original seven Where requests, six exports/values and sixteen local
origins, and sixteen MutualPartial requests/five outputs, remain unchanged.
The existing PreDefinitions checks are now registered as a Lake library and
still execute inside the structural fixture. The owned default-binder pattern
has an explicit syntax type.

Native job 117243385381 reached module request 34 and rejected its stale
expected refusal: recursive List BEq is now supported. A complete NativeTests
audit found exactly three obsolete negative slots. Their counts and expected
elaboration phase are preserved with genuine missing-field-dictionary,
indexed-BEq and dependent-runtime-field refusals. The former capabilities
already have stronger independent positive coverage in the nested deriving
fixture, including generic groups, complete native strings/dictionaries and
all five required target lanes. Existing successful source/workload values,
request counts, checksums and budgets are unchanged.

### Checked WF authoring evidence retained

The same native job successfully exported the actual missing WF relation
closure before the unrelated source-test failure. It selected 34 new
declarations from 12 missing roots, with zero candidate axioms, 3 actual
recursor-rule comparisons and 2,329 shared source nodes. Official-kernel
replay passed against the unchanged frozen pre-WF environment.

The generated 466,947-byte candidate was reconstructed from its 228 emitted
JSON source chunks and matched CI SHA256
`b6bd56c4ab6378905d1d3ac2f0155eb5bc4742be3e19e684d64ac1a3007716f3`.
Native artifact 12081064126 is 3,696,804 bytes with archive SHA256
`0e1a9600ea9122d33556a7f711795a6f70c5acec6153429aecc6d6e526bfc034`.
That file is reviewed candidate data, not an active new Standard or a generic
WF execution claim. Its later selection must preserve actual dictionary
priorities, typed runtime layouts and independently measured snapshot identity.

All accumulated compiler/test changes still require five successful gates
at the next exact tip. The accepted compiler remains fbbc5271; this repair
does not raise the progress estimate. PR #109 remains draft/open/unmerged
on its original base. Native portable Lean, the exact 4.35.0 and v7.2 pins,
propext/Quot.sound, all original workloads and cloud-only validation remain
fixed. P1 remains fail-closed on the audited Classical.choice dependency.

---

## M3+B earlier roadmap checkpoint — mutual proof/default deriving and WF foundation authoring

Latest fully accepted compiler/test: `fbbc5271419dde8b183be723f07ff1f75a462013`.
All five gates passed at that SHA: native 38976283998 (33/33 reported steps),
F1 38976284003, F2 38976283981, F3/F4 38976283973 and focused 38976283967
(15/15). The receipt is
`docs/PSCV0_M3_NESTED_ELIMINATION_TYPED_RECURSION_QUALIFICATION_2026-10-16.md`.
It qualifies the accumulated typed-WF/direct-mutual-structural changes and
complete selected nested elimination/Hashable, including all existing outputs
on all five targets. The original native workloads and measurement step pass.

M3+B remains OPEN at approximately 65–70% (weighted estimate 67/100;
55–75% engineering uncertainty). All six weights remain data 30, source 15,
total recursion 20, P0 15, P1 10 and integration 10; accepted contributions
are 21, 10, 14, 13, 1 and 8. Unqualified local candidates add no points.

### Current candidate: mutual proof decisions and native ordered defaults

This checkpoint retains the unqualified source component/where work from
c55a7caf and complete selected nested Repr/BEq from 37ffb9a3, together with
the local-context repair and native hint-scope correction at
`a0c98a3fbc4d96c1d9e4438dca9a01f88925766a`. All accumulated
source/compiler/test changes require five successful gates at one tip.

Direct nonindexed mutual DecidableEq now uses the complete selected-slot
elimination owner. Each left family has its actual dependent decision motive;
recursive decisions come only from its real checked left-child hypotheses.
Each right operand is a bound variable under its own actual left motive;
no block-level synthetic local ID can collide with a later family's major.
Right-side cases bind every actual minor/IH, leave right IHs unused, and use
Decidable True for companion families. Existing equality transport and proof
field substitution remain responsible for same-constructor decisions.
Different-constructor and field failures use checked projections/discriminators.

The existing psElabIndexFunction owner now handles complete direct groups.
It checks the selected constructor's actual owner/ordinal, validates the
provided fallback, builds every constant motive and real minor telescope,
and checks the final projection or discriminator function. It does not
manufacture an inhabitant, a recursive hypothesis or an injectivity axiom.

Nonindexed group/nested Inhabited reuses the existing native constructor
algorithm: try constructors in order without new assumptions, then with
valid parameter requirements, pruning unused dictionaries. List.nil,
Option.none and Array.empty require no child default; a product uses its
actual component dictionaries. Group dispatch registers a genuinely generated
earlier closed instance before constructing the next member. It performs
no constructor-order search across families and introduces no forward/self
default. Other recursive deriving handlers continue using their original
input environment.

### Audited WF foundation authoring

This authoring checkpoint follows the unqualified proof/default deriving
commit `161b6e16652f3a597fe9d1d5b43988f9ee20a0b2` and includes all preceding
source, scope and nested deriving candidates in its exact-tip qualification.

A separate native-only export profile prepares the actual missing relation
declarations required by the next WF slice. The prior final Standard expression
is frozen unchanged as psSelfHostProdPreWellFoundedPreludeEnvironment; the
current final environment is its alias, so this checkpoint changes no active
logical declaration, class registry, runtime roster or snapshot identity.

The profile requests WellFoundedRelation, generic fix/fix_eq, invImage,
SizeOf and its actual Nat/default instances, sizeOfWFRel, the actual product
lexicographic instance/constructors, emptyWf and the selected Nat decrease
lemmas. It determines already-selected versus missing roots from the actual
frozen environment instead of assuming absence from a partial asset inventory.

Every missing root goes through the existing StandardExport closure,
official-kernel replay, real recursor-rule comparison and deterministic source
renderer at the pinned Lean commit. The approved assumption set remains
propext/Quot.sound. No proof body, theorem, dictionary or trusted admission
is fabricated or substituted by this profile.

The new native CI step runs that existing exporter, retains its source chunks
and exact generated-file SHA256, and uploads the candidate through the existing
artifact step. All earlier commands, frozen replay boundaries and budgets are
unchanged. The native workflow now has one additional required authoring step;
all five primary gates still need to pass at the same compiler/test SHA.

The resulting asset must be retrieved and reviewed before a later coherent
commit selects its declarations, real instance priorities and typed runtime
structure layout. Generic WF execution and relation-specific equations remain
a separate future compiler/runtime qualification.

### Independent evidence and target integration

Pscv0M3GroupProofDeriving separately declares native mutual families and
constructs the portable groups/instances. The direct decision fixture has
cross-family recursion, two equal-typed same-family children, dependent proof
fields and an unrelated always-false BEq instance. This checks actual
DecidableEq evidence independently of Boolean equality.

The fixture checks six generated instances and their exact requirements:
one DecidableEq A for each direct member, no requirements for either nested
empty default, and only Inhabited A for each required-default member.
Later defaults must reference the actual earlier instance and never themselves.

There are thirteen full recursor signature witnesses (2 direct, 8 nested
default and 3 required default slots), four direct second-family projection/
discriminator kernel equations, generic default equations and eight closed
output equations. Runtime preparation must yield exactly two real left
induction worker groups, each with two members and three captures; right
cases, projections and defaults must not create a recursive worker group.

The independently calculated output matrix is:

| flag | m3groupdecide | m3groupdecideatom | m3groupdefault | m3grouprequired |
| --- | ---: | ---: | ---: | ---: |
| false | 1 | 3 | 31 | 55 |
| true | 39 | 3 | 19 | 133 |

The focused workflow requires all thirteen source checks and adds these four
outputs to the established JS, strict compiled TypeScript, locked Rust,
V8 GC and Wasmtime component lanes. Rust generation remains immediately
paired with its execution. The original workloads, request counts, exported
names, expected outputs, checksums, budgets and pins are preserved. Existing
negative slots for newly supported capabilities retain genuine indexed or
nested-DecEq refusals; they are not removed to obtain a pass.

Both the shared equality/decision construction and the independent fixture
have static peer review. Compilation, source execution, fresh-kernel checks,
IR validation and target parity remain unqualified until exact-tip GitHub
Linux results are recorded. No local Lean/Lake/build/test execution occurred.

### Remaining selected boundaries and next work

Pinned Lean's DecEq handler explicitly declines nested inductives. Indexed
DecidableEq/Inhabited and indexed BEq remain outside this candidate, as do
arbitrary nested containers, constructor-local specialization parameters and
function-valued nested fields. The source mutual grammar remains def/function
only. A hint alone does not extend a local function's captured header;
v7.2 rule 10 and PSCV0-D-WHERE-01 preserve pinned native scope.

Broader actual WF relation selection/typed argument packing, optional main
result inference, additional dependent equality/elimination and the remaining
selected matrix are still open. P1 remains blocked by Classical.choice in
the actual pinned fixedpoint/equation dependency closure; unused suffixes
are not P1 support.

Native portable .lean, official Lean 4.35.0 at
eb6cafb7290e8bd5f2937522d8d804f58f02bafc, the exact v7.2 reference blob,
approved propext/Quot.sound and the official checking boundary remain fixed.
PR #109 stays draft/open/unmerged on its original base. No M4/M5 promotion,
replacement kernel, self-hosting, source migration, LLVM, reset or merge is
part of this checkpoint.

---

## M3+B earlier roadmap checkpoint — source components and nested deriving candidate

Latest fully accepted compiler/test: `fbbc5271419dde8b183be723f07ff1f75a462013`.
All five gates passed at that SHA: native 38976283998 (33/33 reported steps),
F1 38976284003, F2 38976283981, F3/F4 38976283973 and focused 38976283967
(15/15). The receipt is
`docs/PSCV0_M3_NESTED_ELIMINATION_TYPED_RECURSION_QUALIFICATION_2026-10-16.md`.
It qualifies the accumulated typed-WF/direct-mutual-structural changes and
complete selected nested elimination/Hashable, including all existing outputs
on all five targets. The original native workloads and measurement step pass.

M3+B remains OPEN at approximately 65–70% (weighted estimate 67/100;
55–75% engineering uncertainty). All six weights remain data 30, source 15,
total recursion 20, P0 15, P1 10 and integration 10; accepted contributions
are 21, 10, 14, 13, 1 and 8. Unqualified local candidates add no points.

### Qualification repair: local context and native hint scope

The combined source/deriving SHA
`37ffb9a356e6ff04c5b607b2c6537469dc5ec32d` failed all five gates at
Where.lean parsing (focused 38978211015, job 117232632319). The lexical
repair `9c65ddca8fb814b31eab6b9f77c42ecabcc6debb` removed the reserved
meta bindings. All five gates then failed at that SHA; focused 38978550909
(job 117233725275) compiled the new Where, PreDefinition, Repr and BEq
production modules but stopped at WhereWellFounded.lean:104–106.

The inner local-context expression was inferred as the enclosing
PsElabWellFoundedResult. This repair explicitly binds PsLocalContext and
uses pure for that inner record expression. The final adapter still returns
the actual checked definition, equation, meta context and source information
from the existing WF constructor. No source/kernel/runtime qualification
was reached by either failed candidate; fbbc5271 remains accepted.

A proposed automatic capture extension was discarded after exact-pin review.
Lean MutualDef.collectUsed/withUsed closes definitions and lifted locals from
their actual checked header/body/local types and values. PreDefinition.Main
then clears the local context before TerminationMeasure reopens the already
closed function header. A section or parent local mentioned only by an active
termination hint is therefore unavailable unless a real checked dependency
already retains it. v7.2 rule 10 and PSCV0-D-WHERE-01 require this native scope
and local-recursion behavior. Adapting only the native oracle would not justify
a different portable capture rule.

The original body-based capture closure and typed component owner remain.
Unused ordinary/inherited-P0 hints add no captures; active WF hints operate
only in the genuinely retained header. The discarded all-ambient dependency
preparation, strategy-term capture seeding and graph relocation are excluded
from this repair. Two exact native rejections and matching portable checks
characterize measure-only and proof-only missing locals. Unused ordinary/P0
hints must retain their owned syntax while adding no hidden header capture.
The existing seven requests, six exports and expected values, and sixteen
local-origin records are preserved.

All five gates must pass at the same repaired compiler/test tip before this
source and nested Repr/BEq candidate is accepted.

### Current candidate: complete selected nested Repr and BEq

The preceding source checkpoint is `c55a7caf857959e07c0e86b8496b422289c8b82b`.
Its flat where ownership, typed SCC strategy selection, original-block capture/
universe closure, local provenance and checked WF source-equation transport are
included unchanged. That checkpoint and this deriving change are unqualified
until all five gates pass at one combined compiler/test tip.

Repr and BEq now consume the existing complete visible/nested elimination plan.
The shared DerivingContext cursor can select an actual auxiliary slot while
retaining all group motives and minors. It validates the actual specialized
family, its own indices, full recursor prefix and real child-hypothesis types.
Right-hand binary cases retain their real telescopes while ignoring all right
IHs; they do not invent a new recursive dictionary or worker group.

Repr uses a Nat-to-Format motive for visible families, Option and Array, a List
of already rendered documents for List slots, and a right-tuple accumulator for
Prod slots. Actual ReprAtom evidence selects native List bracketFill; ordinary
List uses bracket and Array always uses bracketFill. The actual ReprTuple
dictionary handles an independent right product field, while real Prod-slot
hypotheses flatten recursive right tuples in native order. Public constructor
formatting preserves explicit fields, max precedence, group/nest and application
parentheses. Proof/type placeholders and existing structure formatting remain.

BEq uses actual field dictionaries and real selected child IHs. Ordinary List
comparison visits the head first. Array checks equal lengths before demanding
any field comparison, then visits the final element first as pinned Array.isEqv
does. Reverse mode propagates only through the same specialized List tail;
List-valued elements retain ordinary forward comparison. Option and Prod preserve
their native shape and field order. No reflexivity optimization may bypass a
user-supplied nonreflexive BEq dictionary.

### Independent evidence and required cloud qualification

Pscv0M3NestedDeriving independently declares the native mutual and indexed types,
then separately constructs the portable declarations/instances. It checks a
nine-slot dependent-parameter group and a two-slot indexed group, eleven full
signature witnesses, five generated instances, exact selected-slot refusal and
a source singleton deriving positive.

The Repr exports compare complete portable rendered strings against complete
independently rendered native strings, including newlines/spacing/parentheses,
at widths 23/120 and precedences 0/1024. Coverage includes marked/unmarked List,
Array, Option, recursively flattened right tuples, independent Prod Nat Nat and
indexed public Repr. Numeric result bits encode full String equality; no text
hash substitutes for the comparison.

The BEq fixture compares native masks, an actual nonreflexive element dictionary,
ordinary list order, reverse array order and unequal lengths. Open generated-method
WHNF probes establish which unresolved Boolean is demanded first; two general
comparison equations join fresh official-kernel admission. The right-case path
must not introduce additional worker groups.

The focused workflow now requires all twelve source checks and adds these six
outputs to the existing JS, strict compiled TS, locked Rust, V8 GC and Wasmtime
runner: m3nestedrepr, m3nestedtuplerepr, m3nestedindexedrepr, m3nestedbeq,
m3nestedarraybeq and m3nestedatombeq. Each Rust generation remains immediately
paired with its execution. All earlier workloads, request counts, outputs,
checksums, dependency pins and resource budgets remain unchanged.

The two now-supported recursive Repr/BEq capability negatives become real
function-valued nested-field refusals, preserving their precise phase and the
existing fixture's counts. The prior nested fixture retains its raw-key oracle,
all seven outputs and its remaining Inhabited/DecidableEq refusal coverage.

Both production handlers and the selected-slot cursor have independent static
review. No local Lean/Lake/build/test execution is claimed. Only exact-tip GitHub
Linux CI can qualify this source/kernel/IR/backend candidate. Record failed gates
and their actual causes; do not weaken expected values, assertions or budgets.
When four gates pass, let the full native run finish before another feature push.

### Remaining selected limits

Indexed BEq, indexed/group DecidableEq and broader Inhabited remain outside this
candidate. Pinned Lean's DecEq handler itself declines nested inductives; preserve
that explicit native boundary. Arbitrary containers, function-valued nested
fields and constructor-local specialization parameters retain their refusals.

The next proof/default deriving work targets direct nonindexed mutual DecidableEq
and native constructor-ordered nonindexed group/nested Inhabited. Actual broader
WF relations and typed argument packing, optional main-result inference, further
structural/dependent elimination and the rest of the selected matrix remain open.
The source checkpoint's eager unused-hint name-resolution and registration limits
remain explicit. P1 is still blocked by Classical.choice in the actual pinned
fixedpoint/equation closure. An unused nonrecursive suffix is not P1 support.

Native portable .lean, official Lean 4.35.0 and its pinned commit, the exact v7.2
reference blob, approved propext/Quot.sound, the original official checking
boundary and PR draft/open/original base remain fixed. M4/M5 completion, kernel
replacement, self-hosting, compiler-source migration, LLVM, resets and merging
remain outside this work.

---

## M3+B earlier roadmap checkpoint — local definitions and typed component candidate

Latest fully accepted compiler/test: `fbbc5271419dde8b183be723f07ff1f75a462013`.
All five gates passed at that SHA: native 38976283998 (33/33 reported steps),
F1 38976284003, F2 38976283981, F3/F4 38976283973 and focused 38976283967
(15/15). The receipt is
`docs/PSCV0_M3_NESTED_ELIMINATION_TYPED_RECURSION_QUALIFICATION_2026-10-16.md`.
It qualifies the accumulated typed-WF/direct-mutual-structural changes and
complete selected nested elimination/Hashable, including all existing outputs
on all five targets. The original native workloads and measurement step pass.

M3+B remains OPEN at approximately 65–70% (weighted estimate 67/100;
55–75% engineering uncertainty). All six weights remain data 30, source 15,
total recursion 20, P0 15, P1 10 and integration 10; accepted contributions
are 21, 10, 14, 13, 1 and 8. Unqualified local candidates add no points.

### Current candidate: owned local definitions and typed dependency components

This commit adds the selected flat v7.2 where block and one typed predefinition
owner shared by source mutual groups, local definitions and unregistered
standalone WF/P1 hints. Syntax retains each local def, optional local result,
default, complete body/suffix span and enclosing declaration. Both printers
preserve the selected language's spelling and ownership. The .ps mutual
grammar remains def/function-only; no mutual inductive grammar is introduced.

WhereScope resolves headers/defaults without sibling aliases and bodies with
the real scoped aliases. Actual typed body/header fvars determine captures;
source-name occurrence lists are only candidates. Transitive peer captures
include type, instance, value and proof dependencies. Parent-body lambda/let
locals do not enter helper scope. Local binders can shadow helper aliases.
Private module names, monotone fresh IDs, postponed constraints and full
original-block universe closure are retained before dependency partition.

PreDefinition.Basic carries closed peer types, checked bodies with actual peer
fvars, source header count, exact captures, retained source hints and ownership.
PreDefinition independently validates these invariants, computes dependencies
from typed values, partitions deterministic SCCs and substitutes already
checked predecessor constants. Common captures and whole-block levels are
checked before specialization. A late failure returns no partially committed
command environment.

The effective strategy comes from the typed component and the original main
sources. Pinned TerminationHints.ensureNone emits warnings, not rejections.
Genuine nonrecursive components use checked ordinary declarations and exact
eq_def theorems before unused WF/P1 hints are considered. Actual proof-valued
nonrecursive local helpers become checked theorem declarations. An original
partial main gives every lifted local helper inherited partial intent before
SCC partition; a recursive inherited helper retains opaque P0/body identity
even when its raw source owns an unused termination_by or partial_fixpoint
hint. Those hints and spans remain in the AST and supply no WF/P1 evidence.
Explicit source partial retains v7.2's independently inhabited logical opacity,
including the established standalone/all-explicit-partial paths. No P0 defining
equation is emitted.

Recursive total components use the existing direct structural owner. A selected
recursive WF singleton is reconstructed under the actual typed callback through
WhereWellFounded. The exact returned definition and equation are checked against
the retained source body. RecursorEquation owns checked case/rfl transport using
the complete actual elimination plan. It can locate an original header major
below actual typed result lambdas while proving equality of the complete returned
functions in the original header context. Result lambdas do not become source
parameters, captures or measure variables. An independently checked wrong
zero-function/equation must fail at the exact constructor-case proof obligation.

Source provenance retains each real qualified local name, full local span and
actual emitted declaration membership. NativeV7's production batch mapping uses
that local span for helper declarations and generated worker ancestry. Ordinary
origins with no locals preserve their existing JSON shape; local metadata is
serialized explicitly when present.

### Qualification plan and preserved workloads

Pscv0M3Where checks independent pinned declarations, all-kind captures, forward
inference/defaults, sibling and parent/helper recursion, proof shadowing, private
identities, block-wide inherited P0, ignored hints, local WF and actual production
origin serialization. Its seven Host requests and six scalar outputs use the
existing JS, strict TS, locked Rust, V8 GC and Wasmtime runner. The workflow now
requires eleven source checks and retains every existing target command.

Pscv0M3PreDefinitions adds typed corruption checks through the existing structural
fixture executable. Existing mutual-P0 request counts/outputs remain unchanged.
The WF fixture still has sixteen Host requests and twelve runtime outputs.
Its obsolete nonrecursive-WF refusal is replaced by a native/portable ordinary
unused-hint acceptance; all fourteen remaining negative slots keep exact owners.
The unsaturated-header negative is made otherwise well typed so it still reaches
the WF-ARITY rule after the new shared typed prepass. No expected runtime value,
benchmark checksum, pin, heartbeat/depth ceiling or workflow budget is changed.

This candidate has static and independent review only at publication. It needs
native, F1, F2, F3/F4 and focused success at one current compiler/test SHA.
The fbbc5271 receipt does not qualify these source changes. Let the full native
gate finish when the other four gates pass before publishing the next feature.

### Remaining boundaries and next work

Unused hints are still name-resolved before SCC selection; an unknown or
out-of-scope name can therefore fail even when the hint would be unused.
This is not full unused-hint diagnostic parity. Registered standalone WF,
abbrev/opaque where registration and optional top-level result annotations keep
their current separate limitations. The selected local omitted result supports
nondependent codomain inference; genuinely dependent omitted results need an
annotation. Local nested where, attributes, theorem/instance/function/const and
mutual blocks remain outside the selected local grammar.

True multi-member WF, broader actual relation/argument packing, additional
structural shapes and further deriving remain open. Recursive P1 retains the
exact Classical.choice assumption refusal. A nonrecursive unused suffix is not
P1 implementation. Native portable .lean, official Lean 4.35.0 at the pinned
commit, the exact v7.2 reference blob, approved propext/Quot.sound, PR draft/open
on its original base and all M4/M5 boundaries remain unchanged.

---

## M3+B earlier roadmap checkpoint — shared nested elimination candidate

Latest fully accepted compiler/test remains
`01d762eb02eab1d2f795e5338cb3586cd1d1ace0`, recorded in the group-deriving receipt.
The repaired typed-WF and total-mutual candidate
`62a43dcc1ac9069533e4a48bf54639121cb265fd` has passed F1 `38973463203`,
F2 `38973463414`, F3/F4 `38973463241` and focused `38973463517` (15/15).
The full native gate `38973463333` was cancelled by the next compiler push
under the existing cancel-in-progress workflow setting. Its focused log confirms
all source checks, fresh-kernel equations and JS/TS/Rust/V8/Wasmtime execution,
including all twelve WF and six structural outputs. It therefore has four
passes, not five-gate acceptance. The latest accepted compiler remains 01d762eb.

The shared nested elimination and Hashable candidate
`7ce2388184f2c29cc49a2b1a367c05191828265a` needed Lean continuation layout
repair `78f5f2e09b4a4497ddc179648f3ed3a291544f02`, then one legacy
constructor-target initialization in `90cc412e2a171fef95af181c62f9e8c3196049d1`.
At 90cc412e all production modules compile, and F1 `38975380612`,
F2 `38975380763` and F3/F4 `38975380793` pass. Focused `38975380963`
failed compiling the independent native M3NestedKey source command at its
default recursion-depth limit. Native `38975381664` was still in progress
when that fixture blocker was inspected. No source/runtime pass is claimed.

This commit isolates the raw structural/definitional key oracle at the actual
official-kernel boundary. An independent Lean.Declaration.inductDecl constructs
the same family and constructor types, retaining Id in the second List argument.
Its types are compared with decoded canonical admission; the actual fresh kernel
must admit it, and all three public/auxiliary recursor signature witnesses must
pass. The existing canonical admission, three-slot distinction and one-declaration
checks also remain. Native source-command postprocessing support is not claimed.
The provider's options, existing heartbeat/depth ceilings, seven runtime outputs,
all earlier assertions, dependency pins and workflow budgets remain unchanged.

This repaired compiler/test candidate requires its own exact-SHA native, F1, F2,
F3/F4 and focused success. Let its full native gate finish before publishing the
next feature when the other gates pass; implement follow-up work separately.
Neither earlier native results nor focused passes qualify a different tip.

M3+B remains OPEN at approximately 60% (50–70% engineering uncertainty).
All six exit weights remain data 30, source 15, total recursion 20, P0 15,
P1 10 and integration 10; accepted contributions remain 17, 10, 10, 13, 1
and 7 points. Unqualified code adds no accepted points.

| Exit | Candidate advancement | Remaining acceptance |
| --- | --- | --- |
| Data, elimination, deriving | Complete selected nested/mutual/indexed slot plan, full recursor signatures, Match, nested Hashable and runtime traversal | Qualify this exact tip; expand remaining nested deriving |
| Source strategies | Existing selected heads/suffixes and compatible total mutual construction | Typed local where/capture/SCC owner and full source strategy matrix |
| Total recursion | Typed dependent WF and exact direct mutual equations passed focused at 62a43dcc | Obtain all five gates on the repaired current compiler; checked local-match equation transport and broader selected relations/packing |
| P0 ordinary execution | Accepted opaque logical/body identity and actual singleton/mutual runtime | Qualify new local/mixed SCC closure cases when implemented |
| P1 | Exact assumption audit and fail-closed source behavior | Pinned construction requires forbidden Classical.choice |
| Cross-stage integration | Existing baseline has five exact-SHA gates; 62a43dcc has four and cancelled native | Repair nested compilation and obtain all five gates at one current SHA |

### One shared visible and nested elimination plan

Core's checked slot plan retains each visible family and each selected nested
specialization: its actual type former, common parameters, own indices,
constructor head/telescope, recursor identity and ordered recursive-field
targets. List, Option, Array and Prod slots retain their actual container
declarations; no virtual datatype or fabricated recursive metadata is emitted.
Public recursors and auxiliary rec_N entries must match complete reconstructed
telescopes, including motive universes and every real child hypothesis.

Discovery follows the pinned raw structural specialization keys and queue order.
Definitionally equal List(Key A) and List(Id(Key A)) keep distinct slots.
A raw prepass checks uniform family arguments and universe variables before
reduction can erase an occurrence. Existing source uniformity diagnostics remain.
Core.LevelNormalize owns the unchanged normalization definitions; the former
Meta module is a compatibility import, with no Core-to-Meta dependency.

The canonical bridge now accepts the actual retained environment through
psEncodeCheckedAdmissionsCanonicalIn. All three Compiler.Api admission paths
supply it. Fresh official Lean regenerates recursors from the original visible
group; the obsolete shallow unit-wrapper adaptation is removed. The legacy
environment-free API still handles direct batches and refuses nested batches
without their actual container declarations.

Iota, source Match, deriving, checked worker lifting and typed erasure consume
the same complete plan. Every worker retains an exact closed recursor equation,
the common capture telescope and all slot identities. Dispatch selects rec_N
plus its actual specialized child type and indices, never just a base name such
as List. Array/Prod elimination binds the actual major and each typed projection
once. Array uses the existing checked List conversion and shares that allocation
between its field and corresponding IH. No backend-specific recursion is added.

### Nested Hashable and qualification scope

The shared deriving cursor now constructs selected nested Hashable for the
four actual containers. List/Array preserve native left-fold order and seed 7;
Option preserves native none/some policy; Prod combines left then right.
Real slot hypotheses supply recursive results. No self dictionary or production
partial-recursion fallback replaces total checked elimination.

Pscv0M3NestedInductive covers a six-slot singleton, a nested mutual group with
alpha-renamed dependent parameters, an indexed public family with its own
unindexed List slot, repeated/deep specializations, and the distinct raw Id key.
Fresh-kernel full-signature witnesses, actual cross-slot equations/reduction,
generic hash laws, source cases and direct selected-child recursion accompany
seven independent native runtime outputs. Equal-count stale signatures, missing
or duplicate auxiliaries, universe/order errors, worker aliasing, nonuniform raw
occurrences and constructor-local specialization captures have explicit refusals.
The two old capability negatives now exercise still-unsupported function-valued
nested fields; their original runtime exports and observations are unchanged.

The focused workflow builds the new executable and runs its source/kernel check
plus JS, strict compiled TS, locked Rust, V8 GC and Wasmtime against the existing
generic runner. Every existing fixture, command, output, count, checksum, pinned
dependency and budget remains. Source aggregation now requires all ten fixtures.
Each Rust input generator remains immediately paired with its own execution.

### Remaining obligations

This candidate does not establish nested Repr/BEq/DecidableEq/Inhabited, arbitrary
containers, constructor-local specialization parameters or function-valued nested
fields. Default source induction on mutual/nested types retains the pinned
refusal without an explicitly selected supported eliminator. The .ps mutual
grammar remains def/function-only. The direct structural-SCC API does not admit
nested recursive fields.

Flat where/capture/SCC source ownership and exact checked transport between WF
match equations are being implemented separately. Broader WF argument/relation
packing and the remaining deriving/recursion matrix are still open. P1 remains
blocked by Classical.choice in pinned Lean.Order.fix/CCPO.csup and its equations.
Only propext and Quot.sound are approved. Native portable .lean, the existing
official checking boundary, PR draft/open/original base and all M4/M5 boundaries
remain fixed.

---

## M3+B earlier checkpoint: accepted group deriving; recursion candidate

Accepted compiler/test `01d762eb02eab1d2f795e5338cb3586cd1d1ace0` has all five gates green:
native `38967030820` (33/33), F1 `38967031191`, F2 `38967030836`,
F3/F4 `38967030843`, focused `38967030789` (15/15).
See [the exact receipt](PSCV0_M3_GROUP_DERIVING_QUALIFICATION_2026-10-17.md).

Accepted progress is approximately 60% (50–70% engineering uncertainty),
with all six exit weights retained: data 30%, source strategies 15%,
total recursion 20%, P0 15%, P1 10%, integration 10%. Approximate accepted
contributions are 17, 10, 10, 13, 1 and 7 points respectively. The following
candidate adds no accepted points until all five gates pass on its SHA.

### Typed well-founded recursion candidate

The well-founded owner now uses the full explicit typed source header. One
changing measured parameter may have any checked domain depending only on
fixed captures; the Nat-valued measure may depend on those captures. All
remaining evolving arguments form the actual dependent state telescope, and
the result may be any checked type supported by ordinary erasure.

Typed call analysis closes dependencies before partitioning fixed, major and
state arguments. The real Nat.fix motive returns that state function.
Recursive arguments are checked and bound once in original order. The
public f.eq_def uses actual fix_eq and inferred-level funext/congrArg/Eq.trans
where state extensionality is required. No provisional global, recursive
proof assumption, eta conversion rule or runtime ABI is added.

Ps.Erasure.Entry owns validation of the actual definition, universe
arguments and current entry telescope. It recomputes binder roles, checks
local/order identities, and separates raw source-header arguments from
applications of a returned function. Ps.Erasure.WellFounded consumes that
validated entry and the real fixed-point term, then delegates typed
recursive calls to ordinary erasure. Proof Unit slots, erased indices,
polymorphic types and runtime parameters retain their existing conventions.

The original eight well-founded outputs remain unchanged. Four new native
oracles cover polymorphic List reversal with an ordered digest, a fixed
function and returned closure, evolving dependent Fin state with erased
family/proof captures, and a dependent Fin result. Fresh logical equations,
universe closure, all-kind entry roles, a returned-function application and
stale runtime argument-order refusal are checked in the same fixture.

Selected limits remain explicit: no several-changing-input measure pack,
no major domain depending on changing state, and no extension of ordinary
erasure's higher-rank/type-changing-state limits. Body lambdas do not enter
the source header or termination-measure scope.

### Total mutual structural recursion candidate

The shared scoped header preparation now feeds an actual typed structural
batch. Each source member root-matches one explicit major. Every function
owns exactly one ordered component of its actual family motive; families
may own zero, one or several functions. PUnit, an unwrapped component, or
right-associated Prod is constructed and checked at the actual motive
universe. Equal result types never identify functions.

The existing complete-group argument cursor builds motives and minors.
Every recursive call must target a real strict direct constructor field,
with the child's actual family/indices, invariant uniform parameters and
the full original member header. Its source identity selects the exact
component from that child's checked hypothesis; all other evolving
arguments and returned-function applications are checked in source order.

All completed ordinary definitions close without provisional peer locals
or recursive globals. Only then are the exact original source equations
proved against the actual public definitions using checked constructor
cases, delta/iota reduction and product projections. Any late failure
returns no batch. Existing ordinary compiler preparation constructs and
revalidates companion workers before shared erasure.

The new independent native fixture has six outputs. It exercises two
equal-typed functions with distinct observations, differing argument
arities/orders and evolving state, unequal family index telescopes, a
zero-owned companion at Type u, shared implicit/instance/value/proof
captures, exact public equation use and late-member atomicity. It runs
through direct JS, strict TS, locked Rust, V8 GC and Wasmtime components.

This slice requires a root match for every member, distinct header-local
indices, the same actual direct group and uniform parameters, and
equivalent successor motive universes. Nested/function-valued recursive
fields, escaping/unsaturated peers and general mutual well-founded
recursion retain precise refusals.

Remaining shared dependencies include nested specialization motives/traversal,
expanded dependent deriving, flat local where capture/strategy ownership,
compatible SCC dispatch and broader selected structural/WF construction.
Default source mutual/nested induction retains the pinned default refusal;
the .ps mutual grammar remains def/function-only. P1 is blocked by the exact
Classical.choice closure of pinned Lean.Order.fix/CCPO.csup and its equations.
Only propext and Quot.sound remain approved. M3+B stays OPEN.

The following dated sections retain earlier implementation history.

## M3+B earlier candidate: source mutual P0 and typed measured-state recursion

The selected def/function mutual command has one ordered source owner.
`Ps.Elab.Mutual` constructs independent real opaque headers before any P0
body, closes block-wide section/universe captures and uses typed local peer
aliases for the complete captured telescope. Every private actual body is
rechecked after alias substitution. Ordinary runtime selection reuses the
existing checked opaque/body pairing. Per-member and whole-group provenance
survive through all target artifacts and CLI origin JSON. The source grammar
does not add mutual inductive declarations; total/mutual-WF construction and
P1's assumption blocker retain explicit refusals.

`Ps.Elab.RecursionParameters` owns typed fixed/evolving parameter analysis.
The selected Nat-measure path now supports one changing measured Nat plus
independent evolving Nat state and fixed Nat captures, in any header order.
Its real Nat.fix motive returns the state function. Ordered checked Core
lets preserve source argument evaluation; checked extensionality and
congruence derive the public equation without extending conversion.
`Ps.Erasure.WellFounded` revalidates the actual closed definition and entry
arguments, then uses ordinary typed self-call erasure for its callback.

New independent native/source fixtures exercise these constructions and the
existing five runtime targets. Prior `34f43e6b` passed focused/F1/F2/F3-F4 but
native source qualification found a refusal-diagnostic regression; it is not
accepted. This compiler candidate needs all five gates on its own exact SHA.
The accepted baseline remains `a7c6dade`; M3+B and all remaining boundaries
in the six-exit roadmap stay open. See both handoffs for exact evidence.
The dated candidate sections below are historical checkpoints.

## M3+B earlier source group cases candidate

Source matching now specializes the actual complete group recursor through
`Ps.Elab.GroupElimination`: one inferred/unified argument cursor, selected
family motive, checked PUnit companion motives/minors, and the real ordered
constructor telescope. Dependent indices, major/context refinement, and
case-only runtime suffixes reuse their existing owners. Group IHs are hidden
from source case branches; full group induction and cross-family structural
calls remain explicitly unavailable. No new group syntax or trust authority
is introduced. The source fixture compares fresh kernel equations and scalar
observations across five targets; this candidate still requires all five
gates on one exact SHA.

The underlying group-runtime and one-Nat well-founded fixtures passed all
focused targets at `5c8bc97280098ad768b6de5ab9283624f97e5149`, run
`38961009875`. Production/F-gate evidence on its predecessor is mixed-SHA;
the latest fully accepted compiler remains `a7c6dade`. Both handoffs retain
exact lineage. Deriving, broader nested traversal, broader total/mutual
strategies and P1's Classical.choice policy blocker remain open.

## Earlier M3+B candidate — typed group execution and checked Nat measures

Exit 1 now has candidate companion-worker execution on the retained complete
inductive-group plan, with shared captures and distinct per-family indices
and results. Exact checked worker equations and runtime identities are
revalidated before ordinary typed call erasure. The independent fixture
executes a parametric cross-family fold on all five target lanes and rejects
a well-typed stale worker equation. Source group Match/deriving and broader
nested recursive traversal remain open.

Exits 2 and 3 gain candidate measure/proof/span ownership and the selected
one-explicit-Nat-argument/Nat-result total recursion construction. The actual
body uses checked `WellFounded.Nat.fix`; each call needs a scoped decrease
proof, and `.eq_def` follows from checked `fix_eq`. Runtime lowering consumes
that typed construction. Independent proof/runtime fixtures cover arithmetic
decrease, ordered multiple call goals, shifted measure, default proof,
private namespace resolution, successor equation and phase-specific refusals.
Broader argument telescopes, mutual function cliques and general equation
normalization are still obligations.

Exit 4 includes the previously added P0 assurance/body identity and captured
recursive closure. The corrected group/P0/deriving focused suite passed at
test-only `0179354359c9e75de3e7b6f74d7e86835232dff6`, run `38958044907`.
Its predecessor's F1/F2/F3-F4 and full native passes do not constitute
five-gate same-commit acceptance. This new compiler checkpoint
must pass its own full native, F1, F2, F3/F4 and expanded focused workflows.

Exit 5 remains blocked by the actual `Classical.choice` dependency of pinned
`Lean.Order.fix`/`CCPO.csup` and its equations. The approved policy remains
only `propext` and `Quot.sound`; no P1 artifact or proof assumption is enabled.
Exit 6 and M3+B remain OPEN. The last fully accepted compiler is
`a7c6dade87a9d8df74d5248e8276623e7870078c`; approximately 40% was qualified
before these candidates (30–50% engineering uncertainty). Keep all six exit
criteria in the denominator and preserve workloads, checksums and budgets.

## Earlier M3+B shared-owner candidate — 17 October 2026

Native group formation now has one `Ps.Core.InductiveGroup` plan, staged
`Ps.Elab.Data` construction, and atomic canonical admission. The candidate
covers common dependent/alpha-renamed parameters, per-family indices, all
motives/minors, Prop elimination restrictions and unique retained descriptors.
It requires its own five-gate qualification. Portable group reduction now uses the shared plan and
is compared with independent checked kernel equations. Source group matching,
runtime/deriving consumers and nested auxiliaries remain unfinished; `.ps` mutual inductive grammar is not newly selected.

The included P0 candidate exposes ordinary/verified assurance selections,
selects the separately checked actual partial body only for ordinary host
emission, and records returned assurance in artifact origins. Both verified
grades refuse. The valid P1 suffix retains source identity but fails at the
exact `Classical.choice` dependency of pinned `Lean.Order.fix`/`CCPO.csup` and
generated equations; the approved assumption policy is unchanged.

M3+B remains OPEN. The six exit criteria below retain their full denominator.
Approximately 40% is qualified (30–50% engineering uncertainty), pending
acceptance of these candidates. Read both handoffs and exact CI receipts;
historical pending paragraphs do not supersede newer evidence.

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

## Active PSC0 v7.2 architecture authority

See [PSC0 native current/target/later architecture](../ARCHITECTURE.md) for one current set of semantic owners, supported features, Lean 4.35 comparison, future pass boundaries and milestone allocation. The previous PSC2 bootstrap architecture was archived verbatim at [history/PSC2_MINIMAL_SELFHOST_ARCHITECTURE_SNAPSHOT.md](history/PSC2_MINIMAL_SELFHOST_ARCHITECTURE_SNAPSHOT.md). Historical kernel/npm/self-host docs are **not** current M3+B instructions. M2+A unchanged; M3+B still OPEN.

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

# PSCV0 native implementation roadmap — v7.2 sole target

Updated 16 October 2026. **The sole forward `.ps` target is [v7.2](../PSCV0_LANGUAGE_REFERENCE_v7.2.md).** No v7/v7.1 compatibility mode, legacy grammar fallback or architectural restart. Apply the user's [stage directive](PSCV0_V72_STAGE_DIRECTIVE_2026-10-16.md) before every new slice. The [migration matrix](PSCV0_V7_TO_V72_MIGRATION_IMPACT_2026-10-16.md) separates actual semantic changes from formatting and specified behavior from implemented/qualified capability.

**M2+A remains COMPLETE for its original `pscv0-v7-native-bounded/73` profile. M3+B is OPEN.** The accepted [M2 exit review](PSCV0_M2_A_EXIT_REVIEW_2026-10-16.md) and [integration receipt](PSCV0_M2_A_INTEGRATION_QUALIFICATION_2026-10-16.md) are unchanged historical evidence, not full v7.2 conformance. Qualified integration2a707206 passed native38832366451, F1 38832366381, F2 38832366374 and F3/F4/platform38832366314; acceptance280e1e4e records its artifact. Do not repeat that integration.

## History and authority

The pre-v7.2 roadmap is preserved byte-for-byte in [pre-v7.2 history](PSCV0_NATIVE_IMPLEMENTATION_ROADMAP_PRE_V72_HISTORY_2026-10-16.md), blob `fe0d2e84f74d1544bfefd6962b1a5c8612c8413e`. Its research and development journals remain separately retained in their dated history files. Historical version selections and pending-run instructions describe their original checkpoints, not current authority. The v7 and v7.1 reference contents and previous adoption manifest are preserved without creating legacy source modes.

## Architecture and trust boundaries

Native portable `.lean`, official Lean4.35.0 `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Keep source syntax -> name resolution -> elaboration -> prepared Core -> official checking -> typed erasure -> validated IR -> target emission, retaining the same prepared graph. Study corresponding pinned Lean source/tests before each substantial change. `.lean` retains official Lean source semantics; ProofScript-specific grammar is for `.ps`.

Only `propext` and `Quot.sound` are approved logical assumptions. New source admission does not grant unchecked logical authority. A fixedpoint construction introducing additional classical dependencies remains unavailable under the current policy until explicitly resolved. No sorry, source axioms, unresolved proof/inference holes in emitted artifacts, unapproved dependency closure, weakened tests or enlarged budgets.

JS/TS share the ECMA lowering; retain Rust and Wasm GC, with linear memory only at explicit Canonical ABI boundaries. No pskernel-core, independent kernel, compiler-source `.ps` migration, self-hosting or immediate C5 execution. GitHub/cloud Linux only; preserve branches/history with expected-HEAD/non-force updates. PR109 remains draft/open on its existing base; never merge for milestone acceptance.

## Established dependency order

| Milestone | Shared architecture and selected exit |
| --- | --- |
| M0 | Accepted selected typed-erasure/IR foundation, not entire language |
| M1 | Accepted selected checked indexing/library foundation; preserve laws and boundaries |
| M2+A | Accepted selected constraints/search/defaults/rollback/replay/source retention and library/registry/module/runtime evidence at original profile |
| M3+B | General data/elimination, recursion strategies and deriving, extended by v7.2 partial P0 and selected fixedpoint P1 requirements |
| M4+C | General effects, operational outcome distinctions, ordinary partial execution and restricted typed runtime boundaries |
| M4+D | Contracts, partial/total/trace proof obligations, safe model/body/refinement and assurance identity |
| M5+E | Whole selected v7.2 conformance, dependency/target evidence, tooling/incremental/validated optimization/performance and C5 correspondence |

Continue **M3+B -> M4+C/D -> M5+E**. Collect final-E evidence and performance data throughout; solve measured shared bottlenecks when relevant, not through isolated backend-specific source semantics.

## M2+A acceptance retained, not reopened

All six original selected criteria are accepted: (1) checked indexing and selected libraries; (2) five selected checked deriving handlers and refusals; (3) common scoped constraints/instance keys/default ordering/fresh replay/rollback and measured scaling; (4) retained source scopes, references, inserted evidence and once-only projection resumption; (5) strict declaration and live-surface registry/assumption/provenance audits; (6) complete source/kernel/IR/module/backend/GC/ABI/native-host measurement and history-preserving exact integration qualification. Exact owners and results remain in the original exit review; this migration changes neither those receipts nor their bounded denominator.

That completion is not full data/recursion/deriving, a general semantic-preservation theorem, complete verification, production-speed acceptance or v7.2 conformance. Additional v7.2 obligations below are tracked separately.

## M3+B detailed exit — v7.2

1. **Data and elimination:** selected heterogeneous/indexed/dependent and recursive type formation, nested/mutual inductives, constructor consistency, strict positivity, independent motives and recursive pattern matrices. Preserve invalid-index and elimination refusals and proof/runtime erasure on supported backends. Expand deriving through shared data mechanisms.
2. **Owned source strategies:** implement §0B/§2/§5 declaration-head/modifier matrix and body -> recursion suffix -> where ordering. Preserve total-only const, nullary function ownership and compatible mutual strategy rules. Invalid prefixes, duplicate/mixed strategies and wrong suffix ownership reject at intended rules, not unrelated parse errors.
3. **Total recursion:** structural and well-founded elaboration with checked decreasing evidence and exact logical equations; no partial/unsafe shortcut around totality promised by the declaration or contract.
4. **Partial P0 ordinary source:** selected partial def/function, inhabited-result admissibility, checked body typing and logical opacity, explicit executable-body/dependency identity and supported backend lowering. A partial body is not a definitional equation for proofs. Source parsing alone does not close this criterion.
5. **Selected partial_fixpoint P1:** pinned construction/monotonicity, independently checked generated equations and transitive assumption audit. Keep unsupported models or forbidden classical dependencies unavailable rather than broadening policy. Equations do not by themselves prove executable termination, source/model correspondence or target refinement.
6. **Cross-stage qualification:** source/kernel/IR, positive/negative phase-correct fixtures, preserved module/API/proof erasure and admitted backend execution. Ordinary execution must not acquire a verified label. Verified use with unavailable model/refinement remains rejected. Update both handoffs and exact evidence for each completed slice; full M3 closure requires all selected v7.2 criteria, not just one runtime optimization.

## M4+C effects and executable behavior

Generalize through checked bind/pure and selected StateT/ReaderT/ExceptT and appropriate instances. Cover typed do, mutable/erased state, for/while, early return and selected throw/try/catch/finally, explicit world/IO/FFI boundaries. Accommodate ordinary partial execution without equating Return, Throw, Trap or Diverge. Define failure/effect semantics independently of JavaScript exceptions.

Bare ordinary while may execute only under explicit ordinary admission with no behavioral certificate. Total verified loops require invariant, measure and checked effect/proof rules. Potentially divergent verified loops stay staged until the selected operational finite-trace model and target correspondence exist. Restricted unsafe needs an exact registered typed runtime capability, never proof-producing authority.

## M4+D contracts and assurance

Produce kernel-checked proof terms for selected rewriting/simp/omega/grind and admitted automation. Implement given/requires/ensures, proof-only assert, invariant/decreasing and selected Std.WP/vcgen/spec-tail obligations with traceable ledgers. Contract-bearing ordinary source may not discard an unimplemented or unproved contract.

Distinguish type correctness, partial correctness, total correctness, finite-prefix safety and separately promised liveness/progress/fairness. Opaque partial/unsafe behavior requires a safe checked operational model and a proved relation to the executable body for verified use. A normal-return postcondition alone does not prove safety of a never-returning service.

One `.ps` language has explicit ordinary checked, closed verified and boundary-qualified verified artifact identities. Every emitted artifact must truthfully identify its assurance. **No verified executable while any applicable specification, effect, assumption, dependency, termination/trace, erasure, executable-refinement or target obligation remains open. Never automatically downgrade a verified request to ordinary.** Boundary assumptions must be precise, immutable, disclosed and permitted; strict closed policy rejects unsupported external assumptions.

## M5+E full selected v7.2 conformance

Close source-rule -> positive/negative fixture -> exact phase -> pinned Lean elaborated-term/semantic correspondence -> checked IR/backend matrix. Separate parsing, kernel acceptance, ordinary execution, verified admission and formal target correspondence. Validate transitive assumption/primitive/erasure safety, environment cryptographic identity, public/private modules, JS/TS/Rust/GC/Wasmtime evidence and reproducible version/SHA/artifact records.

Complete incremental compilation, tooling, validated optimization/performance and C5 source reconstruction/correspondence. Only then declare selected core/essential v7.2 complete; the earlier bounded M2 all-green result is insufficient. Compiler-source migration/bootstrap and independent kernel remain separate future tasks.

## Qualified runtime slice and performance limits

The [M3 runtime receipt](PSCV0_M3_RUNTIME_QUALIFICATION_AND_PAIRED_PERFORMANCE_2026-10-16.md) qualifies compiler133af061 and records paired same-runner study38840337837. Actual-AST suspension analysis and generic lowering passed all native and independent workflows; generic Nat/Bool recursion ran100000/50000 steps. The same-runner study found about9.25–10.11x improvement for List-to-Array conversion and smaller head/array gains, **not a meaningful deep-list lookup or reversal improvement**. Do not relabel old247x–3158x native-Lean ratios as compiler throughput, universal language speed, Rust performance or solved production performance.

Next measured work is actual-IR closure/dictionary specialization and safe recursive/direct-call lowering, preserving generic instantiation, scope, evaluation order, failure behavior, persistent representations and stack safety. No source-name special cases or unchecked Number substitution. Keep original benchmarks and add representative workload evidence rather than hiding a regression with changed iterations or budgets.

## Direct-recursive Repr accepted — 16 October 2026

The [Repr qualification receipt](PSCV0_M3_RECURSIVE_REPR_QUALIFICATION_2026-10-16.md) records exact compiler/test commit **4501164e5f1c32e00c81ae98d171e7bf201d1907**. Native38898123679, independent F1 38898123552/F2 38898123501/F3-F4-platform38898123787 and focused recursive deriving38898124015 all passed that commit. The full native pipeline passed all33 reported steps, with none skipped. Artifact identities and digests are in the receipt, not inferred from prior runs.

Repr now handles selected direct uniform nonindexed recursive families through the shared checked induction interface. Exact native-oracle strings for generic Nat/Bool trees passed JS, strict compiled TS, Rust, V8 GC and Wasmtime. The existing Hashable law and refusal cases remain; three Repr refusal cases cover unsupported nested/indexed families and missing independent dictionaries. One obsolete native direct-Repr negative became an unsupported nested-Repr negative while its assertion and intended failure phase were retained. The temporary preparation workflow was removed. Parent58d439's abstracted-motive correction and checked Hashable remain preserved.

**This closes the Repr slice, not M3+B.** Broader recursive BEq/DecidableEq, nested/indexed/mutual data and deriving, motives/patterns, total recursion and selected P0/P1 execution/assurance/fixedpoint obligations remain governed by the unchanged M3 exit above. Current partial logical checking retains an independent inhabitant, public opaque logical self and the actual typed private partial marker; all partial executable admission still fails before erasure. Never execute the inhabitant or infer runtime verification from logical opacity.

No new speedup or general compiler-preservation result is claimed. Continue shared mechanisms and focused qualification from this accepted baseline rather than repeating the completed Repr gate or reopening M2+A.

## Direct-recursive BEq accepted; DecidableEq candidate — 16 October 2026

The [BEq qualification receipt](PSCV0_M3_RECURSIVE_BEQ_QUALIFICATION_2026-10-16.md) accepts compiler **058fb67f1eec12add5adc1b3419644eb7e7363c5**. Native38905476639, F1 38905476304, F2 38905476313, F3/F4/platform38905476451 and focused38905476153 all passed the same commit. All33 native steps passed, none skipped. Exact native/focused artifacts12049320144/12048186682 and their digests are recorded in that receipt.

Selected uniform nonindexed direct-recursive BEq now uses checked left-child comparison hypotheses, right constructor case analysis, independent field dictionaries and no reflexivity/pointer shortcut. Native-oracle comparison masks, a non-reflexive field dictionary, checked defining law and all selected target lanes passed. Two obsolete direct-recursive negatives became unsupported nested cases without changing their rejection assertions or phases. This entry supersedes the historical Repr entry's pending BEq status, not its accepted evidence or the unchanged full M3 exit.

The next [recursive DecidableEq candidate](PSCV0_M3_RECURSIVE_DECEQ_2026-10-16.md) extends the same induction mechanism with actual child decision proofs and existing equality transport. Its native-oracle fixture includes proof-bearing recursion and equality independent of custom BEq. **That new compiler remains unqualified until its own five same-commit workflows pass.** BEq success is not DecidableEq or full M3 acceptance. Broader data/elimination/total recursion/P0/P1 remain open; no new performance improvement is claimed.


## Selected definitional strict-child recursion — accepted 16 October 2026

The [qualification receipt](PSCV0_M3_STRUCTURAL_CHILD_QUALIFICATION_2026-10-16.md) accepts `8e7f18885a3e917fbdf000d7d108842b2cc1f067` after all five same-commit workflows passed. No general source `k + 0` projection inference, arbitrary arithmetic decrease, non-first computed major, broader inductives, partial execution or fixedpoint is implied. M3+B remains OPEN. Its older pending deriving text above is historical; exact recursive DecidableEq is already accepted separately.

### Current candidate: computed strict major after unchanged prefix

The accepted strict-child receipt above remains immutable. Candidate extending first-position-only admission to later explicit parameter positions requires all earlier arguments be identical local binder references, retaining once-only elaboration and dependent telescope checks. A pinned-Lean oracle and exact-phase changing-prefix refusal are included in the existing focused suite; qualification pending. No other M3 exit item is claimed closed.

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

## Accepted M3+B fixed and evolving prefix recursion

Compiler/test `8f8aa47fc3b742488bd1ce4ad15024a63c0b6d4f` passed native 38928344482 (33/33 steps), F1 38928344465, F2 38928344501, F3/F4/platform 38928344471 and focused 38928344644 (pinned Lean / JS / TS / Rust / V8 GC / Wasmtime). Read [exact qualification](PSCV0_M3_PREFIX_RECURSION_QUALIFICATION_2026-10-16.md). Both unchanged-prefix computed child and separately checked evolving-prefix worker normalization are qualified in the selected family. Prior candidate pending statuses are historical. M3+B overall OPEN; source strategy, nested/indexed/mutual data, larger elimination, total well-founded recursion, P0/P1 and full cross-stage exit remain pending.

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

## Cloud fixture and metadata runtime follow-up — 2026-10-17

The repair compiler/test head `5ed2d88c961f04f05a62181a43e4dd2d551a73ef`
compiled the production compiler. F1 [38997709319](https://github.com/dwijayuda/pskernel/actions/runs/38997709319),
F2 [38997709253](https://github.com/dwijayuda/pskernel/actions/runs/38997709253), and
F3/F4 [38997709351](https://github.com/dwijayuda/pskernel/actions/runs/38997709351) passed.
Native [38997709234](https://github.com/dwijayuda/pskernel/actions/runs/38997709234)
and focused [38997709365](https://github.com/dwijayuda/pskernel/actions/runs/38997709365)
failed at distinct observed boundaries; no accepted points are added.

Native job `117293801945` reproduced the exact 34-declaration, zero-candidate-axiom,
three-recursor-rule WF asset (466,947 bytes; SHA-256
`b6bd56c4ab6378905d1d3ac2f0155eb5bc4742be3e19e684d64ac1a3007716f3`).
The initialized import then needed the native external symbol `IO.getRandomBytes`.
Pinned Lake's `LeanExeConfig.supportInterpreter` exposes executable symbols to the
interpreter; this follow-up enables it only on `pscv0_native`, which runs the audit.
Native source/Standard checks still passed at 5ed2d88, but later module/runtime
workloads were skipped after the audit failure. No prospective WF pins were printed
or activated. The active 3,599 declarations, 39 classes and 355 ordinary instances
and all three Standard/surface pins remain unchanged.

Focused job `117293802567` rejected two multiline assertion branches in the empty
dictionary fixture. Their branch bodies are now indented as complete applications;
both predicates, messages and refusal boundaries are unchanged.

The indexed native oracle also exposed parameter-name agreement in mutual
inductives, native index promotion, and matches over fixed local index values.
The fixture correction preserves genuinely indexed native declarations, asserts
their exact parameter/index counts, and computes native outputs through generalized
observers of the actual derived defaults. The portable constructor-directed owner,
four derived instances, four native/portable generic equations, eight checked output
equations, four refusal contracts, five target lanes, and all prior fixtures remain.
A fresh complete five-gate matrix at the resulting head is required.

Accepted compiler/test SHA remains `03000e7b0c257fb8f8d2e2b387b7b65a53e8f504`;
weighted M3+B remains **74/100**, open. PR 109 remains draft/open/unmerged.

## Native indexed parent-observer follow-up — 2026-10-17

At `078fb1e2c22f79e7f4eae2f21863e2cad4fa1434`, F1
[38998692100](https://github.com/dwijayuda/pskernel/actions/runs/38998692100), F2
[38998692059](https://github.com/dwijayuda/pskernel/actions/runs/38998692059), and F3/F4
[38998692085](https://github.com/dwijayuda/pskernel/actions/runs/38998692085) passed.
Native [38998692067](https://github.com/dwijayuda/pskernel/actions/runs/38998692067),
job `117296813544`, passed the initialized WF foundation audit and is still
running its later workloads at this checkpoint. Retrieve the completed audit JSON
before using any prospective identity; no pin is inferred from a successful step.

Focused [38998692088](https://github.com/dwijayuda/pskernel/actions/runs/38998692088),
job `117296813222`, has one remaining compilation error: the nested native
`Second.mk k (First.mk m item)` pattern attempts to refine the already-bound
index `k`. The exact seven native parameter/index counts passed, every native
default equation and refusal compiled, and the empty dictionary executable built.
The repair inspects the parent through its own generalized `parentScore` helper,
then combines the actual outer index with the actual parent index and payload.
The portable fixture namespace is byte-identical. All existing equations, refusal
contracts and runtime outputs are preserved.

No completed five-gate success is claimed. Accepted compiler/test SHA remains
`03000e7b0c257fb8f8d2e2b387b7b65a53e8f504`, weighted **74/100**, M3+B open.

## Prepared typed well-founded relation selection — 2026-10-17

This candidate extends the checked unary changing-argument route from a Nat-only
measure to an explicitly typed fixed-codomain measure with an actual synthesized
`WellFoundedRelation` dictionary. It shares a typed relation/fix application plan
between elaboration and erasure; both consumers still validate actual checked Core
in the original local context. Fixed captures, evolving/dependent state, source
argument order, explicit proof slots, result applications and public equations retain
their existing checks. No runtime relation is guessed from source spelling.

The pinned native selection rule is retained: use `WellFounded.Nat.fix` only when
the codomain converts to Nat and the selected dictionary converts to `Nat.lt_wfRel`.
Otherwise construct the real `invImage` dictionary, its relation and well-founded
proof projections, `WellFounded.fix`, and `WellFounded.fix_eq`. The bounded
selected proof closure does not include Lean's `opaqueId` barrier; the direct
proof remains subject to inference, independent kernel admission and performance
qualification. No assumption, conversion rule or unchecked body is added.

Seven reviewed files add the shared Meta owner, source and typed erasure consumers,
the existing Lake registration, and native/source lexicographic left/right examples
with open public equations and Core-kind checks. The WF batch becomes 19 requests:
two positives and 17 semantic refusals. All 12 prior scalar exports remain, with
`m3wfrelationsoutput` as the thirteenth: ten additional comparisons over two
Boolean inputs and JavaScript, strict TypeScript, locked Rust, V8 GC and Wasmtime.
The added refusals retain multiple measured changing parameters, varying measure
codomains and an unproved same-argument generic recursive call.

This prepared implementation depends on activating the exact independently audited
WF foundation. The following activation must use the completed native audit's
observed FNV, declaration SHA-256 and source-surface SHA-256, then qualify the final
selected Standard and compiler through all five cloud gates at one SHA. Neither
the audit step nor this reviewed source candidate adds accepted points.

The separate seven-file dependent-argument packing candidate remains staged and
unqualified. Its reviewed patch SHA-256 is
`0dfb9d68393fb9b707e0d27ec71d84e40da8d3222eec8b7c8d3e82c882e0afe7`.
It is not included in this relation-selection commit.

Accepted compiler/test SHA remains `03000e7b0c257fb8f8d2e2b387b7b65a53e8f504`;
weighted M3+B remains **74/100**, open. PR 109 remains draft/open/unmerged.
