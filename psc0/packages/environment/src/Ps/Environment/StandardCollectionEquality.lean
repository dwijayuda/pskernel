import Ps.Environment.StandardEquality

-- A source-level recursive list comparison is a checked function-valued
-- List.rec worker. It returns a predicate on the right list; only the left
-- recursive child supplies the inductive hypothesis. Every element comparison
-- uses the existing BEq α dictionary. No backend equality intrinsic is added.
def psStandardBEqListName : PsName :=
  psNameAppendStr psListName "beq"

def psStandardBEqListDeclaration : PsDeclaration :=
  let u := psRootName "u"
  let level := PsLevel.param u
  let alpha := PsExpr.fvar 0
  let elemDictionary := PsExpr.app (.constE (psRootName "BEq") [level]) alpha
  let list := psSelfHostListOf alpha level
  let bool := PsExpr.constE psBoolName []
  let boolMotive := psLogicLam 18 "_" bool bool
  let resultArrow := psLogicPi 19 "right" list bool
  let outerMotive := psLogicLam 20 "_" list resultArrow
  let innerMotive := psLogicLam 21 "_" list bool
  let recursor := PsExpr.constE psSelfHostListRecName [.succ .zero, level]
  let outerRecursor := PsExpr.constE psSelfHostListRecName [.succ level, level]
  let innerConsNone := psLogicLam 11 "rightHead" alpha
    (psLogicLam 12 "rightTail" list
      (psLogicLam 13 "rightIH" bool (.constE psBoolFalseName [])))
  let nilMinor := psLogicLam 6 "right" list
    (psLogicApply recursor
      [alpha, innerMotive, .constE psBoolTrueName [],
       innerConsNone, .fvar 6])
  let elemEquality := psLogicApply
    (.constE (psNameAppendStr (psRootName "BEq") "beq") [level])
    [alpha, .fvar 1, .fvar 7, .fvar 11]
  let tailEquality := .app (.fvar 9) (.fvar 12)
  let consEquality := psLogicApply
    (.constE (psNameAppendStr psBoolName "rec") [.succ .zero])
    [boolMotive, .constE psBoolFalseName [], tailEquality, elemEquality]
  let innerConsSome := psLogicLam 11 "rightHead" alpha
    (psLogicLam 12 "rightTail" list
      (psLogicLam 13 "rightIH" bool consEquality))
  let consMinor := psLogicLam 7 "leftHead" alpha
    (psLogicLam 8 "leftTail" list
      (psLogicLam 9 "leftIH" resultArrow
        (psLogicLam 10 "right" list
          (psLogicApply recursor
            [alpha, innerMotive, .constE psBoolFalseName [],
             innerConsSome, .fvar 10]))))
  let body := psLogicApply outerRecursor
    [alpha, outerMotive, nilMinor, consMinor, .fvar 2]
  let type := psLogicPi 0 "α" (.sortE (.succ level))
    (psLogicPi 1 "dictionary" elemDictionary
      (psLogicPi 2 "left" list resultArrow) .instanceImplicit) .implicit
  let value := psLogicLam 0 "α" (.sortE (.succ level))
    (psLogicLam 1 "dictionary" elemDictionary
      (psLogicLam 2 "left" list body) .instanceImplicit) .implicit
  .definitionDecl psStandardBEqListName [u] type value

def psStandardBEqListInstance : PsDeclaration :=
  let u := psRootName "u"
  let level := PsLevel.param u
  let alpha := PsExpr.fvar 0
  let elemDictionary := PsExpr.app (.constE (psRootName "BEq") [level]) alpha
  let list := psSelfHostListOf alpha level
  let classType := PsExpr.app (.constE (psRootName "BEq") [level]) list
  let method := psLogicLam 2 "left" list
    (psLogicLam 3 "right" list
      (psLogicApply (.constE psStandardBEqListName [level])
        [alpha, .fvar 1, .fvar 2, .fvar 3]))
  let result := psLogicApply
    (.constE (psNameAppendStr (psRootName "BEq") "mk") [level])
    [list, method]
  let type := psLogicPi 0 "α" (.sortE (.succ level))
    (psLogicPi 1 "dictionary" elemDictionary classType .instanceImplicit) .implicit
  let value := psLogicLam 0 "α" (.sortE (.succ level))
    (psLogicLam 1 "dictionary" elemDictionary result .instanceImplicit) .implicit
  .definitionDecl (psNameAppendStr (psRootName "PsStandard") "instBEqList")
    [u] type value

def psStandardBEqListDeclarations : List PsDeclaration :=
  [psStandardBEqListDeclaration, psStandardBEqListInstance]

def psStandardPreludeDeclarationsWithCollectionBEq : List PsDeclaration :=
  psStandardPreludeDeclarations ++ psStandardBEqListDeclarations

def psStandardCollectionBEqExtend (environment : PsEnvironment) :
    PsEnvironment :=
  let environment := psStandardPreludeExtend environment
  let environment := psStandardBEqListDeclarations.foldl
    (fun current decl => (psEnvironmentAdd current decl).getD current) environment
  let instanceName := psDeclarationName psStandardBEqListInstance
  { environment with
    instances := psInstanceIndexAdd environment.instances {
      value := .constE instanceName ((psDeclarationLevelParams psStandardBEqListInstance).map PsLevel.param)
      levelParams := psDeclarationLevelParams psStandardBEqListInstance
      type := psDeclarationType psStandardBEqListInstance
      className := some (psRootName "BEq") } }
