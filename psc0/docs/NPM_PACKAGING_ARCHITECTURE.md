# ProofScript PSC0 npm packaging and libraries

## Installation principle

An npm installation of `proofscript` supplies the usable `psc` compiler, the bounded self-host compiler
closure, the TypeScript 7.0.2 emission toolchain, and the generated JavaScript PSKernel Core checker.
It does **not** install every backend, experimental compiler stage or optional checking provider.

The following thirteen `@proofscript/*` packages are mandatory in this PSC0 release:

| Category | Packages |
| --- | --- |
| Self-host compiler closure | `foundation`, `syntax`, `core`, `environment`, `meta`, `elab`, `bridge`, `compiler-ir`, `erasure`, `compiler`, `backend-ts`, `bootstrap` |
| Required checker runtime | `pskernel-core` |

The compiler closure has historical bounded self-host qualification. `pskernel-core` is a required
JavaScript runtime checker with bounded differential acceptance; a *joint* compiler/kernel fixed
point and general soundness proof are not established by npm packaging.

The following packages are **independently installable, not included in the default installation**:
`@proofscript/backend-js`, `@proofscript/backend-rust`, `@proofscript/backend-wasm`,
`@proofscript/cli` (legacy source CLI), `@proofscript/pskernel-lean`,
`@proofscript/pskernel-lean-wasm`, and `@proofscript/stdlib`.

These optional npm packages may be distributed as separate tarballs and eventually published
under the same npm scope. Installing a backend package is not evidence that its API is complete.
Existing scoped runtime facades reuse the monolithic compiler JS runtime; a future
module-separation milestone must generate genuine backend-specific JS runtime modules.

## Windows and TypeScript 7

TypeScript 7.0.2 uses an OS/CPU-specific native compiler package. Packing its Linux
`node_modules` into `proofscript` is not portable and caused a missing
`@typescript/typescript-win32-x64` error on Windows. The new core npm package does **not**
bundle TypeScript itself. npm must install its pinned dependency and matching native
package for the consumer's target platform. See the ZIP's `INSTALL.md` for
offline Windows x64 and Linux x64 commands with predownloaded tarballs.

Direct registry installation after an explicit public release:

```bash
npm install -g proofscript
psc version
psc init my-app
```

Before registry publication, install the local `proofscript-0.1.0-psc0.1.tgz`
with its platform TypeScript tarballs from either ZIP. No automatic npm publication
occurs in the GitHub workflow.

## Standard library

`@proofscript/stdlib` is recommended as an **opt-in** standard-library npm package.
PSC0 stages the existing `stdlib/ProofScript` module tree into
`@proofscript/stdlib/src/ProofScript`. Its PS edition translates supported
`.lean` modules to `.ps` and preserves unsupported originals with
`SOURCE_CONVERSION.json`; the Lean edition retains `.lean` originals.

This initial package is source-only: applications compile the imported modules
into their checked program. It is not a separately linked binary ABI or full
Lean/PSCV-standard-library conformance guarantee.

An application opts in explicitly:

```json
{
  "private": true,
  "dependencies": {
    "@proofscript/stdlib": "0.1.0-psc0.1"
  },
  "proofscript": {
    "libraries": {
      "ProofScript": "@proofscript/stdlib"
    }
  }
}
```

Then use `import ProofScript.Data.List` in a source edition containing that file.
Imports of a source module absent from that edition must fail clearly rather
than silently selecting the other edition.

## Third-party npm libraries

Third parties can publish libraries using standard npm packaging. There is no
need to register compiler plugins, replace the kernel, or execute package JS.

Example library `@example/ps-math`:

```json
{
  "name": "@example/ps-math",
  "version": "0.1.0",
  "type": "module",
  "files": ["src/"],
  "exports": { "./package.json": "./package.json" },
  "proofscript": {
    "library": {
      "schemaVersion": 1,
      "modulePrefix": "Demo",
      "sourceRoot": "src"
    }
  }
}
```

Library file `src/Demo/Math.ps`:

```text
def demoAnswer : Nat := 42
```

Consumer project `package.json`:

```json
{
  "private": true,
  "dependencies": {
    "@example/ps-math": "0.1.0"
  },
  "proofscript": {
    "libraries": {
      "Demo": "@example/ps-math"
    }
  }
}
```

Consumer `src/Main.ps`:

```text
import Demo.Math

def answer : Nat := demoAnswer
```

The compiler reads declared dependency metadata and validated source text.
It does **not** import npm library JavaScript while checking proof terms.
Library namespaces must match manifest declarations, and modules cannot
escape the package source root. `Ps` is reserved for official compiler/kernel
modules; `ProofScript` may only be mapped to `@proofscript/stdlib`.

The imported library uses the same `.ps` or `.lean` source kind as the entry.
No unchecked runtime hooks, tactics or kernel admission overrides are granted.
Semantics remain limited to PSC0's bounded source grammar and compiler profile.

## Assurance and acceptance

Release requires Linux and Windows installed-package tests, strict
TypeScript 7 version/architecture checking, negative-source rejection,
separate optional-package inventory, and basic third-party npm import/build.
Finite kernel comparison does not prove formal metatheory or general consistency.
Neither npm publication nor a completed whole-system self-host fixed point
should be inferred from installability alone.
