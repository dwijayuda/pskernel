import Ps.KernelCore.API.Dag
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

private def require (label : String) (condition : Bool) : IO Unit := do
  unless condition do throw (IO.userError ("PSC1_V2_RECURSOR_FAIL " ++ label))

private def expect {α : Type} : Except String α → IO α
  | .ok result => pure result
  | .error error => throw (IO.userError error)

private def expectPublic {α : Type} (label : String) : Except PsKernelError α → IO α
  | .ok result => pure result
  | .error (.rejectedInvalid message) =>
      throw (IO.userError ("PSC1_V2_RECURSOR_PUBLIC " ++ label ++ " rejectedInvalid: " ++ message))
  | .error (.declinedUnsupported message) =>
      throw (IO.userError ("PSC1_V2_RECURSOR_PUBLIC " ++ label ++ " declinedUnsupported: " ++ message))
  | .error (.resourceExhausted _ message) =>
      throw (IO.userError ("PSC1_V2_RECURSOR_PUBLIC " ++ label ++ " resourceExhausted: " ++ message))
  | .error (.internalError message) =>
      throw (IO.userError ("PSC1_V2_RECURSOR_PUBLIC " ++ label ++ " internalError: " ++ message))

private def nm (value : String) := PsKernelName.str .anonymous value
private def one := PsKernelLevel.succ PsKernelLevel.zero
private def s1 := PsKernelExpr.sort one
private def nat := PsKernelExpr.const psKernelNatName []
private def lit (value : Nat) := PsKernelExpr.lit (.nat value)
private def lam (name : String) (type body : PsKernelExpr) :=
  PsKernelExpr.lam (nm name) type body .default
private def forallE (name : String) (type body : PsKernelExpr) :=
  PsKernelExpr.forallE (nm name) type body .default
private def apply (fn : PsKernelExpr) (args : List PsKernelExpr) := psKernelApplyArgs fn args
private def natRecName := psKernelSimpleRecName psKernelNatName
private def boxName := nm "IotaBox"
private def boxCtorName := PsKernelName.str boxName "mk"
private def boxRecName := psKernelSimpleRecName boxName
private def box := apply (.const boxName [.zero]) [nat]
private def boxMajor := apply (.const boxCtorName [.zero]) [nat,lit 5]
private def natMotive := lam "n" nat nat
private def natStep := lam "n" nat (lam "ih" nat (.bvar 0))
private def natRec (major : PsKernelExpr) :=
  apply (.const natRecName [one]) [natMotive,lit 7,natStep,major]
private def boxRec (motive minor : PsKernelExpr) :=
  apply (.const boxRecName [one,.zero]) [nat,motive,minor,boxMajor]

private def decode (arena : PsKernelExprV2PagedArena) (root : Nat) : IO PsKernelExpr := do
  let graph ← expect (psKernelExprV2DecodeChecked arena)
  expect (psKernelExprV2DecodedRequire graph root)

private def compareWhnf (label : String)
    (original : Except String (PsKernelExpr × PsKernelCheckerState))
    (actual : Option (Except String (PsKernelExprV2WhnfState × Nat))) : IO Unit := do
  match original,actual with
  | .error a,some (.error b) => require (label ++ "-exact-error") (a == b)
  | .ok a,some (.ok b) =>
      require (label ++ "-expression") (psKernelExprEqual a.fst (← decode b.fst.arena b.snd))
  | _,none => throw (IO.userError ("unexpected recursor fallback: " ++ label))
  | _,_ => throw (IO.userError ("recursor result mismatch: " ++ label))

private def compareReduction (label : String)
    (original : Except String (Option PsKernelExpr × PsKernelCheckerState))
    (actual : Option (Except String (PsKernelExprV2WhnfState × Option Nat))) : IO Unit := do
  match original,actual with
  | .error a,some (.error b) => require (label ++ "-exact-error") (a == b)
  | .ok a,some (.ok b) =>
      match a.fst,b.snd with
      | none,none => pure ()
      | some left,some right =>
          require (label ++ "-expression") (psKernelExprEqual left (← decode b.fst.arena right))
      | _,_ => throw (IO.userError ("recursor optional result mismatch: " ++ label))
  | _,none => throw (IO.userError ("unexpected recursor reduction fallback: " ++ label))
  | _,_ => throw (IO.userError ("recursor reduction error mismatch: " ++ label))

private def inferOfficialName : PsKernelName → Lean.Name
  | .anonymous => .anonymous
  | .str parent value => .str (inferOfficialName parent) value
  | .num parent value => .num (inferOfficialName parent) value

private def inferOfficialLevel : PsKernelLevel → Option Lean.Level
  | .zero => some .zero
  | .succ value => (inferOfficialLevel value).map Lean.Level.succ
  | .max left right => do
      return .max (← inferOfficialLevel left) (← inferOfficialLevel right)
  | .imax left right => do
      return .imax (← inferOfficialLevel left) (← inferOfficialLevel right)
  | .param name => some (.param (inferOfficialName name))
  | .mvar _ => none

private def inferOfficialBinder : PsKernelBinderInfo → Lean.BinderInfo
  | .default => .default
  | .implicit => .implicit
  | .strictImplicit => .strictImplicit
  | .instImplicit => .instImplicit

private def inferOfficialExpr : PsKernelExpr → Option Lean.Expr
  | .bvar index => some (.bvar index)
  | .sort level => (inferOfficialLevel level).map Lean.Expr.sort
  | .const name levels => do
      return .const (inferOfficialName name) (← levels.mapM inferOfficialLevel)
  | .app fn arg => do
      return .app (← inferOfficialExpr fn) (← inferOfficialExpr arg)
  | .lam name domain body binderInfo => do
      return .lam (inferOfficialName name) (← inferOfficialExpr domain)
        (← inferOfficialExpr body) (inferOfficialBinder binderInfo)
  | .forallE name domain body binderInfo => do
      return .forallE (inferOfficialName name) (← inferOfficialExpr domain)
        (← inferOfficialExpr body) (inferOfficialBinder binderInfo)
  | .letE name type value body nondep => do
      return .letE (inferOfficialName name) (← inferOfficialExpr type)
        (← inferOfficialExpr value) (← inferOfficialExpr body) nondep
  | .lit (.nat value) => some (.lit (.natVal value))
  | .lit (.str value) => some (.lit (.strVal value))
  | .mdata _ body => (inferOfficialExpr body).map (Lean.Expr.mdata {})
  | .proj name index body => do
      return .proj (inferOfficialName name) index (← inferOfficialExpr body)
  | _ => none

private def officialExpr (value : PsKernelExpr) : IO Lean.Expr :=
  match inferOfficialExpr value with
  | some result => pure result
  | none => throw (IO.userError "official recursor conversion")

private structure Prepared where
  session : PsKernelKernelSession
  arena : PsKernelExprV2PagedArena
  commands : List PsKernelDagCommand
  declarations : List PsKernelExprV2DeclarationRef

private def prepareInductive (label : String) (prior : Prepared) (decl : PsKernelSimpleInductiveDecl) :
    IO Prepared := do
  let admitted ← expectPublic ("admit-" ++ label)
    (psKernelV1AdmitDeclaration prior.session (.ordinaryInductive decl))
  let (a,type) ← expect (psKernelExprV2PagedImportIntoChecked prior.arena decl.type)
  let mut arena := a
  let mut ctors := []
  for ctor in decl.ctors do
    let (a,root) ← expect (psKernelExprV2PagedImportIntoChecked arena ctor.type)
    arena := a
    ctors := ctors ++ [PsKernelDagConstructor.mk ctor.name root]
  let request := PsKernelDagDeclarationRequest.ordinaryInductive decl.levelParams decl.numParams
    (PsKernelDagInductive.mk decl.name type ctors) decl.isUnsafe
  pure (Prepared.mk admitted.session arena (prior.commands ++ [.admit request])
    (psKernelDagDeclarationsAfterAdmission request prior.declarations))

