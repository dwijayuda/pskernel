# PSKernel bootstrap primitive proof boundary: evaluated resolution

Status: **user-authorized migration implemented; cloud validation pending**.
The user explicitly approved the three-operation specification/API migration.
The historical investigation below explains the former opaque-primitive gap.
Actual equality now uses specified cursor operations, and candidates use specified
append. Concrete reflexivity and candidate injectivity proofs need no primitive
hypotheses; freshness retains only existing positive StringEq soundness.
Portable prelude additions are definition aliases, not new axiom declarations.
Old names and primitive IR operations remain supported. No equality theorem
between opaque and specified Lean constants is claimed.

## What the investigation established

Pinned Lean identity:
`293d5d0c0c3f3dded4688b3ccd6a33939ac5102b` (Lean 4.34.0).

1. `Nat.ofDigitChars_ten_toDigits` is a checked decimal round-trip theorem.
   Applying it to `Int.repr (Int.ofNat n)` proves
   `psKernelNatToString_injective`. Decimal injectivity is no longer a missing
   primitive specification.
2. The actual bounded search now has an exact trace theorem recording every
   skipped candidate. Distinctness of the first `length params + 1` candidates,
   together with existing positive comparison soundness, excludes exhaustion.
   This is proved by list membership and the no-duplicates subset length bound.
3. Self-comparison needs only cursor end detection and strict advancement.
   It needs no character-decoding specification: both character reads are
   identical. The implemented fuel is sufficient under those two cursor facts.
4. Candidate distinctness needs an append bridge only for the actual
   `"u_" ++ decimal(n)` family. It does not need a specification for arbitrary
   string-processing operations.
5. The actual candidates are `u`, `u_1`, `u_2`, ... (the nonzero value is
   represented directly). The proofs follow that executable definition.

Full proof/native CI #779 validates the search trace/counting and mutual
recursor typing. Full proof/native CI #780 validates decimal injectivity,
the primitive-obligation decomposition, and mutual rule/header metadata.
The theorem assumptions remain explicit:
`psKernelSimpleFreshElimName_fresh_of_primitive_obligations` is conditional.

## The three unresolved statements

```lean
-- Only the nonzero candidate family requires this append bridge:
∀ n : Nat, 0 < n →
  String.Internal.append "u_" (psKernelNatToString n) =
    String.append "u_" (psKernelNatToString n)

-- These two statements are sufficient for comparator reflexivity:
∀ (s : String) (p : Nat), s.utf8ByteSize ≤ p →
  String.Internal.atEnd s (String.Pos.Raw.mk p) = true

∀ (s : String) (p : Nat),
  String.Internal.atEnd s (String.Pos.Raw.mk p) = false →
    p < (String.Internal.next s (String.Pos.Raw.mk p)).byteIdx
```

They are theorem arguments, not axioms, accepted trust assumptions, or claims
deduced from one-direction `PsKernelStringEqSoundLaw`.

## Evaluated options

| Option | Consequence | Evaluation |
|---|---|---|
| Use standard append lemmas directly on Internal.append | Conflates separate Lean constants | Invalid without a bridge |
| Test many strings or use native evaluation | Gives execution evidence, not quantified checked equality of the constants | Useful conformance evidence only |
| Assume the three statements | Enlarges the trusted/conditional boundary | Requires explicit authorization; not adopted |
| Supply a checked theorem for the actual opaque primitives | Would close the actual-source obligation | No such bridge established by the pinned-source investigation |
| Move the relevant production calls to Lean's specified standard operations | Gives checked definitions while retaining the existing external native symbols | Recommended concrete engineering route, pending the user's exception to the source-change constraint |

The recommended route is a source-level primitive API migration, not evidence
of an observed native append/cursor defect. It is therefore outside the earlier
authorization to correct confirmed production semantic defects.

## Concrete migration scope for review

The relevant substitutions are:

| Actual opaque operation | Specified operation | Native external symbol |
|---|---|---|
| `String.Internal.append` for elimination-name candidates | `String.append` | `lean_string_append` |
| `String.Internal.atEnd` in equality traversal | `String.Pos.Raw.atEnd` | `lean_string_utf8_at_end` |
| `String.Internal.next` in equality traversal | `String.Pos.Raw.next` | `lean_string_utf8_next` |

Production locations are
`src/Ps/KernelCore/Admission/Inductive/Types.lean` (candidate generator) and
`src/Ps/KernelCore/Core/Name.lean` (bounded equality traversal).
Keep candidate formatting, traversal fuel, branch order and failure behavior.
A wider migration of diagnostics, comparison ordering or other String.Internal
calls is not needed for these freshness obligations.

Pinned standard `String.append` has a checked byte-array body.
`String.Pos.Raw.atEnd` compares the byte position with the byte length.
`String.Pos.Raw.next` has checked strict advancement via
`String.Pos.Raw.byteIdx_lt_byteIdx_next`.
The metatheory reference lemmas demonstrate these cursor facts separately;
they do not claim equality with the opaque declarations.

Using the same external symbols supports native code-path continuity. It does
not establish formal source equality, compiler correctness, self-host
portability, or JavaScript/Wasm behavior. Those remain migration validation
obligations. The current proof-branch erasure registries recognize the opaque names:
`packages/erasure/src/text-primitive-erasure.ts` and
`psc15selfhost/packages/erasure/src/Ps/Erasure/Expr.lean`; the portable builtin
names are in `psc15selfhost/packages/core/src/Ps/Core/Builtin.lean`.
They do not currently list the three specified replacements in those dispatches.
A safe migration must account for those aliases and prelude declarations;
changing kernel call sites alone is not yet a validated portable solution.
Before adoption, preserve portable kernel constraints and run focused
Unicode/candidate-collision/equality tests and full proof/native conformance.
Do not move host-only code, Arena transport, or new empirical fuel policies
into the kernel.

## Remaining metatheory work

This investigation does not complete ordinary well-formed environment
extension, full mutual or nested transactions, or the final Kernel/API/session
family. Those claims must continue to distinguish proved components from
unresolved primitive and transaction obligations.

## Primary sources

- [Opaque bootstrap declarations](https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/Init/Data/String/Bootstrap.lean)
- [Checked append and injectivity](https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/Init/Data/String/Defs.lean)
- [Checked cursor definitions and progress](https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/Init/Data/String/Basic.lean)
- [Checked decimal round trip](https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/Init/Data/Nat/ToString.lean)
- [Integer representation](https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/Init/Data/Int/Repr.lean)
- [Native append and next](https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/runtime/object.cpp)
- [Lean FFI reference](https://lean-lang.org/doc/reference/latest/Run-Time-Code/Foreign-Function-Interface/)

## Dependency-complete cursor scope

Cloud proof #787 exposed that the two acceleration hash workers must share
the equality traversal's cursor API for their existing unconditional structural
hash-compatibility proofs. Their cursor calls are migrated identically; mix
functions, seeds, modulus, fuel and traversal control flow are preserved.
The CacheHash and EnvironmentIndexHash theorem statements remain unchanged.
Native differential tests compare both hash workers to the legacy cursor
implementation. The TypeScript package/erasure suite passed in #787.
This is migration dependency closure, not a claimed hash defect or a new trust law.

Validation #788 passed full proofs, native foundation conformance and TypeScript
packages. The added portable Lean gate exposed a prelude expression-constructor
spelling mismatch; the aliases now use the actual portable `PsExpr.constE`.
The full migration gate is pending a successful rerun.
