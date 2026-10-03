<a id="e-matching"></a>

# ProofScript — 16.7. E‑matching

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

grind combines reasoning such as congruence closure, propagation, case analysis, E-matching and algebraic/arithmetic procedures. Its selected lemmas, annotations and solver parameters determine the search problem. Keep these as native proof-producing facilities, not as a replacement for the kernel. The mirrored subchapters and examples retain their individual scopes and failure cases.

**Compiler and coverage boundary.** Lean 4.34 stable parameter-list changes for lia/grobner are inherited only under the selected tactic capability. A timeout must remain an incomplete-search result.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The--grind--tactic/E___matching/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The--grind--tactic/E___matching/index.html). Source Git blob: `89295266464c9b1ce86094a2137b84b5f5a72151`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 16.7. E‑matching

<a id="--tech-term-E-matching"></a>
*E-matching* is a procedure for efficiently instantiating quantified theorem statements with ground terms. It is widely employed in SMT solvers, and `grind` uses it to instantiate theorems efficiently. It is especially effective when combined with [congruence closure](../Congruence-Closure/index.md#--tech-term-Congruence-closure), enabling `grind` to discover non-obvious consequences of equalities and annotated theorems automatically.

E-matching adds new facts to the metaphorical whiteboard, based on an index of theorems. When the whiteboard contains terms that match the index, the E-matching engine instantiates the corresponding theorems, and the resulting terms can feed further rounds of [congruence closure](../Congruence-Closure/index.md#--tech-term-Congruence-closure), [constraint propagation](../Constraint-Propagation/index.md#--tech-term-Constraint-propagation), and theory-specific solvers. Each fact added to the whiteboard by E-matching is referred to as an 
<a id="--tech-term-instance"></a>
*instance*. Annotating theorems for E-matching, thus adding them to the index, is essential for enabling `grind` to make effective use of a library.

In addition to user-specified theorems, `grind` uses automatically generated equations for [`match`](../../Terms/Pattern-Matching/index.md#Lean___Parser___Term___match)-expressions as E-matching theorems. Behind the scenes, the [elaborator](../../Terms/index.md#--tech-term-elaborator) generates auxiliary functions that implement pattern matches, along with equational theorems that specify their behavior. Using these equations with E-matching enables `grind` to reduce these instances of pattern matching.

<a id="e-matching-patterns"></a>
### 16.7.1. Patterns

The E-matching index is a table of *patterns*. When a term matches one of the patterns in the table, `grind` attempts to instantiate and apply the corresponding theorem, giving rise to further facts and equalities. Selecting appropriate patterns is an important part of using `grind` effectively: if the patterns are too restrictive, then useful theorems may not be applied; if they are too general, performance may suffer.

<a id="E-matching-Patterns"></a>
E-matching Patterns 

Consider the following functions and theorems:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="f-_LPAR_in-E-matching-Patterns_RPAR_"></a>
<a id="g-_LPAR_in-E-matching-Patterns_RPAR_"></a>
<a id="gf-_LPAR_in-E-matching-Patterns_RPAR_"></a>

<a id="f-_LPAR_in-Selecting-Patterns_RPAR_"></a>
<a id="g-_LPAR_in-Selecting-Patterns_RPAR_"></a>
<a id="gf-_LPAR_in-Selecting-Patterns_RPAR_"></a>


```proofscript
function f (a : Nat) : Nat :=
  a + 1

function g (a : Nat) : Nat :=
  a - 1

@[grind =]
theorem gf (x : Nat) : g (f x) = x := by
  simp [f, g]
```

The theorem `gf` asserts that `g (f x) = x` for all natural numbers `x`. The attribute `grind =` instructs `grind` to use the left-hand side of the equation, `g (f x)`, as a pattern for heuristic instantiation via E-matching.

This proof goal does not include an instance of `g (f x)`, but `grind` is nonetheless able to solve it:

```proofscript
example {a b} (h : f b = a) : g a = b := by
  grind
```

Although `g a` is not an instance of the pattern `g (f x)`, it becomes one modulo the equation `f b = a`. By substituting `a` with `f b` in `g a`, we obtain the term `g (f b)`, which matches the pattern `g (f x)` with the assignment `x := b`. Thus, the theorem `gf` is instantiated with `x := b`, and the new equality `g (f b) = b` is asserted. `grind` then uses congruence closure to derive the implied equality `g a = g (f b)` and completes the proof.

The `grind_pattern` command can be used to manually select an E-matching pattern for a theorem. Enabling the option `trace.grind.ematch.instance` causes `grind` print a trace message for each theorem instance it generates, which can be helpful when determining E-matching patterns.

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**E-matching Pattern Selection**

<a id="Lean___Parser___Command___grindPattern"></a>

```ebnf
command ::= ...
    | grind_pattern ident => term,*
```

Associates a theorem with one or more patterns. When multiple patterns are provided in a single `grind_pattern` command, *all* of them must match a term before `grind` will attempt to instantiate the theorem.

<a id="Lean___Parser___Command___grindPattern-next"></a>

```ebnf
command ::= ...
    | grind_pattern ident => term,* where (isValue
       | isStrictValue
       | notValue
       | notStrictValue
       | isGround
       | sizeLt
       | depthLt
       | genLt
       | maxInsts
       | guard
       | check
       | notDefEq
       | defEq)
```

The optional `where` clause specifies constraints that must be satisfied before `grind` attempts to instantiate the theorem. Each constraint has the form `variable =/= value`, preventing instantiation when the pattern variable would be assigned the specified value. This is useful to avoid unbounded or excessive instantiations with problematic terms.

<a id="Selecting-Patterns"></a>
Selecting Patterns 

The `grind =` attribute uses the left side of the equality as the E-matching pattern for `gf`:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function f (a : Nat) : Nat :=
  a + 1

function g (a : Nat) : Nat :=
  a - 1

@[grind =]
theorem gf (x : Nat) : g (f x) = x := by
  simp [f, g]
```

For example, the pattern `g (f x)` is too restrictive in the following case: the theorem `gf` will not be instantiated because the goal does not even contain the function symbol `g`.

In this example, `grind` fails because the pattern is too restrictive: the goal does not contain the function symbol `g`.

```proofscript
example (h₁ : f b = a) (h₂ : f c = a) : b = c := by
  grind
```
<a id="--verso-unique-1352"></a>


```lean
`grind` failed
grindb a c:Nath₁:f b = ah₂:f c = ah:¬b = c⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] f b = a[prop] f c = a[prop] ¬b = c[eqc] False propositions[prop] b = c[eqc] Equivalence classes[eqc] {a, f b, f c}
```

Using just `f x` as the pattern allows `grind` to solve the goal automatically:

```proofscript
grind_pattern gf => f x

example {a b c} (h₁ : f b = a) (h₂ : f c = a) : b = c := by
  grind
```

Enabling `trace.grind.ematch.instance` makes it possible to see the equalities found by E-matching:

```proofscript
example (h₁ : f b = a) (h₂ : f c = a) : b = c := by
  set_option trace.grind.ematch.instance true in
  grind
```

```lean
[grind.ematch.instance] gf: g (f c) = c[grind.ematch.instance] gf: g (f b) = b
```

After E-matching, the proof succeeds because congruence closure equates `g (f c)` with `g (f b)`, because both `f b` and `f c` are equal to `a`. Thus, `b` and `c` must be in the same equivalence class.

When multiple patterns are specified together, all of them must match in the current context before `grind` attempts to instantiate the theorem. This is referred to as a 
<a id="--tech-term-multi-pattern"></a>
*multi-pattern*. This is useful for lemmas such as transitivity rules, where multiple premises must be simultaneously present for the rule to apply. A single theorem may be associated with multiple separate patterns by using multiple invocations of `grind_pattern` or the `@[grind _=_]` attribute. If *any* of these separate patterns match, the theorem will be instantiated.

<a id="Multi-Patterns"></a>
Multi-Patterns 

`R` is a transitive binary relation over `Int`:
<a id="R-_LPAR_in-Multi-Patterns_RPAR_"></a>
<a id="Rtrans-_LPAR_in-Multi-Patterns_RPAR_"></a>


```proofscript
opaque R : Int → Int → Prop
axiom Rtrans {x y z : Int} : R x y → R y z → R x z
```

To use the fact that `R` is transitive, `grind` must already be able to satisfy both premises. This is represented using a [multi-pattern](index.md#--tech-term-multi-pattern):

```proofscript
grind_pattern Rtrans => R x y, R y z

example {a b c d} : R a b → R b c → R c d → R a d := by
  grind
```

The multi-pattern `R x y, R y z` instructs `grind` to instantiate `Rtrans` only when both `R x y` and `R y z` are available in the context. In the example, `grind` applies `Rtrans` to derive `R a c` from `R a b` and `R b c`, and can then repeat the same reasoning to deduce `R a d` from `R a c` and `R c d`.

<a id="Pattern-Constraints"></a>
Pattern Constraints 

Certain combinations of theorems can lead to unbounded instantiation, where E-matching repeatedly generates longer and longer terms. Consider theorems about `List.flatMap` and `List.reverse`. If `List.flatMap_def`, `List.flatMap_reverse`, and `List.reverse_flatMap` are all annotated with `@[grind =]`, then as soon as `List.flatMap_reverse` is instantiated, the following chain of instantiations occurs, creating progressively longer function compositions with `List.reverse`. This can be observed using the `#grind_lint` command:

```text
attribute [local grind =] List.reverse_flatMap

set_option trace.grind.ematch.instance true in
#grind_lint inspect List.flatMap_reverse
```

The trace output shows the unbounded instantiation:

```text
[grind.ematch.instance] List.flatMap_def: List.flatMap (List.reverse ∘ f) l = (List.map (List.reverse ∘ f) l).flatten
[grind.ematch.instance] List.flatMap_def: List.flatMap f l.reverse = (List.map f l.reverse).flatten
[grind.ematch.instance] List.flatMap_reverse: List.flatMap f l.reverse = (List.flatMap (List.reverse ∘ f) l).reverse
[grind.ematch.instance] List.reverse_flatMap: (List.flatMap (List.reverse ∘ f) l).reverse =
  List.flatMap (List.reverse ∘ List.reverse ∘ f) l.reverse
[grind.ematch.instance] List.flatMap_def: List.flatMap (List.reverse ∘ List.reverse ∘ f) l.reverse =
  (List.map (List.reverse ∘ List.reverse ∘ f) l.reverse).flatten
```

This pattern continues indefinitely, with each iteration adding another `List.reverse` to the composition. The `where` clause prevents this by excluding problematic instantiations:

```text
grind_pattern reverse_flatMap => (l.flatMap f).reverse where
  f =/= List.reverse ∘ _
```

This instructs `grind` to use the pattern `(l.flatMap f).reverse`, but only when `f` is not a composition with `List.reverse`, preventing the unbounded chain of instantiations.

You can use `#grind_lint check` to look for problematic patterns, or `#grind_lint check in List` or `#grind_lint check in module Std.Data` to look in specific namespaces or modules.

The `grind` attribute automatically generates an E-matching pattern or multi-pattern using a heuristic, instead of using `grind_pattern` to explicitly specify a pattern. It includes a number of variants that select different heuristics. The `grind?` attribute displays an info message showing the pattern which was selected—this is very helpful for debugging!

Patterns are subexpressions of theorem statements. A subexpression is 
<a id="--tech-term-indexable"></a>
*indexable* if it has an indexable constant as its head, and it is said to 
<a id="--tech-term-cover"></a>
*cover* one of the theorem's arguments if it fixes the argument's value. Indexable constants are all constants other than `Eq`, `HEq`, `Iff`, `And`, `Or`, and `Not`. The set of arguments that are covered by a pattern or multi-pattern is referred to as its 
<a id="--tech-term-coverage"></a>
*coverage*. Some constants are lower priority than others; in particular, the arithmetic operators `HAdd.hAdd`, `HSub.hSub`, `HMul.hMul`, `Dvd.dvd`, `HDiv.hDiv`, and `HMod.hMod` have low priority. An indexable subexpression is 
<a id="--tech-term-minimal"></a>
*minimal* if there is no smaller indexable subexpression whose head constant has at least as high priority.

<a id="attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**attribute**

**Grind Patterns**

When the `grind` attribute is added to a definition, it causes `grind` to unfold that definition to its body whenever it is encountered. When using the module system, if the body of the definition is not visible (e.g. via `@[expose]`), then the `grind` attribute is ignored.

<a id="Lean___Parser___Attr___grind-next-next"></a>

```ebnf
attr ::= ...
    | grind grindMod?
```

The `grind` attribute automatically generates an E-matching pattern for a theorem, using a strategy determined by the provided modifier. If no modifier is provided, then `grind` suggests suitable modifiers, displaying the resulting patterns.

<a id="Lean___Parser___Attr___grind___"></a>

```ebnf
attr ::= ...
    | grind! grindMod?
```

The `grind!` attribute automatically generates an E-matching pattern for a theorem, using a strategy determined by the provided modifier. It additionally enforces the condition that the selected pattern(s) should be minimal indexable subexpressions.

<a id="Lean___Parser___Attr___grind___-next"></a>

```ebnf
attr ::= ...
    | grind? grindMod?
```

The `grind?` displays the pattern that was generated.

<a id="Lean___Parser___Attr___grind______"></a>

```ebnf
attr ::= ...
    | grind!? grindMod?
```

The `grind!?` attribute is equivalent to `grind!`, except it displays the resulting pattern for inspection.

Without any modifier, `@[grind]` traverses the conclusion and then the hypotheses from left to right, adding patterns as they increase the coverage, stopping when all arguments are covered. This default strategy can be explicitly requested using the `.` modifier. In addition to using the default strategy, the attribute checks which other strategies could be applied, and displays all of the resulting patterns.

<a id="Lean___Parser___Attr___grindMod"></a>

**syntax**

**Default Pattern**

<a id="Lean___Parser___Attr___grindMod-next"></a>

```ebnf
grindMod ::= ...
    | .
```

<a id="Lean___Parser___Attr___grindMod-next-next"></a>

```ebnf
grindMod ::= ...
    | ·
```

The `.` modifier instructs `grind` to select a multi-pattern by traversing the conclusion of the theorem, and then the hypotheses from left to right. We say this is the default modifier. Each time it encounters a subexpression which covers an argument which was not previously covered, it adds that subexpression as a pattern, until all arguments have been covered. If `grind!` is used, then only minimal indexable subexpressions are considered.

<a id="Lean___Parser___Attr___grindMod-next-next-next"></a>

**syntax**

**Equality Rewrites**

<a id="Lean___Parser___Attr___grindMod-next-next-next-next"></a>

```ebnf
grindMod ::= ...
    | =
```

The `=` modifier instructs `grind` to check that the conclusion of the theorem is an equality, and then uses the left-hand side of the equality as a pattern. This may fail if not all of the arguments appear in the left-hand side.

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next"></a>

**syntax**

**Backward Equality Rewrites**

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next"></a>

```ebnf
grindMod ::= ...
    | =_
```

The `=_` modifier instructs `grind` to check that the conclusion of the theorem is an equality, and then uses the right-hand side of the equality as a pattern. This may fail if not all of the arguments appear in the right-hand side.

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next"></a>

**syntax**

**Bidirectional Equality Rewrites**

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next"></a>

```ebnf
grindMod ::= ...
    | _=_
```

The `_=_` modifier acts like a macro which expands to `=` and `=_`. It adds two patterns, allowing the equality theorem to trigger in either direction.

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Forward Reasoning**

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
grindMod ::= ...
    | →
```

The `→` modifier instructs `grind` to select a multi-pattern from the hypotheses of the theorem. In other words, `grind` will use the theorem for forwards reasoning. To generate a pattern, it traverses the hypotheses of the theorem from left to right. Each time it encounters a subexpression which covers an argument which was not previously covered, it adds that subexpression as a pattern, until all arguments have been covered. If `grind!` is used, then only minimal indexable subexpressions are considered.

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Backward Reasoning**

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
grindMod ::= ...
    | ←
```

The `←` modifier instructs `grind` to select a multi-pattern from the conclusion of theorem. In other words, `grind` will use the theorem for backwards reasoning. This may fail if not all of the arguments to the theorem appear in the conclusion. Each time it encounters a subexpression which covers an argument which was not previously covered, it adds that subexpression as a pattern, until all arguments have been covered. If `grind!` is used, then only minimal indexable subexpressions are considered.

It is important to inspect the patterns generated by the `@[grind]` attribute to ensure that they match the correct parts of the lemma. If the pattern is too strict, the lemma will not be applied in situations where it would be relevant, leading to less automation. If it is too general, then performance will suffer as the lemma is tried in many situations where it is not helpful.

There are also three less commonly used modifiers for lemmas:

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Left-to-Right Traversal**

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
grindMod ::= ...
    | =>
```

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
grindMod ::= ...
    | ⇒
```

The `⇒` modifier instructs `grind` to select a multi-pattern by traversing all the hypotheses from left to right, followed by the conclusion. Each time it encounters a subexpression which covers an argument which was not previously covered, it adds that subexpression as a pattern, until all arguments have been covered. If `grind!` is used, then only minimal indexable subexpressions are considered.

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Right-to-Left Traversal**

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
grindMod ::= ...
    | <=
```

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
grindMod ::= ...
    | ⇐
```

The `⇐` modifier instructs `grind` to select a multi-pattern by traversing the conclusion, and then all the hypotheses from right to left. Each time it encounters a subexpression which covers an argument which was not previously covered, it adds that subexpression as a pattern, until all arguments have been covered. If `grind!` is used, then only minimal indexable subexpressions are considered.

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Backward Reasoning on Equality**

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
grindMod ::= ...
    | ←=
```

The `←=` modifier is unlike the other `grind` modifiers, and it used specifically for backwards reasoning on equality. When a theorem's conclusion is an equality proposition and it is annotated with `@[grind ←=]`, grind `will` instantiate it whenever the corresponding disequality is assumed—this is a consequence of the fact that grind performs all proofs by contradiction. Ordinarily, the grind attribute does not consider the `=` symbol when generating patterns.

<a id="The--____LSQ_grind-_______RSQ_--Attribute"></a>
The `@[grind ←=]` Attribute 

When attempting to prove that `a⁻¹ = b`, `grind` uses `inv_eq` due to the `@[grind ←=]` annotation.
<a id="inv_eq-_LPAR_in-The--____LSQ_grind-_______RSQ_--Attribute_RPAR_"></a>


```proofscript
@[grind ←=]
theorem inv_eq [One α] [Mul α] [Inv α] {a b : α}
    (w : a * b = 1) : a⁻¹ = b :=
  sorry
```

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Function-Valued Congruence Closure**

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
grindMod ::= ...
    | funCC
```

The `funCC` modifier marks global functions that support **function-valued congruence closure**. Given an application `f a₁ a₂ … aₙ`, when `funCC := true`, `grind` generates and tracks equalities for all partial applications:

- `f a₁`
- `f a₁ a₂`
- `…`
- `f a₁ a₂ … aₙ`

Some additional modifiers can be used to add other kinds of lemmas to the index. This includes extensionality theorems, injectivity theorems for functions, and a shortcut to add all constructors of an inductively defined predicate to the index.

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Extensionality**

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
grindMod ::= ...
    | ext
```

The `ext` modifier marks extensionality theorems for use by `grind`. For example, the standard library marks `funext` with this attribute.

Whenever `grind` encounters a disequality `a ≠ b`, it attempts to apply any available extensionality theorems whose matches the type of `a` and `b`.

In addition, adding `@[grind ext]` to a structure registers a its extensionality theorem.

<a id="The--____LSQ_grind-ext_RSQ_--Attribute"></a>
The `@[grind ext]` Attribute 

`Point` is a structure with two fields:
<a id="Point-_LPAR_in-The--____LSQ_grind-ext_RSQ_--Attribute_RPAR_"></a>
<a id="Point___x-_LPAR_in-The--____LSQ_grind-ext_RSQ_--Attribute_RPAR_"></a>
<a id="Point___y-_LPAR_in-The--____LSQ_grind-ext_RSQ_--Attribute_RPAR_"></a>


```proofscript
structure Point where
  x : Int
  y : Int
```

By default, `grind` can solve goals like this one, because definitional equality includes [η-equivalence](../../The-Type-System/index.md#--tech-term-___-equivalence) for product types:

```proofscript
example (p : Point) : p = ⟨p.x, p.y⟩ := by grind
```

However, it can't solve goals like this one that require an appeal to propositional equalities:

```proofscript
example (p : Point) (a : Int) : a = p.x → p = ⟨a, p.y⟩ := by grind
```
<a id="--verso-unique-1369"></a>


```lean
`grind` failed
grindp:Pointa:Inth:a = p.xh_1:¬p = { x := a, y := p.y }⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] a = p.x[prop] ¬p = { x := a, y := p.y }[eqc] False propositions[prop] p = { x := a, y := p.y }[eqc] Equivalence classes[eqc] {a, p.x}
```

This kind of goal may come up when proving theorems like the fact that swapping the fields of a point twice is the identity:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Point___swap-_LPAR_in-The--____LSQ_grind-ext_RSQ_--Attribute_RPAR_"></a>


```proofscript
function Point.swap (p : Point) : Point := ⟨p.y, p.x⟩
```
<a id="swap_swap_eq_id-_LPAR_in-The--____LSQ_grind-ext_RSQ_--Attribute_RPAR_"></a>


```proofscript
theorem swap_swap_eq_id : Point.swap ∘ Point.swap = id := by
  unfold Point.swap
  grind
```
<a id="--verso-unique-1376"></a>


```lean
`grind` failed
grindh:¬((fun p => { x := p.y, y := p.x }) ∘ fun p => { x := p.y, y := p.x }) = idw:Pointh_1:¬{ x := w.x, y := w.y } = id w⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] ¬((fun p => { x := p.y, y := p.x }) ∘ fun p => { x := p.y, y := p.x }) = id[prop] ∃ x, ¬{ x := x.x, y := x.y } = id x[prop] ¬{ x := w.x, y := w.y } = id w[prop] id w = w[eqc] True propositions[prop] ∃ x, ¬{ x := x.x, y := x.y } = id x[eqc] False propositions[prop] ((fun p => { x := p.y, y := p.x }) ∘ fun p => { x := p.y, y := p.x }) = id[prop] { x := w.x, y := w.y } = id w[eqc] Equivalence classes[eqc] {w, id w}[cases] Case analyses[cases] [1/1]: ∃ x, ¬{ x := x.x, y := x.y } = id x[cases] source: Extensionality `funext`[ematch] E-matching patterns[thm] id.eq_1: [@id #1 #0]
[grind] Diagnostics[thm] E-Matching instances[thm] id.eq_1 ↦ 1
```

Adding the `@[grind ext]` attribute to `Point` enables `grind` to solve both the original example and prove this theorem:
<a id="swap_swap_eq_id___-_LPAR_in-The--____LSQ_grind-ext_RSQ_--Attribute_RPAR_"></a>


```proofscript
attribute [grind ext] Point

example (p : Point) (a : Int) : a = p.x → p = ⟨a, p.y⟩ := by
  grind

theorem swap_swap_eq_id' : Point.swap ∘ Point.swap = id := by
  unfold Point.swap
  grind
```

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Injectivity**

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
grindMod ::= ...
    | inj
```

The `inj` modifier marks injectivity theorems for use by `grind`. The conclusion of the theorem must be of the form `Function.Injective f` where the term `f` contains at least one constant symbol.

<a id="Injectivity-Patterns"></a>
Injectivity Patterns 

This function `double` doubles its argument:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="double-_LPAR_in-Injectivity-Patterns_RPAR_"></a>


```proofscript
function double (x : Nat) : Nat := x + x
```

By default, `grind` cannot prove the following theorem:
<a id="A-_LPAR_in-Injectivity-Patterns_RPAR_"></a>


```proofscript
theorem A {n k : Nat} :
    double (n + 5) = double (k - 3) →
    n + 8 = k := by
  grind
```

However, `double` is injective, and this fact can be registered for `grind` using the `grind inj` attribute:
<a id="double_inj-_LPAR_in-Injectivity-Patterns_RPAR_"></a>


```proofscript
@[grind inj]
theorem double_inj : Function.Injective double := by
  simp only [double, Function.Injective]
  grind
```

This injectivity lemma suffices to prove the theorem:
<a id="B-_LPAR_in-Injectivity-Patterns_RPAR_"></a>


```proofscript
theorem B {n k : Nat} :
    double (n + 5) = double (k - 3) →
    n + 8 = k := by
  grind
```

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Constructor Patterns**

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
grindMod ::= ...
    | intro
```

The `intro` modifier instructs `grind` to use the constructors (introduction rules) of an inductive predicate as E-matching theorems.Example:

```proofscript
inductive Even : Nat → Prop where
| zero : Even 0
| add2 : Even x → Even (x + 2)

attribute [grind intro] Even
example (h : Even x) : Even (x + 6) := by grind
example : Even 0 := by grind
```

Here `attribute [grind intro] Even` acts like a macro that expands to `attribute [grind] Even.zero` and `attribute [grind] Even.add2`. This is especially convenient for inductive predicates with many constructors.

<a id="Patterns-for-Constructors"></a>
Patterns for Constructors 

The predicate `Decreasing` states that each of the values in a list of integers is less than the one before, and the function `decreasing` checks this property, returning a `Bool`.
<a id="Decreasing-_LPAR_in-Patterns-for-Constructors_RPAR_"></a>
<a id="Decreasing___nil-_LPAR_in-Patterns-for-Constructors_RPAR_"></a>
<a id="Decreasing___singleton-_LPAR_in-Patterns-for-Constructors_RPAR_"></a>
<a id="Decreasing___cons-_LPAR_in-Patterns-for-Constructors_RPAR_"></a>
<a id="decreasing-_LPAR_in-Patterns-for-Constructors_RPAR_"></a>


```proofscript
inductive Decreasing : List Int → Prop
  | nil : Decreasing []
  | singleton : Decreasing [x]
  | cons : Decreasing (x :: xs) → y > x → Decreasing (y :: x :: xs)

def decreasing : List Int → Bool
  | [] | [_] => true
  | y :: x :: xs => y > x && decreasing (x :: xs)
```

The function is correct if it returns `true` exactly when `Decreasing` holds for its argument. Attempting to prove this fact using a combination of `fun_induction` and `grind` fails immediately, with none of the three cases proven:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="decreasingCorrect-_LPAR_in-Patterns-for-Constructors_RPAR_"></a>


```proofscript
const decreasingCorrect : decreasing xs = Decreasing xs := by
  fun_induction decreasing <;> grind
```
<a id="--verso-unique-1417"></a>


```lean
`grind` failed
grindh:True = ¬Decreasing []⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] True = ¬Decreasing [][eqc] True propositions[prop] ¬Decreasing [][prop] True = ¬Decreasing [][eqc] False propositions[prop] Decreasing []
```
<a id="--verso-unique-1418"></a>


```lean
`grind` failed
grindhead:Inth:True = ¬Decreasing [head]⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] True = ¬Decreasing [head][eqc] True propositions[prop] ¬Decreasing [head][prop] True = ¬Decreasing [head][eqc] False propositions[prop] Decreasing [head]
```
<a id="--verso-unique-1419"></a>


```lean
`grind` failed
grind.1y x:Intxs:List Intih1:(decreasing (x :: xs) = true) = Decreasing (x :: xs)h:(-1 * y + x + 1 ≤ 0 ∧ decreasing (x :: xs) = true) = ¬Decreasing (y :: x :: xs)left:-1 * y + x + 1 ≤ 0left_1:decreasing (x :: xs) = trueright_1:¬Decreasing (y :: x :: xs)⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] (decreasing (x :: xs) = true) = Decreasing (x :: xs)[prop] (-1 * y + x + 1 ≤ 0 ∧ decreasing (x :: xs) = true) = ¬Decreasing (y :: x :: xs)[prop] -1 * y + x + 1 ≤ 0[prop] decreasing (x :: xs) = true[prop] ¬Decreasing (y :: x :: xs)[eqc] True propositions[prop] Decreasing (x :: xs)[prop] ¬Decreasing (y :: x :: xs)[prop] -1 * y + x + 1 ≤ 0 ∧ decreasing (x :: xs) = true[prop] (-1 * y + x + 1 ≤ 0 ∧ decreasing (x :: xs) = true) = ¬Decreasing (y :: x :: xs)[prop] (decreasing (x :: xs) = true) = Decreasing (x :: xs)[prop] decreasing (x :: xs) = true[prop] -1 * y + x + 1 ≤ 0[eqc] False propositions[prop] Decreasing (y :: x :: xs)[eqc] Equivalence classes[eqc] {true, decreasing (x :: xs)}[cases] Case analyses[cases] [1/2]: (-1 * y + x + 1 ≤ 0 ∧ decreasing (x :: xs) = true) = ¬Decreasing (y :: x :: xs)[cases] source: Initial goal[cutsat] Assignment satisfying linear constraints[assign] y := 1[assign] x := 0
```

Adding the `grind intro` attribute to `Decreasing` results in E-matching patterns being added for each of the three constructors, after which `grind` can prove the first two goals, and requires only a case analysis of a hypothesis to prove the final goal:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="decreasingCorrect___-_LPAR_in-Patterns-for-Constructors_RPAR_"></a>


```proofscript
attribute [grind intro] Decreasing

