import Ps.Environment.StandardNumeric

-- Pinned Init.Coe dictionaries, without Lean's transitive closure instances.
-- PSCV0 permits one direct conversion at an expected-type/function/sort boundary.
def psStandardCoercionClass (text : String) (dependent : Bool) : List PsDeclaration :=
  let name := psRootName text
  let ctor := psNameAppendStr name "mk"
  let u := psRootName "u"
  let v := psRootName "v"
  let levels : List PsLevel := [.param u, .param v]
  let sourceSort := PsExpr.sortE (.param u)
  let targetSort := PsExpr.sortE (.param v)
  let classSort := PsExpr.sortE (.max (.max (.succ .zero) (.param u)) (.param v))
  let alpha := PsExpr.fvar 0
  let beta := PsExpr.fvar 1
  let self := PsExpr.fvar 2
  let betaType := if dependent then psLogicPi 3 "value" alpha targetSort else targetSort
  let family := psLogicApply (.constE name levels) [alpha, beta]
  let method := psLogicPi 3 "value" alpha
    (if dependent then .app beta (.fvar 3) else beta)
  let params := fun body => psLogicPi 0 "α" sourceSort
    (psLogicPi 1 (if dependent then "γ" else "β") betaType body .implicit) .implicit
  let lams := fun body => psLogicLam 0 "α" sourceSort
    (psLogicLam 1 (if dependent then "γ" else "β") betaType body .implicit) .implicit
  [ .inductiveDecl (.mk name [u, v]
      (psLogicPi 0 "α" sourceSort
        (psLogicPi 1 (if dependent then "γ" else "β") betaType classSort)) 2 0 [ctor] true),
    .constructorDecl (.mk ctor [u, v]
      (params (psLogicPi 2 "coe" method family)) name 0 2 1 []),
    .definitionDecl (psNameAppendStr name "coe") [u, v]
      (params (psLogicPi 2 "self" family method .instanceImplicit))
      (lams (psLogicLam 2 "self" family (.proj name 0 self) .instanceImplicit)) ]

def psStandardCoercionDeclarations : List PsDeclaration :=
  psStandardCoercionClass "Coe" false ++
  psStandardCoercionClass "CoeFun" true ++
  psStandardCoercionClass "CoeSort" false

def psStandardCoercionExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardCoercionDeclarations.foldl psPreludeAdd environment
  ["Coe", "CoeFun", "CoeSort"].foldl (fun environment text =>
    let name := psRootName text
    let parameters : PsClassParameters :=
      if text == "Coe" then {} else { outputs := [1], outputLevels := [1] }
    { environment with
      classes := name :: environment.classes
      classParameters := (name, parameters) :: environment.classParameters }) environment
