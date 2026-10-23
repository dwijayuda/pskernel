import Ps.Compiler.Ordinary
import ErasureSpineReference

private theorem erasure_reverse_acc (values acc : List alpha) :
    psListReverseAcc values acc = values.reverse ++ acc := by
  induction values generalizing acc with
  | nil => rfl
  | cons head tail ih => simp [psListReverseAcc, ih, List.reverse_cons, List.append_assoc]

private theorem erasure_reverse (values : List alpha) : psListReverse values = values.reverse := by
  simp [psListReverse, erasure_reverse_acc]

private theorem erasure_fold_append {Input State : Type} (step : Input -> State -> State)
    (left right : List Input) (state : State) :
    psErasureFoldReverseWorker step (left ++ right) state =
      psErasureFoldReverseWorker step right (psErasureFoldReverseWorker step left state) := by
  induction left generalizing state with
  | nil => rfl
  | cons head tail ih => simp [psErasureFoldReverseWorker, ih]

private theorem erasure_fold_reverse {Input State : Type} (step : Input -> State -> State)
    (values : List Input) (state : State) :
    psErasureFoldReverseWorker step values.reverse state = values.foldr step state := by
  induction values generalizing state with
  | nil => rfl
  | cons head tail ih =>
      simp [List.reverse_cons, erasure_fold_append, psErasureFoldReverseWorker, ih]

theorem erasure_fold_right_eq {Input State : Type} (step : Input -> State -> State)
    (values : List Input) (state : State) :
    psErasureFoldRight step values state = values.foldr step state := by
  rw [psErasureFoldRight, erasure_reverse, erasure_fold_reverse]

private theorem prepend_reference_foldr (Value : Type) (entries : List (Prod PsName Value))
    (state : PsErasureNameIndex Value) :
    ErasureSpineReference.psErasureIndexPrepend Value entries state =
      entries.foldr (psErasureIndexPrependStep Value) state := by
  induction entries generalizing state with
  | nil => rfl
  | cons entry rest ih =>
      cases entry
      simp only [ErasureSpineReference.psErasureIndexPrepend, List.foldr,
        psErasureIndexPrependStep, ih] <;> rfl

theorem erasure_index_prepend_eq (Value : Type) (entries : List (Prod PsName Value)) :
    psErasureIndexPrepend Value entries = ErasureSpineReference.psErasureIndexPrepend Value entries := by
  funext state
  rw [psErasureIndexPrepend, erasure_fold_right_eq, prepend_reference_foldr]

private theorem name_reference_foldr (entries : List (Prod PsName String)) :
    ErasureSpineReference.psErasureDeclarationNameIndex entries =
      entries.foldr psErasureDeclarationNameStep
        (PsErasureDeclarationNames.mk .empty .empty 0 .empty) := by
  induction entries with
  | nil => rfl
  | cons entry rest ih =>
      cases entry
      simp only [ErasureSpineReference.psErasureDeclarationNameIndex,
        List.foldr, psErasureDeclarationNameStep, ih] <;> rfl

theorem erasure_name_index_eq (entries : List (Prod PsName String)) :
    psErasureDeclarationNameIndex entries =
      ErasureSpineReference.psErasureDeclarationNameIndex entries := by
  rw [psErasureDeclarationNameIndex, erasure_fold_right_eq, name_reference_foldr]

private theorem entry_reference_foldr (environment : PsEnvironment) (declarations : List PsDeclaration) :
    ErasureSpineReference.psErasureDeclarationEntryIndex environment declarations =
      declarations.foldr (psErasureDeclarationEntryStep environment) (.ok .empty) := by
  induction declarations with
  | nil => rfl
  | cons declaration rest ih =>
      simp only [ErasureSpineReference.psErasureDeclarationEntryIndex,
        List.foldr, ih, psErasureDeclarationEntryStep]
      rfl

theorem erasure_entry_index_eq (environment : PsEnvironment) (declarations : List PsDeclaration) :
    psErasureDeclarationEntryIndex environment declarations =
      ErasureSpineReference.psErasureDeclarationEntryIndex environment declarations := by
  rw [psErasureDeclarationEntryIndex, erasure_fold_right_eq, entry_reference_foldr]

#print axioms erasure_fold_right_eq
#print axioms erasure_index_prepend_eq
#print axioms erasure_name_index_eq
#print axioms erasure_entry_index_eq

def runErasureSpineTests : IO Unit := do
  let a := psRootName "a"
  let b := psRootName "b"
  let other := psRootName "other"
  let initial := psErasureIndexInsert Nat .empty other 99
  let entries := [(a,1),(a,2),(b,3)]
  let indexed := psErasureIndexPrepend Nat entries initial
  let retained := ErasureSpineReference.psErasureIndexPrepend Nat entries initial
  for name in [a,b,other] do
    if psErasureIndexFind Nat indexed name != psErasureIndexFind Nat retained name then
      throw (IO.userError "prepend lookup precedence changed")
  if psErasureIndexFind Nat indexed a != some 1 then throw (IO.userError "first-entry precedence")
  let names := psErasureDeclarationNameIndex [(a,"first"),(a,"last"),(b,"other")]
  if names.count != 3 then throw (IO.userError "name count lost duplicates")
  if psErasureIndexFind String names.byCore a != some "first" then throw (IO.userError "core name precedence")
  for text in ["first","last","other"] do
    if psErasureIndexFind Bool names.byOutput (PsName.str .anonymous text) != some true then
      throw (IO.userError "output name index changed")
  let nat := PsExpr.constE psNatName []
  let definition := PsDeclaration.definitionDecl a [] nat (.lit (.natural 7))
  let large := List.replicate 10000 definition
  match psErasureDeclarationEntryIndex psSelfHostProdPreludeEnvironment large with
  | .error _ => throw (IO.userError "entry index smoke refused")
  | .ok result =>
      match psErasureIndexFind PsErasureEntryInfo result a with
      | .none => throw (IO.userError "entry index lost declaration")
      | .some info =>
          if info.runtimeArity != 0 || info.typeArity != 0 || !info.binders.isEmpty then
            throw (IO.userError "entry signature changed")
  match psErasureDeclarationEntryStep psSelfHostProdPreludeEnvironment definition (.error (.unknownLocal 31)) with
  | .error (.unknownLocal 31) => pure ()
  | _ => throw (IO.userError "error state was not preserved")
  IO.println "PSC1_ERASURE_SPINES: generic right-fold and three all-input retained API equalities; complete index structure/error priority; first-entry/output/count semantics;10000 declarations"
