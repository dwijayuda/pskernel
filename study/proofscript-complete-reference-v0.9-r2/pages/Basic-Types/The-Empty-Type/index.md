<a id="empty"></a>

# ProofScript — 20.10. The Empty Type

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Nat, Int, machine integers, floats, characters, strings, bytes, options, products, sums, lists, arrays, maps, ranges, subtypes and lazy computations retain their distinct native contracts. A target representation is not their meaning. Nat subtraction saturates at zero; the selected Int quotient differs from JavaScript BigInt truncation for some negative inputs. String offsets and Unicode conversions require explicit mappings.

**Compiler and coverage boundary.** The full API entries below retain exact names and signature metadata. Distinguish a signature display from executable source. Unknown reachable primitives reject the requested executable profile.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Basic-Types/The-Empty-Type/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Basic-Types/The-Empty-Type/index.html). Source Git blob: `9056b6ec315524b8cd8176524f67701a492fefa6`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 20.10. The Empty Type

The empty type `Empty` represents impossible values. It is an inductive type with no constructors whatsoever.

While the trivial type `Unit`, which has a single constructor that takes no parameters, can be used to model computations where a result is unwanted or uninteresting, `Empty` can be used in situations where no computation should be possible at all. Instantiating a polymorphic type with `Empty` can mark some of its constructors—those with a parameter of the corresponding type—as impossible; this can rule out certain code paths that are not desired.

The presence of a term with type `Empty` indicates that an impossible code path has been reached. There will never be a value with this type, due to the lack of constructors. On an impossible code path, there's no reason to write further code; the function `Empty.elim` can be used to escape an impossible path.

The universe-polymorphic equivalent of `Empty` is `PEmpty`.

<a id="Empty"></a>

**inductive type**

```text
Empty : Type
```

The empty type. It has no constructors.

Use `Empty.elim` in contexts where a value of type `Empty` is in scope.

**Constructors**

<a id="PEmpty"></a>

**inductive type**

```text
PEmpty.{u} : Sort u
```

The universe-polymorphic empty type, with no constructors.

`PEmpty` can be used in any universe, but this flexibility can lead to worse error messages and more challenges with universe level unification. Prefer the type `Empty` or the proposition `False` when possible.

**Constructors**

<a id="Impossible-Code-Paths"></a>
Impossible Code Paths 

The type signature of the function `f` indicates that it might throw exceptions, but allows the exception type to be anything:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="f-_LPAR_in-Impossible-Code-Paths_RPAR_"></a>


```proofscript
function f (n : Nat) : Except ε Nat := pure n
```

Instantiating `f`'s exception type with `Empty` exploits the fact that `f` never actually throws an exception to convert it to a function whose type indicates that no exceptions will be thrown. In particular, it allows `Empty.elim` to be used to avoid handing the impossible exception value.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="g-_LPAR_in-Impossible-Code-Paths_RPAR_"></a>


```proofscript
function g (n : Nat) : Nat :=
  match f (ε := Empty) n with
  | .error e =>
    Empty.elim e
  | .ok v => v
```

<a id="The-Lean-Language-Reference--Basic-Types--The-Empty-Type--API-Reference"></a>
### 20.10.1. API Reference

<a id="Empty___elim"></a>

**def**

```text
Empty.elim.{u} {C : Sort u} : Empty → C
```

`Empty.elim : Empty → C` says that a value of any type can be constructed from `Empty`. This can be thought of as a compiler-checked assertion that a code path is unreachable.

<a id="PEmpty___elim"></a>

**def**

```text
PEmpty.elim.{u_1, u_2} {C : Sort u_1} : PEmpty → C
```

`PEmpty.elim : Empty → C` says that a value of any type can be constructed from `PEmpty`. This can be thought of as a compiler-checked assertion that a code path is unreachable.
