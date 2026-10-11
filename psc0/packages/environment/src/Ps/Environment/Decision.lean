import Ps.Environment.Connectives

-- Trusted primitive signatures follow the pinned RC4 reference; the provider
-- checks relative to the reconstructed portable prelude. Decidable RC4 carries
-- one computational Bool and an erased reflection proof.
def psDecisionName (text : String) : PsName :=
  (text.splitOn ".").foldl psNameAppendStr .anonymous

def psDecisionType (proposition : PsExpr) : PsExpr :=
  .app (.constE psDecidableName []) proposition

def psDecisionDeclarations : List PsDeclaration :=
  let prop := PsExpr.sortE .zero
  let boolean := PsExpr.constE psBoolName []
  let p := PsExpr.fvar 0
  let notP := PsExpr.app (.constE (psRootName "Not") []) p
  let parameter := fun body => psLogicPi 0 "p" prop body .implicit
  let decision := psDecisionType p
  let decisionCtor := fun (name : String) (proof : PsExpr) =>
    PsDeclaration.axiomDecl (psDecisionName name) []
      (parameter (psLogicPi 1 "h" proof decision))
  let decEq := fun (name : String) (type : PsExpr) =>
    PsDeclaration.axiomDecl (psDecisionName name) []
      (psLogicPi 0 "a" type (psLogicPi 1 "b" type
        (psDecisionType (psLogicEq (.succ .zero) type (.fvar 0) (.fvar 1)))))
  let u := psRootName "u"
  let alpha := PsExpr.fvar 4
  let diteType := psLogicPi 4 "α" (.sortE (.param u))
    (psLogicPi 0 "c" prop (psLogicPi 1 "h" decision
      (psLogicPi 2 "t" (psLogicPi 5 "_" p alpha)
        (psLogicPi 3 "e" (psLogicPi 5 "_" notP alpha) alpha)) .instanceImplicit)) .implicit
  [ .definitionDecl (psRootName "outParam") [u]
      (psLogicPi 0 "α" (.sortE (.param u)) (.sortE (.param u)))
      (psLogicLam 0 "α" (.sortE (.param u)) (.fvar 0)),
    decisionCtor "Decidable.isTrue" p,
    decisionCtor "Decidable.isFalse" notP,
    .axiomDecl (psDecisionName "Decidable.decide") []
      (psLogicPi 0 "p" prop (psLogicPi 1 "self" decision boolean .instanceImplicit)),
    decEq "Nat.decEq" (.constE psNatName []),
    decEq "String.decEq" (.constE psStringName []),
    .axiomDecl (psRootName "dite") [u] diteType ]

def psDecisionPrelude (environment : PsEnvironment) : PsEnvironment :=
  let environment := psDecisionDeclarations.foldl (fun current declaration =>
    (psEnvironmentAdd current declaration).getD current) environment
  let instances := ["Bool.decEq", "Nat.decEq", "String.decEq"].foldl (fun index name =>
    let name := psDecisionName name
    match psEnvironmentFind environment name with
    | none => index
    | some declaration => psInstanceIndexAdd index {
        value := .constE name []
        type := psDeclarationType declaration
        className := some psDecidableName }) environment.instances
  { environment with instances, classes := psDecidableName :: environment.classes }
