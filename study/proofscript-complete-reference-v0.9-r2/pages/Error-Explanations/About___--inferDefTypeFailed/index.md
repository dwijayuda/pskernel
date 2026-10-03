<a id="lean___inferDefTypeFailed"></a>

# ProofScript — About: inferDefTypeFailed

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

The inherited error catalog explains invalid constructors, dependent eliminations, missing instances, unresolved names and other rejected programs. These are examples of failure, not snippets to copy into a successful program. Preserve native error IDs while mapping source positions back to .ps. A syntax overlay error should be distinguished from native elaboration, proof search, kernel rejection and unavailable target primitives.

**Compiler and coverage boundary.** Keep malformed, unsupported, cancelled, exhausted and internal-error outcomes distinct. Never turn an unsupported example into a permissive fallback or suppress a failed proof to make documentation appear runnable.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Error-Explanations/About___--inferDefTypeFailed/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Error-Explanations/About___--inferDefTypeFailed/index.html). Source Git blob: `dea290e2474d7b403489f58233b4cc0ae2081836`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## About: inferDefTypeFailed

Error code: `lean.inferDefTypeFailed`

*The type of a definition could not be inferred.*

**Severity:**Error**Since:**4.23.0

This error occurs when the type of a definition is not fully specified and Lean is unable to infer its type from the available information. If the definition has parameters, this error refers only to the resulting type after the colon (the error [`lean.inferBinderTypeFailed`](../About___--inferBinderTypeFailed/index.md#lean___inferBinderTypeFailed) indicates that a parameter type could not be inferred).

To resolve this error, provide additional type information in the definition. This can be done straightforwardly by providing an explicit resulting type after the colon in the definition header. Alternatively, if an explicit resulting type is not provided, adding further type information to the definition's body—such as by specifying implicit type arguments or giving explicit types to `let` binders—may allow Lean to infer the type of the definition. Look for type inference or implicit argument synthesis errors that arise alongside this one to identify ambiguities that may be contributing to this error.

Note that when an explicit resulting type is provided—even if that type contains holes—Lean will not use information from the definition body to help infer the type of the definition or its parameters. Thus, adding an explicit resulting type may also necessitate adding type annotations to parameters whose types were previously inferable. Additionally, it is always necessary to provide an explicit type in a `theorem` declaration: the `theorem` syntax requires a type annotation, and the elaborator will never attempt to use the theorem body to infer the proposition being proved.

<a id="The-Lean-Language-Reference--Error-Explanations--About___--inferDefTypeFailed--Examples"></a>
### Examples

<a id="Implicit-Argument-Cannot-be-Inferred"></a>
Implicit Argument Cannot be Inferred   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed (type annotation)
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-button-2"></a>
Fixed (implicit argument)  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
const emptyNats :=
  []
```

```lean
Failed to infer type of definition `emptyNats`
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-1"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
const emptyNats : List Nat :=
  []
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-2"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
const emptyNats :=
  List.nil (α := Nat)
```

Here, Lean is unable to infer the value of the parameter `α` of the `List` type constructor, which in turn prevents it from inferring the type of the definition. Two fixes are possible: specifying the expected type of the definition allows Lean to infer the appropriate implicit argument to the `List.nil` constructor; alternatively, making this implicit argument explicit in the function body provides sufficient information for Lean to infer the definition's type.

<a id="Definition-Type-Uninferrable-Due-to-Unknown-Parameter-Type"></a>
Definition Type Uninferrable Due to Unknown Parameter Type   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

```proofscript
def identity x :=
  x
```

```lean
Failed to infer type of definition `identity`
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-1"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="identity-_LPAR_in-Definition-Type-Uninferrable-Due-to-Unknown-Parameter-Type_RPAR_"></a>


```proofscript
function identity (x : α) :=
  x
```

In this example, the type of `identity` is determined by the type of `x`, which cannot be inferred. Both the indicated error and [`lean.inferBinderTypeFailed`](../About___--inferBinderTypeFailed/index.md#lean___inferBinderTypeFailed) therefore appear (see that explanation for additional discussion of this example). Resolving the latter—by explicitly specifying the type of `x`—provides Lean with sufficient information to infer the definition type.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Failed to infer type of definition `emptyNats`
```


### Display 2


```text
don't know how to synthesize implicit argument `α`
  @List.nil ?m.3
context:
⊢ Type u_1
```


### Display 3


```text
Failed to infer type of definition `identity`
```


### Display 4


```text
Failed to infer type of binder `x`
```

