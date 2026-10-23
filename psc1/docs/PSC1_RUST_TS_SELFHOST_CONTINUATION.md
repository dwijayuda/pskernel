# Executable continuation: PSC1 TypeScript self-hosting

Continue PR172 autonomously with connected GitHub/Linux Actions only.
No local files/checkout/build/tests. Fetch exact HEAD, expected-HEAD non-force
updates, preserve history. No merge/npm publication.

1. Read main fix/psc1-closure-normalization-20261021 HEAD, AI_WORK_STATE,
   roadmap and PSC1_SELFHOST_PROFILES_QUALIFICATION_2026-10-23.json. Its
   sourceReceiptGitBlob binds the full canonical receipt. Integrated5ce2fc74/
   mergea61eecf4/normal39909569028 qualifies37/37 frozen criteria and all seven
   backends. Documentation gates do not qualify isolated later source.

2. Current implementation branch is perf/psc1-erasure-applied-workers-20261023.
   Encoder compiler commitc3fe670ffbd8a56be552910bbb3a0a20170b2b11; proof repair
   5d819f69ba1ccda0689e7d354fdcab9295807c0d. Actual source parent
   453659433789ae3c6322f61b956e784891776c71, correctness request
   66f1e752cfbdc491d9b2974c849825e8a4193227, run39973570792/job120482257189
   is TERMINAL FAILED: G1 independently admitted/built and10 cases pass;
   G2 timeout1800231ms/3064892KiB, no candidate/G3/fixed point. Audit39978659027
   verifies all source/request/manifest and actual encoder/erasure/token/cache
   mechanisms. Artifact12512171887 digestfd7e28e0e06134029accdd8774a33dc1cd314de67ddad10bf2394b269623ef77,
   expiry2027-01-21T14:53:58Z. Do not repeat unchanged or re-audit this artifact.

3. Focused39972917410/job120480001006 SUCCESS proves two applied IR encoder
   workers equal exact retained originals for all fuel/types/expressions, plus
   public wrappers/type/parameter/binding helpers. Only propext/Quot.sound.
   Zero/leaf tuple tests, all prior proof/runtime/negative gates, and85-module
   Lean/PS source audits pass. Failed proof-script39972417408 is retained;
   its repair changes no compiler source. Keep default4096, tuple bytes,
   exhausted-fuel/error order and independent strict original/transformed IR.

4. Why this change: actual late replay39967678751/job120461727047 runs pinned
   G2 requestae97450bad8f2130d344b0ee98a63766e82849d2b7f897a2b700e7630bdeeb1e
   against G1 manifestf594ea3fee41844add79b774b63df7dd80b8eead15fe265e830768173aa1329d.
   It times out1750180ms/RSS2946364KiB, no response/adoption/admission.
   Final30s ticks26481/27754 WeakCollectionSet (95.4%), primarily type encoder23006
   and expression encoder3397 beneath WeakMapSet. StringEqual absent from
   reported late hot frames. Artifact12508763587 digest
   595db22c3142a82ec0054cc3d981eb5990b622b7c14dfbc7d181b785f0400090,
   expires2027-01-21T14:12:39Z. Do not infer whole-run speed from samples.

5. Previous actual erasure sourceba0d5f2916074b6331441b050a38fd0f12347604/
   requestd2bc51fcce626297db491890551d2902c710a844/run39964278626/job120449945559
   is terminal: G1 admitted/built/ten cases; G2 timeout1800138ms/3002380KiB;
   noG3/fixedpoint. Artifact12508002820 digest
   345dcf59f4b5707a0c9ee9c5301d0e83b3e8aaa86c88b1552c1511b0838a4bb3,
   audit39969728664 verifies identities/actual runtime and worker IR.
   Short9a0a9e6f/run39965349252 timeout240170ms/RSS2277344KiB.
   Earlier token/cursor/lookup/Map attempts remain in the canonical receipt.
   Do not refork obsoletea10c0162 or rerun old failed sources.

6. Preserve lazy2-view tokens/alias/shadow/collision guards, source equality/fuel,
   non-admitting size, cached valid extraction and legacy cold/invalid fallback;
   focused39959279408 checks16000 equality/95576 extraction cases.
   Preserve eight applied erasure workers/all-input proofs39963603961, public
   signatures/default4096/whnf/first duplicates and100001-entry regressions.
   Legitimate partial-application variants and generic/public ABI fallback stay.

7. Qualified Rust reference fix/psc1-rust-owned-string-moves-20261023 is untouched
   at83e18fe183498f7d8b0fc3e3faa5bdacc41cb23d. Source
   5e0b548e6cb3606ee0d3c129e0a829d830e407e4, request
   7d8865a08427a28432e427592dfc4263718c9a2f/run39908529181/job120265913272
   qualifies actual G1/G2/G3 and exact fixed point under1800s.
   G2/G3 692788/660042ms/RSS668192/668184KiB; executable
   d55a8435a157f021e5a7c073037303429b9787729c963af3842a04b9fb009017.
  240s and independent clean-build repeatability remain unqualified. Do not edit
   this branch or discard its artifact12482993158/receipts.

