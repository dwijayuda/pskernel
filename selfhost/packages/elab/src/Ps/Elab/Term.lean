import Ps.Core.Abstract
import Ps.Core.Subst
import Ps.Environment.Resolve
import Ps.Meta.Infer
import Ps.Meta.SynthInstance
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
  | structuralRecursionArity
  | structuralRecursionNotDecreasing
  | structuralRecursionInvariantArgument
  | structuralRecursionInternal

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

def psElabProjectionApplyParameters
    (context : PsElabContext) :
    List PsExpr -> PsExpr -> Except PsElabError PsExpr
  | [], cursor => Except.ok cursor
  | parameter :: rest, cursor =>
      match
          psInferEnsureForall
            context.environment
            context.metaContext
            context.localContext
            cursor with
      | Except.error error =>
          Except.error (PsElabError.infer error)
      | Except.ok forallView =>
          psElabProjectionApplyParameters
            context
            rest
            (psExprInstantiate1 forallView.body parameter)

def psElabFindStructureField
    (context : PsElabContext)
    (typeName : PsName)
    (target : PsExpr)
    (fieldName : String) :
    Nat -> Nat -> PsExpr -> Except PsElabError Nat
  | _, 0, _ => Except.error PsElabError.unsupportedTerm
  | index, remaining + 1, cursor =>
      match
          psInferEnsureForall
            context.environment
            context.metaContext
            context.localContext
            cursor with
      | Except.error error =>
          Except.error (PsElabError.infer error)
      | Except.ok forallView =>
          if psNameLastComponent forallView.name == fieldName then
            Except.ok index
          else
            psElabFindStructureField
              context
              typeName
              target
              fieldName
              (index + 1)
              remaining
              (psExprInstantiate1
                forallView.body
                (PsExpr.proj typeName index target))

def psElabProjectionStep
    (context : PsElabContext)
    (current : PsElabTermResult)
    (fieldName : String) :
    Except PsElabError PsElabTermResult :=
  let reducedType :=
    psWhnf
      context.environment
      current.context.metaContext
      current.context.localContext
      current.type
  let view := psInferAppView reducedType
  match view.head with
  | .constE typeName _ =>
      match psEnvironmentFindInductive current.context.environment typeName with
      | none => Except.error PsElabError.unsupportedTerm
      | some info =>
          if
              !info.isStructure
                || info.numIndices != 0
                || view.args.length != info.numParams then
            Except.error PsElabError.unsupportedTerm
          else
            match info.constructors with
            | [constructorName] =>
                match
                    psEnvironmentFindConstructor
                      current.context.environment
                      constructorName with
                | none => Except.error PsElabError.unsupportedTerm
                | some constructorInfo =>
                    match
                        psElabProjectionApplyParameters
                          current.context
                          view.args
                          constructorInfo.type with
                    | Except.error error => Except.error error
                    | Except.ok fieldCursor =>
                        match
                            psElabFindStructureField
                              current.context
                              typeName
                              current.term
                              fieldName
                              0
                              constructorInfo.numFields
                              fieldCursor with
                        | Except.error error => Except.error error
                        | Except.ok index =>
                            psElabResolvedTerm
                              current.context
                              (PsExpr.proj
                                typeName
                                index
                                current.term)
                              none
            | _ => Except.error PsElabError.unsupportedTerm
  | _ => Except.error PsElabError.unsupportedTerm

def psElabProjectionChain
    (context : PsElabContext) :
    PsElabTermResult ->
    List String ->
    Except PsElabError PsElabTermResult
  | current, [] => Except.ok current
  | current, field :: rest =>
      match psElabProjectionStep context current field with
      | Except.error error => Except.error error
      | Except.ok projected =>
          psElabProjectionChain
            projected.context
            projected
            rest

