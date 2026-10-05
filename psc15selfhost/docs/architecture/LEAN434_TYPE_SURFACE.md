# Lean 4.34 type-surface coverage

Status: exhaustive accounting contract for ProofScript's pinned Lean semantic baseline.

Pinned upstream identity:

- Lean: 4.34.0
- Commit: `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`

This document does **not** make every Lean library or compiler type part of the
ProofScript kernel prelude. ProofScript keeps a small kernel-facing environment
and grows ordinary capabilities through libraries and controlled extensions.
The purpose of this contract is that no Lean type-level surface is invisible or
silently assumed.

## Authoritative inventory

`scripts/lean434-type-inventory.lean` imports the exact pinned `Init`, `Std`,
and `Lean` umbrella modules and enumerates every environment declaration whose
type, after its Pi binders, ends in a `Sort`. This includes data types,
structures/classes, type aliases/families, propositions/predicates, and other
type-level APIs.

The inventory records:

- exact declaration name;
- constant kind;
- `Name.isInternal`;
- defining Lean module;
- membership in `Init`, `Std`, and/or `Lean`;
- whether the current ProofScript canonical prelude contains the same name.

At the audited pinned revision the exact counts are:

| Surface | Type-level declarations | Public | Internal/private | Current ProofScript prelude matches |
| --- | ---: | ---: | ---: | ---: |
| `Init` | 1,379 | 1,343 | 36 | 25 |
| `Std` | 2,534 | 2,360 | 174 | 25 |
| `Lean` | 7,463 | 6,730 | 733 | 25 |

The `Lean` umbrella contains the other two surfaces, so the union is 7,463
declarations rather than the sum of the rows.

## Exhaustive ownership

`LEAN434_TYPE_COVERAGE_POLICY.json` and
`scripts/check-lean434-type-coverage.mjs` assign every one of the 7,463
declarations to exactly one layer, in this order:

1. `lean-internal-private` — Lean implementation details/private declarations;
2. `proofscript-core-prelude` — names required in the small canonical
   ProofScript checking prelude;
3. `proofscript-stdlib` — compatible user-facing types supplied above the core;
4. `lean-init-library-only` — public Lean foundation/runtime library types not
   currently exported as ProofScript core;
5. `lean-std-library-only` — additional public Lean Std library types;
6. `lean-compiler-meta-only` — Lean compiler/elaborator/meta/server/tooling
   types that are not ProofScript kernel-prelude candidates.

CI rejects an unclassified declaration. Adding a new Lean type through a future
Lean pin therefore requires an explicit policy result rather than silently
changing the assumed environment.

## Current core type prelude

The exact Lean type names currently shared with the ProofScript prelude are:

`Array`, `Bool`, `Char`, `Decidable`, `Eq`, `Except`, `Float`,
`Float32`, `Int`, `Int8`, `Int16`, `Int32`, `Int64`, `ISize`,
`List`, `Nat`, `Option`, `Prod`, `String`, `UInt8`, `UInt16`,
`UInt32`, `UInt64`, `USize`, and `Unit`.

The ProofScript stdlib also defines `Ordering`, matching Lean's user-facing
ordering family without requiring it in the checking prelude.

## Language-handbook reconciliation

The consolidated PSC2 language document mentions several additional Lean
families. The audit tracks these separately from the broad Lean inventory so a
language promise cannot be hidden by the generic "library-only" bucket.

Current explicit gaps:

| Name | Intended owner | Current state |
| --- | --- | --- |
| `ByteArray` | standard library | not implemented in current ProofScript stdlib/prelude |
| `Sum` | standard library | not implemented in current ProofScript stdlib/prelude |
| `Fin` | foundation/standard library | not implemented in current ProofScript stdlib/prelude |
| `Subtype` | foundation/standard library | not implemented in current ProofScript stdlib/prelude |
| `Ord` | standard typeclass library | handbook example references it; not currently shipped |
| `Bind` | standard typeclass/effect library | basic-do semantics reference it; not currently shipped as the Lean interface |
| `Pure` | standard typeclass/effect library | basic-do semantics reference it; not currently shipped as the Lean interface |

`Prop`, `Type`, and `Sort` are kernel/universe constructs rather than
ordinary named prelude type declarations.

`Quot` is a special logical-foundation primitive. The kernel implementation has
quotient checking/reduction support, but the current minimal compiler prelude
does not expose Lean's `Quot` declaration as an ordinary source-library type.
That distinction must remain explicit.

## Scalar families

All fixed-width and target-word scalar **type identities** named by the current
PSC2 handbook are present in the canonical prelude:

- `UInt8`, `UInt16`, `UInt32`, `UInt64`, `USize`;
- `Int8`, `Int16`, `Int32`, `Int64`, `ISize`;
- `Float`, `Float32`.

Operation coverage is a separate contract. Lean 4.34 supplies conversion
operations such as the other `.ofNat` and signed `.ofInt` families, while
ProofScript currently exposes only the subset it has deliberately declared.
Such missing operations are language/library-surface gaps, not a reason to
inject unchecked constants or enlarge the kernel trust boundary.

## Provider compatibility rule

The WASM/native-provider contract is stricter than the general Lean library
coverage contract:

> Every declaration in the **canonical ProofScript provider prelude** must be
> present with the same semantic declaration in every current checking provider.

A Lean type that is merely available in `Init` or `Std` is not automatically
part of this contract. A ProofScript prelude extension such as `UInt8.ofNat`
is. This is why the stale bundled WASM snapshot was a provider-compatibility
defect while, for example, the currently unexposed `Int8.ofNat` is a
ProofScript feature-surface gap shared by all providers.

## Generated evidence

The CI workflow emits:

- `lean-type-surfaces.tsv`;
- `lean434-type-surfaces.json`;
- `lean434-type-coverage.json`;
- `lean434-type-coverage-summary.json`;
- exact Init/Std/Lean beyond-surface lists;
- the canonical ProofScript prelude snapshot used for comparison.

These are bounded compatibility inventories for Lean 4.34.0. They are not a
claim that ProofScript implements the whole Lean standard library, compiler,
Meta API, or all behavior associated with every listed type.
