import Ps.Environment.StandardArray

-- Pinned Init.Prelude: OfNat (α : Type u) (n : Nat), with an ordinary
-- checked value field. Nat/Int instances preserve the existing exact literals.
def psStandardOfNatDeclarations : List PsDeclaration :=
  let name := psRootName "OfNat"
  let ctor := psNameAppendStr name "mk"
  let method := psNameAppendStr name "ofNat"
  let u := psRootName "u"
  let levels : List PsLevel := [.param u]
  let sort := PsExpr.sortE (.succ (.param u))
  let alpha := PsExpr.fvar 0
  let n := PsExpr.fvar 1
  let self := PsExpr.fvar 2
  let nat := PsExpr.constE psNatName []
  let family := psLogicApply (.constE name levels) [alpha, n]
  let params := fun body => psLogicPi 0 "α" sort
    (psLogicPi 1 "n" nat body .implicit) .implicit
  let methodParams := fun body => psLogicPi 0 "α" sort
    (psLogicPi 1 "n" nat body) .implicit
  let methodLams := fun body => psLogicLam 0 "α" sort
    (psLogicLam 1 "n" nat body) .implicit
  let instanceDecl := fun (suffix : String) (type value : PsExpr) =>
    PsDeclaration.definitionDecl
      (psNameAppendStr (psRootName "PsStandard") ("instOfNat" ++ suffix)) []
      (psLogicPi 1 "n" nat (psLogicApply (.constE name [.zero]) [type, n]))
      (psLogicLam 1 "n" nat (psLogicApply (.constE ctor [.zero]) [type, n, value]))
  [ .inductiveDecl (.mk name [u]
      (psLogicPi 0 "α" sort (psLogicPi 1 "n" nat sort)) 2 0 [ctor] true),
    .constructorDecl (.mk ctor [u]
      (params (psLogicPi 2 "ofNat" alpha family)) name 0 2 1 []),
    .definitionDecl method [u]
      (methodParams (psLogicPi 2 "self" family alpha .instanceImplicit))
      (methodLams (psLogicLam 2 "self" family (.proj name 0 self) .instanceImplicit)),
    instanceDecl "Nat" nat n,
    instanceDecl "Int" (.constE psIntName []) (.app (.constE psIntOfNatName []) n) ]

-- Lean 4.35.0 Init/Control/Id.lean supplies this instance explicitly:
-- Id is not instance-transparent. Reuse the provided dictionary by ordinary
-- checked conversion; do not broaden instance-search transparency.
def psStandardOfNatId : PsDeclaration :=
  let u := psRootName "u"
  let level := PsLevel.param u
  let alpha := PsExpr.fvar 0
  let n := PsExpr.fvar 1
  let id := PsExpr.app (.constE (psRootName "Id") [level]) alpha
  let family := fun type => psLogicApply (.constE (psRootName "OfNat") [level]) [type, n]
  .definitionDecl (psDecisionName "PsStandard.instOfNatId") [u]
    (psLogicPi 0 "α" (.sortE (.succ level))
      (psLogicPi 1 "n" (.constE psNatName [])
        (psLogicPi 2 "self" (family alpha) (family id) .instanceImplicit) .implicit) .implicit)
    (psLogicLam 0 "α" (.sortE (.succ level))
      (psLogicLam 1 "n" (.constE psNatName [])
        (psLogicLam 2 "self" (family alpha) (.fvar 2) .instanceImplicit) .implicit) .implicit)

def psStandardNumericDeclarations : List PsDeclaration :=
  psStandardOfNatDeclarations ++ [psStandardOfNatId]

def psStandardNumericExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardNumericDeclarations.foldl psPreludeAdd environment
  let name := psRootName "OfNat"
  let instances := (psStandardNumericDeclarations.drop 3).foldl (fun index declaration =>
    psInstanceIndexAdd index {
      value := .constE (psDeclarationName declaration)
        ((psDeclarationLevelParams declaration).map PsLevel.param)
      levelParams := psDeclarationLevelParams declaration
      type := psDeclarationType declaration
      className := some name }) environment.instances
  { environment with
    classes := name :: environment.classes
    classParameters := (name, {}) :: environment.classParameters
    instances }
