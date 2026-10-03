<a id="function-application"></a>

# ProofScript — 13.4. Function Application

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Terms keep native binding, precedence and type-directed elaboration. D-CALL is adjacency-sensitive: f(x,y) supplies two curried arguments; f((x,y)) and native f (x,y) supply one tuple. An empty call passes Unit. Lambdas use fun, records use :=, and match patterns remain native even when constructor terms use decorated calls. Braces delimit specific categories; they do not disable the native layout checks inside them.

**Compiler and coverage boundary.** Preserve grouping that influences elaboration. Do not flatten nested calls, split patterns on arbitrary bars, or rewrite punctuation inside strings and quotations.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Terms/Function-Application/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Terms/Function-Application/index.html). Source Git blob: `6481a3445b37e3b7813407da92050350e07dc23a`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 13.4. Function Application

Ordinarily, function application is written using juxtaposition: the argument is placed after the function, with at least one space between them. In Lean's type theory, all functions take exactly one argument and produce exactly one value. All function applications combine a single function with a single argument. Multiple arguments are represented via currying.

The high-level term language treats a function together with one or more arguments as a single unit, and supports additional features such as implicit, optional, and by-name arguments along with ordinary positional arguments. The elaborator converts these to the simpler model of the core type theory.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Function Application**

A function application consists of a term followed by one or more arguments, or by zero or more arguments and a final 
<a id="--tech-term-ellipsis"></a>
ellipsis.

<a id="Manual___FreeSyntax___more"></a>

```ebnf
term ::= ...
    | term argument+
    | term argument* ..
```

<a id="Lean___Parser___Term___argument"></a>

**syntax**

**Arguments**

Function arguments are either terms or 
<a id="--tech-term-named-arguments"></a>
named arguments.

<a id="Manual___FreeSyntax___more-next"></a>

```ebnf
argument ::= ...
    | term
    | ((ident | _:ident) :=term)
```

The function's core-language type determines the placement of the arguments in the final expression. Function types include names for their expected parameters. In Lean's core language, non-dependent function types are encoded as dependent function types in which the parameter name does not occur in the body. Furthermore, they are chosen internally such that they cannot be written as the name of a named argument; this is important to prevent accidental capture.

Each parameter expected by the function has a name. Recurring over the function's argument types, arguments are selected from the sequence of arguments as follows:

