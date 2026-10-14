import Ps.Environment.StandardUnsignedPower

/-
Pinned Lean 4.35.0 Init/Data/UInt/Basic.lean, commit
eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Copyright Lean FRO, LLC; Apache-2.0; see THIRD_PARTY_NOTICES.md.

Each UIntN.ofInt converts an Int to its nonnegative residue modulo 2^N.
The checked Int.ofNat/Int.negSucc recursor and modular UIntN.ofNat/neg
compute precisely that residue without a target-width assumption or a
new Int.mod runtime primitive. Reuse the same checked Core constructor
already qualified for Int8/16/32/64.ofInt. For unsigned words Lean uses
the default semireducible definition status, unlike implicit_reducible
signed conversions. Exact original native values and target observations
remain independent qualification gates.
-/

def psStandardUnsignedOfIntDeclarations : List PsDeclaration :=
  ["UInt8", "UInt16", "UInt32", "UInt64"].map
    psStandardWrappingOfIntDeclaration

def psStandardUnsignedOfIntExtend (environment : PsEnvironment) : PsEnvironment :=
  psStandardUnsignedOfIntDeclarations.foldl psEnvironmentInsert environment

def psStandardUnsignedOfIntRuntimeDeclarations : List PsDeclaration :=
  psStandardUnsignedOfIntDeclarations
