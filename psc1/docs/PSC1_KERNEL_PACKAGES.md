# Lean4.35 independent kernel packages

The native `@proofscript/pskernel-lean@4.35.0` candidate is install-qualified on
Linux x64/glibc, Linux arm64/glibc, macOS x64, macOS arm64 and Windows x64.
Routine development remains Linux; these macOS/Windows jobs are separate release
qualification. The same tarball passes offline local/global installs on all five.
No package has been published to npm.

Download [artifact12584263337](https://github.com/dwijayuda/pskernel/actions/runs/40155475188/artifacts/12584263337)
and extract `proofscript-pskernel-lean-4.35.0.tgz`.
The tarball is6446239 bytes, SHA256
`c8ffd49220328ec2a96ac1c4388d828df255cc21537b2484b523710fe6c17371`.
Artifact ZIP SHA256
`a5cefb58f4eaf4a558b390294d24c555b763c3a0ef7f7e68aab7cfc324f58b2f`.

```sh
npm install ./proofscript-pskernel-lean-4.35.0.tgz
```

```js
import {createKernel} from '@proofscript/pskernel-lean';
const kernel = await createKernel();
console.log(kernel.metadata);
const result = await kernel.checkCanonicalAdmissions(canonicalAdmissionsJson);
if (!result.accepted) throw new Error(result.errorKind);
```

The input is PSC1 canonical checked admissions v2, not Lean/ProofScript source.
A rejected admission returns `accepted:false`; integrity, identity, process and
resource failures throw. Node22.23.3 or newer is required. No SDK, downloads or
compilation run at installation. An absent architecture fails explicitly.

| Native target | Uncompressed binary bytes |
| --- | ---: |
| linux-x64 | 4079232 |
| linux-arm64 | 4160016 |
| darwin-x64 | 2771584 |
| darwin-arm64 | 2798528 |
| win32-x64 | 4616704 |

Every binary passes14 actual acceptance/rejection cases against the same-source
official Lean4.35 reference, and standalone execution without the Lean SDK/build
tree. Every packed platform passes28 local/global cases through both public APIs,
plus corruption refusal. Exact commits, source closure, binary/archive hashes and
job IDs are in [the receipt](PSC1_KERNEL435_QUALIFICATION_2026-10-25.json).
The native initialization/link strategy reuses archived branch0408f18b; it removes
unused compiler initialization/Lake linkage, retaining official kernel code,
trustlevel0, finite2000000-heartbeat/20000-recursion checks and all provider tests.

The `@proofscript/pskernel-lean-wasm@4.35.0` upgrade remains INCOMPLETE:
[real C++ linear-memory build40154206987](https://github.com/dwijayuda/pskernel/actions/runs/40154206987)
is active. Do not install the repository's old4.34 bytes as4.35. The new package
must pass genuine native/Wasm parity and offline installed platform gates first.
Emscripten6.0.9 and linear memory remain required; this kernel does not use Wasm GC.

Core host integration is implemented and passes32 host-boundary regressions plus
10 Rust transport regressions in40155831321. It adds pinned kernel commands and
an optional Wasm check of identical captured admissions before generated output
publication. Those changes await actual integrated native/Wasm package execution;
they are not a Wasm qualification claim.

The existing [four-engine compiler package](PSC1_GENERATED_PACKAGE.md) remains a
qualified Linux x64 candidate. Five-platform kernel qualification does not qualify
the complete compiler toolchain on those platforms. Native compiler/Rust engine
assets, launcher/publication behavior and installed backend tests remain required
for the final cross-platform release. Do not merge or publish without qualification
and authorization.
