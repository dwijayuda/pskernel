# Installing the self-host-qualified modular compiler

The .4 preview extends PR #211 with installed Node22.23.3 qualification on
Linux x64, Windows x64, macOS Intel and Apple Silicon.
[Platform CI](https://github.com/dwijayuda/pskernel/actions/runs/40814345252) and
[exact receipt](../PSC1_CROSS_PLATFORM_QUALIFICATION_2026-10-29.json).
The [roadmap](../PSC1_DEVELOPMENT_ROADMAP.md) remains the work authority.

## Install and use

Extract GitHub's outer artifact ZIP and its inner cross-platform ZIP. Open a
terminal in the extracted proofscript directory:

```sh
npm install --offline --ignore-scripts --no-audit --no-fund ./proofscript-0.1.0-psc1-modular.4.tgz
npx --offline psc --version
npx --offline psc init
npx --offline psc check
npx --offline psc build Main.ps --out out --watch
```

Node>=22.23.3 is the declared minimum. The four-platform .4 matrix tests22.23.3;
earlier .3 Linux Node24/26/Bun results remain their own evidence. The package is
unpublished: installing the registry name does not select this preview.

The root includes20 core packages,134 source-owned units, the thin psc command
and the unchanged official Lean4.35.0 C++/Emscripten linear-memory Wasm kernel.
It has no hidden whole-compiler dist/implementation bundle. Public proofscript/*
subpaths avoid depending on npm hoisting. Use --engine ts for the TS-generated
compiler. Python/PHP and target SDKs remain optional.

JS and Wasm-core outputs need no external target SDK. For checked TS output,
install the common typescript7.0.2 tarball plus the one native archive listed in
optional/typescript/<platform>.json. Those archives are included for linux-x64,
win32-x64, darwin-x64 and darwin-arm64; do not install all native archives together.
Then run psc build Main.ps --target ts --out out-ts. The resolver verifies exact
package names, versions, SHA-pinned regular files and the matching platform before
running the existing strict TypeScript consumer. Compilation never fetches tools.

## Publication and failure behavior

| Host | Default protocol | Reported success |
| --- | --- | --- |
| Linux | legacy-symlink | confirmed directory/file flush |
| macOS | portable-file | confirmed directory/file flush |
| Windows | portable-atomic | visibility-only |

All profiles expose a complete immutable checked generation through one atomic
pointer replacement. portable-atomic explicitly omits directory/power-loss durability.
Windows durable portable-file remains refused; there is no silent fallback.
A precommit failure preserves the previous generation. After the commit point,
failure reports COMMITTED_DURABILITY_UNCERTAIN with committedPublication;
it never promises rollback. The tests inject both classes of failure and refuse
stale publication sessions. These filesystem checks are not power-loss certification.

compile() executes the complete checked session without publishing. build() and
psc build apply the selected protocol. Watch captures bounded dependencies and
rejects stale results. A type error leaves the previous output available; repairing
the source resumes publication. Unix shutdown is tested with SIGTERM; Windows
automated qualification uses taskkill for the owned tree. Interactive Windows
Ctrl+C/Break behavior remains a separate trial.

## Compiler identity, checking and resource limits

[Provenance acquisition](../../scripts/modular-toolchain-provenance.mjs) validates
the original successful JS/TS G2/G3 artifacts, manifests, independent admissions,
complete source graph and all15 generated npm archives. [Assembly](../../scripts/modular-toolchain-package.mjs)
retains those generated implementations and adds only versioned package/host overlays.
[Installed verification](../../host-tools/executable/verify.mjs) checks the exact
source-graph projection and full installed inventory before importing generated code.

The original compiler source remains17ce19919175b60be06050188e2a546a8a72e689,
closure1f2f1e4a035a32faa6035aeae000e9c92305f8fb34e58b8cc2210504e38213cb.
dist/COMPILER_SELFHOST_QUALIFICATION.json records the original finite Linux
JS/TS G1/G2/G3 graph/npm fixed points. It is distinct from installed-host evidence.
No unchanged self-hosting chain was rerun for this platform fix.

Missing/tampered graphs, checkers, SDKs or resources refuse before execution or
publication. Project metadata cannot select tools or acquire checking authority.
Ordinary requests/tools remain240s, checker120s, with existing memory/stack/fuel,
file/graph/traversal bounds and strict original/transformed IR checks.
The manual3600s G2/G3 correctness profile does not extend installed compilation.

## What this milestone qualifies

One identical root tarball passes local/global offline installation and CLI
registration on four OS/architecture combinations. Each tests both complete
compiler engines, both grammars, actual JS/strict TS/Wasm-core behavior with large
integers and Unicode, real independent kernel acceptance/rejection and watch
edit/reject/repair. The ZIP contains the tested tarball, optional platform TS SDKs,
licenses, instructions, source/package/platform receipts and SHA256SUMS.
Final adoption verifies exact tested host bytes and extracted ZIP hashes without
rebuilding that tarball.

Prior .3 [Linux installed](../PSC1_SELFHOSTED_INSTALLED_QUALIFICATION_2026-10-29.json)
and [M5 self-host](../PSC1_PORTABLE_MODULAR_QUALIFICATION_2026-10-29.json) evidence
remain preserved. Native Rust/component SDK consumers and optional Python/PHP
retain their separate Linux scope. Older compiled Rust/Wasm compiler executors
refuse this newer source cohort. New native executors, full cross-platform M3
coverage, standalone checked-host installation, binary reproduction, interactive
Windows cancellation,240s self-compilation and final release remain separate work.
Hash checking relies on trusted bootstrap/stable resources; it is not a signature,
sandbox or semantic-preservation theorem. No merge or registry publication occurred.
