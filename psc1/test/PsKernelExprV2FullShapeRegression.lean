import Ps.KernelCore.API.Dag
import Ps.KernelCore.Checker.ExprV2.DefEq.FullShape
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

private def require (label : String) (value : Bool) : IO Unit := do
  unless value do throw (IO.userError ("PSC1_V2_FULL_SHAPE_FAIL " ++ label))

private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def expectPublic {α : Type} : Except PsKernelError α → IO α
  | .ok value => pure value
  | .error _ => throw (IO.userError "full-shape fixture admission failed")

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
  | _, none => throw (IO.userError ("unexpected full-shape fallback: " ++ label))
  | _, _ => throw (IO.userError ("full-shape outcome mismatch: " ++ label))

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

private def compareStage (label : String)
    (original : Except String (Prod (Option Bool) PsKernelCheckerState))
    (actual : Option (Except String (Prod PsKernelExprV2CheckState (Option Bool)))) : IO Unit := do
  match original, actual with
  | .error expected, some (.error observed) =>
      require (label ++ "-exact-error") (expected == observed)
  | .ok expected, some (.ok observed) =>
      require (label ++ "-decision") (expected.fst == observed.snd)
      require (label ++ "-fresh-owner") (expected.snd.nextFresh == observed.fst.nextFresh)
  | _, none => throw (IO.userError ("unexpected full-shape fallback: " ++ label))
  | _, _ => throw (IO.userError ("full-shape outcome mismatch: " ++ label))

private def expectStage (label : String)
    (attempt : Option (Except String (Prod PsKernelExprV2CheckState (Option Bool))))
    (value : Option Bool) (fresh : Nat) : IO Unit :=
  require label (match attempt with
    | some (.ok result) => result.snd == value && result.fst.nextFresh == fresh
    | _ => false)

