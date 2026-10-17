import Ps.Environment.StandardNatOrder

-- Fin is a checked structure with a computational value and an erased proof.
-- Its bound is a uniform Core parameter, never a stored constructor field.
def psStandardFinOf (bound : PsExpr) : PsExpr :=
  .app (.constE (psRootName "Fin") []) bound

def psStandardFinVal (bound index : PsExpr) : PsExpr :=
  psOrderCall "Fin.val" [bound, index]

def psStandardFinDeclarations : List PsDeclaration :=
  let name := psRootName "Fin"
  let ctor := psDecisionName "Fin.mk"
  let u := psRootName "u"
  let n := PsExpr.fvar 0
  let value := PsExpr.fvar 1
  let proof := PsExpr.fvar 2
  let self := PsExpr.fvar 3
  let motive := PsExpr.fvar 4
  let nat := psOrderNat
  let family := psStandardFinOf n
  let valid := psOrderCall "Nat.lt" [value, n]
  let params := fun body => psLogicPi 0 "n" nat body .implicit
  let lams := fun body => psLogicLam 0 "n" nat body .implicit
  let made := psLogicApply (.constE ctor []) [n, value, proof]
  let fields := fun body => psLogicPi 1 "val" nat
    (psLogicPi 2 "isLt" valid body)
  let recType := params
    (psLogicPi 4 "motive" (psLogicPi 3 "self" family (.sortE (.param u)))
      (psLogicPi 5 "mk" (fields (.app motive made))
        (psLogicPi 3 "self" family (.app motive self))) .implicit)
  [ .inductiveDecl (.mk name [] (psLogicPi 0 "n" nat psPreludeTypeType)
      1 0 [ctor] true),
    .constructorDecl (.mk ctor [] (params (fields family)) name 0 1 2 []),
    .recursorDecl (.mk (psDecisionName "Fin.rec") [u] recType [name] 1 0 1 1),
    .definitionDecl (psDecisionName "Fin.val") []
      (params (psLogicPi 3 "self" family nat))
      (lams (psLogicLam 3 "self" family (.proj name 0 self))),
    .definitionDecl (psDecisionName "Fin.isLt") []
      (params (psLogicPi 3 "self" family
        (psOrderCall "Nat.lt" [.proj name 0 self, n])))
      (lams (psLogicLam 3 "self" family (.proj name 1 self))) ]

