# PSKernel Core inductive closure: unresolved bootstrap primitive bridge

Status: **incomplete; no new trusted premise adopted**.

## Concrete obligation

The ordinary recursor appends a fresh elimination universe to declaration level
parameters when large elimination is permitted. Complete universe scoping and
name freshness require that the actual selected name is not already declared.

Production `psKernelSimpleElimNameCandidate` constructs `u` and then
`String.Internal.append "u_" (psKernelNatToString n)`.
`psKernelNatToString n` is `Int.repr (Int.ofNat n)`.
`psKernelSimpleFreshElimNameAux` searches with bounded fuel; at fuel zero it
returns a candidate without checking membership. Its root fuel is one plus the
number of declared universe parameters.

The registered `AdmissionEliminationNameConfiguration.lean` candidate proves
the exact search exit disjunction: an unchecked fuel-boundary candidate, or a
candidate for which executable membership is false. This does not remove the
boundary alternative and does not prove unconditional name freshness.

## Why existing named laws do not discharge it

In pinned Lean 4.34 commit
`293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`,
`src/Init/Data/String/Bootstrap.lean` declares
`String.Internal.append` as an opaque external function
(`lean_string_append`). The same file declares the opaque cursor
`next`, `atEnd`, and `get` operations used by PSKernel's comparator.
No checked append/distinctness bridge has been established in this proof tree.

`PsKernelStringEqSoundLaw` restricts positive comparator results.
`PsKernelStringEqReflexiveLaw` restricts comparison of a string with itself.
Neither law specifies append or decimal representation, or says that generated
candidates are distinct. It is unsound to infer those properties from the two
comparator laws. Abstractly, an unspecified append operation could map every
candidate suffix to the same string while equality itself remains sound and
reflexive. This is a missing primitive specification, **not evidence of a bug
in Lean's actual native append implementation**.

A kernel-checked specification/representation bridge for these actual pinned
bootstrap primitives is needed to prove candidate distinctness and discharge
the bounded search non-exhaustion argument. It has not been supplied by adding
an axiom, renaming a law, strengthening an existing trusted law, assuming
distinctness, or changing production generation merely for proof convenience.

## Trusted, conditional, and incomplete boundaries

- Existing named trusted premises: `PsKernelNativeReductionSoundLaw` and
  `PsKernelStringEqSoundLaw`.
- Comparator reflexivity remains an **unresolved explicit conditional
  obligation**. It is not an adopted additional TCB law.
- Candidate distinctness, generated universe freshness, and their primitive
  bridge remain **unproved**, rather than new trusted assumptions.
- Independent ordinary publication evidence does not claim full environment
  well-formedness while this obligation remains open.
- Full mutual recursor/header transaction and nested flatten/rebase/restore
  semantics, final Kernel/API/session family, full audit, integration
  reconciliation and final acceptance gates remain incomplete.

## Pinned standard-library bridge check — 2026-10-09

The pinned `src/Init/Data/String/Defs.lean` defines `String.append`
with a checked byte-array body and proves `String.toByteArray_append`,
`String.append_left_inj`, and `String.append_right_inj`.
These results concern the standard `String.append`/`++` operation.

The executable candidate generator instead calls the separately declared
opaque `String.Internal.append` from `Bootstrap.lean`. Both declarations
carry the native symbol `lean_string_append`, but sharing an external symbol
does not establish a kernel-checked equality of the Lean declarations.
Consequently the standard append injectivity theorem cannot simply be applied
to the actual candidate expression. The missing bridge must relate these
specific declarations (or specify the internal operation directly).
This check narrows the missing obligation; it does not prove that no bridge
could exist elsewhere, prove freshness, or authorize a production rewrite.

Pinned checked append definition and lemmas:
https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/Init/Data/String/Defs.lean

## Required intervention

Identify/provide a kernel-checked bridge applicable to the pinned opaque
bootstrap operations, or explicitly revise the permitted proof boundary.
A new trusted primitive law or a production reimplementation is not authorized
by the current constraints. No such change has been made.

Primary source:
https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/Init/Data/String/Bootstrap.lean

Executable source:
https://github.com/dwijayuda/pskernel/blob/dc7395c18a5536577dc2865bc44203e455f732c4/psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Admission/Inductive/Types.lean
