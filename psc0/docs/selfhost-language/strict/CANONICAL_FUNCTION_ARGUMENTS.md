# Canonical function values, actual entry groups, and finite closure placement

Status: source-level rule argument for the reviewed, unqualified canonical-function candidate. This document supplies a reusable local interface to the erasure and backend arguments. It does not close a correspondence-ledger row, activate strict SH/1, establish a fixed point, or replace the required current-source execution and provider receipts.

The implementation uses unary runtime function **values** and keeps a flat parameter vector only at an actual, known declaration entry or an explicitly typed intrinsic bridge. This makes generic type substitution compositional without traversing or rebuilding stored data. A declaration's entry stops where its checked Core value stops being an immediate lambda. Computation producing a returned function therefore executes at its original entry boundary. A separately reviewed source placement change prevents finite helper construction from eagerly traversing an unused fuel bound or a whole lexical suffix.

## 1. Exact source and review boundary

The source baseline is fc961b8a73ff9fccfbe80cdbc488a1fe1edfb504. The following immutable candidates include the canonical representation changes and the reviewed placement overlays. Their attachment to a branch and qualification are separate root-owned actions.

| Source | Exact candidate blob | Relevant definitions |
| --- | --- | --- |
| Erasure/Basic.lean | 7de707103e0b88e6a5ab206ee242d72a131ca3b7 | Entry metadata, catalogue, binder classification, unary runtime type erasure |
| Erasure/Expr.lean | f1ecc9458fe0c606b0a34c321517069cd27280e4 | Known-entry completion, canonical applications and lambdas, special-head boundaries, foldl bridge, checked-Core annotation view |
| Erasure/Definition.lean | 4c9d3878c01751239022e755e2860c6d49ddf301 | Actual entry opening, catalogue installation, Unit transport, removal of result-arrow exposure |
| Syntax/Lexer.lean | 598b8d75d0d1bf1b6ea7ec05a62814343e33599a | Six inherited Nat placements and three streaming-prefix list placements |
| Nat placement manifest | 1530f2bec9a7b66bddd317ff94409297c39adaca | Exact 102 movements in 29 files; one replaced old worker |
| Streaming placement manifest | b6407ad9b00b69dbe9f9db99f557793657a96bd1 | Three additional exact movements over the Nat Lexer candidate |

Read the immutable source blobs through the repository Git-blob API: [Basic][B], [Expr][E], [Definition][D], [Lexer][L], [Nat manifest][NP], [streaming manifest][LP]. Function names below locate rules in those complete contents; the manifest carries exact before/after text, hashes and overlay bases. This is not an assertion that an unattached blob has executed.

The Expr pin includes the independently reviewed two-edit root-IH eligibility overlay on f16cb31b41b890e9c5d4d2d7540d44d1a5f06e12. It preserves the canonical application/type/bridge constructions discussed here. Its recursor provenance rule and the complementary Core constructor-refinement producer correction remain the ER argument's responsibility; this document does not assume that a same-typed nested IH denotes the current declaration.

The shared relation remains the budget-threaded relation in SEMANTIC_RELATIONS.md, blob 40e540b325186ee514ff3af9e39a22126d29a167. This addendum distinguishes its proof bookkeeping from actual source observations. The prior TS and N arguments remain conditional inputs for unchanged rules; their old source identities and old erasure-interface assumptions must not silently be treated as proofs of the new representation.

## 2. The diagnosed representation defect

The old type erasure flattened a function-valued result into its parent's parameter vector. For a type variable alpha it produced:

~~~
E(Nat -> alpha) = Function([Nat], alpha)
~~~

After substituting alpha := Nat -> Nat, simultaneous IR substitution produced:

~~~
Function([Nat], Function([Nat], Nat))
~~~

Erasing that already-instantiated source type instead produced:

~~~
Function([Nat, Nat], Nat)
~~~

Those are deliberately different types in the exact IR checker. A later backend cast, looser function comparison or JavaScript underapplication cannot repair that disagreement. It can occur in a parameter, result, structure field, or a type argument inside List, Array or any admitted regular family.

A second defect used every remaining instantiated Core Pi as an entry slot. A generic identity has one actual runtime parameter, but instantiating its result to a function exposed extra arrows. Both a saturated call returning that function and an overapplication could then acquire the wrong IR call arity.

The supported implicit source witness is:

~~~lean
def groupId {alpha : Type} (value : alpha) : alpha := value
def groupUse (f : Nat -> Nat) : Nat := groupId f 0
~~~

The existing elaborator inserts the implicit type metavariable, solves it from the typed local f, and closes the Core application spine. It does not require a new source grammar. The evidence for that inference is the actual ApplyArgs, FinalizeExpected, Unify and MetaContext paths, not an execution receipt. An explicit grouped arrow type used as an application operand is not substituted as a witness because that is outside the owned Lean argument parser's current boundary.

