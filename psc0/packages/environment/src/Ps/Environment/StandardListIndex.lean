import Ps.Environment.StandardFin

-- The proof-taking and optional workers share the same structural spine.
-- Neither performs a length pass at runtime. Bounds exist only in the checked
-- Core types; the optional worker stops at the requested cell or the list end.
def psListIndexLength (alpha xs : PsExpr) (level : PsLevel := .zero) : PsExpr :=
  psStandardListCall "length" [alpha, xs] [level]

def psListIndexBound (alpha xs i : PsExpr) (level : PsLevel := .zero) : PsExpr :=
  psOrderCall "Nat.lt" [i, psListIndexLength alpha xs level]

def psListIndexProofName : PsName :=
  psDecisionName "$psc0Standard.listGetProofWorker"

def psListIndexProofGet (alpha xs i h : PsExpr) (level : PsLevel := .zero) : PsExpr :=
  psLogicApply (.constE psListIndexProofName [level]) [alpha, xs, i, h]

def psListIndexOptionalGet (alpha xs i : PsExpr) (level : PsLevel := .zero) : PsExpr :=
  psStandardListCall "get?" [alpha, xs, i] [level]

def psListIndexFalseElim (level : PsLevel) (type proof : PsExpr) : PsExpr :=
  psLogicApply (.constE (psDecisionName "False.elim") [level]) [type, proof]

def psStandardListProofGetDeclaration : PsDeclaration :=
  let u : PsLevel := .param (psRootName "u")
  let alpha := PsExpr.fvar 0
  let xs := PsExpr.fvar 1
  let i := PsExpr.fvar 2
  let h := PsExpr.fvar 3
  let head := PsExpr.fvar 4
  let tail := PsExpr.fvar 5
  let ih := PsExpr.fvar 6
  let previous := PsExpr.fvar 7
  let list := psSelfHostListOf alpha u
  let nilValue := psSelfHostListNilOf alpha u
  let consValue := psSelfHostListConsOf alpha head tail u
  let result := fun xs => psLogicPi 2 "i" psOrderNat
    (psLogicPi 3 "h" (psListIndexBound alpha xs i u) alpha)
  let nilCase := psLogicLam 2 "i" psOrderNat
    (psLogicLam 3 "h" (psListIndexBound alpha nilValue i u)
      (psListIndexFalseElim (.succ u) alpha (psOrderCall "Nat.not_lt_zero" [i, h])))
  let atIndex := fun i => psLogicPi 3 "h" (psListIndexBound alpha consValue i u) alpha
  let zeroCase := psLogicLam 3 "h" (psListIndexBound alpha consValue (.lit (.natural 0)) u) head
  let succCase := psLogicLam 7 "previous" psOrderNat
    (psLogicLam 8 "_" (atIndex previous)
      (psLogicLam 3 "h" (psListIndexBound alpha consValue (psOrderSucc previous) u)
        (psLogicApply ih [previous, psOrderCall "Nat.lt_of_succ_lt_succ"
          [previous, psListIndexLength alpha tail u, h]])))
  let consCase := psLogicLam 4 "head" alpha
    (psLogicLam 5 "tail" list
      (psLogicLam 6 "ih" (result tail)
        (psLogicLam 2 "i" psOrderNat
          (psOrderNatRec (.succ u)
            (psLogicLam 2 "i" psOrderNat (atIndex i)) zeroCase succCase i))))
  -- The List-recursive result owns its changing index/proof arguments,
  -- just like listGetWorker.
  let body := psLogicApply (psStandardListRecursor u (.succ u))
    [alpha, psLogicLam 1 "xs" list (result xs), nilCase, consCase, xs]
  .definitionDecl psListIndexProofName [psRootName "u"]
    (psLogicPi 0 "α" (.sortE (.succ u)) (psLogicPi 1 "xs" list (result xs)) .implicit)
    (psLogicLam 0 "α" (.sortE (.succ u)) (psLogicLam 1 "xs" list body) .implicit)

