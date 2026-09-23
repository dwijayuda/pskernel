# ProofScript language completion plan

Status: **active anti-drift execution plan**

Goal:

> Build a small, coherent general-purpose language for the JavaScript
> ecosystem with Lean-compatible dependent types, theorem proving, and formal
> verification, while keeping the ordinary programming surface closer to Go
> than to full Lean or full TypeScript.

This plan is subordinate to `docs/PROOFSCRIPT_ARCHITECTURE.md`. If a task
conflicts with the canonical checked-core architecture, the architecture wins.

## Canonical completion definition

ProofScript is not considered the intended language merely because syntax
parses or TypeScript emits. A language feature is complete only when the
relevant path is executable:

```text
source
-> syntax / names
-> Lean-compatible Meta / Elab
-> pskernel admission
-> CheckedCoreModule
-> semantics-preserving erasure
-> verified compiler IR
-> TypeScript
-> tsc
-> JavaScript
```

Proof-only features stop after pskernel admission. Runtime features must also
pass the erasure/compiler/backend path.

## Current baseline

Already implemented on the preferred verified path:

- primitive Nat/Int/Bool/String/Unit representation;
- generic functions and higher-order functions;
- checked Nat arithmetic including total / and %, bounded Nat/Bool equality,
  Nat order comparison, Bool logic, and checked Bool/ordering if conditions;
- lambdas and lets;
- structures, parameterized structures, record construction, projection;
- inductives, generic inductives, constructors, checked pattern matching;
- direct positive recursive ADTs;
- bounded structural recursion, including invariant runtime parameters;
- generic recursive list/map/length-style programs;
- theorem proof terms and bounded tactics: exact, assumption, intro, and
  single-premise apply;
- class declarations as kernel-checked structure-like declarations;
- local instance synthesis;
- bounded global instance registration/synthesis;
- checked-core proof/type erasure;
- verified compiler IR -> TypeScript -> JavaScript/.d.ts/source map;
- psc check/build/run --verified with primitive plus strict JSON structure/ADT
  runtime ABI shapes;
- proof-aware LSP/VS Code dogfood tooling.

The legacy `@proofscript/language` software checker remains transitional and
must not receive new foundational semantics.

Execution-evidence note (2026-09-23): current GitHub Actions push jobs are
failing before any job step is created (`steps: null`). The source regressions
for the latest equality/apply/instance-search changes are therefore committed
but do not count as executed root-gate evidence until `npm run check` (or an
equivalent executing CI run) completes.

## Milestone L1 — verified language core closure

Purpose: make the verified path the only place new ordinary language semantics
are added.

Remaining acceptance gates:

- direct calls between generic functions and higher-order functions;
- nested lets/lambdas/if/match combinations;
- richer primitive comparison/equality coverage through Lean-compatible
  elaboration, not backend-only operators;
- broaden the landed typed/exhaustive intrinsic contract only when new
  verified runtime primitives are introduced;
- broaden the landed deterministic JSON structure/ADT run ABI only when new
  checked runtime shapes are added;
- source-level regressions for every supported construct.

Exit condition:

- the verified path covers the small pure core needed to implement its own
  standard data libraries;
- no new tests are added only to the legacy software checker for these
  constructs.

## Milestone L2 — data, recursion, and dependent ADT closure

Purpose: make ProofScript adequate for nontrivial verified libraries.

Implement, in this order:

1. indexed/dependent inductive application in elaboration and erasure;
2. constructor/match coverage for indexed families;
3. multiple structural recursive parameters where Lean's termination theory
   justifies them;
4. mutual inductive declarations;
5. mutual recursive definitions;
6. recursive local `where` groups;
7. bounded well-founded recursion only after the structural path is solid.

Lean rule:

- positivity, recursor generation, dependent elimination, and recursive
  admissibility remain pskernel/Lean-theory responsibilities;
- frontend code may recognize source shape but must not duplicate weaker
  acceptance rules.

Exit condition:

- representative Option/Result/List/Tree/Vec-style libraries compile through
  checked core and execute in JavaScript.

## Milestone L3 — Meta/Elab convergence for the ProofScript subset

Purpose: eliminate ad-hoc elaboration special cases.

Implement:

- universe metavariables and constraints;
- higher-order pattern unification required by the chosen surface subset;
- postponed constraints;
- transparency-sensitive Meta reduction where required;
- coercion insertion only with explicit Lean-compatible semantics;
- proper instance search with priorities, recursion control, outParam /
  semiOutParam behavior as needed by the chosen subset;
- imported instance indexes.

Do not attempt to reproduce every Lean convenience. Implement only machinery
required by the intentionally small ProofScript language and libraries.

Exit condition:

- generic/dependent APIs do not require syntax-specific elaborator hacks;
- typeclass-driven library code is predictable and kernel-rechecked.

## Milestone L4 — theorem prover v1

Purpose: make formal verification pleasant enough for real software specs.

Tactic order:

1. broaden the landed bounded single-premise apply only when multi-goal
   machinery justifies it;
2. refine;
3. constructor;
4. cases;
5. induction;
6. rewrite;
7. simp with a small explicit theorem set;
8. exact? / assumption-style search only after deterministic core tactics;
9. structured multi-goal state and cursor-sensitive LSP proof state.

