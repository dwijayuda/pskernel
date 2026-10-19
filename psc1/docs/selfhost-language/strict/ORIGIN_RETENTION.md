# Origin retention for actual elaboration batches

This is the first bounded origin-retention slice for the source-owned SH/1 path. It retains information at the point where elaboration and structural normalization already produce it. It does not reconstruct a mapping from printed names, repeat preparation, or claim semantic preservation.

**Candidate status:** the two source companions described here are based on `cf35b6b2a3328a065721ef48cf633a44e6122362`. At the time this candidate was prepared, they had received source review only; no build, compiler run, test, or qualification had been performed for these changes. Integration and its actual evidence must be recorded separately. `generalPreservationProven`, `semanticContractQualified`, and `strictSh1Qualified` remain false.

The assurance requirements are still those in [SPEC.md](../SPEC.md), [CORRESPONDENCE.md](CORRESPONDENCE.md), and the [rule ledger](correspondence-obligations.json). Retaining an actual origin is useful input to a correspondence argument; it is not that argument's proof.

## 1. Ownership and scope

Only these compiler modules change in this slice:

| Module | Retained information |
| --- | --- |
| [Elab/Recursion.lean](../../../packages/elab/src/Ps/Elab/Recursion.lean) | The actual successful recursion plan, original containing declaration span, internal worker name, and the worker binder/type/value syntax already constructed by normalization |
| [Elab/Declaration.lean](../../../packages/elab/src/Ps/Elab/Declaration.lean) | One origin per actual source-declaration batch, each actual Core member's batch index/name/role, and errors attributed to the phase the caller actually observed |

The original `PsElabStructuralNormalization`, `PsElabDeclarationBatchResult`, and `PsElabModuleResult` types remain unchanged. Existing builder, planner, normalized-definition, ordinary batch, declaration-worker, declaration-list, and module entry signatures also remain unchanged. They project the successful result or original error from richer companions. The explicitly requested stable batch elaborator remains byte-identical and is called once by the ordinary richer batch path.

The surrounding source-owned compiler API attaches module identity, retains the already parsed module, and composes later preparation/erasure/target checks. Those integrations are separate ownership; this two-module slice does not modify them. It also changes no kernel, provider, definitional-equality, cache, or metatheory algorithm.

## 2. Concrete result contract

The public richer entry points are:

```lean
def psElabDeclarationBatchWithOrigins
    (environment : PsEnvironment) (sourceIndex : Nat)
    (source : PsSyntaxDeclaration) :
    Except PsElabOriginError PsElabDeclarationBatchWithOriginsResult

def psElabModuleWithOrigins
    (environment : PsEnvironment) (sourceModule : PsSyntaxModule) :
    Except PsElabOriginError PsElabModuleWithOriginsResult
```

The declaration result contains `result : PsElabDeclarationBatchResult` and `origin : PsElabBatchOrigin`. The module result contains `result : PsElabModuleResult` and `origins : List PsElabBatchOrigin`.

### Identity and source association

| Record field | Meaning and origin |
| --- | --- |
| `PsElabBatchOrigin.sourceIndex : Nat` | Zero-based ordinal in the original module's source-declaration list; the public module entry starts at zero and advances exactly once per source declaration |
| `sourceName : PsSyntaxName` | The original parsed declaration name, including its existing name span |
| `span : PsSourceSpan` | The original containing declaration's span |
| `members : List PsElabMemberOrigin` | Members in the same order as the actual returned Core declaration batch |
| `normalization : Option PsElabNormalizationOrigin` | `some` only when the existing fallback actually planned and elaborated a normalized worker/public wrapper; otherwise `none` |
| `PsElabMemberOrigin.index : Nat` | Zero-based ordinal within that actual returned batch |
| `name : PsName` | The actual Core member name read from the returned declaration, without printing, reparsing, or guessing |
| `role : PsElabOriginRole` | The role established by the actual declaration kind or the actual normalized worker/wrapper construction |

A complete source association uses the module identity supplied by the caller, the source-local index, and the member-local index. A displayed name is not a witness identifier. The actual `PsName` is retained for exact comparison with the corresponding Core member, including numeric components of internal worker names.

The module result preserves the existing flattened Core declaration order. Its origin list stays in source order, so a datatype batch or normalized two-member batch does not shift later source indices by its Core member count. Member indices restart at zero for every batch.

The public raw declaration worker still accepts an incoming `declarationsRev` prefix. Its richer implementation retains origins only for the source declarations it actually processes; it assigns no invented source origin to that incoming prefix. The source-owned public module entry starts with both accumulators empty.

### Member roles

`PsElabOriginRole` has exactly these constructors:

