<a id="The-Lean-Language-Reference--Terms--Holes"></a>

# ProofScript — 13.9. Holes

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Terms keep native binding, precedence and type-directed elaboration. D-CALL is adjacency-sensitive: f(x,y) supplies two curried arguments; f((x,y)) and native f (x,y) supply one tuple. An empty call passes Unit. Lambdas use fun, records use :=, and match patterns remain native even when constructor terms use decorated calls. Braces delimit specific categories; they do not disable the native layout checks inside them.

**Compiler and coverage boundary.** Preserve grouping that influences elaboration. Do not flatten nested calls, split patterns on arbitrary bars, or rewrite punctuation inside strings and quotations.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Terms/Holes/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Terms/Holes/index.html). Source Git blob: `e184e50d25381b3ea8605f8d4032d22c0806b28c`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 13.9. Holes

A 
<a id="--tech-term-hole"></a>
*hole* or 
<a id="--tech-term-placeholder-term"></a>
*placeholder term* is a term that indicates the absence of instructions to the elaborator.
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
 In terms, holes can be automatically filled when the surrounding context would only allow one type-correct term to be written where the hole is. Otherwise, a hole is an error. In patterns, holes represent universal patterns that can match anything.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Holes**

Holes are written with underscores.

<a id="Lean___Parser___Term___hole"></a>

```ebnf
term ::= ...
    | _
```

<a id="Filling-Holes-with-Unification"></a>
Filling Holes with Unification 

The function `the` can be used similarly to `show` or a [type ascription](../Type-Ascription/index.md#--tech-term-Type-ascriptions).

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="the-_LPAR_in-Filling-Holes-with-Unification_RPAR_"></a>


```proofscript
function the (α : Sort u) (x : α) : α := x
```

If the second parameter's type can be inferred, then the first parameter can be a hole. Both of these commands are equivalent:

```proofscript
#check the String "Hello!"

#check the _ "Hello"
```

When writing proofs, it can be convenient to explicitly introduce unknown values. This is done via 
<a id="--tech-term-synthetic-holes"></a>
*synthetic holes*, which are never solved by unification and may occur in multiple positions. They are primarily useful in tactic proofs, and are described in [the section on metavariables in proofs](../../Tactic-Proofs/Reading-Proof-States/index.md#metavariables-in-proofs).

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Synthetic Holes**

<a id="Lean___Parser___Term___syntheticHole"></a>

```ebnf
term ::= ...
    | ?ident
```

<a id="Lean___Parser___Term___syntheticHole-next"></a>

```ebnf
term ::= ...
    | ?_
```

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
A *hole* (or *placeholder term*), which stands for an unknown term that is expected to be inferred based on context.
For example, in `@id _ Nat.zero`, the `_` must be the type of `Nat.zero`, which is `Nat`.

The way this works is that holes create fresh metavariables.
The elaborator is allowed to assign terms to metavariables while it is checking definitional equalities.
This is often known as *unification*.

Normally, all holes must be solved for. However, there are a few contexts where this is not necessary:
* In `match` patterns, holes are catch-all patterns.
* In some tactics, such as `refine'` and `apply`, unsolved-for placeholders become new goals.

Related concept: implicit parameters are automatically filled in with holes during the elaboration process.

See also `?m` syntax (synthetic holes).
```


### Display 2


```text
A *synthetic hole* (or *synthetic placeholder*), which stands for an unknown term that should be synthesized using tactics.
- `?_` creates a fresh metavariable with an auto-generated name.
- `?m` either refers to a pre-existing metavariable named `m` or creates a fresh metavariable with that name.

In particular, the synthetic hole syntax creates "synthetic opaque metavariables",
the same kind of metavariable used to represent goals in the tactic state.

Synthetic holes are similar to holes in that `_` also creates metavariables,
but synthetic opaque metavariables have some different properties:
- In tactics such as `refine`, only synthetic holes yield new goals.
- During elaboration, unification will not solve for synthetic opaque metavariables, they are "opaque".
  This is to prevent counterintuitive behavior such as disappearing goals.
- When synthetic holes appear under binders, they capture local variables using a more complicated mechanism known as delayed assignment.

## Delayed assigned metavariables

This section gives an overview of some technical details of synthetic holes, which you should feel free to skip.
Understanding delayed assignments is mainly useful for those who are working on tactics and other metaprogramming.
It is included here until there is a suitable place for it in the reference manual.

When a synthetic hole appears under a binding construct, such as for example `fun (x : α) (y : β) => ?s`,
the system creates a *delayed assignment*. This consists of
1. A metavariable `?m` of type `(x : α) → (y : β) → γ x y` whose local context is the local context outside the `fun`,
  where `γ x y` is the type of `?s`. Recall that `x` and `y` appear in the local context of `?s`.
2. A delayed assignment record associating `?m` to `?s` and the variables `#[x, y]` in the local context of `?s`

Then, this function elaborates as `fun (x : α) (y : β) => ?m x y`, where one should understand `x` and `y` here
as being De Bruijn indexes, since Lean uses the locally nameless encoding of lambda calculus.

Once `?s` is fully solved for, in the sense that after metavariable instantiation it is a metavariable-free term `e`,
then we can make the assignment `?m := fun (x' : α) (y' : β) => e[x := x', y := y']`.
(Implementation note: Lean only instantiates full applications `?m x' y'` of delayed assigned metavariables, to skip forming this function.)
This delayed assignment mechanism is essential to the operation of basic tactics like `intro`,
and a good mental model is that it is a way to "apply" the metavariable `?s` by substituting values in for some of its local variables.
While it would be easier to immediately assign `?s := ?m x y`,
delayed assignment preserves `?s` as an unsolved-for metavariable with a local context that still contains `x` and `y`,
which is exactly what tactics like `intro` need.

By default, delayed assigned metavariables pretty print with what they are delayed assigned to.
The delayed assigned metavariables themselves can be pretty printed using `set_option pp.mvars.delayed true`.

For more information, see the "Gruesome details" module docstrings in `Lean.MetavarContext`.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
the String "Hello!" : String
```


### Display 2


```text
the String "Hello" : String
```