A merely local saturation patch would leave the first mismatch. Conversely, changing type grouping without respecting entry boundaries would keep the second. The reviewed candidate addresses both and handles function values inside nominal data through the type law below.

## 3. Domain and the substitution law

### 3.1 Runtime type domain

Use the canonical runtime type domain generated by:

- Enabled scalar primitives and Unit.
- A runtime type parameter bound in the current caller scope.
- An admitted regular nominal owner applied to its ordered runtime type arguments, including the existing Array type constructor.
- A nondependent runtime arrow from one domain to one result in this same domain.

The domain excludes unresolved types, first-class polymorphic values, runtime-dependent layouts and a runtime use of an erased proof or type variable. The actual strict checker must accept the resulting types; Basic's raw fallback to unknown is not a member of this domain and is not a successful typing argument. Existing supported proof/type omission and weak-head conversion have their own erasure premises.

Let E_rho be type erasure with source type locals mapped by rho to the corresponding IR type parameters. Define U(A,B) := Function([A],B). The candidate's arrow clause is exactly:

~~~
E_rho(A -> B) = U(E_rho(A), E_rho(B)).
~~~

It does not inspect whether E_rho(B) is another function before choosing the outer group. This clause is inside psEraseRuntimeTypeWithFuelWorker; primitive, parameter and nominal clauses retain their existing meaning.[B]

### 3.2 Simultaneous substitution

For an admitted rank-1 substitution theta and its IR substitution Theta, where Theta(rho(alpha)) = E_caller(theta(alpha)), the local theorem is:

~~~
E_caller(T[theta]) = SubstIR(Theta, E_rho(T)).
~~~

The theorem is about the supported type structure after the existing checked-Core conversions. It assumes those conversions and binder-mode classifications are valid for the admitted input. It does not claim arbitrary dependent Core terms normalize to that structure.

The proof is structural.

For a scalar, both sides retain the same scalar. For a substituted type parameter, IR substitution returns the chosen caller replacement unchanged; it does not recursively reinterpret names inside that replacement as callee parameters. This is exactly the simultaneous-substitution requirement, including the case in which two scopes print a parameter as T0. For an unsubstituted parameter, both sides retain the corresponding scoped parameter.

For a nominal application D(T1,...,Tk), both sides retain the same resolved owner and arity and apply the induction hypotheses pointwise to the ordered type arguments. No field values are visited. For U(A,B), substitution preserves the one-element parameter list and applies the induction hypotheses to A and B. Thus a function introduced inside B by substitution remains the result type of that one-parameter function on both sides. This is the clause the old flattening violated.

Recursive layouts do not make this induction infinite: a nominal type expression contains an owner and a finite type-argument list, not an unfolded runtime value or recursively expanded field graph. Field layout instantiation then uses the same substitution on its stored field type. Erasure's constructor, projection and match-field rules must identify that stored type correctly; that association belongs to the ER layout argument. Once it does, no runtime transport of nested Lists, Arrays or recursive values is required.

This proves representation compatibility for the admitted types. It does not replace exact IR type checking, create a new coercion, or establish typing completeness outside the current source/type domain.

## 4. Actual declaration entries

### 4.1 Catalogue invariant

PsErasureEntryInfo stores the ordered original binder modes, the number of runtime slots, and the number of type slots. The catalogue is an additional field of PsErasureDeclarationNames; it does not change the existing byCore/byOutput name mapping or count semantics.

psErasureEntryInfoWithFuel inspects the aligned **raw** type/value prefix. It takes a step only when the type is a forallE and the value is a lam. It classifies the original domain in the current local context, pushes the same binder, opens the type body with the fresh free variable, and continues. It stops immediately at any other value root, including a let, application, match/recursor application or computed function result.[B]

The invariant after k steps is: the accumulated modes are exactly the first k aligned original slots; the counts are their runtime/type counts; the local context and opened type are the ones obtained by those k binder openings; the remaining value has the same outer lambda spine as actual definition opening.

The helper peels the raw value body without repeatedly substituting through that entire body. This is sufficient for this invariant because it inspects only root lambda constructors. Replacing a bound variable by a fresh free variable cannot create or remove a lambda root. Domains and dependence are read from the separately opened type, not from the uninstantiated value body.

Structure-recursor lowering preserves this raw prefix: it reconstructs a lambda as a lambda; an application remains an application or becomes the reviewed structure-major let; no other root becomes a lambda. Consequently catalogue construction before that lowering and definition opening after it count the same actual prefix. This is a source-shape argument, not an assumption that arbitrary normalization preserves all entry groups.

The declaration-index worker adds definition and partial-declaration entries, skipping a proposition-valued declaration exactly as definition erasure does. Current strict source admission has its own partial-declaration refusal. The raw helper's ability to represent a partial declaration does not activate partial source definitions in SH/1.

### 4.2 Installation and fallback

psEraseCoreModuleWithRuntimePrelude installs the catalogue once for runtimePrelude ++ declarations, before structure/inductive preparation and definition erasure. Scope updates preserve its entries field. The two output-name reservation constructors preserve that same field.[D][E]

