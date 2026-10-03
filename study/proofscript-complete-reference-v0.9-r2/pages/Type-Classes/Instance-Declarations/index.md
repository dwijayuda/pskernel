<a id="instance-declarations"></a>

# ProofScript — 10.2. Instance Declarations

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Classes are native type-directed interfaces, not JavaScript classes. Instances provide dictionaries and associated evidence. Inference uses the pinned priority and search behavior, so importing an instance can affect elaboration. Derived instances are generated declarations that must be checked. Boolean equality and hashing require laws when used for logical claims.

**Compiler and coverage boundary.** Braced class fields use native field-declaration layout. Instance initializers use their own native sequence grammar, including semicolons only where that grammar permits them.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Type-Classes/Instance-Declarations/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Type-Classes/Instance-Declarations/index.html). Source Git blob: `6e15d2264178f40e251cfa1f2caa0573099e1c58`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 10.2. Instance Declarations

The syntax of instance declarations is almost identical to that of definitions. The only syntactic differences are that the keyword `def` is replaced by `instance` and the name is optional:

<a id="Lean___Parser___Command___instance"></a>

**syntax**

**Instance Declarations**

Most instances define each method using `where` syntax:

<a id="Lean___Parser___Command___instance-next"></a>

```ebnf
instance ::= ...
    | instance ((priority := prio))? declId? declSig where
        structInstField*
```

However, type classes are inductive types, so instances can be constructed using any expression with an appropriate type:

<a id="Lean___Parser___Command___instance-next-next"></a>

```ebnf
instance ::= ...
    | instance ((priority := prio))? declId? declSig :=
        term
```

Instances may also be defined by cases; however, this feature is rarely used outside of `Decidable` instances:

<a id="Lean___Parser___Command___instance-next-next-next"></a>

```ebnf
instance ::= ...
    | instance ((priority := prio))? declId? declSig
        (| term => term)*
```

