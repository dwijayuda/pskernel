# PSC0 AI work state — checked-host implementation

## Authority and scope (2026-10-11)

Repository: `dwijayuda/pskernel`. Work branch: `psc0/npm-modular-packages-v1`.
Starting HEAD: `58234f52f15f961f599799e2e93ec1f1f0f86962`.
Architecture: [PSC0-ARCH/1](docs/PSC0_SOUNDNESS_SECURE_EXTENSIBLE_ARCHITECTURE.md).

The user authorized systematic, cost-controlled implementation of P0/P1/P2, preserving compiler self-hosting and using the latest **qualified** self-host language. Kernel implementation and metatheory are owned by another branch and MUST NOT be changed here. Do not add backends, a general plugin framework, full PSCV, a new language dialect, or a new kernel.

All repository reads/writes use GitHub. All execution/tests use cloud CI. No local checkout, local builds, Desktop Commander, force pushes, or automatic npm publication.

## Compiler self-host boundary

- Authoritative language is bounded `ps-0.9-r3`, new-only; qualified strict PSC0-SH/1 entry remains `psCompilerSh1TypeScriptSources`. Generic APIs do not silently select that strict profile.
- Preserve the selected R seed, TypeScript 7.0.2, bootstrap Node 22.23.3 and Lean 4.34.0. Do not confuse newer language-design documents with an already qualified executable dialect.
- Qualified compiler source: `1fa5559a72b293defc56ef7e7020cf82d4b44b79`; completed evidence run `38027413274`, following original/continuation C1/C2/C3 runs. Details are in [CURRENT.md](docs/selfhost-language/CURRENT.md).
- This slice changes only host/package/test orchestration. A fast Git-object identity guard must compare the complete compiler import closure, all twelve compiler source packages, grammar/seed/toolchain inputs and the kernel subtree to their pinned baselines. Any difference fails and requires deliberate requalification; it must not be papered over by changing the baseline.
- Reuse immutable compiler/kernel runtime artifacts from successful npm run `38075437516`, source `2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a`, artifact `11678641329`, rather than rebuilding unchanged runtimes on each host edit.
- Fast qualification is source-preservation plus installed-host behavior, **not a new C2/C3 fixed point** and not joint compiler/kernel self-hosting. Expensive release/fixed-point jobs remain explicitly requested, not a default edit loop.

## Implementation plan and canonical owners

P0: validate the new publishable workspace schema without weakening source-root validation; distinguish private stdlib authoring from staged stdlib; audit every check/emit entry point.
P1: one provider-neutral checked-prepared session shared by npm CLI and existing host adapters. Freeze accepted graphs, retain opaque session-local authority, re-encode before emission, reject copied/stale handles and wrong provider identity. No kernel fallback.
P2: bounded immutable source/package/lock snapshots; capture bytes once, track absent metadata and realpaths, revalidate before publication. Publish an immutable generation and switch one executable entry point, rather than pretending a set of renames is one transaction.

Portable compiler logic stays in its current `.lean`/generated `.ps` source. Files under `npm-cli/` are host filesystem/process integration, deliberately outside the self-host compiler closure. Do not migrate portable compiler functionality into handwritten JavaScript.

## Validation strategy

1. Source-identity/import-closure guard; no Lean build.
2. Existing checked-session tests plus bounded host invariants (forged receipt, mutation, rejection, input drift, resource limits, symlink escape and output transaction failures).
3. Repack the previously qualified runtime with the current host in cloud CI; install in clean prefixes on Linux/Node22 and Windows/Node26; compile small `.ps` and `.lean` examples and an npm source library. Do not regenerate the compiler or kernel.
4. Upload exact source/runtime identities and test evidence. Update this file with actual run results; never infer pass from a job merely being queued.

## Status at implementation checkpoint

Implementation is being prepared; no new validation success is claimed yet. Read the current branch HEAD and CI before continuing or writing. Preserve concurrent changes with an expected-HEAD non-force lease.

## Limits and deferred work

Kernel JS remains the requested default in the npm CLI, with bounded empirical assurance only. Kernel proofs, new kernel generation, arbitrary executable extension isolation, full effects/contracts, complete source-to-JS preservation, and full installed compiler C2/C3 reproduction are separate milestones. Source-only third-party libraries remain allowed; they receive no proof authority.

The previous 50 KB strict-SH/1 work state is preserved byte-for-byte at [AI_WORK_STATE_BEFORE_CHECKED_HOST.md](docs/selfhost-language/strict/history/AI_WORK_STATE_BEFORE_CHECKED_HOST.md), original Git blob `349308be31b8d6880b2b0a9a5201e776ddb06d36`. Its historical qualification is not superseded or rerun by this host change.
