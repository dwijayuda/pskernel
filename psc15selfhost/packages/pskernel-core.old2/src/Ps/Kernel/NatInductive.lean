import Ps.Kernel.UnitInductive

/- A monomorphic strictly positive unary recursive family in Type: a nullary
constructor and a constructor taking exactly one recursive field. All types are
checked and compared before constants or a derived recursor become available.
This is not a general indexed/mutual/parameterized inductive algorithm. -/
inductive PsKernelNatDeclaration where
  | declaration (name : PsKernelName) (familyType : PsKernelExpr)
      (zeroName : PsKernelName) (zeroType : PsKernelExpr)
      (succName : PsKernelName) (succType : PsKernelExpr)

inductive PsKernelNatPhase where
  | zero
  | succ

inductive PsKernelNatAdmissionTask where
  | initial
  | familyType (state : PsKernelTypeState)
  | familySort (state : PsKernelConversionState)
  | familyName (state : PsKernelLookupState)
  | ctorName (phase : PsKernelNatPhase) (state : PsKernelLookupState)
  | ctorType (phase : PsKernelNatPhase) (state : PsKernelTypeState)
  | ctorResult (phase : PsKernelNatPhase) (state : PsKernelConversionState)
  | recursorName (state : PsKernelLookupState)

inductive PsKernelNatAdmissionState where
  | state (environment : PsKernelList PsKernelDefinition) (declaration : PsKernelNatDeclaration)
      (task : PsKernelNatAdmissionTask)

inductive PsKernelNatAdmissionStep where
  | next (state : PsKernelNatAdmissionState)
  | final (result : PsKernelAdmissionResult)

def psKernelNatFamilySort : PsKernelExpr :=
  PsKernelExpr.sortE (PsKernelLevel.succ PsKernelLevel.zero)

def psKernelNatConstructorName (declaration : PsKernelNatDeclaration) (phase : PsKernelNatPhase) : PsKernelName :=
  match declaration with
  | PsKernelNatDeclaration.declaration name familyType zeroName zeroType succName succType =>
      match phase with
      | PsKernelNatPhase.zero => zeroName
      | PsKernelNatPhase.succ => succName

def psKernelNatConstructorType (declaration : PsKernelNatDeclaration) (phase : PsKernelNatPhase) : PsKernelExpr :=
  match declaration with
  | PsKernelNatDeclaration.declaration name familyType zeroName zeroType succName succType =>
      match phase with
      | PsKernelNatPhase.zero => zeroType
      | PsKernelNatPhase.succ => succType

def psKernelNatExpectedConstructor (name : PsKernelName) (phase : PsKernelNatPhase) : PsKernelExpr :=
  let family : PsKernelExpr := PsKernelExpr.constE name PsKernelList.nil;
  match phase with
  | PsKernelNatPhase.zero => family
  | PsKernelNatPhase.succ => PsKernelExpr.forallE PsKernelName.anonymous family family PsKernelBinder.explicit

def psKernelNatRecursorType (family zero succ : PsKernelExpr) (motive : PsKernelName) : PsKernelExpr :=
  let two : PsKernelNatural := PsKernelNatural.positive (PsKernelPositive.bit0 PsKernelPositive.one);
  let three : PsKernelNatural := PsKernelNatural.positive (PsKernelPositive.bit1 PsKernelPositive.one);
  PsKernelExpr.forallE PsKernelName.anonymous
    (PsKernelExpr.forallE PsKernelName.anonymous family (PsKernelExpr.sortE (PsKernelLevel.param motive)) PsKernelBinder.explicit)
    (PsKernelExpr.forallE PsKernelName.anonymous
      (PsKernelExpr.app (PsKernelExpr.bvar PsKernelNatural.zero) zero)
      (PsKernelExpr.forallE PsKernelName.anonymous
        (PsKernelExpr.forallE PsKernelName.anonymous family
          (PsKernelExpr.forallE PsKernelName.anonymous
            (PsKernelExpr.app (PsKernelExpr.bvar two) (PsKernelExpr.bvar PsKernelNatural.zero))
            (PsKernelExpr.app (PsKernelExpr.bvar three)
              (PsKernelExpr.app succ (PsKernelExpr.bvar (PsKernelNatural.positive PsKernelPositive.one)))) PsKernelBinder.explicit)
          PsKernelBinder.explicit)
        (PsKernelExpr.forallE PsKernelName.anonymous family
          (PsKernelExpr.app (PsKernelExpr.bvar three) (PsKernelExpr.bvar PsKernelNatural.zero)) PsKernelBinder.explicit)
        PsKernelBinder.explicit)
      PsKernelBinder.explicit)
    PsKernelBinder.implicit

