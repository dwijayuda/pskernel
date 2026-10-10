# Source arguments for normalization obligations N-01–N-04

## Status and exact boundary

This document develops the normalization portion of the shared source/Core → original IR → TypeScript/JavaScript relation. This packet is pinned to published source head **3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc**. The line-by-line analysis uses immutable baseline commit **2b5a4c903ed8a069cde8f08265b28042bcaf5766**, whose normalization implementation remained unchanged at documentation commit **047a29f17392fea41ac5d59e7f8cbfc172b20313**, together with the exact integrated Recursion correction **ea8518afd0982e64d6fcfcd2320501d89e0385ec** in §4. Source-completion manifest **639e78ffeba7d64f29ef02eadff9b37951073832** identifies that correction and the batch's two other source changes. The four N rows in the current ledger **9ae363efcb6faab4ffd6c10af0e498ece6004649** differ from the inspected baseline ledger **ac3b08adfd5ded6f0678fa1717988375578685c6** only in their four Recursion source-blob pins; their requirements and open dispositions are unchanged. The common relations and open interfaces are those of the reviewed SEMANTIC_RELATIONS foundation **40e540b325186ee514ff3af9e39a22126d29a167**. SPEC, not this argument, determines mandatory coverage. [I, L, R, S]

The argument distinguishes source equations proved by case analysis, a normalization theorem with named independently meaningful premises, and implementation-specific residuals. It does not introduce a serialized certificate requirement or require a machine-checked theorem as the only assurance method. It does not promote compilation, typing, a fixed point, provider admission or a finite fixture to a general semantic proof. **N-01–N-04 and every other correspondence row remain open; every strict/general/formal assurance flag remains false.**

A bounded hygiene defect in the immutable baseline was found while attempting the N-01 proof. It can wrongly classify a temporary binder inside a parameter domain as an original top-level parameter. The observed fact here is the source transformation, with a predicted refusal; no fixture was executed in this review and no accepted wrong-emission example was established. Section 4 gives the exact limitation and the separately reviewed two-expression correction **ea8518afd0982e64d6fcfcd2320501d89e0385ec**, guarded manifest **fabe10858976ba2fc0d892ef8c0ab20ef227beb6**. That exact reviewed candidate is integrated at the published source head above. The correction does not change parsing, the generalized-state domain, or admission gates. Section 4's candidate terminology identifies the independently reviewed artifact; its claims remain expressly separated from claims about the immutable baseline.

Handwritten PSC1-compatible .lean remains authoritative, generated .ps remains ps-0.9-r3 in new-only mode, R remains selected, and the target remains TypeScript 7.0.2/Node 22.23.3. Kernel, provider, definitional equality, caches and existing theory are unchanged. This work used GitHub MCP source reads, pure in-memory text/hash operations, and creation of unattached review blobs only; no compiler, tests, shell, browser, local files, commits, refs or workflow were executed or changed.

## 1. Actual inputs and the proposition to prove

Consider one source definition with original name f, ordered typed binders B, result syntax R and a root match on a selected binder m. The actual planner obtains B by reversing the returned binder accumulator, not by reconstructing identities from printed names. Write P for its ordered list of all parameter IDs and E for its ordered explicit-parameter subsequence. Let G be membership in the actual generalizedIds list. Repetition in that list is permitted: membership is Boolean, so repeated IDs do not duplicate a selected binder or argument. Let S = filter(G,B) and F = filter(not G,B). The major remains in F. Within each list the original order is preserved. [N:393–407,471–503,582–644,665–709]

Use the complete actual source frame, not a global interpretation of Nat IDs. Original IDs are distinct in that frame; separate restored frames may reuse IDs. An executable environment assigns values to runtime binders and the declared type/ghost interpretation to the remaining binders. A source parameter's renamed syntax is the two string segments $psc0SH and the numeral of its actual ID. The internal declaration name instead appends the string component $psc0SH and a genuine numeric PsName component 0 to f. These are different constructions and have different freshness arguments. [N:51–56,628–642; FN]

For the mathematical worker equation, write u for the invariant parameters other than the major, c for the major value, and s for the selected state values. This notation is a permutation of an already obtained tuple of values; it is not a proposal to change the public calling order. Define D(u,c,s) to mean the original source computation under its original binder/environment association. Define H(u,c) to mean the normalized worker's function-valued result. The intended equation is:

    apply H(u,c) to s  ≈  D(u,c,s)

Here ≈ is the computation relation C of the shared foundation, at each observation index, with its value, callback-demand and permitted-abort clauses. A function result is compared at its result function type and tested by subsequent applications. A two-argument function and a one-argument function returning a function are not identified merely by this notation. [R §§1.2–2.3]

The proof below is about the actual finite syntax transformed by the successful path. It does not claim completeness for every expression accepted by the general frontend. In particular, SPEC's supported independent runtime state and structural recursion requirements do not automatically require every possible type-level lambda/application idiom. The parameter-domain example in §4 is a hygiene/refusal finding within the existing syntax walker, not proof of a missing mandatory grammar capability. [S §4]

## 2. The complete control-flow partition

The ordinary declaration route has the following exhaustive top-level cases. This partition matters because a theorem about a hypothetical always-normalizing compiler would not describe this implementation. [D:1503–1598]

| Actual branch | Transformation and error association |
| --- | --- |
| Stable elaboration succeeds | Return exactly that stable batch. Build member origins from its actual declarations, with no normalization plan. |
| Stable elaboration fails with an error other than structuralRecursionInvariantArgument | Return that error with the original source index/name/span and stableDeclaration phase. No normalization attempt occurs. |
| The particular invariant-argument error occurs on a non-definition source form | Return the same stable error and source association. |
| The error occurs on a definition, and planning fails | Return the actual planning failure with normalizationPlanning phase. |
| Planning returns none | Return the original invariant-argument error with stableDeclaration phase. |
| Planning returns a normalization; worker or wrapper checking fails | Return the actual error with the phase identified at that call boundary, normalizedWorker or publicWrapper. |
| Worker and wrapper succeed | Return exactly the worker/public batch, in that order, with member indices 0/1 and the actual successful plan/syntax origin. |
| Later batch insertion fails | Retain the same source association and record declarationInsertion phase. |

