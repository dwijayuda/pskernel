import Ps.KernelCore.API.DagOrdinaryConstructorResult
import Ps.KernelCore.Admission.Inductive.Ordinary.Constructor
import Ps.KernelCore.Research.ExprV2PagedImport
import Ps.KernelCore.Core.ExprV2.Decode

/-
Future native-only direct constructor-result regression. The independent V1
helpers are frozen at source 0d9f062846d109c362210d441df5fd407ca2cdd7:
Ordinary/Constructor.lean blob 56a70b8ac94283694bf375a8d5c8e7adfd3859b7;
Common/Occurrence.lean blob a8b911d20a603b46edcc63a0bf000c1bacec5341.
This tests structural result analysis, not constructor admission or publication.
All new helpers are called directly; no public fallback supplies a success.
-/

private def require (label : String) (condition : Bool) : IO Unit := do
  unless condition do
    throw (IO.userError ("PSC1_CONSTRUCTOR_RESULT_NATIVE_FAIL " ++ label))

private def expect {α : Type} : Except String α -> IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def sameList {α : Type} (equal : α -> α -> Bool) : List α -> List α -> Bool
  | [],[] => true
  | first :: rest,other :: tail =>
      if equal first other then sameList equal rest tail else false
  | _,_ => false

private def sameOption {α : Type} (equal : α -> α -> Bool) : Option α -> Option α -> Bool
  | none,none => true
  | some left,some right => equal left right
  | _,_ => false

private def sameExcept {α : Type} (equal : α -> α -> Bool) :
    Except String α -> Except String α -> Bool
  | .error left,.error right => left == right
  | .ok left,.ok right => equal left right
  | _,_ => false

private def sameNatList := sameList Nat.beq
private def sameExprList := sameList psKernelExprEq
private def nm (text : String) := PsKernelName.str .anonymous text
private def target := nm "T05Result"
private def other := nm "Other"
private def pn := nm "parameter-p"
private def qn := nm "parameter-q"
private def lu := PsKernelLevel.param (nm "u")
private def lv := PsKernelLevel.param (nm "v")
private def one := PsKernelLevel.succ .zero
private def s0 := PsKernelExpr.sort .zero
private def s1 := PsKernelExpr.sort one
private def t := PsKernelExpr.const target []
private def otherConst := PsKernelExpr.const other []
private def p := PsKernelExpr.fvar pn
private def q := PsKernelExpr.fvar qn
private def indexI := PsKernelExpr.const (nm "index-i") []
private def indexJ := PsKernelExpr.const (nm "index-j") []
private def apps := psKernelApplyArgs
private def lam (name : PsKernelName) (type body : PsKernelExpr) :=
  PsKernelExpr.lam name type body .default
private def all (name : PsKernelName) (type body : PsKernelExpr) :=
  PsKernelExpr.forallE name type body .default
private def letE (name : PsKernelName) (type value body : PsKernelExpr) :=
  PsKernelExpr.letE name type value body false
private def md (body : PsKernelExpr) := PsKernelExpr.mdata 4242 body
private def proj (name : PsKernelName) (body : PsKernelExpr) := PsKernelExpr.proj name 0 body
private def param (name : PsKernelName) (type : PsKernelExpr := s1)
    (userName : PsKernelName := nm "user") (binderInfo : PsKernelBinderInfo := .default) :
    PsKernelOpenBinder := ⟨name,userName,type,binderInfo⟩
private def paramP := param pn
private def paramQ := param qn
private def shapeError :=
  "simple inductive constructor must return the declared datatype with matching parameters and index arity"
private def badRoot := "PSKERNEL_V2_PAGED_INVALID_CHILD"
private def fuelError := "PSKERNEL_V2_ORDINARY_CONTAINS_CONST_FUEL"

/- The fixture builder uses the production node constructors, recording IDs at
   construction time. Expected suffix IDs never come from the result selector
   or its application-spine helper. Repeated fixture subexpressions reuse the
   recorded ID so original identity and multiplicity can be checked directly. -/
private structure Built where
  arena : PsKernelExprV2PagedArena
  memo : List (PsKernelExpr × Nat)

private def empty : Built := ⟨psKernelExprV2PagedEmpty,[]⟩

private def memoFind (expr : PsKernelExpr) : List (PsKernelExpr × Nat) -> Option Nat
  | [] => none
  | (previous,root) :: rest =>
      if psKernelExprEq expr previous then some root else memoFind expr rest

private def remember (expr : PsKernelExpr) (state : Built)
    (result : Except String (PsKernelExprV2PagedArena × Nat)) :
    Except String (Built × Nat) := do
  let (arena,root) ← result
  pure (⟨arena,(expr,root) :: state.memo⟩,root)

