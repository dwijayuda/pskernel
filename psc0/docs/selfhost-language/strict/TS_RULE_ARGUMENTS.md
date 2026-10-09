# TypeScript backend: source arguments for TS-01–TS-09

## Status, scope, and exact implementation boundary

This document supplies conditional, compositional source arguments for all nine TypeScript-backend rows in the strict correspondence ledger. It uses the shared value, environment, grouped-call and interaction-budget relations in SEMANTIC_RELATIONS.md. It does not replace the ledger, change the language contract, or infer a semantic theorem from compiler fixed points, provider admission, or finite runtime examples. All 33 correspondence rows remain open; strictSh1Qualified, semanticContractQualified, generalPreservationProven, and formalPreservationProven remain false. [R, L]

The implementation boundary is commit 3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc. Its Module blob is 2580754407e70be69cc10101c4ebe03c7304a8f0, including the independently reviewed guard declining empty alternatives in the tail optimizer. Its original-IR checker is 178ecf89498be6502be5f747f0c0d62eb1133420, whose local expected-type annotation makes the previously intended empty-match checker branch explicit. The backend Expr, Type and Sh1Target blobs are unchanged from 2b5a4c903ed8a069cde8f08265b28042bcaf5766 / 047a29f17392fea41ac5d59e7f8cbfc172b20313. Source coordinates B2 refer to the preceding Module blob 98bac2823502c641c9b386f0ee1328cd7a688e87 for stable line references; B2R records the exact current guard delta, and every argument about successful empty dispatch uses the current file. §12 separates that source correction from its independently scoped execution evidence. No execution result is reported by this document.

The nine arguments have three layers:

1. Concrete source facts about successful checker and recognizer branches.
2. Local preservation derivations under the shared relation, with their exact structural and host premises stated.
3. The remaining interfaces needed to apply those derivations to every actual accepted source compilation.

The second layer is useful general reasoning; it is neither a new runtime report token nor an assertion that the third layer is already established. In particular, the backend theorem needs the actual source name/capture association. Complete original-IR typing plus target admission alone is a weaker premise, as the two source-inspected IR examples in §11 demonstrate.

## 1. Shared premises and proof organization

Fix the actual original IR I from one successful source-owned atomic compilation. Fix its ordered layouts and declarations, the emitted module, and the world W used by the shared relation. The target gate runs on this same I after complete original-IR typing. It admits no external IR imports. It does not grant strict status to arbitrary direct IR callers. [B1, B5, B6]

The arguments use the following explicit premises.

| Premise | Required content | How it is supplied or remains open |
| --- | --- | --- |
| P-TYPE | Complete typing of the actual I: resolved owners, exact parameter/type arities, field and alternative coverage, checked result types and type substitutions. The enabled source domain supplies only the six primitive types and the 45 enabled intrinsic operations, supported arrays, regular data and functions. | The actual checker and source path supply the concrete successful judgments. Their interpretation and substitution completeness remain the shared typing/layout interfaces. |
| P-WORLD | V, E, C, θ and Π are the same relations throughout expression emission, callbacks, optimizers and initialization. Function values denote actual emitted closures or declarations, including permitted direct optimized functions. | R defines the relation schema; its complete source/Core adequacy remains open. |
| P-NAME | Actual identity associations are preserved. In particular, an initializer moved under a lexical const cannot acquire a captured implicit constructor owner, and each call/alias recognized as printed self denotes the current declaration in that scope. | Ordinary erasure allocators use the actual declaration output-name index. Post-erasure eta names require the occurrence-sensitive argument described below. Target admission supplies additional concrete restrictions, not the whole Core-to-IR association. |
| P-DATA | Values have the canonical immutable representation: dense source arrays, scalar strings and characters, ordinary generated data objects, and related generated functions. Layout fields have their associated owner and instantiated types. | R and the enabled runtime contract. Foreign proxies, getters, mutated iterators/prototypes and cyclic foreign constructor data are outside this domain. |
| P-PRIM | The 45 local operation laws and their operand-demand clauses hold in their declared domains, including proof-required Array.get/set bounds and related map/fold callbacks. | RUNTIME_LAW_REVIEW gives the scalar/sequence arguments and names its remaining primitive/native/host assumptions. It does not supply the callback theorem by itself. |
| P-HOST | The pinned TypeScript 7.0.2 and Node 22.23.3 lane implements the restricted emitted constructs and ordinary built-ins as specified; required representable allocations succeed. | Explicit trusted execution boundary in TS-09. No equality of resource costs, allocation timing, stack limits or failure thresholds is assumed. |

P-NAME is deliberately occurrence-sensitive. It does not assert that every otherwise-unused generated eta parameter differs from every global name. The necessary clauses are:

- Each explicit reference resolves to the corresponding current lexical or permitted global binding.
- If the let-initializer explicit-name scan is false for x, the emitted initializer has no implicit owner/helper reference newly captured by placing it under a const x scope.
- Every callee occurrence which a count/tail recognizer classifies as self actually denotes the current declaration.
- Any generated binder introduced by a rewrite preserves these clauses at its affected occurrences.

The ordinary source allocator's stronger avoidance of the actual byOutput index can establish several of these clauses. The post-erasure eta helper scans explicit uses and binders; actual target constructor checks and the exact generated occurrence construction must supply the remaining implication. A blanket assumption that typed target-admitted IR has global/local disjointness would be false. [B1, B7–B8]

### 1.1 One interaction budget, not one budget per child

C^n observes the independent computations with n available semantic application events. Callee and argument expressions run in order, passing their residual budget forward. A related application consumes one unit before its bodies run. If a value is obtained with r units remaining, its values are related at V^r. At the next invocation with residual zero, the observation stops before that invocation and imposes no later-result claim. Returning from a callback or nested runner carries its residue back to the caller.

Previously obtained values and environments can be weakened to a smaller index. They cannot create new observation budget. The function V^(n+1) clause uses lower-index argument/capture environments and C^j for the body after that application's single charge. W records actual syntax identities and capture edges; it does not assume the semantic conclusion about those captures. [R §1.3]

This permits a mutually consistent proof:

- Non-call expression cases use structural induction, sequencing the residuals.
- Lambda cases use the body induction hypothesis at each smaller permitted function index.
- At a call, weaken the already obtained callee and arguments to the current residual; the callee's function clause supplies its body computation after one charge.
- Recursive global functions are handled at lower application indices. Module initialization additionally uses declaration-prefix induction.
- Count/tail/eta implementations match logical original-IR applications even when no physical JavaScript function call remains.
- Administrative constructor factories, let/match IIFEs, wrapper entry, registry lookup, and generator bookkeeping do not charge an application a second time.

For unrestricted complete computations, all finite budgets and the progress/divergence argument are still required. No finite conformance case establishes them.

## 2. TS-01: names, properties, and generated lexical scopes

### 2.1 What the target worklist establishes

Sh1Target builds a finite worklist over the actual module. It first refuses imports, collects all structure, inductive and declaration globals, then reserves the brand, tag and implementation names, then visits every layout and declaration. Scheduling prepends the complete selected list of tasks; sibling lists have explicit continuation tasks. Acceptance occurs only with an empty worklist. If fuel reaches zero while tasks remain, the result is an error, never an accepted incomplete report. Name-character visits and expression/type depth refusals are explicit. [B1:267–603]

The name roles distinguish globals, local values/types, ordinary references, unquoted properties, and quoted constructor properties. Source case analysis gives the following guarantees:

| Position | Successful-path restriction | Why it matters to emission |
| --- | --- | --- |
| Identifier spelling | Nonempty ASCII initial letter, underscore or dollar; following characters may also be digits. | The emitter inserts these spellings without an identifier-escaping pass. |
| Binding keyword | The actual strict/module binding keywords, including await, yield, arguments and eval, are refused. | Emitted function/parameter/const syntax cannot acquire those reserved meanings. |
| Type binding | The target additionally refuses the listed primitive/type keywords and capture of actual global type owners; local type Array is refused. | Named-type annotations and the Array type constructor keep their interpretation. |
| Property | Identifier-form properties may use keyword spellings, but __proto__ is refused. Quoted constructor properties also refuse __proto__. | Keywords are valid property names; object-literal prototype mutation is not the source record/constructor operation. |
| Private/runtime binding | The exact runtime helper names, first match temporary, count/cursor variables, and generated brand/tag/implementation names are protected. | Authored bindings cannot capture the actual private runtime references. |
| Built-ins | Global bindings cannot replace module built-ins; local value bindings cannot replace the built-ins used directly by expression templates. | Unqualified Array, BigInt, Number, String, Error and undefined in emitted expressions retain their intended bindings. |
| Constructor occurrence | An implicit constructor-owner reference is refused if that owner is a local in the actual occurrence scope. | Emitted Owner["Ctor"] accesses the initialized constructor namespace. |

