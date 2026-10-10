# Backend correspondence: conditional rule arguments

## Status and exact boundary

This review develops the evaluation, scope and control arguments behind the enabled PSC0 TypeScript backend. It is a source review, not an executed receipt, a kernel theorem or a completed end-to-end preservation result. The 33-row [correspondence ledger](correspondence-obligations.json) remains open. In particular, a backend argument cannot establish that source elaboration or erasure selected the correct variable, field, argument or constructor.

The implementation boundary is:

| Source | Immutable blob | Relevant definitions |
| --- | --- | --- |
| BackendTs/Module.lean | fa6491f4861ddc59caba51c03a29790fc6e8653b | General declarations, eta rewrite, count loop, tail loop, generator runtime, module order |
| BackendTs/Expr.lean | dfd58154826c892d18b97b84303abbce6a622d7b | Next two-template correction; general expression and let/match emission otherwise unchanged |
| BackendTs/Sh1Target.lean | a0e7031d8a5e969fad44ab82b80aecbcc88f1139 | Actual names, namespace, depth and initialization admission |
| CompilerIr/Check.lean | 94b80cd7fe617e62c9a95446ff019e088d57b0b3 | Original-IR scope, exact groups, constructor field order and layout checks |
| Erasure/Basic.lean | e0c932e0280b9c0e2b7f7ad1974b548881f452d0 | Actual local-name and declaration-name indexes |
| Erasure/Definition.lean | 709fc44f59bddb3c3d7354ba31ea01f296c9cde8 | Ordered module/prelude declaration-name preparation |

The first, third, fourth, fifth and sixth files are unchanged from source commit 05f37fc04e52bfaed70389291a0fcdeda819f71f. The expression candidate changes only stringAtEnd and arrayEmptyWithCapacity relative to that commit. The separate Nat-major and partial-application repairs belong to erasure, before the backend relation considered here. The [runtime-law review](RUNTIME_LAW_REVIEW.md) owns the detailed 45-operation arguments and their representation/resource assumptions.

The argument below is conditional on the actual accepted domain. It must not be advertised as a theorem for arbitrary JavaScript objects, arbitrary typed original IR, or full PSC1.

## 1. One relation for values, environments and calls

Use the original IR's runtime type as the relation index. Nat and Int share the bigint carrier but have distinct domains. Char and String share the string carrier but have distinct scalar-sequence domains. A function with one parameter returning another function is different from a function with two parameters in one group. These distinctions come from the IR type model and checker; erasing the TypeScript annotations does not remove them from the argument.

A related runtime environment maps each original-IR local/global identity to the JavaScript value denoting that identity. Scalar relations are those in the enabled runtime contract. Record and constructor relations additionally specify the exact owner, private brand/tag, field names, field order where positional construction is used, and the element relation for each field. Arrays are ordinary dense immutable source values with related elements; Unit may be represented by an explicitly present undefined element.

For a lambda, relate the IR closure's captured environment and ordered parameter group to the generated function and its registered generator implementation. The function relation must cover application to every related argument tuple of that group. For a returned function, the result relation is another function relation; it is not an implicit completion of the previous group.

To avoid a circular claim that calls are correct because closures are correct, formulate the relation with an explicit observation index or a small-step simulation. At index zero no future application result is required. At a successor index, related function application must match the next observable evaluation/call step and continue under a smaller index. This supports nested calls and structural recursion without inventing a separate termination proof from a successful finite run. A final proof must fix one such formulation consistently across ER-04, EV-04/05 and TS-04.

Observable obligations are the declared values, constructor/field interpretation, capture, operand order, demand and explicit faults. Generator bookkeeping, private WeakMap lookups and temporary variables are silent implementation steps. Physical allocation success, stack capacity, elapsed time and identical allocation timing are not equated. This does not permit duplicated source computation: the existing Nat and partial-application corrections address that separate demand obligation.

These paragraphs define the premises and proof shape. They do not certify the missing source/Core-to-IR relation or mechanize a new evaluator.

