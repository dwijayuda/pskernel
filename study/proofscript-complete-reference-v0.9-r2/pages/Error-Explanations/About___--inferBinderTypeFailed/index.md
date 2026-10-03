<a id="lean___inferBinderTypeFailed"></a>

# ProofScript — About: inferBinderTypeFailed

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

The inherited error catalog explains invalid constructors, dependent eliminations, missing instances, unresolved names and other rejected programs. These are examples of failure, not snippets to copy into a successful program. Preserve native error IDs while mapping source positions back to .ps. A syntax overlay error should be distinguished from native elaboration, proof search, kernel rejection and unavailable target primitives.

**Compiler and coverage boundary.** Keep malformed, unsupported, cancelled, exhausted and internal-error outcomes distinct. Never turn an unsupported example into a permissive fallback or suppress a failed proof to make documentation appear runnable.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Error-Explanations/About___--inferBinderTypeFailed/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Error-Explanations/About___--inferBinderTypeFailed/index.html). Source Git blob: `9d2bdab0c26e6e85dc23e20823052d2154cc2597`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## About: inferBinderTypeFailed

Error code: `lean.inferBinderTypeFailed`

*The type of a binder could not be inferred.*

**Severity:**Error**Since:**4.23.0

This error occurs when the type of a binder in a declaration header or local binding is not fully specified and cannot be inferred by Lean. Generally, this can be resolved by providing more information to help Lean determine the type of the binder, either by explicitly annotating its type or by providing additional type information at sites where it is used. When the binder in question occurs in the header of a declaration, this error is often accompanied by [`lean.inferDefTypeFailed`](../About___--inferDefTypeFailed/index.md#lean___inferDefTypeFailed).

Note that if a declaration is annotated with an explicit resulting type—even one that contains holes—Lean will not use information from the definition body to infer parameter types. It may therefore be necessary to explicitly specify the types of parameters whose types would otherwise be inferable without the resulting-type annotation; see the “uninferred binder due to resulting type annotation” example below for a demonstration. In `theorem` declarations, the body is never used to infer the types of binders, so any binders whose types cannot be inferred from the rest of the theorem type must include a type annotation.

This error may also arise when identifiers that were intended to be declaration names are inadvertently written in binder position instead. In these cases, the erroneous identifiers are treated as binders with unspecified type, leading to a type inference failure. This frequently occurs when attempting to simultaneously define multiple constants of the same type using syntax that does not support this. Such situations include:

- Attempting to name an example by writing an identifier after the `example` keyword;
- Attempting to define multiple constants with the same type and (if applicable) value by listing them sequentially after `def`, `opaque`, or another declaration keyword;
- Attempting to define multiple fields of a structure of the same type by sequentially listing their names on the same line of a structure declaration; and
- Omitting vertical bars between inductive constructor names.

The first three cases are demonstrated in examples below.

<a id="The-Lean-Language-Reference--Error-Explanations--About___--inferBinderTypeFailed--Examples"></a>
### Examples

<a id="Binder-Type-Requires-New-Type-Variable"></a>
Binder Type Requires New Type Variable   
<a id="error-example-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-button-1"></a>
Fixed  
<a id="error-example-next-next-next-next-next-next-next-next-panel-0"></a>

```proofscript
def identity x :=
  x
```

```lean
Failed to infer type of binder `x`
```

<a id="error-example-next-next-next-next-next-next-next-next-panel-1"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="identity-_LPAR_in-Binder-Type-Requires-New-Type-Variable_RPAR_"></a>


```proofscript
function identity (x : α) :=
  x
```

In the code above, the type of `x` is unconstrained; as this example demonstrates, Lean does not automatically generate fresh type variables for such binders. Instead, the type `α` of `x` must be specified explicitly. Note that if automatic implicit parameter insertion is enabled (as it is by default), a binder for `α` itself need not be provided; Lean will insert an implicit binder for this parameter automatically.

<a id="Uninferred-Binder-Type-Due-to-Resulting-Type-Annotation"></a>
Uninferred Binder Type Due to Resulting Type Annotation   
<a id="error-example-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed  
<a id="error-example-next-next-next-next-next-next-next-next-next-panel-0"></a>

```proofscript
def plusTwo x : Nat :=
  x + 2
```

```lean
Failed to infer type of binder `x`

Note: Because this declaration's type has been explicitly provided, all parameter types and holes (e.g., `_`) in its header are resolved before its body is processed; information from the declaration body cannot be used to infer what these values should be
```

<a id="error-example-next-next-next-next-next-next-next-next-next-panel-1"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function plusTwo (x : Nat) : Nat :=
  x + 2
```

Even though `x` is inferred to have type `Nat` in the body of `plusTwo`, this information is not available when elaborating the type of the definition because its resulting type (`Nat`) has been explicitly specified. Considering only the information in the header, the type of `x` cannot be determined, resulting in the shown error. It is therefore necessary to include the type of `x` in its binder.

<a id="Attempting-to-Name-an-Example-Declaration"></a>
Attempting to Name an Example Declaration   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

```proofscript
example trivial_proof : True :=
  trivial
```

```lean
Failed to infer type of binder `trivial_proof`

Note: Examples do not have names. The identifier `trivial_proof` is being interpreted as a parameter `(trivial_proof : _)`.
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-panel-1"></a>

```proofscript
example : True :=
  trivial
```

This code is invalid because it attempts to give a name to an `example` declaration. Examples cannot be named, and an identifier written where a name would appear in other declaration forms is instead elaborated as a binder, whose type cannot be inferred. If a declaration must be named, it should be defined using a declaration form that supports naming, such as `def` or `theorem`.

<a id="Attempting-to-Define-Multiple-Opaque-Constants-at-Once"></a>
Attempting to Define Multiple Opaque Constants at Once   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

```proofscript
opaque m n : Nat
```

```lean
Failed to infer type of binder `n`

Note: Multiple constants cannot be declared in a single declaration. The identifier `n` is being interpreted as a parameter `(n : _)`.
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-panel-1"></a>
<a id="m-_LPAR_in-Attempting-to-Define-Multiple-Opaque-Constants-at-Once_RPAR_"></a>
<a id="n-_LPAR_in-Attempting-to-Define-Multiple-Opaque-Constants-at-Once_RPAR_"></a>


```proofscript
opaque m : Nat
opaque n : Nat
```

This example incorrectly attempts to define multiple constants with a single `opaque` declaration. Such a declaration can define only one constant: it is not possible to list multiple identifiers after `opaque` or `def` to define them all to have the same type (or value). Such a declaration is instead elaborated as defining a single constant (e.g., `m` above) with parameters given by the subsequent identifiers (`n`), whose types are unspecified and cannot be inferred. To define multiple global constants, it is necessary to declare each separately.

<a id="Attempting-to-Define-Multiple-Structure-Fields-on-the-Same-Line"></a>
Attempting to Define Multiple Structure Fields on the Same Line   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed (Fixed (separate lines))
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-button-2"></a>
Fixed (Fixed (parenthesized))  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

```proofscript
structure Person where
  givenName familyName : String
  age : Nat
```

```lean
Failed to infer type of binder `familyName`
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-panel-1"></a>

```proofscript
structure Person where
  givenName : String
  familyName : String
  age : Nat
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-panel-2"></a>

```proofscript
structure Person where
  (givenName familyName : String)
  age : Nat
```

This example incorrectly attempts to define multiple structure fields (`givenName` and `familyName`) of the same type by listing them consecutively on the same line. Lean instead interprets this as defining a single field, `givenName`, parametrized by a binder `familyName` with no specified type. The intended behavior can be achieved by either listing each field on a separate line, or enclosing the line specifying multiple field names in parentheses (see the manual section on [Inductive Types](../../The-Type-System/Inductive-Types/index.md#inductive-types) for further details about structure declarations).

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Failed to infer type of definition `identity`
```


### Display 2


```text
Failed to infer type of binder `x`
```


### Display 3


```text
Failed to infer type of binder `x`

Note: Because this declaration's type has been explicitly provided, all parameter types and holes (e.g., `_`) in its header are resolved before its body is processed; information from the declaration body cannot be used to infer what these values should be
```


### Display 4


```text
Failed to infer type of binder `trivial_proof`

Note: Examples do not have names. The identifier `trivial_proof` is being interpreted as a parameter `(trivial_proof : _)`.
```


### Display 5


```text
Failed to infer type of binder `n`

Note: Multiple constants cannot be declared in a single declaration. The identifier `n` is being interpreted as a parameter `(n : _)`.
```


### Display 6


```text
Failed to infer type of binder `familyName`
```

