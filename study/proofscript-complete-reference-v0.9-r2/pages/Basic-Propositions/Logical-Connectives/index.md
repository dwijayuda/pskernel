<a id="The-Lean-Language-Reference--Basic-Propositions--Logical-Connectives"></a>

# ProofScript — 19.2. Logical Connectives

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Truth and falsity, conjunction/disjunction, implication, negation, universal/existential quantification and equality keep their native definitions. An existential proof contains logical witness evidence, but elimination restrictions determine when it can construct runtime data. Equality transports dependent values only through justified terms. Computed Boolean comparison does not automatically produce equality evidence.

**Compiler and coverage boundary.** Preserve Prop elimination, proof irrelevance and universe rules. Erasure may remove irrelevant proofs but not the data they certify.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Basic-Propositions/Logical-Connectives/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Basic-Propositions/Logical-Connectives/index.html). Source Git blob: `ea6e0ad22ede4fa664857ec0df9ea2e99e0632fa`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next"></a>

---

## 19.2. Logical Connectives

Conjunction is implemented as the inductively defined proposition `And`. The constructor `And.intro` represents the introduction rule for conjunction: to prove a conjunction, it suffices to prove both conjuncts. Similarly, `And.elim` represents the elimination rule: given a proof of a conjunction and a proof of some other statement that assumes both conjuncts, the other statement can be proven. Because `And` is a [subsingleton](../../The-Type-System/Inductive-Types/index.md#--tech-term-subsingleton), `And.elim` can also be used as part of computing data. However, it should not be confused with `PProd`: using non-computable reasoning principles such as the Axiom of Choice to define data (including `Prod`) causes Lean to be unable to compile and run the resulting program, while using them in a proof of a proposition causes no such issue.

In a [tactic](../../Tactic-Proofs/index.md#tactics) proof, conjunctions can be proved using `And.intro` explicitly via `apply`, but `constructor` is more common. When multiple conjunctions are nested in a proof goal, `and_intros` can be used to apply `And.intro` in each relevant location. Assumptions of conjunctions in the context can be simplified using `cases`, pattern matching with `let` or `match`, or `rcases`.

<a id="And___intro"></a>

**structure**

```text
And (a b : Prop) : Prop
```

`And a b`, or `a ∧ b`, is the conjunction of propositions. It can be constructed and destructed like a pair: if `ha : a` and `hb : b` then `⟨ha, hb⟩ : a ∧ b`, and if `h : a ∧ b` then `h.left : a` and `h.right : b`.

Conventions for notations in identifiers:

- The recommended spelling of `∧` in identifiers is `and`.

**Constructor**

```text
And.intro
```

`And.intro : a → b → a ∧ b` is the constructor for the And operation.

**Fields**

```text
left : a
```

Extract the left conjunct from a conjunction. `h : a ∧ b` then `h.left`, also notated as `h.1`, is a proof of `a`.

```text
right : b
```

Extract the right conjunct from a conjunction. `h : a ∧ b` then `h.right`, also notated as `h.2`, is a proof of `b`.

<a id="And___elim"></a>

**def**

```text
And.elim.{u_1} {a b : Prop} {α : Sort u_1} (f : a → b → α) (h : a ∧ b) :
  α
```

Non-dependent eliminator for `And`.

Disjunction implemented as the inductively defined proposition `Or`. It has two constructors, one for each introduction rule: a proof of either disjunct is sufficient to prove the disjunction. While the definition of `Or` is similar to that of `Sum`, it is quite different in practice. Because `Sum` is a type, it is possible to check *which* constructor was used to create any given value. `Or`, on the other hand, forms propositions: terms that prove a disjunction cannot be interrogated to check which disjunct was true. In other words, because `Or` is not a [subsingleton](../../The-Type-System/Inductive-Types/index.md#--tech-term-subsingleton), its proofs cannot be used as part of a computation.

In a [tactic](../../Tactic-Proofs/index.md#tactics) proof, disjunctions can be proved using either constructor (`Or.inl` or `Or.inr`) explicitly via `apply`. The `left` and `right` tactics select the left and right disjuncts. Assumptions of disjunctions in the context can be simplified using `cases`, pattern matching with `match`, or `rcases`.

<a id="Or___inl"></a>

**inductive predicate**

```text
Or (a b : Prop) : Prop
```

`Or a b`, or `a ∨ b`, is the disjunction of propositions. There are two constructors for `Or`, called `Or.inl : a → a ∨ b` and `Or.inr : b → a ∨ b`, and you can use `match` or `cases` to destruct an `Or` assumption into the two cases.

Conventions for notations in identifiers:

- The recommended spelling of `∨` in identifiers is `or`.

**Constructors**

```text
Or.inl {a b : Prop} (h : a) : a ∨ b
```

`Or.inl` is "left injection" into an `Or`. If `h : a` then `Or.inl h : a ∨ b`.

```text
Or.inr {a b : Prop} (h : b) : a ∨ b
```

`Or.inr` is "right injection" into an `Or`. If `h : b` then `Or.inr h : a ∨ b`.

When either disjunct is [decidable](../../Type-Classes/Basic-Classes/index.md#--tech-term-decidable), it becomes possible to use `Or` to compute data. This is because the decision procedure's result provides a suitable branch condition.

<a id="Or___by_cases"></a>

**def**

```text
Or.by_cases.{u} {p q : Prop} [Decidable p] {α : Sort u} (h : p ∨ q)
  (h₁ : p → α) (h₂ : q → α) : α
```

Construct a non-Prop by cases on an `Or`, when the left conjunct is decidable.

<a id="Or___by_cases___"></a>

**def**

```text
Or.by_cases'.{u} {q p : Prop} [Decidable q] {α : Sort u} (h : p ∨ q)
  (h₁ : p → α) (h₂ : q → α) : α
```

Construct a non-Prop by cases on an `Or`, when the right conjunct is decidable.

Rather than encoding negation as an inductive type, `¬P` is defined to mean `P → False`. In other words, to prove a negation, it suffices to assume the negated statement and derive a contradiction. This also means that `False` can be derived immediately from a proof of a proposition and its negation, and then used to prove any proposition or inhabit any type.

<a id="Not"></a>

**def**

```text
Not (a : Prop) : Prop
```

`Not p`, or `¬p`, is the negation of `p`. It is defined to be `p → False`, so if your goal is `¬p` you can use `intro h` to turn the goal into `h : p ⊢ False`, and if you have `hn : ¬p` and `h : p` then `hn h : False` and `(hn h).elim` will prove anything. For more information: [Propositional Logic](https://lean-lang.org/theorem_proving_in_lean4/propositions_and_proofs.html#propositional-logic)

Conventions for notations in identifiers:

- The recommended spelling of `¬` in identifiers is `not`.

<a id="absurd"></a>

**def**

```text
absurd.{v} {a : Prop} {b : Sort v} (h₁ : a) (h₂ : ¬a) : b
```

Anything follows from two contradictory hypotheses. Example:

```proofscript
example (hp : p) (hnp : ¬p) : q := absurd hp hnp
```

For more information: [Propositional Logic](https://lean-lang.org/theorem_proving_in_lean4/propositions_and_proofs.html#propositional-logic)

<a id="Not___elim"></a>

**def**

```text
Not.elim.{u_1} {a : Prop} {α : Sort u_1} (H1 : ¬a) (H2 : a) : α
```

*Ex falso* for negation: from `¬a` and `a` anything follows. This is the same as `absurd` with the arguments flipped, but it is in the `Not` namespace so that projection notation can be used.

Implication is represented using [function types](../../Terms/Function-Types/index.md#function-types) in the [universe](../../The-Type-System/Universes/index.md#--tech-term-universes) of [propositions](../../The-Type-System/Propositions/index.md#--tech-term-Propositions). To prove `A → B`, it is enough to prove `B` after assuming `A`. This corresponds to the typing rule for `fun`. Similarly, the typing rule for function application corresponds to 
<a id="--tech-term-modus-ponens"></a>
*modus ponens*: given a proof of `A → B` and a proof of `A`, `B` can be proved.

<a id="Truth-Functional-Implication"></a>
Truth-Functional Implication 

The representation of implication as functions in the universe of propositions is equivalent to the traditional definition in which `A → B` is defined as `(¬A) ∨ B`. This can be proved using [propositional extensionality](../../The-Type-System/Propositions/index.md#--tech-term-Extensionality) and the law of the excluded middle:
<a id="truth_functional_imp-_LPAR_in-Truth-Functional-Implication_RPAR_"></a>


```proofscript
theorem truth_functional_imp {A B : Prop} :
    ((¬ A) ∨ B) = (A → B) := by
  apply propext
  constructor
  . rintro (h | h) a <;> trivial
  . intro h
    by_cases A
    . apply Or.inr; solve_by_elim
    . apply Or.inl; trivial
```

Logical equivalence, or “if and only if”, is represented using a structure that is equivalent to the conjunction of both directions of the implication.

<a id="Iff___intro"></a>

**structure**

```text
Iff (a b : Prop) : Prop
```

If and only if, or logical bi-implication. `a ↔ b` means that `a` implies `b` and vice versa. By `propext`, this implies that `a` and `b` are equal and hence any expression involving `a` is equivalent to the corresponding expression with `b` instead.

Conventions for notations in identifiers:

- The recommended spelling of `↔` in identifiers is `iff`.
- The recommended spelling of `<->` in identifiers is `iff` (prefer `↔` over `<->`).

**Constructor**

```text
Iff.intro
```

If `a → b` and `b → a` then `a` and `b` are equivalent.

**Fields**

```text
mp : a → b
```

Modus ponens for if and only if. If `a ↔ b` and `a`, then `b`.

```text
mpr : b → a
```

Modus ponens for if and only if, reversed. If `a ↔ b` and `b`, then `a`.

<a id="Iff___elim"></a>

**def**

```text
Iff.elim.{u_1} {a b : Prop} {α : Sort u_1} (f : (a → b) → (b → a) → α)
  (h : a ↔ b) : α
```

Non-dependent eliminator for `Iff`.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Propositional Connectives**

The logical connectives other than implication are typically referred to using dedicated syntax, rather than via their defined names:

<a id="_FLQQ_term______FLQQ_-next-next-next"></a>

```ebnf
term ::= ...
    | term ∧ term
```

<a id="_FLQQ_term______FLQQ_-next-next-next-next"></a>

```ebnf
term ::= ...
    | term ∨ term
```

<a id="_FLQQ_term_____FLQQ_"></a>

```ebnf
term ::= ...
    | ¬ term
```

<a id="_FLQQ_term______FLQQ_-next-next-next-next-next"></a>

```ebnf
term ::= ...
    | term ↔ term
```

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`And a b`, or `a ∧ b`, is the conjunction of propositions. It can be
constructed and destructed like a pair: if `ha : a` and `hb : b` then
`⟨ha, hb⟩ : a ∧ b`, and if `h : a ∧ b` then `h.left : a` and `h.right : b`.


Conventions for notations in identifiers:

 * The recommended spelling of `∧` in identifiers is `and`.
```


### Display 2


```text
`Or a b`, or `a ∨ b`, is the disjunction of propositions. There are two
constructors for `Or`, called `Or.inl : a → a ∨ b` and `Or.inr : b → a ∨ b`,
and you can use `match` or `cases` to destruct an `Or` assumption into the
two cases.


Conventions for notations in identifiers:

 * The recommended spelling of `∨` in identifiers is `or`.
```


### Display 3


```text
`Not p`, or `¬p`, is the negation of `p`. It is defined to be `p → False`,
so if your goal is `¬p` you can use `intro h` to turn the goal into
`h : p ⊢ False`, and if you have `hn : ¬p` and `h : p` then `hn h : False`
and `(hn h).elim` will prove anything.
For more information: [Propositional Logic](https://lean-lang.org/theorem_proving_in_lean4/propositions_and_proofs.html#propositional-logic)


Conventions for notations in identifiers:

 * The recommended spelling of `¬` in identifiers is `not`.
```


### Display 4


```text
If and only if, or logical bi-implication. `a ↔ b` means that `a` implies `b` and vice versa.
By `propext`, this implies that `a` and `b` are equal and hence any expression involving `a`
is equivalent to the corresponding expression with `b` instead.


Conventions for notations in identifiers:

 * The recommended spelling of `↔` in identifiers is `iff`.
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
A:PropB:Prop⊢ (¬A ∨ B) = (A → B)
```


### Display 2


```text
A:PropB:Prop⊢ ¬A ∨ B ↔ A → B
```


### Display 3


```text
mpA:PropB:Prop⊢ ¬A ∨ B → A → BmprA:PropB:Prop⊢ (A → B) → ¬A ∨ B
```


### Display 4


```text
mpA:PropB:Prop⊢ ¬A ∨ B → A → B
```


### Display 5


```text
mp.inlA:PropB:Proph:¬Aa:A⊢ Bmp.inrA:PropB:Proph:Ba:A⊢ B
```


### Display 6


```text
All goals completed! 🐙
```


### Display 7


```text
mprA:PropB:Prop⊢ (A → B) → ¬A ∨ B
```


### Display 8


```text
mprA:PropB:Proph:A → B⊢ ¬A ∨ B
```


### Display 9


```text
posA:PropB:Proph:A → Bh✝:A⊢ ¬A ∨ BnegA:PropB:Proph:A → Bh✝:¬A⊢ ¬A ∨ B
```


### Display 10


```text
posA:PropB:Proph:A → Bh✝:A⊢ ¬A ∨ B
```


### Display 11


```text
posA:PropB:Proph:A → Bh✝:A⊢ B
```


### Display 12


```text
negA:PropB:Proph:A → Bh✝:¬A⊢ ¬A ∨ B
```


### Display 13


```text
negA:PropB:Proph:A → Bh✝:¬A⊢ ¬A
```

