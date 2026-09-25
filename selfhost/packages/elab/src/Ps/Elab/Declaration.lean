import Ps.Core.Declaration
import Ps.Core.Equality
import Ps.Elab.Term

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

def psElabExplicitParameterIds :
    List PsElabTypedBinder -> List Nat
  | [] => []
  | binder :: rest =>
      match binder.binder with
      | PsBinderInfo.explicit =>
          binder.id :: psElabExplicitParameterIds rest
      | _ =>
          psElabExplicitParameterIds rest

def psElabFindNatIndex
    (target : Nat) :
    List Nat -> Nat -> Option Nat
  | [], _ => none
  | value :: rest, index =>
      if value == target then
        some index
      else
        psElabFindNatIndex target rest (index + 1)

def psElabStructuralRecursionFromSource
    (functionName : PsName)
    (bindersRev : List PsElabTypedBinder)
    (body : PsSyntaxTerm)
    (context : PsElabContext) :
    Option PsElabStructuralRecursion :=
  match body with
  | .matchE (.reference scrutineeName) _ _ =>
      match psSyntaxNameToName scrutineeName with
      | none => none
      | some sourceName =>
          match
              psResolveName
                context.localContext
                context.environment
                sourceName with
          | some (.local scrutineeId) =>
              let explicitParameterIds :=
                psElabExplicitParameterIds bindersRev.reverse
              match
                  psElabFindNatIndex
                    scrutineeId
                    explicitParameterIds
                    0 with
              | none => none
              | some recursiveParameterIndex =>
                  some {
                    functionName := functionName
                    explicitParameterIds := explicitParameterIds
                    recursiveParameterIndex := recursiveParameterIndex
                    calls := []
                  }
          | _ => none
  | _ => none

def psElabDeclarationParts
    (environment : PsEnvironment)
    (nameSyntax : PsSyntaxName)
    (binders : List (PsSyntaxBinderHead × PsSyntaxTerm))
    (typeSyntax : PsSyntaxTerm)
    (valueSyntax : PsSyntaxTerm)
    (isTheorem : Bool) :
    Except PsElabError PsElabDeclarationResult :=
  match psSyntaxNameToName nameSyntax with
  | none => Except.error PsElabError.emptyName
  | some name =>
      let initial := psElabContextEmpty environment
      match psElabTypedBinders
          (fun context term expected => psElabTerm context term expected)
          initial
          binders with
      | Except.error error => Except.error error
      | Except.ok binderResult =>
          match psElabTerm binderResult.context typeSyntax none with
          | Except.error error => Except.error error
          | Except.ok typeResult =>
              match psInferEnsureSort
                  typeResult.context.environment
                  typeResult.context.metaContext
                  typeResult.context.localContext
                  typeResult.type with
              | Except.error error =>
                  Except.error (PsElabError.infer error)
              | Except.ok _ =>
                  let valueContext :=
                    if isTheorem then
                      typeResult.context
                    else
                      psElabContextWithStructuralRecursion
                        typeResult.context
                        (psElabStructuralRecursionFromSource
                          name
                          binderResult.bindersRev
                          valueSyntax
                          typeResult.context)
                  match psElabTerm
                      valueContext
                      valueSyntax
                      (some typeResult.term) with
                  | Except.error error => Except.error error
                  | Except.ok valueResult =>
                      let metaContext := valueResult.context.metaContext
                      let openValue :=
                        psMetaInstantiate metaContext valueResult.term
                      let openType :=
                        psMetaInstantiate metaContext typeResult.term
                      let closed :=
                        psCloseElabTypedBinders
                          metaContext
                          binderResult.bindersRev
                          openValue
                          openType
                      if
                          psExprHasUnresolvedMeta closed.1
                            || psExprHasUnresolvedMeta closed.2 then
                        Except.error PsElabError.unresolvedMetavariable
                      else if isTheorem then
                        Except.ok {
                          declaration :=
                            PsDeclaration.theoremDecl
                              name
                              []
                              closed.2
                              closed.1
                          metaContext := metaContext
                        }
                      else
                        Except.ok {
                          declaration :=
                            PsDeclaration.definitionDecl
                              name
                              []
                              closed.2
                              closed.1
                          metaContext := metaContext
                        }

