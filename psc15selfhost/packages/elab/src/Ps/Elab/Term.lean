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

def psElabBoolNot (value : Bool) : Bool :=
  if value then false else true

def psElabBoolOr (left right : Bool) : Bool :=
  if left then true else right

def psElabBoolAnd (left right : Bool) : Bool :=
  if left then right else false

def psElabNatNe (left right : Nat) : Bool :=
  if Nat.beq left right then false else true

def psElabListLength {α : Type}
    (values : List α) : Nat :=
  match values with
  | [] => 0
  | _ :: rest => Nat.succ (psElabListLength rest)

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

def psElabProjectionApplyParameters
    (context : PsElabContext)
    (parameters : List PsExpr) :
    PsExpr ->
    Except PsElabError PsExpr :=
  match parameters with
  | [] =>
      fun (cursor : PsExpr) =>
        Except.ok cursor
  | parameter :: rest =>
      let smaller : PsExpr -> Except PsElabError PsExpr :=
        psElabProjectionApplyParameters context rest;
      fun (cursor : PsExpr) =>
        match
            psInferEnsureForall
              context.environment
              context.metaContext
              context.localContext
              cursor with
        | Except.error error =>
            Except.error (PsElabError.infer error)
        | Except.ok forallView =>
            smaller
              (psExprInstantiate1 forallView.body parameter)

def psElabFindStructureField
    (context : PsElabContext)
    (typeName : PsName)
    (target : PsExpr)
    (fieldName : String)
    (remaining : Nat) :
    Nat ->
    PsExpr ->
    Except PsElabError Nat :=
  match remaining with
  | 0 =>
      fun (_index : Nat) =>
        fun (_cursor : PsExpr) =>
          Except.error PsElabError.unsupportedTerm
  | nextRemaining + 1 =>
      let smaller : Nat -> PsExpr -> Except PsElabError Nat :=
        psElabFindStructureField
          context
          typeName
          target
          fieldName
          nextRemaining;
      fun (index : Nat) =>
        fun (cursor : PsExpr) =>
          match
              psInferEnsureForall
                context.environment
                context.metaContext
                context.localContext
                cursor with
          | Except.error error =>
              Except.error (PsElabError.infer error)
          | Except.ok forallView =>
              if
                  psStringEq
                    (psNameLastComponent forallView.name)
                    fieldName then
                Except.ok index
              else
                smaller
                  (Nat.succ index)
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
      current.type;
  let view := psInferAppView reducedType;
  match view.head with
  | .constE typeName _ =>
      match psEnvironmentFindInductive current.context.environment typeName with
      | none => Except.error PsElabError.unsupportedTerm
      | some info =>
          let projectionInvalid :=
            if info.isStructure then
              if Nat.beq info.numIndices 0 then
                if Nat.beq (psElabListLength view.args) info.numParams then
                  false
                else
                  true
              else
                true
            else
              true;
          if projectionInvalid then
            Except.error PsElabError.unsupportedTerm
          else
            match info.constructors with
            | List.nil =>
                Except.error PsElabError.unsupportedTerm
            | List.cons constructorName remainingConstructors =>
                match remainingConstructors with
                | List.nil =>
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
                                  constructorInfo.numFields
                                  0
                                  fieldCursor with
                            | Except.error error => Except.error error
                            | Except.ok index =>
                                psElabResolvedTerm
                                  current.context
                                  (PsExpr.proj
                                    typeName
                                    index
                                    current.term)
                                  Option.none
                | List.cons _ _ =>
                    Except.error PsElabError.unsupportedTerm
  | _ => Except.error PsElabError.unsupportedTerm

def psElabProjectionChainWorker
    (fields : List String) :
    PsElabContext ->
    PsElabTermResult ->
    Except PsElabError PsElabTermResult :=
  match fields with
  | [] =>
      fun (_context : PsElabContext) =>
        fun (current : PsElabTermResult) =>
          Except.ok current
  | field :: rest =>
      let smaller : PsElabContext -> PsElabTermResult -> Except PsElabError PsElabTermResult :=
        psElabProjectionChainWorker rest;
      fun (context : PsElabContext) =>
        fun (current : PsElabTermResult) =>
          match psElabProjectionStep context current field with
          | Except.error error => Except.error error
          | Except.ok projected =>
              smaller projected.context projected

def psElabProjectionChain
    (context : PsElabContext)
    (current : PsElabTermResult)
    (fields : List String) :
    Except PsElabError PsElabTermResult :=
  psElabProjectionChainWorker fields context current

def psElabProjectionReference
    (context : PsElabContext)
    (sourceName : PsSyntaxName)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match sourceName.segments with
  | List.nil =>
      match psSyntaxNameToName sourceName with
      | none => Except.error PsElabError.emptyName
      | some name => Except.error (PsElabError.unknownName name)
  | List.cons base tail =>
      match tail with
      | List.nil =>
          match psSyntaxNameToName sourceName with
          | none => Except.error PsElabError.emptyName
          | some name => Except.error (PsElabError.unknownName name)
      | List.cons field rest =>
          let baseName :=
            psNameAppendStr PsName.anonymous base;
          match
              psResolveName
                context.localContext
                context.environment
                baseName with
          | none => Except.error (PsElabError.unknownName baseName)
          | some resolved =>
              let baseTerm : PsExpr :=
                match resolved with
                | .local id => PsExpr.fvar id
                | .global name => PsExpr.constE name [];
              match psElabResolvedTerm context baseTerm Option.none with
              | Except.error error => Except.error error
              | Except.ok baseResult =>
                  match
                      psElabProjectionChain
                        context
                        baseResult
                        (List.cons field rest) with
                  | Except.error error => Except.error error
                  | Except.ok projected =>
                      psElabFinalizeExpected projected expected