def psElabProjectionReference
    (context : PsElabContext)
    (sourceName : PsSyntaxName)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match sourceName.segments with
  | base :: field :: rest =>
      let baseName :=
        psNameAppendStr PsName.anonymous base
      match
          psResolveName
            context.localContext
            context.environment
            baseName with
      | none => Except.error (PsElabError.unknownName baseName)
      | some resolved =>
          let baseTerm :=
            match resolved with
            | .local id => PsExpr.fvar id
            | .global name => PsExpr.constE name []
          match psElabResolvedTerm context baseTerm none with
          | Except.error error => Except.error error
          | Except.ok baseResult =>
              match
                  psElabProjectionChain
                    context
                    baseResult
                    (field :: rest) with
              | Except.error error => Except.error error
              | Except.ok projected =>
                  psElabFinalizeExpected projected expected
  | _ =>
      match psSyntaxNameToName sourceName with
      | none => Except.error PsElabError.emptyName
      | some name => Except.error (PsElabError.unknownName name)

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
          | none =>
              psElabProjectionReference context sourceName expected
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
      let natural := PsExpr.lit (PsLiteral.natural value)
      match expected with
      | some expectedType =>
          let reducedExpected :=
            psWhnf
              context.environment
              context.metaContext
              context.localContext
              expectedType
          match reducedExpected with
          | .constE name _ =>
              if psNameEq name psIntName then
                psElabResolvedTerm
                  context
                  (PsExpr.app
                    (PsExpr.constE psIntOfNatName [])
                    natural)
                  expected
              else
                psElabResolvedTerm context natural expected
          | _ =>
              psElabResolvedTerm context natural expected
      | none =>
          psElabResolvedTerm context natural none

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

def psElabLambdaExpectedBody
    (context : PsElabContext)
    (binders : List PsElabTypedBinder) :
    PsExpr ->
    Except PsElabError (Prod PsElabContext PsExpr)
  | expectedType =>
      match binders with
      | [] =>
          Except.ok
            (context,
              psMetaInstantiate
                context.metaContext
                expectedType)
      | binder :: rest =>
          match
              psInferEnsureForall
                context.environment
                context.metaContext
                context.localContext
                expectedType with
          | Except.error error =>
              Except.error (PsElabError.infer error)
          | Except.ok forallView =>
              let unified :=
                psUnify
                  context.environment
                  context.localContext
                  context.metaContext
                  binder.type
                  forallView.domain
              if !unified.success then
                Except.error PsElabError.typeMismatch
              else
                let nextContext :=
                  psElabContextWithMeta
                    context
                    unified.context
                let nextExpected :=
                  psExprInstantiate1
                    (psMetaInstantiate
                      unified.context
                      forallView.body)
                    (PsExpr.fvar binder.id)
                psElabLambdaExpectedBody
                  nextContext
                  rest
                  nextExpected

def psElabLambdaBodyExpected
    (context : PsElabContext)
    (binders : List PsElabTypedBinder)
    (expected : Option PsExpr) :
    Except
      PsElabError
      (Prod PsElabContext (Option PsExpr)) :=
  match expected with
  | none => Except.ok (context, none)
  | some expectedType =>
      match
          psElabLambdaExpectedBody
            context
            binders
            expectedType with
      | Except.error error => Except.error error
      | Except.ok prepared =>
          Except.ok (prepared.1, some prepared.2)

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
      match
          psElabLambdaBodyExpected
            binderResult.context
            binderResult.bindersRev.reverse
            expected with
      | Except.error error => Except.error error
      | Except.ok prepared =>
          match elaborate prepared.1 body prepared.2 with
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

def psElabFillWildcardAlternatives
    (pattern : PsSyntaxPattern)
    (body : PsSyntaxTerm)
    (span : PsSourceSpan) :
    List PsName ->
    List PsElabMatchAlternative ->
    List PsElabMatchAlternative
  | [], alternativesRev => alternativesRev
  | ctorName :: rest, alternativesRev =>
      let next :=
        match psElabMatchAlternativeFind ctorName alternativesRev with
        | some _ => alternativesRev
        | none =>
            {
              constructorName := ctorName
              pattern := pattern
              body := body
              span := span
            } :: alternativesRev
      psElabFillWildcardAlternatives
        pattern
        body
        span
        rest
        next

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
      match pattern with
      | .wildcard _ =>
          if rest.isEmpty then
            Except.ok
              ((psElabFillWildcardAlternatives
                pattern
                body
                span
                inductiveInfo.constructors
                alternativesRev).reverse)
          else
            Except.error PsElabError.matchPatternUnsupported
      | _ =>
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

