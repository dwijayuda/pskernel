import Ps.Syntax.Translate
import Ps.Bridge.CheckedAdmissions
import Ps.Elab.Declaration
import Ps.Erasure.Definition
import Ps.Compiler.WellFoundedRuntime

inductive PsCompilerSourceKind where
  | lean
  | proofScript

def psCompilerSourceKindLabel : PsCompilerSourceKind → String
  | .lean => "lean"
  | .proofScript => "proofscript"

def psCompilerSourceKindExtension : PsCompilerSourceKind → String
  | .lean => ".lean"
  | .proofScript => ".ps"

-- Filename interpretation is a host boundary, not a semantic fallback. The
-- portable API receives an explicit source kind independently of provenance.
def psCompilerSourceKindOfPath (path : String) : Except String PsCompilerSourceKind :=
  if path.endsWith ".lean" then .ok .lean
  else if path.endsWith ".ps" then .ok .proofScript
  else .error "PSCV0-NATIVE-INPUT: expected .ps or .lean v7.2 input"

inductive PsCompilerError where
  | normalization (message : String)
  | translation (error : PsTranslationError)
  | leanFrontend (error : PsLeanFrontendError)
  | proofScriptFrontend (error : PsProofScriptFrontendError)
  | elaboration (error : PsElabError)
  | admission (error : PsCheckedAdmissionCodecError)
  | erasure (error : PsErasureError)

structure PsCompilerAdmissionReadyModule where
  declarations : List PsDeclaration
  -- Locators for ordinary definitions retained in declarations, never checker
  -- authority. Erasure validates every complete companion equation afresh.
  recursorWorkerGroups : List PsRecursorWorkerGroup := []
  -- Source execution policy is separate from the unchanged checked graph.
  noncomputableNames : List PsName := []

-- A preparation checkpoint is local to one compiler instance. Keep the complete
-- environment and declaration accumulator together; neither is a checked claim.
structure PsCompilerPreparationState where
  sourceKind : PsCompilerSourceKind
  environment : PsEnvironment
  declarationsRev : List PsDeclaration

-- These are retained results, not authority tokens. The source-owned entry
-- point establishes their provenance by constructing and consuming them itself.
structure PsCompilerPreparationOutput where
  prepared : PsCompilerAdmissionReadyModule
  environment : PsEnvironment
  admissions : String
  originParents : List (PsName × PsName) := []

structure PsCompilerPreparationStepWithOriginsResult where
  state : PsCompilerPreparationState
  origins : List PsElabBatchOrigin

-- A caller-owned choice of actual library inputs, never an admission token.
-- A trusted host must bind its authorized context to the exact canonical
-- environment and runtime contract before consuming external artifacts.
-- Names, claimed digests, cached prepared values and this record alone cannot
-- authenticate a profile or upgrade source/backend assurance.
structure PsCompilerProfileContext where
  baseEnvironment : PsEnvironment
  runtimePrelude : PsEnvironment → Option PsVerifiedIrWordSize → List PsDeclaration

-- Keep the chosen context with every internal phase result. The compatibility
-- records above retain their existing public shapes for the Full API only.
structure PsCompilerEngineElaborated where
  environment : PsEnvironment
  declarations : List PsDeclaration
  profile : PsCompilerProfileContext

structure PsCompilerEnginePrepared where
  declarations : List PsDeclaration
  recursorWorkerGroups : List PsRecursorWorkerGroup := []
  noncomputableNames : List PsName := []
  profile : PsCompilerProfileContext

structure PsCompilerEnginePreparationState where
  sourceKind : PsCompilerSourceKind
  environment : PsEnvironment
  declarationsRev : List PsDeclaration
  profile : PsCompilerProfileContext

structure PsCompilerEnginePreparationOutput where
  prepared : PsCompilerEnginePrepared
  environment : PsEnvironment
  admissions : String
  originParents : List (PsName × PsName) := []

structure PsCompilerEnginePreparationStepWithOriginsResult where
  state : PsCompilerEnginePreparationState
  origins : List PsElabBatchOrigin

