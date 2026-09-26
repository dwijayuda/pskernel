import Ps.BackendRust.Expr
import Ps.BackendRust.ValueRefs
import Ps.BackendRust.Runtime

def psRustTypeParameterNames
    (parameters : List PsVerifiedIrTypeParameter) : List String :=
  match parameters with
  | List.nil =>
      List.nil
  | List.cons parameter rest =>
      List.cons
        (psRustConcat3
          (psRustIdentifier parameter.name)
          ": "
          "Clone")
        (psRustTypeParameterNames rest)

def psRustGenericNames
    (parameters : List PsVerifiedIrTypeParameter) : String :=
  match parameters with
  | List.nil =>
      ""
  | List.cons _ _ =>
      let names :=
        psRustTypeParameterNames parameters;
      psRustConcat4
        "<"
        (psRustJoin ", " names)
        ">"
        ""

def psRustEmitStructureFieldList
    (fields : List PsVerifiedIrStructureField) :
    Except PsRustEmitError (List String) :=
  match fields with
  | List.nil =>
      Except.ok List.nil
  | List.cons field rest =>
      if psRustTypeContainsFunction field.type then
        if psRustFunctionTypeIsFirstOrder field.type then
          match psRustEmitType field.type with
          | Except.error error =>
              Except.error error
          | Except.ok printedType =>
              let rendered :=
                psRustConcat4
                  "pub "
                  (psRustIdentifier field.name)
                  ": "
                  printedType;
              match psRustEmitStructureFieldList rest with
              | Except.error error =>
                  Except.error error
              | Except.ok printedRest =>
                  Except.ok (List.cons rendered printedRest)
        else
          Except.error
            (PsRustEmitError.functionStorageUnsupported field.name)
      else
        match psRustEmitType field.type with
        | Except.error error =>
            Except.error error
        | Except.ok printedType =>
            let rendered :=
              psRustConcat4
                "pub "
                (psRustIdentifier field.name)
                ": "
                printedType;
            match psRustEmitStructureFieldList rest with
            | Except.error error =>
                Except.error error
            | Except.ok printedRest =>
                Except.ok (List.cons rendered printedRest)

def psRustEmitStructure
    (structureInfo : PsVerifiedIrStructure) :
    Except PsRustEmitError String :=
  match psRustEmitStructureFieldList structureInfo.fields with
  | Except.error error =>
      Except.error error
  | Except.ok printedFields =>
      let generic :=
        psRustGenericNames structureInfo.typeParameters;
      Except.ok
        (psRustConcat4
          "#[derive(Clone)]\npub struct "
          (psRustIdentifier structureInfo.name)
          generic
          (psRustConcat4
            " { "
            (psRustJoin ", " printedFields)
            " }"
            ""))

def psRustEmitConstructorFieldList
    (fields : List PsVerifiedIrConstructorField) :
    Except PsRustEmitError (List String) :=
  match fields with
  | List.nil =>
      Except.ok List.nil
  | List.cons field rest =>
      if psRustTypeContainsFunction field.type then
        if psRustFunctionTypeIsFirstOrder field.type then
          match psRustEmitType field.type with
          | Except.error error =>
              Except.error error
          | Except.ok printedType =>
              let rendered :=
                psRustConcat3
                  (psRustIdentifier field.name)
                  ": "
                  printedType;
              match psRustEmitConstructorFieldList rest with
              | Except.error error =>
                  Except.error error
              | Except.ok printedRest =>
                  Except.ok (List.cons rendered printedRest)
        else
          Except.error
            (PsRustEmitError.functionStorageUnsupported field.name)
      else
        match psRustEmitType field.type with
        | Except.error error =>
            Except.error error
        | Except.ok printedType =>
            let rendered :=
              psRustConcat3
                (psRustIdentifier field.name)
                ": "
                printedType;
            match psRustEmitConstructorFieldList rest with
            | Except.error error =>
                Except.error error
            | Except.ok printedRest =>
                Except.ok (List.cons rendered printedRest)

