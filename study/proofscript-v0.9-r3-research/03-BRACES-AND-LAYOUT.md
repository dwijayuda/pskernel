# r3 Braces and Layout

Status: **accepted r3 design; documentation/specification only; not implemented**

## Problem

r2 uses braces around selected structures, classes, inductives, matches, instances, local <code>where</code> blocks, conditionals, tactics, and native <code>do</code> forms, but the meaning of newlines/indentation still depends on the nested Lean parser category.

That is semantically faithful but visually misleading: application developers tend to read braces as the primary structural boundary.

r3 adopts a stronger rule:

> In a ProofScript-owned braced sequence, the braces and explicit category separators determine the outer sequence. Indentation inside that owned sequence is formatting, not a second hidden member-boundary mechanism.

Nested inherited syntax can still have native layout rules.

## Alternatives studied

| Design | Advantage | Cost | r3 decision |
|---|---|---|---|
| r2 braces + native layout | smallest migration from v0.7 | false-brace familiarity; formatter trivia remains semantic | reject |
| fewer braces, mostly Lean layout | smallest grammar | less approachable to target audience | retain as inherited style, not canonical Standard style |
| explicit category-owned braces | predictable boundary, easier formatter/LSP | requires separator redesign and migration | **recommend** |
| universal C/JS statement block | familiar | invents statement/return semantics and large lowering | reject |

The goal is explicit structure, not JavaScript blocks.
## General brace rule

The guarantee applies only to registered ProofScript-owned brace productions.

Inside such a brace body:

1. the matching brace closes the owned construct;
2. outer members are separated by the category's explicit separator or marker;
3. indentation does not decide where one outer member ends and the next begins;
4. newlines are formatting except where a nested native child category uses layout;
5. delimiter depth prevents separators inside nested parentheses/brackets/braces from ending the outer member.

A native Lean <code>do</code>, tactic sequence, quotation, or imported extension remains native unless a specific r3 rule owns it.

Thus ProofScript does not claim that every brace anywhere disables Lean layout.

## Category separator table

| Owned body | Outer boundary mechanism |
|---|---|
| structure fields | comma-separated fields; no trailing comma |
| class fields | comma-separated fields; no trailing comma |
| inductive constructors | leading <code>|</code> marker |
| match alternatives | leading <code>|</code> marker |
| instance field initializers | native semicolon separator, optional trailing semicolon |
| local <code>where</code> declarations | native semicolon separator, optional trailing semicolon |
| braced conditional branch | exactly one term, no member sequence |
| braced native <code>do</code> | native semicolon sequence if using one-line/brace mode |
| braced tactics | native tactic semicolon / <code>&lt;;&gt;</code> combinators |

This preserves the r2 policy that ProofScript does not invent a general declaration semicolon.
## Structures and classes

Proposed Standard spelling:

~~~proofscript
structure User where {
  name: String,
  active: Bool
}

class Sized(α: Type) where {
  size: α -> Nat
}
~~~

Conceptual grammar:

~~~ebnf
BracedStructBody ::=
  "{" (StructField ("," StructField)*)? "}"

BracedClassBody ::=
  "{" (ClassField ("," ClassField)*)? "}"
~~~

A field type may span lines. A top-level comma at the owned brace depth ends the field; commas nested inside a term do not. Empty brace bodies are accepted when the corresponding lowered native structure/class declaration is semantically valid.

Canonical lowering removes the commas and constructs the same native field AST.

This is an intentional r3 E-class surface change. The comma is surface punctuation, not a runtime/product operation.

Native layout remains available in inherited style:

~~~proofscript
structure User where
  name : String
  active : Bool
~~~

A Standard formatter chooses the braced/comma form for owned r3 source.

## Inductives

Constructors already have an unambiguous marker:

~~~proofscript
inductive LoadState(α: Type) where {
  | idle
  | loading(requestId: Nat)
  | ready(requestId: Nat, value: α)
}
~~~

The <code>|</code> tokens define constructor boundaries at the owned brace depth. No comma or semicolon is introduced between constructors. An empty constructor sequence is permitted where the corresponding native empty inductive is valid.
## Matches

~~~proofscript
match value with {
  | .none => fallback
  | .some n => n
}
~~~

Each alternative begins with <code>|</code>. The RHS is one complete term parsed in the expected term category. A nested match owns its own alternatives; inner bars are not scanned textually.

The following is valid because the RHS is a nested expression:

~~~proofscript
match outer with {
  | .some x =>
      match x with {
        | .some y => y
        | .none => 0
      }
  | .none => 0
}
~~~

Indentation is formatting for the **outer r3 alternative sequence**. If an RHS itself uses a native layout-sensitive construct, that nested construct retains its rules.