The planner itself declines a source without a root match, an exact local root scrutinee, or an explicit parameter ID for that scrutinee. Its first scan uses an empty generalized list. If the accumulated changedIds list is empty it returns none. Otherwise that actual list becomes generalizedIds, after which the dependency checks, parameter-domain rename, result/body rewrite and normalized worker construction occur. Every bounded syntax walk returns fuelExhausted at zero fuel; no exhausted walk is interpreted as success. [N:272–391,665–709]

The unchanged branch proves an identity transformation only at this normalization boundary. It does not prove the stable elaborator or subsequent eraser correct. Similarly, a preserved failure branch does not establish behavior of a successfully compiled program. These distinctions prevent the control-flow proof from becoming an unsupported end-to-end claim.

## 3. N-01: resolved identities, ordinary hygiene and origins

### 3.1 Exact reference selection

The same psElabResolveReferenceBase is used by reference elaboration and by the normalizer. Its cases are decisive rather than speculative:

1. Resolve the complete PsName, with nearest exact local before a global of that complete name.
2. If absent, and at least two source segments exist, resolve the first segment as a base.
3. Only when that first segment is absent, search proper multi-segment local prefixes, longest first.
4. If a base was selected, project its remaining field suffix. A field/type failure is an error, not permission to try another name.

This follows directly from the nesting of cases in Term, together with psResolveName. Thus the N-01 argument may preserve the selected base and suffix; it must not replace this policy with arbitrary longest-prefix resolution. The normalizer rewrites only a selected local ID belonging to P. Global selections, non-parameter locals and unresolved references remain textually unchanged. A renamed parameter retains precisely the original selected suffix and source-name span. [T:315–425; RES; N:286–305]

The one-segment forms Prop and Type are interpreted as sort references by Term before ordinary named-reference resolution. The ordinary-reference lemma above is for the actual named-reference cases. A complete source alpha theorem must also account for these reserved source forms and the existing PSC1-compatible authoring boundary; it must not silently apply ordinary lookup rules to them. [T:401–425]

Self-recursion identity is deliberately narrower. IsSelf compares the complete syntax name to f and requires absence of an exact same-named local. It does not use projection-prefix resolution. The stable self-call path uses the same complete-name/nonlocal test. Consequently a same-spelled local callable is not rewritten as recursion, and a qualified reference is not identified with f merely because one of its prefixes resembles f. A bare unshadowed f is refused as an escaping reference. [N:24–49,286–288; T:2853–2914]

### 3.2 The body/result alpha argument

For the main body and result walks, the entry context contains the complete original parameter frame, with nextId above every ID in P. Maintain a syntax-walk invariant: the visible original parameter declarations retain their original IDs; each introduced shadow declaration is fresh relative to P; and the order of visible names is the source lexical order. PushName uses the current nextId and prepends the source name. Nested pushes preserve the invariant; returning to an outer immutable context restores its original association. Dummy Prop types are used only for name selection, not as runtime source values. [LC; N:58–81,182–235,605–614]

Under this invariant, reference rewriting preserves exactly the selected original binder. New parameter names cannot be typed by the owned source identifier grammar: $ is not an identifier-start/continuation character, and name parsing requires identifier tokens for components. Their numerals distinguish distinct original IDs. A source shadow binder keeps its original spelling, so it cannot capture the generated parameter name. A reference to a shadow binder has an ID outside P and is not rewritten. A reference to an original parameter receives the same generated name wherever its original ID is selected. Qualified field suffixes are appended unchanged. [LX:317–341; PC:97–195; N:51–56,286–305]

The complete syntax induction has thirteen constructors, with the following cases. It establishes alpha correspondence and preservation of the surrounding syntax, not an arbitrary reordering of runtime computations. [AST; N:129–391]

| Syntax cases | Induction step |
| --- | --- |
| reference | Use the resolution and shadow invariant above; preserve the exact projection suffix and span. |
| natural, string, character, bool, unit | Return the same leaf and span. |
| record | Recurse over each field value in list order; retain field names, list order and record span. |
| ordinary application | Recurse into the callee and each argument; reconstruct the same application boundary and argument list. Static visitation of arguments before the callee is not a runtime evaluation-order claim. |
| direct self application | Use the separate partition/rewrite lemma in §§5–6. |
| lambda and forall | Walk each binder domain before introducing that binder's shadow name; then walk the body under the complete shadow context. Retain binder names/kinds/spans in these nested binders. |
| let | Walk its optional annotation and initializer in the old context, introduce its name only for the body, and reconstruct the same let. |
| if | Preserve condition/then/else positions and the span. Both branches are inspected statically; only the selected branch is demanded by the source semantics. |
| match | Walk the scrutinee in the old context. Walk each alternative under just that pattern's shadow names; preserve patterns, alternative order and branch spans. |

For the ordinary alpha cases, under the stated lookup/environment and typed interpretation premises, the corresponding syntax induction gives the environment-renaming lemma: a local/global lookup obtains the same value, a closure captures corresponding environments, and each ordinary computation constructor invokes the induction hypotheses in its original semantic positions. Direct self application is the distinct worker/state transformation of §§5–6, not an alpha-renaming step. For type syntax, the associated typed substitution and meta-instantiation premises remain the O-SUB/type-validity interface; changing a spelling is not proof that a typechecker or reducer is semantically sound.

### 3.3 Worker identity and truthful origin association

The internal worker's name is a deterministic function of the actual f. Parsed ordinary declaration names have string components; the worker additionally has a numeric PsName component, and environment insertion refuses an existing declaration of exactly that identity. Distinct actual f identities give distinct worker identities under the ordinary constructor equality laws. This is an identity/freshness argument, not reliance on a hash bucket or printed spelling. The worker is elaborated using the original source f as the structural self identity; after that elaboration has replaced permitted self calls with actual IH IDs, the resulting declaration is renamed to the fresh internal worker identity. [N:628–642; D:1435–1455; FN; ENV]

Origins are constructed from the successful objects. Stable origins enumerate the actual stable batch; normalized origins name result.worker and result.publicDeclaration with indices 0 and 1; the retained plan and worker syntax come from that same normalization result. The declaration fold increments sourceIndex once per source declaration, preserves each batch's member order by reversing only its accumulator, and associates an insertion failure with that same batch's source. The compiler preparation wrapper retains these exact origins; the strict source layer adds the actual module name and current Core offset. [D:74–115,1534–1644; API:145–160; SH:632–676]

