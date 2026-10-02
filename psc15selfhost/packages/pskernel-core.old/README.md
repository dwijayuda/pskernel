# pskernel-core.old

Preserved legacy package, renamed from `pskernel-core`.

- npm identity: `@proofscript/pskernel-core.old` (private).
- Original snapshot: `c680b2016ff8e23bdae2bc102128b1308fb5a324` on `psc2/selfhost-lean-kernel`.
- Original source tree: `5588a952fa8f4706c37c5ebfb89c0bab207f4443`.
- Its five Lean source files are preserved byte-for-byte, with the existing
  `Ps.KernelCore` namespace retained for legacy tests.

This is reference/legacy work, not the new independent checker. No implementation,
proof-checking authority, self-hosting claim, or compatibility evidence transfers to
`../pskernel-core/` merely because the new package takes the previous name.

Existing workspace `check:kernel-core-source` and `test:kernel-core` commands continue
to refer to this legacy implementation; they are not new-kernel acceptance tests.
Both packages remain outside the compiler-only bootstrap closure. This rename does
not resume a stopped kernel implementation workstream.