## 2. General expression emission: all eleven constructors

The general worker is psTsEmitExprWithFuel. Failure or fuel exhaustion is an emission refusal. The following arguments concern its successful result, after complete original-IR checking and the actual target gate.

| Original-IR expression | Conditional simulation argument |
| --- | --- |
| literal | psTsEmitLiteral must produce the exact related primitive value. Its escaping, canonicality and integer laws belong to the runtime/literal boundary. |
| var | The printed identifier reads the value associated with the same IR environment entry, provided the environment/name relation holds. |
| intrinsic | Child source computations must occur with the operation's required demand/order; the resulting template must satisfy the enabled operation law. The 45-law review supplies the separate case analysis. |
| lambda | __ps$wrap records a generator implementation closing over the current environment. Constructing the function does not execute its body; invocation binds the same ordered parameter group. |
| call | The emitted __ps$invoke argument list evaluates the callee first and the runtime arguments left to right. It then yields one request carrying those values. Type arguments are compile-time annotations. |
| letE | The initializer is computed once in the old environment; the body uses the resulting binding. The two scope-sensitive templates are justified below. |
| ifE | The conditional evaluates the condition once and only the selected branch. Emission traverses both branches to build text; that compiler traversal is not runtime demand. |
| record | The object expression evaluates field expressions in the IR field list order and stores the matching property names. Its private brand is an additional unobservable representation field. |
| projection | The target expression occurs once. The selected property denotes the same field only under the record-layout relation. |
| constructor | The public constructor object/factory selects the related owner/tag and receives fields in checked positional order. Nullary nongeneric constructors may share one immutable value. |
| matchE | A fresh const receives the scrutinee once; the private tag selects one case; only that case binds the specified fields and evaluates its body. |

There is a concrete check for constructor positional order. In psIrCheckConstructor, the actual field list is compared with psIrCheckConstructorParameters using psIrCheckFieldOrder. A mismatch records constructor-field-order. Thus the backend does not merely trust field-name membership before discarding names for the factory's positional argument list. This closes that local IR shape question. It does not prove that erasure associated the correct source field with each original-IR field.

Record construction instead emits the field names from the IR pairs, so its ordering obligation is the IR field order. The separate source record/Core construction rule must explain any earlier ordering of named source fields.

A related constructor value has exactly its family's tag and fields. The default invalid-tag throw is defensive behavior outside that relation; it is not evidence that an earlier source value was impossible. Mandatory empty-data/match coverage remains a separate open scope issue.

## 3. Let initializers and lexical capture

psTsEmitLetStatements handles a let chain by inspecting whether an initializer uses the new binding's printed name. psTsExprUsesNameWithFuel visits both variable occurrences and binders in all eleven expression forms. At fuel exhaustion it returns true, so uncertainty chooses the more conservative template.

If the name is absent from the initializer's explicit variable/binder syntax, the emitter places a const declaration and the rest of the body in a block. This case also requires protection of implicit emitted names: a constructor expression prints its inductive namespace even though the name-use walk does not inspect that namespace as a variable occurrence. The source/name relation must prevent a local binding from capturing that namespace, while target admission separately protects actual runtime/helper/private names. Under both premises, the initializer cannot accidentally read the new const's temporal-dead-zone binding.

This is a real premise distinction. An arbitrary typed IR let named D with initializer constructor D.c can evade the explicit name walk and print a self-referencing const. That observation alone is not a source-reachable defect: psBuildErasureDeclarationNamesWorker includes inductive declarations as well as definitions/partials/theorems, and psEraseCoreModuleWithRuntimePrelude builds that index from the actual runtime prelude plus source declarations before local names are chosen. A complete ER-09 argument must show that every generated local uses the protected mapping. Target admission and typing alone do not prove that stronger fact.

If the name occurs, the emitter passes the initializer as an argument to a new generator function whose parameter introduces the new binding. The argument expression is outside that parameter's scope. It therefore sees the old environment; only the generated function body sees the new value. A suspended initializer call remains in its surrounding generator context and completes before the parameter is bound.

