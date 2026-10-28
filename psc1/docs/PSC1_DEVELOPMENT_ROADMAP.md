# PSC1 development roadmap

Updated 2026-10-29 Asia/Jakarta. This is the authoritative remaining-work queue.
Practical Core v1 remains frozen at14 feature families and 37 finite criteria.
Completed detail is preserved in [the previous roadmap](history/ROADMAP_BEFORE_LAYOUT_2026-10-26.md)
and [dated evidence](evidence/README.md).

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

M4 now qualifies the finite installed Linux preview described below. The next
dependency is M5: portable module planning/emission in the same compiler, exact
graph/package reproduction, then genuine new modular G1/G2/G3/fixed points.
The qualified .13 distribution stays the default reference. Pilot expansion
remains deferred; the stopped PR #203 and prototype history are preserved.

## M5: portable G1/source qualified; new generations pending

PR #209 continues from PR #208/d53b43c2. At canonical source17ce1991
and tested controller77961851, the133-module closure is
1f2f1e4a035a32faa6035aeae000e9c92305f8fb34e58b8cc2210504e38213cb.
Native/pure G1 runs40748275409/40749484426 independently admit4905 logical
members and reproduce134 actual units/15 packages, exact original/transformed IR,
ownership and all immutable renderer bytes. The1131-file graph is103951941 bytes.
Native G1 takes112.798s/1210604KiB RSS (repeat123.453s/1207588KiB), under240s.

Full source40749527957 passes all16 selected jobs,37/37 finite criteria,
zero blocked and14 scoped target bundles at77961851 (merge3c78e1c1).
Ownership/policy40755976488 passes all11 historical/current identity cases and
the unchanged ordinary/1800s/3600s profile rules. Existing.13 npm qualification
40749527892 passes separately. These results do not establish new fixed points.

Initial generated G2 run40749484847 fails after1557–1566s at the introduced
1800 CPU-second guard, before the defined1800s wall deadline. Actual CPU
diagnostics40754131717 retain the exact whole-compiler source workload.
The user authorizes a sensible increase: diagnostic336ab495 launches
40755246954 with3600s G2/G3 wall-clock requests and160-minute Linux jobs,
restoring the original Node wall policy.1800s correctness and240s performance
remain separate; G1/corpus240s, checker120s and all memory/stack/fuel/byte bounds
remain. G2/G3/fixed points are pending. Candidate version.2 does not promote
the qualified M4.1 umbrella or replace.13.
[Exact partial receipt](PSC1_PORTABLE_MODULAR_QUALIFICATION_2026-10-29.json),
[architecture](architecture/portable-modular-generation.md).

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
| 5 | Fully modular executable compiler | M1/M2 candidate graph and finite M3 application/semantic/seven-target execution are qualified in PR #205–#207; see the [current plan](architecture/executable-package-modularity.md) and [M3 receipt](PSC1_MODULAR_SEMANTIC_QUALIFICATION_2026-10-28.json). M4 finite Linux installed umbrella/thin CLI/watch is qualified in PR #208 ([receipt](PSC1_MODULAR_INSTALLED_QUALIFICATION_2026-10-28.json)); M5 portable reproduction/new generations remain incomplete. Preserve .13, existing package names, independent checking and resource policies. Pilot expansion stays deferred. No new modular fixed-point/release claim. |
| 6 | Component String/IO and export selection | Pending: reuse shared/native ABI; both grammars/four engines, actual validation/execution, exact exports and refusals. Public component ABI currently Bool only. |
| 7 | Full Python/PHP practical applications | Pending: real CLI/JSON/file/multi-module observations against checked reference; retain corpus/Unicode/integer/loop/IO tests. Providers remain optional. |
| 8 | Automatic source-package capture | Pending: bounded deterministic order, exact identities, cycle/missing/stale refusals, real multi-package applications. Metadata never executes code or grants authority. |
| 9 | Native publication committed-outcome parity | Pending: retain transaction and explicitly report post-commit uncertainty. No false rollback guarantee. |
| 10 | Additional platform consumers/publication | Blocked on actual permitted platform execution. Linux does not qualify macOS/Windows durability or SDK/provider consumers. |
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