The property distinction is intentional: a property with the spelling of a helper does not create a lexical binding. Conversely, protecting only explicit IR variables would miss constructor namespaces, so the target has a separate constructor-owner occurrence check. [B1:145–265,465–565]

The target's index operations must satisfy their ordinary exact-name insert/find laws. The shared erasure/name-index argument supplies those laws under the stated PsName equality and hash-routing assumptions. This document does not infer set membership from a hash value alone. [B7, R]

### 2.2 Exact private-name selection

For structure ordinal i the target reserves __ps$brand$i; for inductive ordinal i it reserves __ps$tag$i. It checks those names against all module globals and against already reserved private names. The two prefixes are distinct. Before authored scopes are visited, every positive-arity declaration also reserves its exact __ps$impl$Name. This is conservative even when an optimizer later emits no implementation function.

In the emitter, the brand and tag map workers start at zero and thread the next index. The used set initially contains every declaration, structure and inductive name; each emitted private name is added as well. Induction on layout ordinal proves that the target-admitted candidate at i is absent from that set: globals were checked against every reserved candidate, earlier names have distinct ordinals, and the prefixes cannot coincide. Therefore the existing fresh-name worker succeeds on its first attempted candidate at every layout. Its 4096-attempt overflow fallback is unreachable on this admitted domain. No bound of 4096 layouts is required for this argument; the ordinal continues across separate first-attempt searches. [B2:14–69; B1:277–340]

The match-temporary argument is similar but local. The target rejects __ps$match$0 in binding positions throughout the module. A successful, well-scoped variable read cannot introduce an unbound reference to that name. Property/literal text with the same characters is harmless. Under the depth argument below, the expression-name scan sees the complete explicit expression tree and finds the first candidate unused. Nested match generators may reuse that spelling because each has its own lexical scope; their initializers and case fields use the corresponding nearest temporary.

### 2.3 Why the depth premise covers eta output

Define weighted expression depth w as one plus the maximum child depth for the ordinary tree constructors. For a lambda with k runtime parameters, use:

    w(lambda parameters body) = 1 + k + w(body).

Take the maximum over sibling children, not their sum. Types use their ordinary recursive depth. The target consumes one depth unit on each expression constructor and one additional unit per lambda parameter. Top-level declaration parameters are checked separately without charging the body's depth, because expression scans begin at the body. Consequently, success from depth 4096 implies w(body) ≤ 4096 and bounds all original subexpression scans. [B1:406–522]

The only backend eta rewrite is at a declaration body's root call. Pushing through a let/if/match preserves that constructor and its unchanged non-body children. At a lambda with k parameters, the rewrite replaces the lambda by k nested lets initialized from variable arguments. The transformed body depth is at most k + w(body), below the lambda's old 1 + k + w(body); removing the outer call cannot increase it. Thus the same original weighted bound covers the transformed tree.

The name scan returns true on fuel exhaustion. It therefore cannot assert false absence after a partial scan. On the admitted depth domain it does not exhaust in the relevant scans. The eta and tail recognizers return none on their own exhausted searches, preserving fallback behavior. Expression/type emission returns an explicit fuel error if it cannot finish. These are distinct outcomes, none a semantic acceptance token. [B3:12–67,516–522; B2:207–278,504–535,560–563]

### 2.4 Let scope and the actual source premise

The IR let initializer is evaluated in the old environment. A JavaScript const is lexically in scope inside its own initializer, with a temporal dead zone. The emitter therefore has two branches:

- If the initializer explicitly uses the binder name, it evaluates the initializer as the argument to a fresh generator function whose parameter has that name. The parameter scope begins in the body, so the argument still reads the old binding.
- Otherwise it emits a lexical block containing const x = initializer and the body.

The first branch directly realizes the old-scope rule. The second additionally needs the implicit-reference clause of P-NAME. The scanner records variables and binders, but not a constructor owner's implicit runtime namespace. The target checks an initializer in the old scope, so it does not alone prove that moving that initializer under the new const scope is safe. The actual-source naming invariant is the necessary bridge; §6.3 derives the required occurrence property from the ordinary allocator and the eta construction. Target admission alone is insufficient. [B3:491–510; §11.3]

Constructor-factory parameters such as __field0 and primitive-IIFE parameters such as __ps_a do not require global reservation. Authored field/operand expressions are arguments evaluated outside those parameter scopes; only the already obtained values occur inside the helpers. The corrected capacity and stringAtEnd templates have this same property. [B2:123–158; B3:422–489]

**Conditional TS-01 conclusion.** Given complete actual typing, target success, the exact index laws and occurrence-sensitive P-NAME, all emitted bindings, explicit references, properties, private names and constructor-owner accesses denote their intended entities. The target facts above are structural proofs. The remaining Core/local association is an ER-09/O-SCOPE obligation, not a missing extra target report.

## 3. TS-02: records, constructor objects, brands, and tags

For each structure owner S, the emitter initializes a private unique-symbol brand and prints the interface with that computed brand field plus its ordered declared fields. An IR record emits an ordinary object with brand=true and its field expressions in IR order. By the child-expression hypotheses, those expressions supply related field values. The private brand identifies the representation owner without being a source field. A zero-field structure still produces a real branded object, so its value relation is inhabited. [B2:82–104; B3:588–612]

For each inductive owner F, the emitter initializes a private unique-symbol tag, prints the union of constructor variants, and creates one exported constructor namespace. Its keys are quoted constructor names. Constructors of distinct owners use distinct tag symbols even if their textual constructor names coincide. A variant's fields retain their owner-associated names and instantiated types; reading or switching the private tag yields exactly that constructor's quoted string.

There are two constructor-value branches:

1. With no type parameters and no fields, the namespace contains a prebuilt tagged value.
2. Otherwise it contains a factory with one internal positional parameter per field and the declared type parameters. Calling it builds the same tagged shape from the parameter values. A generic nullary constructor is still a factory and is called with an empty runtime group after type instantiation.

The expression emitter uses the same distinction: it returns the namespace property directly only when both type arguments and fields are empty; otherwise it invokes the constructor factory. Complete type-arity checking aligns the layout's generic case with the call's type-argument list. [B2:106–183; B3:618–641]

The factory ignores IR field labels when constructing its runtime argument list, so field order is a substantive premise. The actual original-IR constructor checker compares the expression's field sequence with the layout's expected field sequence and reports constructor-field-order on disagreement. It also checks the fields' names, types and arity. Therefore positional argument i is the value for layout field i; no unproved arbitrary reordering is hidden in the factory translation. Structures retain their named-field mapping and the actual IR field-expression order. [B4:418–468]

For an empty inductive, the constructor list contributes no value case. Its TypeScript alias is never and its constructor namespace has no entries. That namespace object is compiler representation machinery; it is not an inhabitant of the source type. The empty-value relation remains empty. The corrected general empty elimination demands its scrutinee once and then has only its defensive throw path; the separate tail guard ensures that raw direct-empty cases reach this general path. No native or JavaScript value of Empty is required to justify the empty case. [B2:160–183; B3:642–654; B2R; §12]

The proof is an induction over finite related data, with the shared function relation used for retained function-valued fields. It preserves owner, constructor choice, field interpretation, and immutable value behavior. It does not equate allocation identity, physical sharing, or external object mutation. readonly, as const, type assertions and unique-symbol annotations help express the target representation; their presence alone is not the proof. O-LAYOUT and θ substitution remain responsible for connecting actual Core constructor/projection identities to these checked IR layouts.


## 4. TS-03: general expression templates and demand

The local statement is conditional on related environments and the actual checked expression. If the general expression printer succeeds, its emitted expression implements the corresponding rule in R §3, with the same original-IR applications, selected operands, values and permitted aborts. It uses the one shared budget of §1.1. A compiler-side list traversal that prints both branches does not mean that the generated program evaluates both branches. The runtime argument is about the resulting expression text. [B3:516–702]

The structural induction has the following eleven cases. A child which returns with residual r supplies a value at V^r; subsequent children and retained earlier values use that r, weakened further when necessary.

