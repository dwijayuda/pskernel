# Python/PHP self-host execution

Use connected GitHub tools and Linux Actions only. Fetch fresh HEAD of
feat/psc1-python-php-selfhost-20261024 before expected-HEAD non-force updates.
Read AI_WORK_STATE.md, the single roadmap, architecture and preserved direct
qualification receipt. No local checkouts/builds/tests, PR merge or publishing.

1. Start from verified implementation24f93a383886894cb411ecb76ff38fa46dd47177.
   Source gate40069330525/job120799158087 PASSED both complete86-module closures,
   both grammars,34816 retained runtime comparisons, seven state/four arity
   complete API equalities,144 full retained-emitter comparisons, unchanged-wire
   transport negatives and four independently admitted runtime applications.
   Artifact12550731070 digest432892ba71dfd10da59fcc150fa0220476fae2881c27d199cfca10820afb603d.
   This proves source readiness and regression scopes, not compiler G1/G2/G3.
2. There is one portable emitter per target, behind unchanged native compatibility
   APIs. Keep CompilerService imports pointing to Portable; do not capture the
   native default-argument/metadata adapters or test references as compiler code.
3. Python3.14.8 and PHP8.5.12/ext-gmp are exact runtime guards. The setup action
   installed8.5.12 when8.5.11 was requested;40068963704 correctly refused drift.
   Workflows/inventory now explicitly request8.5.12 and retain the strict guard.
   Qualification records actual interpreter hashes and verifies them throughout.
4. After both closures pass, create one request-only child commit changing
   .github/qualification-requests/psc1-python-php-selfhost.json. Schema
   psc1-python-php-selfhost-request/1; exact current branch and parentCommit;
   action qualify-independent-G1-G2-G3; profile correctness-1800s;
   targets ["python","php"]; g2g3TimeoutMs1800000,g1TimeoutMs240000;
   resourcePolicy only-G2-G3-wall-clock-extended;all-other-policies-unchanged.
   No source/docs in request commit. The dedicated qualification workflow
   independently runs the existing production harness for each target.
5. Require one native seed, remove native compiler executables afterward, then
   actual generatedG1→G2→G3. Each generation must independently admit with
   official Lean4.35.0 checker eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
   strict original/transformed IR, exact sources and ten positive/negative cases.
   Compare canonical admissions/IR/observations plus raw compiler source bytes;
   operational manifest timestamps/events need not be equal.
6. Preserve all terminal failures with exact commits, logs, timings and maxRSS.
   Diagnose actual generated costs/stack traces as source/runtime classes and
   fix them with focused regression evidence before repeating expensive chains.
   G1/corpus/tools240s/checker120s, semantic fuel and all memory/stack policies
   remain unchanged. Do not set Python recursion/digit-limit globals or inflate
   PHP memory. Correctness1800s cannot qualify original performance240s.
7. Obtain latest-source full37/37 seven-backend/both-grammar/application CI,
   plus separately scoped clean G1 reproduction. Preserve older DirectJS/Wasm
   source133e5892/run40062120079 and clean40064496804, Rust/TS refs and history.
   Reconcile AI_WORK_STATE.md/roadmap/receipts and draft PR metadata.
