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
chains) now has a direct node-reading candidate; composite inference, WHNF,
DefEq and admission still require migration. No completion or speedup claim
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
