import Ps.KernelCore.API.Dag
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

/- Every positive environment comes from complete checked admission. Mutated
   metadata/owner records occur only in refusal or repair tests, never as
   authority for a successful checking fixture. -/
private def require (label : String) (condition : Bool) : IO Unit := do
  unless condition do throw (IO.userError ("PSC1_V2_QUOT_OWNER_FAIL " ++ label))

private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error message => throw (IO.userError message)

private def expectPublic {α : Type} (label : String) : Except PsKernelError α → IO α
  | .ok value => pure value
  | .error (.rejectedInvalid message) =>
      throw (IO.userError (label ++ ": rejectedInvalid: " ++ message))
  | .error (.declinedUnsupported message) =>
      throw (IO.userError (label ++ ": declinedUnsupported: " ++ message))
  | .error (.resourceExhausted _ message) =>
      throw (IO.userError (label ++ ": resourceExhausted: " ++ message))
  | .error (.internalError message) =>
      throw (IO.userError (label ++ ": internalError: " ++ message))

private def nm (text : String) := PsKernelName.str .anonymous text
private def one := PsKernelLevel.succ PsKernelLevel.zero
private def s1 := PsKernelExpr.sort one
private def nat := PsKernelExpr.const psKernelNatName []
private def lit (value : Nat) := PsKernelExpr.lit (.nat value)
private def apply := psKernelApplyArgs
private def all (name : String) (domain body : PsKernelExpr) :=
  PsKernelExpr.forallE (nm name) domain body .default
private def lam (name : String) (domain body : PsKernelExpr) :=
  PsKernelExpr.lam (nm name) domain body .default
private def refl (type value : PsKernelExpr) :=
  apply (.const (PsKernelName.str psKernelEqName "refl") [one]) [type,value]
private def relation := PsKernelExpr.app (.const psKernelEqName [one]) nat
private def equality (left right : PsKernelExpr) := apply relation [left,right]
private def quotient := apply (.const psKernelQuotName [one]) [nat,relation]
private def major (representative : PsKernelExpr) :=
  apply (.const psKernelQuotMkName [one]) [nat,relation,representative]
private def identity := lam "x" nat (.bvar 0)
private def respectIdentity := lam "a" nat (lam "b" nat
  (lam "h" (apply relation [.bvar 1,.bvar 0]) (.bvar 0)))
private def respectConstant (type value : PsKernelExpr) := lam "a" nat (lam "b" nat
  (lam "h" (apply relation [.bvar 1,.bvar 0]) (refl type value)))
private def lift (type fn respect value : PsKernelExpr) :=
  apply (.const psKernelQuotLiftName [one,one]) [nat,relation,type,fn,respect,value]
private def liftIdentity (value : PsKernelExpr) := lift nat identity respectIdentity value
private def induction (motive minor value : PsKernelExpr) :=
  apply (.const psKernelQuotIndName [one]) [nat,relation,motive,minor,value]

private def natDecl : PsKernelSimpleInductiveDecl :=
  .mk [] psKernelNatName s1
    [.mk psKernelNatZeroName nat,.mk psKernelNatSuccName (all "n" nat nat)] false 0

private def eqDecl : PsKernelSimpleInductiveDecl :=
  let universeName := nm "u"
  .mk [universeName] psKernelEqName (psKernelExpectedEqType universeName)
    [.mk (PsKernelName.str psKernelEqName "refl") (psKernelExpectedEqReflType universeName)] false 2

private def fixtureTerms : List (String × PsKernelExpr × PsKernelExpr) :=
  let major7 := major (lit 7)
  let result7 := refl nat (lit 7)
  let motive := lam "q" quotient (equality (lit 7) (lit 7))
  let minor := lam "a" nat result7
  let nestedMajor := lift quotient (lam "a" nat major7) (respectConstant quotient major7) major7
  let fnType := all "x" nat nat
  let liftFn := lift fnType (lam "a" nat identity) (respectConstant fnType identity) major7
  let motiveFn := lam "q" quotient (all "x" nat (equality (lit 7) (lit 7)))
  let minorFn := lam "a" nat (lam "x" nat result7)
  let partialLift := apply (.const psKernelQuotLiftName [one,one]) [nat,relation,nat,identity]
  let partialInd := apply (.const psKernelQuotIndName [one]) [nat,relation,motive]
  [("lift",liftIdentity major7,lit 7),
   ("ind",induction motive minor major7,result7),
   ("major-beta",liftIdentity (.app (lam "q" quotient (.bvar 0)) major7),lit 7),
   ("major-zeta",liftIdentity (.letE (nm "q") quotient major7 (.bvar 0) false),lit 7),
   ("major-metadata",liftIdentity (.mdata 31 major7),lit 7),
   ("major-nested-quot",liftIdentity nestedMajor,lit 7),
   ("ind-trailing",.app (induction motiveFn minorFn major7) (lit 9),result7),
   ("lift-trailing",.app liftFn (lit 9),lit 9),
   ("unsaturated-lift",partialLift,partialLift),
   ("unsaturated-ind",partialInd,partialInd)]

