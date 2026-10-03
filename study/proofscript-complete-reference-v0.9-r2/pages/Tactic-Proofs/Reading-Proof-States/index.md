<a id="proof-states"></a>

# ProofScript — 14.2. Reading Proof States

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Tactics construct proof terms, and the checker decides whether those terms prove the requested claim. Use the inherited tactic language, including goal management, rewriting, induction and conv. Semicolon sequencing and the apply-to-all-goals combinator are distinct. Native grammar displays and tactic signatures below describe the selected environment, not a second ProofScript tactic system.

**Compiler and coverage boundary.** Term decorations may appear only in explicitly lifted tactic term slots. Preserve goal names, hygiene and source maps. Search failure is not proof of falsity.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Tactic-Proofs/Reading-Proof-States/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Tactic-Proofs/Reading-Proof-States/index.html). Source Git blob: `0eaba3b3b2feaf43ec23d3b01c984e3a6a05d4da`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 14.2. Reading Proof States

The goals in a proof state are displayed in order, with the main goal on top. Goals may be either named or anonymous. Named goals are indicated with `case` at the top (called a 
<a id="--tech-term-case-label"></a>
*case label*), while anonymous goals have no such indicator. Tactics assign goal names, typically on the basis of constructor names, parameter names, structure field names, or the nature of the reasoning step implemented by the tactic.

<a id="Named-goals"></a>
Named goals 

This proof state contains four goals, all of which are named. This is part of a proof that the `Monad Option` instance is lawful (that is, to provide the `LawfulMonad Option` instance), and the case names (highlighted below) come from the names of the fields of `LawfulMonad`.

<a id="Anonymous-Goals"></a>
Anonymous Goals 

This proof state contains a single anonymous goal.

The `case` and `case'` tactics can be used to select a new main goal using the desired goal's name. When names are assigned in the context of a goal which itself has a name, the new goals' names are appended to the main goal's name with a dot (`'.', Unicode FULL STOP (0x2e)`) between them.

<a id="Hierarchical-Goal-Names"></a>
Hierarchical Goal Names 

In the course of an attempt to prove `∀ (n k : Nat), n + k = k + n`, this proof state can occur:

After `induction k`, the two new cases' names have `zero` as a prefix, because they were created in a goal named `zero`:

Each goal consists of a sequence of assumptions and a desired conclusion. Each assumption has a name and a type; the conclusion is a type. Assumptions are either arbitrary elements of some type or statements that are presumed true.

<a id="Assumption-Names-and-Conclusion"></a>
Assumption Names and Conclusion 

This goal has four assumptions:

They are:

- `α`, an arbitrary type
- `x`, an arbitrary `α`
- `xs`, an arbitrary `List α`
- `ih`, an induction hypothesis that asserts that appending the empty list to `xs` is equal to `xs`.

The conclusion is the statement that prepending `x` to both sides of the equality in the induction hypothesis results in equal lists.

Some assumptions are 
<a id="--tech-term-inaccessible"></a>
*inaccessible*, 
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
 which means that they cannot be referred to explicitly by name. Inaccessible assumptions occur when an assumption is created without a specified name or when the assumption's name is shadowed by a later assumption. Inaccessible assumptions should be regarded as anonymous; they are presented as if they had names because they may be referred to in later assumptions or in the conclusion, and displaying a name allows these references to be distinguished from one another. In particular, inaccessible assumptions are presented with daggers (`†`) after their names.

<a id="Accessible-Assumption-Names"></a>
Accessible Assumption Names 

In this proof state, all assumptions are accessible.

<a id="Inaccessible-Assumption-Names"></a>
Inaccessible Assumption Names 

In this proof state, only the first and third assumptions are accessible. The second and fourth are inaccessible, and their names include a dagger to indicate that they cannot be referenced.

Inaccessible assumptions can still be used. Tactics such as `assumption` or `simp` can scan the entire list of assumptions, finding one that is useful, and `contradiction` can eliminate the current goal by finding an impossible assumption without naming it. Other tactics, such as `rename_i` and `next`, can be used to name inaccessible assumptions, making them accessible. Additionally, assumptions can be referred to by their type, by writing the type in single guillemets.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Assumptions by Type**

Single guillemets around a term represent a reference to some term in scope with that type.

<a id="_FLQQ_term_FLQ___FRQ__FLQQ_"></a>

```ebnf
term ::= ...
    | ‹term›
```

This can be used to refer to local lemmas by their theorem statement rather than by name, or to refer to assumptions regardless of whether they have explicit names.

<a id="Assumptions-by-Type"></a>
Assumptions by Type 

