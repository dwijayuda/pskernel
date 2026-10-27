# PSC1 AI work state

Updated 2026-10-27 Asia/Jakarta. Active draft [PR #193](https://github.com/dwijayuda/pskernel/pull/193),
branch `feat/psc1-watch-runtime-20261027`, starts from PR #192 at
`94e0c13f6a4b434f73c859cc0c716cb6fb8d1340`.
The qualified implementation is `fdc52207fdf3d809ad99b05a5b738aca21b95139`.
Fetch live HEAD and CI before changes. Preserve single-parent, expected-HEAD,
non-force history. Development/builds/tests use connected GitHub and Linux Actions.
No merge or npm registry publication is authorized.

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
