# PSC1 AI work state

Updated 2026-10-29 Asia/Jakarta. Active M5 branch
feat/psc1-portable-modules-20261029 from verified PR #208 HEAD
d53b43c271c65635b07a6ffa78fb6b08a5fa55de.
Initial production modularity implementation PR #205,
stacked on plan PR #204 / b400552324956d9c3a684c9231f60f70066e1629.
GitHub/Linux CI only; expected-HEAD, single-parent/non-force history.
No merge or registry publication.

## Active M5: portable generation qualified; G2/G3 retry running

PR #209 continues from PR #208/d53b43c271c65635b07a6ffa78fb6b08a5fa55de.
Canonical portable module generation reuses the same frontend, actual tagged
member ownership, strict original/transformed IR, specialization/worker provenance,
bounded planner and structured JS/TS renderers. No second handwritten compiler.

Qualified implementation source:17ce19919175b60be06050188e2a546a8a72e689;
same133-module closure at tested controller head77961851d54adb344a87fb32b4472c11b2024519:
1f2f1e4a035a32faa6035aeae000e9c92305f8fb34e58b8cc2210504e38213cb.
Native G0 admits4905 logical declarations; IR counts3252/4289/4944.
All134 units/15 owners match immutable pre-M5 renderer bytes. Strict TS,
graph inspection and nine integrity-negative classes pass. Graph1131 files/
103951941 bytes, within the unchanged128MiB bound. Readable TS and accurate
in-package source maps remain; duplicate sourcesContent is removed.

Portable G1 passes40748275409 at17ce1991 and40749484426 at77961851:
native generation112798ms/maxRSS1210604KiB (repeat123453ms/1207588KiB),
official admission3047ms (repeat3296ms), exact admissions/original/transformed IR,
ownership/module metadata and every rendered file. Raw JSON rows avoid duplicate
escaping while requiring all six native JSON byte round trips and fixed
filename/format/suffix validation. The initial efdb1385/40746744949 wire-size
failure is preserved; no byte limit was raised. Candidate npm version
0.1.0-psc1-modular.2 is not a promoted root umbrella.
G1 seed artifact12842054234 from40748275409:51913188 bytes, ZIP SHA256
8d98483df656c5d490e2648c2f00da04a6b13f00a60f93bb7c3acfa8e2b6e834;
manifest74e14f5650931ccc3de2a4a7ed6829f54197bb8100466bcb2eb0ad90d7b14a85.

Full source40749527957 passes all16 selected jobs at77961851
(tested merge3c78e1c16e184948821550cff8fc3b13609e86f3):37/37 finite
Practical Core criteria, zero blockers,14 scoped target bundles; benchmark skipped.
Existing npm distribution40749527892 passes separately for the preserved.13 cohort.
Ownership/policy audit40755976488 at707bd403 passes11 cases, retaining all
historical M1/M2 extraction tests at immutable M4 and exact current normalization
source identities. Wire tests pass11 malformed/authority/path refusals plus
unsafe-number refusals. These finite checks are not semantic preservation proofs.

Initial real G2 run40749484847 fails before generation completes:
TS1565790ms/maxRSS3130492KiB/1800.61 sampled CPU seconds;
JS1557142ms/maxRSS3265200KiB/1804.32 CPU seconds. Both hit an introduced
CPU=wall cap before the canonical1800s wall deadline. The shared resource module
defines wall-clock profiles. Diagnostic correction restores that Node policy;
native guards are unchanged. No G2/G3 or fixed-point qualification is claimed.

