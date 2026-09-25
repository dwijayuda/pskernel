import Ps.BackendRust.Type
import Ps.BackendRust.Module

structure PsRustCoverage where
  features : List String
  namedTypes : List String
  unsupported : List String

def psRustCoverageEmpty : PsRustCoverage :=
  {
    features := List.nil
    namedTypes := List.nil
    unsupported := List.nil
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
    unsupported := coverage.unsupported
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
    unsupported := coverage.unsupported
  }

def psRustCoverageAddUnsupported
    (coverage : PsRustCoverage)
    (reason : String) : PsRustCoverage :=
  {
    features := coverage.features
    namedTypes := coverage.namedTypes
    unsupported :=
      psRustCoverageAddUnique coverage.unsupported reason
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
  | PsVerifiedIrIntrinsic.machineIntBinary _ _ => "MachineInt.binary"
  | PsVerifiedIrIntrinsic.machineIntCompare _ _ => "MachineInt.compare"
  | PsVerifiedIrIntrinsic.floatBinary _ _ => "Float.binary"
  | PsVerifiedIrIntrinsic.floatCompare _ _ => "Float.compare"
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

def psRustCoverageIntrinsicArity
    (intrinsic : PsVerifiedIrIntrinsic) : Nat :=
  match intrinsic with
  | PsVerifiedIrIntrinsic.machineIntBinary _ _ => 2
  | PsVerifiedIrIntrinsic.machineIntCompare _ _ => 2
  | PsVerifiedIrIntrinsic.floatBinary _ _ => 2
  | PsVerifiedIrIntrinsic.floatCompare _ _ => 2
  | PsVerifiedIrIntrinsic.natAdd => 2
  | PsVerifiedIrIntrinsic.natSub => 2
  | PsVerifiedIrIntrinsic.natMul => 2
  | PsVerifiedIrIntrinsic.natDiv => 2
  | PsVerifiedIrIntrinsic.natMod => 2
  | PsVerifiedIrIntrinsic.natEq => 2
  | PsVerifiedIrIntrinsic.natNe => 2
  | PsVerifiedIrIntrinsic.natLe => 2
  | PsVerifiedIrIntrinsic.natLt => 2
  | PsVerifiedIrIntrinsic.intOfNat => 1
  | PsVerifiedIrIntrinsic.intNegSucc => 1
  | PsVerifiedIrIntrinsic.intNeg => 1
  | PsVerifiedIrIntrinsic.intAdd => 2
  | PsVerifiedIrIntrinsic.intSub => 2
  | PsVerifiedIrIntrinsic.intMul => 2
  | PsVerifiedIrIntrinsic.intEq => 2
  | PsVerifiedIrIntrinsic.intLe => 2
  | PsVerifiedIrIntrinsic.intLt => 2
  | PsVerifiedIrIntrinsic.boolNot => 1
  | PsVerifiedIrIntrinsic.boolAnd => 2
  | PsVerifiedIrIntrinsic.boolOr => 2
  | PsVerifiedIrIntrinsic.boolEq => 2
  | PsVerifiedIrIntrinsic.boolNe => 2
  | PsVerifiedIrIntrinsic.charOfNat => 1
  | PsVerifiedIrIntrinsic.charToNat => 1
  | PsVerifiedIrIntrinsic.stringPush => 2
  | PsVerifiedIrIntrinsic.stringSingleton => 1
  | PsVerifiedIrIntrinsic.stringLength => 1
  | PsVerifiedIrIntrinsic.stringAppend => 2
  | PsVerifiedIrIntrinsic.stringUtf8ByteSize => 1
  | PsVerifiedIrIntrinsic.stringNext => 2
  | PsVerifiedIrIntrinsic.stringGet => 2
  | PsVerifiedIrIntrinsic.stringAtEnd => 2
  | PsVerifiedIrIntrinsic.stringExtract => 3
  | PsVerifiedIrIntrinsic.stringEq => 2
  | PsVerifiedIrIntrinsic.arrayEmptyWithCapacity => 1
  | PsVerifiedIrIntrinsic.arraySize => 1
  | PsVerifiedIrIntrinsic.arrayPush => 2
  | PsVerifiedIrIntrinsic.arrayGet => 2
  | PsVerifiedIrIntrinsic.arrayGetD => 3
  | PsVerifiedIrIntrinsic.arraySet => 3
  | PsVerifiedIrIntrinsic.arraySetIfInBounds => 3
  | PsVerifiedIrIntrinsic.arrayMap => 2
  | PsVerifiedIrIntrinsic.arrayFoldl => 5

def psRustCoverageExprListLength :
    List PsVerifiedIrExpr -> Nat
  | List.nil =>
      0
  | List.cons _ rest =>
      Nat.succ (psRustCoverageExprListLength rest)

def psRustCoverageIntrinsicArityMatches
    (intrinsic : PsVerifiedIrIntrinsic)
    (arguments : List PsVerifiedIrExpr) : Bool :=
  Nat.beq
    (psRustCoverageIntrinsicArity intrinsic)
    (psRustCoverageExprListLength arguments)

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
      psRustCoverageAddUnsupported
        (psRustCoverageAddFeature
          coverage
          "coverage:fuelExhausted")
        "coverage:fuelExhausted"
  | fuel + 1, coverage, type =>
      match type with
      | PsVerifiedIrType.unknown =>
          psRustCoverageAddUnsupported
            (psRustCoverageAddFeature
              coverage
              "type:unknown")
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
      let withParameter :=
        if psRustTypeContainsFunction parameter.type then
          if psRustFunctionTypeIsFirstOrder parameter.type then
            coverage
          else
            psRustCoverageAddUnsupported
              (psRustCoverageAddFeature
                coverage
                "declaration:nestedFunctionParameter")
              "declaration:nestedFunctionParameter"
        else
          coverage;
      psRustCoverageParameterList
        (psRustCoverageType withParameter parameter.type)
        rest

def psRustCoverageLambdaParameterList :
    PsRustCoverage ->
    List PsVerifiedIrParameter ->
    PsRustCoverage
  | coverage, List.nil =>
      coverage
  | coverage, List.cons parameter rest =>
      let withParameter :=
        if psRustTypeContainsFunction parameter.type then
          psRustCoverageAddUnsupported
            (psRustCoverageAddFeature
              coverage
              "expr:lambdaFunctionParameter")
            "expr:lambdaFunctionParameter"
        else
          coverage;
      psRustCoverageLambdaParameterList
        (psRustCoverageType withParameter parameter.type)
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
      psRustCoverageAddUnsupported
        (psRustCoverageAddFeature
          coverage
          "coverage:fuelExhausted")
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
          let withIntrinsicFeature :=
            psRustCoverageAddFeature
              (psRustCoverageAddFeature
                coverage
                "expr:intrinsic")
              (psRustConcat2
                "intrinsic:"
                (psRustCoverageIntrinsicName intrinsic));
          let withIntrinsic :=
            if psRustCoverageIntrinsicArityMatches intrinsic arguments then
              withIntrinsicFeature
            else
              psRustCoverageAddUnsupported
                (psRustCoverageAddFeature
                  withIntrinsicFeature
                  "intrinsic:arity")
                "intrinsic:arity";
          psRustCoverageFoldExprListWith
            visitNested
            arguments
            withIntrinsic
      | PsVerifiedIrExpr.lambda parameters resultType body =>
          let withLambda :=
            psRustCoverageAddFeature
              coverage
              "expr:lambda";
          let withParameterTypes :=
            psRustCoverageLambdaParameterList
              withLambda
              parameters;
          let withResultSupport :=
            if psRustTypeContainsFunction resultType then
              psRustCoverageAddUnsupported
                (psRustCoverageAddFeature
                  withParameterTypes
                  "expr:lambdaFunctionResult")
                "expr:lambdaFunctionResult"
            else
              withParameterTypes;
          let withResultType :=
            psRustCoverageType
              withResultSupport
              resultType;
          psRustCoverageExprWithFuel
            fuel
            withResultType
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
      | PsVerifiedIrExpr.letE _ type value body =>
          let withLet :=
            psRustCoverageAddFeature
              coverage
              "expr:let";
          let withType :=
            psRustCoverageType
              withLet
              type;
          let withValue :=
            psRustCoverageExprWithFuel
              fuel
              withType
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
      | PsVerifiedIrExpr.projection _ target _ =>
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
      let withStorage :=
        if psRustTypeContainsFunction field.type then
          psRustCoverageAddUnsupported
            (psRustCoverageAddFeature
              coverage
              "module:functionStorage")
            "module:functionStorage"
        else
          coverage;
      psRustCoverageStructureFieldList
        (psRustCoverageType withStorage field.type)
        rest

def psRustCoverageConstructorFieldList :
    PsRustCoverage ->
    List PsVerifiedIrConstructorField ->
    PsRustCoverage
  | coverage, List.nil =>
      coverage
  | coverage, List.cons field rest =>
      let withStorage :=
        if psRustTypeContainsFunction field.type then
          psRustCoverageAddUnsupported
            (psRustCoverageAddFeature
              coverage
              "module:functionStorage")
            "module:functionStorage"
        else
          coverage;
      psRustCoverageConstructorFieldList
        (psRustCoverageType withStorage field.type)
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

def psRustCoverageDeclarationIsGenericValue
    (declaration : PsVerifiedIrDeclaration) : Bool :=
  match declaration.parameters with
  | List.nil =>
      match declaration.typeParameters with
      | List.nil => false
      | List.cons _ _ => true
  | List.cons _ _ =>
      false

def psRustCoverageDeclarationList :
    PsRustCoverage ->
    List PsVerifiedIrDeclaration ->
    PsRustCoverage
  | coverage, List.nil =>
      coverage
  | coverage, List.cons declaration rest =>
      let withDeclarationFeature :=
        psRustCoverageAddFeature
          coverage
          "module:declaration";
      let withDeclaration :=
        if psRustCoverageDeclarationIsGenericValue declaration then
          psRustCoverageAddUnsupported
            (psRustCoverageAddFeature
              withDeclarationFeature
              "declaration:genericValue")
            "declaration:genericValue"
        else
          withDeclarationFeature;
      let withResultSupport :=
        if psRustTypeContainsFunction declaration.resultType then
          psRustCoverageAddUnsupported
            (psRustCoverageAddFeature
              withDeclaration
              "declaration:functionResult")
            "declaration:functionResult"
        else
          withDeclaration;
      let withParameters :=
        psRustCoverageParameterList
          withResultSupport
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
      let withImport :=
        psRustCoverageAddUnsupported
          (psRustCoverageAddFeature
            coverage
            "module:externalImport")
          "module:externalImport";
      psRustCoverageImportList
        (psRustCoverageType
          withImport
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
  let withDeclarations :=
    psRustCoverageDeclarationList
      withInductives
      module.declarations;
  match psRustValidateModuleNames module with
  | Except.ok _ =>
      withDeclarations
  | Except.error (PsRustEmitError.unknownStructure _) =>
      psRustCoverageAddUnsupported
        (psRustCoverageAddFeature
          withDeclarations
          "module:unknownStructure")
        "module:unknownStructure"
  | Except.error (PsRustEmitError.unknownInductive _) =>
      psRustCoverageAddUnsupported
        (psRustCoverageAddFeature
          withDeclarations
          "module:unknownInductive")
        "module:unknownInductive"
  | Except.error PsRustEmitError.fuelExhausted =>
      psRustCoverageAddUnsupported
        (psRustCoverageAddFeature
          withDeclarations
          "coverage:nameValidationFuelExhausted")
        "coverage:nameValidationFuelExhausted"
  | Except.error _ =>
      psRustCoverageAddUnsupported
        (psRustCoverageAddFeature
          withDeclarations
          "module:nameValidation")
        "module:nameValidation"

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
      (psRustCoverageReverse coverage.features);
  let namedTypeLines :=
    psRustCoverageLines
      "PSC1_RUST_COVERAGE_NAMED_TYPE: "
      (psRustCoverageReverse coverage.namedTypes);
  let unsupportedLines :=
    psRustCoverageLines
      "PSC1_RUST_COVERAGE_UNSUPPORTED: "
      (psRustCoverageReverse coverage.unsupported);
  let featureBlock :=
    List.cons
      (psRustConcat2
        "PSC1_RUST_COVERAGE_FEATURE_COUNT: "
        (toString (psRustCoverageLength coverage.features)))
      featureLines;
  let namedTypeBlock :=
    List.cons
      (psRustConcat2
        "PSC1_RUST_COVERAGE_NAMED_TYPE_COUNT: "
        (toString (psRustCoverageLength coverage.namedTypes)))
      namedTypeLines;
  let unsupportedBlock :=
    List.cons
      (psRustConcat2
        "PSC1_RUST_COVERAGE_UNSUPPORTED_COUNT: "
        (toString (psRustCoverageLength coverage.unsupported)))
      unsupportedLines;
  psRustConcat2
    (psRustJoin
      "\n"
      (List.append
        (List.append featureBlock namedTypeBlock)
        unsupportedBlock))
    "\n"
