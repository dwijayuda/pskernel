import Ps.Environment.StandardUnsignedOperations
import Ps.Environment.StandardFloatOperations
import Ps.Environment.StandardSignedScalar

/-!
Lean 4.35.0 Init/Prelude.lean and Init/Data/Int/Basic.lean.
The homogeneous classes and generic H* bridges are already in checked native
logical assets. Select those declarations; do not manufacture a second class.
Ground dictionaries reuse the same checked operation values as the earlier
asset stages. Only the final selected search/runtime catalogue changes.
-/

-- Homogeneous class, projection, pinned generic heterogeneous bridge.
def psStandardHomogeneousSpecs : List (String × String × String) :=
  [("Add", "add", "instHAdd"), ("Sub", "sub", "instHSub"),
   ("Mul", "mul", "instHMul"), ("Div", "div", "instHDiv"),
   ("Mod", "mod", "instHMod"), ("Append", "append", "instHAppendOfAppend")]

def psStandardHomogeneousNativeNames : List PsName :=
  psStandardHomogeneousSpecs.flatMap fun (className, fieldName, bridge) =>
    [className, className ++ ".mk", className ++ "." ++ fieldName, bridge].map psDecisionName

-- The old dictionaries remain in frozen logical asset boundaries, but are
-- replaced in the final instance index. Extract the actual checked method:
-- neither a reverse generic bridge nor a wrapper around an old dictionary.
def psStandardHomogeneousInstances : List (PsName × String × PsDeclaration) :=
  let old := psStandardBinaryDeclarations ++
    (psStandardUnsignedOperatorInstances ++ psStandardSignedScalarInstances ++
      psStandardFloatScalarInstances).map Prod.snd
  psStandardHomogeneousSpecs.flatMap fun (className, _, _) =>
    old.filterMap fun declaration => do
      let .app (.app (.app (.constE family _) type) beta) gamma :=
        psDeclarationType declaration | none
      if !psNameEq family (psRootName ("H" ++ className)) ||
          !psExprAlphaEq type beta || !psExprAlphaEq type gamma then none else do
      let .constE owner [] := type | none
      let some (.app (.app (.app (.app (.constE ctor _) _) _) _) method) :=
        psDeclarationValue declaration | none
      if !psNameEq ctor (psDecisionName ("H" ++ className ++ ".mk")) then none else
      let name := psNameAppendStr (psRootName "PsStandard")
        ("inst" ++ className ++ psNameToString owner)
      let value := psLogicApply (.constE (psDecisionName (className ++ ".mk")) [.zero])
        [type, method]
      some (psDeclarationName declaration, className,
        .definitionDecl name [] (.app (.constE (psRootName className) [.zero]) type) value)

def psStandardHomogeneousReplacedNames : List PsName :=
  psStandardHomogeneousInstances.map (fun (name, _, _) => name)

def psStandardOperatorDefaultRegistrations : List (String × String × Nat) :=
  psStandardHomogeneousSpecs.map (fun (className, _, bridge) =>
    (bridge, "H" ++ className, 1000)) ++
  [("PsStandard.instOfNatNat", "OfNat", 100),
   ("PsStandard.instNegInt", "Neg", 500)]

def psStandardOperatorDefaultsExtend (environment : PsEnvironment) : PsEnvironment :=
  let oldNames := psStandardHomogeneousReplacedNames
  let instances := { environment.instances with entries :=
    environment.instances.entries.filter (fun entry =>
      match entry.value with
      | .constE name _ => !oldNames.any (psNameEq name)
      | _ => true) }
  let environment := { environment with instances }
  let environment := psStandardHomogeneousSpecs.foldl
    (fun env (name, _, _) => psStandardRegisterClass env name) environment
  let environment := psStandardHomogeneousInstances.foldl (fun env (_, className, declaration) =>
    psStandardRegisterInstances (psEnvironmentInsert env declaration) className [declaration]) environment
  let environment := psStandardHomogeneousSpecs.foldl (fun env (className, _, bridge) =>
    match psEnvironmentFind env (psDecisionName bridge) with
    | none => env -- The strict audit below refuses missing checked assets.
    | some declaration => psStandardRegisterInstances env ("H" ++ className) [declaration]) environment
  let instances := psStandardOperatorDefaultRegistrations.foldl
    (fun index (name, className, priority) =>
      match psEnvironmentFind environment (psDecisionName name) with
      | none => index
      | some declaration => psInstanceIndexAddDefault index {
        value := .constE (psDeclarationName declaration)
          ((psDeclarationLevelParams declaration).map PsLevel.param)
        levelParams := psDeclarationLevelParams declaration
        type := psDeclarationType declaration
        className := some (psRootName className)
        priority }) environment.instances
  { environment with instances }

def psStandardOperatorDefaultsRuntimeDeclarations (environment : PsEnvironment) :
    List PsDeclaration :=
  psStandardHomogeneousNativeNames.filterMap (psEnvironmentFind environment) ++
    psStandardHomogeneousInstances.map (fun (_, _, declaration) => declaration)

def psStandardOperatorDefaultsAudit (environment : PsEnvironment) : Except String Unit := do
  for name in psStandardHomogeneousNativeNames do
    if (psEnvironmentFind environment name).isNone then
      throw ("PSCV0-STANDARD: missing native operator declaration " ++ psNameToString name)
  for (className, _, bridge) in psStandardHomogeneousSpecs do
    if !environment.classes.any (psNameEq (psRootName className)) then
      throw ("PSCV0-STANDARD: missing homogeneous class " ++ className)
    let some declaration := psEnvironmentFind environment (psDecisionName bridge)
      | throw ("PSCV0-STANDARD: missing operator bridge " ++ bridge)
    psStandardAuditInstance environment declaration
  for (old, _, declaration) in psStandardHomogeneousInstances do
    psStandardAuditDeclaration environment declaration
    psStandardAuditInstance environment declaration
    if environment.instances.entries.any (fun entry =>
        match entry.value with | .constE name _ => psNameEq old name | _ => false) then
      throw ("PSCV0-STANDARD: redundant heterogeneous search rule " ++ psNameToString old)
  for (name, className, priority) in psStandardOperatorDefaultRegistrations do
    let some declaration := psEnvironmentFind environment (psDecisionName name)
      | throw ("PSCV0-STANDARD: missing default declaration " ++ name)
    let entries := environment.instances.defaults.filter (fun entry =>
      match entry.value with
      | .constE actual _ => psNameEq actual (psDecisionName name)
      | _ => false)
    let [entry] := entries | throw ("PSCV0-STANDARD: default count drift " ++ name)
    if entry.priority != priority ||
        !(entry.className.any (psNameEq (psRootName className))) ||
        !psExprAlphaEq entry.type (psDeclarationType declaration) then
      throw ("PSCV0-STANDARD: default metadata drift " ++ name)
