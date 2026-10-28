import Ps.CompilerIr.Specialize
import Lean

/-! Immutable pre-optimization function and a kernel-checked extensional equality.
This proves the bounded key function, not compiler preservation or self-hosting. -/
namespace Ps.Test.SpecializationTypeKey

def referenceTypeKeyWithFuel (fuel : Nat) : PsVerifiedIrType -> Option String :=
  match fuel with
  | 0 => fun (type : PsVerifiedIrType) => Option.none
  | remaining + 1 =>
      let smaller : PsVerifiedIrType -> Option String := referenceTypeKeyWithFuel remaining;
      fun (type : PsVerifiedIrType) =>
        match type with
        | PsVerifiedIrType.unknown => Option.none
        | PsVerifiedIrType.typeParameter _ => Option.none
        | PsVerifiedIrType.primitive primitive => Option.some (psIrSpecializePrimitiveKey primitive)
        | PsVerifiedIrType.function parameters result =>
            let parameterKeys : List (Option String) := psListMap smaller parameters;
            match psIrSpecializeJoinKeys parameterKeys with
            | Option.none => Option.none
            | Option.some parameterKey =>
                match smaller result with
                | Option.none => Option.none
                | Option.some resultKey =>
                    Option.some (psIrSpecializeConcat4 "Fn$" parameterKey "$To$" resultKey)
        | PsVerifiedIrType.named name arguments =>
            let argumentKeys : List (Option String) := psListMap smaller arguments;
            match psIrSpecializeJoinKeys argumentKeys with
            | Option.none => Option.none
            | Option.some keys =>
                if psStringEq keys "" then Option.some (String.Internal.append "N$" name)
                else Option.some (psIrSpecializeConcat4 "N$" name "$" keys)


theorem saturated_eq_reference (fuel : Nat) :
    psIrSpecializeTypeKeyWithFuel fuel = referenceTypeKeyWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ remaining same =>
      funext type
      simpa only [psIrSpecializeTypeKeyWithFuel, referenceTypeKeyWithFuel, same]

def nested : Nat → PsVerifiedIrType
  | 0 => PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
  | n + 1 => PsVerifiedIrType.named "Box" [nested n]

def examples : List PsVerifiedIrType :=
  [PsVerifiedIrType.unknown, PsVerifiedIrType.typeParameter "α",
   PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat,
   PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int,
   PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool,
   PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.char,
   PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.string,
   PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.unit,
   PsVerifiedIrType.named "Unicode😀" [],
   PsVerifiedIrType.function [nested 2, nested 3] (nested 4),
   nested 62, nested 63, nested 64, nested 65]

end Ps.Test.SpecializationTypeKey

#print axioms Ps.Test.SpecializationTypeKey.saturated_eq_reference

def main : IO Unit := do
  let mut cases := 0
  for fuel in List.range 66 do
    for type in Ps.Test.SpecializationTypeKey.examples do
      unless psIrSpecializeTypeKeyWithFuel fuel type ==
          Ps.Test.SpecializationTypeKey.referenceTypeKeyWithFuel fuel type do
        throw (IO.userError "PSC1_SPECIALIZATION_TYPE_KEY_CHANGED")
      cases := cases + 1
  unless psIrSpecializeTypeKey (Ps.Test.SpecializationTypeKey.nested 63) != Option.none &&
      psIrSpecializeTypeKey (Ps.Test.SpecializationTypeKey.nested 64) == Option.none do
    throw (IO.userError "PSC1_SPECIALIZATION_TYPE_KEY_FUEL_BOUND")
  IO.println ("PSC1_SPECIALIZATION_TYPE_KEY_PASS cases=" ++ toString cases ++
    " fuel64-unchanged; extensional equality kernel checked")
