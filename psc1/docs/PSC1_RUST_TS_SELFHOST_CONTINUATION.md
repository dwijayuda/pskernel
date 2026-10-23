# Executable continuation: current PSC1 TypeScript self-hosting

Continue PR172 autonomously using connected GitHub and Linux Actions only.
No local checkout/files/builds/tests. Fresh HEAD, expected-HEAD non-force updates,
preserved history. No merge or npm publication.

1. Read main fix/psc1-closure-normalization-20261021 HEAD, AI_WORK_STATE, roadmap,
   profile contract and compact PSC1_SELFHOST_PROFILES_QUALIFICATION_2026-10-23.json.
   Its sourceReceiptGitBlob binds the complete canonical receipt. Main code5ce2fc74
   / mergea61eecf4 / normal39909569028 qualifies37/37 criteria and all seven targets.
   Do not infer new source qualification from this older integrated baseline.
2. Current implementation branch is perf/psc1-erasure-applied-workers-20261023.
   Code/proof sourcef9675e05b063df1fb949f97188724d11134b7b26, long source parent
   ba0d5f2916074b6331441b050a38fd0f12347604, request
   d2bc51fcce626297db491890551d2902c710a844, run39964278626/job120449945559.
   Fetch its terminal state before doing anything expensive; at receipt write it
   was running actual generated requests. Do not start an unchanged duplicate.
   Short request9a0a9e6f5b6b8c6546c1833b243115f97888c561 (parent09f41833d1c2d5c62de8bc55a25e58076055cc06)
   / run39965349252/job120453647159 passes G1/ten cases, G2 timeout240170ms,
   RSS2277344KiB. No G3/fixed point or240s badge.
3. Preserve Rust branch fix/psc1-rust-owned-string-moves-20261023 untouched
   at83e18fe183498f7d8b0fc3e3faa5bdacc41cb23d. Qualified source
   5e0b548e6cb3606ee0d3c129e0a829d830e407e4, request
   7d8865a08427a28432e427592dfc4263718c9a2f, run39908529181/job120265913272
   genuinely qualifies G1/G2/G3 and exact fixed point under1800s. G2/G3
   692788/660042ms, RSS668192/668184KiB, executable
   d55a8435a157f021e5a7c073037303429b9787729c963af3842a04b9fb009017.
   Original240s and independent clean-build qualification remain incomplete.
4. Keep the proved source normalization: eight applied workers in
   Ps.Erasure.Basic/Definition/Expr, original public types, default4096 and whnf.
   Native39963603961 checks all-input equalities against retained old definitions,
   zero/forall fuel, first duplicates and100001-entry hit/miss. It also runs all
   prior proof/negative/runtime gates and both85-module source audits.
   Auditor39966960519 confirms source/saturated workers are data-returning with
   zero body lambdas. Separate function-valued generated variants are legitimate
   partial applications; inspect actual call paths rather than banning them.
5. Preserve TS token/cursor changes in BackendTs.Module/Expr: lazy two-view symbol
   identities, guarded invariant aliases, cold size counting without admission,
   existing valid-boundary slice extraction and exact legacy invalid/cold fallback.
   Native39959279408 checks16000 equality/95576 extraction cases, max2 views,
   independent UTF8 size and extraction-only module runtime. Never replace source
   String equality with native equality without official all-input equivalence.
   No cache, heap/stack, fuel, stream or wire bound was expanded.
6. Prior trials are terminal and retained:
   tokens source d520a49e/request27f2a216/run39952593596: G2 timeout1800195ms,
   RSS3050788KiB; shorte6df0e0d/run39952866650 timeout240202ms/RSS2281004.
   Cursor sourceedc3e17b/request3dd9152a/run39959835622 timeout1800199ms,
   RSS2989224; short55fcd9d9/run39960115125 timeout240168ms/RSS2370648.
   Both G1/ten cases pass; no admitted G2/G3/fixed point. Do not refork olda10c0162.
   Map sourceaae4aac4 remains an unselected historical experiment.
