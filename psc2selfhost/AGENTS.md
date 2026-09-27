# Working in psc2selfhost

Scope: this directory and its descendants. Follow user instructions and any
applicable higher-priority repository instructions first.

Before changing implementation, read README.md, GOVERNANCE.md, STATUS.md and the
applicable acceptance gate and plan. Refresh repository/branch state; do not
assume historical evidence applies to a changed tree.

- Preserve the package architecture and existing regression gates. Prefer the
  smallest faithful change addressing the first reproducible blocker.
- Keep handwritten portable compiler source in `.lean` until the documented
  source-authority transition. Generate `.ps`; do not manually mirror it.
- Keep PSC1 implementation-profile requirements separate from the PSC2 language
  accepted by the compiler. Document any post-PSC1 bootstrap dependency.
- Kernel admission is independent of Meta/elaboration. A codec, successful
  parser, `lake build`, backend compilation or passing runtime test is not
  admission and must not be reported as such.
- Route verified executable compilation through admitted Core and erasure to
  the shared target-neutral IR. Keep host IO and target layouts outside it.
- Preserve the TypeScript kernel as an independent oracle during migration.
  Never promote an incomplete replacement or silently fall back after rejection.
- Pin semantic oracle versions and record tool versions in evidence. Use
  `docs/STUDY_REFERENCE_POLICY.md` for research; v0.8 is not a language authority.
- A source-profile guard pass is insufficient if a semantic package is skipped.
  Audit the compiler and kernel dependency closures explicitly.
- For semantic fixes, add a regression for the actual failure and an adjacent
  invalid case; run the applicable existing tests. Do not weaken expected results.
- Record gates as PASS, FAIL, BLOCKED, NOT RUN or PLANNED, with commit, command,
  scope and evidence. Timeouts and unavailable runners are not semantic verdicts.
- Keep work in a focused branch; do not merge unrelated diagnostic/performance
  branches wholesale. Observe repository branch protections and session authority.
- Update STATUS.md and the affected plan when actual evidence changes. Keep
  normative rules in their owning documents rather than duplicating them.

Documentation-only work needs link/consistency review and `git diff --check`;
it does not require running unrelated kernel corpora. Do not introduce approval
loops for routine authorized edits. Report material design conflicts explicitly.