| IR form | Concrete emitted mechanism | Local derivation |
| --- | --- | --- |
| literal | Nat and Int decimal bigint literals; JSON-quoted scalar strings; Boolean literals; undefined for Unit | The literal denotes the same indexed primitive value under the formatting/quoting and host assumptions. Decimal formatting and JSON string escaping are separate trusted or source-algebra premises; a type annotation is not used as a runtime conversion. |
| var | The checked identifier itself | The corresponding lexical/global entry is read once. P-NAME, the environment relation and TS-08 establish its binding; reading it does not repeat its initializer. |
| intrinsic | One operation-specific template over printed child expressions | The template's strict or short-circuit demand clauses are proved below. Its result law is the corresponding enabled primitive law. Callback operations additionally use TS-04. |
| lambda | __ps$wrap(function* (parameters) { return body; }) | Evaluating the generator function expression and registering its wrapper creates a closure over the current environment. The generator body is not run now. At a later related invocation, the exact ordered parameters extend that captured environment and the lower-index body argument applies. |
| call | yield* __ps$invoke(callee, arguments), with erased type instantiation annotations | JavaScript evaluates the callee expression, then each runtime argument once in order, before the request is yielded. The request retains those values and the exact group. TS-04 consumes one logical application and delivers its result to this continuation. |
| letE | A delegated generator containing nested const blocks, or a parameterized delegated generator where the initializer uses the bound name | Both branches evaluate the initializer in the old environment before the body uses the new value. The detailed TDZ/implicit-owner conditions are in TS-01. A nested let IIFE is administrative, not an extra IR application. |
| ifE | A parenthesized conditional expression | The condition is demanded once. A related Boolean chooses the same branch; only that branch uses the condition's residual budget. |
| record | An object expression with the private brand, followed by authored retained field initializers | The brand lookup is initialized administrative work. JavaScript obtains field expressions in their original printed order; after they return, the object represents the associated structure. Zero fields still produce an inhabited structure value. |
| projection | Printed target followed by the checked field property | The target is evaluated once. The related structure and owner/field association yield the related field value. Ordinary own fields have no getter invocation in P-DATA. |
| constructor | The owner namespace's quoted constructor property, optionally called with the ordered fields | TS-02 supplies the constructor value/factory distinction. Field expressions are outside factory-local scopes and run in checked order before construction. The private factory call creates no extra original-IR application event. |
| matchE | A delegated generator with one fresh scrutinee const and a tag switch; a separate typed-never branch for no alternatives | The scrutinee runs once. On related data, the same constructor selects the same branch; ordinary field reads extend only that branch's environment. No unrelated branch body is demanded. Empty elimination preserves the scrutinee demand prefix and has no in-domain value continuation. |

The actual original-IR model has exactly these eleven constructors. Optional machine-integer/float printer cases exist in the code but are outside the enabled operation/type admission; their presence is not an expansion of this theorem's domain. Complete expression/type admission and successful emission are both required. [B3, B9, B1]

### 4.1 Full intrinsic-template demand partition

There are 45 enabled operation names, partitioned here by the source-emitted evaluation mechanism. This table accounts for operand placement, not a replacement set of value laws.

| Template family | Enabled operations | Evaluation argument |
| --- | --- | --- |
| Direct strict scalar expressions (24) | natAdd, natMul, natEq, natNe, natLe, natLt; intOfNat, intRepr, intNegSucc, intNeg, intAdd, intSub, intMul, intEq, intLe, intLt; boolNot, boolEq, boolNe; stringPush, stringSingleton, stringAppend, stringEq; arraySize | Each original operand text occurs once in an ordinary strict operand/receiver position. Unary identity templates still evaluate their one operand. Binary operands evaluate left to right. Fixed scalar conversion/method work follows the required operand values. |
| Short-circuit Boolean expressions (2) | boolAnd, boolOr | The left operand is evaluated once. The right is demanded only for true-and or false-or respectively. This follows the enabled intrinsic demand contract; it is not a claim about arbitrary eager two-argument host functions. |
| Typed immediate-function templates (13) | natSub, natDiv, natMod; charOfNat, charToNat; stringLength, stringAtEnd, stringExtract; arrayEmptyWithCapacity, arrayGet, arrayGetD, arraySet, arraySetIfInBounds | All authored operand expressions occur only as the immediate call's arguments, once and in source order. Any repeated references inside the body are references to its already-obtained parameter values. Bounds/branch/arithmetic work follows that capture. |
| Named UTF-8 helper calls (3) | stringUtf8ByteSize, stringNext, stringGet | Ordinary call argument evaluation obtains the text and then position where applicable. The helper's cache/index work sees those stored immutable values. Its character/boundary laws and bounded cache transparency are the separate runtime-family argument. |
| Immutable array extension (1) | arrayPush | The array expression is evaluated once, its ordinary dense contents are copied, then the appended value expression is evaluated once. The early copy has no source callback/getter/iterator effect in the declared domain; its finite silent work commutes with the later value computation under successful allocation. |
| Callback operations (2) | arrayMap, arrayFoldl | Typed immediate-call arguments obtain the function and array/accumulator/range operands once in their declared order. The fixed helper then invokes related callbacks with the prescribed groups, carrying one shared residual budget. |

The counts are 24 + 2 + 13 + 3 + 1 + 2 = 45. The two corrected templates matter to the proof:

- arrayEmptyWithCapacity takes capacity as an explicitly typed immediate-call argument, then discards that parameter and returns the empty array. The capacity expression is still evaluated and may suspend or abort before an array value is produced. Injecting source text into a nongenerator body would neither preserve this syntax nor its demand.
- stringAtEnd takes text and position as two immediate-call arguments before reading the UTF-8 size. Thus text is demanded before position, and both demands precede helper work. The comparison uses only stored parameters.

The six equality type widenings use bigint, boolean or string assertions around operands that each still occur once. Those assertions address TypeScript's literal-overlap rejection; they erase at runtime and do not add conversions, duplicate demands or alter equality. [B3:249–490; RL]

For arrayGetD the fallback is an ordinary strict third argument even when the index is in bounds. For arraySetIfInBounds the replacement value is likewise obtained before its bounds decision. The proof-required get/set operations demand their operands before their explicit defensive bounds guards; their successful-value laws require the source bounds premise. Negative-Nat, malformed-array and arbitrary foreign callback cases cannot be smuggled in through TypeScript casts. [RL, RC]

The arrayPush copy qualification is precise. JavaScript spread can invoke a user-modified iterator in the general language; this theorem uses canonical dense arrays and ordinary built-ins. On that domain, copy work cannot inspect source computation effects or consume logical application events. A foreign iterator, a proxy, resource exhaustion during the copy, or externally observable allocation identity would invalidate that particular commutation premise and is not silently covered.

### 4.2 Error and continuation cases

If a child aborts within the permitted compared domain, the ordinary expression evaluation rules prevent later operands, construction or branch work. A thrown callback/helper abort similarly propagates through the direct expression or suspended generator. Source Except.error is instead an ordinary tagged data value; it does not throw and does not discard the continuation. Compilation-stage refusal and emitter fuel exhaustion occur before the successful-compilation premise. [R §2.3]

For a nonempty match on canonical related data, exhaustive original-IR coverage and TS-02 make the emitted invalid-tag default unreachable. It remains a defensive diagnostic for malformed host carriers. For an empty match, related values of the scrutinee's empty type do not exist. A terminating empty value cannot be assumed to prove the case; only the demanded scrutinee prefix, any permitted pre-value abort/divergence, and absence of an in-domain success branch are relevant. The current tail guard preserves this general routing (§12).

The general local induction relies on the primitive/native laws and the machine argument, but does not assume the full O-IR-JS result to prove itself. Calls use the lower-index function clause; all other expression cases use smaller syntax and the stated non-call host rules. O-IR-JS remains the shared interface until this argument is integrated with the independently defined operations, accepted-source domains and all source/Core associations.

## 5. TS-04: closures, registered calls, direct calls and reentrant runners

### 5.1 Actual machine, not an abstract “trampoline” assertion

The generated runtime has a private WeakMap from public callable values to generator implementations. A request contains one function value and an array of already-evaluated argument values. __ps$run stores a nonempty stack of suspended computations and one result slot. Its loop resumes the top generator with the current slot. A completed generator is popped and supplies its returned value. A yielded request either pushes the registered implementation or calls the permitted direct callable with Reflect.apply. [B2:193–194]

The concrete invariant is:

1. Stack order is bottom caller to top callee. Each stored generator's suspension point corresponds to the related IR evaluation continuation, its lexical environment and already-obtained child values.
2. A newly pushed generator corresponds to the body of exactly the yielded logical application, with that request's stored argument group. Its first resume receives undefined; JavaScript generator entry ignores the first next argument.
3. A completed top generator supplies the related result to its immediate waiting continuation. The result slot is used on that resumption, and is reset to undefined on a new push.
4. Local yield* delegation inside a let, match or __ps$invoke is part of the generator's continuation state. It need not appear as a separate element of the explicit pending array.
5. The semantic observation carries a single residual budget across this whole stack, including calls temporarily realized by nested host invocations. The implementation does not store that proof index, and no runtime state modification is proposed.

The invariant is initialized by a root generator with its related environment. Each actual loop branch preserves it:

| Actual branch | Semantic step and invariant preservation |
| --- | --- |
| next.done | The top body has returned. Pop its frame, weaken the return value/environment as needed to the returned residual, and resume the waiting continuation with that value. If the stack is empty, the root result is returned. |
| Registered request | The request already has the callee and ordered argument values. At positive residual, charge its one original-IR application, obtain the lower-index body relation, and push the actual associated implementation with those arguments. No wrapper is invoked again on this route. |
| Permitted direct request | Charge the same logical application and execute the related direct body. Its result/residual is installed for the waiting generator. This body is justified by the count/tail/helper argument appropriate to that actual callable. The branch does not authorize arbitrary host functions. |
| Throw during resume or direct call | There is no catch around these operations. The throw escapes the runner and its awaiting callers. Pending continuations do not run afterward. The compared abort category/payload is only the one admitted by R and the operation domain. |

The generated language has no catch/finally expression form whose cleanup must be replayed into suspended frames. The runner does not inject an exception with generator.throw and does not execute pending continuations after failure. This is appropriate for the stated aborting semantics; it would not establish a semantics for arbitrary foreign generators with finalizers.

### 5.2 Three callable entry routes

A positive-arity general declaration emits a public synchronous function, a generator implementation and its WeakMap association in that order. A source lambda emits __ps$wrap around a lexical generator implementation; wrap creates a synchronous closure and immediately records that association. Count/tail declarations are ordinary direct functions. Constructor factories and fixed helper closures have their own representation/primitive arguments. A relation requiring every related function to be a registry member would therefore be false. [B2:280–315, 386–428, 650–669; B3:536–557]

For a registered value there are two equivalent entries:

- From a generated IR call inside a runner, lookup enters the stored implementation directly.
- From an ordinary public call, including a prescribed Array callback, the wrapper constructs that same implementation with that exact argument group and runs it synchronously.

The distinction changes host scheduling, not the lambda's capture environment or logical parameter group. wrap's rest-argument array and Reflect.apply transport existing argument values; neither invents currying or silently flattens a returned function. The separate source-to-IR completion and result-arrow eta transformations must already have established the actual group used by this declaration or lambda.

A lambda body is proved at smaller function indices after capture/environment extension. Recursive declaration bodies similarly use lower-index self behavior, and TS-08 supplies the ordered global world. The registry itself only records structural identities. It cannot serve as a semantic certificate or make the proof circular by assuming that every stored implementation is correct.

### 5.3 Callback and reentry composition

arrayMap's adapter calls the supplied function with exactly one element. The host map implementation may supply index and array to the adapter, but the adapter forwards neither. arrayFoldl calls with exactly accumulator and current element, in increasing index order from start while below min(stop, size). All source operands were obtained before this helper body began. [B3:479–490]

If a callback is a public generated wrapper, the helper synchronously enters a fresh __ps$run while the outer runner is suspended inside its intrinsic expression. The simulation state therefore includes an ordinary host-continuation stack of runner invocations in addition to each pending-generator stack. A callback's one semantic application consumes from the outer residual. Its internal calls consume from the remainder; callback return passes that remainder to the helper and then the suspended outer generator. There is no new proof allowance at wrapper entry, map iteration, fold iteration or runner reentry.

For map, induction on the finite dense array prefix maintains a related prefix of produced elements and the current residual. For fold, induction on the finite traversed range maintains the related accumulator and residual. Earlier returned values are weakened when a later callback consumes budget. A permitted callback abort stops later callbacks and escapes through the same outer continuation. At zero before a callback, both observations cut off at that same callback boundary without claiming its subsequent result.

A callback may itself be a count/tail optimized function, or may call another callback operation. Mutual proof by interaction index handles this: direct bodies and nested runner bodies are used only after their corresponding invocation charge, and finite non-call structure is handled structurally. The proof cannot replace all direct Reflect.apply bodies with an unexplained total-function assumption.

### 5.4 Administrative progress and its limit

On canonical finite values, fixed helper loops traverse a finite string/array; a private lookup or field read has the stated finite host meaning. Generator completion pops a frame. Non-call expression work traverses finite syntax and does not create an unbounded new call stack without an original logical invocation. Count/tail iterations which continue are aligned with original calls as detailed below; alias lowering may account for more than one logical call per physical iteration. These facts rule out the identified finite administrative segments silently looping on their own, under P-HOST.

This is a local progress decomposition. To infer a complete all-program divergence/reflection result one must integrate every row, justify the source/Core call alignment and account for all admitted host primitives. Resource failures remain separate. In particular, no bound on V8 memory, native stack use by nested callbacks, wall-clock time or generated continuation size follows from this relation.


## 6. TS-05: the recognized backend eta rewrite

### 6.1 Exact success domain

psTsInlineEtaApplication only inspects a declaration-root call. It requires an empty type-argument list. Every argument must be a var z, and its printed name must occur neither as a variable nor as a lambda/let/match binder anywhere in the callee according to the conservative 4096-fuel scan. The scan returns true at exhausted fuel, so exhaustion cannot produce a false freshness certificate. The recursive eta worker accepts only a lambda, a let prefix, an if with both recursive results successful, or a match whose every alternative recursively succeeds. An exact zipped argument/parameter count is required at each lambda leaf. Other shapes retain the original expression. [B2:207–278; B3:12–51]

Successful recognition does not mean that arbitrary argument computations may be moved inward. Its arguments are already-denoting immutable variables, with names absent from all scopes crossed. Repeated use of the same argument variable is allowed: reading an already-bound value twice is administrative and does not repeat its original initializer. Exact arity checking by the zipper prevents silent dropping or JavaScript underapplication.

### 6.2 Rewrite proof by successful worker structure

At a lambda leaf with parameters p₁,…,pₖ and body e, the original call obtains that closure and then the values of z₁,…,zₖ. Its application extends the captured environment with all those values before e runs. The rewrite instead emits:

    let p₁ = z₁;
    …
    let pₖ = zₖ;
    e

Because every zᵢ differs from every crossed parameter/binder name, each initializer still reads the original corresponding value. The nested lets therefore extend the same environment with the same ordered values as simultaneous parameter binding. Their intermediate bindings cannot change a later argument lookup. The remaining body is unchanged; its relation follows with that related environment.

The call's semantic event is matched immediately before the rewritten parameter-binding/body entry. Physical let initialization and removed generator/wrapper work are administrative realizations of that one invocation. At zero before this logical boundary, the observation cuts off before entering either body even though the optimized text has no physical call there. This is a proof alignment on the independent small-step computations, not a modification of runtime code.

The three recursive worker cases preserve the same alignment:

- For a let-prefix callee, the original initializer and callee-body selection happen before the outer variable-argument reads. The rewrite keeps that initializer in the same place and pushes only those immutable fresh variable reads inward. The prefix binder cannot capture them. An initializer abort or divergence still prevents invocation.
- For an if callee, the condition and only its selected branch are demanded on both sides. The same fresh argument values are read only after that branch reaches its lambda. No computation in an unselected branch is introduced.
- For a match callee, the scrutinee, tag choice and selected field-binding environment are unchanged. Argument freshness includes every match binding, so inward reads retain their original bindings. If alternatives are empty, the callee can yield no related function value: neither side reaches the outer application event. Its scrutinee demand prefix is preserved.

Induction on the successful eta-worker derivation proves exact control selection, environment extension and invocation alignment. The weighted target depth bound in TS-01 covers the added nested-let depth. Let emission then uses its already-proved old-scope rule. Typed owner/helper non-capture is needed at affected occurrences, rather than the false general claim that eta variables cannot share any unused global spelling.

### 6.3 Actual-source self and namespace provenance

The source's ordinary runtime allocator reserves actual byOutput names, including the current definition and constructor-owner globals. Result-arrow eta names use a separate explicit-use/binder scan. A chosen eta name can equal an otherwise unused global. The needed backend premise is narrower and follows from where the new occurrences are placed. [B7, B8, B10:1578–1665]

If an eta parameter equals the current declaration's printed name, successful scan=false means that oldBody contains no explicit occurrence or binder of that name. psErasureEtaFunction introduces the name as a new parameter and as a variable in the new outer call's argument list. It does not introduce it as the callee. psTsEtaApplyWorker preserves existing callees; psTsEtaBind moves those argument leaves into let initializers without substituting or renaming them into any old-body callee position. Repeated eta processing retains this property because each current body and used-parameter set is scanned again.

Count recognition requires a literal callee var equal to the declaration name. Tail self recognition does likewise. TailAliasValue additionally requires an existing lambda whose body is a call of that name; it does not recognize a let-bound variable alias. Consequently every accepted printed-self callee came from an old callee position where that name actually denoted self, or from an ordinary source allocator path already avoiding it. An eta-created argument with the same spelling cannot become a false self call through these transformations. This resolves the backend-specific actual-source self premise without exporting blanket global/local name disjointness.

