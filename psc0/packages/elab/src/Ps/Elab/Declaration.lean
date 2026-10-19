import Ps.Core.Declaration
import Ps.Core.Equality
import Ps.Elab.Recursion
import Ps.Elab.Data
import Ps.Elab.SourceNames

structure PsElabDeclarationResult where
  declaration : PsDeclaration
  metaContext : PsMetaContext
  sourceInfo : PsElabSourceInfo

structure PsElabModuleResult where
  environment : PsEnvironment
  declarations : List PsDeclaration
  commandDiagnostics : List PsDiagnostic := []

-- Origins attach to the actual output batch of one source declaration.
-- Source and member indices are local; module identity is attached by the caller.
inductive PsElabOriginRole where
  | sourceDeclaration
  | inductiveType
  | structureType
  | constructor
  | recursor
  | derivedInstance
  | normalizedWorker
  | publicWrapper

inductive PsElabOriginPhase where
  | stableDeclaration
  | normalizationPlanning
  | normalizedWorker
  | publicWrapper
  | declarationInsertion

structure PsElabMemberOrigin where
  index : Nat
  name : PsName
  role : PsElabOriginRole

-- A mutual source command owns one complete ordered group while each source
-- member keeps its own declaration span and source index. These coordinates
-- are provenance only; they never participate in checked Core identity.
structure PsElabMutualGroupOrigin where
  firstSourceIndex : Nat
  memberIndex : Nat
  memberCount : Nat
  span : PsSourceSpan

structure PsElabLocalDefinitionOrigin where
  name : PsName
  span : PsSourceSpan
  declarations : List PsName

structure PsElabBatchOrigin where
  sourceIndex : Nat
  sourceName : PsSyntaxName
  span : PsSourceSpan
  members : List PsElabMemberOrigin
  normalization : Option PsElabNormalizationOrigin
  sourceInfo : List PsElabSourceInfo := []
  mutualGroup : Option PsElabMutualGroupOrigin := none
  localDefinitions : List PsElabLocalDefinitionOrigin := []
  diagnostics : List PsDiagnostic := []

structure PsElabOriginError where
  error : PsElabError
  sourceIndex : Nat
  sourceName : PsSyntaxName
  span : PsSourceSpan
  phase : PsElabOriginPhase

structure PsElabDeclarationBatchWithOriginsResult where
  result : PsElabDeclarationBatchResult
  origin : PsElabBatchOrigin

structure PsElabModuleWithOriginsResult where
  result : PsElabModuleResult
  origins : List PsElabBatchOrigin
  -- Includes all compiler-generated members owned by a private source command.
  privateNames : List PsName := []
  -- RC4 public 'abbrev' bodies are exposed, unlike ordinary public 'def' bodies.
  exposedNames : List PsName := []

-- These two internal results attribute only phases known at the call boundary.
structure PsElabOriginPhaseError where
  error : PsElabError
  phase : PsElabOriginPhase

structure PsElabNormalizedDefinitionResult where
  worker : PsDeclaration
  publicDeclaration : PsDeclaration
  sourceInfo : List PsElabSourceInfo

def psElabOriginSource
    (source : PsSyntaxDeclaration) : Prod PsSyntaxName PsSourceSpan :=
  match source with
  | .whereDeclaration declaration _ span =>
      let parent := psElabOriginSource declaration
      (parent.fst, PsSourceSpan.mk parent.snd.start span.stop)
  | PsSyntaxDeclaration.definition name _ _ _ span => Prod.mk name span
  | PsSyntaxDeclaration.partialDefinition name _ _ _ span => Prod.mk name span
  | PsSyntaxDeclaration.noncomputableDefinition name _ _ _ span => Prod.mk name span
  | PsSyntaxDeclaration.fixedpointDefinition name _ _ _ span => Prod.mk name span
  | PsSyntaxDeclaration.wellFoundedDefinition name _ _ _ _ span => Prod.mk name span
  | PsSyntaxDeclaration.theoremDecl name _ _ _ span => Prod.mk name span
  | PsSyntaxDeclaration.inductiveDecl name _ _ _ span => Prod.mk name span
  | PsSyntaxDeclaration.structureDecl name _ _ _ span => Prod.mk name span

def psElabOriginErrorAt
    (sourceIndex : Nat) (source : PsSyntaxDeclaration)
    (phase : PsElabOriginPhase) (error : PsElabError) : PsElabOriginError :=
  let sourceOrigin : Prod PsSyntaxName PsSourceSpan := psElabOriginSource source;
  PsElabOriginError.mk error sourceIndex
    (Prod.fst sourceOrigin) (Prod.snd sourceOrigin) phase

