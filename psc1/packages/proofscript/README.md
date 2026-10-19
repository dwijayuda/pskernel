# proofscript — minimal PSC0 npm compiler

`proofscript` is a globally installable npm CLI package (`psc`). It bundles
only 13 core packages: 12 modules in the bounded self-host compiler closure,
plus the generated JavaScript `@proofscript/pskernel-core` admission checker.

Optional modules are published/installed separately: `@proofscript/backend-rust`,
`@proofscript/backend-wasm`, `@proofscript/backend-js`, `@proofscript/stdlib`,
`@proofscript/cli`, `@proofscript/pskernel-lean`, and
`@proofscript/pskernel-lean-wasm`. No optional package is included in
the `proofscript` tarball itself.

TypeScript 7.0.2 is an exact npm dependency but **not bundled** into the tarball.
The npm installer resolves `@typescript/typescript-win32-x64` on Windows x64
or `@typescript/typescript-linux-x64` on Linux x64. Each archive includes
pre-downloaded tarballs for offline installations on these two platforms.

After intentional public registry publication:

```sh
npm install -g proofscript
psc init my-app
psc build src/Main.ps
```

Before publication, install the local `proofscript-0.1.0-psc0.1.tgz`
using instructions from the ZIP's INSTALL.md. The JS checker has bounded
independent negative/positive admission conformance evidence but is not
a formally proven sound, consistent, fully Lean-compatible or self-hosted fixed-point kernel.

Read `psc0/docs/NPM_PACKAGING_ARCHITECTURE.md` in the repository for third-party
library metadata, source-only stdlib registration and package architecture.
