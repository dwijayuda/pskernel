import Ps.Core.Builtin
import Ps.Core.Expr
import Ps.Core.Subst

/-!
Pure scalar operations for selected #eval feedback, never kernel conversion.
The representations follow the existing checked scalar bridge and Lean 4.35.0
Init/Prelude and Init/Data/Float/{Float,Float32}.lean (Apache-2.0,
Microsoft Corporation / Lean FRO, LLC). No effectful operation is registered.
-/

def psInspectionNatural : PsExpr → Option Nat
  | .lit (.natural value) => some value
  | .constE name _ => if psNameEq name psNatZeroName then some 0 else none
  | _ => none

def psInspectionInteger : PsExpr → Option Int
  | .app (.constE name _) value => do
    let value ← psInspectionNatural value
    if psNameEq name psIntOfNatName then some (.ofNat value)
    else if psNameEq name psIntNegSuccName then some (.negSucc value) else none
  | _ => none

def psInspectionIntegerExpr : Int → PsExpr
  | .ofNat value => .app (.constE psIntOfNatName []) (.lit (.natural value))
  | .negSucc value => .app (.constE psIntNegSuccName []) (.lit (.natural value))

def psInspectionCharacter : PsExpr → Option Char
  | .app (.constE name _) value => do
    if !psNameEq name psCharOfNatName then none
    else return Char.ofNat (← psInspectionNatural value)
  | _ => none

def psInspectionString : PsExpr → Option String
  | .lit (.string value) => some value
  | _ => none

def psInspectionBooleanExpr (value : Bool) : PsExpr :=
  .constE (if value then psBoolTrueName else psBoolFalseName) []

def psInspectionBuiltinName (text : String) : PsName :=
  (text.splitOn ".").foldl psNameAppendStr .anonymous

def psInspectionCall (name : String) (arguments : List PsExpr) : PsExpr :=
  psExprApplyMany (.constE (psInspectionBuiltinName name) []) arguments

def psInspectionBool : PsExpr → Option Bool
  | .constE name _ =>
    if psNameEq name psBoolTrueName then some true
    else if psNameEq name psBoolFalseName then some false else none
  | _ => none

-- Read checked Model/UInt projections and return the actual checked ofBits
-- constructor path. No inspection rule fabricates Model validity evidence.
def psInspectionFloatEntry (name : PsName) : Option (Bool × String × Nat) := do
  let .str owner method := name | none
  let is32 ←
    if psNameEq owner psFloatName then some false
    else if psNameEq owner psFloat32Name then some true else none
  if ["nan", "inf"].contains method then return (is32, method, 0)
  if ["add", "sub", "mul", "div", "beq", "lt", "le"].contains method then
    return (is32, method, 2)
  if ["neg", "abs", "isNaN", "isInf", "isFinite", "toString"].contains method then
    return (is32, method, 1)
  if (!is32 && method == "toFloat32") || (is32 && method == "toFloat") then
    return (is32, method, 1)
  none

def psInspectionFloatExpr (is32 : Bool) (bits : Nat) : PsExpr :=
  psInspectionCall (if is32 then "Float32.ofBits" else "Float.ofBits")
    [psInspectionCall (if is32 then "UInt32.ofNat" else "UInt64.ofNat")
      [.lit (.natural bits)]]

def psInspectionScalarInput (name : PsName) (argument : PsExpr) : PsExpr :=
  if psNameEq name (psRootName "mixHash") then
    psInspectionCall "UInt64.toNat" [argument]
  else match psInspectionFloatEntry name with
    | some (is32, _, _) =>
      psInspectionCall (if is32 then "UInt32.toNat" else "UInt64.toNat")
        [psInspectionCall (if is32 then "Float32.toBits" else "Float.toBits") [argument]]
    | none => argument

def psInspectionPlatformProjection (owner : PsName) (index : Nat) (major : PsExpr) :
    Option PsExpr :=
  if !psNameEq owner (psRootName "Subtype") || index != 0 then none else
    match major with
    | .app (.constE name _) _ =>
      if psNameEq name (psInspectionBuiltinName "System.Platform.getNumBits") then
        some (.lit (.natural System.Platform.numBits))
      else none
    | _ => none