Instances defined with explicit terms often consist of either anonymous constructors ([`⟨...⟩`](../../The-Type-System/Inductive-Types/index.md#Lean___Parser___Term___anonymousCtor)) wrapping method implementations or of invocations of `inferInstanceAs` on definitionally equal types.

Elaboration of instances is almost identical to the elaboration of ordinary definitions, with the exception of the caveats documented below. If no name is provided, then one is created automatically. It is possible to refer to this generated name directly, but the algorithm used to generate the names has changed in the past and may change in the future. It's better to explicitly name instances that will be referred to directly. After elaboration, the new instance is registered as a candidate for instance search. Adding the attribute `instance` to a name can be used to mark any other defined name as a candidate.

<a id="Instance-Name-Generation"></a>
Instance Name Generation 

Following these declarations:
<a id="NatWrapper-_LPAR_in-Instance-Name-Generation_RPAR_"></a>
<a id="NatWrapper___val-_LPAR_in-Instance-Name-Generation_RPAR_"></a>


```proofscript
structure NatWrapper where
  val : Nat

instance : BEq NatWrapper where
  beq
    | ⟨x⟩, ⟨y⟩ => x == y
```

the name `instBEqNatWrapper` refers to the new instance.

<a id="Variations-in-Instance-Definitions"></a>
Variations in Instance Definitions 

Given this structure type:
<a id="NatWrapper-_LPAR_in-Variations-in-Instance-Definitions_RPAR_"></a>
<a id="NatWrapper___val-_LPAR_in-Variations-in-Instance-Definitions_RPAR_"></a>


```proofscript
structure NatWrapper where
  val : Nat
```

all of the following ways of defining a `BEq` instance are equivalent:

```proofscript
instance : BEq NatWrapper where
  beq
    | ⟨x⟩, ⟨y⟩ => x == y

instance : BEq NatWrapper :=
  ⟨fun x y => x.val == y.val⟩

instance : BEq NatWrapper :=
  ⟨fun ⟨x⟩ ⟨y⟩ => x == y⟩
```

Aside from introducing different names into the environment, the following are also equivalent:
<a id="instBeqNatWrapper-_LPAR_in-Variations-in-Instance-Definitions_RPAR_"></a>


```proofscript
@[instance]
def instBeqNatWrapper : BEq NatWrapper where
  beq
    | ⟨x⟩, ⟨y⟩ => x == y

instance : BEq NatWrapper :=
  ⟨fun x y => x.val == y.val⟩

instance : BEq NatWrapper :=
  ⟨fun ⟨x⟩ ⟨y⟩ => x == y⟩
```

<a id="recursive-instances"></a>
### 10.2.1. Recursive Instances

Functions defined in `where` structure definition syntax are not recursive. Because instance declaration is a version of structure definition, type class methods are also not recursive by default. Instances for recursive inductive types are common, however. There is a standard idiom to work around this limitation: define a recursive function independently of the instance, and then refer to it in the instance definition. By convention, these recursive functions have the name of the corresponding method, but are defined in the type's namespace.

<a id="Instances-are-not-recursive"></a>
Instances are not recursive 

Given this definition of `NatTree`:
<a id="NatTree-_LPAR_in-Instances-are-not-recursive_RPAR_"></a>
<a id="NatTree___leaf-_LPAR_in-Instances-are-not-recursive_RPAR_"></a>
<a id="NatTree___branch-_LPAR_in-Instances-are-not-recursive_RPAR_"></a>


```proofscript
inductive NatTree where
  | leaf
  | branch (left : NatTree) (val : Nat) (right : NatTree)
```

the following `BEq` instance fails:

```proofscript
instance : BEq NatTree where
  beq
    | .leaf, .leaf =>
      true
    | .branch l1 v1 r1, .branch l2 v2 r2 =>
      l1 == l2 && v1 == v2 && r1 == r2
    | _, _ =>
      false
```

with errors in both the left and right recursive calls that read:

```lean
failed to synthesize instance of type class
  BEq NatTree

Hint: Adding the command `deriving instance BEq for NatTree` may allow Lean to derive the missing instance.
```

Given a suitable recursive function, such as `NatTree.beq`:
<a id="NatTree___beq-_LPAR_in-Instances-are-not-recursive_RPAR_"></a>


```proofscript
def NatTree.beq : NatTree → NatTree → Bool
  | .leaf, .leaf =>
    true
  | .branch l1 v1 r1, .branch l2 v2 r2 =>
    NatTree.beq l1 l2 && v1 == v2 && NatTree.beq r1 r2
  | _, _ =>
    false
```

the instance can be created in a second step:

```proofscript
instance : BEq NatTree where
  beq := NatTree.beq
```

or, equivalently, using anonymous constructor syntax:

```proofscript
instance : BEq NatTree := ⟨NatTree.beq⟩
```

Furthermore, instances are not available for instance synthesis during their own definitions. They are first marked as being available for instance synthesis after they are defined. Nested inductive types, in which the recursive occurrence of the type occurs as a parameter to some other inductive type, may require an instance to be available to write even the recursive function. The standard idiom to work around this limitation is to create a local instance in a recursively-defined function that includes a reference to the function being defined, taking advantage of the fact that instance synthesis may use every binding in the local context with the right type.

<a id="Instances-for-nested-types"></a>
Instances for nested types 

In this definition of `NatRoseTree`, the type being defined occurs nested under another inductive type constructor (`Array`):
<a id="NatRoseTree-_LPAR_in-Instances-for-nested-types_RPAR_"></a>
<a id="NatRoseTree___node-_LPAR_in-Instances-for-nested-types_RPAR_"></a>


```proofscript
inductive NatRoseTree where
  | node (val : Nat) (children : Array NatRoseTree)
```

Checking the equality of rose trees requires checking equality of arrays. However, instances are not typically available for instance synthesis during their own definitions, so the following definition fails, even though `NatRoseTree.beq` is a recursive function and is in scope in its own definition.

```proofscript
def NatRoseTree.beq : (tree1 tree2 : NatRoseTree) → Bool
  | .node val1 children1, .node val2 children2 =>
    val1 == val2 &&
    children1 == children2
```

```lean
failed to synthesize instance of type class
  BEq (Array NatRoseTree)

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

To solve this, a local `BEq NatRoseTree` instance may be `let`-bound:

```proofscript
partial def NatRoseTree.beq : (tree1 tree2 : NatRoseTree) → Bool
  | .node val1 children1, .node val2 children2 =>
    let _ : BEq NatRoseTree := ⟨NatRoseTree.beq⟩
    val1 == val2 &&
    children1 == children2
```

The use of array equality on the children finds the let-bound instance during instance synthesis.

<a id="class-inductive-instances"></a>
### 10.2.2. Instances of class inductives

Many instances have function types: any instance that itself recursively invokes instance search is a function, as is any instance with implicit parameters. While most instances only project method implementations from their own instance parameters, instances of class inductive types typically pattern-match one or more of their arguments, allowing the instance to select the appropriate constructor. This is done using ordinary Lean function syntax. Just as with other instances, the function in question is not available for instance synthesis in its own definition.

<a id="An-instance-for-a-sum-class"></a>
An instance for a sum class 

Because `DecidableEq α` is an abbreviation for `(a b : α) → Decidable (Eq a b)`, its arguments can be used directly, as in this example:
<a id="ThreeChoices-_LPAR_in-An-instance-for-a-sum-class_RPAR_"></a>
<a id="ThreeChoices___yes-_LPAR_in-An-instance-for-a-sum-class_RPAR_"></a>
<a id="ThreeChoices___no-_LPAR_in-An-instance-for-a-sum-class_RPAR_"></a>
<a id="ThreeChoices___maybe-_LPAR_in-An-instance-for-a-sum-class_RPAR_"></a>


```proofscript
inductive ThreeChoices where
  | yes | no | maybe

instance : DecidableEq ThreeChoices
  | .yes,   .yes   =>
    .isTrue rfl
  | .no,    .no    =>
    .isTrue rfl
  | .maybe, .maybe =>
    .isTrue rfl
  | .yes,   .maybe | .yes,   .no
  | .maybe, .yes   | .maybe, .no
  | .no,    .yes   | .no,    .maybe =>
    .isFalse nofun
```

<a id="A-recursive-instance-for-a-sum-class"></a>
A recursive instance for a sum class 

The type `StringList` represents monomorphic lists of strings:
<a id="StringList-_LPAR_in-A-recursive-instance-for-a-sum-class_RPAR_"></a>
<a id="StringList___nil-_LPAR_in-A-recursive-instance-for-a-sum-class_RPAR_"></a>
<a id="StringList___cons-_LPAR_in-A-recursive-instance-for-a-sum-class_RPAR_"></a>


```proofscript
inductive StringList where
  | nil
  | cons (hd : String) (tl : StringList)
```

In the following attempt at defining a `DecidableEq` instance, instance synthesis invoked while elaborating the inner [`if`](../../Terms/Conditionals/index.md#termIfThenElse) fails because the instance is not available for instance synthesis in its own definition:

```proofscript
instance : DecidableEq StringList
  | .nil, .nil => .isTrue rfl
  | .cons h1 t1, .cons h2 t2 =>
    if h : h1 = h2 then
      if h' : t1 = t2 then
        .isTrue (by simp [*])
      else
        .isFalse (by intro hEq; cases hEq; trivial)
    else
      .isFalse (by intro hEq; cases hEq; trivial)
  | .nil, .cons _ _ | .cons _ _, .nil => .isFalse nofun
```

```lean
failed to synthesize instance of type class
  Decidable (t1 = t2)

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

However, because it is an ordinary Lean function, it can recursively refer to its own explicitly-provided name:
<a id="instDecidableEqStringList-_LPAR_in-A-recursive-instance-for-a-sum-class_RPAR_"></a>


```proofscript
instance instDecidableEqStringList : DecidableEq StringList
  | .nil, .nil => .isTrue rfl
  | .cons h1 t1, .cons h2 t2 =>
    let _ : Decidable (t1 = t2) :=
      instDecidableEqStringList t1 t2
    if h : h1 = h2 then
      if h' : t1 = t2 then
        .isTrue (by simp [*])
      else
        .isFalse (by intro hEq; cases hEq; trivial)
    else
      .isFalse (by intro hEq; cases hEq; trivial)
  | .nil, .cons _ _ | .cons _ _, .nil => .isFalse nofun
```

<a id="instance-priorities"></a>
### 10.2.3. Instance Priorities

Instances may be assigned 
<a id="--tech-term-priorities"></a>
*priorities*. During instance synthesis, higher-priority instances are preferred; see [the section on instance synthesis](../Instance-Synthesis/index.md#instance-synth) for details of instance synthesis.

<a id="prio"></a>

**syntax**

**Instance Priorities**

Priorities may be numeric:

<a id="num___antiquot"></a>

```ebnf
prio ::=
    num
```

If no priority is specified, the default priority that corresponds to 1000 is used:

<a id="prioDefault"></a>

```ebnf
prio ::= ...
    | default
```

Three named priorities are available when numeric values are too fine-grained, corresponding to 100, 500, and 10000 respectively. The [`mid`](index.md#prioMid) priority is lower than [`default`](index.md#prioDefault).

<a id="prioLow"></a>

```ebnf
prio ::= ...
    | low
```

<a id="prioMid"></a>

```ebnf
prio ::= ...
    | mid
```

<a id="prioHigh"></a>

```ebnf
prio ::= ...
    | high
```

Finally, priorities can be added and subtracted, so `default + 2` is a valid priority, corresponding to 1002:

<a id="_FLQQ_prio_LPAR___RPAR__FLQQ_"></a>

```ebnf
prio ::= ...
    | (prio)
```

<a id="Lean___Parser___Syntax___addPrio"></a>

```ebnf
prio ::= ...
    | prio + prio
```

<a id="Lean___Parser___Syntax___subPrio"></a>

```ebnf
prio ::= ...
    | prio - prio
```

<a id="default-instances"></a>
### 10.2.4. Default Instances

The `default_instance` attribute specifies that an instance [should be used as a fallback in situations where there is not enough information to select it otherwise](../Instance-Synthesis/index.md#default-instance-synth). If no priority is specified, then the default priority `default` is used.

<a id="attr-next-next-next"></a>

**attribute**

**The default_instance Attribute**

<a id="Lean___Parser___Attr___default_instance"></a>

```ebnf
attr ::= ...
    | default_instance prio?
```

<a id="Default-Instances"></a>
Default Instances 

A default instance of `OfNat Nat` is used to select `Nat` for natural number literals in the absence of other type information. It is declared in the Lean standard library with priority 100. Given this representation of even numbers, in which an even number is represented by half of it:
<a id="Even-_LPAR_in-Default-Instances_RPAR_"></a>
<a id="Even___half-_LPAR_in-Default-Instances_RPAR_"></a>


```proofscript
structure Even where
  half : Nat
```

the following instances allow numeric literals to be used for small `Even` values (a limit on the depth of type class instance search prevents them from being used for arbitrarily large literals):
<a id="ofNatEven0-_LPAR_in-Default-Instances_RPAR_"></a>
<a id="ofNatEvenPlusTwo-_LPAR_in-Default-Instances_RPAR_"></a>


```proofscript
instance ofNatEven0 : OfNat Even 0 where
  ofNat := ⟨0⟩

instance ofNatEvenPlusTwo [OfNat Even n] : OfNat Even (n + 2) where
  ofNat := ⟨(OfNat.ofNat n : Even).half + 1⟩

#eval (0 : Even)
#eval (34 : Even)
#eval (254 : Even)
```

```lean
{ half := 0 }
```

```lean
{ half := 17 }
```

```lean
{ half := 127 }
```

Specifying them as default instances with a priority greater than or equal to 100 causes them to be used instead of `Nat`:

```proofscript
attribute [default_instance 100] ofNatEven0
attribute [default_instance 100] ofNatEvenPlusTwo
```

```proofscript
#eval 0
#eval 34
```

```lean
{ half := 0 }
```

```lean
{ half := 17 }
```

Non-even numerals still use the `OfNat Nat` instance:

```proofscript
#eval 5
```

```lean
5
```

<a id="instance-attribute"></a>
### 10.2.5. The Instance Attribute

The `instance` attribute declares a name to be an instance, with the specified priority. Like other attributes, `instance` can be applied globally, locally, or only when the current namespace is opened. The `instance` declaration is a form of definition that automatically applies the `instance` attribute.

<a id="attr-next-next-next-next"></a>

**attribute**

**The instance Attribute**

Declares the definition to which it is applied to be an instance. If no priority is provided, then the default priority `default` is used.

<a id="Lean___Parser___Attr___instance"></a>

```ebnf
attr ::= ...
    | instance prio?
```

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`attrKind` matches `("scoped" <|> "local")?`, used before an attribute like `@[local simp]`.
```


### Display 2


```text
`declId` matches `foo` or `foo.{u,v}`: an identifier possibly followed by a list of universe names
```


### Display 3


```text
`declSig` matches the signature of a declaration with required type: a list of binders and then `: type`
```


### Display 4


```text
Termination hints are `termination_by` and `decreasing_by`, in that order.
```


### Display 5


```text
The default priority `default = 1000`, which is used when no priority is set.
```


### Display 6


```text
The standardized "low" priority `low = 100`, for things that should be lower than default priority.
```


### Display 7


```text
The standardized "medium" priority `mid = 500`. This is lower than `default`, and higher than `low`.
```


### Display 8


```text
The standardized "high" priority `high = 10000`, for things that should be higher than default priority.
```


### Display 9


```text
Parentheses are used for grouping priority expressions.
```


### Display 10


```text
Addition of priorities. This is normally used only for offsetting, e.g. `default + 1`.
```


### Display 11


```text
Subtraction of priorities. This is normally used only for offsetting, e.g. `default - 1`.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Definition `instBeqNatWrapper` of class type is semireducible. Most type class instances should be instance-reducible, so consider marking this
definition with `@[instance_reducible]`. If it is intentionally semireducible, this warning can be disabled with `set_option warn.classDefReducibility false`.
```


### Display 2


```text
failed to synthesize instance of type class
  BEq NatTree

Hint: Adding the command `deriving instance BEq for NatTree` may allow Lean to derive the missing instance.
```


### Display 3


```text
failed to synthesize instance of type class
  BEq (Array NatRoseTree)

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```


### Display 4


```text
failed to synthesize instance of type class
  Decidable (t1 = t2)

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```


### Display 5


```text
{ half := 0 }
```


### Display 6


```text
{ half := 17 }
```


### Display 7


```text
{ half := 127 }
```


### Display 8


```text
5
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
h1:Stringt1:StringListh2:Stringt2:StringListh:h1 = h2h':t1 = t2⊢ StringList.cons h1 t1 = StringList.cons h2 t2
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
h1:Stringt1:StringListh2:Stringt2:StringListh:h1 = h2h':¬t1 = t2⊢ ¬StringList.cons h1 t1 = StringList.cons h2 t2
```


### Display 4


```text
h1:Stringt1:StringListh2:Stringt2:StringListh:h1 = h2h':¬t1 = t2hEq:StringList.cons h1 t1 = StringList.cons h2 t2⊢ False
```


### Display 5


```text
reflh1:Stringt1:StringListh:h1 = h1h':¬t1 = t1⊢ False
```


### Display 6


```text
h1:Stringt1:StringListh2:Stringt2:StringListh:¬h1 = h2⊢ ¬StringList.cons h1 t1 = StringList.cons h2 t2
```


### Display 7


```text
h1:Stringt1:StringListh2:Stringt2:StringListh:¬h1 = h2hEq:StringList.cons h1 t1 = StringList.cons h2 t2⊢ False
```


### Display 8


```text
reflh1:Stringt1:StringListh:¬h1 = h1⊢ False
```


### Display 9


```text
h1:Stringt1:StringListh2:Stringt2:StringListx✝:Decidable (t1 = t2) := instDecidableEqStringList t1 t2h:h1 = h2h':t1 = t2⊢ StringList.cons h1 t1 = StringList.cons h2 t2
```


### Display 10


```text
h1:Stringt1:StringListh2:Stringt2:StringListx✝:Decidable (t1 = t2) := instDecidableEqStringList t1 t2h:h1 = h2h':¬t1 = t2⊢ ¬StringList.cons h1 t1 = StringList.cons h2 t2
```


### Display 11


```text
h1:Stringt1:StringListh2:Stringt2:StringListx✝:Decidable (t1 = t2) := instDecidableEqStringList t1 t2h:h1 = h2h':¬t1 = t2hEq:StringList.cons h1 t1 = StringList.cons h2 t2⊢ False
```


### Display 12


```text
reflh1:Stringt1:StringListh:h1 = h1x✝:Decidable (t1 = t1) := instDecidableEqStringList t1 t1h':¬t1 = t1⊢ False
```


### Display 13


```text
h1:Stringt1:StringListh2:Stringt2:StringListx✝:Decidable (t1 = t2) := instDecidableEqStringList t1 t2h:¬h1 = h2⊢ ¬StringList.cons h1 t1 = StringList.cons h2 t2
```


### Display 14


```text
h1:Stringt1:StringListh2:Stringt2:StringListx✝:Decidable (t1 = t2) := instDecidableEqStringList t1 t2h:¬h1 = h2hEq:StringList.cons h1 t1 = StringList.cons h2 t2⊢ False
```


### Display 15


```text
reflh1:Stringt1:StringListh:¬h1 = h1x✝:Decidable (t1 = t1) := instDecidableEqStringList t1 t1⊢ False
```