For implicit constructor namespaces, successful target checking rejects a constructor owner shadowed by an existing runtime local in its actual scope. Ordinary source let binders avoid the owner index even in their initializers. New eta parameter lets correspond to old lambda parameter scopes; a constructor reference within that old body would already have been checked under those parameters. An eta argument initializer is only a variable, so it introduces no implicit constructor namespace there. Private helpers are protected by the target's exact reserved-name check. These cases establish the required initializer/owner non-capture for actual emitted lets once the ER scope/name association is supplied.

This backend theorem does not prove missing-argument completion or result-arrow group exposure. In particular, eta inlining cannot justify delaying the computation of a function-valued Core body until extra arguments arrive. ER-ETA-GROUP and the actual source/Core Π retain that separate obligation. The present theorem relates two implementations of the same original IR, with its group already fixed.

## 7. TS-06: count-loop recognition and constructor-chain induction

### 7.1 What is actually recognized

The declaration must have a Nat result and exactly one runtime parameter. Its original body must be a match whose scrutinee is that parameter variable. There must be exactly two alternatives. One alternative body must be literal Nat zero; the other must be natAdd of literal one and an exact one-runtime-argument call of printed self, in either addition operand order. That recursive argument must be a variable bound to one field in the step alternative. A tag lookup and parameter-type printing must succeed. The recognizer tries both alternative orders. [B2:320–428]

It does not require that the constructor has only one field. Unused checked fields may be present. It does not require an empty declaration type-parameter list or inspect recursive call type arguments; original-IR typing supplies their arity and instantiated parameter/result association. Thus the proof must allow permitted type instantiations, not silently narrow recognition to monomorphic lists.

TS-01/05 and the actual ER name invariant establish that the identified callee denotes this declaration and that the identified local denotes that field. Complete match/constructor checking supplies exhaustive alternatives and owner/field types. For related canonical finite data, that field's runtime value is the corresponding stored subvalue; if types change at a permitted recursive instantiation, the induction follows the associated θ at that call. The runtime tag remains the same owner tag used by the body. Successful downstream TypeScript emission/compilation is an additional operational gate, not a substitution for this identity argument.

### 7.2 State invariant and value derivation

Let F(c) be the original count function on a related canonical argument, with its actual current type instantiation. Its two selected equations are:

    F(base(fields)) = 0
    F(step(fields)) = 1 + F(selectedChild)

The alternative with 1 on the other side yields the same Nat equation by arithmetic commutativity. No other source computation is present in the recognized branches: only fixed literals, field value lookups and the one recursive call.

The emitted function initializes cursor to the incoming argument and count to 0n. The invariant at the loop's switch is:

- cursor is related to the argument of the next original recursive activation;
- count is the nonnegative Nat number of step constructors already traversed;
- the original result, if returned, is count + F(cursor);
- the observation has charged exactly the already-traversed original recursive calls and carries their current residual.

At a base tag, F(cursor)=0, so returning count proves the related result. At a step tag, selecting the checked stored field obtains the related child. Incrementing count changes the invariant from count + (1 + F(child)) to (count + 1) + F(child); bigint addition implements that Nat algebra in the representable, successful-allocation domain. The cursor assignment does not mutate the original data.

The selected child is a proper finite stored data subvalue. Its structural size decreases, so a canonical argument cannot sustain an infinite sequence of these steps. Sharing between subvalues does not prevent size/descent; cyclic foreign values are excluded. A finite constructor-chain induction proves the result for every related argument in this success domain, independent of examples or a particular list length.

### 7.3 Demand, logical calls and fault scope

The original non-tail form adds one only after its child call returns. The loop increments before continuing. This moves total silent scalar arithmetic before the recognized child count recursion. The crossed work consists only of that finite count recursion and its total field-read/addition steps, with no authored callback or arbitrary state-argument computation. Under successful allocation, the reordering preserves the result and observed logical-call prefix; the private accumulator is not a source observation at a cutoff. It relies on successful allocation and does not equate resource failures or allocation thresholds. Reading unused canonical fields can also be omitted because those fields are existing values with no getter effect.

Each traversal of a step aligns with the original recursive application before its child body. An observation at residual zero stops at that logical call boundary; it need not equate the optimized machine's private accumulator with a source-visible result at cutoff. At positive residual, consume one and use the smaller-child induction at the remainder. The initial public invocation is charged by the surrounding call relation, separately from these recursive steps.

The emitted default throws on an invalid tag. The typed canonical data relation makes that branch unreachable. It is not a new source abort case, nor a claim that malformed/cyclic foreign inputs satisfy the count equation. The self-identity countermodel in §11 explains why arbitrary typed target-admitted IR without actual source provenance is insufficient.

The count recognizer sees the unmodified original declaration body, before backend eta inlining. A failure falls through to the tail recognizer and then the general emitter. This particular optimization does not reinterpret an empty match: exact two-alternative recognition makes that impossible.

## 8. TS-07: tail loops, captured aliases and simultaneous updates

### 8.1 Success grammar and pure-expression lemma

The declaration has no type parameters and at least one runtime parameter. Its body is first passed through the proved backend eta rewrite. The tail emitter either succeeds for the whole body or returns none and allows the general emitter to handle it. It does not emit a partially optimized fragment after a failure. [B2:504–679; B2R]

The successful pure-expression classifier has exactly these cases:

- literals and variables that are not recognized alias names;
- enabled non-callback intrinsics whose argument expressions are all pure;
- records/constructors whose field expressions are all pure;
- projections with a pure target;
- if expressions with a pure condition and two pure branches.

Calls, lambdas, let expressions and matches are refused as pure leaves. arrayMap and arrayFoldl are refused even with pure arguments. Fuel exhaustion also returns false.

By induction over this classifier, a successful pure expression's general printing contains no IR-call yield, no authored lambda creation, and no prescribed source callback invocation. Its child evaluations have the ordinary TS-03 order, selected branches and primitive value laws. It may allocate immutable values and may reach an operation's permitted abort/defensive guard; “pure” here does not claim arbitrary foreign host totality or absence of resource use. The classifier's rejection of alias variables prevents an erased alias closure from escaping as data.

### 8.2 Direct tail call and tuple invariant

A tail call must have no type arguments and a callee variable equal to self or a known alias. After alias-prefix expansion, its runtime argument count must equal the declaration's runtime parameter count and every resulting argument must pass the pure printer. The direct-self case emits one destructuring assignment followed by continue:

    [p₁, …, pₖ] = [e₁, …, eₖ];
    continue;

JavaScript completely evaluates the right-hand array expression, left to right, before destructuring assigns the target parameters. Thus every eᵢ reads the old activation environment; swapping parameters or referencing an earlier parameter in a later expression is simultaneous call-argument binding, not sequential mutation. A permitted abort in eᵢ prevents later operands and prevents all parameter assignments. [B2:547–583]

The loop invariant relates the current parameter tuple to one original recursive activation, including its fixed global environment and current residual. If declaration-root eta inlining removed a call, the annotated rewritten body retains that original call's logical event at the corresponding parameter/body boundary in each activation, as proved by TS-05. That charge is additional to the direct/alias tail-edge charges below; one or two tail-edge events are not asserted to be the entire activation's event count. In a direct-self branch, TS-03/purity supplies the same ordered argument values. One original recursive application is charged after those values are obtained; the new tuple relates to its parameter environment, and continue reenters that body. No retained closure in this fragment captures mutable loop parameter cells: lambda values are not pure, and the only specially removed lambdas are the nonescaping aliases covered next.

An alias may capture a function-valued parameter by value; this is still an existing related value. Existing function values can be passed around by pure variable lookup. The proof excludes constructing a new arbitrary closure over a loop parameter and retaining it after that parameter is reassigned, which is precisely why an unguarded general tail rewrite would be unsound.

### 8.3 Exact captured-alias argument

A removable alias initializer must have the shape:

    λ q₁ … qₘ. self(c₁, …, cⱼ, q₁, …, qₘ)

The direct self call has no type arguments. Its suffix is exactly the lambda parameters in order, with no extras or omissions. Every captured prefix item is a var whose name is not a lambda parameter. No lambda parameter equals self. The new alias binding must also pass TailBindingSafe. Any prefix item which denotes an already known alias is refused by the pure check. [B2:454–502, 584–607]

The initializer creates a closure over already-obtained values; it performs no body work. The optimizer records only the prefix and alias arity. It may omit the physical closure because:

1. An alias value cannot escape: pure leaves reject alias variables, ordinary call fallback is absent, and the only consuming callee form is the exact alias tail-call path.
2. TailBindingSafe refuses future let or match binders equal to a parameter, self, an alias name, or any captured-prefix name of an active alias. Therefore a saved prefix variable still denotes its captured value at each permitted alias use within this activation.
3. All tail-call right-hand values are evaluated before parameter mutation. After continue, alias construction is logically repeated in the new activation, so a newly read prefix represents that new activation's capture rather than an older escaped closure.
4. Alias arity is checked before appending its saved prefix to the actual arguments, and the total is checked against self's parameter count.

In the original alias call, its actual argument expressions are evaluated before entering the alias body; that body then reads the saved prefix values and invokes self. The emitted right-hand array prints prefix value reads before the actual arguments. These prefix reads are total and silent lookups of already-defined immutable values. Moving them before a potentially aborting actual operand introduces no invocation or abort, preserves that same first abort and suppression of later operands, and does not reorder any demanded argument computation. No computed captured expression is re-evaluated: only its stored variable value is read. With the non-capture checks, both orders obtain the same complete self tuple and the same demanded computations.

There are **two logical applications** in this alias case: the call of the alias and then the alias body's call of self. The optimized single physical loop update must match both, in that order. After actual operand evaluation, a zero residue cuts off before the alias call. With one unit available, the alias body may read its silent prefix but the observation cuts off before self. With at least two, charge both and enter the next activation at the resulting residue. The tuple invariant after continue uses that residue. Counting every physical loop update as exactly one logical call would be wrong for this path.

### 8.4 Let, branch and match induction

For an ordinary let, the recognizer requires scan=false for the initializer's bound name and TailBindingSafe for the new binder. It also requires a pure initializer. The emitted scoped const therefore preserves old-environment evaluation under the TS-01 implicit-owner clause; the body uses the related extended environment. Local block scopes prevent leakage across alternatives or subsequent activations.

For an if, a pure condition is evaluated once, and only the selected recursively emitted body executes. Both branches must have a successful derivation so any runtime choice is covered. For a nonempty match, the pure scrutinee is evaluated once into a fresh private temporary. Checked constructor/tag/field associations determine the case and field bindings. Every field binder passes TailBindingSafe, and every alternative body recursively succeeds. The tag default is unreachable on canonical related data.

For an empty-alternative match, the current guard returns none immediately. This none propagates through any enclosing tail if/let/match recognizer, so the entire declaration uses the corrected general path when no earlier count recognition applies. Count requires two alternatives, and the pure classifier refuses embedded matches, eliminating the other possible empty fast path. (§12 records the exact guard and source-inspected routes.)

The final fallback inside the tail recognizer is only a successful pure expression, emitted as return. Every successful leaf therefore returns, continues through an aligned recursive call, or aborts according to its primitive domain. There is no successful in-domain branch which silently falls through to another while iteration. An infinite loop of continue steps corresponds to infinitely many original direct/alias calls; all non-call administrative pieces are finite under the declared host domain. This supplies the tail-specific no-new-silent-divergence argument.

### 8.5 Local theorem and integration

Induction on the successful tail derivation, with the parameter/alias invariant, proves equivalence to the already-eta-related original body for every finite interaction budget. A direct tail edge decreases that budget by one; an alias edge accounts for both original calls; any prior eta-eliminated event retains its TS-05 charge. Terminal pure and branch work are structural. The environment hypotheses are the ordinary input to a compositional proof, not a missing runtime implementation. TS-05 and actual erasure provenance establish the recognizer's printed-self interpretation; TS-01 supplies private/lexical safety; TS-02 and the primitive laws supply its data/leaf meanings.

The theorem includes direct use as an unregistered callable and callback entry via TS-04. It does not depend on a finite recursion test or the eventual compiler fixed point. The remaining end-to-end task is to connect the actual Core/source environment, groups and data to these same relations and reconcile the complete obligation set; the local tail proof does not require a new tail-specific runtime witness.


## 9. TS-08: module initialization and registration order

### 9.1 Emitted and admitted schedules

psTsEmitModule constructs the module in this order: runtime support, emitted imports, all structure declarations/brands, all inductive declarations/tags/constructor namespaces, and then runtime declarations in their original list order. The actual strict target refuses all external IR imports. The private UTF-8 state begins empty; its helper function declarations and the runner registry are available before any authored initializer. Layout constructors only assemble their received fields and private tag; they do not demand authored runtime globals during this layout prefix. [B2:193–202, 686–702; B1]

The target's declaration worklist starts with an empty earlier-runtime-global set. For each declaration it checks the actual type parameters, runtime parameters and entire body under a scope containing that self name and a flag indicating whether its runtime parameter list is nonempty. It adds the declaration to earlier only for subsequent declarations. Its readVariable rule accepts an existing lexical local first, then positive-arity self, then an earlier runtime declaration. A zero-arity self reference is refused. All nested lambda bodies and both conditional/match branches are traversed; hidden deferred forward dependencies are not exempt. [B1:406–437, 465–565]

The target's successful judgments therefore prove a syntactic property over every runtime variable occurrence: after its enclosing local binders are accounted for, the read is of an earlier declaration or the same positive-arity function. No call-graph guess or execution-order test is required for this conservative property.

### 9.2 Declaration-prefix induction

Induct over the emitted declaration list. The prefix invariant is:

- all runtime support and layout globals are initialized;
- each earlier eager declaration has produced its related value in its declaration position;
- each earlier positive-arity declaration denotes its corresponding callable, and a general declaration's registry association has executed;
- every closure captured from those declarations refers only to the associated lexical entries and permitted initialized globals/self, with the function relation's lower-index captures;
- an earlier value's initialization either returned with the threaded residue or stopped the module at the corresponding abort/divergence/cutoff.

For a positive-arity general declaration, emitting the public function and generator implementation does not execute its body. The following WeakMap.set establishes their concrete association before processing the next declaration. The function's recursive self behavior is defined at lower interaction indices; no same-index assumption that its body already preserves every call is used. An optimized count/tail declaration likewise installs a direct callable whose lower-index body behavior is supplied by TS-06/07. There is no registration obligation for that direct form.

For a nongeneric zero-runtime-arity declaration, the emitted const immediately runs a root generator evaluating its body. By the target occurrence property, every demanded global value/function is from the prefix; self is unavailable by explicit refusal. TS-03/04 therefore applies under the established prefix environment. When it returns, extending the prefix with its related value preserves the invariant. When it aborts, later declarations do not run; an Except.error result instead becomes that declaration's ordinary value and initialization continues.

A positive-arity function invoked during a later initializer can recursively call itself because its own registration has already executed, or it may be a direct optimized function. Its other free global reads were conservatively checked against its own earlier prefix. Thus it cannot indirectly demand a later uninitialized global just because JavaScript physically hoists function declarations.

JavaScript may allocate lexical bindings for the entire module, including later names. The closure/environment relation concerns actual referenced capture entries, not every slot an engine might represent in a module environment. A never-referenced future binding does not violate the prefix invariant. Conversely, hoisting is not used to excuse a source occurrence rejected by target admission.

A generic declaration with no runtime parameters is not silently assigned an arbitrary runtime value: the general emitter returns genericValueUnsupported, and count/tail refuse empty runtime parameter lists. Such an input is outside successful full emission. A nongeneric zero-arity value which returns a function remains eagerly evaluated to that function before the next declaration.

This source-derived invariant proves initialization and registry availability for every accepted emitted module. It deliberately does not provide general forward-reference or mutual-recursion semantics. The target rejects some safe delayed closures, but that conservative refusal is not a hole in the proof for accepted inputs. Connecting the prepared Core declaration identities/order to this actual IR list is the separate ER-01/ER-09 result; the backend-prefix induction itself needs no new runtime instrumentation.

## 10. TS-09: TypeScript-to-JavaScript and host execution boundary

### 10.1 The emitted language fragment

The six enabled primitive carriers are Nat/Int as bigint, Bool as boolean, Char/String as scalar-valid JavaScript strings, and Unit as undefined. Named data types instantiate the checked layout names; function types retain the exact ordered runtime parameter group and result type. Optional fixed-width, floating and word-sized type printers exist but do not become enabled capabilities merely by being printed. The target refuses unknown in the current strict typed path. [B9; RC; B1]

The trusted TypeScript step concerns a restricted emitted fragment: declarations and functions, type parameters/annotations/assertions, ordinary object/array expressions, bigint/string/Boolean expressions, conditionals, lexical const/let blocks, generator functions/yield*, loops/switches, private Symbols, a WeakMap, ordinary calls and the explicitly used built-ins. The proof interprets the resulting JavaScript behavior of this fragment. readonly, unique-symbol typing, generic instantiation expressions, non-null assertions and as annotations supply no extra runtime checks. Their erasure is part of the trusted compiler boundary.