Renamed references retain their original name spans; renamed top binder heads retain name-span, binder kind and head-span; inserted inner/outer self applications use the original call span; state lambdas use their source branch spans; the worker origin uses the original declaration span. This is honest attribution at those stated granularities. Elaboration errors do not suddenly gain an expression-level span when their existing datatype lacks one: the new phase/source record identifies the original declaration and actual phase, not an invented precise location. No stronger diagnostic precision is claimed.

## 4. N-01's parameter-domain obstruction and the narrow correction

### 4.1 What the old source actually does

The preceding body/result invariant cannot simply be asserted for parameter-domain renaming. In base N, RenameParameters starts from psLocalEmpty. After one original binder it rebuilds a prefix context with nextId = that binder's ID + 1. The domain of the next binder is therefore walked with the next original ID still available for a dummy shadow binder. Yet the reference branch tests membership against **all** original parameterIds. A dummy domain-local ID can equal the ID of the current or a later original parameter. [N:505–540,601–604]

A concrete source-derived refusal candidate, with no top-level generic binder, is:

    def f (n : Nat) (x : (fun (T : Type) => T) Nat) : Nat :=
      match n with
      | Nat.zero => x
      | Nat.succ k => f k (Nat.add x 1)

The relevant steps are determined by the source:

1. In the original top telescope, n has ID 0. Elaborating x's closed beta-Nat domain temporarily opens T and restores the surrounding context; x then receives ID 1.
2. A direct recursive occurrence with the changed x operand triggers the intended invariant-argument fallback. The first scan's candidate generalized membership is {1}; m = 0 remains fixed.
3. The original elaborated domain has no free original n/x ID. Reducing its type yields Nat; the intended runtime-state check therefore does not reject it for dependence or being a type/proof parameter.
4. RenameParameters walks x's domain under the prefix containing only n, with nextId 1. Its dummy T also gets 1.
5. The reference T is selected as local 1 and rewritten to $psc0SH.1, but the nested binder head still says T. The rewritten domain is therefore alpha-incorrect.
6. In the worker's state telescope, $psc0SH.1 is x's own not-yet-introduced generated name. With no unrelated matching internal name, the predicted result is an unbound-name refusal, not an accepted implementation of a different result.

Steps 1–5 describe the association failure. The full fixture has not been executed through the pinned compiler or native reference; step 6 and exact diagnostic precedence are predictions, not a reported receipt. The strict syntax walker permits typed lambda/application syntax in a type region, but that alone does not prove that every such general type expression is mandatory minimum SH/1 coverage. SPEC requires the supported typed/runtime contract and truthful normalization; it does not equate the entire frontend datatype with the enabled language. This finding therefore does not establish a mandatory-coverage failure or an accepted semantic counterexample. [T:528–707; N:410–469,505–540; SH:345–392,529–569; S §§2–4]

### 4.2 The reviewed candidate and its invariant

Candidate ea8518afd0982e64d6fcfcd2320501d89e0385ec changes exactly two executable expressions in N, plus two explanatory comments:

- The actual BuildNormalizationWithOrigin call starts RenameParameters with an empty declaration list and binderResult.context.localContext.nextId.
- The recursive prefix step preserves context.nextId when prepending the actual original binder, instead of lowering it to binder.id + 1.

The full original nextId is a reserved high-water mark. It does not expose future declarations. On the actual call path, the following induction proves the corrected invariant.

**Base.** Typed binder elaboration begins at an empty local context and returns the complete ordered original binders. Pushes allocate the previous nextId and increment it; temporary elaboration scopes restore their outer local contexts. Hence every original binder ID is below the returned full nextId. The new rename context has that counter and no declarations.

**Prefix step.** Add precisely the next actual original ID/name/type/kind to the declaration list. Its ID is below the reserved counter. Preserve the counter. The visible declaration list is exactly the old algorithm's original prefix, in exactly the same order.

**Nested domain step.** A dummy binding is allocated at or above the reserved counter, so it is outside P. A nested dummy scope may allocate larger IDs. Returning from the domain walk discards its dummy context. Reuse of dummy IDs in unrelated sibling domains is harmless because they never coexist and never belong to P.

**Resolution consequence.** Complete-name and prefix search see identical declaration names in identical order and the same environment. Original parameter IDs are unchanged. A selected original parameter is therefore renamed exactly as before. A selected dummy local remains an ordinary local reference instead of being mistaken for an original parameter. No future parameter becomes visible. This proves the specific hygiene property rather than merely relying on the rewritten worker to typecheck.

For domains with no local syntax binder, including ordinary no-generic Nat domains, the source result is byte-for-byte the same renamed syntax. Existing references to a stable type parameter retain its actual ID. Body and result walks still use their original complete contexts. Plans, changed-ID accumulation, fixed/state selection, dependency tests, worker/public construction, source spans and origins are untouched. There is no new grammar feature, widening admission gate, helper, or test process.

The stronger helper precondition applies to its actual caller. It does **not** claim that an arbitrary external call to RenameParameters with psLocalEmpty and unrelated nonempty typed/plan inputs is safe. The pinned source contains the recursive call and the one BuildNormalization call; the bounded independent review found no other code caller in the reviewed path. [N; LC; T:528–590]

This correction was independently reviewed by /root/empty_evidence_finish, read back exactly, and checked by reversible in-memory edits. Its SHA-256 is **487deb18c577a22ed10885238b78b5ea31f4e212e738fff13cee3c4f8d259549**, and its UTF-8 size is **35,795 bytes**. The guard requires base blob c403bd879e439b7b6e88303df430890352a14115. Those facts establish the reviewed textual correction; exact-source qualification and broader N-01 disposition remain separate.

## 5. N-02: state selection, dependency legality and structural provenance

### 5.1 The selected-list lemma

ChangedArguments traverses the original explicit ID list and the original actual argument list together. A length mismatch is an error. At position m it records no generalized ID. At another position i it records i precisely when the original operand is not an exact local reference to i. Combining results over syntax concatenates these lists; it does not invent an ID. Therefore, on a successful first scan:

- every member of G belongs to E and differs from m;
- a fixed explicit position other than m in every scanned direct self call contains the exact original parameter identity;
- the selected state list is a subsequence of explicit binders, and nonempty generalized membership produces at least one state binder;
- filter membership preserves the original relative order in both F and S, regardless of repeated occurrences in generalizedIds.

