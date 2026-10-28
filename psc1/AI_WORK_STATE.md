# PSC1 AI work state

Updated 2026-10-28 Asia/Jakarta. Active continuation branch
feat/psc1-modular-checked-host-20261028 from verified PR #205 HEAD4393ed15.
 Production modularity implementation PR #205,
stacked on plan PR #204 / b400552324956d9c3a684c9231f60f70066e1629.
GitHub/Linux CI only; expected-HEAD, single-parent/non-force history.
No merge or registry publication.

## M3: checked real applications through complete modular engines

[PR #206](https://github.com/dwijayuda/pskernel/pull/206) continues from verified
PR #205 HEAD4393ed1551aef8b6e5799b3a611cf084739618d8. Final #205 production40666692730,
npm40666699859, installed CLI40666692776 and source40666699904 all pass.
Source attempt2 retried two installer-only timeouts; full source37/37, zero blocked.

Linux [40677391651](https://github.com/dwijayuda/pskernel/actions/runs/40677391651)
passes both Node22.23.3 and Bun1.4.4 lanes at8dac01c767ccd09959dbb7fde56b92f1fd7727e5.
Each runs both complete generated engines, both source grammars and JS/strict TS
outputs:16 independently checked sessions and264 retained behavior cases per runtime,
528 total. Native compiler executables are removed before modular execution.
Exact candidate/admission/original+specialized IR/source hashes match the native
references. Real CLI/JSON/files and100000-statement compiler-like workloads execute.
Typing refusals and graph changes preserve prior portable generations. Oversized
files refuse before reading; extra directories refuse. Six negatives pass per lane.

The host loader verifies the complete pinned graph before import and around each
request. Its adapter pins all graph/helper resources and delegates independent
official Lean admission, target checks and publication to the existing checked
session. No frontend or verification pipeline is duplicated.
[Execution walkthrough](docs/architecture/modular-checked-execution.md).

Input graph artifact12805544463 / ZIP SHA256
01eb8af4d455e41c919ad523355aa1e238485fe84fa7f2ea70ea3891ae366e38
from production40666692730 / job122743152998 is pinned in
scripts/modular-checked-input.json. It retains source closure41eb4043... and all
prior M1/M2 evidence. Application evidence artifacts: Node12811652107
(46ec26db406be86b808b4aea6c5b62dd8cb5bb827fdd7d422646087196f0f5f4),
Bun12811318450 (74d655faa84c105c5e211944e07f09bd3e9a3057a3b7cab90e6edd17fed73baf).

Follow-up in this commit adopts CI-generated readable formatting, records process
timings and adds four direct loader/session boundary cases; terminal requalification
of those additions is pending. The development harness lives under scripts/,
following the repository guard; its first misplaced-host attempt40677096400 failed
before compiler execution and was corrected without changing that guard.

Remaining M3: complete retained semantic/library and seven-backend corpus, including
genuine Wasm/component and optional-provider execution/refusals. M4 checked umbrella,
thin CLI/watch and default independent Wasm-kernel integration remain unpromoted.
M5 modular generation/fixed points remain unqualified. Default .13, existing budgets
and deferred pilot are preserved. No merge or registry publication.

## Verified milestone: complete source-owned JS/TS compiler candidates

Production run [40664681150](https://github.com/dwijayuda/pskernel/actions/runs/40664681150)
passes at60a0d5cbaa0644215ee21d508d25730b61f2a32c. Exact evidence and tarball hashes:
[qualification receipt](docs/PSC1_EXECUTABLE_PACKAGES_QUALIFICATION_2026-10-28.json).
[Build walkthrough](docs/architecture/executable-package-build.md),
[production plan](docs/architecture/executable-package-modularity.md) and
[machine-readable contract](EXECUTABLE_PACKAGE_CONTRACT.json) describe the boundary.

Implemented and tested:
- Move unchanged Error/failure below orchestration; keep logical names and legacy
  single-backend entry points. Four pure Emit modules contain exact original bodies.
- Extract existing structured module model/printers and actual source-owner
  collection. Ten body/source/profile cases pass; the deferred pilot's policies
  and tests are unchanged, not expanded.
- Capture the complete126-module compiler through the existing elaborator once.
  Reuse established ordinary-checked preparation with exact logical/runtime body
  binding; explicitly record five partial declarations. This is not a totality claim.
- Independently admit4781 logical declarations with official Lean4.35.0
  eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Strict original/specialized/fused IR remains.
- Emit127 real source-owned units across15 existing package names:3150 original,
  3946 specialized and4516 fused values. Every surviving value is owned once.
  One foundation runtime/nominal registry per JS/TS variant; actual import-derived
  dependencies are acyclic. No hidden whole-compiler bundle in candidate packages.
- Order356 computed initializers conservatively through actual function/closure
  references. Eight planner/negative cases pass, including transitive cycles.
- All15 strict TS7.0.2 package checks pass. Nine graph-integrity negatives and
  direct wrong-cohort refusals for both variants pass.
- Both complete modular engines produce26 byte-identical reference responses:
  16 independently admitted positives and10 typing/optional/unknown refusals.
  Both .lean/.ps two-module applications emit JS/TS/Rust that execute42n.
  Wasm bytes validate; this fixture does not claim Wasm runtime execution.
- Fifteen tarballs install offline, preserve exact1075 candidate file bytes and
  execute both compiler variants through ordinary declared npm subpaths.
  This is multi-package installation, not root-only proofscript/psc promotion.

Source closure41eb40437e0df1722128c09c9b9da7cad0ccb1ad61371f23eb6bc2db4e9a1106.
Canonical admission97041042ece09003a253c1f4a038921ff89517a702a96da48bb631de930d1107.
Original IR95dcabab3915a70ce1d1755befecbe3fb448629dcf7203ad3a4a6e63f67861a6.
Fused IR4e973b29d13220693174b7761a6df8bb848c5a2b5414c5d658d492ceba31ba82.
Tested manifestff22aec6d4bcd859704e43081311111f9845f5b7d9d232f977736d71d5e29455.
Candidate1075files/119711529bytes. Capture61474ms/414856KiB child maxRSS;
emission11203ms/364600KiB. Earlier same-source run measured39390ms and7078ms.
Record actual workload measurements, not a claimed universal speedup.

Artifact12805277518 is46722396bytes, SHA256
5323f126410a125d46c32191263cfd65752ebbd2481fbf2f245f18c96e947e27.
It includes candidate tarballs and evidence, not a newly promoted end-user toolchain.

## Preserved regression/reference evidence

At PR head5fa6c4fba129a3b5784ee4aa03a24a8d2f88fddd, source run40661106294
passes16 jobs (benchmark intentionally skipped),37/37 Practical Core criteria,
zero blocked, scoped seven-backend execution/14 target bundles, retained pilot,
source tracing, selected compiler closures and generated-JS G1 cases.
Its tested synthetic merge is a56ed6c37bbba77113c2664551c1150bad212302.
Existing npm run40661106285 passes53 cases for .13 at that same tested merge.
These retained native/bundled checks are distinct from the new modular-engine corpus.

The qualified .13 distribution, proofscript umbrella, psc launcher, independent
default linear-memory official C++/Emscripten Wasm kernel, optional Python/PHP and
qualified Rust/Wasm execution bundles remain reference implementations.
Frozen G3 closure073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9
retains only its original122-module/4742-member evidence. Do not inherit it here.
Apache-2.0 and upstream notices, semantic fuel,240s ordinary compiler/tool requests,
120s checking, memory/stack policies, strict IR and negative tests remain.

## Dependency-ordered continuation

1. Finish M3: run the retained CLI/JSON/library/compiler-like and seven-backend
   corpora through these modular JS/TS engines; add supported Bun and genuine Wasm
   execution/adapters. Current finite examples do not replace that corpus.
2. M4: version the direct low-level API transition and integrate verified graph
   loading/coherent transactional publication with checked @proofscript/compiler,
   thin @proofscript/cli, root-only local/global proofscript install and watch.
   Python/PHP remain optional. Do not silently turn checked APIs into emitters.
3. M5 prerequisite: make module planning/emission a portable operation in the same
   canonical compiler source. Current native build adapter cannot by itself supply
   genuine generated-compiler module reproduction.
4. Reproduce and qualify complete modular G1/G2/G3/fixed points with new identities;
   then applicable platform/publication gates. Do not promote .13 replacement,
   merge, publish npm packages or claim modular self-hosting before those gates.

Experimental pilot expansion and stopped prototype PR #203 remain deferred.
This candidate milestone implements M1/M2 and part of M3, not completion of M4/M5.

## Diagnosed attempts preserved

- f54e051c /40657227476: extracted emitter headers omitted import keywords.
- 7886848d /40657626081: Wasm relied on transitive Foundation.Text; explicit import.
- 5609c2c7 /40658044896: regression test needed explicit legacy service imports.
- ec4218b5 /40658954932 and a8e22de3 /40659282400: boundary passes.
- df3ef061 /40659592035 and b3f7af9c /40660373734: new host-tool Lean reserved
  identifiers/record layout corrected; planner then passes.
- 5fa6c4fb /40661038464: missing existing locked host-tools dependency; provision it.
- 7616e75d /40661568068: total-only checked profile refused compiler partials;
  restore existing ordinary-checked source profile and retain exact body pairing.
- bf1a0940 /40662258347: complete graph/type/integrity checks pass; Rust consumer
  lacked num_bigint. Reuse pinned1.90.0 locked target SDK/rlibs and execute output.
- cafe8c7a /40663294930: cancelled during stalled Elan installer download, before
  compiler checks. Separate bounded setup steps/npm caching; no correctness waiver.
- 60a0d5cb /40664681150: complete focused workflow succeeds.

## Branch/checkpoint procedure

Implementation was staged on build/psc1-executable-packages-20261028 to avoid
restarting the PR's complete matrix on every build fix. Bring qualified changes
to feat/psc1-executable-packages-20261028 with a live expected-HEAD non-force
fast-forward; preserve any concurrent changes rather than overwrite them.
This receipt/work-state commit follows the tested implementation and changes
documentation/status only. Query the exact PR HEAD's CI before any later promotion.

Final documentation run40665911767 at8ac2aa72 refuses the new walkthrough's relative
link outside psc1/. Replace it with the exact qualified GitHub workflow URL; retain
the layout guard unchanged. No compiler/package implementation bytes change.

CI selection now gives the not-yet-integrated production builder its own complete
qualification workflow, alongside the retained pilot exclusion; shared host files
and CLI changes still run the installed-CLI gate. Remove the candidate-builder
exclusion during M4 integration. Successful native compilation is cached before
candidate execution so test failures do not force identical rebuilds. The workflow
edit also reruns the existing CLI at the corrected documentation HEAD.
