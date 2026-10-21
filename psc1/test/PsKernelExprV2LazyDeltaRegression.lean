import Ps.KernelCore.API.Dag
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

private def require (label : String) (value : Bool) : IO Unit := do
  unless value do throw (IO.userError ("PSC1_V2_LAZY_DELTA_FAIL " ++ label))

private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def expectPublic {α : Type} : Except PsKernelError α → IO α
  | .ok value => pure value
  | .error _ => throw (IO.userError "lazy-delta fixture admission failed")

private def nm (value : String) := PsKernelName.str .anonymous value
private def s0 := PsKernelExpr.sort PsKernelLevel.zero
private def s1 := PsKernelExpr.sort (.succ .zero)
private def cn (value : String) := PsKernelExpr.const (nm value) []

private def initialState (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef) :=
  psKernelExprV2CheckStateWithWhnf (psKernelExprV2CheckStateEmpty arena)
    (psKernelExprV2WhnfStateForDeclarations arena declarations)

private def compare (label : String)
    (original : Except String (Prod Bool PsKernelCheckerState))
    (actual : Option (Except String (Prod PsKernelExprV2CheckState Bool))) : IO Unit := do
  match original, actual with
  | .error expected, some (.error observed) =>
      require (label ++ "-exact-error") (expected == observed)
  | .ok expected, some (.ok observed) =>
      require (label ++ "-decision") (expected.fst == observed.snd)
      require (label ++ "-fresh-owner") (expected.snd.nextFresh == observed.fst.nextFresh)
  | _, none => throw (IO.userError ("unexpected lazy-delta fallback: " ++ label))
  | _, _ => throw (IO.userError ("lazy-delta outcome mismatch: " ++ label))

private def sameError : PsKernelError → PsKernelError → Bool
  | .rejectedInvalid a, .rejectedInvalid b => a == b
  | .declinedUnsupported a, .declinedUnsupported b => a == b
  | .internalError a, .internalError b => a == b
  | .resourceExhausted ra a, .resourceExhausted rb b =>
      let kinds := match ra, rb with
        | .fuel, .fuel => true
        | .recursionDepth, .recursionDepth => true
        | .natSize, .natSize => true
        | .cancelled, .cancelled => true
        | .declarationLimit, .declarationLimit => true
        | .hostStack, .hostStack => true
        | _, _ => false
      kinds && a == b
  | _, _ => false

private def samePublic (original : Except PsKernelError Bool)
    (actual : Except PsKernelError PsKernelDagBatchResult) : Bool :=
  match original, actual with
  | .error a, .error b => sameError a b
  | .ok a, .ok b =>
      match b.replies with
      | [.equal value] => a == value
      | _ => false
  | _, _ => false

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

private def expectAttempt {α : Type} (label : String) :
    Option (Except String α) → IO α
  | none => throw (IO.userError ("unexpected fallback: " ++ label))
  | some result => expect result

private def lit (value : Nat) := PsKernelExpr.lit (.nat value)
private def nat := PsKernelExpr.const psKernelNatName []
private def fnType := PsKernelExpr.forallE (nm "x") nat nat .default
private def apply (text : String) (value : PsKernelExpr) := PsKernelExpr.app (cn text) value

private def originalLazy (fuel callbackFuel : Nat)
    (context : PsKernelCheckerContext) (state : PsKernelCheckerState)
    (left right : PsKernelExpr) :=
  psKernelDefEqLazyReductionWithFuel fuel
    (psKernelIsDefEqWithFuel callbackFuel)
    (psKernelWhnfWithRecursorFuel callbackFuel (psKernelIsDefEqWithFuel callbackFuel))
    (psKernelWhnfCoreWithRecursorFuel callbackFuel (psKernelIsDefEqWithFuel callbackFuel))
    context state left right

private def directLazy (fuel callbackFuel : Nat)
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :=
  psKernelExprV2DefEqLazyDeltaWithFuel fuel
    (psKernelExprV2TryDefEqStateWithFuel callbackFuel)
    (fun c s r => psKernelExprV2CheckWhnfWithFuel callbackFuel c s r)
    (fun c s r cheap => psKernelExprV2CheckWhnfCoreWithFuel callbackFuel c s r cheap)
    context state left right

private def originalStep (callbackFuel : Nat)
    (context : PsKernelCheckerContext) (state : PsKernelCheckerState)
    (left right : PsKernelExpr) :=
  psKernelDefEqLazyStep (psKernelIsDefEqWithFuel callbackFuel)
    (psKernelWhnfCoreWithRecursorFuel callbackFuel (psKernelIsDefEqWithFuel callbackFuel))
    context state left right

private def directStep (callbackFuel : Nat)
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :=
  psKernelExprV2DefEqLazyStepWith
    (psKernelExprV2TryDefEqStateWithFuel callbackFuel)
    (fun c s r cheap => psKernelExprV2CheckWhnfCoreWithFuel callbackFuel c s r cheap)
    context state left right

