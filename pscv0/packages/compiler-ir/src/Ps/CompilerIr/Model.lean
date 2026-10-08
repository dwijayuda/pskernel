import Ps.Foundation.Name

inductive PsVerifiedIrPrimitiveType where
  | nat
  | int
  | uint8
  | uint16
  | uint32
  | uint64
  | usize
  | int8
  | int16
  | int32
  | int64
  | isize
  | float
  | float32
  | bool
  | char
  | string
  | unit

inductive PsVerifiedIrType where
  | unknown
  | typeParameter (name : String)
  | primitive (name : PsVerifiedIrPrimitiveType)
  | function
      (parameters : List PsVerifiedIrType)
      (result : PsVerifiedIrType)
  | named
      (name : String)
      (arguments : List PsVerifiedIrType)

inductive PsVerifiedIrMachineIntegerType where
  | uint8
  | uint16
  | uint32
  | uint64
  | usize
  | int8
  | int16
  | int32
  | int64
  | isize

inductive PsVerifiedIrIntegerBinaryOp where
  | add
  | sub
  | mul
  | bitAnd
  | bitOr
  | bitXor

inductive PsVerifiedIrIntegerCompareOp where
  | eq
  | ne
  | lt
  | le
  | gt
  | ge

inductive PsVerifiedIrFloatingType where
  | float
  | float32

inductive PsVerifiedIrFloatBinaryOp where
  | add
  | sub
  | mul
  | div

inductive PsVerifiedIrFloatCompareOp where
  | eq
  | ne
  | lt
  | le
  | gt
  | ge

inductive PsVerifiedIrLiteral where
  | natural (value : Nat)
  | integer (value : Int)
  | machineInteger
      (type : PsVerifiedIrMachineIntegerType)
      (value : Int)
  | string (value : String)
  | bool (value : Bool)
  | unit

inductive PsVerifiedIrIntrinsic where
  | machineIntBinary
      (type : PsVerifiedIrMachineIntegerType)
      (operation : PsVerifiedIrIntegerBinaryOp)
  | machineIntCompare
      (type : PsVerifiedIrMachineIntegerType)
      (operation : PsVerifiedIrIntegerCompareOp)
  | uint8OfNat
  | floatBinary
      (type : PsVerifiedIrFloatingType)
      (operation : PsVerifiedIrFloatBinaryOp)
  | floatCompare
      (type : PsVerifiedIrFloatingType)
      (operation : PsVerifiedIrFloatCompareOp)
  | natAdd
  | natSub
  | natMul
  | natDiv
  | natMod
  | natEq
  | natNe
  | natLe
  | natLt
  | intOfNat
  | intRepr
  | intNegSucc
  | intNeg
  | intAdd
  | intSub
  | intMul
  | intEq
  | intLe
  | intLt
  | boolNot
  | boolAnd
  | boolOr
  | boolEq
  | boolNe
  | charOfNat
  | charToNat
  | stringPush
  | stringSingleton
  | stringLength
  | stringAppend
  | stringUtf8ByteSize
  | stringNext
  | stringGet
  | stringAtEnd
  | stringExtract
  | stringEq
  | arrayEmptyWithCapacity
  | arraySize
  | arrayPush
  | arrayGet
  | arrayGetD
  | arraySet
  | arraySetIfInBounds
  | arrayMap
  | arrayFoldl

structure PsVerifiedIrParameter where
  name : String
  type : PsVerifiedIrType

structure PsVerifiedIrMatchBinding where
  field : String
  name : String
  type : PsVerifiedIrType

