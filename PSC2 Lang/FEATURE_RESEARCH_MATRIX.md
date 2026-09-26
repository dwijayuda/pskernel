# PSC2 Feature Research Matrix

Status: **research input for PSC2 scope; not yet a normative language spec**

This document asks a narrower question than "what features do Lean and
TypeScript have?":

> Which missing/deferred PSC1 facilities are sufficiently common or sufficiently
> painful to omit that PSC2 should standardize them for practical adoption?

PSC2 should not chase feature-count parity. A feature is a strong candidate when
one or more of these are true:

1. it is pervasive in ordinary Lean programming;
2. it is pervasive in Lean theorem development;
3. TypeScript developers rely on a comparable ergonomic capability every day;
4. the feature is not frequent but its absence creates disproportionate pain;
5. it materially improves formal verification or library scalability;
6. it can be implemented above the PSC1 kernel with low semantic cost.

## Evidence discipline

The table uses three kinds of evidence:

- **official docs** — feature is presented as a normal programming/proving tool
  by Lean or TypeScript documentation;
- **repository signal** — current GitHub code-search file-match counts in Lean 4
  or mathlib;
- **migration reasoning** — absence forces verbose encodings or a substantially
  different programming style.

GitHub code-search counts are approximate signals, not exact token-frequency
statistics. They can include comments/examples and change with repository
revision.

Current signals gathered for this study include:

| Search signal | Current file matches | Interpretation |
| --- | ---: | --- |
| `simp` in mathlib | ~7,072 | simplification is pervasive |
| `rw [` in mathlib | ~6,224 | rewriting is pervasive |
| `have ` in mathlib | ~4,552 | local proof facts are pervasive |
| `simpa` in mathlib | ~3,816 | simplifier-driven finishing is pervasive |
| `rcases` in mathlib | ~2,264 | structured proof destructuring is very common |
| `calc` in mathlib | ~1,744 | calculational proof style is very common |
| `by_cases` in mathlib | ~1,536 | proof case splitting is very common |
| `let mut` in Lean 4 repo | ~286 | local imperative syntax is normal implementation code |
| broad `for ` search in Lean 4 repo | ~1,432 | iteration syntax is widespread; count is especially noisy |
| `termination_by` in mathlib | ~60 | specialized, but important when structural recursion is insufficient |

The conclusion should **not** be "add everything with a high count." For
example, `simp` belongs in a large untrusted prover library rather than the
kernel. Conversely, contracts are new enough in Lean 4.34 to have much less
historical usage, but are strategically important for ProofScript's formal
verification identity.

---

# 1. Programming features

## 1.1 Generalized field/method notation

Lean usage: **very high**

TypeScript analogue: **fundamental** (`obj.field`, `obj.method(...)`)

PSC1 status: projections exist; broad generalized method-style notation is
optional/non-blocking.

Pain if omitted: **high**

Recommended PSC2 status: **REQUIRED source/elaboration feature**.

Why:

```lean
xs.map f
arr.push x
str.extract i j
```

and

```ts
xs.map(f)
response.json()
text.trim()
```

are central to readable APIs. PSC2 should support deterministic method lookup
without adopting JavaScript prototype dispatch.

Implementation class: **elaborator sugar**.

Preferred lowering:

```text
x.f(a, b)
  -> resolve declaration f from the static type/namespace of x
  -> f(x, a, b)
```

No kernel change.

## 1.2 Structure update / immutable copy-with-update

Lean usage: **common**

TypeScript analogue: **very common object spread/update**.

PSC1 status: optional/non-blocking.

Pain if omitted: **high**, especially for immutable configuration/AST/state
records.

Recommended PSC2 status: **REQUIRED**.

Example:

```proofscript
{ cfg with timeout := 1000 }
```

This should lower to ordinary constructor/projection operations.

No kernel change.

## 1.3 Named and default arguments

Lean usage: **common**

TypeScript analogue: default parameters are ordinary everyday syntax; named
arguments are commonly approximated with options objects/destructuring.

PSC1 status: optional/non-blocking.

Pain if omitted: **medium-high** for APIs with many optional/configuration
parameters.

