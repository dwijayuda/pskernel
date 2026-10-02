# Owned closed-record fields — 2026-10-03

Semantic commit: `7c45a3ca51ed002e5bb4302c190e8f82cce67a6e`, based on `4734acb9ef2a618040beb572c13433ff7cd92ce8`, for `psc2/selfhost-lean-kernel`. All repository changes are under `psc15selfhost/`.

**Owned joint self-hosting and release remain unachieved.** The generated owned kernel now admits the exact preserved prefix through `PsSourcePos` and `PsSourceSpan`. The complete closure still rejects. This is `@proofscript/pskernel-core@0.1.0-checker.9`, profile `owned-closed-record-fields/6`: private, experimental and non-authoritative. The new owned core remains the default and part of portable bootstrap; Lean WASM/native remain explicit external references only. Failed checks, unsupported input and exhaustion do not fall back. The retired core and `pskernel-one` were not modified.

## Source fragment

`packages/pskernel-core/src/Ps/Kernel/RecordInductive.lean` implements one monomorphic Type-valued family, one constructor and at least one closed, nonrecursive Type-valued field, with no parameters or indices. This is a separate admission route, not a relaxation of the zero-field unit rule.

Fields are checked in the original environment and empty local context before introducing the family. This rejects free/dependent fields, forward references and all recursive occurrences, including negative ones. Previously admitted record families are usable field types. The constructor result must be exactly the family with no universe arguments. Constructor typing, universe restrictions and family/constructor/recursor freshness are checked.

The source derives forward-order field metadata and a dependent eliminator type: `{motive : R -> Sort u} -> ((f0 : T0) -> ... -> (fn : Tn) -> motive (R.mk f0 ... fn)) -> (major : R) -> motive major`. That derived type is checked before the final environment is returned. Typing, lookup, name comparison and metadata construction share the outer transition budget; rejection exposes no partial environment. The host decodes/selects a source-owned route and does not synthesize semantic recursor types.

**Record iota and projection typing/reduction are not enabled.** The record recursor remains neutral during reduction. Parameterized, indexed, recursive and dependent-field records, and Prop/higher-universe families, remain outside this fragment and reject. Generated semantic TypeScript/JavaScript were regenerated, not repaired by hand.

## Identities and executed evidence

The source now has **21 kernel modules and 625 declarations**, in a **76-module portable closure** (55 compiler modules). Both PSC frontends check all 625 declarations; canonical PS emission parity, strict TypeScript and independent native Lean checking of all 21 modules passed.

| Artifact | SHA-256 |
| --- | --- |
| Source manifest | `27f5ca183bf374a2ed9db8001b9802c77d6ae83bf91e0f4db6f1569066250c2f` |
| Generated kernel JS | `5c99fca09b45506155d59f23d21071b891e7d2d064ab91570c189c932e9f6391` |
| Generated kernel TS | `bea67a46614a8b72efafc71f2e98ba797b2ab6a19f60b1245e116d87f08710c5` |
| Record differential records | `6a76cc5654f90600f3b3174306a0067da6272db98bfdd1b23e1a5ccd25c66f90` |

