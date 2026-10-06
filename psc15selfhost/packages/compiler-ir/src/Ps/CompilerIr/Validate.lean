import Ps.CompilerIr.Model
import Ps.Foundation.List

def psStrictStringInList
    (target : String)
    (values : List String) : Bool :=
  match values with
  | List.nil => false
  | List.cons value rest =>
      if psStringEq target value then
        true
      else
        psStrictStringInList target rest

def psStrictStringListUnique
    (values : List String) : Bool :=
  match values with
  | List.nil => true
  | List.cons value rest =>
      if psStrictStringInList value rest then
        false
      else
        psStrictStringListUnique rest

def psStrictTypeListPairAll
    (check : PsVerifiedIrType -> PsVerifiedIrType -> Bool)
    (left : List PsVerifiedIrType) :
    List PsVerifiedIrType -> Bool :=
  match left with
  | List.nil =>
      fun (right : List PsVerifiedIrType) =>
        match right with
        | List.nil => true
        | List.cons _ _ => false
  | List.cons leftHead leftRest =>
      let smaller : List PsVerifiedIrType -> Bool :=
        psStrictTypeListPairAll check leftRest;
      fun (right : List PsVerifiedIrType) =>
        match right with
        | List.nil => false
        | List.cons rightHead rightRest =>
            if check leftHead rightHead then
              smaller rightRest
            else
              false

def psStrictPrimitiveTypeEq
    (left right : PsVerifiedIrPrimitiveType) : Bool :=
  match left with
  | .nat =>
      match right with | PsVerifiedIrPrimitiveType.nat => true | _ => false
  | .int =>
      match right with | PsVerifiedIrPrimitiveType.int => true | _ => false
  | .uint8 =>
      match right with | PsVerifiedIrPrimitiveType.uint8 => true | _ => false
  | .uint16 =>
      match right with | PsVerifiedIrPrimitiveType.uint16 => true | _ => false
  | .uint32 =>
      match right with | PsVerifiedIrPrimitiveType.uint32 => true | _ => false
  | .uint64 =>
      match right with | PsVerifiedIrPrimitiveType.uint64 => true | _ => false
  | .usize =>
      match right with | PsVerifiedIrPrimitiveType.usize => true | _ => false
  | .int8 =>
      match right with | PsVerifiedIrPrimitiveType.int8 => true | _ => false
  | .int16 =>
      match right with | PsVerifiedIrPrimitiveType.int16 => true | _ => false
  | .int32 =>
      match right with | PsVerifiedIrPrimitiveType.int32 => true | _ => false
  | .int64 =>
      match right with | PsVerifiedIrPrimitiveType.int64 => true | _ => false
  | .isize =>
      match right with | PsVerifiedIrPrimitiveType.isize => true | _ => false
  | .float =>
      match right with | PsVerifiedIrPrimitiveType.float => true | _ => false
  | .float32 =>
      match right with | PsVerifiedIrPrimitiveType.float32 => true | _ => false
  | .bool =>
      match right with | PsVerifiedIrPrimitiveType.bool => true | _ => false
  | .char =>
      match right with | PsVerifiedIrPrimitiveType.char => true | _ => false
  | .string =>
      match right with | PsVerifiedIrPrimitiveType.string => true | _ => false
  | .unit =>
      match right with | PsVerifiedIrPrimitiveType.unit => true | _ => false

def psStrictTypeEqWithFuel
    (fuel : Nat) :
    PsVerifiedIrType -> PsVerifiedIrType -> Bool :=
  match fuel with
  | Nat.zero =>
      fun (_left _right : PsVerifiedIrType) => false
  | Nat.succ remaining =>
      let smaller :
          PsVerifiedIrType -> PsVerifiedIrType -> Bool :=
        psStrictTypeEqWithFuel remaining;
      fun (left right : PsVerifiedIrType) =>
        match left with
        | .unknown =>
            match right with
            | .unknown => true
            | _ => false
        | .typeParameter leftName =>
            match right with
            | .typeParameter rightName =>
                psStringEq leftName rightName
            | _ => false
        | .primitive leftPrimitive =>
            match right with
            | .primitive rightPrimitive =>
                psStrictPrimitiveTypeEq
                  leftPrimitive
                  rightPrimitive
            | _ => false
        | .function leftParameters leftResult =>
            match right with
            | .function rightParameters rightResult =>
                if
                    psStrictTypeListPairAll
                      smaller
                      leftParameters
                      rightParameters then
                  smaller leftResult rightResult
                else
                  false
            | _ => false
        | .named leftName leftArguments =>
            match right with
            | .named rightName rightArguments =>
                if psStringEq leftName rightName then
                  psStrictTypeListPairAll
                    smaller
                    leftArguments
                    rightArguments
                else
                  false
            | _ => false

def psStrictTypeEq
    (left right : PsVerifiedIrType) : Bool :=
  psStrictTypeEqWithFuel 4096 left right

def psStrictTypeParameterNames
    (parameters : List PsVerifiedIrTypeParameter) :
    List String :=
  match parameters with
  | List.nil => List.nil
  | List.cons parameter rest =>
      List.cons
        parameter.name
        (psStrictTypeParameterNames rest)

def psStrictParameterNames
    (parameters : List PsVerifiedIrParameter) :
    List String :=
  match parameters with
  | List.nil => List.nil
  | List.cons parameter rest =>
      List.cons
        parameter.name
        (psStrictParameterNames rest)

def psStrictStructureFieldNames
    (fields : List PsVerifiedIrStructureField) :
    List String :=
  match fields with
  | List.nil => List.nil
  | List.cons field rest =>
      List.cons
        field.name
        (psStrictStructureFieldNames rest)

def psStrictConstructorFieldNames
    (fields : List PsVerifiedIrConstructorField) :
    List String :=
  match fields with
  | List.nil => List.nil
  | List.cons field rest =>
      List.cons
        field.name
        (psStrictConstructorFieldNames rest)

def psStrictConstructorNames
    (constructors : List PsVerifiedIrConstructor) :
    List String :=
  match constructors with
  | List.nil => List.nil
  | List.cons constructorInfo rest =>
      List.cons
        constructorInfo.name
        (psStrictConstructorNames rest)

def psStrictBindingFieldNames
    (bindings : List PsVerifiedIrMatchBinding) :
    List String :=
  match bindings with
  | List.nil => List.nil
  | List.cons binding rest =>
      List.cons
        binding.field
        (psStrictBindingFieldNames rest)

def psStrictBindingNames
    (bindings : List PsVerifiedIrMatchBinding) :
    List String :=
  match bindings with
  | List.nil => List.nil
  | List.cons binding rest =>
      List.cons
        binding.name
        (psStrictBindingNames rest)

def psStrictAlternativeNames
    (alternatives :
      List
        (String ×
          List PsVerifiedIrMatchBinding ×
          PsVerifiedIrExpr)) :
    List String :=
  match alternatives with
  | List.nil => List.nil
  | List.cons alternative rest =>
      List.cons
        (Prod.fst alternative)
        (psStrictAlternativeNames rest)

def psStrictFindDeclaration
    (declarations : List PsVerifiedIrDeclaration)
    (target : String) :
    Option PsVerifiedIrDeclaration :=
  match declarations with
  | List.nil => Option.none
  | List.cons declaration rest =>
      if psStringEq declaration.name target then
        Option.some declaration
      else
        psStrictFindDeclaration rest target

def psStrictFindImport
    (imports : List PsVerifiedIrExternalImport)
    (target : String) :
    Option PsVerifiedIrExternalImport :=
  match imports with
  | List.nil => Option.none
  | List.cons importInfo rest =>
      if psStringEq importInfo.localName target then
        Option.some importInfo
      else
        psStrictFindImport rest target

def psStrictFindStructureField
    (fields : List PsVerifiedIrStructureField)
    (target : String) :
    Option PsVerifiedIrStructureField :=
  match fields with
  | List.nil => Option.none
  | List.cons field rest =>
      if psStringEq field.name target then
        Option.some field
      else
        psStrictFindStructureField rest target