private def compareLazy (label : String)
    (original : Except String (Prod PsKernelDeltaResult PsKernelCheckerState))
    (actual : Option (Except String (Prod PsKernelExprV2CheckState Bool))) : IO Unit := do
  match original, actual with
  | .error a, some (.error b) => require (label ++ "-exact-error") (a == b)
  | .ok (.mk (.decided a) old), some (.ok next) =>
      require (label ++ "-decision") (a == next.snd)
      require (label ++ "-fresh") (old.nextFresh == next.fst.nextFresh)
  | .ok (.mk (.residual _ _) _), none => pure ()
  | _, _ => throw (IO.userError ("lazy-delta stage mismatch: " ++ label))

private def compareStep (label : String)
    (original : Except String (Prod PsKernelDeltaStepResult PsKernelCheckerState))
    (actual : Option (Except String
      (Prod PsKernelExprV2CheckState PsKernelExprV2DeltaStepResult))) : IO Unit := do
  match original, actual with
  | .error a, some (.error b) => require (label ++ "-step-error") (a == b)
  | .ok old, some (.ok next) =>
      require (label ++ "-step-fresh") (old.snd.nextFresh == next.fst.nextFresh)
      let decoded ← expect (psKernelExprV2DecodeChecked next.fst.whnf.arena)
      let pairEqual := fun (a b : PsKernelExpr) (x y : Nat) => do
        let ax ← expect (psKernelExprV2DecodedRequire decoded x)
        let by ← expect (psKernelExprV2DecodedRequire decoded y)
        require (label ++ "-step-residual-ids")
          (psKernelExprEqual a ax && psKernelExprEqual b by)
      match old.fst, next.snd with
      | .equal, .equal => pure ()
      | .different a b, .different x y => pairEqual a b x y
      | .continue a b, .continue x y => pairEqual a b x y
      | .unknown a b, .unknown x y => pairEqual a b x y
      | _, _ => throw (IO.userError ("lazy-delta step tag mismatch: " ++ label))
  | _, _ => throw (IO.userError ("lazy-delta step outcome mismatch: " ++ label))

private def officialHints : PsKernelReducibilityHints → Lean.ReducibilityHints
  | .abbrevHint => .abbrev
  | .opaqueHint => .opaque
  | .regular height => .regular (UInt32.ofNat height)

