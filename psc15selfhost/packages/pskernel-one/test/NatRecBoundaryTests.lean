import Ps.Environment.SelfHostProd
import Ps.Erasure.Expr
import Ps.BackendTs.Module

private def nat : PsExpr := .constE psNatName []
private def motive (result : PsExpr) : PsExpr :=
  .lam PsName.anonymous nat result .explicit
private def step : PsExpr :=
  .lam PsName.anonymous nat
    (.lam PsName.anonymous nat
      (.app (.app (.constE psNatAddName []) (.bvar 1)) (.bvar 0)) .explicit) .explicit

def main : IO Unit := do
  let env := psSelfHostProdPreludeEnvironment
  let scope := psErasureScopeEmpty []
  let erase := psEraseRuntimeExpr env scope
  let lower := psEraseNatRecursorApplication env scope erase
  let args := [motive nat, .lit (.natural 0), step, .lit (.natural 5)]
  let value ← match lower args with
    | .ok (.some value) => pure value
    | _ => throw (IO.userError "NAT_REC_BOUNDARY: valid closed motive failed")
  match lower [] with
  | .error .unsupportedApplication => pure ()
  | _ => throw (IO.userError "NAT_REC_BOUNDARY: malformed arity accepted")
  match lower [motive (.bvar 0), .lit (.natural 0), step, .lit (.natural 5)] with
  | .error .unsupportedRuntimeTerm => pure ()
  | _ => throw (IO.userError "NAT_REC_BOUNDARY: dependent motive accepted")
  match lower [motive (.forallE PsName.anonymous nat nat .explicit),
      .lit (.natural 0), step, .lit (.natural 5)] with
  | .error .unsupportedRuntimeTerm => pure ()
  | _ => throw (IO.userError "NAT_REC_BOUNDARY: function result accepted")
  match psTsEmitIntrinsicFromPrinted .natRec ["0n"] with
  | .error .intrinsicArity => pure ()
  | _ => throw (IO.userError "NAT_REC_BOUNDARY: malformed IR arity accepted")
  -- This recursor is beneath addition, with no currentDefinition. Its induction
  -- hypothesis must be the fold accumulator, not a recursive enclosing call.
  let nested := PsVerifiedIrExpr.intrinsic .natAdd [] [.literal (.natural 100), value]
  let ir : PsVerifiedIrModule := {
    imports := []
    structures := []
    inductives := []
    declarations := [{
      name := "nestedNatRec"
      typeParameters := []
      parameters := []
      resultType := .primitive .nat
      body := nested
    }]
  }
  let text ← match psTsEmitModule ir with
    | .ok text => pure text
    | .error _ => throw (IO.userError "NAT_REC_BOUNDARY: emitter failed")
  IO.FS.createDirAll "dist/pskernel-one/nat"
  IO.FS.writeFile "dist/pskernel-one/nat/direct.ts" text
  IO.println "PSKERNEL_ONE_NAT_BOUNDARY: PASS (positive + four fail-closed cases; nested executable emitted)"
