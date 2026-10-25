# Slim universal ProofScript package

The current host/package work is `proofscript@0.1.0-psc1.6`:
[checked output and transactional publication](PSC1_CHECKED_PUBLICATION.md),
[exact current receipt](PSC1_CHECKED_PUBLICATION_QUALIFICATION_2026-10-26.json).
Qualification is in progress; consult the receipt before promoting an artifact.
The preceding qualified generated-IO package remains available in
[its exact installation guide](PSC1_GENERATED_IO_INSTALL.md).

The root embeds the same qualified JS/TS G3 compilers and genuine official Lean4.35
linear-memory Wasm checker. Rust/compiler-Wasm executors and native checking stay
optional. It contains no default native compiler SDK, optional executor payload,
platform SDK binary, Python/PHP transport, SDK download or install-time compilation.

Checked JS, TS, Rust and Wasm-core outputs share the existing private admission
and strict IR session. Output consumers are optional and explicit; they are
separate from compiler execution bundles. All target SDK resources must match
trusted distribution pins. Source/project/package metadata cannot select tools.

Use the current receipt's exact local tarballs and Node22.23.3:

```sh
npm install --offline --ignore-scripts ./proofscript-0.1.0-psc1.6.tgz
npx --no-install psc --identity
npx --no-install psc compile Main.ps --engine ts
npx --no-install psc build Main.lean --target wasm-core --publication-protocol portable-file --out dist/app
```

The new file pointer is opt-in; default legacy stores keep their format. Builds
return immutable generation paths. Post-commit durability uncertainty is explicit;
unsafe stale-lock takeover is refused. Linux publication is the current qualified
platform boundary; actual macOS/Windows commit behavior remains a release blocker.
Do not mistake universal npm metadata for whole-platform qualification.

Independent canonical Lean admission, IR validation, runtime tests and exact
self-host fixed points are distinct forms of evidence, not a preservation proof.
No merge or npm publication is authorized.
The [roadmap](PSC1_DEVELOPMENT_ROADMAP.md) owns remaining platform, component/provider,
source-package resolution and final clean-release work.

[Preserved PR #181 slim guide](history/PSC1_SLIM_UNIVERSAL_BEFORE_CHECKED_PUBLICATION_2026-10-26.md)
retains its frozen120-module payload identities and .4 artifacts.
They remain separate from current122-module .5/.6 payloads and qualifications.
