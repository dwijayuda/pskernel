import Ps.KernelCore.API.Dag
import Ps.KernelCore.Checker.ExprV2.Knot
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

/- Real declarations are admitted by both independent kernels. The callback
probes below use unreachable diagnostic cache hashes, never checked judgments.
No probe result or forged owner is published through the checked API. -/

private def require (label : String) (condition : Bool) : IO Unit := do
  unless condition do throw (IO.userError ("PSC1_V2_K_FAIL " ++ label))

private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def expectPublic {α : Type} : Except PsKernelError α → IO α
  | .ok value => pure value
  | .error _ => throw (IO.userError "checked K fixture failed")

private def attempt {α : Type} (label : String) : Option (Except String α) → IO α
  | some value => expect value
  | none => throw (IO.userError ("unexpected K fallback: " ++ label))

private def nm (text : String) := PsKernelName.str .anonymous text
private def one := PsKernelLevel.succ PsKernelLevel.zero
private def nat := PsKernelExpr.const psKernelNatName []
private def lit (value : Nat) := PsKernelExpr.lit (.nat value)
private def lam (name : String) (type body : PsKernelExpr) :=
  PsKernelExpr.lam (nm name) type body .default
private def all (name : String) (type body : PsKernelExpr) :=
  PsKernelExpr.forallE (nm name) type body .default
private def apps (head : PsKernelExpr) (args : List PsKernelExpr) := psKernelApplyArgs head args
private def unitName := nm "KUnit"
private def unitCtor := PsKernelName.str unitName "mk"
private def unitType := PsKernelExpr.const unitName []
private def eqName := nm "KEquality"
private def eqCtor := PsKernelName.str eqName "refl"
private def eqType (level : PsKernelLevel) (a x y : PsKernelExpr) :=
  apps (.const eqName [level]) [a,x,y]
private def natDecl := PsKernelSimpleInductiveDecl.mk [] psKernelNatName (.sort one)
  [PsKernelSimpleConstructorDecl.mk psKernelNatZeroName nat,
   PsKernelSimpleConstructorDecl.mk psKernelNatSuccName (all "n" nat nat)] false 0
private def unitDecl := PsKernelSimpleInductiveDecl.mk [] unitName (.sort .zero)
  [PsKernelSimpleConstructorDecl.mk unitCtor unitType] false 0
private def equalityDecl :=
  let u := PsKernelLevel.param (nm "u")
  PsKernelSimpleInductiveDecl.mk [nm "u"] eqName
    (all "A" (.sort u) (all "a" (.bvar 0) (all "b" (.bvar 1) (.sort .zero))))
    [PsKernelSimpleConstructorDecl.mk eqCtor
      (all "A" (.sort u) (all "a" (.bvar 0)
        (eqType u (.bvar 1) (.bvar 0) (.bvar 0))))] false 2

private structure Fixture where
  session : PsKernelKernelSession
  arena : PsKernelExprV2PagedArena
  commands : List PsKernelDagCommand
  declarations : List PsKernelExprV2DeclarationRef

private def addInductive (prior : Fixture) (decl : PsKernelSimpleInductiveDecl) : IO Fixture := do
  let admitted ← expectPublic (psKernelV1AdmitDeclaration prior.session (.ordinaryInductive decl))
  let (arena,type) ← expect (psKernelExprV2PagedImportIntoChecked prior.arena decl.type)
  let mut arena := arena
  let mut ctors := []
  for ctor in decl.ctors do
    let (next,root) ← expect (psKernelExprV2PagedImportIntoChecked arena ctor.type)
    arena := next
    ctors := ctors ++ [PsKernelDagConstructor.mk ctor.name root]
  let request := PsKernelDagDeclarationRequest.ordinaryInductive decl.levelParams decl.numParams
    (PsKernelDagInductive.mk decl.name type ctors) decl.isUnsafe
  pure (Fixture.mk admitted.session arena (prior.commands ++ [.admit request])
    (psKernelDagDeclarationsAfterAdmission request prior.declarations))