This covers the local binding mechanism, including a closure in the initializer that captures the old same-named value. A closure in the let body captures the new binding as intended. Nested let blocks give distinct lexical bindings rather than overwriting one shared mutable slot.

The tail optimizer independently refuses an initializer whose value uses the new name. It falls back to the general mechanism instead of reproducing the risky const transformation. The complete source binding relation is still ER-09; syntactically correct JavaScript scoping cannot repair an incorrect earlier Core-to-IR identity.

## 4. Eta inlining: a restricted local rewrite

psTsInlineEtaApplication recognizes only an original-IR call with no type arguments. psTsEtaArgumentsFresh requires every supplied argument to be a variable, and rejects the rewrite if any argument name occurs anywhere in the callee expression, including its binders. It does not move arbitrary computations through the callee.

psTsEtaApplyWorker succeeds only through these callee forms:

1. A lambda whose parameter list can be paired exactly with the supplied arguments.
2. A let whose body can be transformed; its initializer and binding remain in place.
3. An if whose two branches can both be transformed; its condition remains in place.
4. A match whose every branch can be transformed; its scrutinee, alternatives and field bindings remain in place.

Other forms or exhausted fuel return none, and the original expression is emitted.

The argument is by induction over a successful recognizer derivation. At a lambda, psTsEtaBind produces nested lets in parameter order. Freshness ensures that binding an earlier parameter cannot capture a later argument variable. Exact list pairing preserves arity. At let/if/match, the outer computation is unchanged and the induction hypothesis applies to the body or selected branch. Because each argument is an already available variable and its name is absent from the crossed explicit syntax, reading it after the unchanged callee computation preserves its environment binding under the protected implicit-namespace/source-name premise from section 3.

This is a backend rewrite of an explicit IR call. It is not the source erasure completion that creates partial-application lambdas. The latter must first capture already supplied computations outside its newly constructed closure; the backend eta rule cannot be used to justify their deferral or duplication.

The target depth domain weights lambda parameters to account for the extra lets a recognized eta rewrite may introduce. A complete assurance argument must combine that accounting with the exact recognizer derivation, not assume that ordinary unweighted source depth bounds every rewritten expression.

## 5. Count-loop specialization

The recognizer does not inspect a convenient source function name. It checks a declaration returning Nat with exactly one runtime parameter. The body must be a match directly on that parameter, with exactly two alternatives. One alternative must be literal zero. The other must be natAdd of literal one and a call, in either operand position.

The call must have exactly one runtime argument, which is a variable selected from the branch's field bindings. Its callee's printed name must equal the declaration's printed name. psTsCountField resolves that selected variable to the actual field property used by the emitted loop. If any shape check fails, the count specialization is declined.

For an actual self call and related finite constructor data, use the invariant:

> At the beginning of a loop iteration, the original call's result equals the current accumulator plus the result of the same declaration applied to the current cursor.

Initially the accumulator is zero and the cursor is the original argument. In the zero branch, the recursive result is zero and the loop returns the accumulator. In the step branch, the source result is one plus the result on the selected field. Updating the cursor to that field and adding one to the bigint accumulator preserves the invariant. Induction over the number of selected-child edges to a base constructor establishes the final result.

The compared operand in natAdd is literal one, so choosing its left or right position introduces no additional source computation or observable fault. The loop removes generator/stack overhead; it does not promise equal physical resource use.

There is an essential name premise. A printed-name match denotes self only if no declaration parameter or relevant branch binding shadows that declaration name. The actual source erasure's psErasureLocalNameUsed checks both runtimeLocals and declarationNames.byOutput, and its owned name-index/count construction supports this premise for names generated through that mechanism. **Arbitrary typed, target-admitted IR alone does not establish this stronger self-identity premise.** Complete ER-09/ER-07 correspondence must cover every generated binder and reconstructed call. This review therefore does not promote the conditional count argument to a theorem about all externally supplied typed IR.

