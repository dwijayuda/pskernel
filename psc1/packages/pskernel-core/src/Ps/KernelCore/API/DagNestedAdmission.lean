import Ps.KernelCore.API.DagNestedValidation

/- Private complete nested transaction. The environment stays private until
   transformed owning admission, restoration and independent restored checking
   all succeed. Publication/resource receipts remain the public dispatcher's
   job. None propagates to the original command boundary without reusing any
   provisional environment, arena suffix or semantic cache. -/
def psKernelExprV2NestedFinishValidated
    (restored : PsKernelExprV2NestedRestored)
    (attempted : Option (Except String PsKernelDagGeneratedState)) :
    Option (Except String PsKernelExprV2OrdinaryAdmissionResult) :=
  match attempted with
  | Option.none => Option.none
  | Option.some result =>
      match result with
      | Except.error error =>
          Option.some (Except.error error)
      | Except.ok owner =>
          Option.some (Except.ok (PsKernelExprV2OrdinaryAdmissionResult.mk restored.environment owner))

def psKernelExprV2NestedValidationPrefix
    (attempted : Option (Except String PsKernelDagGeneratedState)) :
    Option (Except String PsKernelDagGeneratedState) :=
  match attempted with
  | Option.none => Option.none
  | Option.some result =>
      match result with
      | Except.error error =>
          Option.some (Except.error (String.Internal.append "nested restored validation: " error))
      | Except.ok owner => Option.some (Except.ok owner)

def psKernelExprV2NestedAdmitWith
    (infer check whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (fuel : Nat) (environment : PsKernelEnvironment) (maxRecDepth maxNatSize : Nat)
    (input : PsKernelExprV2Decoded) (owner : PsKernelDagGeneratedState)
    (value : PsKernelDagInductiveGroup) :
    Option (Except String PsKernelExprV2OrdinaryAdmissionResult) :=
  match psKernelExprV2NestedTransformedWith check whnf defeq fuel environment
      maxRecDepth maxNatSize input owner value with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok checked =>
          match psKernelExprV2NestedRestore environment owner checked with
          | Except.error error => Option.some (Except.error error)
          | Except.ok restored =>
              psKernelExprV2NestedFinishValidated restored
                (psKernelExprV2NestedValidationPrefix
                  (psKernelExprV2NestedValidateRestoredWith infer check whnf defeq
                    fuel maxRecDepth maxNatSize restored))

def psKernelExprV2NestedAdmitWithFuel
    (fuel : Nat) (environment : PsKernelEnvironment) (maxRecDepth maxNatSize : Nat)
    (input : PsKernelExprV2Decoded) (owner : PsKernelDagGeneratedState)
    (value : PsKernelDagInductiveGroup) :
    Option (Except String PsKernelExprV2OrdinaryAdmissionResult) :=
  psKernelExprV2NestedAdmitWith psKernelExprV2TryInferStateWithFuel psKernelExprV2TryCheckStateWithFuel
    psKernelExprV2TryWhnfCheckStateWithFuel psKernelExprV2TryDefEqStateWithFuel
    fuel environment maxRecDepth maxNatSize input owner value
