import Ps.Core.Declaration
import Ps.Core.Equality
import Ps.Elab.Recursion

structure PsElabDeclarationResult where
  declaration : PsDeclaration
  metaContext : PsMetaContext

structure PsElabDeclarationBatchResult where
  declarations : List PsDeclaration

structure PsElabConstructorBuildResult where
  context : PsElabContext
  bindersRev : List PsElabTypedBinder

structure PsElabModuleResult where
  environment : PsEnvironment
  declarations : List PsDeclaration

-- Origins attach to the actual output batch of one source declaration.
-- Source and member indices are local; module identity is attached by the caller.
inductive PsElabOriginRole where
  | sourceDeclaration
  | inductiveType
  | structureType
  | constructor
  | recursor
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

structure PsElabBatchOrigin where
  sourceIndex : Nat
  sourceName : PsSyntaxName
  span : PsSourceSpan
  members : List PsElabMemberOrigin
  normalization : Option PsElabNormalizationOrigin

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

-- These two internal results attribute only phases known at the call boundary.
structure PsElabOriginPhaseError where
  error : PsElabError
  phase : PsElabOriginPhase

structure PsElabNormalizedDefinitionResult where
  worker : PsDeclaration
  publicDeclaration : PsDeclaration

def psElabOriginSource
    (source : PsSyntaxDeclaration) : Prod PsSyntaxName PsSourceSpan :=
  match source with
  | PsSyntaxDeclaration.definition name _ _ _ span => Prod.mk name span
  | PsSyntaxDeclaration.partialDefinition name _ _ _ span => Prod.mk name span
  | PsSyntaxDeclaration.theoremDecl name _ _ _ span => Prod.mk name span
  | PsSyntaxDeclaration.inductiveDecl name _ _ _ span => Prod.mk name span
  | PsSyntaxDeclaration.structureDecl name _ _ span => Prod.mk name span

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
  PsElabBatchOrigin.mk sourceIndex
    (Prod.fst sourceOrigin) (Prod.snd sourceOrigin) members normalization

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
  | .matchE scrutinee _ _ =>
      match scrutinee with
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
                              true)
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
    (environment : PsEnvironment)
    (nameSyntax : PsSyntaxName)
    (binders : List (PsSyntaxBinderHead × PsSyntaxTerm))
    (typeSyntax : PsSyntaxTerm)
    (valueSyntax : PsSyntaxTerm)
    (isTheorem : Bool) :
    Except PsElabError PsElabDeclarationResult :=
  match psSyntaxNameToName nameSyntax with
  | none =>
      Except.error PsElabError.emptyName
  | some name =>
      let initial : PsElabContext :=
        psElabContextEmpty environment;
      match
          psElabTypedBinders
            psElabDeclarationTermCallback
            initial
            binders with
      | Except.error error =>
          Except.error error
      | Except.ok binderResult =>
          match
              psElabTerm
                binderResult.context
                typeSyntax
                Option.none with
          | Except.error error =>
              Except.error error
          | Except.ok typeResult =>
              match
                  psInferEnsureSort
                    typeResult.context.environment
                    typeResult.context.metaContext
                    typeResult.context.localContext
                    typeResult.type with
              | Except.error error =>
                  Except.error (PsElabError.infer error)
              | Except.ok _ =>
                  let valueContext : PsElabContext :=
                    if isTheorem then
                      typeResult.context
                    else
                      psElabContextWithStructuralRecursion
                        typeResult.context
                        (psElabStructuralRecursionFromSource
                          name
                          binderResult.bindersRev
                          valueSyntax
                          typeResult.context
                          typeResult.term);
                  match
                      psElabTerm
                        valueContext
                        valueSyntax
                        (Option.some typeResult.term) with
                  | Except.error error =>
                      Except.error error
                  | Except.ok valueResult =>
                      let metaContext : PsMetaContext :=
                        valueResult.context.metaContext;
                      let openValue : PsExpr :=
                        psMetaInstantiate
                          metaContext
                          valueResult.term;
                      let openType : PsExpr :=
                        psMetaInstantiate
                          metaContext
                          typeResult.term;
                      let closed : PsExpr × PsExpr :=
                        psCloseElabTypedBinders
                          metaContext
                          binderResult.bindersRev
                          openValue
                          openType;
                      if
                          psExprHasUnresolvedMeta
                            (Prod.fst closed) then
                        Except.error
                          PsElabError.unresolvedMetavariable
                      else if
                          psExprHasUnresolvedMeta
                            (Prod.snd closed) then
                        Except.error
                          PsElabError.unresolvedMetavariable
                      else if isTheorem then
                        Except.ok
                          (PsElabDeclarationResult.mk
                            (PsDeclaration.theoremDecl
                              name
                              List.nil
                              (Prod.snd closed)
                              (Prod.fst closed))
                            metaContext)
                      else
                        Except.ok
                          (PsElabDeclarationResult.mk
                            (PsDeclaration.definitionDecl
                              name
                              List.nil
                              (Prod.snd closed)
                              (Prod.fst closed))
                            metaContext)

def psSyntaxConstructorCoreName
    (inductiveName : PsName)
    (sourceName : PsSyntaxName) : Option PsName :=
  match sourceName.segments with
  | List.nil =>
      Option.none
  | List.cons segment rest =>
      match rest with
      | List.nil =>
          Option.some (psNameAppendStr inductiveName segment)
      | List.cons _ _ =>
          Option.none

