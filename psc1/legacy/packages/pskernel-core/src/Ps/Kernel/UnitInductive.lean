import Ps.Kernel.Admission

/- A deliberately bounded inductive fragment: one family, no term parameters or
indices, one constructor with no fields. The constructor result must check and
convert to the family at its declared universe parameters. Recursor type and
reduction metadata are derived here, never accepted from the caller. -/
inductive PsKernelUnitDeclaration where
  | declaration (name : PsKernelName) (parameters : PsKernelList PsKernelName)
      (level : PsKernelLevel) (ctorName : PsKernelName) (ctorType : PsKernelExpr)

inductive PsKernelUnitTask where
  | initial
  | parameters (remaining : PsKernelList PsKernelName) (reversed : PsKernelList PsKernelLevel)
  | reverse (remaining : PsKernelList PsKernelLevel) (levels : PsKernelList PsKernelLevel)
  | validate (levels : PsKernelList PsKernelLevel) (state : PsKernelTypeState)
  | family (levels : PsKernelList PsKernelLevel) (state : PsKernelLookupState)
  | constructorName (levels : PsKernelList PsKernelLevel) (state : PsKernelLookupState)
  | constructorType (levels : PsKernelList PsKernelLevel) (state : PsKernelTypeState)
  | constructorResult (levels : PsKernelList PsKernelLevel) (state : PsKernelConversionState)
  | fresh (levels : PsKernelList PsKernelLevel) (candidate : PsKernelNatural) (remaining : PsKernelList PsKernelName)
  | freshCompare (levels : PsKernelList PsKernelLevel) (candidate : PsKernelNatural)
      (remaining : PsKernelList PsKernelName) (work : PsKernelList PsKernelOrderTask)
  | recursorName (levels : PsKernelList PsKernelLevel) (motive : PsKernelName) (state : PsKernelLookupState)

inductive PsKernelUnitState where
  | state (environment : PsKernelList PsKernelDefinition) (declaration : PsKernelUnitDeclaration) (task : PsKernelUnitTask)

inductive PsKernelUnitStep where
  | next (state : PsKernelUnitState)
  | final (result : PsKernelAdmissionResult)

def psKernelUnitNext (env : PsKernelList PsKernelDefinition) (declaration : PsKernelUnitDeclaration)
    (task : PsKernelUnitTask) : PsKernelUnitStep :=
  PsKernelUnitStep.next (PsKernelUnitState.state env declaration task)

def psKernelUnitReject (error : PsKernelCheckError) : PsKernelUnitStep :=
  PsKernelUnitStep.final (PsKernelAdmissionResult.rejected error)

def psKernelUnitRecursorName (family : PsKernelName) : PsKernelName :=
  PsKernelName.str family (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit1 PsKernelPositive.one))))))) (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 PsKernelPositive.one))))))) (PsKernelText.byte (PsKernelNatural.positive (PsKernelPositive.bit1 (PsKernelPositive.bit1 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit0 (PsKernelPositive.bit1 PsKernelPositive.one))))))) PsKernelText.empty)))

def psKernelUnitRecursorType (family ctor : PsKernelExpr) (motive : PsKernelName) : PsKernelExpr :=
  PsKernelExpr.forallE PsKernelName.anonymous
    (PsKernelExpr.forallE PsKernelName.anonymous family
      (PsKernelExpr.sortE (PsKernelLevel.param motive)) PsKernelBinder.explicit)
    (PsKernelExpr.forallE PsKernelName.anonymous
      (PsKernelExpr.app (PsKernelExpr.bvar PsKernelNatural.zero) ctor)
      (PsKernelExpr.forallE PsKernelName.anonymous family
        (PsKernelExpr.app
          (PsKernelExpr.bvar (PsKernelNatural.positive (PsKernelPositive.bit0 PsKernelPositive.one)))
          (PsKernelExpr.bvar PsKernelNatural.zero)) PsKernelBinder.explicit)
      PsKernelBinder.explicit)
    PsKernelBinder.implicit

