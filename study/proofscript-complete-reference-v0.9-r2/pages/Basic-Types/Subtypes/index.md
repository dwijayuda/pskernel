<a id="Subtype"></a>

# ProofScript — 20.20. Subtypes

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Nat, Int, machine integers, floats, characters, strings, bytes, options, products, sums, lists, arrays, maps, ranges, subtypes and lazy computations retain their distinct native contracts. A target representation is not their meaning. Nat subtraction saturates at zero; the selected Int quotient differs from JavaScript BigInt truncation for some negative inputs. String offsets and Unicode conversions require explicit mappings.

**Compiler and coverage boundary.** The full API entries below retain exact names and signature metadata. Distinguish a signature display from executable source. Unknown reachable primitives reject the requested executable profile.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Basic-Types/Subtypes/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Basic-Types/Subtypes/index.html). Source Git blob: `27ebb5f8b36ace6d86fa1b0a3ec10c00ae5bf7bc`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 20.20. Subtypes

The structure `Subtype` represents the elements of a type that satisfy some predicate. They are used pervasively both in mathematics and in programming; in mathematics, they are used similarly to subsets, while in programming, they allow information that is known about a value to be represented in a way that is visible to Lean's logic.

Syntactically, an element of a `Subtype` resembles a tuple of the base type's element and the proof that it satisfies the proposition. They differ from dependent pair types (`Sigma`) in that the second element is a proof of a proposition rather than data, and from existential quantification in that the entire `Subtype` is a type rather than a proposition. Even though they are pairs syntactically, `Subtype` should really be thought of as elements of the base type with associated proof obligations.

