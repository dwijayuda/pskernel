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

The three modules now contain eleven pskernel-admitted theorems in total:
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
- eleven admitted stdlib theorems: nine definitional laws use bounded `rfl`,
  `optionOrElseNoneRight` dogfoods bounded `cases`, and
  `listAppendNilRight` dogfoods bounded induction plus checked rewriting;
- zero runtime external assumptions.

For input `9`, the current dogfood `main` returns `22`.

## First inductive library law

`ProofScript.Data.List.listAppendNilRight` is the first stdlib law in this
tranche that is not pure definitional reflexivity:

```text
listAppend(xs, PsList.nil) = xs
```

It uses bounded induction. Constructor fields retain their source names in the
recursive branch and the recursive field `tail` exposes `tail_ih`. The proof
then rewrites with the checked constructor computation law and that induction
hypothesis. No host theorem or compiler shortcut is involved.

## First universal case-analysis law

`ProofScript.Data.Option.optionOrElseNoneRight` proves:

```text
optionOrElse(value, PsOption.none) = value
```

for every `PsOption` using `by cases value; rfl; rfl`. This deliberately
exercises the pskernel-recursors-based bounded `cases` path on a non-recursive
ADT. Both branches are discharged by ordinary definitional equality.
