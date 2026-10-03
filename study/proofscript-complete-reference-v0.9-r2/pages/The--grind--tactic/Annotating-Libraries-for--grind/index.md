<a id="grind-annotation"></a>

# ProofScript — 16.12. Annotating Libraries for grind

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

grind combines reasoning such as congruence closure, propagation, case analysis, E-matching and algebraic/arithmetic procedures. Its selected lemmas, annotations and solver parameters determine the search problem. Keep these as native proof-producing facilities, not as a replacement for the kernel. The mirrored subchapters and examples retain their individual scopes and failure cases.

**Compiler and coverage boundary.** Lean 4.34 stable parameter-list changes for lia/grobner are inherited only under the selected tactic capability. A timeout must remain an incomplete-search result.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The--grind--tactic/Annotating-Libraries-for--grind/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The--grind--tactic/Annotating-Libraries-for--grind/index.html). Source Git blob: `3fae8b1fc3b3693ef0d891ddfb67c599da3ca57e`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 16.12. Annotating Libraries for grind

To use `grind` effectively with a library, it must be annotated by applying the `grind` attribute to suitable lemmas or declaring `grind_pattern`s. These annotations direct `grind`'s selection of theorems, which lead to further facts on the metaphorical whiteboard. With too few annotations, `grind` will fail to use the lemmas; with too many, it may become slow or it fail due to exhausting resource limitations. Annotations should generally be conservative: only add an annotation if you expect that `grind` should *always* instantiate the theorem once the patterns are matched.

<a id="The-Lean-Language-Reference--The--grind--tactic--Annotating-Libraries-for--grind--Simp-Lemmas"></a>
### 16.12.1. Simp Lemmas

Typically, many theorems that are annotated with `@[simp]` should also be annotated with `@[grind =]`. One significant exception is that typically we avoid having `@[simp]` theorems that introduce an `if` on the right hand side, instead preferring a pair of theorems with the positive and negative conditions as hypotheses. Because `grind` is designed to perform case splitting, it is generally better to instead annotate the single theorem introducing the `if` with `@[grind =]`.

Besides using `@[grind =]` to encourage `grind` to perform rewriting from left to right, you can also use `@[grind _=_]` to “saturate”, allowing bidirectional rewriting whenever either side is encountered.

<a id="The-Lean-Language-Reference--The--grind--tactic--Annotating-Libraries-for--grind--Backwards-and-Forwards-Reasoning"></a>
### 16.12.2. Backwards and Forwards Reasoning

Use `@[grind ←]` (which generates patterns from the conclusion of the theorem) for backwards reasoning theorems, i.e. theorems that should be tried when their conclusion matches a goal. Some examples of theorems in the standard library that are annotated with `grind ←` are:

- ```proofscript
  Array.not_mem_empty (a : α) : ¬ a ∈ #[]
  ```
- ```proofscript
  Array.getElem_filter
    {xs : Array α} {p : α → Bool} {i : Nat}
    (h : i < (xs.filter p).size) :
    p (xs.filter p)[i]
  ```
- ```proofscript
  List.Pairwise.tail
    {l : List α} (h : Pairwise R l) :
    Pairwise R l.tail
  ```

In each case, the lemma is relevant when its conclusion matches a proof goal.

Use `@[grind →]` (which generates patterns from the hypotheses) for forwards reasoning theorems, i.e. where facts should be propagated from existing facts on the whiteboard. Some examples of theorems in the standard library that are annotated with `grind →` are:

- ```proofscript
  List.getElem_of_getElem? {l : List α} :
    l[i]? = some a →
    ∃ h : i < l.length, l[i] = a
  ```
- ```proofscript
  Array.mem_of_mem_erase [BEq α] {a b : α} {xs : Array α}
    (h : a ∈ xs.erase b) :
    a ∈ xs
  ```
- ```proofscript
  List.forall_none_of_filterMap_eq_nil
    (h : filterMap f xs = []) :
    ∀ x ∈ xs, f x = none
  ```

In these cases, the theorems' assumptions determine when they are relevant.

There are many uses for custom patterns created with the `grind_pattern` command. One common use is to introduce inequalities about terms, or membership propositions.

We might have
<a id="count_le_size"></a>


```proofscript
variable [BEq α]

theorem count_le_size {a : α} {xs : Array α} : count a xs ≤ xs.size :=
  ...

grind_pattern count_le_size => count a xs
```

which will register this inequality as soon as a `count a xs` term is encountered (even if the problem has not previously involved inequalities).

We can also use multi-patterns to be more restrictive, e.g. only introducing an inequality about sizes if the whiteboard already contains facts about sizes:
<a id="size_pos_of_mem"></a>


```proofscript
theorem size_pos_of_mem {xs : Array α} (h : a ∈ xs) : 0 < xs.size :=
  sorry

grind_pattern size_pos_of_mem => a ∈ xs, xs.size
```

Unlike a `@[grind →]` attribute, which would cause this theorem to be instantiated whenever `a ∈ xs` is encountered, this pattern will only be used when `xs.size` is already on the whiteboard. (Note that this grind pattern could also be produced using the `@[grind <=]` attribute, which looks at the conclusion first, then backwards through the hypotheses to select patterns. On the other hand, `@[grind →]` would select only `a ∈ xs`.)

In Mathlib we might want to enable polynomial reasoning about the sine and cosine functions, and so add a custom grind pattern
<a id="sin_sq_add_cos_sq"></a>


```proofscript
theorem sin_sq_add_cos_sq : sin x ^ 2 + cos x ^ 2 = 1 := ...

grind_pattern sin_sq_add_cos_sq => sin x, cos x
```

which will instantiate the theorem as soon as **both** `sin x` and `cos x` (with the same `x`) are encountered. This theorem will then automatically enter the Gröbner basis module, and be used to reason about polynomial expressions involving both `sin x` and `cos x`. One both alternatively, more aggressively, write two separate grind patterns so that this theorem instantiated when either `sin x` or `cos x` is encountered.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
declaration uses `sorry`
```

