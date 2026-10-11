# Production architecture migration

Phase B of `DEVELOPMENT_PLAN.md` implements the production ownership model in
`PSKERNEL_REFERENCE.md`. Lean 4.34.0 pinned semantics, the compatibility/conformance
matrices, and `PSKERNEL_CORE_ARCHITECTURE.md` retain their existing authority.
This completion does not claim formal verification, Assurance Plane completion,
provider promotion, or a change to `pskernel-core.old3`.

## Completed ownership

- Test and benchmark monoliths are split into registered Lake support modules.
- Core values and substitution live under `Core/`.
- Environment history, wrapper representation, lookup and mutation have separate
  `Environment/` owners. The semantic view excludes indexes and native capability.
- Checker rules live under `Checker/`; `Ops` defines the internal callbacks,
  `Knot` owns recursive wiring, and Session calls the concrete operations.
- Declaration, Quot and ordinary/mutual/nested admission live under `Admission/`.
  Shared occurrence, parameter, elimination and recursor-validation phases have
  explicit owners without merging distinct admission algorithms.
- Runtime acceleration and trusted native capability have separate owners.
- `ResourcePolicy`, typed failure outcomes and `KernelContract-v1` distinguish
  requests, checked receipts and admitted sessions. Checked receipts are rechecked.
- A 61-row rule inventory preserves all 34 top-level compatibility rows and adds
  27 algorithm, resource and API mappings to executable regression evidence.

## Enforced exit gates

`psc1kernel-architecture-audit.mjs` checks target identity, the 79-module semantic
closure, canonical owner uniqueness, import fences, retired compatibility
shims, the single Knot wiring owner, valid Lake registrations, rule symbol ownership,
test evidence reachable from the foundation executable, and the inventory of 136
legacy diagnostics. The completion flag additionally requires the production
layers and rejects unowned or unreachable source implementations.

The portable workflow retains all existing gates: source/profile and pattern
audits, complete compatibility/conformance audits, generated rule-reference
freshness, PSC1 checking of every source module, native foundation/differential
tests, and canonical ProofScript translation and rechecking. The benchmark
workflow remains separate. Completion should always be assessed against the
workflow results for the exact commit being used.

## Checkpoints and preservation evidence

The Checker migration was verified at `a8d59f0cea51306108b01218c0ca1fb9a903a827`.
Subsequent structural checkpoints are:

- `72c16708901c353f14754dd9f8ec2d59008e7082`: unified admission ownership;
- `831e1af113a01165ab22e42a74ece59e0fa75633`: Core/Environment ownership and Lake audit;
- `b6dbf1fd8c3525cf5049efa9bff435124543ee9a`: typed outcomes and checked public contract.

The admission and Core/Environment moves compare existing declaration bodies
before and after the move. A broader comparison to the pre-Checker baseline
`a3247d659283d0f8482e7e813a3141c070ee902c` preserves all 682 declarations: 679
bodies are unchanged, and three Session entry points delegate to the same
concrete operations now owned by Knot. New resource/API declarations add wrappers
and outcomes without rewriting the existing admission or checking algorithms.

## Intentional representation choices

The 71 temporary compatibility modules were removed after all repository callers
were changed to canonical imports. The source tree now matches the 79-module
semantic closure. The optional fixed-point workflow checks canonical generated
paths. The superseded migration inventory is retained in Git history.
The legacy environment record still carries native configuration for existing
callers; the new public Session configures capability explicitly and strips it
from returned history. This preserves old constructor behavior while making the
semantic-history boundary explicit.

Context retains existing checker context, binder and builtin helpers. Positivity
analysis remains with ordinary/mutual constructor analysis where its distinct
shapes are used. No empty modules or duplicate abstraction are introduced merely
to reproduce every illustrative filename in the Reference.

Portable outcome payloads use `Except PsKernelError Payload`; custom runtime type
parameters remain prohibited by the PSC1 kernel profile. Public record
constructors are not cryptographic authority. Cancellation is sampled at entry,
fuel retains its existing recursive-bound meaning, and host stack failures remain
the host adapter's responsibility. See `KERNEL_CONTRACT_V1.md` for these precise
limits and the trusted integration boundary.

## Work outside this migration

Measured performance changes remain Phase C. Formal specification/refinement,
independent assurance, expanded fuzzing and proof-backed receipts remain Phase D.
The existing default provider and promotion gates are unchanged. Regression
evidence in the rule inventory is neither exhaustive branch coverage nor formal
proof coverage.
