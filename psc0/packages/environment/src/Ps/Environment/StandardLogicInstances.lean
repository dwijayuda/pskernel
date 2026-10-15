import Ps.Environment.StandardClass

/-!
Selected ordinary registrations from Lean 4.35.0 (eb6cafb7290e8bd5f2937522d8d804f58f02bafc):
Init/Prelude.lean, Init/Core.lean and Init/Data/Int/Basic.lean.
Microsoft Corporation / Lean FRO, LLC, Apache-2.0; see THIRD_PARTY_NOTICES.md.
Their checked declarations must occur in the selected native assets; the strict
complete-dependency audit rejects omissions before qualification.
Logical dependency inclusion never implicitly registers instances: select and
audit this complete basic order/propositional-decision layer explicitly.
-/
def psStandardLogicRegistrations : List (String × String) :=
  [("instLTNat", "LT"), ("instLENat", "LE"),
   ("Int.instLTInt", "LT"), ("Int.instLEInt", "LE"),
   ("Int.decLt", "Decidable"), ("Int.decLe", "Decidable"),
   ("Int.instDecidableEq", "Decidable"),
   ("instDecidableTrue", "Decidable"), ("instDecidableFalse", "Decidable"),
   ("instDecidableForall", "Decidable"), ("instDecidableIff", "Decidable"),
   ("instDecidableAnd", "Decidable"), ("instDecidableOr", "Decidable"),
   ("instDecidableNot", "Decidable")]

def psStandardLogicExtend (environment : PsEnvironment) : PsEnvironment :=
  psStandardLogicRegistrations.foldl (fun env (name, className) =>
    match psEnvironmentFind env (psDecisionName name) with
    | none => env -- The strict registry audit rejects any missing declaration.
    | some declaration => psStandardRegisterInstances env className [declaration]) environment

def psStandardLogicRuntimeDeclarations (environment : PsEnvironment) : List PsDeclaration :=
  -- The frozen native Iff body uses the generic BEq-from-DecidableEq bridge
  -- applied to instDecidableEqBool, rather than a ground BEq dictionary.
  (["instBEqOfDecidableEq", "instDecidableEqBool", "Int.decEq"] ++
    (psStandardLogicRegistrations.map Prod.fst).filter
      (fun name => name != "Int.decLt" && name != "Int.decLe")).filterMap
      (fun name => psEnvironmentFind environment (psDecisionName name))

def psStandardLogicAudit (environment : PsEnvironment) : Except String Unit := do
  let required := psStandardLogicRegistrations.map Prod.fst ++
    ["instBEqOfDecidableEq", "instDecidableEqBool", "Int.decEq"]
  let missing := required.filter (fun name =>
    (psEnvironmentFind environment (psDecisionName name)).isNone)
  if !missing.isEmpty then
    throw ("PSCV0-STANDARD: missing checked logic dependencies " ++ String.intercalate ", " missing)
  for (name, className) in psStandardLogicRegistrations do
    let some declaration := psEnvironmentFind environment (psDecisionName name)
      | throw ("PSCV0-STANDARD: missing selected logic declaration " ++ name)
    match declaration with
    | .definitionDecl .. => pure ()
    | _ => throw ("PSCV0-STANDARD: selected logic must be checked definitions " ++ name)
    if !environment.classes.any (psNameEq (psRootName className)) then
      throw ("PSCV0-STANDARD: missing selected logic class " ++ className)
    psStandardAuditInstance environment declaration
  for name in ["instBEqOfDecidableEq", "instDecidableEqBool"] do
    let some (.definitionDecl ..) := psEnvironmentFind environment (psDecisionName name)
      | throw ("PSCV0-STANDARD: missing checked decision runtime dependency " ++ name)