private def recursorInfo (session : PsKernelKernelSession) (name : PsKernelName) :
    IO PsKernelRecursorInfo := do
  match psKernelEnvironmentFind session.environment name with
  | some (.recInfo value) => pure value
  | _ => throw (IO.userError "expected checked generated recursor")

private def invalidReference {α : Type} (result : Except PsKernelError α) : Bool :=
  match result with
  | .error (.rejectedInvalid text) => text == "PSKERNEL_V2_DECODE_INVALID_REFERENCE"
  | _ => false

private def rejectedInvalid {α : Type} (result : Except PsKernelError α) : Bool :=
  match result with
  | .error (.rejectedInvalid _) => true
  | _ => false

private def officialInductive (environment : Lean.Environment)
    (decl : PsKernelSimpleInductiveDecl) : IO Lean.Environment := do
  let type ← officialExpr decl.type
  let mut constructors : List Lean.Constructor := []
  for ctor in decl.ctors do
    constructors := constructors ++ [{ name := inferOfficialName ctor.name, type := ← officialExpr ctor.type }]
  match environment.addDeclCore 0 0 (.inductDecl
      (decl.levelParams.map inferOfficialName) decl.numParams
      [{ name := inferOfficialName decl.name, type := type, ctors := constructors }] decl.isUnsafe)
      none true with
  | .ok next => pure next
  | .error _ => throw (IO.userError "official checked inductive fixture failed")


/- Non-K major tests use checked neutral constants. Generated recursor metadata
   is still installed only after the complete original inductive admission. -/
private def majorPrepareAxiom (prior : Prepared) (name : PsKernelName) (type : PsKernelExpr) :
    IO Prepared := do
  let header := PsKernelConstantBase.mk name [] type
  let admitted ← expectPublic "major-neutral-axiom"
    (psKernelV1AdmitDeclaration prior.session (.axiomDecl (PsKernelAxiomInfo.mk header false)))
  let (arena,typeId) ← expect (psKernelExprV2PagedImportIntoChecked prior.arena type)
  let request := PsKernelDagDeclarationRequest.axiomDecl
    (PsKernelDagConstantBase.mk name [] typeId) false
  pure (Prepared.mk admitted.session arena (prior.commands ++ [.admit request])
    (psKernelDagDeclarationsAfterAdmission request prior.declarations))

private def majorCompareWhnf (label : String)
    (original : Except String (PsKernelExpr × PsKernelCheckerState))
    (actual : Option (Except String (PsKernelExprV2CheckState × Nat))) : IO Unit := do
  compareWhnf label original (psKernelExprV2LowerWhnfAttempt actual)
  match original,actual with
  | .ok a,some (.ok b) =>
      require (label ++ "-fresh-counter") (a.snd.nextFresh == b.fst.nextFresh)
  | _,_ => pure ()

private def majorCompareReduction (label : String)
    (original : Except String (Option PsKernelExpr × PsKernelCheckerState))
    (actual : Option (Except String (PsKernelExprV2CheckState × Option Nat))) : IO Unit := do
  compareReduction label original (psKernelExprV2LowerOptionalWhnfAttempt actual)
  match original,actual with
  | .ok a,some (.ok b) =>
      require (label ++ "-fresh-counter") (a.snd.nextFresh == b.fst.nextFresh)
  | _,_ => pure ()

private def majorResourceMatrix (session : PsKernelKernelSession)
    (generated : PsKernelDagGeneratedState)
    (cases : List (String × PsKernelExpr × PsKernelExpr × Nat)) : IO Unit := do
  let scalar := (psKernelKernelSessionChecker session [] .safe).context
  let initial := psKernelExprV2CheckStateFromWhnf
    (psKernelExprV2WhnfStateForDeclarations generated.arena generated.declarations)
  let mut publics := 0
  let mut cores := 0
  let mut owners := 0
  let mut reducers := 0
  for (label,expr,_,root) in cases do
    for fuel in [0,1,2,3,6,16,64] do
      for (limit,depth) in [(0,0),(1,15),(1,16)] do
        let oldContext := { scalar with maxRecDepth := limit,recDepth := depth }
        let context := psKernelExprV2CheckContextEmpty oldContext
        let oldDefEq := psKernelIsDefEqWithFuel fuel
        let newDefEq := psKernelExprV2TryDefEqStateWithFuel fuel
        majorCompareWhnf (label ++ "-major-public")
          (psKernelWhnfWithRecursorFuel fuel oldDefEq oldContext psKernelCheckerStateEmpty expr)
          (psKernelExprV2TryWhnfCheckStateWithFuel fuel context initial root)
        publics := publics + 1
        for cheapRec in [false,true] do
          for cheapProj in [false,true] do
            majorCompareWhnf (label ++ "-major-core")
              (psKernelWhnfCoreWithRecursorFuel fuel oldDefEq oldContext
                psKernelCheckerStateEmpty expr cheapRec cheapProj)
              (psKernelExprV2TryWhnfCoreOwnedWithLocalValuesFuel fuel newDefEq
                psKernelExprV2CheckLocalValue context initial root cheapRec cheapProj)
            cores := cores + 1
    for structuralFuel in [0,1,2,4,16] do
      for recursorFuel in [0,1,2,8] do
        for (limit,depth) in [(0,0),(1,15),(1,16)] do
          let oldContext := { scalar with maxRecDepth := limit,recDepth := depth }
          let context := psKernelExprV2CheckContextEmpty oldContext
          let reducer := psKernelExprV2TryReduceRecursorOwnedWithFuel recursorFuel
            (psKernelExprV2TryDefEqStateWithFuel 64) psKernelExprV2CheckLocalValue
          majorCompareWhnf (label ++ "-major-fixed-owner")
            (psKernelWhnfWithFuel structuralFuel
              (psKernelReduceRecursorBoundedWithFuel recursorFuel (psKernelIsDefEqWithFuel 64))
              oldContext psKernelCheckerStateEmpty expr)
            (psKernelExprV2TryWhnfOwnedWithReducerFuel structuralFuel
              reducer psKernelExprV2CheckLocalValue context initial root)
          owners := owners + 1
    for fuel in [0,1,2,3,8,32] do
      for (limit,depth) in [(0,0),(1,15),(1,16)] do
        let oldContext := { scalar with maxRecDepth := limit,recDepth := depth }
        let context := psKernelExprV2CheckContextEmpty oldContext
        for cheapRec in [false,true] do
          for cheapProj in [false,true] do
            majorCompareReduction (label ++ "-major-reducer")
              (psKernelReduceRecursorBoundedWithFuel fuel (psKernelIsDefEqWithFuel 64)
                oldContext psKernelCheckerStateEmpty expr cheapRec cheapProj)
              (psKernelExprV2TryReduceRecursorOwnedWithFuel fuel
                (psKernelExprV2TryDefEqStateWithFuel 64) psKernelExprV2CheckLocalValue
                context initial root cheapRec cheapProj)
            reducers := reducers + 1
  require "non-K-major-resource-matrix"
    (publics == 126 && cores == 504 && owners == 360 && reducers == 432)
  IO.println "PSC1_V2_DAG_RECURSOR_MAJOR_MATRIX: PASS public=126 core=504 owners=360 reducer=432"


/- Diagnostic cache rows use an out-of-range hash and cannot establish a
   cached judgment. Each callback must receive the complete previous marker. -/
private def majorCacheTag (rows : List PsKernelExprV2WhnfCacheEntry) (tag : Nat) : Bool :=
  match rows with
  | [row] => row.hash == psKernelCacheHashModulus + tag
  | _ => false

private def majorPairTag (rows : List PsKernelExprV2DefEqPair) (tag : Nat) : Bool :=
  match rows with
  | [row] => row.hash == psKernelCacheHashModulus + tag
  | _ => false

private def majorArenaTag (state : PsKernelExprV2CheckState) (tag : Nat) : Bool :=
  match state.checkedInfer with
  | [row] =>
      match psKernelExprV2PagedRequire state.whnf.arena row.result with
      | .ok entry =>
          match entry.node with
          | .lit (.nat value) => value == 12000 + tag
          | _ => false
      | .error _ => false
  | _ => false

