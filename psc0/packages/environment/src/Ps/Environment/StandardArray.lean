import Ps.Environment.StandardListIndex

-- Checked logical model. Array primitives retain their audited runtime
-- representation; only explicit mk/toList conversions cross the boundary.
def psStandardArrayToList (alpha xs : PsExpr) : PsExpr :=
  psOrderCall "Array.toList" [alpha, xs]

def psStandardArrayMk (alpha xs : PsExpr) : PsExpr :=
  psOrderCall "Array.mk" [alpha, xs]

def psStandardArraySize (alpha xs : PsExpr) : PsExpr :=
  psOrderCall "Array.size" [alpha, xs]

def psStandardArrayBound (alpha xs i : PsExpr) : PsExpr :=
  psOrderCall "Nat.lt" [i, psStandardArraySize alpha xs]

def psStandardArrayDeclarations : List PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let xs := PsExpr.fvar 1
  let list := psSelfHostListOf alpha
  let array := psPreludeArrayOf alpha
  let motive := PsExpr.fvar 2
  let self := PsExpr.fvar 3
  let u := psRootName "u"
  let ctor := psDecisionName "Array.mk"
  let params := fun body => psLogicPi 0 "α" psPreludeTypeType body .implicit
  let lams := fun body => psLogicLam 0 "α" psPreludeTypeType body .implicit
  let made := psStandardArrayMk alpha xs
  let recType := params
    (psLogicPi 2 "motive" (psLogicPi 3 "self" array (.sortE (.param u)))
      (psLogicPi 4 "mk" (psLogicPi 1 "toList" list (.app motive made))
        (psLogicPi 3 "self" array (.app motive self))) .implicit)
  [ .inductiveDecl (.mk psArrayName [] psPreludeArrayType 1 0 [ctor] true),
    .constructorDecl (.mk ctor [] (params (psLogicPi 1 "toList" list array))
      psArrayName 0 1 1 []),
    .recursorDecl (.mk (psDecisionName "Array.rec") [u] recType [psArrayName] 1 0 1 1),
    .definitionDecl (psDecisionName "Array.toList") []
      (params (psLogicPi 3 "self" array list))
      (lams (psLogicLam 3 "self" array (.proj psArrayName 0 self))) ]

-- Total persistent replacement; an out-of-range index leaves the list intact.
def psStandardArrayListSetDeclaration : PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let xs := PsExpr.fvar 1
  let value := PsExpr.fvar 2
  let i := PsExpr.fvar 3
  let head := PsExpr.fvar 4
  let tail := PsExpr.fvar 5
  let ih := PsExpr.fvar 6
  let previous := PsExpr.fvar 7
  let list := psSelfHostListOf alpha
  let result := psLogicPi 3 "i" psOrderNat list
  let step := psLogicLam 4 "head" alpha (psLogicLam 5 "tail" list
    (psLogicLam 6 "ih" result (psLogicLam 3 "i" psOrderNat
      (psOrderNatRec (.succ .zero) (psLogicLam 3 "i" psOrderNat list)
        (psSelfHostListConsOf alpha value tail)
        (psLogicLam 7 "previous" psOrderNat (psLogicLam 8 "_" list
          (psSelfHostListConsOf alpha head (.app ih previous)))) i))))
  let body := psLogicApply psStandardListRecursor
    [alpha, psLogicLam 1 "xs" list result,
     psLogicLam 3 "i" psOrderNat (psSelfHostListNilOf alpha), step, xs]
  .definitionDecl (psDecisionName "$psc0Standard.arrayListSetWorker") []
    (psLogicPi 0 "α" psPreludeTypeType
      (psLogicPi 2 "value" alpha (psLogicPi 1 "xs" list result)) .implicit)
    (psLogicLam 0 "α" psPreludeTypeType
      (psLogicLam 2 "value" alpha (psLogicLam 1 "xs" list body)) .implicit)

