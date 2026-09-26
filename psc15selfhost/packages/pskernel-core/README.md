# `@proofscript/pskernel-core`

`pskernel-core` is the small PSC1-portable trusted-kernel candidate for PSC2.

It is **not** the compiler, elaborator, tactic engine, replay harness, or Lean-compatibility
oracle. Those responsibilities stay outside the trusted kernel.

## Source contract

Kernel source is handwritten as PSC1-compatible `.lean` and must pass
`scripts/check-kernel-core-source.mjs`.

The kernel source must not depend on:

- Lean implementation APIs;
- `Std` implementation APIs;
- macros/custom syntax/custom elaborators;
- `unsafe`, `extern`, `implemented_by`, `run_tac`;
- IO/filesystem/process APIs;
- frontend/parser/elaborator packages;
- backend packages;
- replay/JSON/oracle infrastructure.

Using ordinary foundational types and bootstrap-modeled primitives such as `Nat`,
`String`, and `Char` is allowed when they are inside the PSC1 bootstrap profile.

## What belongs here

Only semantics required to decide whether canonical dependent Core declarations are
admissible.

Preferred layering:

```text
Name
  |
Level
  |
Expr
  |
Instantiate / substitution / local context
  |
Declaration / Environment
  |
Reduction + definitional equality
  |
Type checking / declaration admission
  |
Inductives / constructors / recursors / Quot rules
  |
Checked declaration/module API
```

The exact module split may change, but dependencies should generally point downward.
Keep utility code local and small rather than importing broad compiler/platform packages.

## What does not belong here

Keep these outside the TCB:

```text
parser / pretty-printer
name resolution
elaboration / metavariable solving
syntax sugar
termination UX / equation compiler
Meta / tactics / simp / automation
contracts / VC generation
JSON / NDJSON replay
Lean export/import tooling
differential oracle fixtures
TS / Rust / Wasm lowering
CLI / filesystem / cancellation policy
plugins / FFI / package management
```

They may produce terms or declarations, but the kernel must independently check the
result.

## Relationship to `packages/pskernel`

The two packages have different jobs:

```text
packages/pskernel-core   small candidate TCB
packages/pskernel        larger reference / differential / assurance implementation
```

The reference package can stay large because it is evidence, not the production trust
boundary. Differential tests should compare `pskernel-core` behavior against accepted
Lean/reference behavior without copying the reference package wholesale into the TCB.

## Relationship to compiler Core

The current compiler uses `packages/core`, while `pskernel-core` begins with independent
foundational representations. This is useful during parity work but creates an important
future soundness decision.

An unchecked adapter between two different Core ASTs must **not** become hidden trust.
A bug such as:

```text
compiler declaration A
        |
 buggy adapter
        v
kernel checks different declaration B
        |
erasure executes original A
```

would invalidate the admission story even if the kernel itself were perfect.

Before `pskernel-core` becomes compiler authority, choose one explicit design:

1. **Preferred:** converge on one tiny canonical post-elaboration Core representation
   shared by the compiler and kernel; or
2. make the kernel-owned canonical representation authoritative after conversion and
   require downstream erasure to consume that exact checked representation; or
3. formally verify the adapter strongly enough that it no longer acts as an unexamined
   TCB expansion.

Do not merely check a translated copy and then erase the unchecked original.

## Checked artifact rule

Eventually the only path to executable VerifiedIR should be:

```text
canonical Core
    -> pskernel-core admission
    -> CheckedModule / CheckedCore
    -> erasure
    -> VerifiedIR
```

`CheckedModule` should be constructible only by successful kernel admission at the
public API boundary. Backend packages must never manufacture it or bypass it.

Until this exists, the compiler's current `PsCompilerAdmissionReadyModule` must retain
its weaker, honest name.

## Bootstrap relationship

`pskernel-core` is intentionally **outside the first compiler fixed-point closure**.
That lets the compiler reach a small self-host fixed point while kernel work proceeds in
parallel without creating circular bootstrap requirements.

After the compiler fixed point is demonstrated and the kernel admission API is mature,
wire the checked-core seam as a separate milestone. Do not enlarge the initial bootstrap
closure merely because kernel development happens in the same workspace.

## Growth gates

For every new kernel semantic family require, at minimum:

1. PSC1 source-profile/self-hostability check;
2. direct unit tests;
3. positive parity fixtures;
4. negative/fail-closed fixtures;
5. differential evidence against the accepted reference where practical;
6. no new frontend/backend/platform dependency;
7. an explicit reason the behavior belongs in the kernel rather than elaboration or a
   library.

Prefer small semantic steps over feature batches. A new semantic rule should land with
its own regression evidence before the next family depends on it.

## Compatibility claims

Do not describe `pskernel-core` as fully Lean 4 equivalent merely because individual
Name/Level/Expr/type-checking tests pass. Compatibility claims must match the bounded
acceptance matrix actually exercised. Full Lean equivalence is a separate proof and
assurance milestone.