private def addTheorem (prior : Fixture) (name : PsKernelName)
    (type value : PsKernelExpr) : IO Fixture := do
  let info := PsKernelTheoremInfo.mk (PsKernelConstantBase.mk name [] type) value
  let admitted ← expectPublic (psKernelV1AdmitDeclaration prior.session (.theoremDecl info))
  let (arena,typeId) ← expect (psKernelExprV2PagedImportIntoChecked prior.arena type)
  let (arena,valueId) ← expect (psKernelExprV2PagedImportIntoChecked arena value)
  let request := PsKernelDagDeclarationRequest.theoremDecl
    (PsKernelDagConstantBase.mk name [] typeId) valueId
  pure (Fixture.mk admitted.session arena (prior.commands ++ [.admit request])
    (psKernelDagDeclarationsAfterAdmission request prior.declarations))

private def recInfo (session : PsKernelKernelSession) (name : PsKernelName) :
    IO PsKernelRecursorInfo := do
  match psKernelEnvironmentFind session.environment (psKernelSimpleRecName name) with
  | some (.recInfo value) => pure value
  | _ => throw (IO.userError "missing actually generated K metadata")

private def decode (state : PsKernelExprV2CheckState) (root : Nat) : IO PsKernelExpr := do
  let built ← expect (psKernelExprV2DecodeChecked state.whnf.arena)
  expect (psKernelExprV2DecodedRequire built root)

private def compareWhnf (label : String)
    (old : Except String (PsKernelExpr × PsKernelCheckerState))
    (actual : Option (Except String (PsKernelExprV2CheckState × Nat))) : IO Unit := do
  match old,actual with
  | .error left,some (.error right) => require (label ++ "-error") (left == right)
  | .ok left,some (.ok right) =>
      require (label ++ "-term") (psKernelExprEqual left.fst (← decode right.fst right.snd))
  | _,none => throw (IO.userError ("unexpected differential K fallback " ++ label))
  | _,_ => throw (IO.userError ("K result class differs " ++ label))

private def compareReduction (label : String)
    (old : Except String (Option PsKernelExpr × PsKernelCheckerState))
    (actual : Option (Except String (PsKernelExprV2CheckState × Option Nat))) : IO Unit := do
  match old,actual with
  | .error left,some (.error right) => require (label ++ "-error") (left == right)
  | .ok left,some (.ok right) =>
      match left.fst,right.snd with
      | none,none => pure ()
      | some l,some r => require (label ++ "-term") (psKernelExprEqual l (← decode right.fst r))
      | _,_ => throw (IO.userError ("K reduction option differs " ++ label))
  | _,none => throw (IO.userError ("unexpected reducer K fallback " ++ label))
  | _,_ => throw (IO.userError ("K reducer class differs " ++ label))


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


private def matrices (scalar : PsKernelCheckerContext) (state : PsKernelExprV2CheckState)
    (valid invalid : List (String × PsKernelExpr × Nat)) : IO Unit := do
  let mut publicCount := 0
  let mut coreCount := 0
  let mut reducerCount := 0
  for (label,term,root) in valid do
    for fuel in [0,1,2,3,8,64] do
      for (limit,depth) in [(0,0),(1,15),(1,16)] do
        let limited := { scalar with maxRecDepth := limit,recDepth := depth }
        let context := psKernelExprV2CheckContextEmpty limited
        let oldEq := psKernelIsDefEqWithFuel fuel
        let dagEq := psKernelExprV2TryDefEqStateWithFuel fuel
        compareWhnf (label ++ "-public")
          (psKernelWhnfWithRecursorFuel fuel oldEq limited psKernelCheckerStateEmpty term)
          (psKernelExprV2TryWhnfCheckStateWithFuel fuel context state root)
        publicCount := publicCount + 1
        for cheapRec in [false,true] do
          for cheapProj in [false,true] do
            compareWhnf (label ++ "-core")
              (psKernelWhnfCoreWithRecursorFuel fuel oldEq limited psKernelCheckerStateEmpty term cheapRec cheapProj)
              (psKernelExprV2TryWhnfCoreOwnedWithLocalValuesFuel fuel dagEq
                psKernelExprV2CheckLocalValue context state root cheapRec cheapProj)
            coreCount := coreCount + 1
  for (label,term,root) in valid ++ invalid do
    for fuel in [0,1,2,3,8,64] do
      for (limit,depth) in [(0,0),(1,15),(1,16)] do
        let limited := { scalar with maxRecDepth := limit,recDepth := depth }
        let context := psKernelExprV2CheckContextEmpty limited
        for cheapRec in [false,true] do
          for cheapProj in [false,true] do
            compareReduction (label ++ "-reducer")
              (psKernelReduceRecursorBoundedWithFuel fuel (psKernelIsDefEqWithFuel 64)
                limited psKernelCheckerStateEmpty term cheapRec cheapProj)
              (psKernelExprV2TryReduceRecursorOwnedWithFuel fuel (psKernelExprV2TryDefEqStateWithFuel 64)
                psKernelExprV2CheckLocalValue context state root cheapRec cheapProj)
            reducerCount := reducerCount + 1
  require "matrix-counts" (publicCount == 108 && coreCount == 432 && reducerCount == 648)
  IO.println "PSC1_V2_K_MATRIX_PASS public=108 core=432 reducer=648"

