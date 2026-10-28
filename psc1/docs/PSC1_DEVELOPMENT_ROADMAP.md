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

## Qualified first independent-development milestone

PR #201 implementation `5484a04df34de1bbcfa46a248b6a93ce510035d6` qualifies the
complete current 125-module editable `.ps` compiler with a private Node/V8
runtime and genuine precompiled official native checker. Dedicated run
[40618697529](https://github.com/dwijayuda/pskernel/actions/runs/40618697529)
passes bootstrap, isolated smoke, baseline B1/B2, genuinely changed-source C1/C2
with observed changed behavior, and exact same-source fixed points. The
[dated receipt](PSC1_INDEPENDENT_DEVELOPMENT_QUALIFICATION_2026-10-28.json)
binds source/tool identities and actual measurements. The broader
[source gate](https://github.com/dwijayuda/pskernel/actions/runs/40618701864)
also passes all 16 selected jobs and 37 finite Core criteria.

Ordinary standalone development needs no separately installed external language
tools; the runtime and independent checker are explicit prebuilt components.
The delivered `.ps` workspace is authoritative for its edits; repository Lean
bootstrap ownership is retained. The long correctness profile remains separate
from the unqualified 240-second full-compiler performance goal.

Next address measured rebuild latency, repository-wide canonical `.ps` source
ownership, broader real compiler edits and additional platform qualification.
[Architecture/dependency audit](PSC1_INDEPENDENT_DEVELOPMENT.md) and
[work state](../AI_WORK_STATE.md) record scope and remaining obligations.
Kernel research, a new runtime/backend and full modular partitioning are separate
streams, not prerequisites retroactively attached to this completed milestone.

## Preserved qualification: automatic core package installation

PR #198 continues from qualified PR #197 HEAD9d0e23c3. Cohort .13 makes proofscript
an umbrella over the20 existing core packages and moves the shared implementation
to the existing @proofscript/compiler package. Adapters depend on compiler, never
root. Python/PHP/native and engine/SDK payloads remain optional. The package build
and installed qualification check all runtime/peer edges for cycles, root-only
offline local/global installation, all core exports and shared runtime identity.
Linux [40507930195](https://github.com/dwijayuda/pskernel/actions/runs/40507930195) passes all53 finite package cases/125 exports at acbf4e70. [Exact receipt](PSC1_NPM_UMBRELLA_QUALIFICATION_2026-10-27.json). Root-only installation contains one executor pair; standalone installs may have a separate npm scope, also identity/hash/tamper checked. Final package40509034127 passes all53 cases/125 exports at892e1895. Full source40509034008 passes all16 selected jobs,37/37 Core criteria/zero blocked and scoped seven-backend execution. Superseded40507930222 was cancelled. Older .11 CLI40507924067 also passes all9 compatibility jobs; it is separate from the .13 artifact. Canonical compiler/kernel/host bodies remain
unchanged; no new compiler-internal modularization or fixed point is claimed.

## Preserved simple npm distribution (.12)

The latest user assignment supersedes further internal compiler partition work.
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
| 5 | Genuine modular JS/TS compiler packages | PR#195 v1 remains qualified. Explicit specialization/worker provenance and v2 five-source graph are qualified in PR#196 by [full40481560025](https://github.com/dwijayuda/pskernel/actions/runs/40481560025) at7d7ada7ad7d5f5ca1504527342888d929e1b9959:124 original/129 specialized/160 fused values,57 specialization origins,31 workers/eight specialized-worker chains,seven installable packages,29 v2 cases plus all28 v1 cases. Both grammars/JS/TS/Node/Bun, strict declarations, exact transform/admission/bundled-output comparison to immutable PR#195 and transaction/tamper checks pass. [Architecture](architecture/transform-provenance.md), [finite v2 contract](../test/modular/extended-contract.json). Full source passes16 selected jobs/37 Core criteria; generated JS service G1 passes ten selected cases. [Exact receipt](PSC1_TRANSFORM_OWNERSHIP_QUALIFICATION_2026-10-27.json). Further whole-compiler internal linking and modular G1/G2/G3/fixed points are deferred beyond the completed simple npm milestone. Separate actual graph measurement passes40488488194; intermediate partition implementation b9461a3c remains unqualified on its separate branch. No complete modular compiler claim. |
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
