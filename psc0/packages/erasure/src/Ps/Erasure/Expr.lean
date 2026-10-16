import Ps.Erasure.Recursion
import Ps.Erasure.Array
import Ps.Erasure.Float
import Ps.Erasure.Platform
import Ps.Erasure.Utf8
import Ps.CompilerIr.CheckTypes
import Ps.Meta.TypeView

structure PsErasureAppliedArguments where
  typeArgumentsRev : List PsVerifiedIrType
  runtimeArgumentsRev : List PsVerifiedIrExpr
  runtimeArgumentTypesRev : List PsExpr
  remainingType : PsExpr

def psErasureAppendRuntimeArgument
    (arguments : List PsVerifiedIrExpr) :
    PsVerifiedIrExpr -> List PsVerifiedIrExpr :=
  match arguments with
  | [] => fun (argument : PsVerifiedIrExpr) => List.cons argument List.nil
  | head :: rest =>
      let smaller : PsVerifiedIrExpr -> List PsVerifiedIrExpr :=
        psErasureAppendRuntimeArgument rest;
      fun (argument : PsVerifiedIrExpr) => List.cons head (smaller argument)

-- Calls use the declaration's binder mask. Reclassifying the instantiated
-- telescope changes the ABI when a Sort parameter specializes to Prop.
def psErasureInstantiatedEntryBinder (environment : PsEnvironment)
    (scope : PsErasureScope) (kind : PsErasedBinderKind) (domain : PsExpr) :
    PsErasedBinderKind :=
  match kind with
  | .runtime =>
    if psErasureIsProp environment scope.localContext domain then .proof else .runtime
  | _ => kind

