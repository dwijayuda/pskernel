# Executable Rust and TypeScript self-host continuation

Continue PSC1 PR #172 autonomously. Use connected GitHub tools and Linux GitHub
Actions only; no local repository/files/builds/tests. Preserve all Git history,
fetch current HEAD before mutations, use expected-HEAD non-force updates.
Do not merge or publish packages. Do not stop at planning.

## Read and establish exact state

1. Fetch PR #172 and latest `fix/psc1-closure-normalization-20261021` HEAD,
   then read `psc1/AI_WORK_STATE.md`,
   `psc1/docs/PSC1_DEVELOPMENT_ROADMAP.md`,
   `psc1/docs/PSC1_RUST_TS_SELFHOST_ARCHITECTURE.md`, and
   `psc1/docs/PSC1_RUST_TS_SELFHOST_QUALIFICATION_2026-10-23.json`.
   Read any applicable AGENTS instructions through GitHub.
2. The last full qualified compiler HEAD is
   `ea10eff9b3de063941c6029bb6c821f9cc10cc3f`, source profile
   `76bf4120de83bf776a4e790672f7b2d0198e25db`, tested merge
   `4e5f4d2c8c90178aa7cf301717004cfc6182596f`.
   Run 39880807914 completed successfully, all selected jobs, all 47 full steps,
   readiness 37/37; benchmark was dependency-skipped. Do not rerun without cause.
3. Manual matrix 39880803794: Rust job 120177436334 qualifies actual G1/all ten
   frozen cases, then G2 times out at 240031 ms, G3 not run. Artifact 12470618024
   has exact executable/source/admission/IR identities and request bytes.
   TS job 120177435975 admits the complete bootstrap candidate, then strict
   checking times out at 240006 ms; no executing G1. Artifact 12470288964.
   These artifacts expire 2027-01-21; the normal full artifact expires 2026-11-06.

## Execute the measured Rust correction first

4. Fetch isolated branch `fix/psc1-rust-owned-string-moves-20261023`.
   Last recorded request HEAD `f037377574124cf7a374d627f0c57e4a855e09e5`,
   source correction `9052b59fe7bafc000a2fa8ec24f0ead266276682`,
   run 39886083977 was in progress at this recording. Query its actual terminal
   state and artifacts before changing anything.
5. Exact generated Rust diagnostic 39882471895 at
   `c380c7e899fe7d156443c73b43208ab0ecb6936e` identifies repeated
   `String::clone` from `psJsonStringToChars` in full G2 request decoding.
   The isolated prototype modifies BackendRust/Expr.lean and Tail.lean:
   exact monomorphic immutable forwarding wrappers borrow String arguments;
   already-owned computed expressions move with required grouping; unchanged,
   initialized, unshadowed String loop parameters move only after changing
   arguments are fully evaluated.
6. Review `psc1/test/RustInvariantTailTests.lean` and
   `psc1/scripts/rust-invariant-tail-runtime-tests.mjs`. They retain the old
   emitters, compare generated Rust execution, and cover Unicode, duplicates,
   shadowing, fuel refusal, argument order and reserved identifiers. Prior run
   39885413596 passes those guards and both complete grammar audits but failed
   the actual generated handler program due to lost struct-expression grouping.
   The latest correction restores parentheses without reintroducing copies.
7. Fix actual failures as general emitter/runtime classes, add meaningful
   regressions and rerun the same frozen full compiler pipeline. Do not infer
   whole-compiler speed from the mechanism benchmark. Do not increase stack,
   heap, fuel or deadlines. If native recursion/destruction fails, diagnose it
   on the exact artifact before designing an ABI-preserving runtime correction.

## Diagnose and fix TypeScript using its actual checker

8. Fetch diagnostic branch `diagnostic/psc1-selfhost-profile-20261023`.
   Latest diagnostic recorded:
   `23626b21cada65ea6f78ac6db8dd0e3ffa6dff29`,
   run 39886224622. It inspects actual checker descendants using the exact
   6462076-byte generic compiler module from artifact 12470288964 and locked
   TypeScript 7.0.2. Query terminal logs and diagnosis artifacts.
   Earlier run 39885112247 sampled only the Node launcher; it does not identify
   a checker hotspot.