def psSyntaxConstructorCoreName
    (inductiveName : PsName)
    (sourceName : PsSyntaxName) : Option PsName :=
  match sourceName.segments with
  | [segment] => some (psNameAppendStr inductiveName segment)
  | _ => none

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

def psElabBinderArguments
    (bindersRev : List PsElabTypedBinder) : List PsExpr :=
  bindersRev.reverse.map (fun binder => PsExpr.fvar binder.id)

def psCloseElabImplicitBinders
    (metaContext : PsMetaContext) :
    List PsElabTypedBinder -> PsExpr -> PsExpr
  | [], body => body
  | binder :: rest, body =>
      let binderType :=
        psMetaInstantiate metaContext binder.type
      let closed :=
        PsExpr.forallE
          binder.name
          binderType
          (psExprAbstractFVar binder.id body)
          PsBinderInfo.implicit
      psCloseElabImplicitBinders metaContext rest closed

def psExprListAlphaEq : List PsExpr -> List PsExpr -> Bool
  | [], [] => true
  | left :: leftRest, right :: rightRest =>
      psExprAlphaEq left right
        && psExprListAlphaEq leftRest rightRest
  | _, _ => false

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
      type
  let view := psExprAppView reduced
  match view.head with
  | .constE name _ =>
      psNameEq name inductiveName
        && view.args.length == parameterArgs.length
        && psExprListAlphaEq view.args parameterArgs
  | _ => false

def psElabNestedRecursiveFieldTypeSupportedWithFuel :
    Nat -> PsName -> PsExpr -> Bool
  | 0, _, _ => false
  | remaining + 1, inductiveName, type =>
      if !psExprHasConst inductiveName type then
        true
      else
        let view := psExprAppView type
        match view.head with
        | .constE name _ =>
            if psNameEq name inductiveName then
              true
            else if psNameEq name psListName
                || psNameEq name psOptionName
                || psNameEq name psArrayName then
              match view.args with
              | [argument] =>
                  psElabNestedRecursiveFieldTypeSupportedWithFuel
                    remaining
                    inductiveName
                    argument
              | _ => false
            else if psNameEq name psProdName then
              match view.args with
              | [left, right] =>
                  psElabNestedRecursiveFieldTypeSupportedWithFuel
                      remaining
                      inductiveName
                      left
                    && psElabNestedRecursiveFieldTypeSupportedWithFuel
                      remaining
                      inductiveName
                      right
              | _ => false
            else
              false
        | _ => false

def psElabNestedRecursiveFieldTypeSupported
    (inductiveName : PsName)
    (type : PsExpr) : Bool :=
  psElabNestedRecursiveFieldTypeSupportedWithFuel
    4096
    inductiveName
    type

def psElabRecursiveFieldIndices
    (context : PsElabContext)
    (inductiveName : PsName)
    (parameterArgs : List PsExpr) :
    List PsElabTypedBinder ->
    Nat ->
    List Nat ->
    Except PsElabError (List Nat)
  | [], _, indicesRev => Except.ok indicesRev.reverse
  | field :: rest, index, indicesRev =>
      let direct :=
        psElabIsDirectRecursiveField
          context
          inductiveName
          parameterArgs
          field.type
      if direct then
        psElabRecursiveFieldIndices
          context
          inductiveName
          parameterArgs
          rest
          (index + 1)
          (index :: indicesRev)
      else if psExprHasConst inductiveName field.type then
        if psElabNestedRecursiveFieldTypeSupported
            inductiveName
            field.type then
          psElabRecursiveFieldIndices
            context
            inductiveName
            parameterArgs
            rest
            (index + 1)
            indicesRev
        else
          Except.error PsElabError.unsupportedTerm
      else
        psElabRecursiveFieldIndices
          context
          inductiveName
          parameterArgs
          rest
          (index + 1)
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
          (fun nextContext term expected =>
            psElabTerm nextContext term expected)
          context
          source.fields with
      | Except.error error => Except.error error
      | Except.ok fields =>
          let metaContext := fields.context.metaContext
          let parameterArgs :=
            psElabBinderArguments parameterBindersRev
          match
              psElabRecursiveFieldIndices
                fields.context
                inductiveName
                parameterArgs
                fields.bindersRev.reverse
                0
                [] with
          | Except.error error => Except.error error
          | Except.ok recursiveFields =>
              let appliedInductive :=
                psExprApplyMany
                  (PsExpr.constE inductiveName [])
                  parameterArgs
              let fieldClosed :=
                psCloseElabForallBinders
                  metaContext
                  fields.bindersRev
                  appliedInductive
              let constructorType :=
                psCloseElabImplicitBinders
                  metaContext
                  parameterBindersRev
                  fieldClosed
              if psExprHasUnresolvedMeta constructorType then
                Except.error PsElabError.unresolvedMetavariable
              else
                Except.ok
                  (PsDeclaration.constructorDecl {
                    name := constructorName
                    levelParams := []
                    type := constructorType
                    inductiveName := inductiveName
                    constructorIndex := 0
                    numParams := parameterArgs.length
                    numFields := source.fields.length
                    recursiveFields := recursiveFields
                  })



