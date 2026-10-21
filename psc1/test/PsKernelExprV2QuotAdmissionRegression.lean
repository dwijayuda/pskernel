import Ps.KernelCore.API.Dag
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

/- Every successful admission fixture starts with complete checked Nat/Eq
   admission. Mutated metadata is used only for exact rejection/precedence
   controls. Raw owner helpers are not alternative untrusted APIs. -/

private def require (label : String) (condition : Bool) : IO Unit := do
  unless condition do throw (IO.userError ("PSC1_V2_QUOT_ADMISSION_FAIL " ++ label))

private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def expectPublic {α : Type} (label : String) : Except PsKernelError α → IO α
  | .ok value => pure value
  | .error (.rejectedInvalid error) => throw (IO.userError (label ++ ": invalid: " ++ error))
  | .error (.declinedUnsupported error) => throw (IO.userError (label ++ ": unsupported: " ++ error))
  | .error (.resourceExhausted _ error) => throw (IO.userError (label ++ ": resource: " ++ error))
  | .error (.internalError error) => throw (IO.userError (label ++ ": internal: " ++ error))

private def resourceTag : PsKernelResourceError → Nat
  | .fuel => 0
  | .recursionDepth => 1
  | .natSize => 2
  | .cancelled => 3
  | .declarationLimit => 4
  | .hostStack => 5

private def sameError (left right : PsKernelError) : Bool :=
  match left,right with
  | .rejectedInvalid a,.rejectedInvalid b => a == b
  | .declinedUnsupported a,.declinedUnsupported b => a == b
  | .resourceExhausted a x,.resourceExhausted b y => resourceTag a == resourceTag b && x == y
  | .internalError a,.internalError b => a == b
  | _,_ => false

private def nm (value : String) := PsKernelName.str .anonymous value
private def one := PsKernelLevel.succ PsKernelLevel.zero
private def s1 := PsKernelExpr.sort one
private def nat := PsKernelExpr.const psKernelNatName []
private def lit (value : Nat) := PsKernelExpr.lit (.nat value)
private def app := psKernelApplyArgs
private def pi (name : String) (type body : PsKernelExpr) :=
  PsKernelExpr.forallE (nm name) type body .default
private def lam (name : String) (type body : PsKernelExpr) :=
  PsKernelExpr.lam (nm name) type body .default
private def reflName := PsKernelName.str psKernelEqName "refl"
private def relation : PsKernelExpr := .app (.const psKernelEqName [one]) nat
private def eq7 := app relation [lit 7,lit 7]
private def refl7 := app (.const reflName [one]) [nat,lit 7]
private def quotient := app (.const psKernelQuotName [one]) [nat,relation]
private def mk7 := app (.const psKernelQuotMkName [one]) [nat,relation,lit 7]
private def identity := lam "x" nat (.bvar 0)
private def respect := lam "a" nat (lam "b" nat
  (lam "h" (app relation [.bvar 1,.bvar 0]) (.bvar 0)))
private def liftOf (major : PsKernelExpr) :=
  app (.const psKernelQuotLiftName [one,one]) [nat,relation,nat,identity,respect,major]
private def ind7 := app (.const psKernelQuotIndName [one])
  [nat,relation,lam "q" quotient eq7,lam "a" nat refl7,mk7]

private def natDecl : PsKernelSimpleInductiveDecl :=
  .mk [] psKernelNatName s1
    [.mk psKernelNatZeroName nat,.mk psKernelNatSuccName (pi "n" nat nat)] false 0

private def eqDecl : PsKernelSimpleInductiveDecl :=
  let universeName := nm "u"
  .mk [universeName] psKernelEqName (psKernelExpectedEqType universeName)
    [.mk reflName (psKernelExpectedEqReflType universeName)] false 2

private def importExpr (arena : PsKernelExprV2PagedArena) (expr : PsKernelExpr) :
    IO (PsKernelExprV2PagedArena × Nat) :=
  expect (psKernelExprV2PagedImportIntoChecked arena expr)

private def importOrdinary (arena : PsKernelExprV2PagedArena)
    (decl : PsKernelSimpleInductiveDecl) :
    IO (PsKernelExprV2PagedArena × PsKernelDagDeclarationRequest) := do
  let (first,typeRoot) ← importExpr arena decl.type
  let mut current := first
  let mut ctors := []
  for ctor in decl.ctors do
    let (next,root) ← importExpr current ctor.type
    current := next
    ctors := ctors ++ [PsKernelDagConstructor.mk ctor.name root]
  pure (current,.ordinaryInductive decl.levelParams decl.numParams
    (.mk decl.name typeRoot ctors) decl.isUnsafe)

private structure Fixture where
  label : String
  expr : PsKernelExpr
  expected : PsKernelExpr
  type : PsKernelExpr
  root : Nat
  expectedRoot : Nat

private structure Prepared where
  empty : PsKernelKernelSession
  withEq : PsKernelKernelSession
  withQuot : PsKernelKernelSession
  arena : PsKernelExprV2PagedArena
  input : PsKernelExprV2Decoded
  before : PsKernelDagGeneratedState
  prefix : List PsKernelDagCommand
  cases : List Fixture
  natRoot : Nat
  sortRoot : Nat
  unknownRoot : Nat