const decreasingCorrect' : decreasing xs = Decreasing xs := by
  fun_induction decreasing <;> try grind
  case case3 y x xs ih =>
    apply propext
    constructor
    . grind
    . intro
      | .cons hDec hLt =>
        grind
```

Adding `grind cases` to `Decreasing` enables this case analysis automatically, resulting in a fully automatic proof:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="decreasingCorrect______-_LPAR_in-Patterns-for-Constructors_RPAR_"></a>


```proofscript
attribute [grind cases] Decreasing

const decreasingCorrect'' : decreasing xs = Decreasing xs := by
  fun_induction decreasing <;> grind
```

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Unfolding During Preprocessing**

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
grindMod ::= ...
    | unfold
```

The `unfold` modifier instructs `grind` to unfold the given definition during the preprocessing step. Example:

```proofscript
@[grind unfold] def h (x : Nat) := 2 * x
example : 6 ∣ 3*h x := by grind
```

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Normalization Rules**

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
grindMod ::= ...
    | norm
```

The `norm` modifier instructs `grind` to use a theorem as a normalization rule. That is, the theorem is applied during the preprocessing step. This feature is meant for advanced users who understand how the preprocessor and `grind`'s search procedure interact with each other. New users can still benefit from this feature by restricting its use to theorems that completely eliminate a symbol from the goal. Example:

```text
theorem max_def : max n m = if n ≤ m then m else n
```

For a negative example, consider:

```text
opaque f : Int → Int → Int → Int
theorem fax1 : f x 0 1 = 1 := sorry
theorem fax2 : f 1 x 1 = 1 := sorry
attribute [grind norm] fax1
attribute [grind =] fax2

