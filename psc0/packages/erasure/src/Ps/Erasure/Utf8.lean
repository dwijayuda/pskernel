import Ps.Erasure.Unsigned

-- Nominal ByteArray storage remains checked structure metadata. Only its
-- Array UInt8 payload crosses the three typed primitive contracts.
namespace PsUtf8Runtime
def entry (name : PsName) : Option PsVerifiedIrIntrinsic :=
  match psNameToString name with
  | "String.toUTF8" => some .stringToUtf8
  | "ByteArray.validateUTF8" => some .utf8Valid
  | "$psc0Utf8.decode" => some .utf8Decode
  | _ => none

def arity (name : PsName) : Option Nat := (entry name).map fun _ => 1

def erase (scope : PsErasureScope)
    (lower : PsExpr → Except PsErasureError PsVerifiedIrExpr) (view : PsErasureAppView) :
    Except PsErasureError (Option PsVerifiedIrExpr) := do
  let .constE name _ := view.head | return none
  let some operation := entry name | return none
  let [argument] := view.args | throw .unsupportedApplication
  let (info,field) ← psErasureSingleRuntimeField scope (psRootName "ByteArray")
  let value ← lower argument
  let result : PsVerifiedIrExpr := match operation with
    | .stringToUtf8 => .record info.name []
        [(field.name, .intrinsic operation [] [value])]
    | _ => .intrinsic operation [] [.projection info.name [] value field.name]
  return some result
end PsUtf8Runtime