def psSetConstructorIndex
    (index : Nat)
    (declaration : PsDeclaration) : PsDeclaration :=
  match declaration with
  | .constructorDecl info =>
      PsDeclaration.constructorDecl {
        info with constructorIndex := index
      }
  | _ => declaration

def psElabInductiveConstructors
    (context : PsElabContext)
    (parameterBindersRev : List PsElabTypedBinder)
    (inductiveName : PsName) :
    Nat ->
    List PsSyntaxInductiveConstructor ->
    List PsDeclaration ->
    Except PsElabError (List PsDeclaration)
  | _, [], declarationsRev =>
      Except.ok declarationsRev.reverse
  | index, source :: rest, declarationsRev =>
      match psElabInductiveConstructor
          context
          parameterBindersRev
          inductiveName
          source with
      | Except.error error => Except.error error
      | Except.ok declaration =>
          psElabInductiveConstructors
            context
            parameterBindersRev
            inductiveName
            (index + 1)
            rest
            (psSetConstructorIndex index declaration :: declarationsRev)



def psEnvironmentAddOwnedBootstrapDeclaration
    (environment : PsEnvironment)
    (declaration : PsDeclaration) : Option PsEnvironment :=
  let name := psDeclarationName declaration
  if psNameEq name psProdName
      || psNameEq name psListName
      || psNameEq name psOptionName then
    psEnvironmentAddReplacingAxiom
      environment
      declaration
  else
    psEnvironmentAdd environment declaration

def psAddDeclarationList
    (environment : PsEnvironment) :
    List PsDeclaration -> Except PsElabError PsEnvironment
  | [] => Except.ok environment
  | declaration :: rest =>
      let name := psDeclarationName declaration
      let nextResult :=
        psEnvironmentAddOwnedBootstrapDeclaration
          environment
          declaration
      match nextResult with
      | none =>
          Except.error
            (PsElabError.duplicateDeclaration name)
      | some next =>
          psAddDeclarationList next rest

def psOpenConstructorFields
    (context : PsElabContext) :
    Nat ->
    PsExpr ->
    List PsElabTypedBinder ->
    Except PsElabError PsElabConstructorBuildResult
  | 0, _, bindersRev =>
      Except.ok {
        context := context
        bindersRev := bindersRev
      }
  | remaining + 1, cursor, bindersRev =>
      match psInferEnsureForall
          context.environment
          context.metaContext
          context.localContext
          cursor with
      | Except.error error => Except.error (PsElabError.infer error)
      | Except.ok forallView =>
          let pushed :=
            psLocalPushBinding
              context.localContext
              forallView.name
              forallView.domain
              forallView.binder
          let nextContext :=
            psElabContextWithLocal context pushed.context
          psOpenConstructorFields
            nextContext
            remaining
            (psExprInstantiate1
              forallView.body
              (PsExpr.fvar pushed.id))
            ({
              id := pushed.id
              name := forallView.name
              type := forallView.domain
              binder := forallView.binder
            } :: bindersRev)