8. Current continuation is ONE progressive diagnostic39978891505/job120500641283,
   commitbac05317679a9e756d093d76dfc7a1d3465fc53a on
   diagnostic/psc1-selfhost-profile-20261023. It replays current G2 request
   e90eafca56433f509bb9e77d1e26e034f1de34accadac7bfb2d913893a7e8998 against
   unchanged G1 manifest294fa864b22b32138696ed9dfd54a6e2ae94799ce381628b256dcc0d2d7c3cec,
   sourceedaa13a2a9e3081892175e79d353f6b12af2f4bfb03da703023062cc603ce62d,
   closure816b37f9e38262105edb4e8930da0cda34e53e9ba3b0338841fe99b5a6cd5a82.
   Fetch its current run and artifact list. It publishes phase240/600/1200/1750
   artifacts from the same bounded request; do not launch a duplicate.
   Phase240 artifact12512911643, digest411a6ef3d22907b28b0f6784c94709b0756922f97329a4758400374217905715,
   read39979697224, shows erasure/environment/generator work, native Node46.1%
   and WeakCollectionSet228/27522 (0.8%); this is early, not the late diagnosis.
   For each new available phase artifact, update ONLY
   .github/diagnostics/psc1-profile-read.json on the diagnostic branch, schema
   psc1-profile-read-request/1, freshid, phase, runId39978891505,
   sourceCommitbac05317679a9e756d093d76dfc7a1d3465fc53a,
   artifactId/artifactDigest/artifactExpiresAt from actual API metadata.
   Existing workflow verifies artifact provenance, request/manifest/source hashes,
   source files and phase liveness, then prints PSC1_PROGRESSIVE_PROFILE_READ.
   No compiler re-execution, admission or adoption. Read terminal logs if a phase
   fails; retain original raw profile. The exact source census39977097772 finds
  132 syntactic candidates including false positives, not132 defects. Shape
   inspection39975765156 matches admitted G1 and witnesses delayed saturated
   encoder callbacks. No zero-lambda rule for legitimate callbacks.
   Canonical records14 completed attempts. Derive compact evidence from its
   exact Git blob. Frozen initial profile declaration stays historical.

9. If correctness passes, run the unchanged performance240s profile separately,
   and then coherent integration/full seven-backend/application qualification.
   The current source fails, so diagnose the remaining progressive phases, fix the measured class with
   all-input/regression evidence, source-gate it, then issue one fresh request.
   Do not optimize generic generators from synthetic results: native-invoke and
   manual-iterator corpus experiments were marginal/unadopted; self-tail loops
   already exist. Do not introduce unproved native String equality.

10. Qualification request is a request-only commit after coherent source:
    .github/qualification-requests/psc1-rust-ts-selfhost-correctness.json
    schema psc1-rust-ts-selfhost-request/2, freshid, targets["ts"],
    action qualify-independent-G1-G2-G3, profile correctness-1800s,
    g2g3TimeoutMs1800000/g1TimeoutMs240000,
    resourcePolicy only-G2-G3-wall-clock-extended;all-other-policies-unchanged,
    parentCommit exactsourceHEAD; event.before/parent/requestparent must agree.
    Short .github/qualification-requests/psc1-ts-generator-types.json schema/1,
    resourcePolicy unchanged. Preserve branch guards.

11. Existing workflow Linux commands from psc1/:
    lake build psc1_ir_encoder_worker_normalization_tests psc1_erasure_worker_normalization_tests psc1_target_service_seed psc1_independent_checker
    .lake/build/bin/psc1_ir_encoder_worker_normalization_tests
    node scripts/generated-target-source-audit.mjs ts
    node scripts/generated-target-qualification.mjs ts --self-host correctness-1800s
    node scripts/generated-target-qualification.mjs ts --self-host performance-240s
    Use existing workflows to retain every common proof/checker/negative gate.
    Official Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc; strict IR,
    semantic fuel, heap/stack and ABI refusals unchanged. G1/corpus/build240s,
    checker120s; only actual G2/G3 correct1800s; longjob120min/step110min,
    short15min; cleanup5s, streams32MiB/wire128MiB. One native seed then remove
    native compiler executables, keep independent checker. No native substitute.

12. Preserve all seven backend mappings, Rust ownership/private safe Drop,
    TS typed/structured generator guards and shared architecture. After target
    qualification, integrate only coherent sources onto fresh main with full CI.
    Update AI_WORK_STATE/roadmap/canonical+derived receipt together. DirectJS
    G1/heap defect and independent ExpressionV2 remain separate. No merge/publish.
