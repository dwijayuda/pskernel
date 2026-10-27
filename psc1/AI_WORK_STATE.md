# PSC1 AI work state

Updated2026-10-27 Asia/Jakarta. Active branch `feat/psc1-modular-partitions-20261027`,
from PR#196 HEAD `173ecdc9f7131366d376c80886a7843a402d363b`.
GitHub/Linux CI only; single-parent expected-HEAD/non-force history. No merge or
registry publication. Previous work state is preserved byte-for-byte in
[history](docs/history/AI_WORK_STATE_BEFORE_MODULE_PARTITION_2026-10-27.md).

## Transformed graph measurement passed; v3 partition implementation under test

Read-only native production-transform measurement at177e41a3e3a9cb5504dd5db9a9e8dcb038e1d834
passes [40488488194](https://github.com/dwijayuda/pskernel/actions/runs/40488488194),
job122136170361, with genuine independent official Lean4.35.0 admission.
It captures the complete125-module unified source closure once, strict-checks
original IR, specializes with explicit origins, composes owners, fuses workers
with explicit origins, composes again and records resolved lexical value edges.

| Stage | Values | Structures | Inductives |
| --- | --- | --- | --- |
| Original |3154|221|96|
| Specialized |3950|316|604|
| Fused |4520|316|604|

There are1472 specialization origins and570 worker origins. This snapshot has no
cross-source runtime SCC larger than one. Zero surviving-value sources:
Ps.Foundation.Source, Ps.Core.Expr, Ps.Core.Declaration, Ps.BackendJs.Model.
The final largest owner is Foundation.List with846 values. Time111938ms,
maxRSS389420KiB;240-second/4GiB/8MiB bounds retained. Assurance is the existing
ordinary-checked compiler-source protocol; exact Core admission is separate from
backend preservation or self-hosting. Source-import navigation is not substituted
for these actual transformed value edges. All nominal types retain runtime owner0.

The new explicit v3 profile computes mutual reachability SCCs on at most eight
source owners, preserves runtime initialization independence, topologically
orders the condensation deterministically and coalesces zero surviving-value
sources into shared runtime/type unit0. Partitioning changes ownership/imports,
not IR bodies. Existing v1/v2 ordered-DAG contracts and refusals remain.
Eager initializers, unknown/duplicate owners, unsafe packages and exhausted
budgets refuse. Full compiler emission is still outside the unchanged256-value/
64-type bounds; measurement is not emission qualification.

The native coordinator and common assembler/loader now accept the v3 profile,
store complete source-to-unit/group metadata, retain all source snapshots under
collision-free full module names, and derive aliases through the partition.
The next real graph adds compiler Foundation.Source and Foundation.StringSet
to the prior List/Name/Text/Json/consumer graph. Its eight-package qualification,
12 partition invariants/11 refusals and strict IR cyclic-group runtime fixture
are pending Linux CI. Existing package cases, immutable PR195 baseline comparison,
strict IR, external checker, byte/time/fuel/memory/stack limits remain required.
No completed modular compiler, portable partitioner self-hosting, G2/G3/fixed
point or platform-comprehension claim.

Next: diagnose CI failures, qualify all three profiles and full source gates,
record exact artifacts/source identities, then define the finite next compiler
partition profile from measured scale without silently relaxing existing caps.
Frozen qualified compilers/kernels/providers remain unchanged.

## Preserved PR#196 qualification

# PSC1 AI work state

Updated 2026-10-27 Asia/Jakarta. Active branch `feat/psc1-modular-origins-20261027`,
from PR#195 HEAD `cc13ebfabf6763703ee1ec75a663002a9134bc74`.
Use connected GitHub/Linux CI only. Single-parent expected-HEAD/non-force updates;
no merge or registry publication. PR#195 state is archived byte-for-byte in
[history](docs/history/AI_WORK_STATE_BEFORE_TRANSFORM_OWNERSHIP_2026-10-27.md).

## Transform ownership and extended graph — qualified Linux milestone

PR[#196](https://github.com/dwijayuda/pskernel/pull/196), source checkpoint
`7d7ada7ad7d5f5ca1504527342888d929e1b9959`, passes
[full source40481560025](https://github.com/dwijayuda/pskernel/actions/runs/40481560025).
All16 selected jobs succeed; benchmark is skipped. Tested PR merge:
`accd2875a6c09ab30f3b3fd02e4c07883d4dd675`.
Full job122118349828 and gate122128596249 pass; all37 finite Practical Core
criteria are qualified, zero blocked, with scoped seven-backend execution.
The required modular job122113153459 passes both contracts.
[Dated machine-readable receipt](docs/PSC1_TRANSFORM_OWNERSHIP_QUALIFICATION_2026-10-27.json)
records exact source/package/tool identities, attempts, timings and boundaries.
Subsequent checkpoint edits record documentation/evidence only.
The earlier [dedicated40479759828](https://github.com/dwijayuda/pskernel/actions/runs/40479759828)
also passes at74dd51be44a905e49c3c5d8c505bd10d3ca6a885.

The existing transform engine now returns backend-neutral provenance at actual
specialization creation sites and worker plan companion allocation. Every value,
structure and inductive output has one immediate parent record. Closed type
arguments are explicit. No suffix/prefix inference assigns synthetic owners.
Retained identity does not assert an unchanged body. Existing public APIs use the
same implementation with complete origin-list tracing disabled; opt-in APIs
enable it. No semantic-preservation theorem or zero-overhead claim is made.

Ownership composition strictly checks both modules, complete unique origin
coverage, existing parents, arity/groundness and rule consistency. It carries
owners through specialization and then worker fusion. Tests exercise authored
worker-name collisions and workers whose parents are specialized clones.
Twelve provenance invariants/eight refusals, eight extended layout refusals,
and all14 old planner refusals pass.

The explicit v2 profile emits real Foundation.List, Foundation.Name,
Foundation.Text, Bridge.Json and dependent consumer source as six modules
including one shared runtime/type owner:seven exact-cohort npm packages.
124 original value declarations become129 specialized and160 fused, with57
specialization origins,31 workers and eight specialization-to-worker chains.
All normal values/types remain covered by strict IR and genuine independent
official Lean4.35.0/eb6cafb7290e8bd5f2937522d8d804f58f02bafc admission.

29 finite v2 package cases pass alongside all28 v1 cases. Actual both-grammar,
JS/TS, Node22.23.3/Bun1.4.4 execution includes generic collections, high-order
calls, Unicode names, actual compiler JSON parsing/canonical encoding, huge Nat
values and depth6000. Strict NodeNext/bundler declaration consumers, shared
runtime/tag identity, exact seven-tarball reproduction, provenance/code tampering,
cross-profile mix refusal and before/after-commit transaction outcomes pass.

Immutable PR#195 source atcc13ebfa is built as a separate native baseline harness.
For both grammars, original/specialized/fused IR, canonical admissions and bundled
JS/TS bytes match exactly. Integrated baseline requests took432ms/405ms. The baseline tracked
source stays clean; harness source/binary identities are captured. An initial
interpreter attempt failed on a missing private standard-library artifact.
Native compilation avoids that interpreter dependency without bypassing checks.

Primary integrated [artifact12722888572](https://github.com/dwijayuda/pskernel/actions/runs/40481560025/artifacts/12722888572)
is3380311 bytes, ZIP SHA256
`e8894ab245d602c50ed10b649cab4f1af77d7901d73be8b82f68616f6130183d`.
The earlier dedicated artifact12723121434 remains corroborating evidence.
Its installable-extended-lean/installable-extended-ps directories each contain
seven matching tarballs and SHA256SUMS. Owned packages use Apache-2.0.
v1 remains0.1.0-psc1-modular-pilot.0; v2 is0.1.0-psc1-modular-pilot.1.
These remain experimental components; the proofscript bundled distribution and
117 previously qualified compiler/kernel/provider payloads are retained.

Limits remain240s producer/baseline,120s checker,4GiB address space,8MiB stack,
reference fuel4096 and unchanged transform fuels;1MiB requests,32MiB native
response/cohort,256 surviving IR values/64 nominal types. The explicitly versioned
v2 source bound is2..8 with at most9 units; v1 stays exactly2 sources/3 units.
Measured integrated extended requests: Lean710ms/129512KiB maxRSS,
PS631ms/131608KiB.
These are component measurements, not whole-compiler performance qualification.

[Architecture](docs/architecture/transform-provenance.md),
[v2 contract](test/modular/extended-contract.json).
Read-only unified source-import telemetry measures125 modules/2692524 source
bytes, digest63dc2ecd6306e8465db860a8f3637e6e7ca129aa9169eaed61484b939728722f.
It is separate from transformed runtime ownership or complete modular execution.
Current generated JS service G1 job122117068068 passes ten selected cases using
its89-module closure4192d19b17060d7e8637189fea14309460cd61645376213b672b499c2e43b934;
this is selected-service execution, not modular self-hosting or fixed points.
Full compiler partitioning, cross-unit
recursive groups/type-only coalescing, portable planner self-host qualification,
modular G1/G2/G3/fixed points, other platforms and the arranged independent human
maintainer trial remain pending. Preserve the old successful qualifications
without relabeling them as this changed compiler source.

Next: measure the complete transformed compiler runtime graph and define a finite
partition contract for recursive groups/type-only units. The source-import
navigation receipt alone cannot choose executable package ownership. Preserve
all passed gates, budgets, independent checking, strict IR and negatives.

## Preserved PR #195 reference

# PSC1 AI work state

Updated 2026-10-27 Asia/Jakarta. Active PR[#195](https://github.com/dwijayuda/pskernel/pull/195),
branch `feat/psc1-modular-pilot-20261027`, from PR#193 HEAD
`24d1a9764e8251ab4f4bac65c38fb30f9e8295f4` (re-read unchanged).
Single-parent expected-HEAD non-force history; no merge or registry publication.

## Genuine modular compiler-component pilot

Qualified code checkpoint `42eef6ca6409e9637b189bf3f064f37649ae62ed`.
[Full source40466377732](https://github.com/dwijayuda/pskernel/actions/runs/40466377732)
passes16 selected jobs, benchmark skipped,37/37 Practical Core criteria/zero blocked.
Tested PR merge `8c20d1484ab7f3eca7d47f505418824ab1b7c7e6`.
Required modular job122063338916 passes28 package cases and14 planner refusals.
[Installed/runtime40466372623](https://github.com/dwijayuda/pskernel/actions/runs/40466372623)
also completes successfully. Subsequent checkpoint edits are documentation/evidence only.
[Dated qualification receipt](docs/PSC1_MODULAR_PILOT_QUALIFICATION_2026-10-27.json)
records exact source/package/tool identities and all attempts.

Actual existing Foundation.Name compiler source plus a dependent consumer emit
as three real packages (shared runtime/types, names bodies, consumer bodies) and
a small integrity-loading umbrella. Both .lean/.ps, JS/TS, Node22.23.3/Bun1.4.4
execute against bundled same-IR observations, including Unicode, higher-order
calls, constructor identity, recursion and depth6000. Four strict NodeNext/bundler
consumers, exact same-input four-tarball reproduction, file/directory/symlink/
version/cohort refusals and before/after-commit transaction outcomes pass.
28 finite package cases plus14 pure planner refusals pass.

The production elaborator captures once. Exact tagged origins/erasure names own
every surviving value; unknown synthesized owners refuse. Existing closed
specialization, strict original/transformed IR and external genuine official
Lean4.35.0/`eb6cafb7290e8bd5f2937522d8d804f58f02bafc` admission remain.
No mock checker, facade compiler or emitted-text splitting. Producer240s/4GiB/
8MiB stack, checker120s, reference fuel4096, input1MiB/output+cohort32MiB,
two sources/three units/256 values/64 types. Worker fusion and open generic values
are outside this first profile. Shared type/tag plan and one WeakMap/cache per
variant; JS structural tags and TS unique-symbol ABI stay distinct.

Primary [pilot artifact12716353757](https://github.com/dwijayuda/pskernel/actions/runs/40466377732/artifacts/12716353757),
436285 bytes, ZIP SHA256
`ec03b644d125418591ecf5ab8b7a21ded707bc141c20ec54471e1720330d0af6`.
Earlier standalone pilot40465513856 at8473b22e also passes the same contract;
all six child tarballs reproduce exactly across the two independent runner builds.
Umbrella identities differ because their compiler-commit metadata differs.
It contains installable-lean/installable-ps four-tarball directories, SHA256SUMS,
canonical admissions/IR/source snapshots, cohort pins and qualification JSON.
These are experimental unpublished component packages, version
`0.1.0-psc1-modular-pilot.0`; owned code/packages Apache-2.0.

Measured integrated native candidate requests: Lean82ms/79992KiB maxRSS; PS76ms/79912KiB.
Runtime receipts retain module-load/workload/warm timings and process-reported
maxRSS. These are bounded component observations, not whole-compiler benchmarks,
isolated workload memory or a performance-improvement claim.

[Guide](docs/guides/modular-pilot.md), [finite contract](test/modular/contract.json).
Installed verification assumes a trusted bootstrap/pin and stable package files;
metadata grants no checker/host/publication authority. Flat npm-cohort transaction
qualification does not qualify arbitrary nested service publication or another OS.

CI integration: the pilot is a reusable selected focused gate and a required
final dependency. Its independent stages retain evidence even if another stage
fails; any failure still fails the job/gate. Production CLI does not import these
new host modules; isolated pilot-only edits use this gate, while shared host/CLI
changes retain the entire existing installed workflow.

Existing installed gates pass:55 CLI requests,11 watch cases,16 applications/
264 observations/eight global cases,32 checked publications/143 refusals,
all61 unchanged SDK pins,32 supported-runtime compiler cases/eight runtime-watch
cases and three older-runtime refusals.117 frozen compiler/kernel/provider payloads
are byte-preserved. The prior components-pin failure remains recorded. CI now
permits only a unique metadata-line permutation matching the original pinned
hash/length, after all60 other files match; all61 then must match. On the passing
retry, the fresh minimal SDK already matched; that conditional repair branch
was not exercised. No production verifier or resource pin was relaxed.

Latest preserved root `proofscript@0.1.0-psc1.11`:3831381 bytes, SHA256
`4b7b88a395c00e1e757e7239026349d0bfbecc3e09b24ed8f6563d18f663a7c1`.
[SDK-free ZIP12718935961](https://github.com/dwijayuda/pskernel/actions/runs/40466372623/artifacts/12718935961)
is3909502 bytes, ZIP SHA256
`2cb9cb5aab74898148670b019bdc71c9b63db8c90c6d009a6b8bbea30b56c101`.
It remains the bundled compiler distribution; the new pilot tarballs are separate.

Next: carry explicit synthetic ownership through transforms and measure the complete
compiler dependency graph before extending the profile. Complete modular compiler,
portable planner self-hosting, modular G1/G2/G3/fixed points, seven-backend modular
application parity, macOS/Windows release and arranged human trial remain pending.
Existing qualified bundled executors/kernels/optional providers are unchanged.

## Preserved PR #193 reference

The following previous evidence/artifacts remain historical references; current
checkpoint and artifact identities are recorded above.

## Qualified milestone

`proofscript@0.1.0-psc1.11` supports Node >=22.23.3 and Bun >=1.4.4.
The bundled kernel's existing minimum determines the Node floor. User runtimes
have minimum ranges; exact CI versions and executable hashes are reproduction
evidence. Actual positives: Node22.23.3,24.21.0,26.12.1 and Bun1.4.4.
Actual older-runtime refusals: Node20.20.2,22.0.0 and Bun1.4.0.

CLI check/compile/build accept `--watch`, `-w` and `-watch`.
Initial project capture remains bounded and explicit. The supervisor polls declared
sources/config paths every500ms, debounces saves, serializes full checked attempts
and recaptures exact bytes. Repair after deletion/invalid input, atomic saves,
newly declared missing files and config edits are tested.
A private worker validates its request and captured-input identity, then recaptures
immediately before publication or compile/check stdout. Edits after that guard
queue the next rebuild. The trusted host callback can veto publication.
Success receipts remain JSON lines on stdout; progress/diagnostics use stderr.
Linux cancellation retains130/143, bounded kill escalation and actual native-child
reaping under Node/Bun. There is no semantic incremental cache or speed claim.

| Evidence | Exact result |
| --- | --- |
| [Full source40453128053](https://github.com/dwijayuda/pskernel/actions/runs/40453128053) | Success:15 jobs; benchmark skipped. Full job122023477972; gate122031524959. All37 finite Practical Core criteria qualified, zero blocked; scoped execution across seven backends. Branch headfdc52207fdf3d809ad99b05a5b738aca21b95139; tested PR merge55a2314e964f649ecaee2923766668a83450d5df. |
| [Installed/runtime40453124171](https://github.com/dwijayuda/pskernel/actions/runs/40453124171) | Success at the exact implementation commit. All prior gates retained;55 local/global CLI requests;11 full watch cases;16 applications/264 observations/eight global application cases;32 checked publications/143 refusals. |
| Runtime seal122035904319 | Seven rows: four supported runtimes, each four compiler engines/both grammars and two watch cases; three older-runtime refusals. Total32 positive compiler cases/eight runtime-watch cases. |
| Rust SDK preflight | All61 existing resource pins match a fresh minimal1.90.0 SDK. Production verifier unchanged. |
| Licensing |50 current owned source manifests and nine owned installable tarballs use Apache-2.0; two vendor SDK tarballs remain byte-identical. |

[Dated machine-readable receipt](docs/PSC1_RUNTIME_WATCH_QUALIFICATION_2026-10-27.json)
owns full identities, attempts, runtime binary hashes and retained boundaries.

## Installable artifacts

[Small installable ZIP](https://github.com/dwijayuda/pskernel/actions/runs/40453124171/artifacts/12713556078)
is 3909615 bytes, SHA256
`ace62708681e9272de4347c2a8365cd781222077e3bdf7d2167240a0c804a2d8`.
It contains the SDK-free root tarball, LICENSE/NOTICE, installation instructions
and seven runtime evidence records.
The tarball `proofscript-0.1.0-psc1.11.tgz` is 3831384 bytes, SHA256
`e2ab0b357a4f5836c021cb1d4b1772ee182811f532c1bfa864c94de14f22f6f2`.

[Full toolchain ZIP](https://github.com/dwijayuda/pskernel/actions/runs/40453124171/artifacts/12713391747)
is 206787702 bytes, SHA256
`d14b1530f8768359a980225f1b0ef8616dc9cfab9c640f83cc1a5611b9a9090d`.
It retains all eleven tarballs, including optional Rust/Wasm execution engines,
output SDKs, Python/PHP providers and full installed evidence.
These are unpublished artifacts. The [CLI guide](docs/guides/cli.md) describes
installation, target/engine distinction and explicit SDK selection.
Install commands never download a missing SDK or execute source-package plugins.

## Diagnosed failures and reproducible fixes

Actual Bun1.4.0 failed WebAssembly.Module.exports on the genuine generated Wasm GC
compiler in run40446238737, despite passing policy-only checks. Bun1.4.4 passes
the same workload. Keep export/no-delegation validation; require measured Bun>=1.4.4.
Versions1.4.1–1.4.3 remain unqualified/refused; no first-upstream-fix claim.

Live watch diagnostics in run40451321025 exposed a Rust target refusal at
lib/rustlib/components. Diagnostic40452300522 found the same cargo/std/rustc
components with different bookkeeping line order; the other60 pins matched.
Fresh minimal provisioning matched all61 unchanged pins. Exact-candidate replay
40452569506 then passed all11 watch cases and actual Bun1.4.0 refusal.
Canonical CI provisions that disposable SDK afresh and verifies every pin early.
User instructions use a separate explicit SDK; the CLI never rewrites user SDKs.

Older opaque receipt-timeout logs did not identify their target/error.
The later SDK reproduction identifies a concrete failure class; it does not
retroactively prove every earlier timeout's cause. Live per-case diagnostics and
all original assertions/limits are retained. Earlier hashes are preserved in the
dated receipt and never promoted to the corrected cohort.
The six existing dispatch/publication commands now have separate visible CI steps.

## Licensing, modular execution and preserved evidence

The owner selected Apache-2.0 for all ProofScript-owned source, documentation and
generated compiler components. Current packages include the grant and NOTICE.
Upstream copyrights/licenses, LEAN_LICENSE and other SDK notices remain intact.
Historical archives/receipts retain their original bytes and snapshot metadata.
The compiler license does not determine a user's application license.
[License policy](docs/reference/licensing.md).

[Modular distribution decision](docs/architecture/modular-compiler-distribution.md)
inspects the supplied PSC0 archive without execution. Its core/elab/erasure entries
re-export the compiler and declare independent compilation false.
Genuine source-owned JS/TS modules and cohesive exact-cohort packages are the
chosen final architecture. The module-graph producer/consumer pilot and its own
G1/G2/G3/fixed-point qualification remain pending. Qualified bundled executors
remain available; no textual split or facade completion claim.

Frozen G3 compiler payloads retain122 modules/4742 Core members and closure
`073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9`.
Development source has124 modules/4742 members. Source qualification and frozen
executor qualification remain distinct. This host/license milestone compares
compiler/kernel/provider payload bytes unchanged and makes no new frozen G2/G3
promotion. [Prior layout state](docs/history/AI_WORK_STATE_BEFORE_RUNTIME_WATCH_2026-10-27.md)
retains preceding exact artifacts, source identities and fixed-point references.

Official Lean4.35.0/`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`/trust0,
independent admission, strict original/transformed IR, exact source/body pairing,
negative tests, semantic fuel and memory/stack/lifetime policies remain.
Compiler/tools/G1 stay240s; independent checking stays120s; manual correctness
profiles remain separate from the240s performance target.
Kernel-Wasm stays official C++/Emscripten linear memory; compiler-Wasm stays GC.
Python/PHP remain optional; PSKernel-Core research remains separate.
Windows/macOS publication and final public release remain unqualified.
The arranged independent maintainer trial still awaits its participant.

[Roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md) is the authoritative remaining queue.
The next packaging slice is the finite genuine module-graph pilot; compiler
diagnostics/provenance, platform qualification and the human trial retain their
separate acceptance criteria. Final docs-only checks are visible on PR #193.

