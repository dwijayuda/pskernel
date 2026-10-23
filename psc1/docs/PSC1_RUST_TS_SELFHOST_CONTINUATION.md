# Executable PSC1 Rust and TypeScript continuation

Continue PR #172 from the latest remote HEAD, through actual implementation and
Linux qualification. Use connected GitHub tools and Linux Actions only: no local
checkout, files, builds or tests. Preserve history with expected-HEAD non-force
updates. No merge or npm publication is authorized.

1. Fetch PR172 and active branch fix/psc1-closure-normalization-20261021 HEAD.
   Read applicable AGENTS instructions, AI_WORK_STATE.md, the development roadmap,
   PSC1_SELFHOST_QUALIFICATION_PROFILES.md and the canonical
   PSC1_RUST_TS_SELFHOST_QUALIFICATION_2026-10-23.json.
   Integrated code5ce2fc74b9f01682832ddc10ec9ef27f26458564 / tested merge
   a61eecf46ded19eedcdefcb320aa33118cd8f2ad passes run39909569028:
   all selected jobs,47 full steps,37/37 finite criteria. Preserve the frozen
   14-family contract, both grammars, seven targets and four real application
   categories. Full artifact12483409585 expires2026-11-06T06:45:00Z.
2. Preserve the qualified isolated Rust reference:
   branch fix/psc1-rust-owned-string-moves-20261023, source
   5e0b548e6cb3606ee0d3c129e0a829d830e407e4, request
   7d8865a08427a28432e427592dfc4263718c9a2f, run39908529181/job120265913272.
   Actual G1/G2/G3, independent admission and exact fixed point pass with
   correctness-1800s. G2/G3 are692788/660042ms, RSS668192/668184KiB.
   All three generated executable hashes are
   d55a8435a157f021e5a7c073037303429b9787729c963af3842a04b9fb009017.
   Same-run executable equality is observed; independent clean-build repeatability
   and the240s performance target remain unqualified.
3. Re-query the latest bounded two-view-map trial first: branch
   perf/psc1-bridge-lookup-workers-20261023, source
   aae4aac442154bb0c95fedb35f19fdb1552cc271, request
   9f39ab515a3a0c88979ac7f8902aea731975bbcc, run39920694158/job120304921482.
   Exactly the existing two UTF8 views are indexed by a Map with unchanged
   insertion/eviction order. Strict TS7 old/current differential tests, invalid
   raw offsets, equal separately allocated strings, capacity/state checks and all
   prior proof/audit gates pass. Actual generated qualification is running.
   Keep psc1_ts_utf8_cache_fixture and scripts/ts-utf8-cache-runtime-tests.mjs.
   It follows current profile39918874112: last30s of220s, StringEqual61.8% under
   psStringEqFromWithFuel. Cache-versus-character/inlining attribution and full
   compiler performance improvement are not yet established.
   Previous trials are terminal controls:
   Latest combined branch perf/psc1-bridge-lookup-workers-20261023 has source
   0938c895a9ff007a36df72dc49c836dc7443cef3, request
   10ac556f28782c4efeaa72c168f3969aba68ccca, run39914906360/job120286173371.
   It inherits the predicate correction and uses fully applied constructor/height
   lookup workers, retaining old function types. All-input list/name/fuel/index/
   hash equality proofs, first-duplicate/100001-entry native checks, prior
   regressions and source audits pass; G1 and ten cases pass; G2 times out1800149ms/RSS1630836KiB; G3 not run.
   Keep psc1_bridge_lookup_normalization_tests and its retained reference workers.
   Do not infer generation success or alter cache/fuel/index policies.
   The separate predicate-only comparison is also terminal (G2 timeout1800199ms/RSS2878304KiB):
   branch fix/psc1-ts-generator-result-types-20261023, source
   083f900a60f6df3ad32f2d4e1c4afac2c53cf12a, request
   ecd53ad3f7ea96e07b53c7ece405b0f97c67dbf1,
   run39913434540/job120281442220. At this checkpoint the all-Char official
   proof,1114112 native comparisons, quote regressions and source audits pass;
   G1 and ten cases pass; G2 times out1800199ms. Read final jobs/logs/artifacts.
   Do not infer new G1/G2/G3 from an older source or a green native proof.
   Previous shared-codec source29e871ea/requestb5ba1452/run39908439190
   passed G1 then timed out on G2 at1800240ms/RSS2995304KiB; G3 not run.