def psStrictFindConstructorField
    (fields : List PsVerifiedIrConstructorField)
    (target : String) :
    Option PsVerifiedIrConstructorField :=
  match fields with
  | List.nil => Option.none
  | List.cons field rest =>
      if psStringEq field.name target then
        Option.some field
      else
        psStrictFindConstructorField rest target

def psStrictExprFieldNames
    (fields : List (String × PsVerifiedIrExpr)) :
    List String :=
  match fields with
  | List.nil => List.nil
  | List.cons field rest =>
      List.cons
        (Prod.fst field)
        (psStrictExprFieldNames rest)

def psStrictFindExprField
    (fields : List (String × PsVerifiedIrExpr))
    (target : String) :
    Option PsVerifiedIrExpr :=
  match fields with
  | List.nil => Option.none
  | List.cons field rest =>
      if psStringEq (Prod.fst field) target then
        Option.some (Prod.snd field)
      else
        psStrictFindExprField rest target

def psStrictFindBinding
    (bindings : List PsVerifiedIrMatchBinding)
    (target : String) :
    Option PsVerifiedIrMatchBinding :=
  match bindings with
  | List.nil => Option.none
  | List.cons binding rest =>
      if psStringEq binding.field target then
        Option.some binding
      else
        psStrictFindBinding rest target

def psStrictFindAlternative
    (alternatives :
      List
        (String ×
          List PsVerifiedIrMatchBinding ×
          PsVerifiedIrExpr))
    (target : String) :
    Option
      (List PsVerifiedIrMatchBinding ×
        PsVerifiedIrExpr) :=
  match alternatives with
  | List.nil => Option.none
  | List.cons alternative rest =>
      if psStringEq (Prod.fst alternative) target then
        Option.some (Prod.snd alternative)
      else
        psStrictFindAlternative rest target

def psStrictTypeSubstitutionLookup
    (substitution : List (String × PsVerifiedIrType))
    (target : String) :
    Option PsVerifiedIrType :=
  match substitution with
  | List.nil => Option.none
  | List.cons entry rest =>
      if psStringEq (Prod.fst entry) target then
        Option.some (Prod.snd entry)
      else
        psStrictTypeSubstitutionLookup rest target

def psStrictSubstituteTypeWithFuel
    (substitution : List (String × PsVerifiedIrType))
    (fuel : Nat) :
    PsVerifiedIrType -> PsVerifiedIrType :=
  match fuel with
  | Nat.zero =>
      fun (type : PsVerifiedIrType) => type
  | Nat.succ remaining =>
      let smaller : PsVerifiedIrType -> PsVerifiedIrType :=
        psStrictSubstituteTypeWithFuel
          substitution
          remaining;
      fun (type : PsVerifiedIrType) =>
        match type with
        | .unknown => PsVerifiedIrType.unknown
        | .typeParameter name =>
            match
                psStrictTypeSubstitutionLookup
                  substitution
                  name with
            | Option.none => PsVerifiedIrType.typeParameter name
            | Option.some value => value
        | .primitive primitive => PsVerifiedIrType.primitive primitive
        | .function parameters result =>
            PsVerifiedIrType.function
              (psListMap smaller parameters)
              (smaller result)
        | .named name arguments =>
            PsVerifiedIrType.named name (psListMap smaller arguments)

def psStrictSubstituteType
    (substitution : List (String × PsVerifiedIrType))
    (type : PsVerifiedIrType) :
    PsVerifiedIrType :=
  psStrictSubstituteTypeWithFuel
    substitution
    4096
    type

def psStrictBuildSubstitution
    (parameters : List PsVerifiedIrTypeParameter) :
    List PsVerifiedIrType ->
    Except PsVerifiedIrValidationError
      (List (String × PsVerifiedIrType)) :=
  match parameters with
  | List.nil =>
      fun (arguments : List PsVerifiedIrType) =>
        match arguments with
        | List.nil => Except.ok List.nil
        | List.cons _ _ =>
            Except.error
              PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | List.cons parameter parameterRest =>
      let smaller :
          List PsVerifiedIrType ->
          Except PsVerifiedIrValidationError
            (List (String × PsVerifiedIrType)) :=
        psStrictBuildSubstitution parameterRest;
      fun (arguments : List PsVerifiedIrType) =>
        match arguments with
        | List.nil =>
            Except.error
              PsVerifiedIrValidationError.intrinsicTypeArgumentArity
        | List.cons argument argumentRest =>
            match smaller argumentRest with
            | Except.error error => Except.error error
            | Except.ok rest =>
                Except.ok
                  (List.cons
                    (Prod.mk parameter.name argument)
                    rest)

def psStrictValidateTypeListWith
    (validate :
      PsVerifiedIrType ->
        Except PsVerifiedIrValidationError Unit)
    (types : List PsVerifiedIrType) :
    Except PsVerifiedIrValidationError Unit :=
  match types with
  | List.nil => Except.ok Unit.unit
  | List.cons type rest =>
      match validate type with
      | Except.error error => Except.error error
      | Except.ok _ =>
          psStrictValidateTypeListWith
            validate
            rest

def psStrictValidateTypeInScopeWithFuel
    (module : PsVerifiedIrModule)
    (typeParameters : List String)
    (fuel : Nat) :
    PsVerifiedIrType ->
      Except PsVerifiedIrValidationError Unit :=
  match fuel with
  | Nat.zero =>
      fun (_type : PsVerifiedIrType) =>
        Except.error
          PsVerifiedIrValidationError.validationFuelExhausted
  | Nat.succ remaining =>
      let smaller :
          PsVerifiedIrType ->
            Except PsVerifiedIrValidationError Unit :=
        psStrictValidateTypeInScopeWithFuel
          module
          typeParameters
          remaining;
      fun (type : PsVerifiedIrType) =>
        match type with
        | .unknown =>
            Except.error
              PsVerifiedIrValidationError.unresolvedRuntimeType
        | .typeParameter name =>
            if psStrictStringInList name typeParameters then
              Except.ok Unit.unit
            else
              Except.error
                (PsVerifiedIrValidationError.unknownTypeParameter
                  name)
        | .primitive _ =>
            Except.ok Unit.unit
        | .function parameters result =>
            match
                psStrictValidateTypeListWith
                  smaller
                  parameters with
            | Except.error error => Except.error error
            | Except.ok _ => smaller result
        | .named name arguments =>
            match
                psStrictValidateTypeListWith
                  smaller
                  arguments with
            | Except.error error => Except.error error
            | Except.ok _ =>
                if psStringEq name "Array" then
                  if
                      Nat.beq
                        (psVerifiedIrListLength arguments)
                        1 then
                    Except.ok Unit.unit
                  else
                    Except.error
                      (PsVerifiedIrValidationError.typeArgumentArity
                        name)
                else
                  match
                      psVerifiedIrFindStructure
                        module.structures
                        name with
                  | Option.some structureInfo =>
                      if
                          psVerifiedIrTypeArgumentArityMatches
                            structureInfo.typeParameters
                            arguments then
                        Except.ok Unit.unit
                      else
                        Except.error
                          (PsVerifiedIrValidationError.typeArgumentArity
                            name)
                  | Option.none =>
                      match
                          psVerifiedIrFindInductive
                            module.inductives
                            name with
                      | Option.some inductiveInfo =>
                          if
                              psVerifiedIrTypeArgumentArityMatches
                                inductiveInfo.typeParameters
                                arguments then
                            Except.ok Unit.unit
                          else
                            Except.error
                              (PsVerifiedIrValidationError.typeArgumentArity
                                name)
                      | Option.none =>
                          Except.error
                            (PsVerifiedIrValidationError.unknownTypeName
                              name)

def psStrictValidateTypeInScope
    (module : PsVerifiedIrModule)
    (typeParameters : List String)
    (type : PsVerifiedIrType) :
    Except PsVerifiedIrValidationError Unit :=
  psStrictValidateTypeInScopeWithFuel
    module
    typeParameters
    4096
    type

def psStrictValidateTypeListInScope
    (module : PsVerifiedIrModule)
    (typeParameters : List String)
    (types : List PsVerifiedIrType) :
    Except PsVerifiedIrValidationError Unit :=
  psStrictValidateTypeListWith
    (psStrictValidateTypeInScope module typeParameters)
    types

