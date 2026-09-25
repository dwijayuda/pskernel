import Ps.BackendRust.Type

structure PsRustCoverage where
  features : List String
  namedTypes : List String

def psRustCoverageEmpty : PsRustCoverage :=
  {
    features := List.nil
    namedTypes := List.nil
  }

def psRustCoverageContains :
    List String -> String -> Bool
  | List.nil, _ =>
      false
  | List.cons value rest, target =>
      if psStringEq value target then
        true
      else
        psRustCoverageContains rest target

def psRustCoverageAddUnique
    (values : List String)
    (value : String) : List String :=
  if psRustCoverageContains values value then
    values
  else
    List.cons value values

def psRustCoverageAddFeature
    (coverage : PsRustCoverage)
    (feature : String) : PsRustCoverage :=
  {
    features :=
      psRustCoverageAddUnique coverage.features feature
    namedTypes := coverage.namedTypes
  }

def psRustCoverageAddNamedType
    (coverage : PsRustCoverage)
    (name : String) : PsRustCoverage :=
  {
    features :=
      psRustCoverageAddUnique
        coverage.features
        "type:named"
    namedTypes :=
      psRustCoverageAddUnique coverage.namedTypes name
  }

def psRustCoveragePrimitiveName
    (primitive : PsVerifiedIrPrimitiveType) : String :=
  match primitive with
  | PsVerifiedIrPrimitiveType.nat => "Nat"
  | PsVerifiedIrPrimitiveType.int => "Int"
  | PsVerifiedIrPrimitiveType.uint8 => "UInt8"
  | PsVerifiedIrPrimitiveType.uint16 => "UInt16"
  | PsVerifiedIrPrimitiveType.uint32 => "UInt32"
  | PsVerifiedIrPrimitiveType.uint64 => "UInt64"
  | PsVerifiedIrPrimitiveType.usize => "USize"
  | PsVerifiedIrPrimitiveType.int8 => "Int8"
  | PsVerifiedIrPrimitiveType.int16 => "Int16"
  | PsVerifiedIrPrimitiveType.int32 => "Int32"
  | PsVerifiedIrPrimitiveType.int64 => "Int64"
  | PsVerifiedIrPrimitiveType.isize => "ISize"
  | PsVerifiedIrPrimitiveType.float => "Float"
  | PsVerifiedIrPrimitiveType.float32 => "Float32"
  | PsVerifiedIrPrimitiveType.bool => "Bool"
  | PsVerifiedIrPrimitiveType.char => "Char"
  | PsVerifiedIrPrimitiveType.string => "String"
  | PsVerifiedIrPrimitiveType.unit => "Unit"

