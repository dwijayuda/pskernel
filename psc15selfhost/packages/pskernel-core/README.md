# pskernel-core (new implementation)

npm identity: `@proofscript/pskernel-core`.

**Status: architecture and package-identity scaffold only. No proof checker,
declaration admission, Lean compatibility, compiler authority, or kernel self-hosting
is implemented by this package.** Its only public export is immutable `kernelInfo`.
The npm package is private to prevent accidental publication.

The previous package is preserved as `../pskernel-core.old/`, with npm identity
`@proofscript/pskernel-core.old`. Its source is not imported here, and its historical
tests and compatibility evidence do not establish anything about this implementation.
The legacy Lean namespace remains `Ps.KernelCore`; the new design reserves `Ps.Kernel`.

See [ARCHITECTURE.md](./ARCHITECTURE.md) for the proposed semantic modules, API,
Lean proof import path, TCB, release gates, and self-hosting plan.

## Available now

```js
import { kernelInfo } from '@proofscript/pskernel-core';
console.log(kernelInfo.status); // design-only
```

Run `npm test --workspace @proofscript/pskernel-core` from `psc15selfhost/`,
or `npm test` from this directory. These are package-contract tests, not proof tests.
`npm pack --dry-run` inspects the distributable files. Nothing is published by these commands.

## Migration boundary

The existing `check:kernel-core-source` and `test:kernel-core` workspace commands
remain legacy checks. Their source lookup now points to `pskernel-core.old`.
They are not tests of this package. The existing compiler and Lean providers are
not changed or replaced. Both new and old packages stay outside the existing
compiler-only bootstrap closure.

## Planned release

The release artifact should contain generated JavaScript, TypeScript declarations,
exact portable sources, package-local reproducible build instructions, source/build
manifests, and required license notices. Normal installation must not compile Lean,
run PSC2, download a checker, or enable an alternate proof provider. Public publication,
namespace ownership, and a license for the new implementation require separate resolution.
