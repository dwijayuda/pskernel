<a id="grind-bigger-examples"></a>

# ProofScript — 16.14. Bigger Examples

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

grind combines reasoning such as congruence closure, propagation, case analysis, E-matching and algebraic/arithmetic procedures. Its selected lemmas, annotations and solver parameters determine the search problem. Keep these as native proof-producing facilities, not as a replacement for the kernel. The mirrored subchapters and examples retain their individual scopes and failure cases.

**Compiler and coverage boundary.** Lean 4.34 stable parameter-list changes for lia/grobner are inherited only under the selected tactic capability. A timeout must remain an incomplete-search result.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The--grind--tactic/Bigger-Examples/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The--grind--tactic/Bigger-Examples/index.html). Source Git blob: `660470282132d6b003c5744c0cff1a07f7aee8cc`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="R"></a>
<a id="instCommRingR"></a>
<a id="sin"></a>
<a id="cos"></a>
<a id="trig_identity"></a>

---

## 16.14. Bigger Examples

<a id="The-Lean-Language-Reference--The--grind--tactic--Bigger-Examples--Integrating--grind-___s-Features"></a>
### 16.14.1. Integrating grind's Features

This example demonstrates how the various submodules of `grind` are seamlessly integrated. In particular we can:

- instantiate theorems from the library, using custom patterns,
- perform case splitting,
- do linear integer arithmetic reasoning, including modularity conditions, and
- do Gröbner basis reasoning all without providing explicit instructions to drive the interactions between these modes of reasoning.

For this example we'll begin with a “mocked up” version of the real numbers, and the `sin` and `cos` functions. Of course, this example works [without any changes](https://github.com/leanprover-community/mathlib4/blob/master/MathlibTest/grind/trig.lean) using Mathlib's versions of these!

```proofscript
axiom R : Type

@[instance] axiom instCommRingR : Lean.Grind.CommRing R

axiom sin : R → R
axiom cos : R → R
axiom trig_identity : ∀ x, (cos x)^2 + (sin x)^2 = 1
```

Our first step is to tell grind to “put the trig identity on the whiteboard” whenever it sees a goal involving `sin` or `cos`:

```proofscript
grind_pattern trig_identity => cos x
grind_pattern trig_identity => sin x
```

Note here we use **two** different patterns for the same theorem, so the theorem is instantiated even if `grind` sees just one of these functions. If we preferred to more conservatively instantiate the theorem only when both `sin` and `cos` are present, we could have used a multi-pattern:

```proofscript
grind_pattern trig_identity => cos x, sin x
```

For this example, either approach will work.

Because `grind` immediately notices the trig identity, we can prove goals like this:

```proofscript
example : (cos x + sin x)^2 = 2 * cos x * sin x + 1 := by
  grind
```

Here `grind` does the following:

1. It notices `cos x` and `sin x`, so instantiates the trig identity.
2. It notices that this is a polynomial in `CommRing R`, and sends it to the Gröbner basis module. No calculation happens at this point: it's the first polynomial relation in this ring, so the Gröbner basis is updated to `[(cos x)^2 + (sin x)^2 - 1]`.
3. It notices that the left and right hand sides of the goal are polynomials in `CommRing R`, and sends them to the Gröbner basis module for normalization.

Since their normal forms modulo `(cos x)^2 + (sin x)^2 = 1` are equal, their equivalence classes are merged, and the goal is solved.

