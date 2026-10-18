import Ps.Syntax.Translate
import Ps.Bridge.CheckedAdmissions
import Ps.Environment.SelfHostProd
import Ps.Elab.Declaration
import Ps.Erasure.Definition
import Ps.Compiler.RecursorLift

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

def psCompilerElaborateModule
    (sourceModule : PsSyntaxModule) :
    Except PsCompilerError PsElabModuleResult :=
  match psElabModule psSelfHostProdPreludeEnvironment sourceModule with
  | Except.error error =>
      Except.error (PsCompilerError.elaboration error)
  | Except.ok elaborated =>
      Except.ok elaborated

def psCompilerElaborateSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError PsElabModuleResult :=
  match psCompilerParseSource sourceKind source with
  | Except.error error =>
      Except.error error
  | Except.ok sourceModule =>
      psCompilerElaborateModule sourceModule

def psCompilerPrepareElaboratedWithOutput
    (elaborated : PsElabModuleResult) :
    Except PsCompilerError PsCompilerPreparationOutput := do
  let lifted ← (psRecursorLiftDeclarationsWithOrigins elaborated.environment
    elaborated.declarations).mapError PsCompilerError.normalization
  let elaborated := lifted.result
  match
      psEncodeCheckedAdmissionsCanonicalIn elaborated.environment
        (psCompilerLogicalCheckingView elaborated.declarations) with
  | Except.error error =>
      Except.error (PsCompilerError.admission error)
  | Except.ok canonicalAdmissions =>
      let prepared : PsCompilerAdmissionReadyModule :=
        { declarations := elaborated.declarations, recursorWorkerGroups := lifted.workerGroups
          noncomputableNames := elaborated.declarations.filterMap (fun declaration =>
            let name := psDeclarationName declaration
            if psEnvironmentIsNoncomputable elaborated.environment name then some name else none) };
      let admissions : String := String.Internal.append canonicalAdmissions "\n";
      Except.ok
        (PsCompilerPreparationOutput.mk prepared elaborated.environment admissions lifted.parents)

def psCompilerPrepareElaborated
    (elaborated : PsElabModuleResult) :
    Except PsCompilerError PsCompilerAdmissionReadyModule :=
  match psCompilerPrepareElaboratedWithOutput elaborated with
  | Except.error error => Except.error error
  | Except.ok output => Except.ok output.prepared

def psCompilerCheckElaborated
    (elaborated : PsElabModuleResult) :
    Except PsCompilerError PsCompilerAdmissionReadyModule :=
  psCompilerPrepareElaborated elaborated

def psCompilerPrepareSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError PsCompilerAdmissionReadyModule :=
  match psCompilerElaborateSource sourceKind source with
  | Except.error error =>
      Except.error error
  | Except.ok elaborated =>
      psCompilerPrepareElaborated elaborated

-- Preparation remains pure. Hosts may retain a successful ordered prefix and
-- resume it only when its exact compiler, source kind and source prefix agree.
def psCompilerPreparationStart
    (sourceKind : PsCompilerSourceKind) : PsCompilerPreparationState :=
  PsCompilerPreparationState.mk
    sourceKind psSelfHostProdPreludeEnvironment List.nil

-- One actual elaboration supplies both the next state and source-local origins.
-- The surrounding source-owned caller attaches module identity to these records.
def psCompilerPreparationStepParsedWithOrigins
    (state : PsCompilerPreparationState)
    (sourceModule : PsSyntaxModule) :
    Except PsElabOriginError PsCompilerPreparationStepWithOriginsResult :=
  match psElabModuleWithOrigins state.environment sourceModule with
  | Except.error error => Except.error error
  | Except.ok elaborated =>
      let nextState : PsCompilerPreparationState :=
        PsCompilerPreparationState.mk
          state.sourceKind elaborated.result.environment
          (psListAppend
            (psListReverse elaborated.result.declarations) state.declarationsRev);
      Except.ok
        (PsCompilerPreparationStepWithOriginsResult.mk nextState elaborated.origins)

def psCompilerPreparationStepParsed
    (state : PsCompilerPreparationState)
    (sourceModule : PsSyntaxModule) :
    Except PsCompilerError PsCompilerPreparationState :=
  match psCompilerPreparationStepParsedWithOrigins state sourceModule with
  | Except.error error => Except.error (PsCompilerError.elaboration error.error)
  | Except.ok result => Except.ok result.state

