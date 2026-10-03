<a id="signature-syntax"></a>

# ProofScript — 7.2. Headers and Signatures

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Use def for general declarations, function for an explicitly parameterized definition, and const for a parameterless definition. Keep theorem, example, abbrev and opaque distinct. Expression bodies end through native boundary and suffix rules, not an added semicolon. Dependent binders and named/default arguments preserve native elaboration. Structural and well-founded recursion need the native evidence; partial definitions keep their opaque logical interpretation and separately accounted executable bodies.

**Compiler and coverage boundary.** Preserve declaration kinds, safety/reducibility metadata, native termination suffixes and local capture. An abbreviation is not a fresh nominal type.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Definitions/Headers-and-Signatures/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Definitions/Headers-and-Signatures/index.html). Source Git blob: `6f3f661eec1c02ab33ccc7f10add3de3295409f9`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 7.2. Headers and Signatures

The 
<a id="--tech-term-header"></a>
*header* of a definition or declaration consists of the constant being declared or defined, if relevant, together with its signature. The 
<a id="--tech-term-signature"></a>
*signature* of a constant specifies how it can be used. The information present in the signature is more than just the type, including information such as [universe level parameters](../../The-Type-System/Universes/index.md#--tech-term-universe-parameters) and the default values of its optional parameters. In Lean, signatures are written in a consistent format in different kinds of declarations.

<a id="The-Lean-Language-Reference--Definitions--Headers-and-Signatures--Declaration-Names"></a>
### 7.2.1. Declaration Names

Most headers begin with a 
<a id="--tech-term-declaration-name"></a>
*declaration name*, which is followed by the signature proper: its parameters and the resulting type. A declaration name is a name that may optionally include universe parameters.

<a id="declId"></a>

**syntax**

**Declaration Names**

Declaration names without universe parameters consist of an identifier:

<a id="Lean___Parser___Command___declId"></a>

```ebnf
declId ::=
    ident
```

Declaration names with universe parameters consist of an identifier followed by a period and one or more universe parameter names in braces:

<a id="Lean___Parser___Command___declId-next"></a>

```ebnf
declId ::= ...
    | ident.{ident, ident,*}
```

These universe parameter names are binding occurrences.

Examples do not include declaration names, and names are optional for instance declarations.

<a id="parameter-syntax"></a>
### 7.2.2. Parameters and Types

After the name, if present, is the header's signature. The signature specifies the declaration's parameters and type.

<a id="declSig"></a>

**syntax**

**Declaration Signatures**

A signature consists of zero or more parameters, followed by a colon and a type.

<a id="Lean___Parser___Command___declSig"></a>

```ebnf
declSig ::=
    (ident | hole | bracketedBinder)* : term
```

<a id="optDeclSig"></a>

**syntax**

**Optional Signatures**

Signatures are often optional. In these cases, parameters may be supplied even if the type is omitted.

<a id="Lean___Parser___Command___optDeclSig"></a>

```ebnf
optDeclSig ::=
    (ident | hole | bracketedBinder)* (: term)?
```

Parameters may have three forms:

- An identifier, which names a parameter but does not provide a type. These parameters' types must be inferred during elaboration.
- An underscore (`_`), which indicates a parameter that is not accessible by name in the local scope. These parameters' types must also be inferred during elaboration.
- A bracketed binder, which may specify every aspect of one or more parameters, including their names, their types, default values, and whether they are explicit, implicit, strictly implicit, or instance-implicit.

<a id="bracketed-parameter-syntax"></a>
### 7.2.3. Bracketed Parameter Bindings

Parameters other than identifiers or underscores are collectively referred to as 
<a id="--tech-term-bracketed-binders"></a>
*bracketed binders* because every syntactic form for specifying them has some kind of brackets, braces, or parentheses. All bracketed binders specify the type of a parameter, and most include parameter names. The name is optional for instance implicit parameters. Using an underscore (`_`) instead of a parameter name indicates an anonymous parameter.

<a id="bracketedBinder"></a>

**syntax**

**Explicit Parameters**

Parenthesized parameters indicate explicit parameters. If more than one identifier or underscore is provided, then all of them become parameters with the same type.

<a id="Lean___Parser___Term___explicitBinder"></a>

```ebnf
bracketedBinder ::=
    ((ident | hole) (ident | hole)* : term)
```

<a id="bracketedBinder-next"></a>

**syntax**

**Optional and Automatic Parameters**

Parenthesized parameters with a `:=` assign default values to parameters. Parameters with default values are called 
<a id="--tech-term-optional-parameters"></a>
*optional parameters*. At a call site, if the parameter is not provided, then the provided term is used to fill it in. Prior parameters in the signature are in scope for the default value, and their values at the call site are substituted into the default value term.

If a [tactic script](../../Tactic-Proofs/index.md#tactics) is provided, then the tactics are executed at the call site to synthesize a parameter value; parameters that are filled in via tactics are called 
<a id="--tech-term-automatic-parameters"></a>
*automatic parameters*.

<a id="Lean___Parser___Term___explicitBinder-next"></a>

```ebnf
bracketedBinder ::= ...
    | ((ident | hole) (ident | hole)* : term := term)
```

<a id="bracketedBinder-next-next"></a>

**syntax**

**Implicit Parameters**

Parameters in curly braces indicate [implicit](../../Terms/Functions/index.md#--tech-term-implicit) parameters. Unless provided by name at a call site, these parameters are expected to be synthesized via unification at call sites. Implicit parameters are synthesized at all call sites.

<a id="Lean___Parser___Term___implicitBinder"></a>

```ebnf
bracketedBinder ::= ...
    | {(ident | hole) (ident | hole)* : term}
```

<a id="bracketedBinder-next-next-next"></a>

**syntax**

**Strict Implicit Parameters**

Parameters in double curly braces indicate [strict implicit](../../Terms/Functions/index.md#--tech-term-Strict-implicit) parameters. `⦃ … ⦄` and `{{ … }}` are equivalent. Like implicit parameters, these parameters are expected to be synthesized via unification at call sites when they are not provided by name. Strict implicit parameters are only synthesized at call sites when subsequent parameters in the signature are also provided.

<a id="Lean___Parser___Term___strictImplicitBinder"></a>

```ebnf
bracketedBinder ::= ...
    | ⦃(ident | hole) (ident | hole)* : term⦄
```

<a id="Lean___Parser___Term___strictImplicitBinder-next"></a>

```ebnf
bracketedBinder ::= ...
    | {{(ident | hole) (ident | hole)* : term}}
```

<a id="bracketedBinder-next-next-next-next"></a>

**syntax**

**Instance Implicit Parameters**

Parameters in square brackets indicate [instance implicit](../../Type-Classes/index.md#--tech-term-instance-implicit) parameters, which are synthesized at call sites using [instance synthesis](../../Type-Classes/index.md#--tech-term-synthesizes).

<a id="Lean___Parser___Term___instBinder"></a>

```ebnf
bracketedBinder ::= ...
    | [(ident :)? term]
```

The parameters are always in scope in the signature's type, which occurs after the colon. They are also in scope in the declaration's body, while names bound in the type itself are only in scope in the type. Thus, parameter names are used twice:

- As names in the declaration's function type, bound as part of a [dependent function type](../../The-Type-System/Functions/index.md#--tech-term-Dependent).
- As names in the declaration's body. In function definitions, they are bound by a `fun`.

<a id="Parameter-Scope"></a>
Parameter Scope 

The signature of `add` contains one parameter, `n`. Additionally, the signature's type is `(k : Nat) → Nat`, which is a function type that includes `k`. The parameter `n` is in scope in the function's body, but `k` is not.
<a id="add-_LPAR_in-Parameter-Scope_RPAR_"></a>


```proofscript
def add (n : Nat) : (k : Nat) → Nat
  | 0 => n
  | k' + 1 => 1 + add n k'
```

Like `add`, the signature of `mustBeEqual` contains one parameter, `n`. It is in scope both in the type, where it occurs in a proposition, and in the body, where it occurs as part of the message.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="mustBeEqual-_LPAR_in-Parameter-Scope_RPAR_"></a>


```proofscript
function mustBeEqual (n : Nat) : (k : Nat) → n = k → String :=
  fun _ =>
    fun
    | rfl => s!"Equal - both are {n}!"
```

The section on [function application](../../Terms/Function-Application/index.md#function-application) describes the interpretation of [optional](index.md#--tech-term-optional-parameters), [automatic](index.md#--tech-term-automatic-parameters), [implicit](../../Terms/Functions/index.md#--tech-term-implicit), and [instance implicit](../../Type-Classes/index.md#--tech-term-instance-implicit) parameters in detail.

<a id="automatic-implicit-parameters"></a>
### 7.2.4. Automatic Implicit Parameters

By default, otherwise-unbound names that occur in signatures are converted into implicit parameters when possible These parameters are called 
<a id="--tech-term-automatic-implicit-parameters"></a>
*automatic implicit parameters*. This is possible when they are not in the function position of an application and when there is sufficient information available in the signature to infer their type and any ordering constraints on them. This process is iterated: if the inferred type for the freshly-inserted implicit parameter has dependencies that are not uniquely determined, then these dependencies are replaced with further implicit parameters.

Implicit parameters that don't correspond to names written in signatures are assigned names akin to those of [inaccessible](../../Tactic-Proofs/Reading-Proof-States/index.md#--tech-term-inaccessible) hypotheses in proofs, which cannot be referred to. They show up in signatures with a trailing dagger (`'✝'`). This prevents an arbitrary choice of name by Lean from becoming part of the API by being usable as a [named argument](../../Terms/Function-Application/index.md#--tech-term-named-arguments).

<a id="Automatic-Implicit-Parameters"></a>
Automatic Implicit Parameters 

In this definition of `map`, `α` and `β` are not explicitly bound. Rather than this being an error, they are converted into implicit parameters. Because they must be types, but nothing constrains their universes, the universe parameters `u` and `v` are also inserted.
<a id="map-_LPAR_in-Automatic-Implicit-Parameters_RPAR_"></a>


```proofscript
def map (f : α → β) : (xs : List α) → List β
  | [] => []
  | x :: xs => f x :: map f xs
```

The full signature of `map` is:

```proofscript
map.{u, v} {α : Type u} {β : Type v}
  (f : α → β) (xs : List α) :
  List β
```

<a id="No-Automatic-Implicit-Parameters"></a>
No Automatic Implicit Parameters 

In this definition, `α` and `β` are not explicitly bound. Because `autoImplicit` is disabled, this is an error:

```proofscript
set_option autoImplicit false

def map (f : α → β) : (xs : List α) → List β
  | [] => []
  | x :: xs => f x :: map f xs
```

```lean
Unknown identifier `α`

Note: It is not possible to treat `α` as an implicitly bound variable here because the `autoImplicit` option is set to `false`.
```

```lean
Unknown identifier `β`

Note: It is not possible to treat `β` as an implicitly bound variable here because the `autoImplicit` option is set to `false`.
```

The full signature allows the definition to be accepted:

```proofscript
set_option autoImplicit false

def map.{u, v} {α : Type u} {β : Type v}
    (f : α → β) :
    (xs : List α) → List β
  | [] => []
  | x :: xs => f x :: map f xs
```

Universe parameters are inserted automatically for parameters without explicit type annotations. The type parameters' universes can be inferred, and the appropriate universe parameters inserted, even when `autoImplicit` is disabled:

```proofscript
set_option autoImplicit false

def map {α β} (f : α → β) :
    (xs : List α) → List β
  | [] => []
  | x :: xs => f x :: map f xs
```

<a id="Iterated-Automatic-Implicit-Parameters"></a>
Iterated Automatic Implicit Parameters 

Given a number bounded by `n`, represented by the type `Fin n`, an `AtLeast i` is a natural number paired with a proof that it is at least as large as `i`.
<a id="AtLeast-_LPAR_in-Iterated-Automatic-Implicit-Parameters_RPAR_"></a>
<a id="AtLeast___val-_LPAR_in-Iterated-Automatic-Implicit-Parameters_RPAR_"></a>
<a id="AtLeast___val_gt_i-_LPAR_in-Iterated-Automatic-Implicit-Parameters_RPAR_"></a>


```proofscript
structure AtLeast (i : Fin n) where
  val : Nat
  val_gt_i : val ≥ i.val
```

These numbers can be added:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="AtLeast___add-_LPAR_in-Iterated-Automatic-Implicit-Parameters_RPAR_"></a>


```proofscript
function AtLeast.add (x y : AtLeast i) : AtLeast i :=
  AtLeast.mk (x.val + y.val) <| by
    cases x
    cases y
    dsimp only
    omega
```

The signature of `AtLeast.add` requires multiple rounds of automatic implicit parameter insertion. First, `i` is inserted; but its type depends on the upper bound `n` of `Fin n`. In the second round, `n` is inserted, using a machine-chosen name. Because `n`'s type is `Nat`, which has no dependencies, the process terminates. The final signature can be seen with [`#check`](../../Interacting-with-Lean/index.md#Lean___Parser___Command___check):

```proofscript
#check AtLeast.add
```

```lean
AtLeast.add {n✝ : Nat} {i : Fin n✝} (x y : AtLeast i) : AtLeast i
```

Automatic implicit parameter insertion takes place after the insertion of parameters due to [section variables](../../Namespaces-and-Sections/index.md#--tech-term-Section-variables). Parameters that correspond to section variables have the same name as the corresponding variable, even when they do not correspond to a name written directly in the signature, and disabling automatic implicit parameters has no effect the parameters that correspond to section variables. However, when automatic implicit parameters are enabled, section variable declarations that contain otherwise-unbound variables receive additional section variables that follow the same rules as those for implicit parameters.

Automatic implicit parameters insertion is controlled by two options. By default, automatic implicit parameter insertion is *relaxed*, which means that any unbound identifier may be a candidate for automatic insertion. Setting the option `relaxedAutoImplicit` to `false` disables relaxed mode and causes only identifiers that consist of a single character followed by zero or more digits to be considered for automatic insertion.

<a id="relaxedAutoImplicit"></a>

**option**

```text
relaxedAutoImplicit
```

Default value: `true`

When "relaxed" mode is enabled, any atomic nonempty identifier is eligible for auto bound implicit locals (see option `autoImplicit`).

<a id="autoImplicit"></a>

**option**

```text
autoImplicit
```

Default value: `true`

Unbound local variables in declaration headers become implicit arguments. In "relaxed" mode (default), any atomic identifier is eligible, otherwise only single character followed by numeric digits are eligible. For example, `def f (x : Vector α n) : Vector α n :=` automatically introduces the implicit variables {α n}.

<a id="Relaxed-vs-Non-Relaxed-Automatic-Implicit-Parameters"></a>
Relaxed vs Non-Relaxed Automatic Implicit Parameters 

Misspelled identifiers or missing imports can end up as unwanted implicit parameters, as in this example:
<a id="Answer-_LPAR_in-Relaxed-vs-Non-Relaxed-Automatic-Implicit-Parameters_RPAR_"></a>
<a id="Answer___yes-_LPAR_in-Relaxed-vs-Non-Relaxed-Automatic-Implicit-Parameters_RPAR_"></a>
<a id="Answer___maybe-_LPAR_in-Relaxed-vs-Non-Relaxed-Automatic-Implicit-Parameters_RPAR_"></a>
<a id="Answer___no-_LPAR_in-Relaxed-vs-Non-Relaxed-Automatic-Implicit-Parameters_RPAR_"></a>


```proofscript
inductive Answer where
  | yes
  | maybe
  | no
```

```proofscript
def select (choices : α × α × α) : Asnwer →  α
  | .yes => choices.1
  | .maybe => choices.2.1
  | .no => choices.2.2
```

The resulting error message states that the argument's type is not a constant, so dot notation cannot be used in the pattern:

```lean
Invalid dotted identifier notation: The expected type of `.yes`
  Asnwer
is not of the form `C ...` or `... → C ...` where C is a constant
```

This is because the signature is:

```proofscript
select.{u_1, u_2}
  {α : Type u_1}
  {Asnwer : Sort u_2}
  (choices : α × α × α) :
  Asnwer → α
```

Disabling relaxed automatic implicit parameters makes the error more clear, while still allowing the type to be inserted automatically:

```proofscript
set_option relaxedAutoImplicit false

def select (choices : α × α × α) : Asnwer →  α
  | .yes => choices.1
  | .maybe => choices.2.1
  | .no => choices.2.2
```

```lean
Unknown identifier `Asnwer`

Note: It is not possible to treat `Asnwer` as an implicitly bound variable here because it has multiple characters while the `relaxedAutoImplicit` option is set to `false`.
```

Correcting the error allows the definition to be accepted.

```proofscript
set_option relaxedAutoImplicit false

def select (choices : α × α × α) : Answer →  α
  | .yes => choices.1
  | .maybe => choices.2.1
  | .no => choices.2.2
```

Turning off automatic implicit parameters entirely leads to the definition being rejected:

```proofscript
set_option autoImplicit false

def select (choices : α × α × α) : Answer →  α
  | .yes => choices.1
  | .maybe => choices.2.1
  | .no => choices.2.2
```

```lean
Unknown identifier `α`

Note: It is not possible to treat `α` as an implicitly bound variable here because the `autoImplicit` option is set to `false`.
```

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`declId` matches `foo` or `foo.{u,v}`: an identifier possibly followed by a list of universe names
```


### Display 2


```text
`declSig` matches the signature of a declaration with required type: a list of binders and then `: type`
```


### Display 3


```text
A *hole* (or *placeholder term*), which stands for an unknown term that is expected to be inferred based on context.
For example, in `@id _ Nat.zero`, the `_` must be the type of `Nat.zero`, which is `Nat`.

The way this works is that holes create fresh metavariables.
The elaborator is allowed to assign terms to metavariables while it is checking definitional equalities.
This is often known as *unification*.

Normally, all holes must be solved for. However, there are a few contexts where this is not necessary:
* In `match` patterns, holes are catch-all patterns.
* In some tactics, such as `refine'` and `apply`, unsolved-for placeholders become new goals.

Related concept: implicit parameters are automatically filled in with holes during the elaboration process.

See also `?m` syntax (synthetic holes).
```


### Display 4


```text
`optDeclSig` matches the signature of a declaration with optional type: a list of binders and then possibly `: type`
```


### Display 5


```text
Explicit binder, like `(x y : A)` or `(x y)`.
Default values can be specified using `(x : A := v)` syntax, and tactics using `(x : A := by tac)`.
```


### Display 6


```text
Implicit binder, like `{x y : A}` or `{x y}`.
In regular applications, whenever all parameters before it have been specified,
then a `_` placeholder is automatically inserted for this parameter.
Implicit parameters should be able to be determined from the other arguments and the return type
by unification.

In `@` explicit mode, implicit binders behave like explicit binders.
```


### Display 7


```text
Strict-implicit binder, like `⦃x y : A⦄` or `⦃x y⦄`.
In contrast to `{ ... }` implicit binders, strict-implicit binders do not automatically insert
a `_` placeholder until at least one subsequent explicit parameter is specified.
Do *not* use strict-implicit binders unless there is a subsequent explicit parameter.
Assuming this rule is followed, for fully applied expressions implicit and strict-implicit binders have the same behavior.

Example: If `h : ∀ ⦃x : A⦄, x ∈ s → p x` and `hs : y ∈ s`,
then `h` by itself elaborates to itself without inserting `_` for the `x : A` parameter,
and `h hs` has type `p y`.
In contrast, if `h' : ∀ {x : A}, x ∈ s → p x`, then `h` by itself elaborates to have type `?m ∈ s → p ?m`
with `?m` a fresh metavariable.
```


### Display 8


```text
Instance-implicit binder, like `[C]` or `[inst : C]`.
In regular applications without `@` explicit mode, it is automatically inserted
and solved for by typeclass inference for the specified class `C`.
In `@` explicit mode, if `_` is used for an instance-implicit parameter, then it is still solved for by typeclass inference;
use `(_)` to inhibit this and have it be solved for by unification instead, like an implicit argument.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Unknown identifier `α`

Note: It is not possible to treat `α` as an implicitly bound variable here because the `autoImplicit` option is set to `false`.
```


### Display 2


```text
Unknown identifier `β`

Note: It is not possible to treat `β` as an implicitly bound variable here because the `autoImplicit` option is set to `false`.
```


### Display 3


```text
AtLeast.add {n✝ : Nat} {i : Fin n✝} (x y : AtLeast i) : AtLeast i
```


### Display 4


```text
Invalid dotted identifier notation: The expected type of `.yes`
  Asnwer
is not of the form `C ...` or `... → C ...` where C is a constant
```


### Display 5


```text
Unknown identifier `Asnwer`

Note: It is not possible to treat `Asnwer` as an implicitly bound variable here because it has multiple characters while the `relaxedAutoImplicit` option is set to `false`.
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
n✝:Nati:Fin n✝x:AtLeast iy:AtLeast i⊢ x.val + y.val ≥ ↑i
```


### Display 2


```text
mkn✝:Nati:Fin n✝y:AtLeast ival✝:Natval_gt_i✝:val✝ ≥ ↑i⊢ { val := val✝, val_gt_i := val_gt_i✝ }.val + y.val ≥ ↑i
```


### Display 3


```text
mk.mkn✝:Nati:Fin n✝val✝¹:Natval_gt_i✝¹:val✝ ≥ ↑ival✝:Natval_gt_i✝:val✝ ≥ ↑i⊢ { val := val✝¹, val_gt_i := val_gt_i✝¹ }.val + { val := val✝, val_gt_i := val_gt_i✝ }.val ≥ ↑i
```


### Display 4


```text
mk.mkn✝:Nati:Fin n✝val✝¹:Natval_gt_i✝¹:val✝ ≥ ↑ival✝:Natval_gt_i✝:val✝ ≥ ↑i⊢ val✝¹ + val✝ ≥ ↑i
```


### Display 5


```text
All goals completed! 🐙
```

