import Ps.Core.Abstract
import Ps.Core.Subst
import Ps.Environment.Resolve
import Ps.Meta.Infer
import Ps.Meta.Unify
import Ps.Syntax.Ast
import Ps.Elab.Context
import Ps.Elab.Literal

inductive PsElabError where
  | fuelExhausted
  | emptyName
  | unknownName (name : PsName)
  | invalidNatural (text : String)
  | invalidString (text : String)
  | invalidCharacter (text : String)
  | infer (error : PsInferError)
  | typeMismatch
  | implicitApplicationUnsupported
  | unsupportedTerm
  | matchExpectedType
  | matchScrutineeUnsupported
  | matchInductiveUnsupported
  | matchParameterArity
  | matchPatternUnsupported
  | matchConstructorUnknown (name : PsName)
  | matchDuplicateConstructor (name : PsName)
  | matchNonExhaustive
  | matchRecursorUnsupported
  | matchRecursorLevels
  | matchConstructorArity (name : PsName)
  | matchRecursiveFieldUnsupported (name : PsName)
  | duplicateDeclaration (name : PsName)
  | unresolvedMetavariable

structure PsElabTermResult where
  context : PsElabContext
  term : PsExpr
  type : PsExpr

def psSyntaxNameAppendSegments : PsName -> List String -> PsName
  | name, [] => name
  | name, segment :: rest =>
      psSyntaxNameAppendSegments
        (psNameAppendStr name segment)
        rest

def psSyntaxNameToName (name : PsSyntaxName) : Option PsName :=
  match name.segments with
  | [] => none
  | first :: rest =>
      some
        (psSyntaxNameAppendSegments
          (psNameAppendStr PsName.anonymous first)
          rest)

def psElabResultWithMeta
    (result : PsElabTermResult)
    (metaContext : PsMetaContext)
    (type : PsExpr) : PsElabTermResult :=
  {
    context := psElabContextWithMeta result.context metaContext
    term := psMetaInstantiate metaContext result.term
    type := psMetaInstantiate metaContext type
  }

def psElabFinalizeExpected
    (result : PsElabTermResult)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match expected with
  | none => Except.ok result
  | some expectedType =>
      let unified :=
        psUnify
          result.context.environment
          result.context.localContext
          result.context.metaContext
          result.type
          expectedType
      if unified.success then
        Except.ok
          (psElabResultWithMeta
            result
            unified.context
            expectedType)
      else
        Except.error PsElabError.typeMismatch

def psElabResolvedTerm
    (context : PsElabContext)
    (term : PsExpr)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match psInferType
      context.environment
      context.metaContext
      context.localContext
      term with
  | Except.error error =>
      Except.error (PsElabError.infer error)
  | Except.ok type =>
      psElabFinalizeExpected
        { context := context, term := term, type := type }
        expected

def psElabReference
    (context : PsElabContext)
    (sourceName : PsSyntaxName)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match sourceName.segments with
  | ["Prop"] =>
      psElabResolvedTerm
        context
        (PsExpr.sortE PsLevel.zero)
        expected
  | ["Type"] =>
      psElabResolvedTerm
        context
        (PsExpr.sortE (PsLevel.succ PsLevel.zero))
        expected
  | _ =>
      match psSyntaxNameToName sourceName with
      | none => Except.error PsElabError.emptyName
      | some name =>
          match psResolveName context.localContext context.environment name with
          | none => Except.error (PsElabError.unknownName name)
          | some resolved =>
              match resolved with
              | .local id =>
                  psElabResolvedTerm context (PsExpr.fvar id) expected
              | .global globalName =>
                  psElabResolvedTerm
                    context
                    (PsExpr.constE globalName [])
                    expected

def psElabNatural
    (context : PsElabContext)
    (text : String)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match psParseNaturalText text with
  | none => Except.error (PsElabError.invalidNatural text)
  | some value =>
      psElabResolvedTerm
        context
        (PsExpr.lit (PsLiteral.natural value))
        expected