def psElabNamedReference
    (context : PsElabContext)
    (sourceName : PsSyntaxName)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
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

def psElabReference
    (context : PsElabContext)
    (sourceName : PsSyntaxName)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match sourceName.segments with
  | List.nil =>
      psElabNamedReference context sourceName expected
  | List.cons segment rest =>
      match rest with
      | List.nil =>
          if psStringEq segment "Prop" then
            psElabResolvedTerm
              context
              (PsExpr.sortE PsLevel.zero)
              expected
          else if psStringEq segment "Type" then
            psElabResolvedTerm
              context
              (PsExpr.sortE (PsLevel.succ PsLevel.zero))
              expected
          else
            psElabNamedReference context sourceName expected
      | List.cons _ _ =>
          psElabNamedReference context sourceName expected

def psElabNatural
    (context : PsElabContext)
    (text : String)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match psParseNaturalText text with
  | none => Except.error (PsElabError.invalidNatural text)
  | some value =>
      let natural := PsExpr.lit (PsLiteral.natural value);
      match expected with
      | some expectedType =>
          let reducedExpected :=
            psWhnf
              context.environment
              context.metaContext
              context.localContext
              expectedType;
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
          psElabResolvedTerm context natural Option.none

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
          (PsExpr.lit (PsLiteral.natural (Char.toNat value)));
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
  if value then
    psElabResolvedTerm
      context
      (PsExpr.constE psBoolTrueName [])
      expected
  else
    psElabResolvedTerm
      context
      (PsExpr.constE psBoolFalseName [])
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
    (entries : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) :
    PsElabContext ->
    List PsElabTypedBinder ->
    Except PsElabError PsElabTypedBindersResult :=
  match entries with
  | [] =>
      fun (context : PsElabContext) =>
        fun (bindersRev : List PsElabTypedBinder) =>
          Except.ok {
            context := context
            bindersRev := bindersRev
          }
  | List.cons entry rest =>
      let smaller :
          PsElabContext ->
          List PsElabTypedBinder ->
          Except PsElabError PsElabTypedBindersResult :=
        psElabTypedBindersAcc elaborate rest;
      fun (context : PsElabContext) =>
        fun (bindersRev : List PsElabTypedBinder) =>
          let head := Prod.fst entry;
          let sourceType := Prod.snd entry;
          match psSyntaxNameToName head.name with
          | none => Except.error PsElabError.emptyName
          | some name =>
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
                      let binder := psElabBinderKindToCore head.kind;
                      let pushed :=
                        psLocalPushBinding
                          typeResult.context.localContext
                          name
                          typeResult.term
                          binder;
                      let nextContext :=
                        psElabContextWithLocal
                          typeResult.context
                          pushed.context;
                      let binderEntry : PsElabTypedBinder := {
                        id := pushed.id
                        name := name
                        type := typeResult.term
                        binder := binder
                      };
                      smaller
                        nextContext
                        (List.cons binderEntry bindersRev)

def psElabTypedBinders
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext)
    (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) :
    Except PsElabError PsElabTypedBindersResult :=
  psElabTypedBindersAcc elaborate binders context []

def psElabTypedBinderListReverseAux
    (remaining : List PsElabTypedBinder) :
    List PsElabTypedBinder -> List PsElabTypedBinder :=
  match remaining with
  | List.nil =>
      fun (acc : List PsElabTypedBinder) => acc
  | List.cons head tail =>
      let smaller :
          List PsElabTypedBinder -> List PsElabTypedBinder :=
        psElabTypedBinderListReverseAux tail;
      fun (acc : List PsElabTypedBinder) =>
        smaller (List.cons head acc)

def psElabTypedBinderListReverse
    (values : List PsElabTypedBinder) :
    List PsElabTypedBinder :=
  psElabTypedBinderListReverseAux values List.nil

def psCloseElabTypedBinders
    (metaContext : PsMetaContext)
    (binders : List PsElabTypedBinder) :
    PsExpr ->
    PsExpr ->
    Prod PsExpr PsExpr :=
  match binders with
  | [] =>
      fun (value : PsExpr) =>
        fun (type : PsExpr) =>
          Prod.mk value type
  | binder :: rest =>
      let smaller :
          PsExpr ->
          PsExpr ->
          Prod PsExpr PsExpr :=
        psCloseElabTypedBinders metaContext rest;
      fun (value : PsExpr) =>
        fun (type : PsExpr) =>
          let binderType :=
            psMetaInstantiate metaContext binder.type;
          let closedValue :=
            PsExpr.lam
              binder.name
              binderType
              (psExprAbstractFVar binder.id value)
              binder.binder;
          let closedType :=
            PsExpr.forallE
              binder.name
              binderType
              (psExprAbstractFVar binder.id type)
              binder.binder;
          smaller closedValue closedType

