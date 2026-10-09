# Installed ProofScript examples

These sources ship in the proofscript package at examples/platform. Run `psc examples` to locate them. Copy an example directory into your own workspace before editing or building it; do not write generated output into the compiler installation.

The examples use the current bounded source profile and checked TypeScript build. A successful build means kernel admission, RuntimeIR checks, and the configured TypeScript target check succeeded. The current release does not claim full PSCV verification or compiler semantic preservation.

| Example | What it demonstrates |
| --- | --- |
| checked-nat | A single ProofScript definition admitted and emitted beside its source |
| existing-typescript | An ES2022/NodeNext TypeScript project importing that generated neighbor |
| rejected-source | An ill-typed definition that cannot produce a successful build |

## Start without copying an example

```sh
psc init my-app
cd my-app
```

Init creates package.json, src/Main.ps, and PROOFSCRIPT.md. It installs nothing. In an existing npm project, it adds the source and guide while preserving package.json and tsconfig.json. It refuses existing starter paths rather than overwriting them.

For a published version, the generated exact dependency can be installed with `npm install --ignore-scripts`. For this unpublished preview, install the downloaded candidate tarball from its actual path:

```sh
npm install --save-dev --save-exact --ignore-scripts "/absolute/path/proofscript-0.1.0-preview.2.tgz"
npm run check
npm run build
```

On Windows use your actual drive path to the tarball. The npm scripts invoke the documented package launcher directly, so a conflicting third-party psc bin link cannot select a different compiler. Keep the resulting lockfile with the project.

## checked-nat

Copy checked-nat into a new working directory, install the candidate as above, then run `npm run check` and `npm run build`. The source is deliberately small:

```text
def answer : Nat := 42
```

A successful build writes src/Main.ts and src/Main.checked.json. The generated answer is a bigint. The receipt records the actual checking scope and artifact identity; it is not a transferable proof.

## existing-typescript

Copy existing-typescript into a working directory. Install the candidate tarball; npm also installs this example's exact TypeScript 7.0.2 dependency. Then run:

```sh
npm run build
npm run start
```

The build script runs the checked ProofScript build before the TypeScript project build. Its consumer imports `answer` from `./Main.js`, checks its bigint value, and prints `ProofScript answer: 42`. This is a one-source adoption example. It does not qualify arbitrary module facades, cross-file datatypes, framework bundlers, or unrestricted FFI.

To adopt the same approach in an existing project, preserve its package metadata and TypeScript configuration, add a .ps source under src, and run the checked source build before the existing TypeScript build. Init does not rewrite the project's existing build command.

## Rejected build

The rejected-source directory contains `def answer : Nat := Type`. Its check/build must return a nonzero exit status. See that directory's README for a last-good-output experiment.

## Optional extension demo

The separately built psdev candidate is outside the compiler self-host closure. The generated PROOFSCRIPT.md explains how to install its exact tarball, explicitly enable `command:dev` in package.json, and run `psc dev --once`. This demo uses the same protected checked-build route. It is a bounded one-shot command; live watch and broader module/ABI support remain later work.
