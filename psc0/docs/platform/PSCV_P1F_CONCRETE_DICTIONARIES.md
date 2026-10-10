# PSCV P1-F — concrete instance witness candidates, not a class dependency proof

The P1-E Lean 4.35.0-rc3 `#synth` results were generic for `HAdd`,
`HMul`, `HSub` and `BEq`. A generic implementation name does not show
which concrete `Add Nat`, `Mul Nat`, `Sub Nat`, `DecidableEq Nat`
or `DecidableEq Bool` declaration Lean selected.

This follow-up checks exactly those concrete typeclasses, as well as
`Add Int` and `Append String`, under the actual pinned ambient
`PSCVL.Policy` imported environment. The source is a fixed suite of
`#synth` and `inferInstance` examples, with no additional imports or
registrations allowed by the review validator.

The output is a *candidate layer*: observed concrete terms for typeclass
goals suggested by the previous generic terms. Actual dependency edges,
kernel-level replay, the typed source instance declarations, scope,
priority and equal-tie selection, and precise source blob/line locators
must still be verified before any normative `std.*` ID can be approved.
A source row appearing in these samples is not counted as a resolved ID.

P1 still has **191 unresolved** of 194 required snapshot IDs, the
complete ordered allowed Standard/verification effect registry is absent,
and the protected PSCV-CERT-v1 gate stays closed. P2–P5 remain stagewise
under `docs/platform/PSCV_P1_TO_P5_SOUND_GATES.md`. No kernel, compiler,
bootstrap source, npm runtime, chosen native provider or seed change.