We can also do this sort of argument when [congruence closure](../Congruence-Closure/index.md#--tech-term-Congruence-closure) is needed:

```proofscript
example (f : R → Nat) :
    f ((cos x + sin x)^2) = f (2 * cos x * sin x + 1) := by
  grind
```

As before, `grind` instantiates the trig identity, notices that `(cos x + sin x)^2` and `2 * cos x * sin x + 1` are equal modulo `(cos x)^2 + (sin x)^2 = 1`, puts those algebraic expressions in the same equivalence class, and then puts the function applications `f ((cos x + sin x)^2)` and `f (2 * cos x * sin x + 1)` in the same equivalence class, and closes the goal.

Notice that we've used an arbitrary function `f : R → Nat` here; let's check that `grind` can use some linear integer arithmetic reasoning after the Gröbner basis steps:

```proofscript
example (f : R → Nat) :
    4 * f ((cos x + sin x)^2) ≠ 2 + f (2 * cos x * sin x + 1) := by
  grind
```

Here `grind` first works out that this goal reduces to `4 * n ≠ 2 + n` for some `n : Nat` (i.e. by identifying the two function applications as described above), and then uses modularity to derive a contradiction.

Finally, we can also mix in some case splitting:

```proofscript
example (f : R → Nat) :
    max 3 (4 * f ((cos x + sin x)^2)) ≠
      2 + f (2 * cos x * sin x + 1) := by
  grind
```

As before, `grind` first does the instantiation and Gröbner basis calculations required to identify the two function applications. However the `cutsat` algorithm by itself can't do anything with `max 3 (4 * n) ≠ 2 + n`. Next, after instantiating `Nat.max_def` (automatically, because of an annotation in the standard library) which states `∀ {n m : Nat}, max n m = if n ≤ m then m else n`, `grind` can then case split on the inequality. In the branch `3 ≤ 4 * n`, `cutsat` again uses modularity to prove `4 * n ≠ 2 + n`. In the branch `4 * n < 3`, `cutsat` quickly determines `n = 0`, and then notices that `4 * 0 ≠ 2 + 0`.

This has been, of course, a quite artificial example! In practice, this sort of automatic integration of different reasoning modes is very powerful: the central “whiteboard” which tracks instantiated theorems and equivalence classes can hand off relevant terms and equalities to the appropriate modules (here, `cutsat` and Gröbner bases), which can then return new facts to the whiteboard.

<a id="grind-if-then-else-norm"></a>
### 16.14.2. if-then-else Normalization

This example is a showcase for the “out of the box” power of `grind`. Later examples will explore adding `@[grind]` annotations as part of the development process, to make `grind` more effective in a new domain. This example does not rely on any of the algebra extensions to `grind`, we're just using:

- instantiation of annotated theorems from the library,
- [congruence closure](../Congruence-Closure/index.md#--tech-term-Congruence-closure), and
- case splitting.

The solution here builds on an earlier formalization by Chris Hughes, but with some notable improvements:

- the verification is separate from the code,
- the proof is now a one-liner combining `fun_induction` and `grind`,
- the proof is robust to changes in the code (e.g. swapping out `HashMap` for `TreeMap`) as well as changes to the precise verification conditions.

<a id="The-Lean-Language-Reference--The--grind--tactic--Bigger-Examples--if---then---else--Normalization--The-problem"></a>
#### 16.14.2.1. The problem

Here is Rustan Leino's original description of the problem, as [posted by Leonardo de Moura](https://leanprover.zulipchat.com/#narrow/stream/113488-general/topic/Rustan's.20challenge) on the Lean Zulip:

> The data structure is an expression with Boolean literals, variables, and if-then-else expressions.
> 
>  
> 
> The goal is to normalize such expressions into a form where: a) No nested ifs: the condition part of an if-expression is not itself an if-expression b) No constant tests: the condition part of an if-expression is not a constant c) No redundant ifs: the then and else branches of an if are not the same d) Each variable is evaluated at most once: the free variables of the condition are disjoint from those in the then branch, and also disjoint from those in the else branch.
> 
>  
> 
> One should show that a normalization function produces an expression satisfying these four conditions, and one should also prove that the normalization function preserves the meaning of the given expression.

<a id="The-Lean-Language-Reference--The--grind--tactic--Bigger-Examples--if---then---else--Normalization--The-Formal-Statement"></a>
#### 16.14.2.2. The Formal Statement

To formalize the statement in Lean, we use an inductive type `IfExpr`:
<a id="IfExpr"></a>
<a id="IfExpr___lit"></a>
<a id="IfExpr___var"></a>
<a id="IfExpr___ite"></a>


```proofscript
/--
An if-expression is either boolean literal, a
numbered variable, or an if-then-else expression
where each subexpression is an if-expression.
-/
inductive IfExpr
  | lit : Bool → IfExpr
  | var : Nat → IfExpr
  | ite : IfExpr → IfExpr → IfExpr → IfExpr
deriving DecidableEq
```