def psInspectionScalarArity (name : PsName) : Option Nat :=
  if let some (_, _, arity) := psInspectionFloatEntry name then some arity
  else if psNameEq name (psInspectionBuiltinName "System.Platform.numBits") then some 0
  else if psNameEq name (psRootName "mixHash") then some 2
  else if psNameEq name (psInspectionBuiltinName "String.hash") ||
      psNameEq name (psInspectionBuiltinName "System.Platform.getNumBits") then some 1
  else if [psIntNegName, psIntReprName, psCharOfNatName, psCharToNatName,
      psStringSingletonName, psStringLengthName, psStringUtf8ByteSizeName,
      psStringPosRawMkName, psStringPosRawByteIdxName].any (psNameEq name) then some 1
  else if [psIntAddName, psIntSubName, psIntMulName, psNatBltName,
      psStringPushName, psStringAppendName, psStringGetName,
      psStringNextName, psStringAtEndName].any (psNameEq name) then some 2
  else if psNameEq name psStringExtractName then some 3 else none

def psInspectionFloatEval (is32 : Bool) (method : String) (arguments : List PsExpr) :
    Option PsExpr := do
  if is32 then
    let read := fun expression => do
      return Float32.ofBits (UInt32.ofNat (← psInspectionNatural expression))
    let result := fun (value : Float32) => psInspectionFloatExpr true value.toBits.toNat
    match method, arguments with
    | "nan", [] => return result Float32.nan
    | "inf", [] => return result Float32.inf
    | "add", [a, b] => return result (Float32.add (← read a) (← read b))
    | "sub", [a, b] => return result (Float32.sub (← read a) (← read b))
    | "mul", [a, b] => return result (Float32.mul (← read a) (← read b))
    | "div", [a, b] => return result (Float32.div (← read a) (← read b))
    | "beq", [a, b] => return psInspectionBooleanExpr (Float32.beq (← read a) (← read b))
    | "lt", [a, b] => return psInspectionBooleanExpr (Float32.lt (← read a) (← read b))
    | "le", [a, b] => return psInspectionBooleanExpr (Float32.le (← read a) (← read b))
    | "neg", [a] => return result (Float32.neg (← read a))
    | "abs", [a] => return result (Float32.abs (← read a))
    | "isNaN", [a] => return psInspectionBooleanExpr (Float32.isNaN (← read a))
    | "isInf", [a] => return psInspectionBooleanExpr (Float32.isInf (← read a))
    | "isFinite", [a] => return psInspectionBooleanExpr (Float32.isFinite (← read a))
    | "toString", [a] => return .lit (.string (Float32.toString (← read a)))
    | "toFloat", [a] => return psInspectionFloatExpr false (Float32.toFloat (← read a)).toBits.toNat
    | _, _ => none
  else
    let read := fun expression => do
      return Float.ofBits (UInt64.ofNat (← psInspectionNatural expression))
    let result := fun (value : Float) => psInspectionFloatExpr false value.toBits.toNat
    match method, arguments with
    | "nan", [] => return result Float.nan
    | "inf", [] => return result Float.inf
    | "add", [a, b] => return result (Float.add (← read a) (← read b))
    | "sub", [a, b] => return result (Float.sub (← read a) (← read b))
    | "mul", [a, b] => return result (Float.mul (← read a) (← read b))
    | "div", [a, b] => return result (Float.div (← read a) (← read b))
    | "beq", [a, b] => return psInspectionBooleanExpr (Float.beq (← read a) (← read b))
    | "lt", [a, b] => return psInspectionBooleanExpr (Float.lt (← read a) (← read b))
    | "le", [a, b] => return psInspectionBooleanExpr (Float.le (← read a) (← read b))
    | "neg", [a] => return result (Float.neg (← read a))
    | "abs", [a] => return result (Float.abs (← read a))
    | "isNaN", [a] => return psInspectionBooleanExpr (Float.isNaN (← read a))
    | "isInf", [a] => return psInspectionBooleanExpr (Float.isInf (← read a))
    | "isFinite", [a] => return psInspectionBooleanExpr (Float.isFinite (← read a))
    | "toString", [a] => return .lit (.string (Float.toString (← read a)))
    | "toFloat32", [a] => return psInspectionFloatExpr true (Float.toFloat32 (← read a)).toBits.toNat
    | _, _ => none

