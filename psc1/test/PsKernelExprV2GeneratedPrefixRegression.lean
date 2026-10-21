import Ps.KernelCore.API.Dag
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

/- Focused T03a qualification. Every family is admitted by the independent
   checker and official Lean; internal owner records are never an admission
   oracle. The prefix poison checks are internal invariant/atomicity probes. -/
namespace PsKernelExprV2GeneratedPrefixRegression

private def require (label : String) (condition : Bool) : IO Unit := do
  unless condition do throw (IO.userError ("PSC1_V2_PREFIX_FAIL " ++ label))

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
  | none => throw (IO.userError ("PSC1_V2_PREFIX_FALLBACK " ++ label))
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
  | .error _ => throw (IO.userError "PSC1_V2_PREFIX_OFFICIAL_GROUP")

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


/- T03b: the prior argument is a genuinely returned public session. No owner
   table is accepted by the next public call. Low-level probes below inspect
   the same privately derived representation and cannot hide fallback. -/
private def sessionOwnersRegression
    (prior : PsKernelKernelSession) (officialPrior : Lean.Environment)
    (terms : List (String × PsKernelExpr)) (oldRec : PsKernelRecursorInfo) : IO Unit := do
  let definitionName := nm "SessionReusedDefinition"
  let axiomName := nm "SessionReusedAxiom"
  let theoremName := nm "SessionReusedTheorem"
  let opaqueName := nm "SessionReusedOpaque"
  let proposition := PsKernelExpr.sort .zero
  let identityType := pi "P" proposition (pi "h" (.bvar 0) (.bvar 1))
  let identityValue := PsKernelExpr.lam (nm "P") proposition
    (.lam (nm "h") (.bvar 0) (.bvar 0) .default) .default
  let definition := PsKernelDefinitionInfo.mk
    (PsKernelConstantBase.mk definitionName [] nat) seven .abbrevHint .safe
  let axiomInfo := PsKernelAxiomInfo.mk (PsKernelConstantBase.mk axiomName [] nat) false
  let theoremInfo := PsKernelTheoremInfo.mk
    (PsKernelConstantBase.mk theoremName [] identityType) identityValue
  let opaqueInfo := PsKernelOpaqueInfo.mk
    (PsKernelConstantBase.mk opaqueName [] nat) seven false
  let requests : List PsKernelDeclarationRequest := [
    .definitionDecl definition, .axiomDecl axiomInfo,
    .theoremDecl theoremInfo, .opaqueDecl opaqueInfo]
  let mut session := prior
  for request in requests do
    session := (← expectPublic "session-additional-checked-admission"
      (psKernelV1AdmitDeclaration session request)).session
  let officialRequests : List Lean.Declaration := [
    .defnDecl { name := officialName definitionName, levelParams := [], type := officialExpr nat, value := officialExpr seven, hints := .abbrev, safety := .safe },
    .axiomDecl { name := officialName axiomName, levelParams := [], type := officialExpr nat, isUnsafe := false },
    .thmDecl { name := officialName theoremName, levelParams := [], type := officialExpr identityType, value := officialExpr identityValue },
    .opaqueDecl { name := officialName opaqueName, levelParams := [], type := officialExpr nat, value := officialExpr seven, isUnsafe := false }]
  let mut official := officialPrior
  for request in officialRequests do
    match official.addDeclCore 0 0 request none true with
    | .ok next => official := next
    | .error _ => throw (IO.userError "session-official-declaration")
  let universeName := nm "session_u"
  let eqDeclaration := PsKernelSimpleInductiveDecl.mk [universeName] psKernelEqName
    (psKernelExpectedEqType universeName)
    [PsKernelSimpleConstructorDecl.mk (PsKernelName.str psKernelEqName "refl")
      (psKernelExpectedEqReflType universeName)] false 2
  let withEq ← expectPublic "session-checked-Eq"
    (psKernelV1AdmitDeclaration session (.ordinaryInductive eqDeclaration))
  session := (← expectPublic "session-checked-Quot" (psKernelV1AdmitDeclaration withEq.session .quot)).session
  require "session-quot-admitted" session.environment.quotInitialized
  let (padding,_) ← expect (psKernelExprV2PagedMkLit psKernelExprV2PagedEmpty (.nat 991))
  let (padding,_) ← expect (psKernelExprV2PagedMkLit padding (.nat 992))
  let (padding,natId) ← expect (psKernelExprV2PagedImportIntoChecked padding nat)
  let mut input := padding
  let mut roots : List (String × PsKernelExpr × Nat) := []
  for (label,term) in terms ++ [("old-definition",constE definitionName)] do
    let (next,id) ← expect (psKernelExprV2PagedImportIntoChecked input term)
    input := next
    roots := roots ++ [(label,term,id)]
  let mut otherRoots : List Nat := []
  for term in [constE axiomName,constE theoremName,constE opaqueName,
      constE psKernelQuotName [one]] do
    let (next,id) ← expect (psKernelExprV2PagedImportIntoChecked input term)
    input := next
    otherRoots := id :: otherRoots
  let (input,sevenId) ← expect (psKernelExprV2PagedImportIntoChecked input seven)
  let built ← expect (psKernelExprV2DecodeChecked input)
  let installed ← expect (psKernelDagGeneratedFromSession session input built)
  require "session-demand-scoped-owner-count"
    (installed.declarations.length < session.environment.constants.length &&
      installed.arena.size == installed.built.size)
  for i in List.range 32 do
    require "session-unrelated-owner-not-imported"
      (psKernelExprV2DeclarationRefFind installed.declarations (.num (nm "PrefixOld") i)).isNone
  let (sortArena,_) ← expect (psKernelExprV2PagedImportIntoChecked psKernelExprV2PagedEmpty s1)
  let sortBuilt ← expect (psKernelExprV2DecodeChecked sortArena)
  let sortOwners ← expect (psKernelDagGeneratedFromSession session sortArena sortBuilt)
  require "session-closed-sort-imports-no-declarations"
    (sortOwners.declarations.isEmpty && sortOwners.arena.size == sortArena.size)
  let mut kinds : List Nat := []
  for owner in installed.declarations do
    let some info := psKernelEnvironmentFind session.environment owner.name
      | throw (IO.userError "session-owner-not-live")
    require "session-exact-live-metadata"
      (psKernelExprV2DeclarationRefMatches owner info &&
        psKernelExprEqual (psKernelConstantInfoType info) (← decode installed.arena owner.type))
    let tag := match info with
      | .axiomInfo _ => 0 | .defnInfo _ => 1 | .thmInfo _ => 2 | .opaqueInfo _ => 3
      | .inductInfo _ => 4 | .ctorInfo _ => 5 | .recInfo _ => 6 | .quotInfo _ => 7
    if !kinds.contains tag then kinds := tag :: kinds
    match info with
    | .defnInfo value =>
        let some body := owner.deltaValue | throw (IO.userError "session-definition-body")
        require "session-exact-transparent-body"
          (psKernelExprEqual value.value (← decode installed.arena body))
    | _ => require "session-no-invented-delta" owner.deltaValue.isNone
    match info with
    | .recInfo rec =>
        for rule in rec.rules do
          let some rhs := psKernelExprV2RecursorRuleOwner installed.declarations rec rule
            | throw (IO.userError "session-missing-rule-owner")
          require "session-exact-private-rule" (rhs >= input.size &&
            psKernelExprEqual rule.rhs (← decode installed.arena rhs))
    | _ => pure ()
  require "session-all-eight-kinds" (kinds.length == 8)
  for index in List.range input.size do
    require "session-external-ID-stable"
      (psKernelExprEqual (← expect (psKernelExprV2DecodedRequire built index))
        (← expect (psKernelExprV2DecodedRequire installed.built index)))
  let scalar := (psKernelKernelSessionChecker session [] .safe).context
  for root in otherRoots do
    let _ ← attempt "session-other-kind-direct-check"
      (psKernelExprV2TryCheckWithDeclarationsFuel 4096 scalar installed.arena installed.declarations root)
  let _ ← expectPublic "session-other-kinds-public-check"
    (psKernelV1RunDag session [] .safe input (otherRoots.map PsKernelDagCommand.check))
  for (label,term,root) in roots do
    let checked ← attempt ("session-" ++ label ++ "-direct-check")
      (psKernelExprV2TryCheckWithDeclarationsFuel 4096 scalar installed.arena installed.declarations root)
    require "session-direct-check-type" (psKernelExprEqual nat
      (← expectPublic "session-normalized-type"
        (psKernelV1Whnf session [] .safe (← decode checked.fst checked.snd))))
    let normalized ← attempt ("session-" ++ label ++ "-direct-whnf")
      (psKernelExprV2TryWhnfOwnedWithDeclarationsFuel 4096 scalar installed.arena installed.declarations root)
    require "session-direct-whnf-value"
      (psKernelExprEqual seven (← decode normalized.fst normalized.snd))
    require "session-direct-defeq"
      (← attempt ("session-" ++ label ++ "-direct-defeq")
        (psKernelExprV2TryDefEqWithDeclarationsFuel 4096 scalar installed.arena installed.declarations root sevenId))
    require "session-official-check"
      (match Lean.Kernel.check official {} (officialExpr term) with | .ok _ => true | _ => false)
    require "session-official-defeq"
      (match Lean.Kernel.isDefEq official {} (officialExpr term) (officialExpr seven) with
       | .ok true => true | _ => false)
  let commands := roots.flatMap fun (_,_,root) => [.check root,.whnf root,.isDefEq root sevenId]
  let reused ← expectPublic "session-second-public-call" (psKernelV1RunDag session [] .safe input commands)
  require "session-public-all-replies" (reused.replies.length == 21 && roots.length == 7)
  for index in List.range roots.length do
    match reused.replies.drop (3 * index) with
    | .checked _ :: .normalized value :: .equal true :: _ =>
        require "session-public-exact-whnf" (psKernelExprEqual value seven)
    | _ => throw (IO.userError "session-public-reply-kind")
  let some oldOwner := psKernelExprV2DeclarationRefFind installed.declarations oldRec.base.name
    | throw (IO.userError "session-old-recursor-owner")
  let missing := installed.declarations.filter fun owner => !psKernelNameEq owner.name oldRec.base.name
  let mismatched := { oldOwner with kind := .axiomDecl } :: missing
  let some (_,_,firstRoot) := roots.head? | throw (IO.userError "session-first-root")
  for owners in [missing,mismatched] do
    require "session-stale-or-mismatched-owner-declines"
      (psKernelExprV2TryWhnfOwnedWithDeclarationsFuel 4096 scalar installed.arena owners firstRoot).isNone
  let privateId := input.size
  let badCommands : List PsKernelDagCommand := [
    .check privateId, .whnf privateId, .isDefEq privateId sevenId, .isDefEq sevenId privateId,
    .admit (.axiomDecl (PsKernelDagConstantBase.mk (nm "SessionPrivateId") [] privateId) false)]
  for command in badCommands do
    require "session-private-ID-refused"
      (match psKernelV1RunDag session [] .safe input [command] with
       | .error (.rejectedInvalid text) => text == "PSKERNEL_V2_DECODE_INVALID_REFERENCE"
       | _ => false)
  let lateName := nm "SessionLateAtomic"
  require "session-late-command-failure-atomic"
    (rejected (psKernelV1RunDag session [] .safe input [
      .admit (.axiomDecl (PsKernelDagConstantBase.mk lateName [] natId) false), .check privateId]))
  require "session-failed-command-did-not-mutate"
    (!(psKernelEnvironmentContains session.environment lateName))
  let malformed := { psKernelExprV2PagedEmpty with pageLimit := 0 }
  let emptyState := PsKernelDagGeneratedState.mk malformed psKernelExprV2DecodedEmpty []
  let firstImported ← expect (psKernelDagGeneratedInstallSessionInfo (.axiomInfo axiomInfo) emptyState)
  require "session-fault-first-import-succeeds" (firstImported.declarations.length == 1)
  require "session-late-import-fault"
    (match psKernelDagGeneratedCompleteDemands session.environment.constants session.environment
        [axiomName,theoremName] emptyState with
     | .error _ => true | _ => false)
  require "session-public-rejects-malformed-owner-before-import"
    (rejected (psKernelV1RunDag session [] .safe malformed []))
  let fork7 ← expectPublic "session-fork7" (psKernelV1AdmitDeclaration prior (.definitionDecl definition))
  let eight := PsKernelExpr.lit (.nat 8)
  let fork8 ← expectPublic "session-fork8"
    (psKernelV1AdmitDeclaration prior (.definitionDecl { definition with value := eight }))
  let some (_,_,definitionId) := roots.getLast? | throw (IO.userError "session-definition-root")
  for (fork,expected) in [(fork7.session,seven),(fork8.session,eight),
      (fork7.session,seven),(fork8.session,eight)] do
    let owner ← expect (psKernelDagGeneratedFromSession fork input built)
    let context := (psKernelKernelSessionChecker fork [] .safe).context
    let direct ← attempt "session-fork-direct"
      (psKernelExprV2TryWhnfOwnedWithDeclarationsFuel 4096 context owner.arena owner.declarations definitionId)
    require "session-fork-direct-value" (psKernelExprEqual expected (← decode direct.fst direct.snd))
    let actual ← expectPublic "session-fork-public"
      (psKernelV1RunDag fork [] .safe input [.whnf definitionId])
    require "session-fork-public-value"
      (match actual.replies with | [.normalized value] => psKernelExprEqual value expected | _ => false)
  IO.println "PSC1_V2_SESSION_OWNERS: PASS kinds=8 direct=7 privateIDs=5 forks=2"
  IO.println "PSC1_V2_SESSION_OWNERS_OFFICIAL: PASS declarations=4 direct=7"

