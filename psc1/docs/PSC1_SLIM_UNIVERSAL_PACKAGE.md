# Slim universal ProofScript package milestone

The new unpublished `proofscript@0.1.0-psc1.4` root is **3,703,113 bytes**,
compared with 62,181,083 bytes for the preceding integrated root: a **94.04%**
reduction. It embeds the unchanged qualified G3 JS and TS compilers and the genuine
official Lean4.35 C++ linear-memory Wasm kernel. Rust and compiler-Wasm execution
are optional packages. No native compiler, native kernel, Rust executor,
compiler-Wasm executor, platform formatter or Python/PHP payload is in the default
root. There is no install-time build, SDK download or executor fallback.

## Qualified download and installation

[Download the five-tarball artifact](https://github.com/dwijayuda/pskernel/actions/runs/40166882825/artifacts/12588024057).
Artifact ZIP SHA256:
`163ca39fa564e407b1008e25cdfd358f0516e6af669963ceef585bd4c628e708`.

Extract and enter `tarballs/`. The root tarball is
`proofscript-0.1.0-psc1.4.tgz`, SHA256:
`f198538c5396d25cc9944c50c698a00bea1685ce997b55e766dd4582fddf794e`.
Use Node **22.23.3**, matching the qualified transports.

```sh
npm install --offline --ignore-scripts ./proofscript-0.1.0-psc1.4.tgz
npx --no-install psc --identity
npx --no-install psc check Main.lean
npx --no-install psc compile Main.ps --engine ts
npx --no-install psc build Main.ps --out dist/app
```

`check` and `compile` use the generated JS executor by default and the real Wasm
kernel. `compile` prints JSON containing checked JS source and its receipt.
`build` publishes a complete immutable JS generation on Linux using the original
lock, before/after resource checks, file/directory fsync and atomic current-pointer
commit. Non-Linux publication is explicitly refused; use checked compile API/stdout.
The package format and checked-compilation path use portable Node APIs, but this
milestone is **executed and qualified on Linux only**. It is not a macOS/Windows
whole-toolchain release qualification.

For imports, supply `--project project.json` containing the ordered captured
closure `{entryModule, sources:[{module,kind,text}], assurance?}`.
Project files cannot select output paths, executors or checker tools.
Those require explicit CLI options. Source decoding is fatal UTF-8 and preserves
BOM bytes before the existing frontend; unsupported syntax is refused, not normalized.

## Explicit optional executors

The archive includes these unchanged qualified packages:

| Package | Tarball | SHA256 |
| --- | --- | --- |
| @proofscript/compiler-wasm@0.1.0-psc1.3 | proofscript-compiler-wasm-0.1.0-psc1.3.tgz | 340b90eca1d08b1f20b4ca618358d7ac7b7931371f2232eb6aa54101099fcc83 |
| @proofscript/compiler-rust-linux-x64@0.1.0-psc1.3 | proofscript-compiler-rust-linux-x64-0.1.0-psc1.3.tgz | 551f150d09d98fe48312c40cdaa793522534c84fff250097199ff75b467530f7 |
| @proofscript/pskernel-lean@4.35.0 | proofscript-pskernel-lean-4.35.0.tgz | c8ffd49220328ec2a96ac1c4388d828df255cc21537b2484b523710fe6c17371 |
| @proofscript/pskernel-lean-wasm@4.35.0 | proofscript-pskernel-lean-wasm-4.35.0.tgz | b203982eeb851b797f7a35a8a66f883472a6130f24f36c26b8931bd5e0881511 |

```sh
npm install --offline --ignore-scripts ./proofscript-compiler-wasm-0.1.0-psc1.3.tgz
npx --no-install psc build Main.ps --engine wasm-core --out dist/wasm-executor

# Rust execution currently requires Linux x64/glibc:
npm install --offline --ignore-scripts ./proofscript-compiler-rust-linux-x64-0.1.0-psc1.3.tgz
npx --no-install psc build Main.lean --engine rust --out dist/rust-executor

# Optional independent native comparison:
npm install --offline --ignore-scripts ./proofscript-pskernel-lean-4.35.0.tgz
npx --no-install psc build Main.ps --kernel both --out dist/dual
npx --no-install psc kernel check admissions.json --provider both
```

The resolver accepts only the closed engine inventory, exact package version,
index/manifest/resource hashes, source closure and executable identities copied
from successful qualified artifacts. It resolves ordinary local/global npm
packages; it never downloads one or loads a plugin named by source text.
An absent, wrong-version, corrupt or unsupported executor fails explicitly.
A missing/corrupt/refusing Wasm checker never falls back to the native checker.

The optional compiler-Wasm uses PSC1's existing GC architecture. It is distinct
from the **linear-memory official C++ Lean kernel** included in the root.
All executors use the same existing 120-module compiler source, frontend,
elaborator, checked IR and strict original/transformed IR verification pipeline.
No compiler implementation has been rewritten.

## Typed public API

```js
import {compile, build, getCompilerMetadata} from 'proofscript';

const options = {
  entryModule: 'Entry',
  sources: [{module: 'Entry', kind: 'lean', text: 'def answer : Nat := 42\n'}],
};

console.log(getCompilerMetadata());
const checked = compile(options);             // checked.source is admitted JS
const fromWasm = compile({...options, engine: 'wasm-core'}); // optional package
const published = build({...options, out: 'dist/app'});     // Linux publication
```

`createIndependentKernelToolchain()` preserves a typed independent-kernel entry
point and defaults to Wasm. Explicit `provider:'both'` checks identical canonical
bytes with both actual providers. `checkCanonicalAdmissions(json)` checks
canonical admissions, not source or a compiler semantic-preservation proof.

`compileCandidate({...options, engine:'js', target:'rust'})` also exposes the
existing JS/TS/Rust/Wasm-core **candidate** mappings. It returns
`logicalAdmission:'not-run'` and `publicationAuthority:false`. It is not checked
non-JS publication. Checked compilation/publication remains JS, as in the preceding
generated package. Component/optional-provider dispatch remains future work.
The preceding native distribution, including all seven output mappings and
matching optional Python/PHP providers, remains preserved in
[its install guide](PSC1_KERNEL_PACKAGES.md) and original qualified artifact;
the new slim flavor does not overwrite or relabel it.

## Actual qualification

[Linux package run40166882825](https://github.com/dwijayuda/pskernel/actions/runs/40166882825)
at `0a717520110c673006d3f5f5d7627e59d5853f62` passed:

- 20 real compiler cases: all four executors and both source grammars.
- 12 local/global CLI cases, with SDKs absent and optional packages absent initially.
- 48 candidate target/grammar mappings, including 16 with optional packages absent and an actual checked dual-provider compile.
- 14 genuine native/Wasm acceptance/rejection comparisons.
- 36 source, integrity, version, project-authority, policy and publication-fault refusals, preserving prior output.
- Packed public TypeScript API/type-refusal checks.

Normal source run40166884643 PASSED at code
`0a717520110c673006d3f5f5d7627e59d5853f62`: full job121091590002 and final
gate121096509883,37/37 Practical Core criteria,0 blocked,all seven backends/both
grammars,minimum Python and installed native npm/source libraries.
Tested merge`559ea387ad22999b7b6aedd073fd61c8a0c1bc28` and code HEAD share
tree`0a232bbdf67f6f8de60950142af3be17f1231e4d`.
Full artifact12589082030 ZIP SHA256
`1c0d30be97a68c7ca3fb25667dd8412dbb477d8df447960d12fd5b88764700a2`.
This is separate from slim package40166882825 and does not imply complete
cross-platform or checked non-JS generated publication qualification.

[The exact receipt](PSC1_SLIM_UNIVERSAL_QUALIFICATION_2026-10-25.json) retains both
package and source evidence.
No new G1/G2/G3 runs are needed for unchanged frozen payloads; the original
self-host/fixed-point identities are preserved. Kernel/checker120s,
normal compiler/tool240s, strict IR, semantic fuel and memory/stack/lifetime
policies are unchanged. No merge or npm publication is authorized.

[Roadmap](PSC1_DEVELOPMENT_ROADMAP.md) and
[executable continuation](PSC1_SLIM_UNIVERSAL_CONTINUATION.md) distinguish this
Linux-qualified package milestone from the remaining complete universal release.