def psElabString
    (context : PsElabContext)
    (text : String)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match psDecodeStringLiteral text with
  | none => Except.error (PsElabError.invalidString text)
  | some value =>
      psElabResolvedTerm
        context
        (PsExpr.lit (PsLiteral.string value))
        expected

def psElabCharacter
    (context : PsElabContext)
    (text : String)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match psDecodeCharacterLiteral text with
  | none => Except.error (PsElabError.invalidCharacter text)
  | some value =>
      let term :=
        PsExpr.app
          (PsExpr.constE psCharOfNatName [])
          (PsExpr.lit (PsLiteral.natural value.toNat))
      psElabResolvedTerm context term expected

def psElabUnit
    (context : PsElabContext)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  psElabResolvedTerm
    context
    (PsExpr.constE psUnitUnitName [])
    expected

def psElabBool
    (context : PsElabContext)
    (value : Bool)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  let name := if value then psBoolTrueName else psBoolFalseName
  psElabResolvedTerm
    context
    (PsExpr.constE name [])
    expected

structure PsElabTypedBinder where
  id : Nat
  name : PsName
  type : PsExpr
  binder : PsBinderInfo

structure PsElabTypedBindersResult where
  context : PsElabContext
  bindersRev : List PsElabTypedBinder

def psElabBinderKindToCore : PsSyntaxBinderKind -> PsBinderInfo
  | .explicit => PsBinderInfo.explicit
  | .implicit => PsBinderInfo.implicit
  | .strictImplicit => PsBinderInfo.strictImplicit
  | .instanceImplicit => PsBinderInfo.instanceImplicit

def psElabTypedBindersAcc
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext) :
    List (PsSyntaxBinderHead × PsSyntaxTerm) ->
    List PsElabTypedBinder ->
    Except PsElabError PsElabTypedBindersResult
  | [], bindersRev =>
      Except.ok {
        context := context
        bindersRev := bindersRev
      }
  | (head, sourceType) :: rest, bindersRev =>
      match psSyntaxNameToName head.name with
      | none => Except.error PsElabError.emptyName
      | some name =>
          match elaborate context sourceType none with
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
                  let binder := psElabBinderKindToCore head.kind
                  let pushed :=
                    psLocalPushBinding
                      typeResult.context.localContext
                      name
                      typeResult.term
                      binder
                  let nextContext :=
                    psElabContextWithLocal
                      typeResult.context
                      pushed.context
                  psElabTypedBindersAcc
                    elaborate
                    nextContext
                    rest
                    ({
                      id := pushed.id
                      name := name
                      type := typeResult.term
                      binder := binder
                    } :: bindersRev)

def psElabTypedBinders
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext)
    (binders : List (PsSyntaxBinderHead × PsSyntaxTerm)) :
    Except PsElabError PsElabTypedBindersResult :=
  psElabTypedBindersAcc elaborate context binders []

def psCloseElabTypedBinders
    (metaContext : PsMetaContext) :
    List PsElabTypedBinder ->
    PsExpr ->
    PsExpr ->
    (PsExpr × PsExpr)
  | [], value, type => (value, type)
  | binder :: rest, value, type =>
      let binderType :=
        psMetaInstantiate metaContext binder.type
      let closedValue :=
        PsExpr.lam
          binder.name
          binderType
          (psExprAbstractFVar binder.id value)
          binder.binder
      let closedType :=
        PsExpr.forallE
          binder.name
          binderType
          (psExprAbstractFVar binder.id type)
          binder.binder
      psCloseElabTypedBinders
        metaContext
        rest
        closedValue
        closedType

def psElabLambda
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext)
    (binders : List (PsSyntaxBinderHead × PsSyntaxTerm))
    (body : PsSyntaxTerm)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match psElabTypedBinders elaborate context binders with
  | Except.error error => Except.error error
  | Except.ok binderResult =>
      match elaborate binderResult.context body none with
      | Except.error error => Except.error error
      | Except.ok bodyResult =>
          let metaContext := bodyResult.context.metaContext
          let openTerm :=
            psMetaInstantiate metaContext bodyResult.term
          let openType :=
            psMetaInstantiate metaContext bodyResult.type
          let closed :=
            psCloseElabTypedBinders
              metaContext
              binderResult.bindersRev
              openTerm
              openType
          let outerContext :=
            psElabContextWithMeta context metaContext
          psElabFinalizeExpected
            {
              context := outerContext
              term := closed.1
              type := closed.2
            }
            expected

