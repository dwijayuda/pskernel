import Ps.BackendRust.Module
import Ps.BackendRust.Coverage

def psBackendRustLetFunctionResultModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
    inductives := []
    declarations := [
      {
        name := "makeAdderViaLet"
        typeParameters := []
        parameters := [
          {
            name := "offset"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType :=
          PsVerifiedIrType.function
            [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
            (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
        body :=
          PsVerifiedIrExpr.letE
            "delta"
            (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
            (PsVerifiedIrExpr.var "offset")
            (PsVerifiedIrExpr.lambda
              [
                {
                  name := "value"
                  type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
                }
              ]
              (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
              (PsVerifiedIrExpr.intrinsic
                PsVerifiedIrIntrinsic.natAdd
                [
                  PsVerifiedIrExpr.var "value",
                  PsVerifiedIrExpr.var "delta"
                ]))
      },
      {
        name := "forwardCallbackViaLet"
        typeParameters := []
        parameters := [
          {
            name := "callback"
            type :=
              PsVerifiedIrType.function
                [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
                (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
          }
        ]
        resultType :=
          PsVerifiedIrType.function
            [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
            (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
        body :=
          PsVerifiedIrExpr.letE
            "forwarded"
            (PsVerifiedIrType.function
              [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
              (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat))
            (PsVerifiedIrExpr.var "callback")
            (PsVerifiedIrExpr.var "forwarded")
      }
    ]
  }

def psTestBackendRustLetFunctionResult : Bool :=
  match psRustEmitModule psBackendRustLetFunctionResultModule with
  | Except.error _ =>
      false
  | Except.ok output =>
      output.contains
          "pub fn makeAdderViaLet(offset: PsNat) -> impl Fn(PsNat) -> PsNat + Clone"
        && output.contains
          "{ let delta = (offset).clone(); move |value: PsNat| "
        && output.contains
          "pub fn forwardCallbackViaLet(callback: impl Fn(PsNat) -> PsNat + Clone) -> impl Fn(PsNat) -> PsNat + Clone"
        && output.contains
          "{ let forwarded = (callback).clone(); forwarded }"

def psTestBackendRustCoverageLetFunctionResult : Bool :=
  let coverage :=
    psRustCoverageModule psBackendRustLetFunctionResultModule;
  Nat.beq
    (psRustCoverageLength coverage.unsupported)
    0

def psBackendRustConditionalFunctionResultModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
    inductives := []
    declarations := [
      {
        name := "chooseCallback"
        typeParameters := []
        parameters := [
          {
            name := "condition"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
          },
          {
            name := "left"
            type :=
              PsVerifiedIrType.function
                [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
                (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
          },
          {
            name := "right"
            type :=
              PsVerifiedIrType.function
                [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
                (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
          }
        ]
        resultType :=
          PsVerifiedIrType.function
            [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
            (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
        body :=
          PsVerifiedIrExpr.ifE
            (PsVerifiedIrExpr.var "condition")
            (PsVerifiedIrExpr.var "left")
            (PsVerifiedIrExpr.var "right")
      }
    ]
  }

def psTestBackendRustRejectsConditionalFunctionResult : Bool :=
  match psRustEmitModule psBackendRustConditionalFunctionResultModule with
  | Except.error (PsRustEmitError.functionResultUnsupported name) =>
      psStringEq name "chooseCallback"
  | _ =>
      false

def psBackendRustLetLambdaForwardingModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
    inductives := []
    declarations := [
      {
        name := "storeLocalClosureBeforeReturn"
        typeParameters := []
        parameters := [
          {
            name := "offset"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType :=
          PsVerifiedIrType.function
            [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
            (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
        body :=
          PsVerifiedIrExpr.letE
            "callback"
            (PsVerifiedIrType.function
              [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
              (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat))
            (PsVerifiedIrExpr.lambda
              [
                {
                  name := "value"
                  type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
                }
              ]
              (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
              (PsVerifiedIrExpr.intrinsic
                PsVerifiedIrIntrinsic.natAdd
                [
                  PsVerifiedIrExpr.var "value",
                  PsVerifiedIrExpr.var "offset"
                ]))
            (PsVerifiedIrExpr.var "callback")
      }
    ]
  }

def psTestBackendRustRejectsLetStoredClosure : Bool :=
  match psRustEmitModule psBackendRustLetLambdaForwardingModule with
  | Except.error (PsRustEmitError.functionResultUnsupported name) =>
      psStringEq name "storeLocalClosureBeforeReturn"
  | _ =>
      false

def main : IO Unit := do
  if psTestBackendRustLetFunctionResult then
    IO.println "PSC1_BACKEND_RUST_PASS: let-bound function results"
  else
    throw (IO.userError "PSC1_BACKEND_RUST_FAIL: let-bound function results")
  if psTestBackendRustCoverageLetFunctionResult then
    IO.println "PSC1_BACKEND_RUST_PASS: let-bound function result coverage"
  else
    throw (IO.userError "PSC1_BACKEND_RUST_FAIL: let-bound function result coverage")
  if psTestBackendRustRejectsConditionalFunctionResult then
    IO.println "PSC1_BACKEND_RUST_PASS: reject conditional function results"
  else
    throw (IO.userError "PSC1_BACKEND_RUST_FAIL: reject conditional function results")
  if psTestBackendRustRejectsLetStoredClosure then
    IO.println "PSC1_BACKEND_RUST_PASS: reject let-stored local closures"
  else
    throw (IO.userError "PSC1_BACKEND_RUST_FAIL: reject let-stored local closures")
  IO.println "PSC1_BACKEND_RUST_LET_FUNCTION_RESULT_TESTS: PASS"
