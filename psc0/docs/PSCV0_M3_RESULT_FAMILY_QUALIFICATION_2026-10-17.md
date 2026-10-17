# Bounded own-binder result-family qualification — 17 October 2026

Accepted compiler/test SHA:
[`0e2f5c461d30457caee322b8135293597f55ac4b`](https://github.com/dwijayuda/pskernel/commit/0e2f5c461d30457caee322b8135293597f55ac4b).

**All five gates passed at that exact compiler/test SHA.** This qualifies the
bounded own-binder omitted-result rule and its resource-error propagation,
with **960 retained observed runtime comparisons**. The engineering estimate
remains **78/100**, and M3+B/M4/M5 remain open.

The preceding generic P0 acceptance is
`82b248a3ee2cd9246756690db23b7dffd612e022`; its
[full receipt](PSCV0_M3_GENERIC_P0_RUNTIME_QUALIFICATION_2026-10-17.md)
records the two added generic exports and the preceding 960-comparison
baseline. The earlier
[independent WF receipt](PSCV0_M3_INDEPENDENT_WF_QUALIFICATION_2026-10-17.md)
retains the 940-comparison construction checkpoint. Those acceptances remain
historical evidence; this receipt identifies the later tested compiler.

## Complete same-SHA qualification

| Gate | Run | Job | Result |
| --- | --- | --- | --- |
| Native Linux | [39040588006](https://github.com/dwijayuda/pskernel/actions/runs/39040588006) | `117419140165` | SUCCESS; all 34 reported steps |
| Focused M3 | [39040587989](https://github.com/dwijayuda/pskernel/actions/runs/39040587989) | `117419139972` | SUCCESS; all 15 reported steps |
| F1 canonical model | [39040587981](https://github.com/dwijayuda/pskernel/actions/runs/39040587981) | `117419139877` | SUCCESS; all 10 reported steps |
| F2 logical operations | [39040588008](https://github.com/dwijayuda/pskernel/actions/runs/39040588008) | `117419139837` | SUCCESS; all 9 reported steps |
| F3/F4/platform | [39040587982](https://github.com/dwijayuda/pskernel/actions/runs/39040587982) | `117419140082` | SUCCESS; all 11 reported steps |

Native completed all 34 reported steps and focused M3 all 15. Foundation F1/F2/
F3-F4-platform completed 10/9/11 respectively. There were no skipped required
steps. The published Native/focused logs contain **4,476,633 /
8,264,521 characters**.

| Gate | Artifact | Files | Bytes | SHA-256 |
| --- | --- | ---: | ---: | --- |
| Native Linux | [12103729665](https://github.com/dwijayuda/pskernel/actions/runs/39040588006/artifacts/12103729665) | 236 | 6,797,268 | `09a19655357ca975337902a831a3c7b86f9a4390ecca91676ae7aecec957aad1` |
| Focused M3 | [12103214519](https://github.com/dwijayuda/pskernel/actions/runs/39040587989/artifacts/12103214519) | 286 | 3,038,443 | `31119835fc1aef644509103d290cf118f20577158864b03223327524da773ac8` |
| F1 canonical model | [12103544009](https://github.com/dwijayuda/pskernel/actions/runs/39040587981/artifacts/12103544009) | 6 | 1,674,681 | `0fb8f54fcf91fab656a79302b392cf1260679447f5ab6c53775cde71dd7e48af` |
| F2 logical operations | [12103698107](https://github.com/dwijayuda/pskernel/actions/runs/39040588008/artifacts/12103698107) | 3 | 1,798,323 | `cd1fd8dd8ede0f36e07be12463f4ee4f75b71259fabbf7839967f542ab0273c6` |
| F3/F4/platform | [12103851464](https://github.com/dwijayuda/pskernel/actions/runs/39040587982/artifacts/12103851464) | 7 | 295,038 | `b924748f59ce21b9b8ca2c8d5536308a58ac3ec19fecacf67fe5240dcfe9b181` |

Each artifact's run/head identity, size and SHA-256 metadata matches its
completed upload receipt. The focused upload contains 286 files. The ZIP
contents were not independently reopened.

## Checked inference rule and elaboration schedule

The old result hole was created outside a declaration's own binders. It could
infer a fixed result such as Nat but could not represent a body-inferred type
such as Fin(n + 1). The implementation now creates a natural result family
over the resolved own-binder telescope, in the enclosing local context, then
applies it to the original arguments. Body inference and checked caller
constraints share that same family.

Only an unassigned, natural, non-delayed metavariable with positive
`numScopeArgs` and exactly its complete argument spine receives the new rule.
Zero-argument holes retain their ordinary treatment. The metadata survives
template export, fresh replay and duplicate-template comparison.

| Boundary | Implemented check |
| --- | --- |
| Pattern assignment | Abstract distinct actual binding locals in application order; reject repeated arguments, nonbindings and arguments already in the family creation scope. |
| Constant approximation | Require the proposed value to fit the creation scope; build the lambda telescope from the declared family type and check its terminal Sort. |
| Candidate acceptance | Check type, occurs and scope in the creation locals, then retry the complete original equality in the actual comparison scope before assignments commit. |
| Pending metavariables | Preserve their complete saved creation scope; do not prune another pending hole's scope to obtain a family assignment. |
| Blocked family | Permit ordinary conversion to make progress; prevent generic application congruence from guessing a family head and index. |
| Failed comparison | Restore term and universe assignments, declarations, allocation state and delayed state. |

A full unresolved family is recognized as an unknown expected result by its
existing elaboration owners. Lambda bodies may infer their shape, record
bodies wait for a known structure, and tactics preserve their unresolved-goal
guard. Caller constraints and mandatory defaulting keep their existing
schedule. A fixed-index match may defer unknown result dependence, while
the dependent-context refusal and final checked recursor construction remain.
Solved families are beta-reduced before capture closure.

The header elaborates its own binders and any explicit annotation before
deciding whether it is complete. Inference can use a solved annotation's
context, as in the retained headerSolved case, but cannot infer an own
parameter type from the later body. Explicit main result holes remain
different from omitted annotations; selected local explicit holes can use
body inference. All final unresolved-term, lifted-type, body and official
kernel checks remain.

## Resource failures retain their owner

Concrete resource failures now propagate through the migrated instance
candidate/check/search paths, synthetic assignment and default attempts,
checked work queues and elaborator adaptation/postponement owners.
They cannot turn into a blocked result that permits fallback or another
default. A checked queue abort restores the original context and pending
order while retaining the number of attempts already consumed.

This is a bounded migration of production owners. Legacy Option/result-only
compatibility wrappers remain, as do pre-existing low-level normalization
and unifier fuel policies. No global resource-policy rewrite is claimed.

## New source and native qualification

The result-inference fixture retains the original successful sources and
adds direct evidence for own-binder dependence. The completed focused source
path checks **19 pinned native examples**, **19 source theorems** and
**18 closed total definitions**, plus the original **three opaque/private
partial pairs**. It runs seven source requests: one successful source-only
request and six exact refusals. The successful request produces declarations
and no executable artifacts.

| Source case | Required checked observation |
| --- | --- |
| Direct dependent result | `dependent n` has result Fin(n + 1), with a universal reflexive source/native equation. |
| Forward local helper | A helper's result depends on its own k; applying it to n + 1 substitutes that argument in the result family. |
| Qualified helper | `dependentForward.helper k` has the expected Fin(k + 1) type without capturing an unused parent n. |
| Explicit parent result | A Nat parent observes Fin.val of the inferred helper result. |
| Saved tactic | A local explicit result hole resumes `exact k` under the caller's Nat constraint. |
| Caller-directed numeral dictionary | A mutual caller selects CallerToken for an omitted callee result; the actual OfNat 0 dictionary returns a token with value 23. |
| Fixed-index match | A ZeroIndex 0 match with omitted result is checked and observed as Nat. |
| Record resumption | A helper's record body resumes under the caller's annotated token result. |
| Own type binder | `ownIdentity(A : Type u, a : A)` infers A and has a universal source/native equation. |
| Retained cases | Values, defaults, solved headers, closures, mutual total/partial bodies, source printing and ambient captures remain. |

The old own-binder-dependent-result refusal is replaced by a genuinely
illtyped Fin constructor. The main Where request batch retains seven requests: one successful
five-target emission and six refusals. Its separate partial-hint batch remains
unchanged, with one source-only success and seven refusals.

| Refusal case | Exact owning rule |
| --- | --- |
| Explicit main result hole | PSCV0-DECLARATION-HEADER |
| Explicit mutual main result hole | PSCV0-WHERE-HEADER |
| Unresolved omitted result | PSCV0-WHERE-INFER-TYPE |
| Parameter type inferred only from body | PSCV0-WHERE-HEADER |
| Illtyped omitted result body | PSCV0-TYPE-MISMATCH |
| Inferred fixedpoint with unapproved assumption | PSCV0-FIXPOINT-ASSUMPTION |

The Native fixture adds 151 lines while preserving its preceding source
byte-for-byte. Its first new boundary test solves R n = Fin(succ n) with a
checked lambda and universe assignment. A separate pending index carrying n
must block without changing its declaration, pruning its scope, assigning
the family or guessing R := Fin. Checking the index first then resumes the
same family. A productive Eq control succeeds before a comparison with a
different final endpoint verifies complete term/universe/declaration rollback.

The second new boundary test obtains a real zero-fuel inference error on a
Nat literal. Postponement must retain it, and queue draining must stop before
a later default can unlock the continuation. The positive control preassigns
that same default and checks that the same continuation succeeds. Thus the
refusal is a resource boundary, rather than a permanently invalid fixture.

The actual completed Native and focused logs contain these new markers:

```text
PSCV0_NATIVE_RESULT_FAMILY: PASS checked dependent family, preserved pending index scope, checked resumption and complete equality rollback

PSCV0_NATIVE_SYNTHETIC_RESOURCE: PASS inference fuel, postponement and checked drain

PSCV0_M3_RESULT_INFERENCE: PASS independent native dependent result families, caller-guided inference and main-hole/local-hole boundaries, preserved source printing, checked total and partial headers, recursive predefinitions, scoped captures and exact refusals
```

## Retained source, trust and runtime coverage

The completed focused build passed **668 jobs and 14 outer fixture commands**.
The original WF fixture retained 21 requests: two positive requests and 19
required refusals. Dependent and independent two-argument packing, source
equations, captured callbacks, closure and construction checks passed.
All **38 WF** and **10 Where** printed assumption closures stay within the
approved set; the generic P0 native closure marker passes and P1 still refuses
its audited Classical.choice dependency.

An anchored scan of completed output finds exactly **56 runtime PASS lines**,
byte-for-byte identical to the preceding P0 baseline after timestamps are
removed: 26 scalar ECMA, 13 scalar Rust, 13 scalar Wasm, plus 2/1/1 from original
deriving. There is no substituted source-only count for an emitted case.
The retained scalar runner, blob `83f069245f7b94fa5a9bce4779ab6619b46512c3`,
and original recursive-deriving runner, blob
`b3898fc6d889ab05af9c676342c4f34059f9bbc8`, each assert both flags against
the corresponding native oracle in every execution lane.

No runtime export or workflow changes are part of this feature. The accepted
focused total remains **960 actual comparisons**: 72 scalar exports × two
flags × five lanes = 720, plus the original 24 deriving exports × two flags ×
five lanes = 240. Both flags are checked against the native oracle in direct
JavaScript, strict compiled TypeScript, locked Rust, V8 GC core and Wasmtime
components.

| Runtime suite | Exports | Flags | Lanes | Observed comparisons |
| --- | ---: | ---: | ---: | ---: |
| groupfold | 2 | 2 | 5 | 20 |
| wellfounded | 16 | 2 | 5 | 160 |
| groupmatch | 4 | 2 | 5 | 40 |
| mutual | 5 | 2 | 5 | 50 |
| groupderive | 6 | 2 | 5 | 60 |
| mutualstructural | 6 | 2 | 5 | 60 |
| nestedfold | 7 | 2 | 5 | 70 |
| wherefixture | 6 | 2 | 5 | 60 |
| nestedderive | 6 | 2 | 5 | 60 |
| groupproof | 4 | 2 | 5 | 40 |
| emptydict | 4 | 2 | 5 | 40 |
| indexedinhabited | 4 | 2 | 5 | 40 |
| p0generic | 2 | 2 | 5 | 20 |
| Original recursive deriving | 24 | 2 | 5 | 240 |
| **Total** | **96** | **2** | **5** | **960** |

The generic P0 suite retains Nat false/true 2947/4123 and Bool false/true 12/21,
actual opaque/private bodies, complete type/universe telescopes and both
verified-assurance refusals without executable artifacts. Ordinary observed
returns do not grant a logical partial-body equation or verified backend
correspondence. The historical generic Wasm marker's wording about checked
equations does not alter that boundary.

The completed Native job passed all 34 steps, including the retained expected
instance, synthetic, default-instance and instance-graph controls. It
regenerated and audited the proof assets and retained the admitted Standard
at **3,633 declarations, 41 classes and 359 instances**:
FNV `4990397000639020696`,
Standard SHA-256 `5e96678b7ca94ac8dcb63d36cee81c5997287f507ce8c0c26d28321b37ce97d7`,
surface SHA-256 `7a996cfc6253693799d43fdcf78dd7f30eb0713a3eb31831daa9d804faf818c6`.

The real three-module application, GC core/component qualification, direct
JavaScript, compiled TypeScript and Rust execution all pass. Direct JS,
compiled TS and Rust each retain **1,069 shared observations**. The Wasmtime
host check covers aggregates, normalization, indirect parameters, repeated
calls and post-return. The generic Nat/Bool controls execute
**100,000/50,000 steps**. The final M1 performance JSON records the exact
`sourceSha` `0e2f5c461d30457caee322b8135293597f55ac4b`; no different compiler revision is substituted.

## Failed candidates and bounded repairs

The accepted candidate follows four completed failed matrices. None of these
earlier compiler/test SHAs is independently accepted.

| Candidate | Native / focused runs | Observed host failure | Subsequent repair |
| --- | --- | --- | --- |
| `d5ba914b029ad2fbcf661968e1616529b7855d0d` | [39038894477](https://github.com/dwijayuda/pskernel/actions/runs/39038894477) / [39038894559](https://github.com/dwijayuda/pskernel/actions/runs/39038894559) | Synthetic:60:71 and :265:77, unexpected identifier while parsing record fields. All five gates failed. | A four-comma-only correction was attempted; it was insufficient. |
| `854e2f48f91eb0ebbe336259dbf8ec7ff4b3481b` | [39039646657](https://github.com/dwijayuda/pskernel/actions/runs/39039646657) / [39039646620](https://github.com/dwijayuda/pskernel/actions/runs/39039646620) | Same Synthetic errors shifted to :60:72 and :265:78. All five gates failed. | Align the outer fields of those two records and the two matching Application/Where records. |
| `2d8721309f85fed0f897e801fd51cc105d216220` | [39039973782](https://github.com/dwijayuda/pskernel/actions/runs/39039973782) / [39039973822](https://github.com/dwijayuda/pskernel/actions/runs/39039973822) | Synthetic/Basic/Postponed/Binders compile; Application:280/282/283 reports Unit/result mismatch and unexpected outdented else. All five gates failed. | Place the complete conditional on its own indented branch line; whitespace only. |
| `d7b42ebf8b53fcf61852836181c37c867c93e674` | [39040281210](https://github.com/dwijayuda/pskernel/actions/runs/39040281210) / [39040281196](https://github.com/dwijayuda/pskernel/actions/runs/39040281196) | Application/Match/Term compile; Where:93:11 returns an Option from the enclosing five-field header routine. All five gates failed. | Produce the branch value with pure(some(...)) and continue through the existing header checks. |

The first two failures were caused by field layout, not repaired merely by
inserting commas. The pinned structure parser uses sepByIndent/checkColGe:
each subsequent field must start at or to the right of the first field even
after a comma. The final field layout and application conditional repairs
change only whitespace/separators. The final annotation repair corrects the
branch return owner. All four failed matrices stopped before new native or
source behavior assertions.

The completed Native logs for these four failed candidates contain
92,941 / 89,934 / 92,461 / 92,652 characters respectively. Their exact errors
and full gate identities remain in the candidate work-document revisions.
The valid source examples, their expected values, all assertions, workflow
owners and resource budgets remain unchanged through the repairs.

## Exact implementation and fixture scope

Relative to the accepted P0 compiler/test baseline, the feature changes
**12 compiler files and three fixtures**, **684 added / 169 removed lines**
(**515 net lines**). It changes no runtime exports or workflow.
The accepted P0 and WF fixture/runner coverage remains in the same branch.

| File under psc0/ | Qualified blob | Added / removed |
| --- | --- | ---: |
| packages/meta/src/Ps/Meta/Context.lean | `147352b81d01fb6904b08434e33d1dd45ecb4ddd` | 19 / 1 |
| packages/meta/src/Ps/Meta/Abstract.lean | `d1ef13423546dfaa84f16792546fbe860ffc3a9c` | 6 / 3 |
| packages/meta/src/Ps/Meta/Unify.lean | `982b64fc9c435c8fba41732f8e44f67ca87c08e2` | 141 / 6 |
| packages/elab/src/Ps/Elab/Basic.lean | `2f986506476aa90f728e748d2d5b905980085408` | 22 / 4 |
| packages/elab/src/Ps/Elab/Application.lean | `0a86703ef71dbd12500768df147c4ef71d9a3f4c` | 30 / 14 |
| packages/elab/src/Ps/Elab/Binders.lean | `2983ee482d67b1c9d97ddb0d85cdfc260a5dcba3` | 4 / 2 |
| packages/elab/src/Ps/Elab/Postponed.lean | `c1841a32d5aa21c232262f8cc17f5160c62a2d27` | 30 / 18 |
| packages/elab/src/Ps/Elab/Match.lean | `846593803af30a8b4cb3530383805b9fcd03e60e` | 5 / 2 |
| packages/elab/src/Ps/Elab/Where.lean | `7d0a50cd02adfdcf8d91d84e4667d13fafc41187` | 28 / 44 |
| packages/meta/src/Ps/Meta/InstanceCandidate.lean | `97c11b3a6a9b185eeabb552d442407d8a4a61e5a` | 18 / 6 |
| packages/meta/src/Ps/Meta/InstanceSearch.lean | `7f600c6ed25dcc7281ff628d753364b0c644d64f` | 41 / 25 |
| packages/meta/src/Ps/Meta/Synthetic.lean | `58a4889d50ab8f2bc797ce76d204cf9f791bd3a5` | 94 / 38 |
| test/Pscv0M3ResultInference.lean | `23d61845cabcd0d9a2ce8193dcfcfeb655a57274` | 92 / 3 |
| test/Pscv0M3Where.lean | `9e7634b5c5eea225957e5effacaff86a94a5e6e6` | 3 / 3 |
| test/Pscv0NativeTests.lean | `23b3a23309b2bf9a62993e2ddbf73624e13efc76` | 151 / 0 |

The comparison also includes current work records, migration notes and the
accepted P0 receipt; those are documentation. The subsequent final checkpoint
adds this receipt and updates current documentation without changing the
qualified compiler/test tree.

## Engineering estimate and next obligation

The accepted engineering estimate remains **78/100**. It is progress against
selected milestone exits, not measured language coverage.

| Exit | Accepted | Weight |
| --- | ---: | ---: |
| Data, elimination and deriving | 25 | 30 |
| v7.2 source strategies | 14 | 15 |
| Total structural/WF recursion | 16 | 20 |
| P0 ordinary partial execution | 13 | 15 |
| P1 selected partial_fixpoint | 1 | 10 |
| Cross-stage integration | 9 | 10 |
| **Total** | **78** | **100** |

The earlier source point already grouped optional main-result inference and
inherited-partial hint fidelity. This result-family slice closes the bounded
own-binder omission gap; it does not consume the last source point while
general unused-hint diagnostic parity remains. Syntax repairs, regressions
and passing gates receive no separate credit, and source-only examples add
no runtime-comparison count.

The next concrete source obligation is unused-hint handling for a checked
nonrecursive Where helper. The current
`ordinary-unused-unknown-measure` fixture still refuses an unknown measure
in a helper whose actual body is nonrecursive. WhereScope scopes that suffix
before the typed PreDefinition component graph can establish that it is unused.
At the pinned Lean source, addPreDefinitions processes a nonrecursive member
first, then TerminationHints.ensureNone emits the unused-hint warning without
elaborating its expression. A future change must reconcile those owners while
preserving raw suffixes/spans, checked header/body dependencies, capture
closure, active recursive measures/proofs and original-main strategy checks.
A superficial source-name scan is not sufficient evidence of nonrecursion.

The inference rule remains bounded. Constant approximation is eager and
checked; arbitrary application inversion, general higher-order completeness,
and new scheduling/backtracking are outside this qualification. Some dependent
or ambiguous callers may require annotations. Broader indexed binary deriving,
nested/source induction, larger changing WF packs, arbitrary measure
telescopes, general mutual WF and the complete P0 matrix remain open.

Only **propext** and **Quot.sound** are approved. P1 continues to refuse its
audited Classical.choice dependency. M3+B, M4 and M5 remain open. The PR stays
draft/open/unmerged on its original base.

## Authority and evidence method

- Sole forward language authority: PSCV0_LANGUAGE_REFERENCE_v7.2.md, blob
  `694115223777599ba28ee175e14bb642b7b6aa4b`, including local Where ownership
  and binder/result inference rules.
- Required Lean 4.35.0 pin:
  `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
- The implementation review includes that pin's result inference/unification,
  scope metadata and source-header owners. Layout repairs were checked against
  the actual pinned structure parser and sepByIndent/checkColGe.
- All repository access and mutation used connected GitHub tools. Compilation
  and execution used cloud Linux CI. No local clone, repository execution,
  shell build, gate cancellation or force push was used.
- Evidence comprises completed decoded logs, exact source and runner
  assertions, same-SHA job outcomes, artifact metadata and matching upload
  receipts. Artifact ZIP contents were not independently reopened.
- Every earlier failed run had completed before another compiler/test push.
  Final documentation is committed after healthy Native CI completes; a
  documentation-only head does not claim separate compiler qualification.

## Linked source owners

- [Qualified result-inference fixture](../test/Pscv0M3ResultInference.lean) and [Native boundary fixture](../test/Pscv0NativeTests.lean).
- [Unifier family owner](../packages/meta/src/Ps/Meta/Unify.lean), [header owner](../packages/elab/src/Ps/Elab/Where.lean) and [checked synthetic queues](../packages/meta/src/Ps/Meta/Synthetic.lean).
- [Existing source score rationale](PSCV0_M3_DEPENDENT_WF_INDEXED_QUALIFICATION_2026-10-17.md#engineering-progress-and-remaining-obligations).
- [Current unused-hint scope owner](../packages/elab/src/Ps/Elab/WhereScope.lean) and [checked component owner](../packages/elab/src/Ps/Elab/PreDefinition.lean).
- Pinned Lean [nonrecursive dispatch](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/PreDefinition/Main.lean#L288-L320), [unused-hint warnings](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/PreDefinition/TerminationHint.lean#L101-L119), [structure parser](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Term.lean#L352-L356), and [field indentation](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Extra.lean#L208-L210).
