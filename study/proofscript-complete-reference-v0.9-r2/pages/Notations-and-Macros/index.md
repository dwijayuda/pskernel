<a id="language-extension"></a>

# ProofScript — 23. Notations and Macros

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Use native notation, syntax categories, quotations, macros and elaborators in an explicitly declared extension environment. Macro hygiene preserves binding identity; a convenient generated name is not enough. Quoted parser code remains native code rather than being rewritten as ordinary surface expressions. Extensions produce syntax or candidate declarations and gain no independent proof authority.

## ProofScript way of writing it


```proofscript
infixl:65 " <+> " => Nat.add

function combined(x: Nat, y: Nat): Nat := x <+> y
```

**Compiler and coverage boundary.** Register collisions and lifted child slots explicitly. Do not globally rewrite strings, quoted grammar, tactic combinators or host code. Plugin operating-system permissions are separate from logical soundness.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Notations-and-Macros/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Notations-and-Macros/index.html). Source Git blob: `510cedeaf2e96c92a8405dfe0a700b3db3f9c942`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 23. Notations and Macros

Different mathematical fields have their own notational conventions, and many notations are reused with differing meanings in different fields. It is important that formal developments are able to use established notations: formalizing mathematics is already difficult, and the mental overhead of translating between syntaxes can be substantial. At the same time, it's important to be able to control the scope of notational extensions. Many fields use related notations with very different meanings, and it should be possible to combine developments from these separate fields in a way where both readers and the system know which convention is in force in any given region of a file.

Lean addresses the problem of notational extensibility with a variety of mechanisms, each of which solves a different aspect of the problem. They can be combined flexibly to achieve the necessary results:

- The [*extensible parser*](../Elaboration-and-Compilation/index.md#parser) 
  <a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
   allows a great variety of notational conventions to be implemented declaratively, and combined flexibly.
- [Macros](../Elaboration-and-Compilation/index.md#macro-and-elab) allow new syntax to be easily mapped to existing syntax, which is a simple way to provide meaning to new constructs. Due to [hygiene](Macros/index.md#--tech-term-hygienic) and automatic propagation of source positions, this process doesn't interfere with Lean's interactive features.
- [Elaborators](../Elaboration-and-Compilation/index.md#macro-and-elab) provide new syntax with the same tools available to Lean's own syntax in cases where a macro is insufficiently expressive.
- [Notations](Notations/index.md#notations) allow the simultaneous definition of a parser extension, a macro, and a pretty printer. When defining infix, prefix, or postfix operators, [custom operators](Custom-Operators/index.md#operators) automatically take care of precedence and associativity.
- Low-level parser extensions allow the parser to be extended in ways that modify its rules for tokens and whitespace, or that even completely replace Lean's syntax. This is an advanced topic that requires familiarity with Lean internals; nevertheless, the possibility of doing this without modifying the compiler is important. This reference manual is written using a language extension that replaces Lean's concrete syntax with a Markdown-like language for writing documents, but the source files are still Lean files.

1. [23.1. Custom Operators](Custom-Operators/index.md#operators)
2. [23.2. Precedence](Precedence/index.md#precedence)
3. [23.3. Notations](Notations/index.md#notations)
4. [23.4. Defining New Syntax](Defining-New-Syntax/index.md#syntax-ext)
5. [23.5. Macros](Macros/index.md#macros)
6. [23.6. Elaborators](Elaborators/index.md#elaborators)
7. [23.7. Extending `do`-Notation](Extending--do--Notation/index.md#do-elab)
8. [23.8. Extending Lean's Output](Extending-Lean___s-Output/index.md#unexpand-and-delab)