def psElabBatchOriginAt
    (sourceIndex : Nat) (source : PsSyntaxDeclaration)
    (members : List PsElabMemberOrigin)
    (normalization : Option PsElabNormalizationOrigin) : PsElabBatchOrigin :=
  let sourceOrigin : Prod PsSyntaxName PsSourceSpan := psElabOriginSource source;
  { sourceIndex, sourceName := sourceOrigin.fst, span := sourceOrigin.snd,
    members, normalization }

def psElabStableMemberRole (declaration : PsDeclaration) : PsElabOriginRole :=
  match declaration with
  | PsDeclaration.inductiveDecl info =>
      if info.isStructure then PsElabOriginRole.structureType
      else PsElabOriginRole.inductiveType
  | PsDeclaration.constructorDecl _ => PsElabOriginRole.constructor
  | PsDeclaration.recursorDecl _ => PsElabOriginRole.recursor
  | _ => PsElabOriginRole.sourceDeclaration

def psElabStableMemberOrigins
    (declarations : List PsDeclaration) (index : Nat) : List PsElabMemberOrigin :=
  match declarations with
  | List.nil => List.nil
  | List.cons declaration rest =>
      List.cons
        (PsElabMemberOrigin.mk index (psDeclarationName declaration)
          (psElabStableMemberRole declaration))
        (psElabStableMemberOrigins rest (Nat.succ index))

def psElabExplicitParameterIds
    (binders : List PsElabTypedBinder) : List Nat :=
  match binders with
  | List.nil =>
      List.nil
  | List.cons binder rest =>
      let smaller : List Nat :=
        psElabExplicitParameterIds rest;
      match binder.binder with
      | PsBinderInfo.explicit =>
          List.cons binder.id smaller
      | _ =>
          smaller

def psElabFindNatIndexWorker
    (target : Nat)
    (values : List Nat) :
    Nat -> Option Nat :=
  match values with
  | List.nil =>
      fun (_index : Nat) => Option.none
  | List.cons value rest =>
      let smaller : Nat -> Option Nat :=
        psElabFindNatIndexWorker target rest;
      fun (index : Nat) =>
        if Nat.beq value target then
          Option.some index
        else
          smaller (Nat.succ index)

def psElabFindNatIndex
    (target : Nat)
    (values : List Nat)
    (index : Nat) : Option Nat :=
  psElabFindNatIndexWorker target values index

def psElabStructuralRecursionFromSource
    (functionName : PsName)
    (bindersRev : List PsElabTypedBinder)
    (body : PsSyntaxTerm)
    (context : PsElabContext)
    (resultType : PsExpr) :
    Option PsElabStructuralRecursion :=
  match body with
  | .matchMany [scrutinee] _ _ _ =>
      match scrutinee.term with
      | .reference scrutineeName =>
          match psSyntaxNameToName scrutineeName with
          | none =>
              Option.none
          | some sourceName =>
              match
                  psResolveName
                    context.localContext
                    context.environment
                    sourceName with
              | some resolution =>
                  match resolution with
                  | .local scrutineeId =>
                      let explicitParameterIds :=
                        psElabExplicitParameterIds
                          (psElabTypedBinderListReverse bindersRev);
                      match
                          psElabFindNatIndex
                            scrutineeId
                            explicitParameterIds
                            0 with
                      | none =>
                          Option.none
                      | some recursiveParameterIndex =>
                          Option.some
                            (PsElabStructuralRecursion.mk
                              functionName
                              (psElabRecursionParameterIds
                                (psElabTypedBinderListReverse bindersRev))
                              explicitParameterIds
                              recursiveParameterIndex
                              List.nil
                              resultType
                              true [] false)
                  | _ =>
                      Option.none
              | none =>
                  Option.none
      | _ =>
          Option.none
  | _ =>
      Option.none

def psElabDeclarationTermCallback
    (context : PsElabContext)
    (term : PsSyntaxTerm)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  psElabTerm context term expected