private def add (expr : PsKernelExpr) (state : Built) : Except String (Built × Nat) :=
  match memoFind expr state.memo with
  | some root => .ok (state,root)
  | none =>
      match expr with
      | .bvar index => remember expr state (psKernelExprV2PagedMkBVar state.arena index)
      | .fvar name => remember expr state (psKernelExprV2PagedMkFVar state.arena name)
      | .mvar name => remember expr state (psKernelExprV2PagedMkMVar state.arena name)
      | .sort level => remember expr state (psKernelExprV2PagedMkSort state.arena level)
      | .const name levels => remember expr state (psKernelExprV2PagedMkConst state.arena name levels)
      | .lit value => remember expr state (psKernelExprV2PagedMkLit state.arena value)
      | .app fn arg => do
          let (state,fnId) ← add fn state
          let (state,argId) ← add arg state
          remember expr state (psKernelExprV2PagedMkApp state.arena fnId argId)
      | .lam name type body info => do
          let (state,typeId) ← add type state
          let (state,bodyId) ← add body state
          remember expr state (psKernelExprV2PagedMkLam state.arena name typeId bodyId info)
      | .forallE name type body info => do
          let (state,typeId) ← add type state
          let (state,bodyId) ← add body state
          remember expr state (psKernelExprV2PagedMkForall state.arena name typeId bodyId info)
      | .letE name type value body nondep => do
          let (state,typeId) ← add type state
          let (state,valueId) ← add value state
          let (state,bodyId) ← add body state
          remember expr state
            (psKernelExprV2PagedMkLet state.arena name typeId valueId bodyId nondep)
      | .mdata tag body => do
          let (state,bodyId) ← add body state
          remember expr state (psKernelExprV2PagedMkMData state.arena tag bodyId)
      | .proj name index body => do
          let (state,bodyId) ← add body state
          remember expr state (psKernelExprV2PagedMkProj state.arena name index bodyId)

private def addList (exprs : List PsKernelExpr) (state : Built) :
    Except String (Built × List Nat) := do
  match exprs with
  | [] => pure (state,[])
  | first :: rest =>
      let (state,root) ← add first state
      let (state,roots) ← addList rest state
      pure (state,root :: roots)

private def buildParams (parameters : List PsKernelOpenBinder) (state : Built) :
    Except String (Built × List PsKernelExprV2OrdinaryOpenBinder) := do
  match parameters with
  | [] => pure (state,[])
  | first :: rest =>
      let (state,type) ← add first.type state
      let (state,tail) ← buildParams rest state
      pure (state,⟨first.internalName,first.userName,type,first.binderInfo⟩ :: tail)

private def decodeOption (built : PsKernelExprV2Decoded) :
    Option (List Nat) -> IO (Option (List PsKernelExpr))
  | none => pure none
  | some roots => do
      let exprs ← expect (roots.mapM (psKernelExprV2DecodedRequire built))
      pure (some exprs)

private def decodeResult (built : PsKernelExprV2Decoded) :
    Except String (List Nat) -> IO (Except String (List PsKernelExpr))
  | .error error => pure (.error error)
  | .ok roots => do
      let exprs ← expect (roots.mapM (psKernelExprV2DecodedRequire built))
      pure (.ok exprs)

private structure SelectorCase where
  label : String
  parameters : List PsKernelOpenBinder
  levels : List PsKernelLevel
  numIndices : Nat
  expr : PsKernelExpr
  expected : Option (List PsKernelExpr)