def psWrapRecursiveHypotheses
    (motiveId : Nat)
    (fieldArgs : List PsExpr) :
    List Nat -> PsExpr -> Except PsElabError PsExpr
  | [], body => Except.ok body
  | fieldIndex :: rest, body =>
      match fieldArgs[fieldIndex]? with
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
                fields.bindersRev.reverse.map
                  (fun field => PsExpr.fvar field.id)
              let intro :=
                psExprApplyMany
                  (PsExpr.constE info.name [])
                  (parameterArgs ++ fieldArgs)
              let body :=
                PsExpr.app (PsExpr.fvar motiveId) intro
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

def psBuildRecursorMinorBinders
    (parameterArgs : List PsExpr)
    (motiveId : Nat) :
    List PsDeclaration ->
    PsElabContext ->
    Nat ->
    List PsElabTypedBinder ->
    Except PsElabError PsElabRecursorMinorsResult
  | [], context, _, bindersRev =>
      Except.ok {
        context := context
        bindersRev := bindersRev
      }
  | declaration :: rest, context, index, bindersRev =>
      match psBuildInductiveMinorType
          context
          parameterArgs
          motiveId
          declaration with
      | Except.error error => Except.error error
      | Except.ok minorType =>
          let minorName :=
            psNameAppendNum (psRootName "_minor") index
          let pushed :=
            psLocalPushBinding
              context.localContext
              minorName
              minorType
              PsBinderInfo.explicit
          let nextContext :=
            psElabContextWithLocal context pushed.context
          psBuildRecursorMinorBinders
            parameterArgs
            motiveId
            rest
            nextContext
            (index + 1)
            ({
              id := pushed.id
              name := minorName
              type := minorType
              binder := PsBinderInfo.explicit
            } :: bindersRev)

def psBuildInductiveRecursor
    (context : PsElabContext)
    (parameterBindersRev : List PsElabTypedBinder)
    (inductiveInfo : PsInductiveInfo)
    (constructors : List PsDeclaration) :
    Except PsElabError PsDeclaration :=
  let universeName := psRootName "u"
  let parameterArgs :=
    psElabBinderArguments parameterBindersRev
  let inductiveType :=
    psExprApplyMany
      (PsExpr.constE inductiveInfo.name [])
      parameterArgs
  let motiveName := psRootName "_motive"
  let motiveType :=
    PsExpr.forallE
      (psRootName "_major")
      inductiveType
      (PsExpr.sortE (PsLevel.param universeName))
      PsBinderInfo.explicit
  let motivePush :=
    psLocalPushBinding
      context.localContext
      motiveName
      motiveType
      PsBinderInfo.explicit
  let motiveContext :=
    psElabContextWithLocal context motivePush.context
  match psBuildRecursorMinorBinders
      parameterArgs
      motivePush.id
      constructors
      motiveContext
      0
      [] with
  | Except.error error => Except.error error
  | Except.ok minors =>
      let majorName := psRootName "_major"
      let majorPush :=
        psLocalPushBinding
          minors.context.localContext
          majorName
          inductiveType
          PsBinderInfo.explicit
      let majorBinder : PsElabTypedBinder := {
        id := majorPush.id
        name := majorName
        type := inductiveType
        binder := PsBinderInfo.explicit
      }
      let motiveBinder : PsElabTypedBinder := {
        id := motivePush.id
        name := motiveName
        type := motiveType
        binder := PsBinderInfo.explicit
      }
      let body :=
        PsExpr.app
          (PsExpr.fvar motivePush.id)
          (PsExpr.fvar majorPush.id)
      let withMajor :=
        psCloseElabForallBinders
          minors.context.metaContext
          [majorBinder]
          body
      let withMinors :=
        psCloseElabForallBinders
          minors.context.metaContext
          minors.bindersRev
          withMajor
      let withMotive :=
        psCloseElabForallBinders
          minors.context.metaContext
          [motiveBinder]
          withMinors
      let recursorType :=
        psCloseElabImplicitBinders
          minors.context.metaContext
          parameterBindersRev
          withMotive
      let recursorName :=
        psNameAppendStr inductiveInfo.name "rec"
      if psExprHasUnresolvedMeta recursorType then
        Except.error PsElabError.unresolvedMetavariable
      else
        Except.ok
          (PsDeclaration.recursorDecl {
            name := recursorName
            levelParams := [universeName]
            type := recursorType
            inductiveNames := [inductiveInfo.name]
            numParams := parameterArgs.length
            numIndices := 0
            numMotives := 1
            numMinors := constructors.length
          })



