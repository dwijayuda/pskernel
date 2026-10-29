# PSC1 development roadmap

Updated 2026-10-29 Asia/Jakarta. This is the authoritative remaining-work queue.
Practical Core v1 remains frozen at14 feature families and 37 finite criteria.
Completed detail is preserved in [the previous roadmap](history/ROADMAP_BEFORE_LAYOUT_2026-10-26.md)
and [dated evidence](evidence/README.md).

## Active real-application compiler profile

Active branch `feat/psc1-semantic-incremental-20261029`, from PR #214 source
adoption `c83039f05a445f496f71aea2429ba75c61b81f40`. The qualified .6 package
and [delivery40863008602](https://github.com/dwijayuda/pskernel/actions/runs/40863008602)
remain unchanged. [Read-only evidence40863787611](https://github.com/dwijayuda/pskernel/actions/runs/40863787611)
recovers the same-runner comparison without recompilation: .5/.6 warm check
2441/1086ms, warm JS build3439/1564ms, real CLI/JSON application19186/14292ms.
Both installed packages execute the11-module,50478-byte application correctly
after all three leaf edits. Artifact12892806521 contains the verified ZIP.
Root SHA-256 remains23ab4f5b3eba1744b54ce3c9bc66a69edc6504b0a5568129eb99b70aa381a2f2.

Further read-only phase evidence40864571265 shows that the real application's
new compiler phase still takes12.5–12.6s, while independent admission takes
178–184ms. The next step is instrumentation separating capture/elaboration,
semantic preparation, strict original IR validation and backend emission before
choosing an optimization. The .7 proposal is experimental host instrumentation,
not qualified release or changed compiler semantics. Do not claim its package
qualified until actual tests and source adoption pass.


## Persistent development sessions — qualified source milestone

Active branch `feat/psc1-persistent-development-20261029`, from PR #213 HEAD
`b1d8d55cb664f1ab4b3d30973c10fbf950674c7d`.
[Integrated qualification40860864442](https://github.com/dwijayuda/pskernel/actions/runs/40860864442)
passes at `41d4b5db9fc51b7d117c261cd51e9bad05a76d0a`. Adopt exactly its15
formatted source pins, recorded in [the receipt](PSC1_PERSISTENT_QUALIFICATION_2026-10-29.json).
Compiler source/1131 original graph files, official kernel artifacts, Lean4.35.0
and original JS/TS G1/G2/G3 fixed-point evidence remain unchanged.

Implemented and tested:
- synchronous setup-only read/hash coalescing; fresh mutable-resource checks at
  all existing execution/publication boundaries;
- a narrow Linux ext4/XFS optimization for the executing binary: hash the loaded
  image, freshly bind its inode/path and require ETXTBSY on each use; any unknown
  filesystem, permission ambiguity, replacement or unsupported host uses fresh
  hashing. This is not an mtime cache;
- a bounded private independent-kernel worker. Reuse exact official compiled
  Wasm code and launcher script, but create fresh VM context, Wasm instance,
  linear memory and logical checking state for every request. Keep120s,
  32MiB response,128MiB input,4096MiB V8 heap/8MiB JS stack and original Wasm/fuel
  limits. No acceptance cache or replacement checker;
- prepared build scheduling through existing generated frontend, strict IR,
  transformations and all four core emitters.24 candidate byte comparisons
  cover JS/TS engine variants, both grammars, JS/TS/Rust/Wasm outputs, changed
  dependencies, refusals and assurance; this is not new Rust executor qualification;
- actual JS/strict-TS/Wasm builds, four typing refusals,14 original and14 warm
  kernel fixture comparisons, source tamper refusal, error repair, publication
  preservation and worker shutdown;
- byte-identical successful check saves report unchanged and retain the previous
  result without issuing another request/admission claim (182ms observed).
  Builds still revalidate publication. Real source changes always check anew.

The final producer's tiny-source diagnostic samples are2.34s cold check,
2.90s cold JS build, about1.00s stable warm check and1.40s stable warm JS build.
Earlier same-source samples are faster; do not claim a universal bound. A real
three-module check leaf edit takes1069ms, with two modules reused.
The watchBuild.editMs field includes a subsequent negative test; do not present
it as isolated rebuild latency. The delivery job performs a controlled .5/.6
comparison on one runner and executes the existing CLI/JSON application.

The new root is `proofscript-0.1.0-psc1-modular.6.tgz`,9836728 bytes,
SHA-256 `23ab4f5b3eba1744b54ce3c9bc66a69edc6504b0a5568129eb99b70aa381a2f2`.
Canonical adoption verifies exact passing source/package identities and reuses
that tarball rather than rebuilding or repeating self-hosting. Its delivery
contains ADOPTION.json, COMPARISON.json, installation instructions and hashes.
Previous .5 and .4 remain their qualified references; .6 is Linux/Node qualified,
with Windows/macOS/Bun fast-path qualification pending. No merge/publication.

Next measured queue: remaining graph verification/metadata work; persistent
target consumers; dependency-directed preparation beyond prefixes; cold startup;
then finer algorithmic work if actual applications expose it. Persistent disk IR
or admission caches are not introduced. Extra deliverables may become optional
only with explicit output contracts; strict checking remains mandatory.
[Architecture and usage](architecture/fast-development.md).
Prior PR #213 retained.11 run40842650301 and source run40842871739 are terminal green.
Prototype/harness failures and earlier pending descriptions below are historical.


## Installed development latency — verified Linux milestone

Active branch `feat/psc1-development-speed-20261029`, draft [PR #213](https://github.com/dwijayuda/pskernel/pull/213), from PR #212 HEAD
`b4facc22e7c576a112710e5081a84349c3f3a1e1`.
[Focused installed qualification](https://github.com/dwijayuda/pskernel/actions/runs/40840703422)
passes at producer `f61b5d8cefce07f2b9516db5edb300c8107e8fba`.
Canonical source adoption commit `20ef104cd690a45fd2e4e1e9e9163f33b1631a4b`
uses the exact CI-formatted sources and pins in
[the receipt](PSC1_DEVELOPMENT_QUALIFICATION_2026-10-29.json).

Implemented and tested:
- default check performs generated preparation, strict original IR validation and
  fresh independent Lean 4.35.0 admission, without emitting/consuming a target;
  explicit target/ABI checks retain target validation;
- successful evidence defaults to compact records; `--evidence full` retains
  source/admission/IR/request/candidate dumps. All validation still runs;
- resource aliases are hashed once per capture/pass; all existing fresh resource
  boundaries remain. Actual admissions replace the redundant kernel-health probe;
- Linux/Node watch retains compiler modules in a private sequential supervised
  worker. Check-only preparation reuses exact module prefixes; edits invalidate
  the suffix, errors clear reuse, every request receives fresh kernel admission.

The installed .5 root passes both generated engines and both source grammars,
12 JS/strict-TS/Wasm builds, four type refusals, 14 real kernel fixtures, full and
minimal evidence, tamper-before-execution refusal, ordinary partial checking,
live dependency invalidation, error repair, preserved publication and shutdown.
No handwritten replacement compiler or compiler-source/backend changes are made.

Two-sample cold-process means for tiny `def answer : Nat := 42`, milliseconds:

| Operation | Qualified .4 baseline | .5 | Reduction |
| --- | ---: | ---: | ---: |
| check | 3824 | 3403 | 11.0% |
| js | 4844 | 4568 | 5.7% |
| ts | 5395 | 5275 | 2.2% |

A three-module watch leaf edit completes in 2689ms; preparation reuses 2/3 modules.
This is observational Linux/Node evidence, not a speed guarantee. Cold build gains
remain small. Resource verification still costs about 1.2–1.36s/session; compiler
startup/preparation is the next measured target. The watch-build test's editMs
includes the subsequent negative-publication test, so it is not a rebuild latency.

The exact root is `proofscript-0.1.0-psc1-modular.5.tgz` (9831729 bytes), SHA-256
`bf8c244bdc2b936a07bf1d43d256b99cdb394abfaae0d544c1d3f21d91ecde9b`. Independent kernel, G3 graph and admissions identities are
unchanged. No new self-host chain or broad release matrix is required for this
host-only slice. The .4 cross-platform ZIP remains its qualified platform reference;
.5 Linux results do not qualify its new host on Windows/macOS/Bun.
[Usage, invariants and next work](architecture/fast-development.md).

Adoption follow-ups preserve the historical AST/layout epochs for the intentionally
changed checked-command CLI; current bodies remain bound to qualified source pins.
The final adoption job verifies exact sources/terminal qualification and reuses
that same tested tarball; it does not repeat the installed suite. Draft PR remains
unmerged, with no registry publication.

Next, in dependency order: measure and remove repeated resource/startup work
without moving or weakening trust boundaries; then consider warm build preparation
and an independently supervised persistent kernel only if measurements justify it.
Keep all seven backend mappings and Python/PHP optional; do not add speculative
backend, package, self-host or release obligations.

Prior PR #212 is terminal: adoption40815741447 passes; source40815747045 passes
all16 selected jobs/37 finite Core criteria/zero blocked; retained.11 run40815741441
passes all9 jobs. Earlier pending text below is historical.

## Cross-platform npm/CLI milestone — PR #212

Continue from PR #211 HEAD2c278ab9a47c24ef8635f99b41629fc79fd82699.
The user's platform request authorizes Windows/macOS GitHub Actions in addition
to Linux; all repository work remains connected-GitHub/Actions only.
[Focused qualification40814345252](https://github.com/dwijayuda/pskernel/actions/runs/40814345252)
tests producer1c913c5c12049468d78b324a69356e047b3c7fc9.
The exact tested host/package sources are adopted, including pinned formatting
that preserves each proposed AST. The historical cleanup/layout/runtime/modular
AST guards remain intact; the new platform behavior has its own source pins and receipt.

The same root proofscript-0.1.0-psc1-modular.4.tgz is installed offline with an empty
npm cache on Linux x64, Windows x64, macOS Intel and Apple Silicon, Node22.23.3.
Core package count20; source-owned units134. Independent official Lean4.35.0
C++/Emscripten linear-memory Wasm remains the default. The unchanged source graph,
all original JS/TS G1/G2/G3 fixed-point evidence and earlier Linux Node/Bun,
seven-target and real-application evidence remain separately preserved.
No compiler regeneration or G2/G3 rerun is needed for these host-only changes.

Each platform executes both JS/TS engines, both .lean/.ps inputs and JS/strict
TS/Wasm-core outputs:12 builds per platform,48 total, with actual Nat42,
large negative Int and Unicode String observations. Additional real CLI init/check/
build, compile without publication, watch42→43→type error→44, local/global
offline root installation and npm command registration pass. Real kernel acceptance
and rejection, module-before-import tamper, optional-SDK tamper, typing refusals,
precommit preservation, postcommit uncertainty and stale-session refusal pass.
The earlier diagnostic40812222220 also passes all14 kernel cases and complete4905
compiler admissions on Windows and both macOS architectures using the exact same
unchanged kernel payload; that diagnostic alone did not qualify compilation.

Publication defaults are explicit: Linux legacy-symlink, macOS portable-file,
Windows portable-atomic. The Windows profile guarantees complete atomic visibility
and returns durability:visibility-only; it does not claim power-loss directory
durability. Explicit durable portable-file still refuses on Windows. File flushing
uses a writable handle there; durable paths retain their directory fsync failures.
Unix watch shutdown uses SIGTERM; Windows automated shutdown exercises taskkill of
the owned tree, not interactive Ctrl+C/Break. SIGBREAK handling is implemented but
interactive console behavior is not separately qualified.

TypeScript7.0.2 platform SDKs reuse exact package-lock/SHA512 pins and strict file
inventories. Only the two matching optional SDK tarballs are installed per worker.
All four native SDK archives and common TypeScript archive are included in the ZIP.
Python/PHP stay optional; Rust/component SDKs and old Rust/Wasm compiler executors
retain their existing platform/source-cohort refusals. This finite Node platform
milestone does not claim cross-platform native executors, full M3 semantics on each
OS, native binary reproduction, Windows crash durability, registry release or
240s self-compilation. Ordinary240s/compiler,120s/checker, memory/stack/fuel,
strict original/transformed IR and independent admission policies are unchanged.
No merge, force-push or npm publication.

[Exact platform/source receipt](PSC1_CROSS_PLATFORM_QUALIFICATION_2026-10-29.json)
and [installation guide](architecture/selfhosted-installed-toolchain.md).

[Verified cross-platform ZIP](https://github.com/dwijayuda/pskernel/actions/runs/40814345252/artifacts/12872251721):48024239 bytes,
SHA256 a657e8d11ef37a9c63035981c8172d75c9a70acd6ed6b574bcfe1b1356d6ba89.
Root:9824032 bytes, SHA256 97f0bd6809c9f2a910b64ca96977c0725c6810291ea2f5991ce74fdfcf142446.
The archive includes the root and all four optional native TypeScript SDKs,
checksums, notices, exact source pins and actual platform receipts.
Final canonical adoption is checked by the focused platform-adoption workflow;
it extracts and verifies the same ZIP without rebuilding it.

## Current change and preserved qualifications

PR#193 qualifies runtime/watch and Apache-2.0 package cohort .11 at
`fdc52207fdf3d809ad99b05a5b738aca21b95139`. Full source run40453128053 passes37/37 finite
criteria and scoped seven-backend execution. Installed/runtime run40453124171
passes all previous/new gates,32 supported-runtime compiler cases and three
older-runtime refusals. [Dated receipt](PSC1_RUNTIME_WATCH_QUALIFICATION_2026-10-27.json)
and [work state](../AI_WORK_STATE.md) contain exact artifacts and limitations.

PR#195's qualified development source had124 modules/4742 Core members. The current
transform-provenance extension has125 source-import modules/2692524 source bytes,
recorded separately from transformed runtime ownership. PR#196 source7d7ada7a
passes full40481560025:16 selected jobs,37/37 finite Core criteria/zero blocked,
scoped seven-backend execution and generated JS service G1 selected corpus.
[Transform qualification receipt](PSC1_TRANSFORM_OWNERSHIP_QUALIFICATION_2026-10-27.json)
records exact identities and finite scope. Frozen qualified G3 executors
retain122 modules/4742 members and closure
073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9.
Current source qualification and frozen executor qualification remain distinct.
Repository organization remains qualified at PR#192 /94e0c13f6a4b434f73c859cc0c716cb6fb8d1340.

## Current direction: fully modular executable compiler plan

The 2026-10-28 user decision defers further pilot development and selects
[the production executable-package plan](architecture/executable-package-modularity.md).
Keep proofscript as the installation umbrella and psc as its thin CLI. Gradually
replace source-only/checked-API facades with real source-responsible executable
modules where appropriate. Move misplaced shared contracts down to avoid cycles;
do not hide them in undeclared runtime loads. Preserve qualified .13 until the
production graph passes its own finite gates.

PR #205 reaches a verified candidate M1/M2 milestone. Linux run40664681150 at
60a0d5cb passes complete126-source capture,4781 logical declarations independently
admitted,4516 uniquely owned transformed values in127 units/15 existing packages,
all strict TS checks,26 exact modular-compiler response observations, emitted
JS/TS/Rust execution, Wasm validation, graph/cohort negatives and offline npm
package byte/consumer checks. [Exact receipt](PSC1_EXECUTABLE_PACKAGES_QUALIFICATION_2026-10-28.json)
and [build walkthrough](architecture/executable-package-build.md) state the scope.

PR #206 qualifies checked application execution through the complete modular
engines. [Linux run 40679842606](https://github.com/dwijayuda/pskernel/actions/runs/40679842606)
passes Node 22.23.3 and Bun 1.4.4 at `f433bad0`: 32 checked builds,
528 retained behavior executions and 20 boundary/resource negatives across both
engines, both grammars and JS/strict TS output. Each application has 11 source
modules. Native frontends are absent during modular execution; normalized candidate,
canonical admission, serialized IR and decoded source comparisons match the native
references. [Receipt](PSC1_MODULAR_CHECKED_APPLICATION_QUALIFICATION_2026-10-28.json)
and [execution walkthrough](architecture/modular-checked-execution.md).

The retained source and installed regressions remain separate evidence from this
new modular-engine lane. Source run 40681840579 passes all 16 selected jobs at `05ae5cb4`
(tested merge `e81c3468d68c55719b92198daee658b4972d8d7c`): 37/37 criteria, zero blockers,
14 scoped target-execution bundles. Installed CLI/runtime run 40679842769 passes
all nine jobs at `f433bad0` using its retained .11 cohort/frozen compiler. The .13
npm umbrella retains its separate 53-case reference at PR #205 HEAD `4393ed15`.
CI setup now shares one bounded, cache-aware Lean launcher across 11 sites in
eight active workflows. All 14 observed cache-hit invocations complete in 0–1 seconds;
the previous unconditional setup spent 572 seconds before cancellation. No test,
compiler/checker budget, semantic fuel or memory/stack policy was relaxed.

PR #207 extends M3 with the retained semantic/library corpus and genuine checked
execution of all seven target adapters. [Run 40695323668](https://github.com/dwijayuda/pskernel/actions/runs/40695323668)
passes at `308f2fd988428d30be7c5fd9cfe0c8ace9242447`: **448 checked builds,
552 refusals and 6,944 published function calls**, including 6,048 individual
authored case/flag observations. The complete matrix is eight semantic families,
both source grammars, both complete modular engines and Node/Bun. Existing native
oracles and sealed authored fixtures are reused; only imported libraries undergo
checked grammar conversion, preserving the original native admission bytes.

Additional public-value [run 40700728090](https://github.com/dwijayuda/pskernel/actions/runs/40700728090)
passes 120 builds and 20 refusals at CI-only `85f61b4b`, with identical
compiler/controller sources to `308f2fd9`. JS/TS/Rust/Wasm-core and optional
Python/PHP return the retained Nat, large negative Int, Unicode String, list-result,
handler and ordinary-loop observations. Wasm-component execution is covered in
the semantic matrix using its supported Bool ABI. Richer component ABI and real
non-JS host-IO application qualification remain separate queue items.
Compiled Rust rlib digests vary between execution directories; source/admission/IR
and behavior match. Native binary reproduction is not qualified by this milestone.
[Exact receipt](PSC1_MODULAR_SEMANTIC_QUALIFICATION_2026-10-28.json) and
[extended execution walkthrough](architecture/modular-checked-execution.md).

Retained source [40698796765](https://github.com/dwijayuda/pskernel/actions/runs/40698796765)
passes all 16 selected jobs, 37/37 finite criteria/zero blockers and 14 scoped target
bundles at `308f2fd9` (tested merge `5a48846d97cbeb30c5167ed22d2c9529873d4035`).
Installed CLI [40695323349](https://github.com/dwijayuda/pskernel/actions/runs/40695323349)
passes all nine retained .11-cohort jobs. These scopes remain distinct from both
the new modular graph and the separate .13 reference.

M4 qualifies the finite installed Linux preview described below. M5 now qualifies
portable planning/emission, exact graph/package reproduction and genuine separate
JS/TS G1/G2/G3/fixed points in its finite Linux scope.
The qualified .13 distribution stays the default reference. Pilot expansion
remains deferred; the stopped PR #203 and prototype history are preserved.

## Qualified installed integration: self-host-qualified compiler in proofscript

PR #211 continues from PR #209 /2cb55ddc93404d840b07cc3faad5accd1cee62b0.
Implementation b616e2fe1cbe21646cb6b2f1f22825554ea7b1da passes
[installed qualification40799529998](https://github.com/dwijayuda/pskernel/actions/runs/40799529998),
all10 jobs. Version0.1.0-psc1-modular.3 bundles20 core packages,134 actual
source-owned units, the thin psc CLI and the unchanged genuine official Lean4.35.0
C++/Emscripten linear-memory Wasm kernel. Python/PHP and target SDKs remain optional.

Assembly validates both original JS/TS40755246954 artifacts, G2/G3 manifests,
independent admissions, complete source graphs and all15 original npm tarballs.
Every original generated implementation file remains exact; only explicit
package/host overlays are added. The same133-module compiler source remains
17ce19919175b60be06050188e2a546a8a72e689, closure
1f2f1e4a035a32faa6035aeae000e9c92305f8fb34e58b8cc2210504e38213cb.
The source graph manifest remains74e14f5650931ccc3de2a4a7ed6829f54197bb8100466bcb2eb0ad90d7b14a85;
all4905 logical declarations are also re-admitted by the installed default
Wasm kernel on both Node/Bun, digest
cff6304aef7b3e7c69ac7c4941d275a685b945af2fdc79bf9dfee7ebfd1513f4.
Original source self-hosting and new installed-host qualification remain distinct.

Fresh root-only npm/compiler/kernel tests pass Node22.23.3,24.22.1,26.12.1 and
Bun1.4.4. Node/Bun both engines pass128 checked seven-target builds/20 source or
assurance refusals, global root-only installation,18 retained watch cases,
46 metadata/resource/cycle/consumer refusals,16 Unicode IO builds/8 unsupported
IO-ABI refusals,4 strict NodeNext/Bundler consumers and live TS-watch edits on both
hosts (two successful builds per host; shutdown101ms). All32 real application
builds/528 behavior cases pass:11-module CLI/JSON/file/compiler-like programs,
both grammars/engines and JS/strict TS outputs. Maximum observed application-case
time/RSS:Node11726ms/165428KiB; Bun4132ms/107488KiB. These concurrent CI case
measurements are not compiler memory measurements or universal benchmarks.

[Current source40799548941](https://github.com/dwijayuda/pskernel/actions/runs/40799548941)
passes all16 selected jobs,37/37 finite Core criteria,zero blockers and14 target
bundles (tested merge103ee6344214f584997fb4b3c08af359e28cb80a; benchmark skipped).
[Retained CLI40799529980](https://github.com/dwijayuda/pskernel/actions/runs/40799529980)
passes all9 jobs, preserving the separate frozen.11 reference, older-runtime
refusals and original native guardian/cancellation regressions. Its tarball hash
61fd6c4a2c9c68bf8b02342a8660ffcc328d8cf063650755c9a8ad47923446a3
belongs to that reference scope, not this new root.

[Verified ZIP](https://github.com/dwijayuda/pskernel/actions/runs/40799529998/artifacts/12867276735)
contains the exact root tarball, notices, installation instructions, original
compiler receipt, installed qualification and SHA256SUMS. GitHub wraps the inner
installable ZIP and delivery.json; extract both layers. Inner ZIP:9160194 bytes,
SHA256 fcf24be0ba7ef2d8088b5f2a402a0537c2f6d208cdeedcf90bca587d8c2f83bd.
Root proofscript-0.1.0-psc1-modular.3.tgz:9820916 bytes,
SHA2569a0bc7727c009b071d9835db536a6856bb20b294b8e6d5ff18ef79e68bdb0b57.
The delivery job independently extracts/checksums the ZIP, installs its root
offline with an empty npm cache and executes npm psc help/init/check/build,
observing answer42. It never rebuilds the tested tarball.
[Matching optional SDK/provider resources](https://github.com/dwijayuda/pskernel/actions/runs/40799529998/artifacts/12864774827)
remain separate. Installed graph:1479 files/108582986 bytes, below128MiB.

Canonical compiler/checked host/checker bodies, strict original/transformed IR,
source pairing, ordinary240s requests,120s checking, heap/stack/fuel and all
graph/file/traversal bounds remain unchanged. No new G2/G3 run is needed for
byte-identical compiler payloads; the original3600s correctness and240s performance
profiles remain separate. Preserve.13/M4.1, frozen Rust/Wasm executors and history.
This is a finite Linux installed preview, not universal release, standalone checked
host qualification, native binary reproduction, a compiler preservation theorem
or240s self-compilation. New Rust/Wasm executors and the complete M3 semantic-family
matrix for this installed cohort remain open. No merge or npm registry publication.

[Exact installed receipt](PSC1_SELFHOSTED_INSTALLED_QUALIFICATION_2026-10-29.json)
and [integration guide](architecture/selfhosted-installed-toolchain.md).

## M5: JS/TS G1/G2/G3 and exact modular fixed points qualified

PR #209 continues from PR #208 / d53b43c271c65635b07a6ffa78fb6b08a5fa55de.
[Linux qualification 40755246954](https://github.com/dwijayuda/pskernel/actions/runs/40755246954)
passes both genuine JS and TypeScript chains at controller
336ab495df5479a959a071166b7c2c6b24823b26. Adopted controller checkpoint:
0a4cbba5c38327290f0c309c507cdaf583dc9b15. Canonical implementation source:
17ce19919175b60be06050188e2a546a8a72e689; exact 133-module source closure:
1f2f1e4a035a32faa6035aeae000e9c92305f8fb34e58b8cc2210504e38213cb.

The same frontend/elaborator, strict original/transformed IR, bounded planner and
structured source-owned renderers produce 134 units in 15 executable packages.
All 4905 logical declarations are independently checked using official Lean
4.35.0 / eb6cafb7290e8bd5f2937522d8d804f58f02bafc at every generation.
Admission digest: cff6304aef7b3e7c69ac7c4941d275a685b945af2fdc79bf9dfee7ebfd1513f4.
G1/G2/G3 manifest: 74e14f5650931ccc3de2a4a7ed6829f54197bb8100466bcb2eb0ad90d7b14a85.
Complete graphs, all 1131 files / 103951941 bytes, exact IR/rendered references,
and all 15 actual npm tarballs reproduce byte-for-byte across both chains.
Native frontend executables are quarantined; nativeFrontendCalls=0.

| Producer | G2 wall | G3 wall | G2 maxRSS | G3 maxRSS |
| --- | ---: | ---: | ---: | ---: |
| JS | 2930.381 s | 2907.843 s | 4024528 KiB | 4017160 KiB |
| TypeScript | 2914.908 s | 3078.368 s | 3895680 KiB | 3977884 KiB |

Each request succeeds within the explicit correctness-3600s wall profile.
The user's authorized increase applies only to G2-self/G3-self; retain the
correctness-1800s and performance-240s profiles unchanged. G1/corpus/tools remain
240s; checker remains 120s. V8 heap 4096 MiB / stack 8 MiB, native 4 GiB AS and CPU
guards, semantic fuel, 32 MiB files/streams, 128 MiB graph/stage/wire, 8192
values/files, 257 units, 4096 reference depth and 131072 initializer edges remain.
MaxRSS is measured process memory, not a changed V8 heap allowance.
The 160-minute Linux jobs cover both requests, checking, corpus and packaging.

[G1 seed 40748275409](https://github.com/dwijayuda/pskernel/actions/runs/40748275409)
passes at17ce1991: 112798 ms / 1210604 KiB; repeat40749484426 passes at77961851:
123453 ms /1207588 KiB. [Adopted G1 40759089971](https://github.com/dwijayuda/pskernel/actions/runs/40759089971)
passes at0a4cbba5:115849 ms /1208424 KiB, same native ELF and source closure.
All six raw-JSON/native byte round trips pass. The efdb1385/40746744949 transient
wire overflow is preserved and fixed by removing duplicate escaping, not raising bounds.

Each generated G2/G3 graph also passes the retained small corpus: 26 exact response
observations, 16 independently admitted positives and 10 refusals across the two
grammars/variants; actual JS/strict TS/Rust execution, Wasm validation, wrong-cohort
refusals and offline installation/repacking of all 15 packages. Nested corpus
receipts retain their original conservative local-scope wording; the enclosing
generation receipts supply the actual G2/G3/fixed-point evidence.

[Full source 40759096464](https://github.com/dwijayuda/pskernel/actions/runs/40759096464)
passes all16 selected jobs at0a4cbba5:37/37 finite Practical Core criteria,
zero blockers and14 scoped target bundles. Earlier40749527957 at77961851 passes
the same scope. [Ownership/policy40755976488](https://github.com/dwijayuda/pskernel/actions/runs/40755976488)
passes all11 retained/current cases and wire/profile refusals.
[Retained CLI40759090079](https://github.com/dwijayuda/pskernel/actions/runs/40759090079)
passes all9 jobs at0a4cbba5, including supported Node/Bun and older-runtime
refusals. Its frozen.11 reference cohort is separate from M5. The prior
40749484645 cancellation at the60-minute aggregate deadline remains recorded;
the90-minute job retry changes no commands or per-request limits.
[Existing.13 npm40759096440](https://github.com/dwijayuda/pskernel/actions/runs/40759096440)
passes separately.

Download qualified graphs, IR, manifests, npm tarballs and full receipts:
[JS artifact12852666295](https://github.com/dwijayuda/pskernel/actions/runs/40755246954/artifacts/12852666295)
(115817158 bytes; SHA256 ea16cfb3d4c597d3b37fb22b1b1cffa2940f7075a0d17197140ca6d9e4825194),
[TS artifact12851274486](https://github.com/dwijayuda/pskernel/actions/runs/40755246954/artifacts/12851274486)
(115817233 bytes; SHA256 b49445fe4c4c5626f5a718b619024a6abbcfb3975b5f7f5e080ea1338f221715).

Initial40749484847 G2 failures hit an introduced CPU=wall cap before the defined
wall deadline; correcting Node supervision preserves the canonical wall policy and
native CPU guards. Diagnostics40754131717/40759841635 preserve the exact workload,
CPU profiles and measurements; they are not generation qualification.
The type-key experiment at20e6fa1a remains isolated/unadopted and unqualified.

This completes finite Linux modular JS/TS reproduction, not universal release,
240-second performance, a semantic preservation theorem or totality.
New.2 packages are candidates, not a promoted proofscript root. M4.1 root/.13,
thin psc, default genuine C++/Emscripten linear-memory Wasm kernel, optional
Python/PHP and qualified frozen Rust/Wasm stay preserved. The original generation receipt covers pinned Node. The integration above adds
Node/Bun installed/M4-equivalent application coverage; complete M3 semantic-family,
standalone checked-host, other-platform and final-default-promotion gates remain open. No merge or registry publication.

[Exact qualification receipt](PSC1_PORTABLE_MODULAR_QUALIFICATION_2026-10-29.json)
and [portable architecture](architecture/portable-modular-generation.md).

## M4: qualified installed Linux preview

Final checkpoint `821292dfd7dac39a1281a1b51b8e5ec17af63346` passes full
[source 40728439938](https://github.com/dwijayuda/pskernel/actions/runs/40728439938):
16 selected jobs, 37/37 finite Core criteria, zero blocked and 14 scoped target
bundles (tested merge `ec0dda44f2ec2d77dc0f073965e9dc4fae4293e3`).
[Evidence gate 40728430896](https://github.com/dwijayuda/pskernel/actions/runs/40728430896)
passes exact source/adopted-controller/artifact checks. No qualified product bytes
change in the final evidence update.

PR #208 / `ca92bbdbc7c0f34e1da4076db7300033802eab3e` passes
[40714983520](https://github.com/dwijayuda/pskernel/actions/runs/40714983520):
the genuine 127-unit/15-owner compiler graph, 20 core packages, thin psc CLI,
default official linear-memory Wasm kernel, optional Python/PHP leaves and
fresh root-only local/global installation. Node/Bun pass 16 smoke builds/28
kernel cases, 128 seven-target public/component builds, 20 source/assurance
refusals, 18 retained watch cases and two whole-compiler default-Wasm rechecks.

[40722004088](https://github.com/dwijayuda/pskernel/actions/runs/40722004088)
adds 46 resource/cohort/consumer refusals, 16 Unicode IO callback/trap builds,
eight unsupported dispatcher refusals, four strict type consumers and two TS-engine
live watch cases against the unchanged installed tarball.
[40725714755](https://github.com/dwijayuda/pskernel/actions/runs/40725714755)
passes 32 checked installed CLI/JSON/file/compiler-like builds and 528 behavior cases,
both grammars/engines and JS/strict TS outputs, including 100,000 statements.

Retained source [40719527295](https://github.com/dwijayuda/pskernel/actions/runs/40719527295)
passes all 16 selected jobs, 37/37 finite Core criteria, zero blocked and 14 scoped
target bundles. Retained .11 reference CLI [40714983602](https://github.com/dwijayuda/pskernel/actions/runs/40714983602)
passes all nine jobs; it remains distinct from the modular preview and .13 default.

[Exact receipt](PSC1_MODULAR_INSTALLED_QUALIFICATION_2026-10-28.json),
[architecture and installation](architecture/installed-modular-toolchain.md)
and [installable ZIP](https://github.com/dwijayuda/pskernel/actions/runs/40723525652/artifacts/12832176204).
Existing Rust/Wasm executors remain qualified only for their preserved .13 cohort;
they explicitly refuse this newer compiler source. New modular generations/fixed
points, standalone checked-host installation, actual non-JS host-IO applications
and other-platform durability remain unqualified. No merge/publication or .13 replacement.

## Qualified automatic core package installation (.13)

PR #198 continues from qualified PR #197 HEAD9d0e23c3. Cohort .13 makes proofscript
an umbrella over the20 existing core packages and moves the shared implementation
to the existing @proofscript/compiler package. Adapters depend on compiler, never
root. Python/PHP/native and engine/SDK payloads remain optional. The package build
and installed qualification check all runtime/peer edges for cycles, root-only
offline local/global installation, all core exports and shared runtime identity.
Linux [40507930195](https://github.com/dwijayuda/pskernel/actions/runs/40507930195) passes all53 finite package cases/125 exports at acbf4e70. [Exact receipt](PSC1_NPM_UMBRELLA_QUALIFICATION_2026-10-27.json). Root-only installation contains one executor pair; standalone installs may have a separate npm scope, also identity/hash/tamper checked. Final package40509034127 passes all53 cases/125 exports at892e1895. Full source40509034008 passes all16 selected jobs,37/37 Core criteria/zero blocked and scoped seven-backend execution. Superseded40507930222 was cancelled. Older .11 CLI40507924067 also passes all9 compatibility jobs; it is separate from the .13 artifact. Canonical compiler/kernel/host bodies remain
unchanged; no new compiler-internal modularization or fixed point is claimed.

## Preserved simple npm distribution (.12)

The earlier .12 packaging assignment deferred internal compiler partitioning. That historical scope is preserved; the current production-modularity direction is above.
The conventional builds/installable interfaces for all 24 existing named
packages are complete in the documented Linux scope; the unnamed compiler-unified source directory is retained. Reuse one
qualified proofscript implementation and transparent adapters. Source-only APIs
must be labeled. Full IR splitting, recursive-group packaging and modular
G2/G3/fixed points are deferred, with PR#195/#196 qualifications retained.
[Package guide](guides/npm-packages.md), [finite contract](../NPM_PACKAGE_CONTRACT.json).
PR #197 implementation 9aefeeb and documentation refresh c5c15582 pass all 42 package cases/103 exports in [40501926898](https://github.com/dwijayuda/pskernel/actions/runs/40501926898). Full source 40497179005 passes all 16 selected jobs and 37/37 Core criteria. Default delivery contains 21 tarballs; optional delivery contains nine. [Exact receipt](PSC1_SIMPLE_NPM_PACKAGE_QUALIFICATION_2026-10-27.json) records all sizes, hashes, tested identities and limitations. This qualifies npm distribution, not new compiler-internal modularity.

## Dependency-ordered remaining queue

| Order | Work | Status and finite acceptance |
| --- | --- | --- |
| 1 | Repository organization | Qualified: [receipt](PSC1_LAYOUT_QUALIFICATION_2026-10-26.json). Source 40344469855 passes 37/37; installed40344458391 and current-source WasmG1/40344458240 pass. Canonical owners/compatibility paths, exact move/path checks, generated navigation and unchanged frozen payloads. Human understanding is separate. |
| 2 | Independent maintainer trial | Pending human participation; the user can arrange a maintainer. Record commit, navigation mistakes, elapsed time, assistance and a real small change. No AI/CI comprehension claim. |
| 3 | Compiler-origin structured diagnostics/editor integration | Pending: actual spans/provenance, both grammars, machine/human consumers and malformed-input refusals. |
| 4 | Runtime compatibility, checked watch and licensing | Qualified Linux milestone, PR#193 /fdc52207fdf3d809ad99b05a5b738aca21b95139: Node>=22.23.3, Bun>=1.4.4; actual Node22.23.3/24.21.0/26.12.1 and Bun1.4.4; older Node/Bun refusals;55 CLI requests,11 full watch cases,16 applications/264 observations,32 publications/143 refusals; all61 SDK pins unchanged. Apache-2.0 source/cohort, vendor notices retained. [Receipt](PSC1_RUNTIME_WATCH_QUALIFICATION_2026-10-27.json). Semantic incremental caching remains deferred. |
| 5 | Fully modular executable compiler | M1/M2 candidate graph and finite M3 application/semantic/seven-target execution are qualified in PR #205–#207; see the [current plan](architecture/executable-package-modularity.md) and [M3 receipt](PSC1_MODULAR_SEMANTIC_QUALIFICATION_2026-10-28.json). M4 finite Linux installed umbrella/thin CLI/watch is qualified in PR #208 ([receipt](PSC1_MODULAR_INSTALLED_QUALIFICATION_2026-10-28.json)); M5 finite Linux modular JS/TS G1/G2/G3, full graphs and all15 npm tarballs qualify in40755246954 ([receipt](PSC1_PORTABLE_MODULAR_QUALIFICATION_2026-10-29.json)). Preserve .13, existing package names, independent checking and resource policies. Pilot expansion stays deferred. PR #211 now qualifies the .3 finite Linux installed Node/Bun root, CLI/watch, seven-target and real-application scope ([receipt](PSC1_SELFHOSTED_INSTALLED_QUALIFICATION_2026-10-29.json)). PR #212/.4 qualifies finite Node Linux/Windows/macOS installed JS/TS engines and JS/TS/Wasm-core output ([receipt](PSC1_CROSS_PLATFORM_QUALIFICATION_2026-10-29.json));240s performance, new compiled Rust/Wasm executors and final default promotion remain pending. |
| 6 | Component String/IO and export selection | Pending: reuse shared/native ABI; both grammars/four engines, actual validation/execution, exact exports and refusals. Public component ABI currently Bool only. |
| 7 | Full Python/PHP practical applications | Pending: real CLI/JSON/file/multi-module observations against checked reference; retain corpus/Unicode/integer/loop/IO tests. Providers remain optional. |
| 8 | Automatic source-package capture | Pending: bounded deterministic order, exact identities, cycle/missing/stale refusals, real multi-package applications. Metadata never executes code or grants authority. |
| 9 | Native publication committed-outcome parity | Pending: retain transaction and explicitly report post-commit uncertainty. No false rollback guarantee. |
| 10 | Additional platform consumers/publication | PR #212 qualifies Node22.23.3 Linux x64, Windows x64, macOS x64/arm64, JS/TS engines and JS/strict TS/Wasm-core output. Windows portable-atomic is explicitly visibility-only; durable portable-file refuses. Native Rust/component consumers, Python/PHP platform expansion, interactive Windows cancellation and crash durability remain pending. |
| 11 | Clean reproduction/final universal release | Pending: exact final source/package/platform identities and required generations; authorization before merge/publication. |
| 12 | Original240-second self-compilation target | Unqualified: optimize measured compiler workloads; retain separate correctness profiles and safety policies. |
| 13 | Broader features/extensions and R4 transformations | Deferred beyond frozen v1 or explicit semantic obligations. Preserve working features; packages cannot acquire checker/host/FFI/publication authority. |

## Fixed policies

Official Lean 4.35.0/eb6cafb7290e8bd5f2937522d8d804f58f02bafc, trust 0,
independent admission, exact source/logical-body pairing, strict original/transformed
IR, semantic fuel, memory/stack/lifetime policies, negatives and ABI refusals remain.
G1/compiler/tools/corpus remain 240 seconds; checking remains120 seconds.
Manual G2/G3 correctness profiles remain separate from240-second performance.
Kernel-Wasm remains official C++/Emscripten linear memory; compiler-Wasm retains GC.
PSKernel-Core remains independent. Use dependency-selected CI/exact artifacts;
do not rerun unchanged frozen G2/G3 merely for host/docs changes.
No merge or registry publication is authorized.
