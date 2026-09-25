import Ps.BackendWasm.Type
import Ps.BackendWasm.RuntimeNat

def psWasmArrayTypeListContains
    (types : List PsVerifiedIrType)
    (candidate : PsVerifiedIrType) : Bool :=
  match psWasmIrTypeKey candidate with
  | none => false
  | some candidateKey =>
      types.any
        (fun existing =>
          match psWasmIrTypeKey existing with
          | none => false
          | some existingKey =>
              existingKey == candidateKey)

def psWasmInsertArrayElementType
    (types : List PsVerifiedIrType)
    (candidate : PsVerifiedIrType) :
    List PsVerifiedIrType :=
  if psWasmArrayTypeListContains types candidate then
    types
  else
    types ++ [candidate]

def psWasmCollectArrayTypesFromTypeWithFuel :
    Nat ->
    PsVerifiedIrType ->
    List PsVerifiedIrType ->
    List PsVerifiedIrType
  | 0, _, types => types
  | fuel + 1, type, types =>
      let collect :=
        fun nested state =>
          psWasmCollectArrayTypesFromTypeWithFuel
            fuel
            nested
            state
      match type with
      | .function parameters result =>
          let withParameters :=
            parameters.foldl
              (fun state parameter =>
                collect parameter state)
              types
          collect result withParameters
      | .named "Array" [elementType] =>
          let withNested :=
            collect elementType types
          psWasmInsertArrayElementType
            withNested
            elementType
      | .named _ arguments =>
          arguments.foldl
            (fun state argument =>
              collect argument state)
            types
      | _ => types

def psWasmCollectArrayTypesFromType
    (type : PsVerifiedIrType)
    (types : List PsVerifiedIrType) :
    List PsVerifiedIrType :=
  psWasmCollectArrayTypesFromTypeWithFuel
    64
    type
    types

def psWasmCollectArrayTypesFromIntrinsic
    (operation : PsVerifiedIrIntrinsic)
    (types : List PsVerifiedIrType) :
    List PsVerifiedIrType :=
  match operation with
  | .arrayEmptyWithCapacity elementType
  | .arraySize elementType
  | .arrayPush elementType
  | .arrayGet elementType
  | .arrayGetD elementType
  | .arraySet elementType
  | .arraySetIfInBounds elementType =>
      psWasmCollectArrayTypesFromType
        elementType
        (psWasmInsertArrayElementType
          types
          elementType)
  | .arrayMap sourceType resultType =>
      let withSource :=
        psWasmCollectArrayTypesFromType
          sourceType
          (psWasmInsertArrayElementType
            types
            sourceType)
      psWasmCollectArrayTypesFromType
        resultType
        (psWasmInsertArrayElementType
          withSource
          resultType)
  | .arrayFoldl elementType accumulatorType =>
      let withElement :=
        psWasmCollectArrayTypesFromType
          elementType
          (psWasmInsertArrayElementType
            types
            elementType)
      psWasmCollectArrayTypesFromType
        accumulatorType
        withElement
  | _ => types

