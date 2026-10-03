<a id="syntax-ext"></a>

# ProofScript — 23.4. Defining New Syntax

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Use native notation, syntax categories, quotations, macros and elaborators in an explicitly declared extension environment. Macro hygiene preserves binding identity; a convenient generated name is not enough. Quoted parser code remains native code rather than being rewritten as ordinary surface expressions. Extensions produce syntax or candidate declarations and gain no independent proof authority.

**Compiler and coverage boundary.** Register collisions and lifted child slots explicitly. Do not globally rewrite strings, quoted grammar, tactic combinators or host code. Plugin operating-system permissions are separate from logical soundness.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Notations-and-Macros/Defining-New-Syntax/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Notations-and-Macros/Defining-New-Syntax/index.html). Source Git blob: `4c0c54cbdad535aec788e145c5b81d89ad126ed5`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 23.4. Defining New Syntax

Lean's uniform representation of syntax is very general and flexible. This means that extensions to Lean's parser do not require extensions to the representation of parsed syntax.

<a id="syntax-data"></a>
### 23.4.1. Syntax Model

Lean's parser produces a concrete syntax tree, of type `Lean.Syntax`. `Lean.Syntax` is an inductive type that represents all of Lean's syntax, including commands, terms, tactics, and any custom extensions. All of these are represented by a few basic building blocks:

<a id="--tech-term-Atoms"></a>
Atoms

Atoms are the fundamental terminals of the grammar, including literals (such as those for characters and numbers), parentheses, operators, and keywords.

<a id="--tech-term-Identifiers"></a>
Identifiers

Identifiers represent names, such as `x`, `Nat`, or `Nat.add`. Identifier syntax includes a list of pre-resolved names that the identifier might refer to.

<a id="--tech-term-Nodes"></a>
Nodes

Nodes represent the parsing of nonterminals. Nodes contain a 
<a id="--tech-term-syntax-kind"></a>
*syntax kind*, which identifies the syntax rule that the node results from, along with an array of child `Syntax` values.

  Missing Syntax

When the parser encounters an error, it returns a partial result, so Lean can provide some feedback about partially-written programs or programs that contain mistakes. Partial results contain one or more instances of missing syntax.

Atoms and identifiers are collectively referred to as 
<a id="--tech-term-tokens"></a>
*tokens*.

<a id="Lean___Syntax___missing"></a>

**inductive type**

```text
Lean.Syntax : Type
```

Lean syntax trees.

Syntax trees are used pervasively throughout Lean: they are produced by the parser, transformed by the macro expander, and elaborated. They are also produced by the delaborator and presented to users.

**Constructors**

```text
Lean.Syntax.missing : Lean.Syntax
```

A portion of the syntax tree that is missing because of a parse error.

The indexing operator on `Syntax` also returns `Syntax.missing` when the index is out of bounds.

```text
Lean.Syntax.node (info : Lean.SourceInfo)
  (kind : Lean.SyntaxNodeKind) (args : Array Lean.Syntax) :
  Lean.Syntax
```

A node in the syntax tree that may have further syntax as child nodes. The node's `kind` determines its interpretation.

For nodes produced by the parser, the `info` field is typically `Lean.SourceInfo.none`, and source information is stored in the corresponding fields of identifiers and atoms. This field is used in two ways:

1. The delaborator uses it to associate nodes with metadata that are used to implement interactive features.
2. Nodes created by quotations use the field to mark the syntax as synthetic (storing the result of `Lean.SourceInfo.fromRef`) even when its leading or trailing tokens are not.

```text
Lean.Syntax.atom (info : Lean.SourceInfo) (val : String) :
  Lean.Syntax
```

A non-identifier atomic component of syntax.

All of the following are atoms:

- keywords, such as `def`, `fun`, and `inductive`
- literals, such as numeric or string literals
- punctuation and delimiters, such as `(`, `)`, and `=>`.

Identifiers are represented by the `Lean.Syntax.ident` constructor. Atoms also correspond to quoted strings inside `syntax` declarations.

```text
Lean.Syntax.ident (info : Lean.SourceInfo)
  (rawVal : Substring.Raw) (val : Lean.Name)
  (preresolved : List Lean.Syntax.Preresolved) : Lean.Syntax
```

An identifier.

In addition to source information, identifiers have the following fields:

- `rawVal` is the literal substring from the input file
- `val` is the parsed Lean name, potentially including macro scopes.
- `preresolved` is the list of possible declarations this could refer to, populated by [quotations](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=quasiquotation).

<a id="Lean___Syntax___Preresolved___namespace"></a>

**inductive type**

```text
Lean.Syntax.Preresolved : Type
```

A possible binding of an identifier in the context in which it was quoted.

Identifiers in quotations may refer to either global declarations or to namespaces that are in scope at the site of the quotation. These are saved in the `Syntax.ident` constructor and are part of the implementation of hygienic macros.

**Constructors**

```text
Lean.Syntax.Preresolved.namespace (ns : Lean.Name) :
  Lean.Syntax.Preresolved
```

A potential namespace reference

```text
Lean.Syntax.Preresolved.decl (n : Lean.Name)
  (fields : List String) : Lean.Syntax.Preresolved
```

A potential global constant or section variable reference, with additional field accesses

<a id="The-Lean-Language-Reference--Notations-and-Macros--Defining-New-Syntax--Syntax-Node-Kinds"></a>
### 23.4.2. Syntax Node Kinds

Syntax node kinds typically identify the parser that produced the node. This is one place where the names given to operators or notations (or their automatically-generated internal names) occur. While only nodes contain a field that identifies their kind, identifiers have the kind `identKind` by convention, while atoms have their internal string as their kind by convention. Lean's parser wraps each keyword atom `KW` in a singleton node whose kind is ```token.KW``. The kind of a syntax value can be extracted using `Syntax.getKind`.

<a id="Lean___SyntaxNodeKind"></a>

**def**

```text
Lean.SyntaxNodeKind : Type
```

Specifies the interpretation of a `Syntax.node` value. An abbreviation for `Name`.

Node kinds may be any name, and do not need to refer to declarations in the environment. Conventionally, however, a node's kind corresponds to the `Parser` or `ParserDesc` declaration that produces it. There are also a number of built-in node kinds that are used by the parsing infrastructure, such as `nullKind` and `choiceKind`; these do not correspond to parser declarations.

<a id="Lean___Syntax___isOfKind"></a>

**def**

```text
Lean.Syntax.isOfKind (stx : Lean.Syntax) (k : Lean.SyntaxNodeKind) :
  Bool
```

Checks whether syntax has the given kind or pseudo-kind.

“Pseudo-kinds” are kinds that are assigned by convention to non-`Syntax.node` values: `identKind` for `Syntax.ident`, ```missing`` for `Syntax.missing`, and the atom's string literal for atoms.

<a id="Lean___Syntax___getKind"></a>

**def**

```text
Lean.Syntax.getKind (stx : Lean.Syntax) : Lean.SyntaxNodeKind
```

Gets the kind of a `Syntax.node` value, or the pseudo-kind of any other `Syntax` value.

“Pseudo-kinds” are kinds that are assigned by convention to non-`Syntax.node` values: `identKind` for `Syntax.ident`, ```missing`` for `Syntax.missing`, and the atom's string literal for atoms.

<a id="Lean___Syntax___setKind"></a>

**def**

```text
Lean.Syntax.setKind (stx : Lean.Syntax) (k : Lean.SyntaxNodeKind) :
  Lean.Syntax
```

Changes the kind at the root of a `Syntax.node` to `k`.

Returns all other `Syntax` values unchanged.

<a id="The-Lean-Language-Reference--Notations-and-Macros--Defining-New-Syntax--Token-and-Literal-Kinds"></a>
### 23.4.3. Token and Literal Kinds