Subtypes are [trivial wrappers](../../The-Type-System/Inductive-Types/index.md#inductive-types-trivial-wrappers). They are thus represented identically to the base type in compiled code.

<a id="Subtype___mk"></a>

**structure**

```text
Subtype.{u} {α : Sort u} (p : α → Prop) : Sort (max 1 u)
```

All the elements of a type that satisfy a predicate.

`Subtype p`, usually written `{ x : α // p x }` or `{ x // p x }`, contains all elements `x : α` for which `p x` is true. Its constructor is a pair of the value and the proof that it satisfies the predicate. In run-time code, `{ x : α // p x }` is represented identically to `α`.

There is a coercion from `{ x : α // p x }` to `α`, so elements of a subtype may be used where the underlying type is expected.

Examples:

- `{ n : Nat // n % 2 = 0 }` is the type of even numbers.
- `{ xs : Array String // xs.size = 5 }` is the type of arrays with five `String`s.
- Given `xs : List α`, `List { x : α // x ∈ xs }` is the type of lists in which all elements are contained in `xs`.

Conventions for notations in identifiers:

- The recommended spelling of `{ x // p x }` in identifiers is `subtype`.

**Constructor**

```text
Subtype.mk.{u}
```

**Fields**

```text
val : α
```

The value in the underlying type that satisfies the predicate.

```text
property : p self.val
```

The proof that `val` satisfies the predicate `p`.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Subtypes**

<a id="_FLQQ_term___________________FLQQ_"></a>

```ebnf
term ::= ...
    | { ident : term // term }
```

`{ x : α // p }` is a notation for `Subtype fun (x : α) => p`.

The type ascription may be omitted:

<a id="_FLQQ_term___________________FLQQ_-next"></a>

```ebnf
term ::= ...
    | { ident // term }
```

`{ x // p }` is a notation for `Subtype fun (x : _) => p`.

Due to [proof irrelevance](../../The-Type-System/index.md#--tech-term-proof-irrelevance) and [η-equality](../../The-Type-System/index.md#--tech-term-___-equivalence), two elements of a subtype are definitionally equal when the elements of the base type are definitionally equal. In a proof, the `ext` tactic can be used to transform a goal of equality of elements of a subtype into equality of their values.

<a id="Definitional-Equality-of-Subtypes"></a>
Definitional Equality of Subtypes 

The non-empty strings `s1` and `s2` are definitionally equal despite the fact that their embedded proof terms are different. No case splitting is needed in order to prove that they are equal.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="NonEmptyString-_LPAR_in-Definitional-Equality-of-Subtypes_RPAR_"></a>
<a id="s1-_LPAR_in-Definitional-Equality-of-Subtypes_RPAR_"></a>
<a id="s2-_LPAR_in-Definitional-Equality-of-Subtypes_RPAR_"></a>
<a id="s1_eq_s2-_LPAR_in-Definitional-Equality-of-Subtypes_RPAR_"></a>


```proofscript
const NonEmptyString := { x : String // x ≠ "" }

const s1 : NonEmptyString :=
  ⟨"equal", ne_of_beq_false rfl⟩

def s2 : NonEmptyString where
  val := "equal"
  property :=
    fun h =>
      List.cons_ne_nil _ _ (String.ext_iff.mp h)

theorem s1_eq_s2 : s1 = s2 := by rfl
```

<a id="Extensional-Equality-of-Subtypes"></a>
Extensional Equality of Subtypes 

The non-empty strings `s1` and `s2` are definitionally equal. Ignoring that fact, the equality of the embedded strings can be used to prove that they are equal. The `ext` tactic transforms a goal that consists of equality of non-empty strings into a goal that consists of equality of the strings.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="NonEmptyString-_LPAR_in-Extensional-Equality-of-Subtypes_RPAR_"></a>
<a id="s1-_LPAR_in-Extensional-Equality-of-Subtypes_RPAR_"></a>
<a id="s2-_LPAR_in-Extensional-Equality-of-Subtypes_RPAR_"></a>
<a id="s1_eq_s2-_LPAR_in-Extensional-Equality-of-Subtypes_RPAR_"></a>


```proofscript
abbrev NonEmptyString := { x : String // x ≠ "" }

const s1 : NonEmptyString :=
  ⟨"equal", ne_of_beq_false rfl⟩

def s2 : NonEmptyString where
  val := "equal"
  property :=
    fun h =>
      List.cons_ne_nil _ _ (String.ext_iff.mp h)

theorem s1_eq_s2 : s1 = s2 := by
  ext
  dsimp only [s1, s2]
  rfl
```

There is a coercion from a subtype to its base type. This allows subtypes to be used in positions where the base type is expected, essentially erasing the proof that the value satisfies the predicate.

<a id="Subtype-Coercions"></a>
Subtype Coercions 

Elements of subtypes can be coerced to their base type. Here, `nine` is coerced from a subtype of `Nat` that contains multiples of `3` to `Nat`.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="DivBy3-_LPAR_in-Subtype-Coercions_RPAR_"></a>
<a id="nine-_LPAR_in-Subtype-Coercions_RPAR_"></a>


```proofscript
abbrev DivBy3 := { x : Nat // x % 3 = 0 }

const nine : DivBy3 := ⟨9, by rfl⟩

set_option eval.type true in
#eval Nat.succ nine
```

```lean
10 : Nat
```

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
All the elements of a type that satisfy a predicate.

`Subtype p`, usually written `{ x : α // p x }` or `{ x // p x }`, contains all elements `x : α` for
which `p x` is true. Its constructor is a pair of the value and the proof that it satisfies the
predicate. In run-time code, `{ x : α // p x }` is represented identically to `α`.

There is a coercion from `{ x : α // p x }` to `α`, so elements of a subtype may be used where the
underlying type is expected.

Examples:
 * `{ n : Nat // n % 2 = 0 }` is the type of even numbers.
 * `{ xs : Array String // xs.size = 5 }` is the type of arrays with five `String`s.
 * Given `xs : List α`, `List { x : α // x ∈ xs }` is the type of lists in which all elements are
   contained in `xs`.


Conventions for notations in identifiers:

 * The recommended spelling of `{ x // p x }` in identifiers is `subtype`.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
10 : Nat
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
⊢ s1 = s2
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
i✝:Nata✝:Char⊢ s1.val.toList[i✝]? = some a✝ ↔ s2.val.toList[i✝]? = some a✝
```


### Display 4


```text
i✝:Nata✝:Char⊢ "equal".toList[i✝]? = some a✝ ↔ "equal".toList[i✝]? = some a✝
```


### Display 5


```text
⊢ 9 % 3 = 0
```