def psCloseElabForallBinders
    (metaContext : PsMetaContext) :
    List PsElabTypedBinder ->
    PsExpr ->
    PsExpr
  | [], body => body
  | binder :: rest, body =>
      let binderType :=
        psMetaInstantiate metaContext binder.type
      let closedBody :=
        PsExpr.forallE
          binder.name
          binderType
          (psExprAbstractFVar binder.id body)
          binder.binder
      psCloseElabForallBinders
        metaContext
        rest
        closedBody

def psElabForall
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext)
    (binders : List (PsSyntaxBinderHead × PsSyntaxTerm))
    (body : PsSyntaxTerm)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match psElabTypedBinders elaborate context binders with
  | Except.error error => Except.error error
  | Except.ok binderResult =>
      match elaborate binderResult.context body none with
      | Except.error error => Except.error error
      | Except.ok bodyResult =>
          match psInferEnsureSort
              bodyResult.context.environment
              bodyResult.context.metaContext
              bodyResult.context.localContext
              bodyResult.type with
          | Except.error error =>
              Except.error (PsElabError.infer error)
          | Except.ok _ =>
              let metaContext := bodyResult.context.metaContext
              let openBody :=
                psMetaInstantiate metaContext bodyResult.term
              let closed :=
                psCloseElabForallBinders
                  metaContext
                  binderResult.bindersRev
                  openBody
              let outerContext :=
                psElabContextWithMeta context metaContext
              psElabResolvedTerm
                outerContext
                closed
                expected

def psElabLetAfterValue
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (outerContext : PsElabContext)
    (name : PsName)
    (bindingType : PsExpr)
    (valueResult : PsElabTermResult)
    (body : PsSyntaxTerm)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  let pushed :=
    psLocalPushLet
      valueResult.context.localContext
      name
      bindingType
      valueResult.term
  let bodyContext :=
    psElabContextWithLocal
      valueResult.context
      pushed.context
  match elaborate bodyContext body expected with
  | Except.error error => Except.error error
  | Except.ok bodyResult =>
      let metaContext := bodyResult.context.metaContext
      let closedBindingType :=
        psMetaInstantiate metaContext bindingType
      let closedValue :=
        psMetaInstantiate metaContext valueResult.term
      let openBody :=
        psMetaInstantiate metaContext bodyResult.term
      let closedBody :=
        psExprAbstractFVar pushed.id openBody
      let term :=
        PsExpr.letE
          name
          closedBindingType
          closedValue
          closedBody
      let restoredContext :=
        psElabContextWithMeta outerContext metaContext
      psElabResolvedTerm
        restoredContext
        term
        expected

def psElabLet
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext)
    (nameSyntax : PsSyntaxName)
    (declaredType : Option PsSyntaxTerm)
    (value : PsSyntaxTerm)
    (body : PsSyntaxTerm)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match psSyntaxNameToName nameSyntax with
  | none => Except.error PsElabError.emptyName
  | some name =>
      match declaredType with
      | none =>
          match elaborate context value none with
          | Except.error error => Except.error error
          | Except.ok valueResult =>
              psElabLetAfterValue
                elaborate
                context
                name
                valueResult.type
                valueResult
                body
                expected
      | some sourceType =>
          match elaborate context sourceType none with
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
                  match elaborate
                      typeResult.context
                      value
                      (some typeResult.term) with
                  | Except.error error => Except.error error
                  | Except.ok valueResult =>
                      psElabLetAfterValue
                        elaborate
                        context
                        name
                        typeResult.term
                        valueResult
                        body
                        expected

def psExprApplyMany : PsExpr -> List PsExpr -> PsExpr
  | fn, [] => fn
  | fn, argument :: rest =>
      psExprApplyMany (PsExpr.app fn argument) rest

