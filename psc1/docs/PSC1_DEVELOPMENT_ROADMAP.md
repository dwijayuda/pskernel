# PSC1 development roadmap

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
PSC1_RUST_TS_SELFHOST_ARCHITECTURE.md). First Linux attempt 39875143168 at cda5478553c78eda834a919a2a85f5229d989691
builds both facades and passes all host negatives/DirectJS scalar tests. No G1:
Rust facade parse refusal; TS Expr context visitor elaboration refusal at 522:1.
Corrections bind the Rust runtime plan before projection and retain TS recursive
arity through a single named worker; an all-input native equality is added.
Both-grammar exact closure audit now precedes generation.
Run 39875554029 stopped at the added proof; no generation ran. Run 39875938564
proves the context visitor equality, then both grammar audits identify native
open directives in target facades and native do/Option syntax in TS Module.
The facades now use qualified names; the module helpers use explicit portable
matches/list helpers. Tests retain old helpers and compare output/runtime choices.
Artifact/source identity checks and the reviewed Rust lock requirement are tightened. Run 39876380647 stopped on a new fixture's Bool constructor, corrected at
02e2b6c2714e7b5e727816e9f57e23cfb15b2c2d. Run 39876683792 at
5176635e0656aed9d937ba13783d8d5b82b0e8b1 proves the visitor equality and all
264 old/new TS module output/runtime comparisons. Rust passes both 92-module
grammar audits, emits a full compiler candidate and independently admits it;
Cargo then reaches ENOBUFS (32 MiB diagnostics), so no G1 executes. Preserve
artifact 12468503739 (sha256 549e18247437786702b88164be9bede201491f3a580529d18e64ed12027b2b32).
TS audit identifies one shorthand constructor at Module:731:20; normalized.
Rust now uses the existing rustfmt target formatting before cargo, without
suppressing warnings or changing the 32 MiB/240000 ms resource bounds.
Read-only diagnostic 39877244232 (af235af31b98d626e28d37a7796cfb7705d04bd9)
confirms 1935 warnings and no Rust errors in the bounded prior log. The exact
recorded Cargo lock is now committed (sha256 4d375c97eebc30fce378df900dd76bdd2cb9d82ce7619f50fb7ab3161f8e576d),
including num-bigint 0.4.6 / num-traits 0.2.19 and checksummed transitives.
TS audit 39877162580 accepts parsing, then identifies an untyped local match
in psTsEmitInductiveWithVisibility at 162:1. An explicit String annotation and
a native definitional-equality proof preserve its exact result. No Rust or TS
G1/G2/G3 execution is qualified yet. Run 39877162580/Rust job 120165435405 subsequently reaches rustfmt ETIMEDOUT
at 240103 ms before cargo. Failed artifact 12468649397 retains that exact source.
The self-host tool now compiles raw emitted source with cargo --message-format=short;
all diagnostics remain, including errors, at the same 32 MiB bound. Per-tool
start/completion timing is durable. Normal production formatting remains intact;
large compiler output readability is a separate pending backend task, not an
excuse to change source semantics or resource limits. Run 39877740380/TS job 120167646244 reaches its 15-minute job bound after the
G1 candidate (no executing generation is claimed). Soft single-process timeout
was insufficient for the target process tree. Linux supervision now enforces
SIGKILL for the whole group at the same 240000 ms child deadline and 32 MiB per
stream; the 245000 ms outer supervisor guard allows cleanup only. Tests cover
ignored TERM, exited parents/inherited pipes, and output overflow. Exact source,
bootstrap, service artifact and completed-case evidence is written incrementally.
New explicit requests cancel superseded requests; source/docs alone still never
run G2/G3. Existing runs/history/artifacts remain. Next: execute the new manual matrix,
fix target/source blockers as classes, capture exact tool/runtime evidence and
complete fresh normal qualification after compiler changes.


Updated 2026-10-23. The single release authority is
PSC1_PRACTICAL_CORE_V1_CONTRACT.json: 14 frozen feature families, 37 finite
criteria, both source grammars, seven targets and four actual application
categories. Preserve working functionality. Detailed supported semantics remain
in PSC1_PRACTICAL_CORE_DECISIONS.md; AI_WORK_STATE.md owns continuation status.

## Latest compiler and resumed manual qualification

Compiler source 7732e9786d09d11c1130da4b315c985e9978f23b, tested merge
055ba9833567d3cb166341ec1da794eb725b0414, now passes fresh Linux run
39867567126: every selected job, all 47 full-job steps and 37/37 finite criteria.
Source equivalence proofs, conservative worker captures (including global-read
timing), both grammars, all seven targets, G1, complete closures, host boundary,
minimum Python and installed native package qualification pass.
PSC1_SELFHOST_RESUMPTION_QUALIFICATION_2026-10-23.json retains exact evidence.