def psElabLambdaExpectedBody
    (binders : List PsElabTypedBinder) :
    PsElabContext ->
    PsExpr ->
    Except PsElabError (Prod PsElabContext PsExpr) :=
  match binders with
  | [] =>
      fun (context : PsElabContext) =>
        fun (expectedType : PsExpr) =>
          Except.ok
            (Prod.mk
              context
              (psMetaInstantiate
                context.metaContext
                expectedType))
  | binder :: rest =>
      let smaller :
          PsElabContext ->
          PsExpr ->
          Except PsElabError (Prod PsElabContext PsExpr) :=
        psElabLambdaExpectedBody rest;
      fun (context : PsElabContext) =>
        fun (expectedType : PsExpr) =>
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
                  forallView.domain;
              if psElabBoolNot unified.success then
                Except.error PsElabError.typeMismatch
              else
                let nextContext :=
                  psElabContextWithMeta
                    context
                    unified.context;
                let nextExpected :=
                  psExprInstantiate1
                    (psMetaInstantiate
                      unified.context
                      forallView.body)
                    (PsExpr.fvar binder.id);
                smaller nextContext nextExpected

def psElabLambdaBodyExpected
    (context : PsElabContext)
    (binders : List PsElabTypedBinder)
    (expected : Option PsExpr) :
    Except
      PsElabError
      (Prod PsElabContext (Option PsExpr)) :=
  match expected with
  | none =>
      Except.ok (Prod.mk context Option.none)
  | some expectedType =>
      match
          psElabLambdaExpectedBody
            binders
            context
            expectedType with
      | Except.error error => Except.error error
      | Except.ok prepared =>
          Except.ok
            (Prod.mk
              (Prod.fst prepared)
              (Option.some (Prod.snd prepared)))

def psElabLambda
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext)
    (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
    (body : PsSyntaxTerm)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match psElabTypedBinders elaborate context binders with
  | Except.error error => Except.error error
  | Except.ok binderResult =>
      match
          psElabLambdaBodyExpected
            binderResult.context
            (psElabTypedBinderListReverse binderResult.bindersRev)
            expected with
      | Except.error error => Except.error error
      | Except.ok prepared =>
          match elaborate (Prod.fst prepared) body (Prod.snd prepared) with
          | Except.error error => Except.error error
          | Except.ok bodyResult =>
              let metaContext := bodyResult.context.metaContext;
              let openTerm :=
                psMetaInstantiate metaContext bodyResult.term;
              let openType :=
                psMetaInstantiate metaContext bodyResult.type;
              let closed :=
                psCloseElabTypedBinders
                  metaContext
                  binderResult.bindersRev
                  openTerm
                  openType;
              let outerContext :=
                psElabContextWithMeta context metaContext;
              let finalResult :=
                PsElabTermResult.mk
                  outerContext
                  (Prod.fst closed)
                  (Prod.snd closed);
              psElabFinalizeExpected
                finalResult
                expected

def psCloseElabForallBinders
    (metaContext : PsMetaContext)
    (binders : List PsElabTypedBinder) :
    PsExpr ->
    PsExpr :=
  match binders with
  | [] =>
      fun (body : PsExpr) =>
        body
  | binder :: rest =>
      let smaller : PsExpr -> PsExpr :=
        psCloseElabForallBinders metaContext rest;
      fun (body : PsExpr) =>
        let binderType :=
          psMetaInstantiate metaContext binder.type;
        let closedBody :=
          PsExpr.forallE
            binder.name
            binderType
            (psExprAbstractFVar binder.id body)
            binder.binder;
        smaller closedBody

def psElabForall
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext)
    (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
    (body : PsSyntaxTerm)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match psElabTypedBinders elaborate context binders with
  | Except.error error => Except.error error
  | Except.ok binderResult =>
      match elaborate binderResult.context body Option.none with
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
              let metaContext := bodyResult.context.metaContext;
              let openBody :=
                psMetaInstantiate metaContext bodyResult.term;
              let closed :=
                psCloseElabForallBinders
                  metaContext
                  binderResult.bindersRev
                  openBody;
              let outerContext :=
                psElabContextWithMeta context metaContext;
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
    (arguments : List PsExpr) :
    PsExpr -> PsExpr :=
  match arguments with
  | [] =>
      fun (fn : PsExpr) =>
        fn
  | argument :: rest =>
      let smaller : PsExpr -> PsExpr :=
        psExprApplyManyWorker rest;
      fun (fn : PsExpr) =>
        smaller (PsExpr.app fn argument)

def psExprApplyMany
    (fn : PsExpr)
    (arguments : List PsExpr) : PsExpr :=
  psExprApplyManyWorker arguments fn

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
  let boolType := PsExpr.constE psBoolName [];
  match elaborate context condition (Option.some boolType) with
  | Except.error error => Except.error error
  | Except.ok conditionResult =>
      let trueTerm := PsExpr.constE psBoolTrueName [];
      let conditionProp :=
        psExprApplyMany
          (PsExpr.constE
            psEqName
            [PsLevel.succ PsLevel.zero])
          [boolType, conditionResult.term, trueTerm];
      let decider :=
        psExprApplyMany
          (PsExpr.constE psBoolDecEqName [])
          [conditionResult.term, trueTerm];
      match elaborate
          conditionResult.context
          thenBranch
          expected with
      | Except.error error => Except.error error
      | Except.ok thenResult =>
          let resultType : PsExpr :=
            match expected with
            | some type => type
            | none => thenResult.type;
          match elaborate
              thenResult.context
              elseBranch
              (Option.some resultType) with
          | Except.error error => Except.error error
          | Except.ok elseResult =>
              let metaContext := elseResult.context.metaContext;
              let instantiatedType :=
                psMetaInstantiate metaContext resultType;
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
                          ];
                      let restoredContext :=
                        psElabContextWithMeta context metaContext;
                      psElabResolvedTerm
                        restoredContext
                        term
                        expected

