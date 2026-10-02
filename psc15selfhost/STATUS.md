# PSC2 minimal self-host status

Status (2026-10-03): compiler/reference replay parity is recorded on the preserved 75-module checkpoint. The default generated-owned kernel is checker.9; it admits the exact three-entry unit/PsSourcePos/PsSourceSpan prefix. Full owned joint self-hosting and release remain unachieved. See `docs/continuity/OWNED_RECORD_FIELDS_2026-10-03.md` for current evidence and blockers.

## Current bootstrap shape

```text
handwritten compiler source: PSC1-compatible .lean
bootstrap host:             Lean 4.34 + Lake
self-host source:           generated canonical .ps
fixed-point backend:        TypeScript -> JavaScript
semantic compiler:          backend-neutral
optional extensions:        project, Rust, Wasm
kernel status:              generated-owned pskernel-core default; bounded, non-authoritative
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

The compiler-only preparation path produces `PsCompilerAdmissionReadyModule`, not a blanket proof of owned admission.
This artifact is fail-closed: canonical admissions are revalidated before erasure and
the erasure environment is reconstructed from the bootstrap prelude plus declarations.
A caller-provided environment cannot be smuggled through this artifact.

The checked command path now freezes prepared modules, submits their exact canonical
admissions to the selected kernel, and permits emission only after acceptance.
The new `packages/pskernel-core` is the default; native Lean and Lean WASM require
explicit selection and remain outside the portable source closure. Rejection,
unsupported input, exhaustion and failed checks do not select another checker.
The full owned closure still fails, so compiler-only or reference fixed points
do not establish owned joint self-hosting. The retired core is not a continuation path.

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