def psRustCoverageIntrinsicName
    (intrinsic : PsVerifiedIrIntrinsic) : String :=
  match intrinsic with
  | PsVerifiedIrIntrinsic.natAdd => "Nat.add"
  | PsVerifiedIrIntrinsic.natSub => "Nat.sub"
  | PsVerifiedIrIntrinsic.natMul => "Nat.mul"
  | PsVerifiedIrIntrinsic.natDiv => "Nat.div"
  | PsVerifiedIrIntrinsic.natMod => "Nat.mod"
  | PsVerifiedIrIntrinsic.natEq => "Nat.eq"
  | PsVerifiedIrIntrinsic.natNe => "Nat.ne"
  | PsVerifiedIrIntrinsic.natLe => "Nat.le"
  | PsVerifiedIrIntrinsic.natLt => "Nat.lt"
  | PsVerifiedIrIntrinsic.intOfNat => "Int.ofNat"
  | PsVerifiedIrIntrinsic.intNegSucc => "Int.negSucc"
  | PsVerifiedIrIntrinsic.intNeg => "Int.neg"
  | PsVerifiedIrIntrinsic.intAdd => "Int.add"
  | PsVerifiedIrIntrinsic.intSub => "Int.sub"
  | PsVerifiedIrIntrinsic.intMul => "Int.mul"
  | PsVerifiedIrIntrinsic.intEq => "Int.eq"
  | PsVerifiedIrIntrinsic.intLe => "Int.le"
  | PsVerifiedIrIntrinsic.intLt => "Int.lt"
  | PsVerifiedIrIntrinsic.boolNot => "Bool.not"
  | PsVerifiedIrIntrinsic.boolAnd => "Bool.and"
  | PsVerifiedIrIntrinsic.boolOr => "Bool.or"
  | PsVerifiedIrIntrinsic.boolEq => "Bool.eq"
  | PsVerifiedIrIntrinsic.boolNe => "Bool.ne"
  | PsVerifiedIrIntrinsic.charOfNat => "Char.ofNat"
  | PsVerifiedIrIntrinsic.charToNat => "Char.toNat"
  | PsVerifiedIrIntrinsic.stringPush => "String.push"
  | PsVerifiedIrIntrinsic.stringSingleton => "String.singleton"
  | PsVerifiedIrIntrinsic.stringLength => "String.length"
  | PsVerifiedIrIntrinsic.stringAppend => "String.append"
  | PsVerifiedIrIntrinsic.stringUtf8ByteSize => "String.utf8ByteSize"
  | PsVerifiedIrIntrinsic.stringNext => "String.next"
  | PsVerifiedIrIntrinsic.stringGet => "String.get"
  | PsVerifiedIrIntrinsic.stringAtEnd => "String.atEnd"
  | PsVerifiedIrIntrinsic.stringExtract => "String.extract"
  | PsVerifiedIrIntrinsic.stringEq => "String.eq"
  | PsVerifiedIrIntrinsic.arrayEmptyWithCapacity => "Array.emptyWithCapacity"
  | PsVerifiedIrIntrinsic.arraySize => "Array.size"
  | PsVerifiedIrIntrinsic.arrayPush => "Array.push"
  | PsVerifiedIrIntrinsic.arrayGet => "Array.get"
  | PsVerifiedIrIntrinsic.arrayGetD => "Array.getD"
  | PsVerifiedIrIntrinsic.arraySet => "Array.set"
  | PsVerifiedIrIntrinsic.arraySetIfInBounds => "Array.setIfInBounds"
  | PsVerifiedIrIntrinsic.arrayMap => "Array.map"
  | PsVerifiedIrIntrinsic.arrayFoldl => "Array.foldl"

def psRustCoverageFoldTypeListWith
    (visit :
      PsRustCoverage ->
      PsVerifiedIrType ->
      PsRustCoverage) :
    List PsVerifiedIrType ->
    PsRustCoverage ->
    PsRustCoverage
  | List.nil, coverage =>
      coverage
  | List.cons type rest, coverage =>
      psRustCoverageFoldTypeListWith
        visit
        rest
        (visit coverage type)

def psRustCoverageTypeWithFuel :
    Nat ->
    PsRustCoverage ->
    PsVerifiedIrType ->
    PsRustCoverage
  | 0, coverage, _ =>
      psRustCoverageAddFeature
        coverage
        "coverage:fuelExhausted"
  | fuel + 1, coverage, type =>
      match type with
      | PsVerifiedIrType.unknown =>
          psRustCoverageAddFeature
            coverage
            "type:unknown"
      | PsVerifiedIrType.typeParameter _ =>
          psRustCoverageAddFeature
            coverage
            "type:typeParameter"
      | PsVerifiedIrType.primitive primitive =>
          psRustCoverageAddFeature
            coverage
            (psRustConcat2
              "type:primitive:"
              (psRustCoveragePrimitiveName primitive))
      | PsVerifiedIrType.function parameters result =>
          let withFunction :=
            psRustCoverageAddFeature
              coverage
              "type:function";
          let visitNested :=
            fun
              (current : PsRustCoverage)
              (nested : PsVerifiedIrType) =>
                psRustCoverageTypeWithFuel
                  fuel
                  current
                  nested;
          let withParameters :=
            psRustCoverageFoldTypeListWith
              visitNested
              parameters
              withFunction;
          psRustCoverageTypeWithFuel
            fuel
            withParameters
            result
      | PsVerifiedIrType.named name arguments =>
          let withName :=
            psRustCoverageAddNamedType coverage name;
          let visitNested :=
            fun
              (current : PsRustCoverage)
              (nested : PsVerifiedIrType) =>
                psRustCoverageTypeWithFuel
                  fuel
                  current
                  nested;
          psRustCoverageFoldTypeListWith
            visitNested
            arguments
            withName