structure PsExprAppView where
  head : PsExpr
  args : List PsExpr

def psExprAppViewAccWorker
    (expr : PsExpr) :
    List PsExpr -> PsExprAppView :=
  match expr with
  | .app fn argument =>
      let smaller : List PsExpr -> PsExprAppView :=
        psExprAppViewAccWorker fn;
      fun (args : List PsExpr) =>
        smaller (List.cons argument args)
  | _ =>
      fun (args : List PsExpr) =>
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

def psExprHasConst
    (target : PsName)
    (expr : PsExpr) : Bool :=
  match expr with
  | .constE name _ => psNameEq name target
  | .app fn argument =>
      psElabBoolOr
        (psExprHasConst target fn)
        (psExprHasConst target argument)
  | .lam _ type body _ =>
      psElabBoolOr
        (psExprHasConst target type)
        (psExprHasConst target body)
  | .forallE _ type body _ =>
      psElabBoolOr
        (psExprHasConst target type)
        (psExprHasConst target body)
  | .letE _ type value body =>
      psElabBoolOr
        (psExprHasConst target type)
        (psElabBoolOr
          (psExprHasConst target value)
          (psExprHasConst target body))
  | .proj _ _ value => psExprHasConst target value
  | _ => false

def psMatchNameEqTarget
    (target : PsName)
    (name : PsName) : Bool :=
  psNameEq name target

def psMatchNameListContains
    (names : List PsName)
    (target : PsName) : Bool :=
  match names with
  | [] =>
      false
  | name :: rest =>
      if psMatchNameEqTarget target name then
        true
      else
        psMatchNameListContains rest target

structure PsElabMatchAlternative where
  constructorName : PsName
  pattern : PsSyntaxPattern
  body : PsSyntaxTerm
  span : PsSourceSpan

def psElabMatchAlternativeFind
    (name : PsName) :
    List PsElabMatchAlternative -> Option PsElabMatchAlternative
  | [] => Option.none
  | alternative :: rest =>
      if psNameEq alternative.constructorName name then
        Option.some alternative
      else
        psElabMatchAlternativeFind name rest

def psElabMatchAlternativeCovered
    (alternatives : List PsElabMatchAlternative)
    (ctorName : PsName) : Bool :=
  match psElabMatchAlternativeFind ctorName alternatives with
  | some _ => true
  | none => false

def psElabFillWildcardAlternatives
    (pattern : PsSyntaxPattern)
    (body : PsSyntaxTerm)
    (span : PsSourceSpan)
    (constructors : List PsName)
    (alternativesRev : List PsElabMatchAlternative) :
    List PsElabMatchAlternative :=
  match constructors with
  | [] =>
      alternativesRev
  | ctorName :: rest =>
      let next :=
        match psElabMatchAlternativeFind ctorName alternativesRev with
        | some _ => alternativesRev
        | none =>
            let alternative : PsElabMatchAlternative := {
              constructorName := ctorName
              pattern := pattern
              body := body
              span := span
            };
            List.cons alternative alternativesRev;
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
        if value then
          Except.ok psBoolTrueName
        else
          Except.ok psBoolFalseName
      else
        Except.error PsElabError.matchPatternUnsupported
  | .wildcard _ =>
      Except.error PsElabError.matchPatternUnsupported
  | .constructor syntaxName _ _ =>
      match syntaxName.segments with
      | [] => Except.error PsElabError.matchPatternUnsupported
      | segment :: rest =>
          match rest with
          | [] =>
              Except.ok (psNameAppendStr inductiveName segment)
          | _ :: _ =>
              match psSyntaxNameToName syntaxName with
              | none => Except.error PsElabError.matchPatternUnsupported
              | some name => Except.ok name

def psElabPrepareMatchAlternatives
    (inductiveInfo : PsInductiveInfo)
    (entries : List (Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan)))
    (alternativesRev : List PsElabMatchAlternative) :
    Except PsElabError (List PsElabMatchAlternative) :=
  match entries with
  | [] =>
      let alternatives := List.reverse alternativesRev;
      let exhaustive :=
        List.all
          inductiveInfo.constructors
          (psElabMatchAlternativeCovered alternatives);
      if exhaustive then
        Except.ok alternatives
      else
        Except.error PsElabError.matchNonExhaustive
  | entry :: rest =>
      let pattern := Prod.fst entry;
      let payload := Prod.snd entry;
      let body := Prod.fst payload;
      let span := Prod.snd payload;
      match pattern with
      | .wildcard _ =>
          if List.isEmpty rest then
            Except.ok
              (List.reverse (psElabFillWildcardAlternatives
                pattern
                body
                span
                inductiveInfo.constructors
                alternativesRev))
          else
            Except.error PsElabError.matchPatternUnsupported
      | _ =>
          match psElabMatchPatternConstructorName
              inductiveInfo.name
              pattern with
          | Except.error error => Except.error error
          | Except.ok ctorName =>
              if psElabBoolNot (psMatchNameListContains inductiveInfo.constructors ctorName) then
                Except.error (PsElabError.matchConstructorUnknown ctorName)
              else
                match psElabMatchAlternativeFind ctorName alternativesRev with
                | some _ =>
                    Except.error
                      (PsElabError.matchDuplicateConstructor ctorName)
                | none =>
                    let alternative : PsElabMatchAlternative := {
                      constructorName := ctorName
                      pattern := pattern
                      body := body
                      span := span
                    };
                    psElabPrepareMatchAlternatives
                      inductiveInfo
                      rest
                      (List.cons alternative alternativesRev)

