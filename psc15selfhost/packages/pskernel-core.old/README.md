# pskernel-core.old

Preserved legacy package, renamed from `@proofscript/pskernel-core`.
The new independent-kernel design lives in `../pskernel-core/`.

All five original Lean source files are preserved without semantic edits from
`psc2/selfhost-lean-kernel` at `c680b2016ff8e23bdae2bc102128b1308fb5a324`.
Their source Git tree is `5588a952fa8f4706c37c5ebfb89c0bab207f4443`.

`Ps.KernelCore`, the `PsKernelCore` Lake target, and existing kernel-core test
commands remain legacy identifiers; the workspace now resolves them to this
`.old` directory. They are not evidence for the new package. Both packages
remain excluded from the current first-bootstrap closure.

This rename neither resumes development of the old kernel nor merges work from
other branches. See `../pskernel-core/MIGRATION.md` for scope and validation limits.
This package remains private and is not a published npm replacement.