def psElabInductiveDeclaration
    (environment : PsEnvironment)
    (nameSyntax : PsSyntaxName)
    (params : List (PsSyntaxBinderHead × PsSyntaxTerm))
    (resultType : Option PsSyntaxTerm)
    (constructors : List PsSyntaxInductiveConstructor)
    (isStructure : Bool := false) :
    Except PsElabError PsElabDeclarationBatchResult :=
  match psSyntaxNameToName nameSyntax with
  | none => Except.error PsElabError.emptyName
  | some name =>
      let initial := psElabContextEmpty environment
      match psElabTypedBinders
          (fun context term expected =>
            psElabTerm context term expected)
          initial
          params with
      | Except.error error => Except.error error
      | Except.ok parameters =>
          let result :=
            match resultType with
            | none =>
                Except.ok
                  (parameters.context,
                    PsExpr.sortE (PsLevel.succ PsLevel.zero))
            | some sourceType =>
                match psElabTerm
                    parameters.context
                    sourceType
                    none with
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
                          (elaborated.context, elaborated.term)
          match result with
          | Except.error error => Except.error error
          | Except.ok (headerContext, openResultType) =>
              let instantiatedResultType :=
                psMetaInstantiate
                  headerContext.metaContext
                  openResultType
              match instantiatedResultType with
              | PsExpr.sortE (PsLevel.succ PsLevel.zero) =>
                  let inductiveType :=
                    psCloseElabForallBinders
                      headerContext.metaContext
                      parameters.bindersRev
                      instantiatedResultType
                  if psExprHasUnresolvedMeta inductiveType then
                    Except.error PsElabError.unresolvedMetavariable
                  else
                    let constructorNames :=
                      constructors.map
                        (fun source =>
                          match
                              psSyntaxConstructorCoreName
                                name
                                source.name with
                          | some constructorName => constructorName
                          | none => name)
                    let parameterArgs :=
                      psElabBinderArguments parameters.bindersRev
                    let info : PsInductiveInfo := {
                      name := name
                      levelParams := []
                      type := inductiveType
                      numParams := parameterArgs.length
                      numIndices := 0
                      constructors := constructorNames
                      isStructure := isStructure
                    }
                    let inductiveDeclaration :=
                      PsDeclaration.inductiveDecl info
                    let withInductiveResult :=
                      psEnvironmentAddOwnedBootstrapDeclaration
                        environment
                        inductiveDeclaration
                    match withInductiveResult with
                    | none =>
                        Except.error
                          (PsElabError.duplicateDeclaration name)
                    | some withInductive =>
                        let constructorContext :=
                          psElabContextWithEnvironment
                            headerContext
                            withInductive
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
                                    withConstructors
                                match psBuildInductiveRecursor
                                    recursorContext
                                    parameters.bindersRev
                                    info
                                    constructorDeclarations with
                                | Except.error error =>
                                    Except.error error
                                | Except.ok recursor =>
                                    Except.ok {
                                      declarations :=
                                        [inductiveDeclaration]
                                          ++ constructorDeclarations
                                          ++ [recursor]
                                    }
              | _ =>
                  Except.error PsElabError.unsupportedTerm



