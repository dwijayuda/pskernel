<a id="lean___dependsOnNoncomputable"></a>

# ProofScript — About: dependsOnNoncomputable

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

The inherited error catalog explains invalid constructors, dependent eliminations, missing instances, unresolved names and other rejected programs. These are examples of failure, not snippets to copy into a successful program. Preserve native error IDs while mapping source positions back to .ps. A syntax overlay error should be distinguished from native elaboration, proof search, kernel rejection and unavailable target primitives.

**Compiler and coverage boundary.** Keep malformed, unsupported, cancelled, exhausted and internal-error outcomes distinct. Never turn an unsupported example into a permissive fallback or suppress a failed proof to make documentation appear runnable.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Error-Explanations/About___--dependsOnNoncomputable/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Error-Explanations/About___--dependsOnNoncomputable/index.html). Source Git blob: `c922ff3c9f39c8c3e43f2f88bd9019a1c40ef3cd`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## About: dependsOnNoncomputable

Error code: `lean.dependsOnNoncomputable`

*Declaration depends on noncomputable definitions but is not marked as noncomputable*

**Severity:**Error**Since:**4.22.0

This error indicates that the specified definition depends on one or more definitions that do not contain executable code and is therefore required to be marked as `noncomputable`. Such definitions can be type-checked but do not contain code that can be executed by Lean.

If you intended for the definition named in the error message to be noncomputable, marking it as `noncomputable` will resolve this error. If you did not, inspect the noncomputable definitions on which it depends: they may be noncomputable because they failed to compile, are `axiom`s, or were themselves marked as `noncomputable`. Making all of your definition's noncomputable dependencies computable will also resolve this error. See the manual section on [Modifiers](../../Definitions/Modifiers/index.md#declaration-modifiers) for more information about noncomputable definitions.

<a id="The-Lean-Language-Reference--Error-Explanations--About___--dependsOnNoncomputable--Examples"></a>
### Examples

<a id="Necessarily-Noncomputable-Function-Not-Appropriately-Marked"></a>
Necessarily Noncomputable Function Not Appropriately Marked   
<a id="error-example-next-next-button-0"></a>
Original
<a id="error-example-next-next-button-1"></a>
Fixed  
<a id="error-example-next-next-panel-0"></a>

```proofscript
axiom transform : Nat → Nat

def transformIfZero : Nat → Nat
  | 0 => transform 0
  | n => n
```

```lean
`transform` not supported by code generator; consider marking definition as `noncomputable`
```

<a id="error-example-next-next-panel-1"></a>
<a id="transformIfZero-_LPAR_in-Necessarily-Noncomputable-Function-Not-Appropriately-Marked_RPAR_"></a>


```proofscript
axiom transform : Nat → Nat

noncomputable def transformIfZero : Nat → Nat
  | 0 => transform 0
  | n => n
```

In this example, `transformIfZero` depends on the axiom `transform`. Because `transform` is an axiom, it does not contain any executable code; although the value `transform 0` has type `Nat`, there is no way to compute its value. Thus, `transformIfZero` must be marked `noncomputable` because its execution would depend on this axiom.

<a id="Noncomputable-Dependency-Can-Be-Made-Computable"></a>
Noncomputable Dependency Can Be Made Computable   
<a id="error-example-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-button-1"></a>
Fixed  
<a id="error-example-next-next-next-panel-0"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
noncomputable def getOrDefault [Nonempty α] : Option α → α
  | some x => x
  | none => Classical.ofNonempty

function endsOrDefault (ns : List Nat) : Nat × Nat :=
  let head := getOrDefault ns.head?
  let tail := getOrDefault ns.getLast?
  (head, tail)
```

```lean
failed to compile definition, consider marking it as 'noncomputable' because it depends on 'getOrDefault', which is 'noncomputable'
```

<a id="error-example-next-next-next-panel-1"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="endsOrDefault-_LPAR_in-Noncomputable-Dependency-Can-Be-Made-Computable_RPAR_"></a>


```proofscript
def getOrDefault [Inhabited α] : Option α → α
  | some x => x
  | none => default

function endsOrDefault (ns : List Nat) : Nat × Nat :=
  let head := getOrDefault ns.head?
  let tail := getOrDefault ns.getLast?
  (head, tail)
```

The original definition of `getOrDefault` is noncomputable due to its use of `Classical.choice`. Unlike in the preceding example, however, it is possible to implement a similar but computable version of `getOrDefault` (using the `Inhabited` type class), allowing `endsOrDefault` to be computable. (The differences between `Inhabited` and `Nonempty` are described in the documentation of inhabited types in the manual section on [Basic Classes](../../Type-Classes/Basic-Classes/index.md#basic-classes).)

<a id="Noncomputable-Instance-in-Namespace"></a>
Noncomputable Instance in Namespace   
<a id="error-example-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-button-1"></a>
Fixed  
<a id="error-example-next-next-next-next-panel-0"></a>

```proofscript
open Classical in
/--
Returns `y` if it is in the image of `f`,
or an element of the image of `f` otherwise.
-/
def fromImage (f : Nat → Nat) (y : Nat) :=
  if ∃ x, f x = y then
    y
  else
    f 0
```

```lean
failed to compile definition, consider marking it as 'noncomputable' because it depends on 'propDecidable', which is 'noncomputable'
```

<a id="error-example-next-next-next-next-panel-1"></a>
<a id="fromImage-_LPAR_in-Noncomputable-Instance-in-Namespace_RPAR_"></a>


```proofscript
open Classical in
/--
Returns `y` if it is in the image of `f`,
or an element of the image of `f` otherwise.
-/
noncomputable def fromImage (f : Nat → Nat) (y : Nat) :=
  if ∃ x, f x = y then
    y
  else
    f 0
```

The `Classical` namespace contains `Decidable` instances that are not computable. These are a common source of noncomputable dependencies that do not explicitly appear in the source code of a definition. In the above example, for instance, a `Decidable` instance for the proposition `∃ x, f x = y` is synthesized using a `Classical` decidability instance; therefore, `fromImage` must be marked `noncomputable`.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`transform` not supported by code generator; consider marking definition as `noncomputable`
```


### Display 2


```text
failed to compile definition, consider marking it as 'noncomputable' because it depends on 'getOrDefault', which is 'noncomputable'
```


### Display 3


```text
failed to compile definition, consider marking it as 'noncomputable' because it depends on 'propDecidable', which is 'noncomputable'
```