example (h : c = 1) : f c 0 c = 1 := by
  grind -- fails
```

In this example, `fax1` is a normalization rule, but it is not applicable to the input goal since `f c 0 c` is not an instance of `f x 0 1`. However, `f c 0 c` matches the pattern `f 1 x 1` modulo the equality `c = 1`. Thus, `grind` instantiates `fax2` with `x := 0`, producing the equality `f 1 0 1 = 1`, which the normalizer simplifies to `True`. As a result, nothing useful is learned. In the future, we plan to include linters to automatically detect issues like these. Example:

```proofscript
opaque f : Nat → Nat
opaque g : Nat → Nat

@[grind norm] axiom fax : f x = x + 2
@[grind norm ←] axiom fg : f x = g x

example : f x ≥ 2 := by grind
example : f x ≥ g x := by grind
example : f x + g x ≥ 4 := by grind
```

The `grind` tactic can work with a source algebra that doesn't have a great deal of solving infrastructure (e.g. bitvectors) by “injecting” it into another algebra that has more solving infrastructure (like natural numbers or integers). Homomorphism rules describe the injection from source to target, and how the injection commutes with other operations (like addition or multiplication in the case of bitvectors). Homomorphism predicates present additional facts that `grind` can use about the injection (like that a bitvector of length n corresponds to a natural number less than 2^n).

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Homomorphism Rules**

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
grindMod ::= ...
    | hom
```

The `hom` modifier marks a theorem as a homomorphism rule for `grind`.

Homomorphism rules translate terms from a source domain into a target domain that has a dedicated solver. A collection of homomorphism rules encodes an algebra homomorphism `h : A → B`: each rule states how `h` commutes with a source-domain operation, as in `h (f x y) = g (h x) (h y)`. Example: injecting bitvector operations into integer arithmetic using `BitVec.toNat`:

```text
@[grind hom] theorem toNat_add (x y : BitVec w) :
    (x + y).toNat = (x.toNat + y.toNat) % 2^w
```

The rules must be unconditional equations (or `Iff`s). They are applied to fixpoint outside the E-graph, and only the final result is internalized.

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Homomorphism Predicates**

<a id="Lean___Parser___Attr___grindMod-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
grindMod ::= ...
    | hom_pred
```

The `hom_pred` modifier marks a theorem as a homomorphism predicate for `grind`.

Homomorphism predicates are facts that `grind` instantiates eagerly for the terms it internalizes. The conclusion of the theorem must contain an application `f a₁ … aₙ` whose trailing arguments are exactly the theorem's explicit parameters; the head symbol `f` becomes the trigger. Whenever `grind` internalizes a term with head `f`, the theorem is instantiated with the term's trailing arguments, and the resulting fact is asserted. Typical uses are range facts for injection functions, and translations of relations into a target domain. Examples:

```text
@[grind hom_pred] theorem BitVec.toNat_range (x : BitVec w) : x.toNat < 2^w
@[grind hom_pred] theorem UInt8.le_iff (a b : UInt8) : a ≤ b ↔ a.toBitVec ≤ b.toBitVec
```

The first theorem is triggered by terms of the form `BitVec.toNat x`, and the second one by `a ≤ b` applications. `grind` uses the types of `a` and `b` to discard irrelevant instantiations.

<a id="The-Lean-Language-Reference--The--grind--tactic--E___matching--Inspecting-Patterns"></a>
### 16.7.2. Inspecting Patterns

The `grind?` attribute is a version of the `grind` attribute that additionally displays the generated pattern or [multi-pattern](index.md#--tech-term-multi-pattern). Patterns and multi-patterns are displayed as lists of subexpressions, each of which is a pattern; ordinary patterns are displayed as singleton lists. In these displayed patterns, the names of defined constants are printed as-is. When the theorem's parameters occur in the pattern, they are displayed using numbers rather than names. In particular, they are numbered from right to left, starting at 0; this representation is referred to as 
<a id="--tech-term-de-Bruijn-indices"></a>
*de Bruijn indices*.

<a id="Inspecting-Patterns"></a>
Inspecting Patterns 

In order to use this proof that divisibility is transitive with `grind`, it requires E-matching patterns:
<a id="div_trans-_LPAR_in-Inspecting-Patterns_RPAR_"></a>


```proofscript
theorem div_trans {n k j : Nat} : n ∣ k → k ∣ j → n ∣ j := by
  intro ⟨d₁, p₁⟩ ⟨d₂, p₂⟩
  exact ⟨d₁ * d₂, by rw [p₂, p₁, Nat.mul_assoc]⟩