def psWasmCollectArrayTypesFromExprWithFuel :
    Nat ->
    PsVerifiedIrExpr ->
    List PsVerifiedIrType ->
    List PsVerifiedIrType
  | 0, _, types => types
  | fuel + 1, expression, types =>
      let collect :=
        fun nested state =>
          psWasmCollectArrayTypesFromExprWithFuel
            fuel
            nested
            state
      match expression with
      | .literal _ => types
      | .var _ => types
      | .intrinsic operation arguments =>
          let withOperation :=
            psWasmCollectArrayTypesFromIntrinsic
              operation
              types
          arguments.foldl
            (fun state argument =>
              collect argument state)
            withOperation
      | .lambda parameters resultType body =>
          let withParameters :=
            parameters.foldl
              (fun state parameter =>
                psWasmCollectArrayTypesFromType
                  parameter.type
                  state)
              types
          let withResult :=
            psWasmCollectArrayTypesFromType
              resultType
              withParameters
          collect body withResult
      | .call fn typeArguments arguments =>
          let withFn := collect fn types
          let withTypes :=
            typeArguments.foldl
              (fun state type =>
                psWasmCollectArrayTypesFromType
                  type
                  state)
              withFn
          arguments.foldl
            (fun state argument =>
              collect argument state)
            withTypes
      | .letE _ type value body =>
          let withType :=
            psWasmCollectArrayTypesFromType
              type
              types
          let withValue := collect value withType
          collect body withValue
      | .ifE condition thenBranch elseBranch =>
          let withCondition :=
            collect condition types
          let withThen :=
            collect thenBranch withCondition
          collect elseBranch withThen
      | .record _ typeArguments fields =>
          let withTypes :=
            typeArguments.foldl
              (fun state type =>
                psWasmCollectArrayTypesFromType
                  type
                  state)
              types
          fields.foldl
            (fun state field =>
              collect field.2 state)
            withTypes
      | .projection _ typeArguments target _ =>
          let withTypes :=
            typeArguments.foldl
              (fun state type =>
                psWasmCollectArrayTypesFromType
                  type
                  state)
              types
          collect target withTypes
      | .constructor _ _ typeArguments fields =>
          let withTypes :=
            typeArguments.foldl
              (fun state type =>
                psWasmCollectArrayTypesFromType
                  type
                  state)
              types
          fields.foldl
            (fun state field =>
              collect field.2 state)
            withTypes
      | .matchE _ typeArguments scrutinee alternatives =>
          let withTypes :=
            typeArguments.foldl
              (fun state type =>
                psWasmCollectArrayTypesFromType
                  type
                  state)
              types
          let withScrutinee :=
            collect scrutinee withTypes
          alternatives.foldl
            (fun state alternative =>
              let bindings := alternative.2.1
              let body := alternative.2.2
              let withBindings :=
                bindings.foldl
                  (fun inner binding =>
                    psWasmCollectArrayTypesFromType
                      binding.type
                      inner)
                  state
              collect body withBindings)
            withScrutinee

def psWasmCollectArrayTypesFromExpr
    (expression : PsVerifiedIrExpr)
    (types : List PsVerifiedIrType) :
    List PsVerifiedIrType :=
  psWasmCollectArrayTypesFromExprWithFuel
    4096
    expression
    types

def psWasmCollectModuleArrayElementTypes
    (module : PsVerifiedIrModule) :
    List PsVerifiedIrType :=
  let fromImports :=
    module.imports.foldl
      (fun state importInfo =>
        psWasmCollectArrayTypesFromType
          importInfo.type
          state)
      []
  let fromStructures :=
    module.structures.foldl
      (fun state structureInfo =>
        structureInfo.fields.foldl
          (fun inner field =>
            psWasmCollectArrayTypesFromType
              field.type
              inner)
          state)
      fromImports
  let fromInductives :=
    module.inductives.foldl
      (fun state inductiveInfo =>
        inductiveInfo.constructors.foldl
          (fun inner constructorInfo =>
            constructorInfo.fields.foldl
              (fun fieldsState field =>
                psWasmCollectArrayTypesFromType
                  field.type
                  fieldsState)
              inner)
          state)
      fromStructures
  module.declarations.foldl
    (fun state declaration =>
      let withParameters :=
        declaration.parameters.foldl
          (fun inner parameter =>
            psWasmCollectArrayTypesFromType
              parameter.type
              inner)
          state
      let withResult :=
        psWasmCollectArrayTypesFromType
          declaration.resultType
          withParameters
      psWasmCollectArrayTypesFromExpr
        declaration.body
        withResult)
    fromInductives

def psWasmLowerArrayType?
    (profile : PsWasmTargetProfile)
    (elementType : PsVerifiedIrType) :
    Option PsWasmArrayType :=
  match psWasmArrayTypeName elementType with
  | none => none
  | some name =>
      match psWasmStorageTypeOfIrType? profile elementType with
      | none => none
      | some storageType =>
          some {
            name := name
            elementType := storageType
            mutable := true
          }

def psWasmLowerArrayTypes? 
    (profile : PsWasmTargetProfile) :
    List PsVerifiedIrType ->
    Option (List PsWasmArrayType)
  | [] => some []
  | elementType :: rest =>
      match
          psWasmLowerArrayType?
            profile
            elementType with
      | none => none
      | some lowered =>
          match psWasmLowerArrayTypes? profile rest with
          | none => none
          | some loweredRest =>
              some (lowered :: loweredRest)

def psWasmArrayGetInstruction
    (arrayTypeName : String)
    (elementType : PsVerifiedIrType) : PsWasmInstruction :=
  match elementType with
  | .primitive .uint8 =>
      PsWasmInstruction.arrayGetU arrayTypeName
  | .primitive .uint16 =>
      PsWasmInstruction.arrayGetU arrayTypeName
  | .primitive .int8 =>
      PsWasmInstruction.arrayGetS arrayTypeName
  | .primitive .int16 =>
      PsWasmInstruction.arrayGetS arrayTypeName
  | _ =>
      PsWasmInstruction.arrayGet arrayTypeName