def psStrictLocalLookup
    (locals : List (String × PsVerifiedIrType))
    (target : String) :
    Option PsVerifiedIrType :=
  match locals with
  | List.nil => Option.none
  | List.cons entry rest =>
      if psStringEq (Prod.fst entry) target then
        Option.some (Prod.snd entry)
      else
        psStrictLocalLookup rest target

def psStrictAddParameters
    (parameters : List PsVerifiedIrParameter) :
    List (String × PsVerifiedIrType) ->
    List (String × PsVerifiedIrType) :=
  match parameters with
  | List.nil =>
      fun (locals : List (String × PsVerifiedIrType)) =>
        locals
  | List.cons parameter rest =>
      let smaller :
          List (String × PsVerifiedIrType) ->
          List (String × PsVerifiedIrType) :=
        psStrictAddParameters rest;
      fun (locals : List (String × PsVerifiedIrType)) =>
        smaller
          (List.cons
            (Prod.mk parameter.name parameter.type)
            locals)

def psStrictAddBindings
    (bindings : List PsVerifiedIrMatchBinding) :
    List (String × PsVerifiedIrType) ->
    List (String × PsVerifiedIrType) :=
  match bindings with
  | List.nil =>
      fun (locals : List (String × PsVerifiedIrType)) =>
        locals
  | List.cons binding rest =>
      let smaller :
          List (String × PsVerifiedIrType) ->
          List (String × PsVerifiedIrType) :=
        psStrictAddBindings rest;
      fun (locals : List (String × PsVerifiedIrType)) =>
        smaller
          (List.cons
            (Prod.mk binding.name binding.type)
            locals)

def psStrictParameterTypes
    (parameters : List PsVerifiedIrParameter) :
    List PsVerifiedIrType :=
  match parameters with
  | List.nil => List.nil
  | List.cons parameter rest =>
      List.cons
        parameter.type
        (psStrictParameterTypes rest)

def psStrictDeclarationType
    (declaration : PsVerifiedIrDeclaration) :
    PsVerifiedIrType :=
  match declaration.parameters with
  | List.nil => declaration.resultType
  | List.cons _ _ =>
      PsVerifiedIrType.function
        (psStrictParameterTypes declaration.parameters)
        declaration.resultType

def psStrictMachinePrimitive
    (type : PsVerifiedIrMachineIntegerType) :
    PsVerifiedIrType :=
  match type with
  | .uint8 => PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint8
  | .uint16 => PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint16
  | .uint32 => PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint32
  | .uint64 => PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint64
  | .usize => PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.usize
  | .int8 => PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int8
  | .int16 => PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int16
  | .int32 => PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int32
  | .int64 => PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int64
  | .isize => PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.isize

def psStrictFloatPrimitive
    (type : PsVerifiedIrFloatingType) :
    PsVerifiedIrType :=
  match type with
  | .float => PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.float
  | .float32 => PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.float32

def psStrictArrayType
    (element : PsVerifiedIrType) :
    PsVerifiedIrType :=
  PsVerifiedIrType.named
    "Array"
    (List.cons element List.nil)

def psStrictExactOneTypeArgument
    (arguments : List PsVerifiedIrType) :
    Option PsVerifiedIrType :=
  match arguments with
  | List.cons first rest =>
      match rest with
      | List.nil => Option.some first
      | List.cons _ _ => Option.none
  | List.nil => Option.none

def psStrictExactTwoTypeArguments
    (arguments : List PsVerifiedIrType) :
    Option (PsVerifiedIrType × PsVerifiedIrType) :=
  match arguments with
  | List.cons first rest =>
      match rest with
      | List.cons second tail =>
          match tail with
          | List.nil =>
              Option.some (Prod.mk first second)
          | List.cons _ _ => Option.none
      | List.nil => Option.none
  | List.nil => Option.none

def psStrictNoTypeArguments
    (arguments : List PsVerifiedIrType) : Bool :=
  match arguments with
  | List.nil => true
  | List.cons _ _ => false