inductive PsVerifiedIrExpr where
  | literal (value : PsVerifiedIrLiteral)
  | var (name : String)
  | intrinsic
      (operation : PsVerifiedIrIntrinsic)
      (typeArguments : List PsVerifiedIrType)
      (arguments : List PsVerifiedIrExpr)
  | lambda
      (parameters : List PsVerifiedIrParameter)
      (resultType : PsVerifiedIrType)
      (body : PsVerifiedIrExpr)
  | call
      (fn : PsVerifiedIrExpr)
      (typeArguments : List PsVerifiedIrType)
      (arguments : List PsVerifiedIrExpr)
  | letE
      (name : String)
      (type : PsVerifiedIrType)
      (value : PsVerifiedIrExpr)
      (body : PsVerifiedIrExpr)
  | ifE
      (condition : PsVerifiedIrExpr)
      (thenBranch : PsVerifiedIrExpr)
      (elseBranch : PsVerifiedIrExpr)
  | record
      (structureName : String)
      (typeArguments : List PsVerifiedIrType)
      (fields : List (String × PsVerifiedIrExpr))
  | projection
      (structureName : String)
      (typeArguments : List PsVerifiedIrType)
      (target : PsVerifiedIrExpr)
      (field : String)
  | constructor
      (inductiveName : String)
      (constructorName : String)
      (typeArguments : List PsVerifiedIrType)
      (fields : List (String × PsVerifiedIrExpr))
  | matchE
      (inductiveName : String)
      (typeArguments : List PsVerifiedIrType)
      (scrutinee : PsVerifiedIrExpr)
      (alternatives :
        List
          (String ×
            List PsVerifiedIrMatchBinding ×
            PsVerifiedIrExpr))

structure PsVerifiedIrTypeParameter where
  name : String

structure PsVerifiedIrStructureField where
  name : String
  type : PsVerifiedIrType

structure PsVerifiedIrStructure where
  name : String
  typeParameters : List PsVerifiedIrTypeParameter
  fields : List PsVerifiedIrStructureField

structure PsVerifiedIrConstructorField where
  name : String
  type : PsVerifiedIrType

structure PsVerifiedIrConstructor where
  name : String
  fields : List PsVerifiedIrConstructorField

structure PsVerifiedIrInductive where
  name : String
  typeParameters : List PsVerifiedIrTypeParameter
  constructors : List PsVerifiedIrConstructor

structure PsVerifiedIrDeclaration where
  name : String
  typeParameters : List PsVerifiedIrTypeParameter
  parameters : List PsVerifiedIrParameter
  resultType : PsVerifiedIrType
  body : PsVerifiedIrExpr

structure PsVerifiedIrExternalImport where
  localName : String
  source : String
  importedName : String
  type : PsVerifiedIrType

structure PsVerifiedIrModule where
  imports : List PsVerifiedIrExternalImport
  structures : List PsVerifiedIrStructure
  inductives : List PsVerifiedIrInductive
  declarations : List PsVerifiedIrDeclaration

def psVerifiedIrModuleEmpty : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
    inductives := []
    declarations := []
  }


/- Transitional construction/validation boundary.

The existing PsVerifiedIr* node names predate the explicit validator. Treat raw
PsVerifiedIrModule values as construction IR until wrapped in PsErasedIrModule and
accepted by psValidateErasedIrModule. Backends on the production compiler path
consume PsValidatedIrModule. A future schema cleanup may rename the raw node family
without changing this authority boundary. -/
structure PsErasedIrModule where
  raw : PsVerifiedIrModule

structure PsValidatedIrModule where
  raw : PsVerifiedIrModule

inductive PsVerifiedIrValidationError where
  | unresolvedRuntimeType
  | validationFuelExhausted
  | unknownStructure (name : String)
  | unknownInductive (name : String)
  | unknownConstructor (inductiveName constructorName : String)
  | unknownStructureField (structureName field : String)
  | unknownConstructorField
      (inductiveName constructorName field : String)
  | typeArgumentArity (name : String)
  | invalidMachineIntegerLiteral
      (type : PsVerifiedIrMachineIntegerType)
  | duplicateGlobalName (name : String)
  | duplicateTypeParameter (name : String)
  | duplicateParameter (name : String)
  | duplicateField (owner field : String)
  | duplicateAlternative (constructorName : String)
  | unknownTypeName (name : String)
  | unknownTypeParameter (name : String)
  | unknownVariable (name : String)
  | expressionTypeMismatch
  | callArity
  | intrinsicArity
  | intrinsicTypeArgumentArity
  | fieldCompleteness (owner : String)
  | matchExhaustiveness (inductiveName : String)
  | invalidExternalImport (localName : String)
  | emptyMatch

