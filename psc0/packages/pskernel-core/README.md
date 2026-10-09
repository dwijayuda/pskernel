# PSKernel Core for PSC0

This is the active kernel development package at `psc0/packages/pskernel-core`.
It imports the complete source, companion proofs, and metatheory from
`pscv/prove-pskernel-core-v1` at `85ccb4e1103d77ed77c09c5795fc48ae4ea8ea62`,
with the bounded cache policy and Arena adapter from `132d817071cd62c23a70c15984d6c73e14d6e856`.

The target is **Lean 4.35.0-rc4**, commit
`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. Run Lake from this directory:
the package has its own toolchain and does not replace PSC0's selected compiler
seed or its historical provider receipts.

## Authoring and ownership

Use [PSC0's current bounded self-host profile](../../docs/selfhost-language/CURRENT.md).
The former PSC1-selfhost-stable/1 and PSC1-portable-selfhost/1 restrictions are
historical, not this package's authoring policy. The currently qualified PSC0
frontend still has finite capabilities; Lean-native computed fields, pointer
primitives, arbitrary effects, and Std collections are not automatically portable.
Handwritten Lean remains source authority. Joint generated compiler/kernel
qualification has not been established by copying this package.

Production source is in `src/`; `metatheory/` and `proof/` contain assurance.
`host/` handles Arena transport. `reference/` is a frozen regression oracle,
not the semantic authority. The 4.35 native-evaluation change intentionally
differs from that 4.34 oracle. Native evaluator callbacks are inert in the
production checker; their legacy helper and record types remain for source
compatibility and historical proofs.

## Commands

- `lake build psc_kernel_core_arena`
- `npm test`
- `npm run test:proofs`

The cloud workflow `psc0-pskernel-core-435.yml` checks the exact toolchain,
builds the full metatheory and all 84 companion proofs, runs foundations and
evaluation-order regressions, and gates Arena verdicts and case counts.
Historical Arena 4.34 exports require explicit `--check-historical`;
the default adapter requires the exact 4.35.0-rc4 metadata identity.

The preserved LEAN_4_34 documents and M3/M4 receipts describe historical
checkpoints. They do not certify this migration. Current research, changes,
and outstanding evidence are recorded in [RESEARCH_AND_MIGRATION.md](RESEARCH_AND_MIGRATION.md).
