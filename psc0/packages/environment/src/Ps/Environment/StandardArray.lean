import Ps.Environment.StandardListIndex

-- Lean 4.35.0 Init/Prelude.lean and Init/Data/Array/Basic.lean:
-- element universe u is preserved; recursor motive universe is independent.
-- Checked logical model. Array primitives retain their audited runtime
-- representation; only explicit mk/toList conversions cross the boundary.
def psStandardArrayCall (suffix : String) (arguments : List PsExpr)
    (levels : List PsLevel := [.zero]) : PsExpr :=
  psLogicApply (.constE (psNameAppendStr psArrayName suffix) levels) arguments

def psStandardArrayToList (alpha xs : PsExpr) (level : PsLevel := .zero) : PsExpr :=
  psStandardArrayCall "toList" [alpha, xs] [level]

def psStandardArrayMk (alpha xs : PsExpr) (level : PsLevel := .zero) : PsExpr :=
  psStandardArrayCall "mk" [alpha, xs] [level]

def psStandardArraySize (alpha xs : PsExpr) (level : PsLevel := .zero) : PsExpr :=
  psStandardArrayCall "size" [alpha, xs] [level]

def psStandardArrayBound (alpha xs i : PsExpr) (level : PsLevel := .zero) : PsExpr :=
  psOrderCall "Nat.lt" [i, psStandardArraySize alpha xs level]

def psStandardArrayDeclarations : List PsDeclaration :=
  let u := PsLevel.param (psRootName "u")
  let alpha := PsExpr.fvar 0
  let xs := PsExpr.fvar 1
  let list := psSelfHostListOf alpha u
  let array := psPreludeArrayOf alpha u
  let motive := PsExpr.fvar 2
  let self := PsExpr.fvar 3
  let v := psRootName "v"
  let ctor := psDecisionName "Array.mk"
  let params := fun body => psLogicPi 0 "α" (.sortE (.succ u)) body .implicit
  let lams := fun body => psLogicLam 0 "α" (.sortE (.succ u)) body .implicit
  let made := psStandardArrayMk alpha xs u
  let recType := params
    (psLogicPi 2 "motive" (psLogicPi 3 "self" array (.sortE (.param v)))
      (psLogicPi 4 "mk" (psLogicPi 1 "toList" list (.app motive made))
        (psLogicPi 3 "self" array (.app motive self))) .implicit)
  [ .inductiveDecl (.mk psArrayName [psRootName "u"] (psPreludeArrayType u) 1 0 [ctor] true),
    .constructorDecl (.mk ctor [psRootName "u"] (params (psLogicPi 1 "toList" list array))
      psArrayName 0 1 1 []),
    .recursorDecl (.mk (psDecisionName "Array.rec") [v, psRootName "u"] recType [psArrayName] 1 0 1 1),
    .definitionDecl (psDecisionName "Array.toList") [psRootName "u"]
      (params (psLogicPi 3 "self" array list))
      (lams (psLogicLam 3 "self" array (.proj psArrayName 0 self))) ]

-- Total persistent replacement; an out-of-range index leaves the list intact.
def psStandardArrayListSetDeclaration : PsDeclaration :=
  let u := PsLevel.param (psRootName "u")
  let alpha := PsExpr.fvar 0
  let xs := PsExpr.fvar 1
  let value := PsExpr.fvar 2
  let i := PsExpr.fvar 3
  let head := PsExpr.fvar 4
  let tail := PsExpr.fvar 5
  let ih := PsExpr.fvar 6
  let previous := PsExpr.fvar 7
  let list := psSelfHostListOf alpha u
  let result := psLogicPi 3 "i" psOrderNat list
  let step := psLogicLam 4 "head" alpha (psLogicLam 5 "tail" list
    (psLogicLam 6 "ih" result (psLogicLam 3 "i" psOrderNat
      (psOrderNatRec (.succ u) (psLogicLam 3 "i" psOrderNat list)
        (psSelfHostListConsOf alpha value tail u)
        (psLogicLam 7 "previous" psOrderNat (psLogicLam 8 "_" list
          (psSelfHostListConsOf alpha head (.app ih previous) u))) i))))
  let body := psLogicApply (psStandardListRecursor u (.succ u))
    [alpha, psLogicLam 1 "xs" list result,
     psLogicLam 3 "i" psOrderNat (psSelfHostListNilOf alpha u), step, xs]
  .definitionDecl (psDecisionName "$psc0Standard.arrayListSetWorker") [psRootName "u"]
    (psLogicPi 0 "α" (.sortE (.succ u))
      (psLogicPi 2 "value" alpha (psLogicPi 1 "xs" list result)) .implicit)
    (psLogicLam 0 "α" (.sortE (.succ u))
      (psLogicLam 2 "value" alpha (psLogicLam 1 "xs" list body)) .implicit)

