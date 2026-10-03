<a id="conv"></a>

# ProofScript — 14.6. Targeted Rewriting with conv

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Tactics construct proof terms, and the checker decides whether those terms prove the requested claim. Use the inherited tactic language, including goal management, rewriting, induction and conv. Semicolon sequencing and the apply-to-all-goals combinator are distinct. Native grammar displays and tactic signatures below describe the selected environment, not a second ProofScript tactic system.

**Compiler and coverage boundary.** Term decorations may appear only in explicitly lifted tactic term slots. Preserve goal names, hygiene and source maps. Search failure is not proof of falsity.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Tactic-Proofs/Targeted-Rewriting-with--conv/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Tactic-Proofs/Targeted-Rewriting-with--conv/index.html). Source Git blob: `3a386c8ff7f806bdcc8b42ec4b551e266e2bd535`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 14.6. Targeted Rewriting with conv

The `conv`, or conversion, tactic allows targeted rewriting within a goal. The argument to `conv` is written in a separate language that interoperates with the main tactic language; it features commands to navigate to specific subterms within the goal along with commands that allow these subterms to be rewritten. `conv` is useful when rewrites should only be applied in part of a goal (e.g. only on one side of an equality), rather than across the board, or when rewrites should be applied underneath a binder that prevents tactics like `rw` from accessing the term.

The conversion tactic language is very similar to the main tactic language: it uses the same proof states, tactics work primarily on the main goal and may either fail or succeed with a sequence of new goals, and macro expansion is interleaved with tactic execution. Unlike the main tactic language, in which tactics are intended to eventually solve goals, the `conv` tactic is used to *change* a goal so that it becomes amenable to further processing in the main tactic language. Goals that are intended to be rewritten with `conv` are shown with a vertical bar instead of a turnstile.

<a id="conv-next"></a>

**tactic**

```text
conv
```

`conv => ...` allows the user to perform targeted rewriting on a goal or hypothesis, by focusing on particular subexpressions.

