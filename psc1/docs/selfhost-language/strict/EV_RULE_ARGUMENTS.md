# Original IR to JavaScript: EV-01–EV-11 rule arguments

## Status and exact scope

This packet gives source-level arguments for all eleven expression constructors handled by the general TypeScript emitter. The source anchor is **3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc**, including the reviewed empty-tail fallback in BackendTs/Module.lean. The common value, environment, computation, call and error relations are the final **SEMANTIC_RELATIONS.md**, blob **40e540b325186ee514ff3af9e39a22126d29a167**. Its shared residual interaction budget is used throughout; earlier exact-result-at-index0 wording is superseded. [E01–E06]

The result here is a complete case argument for the general expression translation, under explicit interface premises. It is not a claim that all source normalization, erasure, target optimization, TypeScript translation or host semantics has already been established. In particular, proving the general emitter's lambda/call cases with an application interface is not a license to assume correctness of every optimized callable implementing that interface. Section15 identifies the actual remaining interfaces, separately from ordinary induction hypotheses and the declared trusted implementation boundary.

The normative contract remains SPEC.md and the enabled runtime contract. There is no new capability, narrower source subset, serialized correspondence-certificate requirement, production code change, test invocation, metatheory change or formal theorem in this document. The current full cloud run is separate finite evidence; it cannot supply the universal premises used here. All strict/general qualification flags remain false until the root integration ledger discharges the actual mandatory dependencies. [E07–E08]

## 1. The conditional expression statement

Fix the actual original IR module I produced by one successful atomic compilation, its successful complete IR check and target admission, the actual brand/tag maps built for I, and successful general emission of an expression e. Fix a supported closed runtime type assignment θ and a value environment associated with the IR lexical environment. These are the actual objects, not similarly named replacements from another compilation.

The expression statement G(n,e) is: starting in related environments E^n_IJ, evaluation of e and execution of its emitted general-expression code within corresponding generator continuations have the computation relation C^n_IJ at e's checked result type. Its observation carries the residual budget through every demanded subexpression; each matched logical application consumes one unit immediately before body entry. A result obtained with residual r has relation V^r. At zero budget, execution is observed only up to the next application boundary; no later result is claimed. [E06]

In addition to the ordinary related-environment premise, G uses these named implementation interfaces:

| Interface | Required fact | Intended owner |
| --- | --- | --- |
| J-NAMES | Every printed reference, private helper, implicit constructor namespace and generated temporary denotes its intended entity in the emitted lexical scope. A let declaration cannot capture an implicit namespace in its own initializer. | TS-01 with actual erasure-name provenance in ER-09 |
| J-LAYOUT | The actual IR structure/inductive layouts produce the brand, tag, field and constructor associations specified by the value relation. | TS-02/03; Core-to-IR association belongs to ER-05–08 |
| J-CALL | Registered generator implementations and permitted direct generated callables satisfy the same exact-group application interface, including nested runner entry from callbacks. | TS-04 and optimization cases TS-05–07 |
| J-INIT | The module environment supplies initialized helpers, symbols, constructor objects and earlier permitted globals, with the actual declaration dependency/order rules. | TS-08 |
| J-HOST | The declared ordinary TypeScript7/Node22 semantics, canonical carriers, immutable ownership and representable successful-allocation assumptions hold. | Explicit trusted boundary and TS-09 |
| J-LAWS | The 43 first-order primitive laws and two higher-order iteration schemas apply on their declared domains. | RUNTIME_LAW_REVIEW plus EV-03 below |

A correctly formulated proof may assume E^n and the induction hypothesis for smaller expressions; these are quantified hypotheses of G, not undiscovered defects. By contrast, obtaining J-NAMES for every reachable erasure path, proving J-CALL for every selected optimizer, and composing Core/IR grouping with J-CALL are substantive implementation obligations. A passing target type check alone is not any of those proofs.

### 1.1 Well-founded case structure and residual composition

For positive emission fuel, psTsEmitExprWithFuel calls its smaller emitter only on proper expression children. A zero-fuel call returns fuelExhausted, so it cannot enter the successful-emission theorem. Consecutive lets are handled by psTsEmitLetStatements, whose recursive body is a strict syntactic subterm. A simultaneous structural induction on these two source functions establishes the expression and statement cases. That induction describes code formation; it does not execute the generated program during compilation. [E01]

The function behavior clause uses the separate interaction index. At index n+1, entering a related function consumes one unit, and its body is compared at an arbitrary residual j≤n with its captured environment and arguments weakened to E^j/V^j. A lambda's syntax is a smaller subterm; recursive/global calls obtain their behavior from the decreasing function index and the module/function relation, not from an assumption of same-index recursive correctness. This separates structural induction over code from behavioral induction over applications. [E06]

Sequential composition is essential. If e1 returns a related value with residual r1, then e2 starts at r1; previously obtained values and the enclosing environment are weakened to that index. Continue in this way for a list of operands or initializer/body sequence. An abort stops later demands. A cutoff stops the comparison before an unlicensed call and imposes no claim on later behavior. Giving each operand, callback or nested runner a fresh n would invalidate the argument; none of the cases below does so.

### 1.2 Formation and order of finite printed lists

