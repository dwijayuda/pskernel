import Ps.Core.Abstract
import Ps.Core.Equality
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

def psElabBoolNot (value : Bool) : Bool :=
  if value then false else true

def psElabBoolOr (left right : Bool) : Bool :=
  if left then true else right

def psElabBoolAnd (left right : Bool) : Bool :=
  if left then right else false

def psElabStructuralParameterAt
    (ids : List Nat) : Nat -> Option Nat :=
  match ids with
  | List.nil => fun (_index : Nat) => Option.none
  | List.cons id rest =>
      let smaller : Nat -> Option Nat := psElabStructuralParameterAt rest;
      fun (index : Nat) =>
        match index with
        | Nat.zero => Option.some id
        | Nat.succ next => smaller next

-- Abstraction changes exactly the selected free ID. Equality with the original
-- instantiated type therefore checks its absence without a printed-name test.
def psElabCheckStructuralType
    (context : PsElabContext) (majorId : Nat) (type : PsExpr) :
    Except PsElabError Unit :=
  let instantiated := psMetaInstantiate context.metaContext type;
  if psExprHasUnresolvedMeta instantiated then
    Except.error PsElabError.unresolvedMetavariable
  else if psExprAlphaEq instantiated (psExprAbstractFVar majorId instantiated) then
    Except.ok Unit.unit
  else Except.error PsElabError.structuralRecursionDependentParameter

def psElabCheckStructuralParameters
    (context : PsElabContext) (majorId : Nat) (parameterIds : List Nat) :
    Except PsElabError Unit :=
  match parameterIds with
  | List.nil => Except.ok Unit.unit
  | List.cons id rest =>
      match psLocalFindById context.localContext id with
      | Option.none => Except.error PsElabError.structuralRecursionInternal
      | Option.some declaration =>
          match psElabCheckStructuralType context majorId (psLocalDeclType declaration) with
          | Except.error error => Except.error error
          | Except.ok _ => psElabCheckStructuralParameters context majorId rest

def psElabCheckStructuralTelescope
    (context : PsElabContext) (recursion : PsElabStructuralRecursion) :
    Except PsElabError Nat :=
  match psElabStructuralParameterAt
      recursion.explicitParameterIds recursion.recursiveParameterIndex with
  | Option.none => Except.error PsElabError.structuralRecursionInternal
  | Option.some majorId =>
      match psElabCheckStructuralType context majorId recursion.resultType with
      | Except.error error => Except.error error
      | Except.ok _ =>
          match psElabCheckStructuralParameters context majorId recursion.parameterIds with
          | Except.error error => Except.error error
          | Except.ok _ => Except.ok majorId

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
      fun (index : Nat) =>
        fun (cursor : PsExpr) =>
          let smaller : Nat -> PsExpr -> Except PsElabError Nat :=
            psElabFindStructureField
              context
              typeName
              target
              fieldName
              nextRemaining;
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
      let smaller :
          PsElabContext -> PsElabTermResult -> Except PsElabError PsElabTermResult :=
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

-- Resolve only the base of a projection. The recursive descent considers
-- longer proper local prefixes first; the final segment always remains a field.
def psElabLocalProjectionBaseWorker
    (localContext : PsLocalContext)
    (fields : List String) :
    PsName -> Option (Prod PsResolvedName (List String)) :=
  match fields with
  | List.nil =>
      fun (_base : PsName) => Option.none
  | List.cons field rest =>
      let smaller : PsName -> Option (Prod PsResolvedName (List String)) :=
        psElabLocalProjectionBaseWorker localContext rest;
      fun (base : PsName) =>
        match smaller (psNameAppendStr base field) with
        | Option.some selected => Option.some selected
        | Option.none =>
            match psLocalFindUser localContext base with
            | Option.none => Option.none
            | Option.some declaration =>
                Option.some (Prod.mk
                  (PsResolvedName.local (psLocalDeclId declaration))
                  (List.cons field rest))

-- Share name selection between elaboration and hygienic recursion rewriting.
-- Exact complete names precede the established first-segment projection base.
-- Only an absent first segment permits a longer LOCAL base; a selected base
-- never falls back to another name after a field or type error.
def psElabResolveReferenceBase
    (localContext : PsLocalContext)
    (environment : PsEnvironment)
    (sourceName : PsSyntaxName) :
    Option (Prod PsResolvedName (List String)) :=
  match psSyntaxNameToName sourceName with
  | Option.none => Option.none
  | Option.some name =>
      match psResolveName localContext environment name with
      | Option.some resolved => Option.some (Prod.mk resolved List.nil)
      | Option.none =>
          match sourceName.segments with
          | List.nil => Option.none
          | List.cons first tail =>
              match tail with
              | List.nil => Option.none
              | List.cons second rest =>
                  let base := psNameAppendStr PsName.anonymous first;
                  match psResolveName localContext environment base with
                  | Option.some resolved => Option.some (Prod.mk resolved tail)
                  | Option.none =>
                      psElabLocalProjectionBaseWorker
                        localContext rest (psNameAppendStr base second)

