import Ps.Environment.StandardExcept

-- Lean 4.35.0-rc4, Init/GetElem.lean: proof-carrying class foundation.
-- The collection and index choose the result type and validity predicate.
-- Both are true outParam arguments; the validity predicate produces Prop.
-- Runtime access cannot occur without a checked instance and validity proof.
--
-- This module does not install an unsound List/Array instance or turn a
-- Boolean bounds check into a proposition. Lean-compatible index instances,
-- GetElem? and notation/tactic elaboration require their own checked closure.
def psStandardGetElemName : PsName := psRootName "GetElem"

def psStandardGetElemLevels : List PsName :=
  [psRootName "u", psRootName "v", psRootName "w"]

def psStandardGetElemArgs (coll idx elem valid : PsExpr) : List PsExpr :=
  [coll, idx, elem, valid]

def psStandardGetElemClass : List PsDeclaration :=
  let name := psStandardGetElemName
  let ctor := psNameAppendStr name "mk"
  let projection := psNameAppendStr name "getElem"
  let u := psRootName "u"
  let v := psRootName "v"
  let w := psRootName "w"
  let levels : List PsLevel := [.param u, .param v, .param w]
  let coll := PsExpr.fvar 0
  let idx := PsExpr.fvar 1
  let elem := PsExpr.fvar 2
  let valid := PsExpr.fvar 3
  let self := PsExpr.fvar 4
  let typeU := PsExpr.sortE (.succ (.param u))
  let typeV := PsExpr.sortE (.succ (.param v))
  let typeW := PsExpr.sortE (.succ (.param w))
  let outputElem := PsExpr.app
    (.constE (psRootName "outParam") [.succ (.succ (.param w))]) typeW
  let validType := psLogicPi 30 "xs" coll
    (psLogicPi 31 "i" idx (.sortE .zero))
  let validLevel := PsLevel.succ (.max (.param u) (.param v))
  let outputValid := PsExpr.app (.constE (psRootName "outParam") [validLevel]) validType
  let classSort := PsExpr.sortE
    (.succ (.max (.param u) (.max (.param v) (.param w))))
  let family := psLogicApply (.constE name levels)
    (psStandardGetElemArgs coll idx elem valid)
  let fieldType := psLogicPi 5 "xs" coll
    (psLogicPi 6 "i" idx
      (psLogicPi 7 "h" (psLogicApply valid [.fvar 5, .fvar 6]) elem))
  let parameters := fun body =>
    psLogicPi 0 "coll" typeU
      (psLogicPi 1 "idx" typeV
        (psLogicPi 2 "elem" outputElem
          (psLogicPi 3 "valid" outputValid body .implicit)
          .implicit) .implicit) .implicit
  let paramLams := fun body =>
    psLogicLam 0 "coll" typeU
      (psLogicLam 1 "idx" typeV
        (psLogicLam 2 "elem" outputElem
          (psLogicLam 3 "valid" outputValid body .implicit)
          .implicit) .implicit) .implicit
  [ .inductiveDecl (.mk name [u, v, w]
      (parameters classSort) 4 0 [ctor] true),
    .constructorDecl (.mk ctor [u, v, w]
      (parameters (psLogicPi 8 "getElem" fieldType family))
      name 0 4 1 []),
    .definitionDecl projection [u, v, w]
      (parameters (psLogicPi 4 "self" family fieldType .instanceImplicit))
      (paramLams (psLogicLam 4 "self" family
        (.proj name 0 self) .instanceImplicit)) ]

-- Structure/class metadata is part of the selected deterministic Standard
-- payload, including output argument positions and output-only universe w.
def psStandardGetElemExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardGetElemClass.foldl
    (fun env decl => (psEnvironmentAdd env decl).getD env) environment
  { environment with
    classes := psStandardGetElemName :: environment.classes
    classParameters := (psStandardGetElemName,
      { outputs := [2, 3], outputLevels := [2] : PsClassParameters }) ::
        environment.classParameters }
