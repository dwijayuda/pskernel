import FoundationListTests
import OrdinaryExpansionReference

private theorem append_std {α : Type} (left right : List α) :
    psListAppend left right = left ++ right := by
  rw [foundation_append_eq]
  induction left with
  | nil => rfl
  | cons value rest ih => simp only [FoundationListReference.psListAppend, List.cons_append, ih]

private theorem reverse_acc_std {α : Type} (values acc : List α) :
    psListReverseAcc values acc = values.reverse ++ acc := by
  induction values generalizing acc with
  | nil => rfl
  | cons value rest ih =>
      simp only [psListReverseAcc, ih, List.reverse_cons, List.append_assoc, List.singleton_append]

private theorem reverse_std {α : Type} (values : List α) :
    psListReverse values = values.reverse := by
  simp only [psListReverse, reverse_acc_std, List.append_nil]

theorem ordinary_expansion_acc_eq (declarations : List PsDeclaration)
    (environment : PsEnvironment) (logicalRev : List PsDeclaration) (partialRev : List PsName) :
    psOrdinaryExpandAcc declarations environment logicalRev partialRev =
      match OrdinaryExpansionReference.psOrdinaryExpandWorker declarations environment with
      | Except.error error => Except.error error
      | Except.ok result => Except.ok (Prod.mk
          (logicalRev.reverse ++ result.fst) (partialRev.reverse ++ result.snd)) := by
  induction declarations generalizing environment logicalRev partialRev with
  | nil =>
      simp only [psOrdinaryExpandAcc, OrdinaryExpansionReference.psOrdinaryExpandWorker,
        reverse_std, List.append_nil]
  | cons declaration rest ih =>
      cases declaration <;>
        simp only [psOrdinaryExpandAcc, OrdinaryExpansionReference.psOrdinaryExpandWorker]
      all_goals
        simp_all only [ih, reverse_std, List.reverse_cons, List.append_assoc, List.singleton_append]
        repeat
          first
          | rfl
          | (split <;> simp_all only [ih, reverse_std, List.reverse_cons, List.append_assoc, List.singleton_append])

theorem ordinary_expansion_worker_eq (declarations : List PsDeclaration) :
    psOrdinaryExpandWorker declarations =
      OrdinaryExpansionReference.psOrdinaryExpandWorker declarations := by
  funext environment
  have h := ordinary_expansion_acc_eq declarations environment [] []
  cases result : OrdinaryExpansionReference.psOrdinaryExpandWorker declarations environment with
  | error error =>
      simpa only [psOrdinaryExpandWorker, List.reverse_nil, List.nil_append, result] using h
  | ok expanded =>
      cases expanded with
      | mk logical partials =>
          simpa only [psOrdinaryExpandWorker, List.reverse_nil, List.nil_append, result] using h

#print axioms ordinary_expansion_worker_eq

private def requireSame (declarations : List PsDeclaration) (shouldAccept : Bool) : IO Unit := do
  let actual := psOrdinaryExpandWorker declarations psSelfHostProdPreludeEnvironment
  let expected := OrdinaryExpansionReference.psOrdinaryExpandWorker declarations psSelfHostProdPreludeEnvironment
  match actual,expected with
  | .error a,.error b =>
      if shouldAccept then throw (IO.userError "expected ordinary acceptance")
      if a != b then throw (IO.userError "ordinary refusal/order changed")
  | .ok a,.ok b =>
      if !shouldAccept then throw (IO.userError "forbidden ordinary input was accepted")
      match psEncodeCheckedAdmissionsCanonical a.fst, psEncodeCheckedAdmissionsCanonical b.fst with
      | .ok x,.ok y =>
          if x != y || a.snd.map psNameToString != b.snd.map psNameToString then
            throw (IO.userError "ordinary canonical declarations/partial names changed")
      | _,_ => throw (IO.userError "ordinary fixture encoding refused")
  | _,_ => throw (IO.userError "ordinary success/refusal boundary changed")

def testOrdinaryExpansion : IO Unit := do
  let nat := PsExpr.constE psNatName []
  let binder := psRootName "n"
  let definition := PsDeclaration.definitionDecl (psRootName "constant") [] nat (.lit (.natural 7))
  let name := psRootName "loop"
  let type := PsExpr.forallE binder nat nat .explicit
  let body := PsExpr.lam binder nat (.app (.constE name []) (.bvar 0)) .explicit
  let recursive := PsDeclaration.partialDecl name [] type body
  let scenarios : List (Prod (List PsDeclaration) Bool) := [
    ([],true),([definition],true),([recursive],true),([definition,recursive],true),([recursive,definition],true),
    ([definition,definition],false),
    ([PsDeclaration.axiomDecl (psRootName "forbidden") [] nat],false),
    ([PsDeclaration.opaqueDecl (psRootName "forbidden") [] nat (.lit (.natural 0))],false),
    ([PsDeclaration.partialDecl name [] nat (.lit (.natural 0))],false),
    ([PsDeclaration.partialDecl name [] (PsExpr.forallE binder nat (.constE (psRootName "Missing") []) .explicit) body],false),
    ([PsDeclaration.definitionDecl (psOrdinaryBodyName name) [] type body,recursive],false)
  ]
  for scenario in scenarios do requireSame scenario.fst scenario.snd
  let many := (List.range 10000).map fun index =>
    PsDeclaration.definitionDecl (PsName.num (psRootName "large") index) [] nat (.lit (.natural index))
  match psOrdinaryExpandWorker many psSelfHostProdPreludeEnvironment with
  | .error error => throw (IO.userError error)
  | .ok result =>
      if result.fst.length != 10000 || !result.snd.isEmpty then
        throw (IO.userError "large ordinary traversal lost declarations")
  IO.println "PSC1_ORDINARY_EXPANSION: all-input accumulator/worker equality; canonical ordering; duplicate/axiom/opaque/witness/body-collision refusals;10000 declarations"