The proof is induction on the paired list traversal, followed by the syntax traversal's concatenations. This is stronger than saying that the final worker happens to typecheck: it explains why an operand moved into the fixed group is an identity lookup, rather than an arbitrary allegedly pure computation. A state operand may itself be a variable, lambda, nested call or other supported computation; membership does not assume it is already a value. [N:83–151,250–270,393–407,471–503]

The major's validity is **not** proved by ChangedArguments, which deliberately skips that position. It is proved separately by the generated worker's original structural validator. Keeping these arguments separate prevents a missing major check from being hidden inside the selection lemma.

### 5.2 Free-variable soundness and legal permutation

HasFreeVariable structurally traverses every PsExpr position that can contain a free variable: applications, both binder domain/body positions, all let type/value/body positions, and projections. It tests actual fvar IDs; bvar, literal, sort and constant leaves contain no local free ID. Unresolved expression/metavariable cases are separately rejected by the preceding meta checks. A structural induction therefore yields:

    check(A, {m} ∪ G) = false
    ⇒ no free occurrence of an original major/state ID in A

This is a syntactic nondependence result for the instantiated checked term A. It is not a theorem that arbitrary unification or metavariable assignment is sound. Valid assignment, well-scoped originals and type interpretation remain the independently stated O-SUB/type-validity premises. A global declaration's closed type cannot secretly contain a free variable from this frame under that validity premise. [N:410–469,590–599; R §6]

The implementation checks the instantiated original result and **every** original binder domain, including fixed, major and generalized binders. A generalized domain additionally must not WHNF to a sort, must have an inferable sort type, and must not classify as Prop under the stated level predicate. Thus the source check explicitly excludes moving a parameter whose actual type still syntactically depends on m or G, and excludes directly recognized type/proof state. Source-to-Core validity and the supported universe interpretation are required to turn the successful sort classifier into semantic runtime relevance. No claim is made that a Boolean returned by an unsound inferencer would prove that relevance. [N:434–469]

The telescope permutation proof is then finite and constructive. Original domain well-scoping permits dependencies only on preceding original binders. None can refer to m or any member of G. Hence every surviving dependency is on an earlier member of F. Filtering preserves F order, and moving F ahead of S makes all such dependencies available without changing their values/types. S order is preserved too. The result has no free m/G occurrence and retains the same allowed F dependencies. Therefore the new motive has the independent function telescope S → R required by the first-slice contract. This proves why the actual syntactic check is sufficient for the rearrangement, under the ordinary well-scoping/typing premises; it does not demand a broader dependent telescope. [S:153–164; N:617–639]

### 5.3 Actual child provenance and the checked worker

The planner chooses m only from an exact local root scrutinee in E. The generated worker is then elaborated by the existing declaration path, still using source name f as its structural recursion identity. StructuralRecursionFromSource recomputes the root's actual explicit index after F has been selected; it does not reuse an obsolete original positional index. The root match must have an actual supported non-indexed family and a compatible actual recursor. Match field opening checks constructor owner, parameter/field counts, duplicate pattern binders and level counts. [D:153–202,211–285,1435–1448; T:1688–1788,1982–2124]

Recursive-hypothesis bindings are allocated from the selected constructor's recursive-field indices. When collection is permitted, the context records an association from that freshly opened field ID to its freshly opened IH ID. A nested match may extend those associations only when its scrutinee is the selected major or an already associated child and its expected result matches the recursion result. An unrelated same-typed value does not gain provenance merely through matching. Existing associations remain lexical; branch restoration prevents newly opened field IDs from escaping into unrelated branches. [CTX; T:1517–1587,1943–1980]

ValidateStructuralCall checks the exact number of explicit worker arguments, requires the major operand to resolve to a field ID in that actual call map, and requires every other explicit operand to be the original fixed binder's exact ID. It returns the corresponding IH ID. Arbitrary subtraction, a computed child expression, an unchanged original major, an unrelated field, changed fixed operands, and escaping/unsaturated self references fail their stated paths. Accepted ancestry is therefore derived from the actual validator branches, not from a same-type or same-spelling heuristic. [T:2725–2914]

The semantic claim that such a declared recursive field denotes a strict structural child still uses actual constructor metadata soundness and the regular-data interpretation O-LAYOUT. That premise is narrower and independently meaningful: it concerns which stored field belongs to which constructor and its recursively smaller value. It does not assume that normalization preserves computation.

### 5.4 What N-02 establishes and what remains

Together, §§5.1–5.3 establish the source selection invariant, syntactic domain exclusion, legal independent telescope permutation, and exact accepted child/fixed-ID validation. Given valid original typing, sound supported sort classification and actual layout metadata, they justify the source typing of the function-valued motive. They also permit reconstruction of an original declarative typing derivation from the checked worker: at a rewritten self call, the outer ordinary application checks the S operands, the inner structural call supplies the correctly typed IH, and reinserting the unchanged F operands reconstructs the original telescope.

The imported premises are still not discharged by the mere fact that the generated worker typechecks. In particular, this document does not re-prove inference/unification/meta soundness, every frontend elaboration rule, constructor-metadata correctness, or proof/type erasure independence. The base parameter-domain hygiene gap in §4 also prevents asserting the full alpha premise for every base normalizer path. These are precise boundaries of the N-02 argument, not new admission requirements.

## 6. N-03: the function-valued worker equation

### 6.1 Independent semantic premises

The following argument proves a normalization theorem with explicit premises. None of them says “normalization is correct.”

| Premise | Independent content and source obligation |
| --- | --- |
| A: alpha and typing associations | Original parameter/domain/branch references have the associations proved in §3; parameter domains satisfy the required hygiene invariant, with §4's base limitation or reviewed correction stated explicitly. Types, assignments and binders satisfy the ordinary O-SUB/well-scoping laws. |
| D: legal state domains and child metadata | The syntactic exclusions and exact identity checks in §5 are interpreted by sound supported typing and actual regular-data metadata. |
| V: prior values and calls | Previously available fixed values, primitive operations and function-valued inputs have the shared V/C interpretation at their stated types. Functions are compared by the finite application index; arbitrary host callbacks are not substituted for this premise. |
| K/Π: Core computation and call alignment | Well-scoped Core lambda/application/let/match/recursor constructs obey the independent source/Core operational interpretation and a fixed mapping of original source application groups to their normalized realization. In particular, the regular recursor uses the associated fields and child hypotheses. This is O-CORE-DEMAND/application alignment plus the local substitution/layout laws, not bounded WHNF as an evaluator. |