A number of named kinds are associated with the basic tokens produced by the parser. Typically, single-token syntax productions consist of a `node` that contains a single `atom`; the kind saved in the node allows the value to be recognized. Atoms for literals are not interpreted by the parser: string atoms include their leading and trailing double-quote characters along with any escape sequences contained within, and hexadecimal numerals are saved as a string that begins with `"0x"`. [Helpers](index.md#typed-syntax-helpers) such as `Lean.TSyntax.getString` are provided to perform this decoding on demand.

<a id="Lean___identKind"></a>

**def**

```text
Lean.identKind : Lean.SyntaxNodeKind
```

The pseudo-kind assigned to identifiers: ```ident``.

The name ```ident`` is not actually used as a kind for `Syntax.node` values. It is used by convention as the kind of `Syntax.ident` values.

<a id="Lean___strLitKind"></a>

**def**

```text
Lean.strLitKind : Lean.SyntaxNodeKind
```

```str`` is the node kind of string literals like `"foo"`.

<a id="Lean___interpolatedStrKind"></a>

**def**

```text
Lean.interpolatedStrKind : Lean.SyntaxNodeKind
```

```interpolatedStrKind`` is the node kind of an interpolated string literal like `"value = {x}"` in `s!"value = {x}"`.

<a id="Lean___interpolatedStrLitKind"></a>

**def**

```text
Lean.interpolatedStrLitKind : Lean.SyntaxNodeKind
```

```interpolatedStrLitKind`` is the node kind of interpolated string literal fragments like `"value = {` and `}"` in `s!"value = {x}"`.

<a id="Lean___charLitKind"></a>

**def**

```text
Lean.charLitKind : Lean.SyntaxNodeKind
```

```char`` is the node kind of character literals like `'A'`.

<a id="Lean___numLitKind"></a>

**def**

```text
Lean.numLitKind : Lean.SyntaxNodeKind
```

```num`` is the node kind of number literals like `42` and `0xa1`

<a id="Lean___scientificLitKind"></a>

**def**

```text
Lean.scientificLitKind : Lean.SyntaxNodeKind
```

```scientific`` is the node kind of floating point literals like `1.23e-3`.

<a id="Lean___nameLitKind"></a>

**def**

```text
Lean.nameLitKind : Lean.SyntaxNodeKind
```

```name`` is the node kind of name literals like ```foo``.

<a id="Lean___fieldIdxKind"></a>

**def**

```text
Lean.fieldIdxKind : Lean.SyntaxNodeKind
```

```fieldIdx`` is the node kind of projection indices like the `2` in `x.2`.

<a id="The-Lean-Language-Reference--Notations-and-Macros--Defining-New-Syntax--Internal-Kinds"></a>
### 23.4.4. Internal Kinds

<a id="Lean___groupKind"></a>

**def**

```text
Lean.groupKind : Lean.SyntaxNodeKind
```

The ```group`` kind is used for nodes that result from `Lean.Parser.group`. This avoids confusion with the null kind when used inside `optional`.

<a id="Lean___nullKind"></a>

**def**

```text
Lean.nullKind : Lean.SyntaxNodeKind
```

```null`` is the “fallback” kind, used when no other kind applies. Null nodes result from repetition operators, and empty null nodes represent the failure of an optional parse.

The null kind is used for raw list parsers like `many`.

<a id="Lean___choiceKind"></a>

**def**

```text
Lean.choiceKind : Lean.SyntaxNodeKind
```

The ```choice`` kind is used to represent ambiguous parse results.

The parser prioritizes longer matches over shorter ones, but there is not always a unique longest match. All the parse results are saved, and the determination of which to use is deferred until typing information is available.

<a id="Lean___hygieneInfoKind"></a>

**def**

```text
Lean.hygieneInfoKind : Lean.SyntaxNodeKind
```

```hygieneInfo`` is the node kind of the `Lean.Parser.hygieneInfo` parser, which produces an “invisible token” that captures the hygiene information at the current point without parsing anything.

They can be used to generate identifiers (with `Lean.HygieneInfo.mkIdent`) as if they were introduced in a macro's input, rather than by its implementation.

<a id="source-info"></a>
### 23.4.5. Source Positions

Atoms, identifiers, and nodes optionally contain 
<a id="--tech-term-source-information"></a>
source information that tracks their correspondence with the original file. The parser saves source information for all tokens, but not for nodes; position information for parsed nodes is reconstructed from their first and last tokens. Not all `Syntax` data results from the parser: it may be the result of [macro expansion](../Macros/index.md#--tech-term-macro-expansion), in which case it typically contains a mix of generated and parsed syntax, or it may be the result of [delaborating](../Extending-Lean___s-Output/index.md#--tech-term-delaborators) an internal term to display it to a user. In these use cases, nodes may themselves contain source information.

Source information comes in two varieties:

<a id="--tech-term-Original"></a>
Original

Original source information comes from the parser. In addition to the original source location, it also contains leading and trailing whitespace that was skipped by the parser, which allows the original string to be reconstructed. This whitespace is saved as offsets into the string representation of the original source code (that is, as `Substring`) to avoid having to allocate copies of substrings.

<a id="--tech-term-Synthetic"></a>
Synthetic

Synthetic source information comes from metaprograms (including macros) or from Lean's internals. Because there is no original string to be reconstructed, it does not save leading and trailing whitespace. Synthetic source positions are used to provide accurate feedback even when terms have been automatically transformed, as well as to track the correspondence between elaborated expressions and their presentation in Lean's output. A synthetic position may be marked 
<a id="--tech-term-canonical"></a>
*canonical*, in which case some operations that would ordinarily ignore synthetic positions will treat it as if it were not.

<a id="Lean___SourceInfo___original"></a>

**inductive type**

```text
Lean.SourceInfo : Type
```

Source information that relates syntax to the context that it came from.

The primary purpose of `SourceInfo` is to relate the output of the parser and the macro expander to the original source file. When produced by the parser, `Syntax.node` does not carry source info; the parser associates it only with atoms and identifiers. If a `Syntax.node` is introduced by a quotation, then it has synthetic source info that both associates it with an original reference position and indicates that the original atoms in it may not originate from the Lean file under elaboration.

Source info is also used to relate Lean's output to the internal data that it represents; this is the basis for many interactive features. When used this way, it can occur on `Syntax.node` as well.

**Constructors**

```text
Lean.SourceInfo.original (leading : Substring.Raw)
  (pos : String.Pos.Raw) (trailing : Substring.Raw)
  (endPos : String.Pos.Raw) : Lean.SourceInfo
```

A token produced by the parser from original input that includes both leading and trailing whitespace as well as position information.

The `leading` whitespace is inferred after parsing by `Syntax.updateLeading`. This is because the “preceding token” is not well-defined during parsing, especially in the presence of backtracking.

```text
Lean.SourceInfo.synthetic (pos endPos : String.Pos.Raw)
  (canonical : Bool := false) : Lean.SourceInfo
```

Synthetic syntax is syntax that was produced by a metaprogram or by Lean itself (e.g. by a quotation). Synthetic syntax is annotated with a source span from the original syntax, which relates it to the source file.

The delaborator uses this constructor to store an encoded indicator of which core language expression gave rise to the syntax.

The `canonical` flag on synthetic syntax is enabled for syntax that is not literally part of the original input syntax but should be treated “as if” the user really wrote it for the purpose of hovers and error messages. This is usually used on identifiers in order to connect the binding site to the user's original syntax even if the name of the identifier changes during expansion, as well as on tokens that should receive targeted messages.

Generally speaking, a macro expansion should only use a given piece of input syntax in a single canonical token. An exception to this rule is when the same identifier is used to declare two binders, as in the macro expansion for dependent if:

```text
`(if $h : $cond then $t else $e) ~>
`(dite $cond (fun $h => $t) (fun $h => $t))
```

In these cases, if the user hovers over `h` they will see information about both binding sites.

```text
Lean.SourceInfo.none : Lean.SourceInfo
```

A synthesized token without position information.

<a id="The-Lean-Language-Reference--Notations-and-Macros--Defining-New-Syntax--Inspecting-Syntax"></a>
### 23.4.6. Inspecting Syntax

There are three primary ways to inspect `Syntax` values:

  The `Repr` Instance

The `Repr Syntax` instance produces a very detailed representation of syntax in terms of the constructors of the `Syntax` type.

  The `ToString` Instance

The `ToString Syntax` instance produces a compact view, representing certain syntax kinds with particular conventions that can make it easier to read at a glance. This instance suppresses source position information.

  The Pretty Printer

Lean's pretty printer attempts to render the syntax as it would look in a source file, but fails if the nesting structure of the syntax doesn't match the expected shape.

<a id="Representing-Syntax-as-Constructors"></a>
Representing Syntax as Constructors 

The `Repr` instance's representation of syntax can be inspected by quoting it in the context of [`#eval`](../../Interacting-with-Lean/index.md#Lean___Parser___Command___eval), which can run actions in the command elaboration monad `CommandElabM`. To reduce the size of the example output, the helper `removeSourceInfo` is used to remove source information prior to display.
<a id="removeSourceInfo-_LPAR_in-Representing-Syntax-as-Constructors_RPAR_"></a>


```proofscript
partial def removeSourceInfo : Syntax → Syntax
  | .atom _ str => .atom .none str
  | .ident _ str x pre => .ident .none str x pre
  | .node _ k children => .node .none k (children.map removeSourceInfo)
  | .missing => .missing
```

```proofscript
#eval do
  let stx ← `(2 + $(⟨.missing⟩))
  logInfo (repr (removeSourceInfo stx.raw))
```

```lean
Lean.Syntax.node
  (Lean.SourceInfo.none)
  `«term_+_»
  #[Lean.Syntax.node (Lean.SourceInfo.none) `num #[Lean.Syntax.atom (Lean.SourceInfo.none) "2"],
    Lean.Syntax.atom (Lean.SourceInfo.none) "+", Lean.Syntax.missing]
