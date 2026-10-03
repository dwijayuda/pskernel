# r3 Parenthesized Call Design

Status: **accepted r3 breaking grammar design; documentation/specification only; not implemented**

## Decision

Replace r2 adjacency-sensitive <code>D-CALL</code> with an r3 parenthesized-call surface exception:

~~~proofscript
f(x)
f (x)
~~~

have the same <code>.ps</code> meaning.

Likewise:

~~~proofscript
f(x, y)
f (x, y)
~~~

both denote two curried native arguments.

One tuple argument is written explicitly:

~~~proofscript
f((x, y))
f ((x, y))
~~~

Native <code>.lean</code> syntax and parsing are unchanged.

Because this intentionally reinterprets a valid Lean neighbor in <code>.ps</code>, r3 should no longer classify the feature as a conservative D-class decoration. The proposed feature ID is <code>E-CALL-PARENS-R3</code>.

## Why change r2

r2 distinguishes <code>f(x,y)</code> from <code>f (x,y)</code>. The rule is precise but creates a high-risk false familiarity for TypeScript/JavaScript developers, formatters, refactoring tools, and code-generating agents.

Lean itself is coherent because ordinary application is consistently juxtaposition and all core functions are unary/curried. The r3 proposal is coherent in a different way: parentheses in the owned call form consistently denote an argument list, while explicit nested parentheses denote a product term.

This is a source-compatibility cost, not a change to core function semantics.
## Research comparison

| Alternative | Learnability | Lean compatibility inside .ps | Tooling | Decision |
|---|---|---|---|---|
| r2 adjacency-sensitive call | surprising for TS developers | preserves <code>f (x,y)</code> tuple neighbor | formatter must preserve trivia ownership | reject for r3 |
| r3 trivia-insensitive parenthesized call | familiar, explicit tuple grouping | intentionally reinterprets parenthesized native neighbor | simplest standard formatter | **accepted for r3** |
| native Lean application only | least overlay complexity | maximal | excellent after Lean learning | keep available as inherited non-parenthesized application |
| make all calls JS-like and remove native application | familiar but too invasive | poor | simpler grammar, larger migration | reject |

The r3 call rule is an E-class exception because the surface cost is visible and versioned.

## Ownership grammar

Conceptual grammar:

~~~ebnf
PSTerm ::= ParenthesizedCall | Lift<NativeTerm>

ParenthesizedCall ::=
    CallableHead CallTrivia "(" CallArguments? ")"

CallArguments ::=
    CallArgument ("," CallArgument)* ","?

CallArgument ::=
    NativeIdent ":=" PSTerm
  | PSTerm
~~~

<code>CallableHead</code> is a completed term head admitted by the profile: identifiers, contextual constructors, projections/generalized-field heads, parenthesized heads, and completed calls.

The parser does not delete whitespace and then reparse text. It records the source trivia and chooses ownership structurally.
## Call trivia and line boundaries

The accepted r3 `CallGap` is deliberately **horizontal**.

It permits inherited horizontal Lean space trivia (ordinary spaces under the pinned lexer) and Lean comments treated as lexical trivia nodes. A bare source line terminator outside a comment breaks parenthesized-call ownership between the completed head and `(`.

Thus:

~~~proofscript
f(x)
f (x)
f/- comment -/(x)
~~~

are the same call form, while:

~~~proofscript
f
(x)
~~~

is not one r3 parenthesized call.

A block comment is an atomic trivia node for call ownership; physical line breaks inside the comment do not create a bare line terminator between the head and `(`.

Multiline calls remain available after the opening parenthesis:

~~~proofscript
f(
  x,
  y,
)
~~~

This removes the previous parser-state ambiguity around crossing `do`, tactic, local-declaration, match-alternative, or other sequence boundaries. It is not automatic semicolon insertion.

## Canonical lowering

~~~text
Call(h, [])                 -> native application h ()
Call(h, [a])                -> native application h a
Call(h, [a,b,...])          -> one native application syntax object with ordered arguments
Named(name,e)               -> native named argument (name := e)
TupleArg(a,b)               -> ordinary tuple term used as one call argument
~~~

The elaborator receives one native application object so implicit arguments, defaults, named arguments, expected types, partial application, and instance synthesis retain native behavior.

Do not lower each source argument independently and then reconstruct an application from inferred target types.
## Examples

~~~proofscript
function add(x: Nat, y: Nat): Nat := x + y

const a: Nat := add(1, 2)
const b: Nat := add (1, 2)

function tupled(pair: Nat × Nat): Nat := pair.1 + pair.2

const c: Nat := tupled((1, 2))
const d: Nat := tupled ((1, 2))
~~~

Both <code>a</code> and <code>b</code> lower to the same native two-argument application. Both <code>c</code> and <code>d</code> lower to an application with one product argument.

Nested calls preserve grouping:

~~~proofscript
f(x)(y)
g(f(x), h(y))
~~~

The first lowers as two application groups. The second lowers to a two-argument application whose arguments are separately lowered calls.

## Generalized field notation

r3 changes spacing around the **call parenthesis**, not spacing around Lean field notation.