def psElabMatchFieldAt :
    List PsElabMatchField -> Nat -> Option PsElabMatchField
  | [], _ => none
  | field :: rest, 0 => some field
  | _ :: rest, index + 1 =>
      psElabMatchFieldAt rest index

structure PsElabMatchHypothesesResult where
  context : PsElabContext
  hypothesesRev : List PsElabMatchField

def psElabPushRecursiveHypotheses
    (expectedType : PsExpr)
    (fields : List PsElabMatchField) :
    List Nat ->
    PsElabContext ->
    List PsElabMatchField ->
    Except PsElabError PsElabMatchHypothesesResult
  | [], context, hypothesesRev =>
      Except.ok {
        context := context
        hypothesesRev := hypothesesRev
      }
  | fieldIndex :: rest, context, hypothesesRev =>
      match psElabMatchFieldAt fields fieldIndex with
      | none => Except.error PsElabError.structuralRecursionInternal
      | some field =>
          let hypothesisName :=
            psNameAppendNum
              (psRootName "_ih")
              fieldIndex
          let pushed :=
            psLocalPushBinding
              context.localContext
              hypothesisName
              expectedType
              PsBinderInfo.explicit
          let withLocal :=
            psElabContextWithLocal
              context
              pushed.context
          let withRecursion :=
            match context.structuralRecursion with
            | none => withLocal
            | some recursion =>
                psElabContextWithStructuralRecursion
                  withLocal
                  (some {
                    recursion with
                    calls :=
                      (field.id, pushed.id) :: recursion.calls
                  })
          psElabPushRecursiveHypotheses
            expectedType
            fields
            rest
            withRecursion
            ({
              id := pushed.id
              name := hypothesisName
              type := expectedType
              binder := PsBinderInfo.explicit
            } :: hypothesesRev)

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

def psElabWildcardBinderNames
    (span : PsSourceSpan) :
    Nat -> Nat -> List PsSyntaxName
  | _, 0 => []
  | index, remaining + 1 =>
      {
        segments := ["_wild" ++ toString index]
        span := span
      } ::
        psElabWildcardBinderNames
          span
          (index + 1)
          remaining

def psElabMatchConstructorMinor
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
    (constructorName : PsName)
    (body : PsSyntaxTerm)
    (span : PsSourceSpan)
    (sourceBinders : Option (List PsSyntaxName)) :
    Except PsElabError PsElabMatchMinorResult :=
  match psEnvironmentFindConstructor
      context.environment
      constructorName with
  | none =>
      Except.error
        (PsElabError.matchConstructorUnknown constructorName)
  | some ctorInfo =>
      let binders :=
        match sourceBinders with
        | some values => values
        | none =>
            psElabWildcardBinderNames
              span
              0
              ctorInfo.numFields
      if !psNameEq ctorInfo.inductiveName inductiveInfo.name then
        Except.error
          (PsElabError.matchConstructorUnknown constructorName)
      else if ctorInfo.numParams != parameterArgs.length then
        Except.error PsElabError.matchParameterArity
      else if ctorInfo.numFields != binders.length then
        Except.error
          (PsElabError.matchConstructorArity constructorName)
      else if psSyntaxNameListHasDuplicate binders then
        Except.error
          (PsElabError.matchConstructorArity constructorName)
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
                let fields :=
                  fieldResult.fieldsRev.reverse
                match
                    psElabPushRecursiveHypotheses
                      expectedType
                      fields
                      ctorInfo.recursiveFields
                      fieldResult.context
                      [] with
                | Except.error error => Except.error error
                | Except.ok hypotheses =>
                    match elaborate
                        hypotheses.context
                        body
                        (some expectedType) with
                    | Except.error error => Except.error error
                    | Except.ok bodyResult =>
                        let metaContext := bodyResult.context.metaContext
                        let withHypotheses :=
                          psCloseElabMatchFields
                            metaContext
                            hypotheses.hypothesesRev
                            (psMetaInstantiate
                              metaContext
                              bodyResult.term)
                        let closed :=
                          psCloseElabMatchFields
                            metaContext
                            fieldResult.fieldsRev
                            withHypotheses
                        Except.ok {
                          context :=
                            psElabContextWithMeta
                              context
                              metaContext
                          term := closed
                        }

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
  | .wildcard span =>
      psElabMatchConstructorMinor
        elaborate
        context
        inductiveInfo
        inductiveLevels
        parameterArgs
        expectedType
        alternative.constructorName
        alternative.body
        span
        none
  | .constructor _ binders span =>
      psElabMatchConstructorMinor
        elaborate
        context
        inductiveInfo
        inductiveLevels
        parameterArgs
        expectedType
        alternative.constructorName
        alternative.body
        span
        (some binders)

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

