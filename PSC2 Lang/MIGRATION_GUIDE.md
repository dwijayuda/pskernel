# PSC2 Migration Guide

Status: **design target for migration ergonomics**

PSC2 should be easy to adopt from both Lean 4 and TypeScript without pretending
the three languages have identical semantics.

The migration goal is:

> familiar source habits where they are safe, explicit semantic differences
> where they matter, and no hidden backend-specific escape hatches.

---

# 1. Lean 4 -> PSC2

## 1.1 Intended experience

Lean developers should recognize the core model immediately:

```text
functions / dependent functions
structures
inductives
pattern matching
classes / instances
Prop / theorem / proof terms
recursion / termination
monadic do
Meta / tactics
```

PSC2 should remove the biggest current PSC1 migration friction without forcing
`.ps` to copy every Lean syntax extension.

## 1.2 Programming migration table

| Lean 4 habit | PSC1 | PSC2 target |
| --- | --- | --- |
| `x.f` generalized field notation | partial/bounded | standard |
| `{ s with field := v }` | optional | standard |
| named arguments | optional | standard |
| default arguments | optional | standard |
| nested/equation patterns | bounded | standard |
| multi-scrutinee match | optional | standard |
| `if let` / pattern binds | optional | standard convenience |
| `let mut` / assignment | optional | standard `do` sugar |
| `for` / `while` | optional | standard `do` sugar |
| local/mutual recursion | optional | standard |
| `termination_by`/well-founded recursion | optional | standard theorem/verification profile |
| namespace/open/section/variable | bounded | practical standard subset |
| `abbrev` | optional | standard |
| `opaque` / transparency controls | optional | standard theorem-platform capability |
| deriving | not foundational | controlled standard plugin |
| notation/infix/scoped notation | deferred | controlled standard subset |
| generic Reader/State/Except ecosystem | non-blocking | standard library |

## 1.3 Theorem migration table

| Lean theorem habit | PSC1 | PSC2 target |
| --- | --- | --- |
| `exact`, `intro`, `apply`, `refine` | bounded support | mature support |
| `rfl`, `rw` | bounded | mature |
| `simp only` | bounded | mature |
| `simp`, `simpa` | deferred/limited | standard prover |
| `have` / `show` / `suffices` | not minimal blocker | standard |
| `calc` | not minimal blocker | standard |
| `by_cases`, `by_contra` | post-bootstrap | standard |
| `rcases`, `rintro`, `obtain`, `use` | not minimal | standard structured destructuring |
| `subst`, `generalize`, `change` | post-bootstrap | standard |
| `unfold`, `dsimp` | post-bootstrap | standard |
| dependent/indexed cases/induction | bounded | mature |
| simp/ext/spec attributes | broad attributes deferred | typed controlled registries |
| arithmetic/algebra tactics | deferred | standard packages/plugins |
| general proof search | deferred | plugin/library capability |

## 1.4 Lean syntax compatibility

PSC2 should continue the dual-source strategy:

```text
Foo.lean -> Lean-compatible frontend -> canonical semantics
Foo.ps   -> native PSC frontend      -> canonical semantics
```

A Lean theorem should increasingly be accepted unchanged in `.lean` as the
compatibility level grows.

PSC2 does **not** require `.ps` to adopt every Lean token or macro. Native `.ps`
should remain smaller and easier to learn.

## 1.5 Lean intrinsic verification migration

Lean 4.34 introduced experimental:

```text
requires
ensures
assert
invariant
decreasing
```

PSC2 intentionally adopts this conceptual vocabulary. A Lean verification
example in the supported subset should require little or no conceptual rewrite.

ProofScript may freeze a cleaner/stabler contract semantics than the exact
experimental Lean release details, but compatibility adapters should make
supported `.lean` source straightforward.

---

# 2. TypeScript -> PSC2

## 2.1 Familiar features PSC2 should provide

A TypeScript developer should find familiar ergonomics:

```proofscript
function mapUser(user: User): User :=
  { user with active := true };

function names(users: List User): List String :=
  users.map(fun u => u.name);
```

and, in effectful code:

```proofscript
do {
  let mut total := 0;
  for x in values {
    total := total + x;
  }
  return total;
}
```

PSC2 should therefore standardize:

- method-like notation;
- immutable record update;
- destructuring/pattern matching;
- named/default parameters;
- familiar loops/mutable-looking locals in controlled contexts;
- module/import ergonomics;
- Task/async programming;
- strong inference around generics/instances where possible.

## 2.2 TypeScript concepts with direct/strong PSC analogues

