# PSC1 active work state

## Active Rust and TypeScript priority pivot (2026-10-23)

Rust and TypeScript now lead actual self-hosting qualification. DirectJS stays
working as a reference/regression; further DirectJS-specific G2 tuning is not
prioritized. Existing successful and failed evidence below remains historical.
The compiler source/front end/elaborator/checked IR/admission are shared through
Ps.Compiler.Service; target facades use existing production emitters. New manual
Linux matrix qualification seeds once per target, then requires actual target
execution, all ten frozen cases and independent G1/G2/G3 source/graph/IR fixed
points without native compiler delegation. No current Rust/TS generation is
claimed qualified before CI. Resources, official Lean, all-seven Practical Core
coverage and publication restrictions remain unchanged. Architecture and exact
execution procedure: docs/PSC1_RUST_TS_SELFHOST_ARCHITECTURE.md (roadmap-relative:
PSC1_RUST_TS_SELFHOST_ARCHITECTURE.md). Next: execute the new manual matrix,
fix target/source blockers as classes, capture exact tool/runtime evidence and
complete fresh normal qualification after compiler changes.


Updated 2026-10-23 (Asia/Jakarta). Draft PR #172:
https://github.com/dwijayuda/pskernel/pull/172
Branch: fix/psc1-closure-normalization-20261021.
Use connected GitHub and Linux Actions only; no local checkout/files/build/tests.
Fetch remote HEAD before expected-HEAD, non-force updates. Preserve history.
Merge and registry publication require separate authorization.

## Latest candidate and qualification

Compiler source 7732e9786d09d11c1130da4b315c985e9978f23b; tested merge
055ba9833567d3cb166341ec1da794eb725b0414; base
1fad9ed53cda9b23ac30be9cea85e7857437564e.
Normal qualification run 39867567126: success; every selected job and all 47 full-job steps pass; readiness 37/37.
Exact jobs, steps, readiness, source/IR/checker/package identities and artifacts:
docs/PSC1_SELFHOST_RESUMPTION_QUALIFICATION_2026-10-23.json.
The frozen contract remains 14 families, 37 criteria, both grammars, seven
targets and four actual application categories. No criterion or workload changes.

G1: passed all ten frozen positive/negative cases in job 120137606421.
Service SHA256 d2093ee1d08c561ae62efb259fc834a4873b49684fc8516ac6e82a96783c8efb.
86-module closure 7c87bfc922a4d8dabae343c47f470bff5d5ad11166d18125f14232fdb785edea.
Admission and original/specialized IR digests remain in the exact receipt.
One native seed only, generated frontend/emitter thereafter, separate official
checking. The normal G1 controller's deferred fixedPoint field is lane-local;
it does not supersede the explicit manual results below.

G2/G3 fixed-point qualification remains incomplete. Latest actual manual
39864113546/job 120121869892 at source 573bf485 passes the frozen ten-case G1
corpus, then G2 times out at 240197 ms before admission/publication. G3 is not
run. That failed source precedes the final local-binding correctness guard;
no G2 execution result is claimed for the latest changed source.
docs/PSC1_G2_STABLE_CAPTURE_FAILURE_QUALIFICATION_2026-10-23.json preserves
the exact failed source/request, profile and diagnostic progress evidence.
The original G2 heap-exhaustion defect and every later failure remain open.

## Implemented corrections and verification

Parser primaries avoid unused optional-index span/fuel traversals; nomatch
helpers bind remaining inputs before recursion setup. Canonical token cursors
retain exact decreasing counts and both grammars' old numerical fuel, adjacency,
spans and refusals. Lexer length uses the supported accumulator form. Empty
term/level assignment guards preserve exact scan/walk results.

Seven total core/name/level visitors defer 26 recursive helper constructions
until the final input binder. Native tests retain original definitions and prove
all-input function equalities, plus count/lexer/empty-substitution identities.
Unresolved metas, active term assignments and independent universe assignments
remain tested. These source equalities are not a backend-preservation theorem.

Typed worker fusion removes capture lets only for literals or initialized local
variables unshadowed throughout the alias body. Conservative scanning covers
let/lambda/match binders and every child; exhaustion keeps captures. Nonlocals
retain read timing: a forward global can throw before initialization.
Original declarations, effect/non-value refusals and strict input/output IR
rechecking remain. All earlier escape/order/continuation/divergence/resource
tests stay, with self/lambda/match shadow and forward-global timing cases.