## 6. Tail-loop specialization

The tail recognizer accepts nongeneric declarations with at least one runtime parameter. It translates a body only when every path can be handled by its restricted cases; otherwise emission falls back to the general generator path.

### Pure expressions

psTsTailPureWithFuel admits literals, variables that are not known recursive aliases, selected intrinsics with recursively admitted children, records, constructors, projections and conditionals. It rejects calls, lambdas, lets and matches in a pure-expression position. Array.map and Array.foldl are explicitly rejected because they invoke callbacks. The accepted non-callback intrinsics keep their own enabled-runtime laws and error/order requirements.

This means no new arbitrary closure is constructed in a tail-call argument or return expression. Passing or returning an existing function-valued variable is different: it carries an already established closure relation. The optimizer must not be described as accepting every mathematically pure expression.

### Direct self calls and tuple updates

A recognized tail call has no type arguments and exactly the declaration's runtime arity after any recognized alias prefix is restored. Every argument must pass the pure-expression recognizer. Emission uses a destructuring assignment from a newly evaluated array of arguments, then continues.

The invariant relates the current mutable parameter tuple to the environment of one original recursive invocation. JavaScript evaluates the complete right-hand-side argument list in the old environment, left to right, before writing the parameter tuple. If an argument faults, later arguments and the recursive body are not evaluated; there is no subsequent observable successful continuation using a partly computed source call. With related values, the completed tuple represents the next invocation's parameter environment.

The only rebinding performed by the loop is this parameter update. Let and match bindings use fresh block-local const declarations for each iteration/path. The name guards reject attempts to shadow the declaration's identity, its runtime parameters, recorded aliases or captured alias variables.

### Recognized aliases

An alias must be exactly a lambda whose body calls self with no type arguments. Its trailing arguments must be the lambda parameters in order. Its captured prefix contains only variables that do not coincide with those lambda parameters. Existing aliases may not appear in a supposedly pure captured prefix.

Such an alias is used only as a recognized tail-call callee. Using the alias as a value in a pure result/argument is refused, so the removed closure cannot escape. The subsequent binding guard prevents changing the meaning of a captured prefix variable before the alias is used. Restoring that prefix and appending the call arguments therefore reconstructs the same full tail-call tuple.

The printed self-name premise from the count argument also applies here. A complete local rule proof must connect it to the actual erasure name map, not infer it solely from type checking.

## 7. Generator stack and synchronous wrappers

psTsStackRuntimeSupport implements one work stack. General positive-arity declarations emit a synchronous public function, a generator implementation, and a WeakMap association between them. Lambda emission uses __ps$wrap to establish the same association for a closure.

A call expression evaluates its callee and arguments before __ps$invoke yields a request containing those values. The runtime has two cases:

- For a registered function, it creates and pushes the corresponding generator implementation with the exact argument tuple.
- For a direct function value without a registered implementation, it invokes that value and supplies its result to the suspended caller. This case covers deliberately direct generated helpers/optimized functions under their separate local arguments. It does not admit arbitrary foreign effects or new source FFI.

A useful loop invariant is that the pending generator array represents the outstanding IR evaluation contexts, from the root to the currently active call. The carried value is the completed child's result to be delivered to its parent, or undefined when entering a new child. Advancing the top generator either yields the next request or finishes the current context. A yielded registered request adds one call context. A finished generator removes one context and carries its return value upward. When the root completes, the carried value is the root result.

The generator used by __ps$invoke and yield delegation add administrative steps. They neither reevaluate the callee/arguments nor reorder the child call. A lambda implementation's JavaScript closure retains the lexical environment in which __ps$wrap was called, while a new invocation receives its own parameter environment.

No IR exception handler is inserted by this runtime. A declared runtime fault thrown during an expression or a direct invocation escapes the active run; later source work is not resumed. The abandoned pending contexts have no admitted finalizer effects. This is the appropriate conditional first-fault argument for the current IR. It is not a promise about generators with foreign cleanup handlers or external mutation.