structure PsWasmArrayMapSpec where
  sourceType : PsVerifiedIrType
  resultType : PsVerifiedIrType

structure PsWasmArrayFoldSpec where
  elementType : PsVerifiedIrType
  accumulatorType : PsVerifiedIrType

def psWasmArraySemanticType
    (elementType : PsVerifiedIrType) : PsVerifiedIrType :=
  PsVerifiedIrType.named "Array" [elementType]

def psWasmArrayMapLoopName?
    (sourceType resultType : PsVerifiedIrType) : Option String :=
  match
      psWasmIrTypeKey sourceType,
      psWasmIrTypeKey resultType with
  | some sourceKey, some resultKey =>
      some
        ("__ps_array_map_loop$"
          ++ sourceKey
          ++ "$"
          ++ resultKey)
  | _, _ => none

def psWasmArrayMapRootName?
    (sourceType resultType : PsVerifiedIrType) : Option String :=
  match
      psWasmIrTypeKey sourceType,
      psWasmIrTypeKey resultType with
  | some sourceKey, some resultKey =>
      some
        ("__ps_array_map$"
          ++ sourceKey
          ++ "$"
          ++ resultKey)
  | _, _ => none

def psWasmArrayFoldLoopName?
    (elementType accumulatorType : PsVerifiedIrType) :
    Option String :=
  match
      psWasmIrTypeKey elementType,
      psWasmIrTypeKey accumulatorType with
  | some elementKey, some accumulatorKey =>
      some
        ("__ps_array_foldl$"
          ++ elementKey
          ++ "$"
          ++ accumulatorKey)
  | _, _ => none

def psWasmArrayMapSpecEq
    (left right : PsWasmArrayMapSpec) : Bool :=
  match
      psWasmArrayMapRootName?
        left.sourceType
        left.resultType,
      psWasmArrayMapRootName?
        right.sourceType
        right.resultType with
  | some leftName, some rightName =>
      leftName == rightName
  | _, _ => false

def psWasmArrayFoldSpecEq
    (left right : PsWasmArrayFoldSpec) : Bool :=
  match
      psWasmArrayFoldLoopName?
        left.elementType
        left.accumulatorType,
      psWasmArrayFoldLoopName?
        right.elementType
        right.accumulatorType with
  | some leftName, some rightName =>
      leftName == rightName
  | _, _ => false

def psWasmInsertArrayMapSpec
    (specs : List PsWasmArrayMapSpec)
    (sourceType resultType : PsVerifiedIrType) :
    List PsWasmArrayMapSpec :=
  let candidate : PsWasmArrayMapSpec := {
    sourceType := sourceType
    resultType := resultType
  }
  if specs.any (fun spec => psWasmArrayMapSpecEq spec candidate) then
    specs
  else
    specs ++ [candidate]

def psWasmInsertArrayFoldSpec
    (specs : List PsWasmArrayFoldSpec)
    (elementType accumulatorType : PsVerifiedIrType) :
    List PsWasmArrayFoldSpec :=
  let candidate : PsWasmArrayFoldSpec := {
    elementType := elementType
    accumulatorType := accumulatorType
  }
  if specs.any (fun spec => psWasmArrayFoldSpecEq spec candidate) then
    specs
  else
    specs ++ [candidate]

structure PsWasmArrayHigherOrderSpecs where
  maps : List PsWasmArrayMapSpec
  folds : List PsWasmArrayFoldSpec

def psWasmArrayHigherOrderSpecsEmpty :
    PsWasmArrayHigherOrderSpecs :=
  {
    maps := []
    folds := []
  }

