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

def psIrMachineIntegerFixedWidth : PsVerifiedIrMachineIntegerType → Option Nat
  | .uint8 | .int8 => some 8
  | .uint16 | .int16 => some 16
  | .uint32 | .int32 => some 32
  | .uint64 | .int64 => some 64
  | .usize | .isize => none

def psIrMachineIntegerIsSigned : PsVerifiedIrMachineIntegerType → Bool
  | .int8 | .int16 | .int32 | .int64 | .isize => true
  | _ => false

-- Lean 4.35.0 Init/System/Platform.lean proves that the native
-- platform word width is either 32 or 64 bits. The compiler must select
-- its *target* width explicitly; never infer the build host's width.
inductive PsVerifiedIrWordSize where
  | bits32
  | bits64

def psIrWordSizeBits : PsVerifiedIrWordSize → Nat
  | .bits32 => 32
  | .bits64 => 64

-- A target-sized integer has NO canonical width when the target is
-- absent. Fixed-width integers remain target-independent.
def psIrMachineIntegerWidthWithTarget
    (wordSize : Option PsVerifiedIrWordSize)
    (type : PsVerifiedIrMachineIntegerType) : Option Nat :=
  match type with
  | .usize | .isize => wordSize.map psIrWordSizeBits
  | _ => psIrMachineIntegerFixedWidth type

-- One exact range predicate, shared by the checked IR and backend lowering.
-- The representation uses canonical signed values, not wrapped source Nat
-- literals or a silently inferred 64-bit platform.
def psIrMachineIntegerLiteralInRangeWithTarget
    (wordSize : Option PsVerifiedIrWordSize)
    (type : PsVerifiedIrMachineIntegerType)
    (value : Int) : Bool :=
  match psIrMachineIntegerWidthWithTarget wordSize type with
  | none => false
  | some bits =>
      if psIrMachineIntegerIsSigned type then
        let bound : Int := Int.ofNat (2 ^ (bits - 1))
        decide (-bound ≤ value ∧ value < bound)
      else
        decide (0 ≤ value ∧ value < Int.ofNat (2 ^ bits))

-- Division truncates toward zero; /0 = 0 and %0 = the dividend.
-- Shifts reduce their second operand modulo the value width.
inductive PsVerifiedIrIntegerBinaryOp where
  | add
  | sub
  | mul
  | bitAnd
  | bitOr
  | bitXor
  | div
  | mod
  | shiftLeft
  | shiftRight

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

inductive PsVerifiedIrFloatUnaryOp where
  | neg
  | abs

inductive PsVerifiedIrFloatTestOp where
  | isNaN
  | isInf
  | isFinite

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
  | hashMix
  | stringHash
  | unsignedOfNat (type : PsVerifiedIrMachineIntegerType)
  | signedOfNat (type : PsVerifiedIrMachineIntegerType)
  | signedToUnsigned (type : PsVerifiedIrMachineIntegerType)
  | unsignedToNat (type : PsVerifiedIrMachineIntegerType)
  | machineIntBinary
      (type : PsVerifiedIrMachineIntegerType)
      (operation : PsVerifiedIrIntegerBinaryOp)
  | machineIntCompare
      (type : PsVerifiedIrMachineIntegerType)
      (operation : PsVerifiedIrIntegerCompareOp)
  -- Fixed-width IEEE conversion; nearest-even to floats, saturating/truncating to words.
  | floatConvert (source target : PsVerifiedIrFloatingType)
  | floatOfWord (type : PsVerifiedIrFloatingType) (word : PsVerifiedIrMachineIntegerType)
  | floatToWord (type : PsVerifiedIrFloatingType) (word : PsVerifiedIrMachineIntegerType)
  | floatOfBits (type : PsVerifiedIrFloatingType)
  | floatToBits (type : PsVerifiedIrFloatingType)
  | floatUnary (type : PsVerifiedIrFloatingType) (operation : PsVerifiedIrFloatUnaryOp)
  | floatTest (type : PsVerifiedIrFloatingType) (operation : PsVerifiedIrFloatTestOp)
  | floatBinary
      (type : PsVerifiedIrFloatingType)
      (operation : PsVerifiedIrFloatBinaryOp)
  | floatCompare
      (type : PsVerifiedIrFloatingType)
      (operation : PsVerifiedIrFloatCompareOp)
  | natAdd
  | natSub
  | natMul
  | natPow
  | natLog2
  | natDiv
  | natMod
  | natEq
  | natNe
  | natLe
  | natLt
  | intOfNat
  | intRepr
  | intToNat
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
  -- Sized pure sequence builder; mutable storage never escapes before completion.
  | arrayBuild
  | arrayEmptyWithCapacity
  | arraySize
  | arrayPush
  | arrayGet
  | arrayGetD
  | arraySet
  | arraySetIfInBounds
  | arrayMap
  | arrayFilter
  | arrayFoldl

structure PsVerifiedIrParameter where
  name : String
  type : PsVerifiedIrType

structure PsVerifiedIrMatchBinding where
  field : String
  name : String
  type : PsVerifiedIrType

inductive PsVerifiedIrExpr where
  | unreachable (resultType : PsVerifiedIrType)
  | panic (message : String) (resultType : PsVerifiedIrType)
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
  -- Conservative pre-erasure evidence for safe structural foreign values.
  -- Empty/absent metadata never authorizes a named aggregate export.
  foreignData : List (String × Bool) := []
  imports : List PsVerifiedIrExternalImport
  structures : List PsVerifiedIrStructure
  inductives : List PsVerifiedIrInductive
  declarations : List PsVerifiedIrDeclaration
  -- Internal checked support symbols remain reachable but are never selected
  -- as the application's public API.
  internalNames : List String := []

def psVerifiedIrModuleEmpty : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
    inductives := []
    declarations := []
  }
