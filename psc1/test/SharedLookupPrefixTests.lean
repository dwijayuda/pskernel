import SharedLookupPrefixReference

theorem lookup_prefix_psEnvironmentFindInListWorker_eq (declarations : List PsDeclaration) :
    psEnvironmentFindInListWorker declarations = SharedLookupPrefixReference.psEnvironmentFindInListWorker declarations := by
  induction declarations with
  | nil => rfl
  | cons declaration rest ih =>
      funext target
      simp only [psEnvironmentFindInListWorker, SharedLookupPrefixReference.psEnvironmentFindInListWorker, ih] <;> rfl

#print axioms lookup_prefix_psEnvironmentFindInListWorker_eq

theorem lookup_prefix_psFindConstructorDeclaration_eq (declarations : List PsDeclaration) :
    psFindConstructorDeclaration declarations = SharedLookupPrefixReference.psFindConstructorDeclaration declarations := by
  induction declarations with
  | nil => rfl
  | cons declaration rest ih =>
      funext target
      simp only [psFindConstructorDeclaration, SharedLookupPrefixReference.psFindConstructorDeclaration, ih] <;> rfl

#print axioms lookup_prefix_psFindConstructorDeclaration_eq

theorem lookup_prefix_psFindRecursorDeclaration_eq (declarations : List PsDeclaration) :
    psFindRecursorDeclaration declarations = SharedLookupPrefixReference.psFindRecursorDeclaration declarations := by
  induction declarations with
  | nil => rfl
  | cons declaration rest ih =>
      funext target
      simp only [psFindRecursorDeclaration, SharedLookupPrefixReference.psFindRecursorDeclaration, ih] <;> rfl

#print axioms lookup_prefix_psFindRecursorDeclaration_eq

def runSharedLookupPrefixTests : IO Unit := do
  let name := psRootName "lookup"
  let missing := psRootName "missing"
  let type := PsExpr.sortE PsLevel.zero
  let first := PsDeclaration.axiomDecl name [] type
  let filler := PsDeclaration.axiomDecl missing [] type
  let tail := List.replicate 100000 filler
  match psEnvironmentFindInListWorker (first :: tail) name with
  | .some (.axiomDecl _ [] (.sortE .zero)) => pure ()
  | _ => throw (IO.userError "environment early lookup changed")
  match psEnvironmentFindInListWorker [] name with
  | .none => pure ()
  | _ => throw (IO.userError "environment empty lookup changed")
  let constructor : PsConstructorInfo :=
    {name := name, levelParams := [], type := type, inductiveName := name,
     constructorIndex := 3, numParams := 5, numFields := 7, recursiveFields := [1,2]}
  let laterConstructor := {constructor with constructorIndex := 99}
  let recursor : PsRecursorInfo :=
    {name := name, levelParams := [], type := type, inductiveNames := [name],
     numParams := 5, numIndices := 2, numMotives := 3, numMinors := 7}
  let laterRecursor := {recursor with numMinors := 99}
  let declarations := [first, .constructorDecl constructor, .recursorDecl recursor,
    .constructorDecl laterConstructor, .recursorDecl laterRecursor]
  match psFindConstructorDeclaration declarations name with
  | .some found =>
      if found.constructorIndex != 3 || found.numParams != 5 || found.numFields != 7 ||
          found.recursiveFields != [1,2] then
        throw (IO.userError "constructor duplicate precedence/payload changed")
  | .none => throw (IO.userError "constructor lookup lost first match")
  match psFindRecursorDeclaration declarations name with
  | .some found =>
      if found.numMinors != 7 || found.numIndices != 2 || found.numMotives != 3 then
        throw (IO.userError "recursor duplicate precedence/payload changed")
  | .none => throw (IO.userError "recursor lookup lost first match")
  for query in [name, psRootName "absent"] do
    match psFindConstructorDeclaration tail query, psFindRecursorDeclaration tail query with
    | .none, .none => pure ()
    | _, _ => throw (IO.userError "lookup admitted wrong declaration kind")
  match psFindConstructorDeclaration (.constructorDecl constructor :: tail) name,
      psFindRecursorDeclaration (.recursorDecl recursor :: tail) name with
  | .some _, .some _ => pure ()
  | _, _ => throw (IO.userError "large lookup early result lost")
  IO.println "PSC1_SHARED_LOOKUP_PREFIX: three all-input API equalities;100000 unused tail/absent/kind/first-duplicate payload cases"