def psElabProjectionReference
    (context : PsElabContext)
    (sourceName : PsSyntaxName)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match psElabResolveReferenceBase
      context.localContext context.environment sourceName with
  | Option.none =>
      match sourceName.segments with
      | List.nil => Except.error PsElabError.emptyName
      | List.cons first _ =>
          Except.error
            (PsElabError.unknownName (psNameAppendStr PsName.anonymous first))
  | Option.some selected =>
      let baseTerm : PsExpr :=
        match Prod.fst selected with
        | PsResolvedName.local id => PsExpr.fvar id
        | PsResolvedName.global name => PsExpr.constE name List.nil;
      match Prod.snd selected with
      | List.nil => psElabResolvedTerm context baseTerm expected
      | List.cons _ _ =>
          match psElabResolvedTerm context baseTerm Option.none with
          | Except.error error => Except.error error
          | Except.ok baseResult =>
              match psElabProjectionChain context baseResult (Prod.snd selected) with
              | Except.error error => Except.error error
              | Except.ok projected => psElabFinalizeExpected projected expected

def psElabNamedReference
    (context : PsElabContext)
    (sourceName : PsSyntaxName)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  psElabProjectionReference context sourceName expected

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
    (name : PsName)
    (alternatives : List PsElabMatchAlternative) :
    Option PsElabMatchAlternative :=
  match alternatives with
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
    (constructors : List PsName) :
    List PsElabMatchAlternative ->
    List PsElabMatchAlternative :=
  match constructors with
  | [] =>
      fun (alternativesRev : List PsElabMatchAlternative) =>
        alternativesRev
  | ctorName :: rest =>
      let smaller :
          List PsElabMatchAlternative ->
          List PsElabMatchAlternative :=
        psElabFillWildcardAlternatives
          pattern
          body
          span
          rest;
      fun (alternativesRev : List PsElabMatchAlternative) =>
        let next : List PsElabMatchAlternative :=
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
        smaller next

def psElabMatchAlternativeListReverseAux
    (values : List PsElabMatchAlternative) :
    List PsElabMatchAlternative ->
    List PsElabMatchAlternative :=
  match values with
  | [] =>
      fun (acc : List PsElabMatchAlternative) => acc
  | value :: rest =>
      let smaller :
          List PsElabMatchAlternative ->
          List PsElabMatchAlternative :=
        psElabMatchAlternativeListReverseAux rest;
      fun (acc : List PsElabMatchAlternative) =>
        smaller (List.cons value acc)

def psElabMatchAlternativeListReverse
    (values : List PsElabMatchAlternative) :
    List PsElabMatchAlternative :=
  psElabMatchAlternativeListReverseAux values []

def psElabMatchAlternativesCoverConstructors
    (alternatives : List PsElabMatchAlternative)
    (constructors : List PsName) : Bool :=
  match constructors with
  | [] => true
  | constructorName :: rest =>
      if
          psElabMatchAlternativeCovered
            alternatives
            constructorName then
        psElabMatchAlternativesCoverConstructors alternatives rest
      else
        false

def psElabMatchPatternConstructorName
    (inductiveInfo : PsName)
    (pattern : PsSyntaxPattern) :
    Except PsElabError PsName :=
  match pattern with
  | .bool value _ =>
      if psNameEq inductiveInfo psBoolName then
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
              Except.ok (psNameAppendStr inductiveInfo segment)
          | _ :: _ =>
              match psSyntaxNameToName syntaxName with
              | none => Except.error PsElabError.matchPatternUnsupported
              | some name => Except.ok name

def psElabPrepareMatchAlternativesWorker
    (inductiveInfo : PsInductiveInfo)
    (entries : List (Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan))) :
    List PsElabMatchAlternative ->
    Except PsElabError (List PsElabMatchAlternative) :=
  match entries with
  | [] =>
      fun (alternativesRev : List PsElabMatchAlternative) =>
        let alternatives :=
          psElabMatchAlternativeListReverse alternativesRev;
        let exhaustive :=
          psElabMatchAlternativesCoverConstructors
            alternatives
            inductiveInfo.constructors;
        if exhaustive then
          Except.ok alternatives
        else
          Except.error PsElabError.matchNonExhaustive
  | entry :: rest =>
      let smaller :
          List PsElabMatchAlternative ->
          Except PsElabError (List PsElabMatchAlternative) :=
        psElabPrepareMatchAlternativesWorker
          inductiveInfo
          rest;
      fun (alternativesRev : List PsElabMatchAlternative) =>
        let pattern := Prod.fst entry;
        let payload := Prod.snd entry;
        let body := Prod.fst payload;
        let span := Prod.snd payload;
        match pattern with
        | .wildcard _ =>
            match rest with
            | [] =>
                Except.ok
                  (psElabMatchAlternativeListReverse
                    (psElabFillWildcardAlternatives
                      pattern
                      body
                      span
                      inductiveInfo.constructors
                      alternativesRev))
            | _ :: _ =>
                Except.error PsElabError.matchPatternUnsupported
        | _ =>
            match psElabMatchPatternConstructorName
                inductiveInfo.name
                pattern with
            | Except.error error => Except.error error
            | Except.ok ctorName =>
                if psElabBoolNot
                    (psMatchNameListContains
                      inductiveInfo.constructors
                      ctorName) then
                  Except.error
                    (PsElabError.matchConstructorUnknown ctorName)
                else
                  match
                      psElabMatchAlternativeFind
                        ctorName
                        alternativesRev with
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
                      smaller
                        (List.cons alternative alternativesRev)

def psElabPrepareMatchAlternatives
    (inductiveInfo : PsInductiveInfo)
    (entries : List (Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan)))
    (alternativesRev : List PsElabMatchAlternative) :
    Except PsElabError (List PsElabMatchAlternative) :=
  psElabPrepareMatchAlternativesWorker
    inductiveInfo
    entries
    alternativesRev

