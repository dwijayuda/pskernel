# PSKernel-Core Expression V2 integration work state

Date: 2026-10-21 (Asia/Jakarta; Actions timestamps use UTC)
Status: **IN PROGRESS — NOT a completed Expression V2 kernel**
Integration branch: `integration/psc1-pskernel-expr-v2-lean435-20261021`
Research parent: `research/psc1-pskernel-expr-v2-lean435-20261020`
Refreshed research HEAD: `c98be336e2e95dda998e4353dd791bdba5d8cb4f`
Toolchain: `leanprover/lean4:v4.35.0`
Exact Lean source: `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`

## Current checkpoint and evidence

The latest native-qualified implementation is
[fa0ca224c6fd192d0afa2418d415a6dc67f9f333](https://github.com/dwijayuda/pskernel/commit/fa0ca224c6fd192d0afa2418d415a6dc67f9f333).
Its native job in [39512106401](https://github.com/dwijayuda/pskernel/actions/runs/39512106401)
passed the complete DAG regressions, official Lean fixtures, beta/zeta resource
parity, 1,755 transformation comparisons, local metadata/cache-scope theorems,
the new depth/count budget equivalence theorems, and matched native benchmarks.
The proof axiom check passed. This is not a whole-kernel soundness theorem.

The strict generated runtime smoke for the same semantic implementation passed
on 269552f in [39511802579](https://github.com/dwijayuda/pskernel/actions/runs/39511802579).
The generated job is fully green: 578 strict transformation comparisons,
large shared-DAG, beta/zeta, standalone runtime, whole-checker benchmarks and
33 existing complete-checker operations passed. The workflow itself remains
red because its earlier native proof failed; fa0ca224 corrects that proof.
The earlier dd466 run checked all 1,225 source declarations and emitted JS,
declarations and a source map. Its runtime failure was a host-harness ABI error:
returned function arrows are unary, while known declaration entries have flat
arguments. Seven call sites were corrected; the strict unapplied-oracle guard
remains.

The first independent Arena job at c29f418 has passed complete canonical PS
reconstruction and checking and is generating the executable. The full corpus
comparison has not yet produced a qualified independent result.
The last fully green integration + six-job research checkpoint remains
[69de396ec537c8130b87388ba8045859e443141b](https://github.com/dwijayuda/pskernel/commit/69de396ec537c8130b87388ba8045859e443141b):
[39506742023](https://github.com/dwijayuda/pskernel/actions/runs/39506742023)
and [39506742177](https://github.com/dwijayuda/pskernel/actions/runs/39506742177).
Do not substitute that earlier result for final-commit qualification.

No PR has been merged. Keep the integration branch isolated until all relevant
gates on the eventual implementation commit have passed.

## Objective and execution constraints

Finish the paged expression architecture in the complete independent checker.
The user's complete acceptance criteria remain binding: production integration,
native and official Lean differential checking, all applicable Arena cases,
authentic PSC1 and canonical PS, executable independent JS, unchanged resources
and axioms, whole-checker memory/performance, and final-commit Actions evidence.

All repository reads/writes and tests use connected GitHub and GitHub Actions.
No local checkout or compilation, force updates, release or package publication.
Do not add proof holes, unchecked assumptions, higher kernel fuel, weakened
negative assertions, or exclusions for difficult cases. Finite tests do not
establish formal soundness.

## Actual implementation and remaining boundary

Production owns the paged Node/Entry, indexed storage, smart constructors,
metadata replay validator, collision-safe equality, lifting, multi/reverse
instantiation, abstraction, universe substitution, spine helpers and decoder.
Scalar expression syntax and scalar hashing were factored into shared modules;
the DAG foundation does not import the legacy recursive expression or checker
cache. Promoted Research module names forward to the production owners.

`psKernelV1RunDag` is the public untrusted-input boundary. It validates one arena
and decodes each unique node once for an ordered command batch. Input tables can
be constructed directly through the production paged smart constructors.
Terminal/metadata inference, checked syntactic DefEq, and qualified WHNF slices
read DAG entries directly. All structural shortcuts resolve hash collisions.
Both terms still undergo complete checking before the DefEq shortcut.

**General inference, full DefEq, environment/local declaration expression fields,
delta/recursor/projection/primitive behavior and declaration admission still use
the original recursive expression internally.** This once-per-batch decoder and
the complete fallback are transitional. The default original V1 API also remains.
Do not describe this architecture as the finished replacement or retire the
oracle before the remaining semantic migration qualifies.

Kernel fuel4096 is a recursive bound, not a globally spent instruction count.
Public/core WHNF entry order, recursion-depth guards, C0 beta-spine batching and
expression-derived substitution bounds are preserved. Default DAG transforms use
cached depth after validation: the old expanded count+1 was already capped to
that depth. The native depth/count lemmas justify that numeric cap, not full
substitution refinement. Bounded zero-fuel transforms retain the input subtree.

All seven original semantic caches are restored when leaving a local scope;
only the maximum fresh-name counter survives. FVar-containing terms cannot
publish semantic cache knowledge across contexts. Same numeric IDs in separate
arenas are unrelated. The portable profile exposes internal helpers/records;
the documented checked boundary, not a sealed constructor type, establishes
canonical arena/decoded correspondence.

## New function-normalization migration (qualification pending on this commit)

The next production slice replaces the stateless WHNF fragment with an
operation-owned core cache and threads it through function-position and result
normalization. It directly handles beta/zeta/metadata function heads, preserving
the original predecessor fuel for both calls. Alpha-equivalent keys with
different IDs use collision-safe structural lookup and return the first stored
result syntax; FVar-containing keys are ineligible. Fuel/depth checks precede
hits. The public wrapper always starts empty and discards its internal cache.
Unsupported constant/local-let/recursor/projection/primitive paths still restart
the complete original checker with the original resources.

New native and generated tests cover distinct-ID cache hits, exact cached
syntax, a real hash collision, warmed-cache fuel/depth entry guards, local-scope
exclusion and complete public checking. Three local proofs establish empty
initialization and flag-based lookup/publication exclusion; they do not prove
arena ownership or global cache correctness.

The same complete-public benchmark now includes shared heads, copied
alpha-equivalent heads, unique tags and hash collisions at depths8/32/128.
Native samples use isolated processes with actual peak RSS and matching official
check+WHNF; official Lean exposes no PS fuel parameter. JS retains isolated
A-B-B-A, cold/warm, construction and post-GC heap measurements. An untimed raw
diagnostic reports actual cache growth after the public timing/memory snapshot;
it explicitly does not measure hit/miss/probe counters. No cache eviction or
fuel change is allowed. Results for this slice remain pending.

## Milestone matrix

| Milestone | Implementation | Native correctness | PSC1 / PS / JS | Whole-checker performance | Status |
| --- | --- | --- | --- | --- | --- |
| Paged representation | Single production owner; all 12 families; exact cached metadata | Forgery, collision, sharing, page and reference tests pass | Qualified foundation; current complete closure builds | Construction and validation included in complete-operation measurements | Integrated foundation |
| Transformations | Lift, instantiate/multi/reverse, abstract, universe substitution, spines; scoped memo | 1,755 comparisons plus budget/sharing/negative cases pass | Authentic source and strict generated transform smoke pass | Large shared-DAG fixture; not a full checker speedup claim | Integrated prerequisite |
| Checked DAG ingress | One replay/decode per batch; complete V1 command and declaration families | Positive/negative/fuel/admission regressions pass | Strict standalone generated smoke passes; canonical closure check passes | Adapter cost retained; some fallback checks remain slower | Transitional |
| WHNF | Terminal/metadata/zeta/syntactic-lambda beta qualified; operation-owned function-normalization cache added; qualification pending | Qualified slice has exact low-fuel/depth parity | Qualified slice strict generated smoke passes | Native checked zeta WHNF improves on matched fixtures | Partial; full delta/iota/projection/primitive migration open |
| Inference and DefEq | Terminal/metadata inference; collision-safe checked syntactic shortcut | Complete fallback and shortcut tests pass | Complete checker executes in generated JS | Metadata checks improve; general inference unqualified as DAG-native | Partial |
| Inductive admission | Direct DAG request ingress, complete original admission internally | Existing admission tests pass | Real generated definition/ordinary-inductive checks pass | Full admission comparison pending | Not migrated internally |
| Canonical self-hosting | Actual full production import closure; counts from manifest | Pinned Lean build passes | Current source/canonical checks pass; current final executable gates still running | Generator/runtime costs remain visible | Partial integration qualification |
| Lean Arena | All193 official bodies evaluated; independent metadata-aware transport and full comparison added | Official reference122 accept/71 reject | Independent generated corpus execution pending | Host limits separated from kernel fuel | Not yet independently qualified |
| Formal invariants | Composite metadata preservation, local-cache restoration/eligibility and budget-cap lemmas | Native axiom gate passes | Proofs intentionally outside portable executable closure | Not applicable | Global DAG/substitution/DefEq/admission soundness remains open |

## Latest matched native measurements

Run39512106401 uses the same pinned toolchain, fuel and correctness guards.
DAG time includes public validation/decode. Input construction is separate.
These are two A-B-B-A observations per variant; no generalized improvement follows.

| Complete public operation | Fixture / calls | Original ms | DAG ms |
| --- | --- | --- | --- |
| Check | Metadata96 / 600 | 68 / 67 | 13 / 14 |
| Check | Zeta96 / 50 | 17 / 17 | 18 / 18 |
| Checked WHNF | Metadata96 / 300 | 34 / 34 | 7 / 8 |
| Checked WHNF | Zeta96 / 50 | 32 / 36 | 19 / 20 |
| Checked WHNF | Zeta192 / 20 | 44 / 56 | 25 / 26 |

Generated Node22 checked WHNF in the green269552f generated job also improves:
Zeta24 (two calls) original136.434/141.860ms vs DAG73.340/70.592ms;
peak RSS233,912/233,804KiB vs184,712/189,380KiB. Zeta48 (one call)
is110.821/117.433ms vs69.356/68.058ms. Ordinary zeta type checking still has
adapter overhead (depth24:59.389/63.765ms vs66.908/67.939ms).

The generated harness reports cold/warm full calls, construction, isolated-worker
peak RSS and post-GC heap. Earlier qualified numbers and adapter regressions are
retained below. Allocation, actual semantic cache hit/miss counts and trampoline
costs have not been fully instrumented. Do not infer them from GC event counts.

## Arena evidence and profile

The authenticated round-2026-09 archive has193 cases and SHA256
`98a69742b538296c5f413d0527dfeef8c4d1815fe64b12c8623cd33de63bee0d`.
Official run [39510753165](https://github.com/dwijayuda/pskernel/actions/runs/39510753165)
passed all122 historical good and71 historical bad cases, with positive/negative
controls and no exclusions or remaining timeouts. Only the metadata header was
adapted to the pinned4.35 commit; declaration-body bytes are hash-verified as
unchanged. This is not a fresh native4.35 export and is not independent-kernel
qualification.

The new host transport constructs direct DAG input, invokes the real complete
admission API once, and compares every supplied exported constant/constructor/
inductive/recursor field with the regenerated environment. Exported recursor
rules are never installed as trusted rules. Exact integers and duplicate keys,
invalid references, forged recursor counts/RHS and constructor metadata have
explicit controls. Unrepresented all-lists, oversized UInt32 hints and unsafe/
partial contract differences remain explicit outcomes. Projection type names
participate in dependency ordering. Blank records and non-LeanExport fvar/mvar
wire constructors are rejected; internal expression support is unaffected.

The comparison records every case, distinguishes kernel/metadata/transport
rejection from unsupported and host/kernel resource failures, and fails the full
gate if any case is unmatched. Node executes in a detached directory with empty
PATH; fuel remains4096. Host timeout60s, heap2GiB and two workers are reported
separately. Never turn an OOM/timeout into a semantic rejection or silently
remove the case.

## Next implementation obligations

Complete the operation-owned DAG WHNF state and function-position normalization
with exact cache-key, value, fuel and depth parity, then qualify its cache-heavy
complete-check performance. Cache eviction cannot be used to bound memory:
removing an existing hit can alter fixed-fuel acceptance. List lookup scalability
must be measured before broader migration.

Then migrate environment/local values and checker state to one owning arena,
followed by full delta, recursor/iota, projection, supported primitives, general
inference, lazy DefEq, universes, proof irrelevance and inductive admission.
Retain every established rejection and resource decision. Extend formal replay,
substitution and cache-ownership invariants; do not substitute test counts for
those obligations. Retire legacy adapters and duplicate research algorithms only
after replacement qualification. Keep the full193 independent report and final
Actions results visible throughout the remaining work.

## Historical evidence (superseded where the checkpoint above is newer)

## Execution evidence and corrections

- Commit 953de3067cf285f42ab74fa2cbde43b6ae977aba, run
  [39502809730](https://github.com/dwijayuda/pskernel/actions/runs/39502809730):
  native DAG, adversarial, fuel/depth, official Lean fixture and existing V2
  regressions passed. Authentic PSC1 source checking and JS/declaration/map
  generation passed. Generated runtime gate failed because its harness tried
  to access erased structure constructors; corrected to typed object records.
- Source audit found the JS expression comparator is curried. The older smoke
  harness and initial new harness treated a returned function as truthy.
  Corrected both-stage application, strict Boolean assertions and unequal-term
  sentinels are mandatory before treating JS semantic assertions as evidence.
- Commit 68508d13054d45bf6c244605511662245fc4209d factors one constant rule
  shared by original and DAG inference, preserving lookup/arity/safety/cache
  order. Native compilation of production source succeeded; the new benchmark
  target collided with Lean's global `measure` name. The target now uses a
  unique name. Run [39503690997](https://github.com/dwijayuda/pskernel/actions/runs/39503690997)
  is retained as failed evidence, not a passing qualification.
- Complete-check performance harnesses include validation and decoding, with
  A-B-B-A generated workers, cold and warm samples, construction, peak RSS and
  post-GC heap. Results remain pending. Native samples also compare official
  Lean on matched checked metadata/zeta terms; no generalized speedup claim.

## Current production integration slice

The paged Node/Entry, storage, smart constructors, replay validator and
collision-safe equality now have single owners under `Core/ExprV2`.
Scalar syntax and hash helpers have been extracted without semantic changes.
Research import modules forward to those owners. The production foundation
imports no Research module, recursive expression type or checker cache.
Decode remains a separately named transitional adapter.

Terminal checking and terminal WHNF operate on DAG nodes. Public DAG DefEq
fully checks both operands, applies the original entry resource guards, and
uses same-arena collision-safe structural equality for syntactic success.
The pair memo starts empty and is discarded per operation. A false syntax
result always falls back to full DefEq; it is never a negative DefEq verdict.
Composite checking, other reductions and declaration admission remain legacy.

Native run [39504184911](https://github.com/dwijayuda/pskernel/actions/runs/39504184911)
on 7ac92b1737504d01a56c14f0abc9aeeeed75a4f7 passed expanded exact check/WHNF/
identity fuel-depth parity, adversarial inputs, official comparison, existing
V2 regressions and the matched native performance harness. Its generated job
was still pending at this work-state update. The subsequent structural-equality
promotion requires new CI; this earlier result does not qualify later code.

| Native complete check fixture | Calls per phase | Original ms, A/A | DAG ms, B/B | Official Lean ms, first/last |
| --- | ---: | --- | --- | --- |
| Metadata, depth 32 | 1200 | 26 / 26 | 10 / 10 | 2 / 2 |
| Metadata, depth 96 | 600 | 67 / 72 | 13 / 15 | 3 / 2 |
| Metadata, depth 192 | 300 | 104 / 102 | 13 / 13 | 2 / 3 |
| Zeta, depth 32 | 100 | 6 / 5 | 7 / 7 | 2 / 3 |
| Zeta, depth 96 | 50 | 16 / 16 | 18 / 17 | 3 / 4 |
| Zeta, depth 192 | 20 | 22 / 23 | 22 / 23 | 3 / 2 |

DAG times include validation and decoding on every checked public call. Inputs
were preconstructed. The native clock is millisecond resolution; combined
construction was below that resolution. The metadata slice improves on these
fixtures, while zeta exhibits overhead or parity. These finite cases do not
establish a general kernel speedup or satisfy full migration acceptance.

Generated run 39504184911 has now also passed on 7ac92b1: authentic PSC1
checking of 1,173 declarations, TypeScript 7.0.2, JS/declarations/maps, real
positive/negative checks and admissions with PATH empty, and isolated Node22
A-B-B-A samples. This does not qualify the later foundation commit.

Generated metadata check samples (original vs DAG total milliseconds):
depth32/6 calls 217.115,215.529 vs 83.133,86.491;
depth96/4 calls 340.132,319.812 vs 77.781,80.440;
depth192/2 calls 363.929,391.873 vs 63.011,63.327.
At depth192, isolated peak RSS was 213,964–214,816 KiB original versus
140,424–140,588 KiB DAG; post-GC heaps were about19.23MB versus19.11MB.
DAG input construction cost was22.6–22.8ms for5 inputs versus0.708–0.710ms.
Generated zeta checks regressed: depth8/3calls90.463,94.854ms original versus
123.351,126.853ms DAG; depth24/2calls103.756,108.923 versus138.612,141.043;
depth48/1call101.532,95.461 versus117.685,123.007. The legacy fallback plus
input adapter is not qualified as a general replacement. Production default
V1 APIs retain the existing complete checker. Native/JS batch-throughput and
additional checked WHNF/DefEq measurements are being added; they do not erase
these observed regressions. Allocation counts and detailed cache counters
remain unmeasured.

### Consolidated foundation qualification (2026-10-20 UTC)

At implementation commit `713bd35a3959a4b7fb44cff3eb8c9857c84b2a6c`, both
[production DAG integration jobs](https://github.com/dwijayuda/pskernel/actions/runs/39505188175)
and all six [research jobs](https://github.com/dwijayuda/pskernel/actions/runs/39505188468)
passed. Authentic PSC1 checked 1,136 declarations in the complete SelfHost
closure. Generated TypeScript 7.0.2/Node 22.23.3 executed the complete kernel
and strict DAG assertions. The generated source was 5,138,980 bytes; smoke
peak RSS was 270,756 KiB and post-GC heap 36,843,824 bytes. These are whole
smoke-process observations, not an allocation bound or proof of soundness.
The corrected combined bridge passed its unequal-term sentinel and actual
result comparisons (1,315 declarations in that larger research closure).

The historical whole-JS and memory-probe harnesses also contained the curried
`psKernelExprEq(a,b)` truthiness bug. Their timing observations existed, but
those equality guards did not establish semantic equality. The integration
work now corrects both to `psKernelExprEq(a)(b)`, requires strict Booleans,
and checks an unequal sentinel before measurements. They must be rerun before
using their assertions as qualification evidence.

### Next transformation slice — qualification pending

The integration branch now includes one production generic DAG visitor for
multi-variable/reverse instantiation, abstraction, universe substitution, and
application spines. The bounded zero-budget behavior preserves the original
subtree. Memo keys include effective remaining depth and binder offset. The
actual default worker budget is capped by validated depth before constructing
recursive closures, avoiding expanded-tree fuel allocation on shared DAGs.
Native fixtures cover every expression family, partial-budget memo reuse,
forged graph data, and a 24-level shared graph without materializing its tree.
These additions are pending native and authentic PSC1/generated qualification;
the complete checker migration is still unfinished. The following integration
slice connects the canonical visitor to public checked zeta WHNF.

### Complete executable qualification expansion — pending CI

The original correctness workflow now runs on this integration branch and
derives the complete canonical source closure from imports, comparing it to
the reconstruction manifest instead of hardcoding 79. Exact Lean commit,
TypeScript 7.0.2 output, declarations, source-map structure, and detached Node
execution are checked. The generated .ps checker smoke now performs checking,
inference, beta/zeta/delta/iota, positive/negative DefEq, declaration admission,
ordinary and mutual inductives, cache-scope tests, and zero-fuel rejection.
Its previously vacuous curried equality assertions are fixed and sentinel-tested.
DirectJS is probed separately: known non-scalar/generic emitter limitations
are explicitly reported as unsupported, never as passing kernel execution.

### Checked zeta integration and local proof work — pending CI

The public DAG WHNF operation now calls the canonical DAG substitution visitor
for its terminal/metadata/zeta slice. Public and core WHNF keep separate exact
fuel and recursion-depth rules; unsupported reduction forms restart the original
operation with its original resources. Only newly appended result nodes are
decoded. The operation does not publish semantic cache state or carry a memo to
another command. Full beta/delta/recursor/projection/primitive migration remains.
DAG terminal-inference and reduction workers now delay recursive worker creation
until a branch needs it; this preserves numerical fuel and avoids allocating an
unused predecessor-fuel closure chain. No legacy substitution worker was changed.

Native proof files state conditional local metadata preservation for the six
composite entry builders, exact restoration of all seven scope-sensitive cache
fields, and fresh-counter/FVar-eligibility facts. These are pending proof-checking
in CI, not proofs of replay validity, substitution refinement, all cache uses,
DefEq, declaration admission or kernel soundness. No executable path imports them.

### Refreshed checkpoint (2026-10-21 Asia/Jakarta)

At `2760f486a0efc7e3631725c8f1c657fb97c3fafb`, native integration and the
original native correctness gate passed. PSC1 parsing failed on projection
from a parenthesized product expression in Transform.lean. The replacement
uses an ordinary let-bound record projection, without expanding the language
profile. The generated research bridge also encountered a Lean-download TLS
failure before compilation. Neither failure is reported as a passing gate.
The last fully green integration/research checkpoint remains
`69de396ec537c8130b87388ba8045859e443141b`. The 1,755 native transformation
oracle comparisons passed at `7ffd17f707225645c9aa2bc5282cbae2bcdbbee8` and
again at the following documentation/qualification checkpoint. Generated
transformation execution, the new checked zeta path, local proofs and expanded
canonical checker smoke still require successful CI on their implementation.

### Native zeta and local theorem evidence

Run [39509139906](https://github.com/dwijayuda/pskernel/actions/runs/39509139906)
passed native integration at `d0ad5dac3d0e057dec0bd5edd9ff4d797c0f8d77`,
including checked zeta fuel/depth parity, 1,755 transformation comparisons,
and all new local metadata/cache-scope theorem checks. The original native
correctness job in run39509139873 also passed. Generated and canonical .ps
qualification remain pending. Additional flat-pattern source fixes and strict
generated transformation tests are included next; they require their own CI.

### Complete Arena reference execution — pending CI

The new reference workflow evaluates every one of the 193 cases from the
SHA256-pinned round-2026-09 archive using official Lean at the exact 4.35 pin.
It records each verdict, original/adapted hashes, byte-identical declaration
body hashes, timeouts and driver errors. Only the historical first metadata
line is adapted; this is not a native 4.35 re-export or unchanged-envelope
qualification. No case, including performance cases, is excluded. Accept/reject
controls guard the oracle. This job establishes official reference coverage;
it explicitly does not establish PSKernel-Core corpus compatibility. A current
strict DAG transport with generated-recursors metadata comparison is required
for the independent checker. The older adapter's high fuel and dropped recursor
metadata are not reused.

Authentic PSC1 rejected the initially delayed recursive call form with
`structuralRecursionArity` in Terminal.lean. The supported form now binds the
one-argument recursive call inside the delayed lambda, then applies the local
function to context/arena/root. This retains the delayed computation without
changing the compiler, declared API staging, resources or semantic branches.
Application-spine reconstruction also matches its decreasing argument list at
the top level as required by PSC1 structural-recursion elaboration. These
source-profile corrections are pending authentic PSC1 validation.

The first complete Arena reference run39509681088 evaluated all193 cases:
120 accepted,71 rejected,2 official-harness timeouts, with both controls passing.
The timed-out cases were good/perf/magma-list-deep-n36.ndjson and
magma-list-pair-n21.ndjson. No cases were excluded. The host timeout originally
killed lake without reliably reaping its leanchecker child; the harness now
kills/reaps the isolated process group. The official-reference wall cap is
300 seconds with two workers so the two performance cases can be evaluated.
PSKernel's fuel4096 and its published resource policy are unchanged. Corpus
coverage is not called complete until all actual verdicts are observed.

### Direct beta-spine integration — pending qualification

The checked DAG WHNF worker now handles direct syntactic lambda heads using
C0's simultaneous reversed-argument substitution and remaining-spine rebuild.
Both original core calls retain their exact predecessor fuel/depth. New native
and generated tests include multi-binder reversal, partial/overapplication,
nested beta/zeta, low budgets, and a cache-sensitive case which explicitly
requires fallback. General function normalization still needs operation-owned
structural core caches; erasing those caches would change low-fuel outcomes.
The implementation remains partial and is not yet a full DAG-native checker.

### Transformation elaboration and redundant count removal — pending CI

The next authentic PSC1 error was an untyped match RHS in TransformLeaf
(`matchExpectedType`). Explicit result annotations now cover both such RHSs;
this uses the existing language profile. Default canonical transformations
now read exact cached depth directly instead of traversing the graph to compute
an expanded count that the worker immediately caps to depth. A native lemma
checks depth <= recursive node count and the corresponding cap equality. The
explicit bounded API and all checker fuel limits remain unchanged. Global
validated-arena correspondence and substitution refinement remain unproved;
conditional local metadata lemmas and finite parity tests do not imply them.

### Full reference corpus observed; independent replay gate added

Run [39510753165](https://github.com/dwijayuda/pskernel/actions/runs/39510753165)
on dd466701 evaluated all193 cases:122 accepted,71 rejected,zero timeouts,
both controls passed. This is official Lean reference evidence only. The
complete independent comparison gate now reconstructs the canonical .ps kernel,
compiles real TypeScript7.0.2/Node22, exercises adversarial transport controls,
and runs every adapted body in a detached process with PATH empty and kernel
fuel4096. The host limit is60 seconds/2GiB per case, explicitly separate from
kernel resources. Nonqualifying outcomes fail the full gate after writing all
results; unsupported inputs and resource limits are never counted as matches.
The adapter builds paged expressions directly and validates every supplied
exported constructor/recursor/Quot field against independently admitted data.
It does not install exported recursor bodies. Metadata-kind counts and actual
checker invocation are recorded. Noncanonical all-list metadata remains an
explicit transport limitation. General V1 admission still uses legacy internal
expressions, so a corpus pass would not establish a complete V2 migration.

The beta native build failure was a missing explicit Lake root registration,
not a semantic-test result; that registration is now included. Authentic PSC1
accepted the complete .lean source at dd466701. Its canonical/generated runtime
and the new beta/native proofs still require their own passing evidence.

### Generated transform harness ABI correction

Run [39510753173](https://github.com/dwijayuda/pskernel/actions/runs/39510753173)
checked all 1,225 source declarations with authentic PSC1 and built the complete
TypeScript 7.0.2 / JavaScript executable, declarations and source map. Execution
passed the preceding DAG/admission/negative checks, then the strict oracle-value
guard rejected the first bounded transform comparison because the host harness
under-applied a returned function. Erasure's actual ABI curries each function-value
arrow, while known declaration entries retain flat arguments. The seven affected
bounded-transform and raw-WHNF test calls now follow that ABI. The strict guard
remains; this correction has no kernel or fuel-policy effect and awaits runtime
qualification. Native Beta module registration was corrected in c29f418.
