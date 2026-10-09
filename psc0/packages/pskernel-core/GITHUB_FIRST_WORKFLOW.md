# PSKernel Core GitHub workflow for PSC0

Repository: `dwijayuda/pskernel`.
Current development branch: `psc0/pskernel-core-lean435-arena-v1`.
PSC0 base: `psc0/architecture-plan-v1` at
`e356162ddf1d0780337b2f510925455c70fb658d`.
Kernel location: `psc0/packages/pskernel-core`.

Read the live remote head before work and before every branch update. Use
expected-head leases and preserve published branches. Keep coherent changes in
GitHub and run builds/tests in cloud CI. The user's current instruction excludes
local checkouts, builds, tests and repository files for this work.

Use the current PSC0 authoring guide linked in README. Historical PSC1 profiles,
4.34 receipts and old topic branches are provenance, not current constraints or
evidence for this migration. Keep fail-closed checking and one semantic source;
never patch generated JavaScript or use a fallback checker after failure.

The 4.35 workflow checks the toolchain identity, kernel build, main metatheory,
all 84 companion proofs, foundations, dispatch regressions, historical Arena
verdict coverage and fresh 4.35 exports. Source portability and joint generated
compiler/kernel qualification remain separately reported until established.
Do not silently promote a compiler seed or default provider.

Record exact source commits, binary identity, workload versions, complete
coverage and every failure/decline/timeout. A doc-only evidence commit may cite
an earlier tested code commit explicitly; do not describe it as a fresh run.
