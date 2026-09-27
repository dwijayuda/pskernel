# PSC2 workspace status

Snapshot: 2026-09-27 Asia/Jakarta (2026-09-26 UTC).
Implementation base: `dd2fa706b4a462ef34ecbce32510b8c61e47819b` on `main`.
The earlier inspected `5077149c` differs only by the addition of
`docs/selfhost/POST_PSC1_PLATFORM.md` at this baseline. Documentation created by
this change does not alter the implementation findings below.

## Measured baseline

Commands ran from `psc2selfhost/` with Node v24.19.0. Lean and Lake were not
available in the review environment. These are local observations, not CI or
production qualification.

| Command/check | Result | Meaning |
| --- | --- | --- |
| `node scripts/check-workspace.mjs` | FAIL | `PSC1_WORKSPACE_MANIFEST_MISSING: packages/pskernel/package.json` |
| `node check-psc1-source.mjs` | PASS, limited | 85 modules, 15 source roots; embedded kernel skipped due to missing manifest |
| `node scripts/check-ir-neutrality.mjs` | PASS, limited | Two IR files pass lexical neutrality guard; not a semantic preservation proof |
| `node scripts/bootstrap-project.mjs` | FAIL | `PSC1_BOOTSTRAP_UNKNOWN_PACKAGE: Ps.BackendRust.Module`; failure occurs during read-only source collection |
| Lean build/tests | NOT RUN | Lean/Lake unavailable |
| JS generation/fixed point | NOT RUN | Prerequisite failures; no generated compiler evidence established |
| Embedded-kernel/TS/Lean differential on this tree | NOT RUN | Inherited kernel documents are not fresh local results |

Before these documentation additions: 189 files, 146 `.lean` files and about
63,436 Lean lines including tests. Compared to `selfhost/` at the same revision:
93 identical files, 30 changed counterparts, 66 additional files. Counts describe
the baseline only and must not be used as completion metrics.

## Confirmed source findings

| ID | Finding | Owning next gate |
| --- | --- | --- |
| B01 | Embedded kernel lacks npm/ProofScript metadata, bypassing the source guard | WORKSPACE |
| B02 | Lake lists `Ps.Host.KernelBridge`, but only `KernelBridge.lean.bak` exists | WORKSPACE/LEAN |
| B03 | Bootstrap/generated scripts and Lean host loader retain old package mappings that omit Rust/Wasm | WORKSPACE/SOURCE |
| B04 | `psCompilerCheckElaborated` validates admission serialization, not actual independent admission | ADMISSION |
| B05 | TS/Rust API emission starts from elaborated declarations, without an admitted wrapper | ADMISSION |
| B06 | Compiler `PsExpr` and embedded `PSC1Kernel.Expr` have different representations; no active normal-path adapter found | ADMISSION/KERNEL |
| B07 | CLI identifies PSC1; API wires TS/Rust, while Wasm exists separately in backend modules/tests | SOURCE/TARGETS |
| B08 | Existing source/text fixed-point scripts do not establish admitted-Core/IR fingerprint equality | DUAL/FIXED |
| B09 | Inspected workflows target `selfhost/`; no explicit `psc2selfhost` workflow found | WORKSPACE/RELEASE |
| B10 | Rich PSC2 contracts/prover/platform design is not implemented by merely copying the bootstrap packages | LANGUAGE/CONTRACTS |

The embedded kernel has its own Lake project and significant checking/replay
code. Its documents report bounded semantic milestones, with broader maturity
and full-environment/formal claims still distinct. That supports reuse as an
integration candidate, not a claim of a completed generated kernel here.

## Current milestone state

M0 is open with reproducible structural failures. M1 admission integration is
open. M2-M4 compiler/kernel closure is not established. M5 PSC2 profile delivery
is planned with inherited partial machinery. M6 has substantial backend source,
but host self-generation and this workspace's conformance remain unverified.

**Next action:** execute [foundation repair](plans/01_FOUNDATION_REPAIR.md),
then fix the first actual owned-source/admission blocker. Do not start a full
kernel rewrite, broad tactic expansion or an expensive whole-Std campaign merely
to clear these local integration problems.

## Updating this file

Keep the baseline above as dated history or replace it with an explicitly dated
superseding snapshot. Add exact revision/commands/logs for new evidence, and
update the first blocker. A branch's successful run cannot be copied here as a
PASS unless the relevant code/profile is integrated and evidence applicability
is demonstrated. No completion percentage is asserted.