private def baseSelectorRows : List SelectorCase :=
  let recursiveApp := PsKernelExpr.app otherConst t
  let targetProjection := proj target indexI
  let receiverProjection := proj other t
  let targetFVar := PsKernelExpr.fvar target
  let namedBinder := lam target s0 (.bvar 0)
  let levelLookalike := PsKernelExpr.sort (.param target)
  [ ⟨"S01",[],[],0,t,some []⟩,
    ⟨"S02",[paramP],[],0,apps t [p],some []⟩,
    ⟨"S03",[paramP,paramQ],[],0,apps t [p,q],some []⟩,
    ⟨"S04",[paramP],[],1,apps t [p,indexI],some [indexI]⟩,
    ⟨"S05",[paramP],[],2,apps t [p,indexI,indexJ],some [indexI,indexJ]⟩,
    ⟨"S06",[paramP],[lu,lv],1,apps (.const target [lu,lv]) [p,indexI],some [indexI]⟩,
    ⟨"S07",[paramP],[],1,apps otherConst [p,indexI],none⟩,
    ⟨"S08",[],[],0,.fvar target,none⟩,
    ⟨"S09",[paramP],[lu],1,apps (.const target [lv]) [p,indexI],none⟩,
    ⟨"S10",[paramP],[lu],1,apps t [p,indexI],none⟩,
    ⟨"S11",[paramP],[lu],1,apps (.const target [lu,lv]) [p,indexI],none⟩,
    ⟨"S12",[paramP],[lu,lv],1,apps (.const target [lv,lu]) [p,indexI],none⟩,
    ⟨"S13",[paramP,paramQ],[],0,apps t [p],none⟩,
    ⟨"S14",[paramP],[],0,apps t [q],none⟩,
    ⟨"S15",[paramP,paramQ],[],0,apps t [q,p],none⟩,
    ⟨"S16",[paramP,paramQ],[],0,apps t [p,p],none⟩,
    ⟨"S17",[paramP],[],0,apps t [.bvar 0],none⟩,
    ⟨"S18",[paramP],[],0,apps t [.mvar pn],none⟩,
    ⟨"S19",[paramP],[],0,apps t [md p],none⟩,
    ⟨"S20",[paramP],[],0,apps t [.app (lam (nm "x") s1 (.bvar 0)) p],none⟩,
    ⟨"S21",[paramP],[],0,apps t [.app (.const psKernelTypeAnnotationOutParamName []) p],none⟩,
    ⟨"S22",[paramP],[],2,apps t [p,indexI],none⟩,
    ⟨"S23",[paramP],[],1,apps t [p,indexI,indexJ],none⟩,
    ⟨"S24",[paramP],[],1,md (apps t [p,indexI]),none⟩,
    ⟨"S25",[paramP],[],1,apps (.app (lam (nm "x") s1 (.bvar 0)) t) [p,indexI],none⟩,
    ⟨"S26",[paramP],[],1,apps t [p,recursiveApp],some [recursiveApp]⟩,
    ⟨"S27",[paramP],[],1,apps t [p,targetProjection],some [targetProjection]⟩,
    ⟨"S28",[paramP],[],1,apps t [p,receiverProjection],some [receiverProjection]⟩,
    ⟨"S29",[paramP],[],1,apps t [p,targetFVar],some [targetFVar]⟩,
    ⟨"S30",[paramP],[],1,apps t [p,namedBinder],some [namedBinder]⟩,
    ⟨"S31",[paramP],[],1,apps t [p,levelLookalike],some [levelLookalike]⟩,
    ⟨"S32",[paramP],[],2,apps t [p,indexI,t],some [indexI,t]⟩ ]

private def selectorRows : List SelectorCase :=
  let variants := (baseSelectorRows.filter (fun row =>
      ["S04","S05","S14","S19"].contains row.label)).flatMap (fun row =>
    ([(s0,PsKernelBinderInfo.implicit),(.sort lv,.strictImplicit),
      (s1,.instImplicit)].zipIdx).map (fun ((type,info),index) =>
      { row with
        label := row.label ++ "-descriptor-" ++ toString index
        parameters := row.parameters.map (fun parameter =>
          { parameter with type := type, userName := nm "changed-user", binderInfo := info }) }))
  baseSelectorRows ++ variants ++
    [ ⟨"shared-index",[paramP],[],2,apps t [p,indexI,indexI],some [indexI,indexI]⟩,
      ⟨"shared-recursive-index",[paramP],[],2,apps t [p,t,t],some [t,t]⟩ ]

private def selectorMatrix : IO Nat := do
  require "selector-row-inventory" (selectorRows.length == 46)
  let mut assertions := 0
  for row in selectorRows do
    let (state,parameters) ← expect (buildParams row.parameters empty)
    let (state,root) ← expect (add row.expr state)
    let (state,expectedIds) ← match row.expected with
      | none => pure (state,none)
      | some values => do
          let (state,ids) ← expect (addList values state)
          pure (state,some ids)
    let arena := state.arena
    let decoded ← expect (psKernelExprV2DecodeChecked arena)
    let actual ← expect (psKernelExprV2OrdinaryInductiveAppIndices
      arena target row.levels parameters row.numIndices root)
    let reference := psKernelSimpleInductiveAppIndices
      target row.levels row.parameters row.numIndices row.expr
    require (row.label ++ "/selector-V1")
      (sameOption sameExprList (← decodeOption decoded actual) reference)
    let validated := psKernelExprV2OrdinaryValidateConstructorResult
      arena target row.levels parameters row.numIndices root
    require (row.label ++ "/validator-V1")
      (sameExcept sameExprList (← decodeResult decoded validated)
        (psKernelValidateSimpleConstructorResult
          target row.levels row.parameters row.numIndices row.expr))
    require (row.label ++ "/original-index-IDs") (sameOption sameNatList actual expectedIds)
    assertions := assertions + 3
  pure assertions