A direct raw expression-erasure caller can provide an ordinary name scope without this module prepass. psErasureResolveEntry then consults the actual environment declaration and runs the same prefix helper on its raw type and value. It never guesses entry arity from the fully instantiated result type. A direct single-definition caller can encounter a self axiom before installing its actual value in the environment; psErasureEnsureDefinitionEntry fills only that missing entry from the supplied type/value. These are exact source-data fallbacks, not a second calling convention.

For the normal module path, a successful cache lookup and a recomputation agree by the same prefix invariant. A caller-provided inconsistent catalogue is not an admitted compiler-owned scope; exact subsequent IR checking remains required at public raw boundaries.

## 5. Values, entries, and application saturation

There are three representations with different roles:

| Object | Representation |
| --- | --- |
| Ordinary runtime function value | Unary arrow and unary lambda/call |
| Known declaration entry with runtime slots | Flat ordered vector for exactly its actual aligned slots |
| Type-only generic entry | The same logical zero-runtime entry, transported physically by one ignored Unit parameter |

A runtime local, a projected function field, an application result and a returned closure all use the first row. Taking a known entry as a value constructs the appropriate canonical closure; the flat entry itself is not installed as an ordinary value with a falsely unary type.

### 5.1 Saturated and overapplied known entries

psEraseKnownEntryApplication splits the Core argument list at the length of the cached original binder-mode list. Its existing argument worker traverses that prefix's actual Pi domains in order, recording type arguments, runtime arguments and runtime-domain annotations while omitting proof arguments according to the existing mode rules.

If all original slots are supplied, psEraseFinishEntryWithFuel emits the physical entry activation. The caller then checks exact type/runtime counts against the catalogue. Any remaining original Core arguments are handled by psEraseCanonicalArguments using the instantiated result type. The result's new function arrows never become additional entry parameters.[E]

For groupId f 0, the first activation therefore supplies one type argument and f to groupId. Its result has the unary type of f; the remaining 0 applies to that returned value. For groupId f alone, the returned value is retained immediately; no missing-entry parameter is invented.

A monomorphic entry with no runtime slots is the module's initialized value and needs no synthetic empty call. A nonempty actual runtime vector is passed in its original retained order. The new helper does not use JavaScript function length, annotations guessed from the final instantiated type, or backend underapplication to select these source rules.

### 5.2 Partial known entries

Only unsupplied original entry modes are eligible for completion. Missing runtime modes create typed fresh parameters. Missing proof modes extend only the erased Core context. An unsupplied type mode is refused rather than exported as a first-class polymorphic runtime function.

The helper retains the already supplied runtime operands and appends variables for missing parameters to the eventual flat entry call. It wraps that call with one unary lambda for each missing runtime slot, from last to first. The resulting type is the same unary telescope guaranteed by Section 3.

Computed supplied operands are evaluated once by fresh typed outer lets before those completion lambdas. The capture pass processes the callee first and then supplied runtime arguments in order. Direct immutable variables and literals can remain as values without a let; moving their lookup beneath a fresh lambda introduces no computation or mutable observation in the admitted environment. A computed operand, including a constructor, projection, application or function-producing expression, is captured.

psErasureWrapApplicationCaptures reverses the construction order correctly: the stored reverse binding list wraps the original first capture outermost. Thus the same first failure occurs and later supplied computations remain suppressed. A saved partial application reuses the captured values; it does not recompute them on each later invocation.

Fresh completion parameters are already included in the scope used to allocate capture names. Output reservations retain the catalogue. The ER name argument must supply the usual actual-source non-capture property; these helpers do not weaken that requirement.

## 6. Demand and immediate lambda prefixes

### 6.1 Computed returned functions

For a definition whose actual body after its written parameters is:

~~~lean
let y : Nat := f x;
fun (z : Nat) => Nat.add y z
~~~

the catalogue stops before the let. Definition erasure keeps the opened body's function type as its result and emits that body unchanged in this respect. Completing the original entry evaluates f x and returns the closure. Supplying z later calls the returned unary value. Binding and discarding that value does not postpone the let initializer until a nonexistent z application.

This follows directly from removing psErasureEtaFunction from the definition-result path and from not flattening ordinary runtime-lambda bodies. The old helper remains available as its existing public diagnostic/helper API, but it no longer silently changes those source entry boundaries.[D][E]

### 6.2 Directly nested lambdas at known entries

A known declaration whose actual raw value begins lambda x1, lambda x2, ..., lambda xm can keep the flat entry vector. Each intermediate Core stage binds the already evaluated operand and immediately returns the next closure. There is no let initializer, recursor computation, callback or other body work between those immediate lambdas: such a root would stop the catalogue.

Under immutable canonical environments and successful allocation, contracting or expanding this finite closure-only prefix preserves the result and all authored operand/body computations. Callee lookup is fixed to the known declaration. Operands keep their order. The body begins after the same final retained slot is supplied. A partial prefix returns a canonical closure carrying the supplied values.

