<a id="deriving-instances"></a>

# ProofScript — 10.4. Deriving Instances

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Classes are native type-directed interfaces, not JavaScript classes. Instances provide dictionaries and associated evidence. Inference uses the pinned priority and search behavior, so importing an instance can affect elaboration. Derived instances are generated declarations that must be checked. Boolean equality and hashing require laws when used for logical claims.

**Compiler and coverage boundary.** Braced class fields use native field-declaration layout. Instance initializers use their own native sequence grammar, including semicolons only where that grammar permits them.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Type-Classes/Deriving-Instances/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Type-Classes/Deriving-Instances/index.html). Source Git blob: `4752616ca4d10df1df272b216df21442e4c0423d`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 10.4. Deriving Instances

Lean can automatically generate instances for many classes, a process known as 
<a id="--tech-term-deriving"></a>
*deriving* instances. Instance deriving can be invoked either when defining a type or as a stand-alone command.

<a id="Lean___Parser___Command___optDeriving"></a>

**syntax**

**Instance Deriving (Optional)**

As part of a command that creates a new inductive type, a `deriving` clause specifies a comma-separated list of class names for which instances should be generated:

<a id="Lean___Parser___Command___optDeriving-next"></a>

```ebnf
optDeriving ::=
    (deriving derivingClass,*)?
```

<a id="Lean___Parser___Command___deriving"></a>

**syntax**

**Stand-Alone Deriving of Instances**

The stand-alone [`deriving`](index.md#Lean___Parser___Command___deriving-next) command specifies a number of class names and subject names. Each of the specified classes are derived for each of the specified subjects.

<a id="Lean___Parser___Command___deriving-next"></a>

```ebnf
command ::= ...
    | deriving instance derivingClass,* for term,*
```

<a id="Deriving-Multiple-Classes"></a>
Deriving Multiple Classes 

After specifying multiple classes to derive for multiple types, as in this code:
<a id="A-_LPAR_in-Deriving-Multiple-Classes_RPAR_"></a>
<a id="B-_LPAR_in-Deriving-Multiple-Classes_RPAR_"></a>


```proofscript
structure A where
structure B where

deriving instance BEq, Repr for A, B
```

all the instances exist for all the types, so all four [`#synth`](../../Interacting-with-Lean/index.md#Lean___Parser___Command___synth) commands succeed:

```proofscript
#synth BEq A
#synth BEq B
#synth Repr A
#synth Repr B
```

<a id="deriving-handlers"></a>
### 10.4.1. Deriving Handlers

Instance deriving uses a table of 
<a id="--tech-term-deriving-handlers"></a>
*deriving handlers* that maps type class names to metaprograms that derive instances for them. Deriving handlers may be added to the table using `registerDerivingHandler`, which should be called in an `initialize` block. Each deriving handler should have the type `Array Name → CommandElabM Bool`. When a user requests that an instance of a class be derived, its registered handlers are called one at a time. They are provided with all of the names in the mutual block for which the instance is to be derived, and should either correctly derive an instance and return `true` or have no effect and return `false`. When a handler returns `true`, no further handlers are called.

Lean includes deriving handlers for the following classes:

- `BEq`
- `DecidableEq`
- `Hashable`
- `Inhabited`
- `LawfulBEq`
- `Nonempty`
- `Ord`
- `ReflBEq`
- `Repr`
- `SizeOf`
- `TypeName`

<a id="Lean___Elab___registerDerivingHandler"></a>

**def**

```text
Lean.Elab.registerDerivingHandler (className : Name)
  (handler : DerivingHandler) : IO Unit
```

Registers a deriving handler for a class. This function should be called in an `initialize` block.

A `DerivingHandler` is called on the fully qualified names of all types it is running for. For example, `deriving instance Foo for Bar, Baz` invokes ``fooHandler #[`Bar, `Baz]``.

<a id="Deriving-Handlers"></a>
Deriving Handlers 

Instances of the `IsEnum` class demonstrate that a type is a finite enumeration by providing a bijection between the type and a suitably-sized `Fin`:
<a id="IsEnum-_LPAR_in-Deriving-Handlers_RPAR_"></a>
<a id="IsEnum___size-_LPAR_in-Deriving-Handlers_RPAR_"></a>
<a id="IsEnum___toIdx-_LPAR_in-Deriving-Handlers_RPAR_"></a>
<a id="IsEnum___fromIdx-_LPAR_in-Deriving-Handlers_RPAR_"></a>
<a id="IsEnum___to_from_id-_LPAR_in-Deriving-Handlers_RPAR_"></a>
<a id="IsEnum___from_to_id-_LPAR_in-Deriving-Handlers_RPAR_"></a>


```proofscript
class IsEnum (α : Type) where
  size : Nat
  toIdx : α → Fin size
  fromIdx : Fin size → α
  to_from_id : ∀ (i : Fin size), toIdx (fromIdx i) = i
  from_to_id : ∀ (x : α), fromIdx (toIdx x) = x
```

For inductive types that are trivial enumerations, where no constructor expects any parameters, instances of this class are quite repetitive. The instance for `Bool` is typical:

```proofscript
instance : IsEnum Bool where
  size := 2
  toIdx
    | false => 0
    | true => 1
  fromIdx
    | 0 => false
    | 1 => true
  to_from_id
    | 0 => rfl
    | 1 => rfl
  from_to_id
    | false => rfl
    | true => rfl
```

The deriving handler programmatically constructs each pattern case, by analogy to the `IsEnum Bool` implementation:
<a id="deriveIsEnum-_LPAR_in-Deriving-Handlers_RPAR_"></a>


```proofscript
open Lean Elab Parser Term Command

def deriveIsEnum (declNames : Array Name) : CommandElabM Bool := do
  if h : declNames.size = 1 then
    let env ← getEnv
    if let some (.inductInfo ind) := env.find? declNames[0] then
      let mut tos : Array (TSyntax ``matchAlt) := #[]
      let mut froms := #[]
      let mut to_froms := #[]
      let mut from_tos := #[]
      let mut i := 0

      for ctorName in ind.ctors do
        let c := mkIdent ctorName
        let n := Syntax.mkNumLit (toString i)

        tos      := tos.push      (← `(matchAltExpr| | $c => $n))
        from_tos := from_tos.push (← `(matchAltExpr| | $c => rfl))
        froms    := froms.push    (← `(matchAltExpr| | $n => $c))
        to_froms := to_froms.push (← `(matchAltExpr| | $n => rfl))

        i := i + 1

      let cmd ← `(instance : IsEnum $(mkIdent declNames[0]) where
                    size := $(quote ind.ctors.length)
                    toIdx $tos:matchAlt*
                    fromIdx $froms:matchAlt*
                    to_from_id $to_froms:matchAlt*
                    from_to_id $from_tos:matchAlt*)
      elabCommand cmd

      return true
  return false

initialize
  registerDerivingHandler ``IsEnum deriveIsEnum
```

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
instBEqA
```


### Display 2


```text
instBEqB
```


### Display 3


```text
instReprA
```


### Display 4


```text
instReprB
```