and define some inductive predicates and an `eval` function, so we can state the four desired properties:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="IfExpr___hasNestedIf"></a>
<a id="IfExpr___hasConstantIf"></a>
<a id="IfExpr___hasRedundantIf"></a>
<a id="IfExpr___vars"></a>
<a id="List___disjoint"></a>
<a id="IfExpr___disjoint"></a>
<a id="IfExpr___normalized"></a>
<a id="IfExpr___eval"></a>


```proofscript
namespace IfExpr

/--
An if-expression has a "nested if" if it contains
an if-then-else where the "if" is itself an if-then-else.
-/
def hasNestedIf : IfExpr → Bool
  | lit _ => false
  | var _ => false
  | ite (ite _ _ _) _ _ => true
  | ite _ t e => t.hasNestedIf || e.hasNestedIf

/--
An if-expression has a "constant if" if it contains
an if-then-else where the "if" is itself a literal.
-/
def hasConstantIf : IfExpr → Bool
  | lit _ => false
  | var _ => false
  | ite (lit _) _ _ => true
  | ite i t e =>
    i.hasConstantIf || t.hasConstantIf || e.hasConstantIf

/--
An if-expression has a "redundant if" if
it contains an if-then-else where
the "then" and "else" clauses are identical.
-/
def hasRedundantIf : IfExpr → Bool
  | lit _ => false
  | var _ => false
  | ite i t e => t == e || i.hasRedundantIf ||
      t.hasRedundantIf || e.hasRedundantIf

/--
All the variables appearing in an if-expressions,
read left to right, without removing duplicates.
-/
def vars : IfExpr → List Nat
  | lit _ => []
  | var i => [i]
  | ite i t e => i.vars ++ t.vars ++ e.vars

/--
A helper function to specify that two lists are disjoint.
-/
def _root_.List.disjoint {α} [DecidableEq α] :
    List α → List α → Bool
  | [], _ => true
  | x::xs, ys => x ∉ ys && xs.disjoint ys

/--
An if expression evaluates each variable at most once if
for each if-then-else the variables in the "if" clause
are disjoint from the variables in the "then" clause
and the variables in the "if" clause
are disjoint from the variables in the "else" clause.
-/
def disjoint : IfExpr → Bool
  | lit _ => true
  | var _ => true
  | ite i t e =>
      i.vars.disjoint t.vars && i.vars.disjoint e.vars &&
        i.disjoint && t.disjoint && e.disjoint

/--
An if expression is "normalized" if it has
no nested, constant, or redundant ifs,
and it evaluates each variable at most once.
-/
function normalized (e : IfExpr) : Bool :=
  !e.hasNestedIf && !e.hasConstantIf &&
    !e.hasRedundantIf && e.disjoint

/--
The evaluation of an if expression
at some assignment of variables.
-/
def eval (f : Nat → Bool) : IfExpr → Bool
  | lit b => b
  | var i => f i
  | ite i t e => bif i.eval f then t.eval f else e.eval f

end IfExpr
```

Using these we can state the problem. The challenge is to inhabit the following type (and to do so nicely!):

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="IfNormalization"></a>


```proofscript
const IfNormalization : Type :=
  { Z : IfExpr → IfExpr // ∀ e, (Z e).normalized ∧ (Z e).eval = e.eval }
```

<a id="The-Lean-Language-Reference--The--grind--tactic--Bigger-Examples--if---then---else--Normalization--Other-solutions"></a>
#### 16.14.2.3. Other solutions

At this point, it's worth pausing and doing at least one of the following:

- Try to prove this yourself! It's quite challenging for a beginner! You can [have a go](https://live.lean-lang.org/#project=lean-nightly&url=https%3A%2F%2Fgist.githubusercontent.com%2Fkim-em%2Ff416b31fe29de8a3f1b2b3a84e0f1793%2Fraw%2F75ca61230b50c126f8658bacd933ecf7bfcaa4b8%2Fgrind_ite.lean) in the Live Lean editor without any installation.
- Read Chris Hughes's [solution](https://github.com/leanprover-community/mathlib4/blob/master/Archive/Examples/IfNormalization/Result.lean), which is included in the Mathlib Archive. This solution makes good use of Aesop, but is not ideal because

   

  1. It defines the solution using a subtype, simultaneously giving the construction and proving properties about it. We think it's better stylistically to keep these separate.
  2. Even with Aesop automation, there's still about 15 lines of manual proof work before we can hand off to Aesop.