private def majorStateTag (state : PsKernelExprV2CheckState) (tag : Nat) : Bool :=
  state.nextFresh == tag && majorCacheTag state.checkedInfer tag &&
    majorPairTag state.success tag && majorCacheTag state.inferOnly tag &&
    majorCacheTag state.unfold tag && majorPairTag state.failure tag && majorArenaTag state tag

private def majorStamp (key : Nat) (state : PsKernelExprV2CheckState) (tag : Nat) :
    Except String PsKernelExprV2CheckState := do
  let (arena,markerId) ← psKernelExprV2PagedMkLit state.whnf.arena (.nat (12000 + tag))
  let cache := PsKernelExprV2WhnfCacheEntry.mk key markerId (psKernelCacheHashModulus + tag)
  let pair := PsKernelExprV2DefEqPair.mk key key (psKernelCacheHashModulus + tag)
  let whnf := PsKernelExprV2WhnfState.mk arena (cache :: state.whnf.coreCache)
    (cache :: state.whnf.publicCache) state.whnf.declarations
  pure (PsKernelExprV2CheckState.mk whnf tag [cache] [pair] [cache] [cache] [pair])

private def majorCallback (seed failAt : Nat) (decline : Bool)
    (expectedRoot result tag : Nat) (state : PsKernelExprV2CheckState) (root : Nat) :
    Option (Except String (PsKernelExprV2CheckState × Nat)) :=
  if root != expectedRoot || !majorStateTag state tag then
    some (.error "major callback received wrong input or stale state")
  else if failAt == tag + 1 - seed then
    if decline then none else some (.error "MAJOR_INJECTED")
  else
    some ((majorStamp expectedRoot state (tag + 1)).map (fun next => (next,result)))

private def majorOrderRegression (scalar : PsKernelCheckerContext)
    (initial : PsKernelExprV2CheckState) (root majorId typeId sortId : Nat)
    (expr majorExpr : PsKernelExpr) : IO Unit := do
  let context := psKernelExprV2CheckContextEmpty scalar
  let seed := 30
  let seeded ← expect (majorStamp majorId initial seed)
  require "major-arena-loss-marker-detected"
    (!majorStateTag (psKernelExprV2CheckStateWithArena seeded initial.whnf.arena) seed)
  let denyEq := fun (_ : PsKernelExprV2CheckContext) (_ : PsKernelExprV2CheckState)
      (_ _ : Nat) =>
    (some (.error "MAJOR_FORBIDDEN_DEFEQ") :
      Option (Except String (PsKernelExprV2CheckState × Bool)))
  let oldWhnf := fun (_ : PsKernelCheckerContext) (state : PsKernelCheckerState)
      (term : PsKernelExpr) =>
    Except.ok (term,{ state with nextFresh := state.nextFresh + 1 })
  let oldCore := fun (c : PsKernelCheckerContext) (state : PsKernelCheckerState)
      (term : PsKernelExpr) (_ _ : Bool) => oldWhnf c state term
  let oldInfer := fun (_ : PsKernelCheckerContext) (state : PsKernelCheckerState)
      (term : PsKernelExpr) =>
    if psKernelExprEqual term majorExpr then
      Except.ok (box,{ state with nextFresh := state.nextFresh + 1 })
    else if psKernelExprEqual term box then
      Except.ok (s1,{ state with nextFresh := state.nextFresh + 1 })
    else Except.error "MAJOR_OLD_INFER_INPUT"
  let oldEq := fun (_ : PsKernelCheckerContext) (_ : PsKernelCheckerState)
      (_ _ : PsKernelExpr) =>
    (Except.error "MAJOR_FORBIDDEN_DEFEQ" : Except String (Bool × PsKernelCheckerState))
  let mut sequences := 0
  let mut propagated := 0
  for cheapRec in [false,true] do
    for cheapProj in [false,true] do
      let run := fun (failAt : Nat) (decline : Bool) =>
        let publicWhnf := fun (_ : PsKernelExprV2CheckContext)
            (state : PsKernelExprV2CheckState) (nextRoot : Nat) =>
          if state.nextFresh == seed then
            majorCallback seed failAt decline majorId majorId seed state nextRoot
          else if state.nextFresh == seed + 2 then
            majorCallback seed failAt decline typeId typeId (seed + 2) state nextRoot
          else majorCallback seed failAt decline sortId sortId (seed + 4) state nextRoot
        let coreWhnf := fun (_ : PsKernelExprV2CheckContext)
            (state : PsKernelExprV2CheckState) (nextRoot : Nat) (cr cp : Bool) =>
          if cr == cheapRec && cp == cheapProj then
            majorCallback seed failAt decline majorId majorId seed state nextRoot
          else some (.error "MAJOR_CHEAP_FLAGS")
        let inferType := fun (_ : PsKernelExprV2CheckContext)
            (state : PsKernelExprV2CheckState) (nextRoot : Nat) =>
          if state.nextFresh == seed + 1 then
            majorCallback seed failAt decline majorId typeId (seed + 1) state nextRoot
          else majorCallback seed failAt decline typeId sortId (seed + 3) state nextRoot
        psKernelExprV2TryReduceRecursorOwnedWith
          publicWhnf coreWhnf inferType denyEq context seeded root cheapRec cheapProj
      let actual := run 0 false
      majorCompareReduction "major-five-fixed-callbacks"
        (psKernelReduceRecursorWith oldWhnf oldCore oldInfer oldEq scalar
          { psKernelCheckerStateEmpty with nextFresh := seed } expr cheapRec cheapProj)
        actual
      let some (.ok result) := actual
        | throw (IO.userError "major ordered reduction failed")
      require "major-all-six-fields-after-rule" (majorStateTag result.fst (seed + 5))
      require "major-core-cache-retained"
        (result.fst.whnf.coreCache.any (fun row => row.hash == psKernelCacheHashModulus + seed + 5))
      require "major-public-cache-retained"
        (result.fst.whnf.publicCache.any (fun row => row.hash == psKernelCacheHashModulus + seed + 5))
      require "major-owner-retained"
        (psKernelExprV2DeclarationRefFind result.fst.whnf.declarations boxRecName).isSome
      require "major-rule-actually-reduced" result.snd.isSome
      let _ ← expect (psKernelExprV2PagedValidate result.fst.whnf.arena)
      sequences := sequences + 1
      for failAt in [1,2,3,4,5] do
        for decline in [false,true] do
          require "major-failure-order-and-propagation"
            (match run failAt decline with
             | none => decline
             | some (.error error) => !decline && error == "MAJOR_INJECTED"
             | _ => false)
          propagated := propagated + 1
  require "major-sequence-matrix" (sequences == 4 && propagated == 40)
  IO.println "PSC1_V2_DAG_RECURSOR_MAJOR_STATE: PASS sequence=4 propagated=40"