def psElabIf
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext)
    (condition : PsSyntaxTerm)
    (thenBranch : PsSyntaxTerm)
    (elseBranch : PsSyntaxTerm)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  let boolType := PsExpr.constE psBoolName []
  match elaborate context condition (some boolType) with
  | Except.error error => Except.error error
  | Except.ok conditionResult =>
      let trueTerm := PsExpr.constE psBoolTrueName []
      let conditionProp :=
        psExprApplyMany
          (PsExpr.constE
            psEqName
            [PsLevel.succ PsLevel.zero])
          [boolType, conditionResult.term, trueTerm]
      let decider :=
        psExprApplyMany
          (PsExpr.constE psBoolDecEqName [])
          [conditionResult.term, trueTerm]
      match elaborate
          conditionResult.context
          thenBranch
          expected with
      | Except.error error => Except.error error
      | Except.ok thenResult =>
          let resultType :=
            match expected with
            | some type => type
            | none => thenResult.type
          match elaborate
              thenResult.context
              elseBranch
              (some resultType) with
          | Except.error error => Except.error error
          | Except.ok elseResult =>
              let metaContext := elseResult.context.metaContext
              let instantiatedType :=
                psMetaInstantiate metaContext resultType
              match psInferType
                  elseResult.context.environment
                  metaContext
                  elseResult.context.localContext
                  instantiatedType with
              | Except.error error =>
                  Except.error (PsElabError.infer error)
              | Except.ok typeType =>
                  match psInferEnsureSort
                      elseResult.context.environment
                      metaContext
                      elseResult.context.localContext
                      typeType with
                  | Except.error error =>
                      Except.error (PsElabError.infer error)
                  | Except.ok universeLevel =>
                      let term :=
                        psExprApplyMany
                          (PsExpr.constE psIteName [universeLevel])
                          [
                            instantiatedType,
                            psMetaInstantiate metaContext conditionProp,
                            psMetaInstantiate metaContext decider,
                            psMetaInstantiate metaContext thenResult.term,
                            psMetaInstantiate metaContext elseResult.term
                          ]
                      let restoredContext :=
                        psElabContextWithMeta context metaContext
                      psElabResolvedTerm
                        restoredContext
                        term
                        expected

structure PsExprAppView where
  head : PsExpr
  args : List PsExpr

def psExprAppViewAcc
    (expr : PsExpr)
    (args : List PsExpr) : PsExprAppView :=
  match expr with
  | .app fn argument =>
      psExprAppViewAcc fn (argument :: args)
  | _ => {
      head := expr
      args := args
    }

def psExprAppView (expr : PsExpr) : PsExprAppView :=
  psExprAppViewAcc expr []

def psExprHasConst (target : PsName) : PsExpr -> Bool
  | .constE name _ => psNameEq name target
  | .app fn argument =>
      psExprHasConst target fn || psExprHasConst target argument
  | .lam _ type body _ =>
      psExprHasConst target type || psExprHasConst target body
  | .forallE _ type body _ =>
      psExprHasConst target type || psExprHasConst target body
  | .letE _ type value body =>
      psExprHasConst target type
        || psExprHasConst target value
        || psExprHasConst target body
  | .proj _ _ value => psExprHasConst target value
  | _ => false

def psMatchNameListContains (names : List PsName) (target : PsName) : Bool :=
  names.any (fun name => psNameEq name target)

structure PsElabMatchAlternative where
  constructorName : PsName
  pattern : PsSyntaxPattern
  body : PsSyntaxTerm
  span : PsSourceSpan

def psElabMatchAlternativeFind
    (name : PsName) :
    List PsElabMatchAlternative -> Option PsElabMatchAlternative
  | [] => none
  | alternative :: rest =>
      if psNameEq alternative.constructorName name then
        some alternative
      else
        psElabMatchAlternativeFind name rest

