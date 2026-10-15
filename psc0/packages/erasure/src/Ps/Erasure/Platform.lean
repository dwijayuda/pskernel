import Ps.Erasure.Unsigned
import Ps.CompilerIr.CheckTypes

/-!
Explicit target-word contracts for Lean 4.35.0.
References: Init/Prelude.lean, UInt/Basic{,Aux}.lean, SInt/Basic.lean,
and Lean/Compiler/LCNF/Simp/ConstantFold.lean. The logical environment
retains opaque getNumBits; only executable IR uses the requested width.
No backend discovers a source width from its host or memory addressing mode.
-/
namespace PsPlatformRuntime

inductive Operation where
  | bits | getBits | size | minimum | maximum | power
  | ofInt | toInt | ofNatClamp | ofIntClamp | toNatClamp | abs
  | compare (operation : PsVerifiedIrIntegerCompareOp)
  | convert (source target : PsVerifiedIrMachineIntegerType)

def entry (name : PsName) : Option (PsVerifiedIrMachineIntegerType × Operation) := do
  match psNameToString name with
  | "System.Platform.numBits" => return (.usize, .bits)
  | "System.Platform.getNumBits" => return (.usize, .getBits)
  | "instDecidableEqUSize" => return (.usize, .compare .eq)
  | _ =>
    let .str owner method := name | none
    let text := psNameToString owner
    if text == "USize" || text == "ISize" then
      let word : PsVerifiedIrMachineIntegerType := if text == "USize" then .usize else .isize
      let operation ← match method with
        | "size" => some Operation.size
        | "pow" => some .power
        | "minValue" => if text == "ISize" then some .minimum else none
        | "maxValue" => if text == "ISize" then some .maximum else none
        | "ofInt" => some .ofInt
        | "toInt" => if text == "ISize" then some .toInt else none
        | "ofNatClamp" => if text == "USize" then some .ofNatClamp else none
        | "ofIntClamp" => if text == "ISize" then some .ofIntClamp else none
        | "toNatClampNeg" => if text == "ISize" then some .toNatClamp else none
        | "abs" => if text == "ISize" then some .abs else none
        | "decEq" => some (.compare .eq)
        | "decLt" => some (.compare .lt)
        | "decLe" => some (.compare .le)
        | _ => do
          if !method.startsWith "to" then none else do
          let targetName := psRootName (method.drop 2).toString
          let target ← if text == "USize" then
              (psErasureUnsignedWidth targetName).orElse
                (fun _ => if method == "toISize" then some .isize else none)
            else psErasureSignedWidth targetName
          return .convert word target
      return (word, operation)
    else if method == "toUSize" then
      return (.usize, .convert (← psErasureUnsignedWidth owner) .usize)
    else if method == "toISize" then
      return (.isize, .convert (← psErasureSignedWidth owner) .isize)
    else none

def arity (name : PsName) : Option Nat := do
  let (_, operation) ← entry name
  return match operation with
    | .bits | .size | .minimum | .maximum => 0
    | .compare _ | .power => 2
    | _ => 1

private def natural (n : Nat) : PsVerifiedIrExpr := .literal (.natural n)
private def integer (n : Int) : PsVerifiedIrExpr := .literal (.integer n)
private def op (code : PsVerifiedIrIntrinsic) (values : List PsVerifiedIrExpr) :
    PsVerifiedIrExpr := .intrinsic code [] values

-- A fresh local evaluates each input exactly once. Values are evaluated outside
-- the binder, so nested conversion builders cannot capture their caller's locals.
private def bind (scope : PsErasureScope) (type : PsVerifiedIrType)
    (value : PsVerifiedIrExpr) (body : PsVerifiedIrExpr → PsVerifiedIrExpr) :
    PsVerifiedIrExpr :=
  let name := psErasureLocalName scope "_psWordValue" "word" 0
  .letE name type value (body (.var name))

private def asNatural (word : PsVerifiedIrMachineIntegerType) (value : PsVerifiedIrExpr) :
    Except PsErasureError PsVerifiedIrExpr := do
  if psIrMachineIntegerIsSigned word then
    let some unsigned := psErasureSignedUnsignedWidth word | throw .unsupportedRuntimeTerm
    return op (.unsignedToNat unsigned) [op (.signedToUnsigned word) [value]]
  else return op (.unsignedToNat word) [value]

