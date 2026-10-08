# PSKernel Core

This is the canonical portable PSKernel implementation, formerly
`packages/pskernel-selfhost`. Its package identity is `@proofscript/pskernel-core`
and its Lean modules use `Ps.KernelCore`. The former experimental core is
preserved in `../pskernel-core.old3`; see [PACKAGE_RENAME.md](PACKAGE_RENAME.md)
for the migration map and the separate provider-promotion boundary.

M3 is complete for the explicit small-workload Linux x64 profile. See
[`M3_ACCEPTANCE.md`](M3_ACCEPTANCE.md) for latency/memory budgets, corrected
benchmark evidence and scope. Native is the preferred CLI/server deployment
target; the JS artifact retains its portable source and bounded Node checks.
M4 adds an explicit native core provider and bounded dual checking; see
[`M4_ACCEPTANCE.md`](M4_ACCEPTANCE.md) for the contract, commands and CI gate.
`lean434-wasm` remains the trusted default; promotion is a separate decision.

## Project documentation hierarchy

Use these files in this order when making development decisions:

1. **`PSKERNEL_CORE_ARCHITECTURE.md`** — normative architecture decisions and anti-drift guardrails.
2. **`PSKERNEL_REFERENCE.md`** — canonical human architecture reference: Lean theory/source mapping, current audit, final target structure, trust classes, dependency law, scoring, and migration plan.
3. **`GITHUB_FIRST_WORKFLOW.md`** — canonical GitHub/cloud operating rules for this kernel topic branch.
4. **`DEVELOPMENT_PLAN.md`** — active phases, milestones, task-selection rule, and exit gates.
5. **`KERNEL_THEORY.md`** — theory-oriented explanation and recommended reading order.
6. **`KERNEL_RULE_REFERENCE.md`** — generated rule → implementation → Lean locator → test table.
7. **`LEAN_4_34_COMPATIBILITY.json`** — machine-readable feature-completeness matrix for Lean 4.34.0.
8. **`LEAN_4_34_CONFORMANCE.json`** — machine-readable concrete test coverage for every compatibility rule.
9. **`SELFHOST_EVIDENCE.json`** — optional historical/generated-bootstrap checkpoint evidence; not a normal development gate.
10. **`KERNEL_CONTRACT_V1.md`** — checked public entry points, resource outcomes and integration boundary.
11. **`PSKERNEL_ARCHITECTURE.json`**, **`LEAN_4_34_KERNEL_RULES.json`** and **`PSKERNEL_TCB.json`** — enforced ownership, executable rule evidence and trust inventory.
12. **`ARCHITECTURE_MIGRATION_REPORT.md`** — completed production migration and preservation evidence.

When documents disagree, the architecture guardrails and machine-enforced compatibility/self-host gates take precedence over historical planning text.

This package is the PSC1-profile implementation of the mature
`packages/pskernel/PSC1Kernel` reference kernel.

Official pinned Lean 4.34 behavior and source remain the semantic compatibility
authority. The frozen `packages/pskernel/PSC1Kernel` package remains a valuable
regression/differential oracle and should not be reshaped merely to satisfy
bootstrap syntax restrictions. This package instead
uses the source patterns already exercised by the compiler-only self-host fixed
point.

## Rules

- Lean 4.34 behavior remains the semantic authority.
- Official Lean 4.34 behavior/source is the semantic authority; `packages/pskernel/PSC1Kernel` remains a frozen regression/differential oracle.
- This source tree must pass the same `check-psc1-source.mjs --all-portable`
  gate as other portable compiler packages.
- No `Lean.*`, `Std.*`, `unsafe`, `extern`, `implemented_by`, custom
  macros/elaboration, `namespace`, `abbrev`, or `mutual` conveniences.
- Controlled executable `partial def` may exist during migration, but it is
  tracked separately and cannot turn failure, exhaustion, or nontermination
  into declaration acceptance.
- Replay, JSON import, test adapters, and host policy remain outside the
  semantic kernel package.

## Source layout

Production architecture migration is complete. The source tree contains only
the 79 canonical modules used by `SelfHost.lean`:

```text
src/Ps/KernelCore/
  Core/
  Environment/
  Runtime/Acceleration/
  Runtime/Capability/
  Checker/
  Admission/
  API/
  SelfHost.lean
```

Import `Ps.KernelCore.API.Kernel` for the checked public contract, or the
specific canonical owner for low-level integration. Temporary migration import
paths (`TypeChecker*`, `Theory/*`, and the old flat modules) have been removed.
All repository callers and Lake registrations use the canonical hierarchy.
The superseded migration inventory remains available in Git history.

The joint compiler/kernel fixed point is optional/manual and reserved for
explicit bootstrap/release checkpoints.

Declarations remain explicitly prefixed rather than relying on Lean namespace
conveniences. Tests compare the portable implementation against
the frozen reference implementation before each semantic slice is promoted.