psListMapExcept visits a finite list's head first. A head error returns immediately; a successful head is prepended to the recursively obtained tail. Induction on the input list establishes that successful output has exactly the same length and order, with one converted result for each input. An error is the first compile-time failure in that traversal. psTsJoin preserves the order of those strings, inserting only its specified separators. psListZip consumes one item from each input; callers needing no truncation must first establish equal lengths. These statements follow from the explicit nil/cons branches. [E09–E10]

These are compilation facts, not runtime order. For example, the match emitter prints alternatives before printing the scrutinee; generated code still evaluates the scrutinee before selecting an alternative. Runtime order follows the emitted JavaScript expression/statement forms below.

### 1.3 Observations and compiler failures

Compiler refusals such as unsupportedIntrinsic, intrinsicArity, unknownStructure, unknownInductive or fuelExhausted are outside the premise of successful emission. They are not source exceptions returned by a compiled program. Similarly, a source Except.error is ordinary data in V, distinct from a host throw. The enabled contract's defensive array-bounds and malformed-tag behavior does not enlarge the source domain with arbitrary foreign objects. Resource exhaustion is governed by the stated host boundary and cannot be counted as successful complete evidence. [E06–E08]

## 2. EV-01 — literals

psTsEmitLiteral has five enabled IR literal constructors after machine-integer literals are excluded by strict admission: natural, integer, string, Boolean and Unit. Char is supplied through enabled operations rather than a separate literal constructor, so the five literal constructors serve six primitive value types. Optional machine-integer printing exists in the broad datatype but is not an enabled strict capability. [E02–E04]

For a natural n, psNatToString is the native natural decimal representation and the emitter appends the bigint suffix. Under the trusted decimal-printing and bigint parsing laws, the emitted literal denotes exactly n and is nonnegative. For an integer z, Int.repr provides its signed canonical decimal representation and the same suffix produces the represented bigint; a negative value is a unary-minus bigint expression rather than a distinct signed lexical token. This implements the separate Nat and Int value clauses without conflating their source types. The claim is for every representable input satisfying the resource premise, not only the finite numbers in a fixture. [E02, E10]

The Boolean branches return the tokens true or false according to the input's two constructors. Exhausting these two possibilities is a general proof on the Boolean carrier. Unit returns undefined, the unique host representative fixed by V_Unit; J-NAMES ensures the emitted undefined reference has the intended ordinary binding. Producing these values demands no source operand, function body or callback.

### 2.1 Complete string escaping

The String case calls psJsonQuote. Its psJsonStringToChars invokes the raw-byte traversal with utf8ByteSize(s)+1 fuel and byte position0. For a canonical scalar string, each successful next step consumes the current scalar's positive UTF-8 width, at least one byte. If B is byte length and L is scalar count, L≤B; consequently B+1 permits all L scalar steps and an at-end decision. The zero-fuel fallback that merely returns the accumulated prefix cannot truncate this particular well-formed call. This relies on the pinned native String.get/next/atEnd/utf8ByteSize laws already stated in the runtime-law review. [E11–E12]

The accumulator contains the reverse of the scalars visited so far. The nil/cons reverse recursion restores their original order at the end. psJsonEscapeChars recursively concatenates one escape for the head and the escaped tail, preserving that order. The escape-character case partition is exhaustive:

- Backspace, tab, LF, form feed and CR receive their standard single-character escapes.
- The double quote and backslash receive their escaping prefixes.
- Every remaining code below32 is written as a four-hex-digit control escape, with leading00 and quotient/remainder by16 selecting the last two digits. The low range guarantees both selected digits are in0..15.
- Every other valid scalar is copied as that scalar.

Surrogate code points cannot occur as scalar Char inputs. The surrounding quotes, quote/backslash cases and control escaping therefore form a valid quoted string under the stated current ECMAScript/TypeScript string-literal semantics, including the modern JSON-superset treatment of U+2028/U+2029. Those standard parsing semantics are a J-HOST assumption; this document does not claim to have independently verified the TypeScript parser. Concatenating the decoded character cases reconstructs exactly the original scalar sequence, without normalization. Canonical UTF-16 encoding gives the String value relation. The same quote helper is used for constructor tags and diagnostic strings, where its correctness is a formation premise, not another runtime expression demand. [E11]

No interaction is consumed by a literal. Its result is related at the unchanged residual index, including index0.

## 3. EV-02 — variables

The .var branch returns its name unchanged. Target admission is responsible for its legal binding/reference position; E^n_IJ states that the nearest corresponding IR and JavaScript lexical bindings hold related values. Reading the identifier therefore returns the related value without reevaluating the initializer that established the binding. Weakening handles any residual index inherited from earlier operands. [E01, E05–E06]

For a global, J-INIT and the actual global-name association supply the binding instead. An earlier initialized scalar is a stored value; a function reference is a related callable whose body is not run by the lookup. A same-spelled inner binder is resolved lexically, so the proof follows binding identity and the actual scope association, not equality of strings across scopes.

This local case does not reconstruct a missing Core-local-to-IR mapping. ER-09 must show that erasure chose the intended emitted name. Nor does it prove a count/tail recognizer's printed self-name denotes the global function; that is a separate optimizer/source-provenance premise. Direct identifier lookup is silent under the ordinary immutable lexical-environment model.


## 4. EV-03 — the complete intrinsic family