def psStandardArrayPrimitiveDeclarations : List PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let xs := PsExpr.fvar 1
  let i := PsExpr.fvar 2
  let value := PsExpr.fvar 3
  let beta := PsExpr.fvar 4
  let fn := PsExpr.fvar 5
  let init := PsExpr.fvar 6
  let start := PsExpr.fvar 7
  let stop := PsExpr.fvar 8
  let array := psPreludeArrayOf alpha
  let list := psStandardArrayToList alpha xs
  let params := fun body => psLogicPi 0 "α" psPreludeTypeType body .implicit
  let lams := fun body => psLogicLam 0 "α" psPreludeTypeType body .implicit
  let defn := fun name type body =>
    PsDeclaration.definitionDecl (psDecisionName name) [] type body
  let listSet := psOrderCall "$psc0Standard.arrayListSetWorker" [alpha, value, list, i]
  let setter := psLogicLam 1 "xs" array (psLogicLam 2 "i" psOrderNat
    (psLogicLam 3 "value" alpha (psStandardArrayMk alpha listSet)))
  let h := PsExpr.fvar 9
  let bound := psStandardArrayBound alpha xs i
  let sliced := psOrderCall "List.take" [alpha,
    psOrderCall "Nat.sub" [stop, start],
    psOrderCall "List.drop" [alpha, start, list]]
  [ defn "Array.emptyWithCapacity" psPreludeArrayEmptyType
      (lams (psLogicLam 2 "capacity" psOrderNat
        (psStandardArrayMk alpha (psSelfHostListNilOf alpha)))),
    defn "Array.size" psPreludeArraySizeType
      (lams (psLogicLam 1 "xs" array (psListIndexLength alpha list))),
    defn "Array.push" psPreludeArrayPushType
      (lams (psLogicLam 1 "xs" array (psLogicLam 3 "value" alpha
        (psStandardArrayMk alpha (psOrderCall "List.append" [alpha, list,
          psSelfHostListConsOf alpha value (psSelfHostListNilOf alpha)]))))),
    defn "Array.getD" psPreludeArrayGetDType
      (lams (psLogicLam 1 "xs" array (psLogicLam 2 "i" psOrderNat
        (psLogicLam 3 "fallback" alpha
          (psLogicApply (.constE (psDecisionName "Option.getD") [.zero])
            [alpha, psListIndexOptionalGet alpha list i, value]))))),
    defn "Array.getInternal"
      (params (psLogicPi 1 "xs" array (psLogicPi 2 "i" psOrderNat
        (psLogicPi 9 "h" bound alpha))))
      (lams (psLogicLam 1 "xs" array (psLogicLam 2 "i" psOrderNat
        (psLogicLam 9 "h" bound (psListIndexProofGet alpha list i h))))),
    defn "Array.setIfInBounds" psPreludeArraySetIfInBoundsType (lams setter),
    defn "Array.set"
      (params (psLogicPi 1 "xs" array (psLogicPi 2 "i" psOrderNat
        (psLogicPi 3 "value" alpha (psLogicPi 9 "h" bound array)))))
      (lams (psLogicLam 1 "xs" array (psLogicLam 2 "i" psOrderNat
        (psLogicLam 3 "value" alpha (psLogicLam 9 "h" bound
          (psStandardArrayMk alpha listSet)))))),
    defn "Array.map" psPreludeArrayMapType
      (lams (psLogicLam 4 "β" psPreludeTypeType
        (psLogicLam 5 "f" (psLogicPi 10 "value" alpha beta)
          (psLogicLam 1 "xs" array
            (psStandardArrayMk beta (psOrderCall "List.map" [alpha, beta, fn, list]))))
        .implicit)),
    defn "Array.foldl" psPreludeArrayFoldlType
      (lams (psLogicLam 4 "β" psPreludeTypeType
        (psLogicLam 5 "f" (psLogicPi 10 "acc" beta (psLogicPi 11 "value" alpha beta))
          (psLogicLam 6 "init" beta (psLogicLam 1 "xs" array
            (psLogicLam 7 "start" psOrderNat (psLogicLam 8 "stop" psOrderNat
              (psOrderCall "List.foldl" [alpha, beta, fn, init, sliced]))))))
        .implicit)) ]

def psStandardArrayInstances : List PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let xs := PsExpr.fvar 1
  let i := PsExpr.fvar 2
  let h := PsExpr.fvar 3
  let array := psPreludeArrayOf alpha
  let valid := psLogicLam 1 "xs" array (psLogicLam 2 "i" psOrderNat
    (psStandardArrayBound alpha xs i))
  let args := psStandardGetElemArgs array psOrderNat alpha valid
  let family := fun name more => psLogicApply
    (.constE (psDecisionName name) [.zero, .zero, .zero]) (args ++ more)
  let checkedName := psDecisionName "PsStandard.instGetElemArray"
  let checked := .app (.constE checkedName []) alpha
  let decision := psLogicLam 1 "xs" array (psLogicLam 2 "i" psOrderNat
    (psOrderCall "Nat.decLt" [i, psStandardArraySize alpha xs]))
  let optional := family "PsStandard.instGetElemOptionalDefault" [checked, decision]
  let params := fun body => psLogicPi 0 "α" psPreludeTypeType body .implicit
  let lams := fun body => psLogicLam 0 "α" psPreludeTypeType body .implicit
  [ .definitionDecl checkedName [] (params (family "GetElem" []))
      (lams (family "GetElem.mk" [psLogicLam 1 "xs" array
        (psLogicLam 2 "i" psOrderNat (psLogicLam 3 "h"
          (psStandardArrayBound alpha xs i) (psOrderCall "Array.getInternal" [alpha, xs, i, h])))])),
    .definitionDecl (psDecisionName "PsStandard.instGetElemOptionalArray") []
      (params (family "GetElem?" [])) (lams optional),
    .definitionDecl (psDecisionName "PsStandard.instLawfulGetElemArray") []
      (params (family "LawfulGetElem" [optional]))
      (lams (family "PsStandard.instLawfulGetElemOptionalDefault" [checked, decision])) ]

