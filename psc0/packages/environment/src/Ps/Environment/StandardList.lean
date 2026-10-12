import Ps.Environment.StandardOption

-- Selected RC4 List operations, defined entirely with the checked List.rec
-- eliminator. The current portable Standard roster uses Type-0 parameters,
-- with no runtime axioms or special cases for these public functions.
def psStandardListRecursor : PsExpr :=
  .constE psSelfHostListRecName [.succ .zero]

def psStandardListLengthDeclaration : PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let listAlpha := psSelfHostListOf alpha
  let nat := PsExpr.constE psNatName []
  let motive := psLogicLam 2 "_" listAlpha nat
  let step := psLogicLam 3 "head" alpha
    (psLogicLam 4 "tail" listAlpha
      (psLogicLam 5 "ih" nat
        (.app (.constE psNatSuccName []) (.fvar 5))))
  let type := psLogicPi 0 "α" psPreludeTypeType
    (psLogicPi 1 "xs" listAlpha nat) .implicit
  let body := psLogicApply psStandardListRecursor
    [alpha, motive, .lit (.natural 0), step, .fvar 1]
  let value := psLogicLam 0 "α" psPreludeTypeType
    (psLogicLam 1 "xs" listAlpha body) .implicit
  .definitionDecl (psNameAppendStr psListName "length") [] type value

def psStandardListMapDeclaration : PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let beta := PsExpr.fvar 1
  let listAlpha := psSelfHostListOf alpha
  let listBeta := psSelfHostListOf beta
  let arrow := psLogicPi 5 "element" alpha beta
  let motive := psLogicLam 5 "_" listAlpha listBeta
  let step := psLogicLam 6 "head" alpha
    (psLogicLam 7 "tail" listAlpha
      (psLogicLam 8 "ih" listBeta
        (psSelfHostListConsOf beta (.app (.fvar 2) (.fvar 6)) (.fvar 8))))
  let type := psLogicPi 0 "α" psPreludeTypeType
    (psLogicPi 1 "β" psPreludeTypeType
      (psLogicPi 2 "f" arrow
        (psLogicPi 3 "xs" listAlpha listBeta)) .implicit) .implicit
  let body := psLogicApply psStandardListRecursor
    [alpha, motive, psSelfHostListNilOf beta, step, .fvar 3]
  let value := psLogicLam 0 "α" psPreludeTypeType
    (psLogicLam 1 "β" psPreludeTypeType
      (psLogicLam 2 "f" arrow
        (psLogicLam 3 "xs" listAlpha body)) .implicit) .implicit
  .definitionDecl (psNameAppendStr psListName "map") [] type value

def psStandardListAppendDeclaration : PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let listAlpha := psSelfHostListOf alpha
  let motive := psLogicLam 6 "_" listAlpha listAlpha
  let step := psLogicLam 3 "head" alpha
    (psLogicLam 4 "tail" listAlpha
      (psLogicLam 5 "ih" listAlpha
        (psSelfHostListConsOf alpha (.fvar 3) (.fvar 5))))
  let type := psLogicPi 0 "α" psPreludeTypeType
    (psLogicPi 1 "xs" listAlpha
      (psLogicPi 2 "ys" listAlpha listAlpha)) .implicit
  let body := psLogicApply psStandardListRecursor
    [alpha, motive, .fvar 2, step, .fvar 1]
  let value := psLogicLam 0 "α" psPreludeTypeType
    (psLogicLam 1 "xs" listAlpha
      (psLogicLam 2 "ys" listAlpha body)) .implicit
  .definitionDecl (psNameAppendStr psListName "append") [] type value

def psStandardListFilterDeclaration : PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let listAlpha := psSelfHostListOf alpha
  let bool := PsExpr.constE psBoolName []
  let predicate := psLogicPi 6 "value" alpha bool
  let motive := psLogicLam 6 "_" listAlpha listAlpha
  let boolMotive := psLogicLam 7 "_" bool listAlpha
  let step := psLogicLam 3 "head" alpha
    (psLogicLam 4 "tail" listAlpha
      (psLogicLam 5 "ih" listAlpha
        (psLogicApply (.constE (psNameAppendStr psBoolName "rec") [.succ .zero])
          [boolMotive, .fvar 5, psSelfHostListConsOf alpha (.fvar 3) (.fvar 5),
           .app (.fvar 1) (.fvar 3)])))
  let type := psLogicPi 0 "α" psPreludeTypeType
    (psLogicPi 1 "p" predicate
      (psLogicPi 2 "xs" listAlpha listAlpha)) .implicit
  let body := psLogicApply psStandardListRecursor
    [alpha, motive, psSelfHostListNilOf alpha, step, .fvar 2]
  let value := psLogicLam 0 "α" psPreludeTypeType
    (psLogicLam 1 "p" predicate
      (psLogicLam 2 "xs" listAlpha body)) .implicit
  .definitionDecl (psNameAppendStr psListName "filter") [] type value

-- foldl uses a continuation-valued List.rec motive, avoiding a second
-- recursive evaluator rule while keeping the order f (f init x₁) x₂ exact.
def psStandardListFoldlDeclaration : PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let beta := PsExpr.fvar 1
  let listAlpha := psSelfHostListOf alpha
  let functionType := psLogicPi 10 "acc" beta
    (psLogicPi 11 "item" alpha beta)
  let accumulatorType := psLogicPi 12 "acc" beta beta
  let motive := psLogicLam 12 "_" listAlpha accumulatorType
  let initial := psLogicLam 5 "acc" beta (.fvar 5)
  let step := psLogicLam 6 "head" alpha
    (psLogicLam 7 "tail" listAlpha
      (psLogicLam 8 "ih" accumulatorType
        (psLogicLam 9 "acc" beta
          (.app (.fvar 8)
            (psLogicApply (.fvar 2) [.fvar 9, .fvar 6])))))
  let type := psLogicPi 0 "α" psPreludeTypeType
    (psLogicPi 1 "β" psPreludeTypeType
      (psLogicPi 2 "f" functionType
        (psLogicPi 3 "init" beta
          (psLogicPi 4 "xs" listAlpha beta))) .implicit) .implicit
  let worker := psLogicApply psStandardListRecursor
    [alpha, motive, initial, step, .fvar 4]
  let value := psLogicLam 0 "α" psPreludeTypeType
    (psLogicLam 1 "β" psPreludeTypeType
      (psLogicLam 2 "f" functionType
        (psLogicLam 3 "init" beta
          (psLogicLam 4 "xs" listAlpha (.app worker (.fvar 3))))) .implicit) .implicit
  .definitionDecl (psNameAppendStr psListName "foldl") [] type value

def psStandardListDeclarations : List PsDeclaration :=
  [psStandardListLengthDeclaration, psStandardListMapDeclaration,
   psStandardListAppendDeclaration, psStandardListFilterDeclaration,
   psStandardListFoldlDeclaration]

def psStandardPreludeDeclarationsWithList : List PsDeclaration :=
  psStandardPreludeDeclarationsWithOption ++ psStandardListDeclarations

def psStandardListExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardOptionExtend environment
  psStandardListDeclarations.foldl (fun env decl =>
    (psEnvironmentAdd env decl).getD env) environment