def psStandardArrayPrimitiveDeclarations : List PsDeclaration :=
  let u := PsLevel.param (psRootName "u")
  let alpha := PsExpr.fvar 0
  let xs := PsExpr.fvar 1
  let i := PsExpr.fvar 2
  let value := PsExpr.fvar 3
  let beta := PsExpr.fvar 4
  let fn := PsExpr.fvar 5
  let init := PsExpr.fvar 6
  let start := PsExpr.fvar 7
  let stop := PsExpr.fvar 8
  let array := psPreludeArrayOf alpha u
  let list := psStandardArrayToList alpha xs u
  let params := fun body => psLogicPi 0 "α" (.sortE (.succ u)) body .implicit
  let lams := fun body => psLogicLam 0 "α" (.sortE (.succ u)) body .implicit
  let defn := fun name type body =>
    PsDeclaration.definitionDecl (psDecisionName name) [psRootName "u"] type body
  let defnUV := fun name type body =>
    PsDeclaration.definitionDecl (psDecisionName name) [psRootName "u", psRootName "v"] type body
  let v := PsLevel.param (psRootName "v")
  let listSet := psLogicApply (.constE (psDecisionName "$psc0Standard.arrayListSetWorker") [u]) [alpha, value, list, i]
  let setter := psLogicLam 1 "xs" array (psLogicLam 2 "i" psOrderNat
    (psLogicLam 3 "value" alpha (psStandardArrayMk alpha listSet u)))
  let h := PsExpr.fvar 9
  let bound := psStandardArrayBound alpha xs i u
  let sliced := psStandardListCall "take" [alpha,
    psOrderCall "Nat.sub" [stop, start],
    psStandardListCall "drop" [alpha, start, list] [u]] [u]
  [ defn "Array.emptyWithCapacity" psPreludeArrayEmptyType
      (lams (psLogicLam 2 "capacity" psOrderNat
        (psStandardArrayMk alpha (psSelfHostListNilOf alpha u) u))),
    defn "Array.size" psPreludeArraySizeType
      (lams (psLogicLam 1 "xs" array (psListIndexLength alpha list u))),
    defn "Array.push" psPreludeArrayPushType
      (lams (psLogicLam 1 "xs" array (psLogicLam 3 "value" alpha
        (psStandardArrayMk alpha (psStandardListCall "append" [alpha, list,
          psSelfHostListConsOf alpha value (psSelfHostListNilOf alpha u) u] [u]) u)))),
    defn "Array.getD" psPreludeArrayGetDType
      (lams (psLogicLam 1 "xs" array (psLogicLam 2 "i" psOrderNat
        (psLogicLam 3 "fallback" alpha
          (psLogicApply (.constE (psDecisionName "Option.getD") [u])
            [alpha, psListIndexOptionalGet alpha list i u, value]))))),
    defn "Array.getInternal"
      (params (psLogicPi 1 "xs" array (psLogicPi 2 "i" psOrderNat
        (psLogicPi 9 "h" bound alpha))))
      (lams (psLogicLam 1 "xs" array (psLogicLam 2 "i" psOrderNat
        (psLogicLam 9 "h" bound (psListIndexProofGet alpha list i h u))))),
    defn "Array.setIfInBounds" psPreludeArraySetIfInBoundsType (lams setter),
    defn "Array.set"
      (params (psLogicPi 1 "xs" array (psLogicPi 2 "i" psOrderNat
        (psLogicPi 3 "value" alpha (psLogicPi 9 "h" bound array)))))
      (lams (psLogicLam 1 "xs" array (psLogicLam 2 "i" psOrderNat
        (psLogicLam 3 "value" alpha (psLogicLam 9 "h" bound
          (psStandardArrayMk alpha listSet u)))))),
    defnUV "Array.map" psPreludeArrayMapType
      (lams (psLogicLam 4 "β" (.sortE (.succ v))
        (psLogicLam 5 "f" (psLogicPi 10 "value" alpha beta)
          (psLogicLam 1 "xs" array
            (psStandardArrayMk beta (psStandardListCall "map" [alpha, beta, fn, list] [u, v]) v)))
        .implicit)),
    defnUV "Array.foldl" psPreludeArrayFoldlType
      (lams (psLogicLam 4 "β" (.sortE (.succ v))
        (psLogicLam 5 "f" (psLogicPi 10 "acc" beta (psLogicPi 11 "value" alpha beta))
          (psLogicLam 6 "init" beta (psLogicLam 1 "xs" array
            (psLogicLam 7 "start" psOrderNat (psLogicLam 8 "stop" psOrderNat
              (psStandardListCall "foldl" [beta, alpha, fn, init, sliced] [v, u]))))))
        .implicit)) ]