def psElabMatchPatternConstructorName
    (inductiveName : PsName)
    (pattern : PsSyntaxPattern) :
    Except PsElabError PsName :=
  match pattern with
  | .bool value _ =>
      if psNameEq inductiveName psBoolName then
        Except.ok (if value then psBoolTrueName else psBoolFalseName)
      else
        Except.error PsElabError.matchPatternUnsupported
  | .wildcard _ =>
      Except.error PsElabError.matchPatternUnsupported
  | .constructor syntaxName _ _ =>
      match syntaxName.segments with
      | [] => Except.error PsElabError.matchPatternUnsupported
      | [segment] =>
          Except.ok (psNameAppendStr inductiveName segment)
      | _ =>
          match psSyntaxNameToName syntaxName with
          | none => Except.error PsElabError.matchPatternUnsupported
          | some name => Except.ok name

def psElabPrepareMatchAlternatives
    (inductiveInfo : PsInductiveInfo) :
    List (PsSyntaxPattern × PsSyntaxTerm × PsSourceSpan) ->
    List PsElabMatchAlternative ->
    Except PsElabError (List PsElabMatchAlternative)
  | [], alternativesRev =>
      let alternatives := alternativesRev.reverse
      let exhaustive :=
        inductiveInfo.constructors.all
          (fun ctorName =>
            match psElabMatchAlternativeFind ctorName alternatives with
            | some _ => true
            | none => false)
      if exhaustive then
        Except.ok alternatives
      else
        Except.error PsElabError.matchNonExhaustive
  | (pattern, body, span) :: rest, alternativesRev =>
      match psElabMatchPatternConstructorName
          inductiveInfo.name
          pattern with
      | Except.error error => Except.error error
      | Except.ok ctorName =>
          if !psMatchNameListContains inductiveInfo.constructors ctorName then
            Except.error (PsElabError.matchConstructorUnknown ctorName)
          else
            match psElabMatchAlternativeFind ctorName alternativesRev with
            | some _ =>
                Except.error
                  (PsElabError.matchDuplicateConstructor ctorName)
            | none =>
                psElabPrepareMatchAlternatives
                  inductiveInfo
                  rest
                  ({
                    constructorName := ctorName
                    pattern := pattern
                    body := body
                    span := span
                  } :: alternativesRev)

structure PsElabMatchField where
  id : Nat
  name : PsName
  type : PsExpr
  binder : PsBinderInfo

structure PsElabMatchFieldsResult where
  context : PsElabContext
  fieldsRev : List PsElabMatchField

def psElabMatchApplyParameters
    (context : PsElabContext) :
    List PsExpr -> PsExpr -> Except PsElabError PsExpr
  | [], cursor => Except.ok cursor
  | parameter :: rest, cursor =>
      match psInferEnsureForall
          context.environment
          context.metaContext
          context.localContext
          cursor with
      | Except.error error =>
          Except.error (PsElabError.infer error)
      | Except.ok forallView =>
          psElabMatchApplyParameters
            context
            rest
            (psExprInstantiate1 forallView.body parameter)

def psSyntaxNameListHasDuplicate : List PsSyntaxName -> Bool
  | [] => false
  | name :: rest =>
      let coreName := psSyntaxNameToName name
      let duplicated :=
        rest.any
          (fun candidate =>
            match coreName, psSyntaxNameToName candidate with
            | some left, some right => psNameEq left right
            | _, _ => false)
      duplicated || psSyntaxNameListHasDuplicate rest

def psElabMatchFields
    (context : PsElabContext)
    (inductiveName : PsName) :
    PsExpr ->
    List PsSyntaxName ->
    List PsElabMatchField ->
    Except PsElabError PsElabMatchFieldsResult
  | cursor, [], fieldsRev =>
      Except.ok {
        context := context
        fieldsRev := fieldsRev
      }
  | cursor, binderSyntax :: rest, fieldsRev =>
      match psInferEnsureForall
          context.environment
          context.metaContext
          context.localContext
          cursor with
      | Except.error error =>
          Except.error (PsElabError.infer error)
      | Except.ok forallView =>
          let fieldType :=
            psWhnf
              context.environment
              context.metaContext
              context.localContext
              forallView.domain
          if psExprHasConst inductiveName fieldType then
            Except.error
              (PsElabError.matchRecursiveFieldUnsupported inductiveName)
          else
            match psSyntaxNameToName binderSyntax with
            | none => Except.error PsElabError.emptyName
            | some binderName =>
                let pushed :=
                  psLocalPushBinding
                    context.localContext
                    binderName
                    forallView.domain
                    forallView.binder
                let nextContext :=
                  psElabContextWithLocal context pushed.context
                psElabMatchFields
                  nextContext
                  inductiveName
                  (psExprInstantiate1
                    forallView.body
                    (PsExpr.fvar pushed.id))
                  rest
                  ({
                    id := pushed.id
                    name := binderName
                    type := forallView.domain
                    binder := forallView.binder
                  } :: fieldsRev)

