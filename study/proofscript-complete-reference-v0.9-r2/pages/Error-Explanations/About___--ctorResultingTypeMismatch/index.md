<a id="lean___ctorResultingTypeMismatch"></a>

# ProofScript — About: ctorResultingTypeMismatch

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

The inherited error catalog explains invalid constructors, dependent eliminations, missing instances, unresolved names and other rejected programs. These are examples of failure, not snippets to copy into a successful program. Preserve native error IDs while mapping source positions back to .ps. A syntax overlay error should be distinguished from native elaboration, proof search, kernel rejection and unavailable target primitives.

**Compiler and coverage boundary.** Keep malformed, unsupported, cancelled, exhausted and internal-error outcomes distinct. Never turn an unsupported example into a permissive fallback or suppress a failed proof to make documentation appear runnable.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Error-Explanations/About___--ctorResultingTypeMismatch/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Error-Explanations/About___--ctorResultingTypeMismatch/index.html). Source Git blob: `75a1bc444ac2e9997b43d90dcc5c57afb7271a60`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## About: ctorResultingTypeMismatch

Error code: `lean.ctorResultingTypeMismatch`

*Resulting type of constructor was not the inductive type being declared.*

**Severity:**Error**Since:**4.22.0

In an inductive declaration, the resulting type of each constructor must match the type being declared; if it does not, this error is raised. That is, every constructor of an inductive type must return a value of that type. See the [Inductive Types](../../The-Type-System/Inductive-Types/index.md#inductive-types) manual section for additional details. Note that it is possible to omit the resulting type for a constructor if the inductive type being defined has no indices.

<a id="The-Lean-Language-Reference--Error-Explanations--About___--ctorResultingTypeMismatch--Examples"></a>
### Examples

<a id="Typo-in-Resulting-Type"></a>
Typo in Resulting Type   
<a id="error-example-button-0"></a>
Original
<a id="error-example-button-1"></a>
Fixed  
<a id="error-example-panel-0"></a>

```proofscript
inductive Tree (α : Type) where
  | leaf : Tree α
  | node : α → Tree α → Treee α
```

```lean
Unexpected resulting type for constructor `Tree.node`: Expected an application of
  Tree
but found
  ?m.2
```

<a id="error-example-panel-1"></a>
<a id="Tree___leaf-_LPAR_in-Typo-in-Resulting-Type_RPAR_"></a>
<a id="Tree___node-_LPAR_in-Typo-in-Resulting-Type_RPAR_"></a>


```proofscript
inductive Tree (α : Type) where
  | leaf : Tree α
  | node : α → Tree α → Tree α
```

<a id="Missing-Resulting-Type-After-Constructor-Parameter"></a>
Missing Resulting Type After Constructor Parameter   
<a id="error-example-next-button-0"></a>
Original
<a id="error-example-next-button-1"></a>
Fixed (resulting type)
<a id="error-example-next-button-2"></a>
Fixed (named parameter)  
<a id="error-example-next-panel-0"></a>

```proofscript
inductive Credential where
  | pin      : Nat
  | password : String
```

```lean
Unexpected resulting type for constructor `Credential.pin`: Expected
  Credential
but found
  Nat
```

<a id="error-example-next-panel-1"></a>

```proofscript
inductive Credential where
  | pin      : Nat → Credential
  | password : String → Credential
```

<a id="error-example-next-panel-2"></a>

```proofscript
inductive Credential where
  | pin (num : Nat)
  | password (str : String)
```

If the type of a constructor is annotated, the full type—including the resulting type—must be provided. Alternatively, constructor parameters can be written using named binders; this allows the omission of the constructor's resulting type because it contains no indices.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Unexpected resulting type for constructor `Tree.node`: Expected an application of
  Tree
but found
  ?m.2
```


### Display 2


```text
Unexpected resulting type for constructor `Credential.pin`: Expected
  Credential
but found
  Nat
```

