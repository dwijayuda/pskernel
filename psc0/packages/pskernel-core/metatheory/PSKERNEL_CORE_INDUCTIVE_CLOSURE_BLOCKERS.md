# PSKernel Core inductive closure: bootstrap primitive boundary

Status: **user-authorized migration implemented; cloud validation pending**.
The user explicitly approved the three-operation specification/API migration.
The historical investigation below explains the former opaque-primitive gap.
Actual equality now uses specified cursor operations, and candidates use specified
append. Concrete reflexivity and candidate injectivity proofs need no primitive
hypotheses; freshness retains only existing positive StringEq soundness.
Portable prelude additions are definition aliases, not new axiom declarations.
Old names and primitive IR operations remain supported. No equality theorem
between opaque and specified Lean constants is claimed.

## Proved progress

Full proof/native [#779](https://github.com/dwijayuda/pskernel/actions/runs/37903458196)
and [#780](https://github.com/dwijayuda/pskernel/actions/runs/37903951937) establish:

- Exact skipped-candidate search history and a counting proof excluding fuel
  exhaustion under explicit finite candidate distinctness.
- Unconditional decimal representation injectivity:
  `psKernelNatToString_injective`, using pinned Lean's checked digit round trip.
- Candidate distinctness conditional only on append for the actual nonzero
  prefixed decimal strings.
- Comparator reflexivity conditional on end detection and strict cursor
  advancement. It needs no additional character-equality specification.
- Composition into
  `psKernelSimpleFreshElimName_fresh_of_primitive_obligations`.
  This theorem is **conditional**.

## Remaining actual-source obligations

The actual executable still calls opaque `String.Internal.append`,
`String.Internal.atEnd`, and `String.Internal.next`.
No kernel-checked bridge for those actual declarations has been established.
Standard specified operations share their external native symbols, but that
does not establish equality between the Lean declarations.

Existing trusted premises remain `PsKernelNativeReductionSoundLaw` and
`PsKernelStringEqSoundLaw`. Neither comparator reflexivity nor the three
primitive properties has been adopted as a new trusted law. No production
semantic defect is asserted, and no acceptance criteria have been weakened.

## Concrete evaluated resolution

See [PSKERNEL_CORE_BOOTSTRAP_PRIMITIVE_RESOLUTION.md](PSKERNEL_CORE_BOOTSTRAP_PRIMITIVE_RESOLUTION.md)
for the exact three statements, checked reference operations, pinned primary
sources, evaluated alternatives, and the proposed migration scope.

The recommended engineering route uses the specified standard operations,
retaining the same native external symbols. The portable erasure registries
currently recognize the opaque names, so primitive aliases/prelude support
must also be checked before adoption.

This would be a production primitive API migration for proof/specification
closure. The user's existing instruction forbids changing production merely
to simplify proofs unless correcting a confirmed semantic defect. Applying
this route therefore needs an explicit exception to that source-change
constraint; it is not authorized merely by the existence of the proof gap.

## Incomplete acceptance work

Complete ordinary well-formed extension, full mutual and nested admission
transactions, final Kernel/API/session composition, full semantic audit,
integration reconciliation, and final acceptance gates remain incomplete.
The primitive gap does not imply that all independent transaction lemmas
must stop; mutual recursor semantic work has continued alongside this research.
