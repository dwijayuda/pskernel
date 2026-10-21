import Ps.KernelCore.API.Dag
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

private def require (label : String) (condition : Bool) : IO Unit := do
  unless condition do throw (IO.userError ("PSC1_V2_RECURSOR_FAIL " ++ label))

private def expect {α : Type} : Except String α → IO α
  | .ok result => pure result
  | .error error => throw (IO.userError error)

private def expectPublic {α : Type} : Except PsKernelError α → IO α
  | .ok result => pure result
  | .error _ => throw (IO.userError "recursor fixture public failure")

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
private def box := apply (.const boxName [one]) [nat]
private def boxMajor := apply (.const boxCtorName [one]) [nat,lit 5]
private def natMotive := lam "n" nat nat
private def natStep := lam "n" nat (lam "ih" nat (.bvar 0))
private def natRec (major : PsKernelExpr) :=
  apply (.const natRecName [one]) [natMotive,lit 7,natStep,major]
private def boxRec (motive minor : PsKernelExpr) :=
  apply (.const boxRecName [one,one]) [nat,motive,minor,boxMajor]

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

private def prepareInductive (prior : Prepared) (decl : PsKernelSimpleInductiveDecl) :
    IO Prepared := do
  let admitted ← expectPublic (psKernelV1AdmitDeclaration prior.session (.ordinaryInductive decl))
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

private def regression : IO Unit := do
  let empty ← expectPublic (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let natDecl := PsKernelSimpleInductiveDecl.mk [] psKernelNatName s1
    [PsKernelSimpleConstructorDecl.mk psKernelNatZeroName nat,
     PsKernelSimpleConstructorDecl.mk psKernelNatSuccName (forallE "n" nat nat)] false 0
  let u := nm "u"
  let boxType := forallE "A" (.sort (.param u)) (.sort (.param u))
  let boxCtorType := forallE "A" (.sort (.param u))
    (forallE "value" (.bvar 0) (apply (.const boxName [.param u]) [.bvar 1]))
  let boxDecl := PsKernelSimpleInductiveDecl.mk [u] boxName boxType
    [PsKernelSimpleConstructorDecl.mk boxCtorName boxCtorType] false 1
  let kName := nm "IotaK"
  let kCtorName := PsKernelName.str kName "mk"
  let kType := PsKernelExpr.const kName []
  let kDecl := PsKernelSimpleInductiveDecl.mk [] kName (.sort .zero)
    [PsKernelSimpleConstructorDecl.mk kCtorName kType] false 0
  let first ← prepareInductive (Prepared.mk empty psKernelExprV2PagedEmpty [] []) natDecl
  let second ← prepareInductive first boxDecl
  let prepared ← prepareInductive second kDecl
  let session := prepared.session
  let natInfo ← recursorInfo session natRecName
  let boxInfo ← recursorInfo session boxRecName
  let kInfo ← recursorInfo session (psKernelSimpleRecName kName)
  require "actual-checked-non-K-and-K-metadata" (!natInfo.k && !boxInfo.k && kInfo.k)
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
    apply (.const boxRecName [one,one]) [nat,lam "box" box nat,s1,boxMajor]]
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
  for info in [natInfo,boxInfo] do
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
  require "K-owner-remains-explicitly-unsupported"
    (psKernelExprV2DeclarationRefFind generated.declarations kInfo.base.name).isNone
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
    let checked ← expectPublic (psKernelV1Whnf session [] .safe expr)
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

  let replay ← expectPublic (psKernelV1RunDag empty [] .safe input
    (prepared.commands ++ cases.map (fun (_,_,_,root) => .whnf root)))
  let answers := replay.replies.drop prepared.commands.length
  require "complete-public-batch-reply-count" (answers.length == cases.length)
  for (answer,(_,_,expected,_)) in answers.zip cases do
    require "complete-public-batch-decision"
      (match answer with | .normalized result => psKernelExprEq result expected | _ => false)
  let definition := PsKernelDagDeclarationRequest.definitionDecl
    (PsKernelDagDefinition.mk (PsKernelDagConstantBase.mk (nm "iotaChecked") [] natId)
      literalId .abbrevHint .safe)
  let admitted ← expectPublic (psKernelV1RunDag empty [] .safe input
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
  let _ ← expectPublic (psKernelV1RunDag empty [] .safe input prepared.commands)

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
  IO.println "PSC1_V2_DAG_RECURSOR: PASS public=252 core=504 owners=720 reducer=72 privateIDs=9"
  IO.println "PSC1_V2_DAG_OFFICIAL_RECURSOR: PASS valid=12 invalid=4 addDecl=3"

def main : IO Unit := regression
