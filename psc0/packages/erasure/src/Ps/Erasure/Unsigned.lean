import Ps.Erasure.Basic

-- Lean 4.35.0 keeps UInt's checked BitVec/Fin model and assigns a primitive
-- runtime representation. Only these four target-independent widths are enabled.
def psErasureUnsignedWidth (owner : PsName) : Option PsVerifiedIrMachineIntegerType :=
  match psNameToString owner with
  | "UInt8" => some .uint8 | "UInt16" => some .uint16
  | "UInt32" => some .uint32 | "UInt64" => some .uint64
  | _ => none

def psErasureUnsignedEntryArity (name : PsName) : Option Nat :=
  match name with
  | .str owner method =>
    if (psErasureUnsignedWidth owner).isSome then
      match method with
      | "ofNat" | "ofBitVec" | "toNat" | "toBitVec" | "toFin" => some 1
      | "ofNatLT" => some 2
      | _ => none
    else if psNameToString owner == "BitVec" then
      match method with
      | "ofNat" | "toNat" | "toFin" => some 2
      | "ofNatLT" => some 3
      | _ => none
    else none
  | _ => none

-- Reuse prepared fields and target identities. The callers own the checked
-- bound invariant; this is never an automatic foreign construction adapter.
def psErasureBoundedField (scope : PsErasureScope) (owner : String) :
    Except PsErasureError (PsRuntimeStructureInfo × PsRuntimeStructureField) := do
  let some info := psErasureLookupStructure scope.runtimeStructures (psRootName owner)
    | throw .unsupportedRuntimeTerm
  let [field] := info.fields | throw .unsupportedRuntimeTerm
  if info.unboxed || !info.typeParameters.isEmpty then throw .unsupportedRuntimeTerm
  return (info, field)

def psEraseBoundedWrap (scope : PsErasureScope) (value : PsVerifiedIrExpr) (bitvec : Bool) :
    Except PsErasureError PsVerifiedIrExpr := do
  let (fin, val) ← psErasureBoundedField scope "Fin"
  let value := PsVerifiedIrExpr.record fin.name [] [(val.name, value)]
  if !bitvec then return value
  let (bits, toFin) ← psErasureBoundedField scope "BitVec"
  return .record bits.name [] [(toFin.name, value)]

def psEraseBitVecNatural (scope : PsErasureScope) (value : PsVerifiedIrExpr) :
    Except PsErasureError PsVerifiedIrExpr := do
  let (bits, toFin) ← psErasureBoundedField scope "BitVec"
  let (fin, val) ← psErasureBoundedField scope "Fin"
  return .projection fin.name [] (.projection bits.name [] value toFin.name) val.name

def psEraseUnsignedProjection (scope : PsErasureScope) (width : PsVerifiedIrMachineIntegerType)
    (value : PsVerifiedIrExpr) : Except PsErasureError PsVerifiedIrExpr :=
  psEraseBoundedWrap scope (.intrinsic (.unsignedToNat width) [] [value]) true

def psEraseUnsignedApplication (scope : PsErasureScope)
    (erase : PsExpr → Except PsErasureError PsVerifiedIrExpr) (view : PsErasureAppView) :
    Except PsErasureError (Option PsVerifiedIrExpr) := do
  let .constE (.str owner method) _ := view.head | return none
  if let some width := psErasureUnsignedWidth owner then
    match method, view.args with
    | "ofNat", [value] | "ofNatLT", [value, _] =>
      return some (.intrinsic (.unsignedOfNat width) [] [← erase value])
    | "ofBitVec", [value] =>
      return some (.intrinsic (.unsignedOfNat width) [] [← psEraseBitVecNatural scope (← erase value)])
    | "toNat", [value] =>
      return some (.intrinsic (.unsignedToNat width) [] [← erase value])
    | "toBitVec", [value] =>
      return some (← psEraseUnsignedProjection scope width (← erase value))
    | "toFin", [value] =>
      return some (← psEraseBoundedWrap scope (.intrinsic (.unsignedToNat width) [] [← erase value]) false)
    | _, _ => return none
  else if psNameToString owner == "BitVec" then
    match method, view.args with
    | "ofNat", [width, value] =>
      let modulus := PsVerifiedIrExpr.intrinsic .natPow [] [.literal (.natural 2), ← erase width]
      return some (← psEraseBoundedWrap scope (.intrinsic .natMod [] [← erase value, modulus]) true)
    | "ofNatLT", [_, value, _] => return some (← psEraseBoundedWrap scope (← erase value) true)
    | "toNat", [_, value] => return some (← psEraseBitVecNatural scope (← erase value))
    | "toFin", [_, value] =>
      let (bits, field) ← psErasureBoundedField scope "BitVec"
      return some (.projection bits.name [] (← erase value) field.name)
    | _, _ => return none
  else return none