private def invalidTerms : List PsKernelExpr :=
  let major7 := major (lit 7)
  [liftIdentity (apply (.const psKernelQuotMkName [one]) [nat,relation]),
   liftIdentity (apply (.const psKernelQuotMkName [one]) [nat,relation,lit 7,lit 8]),
   liftIdentity (lit 7),
   lift nat s1 respectIdentity major7,
   apply (.const psKernelQuotLiftName []) [nat,relation,nat,identity,respectIdentity,major7]]

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
  | none => throw (IO.userError "official Quot-owner conversion")

private structure Prepared where
  empty : PsKernelKernelSession
  withNat : PsKernelKernelSession
  withEq : PsKernelKernelSession
  session : PsKernelKernelSession
  arena : PsKernelExprV2PagedArena
  commands : List PsKernelDagCommand
  stages : List PsKernelKernelSession

private def importOrdinary (arena : PsKernelExprV2PagedArena) (value : PsKernelSimpleInductiveDecl) :
    IO (PsKernelExprV2PagedArena × PsKernelDagDeclarationRequest) := do
  let (a,typeRoot) ← expect (psKernelExprV2PagedImportIntoChecked arena value.type)
  let mut arena := a
  let mut ctors := []
  for value in value.ctors do
    let (a,root) ← expect (psKernelExprV2PagedImportIntoChecked arena value.type)
    arena := a
    ctors := ctors ++ [PsKernelDagConstructor.mk value.name root]
  pure (arena,.ordinaryInductive value.levelParams value.numParams
    (.mk value.name typeRoot ctors) value.isUnsafe)

