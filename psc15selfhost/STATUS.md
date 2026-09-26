# PSC2 minimal self-host status

Status: the minimal bootstrap architecture is implemented and hardened, but an actual
Lean/Node fixed-point run is still required before declaring PSC2 self-hosted.

## Current bootstrap shape

```text
handwritten compiler source: PSC1-compatible .lean
bootstrap host:             Lean 4.34 + Lake
self-host source:           generated canonical .ps
fixed-point backend:        TypeScript -> JavaScript
semantic compiler:          backend-neutral through VerifiedIR
bootstrap composition:      packages/bootstrap
optional extensions:        project, Rust, Wasm
trusted-kernel candidate:   packages/pskernel-core (outside first fixed point)
reference/assurance kernel: packages/pskernel (outside TCB and fixed point)
```

The authoritative bootstrap entry is:

```text
packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean
```

The first compiler generation intentionally does **not** depend on project tooling,
Rust, Wasm, `pskernel-core`, or the larger `pskernel` reference package. The point is to
close the smallest stable compiler fixed point first, not to make every platform
capability circularly required for bootstrap.

## Bootstrap closure

`scripts/check-bootstrap-closure.mjs` walks the real Lean import graph from the
bootstrap entry and validates workspace package dependencies. The allowed closure is:

```text
bootstrap
foundation
syntax
core
environment
meta
elab
bridge
compiler-ir
erasure
compiler
backend-ts
portable stdlib modules actually imported
```

Everything else is extension or assurance work until a later milestone explicitly
moves it into the bootstrap contract.

Module-to-package and module-to-source routing for Node bootstrap tools is centralized
in `scripts/workspace-layout.mjs`. `scripts/check-layout-drift.mjs` guards the mapping,
resolver consumers, source-ambiguity behavior, and the host-side `KernelCore` package
mapping. This prevents generation N and N+1 from silently resolving imports differently.

## Acceptance gates

Do not claim a self-host milestone because the architecture looks correct or generated
files appear stable. The bootstrap acceptance sequence is:

```text
npm run check:workspace
npm run check:source:bootstrap
npm run check:layout
npm run check:bootstrap-closure
npm run check:selfhost-orchestration
npm run check:ir-neutrality
npm run build:lean
npm run test:bootstrap
npm run fixed-point
```

`check:selfhost-orchestration` locks the generation paths and script wiring used by the
bootstrap compiler, generated `.ps` workspace, next-generation compiler, source parity,
and TypeScript fixed-point comparison.

After the compiler fixed point is green, run broader assurance:

```text
npm run check
```

The full check additionally includes:

- every portable source profile;
- `pskernel-core` PSC1/self-hostability checks;
- kernel-core Name/Level parity tests;
- broad regression tests;
- Rust/Wasm extension tests.

Those are required release assurance but are deliberately not prerequisites for
producing the smallest compiler generation.

## Fixed-point evidence still required

`npm run fixed-point` must demonstrate both:

1. canonical generated `.ps` workspace parity between bootstrap and next generation;
2. exact generated TypeScript compiler parity between bootstrap and self-host generation.

No successful runtime execution of those gates has been observed in this working
session. Until such evidence exists, the correct status is **bootstrap architecture
ready for execution**, not “PSC2 self-host complete.”

A passing fixed point proves bootstrap stability for this compiler profile. It does not
prove full Lean 4 equivalence or kernel soundness.

## Current semantic boundary

The compiler produces `PsCompilerAdmissionReadyModule`, not `CheckedCore`.

The artifact is intentionally fail-closed for its current weaker role:

- it stores declarations plus their canonical admissions encoding;
- the canonical encoding is recomputed and compared before erasure;
- the environment is reconstructed from the bootstrap prelude plus those declarations;
- a caller-provided environment cannot be smuggled into the erasure path;
- executable backends consume VerifiedIR produced through this preparation boundary.

This still does **not** constitute kernel admission.

## Kernel split

There are now two deliberately different kernel-related packages.

### `packages/pskernel-core`

This is the small trusted-kernel candidate. Its source must remain PSC1-portable `.lean`
and is independently checked by `scripts/check-kernel-core-source.mjs`. It currently
grows from minimal foundational components such as Name and Level and has direct parity
tests against the reference foundations.

It remains outside the first compiler fixed-point closure. Growing it in parallel is
fine; making it a bootstrap dependency before an explicit checked-core adapter exists is
not.

### `packages/pskernel`

This is the larger bounded Lean reference/assurance implementation. It contains much
more semantic machinery and evidence, and is useful for differential/parity work. It is
not the small PSC2 TCB and should not be pulled wholesale into the self-host closure.

The intended later seam is:

```text
Core / AdmissionReadyModule
          |
          v
small kernel adapter + pskernel-core
          |
          v
CheckedModule / CheckedCore
          |
          v
Erasure -> VerifiedIR
```

Only after that adapter performs genuine admission should erasure accept a checked
artifact and the compiler claim kernel-backed self-hosting.

## After the first fixed point

Grow PSC2 upward rather than enlarging trusted semantics. Preferred order:

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
kernel requirements, and backend requirements. Features that can live in libraries,
syntax lowering, elaboration, or controlled plugins must not be pushed into the kernel
for convenience.