```

The right attribute to use is `@[grind →]`, because there should be a pattern for each premise. Using `@[grind? →]`, it is possible to see which patterns are generated:

```proofscript
attribute [grind? →] div_trans
```

There are two:

```lean
div_trans: [@Dvd.dvd `[Nat] `[Nat.instDvd] #4 #3, @Dvd.dvd `[Nat] `[Nat.instDvd] #3 #2]
```

Arguments are numbered from right to left, so `#0` is the assumption that `k ∣ j`, while `#4` is `n`. Thus, these two patterns correspond to the terms `n ∣ k` and `k ∣ j`.

The rules for selecting patterns from subexpressions of the hypotheses and conclusion are subtle.

<a id="Forward-Pattern-Generation"></a>
Forward Pattern Generation 
<a id="p-_LPAR_in-Forward-Pattern-Generation_RPAR_"></a>
<a id="q-_LPAR_in-Forward-Pattern-Generation_RPAR_"></a>


```proofscript
axiom p : Nat → Nat
axiom q : Nat → Nat
```
<a id="h___-_LPAR_in-Forward-Pattern-Generation_RPAR_"></a>


```proofscript
@[grind!? →] theorem h₁ (w : p (q x) = 7) : p (x + 1) = q x := sorry
```

```lean
h₁: [q #1]
```

The pattern is `q x`. Counting from the right, parameter `#0` is the premise `w` and parameter `#1` is the implicit parameter `x`.

Why did `@[grind! →]`? select `q #1`? The attribute `@[grind! →]` finds patterns by traversing the hypotheses (that is, parameters whose types are propositions) from left to right. In this case, there's only a single hypothesis: `p (q x) = 7`. The heuristic described above says that `grind!` will search for a minimal [indexable](index.md#--tech-term-indexable) subexpression which [covers](index.md#--tech-term-cover) a previously uncovered parameter. There's just one uncovered parameter, namely `x`. The whole hypothesis `p (q x) = 7` can't be used because `grind` will not index on equality. The right-hand side `7` is not helpful, because it doesn't determine the value of `x`. `p (q x)` is not suitable because it is not minimal: it has `q x` inside of it, which is indexable (its head is the constant `q`), and it determines the value of `x`. The expression `q x` itself is minimal, because `x` is not indexable. Thus, `q x` is selected as the pattern.

<a id="Backward-Pattern-Generation"></a>
Backward Pattern Generation 

In this example, the `←` modifier indicates that the pattern should be found in the conclusion:
<a id="h___-_LPAR_in-Backward-Pattern-Generation_RPAR_"></a>


```proofscript
set_option trace.grind.debug.ematch.pattern true in
@[grind? ←] theorem h₂ (w : 7 = p (q x)) : p (x + 1) = q x := sorry
```

The left side of the equality is used because `Eq` is not indexable and `HAdd.hAdd` has lower priority than `p`.

```lean
h₂: [p (#1 + 1)]
```

<a id="Bidirectional-Equality-Pattern-Generation"></a>
Bidirectional Equality Pattern Generation 

In this example, two separate E-matching patterns are generated from the equality conclusion. One matches the left-hand side, and the other matches the right-hand side.
<a id="h___-_LPAR_in-Bidirectional-Equality-Pattern-Generation_RPAR_"></a>


```proofscript
@[grind? _=_] theorem h₃ (w : 7 = p (q x)) : p (x + 1) = q x := sorry
```

```lean
h₃: [q #1]
```

The entire left side of the equality is used instead of just `x + 1` because `HAdd.hAdd` has lower priority than `p`.

```lean
h₃: [p (#1 + 1)]
```

<a id="Patterns-from-Conclusion-and-Hypotheses"></a>
Patterns from Conclusion and Hypotheses 

Without any modifiers, `@[grind]` produces a multipattern by first checking the conclusion and then the premises:
<a id="h___-_LPAR_in-Patterns-from-Conclusion-and-Hypotheses_RPAR_"></a>


```proofscript
@[grind? .] theorem h₄ (w : p x = q y) : p (x + 2) = 7 := sorry
```

Here, argument `x` is `#2`, `y` is `#1`, and `w` is `#0`. The resulting multipattern contains the left-hand side of the equality, which is the only [minimal](index.md#--tech-term-minimal) [indexable](index.md#--tech-term-indexable) subexpression of the conclusion that covers an argument (namely `x`). It also contains `q y`, which is the only minimal indexable subexpression of the hypothesis `w` that covers an additional argument (namely `y`).

```lean
h₄: [p (#2 + 2), q #1]
```

<a id="Failing-Backward-Pattern-Generation"></a>
Failing Backward Pattern Generation 

In this example, pattern generation fails because the theorem's conclusion doesn't mention the argument `y`.
<a id="h___-_LPAR_in-Failing-Backward-Pattern-Generation_RPAR_"></a>


```proofscript
@[grind? ←] theorem h₅ (w : p x = q y) : p (x + 2) = 7 := sorry
```

```lean
`@[grind ←] theorem h₅` failed to find patterns in the theorem's conclusion, consider using different options or the `grind_pattern` command
```

<a id="Left-to-Right-Generation"></a>
Left-to-Right Generation 

In this example, the pattern is generated by traversing the premises from left to right, followed by the conclusion:
<a id="h___-_LPAR_in-Left-to-Right-Generation_RPAR_"></a>


```proofscript
@[grind? =>] theorem h₆
    (_ : q (y + 2) = q y)
    (_ : q (y + 1) = q y) :
    p (x + 2) = 7 :=
  sorry
```

In the patterns, `y` is argument `#3` and `x` is argument `#2`, because [automatic implicit parameters](../../Definitions/Headers-and-Signatures/index.md#--tech-term-automatic-implicit-parameters) are inserted from left to right and `y` occurs before `x` in the theorem statement. The premises are arguments `#1` and `#0`. In the resulting multipattern, `y` is covered by a subexpression of the first premise, and `z` is covered by a subexpression of the conclusion:

```lean
h₆: [q (#3 + 2), p (#2 + 2)]
```

<a id="grind-limits"></a>
### 16.7.3. Resource Limits

E-matching can generate an unbounded number of theorem [instances](index.md#--tech-term-instance). For the sake of both efficiency and termination, `grind` limits the number of times that E-matching can run using two mechanisms:

  Generations

Each term is assigned a 
<a id="--tech-term-generation"></a>
*generation*, and terms produced by E-matching have a generation that is one greater than the maximal generation of all the terms used to instantiate the theorem. E-matching only considers terms whose generation is beneath a configurable threshold. The `gen` option to `grind` controls the generation threshold.

  Round Limits

Each invocation of the E-matching engine is referred to as a 
<a id="--tech-term-round"></a>
*round*. Only a limited number of rounds of E-matching are performed. The `ematch` option to `grind` controls the round limit.

<a id="Too-Many-Instances"></a>
Too Many Instances 

E-matching can generate too many theorem [instances](index.md#--tech-term-instance). Some patterns may even generate an unbounded number of instances.

In this example, `s_eq` is added to the index with the pattern `s x`:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="s-_LPAR_in-Too-Many-Instances_RPAR_"></a>
<a id="s_eq-_LPAR_in-Too-Many-Instances_RPAR_"></a>


```proofscript
function s (x : Nat) := 0

@[grind? =] theorem s_eq (x : Nat) : s x = s (x + 1) :=
  rfl
```

```lean
s_eq: [s #0]
```

Attempting to use this theorem results in many facts about `s` applied to concrete values being generated. In particular, `s_eq` is instantiated with a new `Nat` in each of the five rounds. First, `grind` instantiates `s_eq` with `x := 0`, which generates the term `s 1`. This matches the pattern `s x`, and is thus used to instantiate `s_eq` with `x := 1`, which generates the term `s 2`, and so on until the round limit is reached.

```proofscript
example : s 0 > 0 := by
  grind
```
<a id="--verso-unique-1486"></a>


```lean
`grind` failed
grindh:s 0 = 0⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] s 0 = 0[prop] s 0 = s 1[prop] s 1 = s 2[prop] s 2 = s 3[prop] s 3 = s 4[prop] s 4 = s 5[eqc] Equivalence classes[eqc] {s 0, 0, s 1, s 2, s 3, s 4, s 5}[ematch] E-matching patterns[thm] s_eq: [s #0][cutsat] Assignment satisfying linear constraints[assign] s 0 := 0[assign] s 1 := 0[assign] s 2 := 0[assign] s 3 := 0[assign] s 4 := 0[assign] s 5 := 0[limits] Thresholds reached[limit] maximum number of E-matching rounds has been reached, threshold: `(ematch := 5)`
[grind] Diagnostics[thm] E-Matching instances[thm] s_eq ↦ 5
```

Increasing the round limit to 20 causes E-matching to terminate due to the default generation limit of 8:

```proofscript
example : s 0 > 0 := by
  grind (ematch := 20)
```
<a id="--verso-unique-1491"></a>


```lean
`grind` failed
grindh:s 0 = 0⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] s 0 = 0[prop] s 0 = s 1[prop] s 1 = s 2[prop] s 2 = s 3[prop] s 3 = s 4[prop] s 4 = s 5[prop] s 5 = s 6[prop] s 6 = s 7[prop] s 7 = s 8[eqc] Equivalence classes[eqc] {s 0, 0, s 1, s 2, s 3, s 4, s 5, s 6, s 7, s 8}[ematch] E-matching patterns[thm] s_eq: [s #0][cutsat] Assignment satisfying linear constraints[assign] s 0 := 0[assign] s 1 := 0[assign] s 2 := 0[assign] s 3 := 0[assign] s 4 := 0[assign] s 5 := 0[assign] s 6 := 0[assign] s 7 := 0[assign] s 8 := 0[limits] Thresholds reached[limit] maximum term generation has been reached, threshold: `(gen := 8)`
[grind] Diagnostics[thm] E-Matching instances[thm] s_eq ↦ 8
```

<a id="Increasing-E-matching-Limits"></a>
Increasing E-matching Limits 

`iota` returns the list of all numbers strictly less than its argument, and the theorem `iota_succ` describes its behavior on `Nat.succ`:
<a id="iota-_LPAR_in-Increasing-E-matching-Limits_RPAR_"></a>
<a id="iota_succ-_LPAR_in-Increasing-E-matching-Limits_RPAR_"></a>


```proofscript
def iota : Nat → List Nat
  | 0 => []
  | n + 1 => n :: iota n

@[grind =] theorem iota_succ : iota (n + 1) = n :: iota n :=
  rfl
```

The fact that `(iota 20).length > 10` can be proven by repeatedly instantiating `iota_succ` and `List.length_cons`. However, `grind` does not succeed:

```proofscript
example : (iota 20).length > 10 := by
  grind
```
<a id="--verso-unique-1496"></a>


```lean
`grind` failed
grindh:(iota 20).length ≤ 10⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] (iota 20).length ≤ 10[prop] iota 20 = 19 :: iota 19[prop] iota 19 = 18 :: iota 18[prop] (19 :: iota 19).length = (iota 19).length + 1[prop] iota 18 = 17 :: iota 17[prop] (18 :: iota 18).length = (iota 18).length + 1[prop] iota 17 = 16 :: iota 16[prop] (17 :: iota 17).length = (iota 17).length + 1[prop] iota 16 = 15 :: iota 15[prop] (16 :: iota 16).length = (iota 16).length + 1[eqc] True propositions[prop] (iota 20).length ≤ 10[eqc] Equivalence classes[eqc] {iota 20, 19 :: iota 19}[eqc] {(iota 20).length, (19 :: iota 19).length, (iota 19).length + 1}[eqc] {iota 19, 18 :: iota 18}[eqc] {iota 18, 17 :: iota 17}[eqc] {(iota 19).length, (18 :: iota 18).length, (iota 18).length + 1}[eqc] {iota 17, 16 :: iota 16}[eqc] {(iota 18).length, (17 :: iota 17).length, (iota 17).length + 1}[eqc] {iota 16, 15 :: iota 15}[eqc] {(iota 17).length, (16 :: iota 16).length, (iota 16).length + 1}[eqc] others[eqc] {↑(iota 17).length, ↑((iota 16).length + 1)}[eqc] {↑(iota 18).length, ↑((iota 17).length + 1)}[eqc] {↑(iota 19).length, ↑((iota 18).length + 1)}[eqc] {↑(iota 20).length, ↑((iota 19).length + 1)}[ematch] E-matching patterns[thm] List.eq_nil_of_length_eq_zero: [@List.length #2 #1][thm] iota_succ: [iota (#0 + 1)][thm] List.length_cons: [@List.length #2 (@List.cons _ #1 #0)][cutsat] Assignment satisfying linear constraints[assign] (iota 20).length := 4[assign] (iota 19).length := 3[assign] (19 :: iota 19).length := 4[assign] (iota 18).length := 2[assign] (18 :: iota 18).length := 3[assign] (iota 17).length := 1[assign] (17 :: iota 17).length := 2[assign] (iota 16).length := 0[assign] (16 :: iota 16).length := 1[ring] Ring `Lean.Grind.Ring.OfSemiring.Q Nat`[basis] Basis[_] ↑(iota 19).length + -1 * ↑(iota 18).length + -1 = 0[_] ↑(iota 18).length + -1 * ↑(iota 17).length + -1 = 0[_] ↑(iota 17).length + -1 * ↑(iota 16).length + -1 = 0[limits] Thresholds reached[limit] maximum number of E-matching rounds has been reached, threshold: `(ematch := 5)`
[grind] Diagnostics[thm] E-Matching instances[thm] iota_succ ↦ 5[thm] List.length_cons ↦ 4
```

Due to the limited number of E-matching rounds, the chain of instantiations is not completed. Increasing these limits allows `grind` to succeed:

```proofscript
example : (iota 20).length > 10 := by
  grind (gen := 20) (ematch := 20)
```

When the option `diagnostics` is set to `true`, `grind` displays the number of instances that it generates for each theorem. This is useful to detect theorems that contain patterns that are triggering too many instances. In this case, the diagnostics show that `iota_succ` is instantiated 12 times:

```proofscript
set_option diagnostics true in
set_option diagnostics.threshold 10 in
example : (iota 20).length > 10 := by
  grind (gen := 20) (ematch := 20)
```

```lean
[grind] Diagnostics[thm] E-Matching instances[thm] iota_succ ↦ 12[thm] List.length_cons ↦ 11[app] Applications[app] NatCast.natCast ↦ 37[app] List.length ↦ 23[app] iota ↦ 13[app] List.cons ↦ 12[app] Eq ↦ 11[app] HAdd.hAdd ↦ 11[app] Lean.Grind.Ring.OfSemiring.toQ ↦ 11[app] instHAdd ↦ 1[app] LE.le ↦ 1[app] Lean.Grind.CommSemiring.toSemiring ↦ 1[grind] Simplifier[simp] used theorems (max: 15, num: 2):[simp] Lean.Meta.Grind.Arith.normNatOfNatInst ↦ 15[simp] Nat.reduceAdd ↦ 12[simp] tried theorems (max: 46, num: 1):[simp] eq_self ↦ 46 ❌️use `set_option diagnostics.threshold <num>` to control threshold for reporting counters
```

By default, `grind` uses automatically generated equations for [`match`](../../Terms/Pattern-Matching/index.md#Lean___Parser___Term___match)-expressions as E-matching theorems. This can be disabled by setting the `matchEqs` flag to `false`.

<a id="E-matching-and-Pattern-Matching"></a>
E-matching and Pattern Matching 

Enabling diagnostics shows that `grind` uses one of the equations of the auxiliary matching function during E-matching:
<a id="gt1-_LPAR_in-E-matching-and-Pattern-Matching_RPAR_"></a>


```proofscript
theorem gt1 (x y : Nat) :
    x = y + 1 →
    0 < match x with
        | 0 => 0
        | _ + 1 => 1 := by
  set_option diagnostics true in
  grind
```

```lean
[grind] Diagnostics[thm] E-Matching instances[thm] gt1.match_1.congr_eq_2 ↦ 1[app] Applications[app] NatCast.natCast ↦ 4[app] instHAdd ↦ 1[app] HAdd.hAdd ↦ 1[app] gt1.match_1 ↦ 1
```

The theorem has this type:

```proofscript
#check gt1.match_1.congr_eq_2
```

```lean
gt1.match_1.congr_eq_2.{u_1} (motive : Nat → Sort u_1) (x✝ : Nat) (h_1 : Unit → motive 0)
  (h_2 : (n : Nat) → motive n.succ) (n✝ : Nat) (heq_1 : x✝ = n✝.succ) :
  (match x✝ with
    | 0 => h_1 ()
    | n.succ => h_2 n) ≍
    h_2 n✝
```

Disabling the use of matcher function equations causes the proof to fail:

```proofscript
example (x y : Nat)
    : x = y + 1 →
      0 < match x with
          | 0 => 0
          | _+1 => 1 := by
  grind -matchEqs
```
<a id="--verso-unique-1510"></a>


```lean
`grind` failed
grind.2x y:Nath:x = y + 1h_1:(match x with
  | 0 => 0
  | n.succ => 1) =
  0n:Nath_2:x = n + 1⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] x = y + 1[prop] (match x with
      | 0 => 0
      | n.succ => 1) =
      0[prop] x = n + 1[eqc] Equivalence classes[eqc] {x, y + 1, n + 1}[eqc] {y, n}[eqc] others[eqc] {↑y, ↑n}[eqc] {↑y, ↑n}[eqc] {↑(y + 1), ↑(n + 1)}[eqc] {0,
    match x with
    | 0 => 0
    | n.succ => 1}[cases] Case analyses[cases] [2/2]: match x with
    | 0 => 0
    | n.succ => 1[cases] source: Initial goal[cutsat] Assignment satisfying linear constraints[assign] x := 1[assign] y := 0[assign] match x with
    | 0 => 0
    | n.succ => 1 := 0[assign] n := 0[ring] Rings[ring] Ring `Lean.Grind.Ring.OfSemiring.Q Nat`[basis] Basis[_] ↑n + -1 * ↑y = 0[ring] Ring `Int`[basis] Basis[_] ↑y + -1 * ↑n = 0
[grind] Diagnostics[cases] Cases instances[cases] PUnit ↦ 1
```

<a id="trace___grind___ematch___instance"></a>

**option**

```text
trace.grind.ematch.instance
```

Default value: `false`

enable/disable tracing for the given module and submodules

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


````text
The `grind_pattern` command can be used to manually select a pattern for theorem instantiation.
Enabling the option `trace.grind.ematch.instance` causes `grind` to print a trace message for each
theorem instance it generates, which can be helpful when determining patterns.

When multiple patterns are specified together, all of them must match in the current context before
`grind` attempts to instantiate the theorem. This is referred to as a *multi-pattern*.
This is useful for theorems such as transitivity rules, where multiple premises must be simultaneously
present for the rule to apply.

In the following example, `R` is a transitive binary relation over `Int`.
```
opaque R : Int → Int → Prop
axiom Rtrans {x y z : Int} : R x y → R y z → R x z
```
To use the fact that `R` is transitive, `grind` must already be able to satisfy both premises.
This is represented using a multi-pattern:
```
grind_pattern Rtrans => R x y, R y z

example {a b c d} : R a b → R b c → R c d → R a d := by
  grind
```
The multi-pattern `R x y`, `R y z` instructs `grind` to instantiate `Rtrans` only when both `R x y`
and `R y z` are available in the context. In the example, `grind` applies `Rtrans` to derive `R a c`
from `R a b` and `R b c`, and can then repeat the same reasoning to deduce `R a d` from `R a c` and
`R c d`.

You can add constraints to restrict theorem instantiation. For example:
```
grind_pattern extract_extract => (as.extract i j).extract k l where
  as =/= #[]
```
The constraint instructs `grind` to instantiate the theorem only if `as` is **not** definitionally equal
to `#[]`.

## Constraints

- `x =/= term`: The term bound to `x` (one of the theorem parameters) is **not** definitionally equal to `term`.
  The term may contain holes (i.e., `_`).

- `x =?= term`: The term bound to `x` is definitionally equal to `term`.
  The term may contain holes (i.e., `_`).

- `size x < n`: The term bound to `x` has size less than `n`. Implicit arguments
and binder types are ignored when computing the size.

- `depth x < n`: The term bound to `x` has depth less than `n`.

- `is_ground x`: The term bound to `x` does not contain local variables or meta-variables.

- `is_value x`: The term bound to `x` is a value. That is, it is a constructor fully applied to value arguments,
a literal (`Nat`, `Int`, `String`, etc.), or a lambda `fun x => t`.

- `is_strict_value x`: Similar to `is_value`, but without lambdas.

- `not_value x`: The term bound to `x` is a **not** value (see `is_value`).

- `not_strict_value x`: Similar to `not_value`, but without lambdas.

- `gen < n`: The theorem instance has generation less than `n`. Recall that each term is assigned a
generation, and terms produced by theorem instantiation have a generation that is one greater than
the maximal generation of all the terms used to instantiate the theorem. This constraint complements
the `gen` option available in `grind`.

- `max_insts < n`: A new instance is generated only if less than `n` instances have been generated so far.

- `guard e`: The instantiation is delayed until `grind` learns that `e` is `true` in this state.

- `check e`: Similar to `guard e`, but `grind` checks whether `e` is implied by its current state by
assuming `¬ e` and trying to deduce an inconsistency.

## Example

Consider the following example where `f` is a monotonic function
```
opaque f : Nat → Nat
axiom fMono : x ≤ y → f x ≤ f y
```
and you want to instruct `grind` to instantiate `fMono` for every pair of terms `f x` and `f y` when
`x ≤ y` and `x` is **not** definitionally equal to `y`. You can use
```
grind_pattern fMono => f x, f y where
  guard x ≤ y
  x =/= y
```
Then, in the following example, only three instances are generated.
```
/--
trace: [grind.ematch.instance] fMono: a ≤ f a → f a ≤ f (f a)
[grind.ematch.instance] fMono: f a ≤ f (f a) → f (f a) ≤ f (f (f a))
[grind.ematch.instance] fMono: a ≤ f (f a) → f a ≤ f (f (f a))
-/
#guard_msgs in
example : f b = f c → a ≤ f a → f (f a) ≤ f (f (f a)) := by
  set_option trace.grind.ematch.instance true in
  grind
```
````


### Display 2


```text
`attrKind` matches `("scoped" <|> "local")?`, used before an attribute like `@[local simp]`.
```


### Display 3


```text
Marks a theorem or definition for use by the `grind` tactic.

An optional modifier (e.g. `=`, `→`, `←`, `cases`, `intro`, `ext`, `inj`, etc.)
controls how `grind` uses the declaration:
* whether it is applied forwards, backwards, or both,
* whether equalities are used on the left, right, or both sides,
* whether case-splits, constructors, extensionality, or injectivity are applied,
* or whether custom instantiation patterns are used.

See the individual modifier docstrings for details.
```


### Display 4


````text
Like `@[grind]`, but enforces the **minimal indexable subexpression condition**:
when several subterms cover the same free variables, `grind!` chooses the smallest one.

This influences E-matching pattern selection.

### Example
```lean
theorem fg_eq (h : x > 0) : f (g x) = x

@[grind <-] theorem fg_eq (h : x > 0) : f (g x) = x
-- Pattern selected: `f (g x)`

-- With minimal subexpression:
@[grind! <-] theorem fg_eq (h : x > 0) : f (g x) = x
-- Pattern selected: `g x`
```
````


### Display 5


```text
Like `@[grind]`, but also prints the pattern(s) selected by `grind`
as info messages. Useful for debugging annotations and modifiers.
```


### Display 6


```text
Like `@[grind!]`, but also prints the pattern(s) selected by `grind`
as info messages. Combines minimal subexpression selection with debugging output.
```


### Display 7


```text
The `.` modifier instructs `grind` to select a multi-pattern by traversing the conclusion of the
theorem, and then the hypotheses from left to right. We say this is the default modifier.
Each time it encounters a subexpression which covers an argument which was not
previously covered, it adds that subexpression as a pattern, until all arguments have been covered.
If `grind!` is used, then only minimal indexable subexpressions are considered.
```


### Display 8


```text
The `=` modifier instructs `grind` to check that the conclusion of the theorem is an equality,
and then uses the left-hand side of the equality as a pattern. This may fail if not all of the arguments appear
in the left-hand side.
```


### Display 9


```text
The `=_` modifier instructs `grind` to check that the conclusion of the theorem is an equality,
and then uses the right-hand side of the equality as a pattern. This may fail if not all of the arguments appear
in the right-hand side.
```


### Display 10


```text
The `_=_` modifier acts like a macro which expands to `=` and `=_`.  It adds two patterns,
allowing the equality theorem to trigger in either direction.
```


### Display 11


```text
The `→` modifier instructs `grind` to select a multi-pattern from the hypotheses of the theorem.
In other words, `grind` will use the theorem for forwards reasoning.
To generate a pattern, it traverses the hypotheses of the theorem from left to right.
Each time it encounters a subexpression which covers an argument which was not
previously covered, it adds that subexpression as a pattern, until all arguments have been covered.
If `grind!` is used, then only minimal indexable subexpressions are considered.
```


### Display 12


```text
The `←` modifier instructs `grind` to select a multi-pattern from the conclusion of theorem.
In other words, `grind` will use the theorem for backwards reasoning.
This may fail if not all of the arguments to the theorem appear in the conclusion.
Each time it encounters a subexpression which covers an argument which was not
previously covered, it adds that subexpression as a pattern, until all arguments have been covered.
If `grind!` is used, then only minimal indexable subexpressions are considered.
```


### Display 13


```text
The `⇒` modifier instructs `grind` to select a multi-pattern by traversing all the hypotheses from
left to right, followed by the conclusion.
Each time it encounters a subexpression which covers an argument which was not
previously covered, it adds that subexpression as a pattern, until all arguments have been covered.
If `grind!` is used, then only minimal indexable subexpressions are considered.
```


### Display 14


```text
The `⇐` modifier instructs `grind` to select a multi-pattern by traversing the conclusion, and then
all the hypotheses from right to left.
Each time it encounters a subexpression which covers an argument which was not
previously covered, it adds that subexpression as a pattern, until all arguments have been covered.
If `grind!` is used, then only minimal indexable subexpressions are considered.
```


### Display 15


```text
The `←=` modifier is unlike the other `grind` modifiers, and it used specifically for
backwards reasoning on equality. When a theorem's conclusion is an equality proposition and it
is annotated with `@[grind ←=]`, grind `will` instantiate it whenever the corresponding disequality
is assumed—this is a consequence of the fact that grind performs all proofs by contradiction.
Ordinarily, the grind attribute does not consider the `=` symbol when generating patterns.
```


### Display 16


```text
The `funCC` modifier marks global functions that support **function-valued congruence closure**.
Given an application `f a₁ a₂ … aₙ`, when `funCC := true`,
`grind` generates and tracks equalities for all partial applications:
- `f a₁`
- `f a₁ a₂`
- `…`
- `f a₁ a₂ … aₙ`
```


### Display 17


```text
The `ext` modifier marks extensionality theorems for use by `grind`.
For example, the standard library marks `funext` with this attribute.

Whenever `grind` encounters a disequality `a ≠ b`, it attempts to apply any
available extensionality theorems whose matches the type of `a` and `b`.
```


### Display 18


```text
The `inj` modifier marks injectivity theorems for use by `grind`.
The conclusion of the theorem must be of the form `Function.Injective f`
where the term `f` contains at least one constant symbol.
```


### Display 19


````text
The `intro` modifier instructs `grind` to use the constructors (introduction rules)
of an inductive predicate as E-matching theorems.Example:
```
inductive Even : Nat → Prop where
| zero : Even 0
| add2 : Even x → Even (x + 2)

attribute [grind intro] Even
example (h : Even x) : Even (x + 6) := by grind
example : Even 0 := by grind
```
Here `attribute [grind intro] Even` acts like a macro that expands to
`attribute [grind] Even.zero` and `attribute [grind] Even.add2`.
This is especially convenient for inductive predicates with many constructors.
````


### Display 20


````text
The `unfold` modifier instructs `grind` to unfold the given definition during the preprocessing step.
Example:
```
@[grind unfold] def h (x : Nat) := 2 * x
example : 6 ∣ 3*h x := by grind
```
````


### Display 21


````text
The `norm` modifier instructs `grind` to use a theorem as a normalization rule. That is,
the theorem is applied during the preprocessing step.
This feature is meant for advanced users who understand how the preprocessor and `grind`'s search
procedure interact with each other.
New users can still benefit from this feature by restricting its use to theorems that completely
eliminate a symbol from the goal. Example:
```
theorem max_def : max n m = if n ≤ m then m else n
```
For a negative example, consider:
```
opaque f : Int → Int → Int → Int
theorem fax1 : f x 0 1 = 1 := sorry
theorem fax2 : f 1 x 1 = 1 := sorry
attribute [grind norm] fax1
attribute [grind =] fax2

example (h : c = 1) : f c 0 c = 1 := by
  grind -- fails
```
In this example, `fax1` is a normalization rule, but it is not applicable to the input goal since
`f c 0 c` is not an instance of `f x 0 1`. However, `f c 0 c` matches the pattern `f 1 x 1` modulo
the equality `c = 1`. Thus, `grind` instantiates `fax2` with `x := 0`, producing the equality
`f 1 0 1 = 1`, which the normalizer simplifies to `True`. As a result, nothing useful is learned.
In the future, we plan to include linters to automatically detect issues like these.
Example:
```
opaque f : Nat → Nat
opaque g : Nat → Nat

@[grind norm] axiom fax : f x = x + 2
@[grind norm ←] axiom fg : f x = g x

example : f x ≥ 2 := by grind
example : f x ≥ g x := by grind
example : f x + g x ≥ 4 := by grind
```
````


### Display 22


````text
The `hom` modifier marks a theorem as a homomorphism rule for `grind`.

Homomorphism rules translate terms from a source domain into a target domain that has a
dedicated solver. A collection of homomorphism rules encodes an algebra homomorphism
`h : A → B`: each rule states how `h` commutes with a source-domain operation, as in
`h (f x y) = g (h x) (h y)`. Example: injecting bitvector operations into integer
arithmetic using `BitVec.toNat`:
```
@[grind hom] theorem toNat_add (x y : BitVec w) :
    (x + y).toNat = (x.toNat + y.toNat) % 2^w
```
The rules must be unconditional equations (or `Iff`s). They are applied to fixpoint
outside the E-graph, and only the final result is internalized.
````


### Display 23


````text
The `hom_pred` modifier marks a theorem as a homomorphism predicate for `grind`.

Homomorphism predicates are facts that `grind` instantiates eagerly for the terms it
internalizes. The conclusion of the theorem must contain an application `f a₁ … aₙ`
whose trailing arguments are exactly the theorem's explicit parameters; the head
symbol `f` becomes the trigger. Whenever `grind` internalizes a term with head `f`,
the theorem is instantiated with the term's trailing arguments, and the resulting
fact is asserted. Typical uses are range facts for injection functions, and
translations of relations into a target domain. Examples:
```
@[grind hom_pred] theorem BitVec.toNat_range (x : BitVec w) : x.toNat < 2^w
@[grind hom_pred] theorem UInt8.le_iff (a b : UInt8) : a ≤ b ↔ a.toBitVec ≤ b.toBitVec
```
The first theorem is triggered by terms of the form `BitVec.toNat x`, and the second
one by `a ≤ b` applications. `grind` uses the types of `a` and `b` to discard
irrelevant instantiations.
````


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`grind` failed
grindb a c:Nath₁:f b = ah₂:f c = ah:¬b = c⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] f b = a[prop] f c = a[prop] ¬b = c[eqc] False propositions[prop] b = c[eqc] Equivalence classes[eqc] {a, f b, f c}
```


### Display 2


```text
[grind.ematch.instance] gf: g (f c) = c[grind.ematch.instance] gf: g (f b) = b
```


### Display 3


```text
declaration uses `sorry`
```


### Display 4


```text
`grind` failed
grindp:Pointa:Inth:a = p.xh_1:¬p = { x := a, y := p.y }⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] a = p.x[prop] ¬p = { x := a, y := p.y }[eqc] False propositions[prop] p = { x := a, y := p.y }[eqc] Equivalence classes[eqc] {a, p.x}
```


### Display 5


```text
`grind` failed
grindh:¬((fun p => { x := p.y, y := p.x }) ∘ fun p => { x := p.y, y := p.x }) = idw:Pointh_1:¬{ x := w.x, y := w.y } = id w⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] ¬((fun p => { x := p.y, y := p.x }) ∘ fun p => { x := p.y, y := p.x }) = id[prop] ∃ x, ¬{ x := x.x, y := x.y } = id x[prop] ¬{ x := w.x, y := w.y } = id w[prop] id w = w[eqc] True propositions[prop] ∃ x, ¬{ x := x.x, y := x.y } = id x[eqc] False propositions[prop] ((fun p => { x := p.y, y := p.x }) ∘ fun p => { x := p.y, y := p.x }) = id[prop] { x := w.x, y := w.y } = id w[eqc] Equivalence classes[eqc] {w, id w}[cases] Case analyses[cases] [1/1]: ∃ x, ¬{ x := x.x, y := x.y } = id x[cases] source: Extensionality `funext`[ematch] E-matching patterns[thm] id.eq_1: [@id #1 #0]
[grind] Diagnostics[thm] E-Matching instances[thm] id.eq_1 ↦ 1
```


### Display 6


```text
`grind` failed
grind.1n k:Nath:double (n + 5) = double (k - 3)h_1:¬n + 8 = kh_2:-1 * ↑k + 3 ≤ 0⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] double (n + 5) = double (k - 3)[prop] ↑(k - 3) = if -1 * ↑k + 3 ≤ 0 then ↑k + -3 else 0[prop] ¬n + 8 = k[prop] -1 * ↑k + 3 ≤ 0[eqc] True propositions[prop] -1 * ↑k + 3 ≤ 0[eqc] False propositions[prop] n + 8 = k[eqc] Equivalence classes[eqc] {double (n + 5), double (k - 3)}[eqc] others[eqc] {↑(k - 3), if -1 * ↑k + 3 ≤ 0 then ↑k + -3 else 0, ↑k + -3}[cases] Case analyses[cases] [1/2]: if -1 * ↑k + 3 ≤ 0 then ↑k + -3 else 0[cases] source: Initial goal[cutsat] Assignment satisfying linear constraints[assign] n := 0[assign] k := 3[assign] double (n + 5) := 1[assign] double (k - 3) := 1
```


### Display 7


```text
`grind` failed
grind.1y x:Intxs:List Intih1:(decreasing (x :: xs) = true) = Decreasing (x :: xs)h:(-1 * y + x + 1 ≤ 0 ∧ decreasing (x :: xs) = true) = ¬Decreasing (y :: x :: xs)left:-1 * y + x + 1 ≤ 0left_1:decreasing (x :: xs) = trueright_1:¬Decreasing (y :: x :: xs)⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] (decreasing (x :: xs) = true) = Decreasing (x :: xs)[prop] (-1 * y + x + 1 ≤ 0 ∧ decreasing (x :: xs) = true) = ¬Decreasing (y :: x :: xs)[prop] -1 * y + x + 1 ≤ 0[prop] decreasing (x :: xs) = true[prop] ¬Decreasing (y :: x :: xs)[eqc] True propositions[prop] Decreasing (x :: xs)[prop] ¬Decreasing (y :: x :: xs)[prop] -1 * y + x + 1 ≤ 0 ∧ decreasing (x :: xs) = true[prop] (-1 * y + x + 1 ≤ 0 ∧ decreasing (x :: xs) = true) = ¬Decreasing (y :: x :: xs)[prop] (decreasing (x :: xs) = true) = Decreasing (x :: xs)[prop] decreasing (x :: xs) = true[prop] -1 * y + x + 1 ≤ 0[eqc] False propositions[prop] Decreasing (y :: x :: xs)[eqc] Equivalence classes[eqc] {true, decreasing (x :: xs)}[cases] Case analyses[cases] [1/2]: (-1 * y + x + 1 ≤ 0 ∧ decreasing (x :: xs) = true) = ¬Decreasing (y :: x :: xs)[cases] source: Initial goal[cutsat] Assignment satisfying linear constraints[assign] y := 1[assign] x := 0`grind` failed
grindh:True = ¬Decreasing []⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] True = ¬Decreasing [][eqc] True propositions[prop] ¬Decreasing [][prop] True = ¬Decreasing [][eqc] False propositions[prop] Decreasing []`grind` failed
grindhead:Inth:True = ¬Decreasing [head]⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] True = ¬Decreasing [head][eqc] True propositions[prop] ¬Decreasing [head][prop] True = ¬Decreasing [head][eqc] False propositions[prop] Decreasing [head]
```


### Display 8


```text
Definition `decreasingCorrect'` is a proposition; use `theorem` instead of `def`

