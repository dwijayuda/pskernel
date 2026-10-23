# Executable PSC1 continuation after longer-profile qualification

Continue PR172 autonomously through implementation and Linux qualification.
Use connected GitHub tools and Linux Actions only: no local checkout/files/builds/
tests. Fetch fresh HEAD before expected-HEAD non-force updates; preserve history.
No merge or npm publication is authorized.

1. Fetch PR172 and active fix/psc1-closure-normalization-20261021 HEAD.
   Read applicable AGENTS instructions, AI_WORK_STATE, roadmap, profile contract
   and PSC1_SELFHOST_PROFILES_QUALIFICATION_2026-10-23.json first. It is a compact
   projection tied to the exact Git blob of the exhaustive canonical receipt.
   Code5ce2fc74b9f01682832ddc10ec9ef27f26458564 / merge
   a61eecf46ded19eedcdefcb320aa33118cd8f2ad passes normal39909569028:
   all selected jobs,47 full steps,37/37 finite criteria. Preserve14 families,
   both grammars, seven targets, four applications, strict IR/official/negative
   checks and unpublished native package. Full artifact12483409585 expires
   2026-11-06T06:45:00Z.
2. Preserve the qualified isolated Rust reference:
   branch fix/psc1-rust-owned-string-moves-20261023, source
   5e0b548e6cb3606ee0d3c129e0a829d830e407e4, request
   7d8865a08427a28432e427592dfc4263718c9a2f,
   run39908529181/job120265913272. Actual G1/G2/G3, official admission and exact
   source/closure/admission/original/transformed IR/ten-case fixed points pass.
   G2/G3 are692788/660042ms, RSS668192/668184KiB. Same-run executable SHA256
   d55a8435a157f021e5a7c073037303429b9787729c963af3842a04b9fb009017
   matches all3 generations.240s and independent clean builds remain unqualified.
3. All TypeScript generation trials are terminal, G1-only:
   shared codec run39908439190 G2 timeout1800240ms/2995304KiB;
   direct predicate39913434540 timeout1800199ms/2878304KiB;
   applied lookups39914906360 timeout1800149ms/1630836KiB;
   bounded-map39920694158 timeout1800169ms/1787220KiB.
   None produces an admitted G2 candidate; no G3/fixed point.
   Original performance-240s runs remain separately failed; do not weaken them.
4. Preferred next engineering base is the applied-lookup source without the
   unproven-benefit Map: source0938c895a9ff007a36df72dc49c836dc7443cef3,
   tested request10ac556f28782c4efeaa72c168f3969aba68ccca,
   run39914906360/job120286173371. Workflow/documentation descendant
   a10c0162805d0e3e39375d1be55ae38d77ff67d9 has identical compiler code and the
   correct separate240s proof lane. Create a fresh experiment branch from that
   immutable base, update workflow branch guards and copy current continuation
   docs. Never force-reset the later experimental branch.
   Input closure8a875f219d60c3cb7b266569b5533dd96c4e891adbac7fbb02b1215f6fbdbccf;
   G1 manifest e3e93fc46e47ad6036769b6d98655e1a426cb3917bd6417a58254b65d0f9e29f;
   request cffb8230e123e8e9411de5e02133b0b8191dd2c8110f2e2c6a3c0c7651836c2f.
   Artifact12485169920/digest2dd1dc8d8614ec346f53da1d693ef0ddb86410861c3e8f822ea527bf3af5acdf
   expires2027-01-21T06:59:33Z.
5. Preserve the proven changes: all-Char escape-predicate equality with1114112
   native cases; all-list/name/fuel/index/hash constructor/height lookup equality;
   first duplicate and100001-entry miss; existing all-input cursor/lexer/codec
   proofs and source audits. Audited specialized IR confirms constructor/height
   list workers and wrappers now take2 parameters and return data/scalars with
   no body lambdas; the predicate emits a plain function. Existing closed worker
   fusion did not remove the old eager let-before-lambda lookup bodies.
   Do not repeat ineffective wrapper rewrites or remove generic guards blindly.
6. Inspect saved current profile39918874112/job120298957773 at diagnostic source
   a5011506a4d1bad2700802f9ef611616fc439ca9. It is last30s of a220s replay, not
   the last30s of1800s. StringEqual17099/27684 ticks(61.8%),17090 under
   psStringEqFromWithFuel; shared Node17.9%. Profile artifact12485957720 digest
   152b1f627bdc7338a7500ec331f4289f53cca7bb9e15f4c9aadb9f2624449c84,
   expiry2027-01-21T07:36:19Z. Use bottom-up data and generated-code/inlining
   context; determine actual caller and compared-string lengths/equality cases.
   Source character comparison uses Nat.beq(Char.toNat...), while runtime cache
   text comparisons can inline into the same worker. Establish the causal path
   on actual generated compiler work before changing code or retrying1800s.