| TypeScript | PSC2 |
| --- | --- |
| function | function/def |
| generic function | polymorphic/dependent function |
| interface/object record | structure |
| discriminated union | inductive type |
| switch/narrowing | match/pattern refinement |
| optional result | Option |
| error result | Result/Except |
| readonly immutable data | default PSC value model |
| generic constraint | class/instance / dependent constraint |
| object spread update | structure update |
| method call | generalized field/method notation |
| async/await | Task + async/await sugar |
| module import/export | PSC module/import/export model |

## 2.3 TypeScript concepts that should change during migration

### `null` / `undefined`

Prefer:

```proofscript
Option A
```

rather than implicit absence.

### exceptions

Prefer:

```proofscript
Result Error A
Except Error A
```

for expected failures. Host exceptions remain an explicit boundary concern.

### mutation

PSC2 may look imperative locally, but the semantics are owned by `do`/state and
are not JavaScript shared mutable-object semantics.

### objects/classes

Use:

```text
structure + functions + modules + classes/instances + method notation
```

rather than prototype inheritance.

### structural typing

ProofScript types retain their declared logical semantics; compatibility with a
shape is not automatically the same as TypeScript structural assignability.

### `any`

There is no safe portable analogue. Dynamic interop belongs behind typed
FFI/codec boundaries.

### number

Use the intended semantic type:

```text
Nat / Int / UInt* / Int* / Float / Float32
```

rather than treating all numbers as JavaScript `number`.

## 2.4 TypeScript contracts and verification

TypeScript developers do not normally write proof-carrying pre/postconditions,
so PSC2 should keep contract syntax approachable:

```proofscript
function divide(a: Int, b: Int): Int
  requires b != 0
  ensures r => r * b + (a % b) = a :=
  ...;
```

This should read as ordinary design-by-contract syntax while providing stronger
static meaning than a runtime assertion library.

The compiler/VC generator turns the clauses into propositions/proof obligations.

## 2.5 Async migration

TypeScript:

```ts
async function load(): Promise<User> {
  const r = await fetch(url);
  return await r.json();
}
```

PSC2 target concept:

```proofscript
async function load(): Task User := do {
  const r <- fetch(url);
  return await decodeUser(r);
}
```

Exact syntax remains to be frozen. The semantic difference is important:

```text
Task is ProofScript semantics
Promise is one TS-backend representation
```

Rust/Wasm backends are free to use appropriate target mechanisms while
preserving Task behavior.

---

# 3. Formal-verification researcher -> PSC2

PSC2 should support several verification styles without adding separate trusted
logics.

## 3.1 Theorem style

```proofscript
theorem resultCorrect(...): P := by {
  ...
}
```

## 3.2 Dependent-data style

Encode invariants in types/constructors:

```text
Fin n
Vector A n
validated structures
```

## 3.3 Contract style

```proofscript
requires ...
ensures ...
invariant ...
assert ...
```

## 3.4 Hoare/VC style

Use the standard verification library/VC generator for effectful programs.

These approaches should converge on `Prop` and kernel-checked proof terms rather
than becoming unrelated trust domains.

---

# 4. Features that are deliberately not migration goals

PSC2 should not promise zero-friction migration for programs whose semantics
fundamentally rely on:

- TypeScript `any`;
- dynamic property access without a typed model;
- prototype mutation/inheritance;
- ambient globals with implicit side effects;
- unchecked reflection/eval;
- host exception identity;
- arbitrary JS object identity;
- Lean-specific runtime/compiler internals with no portable meaning;
- arbitrary Lean macros/environment extensions before a compatible plugin API
  exists.

Such programs can still interoperate through explicit FFI/compatibility layers.

---

# 5. Migration success criteria

PSC2 should be considered migration-friendly when representative developers can
complete these tasks without fighting the language:

### Lean programmer

- port a normal data-processing module while retaining method notation,
  structures, patterns, loops and typeclasses;
- port a nontrivial theorem using `have`, `calc`, `rw`, `simp`, `by_cases` and
  structured destructuring;
- port a well-founded recursive algorithm;
- port a contract/invariant example from the supported Lean intrinsic
  verification subset.

### TypeScript programmer

- model API data without writing verbose constructor plumbing;
- write collection pipelines naturally;
- use local loop/mutation syntax without abandoning verification;
- write async code against Task;
- call npm/JS APIs through typed adapters;
- add `requires`/`ensures` to critical functions and understand resulting
  diagnostics.

### Verification researcher

- state propositions directly;
- define specifications and loop invariants;
- write custom tactics/VC extensions without expanding the kernel TCB;
- inspect/replay proof artifacts;
- compare kernel/provider results under the assurance profile.

The goal is not identical syntax across communities. The goal is **low semantic
surprise and low unnecessary friction**.