def psStandardArrayPublicDeclarations : List PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let xs := PsExpr.fvar 1
  let i := PsExpr.fvar 2
  let inhabited := PsExpr.fvar 3
  let array := psPreludeArrayOf alpha
  let size := psStandardArraySize alpha xs
  let fin := psStandardFinOf size
  let valid := psLogicLam 1 "xs" array (psLogicLam 2 "i" psOrderNat
    (psStandardArrayBound alpha xs i))
  let args := psStandardGetElemArgs array psOrderNat alpha valid
  let dictionary := psOrderCall "PsStandard.instGetElemOptionalArray" [alpha]
  let params := fun body => psLogicPi 0 "α" psPreludeTypeType body .implicit
  let lams := fun body => psLogicLam 0 "α" psPreludeTypeType body .implicit
  let optionalType := params (psLogicPi 1 "xs" array
    (psLogicPi 2 "i" psOrderNat (psSelfHostOptionOf alpha)))
  let optionalBody := lams (psLogicLam 1 "xs" array (psLogicLam 2 "i" psOrderNat
    (psLogicApply (.constE (psDecisionName "GetElem?.getElem?") [.zero, .zero, .zero])
      (args ++ [dictionary, xs, i]))))
  let bangType := params (psLogicPi 3 "inhabited" (psStandardInhabitedType alpha)
    (psLogicPi 1 "xs" array (psLogicPi 2 "i" psOrderNat alpha)) .instanceImplicit)
  let bangBody := lams (psLogicLam 3 "inhabited" (psStandardInhabitedType alpha)
    (psLogicLam 1 "xs" array (psLogicLam 2 "i" psOrderNat
      (psLogicApply (.constE (psDecisionName "GetElem?.getElem!") [.zero, .zero, .zero])
        (args ++ [dictionary, inhabited, xs, i])))) .instanceImplicit)
  [ .definitionDecl (psDecisionName "Array.get") []
      (params (psLogicPi 1 "xs" array (psLogicPi 2 "i" fin alpha)))
      (lams (psLogicLam 1 "xs" array (psLogicLam 2 "i" fin
        (psOrderCall "Array.getInternal" [alpha, xs, psStandardFinVal size i,
          psOrderCall "Fin.isLt" [size, i]])))),
    .definitionDecl (psDecisionName "List.toArray") []
      (params (psLogicPi 1 "xs" (psSelfHostListOf alpha) array))
      (lams (psLogicLam 1 "xs" (psSelfHostListOf alpha) (psStandardArrayMk alpha xs))),
    .definitionDecl (psDecisionName "Array.get?") [] optionalType optionalBody,
    .definitionDecl (psDecisionName "Array.get?Internal") [] optionalType optionalBody,
    .definitionDecl (psDecisionName "Array.get!") [] bangType bangBody,
    .definitionDecl (psDecisionName "Array.get!Internal") [] bangType bangBody ]

-- Kernel catalog and executable catalog are intentionally distinct here:
-- Array's checked structure implements its logical model, not its GC/Vec/JS
-- runtime layout. Model-only operations enter execution via typed intrinsics.
def psStandardArrayAllDeclarations : List PsDeclaration :=
  psStandardArrayDeclarations ++ [psStandardArrayListSetDeclaration] ++
    psStandardArrayPrimitiveDeclarations ++ psStandardArrayInstances ++
    psStandardArrayPublicDeclarations

def psStandardArrayRuntimeDeclarations : List PsDeclaration :=
  psStandardArrayInstances ++ psStandardArrayPublicDeclarations

def psStandardArrayExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardArrayAllDeclarations.foldl
    psSelfHostReplacePreludeAxiom environment
  let instances := psStandardArrayInstances.foldl (fun index declaration =>
    let name := psDeclarationName declaration
    let className := if psNameEq name (psDecisionName "PsStandard.instGetElemArray")
      then psStandardGetElemName
      else if psNameEq name (psDecisionName "PsStandard.instGetElemOptionalArray")
      then psStandardGetElemOptionalName else psStandardLawfulGetElemName
    psInstanceIndexAdd index {
      value := .constE name []
      type := psDeclarationType declaration
      className := some className }) environment.instances
  { environment with instances }
