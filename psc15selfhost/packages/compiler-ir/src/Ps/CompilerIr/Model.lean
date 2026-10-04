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

def psValidateErasedIrModule
    (erased : PsErasedIrModule) :
    Except PsVerifiedIrValidationError PsValidatedIrModule :=
  if psVerifiedIrModuleResolved erased.raw then
    Except.ok (PsValidatedIrModule.mk erased.raw)
  else
    Except.error PsVerifiedIrValidationError.unresolvedRuntimeType
