# PSC1 development roadmap

Updated 2026-10-22. The authoritative finite scope and dependency-ordered queue
are [PSC1_PRACTICAL_CORE_V1_CONTRACT.json](PSC1_PRACTICAL_CORE_V1_CONTRACT.json).
It freezes fourteen families, 37 acceptance criteria and four actual applications.
This is the single active roadmap. Older status matrices/continuation prompts and
receipts are historical evidence, not competing release authorities. Detailed
semantic rationale remains in PSC1_PRACTICAL_CORE_DECISIONS.md.

Execute the contract's workQueue in dependency order: independent collection
reference, real JSON application, inference/control coverage, typed capability IO, checked numeric
order, practical application/performance completion, then
feature freeze. Start each task with its exact acceptance and a small coherent
change. Reuse working architecture and shared semantics; author both grammars,
exercise JS/TS/Rust early, then all seven mappings before qualification.
Missing acceptance runners are blockers, never inferred successes. Retain all
working features outside the finite scope.

CI has four tiers in psc1-development.yml: fast static contracts/syntax, focused
native plus JS/TS/Rust, integration complete-source closures plus G1, and full
scoped seven-target/minimum-runtime/package qualification. Incremental selection
uses the last successful gate/head interval, not cumulative PR paths. Failed or
cancelled updates retain their testing debt; an unavailable baseline or changed
base falls back to full qualification.
Unknown/unavailable diffs fail conservatively into full testing. Documentation
does not restart compiler jobs. Workflow/authority/build/target changes require full testing. The two pure
selector helpers use static API/dependency regressions; all semantic and release
controllers retain their required tiers. Existing workflows remain manually runnable and reusable; no assertion
or refusal is deleted. Specialization's immutable baseline runs when its benchmark
changes, not on every documentation/source update.

Caches contain pinned tools and exact-source Lake objects only. Every selected
job still builds its requested targets, checks official pins, and regenerates
admission, strict IR, execution and publication evidence. Evidence is never a
cache hit. Concurrency cancels obsolete PR work; explicit manual full runs are
retained. Selection/readiness JSON artifacts expose what ran and why. Require
the incremental gate plus fresh full qualification before merge/release; use
manual psc1-development with full=true to rerun all qualification dependencies.
Repository protection settings have not been changed. The separate manual
psc1-practical-release workflow reruns native/closure/G1/full scoped qualification
and enforces --require-ready; it cannot pass an incomplete Practical Core contract.

Run scripts/practical-core-readiness.mjs to derive implemented/tested/qualified/
blocked criteria from current fixture registration and exact-commit receipts.
The generated dist/development/practical-core-readiness.json is an inventory,
not a proof or admission credential. --require-ready must pass for a release;
the unfinished compiler-like/performance acceptance and unbound finite criteria block
that gate. Historical receipts remain exact historical facts, not current-HEAD
qualification. Full scoped success is necessary and is not release readiness.

Practical Core language and compiler/backend engineering proceed independently
of PSKernel-Core Expression V2 research. Independent official Lean 4.35.0
admission at eb6cafb7290e8bd5f2937522d8d804f58f02bafc, strict original/transformed
IR, ordinary pairing, security/resource policies and all negative tests stay
required. Do not import incomplete kernel research into compiler release gates.

G1 source, tests, successful receipts and artifacts remain preserved; normal
integration runs the ten-case v2 corpus after one native seed, with no subsequent
native frontend/emitter delegation. G2/G3/fixed points and expensive profiles
remain separate manual qualification after stable feature freeze. The open
PSC1_G2_PERFORMANCE_DEFECT_2026-10-21.md retains original heap-exhaustion and later
timeout evidence. Address it when ordinary application compilation reaches the
same mechanism, not merely to self-host an unfinished compiler.

