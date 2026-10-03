<a id="class"></a>

# ProofScript — 10.1. Class Declarations

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Classes are native type-directed interfaces, not JavaScript classes. Instances provide dictionaries and associated evidence. Inference uses the pinned priority and search behavior, so importing an instance can affect elaboration. Derived instances are generated declarations that must be checked. Boolean equality and hashing require laws when used for logical claims.

**Compiler and coverage boundary.** Braced class fields use native field-declaration layout. Instance initializers use their own native sequence grammar, including semicolons only where that grammar permits them.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Type-Classes/Class-Declarations/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Type-Classes/Class-Declarations/index.html). Source Git blob: `b3a55bd5dc344116d2242e8b7e3c45b15daf4c40`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 10.1. Class Declarations

Type classes are declared with the `class` keyword.

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Type Class Declarations**

<a id="Lean___Parser___Command___declaration-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
command ::= ...
    | declModifiers
      class declId bracketedBinder* (: term)?
        (extends (ident : )?term,*)?
        where
        (declModifiers ident ::)?
        structFields
      (deriving ident,*)?
```

Declares a new type class.

The `class` declaration creates a new single-constructor inductive type, just as if the `structure` command had been used instead. In fact, the results of the `class` and `structure` commands are almost identical, and features such as default values may be used the same way in both. Please refer to [the documentation for structures](../../The-Type-System/Inductive-Types/index.md#structures) for more information about default values, inheritance, and other features of structures. The differences between structure and class declarations are:

  Methods instead of fields

Instead of creating field projections that take a value of the structure type as an explicit parameter, [methods](../index.md#--tech-term-methods) are created. Each method takes the corresponding instance as an instance-implicit parameter.

  Instance-implicit parent classes

The constructor of a class that extends other classes takes its class parents' instances as instance-implicit parameters, rather than explicit parameters. When instances of this class are defined, instance synthesis is used to find the values of inherited fields. Parents that are not classes are still explicit parameters to the underlying constructor.

  Parent projections via instance synthesis

Structure field projections make use of [inheritance information](../../The-Type-System/Inductive-Types/index.md#structure-inheritance) to project parent structure fields from child structure values. Classes instead use instance synthesis: given a child class instance, synthesis will construct the parent; thus, methods are not added to child classes in the same way that projections are added to child structures.

  Registered as class

The resulting inductive type is registered as a type class, for which instances may be defined and that may be used as the type of instance-implicit arguments.

  Out and semi-out parameters are considered

The `outParam` and `semiOutParam` [gadgets](index.md#--tech-term-gadgets) have no meaning in structure definitions, but they are used in class definitions to control instance search.

While `deriving` clauses are allowed for class definitions to maintain the parallel between class and structure elaboration, they are not frequently used and should be considered an advanced feature.

<a id="No-Instances-of-Non-Classes"></a>
No Instances of Non-Classes 

Lean rejects instance-implicit parameters of types that are not classes:

```proofscript
def f [n : Nat] : n = n := rfl
```

```lean
invalid binder annotation, type is not a class instance
  Nat

