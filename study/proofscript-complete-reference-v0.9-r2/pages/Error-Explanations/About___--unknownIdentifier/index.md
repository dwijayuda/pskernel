<a id="lean___unknownIdentifier"></a>

# ProofScript — About: unknownIdentifier

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

The inherited error catalog explains invalid constructors, dependent eliminations, missing instances, unresolved names and other rejected programs. These are examples of failure, not snippets to copy into a successful program. Preserve native error IDs while mapping source positions back to .ps. A syntax overlay error should be distinguished from native elaboration, proof search, kernel rejection and unavailable target primitives.

**Compiler and coverage boundary.** Keep malformed, unsupported, cancelled, exhausted and internal-error outcomes distinct. Never turn an unsupported example into a permissive fallback or suppress a failed proof to make documentation appear runnable.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Error-Explanations/About___--unknownIdentifier/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Error-Explanations/About___--unknownIdentifier/index.html). Source Git blob: `6dd529e3cfa58c88f703e5bb6e39d3f35609d524`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## About: unknownIdentifier

Error code: `lean.unknownIdentifier`

*Failed to resolve identifier to variable or constant.*

**Severity:**Error**Since:**4.23.0

This error means that Lean was unable to find a variable or constant matching the given name. More precisely, this means that the name could not be **resolved**, as described in the manual section on [Identifiers](../../Terms/Identifiers/index.md#identifiers-and-resolution): no interpretation of the input as the name of a local or section variable (if applicable), a previously declared global constant, or a projection of either of the preceding was valid. (“If applicable” refers to the fact that in some cases—e.g., the `#print` command's argument—names are resolved only to global constants.)

Note that this error message will display only one possible resolution of the identifier, but the presence of this error indicates failures for **all** possible names to which it might refer. For example, if the identifier `x` is entered with the namespaces `A` and `B` are open, the error message “Unknown identifier `x`” indicates that none of `x`, `A.x`, or `B.x` could be found (or that `A.x` or `B.x`, if either exists, is a protected declaration).

Common causes of this error include forgetting to import the module in which a constant is defined, omitting a constant's namespace when that namespace is not open, or attempting to refer to a local variable that is not in scope.

To help resolve some of these common issues, this error message is accompanied by a code action that suggests constant names similar to the one provided. These include constants in the environment as well as those that can be imported from other modules. Note that these suggestions are available only through supported code editors' built-in code action mechanisms and not as a hint in the error message itself.

<a id="The-Lean-Language-Reference--Error-Explanations--About___--unknownIdentifier--Examples"></a>
### Examples

<a id="Variable-Not-in-Scope"></a>
Variable Not in Scope   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

```proofscript
example (s : IO.FS.Stream) := do
  IO.withStdout s do
    let text := "Hello"
    IO.println text
  IO.println s!"Wrote '{text}' to stream"
```

```lean
Unknown identifier `text`
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-1"></a>

```proofscript
example (s : IO.FS.Stream) := do
  let text := "Hello"
  IO.withStdout s do
    IO.println text
  IO.println s!"Wrote '{text}' to stream"
```

An unknown identifier error occurs on the last line of this example because the variable `text` is not in scope. The `let`-binding on the third line is scoped to the inner [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do) block and cannot be accessed in the outer [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do) block. Moving this binding to the outer [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do) block—from which it remains in scope in the inner block as well—resolves the issue.

<a id="Missing-Namespace"></a>
Missing Namespace   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed (qualified name)
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-2"></a>
Fixed (open namespace)  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
inductive Color where
  | rgb (r g b : Nat)
  | grayscale (k : Nat)

const red : Color :=
  rgb 255 0 0
```

```lean
Unknown identifier `rgb`
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-1"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
inductive Color where
  | rgb (r g b : Nat)
  | grayscale (k : Nat)

const red : Color :=
  Color.rgb 255 0 0
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-2"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
inductive Color where
  | rgb (r g b : Nat)
  | grayscale (k : Nat)

open Color in
const red : Color :=
  rgb 255 0 0
```

In this example, the identifier `rgb` on the last line does not resolve to the `Color` constructor of that name. This is because the constructor's name is actually `Color.rgb`: all constructors of an inductive type have names in that type's namespace. Because the `Color` namespace is not open, the identifier `rgb` cannot be used without its namespace prefix.

One way to resolve this error is to provide the fully qualified constructor name `Color.rgb`; the dotted-identifier notation `.rgb` can also be used, since the expected type of `.rgb 255 0 0` is `Color`. Alternatively, one can open the `Color` namespace and continue to omit the `Color` prefix from the identifier.

<a id="Protected-Constant-Name-Without-Namespace-Prefix"></a>
Protected Constant Name Without Namespace Prefix   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed (qualified name)
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-2"></a>
Fixed (restricted open)  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
protected const A.x := ()

open A

example := x
```

```lean
Unknown identifier `x`
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-1"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
protected const A.x := ()

open A

example := A.x
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-2"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
protected const A.x := ()

open A (x)

example := x
```

In this example, because the constant `A.x` is `protected`, it cannot be referred to by the suffix `x` even with the namespace `A` open. Therefore, the identifier `x` fails to resolve. Instead, to refer to a `protected` constant, it is necessary to include at least its innermost namespace—in this case, `A`. Alternatively, the **restricted opening** syntax—demonstrated in the second corrected example—allows a `protected` constant to be referred to by its unqualified name, without opening the remainder of the namespace in which it occurs (see the manual section on [Namespaces and Sections](../../Namespaces-and-Sections/index.md#namespaces-sections) for details).

<a id="Unresolvable-Name-Inferred-by-Dotted-Identifier-Notation"></a>
Unresolvable Name Inferred by Dotted-Identifier Notation   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed (generalized field notation)
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-2"></a>
Fixed (qualified name)  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function disjoinToNat (b₁ b₂ : Bool) : Nat :=
  .toNat (b₁ || b₂)
```

```lean
Unknown constant `Nat.toNat`

Note: Inferred this name from the expected resulting type of `.toNat`:
  Nat
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-1"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function disjoinToNat (b₁ b₂ : Bool) : Nat :=
  (b₁ || b₂).toNat
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-2"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function disjoinToNat (b₁ b₂ : Bool) : Nat :=
  Bool.toNat (b₁ || b₂)
```

In this example, the dotted-identifier notation `.toNat` causes Lean to infer an unresolvable name (`Nat.toNat`). The namespace used by dotted-identifier notation is always inferred from the expected type of the expression in which it occurs, which—due to the type annotation on `disjoinToNat`—is `Nat` in this example. To use the namespace of an argument's type—as the author of this code seemingly intended—use **generalized field notation** as shown in the first corrected example. Alternatively, the correct namespace can be explicitly specified by writing the fully qualified function name.

<a id="Auto-bound-variables"></a>
Auto-bound variables   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed (modifying options)
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-2"></a>
Fixed (add implicit bindings for the unknown identifiers)  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="thisBreaks-_LPAR_in-Auto-bound-variables_RPAR_"></a>
<a id="thisAlsoBreaks-_LPAR_in-Auto-bound-variables_RPAR_"></a>


```proofscript
set_option relaxedAutoImplicit false in
function thisBreaks (x : α₁) (y : size₁) := ()

set_option autoImplicit false in
function thisAlsoBreaks (x : α₂) (y : size₂) := ()
```

```lean
Unknown identifier `size₁`

Note: It is not possible to treat `size₁` as an implicitly bound variable here because it has multiple characters while the `relaxedAutoImplicit` option is set to `false`.
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-1"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
set_option relaxedAutoImplicit true in
function thisWorks (x : α₁) (y : size₁) := ()

set_option autoImplicit true in
function thisAlsoWorks (x : α₂) (y : size₂) := ()
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-2"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
set_option relaxedAutoImplicit false in
function thisWorks {size₁} (x : α₁) (y : size₁) := ()

set_option autoImplicit false in
function thisAlsoWorks {α₂ size₂} (x : α₂) (y : size₂) := ()
```

Lean's default behavior, when it encounters an identifier it can't identify in the type of a definition, is to add [automatic implicit parameters](../../Definitions/Headers-and-Signatures/index.md#automatic-implicit-parameters) for those unknown identifiers. However, many files or projects disable this feature by setting the `autoImplicit` or `relaxedAutoImplicit` options to `false`.

Without re-enabling the `autoImplicit` or `relaxedAutoImplicit` options, the easiest way to fix this error is to add the unknown identifiers as [ordinary implicit parameters](../../Terms/Functions/index.md#implicit-functions) as shown in the example above.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Unknown identifier `text`
```


### Display 2


```text
Unknown identifier `rgb`
```


### Display 3


```text
Unknown identifier `x`
```


### Display 4


```text
Unknown constant `Nat.toNat`

Note: Inferred this name from the expected resulting type of `.toNat`:
  Nat
```


### Display 5


```text
Unknown identifier `size₁`

Note: It is not possible to treat `size₁` as an implicitly bound variable here because it has multiple characters while the `relaxedAutoImplicit` option is set to `false`.
```


### Display 6


```text
Unknown identifier `α₂`

Note: It is not possible to treat `α₂` as an implicitly bound variable here because the `autoImplicit` option is set to `false`.
```


### Display 7


```text
Unknown identifier `size₂`

Note: It is not possible to treat `size₂` as an implicitly bound variable here because the `autoImplicit` option is set to `false`.
```


### Display 8


```text
Variable name `x` is not explicitly referenced.

Hint: The binding can be removed (if unused) or named `_` (if used implicitly). Alternatively, prefix the name with `_` to silence this warning:
  [apply] _x

Note: This linter can be disabled with `set_option linter.unusedVariables false`
```


### Display 9


```text
Variable name `y` is not explicitly referenced.

Hint: The binding can be removed (if unused) or named `_` (if used implicitly). Alternatively, prefix the name with `_` to silence this warning:
  [apply] _y

Note: This linter can be disabled with `set_option linter.unusedVariables false`
```

