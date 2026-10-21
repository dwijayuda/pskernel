import Ps.KernelCore.API.Dag
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

private def require (label : String) (value : Bool) : IO Unit := do
  unless value do throw (IO.userError ("PSC1_V2_FINAL_RULES_FAIL " ++ label))

private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def expectPublic {α : Type} : Except PsKernelError α → IO α
  | .ok value => pure value
  | .error _ => throw (IO.userError "final-rule fixture admission failed")

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
  | _, none => throw (IO.userError ("unexpected final-rule fallback: " ++ label))
  | _, _ => throw (IO.userError ("final-rule outcome mismatch: " ++ label))

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
private def app2 (fn a b : PsKernelExpr) := PsKernelExpr.app (.app fn a) b
private def forallN (name : String) (domain body : PsKernelExpr) :=
  PsKernelExpr.forallE (nm name) domain body .default
private def pairName := nm "terminalPair"
private def pairCtor := PsKernelName.str pairName "mk"
private def pairType := PsKernelExpr.const pairName []
private def pair (a b : PsKernelExpr) := app2 (.const pairCtor []) a b
private def field (index : Nat) (value : PsKernelExpr) := PsKernelExpr.proj pairName index value
private def unitName := nm "terminalUnit"
private def unitType := PsKernelExpr.const unitName []
private def unitValue := PsKernelExpr.const (PsKernelName.str unitName "mk") []
private def tokenName := nm "terminalToken"
private def token (type : PsKernelExpr) := PsKernelExpr.app (.const tokenName []) type

private structure Fixtures where
  session : PsKernelKernelSession
  arena : PsKernelExprV2PagedArena
  declarations : List PsKernelExprV2DeclarationRef
  requests : List PsKernelDagCommand
  official : Lean.Environment

private def officialExpr (value : PsKernelExpr) : IO Lean.Expr :=
  match inferOfficialExpr value with
  | some result => pure result
  | none => throw (IO.userError "official terminal conversion")

private def admitInductive (f : Fixtures) (name : PsKernelName)
    (type : PsKernelExpr) (ctors : List (PsKernelName × PsKernelExpr))
    (numParams : Nat) : IO Fixtures := do
  let declaration := PsKernelSimpleInductiveDecl.mk [] name type
    (ctors.map fun (n,t) => PsKernelSimpleConstructorDecl.mk n t) false numParams
  let admitted ← expectPublic (psKernelV1AdmitDeclaration f.session (.ordinaryInductive declaration))
  let (a,typeId) ← expect (psKernelExprV2PagedImportIntoChecked f.arena type)
  let mut arena := a
  let mut dagCtors : List PsKernelDagConstructor := []
  let mut officialCtors : List Lean.Constructor := []
  for (ctorName,ctorType) in ctors do
    let (next,root) ← expect (psKernelExprV2PagedImportIntoChecked arena ctorType)
    arena := next
    dagCtors := dagCtors ++ [PsKernelDagConstructor.mk ctorName root]
    let officialCtorType ← officialExpr ctorType
    officialCtors := officialCtors ++ [{
      name := inferOfficialName ctorName
      type := officialCtorType
    }]
  let request := PsKernelDagDeclarationRequest.ordinaryInductive [] numParams
    (PsKernelDagInductive.mk name typeId dagCtors) false
  let mut official := f.official
  if !(psKernelNameEq name psKernelNatName) then
    let officialType ← officialExpr type
    match official.addDeclCore 0 0
        (.inductDecl [] numParams [{
          name := inferOfficialName name
          type := officialType
          ctors := officialCtors
        }] false) none true with
    | .error _ => throw (IO.userError "official terminal inductive")
    | .ok next => official := next
  pure {
    session := admitted.session
    arena := arena
    declarations := psKernelDagDeclarationsAfterAdmission request f.declarations
    requests := f.requests ++ [.admit request]
    official := official
  }

private def admitAxiom (f : Fixtures) (text : String) (type : PsKernelExpr) : IO Fixtures := do
  let name := nm text
  let admitted ← expectPublic (psKernelV1AdmitDeclaration f.session
    (.axiomDecl (PsKernelAxiomInfo.mk (PsKernelConstantBase.mk name [] type) false)))
  let (arena,typeId) ← expect (psKernelExprV2PagedImportIntoChecked f.arena type)
  let request := PsKernelDagDeclarationRequest.axiomDecl (PsKernelDagConstantBase.mk name [] typeId) false
  let officialType ← officialExpr type
  let official ← match f.official.addDeclCore 0 0
      (.axiomDecl {
        name := inferOfficialName name
        levelParams := []
        type := officialType
        isUnsafe := false
      }) none true with
    | .ok result => pure result
    | .error _ => throw (IO.userError "official terminal axiom")
  pure {
    session := admitted.session
    arena := arena
    declarations := psKernelDagDeclarationsAfterAdmission request f.declarations
    requests := f.requests ++ [.admit request]
    official := official
  }

private def admitAlias (f : Fixtures) (text : String) (value : PsKernelExpr) : IO Fixtures := do
  let name := nm text
  let admitted ← expectPublic (psKernelV1AdmitDeclaration f.session
    (.definitionDecl (PsKernelDefinitionInfo.mk (PsKernelConstantBase.mk name [] pairType)
      value (.regular 1) .safe)))
  let (arena,typeId) ← expect (psKernelExprV2PagedImportIntoChecked f.arena pairType)
  let (arena,valueId) ← expect (psKernelExprV2PagedImportIntoChecked arena value)
  let request := PsKernelDagDeclarationRequest.definitionDecl
    (PsKernelDagDefinition.mk (PsKernelDagConstantBase.mk name [] typeId) valueId (.regular 1) .safe)
  let officialType ← officialExpr pairType
  let officialValue ← officialExpr value
  let official ← match f.official.addDeclCore 0 0
      (.defnDecl {
        name := inferOfficialName name
        levelParams := []
        type := officialType
        value := officialValue
        hints := .regular 1
        safety := .safe
      }) none true with
    | .ok result => pure result
    | .error _ => throw (IO.userError "official terminal alias")
  pure {
    session := admitted.session
    arena := arena
    declarations := psKernelDagDeclarationsAfterAdmission request f.declarations
    requests := f.requests ++ [.admit request]
    official := official
  }

private def originalFinal (fuel : Nat) (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState) (left right : PsKernelExpr) :=
  let defeq := psKernelIsDefEqWithFuel fuel
  psKernelIsDefEqAfterFullShape defeq
    (psKernelInferWithRecursorFuel fuel defeq) (psKernelWhnfWithRecursorFuel fuel defeq)
    context state left right left right

