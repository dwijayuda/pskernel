# PSC1Kernel portable self-host port

## Project documentation hierarchy

Use these files in this order when making development decisions:

1. **`PSKERNEL_SELFHOST_ARCHITECTURE.md`** — normative architecture decisions and anti-drift guardrails.
2. **`DEVELOPMENT_PLAN.md`** — active phases, milestones, task-selection rule, and exit gates.
3. **`KERNEL_THEORY.md`** — theory-oriented explanation and recommended reading order.
4. **`LEAN_4_34_COMPATIBILITY.json`** — machine-readable feature-completeness matrix for Lean 4.34.0.
5. **`SELFHOST_EVIDENCE.json`** — fixed-point and generated-runtime evidence for a concrete closure.
6. **`MIGRATION_INVENTORY.md`** — historical migration baseline only; it is not the active roadmap.

When documents disagree, the architecture guardrails and machine-enforced compatibility/self-host gates take precedence over historical planning text.

This package is the PSC1-profile implementation of the mature
`packages/pskernel/PSC1Kernel` reference kernel.

The reference package remains the Lean-4.34 semantic oracle and should not be
reshaped merely to satisfy bootstrap syntax restrictions. This package instead
uses the source patterns already exercised by the compiler-only self-host fixed
point.

## Rules

- Lean 4.34 behavior remains the semantic authority.
- `packages/pskernel/PSC1Kernel` remains the implementation/differential oracle.
- This source tree must pass the same `check-psc1-source.mjs --all-portable`
  gate as other portable compiler packages.
- No `Lean.*`, `Std.*`, `unsafe`, `extern`, `implemented_by`, custom
  macros/elaboration, `namespace`, `abbrev`, or `mutual` conveniences.
- Controlled executable `partial def` may exist during migration, but it is
  tracked separately and cannot turn failure, exhaustion, or nontermination
  into declaration acceptance.
- Replay, JSON import, test adapters, and host policy remain outside the
  semantic kernel package.

## Migration order

1. Name/Level/Expr/substitution.
2. Declarations, local/global environment and checker state.
3. WHNF and inference.
4. Algorithmic definitional equality preserving Lean ordering.
5. Quotients.
6. Ordinary, mutual and nested inductive admission.
7. Complete PSC1 check and canonical `.ps` generation.
8. Generated TypeScript/JavaScript differential replay against the reference.
9. Checked-provider integration.
10. Joint compiler/kernel fixed point.

The source is intentionally flat and explicitly prefixed rather than relying on
Lean namespace conveniences. Tests compare the portable implementation against
the frozen reference implementation before each semantic slice is promoted.