Native job 120133933097 passes the reference proofs and actual original/fused
execution. Both forward-global imports raise ReferenceError before later
divergence. Its bounded worker corpus measures 945 ms baseline / 557 ms fused,
with identical observations and prior 100000-step/billion-bound workloads.
This does not establish whole-compiler speed, memory bounds or preservation.

## Measured remaining G2 blocker

Exact failed replay: 240346 ms, 49211026 raw profile bytes,
artifact 12462609800, ZIP SHA256
7960b253039c3fe80ac52901f6b45fd0dd84b2f24bb09d216b2a7da7170ef1d0.
Read-only run 39865901653 splits 208130 ticks into four windows. GC is 36966
samples (17.8%, previously 22.5%); the inspected substitution worker has no
redundant capture temporaries. This sampled comparison is not a total-cost proof.

Diagnostic run 39866505167/job 120129917036 instruments a copy only, at commit
9d60de0c89677d4330645f49961ff0bcd1debee8 on its separate diagnostic branch.
Original request/service identities stay fixed; no response is adopted, admitted
or published. At 240 seconds the trace has entered 29/86 modules, last entering
declaration index 59 in module 28 Ps.Bridge.CheckedAdmissions, with RSS
2381944 KiB at that point. Entries do not prove completion; logging affects
timing. Artifact 12465125123 retains the counters/identities. The remaining
work concerns general frontend/elaboration throughput and lifetime.

The complete 256-declaration ParserScale workload remains a separate opt-in
probe. Prior measured compile 210139 ms / 696784 KiB / answer42 is an open
normal-frontend scale defect. Never shrink it or silently add it to the frozen
ten-ID generation manifest.

## Manual execution policy and continuation

Separate psc1-selfhost-qualification.yml retains workflow_dispatch and an explicit
committed-request fallback because the connector has no dispatch action.
Only its request path on this branch triggers push qualification; preflight
binds exact event/parent/HEAD and refuses hidden compiler edits. This is a
push-explicit-request event, not workflow_dispatch. Normal CI still runs only G1.
Failures retain exact requests/graphs/stderr and bounded CPU samples for 90 days.

Do not raise 240000 ms child deadlines, heap/stack/fuel policies or the 15-minute
manual job limit. Never delegate generated semantics to a native compiler or
weaken strict original/transformed/target IR, independent official admission at
eb6cafb7290e8bd5f2937522d8d804f58f02bafc, witnesses, negative tests, unsupported
ABIs, package provenance or final qualification. PSKernel-Core Expression V2
research remains independent.

1. Address the measured general frontend/elaboration scale and lifetime issue
   using exact requests and representative normal large-source applications.
   Require finite measured improvement and fresh correctness/full evidence.
   Do not replay unchanged expensive failures.
2. Then explicitly qualify the finalized source through G1/G2/G3. G2 must match
   all source/admission/IR/output identities, independently admit, publish only
   to CI staging and pass every frozen corpus/refusal obligation before G3.
3. Require actual G3/fixed-point evidence before claiming self-hosting. Keep
   separate authorization for merge and release publication.

## Preserved baseline and history

Historical source 9ee6c5ffe8ac344b349fde7eee8f5ef867bd5dde remains qualified in
run 39829564386, tested merge 00decc7fb81fc4023f68cdcdbf8cff1fdd028b12.
Its immutable v1 receipt, derived release inventory, package/expiry evidence
and successful G1 remain source-bound historical evidence. New compiler bytes
have separate exact-source evidence; no old qualification is inherited.
Unrestricted metaprogramming/effects, unsupported public compound ABIs,
non-Linux distribution and formal compiler-preservation certificates remain
outside finite v1.

PSC1_DEVELOPMENT_ROADMAP.md is the single roadmap;
PSC1_PRACTICAL_CORE_V1_CONTRACT.json is the single machine release contract.
The pre-reconciliation state is preserved verbatim in
docs/history/PSC1_SELFHOST_RESUMPTION_HISTORY_THROUGH_7732E978_2026-10-23.md.
Earlier histories and all dated failed/successful receipts remain intact.