This identifies a concrete assumption rather than hiding TypeScript correctness behind a hash. A separately verified TS compiler/JS engine would be a stronger assurance method, but is not required merely to state a valid conditional source argument. The active lane trusts the pinned compiler/engine and ordinary built-ins, with source values restricted by the explicit carrier domain.

### 10.2 Actual pinned CLI, configuration and products

The shared CLI helper accepts only version 7.0.2 and always adds --ignoreConfig for current positional compilation. It resolves the installed package's actual bin.tsc JavaScript launcher, checks that the package declares the typescript name and a relative launcher inside its own real package directory, and invokes that launcher through Node. It does not execute an arbitrary shell shim. The helper's filename/package ownership checks alone do not establish the installed version; sh1-qualify separately executes that exact launcher with --version and requires Version 7.0.2. [Q1; Q3:63–86]

compileTypeScript writes the exact emitted source and invokes the resolved launcher with:

    --ignoreConfig index.ts
    --target ES2022 --module ES2022 --moduleResolution bundler
    --strict --declaration --sourceMap --noEmitOnError
    --skipLibCheck --pretty false

The call uses process.execPath and a separate synchronous child process with a bounded timeout. Successful exit is required before the emitted JavaScript path is returned. The source-profile configuration requires the new-only 0.9-r3 grammar. The recipe and toolchain records bind source files, executing compiler identity, TypeScript profile/version, Node/Lean versions, original IR/admissions products and generated artifact hashes through their existing scoped receipts. [Q2:63–72; Q3:63–149, 335–475]

The active current lane is TypeScript 7.0.2. Historical replay branches and immutable earlier producer receipts retain their historical labels; the current command entry refuses retired historical commands. No retained historical metadata authorizes a TypeScript 5 compiler for new development. Exact source/toolchain qualification and cold selected-seed recovery remain separate obligations with their own actual receipts.

The bounded resource policy uses explicit process-entry headroom checks and an 8192 MiB old-space setting only for the designated generated qualification commands. It records scalar phase traces. It changes neither these expression semantics nor the source-level error relation, and it does not prove that every accepted program fits in memory. The previous out-of-memory observation is evidence of a capacity failure in its exact run, not a source primitive counterexample or a theorem that the reviewed reuse removes the peak. [Q4]

### 10.3 What this row can and cannot conclude

Given the trusted pinned TS/JS semantics for this restricted fragment, the preceding source arguments transfer the original-IR relation to the produced JavaScript. Type erasure removes annotations; ordinary runtime constructs preserve the expression, machine, optimizer and module-order arguments. The canonical carrier and successful-allocation premises are explicit parts of that judgment, not inferred from accepting a TypeScript cast.

A fixed point shows equality of recorded compiler products under an exact recipe. Same-IR checked/raw byte parity shows those entry points emitted the same bytes. A native finite observation reports its recorded inputs/results. A provider accepts only its actual submitted stream. None is a proof of the TypeScript compiler, a replacement for the 33 rule arguments, or permission to claim strict source preservation for a different ref. This document reports source derivations and their dependencies; it reports no new execution or qualification outcome.


## 11. Composition, precise dependencies and rejected stronger claims

### 11.1 Exported local lemmas

The following are source-rule arguments established above for the exact success branches, with explicit domains. “Conditional” means a theorem with its legitimate typing/value/host premises, not a placeholder which assumes the same theorem as a premise.

| Export | Established local conclusion | Required inputs |
| --- | --- | --- |
| TS-NAMES | Exact public/private identifier safety, first-candidate private freshness, complete admitted name scans, and safe emitted lexical/property scopes | Actual complete typing/target acceptance; exact name-index algebra; ER's actual identity association plus the source/eta occurrence argument in §6.3 |
| TS-LAYOUT | Brands, tags, constructor factories and record/field accesses implement the indexed immutable data representation; empty values remain empty and zero-field records remain inhabited | Actual checked layout/field order and θ; canonical related data; actual Core-to-layout association when used end to end |
| TS-TEMPLATES | All eleven general expressions preserve their IR rule's demand/result/abort relation at the returned residual | Related input environments; operation-specific value/demand laws; the mutually proved call/runner lemma |
| TS-RUNNER | Registered/direct entry, capture, ordered requests, returns, permitted aborts and callback reentry preserve one residual budget | Actual emitted callable association; exact group and related arguments; general-body induction or the relevant direct optimized/helper lemma; host generator/WeakMap/call semantics |
| TS-ETA | Every successful backend eta rewrite preserves the original IR call, callee control, captures and its logical invocation boundary | Exact recognizer success and its freshness/arity checks; initializer namespace relation; already-fixed IR group |
| TS-COUNT | Every successful count loop returns the original Nat fold on canonical finite data, with logical recursive calls and no new silent divergence | Actual self/field identity; related finite data; Nat law and representable successful allocation |
| TS-TAIL | Every successful tail derivation preserves old-environment argument values, capture meanings, direct/alias application boundaries and outcomes | Actual self identity; successful purity/binding checks; canonical data/primitive laws; TS-ETA |
| TS-INIT | Every actual emitted module prefix has its required initialized values, callable implementations and general registrations | Target's all-occurrence earlier/self restriction; the expression/call/optimizer lemmas; actual ordered IR list |
| TS-HOST | The preceding emitted-fragment arguments apply to its pinned generated JavaScript | Trusted TypeScript 7.0.2, Node 22.23.3 and the stated ordinary built-in/resource/carrier domain; actual successful configured compilation |

In particular, constructor-field order, private names, full target worklist completion, lambda-weighted depth, old-environment tuple assignment, alias nonescape and global registration order are not left as unexplained production invariants. Their source branches and preservation arguments are given explicitly. Actual-source self recognition is resolved by ordinary output-name reservation and eta callee-position provenance. Empty fallback routing is corrected and source-reviewed in the current code.

These local lemmas can be used in the root EV expression argument. The shared function relation prevents circularity: at a semantic call, its body is related only after that call's charge; closure/global behavioral premises are lower-index; finite data and non-call syntax cases decrease structurally. Module initialization additionally decreases the declaration prefix. A caller may import TS-RUNNER while TS-RUNNER's ordinary generator-body case uses the structural expression theorem, provided these are stated as the same mutual index/syntax construction rather than as two independently assumed conclusions.

Progress is similarly decomposed. The runner handles finite administrative segments and each call/return transition; fixed helpers use finite string/array bounds; eta moves only finite silent lookups/bindings; count decreases a proper stored-child measure; each successful continuing tail path accounts for one direct or two alias-mediated original applications. No optimizer is justified solely by TypeScript typing or a recognizer's Boolean success.

### 11.2 Dependencies which are genuinely outside these local backend arguments

For the actual source-to-JavaScript result, the following interfaces still have to be composed and reconciled:

- The source/Core operational interpretation and Π must establish the original runtime meaning and retained group of each source application, including proof/type classification, direct lambda flattening and result-arrow exposure. An IR backend proof does not prove that its input IR has that source meaning.
- ER must associate the actual opened Core binder IDs, runtime/substitution maps, layouts, constructor fields and output names with the same E/W/θ used here. The source facts consumed by TS are explicit; a hash or printed name alone is insufficient.
- The enabled primitive/native meanings, bounds premises, Unicode canonicality and representable host carrier domains must be exactly those of the operation contract and runtime-law argument. The callback part composes with the proved function/machine relation; it cannot be discharged by native scalar examples alone.
- The complete combined argument must supply all-n adequacy for the independent source/Core computation, using the locally proved no-new-silent-stuttering cases and any other required termination/divergence facts. Resource cost equality is not among those obligations.
- Exact execution/ref/toolchain evidence and the normative profile activation decision must be reconciled separately. A source argument and a run receipt have different content, and both must be described truthfully.

There is no requirement here to add a serialized erasure certificate, a new IR evaluator, a metatheory change or a machine-checked theorem solely because this document is a rule-level proof. SPEC permits an adequate general source argument. Conversely, replacing a missing actual production association with the phrase “assume preservation” would not be an adequate argument. The table above identifies where the current source supplies a concrete derivation and where an upstream shared semantic interface is genuinely needed.

The strict ledger remains unchanged by this document. All 33 rows retain their recorded open status until the owner has integrated the complete argument and evidence. That administrative status does not negate the proved conditional local lemmas; it prevents this one backend packet from unilaterally closing unrelated source, normalizer, erasure, primitive or toolchain claims.

### 11.3 Two source-inspected countermodels to target-only claims

These are mathematical IR constructions examined against the actual source branches. They have not been executed as new fixtures and are not claimed to originate from accepted PSC1 source.

**Implicit constructor in a let initializer.** Let D be an inductive with a nullary constructor leaf, and let an otherwise ordinary zero-arity declaration's body be:

    let D : D = constructor D.leaf;
    var D