9. Fix the measured source/checker issue through the existing TS emitter or
   shared checked compiler. Preserve strict checking, noEmitOnError, tool
   identities and existing 264 output/runtime comparisons and all-input
   visitor equality. No noCheck, any/cast bypasses or handwritten compiler.
   Largest IR functions are parameterized elaborator workers; global constant
   outlining was not justified. An unreachable-function estimate is not a
   preservation argument or implemented optimization.
10. Build and execute genuine TS G1, all five positive/five negative frozen
    cases, then G2/G3 and exact fixed points independently of Rust.

## Run the existing Linux qualification, safely

11. Manual workflow:
    `.github/workflows/psc1-rust-ts-selfhost-qualification.yml`.
    It runs `lake build psc1_target_service_seed psc1_independent_checker`
    and the existing native normalization/host/process-bound regressions,
    audits both complete source grammars, then executes from `psc1/`:
    `node scripts/generated-target-qualification.mjs rust --self-host`
    and independently
    `node scripts/generated-target-qualification.mjs ts --self-host`.
    Read the workflow for its complete registered test list; execute via
    Linux Actions, never on the local machine.
12. Use workflow_dispatch when a connected dispatch mutation is available.
    Otherwise use the existing committed-request fallback:
    first commit source changes on the exact current parent, then create
    **a separate request-only commit** changing only
    `.github/qualification-requests/psc1-rust-ts-selfhost.json`.
    Retain schema `psc1-rust-ts-selfhost-request/1`, action
    `qualify-independent-G1-G2-G3`, exact active branch, targets
    `["rust","ts"]`, resourcePolicy `unchanged`, a fresh unique id and
    parentCommit equal to the fetched current source commit.
    The request commit's sole parent, event.before and parentCommit must match;
    event.after must be the request commit. Use expected-HEAD lease and no force.
    Source/docs pushes alone do not run G2/G3.
13. The isolated ownership workflow uses the same qualification implementation,
    Rust-only, branch-bound request path
    `.github/qualification-requests/psc1-rust-owned-moves.json`.
    Apply the same source-commit / separate request-only-commit rule.
    It additionally runs `psc1_rust_invariant_tail_tests` and
    `node scripts/rust-invariant-tail-runtime-tests.mjs`.
    Keep prototype results explicitly separate until integrated.
14. Query exact workflow/job/step terminal states; preserve incremental
    qualification.json, tool stdout/stderr, source inventory, generated source,
    reviewed lock, request/candidate bytes, artifact hashes, timings and RSS.
    A failed/timeout attempt is evidence of a blocker, never qualification.

## Promotion and completion

15. Integrate only reviewed, validated prototype changes onto the latest active
    branch with a history-preserving expected-HEAD commit; no PR merge. Reconcile
    any concurrent source changes explicitly. Run fresh normal source-selected
    and full Linux seven-backend qualification after compiler/backend changes.
    Historical normal success does not qualify new source.
16. Each target must independently execute G1, G2 and G3, compile the identical
    registered compiler closure, independently admit exact canonical graphs with
    official Lean 4.35.0 commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
    strictly validate original and transformed IR, match source/admission/IR
    fixed-point digests, and pass identical ten-case observations at each stage.
    Native compiler binaries must be unavailable after the single seed.
17. Keep all seven Practical Core mappings, real applications, explicit
    unsupported ABI refusals, strictness/evaluation order and negative tests.
    Existing 15-minute job, 240000 ms child, 32 MiB per-stream and 128 MiB
    request/response limits remain; 245000 ms supervisor guard is cleanup only.
    Do not suppress diagnostics to hide errors or weaken checking.
18. Update the machine receipt, AI_WORK_STATE.md and authoritative roadmap with
    exact commits/run IDs/artifact digests/expiry and completed versus blocked
    work. Preserve historical text/receipts. DirectJS remains G1 reference;
    retain its G2 heap defect without returning to DirectJS-first tuning.
    Record actual generated compiler build/runtime/RSS/source size comparison
    for Rust and TS only once both execute.

Continue implementation through qualification. If the session must end, leave
a verified source checkpoint, exact terminal evidence and updated executable
continuation instructions. Do not claim full self-hosting, production release,
or npm publication before the required evidence and authorization.
