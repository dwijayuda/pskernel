# PSC0 SH/1 implementation work state

Updated: 2026-10-09 14:51:06 UTC.

## Active continuation: finite migration and TypeScript 7-only development

The user requires the new supplied `.ps` grammar only, without active backward compatibility, and now explicitly retires TypeScript 5 from future development. Current PSC0 compilation must use exactly TypeScript 7.0.2. Historical source revisions and evidence remain immutable facts; they do not define a supported current compiler fallback.

Work remains on `psc0/sh1-projection-grammar-v1`, descended from qualified integration `5e3a991088aaa735c8f324c4e70a7a3dee4cd69a`. The canonical implementation branch remains at that previous completed checkpoint until the finite migration qualifies. Main is untouched.

**R is qualified and explicitly selected. The twelve-worker F source is applied, and attempt 2 passed all 87 behavior cases on both authenticated R and current-native F with identical reports. Full F qualification remains pending: its new isolated ABI test source used unsupported `axiom` syntax and failed before C1 emission.** This checkpoint replaces that probe with supported declarations and moves the complete probe before N1. It also removes active PSC0 TypeScript 5 compilation and recovery routes; the replacement native TypeScript 7 recovery requires an independent cold proof.

Handwritten `.lean` remains authoritative. Current `.ps` parsing, printing and owned source consumers use bounded new-only `ps-0.9-r3`. Strict SH/1, full Standard/PSCV and unrestricted PSC1 are not claimed.

### Earned R evidence