-- Positive and negative branch theorems validate the optimized optional
-- algorithm independently of any chosen Decidable dictionary.
def psStandardListIndexBranchDeclaration (positive : Bool) : PsDeclaration :=
  let u : PsLevel := .param (psRootName "u")
  let alpha := PsExpr.fvar 0
  let xs := PsExpr.fvar 1
  let i := PsExpr.fvar 2
  let h := PsExpr.fvar 3
  let head := PsExpr.fvar 4
  let tail := PsExpr.fvar 5
  let ih := PsExpr.fvar 6
  let previous := PsExpr.fvar 7
  let list := psSelfHostListOf alpha u
  let opt := psSelfHostOptionOf alpha u
  let nilValue := psSelfHostListNilOf alpha u
  let consValue := psSelfHostListConsOf alpha head tail u
  let condition := fun xs i =>
    let bound := psListIndexBound alpha xs i u
    if positive then bound else psDecisionNot bound
  let equation := fun xs i proof => psLogicEq (.succ u) opt
    (psListIndexOptionalGet alpha xs i u)
    (if positive then psSelfHostOptionSomeOf alpha (psListIndexProofGet alpha xs i proof u) u
     else psSelfHostOptionNoneOf alpha u)
  let result := fun xs => psLogicPi 2 "i" psOrderNat
    (psLogicPi 3 "h" (condition xs i) (equation xs i h))
  let nilProof := if positive then
    psListIndexFalseElim .zero (equation nilValue i h)
      (psOrderCall "Nat.not_lt_zero" [i, h])
    else psLogicRefl (.succ u) opt (psSelfHostOptionNoneOf alpha u)
  let nilCase := psLogicLam 2 "i" psOrderNat
    (psLogicLam 3 "h" (condition nilValue i) nilProof)
  let zero := PsExpr.lit (.natural 0)
  let zeroBound := psOrderCall "Nat.succ_le_succ"
    [zero, psListIndexLength alpha tail u,
     psOrderCall "Nat.zero_le" [psListIndexLength alpha tail u]]
  let zeroProof := if positive then
    psLogicRefl (.succ u) opt (psSelfHostOptionSomeOf alpha head u)
    else psListIndexFalseElim .zero (equation consValue zero h) (.app h zeroBound)
  let zeroCase := psLogicLam 3 "h" (condition consValue zero) zeroProof
  let nextCondition := if positive then
    psOrderCall "Nat.lt_of_succ_lt_succ"
      [previous, psListIndexLength alpha tail u, h]
    else psLogicLam 9 "tailBound" (psListIndexBound alpha tail previous u)
      (.app h (psOrderCall "Nat.succ_le_succ"
        [psOrderSucc previous, psListIndexLength alpha tail u, .fvar 9]))
  let atIndex := fun i => psLogicPi 3 "h" (condition consValue i) (equation consValue i h)
  let succCase := psLogicLam 7 "previous" psOrderNat
    (psLogicLam 8 "_" (atIndex previous)
      (psLogicLam 3 "h" (condition consValue (psOrderSucc previous))
        (psLogicApply ih [previous, nextCondition])))
  let consCase := psLogicLam 4 "head" alpha
    (psLogicLam 5 "tail" list
      (psLogicLam 6 "ih" (result tail)
        (psLogicLam 2 "i" psOrderNat
          (psOrderNatRec .zero (psLogicLam 2 "i" psOrderNat (atIndex i))
            zeroCase succCase i))))
  let body := psLogicApply (.constE psSelfHostListRecName [.zero, u])
    [alpha, psLogicLam 1 "xs" list (result xs), nilCase, consCase, xs]
  .definitionDecl (psDecisionName
      (if positive then "PsStandard.listIndexPositive" else "PsStandard.listIndexNegative")) [psRootName "u"]
    (psLogicPi 0 "α" (.sortE (.succ u)) (psLogicPi 1 "xs" list (result xs)) .implicit)
    (psLogicLam 0 "α" (.sortE (.succ u)) (psLogicLam 1 "xs" list body) .implicit)