This is a local finite administrative-conversion law. It does **not** permit moving an arbitrary function-producing computation across a later argument. Canonical applications to local/computed values retain nested unary calls and therefore retain their Core call-by-value stage order: the inner application completes before the outer argument is demanded.

### 6.3 A concrete alignment machine

For ordinary function application, the Core operational computation used here is the independent environment-and-closure call-by-value computation: it evaluates its callee and operand, beta application extends that closure's environment, and a returned closure is a value. This clause does not assign a demand rule to a designated Core eliminator, conditional or special head merely because it is encoded with application nodes. Those heads use their separately justified operation-specific rules; the selected-branch rule for a conditional and the demand for a recursor's hypotheses remain ER/runtime obligations. The rules are not defined by calling the eraser. An ordinary multi-operand function spine is the ordered series of those Core applications; original syntax grouping and explicit-empty-call refusal remain properties of the source AST and its actual elaboration.

For a known declaration d with aligned raw lambda prefix x1,...,xm, define a **residual entry view** Entry(d,k,v1,...,vk,rho), for 0 <= k < m. It denotes exactly the independent Core closure obtained by supplying the first k values to that immediate prefix in environment rho. This is a mathematical view of an existing closure, not a new Core term or an axiom about its body. Section 4 proves the prefix used by the compiler is that prefix. Section 6.2 proves the beta steps between successive residual views return the next closure without authored computation.

Construct Pi by induction on the actual erasure derivation, using the following states and transfers.

| Erasure construction | Core state represented | Aligned IR state and transfer |
| --- | --- | --- |
| Ordinary canonical lambda/application | The actual closure and one beta application | One unary IR closure/call, with the same operand and body environment |
| Saturated direct known entry | Evaluation of the original operands through the immediate prefix, ending at its body | Flat-call argument evaluation with the corresponding already-obtained prefix values, then entry to that same body |
| Proper partial known entry | Entry(d,k,values,rho) after its supplied prefix | Ordered supplied captures followed by the generated unary completion chain |
| One call of that completion chain | The next beta application of the residual entry view | Its unary completion-lambda call; on the last parameter, an internal flat-entry transfer enters the same body |
| Special-head completion | The corresponding partial native primitive/constructor with its already supplied values | Ordered captures and unary completion; the last slot reaches the unchanged saturated special rule |
| Type-only generic Unit transport | The checked type-lambda prefix and then its actual computed body | The Unit control transfer followed by the related body, without a fabricated source runtime operand |
| Fold bridge | The operation's actual callback on already obtained accumulator/element values | The two-parameter bridge control followed by the two original canonical callback stages |

The direct-entry row uses a finite refinement of the IR call-argument state. After operand i has returned, record the same value in its prefix vector and relate it to the Core residual entry view after the immediate beta step. Creating that view does not evaluate the next operand or body. This places all actual operand computation in the same order on both sides, and it preserves a possible failure or divergence in an operand. The intermediate steps being contracted are only those already proved to return immediate closures.

The proper-partial row uses the same per-supplied-slot refinement as a saturated direct entry. After each original operand returns, align its immediate Core beta boundary before demanding the next supplied operand. This applies equally to an operand represented by a capture let and to a total variable or literal lookup whose capture let is elided. For example, in a prefix d x (g Unit) of an entry with at least three retained parameters, the d/x boundary precedes evaluation of g Unit; the refinement cannot move that boundary after all captures. If the allowance ends there, both sides retain that prefix value and suspend before the later operand. After the last supplied slot, return the related residual-entry/completion closure at the actual remaining index. There is no second collective partial-prefix charge. An already returned partial value has the remaining canonical unary type; its next supplied runtime slot is charged by the ordinary unary clause.

A last completion-lambda call is followed by an internal IR call of the flat declaration. Only that **control transfer** is administrative in CI: it realizes the beta application already charged for the completion call. The declaration body is not silent. Every authored call, callback, selected branch, error or divergence inside it is matched by the body induction and remains in the observation. Likewise, a Unit transfer may be silent as an erased type-application control edge while activating a computed body. Silence of the transfer never licenses skipping that computation, assuming it total, or moving it beneath a returned runtime lambda.

For the fold bridge, the synthetic two-parameter lambda entry is administrative in CI; the two canonical callback calls in its body retain the original callback stages and their computations. Its accumulator/element arguments are already obtained values. The callback expression itself was captured once at the original operand position. The existing IR/JS relation separately counts and implements the bridge's actual original-IR call; it must not delete that call merely because CI classifies its source realization as administrative.

This Pi is obtained from actual source identities, the proved raw prefix, and the known IR construction sites in the erasure derivation. It is not inferred from a successful result, a printed JavaScript arity, or a declaration with a similar name. A source-authored call to the same declaration does not become administrative merely because its callee name matches a transfer: its role is determined by that actual construction and continuation. The proof world can carry this association without a new serialized production certificate.