def psRustCoverageType
    (coverage : PsRustCoverage)
    (type : PsVerifiedIrType) : PsRustCoverage :=
  psRustCoverageTypeWithFuel 4096 coverage type

def psRustCoverageParameterList :
    PsRustCoverage ->
    List PsVerifiedIrParameter ->
    PsRustCoverage
  | coverage, List.nil =>
      coverage
  | coverage, List.cons parameter rest =>
      psRustCoverageParameterList
        (psRustCoverageType coverage parameter.type)
        rest

def psRustCoverageFoldExprListWith
    (visit :
      PsRustCoverage ->
      PsVerifiedIrExpr ->
      PsRustCoverage) :
    List PsVerifiedIrExpr ->
    PsRustCoverage ->
    PsRustCoverage
  | List.nil, coverage =>
      coverage
  | List.cons expr rest, coverage =>
      psRustCoverageFoldExprListWith
        visit
        rest
        (visit coverage expr)

def psRustCoverageFoldFieldListWith
    (visit :
      PsRustCoverage ->
      PsVerifiedIrExpr ->
      PsRustCoverage) :
    List (Prod String PsVerifiedIrExpr) ->
    PsRustCoverage ->
    PsRustCoverage
  | List.nil, coverage =>
      coverage
  | List.cons field rest, coverage =>
      psRustCoverageFoldFieldListWith
        visit
        rest
        (visit coverage (Prod.snd field))

def psRustCoverageFoldAlternativesWith
    (visit :
      PsRustCoverage ->
      PsVerifiedIrExpr ->
      PsRustCoverage) :
    List
      (Prod String
        (Prod
          (List PsVerifiedIrMatchBinding)
          PsVerifiedIrExpr)) ->
    PsRustCoverage ->
    PsRustCoverage
  | List.nil, coverage =>
      coverage
  | List.cons alternative rest, coverage =>
      let payload := Prod.snd alternative;
      let body := Prod.snd payload;
      psRustCoverageFoldAlternativesWith
        visit
        rest
        (visit coverage body)

