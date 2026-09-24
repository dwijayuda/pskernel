# ProofScript standard library

This directory is the first standard-library tranche authored in ProofScript
and compiled by the same verified project pipeline as user code.

## Current modules

- `ProofScript.Data.Option`: `PsOption`, map/get-or-else/or-else/is-some helpers.
- `ProofScript.Data.Result`: `PsResult`, value/error mapping, get-or-else,
  and Option conversion.
- `ProofScript.Data.List`: `PsList`, structural map/append/length/head helpers.

The `Ps*` type names are intentional and temporary. Lean's Prelude already
owns `Option` and `List`, while the current verified runtime erasure only
assigns executable representations to inductives admitted by the checked
source project. The stdlib therefore does not shadow Lean's built-ins or add
an erasure special case.

The three modules now contain fourteen pskernel-admitted theorems in total:
baseline reflexivity plus definitional computation laws for Option, Result, and
List helpers. These laws now deliberately use bounded `by rfl`, which constructs the same
ordinary `Eq.refl` proof term and relies on kernel definitional equality; the
stdlib still has no library-only proof rule.

Stronger algebraic laws should be added only when the required induction,
rewriting, and branch-proof surface is supported faithfully.

`test/main.ps` is an end-to-end dogfood program. It imports the library
modules, runs generic ADT helpers and structural recursion, and is executed by
the repository package-integration gate through:

```text
ProofScript source modules
  -> mixed/project resolver
  -> Lean-compatible elaboration
  -> pskernel checked core
  -> erasure
  -> verified compiler IR
  -> TypeScript
  -> JavaScript
```

## Current dogfood checkpoint

The end-to-end stdlib test now exercises:

- `optionOrElse`;
- `resultGetOrElse`;
- generic `listMap`;
- structurally recursive `listAppend` with an invariant second list;
- `listLength`;
- fourteen admitted stdlib theorems: ten definitional laws use bounded `rfl`,
  `optionOrElseNoneRight` dogfoods bounded `cases`, while
  `listAppendNilRight` dogfoods bounded induction plus proof-producing
  `simp only`, while `listAppendAssoc` and `listMapAppend` dogfood
  bounded induction plus checked rewriting;
- zero runtime external assumptions.

For input `9`, the current dogfood `main` returns `22`.

## First inductive library law

`ProofScript.Data.List.listAppendNilRight` is the first stdlib law in this
tranche that is not pure definitional reflexivity:

```text
listAppend(xs, PsList.nil) = xs
```

It uses bounded induction. Constructor fields retain their source names in the
recursive branch and the recursive field `tail` exposes `tail_ih`. The
recursive branch now runs
`simp only [listAppendCons(head, tail, PsList.nil), tail_ih]`.
Both simplification rules are explicit checked Eq proofs; the bounded
simplifier reconstructs each equality transport and closes the resulting
reflexive Eq through the kernel-backed rfl path. No global simp database, host
theorem, or compiler shortcut is involved.

## First universal case-analysis law

`ProofScript.Data.Option.optionOrElseNoneRight` proves:

```text
optionOrElse(value, PsOption.none) = value
```

for every `PsOption` using `by cases value; rfl; rfl`. This deliberately
exercises the pskernel-recursors-based bounded `cases` path on a non-recursive
ADT. Both branches are discharged by ordinary definitional equality.

## Append associativity dogfood

`ProofScript.Data.List.listAppendAssoc` proves:

```text
listAppend(listAppend(xs, ys), zs) =
listAppend(xs, listAppend(ys, zs))
```

The proof follows the same induction principle as Lean's `List.append_assoc`.
Because the current bounded `rw` intentionally matches exact structural
occurrences rather than Lean's fuller definitional/kabstract occurrence search,
the recursive branch first rewrites with the checked `listAppendCons`
computation law until the induction-hypothesis occurrence is explicit, then
rewrites by `tail_ih`. The final equality is closed by the ordinary
post-rewrite Eq-reflexivity path.

## Map/append distributivity dogfood

`ProofScript.Data.List.listMapAppend` proves:

```text
listMap(f, listAppend(xs, ys)) =
listAppend(listMap(f, xs), listMap(f, ys))
```

This is a higher-order generic law: the quantified function `f : α -> β`
survives induction as an ordinary surrounding local. The recursive branch uses
the new definitional computation law `listMapCons`, the existing
`listAppendCons`, and `tail_ih`. Every transformation is an ordinary
kernel-checked equality rewrite; the theorem does not depend on a host List
implementation or a hidden simplifier rule.