def psWasmCollectArrayHigherOrderWithFuel :
    Nat ->
    PsVerifiedIrExpr ->
    PsWasmArrayHigherOrderSpecs ->
    PsWasmArrayHigherOrderSpecs
  | 0, _, specs => specs
  | fuel + 1, expression, specs =>
      let collect :=
        fun nested state =>
          psWasmCollectArrayHigherOrderWithFuel
            fuel
            nested
            state
      match expression with
      | .literal _ => specs
      | .var _ => specs
      | .intrinsic operation arguments =>
          let withOperation :=
            match operation with
            | .arrayMap sourceType resultType =>
                {
                  maps :=
                    psWasmInsertArrayMapSpec
                      specs.maps
                      sourceType
                      resultType
                  folds := specs.folds
                }
            | .arrayFoldl elementType accumulatorType =>
                {
                  maps := specs.maps
                  folds :=
                    psWasmInsertArrayFoldSpec
                      specs.folds
                      elementType
                      accumulatorType
                }
            | _ => specs
          arguments.foldl
            (fun state argument =>
              collect argument state)
            withOperation
      | .lambda _ _ body =>
          collect body specs
      | .call fn _ arguments =>
          let withFn := collect fn specs
          arguments.foldl
            (fun state argument =>
              collect argument state)
            withFn
      | .letE _ _ value body =>
          let withValue := collect value specs
          collect body withValue
      | .ifE condition thenBranch elseBranch =>
          let withCondition := collect condition specs
          let withThen := collect thenBranch withCondition
          collect elseBranch withThen
      | .record _ _ fields =>
          fields.foldl
            (fun state field =>
              collect field.2 state)
            specs
      | .projection _ _ target _ =>
          collect target specs
      | .constructor _ _ _ fields =>
          fields.foldl
            (fun state field =>
              collect field.2 state)
            specs
      | .matchE _ _ scrutinee alternatives =>
          let withScrutinee := collect scrutinee specs
          alternatives.foldl
            (fun state alternative =>
              collect alternative.2.2 state)
            withScrutinee

def psWasmCollectArrayHigherOrder
    (module : PsVerifiedIrModule) :
    PsWasmArrayHigherOrderSpecs :=
  module.declarations.foldl
    (fun state declaration =>
      psWasmCollectArrayHigherOrderWithFuel
        4096
        declaration.body
        state)
    psWasmArrayHigherOrderSpecsEmpty

def psWasmArrayNatZero : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.literal
    (PsVerifiedIrLiteral.natural 0)

def psWasmArrayNatOne : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.literal
    (PsVerifiedIrLiteral.natural 1)

