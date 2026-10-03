<a id="custom-tactics"></a>

# ProofScript — 14.8. Custom Tactics

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Tactics construct proof terms, and the checker decides whether those terms prove the requested claim. Use the inherited tactic language, including goal management, rewriting, induction and conv. Semicolon sequencing and the apply-to-all-goals combinator are distinct. Native grammar displays and tactic signatures below describe the selected environment, not a second ProofScript tactic system.

**Compiler and coverage boundary.** Term decorations may appear only in explicitly lifted tactic term slots. Preserve goal names, hygiene and source maps. Search failure is not proof of falsity.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Tactic-Proofs/Custom-Tactics/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Tactic-Proofs/Custom-Tactics/index.html). Source Git blob: `a8332470619e8406d632a693bb6865f879c79656`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 14.8. Custom Tactics

Tactics are productions in the syntax category `tactic`. Given the syntax of a tactic, the tactic interpreter is responsible for carrying out actions in the tactic monad `TacticM`, which is a wrapper around Lean's term elaborator that keeps track of the additional state needed to execute tactics. A custom tactic consists of an extension to the `tactic` category along with either:

- a [macro](../../Notations-and-Macros/Macros/index.md#--tech-term-Macros) that translates the new syntax into existing syntax, or
- an elaborator that carries out `TacticM` actions to implement the tactic.

<a id="tactic-macros"></a>
### 14.8.1. Tactic Macros

The easiest way to define a new tactic is as a [macro](../../Notations-and-Macros/Macros/index.md#--tech-term-Macros) that expands into already-existing tactics. Macro expansion is interleaved with tactic execution. The tactic interpreter first expands tactic macros just before they are to be interpreted. Because tactic macros are not fully expanded prior to running a tactic script, they can use recursion; as long as the recursive occurrence of the macro syntax is beneath a tactic that can be executed, there will not be an infinite chain of expansion.

<a id="Recursive-tactic-macro"></a>
Recursive tactic macro 

This recursive implementation of a tactic akin to `repeat` is defined via macro expansion. When the argument `$t` fails, the recursive occurrence of `rep` is never invoked, and is thus never macro expanded.

```proofscript
syntax "rep" tactic : tactic
macro_rules
  | `(tactic|rep $t) =>
  `(tactic|
    first
      | $t; rep $t
      | skip)

example : 0 ≤ 4 := by
  rep (apply Nat.le.step)
  apply Nat.le.refl
```

Like other Lean macros, tactic macros are [hygienic](../../Notations-and-Macros/Macros/index.md#--tech-term-hygienic). References to global names are resolved when the macro is defined, and names introduced by the tactic macro cannot capture names from its invocation site.

When defining a tactic macro, it's important to specify that the syntax being matched or constructed is for the syntax category `tactic`. Otherwise, the syntax will be interpreted as that of a term, which will match against or construct an incorrect AST for tactics.

<a id="tactic-macro-extension"></a>
#### 14.8.1.1. Extensible Tactic Macros

Because macro expansion can fail, multiple macros can match the same syntax, allowing backtracking. Tactic macros take this further: even if a tactic macro expands successfully, if the expansion fails when interpreted, the tactic interpreter will attempt the next expansion. This is used to make a number of Lean's built-in tactics extensible—new behavior can be added to a tactic by adding a [`macro_rules`](../../Notations-and-Macros/Macros/index.md#Lean___Parser___Command___macro_rules) declaration.

<a id="Extending--trivial"></a>
Extending `trivial` 

The `trivial`, which is used by many other tactics to quickly dispatch subgoals that are not worth bothering the user with, is designed to be extended through new macro expansions. Lean's default `trivial` can't solve `IsEmpty []` goals:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="IsEmpty-_LPAR_in-Extending--trivial_RPAR_"></a>


```proofscript
function IsEmpty (xs : List α) : Prop :=
  ¬ xs ≠ []
```

```proofscript
example (α : Type u) : IsEmpty (α := α) [] := by trivial
```

The error message is an artifact of `trivial` trying `assumption` last. Adding another expansion allows `trivial` to take care of these goals:
<a id="emptyIsEmpty-_LPAR_in-Extending--trivial_RPAR_"></a>


```proofscript
def emptyIsEmpty : IsEmpty (α := α) [] := by simp [IsEmpty]

macro_rules | `(tactic|trivial) => `(tactic|exact emptyIsEmpty)

example (α : Type u) : IsEmpty (α := α) [] := by
  trivial
```

<a id="Expansion-Backtracking"></a>
Expansion Backtracking 

Macro expansion can induce backtracking when the failure arises from any part of the expanded syntax. An infix version of `first` can be defined by providing multiple expansions in separate [`macro_rules`](../../Notations-and-Macros/Macros/index.md#Lean___Parser___Command___macro_rules) declarations:

```proofscript
syntax tactic "<|||>" tactic : tactic
macro_rules
  | `(tactic|$t1 <|||> $t2) => pure t1
macro_rules
  | `(tactic|$t1 <|||> $t2) => pure t2

example : 2 = 2 := by
  rfl <|||> apply And.intro

example : 2 = 2 := by
  apply And.intro <|||> rfl
```

Multiple [`macro_rules`](../../Notations-and-Macros/Macros/index.md#Lean___Parser___Command___macro_rules) declarations are needed because each defines a pattern-matching function that will always take the first matching alternative. Backtracking is at the granularity of [`macro_rules`](../../Notations-and-Macros/Macros/index.md#Lean___Parser___Command___macro_rules) declarations, not their individual cases.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Tactic `assumption` failed

α:Type u⊢ IsEmpty []
```


### Display 2


```text
Definition `emptyIsEmpty` is a proposition; use `theorem` instead of `def`

Note: This linter can be disabled with `set_option linter.defProp false`
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
⊢ 0 ≤ 4
```


### Display 2


```text
⊢ Nat.le 0 0
```


### Display 3


```text
All goals completed! 🐙
```


### Display 4


```text
α:Type u⊢ IsEmpty []
```


### Display 5


```text
α:Type u_1⊢ IsEmpty []
```


### Display 6


```text
⊢ 2 = 2
```

