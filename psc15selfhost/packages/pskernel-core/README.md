# pskernel-core (new)

`@proofscript/pskernel-core@0.1.0-foundation.0` — private, non-authoritative.
The previous package remains `@proofscript/pskernel-core.old`.

This checkpoint contains an **executed PSC data/structural foundation, not a proof
checker**. Owned source is in `src/Ps/Kernel/`; generated ESM, TypeScript, declarations,
canonical `.ps` and flattened source are in `dist/`. No generated semantic code is
hand edited. No old kernel or Lean provider is a runtime dependency.

The only public export remains immutable identity metadata:

```js
import { kernelInfo } from '@proofscript/pskernel-core';
console.log(kernelInfo.status);         // "foundation"
console.log(kernelInfo.canCheckProofs); // false
```

`createKernel`, `checkBundle`, `CheckedModule` and proof admission are not exported.
The experimental generated data layout is not a stable public API.

```sh
npm test                 # package, source and generated-code tests
npm run verify:build     # source/output identity checks, not a soundness proof
npm pack                 # local tarball; publication remains disabled
```

Rebuilding requires an explicit approved PSC seed and TypeScript 5.8.3. The optional
oracle gate uses the pinned Lean provider only as an external test tool. See
`FOUNDATION.md` and the manifests for commands, scope, evidence, seed provenance and
remaining limitations. `ARCHITECTURE.md` describes the full target, not completed
capabilities. No complete Lean compatibility or kernel self-hosting is claimed.