structure PsElabMatchField where
  id : Nat
  name : PsName
  type : PsExpr
  binder : PsBinderInfo

structure PsElabMatchFieldsResult where
  context : PsElabContext
  fieldsRev : List PsElabMatchField

def psElabMatchApplyParameters
    (context : PsElabContext)
    (parameters : List PsExpr)
    (cursor : PsExpr) :
    Except PsElabError PsExpr :=
  match parameters with
  | [] =>
      Except.ok cursor
  | parameter :: rest =>
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

def psSyntaxNameIsWildcardBinder
    (name : PsSyntaxName) : Bool :=
  match name.segments with
  | List.nil =>
      false
  | List.cons segment rest =>
      match rest with
      | List.nil =>
          psStringEq segment "_"
      | List.cons _ _ =>
          false

def psSyntaxNameMatchesCore
    (coreName : Option PsName)
    (candidate : PsSyntaxName) : Bool :=
  if psSyntaxNameIsWildcardBinder candidate then
    false
  else
    match coreName with
    | none =>
        false
    | some left =>
        match psSyntaxNameToName candidate with
        | none =>
            false
        | some right =>
            psNameEq left right

def psSyntaxNameListHasDuplicate : List PsSyntaxName -> Bool
  | List.nil => false
  | List.cons name rest =>
      if psSyntaxNameIsWildcardBinder name then
        psSyntaxNameListHasDuplicate rest
      else
        let coreName := psSyntaxNameToName name;
        let duplicated :=
          List.any rest (psSyntaxNameMatchesCore coreName);
        if duplicated then
          true
        else
          psSyntaxNameListHasDuplicate rest

def psElabMatchFields
    (context : PsElabContext)
    (inductiveName : PsName)
    (cursor : PsExpr)
    (binderSyntaxes : List PsSyntaxName)
    (fieldsRev : List PsElabMatchField) :
    Except PsElabError PsElabMatchFieldsResult :=
  match binderSyntaxes with
  | [] =>
      Except.ok {
        context := context
        fieldsRev := fieldsRev
      }
  | binderSyntax :: rest =>
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
                  forallView.binder;
              let nextContext :=
                psElabContextWithLocal context pushed.context;
              let field : PsElabMatchField := {
                id := pushed.id
                name := binderName
                type := forallView.domain
                binder := forallView.binder
              };
              psElabMatchFields
                nextContext
                inductiveName
                (psExprInstantiate1
                  forallView.body
                  (PsExpr.fvar pushed.id))
                rest
                (List.cons field fieldsRev)

def psElabMatchFieldAt
    (fields : List PsElabMatchField)
    (index : Nat) : Option PsElabMatchField :=
  match fields with
  | [] =>
      none
  | field :: rest =>
      match index with
      | 0 =>
          some field
      | nextIndex + 1 =>
          psElabMatchFieldAt rest nextIndex

structure PsElabMatchHypothesesResult where
  context : PsElabContext
  hypothesesRev : List PsElabMatchField

def psElabPushRecursiveHypotheses
    (expectedType : PsExpr)
    (fields : List PsElabMatchField)
    (fieldIndices : List Nat)
    (context : PsElabContext)
    (hypothesesRev : List PsElabMatchField) :
    Except PsElabError PsElabMatchHypothesesResult :=
  match fieldIndices with
  | [] =>
      Except.ok {
        context := context
        hypothesesRev := hypothesesRev
      }
  | fieldIndex :: rest =>
      match psElabMatchFieldAt fields fieldIndex with
      | none => Except.error PsElabError.structuralRecursionInternal
      | some field =>
          let hypothesisName :=
            psNameAppendNum
              (psRootName "_ih")
              fieldIndex;
          let pushed :=
            psLocalPushBinding
              context.localContext
              hypothesisName
              expectedType
              PsBinderInfo.explicit;
          let withLocal :=
            psElabContextWithLocal
              context
              pushed.context;
          let withRecursion :=
            match context.structuralRecursion with
            | none =>
                withLocal
            | some recursion =>
                let nextRecursion : PsElabStructuralRecursion := {
                  functionName := recursion.functionName
                  explicitParameterIds := recursion.explicitParameterIds
                  recursiveParameterIndex := recursion.recursiveParameterIndex
                  calls :=
                    List.cons
                      (Prod.mk field.id pushed.id)
                      recursion.calls
                };
                psElabContextWithStructuralRecursion
                  withLocal
                  (Option.some nextRecursion);
          let hypothesis : PsElabMatchField := {
            id := pushed.id
            name := hypothesisName
            type := expectedType
            binder := PsBinderInfo.explicit
          };
          psElabPushRecursiveHypotheses
            expectedType
            fields
            rest
            withRecursion
            (List.cons hypothesis hypothesesRev)

