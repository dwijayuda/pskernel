<a id="lean___invalidField"></a>

# ProofScript — About: invalidField

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

The inherited error catalog explains invalid constructors, dependent eliminations, missing instances, unresolved names and other rejected programs. These are examples of failure, not snippets to copy into a successful program. Preserve native error IDs while mapping source positions back to .ps. A syntax overlay error should be distinguished from native elaboration, proof search, kernel rejection and unavailable target primitives.

**Compiler and coverage boundary.** Keep malformed, unsupported, cancelled, exhausted and internal-error outcomes distinct. Never turn an unsupported example into a permissive fallback or suppress a failed proof to make documentation appear runnable.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Error-Explanations/About___--invalidField/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Error-Explanations/About___--invalidField/index.html). Source Git blob: `1ae0f360a93edfc5a7b05fd5b95ef79a130e5c2f`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## About: invalidField

Error code: `lean.invalidField`

*Generalized field notation used in a potentially ambiguous way.*

**Severity:**Error**Since:**4.22.0

This error indicates that an expression containing a dot followed by an identifier was encountered, and that it wasn't possible to understand the identifier as a field.

Lean's field notation is very powerful, but this can also make it confusing: the expression `color.value` can either be a single [identifier](../../Terms/Identifiers/index.md#identifiers-and-resolution). it can be a reference to the [field of a structure](../../The-Type-System/Inductive-Types/index.md#structure-fields), and it and be a calling a function on the value `color` with [generalized field notation](../../Terms/Function-Application/index.md#generalized-field-notation).

<a id="The-Lean-Language-Reference--Error-Explanations--About___--invalidField--Examples"></a>
### Examples

<a id="Incorrect-Field-Name"></a>
Incorrect Field Name   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

```proofscript
#eval (4 + 2).suc
```

```lean
Invalid field `suc`: The environment does not contain `Nat.suc`, so it is not possible to project the field `suc` from an expression
  4 + 2
of type `Nat`
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-1"></a>

```proofscript
#eval (4 + 1).succ
```

The simplest reason for an invalid field error is that the function being sought, like `Nat.suc`, does not exist.

<a id="Projecting-from-the-Wrong-Expression"></a>
Projecting from the Wrong Expression   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

```proofscript
#eval '>'.leftpad 10 ['a', 'b', 'c']
```

```lean
Invalid field `leftpad`: The environment does not contain `Char.leftpad`, so it is not possible to project the field `leftpad` from an expression
  '>'
of type `Char`
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-1"></a>

```proofscript
#eval ['a', 'b', 'c'].leftpad 10 '>'
```

The type of the expression before the dot entirely determines the function being called by the field projection. There is no `Char.leftpad`, and the only way to invoke `List.leftpad` with generalized field notation is to have the list come before the dot.

<a id="Type-is-Not-Specific"></a>
Type is Not Specific   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function double_plus_one {α} [Add α] (x : α) :=
   (x + x).succ
```

```lean
Invalid field notation: Field projection operates on types of the form `C ...` where C is a constant. The expression
  x + x
has type `α` which does not have the necessary form.
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-1"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="double_plus_one-_LPAR_in-Type-is-Not-Specific_RPAR_"></a>


```proofscript
function double_plus_one (x : Nat) :=
   (x + x).succ
```

The `Add` type class is sufficient for performing the addition `x + x`, but the `.succ` field notation cannot operate without knowing more about the actual type from which `succ` is being projected.

<a id="Insufficient-Type-Information-next"></a>
Insufficient Type Information   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

```proofscript
example := fun (n) => n.succ.succ
```

```lean
Invalid field notation: Type of
  n
is not known; cannot resolve field `succ`

Hint: Consider replacing the field projection with a call to one of the following:
  • `Fin.succ`
  • `Nat.succ`
  • `Lean.Level.succ`
  • `Std.PRange.succ`
  • `Lean.Level.PP.Result.succ`
  • `Std.Time.Internal.Bounded.LE.succ`
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-1"></a>

```proofscript
example := fun (n : Nat) => n.succ.succ
```

Generalized field notation can only be used when it is possible to determine the type that is being projected. Type annotations may need to be added to make generalized field notation work.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Invalid field `suc`: The environment does not contain `Nat.suc`, so it is not possible to project the field `suc` from an expression
  4 + 2
of type `Nat`
```


### Display 2


```text
6
```


### Display 3


```text
Invalid field `leftpad`: The environment does not contain `Char.leftpad`, so it is not possible to project the field `leftpad` from an expression
  '>'
of type `Char`
```


### Display 4


```text
['>', '>', '>', '>', '>', '>', '>', 'a', 'b', 'c']
```


### Display 5


```text
Invalid field notation: Field projection operates on types of the form `C ...` where C is a constant. The expression
  x + x
has type `α` which does not have the necessary form.
```


### Display 6


```text
Invalid field notation: Type of
  n
is not known; cannot resolve field `succ`

Hint: Consider replacing the field projection with a call to one of the following:
  • `Fin.succ`
  • `Nat.succ`
  • `Lean.Level.succ`
  • `Std.PRange.succ`
  • `Lean.Level.PP.Result.succ`
  • `Std.Time.Internal.Bounded.LE.succ`
```