def psCompilerPreparationStep
    (state : PsCompilerPreparationState)
    (source : String) :
    Except PsCompilerError PsCompilerPreparationState :=
  match psCompilerParseSource state.sourceKind source with
  | Except.error error => Except.error error
  | Except.ok sourceModule =>
      psCompilerPreparationStepParsed state sourceModule

def psCompilerPreparationElaborated
    (state : PsCompilerPreparationState) : PsElabModuleResult :=
  PsElabModuleResult.mk state.environment (psListReverse state.declarationsRev)

def psCompilerPreparationFinishWithOutput
    (state : PsCompilerPreparationState) :
    Except PsCompilerError PsCompilerPreparationOutput :=
  psCompilerPrepareElaboratedWithOutput (psCompilerPreparationElaborated state)

def psCompilerPreparationFinish
    (state : PsCompilerPreparationState) :
    Except PsCompilerError PsCompilerAdmissionReadyModule :=
  match psCompilerPreparationFinishWithOutput state with
  | Except.error error => Except.error error
  | Except.ok output => Except.ok output.prepared

def psCompilerPreparationSourcesWorker
    (sources : List String)
    (state : PsCompilerPreparationState) :
    Except PsCompilerError PsCompilerPreparationState :=
  match sources with
  | List.nil =>
      Except.ok state
  | List.cons source rest =>
      match psCompilerPreparationStep state source with
      | Except.error error => Except.error error
      | Except.ok next => psCompilerPreparationSourcesWorker rest next

def psCompilerElaborateSourcesWorker
    (sourceKind : PsCompilerSourceKind) (sources : List String) :
    PsEnvironment -> List PsDeclaration -> Except PsCompilerError PsElabModuleResult :=
  fun (environment : PsEnvironment) (declarationsRev : List PsDeclaration) =>
    match
        psCompilerPreparationSourcesWorker sources
          (PsCompilerPreparationState.mk sourceKind environment declarationsRev) with
    | Except.error error => Except.error error
    | Except.ok state => Except.ok (psCompilerPreparationElaborated state)

def psCompilerPrepareSources
    (sourceKind : PsCompilerSourceKind) (sources : List String) :
    Except PsCompilerError PsCompilerAdmissionReadyModule :=
  match
      psCompilerPreparationSourcesWorker sources
        (psCompilerPreparationStart sourceKind) with
  | Except.error error => Except.error error
  | Except.ok state => psCompilerPreparationFinish state

def psCompilerCheckSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError PsCompilerAdmissionReadyModule :=
  psCompilerPrepareSource sourceKind source

def psCompilerValidatePrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerError Unit :=
  match
      psEncodeCheckedAdmissionsCanonicalIn psSelfHostProdPreludeEnvironment
        (psCompilerLogicalCheckingView prepared.declarations) with
  | Except.error error =>
      Except.error (PsCompilerError.admission error)
  | Except.ok _ =>
      Except.ok Unit.unit

def psCompilerAdmissionsFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerError String :=
  match psEncodeCheckedAdmissionsCanonicalIn psSelfHostProdPreludeEnvironment
      (psCompilerLogicalCheckingView prepared.declarations) with
  | Except.error error =>
      Except.error (PsCompilerError.admission error)
  | Except.ok canonicalAdmissions =>
      Except.ok (String.Internal.append canonicalAdmissions "\n")

def psCompilerAdmissionsFromElaborated
    (elaborated : PsElabModuleResult) :
    Except PsCompilerError String :=
  match psCompilerPrepareElaborated elaborated with
  | Except.error error =>
      Except.error error
  | Except.ok prepared =>
      psCompilerAdmissionsFromPrepared prepared

def psCompilerAdmissionsSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError String :=
  match psCompilerPrepareSource sourceKind source with
  | Except.error error =>
      Except.error error
  | Except.ok prepared =>
      psCompilerAdmissionsFromPrepared prepared

def psCompilerEnvironmentFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerError PsEnvironment :=
  match psCompilerValidatePrepared prepared with
  | Except.error error =>
      Except.error error
  | Except.ok _ =>
      match
          psAddDeclarationList
            psSelfHostProdPreludeEnvironment
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

private def psCompilerFixedpointLevelsEq (left right : List PsName) : Bool :=
  left.length == right.length &&
    (left.zip right).all (fun pair => psNameEq pair.fst pair.snd)

private def psCompilerFixedpointClosed (expression : PsExpr) : Bool :=
  !psExprHasUnresolvedMeta expression && psExprFVarsInContext psLocalEmpty expression

