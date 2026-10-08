# Owned decoder memory boundary — 2026-10-03

Base: `847aac5560ae203fee659884e0c788eb8fd7231c`, selected branch `psc2/selfhost-lean-kernel`.

This is a transport-only checkpoint. The generated checker.13 kernel, its source, all semantic outputs and their evidence are unchanged. A complete owned-checked compiler/kernel pair, joint self-hosting and release remain unachieved.

## Change

The disposable worker shares already decoded immutable natural numbers, UTF-8 text and structured names using bounded worker-local maps. Every occurrence is still validated, including shape, canonical natural syntax, Unicode validity, recursive name parents, depth and node limits. Full structured names remain distinct from dotted display names. No judgment, environment, typing result or reduction is cached by the host.

The default heap limit remains 512 MiB. `maxMemoryMb` permits only integer limits from 16 through 512 MiB; callers cannot raise the default cap. An actual worker heap exhaustion returns `accepted: false, errorKind: memory-limit`. Other worker failures still reject the operation. Termination errors cannot create a later unhandled rejection or a second successful outcome. No failed case falls back to another kernel or returns a partial environment.

## Executed evidence

The integrated Windows checked-host run passed 172 tests, with zero failures and one existing POSIX-only skip out of 173. This includes real checked frontend emission, TypeScript 5.8.3 compilation, execution, names that resemble map keys, malformed repeated values, and a forced 16 MiB heap exhaustion followed by an independent successful fresh session.

The separate Linux owned-core, text and wire suite passed 54/54 with no skips. Counts overlap and are not additive. Build/evidence identity and owned-default routing checks passed. The pinned semantic source/output identities are recorded in the companion receipt.

The first Windows attempt used the wrong TypeScript search path and rejected the compiler pin in 20 frontend cases. That failed run is preserved. The second run explicitly supplied the pinned TypeScript directory on PATH and passed; no frontend or kernel semantics were changed to make it pass.

## Evidence and scope

`owned-wire-memory-2026-10-03/receipt.json` records the commands, identities and outcomes. Its compressed run archive preserves both failed and successful logs. The Linux shared launcher recorded its own candidate source identity; the receipt separately identifies the checker.13 integration tree selected by the actual shell command, rather than attributing the Linux tests to a different kernel.

This checkpoint does not change the checker.13 semantic blocker or claim acceptance of the algebraic candidate. Full-source admission and subsequent checked compiler/kernel emission remain separate gates. The owned core stays the default; Lean native/WASM remain explicit references only. All repository edits are under `psc15selfhost/`.
