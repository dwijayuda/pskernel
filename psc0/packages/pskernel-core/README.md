# PSKernel Core for PSC0

This is the active kernel development package at `psc0/packages/pskernel-core`.
It imports the complete source, companion proofs, and metatheory from
`pscv/prove-pskernel-core-v1` at `85ccb4e1103d77ed77c09c5795fc48ae4ea8ea62`,
with the bounded cache policy and Arena adapter from `132d817071cd62c23a70c15984d6c73e14d6e856`.

The target is **Lean 4.35.0-rc4**, commit
`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. Run Lake from this directory:
the package has its own toolchain and does not replace PSC0's selected compiler
seed or its historical provider receipts.

## Correctness status

The metatheory and model/consistency proof are **unfinished**. The checked audit
in `metatheory/Ps/KernelCore/Metatheory/JudgmentAdequacy.lean` shows that the
legacy algorithmic equality rule permits arbitrary equality, and its typing
relation consequently inhabits every type. This is a defect in the proof
specification, not an exhibited executable acceptance of False. Existing
operational refinement theorems cannot be used as a model-soundness proof.

The active string comparator now has a specified equality decision and a proof
of its positive-result law. This closes one primitive obligation; it does not
repair the inadequate judgments. The new semantic layer constructs a nontrivial proposition/sort algebra and
connects the actual sort-inference case to it. The proposition-classifier and
proof-irrelevance bridges retain explicit, still-open semantic callback
obligations. Dependent functions, complete checker correspondence, and declaration
model preservation remain unfinished; the local empty-denotation theorem is not
a consistency theorem for the complete kernel.
See [the current audit and reference comparison](RESEARCH_AND_MIGRATION.md).

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

## Prior native sharing stage and its measured results

[Run 38001623085](https://github.com/dwijayuda/pskernel/actions/runs/38001623085) at
`e9b0cdae39ea9a2ff0d7da841e0faacbf7943df4` verifies the native sharing layer,
the existing metatheory proof suite and all 84 companion proof files. Foundations,
scope/cache regressions and the depth-32 shared-expression family pass.
Fresh 4.35 Prelude, UTF8, XOR and Int64 dependency closures also pass.

The pure expression specification remains in Core/Expr/Basic. Executed syntax
walks use intrinsically certified memo entries, exact input/cursor validation,
and proved compiler simplification. Prepared substitution arguments avoid
repeated lifting of closed expressions. Operation-local scratch tables are separated from persistent hash checkpoints.
Context-free operations keep a fixed memo cursor; binding-sensitive operations
advance it. The two bounded eligibility scans share one scalar worker with an
all-input refinement theorem. Scope exit restores all parent caches and metadata.

This is a **Lean-native experiment**: `portable: false` and
`jointSelfhostQualified: false` are deliberate package metadata.
The current PSC0 frontend/backend has not qualified these execution primitives.
Portable graph storage and batched telescope/context transport remain open.

**Full conformance remains incomplete, and the final native candidate regresses
in the controlled performance check.** Historical and fresh 4.35 Init/Std time
out at their unchanged 500/590-second limits; Mathlib is skipped by its
prerequisite gates. On the same 500,000-record prefix and runner, the repair
baseline completes in 143.53/142.83 seconds while the candidate times out twice
at 180 seconds. Its lower measured memory is censored by timeout. This draft
experiment is not eligible for provider promotion.
See [the exact receipt](MIGRATION_EVIDENCE.json) for all completed measurements.

The [research report](RESEARCH_AND_MIGRATION.md) compares pinned official Lean,
Con Leche, current Con Ron, Nanoda and Lean4Lean, audits historical Arena branches,
and records both successful and failed experiments. Default-provider selection
and generated compiler/kernel qualification remain separate.