Note: This linter can be disabled with `set_option linter.defProp false`
```


### Display 9


```text
Definition `decreasingCorrect''` is a proposition; use `theorem` instead of `def`

Note: This linter can be disabled with `set_option linter.defProp false`
```


### Display 10


```text
div_trans: [@Dvd.dvd `[Nat] `[Nat.instDvd] #4 #3, @Dvd.dvd `[Nat] `[Nat.instDvd] #3 #2]
```


### Display 11


```text
h₁: [q #1]
```


### Display 12


```text
[grind.debug.ematch.pattern] place: p (x + 1) = q x[grind.debug.ematch.pattern] collect: p (x + 1) = q x[grind.debug.ematch.pattern] arg: Nat, support: true[grind.debug.ematch.pattern] arg: p (x + 1), support: false[grind.debug.ematch.pattern] collect: p (x + 1)[grind.debug.ematch.pattern] candidate: p (x + 1)[grind.debug.ematch.pattern] found pattern: p (#1 + 1)[grind.debug.ematch.pattern] found full coverage[grind.debug.ematch.pattern] arg: q x, support: falseh₂: [p (#1 + 1)]
```


### Display 13


```text
h₃: [q #1]h₃: [p (#1 + 1)]
```


### Display 14


```text
h₄: [p (#2 + 2), q #1]
```


### Display 15


```text
`@[grind ←] theorem h₅` failed to find patterns in the theorem's conclusion, consider using different options or the `grind_pattern` command
```


### Display 16


```text
h₆: [q (#3 + 2), p (#2 + 2)]
```


### Display 17


```text
Variable name `x` is not explicitly referenced.

Hint: The binding can be removed (if unused) or named `_` (if used implicitly). Alternatively, prefix the name with `_` to silence this warning:
  [apply] _x

Note: This linter can be disabled with `set_option linter.unusedVariables false`
```


### Display 18


```text
s_eq: [s #0]
```


### Display 19


```text
`grind` failed
grindh:s 0 = 0⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] s 0 = 0[prop] s 0 = s 1[prop] s 1 = s 2[prop] s 2 = s 3[prop] s 3 = s 4[prop] s 4 = s 5[eqc] Equivalence classes[eqc] {s 0, 0, s 1, s 2, s 3, s 4, s 5}[ematch] E-matching patterns[thm] s_eq: [s #0][cutsat] Assignment satisfying linear constraints[assign] s 0 := 0[assign] s 1 := 0[assign] s 2 := 0[assign] s 3 := 0[assign] s 4 := 0[assign] s 5 := 0[limits] Thresholds reached[limit] maximum number of E-matching rounds has been reached, threshold: `(ematch := 5)`
[grind] Diagnostics[thm] E-Matching instances[thm] s_eq ↦ 5
```


### Display 20


```text
`grind` failed
grindh:s 0 = 0⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] s 0 = 0[prop] s 0 = s 1[prop] s 1 = s 2[prop] s 2 = s 3[prop] s 3 = s 4[prop] s 4 = s 5[prop] s 5 = s 6[prop] s 6 = s 7[prop] s 7 = s 8[eqc] Equivalence classes[eqc] {s 0, 0, s 1, s 2, s 3, s 4, s 5, s 6, s 7, s 8}[ematch] E-matching patterns[thm] s_eq: [s #0][cutsat] Assignment satisfying linear constraints[assign] s 0 := 0[assign] s 1 := 0[assign] s 2 := 0[assign] s 3 := 0[assign] s 4 := 0[assign] s 5 := 0[assign] s 6 := 0[assign] s 7 := 0[assign] s 8 := 0[limits] Thresholds reached[limit] maximum term generation has been reached, threshold: `(gen := 8)`
[grind] Diagnostics[thm] E-Matching instances[thm] s_eq ↦ 8
```


### Display 21


```text
`grind` failed
grindh:(iota 20).length ≤ 10⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] (iota 20).length ≤ 10[prop] iota 20 = 19 :: iota 19[prop] iota 19 = 18 :: iota 18[prop] (19 :: iota 19).length = (iota 19).length + 1[prop] iota 18 = 17 :: iota 17[prop] (18 :: iota 18).length = (iota 18).length + 1[prop] iota 17 = 16 :: iota 16[prop] (17 :: iota 17).length = (iota 17).length + 1[prop] iota 16 = 15 :: iota 15[prop] (16 :: iota 16).length = (iota 16).length + 1[eqc] True propositions[prop] (iota 20).length ≤ 10[eqc] Equivalence classes[eqc] {iota 20, 19 :: iota 19}[eqc] {(iota 20).length, (19 :: iota 19).length, (iota 19).length + 1}[eqc] {iota 19, 18 :: iota 18}[eqc] {iota 18, 17 :: iota 17}[eqc] {(iota 19).length, (18 :: iota 18).length, (iota 18).length + 1}[eqc] {iota 17, 16 :: iota 16}[eqc] {(iota 18).length, (17 :: iota 17).length, (iota 17).length + 1}[eqc] {iota 16, 15 :: iota 15}[eqc] {(iota 17).length, (16 :: iota 16).length, (iota 16).length + 1}[eqc] others[eqc] {↑(iota 17).length, ↑((iota 16).length + 1)}[eqc] {↑(iota 18).length, ↑((iota 17).length + 1)}[eqc] {↑(iota 19).length, ↑((iota 18).length + 1)}[eqc] {↑(iota 20).length, ↑((iota 19).length + 1)}[ematch] E-matching patterns[thm] List.eq_nil_of_length_eq_zero: [@List.length #2 #1][thm] iota_succ: [iota (#0 + 1)][thm] List.length_cons: [@List.length #2 (@List.cons _ #1 #0)][cutsat] Assignment satisfying linear constraints[assign] (iota 20).length := 4[assign] (iota 19).length := 3[assign] (19 :: iota 19).length := 4[assign] (iota 18).length := 2[assign] (18 :: iota 18).length := 3[assign] (iota 17).length := 1[assign] (17 :: iota 17).length := 2[assign] (iota 16).length := 0[assign] (16 :: iota 16).length := 1[ring] Ring `Lean.Grind.Ring.OfSemiring.Q Nat`[basis] Basis[_] ↑(iota 19).length + -1 * ↑(iota 18).length + -1 = 0[_] ↑(iota 18).length + -1 * ↑(iota 17).length + -1 = 0[_] ↑(iota 17).length + -1 * ↑(iota 16).length + -1 = 0[limits] Thresholds reached[limit] maximum number of E-matching rounds has been reached, threshold: `(ematch := 5)`
[grind] Diagnostics[thm] E-Matching instances[thm] iota_succ ↦ 5[thm] List.length_cons ↦ 4
```


### Display 22


```text
[diag] Diagnostics[type_class] used instances (max: 17, num: 2):[type_class] instOfNatNat ↦ 17[type_class] instOfNat ↦ 15[kernel] unfolded declarations (max: 387, num: 79):[kernel] Int.Internal.Linear.Poly.rec ↦ 387[kernel] Bool.rec ↦ 321[kernel] Int.Internal.Linear.Expr.rec ↦ 196[kernel] Int.rec ↦ 192[kernel] Nat.rec ↦ 128[kernel] Int.casesOn ↦ 116[kernel] Lean.RArray.rec ↦ 114[kernel] Int.Internal.Linear.Expr.casesOn ↦ 103[kernel] and ↦ 100[kernel] OfNat.ofNat ↦ 89[kernel] List.rec ↦ 85[kernel] Int.Internal.Linear.Poly.casesOn ↦ 85[kernel] Int.Internal.Linear.Poly.denote.match_1 ↦ 81[kernel] Add.add ↦ 72[kernel] HAdd.hAdd ↦ 72[kernel] Nat.casesOn ↦ 64[kernel] Bool.casesOn ↦ 62[kernel] Int.Internal.Linear.Expr.toPoly'.go._f ↦ 58[kernel] Int.Internal.Linear.Expr.toPoly'.go.match_1 ↦ 58[kernel] NatCast.natCast ↦ 55[kernel] Int.Internal.Linear.Poly.brecOn ↦ 51[kernel] List.casesOn ↦ 50[kernel] cond ↦ 49[kernel] cond.match_1 ↦ 49[kernel] Int.add.match_1 ↦ 48[kernel] Int.Internal.Linear.Expr.denote._f ↦ 45[kernel] Int.Internal.Linear.Expr.denote.match_1 ↦ 45[kernel] Int.beq' ↦ 44[kernel] Int.Internal.Linear.Poly.brecOn.go ↦ 41[kernel] Int.negOfNat.match_1 ↦ 40[kernel] Int.Internal.Linear.Expr.brecOn ↦ 35[kernel] Int.Internal.Linear.Expr.brecOn.go ↦ 35[kernel] Int.Internal.Linear.Poly.norm._f ↦ 35[kernel] Int.Internal.Linear.Poly.insert._f ↦ 34[kernel] Int.negOfNat ↦ 33[kernel] Int.mul ↦ 26[kernel] Lean.RArray.get ↦ 26[kernel] Int.Internal.Linear.Poly.beq' ↦ 26[kernel] instOfNatNat ↦ 25[kernel] HMul.hMul ↦ 25[kernel] Mul.mul ↦ 25[kernel] Function.comp ↦ 24[kernel] Int.Internal.Linear.Var.denote ↦ 24[kernel] Int.Internal.Linear.Expr.denote ↦ 23[kernel] Int.Internal.Linear.Poly.insert ↦ 23[kernel] Nat.Internal.Linear.Expr.rec ↦ 23[kernel] instDecidableEqList.match_1 ↦ 22[kernel] List.length._f ↦ 22[kernel] iota._f ↦ 21[kernel] iota.match_1 ↦ 21[kernel] 29 more entries...[kernel] Int.add ↦ 20[kernel] Int.neg.match_1 ↦ 20[kernel] Int.neg ↦ 19[kernel] Neg.neg ↦ 19[kernel] BEq.beq ↦ 17[kernel] Nat.blt ↦ 16[kernel] Decidable.casesOn ↦ 15[kernel] Decidable.rec ↦ 15[kernel] instOfNat ↦ 14[kernel] decide ↦ 13[kernel] Prod.casesOn ↦ 13[kernel] Prod.rec ↦ 13[kernel] Int.Internal.Linear.Poly.combine_mul_k ↦ 13[kernel] Int.Internal.Linear.Poly.combine_mul_k' ↦ 13[kernel] LE.le ↦ 12[kernel] List.brecOn ↦ 12[kernel] Int.Internal.Linear.norm_eq_cert ↦ 12[kernel] Int.Internal.Linear.Expr.norm ↦ 12[kernel] Int.Internal.Linear.Expr.toPoly' ↦ 12[kernel] Int.Internal.Linear.Poly.addConst ↦ 12[kernel] Int.Internal.Linear.Poly.norm ↦ 12[kernel] Nat.Internal.Linear.Expr.casesOn ↦ 12[kernel] Int.Internal.Linear.Expr.toPoly'.go ↦ 12[kernel] Int.Internal.Linear.Poly.addConst._f ↦ 12[kernel] instDecidableEqNat ↦ 11[kernel] Nat.decEq ↦ 11[kernel] List.brecOn.go ↦ 11[kernel] Nat.decEq.match_1 ↦ 11[kernel] Int.Internal.Linear.eq_eq_subst'_cert ↦ 11use `set_option diagnostics.threshold <num>` to control threshold for reporting counters
```


### Display 23


```text
[grind] Diagnostics[thm] E-Matching instances[thm] iota_succ ↦ 12[thm] List.length_cons ↦ 11[app] Applications[app] NatCast.natCast ↦ 37[app] List.length ↦ 23[app] iota ↦ 13[app] List.cons ↦ 12[app] Eq ↦ 11[app] HAdd.hAdd ↦ 11[app] Lean.Grind.Ring.OfSemiring.toQ ↦ 11[app] instHAdd ↦ 1[app] LE.le ↦ 1[app] Lean.Grind.CommSemiring.toSemiring ↦ 1[grind] Simplifier[simp] used theorems (max: 15, num: 2):[simp] Lean.Meta.Grind.Arith.normNatOfNatInst ↦ 15[simp] Nat.reduceAdd ↦ 12[simp] tried theorems (max: 46, num: 1):[simp] eq_self ↦ 46 ❌️use `set_option diagnostics.threshold <num>` to control threshold for reporting counters
```


### Display 24


```text
[diag] Diagnostics[reduction] unfolded reducible declarations (max: 36, num: 1):[reduction] Nat.casesOn ↦ 36[kernel] unfolded declarations (max: 40, num: 5):[kernel] List.rec ↦ 40[kernel] Bool.rec ↦ 28[kernel] OfNat.ofNat ↦ 27[kernel] List.casesOn ↦ 25[kernel] Nat.Internal.Linear.Expr.rec ↦ 23use `set_option diagnostics.threshold <num>` to control threshold for reporting counters
```


### Display 25


```text
[grind] Diagnostics[thm] E-Matching instances[thm] gt1.match_1.congr_eq_2 ↦ 1[app] Applications[app] NatCast.natCast ↦ 4[app] instHAdd ↦ 1[app] HAdd.hAdd ↦ 1[app] gt1.match_1 ↦ 1
```


### Display 26


```text
gt1.match_1.congr_eq_2.{u_1} (motive : Nat → Sort u_1) (x✝ : Nat) (h_1 : Unit → motive 0)
  (h_2 : (n : Nat) → motive n.succ) (n✝ : Nat) (heq_1 : x✝ = n✝.succ) :
  (match x✝ with
    | 0 => h_1 ()
    | n.succ => h_2 n) ≍
    h_2 n✝
```


### Display 27


```text
`grind` failed
grind.2x y:Nath:x = y + 1h_1:(match x with
  | 0 => 0
  | n.succ => 1) =
  0n:Nath_2:x = n + 1⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] x = y + 1[prop] (match x with
      | 0 => 0
      | n.succ => 1) =
      0[prop] x = n + 1[eqc] Equivalence classes[eqc] {x, y + 1, n + 1}[eqc] {y, n}[eqc] others[eqc] {↑y, ↑n}[eqc] {↑y, ↑n}[eqc] {↑(y + 1), ↑(n + 1)}[eqc] {0,
    match x with
    | 0 => 0
    | n.succ => 1}[cases] Case analyses[cases] [2/2]: match x with
    | 0 => 0
    | n.succ => 1[cases] source: Initial goal[cutsat] Assignment satisfying linear constraints[assign] x := 1[assign] y := 0[assign] match x with
    | 0 => 0
    | n.succ => 1 := 0[assign] n := 0[ring] Rings[ring] Ring `Lean.Grind.Ring.OfSemiring.Q Nat`[basis] Basis[_] ↑n + -1 * ↑y = 0[ring] Ring `Int`[basis] Basis[_] ↑y + -1 * ↑n = 0
[grind] Diagnostics[cases] Cases instances[cases] PUnit ↦ 1
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
x:Nat⊢ g (f x) = x
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
x:Nata✝:Natb✝:Nata:Natb:Nath:f b = a⊢ g a = b
```


### Display 4


```text
b:Nata:Natc:Nath₁:f b = ah₂:f c = a⊢ b = c
```


### Display 5


```text
a:Natb:Natc:Nath₁:f b = ah₂:f c = a⊢ b = c
```


### Display 6


```text
a:Intb:Intc:Intd:Int⊢ R a b → R b c → R c d → R a d
```


### Display 7


```text
p:Point⊢ p = { x := p.x, y := p.y }
```


### Display 8


```text
p:Pointa:Int⊢ a = p.x → p = { x := a, y := p.y }
```


### Display 9


```text
⊢ Point.swap ∘ Point.swap = id
```


### Display 10


```text
⊢ ((fun p => { x := p.y, y := p.x }) ∘ fun p => { x := p.y, y := p.x }) = id
```


### Display 11


```text
n:Natk:Nat⊢ double (n + 5) = double (k - 3) → n + 8 = k
```


### Display 12


```text
⊢ Function.Injective double
```


### Display 13


```text
⊢ ∀ ⦃a₁ a₂ : Nat⦄, a₁ + a₁ = a₂ + a₂ → a₁ = a₂
```


### Display 14


```text
x:Nath:Even x⊢ Even (x + 6)
```


### Display 15


```text
⊢ Even 0
```


### Display 16


```text
xs:List Int⊢ (decreasing xs = true) = Decreasing xs
```


### Display 17


```text
case1⊢ (true = true) = Decreasing []case2head✝:Int⊢ (true = true) = Decreasing [head✝]case3y✝:Intx✝:Intxs✝:List Intih1✝:(decreasing (x✝ :: xs✝) = true) = Decreasing (x✝ :: xs✝)⊢ ((decide (y✝ > x✝) && decreasing (x✝ :: xs✝)) = true) = Decreasing (y✝ :: x✝ :: xs✝)
```


### Display 18


```text
y:Intx:Intxs:List Intih:(decreasing (x✝ :: xs✝) = true) = Decreasing (x✝ :: xs✝)⊢ ((decide (y✝ > x✝) && decreasing (x✝ :: xs✝)) = true) = Decreasing (y✝ :: x✝ :: xs✝)
```


### Display 19


```text
y:Intx:Intxs:List Intih:(decreasing (x✝ :: xs✝) = true) = Decreasing (x✝ :: xs✝)⊢ (decide (y > x) && decreasing (x :: xs)) = true ↔ Decreasing (y :: x :: xs)
```


### Display 20


```text
mpy:Intx:Intxs:List Intih:(decreasing (x✝ :: xs✝) = true) = Decreasing (x✝ :: xs✝)⊢ (decide (y > x) && decreasing (x :: xs)) = true → Decreasing (y :: x :: xs)mpry:Intx:Intxs:List Intih:(decreasing (x✝ :: xs✝) = true) = Decreasing (x✝ :: xs✝)⊢ Decreasing (y :: x :: xs) → (decide (y > x) && decreasing (x :: xs)) = true
```


### Display 21


```text
mpy:Intx:Intxs:List Intih:(decreasing (x✝ :: xs✝) = true) = Decreasing (x✝ :: xs✝)⊢ (decide (y > x) && decreasing (x :: xs)) = true → Decreasing (y :: x :: xs)
```


### Display 22


```text
mpry:Intx:Intxs:List Intih:(decreasing (x✝ :: xs✝) = true) = Decreasing (x✝ :: xs✝)⊢ Decreasing (y :: x :: xs) → (decide (y > x) && decreasing (x :: xs)) = true
```


### Display 23


```text
y:Intx:Intxs:List Intih:(decreasing (x✝ :: xs✝) = true) = Decreasing (x✝ :: xs✝)x✝:Decreasing (y :: x :: xs)hDec:Decreasing (x :: xs)hLt:y > x⊢ (decide (y > x) && decreasing (x :: xs)) = true
```


### Display 24


```text
x:Nat⊢ 6 ∣ 3 * h x
```


### Display 25


```text
x:Nat⊢ f x ≥ 2
```


### Display 26


```text
x:Nat⊢ f x ≥ g x
```


### Display 27


```text
x:Nat⊢ f x + g x ≥ 4
```


### Display 28


```text
n:Natk:Natj:Nat⊢ n ∣ k → k ∣ j → n ∣ j
```


### Display 29


```text
n:Natk:Natj:Natd₁:Natp₁:k = n * d₁d₂:Natp₂:j = k * d₂⊢ n ∣ j
```


### Display 30


```text
n:Natk:Natj:Natd₁:Natp₁:k = n * d₁d₂:Natp₂:j = k * d₂⊢ j = n * (d₁ * d₂)
```


### Display 31


```text
n:Natk:Natj:Natd₁:Natp₁:k = n * d₁d₂:Natp₂:j = k * d₂⊢ k * d₂ = n * (d₁ * d₂)
```


### Display 32


```text
n:Natk:Natj:Natd₁:Natp₁:k = n * d₁d₂:Natp₂:j = k * d₂⊢ n * d₁ * d₂ = n * (d₁ * d₂)
```


### Display 33


```text
n:Natk:Natj:Natd₁:Natp₁:k = n * d₁d₂:Natp₂:j = k * d₂⊢ n * (d₁ * d₂) = n * (d₁ * d₂)
```


### Display 34


```text
⊢ s 0 > 0
```


### Display 35


```text
⊢ (iota 20).length > 10
```


### Display 36


```text
x:Naty:Nat⊢ x = y + 1 →
  0 <
    match x with
    | 0 => 0
    | n.succ => 1
```