### 6.4 Cutoffs, progress and composition

Use one residual budget within each relation. For each retained Core application stage, evaluation of its operand consumes from the current remainder, and that stage's aligned logical boundary consumes one matched charge after that operand and before a later stage's operand. A flat-entry argument vector or partial-capture sequence is refined at each supplied slot as described above. Erased ghost-control steps are governed by the separate ghost-independence premise; their silence never silences an activated body. A completion, direct-entry transfer, Unit transfer, fold bridge, callback or nested runner never supplies a fresh allowance.

A cutoff can occur in an operand, before any next supplied-slot beta boundary, before a later unary invocation, or inside the matched body. In the first case the operand induction supplies the matching prefix and suspended outer state. In the next two cases the alignment table supplies the corresponding residual closure/argument vector without evaluating a later operand or entering the next body. In the last case the body induction carries the current remainder. Previously obtained captures are weakened to that remainder; they are not re-evaluated. Returned functions use their returned canonical type at the actual residual index.

For the function clause at index n+1, the outer matched application has already decreased to a residual j <= n before an internal completion-to-entry transfer. Apply the expression/body preservation statement for the actual declaration body at that lower index j, with the established opened environment. Do not invoke an opaque global-function hypothesis a second time and silently spend another charge. This is the same mutual index/body induction used for authored closures: the transfer's code identity is supplied by ENTRY-PREFIX; ordinary calls inside the body still decrease the index. An arbitrary computed callee has no such administrative shortcut.

No claim that CI and IJ use the **same number** for every finite observation is needed or generally correct. IJ counts the inserted original-IR completion/entry/bridge calls according to its own rules. CI projects those implementations onto the original Core groups and beta-body boundaries as just described. The elementary composition statement is about complete, cofinal finite observations of their common IR computation, not an unjustified same-index transitivity rule.

Concretely, take a finite observed prefix on either side. The alignment table expands it into a finite prefix on the other: the relevant parameter, capture and slot lists are finite, and each transfer adds only a finite sequence of lambda creation/binding/control steps before entering the related body. Choose an initial budget larger than the finite number of licensed interactions needed for that prefix, retaining whatever result index is required. For the whole-program composition, the starting environments and supplied canonical value families are related at all required indices, as established by the value/environment part of the mutual compiler argument; a single finite-index input hypothesis is insufficient. The all-indices CI and IJ statements then cover that same common IR prefix with their respective budgets. Downward closure supplies any smaller required result/capture index. This argument permits input-dependent finite expansion; it does not assert a universal constant ratio between the two counts.

The administrative-progress measure is local and concrete: remaining prefix/completion slots, remaining capture wrappers, or the finite fixed sequence of a Unit/fold transfer. A completion consumes a slot and either returns the next closure or enters the original body. A transfer cannot recursively repeat its own administrative bookkeeping without either consuming another finite slot or making a step in the related original computation. Entering an authored body or callback is a return to its simulation, not a claim that the entire body terminates. Thus this alignment introduces no infinite unmatched administrative stuttering and requires no new assumption that all callbacks terminate.

This establishes the local Pi and its cofinal-prefix transport for canonical types and actual entry/curry/bridge constructions. The EV/TS runner induction can consume it with its own original-IR event schedule; the Core/IR proof consumes the source-side schedule. A finite fixture is unnecessary to the argument and cannot substitute for it.

The remaining whole-compiler premises are narrower than an open regrouping guess. The actual source elaboration must relate its typed AST to the independent prepared Core computation; ghost omission must preserve runtime independence; and N/ER must prove the actual recursor/IH computation, not identify an arbitrary same-typed recursive result with the current declaration. None of those follows from Pi. In particular, the construction above does not repair or conceal a wrong IH substitution, and the global correspondence claims remain false until that independent rule is resolved.

The source grammar still distinguishes native groups and an adjacent inner call and preserves their canonical syntax. Maximal Core-spine analysis may contract only the immediate closure-only prefix justified above; it may not cross a computed function result. If a proposed contract instead makes every pure closure allocation, every physical call, or an arbitrary foreign getter/exception a source observation, this Pi is not a proof of that stronger contract. Those observations are excluded by the existing canonical immutable host domain, rather than erased ad hoc to make this implementation pass.

## 7. Type-only generic activation

Removing arbitrary result-arrow exposure makes a legitimate case visible: an actual prefix containing type parameters but no runtime parameters can compute a function-valued or data-valued result. The IR's existing generic scheme rules deliberately reject a generic initialized value with zero runtime parameters.

The candidate preserves that rule. Definition erasure adds one fresh, ignored parameter of the existing Unit type exactly when the opened runtime parameter list is empty and its type-parameter list is nonempty. Its body and result remain the opened body/result. The physical parameter is not added to the Core context or currentDefinition.runtimeParameters.[D]

