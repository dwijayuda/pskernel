# PSCV0 M3+B dependent WF, indexed defaults and source fidelity qualification — 2026-10-17

## Accepted compiler/test identity

Accepted compiler/test commit:
[`60586b7e12aee97954d27e698666a8a2531a0db4`](https://github.com/dwijayuda/pskernel/commit/60586b7e12aee97954d27e698666a8a2531a0db4).

All five required runs completed successfully at this exact SHA, with no
failed, cancelled or skipped reported job steps:

| Gate | Run | Job | Result |
| --- | --- | --- | --- |
| Native Linux | [39013004162](https://github.com/dwijayuda/pskernel/actions/runs/39013004162) | `117339312610` | SUCCESS; all 34 reported steps |
| Focused M3 | [39013004160](https://github.com/dwijayuda/pskernel/actions/runs/39013004160) | `117339312632` | SUCCESS; all 15 reported steps |
| F1 canonical model | [39013004195](https://github.com/dwijayuda/pskernel/actions/runs/39013004195) | `117339312771` | SUCCESS; all 10 reported steps |
| F2 operations | [39013004178](https://github.com/dwijayuda/pskernel/actions/runs/39013004178) | `117339312891` | SUCCESS; all 9 reported steps |
| F3/F4/platform | [39013004170](https://github.com/dwijayuda/pskernel/actions/runs/39013004170) | `117339312589` | SUCCESS; all 11 reported steps |

The last gate, native Linux, completed at **2026-10-17 07:33:52 UTC**.
The complete same-SHA evidence was checked before writing this acceptance
record. A later documentation-only branch head does not replace the
compiler/test identity above.

The three fast-gate logs were also fetched in full. F1 independently
kernel-checked the 922-declaration/30-root canonical-model closure and
21-declaration/two-root constructor closure. F2 checked 1,229 declarations
and 36 operation roots. F3/F4/platform checked the 134-declaration/42-root
conversion, 16-declaration/12-root display/cross-width and
196-declaration/91-root platform closures. Their export records name the
same pinned Lean commit, and their imported assumptions are only
`propext` and `Quot.sound`. These are retained independent checks,
not additional M3 score increments.

This receipt extends the accepted baseline `03000e7b0c257fb8f8d2e2b387b7b65a53e8f504`.
It records the cumulative compiler/test changes, not every intermediate branch tip.
M3+B remains open. PR #109 remains draft/open/unmerged on
`psc0/pscv0-v7-m1-parser-ownership-v1`.

Pinned Lean is 4.35.0, commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
The forward language authority is `psc0/PSCV0_LANGUAGE_REFERENCE_v7.2.md`,
blob `694115223777599ba28ee175e14bb642b7b6aa4b`.
Compiler/build/test execution used connected GitHub cloud Linux.

## Qualified source behavior

Optional main result inference distinguishes a missing codomain from an
explicit `:_`. Selected definition/function/constant/partial heads use the
existing shared predefinitions. Opaque and theorem result requirements,
explicit-main versus inferred-local behavior, parser/printer ownership and
ordinary term-hole refusal remain checked. Six source-only requests stay
nested in the Where fixture; they add no separate runtime export.

Inherited-partial local hints are scoped only after validating all original
main modifiers. The unused local termination suffix retains its exact raw
syntax and source spans; hint-only captures are excluded, while actual body
captures remain. Active hints, headers, bodies and mixed-main strategy
errors remain checked. Eight nested source-only requests cover the positive
case and seven refusal boundaries. The positive case checks four closed
public opaque/private body pairs, original binder order, actual recursion,
absence of a defining equation and local provenance. This is source fidelity
within the existing ordinary partial strategy.

Completed focused run [39013004160](https://github.com/dwijayuda/pskernel/actions/runs/39013004160) passed the source build and all fourteen outer fixture commands. The complete log contains the exact `RESULT_INFERENCE`, `PARTIAL_HINT_SCOPE`, `WHERE_SOURCE`, `WHERE_CONSTRUCTION` and `WHERE` PASS markers. Both source-only batches remain nested in Where, so they are not counted as additional outer fixtures or runtime exports.

Sources: [Where fixture](https://github.com/dwijayuda/pskernel/blob/60586b7e12aee97954d27e698666a8a2531a0db4/psc0/test/Pscv0M3Where.lean), [Where scope owner](https://github.com/dwijayuda/pskernel/blob/60586b7e12aee97954d27e698666a8a2531a0db4/psc0/packages/elab/src/Ps/Elab/WhereScope.lean), and [the required workflow](https://github.com/dwijayuda/pskernel/blob/60586b7e12aee97954d27e698666a8a2531a0db4/.github/workflows/psc0-m3-recursive-deriving.yml).

## Qualified indexed defaults and nominal empty dictionaries

Constructor-directed indexed Inhabited elaboration unifies the full
constructor result with the requested family before filling unresolved
fields in telescope order. It retains constructor order, both existing
search passes, uniform parameter requirements and sequential registration.
Four instances retain complete recursor signatures, checked native/portable
equations and semantic refusals. Four runtime exports add 40 scalar
comparisons across the five existing lanes.

Nominal zero-field dictionary values retain actual checked record identity,
producers, forwarders, initializers and runtime slots in ordinary IR. The
selection requires the fully applied prepared structure layout and exact
parameter count. Nonempty specialization and proof/foreign boundary controls
remain. The raw producer guard is checked as the existing
`Bool.decEq flag true` lowering, with its original parameter and both
nominal branches. Four exports add another 40 comparisons.

The completed focused source stage printed `PSCV0_M3_INDEXED_INHABITED: PASS`, `PSCV0_M3_EMPTY_IR: PASS` and `PSCV0_M3_EMPTY_DICTIONARIES: PASS`. The two four-export suites subsequently passed both Boolean inputs in all five lanes, for 40 comparisons each. The nested indexed Rust suite printed its own exact `PSCV0_M3_RUNTIME_RUST: PASS indexedinhabited` after preparing and executing its corrected Cargo harness.

Sources: [indexed fixture](https://github.com/dwijayuda/pskernel/blob/60586b7e12aee97954d27e698666a8a2531a0db4/psc0/test/Pscv0M3IndexedInhabited.lean), [empty-dictionary fixture](https://github.com/dwijayuda/pskernel/blob/60586b7e12aee97954d27e698666a8a2531a0db4/psc0/test/Pscv0M3EmptyDictionaries.lean), [runtime assertion owner](https://github.com/dwijayuda/pskernel/blob/60586b7e12aee97954d27e698666a8a2531a0db4/psc0/scripts/pscv0-m3-runtime.mjs), and [completed execution](https://github.com/dwijayuda/pskernel/actions/runs/39013004160).

## Activated well-founded foundation and generic relations

The independently audited 34-declaration foundation is selected through the
existing Standard extension. Its frozen pre-WF authoring input remains
unchanged. Native regeneration reproduces the exact generated asset:
466,947 bytes, SHA-256
`b6bd56c4ab6378905d1d3ac2f0155eb5bc4742be3e19e684d64ac1a3007716f3`.

The audit checks complete Core identity, reducibility, class/instance
metadata, priorities, aliases, proof closure, native kernel validation,
three recursor rules and actual dictionary synthesis. It reports no
candidate axioms. The activated Standard has 3,633 declarations, 41 classes
and 359 ordinary instances, with these observed identities:

- FNV: `fnv1a64:4990397000639020696`.
- Standard SHA-256: `sha256:5e96678b7ca94ac8dcb63d36cee81c5997287f507ce8c0c26d28321b37ce97d7`.
- Source surface SHA-256: `sha256:7a996cfc6253693799d43fdcf78dd7f30eb0713a3eb31831daa9d804faf818c6`.

The audit helper retains `runtimeQualified: false` because its scope is
foundation audit. The separately completed source/runtime gates provide
execution evidence. The earlier proposed and activated audits are retained
in the dedicated foundation receipt.

The elaborator infers the actual fixed-codomain measure and synthesizes its
`WellFoundedRelation`. It constructs the actual inverse-image relation and
well-founded proof, generic fix and checked public equation. The Nat
optimization requires conversion of both the codomain and its dictionary.
The lexicographic-left and lexicographic-right examples add ten comparisons.

The focused log prints both `WF_CONSTRUCTION` and `WELL_FOUNDED` PASS, establishing the unchanged lexicographic relation construction, public equations and five-target emission. The fourteen-export WF module then passed all five runtime lanes, including the combined generic-relation export.

The native WF oracle logs 33 assumption closures, all within the approved set. In particular, `WellFounded.fix` and `WellFounded.fix_eq` report empty axiom lists. This is separate from the deliberately rejected P1 closure.

Sources: [WF fixture and native oracle](https://github.com/dwijayuda/pskernel/blob/60586b7e12aee97954d27e698666a8a2531a0db4/psc0/test/Pscv0M3WellFounded.lean), [WF elaboration owner](https://github.com/dwijayuda/pskernel/blob/60586b7e12aee97954d27e698666a8a2531a0db4/psc0/packages/elab/src/Ps/Elab/WellFounded.lean), and [completed focused execution](https://github.com/dwijayuda/pskernel/actions/runs/39013004160). The complete same-SHA native foundation audit is recorded below.

## Exactly two dependent changing arguments

The selected case packs exactly two dependency-ordered changing binders
into one real PSigma layer. The second binder's type depends on the first.
Fixed parameters and captures remain outside the pack; an interleaved fixed
argument stays in its original public position. The measure has a fixed
codomain. The previous unary changing-major plus dependent-state route
remains available when only the first slot is measured.

The logical definition uses actual PSigma constructors/elimination and
WellFounded.fix. Its public curried equation is derived through actual
fix_eq, pair elimination, funext, congrArg and Eq.trans. The entire dependent
callback proof-binder function is inside the pair-elimination motive before
extensional transport.

Typed erasure validates the exact domain/family/constructor shape, two
distinct original header IDs, source order, dependency, complete type,
capture closure and absence of extra state. It checks the full curried
adapter type and replaces only exact alpha-matching adapters with the same
type. Replacement must occur, the raw callback must disappear, and applied
body types must agree before and after replacement. It restores callbacks
at their original header positions and retains ordinary erased proof
slots.

The fixture checks native and portable definitions returning both Nat and
a dependent Fin result, public equations, real Core constructors and
eliminators, closed terms, no unresolved metas, all-kind entry arities, and
rejection of reordered, duplicate and foreign packed fields. The actual
nondecreasing second-slot example still fails its decrease proof; a native
zero-not-less-than-zero theorem makes that boundary explicit. A third
changing argument and changing measure codomain remain refused.

The WF batch has 21 requests: two positive cases and 19 refusals. It retains
14 runtime exports. The new packed export contributes ten comparisons
across the five lanes, evaluated against the actual native oracle.

All three exact WF source/construction/completion markers passed on the original fixture, Git blob `8f5e8d6caee85aa22ec5082530b132cf82f1d5d0` (52,240 UTF-8 bytes). The two positive requests and nineteen required refusals completed before target execution.

For both `m3wfpacked` and `m3wfpackedBounded`, the fixture requires generic `WellFounded.fix`, a real PSigma domain, `PSigma.casesOn`, and `Prod.Lex.left`. Their public `eq_def` proofs must contain generic `fix_eq`, pair elimination, `funext`, `congrArg` and `Eq.trans`. The closure, absence-of-metas, full typed adapter and entry-role checks passed unchanged. The packed entry retains universe `u`, roles `[index, proof, proof, runtime, runtime, runtime]`, and runtime/type arities `5/0`; the dependent-result entry retains two runtime roles and arities `2/0`.

Native `packed` and `packedBounded` report no axioms. Their step equations each report `[Quot.sound]`; these step equations are not described as axiom-free. The explicit zero-not-less-than-zero refusal witness reports no axioms.

The fourteen-export WF suite contributes 140 observed comparisons across all five lanes. Its new packed output accounts for ten of those comparisons. The receipt relies on the actual native-oracle assertion loop and completed execution; it does not claim a separate manual read of the generated `expected.json` artifact.

Sources: [unchanged WF checks](https://github.com/dwijayuda/pskernel/blob/60586b7e12aee97954d27e698666a8a2531a0db4/psc0/test/Pscv0M3WellFounded.lean) and [completed focused run](https://github.com/dwijayuda/pskernel/actions/runs/39013004160).

## Full focused execution and native regression evidence

The required outer source fixture count is 14. All original fixtures and
their refusal/mutation checks remain. The common scalar runtime runner
requires exactly both Boolean inputs and all requested Bool-to-UInt64
exports, including exact decimal oracle values.

The workflow retains 12 scalar module suites with 68 exports: 136
comparisons per lane and 680 over direct JavaScript, strict compiled
TypeScript, locked Rust, V8 GC core and native Wasmtime components.
The cumulative increment from the prior accepted baseline is 100:
40 indexed defaults, 40 empty dictionaries, ten generic relations and ten
dependent packing comparisons. The separate original recursive Hashable
workload also remains.

Focused job `117339312632` completed successfully with all 15 reported steps green. All 668 build jobs passed. The complete fetched log is 7,699,576 characters and contains all fifty source PASS markers: the forty-eight prior successful markers are retained, and WF construction/completion now pass. No source FAIL marker remains.

The fourteen outer fixtures are inductive groups, P1 assumption refusal, original recursive deriving, inductive runtime, WF, inductive match, mutual partial, inductive deriving, mutual structural, nested inductive, Where, nested deriving, group proof deriving and empty dictionaries. Indexed Inhabited is nested inside group proof deriving; result inference and partial-hint scope are nested inside Where.

| Scalar suite | Exports | Two-input comparisons per lane | All five lanes |
| --- | ---: | ---: | ---: |
| `groupfold` | 2 | 4 | 20 |
| `wellfounded` | 14 | 28 | 140 |
| `groupmatch` | 4 | 8 | 40 |
| `mutual` | 5 | 10 | 50 |
| `groupderive` | 6 | 12 | 60 |
| `mutualstructural` | 6 | 12 | 60 |
| `nestedfold` | 7 | 14 | 70 |
| `wherefixture` | 6 | 12 | 60 |
| `nestedderive` | 6 | 12 | 60 |
| `groupproof` | 4 | 8 | 40 |
| `emptydict` | 4 | 8 | 40 |
| `indexedinhabited` | 4 | 8 | 40 |
| **Total** | **68** | **136** | **680** |

An anchored scan of actual output, excluding echoed shell commands, observes exactly 24 scalar ECMA PASS lines (one direct JS and one compiled TS line for each suite), twelve distinct scalar Rust PASS stems, and twelve scalar Wasm PASS stems. Each Wasm pass asserts both V8 GC core and Wasmtime component results. Every suite appears exactly once in every lane.

The separate original recursive Hashable/Repr/BEq/DecidableEq suite retains 24 exports and both Boolean inputs. Its two ECMA PASS lines, one exact Rust PASS line and one Wasm core/component PASS line establish another 240 comparisons. The combined focused total is therefore **920 observed comparisons** across thirteen runtime suites. All 58 scalar exports from the accepted baseline remain; the ten additional exports account for the 100-comparison increment.

Focused artifact [12093283123](https://github.com/dwijayuda/pskernel/actions/runs/39013004160/artifacts/12093283123) contains 267 uploaded files, is 2,844,284 bytes, and has SHA-256 `0e6af29411dfa8c4f43fcc32badc143765d36c56af1f45ab3ceef1e26323de07`. It was created at 07:23:21 UTC; the run finalized at 07:23:25 UTC. The recorded digest is GitHub's uploaded archive digest.

Sources: [completed job](https://github.com/dwijayuda/pskernel/actions/runs/39013004160/job/117339312632), [scalar assertion loop](https://github.com/dwijayuda/pskernel/blob/60586b7e12aee97954d27e698666a8a2531a0db4/psc0/scripts/pscv0-m3-runtime.mjs), [original assertion loop](https://github.com/dwijayuda/pskernel/blob/60586b7e12aee97954d27e698666a8a2531a0db4/psc0/scripts/pscv0-m3-recursive-deriving.mjs), and [all required invocations](https://github.com/dwijayuda/pskernel/blob/60586b7e12aee97954d27e698666a8a2531a0db4/.github/workflows/psc0-m3-recursive-deriving.yml).

### Complete native regression

Native [run 39013004162](https://github.com/dwijayuda/pskernel/actions/runs/39013004162),
[job 117339312610](https://github.com/dwijayuda/pskernel/actions/runs/39013004162/job/117339312610),
ran from 07:16:15 to 07:33:52 UTC. All 34 reported steps passed, with no
skips, failures or cancellations. Its complete fetched log is 4,478,854
characters and contains 157 parsed JSON records, including 108 bounded
profiles.

The `pscv0-well-founded-foundation-audit/1` record is field-for-field
identical to the preceding completed activated audit: 34 active
foundation declarations, 34 candidates, no candidate axioms, native
kernel validation, three compared recursor rules and the exact activated
Standard identities listed above. Its own `runtimeQualified: false`
field retains the foundation-audit scope.

The original source gate retains 293 portable modules and 308 native
closure modules. It passed four checked programs and 92 phase-specific
refusals, plus eight do refusals, two comparison-syntax refusals and one
opaque-definition refusal. The source manifest retains 3,633 strict
declarations. Existing synthetic, default-instance and postponed-work
checks explicitly pass captured scopes, independent replay, mandatory
defaults, quiescence, rollback, priorities, transactional dependencies,
numeral fallback and delayed refusal. These checks directly exercise the
queue behavior surrounding the new narrow instance-progress point.

| Native regression evidence | Observed result |
| --- | --- |
| Direct JavaScript | 1,069 shared runtime observations |
| Compiled TypeScript | 1,069 shared runtime observations |
| Locked Rust | 1,069 shared runtime observations |
| Platform contracts | 35 shared probes per profile in Wasm, ECMA and Rust |
| Linked application | `App.compute(7)=18`, entry exports and three-file provenance |
| Linked GC modules | Four-module checked execution under both V8 and Wasmtime |
| Linked Rust modules | Three-module application passed |
| Direct-JS provenance | 1,239 declaration mappings and 52 generated-parent origins |
| Repeated native Wasmtime host | Shared observations, aggregates, normalization, indirect parameters, repeated calls and post-return passed |
| Generic recursion | Nat/Bool payloads at 100,000/50,000 steps |

The GC JSON record reports profile `pscv0-wasm-c4-gc/1`, five scalar
worlds, 1,069 shared observations, ten natural-limb checks,
`gcInsideComponent: true` and `coreBinaryWatEqual: true`.
It records Node 22.23.3, V8 `12.4.254.21-node.57`, wasm-tools 1.261.0
and Wasmtime 49.0.2.

The M1 performance record names source SHA
`60586b7e12aee97954d27e698666a8a2531a0db4` and the pinned Lean commit.
It reports **7,853 ms** for prelude initialization, four compiler
configurations and twelve runtime rows. The established method uses one
warmup, five runtime samples and three compiler samples after warmup,
excluding setup. The compiler comparison uses the same PSCV0 compiler
and process with identical Array/proof binder telescopes, comparing direct
index return with checked collection lookup at 16 and 128 declarations.
Native Lean and generated JS execute matching operations in different
runtime systems; these measurements are not a compiler-equivalence
benchmark or a claim of a statistically established speed improvement.

Native artifact [12094485892](https://github.com/dwijayuda/pskernel/actions/runs/39013004162/artifacts/12094485892)
is 6,797,545 bytes, created at 07:33:49 UTC, with uploaded-archive SHA-256
`17fe748f9e214a470876129d1f76833e64e46ba08c560967ef7afb9b3fd25feb`.
The artifact metadata, complete run/job identities and measurements all
name the accepted compiler/test SHA.

The earlier proposed and activated foundation audits remain in the
[dedicated foundation receipt](https://github.com/dwijayuda/pskernel/blob/176ac54106b2f7c6f37fb0733af69c609454b137/psc0/docs/PSCV0_M3_WELL_FOUNDED_FOUNDATION_AUDIT_2026-10-17.md).
The full native workflow at the accepted SHA is
[the execution contract](https://github.com/dwijayuda/pskernel/blob/60586b7e12aee97954d27e698666a8a2531a0db4/.github/workflows/psc0-pscv0-native-v7.yml).

## Repairs and evidence boundaries

### Earlier syntax and fixture repairs

Intermediate compile failures remain diagnostic records. Reserved Lean
binders and returned-record layout were corrected before the independently
successful activated native replay. The combined packing callback-equality
call then needed an indented branch body; the native packed decrease proof
needed its complete term on one line. Both repairs retain identical proof
functions and arguments.

The empty-dictionary fixture originally expected a bare-variable branch
guard in raw IR. Tracing the existing conditional elaboration and decision
erasure established the actual Bool equality intrinsic. The fixture now
requires that exact checked guard and both nominal branches. Native
indexed parent observers were generalized to their actual constructor
telescopes. These fixture corrections retain the independent native oracle
and production semantic checks.

### Ready-instance ordering repair

The faithful recursive-worker diagnostic at
[`7f9d7d9a`](https://github.com/dwijayuda/pskernel/commit/7f9d7d9a2abfc911f885976ca52f5b0275b42c72)
identified one ordinary instance goal left by the first explicit
`Prod.Lex.left` coordinate. The numeral in `k - 1` still contained an
unresolved `OfNat Nat 1` dictionary. That prevented an otherwise eligible
complete expected-result comparison from matching the smaller product
pair. Its speculative assignments rolled back, and the nested arithmetic
proof inferred a different relation before the final application check.

Resolving that ready instance to `PsStandard.instOfNatNat 1` made the
same complete expected-result comparison succeed. The repair therefore
progresses only scoped ordinary instance work inside the existing enabled
and eligible application-result branch, before the existing comparison.
Result eligibility is computed first. Captured environments and instance
registries, checked assignment, queue order, full returned context and
resource-failure behavior are retained. Defaults, source continuations,
expected-term adaptation and coercion resumption do not run at this point.
Constructor constraints keep their existing order.

The pinned native application owner follows the same relevant order:
resulting-type eligibility, ready instance synthesis, then expected-type
comparison. Earlier manual diagnostic callbacks had used top-level term
elaboration and drained work between arguments; they did not reproduce the
recursive worker. Their stronger scheduling conclusion was withdrawn
before the faithful diagnostic established this cause.

The two production changes are [Application.lean](https://github.com/dwijayuda/pskernel/blob/60586b7e12aee97954d27e698666a8a2531a0db4/psc0/packages/elab/src/Ps/Elab/Application.lean)
and [Postponed.lean](https://github.com/dwijayuda/pskernel/blob/60586b7e12aee97954d27e698666a8a2531a0db4/psc0/packages/elab/src/Ps/Elab/Postponed.lean).
Their current Git blobs are respectively
`38b24a2bc0f062204cb34b829ed3eba1ea954744` and
`02454575e32cf98add4a2c4c215908ba2c5530d0`.
The unchanged source proof, ordinary unifier and reducer then pass the
complete qualification. Temporary deep replay helpers and raw-worker
plumbing are removed. The WF owner is restored to the exact phase-only
blob `ae03d72b3345d14f104c61c2c67ecb5b05eef52a`, retaining concise
declaration/phase errors and all original proof checks.

Primary comparison:
[pinned Lean application elaborator](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/App.lean).

### Nested Rust assertion-harness repair

The indexed suite is nested below the group-proof directory. Its old
relative output calculation wrote `rust-checks.rs` to a directory
different from Cargo's selected binary path, which would rerun the
preceding empty-dictionary assertions. The common
[runtime runner](https://github.com/dwijayuda/pskernel/blob/60586b7e12aee97954d27e698666a8a2531a0db4/psc0/scripts/pscv0-m3-runtime.mjs)
now resolves the canonical `dist/pscv0-native` directory from its own module
URL, matching [Cargo's existing target](https://github.com/dwijayuda/pskernel/blob/60586b7e12aee97954d27e698666a8a2531a0db4/psc0/v7-native/rust/Cargo.toml).
The eleven flat suites retain their original destination.

No oracle, export name, Boolean input, assertion loop or PASS marker
changed. The completed focused run observes the exact indexed Rust PASS
after its own harness preparation, so all eight indexed Rust comparisons
are included in the accepted total. The runner is 4,142 UTF-8 bytes, blob
`83f069245f7b94fa5a9bce4779ab6619b46512c3`, SHA-256
`2c63a01c05a98563ef1e261ccaaaa769485c5229ce37ee462a2f8c3d494645ca`.

Only a complete five-gate matrix at one compiler/test SHA advances
acceptance. Partial native or source success at earlier candidates does not
independently award progress.

## Engineering progress and remaining obligations

This completed same-SHA matrix raises the accepted engineering estimate
from **74/100 to 78/100**. It measures progress against the six selected
milestone exits; it is not measured language coverage.

| Exit | Weight | Previously accepted | Accepted now |
| --- | ---: | ---: | ---: |
| Data, elimination and deriving | 30 | 24 | 25 |
| v7.2 source strategies | 15 | 13 | 14 |
| Total structural/WF recursion | 20 | 14 | 16 |
| P0 ordinary partial execution | 15 | 13 | 13 |
| P1 selected partial_fixpoint | 10 | 1 | 1 |
| Cross-stage integration | 10 | 9 | 9 |
| Total | 100 | 74 | 78 |

The data increase groups the bounded indexed-default and empty-dictionary
additions into one point. The source increase groups optional main result
inference and inherited-partial hint fidelity into one point. Actual
fixed-codomain relation selection and checked dependent argument packing
justify two total-recursion points. Syntax, fixture, initialization, instance-order and harness
repairs receive no separate credit.

P0 receives no increase from the source-only hint fix. Existing evidence
already covers selected standalone, self-recursive and mutual partial
definitions, imported calls, local captures, nullary and higher-order peers
and closure lowering. Completion of their full combination matrix remains
unestablished; this receipt does not invent an unsupported P0 mechanism.
Logical opacity, absence of a total equation and the separate requirements
for verified execution remain intentional distinctions.

M3+B remains open, approximately **75–80%** by this engineering estimate.
The broader indexed binary BEq/DecidableEq, arbitrary positive containers
and function-valued nested fields, complete source-induction families and
nested eliminators remain bounded. Fully applied nominal prepared empty
dictionaries do not establish general first-class dictionary support.

Omitted main results depending on the main's own binders still require an
annotation. General unused-hint diagnostic parity outside the validated
all-partial original main block remains open; the ordinary nonrecursive
unknown-measure refusal is a retained boundary rather than native-parity
evidence.

Generic WF measures retain a fixed codomain and checked decrease
obligations. Independent changing pairs, a third changing slot, arbitrary
changing telescopes, arbitrary nested packing and general mutual WF remain
unqualified. The existing unary major with dependent changing state is
retained; the new evidence concerns exactly two dependent changing slots.

The full M3+B exit matrix, M4 assurance and M5 completion remain open.
The same-SHA qualification of this cumulative slice does not by itself
close those obligations.

Only `propext` and `Quot.sound` are approved assumptions.
P1 remains blocked by the audited `Classical.choice` dependency in
`Lean.Order.CCPO.csup`, `Lean.Order.fix` and their selected native
Unit/Option equations. The source refusal remains closed.

No complete later milestone is declared finished. The branch remains
native portable Lean, with the existing compiler ownership and backends.