In the following proof, `cases` is repeatedly used to analyze a number. At the beginning of the proof, the number is named `x`, but `cases` generates an inaccessible name for subsequent numbers. Rather than providing names, the proof takes advantage of the fact that there is a single assumption of type `Nat` at any given time and uses `‹Nat›` to refer to it. After the iteration, there is an assumption that `n + 3 < 3`, which `contradiction` can use to remove the goal from consideration.

```proofscript
example : x < 3 → x ∈ [0, 1, 2] := by
  intros
  iterate 3
    cases ‹Nat›
    . decide
  contradiction
```

<a id="Assumptions-by-Type___-Outside-Proofs"></a>
Assumptions by Type, Outside Proofs 

Single-guillemet syntax also works outside of proofs:

```proofscript
#eval
  let x := 1
  let y := 2
  ‹Nat›
```

```lean
2
```

This is generally not a good idea for non-propositions, however—when it matters *which* element of a type is selected, it's better to select it explicitly.

<a id="hiding-terms-in-proof-states"></a>
### 14.2.1. Hiding Proofs and Large Terms

Terms in proof states can be quite big, and there may be many assumptions. Because of definitional proof irrelevance, proof terms typically give little useful information. By default, they are not shown in goals in proof states unless they are 
<a id="--tech-term-atomic"></a>
*atomic*, meaning that they contain no subterms. Hiding proofs is controlled by two options: `pp.proofs` turns the feature on and off, while `pp.proofs.threshold` determines a size threshold for proof hiding.

<a id="Hiding-Proof-Terms"></a>
Hiding Proof Terms 

In this proof state, the proof that `0 < n` is hidden.

<a id="pp___proofs"></a>

**option**

```text
pp.proofs
```

Default value: `false`

(pretty printer) display proofs when true, and replace proofs appearing within expressions by `⋯` when false

<a id="pp___proofs___threshold"></a>

**option**

```text
pp.proofs.threshold
```

Default value: `0`

(pretty printer) when `pp.proofs` is false, controls the complexity of proofs at which they begin being replaced with `⋯`

Additionally, non-proof terms may be hidden when they are too large. In particular, Lean will hide terms that are below a configurable depth threshold, and it will hide the remainder of a term once a certain amount in total has been printed. Showing deep terms can be enabled or disabled with the option `pp.deepTerms`, and the depth threshold can be configured with the option `pp.deepTerms.threshold`. The maximum number of pretty printer steps can be configured with the option `pp.maxSteps`. Printing very large terms can lead to slowdowns or even stack overflows in tooling; please be conservative when adjusting these options' values.

<a id="pp___deepTerms"></a>

**option**

```text
pp.deepTerms
```

Default value: `false`

(pretty printer) display deeply nested terms, replacing them with `⋯` if set to false

<a id="pp___deepTerms___threshold"></a>

**option**

```text
pp.deepTerms.threshold
```

Default value: `50`

(pretty printer) when `pp.deepTerms` is false, the depth at which terms start being replaced with `⋯`

<a id="pp___maxSteps"></a>

**option**

```text
pp.maxSteps
```

Default value: `5000`

(pretty printer) maximum number of expressions to visit, after which terms will pretty print as `⋯`

<a id="metavariables-in-proofs"></a>
### 14.2.2. Metavariables

