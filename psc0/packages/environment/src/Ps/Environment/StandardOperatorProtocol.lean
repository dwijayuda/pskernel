import Ps.Environment.StandardOperatorDefaults
import Ps.Environment.StandardPlatformWords

/-!
Selected notation dependencies from Lean 4.35.0 Init/Prelude.lean,
Init/Data/{Int,UInt,SInt}/Basic.lean and Init/Coe.lean, pinned at
eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Microsoft Corporation /
Lean FRO, LLC, Apache-2.0; see THIRD_PARTY_NOTICES.md.
This final selection does not change any frozen logical exporter boundary.
-/
def psStandardOperatorProtocolClasses : List (String × String × Bool) :=
  [("HPow", "hPow", true), ("Pow", "pow", false),
   ("NatPow", "pow", false), ("HShiftLeft", "hShiftLeft", true),
   ("HShiftRight", "hShiftRight", true),
   ("ShiftLeft", "shiftLeft", false), ("ShiftRight", "shiftRight", false)]

def psStandardOperatorProtocolBridges : List (String × String) :=
  [("instHPow", "HPow"), ("instPowNat", "Pow"),
   ("instHShiftLeftOfShiftLeft", "HShiftLeft"),
   ("instHShiftRightOfShiftRight", "HShiftRight")]

def psStandardOperatorProtocolNativeInstances : List (String × String) :=
  psStandardOperatorProtocolBridges ++
    [("instNatPowNat", "NatPow"), ("Int.instNatPow", "NatPow"),
     ("Nat.instShiftLeft", "ShiftLeft"), ("Nat.instShiftRight", "ShiftRight")]

def psStandardOperatorProtocolNativeNames : List String :=
  psStandardOperatorProtocolClasses.flatMap (fun (name, field, _) =>
    [name, name ++ ".mk", name ++ "." ++ field]) ++
    psStandardOperatorProtocolNativeInstances.map Prod.fst

-- Ground word dictionaries follow the upstream one-field definitions. Pow's
-- exponent is Nat, whereas ShiftLeft/Right take the same word type as the base.
-- Platform dictionaries are logical in every profile but executable only when
-- a target word size is explicitly provided.
def psStandardOperatorProtocolInstances : List (String × Bool × PsDeclaration) :=
  ["UInt8", "UInt16", "UInt32", "UInt64", "USize",
   "Int8", "Int16", "Int32", "Int64", "ISize"].flatMap fun owner =>
    ["Pow", "ShiftLeft", "ShiftRight"].map fun className =>
      let power := className == "Pow"
      let method := if power then "pow" else if className == "ShiftLeft" then "shiftLeft" else "shiftRight"
      let type := PsExpr.constE (psRootName owner) []
      let parameters := if power then [type, .constE psNatName []] else [type]
      let levels := if power then [.zero, .zero] else [.zero]
      let declaration := PsDeclaration.definitionDecl
        (psDecisionName ("PsStandard.inst" ++ className ++ owner)) []
        (psLogicApply (.constE (psRootName className) levels) parameters)
        (psLogicApply (.constE (psDecisionName (className ++ ".mk")) levels)
          (parameters ++ [.constE (psDecisionName (owner ++ "." ++ method)) []]))
      (className, owner == "USize" || owner == "ISize", declaration)

-- PSCV0 selects direct Coe rather than Lean's general CoeTail/CoeHTCT graph.
-- The checked function is exactly the canonical Nat-to-Int constructor.
def psStandardNatIntCoercion : PsDeclaration :=
  let nat := PsExpr.constE psNatName []
  let int := PsExpr.constE psIntName []
  let levels := [PsLevel.succ .zero, .succ .zero]
  .definitionDecl (psDecisionName "PsStandard.instCoeNatInt") []
    (psLogicApply (.constE (psRootName "Coe") levels) [nat, int])
    (psLogicApply (.constE (psDecisionName "Coe.mk") levels)
      [nat, int, .constE psIntOfNatName []])

def psStandardOperatorProtocolExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardOperatorProtocolClasses.foldl (fun env (text, _, hetero) =>
    let name := psRootName text
    { env with
      classes := name :: env.classes
      classParameters := (name, if hetero then { outputs := [2], outputLevels := [2] } else {}) ::
        env.classParameters }) environment
  let environment := psStandardOperatorProtocolNativeInstances.foldl (fun env (name, className) =>
    match psEnvironmentFind env (psDecisionName name) with
    | none => env -- Strict auditing rejects missing native dependencies.
    | some declaration => psStandardRegisterInstances env className [declaration]) environment
  let environment := psStandardOperatorProtocolInstances.foldl (fun env (className, _, declaration) =>
    psStandardRegisterInstances (psEnvironmentInsert env declaration) className [declaration]) environment
  let environment := psStandardRegisterInstances
    (psEnvironmentInsert environment psStandardNatIntCoercion) "Coe" [psStandardNatIntCoercion]
  let instances := psStandardOperatorProtocolBridges.foldl (fun index (name, className) =>
    match psEnvironmentFind environment (psDecisionName name) with
    | none => index
    | some declaration => psInstanceIndexAddDefault index {
      value := .constE (psDeclarationName declaration)
        ((psDeclarationLevelParams declaration).map PsLevel.param)
      levelParams := psDeclarationLevelParams declaration
      type := psDeclarationType declaration
      className := some (psRootName className), priority := 1000 }) environment.instances
  { environment with instances }

def psStandardOperatorProtocolRuntimeDeclarations (environment : PsEnvironment)
    (platform : Bool := false) : List PsDeclaration :=
  (if platform then [] else
    psStandardOperatorProtocolNativeNames.filterMap
      (fun name => psEnvironmentFind environment (psDecisionName name)) ++
      [psStandardNatIntCoercion]) ++
  psStandardOperatorProtocolInstances.filterMap fun (_, dependent, declaration) =>
    if dependent == platform then some declaration else none

def psStandardOperatorProtocolAudit (environment : PsEnvironment) : Except String Unit := do
  let missing := psStandardOperatorProtocolNativeNames.filter (fun name =>
    (psEnvironmentFind environment (psDecisionName name)).isNone)
  if !missing.isEmpty then
    throw ("PSCV0-STANDARD: missing checked operator dependencies " ++ String.intercalate ", " missing)
  for (name, _, hetero) in psStandardOperatorProtocolClasses do
    let className := psRootName name
    if (environment.classes.filter (psNameEq className)).length != 1 then
      throw ("PSCV0-STANDARD: operator class registration drift " ++ name)
    let some (_, parameters) := environment.classParameters.find? (fun entry => psNameEq entry.1 className)
      | throw ("PSCV0-STANDARD: missing operator metadata " ++ name)
    if parameters.outputs != (if hetero then [2] else []) ||
        parameters.outputLevels != (if hetero then [2] else []) then
      throw ("PSCV0-STANDARD: operator output parameter drift " ++ name)
  for (name, _) in psStandardOperatorProtocolNativeInstances do
    let some declaration := psEnvironmentFind environment (psDecisionName name)
      | throw ("PSCV0-STANDARD: missing native operator instance " ++ name)
    psStandardAuditInstance environment declaration
  for (_, _, declaration) in psStandardOperatorProtocolInstances do
    psStandardAuditDeclaration environment declaration
    psStandardAuditInstance environment declaration
  psStandardAuditDeclaration environment psStandardNatIntCoercion
  psStandardAuditInstance environment psStandardNatIntCoercion
  for (name, className) in psStandardOperatorProtocolBridges do
    let [entry] := environment.instances.defaults.filter (fun entry =>
        match entry.value with | .constE actual _ => psNameEq actual (psDecisionName name) | _ => false)
      | throw ("PSCV0-STANDARD: operator default count drift " ++ name)
    if entry.priority != 1000 || !entry.className.any (psNameEq (psRootName className)) then
      throw ("PSCV0-STANDARD: operator default metadata drift " ++ name)
