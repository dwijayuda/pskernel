# Eloquent JavaScript Study for Eloquent ProofScript PSC1

This document records the documentation-design study used to create
`eloquent-proofscript/`.

Primary external source: *Eloquent JavaScript, 4th edition* by Marijn Haverbeke,
studied from the user-provided edition corresponding to
`eloquentjavascript.net`.

Repository sources were cross-checked against the existing PSC1 language,
stdlib, self-host plans, TypeScript study, Lean programming study, theorem
prover study, and language manual.

The new PSC1 text is original. It borrows **pedagogical structure and problem
selection**, not JavaScript semantics or book prose.

## 1. Why Eloquent JavaScript is useful to PSC1

The strongest lesson is not JavaScript syntax.

It is the book's progression from tiny ideas to real programs:

```text
values
-> program structure
-> functions
-> data structures
-> higher-order abstractions
-> project
-> errors/debugging
-> text processing
-> modules
-> effects/asynchrony
-> project: a programming language
```

This sequence teaches abstraction only after the reader has felt the repetition
that abstraction removes.

It also inserts substantial projects before the reader has "finished learning
the language." That is valuable for PSC1 because ProofScript should feel like a
programming language, not merely a formal-methods manual.

## 2. Project-driven structure

The book uses multiple project chapters to make concepts interact.

PSC1 adopts this pattern with projects chosen for PSC1's semantics:

Eloquent JavaScript idea | PSC1 adaptation
--- | ---
delivery robot / persistent simulation | persistent delivery planner
programming-language project | tiny typed language
browser/application projects | omitted from PSC1 core book
large environment-specific programs | tiny compiler pipeline

The projects emphasize:

- persistent data;
- recursive algorithms;
- typed failure;
- parsing and ASTs;
- checking before execution;
- proof opportunities;
- compiler-stage separation.

## 3. Values, types, and operators

JavaScript begins from raw runtime values and explains its dynamic operators.

PSC1 uses the same beginner-friendly entry point but immediately teaches its
semantic distinctions:

```text
Nat / Int
fixed-width integers
Float / Float32
Bool
Char / String
Unit
```

and:

```text
:=  binding/definition
=   propositional equality
==  Bool equality
```

JavaScript's implicit conversion story is deliberately *not* copied.

PSC1 should fail when a meaning is ambiguous rather than silently coerce values
according to host-language rules.

## 4. Program structure

Eloquent JavaScript moves from expressions to statements, bindings, conditionals
and loops.

PSC1 instead teaches:

- definitions;
- lexical `let`;
- expression-valued `if`;
- algebraic `match`;
- recursion and library traversal.

The book's general lesson—give values a larger program structure—is retained,
while unrestricted imperative statements are not invented for PSC1 merely to
match JavaScript.

## 5. Functions

The JavaScript book treats functions as the central tool for structuring larger
programs, reducing repetition, and isolating subprograms.

PSC1 keeps that emphasis.

The PSC1 version covers:

- named functions;
- lambdas;
- function types;
- functions as values;
- closures;
- higher-order functions;
- recursion;
- pure-vs-effectful boundaries.

It explicitly avoids importing JavaScript function semantics such as dynamic
`this`, prototypes, hoisting, or unrestricted early return.

## 6. Data structures

Eloquent JavaScript's object/array chapters teach the practical need to organize
data.

PSC1 maps that problem to its own mechanisms:

JavaScript | PSC1
--- | ---
objects | structures
tagged object conventions | inductives
missing property/null-ish state | Option
throw/error sentinel | Result
arrays | Array
Map/Set | ordered PSC1 map/set abstractions
mutation | persistent values by default semantic model

The lesson remains "choose a data representation that makes the program easy to
understand," but the representation discipline is different.

## 7. Higher-order abstraction

The higher-order-functions chapter is especially relevant to PSC1.

Its core pedagogical idea is that a program should describe the problem using a
vocabulary such as map/fold/filter-style operations rather than repeatedly
spelling low-level traversal mechanics.

PSC1 turns this directly into a language-design rule:

> libraries before syntax.

The current PSC1 stdlib already dogfoods higher-order operations including
`listMap`, `arrayMap`, `arrayFoldl`, `arrayAny`, `arrayAll`,
`optionBind`, and `resultBind`.

## 8. Objects versus PSC1 abstraction

The JavaScript book has an important object-oriented chapter because prototypes,
classes, methods, inheritance, symbols, and iteration are central to JavaScript.

PSC1 must **not** copy this language model.

Its equivalent chapter is "Abstraction with Data and Typeclasses":

