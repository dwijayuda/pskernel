import Ps.CompilerIr.Validate
import Ps.BackendTs.Module
import Ps.BackendJs.Lower
import Ps.BackendJs.Print

namespace TsContinuationFixture

def natT : PsVerifiedIrType := .primitive .nat
def fnT : PsVerifiedIrType := .function [natT] natT
def binaryT : PsVerifiedIrType := .function [natT,natT] natT
def providerT : PsVerifiedIrType := .function [natT] binaryT
def n (value : Nat) : PsVerifiedIrExpr := .literal (.natural value)
def v (name : String) : PsVerifiedIrExpr := .var name
def call (name : String) (args : List PsVerifiedIrExpr) : PsVerifiedIrExpr := .call (v name) [] args
def add (a b : PsVerifiedIrExpr) : PsVerifiedIrExpr := .intrinsic .natAdd [] [a,b]
def sub (a b : PsVerifiedIrExpr) : PsVerifiedIrExpr := .intrinsic .natSub [] [a,b]
def eq (a b : PsVerifiedIrExpr) : PsVerifiedIrExpr := .intrinsic .natEq [] [a,b]
def p (name : String) : PsVerifiedIrParameter := .mk name natT

-- General mutual calls cannot use the existing exact self-loop recognizer.
-- Calls nested in operands/conditions/local values must retain continuations.
def raw : PsVerifiedIrModule := .mk [] [] [] [
  .mk "even" [] [p "n"] natT
    (.ifE (eq (v "n") (n 0)) (n 1) (call "odd" [sub (v "n") (n 1)])),
  .mk "odd" [] [p "n"] natT
    (.ifE (eq (v "n") (n 0)) (n 0) (call "even" [sub (v "n") (n 1)])),
  .mk "sum" [] [p "n"] natT
    (.ifE (eq (v "n") (n 0)) (n 0)
      (add (v "n") (call "sum" [sub (v "n") (n 1)]))),
  .mk "letValue" [] [p "n"] natT
    (.letE "value" natT
      (.letE "argument" natT (add (v "n") (n 1)) (call "even" [v "argument"]))
      (add (v "value") (v "n"))),
  .mk "letTail" [] [p "n"] natT
    (.letE "argument" natT (add (v "n") (n 1)) (call "even" [v "argument"])),
  .mk "condition" [] [p "n"] natT
    (.ifE (eq (call "even" [v "n"]) (n 1)) (n 7) (n 9)),
  .mk "make" [] [p "n"] fnT
    (.lambda [p "x"] natT (call "even" [add (v "n") (v "x")])),
  .mk "capture" [] [p "n"] natT
    (.letE "saved" fnT (.lambda [p "x"] natT (add (v "n") (v "x")))
      (.letE "n" natT (n 99) (.call (v "saved") [] [n 2]))),
  .mk "ordered" [] [.mk "provider" providerT,.mk "left" fnT,.mk "right" fnT] natT
    (.call (call "provider" [n 0]) [] [call "left" [n 1],call "right" [n 2]]),
  .mk "trapTail" [] [.mk "fn" fnT] natT (call "fn" [n 0]),
  .mk "trapValue" [] [.mk "fn" fnT] natT (add (call "fn" [n 0]) (n 1)),
  .mk "spin" [] [p "n"] natT (call "spin" [v "n"]),
  .mk "strictValue" [] [p "n"] natT (.letE "unused" natT (call "spin" [v "n"]) (n 1))
]

end TsContinuationFixture

def main : IO Unit := do
  let validated ← match psStrictValidateModule TsContinuationFixture.raw with
    | .error _ =>
        let report := psCheckVerifiedIrModule psIrCheckDefaultOptions TsContinuationFixture.raw
        for finding in report.findings do
          IO.eprintln (finding.code ++ ":" ++ finding.owner ++ ":" ++ finding.path ++ ":" ++ finding.detail)
        throw (IO.userError "PSC1_TS_CONTINUATION_IR_REFUSED")
    | .ok value => pure value
  let printed ← match psTsEmitModule validated.raw with
    | .error _ => throw (IO.userError "PSC1_TS_CONTINUATION_EMISSION_REFUSED")
    | .ok value => pure value
  IO.FS.createDirAll "dist/scoped-correctness/ts-continuations"
  IO.FS.writeFile "dist/scoped-correctness/ts-continuations/raw.ts" printed
  let jsIr ← match psJsLowerSpecializedModule validated.raw with
    | .error _ => throw (IO.userError "PSC1_JS_CONTINUATION_LOWERING_REFUSED")
    | .ok value => pure value
  match psJsValidateModule jsIr with
  | .error _ => throw (IO.userError "PSC1_JS_CONTINUATION_TARGET_REFUSED")
  | .ok _ => pure ()
  let javascript ← match psJsPrintModuleStackSafe jsIr with
    | .error _ => throw (IO.userError "PSC1_JS_CONTINUATION_EMISSION_REFUSED")
    | .ok value => pure value
  IO.FS.writeFile "dist/scoped-correctness/ts-continuations/raw.js" javascript
  IO.println "PSC1_TS_CONTINUATION_FIXTURE: strict validated IR emitted; this is a backend regression, not source admission evidence"
