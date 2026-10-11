# P1l / P1m — Uniform dependent-Pi model and guarded source bridge

Qualified 11 October 2026. This checkpoint adds model application/beta/eta and connects guarded source Pi formation to the model. It does NOT establish all-source soundness, full Lean conversion or a consistency capstone.

## Exact code and CI

Source commit **`e95c0b5e381e4ee5a0d47001fad6c69494261683`**; [Actions 38143764809](https://github.com/dwijayuda/pskernel/actions/runs/38143764809), job `114482754713`, completed SUCCESS. The complete job log was inspected. It confirms pinned Lean **4.35.0-rc4**, upstream `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`, and an architecture fence over **58 independent Lean source files**.

All three exact assumption gates passed: original **157**, previous G4.4b/P1k **17**, and new P1l/P1m **28** = **202 distinct enumerated theorem receipts**. The 28 consist of 9 graph-application, 10 unified-Pi, and 9 guarded-source theorems. The existing gate parser and global allowlist remain unchanged (`propext`, `Classical.choice`, `Quot.sound`); missing, extra, duplicate or unreviewed receipts fail closed. No qualified theorem depends on `sorryAx`.

IMPORTANT: the supplied `[SetTheoryBasis V]` is a substantial mathematical premise, not a constructed model. Quantified model assumptions do not appear as global `#print axioms` entries. Even the four graph lemmas with no global axioms are conditional on that supplied basis.

The new dependency closure built in a **42-job** Lake invocation; the old closure in a **109-job** invocation, reusing shared outputs. These overlapping invocation counts are NOT additive. Every existing regression, the native official-kernel differential (15 positive equalities, 2 rejection controls, 1 documented equality gap), and the old exploratory benchmarks passed. Existing warnings remain, including a deprecated `dif_pos` spelling in the new graph proof.

## P1l: concrete graph functionality, then application

[Spec/GraphApplication.lean](src/PSKernelFast/Spec/GraphApplication.lean) proves injectivity of the actual Kuratowski pair `{{a},{a,b}}`, including degenerate pairs. Pair membership in `modelGraph F A` is equivalent to domain membership and the unique equation `y = F x`.

`modelGraphApp graph x` depends ONLY on the graph value and argument. It does not receive an arbitrary presentation witness, a domain, fibre family or typing certificate. It noncomputably chooses a related result when one exists and otherwise defaults to the empty set. This is proof-only totalization: the fallback is neither a valid typed application nor an acceptance decision.

From the concrete encoding, the module proves graph functionality and extensionality on the domain, application beta, and introduction/elimination/eta/extensionality for P1k's existing `modelGraphPi` carrier. Application and eta are proved for the previously universe-closed carrier; they are not new fields assumed of a model.

## P1l: one application operation for Prop and Type

[Spec/TaggedDependentPi.lean](src/PSKernelFast/Spec/TaggedDependentPi.lean) defines three proof-only operations:

- `modelPi V v A B`: at codomain sort rank zero, the existing tagged truth-value Pi; at positive rank, the existing dependent graph carrier.
- `modelLam V v A F`: at zero, the distinguished proof point; at positive rank, the function graph.
- `modelApp V f x`: the point applied to anything is the point; otherwise graph application.

The UNIFORM application operation does not require a caller to tell it which regime applies. The already-proved `taggedPoint_ne_graph` theorem justifies the two representations being distinct. No blanket noncollision property for arbitrary images or quotients is introduced.

Formation preserves the exact evaluated source universe operation:

`A in SortModel(u)` and `(for every x in A, B(x) in SortModel(v))`

imply

`modelPi(v,A,B) in SortModel(numericImax(u,v))`.

The existing positive sort carrier convention is `SortModel(n)=U_(n+1)` for positive n, while rank zero is the tagged Prop carrier. Pi introduces NO additional universe successor. Inclusion of model universe carriers is used in the mathematical proof only; it does not add source cumulativity or a new kernel conversion rule.

The module proves introduction, elimination, beta, eta, extensionality, lambda congruence and Pi congruence for both regimes. Body/fibre equality is needed only on the domain, including empty domains. Beta has genuine semantic fibre/body membership premises. Model extensionality is NOT authority to accept arbitrary extensional equality in kernel DefEq.

## P1m: fibre validity is now derived for a source fragment

[Proof/SourcePiModelBridge.lean](src/PSKernelFast/Proof/SourcePiModelBridge.lean) introduces `SourcePiAnnotation`, a source-only inductive relation. Its inputs contain source syntax, source contexts, source universe levels and their valuation; it contains NO semantic model values or assumed fibre-validity hypotheses.

The relation covers Sort, variables whose actual source binder domain is a syntactic Sort, and Pi formation with ANY codomain rank. Thus it extends the old Prop-only source bridge to positive-sort dependent Pis. The codomain annotation is the valuation of the actual source rule's codomain Sort, not unchecked frontend metadata.

Source induction reconstructs `GeneralPiRule`, preserves exact source erasure, derives semantic membership under the sort-binder environment invariant, and derives ALL Pi fibres by extending that source environment. A separate uniqueness proof establishes the exact syntactic inferred Sort, not just a numerically equal rank.

The main execution theorem combines actual `inferClosedGeneralPi` success with this source certificate to obtain exact inferred type, matching source/result erasures, and denotation membership in the modeled inferred type.

One symbolic source family is used throughout:

```lean
forall (A : Sort u), A -> A
```

The actual checker equations for the Prop case (`u=0`) and Type case (`u=1`) are proved by kernel-checked `rfl`, not `native_decide`. The positive case's executed source denotation belongs to `SortModel(2)` via the general bridge. These are checks of the Pi TYPE/proposition itself, not admission of an identity-function proof or executable identity term.

## Proof development provenance

| Commit | CI run | Outcome |
|---|---|---|
| `fa0bfc38499b314bd2ec1c6e10526138be7bcd0a` | [38142533048](https://github.com/dwijayuda/pskernel/actions/runs/38142533048) | Graph functionality/application/beta/eta green |
| `ddc32de7b784e6a02591549e43cdd6397048e702` | [38142864676](https://github.com/dwijayuda/pskernel/actions/runs/38142864676) | Build correctly failed on one incomplete Prop-Pi congruence simplification |
| `8421bc44580808f795788be4be2d6eba4bc5eef9` | [38143138914](https://github.com/dwijayuda/pskernel/actions/runs/38143138914) | Direct composition of existing truth equations fixed that proof; full suite green |
| `e95c0b5e381e4ee5a0d47001fad6c69494261683` | [38143764809](https://github.com/dwijayuda/pskernel/actions/runs/38143764809) | Guarded source bridge, exact executions and all 202 receipts green |

No theorem statement, assumption boundary, runtime acceptance rule or regression expectation was weakened to repair the one proof-script failure. This continuation was NOT entirely first-run green; the failed run is deliberately retained in the record.

The source diff from `68fc0ca5135a0a597fa806c16f6973def09aab5a` adds only three proof-side Lean modules and an audit script, plus the workflow hook. `SetTheoryBasis`, `GeneralPiFormation`, `TypedNormalization` and its native differential fixtures are unchanged. The old 157- and 17-receipt audit scripts are unchanged.

## Remaining obligations and performance boundary

The current source relation deliberately cannot treat a proof variable `x:P` as a proposition variable `P:Prop`: only actual syntactic Sort domains support its variable rule. General dependent contexts, source lambdas/applications/lets, annotation coherence, semantic weakening/substitution and source reduction preservation remain OPEN.

In particular, `modelPi_beta` is now a proved mathematical equation, but `TypedSteps.denotation_preserved` still needs a genuine source-model `stepSound` theorem. No general source interpretation or substitution lemma currently discharges that premise. Extend or replace the proof-only annotation representation as needed; do not constrain the performance-oriented runtime to preserve this transitional proof shape.

Full symbolic conversion, binder/argument congruence, proof irrelevance/eta in executable conversion, protected environment/transparency identity, quotient/inductive/primitive semantics, model-preserving checked declaration extension, and conditional no-derived-False remain further obligations. Public proof admission remains disabled and admitted declarations remain zero.

No new runtime optimization or benchmark was added. Existing G4.4a timings still describe the old head comparator; they are not G4.4b timings and are not representative official-kernel, allocation or RSS comparisons. This increment improves the proof foundation without adding a runtime semantic authority; it does not establish a smaller binary or faster kernel.