private def psCompilerFixedpointUnique (declarations : List PsDeclaration)
    (name : PsName) : Option PsDeclaration :=
  match declarations.filter (fun declaration => psNameEq (psDeclarationName declaration) name) with
  | [declaration] => some declaration
  | _ => none

private def psCompilerFixedpointHelperOwned (auxiliary name : PsName) : Bool :=
  match name with
  | .num (.str owner "_rec") _ => psNameEq owner auxiliary
  | _ => false

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

-- Recursor preparation closes helpers and independently checks exact beta
-- restoration. Undo only those auxiliary-owned helper definitions, plus
-- beta/zeta; never unfold a public definition or Order.fix during this check.
private def psCompilerFixedpointRestore (fuel : Nat)
    (declarations : List PsDeclaration) (auxiliary : PsName) (expression : PsExpr) :
    Except String PsExpr := do
  match fuel with
  | 0 => throw "restoration budget exhausted"
  | fuel + 1 =>
    match expression with
    | .constE name arguments =>
      if !psCompilerFixedpointHelperOwned auxiliary name then return expression
      let some (.definitionDecl _ parameters type value) :=
          psCompilerFixedpointUnique declarations name
        | throw "missing unique auxiliary recursor helper"
      if parameters.length != arguments.length ||
          !psCompilerFixedpointClosed type || !psCompilerFixedpointClosed value then
        throw "auxiliary recursor helper is not closed at its declared universes"
      psCompilerFixedpointRestore fuel declarations auxiliary
        (psExprInstantiateLevelParams parameters arguments value)
    | .app fn argument =>
      let fn ← psCompilerFixedpointRestore fuel declarations auxiliary fn
      let argument ← psCompilerFixedpointRestore fuel declarations auxiliary argument
      match fn with
      | .lam _ _ body _ =>
        psCompilerFixedpointRestore fuel declarations auxiliary (psExprInstantiate1 body argument)
      | _ => return .app fn argument
    | .letE _ _ value body =>
      let value ← psCompilerFixedpointRestore fuel declarations auxiliary value
      psCompilerFixedpointRestore fuel declarations auxiliary (psExprInstantiate1 body value)
    | .lam name type body binder =>
      return .lam name
        (← psCompilerFixedpointRestore fuel declarations auxiliary type)
        (← psCompilerFixedpointRestore fuel declarations auxiliary body) binder
    | .forallE name type body binder =>
      return .forallE name
        (← psCompilerFixedpointRestore fuel declarations auxiliary type)
        (← psCompilerFixedpointRestore fuel declarations auxiliary body) binder
    | .proj typeName index value =>
      return .proj typeName index
        (← psCompilerFixedpointRestore fuel declarations auxiliary value)
    | _ => return expression

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
      psCompilerFixedpointUnique declarations auxiliary
    | throw "missing unique checked fixedpoint auxiliary"
  if !psCompilerFixedpointClosed packedType || !psCompilerFixedpointClosed fixedValue ||
      !(ordered.all (fun member => psCompilerFixedpointLevelsEq levels member.levels)) then
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
        psCompilerFixedpointUnique declarations (PsName.num member.name 2)
      | throw "missing unique checked whole-function equation"
    if !psCompilerFixedpointLevelsEq levels equationLevels ||
        !psCompilerFixedpointClosed equationType || !psCompilerFixedpointClosed equationProof then
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
    let restored ← psCompilerFixedpointRestore 4096 declarations auxiliary member.body
    return (member, psCompilerFixedpointReplacePeers ordered restored)
  let body ← psCompilerFixedpointPack entries packedType
  let reconstructed := PsExpr.lam (psRootName "$psc0Fix") packedType
    (psExprAbstractFVar 0 body) .explicit
  let restored ← psCompilerFixedpointRestore 4096 declarations auxiliary functional
  let reconstructed ← psCompilerFixedpointRestore 4096 declarations auxiliary reconstructed
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
      if !psCompilerFixedpointLevelsEq levels publicLevels ||
          !psExprAlphaEq type publicType then
        throw (.normalization "PSCV0-PARTIAL: private implementation/type mismatch")
      if (declarations.filter (fun declaration =>
          psNameEq (psDeclarationName declaration) name)).length != 1 then
        throw (.normalization "PSCV0-PARTIAL: missing unique opaque logical owner")
      if fixedpoint then
        if !psCompilerFixedpointClosed type || !psCompilerFixedpointClosed body then
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
        psNameEq name auxiliary || psCompilerFixedpointHelperOwned auxiliary name)
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
private def psCompilerErasePreparedRuntimeViewWithGroups
    (prepared : PsCompilerAdmissionReadyModule)
    (runtimeDeclarations : List PsDeclaration)
    (workerGroups : List PsRecursorWorkerGroup)
    (targetWordSize : Option PsVerifiedIrWordSize := none) :
    Except PsCompilerError PsVerifiedIrModule := do
  let environment ← psCompilerEnvironmentFromPrepared prepared
  let runtimePrelude := psSelfHostRuntimePreludeDeclarationsWithProd ++
    (if targetWordSize.isSome then psStandardPlatformRuntimeDeclarations ++
      psStandardOperatorProtocolRuntimeDeclarations environment true else [])
  (psEraseCoreModuleWithRuntimePrelude
    environment
    runtimePrelude
    runtimeDeclarations
    (runtimePrelude.map psDeclarationName ++ workerGroups.flatMap
      (fun group => group.workers.map (·.name))) targetWordSize
    workerGroups).mapError
      PsCompilerError.erasure

