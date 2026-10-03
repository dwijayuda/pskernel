<a id="if-then-else"></a>

# ProofScript — 13.7. Conditionals

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Terms keep native binding, precedence and type-directed elaboration. D-CALL is adjacency-sensitive: f(x,y) supplies two curried arguments; f((x,y)) and native f (x,y) supply one tuple. An empty call passes Unit. Lambdas use fun, records use :=, and match patterns remain native even when constructor terms use decorated calls. Braces delimit specific categories; they do not disable the native layout checks inside them.

**Compiler and coverage boundary.** Preserve grouping that influences elaboration. Do not flatten nested calls, split patterns on arbitrary bars, or rewrite punctuation inside strings and quotations.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Terms/Conditionals/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Terms/Conditionals/index.html). Source Git blob: `b3e3b55f02f6422c14e480098d9b547da7d9dc23`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 13.7. Conditionals

The conditional expression is used to check whether a proposition is true or false.Despite their syntactic similarity, the [`if`](../../Tactic-Proofs/The-Tactic-Language/index.md#if) used [in the tactic language](../../Tactic-Proofs/The-Tactic-Language/index.md#tactic-language-branching) and the `if` used [in `do`-notation](../../Tactic-Proofs/The-Tactic-Language/index.md#tactic-language-branching) are separate syntactic forms, documented in their own sections. This requires that the proposition has a `Decidable` instance, because it's not possible to check whether *arbitrary* propositions are true or false. There is also a [coercion](../../Coercions/index.md#--tech-term-coercion) from `Bool` to `Prop` that results in a decidable proposition (namely, that the `Bool` in question is equal to `true`), described in the [section on decidability](../../Type-Classes/Basic-Classes/index.md#decidable-propositions).

There are two versions of the conditional expression: one simply performs a case distinction, while the other additionally adds an assumption about the proposition's truth or falsity to the local context. This allows run-time checks to generate compile-time evidence that can be used to statically rule out errors.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Conditionals**

Without a name annotation, the conditional expression expresses only control flow.

<a id="termIfThenElse"></a>

```ebnf
term ::= ...
    | if term then
        term
      else
        term
```

With the name annotation, the branches of the [`if`](index.md#termDepIfThenElse) have access to a local assumption that the proposition is respectively true or false.

<a id="termDepIfThenElse"></a>

```ebnf
term ::= ...
    | if binderIdent : term then
        term
      else
        term
```

<a id="Checking-Array-Bounds"></a>
Checking Array Bounds 

Array indexing requires evidence that the index in question is within the bounds of the array, so `getThird` does not elaborate.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function getThird (xs : Array α) : α := xs[2]
```

```lean
failed to prove index is valid, possible solutions:
  - Use `have`-expressions to prove the index is valid
  - Use `a[i]!` notation instead, runtime check is performed, and 'Panic' error message is produced if index is not valid
  - Use `a[i]?` notation instead, result is an `Option` type
  - Use `a[i]'h` notation instead, where `h` is a proof that index is valid
α:Type ?u.3xs:Array α⊢ 2 < xs.size
```

Relaxing the return type to `Option` and adding a bounds check results in the same error. This is because the proof that the index is in bounds was not added to the local context.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function getThird (xs : Array α) : Option α :=
  if xs.size ≤ 2 then none
  else xs[2]
```

```lean
failed to prove index is valid, possible solutions:
  - Use `have`-expressions to prove the index is valid
  - Use `a[i]!` notation instead, runtime check is performed, and 'Panic' error message is produced if index is not valid
  - Use `a[i]?` notation instead, result is an `Option` type
  - Use `a[i]'h` notation instead, where `h` is a proof that index is valid
α:Type ?u.3xs:Array α⊢ 2 < xs.size
```

Naming the proof `h` is sufficient to enable the tactics that perform bounds checking to succeed, even though it does not occur explicitly in the text of the program.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function getThird (xs : Array α) : Option α :=
  if h : xs.size ≤ 2 then none
  else xs[2]
```

There is also a pattern-matching version of [`if`](index.md#termIfLet). If the pattern matches, then it takes the first branch, binding the pattern variables. If the pattern does not match, then it takes the second branch.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Pattern-Matching Conditionals**

<a id="termIfLet"></a>

```ebnf
term ::= ...
    | if let term := term then
        term
      else
        term
```

If a `Bool`-only conditional statement is ever needed, the [`bif`](index.md#boolIfThenElse) variant can be used.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Boolean-Only Conditional**

<a id="boolIfThenElse"></a>

```ebnf
term ::= ...
    | bif term then
        term
      else
        term
```

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`if c then t else e` is notation for `ite c t e`, "if-then-else", which decides to
return `t` or `e` depending on whether `c` is true or false. The explicit argument
`c : Prop` does not have any actual computational content, but there is an additional
`[Decidable c]` argument synthesized by typeclass inference which actually
determines how to evaluate `c` to true or false. Write `if h : c then t else e`
instead for a "dependent if-then-else" `dite`, which allows `t`/`e` to use the fact
that `c` is true/false.


Conventions for notations in identifiers:

 * The recommended spelling of `if c then t else e` in identifiers is `ite` (use `left` for `t` and `right` for `e`).
```


### Display 2


```text
"Dependent" if-then-else, normally written via the notation `if h : c then t(h) else e(h)`,
is sugar for `dite c (fun h => t(h)) (fun h => e(h))`, and it is the same as
`if c then t else e` except that `t` is allowed to depend on a proof `h : c`,
and `e` can depend on `h : ¬c`. (Both branches use the same name for the hypothesis,
even though it has different types in the two cases.)

We use this to be able to communicate the if-then-else condition to the branches.
For example, `Array.get arr i h` expects a proof `h : i < arr.size` in order to
avoid a bounds check, so you can write `if h : i < arr.size then arr.get i h else ...`
to avoid the bounds check inside the if branch. (Of course in this case we have only
lifted the check into an explicit `if`, but we could also use this proof multiple times
or derive `i < arr.size` from some other proposition that we are checking in the `if`.)


Conventions for notations in identifiers:

 * The recommended spelling of `if h : c then t else e` in identifiers is `dite` (use `left` for `t` and `right` for `e`).
```


### Display 3


```text
`binderIdent` matches an `ident` or a `_`. It is used for identifiers in binding
position, where `_` means that the value should be left unnamed and inaccessible.
```


### Display 4


````text
`if let pat := d then t else e` is a shorthand syntax for:
```
match d with
| pat => t
| _ => e
```
It matches `d` against the pattern `pat` and the bindings are available in `t`.
If the pattern does not match, it returns `e` instead.
````


### Display 5


```text
The conditional function.

`cond c x y` is the same as `if c then x else y`, but optimized for a Boolean condition rather than
a decidable proposition. It can also be written using the notation `bif c then x else y`.

Just like `ite`, `cond` is declared `@[macro_inline]`, which causes applications of `cond` to be
unfolded. As a result, `x` and `y` are not evaluated at runtime until one of them is selected, and
only the selected branch is evaluated.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
failed to prove index is valid, possible solutions:
  - Use `have`-expressions to prove the index is valid
  - Use `a[i]!` notation instead, runtime check is performed, and 'Panic' error message is produced if index is not valid
  - Use `a[i]?` notation instead, result is an `Option` type
  - Use `a[i]'h` notation instead, where `h` is a proof that index is valid
α:Type ?u.3xs:Array α⊢ 2 < xs.size
```

