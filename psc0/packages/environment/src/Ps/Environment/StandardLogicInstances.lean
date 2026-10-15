import Ps.Environment.StandardClass

/-!
Selected ordinary registrations from Lean 4.35.0 (eb6cafb7290e8bd5f2937522d8d804f58f02bafc):
Init/Prelude.lean, Init/Core.lean and Init/Data/Int/Basic.lean.
Microsoft Corporation / Lean FRO, LLC, Apache-2.0; see THIRD_PARTY_NOTICES.md.
Their exact checked declarations already occur in frozen native assets.
Logical dependency inclusion never implicitly registers instances: select and
audit this complete basic order/propositional-decision layer explicitly.
-/
def psStandardLogicRegistrations : List (String × String) :=
  [("instLTNat", "LT"), ("instLENat", "LE"),
   ("Int.instLTInt", "LT"), ("Int.instLEInt", "LE"),
   ("Int.decLt", "Decidable"), ("Int.decLe", "Decidable"),
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
  -- Int decisions use the existing typed Int comparison operations. Iff's
  -- native computation refers to the existing checked Bool BEq dictionary.
  ("instBEqBool" :: (psStandardLogicRegistrations.map Prod.fst).filter
    (fun name => name != "Int.decLt" && name != "Int.decLe")).filterMap
      (fun name => psEnvironmentFind environment (psDecisionName name))

def psStandardLogicAudit (environment : PsEnvironment) : Except String Unit := do
  for (name, className) in psStandardLogicRegistrations do
    let some declaration := psEnvironmentFind environment (psDecisionName name)
      | throw ("PSCV0-STANDARD: missing selected logic declaration " ++ name)
    match declaration with
    | .definitionDecl .. => pure ()
    | _ => throw ("PSCV0-STANDARD: selected logic must be checked definitions " ++ name)
    if !environment.classes.any (psNameEq (psRootName className)) then
      throw ("PSCV0-STANDARD: missing selected logic class " ++ className)
    psStandardAuditInstance environment declaration
  if (psEnvironmentFind environment (psDecisionName "instBEqBool")).isNone then
    throw "PSCV0-STANDARD: missing checked Bool BEq runtime dependency"
