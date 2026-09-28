# PSC2 minimal self-host status

Status: architecture and bootstrap-boundary refactor implemented; runtime fixed-point evidence is still required before declaring PSC2 self-hosted.

## Current bootstrap shape

```text
handwritten compiler source: PSC1-compatible .lean
bootstrap host:             Lean 4.34 + Lake
self-host source:           generated canonical .ps
fixed-point backend:        TypeScript -> JavaScript
semantic compiler:          backend-neutral
optional extensions:        project, Rust, Wasm
kernel status:              bounded PSC reference + optional Lean 4.34 host assurance; not compiler authority
```

The authoritative source entry is:

```text
packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean
```

The fixed-point import closure is guarded by `scripts/check-bootstrap-closure.mjs`.
It rejects project tooling, Rust, Wasm and the reference `pskernel` from the first
compiler generation. Workspace package dependencies are checked as well as Lean source
imports.

The external Lean assurance provider in `packages/pskernel-lean` must remain outside this
first fixed-point closure as well. It is selected by host orchestration, not imported by
the portable semantic compiler.

`packages/pskernel-lean` is now also a normal npm workspace package:

```text
@proofscript/pskernel-lean@4.34.0
```

Its npm version tracks the Lean semantic version. Future execution variants should keep
the version out of the package name, for example `@proofscript/pskernel-lean-wasm@4.34.0`.
Workspace membership does not grant bootstrap membership: the package remains marked
`bootstrap: false`, `portable: false`, and remains forbidden from the first fixed-point
closure.

## Acceptance gates

Do not claim a self-host milestone merely because the architecture compiles on paper or
because generated files look stable. The following gates are the acceptance sequence:

```text
npm run check:workspace
npm run check:source:bootstrap
npm run check:layout
npm run check:bootstrap-closure
npm run check:ir-neutrality
npm run build:lean
npm run test:bootstrap
npm run fixed-point
```

After the fixed-point gate is green, run the broader non-bootstrap assurance:

```text
npm run check
```

`npm run check` intentionally includes the all-portable source audit, broad regression
suite, and Rust/Wasm extension suites. These are release assurance, not prerequisites
for producing the smallest compiler generation.

## Fixed-point evidence

`npm run fixed-point` must demonstrate both:

1. canonical generated `.ps` workspace parity between bootstrap and next generation;
2. exact generated TypeScript compiler parity between bootstrap and self-host generation.

A passing fixed point proves bootstrap stability for this compiler profile. It does not
prove full Lean 4 equivalence or final kernel soundness.

## Current semantic boundary

The compiler currently produces `PsCompilerAdmissionReadyModule`, not `CheckedCore`.
This artifact is fail-closed: canonical admissions are revalidated before erasure and
the erasure environment is reconstructed from the bootstrap prelude plus declarations.
A caller-provided environment cannot be smuggled through this artifact.

This remains deliberately weaker than real kernel admission **inside the portable
compiler pipeline**. Do not rename the current compiler artifact to `CheckedCore` and do
not claim that erasure is already gated by a provider-neutral checked artifact.

### External Lean 4.34 assurance provider

`packages/pskernel-lean` now provides a separate native assurance path pinned to Lean
4.34.0 source commit:

```text
293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
```

Its current host path is:

```text
PSC source
  -> generated PSC2 compiler
  -> canonical checked-admissions v2
  -> @proofscript/pskernel-lean public package API
  -> pskernel-lean native process
  -> Lean Environment.addDeclCore / Lean kernel
  -> accept or reject
```

The self-host workspace declares `@proofscript/pskernel-lean@4.34.0` as an optional host
dependency. Host orchestration prefers the installed npm package and, in a zero-install
repository checkout, falls back only to the local package's public `index.mjs`. It must
not import `host/node-provider.mjs` as a private implementation path.

The self-host CLI exposes this as:

```text
psc check <entry.ps|entry.lean> --kernel lean434
psc build <entry.ps|entry.lean> --out <output> --kernel lean434
```

For the kernel-gated build, Lean acceptance occurs before code generation and rejection
prevents output emission. Builds without `--kernel lean434`, including the first
fixed-point path, retain their existing behavior and do not depend on this provider.

This gives PSC2 a real Lean-kernel-backed **external verifier**, but it still does not
solve the provider-neutral compiler boundary. The later kernel-authority milestone must
introduce a genuine `CheckedModule` / `CheckedCore` produced by a selected `KernelProvider`
and make erasure require that artifact.

Current provider documentation:

```text
packages/pskernel-lean/README.md
packages/pskernel-lean/NPM_PACKAGE.md
packages/pskernel-lean/BUILDING.md
packages/pskernel-lean/INTEGRATION.md
```

The npm API is packageable and is tested from a clean external npm consumer. The package
does not yet bundle prebuilt native executables for every OS/architecture. Repository
usage resolves the Lake-built executable; external consumers can provide
`PSC_LEAN_KERNEL_PROVIDER_BIN` until native platform artifacts are distributed.

The copied Lean `kernel/`, `runtime/`, and `util/` source trees are retained for a later
standalone C++/WASM provider. The current native provider links through the pinned
official Lean distribution rather than directly building those copies.

## After the first fixed point

Grow PSC2 upward rather than enlarging the trusted core. Preferred order:

1. richer patterns;
2. namespace ergonomics;
3. method notation;
4. practical local/mutual recursion lowering;
5. structured proof terms;
6. Meta/tactic and simplifier libraries;
7. contracts and VC generation;
8. controlled plugin APIs;
9. Task/async/resource libraries;
10. InterfaceIR/FFI and broader backend/plugin ecosystem.
