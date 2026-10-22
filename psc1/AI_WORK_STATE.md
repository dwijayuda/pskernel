# PSC1 active work state

Updated 2026-10-23 (Asia/Jakarta). Draft PR #172:
https://github.com/dwijayuda/pskernel/pull/172
Branch: fix/psc1-closure-normalization-20261021.
Use connected GitHub and Linux Actions only; no local checkout/files/build/tests.
Fetch latest remote HEAD before expected-HEAD, non-force updates. Preserve history.
Merge and registry publication require separate authorization.

## Current qualified compiler source

Source 9ee6c5ffe8ac344b349fde7eee8f5ef867bd5dde, tested merge
00decc7fb81fc4023f68cdcdbf8cff1fdd028b12, base
1fad9ed53cda9b23ac30be9cea85e7857437564e, run 39829564386:
https://github.com/dwijayuda/pskernel/actions/runs/39829564386

Every selected gate passes: static, native, all three focused lanes, complete
semantic/JS/Rust compiler closures, G1, host-session boundary, full Linux matrix
and aggregate. Benchmark is dependency-skipped. All 47 full-job steps succeed.
Full job 120010034085; aggregate 120026838629; G1 120007421327.

The frozen Practical Core v1 contract is complete in this finite Linux scope:
14 families, 37 qualified criteria, 0 blocked, both grammars, all seven targets
and four actual application categories. Data releaseReady=true.
The authoritative receipt is
docs/PSC1_PRACTICAL_CORE_V1_QUALIFICATION_2026-10-23.json.
It preserves exact jobs/steps, observations, source/IR/admission identities,
artifact digests/expiry and the complete G1/closure evidence. No claim extends
to unrestricted Lean, arbitrary public ABIs or formal backend preservation.

Both/seven execution includes 252 inference/control obligations (36 minimum
Python), 56 collection obligations (8 minimum), 98 order obligations (14 minimum),
168 compiler-like and 294 CLI/JSON actual process cases plus their 24/42
minimum-Python cases, and 28 library obligations plus 4 minimum. All seven actual
IO adapters, native exact-once argument checks, ordinary pairing, privacy,
publication preservation, while refusals and genuine external deadlines pass.
All prior cases, workload sizes and resource ceilings remain.

The manual Practical Core wrapper invokes the same native/closure/G1/full
workflows executed here. Normal full qualification enforces the same readiness
assertion because requireReadyOnFullQualification=true. Qualification rests on
these completed checks; no manual workflow event or duplicate replay is claimed.

## Resolved normal compiler regression

The first small G1 case formerly timed out at 240 seconds in sources 56663b26
and bb59d544. Actual CPU sampling identified recursive printer workers built
before their expression lambda: three branches per fuel level at budget 4096.
WeakMap registration dominated the sample. This was eager setup over fuel,
rather than work over the visited expression graph.

All seven affected JS printer visitors now bind their remaining inputs before
constructing recursive helpers. Traversal algorithms, driver behavior, fuel,
heap/stack settings, deadlines and strict-IR restrictions stay unchanged.
G1 now completes that first case in 2254 ms (prior qualified baseline 2154 ms).
All ten selected G1 cases pass; five positive cases take 1.699-5.560 seconds.
The same single native seed is used, with no later native frontend/emitter
delegation and with separate independent official checking.

Current G1 service:
685d0a3816d5087ac8dee33b6db1be7c59d1369995519bee2d9b7fdfb3c61c3b
Source closure:
d453ba84f3c6f8631754826a75e36c082c64ed14da0118e8ef9b65ba1f8db0cf
86 modules; complete closure lanes have 70 semantic / 86 JS / 89 Rust modules.
G1 artifact 12449875258, ZIP digest
b49c9a3334a87d45396cd5df8ebf1ab86a7d7b2b1e50264788c5b54486df897b,
expires 2027-01-20T18:14:13Z.

PSC1_NORMAL_G1_PERFORMANCE_DEFECT_2026-10-23.md records resolution.
PSC1_NORMAL_G1_FAILURE_2026-10-23.json preserves the exact failed request,
profile and successful full companion matrix. Earlier qualified G1 and failed
attempts remain in Git and their original artifacts/receipts. The original
G2 heap/timeout defect is separate and is not marked resolved.

## Preserved implementation and CI mechanisms