def psWasmArrayNatAdd
    (left right : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.natAdd
    [left, right]

def psWasmArrayNatLt
    (left right : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.natLt
    [left, right]

def psWasmArraySizeExpr
    (elementType : PsVerifiedIrType)
    (array : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    (PsVerifiedIrIntrinsic.arraySize elementType)
    [array]

def psWasmArrayGetExpr
    (elementType : PsVerifiedIrType)
    (array index : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    (PsVerifiedIrIntrinsic.arrayGet elementType)
    [array, index]

def psWasmArrayPushExpr
    (elementType : PsVerifiedIrType)
    (array value : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    (PsVerifiedIrIntrinsic.arrayPush elementType)
    [array, value]

def psWasmArrayEmptyExpr
    (elementType : PsVerifiedIrType)
    (capacity : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    (PsVerifiedIrIntrinsic.arrayEmptyWithCapacity elementType)
    [capacity]

def psWasmArrayMapLoopDeclaration?
    (spec : PsWasmArrayMapSpec) :
    Option PsVerifiedIrDeclaration :=
  match
      psWasmArrayMapLoopName?
        spec.sourceType
        spec.resultType with
  | none => none
  | some loopName =>
      let sourceArrayType :=
        psWasmArraySemanticType spec.sourceType
      let resultArrayType :=
        psWasmArraySemanticType spec.resultType
      let functionType :=
        PsVerifiedIrType.function
          [spec.sourceType]
          spec.resultType
      some {
        name := loopName
        typeParameters := []
        parameters := [
          { name := "fn", type := functionType },
          { name := "array", type := sourceArrayType },
          { name := "index", type := psWasmNatRuntimeType },
          { name := "acc", type := resultArrayType }
        ]
        resultType := resultArrayType
        body :=
          PsVerifiedIrExpr.ifE
            (psWasmArrayNatLt
              (PsVerifiedIrExpr.var "index")
              (psWasmArraySizeExpr
                spec.sourceType
                (PsVerifiedIrExpr.var "array")))
            (PsVerifiedIrExpr.call
              (PsVerifiedIrExpr.var loopName)
              []
              [
                PsVerifiedIrExpr.var "fn",
                PsVerifiedIrExpr.var "array",
                psWasmArrayNatAdd
                  (PsVerifiedIrExpr.var "index")
                  psWasmArrayNatOne,
                psWasmArrayPushExpr
                  spec.resultType
                  (PsVerifiedIrExpr.var "acc")
                  (PsVerifiedIrExpr.call
                    (PsVerifiedIrExpr.var "fn")
                    []
                    [
                      psWasmArrayGetExpr
                        spec.sourceType
                        (PsVerifiedIrExpr.var "array")
                        (PsVerifiedIrExpr.var "index")
                    ])
              ])
            (PsVerifiedIrExpr.var "acc")
      }

def psWasmArrayMapRootDeclaration?
    (spec : PsWasmArrayMapSpec) :
    Option PsVerifiedIrDeclaration :=
  match
      psWasmArrayMapRootName?
        spec.sourceType
        spec.resultType,
      psWasmArrayMapLoopName?
        spec.sourceType
        spec.resultType with
  | some rootName, some loopName =>
      let sourceArrayType :=
        psWasmArraySemanticType spec.sourceType
      let resultArrayType :=
        psWasmArraySemanticType spec.resultType
      let functionType :=
        PsVerifiedIrType.function
          [spec.sourceType]
          spec.resultType
      some {
        name := rootName
        typeParameters := []
        parameters := [
          { name := "fn", type := functionType },
          { name := "array", type := sourceArrayType }
        ]
        resultType := resultArrayType
        body :=
          PsVerifiedIrExpr.call
            (PsVerifiedIrExpr.var loopName)
            []
            [
              PsVerifiedIrExpr.var "fn",
              PsVerifiedIrExpr.var "array",
              psWasmArrayNatZero,
              psWasmArrayEmptyExpr
                spec.resultType
                (psWasmArraySizeExpr
                  spec.sourceType
                  (PsVerifiedIrExpr.var "array"))
            ]
      }
  | _, _ => none

def psWasmArrayFoldDeclaration?
    (spec : PsWasmArrayFoldSpec) :
    Option PsVerifiedIrDeclaration :=
  match
      psWasmArrayFoldLoopName?
        spec.elementType
        spec.accumulatorType with
  | none => none
  | some loopName =>
      let arrayType :=
        psWasmArraySemanticType spec.elementType
      let functionType :=
        PsVerifiedIrType.function
          [spec.accumulatorType, spec.elementType]
          spec.accumulatorType
      some {
        name := loopName
        typeParameters := []
        parameters := [
          { name := "fn", type := functionType },
          { name := "acc", type := spec.accumulatorType },
          { name := "array", type := arrayType },
          { name := "index", type := psWasmNatRuntimeType },
          { name := "stop", type := psWasmNatRuntimeType }
        ]
        resultType := spec.accumulatorType
        body :=
          PsVerifiedIrExpr.ifE
            (psWasmArrayNatLt
              (PsVerifiedIrExpr.var "index")
              (PsVerifiedIrExpr.var "stop"))
            (PsVerifiedIrExpr.ifE
              (psWasmArrayNatLt
                (PsVerifiedIrExpr.var "index")
                (psWasmArraySizeExpr
                  spec.elementType
                  (PsVerifiedIrExpr.var "array")))
              (PsVerifiedIrExpr.call
                (PsVerifiedIrExpr.var loopName)
                []
                [
                  PsVerifiedIrExpr.var "fn",
                  PsVerifiedIrExpr.call
                    (PsVerifiedIrExpr.var "fn")
                    []
                    [
                      PsVerifiedIrExpr.var "acc",
                      psWasmArrayGetExpr
                        spec.elementType
                        (PsVerifiedIrExpr.var "array")
                        (PsVerifiedIrExpr.var "index")
                    ],
                  PsVerifiedIrExpr.var "array",
                  psWasmArrayNatAdd
                    (PsVerifiedIrExpr.var "index")
                    psWasmArrayNatOne,
                  PsVerifiedIrExpr.var "stop"
                ])
              (PsVerifiedIrExpr.var "acc"))
            (PsVerifiedIrExpr.var "acc")
      }

def psWasmArrayRuntimeDeclarationsFromMaps :
    List PsWasmArrayMapSpec ->
    List PsVerifiedIrDeclaration
  | [] => []
  | spec :: rest =>
      let tail :=
        psWasmArrayRuntimeDeclarationsFromMaps rest
      match
          psWasmArrayMapRootDeclaration? spec,
          psWasmArrayMapLoopDeclaration? spec with
      | some root, some loop =>
          root :: loop :: tail
      | _, _ => tail

def psWasmArrayRuntimeDeclarationsFromFolds :
    List PsWasmArrayFoldSpec ->
    List PsVerifiedIrDeclaration
  | [] => []
  | spec :: rest =>
      let tail :=
        psWasmArrayRuntimeDeclarationsFromFolds rest
      match psWasmArrayFoldDeclaration? spec with
      | none => tail
      | some declaration => declaration :: tail

def psWasmRewriteArrayHigherOrderExprWithFuel :
    Nat -> PsVerifiedIrExpr -> PsVerifiedIrExpr
  | 0, expression => expression
  | fuel + 1, expression =>
      let rewrite :=
        psWasmRewriteArrayHigherOrderExprWithFuel fuel
      match expression with
      | .literal literal =>
          PsVerifiedIrExpr.literal literal
      | .var name =>
          PsVerifiedIrExpr.var name
      | .intrinsic operation arguments =>
          let rewritten := arguments.map rewrite
          match operation with
          | .arrayMap sourceType resultType =>
              match
                  psWasmArrayMapRootName?
                    sourceType
                    resultType with
              | none =>
                  PsVerifiedIrExpr.intrinsic
                    operation
                    rewritten
              | some name =>
                  PsVerifiedIrExpr.call
                    (PsVerifiedIrExpr.var name)
                    []
                    rewritten
          | .arrayFoldl elementType accumulatorType =>
              match
                  psWasmArrayFoldLoopName?
                    elementType
                    accumulatorType with
              | none =>
                  PsVerifiedIrExpr.intrinsic
                    operation
                    rewritten
              | some name =>
                  PsVerifiedIrExpr.call
                    (PsVerifiedIrExpr.var name)
                    []
                    rewritten
          | _ =>
              PsVerifiedIrExpr.intrinsic
                operation
                rewritten
      | .lambda parameters resultType body =>
          PsVerifiedIrExpr.lambda
            parameters
            resultType
            (rewrite body)
      | .call fn typeArguments arguments =>
          PsVerifiedIrExpr.call
            (rewrite fn)
            typeArguments
            (arguments.map rewrite)
      | .letE name type value body =>
          PsVerifiedIrExpr.letE
            name
            type
            (rewrite value)
            (rewrite body)
      | .ifE condition thenBranch elseBranch =>
          PsVerifiedIrExpr.ifE
            (rewrite condition)
            (rewrite thenBranch)
            (rewrite elseBranch)
      | .record structureName typeArguments fields =>
          PsVerifiedIrExpr.record
            structureName
            typeArguments
            (fields.map
              (fun field =>
                (field.1, rewrite field.2)))
      | .projection structureName typeArguments target field =>
          PsVerifiedIrExpr.projection
            structureName
            typeArguments
            (rewrite target)
            field
      | .constructor inductiveName constructorName typeArguments fields =>
          PsVerifiedIrExpr.constructor
            inductiveName
            constructorName
            typeArguments
            (fields.map
              (fun field =>
                (field.1, rewrite field.2)))
      | .matchE inductiveName typeArguments scrutinee alternatives =>
          PsVerifiedIrExpr.matchE
            inductiveName
            typeArguments
            (rewrite scrutinee)
            (alternatives.map
              (fun alternative =>
                (
                  alternative.1,
                  alternative.2.1,
                  rewrite alternative.2.2
                )))

def psWasmRewriteArrayHigherOrderDeclaration
    (declaration : PsVerifiedIrDeclaration) :
    PsVerifiedIrDeclaration :=
  {
    name := declaration.name
    typeParameters := declaration.typeParameters
    parameters := declaration.parameters
    resultType := declaration.resultType
    body :=
      psWasmRewriteArrayHigherOrderExprWithFuel
        4096
        declaration.body
  }

def psWasmRewriteArrayHigherOrderDeclarations :
    List PsVerifiedIrDeclaration ->
    List PsVerifiedIrDeclaration
  | [] => []
  | declaration :: rest =>
      psWasmRewriteArrayHigherOrderDeclaration declaration ::
        psWasmRewriteArrayHigherOrderDeclarations rest

def psWasmAugmentArrayHigherOrderRuntime
    (module : PsVerifiedIrModule) : PsVerifiedIrModule :=
  let specs := psWasmCollectArrayHigherOrder module
  let helpers :=
    psWasmArrayRuntimeDeclarationsFromMaps specs.maps
      ++ psWasmArrayRuntimeDeclarationsFromFolds specs.folds
  {
    imports := module.imports
    structures := module.structures
    inductives := module.inductives
    declarations :=
      psWasmRewriteArrayHigherOrderDeclarations
        module.declarations
        ++ helpers
  }