def psRustEmitConstructor
    (constructorInfo : PsVerifiedIrConstructor) :
    Except PsRustEmitError String :=
  match psRustEmitConstructorFieldList constructorInfo.fields with
  | Except.error error =>
      Except.error error
  | Except.ok printedFields =>
      match printedFields with
      | List.nil =>
          Except.ok
            (psRustConcat2
              (psRustIdentifier constructorInfo.name)
              " {}")
      | List.cons _ _ =>
          Except.ok
            (psRustConcat4
              (psRustIdentifier constructorInfo.name)
              " { "
              (psRustJoin ", " printedFields)
              " }")

def psRustEmitConstructorList
    (constructors : List PsVerifiedIrConstructor) :
    Except PsRustEmitError (List String) :=
  match constructors with
  | List.nil =>
      Except.ok List.nil
  | List.cons constructorInfo rest =>
      match psRustEmitConstructor constructorInfo with
      | Except.error error =>
          Except.error error
      | Except.ok printed =>
          match psRustEmitConstructorList rest with
          | Except.error error =>
              Except.error error
          | Except.ok printedRest =>
              Except.ok (List.cons printed printedRest)

def psRustEmitInductive
    (inductiveInfo : PsVerifiedIrInductive) :
    Except PsRustEmitError String :=
  match psRustEmitConstructorList inductiveInfo.constructors with
  | Except.error error =>
      Except.error error
  | Except.ok printedConstructors =>
      let generic :=
        psRustGenericNames inductiveInfo.typeParameters;
      Except.ok
        (psRustConcat4
          "#[derive(Clone)]\npub enum "
          (psRustIdentifier inductiveInfo.name)
          generic
          (psRustConcat4
            " { "
            (psRustJoin ", " printedConstructors)
            " }"
            ""))

def psRustEmitHigherOrderParameterType
    (type : PsVerifiedIrType) :
    Except PsRustEmitError String :=
  match type with
  | PsVerifiedIrType.function parameters result =>
      match psRustEmitTypeListWith psRustEmitType parameters with
      | Except.error error =>
          Except.error error
      | Except.ok printedParameters =>
          match psRustEmitType result with
          | Except.error error =>
              Except.error error
          | Except.ok printedResult =>
              Except.ok
                (psRustConcat4
                  "impl Fn("
                  (psRustJoin ", " printedParameters)
                  ") -> "
                  (psRustConcat2 printedResult " + Clone"))
  | _ =>
      psRustEmitType type

def psRustEmitDeclarationParameter
    (parameter : PsVerifiedIrParameter) :
    Except PsRustEmitError String :=
  if psRustTypeContainsFunction parameter.type then
    if psRustFunctionTypeIsFirstOrder parameter.type then
      match psRustEmitHigherOrderParameterType parameter.type with
      | Except.error error =>
          Except.error error
      | Except.ok printedType =>
          Except.ok
            (psRustConcat3
              (psRustIdentifier parameter.name)
              ": "
              printedType)
    else
      Except.error
        (PsRustEmitError.nestedFunctionParameterUnsupported parameter.name)
  else
    match psRustEmitHigherOrderParameterType parameter.type with
    | Except.error error =>
        Except.error error
    | Except.ok printedType =>
        Except.ok
          (psRustConcat3
            (psRustIdentifier parameter.name)
            ": "
            printedType)

def psRustEmitDeclarationParameterList
    (parameters : List PsVerifiedIrParameter) :
    Except PsRustEmitError (List String) :=
  match parameters with
  | List.nil =>
      Except.ok List.nil
  | List.cons parameter rest =>
      match psRustEmitDeclarationParameter parameter with
      | Except.error error =>
          Except.error error
      | Except.ok rendered =>
          match psRustEmitDeclarationParameterList rest with
          | Except.error error =>
              Except.error error
          | Except.ok printedRest =>
              Except.ok (List.cons rendered printedRest)

def psRustDeclarationIsGenericValue
    (declaration : PsVerifiedIrDeclaration) : Bool :=
  match declaration.parameters with
  | List.nil =>
      match declaration.typeParameters with
      | List.nil => false
      | List.cons _ _ => true
  | List.cons _ _ =>
      false

