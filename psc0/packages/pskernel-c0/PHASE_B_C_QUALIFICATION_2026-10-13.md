# PSKernel-C0 — Lean 4.35 Phase B/C qualification ledger

**Date:** 2026-10-13  
**Branch:** \`perf/pskernel-c0-v7-rust-20261012\`  
**Target:** pinned stable \`leanprover/lean4:v4.35.0\`  
**Scope:** native \`.lean\`; no original-core changes, self-hosting, Rust provider or metatheory promotion.

## Qualified baseline before these changes

The native [CI 38316694316](https://github.com/dwijayuda/pskernel/actions/runs/38316694316) passed all source, semantic, store and benchmark stages at \`51f32f59\`. A **test-only** NDJSON decoder and official \`leanchecker --from-export\` agreed on 14 pinned exact-byte cases (7 accept, 7 reject), including an accepted 128-definition dependency chain and a rejected-last 128-definition chain. This does **not** establish a real Init/Std/Mathlib kernel-corpus result.

## Phase B — strict source-byte conformance boundary

New native test-only source behavior:

1. **Lossless input discipline for the supported subset.** Every parsed name, level, expression, metadata header and definition must have recognized fields. Nested names, applications, constants, binders, lets, projections and regular hints are checked for extra semantic fields. Unrecognized annotations or simultaneous constructors must not be silently dropped.
2. **Pinned source identity.** The exact exporter identity \`lean4export 3.1.0\`, export format \`3.1.0\`, Lean version \`4.35.0\` and Lean commit \`eb6cafb7290e8bd5f2937522d8d804f58f02bafc\` are required. The definition \`all\` array must exist, be typed, and include the declared name. These checks are importer requirements, not type checking shortcuts.
3. **Separate observational outcomes.** The *test harness* reports \`accepted\`, \`rejected\`, \`unsupported\`, \`malformed\`, or \`inconclusive\`. Only the first two reflect a kernel verdict. Unsupported export tags or source versions are not counted as an official checker rejection. Inconclusive checker behavior is not counted as an acceptance.
4. **Negative qualification.** Mutations of a known accepted file cover unknown definition and expression fields, format annotations, exporter-version drift, malformed manifest and unknown name components.

Important: the error-message classification in this **test adapter** is not a production protocol and does not yet distinguish all resource/fuel/budget failures. A typed production boundary should replace it before accepting general exports.

### Supported source subset

| Export family | Current qualification |
| --- | --- |
| Header/name/level references | Strict sequential IDs and pinned metadata |
| \`sort\`, \`bvar\`, \`const\`, \`app\` | Test-only decoding; some have exact-byte positive/negative fixtures |
| \`lam\`, \`forallE\`, \`letE\` | Test-only decoding; same-byte acceptance/rejection fixtures |
| \`proj\`, \`natVal\`, \`strVal\` | Parser code exists; **not** an official corpus qualification |
| Safe ordinary \`def\` | Sequential atomic C0 checking in test adapter |
| \`axiom\`, \`thm\`, \`opaque\`, \`quot\` and inductive blocks | Unsupported by this adapter; explicit decline |
| Free/meta variables and structured \`mdata\` | Unsupported; no lossy rewriting |
| Real \`Init\`, Std, Mathlib export | **NOT YET QUALIFIED** |

The source format authority is [lean4export format_ndjson.md](https://github.com/leanprover/lean4export/blob/master/format_ndjson.md), interpreted under the pinned 4.35.0 exporter. All valid corpus expansion needs exact official byte replay and a matching policy/fuel declaration.

### Phase B exit gate (not satisfied)

- Record a version-locked actual Init export subset and then growing full exported Init, Std and Mathlib support, with independent official \`leanchecker\` results.
- Complete the negative/unsupported/resource table, including inductives, recursors, quotations, projection and effect/safety classes. A malformed parser input is never silently reinterpreted as an accepted supported declaration.
- Ensure zero false acceptances for supported declarations and never equate unsupported features to negative kernel verdicts.
- Compare whole checked workloads under identical source, version, resource and axiom policy.

## Phase C — non-accepting canonical-store qualification

Existing experimental native indexed stores already replay all canonical node/index metadata and implement persistent/scratch snapshots with selective memoized promotion. Their handles are **public \`Nat\` values**, not sealed provenance. They cannot be an acceptance authority.

The new \`psKernelC0ScratchPromoteVerifiedRoots\` diagnostic operation:

1. Calls the already atomic selective multi-root scratch promotion.
2. Independently replays **the complete promoted** canonical index.
3. Decodes each selected source root and its output root.
4. Compares the complete syntax using **\`psKernelExprEqual\`**, including binder annotations, names and metadata (not the weaker cache-compatible \`psKernelExprEq\`).
5. Returns \`none\` on a missing root, corrupted index or readback divergence; the immutable input remains unchanged.

The regular fast promotion path remains explicitly experimental and is not considered a kernel check. The validated path costs full replay and decode and must not be mistaken for a whole checker throughput improvement. Its value is an independent syntactic preservation gate for later representation studies.

### Phase C exit gate (not satisfied)

- Sealed store/snapshot-local handle provenance; canonical injectivity and correct persistent-to-scratch edge direction.
- Formal \`StoreWF\` representation invariant and source/optimized denotation/refinement proof or an explicitly independent verified admission gate.
- Faithful Lean 4.35 source import, all compound forms and resource/error semantics.
- Architecture comparison between native immutable sharing, indexed two-lifetime store, and a closure/value execution candidate on **actual accepting** workloads, including allocations and RSS.
- No index-derived result may authorize WHNF, DefEq, type inference or admission until qualified.

## CI and deployment

Workflow: [pskernel-c0-lean.yml](https://github.com/dwijayuda/pskernel/blob/perf/pskernel-c0-v7-rust-20261012/.github/workflows/pskernel-c0-lean.yml). This file records implementation intent and evidence boundaries, not a claim that current unqualified changes passed. Check the latest source commit and matching full workflow run before promoting a milestone. No self-host, original-core modification or Rust experiment is part of these phases.