The user explicitly authorizes a sensible increase. Diagnostic controller
336ab495df5479a959a071166b7c2c6b24823b26 runs40755246954 on
diagnostic/psc1-modular-cpu-20261029: existing correctness-3600s only for
G2-self/G3-self,160-minute Linux jobs for both generations, official admission,
corpus execution and exact graph/npm tarball comparisons. It emits45s numeric
RSS/CPU heartbeats and per-generation producer identities. Preserve both
correctness-1800s and performance-240s as separate profiles. GitHub hosted
jobs permit6h: https://docs.github.com/en/actions/reference/limits.
The retry is running, not qualified. Audited controller bytes are now adopted
into PR #209; compiler source is unchanged. The workflow uses an explicit
.github/psc1/modular-selfhost-run.json push marker or manual dispatch, so adopting
already-running request/configuration receipts does not repeat expensive jobs.
Execution steps/limits are identical to336ab495; only the event path changes.

CPU diagnostics40754131717 at a206c7ee sample this exact graph and full self-source
request for240s on both engines; they are explicitly not G2 qualification.
Bounded string comparison, substitution, environment lookup and generator
dispatch are visible; no single dominant first-four-minute defect is established.
V8 logs, measured failures and source/request identities are retained.

G1/corpus/tools240s, checker120s,4096MiB V8 heap/8MiB stack, native4GiB AS,
semantic fuel,32MiB files/streams,128MiB graph/stage/wire,8192 values/files,
257 units,4096 reference depth and131072 initializer edges remain unchanged.
Official Lean4.35.0/eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
ordinary-checked logical/runtime pairing, negatives and unsupported-ABI refusals
remain. Native reference bundles are corpus oracles outside executable graphs;
G2/G3 remove native compiler executables and retain only the independent checker.
M4 umbrella/.13, frozen Rust/Wasm, optional Python/PHP and history are preserved.
No merge or registry publication.

[Exact partial receipt](docs/PSC1_PORTABLE_MODULAR_QUALIFICATION_2026-10-29.json)
and [portable architecture](docs/architecture/portable-modular-generation.md).

The retained.11 reference CLI run40749484645 hits its60-minute aggregate job
deadline during checked publication/Unicode IO cases, after successful prior
stages and without a test assertion failure. Preserve cancelled job123032520132
and artifact12847147334 (206767038 bytes; SHA256
9355312865447134f22fb7e5ec9995ff97d63b03b05d253ff898dc2810f74e2a).
The installed job budget is now90 minutes; all commands, ordinary240s requests,
kernel checks, runtime matrix and required final receipts remain unchanged.
A fresh run must pass; cancellation is not qualification. This is the preserved
reference CLI scope, separate from the new M5 graph and unchanged M4 preview.

## M4 milestone: qualified installed modular Linux preview

