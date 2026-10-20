# r3 Decision: <code>const</code>

Status: **accepted for r3; still usability-gated before stable/1.0 freeze**

## Question

r2 defines:

~~~proofscript
const answer: Nat := 42
~~~

as a parameterless Lean definition.

This is convenient for TypeScript developers, but <code>const</code> in JavaScript/TypeScript means a non-reassignable binding, not "a Lean definition with no declaration parameters."

The question is whether the familiarity benefit outweighs the false-friend risk.

## Alternatives

### A. Retain const everywhere in .ps

Advantages:
- familiar top-level value spelling;
- visually distinguishes ordinary values from explicitly parameterized <code>function</code>;
- maps cleanly to a native parameterless definition.

Costs:
- developers may infer JS object-freezing or local-binding semantics;
- a function-valued <code>const</code> can surprise users who believe functions must use <code>function</code>.

### B. Remove const and teach def

Advantages:
- smallest surface;
- perfect alignment with Lean;
- no false friend.

Costs:
- ordinary application code looks more theorem-prover-specific;
- weakens the value/function teaching distinction.

### C. Introduce another keyword

This merely replaces one vocabulary choice with another and adds migration cost. No candidate studied so far has a semantic advantage.

### D. Keep const only in ps-standard

This would make identical .ps source profile-dependent for no semantic benefit. Reject.
## Accepted r3 decision

Retain <code>const</code> in both r3 profiles as a **top-level/namespace value-declaration alias**.

Rules:

1. <code>const</code> has no declaration parameters.
2. It lowers to native <code>def</code>.
3. It is not a local binding keyword; local immutable bindings remain native <code>let</code>.
4. It does not freeze an object, imply compile-time evaluation, or create JavaScript binding semantics.
5. It may have function type because functions are values.
6. The canonical documentation calls it a "value definition", not a JavaScript const.
7. Public docs should show <code>function</code> for named callable APIs and reserve function-valued <code>const</code> mostly for higher-order values.

Example:

~~~proofscript
const defaultPort: Nat := 8080

function add(x: Nat, y: Nat): Nat :=
  x + y

const normalize: String -> String :=
  fun text => text.trim
~~~

The last form is legal but not the default teaching style for an exported callable API.
## Why not make const stronger

It would be a semantic mistake to define <code>const</code> as "must reduce at compile time" or "must be deeply immutable."

Lean definitions can denote functions, structures, computations, or opaque/runtime-relevant values according to their actual type and definition kind.

The target backend may perform constant folding under its ordinary preservation rules. The source keyword does not authorize it.

## Interaction with local variables

Do not add:

~~~proofscript
const x = value
~~~

as a replacement for native <code>let</code> in r3.

That would create two local immutable-binding vocabularies and import the TypeScript <code>=</code> spelling the language otherwise rejects for binding.

Application code uses:

~~~proofscript
let x := value
~~~

and mutable local syntax remains owned by the corresponding native <code>do</code> mechanisms.

## TypeScript interop

A generated TypeScript module may use JS/TS <code>const</code> internally to emit a target binding. That target keyword has target-language meaning and is not the semantic definition of PSC <code>const</code>.
## Usability gate

Before 1.0, the human study must test whether TypeScript developers can correctly answer:

- whether a <code>const</code> structure is deeply frozen;
- whether a <code>const</code> function value is legal;
- whether local <code>const</code> exists;
- whether changing a referenced foreign resource is prohibited by <code>const</code>;
- whether <code>const</code> means compile-time evaluation.

Predefined freeze rule:

- retain <code>const</code> if at least 80% of trained TypeScript participants answer all five semantic questions correctly after the standard tutorial and there is no substantially better <code>def</code>-only result on the same tasks;
- otherwise reconsider removal before 1.0.

The threshold is a design gate, not a claim that the study has run.

## Migration

If a later study removes <code>const</code>, migration is mechanically simple because its r2/r3 meaning is parameterless <code>def</code>. Preserve documentation/comments and declaration identity.

## Evidence status

Current evidence:
- v0.7/r2 syntax and lowering contract: specified;
- TypeScript familiarity rationale: documented precedent;
- human comprehension: **not yet measured**;
- production parser implementation: not claimed.

Decision for r3: **retain**. Reconsideration remains explicitly permitted before stable/1.0 freeze if the human study shows persistent false-friend confusion.