import Ps.BackendTs.Module

def psBackendTsIdentityModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
    inductives := []
    declarations := [
      {
        name := "idNat"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body := PsVerifiedIrExpr.var "x"
      }
    ]
  }

def psBackendTsExpectedIdentity : String :=
  "// generated from pskernel-admitted ProofScript checked core\n" ++
  "export function idNat(x: bigint): bigint { return x; }\n"

def psTestBackendTsIdentity : Bool :=
  match psTsEmitModule psBackendTsIdentityModule with
  | Except.error _ => false
  | Except.ok output => output == psBackendTsExpectedIdentity

def psBackendTsMaybeModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
    inductives := [
      {
        name := "Maybe"
        typeParameters := [{ name := "A" }]
        constructors := [
          {
            name := "none"
            fields := []
          },
          {
            name := "some"
            fields := [
              {
                name := "value"
                type := PsVerifiedIrType.typeParameter "A"
              }
            ]
          }
        ]
      }
    ]
    declarations := [
      {
        name := "someNat"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.named
            "Maybe"
            [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
        body :=
          PsVerifiedIrExpr.constructor
            "Maybe"
            "some"
            [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
            [
              ("value", PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.natural 1))
            ]
      }
    ]
  }

def psTestBackendTsInductive : Bool :=
  match psTsEmitModule psBackendTsMaybeModule with
  | Except.error _ => false
  | Except.ok output =>
      output.contains "export type Maybe<A>"
        && output.contains "\"some\": <A>(__field0: A): Maybe<A>"
        && output.contains "export const someNat: Maybe<bigint>"
        && output.contains "Maybe[\"some\"]<bigint>(1n)"

def psBackendTsIntrinsicModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
    inductives := []
    declarations := [
      {
        name := "plusOne"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natAdd
            [
              PsVerifiedIrExpr.var "x",
              PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 1)
            ]
      }
    ]
  }

def psTestBackendTsIntrinsic : Bool :=
  match psTsEmitModule psBackendTsIntrinsicModule with
  | Except.error _ => false
  | Except.ok output =>
      output.contains "return (x + 1n);"

structure PsBackendTsNamedTest where
  name : String
  passed : Bool

def psBackendTsMachineLiteralModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
    inductives := []
    declarations := [
      {
        name := "u32Max"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint32
        body :=
          PsVerifiedIrExpr.literal
            (PsVerifiedIrLiteral.machineInteger
              PsVerifiedIrMachineIntegerType.uint32
              4294967295)
      },
      {
        name := "u64Value"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint64
        body :=
          PsVerifiedIrExpr.literal
            (PsVerifiedIrLiteral.machineInteger
              PsVerifiedIrMachineIntegerType.uint64
              42)
      }
    ]
  }

def psTestBackendTsMachineLiterals : Bool :=
  match psTsEmitModule psBackendTsMachineLiteralModule with
  | Except.error _ => false
  | Except.ok output =>
      output.contains "export const u32Max: number = 4294967295;"
        && output.contains "export const u64Value: bigint = 42n;"

def psBackendTsTargetWordLiteralModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
    inductives := []
    declarations := [
      {
        name := "word"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.usize
        body :=
          PsVerifiedIrExpr.literal
            (PsVerifiedIrLiteral.machineInteger
              PsVerifiedIrMachineIntegerType.usize
              42)
      }
    ]
  }

def psTestBackendTsTargetWordLiteralFailsClosed : Bool :=
  match psTsEmitModule psBackendTsTargetWordLiteralModule with
  | Except.error PsTsEmitError.targetWordSizeRequired => true
  | _ => false

def psBackendTsSharedNumericModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
    inductives := []
    declarations := [
      {
        name := "addU32"
        typeParameters := []
        parameters := [
          {
            name := "left"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.uint32
          },
          {
            name := "right"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.uint32
          }
        ]
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint32
        body :=
          PsVerifiedIrExpr.intrinsic
            (PsVerifiedIrIntrinsic.machineIntBinary
              PsVerifiedIrMachineIntegerType.uint32
              PsVerifiedIrIntegerBinaryOp.add)
            [
              PsVerifiedIrExpr.var "left",
              PsVerifiedIrExpr.var "right"
            ]
      },
      {
        name := "addF32"
        typeParameters := []
        parameters := [
          {
            name := "left"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.float32
          },
          {
            name := "right"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.float32
          }
        ]
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.float32
        body :=
          PsVerifiedIrExpr.intrinsic
            (PsVerifiedIrIntrinsic.floatBinary
              PsVerifiedIrFloatingType.float32
              PsVerifiedIrFloatBinaryOp.add)
            [
              PsVerifiedIrExpr.var "left",
              PsVerifiedIrExpr.var "right"
            ]
      }
    ]
  }

def psTestBackendTsSharedNumericIntrinsics : Bool :=
  match psTsEmitModule psBackendTsSharedNumericModule with
  | Except.error _ => false
  | Except.ok output =>
      output.contains "(((left + right)) >>> 0)"
        && output.contains "Math.fround((left + right))"

def psBackendTsTests : List PsBackendTsNamedTest := [
  { name := "identity module", passed := psTestBackendTsIdentity },
  { name := "generic inductive", passed := psTestBackendTsInductive },
  { name := "Nat intrinsic", passed := psTestBackendTsIntrinsic },
  { name := "machine integer literals", passed := psTestBackendTsMachineLiterals },
  { name := "target word literal fails closed", passed := psTestBackendTsTargetWordLiteralFailsClosed },
  { name := "shared numeric intrinsics", passed := psTestBackendTsSharedNumericIntrinsics }
]

def psRunBackendTsTests : List PsBackendTsNamedTest -> IO Bool
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSC1_BACKEND_TS_PASS: " ++ test.name)
      else
        IO.println ("PSC1_BACKEND_TS_FAIL: " ++ test.name)
      let restPassed ← psRunBackendTsTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psRunBackendTsTests psBackendTsTests
  if passed then
    IO.println "PSC1_BACKEND_TS_TESTS: PASS"
  else
    throw (IO.userError "PSC1_BACKEND_TS_TESTS: FAIL")