~~~proofscript
users.map(render)    -- allowed
users .map(render)   -- not added by r3
~~~

The dot retains Lean's native adjacency requirement. The completed head `users.map` is then called through r3 parenthesized-call syntax.

Lowering constructs native generalized-field application syntax and lets the compatible elaborator determine receiver placement; it does not hard-code `users` as the first explicit parameter.

## Constructors

Constructor terms may use the call form where contextual constructor resolution is supported:

~~~proofscript
.some(value)
.ready(id, value)
~~~

Patterns stay native:

~~~proofscript
| .some value => ...
~~~

<code>.some(value)</code> is not an r3 pattern production.
## Named and default arguments

Named syntax remains:

~~~proofscript
connect(host, timeout := 5000)
~~~

It lowers to the native named-argument node and therefore retains native parameter-name matching.

The r3 parser rejects:
- duplicate named keys in one call;
- <code>name: value</code> as a named-argument spelling;
- empty entries;
- doubled commas.

A trailing comma in a nonempty owned call remains allowed.

Missing explicit parameters retain native partial-application/default behavior. The implementation must not substitute JavaScript <code>undefined</code>.

## Empty calls, Unit, and defaults

r3 distinguishes:

~~~proofscript
f()
f(())
~~~

`f()` means **zero source-supplied explicit arguments**.

Its canonical native high-level application request is:

~~~lean
f ..
~~~

The pinned Lean application elaborator inserts implicit, instance, optional/default, and automatic parameters. r3 then applies an additional acceptance rule:

- every omitted explicit parameter must be backed by native `optParam` or `autoParam`;
- an ordinary required explicit parameter may not be satisfied merely because native ellipsis created a metavariable;
- unresolved metavariables remain rejection conditions.

The zero-source-argument declaration sugar:

~~~proofscript
function now(): Time := ...
~~~

lowers to:

~~~lean
def now (_ : Unit := ()) : Time := ...
~~~

so `now()` can use the hidden default Unit through the same empty-call/default-completion mechanism.

Default-only functions therefore behave naturally:

~~~proofscript
function greet(name: String := "world"): String := ...
greet()                       -- native default is inserted
~~~

Required parameters do not disappear:

~~~proofscript
function add(x: Nat): Nat := x + 1
add()                         -- PS_EMPTY_CALL_REQUIRED_ARGUMENT
~~~

`f(())` is an ordinary nonempty call containing one explicit Unit term.

To obtain a function value or partial application, use the function value or an ordinary nonempty/native application form rather than relying on `f()`.

This resolves the default-parameter false friend without introducing JavaScript `undefined` semantics.

## Imported syntax and quotations

<code>ps-standard</code> has a closed syntax environment, so third-party syntax cannot steal the reserved call form.

<code>ps-lean-extensible</code> may import syntax, but the r3 call reservation remains part of the edition. A syntax extension that conflicts with the reserved callable-head + parenthesis region is incompatible unless an explicitly versioned profile defines the interaction.

Quoted syntax is parsed in its quoted category. The frontend must not recursively reinterpret arbitrary quoted text as r3 calls.
## Formatter

Canonical r3 formatting always prints owned calls without a space before the opening parenthesis:

~~~proofscript
f(x)
f(x, y)
f((x, y))
~~~

This formatting choice no longer carries semantic information; adding permitted horizontal Lean trivia before the parenthesis does not change the AST. Tabs are not introduced as a new r3 whitespace token.

Tuple intent is structural and remains visible through the extra grouping.

## Migration from r2

Migration MUST parse the old grammar first.

Given an r2 AST:

- an r2 D-CALL stays an r3 call;
- a native r2 application <code>f (x)</code> can become <code>f(x)</code>;
- a native r2 tuple application <code>f (x, y)</code> MUST become <code>f((x, y))</code>;
- comments and source mappings are moved structurally, not deleted;
- a failed old parse is not guessed into r3 source.

A source formatter is not the migrator.

## Diagnostics

Proposed diagnostics:

- <code>PS_R3_CALL_AMBIGUOUS_EXTENSION</code> — an imported extension conflicts with the reserved call region;
- <code>PS_CALL_EMPTY_ENTRY</code> — doubled/leading comma;
- <code>PS_CALL_DUPLICATE_NAMED_ARGUMENT</code>;
- <code>PS_CALL_TUPLE_MIGRATION_REQUIRED</code> — edition mismatch detects old tuple intent;
- <code>PS_CALL_LINE_BREAK_BEFORE_PAREN</code> — recovery diagnostic when a line break cannot continue the current expression.

## Evidence required before freeze

1. parser ownership tests for ordinary/head/projection/constructor/nested calls;
2. old-edition migration corpus;
3. native lowering comparison;
4. formatter AST round trips;
5. interactions with <code>do</code>, tactics, quotations, macros, defaults, named arguments, and partial application;
6. TypeScript-developer comprehension experiment.

Current status: **accepted r3 design rule**. Exact normative grammar is in `R3-GRAMMAR-AND-FEATURE-REGISTRY.md`. No production parser is claimed.