Note: Use the command `set_option checkBinderAnnotations false` to disable the check
```

<a id="Class-vs-Structure-Constructors"></a>
Class vs Structure Constructors 

A very small algebraic hierarchy can be represented either as structures (`S.Magma`, `S.Semigroup`, and `S.Monoid` below), a mix of structures and classes (`C1.Monoid`), or only using classes (`C2.Magma`, `C2.Semigroup`, and `C2.Monoid`):
<a id="S___Magma-_LPAR_in-Class-vs-Structure-Constructors_RPAR_"></a>
<a id="S___Magma___op-_LPAR_in-Class-vs-Structure-Constructors_RPAR_"></a>
<a id="S___Semigroup-_LPAR_in-Class-vs-Structure-Constructors_RPAR_"></a>
<a id="S___Semigroup___op_assoc-_LPAR_in-Class-vs-Structure-Constructors_RPAR_"></a>
<a id="S___Monoid-_LPAR_in-Class-vs-Structure-Constructors_RPAR_"></a>
<a id="S___Monoid___ident-_LPAR_in-Class-vs-Structure-Constructors_RPAR_"></a>
<a id="S___Monoid___ident_left-_LPAR_in-Class-vs-Structure-Constructors_RPAR_"></a>
<a id="S___Monoid___ident_right-_LPAR_in-Class-vs-Structure-Constructors_RPAR_"></a>
<a id="C1___Monoid-_LPAR_in-Class-vs-Structure-Constructors_RPAR_"></a>
<a id="C1___Monoid___ident-_LPAR_in-Class-vs-Structure-Constructors_RPAR_"></a>
<a id="C1___Monoid___ident_left-_LPAR_in-Class-vs-Structure-Constructors_RPAR_"></a>
<a id="C1___Monoid___ident_right-_LPAR_in-Class-vs-Structure-Constructors_RPAR_"></a>
<a id="C2___Magma-_LPAR_in-Class-vs-Structure-Constructors_RPAR_"></a>
<a id="C2___Magma___op-_LPAR_in-Class-vs-Structure-Constructors_RPAR_"></a>
<a id="C2___Semigroup-_LPAR_in-Class-vs-Structure-Constructors_RPAR_"></a>
<a id="C2___Semigroup___op_assoc-_LPAR_in-Class-vs-Structure-Constructors_RPAR_"></a>
<a id="C2___Monoid-_LPAR_in-Class-vs-Structure-Constructors_RPAR_"></a>
<a id="C2___Monoid___ident-_LPAR_in-Class-vs-Structure-Constructors_RPAR_"></a>
<a id="C2___Monoid___ident_left-_LPAR_in-Class-vs-Structure-Constructors_RPAR_"></a>
<a id="C2___Monoid___ident_right-_LPAR_in-Class-vs-Structure-Constructors_RPAR_"></a>


```proofscript
namespace S
structure Magma (α : Type u) where
  op : α → α → α

structure Semigroup (α : Type u) extends Magma α where
  op_assoc : ∀ x y z, op (op x y) z = op x (op y z)

structure Monoid (α : Type u) extends Semigroup α where
  ident : α
  ident_left : ∀ x, op ident x = x
  ident_right : ∀ x, op x ident = x
end S

namespace C1
class Monoid (α : Type u) extends S.Semigroup α where
  ident : α
  ident_left : ∀ x, op ident x = x
  ident_right : ∀ x, op x ident = x
end C1

namespace C2
class Magma (α : Type u) where
  op : α → α → α

class Semigroup (α : Type u) extends Magma α where
  op_assoc : ∀ x y z, op (op x y) z = op x (op y z)

class Monoid (α : Type u) extends Semigroup α where
  ident : α
  ident_left : ∀ x, op ident x = x
  ident_right : ∀ x, op x ident = x
end C2
```

`S.Monoid.mk` and `C1.Monoid.mk` have identical signatures, because the parent of the class `C1.Monoid` is not itself a class:

```proofscript
S.Monoid.mk.{u} {α : Type u}
  (toSemigroup : S.Semigroup α)
  (ident : α)
  (ident_left : ∀ (x : α), toSemigroup.op ident x = x)
  (ident_right : ∀ (x : α), toSemigroup.op x ident = x) :
  S.Monoid α
```

```proofscript
C1.Monoid.mk.{u} {α : Type u}
  (toSemigroup : S.Semigroup α)
  (ident : α)
  (ident_left : ∀ (x : α), toSemigroup.op ident x = x)
  (ident_right : ∀ (x : α), toSemigroup.op x ident = x) :
  C1.Monoid α
```

Similarly, because neither `S.Magma` nor `C2.Magma` inherits from another structure or class, their constructors are identical:

```proofscript
S.Magma.mk.{u} {α : Type u} (op : α → α → α) : S.Magma α
```

```proofscript
C2.Magma.mk.{u} {α : Type u} (op : α → α → α) : C2.Magma α
```

`S.Semigroup.mk`, however, takes its parent as an ordinary parameter, while `C2.Semigroup.mk` takes its parent as an instance implicit parameter:

```proofscript
S.Semigroup.mk.{u} {α : Type u}
  (toMagma : S.Magma α)
  (op_assoc : ∀ (x y z : α),
    toMagma.op (toMagma.op x y) z = toMagma.op x (toMagma.op y z)) :
  S.Semigroup α