The pinned PSC seed is source `cc79e84014ed1d49b0c31971e0a8ceb99b32472c`, executable SHA `a0673677219da539df555961129385ae4cf5099f303f0c883dd3a26f726449ff`. TypeScript is exactly 5.8.3. Builds used Windows Node 26.7.0; full POSIX tests used WSL Node 22.22.1. Native Lean is 4.34.0, commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`. These are seed-built kernel artifacts, not a newly owned-checked compiler/kernel pair.

**459/459 kernel tests** passed, no skips (the prior 417 plus 42 record tests). **84/84 Windows checked-host tests** passed, including actual Lean/ProofScript record-constructor programs, checked-module emission, strict TS and executed JS fields `7n`/`11n`; these programs do not claim source projection support. **74/74 Linux owned integration tests** passed, including the embedded 459-test regression. **23/23 post-integration focused tests** passed. Do not sum these overlapping test counts. The integrated prepared source partition is byte-identical to the isolated candidate.

Source subset/totality guards, 76-module closure, three direct bootstrap roots, 55 compiler-only modules and 14 source-isolation cases passed. Build/evidence identity and default-routing receipt guards passed. The release guard returned exit 1 with `releaseReady: false`, as required.

All ten evidence suites were regenerated: 47 oracle, 100 semantic-oracle, 68 checker-oracle, 671 universe, 559 comparable term, 138 polymorphic, 109 unit, 201 Nat, 122 natural-literal and **102 record cases**. The record differential has **42 accepts and 60 rejects**, all matching the pinned native Lean provider. The existing term report retains two known completeness gaps. Finite passing tests are not a soundness theorem.

Negative record tests cover malformed results, wrong field types/counts, universe restrictions, free/dependent and recursive/negative fields, collisions, forged metadata, constructor/recursor misuse, exact exhaustion and atomic/fresh-session rejection.

## Exact probes and remaining blockers

The unchanged old full input has SHA `20715347d21c3151b02207cb0b17e4827fa098c1c97861c6438df79b2863a722`. The new four-entry fixture `scripts/fixtures/owned-bootstrap-record-prefix.json` has SHA `9cfa5ecaa863c92355c93aad0ccf2fee6c57ffe987421ae02b8cb6a3803718f7`; the earlier two-entry fixture was preserved.

| Independently checked input | Observed result |
| --- | --- |
| First entry: `_pscCheckedNestedUnit` | Accepted; 3,287 transitions |
| First two entries, through `PsSourcePos` | Accepted; 6,665 transitions |
| First three entries, through `PsSourceSpan` | Accepted; 11,293 transitions |
| First four entries, adding `PsLexCursor` | `unknownConstant`, index 3; 11,499 transitions |
| Preserved 75-module batch, 1,556 admissions | `unsupported-expression:proj`, index 9 |
| Fresh 76-module batch, 1,568 admissions | `unsupported-expression:proj`, index 9 |

`PsLexCursor` needs unavailable `List`/`Char` dependencies. The host decodes the full batch before semantic replay: decoder rejection at index 9 (`psLexCursorDone`) does **not** establish admission of entries 0–8. Only the independent prefixes establish the progress above.

The new preserved working-source closure SHA is `28abff62b3116035b59d3938d658b780dcb559bbf0e84e79e54b7851c95b6140`; canonical admissions SHA is `9c53bc3498ca18c8b82c1e6933c6a5c75e61fd702e60d1dd438c6176b5e63202`. Raw checkout hashes can differ with line endings; the receipt separately compares the exact prepared source partition.

## Full dependency inventory and next work

The refreshed inventory has **1,916 compiler, 625 kernel and 81 prelude declarations**. Its full dependency walk requires **55 prelude declarations and 36 assumptions**, with **zero unresolved references and zero canonical-adapter shape blockers**. This is diagnostic elaboration, not owned acceptance. No additional assumptions were admitted. Complete types, bodies, dependencies and metadata are preserved in the compressed JSON inventory alongside the receipt.

Next, implement bounded projection typing/reduction against validated record metadata, with field bounds, correct binder/substitution behavior and the same budget; adding a host decoder tag alone is insufficient. The earlier semantic prefix also requires parameterized/recursive families and `List`/`Char` dependencies. Record iota, other demanded families, strings/primitives and an explicit policy for all 36 assumptions remain necessary. Full closure admission must precede rebuilding the next checked compiler/kernel pair and any owned fixed-point or release claim.

## Completed background work, preserved separately

The original replay directories were read, not restarted or overwritten. The protected canonical 72-module reference child finished with matching admissions and TS. The preserved 75-module reference pipeline finished through canonical generation 2 and JavaScript parity: TS SHA `c93f5b9f20540175ffc4fdaccfa1d49dd3315ed0ccf67c6e7381a4b76b009c1c`, JS SHA `c3dbb4e05ee5f830f836cc19f46ca4943f76506e65e87209b0f7818fb4624195`. These runs explicitly use `lean434-wasm`, retain owned joint self-hosting false, and do not certify the new 76-module candidate.

Base CI run **37055804543** finished with failure. Its actual step-12 log reports `PSC2_KERNEL_REJECTED: unsupported-expression:proj`; independent compiler-only step 14 passed source and TS fixed-point comparisons. This is not owned success or the CI status of a later commit. The original offline collector's separate results ZIP has SHA `ff182be503a65f083119b8ed12b8a2b86d8286c510777e7107f39580f0b468a7`.

## Reproduction and evidence locations

The sibling directory `owned-record-fields-2026-10-03/` contains `receipt.json` and gzip-compressed JSON copies of the exact old full admission input, new 76-module source/admissions, full declaration inventory and full dependency summary. The receipt hashes both compressed and uncompressed bytes. `run-artifacts.json.gz` preserves executed command scripts and logs, including failed attempts, rather than relying only on inaccessible machine-local paths. Decompress with Node's `node:zlib` or `gzip -dc` and validate the raw SHA before replay.

Kernel builds replace `dist`; build only in a fresh isolated candidate with explicit pinned tools, and regenerate all evidence before integration. From the package directory:

```sh
node scripts/source.mjs
PSC1=/pinned/psc1 TSC=/pinned/typescript/lib/tsc.js node scripts/build.mjs
node --test test/*.test.mjs
node scripts/verify-evidence.mjs
node scripts/release-check.mjs  # Must reject this non-release checkpoint.
```

Regenerate the oracle, semantic-oracle, checker-oracle, level-differential, checker-differential, polymorphic-differential, unit-differential, nat-differential, literal-differential and record-differential scripts with their pinned `PSC1` and/or `LEAN_PROVIDER`. Do not substitute an executable identity or use reference acceptance after owned rejection. Exact argument arrays, working directories, timestamps, outcomes, pinned paths and log hashes are preserved in the receipt/run artifacts.

On the original machine, the isolated candidate is `work/owned-record-4734acb9/psc15selfhost`, evidence is `work/owned-record-4734acb9/evidence`, and the integration worktree is `work/owned-record-integration-4734acb9`. `work/pskernel-integration` remains at the base; protected `work/pskernel` and original replays were not edited. Machine-local paths are historical provenance, not assumed paths on another machine.

Failed attempts were preserved. The first build caught an unsupported new source comparator case; the source was corrected. An initial record test incorrectly expected a Nat literal not to normalize; it now checks the neutral recursor head. The first Windows run caught Lean-style application syntax in the new `.ps` fixture; it was corrected to `OwnedPair.mk(7, 11)`. Final successful runs supersede those attempts without editing generated semantic JavaScript.