4. The current correction removes lazy Boolean right-operand thunks from
   psJsonCharNeedsEscape using definitionally equivalent branches.
   Preserve test/JsonEscapePredicateTests.lean and its explicit lake root
   psc1_json_escape_predicate_tests, existing psJsonQuote/native regressions,
   all-input codec/lexer/cursor equalities and both full source audits.
   Never replace failed proofs with axioms/native_decide/sorry or relax checks.
   The current TS220s replay39912539573 samples only its last30s; it is not a
   profile of the final30s of the1800s request. It reaches generator/thunk paths
   around quoting/codec/constructor lookup. Use full bottom-up data, not flat
   native samples, before another performance change. UTF8 cache and prefix-scan
   hypotheses remain unmeasured; preserve the two-entry cache and raw-offset,
   invalid-boundary, Unicode and resource behavior.
5. Keep the two executable wall-clock profiles separate. In psc1/ on Linux:
   ```sh
   node scripts/generated-target-qualification.mjs rust --self-host performance-240s
   node scripts/generated-target-qualification.mjs ts --self-host performance-240s
   node scripts/generated-target-qualification.mjs rust --self-host correctness-1800s
   node scripts/generated-target-qualification.mjs ts --self-host correctness-1800s
   ```
   The default performance profile remains240000ms for every request/tool and
   existing15-minute jobs. Longer profile changes only G2-self/G3-self to1800000ms.
   G1, corpus and builds remain240000ms; independent checker120000ms. Long
   jobs120min/step110min, cleanup5s, streams32MiB/wire128MiB. Never raise fuel,
   heap/stack, admission, output or wire limits to obtain a pass.
6. Use the existing dedicated workflows and source-first/request-only protocol.
   Longer workflow .github/workflows/psc1-rust-ts-selfhost-correctness.yml reads
   .github/qualification-requests/psc1-rust-ts-selfhost-correctness.json.
   Request schema psc1-rust-ts-selfhost-request/2; action
   qualify-independent-G1-G2-G3; profile correctness-1800s; exact branch and
   targets; g2g3TimeoutMs1800000; g1TimeoutMs240000; resourcePolicy
   only-G2-G3-wall-clock-extended;all-other-policies-unchanged.
   Set a fresh id and parentCommit to freshly fetched source HEAD. The next
   commit must change only that request file. Its parent/event.before/
   parentCommit must agree and event.after must equal its commit.
   Existing performance request paths and schema/1 resourcePolicy unchanged
   stay available; do not silently alter their acceptance criteria.
7. Qualification must call the native seed once, remove native compiler
   executables, then actually use emitted compilers for G2 and G3.
   Independently admit/build/execute every generation and all ten corpus cases.
   Require exact closure/source/canonical-admission/original/transformed IR and
   observation fixed points. Keep negative/unsupported-ABI cases and official
   Lean4.35.0 commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
   Long correctness success cannot grant a240s badge. Record per-request time,
   Linux child maxRSS, sampled tree RSS scope, failures and all source/tool/
   manifest/lock/graph identities. Preserve complete artifacts and expiry.
8. Audit each new terminal artifact once through the existing diagnostic branch:
   diagnostic/psc1-selfhost-profile-20261023 and
   .github/diagnostics/psc1-selfhost-receipts.mjs/workflow. Pin actual run,
   source parent, request commit, artifact ID/digest/expiry and download path.
   The audit verifies source inventory/request/manifest bytes without executing
   compiler code; it cannot supply missing admission or qualification.
   Runs39910276762 and39912095877 already audit the previous four profile results.
9. After current TS correctness, optimize actual workloads toward240s. Rust late
   stack39906025465 reaches strict IR nominal-arity lookup; any index must prove
   all-input equality including duplicates/first binding/structure-before-
   inductive priority/Array/misses and retain report/resource counters.
   Do not remove generic worker guards; checked scalar closed planning already
   removes open generics. Retain Rust String moves/private iterative Drop,
   TS checked result annotations/structured generators and all seven mappings.
10. Integrate only coherent validated changes onto fresh main using non-force
    expected-HEAD commits. Do not copy an entire stale isolated tree or overwrite
    already integrated TS annotations. New integrated compiler/backend source
    requires fresh full seven-backend/application qualification. Separate clean
    build reproducibility/readability/unpublished distribution remains work.
    DirectJS G1 and its tracked G2 heap evidence stay preserved; PSKernel
    ExpressionV2 research remains independent.
11. Continuously update AI_WORK_STATE, roadmap and the existing canonical
    qualification receipt with actual terminal boundaries. Keep passive
    historical/declaration JSON snapshots frozen. Avoid unchanged full CI and
    repeated audits; no merge or package publication.

Continue actual development. If session completion is impossible, leave a verified
checkpoint and update this executable prompt with exact remaining work. Never
claim TypeScript self-hosted or either target240s-qualified without its evidence.
