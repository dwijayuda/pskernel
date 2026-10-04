# GitHub-first migration checkpoint — 2026-10-04

## Status

The PSC2/PSKernel development workflow has been migrated from workstation-first
development to GitHub-first cloud development.

Canonical repository:

```text
dwijayuda/pskernel
```

Canonical integration branch:

```text
psc2/selfhost-lean-kernel
```

Active PSKernel self-host topic branch:

```text
psc2/psc1kernel-selfhost-portable
```

GitHub branch state, committed architecture/contracts, and CI are now the
persistent source of truth. Local worktrees are optional execution/diagnostic
caches only.

See `docs/architecture/GITHUB_CLOUD_WORKFLOW.md` for the operating policy.

## Local repository audit

Before switching authority to GitHub, the authorized Windows workstation was
inspected for:

- current repositories/worktrees and active branches;
- tracked unstaged/staged changes;
- untracked source/debug/build files;
- branch divergence from GitHub;
- remote state;
- local-only prebuilt artifacts.

No local or remote branch was deleted. No published history was rewritten. No
force-push was used.

The primary local `psc2/selfhost-lean-kernel` checkout was substantially
behind GitHub and contained mostly CRLF/build/scratch noise plus a small
tail-loop development state. The active portable-kernel worktree contained no
tracked modifications; its untracked files were build outputs and debugging
snapshots.

A large historical `joint-1410` worktree showed mass deletions caused by an
incomplete/path-length-damaged checkout. That state was not promoted as source
work and was left untouched locally.

## Preserved local checkpoints

Substantive local-only work was committed to separate archive branches instead
of being merged into newer remote heads:

| Archive branch | Commit | Preserved state |
| --- | --- | --- |
| `archive/local-primary-fbfd1088-20261004` | `df4b0f3f5b6ebeaac4ff5e8dbb7d6d1d62335833` | tail-loop/backend-TS working state from the stale primary checkout |
| `archive/local-collections-234ff270-20261004` | `5e79c35fc96371b39ee5a59544eecef529d6235c` | collections and algebraic-projection kernel work |
| `archive/local-compiler-bootstrap-101c15a3-20261004` | `84ddd5cf71bb71ab12e2b284bad5294c496e5096` | compiler/bootstrap status and fixed-point continuity note |
| `archive/local-jsdev-9954fa0e-20261004` | `0f2cd76a7c25acc52e44ea020ee35ee694501c95` | JS self-host profile experiments |
| `archive/local-ts7-ci-b4d8d875-20261004` | `4b3246fc7bf733d037523d9d15ad92ced539248e` | TypeScript-7/Lean-checked CI experiment |
| `archive/local-slim-prebuilt-3c49f7d8-20261004` | `0408f18b47e6cf9b42fce023d24fd73ba79c95af` | slim native Lean provider prebuilts and manifest |

These branches are preservation checkpoints only. They must not be merged
blindly into the current integration branch; recover individual changes only
after comparing them with the current GitHub head.

## Local state intentionally not promoted

The following remain local and are not canonical inputs:

- `psc15selfhost/.lake/`;
- `psc15selfhost/lake-manifest.json`;
- `psc15selfhost/.continuation/`;
- temporary debug scripts;
- temporary generated mutual/nested kernel snapshots;
- benchmark scratch files;
- path-length-damaged/incomplete worktree deletions.

They were not deleted during migration.

## Cloud validation

The integration branch contains:

```text
.github/workflows/psc15selfhost-cloud.yml
```

The workflow checks the pinned Lean 4.34.0 toolchain, portable self-host source
profile, semantic compiler layers, VerifiedIR/erasure tests, minimal self-host
tests, TypeScript backend tests, and semantic-boundary enforcement.

For PSKernel-specific work, the topic branch's portable-kernel workflow remains
the semantic/conformance gate. Generated compiler/kernel fixed-point proof is
manual/optional for PSKernel performance/readability development.

## Operating rule after this checkpoint

Future development must:

1. read the current GitHub branch head before editing;
2. use GitHub content/commits as the source of truth;
3. create topic branches from current remote heads for substantial experiments;
4. publish coherent checkpoints regularly;
5. re-read the target remote branch before integration;
6. never force-push over newer remote work;
7. keep local-only files out of architectural decisions;
8. use cloud/CI validation whenever available;
9. preserve existing branches/history unless explicit deletion is requested.

A future cloud agent should be able to continue development using only the
repository, branch history, architecture documents, and CI results.