private def consumerRows : List
    (List PsKernelOpenBinder × List PsKernelExpr × Option (List PsKernelExpr)) :=
  [ ([],[],some []),([], [indexI,p],some [indexI,p]),([paramP],[],none),
    ([paramP],[p],some []),([paramP],[p,indexI],some [indexI]),
    ([paramP,paramQ],[p,q,indexI,indexJ],some [indexI,indexJ]),
    ([paramP],[q],none),([paramP],[.bvar 0],none),
    ([paramP,paramQ],[p,p],none),([paramP],[md p],none) ]

private def consumerMatrix : IO Nat := do
  let mut assertions := 0
  for (parameters,args,expected) in consumerRows do
    let (state,parametersId) ← expect (buildParams parameters empty)
    let (state,ids) ← expect (addList args state)
    let (state,expectedIds) ← match expected with
      | none => pure (state,none)
      | some values => do
          let (state,ids) ← expect (addList values state)
          pure (state,some ids)
    let decoded ← expect (psKernelExprV2DecodeChecked state.arena)
    let actual ← expect (psKernelExprV2OrdinaryConsumeResultParams parametersId state.arena ids)
    require "consumer/exact-suffix" (sameOption sameNatList actual expectedIds)
    require "consumer/V1-prefix"
      (sameOption sameExprList (← decodeOption decoded actual)
        (psKernelConsumeSimpleResultParams parameters args))
    assertions := assertions + 2
  let (state,cp) ← expect (buildParams [paramP] empty)
  let (state,cpq) ← expect (buildParams [paramP,paramQ] state)
  let (state,pId) ← expect (add p state)
  let (state,qId) ← expect (add q state)
  let probes : List
      (List PsKernelExprV2OrdinaryOpenBinder × List Nat × Except String (Option (List Nat))) :=
    [ ([],[999999],.ok (some [999999])),
      (cp,[qId,999999],.ok none),
      (cpq,[qId,999999],.ok none),
      (cpq,[pId,999999],.error badRoot),
      (cp,[pId,999999],.ok (some [999999])),
      (cp,[999999],.error badRoot) ]
  for (parameters,args,expected) in probes do
    require "consumer/lookup-and-short-circuit"
      (sameExcept (sameOption sameNatList)
        (psKernelExprV2OrdinaryConsumeResultParams parameters state.arena args) expected)
    assertions := assertions + 1
  pure assertions

private def occurrenceTerms : List PsKernelExpr :=
  let shared := md t
  [ .bvar 0,.fvar target,.mvar target,.sort (.param target),t,otherConst,.const target [lv],
    .lit (.nat 17),.lit (.str "T05"),
    .app t otherConst,.app otherConst t,.app otherConst otherConst,
    lam target s0 (.bvar 0),lam (nm "x") t otherConst,lam (nm "x") otherConst t,
    all target s0 (.bvar 0),all (nm "x") t otherConst,all (nm "x") otherConst t,
    letE target s0 otherConst (.bvar 0),letE (nm "x") t otherConst otherConst,
    letE (nm "x") otherConst t otherConst,letE (nm "x") otherConst otherConst t,
    md otherConst,md t,proj target otherConst,proj other t,proj other otherConst,
    apps otherConst [t,t],.app shared shared,
    all (nm "x") otherConst (letE (nm "y") otherConst t t) ]

private def occurrenceMatrix : IO Nat := do
  require "occurrence-term-inventory" (occurrenceTerms.length == 30)
  let mut assertions := 0
  for expr in occurrenceTerms do
    let (state,root) ← expect (add expr empty)
    let entry ← expect (psKernelExprV2PagedRequire state.arena root)
    for nameToFind in [target,other] do
      let reference : Except String Bool := .ok (psKernelExprContainsConst nameToFind expr)
      require "occurrence/canonical-V1"
        (sameExcept (fun a b => a == b)
          (psKernelExprV2OrdinaryContainsConstOnCanonical state.arena nameToFind root) reference)
      assertions := assertions + 1
      for bound in [entry.depth + 1,entry.depth + 4] do
        require "occurrence/adequate-structural-bound"
          (sameExcept (fun a b => a == b)
            (psKernelExprV2OrdinaryContainsConstWithFuel bound state.arena nameToFind root) reference)
        assertions := assertions + 1
      require "occurrence/zero-before-node-kind"
        (sameExcept (fun a b => a == b)
          (psKernelExprV2OrdinaryContainsConstWithFuel 0 state.arena nameToFind root)
          (.error fuelError))
      assertions := assertions + 1
  pure assertions

