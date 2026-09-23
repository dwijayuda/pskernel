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
- generic functions and higher-order functions, including direct generic
  higher-order calls on the verified path;
- checked Nat arithmetic including total / and %, bounded Nat/Bool equality,
  Nat order comparison, Bool logic, and checked Bool/ordering if conditions;
- lambdas and lets, with a source regression nesting let -> lambda(if) -> ADT
  match and local higher-order calls;
- structures, parameterized structures, record construction, projection;
- inductives, generic inductives, constructors, checked pattern matching;
- direct positive recursive ADTs;
- bounded structural recursion, including invariant runtime parameters;
- generic recursive list/map/length-style programs;
- theorem proof terms and bounded tactics: exact, assumption, intro, ordered
  explicit multi-premise apply, bounded refine with synthetic ?_ holes,
  bounded constructor via the same apply machinery, bounded cases, and
  bounded induction through pskernel-generated recursors;
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

- broaden generic/higher-order and nested expression composition only when new
  core expression forms are introduced;
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

1. theorem/result foundations now include named applications, explicit
   dependent Pi binders, Nat literals/arithmetic/relations, Bool primitive
   terms, and native propositional `=`. Add further expression forms only
   when a concrete specification requires them; do not expand syntax by
   analogy alone.
2. indexed/dependent inductive application in elaboration and erasure;
3. constructor/match coverage for indexed families;
4. multiple structural recursive parameters where Lean's termination theory
   justifies them;
5. mutual inductive declarations;
6. mutual recursive definitions;
7. recursive local `where` groups;
8. bounded well-founded recursion only after the structural path is solid.

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

1. establish the ordered multi-goal state foundation used by all tactics;
2. broaden the landed bounded single-premise apply on that state model;
3. refine;
4. constructor;
5. cases;
6. induction;
7. rewrite — bounded current-goal equality transport landed;
8. simp with a small explicit theorem set — bounded non-overlapping multi-rule simp-only sets landed;
9. exact? / assumption-style search only after deterministic core tactics;
10. add cursor-sensitive LSP proof-state snapshots on top of the same goal model.

The low-level multi-goal foundation follows Lean 4.34's separation: tactic state
tracks an ordered list of metavariable goals, while Meta owns metavariable
assignment and proof-term construction. In particular, Lean's `MVarId.apply`
assigns the parent goal and returns the remaining ordered subgoals. ProofScript
must preserve that split; tactic state must not accumulate an independent
`proofs[]` authority.

Current checkpoint: the source AST stores tactic blocks as ordered sequences and
the elaborator consumes the shared @proofscript/tactic goal state. Bounded
explicit `apply` may expose multiple ordered premise goals; solved premises
are assembled into one ordinary kernel proof term before declaration admission.
Implicit and instance binders remain fail-closed until their Meta synthesis
policy is implemented.

Bounded `refine` now admits Lean-style synthetic `?_` holes in the two
currently explicit shapes: the whole refinement term, or direct D-CALL
arguments such as `f(?_)`. Each unassigned synthetic hole becomes an ordered
goal and the parent proof is finalized only after every hole has a
pskernel-checkable solution. This intentionally implements `refine`, not
`refine'`: natural `_` holes and unresolved implicit/instance parameters
remain errors. Nested term holes wait for a general term-with-holes elaborator.

Bounded `constructor` now mirrors Lean 4.34's architecture: it requires an
inductive target, tries constructors in declaration order, and invokes the
existing apply path for the first constructor that matches. Because apply still
fails closed on unresolved implicit/instance binders, parameterized constructor
cases that require broader Meta synthesis remain a later checkpoint.

Bounded `cases local` now supports unindexed, non-recursive inductive locals,
including shared inductive parameters already present in the scrutinee type.
The tactic abstracts the current target over the scrutinee to build a motive,
creates one ordered branch goal per constructor, lambda-abstracts constructor
fields into recursor minors, and closes the parent using the pskernel-generated
`.rec` declaration. Empty inductives use the same zero-minor recursor path.
Recursive and indexed inductives remain fail-closed until Lean-compatible
induction hypotheses and index generalization/equality obligations are modeled.
Local let scrutinees and surrounding locals that depend on the scrutinee also
remain fail-closed until Lean-compatible context substitution/generalization is
implemented; ordinary independent hypotheses remain available in every branch.