def psVerifiedIrIntDecimalMagnitudeWithFuel
    (remainingFuel : Nat) :
    String -> Nat -> Nat -> Nat :=
  match remainingFuel with
  | 0 =>
      fun (_text : String) (_position : Nat) (acc : Nat) =>
        acc
  | fuel + 1 =>
      let smaller : String -> Nat -> Nat -> Nat :=
        psVerifiedIrIntDecimalMagnitudeWithFuel fuel;
      fun (text : String) (position : Nat) (acc : Nat) =>
        if String.Internal.atEnd text (String.Pos.Raw.mk position) then
          acc
        else
          let char : Char :=
            String.Internal.get text (String.Pos.Raw.mk position);
          let digit : Nat :=
            Nat.sub (Char.toNat char) 48;
          let nextPosition : Nat :=
            String.Pos.Raw.byteIdx
              (String.Internal.next
                text
                (String.Pos.Raw.mk position));
          smaller
            text
            nextPosition
            (Nat.add (Nat.mul acc 10) digit)

def psVerifiedIrIntNegativeMagnitude
    (value : Int) : Bool × Nat :=
  let text : String := Int.repr value;
  let fuel : Nat := Nat.succ (String.utf8ByteSize text);
  if String.Internal.atEnd text (String.Pos.Raw.mk 0) then
    Prod.mk false 0
  else
    let first : Char :=
      String.Internal.get text (String.Pos.Raw.mk 0);
    if Nat.beq (Char.toNat first) 45 then
      let start : Nat :=
        String.Pos.Raw.byteIdx
          (String.Internal.next text (String.Pos.Raw.mk 0));
      Prod.mk
        true
        (psVerifiedIrIntDecimalMagnitudeWithFuel
          fuel text start 0)
    else
      Prod.mk
        false
        (psVerifiedIrIntDecimalMagnitudeWithFuel
          fuel text 0 0)

def psVerifiedIrMachineIntegerLiteralCanonical
    (type : PsVerifiedIrMachineIntegerType)
    (value : Int) : Bool :=
  let parts : Bool × Nat :=
    psVerifiedIrIntNegativeMagnitude value;
  let negative : Bool := Prod.fst parts;
  let magnitude : Nat := Prod.snd parts;
  match type with
  | PsVerifiedIrMachineIntegerType.uint8 =>
      if negative then false else Nat.ble magnitude 255
  | PsVerifiedIrMachineIntegerType.uint16 =>
      if negative then false else Nat.ble magnitude 65535
  | PsVerifiedIrMachineIntegerType.uint32 =>
      if negative then false else Nat.ble magnitude 4294967295
  | PsVerifiedIrMachineIntegerType.uint64 =>
      if negative then false
      else Nat.ble magnitude 18446744073709551615
  | PsVerifiedIrMachineIntegerType.usize =>
      if negative then false else true
  | PsVerifiedIrMachineIntegerType.int8 =>
      if negative then Nat.ble magnitude 128
      else Nat.ble magnitude 127
  | PsVerifiedIrMachineIntegerType.int16 =>
      if negative then Nat.ble magnitude 32768
      else Nat.ble magnitude 32767
  | PsVerifiedIrMachineIntegerType.int32 =>
      if negative then Nat.ble magnitude 2147483648
      else Nat.ble magnitude 2147483647
  | PsVerifiedIrMachineIntegerType.int64 =>
      if negative then Nat.ble magnitude 9223372036854775808
      else Nat.ble magnitude 9223372036854775807
  | PsVerifiedIrMachineIntegerType.isize =>
      true

def psVerifiedIrValidateLiteral
    (literal : PsVerifiedIrLiteral) :
    Except PsVerifiedIrValidationError Unit :=
  match literal with
  | PsVerifiedIrLiteral.machineInteger type value =>
      if
          psVerifiedIrMachineIntegerLiteralCanonical
            type
            value then
        Except.ok Unit.unit
      else
        Except.error
          (PsVerifiedIrValidationError.invalidMachineIntegerLiteral
            type)
  | _ =>
      Except.ok Unit.unit

def psVerifiedIrListAll {Value : Type}
    (check : Value -> Bool)
    (values : List Value) : Bool :=
  match values with
  | List.nil => true
  | List.cons value rest =>
      if check value then
        psVerifiedIrListAll check rest
      else
        false