def psCompilerErasePreparedRuntimeView
    (prepared : PsCompilerAdmissionReadyModule)
    (runtimeDeclarations : List PsDeclaration)
    (targetWordSize : Option PsVerifiedIrWordSize := none) :
    Except PsCompilerError PsVerifiedIrModule :=
  psCompilerErasePreparedRuntimeViewWithGroups prepared runtimeDeclarations
    prepared.recursorWorkerGroups targetWordSize

-- Ordinary partial execution only. The native host must have already
-- independently kernel-accepted psCompilerLogicalCheckingView on the exact
-- original prepared graph. A caller cannot mint proof authority via this API.
def psCompilerOrdinaryPartialIrFromCheckedPrepared
    (prepared : PsCompilerAdmissionReadyModule)
    (targetWordSize : Option PsVerifiedIrWordSize := none) :
    Except PsCompilerError PsVerifiedIrModule := do
  let (runtime, auxiliaries) ← psCompilerOrdinaryPartialRuntimeView prepared.declarations
  let mut workerGroups : List PsRecursorWorkerGroup := []
  for group in prepared.recursorWorkerGroups do
    let allOwned := !group.workers.isEmpty && auxiliaries.any (fun auxiliary =>
      group.workers.all (fun worker => psCompilerFixedpointHelperOwned auxiliary worker.name))
    let anyOwned := group.workers.any (fun worker => auxiliaries.any (fun auxiliary =>
      psCompilerFixedpointHelperOwned auxiliary worker.name))
    if allOwned then pure ()
    else if anyOwned then
      throw (.normalization "PSCV0-FIXPOINT-RUNTIME: logical auxiliary owns only part of a worker group")
    else
      workerGroups := workerGroups ++ [group]
  psCompilerErasePreparedRuntimeViewWithGroups prepared runtime workerGroups targetWordSize

def psCompilerVerifiedIrFromPrepared
    (prepared : PsCompilerAdmissionReadyModule)
    (targetWordSize : Option PsVerifiedIrWordSize := none) :
    Except PsCompilerError PsVerifiedIrModule := do
  -- The general source/library API must remain fail-closed for partial
  -- implementations. Only the native host's explicitly ordinary runtime
  -- path may lower the paired body, after real official kernel admission.
  if prepared.declarations.any (fun declaration =>
      match declaration with | .partialDecl .. => true | _ => false) then
    throw (.normalization "PSCV0-PARTIAL-RUNTIME-PENDING: partial logical checking does not admit executable output")
  psCompilerErasePreparedRuntimeView prepared prepared.declarations targetWordSize

def psCompilerVerifiedIrFromElaborated
    (elaborated : PsElabModuleResult)
    (targetWordSize : Option PsVerifiedIrWordSize := none) :
    Except PsCompilerError PsVerifiedIrModule :=
  match psCompilerPrepareElaborated elaborated with
  | Except.error error =>
      Except.error error
  | Except.ok prepared =>
      psCompilerVerifiedIrFromPrepared prepared targetWordSize

def psCompilerVerifiedIrSource
    (sourceKind : PsCompilerSourceKind)
    (source : String)
    (targetWordSize : Option PsVerifiedIrWordSize := none) :
    Except PsCompilerError PsVerifiedIrModule :=
  match psCompilerPrepareSource sourceKind source with
  | Except.error error =>
      Except.error error
  | Except.ok prepared =>
      psCompilerVerifiedIrFromPrepared prepared targetWordSize