Recommended PSC2 status: **REQUIRED**.

Implementation class: **elaboration only**.

## 1.4 Rich patterns and equation-style definitions

Lean usage: **very high**.

TypeScript analogue: destructuring plus discriminated-union narrowing.

PSC1 status: only the basic single-scrutinee path is required; nested patterns,
multi-scrutinee matching, let/do patterns and `if let` are optional.

Pain if omitted: **very high** for algebraic data and compiler/theorem code.

Recommended PSC2 status: **REQUIRED**:

- nested constructor patterns;
- tuple/product patterns;
- multi-scrutinee match;
- let-patterns;
- do-patterns;
- `if let` convenience;
- equation-style function clauses.

Implementation class: **pattern compiler above Core**. Lower to ordinary
matches/eliminators.

No kernel change.

## 1.5 Local recursion, mutual recursion and practical well-founded recursion

Lean usage: structural recursion is pervasive; explicit termination hints are
less frequent but important for algorithms that do not fit structural recursion.

TypeScript analogue: unrestricted recursive functions.

PSC1 status: structural recursion + controlled executable `partial def` are
required; mutual/local/general well-founded recursion are deferred/optional.

Pain if omitted: **medium for ordinary programs, high for algorithm research and
verified recursive algorithms**.

Recommended PSC2 status:

- local recursion: **REQUIRED**;
- practical mutual recursion: **REQUIRED**;
- well-founded recursion and `termination_by`/decreasing evidence:
  **REQUIRED for ProofScript Standard theorem/verification profile**;
- `partial` remains runtime-only and cannot gain proof authority.

This is one of the few PSC2 items that deserves deeper semantic/elaboration
work, although it should still compile to existing recursors/fixpoint machinery
where possible rather than adding a new kernel rule.

## 1.6 `let mut`, assignment, `for`, `while`, `break`, `continue`

Lean usage: **normal implementation code**. Current Lean source contains
hundreds of files using `let mut`, and iteration is widespread.

TypeScript analogue: **fundamental everyday programming**.

PSC1 status: optional/non-blocking; recursion/folds/state are sufficient for the
bootstrap.

Pain if omitted: **high for application developers and compiler authors**.

Recommended PSC2 status: **REQUIRED ergonomic syntax**, with a strict rule:

> mutable-looking syntax is not a new imperative semantic authority.

It must desugar through existing `do`, state, `ForIn`/iteration, recursion and
control-flow abstractions.

This follows Lean's useful design: imperative-looking source can remain pure or
monadic after elaboration.

No kernel change.

## 1.7 Namespaces, sections, shared variables, open/import ergonomics

Lean usage: **pervasive in large libraries**.

TypeScript analogue: ES modules, imports/exports, local module scope.

PSC1 status: deterministic modules/imports and qualified names are required;
most namespace/section/open conveniences are not.

Pain if omitted: **low in tiny programs, very high in large libraries**.

Recommended PSC2 status: **REQUIRED scalable-library ergonomics**, but keep the
semantics simpler than arbitrary Lean environment extensions.

At minimum:

- namespace blocks;
- deterministic `open`/import aliases;
- section-local declarations/options;
- shared `variable` declarations for theorem-heavy code;
- explicit public/private/re-export behavior.

## 1.8 `abbrev`, transparency and `opaque`

Lean usage: **common enough to matter in library design**.

TypeScript analogue: `type` aliases only partially compare; TS has no equivalent
of definitional transparency.

PSC1 status: optional.

Pain if omitted: **medium for programming, high for large theorem libraries**.

Recommended PSC2 status:

- `abbrev`: **REQUIRED convenience**;
- explicit opacity/transparency controls: **REQUIRED theorem-platform
  capability**, with semantics compatible with the kernel/profile model.

## 1.9 Deriving

Lean usage: **common programming convenience**.

TypeScript analogue: decorators/code generation/schema tools rather than a core
language equivalent.

PSC1 status: not foundational.

Pain if omitted: **medium**, but repeated boilerplate becomes severe for data
models.

Recommended PSC2 status: **standard controlled derive plugin API** plus a small
standard derive set (`BEq`/decidable equality, ordering, repr/serialization as
semantically appropriate).