def psStrictIntrinsicSignature
    (operation : PsVerifiedIrIntrinsic)
    (typeArguments : List PsVerifiedIrType) :
    Except PsVerifiedIrValidationError
      (List PsVerifiedIrType × PsVerifiedIrType) :=
  let natType : PsVerifiedIrType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat;
  let intType : PsVerifiedIrType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int;
  let boolType : PsVerifiedIrType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool;
  let charType : PsVerifiedIrType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.char;
  let stringType : PsVerifiedIrType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.string;
  match operation with
  | .machineIntBinary type _ =>
      if psStrictNoTypeArguments typeArguments then
        let valueType : PsVerifiedIrType :=
          psStrictMachinePrimitive type;
        Except.ok
          (Prod.mk
            (List.cons valueType
              (List.cons valueType List.nil))
            valueType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .machineIntCompare type _ =>
      if psStrictNoTypeArguments typeArguments then
        let valueType : PsVerifiedIrType :=
          psStrictMachinePrimitive type;
        Except.ok
          (Prod.mk
            (List.cons valueType
              (List.cons valueType List.nil))
            boolType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .uint8OfNat =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons natType List.nil)
            (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint8))
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .floatBinary type _ =>
      if psStrictNoTypeArguments typeArguments then
        let valueType : PsVerifiedIrType :=
          psStrictFloatPrimitive type;
        Except.ok
          (Prod.mk
            (List.cons valueType
              (List.cons valueType List.nil))
            valueType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .floatCompare type _ =>
      if psStrictNoTypeArguments typeArguments then
        let valueType : PsVerifiedIrType :=
          psStrictFloatPrimitive type;
        Except.ok
          (Prod.mk
            (List.cons valueType
              (List.cons valueType List.nil))
            boolType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .natAdd =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons natType
              (List.cons natType List.nil))
            natType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .natSub =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons natType
              (List.cons natType List.nil))
            natType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .natMul =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons natType
              (List.cons natType List.nil))
            natType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .natDiv =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons natType
              (List.cons natType List.nil))
            natType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .natMod =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons natType
              (List.cons natType List.nil))
            natType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .natEq =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons natType
              (List.cons natType List.nil))
            boolType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .natNe =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons natType
              (List.cons natType List.nil))
            boolType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .natLe =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons natType
              (List.cons natType List.nil))
            boolType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .natLt =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons natType
              (List.cons natType List.nil))
            boolType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .intOfNat =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons natType List.nil)
            intType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .intRepr =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons intType List.nil)
            stringType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .intNegSucc =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons natType List.nil)
            intType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .intNeg =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons intType List.nil)
            intType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .intAdd =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons intType
              (List.cons intType List.nil))
            intType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .intSub =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons intType
              (List.cons intType List.nil))
            intType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .intMul =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons intType
              (List.cons intType List.nil))
            intType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .intEq =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons intType
              (List.cons intType List.nil))
            boolType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .intLe =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons intType
              (List.cons intType List.nil))
            boolType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .intLt =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons intType
              (List.cons intType List.nil))
            boolType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .boolNot =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons boolType List.nil)
            boolType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .boolAnd =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons boolType
              (List.cons boolType List.nil))
            boolType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .boolOr =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons boolType
              (List.cons boolType List.nil))
            boolType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .boolEq =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons boolType
              (List.cons boolType List.nil))
            boolType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .boolNe =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons boolType
              (List.cons boolType List.nil))
            boolType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .charOfNat =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons natType List.nil)
            charType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .charToNat =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons charType List.nil)
            natType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .stringPush =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons stringType
              (List.cons charType List.nil))
            stringType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .stringSingleton =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons charType List.nil)
            stringType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .stringLength =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons stringType List.nil)
            natType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .stringUtf8ByteSize =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons stringType List.nil)
            natType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .stringAppend =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons stringType
              (List.cons stringType List.nil))
            stringType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .stringEq =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons stringType
              (List.cons stringType List.nil))
            boolType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .stringNext =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons stringType
              (List.cons natType List.nil))
            natType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .stringGet =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons stringType
              (List.cons natType List.nil))
            charType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .stringAtEnd =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons stringType
              (List.cons natType List.nil))
            boolType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .stringExtract =>
      if psStrictNoTypeArguments typeArguments then
        Except.ok
          (Prod.mk
            (List.cons stringType
              (List.cons natType
                (List.cons natType List.nil)))
            stringType)
      else
        Except.error
          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
  | .arrayEmptyWithCapacity =>
      match psStrictExactOneTypeArgument typeArguments with
      | Option.none =>
          Except.error
            PsVerifiedIrValidationError.intrinsicTypeArgumentArity
      | Option.some elementType =>
          Except.ok
            (Prod.mk
              (List.cons natType List.nil)
              (psStrictArrayType elementType))
  | .arraySize =>
      match psStrictExactOneTypeArgument typeArguments with
      | Option.none =>
          Except.error
            PsVerifiedIrValidationError.intrinsicTypeArgumentArity
      | Option.some elementType =>
          Except.ok
            (Prod.mk
              (List.cons
                (psStrictArrayType elementType)
                List.nil)
              natType)
  | .arrayPush =>
      match psStrictExactOneTypeArgument typeArguments with
      | Option.none =>
          Except.error
            PsVerifiedIrValidationError.intrinsicTypeArgumentArity
      | Option.some elementType =>
          Except.ok
            (Prod.mk
              (List.cons
                (psStrictArrayType elementType)
                (List.cons elementType List.nil))
              (psStrictArrayType elementType))
  | .arrayGet =>
      match psStrictExactOneTypeArgument typeArguments with
      | Option.none =>
          Except.error
            PsVerifiedIrValidationError.intrinsicTypeArgumentArity
      | Option.some elementType =>
          Except.ok
            (Prod.mk
              (List.cons
                (psStrictArrayType elementType)
                (List.cons natType List.nil))
              elementType)
  | .arrayGetD =>
      match psStrictExactOneTypeArgument typeArguments with
      | Option.none =>
          Except.error
            PsVerifiedIrValidationError.intrinsicTypeArgumentArity
      | Option.some elementType =>
          Except.ok
            (Prod.mk
              (List.cons
                (psStrictArrayType elementType)
                (List.cons natType
                  (List.cons elementType List.nil)))
              elementType)
  | .arraySet =>
      match psStrictExactOneTypeArgument typeArguments with
      | Option.none =>
          Except.error
            PsVerifiedIrValidationError.intrinsicTypeArgumentArity
      | Option.some elementType =>
          Except.ok
            (Prod.mk
              (List.cons
                (psStrictArrayType elementType)
                (List.cons natType
                  (List.cons elementType List.nil)))
              (psStrictArrayType elementType))
  | .arraySetIfInBounds =>
      match psStrictExactOneTypeArgument typeArguments with
      | Option.none =>
          Except.error
            PsVerifiedIrValidationError.intrinsicTypeArgumentArity
      | Option.some elementType =>
          Except.ok
            (Prod.mk
              (List.cons
                (psStrictArrayType elementType)
                (List.cons natType
                  (List.cons elementType List.nil)))
              (psStrictArrayType elementType))
  | .arrayMap =>
      match psStrictExactTwoTypeArguments typeArguments with
      | Option.none =>
          Except.error
            PsVerifiedIrValidationError.intrinsicTypeArgumentArity
      | Option.some pair =>
          let inputType : PsVerifiedIrType := Prod.fst pair;
          let outputType : PsVerifiedIrType := Prod.snd pair;
          let fnType : PsVerifiedIrType :=
            PsVerifiedIrType.function
              (List.cons inputType List.nil)
              outputType;
          Except.ok
            (Prod.mk
              (List.cons fnType
                (List.cons
                  (psStrictArrayType inputType)
                  List.nil))
              (psStrictArrayType outputType))
  | .arrayFoldl =>
      match psStrictExactTwoTypeArguments typeArguments with
      | Option.none =>
          Except.error
            PsVerifiedIrValidationError.intrinsicTypeArgumentArity
      | Option.some pair =>
          let elementType : PsVerifiedIrType := Prod.fst pair;
          let accumulatorType : PsVerifiedIrType := Prod.snd pair;
          let fnType : PsVerifiedIrType :=
            PsVerifiedIrType.function
              (List.cons accumulatorType
                (List.cons elementType List.nil))
              accumulatorType;
          Except.ok
            (Prod.mk
              (List.cons fnType
                (List.cons accumulatorType
                  (List.cons
                    (psStrictArrayType elementType)
                    (List.cons natType
                      (List.cons natType List.nil)))))
              accumulatorType)

def psStrictLiteralType
    (literal : PsVerifiedIrLiteral) :
    PsVerifiedIrType :=
  match literal with
  | .natural _ => PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
  | .integer _ => PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int
  | .machineInteger type _ =>
      psStrictMachinePrimitive type
  | .string _ => PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.string
  | .bool _ => PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
  | .unit => PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.unit

def psStrictCheckArgumentsWith
    (infer :
      PsVerifiedIrExpr ->
        Except PsVerifiedIrValidationError PsVerifiedIrType)
    (expected : List PsVerifiedIrType) :
    List PsVerifiedIrExpr ->
    Except PsVerifiedIrValidationError Unit :=
  match expected with
  | List.nil =>
      fun (arguments : List PsVerifiedIrExpr) =>
        match arguments with
        | List.nil => Except.ok Unit.unit
        | List.cons _ _ =>
            Except.error
              PsVerifiedIrValidationError.callArity
  | List.cons expectedHead expectedRest =>
      let smaller :
          List PsVerifiedIrExpr ->
          Except PsVerifiedIrValidationError Unit :=
        psStrictCheckArgumentsWith
          infer
          expectedRest;
      fun (arguments : List PsVerifiedIrExpr) =>
        match arguments with
        | List.nil =>
            Except.error
              PsVerifiedIrValidationError.callArity
        | List.cons argument argumentRest =>
            match infer argument with
            | Except.error error => Except.error error
            | Except.ok actualType =>
                if
                    psStrictTypeEq
                      expectedHead
                      actualType then
                  smaller argumentRest
                else
                  Except.error
                    PsVerifiedIrValidationError.expressionTypeMismatch

def psStrictFindGlobalValueType
    (module : PsVerifiedIrModule)
    (name : String) :
    Option PsVerifiedIrType :=
  match psStrictFindImport module.imports name with
  | Option.some importInfo =>
      Option.some importInfo.type
  | Option.none =>
      match
          psStrictFindDeclaration
            module.declarations
            name with
      | Option.none => Option.none
      | Option.some declaration =>
          match declaration.typeParameters with
          | List.nil =>
              Option.some
                (psStrictDeclarationType declaration)
          | List.cons _ _ =>
              Option.none

def psStrictCheckStructureFieldsWith
    (infer :
      PsVerifiedIrExpr ->
        Except PsVerifiedIrValidationError PsVerifiedIrType)
    (structureName : String)
    (substitution : List (String × PsVerifiedIrType))
    (expected : List PsVerifiedIrStructureField)
    (actual : List (String × PsVerifiedIrExpr)) :
    Except PsVerifiedIrValidationError Unit :=
  match expected with
  | List.nil => Except.ok Unit.unit
  | List.cons field rest =>
      match psStrictFindExprField actual field.name with
      | Option.none =>
          Except.error
            (PsVerifiedIrValidationError.fieldCompleteness
              structureName)
      | Option.some value =>
          match infer value with
          | Except.error error => Except.error error
          | Except.ok actualType =>
              let expectedType : PsVerifiedIrType :=
                psStrictSubstituteType
                  substitution
                  field.type;
              if psStrictTypeEq expectedType actualType then
                psStrictCheckStructureFieldsWith
                  infer
                  structureName
                  substitution
                  rest
                  actual
              else
                Except.error
                  PsVerifiedIrValidationError.expressionTypeMismatch

