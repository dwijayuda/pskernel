<a id="lean___invalidDottedIdent"></a>

# ProofScript — About: invalidDottedIdent

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

The inherited error catalog explains invalid constructors, dependent eliminations, missing instances, unresolved names and other rejected programs. These are examples of failure, not snippets to copy into a successful program. Preserve native error IDs while mapping source positions back to .ps. A syntax overlay error should be distinguished from native elaboration, proof search, kernel rejection and unavailable target primitives.

**Compiler and coverage boundary.** Keep malformed, unsupported, cancelled, exhausted and internal-error outcomes distinct. Never turn an unsupported example into a permissive fallback or suppress a failed proof to make documentation appear runnable.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Error-Explanations/About___--invalidDottedIdent/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Error-Explanations/About___--invalidDottedIdent/index.html). Source Git blob: `5b0bc3f4eb5be5bf68fdcb4ad937a90a8cffabff`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## About: invalidDottedIdent

Error code: `lean.invalidDottedIdent`

*Dotted identifier notation used with invalid or non-inferrable expected type.*

**Severity:**Error**Since:**4.22.0

This error indicates that dotted identifier notation was used in an invalid or unsupported context. Dotted identifier notation allows an identifier's namespace to be omitted, provided that it can be inferred by Lean based on type information. Details about this notation can be found in the manual section on [identifiers](../../Terms/Identifiers/index.md#identifiers-and-resolution).

This notation can only be used in a term whose type Lean is able to infer. If there is insufficient type information for Lean to do so, this error will be raised. The inferred type must not be a type universe (e.g., `Prop` or `Type`), as dotted-identifier notation is not supported on these types.

<a id="The-Lean-Language-Reference--Error-Explanations--About___--invalidDottedIdent--Examples"></a>
### Examples

<a id="Insufficient-Type-Information"></a>
Insufficient Type Information   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function reverseDuplicate (xs : List α) :=
  .reverse (xs ++ xs)
```

```lean
Invalid dotted identifier notation: The expected type of `.reverse` could not be determined

Hint: Using one of these would be unambiguous:
  [apply] `Array.reverse`
  [apply] `BitVec.reverse`
  [apply] `List.reverse`
  [apply] `Vector.reverse`
  [apply] `List.IsInfix.reverse`
  [apply] `List.IsPrefix.reverse`
  [apply] `List.IsSuffix.reverse`
  [apply] `List.Sublist.reverse`
  [apply] `Lean.Grind.AC.Seq.reverse`
  [apply] `Std.DTreeMap.Internal.Impl.reverse`
  [apply] `Std.Tactic.BVDecide.BVUnOp.reverse`
  [apply] `Std.DTreeMap.Internal.Impl.Ordered.reverse`
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-1"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="reverseDuplicate-_LPAR_in-Insufficient-Type-Information_RPAR_"></a>


```proofscript
function reverseDuplicate (xs : List α) : List α :=
  .reverse (xs ++ xs)
```

Because the return type of `reverseDuplicate` is not specified, the expected type of `.reverse` cannot be determined. Lean will not use the type of the argument `xs ++ xs` to infer the omitted namespace. Adding the return type `List α` allows Lean to infer the type of `.reverse` and thus the appropriate namespace (`List`) in which to resolve this identifier.

Note that this means that changing the return type of `reverseDuplicate` changes how `.reverse` resolves: if the return type is `T`, then Lean will (attempt to) resolve `.reverse` to a function `T.reverse` whose return type is `T`—even if `T.reverse` does not take an argument of type `List α`.

<a id="Dotted-Identifier-Where-Type-Universe-Expected"></a>
Dotted Identifier Where Type Universe Expected   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

```proofscript
example (n : Nat) :=
  match n > 42 with
  | .true  => n - 1
  | .false => n + 1
```

```lean
Invalid dotted identifier notation: Not supported on type universe
  Prop
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-1"></a>

```proofscript
example (n : Nat) :=
  match decide (n > 42) with
  | .true  => n - 1
  | .false => n + 1
```

The proposition `n > 42` has type `Prop`, which, being a type universe, does not support dotted-identifier notation. As this example demonstrates, attempting to use this notation in such a context is almost always an error. The intent in this example was for `.true` and `.false` to be Booleans, not propositions; however, [`match`](../../Terms/Pattern-Matching/index.md#Lean___Parser___Term___match) expressions do not automatically perform this coercion for decidable propositions. Explicitly adding `decide` makes the discriminant a `Bool` and allows the dotted-identifier resolution to succeed.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Invalid dotted identifier notation: The expected type of `.reverse` could not be determined

Hint: Using one of these would be unambiguous:
  [apply] `Array.reverse`
  [apply] `BitVec.reverse`
  [apply] `List.reverse`
  [apply] `Vector.reverse`
  [apply] `List.IsInfix.reverse`
  [apply] `List.IsPrefix.reverse`
  [apply] `List.IsSuffix.reverse`
  [apply] `List.Sublist.reverse`
  [apply] `Lean.Grind.AC.Seq.reverse`
  [apply] `Std.DTreeMap.Internal.Impl.reverse`
  [apply] `Std.Tactic.BVDecide.BVUnOp.reverse`
  [apply] `Std.DTreeMap.Internal.Impl.Ordered.reverse`
```


### Display 2


```text
Invalid dotted identifier notation: Not supported on type universe
  Prop
```