The IR initializer is checked in the old scope and contains no explicit variable D. The target constructor check therefore sees no local D yet; its later body var D reads the local. The emitter's explicit-name scan also sees no D variable in the initializer, so its lexical-const branch would print a value initializer containing D["leaf"] under const D. That introduces a temporal-dead-zone access and can be rejected by the TypeScript step. Complete IR typing plus target checking alone therefore does not guarantee the source allocator's stronger initializer-owner property. Actual source erasure excludes this binder name through byOutput reservation; eta-generated initializers are only variables. [B3:12–51,491–510; B1:491–517; B7–B8]

**Shadowed count self.** Consider an arbitrary IR family Chain with constructors base and step. The step fields are child : Chain and override : (Chain) → Nat. A declaration tally(x : Chain) : Nat matches x: base returns 0; step binds its fields as child and a local named tally, then returns 1 + tally(child).

The IR checker and target resolve lexical bindings before globals/self. They permit that local function field to shadow the declaration's printed name. On step(base, λ _ . 7), the IR computation returns 8. The count recognizer compares that callee spelling with the declaration name and selects child; its loop would return 1. Function-valued field types are checked as runtime types; these checks are not a Core inductive-positivity theorem. This is a countermodel to arbitrary typed-target-IR self identity, not a source-reachable defect claim. The actual erasure allocator and the eta provenance derivation in §6.3 exclude precisely this misleading self occurrence in the intended source-owned lane. [B4:111–126,359–378,785 onward; B1:530–536; B2:320–428]

The second example is useful even if a future source frontend refuses that data declaration for separate positivity reasons: it refutes the proposed premise “typed target IR alone proves self identity.” It does not broaden the enabled source domain or justify removing any admission gate.

### 11.4 Extensional eta is a different assertion from source demand

In an independent call-by-value language, a curried function whose first application computes a callback before returning its second closure can differ in demand from a function which waits for both arguments before computing that callback. Equality of their final values after all arguments does not imply equality of proper-prefix demand. This is why the source result-arrow transformation needs ER-ETA-GROUP/Π and cannot borrow TS-ETA's theorem.

The backend eta optimizer examined here starts from one fixed original-IR call whose argument expressions are already fresh variable values. Its callee-control/demand argument is therefore substantially narrower and is proved in §6. The partial-completion capture repair also has its own prefix demand argument. These three paths are kept distinct in the common relation and in this packet.

## 12. Concrete empty-tail correction at the current source boundary

During the bounded source audit, the preceding Module accepted an empty alternative list in the tail match case. Mapping a converter over that empty list succeeded, and the emitter built an invalid-tag switch rather than declining to the corrected general empty emitter. This was a real dispatcher-route discrepancy against the existing four typed-never emission expectations. It did not establish a fabricated Empty value or justify changing the tests.

The exact current correction is:

    | PsVerifiedIrExpr.matchE name _ scrutinee alternatives =>
        if psListIsEmpty alternatives then Option.none
        else
          … preceding nonempty branch, unchanged …

The old branch is only indented under else. All nonempty case text and runtime helper/cache behavior are unchanged. Root published the reviewed candidate as Module blob 2580754407e70be69cc10101c4ebe03c7304a8f0 in commit 3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc. The exact guarded edit and independent source review are in manifest a3db2591e9e0d7f7dcbef45ad4cc241980d92095. [B2R]

The unchanged native fixture has four empty-elimination routes:

| Existing route | Current dispatch derived from source |
| --- | --- |
| nativeEmptyNat, direct empty body | Count requires two alternatives; tail now declines empty; general prints the typed-never generator. |
| nativeEmptyFunction, function-result empty body | Count's result-type requirement fails; tail now declines empty; general prints the same typed-never branch. |
| nativeEmptyGeneric | Tail refuses declaration type parameters; general already uses the typed-never branch. |
| nativeEmptyTypedCall | The typed let-wrapped empty callee is not a recognized tail callee; the general call path retains that typed empty generator. |

The fixture asserts four occurrences by requiring splitOn("__ps$Computation<never>").length = 5. The guard restores those four source paths; no fixture count, raw input, native invocation, TypeScript process or runtime semantic observation was added or weakened by this correction. Count's two-alternative requirement and the pure classifier's match/let/lambda refusals complete the empty fast-path audit. A nested empty tail branch propagates none and makes the whole declaration fall back. [Q5:49–90,143–148]

These are source-path conclusions. The execution result for the exact source belongs to the separate qualification receipt and is not invented here. This document records no compiler run, provider result or strict activation.

## 13. Immutable source index and review boundary

Source coordinates in this document are one-based line references into the pinned blobs below. B2 uses the preceding Module for stable coordinates; B2R is the only current Module delta, adding the empty-alternatives guard and indenting the prior branch. Current Check B4 contains the explicit PsIrCheckState annotation; no checker meaning is inferred from the previous inference failure.

| ID | Repository path / subject | Immutable blob |
| --- | --- | --- |
| R | psc0/docs/selfhost-language/strict/SEMANTIC_RELATIONS.md, budget-threaded final foundation | 40e540b325186ee514ff3af9e39a22126d29a167 |
| L | psc0/docs/selfhost-language/strict/correspondence-obligations.json, current 33-row ledger | 9ae363efcb6faab4ffd6c10af0e498ece6004649 |
| RC | psc0/docs/selfhost-language/strict/enabled-runtime-contract.json | 8c893f0ecbc37855d02a006bb2774de4b0ebde2b |
| RL | psc0/docs/selfhost-language/strict/RUNTIME_LAW_REVIEW.md | 682250126807cf520fb4c354ad0b52577a04d8b0 |
| B1 | psc0/packages/backend-ts/src/Ps/BackendTs/Sh1Target.lean | a0e7031d8a5e969fad44ab82b80aecbcc88f1139 |
| B2 | psc0/packages/backend-ts/src/Ps/BackendTs/Module.lean, preceding coordinate base | 98bac2823502c641c9b386f0ee1328cd7a688e87 |
| B2R | Same path, current empty-tail guard | 2580754407e70be69cc10101c4ebe03c7304a8f0 |
| B3 | psc0/packages/backend-ts/src/Ps/BackendTs/Expr.lean | a0ab0d6a224bdfd35846990ab6d6e39df422908e |
| B4 | psc0/packages/compiler-ir/src/Ps/CompilerIr/Check.lean, current explicit state annotation | 178ecf89498be6502be5f747f0c0d62eb1133420 |
| B5 | psc0/packages/backend-ts/src/Ps/BackendTs/Sh1.lean | 1026e3a9d1f89432d9a94d9cd098900f6e4d8b53 |
| B6 | psc0/packages/compiler/src/Ps/Compiler/Sh1.lean | a947a4058e3d91a02d4f8120a3d86556100c8555 |
| B7 | psc0/packages/erasure/src/Ps/Erasure/Basic.lean | e0c932e0280b9c0e2b7f7ad1974b548881f452d0 |
| B8 | psc0/packages/erasure/src/Ps/Erasure/Definition.lean | 709fc44f59bddb3c3d7354ba31ea01f296c9cde8 |
| B9 | psc0/packages/backend-ts/src/Ps/BackendTs/Type.lean | 8c9dcf6b0168dcb1edc49d87130fbee09a47cd79 |
| B10 | psc0/packages/erasure/src/Ps/Erasure/Expr.lean, current Nat/partial/empty and eta implementation | 6da268d23db1d2a709134f54dc8ae8a7f81367d3 |
| Q1 | psc0/scripts/typescript-cli.mjs | 9d6607a6f4284b0afba8023566f6e1d75c30a64a |
| Q2 | psc0/scripts/sh1-capabilities.mjs, shared TypeScript compile helper | 8d87080352509dc936614d560aa68ded14fc36e8 |
| Q3 | psc0/scripts/sh1-qualify.mjs | eedce11a6d99dee010c3de4352a716e5385eb156 |
| Q4 | psc0/scripts/sh1-resource-policy.mjs | 7e3066c513a91a6e0717aac9465a879097c0dd82 |
| Q5 | psc0/test/IrCheckerTests.lean, existing empty/zero-field expectations | 2f507fdaef96411dfa5833016c94655549b99938 |
| G | Reviewed empty-tail guarded manifest | a3db2591e9e0d7f7dcbef45ad4cc241980d92095 |

The implementation boundary is [commit 3c0c07f2](https://github.com/dwijayuda/pskernel/tree/3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc/psc0). The document's creation/review manifest records its content hash, exact source pins and bounded independent review; it does not update refs or activate a profile. Kernel, provider, definitional equality, metatheory, runtime helper/cache algorithms, source grammar, seed identity and compiler/toolchain pins are unchanged by this documentation work.