The intrinsic branch first prints the finite argument list with the smaller emitter and then calls psTsEmitIntrinsicFromPrinted. The complete function from that declaration up to psTsEmitLetStatements is **byte-identical** between the reviewed two-operation candidate dfd58154826c892d18b97b84303abbce6a622d7b and current Expr blob a0ab0d6a224bdfd35846990ab6d6e39df422908e:14514 characters. This exact comparison connects the 45 operation arguments in RUNTIME_LAW_REVIEW to the current source. It is a source equality check, not new execution evidence. [E01, E12]

The operation partition is exhaustive for strict SH/1:9 Nat,10 Int,5 Bool,2 Char,10 String and9 Array operations. The 43 first-order cases are the nine Nat laws, ten Int laws, five Boolean laws, two Char laws, ten String laws and seven Array laws excluding map/foldl. Optional machine-integer and floating operations in the broad emitter are refused by the strict domain and are not silently included in this theorem. Exact checked arity and parameter types are used; the psTsPrinted1/2/3/5 helpers return intrinsicArity if their finite argument shape is different. [E01, E04, E07–E08, E12]

### 4.1 Strict and selected operand demands

For a strict operation, the emitted operator or IIFE evaluates the identified operand expressions once in the declared order. A source expression substituted as an IIFE argument is evaluated before the parameter binding exists; repeated parameter reads inside its body repeat a value lookup, not the source computation. The residual-budget sequencing lemma in §1.1 composes the child computations, and the local value law gives the result at the final residual index.

For natSub/div/mod, the local Boolean guard handles truncated subtraction and zero denominators after both operands have been demanded. The divisor-zero branch does not execute a throwing host division. Equality assertions widen only TypeScript types and erase before runtime; they do not coerce values or add demands. The analogous first-order arithmetic/string/array templates use the same sequential argument reasoning. Ordinary Number conversion of an array index occurs only after the relevant bound establishes exact representability in the host array range. [E12]

Bool.and/or are selected-demand operations. JavaScript && and || evaluate the first Boolean once and then either return its decisive Boolean value or demand the second expression. The two possible first values establish precisely the runtime contract's branch rule. Printing the second expression at compile time does not execute it. The false/true cases therefore preserve both result and absence of an unselected demand; ordinary strict two-argument application must not be substituted for this intrinsic rule.

Two already integrated repairs are relevant to composition. stringAtEnd now evaluates its text and then its position as IIFE arguments before comparing the position with the computed byte size. arrayEmptyWithCapacity now evaluates the supplied capacity outside the helper body, passes its already obtained value once, and returns the empty array. Ignoring a capacity's value as an allocation hint does not ignore the capacity expression. Those exact templates, rather than their former versions, are in the current equality above. [E01, E12]

arrayPush spreads the related dense input array before evaluating the appended value expression. Its copying/ordinary element reads are finite and silent under the canonical immutable host domain, so this administrative copying may occur between the two identified operand demands. The claim would fail for arbitrary getters, custom iterators or external mutation; those are not the declared domain. Allocation timing and identity are not observations of immutable source arrays. The appended expression is still demanded once after the input expression and the original array remains value-equivalent. [E08, E12]

### 4.2 Higher-order map: a residual prefix invariant

After evaluating the callback and array expressions in order, arrayMap passes their obtained values to its IIFE. The JavaScript map adapter invokes the source-owned callback with exactly one element; the built-in map's additional index/array arguments are not forwarded. On an ordinary dense array of length m, the built-in iterates precisely the indices0 through m−1, in ascending order, without holes or user-supplied accessors. [E01, E12]

The induction invariant after k completed callbacks is:

1. The source/IR and host have processed the same k positions.
2. Their result prefixes have length k, with each corresponding element related at its declared result type and weakened to the current residual index r.
3. The callback and unprocessed input elements remain related at that residual index, and the input sequence has not changed.
4. The demand prefix and residual r are the ones returned by those k callback computations.

At k<m with r>0, obtain the next related element, consume one unit for that prescribed callback application, and use the related callback's body clause at r−1. A returned value extends both prefixes and yields the residue for the next iteration. A permitted abort ends both pending computations at that point; a cutoff at the next call boundary imposes no result claim beyond that boundary. If r=0, the observation stops before the next callback, even if a physical host run could continue. There is no fresh budget per element. At k=m, the invariant supplies a complete related array at its returned residue, including the empty-array case with no callbacks.

This is induction over an arbitrary finite related array and all permitted residual budgets. It is not extrapolation from a chosen collection of callback tests. J-CALL supplies the generated callback application, including nested runner entry; a diagnostic foreign JavaScript function is not a substitute for that premise.

### 4.3 Higher-order fold: a range and accumulator invariant

The emitted arrayFoldl IIFE demands callback, initial accumulator, array, start and stop in that order. It obtains size m from the already related array and sets end=min(stop,m). The start/stop values are related naturals. If start≥end, the loop is not entered and the already obtained initial value is returned without a callback. [E01, E12]

Otherwise, at loop index i the invariant is that start≤i≤end, the accumulator is the fold of exactly the source prefix [start,i), and the residual is the one returned after those i−start prescribed callback applications. Every i<end is below m, so the element is present and Number(i) denotes the exact host index. The callback group is precisely (accumulator,element). A completed related callback updates the accumulator and yields the shared residue; incrementing i is silent administrative work. The measure end−i strictly decreases for a completed iteration. At end the related final accumulator is returned.