def psRustFunctionResultExprSupported : PsVerifiedIrExpr -> Bool
  | PsVerifiedIrExpr.lambda _ _ _ =>
      true
  | PsVerifiedIrExpr.var _ =>
      true
  | PsVerifiedIrExpr.call fn _ _ =>
      match fn with
      | PsVerifiedIrExpr.var _ =>
          true
      | _ =>
          false
  | PsVerifiedIrExpr.letE _ type value body =>
      if psRustTypeContainsFunction type then
        if psRustFunctionTypeIsFirstOrder type then
          match value with
          | PsVerifiedIrExpr.var _ =>
              psRustFunctionResultExprSupported body
          | _ =>
              false
        else
          false
      else
        psRustFunctionResultExprSupported body
  | _ =>
      false

def psRustDeclarationDirectFunctionResultSupported
    (declaration : PsVerifiedIrDeclaration) : Bool :=
  if psRustFunctionTypeIsFirstOrder declaration.resultType then
    psRustFunctionResultExprSupported declaration.body
  else
    false

def psRustEmitDeclarationResultType
    (declaration : PsVerifiedIrDeclaration) :
    Except PsRustEmitError String :=
  if psRustTypeContainsFunction declaration.resultType then
    if psRustDeclarationDirectFunctionResultSupported declaration then
      psRustEmitHigherOrderParameterType declaration.resultType
    else
      Except.error
        (PsRustEmitError.functionResultUnsupported declaration.name)
  else
    psRustEmitType declaration.resultType

def psRustPrepareDeclarationBody
    (declaration : PsVerifiedIrDeclaration)
    (printedBody : String) : String :=
  if psRustTypeContainsFunction declaration.resultType then
    match declaration.body with
    | PsVerifiedIrExpr.lambda _ _ _ =>
        psRustConcat2 "move " printedBody
    | _ =>
        printedBody
  else
    printedBody

def psRustEmitFunctionResultExprWithFuel
    (declarationName : String) :
    Nat ->
    PsVerifiedIrExpr ->
    Except PsRustEmitError String
  | 0, _ =>
      Except.error PsRustEmitError.fuelExhausted
  | fuel + 1, expr =>
      match expr with
      | PsVerifiedIrExpr.lambda _ _ _ =>
          match psRustEmitExprWithFuel fuel expr with
          | Except.error error =>
              Except.error error
          | Except.ok printed =>
              Except.ok (psRustConcat2 "move " printed)
      | PsVerifiedIrExpr.var _ =>
          psRustEmitExprWithFuel fuel expr
      | PsVerifiedIrExpr.call fn typeArguments arguments =>
          match fn with
          | PsVerifiedIrExpr.var _ =>
              psRustEmitExprWithFuel
                fuel
                (PsVerifiedIrExpr.call fn typeArguments arguments)
          | _ =>
              Except.error
                (PsRustEmitError.functionResultUnsupported declarationName)
      | PsVerifiedIrExpr.letE name _ value body =>
          match psRustEmitExprWithFuel fuel value with
          | Except.error error =>
              Except.error error
          | Except.ok printedValue =>
              match
                  psRustEmitFunctionResultExprWithFuel
                    declarationName
                    fuel
                    body with
              | Except.error error =>
                  Except.error error
              | Except.ok printedBody =>
                  Except.ok
                    (psRustConcat4
                      "{ let "
                      (psRustIdentifier name)
                      " = "
                      (psRustConcat4
                        (psRustClonePrinted printedValue)
                        "; "
                        printedBody
                        " }"))
      | _ =>
          Except.error
            (PsRustEmitError.functionResultUnsupported declarationName)

def psRustEmitFunctionResultExpr
    (declarationName : String)
    (expr : PsVerifiedIrExpr) :
    Except PsRustEmitError String :=
  psRustEmitFunctionResultExprWithFuel
    declarationName
    4096
    expr

