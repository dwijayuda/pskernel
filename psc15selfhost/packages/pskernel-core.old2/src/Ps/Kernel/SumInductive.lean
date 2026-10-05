import Ps.Kernel.EnumInductive
import Ps.Kernel.NatInductive

/- Closed monomorphic sums. Each field is checked in the original environment,
before the family exists. Names, constructor types and the derived dependent
eliminator are checked before any environment escapes. Dispatch to the existing
Nat fragment is decided from source structure before checking, never by retrying
a rejected judgment. Every traversal and judgment uses the outer budget. -/
inductive PsKernelSumProgress where
  | progress (pending : PsKernelList PsKernelEnumConstructor)
      (current : PsKernelList PsKernelDefinition)
      (reversed : PsKernelList PsKernelSumRule) (count : PsKernelNatural)

inductive PsKernelSumMinorContext where
  | context (current : PsKernelList PsKernelDefinition)
      (pending forward : PsKernelList PsKernelSumRule)
      (count : PsKernelNatural) (body : PsKernelExpr)

inductive PsKernelSumTask where
  | initial
  | selectNat (zero successor : PsKernelEnumConstructor) (work : PsKernelList PsKernelOrderTask)
  | natAdmission (state : PsKernelNatAdmissionState)
  | familyName (state : PsKernelLookupState)
  | constructors (progress : PsKernelSumProgress)
  | constructorName (progress : PsKernelSumProgress) (name : PsKernelName)
      (type : PsKernelExpr) (state : PsKernelLookupState)
  | fields (progress : PsKernelSumProgress) (name : PsKernelName)
      (type remaining : PsKernelExpr) (reversed : PsKernelList PsKernelExpr) (count : PsKernelNatural)
  | fieldType (progress : PsKernelSumProgress) (name : PsKernelName)
      (type remaining : PsKernelExpr) (reversed : PsKernelList PsKernelExpr)
      (count : PsKernelNatural) (state : PsKernelTypeState)
  | result (progress : PsKernelSumProgress) (name : PsKernelName) (type : PsKernelExpr)
      (reversed : PsKernelList PsKernelExpr) (count : PsKernelNatural) (work : PsKernelList PsKernelOrderTask)
  | constructorType (progress : PsKernelSumProgress) (name : PsKernelName) (type : PsKernelExpr)
      (reversed : PsKernelList PsKernelExpr) (count : PsKernelNatural) (state : PsKernelTypeState)
  | recursorName (current : PsKernelList PsKernelDefinition)
      (reversed : PsKernelList PsKernelSumRule) (count : PsKernelNatural) (state : PsKernelLookupState)
  | minors (current : PsKernelList PsKernelDefinition) (pending forward : PsKernelList PsKernelSumRule)
      (count : PsKernelNatural) (body : PsKernelExpr)
  | arguments (context : PsKernelSumMinorContext) (reversed : PsKernelList PsKernelExpr)
      (index motiveIndex : PsKernelNatural) (value : PsKernelExpr)
  | minor (context : PsKernelSumMinorContext) (remaining : PsKernelList PsKernelExpr) (value : PsKernelExpr)
  | recursorType (current : PsKernelList PsKernelDefinition) (rules : PsKernelList PsKernelSumRule)
      (type : PsKernelExpr) (state : PsKernelTypeState)

inductive PsKernelSumState where
  | state (environment : PsKernelList PsKernelDefinition) (declaration : PsKernelEnumDeclaration) (task : PsKernelSumTask)

inductive PsKernelSumStep where
  | next (state : PsKernelSumState)
  | final (result : PsKernelAdmissionResult)

def psKernelSumNext (env : PsKernelList PsKernelDefinition) (declaration : PsKernelEnumDeclaration)
    (task : PsKernelSumTask) : PsKernelSumStep :=
  PsKernelSumStep.next (PsKernelSumState.state env declaration task)

def psKernelSumReject (error : PsKernelCheckError) : PsKernelSumStep :=
  PsKernelSumStep.final (PsKernelAdmissionResult.rejected error)

def psKernelSumCurrent (progress : PsKernelSumProgress) : PsKernelList PsKernelDefinition :=
  match progress with
  | PsKernelSumProgress.progress unusedPending current unusedReversed unusedCount => current

def psKernelSumFamilyName (env : PsKernelList PsKernelDefinition)
    (declaration : PsKernelEnumDeclaration) : PsKernelSumStep :=
  match declaration with
  | PsKernelEnumDeclaration.declaration name unusedParameters unusedLevel unusedConstructors =>
      psKernelSumNext env declaration (PsKernelSumTask.familyName (PsKernelLookupState.search name env))