Abort and cutoff propagation use the same rule as map. Callback reentry does not reset the allowance. This proves the higher-order local schema once J-CALL and the source primitive interpretation are supplied. The latter interpretation is pinned in the runtime-law review; identifying the actual erased Core operation and proof/type operands remains an ER obligation.

### 4.4 Primitive domains, faults and finite internal work

For arrayGet/arraySet, the source relation includes the proof-required i<size domain. Their defensive emitted bounds faults outside that domain do not prove the existence of an erased source proof. arrayGetD evaluates its fallback as an ordinary supplied argument even when the chosen element exists; preserving only the returned element would miss that demand. arraySetIfInBounds preserves values when the index is outside the size and otherwise performs the pointwise replacement. Present undefined values remain valid Unit elements; density and length establish presence. [E12]

String laws quantify over canonical scalar sequences and all declared raw byte positions, including the documented non-boundary fallbacks. The existing helper's two-entry cache changes only how its exact byte-index view is obtained; cache-hit equality denotes the same immutable text. No cache algorithm is changed here. Numeric comparison precedes potentially lossy host index conversion where required by the law.

For complete-execution adequacy, the internal non-callback work of these primitives is finite on a finite represented input under the host premise: fixed arithmetic/guard expressions terminate, array copies/ranges have finite length, and UTF-8 loops advance over a finite scalar string. Their trusted built-in implementation may allocate or fail outside the resource premise; the proof does not equate native and V8 costs. A map/fold iteration containing a callback is a logical application, so an infinite callback sequence cannot disappear as uncounted administrative work. [E08, E12]

## 5. EV-04 — lambda creation and lexical capture

The lambda emitter prints a parameter list in the checked order, the result type and a smaller emitted body, then returns a call to __ps$wrap with a generator function expression. Executing that expression creates the generator implementation in the current JavaScript lexical environment. It does not enter the authored body. __ps$wrap creates a synchronous public function and records its exact implementation in the private WeakMap. Its work contains no authored operand or callback evaluation. [E01, E03]

The corresponding IR lambda produces a closure over its current environment, exact parameter group, result type and body. J-NAMES and E supply the same associated captures. At function index0, the group, callable form, structural capture edges and implementation identity match. At index n+1, choose j≤n and arguments related at the parameter types at j. After the invocation's single budget charge, extend both captured environments with the complete ordered argument group. The body is a proper syntax subterm, so the induction hypothesis at residual j gives C^j for the body. J-CALL turns the registered implementation's generator execution into that same application computation. This establishes the function value clause; closure construction itself leaves the caller's budget unchanged. [E06]

A later mutation of an unrelated local frame is not introduced by this argument: authored lexical captures denote immutable bindings. Optimized top-level callables may use private mutable loop parameters internally, but their escape/capture discipline belongs to the optimizer proof. Likewise a recursive global capture is addressed at a lower function index and the module world association, not by a same-index environment assumption. The proof does not require every permitted generated callable to be in the registry, because J-CALL also covers the direct optimized forms.

## 6. EV-05 — exact grouped application

The call emitter prints the callee, any TypeScript type arguments and each runtime operand, then emits a delegated __ps$invoke call. A directly printed lambda is parenthesized; all other successful callee forms already occupy a valid expression position. Lookup of the private helper is silent under J-NAMES/J-INIT. JavaScript obtains the callee value and then the runtime arguments left to right before the invoke generator yields its request. Each source subexpression occurs once in this emitted argument list. [E01, E03]

Apply G successively to the callee and operands with residual threading. At the resulting invocation boundary, a positive residue r licenses the related function clause at r−1 with arguments and captures weakened accordingly. __ps$invoke packages the already obtained callee and argument values, yields the request and later returns the supplied result. J-CALL relates registry dispatch or direct generated invocation to that single logical application and its continuation. Helper entry, wrapping, Reflect.apply and registry lookup do not each consume another semantic unit. An error in a demanded child prevents later operands; an error in the callee body abandons the pending continuation. A zero residue cuts off before entering the body. [E06]

Exact parameter-group checking matters. The theorem uses the checked IR group's arity and order; it does not identify a two-parameter call with one application returning another function. TypeScript type arguments instantiate the already admitted rank-1 callable type and are erased, so they supply no runtime operand and consume no budget. Admitted generic calls use the supported direct callable/type-argument path; arbitrary higher-rank values are not inferred from erased syntax.

This case begins at original IR. It does not justify a source eraser changing Core call groups or the time at which a function-valued source body is demanded. Missing-argument capture, erasure result-arrow exposure, and backend eta inlining have separate producer arguments. The ordinary IR call rule remains the reference for each of them.


## 7. EV-06 — old-scope let initialization

psTsEmitLetStatements has two success paths for a let and a terminal return path for every other expression. Its recursive body translation produces nested statement scopes; the top general .letE branch delegates to the resulting generator IIFE. The declaration's type annotation is erased before runtime. In both paths the required semantic sequence is initializer in the old environment, then body in the extended environment. [E01]

### 7.1 Conservative name-use path

If psTsExprUsesNameWithFuel(4096,value,name) is true, the output is a generator function with name as a parameter, called with the printed initializer as its argument. JavaScript evaluates that argument outside the callee's parameter scope. Consequently even a same-named outer variable, or a closure that captures it in the initializer, is resolved before the new binding exists. Only after a related initializer value returns is the generator body entered with the new parameter binding. The body receives the initializer's residual budget. Delegation and the parameter IIFE are administrative realizations of a let, not a new IR application event.

