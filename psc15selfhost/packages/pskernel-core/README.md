# pskernel-core (new)

Package identity: `@proofscript/pskernel-core`.
Legacy package: `@proofscript/pskernel-core.old`.

**Status: design and npm package contract only. No proof checking is implemented.**
There is deliberately no root checking export, success stub, provider fallback,
or permission to authorize compiler emission. The only current export is
`@proofscript/pskernel-core/metadata`. `private: true` prevents accidental registry
publication. Local installation/packing is not a kernel-completion claim.

The intended implementation is an owned, portable proof checker for the pinned
Lean 4.34 logical profile, shared by PSC2 and a separate Lean export adapter.
Handwritten bootstrap semantics use the proven PSC implementation subset;
canonical `.ps` becomes authoritative only after source, execution and fixed-point
gates. The first distribution target is prebuilt JavaScript with TypeScript types,
not a runtime call to Lean, C++ kernel, KernelOne or the legacy kernel.

See `ARCHITECTURE.md`, `CAPABILITIES.json`, and `MIGRATION.md`.

## Current checks

From this package directory:

```sh
npm test
npm pack --ignore-scripts
```

These check package identity and truthful capability metadata, not proof semantics.
No npm publication, name reservation, full Lean build, proof replay, compatibility
result, self-host result, or size reduction is implied by this package.