- If the parameter's name matches the name provided for a named argument, then that argument is selected.
- If the parameter is [implicit](../Functions/index.md#--tech-term-implicit), a fresh metavariable is created with the parameter's type and selected.
- If the parameter is [instance implicit](../../Type-Classes/index.md#--tech-term-instance-implicit), a fresh instance metavariable is created with the parameter's type and inserted. Instance metavariables are scheduled for later synthesis.
- If the parameter is a [strict implicit](../Functions/index.md#--tech-term-Strict-implicit) parameter and there are any named or positional arguments that have not yet been selected, a fresh metavariable is created with the parameter's type and selected.
- If the parameter is explicit, then the next positional argument is selected and elaborated. If there are no positional arguments:

   

  - If the parameter is declared as an [optional parameter](../../Definitions/Headers-and-Signatures/index.md#--tech-term-optional-parameters), then its default value is selected as the argument.
  - If the parameter is an [automatic parameter](../../Definitions/Headers-and-Signatures/index.md#--tech-term-automatic-parameters) then its associated tactic script is executed to construct the argument.
  - If the parameter is neither optional nor automatic, and no ellipsis is present, then a fresh variable is selected as the argument. If there is an ellipsis, a fresh metavariable is selected as if the argument were implicit.

As a special case, when the function application occurs in a [pattern](../Pattern-Matching/index.md#pattern-matching) and there is an ellipsis, optional and automatic arguments become universal patterns (`_`) instead of being inserted.

It is an error if the type is not a function type and arguments remain. After all arguments have been inserted and there is an ellipsis, then the missing arguments are all set to fresh metavariables, just as if they were implicit arguments. If any fresh variables were created for missing explicit positional arguments, the entire application is wrapped in a `fun` term that binds them. Finally, instance synthesis is invoked and as many metavariables as possible are solved:

1. A type is inferred for the entire function application. This may cause some metavariables to be solved due to unification that occurs during type inference.
2. The instance metavariables are synthesized. [Default instances](../../Type-Classes/Instance-Synthesis/index.md#--tech-term-default-instances) are only used if the inferred type is a metavariable that is the output parameter of one of the instances.
3. If there is an expected type, it is unified with the inferred type; however, errors resulting from this unification are discarded. If the expected and inferred types can be equal, unification can solve leftover implicit argument metavariables. If they can't be equal, an error is not thrown because a surrounding elaborator may be able to insert [coercions](../../Coercions/index.md#--tech-term-coercion) or [monad lifts](../../Functors___-Monads-and--do--Notation/Lifting-Monads/index.md#--tech-term-lifting).

<a id="Named-Arguments"></a>
Named Arguments 

The [`#check`](../../Interacting-with-Lean/index.md#Lean___Parser___Command___check) command can be used to inspect the arguments that were inserted for a function call.

The function `sum3` takes three explicit `Nat` parameters, named `x`, `y`, and `z`.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="sum3-_LPAR_in-Named-Arguments_RPAR_"></a>


```proofscript
function sum3 (x y z : Nat) : Nat := x + y + z
```

All three arguments can be provided positionally.

```proofscript
#check sum3 1 3 8
```

```lean
sum3 1 3 8 : Nat
```

They can also be provided by name.

```proofscript
#check sum3 (x := 1) (y := 3) (z := 8)
```

```lean
sum3 1 3 8 : Nat
```

When arguments are provided by name, it can be in any order.

```proofscript
#check sum3 (y := 3) (z := 8) (x := 1)
```

```lean
sum3 1 3 8 : Nat
```

Named and positional arguments may be freely intermixed.

```proofscript
#check sum3 1 (z := 8) (y := 3)
```

```lean
sum3 1 3 8 : Nat
```

Named and positional arguments may be freely intermixed. If an argument is provided by name, it is used, even if it occurs after a positional argument that could have been used.

```proofscript
#check sum3 1 (x := 8) (y := 3)
```

```lean
sum3 8 3 1 : Nat
```

If a named argument is to be inserted after arguments that aren't provided, a function is created in which the provided argument is filled out.

```proofscript
#check sum3 (z := 8)
```

```lean
fun x y => sum3 x y 8 : Nat → Nat → Nat
```

Behind the scenes, the names of the arguments are preserved in the function type. This means that the remaining arguments can again be passed by name.

```proofscript
#check (sum3 (z := 8)) (y := 1)
```

```lean
fun x => (fun x y => sum3 x y 8) x 1 : Nat → Nat
```

Parameter names are taken from the function's *type*, and the names used for function parameters don't need to match the names used in the type. This means that local bindings that conflict with a parameter's name don't prevent the use of named parameters, because Lean avoids this conflicts by renaming the function's parameter while leaving the name intact in the type.

```proofscript
#check let x := 15; sum3 (z := x)
```

Here, the `x` that named `sum3`'s first argument has been replaced, so as to not conflict with the surrounding `let`:

```lean
let x := 15;
fun x_1 y => sum3 x_1 y x : Nat → Nat → Nat
```

Even though `x` was renamed, it can still be passed by name:

```proofscript
#check (let x := 15; sum3 (z := x)) (x := 4)
```

```lean
(let x := 15;
  fun x_1 y => sum3 x_1 y x)
  4 : Nat → Nat
```

This is because the name `x` is still used in the type. Enabling the option `pp.piBinderNames` shows the parameter names in the type:

```proofscript
set_option pp.piBinderNames true in
#check let x := 15; sum3 (z := x)
```

```lean
let x := 15;
fun x_1 y => sum3 x_1 y x : (x y : Nat) → Nat
```

Optional and automatic parameters are not part of Lean's core type theory. They are encoded using the `optParam` and `autoParam` [gadgets](../../Type-Classes/Class-Declarations/index.md#--tech-term-gadgets).

<a id="optParam"></a>

**def**

```text
optParam.{u} (α : Sort u) (default : α) : Sort u
```

Gadget for optional parameter support.

A binder like `(x : α := default)` in a declaration is syntax sugar for `x : optParam α default`, and triggers the elaborator to attempt to use `default` to supply the argument if it is not supplied.

<a id="autoParam"></a>

**def**

```text
autoParam.{u} (α : Sort u) (tactic : Lean.Syntax) : Sort u
```

Gadget for automatic parameter support. This is similar to the `optParam` gadget, but it uses the given tactic. Like `optParam`, this gadget only affects elaboration. For example, the tactic will *not* be invoked during type class resolution.

<a id="generalized-field-notation"></a>
### 13.4.1. Generalized Field Notation

The [section on structure fields](../../The-Type-System/Inductive-Types/index.md#structure-fields) describes the notation for projecting a field from a term whose type is a structure. Generalized field notation consists of a term followed by a dot (`.`) and an identifier, not separated by spaces.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Field Notation**

<a id="Lean___Parser___Term___proj"></a>

```ebnf
term ::= ...
    | term.ident
```

If a term's type is a constant applied to zero or more arguments, then 
<a id="--tech-term-field-notation"></a>
field notation can be used to apply a function to it, regardless of whether the term is a structure or type class instance that has fields. The use of field notation to apply other functions is called 
<a id="--tech-term-generalized-field-notation"></a>
*generalized field notation*.

The identifier after the dot is looked up in the namespace of the term's type, which is the constant's name. If the type is not an application of a constant (e.g. a metavariable or a universe) then it doesn't have a namespace and generalized field notation cannot be used. As a special case, if an expression is a function, generalized field notation will look in the `Function` namespace. Therefore, `Nat.add.uncurry` is a use of generalized field notation that is equivalent to `Function.uncurry Nat.add`.

If the field is not found, but the constant can be unfolded to yield a further type which is a constant or application of a constant, then the process is repeated with the new constant.

When a function is found, the term before the dot becomes an argument to the function. Specifically, it becomes the first explicit argument that would not be a type error. Aside from that, the application is elaborated as usual.

<a id="Generalized-Field-Notation"></a>
Generalized Field Notation 

The type `Username` is a constant, so functions in the `Username` namespace can be applied to terms with type `Username` with generalized field notation.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Username-_LPAR_in-Generalized-Field-Notation_RPAR_"></a>


```proofscript
const Username := String
```

One such function is `Username.validate`, which checks that a username contains no leading whitespace and that only a small set of acceptable characters are used. In its definition, generalized field notation is used to call the functions `String.isPrefixOf`, `String.any`, `Char.isAlpha`, and `Char.isDigit`. In the case of `String.isPrefixOf`, which takes two `String` arguments, `" "` is used as the first because it's the term before the dot. `String.any` can be called on `name` using generalized field notation even though it has type `Username` because `Username.any` is not defined and `Username` unfolds to `String`.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Username___validate-_LPAR_in-Generalized-Field-Notation_RPAR_"></a>
<a id="Username___validate___notOk-_LPAR_in-Generalized-Field-Notation_RPAR_"></a>
<a id="adminUser-_LPAR_in-Generalized-Field-Notation_RPAR_"></a>


```proofscript
function Username.validate (name : Username) : Except String Unit := do
  if " ".isPrefixOf name then
    throw "Unexpected leading whitespace"
  if name.any notOk then
    throw "Unexpected character"
  return ()
where
  notOk (c : Char) : Bool :=
    !c.isAlpha &&
    !c.isDigit &&
    !c ∈ ['_', ' ']

const adminUser : Username := "admin"
```

However, `Username.validate` can't be called on `"admin"` using field notation, because `String` does not unfold to `Username`.

```proofscript
#eval "admin".validate
```

```lean
Invalid field `validate`: The environment does not contain `String.validate`, so it is not possible to project the field `validate` from an expression
  "admin"
of type `String`
```

`adminUser`, on the other hand, has type `Username`, so the `Username.validate` function can be invoked with generalized field notation:

```proofscript
#eval adminUser.validate
```

```lean
Except.ok ()
```

Going in the other direction, `String.any` **can** be called on the `Username` value `adminUser` with generalized field notation, because the type `Username` unfolds to `String`.

```proofscript
#eval adminUser.any (· == 'm')
```

```lean
true
```

<a id="pp___fieldNotation"></a>

**option**

```text
pp.fieldNotation
```

Default value: `true`

(pretty printer) use field notation when pretty printing, including for structure projections, unless '@[pp_nodot]' is applied

<a id="attr-next-next-next-next-next-next-next-next"></a>

**attribute**

**Controlling Field Notation**

The `pp_nodot` attribute causes Lean's pretty printer to not use field notation when printing a function.

<a id="Lean___Parser___Attr___simple-next-next-next-next-next-next"></a>

```ebnf
attr ::= ...
    | pp_nodot
```

<a id="Turning-Off-Field-Notation"></a>
Turning Off Field Notation 

`Nat.half` is printed using field notation by default.
<a id="Nat___half-_LPAR_in-Turning-Off-Field-Notation_RPAR_"></a>


```proofscript
def Nat.half : Nat → Nat
  | 0 | 1 => 0
  | n + 2 => n.half + 1
```

```proofscript
#check Nat.half Nat.zero
```

```lean
Nat.zero.half : Nat
```

Adding `pp_nodot` to `Nat.half` causes ordinary function application syntax to be used instead when displaying the term.

```proofscript
attribute [pp_nodot] Nat.half

#check Nat.half Nat.zero
```

```lean
Nat.half Nat.zero : Nat
```

<a id="The-Lean-Language-Reference--Terms--Function-Application--Pipeline-Syntax"></a>
### 13.4.2. Pipeline Syntax

Pipeline syntax provides alternative ways to write function applications. Repeated pipelines use parsing precedence instead of nested parentheses to nest applications of functions to positional arguments.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Pipelines**

Right pipe notation applies the term to the right of the pipe to the one on its left.

<a id="_FLQQ_term_____GT___FLQQ_"></a>

```ebnf
term ::= ...
    | term |> term
```

Left pipe notation applies the term on the left of the pipe to the one on its right.

<a id="_FLQQ_term__LT______FLQQ_"></a>

```ebnf
term ::= ...
    | term <| term
```

The intuition behind right pipeline notation is that the values on the left are being fed to the first function, its results are fed to the second one, and so forth. In left pipeline notation, values on the right are fed leftwards.

<a id="Right-pipeline-notation"></a>
Right pipeline notation 

Right pipelines can be used to call a series of functions on a term. For readers, they tend to emphasize the data that's being transformed.

```proofscript
#eval "Hello!" |> String.toList |> List.reverse |> List.head!
```

```lean
'!'
```

<a id="Left-pipeline-notation"></a>
Left pipeline notation 

Left pipelines can be used to call a series of functions on a term. They tend to emphasize the functions over the data.

```proofscript
#eval List.head! <| List.reverse <| String.toList <| "Hello!"
```

```lean
'!'
```

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Pipeline Fields**

There is a version of pipeline notation that's used for [generalized field notation](index.md#--tech-term-generalized-field-notation).

<a id="Lean___Parser___Term___pipeProj"></a>

```ebnf
term ::= ...
    | term |>.ident
```

<a id="Lean___Parser___Term___pipeProj-next"></a>

```ebnf
term ::= ...
    | term |>.fieldIdx
```

`e |>.f arg` is an alternative syntax for `(e).f arg`.

<a id="Pipeline-Fields"></a>
Pipeline Fields 

Some functions are inconvenient to use with pipelines because their argument order is not conducive. For example, `Array.push` takes an array as its first argument, not a `Nat`, leading to this error:

```proofscript
#eval #[1, 2, 3] |> Array.push 4
```

```lean
failed to synthesize instance of type class
  OfNat (Array ?m.4) 4
numerals are polymorphic in Lean, but the numeral `4` cannot be used in a context where the expected type is
  Array ?m.4
due to the absence of the instance above

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

Using pipeline field notation causes the array to be inserted at the first type-correct position:

```proofscript
#eval #[1, 2, 3] |>.push 4
```

```lean
#[1, 2, 3, 4]
```

This process can be iterated:

```proofscript
#eval #[1, 2, 3] |>.push 4 |>.reverse |>.push 0 |>.reverse
```

```lean
#[0, 1, 2, 3, 4]
```

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
The *extended field notation* `e.f` is roughly short for `T.f e` where `T` is the type of `e`.
More precisely,
* if `e` is of a function type, `e.f` is translated to `Function.f (p := e)`
  where `p` is the first explicit parameter of function type
* if `e` is of a named type `T ...` and there is a declaration `T.f` (possibly from `export`),
  `e.f` is translated to `T.f (p := e)` where `p` is the first explicit parameter of type `T ...`
* otherwise, if `e` is of a structure type,
  the above is repeated for every base type of the structure.

The field index notation `e.i`, where `i` is a positive number,
is short for accessing the `i`-th field (1-indexed) of `e` if it is of a structure type.
```


### Display 2


```text
A pipe operator that feeds values from the left into functions on the right.

`x |> f` means the same as `f x`, and it chains such that `x |> f |> g` is interpreted as `g (f x)`.
```


### Display 3


```text
A pipe operator that feeds values from the right into functions on the left.

`f <| x` means the same as `f x`, except that it parses `x` with lower precedence, which means that
`f <| g <| x` is interpreted as `f (g x)` rather than `(f g) x`.
```


### Display 4


```text
`e |>.x` is a shorthand for `(e).x`.
It is especially useful for avoiding parentheses with repeated applications.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
sum3 1 3 8 : Nat
```


### Display 2


```text
sum3 8 3 1 : Nat
```


### Display 3


```text
fun x y => sum3 x y 8 : Nat → Nat → Nat
```


### Display 4


```text
fun x => (fun x y => sum3 x y 8) x 1 : Nat → Nat
```


### Display 5


```text
let x := 15;
fun x_1 y => sum3 x_1 y x : Nat → Nat → Nat
```


### Display 6


```text
(let x := 15;
  fun x_1 y => sum3 x_1 y x)
  4 : Nat → Nat
```


### Display 7


```text
let x := 15;
fun x_1 y => sum3 x_1 y x : (x y : Nat) → Nat
```


### Display 8


```text
Invalid field `validate`: The environment does not contain `String.validate`, so it is not possible to project the field `validate` from an expression
  "admin"
of type `String`
```


### Display 9


```text
Except.ok ()
```


### Display 10


```text
true
```


### Display 11


```text
Nat.zero.half : Nat
```


### Display 12


```text
Nat.half Nat.zero : Nat
```


### Display 13


```text
'!'
```


### Display 14


```text
failed to synthesize instance of type class
  OfNat (Array ?m.4) 4
numerals are polymorphic in Lean, but the numeral `4` cannot be used in a context where the expected type is
  Array ?m.4
due to the absence of the instance above

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```


### Display 15


```text
#[1, 2, 3, 4]
```


### Display 16


```text
#[0, 1, 2, 3, 4]
```