def psCloseElabMatchFields
    (metaContext : PsMetaContext)
    (fields : List PsElabMatchField)
    (term : PsExpr) : PsExpr :=
  match fields with
  | [] =>
      term
  | field :: rest =>
      let closed :=
        PsExpr.lam
          field.name
          (psMetaInstantiate metaContext field.type)
          (psExprAbstractFVar field.id term)
          field.binder;
      psCloseElabMatchFields
        metaContext
        rest
        closed

structure PsElabMatchMinorResult where
  context : PsElabContext
  term : PsExpr

def psElabWildcardBinderNames
    (span : PsSourceSpan)
    (index : Nat)
    (remaining : Nat) :
    List PsSyntaxName :=
  match remaining with
  | 0 =>
      []
  | nextRemaining + 1 =>
      let segment :=
        String.Internal.append "_wild" (toString index);
      let syntaxName : PsSyntaxName := {
        segments := List.cons segment List.nil
        span := span
      };
      List.cons
        syntaxName
        (psElabWildcardBinderNames
          span
          (Nat.succ index)
          nextRemaining)

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
              ctorInfo.numFields;
      if psElabBoolNot (psNameEq ctorInfo.inductiveName inductiveInfo.name) then
        Except.error
          (PsElabError.matchConstructorUnknown constructorName)
      else if psElabNatNe ctorInfo.numParams (psElabListLength parameterArgs) then
        Except.error PsElabError.matchParameterArity
      else if psElabNatNe ctorInfo.numFields (psElabListLength binders) then
        Except.error
          (PsElabError.matchConstructorArity constructorName)
      else if psSyntaxNameListHasDuplicate binders then
        Except.error
          (PsElabError.matchConstructorArity constructorName)
      else if psElabNatNe (psElabListLength ctorInfo.levelParams) (psElabListLength inductiveLevels) then
        Except.error PsElabError.matchRecursorLevels
      else
        let ctorType :=
          psExprInstantiateLevelParams
            ctorInfo.levelParams
            inductiveLevels
            ctorInfo.type;
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
                  List.reverse fieldResult.fieldsRev;
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
                        let metaContext := bodyResult.context.metaContext;
                        let withHypotheses :=
                          psCloseElabMatchFields
                            metaContext
                            hypotheses.hypothesesRev
                            (psMetaInstantiate
                              metaContext
                              bodyResult.term);
                        let closed :=
                          psCloseElabMatchFields
                            metaContext
                            fieldResult.fieldsRev
                            withHypotheses;
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
    (alternatives : List PsElabMatchAlternative)
    (context : PsElabContext)
    (constructorNames : List PsName) :
    Except PsElabError PsElabMatchMinorsResult :=
  match constructorNames with
  | [] =>
      Except.ok {
        context := context
        minors := []
      }
  | ctorName :: rest =>
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
                    minors := List.cons minor.term tail.minors
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
      List (Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan)))
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
              scrutineeResult.type;
          let typeView := psExprAppView scrutineeType;
          match typeView.head with
          | .constE inductiveName inductiveLevels =>
              match psEnvironmentFindInductive
                  scrutineeResult.context.environment
                  inductiveName with
              | none =>
                  Except.error PsElabError.matchScrutineeUnsupported
              | some inductiveInfo =>
                  if psElabNatNe inductiveInfo.numIndices 0 then
                    Except.error PsElabError.matchInductiveUnsupported
                  else if psElabNatNe (psElabListLength typeView.args) inductiveInfo.numParams then
                    Except.error PsElabError.matchParameterArity
                  else
                    match psElabPrepareMatchAlternatives
                        inductiveInfo
                        alternativesSyntax
                        [] with
                    | Except.error error => Except.error error
                    | Except.ok alternatives =>
                        let recursorName :=
                          psNameAppendStr inductiveInfo.name "rec";
                        match psEnvironmentFindRecursor
                            scrutineeResult.context.environment
                            recursorName with
                        | none =>
                            Except.error PsElabError.matchRecursorUnsupported
                        | some recInfo =>
                            if
                                psElabBoolOr
                                  (psElabNatNe
                                    recInfo.numParams
                                    inductiveInfo.numParams)
                                  (psElabBoolOr
                                    (psElabNatNe recInfo.numIndices 0)
                                    (psElabBoolOr
                                      (psElabNatNe recInfo.numMotives 1)
                                      (psElabNatNe
                                        recInfo.numMinors
                                        (psElabListLength inductiveInfo.constructors)))) then
                              Except.error
                                PsElabError.matchRecursorUnsupported
                            else
                              let instantiatedExpected :=
                                psMetaInstantiate
                                  scrutineeResult.context.metaContext
                                  expectedType;
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
                                        if Nat.beq (psElabListLength recInfo.levelParams) 0 then
                                          []
                                        else if Nat.beq (psElabListLength recInfo.levelParams) 1 then
                                          [resultLevel]
                                        else
                                          [];
                                      if Nat.blt 1 (psElabListLength recInfo.levelParams) then
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
                                                PsBinderInfo.explicit;
                                            let recursorTail :=
                                              List.append
                                                minors.minors
                                                (List.cons
                                                  scrutineeResult.term
                                                  List.nil);
                                            let recursorArgs :=
                                              List.append
                                                typeView.args
                                                (List.cons
                                                  motive
                                                  recursorTail);
                                            let recursorTerm :=
                                              psExprApplyMany
                                                (PsExpr.constE
                                                  recursorName
                                                  recursorLevels)
                                                recursorArgs;
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