def regression : IO Unit := do
  let empty ← expectPublic "empty" (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  -- Padding makes every owned input reference nonzero.
  let (padding,_) ← expect (psKernelExprV2PagedMkLit psKernelExprV2PagedEmpty (.nat 53))
  let natDecl := PsKernelSimpleInductiveDecl.mk [] psKernelNatName s1
    [PsKernelSimpleConstructorDecl.mk psKernelNatZeroName nat,
     PsKernelSimpleConstructorDecl.mk psKernelNatSuccName (pi "n" nat nat)] false 0
  let mut prepared ← prepareOrdinary (Prepared.mk empty padding [] []) natDecl
  for i in List.range 32 do
    prepared ← prepareAxiom prepared (.num (nm "PrefixOld") i)
  let old := prepared
  let root := PsKernelName.num (nm "PrefixOwner") 7
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
  let mutualPrepared := prepared
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
  let fastPrepared := prepared
  prepared ← prepareAxiom prepared (PsKernelName.str root "after")
  let treePrefix := newPrefix beforeTree.session.environment treePrepared.session.environment.constants
  let treeRecursors := treePrefix.filterMap fun info =>
    match info with | .recInfo rec => some rec | _ => none
  require "genuine-nested-restoration"
    (treeRecursors.length == 2 &&
      (match psKernelEnvironmentFind prepared.session.environment treeName with
       | some (.inductInfo info) => info.numNested == 1 | _ => false))
  let some aux := treeRecursors.find? fun rec =>
    rec.rules.any fun rule => psKernelNameEq rule.ctor nilName
    | throw (IO.userError "missing actual final auxiliary recursor")
  let leaf := constE leafName
  let listNil := app (constE nilName [.zero]) [tree]
  let listCons := app (constE consName [.zero]) [tree,leaf,listNil]
  let aMajor := app (constE amk [.zero,.zero]) [constE bbase [.zero,.zero]]
  let bMajor := app (constE bmk [.zero,.zero]) [constE abase [.zero,.zero]]
  let aRec ← recInfo prepared.session.environment (psKernelSimpleRecName a)
  let bRec ← recInfo prepared.session.environment (psKernelSimpleRecName b)
  let treeRec ← recInfo prepared.session.environment (psKernelSimpleRecName treeName)
  let fastRec ← recInfo prepared.session.environment (psKernelSimpleRecName fastName)
  let cases := [
    ("mutual-left",← recApplication aRec [u,v] aMajor),
    ("mutual-right",← recApplication bRec [u,v] bMajor),
    ("nested-leaf",← recApplication treeRec [] leaf),
    ("nested-branch",← recApplication treeRec [] (app (constE branchName) [listCons])),
    ("nested-aux",← recApplication aux [] listCons),
    ("nested-no-aux",← recApplication fastRec [] (constE fastCtor))]
  let mut input := prepared.arena
  let mut roots := []
  for (label,term) in cases do
    let (next,root) ← expect (psKernelExprV2PagedImportIntoChecked input term)
    input := next
    roots := roots ++ [(label,term,root)]
  let (next,fastCtorId) ← expect (psKernelExprV2PagedImportIntoChecked input (constE fastCtor))
  let (next,sevenId) ← expect (psKernelExprV2PagedImportIntoChecked next seven)
  input := next
  let built ← expect (psKernelExprV2DecodeChecked input)
  let mut generated := PsKernelDagGeneratedState.mk input built []
  let mut newCount := 0
  let mut recCount := 0
  for transition in prepared.transitions do
    let refs := psKernelDagDeclarationsAfterAdmission transition.request []
    generated := { generated with
      declarations := psKernelDagDeclarationsAfterAdmission transition.request generated.declarations }
    let before := generated
    generated ← expect (psKernelDagGeneratedAfterCommandWithPrevious (.admit transition.request)
      transition.previous transition.current generated)
    match transition.request with
    | .ordinaryInductive .. | .mutualInductive .. | .nestedInductive .. =>
        let delta := newPrefix transition.previous transition.current.constants
        newCount := newCount + delta.length
        for info in delta do
          let name := psKernelConstantInfoName info
          let some owner := psKernelExprV2DeclarationRefFind generated.declarations name
            | throw (IO.userError "new final checked declaration lacks owner")
          require "live-kind-type-and-no-delta"
            (psKernelExprV2DeclarationRefMatches owner info && owner.deltaValue.isNone &&
              psKernelExprEqual (psKernelConstantInfoType info) (← decode generated.arena owner.type))
          match psKernelExprV2DeclarationRefFind refs name with
          | some original =>
              require "exact-original-input-ID-reuse"
                (original.type > 0 && original.type == owner.type && owner.type < input.size)
              require "no-duplicate-input-owner"
                ((generated.declarations.filter fun row => psKernelNameEq row.name name).length == 1)
          | none =>
              require "restored-generated-ID-private" (owner.type >= input.size)
          match info with
          | .recInfo rec =>
              recCount := recCount + 1
              for rule in rec.rules do
                let some rhs := psKernelExprV2RecursorRuleOwner generated.declarations rec rule
                  | throw (IO.userError "missing final rule owner")
                require "final-rule-exact"
                  (psKernelExprEqual rule.rhs (← decode generated.arena rhs))
          | _ => pure ()
        require "input-IDs-never-rewritten" (generated.built.size == generated.arena.size)
        if !transition.previous.constants.isEmpty then
          let some oldHead := transition.previous.constants.head?
            | throw (IO.userError "missing old prefix boundary")
          let poison := PsKernelConstantInfo.axiomInfo
            (PsKernelAxiomInfo.mk (PsKernelConstantBase.mk (nm "PREFIX_POISON") [] s1) false)
          let boundary ← expect (psKernelDagGeneratedInstallNewPrefix
            (delta ++ [oldHead,poison]) transition.previous refs before)
          require "stop-at-old-entry-before-poison-tail"
            (boundary.arena.size == generated.arena.size &&
              boundary.declarations.length == generated.declarations.length)
    | _ =>
        require "non-inductive-owner-unchanged"
          (generated.arena.size == before.arena.size &&
            generated.declarations.length == before.declarations.length)
  -- Nat4 + mutual8 + List4 + nested Tree5 + Fast3 =24 final declarations.
  require "bounded-new-prefix-counts" (newCount == 24 && recCount == 7)
  -- No flattened datatype/constructor can leak: every installed ref has a live final owner.
  for owner in generated.declarations do
    require "no-flattening-only-owner" (psKernelEnvironmentContains prepared.session.environment owner.name)
  for index in List.range input.size do
    require "original-input-stable"
      (psKernelExprEqual (← expect (psKernelExprV2DecodedRequire built index))
        (← expect (psKernelExprV2DecodedRequire generated.built index)))
  Lean.initSearchPath (← Lean.findSysroot)
  let official0 ← Lean.importModules #[{ module := `Init }] {}
  let official1 ← officialGroup official0 mutualGroup
  let listGroup := PsKernelSimpleMutualInductiveDecl.mk [u] 1
    [PsKernelSimpleMutualTypeDecl.mk listDecl.name listDecl.type listDecl.ctors] false
  let official2 ← officialGroup official1 listGroup
  let official3 ← officialGroup official2 treeGroup
  let official ← officialGroup official3 fastGroup
  let scalar := (psKernelKernelSessionChecker prepared.session [] .safe).context
  for (label,term,root) in roots do
    let checked ← attempt (label ++ "-check")
      (psKernelExprV2TryCheckWithDeclarationsFuel 4096 scalar generated.arena generated.declarations root)
    let checkedType ← decode checked.fst checked.snd
    let normalizedType ← expectPublic (label ++ "-normalized-type")
      (psKernelV1Whnf prepared.session [] .safe checkedType)
    require (label ++ "-type") (psKernelExprEqual nat normalizedType)
    let normalized ← attempt (label ++ "-whnf")
      (psKernelExprV2TryWhnfOwnedWithDeclarationsFuel 4096 scalar
        generated.arena generated.declarations root)
    require (label ++ "-iota") (psKernelExprEqual seven (← decode normalized.fst normalized.snd))
    let equal ← attempt (label ++ "-defeq")
      (psKernelExprV2TryDefEqWithDeclarationsFuel 4096 scalar
        generated.arena generated.declarations root sevenId)
    require (label ++ "-equality") equal
    require (label ++ "-V1")
      (psKernelExprEqual seven (← expectPublic label (psKernelV1Whnf prepared.session [] .safe term)))
    require (label ++ "-official")
      (match Lean.Kernel.check official {} (officialExpr term) with | .ok _ => true | _ => false)
    require (label ++ "-official-defeq")
      (match Lean.Kernel.isDefEq official {} (officialExpr term) (officialExpr seven) with
       | .ok true => true | _ => false)
    let positive := PsKernelDefinitionInfo.mk
      (PsKernelConstantBase.mk (nm (label ++ "-checked")) [] nat) term .abbrevHint .safe
    let _ ← expectPublic (label ++ "-definition") (psKernelV1AdmitDeclaration prepared.session (.definitionDecl positive))
    let officialPositive := official.addDeclCore 0 0 (.defnDecl {
      name := officialName positive.base.name
      levelParams := []
      type := officialExpr nat
      value := officialExpr term
      hints := .abbrev
      safety := .safe
    }) none true
    require (label ++ "-official-definition")
      (match officialPositive with | .ok _ => true | _ => false)
    let wrong := { positive with base := { positive.base with type := s1 } }
    require (label ++ "-invalid-definition")
      (rejected (psKernelV1AdmitDeclaration prepared.session (.definitionDecl wrong)))
    require (label ++ "-official-invalid-definition")
      (match official.addDeclCore 0 0 (.defnDecl {
          name := officialName wrong.base.name
          levelParams := []
          type := officialExpr s1
          value := officialExpr term
          hints := .abbrev
          safety := .safe
        }) none true with | .error _ => true | _ => false)
  let result ← expectPublic "whole-batch" (psKernelV1RunDag empty [] .safe input
    (prepared.commands ++ roots.flatMap fun (_,_,root) =>
      [.check root,.whnf root,.isDefEq root sevenId]))
  require "whole-batch-complete" (result.replies.length == prepared.commands.length + 18)
  -- The historical low-level compatibility helper owns only this new Fast family.
  -- Public preexisting-session ownership is checked separately below.
  let firstBatch ← expectPublic "first-batch"
    (psKernelV1RunDag empty [] .safe input treePrepared.commands)
  let some fastTransition := fastPrepared.transitions.getLast?
    | throw (IO.userError "fast transition")
  let secondBatch ← expectPublic "second-batch" (psKernelV1RunDag firstBatch.session [] .safe input
    [.admit fastTransition.request,.check fastCtorId])
  require "two-public-batches" (secondBatch.replies.length == 2)
  let secondAdmitted ← expectPublic "second-owner-admission"
    (psKernelDagRunCommand (PsKernelDagExecutionState.mk firstBatch.session []) [] .safe
      input built (.admit fastTransition.request))
  let secondOwner ← expect (psKernelDagGeneratedAfterCommandWithPrevious
    (.admit fastTransition.request) firstBatch.session.environment
    secondAdmitted.snd.session.environment
    (PsKernelDagGeneratedState.mk input built secondAdmitted.snd.declarations))
  require "second-owner-does-not-invent-old-session-refs"
    (psKernelExprV2DeclarationRefFind secondOwner.declarations psKernelNatName).isNone
  let secondScalar := (psKernelKernelSessionChecker secondAdmitted.snd.session [] .safe).context
  let secondChecked ← attempt "second-batch-direct-new-constructor"
    (psKernelExprV2TryCheckWithDeclarationsFuel 4096 secondScalar
      secondOwner.arena secondOwner.declarations fastCtorId)
  require "second-batch-direct-type"
    (psKernelExprEqual (constE fastName) (← decode secondChecked.fst secondChecked.snd))
  let privateId := input.size
  for command in [.check privateId,.whnf privateId,.isDefEq privateId sevenId] do
    require "private-ID-refused-after-generated-append"
      (match psKernelV1RunDag empty [] .safe input (prepared.commands ++ [command]) with
       | .error (.rejectedInvalid text) => text == "PSKERNEL_V2_DECODE_INVALID_REFERENCE"
       | _ => false)
  let some mutualTransition := mutualPrepared.transitions.getLast?
    | throw (IO.userError "mutual transition")
  require "late-invalid-command-atomic"
    (rejected (psKernelV1RunDag empty [] .safe input
      (prepared.commands ++ [.admit mutualTransition.request])))
  require "original-session-unchanged"
    (!(psKernelEnvironmentContains empty.environment a) &&
      !(psKernelEnvironmentContains old.session.environment a))
  let broken := psKernelExprV2DecodedPush built s1
  require "internal-import-error-does-not-publish-batch"
    (match psKernelDagRunCommandsWithSource prepared.commands built
        (PsKernelDagExecutionState.mk empty []) [] .safe input broken with
     | .error (.internalError text) => text == "PSKERNEL_V2_GENERATED_OWNER_MISMATCH"
     | _ => false)
  let poison := PsKernelConstantInfo.axiomInfo
    (PsKernelAxiomInfo.mk (PsKernelConstantBase.mk (nm "PREFIX_LATE_POISON") [] s1) false)
  require "late-new-kind-error-discards-successful-first-import"
    (match psKernelDagGeneratedInstallNewPrefix [.recInfo aRec,poison]
        old.session.environment [] (PsKernelDagGeneratedState.mk input built []) with
     | .error text => text == "PSKERNEL_V2_GENERATED_PREFIX_KIND"
     | _ => false)
  let missing := generated.declarations.filter fun owner => !psKernelNameEq owner.name aRec.base.name
  require "missing-rule-owner-does-not-authorize"
    (aRec.rules.all fun rule => (psKernelExprV2RecursorRuleOwner missing aRec rule).isNone)
  let some aOwner := psKernelExprV2DeclarationRefFind generated.declarations aRec.base.name
    | throw (IO.userError "missing a owner")
  let mismatched := { aOwner with kind := .axiomDecl } :: missing
  require "mismatched-rule-owner-does-not-authorize"
    (aRec.rules.all fun rule => (psKernelExprV2RecursorRuleOwner mismatched aRec rule).isNone)
  let some (_,_,aRoot) := roots.head? | throw (IO.userError "missing direct mutual root")
  require "missing-owner-direct-reduction-declines"
    (psKernelExprV2TryWhnfOwnedWithDeclarationsFuel 4096 scalar generated.arena missing aRoot).isNone
  require "mismatched-owner-direct-reduction-declines"
    (psKernelExprV2TryWhnfOwnedWithDeclarationsFuel 4096 scalar generated.arena mismatched aRoot).isNone
  let wrongLevels := constE aRec.base.name []
  let (negativeArena,negativeRoot) ← expect
    (psKernelExprV2PagedImportIntoChecked generated.arena wrongLevels)
  require "malformed-universe-rejected-before-owner"
    (match psKernelExprV2TryCheckWithDeclarationsFuel 4096 scalar negativeArena missing negativeRoot with
     | some (.error text) => text == "incorrect number of universe levels"
     | _ => false)
  require "official-malformed-universe"
    (match Lean.Kernel.check official {} (officialExpr wrongLevels) with | .error _ => true | _ => false)
  IO.println "PSC1_V2_GENERATED_PREFIX: PASS new=24 recursors=7 direct=6 privateIDs=3"
  IO.println "PSC1_V2_GENERATED_PREFIX_OFFICIAL: PASS families=5 positive=6 negative=7"
  sessionOwnersRegression result.session official cases aRec

end PsKernelExprV2GeneratedPrefixRegression

def main : IO Unit := PsKernelExprV2GeneratedPrefixRegression.regression