The scanner may return true because an occurrence is present, a nested binder has the name, or the fuel is exhausted. False positives select the safe parameter path and do not remove a computation. The proof of this path therefore does not require scanner completeness.

### 7.2 Lexical-const path

If the scanner returns false, the output is a block containing const name = printedValue followed by the recursively emitted body. A lexical const binding exists during its initializer's evaluation and is not initialized yet. It is therefore necessary to show that the initializer's emitted code cannot refer to that new binding; merely saying “the IR initializer is outside the binder” would miss JavaScript's temporal dead zone.

A structural induction over the scanner gives the explicit-name fact: a false result excludes the tested name from every visited .var and from each named lambda parameter, let binder and match binding, traversing all expression children. The zero-fuel result is true, so a successful false result has not hidden an unvisited suffix behind exhaustion. The scanner conservatively descends into lambdas and alternatives even if they are not immediately executed. This excludes deferred explicit-name capture inside an initializer closure as well. [E01]

That fact is not complete target hygiene by itself. Constructor emission introduces a value reference to its owner namespace even though the scanner visits only the constructor's fields. Other templates introduce fixed helper names. J-NAMES must therefore supply the additional implicit-reference premise. In the actual source pipeline, ordinary erasure-selected local names avoid output owners; backend EtaBind introduces only variable initializers; and erasure-generated result-eta parameters receive the target's lexical owner-capture check at constructor occurrences in their bodies. These producer facts must be imported from the exact ER-09/TS-01 source arguments. A stand-alone arbitrary typed IR let could otherwise be accepted in the initializer's old scope while its printed const captures an implicit namespace. The theorem uses actual source provenance rather than claiming that IR typing alone repairs that mismatch.

With both explicit and implicit references protected, evaluating the initializer inside the otherwise empty new const scope has exactly the old-scope meaning and demands. Its related value initializes the binding once. Lexical extension then satisfies E at the returned residue for the translated body. Nested blocks retain same-spelled outer bindings for their own initializers and make the new binding available only to the corresponding body.

### 7.3 Statement induction

For each consecutive let, apply the appropriate path above and recurse on the proper body subterm. At the terminal non-let expression, the emitted return obtains the child's related result and supplies it to the delegating continuation. Thus the statement translation proves the let expression case for arbitrary finite let chains, not only one same-name example. There is no body execution at generator creation, no duplicated initializer, and no budget reset across the chain.

## 8. EV-07 — Boolean branch selection

The emitter prints a parenthesized conditional expression. Executing it demands the condition once. By its checked Boolean type and G, the obtained host value is exactly the related true or false. JavaScript's conditional operator then evaluates only the matching branch. Applying G to that branch at the condition's returned residue supplies the result, abort or next cutoff boundary. The other branch is not demanded. [E01, E04]

Printing both branches is necessary code formation and has no runtime meaning. The emitted parentheses also make the conditional safe as an operand, callee, field or projection target. The case does not consume an application unit unless the selected child computation does so.

## 9. EV-08 — records and the inhabited zero-field case

For .record, the emitter first resolves the associated brand from the actual map. A failed lookup is a compile-time refusal, excluded by successful emission. For a successful lookup it prints a parenthesized object literal whose first property is the private symbol brand and whose remaining properties follow the checked field list. psListMapExcept and psTsJoin preserve that list order. [E01, E03, E09]

At runtime the already initialized brand lookup and constant true value are silent. Each authored field expression is then evaluated once, in order, and residual composition gives related field values at the final residue. J-LAYOUT identifies those properties with the structure's ordered retained fields. J-NAMES/target admission exclude unsafe property syntax, especially the special __proto__ property, and keep helper/symbol references separate from authored bindings. The resulting ordinary object has the required brand and present own fields, so it satisfies the structure value clause. [E05–E06]

For an empty field list, the same object construction produces a brand-only object. It is an actual value of a structure with one zero-field constructor. It is not an empty inductive, undefined, or an eliminated ghost. This case needs no field computation and leaves the budget unchanged. The runtime contract does not expose object identity or allow source mutation of these records; copying/allocation identity is outside its observations. Readonly TypeScript annotations alone would not enforce that ownership assumption on arbitrary foreign JavaScript.

This argument starts from the checked IR structure layout. Associating the source's ordered retained runtime fields and projection indices with these properties belongs to ER-05/06, including omission of generic type parameters. The current constructor-field admission refuses proof/type fields; this argument does not claim they are silently omitted. The current record expression type alone does not reconstruct the source association.

## 10. EV-09 — one target evaluation and field selection

The projection emitter prints the target once, followed by its admitted property access. G gives a related structure value after evaluating that target with its inherited budget. J-LAYOUT identifies the selected field, and the ordinary generated-object relation supplies a present own data property with a related value. Reading it does not call an accessor, repeat the target computation or mutate the object. The selected value is related at the target's returned residue. [E01, E05–E06]

Expression formation is relevant because no additional parentheses are inserted here. Successful structure-typed target forms emit a valid member-access base: identifiers, prior member access, calls, or already parenthesized conditional/object/delegated-generator expressions. Polymorphic arrayGet/foldl can return a structure and emit IIFE call expressions, also valid member-access bases. Primitive literal or lambda-value forms cannot themselves have this checked structure type. Fixed templates yielding primitive arithmetic expressions are already parenthesized where needed. This uses the admitted type and complete expression/template partition, not a blanket claim that every arbitrary string can precede a dot.