def psKernelUnitStep (state : PsKernelUnitState) : PsKernelUnitStep :=
  match state with
  | PsKernelUnitState.state env declaration task =>
      match declaration with
      | PsKernelUnitDeclaration.declaration name parameters level ctorName ctorType =>
          match task with
          | PsKernelUnitTask.initial =>
              match name with
              | PsKernelName.anonymous => psKernelUnitReject PsKernelCheckError.invalidName
              | _ =>
                  match ctorName with
                  | PsKernelName.anonymous => psKernelUnitReject PsKernelCheckError.invalidName
                  | _ => psKernelUnitNext env declaration (PsKernelUnitTask.parameters parameters PsKernelList.nil)
          | PsKernelUnitTask.parameters remaining reversed =>
              match remaining with
              | PsKernelList.nil => psKernelUnitNext env declaration (PsKernelUnitTask.reverse reversed PsKernelList.nil)
              | PsKernelList.cons parameter tail => psKernelUnitNext env declaration
                  (PsKernelUnitTask.parameters tail (PsKernelList.cons (PsKernelLevel.param parameter) reversed))
          | PsKernelUnitTask.reverse remaining levels =>
              match remaining with
              | PsKernelList.nil => psKernelUnitNext env declaration
                  (PsKernelUnitTask.validate levels (psKernelCheckWithParametersStart env parameters
                    (PsKernelExpr.sortE level) (PsKernelExpr.sortE (PsKernelLevel.succ level))))
              | PsKernelList.cons current tail => psKernelUnitNext env declaration
                  (PsKernelUnitTask.reverse tail (PsKernelList.cons current levels))
          | PsKernelUnitTask.validate levels current =>
              match psKernelTypeStep current with
              | PsKernelTypeStep.next next => psKernelUnitNext env declaration (PsKernelUnitTask.validate levels next)
              | PsKernelTypeStep.final result =>
                  match result with
                  | PsKernelTypeResult.done unused => psKernelUnitNext env declaration
                      (PsKernelUnitTask.family levels (PsKernelLookupState.search name env))
                  | PsKernelTypeResult.rejected error => psKernelUnitReject error
                  | _ => psKernelUnitReject PsKernelCheckError.invalidState
          | PsKernelUnitTask.family levels current =>
              match psKernelLookupStep current with
              | PsKernelLookupStep.next next => psKernelUnitNext env declaration (PsKernelUnitTask.family levels next)
              | PsKernelLookupStep.found unused => psKernelUnitReject PsKernelCheckError.duplicateName
              | PsKernelLookupStep.missing =>
                  let updated : PsKernelList PsKernelDefinition := PsKernelList.cons
                    (PsKernelDefinition.constant name parameters (PsKernelExpr.sortE level)) env;
                  psKernelUnitNext updated declaration
                    (PsKernelUnitTask.constructorName levels (PsKernelLookupState.search ctorName updated))
              | _ => psKernelUnitReject PsKernelCheckError.invalidState
          | PsKernelUnitTask.constructorName levels current =>
              match psKernelLookupStep current with
              | PsKernelLookupStep.next next => psKernelUnitNext env declaration (PsKernelUnitTask.constructorName levels next)
              | PsKernelLookupStep.found unused => psKernelUnitReject PsKernelCheckError.duplicateName
              | PsKernelLookupStep.missing => psKernelUnitNext env declaration
                  (PsKernelUnitTask.constructorType levels (psKernelCheckWithParametersStart env parameters ctorType (PsKernelExpr.sortE level)))
              | _ => psKernelUnitReject PsKernelCheckError.invalidState
          | PsKernelUnitTask.constructorType levels current =>
              match psKernelTypeStep current with
              | PsKernelTypeStep.next next => psKernelUnitNext env declaration (PsKernelUnitTask.constructorType levels next)
              | PsKernelTypeStep.final result =>
                  match result with
                  | PsKernelTypeResult.done unused => psKernelUnitNext env declaration
                      (PsKernelUnitTask.constructorResult levels
                        (psKernelConversionStart env ctorType (PsKernelExpr.constE name levels)))
                  | PsKernelTypeResult.rejected error => psKernelUnitReject error
                  | _ => psKernelUnitReject PsKernelCheckError.invalidState
          | PsKernelUnitTask.constructorResult levels current =>
              match psKernelConversionStep current with
              | PsKernelConversionStep.next next => psKernelUnitNext env declaration (PsKernelUnitTask.constructorResult levels next)
              | PsKernelConversionStep.final result =>
                  match result with
                  | PsKernelConversionResult.equal => psKernelUnitNext
                      (PsKernelList.cons (PsKernelDefinition.constant ctorName parameters ctorType) env) declaration
                      (PsKernelUnitTask.fresh levels PsKernelNatural.zero parameters)
                  | PsKernelConversionResult.different => psKernelUnitReject PsKernelCheckError.typeMismatch
                  | PsKernelConversionResult.rejected error => psKernelUnitReject error
                  | _ => psKernelUnitReject PsKernelCheckError.invalidState
          | PsKernelUnitTask.fresh levels candidate remaining =>
              match remaining with
              | PsKernelList.nil => psKernelUnitNext env declaration
                  (PsKernelUnitTask.recursorName levels (PsKernelName.num name candidate)
                    (PsKernelLookupState.search (psKernelUnitRecursorName name) env))
              | PsKernelList.cons current tail => psKernelUnitNext env declaration
                  (PsKernelUnitTask.freshCompare levels candidate tail
                    (PsKernelList.cons (PsKernelOrderTask.name (PsKernelName.num name candidate) current) PsKernelList.nil))
          | PsKernelUnitTask.freshCompare levels candidate remaining current =>
              match psKernelOrderStep current with
              | PsKernelOrderStep.next next => psKernelUnitNext env declaration
                  (PsKernelUnitTask.freshCompare levels candidate remaining next)
              | PsKernelOrderStep.done order =>
                  match order with
                  | PsKernelOrder.same => psKernelUnitNext env declaration
                      (PsKernelUnitTask.fresh levels (psKernelNaturalSucc candidate) parameters)
                  | _ => psKernelUnitNext env declaration (PsKernelUnitTask.fresh levels candidate remaining)
              | _ => psKernelUnitReject PsKernelCheckError.invalidState
          | PsKernelUnitTask.recursorName levels motive current =>
              match psKernelLookupStep current with
              | PsKernelLookupStep.next next => psKernelUnitNext env declaration (PsKernelUnitTask.recursorName levels motive next)
              | PsKernelLookupStep.found unused => psKernelUnitReject PsKernelCheckError.duplicateName
              | PsKernelLookupStep.missing => PsKernelUnitStep.final (PsKernelAdmissionResult.admitted
                  (PsKernelList.cons (PsKernelDefinition.unitRecursor (psKernelUnitRecursorName name)
                    (PsKernelList.cons motive parameters)
                    (psKernelUnitRecursorType (PsKernelExpr.constE name levels) (PsKernelExpr.constE ctorName levels) motive)
                    ctorName) env))
              | _ => psKernelUnitReject PsKernelCheckError.invalidState

def psKernelUnitStart (env : PsKernelList PsKernelDefinition) (declaration : PsKernelUnitDeclaration) : PsKernelUnitState :=
  PsKernelUnitState.state env declaration PsKernelUnitTask.initial

def psKernelUnitRun (fuel : PsKernelFuel) : PsKernelUnitState -> PsKernelAdmissionResult :=
  match fuel with
  | PsKernelFuel.stop => fun (state : PsKernelUnitState) => PsKernelAdmissionResult.outOfFuel
  | PsKernelFuel.more remaining =>
      fun (state : PsKernelUnitState) =>
        match psKernelUnitStep state with
        | PsKernelUnitStep.final result => result
        | PsKernelUnitStep.next next =>
            let smaller : PsKernelUnitState -> PsKernelAdmissionResult := psKernelUnitRun remaining;
            smaller next