-- Reusable propositional assembly: two proved branches imply the dependent
-- optional law for every actual Decidable witness. No Boolean cast is used.
def psStandardOptionalFromBranchesDeclaration : PsDeclaration :=
  let w := psRootName "w"
  let alpha := PsExpr.fvar 0
  let p := PsExpr.fvar 1
  let get := PsExpr.fvar 2
  let candidate := PsExpr.fvar 3
  let yesProof := PsExpr.fvar 4
  let noProof := PsExpr.fvar 5
  let d := PsExpr.fvar 6
  let flag := PsExpr.fvar 7
  let reflection := PsExpr.fvar 8
  let h := PsExpr.fvar 9
  let opt := psSelfHostOptionOf alpha (.param w)
  let yes := psLogicLam 9 "h" p (psSelfHostOptionSomeOf alpha (.app get h) (.param w))
  let no := psLogicLam 9 "h" (psDecisionNot p) (psSelfHostOptionNoneOf alpha (.param w))
  let equality := fun d => psLogicEq (.succ (.param w)) opt candidate
    (psLogicApply (.constE (psRootName "dite") [.succ (.param w)]) [opt, p, d, yes, no])
  let made := psOrderCall "Decidable.intro" [p, flag, reflection]
  let reflectionType := psDecisionReflects flag p
  let result := psLogicPi 8 "reflection" reflectionType (equality made)
  let boolCase := psLogicApply (.constE (psDecisionName "Bool.rec") [.zero])
    [psLogicLam 7 "flag" (.constE psBoolName []) result,
     psLogicLam 9 "h" (psDecisionNot p) (.app noProof h),
     psLogicLam 9 "h" p (.app yesProof h), flag, reflection]
  let minor := psLogicLam 7 "flag" (.constE psBoolName [])
    (psLogicLam 8 "reflection" reflectionType boolCase)
  let body := psLogicApply (.constE (psDecisionName "Decidable.rec") [.zero])
    [p, psLogicLam 6 "d" (psDecisionType p) (equality d), minor, d]
  let getType := psLogicPi 9 "h" p alpha
  let yesType := psLogicPi 9 "h" p (psLogicEq (.succ (.param w)) opt candidate
    (psSelfHostOptionSomeOf alpha (.app get h) (.param w)))
  let noType := psLogicPi 9 "h" (psDecisionNot p) (psLogicEq (.succ (.param w)) opt candidate
    (psSelfHostOptionNoneOf alpha (.param w)))
  let type := psLogicPi 0 "α" (.sortE (.succ (.param w)))
    (psLogicPi 1 "p" (.sortE .zero)
      (psLogicPi 2 "get" getType (psLogicPi 3 "candidate" opt
        (psLogicPi 4 "positive" yesType (psLogicPi 5 "negative" noType
          (psLogicPi 6 "d" (psDecisionType p) (equality d))))))) .implicit
  let value := psLogicLam 0 "α" (.sortE (.succ (.param w)))
    (psLogicLam 1 "p" (.sortE .zero)
      (psLogicLam 2 "get" getType (psLogicLam 3 "candidate" opt
        (psLogicLam 4 "positive" yesType (psLogicLam 5 "negative" noType
          (psLogicLam 6 "d" (psDecisionType p) body)))))) .implicit
  .definitionDecl (psDecisionName "PsStandard.optionalFromBranches") [w] type value

-- Pinned Lean public proof access takes Fin length. The internal worker keeps the
-- structural major visible to the existing checked recursion/erasure plan.
def psStandardListIndexPublicDeclarations : List PsDeclaration :=
  let u : PsLevel := .param (psRootName "u")
  let alpha := PsExpr.fvar 0
  let xs := PsExpr.fvar 1
  let i := PsExpr.fvar 2
  let inhabited := PsExpr.fvar 3
  let list := psSelfHostListOf alpha u
  let params := fun body => psLogicPi 0 "α" (.sortE (.succ u)) body .implicit
  let lams := fun body => psLogicLam 0 "α" (.sortE (.succ u)) body .implicit
  let lengthU := psListIndexLength alpha xs u
  let finU := psStandardFinOf lengthU
  let get := .definitionDecl (psDecisionName "List.get") [psRootName "u"]
    (psLogicPi 0 "α" (.sortE (.succ u))
      (psLogicPi 1 "xs" list (psLogicPi 2 "i" finU alpha)) .implicit)
    (psLogicLam 0 "α" (.sortE (.succ u))
      (psLogicLam 1 "xs" list (psLogicLam 2 "i" finU
        (psListIndexProofGet alpha xs (psStandardFinVal lengthU i)
          (psOrderCall "Fin.isLt" [lengthU, i]) u)) .implicit))
  let bangType := params (psLogicPi 3 "inhabited" (psStandardInhabitedType alpha (.succ u))
    (psLogicPi 1 "xs" list (psLogicPi 2 "i" psOrderNat alpha)) .instanceImplicit)
  let bangValue := lams (psLogicLam 3 "inhabited" (psStandardInhabitedType alpha (.succ u))
    (psLogicLam 1 "xs" list (psLogicLam 2 "i" psOrderNat
      (psLogicApply (.constE (psDecisionName "GetElem?.getElem!Default") [u])
        [alpha, inhabited, psListIndexOptionalGet alpha xs i u]))) .instanceImplicit)
  let bangAlias := lams (psLogicLam 3 "inhabited" (psStandardInhabitedType alpha (.succ u))
    (psLogicLam 1 "xs" list (psLogicLam 2 "i" psOrderNat
      (psStandardListCall "get!" [alpha, inhabited, xs, i] [u]))) .instanceImplicit)
  [get, .definitionDecl (psDecisionName "List.get!") [psRootName "u"] bangType bangValue,
   .definitionDecl (psDecisionName "List.get!Internal") [psRootName "u"] bangType bangAlias,
   psDeclarationAlias (psDecisionName "List.get?Internal") psStandardListGetQuestionDeclaration]

