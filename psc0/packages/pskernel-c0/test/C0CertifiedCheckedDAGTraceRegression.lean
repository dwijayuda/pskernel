import Ps.KernelCore.Architecture.CertifiedCheckedDAGTrace
import Ps.KernelCore.Checker.Session

/-!
The entire trace is checked by original C0 with exact source state
threading; an invalid later root must return no successful partial trace.
No handle alone, cached hash or prior certificate may skip checking.
-/

def main : IO Unit := do
  let sortZero : PsKernelExpr := .sort .zero
  let bad : PsKernelExpr := .bvar 0
  let some (firstStore, goodId) :=
      psKernelC0EncodeExpr psKernelC0StoreEmpty sortZero
    | throw (IO.userError "checked DAG trace: failed valid source encode")
  let some (store, badId) :=
      psKernelC0EncodeExpr firstStore bad
    | throw (IO.userError "checked DAG trace: failed malformed term encode")
  let some owner := psKernelC0CertifyStore store
    | throw (IO.userError "checked DAG trace: store invariant failed")
  let session := psKernelMkCheckerSession psKernelEnvironmentEmpty []
    .safe 4096 psKernelLeanNatMaxSizeDefault

  let result ← match psKernelC0CheckIndexedDAGTrace
      owner 4096 session.context session.state [goodId, goodId] with
    | .ok result => pure result
    | .error error =>
        throw (IO.userError ("checked DAG trace: valid sequence failed: " ++ error))
  let ⟨finalState, trace⟩ := result
  if psKernelC0CheckedDAGTraceIds trace != [goodId, goodId] then
    throw (IO.userError "checked DAG trace: incorrect source root ID sequence")
  -- Validate a separate exact source run through the two successive states.
  let first ← match psKernelCheckerCheck 4096 session.context session.state sortZero with
    | .ok checked => pure checked
    | .error reason =>
        throw (IO.userError ("checked DAG trace: reference first check failed: " ++ reason))
  let second ← match psKernelCheckerCheck 4096 session.context first.2 sortZero with
    | .ok checked => pure checked
    | .error reason =>
        throw (IO.userError ("checked DAG trace: reference second check failed: " ++ reason))
  if !psKernelExprEqual first.1 (.sort (.succ .zero)) ||
      !psKernelExprEqual second.1 (.sort (.succ .zero)) then
    throw (IO.userError "checked DAG trace: source type of Sort changed")
  let _finalState : PsKernelCheckerState := finalState

  match psKernelC0CheckIndexedDAGTrace
      owner 4096 session.context session.state [goodId, badId] with
  | .ok _ =>
      throw (IO.userError "checked DAG trace: invalid tail published success")
  | .error _ => pure ()
  match psKernelC0CheckIndexedDAGTrace
      owner 0 session.context session.state [goodId] with
  | .ok _ =>
      throw (IO.userError "checked DAG trace: zero checking fuel accepted")
  | .error _ => pure ()
  match psKernelC0CheckIndexedDAGTrace
      owner 4096 session.context session.state [goodId, store.nodes.size + 7] with
  | .ok _ =>
      throw (IO.userError "checked DAG trace: out-of-bounds tail accepted")
  | .error _ => pure ()
  IO.println "C0_CHECKED_DAG_TRACE state_threading=source_checked repeated_valid=accepted invalid_tail=atomic_decline zero_fuel=decline bad_handle=decline"
