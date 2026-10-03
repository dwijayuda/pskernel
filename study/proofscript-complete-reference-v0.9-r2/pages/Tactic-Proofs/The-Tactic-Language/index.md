<a id="tactic-language"></a>

# ProofScript — 14.3. The Tactic Language

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Tactics construct proof terms, and the checker decides whether those terms prove the requested claim. Use the inherited tactic language, including goal management, rewriting, induction and conv. Semicolon sequencing and the apply-to-all-goals combinator are distinct. Native grammar displays and tactic signatures below describe the selected environment, not a second ProofScript tactic system.

**Compiler and coverage boundary.** Term decorations may appear only in explicitly lifted tactic term slots. Preserve goal names, hygiene and source maps. Search failure is not proof of falsity.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Tactic-Proofs/The-Tactic-Language/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Tactic-Proofs/The-Tactic-Language/index.html). Source Git blob: `00fd6fb6500c928cc504cb7b628e08b292ff029f`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 14.3. The Tactic Language

A tactic script consists of a sequence of tactics, separated either by semicolons or newlines. When separated by newlines, tactics must be indented to the same level. Explicit curly braces and semicolons may be used instead of indentation. Tactic sequences may be grouped by parentheses. This allows a sequence of tactics to be used in a position where a single tactic would otherwise be grammatically expected.

Generally, execution proceeds from top to bottom, with each tactic running in the proof state left behind by the prior tactic. The tactic language contains a number of control structures that can modify this flow.

Each tactic is a syntax extension in the `tactic` category. This means that tactics are free to define their own concrete syntax and parsing rules. However, with a few exceptions, the majority of tactics can be identified by a leading keyword; the exceptions are typically frequently-used built-in control structures such as `<;>`.

<a id="tactic-language-control"></a>
### 14.3.1. Control Structures

Strictly speaking, there is no fundamental distinction between control structures and other tactics. Any tactic is free to take others as arguments and arrange for their execution in any context that it sees fit. Even if a distinction is arbitrary, however, it can still be useful. The tactics in this section are those that resemble traditional control structures from programming, or those that *only* recombine other tactics rather than making progress themselves.

<a id="tactic-language-success-failure"></a>
#### 14.3.1.1. Success and Failure

When run in a proof state, every tactic either succeeds or fails. Tactic failure is akin to exceptions: failures typically “bubble up” until handled. Unlike exceptions, there is no operator to distinguish between reasons for failure; `first` simply takes the first branch that succeeds.

<a id="fail"></a>

**tactic**

```text
fail
```

`fail msg` is a tactic that always fails, and produces an error using the given message.

<a id="fail_if_success"></a>

**tactic**

```text
fail_if_success
```

`fail_if_success t` fails if the tactic `t` succeeds.

<a id="try"></a>

**tactic**

```text
try
```

`try tac` runs `tac` and succeeds even if `tac` failed.

<a id="first"></a>

**tactic**

```text
first
```

`first | tac | ...` runs each `tac` until one succeeds, or else fails.

<a id="tactic-language-branching"></a>
#### 14.3.1.2. Branching

Tactic proofs may use pattern matching and conditionals. However, their meaning is not quite the same as it is in terms. While terms are expected to be executed once the values of their variables are known, proofs are executed with their variables left abstract and should consider *all* cases simultaneously. Thus, when `if` and `match` are used in tactics, their meaning is reasoning by cases rather than selection of a concrete branch. All of their branches are executed, and the condition or pattern match is used to refine the main goal with more information in each branch, rather than to select a single branch.

<a id="if"></a>

**tactic**

```text
if
```

In tactic mode, `if t then tac1 else tac2` is alternative syntax for:

```proofscript
by_cases t
· tac1
· tac2
```

It performs case distinction on `h† : t` or `h† : ¬t`, where `h†` is an anonymous hypothesis, and `tac1` and `tac2` are the subproofs. (It doesn't actually use nondependent `if`, since this wouldn't add anything to the context and hence would be useless for proving theorems. To actually insert an `ite` application use `refine if t then ?_ else ?_`.)

The assumptions in each subgoal can be named. `if h : t then tac1 else tac2` can be used as alternative syntax for:

