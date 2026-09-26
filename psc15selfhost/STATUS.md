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
kernel status:              bounded reference package, not yet compiler authority
```

The authoritative source entry is:

```text
packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean
```

The fixed-point import closure is guarded by `scripts/check-bootstrap-closure.mjs`.
It rejects project tooling, Rust, Wasm and the reference `pskernel` from the first
compiler generation. Workspace package dependencies are checked as well as Lean source
imports.

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

This remains deliberately weaker than real kernel admission. The next kernel milestone
must explicitly adapt the local reference `packages/pskernel` (or another accepted
provider) to the compiler Core and make erasure consume a genuine checked artifact.
Until that adapter exists and is gated, do not rename the current boundary to
`CheckedCore` and do not claim kernel-backed self-hosting.

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

Each feature should record its implementation profile, accepted profile, lowering target,
kernel requirements and backend requirements. Features that can live in libraries or
elaboration must not be pushed into the kernel for convenience.
