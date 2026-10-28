# PSC1 AI work state

Updated 2026-10-28 Asia/Jakarta. Branch `feat/psc1-executable-packages-20261028`, based on
PR #204 HEAD `b400552324956d9c3a684c9231f60f70066e1629`. GitHub/Linux CI only; expected-HEAD/non-force
updates. No merge or npm publication.

## Active: execute the production modularity plan

The user has resumed implementation of
[the production plan](docs/architecture/executable-package-modularity.md).
proofscript remains the installation umbrella and psc its thin CLI.
The experimental pilot/prototype remains deferred; no pilot expansion was resumed.

Current M0/M1 slice removes the real source-level driver return edges:
- Shared Error/failure data move unchanged to BackendCommon.ServiceError.
- Each core backend gets a pure Emit module containing its exact existing emitter body.
- Legacy CompilerService entry points remain compatibility wrappers.
- Unified orchestration imports the pure emitters and the compiler driver explicitly.
- Logical names/bodies are preserved, registered Lake roots updated, source IDs measured anew.

[Production contract](EXECUTABLE_PACKAGE_CONTRACT.json) defines finite ownership
cases and remaining M0-M5 acceptance. The source audit verifies exact baseline
bodies and an acyclic package source graph; it does not claim transformed runtime
ownership. Native tests build pure emitters without importing the frontend driver,
emit a strict-IR fixture, exercise actual JS/TS outputs and validate Wasm bytes.
Existing unified/compiler/kernel/backend gates remain.

The source/emitter boundary passed focused Linux runs 40658954932 (ec4218b5) and
40659282400 (a8e22de3). This is source-layer/emitter evidence only. Linux focused workflow
psc1-executable-packages.yml will record actual results. This is real source-layer
work, not completion of the complete executable graph, npm integration or new
G1/G2/G3/fixed points. Production M2 implementation is now in progress: shared structured model/renderers
are extracted with pilot profiles unchanged; a host-only production builder captures
all 126 current compiler source modules, carries owners through the existing checked
transforms, orders computed initializers by transitive dependencies, and emits real
JS/TS files under existing package names. It requires exact external Lean admission
before emission, strict TypeScript, printed-graph audits and tamper negatives.
This candidate pipeline is awaiting Linux CI and is not a promoted npm release.
The planner now passes all eight ordering/negative tests on Linux. Run 40661038464
(5fa6c4fb) builds all new native tools, executes the retained pilot build and unified
entry, and passes all ten ownership/body/profile checks and strict emitter consumers.
Whole-graph Node orchestration then fails before capture: the workflow installed the
root SDK but omitted the existing locked host-tools @babel/parser dependency. Install
that existing lockfile too; no new parser or dependency version is introduced.

Iterate on build/psc1-executable-packages-20261028 to avoid restarting the PR's full
source/package gates for each build fix. PR #205 remains at 5fa6c4fb until a focused
production graph run passes, then fast-forward its branch non-force after a live
expected-HEAD check. Current M2 graph/type/consumer gates remain unqualified.

## Preserved reference and policies

Qualified .13/PR #198 is unchanged as a reference artifact:53 package cases/125
exports,16 source jobs/37 Core criteria, default genuine Lean linear-memory Wasm,
optional Python/PHP/native/engines/SDKs. Exact prior receipt:
docs/PSC1_NPM_UMBRELLA_QUALIFICATION_2026-10-27.json.
Frozen source122 modules/closure073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9
retains only its original qualifications. New source moves require new identities.

Official Lean4.35.0, strict original/transformed IR, source/body pairing, negative
tests, semantic fuels, memory/stack policies and 240s compiler/120s checker limits
remain. No kernel, runtime representation or language semantic rewrite. Apache-2.0
owned code and upstream notices retained. Prototype branches/PR #203 remain
preserved and deferred; no source/history reset.