| Constructor | Assignment rule |
| --- | --- |
| `sourceDeclaration` | A stable ordinary returned Core declaration |
| `inductiveType` | An actual `PsDeclaration.inductiveDecl` whose `info.isStructure` is false |
| `structureType` | An actual `PsDeclaration.inductiveDecl` whose `info.isStructure` is true |
| `constructor` | An actual `PsDeclaration.constructorDecl` in the returned batch |
| `recursor` | An actual `PsDeclaration.recursorDecl` in the returned batch |
| `normalizedWorker` | The actual renamed internal worker declaration constructed by normalized-definition elaboration |
| `publicWrapper` | The actual checked and closed public wrapper declaration constructed in the same execution |

Stable member roles come from the returned Core constructors, not source-name suffixes. Normalized roles come directly from the two actual declaration values retained by the common normalized-definition helper. The current structure elaborator returns its inductive representation, constructor, and recursor; this slice invents no separate projection declaration or role.

## 3. Retained normalization origin

```lean
structure PsElabNormalizationOrigin where
  plan : PsElabRecursionPlan
  span : PsSourceSpan
  workerName : PsName
  workerBinders : List (Prod PsSyntaxBinderHead PsSyntaxTerm)
  workerType : PsSyntaxTerm
  workerValue : PsSyntaxTerm
```

The richer `psElabRecursionBuildNormalizationWithOrigin` constructs the existing worker type and value once. The same actual binder list/type/value are placed in the old normalization result and the compact origin record. In particular, `psElabRecursionWrapAlternatives` is not called a second time to manufacture an explanatory tree.

The retained plan is the actual successful `PsElabRecursionPlan`: public Core name, original parameter IDs, explicit parameter IDs, selected major ID, and generalized IDs. It is captured after the existing typed planning decision and domain checks, not recomputed from names or source text. The internal worker name is the actual numeric Core name used by the normalization path.

The richer builder/planner add no normalization case. They preserve:

- the root-match restriction and selected major;
- typed binder elaboration, explicit-major requirement, and collected changing parameters;
- the existing result/domain dependency refusals;
- parameter renaming and the original bounded syntax walks;
- the existing worker binder order, worker syntax, public type/context, and wrapper arguments;
- the original `none` result and every existing language-level error.

The original `psElabRecursionBuildNormalization` and `psElabPlanStructuralNormalization` APIs project the richer results. The richer temporary companion still contains the old normalization object because worker/wrapper elaboration needs it. The long-lived `PsElabNormalizationOrigin` intentionally has **no `publicContext`, environment, local-context snapshot, or metavariable-context snapshot**.

This retention does not add a syntax-node-to-Core-node map. The worker syntax carries the spans already produced by the existing normalizer; this slice does not assert new expression precision or repair any span.

## 4. Truthful error attribution

`PsElabOriginError` contains the original `PsElabError`, source index, original source name, containing declaration span, and `PsElabOriginPhase`.

| Phase | Boundary that actually knows it |
| --- | --- |
| `stableDeclaration` | The unchanged stable declaration/batch elaborator returned the error. This also applies when the existing fallback planner returns `none`, causing the original stable error to be returned. |
| `normalizationPlanning` | The existing typed structural-normalization planning/building call returned an error. |
| `normalizedWorker` | Elaboration of the constructed worker, validation of its expected Core declaration form, or insertion of that internal worker into the temporary wrapper environment failed. |
| `publicWrapper` | Checking or closing the public worker application, including its existing unresolved-metavariable checks, failed. |
| `declarationInsertion` | The final module fold's existing `psAddDeclarationList` call failed for this actual returned source batch. |

Attribution follows existing control flow. The only stable refusal that triggers normalization remains `structuralRecursionInvariantArgument` on an ordinary definition. Planning is still attempted once. No unrelated stable failure is rerouted through a new fallback.

A batch insertion error is associated with its containing source declaration. The wrapper does not guess which generated member failed when the existing insertion API returns no member ordinal. Likewise, the new phase does not claim an expression-level error location.

The raw APIs return `failure.error`, preserving the existing language-level error value. Allocation limits and implementation resource costs are not claimed to be identical merely because those error values and control-flow decisions are preserved.

## 5. One execution and data lifetime

The richer module fold performs the same semantic operations in the same order:

1. Elaborate the current source declaration through the existing stable path and, only for its existing designated refusal, its existing normalization fallback.
2. Retain the successful batch's actual member identities and optional actual normalization origin.
3. Add that batch to the actual current module environment with the existing `psAddDeclarationList`.
4. Prepend the actual declarations using the existing reverse/append helper, accumulate one source origin, then proceed to the next source declaration.
5. Return the same final environment and ordered declaration list with the source-ordered origin list.

