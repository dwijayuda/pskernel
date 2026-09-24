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