Total deferred List/Nat folds and linear Array-to-List conversion stream
iteration. Total private Nat.rec controller helpers carry erased official
conversion theorems; well-typed changed behavior is refused. Rust uses strictly
rechecked worker fusion while retaining generics. Unknown curried callback
order remains conservative and has actual divergence-before-later-trap tests.
The 100000-step traversal and immediate return from a 10^18 bound pass.

JS/TS retain driven dynamic/non-tail calls and replacement of true tail frames.
The million-mutual-call and lexical capture/order/trap/divergence corpus passes
under its original 262144-KiB bound. Call-free closures stay ordinary functions.
Checked condition/operand sharing and local-let inference retain the 430-node
wrapper, native 64-expression bounds, dependent-let and negative/fuel guards.

Focused core and measured applications run in parallel 15-minute lanes with
the same targets, commands, child budgets and exact-source cache. Artifacts
carry lane/attempt identities. The selected integration tier precedes the full
tier; an integration failure cannot be reported as final qualification.
Failed/cancelled debt is retained. Documentation/qualification receipts select
only static checks after the successful compiler baseline.

## Release-facing reconciliation (2026-10-23)

Verified latest remote HEAD fc60604a6b9759da75f3f507b2b7a4868d57ef99:
the compiler qualification run 39829564386 and final documentation run
39837904301 both succeed. The latter selects qualified source 9ee6c5ff as its
baseline and skips heavy tests. No compiler/runtime/dependency bytes change here.

Release audit found stale README/conformance/IO/application claims and the old
status JSON, which still called typed IO missing and pointed to PR #169.
Reconcile current documentation with the exact finite v1 checkpoint; preserve
all historical sections and archive the old status under docs/history/.
docs/PSC1_RELEASE_CANDIDATE.md gives the exact tested package/hash, platform,
artifact expiry, supported ABI choices and remaining authorization boundary.

scripts/practical-core-release-status.mjs derives the current data-only status
from the single frozen contract and completed immutable receipt. Always-run
static readiness tests compare the inventory and reject inconsistent source,
matrix, gate, G1/closure/checker/package evidence. Exact inventory/test paths
select static checks; contract, readiness gate, compiler, host, workflow and
unknown machine policies retain their existing test tiers. No correctness or
final qualification assertion is removed. Linux run 39846954055 passes at reconciliation source
0b4d4b3f9ae98f37341f06df062ec23303b54094, tested merge
15e55bb274b3b64e17d3e7247979ef2a30c1b980. Static job 120062643558
and aggregate 120062995270 succeed; all heavy jobs are correctly skipped.
The selected baseline is fc60604a / successful run 39837904301. New consistency
and negative regressions pass. GitHub compare against qualified compiler source
9ee6c5ff confirms only documentation, derived inventory, pure static tests and
scheduling helpers changed. Complete run/diff/step evidence is retained in
docs/PSC1_RELEASE_RECONCILIATION_QUALIFICATION_2026-10-23.json.

## Remaining release work and deferred scope

There are no blocked finite Practical Core v1 acceptance items at the qualified
source above. Keep the candidate source stable for release review. A later
compiler/language change needs fresh relevant evidence and complete qualification
before it is called finished; do not inherit these results onto changed code.

G2/G3 and fixed-point qualification stay in the separate manual/release workflow
on finalized feature-frozen compiler source. Keep
docs/PSC1_G2_PERFORMANCE_DEFECT_2026-10-21.md and its original evidence tracked.
No G2/G3 result follows from the G1 fix. Incomplete PSKernel-Core Expression V2
research remains independent; official Lean 4.35.0 admission at
eb6cafb7290e8bd5f2937522d8d804f58f02bafc remains the production boundary.

Unrestricted metaprogramming, arbitrary effects, unsupported compound public
ABIs, non-Linux distribution and formal compiler-preservation certificates stay
outside the frozen v1 claim. Preserve explicit unsupported-ABI refusals and all
security, semantics, resource and regression boundaries.

PSC1_DEVELOPMENT_ROADMAP.md is the single roadmap.
PSC1_PRACTICAL_CORE_V1_CONTRACT.json is the single machine release contract.
Detailed historical work state is in PSC1_IMPLEMENTATION_HISTORY_2026-10-23.md
and the 22nd's history file.
