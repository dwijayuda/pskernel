# Owned uniform algebraic families — 2026-10-03

Integration parent: `f93da97eeace52cc7300d070b0b3b2e12d2a5f11`; semantic candidate source base: `847aac5560ae203fee659884e0c788eb8fd7231c`. Branch: `psc2/selfhost-lean-kernel`.

**A complete owned-checked compiler/kernel pair, joint self-hosting and release remain unachieved.** The generated owned core stays the default and part of portable bootstrap; native Lean and WASM are explicit references, never fallback paths.

## Implemented fragment

Checker.14, profile `owned-uniform-algebraic/11`, adds Type0 type parameters and direct uniform recursion. Headers, constructors, scope, original field types, exact uniform results, covariance, fresh full names and derived dependent recursor types are checked in source. Recursive iota applies every field and direct induction hypothesis in forward order. All nested judgments share the outer transition budget. See `packages/pskernel-core/ALGEBRAIC.md` for the precise supported profile.

The production adapter only decodes parameterized declarations into generated inputs; it does not manufacture semantic types or metadata. Parameter-free production routes remain the preceding Nat/unit/record/enum/sum routes. Nested, indexed, mutual and universe-polymorphic families remain outside the new fragment. There is no user axiom-admission route.

## Built and tested

Both PSC frontends checked **1,105 declarations in 36 kernel modules**, with canonical ProofScript emission parity and strict TypeScript. Independent native Lean checked every module after a reserved identifier in the recovered source was repaired. The portable source closure contains **91 modules: 55 compiler plus 36 kernel modules**.

The full Linux kernel suite passed **651/651**, no skips. The full Windows checked-host suite passed **191 tests, zero failures, one existing POSIX-only skip out of 192**. The focused algebraic suite passed **39/39**. The production algebraic suite passed **19/19**, including real Lean and ProofScript option and recursive-list programs, checked emission, compilation and executed results `11n` and `2n`. These overlapping counts are not additive.

All previous fourteen oracle/differential suites were regenerated for the final source. The new algebraic differential retains **84 cases: 83 comparable matches (29 accepts, 54 rejects) and one separately recorded reference-boundary discrepancy**. Source/totality guards, 133-module semantic boundaries, 91-module closure, three-root minimality, fourteen source-isolation cases and bootstrap manifest checks passed. Build/evidence/default-routing guards passed. Release and authority flags remain false.

The integration source partition was compared byte-for-byte with the isolated prepared source. Focused integrated host tests passed, and exact input replays produced the recorded accept/reject outcomes. Original replay directories and earlier checkpoint evidence were not restarted or overwritten.

## Exact observed boundary

The exact preserved `PsKernelList` declaration is now independently admitted: **9,238 transitions**. Its fixture hash is `1a1dc0ac346acaa79411efb6b91f029e6b1444aa8a39456ff6b993720c548d48`, extracted unchanged from entry 1362 of the preserved checker.13 full input.

The unchanged original 75-module input (1,556 admissions, SHA `20715347d21c3151b02207cb0b17e4827fa098c1c97861c6438df79b2863a722`) and fresh 91-module input (1,714 admissions) now **decode completely**. Both reject semantically at **index 3, PsLexCursor, unknownConstant**, after 11,779 transitions. Its List/Char prelude dependencies remain unavailable. Independent prefixes 1/2/3 accept at 3,327 / 6,903 / 11,549 transitions. This is not acceptance of the complete closure.

The initial full decode exhausted its worker heap and was preserved as a failure. The separately pushed bounded sharing/memory-boundary change avoids repeated wire allocations while retaining the same 512 MiB cap and every input validation. No failed check was retried through a different semantic kernel. The complete source/declaration/dependency inventory and both failing/successful attempts are retained.

| Identity | SHA-256 |
| --- | --- |
| Source manifest | `fe74eb30a78c2ff6b7295862c4988139b717cf7e2fe4e5ece7d131a6a1314513` |
| Generated kernel JS | `4a82bf3bbbaef0c16c2ec42e07bf4cb10dea26c133c82a81a00284d4430d5ebf` |
| Fresh 91-source closure | `46d8f367510683ccea488a88dd5a4fef41899a38d9e9e32adc98f727e7c9206c` |
| Fresh canonical admissions | `441fae9704f3be10567f07dd1f910551e3f79c992bf60f21e4cb7f04b7236c14` |
| Algebraic comparison records | `12f13a20576d4fd03cbe325ecff60d66e431749d742a6af190beb55b64cd74da` |

## Reference discrepancy and preserved failures

One malformed constructor has a loose bound variable. The owned checker rejects `invalidScope`; the pinned native provider accepts it. A direct Lean 4.34.0 `addDeclCore` control with an empty trust-zero environment independently prints `constructor.hasLooseBVars=true` and `raw_addDeclCore=accepted`. The exact request SHA is `ce7311b7515beb593a574c4f55d90ebe11519b30cf3f516ddce36356a69553e2`. This case is not counted as a matching comparison, the owned scope check was not relaxed, and the observation is not presented as a general claim about Lean soundness.

The first source build passed PSC but failed independent Lean because `prefix` is reserved; it was renamed in source. Early smoke fixtures used an invalid parenthesis and a flat name `Nat.succ` instead of a structured name. Early PS frontend fixtures used Lean-style type application; they were corrected to canonical PS call syntax. Original failing logs and fixtures remain preserved. No generated semantic JavaScript was repaired by hand.

## Next gates and reproduction

The next demanded work is checked standard prelude dependencies, parameter-free direct recursion routing, nested recursor representation and explicit primitive/axiom policy. The complete inventory still carries the required prelude and assumption list; this change does not admit those assumptions. Complete owned closure acceptance must precede emitting the next checked compiler/kernel pair; a generated pair must then rebuild its successor before a joint fixed-point claim.

Build only in a fresh isolated candidate: `scripts/build.mjs` replaces dist. Use the exact pinned PSC seed, TypeScript 5.8.3 and explicitly selected native reference binary from the manifests. The continuation receipt added alongside this semantic checkpoint records command arrays, times, source/seed/output hashes, complete input snapshots, full declaration/dependency inventory and compressed successful/failing run artifacts. Finite passing tests are evidence, not a soundness theorem.