def psElabDeclarationParts
    (environment : PsEnvironment) (nameSyntax : PsSyntaxName)
    (binders : List (PsSyntaxBinderHead × PsSyntaxTerm))
    (typeSyntax valueSyntax : PsSyntaxTerm) (isTheorem : Bool)
    (levelNames : List PsName := []) :
    Except PsElabError PsElabDeclarationResult := do
  let some name := psSyntaxNameToName nameSyntax | throw .emptyName
  let binderResult ← psElabTypedBinders psElabDeclarationTermCallback
    (psElabContextEmpty environment levelNames) binders
  let annotation ← psElabType psElabDeclarationTermCallback binderResult.context typeSyntax
  -- Pinned MutualDef.elabHeaders resolves an explicitly supplied header
  -- before any body. Local let-rec inference has its separate source owner.
  let header := psCloseElabForallBinders annotation.context.metaContext
    binderResult.bindersRev annotation.type
  if psExprHasTermMeta (psMetaInstantiate annotation.context.metaContext header) then
    throw (.data "PSCV0-DECLARATION-HEADER: an explicit header must resolve parameter and result types before the body")
  let valueContext := if isTheorem then annotation.context else
    psElabContextWithStructuralRecursion annotation.context
      (psElabStructuralRecursionFromSource name binderResult.bindersRev
        valueSyntax annotation.context annotation.type)
  let value ← psElabTerm valueContext valueSyntax (some annotation.type)
  let constraints := value.context.metaContext
  let closed := psCloseElabTypedBinders constraints binderResult.bindersRev
    (psMetaInstantiate constraints value.term) (psMetaInstantiate constraints annotation.type)
  let closed := (psElabGeneralizeExpr closed.fst, psElabGeneralizeExpr closed.snd)
  let levels := psElabDeclarationLevels levelNames [closed.snd, closed.fst]
  if psExprHasUnresolvedMeta closed.fst || psExprHasUnresolvedMeta closed.snd then
    throw .unresolvedMetavariable
  let declaration := if isTheorem then
    PsDeclaration.theoremDecl name levels closed.snd closed.fst
    else PsDeclaration.definitionDecl name levels closed.snd closed.fst
  return {
    declaration, metaContext := constraints
    sourceInfo := psElabFinishSourceInfo value.context name }

def psElabPartialDeclaration (environment : PsEnvironment)
    (nameSyntax : PsSyntaxName)
    (binders : List (PsSyntaxBinderHead × PsSyntaxTerm))
    (typeSyntax valueSyntax : PsSyntaxTerm) :
    Except PsElabError PsElabDeclarationResult := do
  let some name := psSyntaxNameToName nameSyntax | throw .emptyName
  let binderResult ← psElabTypedBinders psElabDeclarationTermCallback
    (psElabContextEmpty environment) binders
  let annotation ← psElabType psElabDeclarationTermCallback binderResult.context typeSyntax
  let openType := psMetaInstantiate annotation.context.metaContext annotation.type
  let closedType := psCloseElabForallBinders annotation.context.metaContext
    binderResult.bindersRev openType
  if psExprHasUnresolvedMeta closedType then throw .unresolvedMetavariable
  let header := PsDeclaration.axiomDecl name [] closedType
  let some withSelf := psEnvironmentAdd environment header
    | throw (.duplicateDeclaration name)
  let value ← psElabTerm (psElabContextWithEnvironment annotation.context withSelf)
    valueSyntax (some openType)
  let metaContext := value.context.metaContext
  let closed := psCloseElabTypedBinders metaContext binderResult.bindersRev
    (psMetaInstantiate metaContext value.term) (psMetaInstantiate metaContext openType)
  if psExprHasUnresolvedMeta closed.fst || psExprHasUnresolvedMeta closed.snd then
    throw .unresolvedMetavariable
  return {
    declaration := .partialDecl name [] closed.snd closed.fst
    metaContext
    sourceInfo := psElabFinishSourceInfo value.context name }

def psElabDeclaration
    (environment : PsEnvironment)
    (source : PsSyntaxDeclaration) (levelNames : List PsName := []) :
    Except PsElabError PsElabDeclarationResult :=
  match source with
  | .definition name binders type value _ =>
      psElabDeclarationParts
        environment
        name
        binders
        type
        value
        false levelNames
  | .partialDefinition name binders type value _ =>
      psElabPartialDeclaration
        environment
        name
        binders
        type
        value
  | .noncomputableDefinition .. =>
      Except.error (.data "PSCV0-NONCOMPUTABLE-BATCH: noncomputable policy requires typed command-batch elaboration")
  | .fixedpointDefinition _ _ _ _ _ =>
      Except.error (.data "PSCV0-FIXPOINT-BATCH: fixedpoint declarations require typed command-batch elaboration")
  | .wellFoundedDefinition _ _ _ _ _ _ =>
      -- The definition and its checked equation are one source-owned batch.
      -- A single-declaration caller must not silently discard the equation.
      Except.error (.data "PSCV0-WF-BATCH: well-founded declarations require declaration-batch elaboration")
  | .whereDeclaration _ _ _ =>
      Except.error (.data "PSCV0-WHERE-BATCH: local definitions require typed command-batch elaboration")
  | .theoremDecl name binders type value _ =>
      psElabDeclarationParts
        environment
        name
        binders
        type
        value
        true levelNames
  | .inductiveDecl _ _ _ _ _ =>
      Except.error PsElabError.unsupportedTerm
  | .structureDecl _ _ _ _ _ =>
      Except.error PsElabError.unsupportedTerm

