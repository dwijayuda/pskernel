# DirectJS and owned DirectWasm qualified continuation

Use connected GitHub tools and Linux GitHub Actions only. Do not create a local
checkout/build/test. Fetch current HEAD and read AI_WORK_STATE.md, the single
roadmap, architecture and canonical2026-10-24 receipt before writing.
Use fresh expected-HEAD, non-force updates. Preserve concurrent work.

## Verified starting point

Review: work/psc1-direct-selfhost-blockers-20261024, draft PR175, baseafed7c4b.
Qualified executable source133e589288b563e74578b771ec35595beb3a9fe8.
Request2d1f8244d8402fbccd5a018890d61d8ed4d20775,
parent eefedf2a3f9f0002975870e8128bb0f404723946.
Run40062120079 PASSED:
- JS job120777813920, G2/G3824066/832426ms, maxRSS3076776/3179880KiB.
- Wasm job120777813877, G2/G3876840/888398ms, maxRSS1508096/1816228KiB.
Both execute genuine independently checkedG1→G2→G3 with native compilers
disabled after one seed, strict IR, all ten positive/negative observations and
exact source/admission/IR/target-byte fixed points.
Artifacts12548433615 and12549160290; digests/closures/request/producer hashes
in PSC1_DIRECT_SELFHOST_QUALIFICATION_2026-10-24.json.

Clean G1 reproduction40064496804 PASSED at36d917b01a008fcae2259fc7a604b3e8a47e3db1
on diagnostic/psc1-direct-clean-g1-20261024. No .lake cache restored. Fresh
native seed/checker reproduce exact inventories, source/admission/IR/observations
and JS/owned-Wasm bytes of all three qualified generations.
Artifacts12548393011 and12548652944. This is not a second independent G2/G3
execution, DDC or a formal compiler-preservation proof.
Reproducible audit sources on that exact commit:
.github/diagnostics/psc1-direct-g1-rebuild.json
.github/diagnostics/psc1-direct-g1-rebuild.mjs
.github/workflows/diagnostic-psc1-direct-clean-g1.yml

[Full40062210987](https://github.com/dwijayuda/pskernel/actions/runs/40062210987)
PASSED: Linux120780825013 and final gate120786364196;37/37 qualified,0 blocked,
releaseReady=true, all seven backends, both grammars, applications, minimum
Python and installed native package/IO/library regressions. Tested review HEAD
06186537cf9339fc3f24a7d13387c2ad55ee0749 and merge
980d096ca3e85b9ad2970f16602ad1d14a089d69 have identical Git tree
cbf312e1f4bca9e7085719c12b627be5c16099a7, verified through GitHub APIs and checkout log.
Artifact12549325904, digest
sha256:6ad48b109e2e995c344a6855a85de44380f6ee628b67f4033990a152598a7bf9.
This qualifies the tested compiler source; the final receipt update edits docs only.

## Execute next only when further development is requested

1. Re-query exact HEAD, PR and relevant terminal CI. Preserve qualified snapshots
   and artifacts. Do not re-run unchanged1800s correctness chains merely for
   documentation updates. Do not infer current-source Rust/TS qualification
   from older references.
2. Original performance-240s remains unqualified: all current directG2/G3
   durations exceed240s. Profile the actual completed generated compiler
   workload from immutable qualified artifacts/requests. Existing retained
   profiling script/workflows on diagnostic/psc1-direct-selfhost-profile-20261024
   are starting points; adapt exact artifact/request identities with validated
   source-bound diagnostic commits. Pin Node/Lean/wasm-tools and retain profiles.
   Keep sampling overhead separate from clean timings. Do not claim comparative
   backend speed from different compiler closures.
3. Diagnose a demonstrated cost class, then make one dependency-coherent fix.
   Preserve generic APIs/semantics; retain old complete API as proof reference
   where applicable. Test whole-class regressions, exact first/rightmost-error
   priority, lookup duplicate precedence, order/capture/alias/fuel and ABI refusal.
   Preserve all existing backend-neutral architecture and seven targets.
4. Run focused proof/runtime/source gates before expensive generations. The
   current focused request mechanism and workflow are in the review tree.
   Keep both87-module JS and98-module Wasm .lean/.ps inventories exact.
   No fixture-only success may be promoted to self-host qualification.
5. After source stabilizes, create a request-only single child commit changing
   .github/qualification-requests/psc1-direct-selfhost.json. Read fresh HEAD;
   parentCommit must equal it. Keep schema psc1-direct-selfhost-request/1,
   active allowed branch, action qualify-independent-G1-G2-G3,
   profile correctness-1800s, selected targets js and/or wasm-core,
   g2g3TimeoutMs1800000,g1TimeoutMs240000,resourcePolicy
   only-G2-G3-wall-clock-extended;all-other-policies-unchanged.
   No source/docs edits in request commit. Actual native seed then generated
   G1→G2→G3 must execute and independent Lean/strict IR/negative/fixedpoint gates
   must all pass. Run performance-240s separately without relaxing its criteria.
6. Reconcile full current-source37/37 seven-backend/both-grammar/application CI,
   exact testedmerge/head/tree and immutable artifacts. Update AI_WORK_STATE.md,
   roadmap and receipt together. Preserve superseded failures rather than
   silently replacing their results. If a repeatability release criterion needs
   a second full clean chain, run it and label that additional scope separately.
7. Preserve Rust fix/psc1-rust-owned-string-moves-20261023 at83e18fe183498f7d8b0fc3e3faa5bdacc41cb23d
   and TS perf/psc1-erasure-applied-workers-20261023 at84e1e16f61cec3d28d9fdc62d6eaca4f3c0a8577.
   Preserve official Lean4.35.0 checker eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
   strict original/transformed IR, exact source/logical pairing, negative tests,
   semantic fuel and every memory/stack/security policy. G1/corpus/tools240s,
   checker120s,correctnessG2/G31800s; original240s profile remains separate.
   Do not merge PRs or publish packages without authorization.

The requested direct-target self-hosting mission is complete at this checkpoint.
Remaining work is performance/release engineering with the explicit evidence
boundaries above. Prior pending blocker descriptions are historical only.