def psBinderIsStrictImplicit (binder : PsBinderInfo) : Bool :=
  match binder with
  | .strictImplicit => true
  | _ => false

def psBinderIsInstanceImplicit (binder : PsBinderInfo) : Bool :=
  match binder with
  | .instanceImplicit => true
  | _ => false

structure PsElabApplicationResult where
  result : PsElabTermResult
  pendingInstancesRev : List Nat

def psElabApplyArgsWithFuel
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult) :
    Nat ->
    PsElabTermResult ->
    List PsSyntaxTerm ->
    List Nat ->
    Except PsElabError PsElabApplicationResult
  | 0, _, _, _ =>
      Except.error PsElabError.fuelExhausted
  | fuel + 1, current, arguments, pendingInstancesRev =>
      let currentType :=
        psWhnf
          current.context.environment
          current.context.metaContext
          current.context.localContext
          current.type
      match currentType with
      | PsExpr.forallE _ domain body binder =>
          if psBinderAcceptsExplicitArgument binder then
            match arguments with
            | [] =>
                Except.ok {
                  result := current
                  pendingInstancesRev := pendingInstancesRev
                }
            | argument :: rest =>
                match elaborate
                    current.context
                    argument
                    (some domain) with
                | Except.error error => Except.error error
                | Except.ok elaboratedArgument =>
                    let nextTerm :=
                      PsExpr.app
                        current.term
                        elaboratedArgument.term
                    let nextType :=
                      psExprInstantiate1
                        body
                        elaboratedArgument.term
                    psElabApplyArgsWithFuel
                      elaborate
                      fuel
                      {
                        context := elaboratedArgument.context
                        term := nextTerm
                        type := nextType
                      }
                      rest
                      pendingInstancesRev
          else if psBinderIsStrictImplicit binder
              && arguments.isEmpty then
            Except.ok {
              result := current
              pendingInstancesRev := pendingInstancesRev
            }
          else
            let kind :=
              if psBinderIsInstanceImplicit binder then
                PsMetaVarKind.synthetic
              else
                PsMetaVarKind.natural
            let fresh :=
              psMetaFresh
                current.context.metaContext
                current.context.localContext
                domain
                kind
            let nextContext :=
              psElabContextWithMeta
                current.context
                fresh.context
            let nextResult : PsElabTermResult := {
              context := nextContext
              term := PsExpr.app current.term fresh.expr
              type := psExprInstantiate1 body fresh.expr
            }
            let nextPending :=
              if psBinderIsInstanceImplicit binder then
                match fresh.expr with
                | PsExpr.mvar id => id :: pendingInstancesRev
                | _ => pendingInstancesRev
              else
                pendingInstancesRev
            psElabApplyArgsWithFuel
              elaborate
              fuel
              nextResult
              arguments
              nextPending
      | _ =>
          if arguments.isEmpty then
            Except.ok {
              result := current
              pendingInstancesRev := pendingInstancesRev
            }
          else
            Except.error (PsElabError.infer PsInferError.expectedFunction)


def psElabApplyArgs
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (current : PsElabTermResult)
    (arguments : List PsSyntaxTerm)
    (pendingInstancesRev : List Nat) :
    Except PsElabError PsElabApplicationResult :=
  psElabApplyArgsWithFuel
    elaborate
    4096
    current
    arguments
    pendingInstancesRev