def psVerifiedIrTypeResolvedWithFuel
    (fuel : Nat) :
    PsVerifiedIrType -> Bool :=
  match fuel with
  | Nat.zero =>
      fun (_type : PsVerifiedIrType) => false
  | Nat.succ remaining =>
      let smaller : PsVerifiedIrType -> Bool :=
        psVerifiedIrTypeResolvedWithFuel remaining;
      fun (type : PsVerifiedIrType) =>
        match type with
        | PsVerifiedIrType.unknown =>
            false
        | PsVerifiedIrType.typeParameter _ =>
            true
        | PsVerifiedIrType.primitive _ =>
            true
        | PsVerifiedIrType.function parameters result =>
            if psVerifiedIrListAll smaller parameters then
              smaller result
            else
              false
        | PsVerifiedIrType.named _ arguments =>
            psVerifiedIrListAll smaller arguments

def psVerifiedIrTypeResolved
    (type : PsVerifiedIrType) : Bool :=
  psVerifiedIrTypeResolvedWithFuel 4096 type

def psVerifiedIrParameterResolved
    (parameter : PsVerifiedIrParameter) : Bool :=
  psVerifiedIrTypeResolved parameter.type

def psVerifiedIrMatchBindingResolved
    (binding : PsVerifiedIrMatchBinding) : Bool :=
  psVerifiedIrTypeResolved binding.type

def psVerifiedIrParameterResolvedWith
    (typeResolved : PsVerifiedIrType -> Bool)
    (parameter : PsVerifiedIrParameter) : Bool :=
  typeResolved parameter.type

def psVerifiedIrMatchBindingResolvedWith
    (typeResolved : PsVerifiedIrType -> Bool)
    (binding : PsVerifiedIrMatchBinding) : Bool :=
  typeResolved binding.type

def psVerifiedIrExprFieldResolvedWith
    (exprResolved : PsVerifiedIrExpr -> Bool)
    (field : String × PsVerifiedIrExpr) : Bool :=
  match field with
  | Prod.mk _ value =>
      exprResolved value

def psVerifiedIrAlternativeResolvedWith
    (typeResolved : PsVerifiedIrType -> Bool)
    (exprResolved : PsVerifiedIrExpr -> Bool)
    (alternative :
      String ×
        List PsVerifiedIrMatchBinding ×
        PsVerifiedIrExpr) : Bool :=
  match alternative with
  | Prod.mk _ payload =>
      match payload with
      | Prod.mk bindings body =>
          if
              psVerifiedIrListAll
                (psVerifiedIrMatchBindingResolvedWith typeResolved)
                bindings then
            exprResolved body
          else
            false

def psVerifiedIrStructureFieldResolved
    (field : PsVerifiedIrStructureField) : Bool :=
  psVerifiedIrTypeResolved field.type

def psVerifiedIrConstructorFieldResolved
    (field : PsVerifiedIrConstructorField) : Bool :=
  psVerifiedIrTypeResolved field.type

def psVerifiedIrExprResolvedWithFuel
    (fuel : Nat) :
    PsVerifiedIrExpr -> Bool :=
  match fuel with
  | Nat.zero =>
      fun (_expr : PsVerifiedIrExpr) => false
  | Nat.succ remaining =>
      let smaller : PsVerifiedIrExpr -> Bool :=
        psVerifiedIrExprResolvedWithFuel remaining;
      let typeResolved : PsVerifiedIrType -> Bool :=
        psVerifiedIrTypeResolvedWithFuel remaining;
      fun (expr : PsVerifiedIrExpr) =>
        match expr with
        | PsVerifiedIrExpr.literal _ =>
            true
        | PsVerifiedIrExpr.var _ =>
            true
        | PsVerifiedIrExpr.intrinsic _ typeArguments arguments =>
            if psVerifiedIrListAll typeResolved typeArguments then
              psVerifiedIrListAll smaller arguments
            else
              false
        | PsVerifiedIrExpr.lambda parameters resultType body =>
            if
                psVerifiedIrListAll
                  (psVerifiedIrParameterResolvedWith typeResolved)
                  parameters then
              if typeResolved resultType then
                smaller body
              else
                false
            else
              false
        | PsVerifiedIrExpr.call fn typeArguments arguments =>
            if smaller fn then
              if psVerifiedIrListAll typeResolved typeArguments then
                psVerifiedIrListAll smaller arguments
              else
                false
            else
              false
        | PsVerifiedIrExpr.letE _ type value body =>
            if typeResolved type then
              if smaller value then
                smaller body
              else
                false
            else
              false
        | PsVerifiedIrExpr.ifE condition thenBranch elseBranch =>
            if smaller condition then
              if smaller thenBranch then
                smaller elseBranch
              else
                false
            else
              false
        | PsVerifiedIrExpr.record _ typeArguments fields =>
            if psVerifiedIrListAll typeResolved typeArguments then
              psVerifiedIrListAll
                (psVerifiedIrExprFieldResolvedWith smaller)
                fields
            else
              false
        | PsVerifiedIrExpr.projection _ typeArguments target _ =>
            if psVerifiedIrListAll typeResolved typeArguments then
              smaller target
            else
              false
        | PsVerifiedIrExpr.constructor _ _ typeArguments fields =>
            if psVerifiedIrListAll typeResolved typeArguments then
              psVerifiedIrListAll
                (psVerifiedIrExprFieldResolvedWith smaller)
                fields
            else
              false
        | PsVerifiedIrExpr.matchE _ typeArguments scrutinee alternatives =>
            if psVerifiedIrListAll typeResolved typeArguments then
              if smaller scrutinee then
                psVerifiedIrListAll
                  (psVerifiedIrAlternativeResolvedWith
                    typeResolved
                    smaller)
                  alternatives
              else
                false
            else
              false

