import Ps.Environment.StandardFin

-- The proof-taking and optional workers share the same structural spine.
-- Neither performs a length pass at runtime. Bounds exist only in the checked
-- Core types; the optional worker stops at the requested cell or the list end.
def psListIndexLength (alpha xs : PsExpr) : PsExpr :=
  psStandardListCall "length" [alpha, xs]

def psListIndexBound (alpha xs i : PsExpr) : PsExpr :=
  psOrderCall "Nat.lt" [i, psListIndexLength alpha xs]

def psListIndexProofName : PsName :=
  psDecisionName "$psc0Standard.listGetProofWorker"

def psListIndexProofGet (alpha xs i h : PsExpr) : PsExpr :=
  psLogicApply (.constE psListIndexProofName []) [alpha, xs, i, h]

def psListIndexOptionalGet (alpha xs i : PsExpr) : PsExpr :=
  psStandardListCall "get?" [alpha, xs, i]

def psListIndexFalseElim (level : PsLevel) (type proof : PsExpr) : PsExpr :=
  psLogicApply (.constE (psDecisionName "False.elim") [level]) [type, proof]

def psStandardListProofGetDeclaration : PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let xs := PsExpr.fvar 1
  let i := PsExpr.fvar 2
  let h := PsExpr.fvar 3
  let head := PsExpr.fvar 4
  let tail := PsExpr.fvar 5
  let ih := PsExpr.fvar 6
  let previous := PsExpr.fvar 7
  let list := psSelfHostListOf alpha
  let nilValue := psSelfHostListNilOf alpha
  let consValue := psSelfHostListConsOf alpha head tail
  let result := fun xs => psLogicPi 2 "i" psOrderNat
    (psLogicPi 3 "h" (psListIndexBound alpha xs i) alpha)
  let nilCase := psLogicLam 2 "i" psOrderNat
    (psLogicLam 3 "h" (psListIndexBound alpha nilValue i)
      (psListIndexFalseElim (.succ .zero) alpha (psOrderCall "Nat.not_lt_zero" [i, h])))
  let atIndex := fun i => psLogicPi 3 "h" (psListIndexBound alpha consValue i) alpha
  let zeroCase := psLogicLam 3 "h" (psListIndexBound alpha consValue (.lit (.natural 0))) head
  let succCase := psLogicLam 7 "previous" psOrderNat
    (psLogicLam 8 "_" (atIndex previous)
      (psLogicLam 3 "h" (psListIndexBound alpha consValue (psOrderSucc previous))
        (psLogicApply ih [previous, psOrderCall "Nat.lt_of_succ_lt_succ"
          [previous, psListIndexLength alpha tail, h]])))
  let consCase := psLogicLam 4 "head" alpha
    (psLogicLam 5 "tail" list
      (psLogicLam 6 "ih" (result tail)
        (psLogicLam 2 "i" psOrderNat
          (psOrderNatRec (.succ .zero)
            (psLogicLam 2 "i" psOrderNat (atIndex i)) zeroCase succCase i))))
  -- The List-recursive result owns its changing index/proof arguments,
  -- just like listGetWorker.
  let body := psLogicApply (psStandardListRecursor .zero)
    [alpha, psLogicLam 1 "xs" list (result xs), nilCase, consCase, xs]
  .definitionDecl psListIndexProofName []
    (psLogicPi 0 "α" psPreludeTypeType (psLogicPi 1 "xs" list (result xs)) .implicit)
    (psLogicLam 0 "α" psPreludeTypeType (psLogicLam 1 "xs" list body) .implicit)

