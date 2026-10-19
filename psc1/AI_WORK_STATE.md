# PSC1 current work state — scoped correctness and readable output

Updated 2026-10-20. Active repair branch: `fix/psc1-scoped-correctness-20261020`.

## User goal and limits

Repair existing compiler/kernel integration, independent admission, specialization,
module/export/source-map consistency, atomic artifact publication, Rust packaging,
WIT comparison and native/npm command identity. Emit readable JS, TS, Rust, WIT and
WAT. Do not add substantial language features, upgrade Lean, run full self-host
suites, publish npm packages, force-push or modify unrelated PSC0 work.

Use GitHub and Linux cloud CI for development. Fetch the actual branch HEAD before
writes and preserve all existing history. Do not use local checkouts/builds/tests.

## Baseline already verified

The repair branch was fast-forwarded from `469e540371d6c1a083103d16a4ee88737d6480c7`
to `0fd7b9aa8bc2f51b21e0cd9477edde35063de0e4`. The latter passed Actions run
39322348232 and contains the corrected PSKernel-Core port, specialization input and
output rechecks, independent official Lean admission, unmapped-span handling and
initial Rust crate emission. Kernel port source is from the separately qualified
`0a53836489c4e88f46df8f5b8b0c19cc41bafbbb` lineage.

## Current implementation slice — qualification required

- Immutable captured input closure with canonical path/cycle handling; no target
  or source-map reread of source files after admission.
- Private-constructor checked host session and exact admitted declaration graph.
- Entry public declarations selected separately from linked imported helpers.
- Shared specialized-IR declaration plan, stack-safe JS printer selection and TS
  target emission; native/npm use one command model with no generated fallback.
- Exact-pinned host formatting, parsed-tree stability checks for JS/TS and final
  formatted multi-file source-map observation. Correct negative VLQ encoding.
- Unique private stage, checksummed content-addressed generations, stable aliases
  and one atomic current-pointer replacement for each complete artifact bundle.
- Formatted Rust source plus a complete locked Cargo library; structural bounded
  WIT API comparison and actual-binary WAT generation.
- Focused cloud regressions and readable example artifact retention.

These changes are source work until the new exact-commit workflow passes. Read its
actual result and fix failures without weakening tests, increasing kernel fuel,
adding axioms or expanding the language. A previous baseline success is not proof
that the new source has passed.

## Trust distinctions

Direct output currently uses the independent **official Lean 4.34.0 kernel**.
The corrected **PSKernel-Core** source is integrated and tested separately; do not
claim it is already the default direct-output provider. Source admission, bounded
IR typing, formatting identity and executable examples are separate from formal
backend preservation and full language completeness.

The current native/npm launcher is private workspace tooling. Old generated
packages are historical, not a qualified PSC1 native distribution. No self-host
fixed point is asserted by this repair.

## Next actions

1. Run `.github/workflows/psc1-scoped-correctness.yml` on the exact new HEAD.
2. Resolve concrete native compilation and focused runtime failures.
3. Retain and commit the actual npm formatter lockfile generated in cloud CI.
4. Check broad existing per-target refusal/acceptance behavior; avoid accidentally
   applying the DirectJS scalar public ABI restriction to more capable targets.
5. Record exact passing SHA/run plus genuinely remaining audit items in
   `docs/PSC1_SCOPED_CORRECTNESS_2026-10-20.md` before promotion.

The previous full historical work state is preserved byte-for-byte at
`docs/history/AI_WORK_STATE_BEFORE_SCOPED_2026-10-20.md`. Its old PSC0 release and
self-host instructions are archival and do not supersede the scope above.
