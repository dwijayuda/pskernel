<a id="lean___inductiveParamMissing"></a>

# ProofScript — About: inductiveParamMissing

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

The inherited error catalog explains invalid constructors, dependent eliminations, missing instances, unresolved names and other rejected programs. These are examples of failure, not snippets to copy into a successful program. Preserve native error IDs while mapping source positions back to .ps. A syntax overlay error should be distinguished from native elaboration, proof search, kernel rejection and unavailable target primitives.

**Compiler and coverage boundary.** Keep malformed, unsupported, cancelled, exhausted and internal-error outcomes distinct. Never turn an unsupported example into a permissive fallback or suppress a failed proof to make documentation appear runnable.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Error-Explanations/About___--inductiveParamMissing/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Error-Explanations/About___--inductiveParamMissing/index.html). Source Git blob: `527b0a3c6d137d4dcfa533a02966e72a3ba34430`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## About: inductiveParamMissing

Error code: `lean.inductiveParamMissing`

*Parameter not present in an occurrence of an inductive type in one of its constructors.*

**Severity:**Error**Since:**4.22.0

This error occurs when an inductive type constructor is partially applied in the type of one of its constructors such that one or more parameters of the type are omitted. The elaborator requires that all parameters of an inductive type be specified everywhere that type is referenced in its definition, including in the types of its constructors.

If it is necessary to allow the type constructor to be partially applied, without specifying a given type parameter, that parameter must be converted to an index. See the manual section on [Inductive Types](../../The-Type-System/Inductive-Types/index.md#inductive-types) for further explanation of the difference between indices and parameters.

<a id="The-Lean-Language-Reference--Error-Explanations--About___--inductiveParamMissing--Examples"></a>
### Examples

<a id="Omitting-Parameter-in-Argument-to-Higher-Order-Predicate"></a>
Omitting Parameter in Argument to Higher-Order Predicate   
<a id="error-example-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-button-1"></a>
Fixed  
<a id="error-example-next-next-next-next-next-next-next-panel-0"></a>

```proofscript
inductive List.All {α : Type u} (P : α → Prop) : List α → Prop
  | nil : All P []
  | cons {x xs} : P x → All P xs → All P (x :: xs)

structure RoseTree (α : Type u) where
  val : α
  children : List (RoseTree α)

inductive RoseTree.All (P : α → Prop) (t : RoseTree α) : Prop
  | intro : P t.val → List.All (All P) t.children → All P t
```

```lean
Missing parameter(s) in occurrence of inductive type: In the expression
  List.All (All P) t.children
found
  All P
but expected all parameters to be specified:
  All P t

Note: All occurrences of an inductive type in the types of its constructors must specify its fixed parameters. Only indices can be omitted in a partial application of the type constructor.
```

<a id="error-example-next-next-next-next-next-next-next-panel-1"></a>
<a id="RoseTree___All-_LPAR_in-Omitting-Parameter-in-Argument-to-Higher-Order-Predicate_RPAR_"></a>
<a id="RoseTree___All___intro-_LPAR_in-Omitting-Parameter-in-Argument-to-Higher-Order-Predicate_RPAR_"></a>


```proofscript
inductive List.All {α : Type u} (P : α → Prop) : List α → Prop
  | nil : All P []
  | cons {x xs} : P x → All P xs → All P (x :: xs)

structure RoseTree (α : Type u) where
  val : α
  children : List (RoseTree α)

inductive RoseTree.All (P : α → Prop) : RoseTree α → Prop
  | intro : P t.val → List.All (All P) t.children → All P t
```

Because the `RoseTree.All` type constructor must be partially applied in the argument to `List.All`, the unspecified argument (`t`) must not be a parameter of the `RoseTree.All` predicate. Making it an index to the right of the colon in the header of `RoseTree.All` allows this partial application to succeed.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Missing parameter(s) in occurrence of inductive type: In the expression
  List.All (All P) t.children
found
  All P
but expected all parameters to be specified:
  All P t

Note: All occurrences of an inductive type in the types of its constructors must specify its fixed parameters. Only indices can be omitted in a partial application of the type constructor.
```