private def prepare : IO Prepared := do
  let empty ← expectPublic "empty" (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let withNat ← expectPublic "checked-Nat" (psKernelV1AdmitDeclaration empty (.ordinaryInductive natDecl))
  let withEq ← expectPublic "checked-Eq" (psKernelV1AdmitDeclaration withNat.session (.ordinaryInductive eqDecl))
  let admitted ← expectPublic "checked-Quot" (psKernelV1AdmitDeclaration withEq.session .quot)
  let (a,natRequest) ← importOrdinary psKernelExprV2PagedEmpty natDecl
  let (arena,eqRequest) ← importOrdinary a eqDecl
  pure (.mk empty withNat.session withEq.session admitted.session arena
    [.admit natRequest,.admit eqRequest,.admit .quot]
    [withNat.session,withEq.session,admitted.session])

private structure Fixture where
  label : String
  expr : PsKernelExpr
  expected : PsKernelExpr
  type : PsKernelExpr
  root : Nat
  expectedRoot : Nat
  typeRoot : Nat

private structure Inputs where
  arena : PsKernelExprV2PagedArena
  built : PsKernelExprV2Decoded
  cases : List Fixture
  invalids : List (PsKernelExpr × Nat)
  natId : Nat
  sortId : Nat
  missingId : Nat

private def prepareInputs (prepared : Prepared) : IO Inputs := do
  let mut arena := prepared.arena
  let mut cases : List Fixture := []
  for (label,expr,expected) in fixtureTerms do
    let checked ← expectPublic (label ++ "-V1-check") (psKernelV1CheckExpression prepared.session [] .safe expr)
    let (a,root) ← expect (psKernelExprV2PagedImportIntoChecked arena expr)
    let (a,target) ← expect (psKernelExprV2PagedImportIntoChecked a expected)
    let (a,typeRoot) ← expect (psKernelExprV2PagedImportIntoChecked a checked.type)
    arena := a
    cases := cases ++ [Fixture.mk label expr expected checked.type root target typeRoot]
  let mut invalids := []
  for expr in invalidTerms do
    let (a,root) ← expect (psKernelExprV2PagedImportIntoChecked arena expr)
    arena := a
    invalids := invalids ++ [(expr,root)]
  let (a,natId) ← expect (psKernelExprV2PagedImportIntoChecked arena nat)
  let (a,sortId) ← expect (psKernelExprV2PagedImportIntoChecked a s1)
  let (finalArena,missingId) ← expect (psKernelExprV2PagedImportIntoChecked a
    (.const (nm "QuotOwnerMissingDependency") []))
  let built ← expect (psKernelExprV2DecodeChecked finalArena)
  pure (.mk finalArena built cases invalids natId sortId missingId)

private def installedOwner (prepared : Prepared) (input : Inputs) (limit : Nat) :
    IO PsKernelDagGeneratedState := do
  let mut generated := PsKernelDagGeneratedState.mk input.arena input.built []
  for (command,stage) in (prepared.commands.zip prepared.stages).take limit do
    let next := match command with
      | .admit request => psKernelDagDeclarationsAfterAdmission request generated.declarations
      | _ => generated.declarations
    generated ← expect (psKernelDagGeneratedAfterCommand command stage.environment
      { generated with declarations := next })
  pure generated

private def decode (arena : PsKernelExprV2PagedArena) (root : Nat) : IO PsKernelExpr := do
  let built ← expect (psKernelExprV2DecodeChecked arena)
  expect (psKernelExprV2DecodedRequire built root)

private def checkState (generated : PsKernelDagGeneratedState) : PsKernelExprV2CheckState :=
  psKernelExprV2CheckStateWithWhnf (psKernelExprV2CheckStateEmpty generated.arena)
    (psKernelExprV2WhnfStateForDeclarations generated.arena generated.declarations)

private def sameRejection {α β : Type} (label : String)
    (original : Except PsKernelError α) (actual : Except PsKernelError β) : IO Unit := do
  match original,actual with
  | .error (.rejectedInvalid left),.error (.rejectedInvalid right) =>
      require (label ++ "-exact-rejection") (left == right)
  | _,_ => throw (IO.userError ("expected invalid rejection: " ++ label))

private def unchanged (label : String) (before after : PsKernelDagGeneratedState) : IO Unit := do
  require (label ++ "-no-append")
    (after.arena.size == before.arena.size && after.built.size == before.built.size &&
      after.declarations.length == before.declarations.length)
  for (left,right) in before.declarations.zip after.declarations do
    require (label ++ "-same-owner")
      (psKernelNameEq left.name right.name && left.type == right.type &&
        left.deltaValue == right.deltaValue)

private def quotientInfos (session : PsKernelKernelSession) : IO (List PsKernelQuotInfo) := do
  let mut infos := []
  for (name,kind) in
      [(psKernelQuotName,PsKernelQuotKind.typeQ),(psKernelQuotMkName,.ctorQ),
       (psKernelQuotLiftName,.liftQ),(psKernelQuotIndName,.indQ)] do
    match psKernelEnvironmentFind session.environment name with
    | some (.quotInfo value) =>
        require "live-quot-name-and-kind"
          (psKernelNameEq value.base.name name && psKernelExprV2QuotKindEq value.kind kind)
        infos := infos ++ [value]
    | _ => throw (IO.userError "missing checked Quot metadata")
  pure infos

private def exactOwners (session : PsKernelKernelSession) (generated : PsKernelDagGeneratedState) :
    IO Unit := do
  for value in (← quotientInfos session) do
    let some owner := psKernelExprV2DeclarationRefFind generated.declarations value.base.name
      | throw (IO.userError "missing Quot owner")
    require "owned-kind-levels-and-no-delta"
      (psKernelExprV2DeclarationRefMatches owner (.quotInfo value) && owner.deltaValue.isNone)
    require "exact-admitted-Quot-type"
      (psKernelExprEqual (← expect (psKernelExprV2DecodedRequire generated.built owner.type)) value.base.type)
    require "exact-arena-and-decoded-Quot-type"
      (psKernelExprEqual (← decode generated.arena owner.type) value.base.type)
    require "idempotence-guard-uses-exact-live-info" (psKernelDagGeneratedQuotOwnerMatches value generated)

private def metadataRegression (prepared : Prepared) (input : Inputs)
    (before generated : PsKernelDagGeneratedState) : IO Unit := do
  require "all-four-owners-published"
    (generated.declarations.length == before.declarations.length + 4 &&
      generated.arena.size > before.arena.size && generated.built.size == generated.arena.size)
  exactOwners prepared.session generated
  for root in List.range input.arena.size do
    require "immutable-source-prefix"
      (psKernelExprEqual (← expect (psKernelExprV2DecodedRequire input.built root))
        (← expect (psKernelExprV2DecodedRequire generated.built root)))
  for value in (← quotientInfos prepared.session) do
    let some owner := psKernelExprV2DeclarationRefFind generated.declarations value.base.name
      | throw (IO.userError "missing private Quot type")
    require "all-Quot-types-are-private-appended-IDs" (before.arena.size ≤ owner.type)
  let repeated ← expectPublic "idempotent-checked-Quot" (psKernelV1AdmitDeclaration prepared.session .quot)
  let again ← expect (psKernelDagGeneratedAfterCommand (.admit .quot) repeated.session.environment generated)
  unchanged "repeated-Quot" generated again
  let context := psKernelExprV2CheckContextEmpty (psKernelKernelSessionChecker prepared.session [] .safe).context
  for fixture in input.cases do
    require (fixture.label ++ "-owner-was-previously-missing")
      (psKernelExprV2TryCheckStateWithFuel 4096 context (checkState before) fixture.root).isNone
  let some selected := psKernelExprV2DeclarationRefFind generated.declarations psKernelQuotName
    | throw (IO.userError "missing repair target")
  let repairs : List (String × List PsKernelExprV2DeclarationRef) :=
    [("missing",generated.declarations.filter (fun owner => !psKernelNameEq owner.name psKernelQuotName)),
     ("wrong-kind",generated.declarations.map (fun owner =>
       if psKernelNameEq owner.name psKernelQuotName then { owner with kind := .axiomDecl } else owner)),
     ("wrong-type",generated.declarations.map (fun owner =>
       if psKernelNameEq owner.name psKernelQuotName then { owner with type := input.natId } else owner)),
     ("delta-body",generated.declarations.map (fun owner =>
       if psKernelNameEq owner.name psKernelQuotName then { owner with deltaValue := some input.natId } else owner)),
     ("dangling-type",generated.declarations.map (fun owner =>
       if psKernelNameEq owner.name psKernelQuotName then { owner with type := generated.built.size } else owner))]
  for (label,owners) in repairs do
    let damaged := { generated with declarations := owners }
    let repaired ← expect (psKernelDagGeneratedAfterCommand (.admit .quot) prepared.session.environment damaged)
    require (label ++ "-cannot-elide-import")
      (repaired.arena.size > damaged.arena.size && repaired.declarations.length == damaged.declarations.length + 4)
    exactOwners prepared.session repaired
    let retained ← expect (psKernelDagGeneratedAfterCommand (.admit .quot) prepared.session.environment repaired)
    unchanged (label ++ "-repaired-idempotence") repaired retained
  require "repair-controls-retain-original-owner" (selected.type < generated.built.size && repairs.length == 5)

private def planRegression (prepared : Prepared) (before : PsKernelDagGeneratedState) : IO Unit := do
  let environment := prepared.session.environment
  let some plan := psKernelDagGeneratedPlanQuot environment
    | throw (IO.userError "missing complete live Quot plan")
  require "plan-has-all-four-before-import" (plan.length == 4)
  let emptyMarked := psKernelEnvironmentMarkQuotInitialized psKernelEnvironmentEmpty
  let mut environments := [("uninitialized",{ environment with quotInitialized := false }),
    ("initialized-without-metadata",emptyMarked)]
  for value in (← quotientInfos prepared.session) do
    let constants := environment.constants.filter
      (fun info => !psKernelNameEq (psKernelConstantInfoName info) value.base.name)
    let missing := constants.foldl psKernelEnvironmentAddUnchecked psKernelEnvironmentEmpty
    environments := environments ++ [("missing-one",psKernelEnvironmentMarkQuotInitialized missing)]
    let wrongKind := if psKernelExprV2QuotKindEq value.kind .typeQ then PsKernelQuotKind.ctorQ else .typeQ
    let wrong := psKernelEnvironmentReplaceUnchecked environment (.quotInfo { value with kind := wrongKind })
    environments := environments ++ [("wrong-kind",wrong)]
  for (label,environment) in environments do
    require (label ++ "-complete-plan-refuses") (psKernelDagGeneratedPlanQuot environment).isNone
    let after ← expect (psKernelDagGeneratedAfterCommand (.admit .quot) environment before)
    unchanged (label ++ "-atomic-no-publication") before after
  require "ten-plan-refusal-controls" (environments.length == 10)

private def compareExpr (label : String)
    (original : Except String (PsKernelExpr × PsKernelCheckerSession))
    (actual : Option (Except String (PsKernelExprV2CheckState × Nat))) : IO Unit := do
  match original,actual with
  | .error left,some (.error right) => require (label ++ "-exact-error") (left == right)
  | .ok left,some (.ok right) =>
      require (label ++ "-exact-expression")
        (psKernelExprEqual left.fst (← decode right.fst.whnf.arena right.snd))
  | _,none => throw (IO.userError ("unexpected Quot-owner fallback: " ++ label))
  | _,_ => throw (IO.userError ("Quot-owner result mismatch: " ++ label))

private def compareBool (label : String)
    (original : Except String (Bool × PsKernelCheckerSession))
    (actual : Option (Except String (PsKernelExprV2CheckState × Bool))) : IO Unit := do
  match original,actual with
  | .error left,some (.error right) => require (label ++ "-exact-error") (left == right)
  | .ok left,some (.ok right) => require (label ++ "-exact-boolean") (left.fst == right.snd)
  | _,none => throw (IO.userError ("unexpected Quot-owner DefEq fallback: " ++ label))
  | _,_ => throw (IO.userError ("Quot-owner DefEq result mismatch: " ++ label))

private def differentialRegression (prepared : Prepared) (input : Inputs)
    (generated : PsKernelDagGeneratedState) : IO Unit := do
  let base := psKernelKernelSessionChecker prepared.session [] .safe
  let mut checks := 0
  let mut reductions := 0
  let mut equalities := 0
  for fixture in input.cases do
    for fuel in [0,1,2,4,16,64] do
      for (limit,depth) in [(0,0),(1,15),(1,16)] do
        let context := { base.context with maxRecDepth := limit,recDepth := depth }
        let scalar := { base with context := context }
        let ownedContext := psKernelExprV2CheckContextEmpty context
        compareExpr (fixture.label ++ "-check")
          (psKernelSessionCheck fuel scalar fixture.expr)
          (psKernelExprV2TryCheckStateWithFuel fuel ownedContext (checkState generated) fixture.root)
        checks := checks + 1
        compareExpr (fixture.label ++ "-WHNF")
          (psKernelSessionWhnf fuel scalar fixture.expr)
          (psKernelExprV2TryWhnfCheckStateWithFuel fuel ownedContext (checkState generated) fixture.root)
        reductions := reductions + 1
        compareBool (fixture.label ++ "-DefEq")
          (psKernelSessionIsDefEq fuel scalar fixture.expr fixture.expected)
          (psKernelExprV2TryDefEqStateWithFuel fuel ownedContext (checkState generated)
            fixture.root fixture.expectedRoot)
        equalities := equalities + 1
    let context := psKernelExprV2CheckContextEmpty base.context
    let checked ← match psKernelExprV2TryCheckStateWithFuel 4096 context (checkState generated) fixture.root with
      | some result => expect result
      | none => throw (IO.userError ("missing complete Quot-owned check: " ++ fixture.label))
    require (fixture.label ++ "-owned-inferred-type")
      (psKernelExprEqual (← decode checked.fst.whnf.arena checked.snd) fixture.type)
    let reduced ← match psKernelExprV2TryWhnfCheckStateWithFuel 4096 context (checkState generated) fixture.root with
      | some result => expect result
      | none => throw (IO.userError ("missing complete Quot-owned WHNF: " ++ fixture.label))
    require (fixture.label ++ "-owned-WHNF-value")
      (psKernelExprEq (← decode reduced.fst.whnf.arena reduced.snd) fixture.expected)
    require (fixture.label ++ "-owned-DefEq-success")
      (match psKernelExprV2TryDefEqStateWithFuel 4096 context (checkState generated)
          fixture.root fixture.expectedRoot with
       | some (.ok result) => result.snd | _ => false)
  let mut invalidChecks := 0
  for (expr,root) in input.invalids do
    for fuel in [0,1,2,4,16,64] do
      for (limit,depth) in [(0,0),(1,15),(1,16)] do
        let context := { base.context with maxRecDepth := limit,recDepth := depth }
        compareExpr "invalid-checked-Quot"
          (psKernelSessionCheck fuel { base with context := context } expr)
          (psKernelExprV2TryCheckStateWithFuel fuel (psKernelExprV2CheckContextEmpty context)
            (checkState generated) root)
        invalidChecks := invalidChecks + 1
    require "invalid-never-becomes-success"
      (match psKernelExprV2TryCheckStateWithFuel 4096 (psKernelExprV2CheckContextEmpty base.context)
          (checkState generated) root with
       | some (.error _) => true | _ => false)
  require "complete-resource-matrices"
    (checks == 180 && reductions == 180 && equalities == 180 && invalidChecks == 90)

private def definition (name : String) (type value : PsKernelExpr) : PsKernelDefinitionInfo :=
  .mk (.mk (nm name) [] type) value .abbrevHint .safe

private def sourceDefinition (name : String) (type value : Nat) : PsKernelDagDeclarationRequest :=
  .definitionDecl (.mk (.mk (nm name) [] type) value .abbrevHint .safe)

private def directAdmission (label : String) (prepared : Prepared)
    (generated : PsKernelDagGeneratedState) (source : PsKernelDagDeclarationRequest)
    (value : PsKernelDefinitionInfo) (valid : Bool) : IO Unit := do
  let resources := prepared.session.resources
  let environment := psKernelKernelSessionEnvironment prepared.session
  let original := psKernelAddDefinition resources.fuel environment value
    resources.maxRecDepth resources.maxNatSize
  let actual := psKernelDagTryAdmitSimpleWithFuel resources.fuel environment
    resources.maxRecDepth resources.maxNatSize generated.arena generated.declarations
    source (.definitionDecl value)
  match original,actual with
  | .error left,some (.error right) =>
      require (label ++ "-exact-admission-error") (!valid && left == right)
  | .ok left,some (.ok right) =>
      require (label ++ "-real-admission") (valid && psKernelEnvironmentSize left == psKernelEnvironmentSize right)
      match psKernelEnvironmentFind right value.base.name with
      | some (.defnInfo admitted) =>
          require (label ++ "-actual-checked-definition")
            (psKernelExprEqual admitted.base.type value.base.type &&
              psKernelExprEqual admitted.value value.value &&
              psKernelNameListsEq admitted.base.levelParams value.base.levelParams)
      | _ => throw (IO.userError "direct Quot-owned admission omitted definition")
  | _,none => throw (IO.userError ("unexpected Quot-owned admission fallback: " ++ label))
  | _,_ => throw (IO.userError ("Quot-owned admission mismatch: " ++ label))

private def negativeDefinitions (input : Inputs) :
    List (String × PsKernelExpr × PsKernelExpr × Nat × Nat) :=
  let invalids := input.invalids.zipIdx |>.map fun ((expr,root),index) =>
    ("QuotOwnerInvalid" ++ toString index,nat,expr,input.natId,root)
  match input.cases with
  | [] => invalids
  | first :: _ =>
      invalids ++
        [("QuotOwnerWrongType",s1,first.expr,input.sortId,first.root),
         ("QuotOwnerMissingValue",nat,.const (nm "QuotOwnerMissingDependency") [],input.natId,input.missingId)]

private def admissionRegression (prepared : Prepared) (input : Inputs)
    (generated : PsKernelDagGeneratedState) : IO Unit := do
  let mut admittedCommands := []
  let mut admissions := 0
  for fixture in input.cases do
    let label := "QuotOwnerValid-" ++ fixture.label
    let source := sourceDefinition label fixture.typeRoot fixture.root
    directAdmission label prepared generated source (definition label fixture.type fixture.expr) true
    admittedCommands := admittedCommands ++ [.admit source]
    admissions := admissions + 1
  let complete ← expectPublic "all-ten-real-Quot-definitions"
    (psKernelV1RunDag prepared.empty [] .safe input.arena (prepared.commands ++ admittedCommands))
  require "complete-batch-has-all-admission-replies" (complete.replies.length == 13)
  for fixture in input.cases do
    require "completed-batch-publishes-real-definition"
      (match psKernelEnvironmentFind complete.session.environment (nm ("QuotOwnerValid-" ++ fixture.label)) with
       | some (.defnInfo _) => true | _ => false)
  for (label,type,value,typeRoot,valueRoot) in negativeDefinitions input do
    let info := definition label type value
    let source := sourceDefinition label typeRoot valueRoot
    directAdmission label prepared generated source info false
    sameRejection label (psKernelV1AdmitDeclaration prepared.session (.definitionDecl info))
      (psKernelV1RunDag prepared.empty [] .safe input.arena (prepared.commands ++ [.admit source]))
    require (label ++ "-no-publication") (psKernelEnvironmentFind prepared.session.environment (nm label)).isNone
    admissions := admissions + 1
  require "seventeen-actual-direct-admissions" (admissions == 17)
  require "Quot-admission-itself-remains-validated-V1"
    (psKernelDagTryAdmitSimpleWithFuel prepared.session.resources.fuel prepared.withEq.environment
      prepared.session.resources.maxRecDepth prepared.session.resources.maxNatSize
      generated.arena generated.declarations .quot .quot).isNone

private def publicRegression (prepared : Prepared) (input : Inputs) : IO Unit := do
  let mut queries := []
  for fixture in input.cases do
    queries := queries ++ [.check fixture.root,.whnf fixture.root,
      .isDefEq fixture.root fixture.expectedRoot]
  let result ← expectPublic "complete-Quot-owner-batch"
    (psKernelV1RunDag prepared.empty [] .safe input.arena (prepared.commands ++ queries))
  let mut answers := result.replies.drop prepared.commands.length
  for fixture in input.cases do
    match answers with
    | .checked checked :: .normalized reduced :: .equal equal :: rest =>
        require (fixture.label ++ "-public-check")
          (psKernelExprEqual checked.type fixture.type && psKernelExprEqual checked.expression fixture.expr)
        require (fixture.label ++ "-public-WHNF") (psKernelExprEq reduced fixture.expected)
        require (fixture.label ++ "-public-DefEq") equal
        answers := rest
    | _ => throw (IO.userError "incomplete public Quot-owner protocol")
  require "exact-public-thirty-reply-protocol" (answers.isEmpty && queries.length == 30)
  for (expr,root) in input.invalids do
    sameRejection "invalid-Quot-public-WHNF"
      (psKernelV1Whnf prepared.session [] .safe expr)
      (psKernelV1RunDag prepared.empty [] .safe input.arena (prepared.commands ++ [.whnf root]))
  let repeated ← expectPublic "public-repeated-Quot"
    (psKernelV1RunDag prepared.empty [] .safe input.arena
      (prepared.commands ++ [.admit .quot,.admit .quot]))
  require "public-repeat-preserves-environment-size"
    (psKernelEnvironmentSize repeated.session.environment == psKernelEnvironmentSize prepared.session.environment)

private def invalidReference {α : Type} : Except PsKernelError α → Bool
  | .error (.rejectedInvalid message) => message == "PSKERNEL_V2_DECODE_INVALID_REFERENCE"
  | _ => false

private def namespaceRegression (prepared : Prepared) (input : Inputs)
    (generated : PsKernelDagGeneratedState) : IO Unit := do
  let some quotientOwner := psKernelExprV2DeclarationRefFind generated.declarations psKernelQuotName
    | throw (IO.userError "missing private namespace target")
  let privateId := quotientOwner.type
  require "private-target-is-real-new-Quot-type" (input.arena.size ≤ privateId && privateId < generated.built.size)
  let privateHeader := PsKernelDagConstantBase.mk (nm "QuotPrivateHeader") [] privateId
  let publicHeader := PsKernelDagConstantBase.mk (nm "QuotPrivateBody") [] input.natId
  let privateDefinition := PsKernelDagDefinition.mk publicHeader privateId .abbrevHint .safe
  let badHeader := PsKernelDagInductive.mk (nm "QuotPrivateFamily") privateId []
  let badCtor := PsKernelDagInductive.mk (nm "QuotPrivateFamily") input.sortId
    [.mk (nm "QuotPrivateCtor") privateId]
  let commands : List PsKernelDagCommand :=
    [.check privateId,.whnf privateId,.isDefEq privateId input.natId,.isDefEq input.natId privateId,
     .admit (.axiomDecl privateHeader false),.admit (.definitionDecl privateDefinition),
     .admit (.theoremDecl publicHeader privateId),.admit (.opaqueDecl publicHeader privateId false),
     .admit (.mutualDefinitions [privateDefinition]),
     .admit (.ordinaryInductive [] 0 badHeader false),.admit (.ordinaryInductive [] 0 badCtor false),
     .admit (.mutualInductive (.mk [] 0 [badHeader] false)),
     .admit (.nestedInductive (.mk [] 0 [badCtor] false))]
  for command in commands do
    require "public-private-Quot-ID-remains-invalid"
      (invalidReference (psKernelV1RunDag prepared.empty [] .safe input.arena (prepared.commands ++ [command])))
    require "worker-retains-original-input-namespace"
      (invalidReference (psKernelDagRunCommandWithSource input.built
        (.mk prepared.session generated.declarations) [] .safe generated.arena generated.built command))
  require "all-thirteen-private-Quot-input-forms" (commands.length == 13)
  require "earlier-error-precedes-private-ID"
    (match psKernelV1RunDag prepared.empty [] .safe input.arena
        (prepared.commands ++ [.admit (.unsupported "QUOT_OWNER_ORDER"),.check privateId]) with
     | .error (.declinedUnsupported message) => message == "QUOT_OWNER_ORDER" | _ => false)
  require "private-ID-precedes-later-error"
    (invalidReference (psKernelV1RunDag prepared.empty [] .safe input.arena
      (prepared.commands ++ [.check privateId,.admit (.unsupported "QUOT_OWNER_ORDER")])))
  require "failed-batch-has-no-published-session"
    ((psKernelEnvironmentFind prepared.empty.environment psKernelQuotName).isNone &&
      !prepared.empty.environment.quotInitialized && !prepared.withEq.environment.quotInitialized)
  let _ ← expectPublic "fresh-batch-after-failure"
    (psKernelV1RunDag prepared.empty [] .safe input.arena prepared.commands)
  pure ()

private def failedAdmissionRegression (prepared : Prepared) (input : Inputs) : IO Unit := do
  sameRejection "Quot-without-Eq"
    (psKernelV1AdmitDeclaration prepared.empty .quot)
    (psKernelV1RunDag prepared.empty [] .safe input.arena [.admit .quot])
  let wrongEq := PsKernelSimpleInductiveDecl.mk [] psKernelEqName s1
    [.mk (PsKernelName.str psKernelEqName "bad") (.const psKernelEqName [])] false 0
  let wrong ← expectPublic "checked-non-equality-Eq"
    (psKernelV1AdmitDeclaration prepared.empty (.ordinaryInductive wrongEq))
  let (wrongArena,wrongRequest) ← importOrdinary psKernelExprV2PagedEmpty wrongEq
  sameRejection "Quot-requires-correct-Eq-shape"
    (psKernelV1AdmitDeclaration wrong.session .quot)
    (psKernelV1RunDag prepared.empty [] .safe wrongArena [.admit wrongRequest,.admit .quot])
  let occupied := PsKernelAxiomInfo.mk (.mk psKernelQuotName [] s1) false
  let reserved ← expectPublic "checked-reserved-Quot-name"
    (psKernelV1AdmitDeclaration prepared.withEq (.axiomDecl occupied))
  let reservedRequest := PsKernelDagDeclarationRequest.axiomDecl (.mk psKernelQuotName [] input.sortId) false
  sameRejection "Quot-requires-free-reserved-names"
    (psKernelV1AdmitDeclaration reserved.session .quot)
    (psKernelV1RunDag prepared.empty [] .safe input.arena
      (prepared.commands.take 2 ++ [.admit reservedRequest,.admit .quot]))
  require "failed-Quot-never-marks-original-environment"
    (!wrong.session.environment.quotInitialized && !reserved.session.environment.quotInitialized &&
      (psKernelEnvironmentFind prepared.withEq.environment psKernelQuotName).isNone)

private def officialRegression (input : Inputs) : IO Unit := do
  Lean.initSearchPath (← Lean.findSysroot)
  let official ← Lean.importModules #[{ module := `Init }] {}
  let mut positives := 0
  let mut negatives := 0
  for fixture in input.cases do
    let term ← officialExpr fixture.expr
    require (fixture.label ++ "-official-check")
      (match Lean.Kernel.check official {} term with | .ok _ => true | _ => false)
    require (fixture.label ++ "-official-DefEq")
      (match Lean.Kernel.isDefEq official {} term (← officialExpr fixture.expected) with
       | .ok true => true | _ => false)
    let declaration := Lean.Declaration.defnDecl {
      name := inferOfficialName (nm ("QuotOwnerValid-" ++ fixture.label))
      levelParams := []
      type := ← officialExpr fixture.type
      value := term
      hints := .abbrev
      safety := .safe
    }
    require (fixture.label ++ "-official-real-definition")
      (match official.addDeclCore 0 0 declaration none true with | .ok _ => true | _ => false)
    positives := positives + 1
  for (label,type,value,_,_) in negativeDefinitions input do
    let declaration := Lean.Declaration.defnDecl {
      name := inferOfficialName (nm label)
      levelParams := []
      type := ← officialExpr type
      value := ← officialExpr value
      hints := .abbrev
      safety := .safe
    }
    require (label ++ "-official-rejects-definition")
      (match official.addDeclCore 0 0 declaration none true with | .error _ => true | _ => false)
    negatives := negatives + 1
  require "complete-official-matrix" (positives == 10 && negatives == 7)

private def regression : IO Unit := do
  let prepared ← prepare
  let input ← prepareInputs prepared
  require "ten-valid-and-five-invalid-Quot-cases" (input.cases.length == 10 && input.invalids.length == 5)
  let before ← installedOwner prepared input 2
  let generated ← installedOwner prepared input 3
  metadataRegression prepared input before generated
  planRegression prepared before
  differentialRegression prepared input generated
  admissionRegression prepared input generated
  publicRegression prepared input
  namespaceRegression prepared input generated
  failedAdmissionRegression prepared input
  officialRegression input
  IO.println "PSC1_V2_QUOT_OWNER_PASS owners=4 cases=10 checks=180 whnf=180 defeq=180 invalidChecks=90 admissions=17 plans=10 repairs=5 private=13 officialPositive=10 officialNegative=7"

def main : IO Unit := regression
