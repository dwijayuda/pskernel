<a id="lean___inductiveParamMismatch"></a>

# ProofScript — About: inductiveParamMismatch

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

The inherited error catalog explains invalid constructors, dependent eliminations, missing instances, unresolved names and other rejected programs. These are examples of failure, not snippets to copy into a successful program. Preserve native error IDs while mapping source positions back to .ps. A syntax overlay error should be distinguished from native elaboration, proof search, kernel rejection and unavailable target primitives.

**Compiler and coverage boundary.** Keep malformed, unsupported, cancelled, exhausted and internal-error outcomes distinct. Never turn an unsupported example into a permissive fallback or suppress a failed proof to make documentation appear runnable.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Error-Explanations/About___--inductiveParamMismatch/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Error-Explanations/About___--inductiveParamMismatch/index.html). Source Git blob: `977269d1c0f9fac6227749a1735840687b9baf13`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## About: inductiveParamMismatch

Error code: `lean.inductiveParamMismatch`

*Invalid parameter in an occurrence of an inductive type in one of its constructors.*

**Severity:**Error**Since:**4.22.0

This error occurs when a parameter of an inductive type is not uniform in an inductive declaration. The parameters of an inductive type (i.e., those that appear before the colon following the `inductive` keyword) must be identical in all occurrences of the type being defined in its constructors' types. If a parameter of an inductive type must vary between constructors, make the parameter an index by moving it to the right of the colon. See the manual section on [Inductive Types](../../The-Type-System/Inductive-Types/index.md#inductive-types) for additional details.

Note that auto-implicit inlay hints always appear left of the colon in an inductive declaration (i.e., as parameters), even when they are actually indices. This means that double-clicking on an inlay hint to insert such parameters may result in this error. If it does, change the inserted parameters to indices.

<a id="The-Lean-Language-Reference--Error-Explanations--About___--inductiveParamMismatch--Examples"></a>
### Examples

<a id="Vector-Length-Index-as-a-Parameter"></a>
Vector Length Index as a Parameter   
<a id="error-example-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-button-1"></a>
Fixed  
<a id="error-example-next-next-next-next-next-next-panel-0"></a>

```proofscript
inductive Vec (α : Type) (n : Nat) : Type where
  | nil  : Vec α 0
  | cons : α → Vec α n → Vec α (n + 1)
```

```lean
Mismatched inductive type parameter in
  Vec α 0
The provided argument
  0
is not definitionally equal to the expected parameter
  n

Note: The value of parameter `n` must be fixed throughout the inductive declaration. Consider making this parameter an index if it must vary.
```

<a id="error-example-next-next-next-next-next-next-panel-1"></a>
<a id="Vec___nil-_LPAR_in-Vector-Length-Index-as-a-Parameter_RPAR_"></a>
<a id="Vec___cons-_LPAR_in-Vector-Length-Index-as-a-Parameter_RPAR_"></a>


```proofscript
inductive Vec (α : Type) : Nat → Type where
  | nil  : Vec α 0
  | cons : α → Vec α n → Vec α (n + 1)
```

The length argument `n` of the `Vec` type constructor is declared as a parameter, but other values for this argument appear in the `nil` and `cons` constructors (namely, `0` and `n + 1`). An error therefore appears at the first occurrence of such an argument. To correct this, `n` cannot be a parameter of the inductive declaration and must instead be an index, as in the corrected example. On the other hand, `α` remains unchanged throughout all occurrences of `Vec` in the declaration and so is a valid parameter.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Mismatched inductive type parameter in
  Vec α 0
The provided argument
  0
is not definitionally equal to the expected parameter
  n

Note: The value of parameter `n` must be fixed throughout the inductive declaration. Consider making this parameter an index if it must vary.
```