Qualified source `fe2560aba0f347b1caf8d000d371464642d44f23`, [run 37925722635](https://github.com/dwijayuda/pskernel/actions/runs/37925722635), attempt 1, completed successfully. Compiler job `113804052074`, independent provider job `113827136830`, and cold recovery job `113827137018` all passed. The successful source has 61 modules and 1,113,918 raw source bytes.

- Source closure: `f96c811f575cae2be58ccca3ffe587ead83bffa6f8bd862d40936bef28ef3226`.
- C1/C2/C3 JavaScript: `70db0131fa3af62f7193576407ad529be10df2f4296c712f53f7c31f42209061`.
- Selected R identity: `47d88158e075f766f0d146ba3a13b28744c6e196d9844c71f4e52dc7351e2225`.
- Selected manifest actual file SHA-256: `7a0c2cf950333aa680f2ae00e214f57b674dab2d783a1403b242b92e71c56694`.
- Provider receipt actual file SHA-256: `1736aa0c1b3fdd5d59b4c2653c053261e3ada36ea82b68d6b88400e17fc1ab77`.
- Cold receipt actual file SHA-256: `2aa93517b848da1493386ab9be50527275fe1a7a1c7e12f422d8d8431d8d9f1d`.

Native suites passed 75 core, 10 translation and 16 erasure cases. N1 checked complete Lean-to-new-PS-to-Lean correspondence for all 61 modules and 904,355 PS bytes. Its full original-IR checker accepted 56,391 expressions and 725,484 visited steps with zero findings. C2/C3 accepted the complete original IR with zero findings before emitting that same IR and matched all four required products. Their full expression/step counts are not inferred from the native counts.

Per-generation capability gates passed 21 projection API cases, 39 projection and 34 grammar behavior observations per raw Lean/PS fixture, plus the complete bounded grammar positive/refusal suite. C1 preserves the explicitly historical A boundary for its first canonical product. That immutable historical artifact is not a current legacy parser mode.

The unchanged Lean 4.34.0 provider accepted four distinct exact admission streams covering eight C2/C3 roles. This is post-emission acceptance; it does not claim this provider invocation gated emission.

Cold recovery independently rebuilt two new raw-source generations from pinned A into fresh output/cache directories. The pinned same-revision recovery runner matched all first/final products, checked the final original IR before emission, authenticated the parent/cache and recorded success. Its measured elapsed time was 2,728,786.866427 ms, about 45m29s. The job finished at 13:37:09 UTC.

The separate [receipt collector](https://github.com/dwijayuda/pskernel/actions/runs/37938411520) authenticated the successful run, jobs, immutable artifact IDs and 18 exact retained JSON files. Those original file bytes are committed verbatim. The collector did not activate the seed; this later explicit selection commit writes its authenticated proposed manifest. The [selection record](docs/selfhost-language/seed-evidence/fe2560aba0f347b1caf8d000d371464642d44f23/selection.json) maps every retained file to its exact digest and Git blob. Archive digests are not receipt-file digests.

R compiler/provider logs and all 34 complete logged records remain in `docs/selfhost-language/grammar-migration-compiler-evidence.json` and `evidence-logs/`. The cold log and its three-record evidence bundle are retained alongside them. Exact artifact receipts, ancestry, qualification and grammar evidence are under `docs/selfhost-language/seed-evidence/fe2560aba0f347b1caf8d000d371464642d44f23/`.

### Implemented grammar and compiler repair

The adopted reference has SHA-256 `4c02626fd0b991e8526c64b65f4ffb66b9ce7b688298e82fb0309802a263db71` (401,569 bytes / 8,546 lines). It is a design RC with pending Standard environment and implementation conformance. The implementation adopts the documented bounded grammar, not the entire reference.

The parser/printer now own newline sequences, one comma-oriented explicit declaration/constructor binder group, strict record commas, grouped call terms and adjacent postfix calls. Empty invocation stays an empty argument list and unsupported completion is refused; `f(())` remains one Unit argument. PS whitespace/BOM positions have a dedicated lexical entry. Current raw PS imports are parsed before host processing. Unsupported broader syntax remains explicit refusals.

Shared exact-name / first-segment / longest proper local-prefix resolution repairs recursive record-parameter projections. Structural identity predicates remain exact-only, and recursion substitutes only the selected parameter base with scope/shadowing respected. No type-error fallback or name exception is added.

The first R attempt (`48723fe676a0d9ae3fa819bd314199fe0ca2e926`, run 37925016499) failed the native build on two direct blockers: reserved local `postfix` and a Term reference to an unimported list helper. R2 renamed the local and used direct list pattern matching, then ran all three native suites without suppressing later diagnostics. [The original failure evidence](docs/selfhost-language/grammar-migration-attempt-1.json) is preserved. No gate was weakened.

### Finite worker migration: earned evidence and corrected probe

The production migration at `9ee0b1fd38dd1456a187d4675f9027440a989f2d` changes twelve bounded workers in nine Lean source files and removes three projection aliases in a tenth file. Seven existing source guards were aligned with ordinary changing parameters. Public types, parameter order, fuel and zero cases, reversal/order rules and collision limits remain the required contract.

Attempt 1 ([run 37939061854](https://github.com/dwijayuda/pskernel/actions/runs/37939061854)) stopped during a new host fixture's first nonexistent structure-constructor call. The coherent correction at `f62c38c890af13b1e8ccb2a4d2650b9c7c6d2d5f` replaced all 48 invalid calls across 20 structure types using existing neutral factories, same-compiler template copies and explicitly labelled non-IR host fixture records. It retained all 87 independent expectations and added an authenticated R reference preflight. The [attempt 1 evidence](docs/selfhost-language/worker-migration-attempt-1.json) and [fixture audit](docs/selfhost-language/worker-migration-fixture-repair.json) remain retained.

Attempt 2 ([run 37941485695](https://github.com/dwijayuda/pskernel/actions/runs/37941485695), compiler job `113856701970`) passed that reference preflight and the current native development gate. Both complete 87-case reports have observation SHA-256 `697616ab48daf77a44b90ce20085432593ddce9a06fdad124a5a898ece3621be`. Native suites passed 75 core, 10 translation and 16 erasure cases; focused source/snapshot/session tests passed 27/27 and actual PS import/build cases 4/4. The complete native original IR was accepted with 56,602 expressions, 728,064 visited steps and zero findings. All 61 modules round-tripped through the new PS grammar, producing 902,538 PS bytes.

The current F source closure is `6306cdac131f849a9a96de3dc4d628a48b953072b45fc6cc829075bd90b67ac7`. Attempt 2 native JS is `5eeecb1bfa00f11f1691f5ee4b437ecebe5c9a45b4e4256ab1bde23b0771df15`; native TS is `0d90517192bba53dbc6190c774158559b64871b7222ba37b0df5a65a325db99a`. These are completed native results, not selected-seed bootstrap or fixed-point proof.

C1 then stopped at `PSC0_SH1_MIGRATION_ABI_ISOLATED_SIGNATURE_PROBE: leanFrontend`. The owned Lean declaration dispatcher does not accept `axiom`. The corrected isolated source uses nineteen one-constructor monomorphic inductives and the same twelve explicitly annotated partial-application wrappers. Each reference signature is the first explicit worker binder's complete Core type. All twelve specifications, original partial splits, current prepared-Core checks and ordered original-IR comparisons remain unchanged. The exact probe source is retained before execution; nested diagnostics are retained on failure. The independent static review verified all nine guarded edits and the early workflow replacement.

[The complete attempt 2 evidence](docs/selfhost-language/worker-migration-attempt-2.json), [primary log](docs/selfhost-language/evidence-logs/worker-migration-attempt-2.log) and [ABI correction audit](docs/selfhost-language/worker-migration-abi-repair.json) distinguish these completed checks from the missing C1/C2/C3 ABI, paired behavior, fixed point and provider results. No gate has been waived.

### TypeScript 5 retirement

The current JS locator and native Lean host accept only 7.0.2 and retain exact installed-launcher verification. Positional compilation always supplies `--ignoreConfig`. Existing installation, native launcher, runtime replay and erasure-index gates are updated for one compiler version; invalid-version refusal is checked without installing TypeScript 5.

The qualification workflow installs only the pinned TypeScript 7 package. The obsolete full-compiler TypeScript 5/7 comparison is removed. Current qualification rejects all four old reconstruction commands before TypeScript launcher resolution. The existing selected R manifest and identity remain unchanged.

The additional `selfhost-seed-recovery.json` policy authenticates `scripts/sh1-native-seed-recovery.mjs` and its dependencies. Its intended route builds pinned R with Lean 4.34.0, checks and emits the same original IR, compiles with TypeScript 7.0.2, obtains native canonical admissions and translates the ordered 61-module surface. It must compare all four exact final artifact hashes before materializing the existing selected cache identity. A separate clean checkout/cache run is required before claiming this route qualified. No generated compiler or historical parent compiler is needed by that route.

The separate repository-root TypeScript backend still requires migration from the TypeScript 5 programmatic API to the TypeScript 7 CLI, with its own workspace dependencies and targeted existing gates. That work is separate and pending; PSC0 evidence must not imply root-workspace completion.

### Remaining completion gates

1. Run the authenticated R 87-case behavior and supported twelve-signature probe before N1.
2. Qualify exact current source through native development, selected-R C1, C2/C3 four-product equality, full current Core/IR ABI, paired behavior and unchanged independent provider acceptance.
3. Independently cold-prove the native TypeScript 7 selected-R recovery route and retain its exact receipt.
4. Complete and validate the separate root-workspace TypeScript 7 CLI adapter and dependency migration.
5. Retain actual successful evidence, reconcile current guides and fast-forward the canonical implementation branch with a fresh lease. Do not change main.

Use meaningful early checks to reject a whole demonstrated failure class before another long qualification. Do not retry individual expectations or weaken gates. Finite F keeps R selected and does not request a new seed promotion. Daily native/session iteration is not full fixed-point/provider qualification. TypeScript emission timings are only a small final pipeline component; no F whole-pipeline speedup is claimed.

## Historical completed M6 and TypeScript 7 result

This section preserves the completed checkpoint before the active R/F continuation.
Its selected-seed, integration and next-step descriptions are historical; the
active status above is authoritative for this continuation.

The bounded portable runtime IR checker, same-IR checked emission and scoped-let
backend correction are qualified under TypeScript 5.8.3 at
`1b5fd12382c920944924c9d03e0851984293caa2`
([run 37906602597](https://github.com/dwijayuda/pskernel/actions/runs/37906602597)).
Current PSC0 TypeScript 7.0.2 integration is qualified at
`99786185f77edf952f11989d4c9bc44028f22f11`
([run 37910429506](https://github.com/dwijayuda/pskernel/actions/runs/37910429506)).
The second source retains the same portable M6 code. Both checkpoints have
separate compiler and selected-provider receipts.

Canonical integration uses a normal fast-forward of
`psc0/sh1-implementation-v1` to the qualified TS7 descendant and documentation.
The exact qualifying source remains the immutable reference above; a later
documentation commit does not claim a fresh compiler run.

The independently qualified M6 baseline at `1b5fd12382c920944924c9d03e0851984293caa2` records:

| Evidence | Observed result |
| --- | --- |
| Portable compiler source | 61 modules; 1,088,337 bytes |
| Native full original IR | 54,879 expressions; 707,753 visited steps; complete; accepted; zero findings |
| Native fixtures | Eight cases passed |
| N1/C1/C2/C3 runtime conformance | 59 observations per generation, including 29 observations across four let-scope cases |
| Generated checker refusals | 36 negative IR cases and five malformed/foreign carrier cases per generation; resource and direct type-operation cases also passed |
| Current C2/C3 full original IR | Complete; accepted; zero findings; same original IR checked before emission |
| Current C2/C3 products | Canonical surface source, normalized admissions, TS and JS agree; N1 TS/JS also agree |
| Independent selected provider | Three exact admission streams accepted after emission |

The generated C2/C3 summaries do not print their full expression or visited-step
counts. Those fields are not inferred from the native counts; their full reports
remain in `dist/sh1/C2/original-ir-inventory.json` and the corresponding C3 artifact path.

The native development gate's internal total was 144.586 seconds. The C1/C2/C3
generation totals were 1,145.486 / 1,187.825 / 1,199.391 seconds.
Across those three generations, preparation accounted for 60.17% of the recorded
total; `tscAndWrite` accounted for 30.655 seconds, or about 0.87%. The latter
includes evidence writes, hashing and identity work as well as TypeScript.
These are observed phase timings from one qualification run, not controlled benchmarks.

The compiler bundle preserves all 28 complete logged JSON receipts, including
their original provider-not-attempted fields. The separate later provider receipt
records `accepted: true` and `emissionWasGatedByThisCheck: false`.
Compiler qualification, bounded IR typing and exact-stream provider acceptance
are earned; strict SH/1 and profile activation remain false.

See [runtime-ir-checker-qualification.json](docs/selfhost-language/runtime-ir-checker-qualification.json),
[runtime-ir-checker-provider.json](docs/selfhost-language/runtime-ir-checker-provider.json) and
[runtime-ir-checker-execution.json](docs/selfhost-language/runtime-ir-checker-execution.json)
for complete receipts and the retained attempt history.

Current emission uses exact TypeScript 7.0.2. Historical S0/A recovery uses exact
5.8.3, including a byte-checked TypeScript replay when reusing authenticated A.
Frozen recovery receives and verifies its actual historical child launcher
before building. The root workspace still uses the old TypeScript programmatic
API and remains on 5.8.3. Lean 4.34.0 and Node 22.23.3 keep their pins.

The completed same-source comparison compiled the full emitted compiler with
TypeScript 5.8.3 in **9,281.561787 ms** and 7.0.2 in **2,866.119670 ms**.
That single sequential pair gives a **3.238× direct-CLI speed ratio** and
**69.12% less elapsed time**. It includes startup, checking and emission; it does
not measure the complete self-host pipeline. The input TS SHA-256 is
`f20c9132ae2f8adade08346b0457f6bb02b6e5145097116d2a827121304a8f70`.
See [TYPESCRIPT7.md](docs/selfhost-language/TYPESCRIPT7.md) and
[typescript7-qualification.json](docs/selfhost-language/typescript7-qualification.json)
for the exact measurement and scope.

A remains the selected authoring seed. Compiler qualification, bounded runtime
IR typing, exact provider acceptance and strict SH/1 are separate. Strict SH/1
and named-profile activation remain false. Kernel/provider implementation,
defeq/cache internals and metatheory are unchanged.

The execution histories retain all source-form and emission findings, without
rewriting earlier failures as passes:
[runtime-ir-checker-execution.json](docs/selfhost-language/runtime-ir-checker-execution.json),
[first complete native acceptance](docs/selfhost-language/runtime-ir-checker-first-native.json)
and [typescript7-execution.json](docs/selfhost-language/typescript7-execution.json).
The source-compatible callback/match/record-alias forms are documented in
[SPEC.md](docs/selfhost-language/SPEC.md). The general projection-normalizer
repair remains future work; no syntax exception or checker weakening was added.

## Current source and qualification checkpoints

The current qualified integration source is the TypeScript 7 M6 checkpoint
`99786185f77edf952f11989d4c9bc44028f22f11` above. The earlier recursive
generic-argument repair E,
`cf8fbd784944a98b1e390b709685ca54c2511827`, was independently qualified on
`psc0/sh1-generic-erasure-v1`: compiler and pinned-provider jobs passed on the
first execution of [run 37852341550](https://github.com/dwijayuda/pskernel/actions/runs/37852341550).
Its parent helper migration H,
`671685c3f0059574405a1e630dd965d421a26f05`, independently passed both jobs on
the first execution of [run 37851669475](https://github.com/dwijayuda/pskernel/actions/runs/37851669475).

The canonical integration branch is `psc0/sh1-implementation-v1`; integration
preserves each feature branch's source/qualification provenance and uses normal
fast-forwards. Documentation-only descendants preserve the exact qualified
executable sources.

| Checkpoint | Source commit | Result |
| --- | --- | --- |
| A: recursion capability and preparation/session implementation | `e91b9558d665879871b8bf0893915ae64b27c7fe` | Compiler-qualified and exact admissions accepted; remains the selected authoring seed |
| B: Foundation.List migration | `70d6010ddccbdd6b4939f2fb3c088bfe4e607de0` | Compiler-qualified and exact admissions accepted on its first migration execution |
| H: three compiler helpers | `671685c3f0059574405a1e630dd965d421a26f05` | Compiler-qualified and exact admissions accepted on its first execution |
| E: recursive generic-argument erasure | `cf8fbd784944a98b1e390b709685ca54c2511827` | Compiler-qualified and exact admissions accepted on its first execution |
| M6: bounded runtime IR checker and scoped-let correction | `1b5fd12382c920944924c9d03e0851984293caa2` | Qualified under TypeScript 5.8.3, with current IR typing and separate provider acceptance |
| Current TypeScript 7.0.2 integration | `99786185f77edf952f11989d4c9bc44028f22f11` | Same portable M6 source qualified under 7.0.2; historical recovery remains 5.8.3 |

Compiler qualification, Core-provider acceptance and strict runtime SH/1 remain
separate axes. Strict SH/1 is still false, and psconfig retains the existing PSC1
bootstrap lane. No named profile was activated by these changes.

## Completed implementation in this continuation

The helper migration H changes only `Elab/Term.lean` and
`Erasure/Definition.lean` inside the portable closure:

- `psExprApplyManyWorker` now takes its expression accumulator as an ordinary
  explicit parameter.
- `psExprAppViewAccWorker` now takes its argument accumulator as an ordinary
  explicit parameter.
- `psErasureAddUniqueStringWorker` now takes its changing candidate base as an
  ordinary explicit parameter while descending through Nat fuel.

All public worker/wrapper names, complete types, argument order and algorithms
are preserved. The unique-name helper retains its exact zero-fuel and collision
exhaustion suffixes. The three guards accept historical and qualified forms
while retaining wrapper, primitive and unrelated source/admission checks.

The correspondence gate compiles preserved/current raw helper slices with actual
Name/Level/Expr dependencies. It checks seven public types and 2,198 observations
per compiled slice, including typed partial applications. A separate 1,568-observation
check exercises actual exported helpers in each generated compiler. All of these
checks passed on the first compiler execution of both H and E.

The isolated E repair changes `Erasure/Basic.lean`, `Erasure/Definition.lean`
and `Erasure/Expr.lean`. `PsErasureCurrentDefinition` now retains a reversed
accumulator of the current declaration's generic arguments. Type binders record
their assigned Tn in order; runtime and erased proof binders preserve the context.
Recursive induction-hypothesis calls receive the restored declaration order.
The implementation neither captures unrelated local types nor whitelists helper
names.

The focused fixture checks exact original-IR argument order for one, two and
three generics, interleaved proposition/proof/runtime binders, and a monomorphic
control. It emits the same IR object whose calls were asserted. All N1/C1/C2/C3
executions passed 19 behavior observations; N1/C1 also passed native parity.
Kernel/provider implementation and metatheory were unchanged.

## H evidence before the erasure repair

H's compiler job `113565800146` passed on its first execution in
[run 37851669475](https://github.com/dwijayuda/pskernel/actions/runs/37851669475);
provider job `113583716467` also passed on that first execution.

H contains 56 raw modules / 991,563 Git blob bytes, a reduction of 327 bytes
from B. Raw source closure SHA256:
`03c493835b44507fbe692f065f953f9c8252a44edcdf7e62932c3608831d0903`.
C1/C2/C3 agree on canonical surface, ordered admissions, TypeScript and JavaScript.
N1's TypeScript/JavaScript also agree with the generated generations.
The generated JavaScript SHA256 is
`fb7708698c333c1985ae82c0eb5b061c8738f41feffc12f3fddccb1c74fc6855`.

All three full-source inventories complete with 244 expression-typing obligations
and 19 type-argument arity findings. E's isolated repair resolves the latter
category below. H recovered the pinned A seed from its verified cache.

The unchanged pinned provider accepted H's two deduplicated compiler/capability
admission streams after emission. Its preserved receipts are
[qualification](docs/selfhost-language/helper-migration-qualification.json),
[helper correspondence](docs/selfhost-language/helper-migration-correspondence.json),
[small compiler receipts](docs/selfhost-language/helper-migration-compiler-evidence.json)
and [provider acceptance](docs/selfhost-language/helper-migration-provider.json).
The provider identity and checked-emission boundary are the same as E below.

## Historical E evidence before the portable checker

Run 37852341550: compiler job `113568120771` and provider job
`113579690742` both succeeded on the first execution.

E contains 56 raw modules / 992,338 Git blob bytes. Raw source closure SHA256:
`d7866a3c8da745db5b0f6c7ce67381915f6265263615c13a243ec674c1ab13e2`.

C2 and C3 agree on canonical surface, ordered admissions, TypeScript and
JavaScript. Their generated JavaScript SHA256 is
`b6783f5d3ae25fe2da233da3a2c607445efa007a62bbde0275cfa6b8b8b04816`;
native-generated N1 has the same JavaScript bytes. C1's JavaScript is
`d3fd03481ce03d4d2f962f932d4987aff28a7dcf68a395467be2dc57f1d60a2c`.
Its difference is permitted by the C2-versus-C3 contract: the older Q produced
C1's IR, while the new C1 executable contains the repaired erasure used for C2.

The complete C2/C3 IR inventories have **zero type-argument arity findings** and
**244 call-expression typing obligations**, with no other recorded categories.
C1 retains the historical 19 type-argument arity findings in its Q-produced IR.
B's 244-plus-19 result and its empty generic erasure context are historical;
the new repair must not be listed as future work again. The remaining 244
records identify unfinished expression typing, not 244 proven runtime failures.

The unchanged pinned provider source is
`963030dc2d154008fccc82e7c8ed29331f138799`, with binary SHA256
`88f2d20ea733742d48724ecbdc903271e18bcfcccc8682be596a676aef68e3ec`.
It accepted three deduplicated streams: E compiler admissions, raw .lean/.ps
capabilities, and the focused generic-erasure fixture. Default fuel 131,072 and
timeout 60,000 ms were unchanged. Emission preceded this separate check;
`emissionWasGatedByThisCheck` remains false.

Exact qualification, correspondence, compiler and provider receipts are indexed
in [docs/selfhost-language/qualification-evidence.json](docs/selfhost-language/qualification-evidence.json).
E's preserved receipts include
[qualification](docs/selfhost-language/recursive-generic-erasure-qualification.json),
[C2 generic conformance](docs/selfhost-language/recursive-generic-erasure-conformance.json),
[small compiler receipts](docs/selfhost-language/recursive-generic-erasure-compiler-evidence.json)
and [provider acceptance](docs/selfhost-language/recursive-generic-erasure-provider.json).

## Seed, development workflow and next work

The selected authoring compiler Q remains A from
`e91b9558d665879871b8bf0893915ae64b27c7fe`, with JavaScript SHA256
`9d8a91e890c779c6b377b8a482ae3e997a1630b360eb8d6e7c022b3964510096`.
Do not silently promote E, M6 or the TS7 compiler as the seed, or claim the
historical S0 can consume the migrated source. Preserve the authenticated S0 -> A recovery route and A's
qualified seed cache/artifact identities.

Ordinary edits use `npm run dev:sh1`; `npm run iterate:sh1 -- ... --loop`
provides optional resident preparation reuse. Full runs also execute the bounded
native gate before expensive selected-Q generation. Source-family and semantic
milestones receive C1/C2/C3 plus exact provider checks, selected by
`[sh1-qualify]` or full manual dispatch. Independent checkpoint branches may
qualify in parallel. H and E passed their native, compiler and provider gates on their first
execution. M6 and TS7 preserve their separate attempt histories above.

H's bounded native gate took 39.951 seconds, and E's took 25.886 seconds.
Full C1/C2/C3 generation totals were 993.651/1,011.667/991.582 seconds for H and
607.562/606.556/632.401 seconds for E. These are recorded single-run scopes,
not a benchmark or a general speedup claim. The earlier 14.590-second
development result used a smaller bounded gate; warm resident preparation
measurements exclude source reads and optional emission.

The current TS7 native development gate recorded **106.462 seconds** internally
(`106461.999493 ms`), excluding the preceding `lake build`. Current C1/C2/C3
generation totals were 1,065.963 / 1,111.846 / 1,153.540 seconds. These
single-run stage totals are separate from the direct CLI comparison and do not
attribute all cross-run timing differences to TypeScript.

The qualified bounded M6 implementation is described in
[docs/selfhost-language/RUNTIME_IR_PLAN.md](docs/selfhost-language/RUNTIME_IR_PLAN.md).
Its portable expression checker covers the active current IR, with scoped
simultaneous type substitution, checked body/initializer annotations, exact
function grouping, global value/function distinction and explicit resource
failures. The current host inventory reports that portable checker.

The recommended next language slice is the bounded parameter-projection
normalizer repair in MIGRATION.md. Keep its implementation consumable by A and
qualify direct raw-source uses of the repaired form. Replace compatibility aliases
only after a separate explicit qualification and selection of a seed that accepts
that authored source.

Strict runtime enforcement additionally needs enabled primitive/layout/import
and scalar/bounds/text-position contracts, erasure/backend correspondence and
generated evidence for the enforced path. Neither zero type-arity findings nor
Core admission acceptance grants strict SH/1. Broader optional source conveniences
and .ps authority remain separately gated future work.

## Scope of this work

Implement the accepted self-host authoring and iteration plan from research commit
80d04e7ab0e9214ffecf093a6272865f0eaca096. Start with ordinary structural recursion
that changes nondependent value parameters, a pure preparation seam, and focused
generated-compiler qualification. Migrate source families only after capability
evidence passes.

M6 TS5 qualification branch: psc0/sh1-ir-checker-v1.
Current TS7 qualification branch: psc0/typescript-7-v1.
Qualified integration branch: psc0/sh1-implementation-v1.
Historical compiler baseline: 37f63c39d4a07189938046c64152bba25d789450.
The historical 55-module record remains immutable.

## Boundaries

- GitHub/cloud only; no local checkout, builds or tests.
- Kernel/provider implementation and metatheory belong to the native workstream.
- No profile activation or checked/native success claim without corresponding evidence.
- Keep current public compiler APIs and source signatures compatible.
- Solve shared semantic/architectural causes; do not weaken gates to obtain a pass.
- Use focused validation for a complete implementation slice, then current-source
  C2/C3 qualification at the milestone.

## Historical execution notes

The following notes retain their original execution-time status from the initial
implementation and first migration. Pending statements below are historical;
the current checkpoint and next work are stated above.

### Implemented architecture

- Recursion: canonical stable/major worker plus function-valued generalized state;
  preserve public binder kinds and argument order with a wrapper. Reject unsupported
  dependent telescopes and escaping self references.
- Provenance: inspect and enforce which nested matches may introduce decreasing children.
- Preparation: pure start/parsed-step/source-step/finish with both environment and
  ordered declaration accumulator. Session caches retain a valid exact-source prefix
  within one compiler import.
- Qualification: pinned historical seed; isolated TypeScript5.8.3 installation;
  branch-scoped cloud workflow; raw .lean/.ps capability examples; candidate execution;
  explicit C2/C3 canonical source/admission/TS/JS equality.
- Native integration coordination: observed branch psc0/native-core-selfhost-v1 at
  963030dc2d154008fccc82e7c8ed29331f138799. Named native workflow run37825822957,
  job113478295740 completed its actual full checked compiler fixedpoint successfully.
  Source hash ee6dd22f1b74b97113cc1a5e36aadad3cceecb2b152653f2c0dc26dd07aa22f7;
  TypeScript hash fb173a348d1555d1ff224b9977f6fee68591b79f781a6b292c2572648415b033.
  This is evidence for the historical native baseline, not acceptance of our new worker
  admissions. New admissions will be checked through a separate pinned provider checkout.

### Design clarification

Canonical surface source is the output of the existing syntax translator. Lowered
worker/core structure is represented by canonical admissions. The minimum checkpoint
does not add a second elaboration-aware source printer. Generated compilers must
consume raw authored forms, so the new lowering path is exercised directly.

### Initial implementation checkpoint (historical)

The first coherent implementation checkpoint contains portable recursion lowering,
preparation/session reuse, raw capability fixtures, C2/C3 qualification, diagnostic IR
inventory and a separate pinned native-provider acceptance job. Its commit requests
[sh1-qualify]; compiler and provider outcomes are pending cloud execution. After earned capability
qualification, migrate a bounded Foundation.List family using a pinned qualified seed.
The independent host IR report is diagnostic evidence; full strict runtime typing and
PSC0-SH/1 strict profile activation remain separate obligations.

### Review decisions before first execution

The child-provenance boundary also requires alpha-equality of the nested expected
result telescope and the whole worker result. This prevents a narrower induction
hypothesis from disguising missing state application. Fixtures include the rejection
and preservation of valid outer hypotheses. Session results are deeply immutable;
parsed cache limits are entry/source-text limits, not a hard compiler-heap bound.

### Setup checkpoint after first cloud attempt

Commit e67647ec4821d609188e6feb5a4de2380857767e started run37831018572.
Job113496067989 stopped in Lean Action configuration because the historical branch
had no lake-manifest.json; no semantic tests or compiler generation ran. Add the
correct dependency-free manifest and explicitly register Ps.Elab.Recursion in Lake.
Preserve the historical changed-argument refusal test by selecting BatchStable; the
enhanced path is covered by the generated raw-source capability corpus. Rerun the
same coherent qualification after these integration corrections.

### Native build checkpoint

Run37831457914 at e52c30313b1e9124864a304a41f3b4b4c8f74bd0 recovered and
cached S0 successfully (JavaScript SHA25674dcebb7b296d81924d92987e99146b5d1c5ff9fbe3d8076ca591952d2ef7f76).
The new recursion module, context and term changes compiled natively. The wrapper
used two Lean4.34 reserved words as local names (`meta` and `public`); rename them
to metaContext and publicDeclaration together. No semantic acceptance rule changed.
Candidate and full qualification remain pending; reuse the cached seed/build outputs.

### Development gate validation checkpoint

Run37831951758 at e91b9558d665879871b8bf0893915ae64b27c7fe has passed native
compilation and the generated C1 candidate, including raw capability and session
conformance. Current-source C2/C3 and subsequent provider decisions remain pending.
The implementation branch is held at that immutable revision while qualification runs.

A separate psc0/sh1-development-gate-v1 checkpoint adds host-only iteration/recovery
tooling for one bounded native-candidate validation. Portable compiler source remains
identical to e91b9558. No active selfhost-seed.json or Foundation source migration is
included. The temporary workflow branch filter and ref-scoped concurrency preserve
the running full qualification.

Ordinary pushes build the current native PSC frontend and use it to emit N1, then
execute raw capabilities, preparation sessions and a two-module resident CLI smoke.
This evidence is native-seeded development execution, not selected-seed ancestry or
a self-host fixed point. Full qualification retains selected-seed C1/C2/C3 and the
independent provider job. The frozen diagnostic ownership case shares the existing
session conformance boundary. Historical recovery verifies complete provenance and
all four seed products; a malformed cache reconstructs rather than becoming selected.

Once A is qualified, pin its actual source/toolchain/product identities, restore the
implementation workflow branch filter, and apply the staged Foundation.List migration
with its bounded behavior/public-type correspondence gate. Preserve A's historical
source recovery path before allowing B to use the new authoring capability.

### Bounded development result

Commit9641928bcf7d5394f46e19a31a8ae3fd096d44b5 passed run37834854232 on its
first execution. Job113509175107 took74seconds including a15second incremental
native build. The native-candidate receipt reports14590.443683milliseconds for
N1 generation and bounded capability/session/CLI checks. The raw closure has56
modules and SHA2567e18013c260de84b08d57e923aef184993b0c5fea4de4775a68288a8ff9e157a.
N1 JavaScript SHA2569d8a91e890c779c6b377b8a482ae3e997a1630b360eb8d6e7c022b3964510096.
These are single cached Linux x64 development measurements, not a fixed-point or
provider claim. The Foundation behavior matrix correctly skipped unchanged source.
See docs/selfhost-language/qualification-evidence.json for this durable checkpoint.

The next migration checkpoint is staged with additive dev:sh1/iterate:sh1 commands,
the same verified-seed Foundation comparison moved ahead of expensive C1 generation,
and a focused update of check-modular-preparation-source.mjs. That legacy guard
still assumed the old worker spelling and accidentally scanned two structures after
the new state type was added. Its replacement preserves prepared declarations-only
ownership and all unchanged admission/provider-session boundaries; generated session
correspondence already supplies the semantic evidence. Run it in B's early source
checks. Portable compiler source and selected seed remain at A until full evidence.