-- Positive and negative branch theorems validate the optimized optional
-- algorithm independently of any chosen Decidable dictionary.
def psStandardListIndexBranchDeclaration (positive : Bool) : PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let xs := PsExpr.fvar 1
  let i := PsExpr.fvar 2
  let h := PsExpr.fvar 3
  let head := PsExpr.fvar 4
  let tail := PsExpr.fvar 5
  let ih := PsExpr.fvar 6
  let previous := PsExpr.fvar 7
  let list := psSelfHostListOf alpha
  let opt := psSelfHostOptionOf alpha
  let nilValue := psSelfHostListNilOf alpha
  let consValue := psSelfHostListConsOf alpha head tail
  let condition := fun xs i =>
    let bound := psListIndexBound alpha xs i
    if positive then bound else psDecisionNot bound
  let equation := fun xs i proof => psLogicEq (.succ .zero) opt
    (psListIndexOptionalGet alpha xs i)
    (if positive then psSelfHostOptionSomeOf alpha (psListIndexProofGet alpha xs i proof)
     else psSelfHostOptionNoneOf alpha)
  let result := fun xs => psLogicPi 2 "i" psOrderNat
    (psLogicPi 3 "h" (condition xs i) (equation xs i h))
  let nilProof := if positive then
    psListIndexFalseElim .zero (equation nilValue i h)
      (psOrderCall "Nat.not_lt_zero" [i, h])
    else psLogicRefl (.succ .zero) opt (psSelfHostOptionNoneOf alpha)
  let nilCase := psLogicLam 2 "i" psOrderNat
    (psLogicLam 3 "h" (condition nilValue i) nilProof)
  let zero := PsExpr.lit (.natural 0)
  let zeroBound := psOrderCall "Nat.succ_le_succ"
    [zero, psListIndexLength alpha tail,
     psOrderCall "Nat.zero_le" [psListIndexLength alpha tail]]
  let zeroProof := if positive then
    psLogicRefl (.succ .zero) opt (psSelfHostOptionSomeOf alpha head)
    else psListIndexFalseElim .zero (equation consValue zero h) (.app h zeroBound)
  let zeroCase := psLogicLam 3 "h" (condition consValue zero) zeroProof
  let nextCondition := if positive then
    psOrderCall "Nat.lt_of_succ_lt_succ"
      [previous, psListIndexLength alpha tail, h]
    else psLogicLam 9 "tailBound" (psListIndexBound alpha tail previous)
      (.app h (psOrderCall "Nat.succ_le_succ"
        [psOrderSucc previous, psListIndexLength alpha tail, .fvar 9]))
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
  let body := psLogicApply (.constE psSelfHostListRecName [.zero, .zero])
    [alpha, psLogicLam 1 "xs" list (result xs), nilCase, consCase, xs]
  .definitionDecl (psDecisionName
      (if positive then "PsStandard.listIndexPositive" else "PsStandard.listIndexNegative")) []
    (psLogicPi 0 "α" psPreludeTypeType (psLogicPi 1 "xs" list (result xs)) .implicit)
    (psLogicLam 0 "α" psPreludeTypeType (psLogicLam 1 "xs" list body) .implicit)

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

-- RC4 public proof access takes Fin length. The internal worker keeps the
-- structural major visible to the existing checked recursion/erasure plan.
def psStandardListIndexPublicDeclarations : List PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let xs := PsExpr.fvar 1
  let i := PsExpr.fvar 2
  let inhabited := PsExpr.fvar 3
  let list := psSelfHostListOf alpha
  let length := psListIndexLength alpha xs
  let fin := psStandardFinOf length
  let params := fun body => psLogicPi 0 "α" psPreludeTypeType body .implicit
  let lams := fun body => psLogicLam 0 "α" psPreludeTypeType body .implicit
  let get := .definitionDecl (psDecisionName "List.get") []
    (params (psLogicPi 1 "xs" list (psLogicPi 2 "i" fin alpha)))
    (lams (psLogicLam 1 "xs" list (psLogicLam 2 "i" fin
      (psListIndexProofGet alpha xs (psStandardFinVal length i)
        (psOrderCall "Fin.isLt" [length, i])))))
  let bangType := params (psLogicPi 3 "inhabited" (psStandardInhabitedType alpha)
    (psLogicPi 1 "xs" list (psLogicPi 2 "i" psOrderNat alpha)) .instanceImplicit)
  let bangValue := lams (psLogicLam 3 "inhabited" (psStandardInhabitedType alpha)
    (psLogicLam 1 "xs" list (psLogicLam 2 "i" psOrderNat
      (psLogicApply (.constE (psDecisionName "GetElem?.getElem!Default") [.zero])
        [alpha, inhabited, psListIndexOptionalGet alpha xs i]))) .instanceImplicit)
  let bangAlias := lams (psLogicLam 3 "inhabited" (psStandardInhabitedType alpha)
    (psLogicLam 1 "xs" list (psLogicLam 2 "i" psOrderNat
      (psOrderCall "List.get!" [alpha, inhabited, xs, i]))) .instanceImplicit)
  let optionalAlias := lams (psLogicLam 1 "xs" list (psLogicLam 2 "i" psOrderNat
    (psListIndexOptionalGet alpha xs i)))
  [get, .definitionDecl (psDecisionName "List.get!") [] bangType bangValue,
   .definitionDecl (psDecisionName "List.get!Internal") [] bangType bangAlias,
   .definitionDecl (psDecisionName "List.get?Internal") []
     (psDeclarationType psStandardListGetQuestionDeclaration) optionalAlias]

