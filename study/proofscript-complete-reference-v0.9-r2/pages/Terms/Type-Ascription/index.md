<a id="The-Lean-Language-Reference--Terms--Type-Ascription"></a>

# ProofScript — 13.10. Type Ascription

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Terms keep native binding, precedence and type-directed elaboration. D-CALL is adjacency-sensitive: f(x,y) supplies two curried arguments; f((x,y)) and native f (x,y) supply one tuple. An empty call passes Unit. Lambdas use fun, records use :=, and match patterns remain native even when constructor terms use decorated calls. Braces delimit specific categories; they do not disable the native layout checks inside them.

**Compiler and coverage boundary.** Preserve grouping that influences elaboration. Do not flatten nested calls, split patterns on arbitrary bars, or rewrite punctuation inside strings and quotations.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Terms/Type-Ascription/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Terms/Type-Ascription/index.html). Source Git blob: `63e17c8b58f1ea432ed5b16c845ea0c61fc33859`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 13.10. Type Ascription

<a id="--tech-term-Type-ascriptions"></a>
*Type ascriptions* explicitly annotate terms with their types. They are a way to provide Lean with the expected type for a term. This type must be definitionally equal to the type that is expected based on the term's context. Type ascriptions are useful for more than just documenting a program:

- There may not be sufficient information in the program text to derive a type for a term. Ascriptions are one way to provide the type.
- An inferred type may not be the one that was desired for a term.
- The expected type of a term is used to drive the insertion of [coercions](../../Coercions/index.md#--tech-term-coercion), and ascriptions are one way to control where coercions are inserted.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Postfix Type Ascriptions**

Type ascriptions must be surrounded by parentheses. They indicate that the first term's type is the second term.

<a id="Lean___Parser___Term___typeAscription-next"></a>

```ebnf
term ::= ...
    | ([anonymous]term : term)
```

In cases where the term that requires a type ascription is long, such as a tactic proof or a [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do) block, the postfix type ascription with its mandatory parentheses can be difficult to read. Additionally, for both proofs and [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do) blocks, the term's type is essential to its interpretation. In these cases, the prefix versions can be easier to read.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Prefix Type Ascriptions**

<a id="Lean___Parser___Term___show"></a>

```ebnf
term ::= ...
    | show term from term
```

When the term in the body of `show` is a tactic proof, the keyword `from` may be omitted.

<a id="Lean___Parser___Term___show-next"></a>

```ebnf
term ::= ...
    | show term by tacticSeq
```

<a id="Ascribing-Statements-to-Proofs"></a>
Ascribing Statements to Proofs 

This example is unable to execute the tactic proof because the desired proposition is not known. As part of running the earlier tactics, the proposition is automatically refined to be one that the tactics could prove. However, their default cases fill it out incorrectly, leading to a proof that fails.

```proofscript
example (n : Nat) := by
  induction n
  next => rfl
  next n' ih =>
    simp only [HAdd.hAdd, Add.add, Nat.add] at *
    rewrite [ih]
    rfl
```

```lean
Invalid rewrite argument: Expected an equality or iff proof or definition name, but `ih` is a proof of
  0 ≍ n'
```

A prefix type ascription with `show` can be used to provide the proposition being proved. This can be useful in syntactic contexts where adding it as a local definition would be inconvenient.

```proofscript
example (n : Nat) := show 0 + n = n by
  induction n
  next => rfl
  next n' ih =>
    simp only [HAdd.hAdd, Add.add, Nat.add] at *
    rewrite [ih]
    rfl
```

<a id="Ascribing-Types-to--do--Blocks"></a>
Ascribing Types to [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do) Blocks 

This example lacks sufficient type information to synthesize the `Pure` instance.

```proofscript
example := do
  return 5
```

```lean
typeclass instance problem is stuck
  Pure ?m.8

Note: Lean will not try to resolve this typeclass instance problem because the type argument to `Pure` is a metavariable. This argument must be fully determined before Lean will try to resolve the typeclass.

Hint: Adding type annotations and supplying implicit arguments to functions can give Lean more information for typeclass resolution. For example, if you have a variable `x` that you intend to be a `Nat`, but Lean reports it as having an unresolved type like `?m`, replacing `x` with `(x : Nat)` can get typeclass resolution un-stuck.
```

A prefix type ascription with `show`, together with a [hole](../Holes/index.md#--tech-term-hole), can be used to indicate the monad. The [default](../../Type-Classes/Instance-Synthesis/index.md#--tech-term-default-instances) `OfNat _ 5` instance provides enough type information to fill the hole with `Nat`.

```proofscript
example := show StateM String _ from do
  return 5
```

There is an important difference between postfix type ascriptions and `show`. Ordinary postfix type ascriptions change the type that is expected for the term, which can change the way that the term elaborates. After elaboration, however, Lean infers the type of the resulting term and uses that inferred type for further elaboration tasks. On the other hand, `show` elaborates to a term whose inferred type is the ascribed type. The difference can be observed when using [generalized field notation](../Function-Application/index.md#--tech-term-generalized-field-notation), where the ascribed type is only guaranteed to be used to resolve fields when using `show`.

<a id="Postfix-Ascription-vs--show"></a>
Postfix Ascription vs `show`  

This definition establishes an alternative name for `List String`:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Colors-_LPAR_in-Postfix-Ascription-vs--show_RPAR_"></a>


```proofscript
const Colors := List String
```

A postfix type ascription provides the type information that's needed to determine the implicit argument `String` to `List.nil`, but the resulting type is still `List String`:

```proofscript
#check ([] : Colors)
```

```lean
[] : List String
```

When using `show`, on the other hand, the elaborated term is constructed in such a way that the inferred type is `Colors`:

```proofscript
#check (show Colors from [])
```

```lean
have this := [];
this : Colors
```

This function is designed to be invoked using [generalized field notation](../Function-Application/index.md#--tech-term-generalized-field-notation):

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Colors___hasYellow-_LPAR_in-Postfix-Ascription-vs--show_RPAR_"></a>


```proofscript
function Colors.hasYellow (cs : Colors) : Bool :=
  cs.any (·.toLower == "yellow")
```

Due to the differences in their inferred types, it can be used with `show`, but not with the postfix type ascription:

```proofscript
#eval ([] : Colors).hasYellow
```

```lean
Invalid field `hasYellow`: The environment does not contain `List.hasYellow`, so it is not possible to project the field `hasYellow` from an expression
  []
of type `List String`
```

```proofscript
#eval (show Colors from []).hasYellow
```

```lean
false
```

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Type ascription notation: `(0 : Int)` instructs Lean to process `0` as a value of type `Int`.
An empty type ascription `(e :)` elaborates `e` without the expected type.
This is occasionally useful when Lean's heuristics for filling arguments from the expected type
do not yield the right result.
```


### Display 2


```text
This is the same as `byTactic`, but it uses a different syntax kind. This is
used by `show` and `suffices` instead of `byTactic` because these syntaxes don't
support arbitrary terms where `byTactic` is accepted. Mathport uses this to e.g.
safely find-replace `by exact $e` by `$e` in any context without causing
incorrect syntax when the full expression is `show $T by exact $e`.
```


### Display 3


```text
A sequence of tactics in brackets, or a delimiter-free indented sequence of tactics.
Delimiter-free indentation is determined by the *first* tactic of the sequence.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Invalid rewrite argument: Expected an equality or iff proof or definition name, but `ih` is a proof of
  0 ≍ n'
```


### Display 2


```text
typeclass instance problem is stuck
  Pure ?m.8

Note: Lean will not try to resolve this typeclass instance problem because the type argument to `Pure` is a metavariable. This argument must be fully determined before Lean will try to resolve the typeclass.

Hint: Adding type annotations and supplying implicit arguments to functions can give Lean more information for typeclass resolution. For example, if you have a variable `x` that you intend to be a `Nat`, but Lean reports it as having an unresolved type like `?m`, replacing `x` with `(x : Nat)` can get typeclass resolution un-stuck.
```


### Display 3


```text
[] : List String
```


### Display 4


```text
have this := [];
this : Colors
```


### Display 5


```text
Invalid field `hasYellow`: The environment does not contain `List.hasYellow`, so it is not possible to project the field `hasYellow` from an expression
  []
of type `List String`
```


### Display 6


```text
false
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
n:Nat⊢ ?m.2 n
```


### Display 2


```text
zero⊢ ?m.2 0succn✝:Nata✝:?m.2 n✝⊢ ?m.2 (n✝ + 1)
```


### Display 3


```text
⊢ ?m.2 0
```


### Display 4


```text
All goals completed! 🐙
```


### Display 5


```text
n':Natih:0 ≍ n'⊢ 0 ≍ n' + 1
```


### Display 6


```text
n':Natih:0 ≍ n'⊢ 0 ≍ n'.succ
```


### Display 7


```text
zero⊢ 0 + 0 = 0succn✝:Nata✝:0 + n✝ = n✝⊢ 0 + (n✝ + 1) = n✝ + 1
```


### Display 8


```text
⊢ 0 + 0 = 0
```


### Display 9


```text
n':Natih:0 + n✝ = n✝⊢ 0 + (n✝ + 1) = n✝ + 1
```


### Display 10


```text
n':Natih:Nat.add 0 n' = n'⊢ (Nat.add 0 n').succ = n'.succ
```


### Display 11


```text
n':Natih:Nat.add 0 n' = n'⊢ n'.succ = n'.succ
```