def psStrictCheckConstructorFieldsWith
    (infer :
      PsVerifiedIrExpr ->
        Except PsVerifiedIrValidationError PsVerifiedIrType)
    (inductiveName constructorName : String)
    (substitution : List (String × PsVerifiedIrType))
    (expected : List PsVerifiedIrConstructorField)
    (actual : List (String × PsVerifiedIrExpr)) :
    Except PsVerifiedIrValidationError Unit :=
  match expected with
  | List.nil => Except.ok Unit.unit
  | List.cons field rest =>
      match psStrictFindExprField actual field.name with
      | Option.none =>
          Except.error
            (PsVerifiedIrValidationError.fieldCompleteness
              constructorName)
      | Option.some value =>
          match infer value with
          | Except.error error => Except.error error
          | Except.ok actualType =>
              let expectedType : PsVerifiedIrType :=
                psStrictSubstituteType
                  substitution
                  field.type;
              if psStrictTypeEq expectedType actualType then
                psStrictCheckConstructorFieldsWith
                  infer
                  inductiveName
                  constructorName
                  substitution
                  rest
                  actual
              else
                Except.error
                  PsVerifiedIrValidationError.expressionTypeMismatch

def psStrictValidateBindingFieldTypes
    (constructorName : String)
    (substitution : List (String × PsVerifiedIrType))
    (fields : List PsVerifiedIrConstructorField)
    (bindings : List PsVerifiedIrMatchBinding) :
    Except PsVerifiedIrValidationError Unit :=
  match fields with
  | List.nil => Except.ok Unit.unit
  | List.cons field rest =>
      match psStrictFindBinding bindings field.name with
      | Option.none =>
          Except.error
            (PsVerifiedIrValidationError.fieldCompleteness
              constructorName)
      | Option.some binding =>
          let expectedType : PsVerifiedIrType :=
            psStrictSubstituteType
              substitution
              field.type;
          if psStrictTypeEq expectedType binding.type then
            psStrictValidateBindingFieldTypes
              constructorName
              substitution
              rest
              bindings
          else
            Except.error
              PsVerifiedIrValidationError.expressionTypeMismatch

def psStrictValidateBindingsAgainstFields
    (constructorName : String)
    (substitution : List (String × PsVerifiedIrType))
    (fields : List PsVerifiedIrConstructorField)
    (bindings : List PsVerifiedIrMatchBinding) :
    Except PsVerifiedIrValidationError Unit :=
  if
      psStrictStringListUnique
        (psStrictBindingFieldNames bindings) then
    if
        psStrictStringListUnique
          (psStrictBindingNames bindings) then
      if
          Nat.beq
            (psVerifiedIrListLength fields)
            (psVerifiedIrListLength bindings) then
        psStrictValidateBindingFieldTypes
          constructorName
          substitution
          fields
          bindings
      else
        Except.error
          (PsVerifiedIrValidationError.fieldCompleteness
            constructorName)
    else
      Except.error
        (PsVerifiedIrValidationError.duplicateParameter
          constructorName)
  else
    Except.error
      (PsVerifiedIrValidationError.duplicateField
        constructorName
        "")

def psStrictInferMatchAlternativeWith
    (infer :
      List (String × PsVerifiedIrType) ->
      PsVerifiedIrExpr ->
        Except PsVerifiedIrValidationError PsVerifiedIrType)
    (locals : List (String × PsVerifiedIrType))
    (inductiveName : String)
    (substitution : List (String × PsVerifiedIrType))
    (constructors : List PsVerifiedIrConstructor)
    (alternative :
      String ×
        List PsVerifiedIrMatchBinding ×
        PsVerifiedIrExpr) :
    Except PsVerifiedIrValidationError PsVerifiedIrType :=
  let constructorName : String := Prod.fst alternative;
  let payload :
      List PsVerifiedIrMatchBinding × PsVerifiedIrExpr :=
    Prod.snd alternative;
  let bindings : List PsVerifiedIrMatchBinding :=
    Prod.fst payload;
  let body : PsVerifiedIrExpr := Prod.snd payload;
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
          psStrictValidateBindingsAgainstFields
            constructorName
            substitution
            constructorInfo.fields
            bindings with
      | Except.error error => Except.error error
      | Except.ok _ =>
          infer
            (psStrictAddBindings bindings locals)
            body

def psStrictCheckRemainingAlternativesWith
    (infer :
      List (String × PsVerifiedIrType) ->
      PsVerifiedIrExpr ->
        Except PsVerifiedIrValidationError PsVerifiedIrType)
    (locals : List (String × PsVerifiedIrType))
    (inductiveName : String)
    (substitution : List (String × PsVerifiedIrType))
    (constructors : List PsVerifiedIrConstructor)
    (expectedType : PsVerifiedIrType)
    (alternatives :
      List
        (String ×
          List PsVerifiedIrMatchBinding ×
          PsVerifiedIrExpr)) :
    Except PsVerifiedIrValidationError Unit :=
  match alternatives with
  | List.nil => Except.ok Unit.unit
  | List.cons alternative rest =>
      match
          psStrictInferMatchAlternativeWith
            infer
            locals
            inductiveName
            substitution
            constructors
            alternative with
      | Except.error error => Except.error error
      | Except.ok actualType =>
          if psStrictTypeEq expectedType actualType then
            psStrictCheckRemainingAlternativesWith
              infer
              locals
              inductiveName
              substitution
              constructors
              expectedType
              rest
          else
            Except.error
              PsVerifiedIrValidationError.expressionTypeMismatch

def psStrictAllConstructorsCovered
    (constructors : List PsVerifiedIrConstructor)
    (alternatives :
      List
        (String ×
          List PsVerifiedIrMatchBinding ×
          PsVerifiedIrExpr)) :
    Bool :=
  match constructors with
  | List.nil => true
  | List.cons constructorInfo rest =>
      match
          psStrictFindAlternative
            alternatives
            constructorInfo.name with
      | Option.none => false
      | Option.some _ =>
          psStrictAllConstructorsCovered
            rest
            alternatives

