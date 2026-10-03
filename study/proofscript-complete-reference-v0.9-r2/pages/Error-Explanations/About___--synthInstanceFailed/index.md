<a id="lean___synthInstanceFailed"></a>

# ProofScript — About: synthInstanceFailed

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

The inherited error catalog explains invalid constructors, dependent eliminations, missing instances, unresolved names and other rejected programs. These are examples of failure, not snippets to copy into a successful program. Preserve native error IDs while mapping source positions back to .ps. A syntax overlay error should be distinguished from native elaboration, proof search, kernel rejection and unavailable target primitives.

**Compiler and coverage boundary.** Keep malformed, unsupported, cancelled, exhausted and internal-error outcomes distinct. Never turn an unsupported example into a permissive fallback or suppress a failed proof to make documentation appear runnable.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Error-Explanations/About___--synthInstanceFailed/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Error-Explanations/About___--synthInstanceFailed/index.html). Source Git blob: `772b8e43a365e8ffbb16fd3042b0b059ced8831e`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## About: synthInstanceFailed

Error code: `lean.synthInstanceFailed`

*Failed to synthesize instance of type class.*

**Severity:**Error**Since:**4.26.0

[Type classes](../../Type-Classes/index.md#type-classes) are the mechanism that Lean and many other programming languages use to handle overloaded operations. The code that handles a particular overloaded operation is an [*instance*](../../Type-Classes/index.md#--tech-term-instances) of a type class; deciding which instance to use for a given overloaded operation is called *synthesizing* an instance.

As an example, when Lean encounters an expression `x + y` where `x` and `y` both have type `Int`, it is necessary to look up how it should add two integers and also look up what the resulting type will be. This is described as synthesizing an instance of the type class `HAdd Int Int t` for some type `t`.

Many failures to synthesize an instance of a type class are the result of using the wrong binary operation. Both success and failure are not always straightforward, because some instances are defined in terms of other instances, and Lean must recursively search to find appropriate instances. It's possible to [inspect Lean's instance synthesis](../../Type-Classes/Instance-Synthesis/index.md#instance-search), and this can be helpful for diagnosing tricky failures of type class instance synthesis.

<a id="The-Lean-Language-Reference--Error-Explanations--About___--synthInstanceFailed--Examples"></a>
### Examples

<a id="Using-the-Wrong-Binary-Operation"></a>
Using the Wrong Binary Operation   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

```proofscript
#eval "A" + "3"
```

```lean
failed to synthesize instance of type class
  HAdd String String ?m.4

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-1"></a>

```proofscript
#eval "A" ++ "3"
```

The binary operation `+` is associated with the `HAdd` type class, and there's no way to add two strings. The binary operation `++`, associated with the `HAppend` type class, is the correct way to append strings.

<a id="Arguments-Have-the-Wrong-Type"></a>
Arguments Have the Wrong Type   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="x"></a>


```proofscript
const x : Int := 3
#eval x ++ "meters"
```

```lean
failed to synthesize instance of type class
  HAppend Int String ?m.4

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-1"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
const x : Int := 3
#eval ToString.toString x ++ "meters"
```

Lean does not allow integers and strings to be added directly. The function `ToString.toString` uses type class overloading to convert values to strings; by successfully searching for an instance of `ToString Int`, the second example will succeed.

<a id="Missing-Type-Class-Instance"></a>
Missing Type Class Instance   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed (derive instance when defining type)
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-2"></a>
Fixed (derive instance separately)
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-3"></a>
Fixed (define instance)  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
inductive MyColor where
  | chartreuse | sienna | thistle

function forceColor (oc : Option MyColor) :=
  oc.get!
```

```lean
failed to synthesize instance of type class
  Inhabited MyColor

Hint: Adding the command `deriving instance Inhabited for MyColor` may allow Lean to derive the missing instance.
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-1"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
inductive MyColor where
  | chartreuse | sienna | thistle
deriving Inhabited

function forceColor (oc : Option MyColor) :=
  oc.get!
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-2"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
inductive MyColor where
  | chartreuse | sienna | thistle

deriving instance Inhabited for MyColor

function forceColor (oc : Option MyColor) :=
  oc.get!
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-3"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
inductive MyColor where
  | chartreuse | sienna | thistle

instance : Inhabited MyColor where
  default := .sienna

function forceColor (oc : Option MyColor) :=
  oc.get!
```

Type class synthesis can fail because an instance of the type class simply needs to be provided. This commonly happens for type classes like `Repr`, `BEq`, `ToJson` and `Inhabited`. Lean can often [automatically generate instances of the type class with the `deriving` keyword](../../Type-Classes/Deriving-Instances/index.md#deriving-instances) either when the type is defined or with the stand-alone [`deriving`](../../Type-Classes/Deriving-Instances/index.md#Lean___Parser___Command___deriving-next) command.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
failed to synthesize instance of type class
  HAdd String String ?m.4

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```


### Display 2


```text
"A3"
```


### Display 3


```text
failed to synthesize instance of type class
  HAppend Int String ?m.4

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```


### Display 4


```text
"3meters"
```


### Display 5


```text
failed to synthesize instance of type class
  Inhabited MyColor

Hint: Adding the command `deriving instance Inhabited for MyColor` may allow Lean to derive the missing instance.
```

