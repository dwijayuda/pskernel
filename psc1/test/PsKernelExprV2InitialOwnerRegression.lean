import Ps.KernelCore.API.Dag
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

/- Fresh-session ownership controls. Every normal environment comes from real
   public checked admission. Deliberately inconsistent low-level environments
   are isolated lookup-authority probes, never an admission oracle. -/
namespace PsKernelExprV2InitialOwnerRegression

private def require (label : String) (condition : Bool) : IO Unit := do
  unless condition do throw (IO.userError ("PSC1_V2_INITIAL_OWNER_FAIL " ++ label))

private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def expectPublic {α : Type} (label : String) : Except PsKernelError α → IO α
  | .ok value => pure value
  | .error (.rejectedInvalid error) => throw (IO.userError (label ++ ": rejected " ++ error))
  | .error (.declinedUnsupported error) => throw (IO.userError (label ++ ": unsupported " ++ error))
  | .error (.resourceExhausted _ error) => throw (IO.userError (label ++ ": resource " ++ error))
  | .error (.internalError error) => throw (IO.userError (label ++ ": internal " ++ error))

private def attempt {α : Type} (label : String) : Option (Except String α) → IO α
  | none => throw (IO.userError ("PSC1_V2_INITIAL_OWNER_FALLBACK " ++ label))
  | some result => expect result

private def nm (text : String) := PsKernelName.str .anonymous text
private def one := PsKernelLevel.succ .zero
private def s1 := PsKernelExpr.sort one
private def nat := PsKernelExpr.const psKernelNatName []
private def seven := PsKernelExpr.lit (.nat 7)
private def pi (text : String) (domain body : PsKernelExpr) :=
  PsKernelExpr.forallE (nm text) domain body .default
private def app := psKernelApplyArgs
private def constE (name : PsKernelName) (levels : List PsKernelLevel := []) :=
  PsKernelExpr.const name levels

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

private def officialGroup (environment : Lean.Environment)
    (group : PsKernelSimpleMutualInductiveDecl) : IO Lean.Environment := do
  let types : List Lean.InductiveType := group.types.map fun type =>
    { name := officialName type.name
      type := officialExpr type.type
      ctors := type.ctors.map fun ctor =>
        { name := officialName ctor.name, type := officialExpr ctor.type } }
  match environment.addDeclCore 0 0
      (.inductDecl (group.levelParams.map officialName) group.numParams types group.isUnsafe)
      none true with
  | .ok next => pure next
  | .error _ => throw (IO.userError "PSC1_V2_INITIAL_OWNER_OFFICIAL_GROUP")

private structure Transition where
  request : PsKernelDagDeclarationRequest
  previous : PsKernelEnvironment
  current : PsKernelEnvironment

private structure Prepared where
  session : PsKernelKernelSession
  arena : PsKernelExprV2PagedArena
  commands : List PsKernelDagCommand
  transitions : List Transition

private def importGroup (arena : PsKernelExprV2PagedArena)
    (group : PsKernelSimpleMutualInductiveDecl) :
    IO (PsKernelExprV2PagedArena × PsKernelDagInductiveGroup) := do
  let mut arena := arena
  let mut types := []
  for type in group.types do
    let (next,root) ← expect (psKernelExprV2PagedImportIntoChecked arena type.type)
    arena := next
    let mut ctors := []
    for ctor in type.ctors do
      let (next,ctorRoot) ← expect (psKernelExprV2PagedImportIntoChecked arena ctor.type)
      arena := next
      ctors := ctors ++ [PsKernelDagConstructor.mk ctor.name ctorRoot]
    types := types ++ [PsKernelDagInductive.mk type.name root ctors]
  pure (arena,PsKernelDagInductiveGroup.mk group.levelParams group.numParams types group.isUnsafe)

private def prepareGroup (mode : Nat) (prior : Prepared)
    (group : PsKernelSimpleMutualInductiveDecl) : IO Prepared := do
  let (arena,dagGroup) ← importGroup prior.arena group
  let source := if mode == 0 then PsKernelDeclarationRequest.mutualInductive group
    else PsKernelDeclarationRequest.nestedInductive group
  let request := if mode == 0 then PsKernelDagDeclarationRequest.mutualInductive dagGroup
    else PsKernelDagDeclarationRequest.nestedInductive dagGroup
  let admitted ← expectPublic "group" (psKernelV1AdmitDeclaration prior.session source)
  pure (Prepared.mk admitted.session arena (prior.commands ++ [.admit request])
    (prior.transitions ++ [Transition.mk request prior.session.environment admitted.session.environment]))

private def prepareOrdinary (prior : Prepared)
    (decl : PsKernelSimpleInductiveDecl) : IO Prepared := do
  let group := PsKernelSimpleMutualInductiveDecl.mk decl.levelParams decl.numParams
    [PsKernelSimpleMutualTypeDecl.mk decl.name decl.type decl.ctors] decl.isUnsafe
  let (arena,dagGroup) ← importGroup prior.arena group
  let some type := dagGroup.types.head? | throw (IO.userError "ordinary fixture")
  let request := PsKernelDagDeclarationRequest.ordinaryInductive
    decl.levelParams decl.numParams type decl.isUnsafe
  let admitted ← expectPublic "ordinary" (psKernelV1AdmitDeclaration prior.session (.ordinaryInductive decl))
  pure (Prepared.mk admitted.session arena (prior.commands ++ [.admit request])
    (prior.transitions ++ [Transition.mk request prior.session.environment admitted.session.environment]))