```text
by_cases h : t
· tac1
· tac2
```

It performs case distinction on `h : t` or `h : ¬t`.

You can use `?_` or `_` for either subproof to delay the goal to after the tactic, but if a tactic sequence is provided for `tac1` or `tac2` then it will require the goal to be closed by the end of the block.

<a id="Reasoning-by-cases-with--if"></a>
Reasoning by cases with `if` 

In each branch of the [`if`](index.md#if), an assumption is added that reflects whether `n = 0`.

```proofscript
example (n : Nat) : if n = 0 then n < 1 else n > 0 := by
  if n = 0 then
    simp [*]
  else
    simp only [↓reduceIte, gt_iff_lt, *]
    omega
```

<a id="match"></a>

**tactic**

```text
match
```

`match` performs case analysis on one or more expressions. See [Induction and Recursion](https://lean-lang.org/theorem_proving_in_lean4/induction_and_recursion.html). The syntax for the `match` tactic is the same as term-mode `match`, except that the match arms are tactics instead of expressions.

```proofscript
example (n : Nat) : n = n := by
  match n with
  | 0 => rfl
  | i+1 => simp
```

When pattern matching, instances of the [discriminant](../../Terms/Pattern-Matching/index.md#--tech-term-match-discriminants) in the goal are replaced with the patterns that match them in each branch. Each branch must then prove the refined goal. Compared to the `cases` tactic, using `match` can allow a greater degree of flexibility in the cases analysis being performed, but the requirement that each branch solve its goal completely makes it more difficult to incorporate into larger automation scripts.

<a id="Reasoning-by-cases-with--match"></a>
Reasoning by cases with `match` 

In each branch of the [`match`](index.md#match), the discriminant `n` has been replaced by either `0` or `k + 1`.

```proofscript
example (n : Nat) : if n = 0 then n < 1 else n > 0 := by
  match n with
  | 0 =>
    simp
  | k + 1 =>
    simp
```

<a id="tactic-language-goal-selection"></a>
#### 14.3.1.3. Goal Selection

Most tactics affect the [main goal](../index.md#--tech-term-main-goal). Goal selection tactics provide a way to treat a different goal as the main one, rearranging the sequence of goals in the proof state.

<a id="case"></a>

**tactic**

```text
case
```

- `case tag => tac` focuses on the goal with case name `tag` and solves it using `tac`, or else fails.
- `case tag x₁ ... xₙ => tac` additionally renames the `n` most recent hypotheses with inaccessible names to the given names.
- `case tag₁ | tag₂ => tac` is equivalent to `(case tag₁ => tac); (case tag₂ => tac)`.

<a id="case___"></a>

**tactic**

```text
case'
```

`case'` is similar to the `case tag => tac` tactic, but does not ensure the goal has been solved after applying `tac`, nor admits the goal if `tac` failed. Recall that `case` closes the goal using `sorry` when `tac` fails, and the tactic execution is not interrupted.

<a id="rotate_left"></a>

**tactic**

```text
rotate_left
```

`rotate_left n` rotates goals to the left by `n`. That is, `rotate_left 1` takes the main goal and puts it to the back of the subgoal list. If `n` is omitted, it defaults to `1`.

<a id="rotate_right"></a>

**tactic**

```text
rotate_right
```

Rotate the goals to the right by `n`. That is, take the goal at the back and push it to the front `n` times. If `n` is omitted, it defaults to `1`.

<a id="tactic-language-sequencing"></a>
##### 14.3.1.3.1. Sequencing

In addition to running tactics one after the other, each being used to solve the main goal, the tactic language supports sequencing tactics according to the way in which goals are produced. The `<;>` tactic combinator allows a tactic to be applied to *every* [subgoal](../index.md#--tech-term-subgoals) produced by some other tactic. If no new goals are produced, then the second tactic is not run.

<a id="_LT__SEMI__GT_"></a>

**tactic**

```text
<;>
```

`tac <;> tac'` runs `tac` on the main goal and `tac'` on each produced goal, concatenating all goals produced by `tac'`.

If the tactic fails on any of the [subgoals](../index.md#--tech-term-subgoals), then the whole `<;>` tactic fails.

<a id="Subgoal-Sequencing"></a>
Subgoal Sequencing 

In this proof state:

the tactic `cases h` yields the following two goals:

Running `cases h ; simp [*]` causes `simp` to solve the first goal, leaving the second behind:

Replacing the `;` with `<;>` and running `cases h <;> simp [*]` solves **both** of the new goals with `simp`:

<a id="tactic-language-multiple-goals"></a>
##### 14.3.1.3.2. Working on Multiple Goals

The tactics `all_goals` and `any_goals` allow a tactic to be applied to every goal in the proof state. The difference between them is that if the tactic fails for in any of the goals, `all_goals` itself fails, while `any_goals` fails only if the tactic fails in all of the goals.

<a id="all_goals"></a>

**tactic**

```text
all_goals
```

`all_goals tac` runs `tac` on each goal, concatenating the resulting goals. If the tactic fails on any goal, the entire `all_goals` tactic fails.

See also `any_goals tac`.

<a id="any_goals"></a>

**tactic**

```text
any_goals
```

`any_goals tac` applies the tactic `tac` to every goal, concatenating the resulting goals for successful tactic applications. If the tactic fails on all of the goals, the entire `any_goals` tactic fails.

This tactic is like `all_goals try tac` except that it fails if none of the applications of `tac` succeeds.

<a id="tactic-language-focusing"></a>
#### 14.3.1.4. Focusing

Focusing tactics remove some subset of the proof goals (typically leaving only the main goal) from the consideration of some further tactics. In addition to the tactics described here, the `case` and `case'` tactics focus on the selected goal.

<a id="___"></a>

**tactic**

```text
·
```

`· tac` focuses on the main goal and tries to solve it using `tac`, or else fails.

It is generally considered good Lean style to use bullets whenever a tactic line results in more than one new subgoal. This makes it easier to read and maintain proofs, because the connections between steps of reasoning are more clear and any change in the number of subgoals while editing the proof will have a localized effect.

<a id="next"></a>

**tactic**

```text
next
```

`next => tac` focuses on the next goal and solves it using `tac`, or else fails. `next x₁ ... xₙ => tac` additionally renames the `n` most recent hypotheses with inaccessible names to the given names.

<a id="focus"></a>

**tactic**

```text
focus
```

`focus tac` focuses on the main goal, suppressing all other goals, and runs `tac` on it. Usually `· tac`, which enforces that the goal is closed by `tac`, should be preferred.

<a id="tactic-language-iteration"></a>
#### 14.3.1.5. Repetition and Iteration

<a id="iterate"></a>

**tactic**

```text
iterate
```

`iterate n tac` runs `tac` exactly `n` times. `iterate tac` runs `tac` repeatedly until failure.

`iterate`'s argument is a tactic sequence, so multiple tactics can be run using `iterate n (tac₁; tac₂; ⋯)` or

```proofscript
iterate n
  tac₁
  tac₂
  ⋯
```

<a id="repeat"></a>

**tactic**

```text
repeat
```

`repeat tac` repeatedly applies `tac` so long as it succeeds. The tactic `tac` may be a tactic sequence, and if `tac` fails at any point in its execution, `repeat` will revert any partial changes that `tac` made to the tactic state.

The tactic `tac` should eventually fail, otherwise `repeat tac` will run indefinitely.

See also:

- `try tac` is like `repeat tac` but will apply `tac` at most once.
- `repeat' tac` recursively applies `tac` to each goal.
- `first | tac1 | tac2` implements the backtracking used by `repeat`

<a id="repeat___"></a>

**tactic**

```text
repeat'
```

`repeat' tac` recursively applies `tac` on all of the goals so long as it succeeds. That is to say, if `tac` produces multiple subgoals, then `repeat' tac` is applied to each of them.

See also:

- `repeat tac` simply repeatedly applies `tac`.
- `repeat1' tac` is `repeat' tac` but requires that `tac` succeed for some goal at least once.

<a id="repeat1___"></a>

**tactic**

```text
repeat1'
```

`repeat1' tac` recursively applies to `tac` on all of the goals so long as it succeeds, but `repeat1' tac` fails if `tac` succeeds on none of the initial goals.

See also:

- `repeat tac` simply applies `tac` repeatedly.
- `repeat' tac` is like `repeat1' tac` but it does not require that `tac` succeed at least once.

<a id="tactic-language-hygiene"></a>
### 14.3.2. Names and Hygiene

Behind the scenes, tactics generate proof terms. These proof terms exist in a local context, because assumptions in proof states correspond to local binders in terms. Uses of assumptions correspond to variable references. It is very important that the naming of assumptions be predictable; otherwise, small changes to the internal implementation of a tactic could either lead to variable capture or to a broken reference if they cause different names to be selected.

Lean's tactic language is *hygienic*. 
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
 This means that the tactic language respects lexical scope: names that occur in a tactic refer to the enclosing binding in the source code, rather than being determined by the generated code, and the tactic framework is responsible for maintaining this property. Variable references in tactic scripts refer either to names that were in scope at the beginning of the script or to bindings that were explicitly introduced as part of the tactics, rather than to the names chosen for use in the proof term behind the scenes.

A consequence of hygienic tactics is that the only way to refer to an assumption is to explicitly name it. Tactics cannot assign assumption names themselves, but must rather accept names from users; users are correspondingly obligated to provide names for assumptions that they wish to refer to. When an assumption does not have a user-provided name, it is shown in the proof state with a dagger (`'†', DAGGER	0x2020`). The dagger indicates that the name is *inaccessible* and cannot be explicitly referred to.

Hygiene can be disabled by setting the option `tactic.hygienic` to `false`. This is not recommended, as many tactics rely on the hygiene system to prevent capture and thus do not incur the overhead of careful manual name selection.

<a id="tactic___hygienic"></a>

**option**

```text
tactic.hygienic
```

Default value: `true`

make sure tactics are hygienic

<a id="Tactic-hygiene___-inaccessible-assumptions"></a>
Tactic hygiene: inaccessible assumptions 

When proving that `∀ (n : Nat), 0 + n = n`, the initial proof state is:

The tactic `intro` results in a proof state with an inaccessible assumption:

<a id="Tactic-hygiene___-accessible-assumptions"></a>
Tactic hygiene: accessible assumptions 

When proving that `∀ (n : Nat), 0 + n = n`, the initial proof state is:

The tactic `intro n`, with the explicit name `n`, results in a proof state with an accessibly-named assumption:

<a id="tactic-language-assumptions"></a>
#### 14.3.2.1. Accessing Assumptions

Many tactics provide a means of specifying names for the assumptions that they introduce. For example, `intro` and `intros` take assumption names as arguments, and `induction`'s [`with`](../Tactic-Reference/index.md#induction)-form allows simultaneous case selection, assumption naming, and focusing. When an assumption does not have a name, one can be assigned using `next`, `case`, or `rename_i`.

<a id="rename_i"></a>

**tactic**

```text
rename_i
```

`rename_i x_1 ... x_n` renames the last `n` inaccessible names using the given names.

<a id="tactic-language-assumption-management"></a>
### 14.3.3. Assumption Management

Larger proofs can benefit from management of proof states, removing irrelevant assumptions and making their names easier to understand. Along with these operators, `rename_i` allows inaccessible assumptions to be renamed, and `intro`, `intros` and `rintro` convert goals that are implications or universal quantification into goals with additional assumptions.

<a id="rename"></a>

**tactic**

```text
rename
```

`rename t => x` renames the most recent hypothesis whose type matches `t` (which may contain placeholders) to `x`, or fails if no such hypothesis could be found.

<a id="revert"></a>

**tactic**

```text
revert
```

`revert x...` is the inverse of `intro x...`: it moves the given hypotheses into the main goal's target type.

<a id="clear"></a>

**tactic**

```text
clear
```

`clear x...` removes the given hypotheses, or fails if there are remaining references to a hypothesis.

<a id="tactic-language-local-defs"></a>
### 14.3.4. Local Definitions and Proofs

`have` and `let` both create local assumptions. Generally speaking, `have` should be used when proving an intermediate lemma; `let` should be reserved for local definitions.

<a id="have"></a>

**tactic**

```text
have
```

The `have` tactic is for adding opaque definitions and hypotheses to the local context of the main goal. The definitions forget their associated value and cannot be unfolded, unlike definitions added by the `let` tactic.

- `have h : t := e` adds the hypothesis `h : t` if `e` is a term of type `t`.
- `have h := e` uses the type of `e` for `t`.
- `have : t := e` and `have := e` use `this` for the name of the hypothesis.
- `have pat := e` for a pattern `pat` is equivalent to `match e with | pat => _`, where `_` stands for the tactics that follow this one. It is convenient for types that have only one applicable constructor. For example, given `h : p ∧ q ∧ r`, `have ⟨h₁, h₂, h₃⟩ := h` produces the hypotheses `h₁ : p`, `h₂ : q`, and `h₃ : r`.
- The syntax `have (eq := h) pat := e` is equivalent to `match h : e with | pat => _`, which adds the equation `h : e = pat` to the local context.

The tactic supports all the same syntax variants and options as the `have` term.

**Properties and relations**

- It is not possible to unfold a variable introduced using `have`, since the definition's value is forgotten. The `let` tactic introduces definitions that can be unfolded.
- The `have h : t := e` is like doing `let h : t := e; clear_value h`.
- The `have` tactic is preferred for propositions, and `let` is preferred for non-propositions.
- Sometimes `have` is used for non-propositions to ensure that the variable is never unfolded, which may be important for performance reasons. Consider using the equivalent `let +nondep` to indicate the intent.

<a id="have___"></a>

**tactic**

```text
have'
```

Similar to `have`, but using `refine'`

<a id="let"></a>

**tactic**

```text
let
```

The `let` tactic is for adding definitions to the local context of the main goal. The definition can be unfolded, unlike definitions introduced by `have`.

- `let x : t := e` adds the definition `x : t := e` if `e` is a term of type `t`.
- `let x := e` uses the type of `e` for `t`.
- `let : t := e` and `let := e` use `this` for the name of the hypothesis.
- `let pat := e` for a pattern `pat` is equivalent to `match e with | pat => _`, where `_` stands for the tactics that follow this one. It is convenient for types that let only one applicable constructor. For example, given `p : α × β × γ`, `let ⟨x, y, z⟩ := p` produces the local variables `x : α`, `y : β`, and `z : γ`.
- The syntax `let (eq := h) pat := e` is equivalent to `match h : e with | pat => _`, which adds the equation `h : e = pat` to the local context.

The tactic supports all the same syntax variants and options as the `let` term.

**Properties and relations**

- Unlike `have`, it is possible to unfold definitions introduced using `let`, using tactics such as `simp`, `dsimp`, `unfold`, and `subst`.
- The `clear_value` tactic turns a `let` definition into a `have` definition after the fact. The tactic might fail if the local context depends on the value of the variable.
- The `let` tactic is preferred for data (non-propositions).
- Sometimes `have` is used for non-propositions to ensure that the variable is never unfolded, which may be important for performance reasons.

<a id="let-rec"></a>

**tactic**

```text
let rec
```

`let rec f : t := e` adds a recursive definition `f` to the current goal. The syntax is the same as term-mode `let rec`.

The tactic supports all the same syntax variants and options as the `let` term.

<a id="letI"></a>

**tactic**

```text
letI
```

`letI` behaves like `let`, but inlines the value instead of producing a `let` term.

<a id="let___"></a>

**tactic**

```text
let'
```

Similar to `let`, but using `refine'`

<a id="tactic-config"></a>
### 14.3.5. Configuration

Many tactics are configurable.
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
 By convention, tactics share a configuration syntax, described using 

```ebnf
optConfig
```

. The specific options available to each tactic are described in the tactic's documentation.

<a id="Lean___Parser___Tactic___optConfig"></a>

**syntax**

**Tactic Configuration**

A tactic configuration consists of zero or more 
<a id="--tech-term-configuration-items"></a>
configuration items:

<a id="Lean___Parser___Tactic___optConfig-next"></a>

```ebnf
optConfig ::=
    configItem*
```

<a id="Lean___Parser___Tactic___configItem"></a>

**syntax**

**Tactic Configuration Items**

Each configuration item has a name that corresponds to an underlying tactic option. Boolean options may be enabled or disabled using prefix `+` and `-`:

<a id="Lean___Parser___Tactic___configItem-next"></a>

```ebnf
configItem ::=
    +ident
```

<a id="Lean___Parser___Tactic___configItem-next-next"></a>

```ebnf
configItem ::= ...
    | -ident
```

Options may be assigned specific values using a syntax similar to that for named function arguments:

<a id="Lean___Parser___Tactic___configItem-next-next-next"></a>

```ebnf
configItem ::= ...
    | (ident := term)
```

Finally, the name `config` is reserved; it is used to pass an entire set of options as a data structure. The specific type expected depends on the tactic.

<a id="Lean___Parser___Tactic___configItem-next-next-next-next"></a>

```ebnf
configItem ::= ...
    | (config := term)
```

<a id="tactic-language-namespaces-options"></a>
### 14.3.6. Namespace and Option Management

Namespaces and options can be adjusted in tactic scripts using the same syntax as in terms.

<a id="set_option"></a>

**tactic**

```text
set_option
```

`set_option opt val in tacs` (the tactic) acts like `set_option opt val` at the command level, but it sets the option only within the tactics `tacs`.

<a id="open"></a>

**tactic**

```text
open
```

`open Foo in tacs` (the tactic) acts like `open Foo` at command level, but it opens a namespace only within the tactics `tacs`.

<a id="tactic-language-unfolding"></a>
#### 14.3.6.1. Controlling Unfolding

By default, only definitions marked reducible are unfolded, except when checking definitional equality. These operators allow this default to be adjusted for some part of a tactic script.

<a id="with_reducible_and_instances"></a>

**tactic**

```text
with_reducible_and_instances
```

`with_reducible_and_instances tacs` executes `tacs` using the `.instances` transparency setting. In this setting only definitions tagged as `[reducible]` or type class instances are unfolded.

<a id="with_reducible"></a>

**tactic**

```text
with_reducible
```

`with_reducible tacs` executes `tacs` using the reducible transparency setting. In this setting only definitions tagged as `[reducible]` are unfolded.

<a id="with_unfolding_all"></a>

**tactic**

```text
with_unfolding_all
```

`with_unfolding_all tacs` executes `tacs` using the `.all` transparency setting. In this setting all definitions that are not opaque are unfolded.

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Configuration options for tactics.
```


### Display 2


```text
A configuration item for a tactic configuration.
```


### Display 3


```text
`+opt` is short for `(opt := true)`. It sets the `opt` configuration option to `true`.
```


### Display 4


```text
`-opt` is short for `(opt := false)`. It sets the `opt` configuration option to `false`.
```


### Display 5


```text
`(opt := val)` sets the `opt` configuration option to `val`.

As a special case, `(config := ...)` sets the entire configuration.
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
n:Nat⊢ if n = 0 then n < 1 else n > 0
```


### Display 2


```text
n:Nath✝:n = 0⊢ if n = 0 then n < 1 else n > 0
```


### Display 3


```text
All goals completed! 🐙
```


### Display 4


```text
n:Nath✝:¬n = 0⊢ if n = 0 then n < 1 else n > 0
```


### Display 5


```text
n:Nath✝:¬n = 0⊢ 0 < n
```


### Display 6


```text
n:Nat⊢ n = n
```


### Display 7


```text
n:Nat⊢ 0 = 0
```


### Display 8


```text
n:Nati:Nat⊢ i + 1 = i + 1
```


### Display 9


```text
n:Nat⊢ if 0 = 0 then 0 < 1 else 0 > 0
```


### Display 10


```text
n:Natk:Nat⊢ if k + 1 = 0 then k + 1 < 1 else k + 1 > 0
```


### Display 11


```text
x:Nath:x = 1 ∨ x = 2⊢ x < 3
```


### Display 12


```text
inlx:Nath✝:x = 1⊢ x < 3inrx:Nath✝:x = 2⊢ x < 3
```


### Display 13


```text
inrx:Nath✝:x = 2⊢ x < 3
```


### Display 14


```text
⊢ ∀ (n : Nat), 0 + n = n
```


### Display 15


```text
n✝:Nat⊢ 0 + n✝ = n✝
```


### Display 16


```text
n:Nat⊢ 0 + n = n
```