The matching entry predicate uses logical runtimeArity = 0 and typeArity > 0. After the actual ghost prefix has been supplied, psErasureEntryCall invokes the entry with its explicit type arguments and the existing Unit literal. There is no synthetic source argument and no reinterpretation of source f(). Ordinary monomorphic zero-runtime declarations remain initialized values.

The Unit parameter is a transport device for the existing polymorphic function scheme. Its freshness check uses the current reserved-name scope and the body name scan, and its value is unused. Its introduction contributes only administrative work. Computation of the result happens on that type-only activation; the result's arrows remain returned values. This avoids both a free TypeScript type parameter in a constant and a new semantic delay under a returned lambda.

The logical and physical arities must therefore be reported separately in fixtures and evidence. Changing an expected runtime arity from zero to one without identifying this exact predicate would be an invalid ABI adjustment. No other zero-argument or generic-value gate is relaxed.

## 8. Installed special heads

### 8.1 Fixed boundary inventory

The new descriptor contains exactly the same 43 named primitive heads as the existing psErasePrimitiveApplication dispatcher: no missing, extra or duplicate name. The complete old dispatcher is byte-identical except that Array.foldl calls its new typed bridge helper.

| Original Core slots | Heads |
| --- | --- |
| 1 | Int.ofNat, Int.repr, Int.negSucc, Int.neg, Nat.succ, Bool.not, Char.ofNat, Char.toNat, String.Pos.Raw.mk, String.Pos.Raw.byteIdx, String.singleton, String.Internal.length, String.utf8ByteSize |
| 2 | Int.add, Int.sub, Int.mul, Nat.add, Nat.sub, Nat.mul, Nat.div, Nat.mod, Nat.beq, Nat.ble, Nat.blt, Bool.and, Bool.or, String.push, String.Internal.append, String.Internal.next, String.Internal.get, String.Internal.atEnd, Array.emptyWithCapacity, Array.size |
| 3 | String.Internal.extract, Prod.fst, Prod.snd, Array.push |
| 4 | Array.getInternal, Array.getD, Array.setIfInBounds, Array.map |
| 5 | Array.set |
| 7 | Array.foldl |

The numbers count original Core slots, including erased slots. Prod.fst/snd have two type slots then the product value. Arrays retain their existing type positions, runtime operand positions and proof omissions; Array.getInternal and Array.set retain their final proof slot.

Prepared structure/constructor descriptors use the same original parameter-plus-field count as their unchanged saturated lowering. Prepared recursors use parameter count + motive + minor count + major. Ite uses its existing five-slot boundary. Their full/overapplied paths therefore preserve the original ghost, branch and recursor handling; they do not turn lazy branch bodies into ordinary eagerly evaluated argument expressions.

### 8.2 Completion and overapplication

At exact arity, psEraseSpecialBoundary returns control to the existing dispatcher. Above that arity, it erases the exact saturated prefix through that dispatcher and applies any resulting canonical function value to the suffix. This matters for a projected or selected function result.

Below that arity, installed primitives and prepared constructor/structure heads use a shared typed completion traversal of the original telescope. Supplied runtime computations become ordered outer captures. Fresh Core lets retain their source values for type substitution, while runtimeExpressions maps each fresh ID to its one captured IR value. Missing runtime slots become unary lambda parameters. The fully completed Core special expression is then erased through the unchanged saturated dispatcher. It is not reimplemented with a second set of arithmetic or constructor templates.

This covers ordinary monomorphic values such as Nat.add 1 and Option.some instantiated at Nat. Missing type slots are refused; no first-class generic scheme is fabricated.

Partial dependent recursor and ite values retain the existing explicit refusal. This local completion proof is for the named installed primitive/constructor domain, not a general theorem that every partially instantiated dependent eliminator is covered by the mandatory language. The remaining coverage ledger must state its actual source domain; this document does not disguise that boundary as universal dependent-function support.

## 9. Array.foldl and callback reentry

The exact existing intrinsic checker signature takes type arguments in **element, accumulator** order. Its runtime operands are:

~~~
[ Function([accumulator, element], accumulator),
  accumulator, Array(element), Nat, Nat ]
~~~

The canonical source callback instead has type:

~~~
Function([accumulator], Function([element], accumulator)).
~~~

psEraseArrayFoldl first lowers the same two type slots and the same five ordered runtime slots. It captures the callback in a fresh typed let outside the intrinsic. At runtime that capture occurs before the initial accumulator, array and range operands, preserving the callback operand's original position. It then constructs an explicit two-parameter IR lambda:

~~~
(acc, element) => capturedCallback(acc)(element)
~~~

The outer capture prevents re-evaluating a computed callback expression for each fold iteration. The two fresh bridge parameters have the checker's exact types and order. The body makes two canonical unary calls and returns the accumulator type. The remaining intrinsic operands are unchanged. Array.map already has a unary callback and needs no bridge.[E]

For each iteration, the bridge invokes the same captured source function on the same accumulator and element, in that order. Its own closure creation and parameter bindings are finite administrative work. Any authored computation between the callback's unary stages stays between those stages. Existing intrinsic iteration, range, immutable-array, first-error and native-contract laws remain separate unchanged premises.

