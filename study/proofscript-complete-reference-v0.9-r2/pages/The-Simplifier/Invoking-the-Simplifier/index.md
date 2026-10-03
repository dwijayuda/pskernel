<a id="simp-tactic-naming"></a>

# ProofScript — 15.1. Invoking the Simplifier

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

simp uses selected rewrite theorems and congruence reasoning to construct checked evidence. simp only restricts the simplification set; simp at changes a hypothesis or location. The normal forms chosen by a library affect proof maintenance and automation. A simplifier is not a privileged evaluator permitted to replace an unproved goal with success.

**Compiler and coverage boundary.** Track the exact simp set, local hypotheses and configuration. A changed tactic script is not necessarily a changed theorem, but a cached proof must still match its dependency identity.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The-Simplifier/Invoking-the-Simplifier/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The-Simplifier/Invoking-the-Simplifier/index.html). Source Git blob: `8080ac0f75eea6f01586b04fadc19d1b1d7dfc9c`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 15.1. Invoking the Simplifier

Lean's simplifier can be invoked in a variety of ways. The most common patterns are captured in a set of tactics. The [tactic reference](../../Tactic-Proofs/Tactic-Reference/index.md#simp-tactics) contains a complete list of simplification tactics.

Simplification tactics all contain `simp` in their name. Aside from that, they are named according to a system of prefixes and suffixes that describe their functionality:

  `-!` suffix

Sets the `autoUnfold` configuration option to `true`, causing the simplifier to unfold all definitions

  `-?` suffix