def psKernelSumChoose (env : PsKernelList PsKernelDefinition)
    (declaration : PsKernelEnumDeclaration) : PsKernelSumStep :=
  match declaration with
  | PsKernelEnumDeclaration.declaration name unusedParameters unusedLevel constructors =>
      match constructors with
      | PsKernelList.nil => psKernelSumReject PsKernelCheckError.unsupported
      | PsKernelList.cons first tail =>
          match tail with
          | PsKernelList.nil => psKernelSumReject PsKernelCheckError.unsupported
          | PsKernelList.cons second rest =>
              match rest with
              | PsKernelList.cons unused more => psKernelSumFamilyName env declaration
              | PsKernelList.nil =>
                  match second with
                  | PsKernelEnumConstructor.ctor unusedName type =>
                      match type with
                      | PsKernelExpr.forallE unusedBinder field unusedBody unusedVisibility =>
                          match field with
                          | PsKernelExpr.constE target levels =>
                              match levels with
                              | PsKernelList.nil => psKernelSumNext env declaration
                                  (PsKernelSumTask.selectNat first second
                                    (PsKernelList.cons (PsKernelOrderTask.name target name) PsKernelList.nil))
                              | _ => psKernelSumFamilyName env declaration
                          | _ => psKernelSumFamilyName env declaration
                      | _ => psKernelSumFamilyName env declaration