private def prepareAxiom (prior : Prepared) (name : PsKernelName) : IO Prepared := do
  let admitted ← expectPublic "old-axiom" (psKernelV1AdmitDeclaration prior.session
    (.axiomDecl (PsKernelAxiomInfo.mk (PsKernelConstantBase.mk name [] s1) false)))
  let (arena,root) ← expect (psKernelExprV2PagedImportIntoChecked prior.arena s1)
  let request := PsKernelDagDeclarationRequest.axiomDecl (PsKernelDagConstantBase.mk name [] root) false
  pure (Prepared.mk admitted.session arena (prior.commands ++ [.admit request])
    (prior.transitions ++ [Transition.mk request prior.session.environment admitted.session.environment]))

private def newPrefix (previous : PsKernelEnvironment) :
    List PsKernelConstantInfo → List PsKernelConstantInfo
  | [] => []
  | info :: rest =>
      if psKernelEnvironmentContains previous (psKernelConstantInfoName info) then []
      else info :: newPrefix previous rest

private def recInfo (environment : PsKernelEnvironment) (name : PsKernelName) :
    IO PsKernelRecursorInfo := do
  match psKernelEnvironmentFind environment name with
  | some (.recInfo value) => pure value
  | _ => throw (IO.userError "missing final recursor metadata")

/- This helper constructs checked test expressions, not metadata or reduction
   rules. It follows the actual Pi spine, so mutual/nested minor binder order
   is checked independently by both kernels rather than guessed by the test. -/
private def constantFunction (type value : PsKernelExpr) : PsKernelExpr :=
  match type with
  | .forallE name domain body binder =>
      .lam name domain (constantFunction body value) binder
  | _ => value

private def recApplication (info : PsKernelRecursorInfo)
    (originalParams : List PsKernelName) (major : PsKernelExpr) : IO PsKernelExpr := do
  require "fixture-zero-params-and-indices" (info.numParams == 0 && info.numIndices == 0)
  let levels := info.base.levelParams.map fun name =>
    if originalParams.any (psKernelNameEq name) then PsKernelLevel.zero else one
  let mut type := psKernelExprInstantiateLevelParams info.base.type info.base.levelParams levels
  let mut term := PsKernelExpr.const info.base.name levels
  for i in List.range (info.numMotives + info.numMinors) do
    match type with
    | .forallE _ domain body _ =>
        let value := constantFunction domain (if i < info.numMotives then nat else seven)
        term := .app term value
        type := psKernelExprInstantiate body [value]
    | _ => throw (IO.userError "actual recursor Pi spine ended early")
  pure (.app term major)

private def decode (arena : PsKernelExprV2PagedArena) (root : Nat) : IO PsKernelExpr := do
  let built ← expect (psKernelExprV2DecodeChecked arena)
  expect (psKernelExprV2DecodedRequire built root)

private def rejected {α : Type} : Except PsKernelError α → Bool
  | .error (.rejectedInvalid _) => true
  | _ => false

private def prepareSimple (prior : Prepared)
    (request : PsKernelDeclarationRequest) : IO Prepared := do
  let imported : PsKernelExprV2PagedArena × PsKernelDagDeclarationRequest ←
    match request with
    | .axiomDecl value => do
        let (arena,type) ← expect (psKernelExprV2PagedImportIntoChecked prior.arena value.base.type)
        pure (arena,.axiomDecl
          (PsKernelDagConstantBase.mk value.base.name value.base.levelParams type) value.isUnsafe)
    | .definitionDecl value => do
        let (arena,type) ← expect (psKernelExprV2PagedImportIntoChecked prior.arena value.base.type)
        let (arena,body) ← expect (psKernelExprV2PagedImportIntoChecked arena value.value)
        pure (arena,.definitionDecl (PsKernelDagDefinition.mk
          (PsKernelDagConstantBase.mk value.base.name value.base.levelParams type)
          body value.hints value.safety))
    | .theoremDecl value => do
        let (arena,type) ← expect (psKernelExprV2PagedImportIntoChecked prior.arena value.base.type)
        let (arena,body) ← expect (psKernelExprV2PagedImportIntoChecked arena value.value)
        pure (arena,.theoremDecl
          (PsKernelDagConstantBase.mk value.base.name value.base.levelParams type) body)
    | .opaqueDecl value => do
        let (arena,type) ← expect (psKernelExprV2PagedImportIntoChecked prior.arena value.base.type)
        let (arena,body) ← expect (psKernelExprV2PagedImportIntoChecked arena value.value)
        pure (arena,.opaqueDecl
          (PsKernelDagConstantBase.mk value.base.name value.base.levelParams type) body value.isUnsafe)
    | _ => throw (IO.userError "unexpected simple fixture request")
  let admitted ← expectPublic "simple" (psKernelV1AdmitDeclaration prior.session request)
  pure (Prepared.mk admitted.session imported.fst
    (prior.commands ++ [.admit imported.snd])
    (prior.transitions ++
      [Transition.mk imported.snd prior.session.environment admitted.session.environment]))

private def officialSimple (environment : Lean.Environment)
    (request : PsKernelDeclarationRequest) : IO Lean.Environment := do
  let declaration : Lean.Declaration ←
    match request with
    | .axiomDecl value =>
        pure (.axiomDecl {
          name := officialName value.base.name
          levelParams := value.base.levelParams.map officialName
          type := officialExpr value.base.type
          isUnsafe := value.isUnsafe
        })
    | .definitionDecl value =>
        pure (.defnDecl {
          name := officialName value.base.name
          levelParams := value.base.levelParams.map officialName
          type := officialExpr value.base.type
          value := officialExpr value.value
          hints := .abbrev
          safety := .safe
        })
    | .theoremDecl value =>
        pure (.thmDecl {
          name := officialName value.base.name
          levelParams := value.base.levelParams.map officialName
          type := officialExpr value.base.type
          value := officialExpr value.value
        })
    | .opaqueDecl value =>
        pure (.opaqueDecl {
          name := officialName value.base.name
          levelParams := value.base.levelParams.map officialName
          type := officialExpr value.base.type
          value := officialExpr value.value
          isUnsafe := value.isUnsafe
        })
    | _ => throw (IO.userError "unexpected official fixture request")
  match environment.addDeclCore 0 0 declaration none true with
  | .ok next => pure next
  | .error _ => throw (IO.userError "official simple fixture refused")