-- Adapters preserve the collection's original validity predicate. Fin n's
-- own bound says nothing about a separate collection's length or size.
-- The optional adapter retains exactly the underlying optional superclass;
-- its lawfulness witness requires that same underlying dictionary's laws.
def psStandardFinIndexDeclarations : List PsDeclaration :=
  let u := psRootName "u"
  let w := psRootName "w"
  let levels : List PsLevel := [.param u, .zero, .param w]
  let adapterLevels : List PsLevel := [.param u, .param w]
  let coll := PsExpr.fvar 0
  let elem := PsExpr.fvar 1
  let valid := PsExpr.fvar 2
  let n := PsExpr.fvar 3
  let dictionary := PsExpr.fvar 4
  let lawful := PsExpr.fvar 5
  let xs := PsExpr.fvar 10
  let i := PsExpr.fvar 11
  let proof := PsExpr.fvar 12
  let inhabited := PsExpr.fvar 13
  let decision := PsExpr.fvar 14
  let fin := psStandardFinOf n
  let nat := psOrderNat
  let val := psStandardFinVal n i
  let validType := psLogicPi 20 "xs" coll (psLogicPi 21 "i" nat (.sortE .zero))
  let adaptedValid := psLogicLam 10 "xs" coll
    (psLogicLam 11 "i" fin (psLogicApply valid [xs, val]))
  let originalArgs := psStandardGetElemArgs coll nat elem valid
  let adaptedArgs := psStandardGetElemArgs coll fin elem adaptedValid
  let base := psLogicApply (.constE psStandardGetElemName levels) originalArgs
  let optional := psLogicApply (.constE psStandardGetElemOptionalName levels) originalArgs
  let lawfulOriginal := psLogicApply (.constE psStandardLawfulGetElemName levels)
    (originalArgs ++ [dictionary])
  let params := fun body =>
    psLogicPi 0 "coll" (.sortE (.succ (.param u)))
      (psLogicPi 1 "elem" (.sortE (.succ (.param w)))
        (psLogicPi 2 "valid" validType
          (psLogicPi 3 "n" nat body .implicit) .implicit) .implicit) .implicit
  let lams := fun body =>
    psLogicLam 0 "coll" (.sortE (.succ (.param u)))
      (psLogicLam 1 "elem" (.sortE (.succ (.param w)))
        (psLogicLam 2 "valid" validType
          (psLogicLam 3 "n" nat body .implicit) .implicit) .implicit) .implicit
  let call := fun (name : String) (args : List PsExpr) =>
    psLogicApply (.constE (psDecisionName name) levels) args
  let get := call "GetElem.getElem"
    (originalArgs ++ [dictionary, xs, val, proof])
  let checkedMethod := psLogicLam 10 "xs" coll
    (psLogicLam 11 "i" fin
      (psLogicLam 12 "h" (psLogicApply valid [xs, val]) get))
  let checkedName := psDecisionName "PsStandard.instGetElemFin"
  let checked := .definitionDecl checkedName [u, w]
    (params (psLogicPi 4 "dictionary" base
      (psLogicApply (.constE psStandardGetElemName levels) adaptedArgs)
      .instanceImplicit))
    (lams (psLogicLam 4 "dictionary" base
      (call "GetElem.mk" (adaptedArgs ++ [checkedMethod])) .instanceImplicit))
  let superclass := call "GetElem?.toGetElem" (originalArgs ++ [dictionary])
  let checkedAdapter := psLogicApply (.constE checkedName adapterLevels)
    [coll, elem, valid, n, superclass]
  let optionalMethod := psLogicLam 10 "xs" coll (psLogicLam 11 "i" fin
    (call "GetElem?.getElem?" (originalArgs ++ [dictionary, xs, val])))
  let inhabitedType := psStandardInhabitedType elem (.succ (.param w))
  let bangMethod := psLogicLam 13 "inhabited" inhabitedType
    (psLogicLam 10 "xs" coll (psLogicLam 11 "i" fin
      (call "GetElem?.getElem!" (originalArgs ++ [dictionary, inhabited, xs, val]))))
    .instanceImplicit
  let optionalName := psDecisionName "PsStandard.instGetElemOptionalFin"
  let optionalAdapter := psLogicApply (.constE optionalName adapterLevels)
    [coll, elem, valid, n, dictionary]
  let optionalDecl := .definitionDecl optionalName [u, w]
    (params (psLogicPi 4 "dictionary" optional
      (psLogicApply (.constE psStandardGetElemOptionalName levels) adaptedArgs)
      .instanceImplicit))
    (lams (psLogicLam 4 "dictionary" optional
      (call "GetElem?.mk" (adaptedArgs ++
        [checkedAdapter, optionalMethod, bangMethod])) .instanceImplicit))
  let optionalProof := psLogicLam 10 "xs" coll (psLogicLam 11 "i" fin
    (psLogicLam 14 "decision" (psDecisionType (psLogicApply valid [xs, val]))
      (call "LawfulGetElem.getElem?_def"
        (originalArgs ++ [dictionary, lawful, xs, val, decision]))
      .instanceImplicit))
  let bangProof := psLogicLam 13 "inhabited" inhabitedType
    (psLogicLam 10 "xs" coll (psLogicLam 11 "i" fin
      (call "LawfulGetElem.getElem!_def"
        (originalArgs ++ [dictionary, lawful, inhabited, xs, val]))))
    .instanceImplicit
  let lawfulDecl := .definitionDecl
    (psDecisionName "PsStandard.instLawfulGetElemFin") [u, w]
    (params (psLogicPi 4 "dictionary" optional
      (psLogicPi 5 "lawful" lawfulOriginal
        (psLogicApply (.constE psStandardLawfulGetElemName levels)
          (adaptedArgs ++ [optionalAdapter])) .instanceImplicit) .instanceImplicit))
    (lams (psLogicLam 4 "dictionary" optional
      (psLogicLam 5 "lawful" lawfulOriginal
        (call "LawfulGetElem.mk"
          (adaptedArgs ++ [optionalAdapter, optionalProof, bangProof]))
        .instanceImplicit) .instanceImplicit))
  [checked, optionalDecl, lawfulDecl]

def psStandardFinAllDeclarations : List PsDeclaration :=
  psStandardFinDeclarations ++ psStandardFinIndexDeclarations

def psStandardFinExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardFinAllDeclarations.foldl psPreludeAdd environment
  let instances := psStandardFinIndexDeclarations.foldl (fun index declaration =>
    let name := psDeclarationName declaration
    let className := if psNameEq name (psDecisionName "PsStandard.instGetElemFin")
      then psStandardGetElemName
      else if psNameEq name (psDecisionName "PsStandard.instGetElemOptionalFin")
      then psStandardGetElemOptionalName else psStandardLawfulGetElemName
    psInstanceIndexAdd index {
      value := .constE name ((psDeclarationLevelParams declaration).map PsLevel.param)
      type := psDeclarationType declaration
      levelParams := psDeclarationLevelParams declaration
      className := some className }) environment.instances
  { environment with instances }
