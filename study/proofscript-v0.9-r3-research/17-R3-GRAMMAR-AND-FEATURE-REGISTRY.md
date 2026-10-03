# r3 Exact Grammar and Feature Registry

Status: **normative for `ps-0.9-r3`**

This document replaces the abbreviated grammar prose in the integrated r3 reference.

## 1. Grammar notation

- `Native<C>` means the exact pinned Lean 4.34 parser/category `C`.
- `Lift<C>` means that exact native production with only explicitly registered child slots replaced by ProofScript-aware parsers.
- `CallGap` is defined below.
- `? * +` have ordinary EBNF multiplicity meaning.
- Rule-final semicolons in grammar blocks are EBNF punctuation, not source tokens.
- Semantic predicates listed after a production are mandatory.

The parser ownership order remains:

~~~text
1. matching r3 E-class production
2. matching retained D-class production
3. permitted native production for the selected profile
4. committed diagnostic / unsupported-feature
~~~

Once an owned discriminator commits, malformed owned syntax does not silently fall back to another grammar.

## 2. Top-level grammar

~~~ebnf
PSFile ::= Lift<ProfileCommandSequence> EOF ;

PSCommand ::=
    ConstDecl
  | FunctionDecl
  | DecoratedDef
  | BracedStructure
  | BracedClass
  | BracedInductive
  | BracedInstance
  | Lift<PermittedNativeCommand> ;
~~~

The exact permitted native command set depends on `ps-standard` versus `ps-lean-extensible`.

## 3. Value declarations

~~~ebnf
ConstDecl ::=
  Native<DefModifiers> "const" Native<DeclId>
  ResultSpec? NativeContracts? OwnedValue ;

FunctionDecl ::=
  Native<DefModifiers> "function" Native<DeclId>
  ( OrdinaryFunctionHeader | ZeroArgFunctionHeader )
  ResultSpec? NativeContracts? OwnedValue ;

DecoratedDef ::=
  Native<DefModifiers> "def" Native<DeclId>
  Native<DeclarationBinder>*
  ResultSpec? NativeContracts? OwnedValue ;

OrdinaryFunctionHeader ::=
  FunctionBinder+ ;

FunctionBinder ::=
    ExplicitGroup
  | Native<NonExplicitDeclarationBinder> ;

ZeroArgFunctionHeader ::=
  Native<NonExplicitDeclarationBinder>* "(" ")" ;

ExplicitGroup ::=
  "(" ExplicitEntry ("," ExplicitEntry)* ","? ")" ;

ExplicitEntry ::=
  Native<BinderIdent> ":" PSTerm Native<DefaultSuffix>? ;

ResultSpec ::= ":" PSTerm ;

OwnedValue ::=
  ":=" PSDeclBody Native<TerminationSuffix>? WhereSuffix? ;

PSDeclBody ::= Lift<NativeDeclBody> ;

WhereSuffix ::=
    BracedWhere
  | Lift<NativeWhereDecls> ;
~~~

### 3.1 Declaration predicates

- `const` has no declaration binders.
- An ordinary `function` has at least one explicit group somewhere in its binder sequence.
- A zero-source-argument `function` uses `ZeroArgFunctionHeader`; its empty group cannot be mixed with ordinary explicit groups.
- Non-explicit implicit/strict-implicit/instance binders may precede the zero-arg group.
- Native `def` retains native binder rules and receives no hidden zero-arg behavior.

### 3.2 Zero-arg lowering

~~~proofscript
function now(): Time := body
~~~

lowers to a native definition whose hidden Unit parameter is **optional with default Unit**:

~~~lean
def now (_ : Unit := ()) : Time := body
~~~

This preserves a function value while allowing the r3 empty-call rule to invoke it with zero source arguments.

The optional-Unit marker is part of the high-level Lean function type. An explicit type ascription that erases the `optParam` information can also erase the zero-source-argument call convenience.

## 4. Parenthesized calls

### 4.1 Grammar

~~~ebnf
PSTerm ::=
    BracedIf
  | BracedMatch
  | ParenthesizedCall
  | Lift<PermittedNativeTerm> ;

ParenthesizedCall ::=
  CallableHead CallGap "(" CallArguments? ")" ;

CallArguments ::=
  CallArgument ("," CallArgument)* ","? ;

CallArgument ::=
    NamedCallArgument
  | PositionalCallArgument ;

NamedCallArgument ::=
  Native<Ident> ":=" PSTerm ;

PositionalCallArgument ::= PSTerm ;

CallableHead ::=
    Native<CompatibleCompletedHead>
  | "(" PSTerm ")"
  | ParenthesizedCall
  | NativeProjectionOfCompletedHead ;
~~~

### 4.2 Exact `CallGap`

`CallGap` contains zero or more:

- spaces;
- horizontal tabs;
- Lean comments, treated as lexical trivia nodes.

A **bare source line terminator outside a comment is not part of `CallGap`**.