def psRustEmitDeclaration
    (valueNames : List String)
    (declaration : PsVerifiedIrDeclaration) :
    Except PsRustEmitError String :=
  if psRustDeclarationIsGenericValue declaration then
    Except.error
      (PsRustEmitError.genericValueUnsupported declaration.name)
  else
    match psRustEmitDeclarationParameterList declaration.parameters with
    | Except.error error =>
        Except.error error
    | Except.ok printedParameters =>
        match psRustEmitDeclarationResultType declaration with
        | Except.error error =>
            Except.error error
        | Except.ok printedResult =>
            let locals :=
              psRustAddParameterNames
                declaration.parameters
                List.nil;
            match
                psRustRewriteValueRefs
                  valueNames
                  locals
                  declaration.body with
            | Except.error error =>
                Except.error error
            | Except.ok rewrittenBody =>
                let emittedBody :=
                  if psRustTypeContainsFunction declaration.resultType then
                    psRustEmitFunctionResultExpr
                      declaration.name
                      rewrittenBody
                  else
                    psRustEmitExpr rewrittenBody;
                match emittedBody with
                | Except.error error =>
                    Except.error error
                | Except.ok printedBody =>
                    let generic :=
                      psRustGenericNames declaration.typeParameters;
                    Except.ok
                      (psRustConcat4
                        "pub fn "
                        (psRustIdentifier declaration.name)
                        generic
                        (psRustConcat4
                          "("
                          (psRustJoin ", " printedParameters)
                          ") -> "
                          (psRustConcat4
                            printedResult
                            " { "
                            printedBody
                            " }")))

def psRustEmitStructureList
    (structures : List PsVerifiedIrStructure) :
    Except PsRustEmitError (List String) :=
  match structures with
  | List.nil =>
      Except.ok List.nil
  | List.cons structureInfo rest =>
      match psRustEmitStructure structureInfo with
      | Except.error error =>
          Except.error error
      | Except.ok printed =>
          match psRustEmitStructureList rest with
          | Except.error error =>
              Except.error error
          | Except.ok printedRest =>
              Except.ok (List.cons printed printedRest)

def psRustEmitInductiveList
    (inductives : List PsVerifiedIrInductive) :
    Except PsRustEmitError (List String) :=
  match inductives with
  | List.nil =>
      Except.ok List.nil
  | List.cons inductiveInfo rest =>
      match psRustEmitInductive inductiveInfo with
      | Except.error error =>
          Except.error error
      | Except.ok printed =>
          match psRustEmitInductiveList rest with
          | Except.error error =>
              Except.error error
          | Except.ok printedRest =>
              Except.ok (List.cons printed printedRest)

def psRustValueDeclarationNames
    (declarations : List PsVerifiedIrDeclaration) :
    List String :=
  match declarations with
  | List.nil =>
      List.nil
  | List.cons declaration rest =>
      match declaration.parameters with
      | List.nil =>
          List.cons
            declaration.name
            (psRustValueDeclarationNames rest)
      | List.cons _ _ =>
          psRustValueDeclarationNames rest

def psRustEmitDeclarationList
    (valueNames : List String)
    (declarations : List PsVerifiedIrDeclaration) :
    Except PsRustEmitError (List String) :=
  match declarations with
  | List.nil =>
      Except.ok List.nil
  | List.cons declaration rest =>
      match psRustEmitDeclaration valueNames declaration with
      | Except.error error =>
          Except.error error
      | Except.ok printed =>
          match psRustEmitDeclarationList valueNames rest with
          | Except.error error =>
              Except.error error
          | Except.ok printedRest =>
              Except.ok (List.cons printed printedRest)

def psRustStructureNames :
    List PsVerifiedIrStructure -> List String
  | List.nil =>
      List.nil
  | List.cons structureInfo rest =>
      List.cons structureInfo.name (psRustStructureNames rest)

def psRustInductiveNames :
    List PsVerifiedIrInductive -> List String
  | List.nil =>
      List.nil
  | List.cons inductiveInfo rest =>
      List.cons inductiveInfo.name (psRustInductiveNames rest)

def psRustParameterListContainsFunction :
    List PsVerifiedIrParameter -> Bool
  | List.nil =>
      false
  | List.cons parameter rest =>
      if psRustTypeContainsFunction parameter.type then
        true
      else
        psRustParameterListContainsFunction rest

def psRustDeclarationIsStaticFirstOrderFunction
    (declaration : PsVerifiedIrDeclaration) : Bool :=
  match declaration.typeParameters with
  | List.nil =>
      match declaration.parameters with
      | List.nil =>
          false
      | List.cons _ _ =>
          if psRustParameterListContainsFunction declaration.parameters then
            false
          else
            if psRustTypeContainsFunction declaration.resultType then
              false
            else
              true
  | List.cons _ _ =>
      false

def psRustStaticFirstOrderFunctionNames :
    List PsVerifiedIrDeclaration -> List String
  | List.nil =>
      List.nil
  | List.cons declaration rest =>
      if psRustDeclarationIsStaticFirstOrderFunction declaration then
        List.cons
          declaration.name
          (psRustStaticFirstOrderFunctionNames rest)
      else
        psRustStaticFirstOrderFunctionNames rest

