# r3 Remaining Work

Status: **current source-language semantics are closed for ps-0.9-r3; remaining work is implementation, evidence, library/runtime API work, or future language evolution.**

The normative source-language authority is ProofScript_Language_Reference_v0.9.0_r3.md.

## Implementation and evidence work

1. Implement the exact ps-0.9-r3 parser/lowerer and validate it against the owned grammar.
2. Implement the complete psc2-language-v1 capability closure rather than discovering required language features one blocker at a time.
3. Enforce ps-standard-0.9-r3 registration closure and lean-subset-psc2-v1 fail-closed boundaries.
4. Complete the pure requires/ensures contract implementation and proof binding.
5. Implement the selected Standard prover surface without making tactic engines proof authorities.
6. Implement and validate the application library/runtime model described separately in 08-APPLICATION-EFFECTS-ASYNC-RESOURCES.md.
7. Implement InterfaceIR v1 import/export and its runtime validation/adaptation libraries.
8. Implement Semantic Bundle v1 import/recheck behavior.
9. Complete runtime/backend semantic-preservation and primitive-conformance work.
10. Build representative CLI, service, browser, npm, and theorem/library applications.
11. Complete the planned formal frontend/backend evidence.
12. Run the pre-stable usability study and revisit only spellings whose registered criteria justify a language revision.

None of these items changes the meaning of a current source construct merely because implementation work is incomplete.

## Future language work

Future syntax and semantic candidates are tracked only in:

~~~text
POST_PSC2_LANGUAGE_ROADMAP.md
~~~

Current candidates include:

- richer patterns and equation-style definitions;
- local mutation/loop sugar;
- stateful, loop, old/ghost, and async contract syntax;
- application-effect syntax such as async/await/using/defer;
- controlled new Standard extensions;
- possible UI dialects;
- larger explicitly bounded Lean compatibility profiles;
- possible systems-programming surface if concrete requirements justify it.

These candidates are not ps-0.9-r3 syntax.

## Closed design questions for this edition

The current edition has explicit rules for:

- parenthesized call ownership and CallGap;
- empty calls versus explicit Unit arguments;
- zero-source-argument function sugar;
- structural braces and category-specific separators;
- fixed Standard grammar;
- exact psc2-language-v1 language coverage;
- required basic do notation;
- exact psc2-pattern-v1;
- bounded lean-subset-psc2-v1;
- pure requires/ensures contracts;
- separation of compiler-core language from libraries, prover packages, extensions, host boundaries, and future language work.

A new source behavior requires a new explicit language/profile revision rather than an implementation-plan edit.