Therefore:

~~~proofscript
f(x)
f (x)
f /- comment -/ (x)
~~~

are the same r3 call form.

But:

~~~proofscript
f
(x)
~~~

is **not** an r3 parenthesized call. The enclosing profile/native category decides whether it is valid for another reason; `ps-standard` SHOULD diagnose `PS_CALL_LINE_BREAK_BEFORE_PAREN` when the likely intent is a call.

A block comment is an atomic trivia node for call ownership; line breaks physically contained inside the comment do not create a bare line terminator between the head and `(`.

Canonical formatting emits no gap:

~~~proofscript
f(x)
~~~

This rule deliberately avoids JavaScript ASI/newline-continuation semantics and removes ambiguity with native `do`/layout sequence boundaries.

### 4.3 Nonempty call lowering

A nonempty call lowers to one native high-level application syntax object:

~~~text
Call(h,[a1,...,an]) ->
  NativeApplication(L(h), [LArg(a1),...,LArg(an)])
~~~

Named arguments lower to native named-argument nodes.

The frontend does not independently implement TypeScript overload/default dispatch.

### 4.4 Empty call semantics

An empty call:

~~~proofscript
f()
~~~

means:

> invoke `f` with **zero source-supplied explicit arguments**, completing only arguments that r3 permits to be omitted.

Its canonical Lean application request is:

~~~lean
f ..
~~~

using Lean's high-level application ellipsis, followed by the r3 acceptance predicate below.

Lean may insert implicit, instance, strict-implicit, optional, and automatic parameters according to the pinned application algorithm.

r3 then requires:

- every omitted **explicit** argument is backed by native `optParam` or `autoParam`;
- no ordinary required explicit parameter was filled merely because `..` created a metavariable;
- no unresolved metavariable remains in an accepted declaration.

If an ordinary required explicit parameter would be omitted, reject with:

~~~text
PS_EMPTY_CALL_REQUIRED_ARGUMENT
~~~

Thus:

~~~proofscript
function now(): Time := ...
now()
~~~

works because the hidden Unit parameter is `(_ : Unit := ())`.

And:

~~~proofscript
function greet(name: String := "world"): String := ...
greet()
~~~

uses the native default parameter.

But:

~~~proofscript
function add(x: Nat, y: Nat): Nat := x + y
add()
~~~

is rejected rather than inferring hidden values or creating a partial application.

To obtain a function value, write the head itself:

~~~proofscript
const plus: Nat -> Nat -> Nat := add
~~~

not `add()`.

### 4.5 Empty-call/default rationale

This resolves the false familiarity between:

~~~proofscript
function now(): Time := ...
function greet(name: String := "world"): String := ...
~~~

Both can be called with `()`, but for different high-level reasons:

- `now()` consumes its hidden optional Unit;
- `greet()` consumes its declared default.

No JavaScript `undefined` value is introduced.

## 5. Generalized field notation

r3 does **not** add whitespace-insensitive dot syntax.

The inherited rule remains:

~~~proofscript
users.map(render)
~~~

with the dot adjacent to the receiver.

This is not r3 field notation:

~~~proofscript
users .map(render)
~~~

unless some separately declared extensible-profile syntax owns it.

Receiver placement remains the pinned Lean generalized-field elaboration rule; the PSC frontend does not assume the receiver is the first explicit parameter.

## 6. Structural brace grammar

### 6.1 Structures

~~~ebnf
BracedStructure ::=
  Native<StructurePrefixAndHeader> "where" BracedStructBody
  Native<DerivingSuffix>? ;

BracedStructBody ::=
  "{" StructFieldList? "}" ;

StructFieldList ::=
  Lift<NativeStructField>
  ("," Lift<NativeStructField>)* ;
~~~

There is **no trailing field comma**.

A comma nested inside a field type/default/term does not end the outer field; only a comma at the owned struct-body delimiter depth separates fields.

Syntactically empty bodies are candidates only where the lowered native declaration is legal.

### 6.2 Classes

~~~ebnf
BracedClass ::=
  Native<ClassPrefixAndHeader> "where" BracedClassBody
  Native<DerivingSuffix>? ;

BracedClassBody ::=
  "{" ClassFieldList? "}" ;

ClassFieldList ::=
  Lift<NativeStructField>
  ("," Lift<NativeStructField>)* ;
~~~

No trailing field comma.

### 6.3 Inductives

~~~ebnf
BracedInductive ::=
  Native<InductivePrefixAndHeader> "where"
  "{" BracedConstructors "}"
  Native<InductiveSuffix>? ;

BracedConstructors ::=
  ( "|" Lift<NativeConstructorBody> )* ;
~~~

The leading `|` is the constructor boundary marker.

No comma/semicolon constructor terminator is added.

### 6.4 Matches

~~~ebnf
BracedMatch ::=
  Native<MatchPrefixAndDiscriminantsWithLiftedTerms>
  "with" "{" BracedMatchAlternatives "}" ;

