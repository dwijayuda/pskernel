# Executable Rust and TypeScript continuation

Continue PSC1 PR #172 autonomously through implementation and qualification.
Use connected GitHub tools and Linux GitHub Actions only; no local checkout,
files, builds or tests. Fetch latest remote HEAD before expected-HEAD non-force
commits. Preserve all history. Do not merge PRs or publish npm packages.

## Establish the verified boundary

1. Fetch PR #172 and `fix/psc1-closure-normalization-20261021` HEAD. Read
   `psc1/AI_WORK_STATE.md`, `psc1/docs/PSC1_DEVELOPMENT_ROADMAP.md`,
   `psc1/docs/PSC1_RUST_TS_SELFHOST_ARCHITECTURE.md` and
   `psc1/docs/PSC1_RUST_TS_SELFHOST_QUALIFICATION_2026-10-23.json`.
   Read applicable AGENTS instructions through GitHub.
2. Last fully qualified source:
   `d0bef34de7d5d3c495f2a4a73af7eccd892d0d74`; tested merge
   `6cc6c55b4785eebf70f27331610f9e949a3a84e5`.
   Run 39887884270 completes successfully: all selected jobs, all 47 full steps,
   readiness 37/37. Benchmark was dependency-skipped. Preserve all seven targets,
   both grammars, real applications, kernel/IR/negative checks and unpublished
   package evidence. The normal full artifact 12474609129 expires 2026-11-06.
3. Both Rust and TypeScript G1 genuinely execute the same five positive/five
   negative frozen cases with separate official admission. Neither G2/G3 nor
   fixed point has passed at the last terminal checkpoint. Main's integrated
   TS annotation source matches every one of the 489 Lean blobs in the actual
   G1-tested tree a0a0a92f39deb7ff3c9336f41dc6ebcb681ae1d1.
   Do not infer full self-hosting from G1 or a diagnostic job's green status.

## Verify the current shared-cursor correction first

4. Fetch both isolated branch HEADs and query the latest exact jobs/artifacts:
   - Rust `fix/psc1-rust-owned-string-moves-20261023`, source
     `623384b5212576229a6caae474edcdb4e71e9c76`, request
     `62c8937e72ece94e774bcee33f691edd1c293260`,
     run 39893147337/job 120217324058.
   - TS `fix/psc1-ts-generator-result-types-20261023`, source
     `ee45ca9035698ca12f0c6814c91b615db01242ff`, request
     `541419592bc2a90ea2b79737ba7e64ba365c4108`,
     run 39893184640/job 120217442436.
   Both are terminal failures after fully passing the cursor proof, both complete
   grammar audits and all ten G1 cases. Rust G2 fails with stack overflow at
   14116 ms; TS G2 times out at 240086 ms. No G2 graph is admitted. Refresh
   exact current state and inspect new diagnosis before changing code.
5. Both branches contain identical shared files:
   `packages/syntax/src/Ps/Syntax/Cursor.lean` and
   `test/CursorNormalizationTests.lean` under `psc1/`.
   The latter has an explicit lakefile executable root
   `psc1_cursor_normalization_tests`.
   It retains the original bounded character converter, proves equality for
   every fuel/source/raw byte offset, checks UTF8 offsets/fuels and executes
   100000 source characters. The replacement accumulates/reverses, preserving
   the exact original traversal bound and result.
6. This directly addresses exact Rust diagnosis 39891954467/job 120213547067 at
   `5246c05af5236df2a41a4f98c2572c56dbab6ecf`: repeated native
   `psLexStringToListFromWithFuel` worker frames. Do not substitute a stack
   increase or unrelated Foundation-list rewrite for the observed failure.
   The next post-cursor Rust crash diagnosis is dispatched at
   `f07845ad5cd300d1e5c61fa71949741263286cdf` on the diagnostic branch.
   It replays current artifact 12475414282 (digest
   07f4b512e3d381a4ceb376d7f9bf91aab640538e3f9315326d7f8b1f45607c4e),
   exact request ae10e4daf7ed47e76ff30caca7c26a961a4746e3458336a52b4a598e16754681
   and manifest 9c6e5a7b5e230288baa48ffc3265113f54ddd23743a73688d0d2b774df28d130.
   Query its terminal stack, then repair the actual remaining failure class.