def psRustFindStructureFields
    (target : String) :
    List PsVerifiedIrStructure ->
    Option (List PsVerifiedIrStructureField)
  | List.nil =>
      Option.none
  | List.cons structureInfo rest =>
      if psStringEq structureInfo.name target then
        Option.some structureInfo.fields
      else
        psRustFindStructureFields target rest

def psRustFindStructureFieldType
    (target : String) :
    List PsVerifiedIrStructureField ->
    Option PsVerifiedIrType
  | List.nil =>
      Option.none
  | List.cons field rest =>
      if psStringEq field.name target then
        Option.some field.type
      else
        psRustFindStructureFieldType target rest

def psRustFindInductiveConstructors
    (target : String) :
    List PsVerifiedIrInductive ->
    Option (List PsVerifiedIrConstructor)
  | List.nil =>
      Option.none
  | List.cons inductiveInfo rest =>
      if psStringEq inductiveInfo.name target then
        Option.some inductiveInfo.constructors
      else
        psRustFindInductiveConstructors target rest

def psRustFindConstructorFields
    (target : String) :
    List PsVerifiedIrConstructor ->
    Option (List PsVerifiedIrConstructorField)
  | List.nil =>
      Option.none
  | List.cons constructorInfo rest =>
      if psStringEq constructorInfo.name target then
        Option.some constructorInfo.fields
      else
        psRustFindConstructorFields target rest

def psRustFindConstructorFieldType
    (target : String) :
    List PsVerifiedIrConstructorField ->
    Option PsVerifiedIrType
  | List.nil =>
      Option.none
  | List.cons field rest =>
      if psStringEq field.name target then
        Option.some field.type
      else
        psRustFindConstructorFieldType target rest

def psRustValidateStaticStoredFunction
    (staticFunctionNames : List String)
    (locals : List String)
    (fieldName : String)
    (value : PsVerifiedIrExpr) :
    Except PsRustEmitError Bool :=
  match value with
  | PsVerifiedIrExpr.var name =>
      if psRustStringListContains locals name then
        Except.error
          (PsRustEmitError.functionStorageUnsupported fieldName)
      else
        if psRustStringListContains staticFunctionNames name then
          Except.ok true
        else
          Except.error
            (PsRustEmitError.functionStorageUnsupported fieldName)
  | _ =>
      Except.error
        (PsRustEmitError.functionStorageUnsupported fieldName)

def psRustValidateExprListWith
    (validate :
      PsVerifiedIrExpr ->
      Except PsRustEmitError Bool) :
    List PsVerifiedIrExpr ->
    Except PsRustEmitError Bool
  | List.nil =>
      Except.ok true
  | List.cons expr rest =>
      match validate expr with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          psRustValidateExprListWith validate rest

def psRustValidateFieldListWith
    (validate :
      PsVerifiedIrExpr ->
      Except PsRustEmitError Bool) :
    List (Prod String PsVerifiedIrExpr) ->
    Except PsRustEmitError Bool
  | List.nil =>
      Except.ok true
  | List.cons field rest =>
      match validate (Prod.snd field) with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          psRustValidateFieldListWith validate rest

def psRustValidateAlternativeListWith
    (validate :
      PsVerifiedIrExpr ->
      Except PsRustEmitError Bool) :
    List
      (Prod String
        (Prod
          (List PsVerifiedIrMatchBinding)
          PsVerifiedIrExpr)) ->
    Except PsRustEmitError Bool
  | List.nil =>
      Except.ok true
  | List.cons alternative rest =>
      let payload := Prod.snd alternative;
      match validate (Prod.snd payload) with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          psRustValidateAlternativeListWith validate rest