- structures for product data;
- inductives for alternatives;
- functions/modules for behavior;
- typeclasses for type-directed evidence;
- dependent fields/proofs for invariants.

PSC1 `class` remains a Lean-compatible typeclass, not an OOP class.

## 9. Bugs and errors

Eloquent JavaScript highlights how permissiveness can let nonsense flow deep
into a program before failure.

PSC1's adaptation emphasizes prevention layers:

```text
parser rejection
-> type errors
-> explicit Option/Result
-> proof obligations
-> tests
-> backend/conformance gates
```

This is one area where PSC1 should intentionally feel stricter.

Static checking and theorem proving do not eliminate testing. They move many
failures earlier and let selected properties be stated universally.

## 10. Text processing

The JavaScript book teaches text processing heavily through regular expressions.

PSC1 needs text processing primarily to self-host a compiler.

The PSC1 version therefore emphasizes:

- Char/String;
- source spans;
- tokens;
- recursive parsing;
- explicit parser errors;
- fixed precedence;
- lexical ownership.

Regex is treated as a possible library, not a required language feature.

## 11. Modules and packages

The JavaScript book's module/package chapter is highly relevant because PSC1
intentionally lives in the npm ecosystem.

PSC1 adapts it to:

- deterministic logical module names;
- `.ps` / bounded `.lean` source resolution;
- source roots;
- ambiguity rejection;
- `package.json` versus `psconfig.json`;
- npm package reuse;
- exact runtime dependency policy;
- proof/conformance metadata separate from package versioning.

## 12. Asynchrony versus effects

JavaScript's asynchronous-programming story is inseparable from callbacks,
Promises, `async`/`await`, generators, and its event loop.

PSC1 does not copy this as source semantics.

The analogous first-freeze topic is explicit effects:

- reader/context;
- state;
- typed error;
- `pure`;
- `bind`;
- `do`;
- rollback;
- host capabilities.

A future async/task model should be specified backend-neutrally before becoming
part of the language.

## 13. The programming-language project

The book's small-language project is exceptionally relevant to ProofScript.

Its core lessons transfer directly:

- syntax is data;
- a parser turns text into a tree;
- recursive grammar suggests recursive parsing;
- evaluation is a separate stage;
- environments give names meaning;
- language implementation is ordinary programming.

PSC1 extends this teaching project with:

- algebraic ASTs instead of string-tagged JS objects;
- typed Result errors;
- a separate static checker;
- source spans;
- preservation-style proof opportunities.

This leads naturally into the final "tiny compiler pipeline" project.

## 14. Browser and Node chapters

The later Eloquent JavaScript chapters are intentionally environment-specific:
DOM, events, canvas, HTTP/forms, Node filesystem/server APIs, and complete web
projects.

Those are not PSC1 core-language chapters.

The transferable lesson is to distinguish:

```text
language
from
host environment
```

PSC1 expresses that distinction through explicit host capabilities and FFI.

A future "ProofScript on the Web" or "ProofScript on Node/WASI" book can cover
specific environments without redefining PSC1 semantics.

## 15. Exercises

Almost every Eloquent JavaScript concept chapter ends with exercises.

The new PSC1 book does the same.

The exercise design rules are:

- require small code changes, not rote recall;
- make the reader choose a data/error abstraction;
- include explanation questions about semantics;
- introduce a proof only after an executable property is understood;
- keep full solutions separate from hints.

`EXERCISE_HINTS.md` gives direction without replacing the work.

## 16. What was deliberately not imported

PSC1 does not gain these features because Eloquent JavaScript teaches them:

- implicit numeric/string/Bool conversion;
- null/undefined semantics;
- mutable global bindings as ordinary style;
- prototype chains;
- OOP class/inheritance semantics;
- `this`;
- property getters/setters;
- Symbols;
- JavaScript iterator protocol;
- exceptions as the portable error model;
- regex syntax as a language requirement;
- CommonJS semantics;
- Promise/event-loop semantics;
- browser DOM/event/canvas APIs;
- Node filesystem/HTTP APIs as source semantics.

Where those capabilities are useful, they belong in libraries, target packages,
or explicit host interfaces.

## 17. Resulting documentation position

The PSC1 documentation now has complementary learning paths:

```text
docs/                         onboarding
handbook/                     progressive general handbook
eloquent-proofscript/         example/project/exercise-driven book
programming-in-proofscript/   Lean-functional-programming-inspired book
theorem-proving-in-proofscript/ proof-first book
language-manual/              lookup-oriented manual
reference/                    compact reference
```

The Eloquent-style book should be the most approachable path for a programmer
who wants to learn by writing increasingly substantial PSC1 programs.
