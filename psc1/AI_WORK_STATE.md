# PSC1 work state — seven readable direct backends and npm continuation

Updated 2026-10-20. Branch: `feature/psc1-seven-backend-npm-v1`.

## Verified baseline

Parent: `ea03ce125ad4d4902070d6fef92d92b51cb2e857`, PR #163, still open/draft.
PR #162 remains separate. Existing focused Linux run 39349606554 is successful.
The actual compiler/provider is Lean 4.35.0 commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
The first Practical Core receipt and status matrix remain unchanged. Full families
are not complete. See docs/PSC1_PRACTICAL_CORE_SLICE_1.md and its qualification JSON.

## Authorized objective

Implement seven readable direct targets, backend-owned selective runtimes, a
usable npm-distributed native toolchain, optional independently checked npm source
libraries, and optional TS+JS output through two direct emitters from one snapshot.
No releases, publication, merges, kernel changes, unrelated branches, local builds
or full self-host/fixed-point tests. Use connected GitHub and Linux CI only.

## Current work

The new backend-common Script plan is an implementation candidate. It consumes
rechecked existing executable IR, specializes and rechecks, alpha-renames lexical
binders, preserves one-time left-to-right evaluation, and makes branches/matches
explicit for Python/PHP printers. No new source-language feature or VM is introduced.
The code is not qualified until new compilation/execution evidence is recorded.
Architecture decisions and source-backed findings: docs/PSC1_BACKEND_ARCHITECTURE.md.

## Next implementation tasks

1. Implement independent Python/PHP printers and backend-owned helper catalogues.
2. Integrate the native CLI and the existing transactional publisher, retaining all
   original targets and their negative boundaries.
3. Qualify actual target execution, primitive ABI checks, closures, ADTs, arrays,
   recursion, Unicode, runtime selection, maps and failed-publication preservation.
4. Implement TS+JS joint emission using a single admitted input and commit point.
5. Build unpublished native npm tarballs; test fresh install outside the checkout,
   with no Lean/source-checkout dependency. Demonstrate an optional source library.
6. Replace stale current architecture/readme claims while keeping exact history.

## Evidence rules

A successful old run does not qualify this branch's changed bytes. Record exact
source/checkout/tree, run, platform/tool versions, artifacts and bounded coverage.
Do not mark Python/PHP supported until their real emitted programs pass. Keep public
component ABI Bool-only. Type validation is not a backend-preservation proof.
