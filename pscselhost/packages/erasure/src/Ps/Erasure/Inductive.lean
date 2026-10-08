import Ps.Erasure.Basic

structure PsPreparedInductiveParameters where
  scope : PsErasureScope
  values : List PsExpr
  typeParameters : List PsVerifiedIrTypeParameter

def psPrepareInductiveParametersWithFuel
    (environment : PsEnvironment) (fuel : Nat) :
    PsErasureScope -> PsExpr -> Nat -> Nat -> List PsExpr -> List PsVerifiedIrTypeParameter -> Except PsErasureError PsPreparedInductiveParameters :=
  match fuel with
  | Nat.zero =>
      fun (_scope : PsErasureScope) (_cursor : PsExpr) (_count : Nat) (_index : Nat) (_values : List PsExpr) (_parameters : List PsVerifiedIrTypeParameter) =>
        Except.error PsErasureError.fuelExhausted
  | Nat.succ remainingFuel =>
      let smaller : PsErasureScope -> PsExpr -> Nat -> Nat -> List PsExpr -> List PsVerifiedIrTypeParameter -> Except PsErasureError PsPreparedInductiveParameters :=
        psPrepareInductiveParametersWithFuel environment remainingFuel;
      fun (scope : PsErasureScope) (cursor : PsExpr) (count : Nat) (index : Nat) (valuesRev : List PsExpr) (parametersRev : List PsVerifiedIrTypeParameter) =>
        match count with
        | Nat.zero => Except.ok (PsPreparedInductiveParameters.mk scope (psListReverse valuesRev) (psListReverse parametersRev))
        | Nat.succ remaining =>
          match
              psWhnf
                environment
                psMetaEmpty
                scope.localContext
                cursor with
          | .forallE name domain body binder =>
              match
                  psErasureClassifyBinder
                    environment
                    scope.localContext
                    domain with
              | .type =>
                  let pushed :=
                    psLocalPushBinding
                      scope.localContext
                      name
                      domain
                      binder;
                  let parameterName := String.Internal.append "T" (psNatToString index);
                  let value := PsExpr.fvar pushed.id;
                  let nextScope : PsErasureScope := {
                    localContext := pushed.context
                    runtimeLocals := scope.runtimeLocals
                    typeLocals :=
                      List.cons (Prod.mk pushed.id parameterName) scope.typeLocals
                    erasedLocals := List.cons pushed.id scope.erasedLocals
                    declarationNames := scope.declarationNames
                    runtimeConstructors := scope.runtimeConstructors
                    runtimeRecursors := scope.runtimeRecursors
                    runtimeStructures := scope.runtimeStructures
                    runtimeStructureConstructors := scope.runtimeStructureConstructors
                    runtimeExpressions := scope.runtimeExpressions
                    currentDefinition := scope.currentDefinition
                  };
                  smaller
                    nextScope
                    (psExprInstantiate1 body value)
                    remaining
                    (Nat.add index 1)
                    (List.cons value valuesRev)
                    (List.cons
                      (PsVerifiedIrTypeParameter.mk parameterName)
                      parametersRev)
              | _ =>
                  Except.error PsErasureError.unsupportedRuntimeTerm
          | _ =>
              Except.error PsErasureError.binderMismatch

def psPrepareInductiveParameters
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (info : PsInductiveInfo) :
    Except PsErasureError PsPreparedInductiveParameters :=
  psPrepareInductiveParametersWithFuel
    environment
    4096
    scope
    info.type
    info.numParams
    0
    []
    []

def psApplyConstructorParameters
    (environment : PsEnvironment) (scope : PsErasureScope) (values : List PsExpr) :
    PsExpr -> Except PsErasureError PsExpr :=
  match values with
  | List.nil => fun (cursor : PsExpr) => Except.ok cursor
  | List.cons value rest =>
    let smaller : PsExpr -> Except PsErasureError PsExpr := psApplyConstructorParameters environment scope rest;
    fun (cursor : PsExpr) =>
      match
          psWhnf
            environment
            psMetaEmpty
            scope.localContext
            cursor with
      | .forallE _ _ body _ =>
          smaller
            (psExprInstantiate1 body value)
      | _ => Except.error PsErasureError.binderMismatch

structure PsPreparedConstructorFields where
  fields : List PsRuntimeConstructorField