-- Check the retained partial implementation as an ordinary opaque body,
-- AFTER its separately inhabited public logical identity. This is a checking
-- view only: retain the original strategy marker in the prepared graph.
-- No body equation, runtime override, unchecked admission or new axiom is
-- introduced. An invalid self-reference is still rejected by the kernel.
def psCompilerLogicalCheckingView (declarations : List PsDeclaration) : List PsDeclaration :=
  declarations.map fun declaration =>
    match declaration with
    | .partialDecl name levels type value => .opaqueDecl name levels type value
    | _ => declaration

def psCompilerTranslateSource
    (sourceKind targetKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError String :=
  let translated : Except PsTranslationError String :=
    match sourceKind with
    | PsCompilerSourceKind.lean =>
        match targetKind with
        | PsCompilerSourceKind.lean =>
            psCanonicalizeLeanSource source
        | PsCompilerSourceKind.proofScript =>
            psTranslateLeanToProofScript source
    | PsCompilerSourceKind.proofScript =>
        match targetKind with
        | PsCompilerSourceKind.lean =>
            psTranslateProofScriptToLean source
        | PsCompilerSourceKind.proofScript =>
            psCanonicalizeProofScriptSource source;
  match translated with
  | Except.error error =>
      Except.error (PsCompilerError.translation error)
  | Except.ok output =>
      Except.ok output

def psCompilerParseSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError PsSyntaxModule :=
  match sourceKind with
  | PsCompilerSourceKind.lean =>
      match psParseLeanSource source with
      | Except.error error =>
          Except.error (PsCompilerError.leanFrontend error)
      | Except.ok sourceModule =>
          Except.ok sourceModule
  | PsCompilerSourceKind.proofScript =>
      match psParseProofScriptSource source with
      | Except.error error =>
          Except.error (PsCompilerError.proofScriptFrontend error)
      | Except.ok sourceModule =>
          Except.ok sourceModule

def psCompilerEngineElaborateModule
    (profile : PsCompilerProfileContext)
    (sourceModule : PsSyntaxModule) :
    Except PsCompilerError PsCompilerEngineElaborated :=
  match psElabModule profile.baseEnvironment sourceModule with
  | Except.error error =>
      Except.error (PsCompilerError.elaboration error)
  | Except.ok elaborated =>
      Except.ok (PsCompilerEngineElaborated.mk
        elaborated.environment elaborated.declarations profile)

def psCompilerEngineElaborateSource
    (profile : PsCompilerProfileContext)
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError PsCompilerEngineElaborated :=
  match psCompilerParseSource sourceKind source with
  | Except.error error =>
      Except.error error
  | Except.ok sourceModule =>
      psCompilerEngineElaborateModule profile sourceModule

def psCompilerEnginePrepareElaboratedWithOutput
    (elaborated : PsCompilerEngineElaborated) :
    Except PsCompilerError PsCompilerEnginePreparationOutput := do
  let profile := elaborated.profile
  let lifted ← (psRecursorLiftDeclarationsWithOrigins elaborated.environment
    elaborated.declarations).mapError PsCompilerError.normalization
  let elaborated := lifted.result
  match
      psEncodeCheckedAdmissionsCanonicalIn elaborated.environment
        (psCompilerLogicalCheckingView elaborated.declarations) with
  | Except.error error =>
      Except.error (PsCompilerError.admission error)
  | Except.ok canonicalAdmissions =>
      let prepared : PsCompilerEnginePrepared := {
        declarations := elaborated.declarations
        recursorWorkerGroups := lifted.workerGroups
        noncomputableNames := elaborated.declarations.filterMap (fun declaration =>
          let name := psDeclarationName declaration
          if psEnvironmentIsNoncomputable elaborated.environment name then some name else none)
        profile := profile };

      let admissions : String := String.Internal.append canonicalAdmissions "\n";
      Except.ok
        (PsCompilerEnginePreparationOutput.mk prepared elaborated.environment admissions lifted.parents)

def psCompilerEnginePrepareElaborated
    (elaborated : PsCompilerEngineElaborated) :
    Except PsCompilerError PsCompilerEnginePrepared :=
  match psCompilerEnginePrepareElaboratedWithOutput elaborated with
  | Except.error error => Except.error error
  | Except.ok output => Except.ok output.prepared

def psCompilerEngineCheckElaborated
    (elaborated : PsCompilerEngineElaborated) :
    Except PsCompilerError PsCompilerEnginePrepared :=
  psCompilerEnginePrepareElaborated elaborated

def psCompilerEnginePrepareSource
    (profile : PsCompilerProfileContext)
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError PsCompilerEnginePrepared :=
  match psCompilerEngineElaborateSource profile sourceKind source with
  | Except.error error =>
      Except.error error
  | Except.ok elaborated =>
      psCompilerEnginePrepareElaborated elaborated

-- Preparation remains pure. Hosts may retain a successful ordered prefix and
-- resume it only when its exact compiler, source kind and source prefix agree.
def psCompilerEnginePreparationStart
    (profile : PsCompilerProfileContext)
    (sourceKind : PsCompilerSourceKind) : PsCompilerEnginePreparationState :=
  PsCompilerEnginePreparationState.mk
    sourceKind profile.baseEnvironment List.nil profile

-- One actual elaboration supplies both the next state and source-local origins.
-- The surrounding source-owned caller attaches module identity to these records.
def psCompilerEnginePreparationStepParsedWithOrigins
    (state : PsCompilerEnginePreparationState)
    (sourceModule : PsSyntaxModule) :
    Except PsElabOriginError PsCompilerEnginePreparationStepWithOriginsResult :=
  match psElabModuleWithOrigins state.environment sourceModule with
  | Except.error error => Except.error error
  | Except.ok elaborated =>
      let nextState : PsCompilerEnginePreparationState :=
        PsCompilerEnginePreparationState.mk
          state.sourceKind elaborated.result.environment
          (psListAppend
            (psListReverse elaborated.result.declarations) state.declarationsRev) state.profile;
      Except.ok
        (PsCompilerEnginePreparationStepWithOriginsResult.mk nextState elaborated.origins)

def psCompilerEnginePreparationStepParsed
    (state : PsCompilerEnginePreparationState)
    (sourceModule : PsSyntaxModule) :
    Except PsCompilerError PsCompilerEnginePreparationState :=
  match psCompilerEnginePreparationStepParsedWithOrigins state sourceModule with
  | Except.error error => Except.error (PsCompilerError.elaboration error.error)
  | Except.ok result => Except.ok result.state

def psCompilerEnginePreparationStep
    (state : PsCompilerEnginePreparationState)
    (source : String) :
    Except PsCompilerError PsCompilerEnginePreparationState :=
  match psCompilerParseSource state.sourceKind source with
  | Except.error error => Except.error error
  | Except.ok sourceModule =>
      psCompilerEnginePreparationStepParsed state sourceModule

def psCompilerEnginePreparationElaborated
    (state : PsCompilerEnginePreparationState) : PsCompilerEngineElaborated :=
  PsCompilerEngineElaborated.mk state.environment (psListReverse state.declarationsRev) state.profile

def psCompilerEnginePreparationFinishWithOutput
    (state : PsCompilerEnginePreparationState) :
    Except PsCompilerError PsCompilerEnginePreparationOutput :=
  psCompilerEnginePrepareElaboratedWithOutput (psCompilerEnginePreparationElaborated state)

def psCompilerEnginePreparationFinish
    (state : PsCompilerEnginePreparationState) :
    Except PsCompilerError PsCompilerEnginePrepared :=
  match psCompilerEnginePreparationFinishWithOutput state with
  | Except.error error => Except.error error
  | Except.ok output => Except.ok output.prepared

def psCompilerEnginePreparationSourcesWorker
    (sources : List String)
    (state : PsCompilerEnginePreparationState) :
    Except PsCompilerError PsCompilerEnginePreparationState :=
  match sources with
  | List.nil =>
      Except.ok state
  | List.cons source rest =>
      match psCompilerEnginePreparationStep state source with
      | Except.error error => Except.error error
      | Except.ok next => psCompilerEnginePreparationSourcesWorker rest next

def psCompilerEngineElaborateSourcesWorker
    (profile : PsCompilerProfileContext)
    (sourceKind : PsCompilerSourceKind) (sources : List String) :
    PsEnvironment -> List PsDeclaration -> Except PsCompilerError PsCompilerEngineElaborated :=
  fun (environment : PsEnvironment) (declarationsRev : List PsDeclaration) =>
    match
        psCompilerEnginePreparationSourcesWorker sources
          (PsCompilerEnginePreparationState.mk sourceKind environment declarationsRev profile) with
    | Except.error error => Except.error error
    | Except.ok state => Except.ok (psCompilerEnginePreparationElaborated state)

def psCompilerEnginePrepareSources
    (profile : PsCompilerProfileContext)
    (sourceKind : PsCompilerSourceKind) (sources : List String) :
    Except PsCompilerError PsCompilerEnginePrepared :=
  match
      psCompilerEnginePreparationSourcesWorker sources
        (psCompilerEnginePreparationStart profile sourceKind) with
  | Except.error error => Except.error error
  | Except.ok state => psCompilerEnginePreparationFinish state

def psCompilerEngineCheckSource
    (profile : PsCompilerProfileContext)
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError PsCompilerEnginePrepared :=
  psCompilerEnginePrepareSource profile sourceKind source

def psCompilerEngineValidatePrepared
    (prepared : PsCompilerEnginePrepared) :
    Except PsCompilerError Unit :=
  match
      psEncodeCheckedAdmissionsCanonicalIn prepared.profile.baseEnvironment
        (psCompilerLogicalCheckingView prepared.declarations) with
  | Except.error error =>
      Except.error (PsCompilerError.admission error)
  | Except.ok _ =>
      Except.ok Unit.unit

def psCompilerEngineAdmissionsFromPrepared
    (prepared : PsCompilerEnginePrepared) :
    Except PsCompilerError String :=
  match psEncodeCheckedAdmissionsCanonicalIn prepared.profile.baseEnvironment
      (psCompilerLogicalCheckingView prepared.declarations) with
  | Except.error error =>
      Except.error (PsCompilerError.admission error)
  | Except.ok canonicalAdmissions =>
      Except.ok (String.Internal.append canonicalAdmissions "\n")

def psCompilerEngineAdmissionsFromElaborated
    (elaborated : PsCompilerEngineElaborated) :
    Except PsCompilerError String :=
  match psCompilerEnginePrepareElaborated elaborated with
  | Except.error error =>
      Except.error error
  | Except.ok prepared =>
      psCompilerEngineAdmissionsFromPrepared prepared

def psCompilerEngineAdmissionsSource
    (profile : PsCompilerProfileContext)
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError String :=
  match psCompilerEnginePrepareSource profile sourceKind source with
  | Except.error error =>
      Except.error error
  | Except.ok prepared =>
      psCompilerEngineAdmissionsFromPrepared prepared

def psCompilerEngineEnvironmentFromPrepared
    (prepared : PsCompilerEnginePrepared) :
    Except PsCompilerError PsEnvironment :=
  match psCompilerEngineValidatePrepared prepared with
  | Except.error error =>
      Except.error error
  | Except.ok _ =>
      match
          psAddDeclarationList
            prepared.profile.baseEnvironment
            prepared.declarations with
      | Except.error error =>
          Except.error (PsCompilerError.elaboration error)
      | Except.ok environment =>
          Except.ok (prepared.noncomputableNames.foldl psEnvironmentMarkNoncomputable environment)

-- Runtime substitution is permitted only for the checked fixedpoint layout
-- emitted by the predefinition owner. The equation alone is insufficient:
-- a true f = f equation must not authorize an unrelated recursive body.
private structure PsCompilerFixedpointRuntimeMember where
  name : PsName
  levels : List PsName
  type : PsExpr
  body : PsExpr
  auxiliary : PsName
  path : List Nat

private def psCompilerFixedpointProjectionView (levels : List PsName) :
    PsExpr → Option (PsName × List Nat)
  | .constE name arguments =>
    if psExprAlphaEq (.constE name arguments) (.constE name (levels.map PsLevel.param)) then
      some (name, [])
    else none
  | .proj typeName index value => do
    if !psNameEq typeName (psRootName "PProd") || index > 1 then none else do
      let (name, path) ← psCompilerFixedpointProjectionView levels value
      return (name, path ++ [index])
  | _ => none

private def psCompilerFixedpointPath (count index : Nat) : List Nat :=
  match count with
  | 0 | 1 => []
  | count + 2 =>
    match index with
    | 0 => [0]
    | index + 1 => 1 :: psCompilerFixedpointPath (count + 1) index

private def psCompilerFixedpointProject (path : List Nat) (value : PsExpr) : PsExpr :=
  path.foldl (fun value index => .proj (psRootName "PProd") index value) value

private def psCompilerFixedpointReplacePeers
    (members : List PsCompilerFixedpointRuntimeMember) (expression : PsExpr) : PsExpr :=
  match expression with
  | .constE name levels =>
    match members.find? (fun member =>
        psExprAlphaEq (.constE name levels) (.constE member.name (member.levels.map PsLevel.param))) with
    | some member => psCompilerFixedpointProject member.path (.fvar 0)
    | none => expression
  | .app fn argument =>
    .app (psCompilerFixedpointReplacePeers members fn)
      (psCompilerFixedpointReplacePeers members argument)
  | .lam name type body binder =>
    .lam name (psCompilerFixedpointReplacePeers members type)
      (psCompilerFixedpointReplacePeers members body) binder
  | .forallE name type body binder =>
    .forallE name (psCompilerFixedpointReplacePeers members type)
      (psCompilerFixedpointReplacePeers members body) binder
  | .letE name type value body =>
    .letE name (psCompilerFixedpointReplacePeers members type)
      (psCompilerFixedpointReplacePeers members value)
      (psCompilerFixedpointReplacePeers members body)
  | .proj typeName index value =>
    .proj typeName index (psCompilerFixedpointReplacePeers members value)
  | _ => expression

-- Member projection paths determine the leaves. Do not flatten a member
-- merely because its own function/result type contains a PProd.
private def psCompilerFixedpointPack
    (entries : List (PsCompilerFixedpointRuntimeMember × PsExpr))
    (packedType : PsExpr) : Except String PsExpr := do
  match entries with
  | [] => throw "empty fixedpoint component"
  | [(member, value)] =>
    if !psExprAlphaEq member.type packedType then throw "last packed member type mismatch"
    return value
  | (member, value) :: rest =>
    let view := psReduceAppView packedType
    let .constE name [leftSort, rightSort] := view.head
      | throw "packed carrier is not an exact PProd"
    if !psNameEq name (psRootName "PProd") then throw "packed carrier is not PProd"
    let [leftType, rightType] := view.args | throw "packed carrier arity mismatch"
    if !psExprAlphaEq member.type leftType then throw "packed member type mismatch"
    let tail ← psCompilerFixedpointPack rest rightType
    return psExprApplyMany
      (.constE (psNameAppendStr (psRootName "PProd") "mk") [leftSort, rightSort])
      [leftType, rightType, value, tail]

private def psCompilerFixedpointCheckComponent
    (declarations : List PsDeclaration)
    (members : List PsCompilerFixedpointRuntimeMember) (auxiliary : PsName) :
    Except String Unit := do
  let component := members.filter (fun member => psNameEq member.auxiliary auxiliary)
  if component.isEmpty then throw "empty fixedpoint component"
  let ordered ← (List.range component.length).mapM fun index => do
    let path := psCompilerFixedpointPath component.length index
    match component.filter (fun member => member.path == path) with
    | [member] => pure member
    | _ => throw "missing or duplicate packed member projection"
  let first :: _ := ordered | throw "empty fixedpoint component"
  if !psNameEq auxiliary (PsName.num first.name 1) then
    throw "fixedpoint auxiliary does not belong to the first packed member"
  let some (.definitionDecl _ levels packedType fixedValue) :=
      psCompilerRuntimeUnique declarations auxiliary
    | throw "missing unique checked fixedpoint auxiliary"
  if !psCompilerRuntimeClosed packedType || !psCompilerRuntimeClosed fixedValue ||
      !(ordered.all (fun member => psCompilerRuntimeLevelsEq levels member.levels)) then
    throw "fixedpoint auxiliary or member universes are not closed and shared"
  let fixed := psReduceAppView fixedValue
  let .constE fixedName [_] := fixed.head | throw "auxiliary is not an exact Order.fix"
  if !psNameEq fixedName (psNameAppendStr
      (psNameAppendStr (psRootName "Lean") "Order") "fix") then
    throw "auxiliary is not Order.fix"
  let [fixedType, _, functional, _] := fixed.args
    | throw "Order.fix does not have its exact four arguments"
  if !psExprAlphaEq fixedType packedType then throw "Order.fix carrier mismatch"
  let .lam _ functionalType _ .explicit := functional
    | throw "fixedpoint functional is not an explicit lambda"
  if !psExprAlphaEq functionalType packedType then throw "functional domain mismatch"
  for member in ordered do
    let some (.theoremDecl _ equationLevels equationType equationProof) :=
        psCompilerRuntimeUnique declarations (PsName.num member.name 2)
      | throw "missing unique checked whole-function equation"
    if !psCompilerRuntimeLevelsEq levels equationLevels ||
        !psCompilerRuntimeClosed equationType || !psCompilerRuntimeClosed equationProof then
      throw "whole-function equation is not closed at the component universes"
    let equation := psReduceAppView equationType
    let .constE equationName [_] := equation.head | throw "whole-function equation is not Eq"
    if !psNameEq equationName (psRootName "Eq") then throw "whole-function equation is not Eq"
    let [type, left, right] := equation.args | throw "whole-function equation arity mismatch"
    if !psExprAlphaEq type member.type ||
        !psExprAlphaEq left (.constE member.name (levels.map PsLevel.param)) ||
        !psExprAlphaEq right member.body then
      throw "whole-function equation does not state the exact retained body"
  let entries ← ordered.mapM fun member => do
    let restored ← psCompilerRuntimeRestore 4096 declarations auxiliary member.body
    return (member, psCompilerFixedpointReplacePeers ordered restored)
  let body ← psCompilerFixedpointPack entries packedType
  let reconstructed := PsExpr.lam (psRootName "$psc0Fix") packedType
    (psExprAbstractFVar 0 body) .explicit
  let restored ← psCompilerRuntimeRestore 4096 declarations auxiliary functional
  let reconstructed ← psCompilerRuntimeRestore 4096 declarations auxiliary reconstructed
  if !psExprAlphaEq restored reconstructed then
    throw "retained source bodies do not reconstruct the checked fixedpoint functional"

-- The official checker sees the original logical graph. Ordinary execution
-- uses the separately checked actual bodies only after validating their owner:
-- an inhabited opaque declaration (P0), or the complete Order.fix layout (P1).
-- This is never a proof equation or authorization for verified emission.
private def psCompilerOrdinaryPartialRuntimeView
    (declarations : List PsDeclaration) :
    Except PsCompilerError (List PsDeclaration × List PsName) := do
  let implementations := declarations.filter fun declaration =>
    match declaration with | .partialDecl .. => true | _ => false
  let mut members : List PsCompilerFixedpointRuntimeMember := []
  for implementation in implementations do
    let .partialDecl privateName levels type body := implementation
      | throw (.normalization "PSCV0-PARTIAL: malformed implementation marker")
    if (declarations.filter (fun declaration =>
        psNameEq (psDeclarationName declaration) privateName)).length != 1 then
      throw (.normalization "PSCV0-PARTIAL: duplicate implementation marker")
    let owners := declarations.filter fun declaration =>
      match declaration with
      | .opaqueDecl name .. | .definitionDecl name .. =>
        psNameEq (PsName.num name 0) privateName
      | _ => false
    match owners with
    | [owner] =>
      let (name, publicLevels, publicType, value, fixedpoint) :=
        match owner with
        | .opaqueDecl name levels type value => (name, levels, type, value, false)
        | .definitionDecl name levels type value => (name, levels, type, value, true)
        | _ => (.anonymous, [], .sortE .zero, .sortE .zero, false)
      if !psCompilerRuntimeLevelsEq levels publicLevels ||
          !psExprAlphaEq type publicType then
        throw (.normalization "PSCV0-PARTIAL: private implementation/type mismatch")
      if (declarations.filter (fun declaration =>
          psNameEq (psDeclarationName declaration) name)).length != 1 then
        throw (.normalization "PSCV0-PARTIAL: missing unique opaque logical owner")
      if fixedpoint then
        if !psCompilerRuntimeClosed type || !psCompilerRuntimeClosed body then
          throw (.normalization "PSCV0-FIXPOINT-RUNTIME: retained source body is not closed")
        let some (auxiliary, path) := psCompilerFixedpointProjectionView levels value
          | throw (.normalization "PSCV0-FIXPOINT-RUNTIME: public value is not an exact packed projection")
        members := members ++ [{ name, levels, type, body, auxiliary, path }]
    | _ => throw (.normalization "PSCV0-PARTIAL: missing unique opaque logical owner")
  let auxiliaries := members.foldl (fun names member =>
    if names.any (fun name => psNameEq name member.auxiliary) then names
    else names ++ [member.auxiliary]) ([] : List PsName)
  for auxiliary in auxiliaries do
    (psCompilerFixedpointCheckComponent declarations members auxiliary).mapError
      (fun message => .normalization ("PSCV0-FIXPOINT-RUNTIME: " ++ message))
  let runtime := declarations.filterMap fun declaration =>
    let omitted := match declaration with
      | .definitionDecl name .. => auxiliaries.any (fun auxiliary =>
        psNameEq name auxiliary || psCompilerRuntimeHelperOwned auxiliary name)
      | _ => false
    if omitted then none else
      match declaration with
      | .partialDecl .. => none
      | .opaqueDecl name levels type _ | .definitionDecl name levels type _ =>
        let candidate := implementations.find? fun implementation =>
          match implementation with
          | .partialDecl privateName .. => psNameEq (PsName.num name 0) privateName
          | _ => false
        match candidate with
        | some (.partialDecl _ _ _ body) => some (.definitionDecl name levels type body)
        | _ => some declaration
      | _ => some declaration
  return (runtime, auxiliaries)

def psCompilerOrdinaryPartialRuntimeDeclarations
    (declarations : List PsDeclaration) :
    Except PsCompilerError (List PsDeclaration) := do
  let result ← psCompilerOrdinaryPartialRuntimeView declarations
  return result.fst

-- Host-owned execution may erase a runtime representation ONLY after it
-- checked the ORIGINAL canonical logical admissions with Lean 4.35.0.
-- Keep the source logical environment; change only the runtime declaration
-- bodies/identities passed to erasure. The resulting IR still requires the
-- full typed validator and backend capability checks.
private def psCompilerEngineErasePreparedRuntimeViewWithGroups
    (prepared : PsCompilerEnginePrepared)
    (runtimeDeclarations : List PsDeclaration)
    (workerGroups : List PsRecursorWorkerGroup)
    (targetWordSize : Option PsVerifiedIrWordSize := none) :
    Except PsCompilerError PsVerifiedIrModule := do
  let environment ← psCompilerEngineEnvironmentFromPrepared prepared
  let runtimePrelude := prepared.profile.runtimePrelude environment targetWordSize
  (psEraseCoreModuleWithRuntimePrelude
    environment
    runtimePrelude
    runtimeDeclarations
    (runtimePrelude.map psDeclarationName ++ workerGroups.flatMap
      (fun group => group.workers.map (·.name))) targetWordSize
    workerGroups).mapError
      PsCompilerError.erasure

def psCompilerEngineErasePreparedRuntimeView
    (prepared : PsCompilerEnginePrepared)
    (runtimeDeclarations : List PsDeclaration)
    (targetWordSize : Option PsVerifiedIrWordSize := none) :
    Except PsCompilerError PsVerifiedIrModule :=
  psCompilerEngineErasePreparedRuntimeViewWithGroups prepared runtimeDeclarations
    prepared.recursorWorkerGroups targetWordSize

-- Ordinary partial execution only. The native host must have already
-- independently kernel-accepted psCompilerLogicalCheckingView on the exact
-- original prepared graph. A caller cannot mint proof authority via this API.
def psCompilerEngineOrdinaryPartialIrFromCheckedPrepared
    (prepared : PsCompilerEnginePrepared)
    (targetWordSize : Option PsVerifiedIrWordSize := none) :
    Except PsCompilerError PsVerifiedIrModule := do
  let (runtime, partialAuxiliaries) ← psCompilerOrdinaryPartialRuntimeView prepared.declarations
  let environment ← psCompilerEngineEnvironmentFromPrepared prepared
  let (runtime, totalAuxiliaries) ←
    (psCompilerWellFoundedRuntimeView environment prepared.declarations runtime).mapError
      PsCompilerError.elaboration
  let workerGroups ← (psCompilerRuntimeWorkerGroups prepared.recursorWorkerGroups
    (partialAuxiliaries ++ totalAuxiliaries)).mapError PsCompilerError.normalization
  psCompilerEngineErasePreparedRuntimeViewWithGroups prepared runtime workerGroups targetWordSize

def psCompilerEngineVerifiedIrFromPrepared
    (prepared : PsCompilerEnginePrepared)
    (targetWordSize : Option PsVerifiedIrWordSize := none) :
    Except PsCompilerError PsVerifiedIrModule := do
  -- The general source/library API must remain fail-closed for partial
  -- implementations. Only the native host's explicitly ordinary runtime
  -- path may lower the paired body, after real official kernel admission.
  if prepared.declarations.any (fun declaration =>
      match declaration with | .partialDecl .. => true | _ => false) then
    throw (.normalization "PSCV0-PARTIAL-RUNTIME-PENDING: partial logical checking does not admit executable output")
  let environment ← psCompilerEngineEnvironmentFromPrepared prepared
  let (runtime, auxiliaries) ←
    (psCompilerWellFoundedRuntimeView environment prepared.declarations prepared.declarations).mapError
      PsCompilerError.elaboration
  let groups ← (psCompilerRuntimeWorkerGroups prepared.recursorWorkerGroups auxiliaries).mapError
    PsCompilerError.normalization
  psCompilerEngineErasePreparedRuntimeViewWithGroups prepared runtime groups targetWordSize

def psCompilerEngineVerifiedIrFromElaborated
    (elaborated : PsCompilerEngineElaborated)
    (targetWordSize : Option PsVerifiedIrWordSize := none) :
    Except PsCompilerError PsVerifiedIrModule :=
  match psCompilerEnginePrepareElaborated elaborated with
  | Except.error error =>
      Except.error error
  | Except.ok prepared =>
      psCompilerEngineVerifiedIrFromPrepared prepared targetWordSize

def psCompilerEngineVerifiedIrSource
    (profile : PsCompilerProfileContext)
    (sourceKind : PsCompilerSourceKind)
    (source : String)
    (targetWordSize : Option PsVerifiedIrWordSize := none) :
    Except PsCompilerError PsVerifiedIrModule :=
  match psCompilerEnginePrepareSource profile sourceKind source with
  | Except.error error =>
      Except.error error
  | Except.ok prepared =>
      psCompilerEngineVerifiedIrFromPrepared prepared targetWordSize