Final full-source checkpoint `821292dfd7dac39a1281a1b51b8e5ec17af63346`
passes [40728439938](https://github.com/dwijayuda/pskernel/actions/runs/40728439938):
all 16 selected jobs, 37/37 finite Core criteria, zero blocked and 14 scoped target
bundles; benchmark intentionally skipped. Tested merge:
`ec0dda44f2ec2d77dc0f073965e9dc4fae4293e3`.
[Evidence gate 40728430896](https://github.com/dwijayuda/pskernel/actions/runs/40728430896)
also passes, verifying exact adopted test-controller bytes, unchanged qualified
production source and successful job/artifact identities. The following receipt
update changes only documentation/evidence, not the tested tarball or compiler.

PR #208 implementation `ca92bbdbc7c0f34e1da4076db7300033802eab3e` passes
[installed qualification 40714983520](https://github.com/dwijayuda/pskernel/actions/runs/40714983520).
Version `0.1.0-psc1-modular.1` bundles all 20 core packages, including the unchanged
official Lean 4.35.0 linear-memory Wasm kernel. The original 127 source-owned units
in 15 executable owners contain the genuine generated JS/TS compiler bodies.
There is no hidden frozen whole-compiler fallback. The three-line psc launcher
delegates to @proofscript/cli; existing project/watch bodies are relocated with
reversible import/label rewrites. Root subpaths avoid assuming npm hoisting.

Node 22.23.3 and Bun 1.4.4 pass 16 smoke builds/28 actual kernel cases, then
128 public-value/component builds and 20 source/assurance refusals across both
compiler engines and seven targets. Both hosts recheck the exact native-qualified
compiler admission using the real default Wasm kernel and pass fresh global
root-only check/build. Eighteen retained watch cases pass; the reference CLI keeps
its original native guardian/cancellation tests unchanged.

[Boundary/IO/types 40722004088](https://github.com/dwijayuda/pskernel/actions/runs/40722004088)
passes on the exact unchanged root tarball: 46 resource/metadata/installed-consumer
refusals, 16 Unicode callback/trap IO builds, eight unsupported Wasm-core dispatcher
refusals, strict NodeNext/Bundler consumers on both hosts and two extra TS-engine
live watch cases. TS-watch shutdown is 101/102 ms. Checked API phase refusals and
exact candidate diagnostics are tested separately without granting candidate authority.

[Installed applications 40725714755](https://github.com/dwijayuda/pskernel/actions/runs/40725714755)
passes 32 independently checked builds and 528 retained behavior cases: both engines,
both grammars, JS/strict TS outputs, four 11-module CLI/JSON/file/compiler-like apps.
Native reference admission, serialized original/specialized IR and decoded source
identities match. Actual app runners import installed proofscript/io with reversible
rewrites and identical runtime bytes. The 100,000-statement cases take Node
6,250–11,765 ms / maximum 168,740 KiB RSS; Bun 1,605–2,865 ms / 110,356 KiB.
These are concurrent CI observations, not universal performance claims.

[Source 40719527295](https://github.com/dwijayuda/pskernel/actions/runs/40719527295)
passes all 16 selected jobs at the same implementation (tested merge
`1f8415f790387a0702d1760896a2998f0c05a4c1`): 37/37 finite Practical Core criteria,
zero blocked, 14 scoped target bundles; benchmark intentionally skipped.
[Retained CLI 40714983602](https://github.com/dwijayuda/pskernel/actions/runs/40714983602)
passes all nine jobs. Its .11 frozen compatibility cohort is separate from both
the new modular preview and the separately qualified .13 default reference.

[Installable ZIP](https://github.com/dwijayuda/pskernel/actions/runs/40723525652/artifacts/12832176204)
contains the exact tested root tarball, INSTALL, checksums, notices and focused
receipts. GitHub wraps the inner installable ZIP and delivery.json. Extract both
ZIP layers. Root tarball SHA256:
`7773a7a2abcebaf1fd77df836b2c687e013001c23885bb0bb584e6fe8d012507`.
The ZIP's focused receipt predates the additional source/application evidence;
the [complete repository receipt](docs/PSC1_MODULAR_INSTALLED_QUALIFICATION_2026-10-28.json)
records all runs, commits, artifacts, source identities, measurements and attempts.

Installed graph: 1,423 files / 124,338,997 bytes, within the unchanged 128 MiB bound;
32 MiB/file, 8,192 files and existing path/unit bounds remain. Original graph
ownership/admission/IR/files are bound by exact projection; only package metadata
is versioned. The one bounded bootstrap seal is retained in common per-request
pins. Trusted bootstrap/stable-resource assumptions remain; this is not a signature,
sandbox, totality or semantic preservation proof. Official independent admission,
strict original/transformed IR, 240-second compiler/tool and 120-second checker,
memory/stack/fuel, negatives and ABI refusals are preserved.

Python/PHP are optional preview provider leaves. Runtime/tool payloads remain
byte-identical; obsolete checked compiler facades/dependencies are removed and
all prior file pins are verified before resealing archive metadata. Rust/Wasm
remain output backends. Older compiled compiler executors explicitly refuse this
new source cohort and stay qualified/usable with .13. Standalone checked-host
installation and other-platform durability remain unqualified.

CI-only boundary/delivery/application controllers are adopted byte-identically
from the successful diagnostic branch; no canonical compiler/host/package payload
changes accompany this evidence checkpoint. Historical host cleanup/layout/AST
guards remain. No merge, npm publication or .13 replacement.

**Next: M5 portable module planning/emission in the same compiler, deterministic
complete graph/package reproduction, then genuine new modular JS/TS G1/G2/G3 and
fixed points.** Current M4 is a finite Linux preview milestone, not that self-hosted
release. Component String/IO, actual non-JS host-IO applications, platform consumers
and the user-arranged independent maintainer trial remain explicit separate work.
[Architecture](docs/architecture/installed-modular-toolchain.md).

## M3 semantic/backend milestone: qualified focused matrices

PR #207 continues from PR #206 / `7da52af9c21e5676e50ed06199ee614b9c69d03c`.
Implementation/test-controller commit `308f2fd988428d30be7c5fd9cfe0c8ace9242447`
passes [Linux 40695323668](https://github.com/dwijayuda/pskernel/actions/runs/40695323668):
**448 checked builds, 552 refusals and 6,944 published function calls**, including
6,048 individual authored case/flag observations over 54 existing case IDs.
Both complete modular JS/TS engines compile all eight retained semantic families,
both .lean/.ps grammars, and all seven checked targets on Node 22.23.3/Bun 1.4.4.

Actual checked output is published and executed: JS, strict TS, Rust rlibs,
Wasm-core transport, Wasmtime-executed components and optional Python/PHP.
The public component ABI remains Bool; unsupported Nat exports refuse. Missing
SDKs/providers, unsupported assurance and every retained source negative refuse
while preserving the prior portable generation.

Native preparation reuses existing conformance commands/oracles and sealed
pre-admission snapshots. Only captured library sources are checked-converted to
PS; authored PS fixture bodies remain intact. All 16 homogeneous fixtures and
64 native target references independently check, preserving the original native
admission bytes. Before modular execution, all native frontends and frozen
reference compiler executors are moved aside. The retained .11 archive supplies
only pinned SDKs/providers. Compiler source and generated graph identities do not
change, and no alternate handwritten frontend is introduced.

Additional public-value [Linux 40700728090](https://github.com/dwijayuda/pskernel/actions/runs/40700728090)
passes at CI-only `85f61b4b41546070f5605df884f0c63bfc1a9306`, with the exact
compiler/controllers from `308f2fd9`: **120 builds and 20 refusals**, both engines,
Node/Bun, JS/TS/Rust/Wasm-core/Python/PHP. Actual Nat, large negative Int, Unicode
String, list-result, handler and ordinary-loop observations match. That isolated
branch prevented cancelling the long regressions; its two test/workflow files are
adopted byte-identically in this evidence checkpoint.

[Semantic receipt](docs/PSC1_MODULAR_SEMANTIC_QUALIFICATION_2026-10-28.json) records
exact jobs, artifact digests, per-batch counts, canonical identities, resource
policies and remaining work. [Execution walkthrough](docs/architecture/modular-checked-execution.md)
links the real reference/preparation, resource, checking, publication and consumer
paths. Candidate comparisons normalize parsed JSON; admission/decoded source bytes
and serialized IR match. This is finite behavior evidence, not a preservation or
totality proof.

Measured semantic compiler-child time includes graph verification/import:
Node 1,685–178,608 ms; Bun 2,083–17,614 ms across 224 requests per host.
Public-value compiler children take Node 1,155–3,153 ms and Bun 698–2,223 ms.
These are concurrent CI workload observations, not a universal speed comparison.
All existing 240-second compiler/tool and 120-second checker limits remain.
Compiled Rust rlib digests vary between execution directories; generated source,
admission, IR and behavior match. Native artifact reproduction remains unqualified.

Attempts remain in history: `754d97b1` /40693502551 lacked historical Git objects
for the unchanged layout guard; full checkout fixes it. `c122a46c` /40693811688
passes native preparation but reads the wrong archive hash field for SDK/provider
receipts. `308f2fd9` uses their existing tarballSha256 fields while retaining exact
archive verification. No compiler, checker, IR or resource policy was relaxed.

Retained source [40698796765](https://github.com/dwijayuda/pskernel/actions/runs/40698796765)
passes all 16 selected jobs (benchmark intentionally skipped) at branch
`308f2fd988428d30be7c5fd9cfe0c8ace9242447`, tested merge
`5a48846d97cbeb30c5167ed22d2c9529873d4035`: 37/37 Practical Core criteria, zero blockers
and 14 scoped seven-target execution bundles. Retained installed CLI/runtime
[40695323349](https://github.com/dwijayuda/pskernel/actions/runs/40695323349) passes
all nine jobs at the same branch commit, including watch, actual IO applications,
32 publications/143 refusals and supported/older runtime boundaries. Its frozen
.11 test cohort remains separate from the modular graph and the qualified .13
umbrella reference. These are passing terminal results, not pending claims.

The .13 default, official linear-memory C++/Emscripten Wasm kernel, qualified
Rust/Wasm executors, optional Python/PHP, deferred pilot and all prior evidence
remain preserved. The later M4 milestone above qualifies checked umbrella/thin CLI/watch
integration in its finite Linux scope. Actual non-JS host-IO applications and M5
portable module reproduction/new modular G1/G2/G3/fixed points remain incomplete. No merge or registry publication.

## M3 application milestone: qualified checked modular execution

Linux [40679842606](https://github.com/dwijayuda/pskernel/actions/runs/40679842606)
passes both Node 22.23.3 and Bun 1.4.4 lanes at
`f433bad08a5b53992030d4f6ad043bfd0839d68f`. Both complete generated JS/TS engines
compile four retained 11-module applications, covering .lean/.ps and JS/strict TS
output: **32 checked application builds, 528 behavior executions and 20 boundary
negatives**. Native compiler executables are removed before modular execution.
Normalized candidate JSON, canonical admission, serialized original/specialized IR
and decoded target-source identities match the independently checked native references.

The unchanged CLI/JSON/file and compiler-like contracts include Unicode, invalid
input, permission/capability denials, prior-file preservation and 100,000 statements.
Typing refusals and changed graph resources preserve the prior portable generation.
Oversized files refuse before reading; unexpected directories, wrong manifests,
unsupported engines, reserved tool overrides and adapters inside the graph refuse.
A real-loader preflight runs before build/download on both host runtimes.

[Qualification receipt](docs/PSC1_MODULAR_CHECKED_APPLICATION_QUALIFICATION_2026-10-28.json)
records exact source/artifact identities, results and measured process timings.
[Execution walkthrough](docs/architecture/modular-checked-execution.md) links the
loader, session, checker, target consumers and publication path. The adapter reuses
the existing checked host and compiler; it does not duplicate frontend semantics,
grant authority to candidate data or claim a preservation proof.

Input graph artifact 12805544463 from run 40666692730 / job 122743152998, ZIP SHA256
`01eb8af4d455e41c919ad523355aa1e238485fe84fa7f2ea70ea3891ae366e38`,
is pinned in scripts/modular-checked-input.json. Source closure remains
`41eb40437e0df1722128c09c9b9da7cad0ccb1ad61371f23eb6bc2db4e9a1106`.
Application evidence: Node artifact 12812871458
(`88252afc343ffc964c115f6e2bcdc4d529223c6f83e6290ad7724deafef19c92`);
Bun artifact 12811649188
(`d49283a090e1883b20fc58757219a73bff69d7972393b7ebfab6d4c2ea2840d5`).

Measured compiler-child time, including import/hash verification and compilation:
Node 9,646–17,367 ms; Bun 8,891–17,538 ms across 16 application builds per runtime.
Generated 100,000-statement application execution is measured separately: Node
4,015–7,703 ms / maximum 170,248 KiB RSS; Bun 2,517–4,518 ms / maximum 107,372 KiB RSS.
These are one CI workload's observations, not a general performance claim.

## Retained regression and development-process evidence

Source [40681840579](https://github.com/dwijayuda/pskernel/actions/runs/40681840579)
passes all 16 selected jobs (benchmark intentionally skipped) at branch
`05ae5cb47c677357a2eb9e82b0987f1280efffb9`, tested merge
`e81c3468d68c55719b92198daee658b4972d8d7c`: 37/37 Practical Core criteria, zero blockers,
and scoped seven-backend execution with 14 target bundles. This retained
native/source/G1 evidence is distinct from the new modular-engine application lane.

Installed CLI/runtime [40679842769](https://github.com/dwijayuda/pskernel/actions/runs/40679842769)
passes all nine jobs at `f433bad0`, including watch, publication and runtime
acceptance/refusals. This workflow uses its retained .11 test cohort and frozen
compiler closure `073e5156...`; it does not promote the modular candidate.
The separate .13 npm umbrella reference remains qualified by 40666699859 at
PR #205 HEAD `4393ed15` with all 53 cases passing.

CI-only commit `05ae5cb47c677357a2eb9e82b0987f1280efffb9` replaces 11
unconditional installer sites across eight active workflows with the shared
.github/actions/psc1-lean-launcher action. It respects the existing exact toolchain
cache, bounds downloads/retries and avoids fetching an unrelated default Lean.
The observed old setup spent 572 seconds before cancellation; cached shared setup
takes 0–1 seconds in the measured lanes. All test commands, official Lean 4.35.0,
compiler/checker limits and semantic/memory/stack/fuel policies remain unchanged.

Diagnosed attempts are preserved in the receipt: the development harness moved
from production host code into scripts/ after the repository guard refused it;
a documentation link was corrected without relaxing that guard; a mistakenly
removed filesystem import was restored and covered by the new fast preflight.
The first application qualification, 40677391651 at `8dac01c7`, also passed all
528 cases before the four additional boundary cases were added per runtime.

The retained M3 application/semantic/seven-target scopes are now qualified above.
M4 checked umbrella/thin CLI/watch and default independent Wasm-kernel use are now
qualified in the preview scope above; release promotion remains pending. M5 modular generation/fixed
points and compiled native artifact reproduction are unqualified.
Qualified .13, default linear-memory C++/Emscripten kernel, existing Rust/Wasm
executors, optional Python/PHP and deferred pilot remain preserved.

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

1. M4 finite Linux installed preview is qualified above. Preserve exact .13 and
   earlier source/graph/kernel qualifications; do not inherit their self-host receipts.
2. M5 portable planning/emission and independently checked G1 now pass above.
   Preserve the exact source and G1 artifact while the one-hour requests execute.
3. Inspect40755246954; require independently admitted JS/TS G2/G3 and exact
   complete graph/npm bytes. If it fails, use actual phase/profile evidence for
   a targeted fix, not a relaxed checker/IR/resource criterion.
4. Follow the roadmap for component String/IO, actual non-JS IO apps, optional
   executors, platform consumers and authorized final promotion.

Pilot expansion and stopped PR #203 remain deferred. The M4 preview does not
replace .13, qualify standalone checked-host installation or claim a self-hosted release.

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

Historical M1/M2 CI selection gave the then-unintegrated production builder its own complete
qualification workflow, alongside the retained pilot exclusion; shared host files
and CLI changes still run the installed-CLI gate. Remove the candidate-builder
exclusion during M4 integration; M4 now imports executable helpers and the reference
CLI workflow watches those dependencies. Successful native compilation is cached before
candidate execution so test failures do not force identical rebuilds. The workflow
edit also reruns the existing CLI at the corrected documentation HEAD.
