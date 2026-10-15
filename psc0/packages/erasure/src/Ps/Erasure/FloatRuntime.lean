import Ps.Erasure.Basic

/-!
Exact IEEE conversion support, built once as typed IR for every executable
backend. Reference: Lean 4.35.0 Init/Data/OfScientific.lean and
Init/Data/Float/Model/Unpacked/{Round,Operations/OfScientific,Operations/Div}.lean.
The native fast-path thresholds and power tables follow the Apache-2.0 Lean
implementation (Microsoft Corporation; Lean FRO, LLC; Leonardo de Moura,
Julia M. Himmel). The rational rounding IR builder below is an independent
implementation of the same nearest-even invariant, not a new logical axiom.
-/
namespace PsFloatRuntime

private def n (v : Nat) : PsVerifiedIrExpr := .literal (.natural v)
private def z (v : Int) : PsVerifiedIrExpr := .literal (.integer v)
private def v := PsVerifiedIrExpr.var
private def op (o : PsVerifiedIrIntrinsic) (args : List PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  .intrinsic o [] args
private def bind (name : String) (type : PsVerifiedIrPrimitiveType)
    (value body : PsVerifiedIrExpr) : PsVerifiedIrExpr := .letE name (.primitive type) value body
private def choice := PsVerifiedIrExpr.ifE
private def add (a b : PsVerifiedIrExpr) := op .natAdd [a,b]
private def sub (a b : PsVerifiedIrExpr) := op .natSub [a,b]
private def mul (a b : PsVerifiedIrExpr) := op .natMul [a,b]
private def div (a b : PsVerifiedIrExpr) := op .natDiv [a,b]
private def eq (a b : PsVerifiedIrExpr) := op .natEq [a,b]
private def lt (a b : PsVerifiedIrExpr) := op .natLt [a,b]
private def pow2 (a : PsVerifiedIrExpr) := op .natPow [n 2,a]
private def asInt (a : PsVerifiedIrExpr) := op .intOfNat [a]
private def asNat (a : PsVerifiedIrExpr) := op .intToNat [a]
private def neg (a : PsVerifiedIrExpr) := op .intNeg [a]
private def iadd (a b : PsVerifiedIrExpr) := op .intAdd [a,b]
private def isub (a b : PsVerifiedIrExpr) := op .intSub [a,b]
private def ilt (a b : PsVerifiedIrExpr) := op .intLt [a,b]

def roles : List String :=
  ["float64_ratio", "float64_scientific", "float64_natural", "float64_integer", "float64_model_scientific",
   "float32_ratio", "float32_scientific", "float32_natural", "float32_integer", "float32_model_scientific"]

def role (width : PsVerifiedIrFloatingType) (suffix : String) : String :=
  (match width with | .float => "float64_" | .float32 => "float32_") ++ suffix

private def fresh (names : PsErasureDeclarationNames) (base : String) :
    Nat → Nat → Except PsErasureError String
  | 0, _ => .error .fuelExhausted
  | fuel + 1, index =>
    let candidate := base ++ (if index == 0 then "" else "_" ++ toString index)
    if (psErasureIndexFind Bool names.byOutput (psRootName candidate)).isSome then
      fresh names base fuel (index + 1)
    else .ok candidate

def reserve (scope : PsErasureScope) : Except PsErasureError PsErasureScope := do
  let mut scope := scope
  for key in roles do
    let name ← fresh scope.declarationNames ("_ps_" ++ key)
      (scope.declarationNames.count + 1) 0
    scope := psErasureReserveOutputName scope name
    scope := { scope with declarationNames := { scope.declarationNames with
      supportNames := (key, name) :: scope.declarationNames.supportNames } }
  return scope

def name (scope : PsErasureScope) (width : PsVerifiedIrFloatingType) (suffix : String) :
    Except PsErasureError String :=
  match scope.declarationNames.supportNames.lookup (role width suffix) with
  | some name => .ok name
  | none => .error .unsupportedApplication

def call (scope : PsErasureScope) (width : PsVerifiedIrFloatingType) (suffix : String)
    (args : List PsVerifiedIrExpr) : Except PsErasureError PsVerifiedIrExpr := do
  return .call (.var (← name scope width suffix)) [] args

private def valueType : PsVerifiedIrFloatingType → PsVerifiedIrType
  | .float => .primitive .float | .float32 => .primitive .float32
private def wordType : PsVerifiedIrFloatingType → PsVerifiedIrMachineIntegerType
  | .float => .uint64 | .float32 => .uint32
private def fromBits (width : PsVerifiedIrFloatingType) (bits : PsVerifiedIrExpr) :=
  op (.floatOfBits width) [op (.unsignedOfNat (wordType width)) [bits]]
private def constant (width : PsVerifiedIrFloatingType) (bits : Nat) :=
  op (.floatOfBits width) [.literal (.machineInteger (wordType width) (Int.ofNat bits))]
private def infinity : PsVerifiedIrFloatingType → Nat
  | .float => 9218868437227405312 | .float32 => 2139095040

-- n/d is positive and d is nonzero. Determine its binade exactly; round once
-- at max(binade - fractionBits, minimumSubnormalExponent). A quotient carry
-- advances the exponent before packing, including the overflow boundary.
def ratioBody (width : PsVerifiedIrFloatingType) : PsVerifiedIrExpr :=
  let (fraction, bias, minimumUnit, maximumUnit) : Nat × Nat × Int × Int :=
    match width with | .float => (52, 1023, -1074, 971) | .float32 => (23, 127, -149, 104)
  let hidden := 2 ^ fraction
  let numerator := v "numerator"
  let denominator := v "denominator"
  let raw := v "rawExponent"
  let unit := v "unitExponent"
  let q := v "quotient"
  let twice := v "twiceRemainder"
  let rounded := v "rounded"
  let carry := v "carry"
  let finalUnit := v "finalUnit"
  let significand := v "significand"
  let packed := choice (lt significand (n hidden)) significand
    (add (mul (asNat (iadd finalUnit (z (Int.ofNat (fraction + bias))))) (n hidden))
      (sub significand (n hidden)))
  choice (eq numerator (n 0)) (constant width 0) <|
  bind "rawExponent" .int (isub (asInt (op .natLog2 [numerator])) (asInt (op .natLog2 [denominator]))) <|
  bind "belowBinade" .bool
    (choice (ilt raw (z 0))
      (lt (mul numerator (pow2 (asNat (neg raw)))) denominator)
      (lt numerator (mul denominator (pow2 (asNat raw))))) <|
  bind "binade" .int (isub raw (choice (v "belowBinade") (z 1) (z 0))) <|
  choice (ilt (z (Int.ofNat bias)) (v "binade")) (constant width (infinity width)) <|
  bind "candidateUnit" .int (isub (v "binade") (z (Int.ofNat fraction))) <|
  bind "unitExponent" .int
    (choice (ilt (v "candidateUnit") (z minimumUnit)) (z minimumUnit) (v "candidateUnit")) <|
  bind "scaledNumerator" .nat
    (choice (ilt unit (z 0)) (mul numerator (pow2 (asNat (neg unit)))) numerator) <|
  bind "scaledDenominator" .nat
    (choice (ilt unit (z 0)) denominator (mul denominator (pow2 (asNat unit)))) <|
  bind "quotient" .nat (div (v "scaledNumerator") (v "scaledDenominator")) <|
  bind "twiceRemainder" .nat (mul (n 2) (op .natMod [v "scaledNumerator", v "scaledDenominator"])) <|
  bind "rounded" .nat
    (choice (op .boolOr [lt (v "scaledDenominator") twice,
      op .boolAnd [eq twice (v "scaledDenominator"), eq (op .natMod [q, n 2]) (n 1)]])
      (add q (n 1)) q) <|
  bind "carry" .bool (eq rounded (n (2 * hidden))) <|
  bind "finalUnit" .int (iadd unit (choice carry (z 1) (z 0))) <|
  bind "significand" .nat (choice carry (div rounded (n 2)) rounded) <|
  choice (ilt (z maximumUnit) finalUnit) (constant width (infinity width)) (fromBits width packed)

private def powers64 : List Nat :=
  [0x3FF0000000000000, 0x4024000000000000, 0x4059000000000000, 0x408F400000000000,
   0x40C3880000000000, 0x40F86A0000000000, 0x412E848000000000, 0x416312D000000000,
   0x4197D78400000000, 0x41CDCD6500000000, 0x4202A05F20000000, 0x42374876E8000000,
   0x426D1A94A2000000, 0x42A2309CE5400000, 0x42D6BCC41E900000, 0x430C6BF526340000,
   0x4341C37937E08000, 0x4376345785D8A000, 0x43ABC16D674EC800, 0x43E158E460913D00,
   0x4415AF1D78B58C40, 0x444B1AE4D6E2EF50, 0x4480F0CF064DD592]
private def powers32 : List Nat :=
  [0x3F800000, 0x41200000, 0x42C80000, 0x447A0000, 0x461C4000, 0x47C35000,
   0x49742400, 0x4B189680, 0x4CBEBC20, 0x4E6E6B28, 0x501502F9]

-- Balanced selection avoids a runtime Array allocation for the native fast path.
private def powerTable (width : PsVerifiedIrFloatingType) (exponent : PsVerifiedIrExpr) :
    Nat → Nat → List Nat → PsVerifiedIrExpr
  | 0, _, _ => .unreachable (valueType width)
  | fuel + 1, offset, values =>
    match values with
    | [] => .unreachable (valueType width)
    | [bits] => constant width bits
    | _ =>
      let half := values.length / 2
      choice (lt exponent (n (offset + half)))
        (powerTable width exponent fuel offset (values.take half))
        (powerTable width exponent fuel (offset + half) (values.drop half))

def scientificBody (scope : PsErasureScope) (width : PsVerifiedIrFloatingType) :
    Except PsErasureError PsVerifiedIrExpr := do
  let m := v "mantissa"
  let e := v "exponent"
  let negative := v "negativeExponent"
  let (exactBits, limit, exponentLimit, table) : Nat × Nat × Nat × List Nat :=
    match width with | .float => (53, 22, 2048, powers64) | .float32 => (23, 10, 256, powers32)
  let magnitude := op (.floatOfWord width .uint64) [op (.unsignedOfNat .uint64) [m]]
  let ratio ← call scope width "ratio"
    [choice negative m (mul m (v "power")), choice negative (v "power") (n 1)]
  return choice (eq m (n 0)) (constant width 0) <|
    choice (op .boolAnd [lt m (n (2 ^ exactBits)), op .natLe [e, n limit]])
      (bind "powerOfTen" (match width with | .float => .float | .float32 => .float32)
        (powerTable width e table.length 0 table)
        (choice negative (op (.floatBinary width .div) [magnitude, v "powerOfTen"])
          (op (.floatBinary width .mul) [magnitude, v "powerOfTen"]))) <|
    choice (choice negative (lt (add (n exponentLimit) (op .natLog2 [m])) e) (lt (n exponentLimit) e))
      (choice negative (constant width 0) (constant width (infinity width))) <|
    bind "power" .nat (op .natPow [n 10, e]) ratio

def declarations (scope : PsErasureScope) : Except PsErasureError (List PsVerifiedIrDeclaration) := do
  let mut result := []
  for width in [PsVerifiedIrFloatingType.float, .float32] do
    let natural ← call scope width "ratio" [v "value", n 1]
    let natural := choice (lt (v "value") (n (2 ^ 64)))
      (op (.floatOfWord width .uint64) [op (.unsignedOfNat .uint64) [v "value"]]) natural
    let integer ← call scope width "natural"
      [asNat (choice (ilt (v "value") (z 0)) (neg (v "value")) (v "value"))]
    let integer := bind "magnitude" (match width with | .float => .float | .float32 => .float32)
      integer (choice (ilt (v "value") (z 0)) (op (.floatUnary width .neg) [v "magnitude"]) (v "magnitude"))
    let modelScientific ← call scope width "scientific"
      [v "mantissa", ilt (v "exponent") (z 0),
       asNat (choice (ilt (v "exponent") (z 0)) (neg (v "exponent")) (v "exponent"))]
    for (suffix, parameters, body) in [
        ("ratio", [("numerator", .nat), ("denominator", .nat)], ratioBody width),
        ("scientific", [("mantissa", .nat), ("negativeExponent", .bool), ("exponent", .nat)], ← scientificBody scope width),
        ("natural", [("value", .nat)], natural),
        ("integer", [("value", .int)], integer),
        ("model_scientific", [("mantissa", .nat), ("exponent", .int)], modelScientific)] do
      result := result ++ [{
        name := ← name scope width suffix
        typeParameters := []
        parameters := parameters.map fun (name, type) => ⟨name, .primitive type⟩
        resultType := valueType width
        body := body }]
  return result

end PsFloatRuntime