def psKernelNatAdmissionNext (env : PsKernelList PsKernelDefinition) (declaration : PsKernelNatDeclaration)
    (task : PsKernelNatAdmissionTask) : PsKernelNatAdmissionStep :=
  PsKernelNatAdmissionStep.next (PsKernelNatAdmissionState.state env declaration task)

def psKernelNatAdmissionReject (error : PsKernelCheckError) : PsKernelNatAdmissionStep :=
  PsKernelNatAdmissionStep.final (PsKernelAdmissionResult.rejected error)

def psKernelNatAdmissionStep (state : PsKernelNatAdmissionState) : PsKernelNatAdmissionStep :=
  match state with
  | PsKernelNatAdmissionState.state env declaration task =>
      match declaration with
      | PsKernelNatDeclaration.declaration name familyType zeroName zeroType succName succType =>
          match task with
          | PsKernelNatAdmissionTask.initial =>
              match name with
              | PsKernelName.anonymous => psKernelNatAdmissionReject PsKernelCheckError.invalidName
              | _ =>
                  match zeroName with
                  | PsKernelName.anonymous => psKernelNatAdmissionReject PsKernelCheckError.invalidName
                  | _ =>
                      match succName with
                      | PsKernelName.anonymous => psKernelNatAdmissionReject PsKernelCheckError.invalidName
                      | _ => psKernelNatAdmissionNext env declaration (PsKernelNatAdmissionTask.familyType
                          (psKernelCheckStart env familyType
                            (PsKernelExpr.sortE (PsKernelLevel.succ (PsKernelLevel.succ PsKernelLevel.zero)))))
          | PsKernelNatAdmissionTask.familyType current =>
              match psKernelTypeStep current with
              | PsKernelTypeStep.next next => psKernelNatAdmissionNext env declaration (PsKernelNatAdmissionTask.familyType next)
              | PsKernelTypeStep.final result =>
                  match result with
                  | PsKernelTypeResult.done unused => psKernelNatAdmissionNext env declaration
                      (PsKernelNatAdmissionTask.familySort (psKernelConversionStart env familyType psKernelNatFamilySort))
                  | PsKernelTypeResult.rejected error => psKernelNatAdmissionReject error
                  | _ => psKernelNatAdmissionReject PsKernelCheckError.invalidState
          | PsKernelNatAdmissionTask.familySort current =>
              match psKernelConversionStep current with
              | PsKernelConversionStep.next next => psKernelNatAdmissionNext env declaration (PsKernelNatAdmissionTask.familySort next)
              | PsKernelConversionStep.final result =>
                  match result with
                  | PsKernelConversionResult.equal => psKernelNatAdmissionNext env declaration
                      (PsKernelNatAdmissionTask.familyName (PsKernelLookupState.search name env))
                  | PsKernelConversionResult.different => psKernelNatAdmissionReject PsKernelCheckError.unsupported
                  | PsKernelConversionResult.rejected error => psKernelNatAdmissionReject error
                  | _ => psKernelNatAdmissionReject PsKernelCheckError.invalidState
          | PsKernelNatAdmissionTask.familyName current =>
              match psKernelLookupStep current with
              | PsKernelLookupStep.next next => psKernelNatAdmissionNext env declaration (PsKernelNatAdmissionTask.familyName next)
              | PsKernelLookupStep.found unused => psKernelNatAdmissionReject PsKernelCheckError.duplicateName
              | PsKernelLookupStep.missing =>
                  let updated : PsKernelList PsKernelDefinition := PsKernelList.cons
                    (PsKernelDefinition.natFamily name zeroName succName) env;
                  psKernelNatAdmissionNext updated declaration
                    (PsKernelNatAdmissionTask.ctorName PsKernelNatPhase.zero (PsKernelLookupState.search zeroName updated))
              | _ => psKernelNatAdmissionReject PsKernelCheckError.invalidState
          | PsKernelNatAdmissionTask.ctorName phase current =>
              match psKernelLookupStep current with
              | PsKernelLookupStep.next next => psKernelNatAdmissionNext env declaration (PsKernelNatAdmissionTask.ctorName phase next)
              | PsKernelLookupStep.found unused => psKernelNatAdmissionReject PsKernelCheckError.duplicateName
              | PsKernelLookupStep.missing => psKernelNatAdmissionNext env declaration
                  (PsKernelNatAdmissionTask.ctorType phase
                    (psKernelCheckStart env (psKernelNatConstructorType declaration phase) psKernelNatFamilySort))
              | _ => psKernelNatAdmissionReject PsKernelCheckError.invalidState
          | PsKernelNatAdmissionTask.ctorType phase current =>
              match psKernelTypeStep current with
              | PsKernelTypeStep.next next => psKernelNatAdmissionNext env declaration (PsKernelNatAdmissionTask.ctorType phase next)
              | PsKernelTypeStep.final result =>
                  match result with
                  | PsKernelTypeResult.done unused => psKernelNatAdmissionNext env declaration
                      (PsKernelNatAdmissionTask.ctorResult phase (psKernelConversionStart env
                        (psKernelNatConstructorType declaration phase) (psKernelNatExpectedConstructor name phase)))
                  | PsKernelTypeResult.rejected error => psKernelNatAdmissionReject error
                  | _ => psKernelNatAdmissionReject PsKernelCheckError.invalidState
          | PsKernelNatAdmissionTask.ctorResult phase current =>
              match psKernelConversionStep current with
              | PsKernelConversionStep.next next => psKernelNatAdmissionNext env declaration (PsKernelNatAdmissionTask.ctorResult phase next)
              | PsKernelConversionStep.final result =>
                  match result with
                  | PsKernelConversionResult.equal =>
                      let updated : PsKernelList PsKernelDefinition := PsKernelList.cons
                        (PsKernelDefinition.constant (psKernelNatConstructorName declaration phase) PsKernelList.nil
                          (psKernelNatConstructorType declaration phase)) env;
                      match phase with
                      | PsKernelNatPhase.zero => psKernelNatAdmissionNext updated declaration
                          (PsKernelNatAdmissionTask.ctorName PsKernelNatPhase.succ (PsKernelLookupState.search succName updated))
                      | PsKernelNatPhase.succ => psKernelNatAdmissionNext updated declaration
                          (PsKernelNatAdmissionTask.recursorName (PsKernelLookupState.search (psKernelUnitRecursorName name) updated))
                  | PsKernelConversionResult.different => psKernelNatAdmissionReject PsKernelCheckError.unsupported
                  | PsKernelConversionResult.rejected error => psKernelNatAdmissionReject error
                  | _ => psKernelNatAdmissionReject PsKernelCheckError.invalidState
          | PsKernelNatAdmissionTask.recursorName current =>
              match psKernelLookupStep current with
              | PsKernelLookupStep.next next => psKernelNatAdmissionNext env declaration (PsKernelNatAdmissionTask.recursorName next)
              | PsKernelLookupStep.found unused => psKernelNatAdmissionReject PsKernelCheckError.duplicateName
              | PsKernelLookupStep.missing =>
                  let motive : PsKernelName := PsKernelName.num name PsKernelNatural.zero;
                  PsKernelNatAdmissionStep.final (PsKernelAdmissionResult.admitted
                    (PsKernelList.cons (PsKernelDefinition.natRecursor (psKernelUnitRecursorName name)
                      (PsKernelList.cons motive PsKernelList.nil)
                      (psKernelNatRecursorType (PsKernelExpr.constE name PsKernelList.nil)
                        (PsKernelExpr.constE zeroName PsKernelList.nil) (PsKernelExpr.constE succName PsKernelList.nil) motive)
                      zeroName succName) env))
              | _ => psKernelNatAdmissionReject PsKernelCheckError.invalidState

def psKernelNatAdmissionStart (env : PsKernelList PsKernelDefinition) (declaration : PsKernelNatDeclaration) : PsKernelNatAdmissionState :=
  PsKernelNatAdmissionState.state env declaration PsKernelNatAdmissionTask.initial

def psKernelNatAdmissionRun (fuel : PsKernelFuel) : PsKernelNatAdmissionState -> PsKernelAdmissionResult :=
  match fuel with
  | PsKernelFuel.stop => fun (state : PsKernelNatAdmissionState) => PsKernelAdmissionResult.outOfFuel
  | PsKernelFuel.more remaining =>
      fun (state : PsKernelNatAdmissionState) =>
        match psKernelNatAdmissionStep state with
        | PsKernelNatAdmissionStep.final result => result
        | PsKernelNatAdmissionStep.next next =>
            let smaller : PsKernelNatAdmissionState -> PsKernelAdmissionResult := psKernelNatAdmissionRun remaining;
            smaller next