## Instances

Lean's instance initializer sequence already admits semicolon separators. r3 uses them explicitly in brace mode:

~~~proofscript
instance : Sized String where {
  size(s: String): Nat := s.length;
}
~~~

Conceptual grammar:

~~~ebnf
BracedInstanceBody ::=
  "{" (InstanceField (";" InstanceField)* ";"?)? "}"
~~~

Semicolons here are not declaration terminators; they belong to the instance initializer sequence, a role already present in the native category.
## Local where declarations

Brace mode uses native local-declaration semicolons explicitly:

~~~proofscript
function incrementTwice(x: Nat): Nat :=
  helper(helper(x))
where {
  helper(y: Nat): Nat := y + 1;
}
~~~

Multiple local declarations require a semicolon at the r3 brace depth.

Layout mode remains available through inherited syntax:

~~~proofscript
def incrementTwice (x : Nat) : Nat :=
  helper (helper x)
where
  helper (y : Nat) : Nat := y + 1
~~~

The formatter never rewrites between these forms without an AST-level transformation.

## Conditionals

r3 retains one-term braced conditionals:

~~~proofscript
if (n <= 10) { n } else { 10 }
~~~

A branch is a single term. It is not a statement list and it has no implicit return.

Effect sequencing belongs in an explicit <code>do</code> term.

## Native do

Two canonical presentations remain distinct and explicit:

~~~proofscript
do
  action1
  action2
~~~

and a compact/native brace sequence where separators are explicit:

~~~proofscript
do { action1; action2; }
~~~

The Standard formatter SHOULD avoid a brace-delimited <code>do</code> body whose outer element boundaries depend only on indentation. This is a formatting/profile restriction, not a change to native Lean do semantics.
## Tactics

Native proof syntax remains:

~~~proofscript
by
  constructor
  · exact left
  · exact right
~~~

or explicitly separated brace form:

~~~proofscript
by { constructor; exact left; exact right }
~~~

The native all-goals combinator is not a separator:

~~~proofscript
by { constructor <;> trivial }
~~~

r3 does not normalize <code>;</code> and <code>&lt;;&gt;</code> into one another.

## Parser algorithm

An owned brace parser maintains:
- the matching delimiter;
- current nested delimiter depth;
- the outer sequence's separator/marker rule;
- child-category parser state;
- source positions.

It does **not** split source lines and does **not** infer members from indentation.

For a field body, a comma closes the current field only at outer brace depth. For a match/inductive body, a <code>|</code> starts a new member only at outer brace depth and in the corresponding member-start state. For instance/where bodies, semicolon separators are interpreted only at outer brace depth.

## Formatter

The Standard formatter:
- uses two-space indentation as presentation only inside owned braces;
- emits commas **between** structure/class fields and never emits a trailing field comma;
- emits one constructor/alternative per line;
- emits semicolons for multiline owned instance/where brace bodies because those separators are grammatical;
- does not add a semicolon after the closing brace of a declaration;
- preserves nested native layout or rewrites it only through a defined AST normalization.
## Migration from r2

Migration parses r2 first.

- r2 braced structure/class fields are emitted with commas **between** fields and no trailing field comma.
- r2 match and inductive members keep their marker tokens; no new separator is needed.
- r2 instance/where member sequences receive explicit native semicolons where the old AST contains more than one member and no separator was present in source.
- nested native <code>do</code>/tactic syntax is preserved according to its AST.
- comments remain attached to the owning member/source span.

A global "insert comma at every newline" transform is invalid.

## Diagnostics

Proposed codes:
- <code>PS_BRACE_FIELD_COMMA_REQUIRED</code>;
- <code>PS_BRACE_UNEXPECTED_SEPARATOR</code>;
- <code>PS_BRACE_MEMBER_MARKER_REQUIRED</code>;
- <code>PS_BRACE_INSTANCE_SEMICOLON_REQUIRED</code>;
- <code>PS_BRACE_WHERE_SEMICOLON_REQUIRED</code>;
- <code>PS_BRACE_UNTERMINATED</code>;
- <code>PS_BRACE_NESTED_LAYOUT</code> for a child-native layout failure reported with the original nested category.

## Effects on targets

The change is surface-only. Lowered native syntax/Core and RuntimeIR should be identical to the corresponding r2/native program.

A backend must therefore not observe brace style.

## Evidence required before freeze

1. parser prototype with arbitrary reindentation of owned brace members;
2. formatter round-trip property;
3. nested delimiter/comment corpus;
4. native lowering comparison;
5. migration corpus;
6. usability comparison of r2 hybrid braces, r3 explicit braces, and Lean layout.

Current status: **accepted r3 design rule; implementation/testing evidence remains future work**.