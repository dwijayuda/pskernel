import Ps.KernelCore.API.Kernel

-- Test-only public API exercise. No environment or admission state is inserted
-- unchecked. The same source is compiled by Lean and PSC/backend-ts.
def psKernelJsProbeRequest (kind : Nat) : PsKernelDeclarationRequest :=
  let name := PsKernelName.str PsKernelName.anonymous "JsProbe";
  let sort0 := PsKernelExpr.sort PsKernelLevel.zero;
  let sort1 := PsKernelExpr.sort (PsKernelLevel.succ PsKernelLevel.zero);
  let value :=
    if kind == 1 then sort1
    else if kind == 2 then
      PsKernelExpr.const (PsKernelName.str PsKernelName.anonymous "Missing") List.nil
    else if kind == 3 then PsKernelExpr.bvar 0
    else sort0;
  let base := PsKernelConstantBase.mk name List.nil sort1;
  PsKernelDeclarationRequest.definitionDecl
    (PsKernelDefinitionInfo.mk base value
      (PsKernelReducibilityHints.regular 0) PsKernelDefinitionSafety.safe)

def psKernelJsProbeOutcome
    (result : Except PsKernelError PsKernelAdmissionResult) : String :=
  match result with
  | Except.ok _ => "accepted"
  | Except.error error =>
      match error with
      | PsKernelError.rejectedInvalid _ => "rejected-invalid"
      | PsKernelError.declinedUnsupported _ => "unsupported"
      | PsKernelError.resourceExhausted _ _ => "resource-exhausted"
      | PsKernelError.internalError _ => "internal-error"

def psKernelJsProbeDecision (kind : Nat) : String :=
  let resources := psKernelResourcePolicyDefault;
  match psKernelKernelSessionEmpty resources psKernelProviderDefault with
  | Except.error _ => "session-error"
  | Except.ok session =>
      if kind == 4 then
        match psKernelV1AdmitDeclaration session (psKernelJsProbeRequest 0) with
        | Except.error _ => "setup-error"
        | Except.ok admitted =>
            psKernelJsProbeOutcome
              (psKernelV1AdmitDeclaration admitted.session (psKernelJsProbeRequest 0))
      else if kind == 5 then
        psKernelJsProbeOutcome
          (psKernelV1AdmitDeclaration session (PsKernelDeclarationRequest.unsupported "probe"))
      else
        psKernelJsProbeOutcome
          (psKernelV1AdmitDeclaration session (psKernelJsProbeRequest kind))