def psElabInductiveConstructorNames
    (inductiveName : PsName)
    (sources : List PsSyntaxInductiveConstructor) : List PsName :=
  match sources with
  | List.nil => List.nil
  | List.cons source rest =>
      let currentName : PsName :=
        match
            psSyntaxConstructorCoreName
              inductiveName
              source.name with
        | Option.some constructorName => constructorName
        | Option.none => inductiveName;
      List.cons
        currentName
        (psElabInductiveConstructorNames inductiveName rest)

def psElabContextWithEnvironment
    (context : PsElabContext)
    (environment : PsEnvironment) : PsElabContext :=
  {
    environment := environment
    localContext := context.localContext
    instances := context.instances
    metaContext := context.metaContext
    structuralRecursion := context.structuralRecursion
  }

def psElabBinderArgument
    (binder : PsElabTypedBinder) : PsExpr :=
  PsExpr.fvar binder.id

def psElabBinderArgumentsInOrder
    (binders : List PsElabTypedBinder) : List PsExpr :=
  match binders with
  | List.nil => List.nil
  | List.cons binder rest =>
      List.cons
        (psElabBinderArgument binder)
        (psElabBinderArgumentsInOrder rest)

def psElabBinderArguments
    (bindersRev : List PsElabTypedBinder) : List PsExpr :=
  psElabBinderArgumentsInOrder
    (psElabTypedBinderListReverse bindersRev)

def psCloseElabImplicitBindersWorker
    (binders : List PsElabTypedBinder) :
    PsMetaContext -> PsExpr -> PsExpr :=
  match binders with
  | List.nil =>
      fun (_metaContext : PsMetaContext) =>
        fun (body : PsExpr) => body
  | List.cons binder rest =>
      let smaller :
          PsMetaContext -> PsExpr -> PsExpr :=
        psCloseElabImplicitBindersWorker rest;
      fun (metaContext : PsMetaContext) =>
        fun (body : PsExpr) =>
          let binderType :=
            psMetaInstantiate metaContext binder.type;
          let closed :=
            PsExpr.forallE
              binder.name
              binderType
              (psExprAbstractFVar binder.id body)
              PsBinderInfo.implicit;
          smaller metaContext closed

def psCloseElabImplicitBinders
    (metaContext : PsMetaContext)
    (binders : List PsElabTypedBinder)
    (body : PsExpr) : PsExpr :=
  psCloseElabImplicitBindersWorker
    binders
    metaContext
    body

def psExprListAlphaEqWorker
    (left : List PsExpr) :
    List PsExpr -> Bool :=
  match left with
  | List.nil =>
      fun (right : List PsExpr) =>
        match right with
        | List.nil => true
        | List.cons _ _ => false
  | List.cons leftExpr leftRest =>
      let smaller : List PsExpr -> Bool :=
        psExprListAlphaEqWorker leftRest;
      fun (right : List PsExpr) =>
        match right with
        | List.nil => false
        | List.cons rightExpr rightRest =>
            if psExprAlphaEq leftExpr rightExpr then
              smaller rightRest
            else
              false

def psExprListAlphaEq
    (left : List PsExpr)
    (right : List PsExpr) : Bool :=
  psExprListAlphaEqWorker left right

def psElabIsDirectRecursiveField
    (context : PsElabContext)
    (inductiveName : PsName)
    (parameterArgs : List PsExpr)
    (type : PsExpr) : Bool :=
  let reduced :=
    psWhnf
      context.environment
      context.metaContext
      context.localContext
      type;
  let view := psExprAppView reduced;
  match view.head with
  | .constE name _ =>
      if psNameEq name inductiveName then
        if Nat.beq
            (psElabListLength view.args)
            (psElabListLength parameterArgs) then
          psExprListAlphaEq view.args parameterArgs
        else
          false
      else
        false
  | _ => false

def psElabContainerRecursiveName (name : PsName) : Bool :=
  if psNameEq name psListName then
    true
  else if psNameEq name psOptionName then
    true
  else
    psNameEq name psArrayName

def psElabNestedRecursiveFieldTypeSupportedWithFuel
    (fuel : Nat) : PsName -> PsExpr -> Bool :=
  match fuel with
  | Nat.zero =>
      fun (_inductiveName : PsName) (_type : PsExpr) => false
  | Nat.succ remaining =>
      fun (inductiveName : PsName) (type : PsExpr) =>
        let smaller : PsName -> PsExpr -> Bool :=
          psElabNestedRecursiveFieldTypeSupportedWithFuel remaining;
        if psExprHasConst inductiveName type then
          let view := psExprAppView type;
          match view.head with
          | .constE name _ =>
              if psNameEq name inductiveName then
                true
              else if psElabContainerRecursiveName name then
                match view.args with
                | List.nil =>
                    false
                | List.cons argument rest =>
                    match rest with
                    | List.nil =>
                        smaller inductiveName argument
                    | List.cons _ _ =>
                        false
              else if psNameEq name psProdName then
                match view.args with
                | List.nil =>
                    false
                | List.cons left rest =>
                    match rest with
                    | List.nil =>
                        false
                    | List.cons right tail =>
                        match tail with
                        | List.nil =>
                            if smaller inductiveName left then
                              smaller inductiveName right
                            else
                              false
                        | List.cons _ _ =>
                            false
              else
                false
          | _ => false
        else
          true

