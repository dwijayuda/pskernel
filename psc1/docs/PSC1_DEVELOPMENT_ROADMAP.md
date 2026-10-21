# PSC1 development roadmap

Updated 2026-10-21. The authoritative finite scope and dependency-ordered queue
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
all four actual-application runners and unbound finite criteria currently block
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

The typed IO continuation at 74179eb664e132502a24ce60b52a3dbd52b1d0cc passes
full Linux run 39627387430, tested merge 2a6dbec7b7f3d02c6dc6399360422da350e646e7.
Both grammars/all seven execute 28 general sequencing obligations plus 4 on minimum
Python. Fourteen actual IO consumers, two minimum-Python consumers, two installed
unpublished-package consumers and 80 host policy cases pass. Core/component
String ABI, foreign-trap separation, strict memory/schema checks and oversized
request refusal are included. The typed-io family's three finite criteria are
scoped-qualified; readiness is 15 qualified / 22 blocked, releaseReady=false.
See PSC1_TYPED_IO_EXECUTION_QUALIFICATION_2026-10-21.json,
PSC1_TYPED_IO_V1.md and PSC1_WASM_STRING_ABI_V1.md.

Continue unbound inference/control criteria, constructive checked numeric order,
then complete CLI/JSON/library/compiler-like application acceptance and measured
large inputs. Existing partial application regressions remain; source execution
does not imply complete four-application or release qualification. Preserve the
f799 inference/protocol,5a0f sequencing and1fbf five-target standalone receipts
with their original source and CI identities. G2/G3 stay deferred until freeze.

## Active continuation: checked order and actual applications

Constructive Nat/Int ordering is implemented and native-admitted in run
39636740787; target/full qualification is pending. PracticalCli supplies both
authored source grammars and nineteen actual process-level CLI/JSON scenarios per
target. Its exact-commit matrix, minimum Python and full gates determine the two
application rows. Library and compiler-like/performance acceptance remain next.
No milestone here reopens G2/G3 or replaces the finite release contract.