Causes the simplifier to keep track of which rules it employed during simplification and suggest a minimal [simp set](../Simp-sets/index.md#--tech-term-simp-set) as an edit to the tactic script

  `-_arith` suffix

Enables the use of linear arithmetic simplification rules

  `d-` prefix

Causes the simplifier to simplify only with rewrites that hold definitionally

  `-_all` suffix

Causes the simplifier to repeatedly simplify all assumptions and the conclusion of the goal, taking as many hypotheses into account as possible, until no further simplification is possible

There are two further simplification tactics, `simpa` and `simpa!`, which are used to simultaneously simplify a goal and either a proof term or an assumption before discharging the goal. This simultaneous simplification makes proofs more robust to changes in the [simp set](../Simp-sets/index.md#--tech-term-simp-set).

<a id="simp-tactic-params"></a>
### 15.1.1. Parameters

The simplification tactics have the following grammar:

<a id="tactic-next"></a>

**syntax**

**Simplification Tactics**

<a id="Lean___Parser___Tactic___simp"></a>

```ebnf
tactic ::= ...
    | simp optConfig only? ([ (simpStar | simpErase | simpLemma),* ] )? (at (term | locationType)*)?
```

In other words, an invocation of a simplification tactic takes the following modifiers, in order, all of which are optional:

- A set of [configuration options](../../Tactic-Proofs/The-Tactic-Language/index.md#tactic-config), which should include the fields of `Lean.Meta.Simp.Config` or `Lean.Meta.DSimp.Config`, depending on whether the simplifier being invoked is a version of `simp` or a version of `dsimp`.
- The [`only`](../../Tactic-Proofs/Tactic-Reference/index.md#simp) modifier excludes the default simp set, instead beginning with an emptyTechnically, the simp set always includes `eq_self` and `iff_self` in order to discharge reflexive cases. simp set.
- The lemma list adds or removes lemmas from the simp set. There are three ways to specify lemmas in the lemma list:

   

  - `*`, which adds all assumptions in the proof state to the simp set
  - `-` followed by a lemma, which removes the lemma from the simp set
  - A lemma specifier, consisting of the following in sequence:

     

    - An optional `↓` or `↑`, which respectively cause the lemma to be applied before or after entering a subterm (`↑` is the default). The simplifier typically simplifies subterms before attempting to simplify parent terms, as simplified arguments often make more rules applicable; `↓` causes the parent term to be simplified with the rule prior to the simplification of subterms.
    - An optional `←`, which causes equational lemmas to be used from right to left rather than from left to right.
    - A mandatory lemma, which can be a simp set name, a lemma name, or a term. Terms are treated as if they were named lemmas with fresh names.
- A location specifier, preceded by [`at`](../../Tactic-Proofs/Tactic-Reference/index.md#simp), which consists of a sequence of locations. Locations may be:

   

  - The name of an assumption, indicating that its type should be simplified
  - An asterisk `*`, indicating that all assumptions and the conclusion should be simplified
  - A turnstile `⊢`, indicating that the conclusion should be simplified

   

  By default, only the conclusion is simplified.

<a id="Location-specifiers-for--simp"></a>
Location specifiers for `simp` 

In this proof state,

the tactic `simp +arith` simplifies only the goal:

Invoking `simp +arith at h` yields a goal in which the hypothesis `h` has been simplified:

The conclusion can be additionally simplified by adding `⊢`, that is, `simp +arith at h ⊢`:

Using `simp +arith at *` simplifies all assumptions together with the conclusion:

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
The `simp` tactic uses lemmas and hypotheses to simplify the main goal target or
non-dependent hypotheses. It has many variants:
- `simp` simplifies the main goal target using lemmas tagged with the attribute `[simp]`.
- `simp [h₁, h₂, ..., hₙ]` simplifies the main goal target using the lemmas tagged
  with the attribute `[simp]` and the given `hᵢ`'s, where the `hᵢ`'s are expressions.-
- If an `hᵢ` is a defined constant `f`, then `f` is unfolded. If `f` has equational lemmas associated
  with it (and is not a projection or a `reducible` definition), these are used to rewrite with `f`.
- `simp [*]` simplifies the main goal target using the lemmas tagged with the
  attribute `[simp]` and all hypotheses.
- `simp only [h₁, h₂, ..., hₙ]` is like `simp [h₁, h₂, ..., hₙ]` but does not use `[simp]` lemmas.
- `simp [-id₁, ..., -idₙ]` simplifies the main goal target using the lemmas tagged
  with the attribute `[simp]`, but removes the ones named `idᵢ`.
- `simp at h₁ h₂ ... hₙ` simplifies the hypotheses `h₁ : T₁` ... `hₙ : Tₙ`. If
  the target or another hypothesis depends on `hᵢ`, a new simplified hypothesis
  `hᵢ` is introduced, but the old one remains in the local context.
- `simp at *` simplifies all the hypotheses and the target.
- `simp [*] at *` simplifies target and all (propositional) hypotheses using the
  other hypotheses.
```


### Display 2


```text
Configuration options for tactics.
```


### Display 3


```text
The simp lemma specification `*` means to rewrite with all hypotheses
```


### Display 4


```text
An erasure specification `-thm` says to remove `thm` from the simp set
```


### Display 5


```text
A simp lemma specification is:
* optional `↑` or `↓` to specify use before or after entering the subterm
* optional `←` to use the lemma backward
* `thm` for the theorem to rewrite with
```


### Display 6


```text
Location specifications are used by many tactics that can operate on either the
hypotheses or the goal. It can have one of the forms:
* 'empty' is not actually present in this syntax, but most tactics use
  `(location)?` matchers. It means to target the goal only.
* `at h₁ ... hₙ`: target the hypotheses `h₁`, ..., `hₙ`
* `at h₁ h₂ ⊢`: target the hypotheses `h₁` and `h₂`, and the goal
* `at *`: target all hypotheses and the goal
```


### Display 7


```text
A sequence of one or more locations at which a tactic should operate. These can include local
hypotheses and `⊢`, which denotes the goal.
```


### Display 8


```text
The `⊢` location refers to the current goal.
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
p:Nat → Propx:Nath:p (x + 5 + 2)h':p (3 + x + 9)⊢ p (6 + x + 1)
```


### Display 2


```text
p:Nat → Propx:Nath:p (x + 5 + 2)h':p (3 + x + 9)⊢ p (x + 7)
```


### Display 3


```text
p:Nat → Propx:Nath':p (3 + x + 9)h:p (x + 7)⊢ p (6 + x + 1)
```


### Display 4


```text
p:Nat → Propx:Nath':p (3 + x + 9)h:p (x + 7)⊢ p (x + 7)
```


### Display 5


```text
p:Nat → Propx:Nath:p (x + 7)h':p (x + 12)⊢ p (x + 7)
```

