# New/legacy package migration

Scope: a separate review branch from `psc2/selfhost-lean-kernel` at
`c680b2016ff8e23bdae2bc102128b1308fb5a324`. Main and existing work branches are not
rewritten. Other branches can have additional legacy work; those changes are not
silently merged or discarded by this scoped migration.

## Identity and source preservation

- `packages/pskernel-core` becomes the new design package.
- Existing sources move to `packages/pskernel-core.old`.
- The old npm identity becomes `@proofscript/pskernel-core.old`; both packages remain private.
- The legacy source tree is preserved as Git tree
  `5588a952fa8f4706c37c5ebfb89c0bab207f4443` (five `.lean` files).
- The existing `Ps.KernelCore` module names and `PsKernelCore` Lake target remain
  legacy compatibility identifiers. They resolve to `.old`, never to the new kernel.
- The new planned source prefix is `Ps.Kernel`; no semantic sources or Lake target
  for it are claimed in this design commit.

Update the Lake source root, shared `KernelCore` module-to-package mapping, and
legacy source-profile runner to `.old`. Explicitly forbid both old and new packages
from the current first-bootstrap closure; promotion of the new implemented kernel
requires a separate reviewed gate. Keep the old regression targets running against
old sources rather than silently applying them to an empty new source root.

The existing workspace commands `check:kernel-core-source` and `test:kernel-core`
remain legacy compatibility commands. New design/package tests are run with
`npm test --workspace @proofscript/pskernel-core`. Their success is not proof-checking
or self-host evidence. Historical docs remain historical; apply this migration note
when interpreting their old package paths.

## Validation boundary

Local checks cover the new package metadata/tests and tarball consumption, and the
updated JavaScript policy/layout contract tests. A full Lean/Lake build, complete
repository reference scan, full workspace CI, proof replay, and self-host fixed point
must still run on a full checkout before merging. The local environment used to
prepare this change did not have Lean/Lake or a complete checkout.

Do not publish, merge automatically, change the compiler's default checker, or use
this design package to authorize emission. No registry package was renamed or
published; this is a repository workspace rename and design scaffold only.