private def directFinal (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (left right : Nat) :=
  let defeq := psKernelExprV2TryDefEqStateWithFuel fuel
  let whnf := psKernelExprV2CheckWhnfWithFuel fuel
  let inferType := fun c s r => psKernelExprV2TryInferCoreWithFuel fuel whnf defeq c s r true
  psKernelExprV2DefEqFinalRulesWith defeq inferType whnf context state left right

private def compareOptional (label : String)
    (original : Except String (Option Bool × PsKernelCheckerState))
    (actual : Option (Except String (PsKernelExprV2CheckState × Option Bool))) : IO Unit := do
  match original,actual with
  | .error a,some (.error b) => require (label ++ "-error") (a == b)
  | .ok a,some (.ok b) =>
      require (label ++ "-decision") (a.fst == b.snd)
      require (label ++ "-fresh") (a.snd.nextFresh == b.fst.nextFresh)
  | _,none => throw (IO.userError ("unexpected optional terminal fallback: " ++ label))
  | _,_ => throw (IO.userError ("optional terminal outcome mismatch: " ++ label))

private def sameNode (state : PsKernelExprV2CheckState) (left right : Nat) : Bool :=
  match psKernelExprV2PagedEqOnCanonical state.whnf.arena left right with
  | .ok true => true
  | _ => false

private def decoded (arena : PsKernelExprV2PagedArena) (root : Nat) : IO PsKernelExpr := do
  let canonical ← expect (psKernelExprV2PagedValidate arena)
  let graph ← expect (psKernelExprV2DecodeChecked canonical)
  expect (psKernelExprV2DecodedRequire graph root)


/- The raw callback probes below intentionally redirect the expanded String to
   a separately checked pair constructor. They assert callback/state behavior,
   not admission of a String as a pair. Genuine String projections have separate
   official-Lean checks; the real empty-String-environment workers are compared
   with V1 at their exact budgets without counting a stuck result as admission. -/
private def projectionOwnerMark (state : PsKernelExprV2CheckState)
    (root tag : Nat) : Except String PsKernelExprV2CheckState :=
  match psKernelExprV2PagedMkLit state.whnf.arena (.nat (10000 + tag)) with
  | .error error => .error error
  | .ok (arena,marker) =>
      let row := PsKernelExprV2WhnfCacheEntry.mk root marker (psKernelCacheHashModulus + tag)
      let pair := PsKernelExprV2DefEqPair.mk root marker (psKernelCacheHashModulus + tag)
      let state := psKernelExprV2CheckStateWithArena state arena
      .ok { state with
        nextFresh := tag
        checkedInfer := [row]
        inferOnly := [row]
        unfold := [row]
        success := [pair]
        failure := [pair]
        whnf := { state.whnf with coreCache := [row], publicCache := [row] }
      }

private def projectionOwnerMarked (state : PsKernelExprV2CheckState) (tag : Nat) : Bool :=
  let rowMarked := fun (rows : List PsKernelExprV2WhnfCacheEntry) =>
    match rows with
    | [row] =>
        row.hash == psKernelCacheHashModulus + tag &&
        (match psKernelExprV2PagedRequire state.whnf.arena row.result with
         | .ok entry =>
             match entry.node with
             | .lit (.nat value) => value == 10000 + tag
             | _ => false
         | .error _ => false)
    | _ => false
  let pairMarked := fun (rows : List PsKernelExprV2DefEqPair) =>
    match rows with
    | [row] => row.hash == psKernelCacheHashModulus + tag
    | _ => false
  state.nextFresh == tag && rowMarked state.checkedInfer &&
    rowMarked state.inferOnly && rowMarked state.unfold &&
    rowMarked state.whnf.publicCache && pairMarked state.success && pairMarked state.failure

private def compareProjectionWhnf (label : String)
    (expected : Except String (PsKernelExpr × PsKernelCheckerState))
    (actual : Option (Except String (PsKernelExprV2CheckState × Nat))) : IO Unit := do
  match expected,actual with
  | .error a,some (.error b) => require (label ++ "-exact-error") (a == b)
  | .ok (term,oldState),some (.ok (state,root)) =>
      require (label ++ "-term") (psKernelExprEqual term (← decoded state.whnf.arena root))
      require (label ++ "-fresh") (oldState.nextFresh == state.nextFresh)
  | _,none => throw (IO.userError ("unexpected String projection fallback: " ++ label))
  | _,_ => throw (IO.userError ("String projection outcome mismatch: " ++ label))

private def stringProjectionRegression (f : Fixtures) : IO Unit := do
  let base := psKernelKernelSessionChecker f.session [] .safe
  let context := psKernelExprV2CheckContextEmpty base.context
  let strings := ["","abc","é","é","漢字","🧪",
    String.singleton (Char.ofNat 0),String.singleton (Char.ofNat 65521)]
  let empty ← expectPublic (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let positive := field 0 (pair (lit 7) (lit 8))
  let (positiveArena,positiveId) ← expect (psKernelExprV2PagedImportIntoChecked f.arena positive)
  require "string-projection-public-valid-pair-control"
    (psKernelExprEqual (← expectPublic (psKernelV1Whnf f.session [] .safe positive)) (lit 7))
  let positiveBatch ← expectPublic (psKernelV1RunDag empty [] .safe positiveArena
    (f.requests ++ [.whnf positiveId]))
  require "string-projection-checked-DAG-valid-pair-control"
    (match positiveBatch.replies.reverse with
     | .normalized term :: _ => psKernelExprEqual term (lit 7)
     | _ => false)
  let mut differential := 0
  let mut owners := 0
  let mut failures := 0
  let mut officialValid := 0
  let mut officialInvalid := 0
  for value in strings do
    let literal := PsKernelExpr.lit (.str value)
    let expanded := psKernelStringLitToConstructor value
    let (a,literalId) ← expect (psKernelExprV2PagedImportIntoChecked f.arena literal)
    let (a,expandedId) ← expect (psKernelExprV2PagedImportIntoChecked a expanded)
    let (a,pairId) ← expect (psKernelExprV2PagedImportIntoChecked a (pair (lit 7) (lit 8)))
    let (a,fieldId) ← expect (psKernelExprV2PagedImportIntoChecked a (lit 7))
    let (arena,root) ← expect (psKernelExprV2PagedImportIntoChecked a (.proj pairName 0 literal))
    let cold := initialState arena f.declarations
    -- Direct reducer callbacks do not authorize an ill-typed public command.
    require "string-projection-public-invalid-pair-rejected"
      (match psKernelV1Whnf f.session [] .safe (.proj pairName 0 literal) with
       | .error (.rejectedInvalid _) => true | _ => false)
    require "string-projection-checked-DAG-invalid-pair-rejected"
      (match psKernelV1RunDag empty [] .safe arena (f.requests ++ [.whnf root]) with
       | .error (.rejectedInvalid _) => true | _ => false)
    for cheap in [false,true] do
      let initial ← expect (projectionOwnerMark cold root 40)
      let recurse := fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (r : Nat) =>
        if c.scalar.recDepth != context.scalar.recDepth then
          some (Except.error "STRING_PROJECTION_CONTEXT")
        else if cheap && r == literalId && projectionOwnerMarked s 40 then
          match projectionOwnerMark s root 41 with
          | .error error => some (.error error)
          | .ok next => some (.ok (next,literalId))
        else if r == fieldId && projectionOwnerMarked s 42 then
          match projectionOwnerMark s root 43 with
          | .error error => some (.error error)
          | .ok next => some (.ok (next,fieldId))
        else some (.error "STRING_PROJECTION_RECURSE_ORDER")
      let publicWhnf := fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (r : Nat) =>
        if c.scalar.recDepth != context.scalar.recDepth then
          some (Except.error "STRING_PROJECTION_CONTEXT")
        else if !cheap && r == literalId && projectionOwnerMarked s 40 then
          match projectionOwnerMark s root 41 with
          | .error error => some (.error error)
          | .ok next => some (.ok (next,literalId))
        else if sameNode s r expandedId && projectionOwnerMarked s 41 then
          match projectionOwnerMark s root 42 with
          | .error error => some (.error error)
          | .ok next => some (.ok (next,pairId))
        else some (.error "STRING_PROJECTION_PUBLIC_ORDER")
      let result ← expectAttempt "string-projection-full-owner"
        (psKernelExprV2TryWhnfProjectionOwnedWith recurse publicWhnf
          context initial root pairName 0 literalId cheap)
      require "string-projection-selected-field" (result.snd == fieldId)
      require "string-projection-full-owner-and-appended-arena" (projectionOwnerMarked result.fst 43)
      require "string-projection-core-cache-mode"
        (result.fst.whnf.coreCache.length == (if cheap then 1 else 2))
      owners := owners + 1
      -- Expansion must call public WHNF even in cheap projection mode.
      for declined in [false,true] do
        let stopPublic := fun (_ : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (r : Nat) =>
          if !cheap && r == literalId then
            some (Except.ok (s,literalId))
          else if declined then none else some (.error "STRING_PROJECTION_EXPANSION_FAILURE")
        let majorOnly := fun (_ : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (r : Nat) =>
          if r == literalId then some (Except.ok (s,literalId))
          else some (.error "STRING_PROJECTION_FIELD_MUST_NOT_RUN")
        let failed := psKernelExprV2TryWhnfProjectionOwnedWith majorOnly stopPublic
          context cold root pairName 0 literalId cheap
        require "string-projection-expansion-refusal-or-error-propagates"
          (if declined then failed.isNone else
            match failed with
            | some (.error error) => error == "STRING_PROJECTION_EXPANSION_FAILURE"
            | _ => false)
        failures := failures + 1
    for (typeName,index) in [((nm "String"),0),((nm "String"),2),(pairName,0)] do
      let term := PsKernelExpr.proj typeName index literal
      let (owned,root) ← expect (psKernelExprV2PagedImportIntoChecked arena term)
      for fuel in [0,1,2,4,16,64] do
        for depth in [0,15,16] do
          let scalar := { base.context with maxRecDepth := 1, recDepth := depth }
          let c := psKernelExprV2CheckContextEmpty scalar
          let oldEq := psKernelIsDefEqWithFuel fuel
          let dagEq := psKernelExprV2TryDefEqStateWithFuel fuel
          compareProjectionWhnf "string-projection-public"
            (psKernelWhnfWithRecursorFuel fuel oldEq scalar psKernelCheckerStateEmpty term)
            (psKernelExprV2CheckWhnfOwnedWithFuel fuel dagEq c
              (initialState owned f.declarations) root)
          differential := differential + 1
          for cheap in [false,true] do
            compareProjectionWhnf "string-projection-core"
              (psKernelWhnfCoreWithRecursorFuel fuel oldEq scalar psKernelCheckerStateEmpty term false cheap)
              (psKernelExprV2CheckWhnfCoreOwnedWithFuel fuel dagEq c
                (initialState owned f.declarations) root cheap)
            differential := differential + 1
    let valid := Lean.Expr.proj (inferOfficialName (nm "String")) 0 (.lit (.strVal value))
    let expansion := Lean.Expr.proj (inferOfficialName (nm "String")) 0 (← officialExpr expanded)
    require "official-string-projection-checks"
      (match Lean.Kernel.check f.official {} valid with | .ok _ => true | _ => false)
    require "official-string-projection-expansion-equal"
      (match Lean.Kernel.isDefEq f.official {} valid expansion with | .ok true => true | _ => false)
    officialValid := officialValid + 1
    for invalid in [
        Lean.Expr.proj (inferOfficialName (nm "String")) 2 (.lit (.strVal value)),
        Lean.Expr.proj (inferOfficialName pairName) 0 (.lit (.strVal value))] do
      require "official-invalid-string-projection-rejected"
        (match Lean.Kernel.check f.official {} invalid with | .error _ => true | _ => false)
      officialInvalid := officialInvalid + 1
  require "string-projection-complete-matrix"
    (differential == 1296 && owners == 16 && failures == 32 &&
      officialValid == 8 && officialInvalid == 16)
  IO.println "PSC1_V2_STRING_PROJECTION: PASS differential=1296 owners=16 failures=32 officialValid=8 officialInvalid=16"

private def regression : IO Unit := do
  let empty ← expectPublic (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let (arena,_) ← expect (psKernelExprV2PagedImportChecked s1)
  Lean.initSearchPath (← Lean.findSysroot)
  let official ← Lean.importModules #[{ module := `Init }] {}
  let mut f : Fixtures := {
    session := empty
    arena := arena
    declarations := []
    requests := []
    official := official
  }
  f ← admitInductive f psKernelNatName s1
    [(psKernelNatZeroName,nat),(psKernelNatSuccName,forallN "n" nat nat)] 0
  f ← admitInductive f pairName s1
    [(pairCtor,forallN "first" nat (forallN "second" nat pairType))] 0
  f ← admitInductive f unitName s1 [(PsKernelName.str unitName "mk",unitType)] 0
  let otherUnitName := nm "terminalOtherUnit"
  let otherUnit := PsKernelExpr.const otherUnitName []
  f ← admitInductive f otherUnitName s1 [(PsKernelName.str otherUnitName "mk",otherUnit)] 0
  f ← admitInductive f tokenName (forallN "alpha" s1 s1)
    [(PsKernelName.str tokenName "mk",forallN "alpha" s1 (token (.bvar 0)))] 1
  let loopName := nm "terminalLoop"
  let loopType := PsKernelExpr.const loopName []
  f ← admitInductive f loopName s1
    [(PsKernelName.str loopName "mk",forallN "tail" loopType loopType)] 0
  let choiceName := nm "terminalChoice"
  let choiceType := PsKernelExpr.const choiceName []
  f ← admitInductive f choiceName s1
    [(PsKernelName.str choiceName "first",choiceType),
     (PsKernelName.str choiceName "second",choiceType)] 0
  let indexedName := nm "terminalIndexed"
  let indexedType := PsKernelExpr.app (.const indexedName []) (lit 0)
  f ← admitInductive f indexedName (forallN "index" nat s1)
    [(PsKernelName.str indexedName "zero",indexedType)] 0
  for (text,type) in [
      ("terminalUnitA",unitType),("terminalUnitB",unitType),("terminalUnitOther",otherUnit),
      ("terminalPairA",pairType),("terminalPairB",pairType),
      ("terminalNatA",nat),("terminalNatB",nat),
      ("terminalTokenA",token nat),("terminalTokenB",token nat),("terminalTokenOther",token pairType),
      ("terminalLoopA",loopType),("terminalLoopB",loopType),
      ("terminalChoiceA",choiceType),("terminalChoiceB",choiceType),
      ("terminalIndexedA",indexedType),("terminalIndexedB",indexedType)] do
    f ← admitAxiom f text type
  f ← admitAlias f "terminalAlias1" (cn "terminalPairA")
  f ← admitAlias f "terminalAlias2" (cn "terminalAlias1")
  f ← admitAlias f "terminalAlias3" (cn "terminalAlias2")
  f ← admitAlias f "terminalAlias4" (cn "terminalAlias3")
  let base := psKernelKernelSessionChecker f.session [] .safe
  let context := psKernelExprV2CheckContextEmpty base.context
  let pairA := cn "terminalPairA"
  let pairB := cn "terminalPairB"
  let unitA := cn "terminalUnitA"
  let unitB := cn "terminalUnitB"
  let tokenA := cn "terminalTokenA"
  let eta := pair (field 0 pairA) (field 1 pairA)
  let wrongEta := pair (field 0 pairA) (lit 0)
  let alias := cn "terminalAlias1"
  let fixtures : List (String × PsKernelExpr × PsKernelExpr × Option Bool) := [
    ("unit-axioms",unitA,unitB,some true),
    ("unit-constructor-right",unitA,unitValue,some true),
    ("unit-constructor-left",unitValue,unitA,some true),
    ("unit-types-differ",unitA,cn "terminalUnitOther",some false),
    ("parameter-unit-equal",tokenA,cn "terminalTokenB",some true),
    ("parameter-unit-different",tokenA,cn "terminalTokenOther",some false),
    ("structure-eta-right",pairA,eta,some true),
    ("structure-eta-left",eta,pairA,some true),
    ("metadata-structure-eta",.mdata 31 pairA,eta,some true),
    ("pair-axioms-different",pairA,pairB,some false),
    ("structure-eta-field-different",pairA,wrongEta,some false),
    ("matching-projection-alias-right",field 0 pairA,field 0 alias,some true),
    ("matching-projection-alias-left",field 0 alias,field 0 pairA,some true),
    ("matching-projection-different",field 0 pairA,field 0 pairB,some false),
    ("nat-axioms-different",cn "terminalNatA",cn "terminalNatB",some false),
    ("recursive-type-different",cn "terminalLoopA",cn "terminalLoopB",some false),
    ("projection-index-different",field 0 pairA,field 1 pairA,some false),
    ("unit-versus-nat",unitA,lit 0,some false),
    ("structure-type-different",pairA,.app (.const (PsKernelName.str tokenName "mk") []) nat,some false),
    ("multiple-constructors-different",cn "terminalChoiceA",cn "terminalChoiceB",some false),
    ("indexed-type-different",cn "terminalIndexedA",cn "terminalIndexedB",some false),
    ("unknown-constant",cn "terminalMissing",unitA,none),
    ("invalid-projection-index",field 2 pairA,lit 0,none),
    ("invalid-projection-name",.proj unitName 0 pairA,lit 0,none)]
  let mut owners := 0
  let mut officialValid := 0
  let mut officialInvalid := 0
  for (label,left,right,decision) in fixtures do
    let (a,leftId) ← expect (psKernelExprV2PagedImportIntoChecked f.arena left)
    let (owning,rightId) ← expect (psKernelExprV2PagedImportIntoChecked a right)
    for fuel in [0,1,2,3,4,6,8,16,64] do
      for (limit,depth) in [(0,0),(1,15),(1,16)] do
        let scalar := { base.context with maxRecDepth := limit, recDepth := depth }
        compare label
          (psKernelIsDefEqWithFuel fuel scalar psKernelCheckerStateEmpty left right)
          (psKernelExprV2TryDefEqStateWithFuel fuel
            (psKernelExprV2CheckContextEmpty scalar)
            (initialState owning f.declarations) leftId rightId)
        owners := owners + 1
    require (label ++ "-high-budget-owner")
      (match decision,psKernelExprV2TryDefEqWithDeclarationsFuel
          64 base.context owning f.declarations leftId rightId with
       | some expected,some (.ok actual) => expected == actual
       | none,some (.error _) => true
       | _,_ => false)
    for fuel in [0,1,2,4,8,64] do
      let limited := { f.session with resources := { f.session.resources with fuel := fuel } }
      require (label ++ "-public-protocol")
        (samePublic (psKernelV1IsDefEq limited [] .safe left right)
          (psKernelV1RunDag limited [] .safe owning [.isDefEq leftId rightId]))
    let officialLeft ← officialExpr left
    if let some expected := decision then
      let batch ← expectPublic (psKernelV1RunDag empty [] .safe owning
        (f.requests ++ [.isDefEq leftId rightId]))
      require (label ++ "-checked-same-batch")
        (batch.replies.length == f.requests.length + 1 &&
          match batch.replies.reverse with | .equal actual :: _ => actual == expected | _ => false)
      let officialRight ← officialExpr right
      require (label ++ "-official-left")
        (match Lean.Kernel.check f.official {} officialLeft with | .ok _ => true | _ => false)
      require (label ++ "-official-right")
        (match Lean.Kernel.check f.official {} officialRight with | .ok _ => true | _ => false)
      require (label ++ "-official-decision")
        (match Lean.Kernel.isDefEq f.official {} officialLeft officialRight with
         | .ok actual => actual == expected | _ => false)
      officialValid := officialValid + 1
    else
      require (label ++ "-official-invalid")
        (match Lean.Kernel.check f.official {} officialLeft with | .error _ => true | _ => false)
      officialInvalid := officialInvalid + 1
  require "complete-owner-matrix" (owners == 648)

  let finalFixtures : List (PsKernelExpr × PsKernelExpr) := [
    (unitA,unitB),(unitA,unitValue),(unitA,cn "terminalUnitOther"),
    (tokenA,cn "terminalTokenB"),(tokenA,cn "terminalTokenOther"),
    (pairA,eta),(eta,pairA),(pairA,wrongEta),(pairA,pairB),
    (cn "terminalChoiceA",cn "terminalChoiceB"),
    (cn "terminalIndexedA",cn "terminalIndexedB"),
    (cn "terminalNatA",cn "terminalNatB")]
  let mut finals := 0
  for (left,right) in finalFixtures do
    let (a,leftId) ← expect (psKernelExprV2PagedImportIntoChecked f.arena left)
    let (owning,rightId) ← expect (psKernelExprV2PagedImportIntoChecked a right)
    for fuel in [0,1,2,4,8,64] do
      for (limit,depth) in [(0,0),(1,15),(1,16)] do
        let scalar := { base.context with maxRecDepth := limit, recDepth := depth }
        compare "full-final-stage"
          (originalFinal fuel scalar psKernelCheckerStateEmpty left right)
          (directFinal fuel (psKernelExprV2CheckContextEmpty scalar)
            (initialState owning f.declarations) leftId rightId)
        finals := finals + 1
  require "complete-final-stage-matrix" (finals == 216)
  let projectionFixtures : List (PsKernelExpr × PsKernelExpr × Nat) := [
    (pairA,alias,0),(alias,pairA,0),
    (pair (lit 0) (lit 1),pair (lit 0) (lit 2),0),
    (pair (lit 0) (lit 1),pair (lit 0) (lit 2),1),
    (pairA,pairB,0),(pair (lit 0) (lit 1),lit 0,0),
    (cn "terminalAlias4",pairA,0)]
  let mut projections := 0
  for (left,right,index) in projectionFixtures do
    let (a,leftId) ← expect (psKernelExprV2PagedImportIntoChecked f.arena left)
    let (owning,rightId) ← expect (psKernelExprV2PagedImportIntoChecked a right)
    for callbackFuel in [0,1,2,4,64] do
      let oldDefEq := psKernelIsDefEqWithFuel callbackFuel
      let oldCore := psKernelWhnfCoreWithRecursorFuel callbackFuel oldDefEq
      let dagDefEq := psKernelExprV2TryDefEqStateWithFuel callbackFuel
      let dagCore := fun c s r cheap => psKernelExprV2CheckWhnfCoreWithFuel callbackFuel c s r cheap
      for fuel in [0,1,2,3,4] do
        compare "lazy-projection-stage"
          (psKernelDefEqLazyProjReductionWithFuel fuel oldDefEq oldCore base.context
            psKernelCheckerStateEmpty left right pairName index)
          (psKernelExprV2DefEqLazyProjReductionWithFuel fuel dagDefEq dagCore context
            (initialState owning f.declarations) leftId rightId pairName index)
        projections := projections + 1
  require "complete-projection-stage-matrix" (projections == 175)

  -- Exact constructor translation and callback ordering are separate from
  -- whole-checker String support, whose WHNF still has recursor dependencies.
  let strings := ["","abc","é","é","漢字","🧪",
    String.singleton (Char.ofNat 0),String.singleton (Char.ofNat 65521)]
  let charType := PsKernelExpr.const psKernelCharName []
  let listNil := PsKernelExpr.app (.const psKernelListNilName [.zero]) charType
  let listCons := PsKernelExpr.app (.const psKernelListConsName [.zero]) charType
  let charOfNat := PsKernelExpr.const psKernelCharOfNatName []
  let (a,nilId) ← expect (psKernelExprV2PagedImportIntoChecked f.arena listNil)
  let (a,consId) ← expect (psKernelExprV2PagedImportIntoChecked a listCons)
  let (stringArena,charId) ← expect (psKernelExprV2PagedImportIntoChecked a charOfNat)
  let mut stringBuilds := 0
  let mut stringStages := 0
  let mut officialStrings := 0
  for value in strings do
    let built ← expect (psKernelExprV2StringLitToConstructorOnCanonical stringArena value)
    let term ← decoded built.fst built.snd
    require "string-whole-constructor-exact" (psKernelExprEqual term (psKernelStringLitToConstructor value))
    let independent ← officialExpr term
    require "official-string-constructor-check"
      (match Lean.Kernel.check f.official {} independent with | .ok _ => true | _ => false)
    require "official-string-constructor-equality"
      (match Lean.Kernel.isDefEq f.official {} (.lit (.strVal value)) independent with
       | .ok true => true | _ => false)
    officialStrings := officialStrings + 1
    for fuel in [0,1,2,4,8,64] do
      for position in [0,value.utf8ByteSize,value.utf8ByteSize + 1] do
        let result ← expect (psKernelExprV2StringConstructorDataWithFuel
          fuel stringArena value position nilId consId charId)
        require "string-prefix-budget-exact"
          (psKernelExprEqual (← decoded result.fst result.snd)
            (psKernelStringConstructorDataWithFuel fuel value position listNil listCons charOfNat))
        stringBuilds := stringBuilds + 1
    for sameValue in [true,false] do
      let other := if sameValue then value else value ++ "!"
      let left := PsKernelExpr.lit (.str value)
      let right := psKernelStringLitToConstructor other
      let (a,leftId) ← expect (psKernelExprV2PagedImportIntoChecked stringArena left)
      let (owning,rightId) ← expect (psKernelExprV2PagedImportIntoChecked a right)
      let oldEq := fun (_ : PsKernelCheckerContext) (s : PsKernelCheckerState)
          (l r : PsKernelExpr) =>
        Except.ok (psKernelExprEq l r,{ s with nextFresh := s.nextFresh + 1 })
      let dagEq := fun (_ : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState)
          (l r : Nat) =>
        match psKernelExprV2PagedEqOnCanonical s.whnf.arena l r with
        | .error error => some (.error error)
        | .ok decision => some (.ok ({ s with nextFresh := s.nextFresh + 1 },decision))
      let oldWhnf := fun (_ : PsKernelCheckerContext) (s : PsKernelCheckerState) (r : PsKernelExpr) =>
        Except.ok (r,s)
      let dagWhnf := fun (_ : PsKernelExprV2CheckContext) (s : PsKernelExprV2WhnfState) (r : Nat) =>
        some (Except.ok (s,r))
      for (l,r,oldL,oldR) in [(leftId,rightId,left,right),(rightId,leftId,right,left)] do
        let attempt := psKernelExprV2DefEqStringLitExpansionWith dagEq dagWhnf
          context (initialState owning f.declarations) l r
        compareOptional "string-stage-both-orientations"
          (psKernelDefEqStringLitExpansionWith oldEq oldWhnf base.context
            psKernelCheckerStateEmpty oldL oldR) attempt
        let observed ← expectAttempt "string-stage" attempt
        require "string-false-is-a-decision-not-fallthrough"
          (observed.snd == some sameValue && observed.fst.nextFresh == 1)
        stringStages := stringStages + 1
  require "complete-string-matrix" (stringBuilds == 144 && stringStages == 32 && officialStrings == 8)

  let (a,pairAId) ← expect (psKernelExprV2PagedImportIntoChecked f.arena pairA)
  let (a,pairBId) ← expect (psKernelExprV2PagedImportIntoChecked a pairB)
  let (a,etaId) ← expect (psKernelExprV2PagedImportIntoChecked a eta)
  let (a,pairTypeId) ← expect (psKernelExprV2PagedImportIntoChecked a pairType)
  let (a,unitAId) ← expect (psKernelExprV2PagedImportIntoChecked a unitA)
  let (a,unitBId) ← expect (psKernelExprV2PagedImportIntoChecked a unitB)
  let (a,unitTypeId) ← expect (psKernelExprV2PagedImportIntoChecked a unitType)
  let (a,zeroId) ← expect (psKernelExprV2PagedImportIntoChecked a (lit 0))
  let (a,oneId) ← expect (psKernelExprV2PagedImportIntoChecked a (lit 1))
  let (a,field0Id) ← expect (psKernelExprV2PagedImportIntoChecked a (field 0 pairA))
  let (a,field1Id) ← expect (psKernelExprV2PagedImportIntoChecked a (field 1 pairA))
  let (a,metadataId) ← expect (psKernelExprV2PagedImportIntoChecked a (.mdata 31 pairA))
  let (a,alias4Id) ← expect (psKernelExprV2PagedImportIntoChecked a (cn "terminalAlias4"))
  let (a,aliasProjectionId) ← expect
    (psKernelExprV2PagedImportIntoChecked a (field 0 (cn "terminalAlias4")))
  -- These callback sentinels require shared field IDs, so construct their spines
  -- from the retained zero/one nodes instead of re-importing fresh duplicates.
  let (a,pairCtorId) ← expect (psKernelExprV2PagedMkConst a pairCtor [])
  let (a,pair0Id) ← expect (psKernelExprV2PagedMkApp a pairCtorId zeroId)
  let (a,pair01Id) ← expect (psKernelExprV2PagedMkApp a pair0Id oneId)
  let (a,twoId) ← expect (psKernelExprV2PagedMkLit a (.nat 2))
  let (a,pair02Id) ← expect (psKernelExprV2PagedMkApp a pair0Id twoId)
  let (a,succZeroId) ← expect
    (psKernelExprV2PagedImportIntoChecked a (.app (.const psKernelNatSuccName []) (lit 0)))
  let (owning,loopCtorId) ← expect
    (psKernelExprV2PagedImportIntoChecked a
      (.app (.const (PsKernelName.str loopName "mk") []) (cn "terminalLoopA")))
  let cold := initialState owning f.declarations
  let badDefEq := fun (_ : PsKernelExprV2CheckContext) (_ : PsKernelExprV2CheckState) (_ _ : Nat) =>
    (some (.error "TERMINAL_DEFEQ_CALLED") :
      Option (Except String (PsKernelExprV2CheckState × Bool)))
  let oldBadDefEq := fun (_ : PsKernelCheckerContext) (_ : PsKernelCheckerState) (_ _ : PsKernelExpr) =>
    (Except.error "TERMINAL_DEFEQ_CALLED" : Except String (Bool × PsKernelCheckerState))
  let noInfer := fun (_ : PsKernelExprV2CheckContext) (_ : PsKernelExprV2CheckState) (_ : Nat) =>
    (some (.error "TERMINAL_INFER_CALLED") :
      Option (Except String (PsKernelExprV2CheckState × Nat)))
  let noWhnf := fun (_ : PsKernelExprV2CheckContext) (_ : PsKernelExprV2WhnfState) (_ : Nat) =>
    (some (.error "TERMINAL_WHNF_CALLED") :
      Option (Except String (PsKernelExprV2WhnfState × Nat)))
  let noCore := fun (_ : PsKernelExprV2CheckContext) (_ : PsKernelExprV2WhnfState)
      (_ : Nat) (_ : Bool) =>
    (some (.error "TERMINAL_CORE_CALLED") :
      Option (Except String (PsKernelExprV2WhnfState × Nat)))
  require "projection-zero-before-roots"
    (match psKernelExprV2DefEqLazyProjReductionWithFuel 0 badDefEq noCore context cold
        (owning.size + 1) (owning.size + 2) pairName 0 with
     | some (.error error) => error == "kernel lazy-projection budget exhausted" | _ => false)
  require "eta-fields-zero-before-empty-and-roots"
    (match psKernelExprV2DefEqEtaStructFieldsWithFuel 0 badDefEq context cold
        pairName (owning.size + 1) [] 0 0 with
     | some (.error error) => error == "kernel structure eta budget exhausted" | _ => false)
  require "projection-loop-has-no-eager-nat-stage"
    (match psKernelExprV2DefEqLazyProjReductionWithFuel 1 badDefEq noCore context cold
        succZeroId oneId pairName 0 with
     | some (.error error) => error == "TERMINAL_DEFEQ_CALLED" | _ => false)
  compareOptional "derived-projection-budget"
    (psKernelDefEqProjectionShortcut oldBadDefEq base.context psKernelCheckerStateEmpty
      (field 0 (cn "terminalAlias4")) (field 0 pairA))
    (psKernelExprV2DefEqProjectionShortcutWith badDefEq context cold aliasProjectionId field0Id)
  require "derived-projection-budget-is-not-default-fuel"
    (match psKernelExprV2DefEqProjectionShortcutWith badDefEq context cold
        aliasProjectionId field0Id with
     | some (.error error) => error == "kernel lazy-projection budget exhausted" | _ => false)
  compare "whole-owner-preserves-derived-projection-exhaustion"
    (psKernelIsDefEqWithFuel 64 base.context psKernelCheckerStateEmpty
      (field 0 (cn "terminalAlias4")) (field 0 pairA))
    (psKernelExprV2TryDefEqStateWithFuel 64 context cold aliasProjectionId field0Id)
  require "official-deep-projection-is-equal-despite-kernel-resource-sentinel"
    (match Lean.Kernel.isDefEq f.official {}
        (← officialExpr (field 0 (cn "terminalAlias4"))) (← officialExpr (field 0 pairA)) with
     | .ok true => true | _ => false)
  require "missing-body-does-not-run-projection-finish"
    (psKernelExprV2DefEqProjectionShortcutWith badDefEq context
      (initialState owning []) aliasProjectionId field0Id).isNone
  let selectedFields := fun (_ : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState)
      (l r : Nat) =>
    if l == zeroId && r == zeroId then
      some (Except.ok ({ s with nextFresh := s.nextFresh + 1 },true))
    else some (.error "WRONG_SELECTED_FIELDS")
  let selected ← expectAttempt "selected-projection-fields"
    (psKernelExprV2DefEqLazyProjFinishWith selectedFields context cold pair01Id pair02Id pairName 0)
  require "projection-finish-compares-selected-fields" (selected.snd && selected.fst.nextFresh == 1)
  let wholeValues := fun (_ : PsKernelExprV2CheckContext) (_ : PsKernelExprV2CheckState) (l r : Nat) =>
    (some (Except.error (if l == pair01Id && r == zeroId then "WHOLE_VALUES" else "MIXED_FIELD_AND_VALUE")) :
      Option (Except String (PsKernelExprV2CheckState × Bool)))
  require "one-missing-field-compares-original-values"
    (match psKernelExprV2DefEqLazyProjFinishWith wholeValues context cold pair01Id zeroId pairName 0 with
     | some (.error error) => error == "WHOLE_VALUES" | _ => false)
  let traceFields := fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (l r : Nat) =>
    let expectedLeft := if s.nextFresh == 0 then field0Id else field1Id
    let expectedRight := if s.nextFresh == 0 then zeroId else oneId
    if sameNode s l expectedLeft && r == expectedRight && c.scalar.recDepth == context.scalar.recDepth then
      some (Except.ok ({ s with nextFresh := s.nextFresh + 1 },true))
    else some (.error "ETA_FIELD_ORDER")
  let fields ← expectAttempt "eta-fields"
    (psKernelExprV2DefEqEtaStructFieldsWithFuel 3 traceFields context cold pairName pairAId [zeroId,oneId] 0 0)
  require "eta-fields-left-to-right-fixed-context" (fields.snd && fields.fst.nextFresh == 2)
  require "eta-fields-terminal-iteration-spends-own-fuel"
    (match psKernelExprV2DefEqEtaStructFieldsWithFuel 2 traceFields context cold
        pairName pairAId [zeroId,oneId] 0 0 with
     | some (.error error) => error == "kernel structure eta budget exhausted" | _ => false)
  let recursiveEta ← expectAttempt "recursive-eta-refusal"
    (psKernelExprV2DefEqEtaStructCoreWith badDefEq noInfer context cold pairAId loopCtorId)
  require "recursive-constructor-refuses-before-inference" (!recursiveEta.snd && recursiveEta.fst.nextFresh == 0)
  let traceInfer := fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (r : Nat) =>
    if c.scalar.recDepth == context.scalar.recDepth &&
        ((s.nextFresh == 0 && r == pairAId) || (s.nextFresh == 1 && r == etaId)) then
      some (Except.ok ({ s with nextFresh := s.nextFresh + 1 },pairTypeId))
    else some (.error "ETA_INFERENCE_ORDER")
  let traceEta := fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (l r : Nat) =>
    let expected := if s.nextFresh == 2 then pairTypeId
      else if s.nextFresh == 3 then field0Id else field1Id
    if c.scalar.recDepth == context.scalar.recDepth && sameNode s l expected && sameNode s r expected then
      some (Except.ok ({ s with nextFresh := s.nextFresh + 1 },true))
    else some (.error "ETA_TYPE_OR_FIELD_ORDER")
  let tracedEta ← expectAttempt "eta-trace"
    (psKernelExprV2DefEqEtaStructWith traceEta traceInfer context cold pairAId etaId)
  require "eta-types-before-fields-and-state-preserved" (tracedEta.snd && tracedEta.fst.nextFresh == 5)
  let unitInfer := fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (r : Nat) =>
    if c.scalar.recDepth == context.scalar.recDepth &&
        ((s.nextFresh == 0 && r == unitAId) || (s.nextFresh == 1 && r == unitBId)) then
      some (Except.ok ({ s with nextFresh := s.nextFresh + 1 },unitTypeId))
    else some (.error "UNIT_INFERENCE_ORDER")
  let unitWhnf := fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2WhnfState) (r : Nat) =>
    if c.scalar.recDepth == context.scalar.recDepth && r == unitTypeId then
      some (Except.ok (s,r))
    else some (.error "UNIT_WHNF_ORDER")
  let unitDefEq := fun (_ : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (l r : Nat) =>
    if s.nextFresh == 2 && l == unitTypeId && r == unitTypeId then
      some (Except.ok ({ s with nextFresh := s.nextFresh + 1 },true))
    else some (.error "UNIT_TYPE_ORDER")
  let tracedUnit ← expectAttempt "unit-trace"
    (psKernelExprV2DefEqUnitLikeWith unitDefEq unitInfer unitWhnf context cold unitAId unitBId)
  require "unit-left-whnf-before-right-and-state-preserved" (tracedUnit.snd && tracedUnit.fst.nextFresh == 3)
  require "unit-whnf-error-precedes-right-inference"
    (match psKernelExprV2DefEqUnitLikeWith unitDefEq unitInfer noWhnf context cold unitAId unitBId with
     | some (.error error) => error == "TERMINAL_WHNF_CALLED" | _ => false)
  let declineInfer := fun (_ : PsKernelExprV2CheckContext) (_ : PsKernelExprV2CheckState) (_ : Nat) =>
    (none : Option (Except String (PsKernelExprV2CheckState × Nat)))
  require "unsupported-eta-inference-propagates"
    (psKernelExprV2DefEqFinalRulesWith badDefEq declineInfer noWhnf context cold pairAId etaId).isNone
  require "unsupported-unit-inference-propagates"
    (psKernelExprV2DefEqFinalRulesWith badDefEq declineInfer noWhnf context cold unitAId unitBId).isNone
  let stageUnit ← expectAttempt "unit-stage-no-publication"
    (directFinal 64 context cold unitAId unitBId)
  require "terminal-helper-does-not-publish-original-success"
    (stageUnit.snd && !(← expect (psKernelExprV2DefEqPairContains
      stageUnit.fst.whnf.arena stageUnit.fst.success unitAId unitBId)))
  let warm ← expectAttempt "metadata-eta-owner"
    (psKernelExprV2TryDefEqStateWithFuel 64 context cold metadataId etaId)
  let oldWarm ← expect (psKernelIsDefEqWithFuel 64 base.context psKernelCheckerStateEmpty
    (.mdata 31 pairA) eta)
  require "whole-owner-publishes-original-metadata-pair"
    (warm.snd && (← expect (psKernelExprV2DefEqPairContains
      warm.fst.whnf.arena warm.fst.success metadataId etaId)))
  require "whole-owner-does-not-publish-residual-pair"
    (!(← expect (psKernelExprV2DefEqPairContains
      warm.fst.whnf.arena warm.fst.success pairAId etaId)))
  require "terminal-inference-stays-infer-only"
    (!warm.fst.inferOnly.isEmpty && warm.fst.checkedInfer.isEmpty)
  for fuel in [0,1,64] do
    for depth in [0,15,16] do
      let scalar := { base.context with maxRecDepth := 1, recDepth := depth }
      compare "warm-terminal-entry-guards"
        (psKernelIsDefEqWithFuel fuel scalar oldWarm.snd (.mdata 31 pairA) eta)
        (psKernelExprV2TryDefEqStateWithFuel fuel
          (psKernelExprV2CheckContextEmpty scalar) warm.fst metadataId etaId)
  require "missing-owner-index-never-authorized-by-terminal-rules"
    (psKernelExprV2TryDefEqWithDeclarationsFuel 64 base.context owning [] metadataId etaId).isNone

  let stringLeft := PsKernelExpr.lit (.str "left")
  let stringRight := psKernelStringLitToConstructor "right"
  let (a,stringLeftId) ← expect (psKernelExprV2PagedImportIntoChecked owning stringLeft)
  let (stringsOwning,stringRightId) ← expect (psKernelExprV2PagedImportIntoChecked a stringRight)
  let stringCold := initialState stringsOwning f.declarations
  let identityWhnf := fun (_ : PsKernelExprV2CheckContext) (s : PsKernelExprV2WhnfState) (r : Nat) =>
    some (Except.ok (s,r))
  let falseDefEq := fun (_ : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (_ _ : Nat) =>
    some (Except.ok ({ s with nextFresh := s.nextFresh + 1 },false))
  let stringFinal ← expectAttempt "string-false-final"
    (psKernelExprV2DefEqFinalRulesWith falseDefEq noInfer identityWhnf
      context stringCold stringLeftId stringRightId)
  require "string-false-stops-before-unit-inference"
    (!stringFinal.snd && stringFinal.fst.nextFresh == 1)
  require "string-whnf-error-before-defeq"
    (match psKernelExprV2DefEqStringLitExpansionWith badDefEq noWhnf
        context stringCold stringLeftId stringRightId with
     | some (.error error) => error == "TERMINAL_WHNF_CALLED" | _ => false)
  let declineWhnf := fun (_ : PsKernelExprV2CheckContext) (_ : PsKernelExprV2WhnfState) (_ : Nat) =>
    (none : Option (Except String (PsKernelExprV2WhnfState × Nat)))
  let declineDefEq := fun (_ : PsKernelExprV2CheckContext) (_ : PsKernelExprV2CheckState) (_ _ : Nat) =>
    (none : Option (Except String (PsKernelExprV2CheckState × Bool)))
  require "unsupported-string-whnf-propagates"
    (psKernelExprV2DefEqFinalRulesWith badDefEq noInfer declineWhnf
      context stringCold stringLeftId stringRightId).isNone
  require "unsupported-string-defeq-propagates"
    (psKernelExprV2DefEqFinalRulesWith declineDefEq noInfer identityWhnf
      context stringCold stringLeftId stringRightId).isNone
  for wrongShape in [
      PsKernelExpr.const psKernelStringOfListName [],
      .app (.const psKernelStringOfListName [.zero]) listNil,
      .app (.app (.const psKernelStringOfListName []) listNil) (lit 0)] do
    let (shapeArena,root) ← expect (psKernelExprV2PagedImportIntoChecked stringsOwning wrongShape)
    let refused ← expectAttempt "string-shape-guard"
      (psKernelExprV2DefEqStringLitExpansionWith badDefEq noWhnf
        context (initialState shapeArena f.declarations) stringLeftId root)
    require "string-shape-refusal-precedes-callbacks" (refused.snd.isNone && refused.fst.nextFresh == 0)
  let invalid := pair s1 (lit 0)
  let (invalidArena,invalidId) ← expect (psKernelExprV2PagedImportIntoChecked f.arena invalid)
  require "checked-batch-rejects-invalid-constructor-argument"
    (match psKernelV1RunDag empty [] .safe invalidArena (f.requests ++ [.check invalidId]) with
     | .error (.rejectedInvalid _) => true | _ => false)
  require "official-rejects-invalid-constructor-argument"
    (match Lean.Kernel.check f.official {} (← officialExpr invalid) with | .error _ => true | _ => false)
  officialInvalid := officialInvalid + 1
  let badName := nm "terminalInvalidType"
  let (badArena,badTypeId) ← expect (psKernelExprV2PagedImportIntoChecked f.arena (lit 0))
  let badRequest := PsKernelDagDeclarationRequest.axiomDecl
    (PsKernelDagConstantBase.mk badName [] badTypeId) false
  require "checked-batch-rejects-nonsort-axiom-type"
    (match psKernelV1RunDag empty [] .safe badArena (f.requests ++ [.admit badRequest]) with
     | .error (.rejectedInvalid _) => true | _ => false)
  require "failed-batch-does-not-publish"
    (psKernelEnvironmentFind f.session.environment badName).isNone
  require "official-rejects-nonsort-axiom-type"
    (match f.official.addDeclCore 0 0
        (.axiomDecl {
          name := inferOfficialName badName
          levelParams := []
          type := .lit (.natVal 0)
          isUnsafe := false
        }) none true with
     | .error _ => true | _ => false)
  officialInvalid := officialInvalid + 1
  require "complete-official-matrix" (officialValid == 21 && officialInvalid == 5 && officialStrings == 8)
  stringProjectionRegression f
  IO.println "PSC1_V2_DAG_FINAL_RULES: PASS owner=648 final=216 projection=175 stringBuild=144 stringStage=32"
  IO.println "PSC1_V2_DAG_OFFICIAL_FINAL_RULES: PASS cases=21 invalid=5 strings=8 resource=1"

def main : IO Unit := regression