structure PsElabMatchField where
  id : Nat
  name : PsName
  type : PsExpr
  binder : PsBinderInfo

structure PsElabMatchFieldsResult where
  context : PsElabContext
  fieldsRev : List PsElabMatchField

def psElabMatchApplyParametersWorker
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
        psElabMatchApplyParametersWorker
          context
          rest;
      fun (cursor : PsExpr) =>
        match psInferEnsureForall
            context.environment
            context.metaContext
            context.localContext
            cursor with
        | Except.error error =>
            Except.error (PsElabError.infer error)
        | Except.ok forallView =>
            smaller
              (psExprInstantiate1
                forallView.body
                parameter)

def psElabMatchApplyParameters
    (context : PsElabContext)
    (parameters : List PsExpr)
    (cursor : PsExpr) :
    Except PsElabError PsExpr :=
  psElabMatchApplyParametersWorker
    context
    parameters
    cursor

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

def psSyntaxNameListContainsCore
    (coreName : Option PsName)
    (candidates : List PsSyntaxName) : Bool :=
  match candidates with
  | List.nil =>
      false
  | List.cons candidate rest =>
      if psSyntaxNameMatchesCore coreName candidate then
        true
      else
        psSyntaxNameListContainsCore coreName rest

def psSyntaxNameListHasDuplicate
    (names : List PsSyntaxName) : Bool :=
  match names with
  | List.nil =>
      false
  | List.cons name rest =>
      if psSyntaxNameIsWildcardBinder name then
        psSyntaxNameListHasDuplicate rest
      else
        let coreName := psSyntaxNameToName name;
        if psSyntaxNameListContainsCore coreName rest then
          true
        else
          psSyntaxNameListHasDuplicate rest

def psElabMatchFieldsWorker
    (inductiveName : PsName)
    (binderSyntaxes : List PsSyntaxName) :
    PsElabContext ->
    PsExpr ->
    List PsElabMatchField ->
    Except PsElabError PsElabMatchFieldsResult :=
  match binderSyntaxes with
  | [] =>
      fun (context : PsElabContext) =>
        fun (_cursor : PsExpr) =>
          fun (fieldsRev : List PsElabMatchField) =>
            Except.ok {
              context := context
              fieldsRev := fieldsRev
            }
  | binderSyntax :: rest =>
      let smaller :
          PsElabContext ->
          PsExpr ->
          List PsElabMatchField ->
          Except PsElabError PsElabMatchFieldsResult :=
        psElabMatchFieldsWorker
          inductiveName
          rest;
      fun (context : PsElabContext) =>
        fun (cursor : PsExpr) =>
          fun (fieldsRev : List PsElabMatchField) =>
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
                    smaller
                      nextContext
                      (psExprInstantiate1
                        forallView.body
                        (PsExpr.fvar pushed.id))
                      (List.cons field fieldsRev)

def psElabMatchFields
    (context : PsElabContext)
    (inductiveName : PsName)
    (cursor : PsExpr)
    (binderSyntaxes : List PsSyntaxName)
    (fieldsRev : List PsElabMatchField) :
    Except PsElabError PsElabMatchFieldsResult :=
  psElabMatchFieldsWorker
    inductiveName
    binderSyntaxes
    context
    cursor
    fieldsRev

def psElabMatchFieldAtWorker
    (index : Nat) :
    List PsElabMatchField -> Option PsElabMatchField :=
  match index with
  | 0 =>
      fun (fields : List PsElabMatchField) =>
        match fields with
        | [] =>
            Option.none
        | field :: _rest =>
            Option.some field
  | nextIndex + 1 =>
      fun (fields : List PsElabMatchField) =>
        let smaller :
            List PsElabMatchField -> Option PsElabMatchField :=
          psElabMatchFieldAtWorker nextIndex;
        match fields with
        | [] =>
            Option.none
        | _field :: rest =>
            smaller rest

def psElabMatchFieldAt
    (fields : List PsElabMatchField)
    (index : Nat) : Option PsElabMatchField :=
  psElabMatchFieldAtWorker index fields

structure PsElabMatchHypothesesResult where
  context : PsElabContext
  hypothesesRev : List PsElabMatchField