Generated declarations are checked normally.

## 1.10 Generic effect libraries

Lean usage: Reader/State/Except-style effects are central to compiler,
elaborator and tactic implementation.

TypeScript analogue: context/state libraries, Promise-like sequencing,
application frameworks.

PSC1 status: concrete compiler reader/state/error effect is required; generic
transformer ecosystem is optional.

Pain if omitted: **low for simple apps, high for plugin/compiler authors**.

Recommended PSC2 status: **standard library requirement**, not kernel syntax.

## 1.11 Async/task programming

Lean usage: less central to theorem source, but current Lean/Std has async/task
infrastructure.

TypeScript analogue: **fundamental** `Promise` + `async`/`await`.

PSC1 status: deliberately post-PSC1.

Pain if omitted: **very high for TypeScript/web/server adoption**.

Recommended PSC2 status:

- target-neutral `Task A` semantic/library abstraction: **REQUIRED platform
  capability**;
- structured cancellation/join/race/timeout: strongly recommended;
- `async`/`await` syntax: **source sugar**, not Promise semantics;
- backend adapters map Task to JS, Rust and Wasm host mechanisms.

---

# 2. Theorem-proving features

## 2.1 `have`, `show`, `suffices`

Lean usage: **pervasive**. Current mathlib search signal finds `have` in roughly
4.5k files.

PSC1 status: proof-aware local forms are planned/optional rather than part of the
minimal required tactic surface.

Pain if omitted: **very high**. Long proofs become tactic-state scripts instead
of readable structured terms.

Recommended PSC2 status: **REQUIRED**.

Implementation class: elaboration to ordinary local proof terms.

No kernel change.

## 2.2 `calc`

Lean usage: **very common**, with a current mathlib signal around 1.7k files.

TypeScript analogue: none; this is domain-specific theorem-prover ergonomics.

Pain if omitted: **high for mathematics and equality/inequality reasoning**.

Recommended PSC2 status: **REQUIRED**.

Implementation class: elaborates to transitivity/congruence proof terms.

No kernel change.

## 2.3 Mature rewriting and simplification

Lean usage signals:

- `rw [`: ~6.2k mathlib files;
- `simp`: ~7.1k mathlib files;
- `simpa`: ~3.8k mathlib files.

PSC1 status: bounded Eq `rw`, explicit/bounded `simp only`.

Pain if omitted: **extreme** for Lean migration.

Recommended PSC2 status: **REQUIRED standard prover subsystem**:

- robust `rw`;
- `simp`;
- `simpa`;
- `simp only`;
- simplification at hypotheses/goals;
- deterministic simp-lemma and simp-procedure registration;
- useful diagnostics (`simp?`-style suggestion may be a tool/plugin feature).

This subsystem can be large, but remains outside the TCB. It must construct proof
terms checked by the kernel.

## 2.4 Proof case splitting and contradiction

Lean usage: `by_cases` alone currently matches ~1.5k mathlib files.

PSC1 status: not in the minimal required tactic set.

Recommended PSC2 status: **REQUIRED**:

- `by_cases`;
- `by_contra`;
- `exfalso`;
- useful Decidable-driven branching.

No kernel change.

## 2.5 Structured destructuring: `rcases`, `rintro`, `obtain`, `use`

Lean/mathlib usage: **very common**; `rcases` currently matches ~2.2k files.

PSC1 status: basic `cases`/`induction`, not the mature destructuring family.

Pain if omitted: **high**, particularly for existential/conjunction-heavy
mathematics.

Recommended PSC2 status: **REQUIRED prover ergonomics**, possibly implemented
as standard tactics/macros over a common pattern engine rather than four
independent semantic mechanisms.

## 2.6 `subst`, `generalize`, `change`, `unfold`, `dsimp`

Lean usage: common proof-structuring/normalization tools.

PSC1 status: post-bootstrap candidates.

Pain if omitted: **medium-high** because many otherwise straightforward Lean
proofs become manually encoded.

Recommended PSC2 status: **REQUIRED standard tactic layer**.

## 2.7 `ext` and extensionality support

