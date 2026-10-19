import Ps.Kernel.Data
import Ps.Kernel.Expr
import Ps.Kernel.Environment
import Ps.Kernel.TypeCheck

/- Fresh, sequential replay of closed universe-polymorphic transparent definitions.
No axiom form, self-reference, forward-reference or caller supplied environment.
A failure returns NO environment. These are internal values, not public handles. -/
inductive PsKernelAdmissionState where
  | pending (environment : PsKernelList PsKernelDefinition) (entries : PsKernelList PsKernelDefinition)
  | duplicate (environment : PsKernelList PsKernelDefinition) (entry : PsKernelDefinition)
      (rest : PsKernelList PsKernelDefinition) (state : PsKernelLookupState)
  | checking (environment : PsKernelList PsKernelDefinition) (entry : PsKernelDefinition)
      (rest : PsKernelList PsKernelDefinition) (state : PsKernelTypeState)

inductive PsKernelAdmissionResult where
  | outOfFuel
  | rejected (error : PsKernelCheckError)
  | admitted (environment : PsKernelList PsKernelDefinition)

inductive PsKernelAdmissionStep where
  | next (state : PsKernelAdmissionState)
  | final (result : PsKernelAdmissionResult)

def psKernelAdmissionReject (error : PsKernelCheckError) : PsKernelAdmissionStep :=
  PsKernelAdmissionStep.final (PsKernelAdmissionResult.rejected error)

def psKernelAdmissionStep (state : PsKernelAdmissionState) : PsKernelAdmissionStep :=
  match state with
  | PsKernelAdmissionState.pending env entries =>
      match entries with
      | PsKernelList.nil => PsKernelAdmissionStep.final (PsKernelAdmissionResult.admitted env)
      | PsKernelList.cons entry rest =>
          let name : PsKernelName := psKernelDefinitionName entry;
          match name with
          | PsKernelName.anonymous => psKernelAdmissionReject PsKernelCheckError.invalidName
          | _ => PsKernelAdmissionStep.next (PsKernelAdmissionState.duplicate env entry rest
              (PsKernelLookupState.search name env))
  | PsKernelAdmissionState.duplicate env entry rest current =>
      match psKernelLookupStep current with
      | PsKernelLookupStep.next next => PsKernelAdmissionStep.next (PsKernelAdmissionState.duplicate env entry rest next)
      | PsKernelLookupStep.found unusedEntry => psKernelAdmissionReject PsKernelCheckError.duplicateName
      | PsKernelLookupStep.invalidState => psKernelAdmissionReject PsKernelCheckError.invalidState
      | PsKernelLookupStep.missing =>
          match psKernelDefinitionBody entry with
          | PsKernelDefinitionBody.opaque => psKernelAdmissionReject PsKernelCheckError.unsupported
          | PsKernelDefinitionBody.transparent value =>
              PsKernelAdmissionStep.next (PsKernelAdmissionState.checking env entry rest
                (psKernelCheckWithParametersStart env (psKernelDefinitionParameters entry) value (psKernelDefinitionType entry)))

  | PsKernelAdmissionState.checking env entry rest current =>
      match psKernelTypeStep current with
      | PsKernelTypeStep.next next => PsKernelAdmissionStep.next (PsKernelAdmissionState.checking env entry rest next)
      | PsKernelTypeStep.final result =>
          match result with
          | PsKernelTypeResult.done unusedType =>
              PsKernelAdmissionStep.next (PsKernelAdmissionState.pending (PsKernelList.cons entry env) rest)
          | PsKernelTypeResult.rejected error => psKernelAdmissionReject error
          | _ => psKernelAdmissionReject PsKernelCheckError.invalidState

def psKernelAdmissionStart (entries : PsKernelList PsKernelDefinition) : PsKernelAdmissionState :=
  PsKernelAdmissionState.pending PsKernelList.nil entries

def psKernelAdmissionRun (fuel : PsKernelFuel) : PsKernelAdmissionState -> PsKernelAdmissionResult :=
  match fuel with
  | PsKernelFuel.stop => fun (state : PsKernelAdmissionState) => PsKernelAdmissionResult.outOfFuel
  | PsKernelFuel.more remaining =>
      fun (state : PsKernelAdmissionState) =>
        match psKernelAdmissionStep state with
        | PsKernelAdmissionStep.final result => result
        | PsKernelAdmissionStep.next next =>
            let smaller : PsKernelAdmissionState -> PsKernelAdmissionResult := psKernelAdmissionRun remaining;
            smaller next