private def boundRows : List (PsKernelExpr × Nat × Except String Bool) :=
  let deep := PsKernelExpr.app otherConst otherConst
  [ (t,1,.ok true),(otherConst,1,.ok false),
    (proj target otherConst,1,.ok true),(proj other t,1,.error fuelError),
    (.app t deep,2,.ok true),(.app deep t,2,.error fuelError),
    (lam (nm "x") t deep,2,.ok true),(all (nm "x") t deep,2,.ok true),
    (letE (nm "x") t deep deep,2,.ok true),
    (letE (nm "x") otherConst t deep,2,.ok true),
    (letE (nm "x") otherConst deep t,2,.error fuelError),
    (md t,1,.error fuelError),(md t,2,.ok true),(.app otherConst t,2,.ok true) ]

private def boundaryMatrix : IO Nat := do
  require "bounds/zero-before-invalid-root"
    (sameExcept (fun a b => a == b)
      (psKernelExprV2OrdinaryContainsConstWithFuel 0 psKernelExprV2PagedEmpty target 999999)
      (.error fuelError))
  require "bounds/positive-invalid-root"
    (sameExcept (fun a b => a == b)
      (psKernelExprV2OrdinaryContainsConstWithFuel 1 psKernelExprV2PagedEmpty target 999999)
      (.error badRoot))
  let mut assertions := 2
  for (expr,bound,expected) in boundRows do
    let (state,root) ← expect (add expr empty)
    require "bounds/ordered-branch-bound"
      (sameExcept (fun a b => a == b)
        (psKernelExprV2OrdinaryContainsConstWithFuel bound state.arena target root) expected)
    assertions := assertions + 1
  pure assertions

private def indexListMatrix : IO Nat := do
  let (state,tId) ← expect (add t empty)
  let (state,uId) ← expect (add otherConst state)
  let probes : List (List Nat × Except String Bool) :=
    [ ([],.ok false),([uId,tId],.ok true),([tId,999999],.ok true),
      ([999999,tId],.error badRoot),([uId,999999],.error badRoot),
      ([uId,uId],.ok false),([tId,tId],.ok true) ]
  let mut assertions := 0
  for (ids,expected) in probes do
    require "indexLists/first-hit-first-error"
      (sameExcept (fun a b => a == b)
        (psKernelExprV2OrdinaryIndicesContainTarget state.arena target ids) expected)
    assertions := assertions + 1
  pure assertions

private def precedenceMatrix : IO Nat := do
  let probes : List
      (List PsKernelOpenBinder × List PsKernelLevel × Nat × PsKernelExpr) :=
    [ ([paramP],[],1,apps otherConst [p,t]),([paramP],[lu],1,apps t [p,t]),
      ([paramP],[],1,apps t [q,t]),([paramP],[],2,apps t [p,t]) ]
  let mut assertions := 0
  for (parameters,levels,count,expr) in probes do
    let (state,parametersId) ← expect (buildParams parameters empty)
    let (state,root) ← expect (add expr state)
    require "precedence/shape-before-recursive-index"
      (sameExcept sameNatList
        (psKernelExprV2OrdinaryValidateConstructorResult
          state.arena target levels parametersId count root) (.error shapeError))
    assertions := assertions + 1
  pure assertions

def main : IO Unit := do
  require "harness/constructor-tags"
    (!sameExcept (fun (a b : String) => a == b) (.ok "same") (.error "same") &&
      !sameOption sameNatList none (some []))
  let selector ← selectorMatrix
  let consumer ← consumerMatrix
  let occurrence ← occurrenceMatrix
  let bounds ← boundaryMatrix
  let indexLists ← indexListMatrix
  let precedence ← precedenceMatrix
  let assertions := 1 + selector + consumer + occurrence + bounds + indexLists + precedence
  require "exact-assertion-inventory"
    (assertions == 432 && selector == 138 && consumer == 26 && occurrence == 240 &&
      bounds == 16 && indexLists == 7 && precedence == 4)
  IO.println "PSC1_ORDINARY_CONSTRUCTOR_RESULT_NATIVE: PASS assertions=432 selectorRows=46 occurrenceTerms=30 targets=2 fullAdmission=false"
  IO.println "PSC1_ORDINARY_CONSTRUCTOR_RESULT_SECTIONS: PASS harness=1 selector=138 consumer=26 occurrence=240 bounds=16 indexLists=7 precedence=4"