The separate manual workflow has been resumed; it is not returned to a
feature-freeze deferral. Latest actual source 573bf485 / run 39864113546
passes ten G1 cases, then G2 times out at 240197 ms before admission/publication;
G3 is not run. The final local-binding correctness guard changes compiler bytes
after that failure, so no G2 execution result is claimed for the latest source.
The retained diagnostic enters 29/86 modules by the original deadline, last in
CheckedAdmissions declaration index 59, with about 2.27 GiB observed RSS.
Function-entry samples do not prove completion, scaling or memory bounds.

General frontend/elaboration throughput and lifetime is the immediate blocker.
Require a measured correction on exact and practical large-source inputs, then
fresh full and explicit G1/G2/G3 qualification with unchanged resources and all
identity/refusal checks. Preserve every prior failed/successful artifact and the
original heap-exhaustion defect. No merge or publication has been authorized.

## Historical Practical Core v1 baseline qualified

Source 9ee6c5ffe8ac344b349fde7eee8f5ef867bd5dde passes every selected gate in
Linux run 39829564386, tested merge 00decc7fb81fc4023f68cdcdbf8cff1fdd028b12.
All 47 full-job steps succeed. Native/focused, all three compiler closures,
G1, host boundary, all-seven/minimum-Python/package matrix and aggregate pass.
The exact inventory is 37 qualified / 0 blocked, data releaseReady=true.

PSC1_PRACTICAL_CORE_V1_QUALIFICATION_2026-10-23.json retains exact evidence,
artifact identities/expiry, actual application observations, G1 and source/IR/
admission digests. The earlier incomplete checkpoints remain historical evidence.

Normal G1 performance is restored: the first small case finishes in 2254 ms
after previously timing out at the unchanged 240-second limit. All ten cases
pass. The root correction creates recursive printer helpers after their input
binders, preventing an exponential setup tree over fuel. Seven matching printer
visitors are normalized, with driver semantics and resource policies retained.

The normal qualification run executes the same four reusable workflows as the
manual Practical Core wrapper and the same complete readiness assertion through
requireReadyOnFullQualification=true. Its completed evidence satisfies the
executable finite contract; a manual event is not claimed and an identical
expensive replay is not scheduled merely to change the triggering event.

Current release-facing documents and the derived status inventory are reconciled
with this checkpoint. The prior status is archived; a static regression checks
the contract/receipt/status identities and rejects incomplete required gates.
PSC1_RELEASE_CANDIDATE.md records exact package provenance, artifact expiry and
ABI selection. This documentation/test continuation changes no compiler bytes. Its static
checks and aggregate pass in Linux run 39846954055; the dated release
reconciliation receipt records the source interval and exact selected evidence.

## Dependency-ordered continuation

1. Keep the qualified candidate stable for release review. Merge/publication
   require separate authorization; retain the draft PR and all history.
2. Continue resumed manual self-host qualification through the measured
   frontend/elaboration performance blocker described above. G2/G3 remain
   unqualified; preserve the exact ten-case corpus, resource limits, source-bound
   failures and all independent-checking/strict-IR/negative gates.
3. For later practical feature or compiler changes, state finite acceptance,
   complete shared semantics and both grammars, validate JS/TS/Rust early, then
   every relevant backend mapping. Requalify changed source before declaring
   completion. Keep nonessential extensions outside frozen v1.
4. PSKernel-Core Expression V2 research progresses independently. Official
   Lean 4.35.0 admission remains; incomplete owned-kernel work does not block
   ordinary language/compiler/backend development or replace admission.

## Engineering and CI policy

Keep independent official admission at
eb6cafb7290e8bd5f2937522d8d804f58f02bafc, strict original/transformed/target IR,
ordinary body/witness pairing, actual applications and IO effects, negative
tests, unsupported ABI/publication preservation, and fixed resource limits.

Static -> native/focused -> selected integration (closures/G1/host boundary)
-> full all-seven/minimum-runtime/package qualification are the development
tiers. Focused core and unchanged five-target measured applications run in
parallel 15-minute lanes, each retaining all original commands and child bounds.
Exact-source caches do not replace fresh checks. Artifacts include lane/attempt
identities. Failed/cancelled debt survives to the next source update; unknown
policy changes conservatively select full testing. Documentation and archived
qualification receipts do not rerun compiler work after a successful baseline.

Construct recursive visitor helpers after all remaining input binders.
Partial worker calls before the returned lambda can eagerly branch over the
fuel budget in generated strict code, even when native execution looks fast.
Use real generated execution and fixed input/time/RSS evidence to verify fixes.

G2/G3, unrestricted Lean/metaprogramming, arbitrary effects, unsupported public
compound ABIs, non-Linux distribution and formal backend-preservation
certificates remain outside this finite qualification. Preserve explicit
refusals and the selected ordinary while profile, including all sixteen wider
profile refusals. No soundness, security, semantics or resource boundary is relaxed.