## Preserve and finish the Rust engineering work

7. Last terminal Rust candidate:
   source `981f9dff23ea8c04da730eeefc9fb42c4a2012f6`, request
   `f5f9ed657fa57945070d0e0096c72009a4ac8a10`,
   run 39890802847/job 120209837332. It passes both complete grammar audits,
   actual G1/all ten cases, retained-old/current ownership execution, shared-tail
   and destruction-order comparisons, and 500000-node private destruction.
   G2 then fails with stack overflow at 186541 ms; no response is admitted.
   Artifact 12475186302, digest
   32e79fce138d4e0b45ca904cddd1529d757b6982698318aa0e3ec3c0f027371a.
8. Expr/Tail ownership corrections borrow exact monomorphic ordered intrinsic
   wrappers and move only checked, unique unshadowed String locals after all
   changing arguments are evaluated. Last-use let transfer reuses existing
   scope-aware capture analysis; live originals, captures, duplicate roots,
   shadows and exhausted analysis refuse. Required grouping is retained.
9. The earlier 2-second crash is reproduced by 39889679469 as recursive
   `Rc::drop_slow`. Private regular inductives with a nullary sentinel and one
   final recursive field now drain uniquely owned tails iteratively in safe
   Rust. Shared tails and original drop order are preserved; public enum fields
   and pattern ABI are unchanged. Other shapes retain their existing behavior.
   Generated match bindings borrow fields and clone owned payloads.
   Read `PSC1_RUST_LINEAR_DROP_PROTOTYPE.md`; no unsafe/leaks/raised limits.
10. After the cursor fix, execute real full compiler workloads through G2/G3.
    If another stack/resource failure appears, capture its actual call path
    before choosing source normalization or backend engineering. Keep correctness
    and all public/unsupported ABI boundaries; never retreat to DirectJS-first.

## Finish TypeScript from measured runtime evidence

11. Last terminal structured-generator source:
    `07fcc6037330166067d422d15a6630b1f7f626ae`, request
    `0ab4874a22edbde7025e5f29004f3c7ee2bdd4a1`,
    run 39889151346/job 120204444859. Both grammar audits, actual G1/all ten
    cases and two all-input legacy equality proofs pass; G2 times out at
    240086 ms. Artifact 12474077616, digest
    c3255a3c4743dae6a9bd57cb49856e5c64951e0f6f40912e41e0fa43e9e66d5d.
12. Main already integrates checked result annotations that resolve the native
    strict TypeScript checker contextual-inference stall. The isolated follow-up
    flattens structured generator statements through the existing driver,
    preserving ordinary typed/fuel preflight, evaluation order and conservative
    alias/shadow refusal. Legacy pure-tail output is proved unchanged.
13. Exact late runtime profile 39890014989/job 120207258375 at
    `a6fd57c72041ad54afc14f105b3c9000ff8da88a` replays 220 seconds and
    analyzes the final 30-second tick window. It reaches expression instantiation,
    metavariable/inference work, string/name/environment lookup and generator
    dispatch. The earlier first-30-second profile is mostly JSON parsing.
    Use the late evidence to select dependency-coherent optimizations.
    No noCheck, strictness relaxation, any/cast bypass, extra heap or timeout.
14. Verify whether the shared cursor change improves the full TS workload,
    then complete actual independent G2/G3 and fixed points. Avoid speculative
    constant outlining, broad redesign or cache/resource expansion. Both targets
    must continue using identical shared compiler/frontend source.

## Execute only the existing Linux pipelines

