# PSC1 for Lean Programmers

PSC1 keeps Lean-compatible semantics where they matter but deliberately offers a
smaller, more fixed, JavaScript-ecosystem-friendly language surface.

If you already know Lean, the key idea is:

> Treat PSC1 as a bounded language with Lean-compatible dependent semantics,
> not as a new frontend that automatically accepts every Lean command, macro,
> tactic, or metaprogram.

## Familiar concepts keep familiar names

PSC1 intentionally retains names such as:

- `Prop`;
- `Type`;
- `def`;
- `theorem`;
- `inductive`;
- `structure`;
- `class`;
- `instance`;
- `match`;
- `fun`;
- `by`;
- `do`;
- `:=`;
- `=`;
- `==`.

This is not cosmetic. These names teach the semantic model accurately.

## ProofScript decorations

PSC1 adds a small owned surface.

### D-CALL

```proofscript
f(x, y)
```

canonicalizes to curried Lean application.

### Explicit parameter grouping

```proofscript
function add(x: Nat, y: Nat): Nat :=
  x + y;
```

maps to ordinary ordered binders.

### `const` and `function`

They are aliases of `def`:

```text
const    = parameterless def alias
function = def alias requiring explicit declaration parameters
```

No new declaration kind reaches checked core or pskernel.

### Braced owned forms

PSC1 admits registered braced forms for:

- conditionals;
- structure/class bodies;
- inductive constructor bodies;
- match alternatives;
- where blocks.

The braces are category-specific. They are not a generic statement language.

## The big difference: bounded inheritance

The old v0.7 reference describes a reference-Lean profile that can defer
unowned syntax to the pinned Lean parser.

PSC1 self-hosting cannot use "Lean accepts it" as its standalone parser rule.

The first frozen language instead accepts:

- the required PSC1 surface;
- the bounded supported Lean-compatible subset;
- optional forms explicitly implemented and retained.

Unknown Lean syntax fails closed.

## Why not full Lean syntax?

The self-host compiler is meant to remain small enough to own.

The first profile explicitly avoids requiring:

- arbitrary user syntax categories;
- macros/quotations;
- custom elaborators;
- broad environment extensions;
- unrestricted attributes;
- unsafe implementation escape hatches;
- large metaprogramming machinery.

Those are legitimate Lean facilities, but they are not automatically required
for a small self-hosting ProofScript compiler.

## Kernel semantics vs frontend breadth

PSC1 still wants faithful semantics for what it supports:

- dependent Pi;
- universes;
- implicit arguments;
- metavariables;
- definitional equality;
- inductives and recursors;
- class/instance resolution for the bounded profile;
- proof terms;
- recursion admissibility.

The frontend may be much smaller than Lean while the admitted declarations
remain compatible with the pinned semantic model.

## Tactics are intentionally bounded

The current ProofScript theorem-prover surface has bounded implementations of
operations such as `exact`, `intro`, `apply`, `refine`, `constructor`,
`cases`, `induction`, Eq-oriented `rfl`/`rw`, explicit `simp only`,
and a bounded `exact?`.

This is not a promise of tactic parity.

Large Lean automation is not a prerequisite for PSC1 self-hosting.

## Dual-source support

PSC1 supports both:

```text
.ps
supported .lean
```

through different source frontends that converge before checked semantics.

That means a `.lean` file inside a ProofScript project is **not** implicitly a
full Lean file. It is parsed by the bounded `lean-subset` frontend.

Canonical translation is judged by checked declarations and executable IR, not
byte-identical source.

## Why canonical Lean still matters

Canonical Lean is useful for:

- semantic inspection;
- differential checking;
- bootstrap/reference builds;
- source transition assurance.

But after the ProofScript compiler becomes self-hosting, normal authoring is
intended to be `.ps`, with Lean becoming a generated/reference
representation for the common subset.

## Execution backends

Lean's native compiler representation is not reused as PSC1's semantic
compiler IR.

PSC1 deliberately has:

```text
CheckedCore
-> Erasure
-> target-neutral VerifiedIR
   -> TypeScript
   -> Rust
   -> Wasm
```

The independent backend design is part of the language's portability story.

## What to read next

Lean programmers can usually skip the introductory programming material and go
directly to:

1. [Generics and Dependent Types](../../handbook/05-generics-and-dependent-types.md)
2. [Propositions and Proofs](../../handbook/06-propositions-and-proofs.md)
3. [Typeclasses and Instances](../../handbook/07-typeclasses-and-instances.md)
4. [Recursion and Totality](../../handbook/08-recursion-and-totality.md)
5. [Dual-source Lean Interop](../../handbook/13-dual-source-lean-interop.md)
6. [PSC1 Language Reference](../../PSC1_LANGUAGE_REFERENCE.md)
