<a id="instance-synth"></a>

# ProofScript — 10.3. Instance Synthesis

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Classes are native type-directed interfaces, not JavaScript classes. Instances provide dictionaries and associated evidence. Inference uses the pinned priority and search behavior, so importing an instance can affect elaboration. Derived instances are generated declarations that must be checked. Boolean equality and hashing require laws when used for logical claims.

**Compiler and coverage boundary.** Braced class fields use native field-declaration layout. Instance initializers use their own native sequence grammar, including semicolons only where that grammar permits them.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Type-Classes/Instance-Synthesis/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Type-Classes/Instance-Synthesis/index.html). Source Git blob: `f861d8057ea66f6cd414a0ca73d98aabff5fb077`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 10.3. Instance Synthesis

Instance synthesis is a recursive search procedure that either finds an instance for a given type class or fails. In other words, given a type that is registered as a type class, instance synthesis attempts to construct a term with said type. It respects [reducibility](../../Definitions/Recursive-Definitions/index.md#--tech-term-reducibility): [semireducible](../../Definitions/Recursive-Definitions/index.md#--tech-term-Semireducible) or [irreducible](../../Definitions/Recursive-Definitions/index.md#--tech-term-Irreducible) definitions are not unfolded, so instances for a definition are not automatically treated as instances for its unfolding unless it is [reducible](../../Definitions/Recursive-Definitions/index.md#--tech-term-Reducible). There may be multiple possible instances for a given class; in this case, declared priorities and order of declaration are used as tiebreakers, in that order, with more recent instances taking precedence over earlier ones with the same priority.

This search procedure is efficient in the presence of diamonds and does not loop indefinitely when there are cycles. 
<a id="--tech-term-Diamonds"></a>
*Diamonds* occur when there is more than one route to a given goal, and 
<a id="--tech-term-cycles"></a>
*cycles* are situations when two instances each could be solved if the other were solved. Diamonds occur regularly in practice when encoding mathematical concepts using type classes, and Lean's coercion feature naturally leads to cycles, e.g. between finite sets and finite multisets.

Instance synthesis can be tested using the [`#synth`](../../Interacting-with-Lean/index.md#Lean___Parser___Command___synth) command. Additionally, `inferInstance` and `inferInstanceAs` can be used to synthesize an instance in a position where the instance itself is needed. `inferInstance` with a type annotation and `inferInstanceAs` are not equivalent; `inferInstanceAs` [preprocesses the synthesized instance](index.md#instance-wrapping) to prevent unintentional leakage of implementation details into interfaces.

<a id="inferInstance"></a>

**def**

```text
inferInstance.{u} {α : Sort u} [i : α] : α
```

`inferInstance` synthesizes a value of any target type by typeclass inference. This function has the same type signature as the identity function, but the square brackets on the `[i : α]` argument means that it will attempt to construct this argument by typeclass inference. (This will fail if `α` is not a `class`.) Example:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
#check (inferInstance : Inhabited Nat) -- Inhabited Nat

const foo : Inhabited (Nat × Nat) :=
  inferInstance

example : foo.default = (default, default) :=
  rfl
```

<a id="inferInstanceAs"></a>

**def**

```text
«inferInstanceAs».{u} (α : Sort u) [i : α] : α
```

`inferInstanceAs α` synthesizes an instance of type `α` and then adjusts it to conform to the expected type `β`, which must be inferable from context.

Example:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
const D := Nat
instance : Inhabited D := inferInstanceAs (Inhabited Nat)
```

The adjustment will make sure that when the resulting instance will not "leak" the RHS `Nat` when reduced at transparency levels below `semireducible`, i.e. where `D` would not be unfolded either, preventing "defeq abuse".

More specifically, given the "source type" (the argument) and "target type" (the expected type), `inferInstanceAs` synthesizes an instance for the source type and then unfolds and rewraps its components (fields, nested instances) as necessary to make them compatible with the target type. The individual steps are represented by the following options, which all default to enabled and can be disabled to help with porting:

- `backward.inferInstanceAs.wrap`: master switch for instance adjustment in both `inferInstanceAs` and the default deriving handler
- `backward.inferInstanceAs.wrap.reuseSubInstances`: reuse existing instances for the target type for sub-instance fields to avoid non-defeq instance diamonds
- `backward.inferInstanceAs.wrap.instances`: wrap non-reducible instances in auxiliary definitions
- `backward.inferInstanceAs.wrap.data`: wrap data fields in auxiliary definitions (proof fields are always wrapped)

If you just need to synthesize an instance without transporting between types, use `inferInstance` instead, potentially with a type annotation for the expected type.

<a id="The-Lean-Language-Reference--Type-Classes--Instance-Synthesis--Instance-Search-Summary"></a>
### 10.3.1. Instance Search Summary

Generally speaking, instance synthesis is a recursive search procedure that may, in general, backtrack arbitrarily. Synthesis may *succeed* with an instance term, *fail* if no such term can be found, or get *stuck* if there is insufficient information. A detailed description of the instance synthesis algorithm is available in Selsam, Ullrich, and de Moura (2020)Daniel Selsam, Sebastian Ullrich, and Leonardo de Moura, 2020. [“Tabled typeclass resolution”](https://arxiv.org/abs/2001.04301). arXiv:2001.04301. An instance search problem is given by a type class applied to concrete arguments; these argument values may or may not be known. Instance search attempts every locally-bound variable whose type is a class, as well as each registered instance, in order of priority and definition. When candidate instances themselves have instance-implicit parameters, they impose further synthesis tasks.

A problem is only attempted when all of the input parameters to the type class are known. When a problem cannot yet be attempted, then that branch is stuck; progress in other subproblems may result in the problem becoming solvable. Output or semi-output parameters may be either known or unknown at the start of instance search. Output parameters are ignored when checking whether an instance matches the problem, while semi-output parameters are considered.

Every candidate solution for a given problem is saved in a table; this prevents infinite regress in case of cycles as well as exponential search overheads in the presence of diamonds (that is, multiple paths by which the same goal can be achieved). A branch of the search fails when any of the following occur:

- All potential instances have been attempted, and the search space is exhausted.
- The instance size limit specified by the option `synthInstance.maxSize` is reached.
- The synthesized value of an output parameter does not match the specified value in the search problem. Failed branches are not retried.

If search would otherwise fail or get stuck, the search process attempts to use matching [default instances](index.md#--tech-term-default-instances) in order of priority. For default instances, the input parameters do not need to be fully known, and may be instantiated by the instances parameter values. Default instances may take instance-implicit parameters, which induce further recursive search.

Successful branches in which the problem is fully known (that is, in which there are no unsolved metavariables) are pruned, and further potentially-successful instances are not attempted, because no later instance could cause the previously-succeeding branch to fail.

<a id="instance-search"></a>
### 10.3.2. Instance Search Problems

Instance search occurs during the elaboration of (potentially nullary) function applications. Some of the implicit parameters' values are forced by others; for instance, an implicit type parameter may be solved using the type of a later value argument that is explicitly provided. Implicit parameters may also be solved using information from the expected type at that point in the program. The search for instance implicit arguments may make use of the implicit argument values that have been found, and may additionally solve others.

Instance synthesis begins with the type of the instance-implicit parameter. This type must be the application of a type class to zero or more arguments; these argument values may be known or unknown when search begins. If an argument to a class is unknown, the search process will not instantiate it unless the corresponding parameter is [marked as an output parameter](index.md#class-output-parameters), explicitly making it an output of the instance synthesis routine.

Search may succeed, fail, or get stuck; a stuck search may occur when an unknown argument value becoming known might enable progress to be made. Stuck searches may be re-invoked when the elaborator has discovered one of the previously-unknown implicit arguments. If this does not occur, stuck searches become failures.

<a id="Tracing-Instance-Search"></a>
Tracing Instance Search 

Setting the `trace.Meta.synthInstance` option to `true` causes Lean to emit a trace of the process for synthesizing an instance of a type class. This trace can be used to understand how instance synthesis succeeds and why it fails.

Here, we can see the steps Lean takes to conclude that there exists an element of the type `(Nat ⊕ Empty)` (specifically the element `Sum.inl 0`): Clicking a `▶` symbol expands that branch of the trace, and clicking the `▼` collapses an expanded branch.

```proofscript
set_option pp.explicit true in
set_option trace.Meta.synthInstance true in
#synth Nonempty (Nat ⊕ Empty)
```

```lean
[Meta.synthInstance] ✅️ Nonempty (Sum Nat Empty)[Meta.synthInstance] ✅️ new goal Nonempty (Sum Nat Empty)[Meta.synthInstance.instances] #[@instNonemptyOfInhabited, @instNonemptyOfMonad, @Sum.nonemptyLeft, @Sum.nonemptyRight][Meta.synthInstance.apply] ✅️ apply @Sum.nonemptyRight to Nonempty (Sum Nat Empty)[Meta.synthInstance.tryResolve] ✅️ Nonempty (Sum Nat Empty) ≟ Nonempty (Sum Nat Empty)[Meta.synthInstance] ✅️ new goal Nonempty Empty[Meta.synthInstance.instances] #[@instNonemptyOfInhabited, @instNonemptyOfMonad][Meta.synthInstance.apply] ❌️ apply @instNonemptyOfMonad to Nonempty Empty[Meta.synthInstance.tryResolve] ❌️ Nonempty Empty ≟ Nonempty (?m.5 ?m.6)[Meta.synthInstance.apply] ✅️ apply @instNonemptyOfInhabited to Nonempty Empty[Meta.synthInstance.tryResolve] ✅️ Nonempty Empty ≟ Nonempty Empty[Meta.synthInstance] ✅️ new goal Inhabited Empty[Meta.synthInstance.instances] #[@instInhabitedOfMonad][Meta.synthInstance.apply] ❌️ apply @instInhabitedOfMonad to Inhabited Empty[Meta.synthInstance.tryResolve] ❌️ Inhabited Empty ≟ Inhabited (?m.8 ?m.7)[Meta.synthInstance.apply] ✅️ apply @Sum.nonemptyLeft to Nonempty (Sum Nat Empty)[Meta.synthInstance.tryResolve] ✅️ Nonempty (Sum Nat Empty) ≟ Nonempty (Sum Nat Empty)[Meta.synthInstance] ✅️ new goal Nonempty Nat[Meta.synthInstance.instances] #[@instNonemptyOfInhabited, @instNonemptyOfMonad][Meta.synthInstance.apply] ❌️ apply @instNonemptyOfMonad to Nonempty Nat[Meta.synthInstance.tryResolve] ❌️ Nonempty Nat ≟ Nonempty (?m.5 ?m.6)[Meta.synthInstance.apply] ✅️ apply @instNonemptyOfInhabited to Nonempty Nat[Meta.synthInstance.tryResolve] ✅️ Nonempty Nat ≟ Nonempty Nat[Meta.synthInstance] ✅️ new goal Inhabited Nat[Meta.synthInstance.instances] #[@instInhabitedOfMonad, instInhabitedNat][Meta.synthInstance.apply] ✅️ apply instInhabitedNat to Inhabited Nat[Meta.synthInstance.tryResolve] ✅️ Inhabited Nat ≟ Inhabited Nat[Meta.synthInstance.answer] ✅️ Inhabited Nat[Meta.synthInstance.resume] ✅️ propagating Inhabited Nat to subgoal Inhabited Nat of Nonempty Nat[Meta.synthInstance.resume] size: 1[Meta.synthInstance.answer] ✅️ Nonempty Nat[Meta.synthInstance.resume] ✅️ propagating Nonempty Nat to subgoal Nonempty Nat of Nonempty (Sum Nat Empty)[Meta.synthInstance.resume] size: 2[Meta.synthInstance.answer] ✅️ Nonempty (Sum Nat Empty)[Meta.synthInstance] result @Sum.nonemptyLeft Nat Empty (@instNonemptyOfInhabited Nat instInhabitedNat)
```

By exploring the trace, it is possible to follow the depth-first, backtracking search that Lean uses for type class instance search. This can take a little practice to get used to! In the example above, Lean follows these steps:

- Lean considers the first goal, `Nonempty (Sum Nat Empty)`. Lean sees four ways of possibly satisfying this goal:

   

  - The `Sum.nonemptyRight` instance, which would create a sub-goal `Nonempty Empty`.
  - The `Sum.nonemptyLeft` instance, which would create a sub-goal `Nonempty Nat`.
  - The `instNonemptyOfMonad` instance, which would create two sub-goals `Monad (Sum Nat)` and `Nonempty Nat`.
  - The `instNonemptyOfInhabited` instance, which would create a sub-goal `Inhabited (Sum Nat Empty)`.
- It applies `Sum.nonemptyRight`, which succeeds, leaving a new goal: `Nonempty Empty`.
- The first sub-goal, `Nonempty Empty`, is considered. Lean sees two ways of possibly satisfying this goal:

   

  - The `instNonemptyOfMonad` instance, which is rejected. It can't be used because the type `Empty` is not the application of a monad to a type.
  - The `instNonemptyOfInhabited` instance, which would create a sub-goal `Inhabited Empty`.
- The newly-generated sub-goal, `Inhabited Empty`, is considered. Lean only sees one way of possibly satisfying this goal, `instInhabitedOfMonad`, which is rejected. As before, this is because the type `Empty` is not the application of a monad to a type.
- At this point, there are no remaining options for achieving the original first sub-goal. The search backtracks, using the instance `Sum.nonemptyLeft`, which requires an instance of `Nonempty Nat`. This search eventually succeeds, via the `Inhabited Nat` instance.

The third and fourth original candidates are never considered. Once the search for `Nonempty Nat` succeeds, the [`#synth`](../../Interacting-with-Lean/index.md#Lean___Parser___Command___synth) command finishes and outputs the solution:

```lean
@Sum.nonemptyLeft Nat Empty (@instNonemptyOfInhabited Nat instInhabitedNat)
```

<a id="The-Lean-Language-Reference--Type-Classes--Instance-Synthesis--Candidate-Instances"></a>
### 10.3.3. Candidate Instances

Instance synthesis uses both local and global instances in its search. 
<a id="--tech-term-Local-instances"></a>
*Local instances* are those available in the local context; they may be either parameters to a function or locally defined with `let`. Local instances do not need to be indicated specially; any local variable whose type is a type class is a candidate for instance synthesis. 
<a id="--tech-term-Global-instances"></a>
*Global instances* are those available in the global environment; every global instance is a defined name with the `instance` attribute applied.`instance` declarations automatically apply the `instance` attribute.

<a id="Local-Instances"></a>
Local Instances 

In this example, `addPairs` contains a locally-defined instance of `Add NatPair`:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="NatPair-_LPAR_in-Local-Instances_RPAR_"></a>
<a id="NatPair___x-_LPAR_in-Local-Instances_RPAR_"></a>
<a id="NatPair___y-_LPAR_in-Local-Instances_RPAR_"></a>
<a id="addPairs-_LPAR_in-Local-Instances_RPAR_"></a>


```proofscript
structure NatPair where
  x : Nat
  y : Nat

function addPairs (p1 p2 : NatPair) : NatPair :=
  let _ : Add NatPair :=
    ⟨fun ⟨x1, y1⟩ ⟨x2, y2⟩ => ⟨x1 + x2, y1 + y2⟩⟩
  p1 + p2
```

The local instance is used for the addition, having been found by instance synthesis.

<a id="Local-Instances-Have-Priority"></a>
Local Instances Have Priority 

Here, `addPairs` contains a locally-defined instance of `Add NatPair`, even though there is a global instance:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="NatPair-_LPAR_in-Local-Instances-Have-Priority_RPAR_"></a>
<a id="NatPair___x-_LPAR_in-Local-Instances-Have-Priority_RPAR_"></a>
<a id="NatPair___y-_LPAR_in-Local-Instances-Have-Priority_RPAR_"></a>
<a id="addPairs-_LPAR_in-Local-Instances-Have-Priority_RPAR_"></a>


```proofscript
structure NatPair where
  x : Nat
  y : Nat

instance : Add NatPair where
  add
    | ⟨x1, y1⟩, ⟨x2, y2⟩ => ⟨x1 + x2, y1 + y2⟩

function addPairs (p1 p2 : NatPair) : NatPair :=
  let _ : Add NatPair :=
    ⟨fun _ _ => ⟨0, 0⟩⟩
  p1 + p2
```

The local instance is selected instead of the global one:

```proofscript
#eval addPairs ⟨1, 2⟩ ⟨5, 2⟩
```

```lean
{ x := 0, y := 0 }
```

<a id="instance-synth-parameters"></a>
### 10.3.4. Instance Parameters and Synthesis

The search process for instances is largely governed by class parameters. Type classes take a certain number of parameters, and instances are tried during the search when their choice of parameters is *compatible* with those in the class type for which the instance is being synthesized.

Instances themselves may also take parameters, but the role of instances' parameters in instance synthesis is very different. Instances' parameters represent either variables that may be instantiated by instance synthesis or further synthesis work to be done before the instance can be used. In particular, parameters to instances may be explicit, implicit, or instance-implicit. If they are instance implicit, then they induce further recursive instance searching, while explicit or implicit parameters must be solved by unification.

<a id="Implicit-and-Explicit-Parameters-to-Instances"></a>
Implicit and Explicit Parameters to Instances 

While instances typically take parameters either implicitly or instance-implicitly, explicit parameters may be filled out as if they were implicit during instance synthesis. In this example, `aNonemptySumInstance` is found by synthesis, applied explicitly to `Nat`, which is needed to make it type-correct.
<a id="aNonemptySumInstance-_LPAR_in-Implicit-and-Explicit-Parameters-to-Instances_RPAR_"></a>


```proofscript
instance aNonemptySumInstance
    (α : Type) {β : Type} [inst : Nonempty α] :
    Nonempty (α ⊕ β) :=
  let ⟨x⟩ := inst
  ⟨.inl x⟩
```

```proofscript
set_option pp.explicit true in
#synth Nonempty (Nat ⊕ Empty)
```

In the output, both the explicit argument `Nat` and the implicit argument `Empty` were found by unification with the search goal, while the `Nonempty Nat` instance was found via recursive instance synthesis.

```lean
@aNonemptySumInstance Nat Empty (@instNonemptyOfInhabited Nat instInhabitedNat)
```

<a id="class-output-parameters"></a>
### 10.3.5. Output Parameters

By default, the parameters of a type class are considered to be *inputs* to the search process. If the parameters are not known, then the search process gets stuck, because choosing an instance would require the parameters to have values that match those in the instance, which cannot be determined on the basis of incomplete information. In most cases, guessing instances would make instance synthesis unpredictable.

In some cases, however, the choice of one parameter should cause an automatic choice of another. For example, the overloaded membership predicate type class `Membership` treats the type of elements of a data structure as an output, so that the type of element can be determined by the type of data structure at a use site, instead of requiring that there be sufficient type annotations to determine *both* types prior to starting instance synthesis. An element of a `List Nat` can be concluded to be a `Nat` simply on the basis of its membership in the list.

Type class parameters can be declared as outputs by wrapping their types in the `outParam` [gadget](../Class-Declarations/index.md#--tech-term-gadgets). When a class parameter is an 
<a id="--tech-term-output-parameter"></a>
*output parameter*, instance synthesis will not require that it be known; in fact, any existing value is ignored completely. The first instance that matches the input parameters is selected, and that instance's assignment of the output parameter becomes its value. If there was a pre-existing value, then it is compared with the assignment after synthesis is complete, and it is an error if they do not match.

<a id="outParam"></a>

**def**

```text
outParam.{u} (α : Sort u) : Sort u
```

Gadget for marking output parameters in type classes.

For example, the `Membership` class is defined as:

```text
class Membership (α : outParam (Type u)) (γ : Type v)
```

This means that whenever a typeclass goal of the form `Membership ?α ?γ` comes up, Lean will wait to solve it until `?γ` is known, but then it will run typeclass inference, and take the first solution it finds, for any value of `?α`, which thereby determines what `?α` should be.

This expresses that in a term like `a ∈ s`, `s` might be a `Set α` or `List α` or some other type with a membership operation, and in each case the "member" type `α` is determined by looking at the container type.

<a id="Output-Parameters-and-Stuck-Search"></a>
Output Parameters and Stuck Search 

This serialization framework provides a way to convert values to some underlying storage type:

```proofscript
class Serialize (input output : Type) where
  ser : input → output
export Serialize (ser)

instance : Serialize Nat String where
  ser n := toString n

instance [Serialize α γ] [Serialize β γ] [Append γ] :
    Serialize (α × β) γ where
  ser
    | (x, y) => ser x ++ ser y
```

In this example, the output type is unknown.

```proofscript
example := ser (2, 3)
```

Instance synthesis can't select the `Serialize Nat String` instance, and thus the `Append String` instance, because that would require instantiating the output type as `String`, so the search gets stuck:

```lean
typeclass instance problem is stuck
  Serialize (Nat × Nat) ?m.5

Note: Lean will not try to resolve this typeclass instance problem because the second type argument to `Serialize` is a metavariable. This argument must be fully determined before Lean will try to resolve the typeclass.

Hint: Adding type annotations and supplying implicit arguments to functions can give Lean more information for typeclass resolution. For example, if you have a variable `x` that you intend to be a `Nat`, but Lean reports it as having an unresolved type like `?m`, replacing `x` with `(x : Nat)` can get typeclass resolution un-stuck.
```

As the message indicates, one way to fix the problem is to supply an expected type:

```proofscript
example : String := ser (2, 3)
```

The other is to make the output type into an output parameter:

```proofscript
class Serialize (input : Type) (output : outParam Type) where
  ser : input → output
export Serialize (ser)

instance : Serialize Nat String where
  ser n := toString n

instance [Serialize α γ] [Serialize β γ] [Append γ] :
    Serialize (α × β) γ where
  ser
    | (x, y) => ser x ++ ser y
```

Now, instance synthesis is free to select the `Serialize Nat String` instance, which solves the unknown implicit `output` parameter of `ser`:

```proofscript
example := ser (2, 3)
```

<a id="Output-Parameters-with-Pre-Existing-Values"></a>
Output Parameters with Pre-Existing Values 

The class `OneSmaller` represents a way to transform non-maximal elements of a type into elements of a type that has one fewer elements. There are two separate instances that can match an input type `Option Bool`, with different outputs:
<a id="OneSmaller-_LPAR_in-Output-Parameters-with-Pre-Existing-Values_RPAR_"></a>
<a id="OneSmaller___biggest-_LPAR_in-Output-Parameters-with-Pre-Existing-Values_RPAR_"></a>
<a id="OneSmaller___shrink-_LPAR_in-Output-Parameters-with-Pre-Existing-Values_RPAR_"></a>


```proofscript
class OneSmaller (α : Type) (β : outParam Type) where
  biggest : α
  shrink : (x : α) → x ≠ biggest → β

instance : OneSmaller (Option α) α where
  biggest := none
  shrink
    | some x, _ => x

instance : OneSmaller (Option Bool) (Option Unit) where
  biggest := some true
  shrink
    | none, _ => none
    | some false, _ => some ()

instance : OneSmaller Bool Unit where
  biggest := true
  shrink
    | false, _ => ()
```

Because instance synthesis selects the most recently defined instance, the following code is an error:

```proofscript
#check OneSmaller.shrink (β := Bool) (some false) sorry
```

```lean
failed to synthesize instance of type class
  OneSmaller (Option Bool) Bool

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

The `OneSmaller (Option Bool) (Option Unit)` instance was selected during instance synthesis, without regard to the supplied value of `β`.

<a id="--tech-term-Semi-output-parameters"></a>
*Semi-output parameters* are like output parameters in that they are not required to be known prior to synthesis commencing; unlike output parameters, their values are taken into account when selecting instances.

<a id="semiOutParam"></a>

**def**

```text
semiOutParam.{u} (α : Sort u) : Sort u
```

Gadget for marking semi output parameters in type classes.

Semi-output parameters influence the order in which arguments to type class instances are processed. Lean determines an order where all non-(semi-)output parameters to the instance argument have to be figured out before attempting to synthesize an argument (that is, they do not contain assignable metavariables created during TC synthesis). This rules out instances such as `[Mul β] : Add α` (because `β` could be anything). Marking a parameter as semi-output is a promise that instances of the type class will always fill in a value for that parameter.

For example, the `Coe` class is defined as:

```text
class Coe (α : semiOutParam (Sort u)) (β : Sort v)
```

This means that all `Coe` instances should provide a concrete value for `α` (i.e., not an assignable metavariable). An instance like `Coe Nat Int` or `Coe α (Option α)` is fine, but `Coe α Nat` is not since it does not provide a value for `α`.

Semi-output parameters impose a requirement on instances: each instance of a class with semi-output parameters should determine the values of its semi-output parameters.

<a id="Semi-Output-Parameters-with-Pre-Existing-Values"></a>
Semi-Output Parameters with Pre-Existing Values 

The class `OneSmaller` represents a way to transform non-maximal elements of a type into elements of a type that one fewer elements. It has two separate instances that can match an input type `Option Bool`, with different outputs:
<a id="OneSmaller-_LPAR_in-Semi-Output-Parameters-with-Pre-Existing-Values_RPAR_"></a>
<a id="OneSmaller___biggest-_LPAR_in-Semi-Output-Parameters-with-Pre-Existing-Values_RPAR_"></a>
<a id="OneSmaller___shrink-_LPAR_in-Semi-Output-Parameters-with-Pre-Existing-Values_RPAR_"></a>


```proofscript
class OneSmaller (α : Type) (β : semiOutParam Type) where
  biggest : α
  shrink : (x : α) → x ≠ biggest → β

instance : OneSmaller (Option α) α where
  biggest := none
  shrink
    | some x, _ => x

instance : OneSmaller (Option Bool) (Option Unit) where
  biggest := some true
  shrink
    | none, _ => none
    | some false, _ => some ()

instance : OneSmaller Bool Unit where
  biggest := true
  shrink
    | false, _ => ()
```

Because instance synthesis takes semi-output parameters into account when selecting instances, the `OneSmaller (Option Bool) (Option Unit)` instance is passed over due to the supplied value for `β`:

```proofscript
#check OneSmaller.shrink (β := Bool) (some false) sorry
```

```lean
OneSmaller.shrink (some false) ⋯ : Bool
```

<a id="default-instance-synth"></a>
### 10.3.6. Default Instances

When instance synthesis would otherwise fail, having not selected an instance, the 
<a id="--tech-term-default-instances"></a>
*default instances* specified using the `default_instance` attribute are attempted in order of priority. When priorities are equal, more recently-defined default instances are chosen before earlier ones. The first default instance that causes the search to succeed is chosen.

Default instances may induce further recursive instance search if the default instances themselves have instance-implicit parameters. If the recursive search fails, the search process backtracks and the next default instance is tried.

<a id="The-Lean-Language-Reference--Type-Classes--Instance-Synthesis--___Morally-Canonical___-Instances"></a>
### 10.3.7. “Morally Canonical” Instances

During instance synthesis, if a goal is fully known (that is, contains no metavariables) and search succeeds, no further instances will be attempted for that same goal. In other words, when search succeeds for a goal in a way that can't be refuted by a subsequent increase in information, the goal will not be attempted again, even if there are other instances that could potentially have been used. This optimization can prevent a failure in a later branch of an instance synthesis search from causing spurious backtracking that replaces a fast solution from an earlier branch with a slow exploration of a large state space.

The optimization relies on the assumption that instances are 
<a id="--tech-term-morally-canonical"></a>
*morally canonical*. Even if there is more than one potential implementation of a given type class's overloaded operations, or more than one way to synthesize an instance due to diamonds, *any discovered instance should be considered as good as any other*. In other words, there's no need to consider *all* potential instances so long as one of them has been guaranteed to work. The optimization may be disabled with the backwards-compatibility option `backward.synthInstance.canonInstances`, which may be removed in a future version of Lean.

Code that uses instance-implicit parameters should be prepared to consider all instances as equivalent. In other words, it should be robust in the face of differences in synthesized instances. When the code relies on instances *in fact* being equivalent, it should either explicitly manipulate instances (e.g. via local definitions, by saving them in structure fields, or having a structure inherit from the appropriate class) or it should make this dependency explicit in the type, so that different choices of instance lead to incompatible types.

<a id="instance-wrapping"></a>
### 10.3.8. Wrapping Synthesized Instances

After `inferInstanceAs` or the default `deriving` handler synthesize an instance, the instance body is processed to ensure that its type and the types of its fields match the expected types at `instances` transparency, which unfolds only [reducible](../../Definitions/Recursive-Definitions/index.md#--tech-term-Reducible) and [implicit reducible](../../Definitions/Recursive-Definitions/index.md#--tech-term-Implicit-reducible) definitions. This processing prevents the internals of the instance's definition from being leaked when the instance is reduced at lower than [semireducible](../../Definitions/Recursive-Definitions/index.md#--tech-term-Semireducible) transparency, which could induce unintended dependencies between different parts of a code base.

If the expected type is a proposition, the instance is wrapped in an auxiliary theorem. Otherwise, the synthesized instance is reduced to weak head normal form at `instances` transparency. If the result is a constructor application, each field is processed:

- Sub-instance fields are replaced by a freshly synthesized instance for their type when one can be found. This ensures that the instance is the same as that which would be found by client code that synthesized the instance, avoiding a situation in which multiple paths to an instance (called *diamonds*) yield instances that are not [definitionally equal](../../The-Type-System/index.md#--tech-term-definitional-equality) to one another other. When synthesis does not find an instance, the field is recursively wrapped using this procedure.
- Proof fields whose types are not definitionally equal to the expected type are wrapped in auxiliary theorems that hide the difference in types.
- Data fields whose types do not match the expected type are wrapped in auxiliary definitions with the appropriate reducibility.

If the instance does not reduce to a constructor application and its type does not match the expected type, then it is wrapped in an auxiliary definition with the appropriate reducibility.

<a id="The-Lean-Language-Reference--Type-Classes--Instance-Synthesis--Options"></a>
### 10.3.9. Options

<a id="backward___synthInstance___canonInstances"></a>

**option**

```text
backward.synthInstance.canonInstances
```

Default value: `true`

use optimization that relies on 'morally canonical' instances during type class resolution

<a id="synthInstance___maxHeartbeats"></a>

**option**

```text
synthInstance.maxHeartbeats
```

Default value: `20000`

maximum amount of heartbeats per typeclass resolution problem. A heartbeat is number of (small) memory allocations (in thousands), 0 means no limit

<a id="synthInstance___maxSize"></a>

**option**

```text
synthInstance.maxSize
```

Default value: `128`

maximum number of instances used to construct a solution in the type class instance synthesis procedure

<a id="backward___inferInstanceAs___wrap"></a>

**option**

```text
backward.inferInstanceAs.wrap
```

Default value: `true`

wrap instance bodies in `inferInstanceAs` and the default `deriving` handler

<a id="backward___inferInstanceAs___wrap___reuseSubInstances"></a>

**option**

```text
backward.inferInstanceAs.wrap.reuseSubInstances
```

Default value: `true`

when recursing into sub-instances, reuse existing instances for the target type instead of re-wrapping them, which can be important to avoid non-defeq instance diamonds

<a id="backward___inferInstanceAs___wrap___instances"></a>

**option**

```text
backward.inferInstanceAs.wrap.instances
```

Default value: `true`

wrap non-reducible instances in auxiliary definitions to fix their types

<a id="backward___inferInstanceAs___wrap___data"></a>

**option**

```text
backward.inferInstanceAs.wrap.data
```

Default value: `true`

wrap data fields in auxiliary definitions to fix their types

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
inferInstance : Inhabited Nat
```


### Display 2


```text
Definition `foo` of class type is semireducible. Most type class instances should be instance-reducible, so consider marking this
definition with `@[instance_reducible]`. If it is intentionally semireducible, this warning can be disabled with `set_option warn.classDefReducibility false`.
```


### Display 3


```text
[Meta.synthInstance] ✅️ Nonempty (Sum Nat Empty)[Meta.synthInstance] ✅️ new goal Nonempty (Sum Nat Empty)[Meta.synthInstance.instances] #[@instNonemptyOfInhabited, @instNonemptyOfMonad, @Sum.nonemptyLeft, @Sum.nonemptyRight][Meta.synthInstance.apply] ✅️ apply @Sum.nonemptyRight to Nonempty (Sum Nat Empty)[Meta.synthInstance.tryResolve] ✅️ Nonempty (Sum Nat Empty) ≟ Nonempty (Sum Nat Empty)[Meta.synthInstance] ✅️ new goal Nonempty Empty[Meta.synthInstance.instances] #[@instNonemptyOfInhabited, @instNonemptyOfMonad][Meta.synthInstance.apply] ❌️ apply @instNonemptyOfMonad to Nonempty Empty[Meta.synthInstance.tryResolve] ❌️ Nonempty Empty ≟ Nonempty (?m.5 ?m.6)[Meta.synthInstance.apply] ✅️ apply @instNonemptyOfInhabited to Nonempty Empty[Meta.synthInstance.tryResolve] ✅️ Nonempty Empty ≟ Nonempty Empty[Meta.synthInstance] ✅️ new goal Inhabited Empty[Meta.synthInstance.instances] #[@instInhabitedOfMonad][Meta.synthInstance.apply] ❌️ apply @instInhabitedOfMonad to Inhabited Empty[Meta.synthInstance.tryResolve] ❌️ Inhabited Empty ≟ Inhabited (?m.8 ?m.7)[Meta.synthInstance.apply] ✅️ apply @Sum.nonemptyLeft to Nonempty (Sum Nat Empty)[Meta.synthInstance.tryResolve] ✅️ Nonempty (Sum Nat Empty) ≟ Nonempty (Sum Nat Empty)[Meta.synthInstance] ✅️ new goal Nonempty Nat[Meta.synthInstance.instances] #[@instNonemptyOfInhabited, @instNonemptyOfMonad][Meta.synthInstance.apply] ❌️ apply @instNonemptyOfMonad to Nonempty Nat[Meta.synthInstance.tryResolve] ❌️ Nonempty Nat ≟ Nonempty (?m.5 ?m.6)[Meta.synthInstance.apply] ✅️ apply @instNonemptyOfInhabited to Nonempty Nat[Meta.synthInstance.tryResolve] ✅️ Nonempty Nat ≟ Nonempty Nat[Meta.synthInstance] ✅️ new goal Inhabited Nat[Meta.synthInstance.instances] #[@instInhabitedOfMonad, instInhabitedNat][Meta.synthInstance.apply] ✅️ apply instInhabitedNat to Inhabited Nat[Meta.synthInstance.tryResolve] ✅️ Inhabited Nat ≟ Inhabited Nat[Meta.synthInstance.answer] ✅️ Inhabited Nat[Meta.synthInstance.resume] ✅️ propagating Inhabited Nat to subgoal Inhabited Nat of Nonempty Nat[Meta.synthInstance.resume] size: 1[Meta.synthInstance.answer] ✅️ Nonempty Nat[Meta.synthInstance.resume] ✅️ propagating Nonempty Nat to subgoal Nonempty Nat of Nonempty (Sum Nat Empty)[Meta.synthInstance.resume] size: 2[Meta.synthInstance.answer] ✅️ Nonempty (Sum Nat Empty)[Meta.synthInstance] result @Sum.nonemptyLeft Nat Empty (@instNonemptyOfInhabited Nat instInhabitedNat)@Sum.nonemptyLeft Nat Empty (@instNonemptyOfInhabited Nat instInhabitedNat)
```


### Display 4


```text
{ x := 0, y := 0 }
```


### Display 5


```text
@aNonemptySumInstance Nat Empty (@instNonemptyOfInhabited Nat instInhabitedNat)
```


### Display 6


```text
typeclass instance problem is stuck
  Serialize (Nat × Nat) ?m.5

Note: Lean will not try to resolve this typeclass instance problem because the second type argument to `Serialize` is a metavariable. This argument must be fully determined before Lean will try to resolve the typeclass.

Hint: Adding type annotations and supplying implicit arguments to functions can give Lean more information for typeclass resolution. For example, if you have a variable `x` that you intend to be a `Nat`, but Lean reports it as having an unresolved type like `?m`, replacing `x` with `(x : Nat)` can get typeclass resolution un-stuck.
```


### Display 7


```text
failed to synthesize instance of type class
  OneSmaller (Option Bool) Bool

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```


### Display 8


```text
OneSmaller.shrink (some false) ⋯ : Bool
```