def psElabNestedRecursiveFieldTypeSupported
    (inductiveName : PsName)
    (type : PsExpr) : Bool :=
  psElabNestedRecursiveFieldTypeSupportedWithFuel
    4096
    inductiveName
    type

def psElabReverseNatListAcc
    (values : List Nat) : List Nat -> List Nat :=
  match values with
  | List.nil =>
      fun (acc : List Nat) => acc
  | List.cons head tail =>
      let smaller : List Nat -> List Nat :=
        psElabReverseNatListAcc tail;
      fun (acc : List Nat) =>
        smaller (List.cons head acc)

def psElabReverseNatList (values : List Nat) : List Nat :=
  psElabReverseNatListAcc values List.nil

def psElabRecursiveFieldIndicesWorker
    (context : PsElabContext)
    (inductiveName : PsName)
    (parameterArgs : List PsExpr)
    (fields : List PsElabTypedBinder) :
    Nat ->
    List Nat ->
    Except PsElabError (List Nat) :=
  match fields with
  | List.nil =>
      fun (_index : Nat) (indicesRev : List Nat) =>
        Except.ok (psElabReverseNatList indicesRev)
  | List.cons field rest =>
      let smaller :
          Nat ->
          List Nat ->
          Except PsElabError (List Nat) :=
        psElabRecursiveFieldIndicesWorker
          context
          inductiveName
          parameterArgs
          rest;
      fun (index : Nat) (indicesRev : List Nat) =>
        let direct :=
          psElabIsDirectRecursiveField
            context
            inductiveName
            parameterArgs
            field.type;
        if direct then
          smaller
            (Nat.succ index)
            (List.cons index indicesRev)
        else if psExprHasConst inductiveName field.type then
          if psElabNestedRecursiveFieldTypeSupported
              inductiveName
              field.type then
            smaller (Nat.succ index) indicesRev
          else
            Except.error PsElabError.unsupportedTerm
        else
          smaller (Nat.succ index) indicesRev

def psElabRecursiveFieldIndices
    (context : PsElabContext)
    (inductiveName : PsName)
    (parameterArgs : List PsExpr)
    (fields : List PsElabTypedBinder)
    (index : Nat)
    (indicesRev : List Nat) :
    Except PsElabError (List Nat) :=
  psElabRecursiveFieldIndicesWorker
    context
    inductiveName
    parameterArgs
    fields
    index
    indicesRev

def psElabInductiveConstructor
    (context : PsElabContext)
    (parameterBindersRev : List PsElabTypedBinder)
    (inductiveName : PsName)
    (source : PsSyntaxInductiveConstructor) :
    Except PsElabError PsDeclaration :=
  match psSyntaxConstructorCoreName inductiveName source.name with
  | none => Except.error PsElabError.emptyName
  | some constructorName =>
      match psElabTypedBinders
          psElabDeclarationTermCallback
          context
          source.fields with
      | Except.error error => Except.error error
      | Except.ok fields =>
          let metaContext := fields.context.metaContext;
          let parameterArgs :=
            psElabBinderArguments parameterBindersRev;
          match
              psElabRecursiveFieldIndices
                fields.context
                inductiveName
                parameterArgs
                (psElabTypedBinderListReverse fields.bindersRev)
                0
                [] with
          | Except.error error => Except.error error
          | Except.ok recursiveFields =>
              let appliedInductive :=
                psExprApplyMany
                  (PsExpr.constE inductiveName [])
                  parameterArgs;
              let fieldClosed :=
                psCloseElabForallBinders
                  metaContext
                  fields.bindersRev
                  appliedInductive;
              let constructorType :=
                psCloseElabImplicitBinders
                  metaContext
                  parameterBindersRev
                  fieldClosed;
              if psExprHasUnresolvedMeta constructorType then
                Except.error PsElabError.unresolvedMetavariable
              else
                Except.ok
                  (PsDeclaration.constructorDecl
                    (PsConstructorInfo.mk
                      constructorName
                      List.nil
                      constructorType
                      inductiveName
                      0
                      (psElabListLength parameterArgs)
                      (psElabListLength source.fields)
                      recursiveFields))



def psSetConstructorIndex
    (index : Nat)
    (declaration : PsDeclaration) : PsDeclaration :=
  match declaration with
  | .constructorDecl info =>
      PsDeclaration.constructorDecl
        (PsConstructorInfo.mk
          info.name
          info.levelParams
          info.type
          info.inductiveName
          index
          info.numParams
          info.numFields
          info.recursiveFields)
  | _ => declaration

def psElabReverseDeclarationsAcc
    (declarations : List PsDeclaration) :
    List PsDeclaration -> List PsDeclaration :=
  match declarations with
  | List.nil =>
      fun (acc : List PsDeclaration) => acc
  | List.cons declaration rest =>
      let smaller : List PsDeclaration -> List PsDeclaration :=
        psElabReverseDeclarationsAcc rest;
      fun (acc : List PsDeclaration) =>
        smaller (List.cons declaration acc)

def psElabReverseDeclarations
    (declarations : List PsDeclaration) : List PsDeclaration :=
  psElabReverseDeclarationsAcc declarations List.nil