private structure Query where
  label : String
  term : PsKernelExpr
  normalized : PsKernelExpr
  equalTo : PsKernelExpr

private structure OwnedQuery where
  source : Query
  root : Nat
  target : Nat

private structure InitialFixture where
  empty : PsKernelKernelSession
  session : PsKernelKernelSession
  official : Lean.Environment
  firstArena : PsKernelExprV2PagedArena
  source : PsKernelExprV2PagedArena
  built : PsKernelExprV2Decoded
  owned : PsKernelDagGeneratedState
  queries : List OwnedQuery
  aliasName : PsKernelName
  sealedName : PsKernelName
  theoremName : PsKernelName

private def fixture : IO InitialFixture := do
  let empty ← expectPublic "empty"
    (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let (padding,_) ← expect (psKernelExprV2PagedMkLit psKernelExprV2PagedEmpty (.nat 53))
  let natDecl := PsKernelSimpleInductiveDecl.mk [] psKernelNatName s1
    [PsKernelSimpleConstructorDecl.mk psKernelNatZeroName nat,
     PsKernelSimpleConstructorDecl.mk psKernelNatSuccName (pi "n" nat nat)] false 0
  let mut prepared ← prepareOrdinary (Prepared.mk empty padding [] []) natDecl
  let root := PsKernelName.num (nm "InitialOwner") 7
  let a := PsKernelName.str root "Left"
  let b := PsKernelName.str root "Right"
  let abase := PsKernelName.str a "base"
  let bbase := PsKernelName.str b "base"
  let amk := PsKernelName.str a "mk"
  let bmk := PsKernelName.str b "mk"
  let u := nm "u"
  let v := nm "v"
  let levels := [PsKernelLevel.param u,PsKernelLevel.param v]
  let type := PsKernelExpr.sort (.succ (.max (.param u) (.param v)))
  let aType := constE a levels
  let bType := constE b levels
  let mutualGroup := PsKernelSimpleMutualInductiveDecl.mk [u,v] 0
    [PsKernelSimpleMutualTypeDecl.mk a type
      [PsKernelSimpleConstructorDecl.mk abase aType,
       PsKernelSimpleConstructorDecl.mk amk (pi "other" bType aType)],
     PsKernelSimpleMutualTypeDecl.mk b type
      [PsKernelSimpleConstructorDecl.mk bbase bType,
       PsKernelSimpleConstructorDecl.mk bmk (pi "other" aType bType)]] false
  prepared ← prepareGroup 0 prepared mutualGroup
  let listName := PsKernelName.str root "List"
  let nilName := PsKernelName.str listName "nil"
  let consName := PsKernelName.str listName "cons"
  let sortU := PsKernelExpr.sort (.succ (.param u))
  let listAt (element : PsKernelExpr) := app (constE listName [.param u]) [element]
  let listDecl := PsKernelSimpleInductiveDecl.mk [u] listName (pi "A" sortU sortU)
    [PsKernelSimpleConstructorDecl.mk nilName (pi "A" sortU (listAt (.bvar 0))),
     PsKernelSimpleConstructorDecl.mk consName
       (pi "A" sortU (pi "head" (.bvar 0)
         (pi "tail" (listAt (.bvar 1)) (listAt (.bvar 2)))))] false 1
  prepared ← prepareOrdinary prepared listDecl
  let treeName := PsKernelName.str root "Tree"
  let leafName := PsKernelName.str treeName "leaf"
  let branchName := PsKernelName.str treeName "branch"
  let tree := constE treeName
  let listTree := app (constE listName [.zero]) [tree]
  let treeGroup := PsKernelSimpleMutualInductiveDecl.mk [] 0
    [PsKernelSimpleMutualTypeDecl.mk treeName s1
      [PsKernelSimpleConstructorDecl.mk leafName tree,
       PsKernelSimpleConstructorDecl.mk branchName (pi "children" listTree tree)]] false
  let beforeTree := prepared
  prepared ← prepareGroup 1 prepared treeGroup
  let treePrepared := prepared
  let fastName := PsKernelName.str root "Fast"
  let fastCtor := PsKernelName.str fastName "mk"
  let fastGroup := PsKernelSimpleMutualInductiveDecl.mk [] 0
    [PsKernelSimpleMutualTypeDecl.mk fastName s1
      [PsKernelSimpleConstructorDecl.mk fastCtor (constE fastName)]] false
  prepared ← prepareGroup 1 prepared fastGroup
  let axiomName := PsKernelName.str root "Token"
  let aliasName := PsKernelName.str root "value"
  let theoremName := PsKernelName.str root "identity"
  let sealedName := PsKernelName.str root "sealed"
  let proposition := pi "P" (.sort .zero) (pi "proof" (.bvar 0) (.bvar 1))
  let proof := PsKernelExpr.lam (nm "P") (.sort .zero)
    (.lam (nm "proof") (.bvar 0) (.bvar 0) .default) .default
  let simple := [
    PsKernelDeclarationRequest.axiomDecl
      (PsKernelAxiomInfo.mk (PsKernelConstantBase.mk axiomName [] s1) false),
    .definitionDecl (PsKernelDefinitionInfo.mk
      (PsKernelConstantBase.mk aliasName [] nat) seven .abbrevHint .safe),
    .theoremDecl (PsKernelTheoremInfo.mk
      (PsKernelConstantBase.mk theoremName [] proposition) proof),
    .opaqueDecl (PsKernelOpaqueInfo.mk
      (PsKernelConstantBase.mk sealedName [] nat) seven false)]
  for request in simple do prepared ← prepareSimple prepared request
  let first ← expectPublic "first-public-batch"
    (psKernelV1RunDag empty [] .safe prepared.arena prepared.commands)
  require "first-batch-replies" (first.replies.length == 9)
  require "first-batch-real-environment" (psKernelEnvironmentSize first.session.environment == 28)
  for info in prepared.session.environment.constants do
    let some actual := psKernelEnvironmentFind first.session.environment (psKernelConstantInfoName info)
      | throw (IO.userError "public first batch lost declaration")
    require "public-first-batch-agrees-with-independent-admission"
      (psKernelExprEqual (psKernelConstantInfoType info) (psKernelConstantInfoType actual))
  let treePrefix := newPrefix beforeTree.session.environment treePrepared.session.environment.constants
  let treeRecursors := treePrefix.filterMap fun info =>
    match info with | .recInfo rec => some rec | _ => none
  require "genuine-nested-restoration"
    (treeRecursors.length == 2 &&
      (match psKernelEnvironmentFind first.session.environment treeName with
       | some (.inductInfo info) => info.numNested == 1 | _ => false))
  let some aux := treeRecursors.find? fun rec =>
    rec.rules.any fun rule => psKernelNameEq rule.ctor nilName
    | throw (IO.userError "missing actual nested auxiliary")
  let leaf := constE leafName
  let listNil := app (constE nilName [.zero]) [tree]
  let listCons := app (constE consName [.zero]) [tree,leaf,listNil]
  let aMajor := app (constE amk [.zero,.zero]) [constE bbase [.zero,.zero]]
  let bMajor := app (constE bmk [.zero,.zero]) [constE abase [.zero,.zero]]
  let natRec ← recInfo first.session.environment (psKernelSimpleRecName psKernelNatName)
  let aRec ← recInfo first.session.environment (psKernelSimpleRecName a)
  let bRec ← recInfo first.session.environment (psKernelSimpleRecName b)
  let treeRec ← recInfo first.session.environment (psKernelSimpleRecName treeName)
  let fastRec ← recInfo first.session.environment (psKernelSimpleRecName fastName)
  let reduced := [
    ("ordinary-Nat",← recApplication natRec [] (app (constE psKernelNatSuccName) [.lit (.nat 0)])),
    ("mutual-left",← recApplication aRec [u,v] aMajor),
    ("mutual-right",← recApplication bRec [u,v] bMajor),
    ("nested-leaf",← recApplication treeRec [] leaf),
    ("nested-branch",← recApplication treeRec [] (app (constE branchName) [listCons])),
    ("nested-aux",← recApplication aux [] listCons),
    ("nested-no-aux",← recApplication fastRec [] (constE fastCtor))]
  let queries := reduced.map (fun (label,term) => Query.mk label term seven seven) ++ [
    Query.mk "axiom" (constE axiomName) (constE axiomName) (constE axiomName),
    Query.mk "definition" (constE aliasName) seven seven,
    Query.mk "theorem" (constE theoremName) (constE theoremName) proof,
    Query.mk "opaque" (constE sealedName) (constE sealedName) (constE sealedName),
    Query.mk "proof" proof proof (constE theoremName)]
  -- This source is constructed afresh, not extended from the first batch.
  let (fresh,_) ← expect (psKernelExprV2PagedMkLit psKernelExprV2PagedEmpty (.nat 12345))
  let mut source := fresh
  let mut roots := []
  for query in queries do
    let (next,termId) ← expect (psKernelExprV2PagedImportIntoChecked source query.term)
    let (next,targetId) ← expect (psKernelExprV2PagedImportIntoChecked next query.equalTo)
    source := next
    roots := roots ++ [OwnedQuery.mk query termId targetId]
  let built ← expect (psKernelExprV2DecodeChecked source)
  let owned ← expect (psKernelDagInitialInstall
    (psKernelKernelSessionEnvironment first.session)
    (PsKernelDagGeneratedState.mk source built []))
  Lean.initSearchPath (← Lean.findSysroot)
  let official0 ← Lean.importModules #[{ module := `Init }] {}
  let official1 ← officialGroup official0 mutualGroup
  let listGroup := PsKernelSimpleMutualInductiveDecl.mk [u] 1
    [PsKernelSimpleMutualTypeDecl.mk listDecl.name listDecl.type listDecl.ctors] false
  let official2 ← officialGroup official1 listGroup
  let official3 ← officialGroup official2 treeGroup
  let mut official ← officialGroup official3 fastGroup
  for request in simple do official ← officialSimple official request
  pure (InitialFixture.mk empty first.session official prepared.arena
    source built owned roots aliasName sealedName theoremName)

private def compareExprAttempt {α : Type} (label : String)
    (reference : Except String (PsKernelExpr × α))
    (observed : Option (Except String (PsKernelExprV2PagedArena × Nat))) : IO Unit := do
  match reference,observed with
  | .error expected,some (.error actual) =>
      require (label ++ "-exact-error") (expected == actual)
  | .ok expected,some (.ok actual) =>
      require (label ++ "-exact-expression")
        (psKernelExprEqual expected.fst (← decode actual.fst actual.snd))
  | _,none => throw (IO.userError ("unexpected initial-owner fallback: " ++ label))
  | _,_ => throw (IO.userError ("initial-owner outcome mismatch: " ++ label))

private def compareBoolAttempt {α : Type} (label : String)
    (reference : Except String (Bool × α))
    (observed : Option (Except String Bool)) : IO Unit := do
  match reference,observed with
  | .error expected,some (.error actual) =>
      require (label ++ "-exact-error") (expected == actual)
  | .ok expected,some (.ok actual) =>
      require (label ++ "-exact-boolean") (expected.fst == actual)
  | _,none => throw (IO.userError ("unexpected initial-owner DefEq fallback: " ++ label))
  | _,_ => throw (IO.userError ("initial-owner DefEq mismatch: " ++ label))

private def metadataAndMatrix (fixture : InitialFixture) : IO Unit := do
  let owned := fixture.owned
  require "fresh-second-graph-padding"
    (psKernelExprEqual (.lit (.nat 12345)) (← expect (psKernelExprV2DecodedRequire fixture.built 0)))
  require "new-owner-complete-count" (owned.declarations.length == 28)
  require "appended-tables-correspond" (owned.arena.size == owned.built.size)
  let mut recursors := 0
  let mut rules := 0
  let mut deltas := 0
  for info in fixture.session.environment.constants do
    let name := psKernelConstantInfoName info
    let some live := psKernelEnvironmentFind fixture.session.environment name
      | throw (IO.userError "checked history/index mismatch")
    let some owner := psKernelExprV2DeclarationRefFind owned.declarations name
      | throw (IO.userError "missing initial owner")
    require "only-live-index-metadata" (psKernelExprV2DeclarationRefMatches owner live)
    require "private-type-ID" (owner.type >= fixture.source.size)
    require "exact-live-type"
      (psKernelExprEqual (psKernelConstantInfoType live)
        (← expect (psKernelExprV2DecodedRequire owned.built owner.type)))
    match live with
    | .defnInfo value =>
        deltas := deltas + 1
        let some body := owner.deltaValue | throw (IO.userError "missing transparent body owner")
        require "private-transparent-body-ID" (body >= fixture.source.size)
        require "exact-live-transparent-body"
          (psKernelExprEqual value.value (← expect (psKernelExprV2DecodedRequire owned.built body)))
    | _ => require "only-definitions-publish-delta" owner.deltaValue.isNone
    match live with
    | .recInfo recursor =>
        recursors := recursors + 1
        for rule in recursor.rules do
          rules := rules + 1
          let some rhs := psKernelExprV2RecursorRuleOwner owned.declarations recursor rule
            | throw (IO.userError "missing initial recursor rule")
          require "private-rule-ID" (rhs >= fixture.source.size)
          require "exact-live-rule"
            (psKernelExprEqual rule.rhs (← expect (psKernelExprV2DecodedRequire owned.built rhs)))
    | _ => pure ()
  require "owner-family-counts" (recursors == 7 && rules == 13 && deltas == 1)
  for root in List.range fixture.source.size do
    require "original-input-prefix"
      (psKernelExprEqual (← expect (psKernelExprV2DecodedRequire fixture.built root))
        (← expect (psKernelExprV2DecodedRequire owned.built root)))
  let scalar := (psKernelKernelSessionChecker fixture.session [] .safe).context
  let some aliasQuery := fixture.queries.find? (fun row => row.source.label == "definition")
    | throw (IO.userError "alias query missing")
  require "preexisting-without-owner-explicitly-declines"
    (psKernelExprV2TryCheckWithDeclarationsFuel 4096 scalar fixture.source [] aliasQuery.root).isNone
  let initial := psKernelExprV2CheckStateWithWhnf
    (psKernelExprV2CheckStateEmpty owned.arena)
    (psKernelExprV2WhnfStateForDeclarations owned.arena owned.declarations)
  require "fresh-complete-operation-state"
    (initial.nextFresh == 0 && initial.checkedInfer.isEmpty && initial.inferOnly.isEmpty &&
      initial.success.isEmpty && initial.failure.isEmpty && initial.unfold.isEmpty &&
      initial.whnf.coreCache.isEmpty && initial.whnf.publicCache.isEmpty)
  let some proofQuery := fixture.queries.find? (fun row => row.source.label == "proof")
    | throw (IO.userError "proof query missing")
  let primed ← attempt "fresh-proof-state"
    (psKernelExprV2TryCheckStateWithFuel 4096
      (psKernelExprV2CheckContextEmpty scalar) initial proofQuery.root)
  require "real-operation-used-fresh-names" (primed.fst.nextFresh > 0)
  require "original-state-not-mutated" (initial.nextFresh == 0 && initial.checkedInfer.isEmpty)
  let mut count := 0
  for row in fixture.queries do
    for fuel in [0,1,2,4,16,64,4096] do
      for (limit,depth) in [(0,0),(1,15),(1,16)] do
        let context := { scalar with maxRecDepth := limit, recDepth := depth }
        let reference := PsKernelCheckerSession.mk context psKernelCheckerStateEmpty
        let label := s!"{row.source.label}-fuel{fuel}-limit{limit}-depth{depth}"
        compareExprAttempt (label ++ "-check")
          (psKernelSessionCheck fuel reference row.source.term)
          (psKernelExprV2TryCheckWithDeclarationsFuel fuel context
            owned.arena owned.declarations row.root)
        compareExprAttempt (label ++ "-whnf")
          (psKernelSessionWhnf fuel reference row.source.term)
          (psKernelExprV2TryWhnfOwnedWithDeclarationsFuel fuel context
            owned.arena owned.declarations row.root)
        compareBoolAttempt (label ++ "-defeq")
          (psKernelSessionIsDefEq fuel reference row.source.term row.source.equalTo)
          (psKernelExprV2TryDefEqWithDeclarationsFuel fuel context
            owned.arena owned.declarations row.root row.target)
        count := count + 1
  require "raw-matrix-complete" (count == 252)
  IO.println "PSC1_V2_INITIAL_OWNER_METADATA: PASS owners=28 recursors=7 rules=13 delta=1"
  IO.println "PSC1_V2_INITIAL_OWNER_MATRIX: PASS check=252 whnf=252 defeq=252"

private def publicAndOfficial (fixture : InitialFixture) : IO Unit := do
  let commands := fixture.queries.flatMap fun row =>
    [PsKernelDagCommand.check row.root,.whnf row.root,.isDefEq row.root row.target]
  let batch ← expectPublic "second-public-batch"
    (psKernelV1RunDag fixture.session [] .safe fixture.source commands)
  require "second-batch-all-replies" (batch.replies.length == 36)
  require "second-batch-environment-size"
    (psKernelEnvironmentSize batch.session.environment == 28)
  let mut replies := batch.replies
  for row in fixture.queries do
    let expected ← expectPublic "reference-check"
      (psKernelV1CheckExpression fixture.session [] .safe row.source.term)
    let normal ← expectPublic "reference-whnf"
      (psKernelV1Whnf fixture.session [] .safe row.source.term)
    let equal ← expectPublic "reference-defeq"
      (psKernelV1IsDefEq fixture.session [] .safe row.source.term row.source.equalTo)
    require (row.source.label ++ "-specified-normalization")
      (psKernelExprEqual normal row.source.normalized)
    require (row.source.label ++ "-specified-equality") equal
    match replies with
    | .checked checked :: .normalized actual :: .equal answer :: rest =>
        require (row.source.label ++ "-public-exact-check")
          (psKernelExprEqual checked.expression expected.expression &&
            psKernelExprEqual checked.type expected.type)
        require (row.source.label ++ "-public-exact-whnf") (psKernelExprEqual actual normal)
        require (row.source.label ++ "-public-exact-defeq") (answer == equal)
        replies := rest
    | _ => throw (IO.userError "wrong ordered second-batch reply shape")
    require (row.source.label ++ "-official-check")
      (match Lean.Kernel.check fixture.official {} (officialExpr row.source.term) with
       | .ok _ => true | _ => false)
    require (row.source.label ++ "-official-equality")
      (match Lean.Kernel.isDefEq fixture.official {}
          (officialExpr row.source.term) (officialExpr row.source.equalTo) with
       | .ok true => true | _ => false)
  require "all-second-batch-replies-consumed" replies.isEmpty
  let wrongName := nm "InitialOwnerWrongType"
  let wrong := PsKernelDefinitionInfo.mk
    (PsKernelConstantBase.mk wrongName [] s1) seven .abbrevHint .safe
  require "V1-real-invalid-definition"
    (match psKernelV1AdmitDeclaration fixture.session (.definitionDecl wrong) with
     | .error (.rejectedInvalid text) => text == "definition type mismatch"
     | _ => false)
  require "official-real-invalid-definition"
    (match fixture.official.addDeclCore 0 0 (.defnDecl {
        name := officialName wrongName
        levelParams := []
        type := officialExpr s1
        value := officialExpr seven
        hints := .abbrev
        safety := .safe
      }) none true with | .error _ => true | _ => false)
  IO.println "PSC1_V2_INITIAL_OWNER_PUBLIC: PASS replies=36 secondArena=fresh"
  IO.println "PSC1_V2_INITIAL_OWNER_OFFICIAL: PASS checks=12 equalities=12 invalid=1"

private def invalidReference (result : Except PsKernelError PsKernelDagBatchResult) : Bool :=
  match result with
  | .error (.rejectedInvalid text) => text == "PSKERNEL_V2_DECODE_INVALID_REFERENCE"
  | _ => false

private def namespaceAndGuards (fixture : InitialFixture) : IO Unit := do
  let (source,natId) ← expect (psKernelExprV2PagedImportIntoChecked fixture.source nat)
  let (source,s1Id) ← expect (psKernelExprV2PagedImportIntoChecked source s1)
  let (source,sevenId) ← expect (psKernelExprV2PagedImportIntoChecked source seven)
  let (source,aliasId) ← expect
    (psKernelExprV2PagedImportIntoChecked source (constE fixture.aliasName))
  let missingName := nm "InitialOwnerMissing"
  let (source,missingId) ← expect
    (psKernelExprV2PagedImportIntoChecked source (constE missingName))
  let freshName := nm "InitialOwnerSecondDefinition"
  let (source,freshId) ← expect
    (psKernelExprV2PagedImportIntoChecked source (constE freshName))
  let built ← expect (psKernelExprV2DecodeChecked source)
  let owned ← expect (psKernelDagInitialInstall (psKernelKernelSessionEnvironment fixture.session)
    (PsKernelDagGeneratedState.mk source built []))
  let some aliasOwner := psKernelExprV2DeclarationRefFind owned.declarations fixture.aliasName
    | throw (IO.userError "missing fresh alias owner")
  let some bodyId := aliasOwner.deltaValue | throw (IO.userError "missing fresh alias body")
  let recursor ← recInfo fixture.session.environment (psKernelSimpleRecName psKernelNatName)
  let some rule := recursor.rules.head? | throw (IO.userError "missing genuine Nat rule")
  let some ruleId := psKernelExprV2RecursorRuleOwner owned.declarations recursor rule
    | throw (IO.userError "missing fresh rule owner")
  let privateIds := [source.size,aliasOwner.type,bodyId,ruleId]
  let name := nm "InitialOwnerPrivateAttempt"
  let family := nm "InitialOwnerPrivateFamily"
  let ctor := PsKernelName.str family "mk"
  let mut count := 0
  for privateId in privateIds do
    require "metadata-IDs-outside-source" (privateId >= source.size)
    let privateBase := PsKernelDagConstantBase.mk name [] privateId
    let validBase := PsKernelDagConstantBase.mk name [] natId
    let privateType := PsKernelDagInductive.mk family privateId []
    let privateCtor := PsKernelDagInductive.mk family s1Id
      [PsKernelDagConstructor.mk ctor privateId]
    let commands := [
      PsKernelDagCommand.check privateId,.whnf privateId,
      .isDefEq privateId sevenId,.isDefEq sevenId privateId,
      .admit (.axiomDecl privateBase false),
      .admit (.definitionDecl (PsKernelDagDefinition.mk privateBase sevenId .abbrevHint .safe)),
      .admit (.definitionDecl (PsKernelDagDefinition.mk validBase privateId .abbrevHint .safe)),
      .admit (.theoremDecl privateBase sevenId),
      .admit (.theoremDecl validBase privateId),
      .admit (.opaqueDecl privateBase sevenId false),
      .admit (.opaqueDecl validBase privateId false),
      .admit (.mutualDefinitions
        [PsKernelDagDefinition.mk privateBase sevenId .abbrevHint .unsafeDef]),
      .admit (.mutualDefinitions
        [PsKernelDagDefinition.mk validBase privateId .abbrevHint .unsafeDef]),
      .admit (.ordinaryInductive [] 0 privateType false),
      .admit (.ordinaryInductive [] 0 privateCtor false),
      .admit (.mutualInductive (PsKernelDagInductiveGroup.mk [] 0 [privateType] false)),
      .admit (.mutualInductive (PsKernelDagInductiveGroup.mk [] 0 [privateCtor] false)),
      .admit (.nestedInductive (PsKernelDagInductiveGroup.mk [] 0 [privateType] false)),
      .admit (.nestedInductive (PsKernelDagInductiveGroup.mk [] 0 [privateCtor] false))]
    require "private-position-count" (commands.length == 19)
    for command in commands do
      require "private-ID-never-becomes-an-external-input"
        (invalidReference (psKernelV1RunDag fixture.session [] .safe source [command]))
      count := count + 1
  require "private-matrix-complete" (count == 76)
  let privateId := source.size
  let invalid := PsKernelDagDeclarationRequest.definitionDecl
    (PsKernelDagDefinition.mk
      (PsKernelDagConstantBase.mk (nm "InitialOwnerBadDefinition") [] s1Id)
      sevenId .abbrevHint .safe)
  require "earlier-unknown-constant-before-later-private-ID"
    (match psKernelV1RunDag fixture.session [] .safe source
        [.check missingId,.check privateId] with
     | .error (.rejectedInvalid text) => text == "unknown constant"
     | _ => false)
  require "earlier-semantic-failure-before-later-private-ID"
    (match psKernelV1RunDag fixture.session [] .safe source
        [.admit invalid,.check privateId] with
     | .error (.rejectedInvalid text) => text == "definition type mismatch"
     | _ => false)
  let good := PsKernelDagDeclarationRequest.definitionDecl
    (PsKernelDagDefinition.mk (PsKernelDagConstantBase.mk freshName [] natId)
      aliasId .abbrevHint .safe)
  let admitted ← expectPublic "real-second-batch-admission"
    (psKernelV1RunDag fixture.session [] .safe source [.admit good,.check freshId])
  require "second-batch-admitted-real-reference"
    (psKernelEnvironmentContains admitted.session.environment freshName &&
      psKernelEnvironmentSize admitted.session.environment == 29 &&
      admitted.replies.length == 2)
  require "late-private-failure-is-atomic"
    (invalidReference
      (psKernelV1RunDag fixture.session [] .safe source [.admit good,.check privateId]))
  require "late-semantic-failure-is-atomic"
    (match psKernelV1RunDag fixture.session [] .safe source [.admit good,.admit invalid] with
     | .error (.rejectedInvalid text) => text == "definition type mismatch"
     | _ => false)
  require "input-session-did-not-publish-partial-work"
    (!(psKernelEnvironmentContains fixture.session.environment freshName) &&
      psKernelEnvironmentSize fixture.session.environment == 28)
  require "later-call-cannot-see-private-publication"
    (match psKernelV1CheckExpression fixture.session [] .safe (constE freshName) with
     | .error (.rejectedInvalid text) => text == "unknown constant"
     | _ => false)
  let invalidArena : PsKernelExprV2PagedArena := { psKernelExprV2PagedEmpty with size := 1 }
  require "actual-invalid-graph"
    (match psKernelExprV2PagedValidate invalidArena with | .error _ => true | _ => false)
  let cancelled := { fixture.session with
    resources := { fixture.session.resources with cancelled := true } }
  require "cancellation-precedes-validation-and-import"
    (match psKernelV1RunDag cancelled [] .safe invalidArena [.check 0] with
     | .error (.resourceExhausted .cancelled text) =>
         text == "resource policy declined operation before entry"
     | _ => false)
  let zero := { fixture.session with
    resources := { fixture.session.resources with fuel := 0 } }
  require "fuel-zero-precedes-validation-and-import"
    (match psKernelV1RunDag zero [] .safe invalidArena [.check 0] with
     | .error (.resourceExhausted .fuel text) =>
         text == "resource policy declined operation before entry"
     | _ => false)
  let badProvider := { fixture.session.provider with
    target := { fixture.session.provider.target with leanVersion := "mismatch" } }
  let incompatible := { cancelled with provider := badProvider }
  require "provider-guard-precedes-resource-and-import"
    (match psKernelV1RunDag incompatible [] .safe invalidArena [.check 0] with
     | .error (.declinedUnsupported text) =>
         text == "provider target does not match KernelContract-v1"
     | _ => false)
  let limit := { fixture.session with
    resources := { fixture.session.resources with maxDeclarations := 28 } }
  require "declaration-limit-preserved"
    (match psKernelV1RunDag limit [] .safe source [.admit good] with
     | .error (.resourceExhausted .declarationLimit text) => text == "declaration limit exceeded"
     | _ => false)
  let empty ← expectPublic "empty-second-batch"
    (psKernelV1RunDag fixture.session [] .safe source [])
  require "empty-batch-retains-session" (empty.replies.isEmpty &&
    psKernelEnvironmentSize empty.session.environment == 28)
  let broken := psKernelExprV2DecodedPush built s1
  require "internal-import-error-does-not-return-partial-owner"
    (match psKernelDagInitialInstall (psKernelKernelSessionEnvironment fixture.session)
        (PsKernelDagGeneratedState.mk source broken []) with
     | .error text => text == "PSKERNEL_V2_GENERATED_OWNER_MISMATCH"
     | _ => false)
  IO.println "PSC1_V2_INITIAL_OWNER_NAMESPACE: PASS positions=76 precedence=2 atomic=3 guards=4"

private def comparePublicCheck (label : String)
    (reference : Except PsKernelError PsKernelCheckedExpression)
    (observed : Except PsKernelError PsKernelDagBatchResult) : IO Unit := do
  match reference,observed with
  | .error (.rejectedInvalid expected),.error (.rejectedInvalid actual) =>
      require (label ++ "-same-exact-rejection") (expected == actual)
  | .ok expected,.ok result =>
      match result.replies with
      | [.checked actual] =>
          require (label ++ "-same-exact-checked-type")
            (psKernelExprEqual actual.expression expected.expression &&
              psKernelExprEqual actual.type expected.type)
      | _ => throw (IO.userError "forged lookup changed reply shape")
  | _,_ => throw (IO.userError ("forged lookup changed public outcome: " ++ label))

private def forgedLookupControls (fixture : InitialFixture) : IO Unit := do
  let some (.defnInfo definition) :=
      psKernelEnvironmentFind fixture.session.environment fixture.aliasName
    | throw (IO.userError "missing checked alias")
  let live := PsKernelConstantInfo.defnInfo definition
  let stale := PsKernelConstantInfo.defnInfo
    { definition with base := { definition.base with type := s1 }, value := .sort .zero }
  let wrongKind := PsKernelConstantInfo.axiomInfo
    (PsKernelAxiomInfo.mk { definition.base with type := s1 } false)
  let absentName := nm "InitialOwnerPhantomHistory"
  let phantom := PsKernelConstantInfo.axiomInfo
    (PsKernelAxiomInfo.mk (PsKernelConstantBase.mk absentName [] s1) false)
  let environment := fixture.session.environment
  let variants : List (String × PsKernelEnvironment × Nat) := [
    ("stale-type-and-body",{ environment with constants := [stale] },1),
    ("missing-index",{ environment with constants := [live], index := psKernelEnvironmentEmpty.index },0),
    ("duplicate-history",{ environment with constants := [stale,live,wrongKind] },3),
    ("index-only",{ environment with constants := [] },0),
    ("historical-wrong-kind",{ environment with constants := [wrongKind] },1),
    ("phantom-history",{ environment with constants := [phantom] },0)]
  let (source,root) ← expect
    (psKernelExprV2PagedImportIntoChecked psKernelExprV2PagedEmpty (constE fixture.aliasName))
  let (source,phantomRoot) ← expect
    (psKernelExprV2PagedImportIntoChecked source (constE absentName))
  let built ← expect (psKernelExprV2DecodeChecked source)
  for (label,forged,expectedOwners) in variants do
    -- These are deliberately low-level trusted sessions, not admitted metadata.
    let session := { fixture.session with environment := forged }
    let installed ← expect (psKernelDagInitialInstall (psKernelKernelSessionEnvironment session)
      (PsKernelDagGeneratedState.mk source built []))
    require (label ++ "-owner-count") (installed.declarations.length == expectedOwners)
    for owner in installed.declarations do
      require (label ++ "-live-kind") (psKernelExprV2DeclarationRefMatches owner live)
      require (label ++ "-live-type-not-history")
        (psKernelExprEqual definition.base.type
          (← expect (psKernelExprV2DecodedRequire installed.built owner.type)))
      let some value := owner.deltaValue | throw (IO.userError "history changed live definition kind")
      require (label ++ "-live-body-not-history")
        (psKernelExprEqual definition.value
          (← expect (psKernelExprV2DecodedRequire installed.built value)))
    comparePublicCheck label
      (psKernelV1CheckExpression session [] .safe (constE fixture.aliasName))
      (psKernelV1RunDag session [] .safe source [.check root])
    comparePublicCheck (label ++ "-phantom")
      (psKernelV1CheckExpression session [] .safe (constE absentName))
      (psKernelV1RunDag session [] .safe source [.check phantomRoot])
    let scalar := (psKernelKernelSessionChecker session [] .safe).context
    let raw := psKernelExprV2TryCheckWithDeclarationsFuel 4096 scalar
      installed.arena installed.declarations root
    if expectedOwners > 0 then
      let checked ← attempt (label ++ "-raw-owned") raw
      require (label ++ "-raw-exact-live-type")
        (psKernelExprEqual definition.base.type (← decode checked.fst checked.snd))
    else
      match psKernelEnvironmentFind forged fixture.aliasName with
      | none =>
          require (label ++ "-missing-index-never-authorizes")
            (match raw with | some (.error text) => text == "unknown constant" | _ => false)
      | some _ =>
          require (label ++ "-index-only-explicit-fallback") raw.isNone
    require (label ++ "-phantom-never-installed")
      (psKernelExprV2DeclarationRefFind installed.declarations absentName).isNone
  IO.println "PSC1_V2_INITIAL_OWNER_LIVE_INDEX: PASS variants=6 public=12"

def regression : IO Unit := do
  let prepared ← fixture
  metadataAndMatrix prepared
  publicAndOfficial prepared
  namespaceAndGuards prepared
  forgedLookupControls prepared
  IO.println "PSC1_V2_INITIAL_OWNER: PASS checkedBatches=2 queries=12"

end PsKernelExprV2InitialOwnerRegression

def main : IO Unit := PsKernelExprV2InitialOwnerRegression.regression