def psStrictInferExprWithFuel
    (module : PsVerifiedIrModule)
    (typeParameters : List String)
    (fuel : Nat) :
    List (String × PsVerifiedIrType) ->
    PsVerifiedIrExpr ->
      Except PsVerifiedIrValidationError PsVerifiedIrType :=
  match fuel with
  | Nat.zero =>
      fun
        (_locals : List (String × PsVerifiedIrType))
        (_expr : PsVerifiedIrExpr) =>
        Except.error
          PsVerifiedIrValidationError.validationFuelExhausted
  | Nat.succ remaining =>
      let smaller :
          List (String × PsVerifiedIrType) ->
          PsVerifiedIrExpr ->
            Except PsVerifiedIrValidationError PsVerifiedIrType :=
        psStrictInferExprWithFuel
          module
          typeParameters
          remaining;
      fun
        (locals : List (String × PsVerifiedIrType))
        (expr : PsVerifiedIrExpr) =>
        let inferCurrent :
            PsVerifiedIrExpr ->
              Except PsVerifiedIrValidationError PsVerifiedIrType :=
          fun (nested : PsVerifiedIrExpr) =>
            smaller locals nested;
        match expr with
        | .literal literal =>
            match psVerifiedIrValidateLiteral literal with
            | Except.error error => Except.error error
            | Except.ok _ =>
                Except.ok (psStrictLiteralType literal)
        | .var name =>
            match psStrictLocalLookup locals name with
            | Option.some type => Except.ok type
            | Option.none =>
                match
                    psStrictFindGlobalValueType
                      module
                      name with
                | Option.some type => Except.ok type
                | Option.none =>
                    match
                        psStrictFindDeclaration
                          module.declarations
                          name with
                    | Option.some declaration =>
                        match declaration.typeParameters with
                        | List.cons _ _ =>
                            Except.error
                              (PsVerifiedIrValidationError.typeArgumentArity
                                name)
                        | List.nil =>
                            Except.error
                              (PsVerifiedIrValidationError.unknownVariable
                                name)
                    | Option.none =>
                        Except.error
                          (PsVerifiedIrValidationError.unknownVariable
                            name)
        | .intrinsic operation intrinsicTypes arguments =>
            match
                psStrictValidateTypeListInScope
                  module
                  typeParameters
                  intrinsicTypes with
            | Except.error error => Except.error error
            | Except.ok _ =>
                match
                    psStrictIntrinsicSignature
                      operation
                      intrinsicTypes with
                | Except.error error => Except.error error
                | Except.ok signature =>
                    match
                        psStrictCheckArgumentsWith
                          inferCurrent
                          (Prod.fst signature)
                          arguments with
                    | Except.error error => Except.error error
                    | Except.ok _ =>
                        Except.ok (Prod.snd signature)
        | .lambda parameters resultType body =>
            if
                psStrictStringListUnique
                  (psStrictParameterNames parameters) then
              match
                  psStrictValidateTypeListInScope
                    module
                    typeParameters
                    (psStrictParameterTypes parameters) with
              | Except.error error => Except.error error
              | Except.ok _ =>
                  match
                      psStrictValidateTypeInScope
                        module
                        typeParameters
                        resultType with
                  | Except.error error => Except.error error
                  | Except.ok _ =>
                      let nextLocals :
                          List (String × PsVerifiedIrType) :=
                        psStrictAddParameters
                          parameters
                          locals;
                      match smaller nextLocals body with
                      | Except.error error => Except.error error
                      | Except.ok bodyType =>
                          if psStrictTypeEq bodyType resultType then
                            Except.ok
                              (PsVerifiedIrType.function
                                (psStrictParameterTypes parameters)
                                resultType)
                          else
                            Except.error
                              PsVerifiedIrValidationError.expressionTypeMismatch
            else
              Except.error
                (PsVerifiedIrValidationError.duplicateParameter
                  "lambda")
        | .call fn callTypeArguments arguments =>
            match fn with
            | .var name =>
                match psStrictLocalLookup locals name with
                | Option.some localType =>
                    match callTypeArguments with
                    | List.cons _ _ =>
                        Except.error
                          PsVerifiedIrValidationError.intrinsicTypeArgumentArity
                    | List.nil =>
                        match localType with
                        | .function expected result =>
                            match
                                psStrictCheckArgumentsWith
                                  inferCurrent
                                  expected
                                  arguments with
                            | Except.error error => Except.error error
                            | Except.ok _ => Except.ok result
                        | _ =>
                            Except.error
                              PsVerifiedIrValidationError.expressionTypeMismatch
                | Option.none =>
                    match
                        psStrictFindDeclaration
                          module.declarations
                          name with
                    | Option.some declaration =>
                        match
                            psStrictValidateTypeListInScope
                              module
                              typeParameters
                              callTypeArguments with
                        | Except.error error => Except.error error
                        | Except.ok _ =>
                            if
                                psVerifiedIrTypeArgumentArityMatches
                                  declaration.typeParameters
                                  callTypeArguments then
                              match
                                  psStrictBuildSubstitution
                                    declaration.typeParameters
                                    callTypeArguments with
                              | Except.error error => Except.error error
                              | Except.ok substitution =>
                                  let callableType :
                                      PsVerifiedIrType :=
                                    psStrictSubstituteType
                                      substitution
                                      (psStrictDeclarationType
                                        declaration);
                                  match callableType with
                                  | .function expected result =>
                                      match
                                          psStrictCheckArgumentsWith
                                            inferCurrent
                                            expected
                                            arguments with
                                      | Except.error error =>
                                          Except.error error
                                      | Except.ok _ =>
                                          Except.ok result
                                  | _ =>
                                      match arguments with
                                      | List.nil =>
                                          Except.error
                                            PsVerifiedIrValidationError.callArity
                                      | List.cons _ _ =>
                                          Except.error
                                            PsVerifiedIrValidationError.expressionTypeMismatch
                            else
                              Except.error
                                (PsVerifiedIrValidationError.typeArgumentArity
                                  name)
                    | Option.none =>
                        match
                            psStrictFindImport
                              module.imports
                              name with
                        | Option.some importInfo =>
                            match callTypeArguments with
                            | List.cons _ _ =>
                                Except.error
                                  PsVerifiedIrValidationError.intrinsicTypeArgumentArity
                            | List.nil =>
                                match importInfo.type with
                                | .function expected result =>
                                    match
                                        psStrictCheckArgumentsWith
                                          inferCurrent
                                          expected
                                          arguments with
                                    | Except.error error =>
                                        Except.error error
                                    | Except.ok _ =>
                                        Except.ok result
                                | _ =>
                                    Except.error
                                      PsVerifiedIrValidationError.expressionTypeMismatch
                        | Option.none =>
                            Except.error
                              (PsVerifiedIrValidationError.unknownVariable
                                name)
            | _ =>
                match callTypeArguments with
                | List.cons _ _ =>
                    Except.error
                      PsVerifiedIrValidationError.intrinsicTypeArgumentArity
                | List.nil =>
                    match inferCurrent fn with
                    | Except.error error => Except.error error
                    | Except.ok fnType =>
                        match fnType with
                        | .function expected result =>
                            match
                                psStrictCheckArgumentsWith
                                  inferCurrent
                                  expected
                                  arguments with
                            | Except.error error => Except.error error
                            | Except.ok _ => Except.ok result
                        | _ =>
                            Except.error
                              PsVerifiedIrValidationError.expressionTypeMismatch
        | .letE name type value body =>
            match
                psStrictValidateTypeInScope
                  module
                  typeParameters
                  type with
            | Except.error error => Except.error error
            | Except.ok _ =>
                match inferCurrent value with
                | Except.error error => Except.error error
                | Except.ok valueType =>
                    if psStrictTypeEq type valueType then
                      smaller
                        (List.cons
                          (Prod.mk name type)
                          locals)
                        body
                    else
                      Except.error
                        PsVerifiedIrValidationError.expressionTypeMismatch
        | .ifE condition thenBranch elseBranch =>
            match inferCurrent condition with
            | Except.error error => Except.error error
            | Except.ok conditionType =>
                if
                    psStrictTypeEq
                      conditionType
                      (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool) then
                  match inferCurrent thenBranch with
                  | Except.error error => Except.error error
                  | Except.ok thenType =>
                      match inferCurrent elseBranch with
                      | Except.error error => Except.error error
                      | Except.ok elseType =>
                          if psStrictTypeEq thenType elseType then
                            Except.ok thenType
                          else
                            Except.error
                              PsVerifiedIrValidationError.expressionTypeMismatch
                else
                  Except.error
                    PsVerifiedIrValidationError.expressionTypeMismatch
        | .record structureName structureArguments fields =>
            match
                psVerifiedIrFindStructure
                  module.structures
                  structureName with
            | Option.none =>
                Except.error
                  (PsVerifiedIrValidationError.unknownStructure
                    structureName)
            | Option.some structureInfo =>
                match
                    psStrictValidateTypeListInScope
                      module
                      typeParameters
                      structureArguments with
                | Except.error error => Except.error error
                | Except.ok _ =>
                    if
                        psVerifiedIrTypeArgumentArityMatches
                          structureInfo.typeParameters
                          structureArguments then
                      if
                          psStrictStringListUnique
                            (psStrictExprFieldNames fields) then
                        if
                            Nat.beq
                              (psVerifiedIrListLength fields)
                              (psVerifiedIrListLength structureInfo.fields) then
                          match
                              psStrictBuildSubstitution
                                structureInfo.typeParameters
                                structureArguments with
                          | Except.error error => Except.error error
                          | Except.ok substitution =>
                              match
                                  psStrictCheckStructureFieldsWith
                                    inferCurrent
                                    structureName
                                    substitution
                                    structureInfo.fields
                                    fields with
                              | Except.error error => Except.error error
                              | Except.ok _ =>
                                  Except.ok
                                    (PsVerifiedIrType.named
                                      structureName
                                      structureArguments)
                        else
                          Except.error
                            (PsVerifiedIrValidationError.fieldCompleteness
                              structureName)
                      else
                        Except.error
                          (PsVerifiedIrValidationError.duplicateField
                            structureName
                            "")
                    else
                      Except.error
                        (PsVerifiedIrValidationError.typeArgumentArity
                          structureName)
        | .projection
            structureName
            structureArguments
            target
            fieldName =>
            match
                psStrictValidateTypeListInScope
                  module
                  typeParameters
                  structureArguments with
            | Except.error error => Except.error error
            | Except.ok _ =>
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
                          structureArguments then
                      match inferCurrent target with
                      | Except.error error => Except.error error
                      | Except.ok targetType =>
                          let expectedTarget :
                              PsVerifiedIrType :=
                            PsVerifiedIrType.named
                              structureName
                              structureArguments;
                          if psStrictTypeEq targetType expectedTarget then
                            match
                                psStrictFindStructureField
                                  structureInfo.fields
                                  fieldName with
                            | Option.none =>
                                Except.error
                                  (PsVerifiedIrValidationError.unknownStructureField
                                    structureName
                                    fieldName)
                            | Option.some field =>
                                match
                                    psStrictBuildSubstitution
                                      structureInfo.typeParameters
                                      structureArguments with
                                | Except.error error => Except.error error
                                | Except.ok substitution =>
                                    Except.ok
                                      (psStrictSubstituteType
                                        substitution
                                        field.type)
                          else
                            Except.error
                              PsVerifiedIrValidationError.expressionTypeMismatch
                    else
                      Except.error
                        (PsVerifiedIrValidationError.typeArgumentArity
                          structureName)

        | .constructor
            inductiveName
            constructorName
            inductiveArguments
            fields =>
            match
                psStrictValidateTypeListInScope
                  module
                  typeParameters
                  inductiveArguments with
            | Except.error error => Except.error error
            | Except.ok _ =>
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
                          inductiveArguments then
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
                          if
                              psStrictStringListUnique
                                (psStrictExprFieldNames fields) then
                            if
                                Nat.beq
                                  (psVerifiedIrListLength fields)
                                  (psVerifiedIrListLength constructorInfo.fields) then
                              match
                                  psStrictBuildSubstitution
                                    inductiveInfo.typeParameters
                                    inductiveArguments with
                              | Except.error error => Except.error error
                              | Except.ok substitution =>
                                  match
                                      psStrictCheckConstructorFieldsWith
                                        inferCurrent
                                        inductiveName
                                        constructorName
                                        substitution
                                        constructorInfo.fields
                                        fields with
                                  | Except.error error => Except.error error
                                  | Except.ok _ =>
                                      Except.ok
                                        (PsVerifiedIrType.named
                                          inductiveName
                                          inductiveArguments)
                            else
                              Except.error
                                (PsVerifiedIrValidationError.fieldCompleteness
                                  constructorName)
                          else
                            Except.error
                              (PsVerifiedIrValidationError.duplicateField
                                constructorName
                                "")
                    else
                      Except.error
                        (PsVerifiedIrValidationError.typeArgumentArity
                          inductiveName)

        | .matchE
            inductiveName
            inductiveArguments
            scrutinee
            alternatives =>
            match
                psStrictValidateTypeListInScope
                  module
                  typeParameters
                  inductiveArguments with
            | Except.error error => Except.error error
            | Except.ok _ =>
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
                          inductiveArguments then
                      match inferCurrent scrutinee with
                      | Except.error error => Except.error error
                      | Except.ok scrutineeType =>
                          let expectedScrutinee :
                              PsVerifiedIrType :=
                            PsVerifiedIrType.named
                              inductiveName
                              inductiveArguments;
                          if
                              psStrictTypeEq
                                scrutineeType
                                expectedScrutinee then
                            if
                                psStrictStringListUnique
                                  (psStrictAlternativeNames alternatives) then
                              if
                                  Nat.beq
                                    (psVerifiedIrListLength alternatives)
                                    (psVerifiedIrListLength
                                      inductiveInfo.constructors) then
                                match alternatives with
                                | List.nil =>
                                    Except.error
                                      PsVerifiedIrValidationError.emptyMatch
                                | List.cons first rest =>
                                    match
                                        psStrictBuildSubstitution
                                          inductiveInfo.typeParameters
                                          inductiveArguments with
                                    | Except.error error => Except.error error
                                    | Except.ok substitution =>
                                        match
                                            psStrictInferMatchAlternativeWith
                                              smaller
                                              locals
                                              inductiveName
                                              substitution
                                              inductiveInfo.constructors
                                              first with
                                        | Except.error error => Except.error error
                                        | Except.ok firstType =>
                                            match
                                                psStrictCheckRemainingAlternativesWith
                                                  smaller
                                                  locals
                                                  inductiveName
                                                  substitution
                                                  inductiveInfo.constructors
                                                  firstType
                                                  rest with
                                            | Except.error error => Except.error error
                                            | Except.ok _ =>
                                                if
                                                    psStrictAllConstructorsCovered
                                                      inductiveInfo.constructors
                                                      alternatives then
                                                  Except.ok firstType
                                                else
                                                  Except.error
                                                    (PsVerifiedIrValidationError.matchExhaustiveness
                                                      inductiveName)
                              else
                                Except.error
                                  (PsVerifiedIrValidationError.matchExhaustiveness
                                    inductiveName)
                            else
                              Except.error
                                (PsVerifiedIrValidationError.duplicateAlternative
                                  inductiveName)
                          else
                            Except.error
                              PsVerifiedIrValidationError.expressionTypeMismatch
                    else
                      Except.error
                        (PsVerifiedIrValidationError.typeArgumentArity
                          inductiveName)