private def majorFamilyRegression (context : PsKernelExprV2CheckContext)
    (initial : PsKernelExprV2CheckState) (natInfo boxInfo : PsKernelRecursorInfo)
    (neutralId boxNeutralId constructorId : Nat) : IO Unit := do
  let mut comparisons := 0
  for info in [natInfo,boxInfo] do
    let some typeId := psKernelExprV2RecursorTypeOwner initial.whnf.declarations info
      | throw (IO.userError "major type owner missing")
    for fuel in [0,1,2,3,4,5,8] do
      for index in [0,1,3,4,8] do
        let expected := psKernelRecursorMajorInductWithFuel fuel info.base.type index
        let actual ← expect (psKernelExprV2RecursorMajorInductWithFuel fuel
          initial.whnf.arena typeId index)
        require "major-type-walk-exact"
          (match expected,actual with
           | none,none => true
           | some a,some b => psKernelNameEq a b
           | _,_ => false)
        comparisons := comparisons + 1
  let bad := initial.whnf.arena.size + 1
  require "major-type-zero-before-root"
    (match psKernelExprV2RecursorMajorInductWithFuel 0 initial.whnf.arena bad 0 with
     | .ok none => true | _ => false)
  require "major-type-positive-invalid-root"
    (match psKernelExprV2PagedRequire initial.whnf.arena bad,
        psKernelExprV2RecursorMajorInductWithFuel 1 initial.whnf.arena bad 0 with
     | .error expected,.error actual => expected == actual
     | _,_ => false)
  let forbidden := fun (_ : PsKernelExprV2CheckContext) (_ : PsKernelExprV2CheckState) (_ : Nat) =>
    (some (.error "MAJOR_FORBIDDEN_CALLBACK") :
      Option (Except String (PsKernelExprV2CheckState × Nat)))
  let unowned := psKernelExprV2CheckStateWithWhnf initial
    (psKernelExprV2WhnfStateForDeclarations initial.whnf.arena [])
  require "major-constructor-shortcut-before-owner"
    (match psKernelExprV2RecursorToStructureOwnedWith
        forbidden forbidden context unowned boxInfo constructorId with
     | some (.ok result) => result.snd == constructorId | _ => false)
  require "major-recursive-family-never-infers"
    (match psKernelExprV2RecursorToStructureOwnedWith
        forbidden forbidden context initial natInfo neutralId with
     | some (.ok result) => result.snd == neutralId | _ => false)
  require "major-missing-owner-explicit-decline"
    (psKernelExprV2RecursorToStructureOwnedWith
      forbidden forbidden context unowned natInfo neutralId).isNone
  require "major-compatibility-normalizer-scope-unchanged"
    (psKernelExprV2RecursorNormalizeMajor context.scalar initial.whnf neutralId).isNone
  let majorExpr ← decode initial.whnf.arena boxNeutralId
  for fuel in [0,1,2,4] do
    for (count,index) in [(0,0),(1,0),(3,0),(3,1),(1,2)] do
      let expected := psKernelStructureFieldsWithFuel fuel boxName majorExpr count index
      let actual ← expect (psKernelExprV2RecursorStructureFieldsWithFuel
        fuel initial.whnf.arena boxName boxNeutralId count index)
      require "major-field-count-and-truncation" (actual.snd.length == expected.length)
      for (root,term) in actual.snd.zip expected do
        require "major-field-order-exact"
          (psKernelExprEqual (← decode actual.fst root) term)
  require "major-family-comparison-count" (comparisons == 70)
  IO.println "PSC1_V2_DAG_RECURSOR_MAJOR_FAMILY: PASS comparisons=70 fields=20"


private def majorStringRegression (context : PsKernelExprV2CheckContext)
    (initial : PsKernelExprV2CheckState) (natInfo : PsKernelRecursorInfo)
    (official : Lean.Environment) : IO Unit := do
  let values := ["","a","é","é","🙂","a" ++ String.singleton (Char.ofNat 0) ++ "β"]
  let forbidden := fun (_ : PsKernelExprV2CheckContext) (_ : PsKernelExprV2CheckState) (_ : Nat) =>
    (some (.error "STRING_MAJOR_FORBIDDEN_INFERENCE") :
      Option (Except String (PsKernelExprV2CheckState × Nat)))
  let denyEq := fun (_ : PsKernelExprV2CheckContext) (_ : PsKernelExprV2CheckState) (_ _ : Nat) =>
    (some (.error "STRING_MAJOR_FORBIDDEN_DEFEQ") :
      Option (Except String (PsKernelExprV2CheckState × Bool)))
  let oldWhnf := fun (_ : PsKernelCheckerContext) (state : PsKernelCheckerState)
      (term : PsKernelExpr) =>
    Except.ok (term,{ state with nextFresh := state.nextFresh + 1 })
  let oldCore := fun (c : PsKernelCheckerContext) (state : PsKernelCheckerState)
      (term : PsKernelExpr) (_ _ : Bool) => oldWhnf c state term
  let oldInfer := fun (_ : PsKernelCheckerContext) (_ : PsKernelCheckerState) (_ : PsKernelExpr) =>
    (Except.error "STRING_MAJOR_FORBIDDEN_INFERENCE" :
      Except String (PsKernelExpr × PsKernelCheckerState))
  let oldEq := fun (_ : PsKernelCheckerContext) (_ : PsKernelCheckerState) (_ _ : PsKernelExpr) =>
    (Except.error "STRING_MAJOR_FORBIDDEN_DEFEQ" : Except String (Bool × PsKernelCheckerState))
  let mut cases := 0
  let mut propagated := 0
  for value in values do
    let major := PsKernelExpr.lit (.str value)
    let (arena,majorId) ← expect (psKernelExprV2PagedImportIntoChecked initial.whnf.arena major)
    let expr := natRec major
    let (arena,root) ← expect (psKernelExprV2PagedImportIntoChecked arena expr)
    let entry ← expect (psKernelExprV2PagedRequire arena root)
    let .app _ callMajorId := entry.node
      | throw (IO.userError "String major application fixture")
    let state := psKernelExprV2CheckStateWithArena initial arena
    let identity := fun (_ : PsKernelExprV2CheckContext)
        (next : PsKernelExprV2CheckState) (id : Nat) => some (.ok (next,id))
    let some normalizedAttempt := psKernelExprV2RecursorNormalizeMajorOwnedWith
        identity forbidden context state natInfo majorId
      | throw (IO.userError "String normalization helper declined")
    let normalized ← expect normalizedAttempt
    let expected := psKernelStringLitToConstructor value
    require "string-major-constructor-exact"
      (psKernelExprEqual expected (← decode normalized.fst.whnf.arena normalized.snd))
    require "string-major-official-literal-check"
      (match Lean.Kernel.check official {} (← officialExpr major) with | .ok _ => true | _ => false)
    require "string-major-official-constructor-check"
      (match Lean.Kernel.check official {} (← officialExpr expected) with | .ok _ => true | _ => false)
    require "string-major-official-equality"
      (match Lean.Kernel.isDefEq official {} (← officialExpr major) (← officialExpr expected) with
       | .ok true => true | _ => false)
    -- These intentionally ill-typed Nat-rec/String inputs exercise only raw
    -- callback ordering; they are never offered as admitted declarations.
    let seeded ← expect (majorStamp callMajorId state 60)
    for cheapRec in [false,true] do
      for cheapProj in [false,true] do
        let run := fun (failAt : Nat) (decline : Bool) =>
          let publicWhnf := fun (_ : PsKernelExprV2CheckContext)
              (next : PsKernelExprV2CheckState) (id : Nat) =>
            if next.nextFresh == 60 then
              majorCallback 60 failAt decline callMajorId callMajorId 60 next id
            else
              majorCallback 60 failAt decline id id 61 next id
          let coreWhnf := fun (_ : PsKernelExprV2CheckContext)
              (next : PsKernelExprV2CheckState) (id : Nat) (cr cp : Bool) =>
            if cr == cheapRec && cp == cheapProj then
              majorCallback 60 failAt decline callMajorId callMajorId 60 next id
            else some (.error "STRING_MAJOR_CHEAP_FLAGS")
          psKernelExprV2TryReduceRecursorOwnedWith
            publicWhnf coreWhnf forbidden denyEq context seeded root cheapRec cheapProj
        let actual := run 0 false
        majorCompareReduction "string-major-mandatory-public-callback"
          (psKernelReduceRecursorWith oldWhnf oldCore oldInfer oldEq context.scalar
            { psKernelCheckerStateEmpty with nextFresh := 60 } expr cheapRec cheapProj)
          actual
        require "string-major-two-complete-states"
          (match actual with
           | some (.ok result) => majorStateTag result.fst 62 && result.snd.isNone
           | _ => false)
        cases := cases + 1
        for decline in [false,true] do
          require "string-major-second-public-failure-preserved"
            (match run 2 decline with
             | none => decline
             | some (.error error) => !decline && error == "MAJOR_INJECTED"
             | _ => false)
          propagated := propagated + 1
  require "string-major-matrix" (cases == 24 && propagated == 48)
  IO.println "PSC1_V2_DAG_RECURSOR_MAJOR_STRING: PASS callbacks=24 propagated=48 official=6"

