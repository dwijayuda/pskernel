# r3 TypeScript-Developer Usability Study

Status: protocol complete; human participant study NOT YET RUN.

## Research question

Can TypeScript developers correctly predict ProofScript syntax and semantics after a short tutorial, and does the r3 candidate reduce high-risk misunderstandings compared with r2 and native Lean?

Preference is secondary to semantic comprehension.

## Participants

Target at least:

- 18 TypeScript developers: 6 junior, 6 mid-level, 6 senior;
- 6 Lean users, ideally with mixed application/theorem experience.

Record prior experience with JS, TS, Rust/FP languages, theorem provers, and formal methods.

Do not recruit only project contributors.

## Conditions

Within/between-subject counterbalanced tasks compare:

A. v0.9-r2
B. r3 candidate
C. native Lean
D. TypeScript equivalent where meaningful

Randomize ordering to reduce learning effects.

## Training

Provide a 15-20 minute standardized tutorial covering:

- := versus =;
- function, def, provisional const;
- parenthesized calls and tuple grouping;
- fun lambdas;
- structures/matches;
- Option/Except;
- braces/layout;
- theorem/by;
- contract meaning versus runtime checks.

No hidden coaching during scored tasks.

## Core tasks

1. Read a two-argument function call.
2. Decide whether spacing changes call meaning.
3. Pass one tuple argument.
4. Read named/default parameters.
5. Write a zero-argument Unit function.
6. Explain top-level const.
7. Update a record.
8. Add a match constructor and repair exhaustiveness.
9. Handle Option instead of undefined/null.
10. Propagate a typed failure.
11. Read a Resource cleanup example.
12. Read cancellation/structured-concurrency outcome.
13. Consume an npm binding with a runtime validator.
14. Add a pre/post contract.
15. Interpret a failed proof obligation.
16. Review an AI patch that weakens a contract dependency.
17. Refactor a function signature and update callers.
18. Diagnose a syntax/profile error.

## High-risk comprehension questions

Especially measure:

- f(x) versus f (x);
- f((x,y)) versus f(x,y);
- braces versus indentation;
- whether const freezes data;
- whether function f() is zero-core-arity or Unit sugar;
- whether Option.none equals JS undefined;
- whether typed failure includes arbitrary JS throw;
- whether ensures is a runtime assertion;
- whether successful source proof implies backend correctness.

## Metrics

Record:

- task completion;
- semantic correctness;
- time;
- number of compiler/help lookups;
- parser/whitespace mistakes;
- annotations added;
- error-message comprehension;
- confidence from 1-5;
- preference after correctness questions.

Use confidence-versus-correctness calibration to find dangerous false familiarity.

## Pre-registered decision gates

### D-CALL

Adopt r3 only if it materially reduces call/tuple semantic errors compared with r2 and does not create serious new Lean-user ambiguity.

### Braces

Adopt structural r3 braces only if participants correctly identify outer member boundaries under arbitrary formatting at a substantially higher rate than r2 hybrid braces.

### const

Current provisional threshold: after tutorial, at least 80% of TypeScript participants must answer all tested const-semantic questions correctly and the design must not perform substantially worse than def-only presentation.

Otherwise remove/reconsider const before 1.0.

### function f()

Adopt unless the Unit-sugar model causes meaningful type/ABI confusion; test both reference-as-value and invocation.

## Raw-data schema

For each participant/task record:

~~~text
anonymousParticipantId
experienceBand
condition
taskId
start/end duration
answer
correct
confidence
helpRequests
errorCodesSeen
freeTextExplanation
~~~

Store no unnecessary identifying personal data.

## Analysis

Report:

- per-condition error rate;
- median/quantile completion time;
- confidence calibration;
- common misconception categories;
- subgroup caveats;
- missing/abandoned tasks.

Do not claim population-wide superiority from this convenience-sized study.

## Status

Protocol: complete.
Recruitment: not started.
Participants: 0.
Observed human results: none.
Language superiority claim: not made.
