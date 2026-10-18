import Ps.Environment.StandardUnsignedOrder

/-
Pinned Lean 4.35.0 Init/Data/UInt/Basic.lean, commit
eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Copyright Lean FRO, LLC; Apache-2.0; see THIRD_PARTY_NOTICES.md.

UInt8/16/32/64.pow are ordinary primitive recursions on Nat:
x^0 = 1, x^(n+1) = UIntN.mul (UIntN.pow x n) x.
Reuse the *same* checked Core builder as Int8/16/32/64.pow to retain
identical recurrence, binder ownership and typed erasure. This adds
no target compiler intrinsic, axiom or platform-size assumption.
-/

def psStandardUnsignedPowerDeclarations : List PsDeclaration :=
  ["UInt8", "UInt16", "UInt32", "UInt64"].map psStandardFixedWidthPower

def psStandardUnsignedPowerExtend (environment : PsEnvironment) : PsEnvironment :=
  psStandardUnsignedPowerDeclarations.foldl psEnvironmentInsert environment

def psStandardUnsignedPowerRuntimeDeclarations : List PsDeclaration :=
  psStandardUnsignedPowerDeclarations