def psVerifiedIrExprResolved
    (expr : PsVerifiedIrExpr) : Bool :=
  psVerifiedIrExprResolvedWithFuel 4096 expr

def psVerifiedIrStructureResolved
    (structureInfo : PsVerifiedIrStructure) : Bool :=
  psVerifiedIrListAll
    psVerifiedIrStructureFieldResolved
    structureInfo.fields

def psVerifiedIrConstructorResolved
    (constructorInfo : PsVerifiedIrConstructor) : Bool :=
  psVerifiedIrListAll
    psVerifiedIrConstructorFieldResolved
    constructorInfo.fields

def psVerifiedIrInductiveResolved
    (inductiveInfo : PsVerifiedIrInductive) : Bool :=
  psVerifiedIrListAll
    psVerifiedIrConstructorResolved
    inductiveInfo.constructors

def psVerifiedIrDeclarationResolved
    (declaration : PsVerifiedIrDeclaration) : Bool :=
  if
      psVerifiedIrListAll
        psVerifiedIrParameterResolved
        declaration.parameters then
    if psVerifiedIrTypeResolved declaration.resultType then
      psVerifiedIrExprResolved declaration.body
    else
      false
  else
    false

def psVerifiedIrImportResolved
    (importInfo : PsVerifiedIrExternalImport) : Bool :=
  psVerifiedIrTypeResolved importInfo.type

def psVerifiedIrModuleResolved
    (module : PsVerifiedIrModule) : Bool :=
  if psVerifiedIrListAll psVerifiedIrImportResolved module.imports then
    if
        psVerifiedIrListAll
          psVerifiedIrStructureResolved
          module.structures then
      if
          psVerifiedIrListAll
            psVerifiedIrInductiveResolved
            module.inductives then
        psVerifiedIrListAll
          psVerifiedIrDeclarationResolved
          module.declarations
      else
        false
    else
      false
  else
    false

def psVerifiedIrListLength {Value : Type}
    (values : List Value) : Nat :=
  match values with
  | List.nil => 0
  | List.cons _ rest =>
      Nat.succ (psVerifiedIrListLength rest)

def psVerifiedIrFindStructure
    (structures : List PsVerifiedIrStructure) :
    String -> Option PsVerifiedIrStructure :=
  match structures with
  | List.nil =>
      fun (_target : String) => Option.none
  | List.cons structureInfo rest =>
      let smaller : String -> Option PsVerifiedIrStructure :=
        psVerifiedIrFindStructure rest;
      fun (target : String) =>
        if psStringEq structureInfo.name target then
          Option.some structureInfo
        else
          smaller target

def psVerifiedIrFindInductive
    (inductives : List PsVerifiedIrInductive) :
    String -> Option PsVerifiedIrInductive :=
  match inductives with
  | List.nil =>
      fun (_target : String) => Option.none
  | List.cons inductiveInfo rest =>
      let smaller : String -> Option PsVerifiedIrInductive :=
        psVerifiedIrFindInductive rest;
      fun (target : String) =>
        if psStringEq inductiveInfo.name target then
          Option.some inductiveInfo
        else
          smaller target

