# ProofScript and independent Lean 4.35 kernel packages

A separate **3.70 MB slim universal-format root** is now qualified on Linux.
See [the new install guide](PSC1_SLIM_UNIVERSAL_PACKAGE.md). This document preserves
the preceding native/all-seven-output distribution and its qualification.


The integrated, unpublished Linux x64/glibc package uses
`@proofscript/pskernel-lean-wasm@4.35.0` as the default independent checker.
It is the official Lean C++ kernel compiled with Emscripten 6.0.9 and linear
memory. Native checking is an explicit `native` or `both` choice; an absent,
corrupt or refusing Wasm checker never causes a native fallback. PSC1's separate
compiler Wasm bundle retains its existing GC architecture.

## Download and install the qualified integration

[Download the seven-package artifact](https://github.com/dwijayuda/pskernel/actions/runs/40161362270/artifacts/12586394254)
from successful run 40161362270, source
`cd6a16ba1c9efc5668507ee6b9eb125f2d3b2fad`.
Artifact ZIP SHA256:
`426c62ce4ca8fb87570d1ba169c681004d7da5e5faea80e2b3fbe07c9ef04b52`.
After extracting, enter `kernel435-core/tarballs/`.

| Package | Tarball | Bytes |
| --- | --- | ---: |
| proofscript | proofscript-0.1.0-psc1.3.tgz | 62181083 |
| @proofscript/pskernel-lean-wasm | proofscript-pskernel-lean-wasm-4.35.0.tgz | 582533 |
| @proofscript/pskernel-lean | proofscript-pskernel-lean-4.35.0.tgz | 6446239 |
| @proofscript/compiler-wasm | proofscript-compiler-wasm-0.1.0-psc1.3.tgz | 1370182 |
| @proofscript/compiler-rust-linux-x64 | proofscript-compiler-rust-linux-x64-0.1.0-psc1.3.tgz | 12917609 |
| @proofscript/backend-python | proofscript-backend-python-0.1.0-psc1.3.tgz | matching optional output provider |
| @proofscript/backend-php | proofscript-backend-php-0.1.0-psc1.3.tgz | matching optional output provider |

Core tarball SHA256:
`02c5db1989adf3ada1ad39318c3efc05498a3f3132b2f21fa6a564aceea3f60a`.
Use Node **22.23.3** for the currently qualified compiler transports.
Core includes both matching kernel packages offline; installation builds nothing
and downloads no compiler SDK. It still embeds the four compiler engines and
native compiler assets during the transition to a slim final package split.

```sh
npm install --offline --ignore-scripts ./proofscript-0.1.0-psc1.3.tgz
npx --no-install psc kernel --identity
npx --no-install psc kernel check admissions.json
npx --no-install psc kernel check admissions.json --provider both
npx --no-install psc check Main.lean
npx --no-install psc generated build Main.ps --engine ts --out dist/generated
npx --no-install psc generated build Main.lean --engine wasm-core --out dist/wasm-executor --kernel both
```

`--engine js|ts|rust|wasm-core` chooses the executing compiler. Generated CLI
publication currently emits **JS**. The preserved native `psc build` path retains
JS/TS/Rust/Wasm core/component and matching optional Python/PHP output providers.
Engine qualification is separate from output-target coverage. Source checking
captures canonical admissions once; native publication also checks its exact
staged graph with default Wasm before committing the generation.

For optional Python/PHP output, install the matching tarball alongside the root
tarball. These providers are not default dependencies.

```sh
npm install --offline --ignore-scripts ./proofscript-0.1.0-psc1.3.tgz ./proofscript-backend-python-0.1.0-psc1.3.tgz
```

Integrated run 40161362270 passes 14 real native/Wasm acceptance/rejection
comparisons, 20 compiler cases, 24 CLI/JSON application builds and 88 observations,
24 generated refusal/tamper cases with previous-output preservation, eight
explicit dual checks, two native publication cases, missing-policy refusal and
installed public TypeScript API checks. The native compiler and native checker
are unavailable during default generated cases. Both actual kernels also accept
the unchanged frozen 120-module compiler admission graph in 10734 ms combined.
This is logical rechecking of an already qualified graph, not a new full-chain
replay or formal compiler-preservation proof.

Fresh global install [run 40160640974](https://github.com/dwijayuda/pskernel/actions/runs/40160640974)
also passes eight actual global-bin builds (all four engines and both grammars),
offline with an empty cache, native compiler/checker unavailable, prior outputs
preserved after bad source and corrupt default Wasm refused.

The latest run also refuses four missing/conflicting default-policy declarations
across generated builds, source checks and native publication (12 refusals), with
the native checker available and previous outputs preserved. Both installed local
and fresh global tests execute inside the same package qualification job.

## Kernel APIs and five-platform evidence

Both kernel tarballs separately pass offline local/global installation on Linux
x64/arm64 glibc, macOS x64/arm64 and Windows x64. Each platform executes 28 actual
acceptance/rejection API cases and corruption refusal without a Lean SDK.
Native checks cover synchronous and asynchronous APIs. Wasm checks use the
asynchronous API.

```js
import {createKernel} from '@proofscript/pskernel-lean-wasm';
const kernel = await createKernel();
const result = await kernel.checkCanonicalAdmissions(canonicalAdmissionsJson);
if (!result.accepted) throw new Error(result.errorKind);
```

The input is canonical checked admissions v2, not source code. Logical rejection
returns `accepted:false`; resource, process and integrity failures throw.
The standalone native package exposes the same `createKernel` pattern.

The root's typed `proofscript/kernel` API
`createIndependentKernelToolchain({root: installedProofscriptDirectory})`
defaults to Wasm. Explicit `provider:'both'` checks the identical captured bytes
with both independently pinned providers and requires agreement.

| Kernel tarball | SHA256 | Qualification |
| --- | --- | --- |
| Wasm | b203982eeb851b797f7a35a8a66f883472a6130f24f36c26b8931bd5e0881511 | run 40158859386, all five platforms |
| Native | c8ffd49220328ec2a96ac1c4388d828df255cc21537b2484b523710fe6c17371 | run 40155475188, all five platforms |

The genuine Wasm build took 1:08:25, peak RSS 1521832 KiB; its sealed toolchain
cache avoids repeating that build for unchanged source. Module size is 2212007
bytes. Native binary sizes are 4079232/4160016 bytes for Linux x64/arm64,
2771584/2798528 for macOS x64/arm64, and 4616704 for Windows x64, all below
7000000 bytes. The slim build reuses the archived narrow-import/kernel-only-init
strategy; it retains official kernel semantics, trust level 0, finite 2000000
heartbeat/20000 recursion limits and real official-reference parity checks.

## Separate compiled compiler bundles

The artifact also includes genuine frozen G3 execution bundles, produced from
the same compiler source; neither is a handwritten replacement compiler.

```sh
npm install --offline --ignore-scripts ./proofscript-compiler-wasm-0.1.0-psc1.3.tgz
# Linux x64/glibc only:
npm install --offline --ignore-scripts ./proofscript-compiler-rust-linux-x64-0.1.0-psc1.3.tgz
```

Both export typed `compileCandidate(unifiedCompilerServiceV2Json)` and
`psCompilerJsServiceCandidate(capturedJsServiceRequestJson)`. These return
candidate data with **no proof admission or publication authority**.
Use the root toolchain's independent checker, strict IR and publication boundary.
Their standalone API is not yet a root CLI optional-bundle discovery mechanism.

Run 40158598464 executes five genuine corpus cases and two refusal cases on each
of five platforms for the Wasm bundle, and both bundles on Linux x64 (ten cases,
four refusals). Compiler Wasm is portable; the Rust bundle currently refuses
unsupported platforms. Every payload and bounded transport is pinned and verified.

The exact code checkpoint also passes the full Linux source gate
[40161364575](https://github.com/dwijayuda/pskernel/actions/runs/40161364575):
37/37 Practical Core criteria, zero blocked, all seven backends/both grammars,
minimum Python and installed native npm/source-library tests. This is separate
from the new integrated G3/default-Wasm artifact qualification above.

## Remaining release boundary

The complete compiler tarball is still Linux x64/glibc; five-platform kernels
and Wasm candidate execution do not qualify the whole toolchain there.
Native compiler binaries also pass source/admission checks on Linux arm64,
macOS x64/arm64 and Windows x64 (run 40157017833), a narrower result than backend
publication or installed toolchain release.

The final release still requires portable transactional publication, a slim
universal JS/TS root with optional execution-bundle selection, Rust payloads and
supervision on additional platforms, generated non-JS output publication and
complete platform release tests. Every exported file/type/bin must actually
exist. No package is published and neither PR is merged.

[Machine-readable qualification](PSC1_KERNEL435_QUALIFICATION_2026-10-25.json),
[distribution contract](../NPM_DISTRIBUTION_CONTRACT.json),
[roadmap](PSC1_DEVELOPMENT_ROADMAP.md) and
[executable continuation](PSC1_KERNEL435_CONTINUATION.md) record exact boundaries.