def psStrictValidateTypeParameters
    (parameters : List PsVerifiedIrTypeParameter) :
    Except PsVerifiedIrValidationError (List String) :=
  let names : List String :=
    psStrictTypeParameterNames parameters;
  if psStrictStringListUnique names then
    Except.ok names
  else
    Except.error
      (PsVerifiedIrValidationError.duplicateTypeParameter
        "")

def psStrictValidateStructureFieldTypes
    (module : PsVerifiedIrModule)
    (typeParameters : List String)
    (fields : List PsVerifiedIrStructureField) :
    Except PsVerifiedIrValidationError Unit :=
  match fields with
  | List.nil => Except.ok Unit.unit
  | List.cons field rest =>
      match
          psStrictValidateTypeInScope
            module
            typeParameters
            field.type with
      | Except.error error => Except.error error
      | Except.ok _ =>
          psStrictValidateStructureFieldTypes
            module
            typeParameters
            rest

def psStrictValidateStructure
    (module : PsVerifiedIrModule)
    (structureInfo : PsVerifiedIrStructure) :
    Except PsVerifiedIrValidationError Unit :=
  match
      psStrictValidateTypeParameters
        structureInfo.typeParameters with
  | Except.error error => Except.error error
  | Except.ok typeParameters =>
      if
          psStrictStringListUnique
            (psStrictStructureFieldNames
              structureInfo.fields) then
        psStrictValidateStructureFieldTypes
          module
          typeParameters
          structureInfo.fields
      else
        Except.error
          (PsVerifiedIrValidationError.duplicateField
            structureInfo.name
            "")

def psStrictValidateConstructorFieldTypes
    (module : PsVerifiedIrModule)
    (typeParameters : List String)
    (fields : List PsVerifiedIrConstructorField) :
    Except PsVerifiedIrValidationError Unit :=
  match fields with
  | List.nil => Except.ok Unit.unit
  | List.cons field rest =>
      match
          psStrictValidateTypeInScope
            module
            typeParameters
            field.type with
      | Except.error error => Except.error error
      | Except.ok _ =>
          psStrictValidateConstructorFieldTypes
            module
            typeParameters
            rest

def psStrictValidateConstructor
    (module : PsVerifiedIrModule)
    (typeParameters : List String)
    (inductiveName : String)
    (constructorInfo : PsVerifiedIrConstructor) :
    Except PsVerifiedIrValidationError Unit :=
  if
      psStrictStringListUnique
        (psStrictConstructorFieldNames
          constructorInfo.fields) then
    psStrictValidateConstructorFieldTypes
      module
      typeParameters
      constructorInfo.fields
  else
    Except.error
      (PsVerifiedIrValidationError.duplicateField
        inductiveName
        "")