```

In the second example, [macro scopes](../Macros/index.md#--tech-term-macro-scopes) inserted by quotation are visible on the call to `List.length`.

```proofscript
#eval do
  let stx ← `(List.length ["Rose", "Daffodil", "Lily"])
  logInfo (repr (removeSourceInfo stx.raw))
```

The contents of the [pre-resolved identifier](../Macros/index.md#--tech-term-pre-resolved-identifiers) `List.length` are visible here:

```lean
Lean.Syntax.node
  (Lean.SourceInfo.none)
  `Lean.Parser.Term.app
  #[Lean.Syntax.ident
      (Lean.SourceInfo.none)
      "List.length".toRawSubstring
      (Lean.Name.mkNum (Lean.Name.mkStr (Lean.Name.mkStr (Lean.Name.mkNum `List.length.«_@».Manual.NotationsMacros.SyntaxDef 1704743902) "_hygCtx") "_hyg") 2)
      [Lean.Syntax.Preresolved.decl `List.length []],
    Lean.Syntax.node
      (Lean.SourceInfo.none)
      `null
      #[Lean.Syntax.node
          (Lean.SourceInfo.none)
          `«term[_]»
          #[Lean.Syntax.atom (Lean.SourceInfo.none) "[",
            Lean.Syntax.node
              (Lean.SourceInfo.none)
              `null
              #[Lean.Syntax.node (Lean.SourceInfo.none) `str #[Lean.Syntax.atom (Lean.SourceInfo.none) "\"Rose\""],
                Lean.Syntax.atom (Lean.SourceInfo.none) ",",
                Lean.Syntax.node (Lean.SourceInfo.none) `str #[Lean.Syntax.atom (Lean.SourceInfo.none) "\"Daffodil\""],
                Lean.Syntax.atom (Lean.SourceInfo.none) ",",
                Lean.Syntax.node (Lean.SourceInfo.none) `str #[Lean.Syntax.atom (Lean.SourceInfo.none) "\"Lily\""]],
            Lean.Syntax.atom (Lean.SourceInfo.none) "]"]]]
```

The `ToString` instance represents the constructors of `Syntax` as follows:

- The `ident` constructor is represented as the underlying name. Source information and pre-resolved names are not shown.
- The `atom` constructor is represented as a string.
- The `missing` constructor is represented by `<missing>`.
- The representation of the `node` constructor depends on the kind. If the kind is ```null``, then the node is represented by its child nodes order in square brackets. Otherwise, the node is represented by its kind followed by its child nodes, both surrounded by parentheses.

<a id="Syntax-as-Strings"></a>
Syntax as Strings 

The string representation of syntax can be inspected by quoting it in the context of [`#eval`](../../Interacting-with-Lean/index.md#Lean___Parser___Command___eval), which can run actions in the command elaboration monad `CommandElabM`.

```proofscript
#eval do
  let stx ← `(2 + $(⟨.missing⟩))
  logInfo (toString stx)
```

```lean
(«term_+_» (num "2") "+" <missing>)
```

In the second example, [macro scopes](../Macros/index.md#--tech-term-macro-scopes) inserted by quotation are visible on the call to `List.length`.

```proofscript
#eval do
  let stx ← `(List.length ["Rose", "Daffodil", "Lily"])
  logInfo (toString stx)
```

```lean
(Term.app
 `List.length._@.Manual.NotationsMacros.SyntaxDef.3168789510._hygCtx._hyg.2
 [(«term[_]» "[" [(str "\"Rose\"") "," (str "\"Daffodil\"") "," (str "\"Lily\"")] "]")])
```

Pretty printing syntax is typically most useful when including it in a message to a user. Normally, Lean automatically invokes the pretty printer when necessary. However, `ppTerm` can be explicitly invoked if needed.

<a id="Pretty-Printed-Syntax"></a>
Pretty-Printed Syntax 

The string representation of syntax can be inspected by quoting it in the context of [`#eval`](../../Interacting-with-Lean/index.md#Lean___Parser___Command___eval), which can run actions in the command elaboration monad `CommandElabM`. Because new syntax declarations also equip the pretty printer with instructions for displaying them, the pretty printer requires a configuration object. This context can be constructed with a helper:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="getPPContext-_LPAR_in-Pretty-Printed-Syntax_RPAR_"></a>


```proofscript
const getPPContext : CommandElabM PPContext := do
  return {
    env := (← getEnv),
    opts := (← getOptions),
    currNamespace := (← getCurrNamespace),
    openDecls := (← getOpenDecls)
  }
```

```proofscript
#eval show CommandElabM Unit from do
  let stx ← `(2 + 5)
  let fmt ← ppTerm (← getPPContext) stx
  logInfo fmt
```

```lean
2 + 5
```

In the second example, the [macro scopes](../Macros/index.md#--tech-term-macro-scopes) inserted on `List.length` by quotation cause it to be displayed with a dagger (`✝`).

```proofscript
#eval do
  let stx ← `(List.length ["Rose", "Daffodil", "Lily"])
  let fmt ← ppTerm (← getPPContext) stx
  logInfo fmt
```

```lean
List.length✝ ["Rose", "Daffodil", "Lily"]
```

Pretty printing wraps lines and inserts indentation automatically. A [coercion](../../Coercions/index.md#--tech-term-coercion) typically converts the pretty printer's output to the type expected by `logInfo`, using a default layout width. The width can be controlled by explicitly calling `pretty` with a named argument.

```proofscript
#eval do
  let flowers := #["Rose", "Daffodil", "Lily"]
  let manyFlowers := flowers ++ flowers ++ flowers
  let stx ← `(List.length [$(manyFlowers.map (quote (k := `term))),*])
  let fmt ← ppTerm (← getPPContext) stx
  logInfo (fmt.pretty (width := 40))
```

```lean
List.length✝
  ["Rose", "Daffodil", "Lily", "Rose",
    "Daffodil", "Lily", "Rose",
    "Daffodil", "Lily"]
```

<a id="typed-syntax"></a>
### 23.4.7. Typed Syntax

Syntax may additionally be annotated with a type that specifies which [syntax category](index.md#--tech-term-syntax-categories) it belongs to. The `TSyntax` structure contains a type-level list of syntax categories along with a syntax tree. The list of syntax categories typically contains precisely one element, in which case the list structure itself is not shown.

<a id="Lean___TSyntax___mk"></a>

**structure**

```text
Lean.TSyntax (ks : Lean.SyntaxNodeKinds) : Type
```

Typed syntax, which tracks the potential kinds of the `Syntax` it contains.

While syntax quotations produce or expect `TSyntax` values of the correct kinds, this is not otherwise enforced; it can easily be circumvented by direct use of the constructor.

**Constructor**

```text
Lean.TSyntax.mk
```

**Fields**

```text
raw : Lean.Syntax
```

The underlying `Syntax` value.

<a id="Lean___SyntaxNodeKinds"></a>

**def**

```text
Lean.SyntaxNodeKinds : Type
```

`SyntaxNodeKinds` is a set of `SyntaxNodeKind`, implemented as a list.

Singleton `SyntaxNodeKinds` are extremely common. They are written as name literals, rather than as lists; list syntax is required only for empty or non-singleton sets of kinds.

[Quasiquotations](../Macros/index.md#--tech-term-Quasiquotation) prevent the substitution of typed syntax that does not come from the correct syntactic category. For many of Lean's built-in syntactic categories, there is a set of [coercions](../../Coercions/index.md#--tech-term-coercion) that appropriately wrap one kind of syntax for another category, such as a coercion from the syntax of string literals to the syntax of terms. Additionally, many helper functions that are only valid on some syntactic categories are defined for the appropriate typed syntax only.

The constructor of `TSyntax` is public, and nothing prevents users from constructing values that break internal invariants. The use of `TSyntax` should be seen as a way to reduce common mistakes, rather than rule them out entirely.

In addition to `TSyntax`, there are types that represent arrays of syntax, with or without separators. These correspond to repeated elements in syntax declarations or antiquotations. `TSyntaxArray ks` is an [abbreviation](../../Definitions/Definitions/index.md#--tech-term-Abbreviations) for `Array (TSyntax ks)`, while `TSepArray ks sep` is a structure; this means that [generalized field notation](../../Terms/Function-Application/index.md#--tech-term-generalized-field-notation) can be used to apply array functions to `TSyntaxArray` but not `TSepArray`. There is a [coercion](../../Coercions/index.md#--tech-term-coercion) between `TSepArray ks` and `TSyntaxArray ks`, as well as explicit conversion functions. This conversion inserts or removes separator elements from the underlying array, and takes time linear in the number of elements.

<a id="Lean___TSyntaxArray"></a>

**def**

```text
Lean.TSyntaxArray (ks : Lean.SyntaxNodeKinds) : Type
```

An array of syntaxes of kind `ks`.

<a id="Lean___TSyntaxArray___raw"></a>

**opaque**

```text
Lean.TSyntaxArray.raw {ks : Lean.SyntaxNodeKinds}
  (as : Lean.TSyntaxArray ks) : Array Lean.Syntax
```

Converts a `TSyntaxArray` to an `Array Syntax`, without reallocation.

<a id="Lean___Syntax___TSepArray___mk"></a>

**structure**

```text
Lean.Syntax.TSepArray (ks : Lean.SyntaxNodeKinds) (sep : String) : Type
```

An array of syntax elements that alternate with the given separator. Each syntax element has a kind drawn from `ks`.

Separator arrays result from repetition operators such as `,*`. [Coercions](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=coercions) to and from `Array (TSyntax ks)` insert or remove separators as required. The untyped equivalent is `Lean.Syntax.SepArray`.

**Constructor**

```text
Lean.Syntax.TSepArray.mk
```

**Fields**

```text
elemsAndSeps : Array Lean.Syntax
```

The array of elements and separators, ordered like `#[el1, sep1, el2, sep2, el3]`.

<a id="Lean___Syntax___TSepArray___getElems"></a>

**def**

```text
Lean.Syntax.TSepArray.getElems {k : Lean.SyntaxNodeKinds} {sep : String}
  (sa : Lean.Syntax.TSepArray k sep) : Lean.TSyntaxArray k
```

Extracts the non-separator elements of a separated array.

<a id="Lean___Syntax___TSepArray___elemsAndSeps"></a>

**def**

```text
Lean.Syntax.TSepArray.elemsAndSeps {ks : Lean.SyntaxNodeKinds}
  {sep : String} (self : Lean.Syntax.TSepArray ks sep) :
  Array Lean.Syntax
```

The array of elements and separators, ordered like `#[el1, sep1, el2, sep2, el3]`.

<a id="Lean___Syntax___TSepArray___ofElems"></a>

**def**

```text
Lean.Syntax.TSepArray.ofElems {k : Lean.SyntaxNodeKinds} {sep : String}
  (elems : Array (Lean.TSyntax k)) : Lean.Syntax.TSepArray k sep
```

Constructs a typed separated array from elements by adding suitable separators. The provided array should not include the separators.

Like `Syntax.SepArray.ofElems` but for typed syntax.

<a id="Lean___Syntax___TSepArray___push"></a>

**def**

```text
Lean.Syntax.TSepArray.push {k : Lean.SyntaxNodeKinds} {sep : String}
  (sa : Lean.Syntax.TSepArray k sep) (e : Lean.TSyntax k) :
  Lean.Syntax.TSepArray k sep
```

Adds an element to the end of a separated array, adding a separator as needed.

<a id="The-Lean-Language-Reference--Notations-and-Macros--Defining-New-Syntax--Aliases"></a>
### 23.4.8. Aliases

A number of aliases are provided for commonly-used typed syntax varieties. These aliases allow code to be written at a higher level of abstraction.

<a id="Lean___Syntax___Term"></a>

**def**

```text
Lean.Syntax.Term : Type
```

Syntax that represents a Lean term.

<a id="Lean___Syntax___Command"></a>

**def**

```text
Lean.Syntax.Command : Type
```

Syntax that represents a command.

<a id="Lean___Syntax___Level"></a>

**def**

```text
Lean.Syntax.Level : Type
```

Syntax that represents a universe level.

<a id="Lean___Syntax___Tactic"></a>

**def**

```text
Lean.Syntax.Tactic : Type
```

Syntax that represents a tactic.

<a id="Lean___Syntax___Prec"></a>

**def**

```text
Lean.Syntax.Prec : Type
```

Syntax that represents a precedence (e.g. for an operator).

<a id="Lean___Syntax___Prio"></a>

**def**

```text
Lean.Syntax.Prio : Type
```

Syntax that represents a priority (e.g. for an instance declaration).

<a id="Lean___Syntax___Ident"></a>

**def**

```text
Lean.Syntax.Ident : Type
```

Syntax that represents an identifier.

<a id="Lean___Syntax___StrLit"></a>

**def**

```text
Lean.Syntax.StrLit : Type
```

Syntax that represents a string literal.

<a id="Lean___Syntax___CharLit"></a>

**def**

```text
Lean.Syntax.CharLit : Type
```

Syntax that represents a character literal.

<a id="Lean___Syntax___NameLit"></a>

**def**

```text
Lean.Syntax.NameLit : Type
```

Syntax that represents a quoted name literal that begins with a back-tick.

<a id="Lean___Syntax___NumLit"></a>

**def**

```text
Lean.Syntax.NumLit : Type
```

Syntax that represents a numeric literal.

<a id="Lean___Syntax___ScientificLit"></a>

**def**

```text
Lean.Syntax.ScientificLit : Type
```

Syntax that represents a scientific numeric literal that may have decimal and exponential parts.

<a id="Lean___Syntax___HygieneInfo"></a>

**def**

```text
Lean.Syntax.HygieneInfo : Type
```

Syntax that represents macro hygiene info.

<a id="syntax-construction-helpers"></a>
### 23.4.9. Helpers for Constructing Syntax

<a id="Lean___mkIdent"></a>

**def**

```text
Lean.mkIdent (val : Lean.Name) : Lean.Ident
```

Creates an identifier from a name. The resulting identifier has no source position.

<a id="Lean___mkIdentFrom"></a>

**def**

```text
Lean.mkIdentFrom (src : Lean.Syntax) (val : Lean.Name)
  (canonical : Bool := false) : Lean.Ident
```

Creates an identifier with its position copied from `src`.

To refer to a specific constant without a risk of variable capture, use `mkCIdentFrom` instead.

<a id="Lean___mkIdentFromRef"></a>

**def**

```text
Lean.mkIdentFromRef {m : Type → Type} [Monad m] [Lean.MonadRef m]
  (val : Lean.Name) (canonical : Bool := false) : m Lean.Ident
```

Creates an identifier with its position copied from the syntax returned by `getRef`.

To refer to a specific constant without a risk of variable capture, use `mkCIdentFromRef` instead.

<a id="Lean___mkCIdent"></a>

**def**

```text
Lean.mkCIdent (c : Lean.Name) : Lean.Ident
```

Creates an identifier that refers to a constant `c`. The identifier has no source position.

This variant of `mkIdent` makes sure that the identifier cannot accidentally be captured.

<a id="Lean___mkCIdentFrom"></a>

**def**

```text
Lean.mkCIdentFrom (src : Lean.Syntax) (c : Lean.Name)
  (canonical : Bool := false) : Lean.Ident
```

Creates an identifier referring to a constant `c`. The identifier's position is copied from `src`.

This variant of `mkIdentFrom` makes sure that the identifier cannot accidentally be captured.

<a id="Lean___mkCIdentFromRef"></a>

**def**

```text
Lean.mkCIdentFromRef {m : Type → Type} [Monad m] [Lean.MonadRef m]
  (c : Lean.Name) (canonical : Bool := false) : m Lean.Syntax
```

Creates an identifier referring to a constant `c`. The identifier's position is copied from the syntax returned by `getRef`.

This variant of `mkIdentFrom` makes sure that the identifier cannot accidentally be captured.

<a id="Lean___Syntax___mkApp"></a>

**def**

```text
Lean.Syntax.mkApp (fn : Lean.Term) (args : Lean.TSyntaxArray `term) :
  Lean.Term
```

Creates syntax representing a Lean term application, but avoids degenerate empty applications.

<a id="Lean___Syntax___mkCApp"></a>

**def**

```text
Lean.Syntax.mkCApp (fn : Lean.Name) (args : Lean.TSyntaxArray `term) :
  Lean.Term
```

Creates syntax representing a Lean constant application, but avoids degenerate empty applications.

<a id="Lean___Syntax___mkLit"></a>

**def**

```text
Lean.Syntax.mkLit (kind : Lean.SyntaxNodeKind) (val : String)
  (info : Lean.SourceInfo := Lean.SourceInfo.none) : Lean.TSyntax kind
```

Creates a literal of the given kind. It is the caller's responsibility to ensure that the provided literal is a valid atom for the provided kind.

If `info` is provided, then the literal's source information is copied from it.

<a id="Lean___Syntax___mkCharLit"></a>

**def**

```text
Lean.Syntax.mkCharLit (val : Char)
  (info : Lean.SourceInfo := Lean.SourceInfo.none) : Lean.CharLit
```

Creates literal syntax for the given character.

If `info` is provided, then the literal's source information is copied from it.

<a id="Lean___Syntax___mkStrLit"></a>

**def**

```text
Lean.Syntax.mkStrLit (val : String)
  (info : Lean.SourceInfo := Lean.SourceInfo.none) : Lean.StrLit
```

Creates literal syntax for the given string.

If `info` is provided, then the literal's source information is copied from it.

<a id="Lean___Syntax___mkNumLit"></a>

**def**

```text
Lean.Syntax.mkNumLit (val : String)
  (info : Lean.SourceInfo := Lean.SourceInfo.none) : Lean.NumLit
```

Creates literal syntax for a number, which is provided as a string. The caller must ensure that the string is a valid token for the `num` token parser.

If `info` is provided, then the literal's source information is copied from it.

<a id="Lean___Syntax___mkNatLit"></a>

**def**

```text
Lean.Syntax.mkNatLit (val : Nat)
  (info : Lean.SourceInfo := Lean.SourceInfo.none) : Lean.NumLit
```

Creates literal syntax for a natural number.

If `info` is provided, then the literal's source information is copied from it.

<a id="Lean___Syntax___mkScientificLit"></a>

**def**

```text
Lean.Syntax.mkScientificLit (val : String)
  (info : Lean.SourceInfo := Lean.SourceInfo.none) :
  Lean.TSyntax Lean.scientificLitKind
```

Creates literal syntax for a number in scientific notation. The caller must ensure that the provided string is a valid scientific notation literal.

If `info` is provided, then the literal's source information is copied from it.

<a id="Lean___Syntax___mkNameLit"></a>

**def**

```text
Lean.Syntax.mkNameLit (val : String)
  (info : Lean.SourceInfo := Lean.SourceInfo.none) : Lean.NameLit
```

Creates literal syntax for a name. The caller must ensure that the provided string is a valid name literal.

If `info` is provided, then the literal's source information is copied from it.

<a id="Lean___mkOptionalNode"></a>

**def**

```text
Lean.mkOptionalNode (arg : Option Lean.Syntax) : Lean.Syntax
```

Creates an optional node.

Optional nodes consist of null nodes that contain either zero or one element.

<a id="Lean___mkGroupNode"></a>

**def**

```text
Lean.mkGroupNode (args : Array Lean.Syntax := #[]) : Lean.Syntax
```

Creates a group node, as if it were parsed by `Lean.Parser.group`.

<a id="Lean___mkHole"></a>

**def**

```text
Lean.mkHole (ref : Lean.Syntax) (canonical : Bool := false) : Lean.Term
```

Creates a hole (`_`). The hole's position is copied from `ref`.

<a id="quote-class"></a>
#### 23.4.9.1. Quoting Data

The `Quote` class allows values to be converted into typed syntax that represents them. For example, `quote 5` represents ``⟨.node .none `num #[.atom .none "5"]⟩``. The class is parameterized over syntax kinds; this allows the same value to be represented appropriately at different kinds. Instance resolution for `Quote` takes typed syntax [coercions](../../Coercions/index.md#--tech-term-coercion) into account. The syntax kind's default value is ```term``.

There is no guarantee that the result of `Quote.quote` will successfully elaborate. Generally speaking, the resulting syntax contains quoted versions of all explicit arguments and omits implicit arguments.

<a id="Lean___Quote___mk"></a>

**type class**

```text
Lean.Quote (α : Type) (k : Lean.SyntaxNodeKind := `term) : Type
```

Converts a runtime value into surface syntax that denotes it.

Instances do not need to guarantee that the resulting syntax will always re-elaborate into an equivalent value. For example, the syntax may omit implicit arguments that can usually be found automatically.

**Instance Constructor**

```text
Lean.Quote.mk
```

**Methods**

```text
quote : α → Lean.TSyntax k
```

Returns syntax for the given value.

When defining instances of `Quote`, use `mkCIdent` and `mkCApp` to avoid variable capture in the generated syntax.

<a id="Defining--Quote--Instances"></a>
Defining `Quote` Instances 

To quote a tree of type `Tree`, `mkCIdent` and `mkCApp` are used to ensure that local bindings with similar names cannot interfere. Using double backticks ensures that the constructor names don't contain typos and are correctly resolved.
<a id="Tree-_LPAR_in-Defining--Quote--Instances_RPAR_"></a>
<a id="Tree___leaf-_LPAR_in-Defining--Quote--Instances_RPAR_"></a>
<a id="Tree___branch-_LPAR_in-Defining--Quote--Instances_RPAR_"></a>
<a id="instQuoteTreeMkStr1___quoteTree-_LPAR_in-Defining--Quote--Instances_RPAR_"></a>


```proofscript
inductive Tree (α : Type u) : Type u where
  | leaf
  | branch (left : Tree α) (val : α) (right : Tree α)

instance [Quote α] : Quote (Tree α) where
  quote := quoteTree
where
  quoteTree
    | .leaf =>
      mkCIdent ``Tree.leaf
    | .branch l v r =>
      mkCApp ``Tree.branch #[quoteTree l, quote v, quoteTree r]
```

<a id="typed-syntax-helpers"></a>
### 23.4.10. Decoding Typed Syntax

For literals, Lean's parser produces a singleton node that contains an `atom`. The inner atom contains a string with source information, while the node's kind specifies how the atom is to be interpreted. This may involve decoding string escape sequences or interpreting base-16 numeric literals. The helpers in this section perform the correct interpretation.

<a id="Lean___TSyntax___getId"></a>

**def**

```text
Lean.TSyntax.getId (s : Lean.Ident) : Lean.Name
```

Extracts the parsed name from the syntax of an identifier.

Returns `Name.anonymous` if the syntax is malformed.

<a id="Lean___TSyntax___getName"></a>

**def**

```text
Lean.TSyntax.getName (s : Lean.NameLit) : Lean.Name
```

Decodes a quoted name literal, returning the name.

Returns `Lean.Name.anonymous` if the syntax is malformed.

<a id="Lean___TSyntax___getNat"></a>

**def**

```text
Lean.TSyntax.getNat (s : Lean.NumLit) : Nat
```

Interprets a numeric literal as a natural number.

Returns `0` if the syntax is malformed.

<a id="Lean___TSyntax___getScientific"></a>

**def**

```text
Lean.TSyntax.getScientific (s : Lean.ScientificLit) : Nat × Bool × Nat
```

Extracts the components of a scientific numeric literal.

Returns a triple `(n, sign, e) : Nat × Bool × Nat`; the number's value is given by:

```proofscript
if sign then n * 10 ^ (-e) else n * 10 ^ e
```

Returns `(0, false, 0)` if the syntax is malformed.

<a id="Lean___TSyntax___getString"></a>

**def**

```text
Lean.TSyntax.getString (s : Lean.StrLit) : String
```

Decodes a string literal, removing quotation marks and unescaping escaped characters.

Returns `""` if the syntax is malformed.

<a id="Lean___TSyntax___getChar"></a>

**def**

```text
Lean.TSyntax.getChar (s : Lean.CharLit) : Char
```

Decodes a character literal.

Returns `(default : Char)` if the syntax is malformed.

<a id="Lean___TSyntax___getHygieneInfo"></a>

**def**

```text
Lean.TSyntax.getHygieneInfo (s : Lean.HygieneInfo) : Lean.Name
```

Decodes macro hygiene information.

<a id="syntax-categories"></a>
### 23.4.11. Syntax Categories

Lean's parser contains a table of 
<a id="--tech-term-syntax-categories"></a>
*syntax categories*, which correspond to nonterminals in a context-free grammar. Some of the most important categories are terms, commands, universe levels, priorities, precedences, and the categories that represent tokens such as literals. Typically, each [syntax kind](index.md#--tech-term-syntax-kind) corresponds to a category. New categories can be declared using [`declare_syntax_cat`](index.md#Lean___Parser___Command___syntaxCat).

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Declaring Syntactic Categories**

Declares a new syntactic category.

<a id="Lean___Parser___Command___syntaxCat"></a>

```ebnf
command ::= ...
    | docComment?
      declare_syntax_cat ident ((behavior := (catBehaviorBoth | catBehaviorSymbol)))?
```

The leading identifier behavior is an advanced feature that usually does not need to be modified. It controls the behavior of the parser when it encounters an identifier, and can sometimes cause the identifier to be treated as a non-reserved keyword instead. This is used to avoid turning the name of every [tactic](../../Tactic-Proofs/index.md#tactics) into a reserved keyword.

<a id="Lean___Parser___LeadingIdentBehavior___default"></a>

**inductive type**

```text
Lean.Parser.LeadingIdentBehavior : Type
```

Specifies how the parsing table lookup function behaves for identifiers.

The function `Lean.Parser.prattParser` uses two tables: one each for leading and trailing parsers. These tables map tokens to parsers. Because keyword tokens are distinct from identifier tokens, keywords and identifiers cannot be confused, even when they are syntactically identical. Specifying an alternative leading identifier behavior allows greater flexibility and makes it possible to avoid reserved keywords in some situations.

When the leading token is syntactically an identifier, the current syntax category's `LeadingIdentBehavior` specifies how the parsing table lookup function behaves, and allows controlled “punning” between identifiers and keywords. This feature is used to avoid creating a reserved symbol for each built-in tactic (e.g., `apply` or `assumption`). As a result, tactic names can be used as identifiers.

**Constructors**

```text
Lean.Parser.LeadingIdentBehavior.default :
  Lean.Parser.LeadingIdentBehavior
```

If the leading token is an identifier, then the parser just executes the parsers associated with the auxiliary token “ident”, which parses identifiers.

```text
Lean.Parser.LeadingIdentBehavior.symbol :
  Lean.Parser.LeadingIdentBehavior
```

If the leading token is an identifier `<foo>`, and there are parsers `P` associated with the token `<foo>`, then the parser executes `P`. Otherwise, it executes only the parsers associated with the auxiliary token “ident”, which parses identifiers.

```text
Lean.Parser.LeadingIdentBehavior.both :
  Lean.Parser.LeadingIdentBehavior
```

If the leading token is an identifier `<foo>`, then it executes the parsers associated with token `<foo>` and parsers associated with the auxiliary token “ident”, which parses identifiers.

<a id="syntax-rules"></a>
### 23.4.12. Syntax Rules

Each [syntax category](index.md#--tech-term-syntax-categories) is associated with a set of 
<a id="--tech-term-syntax-rules"></a>
*syntax rules*, which correspond to productions in a context-free grammar. Syntax rules can be defined using the [`syntax`](index.md#Lean___Parser___Command___syntax) command.

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Syntax Rules**

<a id="Lean___Parser___Command___syntax"></a>

```ebnf
command ::= ...
    | docComment?
      attributes?
      attrKind
      syntax(:prec)? ((name := ident))? ((priority := prio))? stx* : ident
```

As with operator and notation declarations, the contents of the documentation comments are shown to users while they interact with the new syntax. Attributes may be added to invoke compile-time metaprograms on the resulting definition.

Syntax rules interact with [section scopes](../../Namespaces-and-Sections/index.md#--tech-term-section-scope) in the same manner as attributes, operators, and notations. By default, syntax rules are available to the parser in any module that transitively imports the one in which they are established, but they may be declared `scoped` or `local` to restrict their availability either to contexts in which the current namespace has been opened or to the current [section scope](../../Namespaces-and-Sections/index.md#--tech-term-section-scope), respectively.

When multiple syntax rules for a category can match the current input, the [local longest-match rule](../Custom-Operators/index.md#--tech-term-local-longest-match-rule) is used to select one of them. Like notations and operators, if there is a tie for the longest match then the declared priorities are used to determine which parse result applies. If this still does not resolve the ambiguity, then all the results that tied are saved. The elaborator is expected to attempt all of them, succeeding when exactly one can be elaborated.

The syntax rule's precedence, written immediately after the [`syntax`](index.md#Lean___Parser___Command___syntax) keyword, restricts the parser to use this new syntax only when the precedence context is at least the provided value. Just as with operators and notations, syntax rules may be manually provided with a name; if they are not, an otherwise-unused name is generated. Whether provided or generated, this name is used as the syntax kind in the resulting `node`.

The body of a syntax declaration is even more flexible than that of a notation. String literals specify atoms to match. Subterms may be drawn from any syntax category, rather than just terms, and they may be optional or repeated, with or without interleaved comma separators. Identifiers in syntax rules indicate syntax categories, rather than naming subterms as they do in notations.

Finally, the syntax rule specifies which syntax category it extends. It is an error to declare a syntax rule in a nonexistent category.

<a id="stx"></a>

**syntax**

**Syntax Specifiers**

The syntactic category `stx` is the grammar of specifiers that may occur in the body of a [`syntax`](index.md#Lean___Parser___Command___syntax) command.

String literals are parsed as [atoms](index.md#--tech-term-Atoms) (including both keywords such as `if`, `#eval`, or `where`):

<a id="Lean___Parser___Syntax___atom"></a>

```ebnf
stx ::=
    str
```

Leading and trailing spaces in the strings do not affect parsing, but they cause Lean to insert spaces in the corresponding position when displaying the syntax in [proof states](../../Tactic-Proofs/index.md#--tech-term-proof-state) and error messages. Ordinarily, valid identifiers occurring as atoms in syntax rules become reserved keywords. Preceding a string literal with an ampersand (`&`) suppresses this behavior:

<a id="Lean___Parser___Syntax___nonReserved"></a>

```ebnf
stx ::= ...
    | &str
```

Identifiers specify the syntactic category expected in a given position, and may optionally provide a precedence:

<a id="Lean___Parser___Syntax___cat"></a>

```ebnf
stx ::= ...
    | ident(:prec)?
```

The `*` modifier is the Kleene star, matching zero or more repetitions of the preceding syntax. It can also be written using `many`.

<a id="_FLQQ_stx_____FLQQ_"></a>

```ebnf
stx ::= ...
    | stx *
```

The `+` modifier matches one or more repetitions of the preceding syntax. It can also be written using `many1`.

<a id="_FLQQ_stx_____FLQQ_-next"></a>

```ebnf
stx ::= ...
    | stx +
```

The `?` modifier makes a subterm optional, and matches zero or one, but not more, repetitions of the preceding syntax. It can also be written as `optional`.

<a id="stx____"></a>

```ebnf
stx ::= ...
    | stx ?
```

<a id="Lean___Parser___Syntax___unary"></a>

```ebnf
stx ::= ...
    | optional(stx)
```

The `,*` modifier matches zero or more repetitions of the preceding syntax with interleaved commas. It can also be written using `sepBy`.

<a id="_FLQQ_stx________FLQQ_"></a>

```ebnf
stx ::= ...
    | stx ,*
```

The `,+` modifier matches one or more repetitions of the preceding syntax with interleaved commas. It can also be written using `sepBy1`.

<a id="_FLQQ_stx________FLQQ_-next"></a>

```ebnf
stx ::= ...
    | stx ,+
```

The `,*,?` modifier matches zero or more repetitions of the preceding syntax with interleaved commas, allowing an optional trailing comma after the final repetition. It can also be written using `sepBy` with the `allowTrailingSep` modifier.

<a id="_FLQQ_stx______________FLQQ_"></a>

```ebnf
stx ::= ...
    | stx ,*,?
```

The `,+,?` modifier matches one or more repetitions of the preceding syntax with interleaved commas, allowing an optional trailing comma after the final repetition. It can also be written using `sepBy1` with the `allowTrailingSep` modifier.

<a id="_FLQQ_stx______________FLQQ_-next"></a>

```ebnf
stx ::= ...
    | stx ,+,?
```

The `<|>` operator, which can be written `orelse`, matches either syntax. However, if the first branch consumes any tokens, then it is committed to, and failures will not be backtracked:

<a id="_FLQQ_stx__LT_____GT___FLQQ_"></a>

```ebnf
stx ::= ...
    | stx <|> stx
```

<a id="Lean___Parser___Syntax___binary"></a>

```ebnf
stx ::= ...
    | orelse(stx, stx)
```

The `!` operator matches the complement of its argument. If its argument fails, then it succeeds, resetting the parsing state.

<a id="stx____-next"></a>

```ebnf
stx ::= ...
    | ! stx
```

Syntax specifiers may be grouped using parentheses.

<a id="Lean___Parser___Syntax___paren"></a>

```ebnf
stx ::= ...
    | (stx)
```

Repetitions may be defined using `many` and `many1`. The latter requires at least one instance of the repeated syntax.

<a id="Lean___Parser___Syntax___unary-next"></a>

```ebnf
stx ::= ...
    | many(stx)
```

<a id="Lean___Parser___Syntax___unary-next-next"></a>

```ebnf
stx ::= ...
    | many1(stx)
```

Repetitions with separators may be defined using `sepBy` and `sepBy1`, which respectively match zero or more occurrences and one or more occurrences, separated by some other syntax. They come in three varieties:

- The two-parameter version uses the atom provided in the string literal to parse the separators, and does not allow trailing separators.
- The three-parameter version uses the third parameter to parse the separators, using the atom for pretty-printing.
- The four-parameter version optionally allows the separator to occur an extra time at the end of the sequence. The fourth argument must always literally be the keyword `allowTrailingSep`.

<a id="Lean___Parser___Syntax___sepBy"></a>

```ebnf
stx ::= ...
    | sepBy(stx, str)
```

<a id="Lean___Parser___Syntax___sepBy-next"></a>

```ebnf
stx ::= ...
    | sepBy(stx, str, stx)
```

<a id="Lean___Parser___Syntax___sepBy-next-next"></a>

```ebnf
stx ::= ...
    | sepBy(stx, str, stx, allowTrailingSep)
```

<a id="Lean___Parser___Syntax___sepBy1"></a>

```ebnf
stx ::= ...
    | sepBy1(stx, str)
```

<a id="Lean___Parser___Syntax___sepBy1-next"></a>

```ebnf
stx ::= ...
    | sepBy1(stx, str, stx)
```

<a id="Lean___Parser___Syntax___sepBy1-next-next"></a>

```ebnf
stx ::= ...
    | sepBy1(stx, str, stx, allowTrailingSep)
```

<a id="Parsing-Matched-Parentheses-and-Brackets"></a>
Parsing Matched Parentheses and Brackets 

A language that consists of matched parentheses and brackets can be defined using syntax rules. The first step is to declare a new [syntax category](index.md#--tech-term-syntax-categories):
<a id="Lean___Parser___Category___balanced-_LPAR_in-Parsing-Matched-Parentheses-and-Brackets_RPAR_"></a>


```proofscript
declare_syntax_cat balanced
```

Next, rules can be added for parentheses and square brackets. To rule out empty strings, the base cases consist of empty pairs.

```proofscript
syntax "(" ")" : balanced
syntax "[" "]" : balanced
syntax "(" balanced ")" : balanced
syntax "[" balanced "]" : balanced
syntax balanced balanced : balanced
```

In order to invoke Lean's parser on these rules, there must also be an embedding from the new syntax category into one that may already be parsed:
<a id="termBalanced-_LPAR_in-Parsing-Matched-Parentheses-and-Brackets_RPAR_"></a>


```proofscript
syntax (name := termBalanced) "balanced " balanced : term
```

These terms cannot be elaborated, but reaching an elaboration error indicates that parsing succeeded:

```proofscript
/--
error: elaboration function for `termBalanced` has not been implemented
  balanced ()
-/
#guard_msgs in
example := balanced ()

/--
error: elaboration function for `termBalanced` has not been implemented
  balanced []
-/
#guard_msgs in
example := balanced []

/--
error: elaboration function for `termBalanced` has not been implemented
  balanced [[]()([])]
-/
#guard_msgs in
example := balanced [[] () ([])]
```

Similarly, parsing fails when they are mismatched:

```lean
example := balanced [() (]]
```

```lean
<example>:1:25-1:26: unexpected token ']'; expected ')' or balanced
```

<a id="Parsing-Comma-Separated-Repetitions"></a>
Parsing Comma-Separated Repetitions 

A variant of list literals that requires double square brackets and allows a trailing comma can be added with the following syntax:

```proofscript
syntax "[[" term,*,? "]]" : term
```

Adding a [macro](../Macros/index.md#--tech-term-Macros) that describes how to translate it into an ordinary list literal allows it to be used in tests.

```proofscript
macro_rules
  | `(term|[[$e:term,*]]) => `([$e,*])
```

```proofscript
#eval [["Dandelion", "Thistle",]]
```

```lean
["Dandelion", "Thistle"]
```

<a id="syntax-indentation"></a>
### 23.4.13. Indentation

Internally, the parser maintains a saved source position. Syntax rules may include instructions that interact with these saved positions, causing parsing to fail when a condition is not met. Indentation-sensitive constructs, such as [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do), save a source position, parse their constituent parts while taking this saved position into account, and then restore the original position.

In particular, Indentation-sensitvity is specified by combining `withPosition` or `withPositionAfterLinebreak`, which save the source position at the start of parsing some other syntax, with `colGt`, `colGe`, and `colEq`, which compare the current column with the column from the most recently-saved position. `lineEq` can also be used to ensure that two positions are on the same line in the source file.

<a id="withPosition"></a>

**parser alias**

```text
withPosition(p)
```

Arity is sum of arguments' arities

`withPosition(p)` runs `p` while setting the "saved position" to the current position. This has no effect on its own, but various other parsers access this position to achieve some composite effect:

- `colGt`, `colGe`, `colEq` compare the column of the saved position to the current position, used to implement Python-style indentation sensitive blocks
- `lineEq` ensures that the current position is still on the same line as the saved position, used to implement composite tokens

The saved position is only available in the read-only state, which is why this is a scoping parser: after the `withPosition(..)` block the saved position will be restored to its original value.

This parser has the same arity as `p` - it just forwards the results of `p`.

<a id="withoutPosition"></a>

**parser alias**

```text
withoutPosition(p)
```

Arity is sum of arguments' arities

`withoutPosition(p)` runs `p` without the saved position, meaning that position-checking parsers like `colGt` will have no effect. This is usually used by bracketing constructs like `(...)` so that the user can locally override whitespace sensitivity.

This parser has the same arity as `p` - it just forwards the results of `p`.

<a id="withPositionAfterLinebreak"></a>

**parser alias**

```text
withPositionAfterLinebreak
```

- Arity: 1
- Automatically wraps arguments in a `null` node unless there's exactly one

<a id="colGt"></a>

**parser alias**

```text
colGt
```

- Arity: 0
- Automatically wraps arguments in a `null` node unless there's exactly one

The `colGt` parser requires that the next token starts a strictly greater column than the saved position (see `withPosition`). This can be used for whitespace sensitive syntax for the arguments to a tactic, to ensure that the following tactic is not interpreted as an argument.

```text
example (x : False) : False := by
  revert x
  exact id
```

Here, the `revert` tactic is followed by a list of `colGt ident`, because otherwise it would interpret `exact` as an identifier and try to revert a variable named `exact`.

This parser has arity 0 - it does not capture anything.

<a id="colGe"></a>

**parser alias**

```text
colGe
```

- Arity: 0
- Automatically wraps arguments in a `null` node unless there's exactly one

The `colGe` parser requires that the next token starts from at least the column of the saved position (see `withPosition`), but allows it to be more indented. This can be used for whitespace sensitive syntax to ensure that a block does not go outside a certain indentation scope. For example it is used in the lean grammar for `else if`, to ensure that the `else` is not less indented than the `if` it matches with.

This parser has arity 0 - it does not capture anything.

<a id="colEq"></a>

**parser alias**

```text
colEq
```

- Arity: 0
- Automatically wraps arguments in a `null` node unless there's exactly one

The `colEq` parser ensures that the next token starts at exactly the column of the saved position (see `withPosition`). This can be used to do whitespace sensitive syntax like a `by` block or `do` block, where all the lines have to line up.

This parser has arity 0 - it does not capture anything.

<a id="lineEq"></a>

**parser alias**

```text
lineEq
```

- Arity: 0
- Automatically wraps arguments in a `null` node unless there's exactly one

The `lineEq` parser requires that the current token is on the same line as the saved position (see `withPosition`). This can be used to ensure that composite tokens are not "broken up" across different lines. For example, `else if` is parsed using `lineEq` to ensure that the two tokens are on the same line.

This parser has arity 0 - it does not capture anything.

<a id="Aligned-Columns"></a>
Aligned Columns 

This syntax for saving notes takes a bulleted list of items, each of which must be aligned at the same column.

```proofscript
syntax "note " ppLine withPosition((colEq "◦ " str ppLine)+) : term
```

There is no elaborator or macro associated with this syntax, but the following example is accepted by the parser:

```proofscript
#check
  note
    ◦ "One"
    ◦ "Two"
```

```lean
elaboration function for `«termNote__◦__»` has not been implemented
  note
    ◦ "One"
    ◦ "Two"
```

The syntax does not require that the list is indented with respect to the opening token, which would require an extra `withPosition` and a `colGt`.

```proofscript
#check
  note
◦ "One"
◦ "Two"
```

```lean
elaboration function for `«termNote__◦__»` has not been implemented
  note
    ◦ "One"
    ◦ "Two"
```

The following examples are not syntactically valid because the columns of the bullet points do not match.

```lean
#check  note    ◦ "One"   ◦ "Two"
```

```lean
<example>:4:3-4:4: expected end of input
```

```lean
#check  note   ◦ "One"     ◦ "Two"
```

```lean
<example>:4:5-4:6: expected end of input
```

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
A `docComment` parses a "documentation comment" like `/-- foo -/`. This is not treated like
a regular comment (that is, as whitespace); it is parsed and forms part of the syntax tree structure.

At parse time, `docComment` checks the value of the `doc.verso` option. If it is true, the contents
are parsed as Verso markup. If not, the contents are treated as plain text or Markdown. Use
`plainDocComment` to always treat the contents as plain text.

A plain text doc comment node contains a `/--` atom and then the remainder of the comment, `foo -/`
in this example. Use `TSyntax.getDocString` to extract the body text from a doc string syntax node.
A Verso comment node contains the `/--` atom, the document's syntax tree, and a closing `-/` atom.
```


### Display 2


```text
`attrKind` matches `("scoped" <|> "local")?`, used before an attribute like `@[local simp]`.
```


### Display 3


```text
`p*` is shorthand for `many(p)`. It uses parser `p` 0 or more times, and produces a
`nullNode` containing the array of parsed results. This parser has arity 1.

If `p` has arity more than 1, it is auto-grouped in the items generated by the parser.
```


### Display 4


```text
Parses the literal symbol.

The symbol is automatically included in the set of reserved tokens ("keywords").
Keywords cannot be used as identifiers, unless the identifier is otherwise escaped.
For example, `"fun"` reserves `fun` as a keyword; to refer an identifier named `fun` one can write `«fun»`.
Adding a `&` prefix prevents it from being reserved, for example `&"true"`.

Whitespace before or after the atom is used as a pretty printing hint.
For example, `" + "` parses `+` and pretty prints it with whitespace on both sides.
The whitespace has no effect on parsing behavior.
```


### Display 5


```text
Parses a literal symbol. The `&` prefix prevents it from being included in the set of reserved tokens ("keywords").
This means that the symbol can still be recognized as an identifier by other parsers.

Some syntax categories, such as `tactic`, automatically apply `&` to the first symbol.

Whitespace before or after the atom is used as a pretty printing hint.
For example, `" + "` parses `+` and pretty prints it with whitespace on both sides.
The whitespace has no effect on parsing behavior.

(Not exposed by parser description syntax:
If the `includeIdent` argument is true, lets `ident` be reinterpreted as `atom` if it matches.)
```


### Display 6


```text
`p+` is shorthand for `many1(p)`. It uses parser `p` 1 or more times, and produces a
`nullNode` containing the array of parsed results. This parser has arity 1.

If `p` has arity more than 1, it is auto-grouped in the items generated by the parser.
```


### Display 7


```text
`(p)?` is shorthand for `optional(p)`. It uses parser `p` 0 or 1 times, and produces a
`nullNode` containing the array of parsed results. This parser has arity 1.

`p` is allowed to have arity n > 1 (in which case the node will have either 0 or n children),
but if it has arity 0 then the result will be ambiguous.

Because `?` is an identifier character, `ident?` will not work as intended.
You have to write either `ident ?` or `(ident)?` for it to parse as the `?` combinator
applied to the `ident` parser.
```


### Display 8


```text
`p,*` is shorthand for `sepBy(p, ",")`. It parses 0 or more occurrences of
`p` separated by `,`, that is: `empty | p | p,p | p,p,p | ...`.

It produces a `nullNode` containing a `SepArray` with the interleaved parser
results. It has arity 1, and auto-groups its component parser if needed.
```


### Display 9


```text
`p,+` is shorthand for `sepBy1(p, ",")`. It parses 1 or more occurrences of
`p` separated by `,`, that is: `p | p,p | p,p,p | ...`.

It produces a `nullNode` containing a `SepArray` with the interleaved parser
results. It has arity 1, and auto-groups its component parser if needed.
```


### Display 10


```text
`p,*,?` is shorthand for `sepBy(p, ",", allowTrailingSep)`.
It parses 0 or more occurrences of `p` separated by `,`, possibly including
a trailing `,`, that is: `empty | p | p, | p,p | p,p, | p,p,p | ...`.

It produces a `nullNode` containing a `SepArray` with the interleaved parser
results. It has arity 1, and auto-groups its component parser if needed.
```


### Display 11


```text
`p,+,?` is shorthand for `sepBy1(p, ",", allowTrailingSep)`.
It parses 1 or more occurrences of `p` separated by `,`, possibly including
a trailing `,`, that is: `p | p, | p,p | p,p, | p,p,p | ...`.

It produces a `nullNode` containing a `SepArray` with the interleaved parser
results. It has arity 1, and auto-groups its component parser if needed.
```


### Display 12


```text
`p1 <|> p2` is shorthand for `orelse(p1, p2)`, and parses either `p1` or `p2`.
It does not backtrack, meaning that if `p1` consumes at least one token then
`p2` will not be tried. Therefore, the parsers should all differ in their first
token. The `atomic(p)` parser combinator can be used to locally backtrack a parser.
(For full backtracking, consider using extensible syntax classes instead.)

On success, if the inner parser does not generate exactly one node, it will be
automatically wrapped in a `group` node, so the result will always be arity 1.

The `<|>` combinator does not generate a node of its own, and in particular
does not tag the inner parsers to distinguish them, which can present a problem
when reconstructing the parse. A well formed `<|>` parser should use disjoint
node kinds for `p1` and `p2`.
```


### Display 13


```text
`!p` parses the negation of `p`. That is, it fails if `p` succeeds, and
otherwise parses nothing. It has arity 0.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Lean.Syntax.node
  (Lean.SourceInfo.none)
  `«term_+_»
  #[Lean.Syntax.node (Lean.SourceInfo.none) `num #[Lean.Syntax.atom (Lean.SourceInfo.none) "2"],
    Lean.Syntax.atom (Lean.SourceInfo.none) "+", Lean.Syntax.missing]
```


### Display 2


```text
Lean.Syntax.node
  (Lean.SourceInfo.none)
  `Lean.Parser.Term.app
  #[Lean.Syntax.ident
      (Lean.SourceInfo.none)
      "List.length".toRawSubstring
      (Lean.Name.mkNum (Lean.Name.mkStr (Lean.Name.mkStr (Lean.Name.mkNum `List.length.«_@».Manual.NotationsMacros.SyntaxDef 1704743902) "_hygCtx") "_hyg") 2)
      [Lean.Syntax.Preresolved.decl `List.length []],
    Lean.Syntax.node
      (Lean.SourceInfo.none)
      `null
      #[Lean.Syntax.node
          (Lean.SourceInfo.none)
          `«term[_]»
          #[Lean.Syntax.atom (Lean.SourceInfo.none) "[",
            Lean.Syntax.node
              (Lean.SourceInfo.none)
              `null
              #[Lean.Syntax.node (Lean.SourceInfo.none) `str #[Lean.Syntax.atom (Lean.SourceInfo.none) "\"Rose\""],
                Lean.Syntax.atom (Lean.SourceInfo.none) ",",
                Lean.Syntax.node (Lean.SourceInfo.none) `str #[Lean.Syntax.atom (Lean.SourceInfo.none) "\"Daffodil\""],
                Lean.Syntax.atom (Lean.SourceInfo.none) ",",
                Lean.Syntax.node (Lean.SourceInfo.none) `str #[Lean.Syntax.atom (Lean.SourceInfo.none) "\"Lily\""]],
            Lean.Syntax.atom (Lean.SourceInfo.none) "]"]]]
```


### Display 3


```text
(«term_+_» (num "2") "+" <missing>)
```


### Display 4


```text
(Term.app
 `List.length._@.Manual.NotationsMacros.SyntaxDef.3168789510._hygCtx._hyg.2
 [(«term[_]» "[" [(str "\"Rose\"") "," (str "\"Daffodil\"") "," (str "\"Lily\"")] "]")])
```


### Display 5


```text
2 + 5
```


### Display 6


```text
List.length✝ ["Rose", "Daffodil", "Lily"]
```


### Display 7


```text
List.length✝
  ["Rose", "Daffodil", "Lily", "Rose",
    "Daffodil", "Lily", "Rose",
    "Daffodil", "Lily"]
```


### Display 8


```text
["Dandelion", "Thistle"]
```


### Display 9


```text
elaboration function for `«termNote__◦__»` has not been implemented
  note
    ◦ "One"
    ◦ "Two"
```

