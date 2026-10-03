<a id="type-classes"></a>

# ProofScript — 10. Type Classes

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Classes are native type-directed interfaces, not JavaScript classes. Instances provide dictionaries and associated evidence. Inference uses the pinned priority and search behavior, so importing an instance can affect elaboration. Derived instances are generated declarations that must be checked. Boolean equality and hashing require laws when used for logical claims.

## ProofScript way of writing it


```proofscript
class Sized(α: Type) where {
  size: α -> Nat
}

instance : Sized String where {
  size(s: String): Nat := s.length
}
```

**Compiler and coverage boundary.** Braced class fields use native field-declaration layout. Instance initializers use their own native sequence grammar, including semicolons only where that grammar permits them.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Type-Classes/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Type-Classes/index.html). Source Git blob: `a12bec839654d8a01fe2f85f5be487e5a5437951`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 10. Type Classes

An operation is *polymorphic* if it can be used with multiple types. In Lean, polymorphism comes in three varieties:

1. [universe polymorphism](../The-Type-System/Universes/index.md#--tech-term-universe-polymorphism), where the sorts in a definition can be instantiated in various ways,
2. functions that take types as (potentially implicit) parameters, allowing a single body of code to work with any type, and
3. <a id="--tech-term-ad-hoc-polymorphism"></a>
  *ad-hoc polymorphism*, implemented with type classes, in which operations to be overloaded may have different implementations for different types.

Because Lean does not allow case analysis of types, polymorphic functions implement operations that are uniform for any choice of type argument; for example, `List.map` does not suddenly compute differently depending on whether the input list contains `String`s or `Nat`s. Ad-hoc polymorphic operations are useful when there is no “uniform” way to implement an operation; the canonical use case is for overloading arithmetic operators so that they work with `Nat`, `Int`, `Float`, and any other type that has a sensible notion of addition. Ad-hoc polymorphism may also involve multiple types; looking up a value at a given index in a collection involves the collection type, the index type, and the type of member elements to be extracted. A 
<a id="--tech-term-type-class"></a>
*type class*Type classes were first described in Philip Wadler and Stephen Blott, 1989. “How to make ad-hoc polymorphism less ad hoc”. In *Proceedings of the 16th Symposium on Principles of Programming Languages.* describes a collection of overloaded operations (called 
<a id="--tech-term-methods"></a>
*methods*) together with the involved types.

Type classes are very flexible. Overloading may involve multiple types; operations like indexing into a data structure can be overloaded for a specific choice of data structure, index type, element type, and even a predicate that asserts the presence of the key in the structure. Due to Lean's expressive type system, overloading operations is not restricted only to types; type classes may be parameterized by ordinary values, by families of types, and even by predicates or propositions. All of these possibilities are used in practice:

  Natural number literals

The `OfNat` type class is used to interpret natural number literals. Instances may depend not only on the type being instantiated, but also on the number literal itself.

  Computational effects

Type classes such as `Monad`, whose parameter is a function from one type to another, are used to provide [special syntax for programs with side effects.](../Functors___-Monads-and--do--Notation/index.md#monads-and-do) The “type” for which operations are overloaded is actually a type-level function, such as `Option`, `IO`, or `Except`.

  Predicates and propositions

The `Decidable` type class allows a decision procedure for a proposition to be found automatically by Lean. This is used as the basis for [`if`](../Terms/Conditionals/index.md#termIfThenElse)-expressions, which may branch on any decidable proposition.

While ordinary polymorphic definitions simply expect instantiation with arbitrary parameters, the operators overloaded with type classes are to be instantiated with 
<a id="--tech-term-instances"></a>
*instances* that define the overloaded operation for some specific set of parameters. These 
<a id="--tech-term-instance-implicit"></a>
instance-implicit parameters are indicated in square brackets. At invocation sites, Lean either 
<a id="--tech-term-synthesizes"></a>
*synthesizes* 
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
 a suitable instance from the available candidates or signals an error. Because instances may themselves have instance parameters, this search process may be recursive and result in a final composite instance value that combines code from a variety of instances. Thus, type class instance synthesis is also a means of constructing programs in a type-directed manner.

Here are some typical use cases for type classes:

- Type classes may represent overloaded operators, such as arithmetic that can be used with a variety of types of numbers or a membership predicate that can be used for a variety of data structures. There is often a single canonical choice of operator for a given type—after all, there is no sensible alternative definition of addition for `Nat`—but this is not an essential property, and libraries may provide alternative instances if needed.
- Type classes can represent an algebraic structure, providing both the extra structure and the axioms required by the structure. For example, a type class that represents an Abelian group may contain methods for a binary operator, a unary inverse operator, an identity element, as well as proofs that the binary operator is associative and commutative, that the identity is an identity, and that the inverse operator yields the identity element on both sides of the operator. Here, there may not be a canonical choice of structure, and a library may provide many ways to instantiate a given set of axioms; there are two equally canonical monoid structures over the integers.
- A type class can represent a relation between two types that allows them to be used together in some novel way by a library. The `Coe` class represents automatically-inserted coercions from one type to another, and `MonadLift` represents a way to run operations with one kind of effect in a context that expects another kind.
- Type classes can represent a framework of type-driven code generation, where instances for polymorphic types each contribute some portion of a final program. The `Repr` class defines a canonical pretty printer for a type, and polymorphic types end up with polymorphic `Repr` instances. When pretty printing is finally invoked on an expression with a known concrete type, such as `List (Nat × (String ⊕ Int))`, the resulting pretty printer contains code assembled from the `Repr` instances for `List`, `Prod`, `Nat`, `Sum`, `String`, and `Int`.

1. [10.1. Class Declarations](Class-Declarations/index.md#class)
2. [10.2. Instance Declarations](Instance-Declarations/index.md#instance-declarations)
3. [10.3. Instance Synthesis](Instance-Synthesis/index.md#instance-synth)
4. [10.4. Deriving Instances](Deriving-Instances/index.md#deriving-instances)
5. [10.5. Basic Classes](Basic-Classes/index.md#basic-classes)