def psPrepareConstructorFieldsWithFuel
    (environment : PsEnvironment) (fuel : Nat) :
    PsErasureScope -> PsExpr -> Nat -> Nat -> List PsRuntimeConstructorField -> Except PsErasureError PsPreparedConstructorFields :=
  match fuel with
  | Nat.zero =>
      fun (_scope : PsErasureScope) (_cursor : PsExpr) (_count : Nat) (_index : Nat) (_fields : List PsRuntimeConstructorField) =>
        Except.error PsErasureError.fuelExhausted
  | Nat.succ remainingFuel =>
      let smaller : PsErasureScope -> PsExpr -> Nat -> Nat -> List PsRuntimeConstructorField -> Except PsErasureError PsPreparedConstructorFields :=
        psPrepareConstructorFieldsWithFuel environment remainingFuel;
      fun (scope : PsErasureScope) (cursor : PsExpr) (count : Nat) (index : Nat) (fieldsRev : List PsRuntimeConstructorField) =>
        match count with
        | Nat.zero => Except.ok (PsPreparedConstructorFields.mk (psListReverse fieldsRev))
        | Nat.succ remaining =>
          match
              psWhnf
                environment
                psMetaEmpty
                scope.localContext
                cursor with
          | .forallE name domain body binder =>
              match
                  psErasureClassifyBinder
                    environment
                    scope.localContext
                    domain with
              | .runtime =>
                  match psEraseRuntimeType environment scope domain with
                  | Except.error error => Except.error error
                  | Except.ok fieldType =>
                      let fieldName :=
                        psErasureSafeIdentifier
                          (psNameToString name)
                          (String.Internal.append "field" (psNatToString index));
                      let pushed :=
                        psLocalPushBinding
                          scope.localContext
                          name
                          domain
                          binder;
                      let nextScope : PsErasureScope := {
                        localContext := pushed.context
                        runtimeLocals :=
                          List.cons (Prod.mk pushed.id fieldName) scope.runtimeLocals
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
                      smaller
                        nextScope
                        (psExprInstantiate1
                          body
                          (PsExpr.fvar pushed.id))
                        remaining
                        (Nat.add index 1)
                        (List.cons (PsRuntimeConstructorField.mk index fieldName fieldType false) fieldsRev)
              | _ =>
                  Except.error PsErasureError.unsupportedRuntimeTerm
          | _ =>
              Except.error PsErasureError.binderMismatch

def psPrepareConstructorFields
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (cursor : PsExpr)
    (fieldCount : Nat) :
    Except PsErasureError PsPreparedConstructorFields :=
  psPrepareConstructorFieldsWithFuel
    environment
    4096
    scope
    cursor
    fieldCount
    0
    []

def psFindConstructorDeclaration (declarations : List PsDeclaration) : PsName -> Option PsConstructorInfo :=
  match declarations with
  | List.nil => fun (_target : PsName) => Option.none
  | List.cons declaration rest =>
      let smaller : PsName -> Option PsConstructorInfo := psFindConstructorDeclaration rest;
      fun (target : PsName) =>
        match declaration with
        | PsDeclaration.constructorDecl info =>
            if psNameEq info.name target then Option.some info else smaller target
        | _ => smaller target


def psFindRecursorDeclaration (declarations : List PsDeclaration) : PsName -> Option PsRecursorInfo :=
  match declarations with
  | List.nil => fun (_target : PsName) => Option.none
  | List.cons declaration rest =>
      let smaller : PsName -> Option PsRecursorInfo := psFindRecursorDeclaration rest;
      fun (target : PsName) =>
        match declaration with
        | PsDeclaration.recursorDecl info =>
            if psNameEq info.name target then Option.some info else smaller target
        | _ => smaller target


def psPrepareRuntimeConstructors
    (environment : PsEnvironment) (declarations : List PsDeclaration)
    (parameterScope : PsErasureScope) (parameterValues : List PsExpr)
    (inductiveName : String) (names : List PsName) :
    List PsRuntimeConstructorInfo -> Except PsErasureError (List PsRuntimeConstructorInfo) :=
  match names with
  | List.nil => fun (constructorsRev : List PsRuntimeConstructorInfo) => Except.ok (psListReverse constructorsRev)
  | List.cons coreName rest =>
    let smaller : List PsRuntimeConstructorInfo -> Except PsErasureError (List PsRuntimeConstructorInfo) :=
      psPrepareRuntimeConstructors environment declarations parameterScope parameterValues inductiveName rest;
    fun (constructorsRev : List PsRuntimeConstructorInfo) =>
      match psFindConstructorDeclaration declarations coreName with
      | Option.none => Except.error (PsErasureError.unknownConstant coreName)
      | Option.some ctorInfo =>
          match
              psApplyConstructorParameters
                environment
                parameterScope
                parameterValues
                ctorInfo.type with
          | Except.error error => Except.error error
          | Except.ok fieldCursor =>
              match
                  psPrepareConstructorFields
                    environment
                    parameterScope
                    fieldCursor
                    ctorInfo.numFields with
              | Except.error error => Except.error error
              | Except.ok preparedFields =>
                  let adjustField :=
                    fun (field : PsRuntimeConstructorField) =>
                      PsRuntimeConstructorField.mk
                        (Nat.add ctorInfo.numParams field.sourceIndex)
                        field.name field.type
                        (psErasureNatInList ctorInfo.recursiveFields field.sourceIndex);
                  let fields := psListMap adjustField preparedFields.fields;
                  let runtimeInfo : PsRuntimeConstructorInfo := {
                    inductiveName := inductiveName
                    name :=
                      psErasureSafeIdentifier
                        (psNameLastComponent coreName)
                        "constructor"
                    coreName := coreName
                    numParams := ctorInfo.numParams
                    fields := fields
                  };
                  smaller
                    (List.cons runtimeInfo constructorsRev)

structure PsPreparedInductiveResult where
  scope : PsErasureScope
  ir : PsVerifiedIrInductive

def psErasureAppendConstructorEntries (entries : List (PsName × PsRuntimeConstructorInfo))
    (tail : PsErasureNameIndex PsRuntimeConstructorInfo) : PsErasureNameIndex PsRuntimeConstructorInfo :=
  psErasureIndexPrepend PsRuntimeConstructorInfo entries tail

def psPrepareRuntimeInductive
    (environment : PsEnvironment)
    (declarations : List PsDeclaration)
    (scope : PsErasureScope)
    (info : PsInductiveInfo) :
    Except PsErasureError PsPreparedInductiveResult :=
  if psErasureNatNotEqual info.numIndices 0 then
    Except.error PsErasureError.unsupportedRuntimeTerm
  else
    let outputName : String :=
      match psErasureLookupName scope.declarationNames info.name with
      | Option.some known => known
      | Option.none =>
          psErasureSafeIdentifier
            (psNameToString info.name)
            "Inductive";
    match
        psPrepareInductiveParameters
          environment
          scope
          info with
    | Except.error error => Except.error error
    | Except.ok parameters =>
        match
            psPrepareRuntimeConstructors
              environment
              declarations
              parameters.scope
              parameters.values
              outputName
              info.constructors
              [] with
        | Except.error error => Except.error error
        | Except.ok constructors =>
            let recursorName :=
              psNameAppendStr info.name "rec";
            match psFindRecursorDeclaration declarations recursorName with
            | Option.none =>
                Except.error
                  (PsErasureError.unknownConstant recursorName)
            | Option.some recInfo =>
                if
                    if psErasureNatNotEqual recInfo.numParams info.numParams then true
                    else if psErasureNatNotEqual recInfo.numIndices 0 then true
                    else if psErasureNatNotEqual recInfo.numMotives 1 then true
                    else psErasureNatNotEqual recInfo.numMinors (psListLength constructors) then
                  Except.error PsErasureError.unsupportedRuntimeTerm
                else
                  let runtimeInfo : PsRuntimeInductiveInfo := {
                    name := outputName
                    coreName := info.name
                    recursorName := recursorName
                    numParams := info.numParams
                    typeParameters := parameters.typeParameters
                    constructors := constructors
                  };
                  let makeEntry :=
                    fun (ctorInfo : PsRuntimeConstructorInfo) => Prod.mk ctorInfo.coreName ctorInfo;
                  let constructorEntries := psListMap makeEntry constructors;
                  let nextScope : PsErasureScope := {
                    localContext := scope.localContext
                    runtimeLocals := scope.runtimeLocals
                    typeLocals := scope.typeLocals
                    erasedLocals := scope.erasedLocals
                    declarationNames := scope.declarationNames
                    runtimeConstructors :=
                      psErasureAppendConstructorEntries constructorEntries scope.runtimeConstructors
                    runtimeRecursors :=
                      psErasureIndexInsert PsRuntimeInductiveInfo scope.runtimeRecursors recursorName runtimeInfo
                    runtimeStructures := scope.runtimeStructures
                    runtimeStructureConstructors :=
                      scope.runtimeStructureConstructors
                    runtimeExpressions := []
                    currentDefinition := Option.none
                  };
                  let makeField :=
                    fun (field : PsRuntimeConstructorField) =>
                      PsVerifiedIrConstructorField.mk field.name field.type;
                  let makeConstructor :=
                    fun (ctorInfo : PsRuntimeConstructorInfo) =>
                      PsVerifiedIrConstructor.mk ctorInfo.name (psListMap makeField ctorInfo.fields);
                  let irConstructors := psListMap makeConstructor constructors;
                  Except.ok {
                    scope := nextScope
                    ir := {
                      name := outputName
                      typeParameters := parameters.typeParameters
                      constructors := irConstructors
                    }
                  }

structure PsPreparedInductivesResult where
  scope : PsErasureScope
  ir : List PsVerifiedIrInductive

def psPrepareRuntimeInductives
    (environment : PsEnvironment) (declarations : List PsDeclaration) (inputs : List PsDeclaration) :
    PsErasureScope -> List PsVerifiedIrInductive -> Except PsErasureError PsPreparedInductivesResult :=
  match inputs with
  | List.nil =>
      fun (scope : PsErasureScope) (irRev : List PsVerifiedIrInductive) =>
        Except.ok (PsPreparedInductivesResult.mk scope (psListReverse irRev))
  | List.cons declaration rest =>
    let smaller : PsErasureScope -> List PsVerifiedIrInductive -> Except PsErasureError PsPreparedInductivesResult :=
      psPrepareRuntimeInductives environment declarations rest;
    fun (scope : PsErasureScope) (irRev : List PsVerifiedIrInductive) =>
      match declaration with
      | .inductiveDecl info =>
          if info.isStructure then
            smaller
              scope
              irRev
          else
            match
                psPrepareRuntimeInductive
                  environment
                  declarations
                  scope
                  info with
            | Except.error error => Except.error error
            | Except.ok prepared =>
                smaller
                  prepared.scope
                  (List.cons prepared.ir irRev)
      | _ =>
          smaller
            scope
            irRev