The argument concerns property identity within the IR layout. ER-05 supplies the actual source projection's owner and index association; substituting a same-spelled field of another structure is not justified.

## 11. EV-10 — owner-qualified constructor creation

The constructor emitter looks up the inductive owner's tag map and prints access to that owner's exported constructor property, with the constructor name safely quoted. It then distinguishes a monomorphic nullary value from every generic or field-bearing constructor. Actual layout checking associates the constructor with its owner and supplies the exact checked retained field order. [E01, E03–E05]

For a monomorphic nullary constructor, psTsEmitConstructorValue has already placed an object with that private tag and quoted constructor identity in the exported namespace. The expression is just its property access. It has the corresponding nullary value relation, consumes no logical application and demands no field. Reusing the stored object's identity is unobservable for immutable source data.

Otherwise the namespace property is a factory. The factory's synthetic parameter list has exactly the field count, indexed in increasing order; its parameter types and field-property assignments are paired with equal-length lists, so psListZip does not truncate. The call emitter for this constructor supplies each printed field in the same order. Runtime argument evaluation is once from left to right before parameter binding. The factory body only reads those obtained parameters and builds the tag/field object. It neither reevaluates field expressions nor invokes an authored callback. Its ordinary JavaScript call is administrative constructor construction, not an IR function application charged to the interaction budget.

Generic nullary constructors use a zero-runtime-argument factory because their type parameter list is nonempty. The exact checked type arguments match that declaration arity; type instantiation erases at runtime and the factory still produces the proper tagged nullary value. A field-bearing factory and its return object satisfy the same constructor-value relation by the pointwise field induction. Generic type parameters contribute no runtime fields. ER-05/06 accounts for the source's ordered runtime-field association; the current constructor-field admission refuses proof/type fields, so no proof/type-field omission is claimed here.

Owner namespace lookup precedes runtime field evaluation. Under J-NAMES/J-INIT it is an initialized immutable data-property lookup, so that extra administrative step is silent. A locally captured namespace, accessor-bearing foreign namespace or mutated constructor object is outside the established premise.

## 12. EV-11 — ordinary and empty matches

### 12.1 Nonempty family dispatch

For nonempty alternatives, the emitted generator IIFE first evaluates the printed scrutinee and stores it in a fresh private const. It then switches on that stored value's associated private tag. G yields a related constructor value, J-LAYOUT supplies the matching tag, and complete IR checking establishes the required unique constructor-alternative coverage. Exactly that case is selected. No other branch body is evaluated. [E01, E03–E06]

Each selected match binding reads the specified field from the same temporary and binds its checked local type/name. These ordinary data-property reads are silent and preserve the field-value relation. Extending the branch environment in the specified order gives E at the scrutinee's residue, and G for the selected proper body subterm supplies its related result. The branch returns from the IIFE. Unselected alternatives printed earlier are code only.

J-NAMES supplies freshness of the private match temporary, including after the backend's supported eta rewriting. Its actual target-depth reservation argument belongs to TS-01; a finite search that can fall back to an overflow name must not be called universally fresh without the admitted-depth premise. Constructor/tag ownership and the selected branch's field association remain explicit.

The emitted invalid-constructor-tag throw is unreachable for a related constructed value with the checked complete alternatives. It provides defensive behavior for malformed values, not an extra source result. No fabricated host value is used to justify the typed case.

### 12.2 Empty family: scrutinee demand without a value case

When alternatives are empty, the general expression emitter instead produces a generator with result Computation<never>, evaluates void(printedScrutinee), and then throws its defensive unreachable-empty-match error. It does not read a constructor tag, create a field binding or synthesize a value of the empty family. [E01]

There is no V_F constructor case for an empty inductive F. Therefore a related scrutinee computation cannot return a related F value and then require an ordinary branch. It may reach the next logical application cutoff, or have a permitted non-value behavior considered by C. Up to that point the emitted void operand demands the scrutinee exactly once and preserves its observed demands, abort or divergence under the composed computation/machine relation. The proof never erases that demand merely because F has no values. If a malformed foreign value returns anyway, the defensive throw lies outside the related source-value case.

The never result supports every surrounding checked result type without inventing an inhabitant, including a function result or an empty match used in a typed initializer/callee position. The eraser's result-typed outer let is a typing and motive-association device; applying the let case preserves evaluation of its empty initializer before any result lookup. Its source motive correspondence remains ER-07.

### 12.3 Actual dispatcher coverage

The current declaration dispatcher tries count optimization, then tail optimization, then general emission. The count recognizer requires its two-case pattern, so it does not accept an empty match. Current psTsTailEmitWithFuel explicitly returns none for an empty alternative list; failure propagates through its enclosing recognized branch, selecting general emission. The pure-expression tail classifier also declines embedded match/let/lambda shapes instead of silently accepting their evaluation. Thus the supported empty routes reach the typed general case above. [E03]

That last statement uses the committed Module blob2580754407e70be69cc10101c4ebe03c7304a8f0. Its exact empty-tail correction is separate from the general expression proof. The complete nonempty tail/count success arguments belong to TS-06/07. Existing native fixtures retain their four expected typed empty emissions; those finite assertions are useful regression evidence and are not the general argument in this section.