See [https://lean-lang.org/theorem_proving_in_lean4/conv.html](https://lean-lang.org/theorem_proving_in_lean4/conv.html) for more details.

Basic forms:

- `conv => cs` will rewrite the goal with conv tactics `cs`.
- `conv at h => cs` will rewrite hypothesis `h`.
- `conv in pat => cs` will rewrite the first subexpression matching `pat` (see `pattern`).

<a id="Navigation-and-Rewriting-with--conv"></a>
Navigation and Rewriting with `conv` 

In this example, there are multiple instances of addition, and `rw` would by default rewrite the first instance that it encounters. Using `conv` to navigate to the specific subterm before rewriting leaves `rw` no choice but to rewrite the correct term.

```proofscript
example (x y z : Nat) : x + (y + z) = (x + z) + y := by
  conv =>
    lhs
    arg 2
    rw [Nat.add_comm]
  rw [Nat.add_assoc]
```

<a id="Rewriting-Under-Binders-with--conv"></a>
Rewriting Under Binders with `conv` 

In this example, addition occurs under binders, so `rw` can't be used. However, after using `conv` to navigate to the function body, it succeeds. The nested use of `conv` causes control to return to the current position in the term after performing further conversions on one of its subterms. Because the goal is a reflexive equation after rewriting, `conv` automatically closes it.

```proofscript
example :
    (fun (x y z : Nat) =>
      x + (y + z))
    =
    (fun x y z =>
      (z + x) + y)
  := by
  conv =>
    lhs
    intro x y z
    conv =>
      arg 2
      rw [Nat.add_comm]
    rw [← Nat.add_assoc]
    arg 1
    rw [Nat.add_comm]
```

<a id="conv-control"></a>
### 14.6.1. Control Structures

<a id="Lean___Parser___Tactic___Conv___first"></a>

**conv tactic**

```text
first
```

`first | conv | ...` runs each `conv` until one succeeds, or else fails.

<a id="Lean___Parser___Tactic___Conv___convTry_"></a>

**conv tactic**

```text
try
```

`try tac` runs `tac` and succeeds even if `tac` failed.

<a id="Lean___Parser___Tactic___Conv____FLQQ_conv__LT__SEMI__GT___FLQQ_"></a>

**conv tactic**

```text
<;>
```

`tac <;> tac'` runs `tac` on the main goal and `tac'` on each produced goal, concatenating all goals produced by `tac'`.

<a id="Lean___Parser___Tactic___Conv___convRepeat_"></a>

**conv tactic**

```text
repeat
```

`repeat convs` runs the sequence `convs` repeatedly until it fails to apply.

<a id="Lean___Parser___Tactic___Conv___skip"></a>

**conv tactic**

```text
skip
```

`skip` does nothing.

<a id="Lean___Parser___Tactic___Conv___nestedConv"></a>

**conv tactic**

```text
{ ... }
```

`{ convs }` runs the list of `convs` on the current target, and any subgoals that remain are trivially closed by `skip`.

<a id="Lean___Parser___Tactic___Conv___paren"></a>

**conv tactic**

```text
( ... )
```

`(convs)` runs the `convs` in sequence on the current list of targets. This is pure grouping with no added effects.

<a id="Lean___Parser___Tactic___Conv___convDone"></a>

**conv tactic**

```text
done
```

`done` succeeds iff there are no goals remaining.

<a id="conv-goals"></a>
### 14.6.2. Goal Selection

<a id="Lean___Parser___Tactic___Conv___allGoals"></a>

**conv tactic**

```text
all_goals
```

`all_goals tac` runs `tac` on each goal, concatenating the resulting goals, if any.

<a id="Lean___Parser___Tactic___Conv___anyGoals"></a>

**conv tactic**

```text
any_goals
```

`any_goals tac` applies the tactic `tac` to every goal, and succeeds if at least one application succeeds.

<a id="Lean___Parser___Tactic___Conv___case"></a>

**conv tactic**

```text
case ... => ...
```

- `case tag => tac` focuses on the goal with case name `tag` and solves it using `tac`, or else fails.
- `case tag x₁ ... xₙ => tac` additionally renames the `n` most recent hypotheses with inaccessible names to the given names.
- `case tag₁ | tag₂ => tac` is equivalent to `(case tag₁ => tac); (case tag₂ => tac)`.

<a id="Lean___Parser___Tactic___Conv___case___"></a>

**conv tactic**

```text
case' ... => ...
```

`case'` is similar to the `case tag => tac` tactic, but does not ensure the goal has been solved after applying `tac`, nor admits the goal if `tac` failed. Recall that `case` closes the goal using `sorry` when `tac` fails, and the tactic execution is not interrupted.

<a id="Lean___Parser___Tactic___Conv____FLQQ_convNext______GT___FLQQ_"></a>

**conv tactic**

```text
next ... => ...
```

`next => tac` focuses on the next goal and solves it using `tac`, or else fails. `next x₁ ... xₙ => tac` additionally renames the `n` most recent hypotheses with inaccessible names to the given names.

<a id="Lean___Parser___Tactic___Conv___focus"></a>

**conv tactic**

```text
focus
```

`focus tac` focuses on the main goal, suppressing all other goals, and runs `tac` on it. Usually `· tac`, which enforces that the goal is closed by `tac`, should be preferred.

<a id="Lean___Parser___Tactic___Conv____FLQQ_conv_____FLQQ_"></a>

**conv tactic**

```text
· ...
```

`· conv` focuses on the main conv goal and tries to solve it using `s`.

<a id="Lean___Parser___Tactic___Conv___failIfSuccess"></a>

**conv tactic**

```text
fail_if_success
```

`fail_if_success t` fails if the tactic `t` succeeds.

<a id="conv-nav"></a>
### 14.6.3. Navigation

<a id="Lean___Parser___Tactic___Conv___lhs"></a>

**conv tactic**

```text
lhs
```

Traverses into the left subterm of a binary operator.

In general, for an `n`-ary operator, it traverses into the second to last argument. It is a synonym for `arg -2`.

<a id="Lean___Parser___Tactic___Conv___rhs"></a>

**conv tactic**

```text
rhs
```

Traverses into the right subterm of a binary operator.

In general, for an `n`-ary operator, it traverses into the last argument. It is a synonym for `arg -1`.

<a id="Lean___Parser___Tactic___Conv___fun"></a>

**conv tactic**

```text
fun
```

Traverses into the function of a (unary) function application. For example, `| f a b` turns into `| f a`. (Use `arg 0` to traverse into `f`.)

<a id="Lean___Parser___Tactic___Conv___congr"></a>

**conv tactic**

```text
congr
```

Performs one step of "congruence", which takes a term and produces subgoals for all the function arguments. For example, if the target is `f x y` then `congr` produces two subgoals, one for `x` and one for `y`.

<a id="Lean___Parser___Tactic___Conv___arg"></a>

**conv tactic**

```text
arg [@]i
```

- `arg i` traverses into the `i`'th argument of the target. For example if the target is `f a b c d` then `arg 1` traverses to `a` and `arg 3` traverses to `c`. The index may be negative; `arg -1` traverses into the last argument, `arg -2` into the second-to-last argument, and so on.
- `arg @i` is the same as `arg i` but it counts all arguments instead of just the explicit arguments.
- `arg 0` traverses into the function. If the target is `f a b c d`, `arg 0` traverses into `f`.

<a id="Lean___Parser___Tactic___Conv___enterArg"></a>

**syntax**

**Arguments to enter**

<a id="Lean___Parser___Tactic___Conv___enterArg-next"></a>

```ebnf
enterArg ::= ...
    | num
```

<a id="Lean___Parser___Tactic___Conv___enterArg-next-next"></a>

```ebnf
enterArg ::= ...
    | @num
```

<a id="Lean___Parser___Tactic___Conv___enterArg-next-next-next"></a>

```ebnf
enterArg ::= ...
    | ident
```

<a id="Lean___Parser___Tactic___Conv___enter"></a>

**conv tactic**

```text
enter
```

`enter [arg, ...]` is a compact way to describe a path to a subterm. It is a shorthand for other conv tactics as follows:

- `enter [i]` is equivalent to `arg i`.
- `enter [@i]` is equivalent to `arg @i`.
- `enter [x]` (where `x` is an identifier) is equivalent to `ext x`.
- `enter [in e]` (where `e` is a term) is equivalent to `pattern e`. Occurrences can be specified with `enter [in (occs := ...) e]`. For example, given the target `f (g a (fun x => x b))`, `enter [1, 2, x, 1]` will traverse to the subterm `b`.

<a id="Lean___Parser___Tactic___Conv___pattern"></a>

**conv tactic**

```text
pattern
```

- `pattern pat` traverses to the first subterm of the target that matches `pat`.
- `pattern (occs := *) pat` traverses to every subterm of the target that matches `pat` which is not contained in another match of `pat`. It generates one subgoal for each matching subterm.
- `pattern (occs := 1 2 4) pat` matches occurrences `1, 2, 4` of `pat` and produces three subgoals. Occurrences are numbered left to right from the outside in.

Note that skipping an occurrence of `pat` will traverse inside that subexpression, which means it may find more matches and this can affect the numbering of subsequent pattern matches. For example, if we are searching for `f _` in `f (f a) = f b`:

- `occs := 1 2` (and `occs := *`) returns `| f (f a)` and `| f b`
- `occs := 2` returns `| f a`
- `occs := 2 3` returns `| f a` and `| f b`
- `occs := 1 3` is an error, because after skipping `f b` there is no third match.

<a id="Lean___Parser___Tactic___Conv___ext"></a>

**conv tactic**

```text
ext
```

`ext x` traverses into a binder (a `fun x => e` or `∀ x, e` expression) to target `e`, introducing name `x` in the process.

<a id="Lean___Parser___Tactic___Conv___convArgs"></a>

**conv tactic**

```text
args
```

`args` traverses into all arguments. Synonym for `congr`.

<a id="Lean___Parser___Tactic___Conv___convLeft"></a>

**conv tactic**

```text
left
```

`left` traverses into the left argument. Synonym for `lhs`.

<a id="Lean___Parser___Tactic___Conv___convRight"></a>

**conv tactic**

```text
right
```

`right` traverses into the right argument. Synonym for `rhs`.

<a id="Lean___Parser___Tactic___Conv___convIntro___"></a>

**conv tactic**

```text
intro
```

`intro` traverses into binders. Synonym for `ext`.

<a id="conv-change"></a>
### 14.6.4. Changing the Goal

<a id="conv-reduction"></a>
#### 14.6.4.1. Reduction

<a id="Lean___Parser___Tactic___Conv___cbv"></a>

**conv tactic**

```text
cbv
```

`cbv` performs simplification that closely mimics call-by-value evaluation. It reduces the target term by unfolding definitions using their defining equations and applying matcher equations. The unfolding is propositional, so `cbv` also works with functions defined via well-founded recursion or partial fixpoints.

The proofs produced by `cbv` only use the three standard axioms. In particular, they do not require trust in the correctness of the code generator.

<a id="The--cbv--Tactic"></a>
The `cbv` Tactic 

The `cbv` tactic can be used to reduce functions, including ones that are defined via [well-founded recursion](../../Definitions/Recursive-Definitions/index.md#well-founded-recursion), which are otherwise irreducible. Ordinarily, `f` is only propositionally equal to its unfolding, so `rfl` can't prove the equality `f 5 = 5`:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="f-_LPAR_in-The--cbv--Tactic_RPAR_"></a>


```proofscript
function f (n : Nat) :=
  match n with
  | 0 => 0
  | n + 1 => f n + 1
termination_by (n,0)
```

```proofscript
example : f 5 = 5 := by rfl
```

```lean
Tactic `rfl` failed: The left-hand side
  f 5
is not definitionally equal to the right-hand side
  5

⊢ f 5 = 5
```

Using `cbv` on the left-hand side of the equality, the statement can be made true:

```proofscript
example : f 5 = 5 := by
  conv =>
    lhs
    cbv
```

<a id="Lean___Parser___Tactic___Conv___whnf"></a>

**conv tactic**

```text
whnf
```

Reduces the target to Weak Head Normal Form. This reduces definitions in "head position" until a constructor is exposed. For example, `List.map f [a, b, c]` weak head normalizes to `f a :: List.map f [b, c]`.

<a id="Lean___Parser___Tactic___Conv___reduce"></a>

**conv tactic**

```text
reduce
```

Puts term in normal form, this tactic is meant for debugging purposes only.

<a id="Lean___Parser___Tactic___Conv___zeta"></a>

**conv tactic**

```text
zeta
```

Expands let-declarations and let-variables.

<a id="Lean___Parser___Tactic___Conv___delta"></a>

**conv tactic**

```text
delta
```

`delta id1 id2 ...` unfolds all occurrences of `id1`, `id2`, ... in the target. Like the `delta` tactic, this ignores any definitional equations and uses primitive delta-reduction instead, which may result in leaking implementation details. Users should prefer `unfold` for unfolding definitions.

<a id="Lean___Parser___Tactic___Conv___unfold"></a>

**conv tactic**

```text
unfold
```

- `unfold id` unfolds all occurrences of definition `id` in the target.
- `unfold id1 id2 ...` is equivalent to `unfold id1; unfold id2; ...`.

Definitions can be either global or local definitions.

For non-recursive global definitions, this tactic is identical to `delta`. For recursive global definitions, it uses the "unfolding lemma" `id.eq_def`, which is generated for each recursive definition, to unfold according to the recursive definition given by the user. Only one level of unfolding is performed, in contrast to `simp only [id]`, which unfolds definition `id` recursively.

This is the `conv` version of the `unfold` tactic.

<a id="conv-simp"></a>
#### 14.6.4.2. Simplification

<a id="Lean___Parser___Tactic___Conv___simp"></a>

**conv tactic**

```text
simp
```

`simp [thm]` performs simplification using `thm` and marked `@[simp]` lemmas. See the `simp` tactic for more information.

<a id="Lean___Parser___Tactic___Conv___dsimp"></a>

**conv tactic**

```text
dsimp
```

`dsimp` is the definitional simplifier in `conv`-mode. It differs from `simp` in that it only applies theorems that hold by reflexivity.

Examples:

```proofscript
example (a : Nat): (0 + 0) = a - a := by
  conv =>
    lhs
    dsimp
    rw [← Nat.sub_self a]
```

<a id="Lean___Parser___Tactic___Conv___simpMatch"></a>

**conv tactic**

```text
simp_match
```

`simp_match` simplifies match expressions. For example,

```proofscript
match [a, b] with
| [] => 0
| hd :: tl => hd
```

simplifies to `a`.

<a id="conv-rw"></a>
#### 14.6.4.3. Rewriting

<a id="Lean___Parser___Tactic___Conv___change"></a>

**conv tactic**

```text
change
```

`change t'` replaces the target `t` with `t'`, assuming `t` and `t'` are definitionally equal.

<a id="Lean___Parser___Tactic___Conv___rewrite"></a>

**conv tactic**

```text
rewrite
```

`rw [thm]` rewrites the target using `thm`. See the `rw` tactic for more information.

<a id="Lean___Parser___Tactic___Conv___convRw__"></a>

**conv tactic**

```text
rw
```

`rw [rules]` applies the given list of rewrite rules to the target. See the `rw` tactic for more information.

<a id="Lean___Parser___Tactic___Conv___convErw__"></a>

**conv tactic**

```text
erw
```

`erw [rules]` is a shorthand for `rw (transparency := .default) [rules]`. This does rewriting up to unfolding of regular definitions (by comparison to regular `rw` which only unfolds `@[reducible]` definitions).

<a id="Lean___Parser___Tactic___Conv___convApply_"></a>

**conv tactic**

```text
apply
```

The `apply thm` conv tactic is the same as `apply thm` the tactic. There are no restrictions on `thm`, but strange results may occur if `thm` cannot be reasonably interpreted as proving one equality from a list of others.

<a id="conv-nested"></a>
### 14.6.5. Nested Tactics

<a id="conv___"></a>

**tactic**

```text
conv'
```

Executes the given conv block without converting regular goal into a `conv` goal.

<a id="Lean___Parser___Tactic___Conv___nestedTactic"></a>

**conv tactic**

```text
tactic
```

Focuses, converts the `conv` goal `⊢ lhs` into a regular goal `⊢ lhs = rhs`, and then executes the given tactic block.

<a id="Lean___Parser___Tactic___Conv___nestedTacticCore"></a>

**conv tactic**

```text
tactic'
```

Executes the given tactic block without converting `conv` goal into a regular goal.

<a id="conv___-next"></a>

**tactic**

```text
conv'
```

Executes the given conv block without converting regular goal into a `conv` goal.

<a id="Lean___Parser___Tactic___Conv___convConvSeq"></a>

**conv tactic**

```text
conv => ...
```

`conv => cs` runs `cs` in sequence on the target `t`, resulting in `t'`, which becomes the new target subgoal.

<a id="conv-debug"></a>
### 14.6.6. Debugging Utilities

<a id="Lean___Parser___Tactic___Conv___convTrace_state"></a>

**conv tactic**

```text
trace_state
```

`trace_state` prints the current goal state.

<a id="conv-other"></a>
### 14.6.7. Other

<a id="Lean___Parser___Tactic___Conv___convRfl"></a>

**conv tactic**

```text
rfl
```

`rfl` closes one conv goal "trivially", by using reflexivity (that is, no rewriting).

<a id="Lean___Parser___Tactic___Conv___normCast"></a>

**conv tactic**

```text
norm_cast
```

`norm_cast` tactic in `conv` mode.

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`binderIdent` matches an `ident` or a `_`. It is used for identifiers in binding
position, where `_` means that the value should be left unnamed and inaccessible.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Tactic `rfl` failed: The left-hand side
  f 5
is not definitionally equal to the right-hand side
  5

⊢ f 5 = 5
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
x:Naty:Natz:Nat⊢ x + (y + z) = x + z + y
```


### Display 2


```text
x:Naty:Natz:Nat| x + (y + z) = x + z + y
```


### Display 3


```text
x:Naty:Natz:Nat| x + (y + z)
```


### Display 4


```text
x:Naty:Natz:Nat| y + z
```


### Display 5


```text
x:Naty:Natz:Nat| z + y
```


### Display 6


```text
x:Naty:Natz:Nat⊢ x + (z + y) = x + (z + y)
```


### Display 7


```text
All goals completed! 🐙
```


### Display 8


```text
⊢ (fun x y z => x + (y + z)) = fun x y z => z + x + y
```


### Display 9


```text
| (fun x y z => x + (y + z)) = fun x y z => z + x + y
```


### Display 10


```text
| fun x y z => x + (y + z)
```


### Display 11


```text
x:Naty:Natz:Nat| x + z + y
```


### Display 12


```text
x:Naty:Natz:Nat| x + z
```


### Display 13


```text
x:Naty:Natz:Nat| z + x
```


### Display 14


```text
⊢ f 5 = 5
```


### Display 15


```text
| f 5 = 5
```


### Display 16


```text
| f 5
```


### Display 17


```text
| 5
```


### Display 18


```text
a:Nat⊢ 0 + 0 = a - a
```


### Display 19


```text
a:Nat| 0 + 0 = a - a
```


### Display 20


```text
a:Nat| 0 + 0
```


### Display 21


```text
a:Nat| 0
```


### Display 22


```text
a:Nat| a - a
```