Lean usage: highly important in algebraic/structural libraries.

TypeScript analogue: none.

Recommended PSC2 status: **standard prover feature**, backed by controlled
extensionality registration rather than arbitrary trusted metadata.

## 2.8 Arithmetic/algebra automation

Typical Lean/mathlib tools include:

- `omega` / current Presburger/linear arithmetic facilities;
- `lia`/`linarith`-style linear reasoning;
- `ring`/`ring_nf`;
- `norm_num`;
- `decide`/native-decision procedures where soundly reconstructed;
- `aesop`/`grind`-style general search.

Pain if omitted: **high in domain work**, but they do not belong in the language
kernel or minimal grammar.

Recommended PSC2 status: **standard packages/plugins with proof reconstruction**.
PSC2 may define stable tactic/plugin APIs they rely on without making every
automation engine a release blocker.

## 2.9 Stronger typeclass synthesis and coercions

Lean usage: **pervasive infrastructure**, often invisible in source because it
makes overloaded notation/APIs work.

TypeScript analogue: generic constraints, interface-driven APIs, contextual type
inference and implicit conversions/narrowing only loosely compare.

PSC1 status: bounded instance/Decidable machinery and bounded coercions.

Pain if omitted: **very high for importing Lean-style libraries**.

Recommended PSC2 status:

- recursive instance synthesis with cycle/depth control;
- priorities;
- imported/scoped/local instances;
- practical `outParam`/`semiOutParam`-style behavior if compatibility needs it;
- deterministic coercion insertion and coercion chains;
- clear ambiguity diagnostics.

These remain elaborator/Meta behavior, not kernel rules.

## 2.10 Controlled attributes and notation

Lean usage: attributes such as simplifier/extensionality/instance registrations
are central to ecosystem-scale automation; notation is essential to readable
mathematics.

TypeScript analogue: decorators/metadata and fixed syntax only partially
compare.

PSC1 status: broad attributes/macros/custom syntax are deferred.

Pain if omitted: **high for theorem ecosystems**, even though the features are
not needed for the bootstrap compiler.

Recommended PSC2 status:

- standardized registries for `simp`, extensionality, derives/specs and other
  core prover metadata;
- simple prefix/postfix/infix notation;
- scoped notation;
- controlled syntax plugins after the standard cases are proven safe;
- no arbitrary plugin may grant proof authority.

---

# 3. Formal-verification features

## 3.1 `requires` / `ensures`

Lean status: **new in Lean 4.34 intrinsic verification and explicitly marked
experimental**.

Historical frequency: low/new, so raw usage count would be misleading.

Strategic importance to ProofScript: **very high**.

Recommended PSC2 status: **REQUIRED verification profile**.

Why:

- it is immediately understandable to software engineers;
- it gives specifications a first-class location next to executable code;
- Lean 4.34 now provides an interoperability precedent;
- the clauses can elaborate to propositions/verification conditions rather than
  expanding the kernel;
- the same contracts can govern TS/Rust/Wasm output because they live before
  backend lowering.

## 3.2 `assert`

Lean 4.34 intrinsic verification: an assertion in `do` states a proposition at
that point; `vcgen` proves it and runtime execution does not need to perform a
check.

Recommended PSC2 status: **REQUIRED verification construct**.

ProofScript must distinguish:

- verified `assert` — creates a proof obligation;
- runtime diagnostic/checking API — ordinary executable behavior.

A runtime assertion cannot satisfy a proof obligation merely because it did not
fail in one execution.

## 3.3 Loop `invariant`

Lean 4.34 supports loop invariants integrated with VC generation, including
`for` loops over supported pure iterators.

Recommended PSC2 status: **REQUIRED** once PSC2 standardizes loop syntax.

This is a natural bridge between TypeScript-style imperative code and
ProofScript verification.

## 3.4 `decreasing` / termination evidence

Lean 4.34 intrinsic verification includes decreasing clauses for loops, while
Lean definitions separately have termination machinery.

Recommended PSC2 status: **REQUIRED where termination must be proved**.

Use a common logical foundation where possible rather than creating unrelated
"loop termination" and "recursive termination" proof languages.