## 13. Composition with the generated machine

The preceding cases describe general-emitter code executed within a related generator continuation. They do not assume that each JavaScript helper call is an authored call. Let/match IIFEs, constructor factories, wrappers, registry lookup and primitive argument-binding IIFEs are administrative implementations of the corresponding IR construct. An actual .call or prescribed map/fold callback is a logical application and uses the common single charge. [E03, E06]

The required machine relation associates the pending JavaScript generator stack and each saved continuation with its corresponding IR continuation. A yielded request carries already evaluated callee/argument values; a returned child result resumes the immediately pending continuation. Nested runner entry during an intrinsic callback composes with the suspended outer continuation and returns its residual. The TS-04 packet must provide the actual transition and progress derivation for these statements. Merely observing that a generator eventually returns the same test result is insufficient.

This interface permits the structural expression proof and machine proof to be established together by the same decreasing interaction index. The lambda/call cases provide related expression bodies; the runner cases realize their calls/returns. They cannot use the unqualified conclusion “all generated functions are correct” as a premise. Direct optimized callables obtain their body behavior from the separate finite recognizer-success arguments.

All-index adequacy needs an administrative progress argument. For the general expression code, finite syntax bounds non-call expression/statement work between demands. Name/property/symbol reads and object construction are finite under J-HOST. The primitive loops have the finite measures in §4.4; a callback creates a logical application boundary. The remaining generator scheduling and optimized-loop transitions must establish that an infinite implementation path cannot hide forever as silent unmatched administration. This is a specific TS-04–07 interface, not a request for unlimited stress tests.

## 14. Coverage and exact local result

The following table records what the case analysis supplies. “Local case established” always means the quantified statement G under the named interfaces in §1; it does not activate a repository qualification flag.

| Row | Local case established here | Additional actual implementation interface |
| --- | --- | --- |
| EV-01 | All five enabled literal constructors; complete scalar-string escaping and fuel coverage; no operand demand | Trusted decimal/string parser semantics and intended undefined binding |
| EV-02 | Direct nearest-binding lookup without initializer reevaluation | Actual erasure binding association and initialized globals |
| EV-03 | All45 enabled laws composed with child demand rules; residual prefix/range induction for map/foldl | Pinned source primitive/proof-domain identity and generated callback application |
| EV-04 | Lexical closure creation; no body demand; lower-index application argument | Capture/name association, registration and generated callable interface |
| EV-05 | Callee then operands once; exact group; one logical invocation charge | Machine/direct-call behavior and earlier Core-to-IR grouping |
| EV-06 | Parameter-IIFE and lexical-const paths; arbitrary finite let chains | Implicit namespace/helper hygiene from actual producers |
| EV-07 | One Boolean condition and exactly the selected branch | Child induction and ordinary conditional semantics |
| EV-08 | Ordered fields and brand relation; inhabited zero-field record | Actual source/IR structure layout and safe property names |
| EV-09 | One target computation and associated ordinary field lookup | Actual source projection/layout association |
| EV-10 | Owner-qualified nullary value or factory; ordered retained fields | Constructor layout/generic association and initialized namespace |
| EV-11 | One scrutinee, unique selected branch, or demanded empty computation | Actual motive/field association, private-name freshness and dispatcher success/fallback proofs |

These eleven constructors exhaust PsVerifiedIrExpr. A larger input datatype, a parser acceptance test, or a finite fixture count does not add another enabled case. Unsupported operations/types must be refused by the existing strict admissions; this theorem does not redefine them to make translation succeed. [E04–E08]

## 15. What remains to compose and what is already an ordinary premise

There are three distinct levels of remaining work.

First, ordinary semantic proof inputs are already explicit: a supported θ, related E at the inherited index, child induction hypotheses, the finite list/data induction, and the declared standard host/resource assumptions. They are not missing runtime certificates. The exact source case arguments above discharge the general emitter's syntax/demand preservation under those inputs and interfaces; they need not be rerun as a test for each new source program.

Second, the actual backend packet must provide J-NAMES, J-LAYOUT, J-CALL and J-INIT for the current admitted module and every selected optimization route. The producer-sensitive exception in §7.2 must be accounted for, not replaced by a false assertion that every new eta name avoids every global. The empty fallback is already an exact reviewed source change; the all-case proof still imports nonempty optimizers. The complete runner transition/progress and callback reentry arguments are substantive, finite source arguments capable of satisfying this interface. Once reviewed and supplied, they remove those dependencies from EV rather than becoming permanent generic caveats.

Third, lifting the resulting IR/JavaScript statement back to PSC1/Core requires ER/N's actual binder/type/proof/layout and grouping/demand associations. A Core type check does not itself prove which proof arguments may be erased, when a recursor's IH is demanded, or whether result-arrow eta changes an application prefix's demand. Those questions must be resolved with the actual source normalization/erasure paths and the pinned native interpretation. The actual infer/WHNF classification agreement used by erasure must be justified where declarative Core typing alone is insufficient. No expression-level source witness is demanded solely by this document.

The source rule arguments, exact-current native/N1/C1/C2/C3 qualification and provider admission are different evidence components. The cloud result can establish the reproducible compiler checkpoint and finite conformance for its exact inputs. It does not decide the remaining general semantic interfaces by implication. Strict activation requires the combined mandatory ledger disposition, while a formal machine-checked theorem would require its own separate artifact and assumptions.