```

```proofscript
C2.Semigroup.mk.{u} {α : Type u} [toMagma : C2.Magma α]
  (op_assoc : ∀ (x y z : α),
    toMagma.op (toMagma.op x y) z = toMagma.op x (toMagma.op y z)) :
  C2.Semigroup α
```

Finally, `C2.Monoid.mk` takes its semigroup parent as an instance implicit parameter. The references to `op` become references to the method `C2.Magma.op`, relying on instance synthesis to recover the implementation from the `C2.Semigroup` instance-implicit parameter via its parent projection:

```proofscript
C2.Monoid.mk.{u} {α : Type u}
  [toSemigroup : C2.Semigroup α]
  (ident : α)
  (ident_left : ∀ (x : α), C2.Magma.op ident x = x)
  (ident_right : ∀ (x : α), C2.Magma.op x ident = x) :
  C2.Monoid α
```

Parameters to type classes may be marked with 
<a id="--tech-term-gadgets"></a>
*gadgets*, which are special versions of the identity function that cause the elaborator to treat a value differently. Gadgets never change the *meaning* of a term, but they may cause it to be treated differently in elaboration-time search procedures. The gadgets `outParam` and `semiOutParam` affect [instance synthesis](../Instance-Synthesis/index.md#instance-synth), so they are documented in that section.

Whether a type is a class or not has no effect on definitional equality. Two instances of the same class with the same parameters are not necessarily identical and may in fact be very different.

<a id="Instances-are-Not-Unique"></a>
Instances are Not Unique 

This implementation of binary heap insertion is buggy:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Heap-_LPAR_in-Instances-are-Not-Unique_RPAR_"></a>
<a id="Heap___contents-_LPAR_in-Instances-are-Not-Unique_RPAR_"></a>
<a id="Heap___bubbleUp-_LPAR_in-Instances-are-Not-Unique_RPAR_"></a>
<a id="Heap___insert-_LPAR_in-Instances-are-Not-Unique_RPAR_"></a>


```proofscript
structure Heap (α : Type u) where
  contents : Array α
deriving Repr

function Heap.bubbleUp [Ord α] (i : Nat) (xs : Heap α) : Heap α :=
  if h : i = 0 then xs
  else if h : i ≥ xs.contents.size then xs
  else
    let j := i / 2
    if Ord.compare xs.contents[i] xs.contents[j] == .lt then
      Heap.bubbleUp j { xs with contents := xs.contents.swap i j }
    else xs

function Heap.insert [Ord α] (x : α) (xs : Heap α) : Heap α :=
  let i := xs.contents.size
  {xs with contents := xs.contents.push x}.bubbleUp i
```

The problem is that a heap constructed with one `Ord` instance may later be used with another, leading to the breaking of the heap invariant.

One way to correct this is to make the heap type depend on the selected `Ord` instance:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Heap___-_LPAR_in-Instances-are-Not-Unique_RPAR_"></a>
<a id="Heap______contents-_LPAR_in-Instances-are-Not-Unique_RPAR_"></a>
<a id="Heap______bubbleUp-_LPAR_in-Instances-are-Not-Unique_RPAR_"></a>
<a id="Heap______insert-_LPAR_in-Instances-are-Not-Unique_RPAR_"></a>


```proofscript
structure Heap' (α : Type u) [Ord α] where
  contents : Array α

function Heap'.bubbleUp [inst : Ord α]
    (i : Nat) (xs : @Heap' α inst) :
    @Heap' α inst :=
  if h : i = 0 then xs
  else if h : i ≥ xs.contents.size then xs
  else
    let j := i / 2
    if inst.compare xs.contents[i] xs.contents[j] == .lt then
      Heap'.bubbleUp j {xs with contents := xs.contents.swap i j}
    else xs

function Heap'.insert [Ord α] (x : α) (xs : Heap' α) : Heap' α :=
  let i := xs.contents.size
  {xs with contents := xs.contents.push x}.bubbleUp i
```

In the improved definitions, `Heap'.bubbleUp` is needlessly explicit; the instance does not need to be explicitly named here because Lean would select the indicated instances nonetheless, but it does bring the correctness invariant front and center for readers.

<a id="class-inductive"></a>
### 10.1.1. Sum Types as Classes

