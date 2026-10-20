import Ps.Core.Abstract
import Ps.Core.Subst
import Ps.Meta.Infer
import Ps.Meta.Unify
import Ps.Syntax.Ast
import Ps.Elab.Context

-- Shared checked term results and scope closing. Control elaborators depend on
-- these callbacks, never on the term dispatch or a second lowering pipeline.

inductive PsElabError where
  | fuelExhausted
  | emptyName
  | doExpectedType
  | doUnsupportedEffect
  | doStatementOutsideBlock
  | unknownName (name : PsName)
  | invalidNatural (text : String)
  | invalidString (text : String)
  | invalidCharacter (text : String)
  | infer (error : PsInferError)
  | typeMismatch
  | implicitApplicationUnsupported
  | emptyCallUnsupported
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
  | structuralRecursionDependentParameter
  | structuralRecursionEscapingReference

structure PsElabTermResult where
  context : PsElabContext
  term : PsExpr
  type : PsExpr

def psSyntaxNameAppendSegments
    (segments : List String) :
    PsName -> PsName :=
  match segments with
  | [] =>
      fun (name : PsName) =>
        name
  | segment :: rest =>
      let smaller : PsName -> PsName :=
        psSyntaxNameAppendSegments rest;
      fun (name : PsName) =>
        smaller (psNameAppendStr name segment)

def psSyntaxNameToName (name : PsSyntaxName) : Option PsName :=
  match name.segments with
  | [] => Option.none
  | first :: rest =>
      Option.some
        (psSyntaxNameAppendSegments
          rest
          (psNameAppendStr PsName.anonymous first))

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
          expectedType;
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
      let result :=
        PsElabTermResult.mk
          context
          term
          type;
      psElabFinalizeExpected
        result
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
      valueResult.term;
  let bodyContext :=
    psElabContextWithLocal
      valueResult.context
      pushed.context;
  match elaborate bodyContext body expected with
  | Except.error error => Except.error error
  | Except.ok bodyResult =>
      let metaContext := bodyResult.context.metaContext;
      let closedBindingType :=
        psMetaInstantiate metaContext bindingType;
      let closedValue :=
        psMetaInstantiate metaContext valueResult.term;
      let openBody :=
        psMetaInstantiate metaContext bodyResult.term;
      let closedBody :=
        psExprAbstractFVar pushed.id openBody;
      let term :=
        PsExpr.letE
          name
          closedBindingType
          closedValue
          closedBody;
      let restoredContext :=
        psElabContextWithMeta outerContext metaContext;
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
          match elaborate context value Option.none with
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
          match elaborate context sourceType Option.none with
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
                      (Option.some typeResult.term) with
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

def psExprApplyManyWorker
    (arguments : List PsExpr)
    (fn : PsExpr) : PsExpr :=
  match arguments with
  | [] => fn
  | argument :: rest =>
      psExprApplyManyWorker rest (PsExpr.app fn argument)

def psExprApplyMany
    (fn : PsExpr)
    (arguments : List PsExpr) :
    PsExpr :=
  psExprApplyManyWorker arguments fn

structure PsExprAppView where
  head : PsExpr
  args : List PsExpr

def psExprAppViewAccWorker
    (expr : PsExpr)
    (args : List PsExpr) : PsExprAppView :=
  match expr with
  | .app fn argument =>
      psExprAppViewAccWorker fn (List.cons argument args)
  | _ =>
      {
        head := expr
        args := args
      }

def psExprAppViewAcc
    (expr : PsExpr)
    (args : List PsExpr) : PsExprAppView :=
  psExprAppViewAccWorker expr args

def psExprAppView (expr : PsExpr) : PsExprAppView :=
  psExprAppViewAcc expr []

