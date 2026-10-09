# PSC0 SH/1 implementation work state

Updated: 2026-10-09 11:45:30 UTC.

## Active continuation: new-only R3 source grammar and projection repair

The user explicitly requests **no active backward-compatibility grammar**: adopt
the new supplied .ps syntax only where implemented. Work is isolated on
`psc0/sh1-projection-grammar-v1`, based on qualified integration
`5e3a991088aaa735c8f324c4e70a7a3dee4cd69a`. Canonical integration remains at that
completed checkpoint while this new source change is prepared and qualified.

The supplied reference is
`ProofScript_PSCV_Language_Reference_NORMATIVE_RC_v2_Lean4.35rc3 (1)(6).md`,
401,569 bytes, 8,546 lines, SHA-256
`4c02626fd0b991e8526c64b65f4ffb66b9ce7b688298e82fb0309802a263db71`.
Its status is PSCV-RC-v2 design, with a pending Standard environment manifest and
pending implementation conformance. This work adopts a bounded set of its owned
base grammar rules; it does not claim full PSC2 Standard or PSCV conformance or
repin the Lean/provider workstream.

Implementation assembled for the coherent qualification checkpoint:

- Shared exact-name / first-segment / longest proper local-prefix resolution
  repairs recursive record-parameter projections. Structural identity predicates
  stay exact-only; no type-error fallback or name exception is added.
- Replace the current .ps parser and printer together: newlines for sequence
  ownership, one comma-oriented explicit declaration/constructor parameter group,
  strict record commas, complete grouped call terms and adjacent postfix calls.
- Preserve empty invocation as an empty argument list. Optional argument
  completion is unsupported and fails explicitly; `f(())` remains one Unit
  argument. The old `f()`-means-Unit shortcut is removed.
- Use a PS-specific lexical entry for its whitespace/line rules; the bounded
  Lean authoring parser remains available as a separate source kind.
- Migrate owned active PS fixtures and source-loading paths. A full raw-source
  parser must see PS imports before any host stripping can hide obsolete syntax.
- Unsupported broader syntax and verification semantics remain explicit
  refusals. In particular the old compilerBind/compilerPure-specific do sugar
  is not relabeled as Standard monadic or verified do.

No new grammar/compiler qualification has completed for this continuation.
This code checkpoint is a qualification candidate, not a success receipt.

The first cloud attempt at `48723fe676a0d9ae3fa819bd314199fe0ca2e926`
([run 37925016499](https://github.com/dwijayuda/pskernel/actions/runs/37925016499))
passed source/profile/helper and authenticated A recovery gates, then stopped in
the native build. Two root causes were reported: the new local name `postfix`
is reserved in Lean, and the Term empty-call guard referenced a list helper that
is not imported there. The correction renames that local to `postfixResult` and
uses direct `List.nil`/`List.cons` matching without adding an import or changing
application semantics. The parser/lexer helper and local-name audit found no
additional direct-reference blocker. The next attempt runs all three existing
native regression suites before returning their combined failure status, so one
failing suite cannot hide another suite's diagnostics. No gate is relaxed.
See [the exact first-attempt evidence](docs/selfhost-language/grammar-migration-attempt-1.json).
Native regression, N1, C1/C2/C3, provider and cold successor gates have not yet run.

The planned early gates cover migrated native parser/printer/elaboration tests,
fatal UTF-8 and actual-AST import loading, and successor descriptor integrity.
N1 checks 40 small grammar round trips plus explicit refusals and the complete
61-module Lean-to-new-PS-to-Lean correspondence. The exact N1 canonical surface
digest is reused as the required C2/C3 surface digest, avoiding a repeated full
round-trip pass. Each current generated compiler also executes the raw capability
fixtures, including 39 projection and 34 new-grammar behavior observations.

A distinct TS7 successor descriptor and same-revision recovery runner are included.
They preserve the complete unchanged v1 A descriptor and compare the separate
first-generation and final products of A(raw successor source) and C1(raw source).
Only a fresh two-generation recovery may earn the cold-recovery receipt. Seed
selection requires both that receipt and actual independent provider acceptance;
compiler qualification alone never changes the selected manifest. The remaining
12 worker migrations are prepared separately and are not part of this source
checkpoint. Current
Lean 4.34.0, Node 22.23.3 and TypeScript 7.0.2 pins remain; historical S0/A recovery
uses immutable old revisions and exact TypeScript 5.8.3. That recovery is not an
active old-PS parser in the new compiler. A remains selected until a separately
qualified recoverable successor is explicitly selected.

The remaining practical source migration is now finite:
**12 workers in 9 source files across 2 families**, followed by **3 projection
alias removals** and the final adoption evidence. See
[the backlog](docs/selfhost-language/MIGRATION_BACKLOG.md) and
[its machine-readable inventory](docs/selfhost-language/migration-backlog.json).
All 1,500 declaration headers in the audited 5e3 baseline's 61-module closure were inspected;
none has a non-explicit binder after an explicit binder, so the new declaration
grammar does not require reordering the current compiler's public telescopes.

## Last completed M6 and TypeScript 7 result

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