def psElabStructureDeclaration
    (environment : PsEnvironment)
    (name : PsSyntaxName)
    (params : List (PsSyntaxBinderHead × PsSyntaxTerm))
    (fields : List (PsSyntaxBinderHead × PsSyntaxTerm))
    (span : PsSourceSpan) :
    Except PsElabError PsElabDeclarationBatchResult :=
  if fields.isEmpty then
    Except.error PsElabError.unsupportedTerm
  else
    let constructorName : PsSyntaxName := {
      segments := ["mk"]
      span := span
    }
    let constructor : PsSyntaxInductiveConstructor := {
      name := constructorName
      fields := fields
      span := span
    }
    psElabInductiveDeclaration
      environment
      name
      params
      none
      [constructor]
      true

def psElabPartialDeclaration
    (environment : PsEnvironment)
    (nameSyntax : PsSyntaxName)
    (binders : List (PsSyntaxBinderHead × PsSyntaxTerm))
    (typeSyntax : PsSyntaxTerm)
    (valueSyntax : PsSyntaxTerm) :
    Except PsElabError PsElabDeclarationResult :=
  match psSyntaxNameToName nameSyntax with
  | none => Except.error PsElabError.emptyName
  | some name =>
      let initial := psElabContextEmpty environment
      match
          psElabTypedBinders
            (fun context term expected =>
              psElabTerm context term expected)
            initial
            binders with
      | Except.error error => Except.error error
      | Except.ok binderResult =>
          match
              psElabTerm
                binderResult.context
                typeSyntax
                none with
          | Except.error error => Except.error error
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
                  let typeMeta := typeResult.context.metaContext
                  let openType :=
                    psMetaInstantiate typeMeta typeResult.term
                  let closedType :=
                    psCloseElabForallBinders
                      typeMeta
                      binderResult.bindersRev
                      openType
                  if psExprHasUnresolvedMeta closedType then
                    Except.error PsElabError.unresolvedMetavariable
                  else
                    let selfHeader :=
                      PsDeclaration.axiomDecl name [] closedType
                    match psEnvironmentAdd environment selfHeader with
                    | none =>
                        Except.error
                          (PsElabError.duplicateDeclaration name)
                    | some withSelf =>
                        let valueContext :=
                          psElabContextWithEnvironment
                            typeResult.context
                            withSelf
                        match
                            psElabTerm
                              valueContext
                              valueSyntax
                              (some openType) with
                        | Except.error error => Except.error error
                        | Except.ok valueResult =>
                            let metaContext :=
                              valueResult.context.metaContext
                            let openValue :=
                              psMetaInstantiate
                                metaContext
                                valueResult.term
                            let finalOpenType :=
                              psMetaInstantiate
                                metaContext
                                openType
                            let closed :=
                              psCloseElabTypedBinders
                                metaContext
                                binderResult.bindersRev
                                openValue
                                finalOpenType
                            if
                                psExprHasUnresolvedMeta closed.1
                                  || psExprHasUnresolvedMeta closed.2 then
                              Except.error
                                PsElabError.unresolvedMetavariable
                            else
                              Except.ok {
                                declaration :=
                                  PsDeclaration.partialDecl
                                    name
                                    []
                                    closed.2
                                    closed.1
                                metaContext := metaContext
                              }

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

def psElabDeclarationBatch
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
          Except.ok { declarations := [result.declaration] }

def psPrependBatchReverse
    (declarations : List PsDeclaration)
    (declarationsRev : List PsDeclaration) :
    List PsDeclaration :=
  declarations.reverse ++ declarationsRev

def psElabDeclarations
    (environment : PsEnvironment) :
    List PsSyntaxDeclaration ->
    List PsDeclaration ->
    Except PsElabError PsElabModuleResult
  | [], declarationsRev =>
      Except.ok {
        environment := environment
        declarations := declarationsRev.reverse
      }
  | source :: rest, declarationsRev =>
      match psElabDeclarationBatch environment source with
      | Except.error error => Except.error error
      | Except.ok result =>
          match psAddDeclarationList environment result.declarations with
          | Except.error error => Except.error error
          | Except.ok nextEnvironment =>
              psElabDeclarations
                nextEnvironment
                rest
                (psPrependBatchReverse
                  result.declarations
                  declarationsRev)

def psElabModule
    (environment : PsEnvironment)
    (module : PsSyntaxModule) :
    Except PsElabError PsElabModuleResult :=
  psElabDeclarations environment module.declarations []