private def fromNatural (word : PsVerifiedIrMachineIntegerType) (value : PsVerifiedIrExpr) :
    PsVerifiedIrExpr :=
  op (if psIrMachineIntegerIsSigned word then .signedOfNat word else .unsignedOfNat word) [value]

private def asInteger (scope : PsErasureScope) (word : PsVerifiedIrMachineIntegerType)
    (value : PsVerifiedIrExpr) : Except PsErasureError PsVerifiedIrExpr := do
  let raw ← asNatural word value
  if !psIrMachineIntegerIsSigned word then return op .intOfNat [raw]
  let some bits := psIrMachineIntegerFixedWidth word | throw .unsupportedRuntimeTerm
  return bind scope (.primitive .nat) raw fun raw =>
    .ifE (op .natLt [raw, natural (2 ^ (bits - 1))])
      (op .intOfNat [raw])
      (op .intSub [op .intOfNat [raw], integer (Int.ofNat (2 ^ bits))])

private def fromInteger (scope : PsErasureScope) (word : PsVerifiedIrMachineIntegerType)
    (value : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  bind scope (.primitive .int) value fun value =>
    .ifE (op .intLt [value, integer 0])
      (op (.machineIntBinary word .sub)
        [.literal (.machineInteger word 0),
         fromNatural word (op .intToNat [op .intNeg [value]])])
      (fromNatural word (op .intToNat [value]))

def erase (scope : PsErasureScope)
    (lower : PsExpr → Except PsErasureError PsVerifiedIrExpr) (view : PsErasureAppView) :
    Except PsErasureError (Option PsVerifiedIrExpr) := do
  let .constE name _ := view.head | return none
  let some (word, operation) := entry name | return none
  let word ← psErasureResolveWord scope word
  let some bits := psIrMachineIntegerFixedWidth word | throw .unsupportedRuntimeTerm
  let wordType ← (psIrMachineType word).mapError (fun _ => PsErasureError.unsupportedRuntimeTerm)
  let args ← view.args.mapM lower
  let bound := 2 ^ (bits - 1)
  let min : Int := -(Int.ofNat bound)
  let max : Int := Int.ofNat (bound - 1)
  let result ← match operation, args with
    | .bits, [] => pure (natural bits)
    | .getBits, [unit] => do
      let (subtype, field) ← psErasureSingleRuntimeField scope (psRootName "Subtype")
      pure (bind scope (.primitive .unit) unit fun _ =>
        .record subtype.name [.primitive .nat] [(field.name, natural bits)])
    | .size, [] => pure (natural (2 ^ bits))
    | .minimum, [] => pure (.literal (.machineInteger word min))
    | .maximum, [] => pure (.literal (.machineInteger word max))
    | .power, [value, exponent] => do
      let .str owner _ := name | throw .unsupportedApplication
      let some helper := psErasureLookupName scope.declarationNames
        (psNameAppendStr (psRootName "PsStandard") (psNameToString owner ++ "Pow"))
        | throw .unsupportedApplication
      pure (.call (.var helper) [] [value, exponent])
    | .ofInt, [value] => pure (fromInteger scope word value)
    | .toInt, [value] => asInteger scope word value
    | .toNatClamp, [value] => pure (op .intToNat [← asInteger scope word value])
    | .ofNatClamp, [value] =>
      pure (bind scope (.primitive .nat) value fun value =>
        fromNatural word (.ifE (op .natLt [value, natural (2 ^ bits)])
          value (natural (2 ^ bits - 1))))
    | .ofIntClamp, [value] =>
      pure (fromInteger scope word
        (bind scope (.primitive .int) value fun value =>
          .ifE (op .intLt [value, integer min]) (integer min)
            (.ifE (op .intLt [integer max, value]) (integer max) value)))
    | .abs, [value] =>
      pure (bind scope wordType value fun value =>
        .ifE (op (.machineIntCompare word .lt) [value, .literal (.machineInteger word 0)])
          (op (.machineIntBinary word .sub) [.literal (.machineInteger word 0), value]) value)
    | .compare operation, [a,b] => pure (op (.machineIntCompare word operation) [a,b])
    | .convert source target, [value] => do
      let source ← psErasureResolveWord scope source
      let target ← psErasureResolveWord scope target
      if psIrMachineIntegerIsSigned source then
        pure (fromInteger scope target (← asInteger scope source value))
      else pure (fromNatural target (← asNatural source value))
    | _, _ => throw .unsupportedApplication
  return some result

end PsPlatformRuntime