def psStandardListIndexInstances : List PsDeclaration :=
  let u : PsLevel := .param (psRootName "u")
  let alpha := PsExpr.fvar 0
  let xs := PsExpr.fvar 1
  let i := PsExpr.fvar 2
  let h := PsExpr.fvar 3
  let inhabited := PsExpr.fvar 4
  let decision := PsExpr.fvar 5
  let list := psSelfHostListOf alpha u
  let valid := psLogicLam 1 "xs" list (psLogicLam 2 "i" psOrderNat
    (psListIndexBound alpha xs i u))
  let args := psStandardGetElemArgs list psOrderNat alpha valid
  let levels : List PsLevel := [u, .zero, u]
  let family := fun name more => psLogicApply (.constE name levels) (args ++ more)
  let params := fun body => psLogicPi 0 "α" (.sortE (.succ u)) body .implicit
  let lams := fun body => psLogicLam 0 "α" (.sortE (.succ u)) body .implicit
  let checkedName := psDecisionName "PsStandard.instGetElemList"
  let optionalName := psDecisionName "PsStandard.instGetElemOptionalList"
  let lawfulName := psDecisionName "PsStandard.instLawfulGetElemList"
  let checked := .app (.constE checkedName [u]) alpha
  let optional := .app (.constE optionalName [u]) alpha
  let method := psLogicLam 1 "xs" list (psLogicLam 2 "i" psOrderNat
    (psLogicLam 3 "h" (psListIndexBound alpha xs i u) (psListIndexProofGet alpha xs i h u)))
  let checkedDecl := .definitionDecl checkedName [psRootName "u"]
    (params (family psStandardGetElemName []))
    (lams (family (psDecisionName "GetElem.mk") [method]))
  let optionalDecl := .definitionDecl optionalName [psRootName "u"]
    (params (family psStandardGetElemOptionalName []))
    (lams (family (psDecisionName "GetElem?.mk")
      [checked, .app (.constE (psDecisionName "List.get?") [u]) alpha,
       .app (.constE (psDecisionName "List.get!") [u]) alpha]))
  let proposition := psListIndexBound alpha xs i u
  let get := psLogicLam 3 "h" proposition (psListIndexProofGet alpha xs i h u)
  let positive := psLogicApply (.constE (psDecisionName "PsStandard.listIndexPositive") [u]) [alpha, xs, i]
  let negative := psLogicApply (.constE (psDecisionName "PsStandard.listIndexNegative") [u]) [alpha, xs, i]
  let proof := psLogicApply (.constE (psDecisionName "PsStandard.optionalFromBranches") [u])
    [alpha, proposition, get, psListIndexOptionalGet alpha xs i u, positive, negative, decision]
  let optionalLaw := psLogicLam 1 "xs" list (psLogicLam 2 "i" psOrderNat
    (psLogicLam 5 "decision" (psDecisionType proposition) proof .instanceImplicit))
  let bang := psStandardListCall "get!" [alpha, inhabited, xs, i] [u]
  let bangLaw := psLogicLam 4 "inhabited" (psStandardInhabitedType alpha (.succ u))
    (psLogicLam 1 "xs" list (psLogicLam 2 "i" psOrderNat
      (psLogicRefl (.succ u) alpha bang))) .instanceImplicit
  let lawfulDecl := .definitionDecl lawfulName [psRootName "u"]
    (params (family psStandardLawfulGetElemName [optional]))
    (lams (family (psDecisionName "LawfulGetElem.mk") [optional, optionalLaw, bangLaw]))
  [checkedDecl, optionalDecl, lawfulDecl]

def psStandardListIndexDeclarations : List PsDeclaration :=
  [psStandardListProofGetDeclaration,
   psStandardListIndexBranchDeclaration true,
   psStandardListIndexBranchDeclaration false,
   psStandardOptionalFromBranchesDeclaration] ++
  psStandardListIndexPublicDeclarations ++ psStandardListIndexInstances

def psStandardListIndexExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardListIndexDeclarations.foldl psPreludeAdd environment
  let instances := psStandardListIndexInstances.foldl (fun index declaration =>
    let name := psDeclarationName declaration
    let className := if psNameEq name (psDecisionName "PsStandard.instGetElemList")
      then psStandardGetElemName
      else if psNameEq name (psDecisionName "PsStandard.instGetElemOptionalList")
      then psStandardGetElemOptionalName else psStandardLawfulGetElemName
    psInstanceIndexAdd index {
      value := .constE name ((psDeclarationLevelParams declaration).map PsLevel.param)
      levelParams := psDeclarationLevelParams declaration
      type := psDeclarationType declaration
      className := some className }) environment.instances
  { environment with instances }
