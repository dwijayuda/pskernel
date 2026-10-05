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

The primary historical checkout, `pskernel-integration`, and the algebraic
integration worktree showed many apparent modifications caused by Windows
CRLF normalization; re-checking with end-of-line whitespace ignored found **no
substantive content diffs** in those worktrees. Their existing archive branch
tips therefore remain sufficient preservation checkpoints.

The active portable-kernel worktree matched GitHub commit
`640fe165855056f49c0e854cf3b5520d00289a75` for tracked source. Its remaining
debugging files were intentionally gitignored scratch; they were preserved on
`archive/local-pskernel-debug-scratch-20261004` rather than merged into the
canonical kernel branch.

A large historical `joint-1410` worktree showed mass deletions caused by an
incomplete/path-length-damaged checkout. That state was not promoted as source
work and was left untouched locally.

A stale standalone `psc1kernel-selfhost-portable` checkout at
`ab702ec1bc203b731efc6eb0a8bfa08a59dcbf69` similarly showed a
path/sparse-checkout-damaged delete/recreate state. It was left untouched and
is not a canonical development input.

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
| `archive/local-artifact-transfer-49598e6b-20261004` | `49598e6b34d4725cb119bfc96d330a7fc1a12002` | staged verified PSC2 runtime bundle checkpoint that previously existed only as a detached worktree tip |
| `archive/local-lean-slim-a3108135-20261004` | `a31081352737628951fe37010a79752c658c7a1e` | slim native provider/compiler-semantics checkpoint that previously existed only as a detached worktree tip |
| `archive/local-pskernel-debug-scratch-20261004` | `fb12d8bad34c7032e7bbc95447ac419a47b5a3fd` | PSKernel self-host diagnostic scripts, WHNF probe, temporary mutual/nested source snapshots, and isolation scripts preserved without polluting the canonical topic branch |

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