Premise K/Π needs an independently justified source/Core interpretation, call-event alignment and ordinary elaboration adequacy. The proof below supplies the normalization-specific structural-fold and demand cases that such an interpretation must validate. It does not claim that naming K discharges the entire frontend. Section 8 separates this remaining bridge from the local theorem.

Use one remaining interaction budget throughout the computation, as in the revised foundation. If an operand returns with residual r, the next operand or continuation starts with r; earlier values/environments are weakened to that smaller index. At a matched invocation with positive residue r, the body starts with r−1. At residue 0 the observation cuts off before that invocation, without a claim about its later result. A returned function is related at its actual residual result index. No operand, callback, recursive call or nested runner receives a fresh copy of the initial budget.

The proposed source-call alignment charges each original demanded public, recursive, state-expression or callback application once. The fresh worker/public plumbing and recursor closure-building steps realize that source computation administratively; they do not reset the budget or create extra logical applications merely because Core/host implementation steps occur. A rewritten direct self occurrence is matched to its demanded child-IH/state application, while nonself application nodes retain their original positions. Whether this alignment implements the independent source/Core interpretation is a precise K/Π obligation. Structural termination alone does not establish that observational classification.

For a canonical finite major c, define its structural size recursively from its declared direct recursive children. For Nat it is n; for a regular constructor it is one plus the sum of those children's sizes. Each permitted child has smaller size. Values with cyclic foreign structure are outside the canonical value relation. This is the well-founded measure for normalization recursion; the function interaction index from the common relation handles higher-order values and callbacks. There is no need to equate this measure with emitted instruction count or host allocation. [R §§1.2–1.3; S §3]

### 6.2 The exact worker equation

For a constructor C with fields z and recursive children d₁,…,dᵣ, the generated syntax is a root match whose C alternative is a lambda over **the complete ordered S list**, around the entire renamed/re-written original branch E_C. Field patterns stay outside that lambda. The stable elaborator closes actual field binders and actual IH binders around the branch term. Therefore its canonical minor shape is:

    λ fields. λ IH₁ … IHᵣ. λ s. E'_C

The types of the IHs are the same independent S → R motive. At a direct source self call, RewriteCall makes an inner application with the F explicit operands and an outer application with the S explicit operands. The stable inner self-call validator returns the actual child IH fvar. Ordinary application elaboration applies that IH to the selected state operands. It neither inserts stale state into the IH lookup nor pretends that changed arguments are fixed. [N:250–270,542–555,617–639; T:1688–1788,2858–2897]

The generated worker's outer source binders are F only. In prepared Core, these outer binders are followed by the actual root recursor computation returning the S function. The source does not move S into the outer recursion parameter list. This is the source-side part of SPEC's stale-state warning. Subsequent erasure must still preserve that separation through its own currentDefinition and eta/call treatment; that is a distinct ER-04/ER-09/O-GROUP obligation. [S:159–164; D:1435–1448; N:630–639]

Define H(u,c) by the canonical primitive-recursion equation using these minors. On C(z), each actual child IH denotes H(u,dᵢ), and H(u,c) yields the closure λs.E'_C with u, c, z and those hypotheses associated in its environment. Define D(u,c,s) independently by the original root-match branch and original direct structural recursive calls. The theorem is that applying the obtained H closure to related state values yields the computation D at the same result type and initial interaction budget, with related outcomes at the residual budget actually returned.

### 6.3 The readiness lemma: obtaining an IH does not execute a branch body

This step is essential. Extensional equality of final functions would not justify evaluating an arbitrary function-valued computation early.

The successful normalized path has a nonempty G membership and hence a nonempty S list (§5.1). Every actual branch is wrapped in that state lambda (§6.2). To obtain H(u,c), the recursor can inspect the already obtained constructor c, bind its already obtained fields, and obtain its child hypotheses. Its selected minor then produces a closure over S; it does not evaluate E'_C.

Prove by structural induction on c that obtaining this closure terminates with no source-observable callback, state transition, permitted abort, or evaluation of an original branch-body computation:

- A constructor with no recursive children requires only constructor inspection, field value binding and closure creation.
- For recursive children, each H(u,dᵢ) is obtained by the induction hypothesis. Each child is smaller; there are finitely many fields. Once those hypotheses are available, the selected minor returns the state closure.
- Other constructors follow the same finite cases. The only new work consists of structural inspection, binding and closure construction.
- Nat follows the zero/successor instances of this reasoning. Even if an implementation of the independent recursor interpretation obtains all predecessor closures eagerly, there is finite descent before any state body is applied.

The structural proof establishes termination of this prefix and excludes evaluation of original branch/state/callback computations. Treating all its introduced worker/recursor steps as administrative additionally uses the fixed source-call alignment Π just described. Under that justified alignment they consume no new original logical-call event, while any demanded original recursive or callback application retains its event. Finite descent by itself proves termination, not silence or permission to erase a logical event. No arbitrary computation is being declared pure: the exact minor shape prevents original branch code from running. Field and fixed-parameter values have already been obtained. The proof permits additional allocation or finite traversal, whose success is governed by the existing resource premise; it makes no bound on peak memory or claim that a particular run fits. It also does not authorize infinite silent stuttering: the decreasing finite structural measure excludes it here.

If a prospective Core interpretation evaluated a state body while merely acquiring its function-valued hypothesis, it would not satisfy this readiness lemma and could not be used to close N-03. Likewise, an IR rewrite that flattens away this boundary must prove its own alignment; the lemma is about the independent normalized Core worker shape, not automatic justification for erasure's result-arrow exposure.

### 6.4 The decisive recursive-call case

Consider one original direct self call, whose explicit arguments are in E order. Partition its positions by G without evaluating them. By §5.1, each non-major fixed position is the exact original parameter reference; by §5.3, the major is an actual child reference. These are immutable value lookups. All potentially computed operands are in the selected state subsequence, and that subsequence retains its original order.