def psKernelSumStep (state : PsKernelSumState) : PsKernelSumStep :=
  match state with
  | PsKernelSumState.state env declaration task =>
      match declaration with
      | PsKernelEnumDeclaration.declaration name parameters level constructors =>
          match task with
          | PsKernelSumTask.initial =>
              match name with
              | PsKernelName.anonymous => psKernelSumReject PsKernelCheckError.invalidName
              | _ =>
                  match parameters with
                  | PsKernelList.cons unused rest => psKernelSumReject PsKernelCheckError.unsupported
                  | PsKernelList.nil =>
                      match level with
                      | PsKernelLevel.succ base =>
                          match base with
                          | PsKernelLevel.zero => psKernelSumChoose env declaration
                          | _ => psKernelSumReject PsKernelCheckError.unsupported
                      | _ => psKernelSumReject PsKernelCheckError.unsupported
          | PsKernelSumTask.selectNat zero successor work =>
              match psKernelOrderStep work with
              | PsKernelOrderStep.next next => psKernelSumNext env declaration (PsKernelSumTask.selectNat zero successor next)
              | PsKernelOrderStep.done order =>
                  match order with
                  | PsKernelOrder.same =>
                      match zero with
                      | PsKernelEnumConstructor.ctor zeroName zeroType =>
                          match successor with
                          | PsKernelEnumConstructor.ctor succName succType => psKernelSumNext env declaration
                              (PsKernelSumTask.natAdmission (psKernelNatAdmissionStart env
                                (PsKernelNatDeclaration.declaration name (PsKernelExpr.sortE level)
                                  zeroName zeroType succName succType)))
                  | _ => psKernelSumFamilyName env declaration
              | _ => psKernelSumReject PsKernelCheckError.invalidState
          | PsKernelSumTask.natAdmission current =>
              match psKernelNatAdmissionStep current with
              | PsKernelNatAdmissionStep.next next => psKernelSumNext env declaration (PsKernelSumTask.natAdmission next)
              | PsKernelNatAdmissionStep.final result => PsKernelSumStep.final result
          | PsKernelSumTask.familyName current =>
              match psKernelLookupStep current with
              | PsKernelLookupStep.next next => psKernelSumNext env declaration (PsKernelSumTask.familyName next)
              | PsKernelLookupStep.found unused => psKernelSumReject PsKernelCheckError.duplicateName
              | PsKernelLookupStep.missing => psKernelSumNext env declaration
                  (PsKernelSumTask.constructors (PsKernelSumProgress.progress constructors
                    (psKernelRecordFamilyEnvironment env name) PsKernelList.nil PsKernelNatural.zero))
              | _ => psKernelSumReject PsKernelCheckError.invalidState
          | PsKernelSumTask.constructors progress =>
              match progress with
              | PsKernelSumProgress.progress pending current reversed count =>
                  match pending with
                  | PsKernelList.nil => psKernelSumNext env declaration
                      (PsKernelSumTask.recursorName current reversed count
                        (PsKernelLookupState.search (psKernelUnitRecursorName name) current))
                  | PsKernelList.cons ctor rest =>
                      match ctor with
                      | PsKernelEnumConstructor.ctor ctorName ctorType =>
                          match ctorName with
                          | PsKernelName.anonymous => psKernelSumReject PsKernelCheckError.invalidName
                          | _ => psKernelSumNext env declaration
                              (PsKernelSumTask.constructorName (PsKernelSumProgress.progress rest current reversed count)
                                ctorName ctorType (PsKernelLookupState.search ctorName current))
          | PsKernelSumTask.constructorName progress ctorName ctorType current =>
              match psKernelLookupStep current with
              | PsKernelLookupStep.next next => psKernelSumNext env declaration
                  (PsKernelSumTask.constructorName progress ctorName ctorType next)
              | PsKernelLookupStep.found unused => psKernelSumReject PsKernelCheckError.duplicateName
              | PsKernelLookupStep.missing => psKernelSumNext env declaration
                  (PsKernelSumTask.fields progress ctorName ctorType ctorType PsKernelList.nil PsKernelNatural.zero)
              | _ => psKernelSumReject PsKernelCheckError.invalidState
          | PsKernelSumTask.fields progress ctorName ctorType remaining reversed count =>
              match remaining with
              | PsKernelExpr.forallE unusedName field body unusedBinder => psKernelSumNext env declaration
                  (PsKernelSumTask.fieldType progress ctorName ctorType body
                    (PsKernelList.cons field reversed) (psKernelNaturalSucc count)
                    (psKernelCheckStart env field psKernelEnumType))
              | PsKernelExpr.constE resultName resultLevels =>
                  match resultLevels with
                  | PsKernelList.nil => psKernelSumNext env declaration
                      (PsKernelSumTask.result progress ctorName ctorType reversed count
                        (PsKernelList.cons (PsKernelOrderTask.name resultName name) PsKernelList.nil))
                  | _ => psKernelSumReject PsKernelCheckError.invalidUniverse
              | _ => psKernelSumReject PsKernelCheckError.typeMismatch
          | PsKernelSumTask.fieldType progress ctorName ctorType remaining reversed count current =>
              match psKernelTypeStep current with
              | PsKernelTypeStep.next next => psKernelSumNext env declaration
                  (PsKernelSumTask.fieldType progress ctorName ctorType remaining reversed count next)
              | PsKernelTypeStep.final result =>
                  match result with
                  | PsKernelTypeResult.done unused => psKernelSumNext env declaration
                      (PsKernelSumTask.fields progress ctorName ctorType remaining reversed count)
                  | PsKernelTypeResult.rejected error => psKernelSumReject error
                  | _ => psKernelSumReject PsKernelCheckError.invalidState
          | PsKernelSumTask.result progress ctorName ctorType reversed count work =>
              match psKernelOrderStep work with
              | PsKernelOrderStep.next next => psKernelSumNext env declaration
                  (PsKernelSumTask.result progress ctorName ctorType reversed count next)
              | PsKernelOrderStep.done order =>
                  match order with
                  | PsKernelOrder.same => psKernelSumNext env declaration
                      (PsKernelSumTask.constructorType progress ctorName ctorType reversed count
                        (psKernelCheckStart (psKernelSumCurrent progress) ctorType psKernelEnumType))
                  | _ => psKernelSumReject PsKernelCheckError.typeMismatch
              | _ => psKernelSumReject PsKernelCheckError.invalidState
          | PsKernelSumTask.constructorType progress ctorName ctorType reversed fields current =>
              match psKernelTypeStep current with
              | PsKernelTypeStep.next next => psKernelSumNext env declaration
                  (PsKernelSumTask.constructorType progress ctorName ctorType reversed fields next)
              | PsKernelTypeStep.final result =>
                  match result with
                  | PsKernelTypeResult.done unused =>
                      match progress with
                      | PsKernelSumProgress.progress pending entries rules count => psKernelSumNext env declaration
                          (PsKernelSumTask.constructors (PsKernelSumProgress.progress pending
                            (PsKernelList.cons (PsKernelDefinition.constant ctorName PsKernelList.nil ctorType) entries)
                            (PsKernelList.cons (PsKernelSumRule.rule ctorName reversed fields) rules) (psKernelNaturalSucc count)))
                  | PsKernelTypeResult.rejected error => psKernelSumReject error
                  | _ => psKernelSumReject PsKernelCheckError.invalidState
          | PsKernelSumTask.recursorName current reversed count lookup =>
              match psKernelLookupStep lookup with
              | PsKernelLookupStep.next next => psKernelSumNext env declaration
                  (PsKernelSumTask.recursorName current reversed count next)
              | PsKernelLookupStep.found unused => psKernelSumReject PsKernelCheckError.duplicateName
              | PsKernelLookupStep.missing => psKernelSumNext env declaration
                  (PsKernelSumTask.minors current reversed PsKernelList.nil count
                    (PsKernelExpr.forallE PsKernelName.anonymous (PsKernelExpr.constE name PsKernelList.nil)
                      (PsKernelExpr.app (PsKernelExpr.bvar (psKernelNaturalSucc count))
                        (PsKernelExpr.bvar PsKernelNatural.zero)) PsKernelBinder.explicit))
              | _ => psKernelSumReject PsKernelCheckError.invalidState
          | PsKernelSumTask.minors current pending forward count body =>
              match pending with
              | PsKernelList.cons rule rest =>
                  match count with
                  | PsKernelNatural.zero => psKernelSumReject PsKernelCheckError.invalidState
                  | _ =>
                      match rule with
                      | PsKernelSumRule.rule ctorName reversed fields =>
                          let next : PsKernelNatural := psKernelNaturalPred count;
                          psKernelSumNext env declaration
                            (PsKernelSumTask.arguments
                              (PsKernelSumMinorContext.context current rest (PsKernelList.cons rule forward) next body)
                              reversed fields next (PsKernelExpr.constE ctorName PsKernelList.nil))
              | PsKernelList.nil =>
                  match count with
                  | PsKernelNatural.positive unused => psKernelSumReject PsKernelCheckError.invalidState
                  | PsKernelNatural.zero =>
                      let recType : PsKernelExpr := psKernelEnumRecursorType name body;
                      psKernelSumNext env declaration (PsKernelSumTask.recursorType current forward recType
                        (PsKernelTypeState.state
                          (PsKernelTypingContext.context current (PsKernelList.cons (psKernelRecordMotive name) PsKernelList.nil))
                          (PsKernelList.cons (PsKernelTypeTask.infer PsKernelList.nil recType)
                            (PsKernelList.cons PsKernelTypeTask.reduceTop PsKernelList.nil)) PsKernelList.nil))
          | PsKernelSumTask.arguments context reversed index motiveIndex value =>
              match index with
              | PsKernelNatural.zero => psKernelSumNext env declaration
                  (PsKernelSumTask.minor context reversed (PsKernelExpr.app (PsKernelExpr.bvar motiveIndex) value))
              | _ =>
                  let next : PsKernelNatural := psKernelNaturalPred index;
                  psKernelSumNext env declaration (PsKernelSumTask.arguments context reversed next
                    (psKernelNaturalSucc motiveIndex) (PsKernelExpr.app value (PsKernelExpr.bvar next)))
          | PsKernelSumTask.minor context remaining value =>
              match remaining with
              | PsKernelList.cons field rest => psKernelSumNext env declaration
                  (PsKernelSumTask.minor context rest
                    (PsKernelExpr.forallE PsKernelName.anonymous field value PsKernelBinder.explicit))
              | PsKernelList.nil =>
                  match context with
                  | PsKernelSumMinorContext.context current pending forward count body => psKernelSumNext env declaration
                      (PsKernelSumTask.minors current pending forward count
                        (PsKernelExpr.forallE PsKernelName.anonymous value body PsKernelBinder.explicit))
          | PsKernelSumTask.recursorType current rules type typing =>
              match psKernelTypeStep typing with
              | PsKernelTypeStep.next next => psKernelSumNext env declaration
                  (PsKernelSumTask.recursorType current rules type next)
              | PsKernelTypeStep.final result =>
                  match result with
                  | PsKernelTypeResult.done inferred =>
                      match inferred with
                      | PsKernelExpr.sortE unused => PsKernelSumStep.final (PsKernelAdmissionResult.admitted
                          (PsKernelList.cons (PsKernelDefinition.sumRecursor (psKernelUnitRecursorName name)
                            (PsKernelList.cons (psKernelRecordMotive name) PsKernelList.nil) type rules) current))
                      | _ => psKernelSumReject PsKernelCheckError.typeExpected
                  | PsKernelTypeResult.rejected error => psKernelSumReject error
                  | _ => psKernelSumReject PsKernelCheckError.invalidState

def psKernelSumStart (env : PsKernelList PsKernelDefinition) (declaration : PsKernelEnumDeclaration) : PsKernelSumState :=
  PsKernelSumState.state env declaration PsKernelSumTask.initial

def psKernelSumRun (fuel : PsKernelFuel) : PsKernelSumState -> PsKernelAdmissionResult :=
  match fuel with
  | PsKernelFuel.stop => fun (state : PsKernelSumState) => PsKernelAdmissionResult.outOfFuel
  | PsKernelFuel.more remaining =>
      fun (state : PsKernelSumState) =>
        match psKernelSumStep state with
        | PsKernelSumStep.final result => result
        | PsKernelSumStep.next next =>
            let smaller : PsKernelSumState -> PsKernelAdmissionResult := psKernelSumRun remaining;
            smaller next
