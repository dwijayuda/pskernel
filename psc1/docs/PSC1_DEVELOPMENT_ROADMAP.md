# PSC1 development roadmap

Updated 2026-10-28 Asia/Jakarta. This is the authoritative remaining-work queue.
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

The dependency-ordered queue is: finish M3's full retained semantic/library and
seven-backend corpus through the modular engines; M4 checked
root-only umbrella/thin CLI/watch and coherent graph publication; portable module
generation within the same compiler; then M5 new modular G1/G2/G3/fixed points and
applicable platform/publication gates. M3 has finite partial qualification;
M4/M5 remain incomplete. The .13 API/distribution stays the default reference.
Existing pilot tests/evidence remain; expanding experimental pilot
profiles is not a prerequisite. The stopped PR #203/prototype branches are
preserved, not promoted.

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
| 5 | Fully modular executable compiler | Planned, not implemented/qualified: [current production plan](architecture/executable-package-modularity.md), finite M0-M5 stages and acceptance. Preserve proofscript umbrella/thin psc CLI, existing package names, acyclic source-responsible implementations and all checking/resource policies. Qualified .13 remains the release reference. Pilot expansion and PR #203's prototype are deferred. Prior [v1 qualification](PSC1_MODULAR_PILOT_QUALIFICATION_2026-10-27.json) and [v2 ownership qualification](PSC1_TRANSFORM_OWNERSHIP_QUALIFICATION_2026-10-27.json) retain only their stated component scopes; no complete modular compiler or new fixed-point claim. |
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