def psSyntaxTermListIsEmpty
    (values : List PsSyntaxTerm) : Bool :=
  match values with
  | [] =>
      true
  | _ :: _ =>
      false

def psElabApplyArgsWithFuel
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (remainingFuel : Nat)
    (current : PsElabTermResult)
    (arguments : List PsSyntaxTerm)
    (pendingInstancesRev : List Nat) :
    Except PsElabError PsElabApplicationResult :=
  match remainingFuel with
  | 0 =>
      Except.error PsElabError.fuelExhausted
  | fuel + 1 =>
      let currentType :=
        psWhnf
          current.context.environment
          current.context.metaContext
          current.context.localContext
          current.type;
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
                        elaboratedArgument.term;
                    let nextType :=
                      psExprInstantiate1
                        body
                        elaboratedArgument.term;
                    let nextResult : PsElabTermResult := {
                      context := elaboratedArgument.context
                      term := nextTerm
                      type := nextType
                    };
                    psElabApplyArgsWithFuel
                      elaborate
                      fuel
                      nextResult
                      rest
                      pendingInstancesRev
          else if
              psElabBoolAnd
                (psBinderIsStrictImplicit binder)
                (psSyntaxTermListIsEmpty arguments) then
            Except.ok {
              result := current
              pendingInstancesRev := pendingInstancesRev
            }
          else
            let kind :=
              if psBinderIsInstanceImplicit binder then
                PsMetaVarKind.synthetic
              else
                PsMetaVarKind.natural;
            let fresh :=
              psMetaFresh
                current.context.metaContext
                current.context.localContext
                domain
                kind;
            let nextContext :=
              psElabContextWithMeta
                current.context
                fresh.context;
            let nextResult : PsElabTermResult := {
              context := nextContext
              term := PsExpr.app current.term fresh.expr
              type := psExprInstantiate1 body fresh.expr
            };
            let nextPending :=
              if psBinderIsInstanceImplicit binder then
                match fresh.expr with
                | PsExpr.mvar id =>
                    List.cons id pendingInstancesRev
                | _ => pendingInstancesRev
              else
                pendingInstancesRev;
            psElabApplyArgsWithFuel
              elaborate
              fuel
              nextResult
              arguments
              nextPending
      | _ =>
          if psSyntaxTermListIsEmpty arguments then
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

def psElabSolvePendingInstances
    (current : PsElabTermResult)
    (pendingInstances : List Nat) :
    Except PsElabError PsElabTermResult :=
  match pendingInstances with
  | [] =>
      let metaContext := current.context.metaContext;
      Except.ok {
        context := current.context
        term := psMetaInstantiate metaContext current.term
        type := psMetaInstantiate metaContext current.type
      }
  | id :: rest =>
      let metaContext := current.context.metaContext;
      match psMetaFindAssignment metaContext id with
      | some _ =>
          psElabSolvePendingInstances current rest
      | none =>
          match psMetaFindDecl metaContext id with
          | none =>
              Except.error PsElabError.implicitApplicationUnsupported
          | some declaration =>
              let target :=
                psMetaInstantiate metaContext declaration.type;
              if psExprHasUnresolvedMeta target then
                Except.error PsElabError.implicitApplicationUnsupported
              else
                let synthesized :=
                  psSynthInstance
                    current.context.environment
                    current.context.localContext
                    current.context.instances
                    metaContext
                    target;
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
                        let assignedResult : PsElabTermResult := {
                          context :=
                            psElabContextWithMeta
                              current.context
                              assigned
                          term := current.term
                          type := current.type
                        };
                        psElabSolvePendingInstances
                          assignedResult
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

def psElabDropForallBinders
    (remaining : Nat)
    (type : PsExpr) : Option PsExpr :=
  match remaining with
  | 0 =>
      some type
  | nextRemaining + 1 =>
      match type with
      | .forallE _ _ body _ =>
          psElabDropForallBinders nextRemaining body
      | _ => none

def psElabTakeForallNames
    (remaining : Nat)
    (type : PsExpr) : Option (List String) :=
  match remaining with
  | 0 =>
      some []
  | nextRemaining + 1 =>
      match type with
      | .forallE name _ body _ =>
          match psElabTakeForallNames nextRemaining body with
          | none => none
          | some rest =>
              some (List.cons (psNameLastComponent name) rest)
      | _ => none

def psSyntaxRecordFieldName
    (field : Prod PsSyntaxName PsSyntaxTerm) :
    Option String :=
  let syntaxName := Prod.fst field;
  match List.reverse syntaxName.segments with
  | [] => none
  | name :: _ => some name

def psSyntaxRecordFieldMatchesName
    (name : String)
    (field : Prod PsSyntaxName PsSyntaxTerm) : Bool :=
  match psSyntaxRecordFieldName field with
  | none => false
  | some fieldName => psStringEq fieldName name

def psSyntaxRecordHasField
    (fields :
      List (Prod PsSyntaxName PsSyntaxTerm))
    (name : String) : Bool :=
  List.any fields (psSyntaxRecordFieldMatchesName name)

