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

Snapshot as of2026-10-23 22:39UTC (re-query before acting):
- Childc115c65732ea1bf78aba263658e9ab804e116822 fixes the main Wasm
  lower-expression prefix. Focused40034701526/job120691199253 PASSED:
  52 all-input prefix equalities;464 owned Wasm definitions scanned with no
  unsafe prefix; actual retained original rejected; million-fuel early result
  and exact zero-fuel refusal; both87/98-module .lean/.ps and all earlier tests.
- Last Wasm487e7100/run40031965458 completed independently admittedG1/ten
  cases, then G2 stack666386ms/1026060KiB. Exact retained map40033860834
  identifies repeated2286 as psWasmLowerExprWorker. Its335-character type
  exceeded the old guard180-character bound; the recursive binding still
  preceded all four inputs. c115c657 fixes placement, no resource/fuel change.
- JS request8d7a5dc5488e872c0f81b5f848fd6b44d3654456, parent844f8c3b,
  run40033515365/job120687475727 is executing actual generations on verified
  direct-dispatch source82994f85. Later Wasm-only edits leave its closure
  unchanged. Do not duplicate/cancel that request.
- Prior JS85433830/run40027650302 completedG1 but G2 hit1800227ms/3132516KiB.
  Retained profile40031550466 confirms6 lazy getters and StringEqual0.1%
  sampled ticks; direct dispatch removes helper generators and duplicate
  lookups, with64 order/trap cases and40→20 instrumented lookups.
- Review branch/draft175 was non-force fast-forwarded to8d7a5dc5 after the
  prior full gate completed. New full40033570924 is active; focused40033565233
  passed. Request workflow40033565129 correctly skipped multi-commit ref
  integration. Keep review stable until that full run ends.
- Preserved parent85433830/full40027662328 PASSED37/37,all seven/both
  grammars/apps/packages,tree1382a67a7af0975fda2ecb855a1ee011d035af8f.
  Changed compiler source requires its own full qualification.
- Next request selects onlyWasm on the latest child after this passing gate.
  Check the remote manifest/run first: it may already have been dispatched.
- Neither direct target has a terminal qualifiedG2/G3 fixed point yet.

1. Re-query the actual JS run, latest child Wasm request/run and review full CI. If still active, continue waiting without
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
   - Wasm owned-closure prefix guard plus52 all-input equalities, including the main lower-expression worker.
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