The generated lambda participates in the existing registered-generator/runner convention. A synchronous host intrinsic callback can reenter the runner through its ordinary wrapper; the inner invocation uses its own local continuation stack, returns or throws synchronously to the caller, and does not overwrite the outer runner's suspended context. That is the previously reviewed TS runner/reentry rule. This adapter adds no callback queue, asynchronous event, mutable cache or alternate runner.

## 10. Checked-Core annotations

The added psErasureCheckedTypeViewWithFuel recovers an annotation from already checked, prepared Core. For an application it obtains the callee's actual Pi type and instantiates its body. For a lambda it extends the context and rebuilds its Pi result; for a let it opens the body type and substitutes the original value; projection metadata still uses the existing projection-type operation. Ordinary leaves retain the existing inference path.

This avoids repeating the conservative read-only argument comparison that rejected a closed generic lambda annotation because of structurally different but already checked universe expressions. It does not accept source, solve new metavariables, change Meta/Reduce/defeq, or replace checking of the final exact IR. Its soundness premise is the checked-Core type derivation supplied by the upstream pipeline; raw malformed Core remains outside this annotation lemma.

The helper's new recursive function has all of its value arguments before the Nat dispatch. It does not add an eager fuel-closure chain. Its three call sites supply result annotations for runtime lambdas, projection targets and computed application heads; all mode, layout and target checks remain separate.

## 11. Finite closure placement: exact rule

### 11.1 Authorized movement

The old compiler source commonly uses this finite factory shape:

~~~lean
def worker (fixed : Fixed) (fuel : Nat) : State -> Result :=
  match fuel with
  | 0 => fun (state : State) => ZERO_BODY
  | remaining + 1 =>
      let smaller : State -> Result := worker fixed remaining;
      fun (state : State) => BODY
~~~

With canonical returned-function boundaries, constructing worker fixed fuel evaluates the recursive factory before returning the state closure. For a large default bound this can construct thousands of closures before any state is inspected.

The reviewed movement is only:

~~~lean
  | remaining + 1 =>
      fun (state : State) =>
        let smaller : State -> Result := worker fixed remaining;
        BODY
~~~

All existing consecutive returned state lambdas are crossed together. Public headers, complete Core types, fixed/major inputs, zero policies, defaults, recursive operands and the active BODY are unchanged. This is source binder placement; it does not add a backend optimizer or change a reduction/cache/checking algorithm.

### 11.2 General construction proof

Induct on the finite Nat major. At zero the source returns an immediate state lambda without evaluating ZERO_BODY. At successor, the only moved recursive construction uses the same already bound fixed operands and the actual predecessor. By induction it terminates with the smaller function value without evaluating state-dependent body work. The branch then returns its immediate lambda. Hence the moved prefix is finite pure closure construction under successful allocation.

Commuting this prefix with the existing state-lambda construction preserves the function's behavior. On activation, the same smaller value is bound before the identical BODY. If an outer operand fails before activation, the only suppressed work is that finite pure construction. Authored callback, error, state and body demand order is unchanged. This is not unrestricted call-by-value zeta reduction across a lambda.

Both capture directions are required. Newly crossed state parameter names occur in neither the moved RHS nor its type annotation. Moved binding names are neither rebound by a crossed parameter nor free in a crossed parameter type. The fixed self-call operands remain the original header variables, with only the structural major replaced by the actual predecessor.

There is one explicit non-recursive companion binding in psParseLeanProductWithNomatchWithFuel. It chooses, by an already obtained Bool, between already obtained function values. It invokes neither function. It moves after smaller in the same original order. No other computed-prefix generalization is included.

### 11.3 Frontend and recursion identity

The owned frontend accepts the same typed let after an existing typed lambda. Lambda and let context extensions preserve the structuralRecursion metadata. The existing self call retains its fixed-argument IDs, strict child ID and major position; only fresh auxiliary let/state IDs can be allocated in a different order. Capture checks make these contexts alpha-equivalent for the body.

The structural-call validator checks those actual argument identities and strict-child provenance, not the relative text position of the let. Consequently the same successful call still selects the same hypothesis. In elaborated recursor terms, the smaller value can already be a resolved IH value; the source movement is then even more directly the placement of that immutable binding. Neither case relaxes structural recursion validation.

The exact packet has 102 movements in 29 files: 90 fuel functions and 12 other Nat count/index/value functions. Its original inventory had 103 members; psEraseFinishApplicationWithFuelWorker is explicitly eliminated by the separately reviewed canonical entry implementation, whose replacement has its value arguments before dispatch. The new catalogue helper's own narrow construction placement was separately reviewed before this packet.

Every before/after guard is unique, every full candidate reverses to its stated base, and all candidate blobs were read back exactly. Independent review checked every source row and overlay. These checks establish the specified source edits and the rule's premises; they are not compiler execution evidence.