private def regression : IO Unit := do
  let empty ← expectPublic (psKernelKernelSessionEmpty
    psKernelResourcePolicyDefault psKernelProviderDefault)
  let natDecl := PsKernelSimpleInductiveDecl.mk [] psKernelNatName s1
    [PsKernelSimpleConstructorDecl.mk psKernelNatZeroName nat,
     PsKernelSimpleConstructorDecl.mk psKernelNatSuccName
       (.forallE (nm "n") nat nat .default)] false 0
  let admitted ← expectPublic (psKernelV1AdmitDeclaration empty (.ordinaryInductive natDecl))
  let mut session := admitted.session
  let (a, sortId) ← expect (psKernelExprV2PagedImportChecked s1)
  let (a, natId) ← expect (psKernelExprV2PagedImportIntoChecked a nat)
  let (a, succTypeId) ← expect (psKernelExprV2PagedImportIntoChecked a
    (.forallE (nm "n") nat nat .default))
  let natRequest := PsKernelDagDeclarationRequest.ordinaryInductive [] 0
    (PsKernelDagInductive.mk psKernelNatName sortId
      [PsKernelDagConstructor.mk psKernelNatZeroName natId,
       PsKernelDagConstructor.mk psKernelNatSuccName succTypeId]) false
  let mut arena := a
  let mut declarations := psKernelDagDeclarationsAfterAdmission natRequest []
  let mut requests := [PsKernelDagCommand.admit natRequest]
  let hints : List (String × PsKernelReducibilityHints) :=
    [("Abbrev",.abbrevHint),("Low",.regular 1),("High",.regular 7),("Opaque",.opaqueHint)]
  let mut specifications : List
      (String × List PsKernelName × PsKernelExpr × PsKernelExpr × PsKernelReducibilityHints) := []
  for (label,hint) in hints do
    for value in [0,1] do
      specifications := specifications ++ [("delta" ++ label ++ toString value,[],nat,lit value,hint)]
  let u := nm "u"
  let identity := PsKernelExpr.lam (nm "x") nat (.bvar 0) .default
  let constant := PsKernelExpr.lam (nm "x") nat (lit 0) .default
  specifications := specifications ++ [
    ("deltaAlias1",[],nat,cn "deltaAbbrev0",.regular 8),
    ("deltaAlias2",[],nat,cn "deltaAlias1",.regular 9),
    ("deltaConst",[],fnType,constant,.regular 1),
    ("deltaId",[],fnType,identity,.regular 1),
    ("deltaPoly",[u],fnType,constant,.regular 1)]
  Lean.initSearchPath (← Lean.findSysroot)
  let mut official ← Lean.importModules #[{ module := `Init }] {}
  for (text,params,type,value,hint) in specifications do
    let name := nm text
    let (a, typeId) ← expect (psKernelExprV2PagedImportIntoChecked arena type)
    let (a, valueId) ← expect (psKernelExprV2PagedImportIntoChecked a value)
    arena := a
    let info := PsKernelDefinitionInfo.mk (PsKernelConstantBase.mk name params type) value hint .safe
    let next ← expectPublic (psKernelV1AdmitDeclaration session (.definitionDecl info))
    session := next.session
    let request := PsKernelDagDeclarationRequest.definitionDecl
      (PsKernelDagDefinition.mk (PsKernelDagConstantBase.mk name params typeId) valueId hint .safe)
    declarations := psKernelDagDeclarationsAfterAdmission request declarations
    requests := requests ++ [.admit request]
    let some officialType := inferOfficialExpr type
      | throw (IO.userError "official delta type conversion")
    let some officialValue := inferOfficialExpr value
      | throw (IO.userError "official delta value conversion")
    match official.addDeclCore 0 0
        (.defnDecl {
          name := inferOfficialName name
          levelParams := params.map inferOfficialName
          type := officialType
          value := officialValue
          hints := officialHints hint
          safety := .safe
        }) none true with
    | .ok next => official := next
    | .error _ => throw (IO.userError ("official delta fixture " ++ text))
  let base := psKernelKernelSessionChecker session [] .safe
  let context := psKernelExprV2CheckContextEmpty base.context
  let poly := fun (level : PsKernelLevel) (argument : PsKernelExpr) =>
    PsKernelExpr.app (.const (nm "deltaPoly") [level]) argument
  let fixtures : List (String × PsKernelExpr × PsKernelExpr × Option Bool) := [
    ("left-definition",cn "deltaAbbrev0",lit 0,some true),
    ("right-definition",lit 0,cn "deltaAbbrev0",some true),
    ("left-negative",cn "deltaAbbrev0",lit 1,some false),
    ("greater-left-height",cn "deltaHigh0",cn "deltaLow0",some true),
    ("greater-right-height",cn "deltaLow0",cn "deltaHigh0",some true),
    ("abbrev-before-opaque",cn "deltaAbbrev0",cn "deltaOpaque0",some true),
    ("opaque-after-abbrev",cn "deltaOpaque0",cn "deltaAbbrev0",some true),
    ("three-step-chain",cn "deltaAlias2",lit 0,some true),
    ("three-step-negative",cn "deltaAlias2",lit 1,some false),
    ("failed-args-still-equal",apply "deltaConst" (lit 0),apply "deltaConst" (lit 1),some true),
    ("failed-args-different",apply "deltaId" (lit 0),apply "deltaId" (lit 1),some false),
    ("one-sided-beta",apply "deltaId" (lit 1),lit 1,some true),
    ("original-metadata-pair",.mdata 7 (cn "deltaAlias2"),lit 0,some true),
    ("zeta-chain",.letE (nm "v") nat (cn "deltaAlias2") (.bvar 0) false,lit 0,some true),
    ("beta-chain",.app identity (cn "deltaAlias2"),lit 0,some true),
    ("equivalent-universes",poly .zero (lit 0),poly (.max .zero .zero) (lit 1),some true),
    ("different-universes",poly .zero (lit 0),poly (.succ .zero) (lit 0),some true),
    ("two-hints-negative",cn "deltaHigh1",cn "deltaOpaque0",some false),
    ("unknown-definition",cn "deltaMissing",lit 0,none),
    ("invalid-level-arity",apply "deltaPoly" (lit 0),lit 0,none)]
  let mut comparisons := 0
  let mut officialValid := 0
  let mut officialInvalid := 0
  for (label,left,right,decision) in fixtures do
    let (a,leftId) ← expect (psKernelExprV2PagedImportIntoChecked arena left)
    let (owning,rightId) ← expect (psKernelExprV2PagedImportIntoChecked a right)
    for fuel in [0,1,2,3,4,5,6,8,16,64] do
      for maxRecDepth in [0,1,2] do
        for recDepth in [0,15,16] do
          let scalar := { base.context with maxRecDepth := maxRecDepth, recDepth := recDepth }
          compare label
            (psKernelIsDefEqWithFuel fuel scalar psKernelCheckerStateEmpty left right)
            (psKernelExprV2TryDefEqStateWithFuel fuel
              (psKernelExprV2CheckContextEmpty scalar) (initialState owning declarations) leftId rightId)
          comparisons := comparisons + 1
    let high := psKernelExprV2TryDefEqWithDeclarationsFuel 64
      base.context owning declarations leftId rightId
    require (label ++ "-high-budget-direct")
      (match decision,high with
       | some expected,some (.ok observed) => expected == observed
       | none,some (.error _) => true
       | _,_ => false)
    for fuel in [0,1,2,4,8,64] do
      let limited := { session with resources := { session.resources with fuel := fuel } }
      require (label ++ "-public-failure-protocol")
        (samePublic (psKernelV1IsDefEq limited [] .safe left right)
          (psKernelV1RunDag limited [] .safe owning [.isDefEq leftId rightId]))
    let some officialLeft := inferOfficialExpr left
      | throw (IO.userError "official left conversion")
    if let some expected := decision then
      let batch ← expectPublic (psKernelV1RunDag empty [] .safe owning
        (requests ++ [.isDefEq leftId rightId]))
      require (label ++ "-checked-same-batch")
        (batch.replies.length == requests.length + 1 &&
          match batch.replies.reverse with | .equal observed :: _ => observed == expected | _ => false)
      let some officialRight := inferOfficialExpr right
        | throw (IO.userError "official right conversion")
      require (label ++ "-official-left-check")
        (match Lean.Kernel.check official {} officialLeft with | .ok _ => true | _ => false)
      require (label ++ "-official-right-check")
        (match Lean.Kernel.check official {} officialRight with | .ok _ => true | _ => false)
      require (label ++ "-official-decision")
        (match Lean.Kernel.isDefEq official {} officialLeft officialRight with
         | .ok observed => observed == expected | _ => false)
      officialValid := officialValid + 1
    else
      require (label ++ "-official-invalid")
        (match Lean.Kernel.check official {} officialLeft with | .error _ => true | _ => false)
      officialInvalid := officialInvalid + 1
  require "complete-raw-matrix" (comparisons == 1800)
  let mut stageComparisons := 0
  let mut stepComparisons := 0
  for (leftHint,_) in hints do
    for (rightHint,_) in hints do
      for orientation in [false,true] do
        let left := cn ("delta" ++ leftHint ++ (if orientation then "1" else "0"))
        let right := cn ("delta" ++ rightHint ++ (if orientation then "0" else "1"))
        let (a,leftId) ← expect (psKernelExprV2PagedImportIntoChecked arena left)
        let (owning,rightId) ← expect (psKernelExprV2PagedImportIntoChecked a right)
        for callbackFuel in [0,1,4,64] do
          compareStep "all-hint-single-step"
            (originalStep callbackFuel base.context psKernelCheckerStateEmpty left right)
            (directStep callbackFuel context (initialState owning declarations) leftId rightId)
          stepComparisons := stepComparisons + 1
          for fuel in [0,1,2,4] do
            for eagerReduce in [false,true] do
              let scalar := { base.context with eagerReduce := eagerReduce }
              compareLazy "all-hint-loop"
                (originalLazy fuel callbackFuel scalar psKernelCheckerStateEmpty left right)
                (directLazy fuel callbackFuel (psKernelExprV2CheckContextEmpty scalar)
                  (initialState owning declarations) leftId rightId)
              stageComparisons := stageComparisons + 1
  require "complete-stage-matrix" (stageComparisons == 1024 && stepComparisons == 128)

  -- Warm owners arise only from a complete successful checking operation.
  let left := apply "deltaConst" (lit 0)
  let right := apply "deltaConst" (lit 1)
  let (a,leftId) ← expect (psKernelExprV2PagedImportIntoChecked arena left)
  let (a,rightId) ← expect (psKernelExprV2PagedImportIntoChecked a right)
  let (a,zeroId) ← expect (psKernelExprV2PagedImportIntoChecked a (lit 0))
  let (owning,oneId) ← expect (psKernelExprV2PagedImportIntoChecked a (lit 1))
  let cold := initialState owning declarations
  let warm ← expectAttempt "warm-owner"
    (psKernelExprV2TryDefEqStateWithFuel 64 context cold leftId rightId)
  let oldWarm ← expect (psKernelIsDefEqWithFuel 64 base.context
    psKernelCheckerStateEmpty left right)
  require "failed-arguments-do-not-mean-inequality" (warm.snd && oldWarm.fst)
  require "nonprop-state-survives-full-delta"
    (!warm.fst.inferOnly.isEmpty && warm.fst.checkedInfer.isEmpty &&
      !warm.fst.unfold.isEmpty && !warm.fst.failure.isEmpty)
  for (x,y) in [(leftId,rightId),(rightId,leftId)] do
    require "failure-pair-is-symmetric"
      (← expect (psKernelExprV2DefEqPairContains warm.fst.whnf.arena warm.fst.failure x y))
  require "original-failure-pair-is-symmetric"
    (psKernelExprPairSetContains oldWarm.snd.failure left right &&
      psKernelExprPairSetContains oldWarm.snd.failure right left)
  require "full-owner-publishes-original-success"
    (← expect (psKernelExprV2DefEqPairContains warm.fst.whnf.arena warm.fst.success leftId rightId))
  require "unequal-argument-pair-never-success"
    (!(← expect (psKernelExprV2DefEqPairContains warm.fst.whnf.arena
      warm.fst.success zeroId oneId)))
  for root in [leftId,rightId] do
    let entry ← expect (psKernelExprV2PagedRequire warm.fst.whnf.arena root)
    require "unfold-cache-published-both-sides"
      (← expect (psKernelExprV2WhnfCacheFindIn warm.fst.unfold
        warm.fst.whnf.arena root entry.hash)).isSome
  for fuel in [0,1,64] do
    for recDepth in [0,15,16] do
      let scalar := { base.context with maxRecDepth := 1, recDepth := recDepth }
      compare "warm-entry-guards"
        (psKernelIsDefEqWithFuel fuel scalar oldWarm.snd left right)
        (psKernelExprV2TryDefEqStateWithFuel fuel
          (psKernelExprV2CheckContextEmpty scalar) warm.fst leftId rightId)
  let badDefEq := fun (_ : PsKernelExprV2CheckContext) (_ : PsKernelExprV2CheckState)
      (_ _ : Nat) =>
    (some (.error "arguments-called") :
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
  let oldBadDefEq := fun (_ : PsKernelCheckerContext) (_ : PsKernelCheckerState)
      (_ _ : PsKernelExpr) =>
    (Except.error "arguments-called" : Except String (Prod Bool PsKernelCheckerState))
  let core := fun c s r cheap => psKernelExprV2CheckWhnfCoreWithFuel 64 c s r cheap
  let oldCore := psKernelWhnfCoreWithRecursorFuel 64 (psKernelIsDefEqWithFuel 64)
  compareStep "cold-argument-callback-error"
    (psKernelDefEqLazyStep oldBadDefEq oldCore base.context psKernelCheckerStateEmpty left right)
    (psKernelExprV2DefEqLazyStepWith badDefEq core context cold leftId rightId)
  require "cold-callback-really-ran"
    (match psKernelExprV2DefEqLazyStepWith badDefEq core context cold leftId rightId with
     | some (.error error) => error == "arguments-called" | _ => false)
  for (x,y,oldX,oldY) in [(leftId,rightId,left,right),(rightId,leftId,right,left)] do
    let hit := psKernelExprV2DefEqLazyStepWith badDefEq core context warm.fst x y
    compareStep "failure-hit-skips-only-args"
      (psKernelDefEqLazyStep oldBadDefEq oldCore base.context oldWarm.snd oldX oldY) hit
    require "failure-hit-still-unfolds-to-equal"
      (match hit with | some (.ok (_, .equal)) => true | _ => false)
  let child := (psKernelExprV2CheckStateFreshName warm.fst (nm "scope")).snd
  let restored := psKernelExprV2CheckStateExitLocalScope cold child
  require "scope-restores-delta-caches"
    (restored.failure.isEmpty && restored.unfold.isEmpty &&
      restored.whnf.arena.size == child.whnf.arena.size &&
      restored.nextFresh == child.nextFresh)
  require "scope-cannot-reuse-child-failure"
    (match psKernelExprV2DefEqLazyStepWith badDefEq core context restored leftId rightId with
     | some (.error error) => error == "arguments-called" | _ => false)
  let preserved := psKernelExprV2CheckStateWithInferOnly
    (psKernelExprV2CheckStateWithArena
      (psKernelExprV2CheckStateWithSuccess child child.success) child.whnf.arena) child.inferOnly
  require "ordinary-setters-preserve-delta-caches"
    (preserved.unfold.length == child.unfold.length &&
      (← expect (psKernelExprV2DefEqPairContains preserved.whnf.arena
        preserved.failure leftId rightId)))

  -- Body references are required only for a selected unfold, after same-definition args.
  require "missing-selected-body-declines"
    (psKernelExprV2DefEqUnfold context (initialState owning []) leftId).isNone
  let shortcut := directStep 64 context (initialState owning []) leftId leftId
  require "same-args-shortcut-does-not-preflight-body"
    (match shortcut with | some (.ok (_, .equal)) => true | _ => false)
  let selectedLeft := cn "deltaAbbrev0"
  let selectedRight := cn "deltaHigh1"
  let (a,selectedLeftId) ← expect (psKernelExprV2PagedImportIntoChecked owning selectedLeft)
  let (selectionArena,selectedRightId) ← expect (psKernelExprV2PagedImportIntoChecked a selectedRight)
  let some selectedRef := psKernelExprV2DeclarationRefFind declarations (nm "deltaAbbrev0")
    | throw (IO.userError "selected definition reference")
  let selected := directStep 64 context (initialState selectionArena [selectedRef])
    selectedLeftId selectedRightId
  compareStep "unselected-missing-body-is-not-preflighted"
    (originalStep 64 base.context psKernelCheckerStateEmpty selectedLeft selectedRight) selected
  require "selected-one-side-continues"
    (match selected with | some (.ok (_, .continue _ _)) => true | _ => false)
  let corruptRef := { selectedRef with kind := PsKernelExprV2DeclarationRefKind.axiomDecl }
  require "mismatched-owning-reference-declines"
    (psKernelExprV2DefEqUnfold context (initialState selectionArena [corruptRef]) selectedLeftId).isNone
  let (arityArena,badArityId) ← expect
    (psKernelExprV2PagedImportIntoChecked owning (apply "deltaPoly" (lit 0)))
  require "invalid-level-arity-is-no-definition-in-raw-step"
    (match directStep 64 context (initialState arityArena declarations) badArityId zeroId with
     | some (.ok (_, .unknown _ _)) => true | _ => false)
  require "raw-arity-residual-is-explicit-fallback"
    (directLazy 4 64 context (initialState arityArena declarations) badArityId zeroId).isNone

  -- Genuine modular-hash collisions are checked against exact source syntax.
  let collisionLeft := apply "deltaConst" (lit 65521)
  let (collisionArena,collisionId) ← expect
    (psKernelExprV2PagedImportIntoChecked warm.fst.whnf.arena collisionLeft)
  let collisionState := psKernelExprV2CheckStateWithArena warm.fst collisionArena
  let leftEntry ← expect (psKernelExprV2PagedRequire collisionArena leftId)
  let collisionEntry ← expect (psKernelExprV2PagedRequire collisionArena collisionId)
  require "real-failure-key-hash-collision"
    (leftEntry.hash == collisionEntry.hash &&
      !(← expect (psKernelExprV2PagedEqOnCanonical collisionArena leftId collisionId)))
  require "failure-collision-does-not-suppress-args"
    (match psKernelExprV2DefEqLazyStepWith badDefEq core
        context collisionState collisionId rightId with
     | some (.error error) => error == "arguments-called" | _ => false)
  let idZero := apply "deltaId" (lit 0)
  let idCollision := apply "deltaId" (lit 65521)
  let (a,idZeroId) ← expect (psKernelExprV2PagedImportIntoChecked collisionArena idZero)
  let (idArena,idCollisionId) ← expect (psKernelExprV2PagedImportIntoChecked a idCollision)
  let primed ← expectAttempt "prime-unfold"
    (psKernelExprV2DefEqUnfold context (initialState idArena declarations) idZeroId)
  let collided ← expectAttempt "collision-unfold"
    (psKernelExprV2DefEqUnfold context primed.fst idCollisionId)
  let some unfoldedId := collided.snd
    | throw (IO.userError "collision definition did not unfold")
  let decoded ← expect (psKernelExprV2DecodeChecked collided.fst.whnf.arena)
  let observed ← expect (psKernelExprV2DecodedRequire decoded unfoldedId)
  let oldPrimed := psKernelDefEqUnfold base.context psKernelCheckerStateEmpty idZero
  let oldCollided := psKernelDefEqUnfold base.context oldPrimed.snd idCollision
  let some expected := oldCollided.fst
    | throw (IO.userError "reference collision definition did not unfold")
  require "unfold-collision-miss-exact-result" (psKernelExprEqual observed expected)
  let zeroEntry ← expect (psKernelExprV2PagedRequire idArena idZeroId)
  let otherEntry ← expect (psKernelExprV2PagedRequire idArena idCollisionId)
  require "real-unfold-key-hash-collision" (zeroEntry.hash == otherEntry.hash)
  require "collision-inserts-distinct-unfold"
    (collided.fst.unfold.length == primed.fst.unfold.length + 1)

  -- Open terms are never cached even when the argument comparison returns false.
  let openLeft := apply "deltaConst" (.fvar (nm "openLeft"))
  let openRight := apply "deltaConst" (.fvar (nm "openRight"))
  let (a,openLeftId) ← expect (psKernelExprV2PagedImportIntoChecked owning openLeft)
  let (openArena,openRightId) ← expect (psKernelExprV2PagedImportIntoChecked a openRight)
  let falseDefEq := fun (_ : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState)
      (_ _ : Nat) =>
    (some (Except.ok (Prod.mk { s with nextFresh := s.nextFresh + 1 } false)) :
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
  let oldFalseDefEq := fun (_ : PsKernelCheckerContext) (s : PsKernelCheckerState)
      (_ _ : PsKernelExpr) =>
    (Except.ok (Prod.mk false { s with nextFresh := s.nextFresh + 1 }) :
      Except String (Prod Bool PsKernelCheckerState))
  let opened := psKernelExprV2DefEqLazyStepWith falseDefEq core
    context (initialState openArena declarations) openLeftId openRightId
  compareStep "open-argument-state"
    (psKernelDefEqLazyStep oldFalseDefEq oldCore base.context
      psKernelCheckerStateEmpty openLeft openRight) opened
  let opened ← expectAttempt "open-step" opened
  require "open-inputs-do-not-publish-delta-caches"
    (opened.fst.failure.isEmpty && opened.fst.unfold.isEmpty && opened.fst.nextFresh == 1)
  require "open-failed-args-can-still-unfold-equal"
    (match opened.snd with | .equal => true | _ => false)

  -- The outermost/rightmost argument callback precedes inner shape or arity tests.
  let argLeft := PsKernelExpr.app left (lit 1)
  let argRight := PsKernelExpr.app (apply "deltaConst" (.mvar (nm "inner"))) (lit 2)
  let (a,argLeftId) ← expect (psKernelExprV2PagedImportIntoChecked owning argLeft)
  let (argArena,argRightId) ← expect (psKernelExprV2PagedImportIntoChecked a argRight)
  let orderDefEq := fun (_ : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState)
      (x _ : Nat) =>
    match psKernelExprV2PagedRequire s.whnf.arena x with
    | .error error => some (.error error)
    | .ok entry =>
        some (Except.error
          (match entry.node with
           | .lit (.nat 1) => "rightmost-first"
           | _ => "wrong-inner-order") :
          Except String (Prod PsKernelExprV2CheckState Bool))
  let oldOrderDefEq := fun (_ : PsKernelCheckerContext) (_ : PsKernelCheckerState)
      (x _ : PsKernelExpr) =>
    (Except.error
      (match x with | .lit (.nat 1) => "rightmost-first" | _ => "wrong-inner-order") :
      Except String (Prod Bool PsKernelCheckerState))
  for (otherId,other) in [(argRightId,argRight),(rightId,right)] do
    let actual := psKernelExprV2DefEqArgs orderDefEq
      context (initialState argArena declarations) argLeftId otherId
    compare "rightmost-before-inner-or-arity"
      (psKernelDefEqArgs oldOrderDefEq base.context psKernelCheckerStateEmpty argLeft other) actual
    require "rightmost-callback-was-first"
      (match actual with | some (.error error) => error == "rightmost-first" | _ => false)
  require "argument-zero-before-roots-and-callback"
    (match psKernelExprV2DefEqArgsWithFuel 0 badDefEq context cold
        (owning.size + 1) (owning.size + 2) with
     | some (.error error) => error == "kernel defeq argument budget exhausted" | _ => false)

  -- Selected-side callbacks retain the reference's projection/left-to-right order.
  let projection := PsKernelExpr.app (.proj (nm "unownedProjection") 0 (lit 0)) (lit 1)
  let (a,projectionId) ← expect (psKernelExprV2PagedImportIntoChecked selectionArena projection)
  let projectionCore := fun (_ : PsKernelExprV2CheckContext) (_ : PsKernelExprV2WhnfState)
      (_ : Nat) (cheap : Bool) =>
    (some (.error (if cheap then "definition-too-early" else "projection-first")) :
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
  let oldProjectionCore := fun (_ : PsKernelCheckerContext) (_ : PsKernelCheckerState)
      (_ : PsKernelExpr) (cheapRec cheapProj : Bool) =>
    (Except.error
      (if cheapRec then "wrong-recursor-mode"
       else if cheapProj then "definition-too-early" else "projection-first") :
      Except String (Prod PsKernelExpr PsKernelCheckerState))
  for (x,y,oldX,oldY) in
      [(selectedLeftId,projectionId,selectedLeft,projection),
       (projectionId,selectedLeftId,projection,selectedLeft)] do
    let actual := psKernelExprV2DefEqLazyStepWith badDefEq projectionCore
      context (initialState a declarations) x y
    compareStep "projection-peer-first"
      (psKernelDefEqLazyStep oldBadDefEq oldProjectionCore
        base.context psKernelCheckerStateEmpty oldX oldY) actual
    require "projection-core-mode"
      (match actual with | some (.error error) => error == "projection-first" | _ => false)
  let low0 := cn "deltaLow0"
  let low1 := cn "deltaLow1"
  let (a,low0Id) ← expect (psKernelExprV2PagedImportIntoChecked a low0)
  let (bothArena,low1Id) ← expect (psKernelExprV2PagedImportIntoChecked a low1)
  let leftFirstCore := fun (_ : PsKernelExprV2CheckContext) (s : PsKernelExprV2WhnfState)
      (root : Nat) (cheap : Bool) =>
    match psKernelExprV2PagedRequire s.arena root with
    | .error error => some (.error error)
    | .ok entry =>
        some (Except.error
          (if cheap then
             (match entry.node with
              | .lit (.nat 0) => "left-unfold-first"
              | _ => "right-unfold-too-early")
           else "wrong-projection-mode") :
          Except String (Prod PsKernelExprV2WhnfState Nat))
  let oldLeftFirstCore := fun (_ : PsKernelCheckerContext) (_ : PsKernelCheckerState)
      (expr : PsKernelExpr) (cheapRec cheapProj : Bool) =>
    (Except.error
      (if cheapRec then "wrong-recursor-mode"
       else if cheapProj then
         (match expr with
          | .lit (.nat 0) => "left-unfold-first"
          | _ => "right-unfold-too-early")
       else "wrong-projection-mode") :
      Except String (Prod PsKernelExpr PsKernelCheckerState))
  let ordered := psKernelExprV2DefEqLazyStepWith badDefEq leftFirstCore
    context (initialState bothArena declarations) low0Id low1Id
  compareStep "both-definition-left-before-right"
    (psKernelDefEqLazyStep oldBadDefEq oldLeftFirstCore
      base.context psKernelCheckerStateEmpty low0 low1) ordered
  require "left-unfold-callback-was-first"
    (match ordered with | some (.error error) => error == "left-unfold-first" | _ => false)

  -- Lazy loop fuel is independent of the fixed core/DefEq predecessor callbacks.
  let alias := cn "deltaAlias2"
  let (chainArena,aliasId) ← expect (psKernelExprV2PagedImportIntoChecked owning alias)
  for fuel in [0,1,2,3,4] do
    compareLazy "fixed-callback-across-three-steps"
      (originalLazy fuel 1 base.context psKernelCheckerStateEmpty alias (lit 0))
      (directLazy fuel 1 context (initialState chainArena declarations) aliasId zeroId)
  require "three-steps-use-fixed-callback-fuel"
    (match directLazy 3 1 context (initialState chainArena declarations) aliasId zeroId with
     | some (.ok result) => result.snd | _ => false)
  require "two-loop-steps-exhaust-own-budget"
    (match directLazy 2 1 context (initialState chainArena declarations) aliasId zeroId with
     | some (.error error) => error == "kernel lazy-delta budget exhausted" | _ => false)
  require "lazy-zero-before-invalid-roots"
    (match directLazy 0 64 context cold (owning.size + 1) (owning.size + 2) with
     | some (.error error) => error == "kernel lazy-delta budget exhausted" | _ => false)
  let blocked := { base.context with maxRecDepth := 1, recDepth := 16 }
  compareLazy "lazy-helper-has-no-extra-depth-entry"
    (originalLazy 1 0 blocked psKernelCheckerStateEmpty (lit 0) (lit 0))
    (directLazy 1 0 (psKernelExprV2CheckContextEmpty blocked) cold zeroId zeroId)
  require "unknown-residual-is-not-a-negative"
    (directLazy 1 64 context cold zeroId oneId).isNone
  require "missing-reference-propagates-through-loop"
    (directLazy 4 64 context (initialState chainArena []) aliasId zeroId).isNone
  let declined := psKernelExprV2DefEqLazyDeltaContinueWithFuel 4
    (fun _ _ _ _ => some (.ok (cold,true)))
    (psKernelExprV2TryDefEqStateWithFuel 64)
    (fun c s r => psKernelExprV2CheckWhnfWithFuel 64 c s r)
    core context (initialState chainArena []) aliasId zeroId
  require "outer-none-does-not-run-success-continuation" declined.isNone
  let residualError := psKernelExprV2DefEqLazyDeltaContinueWithFuel 1
    (fun _ _ _ _ => some (.error "residual-reached"))
    (psKernelExprV2TryDefEqStateWithFuel 64)
    (fun c s r => psKernelExprV2CheckWhnfWithFuel 64 c s r)
    core context cold zeroId oneId
  require "only-residual-runs-later-stage"
    (match residualError with | some (.error error) => error == "residual-reached" | _ => false)

  let metadata := PsKernelExpr.mdata 7 alias
  let (metadataArena,metadataId) ← expect (psKernelExprV2PagedImportIntoChecked chainArena metadata)
  let metadataResult ← expectAttempt "metadata-full-owner"
    (psKernelExprV2TryDefEqStateWithFuel 64 context
      (initialState metadataArena declarations) metadataId zeroId)
  require "delta-success-publishes-original-metadata-pair"
    (metadataResult.snd && (← expect (psKernelExprV2DefEqPairContains
      metadataResult.fst.whnf.arena metadataResult.fst.success metadataId zeroId)))
  require "delta-success-does-not-publish-normalized-pair"
    (!(← expect (psKernelExprV2DefEqPairContains
      metadataResult.fst.whnf.arena metadataResult.fst.success aliasId zeroId)))

  -- Complete public checking rejects invalid applications and invalid declaration bodies.
  let invalid := apply "deltaId" s1
  let (invalidArena,invalidId) ← expect (psKernelExprV2PagedImportIntoChecked arena invalid)
  require "checked-api-rejects-invalid-definition-argument"
    (match psKernelV1RunDag empty [] .safe invalidArena (requests ++ [.check invalidId]) with
     | .error (.rejectedInvalid _) => true | _ => false)
  let some invalidOfficial := inferOfficialExpr invalid
    | throw (IO.userError "invalid argument conversion")
  require "official-rejects-invalid-definition-argument"
    (match Lean.Kernel.check official {} invalidOfficial with | .error _ => true | _ => false)
  officialInvalid := officialInvalid + 1
  let badName := nm "deltaRejectedBody"
  let badRequest := PsKernelDagDeclarationRequest.definitionDecl
    (PsKernelDagDefinition.mk (PsKernelDagConstantBase.mk badName [] natId) sortId (.regular 1) .safe)
  require "checked-api-rejects-invalid-definition-body"
    (match psKernelV1RunDag empty [] .safe arena (requests ++ [.admit badRequest]) with
     | .error (.rejectedInvalid _) => true | _ => false)
  require "failed-batch-does-not-publish"
    (psKernelEnvironmentFind session.environment badName).isNone
  require "official-rejects-invalid-definition-body"
    (match official.addDeclCore 0 0
        (.defnDecl {
          name := inferOfficialName badName
          levelParams := []
          type := .const (inferOfficialName psKernelNatName) []
          value := .sort (.succ .zero)
          hints := .regular 1
          safety := .safe
        }) none true with
     | .error _ => true | _ => false)
  officialInvalid := officialInvalid + 1
  require "complete-official-matrix" (officialValid == 18 && officialInvalid == 4)
  IO.println "PSC1_V2_DAG_LAZY_DELTA: PASS comparisons=1800 stage=1024 steps=128"
  IO.println "PSC1_V2_DAG_OFFICIAL_LAZY_DELTA: PASS cases=18 invalid=4"

def main : IO Unit := regression