def psInspectionScalarEval (name : PsName) (arguments : List PsExpr) : Option PsExpr := do
  if let some (is32, method, _) := psInspectionFloatEntry name then
    return ← psInspectionFloatEval is32 method arguments
  match arguments with
  | [] =>
    if psNameEq name (psInspectionBuiltinName "System.Platform.numBits") then
      return .lit (.natural System.Platform.numBits)
    none
  | [first] =>
    if psNameEq name (psInspectionBuiltinName "String.hash") then
      return psInspectionCall "UInt64.ofNat" [.lit (.natural (String.hash (← psInspectionString first)).toNat)]
    if psNameEq name psIntNegName then
      return psInspectionIntegerExpr (-(← psInspectionInteger first))
    if psNameEq name psIntReprName then
      return .lit (.string (toString (← psInspectionInteger first)))
    if psNameEq name psCharToNatName then
      return .lit (.natural (Char.toNat (← psInspectionCharacter first)))
    if psNameEq name psStringSingletonName then
      return .lit (.string (String.singleton (← psInspectionCharacter first)))
    if psNameEq name psStringLengthName then
      return .lit (.natural (String.Internal.length (← psInspectionString first)))
    if psNameEq name psStringUtf8ByteSizeName then
      return .lit (.natural (String.utf8ByteSize (← psInspectionString first)))
    if psNameEq name psStringPosRawMkName || psNameEq name psStringPosRawByteIdxName then
      return .lit (.natural (← psInspectionNatural first))
    -- Char.ofNat and getNumBits are held as canonical scalar/opaque values.
    -- Their consumers own projection; returning the same redex would loop.
    none
  | [first, second] =>
    if psNameEq name (psRootName "mixHash") then
      let value := mixHash (UInt64.ofNat (← psInspectionNatural first))
        (UInt64.ofNat (← psInspectionNatural second))
      return psInspectionCall "UInt64.ofNat" [.lit (.natural value.toNat)]
    if psNameEq name psIntAddName then
      return psInspectionIntegerExpr ((← psInspectionInteger first) + (← psInspectionInteger second))
    if psNameEq name psIntSubName then
      return psInspectionIntegerExpr ((← psInspectionInteger first) - (← psInspectionInteger second))
    if psNameEq name psIntMulName then
      return psInspectionIntegerExpr ((← psInspectionInteger first) * (← psInspectionInteger second))
    if psNameEq name psNatBltName then
      return psInspectionBooleanExpr (decide ((← psInspectionNatural first) < (← psInspectionNatural second)))
    if psNameEq name psStringPushName then
      return .lit (.string (String.push (← psInspectionString first) (← psInspectionCharacter second)))
    if psNameEq name psStringAppendName then
      return .lit (.string ((← psInspectionString first) ++ (← psInspectionString second)))
    if psNameEq name psStringGetName then
      let character := String.Internal.get (← psInspectionString first)
        (String.Pos.Raw.mk (← psInspectionNatural second))
      return .app (.constE psCharOfNatName []) (.lit (.natural character.toNat))
    if psNameEq name psStringNextName then
      let next := String.Internal.next (← psInspectionString first)
        (String.Pos.Raw.mk (← psInspectionNatural second))
      return .lit (.natural (String.Pos.Raw.byteIdx next))
    if psNameEq name psStringAtEndName then
      return psInspectionBooleanExpr (String.Internal.atEnd (← psInspectionString first)
        (String.Pos.Raw.mk (← psInspectionNatural second)))
    none
  | [first, second, third] =>
    if psNameEq name psStringExtractName then
      return .lit (.string (String.Internal.extract (← psInspectionString first)
        (String.Pos.Raw.mk (← psInspectionNatural second))
        (String.Pos.Raw.mk (← psInspectionNatural third))))
    none
  | _ => none
