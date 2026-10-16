# M3 direct-recursive BEq — qualified 16 October 2026

## Acceptance and exact boundary

**The selected direct uniform nonindexed recursive BEq slice is implemented and qualified. M3+B remains OPEN.** The source design is in [recursive BEq](PSCV0_M3_RECURSIVE_BEQ_2026-10-16.md). This receipt supersedes its pending qualification language, not the v7.2 specification or other M3 requirements.

Qualified compiler/test commit: **058fb67f1eec12add5adc1b3419644eb7e7363c5**, tree **941632044351df01189f556c05859ea92e316f7d**. Subsequent preparation/recording/DecidableEq development commits do not inherit its qualification. The acceptance evidence here belongs only to the exact SHA above.

Official Lean4.35.0 `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`; v7.2 reference blob `694115223777599ba28ee175e14bb642b7b6aa4b`, SHA256 `c65487eccbd2829d1d9e5e1be3bc7f4cb37849b841ab3257ea0dd47665b8a30e`. Approved assumptions remain propext/Quot.sound only.

## Five same-commit gates

| Required workflow | Exact run | Result |
| --- | --- | --- |
| Full native Linux pipeline | [38905476639](https://github.com/dwijayuda/pskernel/actions/runs/38905476639) | SUCCESS; all 33 reported steps including setup/cleanup, none skipped |
| Independent F1 canonical model | [38905476304](https://github.com/dwijayuda/pskernel/actions/runs/38905476304) | SUCCESS |
| Independent F2 logical operations | [38905476313](https://github.com/dwijayuda/pskernel/actions/runs/38905476313) | SUCCESS |
| Independent F3/F4/platform | [38905476451](https://github.com/dwijayuda/pskernel/actions/runs/38905476451) | SUCCESS |
| Focused recursive deriving and target execution | [38905476153](https://github.com/dwijayuda/pskernel/actions/runs/38905476153) | SUCCESS |

Native job116988198551 passed compilation, parser/native checks, logical-asset regeneration, checked source/Standard, module emission, GC/components, TypeScript/Rust, repeated native Wasmtime/post-return, unchanged measurement and publication. Focused job116987837831 passed independent source and five-target generation, direct JS, strict compiled TS, locked Rust, V8 GC and Wasmtime components. These are actual same-commit results, not inherited Repr or earlier focused-only success.

## Published exact artifacts

| Artifact | ID | Bytes | GitHub SHA256 |
| --- | --- | ---: | --- |
| pscv0-v7-native-058fb67f1eec12add5adc1b3419644eb7e7363c5 | 12049320144 | 6704499 | 8984490e21626bc591ed54ab567a7f2cc24a7deb66bc1c212b4ed0e0ff1e2061 |
| pscv0-m3-recursive-hash-058fb67f1eec12add5adc1b3419644eb7e7363c5 | 12048186682 | 238569 | f0d21edbf82f50a5e84fd84f86e579ba7f0936d0885490fe66af68e73b432a13 |

Run artifact metadata identifies the qualified SHA. Both were present and unexpired when inspected; hosting expiry is not a permanent-download guarantee. The focused artifact retains its historical Hashable name but exercises Hashable, Repr and BEq.

## Implemented semantics and evidence

Field plans distinguish erased proofs, independent BEq dictionaries and direct recursive evidence. Checked left induction produces child comparators of type family -> Bool; right constructor case analysis deliberately ignores its own hypotheses. Different constructors return false. Equal constructors apply the actual independent dictionaries or checked child comparator, in source field conjunction order. Structures retain direct projections. No assumed self dictionary, partial helper, LawfulBEq assumption, pointer/reflexivity shortcut, source-name fast path or backend-specific equality was added.

The existing generic tree fixture retains Hashable/Repr and adds native-oracle Nat/Bool comparison masks, deep/right and left changes, constructor mismatch in both directions, and an explicitly non-reflexive field dictionary. A source rfl theorem checks the recursive constructor equation. Three new BEq refusals cover unsupported nested/indexed families and missing independent field dictionaries at the intended elaboration rule. Seven exports keep the Bool-to-UInt64 ABI; recursive data stays internal.

The separately inspected earlier candidate34426e22 focused artifact12046737336 was238568bytes, SHA25624dd67525fca27a4c08a12f164c30218f219cc890124009dca44f779e91f23be, independently downloaded and hashed by cloud38903969917. Its expected masks were Nat/Bool1/7 for false and7/1 for true, with non-reflexive dictionary check1/1. Generated JS and compiled TS showed a left-recursive comparator and a right constructor switch without eager second traversal. Final058f preserves that compiler behavior, adds the reviewed test-boundary reconciliation and documents the case-only lowering invariant. These observations are not a global complexity/preservation theorem or measured speedup.

## Historical correction, not relaxed validation

Original candidate34426e22 passed focused38902937385 and independent replays, but native38902937355 failed because two old negatives still classified direct recursive BEq as unsupported. Successful cloud preparation38903969917/job116982807103 verified original native-test blob913c02e94f1688da595c6bad617eb8a7f8f9c83b and prepared exact blob44338bb06e8f633d8b27c6413cbd3c9b5c684979.

Exactly two fields changed to unsupported nested forms: `next: List RecursiveCell` and `tail: List(Chain A)`. Rejection assertions, phases and diagnostic expectations stayed unchanged. Positive direct-recursive behavior is independently qualified, rather than inferred from removal of a negative. Original benchmark operations, checksums, test budgets and other fixtures were unchanged. The temporary BEq preparation workflow was removed. Failed/preparation-only runs remain historical evidence and are not counted as qualification.

## Remaining work

Recursive DecidableEq is the next separate proof-producing equality slice and is not qualified by this receipt. Broader nested/indexed/mutual data/deriving, elimination/motives/patterns, structural/well-founded recursion, P0 executable assurance and selected P1 fixedpoints remain open. Preserve the independent partial inhabitant/public opaque self/private actual-body marker; all partial executable admission remains refused. Never execute a witness as the source program or invent body equations/totality.

No new performance gain, production-speed parity or general compiler-preservation proof is claimed. M2+A, Hashable and Repr receipts remain unchanged. Native portable .lean; no pskernel-core, self-hosting, compiler-source migration or immediate C5. PR109 remains draft/open on its existing base and unmerged.
