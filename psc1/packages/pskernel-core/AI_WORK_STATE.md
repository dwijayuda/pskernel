# PSKernel-Core Expression V2 integration work state

Date: 2026-10-21 (Asia/Jakarta)
Status: **IN PROGRESS — NOT a finished Expression V2 checker**
Integration branch: `integration/psc1-pskernel-expr-v2-lean435-20261021`
Research parent: `research/psc1-pskernel-expr-v2-lean435-20261020`
Refreshed research HEAD: `c98be336e2e95dda998e4353dd791bdba5d8cb4f`
Toolchain: `leanprover/lean4:v4.35.0`
Exact Lean source: `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`

## Objective and trusted boundary

Finish the paged, sharing-aware expression architecture in the complete,
independent PSKernel-Core checker. The user's complete acceptance criteria
remain binding: native, official Lean differential, applicable full Arena,
PSC1 source and canonical PS, generated JS, unchanged resources/axioms,
whole-checker memory/performance, and final-commit CI.

All repository reads/writes and tests use connected GitHub and GitHub Actions.
No local checkout, local compilation, force update, release or publication.
No sorry/admit, unchecked proof assumptions, fuel increase, or excluded
difficult corpus cases. No claim that finite regressions prove soundness.

## Refreshed baseline evidence

The branch had not advanced past c98be336 when inspected. Its only difference
from dd1df299264a3b4e4a1eedc3a98852041043bc74 is documentation.

- [39494544496](https://github.com/dwijayuda/pskernel/actions/runs/39494544496):
  six Expression V2 research jobs passed.
- [39494159604](https://github.com/dwijayuda/pskernel/actions/runs/39494159604):
  both original native and PSC1 portability jobs passed.
- [39492950104](https://github.com/dwijayuda/pskernel/actions/runs/39492950104):
  combined generated checker/restricted V2 bridge passed.

The old generated production smoke only exercised helper operations.
The combined bridge checked real terms, but did not migrate the checker.

## Exact architectural findings

The original production closure is 79 files / 843,451 bytes at c98be336:
28 Admission files, 26 Checker, 10 Core, 5 Runtime, 5 API, 4 Environment,
and SelfHost. New closure counts must come from imports and the bootstrap
manifest, never an asserted count of 79.

Expression V2's prior dependency on Runtime/Acceleration/Cache imported the
legacy expression representation. Scalar syntax and hashing must be factored
out before production DAG modules can stand independently.

The existing V2 subset does not have the production resource contract.
Kernel fuel is a **recursive bound**, not an accumulated instruction count.
WHNF public/core entry ordering, recursion-depth guards, spine beta batching,
recursor callbacks and expression-derived substitution budgets must be kept.

All seven semantic caches are restored on local-scope exit; only the maximum
fresh-name counter survives. FVar-sensitive computations cannot be cached
across contexts. Same numeric IDs in sibling immutable arenas are unrelated.
A caller-supplied equality memo or raw arena is not trusted.

## Active implementation

1. Factor scalar types and hash helpers. Promote the one paged Node/Entry,
   storage, constructor and replay-validation implementation to Core/ExprV2.
   Research modules become forwarding imports where appropriate.
2. Add Core/ExprV2/Decode: one topological materialization per unique node,
   with paged decoded storage and physical sharing. No per-WHNF/DefEq import.
3. Add API/DagTypes, DagDeclaration and Dag: untrusted DAG commands for the
   existing expression checking and complete declaration request families.
   One public batch validates/reconstructs its graph once; each command uses
   the complete KernelContract-v1 API and its unchanged resource policy.
4. Implement the missing multi/reverse instantiation, abstraction,
   universe substitution and spine helpers with bounded legacy parity.
5. Strengthen generated JS tests to run real checking, admissions,
   negative outcomes, contexts and resource cases; derive closure counts.
6. Add native and generated DAG ingress regression, forged-data rejection,
   same-ID/different-arena cases, exact low-fuel parity, ordinary induction
   and official Lean comparisons.

**The DAG ingress is transitional. Terminal inference (including metadata
chains), terminal WHNF and checked same-arena identity now have direct
node-reading candidates; other composite inference, reductions, DefEq and
admission still require migration. No completion or speedup claim
follows from its existence or passing tests.**

## Milestone matrix

| Milestone | Implementation | Native correctness | PSC1 / PS / JS | Whole-checker performance | Status |
| --- | --- | --- | --- | --- | --- |
| Paged representation | Qualified research; production factoring underway | Baseline green | Baseline green | Microbenchmarks only | In progress |
| Single instantiate / lift / structural equality | Qualified research | Baseline green | Baseline green | Research measurements only | Not production checker |
| General transformations | New production prerequisites underway | Pending | Pending | Pending | In progress |
| Checked DAG input / complete API | New one-time input adapter underway | Pending | Pending | Pending | Transitional |
| Full DAG-native WHNF | Missing | Not qualified | Not qualified | Not measured | Incomplete |
| DAG-native inference and DefEq | Terminal/mdata inference candidate; full DefEq missing | Pending | Pending | Not measured | Incomplete |
| DAG-native inductive admission | Missing | Not qualified | Not qualified | Not measured | Incomplete |
| Complete integrated self-hosting | New full source closure must qualify | Pending | Pending | Pending | Incomplete |
| Lean Arena | Existing infrastructure audit underway | Full applicable run not established | Not established | Not measured | Incomplete |
| Formal invariants/metatheory | Existing semantics retained; no new soundness theorem | Not proved | Not applicable | Not applicable | Open |

## Next migration obligations

Preserve the existing control flow while moving expression operations to an
arena owned by checker state. Environment/local declarations and all semantic
caches must refer to that same arena. Missing full behavior includes lazy
delta, local-let unfolding, Quot reduction, Nat primitives, recursors with K
and structure conversion, projections, both function-eta directions,
structure eta, unit-like types, proof irrelevance and universe equivalence.

Do not replace these with the bounded beta/zeta research worker. Retain the
legacy complete checker only as a migration fallback/oracle until all
equivalent operations qualify, then retire obsolete implementations.

## Evidence discipline

Only record a new implementation as qualified after reading its actual
Actions result on the exact commit. Retain failed runs and diagnosis.
Benchmark the complete checked operations with conversions, construction,
memory and runtime overhead visible. An ingress adapter is expected to add
work; do not present representation microbenchmarks as complete-checker gains.

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
