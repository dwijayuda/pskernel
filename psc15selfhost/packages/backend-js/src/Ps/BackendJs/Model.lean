import Ps.CompilerIr.Model

inductive PsJsIrMachineIntegerType where
  | uint8
  | uint16
  | uint32
  | uint64
  | int8
  | int16
  | int32
  | int64

inductive PsJsIrIntegerBinaryOp where
  | add
  | sub
  | mul
  | bitAnd
  | bitOr
  | bitXor

inductive PsJsIrIntegerCompareOp where
  | eq
  | ne
  | lt
  | le
  | gt
  | ge

inductive PsJsIrFloatingType where
  | float
  | float32

inductive PsJsIrFloatBinaryOp where
  | add
  | sub
  | mul
  | div

inductive PsJsIrFloatCompareOp where
  | eq
  | ne
  | lt
  | le
  | gt
  | ge

inductive PsJsIrLiteral where
  | natural (value : Nat)
  | integer (value : Int)
  | machineInteger
      (type : PsJsIrMachineIntegerType)
      (value : Int)
  | string (value : String)
  | bool (value : Bool)
  | unit

inductive PsJsIrUnaryOp where
  | bigintNeg
  | boolNot

inductive PsJsIrBinaryOp where
  | bigintAdd
  | bigintSub
  | bigintMul
  | bigintEq
  | bigintNe
  | bigintLe
  | bigintLt
  | boolAnd
  | boolOr
  | boolEq
  | boolNe
  | stringConcat
  | stringEq
  | machineInt
      (type : PsJsIrMachineIntegerType)
      (operation : PsJsIrIntegerBinaryOp)
  | machineIntCompare
      (operation : PsJsIrIntegerCompareOp)
  | floatBinary
      (type : PsJsIrFloatingType)
      (operation : PsJsIrFloatBinaryOp)
  | floatCompare
      (operation : PsJsIrFloatCompareOp)

inductive PsJsIrRuntimeOp where
  | uint8OfNat
  | natSub
  | natDiv
  | natMod
  | intNegSucc
  | intRepr
  | charOfNat
  | charToNat
  | stringLength
  | stringUtf8ByteSize
  | stringNext
  | stringGet
  | stringAtEnd
  | stringExtract

inductive PsJsIrExpr where
  | literal (value : PsJsIrLiteral)
  | var (name : String)
  | unary
      (operation : PsJsIrUnaryOp)
      (value : PsJsIrExpr)
  | binary
      (operation : PsJsIrBinaryOp)
      (left right : PsJsIrExpr)
  | runtime
      (operation : PsJsIrRuntimeOp)
      (arguments : List PsJsIrExpr)
  | lambda
      (parameters : List String)
      (body : PsJsIrExpr)
  | call
      (fn : PsJsIrExpr)
      (arguments : List PsJsIrExpr)
  | letE
      (name : String)
      (value : PsJsIrExpr)
      (body : PsJsIrExpr)
  | ifE
      (condition : PsJsIrExpr)
      (thenBranch elseBranch : PsJsIrExpr)

structure PsJsIrParameter where
  name : String

structure PsJsIrDeclaration where
  name : String
  parameters : List PsJsIrParameter
  body : PsJsIrExpr

structure PsJsIrModule where
  declarations : List PsJsIrDeclaration
