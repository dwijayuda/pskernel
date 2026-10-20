# ProofScript Post-PSC2 Language Roadmap

**Status:** non-normative language-evolution roadmap

**Current language authority:** ProofScript_Language_Reference_v0.9.0_r3.md

This document contains only proposed future source-language evolution after psc2-language-v1. It intentionally excludes compiler implementation work, backend work, package/runtime implementation, InterfaceIR engineering, Meta-service implementation, release evidence, and self-host sequencing.

Nothing in this roadmap is current syntax until a separately versioned language/profile specification adopts it.

# 1. Design rule

A future feature should become language syntax only when ordinary libraries are insufficient or when repeated source ergonomics justify a stable surface form.

Use the following ownership order:

~~~text
ordinary library
-> fixed Standard prover/library facility
-> official syntax sugar over existing semantics
-> controlled extension profile
-> new language semantics only when genuinely necessary
~~~

Adding syntax must not enlarge the trusted logical theory unless the new feature genuinely requires a new logical construct and that change is separately specified.

# 2. L1 — richer matching and definitions

Candidates:

- multi-scrutinee match;
- pattern alternatives;
- record patterns;
- if let;
- let-pattern bindings;
- do-pattern bindings;
- equation-style function definitions.

Requirements:

- preserve the same inductive/elimination theory;
- preserve exhaustiveness/refutability rules;
- reject dependent matches whose motive cannot be represented exactly;
- do not require Lean equation-compiler parity as a prerequisite.

These are primarily syntax/elaboration conveniences over existing semantic machinery.

# 3. L2 — local imperative-looking ergonomics

Candidates:

- let mut;
- reassignment;
- for;
- while;
- break;
- continue.

Requirements:

- define semantics through explicit ProofScript state/effect/iteration abstractions;
- never inherit JavaScript mutation, aliasing, iterator, or early-return semantics by accident;
- keep pure ordinary functions pure;
- make reference identity/aliasing explicit if references are ever introduced.

The first version should prefer desugaring into existing library/effect constructs.

# 4. L3 — richer verification language

Candidates:

- verified assert;
- loop invariant;
- decreasing syntax;
- old/pre-state;
- ghost values;
- modifies/frame clauses;
- stateful postconditions;
- effectful postconditions;
- asynchronous/trace contracts.

Requirements:

- every successful proof claim reduces to an explicit proposition or program-logic judgment over the existing logical foundation;
- runtime checking and formal proof remain distinct;
- hidden host effects cannot satisfy proof obligations;
- state/trace models must be explicit and versioned.

The current requires/ensures pure-contract core remains the base semantic anchor.

# 5. L4 — application-effect syntax

Possible syntax over the separately specified application semantic model:

- async;
- await;
- using;
- defer;
- structured concurrency blocks;
- stream iteration/consumption forms.

Requirements:

- syntax must preserve the separately specified cold/start distinction;
- typed application errors remain distinct from unexpected runtime faults;
- cancellation semantics remain explicit;
- deterministic resource cleanup remains explicit;
- capabilities remain visible through the selected application semantics;
- target Promise/future/WASI mechanisms do not define source meaning.

This work should follow stable library semantics rather than precede them.

# 6. L5 — controlled source extensibility

Candidates:

- official deriving declarations;
- additional fixed notation families;
- versioned compile-time reflection forms;
- restricted official macro-like conveniences;
- schema/code-generation declarations.

Requirements:

- each ps-standard version remains a closed grammar;
- ordinary dependencies cannot mutate Standard parsing;
- new Standard registrations require a new explicit Standard profile/version;
- generated declarations remain ordinary declarations subject to normal logical checking.

Arbitrary Lean-style parser/elaborator extensibility remains an extensible-profile capability rather than a Standard default.

# 7. L6 — UI/application dialects

A future UI dialect such as .psx may be defined separately.

It must specify:

- a distinct grammar/profile identity;
- exact lowering to ordinary ProofScript constructs;
- component/value semantics;
- effect/resource/capability behavior;
- foreign/runtime assumptions;
- interaction with Standard imports and tooling.

JSX syntax alone is not sufficient to define such a dialect.

# 8. L7 — larger Lean compatibility profiles

Later Lean compatibility profiles may include selected additional native families such as:

- richer pattern/equation syntax;
- additional theorem commands;
- additional standard tactics;
- selected notation;
- selected Meta-facing authoring forms.

Each profile must be enumerated.

No future compatibility level should be inferred merely from a Lean version number.

# 9. L8 — systems-language surface, if demanded

Potential future systems-programming language work should be driven by concrete requirements rather than by Rust/C feature parity.

Candidates may include:

- explicit ownership/borrowing-style resource APIs or syntax;
- layout/ABI declarations;
- explicit pointer/reference capabilities;
- atomics/concurrency primitives;
- foreign-memory regions;
- target-feature declarations.

Any such feature must distinguish:

- logical value semantics;
- executable representation;
- foreign/unsafe assumptions;
- proof-valid code from runtime-only code.

Most systems facilities should remain libraries/FFI until a stable source construct is demonstrably necessary.

# 10. Adoption rule

A Post-PSC2 candidate becomes current language only when its proposal defines:

1. source grammar;
2. static semantics;
3. dynamic/logical semantics;
4. interaction with existing constructs;
5. rejection/ambiguity rules;
6. profile ownership;
7. canonical examples;
8. explicit non-goals.

Compiler architecture, backend strategy, test plans, release gates, and implementation schedules belong in other documents and are not part of the language proposal itself.