The original call first obtains its callee, then demands its runtime operands in original order. The intervening fixed/child operands are total, silent reads of already-bound immutable values. Removing or relocating those reads may cross computed state operands, including operands that abort or diverge, but introduces no invocation or abort, does not reorder any demanded state computation, and preserves the first abort/divergence and suppression of later operands. Ghost/type positions use the declared type/ghost interpretation, not an invented runtime effect. The observable operand sequence is therefore precisely the sequence of selected state computations, in their original relative order.

The rewritten call obtains the corresponding child hypothesis through the inner fixed/major application. On the actual elaborated path this becomes its associated IH fvar. If the independent recursor semantics obtains that hypothesis earlier, §6.3 shows the intervening work is finite and silent. The outer application then evaluates the selected state operands in the same caller environment and in the same relative order. Apply the syntax induction hypotheses sequentially: each operand receives the preceding operand's residual interaction budget, yields values related at its resulting residue, and passes that residue to the next. Previously obtained values are weakened to the current index. The same sequence reaches the corresponding abort/divergence or cutoff boundary; no later operand gets a restarted allowance.

For terminating operands, retain the complete resulting tuple before executing the child's state body. Lambda application extends the child's environment with that tuple. It does not overwrite the caller's first state variable while evaluating a later state expression. Consequently a swap such as (s₂,s₁), or expressions in which later operands read earlier original state variables, uses simultaneous **old-environment values**, not sequential assignment.

At the matched recursive invocation, let r be the residue after callee/state-operand evaluation. If r is zero, both observations cut off before that invocation. Otherwise consume exactly one unit and apply the structural induction hypothesis at the strictly smaller child d to the tuple weakened to r−1, with the child bodies observed at that same residue r−1. It relates the child H(u,d) application to D(u,d,newState). This is the original recursive computation. The hypothesis is justified by structural descent and the current residual budget, not by assuming all recursive calls preserve semantics or restarting the initial index. A function-valued result is related at the residue actually returned, and a subsequent call consumes from that residue.

For an operand abort or divergence, induction on the ordered operand list identifies the same first failing demanded computation. Later state operands and the child's body are not evaluated on either side. The readiness prefix cannot introduce a different source abort under the stated canonical/resource premises. An Except.error value is ordinary data and does not interrupt this list unless the original surrounding source explicitly branches on it. Foreign throwing-callback probes remain outside this source domain unless an extension is separately stated.

The argument would be invalid if a supposedly fixed operand were an arbitrary expression, if a child were recomputed by subtraction/projection, if selected state operands were permuted, or if the early worker prefix could run branch code. The actual selection/validator/minor-shape cases above establish exactly the conditions that avoid those errors.

### 6.5 Ordinary expression cases and higher-order results

Complete the proof by a mutual syntax/structural induction, using the finite residual interaction budget for higher-order observations. Every sequential case threads that one residue; every related invocation charges it once, every return carries it back, and cutoff imposes no post-invocation result obligation.

- A renamed original variable reads its corresponding value; a local shadow or prior global has the same lexical association. Primitive literal leaves are unchanged.
- An ordinary application retains the callee boundary and ordered argument list. Apply its subexpression hypotheses in the independent source call order, passing the residual budget from callee to operands; then use the already related callee's clause at the residue after the one invocation charge. A zero residue cuts off before entry. Static scanner visitation order is irrelevant.
- A lambda is a related closure, because its structural captures are associated at index 0 and its captured values/parameter extensions satisfy the foundation's lower-index E/V clauses for each licensed positive-index invocation. Construction does not execute the body. A returned function is compared at its result function type.
- A let evaluates corresponding initializers in the old environments, extends each environment with the corresponding resulting value, and applies its body hypothesis. The source walker introduces the let shadow only for that body.
- An if evaluates corresponding conditions and only the corresponding selected branch. Inspection of both branches by the compiler adds no runtime demand.
- A record preserves its labels and field syntax. Under the same source record/layout interpretation, corresponding selected field computations occur in the same order. A projection's selected base and suffix are unchanged, so its actual layout/type association supplies the same field. This uses layout meaning rather than equating property spellings.
- A nested match preserves its scrutinee, patterns, field binders and alternative positions. Apply the scrutinee hypothesis, bind corresponding actual fields, and use the selected branch hypothesis. Any recursive self occurrence in that branch must still have passed the actual provenance validator.
- Forall and annotation/domain positions use typed alpha/substitution and the supported ghost/type interpretation; they do not become newly demanded runtime code.
- The direct self-application case is §6.4.

The induction supports captured invariant functions, multiple varying parameters, state before the major, and source function results without pretending that JavaScript underapplication implements the public API. The compiler's type/erasure/backend call alignment remains a separate bridge. A syntactic normalizer proof cannot certify an unrelated callback, malformed foreign data, source-visible mutation, or arbitrary host exception handling.

### 6.6 The precise conditional conclusion

Under A, D, V and K/Π, and for each canonical finite major and related environment/state tuple, the function-valued worker equation holds for every finite initial interaction budget, with outcomes related at the residual budget actually returned. Operand demand, selected callbacks and permitted aborts correspond. The readiness measure rules out new infinite silent recursion in obtaining H; divergence of an original demanded computation is preserved by the same ordered expression cases and related calls. This gives the normalization-specific simulation, not merely an extensional equation on a few Nat outputs.

The unresolved bridge is to establish A/D/K/Π for every **actual accepted** compilation at the chosen implementation boundary, and connect its Core functions to the same Π/C relation used by erasure. Section 4 identifies one concrete base A obstruction and a narrow candidate correction. Ordinary elaboration, meta/type validity, actual constructor/recursor semantics and later eta/group alignment retain their stated obligations. A finite witness or a checked worker type can support those interfaces, but cannot stand in for them.

## 7. N-04: original public telescope and wrapper behavior

The wrapper is built from the original public context, original publicBindersRev and original instantiated publicType. Its application uses the actual fresh worker constant and actual original binder fvars, ordered F followed by S. It is checked against that original public type. Then CloseElabTypedBinders closes the original binders in reverse accumulator order, using each original binder's ID, name, instantiated domain and binder kind for both the value lambda and type forall. The resulting declaration has the original public name. The worker/public batch is returned in that order. [D:1435–1493; T:620–653; N:635–644]

These are universal source facts about the successful wrapper branch:

1. No public binder is deleted merely because it moved internally; the original complete binder list is closed.
2. No implicit/strict-implicit/instance-implicit binder kind is converted to explicit by wrapper closure.
3. Original public binder order is retained, including when selected state precedes the major.
4. The wrapper's internal permutation contains original fvars only; it does not re-run argument expressions or synthesize a replacement state.
5. Worker insertion precedes wrapper checking, and insertion of a conflicting internal identity is refused.

To prove the calling behavior, induct over prefixes of the original public telescope while retaining the caller's original application groups. Each matched original caller group, including one supplying only a proper runtime prefix, threads its callee/operand residues and then consumes its own invocation event, or cuts off if the residue is zero. A proper-prefix group returns the corresponding remaining closure at its returned residue; it does not reset the allowance. Before all original runtime arguments needed by the body have been obtained, the wrapper is the corresponding closure over the already obtained prefix. Its remaining original binder domains and order are unchanged. It cannot execute the internal worker application simply because a prefix was supplied: that application is inside the body under the remaining original lambdas. This is the same public source boundary as the original definition.

For the final original caller group that completes the tuple required to enter the public body, the same rule consumes that group's event from its callee/operand residue and enters the body at the resulting residue, or cuts off at zero. Any earlier proper-prefix groups have already consumed their own matched events. Under the fixed Π alignment, the introduced private worker delegation realizes the body of this final source invocation administratively; it neither double-charges it nor starts a new budget. Evaluating the wrapper reads its already-bound values in F/S order. Those reads are silent; the original caller has already demanded the argument expressions in its original application boundaries and order. Applying the worker to this tuple then yields the original computation by §6. Thus the internal reordering does not reorder original argument computations. For a function-valued result, compare the returned closures at the result function relation indexed by the actual residual budget and continue subsequent caller applications from that residue. For rank-1 parameters, quantify over the same supported type assignment θ and use the same original ghost interpretation.

The type part uses ordinary well-scoped closing/substitution and valid final meta instantiation. The semantic body part uses N-03's worker equation. Neither follows just from the checker's success. At the IR/JavaScript boundary, the resulting original public telescope must still be related through Π; direct nested-lambda flattening, result-arrow eta exposure and partial capture are O-GROUP/ER-04 obligations. The wrapper proof does not erase that distinction or change the full public curried contract required by SPEC. [S:147–164; R §§1.3,2.2,6]

This yields the source/Core wrapper theorem given the independent premises above. It is a reusable proof for arbitrary supported original binder order and state count, rather than a claim restricted to a finite twelve-worker ABI sample.

## 8. Row disposition and the smallest remaining proof work

The source arguments produce the following reusable results. A result's stated independent hypotheses are part of its scope; they are not certification tokens.

| Row | Established source argument | Precise remaining interface |
| --- | --- | --- |
| N-01 | Actual top-level success/refusal partition; exact self/reference-selection policy; complete body/result shadow-walk cases; deterministic worker identity; actual member/source/phase/span origin construction. The integrated reviewed correction supplies the missing parameter-domain dummy-ID separation on its actual caller path. | Qualify the published implementation boundary; complete typed alpha interpretation, including reserved sort-reference cases, legal initial namespace and valid meta/closing premises. Base c403 has the concrete domain-shadow association obstruction, so its full alpha claim cannot be asserted; current ea8518 contains the reviewed repair. |
| N-02 | Membership/order theorem; G ⊆ E without m; fixed-ID preservation; syntactic nondependence over all Core forms; legal telescope permutation; actual accepted major/child/fixed argument checks. | Sound supported type/sort classification, valid instantiated original typing, constructor/recursor metadata meaning, and the alpha premise from N-01. These are independent typing/layout facts, not final-value tests. |
| N-03 | Structural-fold equation; finite hypothesis-readiness proof, administratively silent under K/Π; recursive-call simulation with exact state order, old-environment simultaneous values, first-abort/divergence handling, closure cases and indexed higher-order use. | Instantiate A/D/K/Π for the actual accepted path: ordinary source/Core elaboration adequacy, typed substitution, declared recursor interpretation, actual layout and the same shared call relation. Downstream IH reconstruction and eta/group changes remain ER obligations. |
| N-04 | Original full public telescope/name/kind/order retention; actual worker-argument identity; prefix-closure argument; wrapper delegation theorem from the worker equation. | N-01/N-03 premises, valid meta/closing laws, and Π/O-GROUP when connecting the public Core telescope to original IR and JavaScript. |

For a source-level assurance route, the smallest semantic next step is not another fixture catalogue or a new serialized witness. It is to establish the ordinary Core interpretation used in K, the typed opening/closing/meta facts used in A, and actual constructor/recursor association used in D, then instantiate the finite cases already given here. The existing proof development may supply those premises if its statements genuinely match this implementation and domain. This document does not modify that theory or assert such a match without review.

The N-specific demand proof is substantive: it identifies the only early work introduced by the function-valued fold and proves that work finite from the nonempty state-lambda shape and strict structural children. Its classification as administratively silent additionally requires the fixed K/Π alignment described in §6; finite descent alone does not establish that classification. The argument also identifies exactly why interleaved fixed/state parameter order is safe. It cannot settle later erasure's call convention by itself. In particular, plain extensional eta equality is not a substitute for O-GROUP, and a source-level hypothesis function is not automatically equal in demand to any reconstructed IR recursive expression.

No accepted incorrect-emission counterexample was established. The domain-shadow example is an independently checked source mechanism with a predicted refusal and explicit coverage limits. The correction is independently reviewable as an invariant repair without expanding grammar or weakening a gate. No claim of successful native or generated execution is made for it.

**Disposition:** retain generalPreservationProven = false and strictSh1Discharged = false for each N row. Retain strictSh1Qualified, semanticContractQualified and formalPreservationProven = false. The document supplies proof content and specific residuals; it closes no ledger row.

## 9. Immutable source index and review artifacts

Line numbers in the argument refer to the base blobs below. The published Recursion correction adds two comments and a line break, so later corrected-source line numbers differ slightly. The base and corrected identities remain separate; §4 gives the exact correction and its actual-caller proof. The packet's integration boundary is 3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc.

