# DirectJS and owned DirectWasm self-host continuation

This is an executable continuation prompt, not authorization to merge or publish.
Use connected GitHub tools and Linux GitHub Actions only. Do not create a local
checkout, local scripts, local build or local tests.

## Continue autonomously

Continue PSC1 self-hosting from the latest remote HEAD. Read AI_WORK_STATE.md,
PSC1_DEVELOPMENT_ROADMAP.md, PSC1_COMPILER_SELFHOST_ARCHITECTURE.md and
PSC1_DIRECT_SELFHOST_QUALIFICATION_2026-10-24.json first. Fetch every relevant
remote ref before writing. Preserve history with expected-HEAD non-force updates.

The active child branch is work/psc1-direct-selfhost-spines2-20261024.
The preserved review branch is work/psc1-direct-selfhost-blockers-20261024,
draft PR175, based on draft PR174/integrationafed7c4b. Do not cancel existing
qualifications or infer success from elapsed job time.

Snapshot as of2026-10-23 21:56UTC (re-query before acting):
- Child implementation52cff17196b71481e3cb8ced1c4d3fee2d1280d0 passes full
  focused40028430603/job120670363952: generic reverse fold and three complete
  erasure index API equalities, all prior ordinary/checked/prefix proofs,
 10000 declarations, native/reference/runtime/negative/capture/owned-Wasm
  checks and both87-module JS/98-module Wasm Lean/PS source censuses.
- Actual child Wasm requestbef0e260a062f89981af514480d9bd7414047d97,
  parent4f88fac688408adb7a4c059539746719c39c0170, run40028857732,
  job120671963814 is executing G1/G2/G3 on that source.
- Parent JS request85433830522dc0cc52541b985510122b67dea364,
  sourcefcea1326b6abf02d151a8e0a248d95a70c9e0faf,
  run40027650302/job120667923890 is executing generations.
- Parent full40027662328 is in Linux job120672846738 after its selected
  static/native/core/application/closure/G1 jobs passed.
- Parent merge34d29e215ea568466dcbc96b14b5e10b2dddb438 and head85433830
  have identical tree1382a67a7af0975fda2ecb855a1ee011d035af8f.
- Neither active direct-target attempt has a terminal fixed-point result yet.

1. Re-query those three runs. If still active, continue waiting without
   dispatching duplicates. If completed, inspect the actual job log and immutable
   artifact metadata; record exact source closure, request/service/source/binary
   identities, G2/G3 elapsed times, Linux wait4 RSS and sampled process-tree RSS,
   independent admission, original/transformed strict IR, observations and
   fixed-point outcomes. A failed G2 means no G3/fixed-point claim.

2. On a failure, diagnose its actual retained generated compiler/request. Do not
   substitute a native compiler or current-source rebuild for that diagnostic.
   The isolated diagnostic branch diagnostic/psc1-direct-selfhost-profile-20261024
   has hash/provenance-checked scripts for actual JS CPU profiling and Wasm
   binary-export-anchored function mapping. A read-only IR inventory is a
   heuristic review queue, not a list of proved defects. The large-fuel,
   declaration-spine and StringEqual mechanisms are documented in the architecture
   note. Fix a relevant defect class with exact old/new acceptance and refusal
   criteria, rather than raising stack/fuel/heap/deadline limits.

3. Preserve all current proofs and regressions. In particular:
   - Wasm delayed-prefix guard plus51 all-input equalities.
   - Ordinary accumulator/public API equality and exact canonical ordering.
   - Checked collector/lookup/normalization equality and rightmost-error priority.
   - Erasure generic right-fold and three complete index API equalities,
     including first-entry precedence, hash shape, output names and counts.
   - DirectJS immutable iteration captures, alias/hygiene/fuel fallbacks and lazy
     invariant UTF8 tokens: max2 indexed views, size-only non-admission, original
     extraction and source String equality.
   - Raw byte/float metadata bounds and existing source scalar/float refusals.
   Native proofs/fixtures/source census do not replace generated execution.

4. After a passing focused gate, create a request-only child commit changing
   .github/qualification-requests/psc1-direct-selfhost.json. Read the latest
   HEAD immediately beforehand; parentCommit must equal that HEAD. Keep:
   schema psc1-direct-selfhost-request/1; exact active allowed branch;
   action qualify-independent-G1-G2-G3; profile correctness-1800s;
   selected targets js and/or wasm-core; g2g3TimeoutMs1800000;
   g1TimeoutMs240000; resourcePolicy
   only-G2-G3-wall-clock-extended;all-other-policies-unchanged.
   No source/document edits in the same request commit. The existing workflow
   validates exact parent/path/branch and performs one native seed per target,
   then actual generated G1→G2→G3 with the native compiler removed.

5. Qualify the final common source for both targets. A successful parent JS run
   is valuable preserved evidence, but does not qualify subsequent changed
   erasure source. Once the common compiler is stable, execute current-source JS
   and Wasm generation chains and exact source/admission/IR/observation/target-byte
   fixed points. For Wasm bind the owned decoded binary too. Keep the original
   performance240s profile separate from1800s correctness; independent clean
   builds are a separate reproducibility claim.

6. Preserve terminal parent full-CI evidence. When the child is verified and
   stable, update the existing review branch by a fresh expected-HEAD non-force
   fast-forward if it is still an ancestor. Do not lose concurrent changes or
   merge a PR. Obtain full current-source seven-backend/both-grammar/application
   CI and derived37/37 readiness. The parent's full result is scoped to its
   exact tested tree; it cannot be inherited by changed compiler code.

7. Continuously reconcile AI_WORK_STATE.md, the single roadmap and canonical
   direct-target receipt with exact immutable results and executable next steps.
   Preserve qualified Rust83e18fe183498f7d8b0fc3e3faa5bdacc41cb23d and
   TS84e1e16f61cec3d28d9fdc62d6eaca4f3c0a8577 branches/evidence. Preserve official
   Lean4.35.0 checker eb6cafb7290e8bd5f2937522d8d804f58f02bafc, strict IR,
   negative tests, source identities and all resource/security boundaries.
   Do not merge, publish npm packages, return to another backend as a substitute,
   or stop after a small milestone.

Finish with genuine independently checked reproducible G1/G2/G3 fixed points
for DirectJS and owned DirectWasm, plus full latest-source regressions. If the
session cannot finish, leave a verified checkpoint and refresh this continuation
prompt with terminal/live state and the exact remaining blocker.