The complete application relation must include both this machine invariant and the direct count/tail paths. Registration lookup alone is not a preservation proof.

## 8. Module initialization and helper namespaces

The target gate inspects the actual module before emission. It rejects external IR imports in this closed lane and admits a runtime variable only when it is lexical, an earlier runtime declaration, or positive-arity self. It traverses lambda and branch bodies as well as immediate initializers. Thus a later global demand hidden inside a closure is not automatically accepted.

The emitter creates runtime helpers and layout tags/brands before emitting the ordered runtime declarations. A general function's public wrapper/implementation are followed by their registration. Every earlier declaration has therefore finished initialization and any required registration before a later zero-arity initializer can call it. A positive-arity function does not execute its body during registration. Zero-arity self is refused, including beneath a delayed closure.

The proof is an induction over the emitted declaration order, combined with the target variable rule and the local call relation. It is intentionally conservative: it does not justify arbitrary safe forward references or mutual recursion by a call-graph guess.

Names matter in both TypeScript namespaces. The gate separates binding/type/property roles, rejects keywords where they are bindings, rejects __proto__ as a source property, protects actual unqualified runtime globals, and checks the generated brand/tag/implementation names against module and local bindings. IIFE parameter names need not be globally reserved because source operand expressions occur as call arguments outside those local binder scopes.

The target specifically reserves __ps$match$0. Together with its admitted expression-depth domain and the conservative name-use walk, the first match temporary is available in the supported path; nested generated match functions give distinct scopes. Brand/tag numbering is checked against the actual number/order of layouts. These facts are narrower and more useful than claiming a general unbounded fresh-name algorithm.

## 9. What remains before any semantic qualification

This review supplies conditional family arguments and identifies their exact implementation premises. It does not close any of the 33 full correspondence rows. The next required work is to connect:

1. Actual source, normalized worker/public batches and binder identities to the prepared Core terms.
2. Proof/type omission, application grouping, runtime layout and reconstructed recursion to the corresponding original IR.
3. All generated local names, including new output-only temporaries and completion parameters, to the no-capture/no-self-shadow premises used above.
4. The enabled scalar/callback laws and the common value/environment/call relation to each backend path.
5. Mandatory regular empty-data/match coverage to an explicit implementation or normative disposition, without treating absence from the compiler corpus as a waiver.
6. Exact-source native/generated/cloud evidence to the reviewed implementation, preserving the independent provider and source/runtime qualification axes.

TypeScript 7.0.2 and Node 22.23.3 remain explicit trusted toolchain/runtime assumptions. No TS5 fallback, old grammar path, seed promotion, cache algorithm change, kernel/provider/defeq change or existing metatheory edit is introduced by this document.

## Source references

- [General module/runtime emitter](../../../packages/backend-ts/src/Ps/BackendTs/Module.lean): the exact definitions listed in the boundary table.
- [General expression emitter](../../../packages/backend-ts/src/Ps/BackendTs/Expr.lean): eleven expression cases, let statements and conservative name-use traversal.
- [Portable target gate](../../../packages/backend-ts/src/Ps/BackendTs/Sh1Target.lean): roles, private names, variable availability and weighted depth.
- [Original-IR checker](../../../packages/compiler-ir/src/Ps/CompilerIr/Check.lean): runtime groups, field order and layout checking.
- [Erasure name representation](../../../packages/erasure/src/Ps/Erasure/Basic.lean): output-name index, local-name use and freshness budget.
- [Erasure declaration preparation](../../../packages/erasure/src/Ps/Erasure/Definition.lean): inductive/declaration names from the ordered runtime prelude plus source declarations.
- [Normative language contract](../SPEC.md), [enabled runtime contract](enabled-runtime-contract.json), [correspondence ledger](correspondence-obligations.json) and [runtime law review](RUNTIME_LAW_REVIEW.md).