def psRustValidateStorageFieldListWith
    (staticFunctionNames : List String)
    (locals : List String)
    (definitionFields : List PsVerifiedIrStructureField)
    (validateNested :
      PsVerifiedIrExpr ->
      Except PsRustEmitError Bool) :
    List (Prod String PsVerifiedIrExpr) ->
    Except PsRustEmitError Bool
  | List.nil =>
      Except.ok true
  | List.cons field rest =>
      let fieldName := Prod.fst field;
      let value := Prod.snd field;
      match psRustFindStructureFieldType fieldName definitionFields with
      | Option.none =>
          match validateNested value with
          | Except.error error =>
              Except.error error
          | Except.ok _ =>
              psRustValidateStorageFieldListWith
                staticFunctionNames
                locals
                definitionFields
                validateNested
                rest
      | Option.some fieldType =>
          if psRustTypeContainsFunction fieldType then
            if psRustFunctionTypeIsFirstOrder fieldType then
              match
                  psRustValidateStaticStoredFunction
                    staticFunctionNames
                    locals
                    fieldName
                    value with
              | Except.error error =>
                  Except.error error
              | Except.ok _ =>
                  psRustValidateStorageFieldListWith
                    staticFunctionNames
                    locals
                    definitionFields
                    validateNested
                    rest
            else
              Except.error
                (PsRustEmitError.functionStorageUnsupported fieldName)
          else
            match validateNested value with
            | Except.error error =>
                Except.error error
            | Except.ok _ =>
                psRustValidateStorageFieldListWith
                  staticFunctionNames
                  locals
                  definitionFields
                  validateNested
                  rest

def psRustValidateConstructorStorageFieldListWith
    (staticFunctionNames : List String)
    (locals : List String)
    (definitionFields : List PsVerifiedIrConstructorField)
    (validateNested :
      PsVerifiedIrExpr ->
      Except PsRustEmitError Bool) :
    List (Prod String PsVerifiedIrExpr) ->
    Except PsRustEmitError Bool
  | List.nil =>
      Except.ok true
  | List.cons field rest =>
      let fieldName := Prod.fst field;
      let value := Prod.snd field;
      match psRustFindConstructorFieldType fieldName definitionFields with
      | Option.none =>
          match validateNested value with
          | Except.error error =>
              Except.error error
          | Except.ok _ =>
              psRustValidateConstructorStorageFieldListWith
                staticFunctionNames
                locals
                definitionFields
                validateNested
                rest
      | Option.some fieldType =>
          if psRustTypeContainsFunction fieldType then
            if psRustFunctionTypeIsFirstOrder fieldType then
              match
                  psRustValidateStaticStoredFunction
                    staticFunctionNames
                    locals
                    fieldName
                    value with
              | Except.error error =>
                  Except.error error
              | Except.ok _ =>
                  psRustValidateConstructorStorageFieldListWith
                    staticFunctionNames
                    locals
                    definitionFields
                    validateNested
                    rest
            else
              Except.error
                (PsRustEmitError.functionStorageUnsupported fieldName)
          else
            match validateNested value with
            | Except.error error =>
                Except.error error
            | Except.ok _ =>
                psRustValidateConstructorStorageFieldListWith
                  staticFunctionNames
                  locals
                  definitionFields
                  validateNested
                  rest

def psRustValidateStorageAlternativeListWith
    (validateBody :
      List PsVerifiedIrMatchBinding ->
      PsVerifiedIrExpr ->
      Except PsRustEmitError Bool) :
    List
      (Prod String
        (Prod
          (List PsVerifiedIrMatchBinding)
          PsVerifiedIrExpr)) ->
    Except PsRustEmitError Bool
  | List.nil =>
      Except.ok true
  | List.cons alternative rest =>
      let payload := Prod.snd alternative;
      match validateBody (Prod.fst payload) (Prod.snd payload) with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          psRustValidateStorageAlternativeListWith
            validateBody
            rest