-- Elaborate the canonical worker with the original source self name, then give
-- its closed core declaration an internal numeric name. Recursive core terms are
-- recursors, so this rename cannot leave an unresolved self constant behind.
-- The richer result keeps the two actual declarations and the known error phase.
def psElabNormalizedDefinitionWithPhase
    (environment : PsEnvironment) (sourceName : PsSyntaxName)
    (normalized : PsElabStructuralNormalization) (levelNames : List PsName := []) :
    Except PsElabOriginPhaseError PsElabNormalizedDefinitionResult :=
  match psElabDeclarationParts environment sourceName
      normalized.workerBinders normalized.workerType normalized.workerValue false levelNames with
  | Except.error error =>
      Except.error
        (PsElabOriginPhaseError.mk error PsElabOriginPhase.normalizedWorker)
  | Except.ok workerResult =>
      match workerResult.declaration with
      | PsDeclaration.definitionDecl _ levels workerType workerValue =>
          let worker : PsDeclaration := PsDeclaration.definitionDecl
            normalized.workerName levels workerType workerValue;
          match psEnvironmentAdd environment worker with
          | Option.none =>
              Except.error
                (PsElabOriginPhaseError.mk
                  (PsElabError.duplicateDeclaration normalized.workerName)
                  PsElabOriginPhase.normalizedWorker)
          | Option.some workerEnvironment =>
              let context : PsElabContext := psElabContextWithEnvironment
                normalized.publicContext workerEnvironment;
              let fresh := (psDeclarationLevelParams worker).foldl
                (fun (state : PsMetaContext × List PsLevel) name =>
                  if levelNames.any (psNameEq name) then
                    (state.fst, PsLevel.param name :: state.snd)
                  else
                    let next := psMetaFreshLevel state.fst
                    (next.context, next.level :: state.snd)) (context.metaContext, []);
              let context := psElabContextWithMeta context fresh.fst;
              let application : PsExpr := psExprApplyMany
                (PsExpr.constE normalized.workerName fresh.snd.reverse)
                normalized.workerArguments;
              match psElabResolvedTerm context application
                  (Option.some normalized.publicType) with
              | Except.error error =>
                  Except.error
                    (PsElabOriginPhaseError.mk error PsElabOriginPhase.publicWrapper)
              | Except.ok checked =>
                  let metaContext : PsMetaContext := checked.context.metaContext;
                  let closed : Prod PsExpr PsExpr := psCloseElabTypedBinders metaContext
                    normalized.publicBindersRev
                    (psMetaInstantiate metaContext checked.term)
                    (psMetaInstantiate metaContext normalized.publicType);
                  let closed := (psElabGeneralizeExpr closed.fst, psElabGeneralizeExpr closed.snd);
                  let levelParams := psElabDeclarationLevels levelNames [closed.snd, closed.fst];
                  if psExprHasUnresolvedMeta (Prod.fst closed) then
                    Except.error
                      (PsElabOriginPhaseError.mk PsElabError.unresolvedMetavariable
                        PsElabOriginPhase.publicWrapper)
                  else if psExprHasUnresolvedMeta (Prod.snd closed) then
                    Except.error
                      (PsElabOriginPhaseError.mk PsElabError.unresolvedMetavariable
                        PsElabOriginPhase.publicWrapper)
                  else
                    let publicDeclaration : PsDeclaration := PsDeclaration.definitionDecl
                      normalized.publicName levelParams (Prod.snd closed) (Prod.fst closed);
                    Except.ok
                      {
                        worker, publicDeclaration
                        sourceInfo := [
                          { workerResult.sourceInfo with owner := normalized.workerName },
                          psElabFinishSourceInfo checked.context normalized.publicName] }
      | _ =>
          Except.error
            (PsElabOriginPhaseError.mk PsElabError.structuralRecursionInternal
              PsElabOriginPhase.normalizedWorker)