Terms that begin with a question mark are 
<a id="--tech-term-metavariables"></a>
*metavariables* that correspond to an unknown value. They may stand for either [universe](../../The-Type-System/Universes/index.md#--tech-term-universes) levels or for terms. Some metavariables arise as part of Lean's elaboration process, when not enough information is yet available to determine a value. These metavariables' names have a numeric component at the end, such as `?m.392` or `?u.498`. Other metavariables come into existence as a result of tactics or [synthetic holes](../../Terms/Holes/index.md#--tech-term-synthetic-holes). These metavariables' names do not have a numeric component. Metavariables that result from tactics frequently appear as goals whose [case labels](index.md#--tech-term-case-label) match the name of the metavariable.

<a id="Universe-Level-Metavariables"></a>
Universe Level Metavariables 

In this proof state, the universe level of `α` is unknown:

<a id="Type-Metavariables"></a>
Type Metavariables 

In this proof state, the type of list elements is unknown. The metavariable is repeated because the unknown type must be the same in both positions.

<a id="Metavariables-in-Proofs"></a>
Metavariables in Proofs 

In this proof state,

applying the tactic `apply Nat.lt_trans` results in the following proof state, in which the middle value of the transitivity step `?m` is unknown:

<a id="Explicitly-Created-Metavariables"></a>
Explicitly-Created Metavariables 

Explicit named holes are represented by metavariables, and additionally give rise to proof goals. In this proof state,

applying the tactic `apply @Nat.lt_trans i ?middle k ?p1 ?p2` results in the following proof state, in which the middle value of the transitivity step `?middle` is unknown and goals have been created for each of the named holes in the term:

The display of metavariable numbers can be disabled using the `pp.mvars`. This can be useful when using features such as [`#guard_msgs`](../../Interacting-with-Lean/index.md#Lean___guardMsgsCmd) that match Lean's output against a desired string, which is very useful when writing tests for custom tactics.

<a id="pp___mvars"></a>

**option**

```text
pp.mvars
```

Default value: `true`

(pretty printer) display names of metavariables when true, and otherwise display them as '?*' (for expression metavariables) and as '*' (for universe level metavariables)

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`‹t›` resolves to an (arbitrary) hypothesis of type `t`.
It is useful for referring to hypotheses without accessible names.
`t` may contain holes that are solved by unification with the expected type;
in particular, `‹_›` is a shortcut for `by assumption`.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
2
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
bind_pure_compα:Type ?u.9β:Type ?u.9f:α → βx:Option α⊢ (do
    let a ← x
    pure (f a)) =
  f <$> xbind_mapα:Type ?u.9β:Type ?u.9f:Option (α → β)x:Option α⊢ (do
    let x_1 ← f
    x_1 <$> x) =
  f <*> xpure_bindα:Type ?u.9β:Type ?u.9x:αf:α → Option β⊢ pure x >>= f = f xbind_assocα:Type ?u.9β:Type ?u.9γ:Type ?u.9x:Option αf:α → Option βg:β → Option γ⊢ x >>= f >>= g = x >>= fun x => f x >>= g
```


### Display 2


```text
n:Natk:Nat⊢ n + k = k + n
```


### Display 3


```text
zerok:Nat⊢ 0 + k = k + 0succk:Natn✝:Nata✝:n✝ + k = k + n✝⊢ n✝ + 1 + k = k + (n✝ + 1)
```


### Display 4


```text
zero.zero⊢ 0 + 0 = 0 + 0zero.succn✝:Nata✝:0 + n✝ = n✝ + 0⊢ 0 + (n✝ + 1) = n✝ + 1 + 0succk:Natn✝:Nata✝:n✝ + k = k + n✝⊢ n✝ + 1 + k = k + (n✝ + 1)
```


### Display 5


```text
consα:Type ?u.3x:αxs:List αih:xs ++ [] = xs⊢ x :: xs ++ [] = x :: xs
```


### Display 6


```text
bind_pure_compα:Type ?u.3β:Type ?u.3f:α → βx:Option α⊢ (do
    let a ← x
    pure (f a)) =
  f <$> x
```


### Display 7


```text
bind_pure_compα:Type ?u.3β✝:Type ?u.3f:α → β✝x✝:Option α⊢ (do
    let a ← x✝
    pure (f a)) =
  f <$> x✝
```


### Display 8


```text
x:Nat⊢ x < 3 → x ∈ [0, 1, 2]
```


### Display 9


```text
x:Nata✝:x < 3⊢ x ∈ [0, 1, 2]
```


### Display 10


```text
succ.succ.zeroa✝:0 + 1 + 1 < 3⊢ 0 + 1 + 1 ∈ [0, 1, 2]succ.succ.succn✝:Nata✝:n✝ + 1 + 1 + 1 < 3⊢ n✝ + 1 + 1 + 1 ∈ [0, 1, 2]
```


### Display 11


```text
succ.succ.zeroa✝:0 + 1 + 1 < 3⊢ 0 + 1 + 1 ∈ [0, 1, 2]
```


### Display 12


```text
All goals completed! 🐙
```


### Display 13


```text
n:Nati:Fin ngt:↑i > 5⊢ ⟨0, ⋯⟩ < i
```


### Display 14


```text
α:Type ?u.4x:αxs:List αelem:x ∈ xs⊢ xs.length > 0
```


### Display 15


```text
x:?m.8xs:List ?m.8elem:x ∈ xs⊢ xs.length > 0
```


### Display 16


```text
i:Natj:Natk:Nath1:i < jh2:j < k⊢ i < k
```


### Display 17


```text
h₁i:Natj:Natk:Nath1:i < jh2:j < k⊢ i < ?mai:Natj:Natk:Nath1:i < jh2:j < k⊢ ?m < kmi:Natj:Natk:Nath1:i < jh2:j < k⊢ Nat
```


### Display 18


```text
middlei:Natj:Natk:Nath1:i < jh2:j < k⊢ Natp1i:Natj:Natk:Nath1:i < jh2:j < k⊢ i < ?middlep2i:Natj:Natk:Nath1:i < jh2:j < k⊢ ?middle < k
```