def psElabSolvePendingInstances :
    PsElabTermResult ->
    List Nat ->
    Except PsElabError PsElabTermResult
  | current, [] =>
      let metaContext := current.context.metaContext
      Except.ok {
        context := current.context
        term := psMetaInstantiate metaContext current.term
        type := psMetaInstantiate metaContext current.type
      }
  | current, id :: rest =>
      let metaContext := current.context.metaContext
      match psMetaFindAssignment metaContext id with
      | some _ =>
          psElabSolvePendingInstances current rest
      | none =>
          match psMetaFindDecl metaContext id with
          | none =>
              Except.error PsElabError.implicitApplicationUnsupported
          | some declaration =>
              let target :=
                psMetaInstantiate metaContext declaration.type
              if psExprHasUnresolvedMeta target then
                Except.error PsElabError.implicitApplicationUnsupported
              else
                let synthesized :=
                  psSynthInstance
                    current.context.environment
                    current.context.localContext
                    current.context.instances
                    metaContext
                    target
                match synthesized.value with
                | none =>
                    Except.error PsElabError.implicitApplicationUnsupported
                | some value =>
                    match psMetaAssign
                        synthesized.context
                        id
                        value with
                    | none =>
                        Except.error
                          PsElabError.implicitApplicationUnsupported
                    | some assigned =>
                        psElabSolvePendingInstances
                          {
                            context :=
                              psElabContextWithMeta
                                current.context
                                assigned
                            term := current.term
                            type := current.type
                          }
                          rest

def psElabFinishApplication
    (application : PsElabApplicationResult)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match psElabFinalizeExpected application.result expected with
  | Except.error error => Except.error error
  | Except.ok finalized =>
      psElabSolvePendingInstances
        finalized
        application.pendingInstancesRev

structure PsElabRecordCandidate where
  constructorName : PsName
  fieldNames : List String

def psElabDropForallBinders :
    Nat -> PsExpr -> Option PsExpr
  | 0, type => some type
  | remaining + 1, type =>
      match type with
      | .forallE _ _ body _ =>
          psElabDropForallBinders remaining body
      | _ => none

def psElabTakeForallNames :
    Nat -> PsExpr -> Option (List String)
  | 0, _ => some []
  | remaining + 1, type =>
      match type with
      | .forallE name _ body _ =>
          match psElabTakeForallNames remaining body with
          | none => none
          | some rest =>
              some (psNameLastComponent name :: rest)
      | _ => none

def psSyntaxRecordFieldName
    (field : Prod PsSyntaxName PsSyntaxTerm) :
    Option String :=
  match field.1.segments.reverse with
  | [] => none
  | name :: _ => some name

def psSyntaxRecordHasField
    (fields :
      List (Prod PsSyntaxName PsSyntaxTerm))
    (name : String) : Bool :=
  fields.any
    (fun field =>
      match psSyntaxRecordFieldName field with
      | none => false
      | some fieldName => fieldName == name)

def psSyntaxRecordFieldsMatch
    (fields :
      List (Prod PsSyntaxName PsSyntaxTerm))
    (names : List String) : Bool :=
  fields.length == names.length
    && names.all
      (fun name => psSyntaxRecordHasField fields name)

def psSyntaxRecordFindField :
    List (Prod PsSyntaxName PsSyntaxTerm) ->
    String ->
    Option PsSyntaxTerm
  | [], _ => none
  | field :: rest, name =>
      match psSyntaxRecordFieldName field with
      | some fieldName =>
          if fieldName == name then
            some field.2
          else
            psSyntaxRecordFindField rest name
      | none =>
          psSyntaxRecordFindField rest name

def psSyntaxRecordOrderFields
    (fields :
      List (Prod PsSyntaxName PsSyntaxTerm)) :
    List String -> Option (List PsSyntaxTerm)
  | [] => some []
  | name :: rest =>
      match
          psSyntaxRecordFindField fields name,
          psSyntaxRecordOrderFields fields rest with
      | some value, some values =>
          some (value :: values)
      | _, _ => none