def psElabPushRecursiveHypothesesWorker
    (expectedType : PsExpr)
    (fields : List PsElabMatchField)
    (fieldIndices : List Nat) :
    PsElabContext ->
    List PsElabMatchField ->
    Except PsElabError PsElabMatchHypothesesResult :=
  match fieldIndices with
  | [] =>
      fun (context : PsElabContext) =>
        fun (hypothesesRev : List PsElabMatchField) =>
          Except.ok {
            context := context
            hypothesesRev := hypothesesRev
          }
  | fieldIndex :: rest =>
      let smaller :
          PsElabContext ->
          List PsElabMatchField ->
          Except PsElabError PsElabMatchHypothesesResult :=
        psElabPushRecursiveHypothesesWorker
          expectedType
          fields
          rest;
      fun (context : PsElabContext) =>
        fun (hypothesesRev : List PsElabMatchField) =>
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
              let withRecursion : PsElabContext :=
                match context.structuralRecursion with
                | none =>
                    withLocal
                | some recursion =>
                    let nextRecursion : PsElabStructuralRecursion := {
                      functionName := recursion.functionName
                      parameterIds := recursion.parameterIds
                      explicitParameterIds := recursion.explicitParameterIds
                      recursiveParameterIndex := recursion.recursiveParameterIndex
                      calls :=
                        if recursion.collectCalls then
                          List.cons (Prod.mk field.id pushed.id) recursion.calls
                        else recursion.calls
                      resultType := recursion.resultType
                      collectCalls := recursion.collectCalls
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
              smaller
                withRecursion
                (List.cons hypothesis hypothesesRev)

def psElabPushRecursiveHypotheses
    (expectedType : PsExpr)
    (fields : List PsElabMatchField)
    (fieldIndices : List Nat)
    (context : PsElabContext)
    (hypothesesRev : List PsElabMatchField) :
    Except PsElabError PsElabMatchHypothesesResult :=
  psElabPushRecursiveHypothesesWorker
    expectedType
    fields
    fieldIndices
    context
    hypothesesRev

def psCloseElabMatchFieldsWorker
    (metaContext : PsMetaContext)
    (fields : List PsElabMatchField) :
    PsExpr -> PsExpr :=
  match fields with
  | [] =>
      fun (term : PsExpr) =>
        term
  | field :: rest =>
      let smaller : PsExpr -> PsExpr :=
        psCloseElabMatchFieldsWorker metaContext rest;
      fun (term : PsExpr) =>
        let closed :=
          PsExpr.lam
            field.name
            (psMetaInstantiate metaContext field.type)
            (psExprAbstractFVar field.id term)
            field.binder;
        smaller closed

def psCloseElabMatchFields
    (metaContext : PsMetaContext)
    (fields : List PsElabMatchField)
    (term : PsExpr) : PsExpr :=
  psCloseElabMatchFieldsWorker
    metaContext
    fields
    term

structure PsElabMatchMinorResult where
  context : PsElabContext
  term : PsExpr

def psElabWildcardBinderNamesWorker
    (span : PsSourceSpan)
    (remaining : Nat) :
    Nat -> List PsSyntaxName :=
  match remaining with
  | 0 =>
      fun (_index : Nat) =>
        []
  | nextRemaining + 1 =>
      fun (index : Nat) =>
        let smaller : Nat -> List PsSyntaxName :=
          psElabWildcardBinderNamesWorker
            span
            nextRemaining;
        let segment :=
          String.Internal.append "_wild" (psNatToString index);
        let syntaxName : PsSyntaxName := {
          segments := List.cons segment List.nil
          span := span
        };
        List.cons
          syntaxName
          (smaller (Nat.succ index))

def psElabWildcardBinderNames
    (span : PsSourceSpan)
    (index : Nat)
    (remaining : Nat) :
    List PsSyntaxName :=
  psElabWildcardBinderNamesWorker
    span
    remaining
    index

def psElabMatchFieldListReverseWorker
    (fields : List PsElabMatchField) :
    List PsElabMatchField -> List PsElabMatchField :=
  match fields with
  | [] =>
      fun (acc : List PsElabMatchField) =>
        acc
  | field :: rest =>
      let smaller :
          List PsElabMatchField -> List PsElabMatchField :=
        psElabMatchFieldListReverseWorker rest;
      fun (acc : List PsElabMatchField) =>
        smaller (List.cons field acc)

def psElabMatchFieldListReverse
    (fields : List PsElabMatchField) :
    List PsElabMatchField :=
  psElabMatchFieldListReverseWorker fields []
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
      let binders : List PsSyntaxName :=
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
                  psElabMatchFieldListReverse fieldResult.fieldsRev;
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
                        (psElabContextAfterStructuralFields hypotheses.context)
                        body
                        (Option.some expectedType) with
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
      match elaborate context alternative.body (Option.some expectedType) with
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
        Option.none
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
        (Option.some binders)

structure PsElabMatchMinorsResult where
  context : PsElabContext
  minors : List PsExpr

def psElabMatchMinorsWorker
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
    (constructorNames : List PsName) :
    PsElabContext ->
    Except PsElabError PsElabMatchMinorsResult :=
  match constructorNames with
  | [] =>
      fun (context : PsElabContext) =>
        Except.ok {
          context := context
          minors := []
        }
  | ctorName :: rest =>
      let smaller :
          PsElabContext ->
          Except PsElabError PsElabMatchMinorsResult :=
        psElabMatchMinorsWorker
          elaborate
          inductiveInfo
          inductiveLevels
          parameterArgs
          expectedType
          alternatives
          rest;
      fun (context : PsElabContext) =>
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
                match smaller minor.context with
                | Except.error error => Except.error error
                | Except.ok tail =>
                    Except.ok {
                      context := tail.context
                      minors := List.cons minor.term tail.minors
                    }

-- Refine only the whole structural match, after every minor has contributed
-- its meta solutions. Reopen exactly the constructor fields, replace the major
-- through the remaining term (including IH lambdas), and close the same IDs.
def psElabRefineStructuralMinor
    (majorId fieldCount : Nat) (context : PsLocalContext)
    (constructorValue minor : PsExpr) : Except PsElabError PsExpr :=
  match fieldCount with
  | Nat.zero =>
      Except.ok (psExprInstantiate1 (psExprAbstractFVar majorId minor) constructorValue)
  | Nat.succ remaining =>
      match minor with
      | PsExpr.lam name domain body binder =>
          let pushed := psLocalPushBinding context name domain binder;
          match psElabRefineStructuralMinor majorId remaining pushed.context
              (PsExpr.app constructorValue (PsExpr.fvar pushed.id))
              (psExprInstantiate1 body (PsExpr.fvar pushed.id)) with
          | Except.error error => Except.error error
          | Except.ok refined =>
              Except.ok (PsExpr.lam name domain
                (psExprAbstractFVar pushed.id refined) binder)
      | _ => Except.error PsElabError.structuralRecursionInternal

def psElabRefineStructuralMinors
    (context : PsElabContext) (majorId : Nat)
    (inductiveLevels : List PsLevel) (parameterArgs : List PsExpr)
    (constructorNames : List PsName) (minors : List PsExpr) :
    Except PsElabError (List PsExpr) :=
  match constructorNames with
  | List.nil =>
      match minors with
      | List.nil => Except.ok List.nil
      | _ => Except.error PsElabError.structuralRecursionInternal
  | List.cons constructorName rest =>
      match minors with
      | List.nil => Except.error PsElabError.structuralRecursionInternal
      | List.cons minor tail =>
          match psEnvironmentFindConstructor context.environment constructorName with
          | Option.none => Except.error PsElabError.structuralRecursionInternal
          | Option.some constructorInfo =>
              let constructorValue := psMetaInstantiate context.metaContext
                (psExprApplyMany (PsExpr.constE constructorName inductiveLevels) parameterArgs);
              match psElabRefineStructuralMinor majorId constructorInfo.numFields
                  context.localContext constructorValue (psMetaInstantiate context.metaContext minor) with
              | Except.error error => Except.error error
              | Except.ok refined =>
                  match psElabRefineStructuralMinors context majorId
                      inductiveLevels parameterArgs rest tail with
                  | Except.error error => Except.error error
                  | Except.ok refinedTail => Except.ok (List.cons refined refinedTail)

def psElabRefineStructuralMatch
    (inductiveLevels : List PsLevel) (parameterArgs : List PsExpr)
    (constructorNames : List PsName) (result : PsElabMatchMinorsResult) :
    Except PsElabError PsElabMatchMinorsResult :=
  match result.context.structuralRecursion with
  | Option.none => Except.ok result
  | Option.some recursion =>
      if recursion.collectCalls then
        match psElabCheckStructuralTelescope result.context recursion with
        -- An actual recursive call refuses these errors before returning its IH.
        -- Nonrecursive dependent/Prop matches retain their constant motive.
        | Except.error _ => Except.ok result
        | Except.ok majorId =>
            match psElabRefineStructuralMinors result.context majorId
                inductiveLevels parameterArgs constructorNames result.minors with
            | Except.error error => Except.error error
            | Except.ok minors =>
                Except.ok (PsElabMatchMinorsResult.mk result.context minors)
      else Except.ok result

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
  match psElabMatchMinorsWorker
      elaborate
      inductiveInfo
      inductiveLevels
      parameterArgs
      expectedType
      alternatives
      constructorNames
      context with
  | Except.error error => Except.error error
  | Except.ok result =>
      psElabRefineStructuralMatch inductiveLevels parameterArgs constructorNames result

def psElabExprListAppendWorker
    (values : List PsExpr) :
    List PsExpr -> List PsExpr :=
  match values with
  | [] =>
      fun (right : List PsExpr) =>
        right
  | value :: rest =>
      let smaller : List PsExpr -> List PsExpr :=
        psElabExprListAppendWorker rest;
      fun (right : List PsExpr) =>
        List.cons value (smaller right)

def psElabExprListAppend
    (left : List PsExpr)
    (right : List PsExpr) :
    List PsExpr :=
  psElabExprListAppendWorker left right

-- The declaration's root match has one permission to establish its IH map.
-- Nested matches retain existing root-child identities but cannot create aliases
-- from a different recurrence, even when the result types happen to agree.
def psElabStructuralMatchContext
    (context : PsElabContext) (scrutinee expectedType : PsExpr) : PsElabContext :=
  match context.structuralRecursion with
  | Option.none => context
  | Option.some recursion =>
      let sameResult := psExprAlphaEq
        (psMetaInstantiate context.metaContext expectedType)
        (psMetaInstantiate context.metaContext recursion.resultType);
      let permitted : Bool :=
        if recursion.collectCalls then
          if sameResult then
            match scrutinee with
            | PsExpr.fvar id =>
                match psElabStructuralParameterAt
                    recursion.explicitParameterIds recursion.recursiveParameterIndex with
                | Option.none => false
                | Option.some majorId => Nat.beq id majorId
            | _ => false
          else false
        else false;
      psElabContextWithStructuralRecursion context
        (Option.some (PsElabStructuralRecursion.mk
          recursion.functionName recursion.parameterIds recursion.explicitParameterIds
          recursion.recursiveParameterIndex recursion.calls recursion.resultType permitted))

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
      match elaborate context scrutineeSyntax Option.none with
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
                                            (psElabStructuralMatchContext
                                              scrutineeResult.context
                                              scrutineeResult.term
                                              instantiatedExpected)
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
                                              psElabExprListAppend
                                                minors.minors
                                                (List.cons
                                                  scrutineeResult.term
                                                  List.nil);
                                            let recursorArgs :=
                                              psElabExprListAppend
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
                                              (Option.some instantiatedExpected)
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

def psElabApplyArgsWithFuelWorker
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (remainingFuel : Nat) :
    PsElabTermResult ->
    List PsSyntaxTerm ->
    List Nat ->
    Except PsElabError PsElabApplicationResult :=
  match remainingFuel with
  | 0 =>
      fun (_current : PsElabTermResult) =>
        fun (_arguments : List PsSyntaxTerm) =>
          fun (_pendingInstancesRev : List Nat) =>
            Except.error PsElabError.fuelExhausted
  | fuel + 1 =>
      fun (current : PsElabTermResult) =>
        fun (arguments : List PsSyntaxTerm) =>
          fun (pendingInstancesRev : List Nat) =>
            let smaller :
                PsElabTermResult ->
                List PsSyntaxTerm ->
                List Nat ->
                Except PsElabError PsElabApplicationResult :=
              psElabApplyArgsWithFuelWorker elaborate fuel;
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
                          (Option.some domain) with
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
                          smaller
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
                  let nextPending : List Nat :=
                    if psBinderIsInstanceImplicit binder then
                      match fresh.expr with
                      | PsExpr.mvar id =>
                          List.cons id pendingInstancesRev
                      | _ => pendingInstancesRev
                    else
                      pendingInstancesRev;
                  smaller
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
                  Except.error
                    (PsElabError.infer PsInferError.expectedFunction)

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
  psElabApplyArgsWithFuelWorker
    elaborate
    remainingFuel
    current
    arguments
    pendingInstancesRev

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

def psElabSolvePendingInstancesWorker
    (pendingInstances : List Nat) :
    PsElabTermResult ->
    Except PsElabError PsElabTermResult :=
  match pendingInstances with
  | [] =>
      fun (current : PsElabTermResult) =>
        let metaContext := current.context.metaContext;
        Except.ok {
          context := current.context
          term := psMetaInstantiate metaContext current.term
          type := psMetaInstantiate metaContext current.type
        }
  | id :: rest =>
      let smaller :
          PsElabTermResult ->
          Except PsElabError PsElabTermResult :=
        psElabSolvePendingInstancesWorker rest;
      fun (current : PsElabTermResult) =>
        let metaContext := current.context.metaContext;
        match psMetaFindAssignment metaContext id with
        | some _ =>
            smaller current
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
                          smaller assignedResult

def psElabSolvePendingInstances
    (current : PsElabTermResult)
    (pendingInstances : List Nat) :
    Except PsElabError PsElabTermResult :=
  psElabSolvePendingInstancesWorker
    pendingInstances
    current

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

def psElabDropForallBindersWorker
    (remaining : Nat) :
    PsExpr -> Option PsExpr :=
  match remaining with
  | 0 =>
      fun (type : PsExpr) =>
        Option.some type
  | nextRemaining + 1 =>
      fun (type : PsExpr) =>
        let smaller : PsExpr -> Option PsExpr :=
          psElabDropForallBindersWorker nextRemaining;
        match type with
        | .forallE _ _ body _ =>
            smaller body
        | _ => Option.none

def psElabDropForallBinders
    (remaining : Nat)
    (type : PsExpr) : Option PsExpr :=
  psElabDropForallBindersWorker
    remaining
    type

def psElabTakeForallNamesWorker
    (remaining : Nat) :
    PsExpr -> Option (List String) :=
  match remaining with
  | 0 =>
      fun (_type : PsExpr) =>
        Option.some []
  | nextRemaining + 1 =>
      fun (type : PsExpr) =>
        let smaller : PsExpr -> Option (List String) :=
          psElabTakeForallNamesWorker nextRemaining;
        match type with
        | .forallE name _ body _ =>
            match smaller body with
            | none => Option.none
            | some rest =>
                Option.some
                  (List.cons (psNameLastComponent name) rest)
        | _ => Option.none

def psElabTakeForallNames
    (remaining : Nat)
    (type : PsExpr) : Option (List String) :=
  psElabTakeForallNamesWorker
    remaining
    type

def psSyntaxRecordLastSegment
    (segments : List String) : Option String :=
  match segments with
  | [] =>
      Option.none
  | first :: rest =>
      match rest with
      | [] =>
          Option.some first
      | _ :: _ =>
          psSyntaxRecordLastSegment rest

def psSyntaxRecordFieldName
    (field : Prod PsSyntaxName PsSyntaxTerm) :
    Option String :=
  let syntaxName := Prod.fst field;
  psSyntaxRecordLastSegment syntaxName.segments

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
  match fields with
  | [] =>
      false
  | field :: rest =>
      if psSyntaxRecordFieldMatchesName name field then
        true
      else
        psSyntaxRecordHasField rest name

def psSyntaxRecordHasNamedField
    (fields : List (Prod PsSyntaxName PsSyntaxTerm))
    (name : String) : Bool :=
  psSyntaxRecordHasField fields name

def psSyntaxRecordFieldsMatchWorker
    (names : List String) :
    List (Prod PsSyntaxName PsSyntaxTerm) -> Bool :=
  match names with
  | [] =>
      fun (_fields : List (Prod PsSyntaxName PsSyntaxTerm)) =>
        true
  | name :: rest =>
      let smaller :
          List (Prod PsSyntaxName PsSyntaxTerm) -> Bool :=
        psSyntaxRecordFieldsMatchWorker rest;
      fun (fields : List (Prod PsSyntaxName PsSyntaxTerm)) =>
        if psSyntaxRecordHasNamedField fields name then
          smaller fields
        else
          false

def psSyntaxRecordFieldsMatch
    (fields :
      List (Prod PsSyntaxName PsSyntaxTerm))
    (names : List String) : Bool :=
  psElabBoolAnd
    (Nat.beq (psElabListLength fields) (psElabListLength names))
    (psSyntaxRecordFieldsMatchWorker names fields)

def psSyntaxRecordFindField
    (fields : List (Prod PsSyntaxName PsSyntaxTerm))
    (name : String) :
    Option PsSyntaxTerm :=
  match fields with
  | [] =>
      Option.none
  | field :: rest =>
      match psSyntaxRecordFieldName field with
      | Option.some fieldName =>
          if psStringEq fieldName name then
            Option.some (Prod.snd field)
          else
            psSyntaxRecordFindField rest name
      | Option.none =>
          psSyntaxRecordFindField rest name

def psSyntaxRecordOrderFields
    (fields : List (Prod PsSyntaxName PsSyntaxTerm))
    (names : List String) :
    Option (List PsSyntaxTerm) :=
  match names with
  | [] =>
      Option.some []
  | name :: rest =>
      match psSyntaxRecordFindField fields name with
      | Option.none =>
          Option.none
      | Option.some value =>
          match psSyntaxRecordOrderFields fields rest with
          | Option.none =>
              Option.none
          | Option.some values =>
              Option.some (List.cons value values)

def psElabRecordCandidateForInfo
    (environment : PsEnvironment)
    (info : PsInductiveInfo) :
    Option PsElabRecordCandidate :=
  if info.isStructure then
    match info.constructors with
    | [] =>
        Option.none
    | constructorName :: rest =>
        match rest with
        | [] =>
            match
                psEnvironmentFindConstructor
                  environment
                  constructorName with
            | Option.none => Option.none
            | Option.some constructorInfo =>
                match
                    psElabDropForallBinders
                      constructorInfo.numParams
                      constructorInfo.type with
                | Option.none => Option.none
                | Option.some fieldsType =>
                    match
                        psElabTakeForallNames
                          constructorInfo.numFields
                          fieldsType with
                    | Option.none => Option.none
                    | Option.some fieldNames =>
                        Option.some {
                          constructorName := constructorName
                          fieldNames := fieldNames
                        }
        | _ :: _ =>
            Option.none
  else
    Option.none

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
      | Option.none => Option.none
      | Option.some info =>
          if psElabNatNe (psElabListLength view.args) info.numParams then
            Option.none
          else
            psElabRecordCandidateForInfo
              context.environment
              info
  | _ => Option.none

def psElabRecordCandidates
    (environment : PsEnvironment)
    (fields : List (Prod PsSyntaxName PsSyntaxTerm))
    (declarations : List PsDeclaration)
    (candidatesRev : List PsElabRecordCandidate) :
    List PsElabRecordCandidate :=
  match declarations with
  | [] =>
      candidatesRev
  | declaration :: rest =>
      let candidates :=
        psElabRecordCandidates
          environment
          fields
          rest
          candidatesRev;
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
                List.cons candidate candidates
              else
                candidates
          | none =>
              candidates
      | _ =>
          candidates

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
      Option.none
  | candidate :: rest =>
      match rest with
      | [] => Option.some candidate
      | _ :: _ => Option.none

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
  let candidate : Option PsElabRecordCandidate :=
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
              Option.some found
            else
              Option.none
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
                Option.none with
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
      | Option.none => Option.none
      | Option.some name =>
          match
              psResolveName
                context.localContext
                context.environment
                name with
          | Option.none => Option.none
          | Option.some resolved =>
              match resolved with
              | .local id => Option.some id
              | .global _ => Option.none
  | _ => Option.none

def psElabNatListAtWorker
    (index : Nat) :
    List Nat -> Option Nat :=
  match index with
  | 0 =>
      fun (values : List Nat) =>
        match values with
        | [] =>
            Option.none
        | value :: _ =>
            Option.some value
  | nextIndex + 1 =>
      fun (values : List Nat) =>
        let smaller :
            List Nat -> Option Nat :=
          psElabNatListAtWorker nextIndex;
        match values with
        | [] =>
            Option.none
        | _ :: rest =>
            smaller rest

def psElabNatListAt
    (values : List Nat)
    (index : Nat) : Option Nat :=
  psElabNatListAtWorker
    index
    values
def psElabValidateStructuralCallWorker
    (arguments : List PsSyntaxTerm) :
    PsElabContext ->
    PsElabStructuralRecursion ->
    Nat ->
    Option Nat ->
    Except PsElabError Nat :=
  match arguments with
  | [] =>
      fun (context : PsElabContext) =>
        fun (recursion : PsElabStructuralRecursion) =>
          fun (index : Nat) =>
            fun (hypothesisId : Option Nat) =>
              match hypothesisId with
              | Option.some resolvedHypothesisId =>
                  Except.ok resolvedHypothesisId
              | Option.none =>
                  Except.error PsElabError.structuralRecursionInternal
  | argument :: rest =>
      let smaller :
          PsElabContext ->
          PsElabStructuralRecursion ->
          Nat ->
          Option Nat ->
          Except PsElabError Nat :=
        psElabValidateStructuralCallWorker rest;
      fun (context : PsElabContext) =>
        fun (recursion : PsElabStructuralRecursion) =>
          fun (index : Nat) =>
            fun (hypothesisId : Option Nat) =>
              match psElabSyntaxLocalId context argument with
              | Option.none =>
                  if Nat.beq index recursion.recursiveParameterIndex then
                    Except.error PsElabError.structuralRecursionNotDecreasing
                  else
                    Except.error PsElabError.structuralRecursionInvariantArgument
              | Option.some argumentId =>
                  if Nat.beq index recursion.recursiveParameterIndex then
                    match
                        psElabStructuralRecursionFindCall
                          recursion.calls
                          argumentId with
                    | Option.none =>
                        Except.error PsElabError.structuralRecursionNotDecreasing
                    | Option.some nextHypothesisId =>
                        smaller
                          context
                          recursion
                          (Nat.succ index)
                          (Option.some nextHypothesisId)
                  else
                    match
                        psElabNatListAt
                          recursion.explicitParameterIds
                          index with
                    | Option.none =>
                        Except.error PsElabError.structuralRecursionArity
                    | Option.some originalId =>
                        if Nat.beq argumentId originalId then
                          smaller
                            context
                            recursion
                            (Nat.succ index)
                            hypothesisId
                        else
                          Except.error
                            PsElabError.structuralRecursionInvariantArgument

def psElabValidateStructuralCall
    (context : PsElabContext)
    (recursion : PsElabStructuralRecursion)
    (index : Nat)
    (arguments : List PsSyntaxTerm)
    (hypothesisId : Option Nat) :
    Except PsElabError Nat :=
  psElabValidateStructuralCallWorker
    arguments
    context
    recursion
    index
    hypothesisId
def psElabStructuralNameIsLocal (context : PsElabContext) (name : PsName) : Bool :=
  match psLocalFindUser context.localContext name with
  | Option.none => false
  | Option.some _ => true

def psTryElabStructuralSelfCall
    (context : PsElabContext)
    (fn : PsSyntaxTerm)
    (arguments : List PsSyntaxTerm)
    (expected : Option PsExpr) :
    Except PsElabError (Option PsElabTermResult) :=
  match context.structuralRecursion with
  | Option.none =>
      Except.ok Option.none
  | Option.some recursion =>
      match fn with
      | .reference sourceName =>
          match psSyntaxNameToName sourceName with
          | Option.some calledName =>
              if psElabBoolNot (psNameEq calledName recursion.functionName) then
                Except.ok Option.none
              else if psElabStructuralNameIsLocal context calledName then
                Except.ok Option.none
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
                      Option.none with
                | Except.error error => Except.error error
                | Except.ok hypothesisId =>
                    match psElabCheckStructuralTelescope context recursion with
                    | Except.error error => Except.error error
                    | Except.ok _ =>
                        match
                            psElabResolvedTerm
                              context
                              (PsExpr.fvar hypothesisId)
                              expected with
                        | Except.error error => Except.error error
                        | Except.ok result => Except.ok (Option.some result)
          | Option.none => Except.ok Option.none
      | _ =>
          Except.ok Option.none

def psElabStructuralReferenceEscapes
    (context : PsElabContext) (sourceName : PsSyntaxName) : Bool :=
  match context.structuralRecursion with
  | Option.none => false
  | Option.some recursion =>
      match psSyntaxNameToName sourceName with
      | Option.none => false
      | Option.some name =>
          if psNameEq name recursion.functionName then
            match psLocalFindUser context.localContext name with
            | Option.none => true
            | Option.some _ => false
          else false

def psElabTermWithFuel
    (fuel : Nat) :
    PsElabContext ->
    PsSyntaxTerm ->
    Option PsExpr ->
    Except PsElabError PsElabTermResult :=
  match fuel with
  | 0 =>
      fun (_context : PsElabContext) =>
        fun (_term : PsSyntaxTerm) =>
          fun (_expected : Option PsExpr) =>
            Except.error PsElabError.fuelExhausted
  | remaining + 1 =>
      fun (context : PsElabContext) =>
        fun (term : PsSyntaxTerm) =>
          fun (expected : Option PsExpr) =>
            let smaller :
                PsElabContext ->
                PsSyntaxTerm ->
                Option PsExpr ->
                Except PsElabError PsElabTermResult :=
              psElabTermWithFuel remaining;
            match term with
            | .reference name =>
                if psElabStructuralReferenceEscapes context name then
                  Except.error PsElabError.structuralRecursionEscapingReference
                else
                  match psElabReference context name Option.none with
                  | Except.error error => Except.error error
                  | Except.ok reference =>
                      match psElabApplyArgs
                          smaller
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
                  smaller
                  context
                  fields
                  expected
            | .bool value _ =>
                psElabBool context value expected
            | .lambda binders body _ =>
                psElabLambda
                  smaller
                  context
                  binders
                  body
                  expected
            | .forallE binders body _ =>
                psElabForall
                  smaller
                  context
                  binders
                  body
                  expected
            | .letE name declaredType value body _ =>
                psElabLet
                  smaller
                  context
                  name
                  declaredType
                  value
                  body
                  expected
            | .ifE condition thenBranch elseBranch _ =>
                psElabIf
                  smaller
                  context
                  condition
                  thenBranch
                  elseBranch
                  expected
            | .matchE scrutinee alternatives _ =>
                psElabMatch
                  smaller
                  context
                  scrutinee
                  alternatives
                  expected
            | .app fn args _ =>
                -- R3 empty calls request argument completion. This bounded
                -- profile has no optional/default parameter metadata yet.
                -- Keep [] distinct from an explicit Unit argument and fail closed.
                match args with
                | List.nil => Except.error PsElabError.emptyCallUnsupported
                | List.cons _ _ =>
                    match
                        psTryElabStructuralSelfCall
                          context
                          fn
                          args
                          expected with
                    | Except.error error => Except.error error
                    | Except.ok selfCall =>
                        match selfCall with
                        | Option.some result => Except.ok result
                        | Option.none =>
                            match smaller context fn Option.none with
                            | Except.error error => Except.error error
                            | Except.ok elaboratedFn =>
                                match psElabApplyArgs
                                    smaller
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