def psElabNormalizedDefinitionBatch
    (result : PsElabNormalizedDefinitionResult) : PsElabDeclarationBatchResult :=
  { declarations := [result.worker, result.publicDeclaration], sourceInfo := result.sourceInfo }

def psElabNormalizedDefinition
    (environment : PsEnvironment) (sourceName : PsSyntaxName)
    (normalized : PsElabStructuralNormalization) :
    Except PsElabError PsElabDeclarationBatchResult :=
  match psElabNormalizedDefinitionWithPhase environment sourceName normalized with
  | Except.error failure => Except.error failure.error
  | Except.ok result => Except.ok (psElabNormalizedDefinitionBatch result)

def psElabDeclarationBatchStable
    (environment : PsEnvironment)
    (source : PsSyntaxDeclaration) (levelNames : List PsName := []) :
    Except PsElabError PsElabDeclarationBatchResult :=
  match source with
  | .wellFoundedDefinition name binders type value termination _ =>
      match psElabWellFoundedParts psElabDeclarationTermCallback
          environment name binders type value termination levelNames with
      | .error error => .error error
      | .ok result =>
          .ok {
            declarations := [result.declaration, result.equation]
            sourceInfo := [result.sourceInfo]
          }
  | .inductiveDecl name params resultType constructors _ =>
      psElabInductiveDeclaration
        environment
        name
        params
        resultType
        constructors
        false levelNames
  | .structureDecl name params resultType fields span =>
      psElabStructureDeclaration
        environment
        name
        params
        resultType
        fields
        span levelNames
  | _ =>
      match psElabDeclaration environment source levelNames with
      | Except.error error => Except.error error
      | Except.ok result =>
          Except.ok
            { declarations := [result.declaration], sourceInfo := [result.sourceInfo] }

-- Historical callers can request the unchanged stable elaborator explicitly.
-- The ordinary path keeps its one typed normalization attempt for the same
-- capability refusal. Origins are recorded from that execution, not a replay.
def psElabDeclarationBatchWithOrigins
    (environment : PsEnvironment) (sourceIndex : Nat)
    (source : PsSyntaxDeclaration) (levelNames : List PsName := []) :
    Except PsElabOriginError PsElabDeclarationBatchWithOriginsResult :=
  match psElabDeclarationBatchStable environment source levelNames with
  | Except.ok result =>
      let members : List PsElabMemberOrigin :=
        psElabStableMemberOrigins result.declarations 0;
      Except.ok
        (PsElabDeclarationBatchWithOriginsResult.mk result
          { (psElabBatchOriginAt sourceIndex source members Option.none) with
            sourceInfo := result.sourceInfo })
  | Except.error error =>
      match error with
      | PsElabError.structuralRecursionInvariantArgument
      | PsElabError.structuralRecursionDependentParameter =>
          match source with
          | PsSyntaxDeclaration.definition name binders type value span =>
              match psElabPlanStructuralNormalizationWithOrigin
                  environment name binders type value span levelNames with
              | Except.error failure =>
                  Except.error
                    (psElabOriginErrorAt sourceIndex source
                      PsElabOriginPhase.normalizationPlanning failure)
              | Except.ok plan =>
                  match plan with
                  | Option.none =>
                      Except.error
                        (psElabOriginErrorAt sourceIndex source
                          PsElabOriginPhase.stableDeclaration error)
                  | Option.some normalized =>
                      match psElabNormalizedDefinitionWithPhase
                          environment name normalized.normalization levelNames with
                      | Except.error failure =>
                          Except.error
                            (psElabOriginErrorAt sourceIndex source
                              failure.phase failure.error)
                      | Except.ok result =>
                          let members : List PsElabMemberOrigin :=
                            List.cons
                              (PsElabMemberOrigin.mk 0 (psDeclarationName result.worker)
                                PsElabOriginRole.normalizedWorker)
                              (List.cons
                                (PsElabMemberOrigin.mk 1
                                  (psDeclarationName result.publicDeclaration)
                                  PsElabOriginRole.publicWrapper)
                                List.nil);
                          Except.ok
                            (PsElabDeclarationBatchWithOriginsResult.mk
                              (psElabNormalizedDefinitionBatch result)
                              { (psElabBatchOriginAt sourceIndex source members
                                (Option.some normalized.origin)) with sourceInfo := result.sourceInfo })
          | _ =>
              Except.error
                (psElabOriginErrorAt sourceIndex source
                  PsElabOriginPhase.stableDeclaration error)
      | _ =>
          Except.error
            (psElabOriginErrorAt sourceIndex source
              PsElabOriginPhase.stableDeclaration error)