private def fixedOwners (scalar : PsKernelCheckerContext) (state : PsKernelExprV2CheckState)
    (valid : List (String × PsKernelExpr × Nat)) : IO Unit := do
  let context := psKernelExprV2CheckContextEmpty scalar
  let mut count := 0
  for (label,term,root) in valid do
    for structural in [0,1,2,8] do
      for owner in [0,1,2,8] do
        compareWhnf (label ++ "-fixed-owner")
          (psKernelWhnfWithFuel structural
            (psKernelReduceRecursorBoundedWithFuel owner (psKernelIsDefEqWithFuel 64))
            scalar psKernelCheckerStateEmpty term)
          (psKernelExprV2TryWhnfOwnedWithReducerFuel structural
            (psKernelExprV2TryReduceRecursorOwnedWithFuel owner (psKernelExprV2TryDefEqStateWithFuel 64)
              psKernelExprV2CheckLocalValue)
            psKernelExprV2CheckLocalValue context state root)
        count := count + 1
  require "fixed-owner-count" (count == 96)
  IO.println "PSC1_V2_K_FIXED_OWNER_PASS cases=96"

private def cacheMark (cache : PsKernelExprV2WhnfCache) (mark : Nat) : Bool :=
  match psKernelExprV2WhnfCacheEntries cache with | [row] => row.hash == psKernelCacheHashModulus + mark | _ => false
private def pairMark (rows : List PsKernelExprV2DefEqPair) (mark : Nat) : Bool :=
  match rows with | [row] => row.hash == psKernelCacheHashModulus + mark | _ => false
private def arenaMark (state : PsKernelExprV2CheckState) (mark : Nat) : Bool :=
  match psKernelExprV2WhnfCacheEntries state.whnf.coreCache with
  | [row] =>
      match psKernelExprV2PagedRequire state.whnf.arena row.result with
      | .ok entry =>
          match entry.node with | .lit (.nat value) => value == 9000 + mark | _ => false
      | .error _ => false
  | _ => false
private def marked (state : PsKernelExprV2CheckState) (mark : Nat) : Bool :=
  state.nextFresh == mark && arenaMark state mark && cacheMark state.whnf.coreCache mark &&
    cacheMark state.whnf.publicCache mark && cacheMark state.checkedInfer mark &&
    cacheMark state.inferOnly mark && cacheMark state.unfold mark &&
    pairMark state.success mark && pairMark state.failure mark
private def stamp (key mark : Nat) (state : PsKernelExprV2CheckState) :
    Except String PsKernelExprV2CheckState := do
  let (arena,marker) ← psKernelExprV2PagedMkLit state.whnf.arena (.nat (9000 + mark))
  let cache := PsKernelExprV2WhnfCacheEntry.mk key marker (psKernelCacheHashModulus + mark)
  let pair := PsKernelExprV2DefEqPair.mk key key (psKernelCacheHashModulus + mark)
  let entries := psKernelExprV2WhnfCacheFromList [cache]
  pure (PsKernelExprV2CheckState.mk
    (PsKernelExprV2WhnfState.mk arena entries entries state.whnf.declarations)
    mark entries [pair] entries entries [pair])