## 12. Three streaming-prefix list readers

The Nat proof does not automatically cover a list or tree major. A separate List-tail induction covers exactly psLexReadIdentifier, psLexReadNatural and psLexSkipLineComment.

Their nil branches immediately return their state lambdas. A cons branch originally constructs only self(rest), then returns its lambda. Predicate, newline test, position update, accumulator work and returned cursor are all inside that lambda. On a proper finite list, induction on the strict tail proves the same finite pure-construction premise. The same bidirectional capture checks hold.

The practical difference is source-proven: the original factory visits the **entire remaining source suffix** before testing whether the first character is a delimiter. psLexReadToken supplies that suffix for each identifier or numeral; both trivia paths supply it after each line-comment prefix. Repeated bounded-size tokens/comments therefore incur a quadratic sum of suffix lengths in this closure-construction component. Moving the binding below the existing state lambdas constructs only the reader stages that are activated, plus at most the boundary stage.[L]

The exact three edits retain all nil cases and active suffixes byte-for-byte, including delimiter retention and source positions. They overlay the six already reviewed Nat Lexer movements. No source, grammar, fixture, reference, numeric bound or error behavior is changed.

This does not establish total lexer linearity. Existing string/block-comment wrappers still compute their original length-based bounds. Character-literal readers inspect bounded immediate prefixes. The remaining 169 list/tree factory occurrences in 128 functions are inventoried and unmodified: full traversals have input-sized construction; some equality/search helpers can still construct beyond a short-circuit prefix. Generic JSON's digit reader remains outside this bounded raw-source lexer correction. No evidence in this packet justifies another broad optimization batch.

## 13. Interfaces exported to the other arguments

The local results established here are:

1. **U-SUBST:** unary runtime type erasure commutes with admitted rank-1 simultaneous substitution, structurally under nominal type arguments.
2. **ENTRY-PREFIX:** cached and fallback entry descriptions match actual aligned raw Core definition opening; computed results do not enlarge the entry.
3. **ENTRY-CALL:** complete, partial and overapplied known entries use exactly that boundary; supplied computed partial operands are captured once in order.
4. **LAMBDA-ADMIN:** only the finite immediate lambda-only prefix can be contracted into a known flat entry without moving authored computation.
5. **GHOST-UNIT:** the narrowly defined generic zero-runtime entry uses an ignored Unit physical parameter without changing its logical prefix or returned-value demand.
6. **SPECIAL-BOUNDARY:** the enumerated installed primitive and prepared constructor domain completes/splits at its actual fixed Core boundary while reusing the old saturated rules.
7. **FOLD-BRIDGE:** the one required binary intrinsic callback bridge preserves its canonical callback value, operand order and unary stage behavior.
8. **FINITE-PLACEMENT:** the exact 102 Nat and three lexical List-tail movements commute only finite pure construction with existing state lambdas under the checked capture/recursion conditions.
9. **ENTRY-PI:** the concrete residual-entry alignment and finite administrative progress justify canonical entry/curry/bridge groups and cofinal CI/IJ observation transport without assuming equal physical call counts.

These are general rule arguments, not deductions from the new examples. Their consuming ER/EV/TS proofs still supply checked-Core typing and conversion, actual binder-mode classification, proof-domain erasure, layout/field association, name hygiene, recursor/IH correspondence, canonical scalar/collection laws, module initialization, and runner/progress facts. The explicit call-event projection and cofinal-prefix transport in Sections 6.3–6.4 discharge the local canonical entry/curry/bridge grouping interface. Actual source-to-Core adequacy, ghost independence and recursor/IH semantics remain separate consuming obligations.

Qualification additionally needs the actual current-source compiler generations, exact original-IR admission, TypeScript compilation, runtime observations, fixed-point products, native comparison and the independent selected provider evidence. The bounded resource policy and checkpoints can measure the new preparation path; this source proof does not predict its peak heap or claim that the previous OOM has been fixed.

Strict qualification: **false**. Complete semantic proof: **false**. Correspondence rows closed by this document alone: **zero**.

[B]: https://api.github.com/repos/dwijayuda/pskernel/git/blobs/7de707103e0b88e6a5ab206ee242d72a131ca3b7
[E]: https://api.github.com/repos/dwijayuda/pskernel/git/blobs/f1ecc9458fe0c606b0a34c321517069cd27280e4
[D]: https://api.github.com/repos/dwijayuda/pskernel/git/blobs/4c9d3878c01751239022e755e2860c6d49ddf301
[L]: https://api.github.com/repos/dwijayuda/pskernel/git/blobs/598b8d75d0d1bf1b6ea7ec05a62814343e33599a
[NP]: https://api.github.com/repos/dwijayuda/pskernel/git/blobs/1530f2bec9a7b66bddd317ff94409297c39adaca
[LP]: https://api.github.com/repos/dwijayuda/pskernel/git/blobs/b6407ad9b00b69dbe9f9db99f557793657a96bd1
