# PSC2 Next-Session Checklist

Status date: 2026-09-27
Branch to continue: `psc2/minimal-selfhost-psc15`

Use this as the first-page checklist for a new chat/agent.

## Read first

1. `docs/continuity/PSC2_MINIMAL_SELFHOST_CONTEXT.md`
2. `docs/continuity/PSC2_KERNEL_CORE_DECISIONS.md`
3. `docs/superpowers/plans/2026-09-27-psc2-minimal-kernel-phase1.md`
4. `packages/pskernel-core/src/Ps/KernelCore.lean`
5. `scripts/check-kernel-core-source.mjs`
6. `.github/workflows/psc2-minimal-kernel.yml`

Then inspect the branch HEAD and latest PSC2 minimal-kernel CI run. Do not assume this checklist is newer than repository code.

## First commands/gates to reproduce

From `psc15selfhost/`:

```sh
lake exe psc2_kernel_core_boundary_tests
lake exe psc2_kernel_core_name_parity_tests
lake exe psc2_kernel_core_level_parity_tests
node scripts/check-bootstrap-closure.mjs
node scripts/check-kernel-core-source.mjs
```

The last command is the critical self-host-source gate. It must invoke the actual PSC1 compiler, not only a regex/source linter.

## Current expected state

Expected green before moving to Expr:

- boundary,
- Name differential parity,
- Level differential parity,
- bootstrap isolation,
- PSC1 source-profile check,
- PSC1 admission-ready check of trusted Name+Level closure.

If any lower-layer gate is red, fix it before expanding the kernel.

## Current blocker being closed

The latest known blocker in this chat was that trusted source could parse/elaborate under PSC1 but checked admission rejected `partial` declarations.

The fix in progress is to keep trusted definitions total:

- Name string equality uses explicit Nat fuel based on UTF-8 byte size.
- Level normalization should be structural.
- Level equivalence uses explicit fuel based on level-tree size.

Verify these are green under `node scripts/check-kernel-core-source.mjs` before starting Expr.

## Next RED slice after Name+Level are green

Create an `Expr` differential test first.

Minimum expression representation should be chosen from actual trusted-kernel need and mature PSC1Kernel behavior, likely including the Lean kernel expression forms required by the checker:

- bound variable,
- free variable if trusted checking requires it internally,
- metavariable representation if needed for rejection/detection,
- sort,
- constant + universe levels,
- application,
- lambda,
- forall,
- let,
- literal/projection only if the trusted kernel really needs them at this layer.

Do not blindly copy all helper APIs from the mature reference.

For each Expr operation:

1. add failing differential case,
2. implement smallest PSC1-subset code,
3. run Lean parity,
4. run self-host source/admission gate,
5. keep bootstrap closure isolated.

## Drift alarms

Stop and re-evaluate if a proposed change does any of the following:

- imports `Lean.*` or `Std.*` into trusted kernel source,
- adds `unsafe`, `extern`, custom macros/elaborators, or IO to trusted kernel,
- introduces target/backend-specific semantics,
- makes `pskernel-core` a bootstrap dependency before planned cutover,
- adds broad stdlib/runtime machinery to solve a small kernel need,
- removes a differential test instead of resolving mismatch,
- uses full Lean syntax that current PSC1 cannot compile,
- calls the kernel/PSC2 fully self-hosted before fixed-point evidence exists.

## Reporting format for future sessions

When reporting progress, distinguish:

- Lean build status,
- reference parity status,
- PSC1 source/self-host status,
- bootstrap isolation status,
- fixed-point status.

Never collapse these into one vague percentage or say `self-hosted` merely because the Lean bootstrap builds.
