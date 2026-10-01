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
      (arguments : List PsVerifiedIrExpr)
  | lambda
      (parameters : List PsVerifiedIrParameter)
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
      (fields : List (String × PsVerifiedIrExpr))
  | projection
      (structureName : String)
      (target : PsVerifiedIrExpr)
      (field : String)
  | constructor
      (inductiveName : String)
      (constructorName : String)
      (typeArguments : List PsVerifiedIrType)
      (fields : List (String × PsVerifiedIrExpr))
  | matchE
      (inductiveName : String)
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