private def prepare : IO Prepared := do
  let empty ← expectPublic "empty"
    (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let withNat ← expectPublic "checked-Nat" (psKernelV1AdmitDeclaration empty (.ordinaryInductive natDecl))
  let withEq ← expectPublic "checked-Eq" (psKernelV1AdmitDeclaration withNat.session (.ordinaryInductive eqDecl))
  let withQuot ← expectPublic "independent-Quot" (psKernelV1AdmitDeclaration withEq.session .quot)
  let (first,natRequest) ← importOrdinary psKernelExprV2PagedEmpty natDecl
  let (second,eqRequest) ← importOrdinary first eqDecl
  let mut arena := second
  let mut cases := []
  for (label,expr,expected) in
      [("mk",mk7,mk7),("lift",liftOf mk7,lit 7),("ind",ind7,refl7),
       ("beta-major",liftOf (.app (lam "q" quotient (.bvar 0)) mk7),lit 7)] do
    let checked ← expectPublic (label ++ "-reference-type")
      (psKernelV1CheckExpression withQuot.session [] .safe expr)
    let (next,root) ← importExpr arena expr
    let (next,expectedRoot) ← importExpr next expected
    arena := next
    cases := cases ++ [Fixture.mk label expr expected checked.type root expectedRoot]
  let (next,natRoot) ← importExpr arena nat
  let (next,sortRoot) ← importExpr next s1
  let (finalArena,unknownRoot) ← importExpr next (.const (nm "QuotAdmissionUnknown") [])
  let input ← expect (psKernelExprV2DecodeChecked finalArena)
  let initial := PsKernelDagGeneratedState.mk finalArena input []
  let natRefs := psKernelDagDeclarationsAfterAdmission natRequest []
  let withNatOwner ← expect (psKernelDagGeneratedAfterCommandWithPrevious
    (.admit natRequest) empty.environment withNat.session.environment
    { initial with declarations := natRefs })
  let eqRefs := psKernelDagDeclarationsAfterAdmission eqRequest withNatOwner.declarations
  let before ← expect (psKernelDagGeneratedAfterCommandWithPrevious
    (.admit eqRequest) withNat.session.environment withEq.session.environment
    { withNatOwner with declarations := eqRefs })
  pure (.mk empty withEq.session withQuot.session finalArena input before
    [.admit natRequest,.admit eqRequest] cases natRoot sortRoot unknownRoot)

private def exactQuotEnvironment (label : String)
    (expected actual : PsKernelEnvironment) : IO Unit := do
  require (label ++ "-size") (psKernelEnvironmentSize expected == psKernelEnvironmentSize actual)
  require (label ++ "-initialized") (expected.quotInitialized == actual.quotInitialized)
  for name in [psKernelQuotName,psKernelQuotMkName,psKernelQuotLiftName,psKernelQuotIndName] do
    match psKernelEnvironmentFind expected name,psKernelEnvironmentFind actual name with
    | some (.quotInfo left),some (.quotInfo right) =>
        require (label ++ "-exact-live-header")
          (psKernelNameEq left.base.name right.base.name &&
           psKernelNameListsEq left.base.levelParams right.base.levelParams &&
           psKernelExprV2QuotKindEq left.kind right.kind &&
           psKernelExprEqual left.base.type right.base.type)
    | _,_ => throw (IO.userError (label ++ "-missing-live-Quot-header"))

private def compareAdmission (label : String)
    (reference : Except PsKernelError PsKernelAdmissionResult)
    (attempt : Except PsKernelError (PsKernelAdmissionResult × PsKernelDagGeneratedState)) :
    IO Unit := do
  match reference,attempt with
  | .error expected,.error actual => require (label ++ "-exact-error") (sameError expected actual)
  | .ok expected,.ok (actual,_) =>
      exactQuotEnvironment label expected.session.environment actual.session.environment
      let a := expected.declaration.receipt
      let b := actual.declaration.receipt
      require (label ++ "-exact-receipt")
        (a.declarationsBefore == b.declarationsBefore && a.declarationsAfter == b.declarationsAfter &&
         a.target.contract == b.target.contract && a.target.leanVersion == b.target.leanVersion &&
         a.target.leanCommit == b.target.leanCommit)
  | _,_ => throw (IO.userError (label ++ "-admission-outcome-class"))

private def decoded (arena : PsKernelExprV2PagedArena) (root : Nat) : IO PsKernelExpr := do
  let table ← expect (psKernelExprV2DecodeChecked arena)
  expect (psKernelExprV2DecodedRequire table root)



private def headerRegression : IO Unit := do
  let mut count := 0
  for prefixSize in [0,3,63,64,127,129] do
    let mut initial := psKernelExprV2PagedEmpty
    for _ in [:prefixSize] do
      let next ← expect (psKernelExprV2PagedMkSort initial one)
      initial := next.1
    for (u,v) in [(nm "u",nm "v"),(nm "α",nm "β"),
        (.num (nm "level") 17,.anonymous),(nm "same",nm "same")] do
      let built ← expect (psKernelDagQuotBuildHeaders initial u v)
      require "header-exact-55-append" (built.arena.size == initial.size + 55)
      require "header-four-exact-roots"
        (built.quotType == initial.size + 14 && built.mkType == initial.size + 19 &&
          built.liftType == initial.size + 38 && built.indType == initial.size + 54)
      let canonical ← expect (psKernelExprV2PagedValidate built.arena)
      let table ← expect (psKernelExprV2DecodeChecked canonical)
      for root in [:initial.size] do
        let value ← expect (psKernelExprV2DecodedRequire table root)
        require "header-preserves-prefix" (psKernelExprEqual value s1)
      for (root,expected) in
          [(built.quotType,psKernelMakeQuotType u),(built.mkType,psKernelMakeQuotMkType u),
           (built.liftType,psKernelMakeQuotLiftType u v),(built.indType,psKernelMakeQuotIndType u)] do
        let value ← expect (psKernelExprV2DecodedRequire table root)
        require "header-exact-reference-builder" (psKernelExprEqual value expected)
        require "header-closed-no-fvar"
          (!psKernelExprHasLooseBVar value && !psKernelExprHasFVar value)
      count := count + 1
  require "all-header-prefix-universe-cases" (count == 24)

private def syntaxRegression : IO Unit := do
  let u := nm "u"
  let level := PsKernelLevel.param u
  let eq := psKernelExpectedEqType u
  let refl := psKernelExpectedEqReflType u
  let rename (value : PsKernelExpr) : PsKernelExpr :=
    match value with
    | .forallE _ type body _ => .forallE (nm "renamed") type body .instImplicit
    | other => other
  let eqCases : List PsKernelExpr :=
    [eq,rename eq,
     .forallE (nm "x") (.sort level) (.forallE (nm "y") (.bvar 0)
       (.forallE (nm "z") (.bvar 1) (.sort .zero) .implicit) .strictImplicit) .default,
     .mdata 7 eq,.letE (nm "t") s1 s1 eq false,
     .forallE (nm "x") s1 (.forallE (nm "a") (.bvar 0)
       (.forallE (nm "b") (.bvar 1) (.sort .zero) .default) .default) .default,
     .forallE (nm "x") (.sort level) (.forallE (nm "a") (.bvar 1)
       (.forallE (nm "b") (.bvar 1) (.sort .zero) .default) .default) .default,
     .forallE (nm "x") (.sort level) (.forallE (nm "a") (.bvar 0)
       (.forallE (nm "b") (.bvar 0) (.sort .zero) .default) .default) .default,
     .forallE (nm "x") (.sort level) (.forallE (nm "a") (.bvar 0)
       (.forallE (nm "b") (.bvar 1) s1 .default) .default) .default,
     .forallE (nm "x") (.sort (.max level .zero)) (.forallE (nm "a") (.bvar 0)
       (.forallE (nm "b") (.bvar 1) (.sort .zero) .default) .default) .default,
     .bvar 0,.sort .zero]
  let mkRefl (head : PsKernelExpr) (args : List PsKernelExpr) : PsKernelExpr :=
    .forallE (nm "x") (.sort level)
      (.forallE (nm "a") (.bvar 0) (app head args) .default) .implicit
  let reflCases : List PsKernelExpr :=
    [refl,rename refl,
     mkRefl (.const psKernelEqName [level]) [.bvar 1,.bvar 0,.bvar 0],
     .mdata 9 refl,.letE (nm "t") s1 s1 refl false,
     mkRefl (.const psKernelEqName []) [.bvar 1,.bvar 0,.bvar 0],
     mkRefl (.const (nm "NotEq") [level]) [.bvar 1,.bvar 0,.bvar 0],
     mkRefl (.const psKernelEqName [level]) [.bvar 0,.bvar 0,.bvar 0],
     mkRefl (.const psKernelEqName [level]) [.bvar 1,.bvar 1,.bvar 0],
     mkRefl (.const psKernelEqName [level]) [.bvar 1,.bvar 0,.bvar 1],
     mkRefl (.const psKernelEqName [level]) [.bvar 1,.bvar 0],
     mkRefl (.const psKernelEqName [level]) [.bvar 1,.bvar 0,.bvar 0,.bvar 0]]
  for (expected,cases,checkType) in
      [(eq,eqCases,psKernelDagQuotCheckEqType),(refl,reflCases,psKernelDagQuotCheckReflType)] do
    for value in cases do
      let (arena,root) ← importExpr psKernelExprV2PagedEmpty value
      match checkType arena root u with
      | some actual => require "syntax-exact-ExprEq" (actual == psKernelExprEq value expected)
      | none => throw (IO.userError "canonical syntax check unexpectedly declined")
    require "invalid-root-declines"
      (checkType psKernelExprV2PagedEmpty 0 u).isNone
  require "syntax-case-count" (eqCases.length + reflCases.length == 24)


private structure GuardCase where
  label : String
  environment : PsKernelEnvironment
  state : PsKernelDagGeneratedState

private def rejectedEnvironment (infos : List PsKernelConstantInfo) : PsKernelEnvironment :=
  infos.foldl psKernelEnvironmentAddUnchecked psKernelEnvironmentEmpty

private def rejectedOwner (infos : List PsKernelConstantInfo) : IO PsKernelDagGeneratedState := do
  let mut state := PsKernelDagGeneratedState.mk psKernelExprV2PagedEmpty psKernelExprV2DecodedEmpty []
  for info in infos do
    match info with
    | .inductInfo _ | .ctorInfo _ =>
        state ← expect (psKernelDagGeneratedInstallNewInfo info [] state)
    | _ => pure ()
  pure state

private def guardCases (prepared : Prepared) : IO (List GuardCase) := do
  let some (.inductInfo eq) := psKernelEnvironmentFind prepared.withEq.environment psKernelEqName
    | throw (IO.userError "checked Eq metadata missing")
  let some (.ctorInfo refl) := psKernelEnvironmentFind prepared.withEq.environment reflName
    | throw (IO.userError "checked Eq.refl metadata missing")
  let goodEq := PsKernelConstantInfo.inductInfo eq
  let goodRefl := PsKernelConstantInfo.ctorInfo refl
  let malformed : List (String × List PsKernelConstantInfo) :=
    [("missing-Eq",[]),
     ("wrong-Eq-kind",[.axiomInfo (.mk eq.base false),goodRefl]),
     ("Eq-no-universe",[.inductInfo { eq with base := { eq.base with levelParams := [] } },goodRefl]),
     ("Eq-extra-universe",[.inductInfo { eq with base := { eq.base with levelParams := [nm "u",nm "v"] } },goodRefl]),
     ("Eq-no-ctor",[.inductInfo { eq with ctors := [] },goodRefl]),
     ("Eq-extra-ctor",[.inductInfo { eq with ctors := [reflName,nm "extra"] },goodRefl]),
     ("Eq-wrong-type",[.inductInfo { eq with base := { eq.base with type := s1 } },goodRefl]),
     ("Eq-type-before-missing-refl",[.inductInfo { eq with base := { eq.base with type := s1 } }]),
     ("missing-refl",[goodEq]),
     ("refl-no-universe",[goodEq,.ctorInfo { refl with base := { refl.base with levelParams := [] } }]),
     ("refl-extra-universe",[goodEq,.ctorInfo { refl with base := { refl.base with levelParams := [nm "u",nm "v"] } }]),
     ("refl-wrong-type",[goodEq,.ctorInfo { refl with base := { refl.base with type := s1 } }])]
  let mut rows := [GuardCase.mk "checked-positive" prepared.withEq.environment prepared.before]
  for (label,infos) in malformed do
    let environment := rejectedEnvironment infos
    require (label ++ "-reference-rejects")
      (match psKernelAddQuot environment with | .error _ => true | _ => false)
    rows := rows ++ [.mk label environment (← rejectedOwner infos)]
  for name in [psKernelQuotName,psKernelQuotMkName,psKernelQuotLiftName,psKernelQuotIndName] do
    let occupied := PsKernelAxiomInfo.mk (.mk name [] s1) false
    let admitted ← expectPublic "checked-reserved-name"
      (psKernelV1AdmitDeclaration prepared.withEq (.axiomDecl occupied))
    rows := rows ++ [.mk "reserved-name" admitted.session.environment prepared.before]
  require "seventeen-guard-rows" (rows.length == 17)
  pure rows

private def guardRegression (prepared : Prepared) : IO Unit := do
  let rows ← guardCases prepared
  let mut comparisons := 0
  for row in rows do
    match psKernelAddQuot row.environment,psKernelDagTryAddQuotOwned row.environment row.state with
    | .error expected,some (.error actual) =>
        require (row.label ++ "-raw-exact-error-order") (expected == actual)
    | .ok expected,some (.ok (actual,_)) =>
        require (row.label ++ "-only-checked-positive") (row.label == "checked-positive")
        exactQuotEnvironment row.label expected actual
    | _,none => throw (IO.userError (row.label ++ "-unexpected-raw-decline"))
    | _,_ => throw (IO.userError (row.label ++ "-raw-outcome-mismatch"))
    for fuel in [0,1,2,8,4096] do
      for depth in [0,1,64] do
        let session := PsKernelKernelSession.mk row.environment
          { prepared.withEq.resources with fuel := fuel, maxRecDepth := depth }
          prepared.withEq.provider
        compareAdmission (row.label ++ "-public-policy")
          (psKernelV1AdmitDeclaration session .quot)
          (psKernelDagAdmitDeclarationOwned session row.state .quot .quot)
        comparisons := comparisons + 1
  require "all-255-admission-resource-rows" (comparisons == 255)
  let size := psKernelEnvironmentSize prepared.withEq.environment
  for maximum in [size + 3,size + 4] do
    let session := { prepared.withEq with
      resources := { prepared.withEq.resources with maxDeclarations := maximum } }
    compareAdmission "declaration-count-after-complete-bootstrap"
      (psKernelV1AdmitDeclaration session .quot)
      (psKernelDagAdmitDeclarationOwned session prepared.before .quot .quot)
  let cancelled := { prepared.withEq with
    resources := { prepared.withEq.resources with cancelled := true, fuel := 0 } }
  compareAdmission "cancel-before-fuel-and-Quot"
    (psKernelV1AdmitDeclaration cancelled .quot)
    (psKernelDagAdmitDeclarationOwned cancelled prepared.before .quot .quot)
  let wrongProvider := { cancelled with provider :=
    { cancelled.provider with target := { cancelled.provider.target with leanVersion := "wrong" } } }
  compareAdmission "provider-before-resources-and-Quot"
    (psKernelV1AdmitDeclaration wrongProvider .quot)
    (psKernelDagAdmitDeclarationOwned wrongProvider prepared.before .quot .quot)
  require "unchanged-source-session-not-initialized"
    (!prepared.withEq.environment.quotInitialized &&
      (psKernelEnvironmentFind prepared.withEq.environment psKernelQuotName).isNone)

private def sameOwner (label : String) (expected actual : PsKernelDagGeneratedState) : IO Unit := do
  require (label ++ "-sizes") (expected.arena.size == actual.arena.size &&
    expected.built.size == actual.built.size && expected.declarations.length == actual.declarations.length)
  for (left,right) in expected.declarations.zip actual.declarations do
    require (label ++ "-original-owner-IDs")
      (psKernelNameEq left.name right.name && left.type == right.type &&
        left.deltaValue == right.deltaValue)
  for root in [:expected.built.size] do
    require (label ++ "-exact-decoded-prefix")
      (psKernelExprEqual (← expect (psKernelExprV2DecodedRequire expected.built root))
        (← expect (psKernelExprV2DecodedRequire actual.built root)))

private def ownershipRegression (prepared : Prepared) : IO PsKernelDagGeneratedState := do
  let some attempted := psKernelDagTryAddQuotOwned
      (psKernelKernelSessionEnvironment prepared.withEq) prepared.before
    | throw (IO.userError "checked same-batch Quot declined")
  let (environment,owned) ← expect attempted
  exactQuotEnvironment "direct-owned-bootstrap" prepared.withQuot.environment environment
  require "actual-55-new-nodes-and-four-owners"
    (owned.arena.size == prepared.before.arena.size + 55 &&
      owned.built.size == prepared.before.built.size + 55 &&
      owned.declarations.length == prepared.before.declarations.length + 4)
  for (name,offset) in
      [(psKernelQuotName,14),(psKernelQuotMkName,19),(psKernelQuotLiftName,38),(psKernelQuotIndName,54)] do
    let some owner := psKernelExprV2DeclarationRefFind owned.declarations name
      | throw (IO.userError "direct-bootstrap-owner-missing")
    let some info := psKernelEnvironmentFind environment name
      | throw (IO.userError "direct-bootstrap-live-info-missing")
    require "exact-private-root-and-kind"
      (owner.type == prepared.before.arena.size + offset && owner.deltaValue.isNone &&
        psKernelExprV2DeclarationRefMatches owner info)
    require "private-type-equals-published-type"
      (psKernelExprEqual (← expect (psKernelExprV2DecodedRequire owned.built owner.type))
        (psKernelConstantInfoType info))
  for root in [:prepared.input.size] do
    require "direct-publication-preserves-original-input-ID"
      (psKernelExprEqual (← expect (psKernelExprV2DecodedRequire prepared.input root))
        (← expect (psKernelExprV2DecodedRequire owned.built root)))
  let reused ← expect (psKernelDagGeneratedAfterCommandWithPrevious (.admit .quot)
    prepared.withEq.environment environment owned)
  sameOwner "bridge-reuses-direct-headers" owned reused
  for state in [owned,{ owned with declarations := [] }] do
    let some result := psKernelDagTryAddQuotOwned environment state
      | throw (IO.userError "initialized-Quot-declined")
    let (sameEnvironment,next) ← expect result
    exactQuotEnvironment "initialized" environment sameEnvironment
    sameOwner "initialized-no-op" state next
  for name in [psKernelEqName,reflName] do
    let existing := prepared.before.declarations
    let without := existing.filter fun entry => !psKernelNameEq entry.name name
    let wrongKind := existing.map fun entry =>
      if psKernelNameEq entry.name name then { entry with kind := .axiomDecl } else entry
    let dangling := existing.map fun entry =>
      if psKernelNameEq entry.name name then { entry with type := prepared.before.arena.size } else entry
    for refs in [without,wrongKind,dangling] do
      let broken := { prepared.before with declarations := refs }
      require "missing-mismatched-dangling-prerequisite-owner-declines"
        (psKernelDagTryAddQuotOwned prepared.withEq.environment broken).isNone
      compareAdmission "explicit-fallback-keeps-V1"
        (psKernelV1AdmitDeclaration prepared.withEq .quot)
        (psKernelDagAdmitDeclarationOwned prepared.withEq broken .quot .quot)
  let broken := { prepared.before with built := psKernelExprV2DecodedEmpty }
  require "incoherent-private-table-declines-before-construction"
    (psKernelDagTryAddQuotOwned prepared.withEq.environment broken).isNone
  let compatibility ← expectPublic "historical-no-carrier"
    (psKernelDagAdmitDeclaration prepared.withEq prepared.before.arena
      prepared.before.declarations .quot .quot)
  exactQuotEnvironment "historical-fallback" prepared.withQuot.environment compatibility.session.environment
  pure owned


private def checkState (generated : PsKernelDagGeneratedState) : PsKernelExprV2CheckState :=
  psKernelExprV2CheckStateWithWhnf (psKernelExprV2CheckStateEmpty generated.arena)
    (psKernelExprV2WhnfStateForDeclarations generated.arena generated.declarations)

private def compareExpr (label : String)
    (original : Except String (PsKernelExpr × PsKernelCheckerSession))
    (actual : Option (Except String (PsKernelExprV2CheckState × Nat))) : IO Unit := do
  match original,actual with
  | .error left,some (.error right) => require (label ++ "-exact-error") (left == right)
  | .ok left,some (.ok right) =>
      require (label ++ "-exact-expression")
        (psKernelExprEqual left.fst (← decoded right.fst.whnf.arena right.snd))
  | _,none => throw (IO.userError ("unexpected direct-Quot consumer decline: " ++ label))
  | _,_ => throw (IO.userError ("direct-Quot consumer outcome mismatch: " ++ label))

private def compareBool (label : String)
    (original : Except String (Bool × PsKernelCheckerSession))
    (actual : Option (Except String (PsKernelExprV2CheckState × Bool))) : IO Unit := do
  match original,actual with
  | .error left,some (.error right) => require (label ++ "-exact-error") (left == right)
  | .ok left,some (.ok right) => require (label ++ "-exact-boolean") (left.fst == right.snd)
  | _,none => throw (IO.userError ("unexpected direct-Quot equality decline: " ++ label))
  | _,_ => throw (IO.userError ("direct-Quot equality outcome mismatch: " ++ label))

private def consumerRegression (prepared : Prepared) (owned : PsKernelDagGeneratedState) : IO Unit := do
  let base := psKernelKernelSessionChecker prepared.withQuot [] .safe
  let mut rows := 0
  for fixture in prepared.cases do
    for fuel in [0,1,2,16,4096] do
      for (limit,depth) in [(0,0),(1,15),(1,16)] do
        let context := { base.context with maxRecDepth := limit, recDepth := depth }
        let scalar := { base with context := context }
        let c := psKernelExprV2CheckContextEmpty context
        compareExpr (fixture.label ++ "-check")
          (psKernelSessionCheck fuel scalar fixture.expr)
          (psKernelExprV2TryCheckStateWithFuel fuel c (checkState owned) fixture.root)
        compareExpr (fixture.label ++ "-WHNF")
          (psKernelSessionWhnf fuel scalar fixture.expr)
          (psKernelExprV2TryWhnfCheckStateWithFuel fuel c (checkState owned) fixture.root)
        compareBool (fixture.label ++ "-DefEq")
          (psKernelSessionIsDefEq fuel scalar fixture.expr fixture.expected)
          (psKernelExprV2TryDefEqStateWithFuel fuel c (checkState owned) fixture.root fixture.expectedRoot)
        rows := rows + 1
    let c := psKernelExprV2CheckContextEmpty base.context
    let some checked := psKernelExprV2TryCheckStateWithFuel 4096 c (checkState owned) fixture.root
      | throw (IO.userError "complete direct-owned check declined")
    let checked ← expect checked
    require "complete-owned-inferred-type"
      (psKernelExprEqual (← decoded checked.1.whnf.arena checked.2) fixture.type)
    let some reduced := psKernelExprV2TryWhnfCheckStateWithFuel 4096 c (checkState owned) fixture.root
      | throw (IO.userError "complete direct-owned reduction declined")
    let reduced ← expect reduced
    require "complete-owned-normal-form"
      (psKernelExprEq (← decoded reduced.1.whnf.arena reduced.2) fixture.expected)
    require "complete-owned-true-equality"
      (match psKernelExprV2TryDefEqStateWithFuel 4096 c (checkState owned)
          fixture.root fixture.expectedRoot with
       | some (.ok result) => result.2 | _ => false)
  require "sixty-raw-rows-for-each-consumer" (rows == 60)

private def samePublicFailure {α β : Type} (label : String)
    (expected : Except PsKernelError α) (actual : Except PsKernelError β) : IO Unit := do
  match expected,actual with
  | .error left,.error right => require (label ++ "-exact-typed-failure") (sameError left right)
  | _,_ => throw (IO.userError (label ++ "-expected-failure"))

private def publicRegression (prepared : Prepared) (owned : PsKernelDagGeneratedState) : IO Unit := do
  let commands := prepared.prefix ++ [.admit .quot]
  let queries := prepared.cases.flatMap fun fixture =>
    [PsKernelDagCommand.check fixture.root,.whnf fixture.root,.isDefEq fixture.root fixture.expectedRoot]
  let result ← expectPublic "complete-owned-bootstrap-and-consumers"
    (psKernelV1RunDag prepared.empty [] .safe prepared.arena (commands ++ queries))
  exactQuotEnvironment "complete-public" prepared.withQuot.environment result.session.environment
  let mut answers := result.replies.drop commands.length
  for fixture in prepared.cases do
    match answers with
    | .checked checked :: .normalized reduced :: .equal equal :: rest =>
        require (fixture.label ++ "-ordered-complete-public")
          (psKernelExprEqual checked.expression fixture.expr &&
            psKernelExprEqual checked.type fixture.type &&
            psKernelExprEq reduced fixture.expected && equal)
        answers := rest
    | _ => throw (IO.userError "wrong owned-bootstrap reply protocol")
  require "exact-twelve-query-replies" (queries.length == 12 && answers.isEmpty)
  let execution := PsKernelDagExecutionState.mk prepared.withEq prepared.before.declarations
  let raw ← expectPublic "raw-owned-command"
    (psKernelDagRunCommandOwnedWithSource prepared.input execution [] .safe
      prepared.before.arena prepared.before.built (.admit .quot))
  let some next := raw.owner | throw (IO.userError "owned command lost carrier")
  sameOwner "production-command-passes-complete-Quot-owner" owned next
  let some fixture := prepared.cases[1]? | throw (IO.userError "missing lift fixture")
  let goodName := nm "QuotAdmissionValid"
  let good := PsKernelDefinitionInfo.mk (.mk goodName [] nat) fixture.expr .abbrevHint .safe
  let goodSource := PsKernelDagDeclarationRequest.definitionDecl
    (.mk (.mk goodName [] prepared.natRoot) fixture.root .abbrevHint .safe)
  let reference ← expectPublic "V1-valid-definition"
    (psKernelV1AdmitDeclaration prepared.withQuot (.definitionDecl good))
  let actual ← expectPublic "owned-public-valid-definition"
    (psKernelV1RunDag prepared.empty [] .safe prepared.arena (commands ++ [.admit goodSource]))
  require "whole-batch-publishes-real-definition"
    (psKernelEnvironmentSize actual.session.environment == psKernelEnvironmentSize reference.session.environment &&
      (psKernelEnvironmentFind actual.session.environment goodName).isSome)
  for (name,value,root) in
      [(nm "QuotAdmissionWrongBody",s1,prepared.sortRoot),
       (nm "QuotAdmissionUnknownBody",.const (nm "QuotAdmissionUnknown") [],prepared.unknownRoot)] do
    let bad := PsKernelDefinitionInfo.mk (.mk name [] nat) value .abbrevHint .safe
    let badSource := PsKernelDagDeclarationRequest.definitionDecl
      (.mk (.mk name [] prepared.natRoot) root .abbrevHint .safe)
    samePublicFailure "real-invalid-definition"
      (psKernelV1AdmitDeclaration prepared.withQuot (.definitionDecl bad))
      (psKernelV1RunDag prepared.empty [] .safe prepared.arena (commands ++ [.admit badSource]))
  samePublicFailure "late-error-no-publication"
    (psKernelV1CheckExpression reference.session [] .safe (.const (nm "QuotAdmissionUnknown") []))
    (psKernelV1RunDag prepared.empty [] .safe prepared.arena
      (commands ++ [.admit goodSource,.check prepared.unknownRoot]))
  require "source-session-retains-no-partial-publication"
    ((psKernelEnvironmentFind prepared.empty.environment psKernelQuotName).isNone &&
      (psKernelEnvironmentFind prepared.empty.environment goodName).isNone &&
      !prepared.empty.environment.quotInitialized)
  samePublicFailure "public-missing-Eq"
    (psKernelV1AdmitDeclaration prepared.empty .quot)
    (psKernelV1RunDag prepared.empty [] .safe prepared.arena [.admit .quot])


private def invalidReference {α : Type} : Except PsKernelError α → Bool
  | .error (.rejectedInvalid message) => message == "PSKERNEL_V2_DECODE_INVALID_REFERENCE"
  | _ => false

private def namespaceRegression (prepared : Prepared) (owned : PsKernelDagGeneratedState) : IO Unit := do
  let some owner := psKernelExprV2DeclarationRefFind owned.declarations psKernelQuotName
    | throw (IO.userError "private Quot type missing")
  let root := owner.type
  require "new-owner-is-outside-original-input" (prepared.input.size ≤ root && root < owned.built.size)
  let privateHeader := PsKernelDagConstantBase.mk (nm "QuotAdmissionPrivate") [] root
  let publicHeader := PsKernelDagConstantBase.mk (nm "QuotAdmissionPrivateBody") [] prepared.natRoot
  let definition := PsKernelDagDefinition.mk publicHeader root .abbrevHint .safe
  let family := PsKernelDagInductive.mk (nm "QuotAdmissionPrivateFamily") root []
  let ctor := PsKernelDagInductive.mk (nm "QuotAdmissionPrivateFamily") prepared.sortRoot
    [.mk (nm "QuotAdmissionPrivateCtor") root]
  let commands : List PsKernelDagCommand :=
    [.check root,.whnf root,.isDefEq root prepared.natRoot,.isDefEq prepared.natRoot root,
     .admit (.axiomDecl privateHeader false),.admit (.definitionDecl definition),
     .admit (.theoremDecl publicHeader root),.admit (.opaqueDecl publicHeader root false),
     .admit (.mutualDefinitions [definition]),
     .admit (.ordinaryInductive [] 0 family false),.admit (.ordinaryInductive [] 0 ctor false),
     .admit (.mutualInductive (.mk [] 0 [family] false)),
     .admit (.nestedInductive (.mk [] 0 [ctor] false))]
  let execution := PsKernelDagExecutionState.mk prepared.withQuot owned.declarations
  let prelude := prepared.prefix ++ [.admit .quot]
  for command in commands do
    require "owned-command-never-accepts-private-ID-as-source"
      (invalidReference (psKernelDagRunCommandOwnedWithSource prepared.input execution [] .safe
        owned.arena owned.built command))
    require "owned-batch-retains-original-input"
      (invalidReference (psKernelDagRunCommandsOwnedWithSource [command] prepared.input execution
        [] .safe owned.arena owned.built))
    require "public-batch-retains-original-input"
      (invalidReference (psKernelV1RunDag prepared.empty [] .safe prepared.arena (prelude ++ [command])))
  require "all-thirteen-private-input-forms" (commands.length == 13)
  require "earlier-unsupported-before-private-ID"
    (match psKernelV1RunDag prepared.empty [] .safe prepared.arena
        (prelude ++ [.admit (.unsupported "QUOT_ADMISSION_ORDER"),.check root]) with
     | .error (.declinedUnsupported text) => text == "QUOT_ADMISSION_ORDER" | _ => false)
  require "private-ID-before-later-unsupported"
    (invalidReference (psKernelV1RunDag prepared.empty [] .safe prepared.arena
      (prelude ++ [.check root,.admit (.unsupported "QUOT_ADMISSION_ORDER")])))
  let invalidArena := { prepared.arena with size := prepared.arena.size + 1 }
  let cancelled := { prepared.empty with
    resources := { prepared.empty.resources with cancelled := true, fuel := 0 } }
  require "cancel-before-graph-and-Quot"
    (match psKernelV1RunDag cancelled [] .safe invalidArena [.admit .quot] with
     | .error (.resourceExhausted .cancelled text) =>
         text == "resource policy declined operation before entry" | _ => false)
  let zero := { prepared.empty with resources := { prepared.empty.resources with fuel := 0 } }
  require "zero-fuel-before-graph-and-Quot"
    (match psKernelV1RunDag zero [] .safe invalidArena [.admit .quot] with
     | .error (.resourceExhausted .fuel text) =>
         text == "resource policy declined operation before entry" | _ => false)
  let incompatible := { cancelled with provider := { cancelled.provider with
    target := { cancelled.provider.target with leanVersion := "wrong" } } }
  require "provider-before-resource-graph-and-Quot"
    (match psKernelV1RunDag incompatible [] .safe invalidArena [.admit .quot] with
     | .error (.declinedUnsupported text) =>
         text == "provider target does not match KernelContract-v1" | _ => false)

private def officialName : PsKernelName → Lean.Name
  | .anonymous => .anonymous
  | .str parent text => .str (officialName parent) text
  | .num parent value => .num (officialName parent) value

private def officialLevel : PsKernelLevel → Lean.Level
  | .zero => .zero
  | .succ value => .succ (officialLevel value)
  | .max left right => .max (officialLevel left) (officialLevel right)
  | .imax left right => .imax (officialLevel left) (officialLevel right)
  | .param name => .param (officialName name)
  | .mvar name => .mvar ⟨officialName name⟩

private def officialBinder : PsKernelBinderInfo → Lean.BinderInfo
  | .default => .default
  | .implicit => .implicit
  | .strictImplicit => .strictImplicit
  | .instImplicit => .instImplicit

private def officialExpr : PsKernelExpr → Lean.Expr
  | .bvar index => .bvar index
  | .fvar name => .fvar ⟨officialName name⟩
  | .mvar name => .mvar ⟨officialName name⟩
  | .sort level => .sort (officialLevel level)
  | .const name levels => .const (officialName name) (levels.map officialLevel)
  | .app fn arg => .app (officialExpr fn) (officialExpr arg)
  | .lam name domain body binder =>
      .lam (officialName name) (officialExpr domain) (officialExpr body) (officialBinder binder)
  | .forallE name domain body binder =>
      .forallE (officialName name) (officialExpr domain) (officialExpr body) (officialBinder binder)
  | .letE name type value body nondep =>
      .letE (officialName name) (officialExpr type) (officialExpr value) (officialExpr body) nondep
  | .lit (.nat value) => .lit (.natVal value)
  | .lit (.str value) => .lit (.strVal value)
  | .mdata _ body => .mdata {} (officialExpr body)
  | .proj name index body => .proj (officialName name) index (officialExpr body)



private def officialOrdinary (environment : Lean.Environment)
    (decl : PsKernelSimpleInductiveDecl) : IO Lean.Environment := do
  let type : Lean.InductiveType :=
    { name := officialName decl.name
      type := officialExpr decl.type
      ctors := decl.ctors.map fun ctor =>
        { name := officialName ctor.name, type := officialExpr ctor.type } }
  match environment.addDeclCore 0 0
      (.inductDecl (decl.levelParams.map officialName) decl.numParams [type] decl.isUnsafe)
      none true with
  | .ok next => pure next
  | .error _ => throw (IO.userError "official-fresh-inductive-admission")

private def officialRegression (prepared : Prepared) : IO Unit := do
  let empty ← Lean.mkEmptyEnvironment 0
  require "official-bootstrap-rejects-missing-Eq"
    (match empty.addDeclCore 0 0 .quotDecl none true with | .error _ => true | _ => false)
  let withNat ← officialOrdinary empty natDecl
  let withEq ← officialOrdinary withNat eqDecl
  let environment ← match withEq.addDeclCore 0 0 .quotDecl none true with
    | .ok next => pure next
    | .error _ => throw (IO.userError "official-fresh-Quot-bootstrap")
  let repeated ← match environment.addDeclCore 0 0 .quotDecl none true with
    | .ok next => pure next
    | .error _ => throw (IO.userError "official-repeat-Quot-bootstrap")
  let mut positives := 0
  for fixture in prepared.cases do
    require (fixture.label ++ "-official-check")
      (match Lean.Kernel.check repeated {} (officialExpr fixture.expr) with
       | .ok _ => true | _ => false)
    require (fixture.label ++ "-official-equality")
      (match Lean.Kernel.isDefEq repeated {}
          (officialExpr fixture.expr) (officialExpr fixture.expected) with
       | .ok true => true | _ => false)
    let definition := Lean.Declaration.defnDecl {
      name := officialName (nm ("QuotAdmissionOfficial-" ++ fixture.label))
      levelParams := []
      type := officialExpr fixture.type
      value := officialExpr fixture.expr
      hints := .abbrev
      safety := .safe
    }
    require (fixture.label ++ "-official-definition")
      (match repeated.addDeclCore 0 0 definition none true with | .ok _ => true | _ => false)
    positives := positives + 1
  for (label,body) in
      [("wrong-body",s1),("unknown-body",PsKernelExpr.const (nm "QuotAdmissionUnknown") [])] do
    let definition := Lean.Declaration.defnDecl {
      name := officialName (nm ("QuotAdmissionOfficial-" ++ label))
      levelParams := []
      type := officialExpr nat
      value := officialExpr body
      hints := .abbrev
      safety := .safe
    }
    require (label ++ "-official-refuses")
      (match repeated.addDeclCore 0 0 definition none true with | .error _ => true | _ => false)
  let occupied ← match withEq.addDeclCore 0 0
      (.axiomDecl { name := `Quot, levelParams := [], type := officialExpr s1, isUnsafe := false })
      none true with
    | .ok next => pure next
    | .error _ => throw (IO.userError "official-reserved-name-fixture")
  require "official-reserved-name-refuses-Quot"
    (match occupied.addDeclCore 0 0 .quotDecl none true with | .error _ => true | _ => false)
  require "all-four-official-positive-terms" (positives == 4)

private def regression : IO Unit := do
  headerRegression
  syntaxRegression
  let prepared ← prepare
  guardRegression prepared
  let owned ← ownershipRegression prepared
  consumerRegression prepared owned
  publicRegression prepared owned
  namespaceRegression prepared owned
  officialRegression prepared
  IO.println "PSC1_V2_QUOT_ADMISSION_PASS headers=24 syntax=24 guards=17 admissions=255 policy=4 checks=60 whnf=60 defeq=60 private=13 officialPositive=4 officialNegative=4"

def main : IO Unit := regression