private def probeStep (key seed stage failAt : Nat) (decline : Bool)
    (state : PsKernelExprV2CheckState) :
    Option (Except String PsKernelExprV2CheckState) :=
  if marked state (seed + stage - 1) then
    if stage == failAt then
      if decline then none else some (.error "K_CALLBACK_SENTINEL")
    else some (stamp key (seed + stage) state)
  else some (.error "K_CALLBACK_STATE_OR_ORDER")

private def withRoot (value : Option (Except String PsKernelExprV2CheckState)) (root : Nat) :
    Option (Except String (PsKernelExprV2CheckState × Nat)) :=
  value.map (fun result => result.map (fun state => (state,root)))

private def runProbe (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (info : PsKernelRecursorInfo) (major appType candidateType seed failAt : Nat)
    (decline equal : Bool) :
    Option (Except String (PsKernelExprV2CheckState × Nat)) :=
  let infer := fun (_ : PsKernelExprV2CheckContext) (next : PsKernelExprV2CheckState) (root : Nat) =>
    if next.nextFresh == seed then
      if root == major then withRoot (probeStep major seed 1 failAt decline next) appType
      else some (.error "K_INITIAL_MAJOR")
    else if root == major then some (.error "K_CANDIDATE_NOT_CONSTRUCTED")
    else withRoot (probeStep major seed 3 failAt decline next) candidateType
  let whnf := fun (_ : PsKernelExprV2CheckContext) (next : PsKernelExprV2CheckState) (root : Nat) =>
    if root == appType then withRoot (probeStep major seed 2 failAt decline next) appType
    else some (.error "K_TYPE_WHNF_ORDER")
  let defeq := fun (_ : PsKernelExprV2CheckContext) (next : PsKernelExprV2CheckState) (left right : Nat) =>
    if left == appType && right == candidateType then
      (probeStep major seed 4 failAt decline next).map (fun result =>
        result.map (fun updated => (updated,equal)))
    else some (.error "K_DEFEQ_ARGUMENT_ORDER")
  match stamp major seed state with
  | .error error => some (.error error)
  | .ok seeded => psKernelExprV2RecursorKForFamilyOwnedWith whnf infer defeq context
      seeded info eqName major


private def carrierProbes (context : PsKernelExprV2CheckContext)
    (initial : PsKernelExprV2CheckState) (info : PsKernelRecursorInfo) (major : Nat) : IO Unit := do
  let standard := eqType one nat (lit 0) (lit 0)
  let cases : List (String × PsKernelExpr × Bool × Nat × Option PsKernelExpr) := [
    ("true",standard,true,4,some (apps (.const eqCtor [one]) [nat,lit 0])),
    ("false",standard,false,4,none),
    ("parameter-mvar",eqType one (.mvar (nm "A")) (lit 0) (lit 0),true,4,
      some (apps (.const eqCtor [one]) [.mvar (nm "A"),lit 0])),
    ("universe-mvar",eqType (.mvar (nm "u")) nat (lit 0) (lit 0),true,4,
      some (apps (.const eqCtor [.mvar (nm "u")]) [nat,lit 0])),
    ("index-mvar",eqType one nat (lit 0) (.mdata 7 (.mvar (nm "index"))),true,2,none),
    ("wrong-family",nat,true,2,none),
    ("short-params",apps (.const eqName [one]) [nat],true,2,none),
    ("nonconstant-family",.sort .zero,true,2,none)]
  let mut owners := 0
  let mut propagated := 0
  for (label,type,equal,steps,expected) in cases do
    let (arena,typeId) ← expect (psKernelExprV2PagedImportIntoChecked initial.whnf.arena type)
    let (arena,candidateType) ← expect (psKernelExprV2PagedMkMData arena 77 typeId)
    let state := psKernelExprV2CheckStateWithArena initial arena
    let entry ← expect (psKernelExprV2PagedRequire arena typeId)
    require (label ++ "-validated-mvar-correspondence")
      (entry.hasExprMVar == psKernelExprHasMVarForK type)
    let (_,args) ← expect (psKernelExprV2TransformAppSpineOnCanonical arena typeId)
    let hasIndex ← expect (psKernelExprV2RecursorKIndicesHaveMVar arena
      (psKernelExprV2QuotDrop info.numParams args))
    require (label ++ "-index-mvar-correspondence")
      (hasIndex == psKernelExprListAnyMVar
        (psKernelExprListDrop info.numParams (psKernelExprGetAppArgs type)))
    for seed in [2,11] do
      let result ← attempt label (runProbe context state info major typeId candidateType seed 0 false equal)
      require (label ++ "-complete-owner") (marked result.fst (seed + steps))
      require (label ++ "-private-owner-retained")
        (psKernelExprV2DeclarationRefFind result.fst.whnf.declarations info.base.name).isSome
      match expected with
      | some term =>
          require (label ++ "-candidate-levels-params")
            (psKernelExprEqual term (← decode result.fst result.snd))
      | none => require (label ++ "-original-major") (result.snd == major)
      let _ ← expect (psKernelExprV2PagedValidate result.fst.whnf.arena)
      owners := owners + 1
  let (arena,typeId) ← expect (psKernelExprV2PagedImportIntoChecked initial.whnf.arena standard)
  let (arena,candidateType) ← expect (psKernelExprV2PagedMkMData arena 88 typeId)
  let state := psKernelExprV2CheckStateWithArena initial arena
  for seed in [2,11] do
    for failAt in [1,2,3,4] do
      for decline in [false,true] do
        match runProbe context state info major typeId candidateType seed failAt decline true with
        | none => require "None-is-unsupported" decline
        | some (.error error) =>
            require "exact-callback-failure"
              (!decline && error == "K_CALLBACK_SENTINEL")
        | some (.ok _) => throw (IO.userError "failed K callback accepted")
        propagated := propagated + 1
  require "K-owner-counts" (owners == 16 && propagated == 16)
  IO.println "PSC1_V2_K_OWNER_PASS carrier=16 propagated=16 metadata=16"

private def ordering (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (kRoot natRoot badLevels : Nat) : IO Unit := do
  let reducer := psKernelExprV2TryReduceRecursorOwnedWithFuel 1
    (psKernelExprV2TryDefEqStateWithFuel 64) psKernelExprV2CheckLocalValue
  for root in [kRoot,badLevels] do
    require "K-infers-before-constructor-or-rule-level-check"
      (match reducer context state root false false with
       | some (.error error) => error == "kernel inference budget exhausted"
       | _ => false)
  require "non-K-constructor-keeps-zero-predecessor-shortcut"
    (match reducer context state natRoot false false with
     | some (.ok (_,some _)) => true | _ => false)
  let unowned := psKernelExprV2CheckStateWithWhnf state
    (psKernelExprV2WhnfStateForDeclarations state.whnf.arena [])
  require "missing-K-owner-explicit-unsupported"
    (reducer context unowned kRoot false false).isNone
  require "zero-recursor-before-invalid-root"
    (match psKernelExprV2TryReduceRecursorOwnedWithFuel 0
        (psKernelExprV2TryDefEqStateWithFuel 64) psKernelExprV2CheckLocalValue
        context state (state.whnf.arena.size + 1) false false with
     | some (.error error) => error == "kernel recursor budget exhausted" | _ => false)
  IO.println "PSC1_V2_K_ORDER_PASS guards=5"

private def officialProof (environment : Lean.Environment) (name : PsKernelName)
    (type value : PsKernelExpr) : IO Lean.Environment := do
  let type ← officialExpr type
  let value ← officialExpr value
  match environment.addDeclCore 0 0 (.thmDecl {
      name := inferOfficialName name,levelParams := [],type := type,value := value }) none true with
  | .ok next => pure next
  | .error _ => throw (IO.userError "official K proof fixture failed")


private def unitProofName := nm "KUnitProof"
private def equalityProofName := nm "KEqualityProof"
private def equalityType := eqType one nat (lit 0) (lit 0)
private def equalityValue := apps (.const eqCtor [one]) [nat,lit 0]
private def unitRec (levels : List PsKernelLevel) (major : PsKernelExpr) :=
  apps (.const (psKernelSimpleRecName unitName) levels)
    [lam "h" unitType nat,lit 7,major]
private def equalityRec (major : PsKernelExpr) :=
  apps (.const (psKernelSimpleRecName eqName) [one,one])
    [nat,lit 0,lam "b" nat (lam "h" (eqType one nat (lit 0) (.bvar 0)) nat),
     lit 7,lit 0,major]

private structure Ready where
  empty : PsKernelKernelSession
  prepared : Fixture
  input : PsKernelExprV2PagedArena
  scalar : PsKernelCheckerContext
  state : PsKernelExprV2CheckState
  valid : List (String × PsKernelExpr × Nat)
  invalid : List (String × PsKernelExpr × Nat)
  major : Nat
  kRoot : Nat
  natRoot : Nat
  badLevels : Nat
  natId : Nat
  sortId : Nat
  sevenId : Nat

private def prepare : IO Ready := do
  let empty ← expectPublic (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let first ← addInductive (Fixture.mk empty psKernelExprV2PagedEmpty [] []) natDecl
  let second ← addInductive first unitDecl
  let third ← addInductive second equalityDecl
  let fourth ← addTheorem third unitProofName unitType (.const unitCtor [])
  let prepared ← addTheorem fourth equalityProofName equalityType equalityValue
  let unitInfo ← recInfo prepared.session unitName
  let equalityInfo ← recInfo prepared.session eqName
  require "real-K-checked-metadata" (unitInfo.k && equalityInfo.k &&
    unitInfo.base.levelParams.length == 1 && equalityInfo.base.levelParams.length == 2 &&
    equalityInfo.numParams == 2 && equalityInfo.numIndices == 1)
  let unitMajor := PsKernelExpr.const unitProofName []
  let equalityMajor := PsKernelExpr.const equalityProofName []
  let fixtures : List (String × PsKernelExpr) := [
    ("unit-constructor",unitRec [one] (.const unitCtor [])),
    ("unit-theorem",unitRec [one] unitMajor),
    ("unit-beta",unitRec [one] (.app (lam "h" unitType (.bvar 0)) unitMajor)),
    ("unit-zeta",unitRec [one] (.letE (nm "h") unitType unitMajor (.bvar 0) false)),
    ("equality-constructor",equalityRec equalityValue),
    ("equality-theorem",equalityRec equalityMajor)]
  let negatives : List (String × PsKernelExpr) := [
    ("missing-level",unitRec [] (.const unitCtor [])),
    ("extra-level",unitRec [one,one] (.const unitCtor [])),
    ("wrong-major",unitRec [one] (lit 0))]
  let mut input := prepared.arena
  let mut valid := []
  let mut invalid := []
  for (label,term) in fixtures do
    let (next,root) ← expect (psKernelExprV2PagedImportIntoChecked input term)
    input := next
    valid := valid ++ [(label,term,root)]
  for (label,term) in negatives do
    let (next,root) ← expect (psKernelExprV2PagedImportIntoChecked input term)
    input := next
    invalid := invalid ++ [(label,term,root)]
  let (a,major) ← expect (psKernelExprV2PagedImportIntoChecked input equalityMajor)
  let (a,kRoot) ← expect (psKernelExprV2PagedImportIntoChecked a (unitRec [one] (.const unitCtor [])))
  let (a,badLevels) ← expect (psKernelExprV2PagedImportIntoChecked a (unitRec [] (.const unitCtor [])))
  let natRec := apps (.const (psKernelSimpleRecName psKernelNatName) [one])
    [lam "n" nat nat,lit 7,lam "n" nat (lam "ih" nat (.bvar 0)),
     .const psKernelNatZeroName []]
  let (a,natRoot) ← expect (psKernelExprV2PagedImportIntoChecked a natRec)
  let (a,natId) ← expect (psKernelExprV2PagedImportIntoChecked a nat)
  let (a,sortId) ← expect (psKernelExprV2PagedImportIntoChecked a (.sort one))
  let (a,sevenId) ← expect (psKernelExprV2PagedImportIntoChecked a (lit 7))
  input := a
  let built ← expect (psKernelExprV2DecodeChecked input)
  let mut generated := PsKernelDagGeneratedState.mk input built prepared.declarations
  for command in prepared.commands do
    generated ← expect (psKernelDagGeneratedAfterCommand command prepared.session.environment generated)
  let _ ← expect (psKernelExprV2PagedValidate generated.arena)
  let state := psKernelExprV2CheckStateWithWhnf
    (psKernelExprV2CheckStateEmpty generated.arena)
    (psKernelExprV2WhnfStateForDeclarations generated.arena generated.declarations)
  for info in [unitInfo,equalityInfo] do
    let some owner := psKernelExprV2DeclarationRefFind generated.declarations info.base.name
      | throw (IO.userError "missing checked K recursor owner")
    require "K-owner-exact-type" (psKernelExprEqual info.base.type (← decode state owner.type))
    require "K-owner-matches-authority" (psKernelExprV2DeclarationRefMatches owner (.recInfo info))
    for rule in info.rules do
      let some rhs := psKernelExprV2RecursorRuleOwner generated.declarations info rule
        | throw (IO.userError "missing checked K rule owner")
      require "K-owner-exact-rule" (psKernelExprEqual rule.rhs (← decode state rhs))
  let scalar := (psKernelKernelSessionChecker prepared.session [] .safe).context
  pure (Ready.mk empty prepared input scalar state valid invalid major kRoot natRoot badLevels
    natId sortId sevenId)

private def rejected {α : Type} : Except PsKernelError α → Bool
  | .error (.rejectedInvalid _) => true
  | _ => false

private def directAdmission (ready : Ready) (source : PsKernelDagDeclarationRequest)
    (shouldAccept : Bool) : IO Unit := do
  let built ← expect (psKernelExprV2DecodeChecked ready.input)
  let declaration ← expect (psKernelDagDecodeDeclaration built source)
  let .definitionDecl value := declaration
    | throw (IO.userError "K direct fixture is not a definition")
  let session := ready.prepared.session
  let observed := psKernelDagTryAdmitSimpleWithFuel session.resources.fuel
    (psKernelKernelSessionEnvironment session)
    session.resources.maxRecDepth session.resources.maxNatSize
    ready.state.whnf.arena ready.state.whnf.declarations source declaration
  match psKernelV1AdmitDeclaration session declaration,observed with
  | .ok original,some (.ok environment) =>
      require "K-direct-positive-decision" shouldAccept
      match psKernelEnvironmentFind environment value.base.name,
          psKernelEnvironmentFind original.session.environment value.base.name with
      | some (.defnInfo actual),some (.defnInfo expected) =>
          require "K-direct-published-definition"
            (psKernelExprEqual actual.base.type expected.base.type &&
              psKernelExprEqual actual.value expected.value &&
              psKernelNameListsEq actual.base.levelParams expected.base.levelParams &&
              psKernelDefinitionSafetyIsSafe actual.safety)
      | _,_ => throw (IO.userError "K direct admission did not publish the checked definition")
  | .error (.rejectedInvalid expected),some (.error actual) =>
      require "K-direct-invalid-exact-message" (!shouldAccept && actual == expected)
  | _,none => throw (IO.userError "K direct admission unexpectedly fell back")
  | _,_ => throw (IO.userError "K direct admission outcome differs from V1")

private def checked (ready : Ready) : IO Unit := do
  let context := psKernelExprV2CheckContextEmpty ready.scalar
  for (label,term,root) in ready.valid do
    let old ← expectPublic (psKernelV1Whnf ready.prepared.session [] .safe term)
    require (label ++ "-real-V1") (psKernelExprEqual old (lit 7))
    let owned ← attempt label
      (psKernelExprV2TryWhnfCheckStateWithFuel 4096 context ready.state root)
    require (label ++ "-real-full-owner") (psKernelExprEqual (← decode owned.fst owned.snd) (lit 7))
  let result ← expectPublic (psKernelV1RunDag ready.empty [] .safe ready.input
    (ready.prepared.commands ++ ready.valid.map (fun (_,_,root) => .whnf root)))
  let answers := result.replies.drop ready.prepared.commands.length
  require "real-K-batch-count" (answers.length == 6)
  for answer in answers do
    require "real-K-batch-result"
      (match answer with | .normalized value => psKernelExprEqual value (lit 7) | _ => false)
  for (_,term,root) in ready.invalid do
    require "real-invalid-V1" (rejected (psKernelV1Whnf ready.prepared.session [] .safe term))
    require "real-invalid-public-DAG" (rejected (psKernelV1RunDag ready.empty [] .safe ready.input
      (ready.prepared.commands ++ [.whnf root])))
  let good := PsKernelDagDeclarationRequest.definitionDecl (PsKernelDagDefinition.mk
    (PsKernelDagConstantBase.mk (nm "KChecked") [] ready.natId) ready.kRoot .abbrevHint .safe)
  let goodResult ← expectPublic (psKernelV1RunDag ready.empty [] .safe ready.input
    (ready.prepared.commands ++ [.admit good,.check ready.kRoot,.isDefEq ready.kRoot ready.sevenId]))
  require "real-K-admission-check-defeq" (match goodResult.replies.reverse with
    | .equal true :: .checked _ :: .admitted _ :: _ => true | _ => false)
  let bad := PsKernelDagDeclarationRequest.definitionDecl (PsKernelDagDefinition.mk
    (PsKernelDagConstantBase.mk (nm "KRejected") [] ready.sortId) ready.kRoot .abbrevHint .safe)
  require "real-K-bad-definition" (rejected (psKernelV1RunDag ready.empty [] .safe ready.input
    (ready.prepared.commands ++ [.admit bad])))
  require "K-batch-does-not-mutate-original-session"
    (psKernelEnvironmentFind ready.empty.environment unitName).isNone
  directAdmission ready good true
  directAdmission ready bad false
  IO.println "PSC1_V2_K_DIRECT_ADMISSION_PASS cases=2"
  IO.println "PSC1_V2_K_CHECKED_PASS valid=6 invalid=3 declarations=2 batch=6"

private def official (ready : Ready) : IO Unit := do
  Lean.initSearchPath (← Lean.findSysroot)
  let first ← Lean.importModules #[{ module := `Init }] {}
  let second ← officialInductive first unitDecl
  let third ← officialInductive second equalityDecl
  let fourth ← officialProof third unitProofName unitType (.const unitCtor [])
  let environment ← officialProof fourth equalityProofName equalityType equalityValue
  for (label,term,_) in ready.valid do
    let term ← officialExpr term
    require (label ++ "-official-check")
      (match Lean.Kernel.check environment {} term with | .ok _ => true | _ => false)
    require (label ++ "-official-reduction")
      (match Lean.Kernel.isDefEq environment {} term (← officialExpr (lit 7)) with
       | .ok true => true | _ => false)
  for (label,term,_) in ready.invalid do
    require (label ++ "-official-negative")
      (match Lean.Kernel.check environment {} (← officialExpr term) with | .error _ => true | _ => false)
  for (name,type,shouldAccept) in [("KChecked",nat,true),("KRejected",PsKernelExpr.sort one,false)] do
    let result := environment.addDeclCore 0 0 (.defnDecl {
      name := inferOfficialName (nm name),levelParams := [],type := ← officialExpr type,
      value := ← officialExpr (unitRec [one] (.const unitCtor [])),hints := .abbrev,safety := .safe
    }) none true
    require (name ++ "-official-declaration")
      (match result with | .ok _ => shouldAccept | .error _ => !shouldAccept)
  IO.println "PSC1_V2_K_OFFICIAL_PASS valid=6 invalid=3 declarations=2"

def main : IO Unit := do
  let ready ← prepare
  checked ready
  official ready
  matrices ready.scalar ready.state ready.valid ready.invalid
  fixedOwners ready.scalar ready.state ready.valid
  let info ← recInfo ready.prepared.session eqName
  let context := psKernelExprV2CheckContextEmpty ready.scalar
  carrierProbes context ready.state info ready.major
  ordering context ready.state ready.kRoot ready.natRoot ready.badLevels
  IO.println "PSC1_V2_RECURSOR_K_PASS"