BracedMatchAlternatives ::=
  BracedMatchAlternative+ ;

BracedMatchAlternative ::=
  "|" Native<PatternGroup> "=>" PSTerm ;
~~~

Patterns remain native.

The RHS is exactly one term; nested terms can themselves contain native/owned sequences.

### 6.5 Instances

~~~ebnf
BracedInstance ::=
  Native<InstancePrefixAndHeader> "where"
  "{" BracedInstanceFields? "}" ;

BracedInstanceFields ::=
  Lift<NativeStructInstField>
  (";" Lift<NativeStructInstField>)* ";"? ;
~~~

Semicolons here belong to the native instance-initializer sequence.

### 6.6 Local `where`

~~~ebnf
BracedWhere ::=
  "where" "{"
  Lift<NativeWhereLocalDecl>
  (";" Lift<NativeWhereLocalDecl>)* ";"?
  "}" ;
~~~

At least one local declaration is required.

Semicolons belong to the local-declaration sequence, not the outer definition.

### 6.7 Braced conditionals

~~~ebnf
BracedIf ::=
  "if" "(" PSTerm ")" "{" PSTerm "}"
  "else" "{" PSTerm "}" ;
~~~

Each branch is exactly one term.

No statement list and no implicit return are introduced.

### 6.8 Native `do` and tactics

Native `do` and tactic brace/layout syntax are inherited according to the selected profile.

The r3 structural-brace rule does not reinterpret their inner sequencing.

## 7. Trailing-comma policy

Trailing comma admission is category-specific.

Accepted:

~~~proofscript
f(x, y,)
function f(x: Nat, y: Nat,): Nat := ...
~~~

Not accepted:

~~~proofscript
structure S where {
  x: Nat,
  y: Nat,
}
~~~

The closing `}` terminates the field list.

## 8. Pattern boundary

`E-CALL-PARENS-R3` is term-only.

This remains a native pattern:

~~~proofscript
| .some x => ...
~~~

This is not an r3 pattern:

~~~proofscript
| .some(x) => ...
~~~

## 9. Diagnostics added/changed in r3

Normative r3 diagnostics include:

- `PS_CALL_LINE_BREAK_BEFORE_PAREN`;
- `PS_EMPTY_CALL_REQUIRED_ARGUMENT`;
- `PS_CALL_EMPTY_ENTRY`;
- `PS_CALL_DUPLICATE_NAMED_ARGUMENT`;
- `PS_CALL_TUPLE_MIGRATION_REQUIRED`;
- `PS_BRACE_FIELD_COMMA_REQUIRED`;
- `PS_BRACE_TRAILING_FIELD_COMMA`;
- `PS_BRACE_UNEXPECTED_SEPARATOR`;
- `PS_BRACE_MEMBER_MARKER_REQUIRED`;
- `PS_BRACE_INSTANCE_SEMICOLON_REQUIRED`;
- `PS_BRACE_WHERE_SEMICOLON_REQUIRED`;
- `PS_BRACE_UNTERMINATED`;
- inherited/native diagnostics for child-category failures.

The r2 diagnostic that rejects `function f()` is retired for r3.

## 10. Feature-ID migration

r3 feature identities are machine-readable in `r3-feature-registry.json`.

Key changes:

- `D-CALL` -> retired for r3 source;
- `E-CALL-PARENS-R3` -> new owned parenthesized call;
- `E-CALL-EMPTY-R3` -> empty-call/default-completion semantics;
- `E-ZERO-ARG-FUNCTION-R3` -> zero-source-argument declaration sugar;
- structure/class/match/inductive/instance/where body features receive r3 structural-boundary revisions.

## 11. Lowering/acceptance separation

Most r3 owned syntax lowers structurally before native elaboration.

Empty calls are special only in the following bounded sense:

1. syntax lowering emits the native high-level ellipsis application;
2. native elaboration performs its pinned argument insertion;
3. the r3 acceptance check rejects an application whose zero-source-argument call omitted a required explicit parameter.

The kernel remains unchanged.

## 12. Formatter obligations

The Standard formatter MUST:

- print owned calls with no gap before `(`;
- keep `f()` visually distinct from `f(())`;
- use extra grouping for one tuple argument;
- keep generalized-field dots adjacent;
- emit commas between structure/class fields and no trailing field comma;
- emit one constructor/match alternative per canonical multiline line;
- preserve native `;` versus `<;>`;
- never invent a general declaration semicolon;
- preserve source binding/category identity.

## 13. Migration obligations

An r2 migrator parses r2 first.

At minimum:

~~~text
r2 D-CALL f(x,y)       -> r3 f(x,y)
r2 native f (x,y)      -> r3 f((x,y))
r2 function f() error  -> may become valid only under r3
r2 brace field layout  -> r3 comma-separated outer fields
~~~

The migrator must preserve comments/source provenance and must not apply regex/global punctuation rewriting.