private def regression : IO Unit := do
  let empty ← expectPublic
    (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let mut session := empty
  let mut arena := psKernelExprV2PagedEmpty
  let mut declarations : List PsKernelExprV2DeclarationRef := []
  let mut official ← Lean.mkEmptyEnvironment
  let u := cn "shapeU"
  let functionType := PsKernelExpr.forallE (nm "argument") u u .implicit
  let specifications : List (String × PsKernelExpr) := [
    ("shapeU", s1), ("shapeA", u), ("shapeB", u),
    ("shapeF", functionType),
    ("shapeH", .forallE (nm "x") u functionType .default)]
  for (text, type) in specifications do
    let name := nm text
    let (next, root) ← expect (psKernelExprV2PagedImportIntoChecked arena type)
    let admitted ← expectPublic (psKernelV1AdmitDeclaration session
      (.axiomDecl (PsKernelAxiomInfo.mk (PsKernelConstantBase.mk name [] type) false)))
    session := admitted.session
    arena := next
    declarations := psKernelDagDeclarationsAfterAdmission
      (.axiomDecl (PsKernelDagConstantBase.mk name [] root) false) declarations
    let some officialType := inferOfficialExpr type
      | throw (IO.userError "official full-shape type conversion")
    match official.addDeclCore 0 0
        (.axiomDecl {
          name := inferOfficialName name
          levelParams := []
          type := officialType
          isUnsafe := false
        }) none true with
    | .ok next => official := next
    | .error _ => throw (IO.userError ("official full-shape fixture " ++ text))
  let f := cn "shapeF"
  let a := cn "shapeA"
  let h := cn "shapeH"
  let eta := PsKernelExpr.lam (nm "eta") u (.app f (.bvar 0)) .default
  let etaOtherName := PsKernelExpr.lam (nm "other") u (.app f (.bvar 0)) .strictImplicit
  let id := PsKernelExpr.lam (nm "x") u (.bvar 0) .default
  let idOtherName := PsKernelExpr.lam (nm "y") u (.bvar 0) .implicit
  let appLeft := PsKernelExpr.app (.app h s0) s1
  let appRight := PsKernelExpr.app (.app h s0) s1
  /- Some stage inputs are intentionally ill-typed: these exercise the
     original shape/callback order, never public acceptance. -/
  let stageFixtures : List (String × PsKernelExpr × PsKernelExpr) := [
    ("sort-equal", s0, s0), ("sort-different", s0, s1),
    ("nat-equal", .lit (.nat 7), .lit (.nat 7)),
    ("nat-different", .lit (.nat 7), .lit (.nat 8)),
    ("string-different", .lit (.str "a"), .lit (.str "b")),
    ("shape-mismatch", s0, .lit (.nat 7)),
    ("terminal-undecided", f, a),
    ("lambda-alpha", id, idOtherName),
    ("lambda-domain-different", .lam (nm "x") s0 (.bvar 0) .default,
      .lam (nm "x") s1 (.bvar 0) .default),
    ("forall-alpha", functionType, .forallE (nm "other") u u .default),
    ("forall-domain-different", .forallE (nm "x") s0 s0 .default,
      .forallE (nm "x") s1 s0 .default),
    ("app-equal", appLeft, appRight),
    ("app-argument-different", .app f s0, .app f s1),
    ("app-arity-different", .app f s0, .app (.app f s0) s1),
    ("eta-left", eta, f), ("eta-right", f, eta),
    ("eta-nonfunction", eta, a),
    ("eta-unknown", eta, cn "shapeMissing"),
    ("eta-metavariable", .mvar (nm "untrusted"), eta)]
  let base := psKernelKernelSessionChecker session [] .safe
  let mut stageComparisons := 0
  for (label, left, right) in stageFixtures do
    let (next, leftId) ← expect (psKernelExprV2PagedImportIntoChecked arena left)
    let (owning, rightId) ← expect (psKernelExprV2PagedImportIntoChecked next right)
    for fuel in [0,1,2,4,8,64] do
      for (limit, depth) in [(0,0),(1,15),(1,16)] do
        let scalar := { base.context with maxRecDepth := limit, recDepth := depth }
        let context := psKernelExprV2CheckContextEmpty scalar
        let defeq := psKernelIsDefEqWithFuel fuel
        let whnf := psKernelWhnfWithRecursorFuel fuel defeq
        let inferType := psKernelInferWithRecursorFuel fuel defeq
        let dagDefEq := psKernelExprV2TryDefEqStateWithFuel fuel
        let dagWhnf := psKernelExprV2CheckWhnfWithFuel fuel
        let dagInfer := fun c s r =>
          psKernelExprV2TryInferCoreWithFuel fuel dagWhnf dagDefEq c s r true
        compareStage label
          (psKernelDefEqFullShapeWith defeq inferType whnf
            scalar psKernelCheckerStateEmpty left right)
          (psKernelExprV2DefEqFullShapeWith dagDefEq dagInfer dagWhnf
            context (initialState owning declarations) leftId rightId)
        stageComparisons := stageComparisons + 1
  require "complete-stage-matrix" (stageComparisons == 342)
  let ownerFixtures : List (String × PsKernelExpr × PsKernelExpr) := [
    ("eta-left", eta, f), ("eta-right", f, eta),
    ("eta-alpha", etaOtherName, f),
    ("eta-metadata-left", .mdata 17 eta, f),
    ("eta-metadata-right", f, .mdata 19 eta),
    ("eta-applied", .app eta a, .app f a)]
  let mut ownerComparisons := 0
  for (label, left, right) in ownerFixtures do
    let (next, leftId) ← expect (psKernelExprV2PagedImportIntoChecked arena left)
    let (owning, rightId) ← expect (psKernelExprV2PagedImportIntoChecked next right)
    for fuel in [0,1,2,4,8,64] do
      for (limit, depth) in [(0,0),(1,15),(1,16)] do
        let scalar := { base.context with maxRecDepth := limit, recDepth := depth }
        compare label
          (psKernelIsDefEqWithFuel fuel scalar psKernelCheckerStateEmpty left right)
          (psKernelExprV2TryDefEqStateWithFuel fuel
            (psKernelExprV2CheckContextEmpty scalar)
            (initialState owning declarations) leftId rightId)
        ownerComparisons := ownerComparisons + 1
    for fuel in [0,1,2,4,8,64] do
      let limited := { session with resources := { session.resources with fuel := fuel } }
      require (label ++ "-public-parity")
        (samePublic (psKernelV1IsDefEq limited [] .safe left right)
          (psKernelV1RunDag limited [] .safe owning [.isDefEq leftId rightId]))
    let some officialLeft := inferOfficialExpr left
      | throw (IO.userError "official full-shape left conversion")
    let some officialRight := inferOfficialExpr right
      | throw (IO.userError "official full-shape right conversion")
    require (label ++ "-official-left-check")
      (match Lean.Kernel.check official {} officialLeft with | .ok _ => true | _ => false)
    require (label ++ "-official-right-check")
      (match Lean.Kernel.check official {} officialRight with | .ok _ => true | _ => false)
    require (label ++ "-official-equality")
      (match Lean.Kernel.isDefEq official {} officialLeft officialRight with
       | .ok true => true | _ => false)
  require "complete-owner-matrix" (ownerComparisons == 108)
  let (next, fId) ← expect (psKernelExprV2PagedImportIntoChecked arena f)
  let (next, aId) ← expect (psKernelExprV2PagedImportIntoChecked next a)
  let (next, s0Id) ← expect (psKernelExprV2PagedImportIntoChecked next s0)
  let (next, s1Id) ← expect (psKernelExprV2PagedImportIntoChecked next s1)
  let (next, etaId) ← expect (psKernelExprV2PagedImportIntoChecked next eta)
  let (next, metadataId) ← expect (psKernelExprV2PagedImportIntoChecked next (.mdata 17 eta))
  let (next, hId) ← expect (psKernelExprV2PagedImportIntoChecked next h)
  /- The trace below checks owned IDs, not structural equality. Reuse the
     separately named head/arguments rather than importing fresh children. -/
  let (next, shortAppId) ← expect (psKernelExprV2PagedMkApp next hId s0Id)
  let (next, appId) ← expect (psKernelExprV2PagedMkApp next shortAppId s1Id)
  let (next, projectionId) ← expect
    (psKernelExprV2PagedImportIntoChecked next (.proj (nm "unadmittedStruct") 0 a))
  let (owning, invalidId) ← expect (psKernelExprV2PagedImportIntoChecked next (.app f s0))
  let context := psKernelExprV2CheckContextEmpty base.context
  let cold := initialState owning declarations
  let noInfer := fun (_ : PsKernelExprV2CheckContext) (_ : PsKernelExprV2CheckState) (_ : Nat) =>
    some (.error "FULL_SHAPE_UNEXPECTED_INFER" :
      Except String (PsKernelExprV2CheckState × Nat))
  let noWhnf := fun (_ : PsKernelExprV2CheckContext) (_ : PsKernelExprV2WhnfState) (_ : Nat) =>
    some (.error "FULL_SHAPE_UNEXPECTED_WHNF" :
      Except String (PsKernelExprV2WhnfState × Nat))
  let noDefEq := fun (_ : PsKernelExprV2CheckContext) (_ : PsKernelExprV2CheckState) (_ _ : Nat) =>
    some (.error "FULL_SHAPE_HEAD_FIRST" :
      Except String (PsKernelExprV2CheckState × Bool))
  require "app-head-before-arity"
    (match psKernelExprV2DefEqFullShapeWith noDefEq noInfer noWhnf
        context cold appId shortAppId with
     | some (.error error) => error == "FULL_SHAPE_HEAD_FIRST" | _ => false)
  let trace := fun (c : PsKernelExprV2CheckContext)
      (s : PsKernelExprV2CheckState) (l r : Nat) =>
    let expected := if s.nextFresh == 0 then hId
      else if s.nextFresh == 1 then s0Id else s1Id
    if l == expected && r == expected && c.scalar.recDepth == context.scalar.recDepth then
      some (.ok ({ s with nextFresh := s.nextFresh + 1 }, true))
    else some (.error "FULL_SHAPE_ARGUMENT_ORDER")
  expectStage "app-left-to-right-and-no-extra-depth"
    (psKernelExprV2DefEqFullShapeWith trace noInfer noWhnf context cold appId appId)
    (some true) 3
  let falseAfterHead := fun (_ : PsKernelExprV2CheckContext)
      (s : PsKernelExprV2CheckState) (_ _ : Nat) =>
    some (.ok ({ s with nextFresh := s.nextFresh + 1 }, s.nextFresh == 0))
  expectStage "failed-argument-is-undecided"
    (psKernelExprV2DefEqFullShapeWith falseAfterHead noInfer noWhnf
      context cold appId appId) none 2
  let decline := fun (_ : PsKernelExprV2CheckContext) (_ : PsKernelExprV2CheckState) (_ _ : Nat) =>
    (none : Option (Except String (PsKernelExprV2CheckState × Bool)))
  require "unsupported-child-escapes-no-state"
    (psKernelExprV2DefEqFullShapeWith decline noInfer noWhnf context cold appId appId).isNone
  require "argument-list-zero-fuel-before-empty"
    (match psKernelExprV2DefEqFullShapeListsWithFuel 0 trace context cold [] [] with
     | some (.error error) => error == "kernel defeq argument-list budget exhausted"
     | _ => false)
  let sameWhnf := fun (_ : PsKernelExprV2CheckContext) (s : PsKernelExprV2WhnfState) (r : Nat) =>
    some (.ok (s, r))
  let coreError := fun (_ : PsKernelExprV2CheckContext) (_ : PsKernelExprV2WhnfState)
      (r : Nat) (cheap : Bool) =>
    some (.error (if cheap then "FULL_SHAPE_CHEAP_PROJECTION"
      else if r == s0Id then "FULL_SHAPE_LEFT_CORE" else "FULL_SHAPE_RIGHT_CORE") :
      Except String (PsKernelExprV2WhnfState × Nat))
  require "full-core-left-error-first"
    (match psKernelExprV2DefEqResidualWith noDefEq noInfer sameWhnf coreError
        context cold s0Id s1Id with
     | some (.error error) => error == "FULL_SHAPE_LEFT_CORE" | _ => false)
  let coreIdentity := fun (_ : PsKernelExprV2CheckContext) (s : PsKernelExprV2WhnfState)
      (r : Nat) (cheap : Bool) =>
    if cheap then some (.error "FULL_SHAPE_CHEAP_PROJECTION")
    else some (.ok (s, r))
  require "matching-projection-declines-before-full-core"
    (psKernelExprV2DefEqResidualWith noDefEq noInfer noWhnf coreError
      context cold projectionId projectionId).isNone
  require "residual-terminal-rule-remains-unsupported"
    (psKernelExprV2DefEqResidualWith noDefEq noInfer sameWhnf coreIdentity
      context cold fId aId).isNone
  require "sort-negative-is-final"
    (match psKernelExprV2DefEqResidualWith noDefEq noInfer sameWhnf coreIdentity
        context cold s0Id s1Id with
     | some (.ok result) => !result.snd | _ => false)
  let changedCore := fun (_ : PsKernelExprV2CheckContext) (s : PsKernelExprV2WhnfState)
      (_ : Nat) (cheap : Bool) =>
    if cheap then some (.error "FULL_SHAPE_CHEAP_PROJECTION")
    else some (.ok (s, s1Id))
  let changedCompare := fun (_ : PsKernelExprV2CheckContext)
      (s : PsKernelExprV2CheckState) (l r : Nat) =>
    if l == s1Id && r == s1Id then some (.ok (s, false))
    else some (.error "FULL_SHAPE_CHANGED_PAIR")
  require "changed-full-roots-use-owning-callback"
    (match psKernelExprV2DefEqResidualWith changedCompare noInfer sameWhnf changedCore
        context cold s0Id s1Id with
     | some (.ok result) => !result.snd | _ => false)
  let some (.ok warm) := psKernelExprV2TryDefEqStateWithFuel 64
      context cold metadataId fId
    | throw (IO.userError "full-shape warm eta")
  require "warm-eta-is-true" warm.snd
  require "success-original-pair"
    (← expect (psKernelExprV2DefEqPairContains warm.fst.whnf.arena
      warm.fst.success metadataId fId))
  require "success-not-residual-pair"
    (!(← expect (psKernelExprV2DefEqPairContains warm.fst.whnf.arena
      warm.fst.success etaId fId)))
  let oldWarm ← expect (psKernelIsDefEqWithFuel 64 base.context
    psKernelCheckerStateEmpty (.mdata 17 eta) f)
  for fuel in [0,1,64] do
    for depth in [0,15,16] do
      let scalar := { base.context with maxRecDepth := 1, recDepth := depth }
      compare "warm-fuel-depth-guards"
        (psKernelIsDefEqWithFuel fuel scalar oldWarm.snd (.mdata 17 eta) f)
        (psKernelExprV2TryDefEqStateWithFuel fuel
          (psKernelExprV2CheckContextEmpty scalar) warm.fst metadataId fId)
  require "missing-owner-index-is-not-authorized-by-eta"
    (psKernelExprV2TryDefEqWithDeclarationsFuel 64 base.context owning []
      metadataId fId).isNone
  require "public-rejects-illtyped-application"
    (match psKernelV1RunDag session [] .safe owning [.isDefEq invalidId invalidId] with
     | .error (.rejectedInvalid _) => true | _ => false)
  let some officialInvalid := inferOfficialExpr (.app f s0)
    | throw (IO.userError "official full-shape invalid conversion")
  require "official-rejects-illtyped-application"
    (match Lean.Kernel.check official {} officialInvalid with | .error _ => true | _ => false)
  IO.println "PSC1_V2_DAG_FULL_SHAPE: PASS stageComparisons=342 ownerComparisons=108"
  IO.println "PSC1_V2_DAG_OFFICIAL_FULL_SHAPE: PASS cases=6 invalid=1"

def main : IO Unit := regression
