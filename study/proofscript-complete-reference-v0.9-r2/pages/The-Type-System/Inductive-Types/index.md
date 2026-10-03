<a id="inductive-types"></a>

# ProofScript — 4.4. Inductive Types

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Functions, propositions, universes, inductives and quotients retain their Lean meaning. A proof is an inhabitant of a proposition; Boolean truth is not the same object. Parameters may determine later parameter types. Universe levels cannot be approximated as machine integer ranks. Inductive constructors require the native positivity, universe, parameter and index checks. Quotient eliminators must respect their relation, rather than use runtime object identity.

**Compiler and coverage boundary.** Use exact declared core rules and axiom policies. Library names and hash matches alone cannot authorize primitive reductions. Soundness and exact acceptance equivalence are distinct obligations.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The-Type-System/Inductive-Types/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The-Type-System/Inductive-Types/index.html). Source Git blob: `492a70fb1c08fb325d94032e1db23f8622f5cdbf`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next"></a>

---

## 4.4. Inductive Types

<a id="--tech-term-Inductive-types"></a>
*Inductive types* are the primary means of introducing new types to Lean. While [universes](../Universes/index.md#--tech-term-universes), [functions](../Functions/index.md#--tech-term-Functions), and [quotient types](../Quotients/index.md#--tech-term-Quotient-types) are built-in primitives that could not be added by users, every other type in Lean is either an inductive type or defined in terms of universes, functions, and inductive types. Inductive types are specified by their 
<a id="--tech-term-type-constructors"></a>
*type constructors* 
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
 and their 
<a id="--tech-term-constructors"></a>
*constructors*; 
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
 their other properties are derived from these. Each inductive type has a single type constructor, which may take both [universe parameters](../Universes/index.md#--tech-term-universe-parameters) and ordinary parameters. Inductive types may have any number of constructors; these constructors introduce new values whose types are headed by the inductive type's type constructor.

Based on the type constructor and the constructors for an inductive type, Lean derives a 
<a id="--tech-term-recursor"></a>
*recursor*
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
. Logically, recursors represent induction principles or elimination rules; computationally, they represent primitive recursive computations. The termination of recursive functions is justified by translating them into uses of the recursors, so Lean's kernel only needs to perform type checking of recursor applications, rather than including a separate termination analysis. Lean additionally produces a number of helper constructions based on the recursor,The term *recursor* is always used, even for non-recursive types. which are used elsewhere in the system.

*Structures* are a special case of inductive types that have exactly one constructor. When a structure is declared, Lean generates helpers that enable additional language features to be used with the new structure.

This section describes the specific details of the syntax used to specify both inductive types and structures, the new constants and definitions in the environment that result from inductive type declarations, and the run-time representation of inductive types' values in compiled code.

<a id="inductive-declarations"></a>
### 4.4.1. Inductive Type Declarations

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Inductive Type Declarations**

<a id="Lean___Parser___Command___declaration"></a>

```ebnf
command ::= ...
    | declModifiers
      inductive declId optDeclSig where
        (| declModifiers ident optDeclSig)*
      (deriving ident,*)?
```

Declares a new inductive type. The meaning of the 

```ebnf
declModifiers
```

 is as described in the section [on declaration modifiers](../../Definitions/Modifiers/index.md#declaration-modifiers).

After declaring an inductive type, its type constructor, constructors, and recursor are present in the environment. New inductive types extend Lean's core logic—they are not encoded or represented by some other already-present data. Inductive type declarations must satisfy [a number of well-formedness requirements](index.md#well-formed-inductives) to ensure that the logic remains consistent.

The first line of the declaration, from `inductive` to `where`, specifies the new [type constructor](index.md#--tech-term-type-constructors)'s name and type. If a type signature for the type constructor is provided, then its result type must be a [universe](../Universes/index.md#--tech-term-universes), but the parameters do not need to be types. If no signature is provided, then Lean will attempt to infer a universe that's just big enough to contain the resulting type. In some situations, this process may fail to find a minimal universe or fail to find one at all, necessitating an annotation.

The constructor specifications follow `where`. Constructors are not mandatory, as constructorless inductive types such as `False` and `Empty` are perfectly sensible. Each constructor specification begins with a vertical bar (`'|'`, Unicode `'VERTICAL BAR' (U+007c)`), declaration modifiers, and a name. The name is a [raw identifier](../../Source-Files-and-Modules/index.md#--tech-term-raw-identifier). A declaration signature follows the name. The signature may specify any parameters, modulo the well-formedness requirements for inductive type declarations, but the return type in the signature must be a saturated application of the type constructor of the inductive type being specified. If no signature is provided, then the constructor's type is inferred by inserting sufficient implicit parameters to construct a well-formed return type.

The new inductive type's name is defined in the [current namespace](../../Namespaces-and-Sections/index.md#--tech-term-current-namespace). Each constructor's name is in the inductive type's namespace.
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

<a id="inductive-datatypes-parameters-and-indices"></a>
#### 4.4.1.1. Parameters and Indices

Type constructors may take two kinds of arguments: 
<a id="--tech-term-parameters"></a>
*parameters* 
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
 and 
<a id="--tech-term-indices"></a>
*indices*.
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
 Parameters must be used consistently in the entire definition; all occurrences of the type constructor in each constructor in the declaration must take precisely the same argument. Indices may vary among the occurrences of the type constructor. All parameters must precede all indices in the type constructor's signature.

Parameters that occur prior to the colon (`':'`) in the type constructor's signature are considered parameters to the entire inductive type declaration. They are always parameters that must be uniform throughout the type's definition. Generally speaking, parameters that occur after the colon are indices that may vary throughout the definition of the type. However, if the option `inductive.autoPromoteIndices` is `true`, then syntactic indices that could have been parameters are made into parameters. An index could have been a parameter if all of its type dependencies are themselves parameters and it is used uniformly as an uninstantiated variable in all occurrences of the inductive type's type constructor in all constructors.

<a id="inductive___autoPromoteIndices"></a>

**option**

```text
inductive.autoPromoteIndices
```

Default value: `true`

Promote indices to parameters in inductive types whenever possible.

Indices can be seen as defining a *family* of types. Each choice of indices selects a type from the family, which has its own set of available constructors. Type constructors with indices are said to specify 
<a id="--tech-term-indexed-families"></a>
*indexed families* 
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
 of types.

<a id="example-inductive-types"></a>
#### 4.4.1.2. Example Inductive Types

<a id="A-constructorless-type"></a>
A constructorless type 

`Vacant` is an empty inductive type, equivalent to Lean's `Empty` type:
<a id="Vacant-_LPAR_in-A-constructorless-type_RPAR_"></a>


```proofscript
inductive Vacant : Type where
```

Empty inductive types are not useless; they can be used to indicate unreachable code.

<a id="A-constructorless-proposition"></a>
A constructorless proposition 

`No` is a false [proposition](../Propositions/index.md#--tech-term-Propositions), equivalent to Lean's `False`:
<a id="No-_LPAR_in-A-constructorless-proposition_RPAR_"></a>


```proofscript
inductive No : Prop where
```

<a id="A-unit-type"></a>
A unit type 

`Solo` is equivalent to Lean's `Unit` type:
<a id="Solo-_LPAR_in-A-unit-type_RPAR_"></a>
<a id="Solo___solo-_LPAR_in-A-unit-type_RPAR_"></a>


```proofscript
inductive Solo where
  | solo
```

It is an example of an inductive type in which the signatures have been omitted for both the type constructor and the constructor. Lean assigns `Solo` to `Type`:

```proofscript
#check Solo
```

```lean
Solo : Type
```

The constructor is named `Solo.solo`, because constructor names are in the type constructor's namespace. Because `Solo` expects no arguments, the signature inferred for `Solo.solo` is:

```proofscript
#check Solo.solo
```

```lean
Solo.solo : Solo
```

<a id="A-true-proposition"></a>
A true proposition 

`Yes` is equivalent to Lean's `True` proposition:
<a id="Yes-_LPAR_in-A-true-proposition_RPAR_"></a>
<a id="Yes___intro-_LPAR_in-A-true-proposition_RPAR_"></a>


```proofscript
inductive Yes : Prop where
  | intro
```

Unlike `One`, the new inductive type `Yes` is specified to be in the `Prop` universe.

```proofscript
#check Yes
```

```lean
Yes : Prop
```

The signature inferred for `Yes.intro` is:

```proofscript
#check Yes.intro
```

```lean
Yes.intro : Yes
```

<a id="A-type-with-parameter-and-index"></a>
A type with parameter and index 

An `EvenOddList α b` is a list where `α` is the type of the data stored in the list and `b` is `true` when there are an even number of entries:
<a id="EvenOddList-_LPAR_in-A-type-with-parameter-and-index_RPAR_"></a>
<a id="EvenOddList___nil-_LPAR_in-A-type-with-parameter-and-index_RPAR_"></a>
<a id="EvenOddList___cons-_LPAR_in-A-type-with-parameter-and-index_RPAR_"></a>

<a id="EvenOddList-_LPAR_in-Recursor-with-parameters-and-indices_RPAR_"></a>
<a id="EvenOddList___nil-_LPAR_in-Recursor-with-parameters-and-indices_RPAR_"></a>
<a id="EvenOddList___cons-_LPAR_in-Recursor-with-parameters-and-indices_RPAR_"></a>


```proofscript
inductive EvenOddList (α : Type u) : Bool → Type u where
  | nil : EvenOddList α true
  | cons : α → EvenOddList α isEven → EvenOddList α (not isEven)
```

This example is well typed because there are two entries in the list:

```proofscript
example : EvenOddList String true :=
  .cons "a" (.cons "b" .nil)
```

This example is not well typed because there are three entries in the list:

```proofscript
example : EvenOddList String true :=
  .cons "a" (.cons "b" (.cons "c" .nil))
```

```lean
Type mismatch
  EvenOddList.cons "a" (EvenOddList.cons "b" (EvenOddList.cons "c" EvenOddList.nil))
has type
  EvenOddList String !!!true
but is expected to have type
  EvenOddList String true
```

In this declaration, `α` is a [parameter](index.md#--tech-term-parameters), because it is used consistently in all occurrences of `EvenOddList`. `b` is an [index](index.md#--tech-term-indices), because different `Bool` values are used for it at different occurrences.

<a id="Parameters-before-and-after-the-colon"></a>
Parameters before and after the colon 

In this example, both parameters are specified before the colon in `Either`'s signature.
<a id="Either-_LPAR_in-Parameters-before-and-after-the-colon_RPAR_"></a>
<a id="Either___left-_LPAR_in-Parameters-before-and-after-the-colon_RPAR_"></a>
<a id="Either___right-_LPAR_in-Parameters-before-and-after-the-colon_RPAR_"></a>


```proofscript
inductive Either (α : Type u) (β : Type v) : Type (max u v) where
  | left : α → Either α β
  | right : β → Either α β
```

In this version, there are two types named `α` that might not be identical:
<a id="Either___-_LPAR_in-Parameters-before-and-after-the-colon_RPAR_"></a>


```proofscript
inductive Either' (α : Type u) (β : Type v) : Type (max u v) where
  | left : {α : Type u} → {β : Type v} → α → Either' α β
  | right : β → Either' α β
```

```lean
Mismatched inductive type parameter in
  Either' α β
The provided argument
  α
is not definitionally equal to the expected parameter
  α✝

Note: The value of parameter `α✝` must be fixed throughout the inductive declaration. Consider making this parameter an index if it must vary.
```

Placing the parameters after the colon results in parameters that can be instantiated by the constructors:
<a id="Either______-_LPAR_in-Parameters-before-and-after-the-colon_RPAR_"></a>
<a id="Either_________left-_LPAR_in-Parameters-before-and-after-the-colon_RPAR_"></a>
<a id="Either_________right-_LPAR_in-Parameters-before-and-after-the-colon_RPAR_"></a>


```proofscript
inductive Either'' : Type u → Type v → Type (max u v + 1) where
  | left : {α : Type u} → {β : Type v} → α → Either'' α β
  | right : β → Either'' α β
```

A larger universe is required for this type because [constructor parameters must be in universes that are smaller than the inductive type's universe](index.md#inductive-type-universe-levels). `Either''.right`'s type parameter is discovered via Lean's ordinary rules for [automatic implicit parameters](../../Definitions/Headers-and-Signatures/index.md#--tech-term-automatic-implicit-parameters).

<a id="anonymous-constructor-syntax"></a>
#### 4.4.1.3. Anonymous Constructor Syntax

If an inductive type has just one constructor, then this constructor is eligible for 
<a id="--tech-term-anonymous-constructor-syntax"></a>
*anonymous constructor syntax*. Instead of writing the constructor's name applied to its arguments, the explicit arguments can be enclosed in angle brackets (`'⟨'` and `'⟩'`, Unicode `MATHEMATICAL LEFT ANGLE BRACKET	(U+0x27e8)` and `MATHEMATICAL RIGHT ANGLE BRACKET	(U+0x27e9)`) and separated with commas. This works in both pattern and expression contexts. Providing arguments by name or converting all implicit parameters to explicit parameters with `@` requires using the ordinary constructor syntax.

<a id="term"></a>

**syntax**

**Anonymous Constructors**

Constructors can be invoked anonymously by enclosing their explicit arguments in angle brackets, separated by commas.

<a id="Lean___Parser___Term___anonymousCtor"></a>

```ebnf
term ::= ...
    | ⟨ term,* ⟩
```

<a id="Anonymous-constructors"></a>
Anonymous constructors 

The type `AtLeastOne α` is similar to `List α`, except there's always at least one element present:
<a id="AtLeastOne-_LPAR_in-Anonymous-constructors_RPAR_"></a>
<a id="AtLeastOne___mk-_LPAR_in-Anonymous-constructors_RPAR_"></a>


```proofscript
inductive AtLeastOne (α : Type u) : Type u where
  | mk : α → Option (AtLeastOne α) → AtLeastOne α
```

Anonymous constructor syntax can be used to construct them:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="oneTwoThree-_LPAR_in-Anonymous-constructors_RPAR_"></a>


```proofscript
const oneTwoThree : AtLeastOne Nat :=
  ⟨1, some ⟨2, some ⟨3, none⟩⟩⟩
```

and to match against them:
<a id="AtLeastOne___head-_LPAR_in-Anonymous-constructors_RPAR_"></a>


```proofscript
def AtLeastOne.head : AtLeastOne α → α
  | ⟨x, _⟩ => x
```

Equivalently, traditional constructor syntax could have been used:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="oneTwoThree___-_LPAR_in-Anonymous-constructors_RPAR_"></a>
<a id="AtLeastOne___head___-_LPAR_in-Anonymous-constructors_RPAR_"></a>


```proofscript
const oneTwoThree' : AtLeastOne Nat :=
  .mk 1 (some (.mk 2 (some (.mk 3 none))))

def AtLeastOne.head' : AtLeastOne α → α
  | .mk x _ => x
```

<a id="inductive-declarations-deriving-instances"></a>
#### 4.4.1.4. Deriving Instances

The optional `deriving` clause of an inductive type declaration can be used to derive instances of type classes. Please refer to [the section on instance deriving](../../Type-Classes/Deriving-Instances/index.md#deriving-instances) for more information.

<a id="structures"></a>
### 4.4.2. Structure Declarations

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Structure Declarations**

<a id="Lean___Parser___Command___declaration-next"></a>

```ebnf
command ::= ...
    | declModifiers
      structure declId bracketedBinder* (: term)?
        (extends (ident : )?term,*)?
        where
        (declModifiers ident ::)?
        structFields
      (deriving derivingClass,*)?
```

Declares a new structure type.

<a id="--tech-term-Structures"></a>
Structures are inductive types that have only a single constructor and no indices. In exchange for these restrictions, Lean generates code for structures that offers a number of conveniences: projection functions are generated for each field, an additional constructor syntax based on field names rather than positional arguments is available, a similar syntax may be used to replace the values of certain named fields, and structures may extend other structures. Just like other inductive types, structures may be recursive; they are subject to the same restrictions regarding strict positivity. Structures do not add any expressive power to Lean; all of their features are implemented in terms of code generation.

<a id="structure-params"></a>
#### 4.4.2.1. Structure Parameters

Just like ordinary inductive type declarations, the header of the structure declaration contains a signature that may specify both parameters and a resulting universe. Structures may not define [indexed families](index.md#--tech-term-indexed-families).

<a id="structure-fields"></a>
#### 4.4.2.2. Fields

Each field of a structure declaration corresponds to a parameter of the constructor.

<a id="Inferring-Universes"></a>
Inferring Universes 

The structure `MyProd` is the same as `Prod`.
<a id="MyProd-_LPAR_in-Inferring-Universes_RPAR_"></a>
<a id="MyProd___fst-_LPAR_in-Inferring-Universes_RPAR_"></a>
<a id="MyProd___snd-_LPAR_in-Inferring-Universes_RPAR_"></a>


```proofscript
structure MyProd (α β : Type _) where
  fst : α
  snd : β
```

The two parameters and the two fields are constructor parameters:

```proofscript
MyProd.mk.{u, v}
  {α : Type u}
  {β : Type v}
  (fst : α)
  (snd : β)
  : MyProd.{u, v} α β
```

Additionally, the constructor is [universe polymorphic](../Universes/index.md#--tech-term-universe-polymorphism); the type constructor `MyProd` takes two universe parameters:

```proofscript
MyProd.{u, v} (α : Type u) (β : Type v) : Type (max u v)
```

The universe level of each type of each field must be less than or equal to the universe level of the structure. Lean infers that `Type (max u v)` is the least universe that can accommodate both `Type u` and `Type v`.

Auto-implicit arguments are inserted in each field separately, even if their names coincide, and the fields become constructor parameters that quantify over types.

<a id="Auto-Implicit-Parameters-in-Structure-Fields"></a>
Auto-Implicit Parameters in Structure Fields 

The structure `MyStructure` contains fields whose types have auto-implicit parameters:
<a id="MyStructure-_LPAR_in-Auto-Implicit-Parameters-in-Structure-Fields_RPAR_"></a>
<a id="MyStructure___field1-_LPAR_in-Auto-Implicit-Parameters-in-Structure-Fields_RPAR_"></a>
<a id="MyStructure___field2-_LPAR_in-Auto-Implicit-Parameters-in-Structure-Fields_RPAR_"></a>


```proofscript
structure MyStructure where
  field1 : Fin n
  field2 : Fin n
```

Each fields in the constructor `MyStructure.mk` takes its own implicit parameter `n` of type `Nat`:

```proofscript
MyStructure.mk
  (field1 : {n : Nat} → Fin n)
  (field2 : {n : Nat} → Fin n)
  : MyStructure
```

The type constructor `MyStructure` takes no universe parameters, and the resulting type is in `Type`, which is the universe for `Nat` and `Fin n`:

```proofscript
MyStructure : Type
```

For each field, a 
<a id="--tech-term-projection-function"></a>
projection function is generated that extracts the field's value from the underlying type's constructor. This function is in the structure's name's namespace. Structure field projections are handled specially by the elaborator (as described in the [section on structure inheritance](index.md#structure-inheritance)), which performs extra steps beyond looking up a namespace. When field types depend on prior fields, the types of the dependent projection functions are written in terms of earlier projections, rather than explicit pattern matching.

<a id="Dependent-projection-types"></a>
Dependent projection types 

The structure `ArraySized` contains a field whose type depends on both a structure parameter and an earlier field:
<a id="ArraySized-_LPAR_in-Dependent-projection-types_RPAR_"></a>
<a id="ArraySized___array-_LPAR_in-Dependent-projection-types_RPAR_"></a>
<a id="ArraySized___size_eq_length-_LPAR_in-Dependent-projection-types_RPAR_"></a>


```proofscript
structure ArraySized (α : Type u) (length : Nat)  where
  array : Array α
  size_eq_length : array.size = length
```

The signature of the projection function `size_eq_length` takes the structure type's parameter as an implicit parameter and refers to the earlier field using the corresponding projection:

```proofscript
ArraySized.size_eq_length.{u}
  {α : Type u} {length : Nat}
  (self : ArraySized α length)
  : self.array.size = length
```

Structure fields may have default values, specified with `:=`. These values are used if no explicit value is provided.

<a id="Default-values"></a>
Default values 

An adjacency list representation of a graph can be represented as an array of lists of `Nat`. The size of the array indicates the number of vertices, and the outgoing edges from each vertex are stored in the array at the vertex's index. Because the default value `#[]` is provided for the field `adjacency`, the empty graph `Graph.empty` can be constructed without providing any field values.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Graph-_LPAR_in-Default-values_RPAR_"></a>
<a id="Graph___adjacency-_LPAR_in-Default-values_RPAR_"></a>
<a id="Graph___empty-_LPAR_in-Default-values_RPAR_"></a>


```proofscript
structure Graph where
  adjacency : Array (List Nat) := #[]

const Graph.empty : Graph := {}
```

Structure fields may additionally be accessed via their index, using dot notation. Fields are numbered beginning with `1`.

<a id="structure-constructors"></a>
#### 4.4.2.3. Structure Constructors

Structure constructors may be explicitly named by providing the constructor name and `::` prior to the fields. If no name is explicitly provided, then the constructor is named `mk` in the structure type's namespace. [Declaration modifiers](../../Definitions/Modifiers/index.md#declaration-modifiers) may additionally be provided along with an explicit constructor name.

<a id="Non-default-constructor-name"></a>
Non-default constructor name 

The structure `Palindrome` contains a string and a proof that the string is the same when reversed:
<a id="Palindrome-_LPAR_in-Non-default-constructor-name_RPAR_"></a>
<a id="Palindrome___ofString-_LPAR_in-Non-default-constructor-name_RPAR_"></a>
<a id="Palindrome___text-_LPAR_in-Non-default-constructor-name_RPAR_"></a>
<a id="Palindrome___is_palindrome-_LPAR_in-Non-default-constructor-name_RPAR_"></a>


```proofscript
structure Palindrome where
  ofString ::
  text : String
  is_palindrome : text.data.reverse = text.data
```

Its constructor is named `Palindrome.ofString`, rather than `Palindrome.mk`.

<a id="Modifiers-on-structure-constructor"></a>
Modifiers on structure constructor 

The structure `NatStringBimap` maintains a finite bijection between natural numbers and strings. It consists of a pair of maps, such that the keys each occur as values exactly once in the other map. Because the constructor is private, code outside the defining module can't construct new instances and must use the provided API, which maintains the invariants of the type. Additionally, providing the default constructor name explicitly is an opportunity to attach a [documentation comment](../../Definitions/Modifiers/index.md#--tech-term-Documentation-comments) to the constructor.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="NatStringBimap-_LPAR_in-Modifiers-on-structure-constructor_RPAR_"></a>
<a id="_private___Manual___Language___InductiveTypes___Structures___0___NatStringBimap___mk-_LPAR_in-Modifiers-on-structure-constructor_RPAR_"></a>
<a id="NatStringBimap___natToString-_LPAR_in-Modifiers-on-structure-constructor_RPAR_"></a>
<a id="NatStringBimap___stringToNat-_LPAR_in-Modifiers-on-structure-constructor_RPAR_"></a>
<a id="NatStringBimap___empty-_LPAR_in-Modifiers-on-structure-constructor_RPAR_"></a>
<a id="NatStringBimap___insert-_LPAR_in-Modifiers-on-structure-constructor_RPAR_"></a>


```proofscript
structure NatStringBimap where
  /--
  Build a finite bijection between some
  natural numbers and strings
  -/
  private mk ::
  natToString : Std.HashMap Nat String
  stringToNat : Std.HashMap String Nat

const NatStringBimap.empty : NatStringBimap := ⟨{}, {}⟩

function NatStringBimap.insert
    (nat : Nat) (string : String)
    (map : NatStringBimap) :
    Option NatStringBimap :=
  if map.natToString.contains nat ||
      map.stringToNat.contains string then
    none
  else
    some <|
      NatStringBimap.mk
        (map.natToString.insert nat string)
        (map.stringToNat.insert string nat)
```

Because structures are represented by single-constructor inductive types, their constructors can be invoked or matched against using [anonymous constructor syntax](index.md#--tech-term-anonymous-constructor-syntax). Additionally, structures may be constructed or matched against using 
<a id="--tech-term-structure-instance"></a>
*structure instance* notation, which includes the names of the fields together with values for them.

<a id="term-next"></a>

**syntax**

**Structure Instances**

<a id="Lean___Parser___Term___structInst"></a>

```ebnf
term ::= ...
    | { structInstField,*
        (: term)? }
```

Constructs a value of a constructor type given values for named fields. Field specifiers may take two forms:

<a id="Lean___Parser___Term___structInstField"></a>

```ebnf
structInstField ::= ...
    | structInstLVal := private? term
```

<a id="Lean___Parser___Term___structInstField-next"></a>

```ebnf
structInstField ::= ...
    | ident
```

A 

```ebnf
structInstLVal
```

 is a field name (an identifier), a field index (a natural number), or a term in square brackets, followed by a sequence of zero or more subfields. Subfields are either a field name or index preceded by a dot, or a term in square brackets.

This syntax is elaborated to applications of structure constructors. The values provided for fields are by name, and they may be provided in any order. The values provided for subfields are used to initialize fields of constructors of structures that are themselves found in fields. Terms in square brackets are not allowed when constructing a structure; they are used in structure updates.

Field specifiers that do not contain `:=` are field abbreviations. In this context, the identifier `f` is an abbreviation for `f := f`; that is, the value of `f` in the current scope is used to initialize the field `f`.

Every field that does not have a default value must be provided. If a tactic is specified as the default argument, then it is run at elaboration time to construct the argument's value.

In a pattern context, field names are mapped to patterns that match the corresponding projection, and field abbreviations bind a pattern variable that is the field's name. Default arguments are still present in patterns; if a pattern does not specify a value for a field with a default value, then the pattern only matches the default.

When a field definition contains the `private` modifier, the value is placed in the current module's [private scope](../../Source-Files-and-Modules/index.md#--tech-term-private-scope), even if the structure value is itself in the public scope. The value is wrapped in a public but non-exposed helper definition. This is particularly useful with instances of type classes, because the implementation of [methods](../../Type-Classes/index.md#--tech-term-methods) in public [instances](../../Type-Classes/index.md#--tech-term-instances) of type classes are [exposed](../../Source-Files-and-Modules/index.md#--tech-term-exposed) by default. This modifier allows them to be made private.

The optional type annotation allows the structure type to be specified in contexts where it is not otherwise determined.

<a id="Patterns-and-default-values"></a>
Patterns and default values 

The structure `AugmentedIntList` contains a list together with some extra information, which is empty if omitted:
<a id="AugmentedIntList-_LPAR_in-Patterns-and-default-values_RPAR_"></a>
<a id="AugmentedIntList___list-_LPAR_in-Patterns-and-default-values_RPAR_"></a>
<a id="AugmentedIntList___augmentation-_LPAR_in-Patterns-and-default-values_RPAR_"></a>


```proofscript
structure AugmentedIntList where
  list : List Int
  augmentation : String := ""
```

When testing whether the list is empty, the function `isEmpty` must explicitly match the `augmentation` field, even though it has a default value:
<a id="AugmentedIntList___isEmpty-_LPAR_in-Patterns-and-default-values_RPAR_"></a>


```proofscript
def AugmentedIntList.isEmpty : AugmentedIntList → Bool
  | {list := [], augmentation := ""} => true
  | _ => false

#eval {list := [], augmentation := "extra" : AugmentedIntList}.isEmpty
```

```lean
false
```

<a id="Private-Field-Values"></a>
Private Field Values 

Even when a definition of a structure is [exposed](../../Source-Files-and-Modules/index.md#--tech-term-exposed), individual fields may be hidden using the field-level `private` modifier. In this module, the exposed public definition of `x` may use the private definition `secret` because the `imaginary` field's value is not exposed:

  `Main.lean`
<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Complex-_LPAR_in-Private-Field-Values_RPAR_"></a>
<a id="Complex___real-_LPAR_in-Private-Field-Values_RPAR_"></a>
<a id="Complex___imaginary-_LPAR_in-Private-Field-Values_RPAR_"></a>
<a id="_private___0___secret-_LPAR_in-Private-Field-Values_RPAR_"></a>
<a id="x-_LPAR_in-Private-Field-Values_RPAR_"></a>


```proofscript
module

public structure Complex where
  real : Float
  imaginary : Float

private const secret := 2.3

@[expose]
public const x : Complex := {
  real := 5.0
  imaginary := private 2 * secret
}
```

<a id="Private-Methods"></a>
Private Methods 

In this module, the existence of the `State` structure is public, but its constructor and field are private. The function `State.toString` is also private, and is intended to be accessed via the `ToString` instance. However, because the implementations of [methods](../../Type-Classes/index.md#--tech-term-methods) are exposed for public instances, this is not allowed:

  `Main.lean`
<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
module

public structure State where
  private mk ::
  private count : Nat

private function State.toString (s : State) : String :=
  s!"⟨{s.count}⟩"

public instance : ToString State where
  toString s := s.toString
```

```lean
Invalid field `toString`: The environment does not contain `State.toString`, so it is not possible to project the field `toString` from an expression
  s
of type `State`

Note: A private declaration `State.toString` (from the current module) exists but would need to be public to access here.
```

Marking the implementation of `toString` as `private` removes it from the module's [public scope](../../Source-Files-and-Modules/index.md#--tech-term-public-scope), giving it access to private functions:

  `Main.lean`
<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
module

public structure State where
  private mk ::
  private count : Nat

private function State.toString (s : State) : String :=
  s!"⟨{s.count}⟩"

public instance : ToString State where
  toString s := private s.toString
```

<a id="term-next-next"></a>

**syntax**

**Structure Updates**

<a id="Lean___Parser___Term___structInst-next"></a>

```ebnf
term ::= ...
    | {term with
        structInstField,*
        (: term)?}
```

Updates a value of a constructor type. The term that precedes the `with` clause is expected to have a structure type; it is the value that is being updated. A new instance of the structure is created in which every field not specified is copied from the value that is being updated, and the specified fields are replaced with their new values. When updating a structure, array values may also be replaced by including the index to be updated in square brackets. This updating does not require that the index expression be in bounds for the array, and out-of-bounds updates are discarded.

<a id="Updating-arrays"></a>
Updating arrays 

Updating structures may use array indices as well as projection names. Updates at indices that are out of bounds are ignored:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="AugmentedIntArray-_LPAR_in-Updating-arrays_RPAR_"></a>
<a id="AugmentedIntArray___array-_LPAR_in-Updating-arrays_RPAR_"></a>
<a id="AugmentedIntArray___augmentation-_LPAR_in-Updating-arrays_RPAR_"></a>
<a id="one-_LPAR_in-Updating-arrays_RPAR_"></a>
<a id="two-_LPAR_in-Updating-arrays_RPAR_"></a>
<a id="two___-_LPAR_in-Updating-arrays_RPAR_"></a>
<a id="two______-_LPAR_in-Updating-arrays_RPAR_"></a>


```proofscript
structure AugmentedIntArray where
  array : Array Int
  augmentation : String := ""
deriving Repr

const one : AugmentedIntArray := {array := #[1]}
const two : AugmentedIntArray := {one with array := #[1, 2]}
const two' : AugmentedIntArray := {two with array[0] := 2}
const two'' : AugmentedIntArray := {two with array[99] := 3}
#eval (one, two, two', two'')
```

```lean
({ array := #[1], augmentation := "" },
 { array := #[1, 2], augmentation := "" },
 { array := #[2, 2], augmentation := "" },
 { array := #[1, 2], augmentation := "" })
```

Values of structure types may also be declared using `where`, followed by definitions for each field. This may only be used as part of a definition, not in an expression context.

<a id="where--for-structures"></a>
`where` for structures 

The product type in Lean is a structure named `Prod`. Products can be defined using their projections:
<a id="location-_LPAR_in-where--for-structures_RPAR_"></a>


```proofscript
def location : Float × Float where
  fst := 22.807
  snd := -13.923
```

<a id="structure-inheritance"></a>
#### 4.4.2.4. Structure Inheritance

Structures may be declared as extending other structures using the optional `extends` clause. The resulting structure type has all of the fields of all of the parent structure types. If the parent structure types have overlapping field names, then all overlapping field names must have the same type.

The resulting structure has a 
<a id="--tech-term-field-resolution-order"></a>
*field resolution order* that affects the values of fields. When possible, this resolution order is the [C3 linearization](https://en.wikipedia.org/wiki/C3_linearization) of the structure's parents. Essentially, the field resolution order should be a total ordering of the entire set of parents such that every `extends` list is in order. When there is no C3 linearization, a heuristic is used to find an order nonetheless. Every structure type is first in its own field resolution order.

The field resolution order is used to compute the default values of optional fields. When the value of a field is not specified, the first default value defined in the resolution order is used. References to fields in the default value use the field resolution order as well; this means that child structures that override default fields of parent constructors may also change the computed default values of parent fields. Because the child structure is the first element of its own resolution order, default values in the child structure take precedence over default values from the parent structures.

When the new structure extends existing structures, the new structure's constructor takes the existing structure's information as additional arguments. Typically, this is in the form of a constructor parameter for each parent structure type. This parent value contains all of the parent's fields. If the parents' fields overlap, however, then the subset of non-overlapping fields from one or more of the parents is included instead of an entire value of the parent structure to prevent duplicating field information.

There is no subtyping relation between a parent structure type and its children. Even if structure `B` extends structure `A`, a function expecting an `A` will not accept a `B`. However, conversion functions are generated that convert a structure into each of its parents. These conversion functions are called 
<a id="--tech-term-parent-projections"></a>
*parent projections*. Parent projections are in the child structure's namespace, and their name is the parent structure's name preceded by `to`.

<a id="Structure-type-inheritance-with-overlapping-fields"></a>
Structure type inheritance with overlapping fields 

In this example, a `Textbook` is a `Book` that is also an `AcademicWork`:
<a id="Book-_LPAR_in-Structure-type-inheritance-with-overlapping-fields_RPAR_"></a>
<a id="Book___title-_LPAR_in-Structure-type-inheritance-with-overlapping-fields_RPAR_"></a>
<a id="Book___author-_LPAR_in-Structure-type-inheritance-with-overlapping-fields_RPAR_"></a>
<a id="AcademicWork-_LPAR_in-Structure-type-inheritance-with-overlapping-fields_RPAR_"></a>
<a id="AcademicWork___author-_LPAR_in-Structure-type-inheritance-with-overlapping-fields_RPAR_"></a>
<a id="AcademicWork___discipline-_LPAR_in-Structure-type-inheritance-with-overlapping-fields_RPAR_"></a>
<a id="Textbook-_LPAR_in-Structure-type-inheritance-with-overlapping-fields_RPAR_"></a>


```proofscript
structure Book where
  title : String
  author : String

structure AcademicWork where
  author : String
  discipline : String

structure Textbook extends Book, AcademicWork

#check Textbook.toBook
```

Because the field `author` occurs in both `Book` and `AcademicWork`, the constructor `Textbook.mk` does not take both parents as arguments. Its signature is:

```proofscript
Textbook.mk (toBook : Book) (discipline : String) : Textbook
```

The conversion functions are:

```proofscript
Textbook.toBook (self : Textbook) : Book
```

```proofscript
Textbook.toAcademicWork (self : Textbook) : AcademicWork
```

The latter combines the `author` field of the included `Book` with the unbundled `Discipline` field, and is equivalent to:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="toAcademicWork-_LPAR_in-Structure-type-inheritance-with-overlapping-fields_RPAR_"></a>


```proofscript
function toAcademicWork (self : Textbook) : AcademicWork :=
  let .mk book discipline := self
  let .mk _title author := book
  .mk author discipline
```

The resulting structure's projections can be used as if its fields are simply the union of the parents' fields. The Lean elaborator automatically generates an appropriate projection when fields are used. Likewise, the field-based initialization and structure update notations hide the details of the encoding of inheritance. The encoding is, however, visible when using the constructor's name, when using [anonymous constructor syntax](index.md#--tech-term-anonymous-constructor-syntax), or when referring to fields by their index rather than their name.

<a id="Field-Indices-and-Structure-Inheritance"></a>
Field Indices and Structure Inheritance 
<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Pair-_LPAR_in-Field-Indices-and-Structure-Inheritance_RPAR_"></a>
<a id="Pair___fst-_LPAR_in-Field-Indices-and-Structure-Inheritance_RPAR_"></a>
<a id="Pair___snd-_LPAR_in-Field-Indices-and-Structure-Inheritance_RPAR_"></a>
<a id="Triple-_LPAR_in-Field-Indices-and-Structure-Inheritance_RPAR_"></a>
<a id="Triple___thd-_LPAR_in-Field-Indices-and-Structure-Inheritance_RPAR_"></a>
<a id="coords-_LPAR_in-Field-Indices-and-Structure-Inheritance_RPAR_"></a>


```proofscript
structure Pair (α : Type u) where
  fst : α
  snd : α
deriving Repr

structure Triple (α : Type u) extends Pair α where
  thd : α
deriving Repr

const coords : Triple Nat := {fst := 17, snd := 2, thd := 95}
```

Evaluating the first field index of `coords` yields the underlying `Pair`, rather than the contents of the field `fst`:

```proofscript
#eval coords.1
```

```lean
{ fst := 17, snd := 2 }
```

The elaborator translates `coords.fst` into `coords.toPair.fst`.

<a id="No-structure-subtyping"></a>
No structure subtyping 

Given these definitions of even numbers, even prime numbers, and a concrete even prime:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="EvenNumber-_LPAR_in-No-structure-subtyping_RPAR_"></a>
<a id="EvenNumber___val-_LPAR_in-No-structure-subtyping_RPAR_"></a>
<a id="EvenNumber___isEven-_LPAR_in-No-structure-subtyping_RPAR_"></a>
<a id="EvenPrime-_LPAR_in-No-structure-subtyping_RPAR_"></a>
<a id="EvenPrime___notOne-_LPAR_in-No-structure-subtyping_RPAR_"></a>
<a id="EvenPrime___isPrime-_LPAR_in-No-structure-subtyping_RPAR_"></a>
<a id="two-_LPAR_in-No-structure-subtyping_RPAR_"></a>
<a id="printEven-_LPAR_in-No-structure-subtyping_RPAR_"></a>


```proofscript
structure EvenNumber where
  val : Nat
  isEven : 2 ∣ val := by decide

structure EvenPrime extends EvenNumber where
  notOne : val ≠ 1 := by decide
  isPrime : ∀ n, n ≤ val → n ∣ val  → n = 1 ∨ n = val

def two : EvenPrime where
  val := 2
  isPrime := by
    intros
    repeat' (cases ‹Nat.le _ _›)
    all_goals omega

function printEven (num : EvenNumber) : IO Unit :=
  IO.print num.val
```

it is a type error to apply `printEven` directly to `two`:

```proofscript
#check printEven two
```

```lean
Application type mismatch: The argument
  two
has type
  EvenPrime
but is expected to have type
  EvenNumber
in the application
  printEven two
```

because values of type `EvenPrime` are not also values of type `EvenNumber`.

The `#print` command displays the most important information about structure types, including the [parent projections](index.md#--tech-term-parent-projections), all the fields with their default values, the constructor, and the [field resolution order](index.md#--tech-term-field-resolution-order). When working with deep hierarchies that contain inheritance diamonds, this information can be very useful.

<a id="___print--and-Structure-Types"></a>
`#print` and Structure Types 

This collection of structure types models a variety of bicycles, both electric and non-electric and both ordinary-sized and large family bicycles. The final structure type, `ElectricFamilyBike`, contains a diamond in its inheritance graph, because both `FamilyBike` and `ElectricBike` extend `Bicycle`.
<a id="Vehicle-_LPAR_in-___print--and-Structure-Types_RPAR_"></a>
<a id="Vehicle___wheels-_LPAR_in-___print--and-Structure-Types_RPAR_"></a>
<a id="Bicycle-_LPAR_in-___print--and-Structure-Types_RPAR_"></a>
<a id="ElectricVehicle-_LPAR_in-___print--and-Structure-Types_RPAR_"></a>
<a id="ElectricVehicle___batteries-_LPAR_in-___print--and-Structure-Types_RPAR_"></a>
<a id="FamilyBike-_LPAR_in-___print--and-Structure-Types_RPAR_"></a>
<a id="ElectricBike-_LPAR_in-___print--and-Structure-Types_RPAR_"></a>
<a id="ElectricFamilyBike-_LPAR_in-___print--and-Structure-Types_RPAR_"></a>


```proofscript
structure Vehicle where
  wheels : Nat

structure Bicycle extends Vehicle where
  wheels := 2

structure ElectricVehicle extends Vehicle where
  batteries : Nat := 1

structure FamilyBike extends Bicycle where
  wheels := 3

structure ElectricBike extends Bicycle, ElectricVehicle

structure ElectricFamilyBike
    extends FamilyBike, ElectricBike where
  batteries := 2
```

The `#print` command displays the important information about each structure type:

```proofscript
#print ElectricBike
```

```lean
structure ElectricBike : Type
number of parameters: 0
parents:
  ElectricBike.toBicycle : Bicycle
  ElectricBike.toElectricVehicle : ElectricVehicle
fields:
  Vehicle.wheels : Nat :=
    2
  ElectricVehicle.batteries : Nat :=
    1
constructor:
  ElectricBike.mk (toBicycle : Bicycle) (batteries : Nat) : ElectricBike
field notation resolution order:
  ElectricBike, Bicycle, ElectricVehicle, Vehicle
```

An `ElectricFamilyBike` has three wheels by default because `FamilyBike` precedes `Bicycle` in its resolution order:

```proofscript
#print ElectricFamilyBike
```

```lean
structure ElectricFamilyBike : Type
number of parameters: 0
parents:
  ElectricFamilyBike.toFamilyBike : FamilyBike
  ElectricFamilyBike.toElectricBike : ElectricBike
fields:
  Vehicle.wheels : Nat :=
    3
  ElectricVehicle.batteries : Nat :=
    2
constructor:
  ElectricFamilyBike.mk (toFamilyBike : FamilyBike) (batteries : Nat) : ElectricFamilyBike
field notation resolution order:
  ElectricFamilyBike, FamilyBike, ElectricBike, Bicycle, ElectricVehicle, Vehicle
```

<a id="inductive-types-logical-model"></a>
### 4.4.3. Logical Model

<a id="recursors"></a>
#### 4.4.3.1. Recursors

Every inductive type is equipped with a [recursor](index.md#--tech-term-recursor). The recursor is completely determined by the signatures of the type constructor and the constructors. Recursors have function types, but they are primitive and are not definable using `fun`.

<a id="recursor-types"></a>
##### 4.4.3.1.1. Recursor Types

The recursor takes the following parameters:

  The inductive type's [parameters](index.md#--tech-term-parameters)

Because parameters are consistent, they can be abstracted over the entire recursor.

  The 
<a id="--tech-term-motive"></a>
*motive*

The motive determines the type of an application of the recursor. The motive is a function whose arguments are the type's indices and an instance of the type with these indices instantiated. The specific universe for the type that the motive determines depends on the inductive type's universe and the specific constructors—see the section on [[subsingleton](index.md#--tech-term-subsingleton) elimination](index.md#subsingleton-elimination) for details.

  A 
<a id="--tech-term-minor-premise"></a>
*minor premise* for each constructor

For each constructor, the recursor expects a function that satisfies the motive for an arbitrary application of the constructor. Each minor premise abstracts over all of the constructor's parameters. If the constructor's parameter's type is the inductive type itself, then the minor premise additionally takes a parameter whose type is the motive applied to that parameter's value—this will receive the result of recursively processing the recursive parameter.

  The 
<a id="--tech-term-major-premise"></a>
*major premise*, or target

Finally, the recursor takes an instance of the type as an argument, along with any index values.

The result type of the recursor is the motive applied to these indices and the major premise.

<a id="The-recursor-for--Bool"></a>
The recursor for `Bool` 

`Bool`'s recursor `Bool.rec` has the following parameters:

- The motive computes a type in any universe, given a `Bool`.
- There are minor premises for both constructors, in which the motive is satisfied for both `false` and `true`.
- The major premise is some `Bool`.

The return type is the motive applied to the major premise.

```proofscript
Bool.rec.{u} {motive : Bool → Sort u}
  (false : motive false)
  (true : motive true)
  (t : Bool) : motive t
```

<a id="The-recursor-for--List"></a>
The recursor for `List` 

`List`'s recursor `List.rec` has the following parameters:

- The parameter `α` comes first, because the motive, minor premises, and major premise need to refer to it.
- The motive computes a type in any universe, given a `List α`. There is no connection between the universe levels `u` and `v`.
- There are minor premises for both constructors:

   

  - The motive is satisfied for `List.nil`
  - The motive should be satisfiable for any application of `List.cons`, given that it is satisfiable for the tail. The extra parameter `motive tail` is because `tail`'s type is a recursive occurrence of `List`.
- The major premise is some `List α`.

Once again, the return type is the motive applied to the major premise.

```proofscript
List.rec.{u, v} {α : Type v} {motive : List α → Sort u}
  (nil : motive [])
  (cons : (head : α) → (tail : List α) → motive tail →
    motive (head :: tail))
  (t : List α) : motive t
```

<a id="Recursor-with-parameters-and-indices"></a>
Recursor with parameters and indices 

Given the definition of `EvenOddList`:

```proofscript
inductive EvenOddList (α : Type u) : Bool → Type u where
  | nil : EvenOddList α true
  | cons : α → EvenOddList α isEven → EvenOddList α (not isEven)
```

The recursor `EvenOddList.rec` is very similar to that for `List`. The difference comes from the presence of the index:

- The motive now abstracts over any arbitrary choice of index.
- The minor premise for `nil` applies the motive to `nil`'s index value `true`.
- The minor premise `cons` abstracts over the index value used in its recursive occurrence, and instantiates the motive with its negation.
- The major premise additionally abstracts over an arbitrary choice of index.

```proofscript
EvenOddList.rec.{u, v} {α : Type v}
  {motive : (isEven : Bool) → EvenOddList α isEven → Sort u}
  (nil : motive true EvenOddList.nil)
  (cons : {isEven : Bool} →
    (head : α) →
    (tail : EvenOddList α isEven) → motive isEven tail →
    motive (!isEven) (EvenOddList.cons head tail)) :
  {isEven : Bool} → (t : EvenOddList α isEven) → motive isEven t
```

When using a predicate (that is, a function that returns a `Prop`) for the motive, recursors express induction. The minor premises for non-recursive constructors are the base cases, and the additional arguments supplied to minor premises for constructors with recursive arguments are the induction hypotheses.

<a id="subsingleton-elimination"></a>
###### 4.4.3.1.1.1. Subsingleton Elimination

Proofs in Lean are computationally irrelevant. In other words, having been provided with **some** proof of a proposition, it should be impossible for a program to check **which** proof it has received. This is reflected in the types of recursors for inductively defined propositions or predicates. For these types, if there's more than one potential proof of the theorem then the motive may only return another `Prop`. If the type is structured such that there's only at most one proof anyway, then the motive may return a type in any universe. A proposition that has at most one inhabitant is called a 
<a id="--tech-term-subsingleton"></a>
*subsingleton*. Rather than obligating users to *prove* that there's only one possible proof, a conservative syntactic approximation is used to check whether a proposition is a subsingleton. Propositions that fulfill both of the following requirements are considered to be subsingletons:

- There is at most one constructor.
- Each of the constructor's parameter types is either a `Prop`, a parameter, or an index.

<a id="True--is-a-subsingleton"></a>
`True` is a subsingleton 

`True` is a subsingleton because it has one constructor, and this constructor has no parameters. Its recursor has the following signature:

```proofscript
True.rec.{u} {motive : True → Sort u}
  (intro : motive True.intro)
  (t : True) : motive t
```

<a id="False--is-a-subsingleton"></a>
`False` is a subsingleton 

`False` is a subsingleton because it has no constructors. Its recursor has the following signature:

```proofscript
False.rec.{u} (motive : False → Sort u) (t : False) : motive t
```

Note that the motive is an explicit parameter. This is because it is not mentioned in any further parameters' types, so it could not be solved by unification.

<a id="And--is-a-subsingleton"></a>
`And` is a subsingleton 

`And` is a subsingleton because it has one constructor, and both of the constructor's parameters' types are propositions. Its recursor has the following signature:

```proofscript
And.rec.{u} {a b : Prop} {motive : a ∧ b → Sort u}
  (intro : (left : a) → (right : b) → motive (And.intro left right))
  (t : a ∧ b) : motive t
```

<a id="Or--is-not-a-subsingleton"></a>
`Or` is not a subsingleton 

`Or` is not a subsingleton because it has more than one constructor. Its recursor has the following signature:

```proofscript
Or.rec {a b : Prop} {motive : a ∨ b → Prop}
  (inl : ∀ (h : a), motive (.inl h))
  (inr : ∀ (h : b), motive (.inr h))
  (t : a ∨ b) : motive t
```

The motive's type indicates that `Or.rec` can only be used to produce proofs. A proof of a disjunction can be used to prove something else, but there's no way for a program to inspect *which* of the two disjuncts was true and used for the proof.

<a id="Eq--is-a-subsingleton"></a>
`Eq` is a subsingleton 

`Eq` is a subsingleton because it has just one constructor, `Eq.refl`. This constructor instantiates `Eq`'s index with a parameter value, so all arguments are parameters:

```proofscript
Eq.refl.{u} {α : Sort u} (x : α) : Eq x x
```

Its recursor has the following signature:

```proofscript
Eq.rec.{u, v} {α : Sort v} {x : α}
  {motive : (y : α) → x = y → Sort u}
  (refl : motive x (.refl x))
  {y : α} (t : x = y) : motive y t
```

This means that proofs of equality can be used to rewrite the types of non-propositions.

<a id="iota-reduction"></a>
##### 4.4.3.1.2. Reduction

In addition to adding new constants to the logic, inductive type declarations also add new reduction rules. These rules govern the interaction between recursors and constructors; specifically recursors that have constructors as their major premise. This form of reduction is called 
<a id="--tech-term-___-reduction"></a>
*ι-reduction* (iota reduction)
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
.

When the recursor's major premise is a constructor with no recursive parameters, the recursor application reduces to an application of the constructor's minor premise to the constructor's arguments. If there are recursive parameters, then these arguments to the minor premise are found by applying the recursor to the recursive occurrence.

<a id="well-formed-inductives"></a>
#### 4.4.3.2. Well-Formedness Requirements

Inductive type declarations are subject to a number of well-formedness requirements. These requirements ensure that Lean remains consistent as a logic when it is extended with the inductive type's new rules. They are conservative: there exist potential inductive types that do not undermine consistency, but that these requirements nonetheless reject.

<a id="inductive-type-universe-levels"></a>
##### 4.4.3.2.1. Universe Levels

Type constructors of inductive types must either inhabit a [universe](../Universes/index.md#--tech-term-universes) or a function type whose return type is a universe. Each constructor must inhabit a function type that returns a saturated application of the inductive type. If the inductive type's universe is `Prop`, then there are no further restrictions on universes, because `Prop` is [impredicative](../Universes/index.md#--tech-term-impredicative). If the universe is not `Prop`, then the following must hold for each parameter to the constructor:

- If the constructor's parameter is a parameter (in the sense of parameters vs indices) of the inductive type, then this parameter's type may be no larger than the type constructor's universe.
- All other constructor parameters must be smaller than the type constructor's universe.

<a id="Universes___-constructors___-and-parameters"></a>
Universes, constructors, and parameters 

`Either` is in the greater of its arguments' universes, because both are parameters to the inductive type:
<a id="Either-_LPAR_in-Universes___-constructors___-and-parameters_RPAR_"></a>
<a id="Either___inl-_LPAR_in-Universes___-constructors___-and-parameters_RPAR_"></a>
<a id="Either___inr-_LPAR_in-Universes___-constructors___-and-parameters_RPAR_"></a>


```proofscript
inductive Either (α : Type u) (β : Type v) : Type (max u v) where
  | inl : α → Either α β
  | inr : β → Either α β
```

`CanRepr` is in a larger universe than the constructor parameter `α`, because `α` is not one of the inductive type's parameters:
<a id="CanRepr-_LPAR_in-Universes___-constructors___-and-parameters_RPAR_"></a>
<a id="CanRepr___mk-_LPAR_in-Universes___-constructors___-and-parameters_RPAR_"></a>


```proofscript
inductive CanRepr : Type (u + 1) where
  | mk : (α : Type u) → [Repr α] → CanRepr
```

Constructorless inductive types may be in universes smaller than their parameters:
<a id="Spurious-_LPAR_in-Universes___-constructors___-and-parameters_RPAR_"></a>


```proofscript
inductive Spurious (α : Type 5) : Type 0 where
```

It would, however, be impossible to add a constructor to `Spurious` without changing its levels.

<a id="strict-positivity"></a>
##### 4.4.3.2.2. Strict Positivity

All occurrences of the type being defined in the types of the parameters of the constructors must be in 
<a id="--tech-term-strictly-positive"></a>
*strictly positive* positions. A position is strictly positive if it is not in a function's argument type (no matter how many function types are nested around it) and it is not an argument of any expression other than type constructors of inductive types. This restriction rules out unsound inductive type definitions, at the cost of also ruling out some unproblematic ones.

<a id="Non-strictly-positive-inductive-types"></a>
Non-strictly-positive inductive types 

The type `Bad` would make Lean inconsistent if it were not rejected:

```proofscript
inductive Bad where
  | bad : (Bad → Bad) → Bad
```

```lean
(kernel) arg #1 of 'Bad.bad' has a non positive occurrence of the datatypes being declared
```

This is because it would be possible to write a circular argument that proves `False` under the assumption `Bad`. `Bad.bad` is rejected because the constructor's parameter has type `Bad → Bad`, which is a function type in which `Bad` occurs as an argument type.

This declaration of a fixed point operator is rejected, because `Fix` occurs as an argument to `f`:
<a id="Fix-_LPAR_in-Non-strictly-positive-inductive-types_RPAR_"></a>


```proofscript
inductive Fix (f : Type u → Type u) where
  | fix : f (Fix f) → Fix f
```

```lean
(kernel) arg #2 of 'Fix.fix' contains a non valid occurrence of the datatypes being declared
```

`Fix.fix` is rejected because `f` is not a type constructor of an inductive type, but `Fix` itself occurs as an argument to it. In this case, `Fix` is also sufficient to construct a type equivalent to `Bad`:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
const Bad : Type := Fix fun t => t → t
```

<a id="prop-vs-type"></a>
##### 4.4.3.2.3. Prop vs Type

Lean rejects universe-polymorphic types that could not, in practice, be used polymorphically. This could arise if certain instantiations of the universe parameters would cause the type itself to be a `Prop`. If this type is not a [subsingleton](index.md#--tech-term-subsingleton), then its recursor can only target propositions (that is, the [motive](index.md#--tech-term-motive) must return a `Prop`). These types only really make sense as `Prop`s themselves, so the universe polymorphism is probably a mistake. Because they are largely useless, Lean's inductive type elaborator has not been designed to support these types.

When such universe-polymorphic inductive types are indeed subsingletons, it can make sense to define them. Lean's standard library defines `PUnit` and `PEmpty`. To define a subsingleton that can inhabit `Prop` or a `Type`, set the option `bootstrap.inductiveCheckResultingUniverse` to `false`.

<a id="bootstrap___inductiveCheckResultingUniverse"></a>

**option**

```text
bootstrap.inductiveCheckResultingUniverse
```

Default value: `true`

by default the `inductive`/`structure` commands report an error if the resulting universe is not zero, but may be zero for some universe parameters. Reason: unless this type is a subsingleton, it is hardly what the user wants since it can only eliminate into `Prop`. In the `Init` package, we define subsingletons, and we use this option to disable the check. This option may be deleted in the future after we improve the validator

<a id="Overly-universe-polymorphic--Bool"></a>
Overly-universe-polymorphic `Bool` 

Defining a version of `Bool` that can be in any universe is not allowed:
<a id="PBool-_LPAR_in-Overly-universe-polymorphic--Bool_RPAR_"></a>


```proofscript
inductive PBool : Sort u where
  | true
  | false
```

```lean
Invalid universe polymorphic resulting type: The resulting universe is not `Prop`, but it may be `Prop` for some parameter values:
  Sort u

Hint: A possible solution is to use levels of the form `max 1 _` or `_ + 1` to ensure the universe is of the form `Type _`
```

<a id="recursor-elaboration-helpers"></a>
#### 4.4.3.3. Constructions for Termination Checking

In addition to the type constructor, constructors, and recursors that Lean's core type theory prescribes for inductive types, Lean constructs a number of useful helpers. First, the equation compiler (which translates recursive functions with pattern matching in to applications of recursors) makes use of these additional constructs:

- `recOn` is a version of the recursor in which the major premise is prior to the minor premise for each constructor.
- `casesOn` is a version of the recursor in which the major premise is prior to the minor premise for each constructor, and recursive arguments do not yield induction hypotheses. It expresses case analysis rather than primitive recursion.
- `below` computes a type that, for some motive, expresses that *all* inhabitants of the inductive type that are subtrees of the major premise satisfy the motive. It transforms a motive for induction or primitive recursion into a motive for strong recursion or strong induction.
- `brecOn` is a version of the recursor in which `below` is used to provide access to all subtrees, rather than just immediate recursive parameters. It represents strong induction.
- `noConfusion` is a general statement from which injectivity and disjointness of constructors can be derived.
- `noConfusionType` is the motive used for `noConfusion` that determines what the consequences of two constructors being equal would be. For separate constructors, this is `False`; if both constructors are the same, then the consequence is the equality of their respective parameters.

These constructions follow the description in McBride, Goguen, and McKinna (2004)Conor McBride, Healfdene Goguen, and James McKinna, 2004. [“A Few Constructions on Constructors”](https://doi.org/10.1007/11617990_12). In *Types for Proofs and Programs, International Workshop, TYPES 2004.* (LNCS 3839).

For [well-founded recursion](../../Definitions/Recursive-Definitions/index.md#--tech-term-well-founded-recursion), it is frequently useful to have a generic notion of size available. This is captured in the `SizeOf` class.

<a id="SizeOf___mk"></a>

**type class**

```text
SizeOf.{u} (α : Sort u) : Sort (max 1 u)
```

`SizeOf` is a typeclass automatically derived for every inductive type, which equips the type with a "size" function to `Nat`. The default instance defines each constructor to be `1` plus the sum of the sizes of all the constructor fields.

This is used for proofs by well-founded induction, since every field of the constructor has a smaller size than the constructor itself, and in many cases this will suffice to do the proof that a recursive function is only called on smaller values. If the default proof strategy fails, it is recommended to supply a custom size measure using the `termination_by` argument on the function definition.

**Instance Constructor**

```text
SizeOf.mk.{u}
```

**Methods**

```text
sizeOf : α → Nat
```

The "size" of an element, a natural number which decreases on fields of each inductive type.

<a id="run-time-inductives"></a>
### 4.4.4. Run-Time Representation

An inductive type's run-time representation depends both on how many constructors it has, how many arguments each constructor takes, and whether these arguments are [relevant](index.md#--tech-term-relevant).

<a id="inductive-types-runtime-special-support"></a>
#### 4.4.4.1. Exceptions

Not every inductive type is represented as indicated here—some inductive types have special support from the Lean compiler:

- The representation of the fixed-width integer types `UInt8`, …, `UInt64`, `Int8`, …, `Int64`, and `USize` depends on whether the code is compiled for a 32- or 64-bit architecture. Their representation is described [in a dedicated section](../../Basic-Types/Fixed-Precision-Integers/index.md#fixed-int-runtime).
- `Char` is represented by `uint32_t`. Because `Char` values never require more than 21 bits, they are always unboxed.
- `Float` is represented by a pointer to a Lean object that contains a “double”.
- An 
  <a id="--tech-term-enum-inductive"></a>
  *enum inductive* type of at least 2 and at most 2^{32} constructors, each of which has no parameters, is represented by the first type of `uint8_t`, `uint16_t`, `uint32_t` that is sufficient to assign a unique value to each constructor. For example, the type `Bool` is represented by `uint8_t`, with values `0` for `false` and `1` for `true`.
- `Decidable α` is represented the same way as `Bool`
- `Nat` and `Int` are represented by `lean_object *`. Their representations are described in more detail in [the section on natural numbers](../../Basic-Types/Natural-Numbers/index.md#nat-runtime) and [the section on integers](../../Basic-Types/Integers/index.md#int-runtime).

<a id="inductive-types-runtime-relevance"></a>
#### 4.4.4.2. Relevance

Types and proofs have no run-time representation. That is, if an inductive type is a `Prop`, then its values are erased prior to compilation. Similarly, all theorem statements and types are erased. Types with run-time representations are called 
<a id="--tech-term-relevant"></a>
*relevant*, while types without run-time representations are called 
<a id="--tech-term-irrelevant"></a>
*irrelevant*.

<a id="Types-are-irrelevant"></a>
Types are irrelevant 

Even though `List.cons` has the following signature, which indicates three parameters:

```proofscript
List.cons.{u} {α : Type u} : α → List α → List α
```

its run-time representation has only two, because the type argument is run-time irrelevant.

<a id="Proofs-are-irrelevant"></a>
Proofs are irrelevant 

Even though `Fin.mk` has the following signature, which indicates three parameters:

```proofscript
Fin.mk {n : Nat} (val : Nat) : val < n → Fin n
```

its run-time representation has only two, because the proof is erased.

In most cases, irrelevant values simply disappear from compiled code. However, in cases where some representation is required (such as when they are arguments to polymorphic constructors), they are represented by a trivial value.

<a id="inductive-types-trivial-wrappers"></a>
#### 4.4.4.3. Trivial Wrappers

An inductive type is a 
<a id="--tech-term-trivial-wrapper"></a>
trivial wrapper if it has has exactly one constructor and that constructor has exactly one run-time relevant parameter. Trivial wrappers are represented identically to their constructor's parameter in the following circumstances:

- The inductive type is private.
- The type is public, and the [public scope](../../Source-Files-and-Modules/index.md#--tech-term-public-scope) of the module in which it is defined contains enough information to determine that it is a trivial wrapper.
- The type is defined in a source file that is not a [module](../../Source-Files-and-Modules/index.md#--tech-term-module).

<a id="Zero-Overhead-Subtypes"></a>
Zero-Overhead Subtypes 

The structure `Subtype` bundles an element of some type with a proof that it satisfies a predicate. Its constructor takes four arguments, but three of them are irrelevant:

```proofscript
Subtype.mk.{u} {α : Sort u} {p : α → Prop}
  (val : α) (property : p val) : Subtype p
```

Thus, subtypes impose no runtime overhead in compiled code, and are represented identically to the type of the `val` field.

<a id="Signed-Integers"></a>
Signed Integers 

The signed integer types `Int8`, ..., `Int64`, `ISize` are structures with a single field that wraps the corresponding unsigned integer type. They are represented by the unsigned C types `uint8_t`, ..., `uint64_t`, `size_t`, respectively, because they have a trivial structure.

<a id="inductive-types-standard-representation"></a>
#### 4.4.4.4. Other Inductive Types

If an inductive type doesn't fall into one of the categories above, then its representation is determined by its constructors. Constructors without relevant parameters are represented by their index into the list of constructors, as unboxed unsigned machine integers (scalars). Constructors with relevant parameters are represented as an object with a header, the constructor's index, an array of pointers to other objects, and then arrays of scalar fields sorted by their types. The header tracks the object's reference count and other necessary bookkeeping.

Recursive functions are compiled as they are in most programming languages, rather than by using the inductive type's recursor. Elaborating recursive functions to recursors serves to provide reliable termination evidence, not executable code.

<a id="inductive-types-ffi"></a>
##### 4.4.4.4.1. FFI

From the perspective of C, these other inductive types are represented by `lean_object *`. Each constructor is stored as a `lean_ctor_object`, and `lean_is_ctor` will return true.

There are no guarantees about the exact layout of fields in a constructor object; the compiler is free to select any layout. Thus, constructor objects should only be created or unpacked by functions defined in Lean code. These functions can be made available to C via the [`export`](../../Run-Time-Code/Foreign-Function-Interface/index.md#Lean___Parser___Attr___export) attribute. Because the resulting C and Lean code call symbols defined in each other, they should be linked together. Each C should be compiled to an object file using a custom target in Lake and added to the Lean library configuration's `moreLinkObjs` field.

<a id="mutual-inductive-types"></a>
### 4.4.5. Mutual Inductive Types

Inductive types may be mutually recursive. Mutually recursive definitions of inductive types are specified by defining the types in a `mutual ... end` block.

<a id="Mutually-Defined-Inductive-Types"></a>
Mutually Defined Inductive Types 

The type `EvenOddList` in a prior example used a Boolean index to select whether the list in question should have an even or odd number of elements. This distinction can also be expressed by the choice of one of two mutually inductive types `EvenList` and `OddList`:
<a id="EvenList-_LPAR_in-Mutually-Defined-Inductive-Types_RPAR_"></a>
<a id="EvenList___nil-_LPAR_in-Mutually-Defined-Inductive-Types_RPAR_"></a>
<a id="EvenList___cons-_LPAR_in-Mutually-Defined-Inductive-Types_RPAR_"></a>
<a id="OddList-_LPAR_in-Mutually-Defined-Inductive-Types_RPAR_"></a>
<a id="OddList___cons-_LPAR_in-Mutually-Defined-Inductive-Types_RPAR_"></a>


```proofscript
mutual
  inductive EvenList (α : Type u) : Type u where
    | nil : EvenList α
    | cons : α → OddList α → EvenList α
  inductive OddList (α : Type u) : Type u where
    | cons : α → EvenList α → OddList α
end

example : EvenList String := .cons "x" (.cons "y" .nil)
example : OddList String := .cons "x" (.cons "y" (.cons "z" .nil))
```

```proofscript
example : OddList String := .cons "x" (.cons "y" .nil)
```

```lean
Unknown constant `OddList.nil`

Note: Inferred this name from the expected resulting type of `.nil`:
  OddList String
```

<a id="mutual-inductive-types-requirements"></a>
#### 4.4.5.1. Requirements

The inductive types declared in a `mutual` block are considered as a group; they must collectively satisfy generalized versions of the well-formedness criteria for non-mutually-recursive inductive types. This is true even if they could be defined without the `mutual` block, because they are not in fact mutually recursive.

<a id="mutual-inductive-types-dependencies"></a>
##### 4.4.5.1.1. Mutual Dependencies

Each type constructor's signature must be able to be elaborated without reference to the other inductive types in the `mutual` group. In other words, the inductive types in the `mutual` group may not take each other as arguments. The constructors of each inductive type may mention the other type constructors in the group in their parameter types, with restrictions that are a generalization of those for recursive occurrences in non-mutual inductive types.

<a id="Mutual-inductive-type-constructors-may-not-mention-each-other"></a>
Mutual inductive type constructors may not mention each other 

These inductive types are not accepted by Lean:

```proofscript
mutual
  inductive FreshList (α : Type) (r : α → α → Prop) : Type where
    | nil : FreshList α r
    | cons (x : α) (xs : FreshList α r) (fresh : Fresh r x xs)
  inductive Fresh
      (r : α → FreshList α → Prop) :
      α → FreshList α r → Prop where
    | nil : Fresh r x .nil
    | cons : r x y → (f : Fresh r x ys) → Fresh r x (.cons y ys f)
end
```

The type constructors may not refer to the other type constructors in the `mutual` group, so `FreshList` is not in scope in the type constructor of `Fresh`:

```lean
Unknown identifier `FreshList`
```

<a id="mutual-inductive-types-same-parameters"></a>
##### 4.4.5.1.2. Parameters Must Match

All inductive types in the `mutual` group must have the same [parameters](index.md#--tech-term-parameters). Their indices may differ.

<a id="Differing-numbers-of-parameters"></a>
Differing numbers of parameters 

Even though `Both` and `Optional` are not mutually recursive, they are declared in the same `mutual` block and must therefore have identical parameters:

```proofscript
mutual
  inductive Both (α : Type u) (β : Type v) where
    | mk : α → β → Both α β
  inductive Optional (α : Type u) where
    | none
    | some : α → Optional α
end
```

```lean
Invalid mutually inductive types: `Optional` has 1 parameter(s), but the preceding type `Both` has 2

Note: All inductive types declared in the same `mutual` block must have the same parameters
```

<a id="Differing-parameter-types"></a>
Differing parameter types 

Even though `Many` and `Optional` are not mutually recursive, they are declared in the same `mutual` block and must therefore have identical parameters. They both have exactly one parameter, but `Many`'s parameter is not necessarily in the same universe as `Optional`'s:

```proofscript
mutual
  inductive Many (α : Type) : Type u where
    | nil : Many α
    | cons : α → Many α → Many α
  inductive Optional (α : Type u) where
    | none
    | some : α → Optional α
end
```

```lean
Invalid mutually inductive types: Parameter `α` has type
  Type u
of sort `Type (u + 1)` but is expected to have type
  Type
of sort `Type 1`
```

<a id="mutual-inductive-types-same-universe"></a>
##### 4.4.5.1.3. Universe Levels

The universe levels of each inductive type in a mutual group must obey the same requirements as non-mutually-recursive inductive types. Additionally, all the inductive types in a mutual group must be in the same universe, which implies that their constructors are similarly limited with respect to their parameters' universes.

<a id="Universe-mismatch"></a>
Universe mismatch 

These mutually-inductive types are a somewhat complicated way to represent run-length encoding of a list:
<a id="RLE___nil-_LPAR_in-Universe-mismatch_RPAR_"></a>
<a id="RLE___run-_LPAR_in-Universe-mismatch_RPAR_"></a>
<a id="PrefixRunOf-_LPAR_in-Universe-mismatch_RPAR_"></a>
<a id="PrefixRunOf___zero-_LPAR_in-Universe-mismatch_RPAR_"></a>
<a id="PrefixRunOf___succ-_LPAR_in-Universe-mismatch_RPAR_"></a>


```proofscript
mutual
  inductive RLE : List α → Type where
  | nil : RLE []
  | run (x : α) (n : Nat) :
    n ≠ 0 → PrefixRunOf n x xs ys → RLE ys → RLE xs

  inductive PrefixRunOf : Nat → α → List α → List α → Type where
  | zero
    (noMore : ¬∃zs, xs = x :: zs := by simp) :
    PrefixRunOf 0 x xs xs
  | succ :
    PrefixRunOf n x xs ys →
    PrefixRunOf (n + 1) x (x :: xs) ys
end

example : RLE [1, 1, 2, 2, 3, 1, 1, 1] :=
  .run 1 2 (by decide) (.succ (.succ .zero)) <|
  .run 2 2 (by decide) (.succ (.succ .zero)) <|
  .run 3 1 (by decide) (.succ .zero) <|
  .run 1 3 (by decide) (.succ (.succ (.succ (.zero)))) <|
  .nil
```

Specifying `PrefixRunOf` as a `Prop` would be sensible, but it cannot be done because the types would be in different universes:

```proofscript
mutual
  inductive RLE : List α → Type where
  | nil : RLE []
  | run
    (x : α) (n : Nat) :
    n ≠ 0 → PrefixRunOf n x xs ys → RLE ys →
    RLE xs

  inductive PrefixRunOf : Nat → α → List α → List α → Prop where
  | zero
    (noMore : ¬∃zs, xs = x :: zs := by simp) :
    PrefixRunOf 0 x xs xs
  | succ :
    PrefixRunOf n x xs ys →
    PrefixRunOf (n + 1) x (x :: xs) ys
end
```

```lean
Invalid mutually inductive types: The resulting type of this declaration
  Prop
differs from a preceding one
  Type

Note: All inductive types declared in the same `mutual` block must belong to the same type universe
```

This particular property can be expressed by separately defining the well-formedness condition and using a subtype:
<a id="RunLengths-_LPAR_in-Universe-mismatch_RPAR_"></a>
<a id="NoRepeats-_LPAR_in-Universe-mismatch_RPAR_"></a>
<a id="RunsMatch-_LPAR_in-Universe-mismatch_RPAR_"></a>
<a id="NonZero-_LPAR_in-Universe-mismatch_RPAR_"></a>
<a id="RLE___rle-_LPAR_in-Universe-mismatch_RPAR_"></a>
<a id="RLE___noRepeats-_LPAR_in-Universe-mismatch_RPAR_"></a>
<a id="RLE___runsMatch-_LPAR_in-Universe-mismatch_RPAR_"></a>
<a id="RLE___nonZero-_LPAR_in-Universe-mismatch_RPAR_"></a>


```proofscript
def RunLengths α := List (α × Nat)
def NoRepeats : RunLengths α → Prop
  | [] => True
  | [_] => True
  | (x, _) :: ((y, n) :: xs) =>
    x ≠ y ∧ NoRepeats ((y, n) :: xs)
def RunsMatch : RunLengths α → List α → Prop
  | [], [] => True
  | (x, n) :: xs, ys =>
    ys.take n = List.replicate n x ∧
    RunsMatch xs (ys.drop n)
  | _, _ => False
def NonZero : RunLengths α → Prop
  | [] => True
  | (_, n) :: xs => n ≠ 0 ∧ NonZero xs
structure RLE (xs : List α) where
  rle : RunLengths α
  noRepeats : NoRepeats rle
  runsMatch : RunsMatch rle xs
  nonZero : NonZero rle

example : RLE [1, 1, 2, 2, 3, 1, 1, 1] where
  rle := [(1, 2), (2, 2), (3, 1), (1, 3)]
  noRepeats := by simp [NoRepeats]
  runsMatch := by simp [RunsMatch]
  nonZero := by simp [NonZero]
```

<a id="mutual-inductive-types-positivity"></a>
##### 4.4.5.1.4. Positivity

Each inductive type that is defined in the `mutual` group may occur only strictly positively in the types of the parameters of the constructors of all the types in the group. In other words, in the type of each parameter to each constructor in all the types of the group, none of the type constructors in the group occur to the left of any arrows, and none of them occur in argument positions unless they are an argument to an inductive type's type constructor.

<a id="Mutual-strict-positivity"></a>
Mutual strict positivity 

In the following mutual group, `Tm` occurs in a negative position in the argument to `Binding.scope`:
<a id="Tm-_LPAR_in-Mutual-strict-positivity_RPAR_"></a>
<a id="Binding-_LPAR_in-Mutual-strict-positivity_RPAR_"></a>


```proofscript
mutual
  inductive Tm where
    | app : Tm → Tm → Tm
    | lam : Binding → Tm
  inductive Binding where
    | scope : (Tm → Tm) → Binding
end
```

Because `Tm` is part of the same mutual group, it must occur only strictly positively in the arguments to the constructors of `Binding`. It occurs, however, negatively:

```lean
(kernel) arg #1 of 'Binding.scope' has a non positive occurrence of the datatypes being declared
```

<a id="Nested-positions"></a>
Nested positions 

The definitions of `LocatedStx` and `Stx` satisfy the positivity condition because the recursive occurrences are not to the left of any arrows and, when they are arguments, they are arguments to inductive type constructors.
<a id="LocatedStx-_LPAR_in-Nested-positions_RPAR_"></a>
<a id="LocatedStx___mk-_LPAR_in-Nested-positions_RPAR_"></a>
<a id="Stx-_LPAR_in-Nested-positions_RPAR_"></a>
<a id="Stx___atom-_LPAR_in-Nested-positions_RPAR_"></a>
<a id="Stx___node-_LPAR_in-Nested-positions_RPAR_"></a>


```proofscript
mutual
  inductive LocatedStx where
    | mk (line col : Nat) (val : Stx)
  inductive Stx where
    | atom (str : String)
    | node (kind : String) (args : List LocatedStx)
end
```

<a id="mutual-inductive-types-recursors"></a>
#### 4.4.5.2. Recursors

Mutual inductive types are provided with primitive recursors, just like non-mutually-defined inductive types. These recursors take into account that they must process the other types in the group, and thus will have a motive for each inductive type. Because all inductive types in the `mutual` group are required to have identical parameters, the recursors still take the parameters first, abstracting them over the motives and the rest of the recursor. Additionally, because the recursor must process the group's other types, it will require cases for each constructor of each of the types in the group. The actual dependency structure between the types is not taken into account; even if an additional motive or constructor case is not really required due to there being fewer mutual dependencies than there could be, the generated recursor still requires them.

<a id="Even-and-odd"></a>
Even and odd 
<a id="Even-_LPAR_in-Even-and-odd_RPAR_"></a>
<a id="Even___zero-_LPAR_in-Even-and-odd_RPAR_"></a>
<a id="Even___succ-_LPAR_in-Even-and-odd_RPAR_"></a>
<a id="Odd-_LPAR_in-Even-and-odd_RPAR_"></a>
<a id="Odd___succ-_LPAR_in-Even-and-odd_RPAR_"></a>


```proofscript
mutual
  inductive Even : Nat → Prop where
    | zero : Even 0
    | succ : Odd n → Even (n + 1)
  inductive Odd : Nat → Prop where
    | succ : Even n → Odd (n + 1)
end
```

```proofscript
Even.rec
  {motive_1 : (a : Nat) → Even a → Prop}
  {motive_2 : (a : Nat) → Odd a → Prop}
  (zero : motive_1 0 Even.zero)
  (succ : {n : Nat} → (a : Odd n) → motive_2 n a → motive_1 (n + 1) (Even.succ a)) :
  (∀ {n : Nat} (a : Even n), motive_1 n a → motive_2 (n + 1) (Odd.succ a)) →
  ∀ {a : Nat} (t : Even a), motive_1 a t
```

```proofscript
Odd.rec
  {motive_1 : (a : Nat) → Even a → Prop}
  {motive_2 : (a : Nat) → Odd a → Prop}
  (zero : motive_1 0 Even.zero)
  (succ : ∀ {n : Nat} (a : Odd n), motive_2 n a → motive_1 (n + 1) (Even.succ a)) :
  (∀ {n : Nat} (a : Even n), motive_1 n a → motive_2 (n + 1) (Odd.succ a)) → ∀ {a : Nat} (t : Odd a), motive_2 a t
```

<a id="Spuriously-mutual-types"></a>
Spuriously mutual types 

The types `Two` and `Three` are defined in a mutual block, even though they do not refer to each other:
<a id="Two-_LPAR_in-Spuriously-mutual-types_RPAR_"></a>
<a id="Two___mk-_LPAR_in-Spuriously-mutual-types_RPAR_"></a>
<a id="Three-_LPAR_in-Spuriously-mutual-types_RPAR_"></a>
<a id="Three___mk-_LPAR_in-Spuriously-mutual-types_RPAR_"></a>


```proofscript
mutual
  inductive Two (α : Type) where
    | mk : α → α → Two α
  inductive Three (α : Type) where
    | mk : α → α → α → Three α
end
```

`Two`'s recursor, `Two.rec`, nonetheless requires a motive and a case for `Three`:

```proofscript
Two.rec.{u} {α : Type}
  {motive_1 : Two α → Sort u}
  {motive_2 : Three α → Sort u}
  (mk : (a a_1 : α) → motive_1 (Two.mk a a_1)) :
  ((a a_1 a_2 : α) → motive_2 (Three.mk a a_1 a_2)) → (t : Two α) → motive_1 t
```

<a id="mutual-inductive-types-run-time"></a>
#### 4.4.5.3. Run-Time Representation

Mutual inductive types are represented identically to [non-mutual inductive types](index.md#run-time-inductives) in compiled code and in the runtime. The restrictions on mutual inductive types exist to ensure Lean's consistency as a logic, and do not impact compiled code.

<a id="nested-inductive-types"></a>
#### 4.4.5.4. Nested Inductive Types

<a id="--tech-term-Nested-inductive-types"></a>
*Nested inductive types* are inductive types in which recursive occurrences of the type being defined are parameters to other inductive type constructors. These recursive occurrences are “nested” underneath the other type constructors. Nested inductive types that satisfy certain requirements can be translated into mutual inductive types; this translation demonstrates that they are sound. Internally, the [kernel](../../Elaboration-and-Compilation/index.md#--tech-term-kernel) performs this translation; if it succeeds, then the *original* nested inductive type is accepted. This avoids performance and usability issues that would arise from details of the translation surfacing.

Nested recursive occurrences must satisfy the following requirements:

- They must be nested *directly* under an inductive type's type constructor. Terms that reduce to such nested occurrences are not accepted.
- Local variables such as the constructor's parameters may not occur in the arguments to the nested occurrence.
- The nested occurrences must occur strictly positively. They must occur strictly positively in the position in which they are nested, and the type constructor in which they are nested must itself occur in a strictly positive position.
- Constructor parameters whose types include nested occurrences may not be used in ways that rely on the specific choice of outer type constructor. The translated version will not be usable in those contexts.
- Nested occurrences may not be used as parameters to the outer type constructor that occur in the types of the outer type's indices.

<a id="Nested-Inductive-Types"></a>
Nested Inductive Types 

Instead of using two constructors, the natural numbers can be defined using `Option`:
<a id="ONat-_LPAR_in-Nested-Inductive-Types_RPAR_"></a>
<a id="ONat___mk-_LPAR_in-Nested-Inductive-Types_RPAR_"></a>


```proofscript
inductive ONat : Type where
  | mk (pred : Option ONat)
```

Arbitrarily-branching trees, also known as *rose trees*, are nested inductive types:
<a id="RTree-_LPAR_in-Nested-Inductive-Types_RPAR_"></a>
<a id="RTree___empty-_LPAR_in-Nested-Inductive-Types_RPAR_"></a>
<a id="RTree___node-_LPAR_in-Nested-Inductive-Types_RPAR_"></a>


```proofscript
inductive RTree (α : Type u) : Type u where
  | empty
  | node (val : α) (children : List (RTree α))
```

<a id="Invalid-Nested-Inductive-Types"></a>
Invalid Nested Inductive Types 

This declaration of arbitrarily-branching rose trees declares an alias for `List`, rather than using `List` directly:
<a id="Children-_LPAR_in-Invalid-Nested-Inductive-Types_RPAR_"></a>
<a id="RTree-_LPAR_in-Invalid-Nested-Inductive-Types_RPAR_"></a>


```proofscript
abbrev Children := List

inductive RTree (α : Type u) : Type u where
  | empty
  | node (val : α) (children : Children (RTree α))
```

```lean
(kernel) arg #3 of 'RTree.node' contains a non valid occurrence of the datatypes being declared
```

This declaration of arbitrarily-branching rose trees tracks the depth of the tree using an index. The constructor `DRTree.node` has an [automatic implicit parameter](../../Definitions/Headers-and-Signatures/index.md#--tech-term-automatic-implicit-parameters) `n` that represents the depths of all sub-trees. However, local variables such as constructor parameters are not permitted as arguments to nested occurrences:
<a id="DRTree-_LPAR_in-Invalid-Nested-Inductive-Types_RPAR_"></a>


```proofscript
inductive DRTree (α : Type u) : Nat → Type u where
  | empty : DRTree α 0
  | node (val : α) (children : List (DRTree α n)) : DRTree α (n + 1)
```

This declaration includes a non-strictly-positive occurrence of the inductive type, nested under an `Option`:
<a id="WithCheck-_LPAR_in-Invalid-Nested-Inductive-Types_RPAR_"></a>


```proofscript
inductive WithCheck where
  | done
  | check (f : Option WithCheck → Bool)
```

```lean
(kernel) arg #1 of 'WithCheck.check' has a non positive occurrence of the datatypes being declared
```

This rose tree has a branching factor that's limited by its parameter:
<a id="BRTree-_LPAR_in-Invalid-Nested-Inductive-Types_RPAR_"></a>


```proofscript
inductive BRTree (branches : Nat) (α : Type u) : Type u where
  | mk :
    (children : List (BRTree branches α)) →
    children.length < branches →
    BRTree branches α
```

Only nested inductive types that can be translated to mutual inductive types are allowed. However, translating this type would require a translation of `List.length` to the translated types, but function definitions may not occur in mutual blocks with inductive types. The resulting error message shows that the function was not translated, but was applied to a term of the translated type:

```lean
(kernel) application type mismatch
  List.length children
argument has type
  @_nested.List_1 branches α
but function has type
  List (@BRTree branches α) → Nat
```

It is acceptable to use the parameter with the nested occurrence with fully polymorphic functions, such as `id`:
<a id="RTree______-_LPAR_in-Invalid-Nested-Inductive-Types_RPAR_"></a>


```proofscript
inductive RTree'' (α : Type u) : Type u where
  | mk :
    (children : List (BRTree branches α)) →
    id children = children →
    BRTree branches α
```

In this case, the function applies equally well to the translated version as it does to the original.

The translation from nested inductive types to mutual inductive types proceeds as follows:

  Nested occurrences become inductive types

Nested occurrences of the inductive type are translated into new inductive types in the same mutual group, which replace the original nested occurrences. These new inductive types have the same constructors as the outer inductive type, except the original parameters are instantiated by the translated version of the type. The original inductive type becomes an alias for the version in which the nested occurrences have been rewritten. This process is repeated if the resulting type is also a nested inductive type (e.g. a type nested under `Array` becomes a type nested under `List`, because `Array`'s constructor takes a `List`).

  Conversions to and from the nested types

Conversions between the outer inductive type applied to the new alias and the generated auxiliary types are generated. These conversions are then proved to be mutual inverses.

  Constructor reconstruction

Each constructor of the original type is defined as a function that returns the constructor of the translated type, after applying the appropriate conversions.

  Recursor reconstruction

The recursor for the nested inductive type is constructed from the recursor for the translated type. In the translation, the motives for the nested occurrences are composed with the conversion functions and the [minor premises](index.md#--tech-term-minor-premise) use them as needed. The proofs that the conversion functions are mutually inverse are needed because the encoded constructors convert in one direction, but end up applied to the result of the conversion in the other direction.

<a id="Translating-Nested-Inductive-Types"></a>
Translating Nested Inductive Types 

This nested inductive type represents the natural numbers:

```proofscript
inductive ONat where
  | mk (pred : Option ONat) : ONat

#check ONat.rec
```

The first step in the internal translation is to replace the nested occurrences with auxiliary inductive types that “inline” the resulting type. In this case, the nested occurrence is under `Option`; thus, the auxiliary type has the constructors of `Option`, with `ONat'` substituted for the type parameter:
<a id="ONat___-_LPAR_in-Translating-Nested-Inductive-Types_RPAR_"></a>
<a id="ONat______mk-_LPAR_in-Translating-Nested-Inductive-Types_RPAR_"></a>
<a id="OptONat-_LPAR_in-Translating-Nested-Inductive-Types_RPAR_"></a>
<a id="OptONat___none-_LPAR_in-Translating-Nested-Inductive-Types_RPAR_"></a>
<a id="OptONat___some-_LPAR_in-Translating-Nested-Inductive-Types_RPAR_"></a>


```proofscript
mutual
inductive ONat' where
  | mk (pred : OptONat) : ONat'

inductive OptONat where
  | none
  | some : ONat' → OptONat
end
```

`ONat'` is the encoding of `ONat`:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
const ONat := ONat'
```

The next step is to define conversion functions that translate the original nested type to and from the auxiliary type:
<a id="OptONat___ofOption-_LPAR_in-Translating-Nested-Inductive-Types_RPAR_"></a>
<a id="OptONat___toOption-_LPAR_in-Translating-Nested-Inductive-Types_RPAR_"></a>


```proofscript
def OptONat.ofOption : Option ONat → OptONat
  | Option.none => OptONat.none
  | Option.some o => OptONat.some o
def OptONat.toOption : OptONat → Option ONat
  | OptONat.none => Option.none
  | OptONat.some o => Option.some o
```

These conversion functions are mutually inverse:
<a id="OptONat___to_of_eq_id-_LPAR_in-Translating-Nested-Inductive-Types_RPAR_"></a>
<a id="OptONat___of_to_eq_id-_LPAR_in-Translating-Nested-Inductive-Types_RPAR_"></a>


```proofscript
def OptONat.to_of_eq_id o :
    OptONat.toOption (ofOption o) = o := by
  cases o <;> rfl
def OptONat.of_to_eq_id o :
    OptONat.ofOption (OptONat.toOption o) = o := by
  cases o <;> rfl
```

The original constructor is translated to an application of the translation's corresponding constructor, with the appropriate conversion applied for the nested occurrence:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function ONat.mk (pred : Option ONat) : ONat :=
  ONat'.mk (.ofOption pred)
```

Finally, the original type's recursor can be translated. The translated recursor uses the translated type's recursor. The original nested occurrences are translated using the conversions, and the proofs that the conversions are mutually inverse are used to rewrite types as needed.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="ONat___rec-_LPAR_in-Translating-Nested-Inductive-Types_RPAR_"></a>


```proofscript
noncomputable function ONat.rec
    {motive1 : ONat → Sort u}
    {motive2 : Option ONat → Sort u}
    (h1 :
      (pred : Option ONat) → motive2 pred →
      motive1 (ONat.mk pred))
    (h2 : motive2 none)
    (h3 : (o : ONat) → motive1 o → motive2 (some o)) :
    (t : ONat) → motive1 t :=
  @ONat'.rec motive1 (motive2 ∘ OptONat.toOption)
    (fun pred ih =>
      OptONat.of_to_eq_id pred ▸ h1 pred.toOption ih)
    h2
    h3
```

<a id="The-Lean-Language-Reference--The-Type-System--Inductive-Types--Mutual-Inductive-Types--Lattice-Theoretic-Inductive-and-Coinductive-Predicates"></a>
#### 4.4.5.5. Lattice-Theoretic Inductive and Coinductive Predicates

The syntax of inductive type declarations can be used to specify both inductive and coinductive predicates. These are not a built-in feature of Lean's type system, but are instead elaborated to a suitable encoding. They are described in [a dedicated section](../../Definitions/Recursive-Definitions/index.md#coinductive-predicates).

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`declModifiers` is the collection of modifiers on a declaration:
* a doc comment `/-- ... -/`
* a list of attributes `@[attr1, attr2]`
* a visibility specifier, `private` or `public`
* `protected`
* `noncomputable`
* `unsafe`
* `partial` or `nonrec`

All modifiers are optional, and have to come in the listed order.

`nestedDeclModifiers` is the same as `declModifiers`, but attributes are printed
on the same line as the declaration. It is used for declarations nested inside other syntax,
such as inductive constructors, structure projections, and `let rec` / `where` definitions.
```


### Display 2


````text
In Lean, every concrete type other than the universes
and every type constructor other than dependent arrows
is an instance of a general family of type constructions known as inductive types.
It is remarkable that it is possible to construct a substantial edifice of mathematics
based on nothing more than the type universes, dependent arrow types, and inductive types;
everything else follows from those.
Intuitively, an inductive type is built up from a specified list of constructors.
For example, `List α` is the list of elements of type `α`, and is defined as follows:
```
inductive List (α : Type u) where
| nil
| cons (head : α) (tail : List α)
```
A list of elements of type `α` is either the empty list, `nil`,
or an element `head : α` followed by a list `tail : List α`.
See [Inductive types](https://lean-lang.org/theorem_proving_in_lean4/inductive_types.html)
for more information.
````


### Display 3


```text
`declId` matches `foo` or `foo.{u,v}`: an identifier possibly followed by a list of universe names
```


### Display 4


```text
`optDeclSig` matches the signature of a declaration with optional type: a list of binders and then possibly `: type`
```


### Display 5


```text
The *anonymous constructor* `⟨e, ...⟩` is equivalent to `c e ...` if the
expected type is an inductive type with a single constructor `c`.
If more terms are given than `c` has parameters, the remaining arguments
are turned into a new anonymous constructor application. For example,
`⟨a, b, c⟩ : α × (β × γ)` is equivalent to `⟨a, ⟨b, c⟩⟩`.
```


### Display 6


```text
Structure instance. `{ x := e, ... }` assigns `e` to field `x`, which may be
inherited. If `e` is itself a variable called `x`, it can be elided:
`fun y => { x := 1, y }`.
A *structure update* of an existing value can be given via `with`:
`{ point with x := 1 }`.
The structure type can be specified if not inferable:
`{ x := 1, y := 2 : Point }`.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Solo : Type
```


### Display 2


```text
Solo.solo : Solo
```


### Display 3


```text
Yes : Prop
```


### Display 4


```text
Yes.intro : Yes
```


### Display 5


```text
Type mismatch
  EvenOddList.cons "a" (EvenOddList.cons "b" (EvenOddList.cons "c" EvenOddList.nil))
has type
  EvenOddList String !!!true
but is expected to have type
  EvenOddList String true
```


### Display 6


```text
Mismatched inductive type parameter in
  Either' α β
The provided argument
  α
is not definitionally equal to the expected parameter
  α✝

Note: The value of parameter `α✝` must be fixed throughout the inductive declaration. Consider making this parameter an index if it must vary.
```


### Display 7


```text
`String.data` has been deprecated: Use `String.toList` instead
```


### Display 8


```text
false
```


### Display 9


```text
Invalid field `toString`: The environment does not contain `State.toString`, so it is not possible to project the field `toString` from an expression
  s
of type `State`

Note: A private declaration `State.toString` (from the current module) exists but would need to be public to access here.
```


### Display 10


```text
({ array := #[1], augmentation := "" },
 { array := #[1, 2], augmentation := "" },
 { array := #[2, 2], augmentation := "" },
 { array := #[1, 2], augmentation := "" })
```


### Display 11


```text
Textbook.toBook (self : Textbook) : Book
```


### Display 12


```text
{ fst := 17, snd := 2 }
```


### Display 13


```text
printEven sorry : IO Unit
```


### Display 14


```text
Application type mismatch: The argument
  two
has type
  EvenPrime
but is expected to have type
  EvenNumber
in the application
  printEven two
```


### Display 15


```text
structure ElectricBike : Type
number of parameters: 0
parents:
  ElectricBike.toBicycle : Bicycle
  ElectricBike.toElectricVehicle : ElectricVehicle
fields:
  Vehicle.wheels : Nat :=
    2
  ElectricVehicle.batteries : Nat :=
    1
constructor:
  ElectricBike.mk (toBicycle : Bicycle) (batteries : Nat) : ElectricBike
field notation resolution order:
  ElectricBike, Bicycle, ElectricVehicle, Vehicle
```


### Display 16


```text
structure ElectricFamilyBike : Type
number of parameters: 0
parents:
  ElectricFamilyBike.toFamilyBike : FamilyBike
  ElectricFamilyBike.toElectricBike : ElectricBike
fields:
  Vehicle.wheels : Nat :=
    3
  ElectricVehicle.batteries : Nat :=
    2
constructor:
  ElectricFamilyBike.mk (toFamilyBike : FamilyBike) (batteries : Nat) : ElectricFamilyBike
field notation resolution order:
  ElectricFamilyBike, FamilyBike, ElectricBike, Bicycle, ElectricVehicle, Vehicle
```


### Display 17


```text
(kernel) arg #1 of 'Bad.bad' has a non positive occurrence of the datatypes being declared
```


### Display 18


```text
(kernel) arg #2 of 'Fix.fix' contains a non valid occurrence of the datatypes being declared
```


### Display 19


```text
Invalid universe polymorphic resulting type: The resulting universe is not `Prop`, but it may be `Prop` for some parameter values:
  Sort u

Hint: A possible solution is to use levels of the form `max 1 _` or `_ + 1` to ensure the universe is of the form `Type _`
```


### Display 20


```text
Unknown constant `OddList.nil`

Note: Inferred this name from the expected resulting type of `.nil`:
  OddList String
```


### Display 21


```text
Invalid mutually inductive types: Binder annotations for parameter `α` must match
```


### Display 22


```text
Unknown identifier `FreshList`
```


### Display 23


```text
Invalid mutually inductive types: `Optional` has 1 parameter(s), but the preceding type `Both` has 2

Note: All inductive types declared in the same `mutual` block must have the same parameters
```


### Display 24


```text
Invalid mutually inductive types: Parameter `α` has type
  Type u
of sort `Type (u + 1)` but is expected to have type
  Type
of sort `Type 1`
```


### Display 25


```text
Invalid mutually inductive types: The resulting type of this declaration
  Prop
differs from a preceding one
  Type

Note: All inductive types declared in the same `mutual` block must belong to the same type universe
```


### Display 26


```text
(kernel) arg #1 of 'Binding.scope' has a non positive occurrence of the datatypes being declared
```


### Display 27


```text
(kernel) arg #3 of 'RTree.node' contains a non valid occurrence of the datatypes being declared
```


### Display 28


```text
(kernel) invalid nested inductive datatype 'List', nested inductive datatypes parameters cannot contain local variables.
```


### Display 29


```text
(kernel) arg #1 of 'WithCheck.check' has a non positive occurrence of the datatypes being declared
```


### Display 30


```text
(kernel) application type mismatch
  List.length children
argument has type
  @_nested.List_1 branches α
but function has type
  List (@BRTree branches α) → Nat
```


### Display 31


```text
Variable name `RTree''` is not explicitly referenced.

Hint: The binding can be removed (if unused) or named `_` (if used implicitly). Alternatively, prefix the name with `_` to silence this warning:
  [apply] _RTree''

Note: This linter can be disabled with `set_option linter.unusedVariables false`
```


### Display 32


```text
ONat.rec.{u} {motive_1 : ONat → Sort u} {motive_2 : Option ONat → Sort u}
  (mk : (pred : Option ONat) → motive_2 pred → motive_1 (ONat.mk pred)) (none : motive_2 none)
  (some : (val : ONat) → motive_1 val → motive_2 (some val)) (t : ONat) : motive_1 t
```


### Display 33


```text
Definition `OptONat.to_of_eq_id` is a proposition; use `theorem` instead of `def`

Note: This linter can be disabled with `set_option linter.defProp false`
```


### Display 34


```text
Definition `OptONat.of_to_eq_id` is a proposition; use `theorem` instead of `def`

Note: This linter can be disabled with `set_option linter.defProp false`
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
⊢ ∀ (n : Nat), n ≤ 2 → n ∣ 2 → n = 1 ∨ n = 2
```


### Display 2


```text
n✝:Nata✝¹:n✝ ≤ 2a✝:n✝ ∣ 2⊢ n✝ = 1 ∨ n✝ = 2
```


### Display 3


```text
step.step.refl.refla✝:0 ∣ 2⊢ 0 = 1 ∨ 0 = 2
```


### Display 4


```text
All goals completed! 🐙
```


### Display 5


```text
⊢ 2 ≠ 0
```


### Display 6


```text
⊢ 1 ≠ 0
```


### Display 7


```text
⊢ 3 ≠ 0
```


### Display 8


```text
⊢ NoRepeats [(1, 2), (2, 2), (3, 1), (1, 3)]
```


### Display 9


```text
⊢ RunsMatch [(1, 2), (2, 2), (3, 1), (1, 3)] [1, 1, 2, 2, 3, 1, 1, 1]
```


### Display 10


```text
⊢ NonZero [(1, 2), (2, 2), (3, 1), (1, 3)]
```


### Display 11


```text
o:Option ONat⊢ (ofOption o).toOption = o
```


### Display 12


```text
none⊢ (ofOption Option.none).toOption = Option.nonesomeval✝:ONat⊢ (ofOption (Option.some val✝)).toOption = Option.some val✝
```


### Display 13


```text
o:OptONat⊢ ofOption o.toOption = o
```


### Display 14


```text
none⊢ ofOption none.toOption = nonesomea✝:ONat'⊢ ofOption (some a✝).toOption = some a✝
```