Every tactic must construct an ordinary core proof term. Tactics and LSP goal
state never become proof authorities.

Exit condition:

- representative data-structure invariants and function-correctness theorems
  can be written without manually constructing proof terms.

## Milestone L5 — modules, projects, and npm interoperability

Purpose: make the language useful for real JavaScript projects.

Implement:

- ProofScript module/import graph with deterministic project builds;
- package manifests/configuration integrated with `psc`;
- npm package resolution for runtime dependencies;
- explicit `extern`/FFI declarations with a checked boundary;
- generated or authored bindings for TypeScript/JavaScript libraries;
- import/export mapping to ESM first;
- source maps that remain useful through verified emission.

Interop rule:

- JavaScript/TypeScript libraries are trusted runtime dependencies, not proof
  evidence;
- external declarations state assumptions explicitly;
- verified ProofScript code may prove properties about models/specifications,
  but pskernel must never trust JavaScript execution as a proof oracle.

Exit condition:

- a small Node application can use at least one normal npm package while its
  internal pure logic remains verified ProofScript.

## Milestone L6 — controlled effects for general-purpose JS

Purpose: move from pure verified libraries to applications.

Start deliberately small:

- IO capability boundary;
- errors/results;
- Promise/async interoperability;
- mutable references/arrays only with explicit semantics;
- JS callbacks;
- browser/Node host APIs through FFI.

Avoid copying TypeScript's entire object/effect model.

Exit condition:

- command-line and small web/service programs can be authored primarily in
  ProofScript while keeping pure verified logic separate from effectful host
  code.

## Milestone L7 — standard library and ecosystem

Build libraries in ProofScript itself where practical:

- Option / Result;
- List / Array-facing adapters;
- Map / Set-facing verified abstractions;
- String utilities;
- numeric helpers;
- JSON model/codec layer;
- assertions/spec helpers;
- theorem libraries for common ADTs.

Prefer npm packages for libraries outside the foundational standard library.

Exit condition:

- ordinary users can write useful programs without importing Lean internals.

## Milestone L8 — legacy path retirement

Retire the legacy software checker only after verified-core regressions cover
its useful behavior.

Required before deletion:

- feature-by-feature migration matrix;
- psc verified path is the default;
- old path is behind an explicit legacy flag for one transition period;
- no package outside legacy tests depends on `@proofscript/language` for
  semantic checking;
- architecture gate prevents reintroduction.

## Milestone L9 — production hardening

- deterministic incremental builds;
- package cache;
- diagnostic stability;
- LSP incremental analysis;
- formatter;
- source maps;
- performance budgets;
- fuzz/property tests for parser/elaborator/erasure;
- differential Lean tests for all semantic additions;
- npm publication layout;
- versioned language specification and compatibility policy.

## Anti-drift rules

These are mandatory for all future development.

1. Repository HEAD is source of truth; re-read before editing.
2. Never add a runtime language feature only in the legacy software checker.
3. Never add a backend special case for syntax that was not first admitted by
   Lean-compatible elaboration/pskernel.
4. Never weaken Meta/Elab/kernel checks to make JS compilation pass.
5. Every executable language feature needs a source-level end-to-end gate:
   source -> checked core -> verified IR -> TS -> JS.
6. Every proof feature needs a kernel-admission regression.
7. Every Lean-sensitive semantic change should be checked against pinned Lean
   4.34 source/behavior where practical.
8. Unsupported cases fail closed with a specific diagnostic.
9. Keep trusted and untrusted layers explicit. Compiler, LSP, editor, tactics,
   erasure, and backends do not gain proof authority.
10. Keep files/modules bounded; split by semantic responsibility before they
    become multi-purpose dispatchers.
11. No new syntax merely for convenience unless its ownership and canonical
    Lean meaning are specified.
12. Do not claim full Lean compatibility, formal equivalence, or 100%
    completion until the corresponding kernel gates are actually closed.
13. CI results count only when jobs execute real steps; a `steps: null`
    failure is infrastructure evidence, not semantic pass/fail evidence.
14. Prefer deleting transitional duplication after verified-core coverage
    catches up instead of maintaining two implementations indefinitely.

## Immediate execution queue

Do not reorder without repository evidence.

1. Repair/obtain an executing CI or local root-gate run.
2. Continue verified primitive/equality/comparison semantics beyond the landed
   Nat +,-,*,/,%, Nat/Bool ==/!=, and Bool !/&&/|| paths only where
   Lean-compatible meaning is explicit.
3. Extend the landed postponed global-instance lookup toward parameterized
   instances/priorities only as ProofScript libraries require them.
4. Continue theorem prover v1 with refine/constructor/cases; broaden apply only
   with an explicit multi-goal model.
5. Implement project/module/import semantics on the checked-core path.
6. Design and implement explicit npm/JS FFI.
7. Start the ProofScript-written standard library.
8. Expand recursion/dependent ADTs only with pskernel-backed theory gates.
9. Make verified mode default once feature coverage surpasses the legacy lane.
10. Retire the legacy software checker.

## Progress reporting format

Every development report should state:

- current HEAD;
- commits made;
- exact feature/gate added;
- what pskernel/Lean semantic rule is relied on;
- tests/gates actually executed;
- tests not executed and why;
- unsupported cases kept fail-closed;
- next smallest milestone.

Do not report invented completion percentages.
