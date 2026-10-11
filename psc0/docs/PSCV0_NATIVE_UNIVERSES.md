# Native source universes

Implementation follows the canonical v7 reference and pinned Lean 4.35.0-rc4
commit c29b6dda4f7c20e3eeaa717c4e565663c5cfa364. This capability is not full v7
conformance. Compilation and qualification use native Lean and its official
kernel, with no pskernel-core or compiler-source/self-host generation.

## Syntax and ownership

Selected RC4 grammar: scoped universe/universes commands; Type, Prop and Sort;
named levels, numerals, holes, parenthesized levels, max/imax and numeral offsets.
Offsets retain RC4's default bound of 32. Universe syntax is distinct from term
names; namespace qualification never rewrites a level name. Namespace/section
frames restore universe visibility. Declaration closure retains only used
parameters and generalizes unsolved universe holes, never term holes.

Pinned upstream locators:
- src/Lean/Parser/Level.lean: Level.paren/max/imax/hole/num/ident/addLit.
- src/Lean/Elab/Level.lean: elabLevel and maximum offset validation.
- src/Lean/Elab/Declaration.lean: declaration-level parameter collection.

## Shared semantics

Elaboration contexts own visible level names. Canonical Core already owns levels
and declaration parameters, so no new backend or kernel representation is added.
Every ordinary constant use and global instance candidate instantiates its own
fresh levels. Instance candidate failure keeps its original constraint snapshot.
Family declarations, constructors and projections share the family's level
parameters. Recursor applications share one family/motive arity check.

LevelNormalize is shared by inference, read-only conversion and unification.
It applies sound symbolic max/imax reductions and domination; it leaves unknown
imax conditions symbolic instead of guessing constraints. The official kernel
checks every admitted result. It is not yet the complete RC4 universe equation
solver (in particular disjunctive constraints and general imax equations).

Structures infer a positive result universe from their field sorts; explicit
inductive result universes must be positive. Prop inductives, explicit constant
universe applications, declaration-local universe suffixes and auto-bound
universe names remain separate work. Data headers with unresolved holes are
still refused; they require whole-family constraint collection before closure.

## Compact validation

The existing composite program now includes polymorphic definitions, symbolic
sort grammar, generalized holes, recursive data, projections and global instance
search. Five added observations exercise its executable results in both Rust and
TypeScript. Four negative cases check unknown/scoped/duplicate names and the
source offset bound. Existing refusal expectations are retained. Qualification
is pending until the full native cloud workflow passes; record the exact source
and run in AI_WORK_STATE.md after completion.