def psStrictValidateConstructors
    (module : PsVerifiedIrModule)
    (typeParameters : List String)
    (inductiveName : String)
    (constructors : List PsVerifiedIrConstructor) :
    Except PsVerifiedIrValidationError Unit :=
  match constructors with
  | List.nil => Except.ok Unit.unit
  | List.cons constructorInfo rest =>
      match
          psStrictValidateConstructor
            module
            typeParameters
            inductiveName
            constructorInfo with
      | Except.error error => Except.error error
      | Except.ok _ =>
          psStrictValidateConstructors
            module
            typeParameters
            inductiveName
            rest

def psStrictValidateInductive
    (module : PsVerifiedIrModule)
    (inductiveInfo : PsVerifiedIrInductive) :
    Except PsVerifiedIrValidationError Unit :=
  match
      psStrictValidateTypeParameters
        inductiveInfo.typeParameters with
  | Except.error error => Except.error error
  | Except.ok typeParameters =>
      if
          psStrictStringListUnique
            (psStrictConstructorNames
              inductiveInfo.constructors) then
        psStrictValidateConstructors
          module
          typeParameters
          inductiveInfo.name
          inductiveInfo.constructors
      else
        Except.error
          (PsVerifiedIrValidationError.duplicateGlobalName
            inductiveInfo.name)

def psStrictValidateDeclaration
    (module : PsVerifiedIrModule)
    (declaration : PsVerifiedIrDeclaration) :
    Except PsVerifiedIrValidationError Unit :=
  match
      psStrictValidateTypeParameters
        declaration.typeParameters with
  | Except.error error => Except.error error
  | Except.ok typeParameters =>
      if
          psStrictStringListUnique
            (psStrictParameterNames
              declaration.parameters) then
        match
            psStrictValidateTypeListInScope
              module
              typeParameters
              (psStrictParameterTypes
                declaration.parameters) with
        | Except.error error => Except.error error
        | Except.ok _ =>
            match
                psStrictValidateTypeInScope
                  module
                  typeParameters
                  declaration.resultType with
            | Except.error error => Except.error error
            | Except.ok _ =>
                let locals :
                    List (String × PsVerifiedIrType) :=
                  psStrictAddParameters
                    declaration.parameters
                    List.nil;
                match
                    psStrictInferExprWithFuel
                      module
                      typeParameters
                      4096
                      locals
                      declaration.body with
                | Except.error error => Except.error error
                | Except.ok bodyType =>
                    if
                        psStrictTypeEq
                          bodyType
                          declaration.resultType then
                      Except.ok Unit.unit
                    else
                      Except.error
                        PsVerifiedIrValidationError.expressionTypeMismatch
      else
        Except.error
          (PsVerifiedIrValidationError.duplicateParameter
            declaration.name)

def psStrictValidateImport
    (module : PsVerifiedIrModule)
    (importInfo : PsVerifiedIrExternalImport) :
    Except PsVerifiedIrValidationError Unit :=
  if psStringEq importInfo.localName "" then
    Except.error
      (PsVerifiedIrValidationError.invalidExternalImport
        importInfo.localName)
  else if psStringEq importInfo.source "" then
    Except.error
      (PsVerifiedIrValidationError.invalidExternalImport
        importInfo.localName)
  else if psStringEq importInfo.importedName "" then
    Except.error
      (PsVerifiedIrValidationError.invalidExternalImport
        importInfo.localName)
  else
    psStrictValidateTypeInScope
      module
      List.nil
      importInfo.type

def psStrictValidateStructureList
    (module : PsVerifiedIrModule)
    (structures : List PsVerifiedIrStructure) :
    Except PsVerifiedIrValidationError Unit :=
  match structures with
  | List.nil => Except.ok Unit.unit
  | List.cons value rest =>
      match psStrictValidateStructure module value with
      | Except.error error => Except.error error
      | Except.ok _ =>
          psStrictValidateStructureList module rest

def psStrictValidateInductiveList
    (module : PsVerifiedIrModule)
    (inductives : List PsVerifiedIrInductive) :
    Except PsVerifiedIrValidationError Unit :=
  match inductives with
  | List.nil => Except.ok Unit.unit
  | List.cons value rest =>
      match psStrictValidateInductive module value with
      | Except.error error => Except.error error
      | Except.ok _ =>
          psStrictValidateInductiveList module rest

def psStrictValidateDeclarationList
    (module : PsVerifiedIrModule)
    (declarations : List PsVerifiedIrDeclaration) :
    Except PsVerifiedIrValidationError Unit :=
  match declarations with
  | List.nil => Except.ok Unit.unit
  | List.cons value rest =>
      match psStrictValidateDeclaration module value with
      | Except.error error => Except.error error
      | Except.ok _ =>
          psStrictValidateDeclarationList module rest

def psStrictValidateImportList
    (module : PsVerifiedIrModule)
    (imports : List PsVerifiedIrExternalImport) :
    Except PsVerifiedIrValidationError Unit :=
  match imports with
  | List.nil => Except.ok Unit.unit
  | List.cons value rest =>
      match psStrictValidateImport module value with
      | Except.error error => Except.error error
      | Except.ok _ =>
          psStrictValidateImportList module rest

def psStrictCollectImportNames
    (imports : List PsVerifiedIrExternalImport) :
    List String :=
  match imports with
  | List.nil => List.nil
  | List.cons value rest =>
      List.cons value.localName
        (psStrictCollectImportNames rest)

def psStrictCollectStructureNames
    (structures : List PsVerifiedIrStructure) :
    List String :=
  match structures with
  | List.nil => List.nil
  | List.cons value rest =>
      List.cons value.name
        (psStrictCollectStructureNames rest)

def psStrictCollectInductiveNames
    (inductives : List PsVerifiedIrInductive) :
    List String :=
  match inductives with
  | List.nil => List.nil
  | List.cons value rest =>
      List.cons value.name
        (psStrictCollectInductiveNames rest)

def psStrictCollectDeclarationNames
    (declarations : List PsVerifiedIrDeclaration) :
    List String :=
  match declarations with
  | List.nil => List.nil
  | List.cons value rest =>
      List.cons value.name
        (psStrictCollectDeclarationNames rest)

def psStrictValidateGlobalNames
    (module : PsVerifiedIrModule) :
    Except PsVerifiedIrValidationError Unit :=
  let names : List String :=
    psListAppend
      (psStrictCollectImportNames module.imports)
      (psListAppend
        (psStrictCollectStructureNames module.structures)
        (psListAppend
          (psStrictCollectInductiveNames module.inductives)
          (psStrictCollectDeclarationNames module.declarations)));
  if psStrictStringListUnique (List.cons "Array" names) then
    Except.ok Unit.unit
  else
    Except.error
      (PsVerifiedIrValidationError.duplicateGlobalName "")

def psStrictValidateModule
    (module : PsVerifiedIrModule) :
    Except PsVerifiedIrValidationError Unit :=
  match psStrictValidateGlobalNames module with
  | Except.error error => Except.error error
  | Except.ok _ =>
      match psStrictValidateImportList module module.imports with
      | Except.error error => Except.error error
      | Except.ok _ =>
          match
              psStrictValidateStructureList
                module
                module.structures with
          | Except.error error => Except.error error
          | Except.ok _ =>
              match
                  psStrictValidateInductiveList
                    module
                    module.inductives with
              | Except.error error => Except.error error
              | Except.ok _ =>
                  psStrictValidateDeclarationList
                    module
                    module.declarations

def psValidateErasedIrModule
    (erased : PsErasedIrModule) :
    Except PsVerifiedIrValidationError PsValidatedIrModule :=
  match psValidateErasedIrModuleReferences erased with
  | Except.error error => Except.error error
  | Except.ok _ =>
      match psStrictValidateModule erased.raw with
      | Except.error error => Except.error error
      | Except.ok _ =>
          match erased.raw.imports with
          | List.nil => Except.ok (PsValidatedIrModule.mk erased.raw)
          | List.cons value _ =>
              Except.error (PsVerifiedIrValidationError.invalidExternalImport value.localName)
