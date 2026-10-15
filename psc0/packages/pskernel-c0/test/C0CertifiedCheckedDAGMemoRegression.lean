import Ps.KernelCore.Architecture.CertifiedCheckedDAGMemo
import Ps.KernelCore.Checker.Session

/-!
Exact checked DAG receipt regression. This is NOT a proof-checker shortcut:
certificate construction runs the authoritative source checker. Every result
carries Lean-checked equality to the exact source judgment at its initial
state, environment, local context, and fuel.
-/

def main : IO Unit := do
  let sortZero : PsKernelExpr := .sort .zero
  let some (store, id) := psKernelC0EncodeExpr psKernelC0StoreEmpty sortZero
    | throw (IO.userError "certified DAG: failed encoding valid expression")
  let some certifiedRoot := psKernelC0CertifyRoot store id
    | throw (IO.userError "certified DAG: valid canonical root rejected")
  let session := psKernelMkCheckerSession psKernelEnvironmentEmpty []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let receipt ← match psKernelC0CaptureCheckedDAGRoot
      4096 session.context session.state certifiedRoot with
    | .ok r => pure r
    | .error e => throw (IO.userError
        ("certified DAG: source rejected valid Sort: " ++ e))
  let _exactSource :
      psKernelCheckerCheck 4096 session.context session.state
          receipt.root.expression =
        .ok (receipt.inferredType, receipt.finalState) :=
    psKernelC0CertifiedCheckedDAGRoot_source receipt
  let _wf : psKernelC0StoreWF receipt.root.owner.store :=
    psKernelC0CertifiedCheckedDAGRoot_storeWF receipt
  let _rootEq :
      psKernelC0DecodeExpr receipt.root.owner.store receipt.root.root =
        some receipt.root.expression :=
    psKernelC0CertifiedCheckedDAGRoot_exactRead receipt
  if !psKernelExprEqual receipt.inferredType (.sort (.succ .zero)) then
    throw (IO.userError "certified DAG: incorrect source inferred type")

  -- A store certificate is only syntax: it MUST NOT make a loose bound
  -- variable a checked, admitted term.
  let some (badStore, badId) :=
      psKernelC0EncodeExpr psKernelC0StoreEmpty (.bvar 0)
    | throw (IO.userError "certified DAG: bad syntax encoding declined")
  let some badRoot := psKernelC0CertifyRoot badStore badId
    | throw (IO.userError "certified DAG: canonical raw bvar not certifiable")
  match psKernelC0CaptureCheckedDAGRoot
      4096 session.context session.state badRoot with
  | .ok _ =>
      throw (IO.userError "certified DAG: source-invalid bvar accepted")
  | .error _ => pure ()
  IO.println "C0_CERTIFIED_CHECKED_DAG owned_root=pass exact_source=pass invalid=declined"
