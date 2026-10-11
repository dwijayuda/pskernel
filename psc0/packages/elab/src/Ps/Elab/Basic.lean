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
  | invalidArgument (message : String)
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

-- Shared bidirectional operations. Holes remain ordinary scoped metavariables;
-- declaration completion rejects every unresolved term or universe metavariable.
abbrev PsElaborator :=
  PsElabContext → PsSyntaxTerm → Option PsExpr → Except PsElabError PsElabTermResult

structure PsElabTypeResult where
  context : PsElabContext
  type : PsExpr

def psElabFreshType (context : PsElabContext) : PsElabTypeResult :=
  let level := psMetaFreshLevel context.metaContext
  let fresh := psMetaFresh level.context context.localContext (.sortE level.level) .natural
  { context := psElabContextWithMeta context fresh.context, type := fresh.expr }

def psElabHole (context : PsElabContext) (expected : Option PsExpr) : PsElabTermResult :=
  let target := match expected with
    | some type => PsElabTypeResult.mk context type
    | none => psElabFreshType context
  let fresh := psMetaFresh target.context.metaContext target.context.localContext target.type .natural
  { context := psElabContextWithMeta target.context fresh.context
    term := fresh.expr
    type := target.type }

def psElabType (elaborate : PsElaborator) (context : PsElabContext)
    (source : PsSyntaxTerm) : Except PsElabError PsElabTypeResult := do
  match source with
  | .hole _ => return psElabFreshType context
  | _ =>
    let result ← elaborate context source none
    let _ ← (psInferEnsureSort result.context.environment result.context.metaContext
      result.context.localContext result.type).mapError PsElabError.infer
    return { context := result.context, type := result.term }

def psElabAscription (elaborate : PsElaborator) (context : PsElabContext)
    (value type : PsSyntaxTerm) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult := do
  let annotation ← psElabType elaborate context type
  let result ← elaborate annotation.context value (some annotation.type)
  psElabFinalizeExpected result expected
