<a id="The-Lean-Language-Reference--Basic-Propositions--Quantifiers"></a>

# ProofScript — 19.3. Quantifiers

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Truth and falsity, conjunction/disjunction, implication, negation, universal/existential quantification and equality keep their native definitions. An existential proof contains logical witness evidence, but elimination restrictions determine when it can construct runtime data. Equality transports dependent values only through justified terms. Computed Boolean comparison does not automatically produce equality evidence.

**Compiler and coverage boundary.** Preserve Prop elimination, proof irrelevance and universe rules. Erasure may remove irrelevant proofs but not the data they certify.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Basic-Propositions/Quantifiers/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Basic-Propositions/Quantifiers/index.html). Source Git blob: `412adffb5f57e236f32bb6c9f823f704ac92cbe1`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 19.3. Quantifiers

Just as implication is implemented as ordinary function types in `Prop`, universal quantification is implemented as dependent function types in `Prop`. Because `Prop` is [impredicative](../../The-Type-System/Universes/index.md#--tech-term-impredicative), any function type in which the [codomain](../../The-Type-System/Functions/index.md#--tech-term-codomain) is a `Prop` is itself a `Prop`, even if the [domain](../../The-Type-System/Functions/index.md#--tech-term-domain) is a `Type`. The typing rules for dependent functions precisely match the introduction and elimination rules for universal quantification: if a predicate holds for any arbitrarily chosen element of a type, then it holds universally. If a predicate holds universally, then it can be instantiated to a proof for any individual.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Universal Quantification**

<a id="Lean___Parser___Term___forall"></a>

```ebnf
term ::= ...
    | ∀ ident ident* (: term)?, term
```

<a id="Lean___Parser___Term___forall-next"></a>

```ebnf
term ::= ...
    | forall ident ident* (: term)?, term
```

<a id="Lean___Parser___Term___forall-next-next"></a>

```ebnf
term ::= ...
    | ∀ (ident | hole | bracketedBinder) (ident | hole | bracketedBinder)*, term
```

<a id="Lean___Parser___Term___forall-next-next-next"></a>

```ebnf
term ::= ...
    | forall (ident | hole | bracketedBinder) (ident | hole | bracketedBinder)*, term
```

Universal quantifiers bind one or more variables, which are then in scope in the final term. The identifiers may also be `_`. With parenthesized type annotations, multiple bound variables may have different types, while the unparenthesized variant requires that all have the same type.

Even though universal quantifiers are represented by functions, their proofs should not be thought of as computations. Because of proof irrelevance and the elimination restriction for propositions, there's no way to actually compute data using these proofs. As a result, they are free to use reasoning principles that are not readily computed, such as the classical Axiom of Choice.

Existential quantification is implemented as a structure that is similar to `Subtype` and `Sigma`: it contains a 
<a id="--tech-term-witness"></a>
*witness*, which is a value that satisfies the predicate, along with a proof that the witness does in fact satisfy the predicate. In other words, it is a form of dependent pair type. Unlike both `Subtype` and `Sigma`, it is a [proposition](../../The-Type-System/Propositions/index.md#--tech-term-Propositions); this means that programs cannot in general use a proof of an existential statement to obtain a value that satisfies the predicate.

When writing a proof, the `exists` tactic allows one (or more) witness(es) to be specified for a (potentially nested) existential statement. The `constructor` tactic, on the other hand, creates a [metavariable](../../Tactic-Proofs/Reading-Proof-States/index.md#--tech-term-metavariables) for the witness; providing a proof of the predicate may solve the metavariable as well. The components of an existential assumption can be made available individually by pattern matching with `let` or `match`, as well as by using `cases` or `rcases`.

<a id="Proving-Existential-Statements"></a>
Proving Existential Statements 

When proving that there exists some natural number that is the sum of four and five, the `exists` tactic expects the sum to be provided, constructing the equality proof using `trivial`:
<a id="ex_four_plus_five-_LPAR_in-Proving-Existential-Statements_RPAR_"></a>


```proofscript
theorem ex_four_plus_five : ∃ n, 4 + 5 = n := by
  exists 9
```

The `constructor` tactic, on the other hand, expects a proof. The `rfl` tactic causes the sum to be determined as a side effect of checking definitional equality.
<a id="ex_four_plus_five___-_LPAR_in-Proving-Existential-Statements_RPAR_"></a>


```proofscript
theorem ex_four_plus_five' : ∃ n, 4 + 5 = n := by
  constructor
  rfl
```

<a id="Exists___intro"></a>

**inductive predicate**

```text
Exists.{u} {α : Sort u} (p : α → Prop) : Prop
```

Existential quantification. If `p : α → Prop` is a predicate, then `∃ x : α, p x` asserts that there is some `x` of type `α` such that `p x` holds. To create an existential proof, use the `exists` tactic, or the anonymous constructor notation `⟨x, h⟩`. To unpack an existential, use `cases h` where `h` is a proof of `∃ x : α, p x`, or `let ⟨x, hx⟩ := h`.

Because Lean has proof irrelevance, any two proofs of an existential are definitionally equal. One consequence of this is that it is impossible to recover the witness of an existential from the mere fact of its existence. For example, the following does not compile:

```text
example (h : ∃ x : Nat, x = x) : Nat :=
  let ⟨x, _⟩ := h  -- fail, because the goal is `Nat : Type`
  x
```

The error message `recursor 'Exists.casesOn' can only eliminate into Prop` means that this only works when the current goal is another proposition:

```proofscript
example (h : ∃ x : Nat, x = x) : True :=
  let ⟨x, _⟩ := h  -- ok, because the goal is `True : Prop`
  trivial
```

**Constructors**

```text
Exists.intro.{u} {α : Sort u} {p : α → Prop} (w : α)
  (h : p w) : Exists p
```

Existential introduction. If `a : α` and `h : p a`, then `⟨a, h⟩` is a proof that `∃ x : α, p x`.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Existential Quantification**

<a id="_FLQQ_term_________FLQQ_"></a>

```ebnf
term ::= ...
    | ∃ ident ident* (: term)?, term
```

<a id="_FLQQ_termExists______FLQQ_"></a>

```ebnf
term ::= ...
    | exists ident ident* (: term)?, term
```

<a id="_FLQQ_term_________FLQQ_-next"></a>

```ebnf
term ::= ...
    | ∃ bracketedExplicitBinders bracketedExplicitBinders*, term
```

<a id="_FLQQ_termExists______FLQQ_-next"></a>

```ebnf
term ::= ...
    | exists bracketedExplicitBinders bracketedExplicitBinders*, term
```

Existential quantifiers bind one or more variables, which are then in scope in the final term. The identifiers may also be `_`. With parenthesized type annotations, multiple bound variables may have different types, while the unparenthesized variant requires that all have the same type. If more than one variable is bound, then the result is multiple instances of `Exists`, nested to the right.

<a id="Exists___choose"></a>

**def**

```text
Exists.choose.{u_1} {α : Sort u_1} {p : α → Prop} (P : ∃ a, p a) : α
```

Extract an element from an existential statement, using `Classical.choose`.

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


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


### Display 2


```text
`binderIdent` matches an `ident` or a `_`. It is used for identifiers in binding
position, where `_` means that the value should be left unnamed and inaccessible.
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
⊢ ∃ n, 4 + 5 = n
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
h⊢ 4 + 5 = ?ww⊢ Nat
```

