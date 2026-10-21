# Diagnostic branch: authentic Arena logical-call tracing

Date: 2026-10-21 UTC
Branch: `research/psc1-arena-logical-20261021`
Runtime source baseline: **`e015839e0cdf29b1e4f2d4a750fed8956c0afe17`**
Active integration development remains on
`integration/psc1-pskernel-expr-v2-lean435-20261021`, most recently
`a256edb117ace146d1798f3d32cdeb488a45db84`.

This diagnostic branch changes only the profile harness/workflow and this state
record. No compiler, portable kernel, provider or runtime semantic source changes.
The qualified e015 native, generated and canonical provider jobs are recorded in
integration39565480601, correctness39565480292 and research39565480417; all terminal
PASS. The new containing diagnostic source and trace harness are **NOT RUN** until
their own Actions job completes. Trace collection cannot claim gate B or C.
Gate A remains the documented e015 scoped V1 developer provider.

## Why this diagnostic exists

The f483 structural-allocation profile39564831855 finished collection successfully:
stuck-prop completed with the expected rejection under unchanged limits, while
repeated-subproblem, church-numerals and init-prelude still timed out. Repeated-
subproblem now identifies psKernelExprHasFVar as a hot function, but the generated
trampoline hides its logical caller. We need that caller before changing cache
eligibility, admission validation or transform scanning.

The workflow first runs its existing authentic PSC1/canonical compilation,
detached controls, official reference, unprofiled cases and V8 profiles unchanged.
Only afterward it creates a separate instrumented `kernel.logical.mjs`.
A strict source guard accepts the reviewed TypeScript-erased trampoline, retaining
all generated function bodies unchanged. The parallel label stack records named
pending generators, including nested trampoline calls, without reading term payloads
or modifying semantic decisions. Existing source maps do not describe this copy.

Sampling uses at most 800 samples, 64 named frames and 16,384 inspected frames per
sample, every 4,096 resumes and at least 100ms apart. Synchronous append preserves
completed samples after a timeout kill. Frame counts are diagnostic samples, not
CPU accounting, kernel fuel or performance ratios. Anonymous frames are omitted;
truncated stacks and missing final records are explicit.

The original authenticated four-case bodies are replayed through the same complete
RunDag, transport and 4096 fuel. Host limits remain60s/2GiB and PATH is empty.
The same-source baseline report and exact body/header receipts are required.
The instrumented copy separately runs the complete existing positive/adversarial
replay controls before cases. Any rewrite mismatch, malformed trace, protocol
failure or contradictory completed outcome fails collection; timeouts remain
timeouts, never rejection or parity passes.

The generated original bundle, separate diagnostic bundle, complete records,
logical traces, V8 profiles and checksums are attached to the Actions artifact.
The production artifacts and all qualification results remain uninstrumented.

## Ready-to-execute continuation

Inspect this branch's exact HEAD and terminal
`.github/workflows/psc1-pskernel-arena435-profile.yml` job/log/artifact.
If the strict trampoline guard rejects TypeScript formatting, inspect the actual
emitted prefix in the artifact and fix only the diagnostic recognizer, keeping
a reviewed exact source identity. Do not relax it to accept arbitrary code.
If controls fail, classify an instrumentation/harness defect and correct it
before interpreting samples. If collection passes, correlate named ancestors
with the untouched source and authenticated per-case progress. Implement any
semantic optimization on the active integration branch with native, portable,
canonical/generated, formal-local and original unprofiled corpus qualification.

This is executed through connected GitHub tools and Linux GitHub Actions.
No local checkout, local CI, force push, main merge or npm publication is used.

## Historical integration state at runtime baseline

The following state file is preserved from e015's tree. Its pending wording
predates e015's terminal green jobs cited above and does not override this summary.

# PSKernel-Core Expression V2 integration work state

