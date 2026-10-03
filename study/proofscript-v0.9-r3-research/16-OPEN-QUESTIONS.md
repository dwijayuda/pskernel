# r3 Open Questions

Status: unresolved **implementation/evidence and pre-stable/1.0** questions. The r3 design baseline itself has been accepted.

1. Exact production parser rule for parenthesized-call continuation across newline boundaries.
2. Complete migration algorithm/source-map behavior for old r2 native tuple application in `.ps`.
3. Closed official notation/tactic set for `ps-standard`.
4. Canonical semantic-bundle format from Extensible to Standard.
5. Final concrete contract syntax for success/error/state outcomes beyond the accepted semantic model.
6. First partial/effectful program logic beyond total pure contracts.
7. Exact Lean-library representation of App/Fiber/Resource/Stream.
8. Failure-combination type for body plus cleanup failure.
9. Scheduler trace model and determinism guarantees.
10. Direct JS and WASI cancellation/resource mapping.
11. InterfaceIR serialized schema and versioning.
12. Limits for TypeScript overload/generic specialization.
13. Runtime validator/schema derivation library.
14. First real npm binding corpus.
15. First complete r3 PSC reference application.
16. Formal relation from the production parser AST to the planned call-overlay model.
17. Formal relation from production RuntimeIR/JsIR to the planned backend-preservation model.
18. ECMAScript subset semantics and printer/parser relation.
19. First direct-Wasm preservation theorem.
20. Human participant recruitment/results and whether those results justify any pre-1.0 revision, especially to `const`.

Resolved by r3 acceptance and therefore no longer open:
- the r3 grammar/design identity is `ps-0.9-r3`;
- parenthesized calls are whitespace/trivia-insensitive in `.ps` as specified;
- one tuple argument uses extra grouping;
- ProofScript-owned braces are structurally delimited at their outer member level;
- structure/class fields use commas only between fields, with no trailing field comma;
- braced r3 conditionals remain one-term branches rather than general statement blocks;
- `function f()` is Unit-function sugar;
- `const` is retained in r3, while remaining reviewable before stable/1.0;
- Standard versus Extensible profiles, PSC-owned contract semantics, the application-semantics direction, and InterfaceIR architecture are accepted.

No unresolved implementation/evidence item may be silently reported as completed merely because its design has been accepted.