def psElabInductiveConstructorsWorker
    (context : PsElabContext)
    (parameterBindersRev : List PsElabTypedBinder)
    (inductiveName : PsName)
    (sources : List PsSyntaxInductiveConstructor) :
    Nat ->
    List PsDeclaration ->
    Except PsElabError (List PsDeclaration) :=
  match sources with
  | List.nil =>
      fun (_index : Nat) =>
        fun (declarationsRev : List PsDeclaration) =>
          Except.ok (psElabReverseDeclarations declarationsRev)
  | List.cons source rest =>
      let smaller :
          Nat -> List PsDeclaration -> Except PsElabError (List PsDeclaration) :=
        psElabInductiveConstructorsWorker
          context
          parameterBindersRev
          inductiveName
          rest;
      fun (index : Nat) =>
        fun (declarationsRev : List PsDeclaration) =>
          match psElabInductiveConstructor
              context
              parameterBindersRev
              inductiveName
              source with
          | Except.error error => Except.error error
          | Except.ok declaration =>
              smaller
                (Nat.succ index)
                (List.cons
                  (psSetConstructorIndex index declaration)
                  declarationsRev)

def psElabInductiveConstructors
    (context : PsElabContext)
    (parameterBindersRev : List PsElabTypedBinder)
    (inductiveName : PsName)
    (index : Nat)
    (sources : List PsSyntaxInductiveConstructor)
    (declarationsRev : List PsDeclaration) :
    Except PsElabError (List PsDeclaration) :=
  psElabInductiveConstructorsWorker
    context
    parameterBindersRev
    inductiveName
    sources
    index
    declarationsRev

def psEnvironmentAddOwnedBootstrapDeclaration
    (environment : PsEnvironment)
    (declaration : PsDeclaration) : Option PsEnvironment :=
  let name := psDeclarationName declaration;
  if psNameEq name psProdName then
    psEnvironmentAddReplacingAxiom environment declaration
  else if psNameEq name psListName then
    psEnvironmentAddReplacingAxiom environment declaration
  else if psNameEq name psOptionName then
    psEnvironmentAddReplacingAxiom environment declaration
  else
    psEnvironmentAdd environment declaration

def psAddDeclarationListWorker
    (declarations : List PsDeclaration)
    (environment : PsEnvironment) :
    Except PsElabError PsEnvironment :=
  match declarations with
  | List.nil =>
      Except.ok environment
  | List.cons declaration rest =>
      let name := psDeclarationName declaration;
      let nextResult :=
        psEnvironmentAddOwnedBootstrapDeclaration
          environment
          declaration;
      match nextResult with
      | none =>
          Except.error
            (PsElabError.duplicateDeclaration name)
      | some next =>
          psAddDeclarationListWorker rest next

def psAddDeclarationList
    (environment : PsEnvironment)
    (declarations : List PsDeclaration) :
    Except PsElabError PsEnvironment :=
  psAddDeclarationListWorker declarations environment

def psOpenConstructorFieldsWorker
    (fuel : Nat) :
    PsElabContext ->
    PsExpr ->
    List PsElabTypedBinder ->
    Except PsElabError PsElabConstructorBuildResult :=
  match fuel with
  | Nat.zero =>
      fun (context : PsElabContext)
          (_cursor : PsExpr)
          (bindersRev : List PsElabTypedBinder) =>
        Except.ok
          (PsElabConstructorBuildResult.mk
            context
            bindersRev)
  | Nat.succ remaining =>
      fun (context : PsElabContext)
          (cursor : PsExpr)
          (bindersRev : List PsElabTypedBinder) =>
        let smaller :
            PsElabContext ->
            PsExpr ->
            List PsElabTypedBinder ->
            Except PsElabError PsElabConstructorBuildResult :=
          psOpenConstructorFieldsWorker remaining;
        match psInferEnsureForall
            context.environment
            context.metaContext
            context.localContext
            cursor with
        | Except.error error =>
            Except.error (PsElabError.infer error)
        | Except.ok forallView =>
            let pushed :=
              psLocalPushBinding
                context.localContext
                forallView.name
                forallView.domain
                forallView.binder;
            let nextContext :=
              psElabContextWithLocal context pushed.context;
            smaller
              nextContext
              (psExprInstantiate1
                forallView.body
                (PsExpr.fvar pushed.id))
              (List.cons
                (PsElabTypedBinder.mk
                  pushed.id
                  forallView.name
                  forallView.domain
                  forallView.binder)
                bindersRev)

def psOpenConstructorFields
    (context : PsElabContext)
    (fuel : Nat)
    (cursor : PsExpr)
    (bindersRev : List PsElabTypedBinder) :
    Except PsElabError PsElabConstructorBuildResult :=
  psOpenConstructorFieldsWorker
    fuel
    context
    cursor
    bindersRev

def psElabExprAt
    (values : List PsExpr) : Nat -> Option PsExpr :=
  match values with
  | List.nil =>
      fun (_index : Nat) => Option.none
  | List.cons head tail =>
      let smaller : Nat -> Option PsExpr :=
        psElabExprAt tail;
      fun (index : Nat) =>
        match index with
        | Nat.zero =>
            Option.some head
        | Nat.succ rest =>
            smaller rest

def psElabAppendExprs
    (left : List PsExpr) : List PsExpr -> List PsExpr :=
  match left with
  | List.nil =>
      fun (right : List PsExpr) => right
  | List.cons head tail =>
      let smaller : List PsExpr -> List PsExpr :=
        psElabAppendExprs tail;
      fun (right : List PsExpr) =>
        List.cons head (smaller right)