def psElabDeclarationBatch
    (environment : PsEnvironment) (source : PsSyntaxDeclaration)
    (levelNames : List PsName := []) :
    Except PsElabError PsElabDeclarationBatchResult :=
  match psElabDeclarationBatchWithOrigins environment 0 source levelNames with
  | Except.error failure => Except.error failure.error
  | Except.ok result => Except.ok result.result

def psPrependBatchReverse
    (declarations : List PsDeclaration)
    (declarationsRev : List PsDeclaration) :
    List PsDeclaration :=
  psElabAppendDeclarations
    (psElabReverseDeclarations declarations)
    declarationsRev

-- Internal scoped batches use psElabDeclarationBatchWithOrigins above.
-- The legacy public source-list/module entry points validate original syntax.
def psElabSourceDeclarationBatchWithOrigins (environment : PsEnvironment)
    (sourceIndex : Nat) (source : PsSyntaxDeclaration) :
    Except PsElabOriginError PsElabDeclarationBatchWithOriginsResult := do
  (psElabSourceDeclarationNames 4096 source).mapError
    (psElabOriginErrorAt sourceIndex source .stableDeclaration)
  psElabDeclarationBatchWithOrigins environment sourceIndex source

def psElabDeclarationsWithOriginsWorker
    (sources : List PsSyntaxDeclaration)
    (environment : PsEnvironment)
    (declarationsRev : List PsDeclaration)
    (originsRev : List PsElabBatchOrigin)
    (sourceIndex : Nat) :
    Except PsElabOriginError PsElabModuleWithOriginsResult :=
  match sources with
  | List.nil =>
      Except.ok
        (PsElabModuleWithOriginsResult.mk
          (PsElabModuleResult.mk
            environment
            (psElabReverseDeclarations declarationsRev))
          (psListReverse originsRev) [] [])
  | List.cons source rest =>
      match psElabSourceDeclarationBatchWithOrigins environment sourceIndex source with
      | Except.error error => Except.error error
      | Except.ok batch =>
          match
              psAddDeclarationList
                environment
                batch.result.declarations with
          | Except.error error =>
              Except.error
                (PsElabOriginError.mk error batch.origin.sourceIndex
                  batch.origin.sourceName batch.origin.span
                  PsElabOriginPhase.declarationInsertion)
          | Except.ok nextEnvironment =>
              psElabDeclarationsWithOriginsWorker
                rest
                nextEnvironment
                (psPrependBatchReverse
                  batch.result.declarations
                  declarationsRev)
                (List.cons batch.origin originsRev)
                (Nat.succ sourceIndex)

-- Existing raw APIs project the same actual declarations, environment and error.
-- A raw worker's incoming declaration prefix receives no invented origins.
def psElabDeclarationsWorker
    (sources : List PsSyntaxDeclaration)
    (environment : PsEnvironment)
    (declarationsRev : List PsDeclaration) :
    Except PsElabError PsElabModuleResult :=
  match psElabDeclarationsWithOriginsWorker
      sources environment declarationsRev List.nil 0 with
  | Except.error failure => Except.error failure.error
  | Except.ok result => Except.ok result.result

def psElabDeclarations
    (environment : PsEnvironment)
    (sources : List PsSyntaxDeclaration)
    (declarationsRev : List PsDeclaration) :
    Except PsElabError PsElabModuleResult :=
  psElabDeclarationsWorker
    sources
    environment
    declarationsRev

def psElabModuleWithOrigins
    (environment : PsEnvironment)
    (sourceModule : PsSyntaxModule) :
    Except PsElabOriginError PsElabModuleWithOriginsResult := do
  for entry in sourceModule.imports do
    (psElabSourceName entry.moduleName).mapError fun error =>
      PsElabOriginError.mk error 0 entry.moduleName entry.span .stableDeclaration
  psElabDeclarationsWithOriginsWorker
    sourceModule.declarations environment List.nil List.nil 0

def psElabModule
    (environment : PsEnvironment)
    (module : PsSyntaxModule) :
    Except PsElabError PsElabModuleResult :=
  match psElabModuleWithOrigins environment module with
  | Except.error failure => Except.error failure.error
  | Except.ok result => Except.ok result.result