def psCloseElabMatchFields
    (metaContext : PsMetaContext) :
    List PsElabMatchField -> PsExpr -> PsExpr
  | [], term => term
  | field :: rest, term =>
      let closed :=
        PsExpr.lam
          field.name
          (psMetaInstantiate metaContext field.type)
          (psExprAbstractFVar field.id term)
          field.binder
      psCloseElabMatchFields metaContext rest closed

structure PsElabMatchMinorResult where
  context : PsElabContext
  term : PsExpr

def psElabMatchMinor
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext)
    (inductiveInfo : PsInductiveInfo)
    (inductiveLevels : List PsLevel)
    (parameterArgs : List PsExpr)
    (expectedType : PsExpr)
    (alternative : PsElabMatchAlternative) :
    Except PsElabError PsElabMatchMinorResult :=
  match alternative.pattern with
  | .bool _ _ =>
      match elaborate context alternative.body (some expectedType) with
      | Except.error error => Except.error error
      | Except.ok bodyResult =>
          Except.ok {
            context := bodyResult.context
            term := bodyResult.term
          }
  | .wildcard _ =>
      Except.error PsElabError.matchPatternUnsupported
  | .constructor _ binders _ =>
      match psEnvironmentFindConstructor
          context.environment
          alternative.constructorName with
      | none =>
          Except.error
            (PsElabError.matchConstructorUnknown
              alternative.constructorName)
      | some ctorInfo =>
          if !psNameEq ctorInfo.inductiveName inductiveInfo.name then
            Except.error
              (PsElabError.matchConstructorUnknown
                alternative.constructorName)
          else if ctorInfo.numParams != parameterArgs.length then
            Except.error PsElabError.matchParameterArity
          else if ctorInfo.numFields != binders.length then
            Except.error
              (PsElabError.matchConstructorArity
                alternative.constructorName)
          else if psSyntaxNameListHasDuplicate binders then
            Except.error
              (PsElabError.matchConstructorArity
                alternative.constructorName)
          else if ctorInfo.levelParams.length != inductiveLevels.length then
            Except.error PsElabError.matchRecursorLevels
          else
            let ctorType :=
              psExprInstantiateLevelParams
                ctorInfo.levelParams
                inductiveLevels
                ctorInfo.type
            match psElabMatchApplyParameters
                context
                parameterArgs
                ctorType with
            | Except.error error => Except.error error
            | Except.ok fieldCursor =>
                match psElabMatchFields
                    context
                    inductiveInfo.name
                    fieldCursor
                    binders
                    [] with
                | Except.error error => Except.error error
                | Except.ok fieldResult =>
                    match elaborate
                        fieldResult.context
                        alternative.body
                        (some expectedType) with
                    | Except.error error => Except.error error
                    | Except.ok bodyResult =>
                        let metaContext := bodyResult.context.metaContext
                        let closed :=
                          psCloseElabMatchFields
                            metaContext
                            fieldResult.fieldsRev
                            (psMetaInstantiate
                              metaContext
                              bodyResult.term)
                        Except.ok {
                          context :=
                            psElabContextWithMeta
                              context
                              metaContext
                          term := closed
                        }

structure PsElabMatchMinorsResult where
  context : PsElabContext
  minors : List PsExpr