def psElabAppendDeclarations
    (left : List PsDeclaration) :
    List PsDeclaration -> List PsDeclaration :=
  match left with
  | List.nil =>
      fun (right : List PsDeclaration) => right
  | List.cons head tail =>
      let smaller : List PsDeclaration -> List PsDeclaration :=
        psElabAppendDeclarations tail;
      fun (right : List PsDeclaration) =>
        List.cons head (smaller right)

def psWrapRecursiveHypotheses
    (motiveId : Nat)
    (fieldArgs : List PsExpr)
    (indices : List Nat)
    (body : PsExpr) : Except PsElabError PsExpr :=
  match indices with
  | List.nil => Except.ok body
  | List.cons fieldIndex rest =>
      match psElabExprAt fieldArgs fieldIndex with
      | none => Except.error PsElabError.unsupportedTerm
      | some recursiveValue =>
          match
              psWrapRecursiveHypotheses
                motiveId
                fieldArgs
                rest
                body with
          | Except.error error => Except.error error
          | Except.ok inner =>
              Except.ok
                (PsExpr.forallE
                  (psNameAppendNum
                    (psRootName "_ih")
                    fieldIndex)
                  (PsExpr.app
                    (PsExpr.fvar motiveId)
                    recursiveValue)
                  inner
                  PsBinderInfo.explicit)

def psBuildInductiveMinorType
    (context : PsElabContext)
    (parameterArgs : List PsExpr)
    (motiveId : Nat)
    (declaration : PsDeclaration) :
    Except PsElabError PsExpr :=
  match declaration with
  | .constructorDecl info =>
      match psElabMatchApplyParameters
          context
          parameterArgs
          info.type with
      | Except.error error => Except.error error
      | Except.ok fieldCursor =>
          match psOpenConstructorFields
              context
              info.numFields
              fieldCursor
              [] with
          | Except.error error => Except.error error
          | Except.ok fields =>
              let fieldArgs :=
                psElabBinderArguments fields.bindersRev;
              let intro :=
                psExprApplyMany
                  (PsExpr.constE info.name [])
                  (psElabAppendExprs parameterArgs fieldArgs);
              let body :=
                PsExpr.app (PsExpr.fvar motiveId) intro;
              match
                  psWrapRecursiveHypotheses
                    motiveId
                    fieldArgs
                    info.recursiveFields
                    body with
              | Except.error error => Except.error error
              | Except.ok withHypotheses =>
                  Except.ok
                    (psCloseElabForallBinders
                      fields.context.metaContext
                      fields.bindersRev
                      withHypotheses)
  | _ => Except.error PsElabError.unsupportedTerm

structure PsElabRecursorMinorsResult where
  context : PsElabContext
  bindersRev : List PsElabTypedBinder

def psBuildRecursorMinorBindersWorker
    (parameterArgs : List PsExpr)
    (motiveId : Nat)
    (declarations : List PsDeclaration) :
    PsElabContext ->
    Nat ->
    List PsElabTypedBinder ->
    Except PsElabError PsElabRecursorMinorsResult :=
  match declarations with
  | List.nil =>
      fun (context : PsElabContext) =>
        fun (_index : Nat) =>
          fun (bindersRev : List PsElabTypedBinder) =>
            Except.ok
              (PsElabRecursorMinorsResult.mk
                context
                bindersRev)
  | List.cons declaration rest =>
      let smaller :
          PsElabContext ->
          Nat ->
          List PsElabTypedBinder ->
          Except PsElabError PsElabRecursorMinorsResult :=
        psBuildRecursorMinorBindersWorker
          parameterArgs
          motiveId
          rest;
      fun (context : PsElabContext) =>
        fun (index : Nat) =>
          fun (bindersRev : List PsElabTypedBinder) =>
            match psBuildInductiveMinorType
                context
                parameterArgs
                motiveId
                declaration with
            | Except.error error => Except.error error
            | Except.ok minorType =>
                let minorName :=
                  psNameAppendNum (psRootName "_minor") index;
                let pushed :=
                  psLocalPushBinding
                    context.localContext
                    minorName
                    minorType
                    PsBinderInfo.explicit;
                let nextContext :=
                  psElabContextWithLocal context pushed.context;
                smaller
                  nextContext
                  (Nat.succ index)
                  (List.cons
                    (PsElabTypedBinder.mk
                      pushed.id
                      minorName
                      minorType
                      PsBinderInfo.explicit)
                    bindersRev)

def psBuildRecursorMinorBinders
    (parameterArgs : List PsExpr)
    (motiveId : Nat)
    (declarations : List PsDeclaration)
    (context : PsElabContext)
    (index : Nat)
    (bindersRev : List PsElabTypedBinder) :
    Except PsElabError PsElabRecursorMinorsResult :=
  psBuildRecursorMinorBindersWorker
    parameterArgs
    motiveId
    declarations
    context
    index
    bindersRev

