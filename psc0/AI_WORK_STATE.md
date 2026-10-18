# PSC0 v7.2 AI work state — M3+B

Updated 2026-10-18. Fresh GitHub refs and exact-SHA CI override this checkpoint.
M3+B and full selected `.lean`/`.ps` input parity remain OPEN.

## Work contract

Complete all six M3+B exits autonomously through GitHub connectors and GitHub
Linux CI only. No local checkout/files/build/test/compiler or Desktop Commander.
Compiler implementation is native portable `.lean`, pinned to official Lean
4.35.0, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Study pinned source
and tests before substantial design; preserve upstream Apache-2.0 notices.
Minimal coherent validation; no PSKernel-Core/C0, self-hosting, C5 or VSIX work.
Approved logical assumptions exactly `propext`, `Quot.sound`, `Classical.choice`.
Wasm GC internally; linear memory only at explicit ABI boundaries in this
compiler lane. Never weaken acceptance, fabricate evidence or enlarge budgets.

Both `.ps` and `.lean` compiler INPUTS follow the selected v7.2 features,
semantics and assurance rules for every supported output. Keep distinct surface
grammars: native Lean layout/application in `.lean`, owned ProofScript spelling
in `.ps`. Both converge on shared resolution/elaboration, checked Core, typed
erasure, validated IR and backends. Do not parse `.lean` as `.ps`, accept arbitrary
host Lean, or use its extension to bypass unsupported-feature, dependency,
assumption, recursion or verification rules. Native oracle tests are not input
parity evidence. Preserve unresolved-proof and verified-assurance refusals.

Repository: `dwijayuda/pskernel`.
Main: `psc0/pscv0-v7-native-lean-v1`.
Preparation: `psc0/m3-fixedpoint-foundation-20261018`.
PR109 remains an unmerged draft unless a fresh authorized operation says otherwise.
Use expected-HEAD, non-force ref updates and preserve concurrent history.
Never supersede/cancel a healthy main Native run. Preparation keeps
`cancel-in-progress: false`, at most one active and one pending run.

## Qualified baseline and unchanged foundation

Fresh main ref read in this continuation: `33676076bcda7b0de5ec1f9803f49b8b1d28a058`.
No main promotion was performed. The prior exact-SHA integration receipt is
[PSCV0_M3_INTEGRATION_33676076_2026-10-18.md](docs/PSCV0_M3_INTEGRATION_33676076_2026-10-18.md).
It records Native 39099546592, M3 39099546513, F1 39099546493,
F2 39099546574 and F3 39099546446 as successful for that SHA.
Do not apply those results to later preparation code.

Selected foundation remains 3757 declarations, 44 classes, 371 ordinary instances,
13 defaults. FNV `3071911941504503432`; declaration SHA256
`364627b451f83a04064643d29f0fa3bb1bda85eab70d588d3e66755ddc67efe1`;
surface SHA256 `9b07ab5dc1ce2e429fb5ebe4dba0e8da5db667d395521718e0a9a65f9e748214`.
Preserve all frozen asset-authoring stages and historical receipt identities.
`Classical.propDecidable` is not an automatic runtime instance.

## Current PProd correction

Initial fresh preparation ref was `2cc98ec70d1e7ee216e81b43a513128588d148f7`,
not the previously reported `01424b88`. That commit already registered selected
`PProd`, `PProd.mk`, `PProd.rec` in `SelfHostProd.lean`'s shared runtime catalogue,
but also accidentally made the frozen F4 scientific stage refer to itself.
Run 39116402919 failed native build; subsequent substantive checks were skipped.
Do not describe that run as testing PProd runtime behavior.

Pushed `d1d8fa4293ddff18ee5e85bd27ab468191deca61` as a non-force child:
- Restored `psSelfHostProdPreFloatDisplayPreludeEnvironment` to extend
  `psSelfHostProdPreFloatConversionsPreludeEnvironment`.
- Kept the shared selected-data registration, with no backend-specific primitive,
  new logical declaration, axiom, runtime Order library or fingerprint change.
- Extended the existing foundation inventory with the F4 boundary equation and
  hard checks that the PProd roster is complete, selected and uniquely registered.

Run 39120696559 / job117655533765 is the exact d1d8fa42 preparation run.
Last inspected while in progress: native build, selected manifest, fixedpoint
and PSum exports, retained PSum/packing, native Order metadata, selected source
behavior and indexed matching PASSED. The combined primitive-audit/recursor
candidate step FAILED; fetch completed logs for its exact reason. Source-step
success is not yet backend execution or full integration qualification.