def psStandardArrayInstances : List PsDeclaration :=
  let u := PsLevel.param (psRootName "u")
  let alpha := PsExpr.fvar 0
  let xs := PsExpr.fvar 1
  let i := PsExpr.fvar 2
  let h := PsExpr.fvar 3
  let array := psPreludeArrayOf alpha u
  let valid := psLogicLam 1 "xs" array (psLogicLam 2 "i" psOrderNat
    (psStandardArrayBound alpha xs i u))
  let args := psStandardGetElemArgs array psOrderNat alpha valid
  let family := fun name more => psLogicApply
    (.constE (psDecisionName name) [u, .zero, u]) (args ++ more)
  let checkedName := psDecisionName "PsStandard.instGetElemArray"
  let checked := .app (.constE checkedName [u]) alpha
  let decision := psLogicLam 1 "xs" array (psLogicLam 2 "i" psOrderNat
    (psOrderCall "Nat.decLt" [i, psStandardArraySize alpha xs u]))
  let optional := family "PsStandard.instGetElemOptionalDefault" [checked, decision]
  let params := fun body => psLogicPi 0 "α" (.sortE (.succ u)) body .implicit
  let lams := fun body => psLogicLam 0 "α" (.sortE (.succ u)) body .implicit
  [ .definitionDecl checkedName [psRootName "u"] (params (family "GetElem" []))
      (lams (family "GetElem.mk" [psLogicLam 1 "xs" array
        (psLogicLam 2 "i" psOrderNat (psLogicLam 3 "h"
          (psStandardArrayBound alpha xs i u) (psStandardArrayCall "getInternal" [alpha, xs, i, h] [u])))])),
    .definitionDecl (psDecisionName "PsStandard.instGetElemOptionalArray") [psRootName "u"]
      (params (family "GetElem?" [])) (lams optional),
    .definitionDecl (psDecisionName "PsStandard.instLawfulGetElemArray") [psRootName "u"]
      (params (family "LawfulGetElem" [optional]))
      (lams (family "PsStandard.instLawfulGetElemOptionalDefault" [checked, decision])) ]

def psStandardArrayPublicDeclarations : List PsDeclaration :=
  let u := PsLevel.param (psRootName "u")
  let alpha := PsExpr.fvar 0
  let xs := PsExpr.fvar 1
  let i := PsExpr.fvar 2
  let inhabited := PsExpr.fvar 3
  let array := psPreludeArrayOf alpha u
  let size := psStandardArraySize alpha xs u
  let fin := psStandardFinOf size
  let valid := psLogicLam 1 "xs" array (psLogicLam 2 "i" psOrderNat
    (psStandardArrayBound alpha xs i u))
  let args := psStandardGetElemArgs array psOrderNat alpha valid
  let dictionary := psLogicApply (.constE (psDecisionName "PsStandard.instGetElemOptionalArray") [u]) [alpha]
  let params := fun body => psLogicPi 0 "α" (.sortE (.succ u)) body .implicit
  let lams := fun body => psLogicLam 0 "α" (.sortE (.succ u)) body .implicit
  let optionalType := params (psLogicPi 1 "xs" array
    (psLogicPi 2 "i" psOrderNat (psSelfHostOptionOf alpha u)))
  let optionalBody := lams (psLogicLam 1 "xs" array (psLogicLam 2 "i" psOrderNat
    (psLogicApply (.constE (psDecisionName "GetElem?.getElem?") [u, .zero, u])
      (args ++ [dictionary, xs, i]))))
  let bangType := params (psLogicPi 3 "inhabited" (psStandardInhabitedType alpha (.succ u))
    (psLogicPi 1 "xs" array (psLogicPi 2 "i" psOrderNat alpha)) .instanceImplicit)
  let bangBody := lams (psLogicLam 3 "inhabited" (psStandardInhabitedType alpha (.succ u))
    (psLogicLam 1 "xs" array (psLogicLam 2 "i" psOrderNat
      (psLogicApply (.constE (psDecisionName "GetElem?.getElem!") [u, .zero, u])
        (args ++ [dictionary, inhabited, xs, i])))) .instanceImplicit)
  [ .definitionDecl (psDecisionName "Array.get") [psRootName "u"]
      (params (psLogicPi 1 "xs" array (psLogicPi 2 "i" fin alpha)))
      (lams (psLogicLam 1 "xs" array (psLogicLam 2 "i" fin
        (psStandardArrayCall "getInternal" [alpha, xs, psStandardFinVal size i,
          psOrderCall "Fin.isLt" [size, i]] [u])))),
    .definitionDecl (psDecisionName "List.toArray") [psRootName "u"]
      (params (psLogicPi 1 "xs" (psSelfHostListOf alpha u) array))
      (lams (psLogicLam 1 "xs" (psSelfHostListOf alpha u) (psStandardArrayMk alpha xs u))),
    .definitionDecl (psDecisionName "Array.get?") [psRootName "u"] optionalType optionalBody,
    .definitionDecl (psDecisionName "Array.get?Internal") [psRootName "u"] optionalType optionalBody,
    .definitionDecl (psDecisionName "Array.get!") [psRootName "u"] bangType bangBody,
    .definitionDecl (psDecisionName "Array.get!Internal") [psRootName "u"] bangType bangBody ]

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
      value := .constE name ((psDeclarationLevelParams declaration).map PsLevel.param)
      levelParams := psDeclarationLevelParams declaration
      type := psDeclarationType declaration
      className := some className }) environment.instances
  { environment with instances }