def psElabMatchMinors
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (inductiveInfo : PsInductiveInfo)
    (inductiveLevels : List PsLevel)
    (parameterArgs : List PsExpr)
    (expectedType : PsExpr)
    (alternatives : List PsElabMatchAlternative) :
    PsElabContext ->
    List PsName ->
    Except PsElabError PsElabMatchMinorsResult
  | context, [] =>
      Except.ok {
        context := context
        minors := []
      }
  | context, ctorName :: rest =>
      match psElabMatchAlternativeFind ctorName alternatives with
      | none => Except.error PsElabError.matchNonExhaustive
      | some alternative =>
          match psElabMatchMinor
              elaborate
              context
              inductiveInfo
              inductiveLevels
              parameterArgs
              expectedType
              alternative with
          | Except.error error => Except.error error
          | Except.ok minor =>
              match psElabMatchMinors
                  elaborate
                  inductiveInfo
                  inductiveLevels
                  parameterArgs
                  expectedType
                  alternatives
                  minor.context
                  rest with
              | Except.error error => Except.error error
              | Except.ok tail =>
                  Except.ok {
                    context := tail.context
                    minors := minor.term :: tail.minors
                  }

def psElabMatch
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext)
    (scrutineeSyntax : PsSyntaxTerm)
    (alternativesSyntax :
      List (PsSyntaxPattern × PsSyntaxTerm × PsSourceSpan))
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match expected with
  | none => Except.error PsElabError.matchExpectedType
  | some expectedType =>
      match elaborate context scrutineeSyntax none with
      | Except.error error => Except.error error
      | Except.ok scrutineeResult =>
          let scrutineeType :=
            psWhnf
              scrutineeResult.context.environment
              scrutineeResult.context.metaContext
              scrutineeResult.context.localContext
              scrutineeResult.type
          let typeView := psExprAppView scrutineeType
          match typeView.head with
          | .constE inductiveName inductiveLevels =>
              match psEnvironmentFindInductive
                  scrutineeResult.context.environment
                  inductiveName with
              | none =>
                  Except.error PsElabError.matchScrutineeUnsupported
              | some inductiveInfo =>
                  if inductiveInfo.numIndices != 0 then
                    Except.error PsElabError.matchInductiveUnsupported
                  else if typeView.args.length != inductiveInfo.numParams then
                    Except.error PsElabError.matchParameterArity
                  else
                    match psElabPrepareMatchAlternatives
                        inductiveInfo
                        alternativesSyntax
                        [] with
                    | Except.error error => Except.error error
                    | Except.ok alternatives =>
                        let recursorName :=
                          psNameAppendStr inductiveInfo.name "rec"
                        match psEnvironmentFindRecursor
                            scrutineeResult.context.environment
                            recursorName with
                        | none =>
                            Except.error PsElabError.matchRecursorUnsupported
                        | some recInfo =>
                            if recInfo.numParams != inductiveInfo.numParams
                                || recInfo.numIndices != 0
                                || recInfo.numMotives != 1
                                || recInfo.numMinors
                                  != inductiveInfo.constructors.length then
                              Except.error
                                PsElabError.matchRecursorUnsupported
                            else
                              let instantiatedExpected :=
                                psMetaInstantiate
                                  scrutineeResult.context.metaContext
                                  expectedType
                              match psInferType
                                  scrutineeResult.context.environment
                                  scrutineeResult.context.metaContext
                                  scrutineeResult.context.localContext
                                  instantiatedExpected with
                              | Except.error error =>
                                  Except.error (PsElabError.infer error)
                              | Except.ok expectedTypeType =>
                                  match psInferEnsureSort
                                      scrutineeResult.context.environment
                                      scrutineeResult.context.metaContext
                                      scrutineeResult.context.localContext
                                      expectedTypeType with
                                  | Except.error error =>
                                      Except.error (PsElabError.infer error)
                                  | Except.ok resultLevel =>
                                      let recursorLevels :=
                                        if recInfo.levelParams.length == 0 then
                                          []
                                        else if recInfo.levelParams.length == 1 then
                                          [resultLevel]
                                        else
                                          []
                                      if recInfo.levelParams.length > 1 then
                                        Except.error
                                          PsElabError.matchRecursorLevels
                                      else
                                        match psElabMatchMinors
                                            elaborate
                                            inductiveInfo
                                            inductiveLevels
                                            typeView.args
                                            instantiatedExpected
                                            alternatives
                                            scrutineeResult.context
                                            inductiveInfo.constructors with
                                        | Except.error error =>
                                            Except.error error
                                        | Except.ok minors =>
                                            let motive :=
                                              PsExpr.lam
                                                (psRootName "_match")
                                                scrutineeType
                                                instantiatedExpected
                                                PsBinderInfo.explicit
                                            let recursorTerm :=
                                              psExprApplyMany
                                                (PsExpr.constE
                                                  recursorName
                                                  recursorLevels)
                                                (typeView.args
                                                  ++ [motive]
                                                  ++ minors.minors
                                                  ++ [scrutineeResult.term])
                                            psElabResolvedTerm
                                              minors.context
                                              recursorTerm
                                              (some instantiatedExpected)
          | _ =>
              Except.error PsElabError.matchScrutineeUnsupported