7. Preserve the bounded-map experiment separately:
   sourceaae4aac442154bb0c95fedb35f19fdb1552cc271/request
   9f39ab515a3a0c88979ac7f8902aea731975bbcc/run39920694158/job120304921482.
   It keeps2 views/exact eviction and passes1458 strict old/current runtime
   comparisons, Unicode/surrogates/invalid offsets/equal separate strings.
   Synthetic prefix was10.215ms old/10.496ms indexed (no advantage asserted);
   real G2 still times out. It is not selected for promotion.
   Artifact12488294175 digest515d90795f00cc2c3c22af72d65e272ec0bc24d42e632bbb051ac3e4253ea8da
   expires2027-01-21T07:52:25Z. Do not remove history or claim a speedup.
8. Make a small dependency-coherent correction addressing measured cost. Keep
   all input/output/error/evaluation/Unicode/raw-offset/fuel semantics and
   negative/unsupported ABI refusals. Any primitive String equality replacement
   needs official all-input equivalence and supported source builtin mapping;
   do not use native_decide/new axioms/sorry to bypass opaque String APIs.
   Any loop/view reuse must avoid eager work on exhausted fuel, alias/shadow/
   capture issues and retaining extra views across calls. Do not expand the
   existing cache, heap/stack/fuel/stream/wire limits.
9. Run through Actions only. Profiles from psc1/:
   ```sh
   node scripts/generated-target-qualification.mjs ts --self-host correctness-1800s
   node scripts/generated-target-qualification.mjs rust --self-host correctness-1800s
   node scripts/generated-target-qualification.mjs ts --self-host performance-240s
   node scripts/generated-target-qualification.mjs rust --self-host performance-240s
   ```
   performance keeps15-minute jobs/240000ms every request/build.
   Longer profile changes only G2-self/G3-self to1800000ms, job120min/step110min.
   G1/corpus/builds240000ms; checker120000ms; cleanup5s; streams32MiB/wire128MiB.
   Use source-first then request-only commits. Long request path
   .github/qualification-requests/psc1-rust-ts-selfhost-correctness.json:
   schema psc1-rust-ts-selfhost-request/2; action qualify-independent-G1-G2-G3;
   exact branch/targets; profile correctness-1800s; g2g3TimeoutMs1800000;
   g1TimeoutMs240000; resourcePolicy
   only-G2-G3-wall-clock-extended;all-other-policies-unchanged.
   Fresh id/parentCommit; next commit changes only the request file.
   Parent/event.before/parentCommit must agree, event.after equals request commit.
   Retain existing performance schema/1/resourcePolicy unchanged request lanes.
10. Native seed once, then remove native compiler executables. Actual emitted
    compilers must produce G2/G3, independently admit/build/execute all ten cases
    per generation and exact fixed points. Official Lean4.35.0 commit
    eb6cafb7290e8bd5f2937522d8d804f58f02bafc, original/post-plan strict IR,
    source/tool/artifact identities and every negative remain.
    Long correctness cannot grant240s. Record time/RSS/failures and artifacts.
11. Audit each new terminal artifact once with the existing diagnostic branch
    .github/diagnostics/psc1-selfhost-receipts.mjs/workflow, pinning source parent,
    request, run, artifact ID/digest/expiry. Audits39910276762/39912095877/
    39917944529/39918849858/39925093205 already cover all current attempts.
    They verify data and never supply missing admission/qualification.
12. After TS correctness optimize both toward240s. Rust exact late stack39906025465
    reaches strict IR nominal-arity lookup. Any index must prove first-binding/
    duplicate/structure-before-inductive/Array/miss equivalence and retain all
    report/resource counters and size preflight. Keep checked scalar closed
    planning/generic fallback, Rust ownership/private safe Drop, TS checked
    generator results, all input grammar/proof tests and all7 backend mappings.
13. Integrate only coherent validated files onto latest main, preserving existing
    TS annotations and concurrent history; do not copy a stale entire tree.
    Fresh full seven-backend/application qualification is mandatory for new
    integrated compiler source. Same-run Rust executable equality is not separate
    clean-build reproducibility. DirectJS G1 and its G2 heap evidence stay;
    ExpressionV2 research remains independent and never replaces official Lean.
14. Update AI_WORK_STATE/roadmap, exhaustive canonical receipt and its compact
    derived projection together from actual CI data. Freeze passive history.
    Avoid unchanged full CI, repeated audits and unmeasured cache/architecture
    experiments. No merge or package publication.

Continue actual implementation from this verified checkpoint. Neither target is
240s-qualified and TypeScript is not self-host-qualified. Do not claim project
completion or promote a candidate without the required fresh evidence.
