# Owned closed-record elimination — 2026-10-03

Base: `052630ebbb3b3526894db29512adea3f65fcd8cd`, branch `psc2/selfhost-lean-kernel`. **Owned joint self-hosting and release are not achieved.** The new owned core remains the default and part of portable bootstrap. Native Lean and Lean WASM remain explicitly selected external references, never fallbacks.

The interrupted continuation had produced an isolated source-built candidate, not a commit. The resumption recovered it without overwriting its logs, verified source/output/evidence identities and recorded log hashes, reviewed the source changes, and completed the previously unsuccessful closure checks under POSIX with the pinned TypeScript tool. Evidence from the interrupted work is distinguished from fresh resumption checks in the receipt.

## Implemented source fragment

`@proofscript/pskernel-core@0.1.0-checker.10`, profile `owned-closed-record-elimination/7`, adds projection inference, projection reduction, neutral projection conversion, and record recursor iota. Semantic changes are in `TypeCheck.lean`, `Reduction.lean`, and `Conversion.lean`. Generated semantic TS/JS came from the pinned PSC build, not manual patches.

Projection inference checks the entire major expression, normalizes its inferred type, compares the full family name and empty universe application, then looks up previously validated closed-record metadata. It bounds-checks the field index before returning the closed field type. The supported field types contain no free or dependent record-field variables, so returning one introduces no binder substitution. Existing capture-avoiding expression traversal remains responsible for projections under lambdas and lets.

Projection reduction and record iota verify the constructor head and exact complete argument spine against metadata installed by record admission. Projection selects the appropriate argument; iota applies the selected minor to every field in forward order. All lookup, name comparison, spine traversal, bound checking, inference and conversion share the same transition budget. Neutral projections compare family, exact arbitrary-precision index and normalized major. Whole admission rejects malformed majors and discarded ill-typed constructor fields; no partial environment is returned.

The host adds only strict wire decoding for `{k:'proj',n,i,e}` into generated constructors. It does not synthesize types or implement semantic reduction. Parameterized/dependent/recursive records, general sum families, strings and other missing primitives remain outside this fragment. There is no additional axiom-admission route.

## Identities and tests

The package contains 21 kernel modules and 643 declarations; the portable closure remains 76 modules, including 55 compiler modules.

| Identity | SHA-256 |
| --- | --- |
| Source manifest | `f1768c4a43bfd6bcbfa54b2107e0e9bad719c8718eb5ab63c4f6e4954b975c28` |
| Generated JavaScript | `06ff66420250031403fd72257da012e36c38b84822c35c3064ab33af96ddc0b3` |
| Generated TypeScript | `137046d6f4bd1af399ea44f2b27f98c7d77659a88485ac088cfce13cbbe3e76c` |
| Elimination differential records | `a44651d2fbef076a9386c62e2a03d847fd46f3b5fdc86611a07a134c8904d622` |

Both PSC frontends checked 643 declarations; canonical PS emission parity, strict TypeScript and independent native Lean checking of all 21 modules passed. The seed source is `cc79e84014ed1d49b0c31971e0a8ceb99b32472c`, executable SHA `a0673677219da539df555961129385ae4cf5099f303f0c883dd3a26f726449ff`; TypeScript is 5.8.3 and native Lean is pinned to 4.34.0 / `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`.

Recovered completed runs: **489/489 kernel tests**, **104/104 Windows checked-host tests**, and **91/91 Linux integration tests**, with no skips. These overlap and must not be summed. The Linux integration *aggregate command* later exited 1 during source/closure checks; it is not relabeled successful. Those remaining checks were rerun successfully in the resumption with canonical source line endings, POSIX symlinks and the exact TypeScript pin. Source guards, 76-module closure, 3-root minimality, 14 source-isolation cases and bootstrap manifest checks passed.

Actual Lean and ProofScript programs containing `pair.right` and `p.left` were owned-checked, emitted, compiled and executed, yielding `11n` and `7n`. A source record match likewise checked and executed to `11n`. Projection and iota differential witnesses compare dependent result types, so merely accepting a term with type Nat cannot make the tests pass.

All prior evidence suites were regenerated for this source identity. The new elimination differential matches native Lean on **128 cases: 53 accepts and 75 rejects**. Existing term comparison keeps its two known completeness gaps. A legacy projection-negative fixture continues rejecting; only its expected error classification changed from unsupported to typeMismatch. Finite evidence is not a soundness theorem. Package privacy, public authority and release gates remain closed.

## Exact input probes and remaining work

The preserved 75-module batch (1,556 admissions, SHA `20715347d21c3151b02207cb0b17e4827fa098c1c97861c6438df79b2863a722`) and prior 76-module batch (1,568 admissions, SHA `9c53bc3498ca18c8b82c1e6933c6a5c75e61fd702e60d1dd438c6176b5e63202`) now pass projection decoding and reject **unsupported-inductive-shape at index 14**, the six-constructor `PsTokenKind` family.

Fresh 76-module source closure SHA is `d2a0a6620dd34a3fc73a05ea6cd1584843574460853fa763ddc31b5e7bb7ca99`; its 1,570-admission input SHA is `8f31b0c37597e5219beb95499f8e9b23762baa42d8663c6df66b48f9d9caa186`. It has the same decoder rejection at index 14. The full declaration inventory, complete dependency summary, exact source snapshot and exact input are stored with compressed/uncompressed hashes beside this document.

**Decoder progress is not semantic admission progress.** The whole batch is decoded before replay. Independently checked prefixes still accept the first three entries at 3,287 / 6,665 / 11,293 transitions respectively. The four-entry prefix rejects `unknownConstant` at `PsLexCursor`, index 3, after 11,499 transitions, because the owned prelude lacks List/Char dependencies. Nothing in this continuation claims that entries 0–13 of the full batch passed.

The next demanded fragments are multiple-constructor families, parameterized and recursive families, the explicit checked prelude and primitive policy, and nested recursor support. Complete generated-owned closure admission must precede emission/rebuilding of the next checked compiler/kernel pair and owned fixed-point claims. No next owned-checked pair was produced here.

## Reproduction and recovery

The companion `owned-record-elimination-2026-10-03/receipt.json` binds all current artifacts and verified runs. `run-artifacts.json.gz` retains earlier failed attempts alongside subsequent successful checks. Original record-prefix and full inputs remain unchanged at `owned-record-fields-2026-10-03/`. Rebuild only in a fresh isolated candidate: the package builder replaces dist and invalidates previous evidence. Use the explicit pinned PSC seed, native reference binary and TypeScript tool; never bypass their identities or invoke a reference after owned rejection.

The source checkout now requests LF for portable `.lean`/`.ps` files, with existing package-specific byte-preservation rules taking precedence. This repairs source-guard portability without modifying compiler semantics. Unrelated source files matched their base Git blobs after normalization and are not part of the semantic patch. Protected checkouts and original replay directories were read only.

Base CI run `37071983742` ended cancelled on 2026-10-02: steps 5–11 and 13 succeeded, the owned fixed-point step 12 failed, and independent compiler step 14 was cancelled. This is not a success claim or the status of a later commit. The older preserved reference replay completed generation-2 JS parity; it was not restarted and does not certify the current candidate.