def psBinderAcceptsExplicitArgument (binder : PsBinderInfo) : Bool :=
  match binder with
  | .explicit => true
  | _ => false

def psElabApplyArgs
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (current : PsElabTermResult) :
    List PsSyntaxTerm -> Except PsElabError PsElabTermResult
  | [] => Except.ok current
  | argument :: rest =>
      match psInferEnsureForall
          current.context.environment
          current.context.metaContext
          current.context.localContext
          current.type with
      | Except.error error =>
          Except.error (PsElabError.infer error)
      | Except.ok fnType =>
          if psBinderAcceptsExplicitArgument fnType.binder then
            match elaborate current.context argument (some fnType.domain) with
            | Except.error error => Except.error error
            | Except.ok elaboratedArgument =>
                let nextTerm :=
                  PsExpr.app current.term elaboratedArgument.term
                let nextType :=
                  psExprInstantiate1
                    fnType.body
                    elaboratedArgument.term
                psElabApplyArgs
                  elaborate
                  {
                    context := elaboratedArgument.context
                    term := nextTerm
                    type := nextType
                  }
                  rest
          else
            Except.error PsElabError.implicitApplicationUnsupported

def psElabTermWithFuel
    (fuel : Nat)
    (context : PsElabContext)
    (term : PsSyntaxTerm)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match fuel with
  | 0 => Except.error PsElabError.fuelExhausted
  | remaining + 1 =>
      match term with
      | .reference name =>
          psElabReference context name expected
      | .natural text _ =>
          psElabNatural context text expected
      | .string text _ =>
          psElabString context text expected
      | .character text _ =>
          psElabCharacter context text expected
      | .unit _ =>
          psElabUnit context expected
      | .bool value _ =>
          psElabBool context value expected
      | .lambda binders body _ =>
          psElabLambda
            (psElabTermWithFuel remaining)
            context
            binders
            body
            expected
      | .forallE binders body _ =>
          psElabForall
            (psElabTermWithFuel remaining)
            context
            binders
            body
            expected
      | .letE name declaredType value body _ =>
          psElabLet
            (psElabTermWithFuel remaining)
            context
            name
            declaredType
            value
            body
            expected
      | .ifE condition thenBranch elseBranch _ =>
          psElabIf
            (psElabTermWithFuel remaining)
            context
            condition
            thenBranch
            elseBranch
            expected
      | .matchE scrutinee alternatives _ =>
          psElabMatch
            (psElabTermWithFuel remaining)
            context
            scrutinee
            alternatives
            expected
      | .app fn args _ =>
          match psElabTermWithFuel remaining context fn none with
          | Except.error error => Except.error error
          | Except.ok elaboratedFn =>
              match psElabApplyArgs
                  (psElabTermWithFuel remaining)
                  elaboratedFn
                  args with
              | Except.error error => Except.error error
              | Except.ok result =>
                  psElabFinalizeExpected result expected

def psElabTerm
    (context : PsElabContext)
    (term : PsSyntaxTerm)
    (expected : Option PsExpr := none) :
    Except PsElabError PsElabTermResult :=
  psElabTermWithFuel 4096 context term expected