def psVerifiedIrFindConstructor
    (constructors : List PsVerifiedIrConstructor) :
    String -> Option PsVerifiedIrConstructor :=
  match constructors with
  | List.nil =>
      fun (_target : String) => Option.none
  | List.cons constructorInfo rest =>
      let smaller : String -> Option PsVerifiedIrConstructor :=
        psVerifiedIrFindConstructor rest;
      fun (target : String) =>
        if psStringEq constructorInfo.name target then
          Option.some constructorInfo
        else
          smaller target

def psVerifiedIrStructureHasField
    (fields : List PsVerifiedIrStructureField) :
    String -> Bool :=
  match fields with
  | List.nil =>
      fun (_target : String) => false
  | List.cons field rest =>
      let smaller : String -> Bool :=
        psVerifiedIrStructureHasField rest;
      fun (target : String) =>
        if psStringEq field.name target then true
        else smaller target

def psVerifiedIrConstructorHasField
    (fields : List PsVerifiedIrConstructorField) :
    String -> Bool :=
  match fields with
  | List.nil =>
      fun (_target : String) => false
  | List.cons field rest =>
      let smaller : String -> Bool :=
        psVerifiedIrConstructorHasField rest;
      fun (target : String) =>
        if psStringEq field.name target then true
        else smaller target

def psVerifiedIrTypeArgumentArityMatches
    (parameters : List PsVerifiedIrTypeParameter)
    (arguments : List PsVerifiedIrType) : Bool :=
  Nat.beq
    (psVerifiedIrListLength parameters)
    (psVerifiedIrListLength arguments)

def psVerifiedIrValidateExprListWith
    (validateExpr :
      PsVerifiedIrExpr ->
        Except PsVerifiedIrValidationError Unit)
    (values : List PsVerifiedIrExpr) :
    Except PsVerifiedIrValidationError Unit :=
  match values with
  | List.nil =>
      Except.ok Unit.unit
  | List.cons value rest =>
      match validateExpr value with
      | Except.error error => Except.error error
      | Except.ok _ =>
          psVerifiedIrValidateExprListWith validateExpr rest

def psVerifiedIrValidateRecordFieldsWith
    (structureName : String)
    (structureFields : List PsVerifiedIrStructureField)
    (validateExpr :
      PsVerifiedIrExpr ->
        Except PsVerifiedIrValidationError Unit)
    (fields : List (String × PsVerifiedIrExpr)) :
    Except PsVerifiedIrValidationError Unit :=
  match fields with
  | List.nil =>
      Except.ok Unit.unit
  | List.cons field rest =>
      match field with
        | Prod.mk fieldName value =>
            if
                psVerifiedIrStructureHasField
                  structureFields
                  fieldName then
              match validateExpr value with
              | Except.error error => Except.error error
              | Except.ok _ =>
                  psVerifiedIrValidateRecordFieldsWith
                    structureName
                    structureFields
                    validateExpr
                    rest
            else
              Except.error
                (PsVerifiedIrValidationError.unknownStructureField
                  structureName
                  fieldName)

def psVerifiedIrValidateConstructorFieldsWith
    (inductiveName constructorName : String)
    (constructorFields : List PsVerifiedIrConstructorField)
    (validateExpr :
      PsVerifiedIrExpr ->
        Except PsVerifiedIrValidationError Unit)
    (fields : List (String × PsVerifiedIrExpr)) :
    Except PsVerifiedIrValidationError Unit :=
  match fields with
  | List.nil =>
      Except.ok Unit.unit
  | List.cons field rest =>
      match field with
        | Prod.mk fieldName value =>
            if
                psVerifiedIrConstructorHasField
                  constructorFields
                  fieldName then
              match validateExpr value with
              | Except.error error => Except.error error
              | Except.ok _ =>
                  psVerifiedIrValidateConstructorFieldsWith
                    inductiveName
                    constructorName
                    constructorFields
                    validateExpr
                    rest
            else
              Except.error
                (PsVerifiedIrValidationError.unknownConstructorField
                  inductiveName
                  constructorName
                  fieldName)

def psVerifiedIrValidateBindings
    (inductiveName constructorName : String)
    (constructorFields : List PsVerifiedIrConstructorField)
    (bindings : List PsVerifiedIrMatchBinding) :
    Except PsVerifiedIrValidationError Unit :=
  match bindings with
  | List.nil =>
      Except.ok Unit.unit
  | List.cons binding rest =>
        if
            psVerifiedIrConstructorHasField
              constructorFields
              binding.field then
          psVerifiedIrValidateBindings
            inductiveName
            constructorName
            constructorFields
            rest
        else
          Except.error
            (PsVerifiedIrValidationError.unknownConstructorField
              inductiveName
              constructorName
              binding.field)