- Read Wojciech Nawrocki's [solution](https://leanprover.zulipchat.com/#narrow/channel/113488-general/topic/Rustan's.20challenge/near/398824748). This one uses less automation, at about 300 lines of proof work.

<a id="The-Lean-Language-Reference--The--grind--tactic--Bigger-Examples--if---then---else--Normalization--The-solution-using--grind"></a>
#### 16.14.2.4. The solution using grind

Actually solving the problem is not that hard: we just need a recursive function that carries along a record of “already assigned variables”, and then, whenever performing a branch on a variable, adding a new assignment in each of the branches. It also needs to flatten nested if-then-else expressions which have another if-then-else in the “condition” position. (This is extracted from Chris Hughes's solution, but without the subtyping.)

Let's work inside the `IfExpr` namespace.

```proofscript
namespace IfExpr
```

```proofscript
def normalize (assign : Std.HashMap Nat Bool) :
    IfExpr → IfExpr
  | lit b => lit b
  | var v =>
    match assign[v]? with
    | none => var v
    | some b => lit b
  | ite (lit true)  t _ => normalize assign t
  | ite (lit false) _ e => normalize assign e
  | ite (ite a b c) t e =>
    normalize assign (ite a (ite b t e) (ite c t e))
  | ite (var v)     t e =>
    match assign[v]? with
    | none =>
      let t' := normalize (assign.insert v true) t
      let e' := normalize (assign.insert v false) e
      if t' = e' then t' else ite (var v) t' e'
    | some b => normalize assign (ite (lit b) t e)
```

This is pretty straightforward, but it immediately runs into a problem:

```lean
fail to show termination for
  IfExpr.normalize
with errors
failed to infer structural recursion:
Cannot use parameter assign:
  the type HashMap Nat Bool does not have a `.brecOn` recursor
Cannot use parameter #2:
  failed to eliminate recursive application
    normalize assign (a.ite (b.ite t e) (c.ite t e))

Could not find a decreasing measure.
```

Lean here is telling us that it can't see that the function is terminating. Often Lean is pretty good at working this out for itself, but for sufficiently complicated functions we need to step in to give it a hint.

In this case we can see that it's the recursive call `ite (ite a b c) t e` which is calling `normalize` on `(ite a (ite b t e) (ite c t e))` where Lean is having difficulty. Lean has made a guess at a plausible termination measure, based on using automatically generated `sizeOf` function, but can't prove the resulting goal, essentially because `t` and `e` appear multiple times in the recursive call.

To address problems like this, we nearly always want to stop using the automatically generated `sizeOf` function, and construct our own termination measure. We'll use
<a id="IfExpr___normSize"></a>


```proofscript
@[simp] def normSize : IfExpr → Nat
  | lit _ => 0
  | var _ => 1
  | .ite i t e => 2 * normSize i + max (normSize t) (normSize e) + 1
```

Many different functions would work here. The basic idea is to increase the “weight” of the “condition” branch (this is the multiplicative factor in the `2 * normSize i` ), so that as long the “condition” part shrinks a bit, the whole expression counts as shrinking even if the “then” and “else” branches have grown. We've annotated the definition with `@[simp]` so Lean's automated termination checker is allowed to unfold the definition.

With this in place, the definition goes through using the `termination_by` clause:

```proofscript
def normalize (assign : Std.HashMap Nat Bool) :
    IfExpr → IfExpr
  | lit b => lit b
  | var v =>
    match assign[v]? with
    | none => var v
    | some b => lit b
  | ite (lit true)  t _ => normalize assign t
  | ite (lit false) _ e => normalize assign e
  | ite (ite a b c) t e =>
    normalize assign (ite a (ite b t e) (ite c t e))
  | ite (var v)     t e =>
    match assign[v]? with
    | none =>
      let t' := normalize (assign.insert v true) t
      let e' := normalize (assign.insert v false) e
      if t' = e' then t' else ite (var v) t' e'
    | some b => normalize assign (ite (lit b) t e)
termination_by e => e.normSize
```

Now it's time to prove some properties of this function. We're just going to package together all the properties we want:

```proofscript
theorem normalize_spec
    (assign : Std.HashMap Nat Bool) (e : IfExpr) :
    (normalize assign e).normalized
      ∧ (∀ f, (normalize assign e).eval f =
          e.eval fun w => assign[w]?.getD (f w))
      ∧ ∀ (v : Nat),
          v ∈ vars (normalize assign e) → ¬ v ∈ assign :=
  sorry
```

That is:

- the result of `normalize` is actually normalized according to the initial definitions,
- if we normalize an “if-then-else” expression using some assignments, and then evaluate the remaining variables, we get the same result as evaluating the original “if-then-else” using the composite of the two assignments,
- and any variable appearing in the assignments no longer appears in the normalized expression.

You might think that we should state these three properties as separate lemmas, but it turns out that proving them all at once is really convenient, because we can use the `fun_induction` tactic to assume that all these properties hold for `normalize` in the recursive calls, and then `grind` will just put all the facts together for the result:

```proofscript
-- We tell `grind` to unfold our definitions above.
attribute [local grind]
  normalized hasNestedIf hasConstantIf hasRedundantIf
  disjoint vars eval List.disjoint

theorem normalize_spec
    (assign : Std.HashMap Nat Bool) (e : IfExpr) :
    (normalize assign e).normalized
      ∧ (∀ f, (normalize assign e).eval f =
          e.eval fun w => assign[w]?.getD (f w))
      ∧ ∀ (v : Nat),
          v ∈ vars (normalize assign e) → ¬ v ∈ assign := by
  fun_induction normalize with grind
```

The fact that the `fun_induction` plus `grind` combination just works here is sort of astonishing. We're really excited about this, and we're hoping to see a lot more proofs in this style!

A lovely consequence of highly automated proofs is that often you have some flexibility to change the statements, without changing the proof at all! As examples, the particular way that we asserted above that “any variable appearing in the assignments no longer appears in the normalized expression” could be stated in many different ways (although not omitted!). The variations really don't matter, and `grind` can both prove, and use, any of them:

Here we use `assign.contains v = false`:

```proofscript
example (assign : Std.HashMap Nat Bool) (e : IfExpr) :
    (normalize assign e).normalized
      ∧ (∀ f, (normalize assign e).eval f =
          e.eval fun w => assign[w]?.getD (f w))
      ∧ ∀ (v : Nat), v ∈ vars (normalize assign e) →
          assign.contains v = false := by
  fun_induction normalize with grind
```

and here we use `assign[v]? = none`:

```proofscript
example (assign : Std.HashMap Nat Bool) (e : IfExpr) :
    (normalize assign e).normalized
      ∧ (∀ f, (normalize assign e).eval f =
          e.eval fun w => assign[w]?.getD (f w))
      ∧ ∀ (v : Nat),
          v ∈ vars (normalize assign e) → assign[v]? = none := by
  fun_induction normalize with grind
```

In fact, it's also of no consequence to `grind` whether we use a `HashMap` or a `TreeMap` to store the assignments, we can simply switch that implementation detail out, without having to touch the proofs:

```proofscript
def normalize (assign : Std.TreeMap Nat Bool) :
    IfExpr → IfExpr
  | lit b => lit b
  | var v =>
    match assign[v]? with
    | none => var v
    | some b => lit b
  | ite (lit true)  t _ => normalize assign t
  | ite (lit false) _ e => normalize assign e
  | ite (ite a b c) t e =>
    normalize assign (ite a (ite b t e) (ite c t e))
  | ite (var v)     t e =>
    match assign[v]? with
    | none =>
      let t' := normalize (assign.insert v true) t
      let e' := normalize (assign.insert v false) e
      if t' = e' then t' else ite (var v) t' e'
    | some b => normalize assign (ite (lit b) t e)
termination_by e => e.normSize

theorem normalize_spec
    (assign : Std.TreeMap Nat Bool) (e : IfExpr) :
    (normalize assign e).normalized
      ∧ (∀ f, (normalize assign e).eval f =
          e.eval fun w => assign[w]?.getD (f w))
      ∧ ∀ (v : Nat),
          v ∈ vars (normalize assign e) → ¬ v ∈ assign := by
  fun_induction normalize with grind
```

(The fact that we can do this relies on the fact that all the lemmas for both `HashMap` and for `TreeMap` that `grind` needs have already be annotated in the standard library.)

If you'd like to play around with this code, you can find the whole file [here](https://github.com/leanprover/lean4/blob/master/tests/lean/run/grind_ite.lean), or in fact [play with it with no installation](https://live.lean-lang.org/#project=lean-nightly&url=https%3A%2F%2Fraw.githubusercontent.com%2Fleanprover%2Flean4%2Frefs%2Fheads%2Fmaster%2Ftests%2Flean%2Frun%2Fgrind_ite.lean) in the Live Lean editor.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
fail to show termination for
  IfExpr.normalize
with errors
failed to infer structural recursion:
Cannot use parameter assign:
  the type HashMap Nat Bool does not have a `.brecOn` recursor
Cannot use parameter #2:
  failed to eliminate recursive application
    normalize assign (a.ite (b.ite t e) (c.ite t e))


Could not find a decreasing measure.
The basic measures relate at each recursive call as follows:
(<, ≤, =: relation proved, ? all proofs failed, _: no proof attempted)
             #1 x2
1) 219:27-45  =  <
2) 220:27-45  =  <
3) 222:4-52   =  ?
4) 226:16-50  ?  _
5) 227:16-51  _  _
6) 229:16-50  _  _

