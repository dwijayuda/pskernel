# PSKernel GitHub-first development workflow

GitHub is the canonical source of truth for this PSKernel topic branch.

Repository:

```text
dwijayuda/pskernel
```

Kernel topic branch:

```text
psc2/psc1kernel-selfhost-portable
```

Integration branch:

```text
psc2/selfhost-lean-kernel
```

The repository-wide policy is maintained on the integration branch in
`psc15selfhost/docs/architecture/GITHUB_CLOUD_WORKFLOW.md`.

## Rules

1. Start every task by reading the current GitHub branch head.
2. Read/edit source through GitHub/cloud tooling; do not rely on a developer
   workstation as persistent state.
3. Re-read the target branch before every update.
4. Never force-push over newer remote work.
5. Push coherent checkpoints frequently.
6. Preserve published branches/history.
7. Use local execution only as an optional accelerator/diagnostic cache.
8. Local build/debug artifacts are never semantic authority.
9. Portable kernel changes must keep the fast authoritative gates green:
   source profile, PSC1 check, Lean build, compatibility/conformance,
   frozen-reference differential, and canonical `.ps` recheck.
10. Generated compiler/kernel fixed-point reproduction is manual/optional for
    this branch unless an explicit bootstrap/release task requests it.

## Noncanonical local state

Do not use these as development inputs unless a particular artifact is
deliberately promoted into the repository:

```text
psc15selfhost/.lake/
psc15selfhost/lake-manifest.json
psc15selfhost/.continuation/
temporary debug scripts
temporary generated source snapshots
benchmark scratch files
```

Existing local files are not deleted by this policy.

## Preserved workstation state

The workstation-to-GitHub migration was completed on 2026-10-04. Substantive
local-only states were preserved on `archive/local-*-20261004` branches
instead of being merged into newer heads.

The integration branch records the full archive inventory in
`psc15selfhost/docs/continuity/GITHUB_FIRST_MIGRATION_2026-10-04.md`.

Archive branches are recovery references, not merge queues. Compare individual
changes against the latest GitHub head before reusing them.

## Kernel development priority

Current kernel work remains:

```text
semantic compatibility
  > readability/explainability
  > measured native performance
  > convenience
```

For performance/readability work, prefer small GitHub commits that each close
one invariant and let the portable CI establish semantic safety.