def psVerifiedIrValidateAlternativeWith
    (inductiveName : String)
    (constructors : List PsVerifiedIrConstructor)
    (validateExpr :
      PsVerifiedIrExpr ->
        Except PsVerifiedIrValidationError Unit)
    (alternative :
      String ×
        List PsVerifiedIrMatchBinding ×
        PsVerifiedIrExpr) :
    Except PsVerifiedIrValidationError Unit :=
  match alternative with
  | Prod.mk constructorName payload =>
      match payload with
      | Prod.mk bindings body =>
          match
              psVerifiedIrFindConstructor
                constructors
                constructorName with
          | Option.none =>
              Except.error
                (PsVerifiedIrValidationError.unknownConstructor
                  inductiveName
                  constructorName)
          | Option.some constructorInfo =>
              match
                  psVerifiedIrValidateBindings
                    inductiveName
                    constructorName
                    constructorInfo.fields
                    bindings with
              | Except.error error => Except.error error
              | Except.ok _ => validateExpr body

def psVerifiedIrValidateAlternativesWith
    (inductiveName : String)
    (constructors : List PsVerifiedIrConstructor)
    (validateExpr :
      PsVerifiedIrExpr ->
        Except PsVerifiedIrValidationError Unit)
    (alternatives :
      List
        (String ×
          List PsVerifiedIrMatchBinding ×
          PsVerifiedIrExpr)) :
    Except PsVerifiedIrValidationError Unit :=
  match alternatives with
  | List.nil =>
      Except.ok Unit.unit
  | List.cons alternative rest =>
        match
            psVerifiedIrValidateAlternativeWith
              inductiveName
              constructors
              validateExpr
              alternative with
        | Except.error error => Except.error error
        | Except.ok _ =>
            psVerifiedIrValidateAlternativesWith
              inductiveName
              constructors
              validateExpr
              rest