def psRustCoverageExprWithFuel :
    Nat ->
    PsRustCoverage ->
    PsVerifiedIrExpr ->
    PsRustCoverage
  | 0, coverage, _ =>
      psRustCoverageAddFeature
        coverage
        "coverage:fuelExhausted"
  | fuel + 1, coverage, expr =>
      let visitNested :=
        fun
          (current : PsRustCoverage)
          (nested : PsVerifiedIrExpr) =>
            psRustCoverageExprWithFuel
              fuel
              current
              nested;
      match expr with
      | PsVerifiedIrExpr.literal _ =>
          psRustCoverageAddFeature
            coverage
            "expr:literal"
      | PsVerifiedIrExpr.var _ =>
          psRustCoverageAddFeature
            coverage
            "expr:var"
      | PsVerifiedIrExpr.intrinsic intrinsic arguments =>
          let withIntrinsic :=
            psRustCoverageAddFeature
              (psRustCoverageAddFeature
                coverage
                "expr:intrinsic")
              (psRustConcat2
                "intrinsic:"
                (psRustCoverageIntrinsicName intrinsic));
          psRustCoverageFoldExprListWith
            visitNested
            arguments
            withIntrinsic
      | PsVerifiedIrExpr.lambda parameters body =>
          let withLambda :=
            psRustCoverageAddFeature
              coverage
              "expr:lambda";
          let withParameterTypes :=
            psRustCoverageParameterList
              withLambda
              parameters;
          psRustCoverageExprWithFuel
            fuel
            withParameterTypes
            body
      | PsVerifiedIrExpr.call fn typeArguments arguments =>
          let withCall :=
            psRustCoverageAddFeature
              coverage
              "expr:call";
          let withFn :=
            psRustCoverageExprWithFuel
              fuel
              withCall
              fn;
          let withTypes :=
            psRustCoverageFoldTypeListWith
              psRustCoverageType
              typeArguments
              withFn;
          psRustCoverageFoldExprListWith
            visitNested
            arguments
            withTypes
      | PsVerifiedIrExpr.letE _ value body =>
          let withLet :=
            psRustCoverageAddFeature
              coverage
              "expr:let";
          let withValue :=
            psRustCoverageExprWithFuel
              fuel
              withLet
              value;
          psRustCoverageExprWithFuel
            fuel
            withValue
            body
      | PsVerifiedIrExpr.ifE condition thenBranch elseBranch =>
          let withIf :=
            psRustCoverageAddFeature
              coverage
              "expr:if";
          let withCondition :=
            psRustCoverageExprWithFuel
              fuel
              withIf
              condition;
          let withThen :=
            psRustCoverageExprWithFuel
              fuel
              withCondition
              thenBranch;
          psRustCoverageExprWithFuel
            fuel
            withThen
            elseBranch
      | PsVerifiedIrExpr.record _ fields =>
          psRustCoverageFoldFieldListWith
            visitNested
            fields
            (psRustCoverageAddFeature
              coverage
              "expr:record")
      | PsVerifiedIrExpr.projection target _ =>
          psRustCoverageExprWithFuel
            fuel
            (psRustCoverageAddFeature
              coverage
              "expr:projection")
            target
      | PsVerifiedIrExpr.constructor _ _ typeArguments fields =>
          let withConstructor :=
            psRustCoverageAddFeature
              coverage
              "expr:constructor";
          let withTypes :=
            psRustCoverageFoldTypeListWith
              psRustCoverageType
              typeArguments
              withConstructor;
          psRustCoverageFoldFieldListWith
            visitNested
            fields
            withTypes
      | PsVerifiedIrExpr.matchE _ scrutinee alternatives =>
          let withMatch :=
            psRustCoverageAddFeature
              coverage
              "expr:match";
          let withScrutinee :=
            psRustCoverageExprWithFuel
              fuel
              withMatch
              scrutinee;
          psRustCoverageFoldAlternativesWith
            visitNested
            alternatives
            withScrutinee

def psRustCoverageExpr
    (coverage : PsRustCoverage)
    (expr : PsVerifiedIrExpr) : PsRustCoverage :=
  psRustCoverageExprWithFuel 4096 coverage expr

def psRustCoverageStructureFieldList :
    PsRustCoverage ->
    List PsVerifiedIrStructureField ->
    PsRustCoverage
  | coverage, List.nil =>
      coverage
  | coverage, List.cons field rest =>
      psRustCoverageStructureFieldList
        (psRustCoverageType coverage field.type)
        rest

def psRustCoverageConstructorFieldList :
    PsRustCoverage ->
    List PsVerifiedIrConstructorField ->
    PsRustCoverage
  | coverage, List.nil =>
      coverage
  | coverage, List.cons field rest =>
      psRustCoverageConstructorFieldList
        (psRustCoverageType coverage field.type)
        rest

def psRustCoverageConstructorList :
    PsRustCoverage ->
    List PsVerifiedIrConstructor ->
    PsRustCoverage
  | coverage, List.nil =>
      coverage
  | coverage, List.cons constructorInfo rest =>
      psRustCoverageConstructorList
        (psRustCoverageConstructorFieldList
          coverage
          constructorInfo.fields)
        rest

