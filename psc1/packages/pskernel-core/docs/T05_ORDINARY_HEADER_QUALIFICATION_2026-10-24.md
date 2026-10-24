# T05 ordinary-header narrow qualification — 2026-10-24

The private ordinary-header implementation passed its exact-source narrow cohort:

- Source: `f5d97bafbd48adde29101ed44f45288ae53b9c87`
- Source tree: `9e85b027cc0f8535efc475b490069f2012fd1435`
- Production tree: `6951c3237eaca9fcc1ec9c173028cb651a6afa0d`
- [Actions run 40089243726, attempt 1](https://github.com/dwijayuda/pskernel/actions/runs/40089243726)
- Exactly one push-triggered run; no duplicate dispatch, rerun or mixed-source receipt.

| Gate | Job | Artifact | Verified result |
| --- | ---: | ---: | --- |
| Native | 120858341284 | 12558173561 | 172 exact reports, all direct and retained native controls |
| Generated complete production | 120858822962 | 12558878274 | 1,992 header assertions, 1,884 cache matrix, strict bodies and retained controls |
| Canonical complete production | 120858823020 | 12559537082 | Independent canonical closure, 1,992 header assertions and all retained controls |

All **498 artifact files** were independently read, CRC-checked and hashed:
49 native, 223 generated and 226 canonical. Every artifact contained 32 copied
inputs matching the authenticated source Git blobs. Both routes archived the
actual 146-module Lean closure and tar. The canonical route independently
reconstructed, checked and built its full 146-module ProofScript closure; its
uploaded manifest, tar and recomputed closure digest agreed. All complete and
bounded `.js`, `.ts`, `.d.ts` and `.js.map` outputs were verified, as were the
actual copied/executed scripts and original provenance/receipt log digests.

## Native and runtime scope

The 172 source-named native reports comprise 49 header/state equations,
15 structural occurrence/annotation reports, and 108 retained scope/session/
scalar/cache/Knot reports. Ordered names, uniqueness and exact counts matched
the actual proof sources. All required command statuses were zero; only the
permitted standard axioms were present. The direct native header matrix,
occurrence and annotation fuel matrices, complete-owner callback controls,
official Lean positive/negative cases and retained DAG/prefix controls passed.

Both authentic generated routes executed exactly:

| Header section | Assertions |
| --- | ---: |
| Harness | 1 |
| Header | 444 |
| Occurrence | 1,378 |
| Annotations | 94 |
| State | 47 |
| Phases | 20 |
| Top callbacks | 8 |
| **Total per route** | **1,992** |

Each route also passed both bounded and complete-kernel cache matrices of
1,884 assertions, the 13,665 scalar-hash assertions and 38 short-entry
assertions, all strict generated-body checks, retained DAG and ownership
controls, prefix controls, generated smoke and invalid-recursor controls.
The original source/run/attempt/route-bound receipts and every root log digest
were independently reconciled. No earlier source's pass is substituted.

| Observation | Generated | Canonical |
| --- | ---: | ---: |
| Header matrix wall time | 3.93 s | 3.29 s |
| Header peak RSS | 295,972 KiB | 306,436 KiB |
| Whole detached runtime step | 197 s | 158 s |

These are scoped observations, not a general speedup claim. The unchanged
runtime step cap was 25 minutes. Lean 4.35.0 at commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, TypeScript 7.0.2, Node 22,
fuel 4096, empty PATH and 2048 MiB V8 old-space remained required. Old-space
is not a hard RSS limit. All project execution occurred on Actions Linux.

## Exact repair and limitations

The preceding 60fe candidate passed native checks but failed complete PSC1
checking on both routes with `structuralRecursionArity`. This f5 candidate
changes exactly two recursive calls in `DagOrdinaryOccurrence.lean` to
branch-local partial-self-call lets and adds small structural PSC1 prechecks
before the full source check. Inlining those lets restores the old source.
Proof statements, native fixtures and the generated 1,992 inventory remained
unchanged. That preceding failure is preserved as separate evidence.

This qualification covers **private ordinary-header analysis only**. The
matrix reports `headerOnly=true`, `fullAdmission=false` and
`publicFallbackUsed=false`. Structural equivalence remains conditional on the
explicit ArenaModel; replay establishment and actual decoder correspondence
were not proved by this source. Constructor admission, positivity, generated
recursors, full owner threading and atomic publication remain later work.
Public ordinary admission continues through its existing complete fallback.

T05 and the changed source's full A qualification remain OPEN. B/D remain OPEN
and C remains FAIL. T01F/scoped A remain qualified only at the original 0d9f
cohort, which remains the integration HEAD. The later integration-push
cancellations are separate observations and do not qualify another cohort.
The five full work-branch qualification triggers remain paused. The subsequent
constructor-helper candidate requires its own proof and runtime receipts.

## Saved independent evidence

- [Cohort reconciliation](evidence/2026-10-24-t05-header-f5d97baf-cohort-pass.json)
- [Native artifact review](evidence/2026-10-24-t05-f5d9-native-artifact-review.json)
- [Native proof and receipt review](evidence/2026-10-24-t05-f5d97baf-native-proofs.json)
- [Generated artifact review](evidence/2026-10-24-t05-f5d9-generated-artifact-review.json)
- [Canonical artifact review](evidence/2026-10-24-t05-f5d9-canonical-artifact-review.json)
- [Generated terminal log review](evidence/2026-10-24-t05-f5d9-generated-terminal-log-review.json)
- [Canonical terminal log review](evidence/2026-10-24-t05-f5d9-canonical-terminal-log-review.json)

The static archive verifiers are saved under `evidence/tools/`. They inspect
bytes, source identities, logs and receipts; they do not execute project code.
