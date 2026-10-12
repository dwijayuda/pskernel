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
  -- Lean RC4 class type constructors expose coll/idx/elem/valid as
  -- explicit parameters; the generated constructor and projection hide
  -- those same parameters implicitly. Conflating these Pi telescopes makes
  -- source class specialization fail before any indexing proof is checked.
  let classParameters := fun body =>
    psLogicPi 0 "coll" typeU
      (psLogicPi 1 "idx" typeV
        (psLogicPi 2 "elem" outputElem
          (psLogicPi 3 "valid" outputValid body)))
  let paramLams := fun body =>
    psLogicLam 0 "coll" typeU
      (psLogicLam 1 "idx" typeV
        (psLogicLam 2 "elem" outputElem
          (psLogicLam 3 "valid" outputValid body .implicit)
          .implicit) .implicit) .implicit
  [ .inductiveDecl (.mk name [u, v, w]
      (classParameters classSort) 4 0 [ctor] true),
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


-- M1 selected Type-0 optional-indexing foundation. Option and Inhabited are
-- currently Type-0-only in the executable prelude. This is a checked subset,
-- NOT a claim of full RC4 GetElem? universe polymorphism or panic semantics.
-- Keep an explicit superclass dictionary as a computational field, rather
-- than silently synthesizing an independent (potentially different) GetElem.
def psStandardGetElemOptionalName : PsName := psRootName "GetElem?"

def psStandardGetElemOptionalClass : List PsDeclaration :=
  let name := psStandardGetElemOptionalName
  let ctor := psNameAppendStr name "mk"
  let u := psRootName "u"
  let v := psRootName "v"
  let levels : List PsLevel := [.param u, .param v]
  let coll := PsExpr.fvar 0
  let idx := PsExpr.fvar 1
  let elem := PsExpr.fvar 2
  let valid := PsExpr.fvar 3
  let self := PsExpr.fvar 4
  let typeU := PsExpr.sortE (.succ (.param u))
  let typeV := PsExpr.sortE (.succ (.param v))
  let typeZero := PsExpr.sortE (.succ .zero)
  let outputElem := PsExpr.app
    (.constE (psRootName "outParam") [.succ (.succ .zero)]) typeZero
  let validType := psLogicPi 30 "xs" coll
    (psLogicPi 31 "i" idx (.sortE .zero))
  let validLevel := PsLevel.succ (.max (.param u) (.param v))
  let outputValid := PsExpr.app
    (.constE (psRootName "outParam") [validLevel]) validType
  let family := psLogicApply (.constE name levels)
    (psStandardGetElemArgs coll idx elem valid)
  let superclass := psLogicApply
    (.constE psStandardGetElemName [.param u, .param v, .zero])
    (psStandardGetElemArgs coll idx elem valid)
  let optionalType := psLogicPi 5 "xs" coll
    (psLogicPi 6 "i" idx (psSelfHostOptionOf elem))
  let panicType := psLogicPi 9 "inhabited"
    (psStandardInhabitedType elem)
    (psLogicPi 10 "xs" coll
      (psLogicPi 11 "i" idx elem)) .instanceImplicit
  let params := fun body =>
    psLogicPi 0 "coll" typeU
      (psLogicPi 1 "idx" typeV
        (psLogicPi 2 "elem" outputElem
          (psLogicPi 3 "valid" outputValid body .implicit)
          .implicit) .implicit) .implicit
  let classParams := fun body =>
    psLogicPi 0 "coll" typeU
      (psLogicPi 1 "idx" typeV
        (psLogicPi 2 "elem" outputElem
          (psLogicPi 3 "valid" outputValid body)))
  let paramLams := fun body =>
    psLogicLam 0 "coll" typeU
      (psLogicLam 1 "idx" typeV
        (psLogicLam 2 "elem" outputElem
          (psLogicLam 3 "valid" outputValid body .implicit)
          .implicit) .implicit) .implicit
  let fields := psLogicPi 5 "toGetElem" superclass
    (psLogicPi 6 "getElem?" optionalType
      (psLogicPi 7 "getElem!" panicType family))
  let projection := fun (text : String) (index : Nat) (type : PsExpr) =>
    .definitionDecl (psNameAppendStr name text) [u, v]
      (params (psLogicPi 4 "self" family type .instanceImplicit))
      (paramLams (psLogicLam 4 "self" family
        (.proj name index self) .instanceImplicit))
  [ .inductiveDecl (.mk name [u, v]
      (classParams (.sortE (.succ (.max (.param u) (.param v)))))
      4 0 [ctor] true),
    .constructorDecl (.mk ctor [u, v]
      (params fields) name 0 4 3 []),
    projection "toGetElem" 0 superclass,
    projection "getElem?" 1 optionalType,
    projection "getElem!" 2 panicType ]

-- Source-class inheritance and dictionary erasure must agree on the exact
-- Core family. Use a low-priority checked dictionary projection, not an
-- automatic axiom or a Bool-to-Prop shortcut.
def psStandardGetElemOptionalSuperclassInstance : PsDeclaration :=
  let name := psNameAppendStr (psRootName "PsStandard") "instGetElemFromOptional"
  let optional := psStandardGetElemOptionalName
  let u := psRootName "u"
  let v := psRootName "v"
  let levels : List PsLevel := [.param u, .param v]
  let coll := PsExpr.fvar 0
  let idx := PsExpr.fvar 1
  let elem := PsExpr.fvar 2
  let valid := PsExpr.fvar 3
  let family := psLogicApply (.constE optional levels)
    (psStandardGetElemArgs coll idx elem valid)
  let base := psLogicApply (.constE psStandardGetElemName
    [.param u, .param v, .zero])
    (psStandardGetElemArgs coll idx elem valid)
  let params := fun body =>
    psLogicPi 0 "coll" (.sortE (.succ (.param u)))
      (psLogicPi 1 "idx" (.sortE (.succ (.param v)))
        (psLogicPi 2 "elem" psPreludeTypeType
          (psLogicPi 3 "valid"
            (psLogicPi 30 "xs" coll
              (psLogicPi 31 "i" idx (.sortE .zero)))
            body .implicit) .implicit) .implicit) .implicit
  let lams := fun body =>
    psLogicLam 0 "coll" (.sortE (.succ (.param u)))
      (psLogicLam 1 "idx" (.sortE (.succ (.param v)))
        (psLogicLam 2 "elem" psPreludeTypeType
          (psLogicLam 3 "valid"
            (psLogicPi 30 "xs" coll
              (psLogicPi 31 "i" idx (.sortE .zero)))
            body .implicit) .implicit) .implicit) .implicit
  let value := psLogicLam 4 "self" family (.proj optional 0 (.fvar 4))
    .instanceImplicit
  .definitionDecl name [u, v]
    (params (psLogicPi 4 "self" family base .instanceImplicit))
    (lams value)

def psStandardGetElemOptionalDeclarations : List PsDeclaration :=
  psStandardGetElemOptionalClass ++ [psStandardGetElemOptionalSuperclassInstance]

def psStandardGetElemOptionalExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardGetElemExtend environment
  let environment := psStandardGetElemOptionalDeclarations.foldl
    (fun env decl => (psEnvironmentAdd env decl).getD env) environment
  let instanceEntry : PsInstanceEntry := {
    value := .constE (psNameAppendStr (psRootName "PsStandard")
      "instGetElemFromOptional")
      [.zero, .zero]
    type := psDeclarationType psStandardGetElemOptionalSuperclassInstance
    levelParams := [psRootName "u", psRootName "v"]
    priority := 100
    className := some psStandardGetElemName }
  { environment with
    classes := psStandardGetElemOptionalName :: environment.classes
    classParameters := (psStandardGetElemOptionalName,
      { outputs := [2, 3], outputLevels := [] : PsClassParameters }) ::
        environment.classParameters
    instances := psInstanceIndexAdd environment.instances instanceEntry }