def psStandardListIndexInstances : List PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let xs := PsExpr.fvar 1
  let i := PsExpr.fvar 2
  let h := PsExpr.fvar 3
  let inhabited := PsExpr.fvar 4
  let decision := PsExpr.fvar 5
  let list := psSelfHostListOf alpha
  let valid := psLogicLam 1 "xs" list (psLogicLam 2 "i" psOrderNat
    (psListIndexBound alpha xs i))
  let args := psStandardGetElemArgs list psOrderNat alpha valid
  let levels : List PsLevel := [.zero, .zero, .zero]
  let family := fun name more => psLogicApply (.constE name levels) (args ++ more)
  let params := fun body => psLogicPi 0 "α" psPreludeTypeType body .implicit
  let lams := fun body => psLogicLam 0 "α" psPreludeTypeType body .implicit
  let checkedName := psDecisionName "PsStandard.instGetElemList"
  let optionalName := psDecisionName "PsStandard.instGetElemOptionalList"
  let lawfulName := psDecisionName "PsStandard.instLawfulGetElemList"
  let checked := .app (.constE checkedName []) alpha
  let optional := .app (.constE optionalName []) alpha
  let method := psLogicLam 1 "xs" list (psLogicLam 2 "i" psOrderNat
    (psLogicLam 3 "h" (psListIndexBound alpha xs i) (psListIndexProofGet alpha xs i h)))
  let checkedDecl := .definitionDecl checkedName []
    (params (family psStandardGetElemName []))
    (lams (family (psDecisionName "GetElem.mk") [method]))
  let optionalDecl := .definitionDecl optionalName []
    (params (family psStandardGetElemOptionalName []))
    (lams (family (psDecisionName "GetElem?.mk")
      [checked, .app (.constE (psDecisionName "List.get?") [.zero]) alpha,
       .app (.constE (psDecisionName "List.get!") []) alpha]))
  let proposition := psListIndexBound alpha xs i
  let get := psLogicLam 3 "h" proposition (psListIndexProofGet alpha xs i h)
  let positive := psOrderCall "PsStandard.listIndexPositive" [alpha, xs, i]
  let negative := psOrderCall "PsStandard.listIndexNegative" [alpha, xs, i]
  let proof := psLogicApply (.constE (psDecisionName "PsStandard.optionalFromBranches") [.zero])
    [alpha, proposition, get, psListIndexOptionalGet alpha xs i, positive, negative, decision]
  let optionalLaw := psLogicLam 1 "xs" list (psLogicLam 2 "i" psOrderNat
    (psLogicLam 5 "decision" (psDecisionType proposition) proof .instanceImplicit))
  let bang := psOrderCall "List.get!" [alpha, inhabited, xs, i]
  let bangLaw := psLogicLam 4 "inhabited" (psStandardInhabitedType alpha)
    (psLogicLam 1 "xs" list (psLogicLam 2 "i" psOrderNat
      (psLogicRefl (.succ .zero) alpha bang))) .instanceImplicit
  let lawfulDecl := .definitionDecl lawfulName []
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
      value := .constE name []
      type := psDeclarationType declaration
      className := some className }) environment.instances
  { environment with instances }
