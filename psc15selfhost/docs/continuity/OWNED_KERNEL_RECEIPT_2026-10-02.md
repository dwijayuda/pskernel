# Owned-kernel checkpoint receipt

Received `pskernel-core-work-chat-handoff-2026-10-02.zip` with SHA-256
`f069a519c4ae268b7813e0906e5d1d587dd910fa8a1c63cc944569a26875c303`.
Every entry in both supplied checksum files matched. The complete package tarball
is `@proofscript/pskernel-core@0.1.0-checker.0`, SHA-256
`8e21439df03390655ac510226dd3c4d494c534d5277d65a9bcfdb910b1989215`.
The package was imported from that tarball, not PR #53 or remote candidate folders.
Its historical source/build/reference manifests are retained unchanged.

## Compiler checkpoint and integration base

The original `work/pskernel` checkout remains on
`fbfd10886bc290b006a9abc01d36153f2d7a89c7` with its replay alive. A separate
`work/pskernel-integration` checkout was created from that exact commit. The local
`checkpoints/compiler-fbfd1088-pre-kernel` archive retains committed sources,
uncommitted changes, exact working files, generated artifacts, binaries, logs and
the command transcript, with a SHA-256 manifest. Active logs are snapshots and will
need their final results appended to the evidence record.

Compiler commits on the integration branch:

- `e249a3835791062e375e55aa13b56250f59f36b5`: native JSON transport and installed TypeScript lookup.
- `e472a751038080387d296ad05a1fe06fff0c7547`: guarded tail-loop emission.

The canonical 55-file source replay reached a source fixed point with closure
SHA-256 `77e1046ec27bbaddccbdd4bc720c3dd85f785f358017f484bf548cba7814fe23`.
This is not an emitted-compiler fixed point. Both retained generated-compiler
replays still have no completed emission result; their latest completed phase is
parsing module 25, `Ps.Environment.Prelude`.

A full native checked build of the tail-loop source snapshot completed in 124,074 ms,
using the explicit native Lean alternative. It prepared 1,755 declarations and
checked a 9,891,566-byte canonical payload. Its TypeScript exactly matches the
independent native emission:
`caa7fe0f979ba223c09ed31512a201add2c31a6e424e201f0748490246f0e6b0`.
That result is Lean-backed bootstrap evidence, not generated compiler self-hosting.

## Reproduced receipt baseline

Linux Node 22.22.1, unchanged package, no dependency installation:

- `node --test test/*.test.mjs`: 264 passed, 0 failed, 0 skipped.
- `node scripts/verify-build.mjs`: PASS.
- `node scripts/verify-evidence.mjs`: PASS.
- `node scripts/release-check.mjs`: exit 1, expected; release remains blocked.

Windows Node 26.7.0 passed 262/264; the executable-bit and symlink tests require
POSIX filesystem behavior. The Linux run covers both. The combined-checkout test
also executes the complete 264-test suite on POSIX and verifies release rejection.
These identity checks do not rerun the historical Lean differential computations.

## Ownership and remaining blockers

The user's subsequent instruction retires the old `pskernel-core` package and its
routing. The integration tree removes the `Ps.KernelCore` source path, routing,
Lake targets and obsolete parity tests. Its source remains recoverable from Git
and the protected compiler checkpoint. `Ps.Kernel` now resolves to the received
owned package. No KernelOne or stopped legacy-core development is resumed.

Lean Wasm remains the default checker; native Lean remains the explicit alternative.
The owned package is private, non-authoritative and excluded from the portable
compiler closure. Its generated semantic JavaScript is the unmodified received
artifact. No failing or unsupported check is converted into acceptance.

The received source elaborates to 376 declarations with the current PSC seed, but
canonical admission fails with `unsupportedDeclaration`. The current nested
recursor adapter covers only its documented container shapes. The owned checker
also lacks inductive admission and universe-polymorphic term checking. Native Lean
compilation independently reports `prefix` as a reserved identifier in
`Ps/Kernel/Universe.lean:59`; it has not passed. A source fix requires a measured
regeneration and new evidence, not edits to generated JavaScript or relabeling the
historical manifests. Full dependency inventory, exact checked emission, owned
closure admission and the C2/C3 plus K2/K3 fixed points remain release blockers.

## Parameterized direct-recursion adapter follow-up

The inventory localized the canonical admission failure to `PsKernelList`: the
adapter mistook a direct recursive field `PsKernelList alpha` for nested recursion.
Direct applications now retain their arguments and are classified as direct only
when those arguments do not themselves contain the inductive family. The existing
nested-container restrictions are unchanged. A generic-list fixture, structural
wrapper lookup and nested-self-argument negative case cover the distinction.

All nine native checked-seed cases passed. The real native Lean provider then
accepted the received 376-declaration kernel source in 5,387 ms. Canonical
admissions SHA-256:
`f5db2da9f85517eae88c96829f6bd61fed9ede7e31dbc8a86660bbe75f3c259b`.
This is external Lean admission of the owned source, not owned-kernel admission
or a self-hosted fixed point. The received package bytes and historical manifests
remain unchanged.