| Label | Source or artifact | Immutable identity |
| --- | --- | --- |
| I | [Published source integration](https://github.com/dwijayuda/pskernel/commit/3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc), with [source-completion manifest](https://api.github.com/repos/dwijayuda/pskernel/git/blobs/639e78ffeba7d64f29ef02eadff9b37951073832) | 3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc; manifest 639e78ffeba7d64f29ef02eadff9b37951073832 |
| S | [SPEC.md](https://github.com/dwijayuda/pskernel/blob/2b5a4c903ed8a069cde8f08265b28042bcaf5766/psc0/docs/selfhost-language/SPEC.md) | 61f0f36ffe7880144f60845084e8be6a61b91eed |
| L | [Four exact N rows in the current correspondence ledger](https://api.github.com/repos/dwijayuda/pskernel/git/blobs/9ae363efcb6faab4ffd6c10af0e498ece6004649) | 9ae363efcb6faab4ffd6c10af0e498ece6004649; inspected baseline ac3b08adfd5ded6f0678fa1717988375578685c6 |
| R | [Shared semantic relations foundation](https://github.com/dwijayuda/pskernel/blob/3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc/psc0/docs/selfhost-language/strict/SEMANTIC_RELATIONS.md) | 40e540b325186ee514ff3af9e39a22126d29a167 |
| N | [Elab/Recursion.lean](https://github.com/dwijayuda/pskernel/blob/2b5a4c903ed8a069cde8f08265b28042bcaf5766/psc0/packages/elab/src/Ps/Elab/Recursion.lean) | c403bd879e439b7b6e88303df430890352a14115 |
| D | [Elab/Declaration.lean](https://github.com/dwijayuda/pskernel/blob/2b5a4c903ed8a069cde8f08265b28042bcaf5766/psc0/packages/elab/src/Ps/Elab/Declaration.lean) | ff632f3a40b069bfead799b408af009ec9931261 |
| T | [Elab/Term.lean](https://github.com/dwijayuda/pskernel/blob/2b5a4c903ed8a069cde8f08265b28042bcaf5766/psc0/packages/elab/src/Ps/Elab/Term.lean) | ff7896a864a291ffbf1eb3aa70d6004ac86d1112 |
| API | [Compiler/Api.lean](https://github.com/dwijayuda/pskernel/blob/2b5a4c903ed8a069cde8f08265b28042bcaf5766/psc0/packages/compiler/src/Ps/Compiler/Api.lean) | f31d88f0172122d4cf62d62f35f372fe89581c18 |
| SH | [Compiler/Sh1.lean](https://github.com/dwijayuda/pskernel/blob/2b5a4c903ed8a069cde8f08265b28042bcaf5766/psc0/packages/compiler/src/Ps/Compiler/Sh1.lean) | a947a4058e3d91a02d4f8120a3d86556100c8555 |
| AST | [Syntax/Ast.lean](https://github.com/dwijayuda/pskernel/blob/2b5a4c903ed8a069cde8f08265b28042bcaf5766/psc0/packages/syntax/src/Ps/Syntax/Ast.lean) | 4a9daaf4179ca7fa74e9183e542891ec110fd5d7 |
| LC | [Environment/LocalContext.lean](https://github.com/dwijayuda/pskernel/blob/2b5a4c903ed8a069cde8f08265b28042bcaf5766/psc0/packages/environment/src/Ps/Environment/LocalContext.lean) | fcd057e60367c2fa3f9ffcdf7cf5c40a7c5d49a6 |
| RES | [Environment/Resolve.lean](https://github.com/dwijayuda/pskernel/blob/2b5a4c903ed8a069cde8f08265b28042bcaf5766/psc0/packages/environment/src/Ps/Environment/Resolve.lean) | Path read at the pinned source commit |
| ENV | [Environment/Basic.lean](https://github.com/dwijayuda/pskernel/blob/2b5a4c903ed8a069cde8f08265b28042bcaf5766/psc0/packages/environment/src/Ps/Environment/Basic.lean) | Path read at the pinned source commit |
| CTX | [Elab/Context.lean](https://github.com/dwijayuda/pskernel/blob/2b5a4c903ed8a069cde8f08265b28042bcaf5766/psc0/packages/elab/src/Ps/Elab/Context.lean) | Path read at the pinned source commit |
| LX | [Syntax/Lexer.lean](https://github.com/dwijayuda/pskernel/blob/2b5a4c903ed8a069cde8f08265b28042bcaf5766/psc0/packages/syntax/src/Ps/Syntax/Lexer.lean) | Path read at the pinned source commit |
| PC | [Syntax/ParseCommon.lean](https://github.com/dwijayuda/pskernel/blob/2b5a4c903ed8a069cde8f08265b28042bcaf5766/psc0/packages/syntax/src/Ps/Syntax/ParseCommon.lean) | Path read at the pinned source commit |
| FN | [Foundation/Name.lean](https://github.com/dwijayuda/pskernel/blob/2b5a4c903ed8a069cde8f08265b28042bcaf5766/psc0/packages/foundation/src/Ps/Foundation/Name.lean) | Path read at the pinned source commit |
| SUB | [Core/Subst.lean](https://github.com/dwijayuda/pskernel/blob/2b5a4c903ed8a069cde8f08265b28042bcaf5766/psc0/packages/core/src/Ps/Core/Subst.lean) | c8439e444e38b642043f2d18561a77a2bdd420a2 |
| ABS | [Core/Abstract.lean](https://github.com/dwijayuda/pskernel/blob/2b5a4c903ed8a069cde8f08265b28042bcaf5766/psc0/packages/core/src/Ps/Core/Abstract.lean) | 8ac0f21d92538502ee14fc6932eb0f48fda48a85 |
| H | [Published reviewed hygiene correction](https://github.com/dwijayuda/pskernel/blob/3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc/psc0/packages/elab/src/Ps/Elab/Recursion.lean) | ea8518afd0982e64d6fcfcd2320501d89e0385ec |
| HM | [Guarded hygiene manifest](https://api.github.com/repos/dwijayuda/pskernel/git/blobs/fabe10858976ba2fc0d892ef8c0ab20ef227beb6) | fabe10858976ba2fc0d892ef8c0ab20ef227beb6 |

The hygiene correction's bounded independent review covers its exact two-expression invariant repair on the actual caller path. It does not constitute independent closure of this entire normalization argument or any N row. A reviewer should evaluate §§5–7 against the common relations and imported premises before changing any assurance disposition.