def psBuildInductiveRecursor
    (context : PsElabContext)
    (parameterBindersRev : List PsElabTypedBinder)
    (inductiveInfo : PsInductiveInfo)
    (constructors : List PsDeclaration) :
    Except PsElabError PsDeclaration :=
  let universeName := psRootName "u";
  let parameterArgs :=
    psElabBinderArguments parameterBindersRev;
  let inductiveType :=
    psExprApplyMany
      (PsExpr.constE inductiveInfo.name List.nil)
      parameterArgs;
  let motiveName := psRootName "_motive";
  let motiveType :=
    PsExpr.forallE
      (psRootName "_major")
      inductiveType
      (PsExpr.sortE (PsLevel.param universeName))
      PsBinderInfo.explicit;
  let motivePush :=
    psLocalPushBinding
      context.localContext
      motiveName
      motiveType
      PsBinderInfo.explicit;
  let motiveContext :=
    psElabContextWithLocal context motivePush.context;
  match psBuildRecursorMinorBinders
      parameterArgs
      motivePush.id
      constructors
      motiveContext
      0
      List.nil with
  | Except.error error =>
      Except.error error
  | Except.ok minors =>
      let majorName := psRootName "_major";
      let majorPush :=
        psLocalPushBinding
          minors.context.localContext
          majorName
          inductiveType
          PsBinderInfo.explicit;
      let majorBinder : PsElabTypedBinder :=
        PsElabTypedBinder.mk
          majorPush.id
          majorName
          inductiveType
          PsBinderInfo.explicit;
      let motiveBinder : PsElabTypedBinder :=
        PsElabTypedBinder.mk
          motivePush.id
          motiveName
          motiveType
          PsBinderInfo.explicit;
      let body :=
        PsExpr.app
          (PsExpr.fvar motivePush.id)
          (PsExpr.fvar majorPush.id);
      let withMajor :=
        psCloseElabForallBinders
          minors.context.metaContext
          (List.cons majorBinder List.nil)
          body;
      let withMinors :=
        psCloseElabForallBinders
          minors.context.metaContext
          minors.bindersRev
          withMajor;
      let withMotive :=
        psCloseElabForallBinders
          minors.context.metaContext
          (List.cons motiveBinder List.nil)
          withMinors;
      let recursorType :=
        psCloseElabImplicitBinders
          minors.context.metaContext
          parameterBindersRev
          withMotive;
      let recursorName :=
        psNameAppendStr inductiveInfo.name "rec";
      if psExprHasUnresolvedMeta recursorType then
        Except.error PsElabError.unresolvedMetavariable
      else
        Except.ok
          (PsDeclaration.recursorDecl
            (PsRecursorInfo.mk
              recursorName
              (List.cons universeName List.nil)
              recursorType
              (List.cons inductiveInfo.name List.nil)
              (psElabListLength parameterArgs)
              0
              1
              (psElabListLength constructors)))

def psElabInductiveDeclaration
    (environment : PsEnvironment)
    (nameSyntax : PsSyntaxName)
    (params : List (PsSyntaxBinderHead × PsSyntaxTerm))
    (resultType : Option PsSyntaxTerm)
    (constructors : List PsSyntaxInductiveConstructor)
    (isStructure : Bool) :
    Except PsElabError PsElabDeclarationBatchResult :=
  match psSyntaxNameToName nameSyntax with
  | Option.none => Except.error PsElabError.emptyName
  | Option.some name =>
      let initial := psElabContextEmpty environment;
      match psElabTypedBinders
          psElabDeclarationTermCallback
          initial
          params with
      | Except.error error => Except.error error
      | Except.ok parameters =>
          let result : Except PsElabError (Prod PsElabContext PsExpr) :=
            match resultType with
            | Option.none =>
                Except.ok
                  (Prod.mk
                    parameters.context
                    (PsExpr.sortE (PsLevel.succ PsLevel.zero)))
            | Option.some sourceType =>
                match psElabTerm
                    parameters.context
                    sourceType
                    Option.none with
                | Except.error error => Except.error error
                | Except.ok elaborated =>
                    match psInferEnsureSort
                        elaborated.context.environment
                        elaborated.context.metaContext
                        elaborated.context.localContext
                        elaborated.type with
                    | Except.error error =>
                        Except.error (PsElabError.infer error)
                    | Except.ok _ =>
                        Except.ok
                          (Prod.mk
                            elaborated.context
                            elaborated.term);
          match result with
          | Except.error error => Except.error error
          | Except.ok headerResult =>
              let headerContext := Prod.fst headerResult;
              let openResultType := Prod.snd headerResult;
              let instantiatedResultType :=
                psMetaInstantiate
                  headerContext.metaContext
                  openResultType;
              let resultTypeIsSortOne : Bool :=
                match instantiatedResultType with
                | PsExpr.sortE level =>
                    match level with
                    | PsLevel.succ innerLevel =>
                        match innerLevel with
                        | PsLevel.zero => true
                        | _ => false
                    | _ => false
                | _ => false;
              if resultTypeIsSortOne then
                  let inductiveType :=
                    psCloseElabForallBinders
                      headerContext.metaContext
                      parameters.bindersRev
                      instantiatedResultType;
                  if psExprHasUnresolvedMeta inductiveType then
                    Except.error PsElabError.unresolvedMetavariable
                  else
                    let constructorNames :=
                      psElabInductiveConstructorNames
                        name
                        constructors;
                    let parameterArgs :=
                      psElabBinderArguments parameters.bindersRev;
                    let info : PsInductiveInfo := {
                      name := name
                      levelParams := []
                      type := inductiveType
                      numParams := psElabListLength parameterArgs
                      numIndices := 0
                      constructors := constructorNames
                      isStructure := isStructure
                    };
                    let inductiveDeclaration :=
                      PsDeclaration.inductiveDecl info;
                    let withInductiveResult :=
                      psEnvironmentAddOwnedBootstrapDeclaration
                        environment
                        inductiveDeclaration;
                    match withInductiveResult with
                    | Option.none =>
                        Except.error
                          (PsElabError.duplicateDeclaration name)
                    | Option.some withInductive =>
                        let constructorContext :=
                          psElabContextWithEnvironment
                            headerContext
                            withInductive;
                        match psElabInductiveConstructors
                            constructorContext
                            parameters.bindersRev
                            name
                            0
                            constructors
                            [] with
                        | Except.error error =>
                            Except.error error
                        | Except.ok constructorDeclarations =>
                            match psAddDeclarationList
                                withInductive
                                constructorDeclarations with
                            | Except.error error =>
                                Except.error error
                            | Except.ok withConstructors =>
                                let recursorContext :=
                                  psElabContextWithEnvironment
                                    headerContext
                                    withConstructors;
                                match psBuildInductiveRecursor
                                    recursorContext
                                    parameters.bindersRev
                                    info
                                    constructorDeclarations with
                                | Except.error error =>
                                    Except.error error
                                | Except.ok recursor =>
                                    Except.ok
                                      (PsElabDeclarationBatchResult.mk
                                        (psElabAppendDeclarations
                                          (List.cons
                                            inductiveDeclaration
                                            constructorDeclarations)
                                          (List.cons recursor List.nil)))
              else
                  Except.error PsElabError.unsupportedTerm



