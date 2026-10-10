import Ps.KernelCore.Admission.Inductive.Common.Parameters

/-
Canonical parameter-opening arity assurance.

The executable worker opens exactly one checked binder per recursion step
and reverses its binder accumulator only after the final WHNF succeeds.
A successful call therefore produces exactly the requested number of
canonical parameter binders; a failed call makes no such claim.
This invariant does not assume that infer-only is a typing certificate.
-/

theorem psKernelReverseOpenBindersWorker_length
    (values acc : List PsKernelOpenBinder) :
    (psKernelReverseOpenBindersWorker values acc).length =
      values.length + acc.length := by
  induction values generalizing acc with
  | nil =>
      simp [psKernelReverseOpenBindersWorker]
  | cons head tail ih =>
      simpa [
        psKernelReverseOpenBindersWorker,
        Nat.add_assoc, Nat.add_comm, Nat.add_left_comm
      ] using (ih (List.cons head acc))

theorem psKernelReverseOpenBinders_length
    (values : List PsKernelOpenBinder) :
    (psKernelReverseOpenBinders values).length =
      values.length := by
  simpa [psKernelReverseOpenBinders] using
    (psKernelReverseOpenBindersWorker_length
      values List.nil)

theorem psKernelOpenSimpleHeaderParamsWorker_success_length
    (remainingParams fuel : Nat)
    (session : PsKernelCheckerSession)
    (type : PsKernelExpr)
    (revBinders : List PsKernelOpenBinder)
    (result : PsKernelOpenBindersResult)
    (hRun :
      psKernelOpenSimpleHeaderParamsWorker
          remainingParams fuel session type revBinders =
        Except.ok result) :
    result.binders.length =
      remainingParams + revBinders.length := by
  induction remainingParams generalizing session type revBinders with
  | zero =>
      simp only [psKernelOpenSimpleHeaderParamsWorker] at hRun
      cases hWhnf :
          psKernelSessionWhnf fuel session type with
      | error error =>
          simp [psKernelFinishOpenBindersWithWhnf, hWhnf] at hRun
      | ok reduced =>
          simp [
            psKernelFinishOpenBindersWithWhnf,
            psKernelOpenBindersResult, hWhnf
          ] at hRun
          rcases hRun with rfl
          simpa [psKernelReverseOpenBinders_length]
  | succ remaining ih =>
      simp only [psKernelOpenSimpleHeaderParamsWorker] at hRun
      cases hStep :
          psKernelOpenSimpleHeaderParamStep fuel session type with
      | error error =>
          simp [hStep] at hRun
      | ok step =>
          rcases step with ⟨pair, nextType⟩
          rcases pair with ⟨nextSession, binder⟩
          have hTail :
              psKernelOpenSimpleHeaderParamsWorker
                  remaining fuel nextSession nextType
                  (List.cons binder revBinders) =
                Except.ok result := by
            simpa [hStep] using hRun
          have hLength :=
            ih nextSession nextType
              (List.cons binder revBinders) hTail
          simpa [
            Nat.succ_eq_add_one,
            Nat.add_assoc, Nat.add_comm, Nat.add_left_comm
          ] using hLength

theorem psKernelOpenSimpleHeaderParams_success_length
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (type : PsKernelExpr)
    (numParams : Nat)
    (result : PsKernelOpenBindersResult)
    (hRun :
      psKernelOpenSimpleHeaderParams
          fuel session type numParams =
        Except.ok result) :
    result.binders.length = numParams := by
  have hWorker :
      psKernelOpenSimpleHeaderParamsWorker
          numParams fuel session type List.nil =
        Except.ok result := by
    simpa [psKernelOpenSimpleHeaderParams] using hRun
  have hLength :=
    psKernelOpenSimpleHeaderParamsWorker_success_length
      numParams fuel session type List.nil result hWorker
  simpa using hLength