Most type classes follow the paradigm of a set of overloaded methods from which clients may choose freely. This is naturally modeled by a product type, from which the overloaded methods are projections. Some classes, however, are sum types: they require that the recipient of the synthesized instance first check *which* of the available instance constructors was provided. To account for these classes, a class declaration may consist of an arbitrary [inductive type](../../The-Type-System/Inductive-Types/index.md#--tech-term-Inductive-types), not just an extended form of structure declaration.

<a id="Lean___Parser___Command___declaration-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Class Inductive Type Declarations**

<a id="Lean___Parser___Command___declaration-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
command ::= ...
    | declModifiers
      class inductive declId optDeclSig where
        (| declModifiers ident optDeclSig)*
      (deriving ident,*)?
```

Class inductive types are just like other inductive types, except they may participate in instance synthesis. The paradigmatic example of a class inductive is `Decidable`: synthesizing an instance in a context with free variables amounts to synthesizing the decision procedure, but if there are no free variables, then the truth of the proposition can be established by instance synthesis alone (as is done by the `decide` tactic).

<a id="class-abbrev"></a>
### 10.1.2. Class Abbreviations

In some cases, many related type classes may co-occur throughout a codebase. Rather than writing all the names repeatedly, it would be possible to define a class that extends all the classes in question, contributing no new methods itself. However, this new class has a disadvantage: its instances must be declared explicitly.

The `class abbrev` command allows the creation of 
<a id="--tech-term-class-abbreviations"></a>
*class abbreviations* in which one name is short for a number of other class parameters. Behind the scenes, a class abbreviation is represented by a class that extends all the others. Its constructor is additionally declared to be an instance so the new class can be constructed by instance synthesis alone.

<a id="Class-Abbreviations"></a>
Class Abbreviations 

Both `plusTimes1` and `plusTimes2` require that their parameters' type have `Add` and `Mul` instances:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="AddMul-_LPAR_in-Class-Abbreviations_RPAR_"></a>
<a id="plusTimes1-_LPAR_in-Class-Abbreviations_RPAR_"></a>
<a id="AddMul___-_LPAR_in-Class-Abbreviations_RPAR_"></a>
<a id="plusTimes2-_LPAR_in-Class-Abbreviations_RPAR_"></a>


```proofscript
class abbrev AddMul (α : Type u) := Add α, Mul α

function plusTimes1 [AddMul α] (x y z : α) := x + y * z

class AddMul' (α : Type u) extends Add α, Mul α

function plusTimes2 [AddMul' α] (x y z : α) := x + y * z
```

Because `AddMul` is a `class abbrev`, no additional declarations are necessary to use `plusTimes1` with `Nat`:

```proofscript
#eval plusTimes1 2 5 7
```

```lean
37
```

However, `plusTimes2` fails, because there is no `AddMul' Nat` instance—no instances whatsoever have yet been declared:

```proofscript
#eval plusTimes2 2 5 7
```

```lean
failed to synthesize instance of type class
  AddMul' ?m.8

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

Declaring a very general instance takes care of the problem for `Nat` and every other type:

```proofscript
instance [Add α] [Mul α] : AddMul' α where

#eval plusTimes2 2 5 7
```

```lean
37
```

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`declModifiers` is the collection of modifiers on a declaration:
* a doc comment `/-- ... -/`
* a list of attributes `@[attr1, attr2]`
* a visibility specifier, `private` or `public`
* `protected`
* `noncomputable`
* `unsafe`
* `partial` or `nonrec`

All modifiers are optional, and have to come in the listed order.

`nestedDeclModifiers` is the same as `declModifiers`, but attributes are printed
on the same line as the declaration. It is used for declarations nested inside other syntax,
such as inductive constructors, structure projections, and `let rec` / `where` definitions.
```


### Display 2


```text
`declId` matches `foo` or `foo.{u,v}`: an identifier possibly followed by a list of universe names
```


### Display 3


```text
`optDeclSig` matches the signature of a declaration with optional type: a list of binders and then possibly `: type`
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
invalid binder annotation, type is not a class instance
  Nat

Note: Use the command `set_option checkBinderAnnotations false` to disable the check
```


### Display 2


```text
37
```


### Display 3


```text
failed to synthesize instance of type class
  AddMul' ?m.8

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

