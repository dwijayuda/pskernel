# PSC1 AI work state

Updated 2026-10-29 Asia/Jakarta. Active branch feat/psc1-wire-quote-20261029,
from PR #214 qualified HEAD c83039f05a445f496f71aea2429ba75c61b81f40.
Connected GitHub and Linux Actions only; previous platform evidence is retained. Expected-HEAD,
single-parent/non-force history. No merge or npm registry publication.

## Verified .9 delivery and scope

[Adoption40885379578](https://github.com/dwijayuda/pskernel/actions/runs/40885379578)
passes at708f6b5ca99eb44e2dc6608404dffeb5af717cd5. It verifies all four exact
host pins, current source against the passing G1 snapshot, both immutable
qualification reports and the paired measurements; it reuses the tested tarball.

[Verified Linux ZIP](https://github.com/dwijayuda/pskernel/actions/runs/40885379578/artifacts/12901169879)
(GitHub sign-in required), outer artifact SHA256:
7ca0c059e3684c60b5e3afbb8c50b8e385145845af8ad697f7b97859bacab9b3.
It contains .9 root5197da26..., matching TypeScript7.0.2 tarballs, Apache-2.0/
notices, installation instructions, qualification/comparison/adoption receipts
and SHA256SUMS. The installer explicitly states that native quoting is not active
in the retained 17ce1991 G3 graph. The newer 120bbbc5 source cohort remains
separately checked G1; new-cohort G2/G3/fixed-point promotion is still pending.
No source qualification is silently inherited or downgraded.

The retained G3 source17ce1991 compilePreparedWithOutputAbi body was also read
directly and matches the prior7b9dc272 body exactly, confirming that it performs
the required original-IR validation before transforms. The adapter removes only
the redundant pass. New retained-CLI run40885379473 is separate; read it live
before terminal claims. No merge or npm publication.

## Verified transport and validation implementation

PR #215 HEAD 7b9dc2725be226f401a8adcd2e6f0af391308504 is now fully green:
[source40872117065](https://github.com/dwijayuda/pskernel/actions/runs/40872117065)
and retained frozen-.11 [CLI40871621864](https://github.com/dwijayuda/pskernel/actions/runs/40871621864).
The latter tests its own historical cohort; it is not new-source self-host evidence.

[Transport qualification](docs/PSC1_WIRE_TRANSPORT_QUALIFICATION_2026-10-29.json) and [source-linked walkthrough](docs/evidence/PSC1_WIRE_TRANSPORT_2026-10-29.md)
record two distinct implemented scopes:
- Remove the duplicate warm-build original-IR pass. Check-only retains its check;
  builds use the existing generated check before transforms. All transformed IR,
  independent admission, resource, target and publication checks remain.
- Add shared Lean serializer parameters while preserving old entry points.
  Exact prior-body audits and two rfl equations pass, with observed [propext]
  dependencies. A fixed private Node serializer verifies scalar UTF-8 and JSON
  roundtrips, otherwise using the generated quoter. No project callbacks.

[G1 compiler40879970347](https://github.com/dwijayuda/pskernel/actions/runs/40879970347)
passes at7e25050ffd9027f22f8b4b723ad4b6c017e11bbc: 4907 independently admitted
logical declarations, 134 units/15 strictly checked TS packages, nine integrity
refusals, and both executing generated JS/TS compilers. Each matches all1,112,064
Unicode scalars plus boundary/fallback cases. Across both engines,26 request cases
match old .7 and new legacy candidate bytes; positive candidates admit natively,
six actual large IO applications also admit through the official Wasm kernel.
This is finite G1 transport evidence, not new G2/G3 or compiler preservation proof.

[Paired40882916436](https://github.com/dwijayuda/pskernel/actions/runs/40882916436)
compares the same prepared graph/policies with native versus generated portable
quoting: JS body10885→8677ms/comment6293→4018ms; TS body11959→9170ms/
comment6674→4179ms. Savings2.2–2.8s are candidate-only observations; both modes
independently admit and execute every application. Initial JIT samples are not
cold CLI speed claims.

Installed [40881471194](https://github.com/dwijayuda/pskernel/actions/runs/40881471194)
passes atae89810d3548731e3834041665ea16cbc5ddc228 with the exact four host pins.
The .9 root is9838447 bytes, SHA256
5197da266e3795406b127f6569f67ba8016d705fa602c03a4454a7cbc970b620.
Both engines/grammars,12 real builds/four refusals,24 candidate comparisons,
14 original/14 warm kernel fixtures, live watch/tamper/publication/shutdown pass.
Its same-runner .7/.9 warm application means7369/6762ms are observational.
The raw comparison label candidate-.8 is historical text; exact receipt and SHA
identify .9. Preserve raw evidence; the future controller is corrected.

**The .9 installed graph intentionally remains qualified source17ce1991,
digest1f2f1e4a/manifest74e14f56. Native quoting is not active in that older graph.**
New source7e25050f has digest120bbbc5/G1 manifest5ba70eff and executes fast quoting,
but has not run its own G2/G3/fixed points or been promoted into the locked root.
Keep the strict provenance gate. No old fixed-point receipt is relabelled.
Canonical source adoption and ZIP delivery must verify terminal artifacts and
exact pins before a delivery claim. No merge or npm publication.

Dependency-ordered queue: preserve this verified host/G1 checkpoint; batch further
shared-source work; run one manual new-cohort correctness chain before promotion.
Existing requests took about50min each, so avoid repeating them for controller edits.
Keep the separate240s performance target, official Lean4.35.0, all resource/fuel
limits, seven-backend semantics, optional Python/PHP and prior platform evidence.

## Historical active follow-up: duplicate validation and admission transport

Branch `feat/psc1-wire-quote-20261029`, from PR #215 HEAD
7b9dc2725be226f401a8adcd2e6f0af391308504. Live source40872117065 and retained
CLI40871621864 had no failures and were still running when this branch started;
re-query before final claims. Preserve .7 and all exact compiler/kernel evidence.

The host-only .8 proposal removes the extra original-IR validation in warm builds.
The existing generated compilePreparedWithOutputAbi validates original IR before
any transform; check-only retains its adapter validation, including reuse hits.
Installed qualification and a same-runner application comparison are required
before canonical adoption. The qualified G3 graph is unchanged for this host slice.

Next, add a serializer parameter in shared Lean transport source while preserving
legacy entry points by applying psJsonQuote. A fixed private host native quoter
must have exact Unicode/control byte parity, roundtrip checks and generated fallback;
project data cannot select callbacks. Regenerate and independently check actual
JS/TS compiler graphs. New source-cohort evidence must stay separate from .7's
G1/G2/G3/fixed points. Do not silently relabel that evidence or weaken provenance.
Full source-cohort self-hosting remains a later promotion gate, not an edit loop.

## Verified .7 delivery

Canonical adoption [40871621775](https://github.com/dwijayuda/pskernel/actions/runs/40871621775)
passes at1e104ecc3c2a89678f41c8a1853437cd32d5b6b8. All four production pins,
terminal qualification/package/source identities, unchanged compiler source,
historical host correspondence and repository layout pass.
[Download the verified Linux x64 ZIP](https://github.com/dwijayuda/pskernel/actions/runs/40871621775/artifacts/12895314098)
(GitHub sign-in required). Outer artifact SHA256:
785ec1578d7ef4560ec39ed99eb45e9db22b397a9980f1d7314de32423172d0b.
It contains the exact tested .7 root, two matching TypeScript7.0.2 SDK tarballs,
Apache-2.0/notices, installation instructions, qualification/comparison/adoption
receipts and SHA256SUMS. No rebuild or new compiler/self-host claim.
Root SHA256 remains ab0e2ce442f52311f9fad0e96cebc759c9848434ad49e8c06c6e2df9a76c9d79.
Retained CLI run40871621864 is separate and must be read live before terminal claims.

## Qualified structural reuse — .7 Linux/Node milestone

Installed [40870884480](https://github.com/dwijayuda/pskernel/actions/runs/40870884480)
passes at018057cd6ab0f4b12456d444f25d9ccc6ac0c47f using exact producer
57e72bce3bc1a329704696878ff07a53fb4c7ee3. Adopt its four CI-formatted source
pins, not the abandoned fingerprints. [Qualification receipt](docs/PSC1_SEMANTIC_REUSE_QUALIFICATION_2026-10-29.json)
records exact package/source/artifact identities and the diagnosed experiments.
No compiler source, original134-unit G3 graph, Lean4.35.0 kernel, semantic fuel,
strict IR, failure behavior or existing request/heap/stack policies change.

Both generated JS/TS engines and both grammars pass12 actual JS/strict-TS/Wasm
builds, four typing refusals,24 prepared/cold target candidate comparisons,
14 original/14 warm independent-kernel fixtures, tamper refusal, full/minimal
evidence, ordinary partial checking, dependency invalidation and live watch
error/publication/shutdown. The producer additionally passes ten real11-module
application candidate comparisons, including shifted origins, body changes,
typing refusal/recovery in both engines, and three independently checked actual
Unicode JSON/file-processing executions.

Same-runner .6/.7 application comparison: stable warm means7213/4566ms,
1.58x speedup (36.7% less time); six checked application executions pass.
The first requests10147/10037ms show no material cold improvement.
These are comment-only leaf-edit observations, not body-edit or universal bounds.
Changed bodies miss comparison in0.07–0.15ms and recompute normally.
New tiny-source CLI samples: check1447–1451ms, JS1800–1804ms, TS2190–2194ms;
not cross-runner comparisons. Three-module watch check leaf edit804ms;
unchanged-save182.6ms issues no new admission. watchBuild.editMs includes a
later negative case and must not be described as isolated rebuild latency.

Root proofscript-0.1.0-psc1-modular.7.tgz is9837710 bytes,
SHA256 ab0e2ce442f52311f9fad0e96cebc759c9848434ad49e8c06c6e2df9a76c9d79.
Canonical adoption verifies exact source pins and reuses that tested tarball,
matching SDKs and results. Its separate delivery job must pass before claiming
the new ZIP verified. .6 remains downloadable at artifact12892806521.
New .7 host evidence is Linux/Node only; preserve .4 platform and all previous
compiler/backend/self-host receipts. No merge or npm publication.

Next: profile the remaining backend subpasses separately. Actual V8 samples
show generated recursive runtime/Text insertion/JSON escaping and allocation;
do not infer quadratic behavior from those samples (Text already uses balanced
chunks). Optimize shared source/runtime algorithms with exact output parity,
then regenerate/qualify changed compiler graphs only when source changes require it.
Persistent target consumers and cold startup follow measured benefit. No general
query framework, persistent admission cache or duplicate compiler is introduced.

## Historical diagnostic checkpoints

## Structural-sharing producer passes; installed gate next

[40869848303](https://github.com/dwijayuda/pskernel/actions/runs/40869848303)
passes at57e72bce3bc1a329704696878ff07a53fb4c7ee3. Exact staged production
pins are recorded by that job; original compiler graph and kernel remain unchanged.
Both JS/TS engines pass ten exact real-application cold/prepared candidate
comparisons, including prefixed comments that shift source origins, actual
body changes, typing refusal and recovery. Unchanged semantic preparation takes
1.5–3.2ms rather than the observed initial3–4s; changed bodies miss comparison
in0.07–0.15ms. Printing reuse hits only equivalent inputs. Three actual Unicode
application builds independently admit and execute; warm total8.4–8.5s on this
profiled runner. These are not cross-runner speedup claims or semantic-edit wins.

Artifact12896251225 SHA256 f8dd6a58ef06541438b3064382a319b8d325f0cbb163414ae1c08c14090dcd0e
holds the exact candidate .7 package and four formatted source pins. The next
installed qualification reuses it and matching already-qualified TypeScript SDKs;
no compiler rebuild, G2/G3 rerun or repeated large application parity matrix.
A same-runner .6/.7 application comparison follows the preserved focused suite.
The .7 root is not release-qualified until that gate and source adoption pass.
Retained .6 source gates40863053548 and frozen.11 CLI40863008436 are now terminal green.

## Structural sharing replaces the fingerprint experiment

[40868629404](https://github.com/dwijayuda/pskernel/actions/runs/40868629404)
passes at ea90cd65d5ab018b0051a7d2b14fea87bf6474f6: ten exact real-application
candidate comparisons across JS/TS engines, including body change, typing refusal
and recovery; three independently checked/actually executed Unicode applications.
Fingerprint reuse works for TS, but JS data exceeds its node budget. CPU samples
identify generated Text insertion, JSON escaping and allocation as hot paths;
the official warm checker spends most of its wall time idle between requests.

Replace optional hashing with bounded iterative comparison of complete private,
immutable compiler values. Shared nodes from unchanged captured prefixes compare
by identity; distinct nodes compare all own keys/descriptors/hidden symbols and
values. Unsupported shapes/accessors/cycles/budget misses conservatively recompute.
No source-text approximation, admission cache or handwritten frontend is added.
Only one emitter input/result graph is retained, with at most4,194,304 source
characters; originals/transforms still validate and all requests check independently.
This next candidate remains experimental until its exact installed tests pass.

## Pure-reuse diagnostic follow-up

[40868027763](https://github.com/dwijayuda/pskernel/actions/runs/40868027763)
passes at84038c5e4e126557a34d3f8ace4a0a3850c0d48d: bounded key safety
and three genuinely checked/executed application compilations. The100ms
semantic fingerprint budget missed conservatively; emitter reuse hit on the
third request. Print-only work was1606ms before reuse, while the remaining
backend pipeline still cost6154ms. No general semantic-edit acceleration claimed.
The follow-up batches fingerprint hash writes, retains bounded fallbacks,
adds CPU attribution and exact cold/warm candidate parity for both JS/TS engines
over real application comment/body/refusal/recovery cases. The optional key
budget is500ms; compiler/checker/fuel/memory limits are unchanged. .6 remains
the qualified installable artifact until all .7 gates and adoption pass.

## Bounded pure-compiler reuse experiment

Phase probe [40865163111](https://github.com/dwijayuda/pskernel/actions/runs/40865163111)
passes at040461b64154a23a4b4379eaa0e10cd58972aa3e. On warm comment-only leaf
edits: capture/elaboration9.5–12.8ms, semantic preparation2620–2691ms,
strict original IR264–292ms, backend pipeline5916–5936ms. These are observations
from that runner, not comparable speedup claims against other runners.

The .7 proposal tests bounded private value fingerprints of complete generated
semantic-preparation inputs and emitter arguments, including hidden constructor
symbols and UTF-16 code units. Unsupported shapes/cycles/budget misses disable
reuse; no getter evaluation or persistent/admission cache. Generated functions
remain the implementation. Fresh capture/origins, original/transformed IR,
target checks, official independent admission and mutable-resource checks remain.
Add print-only timing before attributing the whole backend pipeline to printing.
This remains an experiment until genuine parity and installed checks pass.

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

[Exact platform/source receipt](docs/PSC1_CROSS_PLATFORM_QUALIFICATION_2026-10-29.json)
and [installation guide](docs/architecture/selfhosted-installed-toolchain.md).

[Verified cross-platform ZIP](https://github.com/dwijayuda/pskernel/actions/runs/40814345252/artifacts/12872251721):48024239 bytes,
SHA256 a657e8d11ef37a9c63035981c8172d75c9a70acd6ed6b574bcfe1b1356d6ba89.
Root:9824032 bytes, SHA256 97f0bd6809c9f2a910b64ca96977c0725c6810291ea2f5991ce74fdfcf142446.
The archive includes the root and all four optional native TypeScript SDKs,
checksums, notices, exact source pins and actual platform receipts.
Final canonical adoption is checked by the focused platform-adoption workflow;
it extracts and verifies the same ZIP without rebuilding it.

### Canonical adoption and retained reference follow-up

[Adoption40815403860](https://github.com/dwijayuda/pskernel/actions/runs/40815403860)
passes at25dbdaa024386e9904dcf3c413e7100035e4d148: all11 exact source pins,
unchanged compiler sources, complete historical AST/format guards and16 extracted
ZIP checksums; no repeated compilation. [Verified artifact](https://github.com/dwijayuda/pskernel/actions/runs/40815403860/artifacts/12872291923).

The automatic retained.11 run40815403827 fails its old current-production hash
assumption for transactional-publication.mjs after intentional platform adoption.
The .4 four-platform qualification is passing. The reference assembler now captures
those finite affected host files from immutable pre-platform2c278ab9 and separately
verifies every current source against the platform receipt. Existing reference
regression bodies, old compiler/kernel/provider payload checks and all negatives
remain intact. The retry is pending; do not confuse this historical-host assembly
failure with compiler/platform execution failure. Broad source gates40815408758
were selected automatically; no extra G1/G2/G3 was dispatched.

## Verified integration: self-host-qualified compiler in proofscript

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

[Exact installed receipt](docs/PSC1_SELFHOSTED_INSTALLED_QUALIFICATION_2026-10-29.json)
and [integration guide](docs/architecture/selfhosted-installed-toolchain.md).

## Preserved M5: JS/TS G1/G2/G3 and exact modular fixed points qualified

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
Node/Bun installed and M4-equivalent application coverage; the complete M3
semantic-family matrix, standalone checked host, other platforms and final default
promotion remain unqualified. No merge or registry publication.

[Exact qualification receipt](docs/PSC1_PORTABLE_MODULAR_QUALIFICATION_2026-10-29.json)
and [portable architecture](docs/architecture/portable-modular-generation.md).

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

**M5 now qualifies finite Linux JS/TS graph/package reproduction and genuine
G1/G2/G3 fixed points above.** M4 remains its original installed preview cohort;
new root promotion is a separate gate. Component String/IO, actual non-JS host-IO applications, platform consumers
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
integration in its finite Linux scope. M5 reproduction/fixed points are now qualified
above; actual non-JS host-IO applications remain incomplete. No merge or registry publication.

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
qualified in the preview scope above; release promotion remains pending. M5 modular
generation/fixed points now pass above; compiled native artifact reproduction remains unqualified.
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
2. M5 is qualified in its finite Linux JS/TS scope:40755246954, exact source17ce1991,
   complete graph and 15 npm tarballs. Preserve its source, measurements and artifacts.
3. The .3 installed Node/Bun/application gates now pass above. Retain platform and
   final-default-promotion gates. Optimize toward240s using actual workload profiles;
   do not adopt the parked type-key experiment without its own exact proof/evidence.
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


### Wire quoting: public ABI correction and cold routing (2026-10-29)

The full source run 40886789852 passed its selected compiler/source/backend jobs but failed the default JS/Rust transport fixture: the added higher-order quote helper was accidentally public (PSC1_PUBLIC_NONSCALAR_SIGNATURE_UNQUALIFIED). Move it into Ps.Internal.CompilerHost, preserving the scalar ABI refusal and exact legacy bodies; re-qualify this corrected source cohort before promoting it. The installable retained-source .9 artifact remains valid and separate. Its default source graph does not enable native quote calls.

Cold Node/Linux JS/TS/Rust/Wasm-core builds now select the same installed, hash-bound prepared adapter already used by warm builds; every original/transformed IR check, independent admission and publication boundary remains required. Other runtimes/platforms/targets retain their previous route. This host routing requires actual installed qualification; it is not yet claimed qualified. The earlier G1 and paired-quote measurements remain precursor evidence, not qualification of the namespace-corrected source. The in-progress precursor generations must not be promoted for this corrected source.