def psElabStructureDeclaration
    (environment : PsEnvironment)
    (name : PsSyntaxName)
    (params : List (PsSyntaxBinderHead × PsSyntaxTerm))
    (fields : List (PsSyntaxBinderHead × PsSyntaxTerm))
    (span : PsSourceSpan) :
    Except PsElabError PsElabDeclarationBatchResult :=
  let constructorName : PsSyntaxName :=
    PsSyntaxName.mk
      (List.cons "mk" List.nil)
      span;
  let constructor : PsSyntaxInductiveConstructor :=
    PsSyntaxInductiveConstructor.mk
      constructorName
      fields
      span;
  psElabInductiveDeclaration
    environment
    name
    params
    Option.none
    (List.cons constructor List.nil)
    true

def psElabPartialDeclaration
    (environment : PsEnvironment)
    (nameSyntax : PsSyntaxName)
    (binders : List (PsSyntaxBinderHead × PsSyntaxTerm))
    (typeSyntax : PsSyntaxTerm)
    (valueSyntax : PsSyntaxTerm) :
    Except PsElabError PsElabDeclarationResult :=
  match psSyntaxNameToName nameSyntax with
  | Option.none => Except.error PsElabError.emptyName
  | Option.some name =>
      let initial := psElabContextEmpty environment;
      match
          psElabTypedBinders
            psElabDeclarationTermCallback
            initial
            binders with
      | Except.error error =>
          Except.error error
      | Except.ok binderResult =>
          match
              psElabTerm
                binderResult.context
                typeSyntax
                Option.none with
          | Except.error error =>
              Except.error error
          | Except.ok typeResult =>
              match
                  psInferEnsureSort
                    typeResult.context.environment
                    typeResult.context.metaContext
                    typeResult.context.localContext
                    typeResult.type with
              | Except.error error =>
                  Except.error (PsElabError.infer error)
              | Except.ok _ =>
                  let typeMeta := typeResult.context.metaContext;
                  let openType :=
                    psMetaInstantiate typeMeta typeResult.term;
                  let closedType :=
                    psCloseElabForallBinders
                      typeMeta
                      binderResult.bindersRev
                      openType;
                  if psExprHasUnresolvedMeta closedType then
                    Except.error PsElabError.unresolvedMetavariable
                  else
                    let selfHeader :=
                      PsDeclaration.axiomDecl name List.nil closedType;
                    match psEnvironmentAdd environment selfHeader with
                    | Option.none =>
                        Except.error
                          (PsElabError.duplicateDeclaration name)
                    | Option.some withSelf =>
                        let valueContext :=
                          psElabContextWithEnvironment
                            typeResult.context
                            withSelf;
                        match
                            psElabTerm
                              valueContext
                              valueSyntax
                              (Option.some openType) with
                        | Except.error error => Except.error error
                        | Except.ok valueResult =>
                            let metaContext :=
                              valueResult.context.metaContext;
                            let openValue :=
                              psMetaInstantiate
                                metaContext
                                valueResult.term;
                            let finalOpenType :=
                              psMetaInstantiate
                                metaContext
                                openType;
                            let closed :=
                              psCloseElabTypedBinders
                                metaContext
                                binderResult.bindersRev
                                openValue
                                finalOpenType;
                            if
                                psExprHasUnresolvedMeta
                                  (Prod.fst closed) then
                              Except.error
                                PsElabError.unresolvedMetavariable
                            else if
                                psExprHasUnresolvedMeta
                                  (Prod.snd closed) then
                              Except.error
                                PsElabError.unresolvedMetavariable
                            else
                              Except.ok
                                (PsElabDeclarationResult.mk
                                  (PsDeclaration.partialDecl
                                    name
                                    List.nil
                                    (Prod.snd closed)
                                    (Prod.fst closed))
                                  metaContext)

def psElabDeclaration
    (environment : PsEnvironment)
    (source : PsSyntaxDeclaration) :
    Except PsElabError PsElabDeclarationResult :=
  match source with
  | .definition name binders type value _ =>
      psElabDeclarationParts
        environment
        name
        binders
        type
        value
        false
  | .partialDefinition name binders type value _ =>
      psElabPartialDeclaration
        environment
        name
        binders
        type
        value
  | .theoremDecl name binders type value _ =>
      psElabDeclarationParts
        environment
        name
        binders
        type
        value
        true
  | .inductiveDecl _ _ _ _ _ =>
      Except.error PsElabError.unsupportedTerm
  | .structureDecl _ _ _ _ =>
      Except.error PsElabError.unsupportedTerm