def psRustValidateStorageExprWithFuel
    (structures : List PsVerifiedIrStructure)
    (inductives : List PsVerifiedIrInductive)
    (staticFunctionNames : List String)
    (locals : List String) :
    Nat ->
    PsVerifiedIrExpr ->
    Except PsRustEmitError Bool
  | 0, _ =>
      Except.error PsRustEmitError.fuelExhausted
  | fuel + 1, expr =>
      let validateNested :=
        fun (nested : PsVerifiedIrExpr) =>
          psRustValidateStorageExprWithFuel
            structures
            inductives
            staticFunctionNames
            locals
            fuel
            nested;
      match expr with
      | PsVerifiedIrExpr.literal _ =>
          Except.ok true
      | PsVerifiedIrExpr.var _ =>
          Except.ok true
      | PsVerifiedIrExpr.intrinsic _ arguments =>
          psRustValidateExprListWith validateNested arguments
      | PsVerifiedIrExpr.lambda parameters _ body =>
          psRustValidateStorageExprWithFuel
            structures
            inductives
            staticFunctionNames
            (psRustAddParameterNames parameters locals)
            fuel
            body
      | PsVerifiedIrExpr.call fn _ arguments =>
          match validateNested fn with
          | Except.error error =>
              Except.error error
          | Except.ok _ =>
              psRustValidateExprListWith validateNested arguments
      | PsVerifiedIrExpr.letE name _ value body =>
          match validateNested value with
          | Except.error error =>
              Except.error error
          | Except.ok _ =>
              psRustValidateStorageExprWithFuel
                structures
                inductives
                staticFunctionNames
                (List.cons name locals)
                fuel
                body
      | PsVerifiedIrExpr.ifE condition thenBranch elseBranch =>
          match validateNested condition with
          | Except.error error =>
              Except.error error
          | Except.ok _ =>
              match validateNested thenBranch with
              | Except.error error =>
                  Except.error error
              | Except.ok _ =>
                  validateNested elseBranch
      | PsVerifiedIrExpr.record structureName _ fields =>
          match psRustFindStructureFields structureName structures with
          | Option.none =>
              psRustValidateFieldListWith validateNested fields
          | Option.some definitionFields =>
              psRustValidateStorageFieldListWith
                staticFunctionNames
                locals
                definitionFields
                validateNested
                fields
      | PsVerifiedIrExpr.projection _ _ target _ =>
          validateNested target
      | PsVerifiedIrExpr.constructor
          inductiveName
          constructorName
          _
          fields =>
          match
              psRustFindInductiveConstructors
                inductiveName
                inductives with
          | Option.none =>
              psRustValidateFieldListWith validateNested fields
          | Option.some constructors =>
              match
                  psRustFindConstructorFields
                    constructorName
                    constructors with
              | Option.none =>
                  psRustValidateFieldListWith validateNested fields
              | Option.some definitionFields =>
                  psRustValidateConstructorStorageFieldListWith
                    staticFunctionNames
                    locals
                    definitionFields
                    validateNested
                    fields
      | PsVerifiedIrExpr.matchE _ _ scrutinee alternatives =>
          match validateNested scrutinee with
          | Except.error error =>
              Except.error error
          | Except.ok _ =>
              let validateBody :=
                fun
                  (bindings : List PsVerifiedIrMatchBinding)
                  (body : PsVerifiedIrExpr) =>
                  psRustValidateStorageExprWithFuel
                    structures
                    inductives
                    staticFunctionNames
                    (psRustAddBindingNames bindings locals)
                    fuel
                    body;
              psRustValidateStorageAlternativeListWith
                validateBody
                alternatives

def psRustValidateStorageDeclarationList
    (structures : List PsVerifiedIrStructure)
    (inductives : List PsVerifiedIrInductive)
    (staticFunctionNames : List String) :
    List PsVerifiedIrDeclaration ->
    Except PsRustEmitError Bool
  | List.nil =>
      Except.ok true
  | List.cons declaration rest =>
      match
          psRustValidateStorageExprWithFuel
            structures
            inductives
            staticFunctionNames
            (psRustAddParameterNames
              declaration.parameters
              List.nil)
            4096
            declaration.body with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          psRustValidateStorageDeclarationList
            structures
            inductives
            staticFunctionNames
            rest

def psRustValidateModuleFunctionStorage
    (module : PsVerifiedIrModule) :
    Except PsRustEmitError Bool :=
  psRustValidateStorageDeclarationList
    module.structures
    module.inductives
    (psRustStaticFirstOrderFunctionNames module.declarations)
    module.declarations

