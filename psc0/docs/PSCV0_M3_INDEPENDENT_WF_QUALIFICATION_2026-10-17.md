# PSCV0 M3 independent well-founded recursion qualification

17 October 2026. Accepted compiler/test commit:
[`c23a6fb479d3c930dc97f9f13c0421b307e462a2`](https://github.com/dwijayuda/pskernel/commit/c23a6fb479d3c930dc97f9f13c0421b307e462a2).

All five gates completed successfully at this exact SHA. The independent
two-changing-argument WF slice is accepted. The focused total is **940 observed
comparisons**, up from 920. The weighted engineering estimate remains **78/100**:
this extends already-credited pair packing and earns no extra whole point.
M3+B, M4 and M5 remain open.

## Same-SHA gates and immutable artifacts

| Gate | Run | Job | Result |
| --- | --- | --- | --- |
| Native Linux | [39034525558](https://github.com/dwijayuda/pskernel/actions/runs/39034525558) | `117401567568` | SUCCESS; all 34 reported steps |
| Focused M3 | [39034525589](https://github.com/dwijayuda/pskernel/actions/runs/39034525589) | `117401567829` | SUCCESS; all 15 reported steps |
| F1 canonical model | [39034525557](https://github.com/dwijayuda/pskernel/actions/runs/39034525557) | `117401567532` | SUCCESS; all 10 reported steps |
| F2 logical operations | [39034525553](https://github.com/dwijayuda/pskernel/actions/runs/39034525553) | `117401567564` | SUCCESS; all 9 reported steps |
| F3/F4/platform | [39034525602](https://github.com/dwijayuda/pskernel/actions/runs/39034525602) | `117401567830` | SUCCESS; all 11 reported steps |

The complete native run finished before the next compiler/test branch update.
No healthy run was cancelled or replaced. The next generic-P0 candidate has its
own qualification obligation and cannot inherit a claim that its added tests ran.

| Gate | Artifact | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| Focused M3 | [12101547251](https://github.com/dwijayuda/pskernel/actions/runs/39034525589/artifacts/12101547251) | 2,857,573 | `b2ee8740307b6a7bd47ea3fcce4494da3c0e17f5bee40c33e7dd462da481af73` |
| Native Linux | [12102340396](https://github.com/dwijayuda/pskernel/actions/runs/39034525558/artifacts/12102340396) | 6,797,403 | `b3147a6954a79f7fe5f0f5d32b06cb50d79055b3c5199fa2b925d2cc9a58788d` |
| F1 | [12101078462](https://github.com/dwijayuda/pskernel/actions/runs/39034525557/artifacts/12101078462) | 1,674,681 | `048fe1b1b3fb04cbf3bf4cb23bccb80770eb8f68477ca0965ad7ca363d7a38b8` |
| F2 | [12101108414](https://github.com/dwijayuda/pskernel/actions/runs/39034525553/artifacts/12101108414) | 1,798,323 | `98857afc86edfb2eea2d65b4c96cdae747f6daba4b3c538de6169282f532d8ae` |
| F3/F4/platform | [12101816235](https://github.com/dwijayuda/pskernel/actions/runs/39034525602/artifacts/12101816235) | 295,038 | `a16e782da518b21b52445071e7c5d55516995dd58ead752ef08a1f66f62c9308` |

The focused artifact contains **267 files**. The complete focused/native logs
are **7,705,040 / 4,478,235 characters**. Job and artifact identities above refer
to the accepted compiler/test SHA, independently of the commit containing this receipt.

## Qualified source and logical construction

The independent functions retain their original source and native Lean oracles.
`independentLeft` decreases the first coordinate while increasing the second;
its source has an erased type family, proposition/proof arguments and an
interleaved fixed step. `independentRight` steps the second coordinate with the
first fixed, then decreases the first coordinate and resets the second. Its
nested matches exercise both branches of the lexicographic relation.

The fixture remains blob `cf91f5d5952c4e1fce1f753e414a441e4b6046d8` at
[the accepted source](https://github.com/dwijayuda/pskernel/blob/c23a6fb479d3c930dc97f9f13c0421b307e462a2/psc0/test/Pscv0M3WellFounded.lean).
Its original three decrease proofs, native oracles, runtime assertions,
public source equations and negative controls were not changed to accommodate
the implementation repairs.

Focused M3 built all **668 jobs** and completed the existing **14 outer fixture
commands**. The WF fixture completed **21 requests: two positives and 19 required
refusals**, including nondecreasing independent sum/tuple measures. Existing
dependent packing, generic relations, private scope, hint ownership, source
printing, all-kind entry slots and dependent result applications remain covered.

The actual log contains both `PSCV0_M3_WF_CONSTRUCTION: PASS` and the complete
WF emission pass. Construction checks retain real `WellFounded.fix/fix_eq`,
PSigma elimination, dependent callback proofs, checked extensional equation
transport, universe closure and the exact public equations. No recursive axiom
or ordinary-P0 marker is introduced for these total definitions.

All **38 printed native WF assumption closures** remain within `propext` and
`Quot.sound`. Both independent native functions have empty assumption closures;
their step/reset equations use only `Quot.sound`. The independent Lean source
and the retained PSCV0 source are checked separately.

## Three repaired boundaries

### Expected-result instance recovery

The original `Prod.Lex.right(0, Nat.lt_succ_self(k))` proof is valid. An eligible
expected-result comparison learned the numeral's input type inside the same
equality and then blocked on the actual pending `OfNat` projection. Rolling
back that comparison lost the input inference before the next proof argument.

The recursive unifier accepts an optional higher-layer recovery callback.
The ordinary entry points supply none. Recovery finds only the actual queued
ordinary instance blocking a projection, uses its saved environment/registry
and creation locals, requires checked synthesis progress, and retries the same
complete comparison. Failure restores term and universe assignments and
resource refusals propagate. No defaults, source continuations or coercion
resumption are run by this recovery.

Native Linux prints
`PSCV0_NATIVE_EXPECTED_INSTANCE: PASS inferred input, complete rollback and saved scope`.
The three direct tests establish inference learned during equality, complete
rollback after a later unequal endpoint, and exclusion of a later caller-local
instance from an earlier goal's saved scope.

This implementation follows the inspected pinned Lean
[ExprDefEq](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Meta/ExprDefEq.lean)
and
[SynthInstance](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Meta/SynthInstance.lean)
recovery model, while keeping Meta independent of elaborator queues.

### Exact equations through nested matches

After decrease proofs passed, equation transport needed a second checked
constructor split for the inner match of `independentRight`. The existing
reflexivity attempt stays first. A further split is available only when a
remaining canonical recursor on an equality side exposes an actual scoped
local major. Each leaf still requires checked reflexivity; inaccessible
induction hypotheses remain inaccessible and the whole retained equation is
checked. Resource errors remain failures. The bound of 64 is a bound on nested
depth, not a total branch-work budget.

### Packed callback capture during executable preparation

After exact logical construction passed, eager substitution of the curried
callback adapter allowed typed recursor lifting to capture the raw packed
callback inside that adapter. The adapter's `PSigma.mk` moved into
`m3wfindependentRight._rec.0`, beyond the parent's exact adapter rewrite.

The accepted functional instead retains a typed Core let for the original
source-curried callback. Nested recursor helpers capture that typed function
value. The raw callback stays in the parent adapter, where the existing pair
eraser consumes the exact adapter and still rejects a surviving raw use.
Ordinary runtime let erasure preserves the resulting function binding.
The logical term is related by ordinary zeta reduction and continues through
the existing definition, equation and official-kernel checks. Arbitrary
runtime PSigma values are not admitted.

The change belongs to
[WF functional construction](https://github.com/dwijayuda/pskernel/blob/c23a6fb479d3c930dc97f9f13c0421b307e462a2/psc0/packages/elab/src/Ps/Elab/WellFounded.lean).
The existing
[typed recursor lifting](https://github.com/dwijayuda/pskernel/blob/c23a6fb479d3c930dc97f9f13c0421b307e462a2/psc0/packages/compiler/src/Ps/Compiler/RecursorLift.lean)
and
[pair erasure](https://github.com/dwijayuda/pskernel/blob/c23a6fb479d3c930dc97f9f13c0421b307e462a2/psc0/packages/erasure/src/Ps/Erasure/WellFounded.lean)
retain their exact closure and adapter checks.

## Actual backend execution

Every export runs with both Boolean inputs in direct JavaScript, strict
compiled TypeScript, locked Rust, V8 Wasm GC core and Wasmtime components.
The two independent WF exports add **20 comparisons**; all previous exports
remain.

| Runtime suite | Exports | Comparisons across five lanes |
| --- | ---: | ---: |
| `groupfold` | 2 | 20 |
| `wellfounded` | 16 | 160 |
| `groupmatch` | 4 | 40 |
| `mutual` | 5 | 50 |
| `groupderive` | 6 | 60 |
| `mutualstructural` | 6 | 60 |
| `nestedfold` | 7 | 70 |
| `wherefixture` | 6 | 60 |
| `nestedderive` | 6 | 60 |
| `groupproof` | 4 | 40 |
| `emptydict` | 4 | 40 |
| `indexedinhabited` | 4 | 40 |
| Original recursive deriving | 24 | 240 |
| **Total** | **94** | **940** |

An anchored scan of completed output observes **24 scalar ECMA PASS lines,
12 distinct scalar Rust PASS stems and 12 scalar Wasm PASS stems**. Each scalar
suite appears once per lane. Each Wasm pass checks core and component execution
separately. The original recursive deriving suite retains its separate 2/1/1
markers and 240 comparisons. These counts describe fixture observations,
not independent features or total language coverage.

## Original native and foundation regression

Native Linux passed all 34 reported steps, including parser/native cases,
captured queues, mandatory defaults, quiescence, rollback, instance scopes and
the three new direct recovery regressions. JavaScript, TypeScript and Rust each
retain **1,069 shared observations**; platform contracts retain **35 probes per
profile**. The real three-module application, V8/Wasmtime GC execution, repeated
component calls, aggregate/post-return checks and 100,000/50,000-step generic
Nat/Bool recursion pass. M1 measurements name the exact accepted source SHA;
they are not a compiler-equivalence or speedup claim.

The foundation audit still reports 34 active additions, no candidate axioms,
native kernel validation and three compared recursor rules. Standard remains
3,633 declarations, 41 classes and 359 instances:

| Identity | Value |
| --- | --- |
| Standard FNV | `fnv1a64:4990397000639020696` |
| Standard SHA-256 | `5e96678b7ca94ac8dcb63d36cee81c5997287f507ce8c0c26d28321b37ce97d7` |
| Source surface SHA-256 | `7a996cfc6253693799d43fdcf78dd7f30eb0713a3eb31831daa9d804faf818c6` |

The audit's `runtimeQualified:false` remains scoped to that audit; the completed
workloads above establish execution separately.

## Earlier failures and remaining scope

The earlier candidates are diagnostic history, not accepted comparison credit:
`cb0b1e85` failed the original proof; `5b87922` advanced to equation transport
but had a reserved native-test identifier; `438dd91e` missed a Meta.Recursor
import. At `9c3e76b1`, Native/F1/F2/F3 passed and complete WF construction passed,
but focused erasure failed at the escaped `PSigma.mk`. The accepted `c23a6fb4`
completes all five gates after the typed-binding repair.

Exactly two dependency-ordered changing binders are supported by the selected
PSigma construction, including an independent constant second family. Larger
packs, arbitrary WF telescopes, general mutual WF and variable measure codomains
remain outside the accepted slice. Broader indexed binary deriving, nested/source
induction, own-binder-dependent omitted results, broader hint diagnostic parity
and the complete P0 combination matrix remain open.

The next separate fixture qualifies generic ordinary mutual P0 at Nat and Bool
with real seed/default dictionaries, both entry directions and both flags.
Its proposed 20 comparisons are not part of this receipt. The natural result-family
implementation is a later, separately reviewed compiler change.

Only `propext` and `Quot.sound` are approved assumptions. P1 stays fail-closed
because of the audited `Classical.choice` dependency. Ordinary execution does not
prove verified backend correspondence. Lean remains **4.35.0**
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`; the sole forward language authority is
`psc0/PSCV0_LANGUAGE_REFERENCE_v7.2.md`, blob
`694115223777599ba28ee175e14bb642b7b6aa4b`.

Connected GitHub is canonical; build and test execution uses cloud Linux.
PR #109 remains draft/open/unmerged on
`psc0/pscv0-v7-m1-parser-ownership-v1`.
