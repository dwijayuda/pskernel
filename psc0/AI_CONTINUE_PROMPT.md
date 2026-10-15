# Continue PSC0 / PSCV0 v7 M2 + Phase A

## Shared default instances prepared for qualification — 15 October 2026

The Array prerequisite passed [native38737651266](https://github.com/dwijayuda/pskernel/actions/runs/38737651266) at `3642e8835f36f238c88e4097914df55b199fd58e`: 851 shared observations and all required gates. It is integrated to main `e3902f3d91556af40b85f65566ff6787620346ee`, pending exact-main qualification. F2 is already exact-main qualified at `ef5c5e342015bfabcb58ae1f3291f0fe544cec5a` (native38736277605, F138736277937, F238736278026).

This coherent F3 prerequisite implements a separate priority-ordered default-instance registry, selected declaration `@[default_instance priority]` syntax, checked class-result registration, captured-scope resolution, transactional dependency solving, one-default-at-a-time quiescence scheduling, and public/private module propagation. Ordinary instance priority remains independent. Both imported registries preserve newest-first tie order and deduplicate import diamonds. Candidate preparation, type checking and tabled ordinary synthesis are reused; default search is bounded and resource exhaustion rolls back the whole worklist rather than selecting a lower-priority fallback.

Primary reference: pinned Lean 4.35.0 `Lean/Meta/Instances.lean` (DefaultInstances/addDefaultInstance) and `Lean/Elab/SyntheticMVars.lean` (synthesizeUsingDefaultPrio/synthesizePending/synthesizeUsingDefault). Tests studied: `tests/elab/defaultInstanceWithPrio.lean`, `defaultInstBacktrackIssue.lean`, and `tests/elab_fail/defaultInstance.lean`. The adapted algorithm's upstream Apache-2.0 authorship is recorded in Synthetic.lean. PSC0 retains its immutable scoped contexts and bounded tabled search rather than importing Lean elaborator state.

One source fixture and seven shared observations exercise priorities across goals, failed-candidate rollback, recursive defaults, tie order, surrounding type information, rigid default-only dictionaries and universe instantiation. Matching native Lean guards provide an independent semantic oracle. Compact checks additionally cover ordinary-search separation, resource rollback, imported ordering/diamond deduplication, private visibility and nonclass rejection. Existing whole-subsystem and backend gates remain required. Intended total: 858 shared observations.

The strict declaration snapshot format becomes v3 to include default registrations; the source-surface payload becomes v2 to include the actual selected attribute registry and defaults. Existing pins intentionally refuse until independent cloud measurement is reviewed. No new Standard declarations/defaults, assumptions, runtime operations or budgets. Scientific syntax and OfNat/OfScientific literal integration are still next, followed by F3 numeric conversions; existing delayed numeral fallback is not claimed to implement the new literal policy. F3's 134-declaration checked conversion candidate remains unselected. This default-instance implementation is prepared, not yet qualified; M2+A remains open.


## Array universe prerequisite: logical gate qualified, strict pins reviewed — 15 October 2026

At `ae8f17d4d264cdd9be02cbd466f9ffd94ed07b73`, [F3 logical replay38734094036](https://github.com/dwijayuda/pskernel/actions/runs/38734094036) passes: 42 roots, 134 declarations, one recursor rule, 3,286 shared nodes and 617,019 UTF-8 bytes; SHA-256 `45e6c8b81fbd971c891d173acef36c2ce6f6c59b674a06ffc9bfbe2e8cff6391`. No new assumptions, replaced definitions or quotient primitives. The candidate remains unselected. Independent [F1 replay38734094050](https://github.com/dwijayuda/pskernel/actions/runs/38734094050) and [F2 replay38734094025](https://github.com/dwijayuda/pskernel/actions/runs/38734094025) also pass.

[Native38734094047](https://github.com/dwijayuda/pskernel/actions/runs/38734094047) compiled the complete Array family and oracles, passed the strengthened signature audit, and regenerated the prior assets. Both strict checks independently refused the intentional registry change with FNV `14544844717468498892`, declaration SHA-256 `373b27a0b77083baa58810055d68b6639ec00c2038da7641d3dd5c042e8f4e0d`, and surface SHA-256 `579f461576427a5daf711943613979e4517803475779e40b0200f359450744fa`. These reviewed values are now pinned; no guard is relaxed. Full Array source/runtime qualification remains pending.

F2 [native38734252078](https://github.com/dwijayuda/pskernel/actions/runs/38734252078) is green at `9ffdd799a05ee256368266831bbaec74bee18ed2`, including 843 shared observations across JS, TS, Rust and GC Wasm/component. Incorporate its six constant-observation metadata corrections (`args: null`) while preserving the eight new Array observations. Finish F2 exact-main qualification separately.

Next F3 work: shared priority-ordered default instances and exact scientific syntax, followed by checked conversion selection and typed backend conversion lowering. Pinned Lean `Lean/Meta/Instances.lean` and `Lean/Elab/SyntheticMVars.lean` establish descending priorities, transactional candidate attempts, and return to ordinary synthesis after one successful default. Float's OfScientific priority 501 must precede Neg Int's 500; surrounding expected types take precedence. Do not hardcode a Float literal fallback. M2+A remains open.


## Array universe family prepared; F3 remains unselected — 15 October 2026

F3 [38731735348](https://github.com/dwijayuda/pskernel/actions/runs/38731735348) found 134 candidate declarations, no new assumptions, and one general dependency mismatch: PSC0's monomorphic Array versus Lean's universe-polymorphic Array. The native `ofScientific` fast-path tables and their proofs require the native family. The repair preserves the checked list-backed logical model and existing runtime layouts.

Studied pinned Lean 4.35.0 `Init/Prelude.lean` (Array, mk/toList, size, getInternal, push), `Init/Data/Array/Basic.lean` (map/foldl), and tests `compile/{array,arrayMk}.lean`, `elab/{arrayGetU,array_map_module}.lean`. Element universe u is propagated through Array and its complete selected operation family; recursor motive and map/fold result universes are independent. GetElem/GetElem?/LawfulGetElem, Inhabited, Hashable, Repr and ToFormat dictionaries carry the same universe parameters. ByteArray specializes to universe zero. Seven obsolete Type-0 signature exceptions are replaced by exact normalized native signature checks; the explicit fold-bound default policy remains separately recorded.

One shared fixture adds eight cross-universe runtime observations (map both ways, fold both ways, default, formatting, repr, hash), plus generic checked list/size identities. Existing Array, ByteArray, proof assets and all-backend suites remain required. Strict manifest pins are intentionally unchanged until the independent CI measurement is reviewed. No limits, logical assumptions, runtime layout, self-hosting or C5 changes.

This research branch also incorporates F2 shared constant/application erasure from `c3081a0e0c102ba8f8fad16940301af893dcfe5b`. Its independent [F1 replay38733051176](https://github.com/dwijayuda/pskernel/actions/runs/38733051176) and [F2 replay38733051136](https://github.com/dwijayuda/pskernel/actions/runs/38733051136) pass; [full native38733051228](https://github.com/dwijayuda/pskernel/actions/runs/38733051228) is still in progress. Finish F2 exact-main qualification before integrating this Array/F3 work. Current Array changes are prepared, not yet qualified; F3 scalar declarations and source syntax remain unselected.


## F3 logical dependency gate prepared — 15 October 2026

Research branch `psc0/pscv0-v7-f3-conversions-research` was based on F2 candidate `d70fe6c562d7643f9b42a13d72f718ae146b1d7c` and now incorporates its class-key audit and corrected metadata pins through `cbdb554fa9209361cd72217432fb8435d1a15022` while F2 full runtime qualification continues independently. This branch adds only native authoring/export and a read-only cloud replay workflow; it does not select any F3 declaration or enable new syntax/runtime operations.

Pinned Lean 4.35.0 sources studied: Init/Data/OfScientific{,/Basic}; Float/{Float,Float32}, Model/{Float,Float32}, Model/Unpacked/Operations/{OfNat,ToNat,OfScientific}; SInt/Float{,32}; Lean/Parser/Basic.decimalNumberFn and Lean/Elab/BuiltinTerm.elabScientificLit. Relevant tests: elab/float_conversions.lean, elab_fail/scientific.lean, pkg/ofScientific/{Main.lean,test-data/README.md,doubleround.txt}. Existing scalar-completion design remains the roadmap.

The coherent logical candidate has 42 roots: both widths' ofScientific/ofNat/ofInt and conversions to eight fixed signed/unsigned word types, and conversions from those words plus Nat/Int into both floats. It uses the current selected F2 declarations as its dependency cut, original native definitions/proofs, shared source serialization and official kernel replay. Platform words and opaque Float/Float32 cross-width conversions remain separate contracts. No new assumptions, theorem replacements, computational axioms or budgets.

Semantic design: scientific lexing retains an exact mantissa, signed decimal exponent and source span; expected type and the shared OfScientific synthetic constraint determine interpretation. Float's default priority is 501. Native fast paths require exactly representable operands; model fallback bounds extreme exponents before powers of ten and rounds once to the selected width. Numeric integer-to-float conversion uses nearest-even; float-to-fixed-integer truncates toward zero, clamps at bounds and maps NaN to zero. Never convert an arbitrary UInt64/Int64 to binary64 before rounding to binary32: that can double-round. Reuse the shared typed conversion boundary across backends, canonical NaN observation and existing ABI plan.

Next: inspect this gate's proof/closure result, assess any dependency-family mismatches, finish F2 exact main qualification, then implement F3 coherently. No F3 acceptance/runtime claim. Keep both handoffs current.

F3 first run38730356496 built the exporter but stopped on a missing CLI success return in the adjacent F2 branch. This return is restored; no logical candidate result was produced by that run.


## F2 instance-index invariant reviewed — 15 October 2026

Research `49a38a118b6ed2b0fa5955bac4b8d9399c4b6466` fixes the Float equality registration: DecidableEq is a reducible Pi alias, so its result-class key is Decidable. Pinned Lean Meta/Instances.{mkInstanceKey,checkNonClassInstance} and SynthInstance were studied. A shared Standard manifest audit now reduces every registered instance telescope and checks its explicit key against the actual registered result class, preventing this entire metadata failure family. The unchanged native logical asset still passes independent F2 replay [38730889909](https://github.com/dwijayuda/pskernel/actions/runs/38730889909), and F1 replay [38730889978](https://github.com/dwijayuda/pskernel/actions/runs/38730889978) passes.

[Native38730889997](https://github.com/dwijayuda/pskernel/actions/runs/38730889997) built successfully, passed the new class-key audit and all 88 native Float oracle observations, then independently reported the metadata-only digest change. Reviewed current pins: `fnv1a64:11971833863653521941`; declaration `sha256:8a3fbf1e59845739e6926b7e52add0059a33054cf74625f64923d4f360c43c7e`; surface `sha256:ff2b3e2ed6e043cb11a332d5175ff1116f8e4c1a4c13a91baca71bb53a917fc3`. Standard remains 3,122 declarations. The older pin checkpoint below is superseded. Full runtime/backend qualification is still required.

F3 dependency research proceeds separately at `cafabfdadf0453cb9e8e7355bb8a952bc39a644a`, [38730356496](https://github.com/dwijayuda/pskernel/actions/runs/38730356496), with 42 scientific/fixed-word conversion roots and no F3 selection. Its gate is based on F2's declaration roster; after F2 qualification synchronize metadata before F3 integration. Main F1 remains unchanged and qualified. No new assumptions, pskernel-core, self-hosting or C5.


## Working contract

GitHub canonical: dwijayuda/pskernel. Main development branch `psc0/pscv0-v7-native-lean-v1`; draft PR109 keeps its original base and must not be merged. Inspect live branch HEAD and exact-commit CI before writes; preserve history with expected-HEAD, non-force updates. Use GitHub integration and cloud Linux CI only, no local checkout/files/builds or Desktop Commander. Keep research workflows contents: read.

Pinned Lean 4.35.0: `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Study corresponding official source and tests before every substantial feature. Native .lean; no pskernel-core, bootstrap/self-hosting, compiler-source .ps migration or C5. Application .ps fixtures are allowed. Only approved assumptions propext and Quot.sound. Original upstream Float correspondence imports Classical.choice and remains outside the selected portable closure.

Read the latest AI_WORK_STATE.md checkpoint, docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md and docs/PSCV0_M2_A_SCALAR_COMPLETION_2026-10-14.md; canonical v7 specifications govern completion. Continue M2+A -> M3+B -> M4+C/D -> M5/E. M1 is complete; M2+A is not.

## Immediate continuation

1. Inspect live research HEAD and current native/F1/F2 workflow results. The former Wasm fallback became redundant after exhaustive F2 dispatch; it was removed. The primitive audit now includes Model methods and Eq decision helpers. Do not redo qualified F1.
2. Finish coherent F2 qualification after the exact registry pins above. Fix root causes without weakening checks. Integrate the reviewed tree to fresh main only after all required lanes pass, restore workflow main-branch triggers, then qualify the exact main commit. Update BOTH handoff files, roadmap and PR evidence.
3. Continue F3 scientific syntax/defaults and scalar conversions, F4 complete Float qualification, USize/ISize explicit target profiles and remaining authoritative selected Standard/manifest obligations. Study the whole affected subsystem first.
4. F3 research at cafabfdadf0453cb9e8e7355bb8a952bc39a644a (run38730356496) covers pinned Parser/Basic.decimalNumberFn, Elab/BuiltinTerm.elabScientificLit, Init/Data/OfScientific{,/Basic}, Float/Model/Unpacked/Operations/OfScientific and tests/pkg/ofScientific (including doubleround.txt). Keep exact Nat mantissa, exponent sign and Nat exponent until the expected type/OfScientific instance is selected. Default Float priority is 501. Reuse exact rounding and exponent bounds; do not parse via binary64 before choosing Float32. Only the isolated F3 logical exporter gate is staged; syntax/runtime remain pending.

## Verification and invariants

The F2 asset is selected behind frozen psSelfHostProdPreFloatOperationsPreludeEnvironment and psStandardFloatOperationsBoundary; proof dependencies stay out of runtime support. IEEE BEq identifies signed zeros and rejects NaN equality; logical DecidableEq compares canonical bits, distinguishes signed zero and identifies NaNs. All backends share typed IR; Wasm uses GC internally, with linear memory only at explicit Canonical ABI boundaries.

Use existing native build targets pscv0_native, pscv0_native_checks, pscv0_wasm_checks and pscv0_m1_performance. Follow current workflows for pinned commands/tools. Authoring must prepend the local Ps namespace root to Lake's LEAN_PATH. The awaited pooled-task helper resets the real C++ kernel heartbeat counter per independent authoring declaration; source requests keep cumulative 2,000,000-heartbeat/20,000-depth limits.

No new assumptions, proof placeholders, unchecked casts, fallback admission or increased budgets. Keep checked logical admission, runtime conformance and formal preservation claims separate. Prefer complete coherent features and compact differential validation, then the existing full backend suite. Update both handoffs each milestone slice.
