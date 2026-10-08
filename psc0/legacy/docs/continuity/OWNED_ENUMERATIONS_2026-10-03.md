# Owned nullary enumerations — 2026-10-03

Base: `56e5e00f0fb9d91018d4f76025cd802d9f6096b2`, branch `psc2/selfhost-lean-kernel`. **Complete owned-checked compiler/kernel pair, joint self-hosting and release remain unachieved.** New pskernel-core stays the default and part of portable bootstrap; Lean WASM/native are explicit external references only. No fallback or new axiom-admission route was added.

## Source fragment

`@proofscript/pskernel-core@0.1.0-checker.11`, profile `owned-nullary-enumerations/8`, admits one monomorphic Type-valued family with two or more nullary constructors. Source-owned admission checks exact full names, freshness, constructor result/type judgments and the derived dependent recursor type before publishing an environment. Its source reduction chooses the constructor-specific minor. All name lookup, metadata construction, branch traversal, type inference and reduction use the outer transition budget. Parameters, indices, constructor fields, recursive sum families and Prop/higher-universe enum families remain unsupported. `EnumInductive.lean`, `Environment.lean`, `JointAdmission.lean` and `Reduction.lean` contain the semantic changes; emitted TS/JS were regenerated, not patched.

## Executed evidence

Fresh resumption: **521/521 Linux kernel tests**, no skips; **122/123 Windows checked-host tests passed**, one explicitly POSIX-only baseline skip and zero failures; **41/41 integrated focused tests**, no skips. The separate complete Linux run covers the Windows platform skip. Counts overlap and must not be summed. The integrated prepared source partition equals the isolated candidate exactly. Source-subset/totality guards, 119-production-module semantic boundaries, the 77-module closure, three-root minimality and 14 source-isolation cases passed. The release guard still rejects.

Recovered and identity-verified candidate evidence: both PSC frontends check **687 declarations in 22 kernel modules**; canonical PS emission parity, strict TypeScript and independent native Lean module checks passed. The new enum differential matches native Lean on **109 cases (48 accepts, 61 rejects)**. All prior oracle/differential suites were regenerated for this source identity; the two existing term-comparison completeness gaps are retained. Real Lean/PS enum programs were owned-checked, emitted and executed. Finite tests are not a soundness theorem.

| Identity | SHA-256 |
| --- | --- |
| Source manifest | `cfcf3dbf7c8e1908aaf644398ecffc1806b56c5049464a73686877dc37700183` |
| Generated JS | `96cc81479f93310b4ecdba69f1b1052b335df1089ce8bd4006b77393816f60e5` |
| Generated TS | `007cf8a6790461c21c378c43777ad219ed8c74c28fbd41eabf544467abf09555` |
| Enum differential records | `fcefcca587a38c6cf2f81dfe140585d75d82f899fc968670c4ac9943a056d26b` |
| Fresh 77-source closure | `28c30d7ea4961828ed61b31c98f7d3dafde23b9d00eb8ae184a80e43a32a8f46` |
| Fresh canonical admissions | `356ae09219cc9336c78ebbf6827971d3b4fe92eb50d7b7fd97228622878302d7` |

## Exact closure status and remaining blockers

The exact preserved PsTokenKind declaration now passes in isolation. The fresh 1584-admission, 77-module batch still rejects `unsupported-inductive-shape` at index **17**, `PsLexError`: a sum with four PsSourceSpan-bearing constructors and one nullary constructor. This is decoder progress, not evidence that entries 0–16 passed. Independent prefixes still accept the unit/PsSourcePos/PsSourceSpan entries, while PsLexCursor rejects at index 3 for missing List/Char prelude dependencies. The full inventory has 1,916 compiler, 687 kernel and 81 prelude declarations, needs 55 prelude declarations and 36 explicitly unresolved-as-policy assumptions, and reports no unresolved symbol references. None of those assumptions has been blindly admitted.

Next required fragments include checked payload sums, parameterized/recursive/nested families and an explicit primitive/prelude policy. Complete generated-owned closure admission must precede the next checked compiler/kernel rebuild and fixed-point claims. The original 72/75-module reference replay evidence was not restarted or overwritten and does not certify this candidate.

## Resumption corrections

Two old rejection fixtures describe valid enums under the new fragment. Their original Flag and nullary Counter inputs are retained as positive regression cases. Additional checks reject payload sums, wrong constructor results, Nat-style application and Nat-style recursor misuse; names zero/succ do not grant Nat authority. Earlier failed runs remain preserved. Portable source CRLF normalization was limited to compiler closure files and each normalized file was checked against its unchanged base Git blob; no compiler semantic changes or retired-package edits were introduced.

## Preserved inputs and recovery

Semantic commit: `1705dba1a14fdfd570d1b674bfc94beb04387ff2`. The sibling `owned-enumerations-2026-10-03/receipt.json` binds the exact fresh 77-source snapshot, full admissions, complete declaration/dependency inventory, integrated source partition, exact probes and successful/failing command logs. Gzip entries record compressed and uncompressed hashes. Rebuild only in a new isolated candidate: building replaces dist and invalidates earlier differential evidence. Original replay directories and all preceding checkpoints remain unchanged. This receipt does not claim current CI success or release readiness.