Bounded `induction local` now extends the same recursor path to direct
recursive fields. The motive is obtained by abstracting the major premise from
the current goal; constructor fields are introduced first, followed by one
induction hypothesis per direct recursive field, exactly matching pskernel's
generated minor binder order. Each IH has the motive instantiated at that
recursive field. Indexed families, higher-order/nested recursive arguments,
local-let majors, and dependent surrounding locals remain fail-closed.

Universe-polymorphic Prelude constants are a prerequisite for equality tactics.
The Meta layer now creates fresh level metavariables for declaration universe
parameters, solves the bounded structural level equations generated by ordinary
application/type constraints, instantiates solved levels before checking, and
rejects unresolved level metavariables before kernel admission. Complex
non-structural max/imax universe constraints remain fail-closed.

Bounded `rw` now uses the inherited Lean spelling `rw [h]` and
`rw [← h]` for a single equality proof. The tactic follows Lean 4.34's core
rewrite construction rather than mutating goal text: it recognizes a real
Prelude `Eq` proof, abstracts exact structural occurrences of the selected
side into a motive, creates the rewritten child goal, and reconstructs the
parent proof with kernel-checked `Eq.ndrec_symm` (forward) or `Eq.ndrec`
(reverse). The bounded `rw` macro behavior also follows Lean's documented
`rewrite; try (with_reducible rfl)` shape for equality goals: after transport,
an `Eq` target whose sides are definitionally equal is closed with the real
polymorphic `Eq.refl`. This is not yet a general standalone `rfl` tactic.
Multiple rules, locations, occurrence selectors, iff rewriting,
definitional/kabstract occurrence matching, broader reflexive relations, and
extra theorem-argument synthesis remain fail-closed until their Meta behavior
is modeled.

The first simplifier checkpoint is intentionally `simp only [h]` (or
`simp only [← h]`) with one explicit `Eq` proof. It shares the same
kernel-checked equality transport as `rw`, repeats the selected rewrite to a
fixed point, and then attempts bounded equality reflexivity. To make
termination explicit before Lean's full simp orientation/index machinery is
ported, the chosen direction must strictly reduce a conservative structural
expression-size metric. The explicit-set checkpoint now accepts multiple rules in source order. Because
Lean's real simplifier resolves candidates through indexed theorem lookup and
priorities, ProofScript currently rejects pairwise structurally overlapping
selected lhs patterns rather than inventing a conflicting rule-selection
policy. Non-overlapping explicit rules are repeated to a fixed point through
the same proof-producing transport chain. Global `@[simp]` sets, iff lemmas,
theorem preprocessing, congruence indexes, dischargers, locations,
`simp_all`, and Lean's complete orientation/priority algorithm remain
fail-closed.

Dependent theorem/result applications now elaborate nested application arguments
as ordinary terms through the same Lean-compatible application elaborator. The
outer declaration type is still required to inhabit a `Sort`, so this widens
expressiveness without weakening type acceptance. Lean-compatible `Eq a b`
source spelling is now used in the proof regressions; the implicit carrier type
is inferred. The first executable gate covers `Eq (Nat.succ a) a`.
Native infix `=` is now parsed as non-associative proposition syntax with
application precedence above equality and arrow precedence below it, and it
elaborates to the real polymorphic `Eq`. Nat literals, arithmetic `+ - * / %`, Nat relations `< <= > >=`, and the
current verified Bool term subset (`true`, `false`, `!`, `&&`, `||`,
`==`, `!=`) are accepted in theorem/result positions through the same
notation semantics as ordinary expressions. Relation propositions use
`LE.le`/`LT.lt`; Bool operators stay Bool-valued, so an outer proposition
such as `(x == y) = true` is still required. Dependent lambdas/matches remain
future surface work.

The first deterministic search slice is now landed as bounded `exact?`.
It searches newest-first locals and then at most 4096 newest-first
zero-universe environment constants, accepting only candidates that already
close the target by ordinary `exact`. It does not apply candidates with
premises or recursively solve generated goals.

Every tactic must construct an ordinary core proof term. Tactics and LSP goal
state never become proof authorities.

Exit condition:

- representative data-structure invariants and function-correctness theorems
  can be written without manually constructing proof terms.

## Milestone L4.5 — dual-source ProofScript / Lean-subset frontends

