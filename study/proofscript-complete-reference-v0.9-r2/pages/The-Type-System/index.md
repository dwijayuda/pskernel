<a id="type-system"></a>

# ProofScript — 4. The Type System

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Functions, propositions, universes, inductives and quotients retain their Lean meaning. A proof is an inhabitant of a proposition; Boolean truth is not the same object. Parameters may determine later parameter types. Universe levels cannot be approximated as machine integer ranks. Inductive constructors require the native positivity, universe, parameter and index checks. Quotient eliminators must respect their relation, rather than use runtime object identity.

## ProofScript way of writing it


```proofscript
universe u

function identity {α: Type u}(x: α): α := x

function retain(n: Nat, i: Fin n): Fin n := i

theorem keepProof {P: Prop}(h: P): P := by
  exact h
```

**Compiler and coverage boundary.** Use exact declared core rules and axiom policies. Library names and hash matches alone cannot authorize primitive reductions. Soundness and exact acceptance equivalence are distinct obligations.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The-Type-System/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The-Type-System/index.html). Source Git blob: `6637c7e60db0f41c0ab3e1afc4c11f157935c5e5`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 4. The Type System

<a id="--tech-term-Terms"></a>
*Terms*, also known as 
<a id="--tech-term-expressions"></a>
*expressions*, are the fundamental units of meaning in Lean's core language. They are produced from user-written syntax by the [elaborator](../Terms/index.md#--tech-term-elaborator). Lean's type system relates terms to their *types*, which are also themselves terms. Types can be thought of as denoting sets, while terms denote individual elements of these sets. A term is 
<a id="--tech-term-well-typed"></a>
*well-typed* if it has a type under the rules of Lean's type theory. Only well-typed terms have a meaning.

Terms are a dependently typed λ-calculus: they include function abstraction, application, variables, and `let`-bindings. In addition to bound variables, variables in the term language may refer to [constructors](Inductive-Types/index.md#--tech-term-constructors), [type constructors](Inductive-Types/index.md#--tech-term-type-constructors), [recursors](Inductive-Types/index.md#--tech-term-recursor), 
<a id="--tech-term-defined-constants"></a>
defined constants, or opaque constants. Constructors, type constructors, recursors, and opaque constants are not subject to substitution, while defined constants may be replaced with their definitions.

A 
<a id="--tech-term-derivation"></a>
*derivation* demonstrates the well-typedness of a term by explicitly indicating the precise inference rules that are used. Implicitly, well-typed terms can stand in for the derivations that demonstrate their well-typedness. Lean's type theory is explicit enough that derivations can be reconstructed from well-typed terms, which greatly reduces the overhead that would be incurred from storing a complete derivation, while still being expressive enough to represent modern research mathematics. This means that proof terms are sufficient evidence of the truth of a theorem and are amenable to independent verification.

In addition to having types, terms are also related by 
<a id="--tech-term-definitional-equality"></a>
*definitional equality*. This is the mechanically-checkable relation that syntactically equates terms modulo their computational behavior. Definitional equality includes the following forms of 
<a id="--tech-term-reduction"></a>
reduction:

<a id="--tech-term-___"></a>
β (beta)

Applying a function abstraction to an argument by substitution for the bound variable

<a id="--tech-term-___-next"></a>
δ (delta)

Replacing occurrences of [defined constants](index.md#--tech-term-defined-constants) by the definition's value

<a id="--tech-term-___-next-next"></a>
ι (iota)

Reduction of recursors whose targets are constructors (primitive recursion)

<a id="--tech-term-___-next-next-next"></a>
ζ (zeta)

Replacement of let-bound variables by their defined values

  Quotient reduction

[Reduction of the quotient type's function lifting operator](Quotients/index.md#quotient-model) when applied to an element of a quotient

Terms in which all possible reductions have been carried out are in 
<a id="--tech-term-normal-form"></a>
*normal form*.

Definitional equality includes 
<a id="--tech-term-___-equivalence"></a>
η-equivalence of functions and single-constructor inductive types. That is, `fun x => f x` is definitionally equal to `f`, and `S.mk x.f1 x.f2` is definitionally equal to `x`, if `S` is a structure with fields `f1` and `f2`. It also features 
<a id="--tech-term-proof-irrelevance"></a>
*proof irrelevance*: any two proofs of the same proposition are definitionally equal. It is reflexive and symmetric, but not transitive.

Definitional equality is used by conversion: if two terms are definitionally equal, and a given term has one of them as its type, then it also has the other as its type. Because definitional equality includes reduction, types can result from computations over data.

<a id="Computing-types"></a>
Computing types 

When passed a natural number, the function `LengthList` computes a type that corresponds to a list with precisely that many entries in it:
<a id="LengthList-_LPAR_in-Computing-types_RPAR_"></a>


```proofscript
def LengthList (α : Type u) : Nat → Type u
  | 0 => PUnit
  | n + 1 => α × LengthList α n
```

Because Lean's tuples nest to the right, multiple nested parentheses are not needed:

```proofscript
example : LengthList Int 0 := ()

example : LengthList String 2 :=
  ("Hello", "there", ())
```

If the length does not match the number of entries, then the computed type will not match the term:

```proofscript
example : LengthList String 5 :=
  ("Wrong", "number", ())
```

```lean
Application type mismatch: The argument
  ()
has type
  Unit
but is expected to have type
  LengthList String 3
in the application
  ("number", ())
```

The basic types in Lean are [universes](Universes/index.md#--tech-term-universes), [function](Functions/index.md#--tech-term-Functions) types, the quotient former `Quot`, and [type constructors](Inductive-Types/index.md#--tech-term-type-constructors) of [inductive types](Inductive-Types/index.md#--tech-term-Inductive-types). [Defined constants](index.md#--tech-term-defined-constants), applications of [recursors](Inductive-Types/index.md#--tech-term-recursor), function application, [axioms](../Axioms/index.md#--tech-term-Axioms) or [opaque constants](../Definitions/Definitions/index.md#--tech-term-Opaque-constants) may additionally give types, just as they can give rise to terms in any other type.

1. [4.1. Functions](Functions/index.md#functions)
2. [4.2. Propositions](Propositions/index.md#propositions)
3. [4.3. Universes](Universes/index.md#The-Lean-Language-Reference--The-Type-System--Universes)
4. [4.4. Inductive Types](Inductive-Types/index.md#inductive-types)
5. [4.5. Quotients](Quotients/index.md#quotients)

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Application type mismatch: The argument
  ()
has type
  Unit
but is expected to have type
  LengthList String 3
in the application
  ("number", ())
```

