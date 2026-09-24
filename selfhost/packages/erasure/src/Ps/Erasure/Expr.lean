import Ps.Erasure.Basic

structure PsErasureAppliedArguments where
  typeArgumentsRev : List PsVerifiedIrType
  runtimeArgumentsRev : List PsVerifiedIrExpr
  remainingType : PsExpr

def psEraseApplicationArguments
    (erase :
      PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (environment : PsEnvironment)
    (scope : PsErasureScope) :
    PsExpr ->
    List PsExpr ->
    PsErasureAppliedArguments ->
    Except PsErasureError PsErasureAppliedArguments
  | functionType, [], state =>
      Except.ok {
        typeArgumentsRev := state.typeArgumentsRev
        runtimeArgumentsRev := state.runtimeArgumentsRev
        remainingType := functionType
      }
  | functionType, argument :: rest, state =>
      match
          psWhnf
            environment
            psMetaEmpty
            scope.localContext
            functionType with
      | .forallE _ domain body _ =>
          match
              psErasureClassifyBinder
                environment
                scope.localContext
                domain with
          | .type =>
              match psEraseRuntimeType environment scope argument with
              | Except.error error => Except.error error
              | Except.ok erasedType =>
                  psEraseApplicationArguments
                    erase
                    environment
                    scope
                    (psExprInstantiate1 body argument)
                    rest
                    {
                      typeArgumentsRev :=
                        erasedType :: state.typeArgumentsRev
                      runtimeArgumentsRev :=
                        state.runtimeArgumentsRev
                      remainingType := state.remainingType
                    }
          | .proof =>
              psEraseApplicationArguments
                erase
                environment
                scope
                (psExprInstantiate1 body argument)
                rest
                state
          | .runtime =>
              match erase argument with
              | Except.error error => Except.error error
              | Except.ok erasedArgument =>
                  psEraseApplicationArguments
                    erase
                    environment
                    scope
                    (psExprInstantiate1 body argument)
                    rest
                    {
                      typeArgumentsRev :=
                        state.typeArgumentsRev
                      runtimeArgumentsRev :=
                        erasedArgument :: state.runtimeArgumentsRev
                      remainingType := state.remainingType
                    }
      | _ => Except.error PsErasureError.unsupportedApplication

def psEraseFinishApplicationWithFuel
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (fn : PsVerifiedIrExpr)
    (typeArguments : List PsVerifiedIrType) :
    Nat ->
    PsExpr ->
    List PsVerifiedIrParameter ->
    List PsVerifiedIrExpr ->
    Except PsErasureError PsVerifiedIrExpr
  | 0, _, _, _ =>
      Except.error PsErasureError.fuelExhausted
  | fuel + 1, functionType, parametersRev, runtimeArguments =>
      match
          psWhnf
            environment
            psMetaEmpty
            scope.localContext
            functionType with
      | .forallE name domain body binder =>
          match
              psErasureClassifyBinder
                environment
                scope.localContext
                domain with
          | .type =>
              Except.error PsErasureError.unsupportedApplication
          | .proof =>
              let pushed :=
                psLocalPushBinding
                  scope.localContext
                  name
                  domain
                  binder
              let nextScope : PsErasureScope := {
                localContext := pushed.context
                runtimeLocals := scope.runtimeLocals
                typeLocals := scope.typeLocals
                erasedLocals := pushed.id :: scope.erasedLocals
                declarationNames := scope.declarationNames
                runtimeConstructors := scope.runtimeConstructors
                runtimeRecursors := scope.runtimeRecursors
                runtimeStructures := scope.runtimeStructures
                runtimeStructureConstructors :=
                  scope.runtimeStructureConstructors
                runtimeExpressions := scope.runtimeExpressions
                currentDefinition := scope.currentDefinition
              }
              psEraseFinishApplicationWithFuel
                environment
                nextScope
                fn
                typeArguments
                fuel
                (psExprInstantiate1
                  body
                  (PsExpr.fvar pushed.id))
                parametersRev
                runtimeArguments
          | .runtime =>
              match psEraseRuntimeType environment scope domain with
              | Except.error error => Except.error error
              | Except.ok parameterType =>
                  let pushed :=
                    psLocalPushBinding
                      scope.localContext
                      name
                      domain
                      binder
                  let parameterName :=
                    psErasureSafeIdentifier
                      (psNameToString name ++ "$" ++ toString pushed.id)
                      ("arg$" ++ toString pushed.id)
                  let nextScope : PsErasureScope := {
                    localContext := pushed.context
                    runtimeLocals :=
                      (pushed.id, parameterName) :: scope.runtimeLocals
                    typeLocals := scope.typeLocals
                    erasedLocals := scope.erasedLocals
                    declarationNames := scope.declarationNames
                    runtimeConstructors := scope.runtimeConstructors
                    runtimeRecursors := scope.runtimeRecursors
                    runtimeStructures := scope.runtimeStructures
                    runtimeStructureConstructors :=
                      scope.runtimeStructureConstructors
                    runtimeExpressions := scope.runtimeExpressions
                    currentDefinition := scope.currentDefinition
                  }
                  psEraseFinishApplicationWithFuel
                    environment
                    nextScope
                    fn
                    typeArguments
                    fuel
                    (psExprInstantiate1
                      body
                      (PsExpr.fvar pushed.id))
                    ({
                      name := parameterName
                      type := parameterType
                    } :: parametersRev)
                    (runtimeArguments ++
                      [PsVerifiedIrExpr.var parameterName])
      | _ =>
          let body :=
            if runtimeArguments.isEmpty then
              fn
            else
              PsVerifiedIrExpr.call
                fn
                typeArguments
                runtimeArguments
          match parametersRev.reverse with
          | [] => Except.ok body
          | parameters =>
              Except.ok
                (PsVerifiedIrExpr.lambda parameters body)

def psEraseFinishApplication
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (fn : PsVerifiedIrExpr)
    (typeArguments : List PsVerifiedIrType)
    (runtimeArguments : List PsVerifiedIrExpr)
    (remainingType : PsExpr) :
    Except PsErasureError PsVerifiedIrExpr :=
  psEraseFinishApplicationWithFuel
    environment
    scope
    fn
    typeArguments
    4096
    remainingType
    []
    runtimeArguments

def psEraseMappedIntrinsic
    (erase :
      PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (operation : PsVerifiedIrIntrinsic)
    (arguments : List PsExpr) :
    Except PsErasureError PsVerifiedIrExpr :=
  match arguments.mapM erase with
  | Except.error error => Except.error error
  | Except.ok erased =>
      Except.ok
        (PsVerifiedIrExpr.intrinsic operation erased)

def psEraseSelectedArguments
    (erase :
      PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (arguments : List PsExpr) :
    List Nat -> Except PsErasureError (List PsVerifiedIrExpr)
  | [] => Except.ok []
  | index :: rest =>
      match arguments[index]? with
      | none => Except.error PsErasureError.unsupportedApplication
      | some argument =>
          match erase argument with
          | Except.error error => Except.error error
          | Except.ok erased =>
              match psEraseSelectedArguments erase arguments rest with
              | Except.error error => Except.error error
              | Except.ok erasedRest =>
                  Except.ok (erased :: erasedRest)

def psErasePrimitiveApplication
    (erase :
      PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (view : PsErasureAppView) :
    Except PsErasureError (Option PsVerifiedIrExpr) :=
  match view.head with
  | .constE name _ =>
      let text := psNameToString name
      let binary :=
        fun operation =>
          if view.args.length == 2 then
            match
                psEraseMappedIntrinsic
                  erase
                  operation
                  view.args with
            | Except.error error => Except.error error
            | Except.ok result => Except.ok (some result)
          else
            Except.error PsErasureError.unsupportedApplication
      if text == "Int.ofNat" then
        if view.args.length == 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.intOfNat
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if text == "Int.negSucc" then
        if view.args.length == 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.intNegSucc
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if text == "Int.neg" then
        if view.args.length == 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.intNeg
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if text == "Int.add" then
        binary PsVerifiedIrIntrinsic.intAdd
      else if text == "Int.sub" then
        binary PsVerifiedIrIntrinsic.intSub
      else if text == "Int.mul" then
        binary PsVerifiedIrIntrinsic.intMul
      else if text == "Nat.add" then
        binary PsVerifiedIrIntrinsic.natAdd
      else if text == "Nat.sub" then
        binary PsVerifiedIrIntrinsic.natSub
      else if text == "Nat.mul" then
        binary PsVerifiedIrIntrinsic.natMul
      else if text == "Nat.div" then
        binary PsVerifiedIrIntrinsic.natDiv
      else if text == "Nat.mod" then
        binary PsVerifiedIrIntrinsic.natMod
      else if text == "Nat.beq" then
        binary PsVerifiedIrIntrinsic.natEq
      else if text == "Bool.and" then
        binary PsVerifiedIrIntrinsic.boolAnd
      else if text == "Bool.or" then
        binary PsVerifiedIrIntrinsic.boolOr
      else if text == "Bool.not" then
        if view.args.length == 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.boolNot
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if text == "Char.ofNat" then
        if view.args.length == 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.charOfNat
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if text == "Char.toNat" then
        if view.args.length == 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.charToNat
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if text == "String.push" then
        binary PsVerifiedIrIntrinsic.stringPush
      else if text == "String.singleton" then
        if view.args.length == 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.stringSingleton
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if text == "String.Internal.length" then
        if view.args.length == 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.stringLength
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if text == "String.Internal.append" then
        binary PsVerifiedIrIntrinsic.stringAppend
      else if text == "String.utf8ByteSize" then
        if view.args.length == 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.stringUtf8ByteSize
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if text == "String.Internal.next" then
        binary PsVerifiedIrIntrinsic.stringNext
      else if text == "String.Internal.get" then
        binary PsVerifiedIrIntrinsic.stringGet
      else if text == "String.Internal.atEnd" then
        binary PsVerifiedIrIntrinsic.stringAtEnd
      else if text == "String.Internal.extract" then
        if view.args.length == 3 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.stringExtract
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if text == "Array.emptyWithCapacity" && view.args.length == 2 then
        match psEraseSelectedArguments erase view.args [1] with
        | Except.error error => Except.error error
        | Except.ok args =>
            Except.ok
              (some
                (PsVerifiedIrExpr.intrinsic
                  PsVerifiedIrIntrinsic.arrayEmptyWithCapacity
                  args))
      else if text == "Array.size" && view.args.length == 2 then
        match psEraseSelectedArguments erase view.args [1] with
        | Except.error error => Except.error error
        | Except.ok args =>
            Except.ok
              (some
                (PsVerifiedIrExpr.intrinsic
                  PsVerifiedIrIntrinsic.arraySize
                  args))
      else if text == "Array.push" && view.args.length == 3 then
        match psEraseSelectedArguments erase view.args [1, 2] with
        | Except.error error => Except.error error
        | Except.ok args =>
            Except.ok
              (some
                (PsVerifiedIrExpr.intrinsic
                  PsVerifiedIrIntrinsic.arrayPush
                  args))
      else if text == "Array.getInternal" && view.args.length == 4 then
        match psEraseSelectedArguments erase view.args [1, 2] with
        | Except.error error => Except.error error
        | Except.ok args =>
            Except.ok
              (some
                (PsVerifiedIrExpr.intrinsic
                  PsVerifiedIrIntrinsic.arrayGet
                  args))
      else if text == "Array.getD" && view.args.length == 4 then
        match psEraseSelectedArguments erase view.args [1, 2, 3] with
        | Except.error error => Except.error error
        | Except.ok args =>
            Except.ok
              (some
                (PsVerifiedIrExpr.intrinsic
                  PsVerifiedIrIntrinsic.arrayGetD
                  args))
      else if text == "Array.set" && view.args.length == 5 then
        match psEraseSelectedArguments erase view.args [1, 2, 3] with
        | Except.error error => Except.error error
        | Except.ok args =>
            Except.ok
              (some
                (PsVerifiedIrExpr.intrinsic
                  PsVerifiedIrIntrinsic.arraySet
                  args))
      else if text == "Array.setIfInBounds" && view.args.length == 4 then
        match psEraseSelectedArguments erase view.args [1, 2, 3] with
        | Except.error error => Except.error error
        | Except.ok args =>
            Except.ok
              (some
                (PsVerifiedIrExpr.intrinsic
                  PsVerifiedIrIntrinsic.arraySetIfInBounds
                  args))
      else if text == "Array.map" && view.args.length == 4 then
        match psEraseSelectedArguments erase view.args [2, 3] with
        | Except.error error => Except.error error
        | Except.ok args =>
            Except.ok
              (some
                (PsVerifiedIrExpr.intrinsic
                  PsVerifiedIrIntrinsic.arrayMap
                  args))
      else if text == "Array.foldl" && view.args.length == 7 then
        match psEraseSelectedArguments erase view.args [2, 3, 4, 5, 6] with
        | Except.error error => Except.error error
        | Except.ok args =>
            Except.ok
              (some
                (PsVerifiedIrExpr.intrinsic
                  PsVerifiedIrIntrinsic.arrayFoldl
                  args))
      else
        Except.ok none
  | _ => Except.ok none

def psEraseCondition
    (erase :
      PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (proposition : PsExpr) :
    Except PsErasureError PsVerifiedIrExpr :=
  let view := psErasureAppView proposition
  match view.head, view.args with
  | .constE name _, [type, left, right] =>
      if psNameEq name psEqName then
        match type with
        | .constE typeName _ =>
            if psNameEq typeName psBoolName then
              match right with
              | .constE trueName _ =>
                  if psNameEq trueName psBoolTrueName then
                    erase left
                  else
                    Except.error PsErasureError.unsupportedApplication
              | _ =>
                  Except.error PsErasureError.unsupportedApplication
            else if psNameEq typeName psStringName then
              match erase left with
              | Except.error error => Except.error error
              | Except.ok erasedLeft =>
                  match erase right with
                  | Except.error error => Except.error error
                  | Except.ok erasedRight =>
                      Except.ok
                        (PsVerifiedIrExpr.intrinsic
                          PsVerifiedIrIntrinsic.stringEq
                          [erasedLeft, erasedRight])
            else
              Except.error PsErasureError.unsupportedApplication
        | _ => Except.error PsErasureError.unsupportedApplication
      else
        Except.error PsErasureError.unsupportedApplication
  | _, _ => Except.error PsErasureError.unsupportedApplication

def psEraseIteApplication
    (erase :
      PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (view : PsErasureAppView) :
    Except PsErasureError (Option PsVerifiedIrExpr) :=
  match view.head with
  | .constE name _ =>
      if psNameEq name psIteName && view.args.length == 5 then
        match view.args[1]?, view.args[3]?, view.args[4]? with
        | some proposition, some thenBranch, some elseBranch =>
            match psEraseCondition erase proposition with
            | Except.error error => Except.error error
            | Except.ok condition =>
                match erase thenBranch with
                | Except.error error => Except.error error
                | Except.ok erasedThen =>
                    match erase elseBranch with
                    | Except.error error => Except.error error
                    | Except.ok erasedElse =>
                        Except.ok
                          (some
                            (PsVerifiedIrExpr.ifE
                              condition
                              erasedThen
                              erasedElse))
        | _, _, _ =>
            Except.error PsErasureError.unsupportedApplication
      else
        Except.ok none
  | _ => Except.ok none

def psErasureLookupTypeSubstitution :
    List (String × PsVerifiedIrType) ->
    String ->
    Option PsVerifiedIrType
  | [], _ => none
  | entry :: rest, name =>
      if entry.1 == name then some entry.2
      else psErasureLookupTypeSubstitution rest name

def psSubstituteVerifiedTypeWithFuel
    (substitutions : List (String × PsVerifiedIrType)) :
    Nat -> PsVerifiedIrType -> PsVerifiedIrType
  | 0, type => type
  | fuel + 1, type =>
      match type with
      | .typeParameter name =>
          match
              psErasureLookupTypeSubstitution
                substitutions
                name with
          | some replacement => replacement
          | none => type
      | .function parameters result =>
          PsVerifiedIrType.function
            (parameters.map
              (psSubstituteVerifiedTypeWithFuel
                substitutions
                fuel))
            (psSubstituteVerifiedTypeWithFuel
              substitutions
              fuel
              result)
      | .named name arguments =>
          PsVerifiedIrType.named
            name
            (arguments.map
              (psSubstituteVerifiedTypeWithFuel
                substitutions
                fuel))
      | _ => type

def psSubstituteVerifiedType
    (substitutions : List (String × PsVerifiedIrType))
    (type : PsVerifiedIrType) : PsVerifiedIrType :=
  psSubstituteVerifiedTypeWithFuel substitutions 4096 type

def psEraseRuntimeStructureFields
    (erase :
      PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (arguments : List PsExpr) :
    List PsRuntimeStructureField ->
    List (String × PsVerifiedIrExpr) ->
    Except PsErasureError (List (String × PsVerifiedIrExpr))
  | [], fieldsRev => Except.ok fieldsRev.reverse
  | field :: rest, fieldsRev =>
      match arguments[field.sourceIndex]? with
      | none => Except.error PsErasureError.unsupportedApplication
      | some argument =>
          match erase argument with
          | Except.error error => Except.error error
          | Except.ok value =>
              psEraseRuntimeStructureFields
                erase
                arguments
                rest
                ((field.name, value) :: fieldsRev)

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
      | none => Except.ok none
      | some structureInfo =>
          let expectedArity :=
            structureInfo.numParams + structureInfo.fields.length
          if view.args.length != expectedArity then
            Except.error PsErasureError.unsupportedApplication
          else
            match
                (view.args.take structureInfo.numParams).mapM
                  (psEraseRuntimeType environment scope) with
            | Except.error error => Except.error error
            | Except.ok typeArguments =>
                if typeArguments.length != structureInfo.typeParameters.length then
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
                        (some
                          (PsVerifiedIrExpr.record
                            structureInfo.name
                            fields))
  | _ => Except.ok none

def psEraseRuntimeConstructorFields
    (erase :
      PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (arguments : List PsExpr) :
    List PsRuntimeConstructorField ->
    List (String × PsVerifiedIrExpr) ->
    Except PsErasureError (List (String × PsVerifiedIrExpr))
  | [], fieldsRev => Except.ok fieldsRev.reverse
  | field :: rest, fieldsRev =>
      match arguments[field.sourceIndex]? with
      | none => Except.error PsErasureError.unsupportedApplication
      | some argument =>
          match erase argument with
          | Except.error error => Except.error error
          | Except.ok value =>
              psEraseRuntimeConstructorFields
                erase
                arguments
                rest
                ((field.name, value) :: fieldsRev)

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
      | none => Except.ok none
      | some ctorInfo =>
          let expectedArity :=
            ctorInfo.numParams + ctorInfo.fields.length
          if view.args.length != expectedArity then
            Except.error PsErasureError.unsupportedApplication
          else
            match
                (view.args.take ctorInfo.numParams).mapM
                  (psEraseRuntimeType environment scope) with
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
                      (some
                        (PsVerifiedIrExpr.constructor
                          ctorInfo.inductiveName
                          ctorInfo.name
                          typeArguments
                          fields))
  | _ => Except.ok none

structure PsErasedMatchMinor where
  constructorName : String
  bindings : List PsVerifiedIrMatchBinding
  body : PsVerifiedIrExpr

structure PsOpenMatchMinor where
  scope : PsErasureScope
  cursor : PsExpr
  bindingsRev : List PsVerifiedIrMatchBinding

def psOpenMatchMinorFields
    (environment : PsEnvironment)
    (substitutions : List (String × PsVerifiedIrType)) :
    List PsRuntimeConstructorField ->
    PsOpenMatchMinor ->
    Except PsErasureError PsOpenMatchMinor
  | [], state => Except.ok state
  | field :: rest, state =>
      match state.cursor with
      | .lam name domain body binder =>
          match
              psErasureClassifyBinder
                environment
                state.scope.localContext
                domain with
          | .runtime =>
              let bindingName :=
                psErasureSafeIdentifier
                  (psNameToString name)
                  field.name
              let pushed :=
                psLocalPushBinding
                  state.scope.localContext
                  name
                  domain
                  binder
              let nextScope : PsErasureScope := {
                localContext := pushed.context
                runtimeLocals :=
                  (pushed.id, bindingName) ::
                    state.scope.runtimeLocals
                typeLocals := state.scope.typeLocals
                erasedLocals := state.scope.erasedLocals
                declarationNames := state.scope.declarationNames
                runtimeConstructors :=
                  state.scope.runtimeConstructors
                runtimeRecursors := state.scope.runtimeRecursors
                runtimeStructures := state.scope.runtimeStructures
                runtimeStructureConstructors := state.scope.runtimeStructureConstructors
                runtimeExpressions := state.scope.runtimeExpressions
                currentDefinition := state.scope.currentDefinition
              }
              psOpenMatchMinorFields
                environment
                substitutions
                rest
                {
                  scope := nextScope
                  cursor :=
                    psExprInstantiate1
                      body
                      (PsExpr.fvar pushed.id)
                  bindingsRev := {
                    field := field.name
                    name := bindingName
                    type :=
                      psSubstituteVerifiedType
                        substitutions
                        field.type
                  } :: state.bindingsRev
                }
          | _ =>
              Except.error PsErasureError.unsupportedRuntimeTerm
      | _ => Except.error PsErasureError.binderMismatch

def psErasureFindStringIndex
    (target : String) :
    List String -> Nat -> Option Nat
  | [], _ => none
  | value :: rest, index =>
      if value == target then
        some index
      else
        psErasureFindStringIndex target rest (index + 1)

def psErasureRecursiveCallArguments :
    List String -> Nat -> String -> List PsVerifiedIrExpr
  | [], _, _ => []
  | _ :: rest, 0, recursiveName =>
      PsVerifiedIrExpr.var recursiveName ::
        rest.map (fun name => PsVerifiedIrExpr.var name)
  | name :: rest, index + 1, recursiveName =>
      PsVerifiedIrExpr.var name ::
        psErasureRecursiveCallArguments
          rest
          index
          recursiveName

structure PsOpenMatchHypotheses where
  scope : PsErasureScope
  cursor : PsExpr

def psOpenMatchMinorHypotheses
    (recursiveParameterIndex : Option Nat)
    (bindings : List PsVerifiedIrMatchBinding) :
    List PsRuntimeConstructorField ->
    PsOpenMatchHypotheses ->
    Except PsErasureError PsOpenMatchHypotheses
  | [], state => Except.ok state
  | field :: rest, state =>
      if !field.recursive then
        psOpenMatchMinorHypotheses
          recursiveParameterIndex
          bindings
          rest
          state
      else
        match state.cursor with
        | .lam name domain body binder =>
            match bindings.find? (fun binding => binding.field == field.name) with
            | none => Except.error PsErasureError.binderMismatch
            | some binding =>
                let pushed :=
                  psLocalPushBinding
                    state.scope.localContext
                    name
                    domain
                    binder
                let baseScope : PsErasureScope := {
                  localContext := pushed.context
                  runtimeLocals := state.scope.runtimeLocals
                  typeLocals := state.scope.typeLocals
                  erasedLocals := pushed.id :: state.scope.erasedLocals
                  declarationNames := state.scope.declarationNames
                  runtimeConstructors := state.scope.runtimeConstructors
                  runtimeRecursors := state.scope.runtimeRecursors
                  runtimeStructures := state.scope.runtimeStructures
                  runtimeStructureConstructors :=
                    state.scope.runtimeStructureConstructors
                  runtimeExpressions := state.scope.runtimeExpressions
                  currentDefinition := state.scope.currentDefinition
                }
                let nextScope :=
                  match
                      state.scope.currentDefinition,
                      recursiveParameterIndex with
                  | some current, some parameterIndex =>
                      {
                        baseScope with
                        runtimeExpressions :=
                          (pushed.id,
                            PsVerifiedIrExpr.call
                              (PsVerifiedIrExpr.var current.name)
                              []
                              (psErasureRecursiveCallArguments
                                current.runtimeParameters
                                parameterIndex
                                binding.name)) ::
                            baseScope.runtimeExpressions
                      }
                  | _, _ => baseScope
                psOpenMatchMinorHypotheses
                  recursiveParameterIndex
                  bindings
                  rest
                  {
                    scope := nextScope
                    cursor :=
                      psExprInstantiate1
                        body
                        (PsExpr.fvar pushed.id)
                  }
        | _ => Except.error PsErasureError.binderMismatch

def psEraseMatchMinor
    (environment : PsEnvironment)
    (eraseAt :
      PsErasureScope ->
      PsExpr ->
      Except PsErasureError PsVerifiedIrExpr)
    (scope : PsErasureScope)
    (substitutions : List (String × PsVerifiedIrType))
    (recursiveParameterIndex : Option Nat)
    (ctorInfo : PsRuntimeConstructorInfo)
    (minor : PsExpr) :
    Except PsErasureError PsErasedMatchMinor :=
  match
      psOpenMatchMinorFields
        environment
        substitutions
        ctorInfo.fields
        {
          scope := scope
          cursor := minor
          bindingsRev := []
        } with
  | Except.error error => Except.error error
  | Except.ok opened =>
      let bindings := opened.bindingsRev.reverse
      match
          psOpenMatchMinorHypotheses
            recursiveParameterIndex
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

def psEraseMatchAlternatives
    (environment : PsEnvironment)
    (eraseAt :
      PsErasureScope ->
      PsExpr ->
      Except PsErasureError PsVerifiedIrExpr)
    (scope : PsErasureScope)
    (substitutions : List (String × PsVerifiedIrType))
    (recursiveParameterIndex : Option Nat)
    (arguments : List PsExpr)
    (minorStart : Nat) :
    Nat ->
    List PsRuntimeConstructorInfo ->
    List
      (String ×
        List PsVerifiedIrMatchBinding ×
        PsVerifiedIrExpr) ->
    Except PsErasureError
      (List
        (String ×
          List PsVerifiedIrMatchBinding ×
          PsVerifiedIrExpr))
  | _, [], alternativesRev =>
      Except.ok alternativesRev.reverse
  | index, ctorInfo :: rest, alternativesRev =>
      match arguments[minorStart + index]? with
      | none => Except.error PsErasureError.unsupportedApplication
      | some minor =>
          match
              psEraseMatchMinor
                environment
                eraseAt
                scope
                substitutions
                recursiveParameterIndex
                ctorInfo
                minor with
          | Except.error error => Except.error error
          | Except.ok alternative =>
              psEraseMatchAlternatives
                environment
                eraseAt
                scope
                substitutions
                recursiveParameterIndex
                arguments
                minorStart
                (index + 1)
                rest
                ((alternative.constructorName,
                  alternative.bindings,
                  alternative.body) :: alternativesRev)

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
      | none => Except.ok none
      | some inductiveInfo =>
          let expectedArity :=
            inductiveInfo.numParams +
              1 +
              inductiveInfo.constructors.length +
              1
          if view.args.length != expectedArity then
            Except.error PsErasureError.unsupportedApplication
          else
            match
                (view.args.take inductiveInfo.numParams).mapM
                  (psEraseRuntimeType environment scope) with
            | Except.error error => Except.error error
            | Except.ok typeArguments =>
                if
                    typeArguments.length !=
                      inductiveInfo.typeParameters.length then
                  Except.error PsErasureError.unsupportedApplication
                else
                  let substitutions :=
                    inductiveInfo.typeParameters.zip typeArguments
                      |>.map
                        (fun entry =>
                          (entry.1.name, entry.2))
                  let minorStart := inductiveInfo.numParams + 1
                  let majorIndex := expectedArity - 1
                  match view.args[majorIndex]? with
                  | none =>
                      Except.error PsErasureError.unsupportedApplication
                  | some major =>
                      match eraseAt scope major with
                      | Except.error error => Except.error error
                      | Except.ok scrutinee =>
                          let recursiveParameterIndex :=
                            match
                                scope.currentDefinition,
                                scrutinee with
                            | some current, PsVerifiedIrExpr.var name =>
                                psErasureFindStringIndex
                                  name
                                  current.runtimeParameters
                                  0
                            | _, _ => none
                          match
                              psEraseMatchAlternatives
                                environment
                                eraseAt
                                scope
                                substitutions
                                recursiveParameterIndex
                                view.args
                                minorStart
                                0
                                inductiveInfo.constructors
                                [] with
                          | Except.error error => Except.error error
                          | Except.ok alternatives =>
                              Except.ok
                                (some
                                  (PsVerifiedIrExpr.matchE
                                    inductiveInfo.name
                                    scrutinee
                                    alternatives))
  | _ => Except.ok none

def psEraseRuntimeExprWithFuel
    (environment : PsEnvironment)
    (scope : PsErasureScope) :
    Nat -> PsExpr -> Except PsErasureError PsVerifiedIrExpr
  | 0, _ => Except.error PsErasureError.fuelExhausted
  | fuel + 1, expr =>
      match expr with
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
          | some runtimeExpr => Except.ok runtimeExpr
          | none =>
              match psErasureLookupNat scope.runtimeLocals id with
              | some name => Except.ok (PsVerifiedIrExpr.var name)
              | none =>
                  if
                      psErasureNatInList scope.erasedLocals id
                        || match psErasureLookupNat scope.typeLocals id with
                           | some _ => true
                           | none => false then
                    Except.error (PsErasureError.erasedLocalUsed id)
                  else
                    Except.error (PsErasureError.unknownLocal id)
      | .constE name _ =>
          match
              psErasureLookupConstructor
                scope.runtimeConstructors
                name with
          | some ctorInfo =>
              if
                  ctorInfo.numParams == 0
                    && ctorInfo.fields.isEmpty then
                Except.ok
                  (PsVerifiedIrExpr.constructor
                    ctorInfo.inductiveName
                    ctorInfo.name
                    []
                    [])
              else
                Except.error PsErasureError.unsupportedApplication
          | none =>
              match psErasureLookupName scope.declarationNames name with
              | some known => Except.ok (PsVerifiedIrExpr.var known)
              | none =>
                  if psNameEq name psBoolTrueName then
                    Except.ok
                      (PsVerifiedIrExpr.literal
                        (PsVerifiedIrLiteral.bool true))
                  else if psNameEq name psBoolFalseName then
                    Except.ok
                      (PsVerifiedIrExpr.literal
                        (PsVerifiedIrLiteral.bool false))
                  else if psNameEq name psUnitUnitName then
                    Except.ok
                      (PsVerifiedIrExpr.literal
                        PsVerifiedIrLiteral.unit)
                  else
                    Except.error (PsErasureError.unknownConstant name)
      | .app _ _ =>
          let view := psErasureAppView expr
          let erase :=
            psEraseRuntimeExprWithFuel
              environment
              scope
              fuel
          let eraseAt :=
            fun nextScope value =>
              psEraseRuntimeExprWithFuel
                environment
                nextScope
                fuel
                value
          match psEraseIteApplication erase view with
          | Except.error error => Except.error error
          | Except.ok (some lowered) => Except.ok lowered
          | Except.ok none =>
              match psErasePrimitiveApplication erase view with
              | Except.error error => Except.error error
              | Except.ok (some lowered) => Except.ok lowered
              | Except.ok none =>
                  match
                      psEraseRuntimeStructureApplication
                        environment
                        scope
                        erase
                        view with
                  | Except.error error => Except.error error
                  | Except.ok (some lowered) => Except.ok lowered
                  | Except.ok none =>
                      match
                          psEraseRuntimeConstructorApplication
                            environment
                            scope
                            erase
                            view with
                      | Except.error error => Except.error error
                      | Except.ok (some lowered) => Except.ok lowered
                      | Except.ok none =>
                          match
                              psEraseRuntimeRecursorApplication
                                environment
                                scope
                                eraseAt
                                view with
                          | Except.error error => Except.error error
                          | Except.ok (some lowered) => Except.ok lowered
                          | Except.ok none =>
                              match
                                  psInferType
                                    environment
                                    psMetaEmpty
                                    scope.localContext
                                    view.head with
                              | Except.error _ =>
                                  Except.error
                                    PsErasureError.unsupportedApplication
                              | Except.ok headType =>
                                  match erase view.head with
                                  | Except.error error =>
                                      Except.error error
                                  | Except.ok loweredHead =>
                                      match
                                          psEraseApplicationArguments
                                            erase
                                            environment
                                            scope
                                            headType
                                            view.args
                                            {
                                              typeArgumentsRev := []
                                              runtimeArgumentsRev := []
                                              remainingType := headType
                                            } with
                                      | Except.error error =>
                                          Except.error error
                                      | Except.ok applied =>
                                          let typeArguments :=
                                            applied.typeArgumentsRev.reverse
                                          let runtimeArguments :=
                                            applied.runtimeArgumentsRev.reverse
                                          psEraseFinishApplication
                                            environment
                                            scope
                                            loweredHead
                                            typeArguments
                                            runtimeArguments
                                            applied.remainingType
      | .lam name type body binder =>
          let kind :=
            psErasureClassifyBinder
              environment
              scope.localContext
              type
          let pushed :=
            psLocalPushBinding
              scope.localContext
              name
              type
              binder
          let openedBody :=
            psExprInstantiate1 body (PsExpr.fvar pushed.id)
          match kind with
          | .runtime =>
              let parameterName :=
                psErasureSafeIdentifier
                  (psNameToString name)
                  "arg"
              match psEraseRuntimeType environment scope type with
              | Except.error error => Except.error error
              | Except.ok parameterType =>
                  let nextScope : PsErasureScope := {
                    localContext := pushed.context
                    runtimeLocals :=
                      (pushed.id, parameterName) ::
                        scope.runtimeLocals
                    typeLocals := scope.typeLocals
                    erasedLocals := scope.erasedLocals
                    declarationNames := scope.declarationNames
                    runtimeConstructors := scope.runtimeConstructors
                    runtimeRecursors := scope.runtimeRecursors
                    runtimeStructures := scope.runtimeStructures
                    runtimeStructureConstructors := scope.runtimeStructureConstructors
                    runtimeExpressions := scope.runtimeExpressions
                    currentDefinition := scope.currentDefinition
                  }
                  match
                      psEraseRuntimeExprWithFuel
                        environment
                        nextScope
                        fuel
                        openedBody with
                  | Except.error error => Except.error error
                  | Except.ok loweredBody =>
                      match loweredBody with
                      | .lambda parameters innerBody =>
                          Except.ok
                            (PsVerifiedIrExpr.lambda
                              ({
                                name := parameterName
                                type := parameterType
                              } :: parameters)
                              innerBody)
                      | _ =>
                          Except.ok
                            (PsVerifiedIrExpr.lambda
                              [{
                                name := parameterName
                                type := parameterType
                              }]
                              loweredBody)
          | .type =>
              let typeName := "T" ++ toString pushed.id
              let nextScope : PsErasureScope := {
                localContext := pushed.context
                runtimeLocals := scope.runtimeLocals
                typeLocals :=
                  (pushed.id, typeName) :: scope.typeLocals
                erasedLocals := pushed.id :: scope.erasedLocals
                declarationNames := scope.declarationNames
                runtimeConstructors := scope.runtimeConstructors
                runtimeRecursors := scope.runtimeRecursors
                runtimeStructures := scope.runtimeStructures
                runtimeStructureConstructors := scope.runtimeStructureConstructors
                runtimeExpressions := scope.runtimeExpressions
                currentDefinition := scope.currentDefinition
              }
              psEraseRuntimeExprWithFuel
                environment
                nextScope
                fuel
                openedBody
          | .proof =>
              let nextScope : PsErasureScope := {
                localContext := pushed.context
                runtimeLocals := scope.runtimeLocals
                typeLocals := scope.typeLocals
                erasedLocals := pushed.id :: scope.erasedLocals
                declarationNames := scope.declarationNames
                runtimeConstructors := scope.runtimeConstructors
                runtimeRecursors := scope.runtimeRecursors
                runtimeStructures := scope.runtimeStructures
                runtimeStructureConstructors := scope.runtimeStructureConstructors
                runtimeExpressions := scope.runtimeExpressions
                currentDefinition := scope.currentDefinition
              }
              psEraseRuntimeExprWithFuel
                environment
                nextScope
                fuel
                openedBody
      | .letE name type value body =>
          let kind :=
            psErasureClassifyBinder
              environment
              scope.localContext
              type
          match kind with
          | .runtime =>
              match
                  psEraseRuntimeExprWithFuel
                    environment
                    scope
                    fuel
                    value with
              | Except.error error => Except.error error
              | Except.ok loweredValue =>
                  let pushed :=
                    psLocalPushLet
                      scope.localContext
                      name
                      type
                      value
                  let localName :=
                    psErasureSafeIdentifier
                      (psNameToString name)
                      "local"
                  let nextScope : PsErasureScope := {
                    localContext := pushed.context
                    runtimeLocals :=
                      (pushed.id, localName) ::
                        scope.runtimeLocals
                    typeLocals := scope.typeLocals
                    erasedLocals := scope.erasedLocals
                    declarationNames := scope.declarationNames
                    runtimeConstructors := scope.runtimeConstructors
                    runtimeRecursors := scope.runtimeRecursors
                    runtimeStructures := scope.runtimeStructures
                    runtimeStructureConstructors := scope.runtimeStructureConstructors
                    runtimeExpressions := scope.runtimeExpressions
                    currentDefinition := scope.currentDefinition
                  }
                  match
                      psEraseRuntimeExprWithFuel
                        environment
                        nextScope
                        fuel
                        (psExprInstantiate1
                          body
                          (PsExpr.fvar pushed.id)) with
                  | Except.error error => Except.error error
                  | Except.ok loweredBody =>
                      Except.ok
                        (PsVerifiedIrExpr.letE
                          localName
                          loweredValue
                          loweredBody)
          | _ =>
              psEraseRuntimeExprWithFuel
                environment
                scope
                fuel
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
          match
              psErasureLookupStructure
                scope.runtimeStructures
                typeName with
          | none => Except.error PsErasureError.unsupportedRuntimeTerm
          | some structureInfo =>
              match
                  structureInfo.fields.find?
                    (fun field => field.projectionIndex == index) with
              | none => Except.error PsErasureError.unsupportedRuntimeTerm
              | some field =>
                  match
                      psEraseRuntimeExprWithFuel
                        environment
                        scope
                        fuel
                        target with
                  | Except.error error => Except.error error
                  | Except.ok loweredTarget =>
                      Except.ok
                        (PsVerifiedIrExpr.projection
                          loweredTarget
                          field.name)

def psEraseRuntimeExpr
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (expr : PsExpr) :
    Except PsErasureError PsVerifiedIrExpr :=
  psEraseRuntimeExprWithFuel environment scope 4096 expr