## This child: independent failure attribution and actual runtime checks

The existing preparation workflow now separates ordinary primitive/closure audits
from the UNSELECTED recursor authoring step. Both remain required and fail the
job on error. No `continue-on-error`, skipped case or changed expected result.

The existing recursor executable first reports the earliest structural mismatch
per native recursor, including an exact expression path and both raw subexpressions.
It then calls the unchanged strict candidate authorer. This diagnostic does not
normalize types, modify assets, replace native references, approve mismatches,
select fingerprints or change the original error status. It is intended to expose
the actual Fin.rec mismatch and any related cases together, rather than guessing
or weakening correspondence from a single failing example.

Preparation additionally builds/runs the existing structural-mutual source fixture
and executes its outputs plus both existing input-parity fixtures through direct
JavaScript, strict TypeScript, Rust, Wasm GC and components. Reuse the existing
`pscv0-m3-runtime.mjs` observers and every listed expected export, including
`m3fields`; no new backend implementation or alternate oracle.
Runtime steps require successful source fixtures. Independent backend failures
remain visible even if another backend or the authoring candidate failed.
This is focused preparation coverage, not all five integration gates.

This child is UNQUALIFIED until its actual build, logs and runtime observations
are inspected. Do not promote it on the basis of d1d8fa42 or main33676076.

## Remaining critical path

1. Read exact-SHA preparation logs. Close any genuine PProd/runtime regressions,
   retaining proof-valued components, heterogeneous data and `.ps`/`.lean` cases.
2. Correct the independent selected recursor source-metadata authoring mismatch
   from actual structural evidence. `StandardFin.lean` uses `Nat.lt` in its proof
   field; do not assume the native raw term has identical syntax. Earlier strict
   authoring failed at Fin.rec. Selected Except intentionally specializes Type-0
   universes, so whole-native-type substitution is not a metadata-only fix.
   Preserve all logical layouts and earlier frozen bases. Require official
   trust-zero replay, complete binder metadata, symbolic iota checks and independent
   digests before selecting any new asset. Keep the six exact `$psc0Format` helper
   recursors separate from the 109 native-library identities.
3. Implement selected named/generalizing matches using the existing Match,
   PatternMatrix and dependent refinement owners. Retained design:
   `docs/PSCV0_M3_MATCH_METADATA_DESIGN_2026-10-18.md`. Keep named branch equations
   separate from structural IH motives and automatic index-constraint discharge.
   No copied host elaborator, ad hoc retry or fresh parallel matcher.
4. Finish the six-exit source-rule/native-owner/evidence audit, then green
   preparation and all five same-SHA integration gates before main promotion.
   Continue M3+B -> M4+C/D -> M5+E, without starting self-hosting or C5 now.

Canonical v7.2 retains structural-subterm restrictions and pending equation-style
acceptance. Source mutual blocks select definitions/functions, not mutual data
syntax. Native default mutual/nested induction refusal is intentional; explicit
recursors have separate support. Acc.rec large elimination does not authorize
automatic Type-valued predicate recursion.

## Retained detailed history and designs

The prior work state and continuation prompt were copied verbatim by their Git
blob identities, not reconstructed or discarded:
[earlier work state](docs/AI_WORK_STATE_PRE_PPROD_2cc98ec7.md) and
[earlier continuation prompt](docs/AI_CONTINUE_PROMPT_PRE_PPROD_2cc98ec7.md).
They retain detailed source construction, function-field, named application,
proof-form and parser/elaborator negative-control history, exact run/artifact
identities, existing designs and upstream reference rosters. Read them when
continuing those slices; their old 'running' statements are historical.

Authoritative remaining references include `ARCHITECTURE.md`,
`PSCV0_LANGUAGE_REFERENCE_v7.2.md`, the native implementation roadmap,
`docs/PSCV0_M3_LEAN_FOUNDATION_AND_EXIT_LEDGER_2026-10-18.md`,
`docs/PSCV0_M3_RECURSOR_FOUNDATION_SOURCE_2026-10-18.md`, and the prior detailed
checkpoint. This continuation also directly inspected pinned Lean
`src/Lean/Meta/PProdN.lean`: PProd/And packing and shared projections support the
chosen runtime-catalogue owner, not target-specific special cases.