def psRustCoverageStructureList :
    PsRustCoverage ->
    List PsVerifiedIrStructure ->
    PsRustCoverage
  | coverage, List.nil =>
      coverage
  | coverage, List.cons structureInfo rest =>
      psRustCoverageStructureList
        (psRustCoverageStructureFieldList
          (psRustCoverageAddFeature
            coverage
            "module:structure")
          structureInfo.fields)
        rest

def psRustCoverageInductiveList :
    PsRustCoverage ->
    List PsVerifiedIrInductive ->
    PsRustCoverage
  | coverage, List.nil =>
      coverage
  | coverage, List.cons inductiveInfo rest =>
      psRustCoverageInductiveList
        (psRustCoverageConstructorList
          (psRustCoverageAddFeature
            coverage
            "module:inductive")
          inductiveInfo.constructors)
        rest

def psRustCoverageDeclarationList :
    PsRustCoverage ->
    List PsVerifiedIrDeclaration ->
    PsRustCoverage
  | coverage, List.nil =>
      coverage
  | coverage, List.cons declaration rest =>
      let withDeclaration :=
        psRustCoverageAddFeature
          coverage
          "module:declaration";
      let withParameters :=
        psRustCoverageParameterList
          withDeclaration
          declaration.parameters;
      let withResult :=
        psRustCoverageType
          withParameters
          declaration.resultType;
      psRustCoverageDeclarationList
        (psRustCoverageExpr
          withResult
          declaration.body)
        rest

def psRustCoverageImportList :
    PsRustCoverage ->
    List PsVerifiedIrExternalImport ->
    PsRustCoverage
  | coverage, List.nil =>
      coverage
  | coverage, List.cons item rest =>
      psRustCoverageImportList
        (psRustCoverageType
          (psRustCoverageAddFeature
            coverage
            "module:externalImport")
          item.type)
        rest

def psRustCoverageModule
    (module : PsVerifiedIrModule) : PsRustCoverage :=
  let withImports :=
    psRustCoverageImportList
      psRustCoverageEmpty
      module.imports;
  let withStructures :=
    psRustCoverageStructureList
      withImports
      module.structures;
  let withInductives :=
    psRustCoverageInductiveList
      withStructures
      module.inductives;
  psRustCoverageDeclarationList
    withInductives
    module.declarations

def psRustCoverageReverseAcc :
    List String -> List String -> List String
  | List.nil, output =>
      output
  | List.cons value rest, output =>
      psRustCoverageReverseAcc
        rest
        (List.cons value output)

def psRustCoverageReverse
    (values : List String) : List String :=
  psRustCoverageReverseAcc values List.nil

def psRustCoverageLength : List String -> Nat
  | List.nil =>
      0
  | List.cons _ rest =>
      Nat.succ (psRustCoverageLength rest)

def psRustCoverageLines
    (linePrefix : String)
    (values : List String) : List String :=
  match values with
  | List.nil =>
      List.nil
  | List.cons value rest =>
      List.cons
        (psRustConcat2 linePrefix value)
        (psRustCoverageLines linePrefix rest)

def psRustCoverageReport
    (coverage : PsRustCoverage) : String :=
  let featureLines :=
    psRustCoverageLines
      "PSC1_RUST_COVERAGE_FEATURE: "
      psRustCoverageReverse coverage.features;
  let namedTypeLines :=
    psRustCoverageLines
      "PSC1_RUST_COVERAGE_NAMED_TYPE: "
      psRustCoverageReverse coverage.namedTypes;
  psRustConcat2
    (psRustJoin
      "\n"
      (List.append
        (List.cons
          (psRustConcat2
            "PSC1_RUST_COVERAGE_FEATURE_COUNT: "
            (toString psRustCoverageLength coverage.features))
          featureLines)
        (List.cons
          (psRustConcat2
            "PSC1_RUST_COVERAGE_NAMED_TYPE_COUNT: "
            (toString psRustCoverageLength coverage.namedTypes))
          namedTypeLines)))
    "\n"