## 16. Immutable source references

All current-source links below are anchored to commit3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc. Function names in the argument identify the relevant case boundaries; the blobs fix the complete source. Older candidate references are used only for the exact intrinsic-region comparison and retained source-review history.


| Ref | Source | Exact Git blob |
| --- | --- | --- |
| E01 | [psc0/packages/backend-ts/src/Ps/BackendTs/Expr.lean](https://github.com/dwijayuda/pskernel/blob/3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc/psc0/packages/backend-ts/src/Ps/BackendTs/Expr.lean) | a0ab0d6a224bdfd35846990ab6d6e39df422908e |
| E02 | [psc0/packages/backend-ts/src/Ps/BackendTs/Type.lean](https://github.com/dwijayuda/pskernel/blob/3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc/psc0/packages/backend-ts/src/Ps/BackendTs/Type.lean) | 8c9dcf6b0168dcb1edc49d87130fbee09a47cd79 |
| E03 | [psc0/packages/backend-ts/src/Ps/BackendTs/Module.lean](https://github.com/dwijayuda/pskernel/blob/3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc/psc0/packages/backend-ts/src/Ps/BackendTs/Module.lean) | 2580754407e70be69cc10101c4ebe03c7304a8f0 |
| E04 | [psc0/packages/compiler-ir/src/Ps/CompilerIr/Model.lean](https://github.com/dwijayuda/pskernel/blob/3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc/psc0/packages/compiler-ir/src/Ps/CompilerIr/Model.lean) | a58fa183103817b9b65db45cc9e9798e6abcf4d3 |
| E05 | [psc0/packages/backend-ts/src/Ps/BackendTs/Sh1Target.lean](https://github.com/dwijayuda/pskernel/blob/3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc/psc0/packages/backend-ts/src/Ps/BackendTs/Sh1Target.lean) | a0e7031d8a5e969fad44ab82b80aecbcc88f1139 |
| E06 | [psc0/docs/selfhost-language/strict/SEMANTIC_RELATIONS.md](https://github.com/dwijayuda/pskernel/blob/3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc/psc0/docs/selfhost-language/strict/SEMANTIC_RELATIONS.md) | 40e540b325186ee514ff3af9e39a22126d29a167 |
| E07 | [psc0/docs/selfhost-language/SPEC.md](https://github.com/dwijayuda/pskernel/blob/3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc/psc0/docs/selfhost-language/SPEC.md) | 61f0f36ffe7880144f60845084e8be6a61b91eed |
| E08 | [psc0/docs/selfhost-language/strict/enabled-runtime-contract.json](https://github.com/dwijayuda/pskernel/blob/3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc/psc0/docs/selfhost-language/strict/enabled-runtime-contract.json) | 8c893f0ecbc37855d02a006bb2774de4b0ebde2b |
| E09 | [psc0/packages/foundation/src/Ps/Foundation/List.lean](https://github.com/dwijayuda/pskernel/blob/3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc/psc0/packages/foundation/src/Ps/Foundation/List.lean) | 29e4e59c271c1a26604cc738a8794f9bb70a2e83 |
| E10 | [psc0/packages/foundation/src/Ps/Foundation/Name.lean](https://github.com/dwijayuda/pskernel/blob/3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc/psc0/packages/foundation/src/Ps/Foundation/Name.lean) | 9c896076032762543b57d88c0010f90ad0a066d5 |
| E11 | [psc0/packages/bridge/src/Ps/Bridge/Json.lean](https://github.com/dwijayuda/pskernel/blob/3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc/psc0/packages/bridge/src/Ps/Bridge/Json.lean) | 4ddfec62f2edd54be87091812dcb6add6304e3ed |
| E12 | [psc0/docs/selfhost-language/strict/RUNTIME_LAW_REVIEW.md](https://github.com/dwijayuda/pskernel/blob/3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc/psc0/docs/selfhost-language/strict/RUNTIME_LAW_REVIEW.md) | 682250126807cf520fb4c354ad0b52577a04d8b0 |
| E13 | [psc0/packages/compiler-ir/src/Ps/CompilerIr/Check.lean](https://github.com/dwijayuda/pskernel/blob/3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc/psc0/packages/compiler-ir/src/Ps/CompilerIr/Check.lean) | 178ecf89498be6502be5f747f0c0d62eb1133420 |
| E14 | [psc0/docs/selfhost-language/strict/correspondence-obligations.json](https://github.com/dwijayuda/pskernel/blob/3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc/psc0/docs/selfhost-language/strict/correspondence-obligations.json) | 9ae363efcb6faab4ffd6c10af0e498ece6004649 |
| E15 | [psc0/docs/selfhost-language/strict/post-review-source-completion.json](https://github.com/dwijayuda/pskernel/blob/3c0c07f2b6dd9e28d4ee2cfc4e02a0a63503a9cc/psc0/docs/selfhost-language/strict/post-review-source-completion.json) | 639e78ffeba7d64f29ef02eadff9b37951073832 |

The full current checker source is E13; E14 preserves the active ledger and E15 the exact three-file source completion. This packet changes no flag in either. The first-order source meanings and native-source pins cited by E12 remain its explicit trusted/review boundary; they are not replaced by foreign diagnostic callbacks.