def psVerifiedIrValidateExprReferencesWithFuel
    (module : PsVerifiedIrModule)
    (fuel : Nat) :
    PsVerifiedIrExpr ->
      Except PsVerifiedIrValidationError Unit :=
  match fuel with
  | Nat.zero =>
      fun (_expr : PsVerifiedIrExpr) =>
        Except.error
          PsVerifiedIrValidationError.validationFuelExhausted
  | Nat.succ remaining =>
      let smaller :
          PsVerifiedIrExpr ->
            Except PsVerifiedIrValidationError Unit :=
        psVerifiedIrValidateExprReferencesWithFuel
          module
          remaining;
      fun (expr : PsVerifiedIrExpr) =>
        match expr with
        | PsVerifiedIrExpr.literal literal =>
            psVerifiedIrValidateLiteral literal
        | PsVerifiedIrExpr.var _ =>
            Except.ok Unit.unit
        | PsVerifiedIrExpr.intrinsic _ _ arguments =>
            psVerifiedIrValidateExprListWith smaller arguments
        | PsVerifiedIrExpr.lambda _ _ body =>
            smaller body
        | PsVerifiedIrExpr.call fn _ arguments =>
            match smaller fn with
            | Except.error error => Except.error error
            | Except.ok _ =>
                psVerifiedIrValidateExprListWith
                  smaller
                  arguments
        | PsVerifiedIrExpr.letE _ _ value body =>
            match smaller value with
            | Except.error error => Except.error error
            | Except.ok _ => smaller body
        | PsVerifiedIrExpr.ifE
            condition
            thenBranch
            elseBranch =>
            match smaller condition with
            | Except.error error => Except.error error
            | Except.ok _ =>
                match smaller thenBranch with
                | Except.error error => Except.error error
                | Except.ok _ => smaller elseBranch
        | PsVerifiedIrExpr.record
            structureName
            typeArguments
            fields =>
            match
                psVerifiedIrFindStructure
                  module.structures
                  structureName with
            | Option.none =>
                Except.error
                  (PsVerifiedIrValidationError.unknownStructure
                    structureName)
            | Option.some structureInfo =>
                if
                    psVerifiedIrTypeArgumentArityMatches
                      structureInfo.typeParameters
                      typeArguments then
                  psVerifiedIrValidateRecordFieldsWith
                    structureName
                    structureInfo.fields
                    smaller
                    fields
                else
                  Except.error
                    (PsVerifiedIrValidationError.typeArgumentArity
                      structureName)
        | PsVerifiedIrExpr.projection
            structureName
            typeArguments
            target
            field =>
            match
                psVerifiedIrFindStructure
                  module.structures
                  structureName with
            | Option.none =>
                Except.error
                  (PsVerifiedIrValidationError.unknownStructure
                    structureName)
            | Option.some structureInfo =>
                if
                    psVerifiedIrTypeArgumentArityMatches
                      structureInfo.typeParameters
                      typeArguments then
                  if
                      psVerifiedIrStructureHasField
                        structureInfo.fields
                        field then
                    smaller target
                  else
                    Except.error
                      (PsVerifiedIrValidationError.unknownStructureField
                        structureName
                        field)
                else
                  Except.error
                    (PsVerifiedIrValidationError.typeArgumentArity
                      structureName)
        | PsVerifiedIrExpr.constructor
            inductiveName
            constructorName
            typeArguments
            fields =>
            match
                psVerifiedIrFindInductive
                  module.inductives
                  inductiveName with
            | Option.none =>
                Except.error
                  (PsVerifiedIrValidationError.unknownInductive
                    inductiveName)
            | Option.some inductiveInfo =>
                if
                    psVerifiedIrTypeArgumentArityMatches
                      inductiveInfo.typeParameters
                      typeArguments then
                  match
                      psVerifiedIrFindConstructor
                        inductiveInfo.constructors
                        constructorName with
                  | Option.none =>
                      Except.error
                        (PsVerifiedIrValidationError.unknownConstructor
                          inductiveName
                          constructorName)
                  | Option.some constructorInfo =>
                      psVerifiedIrValidateConstructorFieldsWith
                        inductiveName
                        constructorName
                        constructorInfo.fields
                        smaller
                        fields
                else
                  Except.error
                    (PsVerifiedIrValidationError.typeArgumentArity
                      inductiveName)
        | PsVerifiedIrExpr.matchE
            inductiveName
            typeArguments
            scrutinee
            alternatives =>
            match
                psVerifiedIrFindInductive
                  module.inductives
                  inductiveName with
            | Option.none =>
                Except.error
                  (PsVerifiedIrValidationError.unknownInductive
                    inductiveName)
            | Option.some inductiveInfo =>
                if
                    psVerifiedIrTypeArgumentArityMatches
                      inductiveInfo.typeParameters
                      typeArguments then
                  match smaller scrutinee with
                  | Except.error error => Except.error error
                  | Except.ok _ =>
                      psVerifiedIrValidateAlternativesWith
                        inductiveName
                        inductiveInfo.constructors
                        smaller
                        alternatives
                else
                  Except.error
                    (PsVerifiedIrValidationError.typeArgumentArity
                      inductiveName)

def psVerifiedIrValidateDeclarationsWith
    (module : PsVerifiedIrModule)
    (declarations : List PsVerifiedIrDeclaration) :
    Except PsVerifiedIrValidationError Unit :=
  match declarations with
  | List.nil =>
      Except.ok Unit.unit
  | List.cons declaration rest =>
        match
            psVerifiedIrValidateExprReferencesWithFuel
              module
              4096
              declaration.body with
        | Except.error error => Except.error error
        | Except.ok _ =>
            psVerifiedIrValidateDeclarationsWith
              module
              rest

def psVerifiedIrValidateReferences
    (module : PsVerifiedIrModule) :
    Except PsVerifiedIrValidationError Unit :=
  psVerifiedIrValidateDeclarationsWith
    module
    module.declarations

def psValidateErasedIrModuleReferences
    (erased : PsErasedIrModule) :
    Except PsVerifiedIrValidationError PsValidatedIrModule :=
  if psVerifiedIrModuleResolved erased.raw then
    match psVerifiedIrValidateReferences erased.raw with
    | Except.error error => Except.error error
    | Except.ok _ =>
        Except.ok (PsValidatedIrModule.mk erased.raw)
  else
    Except.error PsVerifiedIrValidationError.unresolvedRuntimeType
