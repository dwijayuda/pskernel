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


-- Universe-polymorphic optional-indexing foundation with checked Option
-- and Inhabited applications at the inferred element universe.
-- Keep an explicit superclass dictionary as a computational field, rather
-- than silently synthesizing an independent (potentially different) GetElem.
def psStandardGetElemOptionalName : PsName := psRootName "GetElem?"

def psStandardGetElemOptionalClass : List PsDeclaration :=
  let name := psStandardGetElemOptionalName
  let ctor := psNameAppendStr name "mk"
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
  let outputValid := PsExpr.app
    (.constE (psRootName "outParam") [validLevel]) validType
  let family := psLogicApply (.constE name levels)
    (psStandardGetElemArgs coll idx elem valid)
  let superclass := psLogicApply
    (.constE psStandardGetElemName [.param u, .param v, .param w])
    (psStandardGetElemArgs coll idx elem valid)
  let optionalType := psLogicPi 5 "xs" coll
    (psLogicPi 6 "i" idx (psSelfHostOptionOf elem (.param w)))
  let panicType := psLogicPi 9 "inhabited"
    (psStandardInhabitedType elem (.succ (.param w)))
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
    .definitionDecl (psNameAppendStr name text) [u, v, w]
      (params (psLogicPi 4 "self" family type .instanceImplicit))
      (paramLams (psLogicLam 4 "self" family
        (.proj name index self) .instanceImplicit))
  [ .inductiveDecl (.mk name [u, v, w]
      (classParams (.sortE (.succ (.max (.param u) (.max (.param v) (.param w))))))
      4 0 [ctor] true),
    .constructorDecl (.mk ctor [u, v, w]
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
  let w := psRootName "w"
  let levels : List PsLevel := [.param u, .param v, .param w]
  let coll := PsExpr.fvar 0
  let idx := PsExpr.fvar 1
  let elem := PsExpr.fvar 2
  let valid := PsExpr.fvar 3
  let family := psLogicApply (.constE optional levels)
    (psStandardGetElemArgs coll idx elem valid)
  let base := psLogicApply (.constE psStandardGetElemName
    [.param u, .param v, .param w])
    (psStandardGetElemArgs coll idx elem valid)
  let params := fun body =>
    psLogicPi 0 "coll" (.sortE (.succ (.param u)))
      (psLogicPi 1 "idx" (.sortE (.succ (.param v)))
        (psLogicPi 2 "elem" (.sortE (.succ (.param w)))
          (psLogicPi 3 "valid"
            (psLogicPi 30 "xs" coll
              (psLogicPi 31 "i" idx (.sortE .zero)))
            body .implicit) .implicit) .implicit) .implicit
  let lams := fun body =>
    psLogicLam 0 "coll" (.sortE (.succ (.param u)))
      (psLogicLam 1 "idx" (.sortE (.succ (.param v)))
        (psLogicLam 2 "elem" (.sortE (.succ (.param w)))
          (psLogicLam 3 "valid"
            (psLogicPi 30 "xs" coll
              (psLogicPi 31 "i" idx (.sortE .zero)))
            body .implicit) .implicit) .implicit) .implicit
  let value := psLogicLam 4 "self" family (.proj optional 0 (.fvar 4))
    .instanceImplicit
  .definitionDecl name [u, v, w]
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
      [.param (psRootName "u"), .param (psRootName "v"), .param (psRootName "w")]
    type := psDeclarationType psStandardGetElemOptionalSuperclassInstance
    levelParams := [psRootName "u", psRootName "v", psRootName "w"]
    priority := 100
    className := some psStandardGetElemName }
  { environment with
    classes := psStandardGetElemOptionalName :: environment.classes
    classParameters := (psStandardGetElemOptionalName,
      { outputs := [2, 3], outputLevels := [2] : PsClassParameters }) ::
        environment.classParameters
    instances := psInstanceIndexAdd environment.instances instanceEntry }


-- Checked M1 lawfulness contract. This is a Prop-valued class, not a
-- runtime certificate: neither field may be constructed without an actual
-- kernel-checkable equality proof. All element-dependent laws share the
-- same element universe as the superclass and optional dictionary.
--
-- The two fields follow Init/GetElem.lean at pinned Lean 4.35.0-rc4:
--  * optional lookup is equal to the dependent decidable branch;
--  * bang lookup is equal, propositionally, to matching Option with
--    Inhabited.default on none. The latter equality is NOT permission
--    for a runtime implementation to silently return default: the required
--    out-of-bounds panic remains a separate compiler/runtime obligation.
def psStandardLawfulGetElemName : PsName := psRootName "LawfulGetElem"

def psStandardLawfulGetElemClass : List PsDeclaration :=
  let name := psStandardLawfulGetElemName
  let ctor := psNameAppendStr name "mk"
  let u := psRootName "u"
  let v := psRootName "v"
  let w := psRootName "w"
  let levels : List PsLevel := [.param u, .param v, .param w]
  let coll := PsExpr.fvar 0
  let idx := PsExpr.fvar 1
  let elem := PsExpr.fvar 2
  let valid := PsExpr.fvar 3
  let optionalDict := PsExpr.fvar 4
  let self := PsExpr.fvar 5
  let typeU := PsExpr.sortE (.succ (.param u))
  let typeV := PsExpr.sortE (.succ (.param v))
  let optionElem := psSelfHostOptionOf elem (.param w)
  let validType := psLogicPi 30 "xs" coll
    (psLogicPi 31 "i" idx (.sortE .zero))
  let outputElem := PsExpr.app
    (.constE (psRootName "outParam") [.succ (.succ (.param w))])
    (.sortE (.succ (.param w)))
  let validLevel := PsLevel.succ (.max (.param u) (.param v))
  let outputValid := PsExpr.app
    (.constE (psRootName "outParam") [validLevel]) validType
  let optFamily := psLogicApply (.constE psStandardGetElemOptionalName levels)
    (psStandardGetElemArgs coll idx elem valid)
  let family := psLogicApply (.constE name levels)
    (psStandardGetElemArgs coll idx elem valid ++ [optionalDict])
  let parameters := fun body =>
    psLogicPi 0 "coll" typeU
      (psLogicPi 1 "idx" typeV
        (psLogicPi 2 "elem" outputElem
          (psLogicPi 3 "valid" outputValid body .implicit)
          .implicit) .implicit) .implicit
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
  let getOptional := fun (xs i : PsExpr) =>
    psLogicApply (.constE (psNameAppendStr psStandardGetElemOptionalName "getElem?") levels)
      (psStandardGetElemArgs coll idx elem valid ++ [optionalDict, xs, i])
  let getBang := fun (dict xs i : PsExpr) =>
    psLogicApply (.constE (psNameAppendStr psStandardGetElemOptionalName "getElem!") levels)
      (psStandardGetElemArgs coll idx elem valid ++ [optionalDict, dict, xs, i])
  let superclass :=
    psLogicApply (.constE (psNameAppendStr psStandardGetElemOptionalName "toGetElem") levels)
      (psStandardGetElemArgs coll idx elem valid ++ [optionalDict])
  let getChecked := fun (xs i proof : PsExpr) =>
    psLogicApply
      (.constE (psNameAppendStr psStandardGetElemName "getElem")
        [.param u, .param v, .param w])
      (psStandardGetElemArgs coll idx elem valid ++
        [superclass, xs, i, proof])
  let xs := PsExpr.fvar 7
  let i := PsExpr.fvar 8
  let decision := PsExpr.fvar 9
  let proposition := psLogicApply valid [xs, i]
  let positive := psLogicLam 10 "proof" proposition
    (psSelfHostOptionSomeOf elem (getChecked xs i (.fvar 10)) (.param w))
  let negative := psLogicLam 11 "notProof"
    (PsExpr.app (.constE (psRootName "Not") []) proposition)
    (psSelfHostOptionNoneOf elem (.param w))
  let expectedOpt := psLogicApply (.constE (psRootName "dite") [.succ (.param w)])
    [optionElem, proposition, decision, positive, negative]
  let optionalLaw := psLogicPi 7 "xs" coll
    (psLogicPi 8 "i" idx
      (psLogicPi 9 "decision" (psDecisionType proposition)
        (psLogicEq (.succ (.param w)) optionElem (getOptional xs i) expectedOpt)
        .instanceImplicit))
  let inhabited := PsExpr.fvar 10
  let bangXs := PsExpr.fvar 11
  let bangI := PsExpr.fvar 12
  let option := getOptional bangXs bangI
  let motive := psLogicLam 13 "_value" optionElem elem
  let someBranch := psLogicLam 14 "value" elem (.fvar 14)
  let folded := psLogicApply
    (.constE psSelfHostOptionRecName [.succ (.param w), .param w])
    [elem, motive, psStandardInhabitedDefault (.succ (.param w)) elem inhabited,
      someBranch, option]
  let bangLaw := psLogicPi 10 "inhabited" (psStandardInhabitedType elem (.succ (.param w)))
    (psLogicPi 11 "xs" coll
      (psLogicPi 12 "i" idx
        (psLogicEq (.succ (.param w)) elem (getBang inhabited bangXs bangI) folded)))
    .instanceImplicit
  let projection := fun (field : String) (index : Nat) (fieldType : PsExpr) =>
    .definitionDecl (psNameAppendStr name field) [u, v, w]
      (parameters (psLogicPi 4 "optional" optFamily
        (psLogicPi 5 "self" family fieldType .instanceImplicit)
        .instanceImplicit))
      (paramLams (psLogicLam 4 "optional" optFamily
        (psLogicLam 5 "self" family (.proj name index self) .instanceImplicit)
        .instanceImplicit))
  [ .inductiveDecl (.mk name [u, v, w]
      (classParameters (psLogicPi 4 "optional" optFamily (.sortE .zero) .instanceImplicit))
      5 0 [ctor] true),
    .constructorDecl (.mk ctor [u, v, w]
      (parameters (psLogicPi 4 "optional" optFamily
        (psLogicPi 5 "getElem?_def" optionalLaw
          (psLogicPi 6 "getElem!_def" bangLaw family))
        .instanceImplicit)) name 0 5 2 []),
    projection "getElem?_def" 0 optionalLaw,
    projection "getElem!_def" 1 bangLaw ]

def psStandardLawfulGetElemExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardGetElemOptionalExtend environment
  let environment := psStandardLawfulGetElemClass.foldl
    (fun env decl => (psEnvironmentAdd env decl).getD env) environment
  { environment with
    classes := psStandardLawfulGetElemName :: environment.classes
    classParameters := (psStandardLawfulGetElemName,
      { outputs := [2, 3], outputLevels := [2] : PsClassParameters }) ::
        environment.classParameters }

-- Core outOfBounds is definitionally equal to Inhabited.default,
-- while verified target IR explicitly traps at every supported universe.
def psStandardOutOfBoundsDeclaration : PsDeclaration :=
  let w := psRootName "w"
  let alpha := PsExpr.fvar 0
  let dictionary := PsExpr.fvar 1
  let type := psLogicPi 0 "α" (.sortE (.succ (.param w)))
    (psLogicPi 1 "inhabited" (psStandardInhabitedType alpha (.succ (.param w))) alpha
      .instanceImplicit) .implicit
  let value := psLogicLam 0 "α" (.sortE (.succ (.param w)))
    (psLogicLam 1 "inhabited" (psStandardInhabitedType alpha (.succ (.param w)))
      (psStandardInhabitedDefault (.succ (.param w)) alpha dictionary)
      .instanceImplicit) .implicit
  .definitionDecl (psRootName "outOfBounds") [w] type value

-- Kernel-checked reusable bang implementation; a Some result returns the
-- element and None calls the nonreturning outOfBounds declaration.
def psStandardGetElemBangDefaultDeclaration : PsDeclaration :=
  let w := psRootName "w"
  let alpha := PsExpr.fvar 0
  let dictionary := PsExpr.fvar 1
  let candidate := PsExpr.fvar 2
  let option := psSelfHostOptionOf alpha (.param w)
  let motive := psLogicLam 3 "_" option alpha
  let someBranch := psLogicLam 4 "value" alpha (.fvar 4)
  let failure := psLogicApply (.constE (psRootName "outOfBounds") [.param w])
    [alpha, dictionary]
  let result := psLogicApply (.constE psSelfHostOptionRecName [.succ (.param w), .param w])
    [alpha, motive, failure, someBranch, candidate]
  let type := psLogicPi 0 "α" (.sortE (.succ (.param w)))
    (psLogicPi 1 "inhabited" (psStandardInhabitedType alpha (.succ (.param w)))
      (psLogicPi 2 "candidate" option alpha) .instanceImplicit) .implicit
  let value := psLogicLam 0 "α" (.sortE (.succ (.param w)))
    (psLogicLam 1 "inhabited" (psStandardInhabitedType alpha (.succ (.param w)))
      (psLogicLam 2 "candidate" option result) .instanceImplicit) .implicit
  .definitionDecl (psNameAppendStr psStandardGetElemOptionalName "getElem!Default")
    [w] type value


-- The low-priority M1 default derives GetElem? ONLY from a checked
-- GetElem dictionary plus a dependent Decidable witness at every index.
-- The proofs carried by Decidable are kernel validated and runtime erased.
-- Element universes remain explicit through every constructor and recursor.
def psStandardOptionalDefaultDecisionDeclarations : List PsDeclaration :=
  let truth := PsExpr.constE (psRootName "True") []
  let falsity := PsExpr.constE (psRootName "False") []
  let yes := psLogicApply
    (.constE (psDecisionName "Decidable.isTrue") [])
    [truth, .constE (psNameAppendStr (psRootName "True") "intro") []]
  let noProof := psLogicLam 0 "h" falsity (.fvar 0)
  let no := psLogicApply
    (.constE (psDecisionName "Decidable.isFalse") [])
    [falsity, noProof]
  [ .definitionDecl
      (psNameAppendStr (psRootName "PsStandard") "instDecidableTrue")
      [] (psDecisionType truth) yes,
    .definitionDecl
      (psNameAppendStr (psRootName "PsStandard") "instDecidableFalse")
      [] (psDecisionType falsity) no ]

def psStandardGetElemOptionalDefaultInstance : PsDeclaration :=
  let name := psNameAppendStr (psRootName "PsStandard") "instGetElemOptionalDefault"
  let u := psRootName "u"
  let v := psRootName "v"
  let w := psRootName "w"
  let levels : List PsLevel := [.param u, .param v, .param w]
  let coll := PsExpr.fvar 0
  let idx := PsExpr.fvar 1
  let elem := PsExpr.fvar 2
  let valid := PsExpr.fvar 3
  let getDictionary := PsExpr.fvar 4
  let decide := PsExpr.fvar 5
  let base := psLogicApply
    (.constE psStandardGetElemName [.param u, .param v, .param w])
    (psStandardGetElemArgs coll idx elem valid)
  let optional := psLogicApply
    (.constE psStandardGetElemOptionalName levels)
    (psStandardGetElemArgs coll idx elem valid)
  let validType := psLogicPi 30 "xs" coll
    (psLogicPi 31 "i" idx (.sortE .zero))
  let indexedDecision := psLogicPi 6 "xs" coll
    (psLogicPi 7 "i" idx
      (psDecisionType (psLogicApply valid [.fvar 6, .fvar 7])))
  let parameters := fun body =>
    psLogicPi 0 "coll" (.sortE (.succ (.param u)))
      (psLogicPi 1 "idx" (.sortE (.succ (.param v)))
        (psLogicPi 2 "elem" (.sortE (.succ (.param w)))
          (psLogicPi 3 "valid" validType body .implicit)
          .implicit) .implicit) .implicit
  let parameterLams := fun body =>
    psLogicLam 0 "coll" (.sortE (.succ (.param u)))
      (psLogicLam 1 "idx" (.sortE (.succ (.param v)))
        (psLogicLam 2 "elem" (.sortE (.succ (.param w)))
          (psLogicLam 3 "valid" validType body .implicit)
          .implicit) .implicit) .implicit
  let xs := PsExpr.fvar 8
  let i := PsExpr.fvar 9
  let prop := psLogicApply valid [xs, i]
  let h := PsExpr.fvar 10
  let get := psLogicApply
    (.constE (psNameAppendStr psStandardGetElemName "getElem")
      [.param u, .param v, .param w])
    (psStandardGetElemArgs coll idx elem valid ++
      [getDictionary, xs, i, h])
  let yes := psLogicLam 10 "h" prop (psSelfHostOptionSomeOf elem get (.param w))
  let no := psLogicLam 11 "notH"
    (.app (.constE (psRootName "Not") []) prop)
    (psSelfHostOptionNoneOf elem (.param w))
  let witness := psLogicApply decide [xs, i]
  let result := psLogicApply (.constE (psRootName "dite") [.succ (.param w)])
    [psSelfHostOptionOf elem (.param w), prop, witness, yes, no]
  let getOptional := psLogicLam 8 "xs" coll
    (psLogicLam 9 "i" idx result)
  let inhabited := PsExpr.fvar 12
  let bangXs := PsExpr.fvar 13
  let bangI := PsExpr.fvar 14
  let optionalResult := psLogicApply getOptional [bangXs, bangI]
  let bang := psLogicApply
    (.constE (psNameAppendStr psStandardGetElemOptionalName
      "getElem!Default") [.param w])
    [elem, inhabited, optionalResult]
  let getBang := psLogicLam 12 "inhabited" (psStandardInhabitedType elem (.succ (.param w)))
    (psLogicLam 13 "xs" coll
      (psLogicLam 14 "i" idx bang))
    .instanceImplicit
  let value := psLogicApply
    (.constE (psNameAppendStr psStandardGetElemOptionalName "mk") levels)
    (psStandardGetElemArgs coll idx elem valid ++
      [getDictionary, getOptional, getBang])
  let type := parameters (psLogicPi 4 "checked" base
    (psLogicPi 5 "decide" indexedDecision optional .instanceImplicit)
    .instanceImplicit)
  let body := parameterLams
    (psLogicLam 4 "checked" base
      (psLogicLam 5 "decide" indexedDecision value .instanceImplicit)
      .instanceImplicit)
  .definitionDecl name [u, v, w] type body

-- M1 checked lawfulness for the EXACT derived optional dictionary.
-- This instance never asserts the law for an arbitrary, user-supplied GetElem?
-- dictionary. It specializes LawfulGetElem's implicit superclass parameter
-- to the default dictionary's actual term. Independent decision witnesses
-- are reconciled by PsStandard.decidableUnique (checked in Decision.lean).
def psStandardLawfulGetElemOptionalDefaultDeclarations : List PsDeclaration :=
  let name := psDecisionName "PsStandard.instLawfulGetElemOptionalDefault"
  let unfoldingLemma := psDecisionName "PsStandard.getElemOptionalDefaultDefinition"
  let optionalLemma := psDecisionName "PsStandard.getElemOptionalDefaultLaw"
  let bangLemma := psDecisionName "PsStandard.getElemBangDefaultLaw"
  let u := psRootName "u"
  let v := psRootName "v"
  let w := psRootName "w"
  let levels : List PsLevel := [.param u, .param v, .param w]
  let coll := PsExpr.fvar 0
  let idx := PsExpr.fvar 1
  let elem := PsExpr.fvar 2
  let valid := PsExpr.fvar 3
  let checked := PsExpr.fvar 4
  let decide := PsExpr.fvar 5
  let base := psLogicApply (.constE psStandardGetElemName
    [.param u, .param v, .param w])
    (psStandardGetElemArgs coll idx elem valid)
  let validType := psLogicPi 30 "xs" coll
    (psLogicPi 31 "i" idx (.sortE .zero))
  let indexedDecision := psLogicPi 6 "xs" coll
    (psLogicPi 7 "i" idx
      (psDecisionType (psLogicApply valid [.fvar 6, .fvar 7])))
  let params := fun body =>
    psLogicPi 0 "coll" (.sortE (.succ (.param u)))
      (psLogicPi 1 "idx" (.sortE (.succ (.param v)))
        (psLogicPi 2 "elem" (.sortE (.succ (.param w)))
          (psLogicPi 3 "valid" validType body .implicit)
          .implicit) .implicit) .implicit
  let lams := fun body =>
    psLogicLam 0 "coll" (.sortE (.succ (.param u)))
      (psLogicLam 1 "idx" (.sortE (.succ (.param v)))
        (psLogicLam 2 "elem" (.sortE (.succ (.param w)))
          (psLogicLam 3 "valid" validType body .implicit)
          .implicit) .implicit) .implicit
  let getOpt := psLogicApply
    (.constE (psDecisionName "PsStandard.instGetElemOptionalDefault") levels)
    (psStandardGetElemArgs coll idx elem valid ++ [checked, decide])
  let lawful := psLogicApply (.constE psStandardLawfulGetElemName levels)
    (psStandardGetElemArgs coll idx elem valid ++ [getOpt])
  let xs := PsExpr.fvar 20
  let i := PsExpr.fvar 21
  let decision := PsExpr.fvar 22
  let proposition := psLogicApply valid [xs, i]
  let optType := psSelfHostOptionOf elem (.param w)
  let ownDecision := psLogicApply decide [xs, i]
  let checkedGet := fun (h : PsExpr) =>
    psLogicApply (.constE (psNameAppendStr psStandardGetElemName "getElem")
      [.param u, .param v, .param w])
      (psStandardGetElemArgs coll idx elem valid ++ [checked, xs, i, h])
  let positive := psLogicLam 23 "h" proposition
    (psSelfHostOptionSomeOf elem (checkedGet (.fvar 23)) (.param w))
  let negative := psLogicLam 24 "notH"
    (psDecisionNot proposition) (psSelfHostOptionNoneOf elem (.param w))
  let decideOptional := fun (d : PsExpr) =>
    psLogicApply (.constE (psRootName "dite") [.succ (.param w)])
      [optType, proposition, d, positive, negative]
  let getOptionalMethod := psLogicApply
    (.constE (psNameAppendStr psStandardGetElemOptionalName "getElem?") levels)
    (psStandardGetElemArgs coll idx elem valid ++ [getOpt, xs, i])
  let optEq := fun (left right : PsExpr) =>
    psLogicEq (.succ (.param w)) optType left right
  let decisionEq := psLogicApply
    (.constE (psDecisionName "PsStandard.decidableUnique") [])
    [proposition, ownDecision, decision]
  let other := PsExpr.fvar 25
  let motive := psLogicLam 25 "other" (psDecisionType proposition)
    (psLogicLam 26 "equal" (psLogicEq (.succ .zero)
      (psDecisionType proposition) ownDecision other)
      (optEq getOptionalMethod (decideOptional other)))
  let proofOpt := psLogicApply (.constE (psNameAppendStr psEqName "rec")
      [.zero, .succ .zero])
    [psDecisionType proposition, ownDecision, motive,
     psLogicRefl (.succ (.param w)) optType getOptionalMethod,
     decision, decisionEq]
  let optionalLaw := psLogicLam 20 "xs" coll
    (psLogicLam 21 "i" idx
      (psLogicLam 22 "decision" (psDecisionType proposition)
        proofOpt .instanceImplicit))
  let inhabited := PsExpr.fvar 27
  let bangXs := PsExpr.fvar 28
  let bangI := PsExpr.fvar 29
  let optionalCall := psLogicApply
    (.constE (psNameAppendStr psStandardGetElemOptionalName "getElem?") levels)
    (psStandardGetElemArgs coll idx elem valid ++
      [getOpt, bangXs, bangI])
  let bangCall := psLogicApply
    (.constE (psNameAppendStr psStandardGetElemOptionalName "getElem!") levels)
    (psStandardGetElemArgs coll idx elem valid ++
      [getOpt, inhabited, bangXs, bangI])
  let bangMotive := psLogicLam 30 "_" optType elem
  let someBranch := psLogicLam 31 "value" elem (.fvar 31)
  let matchOptional := psLogicApply
    (.constE psSelfHostOptionRecName [.succ (.param w), .param w])
    [elem, bangMotive,
     psStandardInhabitedDefault (.succ (.param w)) elem inhabited,
     someBranch, optionalCall]
  let bangProof := psLogicLam 27 "inhabited" (psStandardInhabitedType elem (.succ (.param w)))
    (psLogicLam 28 "xs" coll
      (psLogicLam 29 "i" idx
        (psLogicRefl (.succ (.param w)) elem bangCall)))
    .instanceImplicit
  -- Independent checked lemma declarations make each definitional contract
  -- auditable before constructor assembly. Their bodies contain no axioms.
  -- First check definitional equality of this precise dictionary projection
  -- before transporting it across independently supplied Decidable evidence.
  let unfoldingType := params (psLogicPi 4 "checked" base
    (psLogicPi 5 "decide" indexedDecision
      (psLogicPi 20 "xs" coll
        (psLogicPi 21 "i" idx
          (optEq getOptionalMethod (decideOptional ownDecision)))
      .instanceImplicit) .instanceImplicit))
  let unfoldingValue := lams (psLogicLam 4 "checked" base
    (psLogicLam 5 "decide" indexedDecision
      (psLogicLam 20 "xs" coll
        (psLogicLam 21 "i" idx
          (psLogicRefl (.succ (.param w)) optType getOptionalMethod)))
      .instanceImplicit) .instanceImplicit)
  let optionalLemmaType := params (psLogicPi 4 "checked" base
    (psLogicPi 5 "decide" indexedDecision
      (psLogicPi 20 "xs" coll
        (psLogicPi 21 "i" idx
          (psLogicPi 22 "decision" (psDecisionType proposition)
            (optEq getOptionalMethod (decideOptional decision))
            .instanceImplicit))) .instanceImplicit) .instanceImplicit)
  let optionalLemmaValue := lams (psLogicLam 4 "checked" base
    (psLogicLam 5 "decide" indexedDecision optionalLaw .instanceImplicit)
    .instanceImplicit)
  let bangLemmaType := params (psLogicPi 4 "checked" base
    (psLogicPi 5 "decide" indexedDecision
      (psLogicPi 27 "inhabited" (psStandardInhabitedType elem (.succ (.param w)))
        (psLogicPi 28 "xs" coll
          (psLogicPi 29 "i" idx
            (psLogicEq (.succ (.param w)) elem bangCall matchOptional)))
        .instanceImplicit) .instanceImplicit) .instanceImplicit)
  let bangLemmaValue := lams (psLogicLam 4 "checked" base
    (psLogicLam 5 "decide" indexedDecision bangProof .instanceImplicit)
    .instanceImplicit)
  let value := psLogicApply
    (.constE (psNameAppendStr psStandardLawfulGetElemName "mk") levels)
    (psStandardGetElemArgs coll idx elem valid ++
      [getOpt, optionalLaw, bangProof])
  -- The bang proof above is deliberately reflexive only if the specialized
  -- optional dictionary's bang method reduces to match/none=default.
  -- The official checker rejects it if the two definitions drift.
  let type := params (psLogicPi 4 "checked" base
    (psLogicPi 5 "decide" indexedDecision lawful .instanceImplicit)
    .instanceImplicit)
  let body := lams (psLogicLam 4 "checked" base
    (psLogicLam 5 "decide" indexedDecision value .instanceImplicit)
    .instanceImplicit)
  [ .definitionDecl unfoldingLemma [u, v, w] unfoldingType unfoldingValue,
    .definitionDecl optionalLemma [u, v, w] optionalLemmaType optionalLemmaValue,
    .definitionDecl bangLemma [u, v, w] bangLemmaType bangLemmaValue,
    .definitionDecl name [u, v, w] type body ]

def psStandardGetElemOptionalDefaultDeclarations : List PsDeclaration :=
  psStandardOptionalDefaultDecisionDeclarations ++
    [psStandardGetElemOptionalDefaultInstance] ++
    psStandardLawfulGetElemOptionalDefaultDeclarations

-- Use the same checked declaration closure for elaboration and execution.
-- No new trusted primitive, Boolean proof shortcut, or fallback conversion.
def psStandardGetElemOptionalDefaultExtend (environment : PsEnvironment) :
    PsEnvironment :=
  let environment := psStandardGetElemOptionalDefaultDeclarations.foldl
    (fun env declaration => psPreludeAdd env declaration) environment
  let trueName := psNameAppendStr (psRootName "PsStandard") "instDecidableTrue"
  let falseName := psNameAppendStr (psRootName "PsStandard") "instDecidableFalse"
  let optionalName := psNameAppendStr (psRootName "PsStandard") "instGetElemOptionalDefault"
  let lawfulName := psDecisionName "PsStandard.instLawfulGetElemOptionalDefault"
  let choices : List (PsName × PsName × Nat × List PsName) :=
    [ (trueName, psDecidableName, 1000, []),
      (falseName, psDecidableName, 1000, []),
      (optionalName, psStandardGetElemOptionalName, 100,
        [psRootName "u", psRootName "v", psRootName "w"]),
      (lawfulName, psStandardLawfulGetElemName, 100,
        [psRootName "u", psRootName "v", psRootName "w"]) ]
  let index := choices.foldl (fun index (name, className, priority, levelParams) =>
    match psEnvironmentFind environment name with
    | some declaration =>
      psInstanceIndexAdd index {
        value := .constE name (levelParams.map PsLevel.param)
        type := psDeclarationType declaration
        className := some className
        priority
        levelParams }
    | none => index) environment.instances
  { environment with instances := index }
