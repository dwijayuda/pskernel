# ProofScript standard library

This directory is the first standard-library tranche authored in ProofScript
and compiled by the same verified project pipeline as user code.

## Current modules

- `ProofScript.Data.Option`: `PsOption`, map/bind/get-or-else/or-else/is-some helpers.
- `ProofScript.Data.Result`: `PsResult`, value/error mapping, bind, get-or-else,
  status checks, and two-way Option conversion.
- `ProofScript.Data.List`: `PsList`, structural map/append/length/head/head-or-else/is-empty helpers.

- `ProofScript.Text.Lexer`: portable ASCII lexer character classes plus
  `String.Pos.Raw` byte-position and `SourceSpan` helpers, authored in
  ProofScript over the certified Lean 4.34 text foundation.

The `Ps*` type names are intentional and temporary. Lean's Prelude already
owns `Option` and `List`, while the current verified runtime erasure only
assigns executable representations to inductives admitted by the checked
source project. The stdlib therefore does not shadow Lean's built-ins or add
an erasure special case.

The three modules now contain thirty-seven pskernel-admitted theorems in total:
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

- `optionBind` and `optionOrElse`;
- `resultBind`, `resultGetOrElse`, `resultMapError`, `resultIsOk`, and two-way Result/Option conversion;
- generic `listMap`;
- structurally recursive `listAppend` with an invariant second list;
- `listLength`, `listIsEmpty`, and `listHeadOrElse` runtime composition;
- thirty-seven admitted stdlib theorems: twenty-two definitional laws use bounded
  `rfl`, `optionOrElseNoneRight`, `resultToOptionMap`, and
  `resultToOptionMapError`, `resultMapMapError`, and `resultGetOrElseMap` dogfood bounded `cases`; `optionMapOrElse`, `optionGetOrElseOrElse`, and `optionGetOrElseMap` dogfood higher-order/helper composition through Option case analysis,
  `optionOrElseNoneSymm` dogfoods environment-candidate `exact?` Eq
  symmetry, `optionGetOrElseNoneSome` dogfoods proof-producing multi-rule
  `simp only`, and `listAppendNilRight` / `listAppendAssoc` /
  `listMapAppend` dogfood bounded induction plus checked rewriting;
- portable lexer classification and a non-BMP UTF-8 first-character span;
- zero runtime external assumptions.

For input `9`, the current dogfood `main` returns `22`.

## List head fallback checkpoint

`ProofScript.Data.List.listHeadOrElse` returns the first list element or an
explicit fallback for `nil`. `listHeadOrElseNil` and
`listHeadOrElseCons` record the two constructor equations as bounded
Eq-only `rfl` proofs.

The dogfood computes both the Option-based value and the direct list-head
fallback, then selects through `optionIsSome`. This executes the new helper
while also bringing the existing Option status query into the verified runtime
path without changing the expected result.

## List emptiness checkpoint

`ProofScript.Data.List.listIsEmpty` exposes the constructor distinction as a
verified Bool: `nil -> true`, `cons -> false`. The direct `cons`
computation theorem `listIsEmptyCons` and the nil-left composition law
`listIsEmptyAppendNilLeft` are definitional Eq proofs closed by bounded
`rfl`. The latter intentionally lets its later list argument determine the
generic element type instead of relying on an unconstrained polymorphic
`PsList.nil`.

The dogfood program now chooses between zero and `listLength` with a verified
Bool `if` driven by `listIsEmpty`, composing ADT matching with the already
verified Bool-control-flow path without new compiler semantics.

## First inductive library law

`ProofScript.Data.List.listAppendNilRight` is the first stdlib law in this
tranche that is not pure definitional reflexivity:

```text
listAppend(xs, PsList.nil) = xs
```

It uses bounded induction. Constructor fields retain their source names in the
recursive branch and the recursive field `tail` exposes `tail_ih`. The proof
rewrites with the checked constructor computation law and that induction
hypothesis. No host theorem or compiler shortcut is involved.

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

## Option simp-only integration law

`ProofScript.Data.Option.optionGetOrElseNoneSome` proves:

```text
optionGetOrElse(
  optionOrElse(PsOption.none, PsOption.some(value)),
  default
) = value
```

with exactly the two checked rules `optionOrElseNone` and
`optionGetOrElseSome`. Both directions strictly reduce the current structural
expression-size metric and their lhs patterns are non-overlapping. This keeps a
genuine multi-rule `simp only` regression in the end-to-end stdlib while every
generic type parameter is constrained by an ordinary value term.

## Result/Option map compatibility

`ProofScript.Data.Result.resultToOptionMap` proves:

```text
resultToOption(resultMap(f, value)) =
optionMap(f, resultToOption(value))
```

for every `PsResult`. The proof is bounded case analysis followed by
definitional reflexivity in both constructors. This is the first stdlib law
linking the higher-order Result mapper to the Option mapper; it uses no host
functor implementation or special theorem rule.

`resultToOptionFromSome` records the corresponding checked success
round-trip through `resultFromOption`; the explicit error value constrains the
otherwise-phantom error type and the theorem closes by bounded `rfl`.

## Result error-map/Option compatibility

`ProofScript.Data.Result.resultToOptionMapError` proves:

```text
resultToOption(resultMapError(f, value)) =
resultToOption(value)
```

for every `PsResult`. This mirrors Lean 4.34's `Except.mapError` /
`Except.toOption` behavior: mapping the error payload preserves successful
values, while `toOption` discards the error payload entirely. The proof is
bounded case analysis plus definitional reflexivity in both constructors, so
the law adds no new proof rule or host-side Result semantics.


## Result value/error map commutation

`ProofScript.Data.Result.resultMapMapError` proves:

```text
resultMap(f, resultMapError(g, value)) =
resultMapError(g, resultMap(f, value))
```

for every `PsResult`. Value mapping changes only the success payload and error
mapping changes only the error payload, so the operations commute. The proof is
bounded constructor case analysis followed by kernel definitional reflexivity in
both branches. This gives the stdlib a generic two-channel law without adding a
new tactic, host-side Result semantics, or backend rewrite.

## Option get-or-else/or-else compatibility

`ProofScript.Data.Option.optionGetOrElseOrElse` proves:

```text
optionGetOrElse(optionOrElse(value, fallback), default) =
optionGetOrElse(value, optionGetOrElse(fallback, default))
```

for every `PsOption`. A present value wins immediately; when the first value
is absent, both sides reduce to extracting the fallback with the same default.
The proof is bounded `cases` plus Eq-only `rfl`, following the constructor
behavior of Lean 4.34's Option elimination/get-default operations and strict
Option choice without adding new elaborator or runtime semantics.

## Option bind checkpoint

`ProofScript.Data.Option.optionBind` now provides the standard Option
sequencing operation:

```text
optionBind(value, f)
```

It follows Lean 4.34 `Option.bind` constructor behavior exactly for this
source-owned ADT: `none` stays `none`, while `some(value)` continues with
`f(value)`. The adjacent `optionBindNone` and `optionBindSome` theorems
are both definitional and close with bounded Eq-only `rfl`.

The dogfood program routes its Result-derived Option through `optionBind`
before fallback selection, so the executable source -> checked core -> erasure
-> verified IR -> TypeScript -> JavaScript path now exercises higher-order
Option sequencing as well as mapping.

## Option map/get-or-else compatibility

`ProofScript.Data.Option.optionGetOrElseMap` proves:

```text
optionGetOrElse(optionMap(f, value), f(fallback)) =
f(optionGetOrElse(value, fallback))
```

for every `PsOption`. In the `some` branch both sides reduce to the mapped
value; in the `none` branch both reduce to the mapped fallback. The proof is
bounded `cases` followed by Eq-only `rfl`, matching Lean 4.34's
constructor-level `Option.map` and `Option.getD` behavior without adding a
special rewrite rule or runtime implementation.

## Result status checkpoint

`ProofScript.Data.Result.resultIsOk` exposes Result constructor status as
Bool. The generic laws `resultIsOkMap` and `resultIsOkMapError` prove by
bounded constructor cases that mapping either payload channel preserves that
status. This avoids underconstrained direct constructor statements where the
opposite Result type parameter is phantom.

The dogfood program guards Result extraction with `resultIsOk`, composing
Result matching with the existing verified Bool control-flow path while keeping
the error channel explicit.

## Option-to-Result conversion checkpoint

`ProofScript.Data.Result.resultFromOption` converts a source-owned
`PsOption` into `PsResult` using an explicit error value:

```text
none    -> error(error)
some(x) -> ok(x)
```

`resultFromOptionSome` records the direct success conversion. For the absent
case, `resultGetOrElseFromNone` observes the resulting error through an
explicit fallback; that fallback also provides the otherwise-phantom success
type. Both close by bounded Eq-only `rfl`. The dogfood program round-trips its
mapped Result through Option and back before value extraction, so both
conversion directions are exercised through verified compilation and
JavaScript execution.

## Result bind checkpoint

`ProofScript.Data.Result.resultBind` provides success-channel sequencing:

```text
resultBind(value, f)
```

It mirrors Lean 4.34 `Except.bind` for the source-owned Result ADT: an
`ok(value)` continues with `f(value)`, while an `error(error)` propagates
the same error unchanged. `resultBindOk` and `resultBindError` are
definitional computation laws proved by bounded Eq-only `rfl`.

The stdlib dogfood now sends its mapped Result through `resultBind` before
error mapping and extraction, exercising higher-order Result sequencing through
the existing verified compilation path without any host Result implementation.

## Result map/get-or-else compatibility

`resultGetOrElseFromSome` first records the success path through
`resultFromOption`, using the explicit error value to constrain both Result
parameters. `ProofScript.Data.Result.resultGetOrElseMap` then proves:

```text
resultGetOrElse(resultMap(f, value), f(fallback)) =
f(resultGetOrElse(value, fallback))
```

for every `PsResult`. On a successful value both sides reduce to `f(value)`;
on an error both reduce to the mapped fallback. The proof is bounded constructor
case analysis plus Eq-only definitional reflexivity, matching the constructor
behavior of Lean 4.34 `Except.map` without adding a Result-specific tactic or
runtime shortcut.

## Exact-search symmetry dogfood

`ProofScript.Data.Option.optionOrElseNoneSymm` proves the reverse orientation
of the earlier definitional law:

```text
fallback = optionOrElse(PsOption.none, fallback)
```

using only:

```text
by exact?
```

The matching forward theorem `optionOrElseNone` is already in the environment.
Direct candidate matching therefore fails on orientation; bounded library search
tries the symmetric Eq target, infers the theorem's ordinary implicit/default
arguments, then reconstructs the requested proof with the real polymorphic
`Eq.symm`. The completed term is still checked by pskernel.

## Option map/orElse compatibility

`ProofScript.Data.Option.optionMapOrElse` proves:

```text
optionMap(f, optionOrElse(value, fallback)) =
optionOrElse(optionMap(f, value), optionMap(f, fallback))
```

for every Option value and fallback. The proof is exactly
`by cases value; rfl; rfl`. Both constructor branches reduce through the
ProofScript-authored Option definitions and close by kernel definitional
equality. The law therefore exercises a higher-order function argument across
bounded case analysis without adding a host functor implementation or a new
proof rule.