15. The isolated workflows register/run the cursor proof before both source
    audits and generation. From `psc1/`, their essential commands are:
    ```bash
    set -euo pipefail
    lake build psc1_cursor_normalization_tests psc1_target_service_seed psc1_independent_checker psc1_js_service_tests psc1_source_census_probe psc1_ts_service_normalization_tests
    .lake/build/bin/psc1_cursor_normalization_tests
    .lake/build/bin/psc1_ts_service_normalization_tests
    .lake/build/bin/psc1_js_service_tests
    node scripts/generated-target-source-audit.mjs rust
    node scripts/generated-target-qualification.mjs rust --self-host
    ```
    Run the same target commands independently for `ts`.
    The Rust workflow additionally builds/runs
    `psc1_rust_invariant_tail_tests` and
    `node scripts/rust-invariant-tail-runtime-tests.mjs`.
    Read each complete workflow for host/manifest/process-bound negative tests,
    exact tools and artifact retention. Execute through Actions, never locally.
16. Main manual matrix:
    `.github/workflows/psc1-rust-ts-selfhost-qualification.yml`.
    Use connected workflow_dispatch when available. Otherwise commit source
    first, then make a **separate request-only commit** changing only
    `.github/qualification-requests/psc1-rust-ts-selfhost.json`:
    schema `psc1-rust-ts-selfhost-request/1`, action
    `qualify-independent-G1-G2-G3`, a fresh id, exact active branch,
    targets `["rust","ts"]`, resourcePolicy `unchanged`, and parentCommit
    equal to the freshly fetched current source HEAD.
    Request commit parent, event.before and parentCommit must match;
    event.after must equal the request commit. Use expected-HEAD non-force updates.
17. Isolated requests use the same rules and branch-specific workflow:
    Rust path `.github/qualification-requests/psc1-rust-owned-moves.json`
    with targets `["rust"]`; TS path
    `.github/qualification-requests/psc1-ts-generator-types.json`
    with targets `["ts"]`. Source/docs pushes alone do not run G2/G3.
    Preserve all incremental receipts, sources, graph/IR, request/candidate
    bytes, exact tools/locks, timings/RSS and failed tool stdout/stderr.

## Promotion and final acceptance

18. Each target must actually generate, independently admit, build and execute
    G1/G2/G3, with all ten unchanged cases at every stage. Require exact closure,
    source, canonical admission, original/transformed IR and observation fixed
    points. Native compiler binaries stay unavailable after the sole seed.
19. Separately record repeated clean target build-product identities. The
    controller currently asserts source/graph/IR/observations; it does not
    establish native executable bit equality. Account for Cargo build-path
    identity reproducibly without skipping fresh generation or weakening checks.
    Preserve readable large compiler output, TS declarations/maps and a reviewed
    exact Cargo lock; publish nothing without authorization.
20. Promote only coherent validated changes onto the latest PR #172 branch with
    history-preserving expected-HEAD commits. Reconcile concurrent edits.
    Run fresh normal source-selected and full seven-backend qualification on
    the integrated source; historical success does not qualify a new source.
    Keep the 37-criterion finite contract, real applications and DirectJS G1.
21. Official Lean 4.35.0 commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
    strict original/transformed IR, semantic/ABI refusals and all negatives remain.
    Existing 15-minute jobs, 240000 ms child process groups, 32 MiB per stream
    and 128 MiB requests/responses remain. The 245000 ms guard is cleanup only.
    Preserve existing fuel/heap/stack policies; no verification shortcuts.
22. Reconcile the machine receipt, authoritative roadmap and AI_WORK_STATE.md
    with exact terminal commits/runs/artifact hashes/expiry and explicit completed,
    tested, qualified, blocked and deferred boundaries. Preserve old evidence.
    Do not let Expression V2 kernel research block this compiler work.
    DirectJS-specific G2 optimization remains deprioritized.

Continue through actual implementation and qualification. If completion is not
possible in the session, preserve a verified source checkpoint and update this
executable prompt with the exact remaining work. Do not claim final self-hosting,
binary reproducibility, merge, publication or general backend correctness early.