## 3.5 Verification-condition generation

Lean's `Std.Do`/`vcgen` ecosystem demonstrates that practical imperative
verification can sit above the kernel using weakest-precondition/Hoare-style
specifications and generate ordinary proof goals.

Recommended PSC2 status: **standard untrusted verification engine**.

Architecture:

```text
program + contracts
       |
       v
PSC2 VC generator
       |
       v
verification conditions : Prop
       |
       v
proof automation / user proofs
       |
       v
small kernel
```

## 3.6 `old` / ghost state

Some contract languages expose `old(expr)` and explicit ghost variables. Lean
4.34's intrinsic syntax instead lets contract/invariant binders name relevant
state and relies on ordinary logical values/specification machinery.

Recommended PSC2 status:

- **do not make `old` a mandatory PSC2 keyword yet**;
- first support explicit pre-state/spec binders and ordinary ghost/proof-only
  values;
- consider ergonomic `old(...)` sugar only after state/effect semantics are
  frozen;
- ghost data must erase and must not influence executable behavior unless
  explicitly reified as runtime data.

This avoids creating a second specification language prematurely.

---

# 4. TypeScript features PSC2 should deliberately *not* imitate

These are common in TypeScript/JavaScript but conflict with ProofScript's core
value proposition:

| TS/JS facility | PSC2 decision |
| --- | --- |
| `any` | do not add to verified portable code |
| implicit `undefined`/`null` | use `Option` / explicit interoperability types |
| prototype inheritance | use structures/classes/modules/functions |
| JavaScript `this` | not a portable semantic foundation |
| structural object identity/assignability everywhere | retain explicit PSC semantic types |
| truthiness | keep typed Bool/Prop conditions |
| implicit numeric coercions | keep explicit scalar conversions |
| Promise semantics as language truth | use target-neutral Task, map to Promise in TS backend |
| exceptions for expected failures | prefer typed Result/Except; host exceptions remain boundary behavior |
| unchecked casts | explicit unsafe/FFI boundary only, never proof evidence |

Migration should feel familiar while remaining semantically ProofScript.

---

# 5. Proposed PSC2 priority

## P0 — adoption blockers

Ship early:

- method notation;
- structure update;
- richer patterns/equation clauses;
- named/default arguments;
- namespaces/sections/open ergonomics;
- local/mutual recursion;
- `let mut`/`for`/`while` as desugaring;
- `have`/`show`/`suffices`/`calc`;
- mature `rw` + `simp` + `simpa`;
- `by_cases`/`by_contra`;
- `rcases`-class destructuring;
- stronger typeclass/coercion support;
- `requires`/`ensures`/`assert`/`invariant` + VC generation.

## P1 — ecosystem scalability

- controlled attributes;
- mathematical/scoped notation;
- deriving framework;
- opacity/transparency conveniences;
- well-founded recursion UX;
- generic effect libraries;
- standard extensionality support;
- Task/async standard model;
- plugin API stabilization.

## P2 — powerful standard packages

- arithmetic/algebra automation;
- broader search automation;
- SMT/proof reconstruction;
- AI tactic integrations;
- advanced async/stream/resource libraries;
- broader Lean Meta compatibility.

## P3 — evaluate only with evidence

Do not add merely for parity:

- full unrestricted Lean macro/environment-extension machinery;
- JavaScript object/prototype semantics;
- TypeScript's unsound escape hatches;
- syntax that duplicates an existing mechanism without substantial ergonomic
  benefit;
- new kernel rules where elaboration/library proofs suffice.

---

# 6. Bottom line

PSC2 should be **bigger in usability but not much bigger in trusted semantics**.

The strongest feature additions are those that satisfy all three audiences at
once:

```text
Lean developer        -> familiar method/pattern/module/proof ergonomics
TypeScript developer  -> familiar call/update/loop/async/application ergonomics
verification user     -> contracts + invariants + proof-producing automation
```

while they still converge on:

```text
PSC1 dependent core
       -> kernel check
       -> CheckedCore
       -> erasure
       -> target-neutral IR
       -> TS / Rust / Wasm
```

That should be the PSC2 design test for every proposed feature.