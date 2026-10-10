# PSC0 AI work state — target-toolchain identity in progress

## Authorized slice (2026-10-11)

Repository `dwijayuda/pskernel`, branch `psc0/npm-modular-packages-v1`.
Start: `2cbe78e3b09504091026434ea3b9a5d3f49b7941`.
The previous frontend resource milestone is complete: implementation `29c2d611a39d7c3187b1b8d333e5d023090bba9f`, successful fast run `38083824580`, 50/50 host tests on Linux/Node22 and Windows/Node26, exact source and retained runtime preservation. Its full state is archived unchanged at [AI_WORK_STATE_FRONTEND_2cbe78.md](docs/history/AI_WORK_STATE_FRONTEND_2cbe78.md), blob `1e28ce878faf256e61e3f354d929427c462677c6`. Do not restart it.

The user authorized continued cost-controlled architecture implementation. This slice closes the remaining target identity gap: the old parent captured TypeScript's launcher/package manifest but did not bind native executable/library bytes. It also synchronously invoked a wrapper, delaying parent cancellation.

## Canonical plan and owners

- `npm-cli/target-files.mjs`: binary-safe bounded streaming inventory, immutable package-tree identities and revalidation.
- `npm-cli/target-process.mjs`: one direct native process, no shell/PATH lookup, sanitized environment, wall/cancellation/output limits, wait for actual close.
- `npm-cli/target-toolchain.mjs`: exact TypeScript7.0.2/platform metadata, selected installed native executable, fixed monolithic-target plan and product hashes.
- `npm-cli/build.mjs`: bind target plan to checked frontend handle; revalidate source AND target before the existing single publication switch. `psc check` remains target-independent.
- [Target contract and research](docs/PSC0_TARGET_TOOLCHAIN_BOUNDARY.md).

The generated TS profile ignores project config, uses a private empty typeRoots and noResolve to avoid inheriting ambient npm types or adding foreign target files. Ordinary ProofScript source-library imports remain unchanged. The actual retained TypeScript launcher is the independent comparison reference for this host change.

## Preservation boundaries

Do not change the 69 portable compiler source files/64-module closure, grammar (`ps-0.9-r3/new-only`), strict-SH/1 entry, seed, TypeScript7.0.2, bootstrap Node22.23.3, Lean4.34 or any kernel source/runtime adapter. Kernel proof and self-host work is owned elsewhere. No extra npm dependencies, new backend, arbitrary plugin sandbox, full verified profile, npm publication or main merge.

Use GitHub and cloud CI only. No local files/checkouts/builds/tests or Desktop Commander. Read current HEAD before writes and use expected-HEAD non-force updates. Retain current fast source identity guard and reuse runtime run `38075437516`, artifact `11678641329`, source `2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a`. The prior archive SHA256 is `3b89239132db2003a3ee0cc01c2c4c9795be4d4ae0097d86a62616fc48fa122a`; expiry is 2026-11-09. No full C2/C3 or compiler/kernel regeneration.

## Required validation, not yet claimed

Keep the original 50 host tests and all installed PS/Lean suites. Add target identity/resource negative tests and native-vs-retained-launcher equality on actual compiler-emitted TS on both OSes. Test ambient typing isolation, exact receipt plan binding, changed native/library bytes and unchanged previous outputs on failure. A passing fixture is not a universal semantic preservation theorem.

## Limitations

Captured installed hashes detect drift but do NOT authenticate registry, CI, OS, dynamic loader or publisher. No hostile-native-code sandbox or total RSS cap is claimed. Toolchain file capture has finite byte/depth/count budgets, not hard IO deadlines. Backend proof, effects/specification/axiom policies, arbitrary plugin isolation, independent scoped compilation and new installed C2/C3 remain separate milestones.

Status: coherent implementation and tests are being assembled; do not claim qualification until actual final CI results are recorded here.