#1: assign

Please use `termination_by` to specify a decreasing measure.
```


### Display 2


```text
declaration uses `sorry`
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
x:R⊢ (cos x + sin x) ^ 2 = 2 * cos x * sin x + 1
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
x:Rf:R → Nat⊢ f ((cos x + sin x) ^ 2) = f (2 * cos x * sin x + 1)
```


### Display 4


```text
x:Rf✝:R → Natn:Natf:R → Nat⊢ 4 * f ((cos x + sin x) ^ 2) ≠ 2 + f (2 * cos x * sin x + 1)
```


### Display 5


```text
x:Rf✝:R → Natn:Natf:R → Nat⊢ max 3 (4 * f ((cos x + sin x) ^ 2)) ≠ 2 + f (2 * cos x * sin x + 1)
```


### Display 6


```text
assign:HashMap Nat Boole:IfExpr⊢ (normalize assign e).normalized = true ∧
  (∀ (f : Nat → Bool), eval f (normalize assign e) = eval (fun w => assign[w]?.getD (f w)) e) ∧
    ∀ (v : Nat), v ∈ (normalize assign e).vars → ¬v ∈ assign
```


### Display 7


```text
assign:HashMap Nat Boole:IfExpr⊢ (normalize assign e).normalized = true ∧
  (∀ (f : Nat → Bool), eval f (normalize assign e) = eval (fun w => assign[w]?.getD (f w)) e) ∧
    ∀ (v : Nat), v ∈ (normalize assign e).vars → assign.contains v = false
```


### Display 8


```text
assign:HashMap Nat Boole:IfExpr⊢ (normalize assign e).normalized = true ∧
  (∀ (f : Nat → Bool), eval f (normalize assign e) = eval (fun w => assign[w]?.getD (f w)) e) ∧
    ∀ (v : Nat), v ∈ (normalize assign e).vars → assign[v]? = none
```


### Display 9


```text
assign:TreeMap Nat Bool comparee:IfExpr⊢ (normalize assign e).normalized = true ∧
  (∀ (f : Nat → Bool), eval f (normalize assign e) = eval (fun w => assign[w]?.getD (f w)) e) ∧
    ∀ (v : Nat), v ∈ (normalize assign e).vars → ¬v ∈ assign
```

