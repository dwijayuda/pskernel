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
