# Install the qualified checked-output candidate

[Download the eight-tarball artifact and evidence](https://github.com/dwijayuda/pskernel/actions/runs/40238538092/artifacts/12616533098).
ZIP SHA256:
`fc204d5e043b3c45776307522a24cfca846a50794b11cf7dddbcf321105c2d35`.
The qualified host/package commit is `1b0e695e67fd76bfd8bb43901eebc35058a0fc1a`.
Use Node **22.23.3**. Extract the ZIP and enter `tarballs/`.
Packages are installable local artifacts; none has been published to npm.

Authenticated GitHub CLI download is also available:

```sh
gh run download 40238538092 --repo dwijayuda/pskernel --name psc1-checked-publication-1b0e695e67fd76bfd8bb43901eebc35058a0fc1a
```

## Root and SDK-free output

```sh
npm install --offline --ignore-scripts ./proofscript-0.1.0-psc1.6.tgz
npx --no-install psc --identity
npx --no-install psc check Main.lean
npx --no-install psc compile Main.ps --engine ts
npx --no-install psc build Main.ps --target wasm-core --publication-protocol portable-file --out dist/wasm
```

The root is **3,761,565 bytes**, SHA256
`4657ecbf3d4afaf3438d115ec24e60d9c4af80e3602c8ee19ed93e45104810dd`. It embeds the same qualified JS/TS G3 executors and genuine
official Lean4.35 C++/Emscripten **linear-memory** Wasm checker.
Compiler-Wasm remains GC and its compiler executor is optional.
JS/Wasm output and ordinary compiler execution need no output SDK.
The default output remains JS and the default kernel remains Wasm.

## Explicit compiler executors and checking

```sh
npm install --offline --ignore-scripts ./proofscript-compiler-wasm-0.1.0-psc1.6.tgz
npm install --offline --ignore-scripts ./proofscript-compiler-rust-linux-x64-0.1.0-psc1.6.tgz
npm install --offline --ignore-scripts ./proofscript-pskernel-lean-4.35.0.tgz
npx --no-install psc build Main.lean --engine rust --kernel both --out dist/dual
```

Rust compiler execution is qualified for Linux x64/glibc. The native checker
selection is explicit; missing or refusing default Wasm never falls back to native.

## Optional checked output consumers

TS output requires both SDK tarballs in an offline install:

```sh
npm install --offline --ignore-scripts ./typescript-7.0.2.tgz ./typescript-typescript-linux-x64-7.0.2.tgz
npx --no-install psc build Main.ps --target ts --publication-protocol portable-file --out dist/ts
```

Rust output requires the separate consumer package and an explicitly provisioned,
matching official Rust1.90.0 toolchain. CI uses a minimal toolchain profile:

```sh
npm install --offline --ignore-scripts ./proofscript-rust-target-consumer-linux-x64-0.1.0-psc1.6.tgz
rustup toolchain install 1.90.0 --profile minimal
npx --no-install psc build Main.lean --target rust --publication-protocol portable-file --out dist/rust
```

The resolver checks the exact selected SDK resource inventory, not version text
alone. An augmented or otherwise different SDK may require a matching isolated
installation and an explicit `--rust-toolchain-root`.
SDK provisioning is a separate user action, never an npm install script or a
compiler request. Current TS/Rust output consumers are qualified on Linux x64.
SDK versions, files, dependencies and tarball hashes are in the receipt.

Build returns immutable `artifact` and `runtimeArtifact` paths. Rust runtimeArtifact
is a checked rlib for linking, not a standalone executable. TS runtimeArtifact is
emitted ESM; Wasm runtimeArtifact is the existing typed loader.
See [checked publication](PSC1_CHECKED_PUBLICATION.md) for API and linking examples,
source encodings, supported ABIs, reader paths and committed-durability outcomes.

## Exact tarballs

| Package | Tarball | SHA256 |
| --- | --- | --- |
| proofscript@0.1.0-psc1.6 | proofscript-0.1.0-psc1.6.tgz | 4657ecbf3d4afaf3438d115ec24e60d9c4af80e3602c8ee19ed93e45104810dd |
| @proofscript/pskernel-lean-wasm@4.35.0 | proofscript-pskernel-lean-wasm-4.35.0.tgz | b203982eeb851b797f7a35a8a66f883472a6130f24f36c26b8931bd5e0881511 |
| @proofscript/pskernel-lean@4.35.0 | proofscript-pskernel-lean-4.35.0.tgz | c8ffd49220328ec2a96ac1c4388d828df255cc21537b2484b523710fe6c17371 |
| @proofscript/compiler-rust-linux-x64@0.1.0-psc1.6 | proofscript-compiler-rust-linux-x64-0.1.0-psc1.6.tgz | 0b727e2388e557cf4a3118557e032aef032e440f982ac58023274f6b68c069b3 |
| @proofscript/compiler-wasm@0.1.0-psc1.6 | proofscript-compiler-wasm-0.1.0-psc1.6.tgz | 47adf8144365056f52dfc1df1b17e4eba5b616a3d7a734be1c01342620ef9778 |
| typescript@7.0.2 | typescript-7.0.2.tgz | da2513f4b95176d6dde8b51aab7afe8a927656c9d277369793f77f7e59371c08 |
| @typescript/typescript-linux-x64@7.0.2 | typescript-typescript-linux-x64-7.0.2.tgz | 7ecad6f67377e831856367ab062ef394f21506a611405bf8ac0ff039348637d3 |
| @proofscript/rust-target-consumer-linux-x64@0.1.0-psc1.6 | proofscript-rust-target-consumer-linux-x64-0.1.0-psc1.6.tgz | 0b57758a5bb074593f699f93d2267d8a80d2fcdeba19f4c61222cbb517e04309 |

[Exact qualification receipt](PSC1_CHECKED_PUBLICATION_QUALIFICATION_2026-10-26.json)
owns test, source and artifact identities. Linux qualification does not qualify
macOS/Windows publication; those commits remain refused. Wasm callback IO and
unsupported standalone ABI types refuse explicitly. JS/TS/Rust callback IO retain
the existing host-owned capability policy. Python/PHP remain optional in the
preserved native distribution.

The [roadmap](PSC1_DEVELOPMENT_ROADMAP.md) owns remaining platform, component/provider,
source-package and final clean-release work. No merge or registry publication is authorized.