Purpose: make the supported ProofScript language interchangeable with a bounded
Lean 4 surface without creating a second semantic pipeline.

Implement, in this order:

1. define a source-kind/frontend registry for `.ps` and supported `.lean` — **landed**; `.lean` recognition currently fails closed until DS2;
2. add a Lean-subset parser that lowers only documented supported constructs
   into the canonical surface module;
3. add a canonical ProofScript source printer, complementing the existing
   canonical Lean lowering;
4. make `psc check/build/run` select the frontend from the entry source kind;
5. add `psc translate <file> --to ps|lean`; keep `emit-lean` as a
   backward-compatible convenience alias;
6. make both source kinds compile through the identical checked-core ->
   erasure -> verified IR -> TypeScript -> JavaScript path;
7. add semantic round-trip gates for `.ps -> .lean -> checked core` and
   `.lean -> .ps -> checked core`;
8. reject unsupported Lean syntax/extensions explicitly rather than
   approximating them.

Initial Lean-subset scope follows features already admitted by ProofScript, not
full Lean syntax. User-defined syntax/macros/elaborators, metaprogramming,
arbitrary commands/attributes, and unsupported tactics remain outside the
subset until they receive explicit semantics.

Exit condition:

- the same representative program/theorem corpus can be authored in canonical
  `.ps` or canonical supported `.lean`, produces pskernel-equivalent
  checked declarations, and emits the same verified runtime IR.

## Milestone L5 — modules, projects, and npm interoperability

Purpose: make the language useful for real JavaScript projects.

Implement:

- source-kind-independent module/import graph with deterministic project builds;
- mixed `.ps` / supported `.lean` dependency resolution, rejecting
  ambiguous duplicate logical modules;
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

Dual-source tooling gates:

- LSP document snapshots carry source kind and dispatch through the same
  frontend registry as `psc`;
- diagnostics, hover, navigation, completion, document symbols, and proof-state
  requests work for both `.ps` and supported `.lean`;
- VS Code recognizes `.ps` directly and supports Lean-subset documents via
  an opt-in/workspace-aware selector so it does not unconditionally conflict
  with the official Lean extension;
- source conversion becomes an editor action only after CLI round-trip gates
  are stable.

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

Reference-source precedence is defined in `docs/STUDY_REFERENCE_POLICY.md` and is mandatory for Lean-sensitive, ProofScript-surface, and TypeScript-host changes.

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

### Dual-source anti-drift additions

- `.ps` and supported `.lean` must converge before semantic acceptance:
  source kind may change parsing/printing, never checked-core meaning, proof
  authority, erasure, or backend semantics.
- Lean-subset parsing is fail-closed. Unsupported Lean macros, syntax
  extensions, elaborators, commands, tactics, and attributes get a specific
  subset diagnostic instead of approximation.
- Bidirectional source translation is judged by checked declaration and
  executable-IR equivalence, not textual identity.

## Immediate execution queue

Do not reorder without repository evidence. The dual-source L4.5 frontend
milestone enters after the current theorem-prover rewrite/simp work and before
the project/module interoperability implementation; this preserves the existing
semantic priorities while making mixed-source modules possible when L5 begins.

1. Repair/obtain an executing CI or local root-gate run.
2. Continue verified primitive/equality/comparison semantics beyond the landed
   Nat +,-,*,/,%, Nat/Bool ==/!=, and Bool !/&&/|| paths only where
   Lean-compatible meaning is explicit.
3. Extend the landed postponed global-instance lookup toward parameterized
   instances/priorities only as ProofScript libraries require them.
4. Validate the landed bounded multi-rule simp-only proof reconstruction.
5. Keep theorem-statement syntax evidence-driven; explicit dependent Pi plus
   the current Nat/Bool/propositional forms cover the reference-backed
   foundation. Add lambdas/match only when a concrete specification needs them.
6. Validate and then broaden the landed bounded zero-subgoal `exact?` search
   only where Lean library-search semantics can be modeled explicitly; do not
   silently turn it into recursive automation.
7. Implement project/module/import semantics on the checked-core path.
8. Design and implement explicit npm/JS FFI.
9. Start the ProofScript-written standard library.
10. Expand recursion/dependent ADTs only with pskernel-backed theory gates.
11. Make verified mode default once feature coverage surpasses the legacy lane.
12. Retire the legacy software checker.

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