private def majorOfficialAxiom (environment : Lean.Environment)
    (name : PsKernelName) (type : PsKernelExpr) : IO Lean.Environment := do
  match environment.addDeclCore 0 0 (.axiomDecl {
    name := inferOfficialName name
    levelParams := []
    type := ← officialExpr type
    isUnsafe := false
  }) none true with
  | .ok next => pure next
  | .error _ => throw (IO.userError "official major neutral axiom failed")

private def majorAdmissionRegression (prepared : Prepared) (input : PsKernelExprV2PagedArena)
    (generated : PsKernelDagGeneratedState) (official : Lean.Environment)
    (cases : List (String × PsKernelExpr × PsKernelExpr × Nat))
    (declarations : List (String × PsKernelExpr × PsKernelExpr × Nat × Nat × Bool)) : IO Unit := do
  let empty ← expectPublic "major-empty"
    (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let replay ← expectPublic "major-public-batch" (psKernelV1RunDag empty [] .safe input
    (prepared.commands ++ cases.map (fun (_,_,_,root) => .whnf root)))
  let replies := replay.replies.drop prepared.commands.length
  require "major-public-batch-complete" (replies.length == cases.length)
  for (reply,(label,expr,expected,_)) in replies.zip cases do
    require (label ++ "-major-public-result")
      (match reply with | .normalized value => psKernelExprEq value expected | _ => false)
    let old ← expectPublic (label ++ "-major-V1") (psKernelV1Whnf prepared.session [] .safe expr)
    require (label ++ "-major-V1-result") (psKernelExprEq old expected)
    require (label ++ "-major-official-check")
      (match Lean.Kernel.check official {} (← officialExpr expr) with | .ok _ => true | _ => false)
    require (label ++ "-major-official-defeq")
      (match Lean.Kernel.isDefEq official {} (← officialExpr expr) (← officialExpr expected) with
       | .ok true => true | _ => false)
  for (label,type,value,typeId,valueId,shouldAccept) in declarations do
    let base := PsKernelConstantBase.mk (nm label) [] type
    let definition := PsKernelDefinitionInfo.mk base value .abbrevHint .safe
    let request := PsKernelDagDeclarationRequest.definitionDecl
      (PsKernelDagDefinition.mk (PsKernelDagConstantBase.mk (nm label) [] typeId)
        valueId .abbrevHint .safe)
    let old := psKernelV1AdmitDeclaration prepared.session (.definitionDecl definition)
    let actual := psKernelV1RunDag empty [] .safe input (prepared.commands ++ [.admit request])
    let resources := prepared.session.resources
    let direct := psKernelDagTryAdmitSimpleWithFuel resources.fuel
      (psKernelKernelSessionEnvironment prepared.session) resources.maxRecDepth resources.maxNatSize
      generated.arena generated.declarations request (.definitionDecl definition)
    require (label ++ "-major-direct-V2-admission")
      (match direct,old with
       | some (.ok environment),.ok _ =>
           shouldAccept && (psKernelEnvironmentFind environment (nm label)).isSome
       | some (.error actualError),.error (.rejectedInvalid expectedError) =>
           !shouldAccept && actualError == expectedError
       | _,_ => false)
    let checked := official.addDeclCore 0 0 (.defnDecl {
      name := inferOfficialName (nm label)
      levelParams := []
      type := ← officialExpr type
      value := ← officialExpr value
      hints := .abbrev
      safety := .safe
    }) none true
    require (label ++ "-major-V1-admission")
      (match old with | .ok _ => shouldAccept | .error (.rejectedInvalid _) => !shouldAccept | _ => false)
    require (label ++ "-major-public-admission")
      (match actual with | .ok _ => shouldAccept | .error (.rejectedInvalid _) => !shouldAccept | _ => false)
    require (label ++ "-major-official-admission")
      (match checked with | .ok _ => shouldAccept | .error _ => !shouldAccept)
  IO.println "PSC1_V2_DAG_OFFICIAL_RECURSOR_MAJOR: PASS valid=6 admitted=2 rejected=2"

private def majorRegression (prior : Prepared) (priorOfficial : Lean.Environment)
    (natInfo boxInfo : PsKernelRecursorInfo) : IO Unit := do
  let natNeutralName := nm "iotaNeutralNat"
  let boxNeutralName := nm "iotaNeutralBox"
  let first ← majorPrepareAxiom prior natNeutralName nat
  let prepared ← majorPrepareAxiom first boxNeutralName box
  let natNeutral := PsKernelExpr.const natNeutralName []
  let boxNeutral := PsKernelExpr.const boxNeutralName []
  let projection := PsKernelExpr.proj boxName 0 boxNeutral
  let recOn := fun (major motive minor : PsKernelExpr) =>
    apply (.const boxRecName [one,.zero]) [nat,motive,minor,major]
  let motive := lam "box" box nat
  let minor := lam "value" nat (.bvar 0)
  let fnType := forallE "x" nat nat
  let stuck := natRec natNeutral
  let fixtures : List (String × PsKernelExpr × PsKernelExpr) := [
    ("stuck-recursive-major",stuck,stuck),
    ("neutral-structure-field",recOn boxNeutral motive minor,projection),
    ("neutral-structure-constant",recOn boxNeutral motive (lam "value" nat (lit 11)),lit 11),
    ("structure-major-beta",recOn (.app (lam "box" box (.bvar 0)) boxNeutral) motive minor,projection),
    ("structure-major-zeta",recOn (.letE (nm "box") box boxNeutral (.bvar 0) false) motive minor,projection),
    ("structure-trailing",.app (recOn boxNeutral (lam "box" box fnType)
      (lam "value" nat (lam "x" nat (.bvar 1)))) (lit 9),projection)]
  let mut input := prepared.arena
  let mut cases : List (String × PsKernelExpr × PsKernelExpr × Nat) := []
  for (label,expr,expected) in fixtures do
    let (arena,root) ← expect (psKernelExprV2PagedImportIntoChecked input expr)
    input := arena
    cases := cases ++ [(label,expr,expected,root)]
  -- The motive returns Type, so its recursor elimination level is two.
  let dependentType := forallE "box" box
    (apply (.const boxRecName [.succ one,.zero])
      [nat,lam "box" box s1,lam "value" nat nat,.bvar 0])
  let dependentValue := lam "box" box (lit 0)
  let declarationFixtures := [
    ("majorDependent",dependentType,dependentValue,true),
    ("majorProjected",nat,recOn boxNeutral motive minor,true),
    ("majorWrongType",s1,recOn boxNeutral motive minor,false),
    ("majorWrongDependent",dependentType,lam "box" box s1,false)]
  let mut declarations : List (String × PsKernelExpr × PsKernelExpr × Nat × Nat × Bool) := []
  for (label,type,value,shouldAccept) in declarationFixtures do
    let (arena,typeId) ← expect (psKernelExprV2PagedImportIntoChecked input type)
    let (arena,valueId) ← expect (psKernelExprV2PagedImportIntoChecked arena value)
    input := arena
    declarations := declarations ++ [(label,type,value,typeId,valueId,shouldAccept)]
  let (a,natNeutralId) ← expect (psKernelExprV2PagedImportIntoChecked input natNeutral)
  let (a,neutralId) ← expect (psKernelExprV2PagedImportIntoChecked a boxNeutral)
  let (a,typeId) ← expect (psKernelExprV2PagedImportIntoChecked a box)
  let (a,sortId) ← expect (psKernelExprV2PagedImportIntoChecked a s1)
  let (a,constructorId) ← expect (psKernelExprV2PagedImportIntoChecked a boxMajor)
  let (a,orderRoot) ← expect (psKernelExprV2PagedImportIntoChecked a (recOn boxNeutral motive minor))
  input := a
  -- Independent imports do not promise shared IDs. The order probe consumes
  -- the actual major ID inside its own application, rather than an equal ID.
  let orderEntry ← expect (psKernelExprV2PagedRequire input orderRoot)
  let .app _ orderMajorId := orderEntry.node
    | throw (IO.userError "major order application fixture")
  let built ← expect (psKernelExprV2DecodeChecked input)
  let mut generated := PsKernelDagGeneratedState.mk input built prepared.declarations
  for command in prepared.commands do
    generated ← expect (psKernelDagGeneratedAfterCommand command prepared.session.environment generated)
  let scalar := (psKernelKernelSessionChecker prepared.session [] .safe).context
  let context := psKernelExprV2CheckContextEmpty scalar
  let initial := psKernelExprV2CheckStateFromWhnf
    (psKernelExprV2WhnfStateForDeclarations generated.arena generated.declarations)
  let official1 ← majorOfficialAxiom priorOfficial natNeutralName nat
  let official ← majorOfficialAxiom official1 boxNeutralName box
  majorResourceMatrix prepared.session generated cases
  majorOrderRegression scalar initial orderRoot orderMajorId typeId sortId
    (recOn boxNeutral motive minor) boxNeutral
  majorFamilyRegression context initial natInfo boxInfo natNeutralId neutralId constructorId
  majorStringRegression context initial natInfo official
  majorAdmissionRegression prepared input generated official cases declarations

private def regression : IO Unit := do
  let empty ← expectPublic "empty-session" (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let natDecl := PsKernelSimpleInductiveDecl.mk [] psKernelNatName s1
    [PsKernelSimpleConstructorDecl.mk psKernelNatZeroName nat,
     PsKernelSimpleConstructorDecl.mk psKernelNatSuccName (forallE "n" nat nat)] false 0
  let u := nm "u"
  -- The data box must live in a provably nonzero universe for Nat-valued elimination.
  let boxType := forallE "A" (.sort (.succ (.param u))) (.sort (.succ (.param u)))
  let boxCtorType := forallE "A" (.sort (.succ (.param u)))
    (forallE "value" (.bvar 0) (apply (.const boxName [.param u]) [.bvar 1]))
  let boxDecl := PsKernelSimpleInductiveDecl.mk [u] boxName boxType
    [PsKernelSimpleConstructorDecl.mk boxCtorName boxCtorType] false 1
  let kName := nm "IotaK"
  let kCtorName := PsKernelName.str kName "mk"
  let kType := PsKernelExpr.const kName []
  let kDecl := PsKernelSimpleInductiveDecl.mk [] kName (.sort .zero)
    [PsKernelSimpleConstructorDecl.mk kCtorName kType] false 0
  let first ← prepareInductive "Nat" (Prepared.mk empty psKernelExprV2PagedEmpty [] []) natDecl
  let second ← prepareInductive "IotaBox" first boxDecl
  let prepared ← prepareInductive "IotaK" second kDecl
  let session := prepared.session
  let natInfo ← recursorInfo session natRecName
  let boxInfo ← recursorInfo session boxRecName
  let kInfo ← recursorInfo session (psKernelSimpleRecName kName)
  require "actual-checked-non-K-and-K-metadata" (!natInfo.k && !boxInfo.k && kInfo.k)
  require "data-box-recursor-has-independent-elimination-universe"
    (boxInfo.base.levelParams.length == 2)
  let ctorZero := PsKernelExpr.const psKernelNatZeroName []
  let ctorTwo := apply (.const psKernelNatSuccName [])
    [apply (.const psKernelNatSuccName []) [ctorZero]]
  let fnType := forallE "x" nat nat
  let natFn := apply (.const natRecName [one])
    [lam "n" nat fnType,lam "x" nat (.bvar 0),
     lam "n" nat (lam "ih" fnType (.bvar 0)),lit 3]
  let partialNat := apply (.const natRecName [one]) [natMotive,lit 7,natStep]
  let fixtures : List (String × PsKernelExpr × PsKernelExpr) := [
    ("zero-constructor",natRec ctorZero,lit 7),
    ("two-constructors",natRec ctorTwo,lit 7),
    ("zero-literal",natRec (lit 0),lit 7),
    ("three-literal",natRec (lit 3),lit 7),
    ("major-beta",natRec (.app (lam "n" nat (.bvar 0)) ctorTwo),lit 7),
    ("major-zeta",natRec (.letE (nm "n") nat ctorTwo (.bvar 0) false),lit 7),
    ("major-metadata",natRec (.mdata 53 ctorTwo),lit 7),
    ("nat-trailing",.app natFn (lit 9),lit 9),
    ("unsaturated",partialNat,partialNat),
    ("parameter-field",boxRec (lam "box" box nat) (lam "a" nat (.bvar 0)),lit 5),
    ("trailing-field",.app (boxRec (lam "box" box fnType)
      (lam "a" nat (lam "x" nat (.bvar 1)))) (lit 9),lit 5),
    ("trailing-argument",.app (boxRec (lam "box" box fnType)
      (lam "a" nat (lam "x" nat (.bvar 0)))) (lit 9),lit 9)]
  let invalids : List PsKernelExpr := [
    natRec (.const psKernelNatSuccName []),
    natRec boxMajor,
    apply (.const natRecName []) [natMotive,lit 7,natStep,ctorZero],
    apply (.const boxRecName [one,.zero]) [nat,lam "box" box nat,s1,boxMajor]]
  let mut input := prepared.arena
  let mut cases : List (String × PsKernelExpr × PsKernelExpr × Nat) := []
  for (label,expr,expected) in fixtures do
    let (a,root) ← expect (psKernelExprV2PagedImportIntoChecked input expr)
    input := a
    cases := cases ++ [(label,expr,expected,root)]
  let mut invalidRoots : List Nat := []
  for expr in invalids do
    let (a,root) ← expect (psKernelExprV2PagedImportIntoChecked input expr)
    input := a
    invalidRoots := invalidRoots ++ [root]
  let (a,natId) ← expect (psKernelExprV2PagedImportIntoChecked input nat)
  let (a,sevenId) ← expect (psKernelExprV2PagedImportIntoChecked a (lit 7))
  let (a,literalId) ← expect (psKernelExprV2PagedImportIntoChecked a (natRec (lit 0)))
  let (a,constructorId) ← expect (psKernelExprV2PagedImportIntoChecked a (natRec ctorZero))
  let (a,missingFieldId) ← expect (psKernelExprV2PagedImportIntoChecked a (natRec (.const psKernelNatSuccName [])))
  let (a,noRuleId) ← expect (psKernelExprV2PagedImportIntoChecked a (natRec boxMajor))
  let (a,wrongLevelsId) ← expect (psKernelExprV2PagedImportIntoChecked a
    (apply (.const natRecName []) [natMotive,lit 7,natStep,ctorZero]))
  let (a,shortId) ← expect (psKernelExprV2PagedImportIntoChecked a partialNat)
  let kExpr := apply (.const kInfo.base.name [])
    [lam "k" kType kType,.const kCtorName [],.const kCtorName []]
  let (a,kId) ← expect (psKernelExprV2PagedImportIntoChecked a kExpr)
  input := a
  let built ← expect (psKernelExprV2DecodeChecked input)
  let mut generated := PsKernelDagGeneratedState.mk input built prepared.declarations
  for command in prepared.commands do
    generated ← expect (psKernelDagGeneratedAfterCommand command session.environment generated)
  let _ ← expect (psKernelExprV2PagedValidate generated.arena)
  require "owning-size-and-private-extension"
    (generated.arena.size == generated.built.size && input.size < generated.arena.size)
  for index in List.range input.size do
    let before ← expect (psKernelExprV2DecodedRequire built index)
    let after ← expect (psKernelExprV2DecodedRequire generated.built index)
    require "original-ID-stable" (psKernelExprEqual before after)
  for info in [natInfo,boxInfo,kInfo] do
    let some owner := psKernelExprV2DeclarationRefFind generated.declarations info.base.name
      | throw (IO.userError "missing checked generated owner")
    require "checked-generated-type-exact"
      (psKernelExprEqual info.base.type (← decode generated.arena owner.type))
    require "generated-owner-live-kind"
      (psKernelExprV2DeclarationRefMatches owner (.recInfo info))
    for rule in info.rules do
      let some rhs := psKernelExprV2RecursorRuleOwner generated.declarations info rule
        | throw (IO.userError "missing checked generated rule")
      require "checked-generated-rule-exact"
        (psKernelExprEqual rule.rhs (← decode generated.arena rhs))
  require "checked-K-owner-installed"
    (psKernelExprV2DeclarationRefFind generated.declarations kInfo.base.name).isSome
  let checker := psKernelKernelSessionChecker session [] .safe
  let initial := psKernelExprV2WhnfStateForDeclarations generated.arena generated.declarations
  let mut publicCases := 0
  let mut coreCases := 0
  let mut owners := 0
  let mut reducers := 0
  Lean.initSearchPath (← Lean.findSysroot)
  let official0 ← Lean.importModules #[{ module := `Init }] {}
  let official1 ← officialInductive official0 boxDecl
  let official ← officialInductive official1 kDecl
  for (label,expr,expected,root) in cases do
    for fuel in [0,1,2,3,6,16,64] do
      for (limit,depth) in [(0,0),(1,15),(1,16)] do
        let context := { checker.context with maxRecDepth := limit,recDepth := depth }
        let oldDefEq := psKernelIsDefEqWithFuel fuel
        compareWhnf (label ++ "-public")
          (psKernelWhnfWithRecursorFuel fuel oldDefEq context psKernelCheckerStateEmpty expr)
          (psKernelExprV2TryWhnfStateWithFuel fuel context initial root)
        publicCases := publicCases + 1
        for cheapProj in [false,true] do
          compareWhnf (label ++ "-core")
            (psKernelWhnfCoreWithRecursorFuel fuel oldDefEq context psKernelCheckerStateEmpty
              expr false cheapProj)
            (psKernelExprV2CheckWhnfCoreWithFuel fuel (psKernelExprV2CheckContextEmpty context)
              initial root cheapProj)
          coreCases := coreCases + 1
    for structuralFuel in [0,1,2,4,16] do
      for recursorFuel in [0,1,2,8] do
        for (limit,depth) in [(0,0),(1,15),(1,16)] do
          let context := { checker.context with maxRecDepth := limit,recDepth := depth }
          compareWhnf (label ++ "-fixed-owner")
            (psKernelWhnfWithFuel structuralFuel
              (psKernelReduceRecursorBoundedWithFuel recursorFuel (psKernelIsDefEqWithFuel 64))
              context psKernelCheckerStateEmpty expr)
            (psKernelExprV2TryWhnfStateWithReducerFuel structuralFuel
              (psKernelExprV2TryReduceRecursorWithLocalValuesFuel recursorFuel psKernelExprV2NoLocalValue)
              psKernelExprV2NoLocalValue context initial root)
          owners := owners + 1
    for fuel in [0,1,2,3,8,32] do
      compareReduction (label ++ "-reducer")
        (psKernelReduceRecursorBoundedWithFuel fuel (psKernelIsDefEqWithFuel 64)
          checker.context psKernelCheckerStateEmpty expr false false)
        (psKernelExprV2TryReduceRecursorWithLocalValuesFuel fuel psKernelExprV2NoLocalValue
          checker.context initial root false)
      reducers := reducers + 1
    let checked ← expectPublic (label ++ "-checked-V1-WHNF") (psKernelV1Whnf session [] .safe expr)
    require (label ++ "-checked-V1") (psKernelExprEq checked expected)
    let owned ← match psKernelExprV2TryWhnfStateWithFuel 4096 checker.context initial root with
      | some result => expect result
      | none => throw (IO.userError ("unexpected owned recursor fallback " ++ label))
    require (label ++ "-owned-complete-WHNF")
      (psKernelExprEq (← decode owned.fst.arena owned.snd) expected)
    let officialInput ← officialExpr expr
    require (label ++ "-official-check")
      (match Lean.Kernel.check official {} officialInput with | .ok _ => true | _ => false)
    require (label ++ "-official-defeq")
      (match Lean.Kernel.isDefEq official {} officialInput (← officialExpr expected) with
       | .ok true => true | _ => false)
  require "complete-resource-matrix"
    (publicCases == 252 && coreCases == 504 && owners == 720 && reducers == 72)

  let replay ← expectPublic "whole-batch-WHNF" (psKernelV1RunDag empty [] .safe input
    (prepared.commands ++ cases.map (fun (_,_,_,root) => .whnf root)))
  let answers := replay.replies.drop prepared.commands.length
  require "complete-public-batch-reply-count" (answers.length == cases.length)
  for (answer,(_,_,expected,_)) in answers.zip cases do
    require "complete-public-batch-decision"
      (match answer with | .normalized result => psKernelExprEq result expected | _ => false)
  let definition := PsKernelDagDeclarationRequest.definitionDecl
    (PsKernelDagDefinition.mk (PsKernelDagConstantBase.mk (nm "iotaChecked") [] natId)
      literalId .abbrevHint .safe)
  let admitted ← expectPublic "whole-batch-definition-check-defeq" (psKernelV1RunDag empty [] .safe input
    (prepared.commands ++ [.admit definition,.check literalId,.isDefEq literalId sevenId]))
  require "real-definition-and-defeq-batch"
    (match admitted.replies.reverse with | .equal true :: .checked _ :: .admitted _ :: _ => true | _ => false)
  let publicBad := PsKernelDagDeclarationRequest.definitionDecl
    (PsKernelDagDefinition.mk (PsKernelDagConstantBase.mk (nm "iotaWrong") [] literalId)
      literalId .abbrevHint .safe)
  require "bad-definition-batch-rejected"
    (rejectedInvalid (psKernelV1RunDag empty [] .safe input (prepared.commands ++ [.admit publicBad])))
  for (expr,root) in invalids.zip invalidRoots do
    require "invalid-recursor-V1" (rejectedInvalid (psKernelV1Whnf session [] .safe expr))
    require "invalid-recursor-public-DAG"
      (rejectedInvalid (psKernelV1RunDag empty [] .safe input (prepared.commands ++ [.whnf root])))
    require "invalid-recursor-official"
      (match Lean.Kernel.check official {} (← officialExpr expr) with | .error _ => true | _ => false)

  let privateId := input.size
  let privateHeader := PsKernelDagConstantBase.mk (nm "privateHeader") [] privateId
  let publicHeader := PsKernelDagConstantBase.mk (nm "privateBody") [] natId
  let privateDefinition := PsKernelDagDefinition.mk publicHeader privateId .abbrevHint .safe
  let privateCommands : List PsKernelDagCommand := [
    .check privateId,.whnf privateId,.isDefEq privateId natId,.isDefEq natId privateId,
    .admit (.axiomDecl privateHeader false),.admit (.definitionDecl privateDefinition),
    .admit (.theoremDecl publicHeader privateId),.admit (.opaqueDecl publicHeader privateId false),
    .admit (.mutualDefinitions [privateDefinition])]
  for command in privateCommands do
    require "private-generated-ID-never-public"
      (invalidReference (psKernelV1RunDag empty [] .safe input (prepared.commands ++ [command])))
    require "source-worker-private-ID-never-public"
      (invalidReference (psKernelDagRunCommandWithSource built
        (PsKernelDagExecutionState.mk session generated.declarations) [] .safe
        generated.arena generated.built command))
  require "sequential-error-before-private-ID"
    (match psKernelV1RunDag empty [] .safe input
        (prepared.commands ++ [.admit (.unsupported "IOTA_ORDER_SENTINEL"),.check privateId]) with
     | .error (.declinedUnsupported text) => text == "IOTA_ORDER_SENTINEL"
     | _ => false)
  require "failed-batch-does-not-publish-to-original-session"
    (psKernelEnvironmentFind empty.environment psKernelNatName).isNone
  let _ ← expectPublic "whole-batch-admission-replay"
    (psKernelV1RunDag empty [] .safe input prepared.commands)

  let badWhnf := fun (_ : PsKernelCheckerContext) (_ : PsKernelExprV2WhnfState) (_ : Nat) =>
    (some (.error "IOTA_MAJOR_CALLBACK") : Option (Except String (PsKernelExprV2WhnfState × Nat)))
  let missingWhnf := fun (_ : PsKernelCheckerContext) (_ : PsKernelExprV2WhnfState) (_ : Nat) =>
    (none : Option (Except String (PsKernelExprV2WhnfState × Nat)))
  let unowned := psKernelExprV2WhnfStateForDeclarations generated.arena prepared.declarations
  require "constructor-major-does-not-call-WHNF"
    (match psKernelExprV2TryReduceInductiveRecursor badWhnf checker.context initial constructorId with
     | some (.ok result) => result.snd.isSome | _ => false)
  require "literal-major-calls-WHNF-before-conversion"
    (match psKernelExprV2TryReduceInductiveRecursor badWhnf checker.context initial literalId with
     | some (.error error) => error == "IOTA_MAJOR_CALLBACK" | _ => false)
  require "literal-major-unsupported-callback-preserved"
    (psKernelExprV2TryReduceInductiveRecursor missingWhnf checker.context initial literalId).isNone
  require "missing-rule-owner-explicit-fallback"
    (psKernelExprV2TryReduceInductiveRecursor badWhnf checker.context unowned constructorId).isNone
  for root in [shortId,missingFieldId,noRuleId,wrongLevelsId] do
    require "inert-before-owner-and-callback"
      (match psKernelExprV2TryReduceInductiveRecursor badWhnf checker.context unowned root with
       | some (.ok result) => result.snd.isNone && result.fst.arena.size == generated.arena.size
       | _ => false)
  require "K-conversion-never-uses-temporary-checker"
    (psKernelExprV2TryReduceInductiveRecursor badWhnf checker.context initial kId).isNone
  require "zero-recursor-budget-before-invalid-root"
    (match psKernelExprV2TryReduceRecursorWithLocalValuesFuel 0 psKernelExprV2NoLocalValue
        checker.context initial (generated.arena.size + 1) false with
     | some (.error error) => error == "kernel recursor budget exhausted" | _ => false)
  require "literal-major-retains-predecessor-zero-budget"
    (match psKernelExprV2TryReduceRecursorWithLocalValuesFuel 1 psKernelExprV2NoLocalValue
        checker.context initial literalId false with
     | some (.error error) => error == "kernel reduction budget exhausted" | _ => false)
  require "constructor-major-does-not-spend-predecessor-WHNF-budget"
    (match psKernelExprV2TryReduceRecursorWithLocalValuesFuel 1 psKernelExprV2NoLocalValue
        checker.context initial constructorId false with
     | some (.ok result) => result.snd.isSome | _ => false)
  let markWhnf := fun (_ : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState) (root : Nat) =>
    match psKernelExprV2PagedRequire state.arena root with
    | .error error => some (.error error)
    | .ok entry => some (.ok
        (PsKernelExprV2WhnfState.mk state.arena state.coreCache
          [PsKernelExprV2WhnfCacheEntry.mk root root entry.hash] state.declarations,root))
  require "callback-state-survives-normalization-and-rule"
    (match psKernelExprV2TryReduceInductiveRecursor markWhnf checker.context initial literalId with
     | some (.ok result) => result.snd.isSome && result.fst.publicCache.length == 1
     | _ => false)
  let warm ← match psKernelExprV2TryWhnfStateWithFuel 4096 checker.context initial constructorId with
    | some result => expect result
    | none => throw (IO.userError "owned recursor warm fallback")
  require "warm-cache-resource-guard-preserved"
    (match psKernelExprV2TryWhnfStateWithFuel 0 checker.context warm.fst constructorId with
     | some (.error error) => error == "kernel reduction budget exhausted" | _ => false)

  for (label,type,value,shouldAccept) in
      [("officialNatIota",nat,natRec (lit 3),true),
       ("officialBoxIota",nat,boxRec (lam "box" box nat) (lam "a" nat (.bvar 0)),true),
       ("officialBadIota",s1,natRec (lit 0),false)] do
    let result := official.addDeclCore 0 0 (.defnDecl {
      name := inferOfficialName (nm label)
      levelParams := []
      type := ← officialExpr type
      value := ← officialExpr value
      hints := .abbrev
      safety := .safe
    }) none true
    require (label ++ "-checked-addDecl")
      (match result with | .ok _ => shouldAccept | .error _ => !shouldAccept)
    let own := psKernelV1AdmitDeclaration session (.definitionDecl
      (PsKernelDefinitionInfo.mk (PsKernelConstantBase.mk (nm label) [] type) value .abbrevHint .safe))
    require (label ++ "-independent-addDecl")
      (match own with | .ok _ => shouldAccept | .error (.rejectedInvalid _) => !shouldAccept | _ => false)
  -- Preserve the old Sort-u fixture as explicit public rejection controls.
  let restrictedName := nm "IotaSortBox"
  let restrictedCtor := PsKernelName.str restrictedName "mk"
  let restrictedRec := psKernelSimpleRecName restrictedName
  let restrictedType := forallE "A" (.sort (.param u)) (.sort (.param u))
  let restrictedCtorType := forallE "A" (.sort (.param u))
    (forallE "value" (.bvar 0) (apply (.const restrictedName [.param u]) [.bvar 1]))
  let restrictedDecl := PsKernelSimpleInductiveDecl.mk [u] restrictedName restrictedType
    [PsKernelSimpleConstructorDecl.mk restrictedCtor restrictedCtorType] false 1
  let restricted ← prepareInductive "IotaSortBox"
    (Prepared.mk session input [] []) restrictedDecl
  let restrictedInfo ← recursorInfo restricted.session restrictedRec
  require "Sort-u-box-has-Prop-only-recursor"
    (restrictedInfo.base.levelParams.length == 1)
  let restrictedOfficial ← officialInductive official restrictedDecl
  let restrictedBox := apply (.const restrictedName [one]) [nat]
  let restrictedMajor := apply (.const restrictedCtor [one]) [nat,lit 5]
  let restrictedArgs := [nat,lam "box" restrictedBox nat,lam "a" nat (.bvar 0),restrictedMajor]
  for (label,levels,message) in
      [("wrong-universe-arity",[one,one],"incorrect number of universe levels"),
       ("forbidden-data-elimination",[one],"application type mismatch")] do
    let expr := apply (.const restrictedRec levels) restrictedArgs
    let (negativeInput,root) ← expect (psKernelExprV2PagedImportIntoChecked restricted.arena expr)
    require ("Sort-u-" ++ label ++ "-V1")
      (match psKernelV1Whnf restricted.session [] .safe expr with
       | .error (.rejectedInvalid actual) => actual == message
       | _ => false)
    require ("Sort-u-" ++ label ++ "-public-DAG")
      (match psKernelV1RunDag empty [] .safe negativeInput
          (prepared.commands ++ restricted.commands ++ [.whnf root]) with
       | .error (.rejectedInvalid actual) => actual == message
       | _ => false)
    require ("Sort-u-" ++ label ++ "-official")
      (match Lean.Kernel.check restrictedOfficial {} (← officialExpr expr) with
       | .error _ => true | _ => false)
  majorRegression prepared official natInfo boxInfo
  IO.println "PSC1_V2_DAG_RECURSOR_UNIVERSE_NEGATIVES: PASS cases=2"
  IO.println "PSC1_V2_DAG_RECURSOR: PASS public=252 core=504 owners=720 reducer=72 privateIDs=9"
  IO.println "PSC1_V2_DAG_OFFICIAL_RECURSOR: PASS valid=12 invalid=4 addDecl=3"

def main : IO Unit := regression
