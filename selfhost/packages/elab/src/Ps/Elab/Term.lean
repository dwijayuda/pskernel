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
  | infer (error : PsInferError)
  | typeMismatch
  | implicitApplicationUnsupported
  | unsupportedTerm
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
      | _ => Except.error PsElabError.unsupportedTerm

def psElabTerm
    (context : PsElabContext)
    (term : PsSyntaxTerm)
    (expected : Option PsExpr := none) :
    Except PsElabError PsElabTermResult :=
  psElabTermWithFuel 4096 context term expected