7. Saved profiles are last30s of220s, not the final1800s request:
   39918874112 StringEqual17099/27684;39961304634 StringEqual8/26866 and
   WeakCollectionSet8025/26866, mainly psErasureTypeValuedWithFuel;39966590664
   StringEqual22/27480 and weak-set114/27480 after proved normalization.
   Different sources may reach different phases; no whole-compiler speedup follows.
   One up-to1750s pinned actual G2 diagnostic replay is requested at diagnostic
   sourced5ca074954b30fd51a0e696734128b0e03a023e8 on
   diagnostic/psc1-selfhost-profile-20261023, to measure the late window. Read that
   run before proposing another optimization. It uses exact request
   ae97450bad8f2130d344b0ee98a63766e82849d2b7f897a2b700e7630bdeeb1e and the
   existing correctness policy. Diagnostic copies/results are never adopted.
8. For each new terminal qualification artifact, audit once using the existing
   .github/diagnostics/psc1-selfhost-receipts.mjs/workflow on the diagnostic branch.
   Bind source parent, request SHA, run/job, artifact ID/digest/expiry. Preserve
   inventory/request/manifest and all source/admission/original/target IR/corpus
   assertions. Flags inspectUtf8TokenWorker, inspectCursorCacheHelpers and
   inspectErasureWorkers record actual mechanism. Audits never supply missing
   compiler execution/admission. Already completed audits39953924361/39957038006/
   39961219637/39964784124 cover the token/cursor trials. Erasure inspection
   initially over-selected function-valued auxiliary variants (39966561743),
   repaired39966960519; no verification/controller requirement changed.
9. If current long run passes, record actual G2/G3 time/RSS and exact fixed points,
   then optimize toward original240s. If it fails, use the late-window evidence
   and actual IR/caller paths to fix the remaining class before another request.
   Small native-invoke and iterator prototypes remain unadopted;20 real corpus
   replays gave13704/13788ms and13016/13508ms, not demonstrated G2 gains.
10. Source-first then request-only commits are required. Long request path
    .github/qualification-requests/psc1-rust-ts-selfhost-correctness.json:
    schema psc1-rust-ts-selfhost-request/2; action qualify-independent-G1-G2-G3;
    exact current branch/targets; profile correctness-1800s; g2g3TimeoutMs1800000;
    g1TimeoutMs240000; resourcePolicy
    only-G2-G3-wall-clock-extended;all-other-policies-unchanged;
    fresh id and parentCommit equal source HEAD. Request commit changes only that
    file; event.before/parent/source and event.after/request SHA must match.
    Short schema/1 path .github/qualification-requests/psc1-ts-generator-types.json
    keeps resourcePolicy unchanged and original240s. Branch guards must match.
11. Existing Linux commands from psc1/:
    lake build psc1_erasure_worker_normalization_tests psc1_ts_utf8_view_tests
    .lake/build/bin/psc1_erasure_worker_normalization_tests
    .lake/build/bin/psc1_ts_utf8_view_tests
    node scripts/ts-utf8-view-runtime-tests.mjs
    node scripts/generated-target-source-audit.mjs ts
    node scripts/generated-target-qualification.mjs ts --self-host correctness-1800s
    node scripts/generated-target-qualification.mjs ts --self-host performance-240s
    Use the existing workflows so all common proof/checker/negative gates run too.
    G1/corpus/build240000ms, checker120000ms; only actual G2/G3 correct1800000ms;
    long job120min/step110min, short15min, cleanup5s, streams32MiB/wire128MiB.
    Preserve official Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
    strict original/transformed IR, semantic fuel, heap/stack, identities and ABI
    refusals. One native seed then native compiler executables removed, independent
    checker retained; no native/handwritten semantic substitute.
12. Promote coherent verified source only onto fresh main, preserving TS typed/
    generic guards and Rust ownership/private safe Drop, then require fresh full
    seven-backend/application qualification. Current isolated G1 or fixed point
    is not that integration gate. Update AI_WORK_STATE, roadmap and canonical
    receipt together; derive the compact projection from its exact Git blob.
    Frozen release contract and passive historical evidence remain unchanged.
    DirectJS G1/heap defect and independent ExpressionV2 research stay separate.