-- Elaborate the canonical worker with the original source self name, then give
-- its closed core declaration an internal numeric name. Recursive core terms are
-- recursors, so this rename cannot leave an unresolved self constant behind.
-- The richer result keeps the two actual declarations and the known error phase.
def psElabNormalizedDefinitionWithPhase
    (environment : PsEnvironment) (sourceName : PsSyntaxName)
    (normalized : PsElabStructuralNormalization) :
    Except PsElabOriginPhaseError PsElabNormalizedDefinitionResult :=
  match psElabDeclarationParts environment sourceName
      normalized.workerBinders normalized.workerType normalized.workerValue false with
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
              let application : PsExpr := psExprApplyMany
                (PsExpr.constE normalized.workerName List.nil)
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
                      normalized.publicName List.nil (Prod.snd closed) (Prod.fst closed);
                    Except.ok
                      (PsElabNormalizedDefinitionResult.mk worker publicDeclaration)
      | _ =>
          Except.error
            (PsElabOriginPhaseError.mk PsElabError.structuralRecursionInternal
              PsElabOriginPhase.normalizedWorker)

def psElabNormalizedDefinitionBatch
    (result : PsElabNormalizedDefinitionResult) : PsElabDeclarationBatchResult :=
  PsElabDeclarationBatchResult.mk
    (List.cons result.worker (List.cons result.publicDeclaration List.nil))

def psElabNormalizedDefinition
    (environment : PsEnvironment) (sourceName : PsSyntaxName)
    (normalized : PsElabStructuralNormalization) :
    Except PsElabError PsElabDeclarationBatchResult :=
  match psElabNormalizedDefinitionWithPhase environment sourceName normalized with
  | Except.error failure => Except.error failure.error
  | Except.ok result => Except.ok (psElabNormalizedDefinitionBatch result)

def psElabDeclarationBatchStable
    (environment : PsEnvironment)
    (source : PsSyntaxDeclaration) :
    Except PsElabError PsElabDeclarationBatchResult :=
  match source with
  | .inductiveDecl name params resultType constructors _ =>
      psElabInductiveDeclaration
        environment
        name
        params
        resultType
        constructors
        false
  | .structureDecl name params fields span =>
      psElabStructureDeclaration
        environment
        name
        params
        fields
        span
  | _ =>
      match psElabDeclaration environment source with
      | Except.error error => Except.error error
      | Except.ok result =>
          Except.ok
            (PsElabDeclarationBatchResult.mk
              (List.cons result.declaration List.nil))

-- Historical callers can request the unchanged stable elaborator explicitly.
-- The ordinary path keeps its one typed normalization attempt for the same
-- capability refusal. Origins are recorded from that execution, not a replay.
def psElabDeclarationBatchWithOrigins
    (environment : PsEnvironment) (sourceIndex : Nat)
    (source : PsSyntaxDeclaration) :
    Except PsElabOriginError PsElabDeclarationBatchWithOriginsResult :=
  match psElabDeclarationBatchStable environment source with
  | Except.ok result =>
      let members : List PsElabMemberOrigin :=
        psElabStableMemberOrigins result.declarations 0;
      Except.ok
        (PsElabDeclarationBatchWithOriginsResult.mk result
          (psElabBatchOriginAt sourceIndex source members Option.none))
  | Except.error error =>
      match error with
      | PsElabError.structuralRecursionInvariantArgument =>
          match source with
          | PsSyntaxDeclaration.definition name binders type value span =>
              match psElabPlanStructuralNormalizationWithOrigin
                  environment name binders type value span with
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
                          environment name normalized.normalization with
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
                              (psElabBatchOriginAt sourceIndex source members
                                (Option.some normalized.origin)))
          | _ =>
              Except.error
                (psElabOriginErrorAt sourceIndex source
                  PsElabOriginPhase.stableDeclaration error)
      | _ =>
          Except.error
            (psElabOriginErrorAt sourceIndex source
              PsElabOriginPhase.stableDeclaration error)

def psElabDeclarationBatch
    (environment : PsEnvironment) (source : PsSyntaxDeclaration) :
    Except PsElabError PsElabDeclarationBatchResult :=
  match psElabDeclarationBatchWithOrigins environment 0 source with
  | Except.error failure => Except.error failure.error
  | Except.ok result => Except.ok result.result

def psPrependBatchReverse
    (declarations : List PsDeclaration)
    (declarationsRev : List PsDeclaration) :
    List PsDeclaration :=
  psElabAppendDeclarations
    (psElabReverseDeclarations declarations)
    declarationsRev

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
          (psListReverse originsRev))
  | List.cons source rest =>
      match psElabDeclarationBatchWithOrigins environment sourceIndex source with
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
    Except PsElabOriginError PsElabModuleWithOriginsResult :=
  psElabDeclarationsWithOriginsWorker
    sourceModule.declarations environment List.nil List.nil 0

def psElabModule
    (environment : PsEnvironment)
    (module : PsSyntaxModule) :
    Except PsElabError PsElabModuleResult :=
  match psElabModuleWithOrigins environment module with
  | Except.error failure => Except.error failure.error
  | Except.ok result => Except.ok result.result