There is one origin per successful source declaration and one member record per actual returned Core member. A normalization origin retains its already constructed worker syntax. This does not run the planner, elaborator, source parser, or full preparation a second time. It introduces metadata allocation and retains some syntax longer; no speedup or equal resource-use claim is made.

The source-owned caller can keep its original parsed module and this batch association alongside the actual prepared declarations. It must not turn an independently supplied record, printed name, caller-provided environment, or caller-provided IR into source authority.

## 6. Safe preparation-result reuse at the next boundary

The existing [Compiler/Api.lean](../../../packages/compiler/src/Ps/Compiler/Api.lean) contains a separate, concrete opportunity to avoid repeated whole-closure work:

- `psCompilerPrepareElaborated` successfully encodes canonical admissions, then discards the encoded string.
- `psCompilerAdmissionsFromPrepared` encodes the same prepared declarations again and appends one newline.
- `psCompilerVerifiedIrFromPrepared` calls `psCompilerEnvironmentFromPrepared`; that validates admissions by encoding again, then rebuilds an environment using `psAddDeclarationList`.
- `PsCompilerPreparationState` already holds the actual final environment obtained while those same source batches were elaborated and inserted.

The approved integration design is to retain the actual final environment and successful canonical admissions result inside the synchronous source-owned preparation result. The source-owned atomic backend can then erase the same prepared declarations against that actual environment and return the retained admissions bytes with the same single final newline.

The environment reuse argument follows construction order: `psCompilerPreparationStart` begins at `psSelfHostProdPreludeEnvironment`; each successful module fold inserts each actual returned batch in order; the preparation state keeps that resulting environment and the same flattened declarations. Temporary self/worker contexts used while elaborating an individual declaration are not substituted for this final module environment. Retaining one final environment is different from retaining an environment snapshot in every origin event.

This reuse must remain inside the raw-source-owned call. Arbitrary external prepared-result APIs retain their existing validation and environment-rebuild obligations. A returned result is not a transferable proof token, and an external caller cannot bypass admission or IR checking by supplying its own environment/report. Reusing the actual successful encoding changes neither the admission encoder's checks nor kernel/provider semantics.

This origin slice does not implement that Compiler.Api/backend integration. It supplies the actual batch information that the root integration can retain in the same source-owned lifetime.

## 7. Assurance boundary and finite completion criteria

This slice supplies a concrete prerequisite for ledger row `N-01` (resolved identity, hygiene, and source origins) and useful batch-order information for `ER-01`. It does not discharge those rows or any general-preservation claim.

The following remain separate obligations:

- a justified source/Core binder and expression relation, including scope and capture;
- general preservation by changing-parameter structural normalization;
- the Core-to-IR relation for omitted proof/type components, runtime parameters, layouts, fields, constructors, and declarations;
- exact evaluation demand/order, including the separately recorded Nat-demand question;
- target/runtime correspondence and all mandatory source-span coverage beyond the containing-declaration association retained here.

Existing Core typing, original-IR typing, provider admission, bootstrap fixed points, and finite runtime observations remain distinct evidence. They must not be relabeled as a general source-to-target semantic proof.

The bounded qualification for this implementation should demonstrate the actual result contract: empty and mixed source modules; source-local versus member-local indexing; stable ordinary/datatype members; an actually normalized worker/public pair with its actual plan and worker syntax; first-error attribution at the reachable phases; and projection of unchanged declarations/errors through old APIs. The relevant native and owned-front-end gates must process the same integrated source revision. These are conformance observations for the implementation, not a theorem over all programs.

The implementation boundary is complete when those results and source revision are retained, the source-owned compiler integration consumes the richer result once, and the old raw APIs keep their contracts. Further origin detail should follow a concrete correspondence obligation; this slice is not permission for a broad compiler rewrite.

## 8. Candidate source provenance

| Path | Base Git blob | Candidate Git blob |
| --- | --- | --- |
| `packages/elab/src/Ps/Elab/Recursion.lean` | `bba4a42a13c29ed5b41761e883e8da0b81a34192` | `c403bd879e439b7b6e88303df430890352a14115` |
| `packages/elab/src/Ps/Elab/Declaration.lean` | `8a8005a2ae0aa6564e075e3b224b432295c6bf05` | `a388d013dbf6c9270ffa91997512f672da6aabff` |

Pure in-memory review confirmed exact base-to-candidate guarded edits, unchanged existing public signatures, no removed declaration, and no new shorthand constructor term. That inspection is not execution evidence. The existing declaration-worker source guard needs its recursive-body checks to follow `psElabDeclarationsWithOriginsWorker`, while retaining the raw wrapper signature/projection checks and the original source restrictions; no restriction should be removed merely because the implementation moved.
