# Owned closed payload sums — 2026-10-03

Base: `0187a23f4d0221a573c08ebc8e75817073c698c1`, branch `psc2/selfhost-lean-kernel`. **Complete owned-checked compiler/kernel pair, joint self-hosting and release remain unachieved.** The generated owned core remains the default and part of portable bootstrap. Native Lean/WASM are explicit references only; errors, rejection and exhaustion never select a fallback.

## Implemented source fragment

`@proofscript/pskernel-core@0.1.0-checker.12`, profile `owned-closed-sums/9`, adds monomorphic Type-valued families with two or more constructors and closed nondependent nonrecursive Type-valued payload fields. `SumInductive.lean` checks every field in the original environment before the family is introduced, verifies fresh full names and exact constructor results, checks the full constructor types and derives and checks a dependent recursor. `Reduction.lean` pairs minors with constructors, verifies the entire constructor argument spine and applies payloads in forward order. All judgments and traversals consume the shared outer transition budget; rejection exposes no partial environment.

The source dispatcher recognizes the existing two-constructor Nat fragment structurally before checking. A rejected Nat judgment is returned directly, not retried as a sum. Constructor names such as zero/succ do not grant Nat authority. The host only decodes raw declarations into generated inputs. General recursive, dependent, indexed and parameterized families remain rejected. Generated semantic TS/JS were rebuilt from source, not patched.

## Executed checks

Fresh Linux kernel suite: **561/561 passed**, no skips. Clean Windows checked-host suite: **142/143 passed**, zero failures and one explicit POSIX-only baseline skip covered by the separate complete Linux run. Focused source-owned sum suite: **40/40**. Real production sum and frontend tests: **15/15**. The integrated source partition was separately compared byte-for-byte with the isolated prepared partition and focused checks were rerun there. Test counts overlap, not additive.

Both PSC frontends checked **740 declarations in 23 kernel modules**; canonical PS emission parity, strict TypeScript and independent native Lean checking passed. The portable closure is **78 modules (55 compiler + 23 kernel)**. Source syntax/totality, 120-module semantic boundaries, three-root minimality, 14 source-isolation cases, bootstrap manifest, build/evidence identities and owned default-routing guards passed. Release and authority flags remain closed.

All thirteen oracle/differential suites were regenerated. The new sum differential matches pinned native Lean on **110 cases: 42 accepts and 68 rejects**. Its result-type equality witnesses test actual branch reduction, not only Nat-typedness. The prior term differential retains its two known completeness gaps. Finite evidence is not a soundness theorem.

Actual Lean and ProofScript payload-constructor/match programs were owned-checked, emitted, compiled and executed to **11n**. Rejected branch and discarded ill-typed-field cases cannot emit output or inherit authority from prior sessions. The original larger-numeral focused witnesses passed without changing their test values.

| Identity | SHA-256 |
| --- | --- |
| Source manifest | `8c21e6dcb8dc8a967abba7d81b3bef97b4f9cab57d548cf331c55fd8ea4f00d0` |
| Generated JS | `bc1eeba2101d102967e332bbbf5ac4eaebef1fa40b30f96c41114eb762831d94` |
| Generated TS | `83d4cf24c02aaa22e0a90a19ca52a93c5a2255d022a769862d7a4b2e1a473ecc` |
| Sum differential | `df67107dd3f14646e8bb708f84b0996ebcb1f82280f917b2d8503124cdb18158` |
| Fresh source closure | `71e7b1a9591d2dab365b28698f9231274c4b99a501caa5b057b0492d4b2d446b` |
| Fresh canonical admissions | `4f4a0bbda219c1426778639ba3b3156bddc07d2c0ce5c7763dc7989e83c88607` |

## Exact inputs and remaining blockers

The exact preserved `[0,1,2,17]` dependency slice (private unit, PsSourcePos, PsSourceSpan, PsLexError) now passes. This is not acceptance of the complete first 18 entries. Full decoding of the fresh **1599-admission** closure rejects `unsupported-expression:str` at index **20**. The preserved full input is replayed separately. Independently checked prefixes still accept the first three entries; PsLexCursor still rejects at index 3 because List/Char dependencies are unavailable.

The complete declaration inventory contains 1916 compiler, 740 kernel and 81 prelude declarations. It retains the full type/body/dependency inventory and the explicit required-prelude/assumption list; no assumptions were blindly admitted. Remaining work includes string/primitive policy, checked prelude families, parameterized and recursive families and native nested recursor representation. Complete owned admission is required before building the next owned-checked pair or claiming its fixed point.

## Preserved failures and regression transitions

The first full Windows attempt ran its receipt check while evidence regeneration was in progress and correctly rejected STALE_EVIDENCE:CHECKER_DIFFERENTIAL. Its behavior checks passed. After regeneration, the full clean run passed with the one documented platform skip. The failed run remains in the evidence rather than being relabeled. Previously unsupported valid payload-sum fixtures were retained as positive regressions, with explicit recursive/unknown-field rejection cases added. Original replays, previous checkpoints and protected checkouts were not modified.

## Preserved inputs and recovery

Semantic commit: `0fc8328d0cd97d72c1252152ab802902029cacf8`. The sibling `owned-closed-sums-2026-10-03/receipt.json` binds the exact fresh 77-source snapshot, full admissions, complete declaration/dependency inventory, integrated source partition, exact probes and successful/failing command logs. Gzip entries record compressed and uncompressed hashes. Rebuild only in a new isolated candidate: building replaces dist and invalidates earlier differential evidence. Original replay directories and all preceding checkpoints remain unchanged. This receipt does not claim current CI success or release readiness.