def psElabRecordCandidateForInfo
    (environment : PsEnvironment)
    (info : PsInductiveInfo) :
    Option PsElabRecordCandidate :=
  if !info.isStructure then
    none
  else
    match info.constructors with
    | [constructorName] =>
        match
            psEnvironmentFindConstructor
              environment
              constructorName with
        | none => none
        | some constructorInfo =>
            match
                psElabDropForallBinders
                  constructorInfo.numParams
                  constructorInfo.type with
            | none => none
            | some fieldsType =>
                match
                    psElabTakeForallNames
                      constructorInfo.numFields
                      fieldsType with
                | none => none
                | some fieldNames =>
                    some {
                      constructorName := constructorName
                      fieldNames := fieldNames
                    }
    | _ => none

def psElabRecordCandidateFromExpected
    (context : PsElabContext)
    (expected : PsExpr) :
    Option PsElabRecordCandidate :=
  let reduced :=
    psWhnf
      context.environment
      context.metaContext
      context.localContext
      expected
  let view := psInferAppView reduced
  match view.head with
  | .constE typeName _ =>
      match
          psEnvironmentFindInductive
            context.environment
            typeName with
      | none => none
      | some info =>
          if view.args.length != info.numParams then
            none
          else
            psElabRecordCandidateForInfo
              context.environment
              info
  | _ => none

def psElabRecordCandidates
    (environment : PsEnvironment)
    (fields :
      List (Prod PsSyntaxName PsSyntaxTerm)) :
    List PsDeclaration ->
    List PsElabRecordCandidate ->
    List PsElabRecordCandidate
  | [], candidatesRev => candidatesRev.reverse
  | declaration :: rest, candidatesRev =>
      match declaration with
      | .inductiveDecl info =>
          match
              psElabRecordCandidateForInfo
                environment
                info with
          | some candidate =>
              if
                  psSyntaxRecordFieldsMatch
                    fields
                    candidate.fieldNames then
                psElabRecordCandidates
                  environment
                  fields
                  rest
                  (candidate :: candidatesRev)
              else
                psElabRecordCandidates
                  environment
                  fields
                  rest
                  candidatesRev
          | none =>
              psElabRecordCandidates
                environment
                fields
                rest
                candidatesRev
      | _ =>
          psElabRecordCandidates
            environment
            fields
            rest
            candidatesRev

def psElabUniqueRecordCandidate
    (environment : PsEnvironment)
    (fields :
      List (Prod PsSyntaxName PsSyntaxTerm)) :
    Option PsElabRecordCandidate :=
  match
      psElabRecordCandidates
        environment
        fields
        environment.declarations
        [] with
  | [candidate] => some candidate
  | _ => none

def psElabRecord
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext)
    (fields :
      List (Prod PsSyntaxName PsSyntaxTerm))
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  let candidate :=
    match expected with
    | some expectedType =>
        match
            psElabRecordCandidateFromExpected
              context
              expectedType with
        | some found =>
            if
                psSyntaxRecordFieldsMatch
                  fields
                  found.fieldNames then
              some found
            else
              none
        | none =>
            psElabUniqueRecordCandidate
              context.environment
              fields
    | none =>
        psElabUniqueRecordCandidate
          context.environment
          fields
  match candidate with
  | none => Except.error PsElabError.unsupportedTerm
  | some found =>
      match
          psSyntaxRecordOrderFields
            fields
            found.fieldNames with
      | none => Except.error PsElabError.unsupportedTerm
      | some arguments =>
          match
              psElabResolvedTerm
                context
                (PsExpr.constE
                  found.constructorName
                  [])
                none with
          | Except.error error => Except.error error
          | Except.ok constructor =>
              match
                  psElabApplyArgs
                    elaborate
                    constructor
                    arguments
                    [] with
              | Except.error error => Except.error error
              | Except.ok application =>
                  psElabFinishApplication
                    application
                    expected

def psElabSyntaxLocalId
    (context : PsElabContext) :
    PsSyntaxTerm -> Option Nat
  | .reference sourceName =>
      match psSyntaxNameToName sourceName with
      | none => none
      | some name =>
          match
              psResolveName
                context.localContext
                context.environment
                name with
          | some (.local id) => some id
          | _ => none
  | _ => none

