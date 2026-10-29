# Installing the self-host-qualified modular compiler

Status: finite Linux installed preview qualified at b616e2fe, 2026-10-29 Asia/Jakarta.
[Installed CI40799529998](https://github.com/dwijayuda/pskernel/actions/runs/40799529998),
[source40799548941](https://github.com/dwijayuda/pskernel/actions/runs/40799548941) and
[retained CLI40799529980](https://github.com/dwijayuda/pskernel/actions/runs/40799529980) pass.
[Exact receipt](../PSC1_SELFHOSTED_INSTALLED_QUALIFICATION_2026-10-29.json).
The [roadmap](../PSC1_DEVELOPMENT_ROADMAP.md) is the remaining-work authority;
[work state](../../AI_WORK_STATE.md) records actual CI and any failures.

## Compiler payload and package identities

The installed preview0.1.0-psc1-modular.3 embeds the exact .2 G3 compiler graph
qualified in PR #209. It does not compile a different frontend or rewrite generated
bodies. The [input](../../scripts/modular-toolchain-input.json) pins both successful
JS/TS generation artifacts and their SHA256 digests.

[Provenance validation](../../scripts/modular-toolchain-provenance.mjs) checks the
committed M5 receipt against the actual archived reports, G2/G3 manifests,
independent admissions, graph inventories and all15 tarballs. Both producers must
match. No generated module is imported during that acquisition/validation step.

[Assembly](../../scripts/modular-toolchain-package.mjs) retains every original
generated file except explicitly versioned package metadata. The existing
[installed verifier](../../host-tools/executable/verify.mjs) requires the exact
source-graph projection and complete installed inventory before runtime import.
The .3 version distinguishes host/API overlays from original .2 candidate tarballs.
All qualified compiler sources, .13 and M4.1 remain preserved.

## User-facing layout

Install proofscript alone; its20 exact core dependencies are bundled.
The three-line psc launcher calls @proofscript/cli. Real generated bodies live
under their source-responsible @proofscript packages; no whole-compiler bundle
is hidden under dist/implementation. Stable proofscript/* subpaths avoid relying
on npm hoisting. Python/PHP and target SDKs remain optional.

Default independent checking uses the unchanged official Lean4.35.0 C++ kernel
compiled with Emscripten to linear-memory Wasm. Rust/Wasm are output backends;
older compiled compiler executors refuse this new source cohort. Neither source
nor project configuration chooses a checker, tool, graph or publication capability.

dist/COMPILER_SELFHOST_QUALIFICATION.json preserves the complete original compiler
receipt; compilerSelfHosting in metadata records its hash, source graph and finite
JS/TS fixed-point scope. Existing fullModularSelfHosting:false fields retain their
conservative local artifact/universal-distribution boundary. The explicit compiler
qualification is separate from current installed-host qualification and240s performance.

## Checking, failure and resource boundaries

Ordinary compilation/tools240s, checker120s, heap/stack, semantic fuel,
32MiB files/streams,128MiB graph/stage,8192 files/values,257 units and graph
traversal bounds remain unchanged. Longer self-host correctness requests stay
manual and separate; installation does not inherit an extended compilation timeout.

Missing/tampered files, manifests, owners, checker identities, packages or consumers
refuse before import/publication. Tests retain runtime/peer cycle refusals,
unsupported ABI/source-cohort refusals and previous-generation preservation.
This relies on trusted bootstrap and stable resources; hashes are not a signature,
sandbox, totality or semantic-preservation theorem.

## Qualification and ZIP

One exact tarball is shared by package smoke, seven-target/global/watch,
boundary/IO/types and real application jobs on Node/Bun. Additional Node24/26
jobs install that same tarball and run real compiler/kernel tests. Full source
qualification remains a separate required gate.

The delivery job reads only successful current-head artifacts and the terminal
PR source gate. It builds a ZIP without rebuilding the package, verifies all ZIP
checksums, installs its extracted root with an empty npm cache/offline registry,
then executes npm psc help/init/check/build and checks the produced answer42.
The ZIP includes notices, installation instructions, focused receipts and hashes.
Matching optional target/provider resources are delivered separately.

Other-platform consumers/durability, native binary reproduction, standalone checked
host, full M3 semantic-family execution for this installed cohort,240s self-compilation,
registry publication and universal release are separate gates.

## Download and verified use

[Verified artifact](https://github.com/dwijayuda/pskernel/actions/runs/40799529998/artifacts/12867276735).
Extract GitHub's outer artifact ZIP, then the inner installable ZIP. Its INSTALL.txt
and SHA256SUMS accompany proofscript-0.1.0-psc1-modular.3.tgz.

```sh
npm install --offline --ignore-scripts ./proofscript-0.1.0-psc1-modular.3.tgz
npx --no-install psc --help
npx --no-install psc init
npx --no-install psc check
npx --no-install psc build --out out --publication-protocol portable-file
```

All20 core packages and the default independent kernel are included. This is an
unpublished preview, so installing the registry package does not select this ZIP.
The same tarball passes Node22.23.3/24.22.1/26.12.1 and Bun1.4.4; Node/Bun both
engines pass128 seven-target builds,32 real-application builds/528 cases and the
retained watch/resource/typing/IO scopes. The source gate qualifies37/37 finite
Core criteria. Other-platform consumers/publication remain unqualified.