The checked-order/application continuation at
af0a5921aa2f3fa4dbf4959d5e2c3b14a843d972 passes full Linux run 39655009732,
tested merge 006ff602e2bce6dcbcad6b970f99307f3a3e7a34. Static/native/focused,
all complete compiler closures, G1, host boundary, full integration and aggregate
gate pass. Both/seven execute 56 checked-order obligations, 294 actual CLI/JSON
process cases and 28 library obligations, with minimum-Python counterparts.
The shared JSON parser rejects trailing commas and Wasm public labels no longer
expose internal hygiene names. Exact evidence and preserved G1 identities:
PSC1_ORDER_APPLICATION_QUALIFICATION_2026-10-22.json.

Readiness is 16 qualified / 21 blocked criteria. CLI, JSON/files and multi-module
library applications are scoped-qualified. Compiler-like/performance acceptance
and unbound family criteria still block Practical Core release readiness.

The active source continuation implements the fourth application: a streaming
decimal-addition compiler pipeline in both authored grammars, independent native
reference, typed byte/line/column diagnostics and twelve finite actual process
cases. Its 100000-statement/500000-byte input has a 120-second/1-GiB external
process acceptance bound, with retained measurements. Existing compiler/host/ABI
limits remain unchanged. JS/TS/Rust and both Wasm consumers run early; full
qualification also requires Python/PHP and minimum Python. This descendant is
implemented, not qualified, until its exact-commit CI completes.
See PSC1_COMPILER_APPLICATION_V1.md and PSC1_COMPILER_APPLICATION_CONTRACT.json.

After the application/performance work, complete the 21 unbound family criteria
in dependency order using actual independent-reference, negative and publication
evidence. Existing tested behavior must acquire complete finite acceptance, not
a cosmetic status binding. Then require the full release workflow and feature
freeze before resuming manual G1 -> G2 -> G3 qualification.

The earlier typed IO qualification at 74179eb664e132502a24ce60b52a3dbd52b1d0cc
(run 39627387430), f799 inference/protocol, 5a0f sequencing and 1fbf standalone
receipts remain exact historical evidence. Sources, artifacts, successful CI and
all diagnostic history remain preserved. G2/G3 remain deferred.

## Measured application runtime continuation

Run 39664407902 at 5fa88fa1842d8d8d9fa1881592ed2801d2778b37 passes native,
focused, all complete closures, G1 and host boundary, but full qualification
fails PHP's 500000-byte compiler workload at the outer 180-second guard.
Both minimum-Python consumers pass. The unchanged acceptance is 120 seconds /
1 GiB; no four-application completion is inferred. Exact diagnostic inventory:
PSC1_APPLICATION_PERFORMANCE_PROGRESS_2026-10-22.json.

Complete the PHP whole-String UTF8 validation/byte-lookup correction and the
measured Rust read-only String-copy correction, then require fresh all-seven,
minimum-runtime and aggregate qualification. A separate focused PHP lane retains
all previous focused targets and existing per-job/process limits. Do not resume
G2/G3 or advance feature freeze while this application or the 21 remaining
family criteria are blocked.

## Latest application qualification and active finite acceptance

Source 81824afb29cff6e22a693f7988797dd62a524026 passes complete run 39672943069,
including full job 119480025557 and aggregate gate 119495645657. The earlier PHP
timeout is corrected under the unchanged 120-second/1-GiB workload bound.
All four frozen application categories now qualify in scoped execution.
The exact historical machine report remains 16 qualified / 21 blocked, not a
Practical Core release. See PSC1_COMPILER_APPLICATION_QUALIFICATION_2026-10-22.json.
This supersedes the application-blocked current-state wording above; all failed
runs remain historical evidence.

The active source adds nine complete finite coverage bindings for arithmetic,
short circuit, transactional inference/calls and owned control/handlers. It is
implemented, not qualified before fresh Linux evidence. Eligibility becomes
25/37 criteria; the twelve unbound criteria are for-loop collections/ranges/
streaming, while controller/divergence, partial pairing/recursion, products/
identity, Array operations and namespace identity/ownership. Their acceptance
meanings remain unchanged. See PSC1_BOUNDED_CORE_ACCEPTANCE_2026-10-22.md.
Continue the remaining queue after validating this coherent group. Full feature
freeze and the manual release gate still require every criterion and application.