def psRustValidateExprNamesWithFuel
    (structureNames : List String)
    (inductiveNames : List String) :
    Nat ->
    PsVerifiedIrExpr ->
    Except PsRustEmitError Bool
  | 0, _ =>
      Except.error PsRustEmitError.fuelExhausted
  | fuel + 1, expr =>
      let validateNested :=
        fun (nested : PsVerifiedIrExpr) =>
          psRustValidateExprNamesWithFuel
            structureNames
            inductiveNames
            fuel
            nested;
      match expr with
      | PsVerifiedIrExpr.literal _ =>
          Except.ok true
      | PsVerifiedIrExpr.var _ =>
          Except.ok true
      | PsVerifiedIrExpr.intrinsic _ arguments =>
          psRustValidateExprListWith validateNested arguments
      | PsVerifiedIrExpr.lambda _ _ body =>
          validateNested body
      | PsVerifiedIrExpr.call fn _ arguments =>
          match validateNested fn with
          | Except.error error =>
              Except.error error
          | Except.ok _ =>
              psRustValidateExprListWith validateNested arguments
      | PsVerifiedIrExpr.letE _ _ value body =>
          match validateNested value with
          | Except.error error =>
              Except.error error
          | Except.ok _ =>
              validateNested body
      | PsVerifiedIrExpr.ifE condition thenBranch elseBranch =>
          match validateNested condition with
          | Except.error error =>
              Except.error error
          | Except.ok _ =>
              match validateNested thenBranch with
              | Except.error error =>
                  Except.error error
              | Except.ok _ =>
                  validateNested elseBranch
      | PsVerifiedIrExpr.record structureName _ fields =>
          if psRustStringListContains structureNames structureName then
            psRustValidateFieldListWith validateNested fields
          else
            Except.error
              (PsRustEmitError.unknownStructure structureName)
      | PsVerifiedIrExpr.projection _ _ target _ =>
          validateNested target
      | PsVerifiedIrExpr.constructor
          inductiveName
          _
          _
          fields =>
          if psRustStringListContains inductiveNames inductiveName then
            psRustValidateFieldListWith validateNested fields
          else
            Except.error
              (PsRustEmitError.unknownInductive inductiveName)
      | PsVerifiedIrExpr.matchE
          inductiveName
          _
          scrutinee
          alternatives =>
          if psRustStringListContains inductiveNames inductiveName then
            match validateNested scrutinee with
            | Except.error error =>
                Except.error error
            | Except.ok _ =>
                psRustValidateAlternativeListWith
                  validateNested
                  alternatives
          else
            Except.error
              (PsRustEmitError.unknownInductive inductiveName)

def psRustValidateDeclarationNames
    (structureNames : List String)
    (inductiveNames : List String) :
    List PsVerifiedIrDeclaration ->
    Except PsRustEmitError Bool
  | List.nil =>
      Except.ok true
  | List.cons declaration rest =>
      match
          psRustValidateExprNamesWithFuel
            structureNames
            inductiveNames
            4096
            declaration.body with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          psRustValidateDeclarationNames
            structureNames
            inductiveNames
            rest

def psRustValidateModuleNames
    (module : PsVerifiedIrModule) :
    Except PsRustEmitError Bool :=
  psRustValidateDeclarationNames
    (psRustStructureNames module.structures)
    (psRustInductiveNames module.inductives)
    module.declarations

def psRustModuleHasImports
    (imports : List PsVerifiedIrExternalImport) : Bool :=
  match imports with
  | List.nil =>
      false
  | List.cons _ _ =>
      true

def psRustEmitModule
    (module : PsVerifiedIrModule) :
    Except PsRustEmitError String :=
  let valueNames :=
    psRustValueDeclarationNames module.declarations;
  if psRustModuleHasImports module.imports then
    Except.error PsRustEmitError.externalImportUnsupported
  else
    match psRustValidateModuleNames module with
    | Except.error error =>
        Except.error error
    | Except.ok _ =>
        match psRustValidateModuleFunctionStorage module with
        | Except.error error =>
            Except.error error
        | Except.ok _ =>
            match psRustEmitStructureList module.structures with
            | Except.error error =>
                Except.error error
            | Except.ok structures =>
                match psRustEmitInductiveList module.inductives with
                | Except.error error =>
                    Except.error error
                | Except.ok inductives =>
                    match psRustEmitDeclarationList valueNames module.declarations with
                    | Except.error error =>
                        Except.error error
                    | Except.ok declarations =>
                        let sections :=
                          List.cons
                            psRustRuntimePrelude
                            (List.append
                              structures
                              (List.append inductives declarations));
                        Except.ok
                          (psRustConcat2
                            (psRustJoin "\n" sections)
                            "\n")