Date: 2026-10-21 (Asia/Jakarta; Actions timestamps use UTC)
Status: **IN PROGRESS — independent developer kernel; complete V2 and Arena gates remain open**
Integration branch: `integration/psc1-pskernel-expr-v2-lean435-20261021`
Lean: `leanprover/lean4:v4.35.0`, exact commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`
Generated path: authentic PSC1 → TypeScript `7.0.2` → Node `22`. Full-kernel DirectJS is unsupported.
Default kernel fuel: **4096**, unchanged. No new runtime axiom or trusted reduction path.



## 2026-10-21 07:56 UTC — allocation proof normalization correction

At candidate `f483e310efdda9dfcca47d42a731540dfe478aba`,
[integration 39564831824 / native job 119104503980](https://github.com/dwijayuda/pskernel/actions/runs/39564831824/job/119104503980)
is terminal **FAIL** in the new equality proof file. Complete checker compilation
and all preceding semantic, mutual, owner, inference, proof-irrelevance, Nat and
transformation regressions passed. The new 800-comparison / 21-hostile native
equality regression also passed. The universal theorems did not elaborate:
the simplifier left equivalent right-expression matcher auxiliaries unresolved.
This is a **proof-script defect**; no kernel decision mismatch was observed.
The later fifteen-worker proof command and native provider/benchmark steps
were **NOT RUN** in that failed job.

The correction explicitly cases the right expression in each equality proof
and finishes remaining definitional matcher equalities with reflexivity in the
fuel proofs. Frozen predecessor definitions, theorem statements, production
functions, required assertions and all CI gates are unchanged. Failed
elaboration's printed `sorryAx` dependencies are failure diagnostics, never
accepted proof receipts; the Lean process exited nonzero and blocked the job.
No admitted proof or new trusted runtime path is introduced.

Native correctness at f483e31 passed; other source/generated/canonical/research
and corpus jobs were still running when this correction was prepared. The
containing correction requires its own exact-SHA qualification. The last fully
green developer/provider checkpoint remains 854bdb9 above; f483e31 is not
qualified by the successful executable regression alone.

## 2026-10-21 07:38 UTC — qualified provider checkpoint; structural allocation candidate

**Last fully qualified native/portable/generated developer checkpoint:**
`854bdb9e0febf4e01fb5ce4b2cc8ea91f61287e4`, on the integration branch above.
Both jobs in [integration 39560050702](https://github.com/dwijayuda/pskernel/actions/runs/39560050702)
and both jobs in [correctness 39560050819](https://github.com/dwijayuda/pskernel/actions/runs/39560050819)
are terminal **PASS**. All six jobs in
[research 39560050764](https://github.com/dwijayuda/pskernel/actions/runs/39560050764)
are terminal **PASS**. This supersedes earlier pending entries for the corrected
Nat fixture, canonical execution and byte-input provider API.

| Exact source | Native | Portable source | Canonical .ps | Generated JS | Proof | Benchmark | Arena | Provider |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `854bdb9e0febf4e01fb5ce4b2cc8ea91f61287e4` | PASS | PASS | PASS source + runtime | PASS both routes | PASS existing gates | PASS selected workloads | FAIL: 24 host timeouts | PASS native + both JS routes |
| Containing allocation candidate | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |

The source-bound native job is
[119088851480](https://github.com/dwijayuda/pskernel/actions/runs/39560050702/job/119088851480);
the generated job is
[119088850976](https://github.com/dwijayuda/pskernel/actions/runs/39560050702/job/119088850976);
the canonical job is
[119088851453](https://github.com/dwijayuda/pskernel/actions/runs/39560050819/job/119088851453).
Required executions include the 280-case mutual-definition matrix, eight
official mutual fixtures and fresh-member budget sentinels; 1,008 inference-only
comparisons; 1,350 proof-irrelevance comparisons; 1,350 Nat comparisons and
192 direct Nat-stage comparisons, with 14 official decisions and one invalid
primitive; metadata, scanner, cache-scope and Nat-fuel proof gates; existing
binder/prefix/admission/failure-order controls; the five official provider
fixtures; and 24 detached provider CLI cases on native and both generated routes.
Each generated route additionally passed all eight private-byte-buffer API cases.
The generated Nat harness reports 2,429 assertions. Neither provider execution
delegates checker decisions to Lean; the generated processes run with PATH empty.

### Exact checkpoint artifacts

All manifests name source `854bdb9e0febf4e01fb5ce4b2cc8ea91f61287e4`.
A checksum is an integrity receipt, not a proof of a verdict.

| Artifact | Download | Uploaded ZIP SHA-256 |
| --- | --- | --- |
| Linux native executable and manifest | [12327502114](https://github.com/dwijayuda/pskernel/actions/runs/39560050702/artifacts/12327502114) | `5763471acc85b564deac16046611cb43c646359a7838fd7bb3ca3008969ccdf6` |
| Complete .lean-generated JS provider, TS, declarations and map | [12328068763](https://github.com/dwijayuda/pskernel/actions/runs/39560050702/artifacts/12328068763) | `4e23b676ed5edc6eb0cc1122037237d0dbafd05dc1269d2d95fc24b5401733c6` |
| Complete canonical source and generated provider | [12328716432](https://github.com/dwijayuda/pskernel/actions/runs/39560050819/artifacts/12328716432) | `d92c13f9bdaa0bf3ff04f7e991aee9f912f0ffd6c5c5047395a9c0cd333b831a` |

Native executable SHA-256:
`562d95ba7b56f9b905b124453f61295902f3d418831322a83c9af2738594cc4d`.
Executable-preserving tar:
`2ad0ed91a03feb9fa46d1485b10cd016b60227b32ce41eb26ea11455912d558c`.
Lean-derived JS:
`3ea6e3b59470fdef9363de2c0f0ea7256a13a1fe65fa9dfe4a068cb8f45476e2`.
Canonical-derived JS:
`d55b36f01cf7581d8eea49d4b5d87583207ff79e084d2f1ee1ae1126107d97f0`.
Canonical source tar:
`3939859c26b5d9ab8fd63845e0c24b02cd420afe75d2fe87b94cb377064fadee`.
Both routes produce the same TS source and declarations:
`2073ab6638edee59e8b658d5404a9f93d37a638ba73bbb9234195bc167411fa0`
and `155b391e4b1b9070e2450e4b76c43c22b24c0f0d86eef6440b4ecd4969c01af2`.
Map hashes are preserved in the manifests. Artifacts have the workflow's
30-day retention; reproducible source and recipes remain committed.

### Corpus result and changed diagnosis

[Full Arena 39560050730 / job 119089611991](https://github.com/dwijayuda/pskernel/actions/runs/39560050730/job/119089611991)
is terminal **FAIL qualification** at the same source: all 193 cases evaluated,
167 matching outcomes (103 acceptances, 56 kernel rejections, one metadata and
seven transport rejections), two separately classified unsafe/partial safety
agreements, and 24 host timeouts. The official reference job
[119088851272](https://github.com/dwijayuda/pskernel/actions/runs/39560050730/job/119088851272)
passed. No timeout is a kernel rejection. Result artifact
[12329155162](https://github.com/dwijayuda/pskernel/actions/runs/39560050730/artifacts/12329155162),
zip SHA-256 `7a49839c167de33bfb80a715c93212333d328aa02234fed32e41670f0d713248`.

The preceding `54ea3d428d85ba2936a037a5d9decdcab1593990` and
`753b30cab254f8b85fa3da4815121c32c484f5e7` full comparisons also ended with the
same 24 host timeouts. The cache-eligibility reorder did not resolve a single
full case. The authentic four-case profile at 54ea3d4 also timed out in all
unprofiled/profiled pairs; its collection success does not qualify the cases.
The source-bound profile and sampled RSS receipts are appended to
[PERFORMANCE_2026-10-21.md](PERFORMANCE_2026-10-21.md).

The containing commit changes only the placement of recursive aliases inside
existing argument lambdas in both structural equality workers and all fifteen
identified eager fuel workers. This prevents partial application from eagerly
constructing recursive function chains or the equality worker for an entire
shared subtree before its other input is examined. No fuel value, recursive
argument, callback placement, error branch, primitive truncation behavior or
public/staged type is changed. Frozen definitions from 854bdb9 and universal
local function-equivalence statements are added in
`test/PsKernelExprEqualityProofs.lean` and `test/PsKernelKnotFuelProofs.lean`.
They require actual Lean checking and the existing axiom audit. These are
replacement theorems using common imported helpers, not global soundness or
allocation-bound proofs.

Native tests add 800 frozen equality comparisons and 21 hostile early mismatches
against a 65-node shared expression. Both generated routes require the same
21 hostile controls plus two staged-ABI controls. The frozen eager oracle is
never evaluated on the exponential unfolded tree. All previous gates remain.
The modified helpers serve V1 as well as DAG users: new same-revision V1/DAG
numbers cannot be advertised as before/after speedups against original 854bdb9.

### Remaining critical path

1. Qualify the containing allocation candidate at its exact SHA: all 15 fuel
   theorems, four expression-equality theorems, native/portable/canonical/generated
   execution, provider controls, whole-operation benchmarks and all 193 cases.
   No allocation or corpus speedup is claimed before those runs finish.
2. Diagnose any remaining authentic timeouts from actual call behavior. Keep
   fuel 4096 and Arena host 60 seconds / 2 GiB; recursive free-variable/node-count
   scans remain. Preserve historical artifacts for a same-run before/after
   comparison if a timed-out whole check begins to finish.
3. The next DAG stage is the ordered general lazy-delta loop, with independent
   unfolding/failure caches, exact hints/universe selection, rightmost-first
   same-definition arguments and fixed callback budgets. It is being prepared
   with direct-stage and official regressions; it is not in this source yet.
4. Four RunDag whole-operation fallback sites remain. Residual DefEq, general
   recursor/iota, broader inference/WHNF and inductive admission still require
   migration. V1 remains the default/reference and provider selection.
   No full V2, global soundness or full Lean Arena claim is made.

The usable developer provider scope at 854bdb9 is qualified as documented in
[PROVIDER.md](PROVIDER.md); unsupported wire features are explicit refusals.
The full V2 architecture and full-corpus gates remain open. No merge or package
publication has occurred. Work is performed only through connected GitHub and
Linux Actions. Agent-side Git object creation did not return a receipt and was
stopped after 610 seconds; no successful mutation was inferred from that call.
All branch updates continue through one writer with a fresh expected SHA.

## 2026-10-21 07:08 UTC — generated predecessor harness ABI correction

Source `753b30cab254f8b85fa3da4815121c32c484f5e7` has terminal **PASS**
in native integration
[39558404780 / job 119083557519](https://github.com/dwijayuda/pskernel/actions/runs/39558404780/job/119083557519),
native correctness, and all six research jobs. Native integration includes the
1,350 Nat comparisons, 192 direct-stage comparisons, 14 official decisions and
one invalid primitive, the preserved mutual-definition/owner controls, local
proofs, official provider fixtures and 24 detached native provider cases.

Its generated integration job
[119083557294](https://github.com/dwijayuda/pskernel/actions/runs/39558404780/job/119083557294)
is terminal **FAIL**, at `exact-syntactic-predecessor` in the new Nat smoke.
The corrected warm-cache tests passed; the failure is a separate **harness ABI
mismatch**: `psKernelExprEqual` is exported as a staged function, and this
single assertion called `psKernelExprEqual(left, right)` instead of
`psKernelExprEqual(left)(right)`. The established DAG smoke already uses the
staged call. Native equality for these same predecessor expressions passed.

This correction changes only that invocation and this receipt. It preserves
the exact syntactic equality assertion, all fixture/count/owner checks and
all production code. Generated provider/API and benchmark steps after the
failed Nat step were **NOT RUN**. The canonical source graph has passed its
independent check; canonical generated execution and full Arena were still
in progress at this receipt. Fresh terminal CI is required for the containing
revision; no earlier native or source pass substitutes for it.

| Exact source | Native | Portable source | Canonical .ps | Generated JS | Proof | Benchmark | Arena | Provider |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `753b30cab254f8b85fa3da4815121c32c484f5e7` | PASS | PASS | PASS source | FAIL .lean-generated; canonical runtime IN PROGRESS | PASS | NOT RUN | IN PROGRESS | PASS native; generated NOT RUN |
| Containing ABI-fixture revision | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |

The preceding `e1b4deb214c3088e64a18f8b15148c7a15be2924` full Arena run
[39554691941 / job 119072275837](https://github.com/dwijayuda/pskernel/actions/runs/39554691941/job/119072275837)
is now terminal **FAIL qualification**: all 193 cases evaluated, 167 matching
outcomes (103 acceptances, 56 kernel rejections, one metadata rejection and
seven transport rejections), two separately classified unsafe/partial safety
agreements, and the same 24 host timeouts. Its artifact is
[12327340227](https://github.com/dwijayuda/pskernel/actions/runs/39554691941/artifacts/12327340227),
zip SHA-256 `3d584f7d918155b1d7eae63573e7398f0ad594688af5ba836f8f69f1a0434f33`.
Earlier “IN PROGRESS” entries for that run below are superseded. The candidate
cache-predicate optimization still needs its own completed Arena/profile results.

## 2026-10-21 06:54 UTC — Nat cache fixture correction

At source `54ea3d428d85ba2936a037a5d9decdcab1593990`, native integration
[39557631971 / job 119081025510](https://github.com/dwijayuda/pskernel/actions/runs/39557631971/job/119081025510)
compiled the new source and ran the existing regressions successfully. The Nat
test reached `nonprop-inference-state-survives-nat-continuation` after its
1,350-case and 192-case loop count checks, then **FAILED** that assertion.
The remaining native proof/provider/benchmark steps were not run in that job.

Classification: **fixture error**, not a demonstrated kernel decision mismatch.
The fixture asked literal operands to populate public WHNF caches, but both
`Checker/Reduction/Whnf.lean` and `Checker/ExprV2/Whnf.lean` deliberately return
literal operands immediately without cache publication. The corrected native and
JS warm fixture uses `Nat.add (Nat.add 1 0) (Nat.add 2 0)` so both immediate
operands exercise actual nonterminal public WHNF publication. The original
simple-add expression remains unchanged for the exact discarded-predecessor
arena-size sentinel. V1 warm-state inputs are changed to the same nested term.

All 1,350 differential fixtures, 192 direct-stage fixtures, official fixtures,
warm guard checks, original-pair assertions and both operand-cache assertions
remain required. No production function, budget, proof statement or acceptance
condition changes in this correction. The containing fixture revision requires
fresh terminal CI; the failed parent is not a qualified milestone. Its native
correctness and official Arena reference passed, while generated/canonical and
full comparison jobs were still running at this receipt.

## 2026-10-21 06:46 UTC — canonical parent PASS; ordered DAG Nat candidate

The immediately preceding complete source `e1b4deb214c3088e64a18f8b15148c7a15be2924`
now has terminal **PASS** in both integration jobs, both correctness jobs and all
six research jobs. Canonical job 119071611610 in
[39554691912](https://github.com/dwijayuda/pskernel/actions/runs/39554691912)
completed independent source-graph reconstruction/checking, generated runtime,
all original DAG regressions, 1,008 inference-only comparisons, 1,350
proof-irrelevance comparisons / 2,000 assertions, large-numeral controls and
the 24 detached provider cases. Complete-kernel DirectJS remains explicitly
UNSUPPORTED. Canonical artifact
[12325868919](https://github.com/dwijayuda/pskernel/actions/runs/39554691912/artifacts/12325868919)
zip SHA-256 is `5123ace515ac90fee4f5482519ff51e7d5b53b8193c84167b4243fdaa7ad2fed`;
canonical JS is `180b441eb8067136fb3037a0940fa93233c99b22b8d9364dcf14cd8c259031b4`;
complete source tar is `7d2a9c8495d7c5f552ed833d5d6cc46e4b43bede4d1d9ab50941e1b4ccdb8e6c`.
The earlier 06:38 “IN PROGRESS” canonical row below is historical and superseded.

| Exact source | Native | Portable .lean | Canonical .ps | Generated JS | Proof | Benchmark | Arena | Provider |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `e1b4deb214c3088e64a18f8b15148c7a15be2924` | PASS | PASS | PASS | PASS both source routes | PASS | PASS selected controls | IN PROGRESS | PASS native and both JS routes, CLI 24 each |
| `9dfcbeff351157ae41572c7a891bc89c543777e1` | NOT RUN separately | NOT RUN separately | NOT RUN separately | NOT RUN separately | NOT RUN separately | NOT RUN separately | NOT RUN separately | NOT RUN separately |
| Containing Nat/documentation revision | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |

The bounded cache-policy/provider-byte ownership changes are retained in
`9dfcbeff351157ae41572c7a891bc89c543777e1`; they will be tested together with this
child revision, not represented as separately tested. This child adds:

- `Checker/ExprV2/DefEq/LazyNat.lean`: exact lazy-entry fuel guard, syntactic
  zero/predecessor handling, original eager/open-expression decision and ordered
  left/right primitive reduction, using the existing owning Nat/WHNF machinery.
  General definition selection still returns outer `none`.
- A non-proposition continuation in the one proof-irrelevance stage, preserving
  its old standalone API. The single DefEq owner supplies fixed predecessor-fuel
  callbacks and publishes only the original requested success pair. Both existing
  compatibility/local-context guards remain unchanged.
- Native and generated 1,350-case DefEq matrices plus 192 direct lazy-stage
  comparisons, 14 official positive/negative decision fixtures and one invalid
  primitive argument. Cold/warm entry guards, typed open locals, numeral/resource
  errors, same-batch checked Nat admission and original-pair/cache state are
  mandatory. An unmatched predecessor candidate does not escape in the arena.
- Local Nat fuel-entry and unmatched-owner lemmas in the retained native proof
  gate. No theorem, old assertion or failure precedence is weakened.
- Updated 4.35 architecture/ownership documentation, a four-site fallback
  inventory, artifact invocation instructions and the source-specific performance
  report `PERFORMANCE_2026-10-21.md`.

The containing revision has not yet executed. Required Actions must reach their
terminal status, including the existing controls and new Nat/API cases. A runtime
ABI or fixture failure blocks qualification and must be repaired without lowering
the assertions. Full V2 remains incomplete: general lazy delta/projection/final
DefEq rules, recursor/iota/Quot and inductive admission still need migration;
boundary decoding and four whole-operation fallback sites remain. All 193 Arena
records must still be evaluated with the exact unchanged resource policy.

## 2026-10-21 06:38 UTC — qualified parent and next source checkpoint

The branch reached **same-source native and generated integration PASS** at
`e1b4deb214c3088e64a18f8b15148c7a15be2924` before the following changes were layered.
Integration [39554691928](https://github.com/dwijayuda/pskernel/actions/runs/39554691928)
finished both jobs successfully: native 119071612176 and generated 119071611694.
The native job checked the retained metadata/cache/fuel proofs, the 280-case mutual
admission matrix and its official fixtures, the new 1,350-case proof-irrelevance
matrix, and the official provider batch (five cases, four accepted declarations,
`doCheck=true`). Native and generated providers each passed all 24 detached CLI
cases with PATH empty. Generated proof irrelevance passed 2,000 assertions.

| Exact source | Native | Portable .lean | Canonical .ps runtime | Generated .lean JS | Proof | Benchmark | Arena | Provider |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `e1b4deb214c3088e64a18f8b15148c7a15be2924` | PASS | PASS | IN PROGRESS | PASS | PASS | PASS | IN PROGRESS | PASS native/Lean-generated; canonical IN PROGRESS |
| Containing revision after cache/provider changes | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN |

Correctness run [39554691912](https://github.com/dwijayuda/pskernel/actions/runs/39554691912)
has native PASS; job 119071611610 passed the complete independent canonical-source
check and compilation and is still executing its generated regression steps at
this receipt. Research run [39554691860](https://github.com/dwijayuda/pskernel/actions/runs/39554691860)
finished all six jobs PASS. Full Arena [39554691941](https://github.com/dwijayuda/pskernel/actions/runs/39554691941)
and authentic diagnostics [39554691896](https://github.com/dwijayuda/pskernel/actions/runs/39554691896)
are still running. These are observed statuses, not inherited qualification of
this containing revision; inspect terminal jobs before promoting it.

New bounded changes awaiting their own CI:

- Inference cache eligibility rejects literals and checked application/binder
  kinds before traversing their subtrees. It returns the exact old Boolean policy;
  a frozen proof-only reference and universal equivalence/extensionality theorems
  are added to the existing cache-scope gate. No fuel, depth, cache lookup or
  publication rule changes. V1 remains a separately selectable semantic reference.
- The generated provider snapshots a bounded caller-owned byte view before UTF-8
  validation and decoding, so concurrent writes through shared backing storage
  cannot change the validated input afterward. Eight detached direct API tests
  cover ordinary/shared buffers, offset views, invalid UTF-8, invalid Unicode
  strings/escapes and fresh sessions. The 24 CLI cases remain mandatory.

Qualified parent artifact receipts:

- Native artifact [12325206307](https://github.com/dwijayuda/pskernel/actions/runs/39554691928/artifacts/12325206307),
  zip SHA-256 `cafece4a3513a5aa8b67dee9af2be7fbce641afff98b0d6bdad54704e9a3d86e`;
  executable `ff48ffb0dbf2ac0d523220d270a48417a77909e9ee800c8199b17f3d08a56be2`;
  native tar `df64a133f1ed0200c75664bb6571b3068c624bb25841c9bc41ece4ff736a02b1`.
- Generated artifact [12325479399](https://github.com/dwijayuda/pskernel/actions/runs/39554691928/artifacts/12325479399),
  zip SHA-256 `4b088c19a837a3ce38cc1980c579d60f166b0ae6ef3c0ab6fcf564d87e5dcee3`;
  `kernel.js` (5,942,214 bytes) SHA-256
  `13fac713ab3db66dd34f707d47e74bf445055adf1303fc5371782c690228ee28`.
  Its manifest also binds readable TypeScript, declarations, map source files,
  provider/codec dependencies and README. Integrity receipts are not proof terms.

The complete earlier-source Arena run [39552920736](https://github.com/dwijayuda/pskernel/actions/runs/39552920736)
at `e2226eafee06d872f536667e449883d0eafbef5f` finished **FAIL qualification**:
193 evaluated, 167 matching outcomes (103 admissions, 56 kernel refusals, one
metadata refusal, seven transport refusals), two explicitly classified
unsafe/partial safety-contract agreements and the same 24 host timeouts.
No timeout was resolved or newly introduced relative to the previous recorded
24-case set. Its official reference passed 122 acceptances / 71 rejections /
zero timeouts. Comparison artifact 12325647052 has zip SHA-256
`07f3603ffef2a5df008307bcba291f89c26ed92e47cc6164e6cbdcf38d14d6b5`.

Authentic diagnostic run [39552920831](https://github.com/dwijayuda/pskernel/actions/runs/39552920831)
at that same older source collected four original cases, all still timeout both
unprofiled and profiled under 60 seconds / 2 GiB / fuel 4096. Kernel entry occurred
after 192 ms (repeated-subproblem), 179 ms (Church), 1,915 ms (Init) and 341 ms
(stuck-Prop projection). Named V1 HasFVar frames dominate the repeated-subproblem
profile; V1 recursor/WHNF/DefEq and runtime generator/WeakMap traffic dominate the
other profiles. The profile does not distinguish the HasFVar logical callers.
Removing redundant inference eligibility scans is therefore one measured-mechanism
candidate, not a claimed timeout solution. Profiled VmHWM samples are lower bounds:
343,456 / 529,800 / 1,048,248 / 513,056 KiB in that order. No heap-exhaustion
conclusion follows. Diagnostic artifact 12324932888 zip SHA-256:
`a148d87d408981df3ce0f16f717feef8d3386e363a9941ee4cd7420929a836ba`.

Next executable gate: run the containing source through native/generated
integration, canonical .ps correctness, six research jobs, full 193 Arena and the
four authentic profile cases. Compare complete outcomes before making performance
claims. If timeouts remain, attribute the remaining V1 recursor/WHNF scans rather
than repeatedly tuning this same cache predicate. Full V2 and full Arena gates
remain open; four whole-operation fallback sites and boundary decoding remain.

## Evidence identity and history

This file is the current summary. [The complete earlier work-state](history/AI_WORK_STATE_2026-10-21_BEFORE_PROVIDER.md) is retained verbatim; its historical “pending” sections do not override the receipts below. A manifest or an earlier green source does not qualify a later commit. Final qualification must use terminal Actions results for the exact source SHA.

## Implementation checkpoint being qualified

This revision adds the default-fuel native/generated canonical-admissions provider and deployable artifacts, advances the one DAG DefEq owner through proof irrelevance, threads same-batch declaration IDs into public DAG DefEq, and introduces authentic Arena timeout profiling. The unchanged original checker remains selectable and remains the provider's declared checked algorithm. The new DAG slice does not make V2 the default.

The retained implementation commits are `2df356a48e92a1fa46e59306f913985a83db0f92` (authentic Arena profiles), `ce7a92d8f7206fd05dba33a89930afa4ddb51fef` (DAG proof irrelevance with 1,350 native/generated comparisons), and the containing provider/integration commit. These commits are source identities, not test receipts.

The foundation commit is `0987be5a059fc6698541a5d376cf98c814b6fd80`: exact extraction of the existing wire constructors into a dependency without prelude loading or resource mutation; complete legacy package dependency/integrity maintenance; and source-bound SHA-256 manifests including source-map source files. Native executables are packaged in a tarball to preserve execute permissions. Canonical artifacts include the complete generated .ps workspace.

The provider is implemented in `host/kernel-provider/KernelProviderMain.lean` and `scripts/pskernel-canonical-provider.mjs`, documented in `PROVIDER.md`, and tested by `scripts/pskernel-provider-smoke.mjs`. It starts from an empty checked session and returns no partial environment. The 24 process cases copy the executable/runtime closure into a fresh detached directory and run with PATH empty; process failure or timeout is never a semantic rejection. `test/PsKernelProviderOfficial.lean` checks the exact valid four-declaration batch and four semantic negatives through official Lean with `doCheck=true`. Unknown transport fields (including unsafe/recursor/environment metadata) are declined; missing required fields and invalid numeric encodings are malformed. The transport scope is safe regular definitions, theorems and checked inductive groups.

**New-source qualification is pending terminal CI for the containing integration SHA.** Older PASS rows below are source-specific. The new native and generated proof-irrelevance matrices, strict provider negative tests, canonical full-closure checks, local proof gates, original regressions, full comparison and authentic diagnostic profiles must execute before their respective readiness claims are promoted.

The new profiling workflow is diagnostic only: it preserves original authenticated bodies, default fuel 4096 and the generated host limit of 60 seconds / 2 GiB. Producing a profile or a diagnostic artifact never qualifies an Arena case.

### Execution-tool interruption and recovery

Child-agent GitHub tree writes twice failed to return receipts after approximately 1,013 and 733 seconds. No branch update was attempted by those calls. The calls were interrupted, the complete source was transferred to the parent, and parent-owned GitHub writes returned tree/commit receipts. All repository work remains GitHub-only; no local checkout, build or test was substituted. Future writes use the parent tool path and fresh non-force expected-SHA updates.

## Guard and transport correction after 8f09068

At exact `8f09068526b843edcf0966db1c1c1211eddae31c`, [native integration job 119068266604](https://github.com/dwijayuda/pskernel/actions/runs/39553651256/job/119068266604) compiled all targets and passed the original DAG matrices, inference-only regressions, transformations, and the new **1,350 proof-irrelevance comparisons plus eight official positive pairs and one invalid-input control**. It then **FAILED** the retained theorem `dag_quick_defeq_depth_error_precedes_syntax` in PsKernelCacheScopeProofs.lean:197.

The theorem exposed an actual compatibility-wrapper ordering defect: the new unsupported external-local branch could hide an already-exhausted scalar depth guard. The containing revision restores that guard before the compatibility fallback. The original theorem is retained unchanged, with additional native/generated external-local depth sentinels. The guard computes no published context; the existing owning worker still enters depth exactly once.

The Unicode transport audit found two lossy decoding behaviors: Node's ordinary UTF-8 string decoding replaces invalid byte sequences, while the pinned Lean JSON parser replaces unpaired Unicode escape surrogates. Both providers now reject malformed UTF-8 and unpaired surrogate escapes before conversion. A linear lexical guard preserves valid surrogate pairs, literal backslash-u text and actual U+FFFD. Six new process controls exercise three malformed and three valid forms, bringing the detached provider suite to 24 cases. This changes host transport validation, not kernel semantics or resource policy.

Native correctness [119068267673](https://github.com/dwijayuda/pskernel/actions/runs/39553651416/job/119068267673) passed at 8f09068. Its official Arena reference [119068266675](https://github.com/dwijayuda/pskernel/actions/runs/39553651194/job/119068266675) passed all 193 cases (122 accepted, 71 rejected, zero timeouts). Generated/full Arena and canonical integration were still running at this update. The old e222 generated integration API reported the proof-irrelevance and 16-case provider steps successful; that older protocol lacks the new strict-binder/Unicode controls and is not promoted.

The in-progress generated job log exposed an early 2.12-MB prefix after later steps had advanced. Successful per-assertion `PSC1_DAG_PASS` console lines are now filtered after `tee`; the complete assertion output remains in the uploaded log, all tests and required markers still execute, and errors plus aggregate receipts remain visible. No test omission or pass inference is introduced.

## First integrated execution receipt: e2226ea

At exact `e2226eafee06d872f536667e449883d0eafbef5f`, [native correctness job 119065961654](https://github.com/dwijayuda/pskernel/actions/runs/39552920733/job/119065961654) passed. The production DAG modules, including the new CheckCore and proof-irrelevance continuation, compiled. Authentic PSC1 source checking in integration job 119065962179 also passed before generated compilation began.

[Native integration job 119065961963](https://github.com/dwijayuda/pskernel/actions/runs/39552920804/job/119065961963) **FAILED compilation** on two layout defects: multiline host return-constructor arguments at KernelProviderMain.lean:106 and a multiline official-axiom fixture record at PsKernelExprV2ProofIrrelevanceRegression.lean:143. The containing revision fixes the layout without changing semantic assertions. Provider review also found inherited-property binder tags in the shared wire decoder; explicit own-property membership and native/generated refusal cases for `constructor` and `__proto__` now close that transport hole.

[Research WHNF job 119065962045](https://github.com/dwijayuda/pskernel/actions/runs/39552920726/job/119065962045) failed before source compilation because the pinned Lean archive download reported TLS error 35. GitHub refused a targeted retry while the containing workflow was running (403: workflow already running). The containing revision installs the same pinned toolchain with three bounded download/install attempts, verifies its exact commit, and still runs every original gate. No test or toolchain pin was relaxed.

[Official Arena job 119065961893](https://github.com/dwijayuda/pskernel/actions/runs/39552920736/job/119065961893) passed all 193 cases: 122 accepted, 71 rejected, zero timeouts; generated comparison and authentic diagnostics were still in progress at this source update. This is an official reference result, not independent generated parity.

## Verified starting checkpoint

The branch was fetched at `49a5df0820216db35c3cbf562172b754b82a03b1`, three commits after the earlier green `38dfe75658a1d723b993904a8d510fb449e6bba0`. The material changes were the ordered DAG DefEq prefix, unsafe/partial mutual admission with fresh per-member owners, and a native test record-layout correction. No newer valid work was reverted.

At `56559c794a93e828cb89ded1b0ed535f93570b69`, [generated integration 39539663203](https://github.com/dwijayuda/pskernel/actions/runs/39539663203/job/119024254755), [both correctness jobs 39539663174](https://github.com/dwijayuda/pskernel/actions/runs/39539663174), and [all six research jobs 39539663281](https://github.com/dwijayuda/pskernel/actions/runs/39539663281) passed. The native integration job failed to parse a test fixture at line 4227; this was a fixture syntax defect, not a passing native qualification. The canonical gate reconstructed **120 modules**, audited **163 portable modules across two roots**, independently checked and compiled the complete .ps closure, and executed its real checker with PATH empty.

At `49a5df0820216db35c3cbf562172b754b82a03b1`, [native integration job 119045258568](https://github.com/dwijayuda/pskernel/actions/runs/39546338992/job/119045258568) passed the full native matrix, including all 280 mutual cases, eight checked official mutual fixtures, fresh-member sentinels, binder/prefix/unsafe/theorem rules, local proofs and benchmarks. The corrected native fixture is the only source difference from 56559c7.

Both jobs in [integration run 39546338992](https://github.com/dwijayuda/pskernel/actions/runs/39546338992) are now **terminal PASS at the same 49a5df0 SHA**. Generated execution passed all semantic markers, 1,008 inference-only comparisons, 128 guarded operation observations, 24 admission observations, strict whole-executable checks and all six profiles. The compiler emitted 5,921,796 bytes of JavaScript plus declarations and maps. Native and generated mutual-definition qualification is no longer pending.

| Exact SHA | Native integration | Authentic portable .lean | Canonical .ps | Generated JS | Local proofs | Full integration benchmarks | Full Arena | New provider |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `56559c794a93e828cb89ded1b0ed535f93570b69` | FAIL (fixture syntax) | PASS | PASS | PASS | NOT RUN (blocked native job) | NOT RUN (native); PASS (JS) | FAIL (24 timeouts) | NOT RUN |
| `49a5df0820216db35c3cbf562172b754b82a03b1` | PASS | PASS | NOT RUN | PASS | PASS | PASS | NOT RUN | NOT RUN |

The 49a5df0 fixture-only commit did not trigger canonical, correctness, research or Arena workflows. Their earlier green results are recorded for their own SHAs, not inherited. The next implementation push explicitly re-runs every required gate.


## Full Arena remains incomplete

[Latest completed full comparison 39539663267](https://github.com/dwijayuda/pskernel/actions/runs/39539663267) at `56559c7` evaluated all **193** cases:

| Recorded outcome | Cases |
| --- | ---: |
| Matched kernel acceptance | 103 |
| Matched kernel rejection | 56 |
| Matched metadata rejection | 1 |
| Matched transport rejection | 7 |
| Explicit unsafe/partial safety-contract agreement | 2 |
| Host timeout (60 seconds, 2 GiB) | 24 |
| Total | 193 |

The timeout set contains **19 official acceptances and five official rejections**. All 24 timeouts reached the public RunDag kernel-admission boundary; snapshots do not distinguish validation, decoding and admission internals. Official Lean's corresponding reference job passed **122 accepted / 71 rejected / zero timeouts**. Body bytes remain authenticated with the historical header adapted to the 4.35 pin. The independent gate correctly failed. Neither the 167 matching outcomes nor the two contract agreements mean 169 independently admitted proofs.

The recorded timeout set is preserved by case number and exact archive entry:

| Case | Archive entry | Official outcome |
| ---: | --- | --- |
| 14 | `bugs/proj-of-stuck-prop.ndjson` | rejected |
| 15 | `bugs/proj-of-subst-prop.ndjson` | rejected |
| 17 | `bugs/rec-missing-ih.ndjson` | rejected |
| 18 | `bugs/rec-of-subst-prop.ndjson` | rejected |
| 24 | `perf/refute-cheap-last.ndjson` | rejected |
| 73 | `init-prelude.ndjson` | accepted |
| 79 | `perf/app-lam.ndjson` | accepted |
| 80 | `perf/args-before-unfold.ndjson` | accepted |
| 81 | `perf/beta-ladder.ndjson` | accepted |
| 82 | `perf/church-numerals.ndjson` | accepted |
| 83 | `perf/discarded-argument-match.ndjson` | accepted |
| 84 | `perf/discarded-argument.ndjson` | accepted |
| 85 | `perf/folded-constant-first.ndjson` | accepted |
| 86 | `perf/folded-constant-last.ndjson` | accepted |
| 87 | `perf/fueled-chain.ndjson` | accepted |
| 88 | `perf/grind-ring-5.ndjson` | accepted |
| 91 | `perf/let-ladder.ndjson` | accepted |
| 92 | `perf/magma-list-deep-n21.ndjson` | accepted |
| 93 | `perf/magma-list-deep-n36.ndjson` | accepted |
| 94 | `perf/magma-list-pair-n21.ndjson` | accepted |
| 95 | `perf/magma-list-pair-n7.ndjson` | accepted |
| 96 | `perf/repeated-subproblem.ndjson` | accepted |
| 97 | `perf/shared-subterm.ndjson` | accepted |
| 99 | `perf/unroll-versus-evaluate.ndjson` | accepted |

## Deployment and architecture gates

- **A — usable developer kernel:** current source/provider changes must pass native, full portable closure, canonical .ps, generated JS and independent provider CI at the same final SHA before this is marked achieved.
- **B — complete DAG replacement:** **NOT ACHIEVED**. Legacy decoding, external-session declaration types, general DefEq continuations, recursor/iota and inductive admission still require work. V1 remains separately available and the default/reference contract.
- **C — complete Arena compatibility:** **NOT ACHIEVED**, with 24 unresolved host timeouts in the latest completed complete comparison.

The native and generated providers must own their sessions, check every supplied declaration, and publish a batch result only after complete checking. Resource exhaustion, unsupported transport and internal errors are distinct from semantic rejection. The old npm-runtime prelude entry that raises fuel to 131072 is not the new provider entry point.

## Performance interpretation

The complete 56559c7 generated integration recorded all **128** guarded operation observations, **24** admission observations and six diagnostic profiles. On the same runner, unique-function WHNF128 was **1375.926–1387.380 ms V1 / 603.417–625.091 ms DAG**, and collision WHNF128 was **3746.170–3763.454 / 2608.680–2626.384 ms**. These supersede the earlier timing regressions for these fixtures only. They do not isolate the scanner refactor's causal effect.

Construction remains more expensive: the five-input unique pool cost **2.393–2.422 ms V1 / 77.926–78.772 ms DAG**; retained heap is mixed. Complete safe-admission warm mean ratios on six selected fixtures range **8.77×–17.58×** in this run. These are workload-specific observations, not a whole-kernel or Arena speedup claim. Preserve the raw run logs and artifact receipts when comparing later changes.

## Remaining whole-operation fallback inventory

There are **four explicit V1 whole-operation fallback sites**, counted as public operation families (not as every internal `Option.none` rule):

| Operation | Owning file and fallback |
| --- | --- |
| Checked expression inference | `API/Dag.lean`: `psKernelDagCheckTerminalOrOriginal` calls `psKernelV1CheckExpression` |
| WHNF | `API/Dag.lean`: `psKernelDagWhnfExpression` calls `psKernelSessionWhnf` |
| DefEq | `API/Dag.lean`: `psKernelDagIsDefEq` calls `psKernelSessionIsDefEq` |
| Declaration admission | `API/DagAdmission.lean`: `psKernelDagAdmitDeclaration` calls `psKernelV1AdmitDeclaration` |

The entry boundary still validates then decodes the complete arena into physically shared recursive expressions; checked inference and WHNF decode new result nodes; declaration requests are decoded before their direct admission attempt. Moving proof irrelevance into the DAG owner removes one unsupported rule family, not these four fallback sites. General lazy delta/full-shape/eta rules, recursor/iota, externally owned environment types and direct inductive admission remain incomplete.

## Formal status and remaining work

Local metadata, scope/cache guard, numeral recurrence and scanner equivalence lemmas pass at the native checkpoint above using the previously approved proof-file dependencies `propext`, `Classical.choice`, and `Quot.sound`. They do not introduce kernel runtime axioms and do not prove global soundness, validated-arena correspondence, full substitution refinement, DefEq or admission.

Continue through the real highest-priority failing gate. Keep complete V1 fallback until each replacement is qualified; preserve exact recursive fuel/depth/callback placement, cache owner scope, failure order and atomic publication. Do not merge, publish npm, increase policy limits or count a timeout as rejection.