def psEraseApplicationArgumentsWorker
    (erase : PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (environment : PsEnvironment) (scope : PsErasureScope)
    (arguments : List (PsExpr × PsErasedBinderKind)) :
    PsExpr -> PsErasureAppliedArguments -> Except PsErasureError PsErasureAppliedArguments :=
  match arguments with
  | [] => fun functionType state => .ok { state with remainingType := functionType }
  | (argument, kind) :: rest =>
    let smaller := psEraseApplicationArgumentsWorker erase environment scope rest
    fun functionType state =>
      match psWhnf environment psMetaEmpty scope.localContext functionType with
      | .forallE _ domain body _ =>
        let remainingType := psExprInstantiate1 body argument
        match psErasureInstantiatedEntryBinder environment scope kind domain with
        | .index => smaller remainingType state
        | .type => do
          let erasedType ← psEraseRuntimeType environment scope argument
          smaller remainingType { state with
            typeArgumentsRev := erasedType :: state.typeArgumentsRev }
        | .proof =>
          smaller remainingType { state with
            runtimeArgumentsRev := psErasureProofSlotValue :: state.runtimeArgumentsRev
            runtimeArgumentTypesRev := .constE psUnitName [] :: state.runtimeArgumentTypesRev }
        | .runtime => do
          let erasedArgument ← erase argument
          smaller remainingType { state with
            runtimeArgumentsRev := erasedArgument :: state.runtimeArgumentsRev
            runtimeArgumentTypesRev := domain :: state.runtimeArgumentTypesRev }
      | _ => .error PsErasureError.unsupportedApplication

def psEraseApplicationArguments
    (erase : PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (environment : PsEnvironment) (scope : PsErasureScope)
    (functionType : PsExpr) (arguments : List PsExpr)
    (binders : List PsErasedBinderKind)
    (state : PsErasureAppliedArguments) : Except PsErasureError PsErasureAppliedArguments :=
  if arguments.length != binders.length then .error PsErasureError.binderMismatch
  else psEraseApplicationArgumentsWorker erase environment scope
    (psListZip arguments binders) functionType state

-- Captures are target bindings only. The supplied runtime domains are recorded
-- before each telescope substitution advances; proof slots use Unit, types are omitted.
structure PsErasureApplicationCaptureTypes where
  runtimeTypes : List PsExpr

structure PsErasureApplicationCaptureState where
  scope : PsErasureScope
  valuesRev : List PsVerifiedIrExpr
  bindingsRev : List (Prod PsVerifiedIrParameter PsVerifiedIrExpr)

def psErasureApplicationOperandIsValue (value : PsVerifiedIrExpr) : Bool :=
  match value with
  | PsVerifiedIrExpr.var _ => true
  | PsVerifiedIrExpr.literal _ => true
  | _ => false

def psErasureCaptureTypedApplicationValue
    (state : PsErasureApplicationCaptureState) (baseName : String)
    (runtimeType : PsVerifiedIrType) (value : PsVerifiedIrExpr) :
    Except PsErasureError PsErasureApplicationCaptureState :=
  let localName :=
    psErasureLocalName state.scope baseName baseName
      state.scope.localContext.nextId;
  if psErasureLocalNameUsed state.scope localName then
    Except.error PsErasureError.fuelExhausted
  else
    -- The completed scope includes every new eta parameter. Reserve
    -- each capture here without adding or changing a Core local.
    let reservedNames : PsErasureDeclarationNames :=
      { state.scope.declarationNames with
        byOutput := psErasureIndexInsert Bool state.scope.declarationNames.byOutput
          (PsName.str PsName.anonymous localName) true
        count := state.scope.declarationNames.count + 1 };
    let nextScope :=
      { state.scope with declarationNames := reservedNames };
    Except.ok
      (PsErasureApplicationCaptureState.mk nextScope
        (List.cons (PsVerifiedIrExpr.var localName) state.valuesRev)
        (List.cons
          (Prod.mk (PsVerifiedIrParameter.mk localName runtimeType) value)
          state.bindingsRev))

def psErasureCaptureApplicationValue
    (environment : PsEnvironment) (state : PsErasureApplicationCaptureState)
    (baseName : String) (type : Option PsExpr) (value : PsVerifiedIrExpr) :
    Except PsErasureError PsErasureApplicationCaptureState :=
  if psErasureApplicationOperandIsValue value then
    Except.ok
      (PsErasureApplicationCaptureState.mk state.scope
        (List.cons value state.valuesRev) state.bindingsRev)
  else
    match type with
    | Option.none => Except.error PsErasureError.unsupportedApplication
    | Option.some sourceType =>
        match psEraseRuntimeType environment state.scope sourceType with
        | Except.error error => Except.error error
        | Except.ok runtimeType =>
            psErasureCaptureTypedApplicationValue state baseName runtimeType value

def psErasureCaptureApplicationFunction
    (environment : PsEnvironment) (scope : PsErasureScope)
    (fn : PsVerifiedIrExpr) (captureTypes : Option PsErasureApplicationCaptureTypes)
    (parameters : List PsVerifiedIrParameter) (resultType : PsVerifiedIrType) :
    Except PsErasureError PsErasureApplicationCaptureState :=
  let initial :=
    PsErasureApplicationCaptureState.mk scope List.nil List.nil;
  -- A direct generic callee stays a variable with its original call type arguments.
  if psErasureApplicationOperandIsValue fn then
    Except.ok (PsErasureApplicationCaptureState.mk scope [fn] List.nil)
  else
    match captureTypes with
    | Option.none => Except.error PsErasureError.unsupportedApplication
    | Option.some types =>
        -- Reconstruct the runtime arrow with the same Unit proof slots and
        -- omitted type binders as the call; no unknown type or guessed cast.
        let eraseType : PsExpr -> Except PsErasureError PsVerifiedIrType :=
          fun (type : PsExpr) => psEraseRuntimeType environment scope type;
        match psListMapExcept eraseType types.runtimeTypes with
        | Except.error error => Except.error error
        | Except.ok suppliedTypes =>
            let parameterType : PsVerifiedIrParameter -> PsVerifiedIrType :=
              fun (parameter : PsVerifiedIrParameter) => parameter.type;
            let runtimeType :=
              PsVerifiedIrType.function
                (psListAppend suppliedTypes (psListMap parameterType parameters))
                resultType;
            psErasureCaptureTypedApplicationValue initial "_psAppFn" runtimeType fn

def psErasureCaptureApplicationArguments
    (environment : PsEnvironment) (arguments : List PsVerifiedIrExpr) :
    List PsExpr -> PsErasureApplicationCaptureState ->
    Except PsErasureError PsErasureApplicationCaptureState :=
  match arguments with
  | List.nil =>
      fun (types : List PsExpr) (state : PsErasureApplicationCaptureState) =>
        if psListIsEmpty types then Except.ok state
        else Except.error PsErasureError.binderMismatch
  | List.cons argument rest =>
      let smaller : List PsExpr -> PsErasureApplicationCaptureState ->
          Except PsErasureError PsErasureApplicationCaptureState :=
        psErasureCaptureApplicationArguments environment rest;
      fun (types : List PsExpr) (state : PsErasureApplicationCaptureState) =>
        let currentType : Option PsExpr :=
          match types with
          | List.nil => Option.none
          | List.cons type _ => Option.some type;
        let remainingTypes : List PsExpr :=
          match types with
          | List.nil => List.nil
          | List.cons _ tail => tail;
        match
            psErasureCaptureApplicationValue environment state "_psAppArg"
              currentType argument with
        | Except.error error => Except.error error
        | Except.ok captured => smaller remainingTypes captured

def psErasureWrapApplicationCaptures
    (bindingsRev : List (Prod PsVerifiedIrParameter PsVerifiedIrExpr)) :
    PsVerifiedIrExpr -> PsVerifiedIrExpr :=
  match bindingsRev with
  | List.nil => fun (body : PsVerifiedIrExpr) => body
  | List.cons binding rest =>
      let smaller : PsVerifiedIrExpr -> PsVerifiedIrExpr :=
        psErasureWrapApplicationCaptures rest;
      fun (body : PsVerifiedIrExpr) =>
        let parameter := Prod.fst binding;
        let value := Prod.snd binding;
        smaller
          (PsVerifiedIrExpr.letE parameter.name parameter.type value body)

-- Function values have one runtime parameter per arrow. Flat parameter groups
-- belong only to known declaration entries and explicit intrinsic ABI bridges.
def psErasureCurryParameters
    (parameters : List PsVerifiedIrParameter)
    (resultType : PsVerifiedIrType) (body : PsVerifiedIrExpr) :
    Prod PsVerifiedIrType PsVerifiedIrExpr :=
  match parameters with
  | List.nil => Prod.mk resultType body
  | List.cons parameter rest =>
      let tail := psErasureCurryParameters rest resultType body;
      Prod.mk
        (PsVerifiedIrType.function [parameter.type] (Prod.fst tail))
        (PsVerifiedIrExpr.lambda [parameter] (Prod.fst tail) (Prod.snd tail))

def psErasureCapturePartialApplication
    (environment : PsEnvironment) (scope : PsErasureScope)
    (fn : PsVerifiedIrExpr) (typeArguments : List PsVerifiedIrType)
    (runtimeArguments : List PsVerifiedIrExpr)
    (captureTypes : Option PsErasureApplicationCaptureTypes)
    (parameters : List PsVerifiedIrParameter) (resultType : PsVerifiedIrType) :
    Except PsErasureError PsVerifiedIrExpr :=
  let runtimeTypes : List PsExpr :=
    match captureTypes with
    | Option.none => List.nil
    | Option.some types => types.runtimeTypes;
  match
      psErasureCaptureApplicationFunction environment scope fn captureTypes
        parameters resultType with
  | Except.error error => Except.error error
  | Except.ok capturedFn =>
      match
          psErasureCaptureApplicationArguments environment runtimeArguments
            runtimeTypes capturedFn with
      | Except.error error => Except.error error
      | Except.ok captured =>
          match psListReverse captured.valuesRev with
          | List.nil => Except.error PsErasureError.binderMismatch
          | List.cons called arguments =>
              let body :=
                PsVerifiedIrExpr.call called typeArguments arguments;
              Except.ok
                (psErasureWrapApplicationCaptures captured.bindingsRev
                  (Prod.snd (psErasureCurryParameters parameters resultType body)))

def psErasureDropPrefix
    (alpha : Type) (count : Nat) (values : List alpha) : List alpha :=
  match count with
  | Nat.zero => values
  | Nat.succ remaining =>
      match values with
      | List.nil => List.nil
      | List.cons _ rest => psErasureDropPrefix alpha remaining rest

def psErasureApplyCoreArguments
    (head : PsExpr) (arguments : List PsExpr) : PsExpr :=
  match arguments with
  | List.nil => head
  | List.cons argument rest =>
      psErasureApplyCoreArguments (PsExpr.app head argument) rest

def psErasureApplyCoreType
    (environment : PsEnvironment) (scope : PsErasureScope)
    (functionType : PsExpr) (arguments : List PsExpr) :
    Except PsErasureError PsExpr :=
  match arguments with
  | List.nil => Except.ok functionType
  | List.cons argument rest =>
      match psWhnf environment psMetaEmpty scope.localContext functionType with
      | PsExpr.forallE _ _ body _ =>
          psErasureApplyCoreType environment scope
            (psExprInstantiate1 body argument) rest
      | _ => Except.error PsErasureError.unsupportedApplication

-- This is an annotation view of already checked, prepared Core, not admission.
-- Applications retain the actual callee Pi and instantiate its body; they do not
-- repeat argument checking with the conservative read-only universe comparison.
-- Ordinary leaves and projection metadata keep the existing inference checks.
def psErasureCheckedTypeViewWithFuel
    (environment : PsEnvironment) (fuel : Nat)
    (localContext : PsLocalContext) (expr : PsExpr) :
    Except PsErasureError PsExpr :=
  (psExprTypeViewWithFuel environment fuel localContext expr).mapError
    (fun _ => PsErasureError.unsupportedRuntimeTerm)

def psErasureCheckedTypeView
    (environment : PsEnvironment) (localContext : PsLocalContext) (expr : PsExpr) :
    Except PsErasureError PsExpr :=
  psErasureCheckedTypeViewWithFuel environment 4096 localContext expr

-- A local/computed function and an entry's returned function are unary values.
-- Ending the supplied spine returns that value; it never completes result arrows.
def psEraseCanonicalArguments
    (erase : PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (environment : PsEnvironment) (scope : PsErasureScope)
    (fn : PsVerifiedIrExpr) (functionType : PsExpr) (arguments : List PsExpr) :
    Except PsErasureError PsVerifiedIrExpr :=
  match arguments with
  | List.nil => Except.ok fn
  | List.cons argument rest =>
      match psWhnf environment psMetaEmpty scope.localContext functionType with
      | PsExpr.forallE _ domain body _ =>
          match psErasureClassifyBinder environment scope.localContext domain with
          | PsErasedBinderKind.type | PsErasedBinderKind.index =>
              Except.error PsErasureError.unsupportedApplication
          | PsErasedBinderKind.proof =>
              psEraseCanonicalArguments erase environment scope
                (.call fn [] [psErasureProofSlotValue])
                (psExprInstantiate1 body argument) rest
          | PsErasedBinderKind.runtime =>
              match erase argument with
              | Except.error error => Except.error error
              | Except.ok value =>
                  psEraseCanonicalArguments erase environment scope
                    (PsVerifiedIrExpr.call fn List.nil [value])
                    (psExprInstantiate1 body argument) rest
      | _ => Except.error PsErasureError.unsupportedApplication

def psErasureEntryCall
    (fn : PsVerifiedIrExpr) (typeArguments : List PsVerifiedIrType)
    (runtimeArguments : List PsVerifiedIrExpr) (unitTransport : Bool) :
    PsVerifiedIrExpr :=
  if psListIsEmpty runtimeArguments then
    if unitTransport then
      PsVerifiedIrExpr.call fn typeArguments
        [PsVerifiedIrExpr.literal PsVerifiedIrLiteral.unit]
    else fn
  else PsVerifiedIrExpr.call fn typeArguments runtimeArguments

-- Only the unconsumed original entry slots can create completion parameters.
-- The instantiated result type may itself be a function; it remains the result.
def psEraseFinishEntryWithFuel
    (environment : PsEnvironment) (fn : PsVerifiedIrExpr)
    (typeArguments : List PsVerifiedIrType) (unitTransport : Bool)
    (fuel : Nat) (scope : PsErasureScope) (functionType : PsExpr)
    (binders : List PsErasedBinderKind)
    (parametersRev : List PsVerifiedIrParameter)
    (runtimeArguments : List PsVerifiedIrExpr)
    (captureTypes : PsErasureApplicationCaptureTypes) :
    Except PsErasureError PsVerifiedIrExpr :=
  match fuel with
  | Nat.zero => Except.error PsErasureError.fuelExhausted
  | Nat.succ remaining =>
      match binders with
      | List.nil =>
          match psListReverse parametersRev with
          | List.nil =>
              Except.ok
                (psErasureEntryCall fn typeArguments runtimeArguments unitTransport)
          | List.cons parameter rest =>
              match psEraseRuntimeType environment scope functionType with
              | Except.error error => Except.error error
              | Except.ok resultType =>
                  psErasureCapturePartialApplication
                    environment scope fn typeArguments runtimeArguments
                    (Option.some captureTypes) (List.cons parameter rest) resultType
      | List.cons kind rest =>
          match psWhnf environment psMetaEmpty scope.localContext functionType with
          | PsExpr.forallE name domain body binder =>
              match psErasureInstantiatedEntryBinder environment scope kind domain with
              | PsErasedBinderKind.type | PsErasedBinderKind.index =>
                  Except.error PsErasureError.unsupportedApplication
              | PsErasedBinderKind.proof =>
                  let pushed := psLocalPushBinding scope.localContext name domain binder
                  let (parameter, nextScope) := psErasureOpenProofSlot scope pushed.context pushed.id
                  psEraseFinishEntryWithFuel environment fn typeArguments unitTransport
                    remaining nextScope (psExprInstantiate1 body (.fvar pushed.id))
                    rest (parameter :: parametersRev)
                    (psErasureAppendRuntimeArgument runtimeArguments psErasureProofSlotValue)
                    captureTypes
              | PsErasedBinderKind.runtime =>
                  match psEraseRuntimeType environment scope domain with
                  | Except.error error => Except.error error
                  | Except.ok parameterType =>
                      let pushed :=
                        psLocalPushBinding scope.localContext name domain binder;
                      let parameterName :=
                        psErasureLocalName scope (psNameToString name) "arg" pushed.id;
                      if psErasureLocalNameUsed scope parameterName then
                        Except.error PsErasureError.fuelExhausted
                      else
                        let nextScope : PsErasureScope := { scope with
                          localContext := pushed.context
                          runtimeLocals :=
                            List.cons (Prod.mk pushed.id parameterName) scope.runtimeLocals
                          typeLocals := scope.typeLocals
                          erasedLocals := scope.erasedLocals
                          declarationNames := scope.declarationNames
                          runtimeConstructors := scope.runtimeConstructors
                          runtimeRecursors := scope.runtimeRecursors
                          runtimeStructures := scope.runtimeStructures
                          runtimeStructureConstructors := scope.runtimeStructureConstructors
                          runtimeExpressions := scope.runtimeExpressions
                          currentDefinition := scope.currentDefinition
                        };
                        psEraseFinishEntryWithFuel environment fn typeArguments unitTransport
                          remaining nextScope (psExprInstantiate1 body (PsExpr.fvar pushed.id))
                          rest
                          (List.cons (PsVerifiedIrParameter.mk parameterName parameterType) parametersRev)
                          (psErasureAppendRuntimeArgument runtimeArguments
                            (PsVerifiedIrExpr.var parameterName))
                          captureTypes
          | _ => Except.error PsErasureError.binderMismatch

def psEraseKnownEntryApplication
    (erase : PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (environment : PsEnvironment) (scope : PsErasureScope)
    (fn : PsVerifiedIrExpr) (entry : PsErasureEntryInfo)
    (headType : PsExpr) (arguments : List PsExpr) :
    Except PsErasureError PsVerifiedIrExpr :=
  let count := psListLength entry.binders;
  let suppliedPrefix := psListTake count arguments;
  let suffix := psErasureDropPrefix PsExpr count arguments;
  let remainingBinders :=
    psErasureDropPrefix PsErasedBinderKind (psListLength suppliedPrefix) entry.binders;
  match psEraseApplicationArguments erase environment scope headType suppliedPrefix
      (psListTake (psListLength suppliedPrefix) entry.binders)
      (PsErasureAppliedArguments.mk List.nil List.nil List.nil headType) with
  | Except.error error => Except.error error
  | Except.ok applied =>
      let typeArguments := psListReverse applied.typeArgumentsRev;
      let runtimeArguments := psListReverse applied.runtimeArgumentsRev;
      let unitTransport : Bool :=
        if Nat.beq entry.runtimeArity 0 then
          if Nat.beq entry.typeArity 0 then false else true
        else false;
      match psEraseFinishEntryWithFuel environment fn typeArguments unitTransport
          4096 scope applied.remainingType remainingBinders List.nil runtimeArguments
          (PsErasureApplicationCaptureTypes.mk
            (psListReverse applied.runtimeArgumentTypesRev)) with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          if psListIsEmpty remainingBinders then
            if Nat.beq (psListLength typeArguments) entry.typeArity then
              if Nat.beq (psListLength runtimeArguments) entry.runtimeArity then
                psEraseCanonicalArguments erase environment scope lowered
                  applied.remainingType suffix
              else Except.error PsErasureError.binderMismatch
            else Except.error PsErasureError.binderMismatch
          else
            if psListIsEmpty suffix then Except.ok lowered
            else Except.error PsErasureError.binderMismatch

def psEraseMappedIntrinsic
    (erase :
      PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (operation : PsVerifiedIrIntrinsic)
    (arguments : List PsExpr) :
    Except PsErasureError PsVerifiedIrExpr :=
  match psListMapExcept erase arguments with
  | Except.error error => Except.error error
  | Except.ok erased =>
      Except.ok
        (PsVerifiedIrExpr.intrinsic operation [] erased)

def psEraseSelectedArguments
    (erase :
      PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (arguments : List PsExpr)
    (indexes : List Nat) : Except PsErasureError (List PsVerifiedIrExpr) :=
  match indexes with
  | [] => Except.ok []
  | index :: rest =>
      match psErasureExprListAt arguments index with
      | Option.none => Except.error PsErasureError.unsupportedApplication
      | Option.some argument =>
          match erase argument with
          | Except.error error => Except.error error
          | Except.ok erased =>
              match psEraseSelectedArguments erase arguments rest with
              | Except.error error => Except.error error
              | Except.ok erasedRest =>
                  Except.ok (List.cons erased erasedRest)

def psEraseSelectedTypeArguments
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (arguments : List PsExpr)
    (indexes : List Nat) : Except PsErasureError (List PsVerifiedIrType) :=
  match indexes with
  | [] => Except.ok []
  | index :: rest =>
      match psErasureExprListAt arguments index with
      | Option.none => Except.error PsErasureError.unsupportedApplication
      | Option.some argument =>
          match psEraseRuntimeType environment scope argument with
          | Except.error error => Except.error error
          | Except.ok erased =>
              match
                  psEraseSelectedTypeArguments
                    environment
                    scope
                    arguments
                    rest with
              | Except.error error => Except.error error
              | Except.ok erasedRest =>
                  Except.ok (List.cons erased erasedRest)

def psEraseTypedIntrinsic
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (erase : PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (operation : PsVerifiedIrIntrinsic)
    (arguments : List PsExpr)
    (typeIndexes : List Nat)
    (runtimeIndexes : List Nat) :
    Except PsErasureError PsVerifiedIrExpr :=
  match
      psEraseSelectedTypeArguments
        environment
        scope
        arguments
        typeIndexes with
  | Except.error error => Except.error error
  | Except.ok typeArguments =>
      match
          psEraseSelectedArguments
            erase
            arguments
            runtimeIndexes with
      | Except.error error => Except.error error
      | Except.ok runtimeArguments =>
          Except.ok
            (PsVerifiedIrExpr.intrinsic
              operation
              typeArguments
              runtimeArguments)

def psErasureBoolAnd
    (left : Bool)
    (right : Bool) : Bool :=
  if left then right else false

def psErasureBoolOr
    (left : Bool)
    (right : Bool) : Bool :=
  if left then true else right

def psErasureBoolNot
    (value : Bool) : Bool :=
  if value then false else true

-- Array.foldl alone has a flat two-parameter callback ABI. Capture its source
-- callback before the remaining operands, then bridge canonical unary calls.
def psEraseArrayFoldl
    (environment : PsEnvironment) (scope : PsErasureScope)
    (erase : PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (arguments : List PsExpr) : Except PsErasureError PsVerifiedIrExpr :=
  match psEraseSelectedTypeArguments environment scope arguments [0, 1] with
  | Except.error error => Except.error error
  | Except.ok typeArguments =>
      match typeArguments with
      | List.nil => Except.error PsErasureError.unsupportedApplication
      | List.cons elementType foldTypeTail =>
          match foldTypeTail with
          | List.nil => Except.error PsErasureError.unsupportedApplication
          | List.cons accumulatorType foldAfterAccumulator =>
              match foldAfterAccumulator with
              | List.nil =>
                  match psEraseSelectedArguments erase arguments [2, 3, 4, 5, 6] with
                  | Except.error error => Except.error error
                  | Except.ok runtimeArguments =>
                      match runtimeArguments with
                      | List.nil => Except.error PsErasureError.unsupportedApplication
                      | List.cons callback rest =>
                          let callbackType := PsVerifiedIrType.function [accumulatorType]
                            (PsVerifiedIrType.function [elementType] accumulatorType);
                          match psErasureCaptureTypedApplicationValue
                              (PsErasureApplicationCaptureState.mk scope List.nil List.nil)
                              "_psFoldFn" callbackType callback with
                          | Except.error error => Except.error error
                          | Except.ok captured =>
                              match captured.valuesRev with
                              | List.nil => Except.error PsErasureError.binderMismatch
                              | List.cons called _ =>
                                  let accumulatorName :=
                                    psErasureLocalName captured.scope "_psFoldAcc" "_psFoldAcc"
                                      captured.scope.localContext.nextId;
                                  if psErasureLocalNameUsed captured.scope accumulatorName then
                                    Except.error PsErasureError.fuelExhausted
                                  else
                                    let accumulatorScope :=
                                      psErasureReserveOutputName captured.scope accumulatorName;
                                    let elementName :=
                                      psErasureLocalName accumulatorScope "_psFoldElement" "_psFoldElement"
                                        accumulatorScope.localContext.nextId;
                                    if psErasureLocalNameUsed accumulatorScope elementName then
                                      Except.error PsErasureError.fuelExhausted
                                    else
                                      let bridge := PsVerifiedIrExpr.lambda
                                        [PsVerifiedIrParameter.mk accumulatorName accumulatorType,
                                          PsVerifiedIrParameter.mk elementName elementType]
                                        accumulatorType
                                        (PsVerifiedIrExpr.call
                                          (PsVerifiedIrExpr.call called List.nil
                                            [PsVerifiedIrExpr.var accumulatorName])
                                          List.nil [PsVerifiedIrExpr.var elementName]);
                                      Except.ok
                                        (psErasureWrapApplicationCaptures captured.bindingsRev
                                          (PsVerifiedIrExpr.intrinsic PsVerifiedIrIntrinsic.arrayFoldl
                                            typeArguments (List.cons bridge rest)))
              | List.cons _ _ => Except.error PsErasureError.unsupportedApplication

def psErasePrimitiveApplication
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (erase :
      PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (view : PsErasureAppView) :
    Except PsErasureError (Option PsVerifiedIrExpr) :=
  match view.head with
  | .constE name _ =>
      let text := psNameToString name;
      let binary : PsVerifiedIrIntrinsic -> Except PsErasureError (Option PsVerifiedIrExpr) :=
        fun (operation : PsVerifiedIrIntrinsic) =>
          if Nat.beq (psListLength view.args) 2 then
            match
                psEraseMappedIntrinsic
                  erase
                  operation
                  view.args with
            | Except.error error => Except.error error
            | Except.ok result => Except.ok (Option.some result)
          else
            Except.error PsErasureError.unsupportedApplication;
      let productProjection : Nat -> Except PsErasureError (Option PsVerifiedIrExpr) :=
        fun (index : Nat) =>
          if Nat.beq (psListLength view.args) 3 then
            match psErasureExprListAt view.args 2 with
            | Option.none => Except.error PsErasureError.unsupportedApplication
            | Option.some value =>
                match erase (PsExpr.proj psProdName index value) with
                | Except.error error => Except.error error
                | Except.ok result => Except.ok (Option.some result)
          else Except.error PsErasureError.unsupportedApplication;
      match psEraseFloatApplication scope erase view with
      | .error error => .error error
      | .ok (some value) => .ok (some value)
      | .ok none =>
      match PsUtf8Runtime.erase scope erase view with
      | .error error => .error error
      | .ok (some value) => .ok (some value)
      | .ok none =>
      match PsPlatformRuntime.erase scope erase view with
      | .error error => .error error
      | .ok (some value) => .ok (some value)
      | .ok none =>
      match psEraseUnsignedApplication scope erase view with
      | .error error => .error error
      | .ok (some value) => .ok (some value)
      | .ok none =>
      if psStringEq text "Prod.fst" then productProjection 0
      else if psStringEq text "Prod.snd" then productProjection 1
      else if psStringEq text "Int.ofNat" then
        if Nat.beq (psListLength view.args) 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.intOfNat
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (Option.some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "Int.toNat" then
        if Nat.beq (psListLength view.args) 1 then
          match psEraseMappedIntrinsic erase PsVerifiedIrIntrinsic.intToNat view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (Option.some result)
        else Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "Int.repr" then
        if Nat.beq (psListLength view.args) 1 then
          match psEraseMappedIntrinsic erase PsVerifiedIrIntrinsic.intRepr view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (Option.some result)
        else Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "Int.negSucc" then
        if Nat.beq (psListLength view.args) 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.intNegSucc
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (Option.some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "Int.neg" then
        if Nat.beq (psListLength view.args) 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.intNeg
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (Option.some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "Int.add" then
        binary PsVerifiedIrIntrinsic.intAdd
      else if psStringEq text "Int.sub" then
        binary PsVerifiedIrIntrinsic.intSub
      else if psStringEq text "Int.mul" then
        binary PsVerifiedIrIntrinsic.intMul
      else if psStringEq text "Nat.succ" then
        match view.args with
        | List.nil => Except.error PsErasureError.unsupportedApplication
        | List.cons argument rest =>
            match rest with
            | List.cons _ _ => Except.error PsErasureError.unsupportedApplication
            | List.nil =>
                match erase argument with
                | Except.error error => Except.error error
                | Except.ok value =>
                    Except.ok (Option.some
                      (PsVerifiedIrExpr.intrinsic PsVerifiedIrIntrinsic.natAdd []
                        [value, PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 1)]))
      else if psStringEq text "mixHash" then
        binary .hashMix
      else if psStringEq text "String.hash" then
        if view.args.length == 1 then
          (psEraseMappedIntrinsic erase .stringHash view.args).map some
        else .error .unsupportedApplication
      else if psStringEq text "Nat.add" then
        binary PsVerifiedIrIntrinsic.natAdd
      else if psStringEq text "Nat.sub" then
        binary PsVerifiedIrIntrinsic.natSub
      else if psStringEq text "Nat.mul" then
        binary PsVerifiedIrIntrinsic.natMul
      else if psStringEq text "Nat.shiftLeft" then
        binary PsVerifiedIrIntrinsic.natShiftLeft
      else if psStringEq text "Nat.shiftRight" then
        binary PsVerifiedIrIntrinsic.natShiftRight
      else if psStringEq text "Int.pow" then
        binary PsVerifiedIrIntrinsic.intPow
      else if psStringEq text "Nat.pow" then
        binary PsVerifiedIrIntrinsic.natPow
      else if psStringEq text "Nat.div" then
        binary PsVerifiedIrIntrinsic.natDiv
      else if psStringEq text "Nat.mod" then
        binary PsVerifiedIrIntrinsic.natMod
      else if psStringEq text "Nat.beq" then
        binary PsVerifiedIrIntrinsic.natEq
      else if psStringEq text "Nat.ble" then
        binary PsVerifiedIrIntrinsic.natLe
      else if psStringEq text "Nat.blt" then
        binary PsVerifiedIrIntrinsic.natLt
      else if psStringEq text "Bool.and" then
        binary PsVerifiedIrIntrinsic.boolAnd
      else if psStringEq text "Bool.or" then
        binary PsVerifiedIrIntrinsic.boolOr
      else if psStringEq text "Bool.not" then
        if Nat.beq (psListLength view.args) 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.boolNot
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (Option.some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "Char.ofNat" then
        if Nat.beq (psListLength view.args) 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.charOfNat
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (Option.some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "Char.toNat" then
        if Nat.beq (psListLength view.args) 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.charToNat
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (Option.some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "String.Pos.Raw.mk" then
        match view.args with
        | List.cons value rest =>
            match rest with
            | List.nil =>
                match erase value with
                | Except.error error => Except.error error
                | Except.ok result => Except.ok (Option.some result)
            | List.cons _ _ =>
                Except.error PsErasureError.unsupportedApplication
        | _ =>
            Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "String.Pos.Raw.byteIdx" then
        match view.args with
        | List.cons value rest =>
            match rest with
            | List.nil =>
                match erase value with
                | Except.error error => Except.error error
                | Except.ok result => Except.ok (Option.some result)
            | List.cons _ _ =>
                Except.error PsErasureError.unsupportedApplication
        | _ =>
            Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "String.push" then
        binary PsVerifiedIrIntrinsic.stringPush
      else if psStringEq text "String.singleton" then
        if Nat.beq (psListLength view.args) 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.stringSingleton
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (Option.some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "String.Internal.length" then
        if Nat.beq (psListLength view.args) 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.stringLength
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (Option.some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "String.Internal.append" then
        binary PsVerifiedIrIntrinsic.stringAppend
      else if psStringEq text "String.utf8ByteSize" then
        if Nat.beq (psListLength view.args) 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.stringUtf8ByteSize
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (Option.some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "String.Internal.next" then
        binary PsVerifiedIrIntrinsic.stringNext
      else if psStringEq text "String.Internal.get" then
        binary PsVerifiedIrIntrinsic.stringGet
      else if psStringEq text "String.Internal.atEnd" then
        binary PsVerifiedIrIntrinsic.stringAtEnd
      else if psStringEq text "String.Internal.extract" then
        if Nat.beq (psListLength view.args) 3 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.stringExtract
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (Option.some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if text == "Array.mk" || text == "Array.toList" then do
        let [alpha, value] := view.args | throw .unsupportedApplication
        let element ← psEraseRuntimeType environment scope alpha
        return some (← psEraseArrayConversion scope element (← erase value) (text == "Array.mk"))
      else if psErasureBoolAnd (psStringEq text "Array.emptyWithCapacity") (Nat.beq (psListLength view.args) 2) then
        match
            psEraseTypedIntrinsic
              environment scope erase
              PsVerifiedIrIntrinsic.arrayEmptyWithCapacity
              view.args [0] [1] with
        | Except.error error => Except.error error
        | Except.ok result => Except.ok (Option.some result)
      else if psErasureBoolAnd (psStringEq text "Array.size") (Nat.beq (psListLength view.args) 2) then
        match
            psEraseTypedIntrinsic
              environment scope erase
              PsVerifiedIrIntrinsic.arraySize
              view.args [0] [1] with
        | Except.error error => Except.error error
        | Except.ok result => Except.ok (Option.some result)
      else if psErasureBoolAnd (psStringEq text "Array.push") (Nat.beq (psListLength view.args) 3) then
        match
            psEraseTypedIntrinsic
              environment scope erase
              PsVerifiedIrIntrinsic.arrayPush
              view.args [0] [1, 2] with
        | Except.error error => Except.error error
        | Except.ok result => Except.ok (Option.some result)
      else if psErasureBoolAnd (psStringEq text "Array.getInternal") (Nat.beq (psListLength view.args) 4) then
        match
            psEraseTypedIntrinsic
              environment scope erase
              PsVerifiedIrIntrinsic.arrayGet
              view.args [0] [1, 2] with
        | Except.error error => Except.error error
        | Except.ok result => Except.ok (Option.some result)
      else if psErasureBoolAnd (psStringEq text "Array.getD") (Nat.beq (psListLength view.args) 4) then
        match
            psEraseTypedIntrinsic
              environment scope erase
              PsVerifiedIrIntrinsic.arrayGetD
              view.args [0] [1, 2, 3] with
        | Except.error error => Except.error error
        | Except.ok result => Except.ok (Option.some result)
      else if psErasureBoolAnd (psStringEq text "Array.set") (Nat.beq (psListLength view.args) 5) then
        match
            psEraseTypedIntrinsic
              environment scope erase
              PsVerifiedIrIntrinsic.arraySet
              view.args [0] [1, 2, 3] with
        | Except.error error => Except.error error
        | Except.ok result => Except.ok (Option.some result)
      else if psErasureBoolAnd (psStringEq text "Array.setIfInBounds") (Nat.beq (psListLength view.args) 4) then
        match
            psEraseTypedIntrinsic
              environment scope erase
              PsVerifiedIrIntrinsic.arraySetIfInBounds
              view.args [0] [1, 2, 3] with
        | Except.error error => Except.error error
        | Except.ok result => Except.ok (Option.some result)
      else if psErasureBoolAnd (psStringEq text "Array.map") (Nat.beq (psListLength view.args) 4) then
        match
            psEraseTypedIntrinsic
              environment scope erase
              PsVerifiedIrIntrinsic.arrayMap
              view.args [0, 1] [2, 3] with
        | Except.error error => Except.error error
        | Except.ok result => Except.ok (Option.some result)
      else if psErasureBoolAnd (psStringEq text "Array.filter") (Nat.beq (psListLength view.args) 5) then
        match psEraseTypedIntrinsic environment scope erase
            PsVerifiedIrIntrinsic.arrayFilter view.args [0] [1, 2, 3, 4] with
        | Except.error error => Except.error error
        | Except.ok result => Except.ok (Option.some result)
      else if psErasureBoolAnd (psStringEq text "Array.foldl") (Nat.beq (psListLength view.args) 7) then
        match
            psEraseArrayFoldl environment scope erase view.args with
        | Except.error error => Except.error error
        | Except.ok result => Except.ok (Option.some result)
      else
        Except.ok Option.none
  | _ => Except.ok Option.none

def psErasureLookupTypeSubstitution
    (entries : List (String × PsVerifiedIrType)) :
    String -> Option PsVerifiedIrType :=
  match entries with
  | List.nil => fun (name : String) => Option.none
  | List.cons entry rest =>
      let smaller := psErasureLookupTypeSubstitution rest;
      fun (name : String) =>
        match entry with
        | Prod.mk key value =>
            if psStringEq key name then Option.some value
            else smaller name

def psSubstituteVerifiedTypeWithFuel
    (substitutions : List (String × PsVerifiedIrType)) (fuel : Nat) :
    PsVerifiedIrType -> PsVerifiedIrType :=
  match fuel with
  | Nat.zero => fun (type : PsVerifiedIrType) => type
  | Nat.succ remaining =>
    fun (type : PsVerifiedIrType) =>
      let smaller : PsVerifiedIrType -> PsVerifiedIrType :=
        psSubstituteVerifiedTypeWithFuel substitutions remaining;
      match type with
      | .typeParameter name =>
          match
              psErasureLookupTypeSubstitution
                substitutions
                name with
          | Option.some replacement => replacement
          | Option.none => type
      | .function parameters result =>
          PsVerifiedIrType.function
            (psListMap smaller parameters)
            (smaller
              result)
      | .named name arguments =>
          PsVerifiedIrType.named
            name
            (psListMap smaller arguments)
      | _ => type

def psSubstituteVerifiedType
    (substitutions : List (String × PsVerifiedIrType))
    (type : PsVerifiedIrType) : PsVerifiedIrType :=
  psSubstituteVerifiedTypeWithFuel substitutions 4096 type

def psErasureLookupStructureRecursor
    (scope : PsErasureScope) (name : PsName) : Option PsRuntimeStructureInfo :=
  match name with
  | PsName.str owner suffix =>
      if psStringEq suffix "rec" then
        psErasureLookupStructure scope.runtimeStructures owner
      else Option.none
  | _ => Option.none

def psEraseRuntimeStructureFields
    (erase : PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (arguments : List PsExpr) (fields : List PsRuntimeStructureField) :
    List (String × PsVerifiedIrExpr) -> Except PsErasureError (List (String × PsVerifiedIrExpr)) :=
  match fields with
  | List.nil => fun (fieldsRev : List (String × PsVerifiedIrExpr)) => Except.ok (psListReverse fieldsRev)
  | List.cons field rest =>
    let smaller : List (String × PsVerifiedIrExpr) -> Except PsErasureError (List (String × PsVerifiedIrExpr)) :=
      psEraseRuntimeStructureFields erase arguments rest;
    fun (fieldsRev : List (String × PsVerifiedIrExpr)) =>
      match psErasureExprListAt arguments field.sourceIndex with
      | Option.none => Except.error PsErasureError.unsupportedApplication
      | Option.some argument =>
          match erase argument with
          | Except.error error => Except.error error
          | Except.ok value =>
              smaller
                (List.cons (Prod.mk field.name value) fieldsRev)

def psEraseRuntimeStructureApplication
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (erase :
      PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (view : PsErasureAppView) :
    Except PsErasureError (Option PsVerifiedIrExpr) :=
  match view.head with
  | .constE name _ =>
      match
          psErasureLookupStructure
            scope.runtimeStructureConstructors
            name with
      | Option.none => Except.ok Option.none
      | Option.some structureInfo =>
          if structureInfo.unboxed then do
            if view.args.length != structureInfo.numParams + 1 then
              throw .unsupportedApplication
            let some field := view.args[structureInfo.numParams]? | throw .unsupportedApplication
            return some (← erase field)
          else
          let expectedArity :=
            Nat.add structureInfo.numParams structureInfo.numFields;
          if psErasureBoolNot (Nat.beq (psListLength view.args) expectedArity) then
            Except.error PsErasureError.unsupportedApplication
          else
            match (do
              let selected ← psErasureSelectSourceTypeArguments
                (psListTake structureInfo.numParams view.args)
                structureInfo.sourceTypeIndices
              psListMapExcept (psEraseRuntimeType environment scope) selected) with
            | Except.error error => Except.error error
            | Except.ok typeArguments =>
                if psErasureBoolNot (Nat.beq (psListLength typeArguments) (psListLength structureInfo.typeParameters)) then
                  Except.error PsErasureError.unsupportedApplication
                else
                  match
                      psEraseRuntimeStructureFields
                        erase
                        view.args
                        structureInfo.fields
                        [] with
                  | Except.error error => Except.error error
                  | Except.ok fields =>
                      Except.ok
                        (Option.some
                          (PsVerifiedIrExpr.record
                            structureInfo.name
                            typeArguments
                            fields))
  | _ => Except.ok Option.none

def psEraseRuntimeConstructorFields
    (erase : PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (arguments : List PsExpr) (fields : List PsRuntimeConstructorField) :
    List (String × PsVerifiedIrExpr) -> Except PsErasureError (List (String × PsVerifiedIrExpr)) :=
  match fields with
  | List.nil => fun (fieldsRev : List (String × PsVerifiedIrExpr)) => Except.ok (psListReverse fieldsRev)
  | List.cons field rest =>
    let smaller : List (String × PsVerifiedIrExpr) -> Except PsErasureError (List (String × PsVerifiedIrExpr)) :=
      psEraseRuntimeConstructorFields erase arguments rest;
    fun (fieldsRev : List (String × PsVerifiedIrExpr)) =>
      match psErasureExprListAt arguments field.sourceIndex with
      | Option.none => Except.error PsErasureError.unsupportedApplication
      | Option.some argument =>
          match erase argument with
          | Except.error error => Except.error error
          | Except.ok value =>
              smaller
                (List.cons (Prod.mk field.name value) fieldsRev)

def psEraseRuntimeConstructorApplication
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (erase :
      PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (view : PsErasureAppView) :
    Except PsErasureError (Option PsVerifiedIrExpr) :=
  match view.head with
  | .constE name _ =>
      match
          psErasureLookupConstructor
            scope.runtimeConstructors
            name with
      | Option.none => Except.ok Option.none
      | Option.some ctorInfo =>
          let expectedArity :=
            Nat.add ctorInfo.numParams ctorInfo.numFields;
          if psErasureBoolNot (Nat.beq (psListLength view.args) expectedArity) then
            Except.error PsErasureError.unsupportedApplication
          else
            match (do
              let some constructor := psEnvironmentFindConstructor environment name
                | throw PsErasureError.unsupportedRuntimeTerm
              let some family := psEnvironmentFindInductive environment constructor.inductiveName
                | throw PsErasureError.unsupportedRuntimeTerm
              let mask ← psErasureInductiveSourceTypeIndices environment scope family
              let selected ← psErasureSelectSourceTypeArguments
                (psListTake ctorInfo.numParams view.args) mask
              psListMapExcept (psEraseRuntimeType environment scope) selected) with
            | Except.error error => Except.error error
            | Except.ok typeArguments =>
                match
                    psEraseRuntimeConstructorFields
                      erase
                      view.args
                      ctorInfo.fields
                      [] with
                | Except.error error => Except.error error
                | Except.ok fields =>
                    Except.ok
                      (Option.some
                        (PsVerifiedIrExpr.constructor
                          ctorInfo.inductiveName
                          ctorInfo.name
                          typeArguments
                          fields))
  | _ => Except.ok Option.none

structure PsErasedMatchMinor where
  constructorName : String
  bindings : List PsVerifiedIrMatchBinding
  body : PsVerifiedIrExpr

structure PsOpenMatchMinor where
  scope : PsErasureScope
  cursor : PsExpr
  bindingsRev : List PsVerifiedIrMatchBinding

-- Walk the checked field telescope, not just its stored runtime projection.
-- Source indices remain stable across proof fields, including trailing ones.
def psOpenMatchMinorFields
    (environment : PsEnvironment) (substitutions : List (String × PsVerifiedIrType))
    (count index : Nat) (fields : List PsRuntimeConstructorField)
    (state : PsOpenMatchMinor) : Except PsErasureError PsOpenMatchMinor := do
  match count with
  | 0 =>
    if !fields.isEmpty then throw .binderMismatch
    return state
  | count + 1 =>
    let .lam name domain body binder := state.cursor | throw .binderMismatch
    let pushed := psLocalPushBinding state.scope.localContext name domain binder
    let cursor := psExprInstantiate1 body (.fvar pushed.id)
    match psErasureClassifyBinder environment state.scope.localContext domain with
    | .type | .index | .proof =>
      if fields.head?.any (fun field => field.sourceIndex <= index) then throw .binderMismatch
      let scope := { state.scope with
        localContext := pushed.context
        erasedLocals := pushed.id :: state.scope.erasedLocals }
      psOpenMatchMinorFields environment substitutions count (index + 1) fields
        { state with scope, cursor }
    | .runtime =>
      let field :: fields := fields | throw .binderMismatch
      if field.sourceIndex != index then throw .binderMismatch
      let bindingName := psErasureLocalName state.scope
        (psNameToString name) field.name pushed.id
      let scope := { state.scope with
        localContext := pushed.context
        runtimeLocals := (pushed.id, bindingName) :: state.scope.runtimeLocals }
      let binding := PsVerifiedIrMatchBinding.mk field.name bindingName
        (psSubstituteVerifiedType substitutions field.type)
      psOpenMatchMinorFields environment substitutions count (index + 1) fields
        { scope, cursor, bindingsRev := binding :: state.bindingsRev }

structure PsOpenMatchHypotheses where
  scope : PsErasureScope
  cursor : PsExpr

def psErasureFindMatchBinding
    (fieldName : String)
    (bindings : List PsVerifiedIrMatchBinding) : Option PsVerifiedIrMatchBinding :=
  match bindings with
  | List.nil => Option.none
  | List.cons binding rest =>
      if psStringEq binding.field fieldName then Option.some binding
      else psErasureFindMatchBinding fieldName rest


def psOpenMatchMinorHypotheses
    (environment : PsEnvironment)
    (eraseAt : PsErasureScope -> PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (recursionPlan : Option PsErasureRecursionPlan) (bindings : List PsVerifiedIrMatchBinding)
    (fields : List PsRuntimeConstructorField) :
    PsOpenMatchHypotheses -> Except PsErasureError PsOpenMatchHypotheses :=
  match fields with
  | List.nil => fun (state : PsOpenMatchHypotheses) => Except.ok state
  | List.cons field rest =>
    let smaller : PsOpenMatchHypotheses -> Except PsErasureError PsOpenMatchHypotheses :=
      psOpenMatchMinorHypotheses environment eraseAt recursionPlan bindings rest;
    fun (state : PsOpenMatchHypotheses) =>
      if psErasureBoolNot field.recursive then
        smaller
          state
      else
        match state.cursor with
        | .lam name domain body binder =>
            match psErasureFindMatchBinding field.name bindings with
            | Option.none => Except.error PsErasureError.binderMismatch
            | Option.some binding =>
                let pushed :=
                  psLocalPushBinding
                    state.scope.localContext
                    name
                    domain
                    binder;
                let baseScope : PsErasureScope := { state.scope with
                  localContext := pushed.context
                  runtimeLocals := state.scope.runtimeLocals
                  typeLocals := state.scope.typeLocals
                  erasedLocals :=
                    List.cons pushed.id state.scope.erasedLocals
                  declarationNames := state.scope.declarationNames
                  runtimeConstructors := state.scope.runtimeConstructors
                  runtimeRecursors := state.scope.runtimeRecursors
                  runtimeStructures := state.scope.runtimeStructures
                  runtimeStructureConstructors := state.scope.runtimeStructureConstructors
                  runtimeExpressions := state.scope.runtimeExpressions
                  currentDefinition := state.scope.currentDefinition
                };
                let replacement : Except PsErasureError (Option PsVerifiedIrExpr) :=
                  match recursionPlan with
                  | none => Except.ok none
                  | some plan => (psErasureRecursiveCall environment eraseAt
                      state.scope plan binding.name).map some;
                match replacement with
                | Except.error error => Except.error error
                | Except.ok value =>
                    let expressions : List (Nat × PsVerifiedIrExpr) :=
                      match value with
                      | Option.none => baseScope.runtimeExpressions
                      | Option.some expression => List.cons (Prod.mk pushed.id expression) baseScope.runtimeExpressions;
                    let nextScope := { baseScope with runtimeExpressions := expressions };
                    smaller (PsOpenMatchHypotheses.mk nextScope (psExprInstantiate1 body (PsExpr.fvar pushed.id)))
        | _ => Except.error PsErasureError.binderMismatch

def psEraseMatchMinor
    (environment : PsEnvironment)
    (eraseAt :
      PsErasureScope ->
      PsExpr ->
      Except PsErasureError PsVerifiedIrExpr)
    (scope : PsErasureScope)
    (substitutions : List (String × PsVerifiedIrType))
    (recursionPlan : Option PsErasureRecursionPlan)
    (ctorInfo : PsRuntimeConstructorInfo)
    (minor : PsExpr) :
    Except PsErasureError PsErasedMatchMinor :=
  match
      psOpenMatchMinorFields
        environment
        substitutions
        ctorInfo.numFields
        ctorInfo.numParams
        ctorInfo.fields
        {
          scope := scope
          cursor := minor
          bindingsRev := []
        } with
  | Except.error error => Except.error error
  | Except.ok opened =>
      let bindings := (psListReverse opened.bindingsRev);
      match
          psOpenMatchMinorHypotheses
            environment
            eraseAt
            recursionPlan
            bindings
            ctorInfo.fields
            {
              scope := opened.scope
              cursor := opened.cursor
            } with
      | Except.error error => Except.error error
      | Except.ok withHypotheses =>
          match eraseAt withHypotheses.scope withHypotheses.cursor with
          | Except.error error => Except.error error
          | Except.ok body =>
              Except.ok {
                constructorName := ctorInfo.name
                bindings := bindings
                body := body
              }

-- Runtime structure fields form an ordered subset of the checked telescope.
-- Recover recursive flags using original projection indices, across proof gaps.
def psErasureStructureRecursorFields
    (numParams : Nat) (recursiveFields : List Nat)
    (fields : List PsRuntimeStructureField) (index : Nat) :
    Except PsErasureError (List PsRuntimeConstructorField) :=
  match fields with
  | List.nil => Except.ok List.nil
  | List.cons field rest =>
      if field.projectionIndex < index then
        Except.error PsErasureError.binderMismatch
      else if psErasureNatNotEqual field.sourceIndex (Nat.add numParams field.projectionIndex) then
        Except.error PsErasureError.binderMismatch
      else
        match psErasureStructureRecursorFields numParams recursiveFields rest (Nat.succ field.projectionIndex) with
        | Except.error error => Except.error error
        | Except.ok tail =>
            Except.ok (List.cons
              (PsRuntimeConstructorField.mk field.sourceIndex field.name field.type
                (psErasureNatInList recursiveFields field.projectionIndex))
              tail)

def psErasureStructureProjectionBindings
    (owner : String) (typeArguments : List PsVerifiedIrType)
    (bindings : List PsVerifiedIrMatchBinding)
    (major : PsVerifiedIrExpr) (body : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  match bindings with
  | List.nil => body
  | List.cons binding rest =>
      PsVerifiedIrExpr.letE binding.name binding.type
        (PsVerifiedIrExpr.projection owner typeArguments major binding.field)
        (psErasureStructureProjectionBindings owner typeArguments rest major body)

def psEraseStructureRecursorMinor
    (environment : PsEnvironment) (scope : PsErasureScope)
    (eraseAt : PsErasureScope -> PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (structureInfo : PsRuntimeStructureInfo) (constructorInfo : PsConstructorInfo)
    (view : PsErasureAppView) :
    Except PsErasureError (Option PsVerifiedIrExpr) :=
  let expectedArity := Nat.add structureInfo.numParams 3;
  if psErasureNatNotEqual (psListLength view.args) expectedArity then
    Except.error PsErasureError.unsupportedApplication
  else
    match (do
      let selected ← psErasureSelectSourceTypeArguments
        (psListTake structureInfo.numParams view.args) structureInfo.sourceTypeIndices
      psListMapExcept (psEraseRuntimeType environment scope) selected) with
    | Except.error error => Except.error error
    | Except.ok typeArguments =>
        if psErasureNatNotEqual (psListLength typeArguments)
            (psListLength structureInfo.typeParameters) then
          Except.error PsErasureError.unsupportedApplication
        else
          match psErasureStructureRecursorFields structureInfo.numParams
              constructorInfo.recursiveFields structureInfo.fields 0 with
          | Except.error error => Except.error error
          | Except.ok fields =>
              match psErasureExprListAt view.args (Nat.add structureInfo.numParams 1) with
              | Option.none => Except.error PsErasureError.unsupportedApplication
              | Option.some minor =>
                  match psErasureExprListAt view.args (Nat.add structureInfo.numParams 2) with
                  | Option.none => Except.error PsErasureError.unsupportedApplication
                  | Option.some major =>
                      match eraseAt scope major with
                      | Except.error error => Except.error error
                      | Except.ok scrutinee =>
                          let recursionPlan := psErasurePlanRecursion scope structureInfo.coreName
                            structureInfo.numParams major [] [minor];
                          let majorName :=
                            psErasureLocalName scope "_psStructureMajor" "_psStructureMajor"
                              scope.localContext.nextId;
                          if psErasureLocalNameUsed scope majorName then
                            Except.error PsErasureError.fuelExhausted
                          else
                            let minorScope := psErasureReserveOutputName scope majorName;
                            let convert : (PsVerifiedIrTypeParameter × PsVerifiedIrType) -> (String × PsVerifiedIrType) :=
                              fun (entry : PsVerifiedIrTypeParameter × PsVerifiedIrType) =>
                                match entry with
                                | Prod.mk parameter value => Prod.mk parameter.name value;
                            let substitutions :=
                              psListMap convert (psListZip structureInfo.typeParameters typeArguments);
                            let runtimeConstructor :=
                              PsRuntimeConstructorInfo.mk structureInfo.name
                                (psErasureSafeIdentifier
                                  (psNameLastComponent constructorInfo.name) "constructor")
                                constructorInfo.name constructorInfo.numParams fields constructorInfo.numFields;
                            match psEraseMatchMinor environment eraseAt minorScope substitutions
                                recursionPlan runtimeConstructor minor with
                            | Except.error error => Except.error error
                            | Except.ok lowered =>
                                Except.ok (Option.some
                                  (PsVerifiedIrExpr.letE majorName
                                    (PsVerifiedIrType.named structureInfo.name typeArguments)
                                    scrutinee
                                    (psErasureStructureProjectionBindings
                                      structureInfo.name typeArguments lowered.bindings
                                      (PsVerifiedIrExpr.var majorName) lowered.body)))

-- Recursive structure minors have field binders followed by generated IH
-- binders. Open them once; never expand a recursive Core recursor in its IH.
def psEraseRuntimeStructureRecursorApplication
    (environment : PsEnvironment) (scope : PsErasureScope)
    (eraseAt : PsErasureScope -> PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (view : PsErasureAppView) :
    Except PsErasureError (Option PsVerifiedIrExpr) :=
  match view.head with
  | PsExpr.constE name _ =>
      match psErasureLookupStructureRecursor scope name with
      | Option.none => Except.ok Option.none
      | Option.some structureInfo =>
          match psEnvironmentFindRecursor environment name with
          | Option.none => Except.error (PsErasureError.unknownConstant name)
          | Option.some recursorInfo =>
              if
                  if psErasureNatNotEqual recursorInfo.numParams structureInfo.numParams then true
                  else if psErasureNatNotEqual recursorInfo.numIndices 0 then true
                  else if psErasureNatNotEqual recursorInfo.numMotives 1 then true
                  else psErasureNatNotEqual recursorInfo.numMinors 1 then
                Except.error PsErasureError.unsupportedRuntimeTerm
              else
                match psEnvironmentFindConstructor environment structureInfo.constructorName with
                | Option.none =>
                    Except.error (PsErasureError.unknownConstant structureInfo.constructorName)
                | Option.some constructorInfo =>
                    if psErasureBoolNot (psNameEq constructorInfo.inductiveName structureInfo.coreName) then
                      Except.error PsErasureError.unsupportedRuntimeTerm
                    else if psErasureNatNotEqual constructorInfo.numParams structureInfo.numParams then
                      Except.error PsErasureError.unsupportedRuntimeTerm
                    else if psErasureNatNotEqual constructorInfo.numFields structureInfo.numFields then
                      Except.error PsErasureError.unsupportedRuntimeTerm
                    else
                      psEraseStructureRecursorMinor environment scope eraseAt
                        structureInfo constructorInfo view
  | _ => Except.ok Option.none

def psEraseMatchAlternativesWorker
    (environment : PsEnvironment)
    (eraseAt : PsErasureScope -> PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (scope : PsErasureScope) (substitutions : List (String × PsVerifiedIrType))
    (recursionPlan : Option PsErasureRecursionPlan) (arguments : List PsExpr) (minorStart : Nat)
    (constructors : List PsRuntimeConstructorInfo) :
    Nat -> List (String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr) ->
    Except PsErasureError (List (String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr)) :=
  match constructors with
  | List.nil =>
    fun (_index : Nat) (alternativesRev : List (String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr)) =>
      Except.ok (psListReverse alternativesRev)
  | List.cons ctorInfo rest =>
    let smaller : Nat -> List (String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr) ->
        Except PsErasureError (List (String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr)) :=
      psEraseMatchAlternativesWorker environment eraseAt scope substitutions recursionPlan arguments minorStart rest;
    fun (index : Nat) (alternativesRev : List (String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr)) =>
      match psErasureExprListAt arguments (Nat.add minorStart index) with
      | Option.none => Except.error PsErasureError.unsupportedApplication
      | Option.some minor =>
          match
              psEraseMatchMinor
                environment
                eraseAt
                scope
                substitutions
                recursionPlan
                ctorInfo
                minor with
          | Except.error error => Except.error error
          | Except.ok alternative =>
              smaller (Nat.add index 1)
                (List.cons
                  (Prod.mk
                    alternative.constructorName
                    (Prod.mk
                      alternative.bindings
                      alternative.body))
                  alternativesRev)

def psEraseMatchAlternatives
    (environment : PsEnvironment)
    (eraseAt : PsErasureScope -> PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (scope : PsErasureScope) (substitutions : List (String × PsVerifiedIrType))
    (recursionPlan : Option PsErasureRecursionPlan) (arguments : List PsExpr) (minorStart : Nat)
    (index : Nat) (constructors : List PsRuntimeConstructorInfo)
    (alternativesRev : List (String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr)) :
    Except PsErasureError (List (String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr)) :=
  psEraseMatchAlternativesWorker environment eraseAt scope substitutions recursionPlan arguments minorStart
    constructors index alternativesRev

def psEraseNatRecursorAlternatives
    (scrutinee : PsVerifiedIrExpr)
    (alternatives : List (String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr)) :
    Except PsErasureError PsVerifiedIrExpr :=
  match alternatives with
  | List.nil => Except.error PsErasureError.binderMismatch
  | List.cons zeroAlternative rest =>
      match rest with
      | List.nil => Except.error PsErasureError.binderMismatch
      | List.cons succAlternative tail =>
          if psErasureBoolNot (psListIsEmpty tail) then Except.error PsErasureError.binderMismatch
          else
            match zeroAlternative with
            | Prod.mk zeroName zeroDetail =>
                match zeroDetail with
                | Prod.mk zeroBindings zeroBody =>
                    match succAlternative with
                    | Prod.mk succName succDetail =>
                        match succDetail with
                        | Prod.mk succBindings succBody =>
                            if psErasureBoolNot (psStringEq zeroName "zero") then Except.error PsErasureError.binderMismatch
                            else if psErasureBoolNot (psStringEq succName "succ") then Except.error PsErasureError.binderMismatch
                            else if psErasureBoolNot (psListIsEmpty zeroBindings) then Except.error PsErasureError.binderMismatch
                            else
                              match succBindings with
                              | List.nil => Except.error PsErasureError.binderMismatch
                              | List.cons binding bindingsTail =>
                                  if psErasureBoolNot (psListIsEmpty bindingsTail) then Except.error PsErasureError.binderMismatch
                                  else
                                    Except.ok
                                      (PsVerifiedIrExpr.ifE
                                        (PsVerifiedIrExpr.intrinsic PsVerifiedIrIntrinsic.natEq []
                                          [scrutinee, PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 0)])
                                        zeroBody
                                        (PsVerifiedIrExpr.letE binding.name (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
                                          (PsVerifiedIrExpr.intrinsic PsVerifiedIrIntrinsic.natSub []
                                            [scrutinee, PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 1)])
                                          succBody))

def psEraseIntRecursorAlternatives
    (scrutinee : PsVerifiedIrExpr)
    (alternatives : List (String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr)) :
    Except PsErasureError PsVerifiedIrExpr :=
  match alternatives with
  | [("ofNat", [nonnegative], positiveBody), ("negSucc", [negative], negativeBody)] =>
    .ok (.ifE (.intrinsic .intLt [] [scrutinee, .literal (.integer 0)])
      (.letE negative.name (.primitive .nat)
        (.intrinsic .natSub []
          [.intrinsic .intToNat [] [.intrinsic .intNeg [] [scrutinee]],
           .literal (.natural 1)]) negativeBody)
      (.letE nonnegative.name (.primitive .nat)
        (.intrinsic .intToNat [] [scrutinee]) positiveBody))
  | _ => .error PsErasureError.binderMismatch

def psEraseRuntimeRecursorApplication
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (eraseAt :
      PsErasureScope ->
      PsExpr ->
      Except PsErasureError PsVerifiedIrExpr)
    (view : PsErasureAppView) :
    Except PsErasureError (Option PsVerifiedIrExpr) :=
  match view.head with
  | .constE name _ =>
      match psErasureLookupRecursor scope.runtimeRecursors name with
      | Option.none => Except.ok Option.none
      | Option.some inductiveInfo =>
          let expectedArity := psRuntimeRecursorArity inductiveInfo;
          if psErasureBoolNot (Nat.beq (psListLength view.args) expectedArity) then
            Except.error PsErasureError.unsupportedApplication
          else
            match (do
              let selected ← psErasureSelectSourceTypeArguments
                (psListTake inductiveInfo.numParams view.args)
                inductiveInfo.sourceTypeIndices
              psListMapExcept (psEraseRuntimeType environment scope) selected) with
            | Except.error error => Except.error error
            | Except.ok typeArguments =>
                if
                    psErasureBoolNot
                      (Nat.beq (psListLength typeArguments)
                        (psListLength inductiveInfo.typeParameters)) then
                  Except.error PsErasureError.unsupportedApplication
                else
                  let convert : (PsVerifiedIrTypeParameter × PsVerifiedIrType) -> (String × PsVerifiedIrType) :=
                    fun (entry : PsVerifiedIrTypeParameter × PsVerifiedIrType) =>
                      match entry with
                      | Prod.mk parameter value => Prod.mk parameter.name value;
                  let substitutions :=
                    psListMap convert (psListZip inductiveInfo.typeParameters typeArguments);
                  let minorStart := Nat.add inductiveInfo.numParams 1;
                  let majorIndex := Nat.sub expectedArity 1;
                  match psErasureExprListAt view.args majorIndex with
                  | Option.none =>
                      Except.error PsErasureError.unsupportedApplication
                  | Option.some major =>
                      match eraseAt scope major with
                      | Except.error error => Except.error error
                      | Except.ok scrutinee =>
                          let indices := (view.args.drop
                            (minorStart + inductiveInfo.constructors.length)).take inductiveInfo.numIndices;
                          let minors := (view.args.drop minorStart).take inductiveInfo.constructors.length;
                          let recursionPlan := psErasurePlanRecursion scope inductiveInfo.coreName
                            inductiveInfo.numParams major indices minors;
                          -- Scalar elimination inspects a major and extracts its
                          -- payload. Capture computations once before either use.
                          let majorIsValue : Bool :=
                            match scrutinee with
                            | PsVerifiedIrExpr.var _ => true
                            | PsVerifiedIrExpr.literal literal =>
                                match literal with
                                | PsVerifiedIrLiteral.natural _ | PsVerifiedIrLiteral.integer _ => true
                                | _ => false
                            | _ => false;
                          let isNat := psNameEq inductiveInfo.coreName psNatName;
                          let isInt := psNameEq inductiveInfo.coreName psIntName;
                          let scalarType := if isNat then PsVerifiedIrPrimitiveType.nat
                            else PsVerifiedIrPrimitiveType.int;
                          let scalarMajorName : Option String :=
                            if isNat || isInt then
                              if majorIsValue then Option.none
                              else Option.some
                                (psErasureLocalName scope "_psScalarMajor" "_psScalarMajor"
                                  scope.localContext.nextId)
                            else Option.none;
                          let majorNameFresh : Bool :=
                            match scalarMajorName with
                            | Option.none => true
                            | Option.some localName =>
                                psErasureBoolNot (psErasureLocalNameUsed scope localName);
                          if psErasureBoolNot majorNameFresh then
                            Except.error PsErasureError.fuelExhausted
                          else
                            -- Reserve only the emitted name before opening minors.
                            -- byCore and every Core local remain unchanged. count is
                            -- the freshness bound and includes this one reservation.
                            let minorScope : PsErasureScope :=
                              match scalarMajorName with
                              | Option.none => scope
                              | Option.some localName =>
                                  let reservedNames : PsErasureDeclarationNames :=
                                    { scope.declarationNames with
                                      byOutput := psErasureIndexInsert Bool scope.declarationNames.byOutput
                                        (PsName.str PsName.anonymous localName) true
                                      count := scope.declarationNames.count + 1 };
                                  { scope with declarationNames := reservedNames };
                            match
                                psEraseMatchAlternatives
                                  environment
                                  eraseAt
                                  minorScope
                                  substitutions
                                  recursionPlan
                                  view.args
                                  minorStart
                                  0
                                  inductiveInfo.constructors
                                  [] with
                            | Except.error error => Except.error error
                            | Except.ok alternatives =>
                                if psNameEq inductiveInfo.coreName psBoolName then
                                  match alternatives with
                                  | [(_, [], onFalse), (_, [], onTrue)] =>
                                    Except.ok (some (.ifE scrutinee onTrue onFalse))
                                  | _ => Except.error PsErasureError.binderMismatch
                                else if isNat || isInt then
                                  let majorReference : PsVerifiedIrExpr :=
                                    match scalarMajorName with
                                    | Option.none => scrutinee
                                    | Option.some localName => PsVerifiedIrExpr.var localName;
                                  let lowered := if isNat then
                                    psEraseNatRecursorAlternatives majorReference alternatives
                                    else psEraseIntRecursorAlternatives majorReference alternatives;
                                  match lowered with
                                  | Except.error error => Except.error error
                                  | Except.ok lowered =>
                                      let result : PsVerifiedIrExpr :=
                                        match scalarMajorName with
                                        | Option.none => lowered
                                        | Option.some localName =>
                                            PsVerifiedIrExpr.letE localName
                                              (PsVerifiedIrType.primitive scalarType)
                                              scrutinee lowered;
                                      Except.ok (Option.some result)
                                else
                                  let matched : PsVerifiedIrExpr :=
                                    PsVerifiedIrExpr.matchE inductiveInfo.name
                                      typeArguments scrutinee alternatives;
                                  if psListIsEmpty alternatives then
                                    match psErasureExprListAt view.args inductiveInfo.numParams with
                                    | Option.none =>
                                        Except.error PsErasureError.unsupportedApplication
                                    | Option.some motive =>
                                        -- Core already checked the motive at this major.
                                        -- A typed IR let carries that result into inference-only
                                        -- positions without changing the original IR model.
                                        match psEraseRuntimeType environment scope
                                            (((view.args.drop (minorStart + inductiveInfo.constructors.length)).take
                                              inductiveInfo.numIndices ++ [major]).foldl PsExpr.app motive) with
                                        | Except.error error => Except.error error
                                        | Except.ok resultType =>
                                            let resultName :=
                                              psErasureLocalName scope "emptyResult" "emptyResult"
                                                scope.localContext.nextId;
                                            if psErasureLocalNameUsed scope resultName then
                                              Except.error PsErasureError.fuelExhausted
                                            else
                                              Except.ok (Option.some
                                                (PsVerifiedIrExpr.letE resultName resultType
                                                  matched (PsVerifiedIrExpr.var resultName)))
                                  else Except.ok (Option.some matched)
  | _ => Except.ok Option.none

def psErasureFindProjectionField
    (index : Nat)
    (fields : List PsRuntimeStructureField) : Option PsRuntimeStructureField :=
  match fields with
  | List.nil => Option.none
  | List.cons field rest =>
      if Nat.beq field.projectionIndex index then Option.some field
      else psErasureFindProjectionField index rest


def psErasureIrUsesNameWithFuel (fuel : Nat) : PsVerifiedIrExpr -> String -> Bool :=
  match fuel with
  | Nat.zero => fun (_expr : PsVerifiedIrExpr) (_name : String) => true
  | Nat.succ remaining =>
      fun (expr : PsVerifiedIrExpr) (name : String) =>
        let smaller : PsVerifiedIrExpr -> String -> Bool := psErasureIrUsesNameWithFuel remaining;
        let uses : PsVerifiedIrExpr -> Bool := fun (value : PsVerifiedIrExpr) => smaller value name;
        let parameterUses : PsVerifiedIrParameter -> Bool :=
          fun (parameter : PsVerifiedIrParameter) => psStringEq parameter.name name;
        let bindingUses : PsVerifiedIrMatchBinding -> Bool :=
          fun (binding : PsVerifiedIrMatchBinding) => psStringEq binding.name name;
        let fieldUses : (String × PsVerifiedIrExpr) -> Bool :=
          fun (field : String × PsVerifiedIrExpr) =>
            match field with
            | Prod.mk _ value => smaller value name;
        let alternativeUses : (String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr) -> Bool :=
          fun (alternative : String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr) =>
            match alternative with
            | Prod.mk _ detail =>
                match detail with
                | Prod.mk bindings body =>
                    if psListAny bindingUses bindings then true else smaller body name;
        match expr with
        | .unreachable _ | .panic .. => false
        | .literal _ => false
        | .var value => psStringEq value name
        | .intrinsic _ _ arguments => psListAny uses arguments
        | .lambda parameters _ body =>
            if psListAny parameterUses parameters then true else smaller body name
        | .call fn _ arguments => if smaller fn name then true else psListAny uses arguments
        | .letE localName _ value body =>
            if psStringEq localName name then true
            else if smaller value name then true else smaller body name
        | .ifE condition thenBranch elseBranch =>
            if smaller condition name then true
            else if smaller thenBranch name then true else smaller elseBranch name
        | .record _ _ fields => psListAny fieldUses fields
        | .projection _ _ target _ => smaller target name
        | .constructor _ _ _ fields => psListAny fieldUses fields
        | .matchE _ _ scrutinee alternatives =>
            if smaller scrutinee name then true else psListAny alternativeUses alternatives


-- A generic declaration with no runtime binders still needs an entry at which
-- its erased type lambda is applied. The ignored Unit parameter is IR-only.
def psErasureIgnoredUnitNameWithFuel
    (scope : PsErasureScope) (body : PsVerifiedIrExpr)
    (fuel index : Nat) : Except PsErasureError String :=
  match fuel with
  | Nat.zero => Except.error PsErasureError.fuelExhausted
  | Nat.succ remaining =>
      let raw := String.Internal.append "_psTypeUnit$" (psNatToString index);
      let name := psErasureLocalName scope raw "_psTypeUnit" index;
      if psErasureLocalNameUsed scope name then
        psErasureIgnoredUnitNameWithFuel scope body remaining (Nat.succ index)
      else if psErasureIrUsesNameWithFuel 4096 body name then
        psErasureIgnoredUnitNameWithFuel scope body remaining (Nat.succ index)
      else Except.ok name

def psErasureEtaNameWithFuel
    (body : PsVerifiedIrExpr) (used : List PsVerifiedIrParameter)
    (fuel : Nat) (index : Nat) : Except PsErasureError String :=
  match fuel with
  | Nat.zero => Except.error PsErasureError.fuelExhausted
  | Nat.succ remaining =>
      let candidate := String.Internal.append "__ps_eta_" (psNatToString index);
      let sameName : PsVerifiedIrParameter -> Bool := fun (parameter : PsVerifiedIrParameter) => psStringEq parameter.name candidate;
      if psListAny sameName used then
        psErasureEtaNameWithFuel body used remaining (Nat.succ index)
      else if psErasureIrUsesNameWithFuel 4096 body candidate then
        psErasureEtaNameWithFuel body used remaining (Nat.succ index)
      else Except.ok candidate

def psErasureEtaParameters
    (body : PsVerifiedIrExpr) (types : List PsVerifiedIrType) :
    List PsVerifiedIrParameter -> Nat -> Except PsErasureError (List PsVerifiedIrParameter) :=
  match types with
  | List.nil => fun (_used : List PsVerifiedIrParameter) (_index : Nat) => Except.ok List.nil
  | List.cons type rest =>
      let smaller : List PsVerifiedIrParameter -> Nat -> Except PsErasureError (List PsVerifiedIrParameter) := psErasureEtaParameters body rest;
      fun (used : List PsVerifiedIrParameter) (index : Nat) =>
        match psErasureEtaNameWithFuel body used 4096 index with
        | Except.error error => Except.error error
        | Except.ok name =>
            let parameter := PsVerifiedIrParameter.mk name type;
            match smaller (List.cons parameter used) (Nat.succ index) with
            | Except.error error => Except.error error
            | Except.ok parameters => Except.ok (List.cons parameter parameters)

def psErasureEtaFunction
    (parameters : List PsVerifiedIrParameter) (resultType : PsVerifiedIrType) (body : PsVerifiedIrExpr) :
    Except PsErasureError PsVerifiedIrExpr :=
  if psListIsEmpty parameters then Except.ok (PsVerifiedIrExpr.lambda parameters resultType body)
  else
    match resultType with
    | PsVerifiedIrType.function argumentTypes finalResult =>
        match psErasureEtaParameters body argumentTypes parameters 0 with
        | Except.error error => Except.error error
        | Except.ok extraParameters =>
            let asVariable : PsVerifiedIrParameter -> PsVerifiedIrExpr :=
              fun (parameter : PsVerifiedIrParameter) => PsVerifiedIrExpr.var parameter.name;
            Except.ok
              (PsVerifiedIrExpr.lambda (psListAppend parameters extraParameters) finalResult
                (PsVerifiedIrExpr.call body List.nil (psListMap asVariable extraParameters)))
    | _ => Except.ok (PsVerifiedIrExpr.lambda parameters resultType body)

-- Audited nullary runtime identities are independent of whether their checked
-- declaration is a constructor, an alias definition, or a foundation primitive.
-- Unit is Lean's abbreviation for PUnit; both have the same runtime carrier.
def psErasureLiteral (name : PsName) : Option PsVerifiedIrLiteral :=
  if psNameEq name psBoolTrueName then some (.bool true)
  else if psNameEq name psBoolFalseName then some (.bool false)
  else if psNameEq name psUnitUnitName ||
      psNameEq name (psNameAppendStr (psRootName "PUnit") "unit") then some .unit
  else if psNameEq name psNatZeroName then some (.natural 0)
  else none

structure PsErasureSpecialEntry where
  arity : Nat
  mayComplete : Bool

-- Only installed intrinsic heads and prepared constructor/recursor metadata
-- supply a special boundary. An arbitrary axiom is not a runtime entry.
def psErasureSpecialEntry
    (scope : PsErasureScope) (name : PsName) : Option PsErasureSpecialEntry :=
  let text := psNameToString name;
  let named : String -> Bool := fun (candidate : String) => psStringEq text candidate;
  if let some arity := psErasureFloatEntryArity name then
    some (PsErasureSpecialEntry.mk arity true)
  else if let some arity := PsUtf8Runtime.arity name then
    some (PsErasureSpecialEntry.mk arity true)
  else if let some arity := PsPlatformRuntime.arity name then
    some (PsErasureSpecialEntry.mk arity true)
  else if let some arity := psErasureUnsignedEntryArity name then
    some (PsErasureSpecialEntry.mk arity true)
  else if named "Eq.rec" then some (PsErasureSpecialEntry.mk 6 false)
  else if named "False.elim" || named "False.rec" then some (PsErasureSpecialEntry.mk 2 false)
  else if psListAny named
      ["Int.ofNat", "Int.repr", "Int.toNat", "Int.negSucc", "Int.neg", "Nat.succ",
        "Bool.not", "Char.ofNat", "Char.toNat", "String.Pos.Raw.mk",
        "String.Pos.Raw.byteIdx", "String.singleton", "String.Internal.length",
        "String.utf8ByteSize", "String.hash"] then
    Option.some (PsErasureSpecialEntry.mk 1 true)
  else if psListAny named
      ["mixHash", "Int.add", "Int.sub", "Int.mul", "Nat.add", "Nat.sub", "Nat.mul",
        "Nat.shiftLeft", "Nat.shiftRight", "Int.pow", "Nat.pow", "Nat.div", "Nat.mod", "Nat.beq", "Nat.ble", "Nat.blt", "Bool.and",
        "Bool.or", "String.push", "String.Internal.append", "String.Internal.next",
        "String.Internal.get", "String.Internal.atEnd", "Array.emptyWithCapacity",
        "Array.size", "Array.mk", "Array.toList"] then
    Option.some (PsErasureSpecialEntry.mk 2 true)
  else if psListAny named
      ["String.Internal.extract", "Prod.fst", "Prod.snd", "Array.push"] then
    Option.some (PsErasureSpecialEntry.mk 3 true)
  else if psListAny named
      ["Array.getInternal", "Array.getD", "Array.setIfInBounds", "Array.map"] then
    Option.some (PsErasureSpecialEntry.mk 4 true)
  else if named "Array.set" || named "Array.filter" then
    Option.some (PsErasureSpecialEntry.mk 5 true)
  else if named "Array.foldl" then
    Option.some (PsErasureSpecialEntry.mk 7 true)
  else if named "Decidable.intro" then
    Option.some (PsErasureSpecialEntry.mk 3 true)
  else if psListAny named ["Decidable.isTrue", "Decidable.isFalse", "Decidable.decide",
      "Bool.decEq", "Bool.beq", "Nat.decEq", "String.decEq", "Int.decEq", "Int.decLt", "Int.decLe"] then
    Option.some (PsErasureSpecialEntry.mk 2 true)
  else if psNameEq name psIteName || named "dite" then
    Option.some (PsErasureSpecialEntry.mk 5 false)
  else
    match psErasureLookupStructure scope.runtimeStructureConstructors name with
    | Option.some info =>
        Option.some
          (PsErasureSpecialEntry.mk
            (Nat.add info.numParams info.numFields) true)
    | Option.none =>
        match psErasureLookupConstructor scope.runtimeConstructors name with
        | Option.some info =>
            Option.some
              (PsErasureSpecialEntry.mk
                (Nat.add info.numParams info.numFields) true)
        | Option.none =>
            match psErasureLookupRecursor scope.runtimeRecursors name with
            | Option.some info =>
                Option.some
                  (PsErasureSpecialEntry.mk
                    (psRuntimeRecursorArity info)
                    false)
            | Option.none =>
                match psErasureLookupStructureRecursor scope name with
                | Option.some info =>
                    Option.some
                      (PsErasureSpecialEntry.mk (Nat.add info.numParams 3) false)
                | Option.none => Option.none

structure PsErasureSpecialCompletion where
  scope : PsErasureScope
  term : PsExpr
  type : PsExpr
  parametersRev : List PsVerifiedIrParameter
  bindingsRev : List (Prod PsVerifiedIrParameter PsVerifiedIrExpr)

-- Supplied runtime computations are captured before any missing parameter lambda.
-- The fresh Core lets retain their original values for type-level substitution;
-- runtimeExpressions maps each opened ID to its one captured runtime value.
def psEraseCompleteSpecialWithFuel
    (eraseAt : PsErasureScope -> PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (environment : PsEnvironment) (fuel count : Nat)
    (arguments : List PsExpr) (state : PsErasureSpecialCompletion) :
    Except PsErasureError PsVerifiedIrExpr :=
  match fuel with
  | Nat.zero => Except.error PsErasureError.fuelExhausted
  | Nat.succ remaining =>
      match count with
      | Nat.zero =>
          if psListIsEmpty arguments then
            match psEraseRuntimeType environment state.scope state.type with
            | Except.error error => Except.error error
            | Except.ok resultType =>
                match eraseAt state.scope state.term with
                | Except.error error => Except.error error
                | Except.ok body =>
                    Except.ok
                      (psErasureWrapApplicationCaptures state.bindingsRev
                        (Prod.snd
                          (psErasureCurryParameters
                            (psListReverse state.parametersRev) resultType body)))
          else Except.error PsErasureError.unsupportedApplication
      | Nat.succ restCount =>
          match psWhnf environment psMetaEmpty state.scope.localContext state.type with
          | PsExpr.forallE name domain body binder =>
              let kind :=
                psErasureClassifyBinder environment state.scope.localContext domain;
              match arguments with
              | List.cons argument rest =>
                  match kind with
                  | PsErasedBinderKind.runtime =>
                      match eraseAt state.scope argument with
                      | Except.error error => Except.error error
                      | Except.ok value =>
                          match psErasureCaptureApplicationValue environment
                              (PsErasureApplicationCaptureState.mk
                                state.scope List.nil state.bindingsRev)
                              "_psSpecialArg" (Option.some domain) value with
                          | Except.error error => Except.error error
                          | Except.ok captured =>
                              match captured.valuesRev with
                              | List.nil => Except.error PsErasureError.binderMismatch
                              | List.cons capturedValue _ =>
                                  let pushed :=
                                    psLocalPushLet captured.scope.localContext name domain argument;
                                  let nextScope := { captured.scope with
                                    localContext := pushed.context
                                    runtimeExpressions := (List.cons (Prod.mk pushed.id capturedValue)
                                      captured.scope.runtimeExpressions) };
                                  let openedArgument := PsExpr.fvar pushed.id;
                                  psEraseCompleteSpecialWithFuel eraseAt environment
                                    remaining restCount rest
                                    (PsErasureSpecialCompletion.mk nextScope
                                      (PsExpr.app state.term openedArgument)
                                      (psExprInstantiate1 body openedArgument)
                                      state.parametersRev captured.bindingsRev)
                  | _ =>
                      psEraseCompleteSpecialWithFuel eraseAt environment
                        remaining restCount rest
                        (PsErasureSpecialCompletion.mk state.scope
                          (PsExpr.app state.term argument)
                          (psExprInstantiate1 body argument)
                          state.parametersRev state.bindingsRev)
              | List.nil =>
                  match kind with
                  | PsErasedBinderKind.type | PsErasedBinderKind.index =>
                      Except.error PsErasureError.unsupportedApplication
                  | PsErasedBinderKind.proof =>
                      let pushed := psLocalPushBinding state.scope.localContext name domain binder
                      let (parameter, nextScope) :=
                        psErasureOpenProofSlot state.scope pushed.context pushed.id
                      let openedArgument := PsExpr.fvar pushed.id
                      psEraseCompleteSpecialWithFuel eraseAt environment
                        remaining restCount List.nil
                        (PsErasureSpecialCompletion.mk nextScope
                          (PsExpr.app state.term openedArgument)
                          (psExprInstantiate1 body openedArgument)
                          (parameter :: state.parametersRev) state.bindingsRev)
                  | PsErasedBinderKind.runtime =>
                      match psEraseRuntimeType environment state.scope domain with
                      | Except.error error => Except.error error
                      | Except.ok parameterType =>
                          let pushed :=
                            psLocalPushBinding state.scope.localContext name domain binder;
                          let parameterName :=
                            psErasureLocalName state.scope (psNameToString name) "arg" pushed.id;
                          if psErasureLocalNameUsed state.scope parameterName then
                            Except.error PsErasureError.fuelExhausted
                          else
                            let nextScope := { state.scope with
                              localContext := pushed.context
                              runtimeLocals := (List.cons (Prod.mk pushed.id parameterName) state.scope.runtimeLocals) };
                            let openedArgument := PsExpr.fvar pushed.id;
                            psEraseCompleteSpecialWithFuel eraseAt environment
                              remaining restCount List.nil
                              (PsErasureSpecialCompletion.mk nextScope
                                (PsExpr.app state.term openedArgument)
                                (psExprInstantiate1 body openedArgument)
                                (List.cons
                                  (PsVerifiedIrParameter.mk parameterName parameterType)
                                  state.parametersRev)
                                state.bindingsRev)
          | _ => Except.error PsErasureError.unsupportedApplication

-- Metadata supplies the proof-recursion boundary for user families as well
-- as the prelude. No constructor tag or proof value is retained at runtime.
def psErasureProofRecursorEntry (environment : PsEnvironment) (name : PsName) :
    Option PsErasureSpecialEntry := do
  let info ← psEnvironmentFindRecursor environment name
  let [familyName] := info.inductiveNames | none
  let family ← psEnvironmentFindInductive environment familyName
  let proofFamily ← (psInductiveIsProp environment family).toOption
  if !proofFamily || info.numMotives != 1 || info.numMinors != family.constructors.length then none else
    return .mk (info.numParams + 1 + info.numMinors + info.numIndices + 1) false

def psEraseRepresentationPreservingMinor
    (eraseAt : PsErasureScope → PsExpr → Except PsErasureError PsVerifiedIrExpr)
    (environment : PsEnvironment) (scope : PsErasureScope) (application minor : PsExpr) :
    Except PsErasureError PsVerifiedIrExpr := do
  let target ← psErasureCheckedTypeView environment scope.localContext application
  let source ← psErasureCheckedTypeView environment scope.localContext minor
  let sourceType ← psEraseRuntimeType environment scope source
  let targetType ← psEraseRuntimeType environment scope target
  if (psIrCheckTypeEqual 4096 sourceType targetType).toOption != some true then
    throw .unsupportedRuntimeTerm
  eraseAt scope minor

-- Open the constructor's erased proof fields before erasing its minor.
-- Erasing the un-applied minor would retain a proof-guarded Unit call slot.
-- Public nonproof index fields require explicit index substitution later.
def psEraseProofMinorFields
    (eraseAt : PsErasureScope → PsExpr → Except PsErasureError PsVerifiedIrExpr)
    (environment : PsEnvironment) (count : Nat) (scope : PsErasureScope)
    (application minor : PsExpr) : Except PsErasureError PsVerifiedIrExpr := do
  match count with
  | 0 => psEraseRepresentationPreservingMinor eraseAt environment scope application minor
  | count + 1 =>
    let type ← psErasureCheckedTypeView environment scope.localContext minor
    let .forallE name domain body binder := psWhnf environment psMetaEmpty scope.localContext type
      | throw .binderMismatch
    if !psErasureIsProp environment scope.localContext domain then throw .unsupportedRuntimeTerm
    let pushed := psLocalPushBinding scope.localContext name domain binder
    let value := PsExpr.fvar pushed.id
    let applied := match psWhnf environment psMetaEmpty scope.localContext minor with
      | .lam _ _ body _ => psExprInstantiate1 body value
      | _ => PsExpr.app minor value
    let scope := { scope with localContext := pushed.context, erasedLocals := pushed.id :: scope.erasedLocals }
    psEraseProofMinorFields eraseAt environment count scope application applied

-- Decidable has a single Boolean payload in Lean 4.35.0. The reflection proof never
-- becomes runtime data. Conditions use the actual dictionary, not its Prop syntax.
def psEraseDecisionApplication
    (eraseAt : PsErasureScope → PsExpr → Except PsErasureError PsVerifiedIrExpr)
    (environment : PsEnvironment) (scope : PsErasureScope)
    (view : PsErasureAppView) : Except PsErasureError (Option PsVerifiedIrExpr) := do
  let .constE name _ := view.head | return none
  let text := psNameToString name
  let erase := eraseAt scope
  match text, view.args with
  | "Decidable.intro", [_, choice, _] => return some (← erase choice)
  | "Decidable.isTrue", [_, _] => return some (.literal (.bool true))
  | "Decidable.isFalse", [_, _] => return some (.literal (.bool false))
  | "Decidable.decide", [_, decision] => return some (← erase decision)
  | "Nat.decEq", [left, right] =>
    return some (.intrinsic .natEq [] [← erase left, ← erase right])
  | "String.decEq", [left, right] =>
    return some (.intrinsic .stringEq [] [← erase left, ← erase right])
  | "Bool.decEq", [left, right] | "Bool.beq", [left, right] =>
    return some (.intrinsic .boolEq [] [← erase left, ← erase right])
  | "Int.decEq", [left, right] =>
    return some (.intrinsic .intEq [] [← erase left, ← erase right])
  | "Int.decLt", [left, right] =>
    return some (.intrinsic .intLt [] [← erase left, ← erase right])
  | "Int.decLe", [left, right] =>
    return some (.intrinsic .intLe [] [← erase left, ← erase right])
  | "ite", [_, _, decision, yes, no] =>
    return some (.ifE (← erase decision) (← erase yes) (← erase no))
  | "dite", [_, _, decision, yes, no] =>
    let application := psExprApplyMany view.head view.args
    let yes ← psEraseProofMinorFields eraseAt environment 1 scope application yes
    let no ← psEraseProofMinorFields eraseAt environment 1 scope application no
    return some (.ifE (← erase decision) yes no)
  | _, _ => return none

-- Proof transports preserve the erased representation. Empty eliminators
-- become typed unreachable nodes. General recursive proof elimination needs
-- its own recursion lowering; it is never guessed from constructor count.
def psEraseLogicalApplication
    (eraseAt : PsErasureScope -> PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (environment : PsEnvironment) (scope : PsErasureScope) (view : PsErasureAppView) :
    Except PsErasureError (Option PsVerifiedIrExpr) := do
  let .constE name _ := view.head | return none
  if psNameEq name (psNameAppendStr (psRootName "False") "elim") then
    let some target := view.args[0]? | throw .unsupportedApplication
    let type ← psEraseRuntimeType environment scope target
    return some (.unreachable type)
  let application := view.args.foldl PsExpr.app view.head
  if psNameEq name (psNameAppendStr psEqName "rec") then
    let some minor := view.args[3]? | throw .unsupportedApplication
    return some (← psEraseRepresentationPreservingMinor eraseAt environment scope application minor)
  let some recursor := psRecursorApplication environment application | return none
  let proofFamily ← (psInductiveIsProp environment recursor.family).mapError
    (fun _ => PsErasureError.unsupportedRuntimeTerm)
  if !proofFamily then return none
  match recursor.family.constructors with
  | [] =>
    let type ← psErasureCheckedTypeView environment scope.localContext application
    return some (.unreachable (← psEraseRuntimeType environment scope type))
  | [constructorName] =>
    let some constructor := psEnvironmentFindConstructor environment constructorName
      | throw .unsupportedRuntimeTerm
    if !constructor.recursiveFields.isEmpty then throw .unsupportedRuntimeTerm
    let some minor := view.args[recursor.info.numParams + 1]? | throw .unsupportedApplication
    return some (← psEraseProofMinorFields eraseAt environment constructor.numFields scope application minor)
  | _ => throw .unsupportedRuntimeTerm

def psEraseSpecialBoundary
    (eraseAt : PsErasureScope -> PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (environment : PsEnvironment) (scope : PsErasureScope)
    (view : PsErasureAppView) : Except PsErasureError (Option PsVerifiedIrExpr) :=
  match view.head with
  | PsExpr.constE name _ =>
      match psErasureLiteral name with
      | some value =>
          if view.args.isEmpty then .ok (some (.literal value))
          else .error .unsupportedApplication
      | none =>
      match (psErasureSpecialEntry scope name).orElse
          (fun _ => psErasureProofRecursorEntry environment name) with
      | Option.none => Except.ok Option.none
      | Option.some entry =>
          let supplied := psListLength view.args;
          if Nat.beq supplied entry.arity then psEraseLogicalApplication eraseAt environment scope view
          else
            match psInferType environment psMetaEmpty scope.localContext view.head with
            | Except.error _ => Except.error PsErasureError.unsupportedApplication
            | Except.ok headType =>
                if Nat.ble entry.arity supplied then
                  let suppliedPrefix := psListTake entry.arity view.args;
                  let suffix := psErasureDropPrefix PsExpr entry.arity view.args;
                  match psErasureApplyCoreType environment scope headType suppliedPrefix with
                  | Except.error error => Except.error error
                  | Except.ok resultType =>
                      match eraseAt scope (psErasureApplyCoreArguments view.head suppliedPrefix) with
                      | Except.error error => Except.error error
                      | Except.ok lowered =>
                          match psEraseCanonicalArguments (eraseAt scope)
                              environment scope lowered resultType suffix with
                          | Except.error error => Except.error error
                          | Except.ok result => Except.ok (Option.some result)
                else if entry.mayComplete then
                  match psEraseCompleteSpecialWithFuel eraseAt environment 4096
                      entry.arity view.args
                      (PsErasureSpecialCompletion.mk scope view.head headType List.nil List.nil) with
                  | Except.error error => Except.error error
                  | Except.ok result => Except.ok (Option.some result)
                else Except.error PsErasureError.unsupportedApplication
  | _ => Except.ok Option.none

def psEraseCanonicalApplication
    (erase : PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (environment : PsEnvironment) (scope : PsErasureScope)
    (view : PsErasureAppView) : Except PsErasureError PsVerifiedIrExpr :=
  match psErasureCheckedTypeView environment scope.localContext view.head with
  | Except.error _ => Except.error PsErasureError.unsupportedApplication
  | Except.ok headType =>
      match erase view.head with
      | Except.error error => Except.error error
      | Except.ok loweredHead =>
          psEraseCanonicalArguments erase environment scope loweredHead headType view.args

-- Public expression erasure may receive an ordinary name scope without the
-- module prepass. A cache miss reads the actual declared value, never its fully
-- instantiated result telescope. The normal module path uses the cached entry.
def psErasureResolveEntry
    (environment : PsEnvironment) (scope : PsErasureScope) (name : PsName) :
    Except PsErasureError (Option PsErasureEntryInfo) :=
  match psErasureLookupEntry scope.declarationNames name with
  | Option.some entry => Except.ok (Option.some entry)
  | Option.none =>
      match psEnvironmentFind environment name with
      | Option.none => Except.ok Option.none
      | Option.some declaration =>
          match declaration with
          | PsDeclaration.definitionDecl _ _ type value =>
              if psErasureIsNonRuntimeDeclaration environment type then Except.ok Option.none
              else
                match psErasureEntryInfoWithFuel environment 4096 psLocalEmpty type value with
                | Except.error error => Except.error error
                | Except.ok entry => Except.ok (Option.some entry)
          | PsDeclaration.partialDecl _ _ type value
          | PsDeclaration.opaqueDecl _ _ type value =>
              if psErasureIsNonRuntimeDeclaration environment type then Except.ok Option.none
              else
                match psErasureEntryInfoWithFuel environment 4096 psLocalEmpty type value with
                | Except.error error => Except.error error
                | Except.ok entry => Except.ok (Option.some entry)
          | _ => Except.ok Option.none

def psEraseGeneralApplication
    (erase : PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (environment : PsEnvironment) (scope : PsErasureScope)
    (view : PsErasureAppView) : Except PsErasureError PsVerifiedIrExpr :=
  match view.head with
  | PsExpr.constE name _ =>
      match psErasureResolveEntry environment scope name with
      | Except.error error => Except.error error
      | Except.ok resolved =>
          match resolved with
          | Option.none =>
              -- End the zero-argument path here: asking canonical erasure to
              -- erase this same unresolved head would recurse without progress.
              if view.args.isEmpty then
                match psErasureLookupName scope.declarationNames name with
                | some known => .ok (.var known)
                | none => .error (.unknownConstant name)
              else psEraseCanonicalApplication erase environment scope view
          | Option.some entry =>
              match psErasureLookupName scope.declarationNames name with
              | Option.none => Except.error (PsErasureError.unknownConstant name)
              | Option.some known =>
                  match psInferType environment psMetaEmpty scope.localContext view.head with
                  | Except.error _ => Except.error PsErasureError.unsupportedApplication
                  | Except.ok headType =>
                      psEraseKnownEntryApplication erase environment scope
                        (PsVerifiedIrExpr.var known) entry headType view.args
  | PsExpr.lam _ domain body _ =>
      match psErasureClassifyBinder environment scope.localContext domain with
      | PsErasedBinderKind.runtime =>
          psEraseCanonicalApplication erase environment scope view
      | _ =>
          -- An immediately applied erased binder is instantiated before body
          -- erasure; its type name must not escape as a free IR type parameter.
          match view.args with
          | List.nil => psEraseCanonicalApplication erase environment scope view
          | List.cons argument rest =>
              erase
                (psErasureApplyCoreArguments
                  (psExprInstantiate1 body argument) rest)
  | _ => psEraseCanonicalApplication erase environment scope view

-- Only the whole expression reached after opening a declaration's actual entry
-- may establish its recursion equation. Child computations retain established
-- IH replacements but cannot manufacture another equation for that declaration.
def psErasureNestedRuntimeScope (scope : PsErasureScope) : PsErasureScope :=
  { scope with currentDefinition := Option.none }

def psEraseRuntimeExprWithFuelWorker
    (environment : PsEnvironment) (fuel : Nat) :
    PsErasureScope -> PsExpr -> Except PsErasureError PsVerifiedIrExpr :=
  match fuel with
  | Nat.zero => fun (_scope : PsErasureScope) (_expr : PsExpr) => Except.error PsErasureError.fuelExhausted
  | Nat.succ remaining =>
    fun (scope : PsErasureScope) (expr : PsExpr) =>
      let smaller : PsErasureScope -> PsExpr -> Except PsErasureError PsVerifiedIrExpr :=
        fun (nextScope : PsErasureScope) (value : PsExpr) =>
          let eraseAtRemainingFuel : PsErasureScope -> PsExpr -> Except PsErasureError PsVerifiedIrExpr :=
            psEraseRuntimeExprWithFuelWorker environment remaining;
          eraseAtRemainingFuel (psErasureNestedRuntimeScope nextScope) value;
      match psErasureExpandUnboxedProjection environment scope expr with
      | some expanded => smaller scope expanded
      | none => match expr with
        | .lit literal =>
            match literal with
            | .natural value =>
                Except.ok
                  (PsVerifiedIrExpr.literal
                    (PsVerifiedIrLiteral.natural value))
            | .string value =>
                Except.ok
                  (PsVerifiedIrExpr.literal
                    (PsVerifiedIrLiteral.string value))
        | .fvar id =>
            match
                psErasureLookupRuntimeExpression
                  scope.runtimeExpressions
                  id with
            | Option.some runtimeExpr => Except.ok runtimeExpr
            | Option.none =>
                match psErasureLookupNat scope.runtimeLocals id with
                | Option.some name => Except.ok (PsVerifiedIrExpr.var name)
                | Option.none =>
                    let typeLocalPresent : Bool :=
                      match psErasureLookupNat scope.typeLocals id with
                      | Option.some _ => true
                      | Option.none => false;
                    if
                        psErasureBoolOr
                          (psErasureNatInList scope.erasedLocals id)
                          typeLocalPresent then
                      Except.error (PsErasureError.erasedLocalUsed id)
                    else
                      Except.error (PsErasureError.unknownLocal id)
        -- Lean 4.35 ToLCNF.visitCore treats constants as applications with no
        -- arguments. One dispatch also handles nullary intrinsics and constructors.
        | .constE _ _ | .app _ _ =>
            let view := psErasureAppView expr;
            let erase :=
              smaller scope;
            let eraseAt :=
              fun (nextScope : PsErasureScope) (value : PsExpr) =>
                smaller nextScope
                  value;
            match psEraseSpecialBoundary eraseAt environment scope view with
            | Except.error error => Except.error error
            | Except.ok special =>
                match special with
                | Option.some result => Except.ok result
                | Option.none =>
                    match psEraseDecisionApplication eraseAt environment scope view with
                    | Except.error error => Except.error error
                    | Except.ok candidate =>
                        match candidate with
                        | Option.some lowered => Except.ok lowered
                        | Option.none =>
                            match
                                psErasePrimitiveApplication
                                  environment
                                  scope
                                  erase
                                  view with
                            | Except.error error => Except.error error
                            | Except.ok candidate =>
                                match candidate with
                                | Option.some lowered => Except.ok lowered
                                | Option.none =>
                                    match
                                        psEraseRuntimeStructureApplication
                                          environment
                                          scope
                                          erase
                                          view with
                                    | Except.error error => Except.error error
                                    | Except.ok candidate =>
                                        match candidate with
                                        | Option.some lowered => Except.ok lowered
                                        | Option.none =>
                                            match
                                                psEraseRuntimeConstructorApplication
                                                  environment
                                                  scope
                                                  erase
                                                  view with
                                            | Except.error error => Except.error error
                                            | Except.ok candidate =>
                                                match candidate with
                                                | Option.some lowered => Except.ok lowered
                                                | Option.none =>
                                                    match
                                                        psEraseRuntimeRecursorApplication
                                                          environment
                                                          scope
                                                          eraseAt
                                                          view with
                                                    | Except.error error => Except.error error
                                                    | Except.ok candidate =>
                                                        match candidate with
                                                        | Option.some lowered => Except.ok lowered
                                                        | Option.none =>
                                                            match psEraseRuntimeStructureRecursorApplication
                                                                environment scope eraseAt view with
                                                            | Except.error error => Except.error error
                                                            | Except.ok structureRecursor =>
                                                                match structureRecursor with
                                                                | Option.some lowered => Except.ok lowered
                                                                | Option.none =>
                                                                    psEraseGeneralApplication erase environment scope view
        | .lam name type body binder =>
            let kind :=
              psErasureClassifyBinder
                environment
                scope.localContext
                type;
            let pushed :=
              psLocalPushBinding
                scope.localContext
                name
                type
                binder;
            let openedBody :=
              psExprInstantiate1 body (PsExpr.fvar pushed.id);
            match kind with
            | .runtime =>
                let parameterName :=
                  psErasureLocalName scope
                    (psNameToString name)
                    "arg" pushed.id;
                match psEraseRuntimeType environment scope type with
                | Except.error error => Except.error error
                | Except.ok parameterType =>
                    let nextScope : PsErasureScope := { scope with
                      localContext := pushed.context
                      runtimeLocals :=
                        List.cons (Prod.mk pushed.id parameterName) scope.runtimeLocals
                      typeLocals := scope.typeLocals
                      erasedLocals := scope.erasedLocals
                      declarationNames := scope.declarationNames
                      runtimeConstructors := scope.runtimeConstructors
                      runtimeRecursors := scope.runtimeRecursors
                      runtimeStructures := scope.runtimeStructures
                      runtimeStructureConstructors := scope.runtimeStructureConstructors
                      runtimeExpressions := scope.runtimeExpressions
                      currentDefinition := scope.currentDefinition
                    };
                    match
                        smaller nextScope
                          openedBody with
                    | Except.error error => Except.error error
                    | Except.ok loweredBody =>
                        match
                            psErasureCheckedTypeView
                              environment
                              nextScope.localContext
                              openedBody with
                        | Except.error _ =>
                            Except.error PsErasureError.unsupportedRuntimeTerm
                        | Except.ok bodyType =>
                            match psEraseRuntimeType environment nextScope bodyType with
                            | Except.error error => Except.error error
                            | Except.ok resultType =>
                                Except.ok
                                  (PsVerifiedIrExpr.lambda
                                    [PsVerifiedIrParameter.mk parameterName parameterType]
                                    resultType loweredBody)
            | .index =>
                let nextScope := { scope with
                  localContext := pushed.context
                  erasedLocals := pushed.id :: scope.erasedLocals }
                smaller nextScope openedBody
            | .type =>
                let typeName := String.Internal.append "T" (psNatToString pushed.id);
                let nextScope : PsErasureScope := { scope with
                  localContext := pushed.context
                  runtimeLocals := scope.runtimeLocals
                  typeLocals :=
                    List.cons (Prod.mk pushed.id typeName) scope.typeLocals
                  erasedLocals := List.cons pushed.id scope.erasedLocals
                  declarationNames := scope.declarationNames
                  runtimeConstructors := scope.runtimeConstructors
                  runtimeRecursors := scope.runtimeRecursors
                  runtimeStructures := scope.runtimeStructures
                  runtimeStructureConstructors := scope.runtimeStructureConstructors
                  runtimeExpressions := scope.runtimeExpressions
                  currentDefinition := scope.currentDefinition
                };
                smaller nextScope
                  openedBody
            | .proof => do
                let (parameter, proofScope) := psErasureOpenProofSlot scope pushed.context pushed.id
                let nextScope := psErasureNestedRuntimeScope proofScope
                let loweredBody ← smaller nextScope openedBody
                let bodyType ← psErasureCheckedTypeView environment nextScope.localContext openedBody
                let resultType ← psEraseRuntimeType environment nextScope bodyType
                return .lambda [parameter] resultType loweredBody
        | .letE name type value body =>
            let kind :=
              psErasureClassifyBinder
                environment
                scope.localContext
                type;
            match kind with
            | .runtime =>
                match psEraseRuntimeType environment scope type with
                | Except.error error => Except.error error
                | Except.ok loweredType =>
                    match
                        smaller scope
                          value with
                    | Except.error error => Except.error error
                    | Except.ok loweredValue =>
                        let pushed :=
                          psLocalPushLet
                            scope.localContext
                            name
                            type
                            value;
                        let localName :=
                          psErasureLocalName scope
                            (psNameToString name)
                            "local" pushed.id;
                        let nextScope : PsErasureScope := { scope with
                          localContext := pushed.context
                          runtimeLocals :=
                            List.cons (Prod.mk pushed.id localName) scope.runtimeLocals
                          typeLocals := scope.typeLocals
                          erasedLocals := scope.erasedLocals
                          declarationNames := scope.declarationNames
                          runtimeConstructors := scope.runtimeConstructors
                          runtimeRecursors := scope.runtimeRecursors
                          runtimeStructures := scope.runtimeStructures
                          runtimeStructureConstructors := scope.runtimeStructureConstructors
                          runtimeExpressions := scope.runtimeExpressions
                          currentDefinition := scope.currentDefinition
                        };
                        match
                            smaller nextScope
                              (psExprInstantiate1
                                body
                                (PsExpr.fvar pushed.id)) with
                        | Except.error error => Except.error error
                        | Except.ok loweredBody =>
                            Except.ok
                              (PsVerifiedIrExpr.letE
                                localName
                                loweredType
                                loweredValue
                                loweredBody)
            | _ =>
                smaller scope
                  (psExprInstantiate1 body value)
        | .bvar _ =>
            Except.error PsErasureError.looseBoundVariable
        | .mvar _ =>
            Except.error PsErasureError.unresolvedMetavariable
        | .sortE _ =>
            Except.error PsErasureError.unsupportedRuntimeTerm
        | .forallE _ _ _ _ =>
            Except.error PsErasureError.unsupportedRuntimeTerm
        | .proj typeName index target =>
            -- RC4 Decidable is represented by its sole computational Bool
            -- field. The reflection field has no runtime projection.
            if psNameEq typeName psDecidableName then
              if index == 0 then smaller scope target
              else Except.error PsErasureError.unsupportedRuntimeTerm
            else if let some width := psErasureFloatWidth typeName then do
              if index != 0 then throw .unsupportedRuntimeTerm
              psEraseFloatProjection scope width (← smaller scope target)
            else if let some width := psErasureUnsignedWidth typeName then do
              if index != 0 then throw .unsupportedRuntimeTerm
              psEraseUnsignedProjection scope (← psErasureResolveWord scope width) (← smaller scope target)
            else if let some width := psErasureSignedWidth typeName then do
              if index != 0 then throw .unsupportedRuntimeTerm
              return .intrinsic (.signedToUnsigned (← psErasureResolveWord scope width)) []
                [← smaller scope target]
            else if psNameEq typeName psArrayName then do
              if index != 0 then throw .unsupportedRuntimeTerm
              let sourceType ← psErasureCheckedTypeView environment scope.localContext target
              let .named "Array" [element] ← psEraseRuntimeType environment scope sourceType
                | throw .unsupportedRuntimeTerm
              psEraseArrayConversion scope element (← smaller scope target) false
            else match
                psErasureLookupStructure
                  scope.runtimeStructures
                  typeName with
            | Option.none => Except.error PsErasureError.unsupportedRuntimeTerm
            | Option.some structureInfo =>
                if structureInfo.unboxed then
                  if index == 0 then smaller scope target else Except.error .unsupportedRuntimeTerm
                else match psErasureFindProjectionField index structureInfo.fields with
                | Option.none => Except.error PsErasureError.unsupportedRuntimeTerm
                | Option.some field =>
                    let typeArgumentsResult :
                        Except PsErasureError (List PsVerifiedIrType) :=
                      match structureInfo.typeParameters with
                      | [] => Except.ok []
                      | _ =>
                          match
                              psErasureCheckedTypeView
                                environment
                                scope.localContext
                                target with
                          | Except.error _ =>
                              Except.error
                                PsErasureError.unsupportedRuntimeTerm
                          | Except.ok targetType =>
                              match
                                  psEraseRuntimeType
                                    environment
                                    scope
                                    targetType with
                              | Except.error error =>
                                  Except.error error
                              | Except.ok erasedType =>
                                  match erasedType with
                                  | .named ownerName arguments =>
                                      if
                                          psErasureBoolAnd
                                            (psStringEq ownerName structureInfo.name)
                                            (Nat.beq
                                              (psListLength arguments)
                                              (psListLength structureInfo.typeParameters))
                                      then
                                        Except.ok arguments
                                      else
                                        Except.error
                                          PsErasureError.unsupportedRuntimeTerm
                                  | _ =>
                                      Except.error
                                        PsErasureError.unsupportedRuntimeTerm;
                    match typeArgumentsResult with
                    | Except.error error => Except.error error
                    | Except.ok typeArguments =>
                        match
                            smaller scope
                              target with
                        | Except.error error => Except.error error
                        | Except.ok loweredTarget =>
                            Except.ok
                              (PsVerifiedIrExpr.projection
                                structureInfo.name
                                typeArguments
                                loweredTarget
                                field.name)
  
def psEraseRuntimeExprWithFuel
    (environment : PsEnvironment) (scope : PsErasureScope) (fuel : Nat) (expr : PsExpr) :
    Except PsErasureError PsVerifiedIrExpr :=
  psEraseRuntimeExprWithFuelWorker environment fuel scope expr

def psEraseRuntimeExpr
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (expr : PsExpr) :
    Except PsErasureError PsVerifiedIrExpr :=
  psEraseRuntimeExprWithFuel environment scope 4096 expr