def psSyntaxRecordHasNamedField
    (fields : List (Prod PsSyntaxName PsSyntaxTerm))
    (name : String) : Bool :=
  psSyntaxRecordHasField fields name

def psSyntaxRecordFieldsMatch
    (fields :
      List (Prod PsSyntaxName PsSyntaxTerm))
    (names : List String) : Bool :=
  psElabBoolAnd
    (Nat.beq (psElabListLength fields) (psElabListLength names))
    (List.all names (psSyntaxRecordHasNamedField fields))

def psSyntaxRecordFindField
    (fields : List (Prod PsSyntaxName PsSyntaxTerm))
    (name : String) :
    Option PsSyntaxTerm :=
  match fields with
  | [] =>
      none
  | field :: rest =>
      match psSyntaxRecordFieldName field with
      | some fieldName =>
          if psStringEq fieldName name then
            some (Prod.snd field)
          else
            psSyntaxRecordFindField rest name
      | none =>
          psSyntaxRecordFindField rest name

def psSyntaxRecordOrderFields
    (fields : List (Prod PsSyntaxName PsSyntaxTerm))
    (names : List String) :
    Option (List PsSyntaxTerm) :=
  match names with
  | [] =>
      some []
  | name :: rest =>
      match psSyntaxRecordFindField fields name with
      | none =>
          none
      | some value =>
          match psSyntaxRecordOrderFields fields rest with
          | none =>
              none
          | some values =>
              some (List.cons value values)

def psElabRecordCandidateForInfo
    (environment : PsEnvironment)
    (info : PsInductiveInfo) :
    Option PsElabRecordCandidate :=
  if info.isStructure then
    match info.constructors with
    | [] =>
        none
    | constructorName :: rest =>
        match rest with
        | [] =>
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
        | _ :: _ =>
            none
  else
    none

def psElabRecordCandidateFromExpected
    (context : PsElabContext)
    (expected : PsExpr) :
    Option PsElabRecordCandidate :=
  let reduced :=
    psWhnf
      context.environment
      context.metaContext
      context.localContext
      expected;
  let view := psInferAppView reduced;
  match view.head with
  | .constE typeName _ =>
      match
          psEnvironmentFindInductive
            context.environment
            typeName with
      | none => none
      | some info =>
          if psElabNatNe (psElabListLength view.args) info.numParams then
            none
          else
            psElabRecordCandidateForInfo
              context.environment
              info
  | _ => none

def psElabRecordCandidates
    (environment : PsEnvironment)
    (fields : List (Prod PsSyntaxName PsSyntaxTerm))
    (declarations : List PsDeclaration)
    (candidatesRev : List PsElabRecordCandidate) :
    List PsElabRecordCandidate :=
  match declarations with
  | [] =>
      List.reverse candidatesRev
  | declaration :: rest =>
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
                  (List.cons candidate candidatesRev)
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
  | [] =>
      none
  | candidate :: rest =>
      match rest with
      | [] => some candidate
      | _ :: _ => none

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
          fields;
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
          | none => none
          | some resolved =>
              match resolved with
              | .local id => some id
              | .global _ => none
  | _ => none

def psElabNatListAt
    (values : List Nat)
    (index : Nat) : Option Nat :=
  match values with
  | [] =>
      none
  | value :: rest =>
      match index with
      | 0 =>
          some value
      | nextIndex + 1 =>
          psElabNatListAt rest nextIndex

def psElabValidateStructuralCall
    (context : PsElabContext)
    (recursion : PsElabStructuralRecursion)
    (index : Nat)
    (arguments : List PsSyntaxTerm)
    (hypothesisId : Option Nat) :
    Except PsElabError Nat :=
  match arguments with
  | [] =>
      match hypothesisId with
      | some resolvedHypothesisId =>
          Except.ok resolvedHypothesisId
      | none =>
          Except.error PsElabError.structuralRecursionInternal
  | argument :: rest =>
      match psElabSyntaxLocalId context argument with
      | none =>
          if Nat.beq index recursion.recursiveParameterIndex then
            Except.error PsElabError.structuralRecursionNotDecreasing
          else
            Except.error PsElabError.structuralRecursionInvariantArgument
      | some argumentId =>
          if Nat.beq index recursion.recursiveParameterIndex then
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
                  (Nat.succ index)
                  rest
                  (some nextHypothesisId)
          else
            match
                psElabNatListAt
                  recursion.explicitParameterIds
                  index with
            | none =>
                Except.error PsElabError.structuralRecursionArity
            | some originalId =>
                if Nat.beq argumentId originalId then
                  psElabValidateStructuralCall
                    context
                    recursion
                    (Nat.succ index)
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
  match context.structuralRecursion with
  | none =>
      Except.ok none
  | some recursion =>
      match fn with
      | .reference sourceName =>
          match psSyntaxNameToName sourceName with
          | some calledName =>
              if psElabBoolNot (psNameEq calledName recursion.functionName) then
                Except.ok none
              else if
                  psElabNatNe
                    (psElabListLength arguments)
                    (psElabListLength recursion.explicitParameterIds) then
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
      | _ =>
          Except.ok none

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
          | Except.ok selfCall =>
              match selfCall with
              | some result => Except.ok result
              | none =>
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
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  psElabTermWithFuel 4096 context term expected