def psElabValidateStructuralCall
    (context : PsElabContext)
    (recursion : PsElabStructuralRecursion) :
    Nat ->
    List PsSyntaxTerm ->
    Option Nat ->
    Except PsElabError Nat
  | _, [], some hypothesisId => Except.ok hypothesisId
  | _, [], none => Except.error PsElabError.structuralRecursionInternal
  | index, argument :: rest, hypothesisId =>
      match psElabSyntaxLocalId context argument with
      | none =>
          if index == recursion.recursiveParameterIndex then
            Except.error PsElabError.structuralRecursionNotDecreasing
          else
            Except.error PsElabError.structuralRecursionInvariantArgument
      | some argumentId =>
          if index == recursion.recursiveParameterIndex then
            match
                psElabStructuralRecursionFindCall
                  recursion.calls
                  argumentId with
            | none =>
                Except.error PsElabError.structuralRecursionNotDecreasing
            | some nextHypothesisId =>
                psElabValidateStructuralCall
                  context
                  recursion
                  (index + 1)
                  rest
                  (some nextHypothesisId)
          else
            match recursion.explicitParameterIds[index]? with
            | none => Except.error PsElabError.structuralRecursionArity
            | some originalId =>
                if argumentId == originalId then
                  psElabValidateStructuralCall
                    context
                    recursion
                    (index + 1)
                    rest
                    hypothesisId
                else
                  Except.error
                    PsElabError.structuralRecursionInvariantArgument

def psTryElabStructuralSelfCall
    (context : PsElabContext)
    (fn : PsSyntaxTerm)
    (arguments : List PsSyntaxTerm)
    (expected : Option PsExpr) :
    Except PsElabError (Option PsElabTermResult) :=
  match context.structuralRecursion, fn with
  | some recursion, .reference sourceName =>
      match psSyntaxNameToName sourceName with
      | some calledName =>
          if !psNameEq calledName recursion.functionName then
            Except.ok none
          else if
              arguments.length != recursion.explicitParameterIds.length then
            Except.error PsElabError.structuralRecursionArity
          else
            match
                psElabValidateStructuralCall
                  context
                  recursion
                  0
                  arguments
                  none with
            | Except.error error => Except.error error
            | Except.ok hypothesisId =>
                match
                    psElabResolvedTerm
                      context
                      (PsExpr.fvar hypothesisId)
                      expected with
                | Except.error error => Except.error error
                | Except.ok result => Except.ok (some result)
      | none => Except.ok none
  | _, _ => Except.ok none

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
          match psElabReference context name none with
          | Except.error error => Except.error error
          | Except.ok reference =>
              match psElabApplyArgs
                  (psElabTermWithFuel remaining)
                  reference
                  []
                  [] with
              | Except.error error => Except.error error
              | Except.ok application =>
                  psElabFinishApplication application expected
      | .natural text _ =>
          psElabNatural context text expected
      | .string text _ =>
          psElabString context text expected
      | .character text _ =>
          psElabCharacter context text expected
      | .unit _ =>
          psElabUnit context expected
      | .record fields _ =>
          psElabRecord
            (psElabTermWithFuel remaining)
            context
            fields
            expected
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
          match
              psTryElabStructuralSelfCall
                context
                fn
                args
                expected with
          | Except.error error => Except.error error
          | Except.ok (some result) => Except.ok result
          | Except.ok none =>
              match psElabTermWithFuel remaining context fn none with
              | Except.error error => Except.error error
              | Except.ok elaboratedFn =>
                  match psElabApplyArgs
                      (psElabTermWithFuel remaining)
                      elaboratedFn
                      args
                      [] with
                  | Except.error error => Except.error error
                  | Except.ok application =>
                      psElabFinishApplication application expected

def psElabTerm
    (context : PsElabContext)
    (term : PsSyntaxTerm)
    (expected : Option PsExpr := none) :
    Except PsElabError PsElabTermResult :=
  psElabTermWithFuel 4096 context term expected
