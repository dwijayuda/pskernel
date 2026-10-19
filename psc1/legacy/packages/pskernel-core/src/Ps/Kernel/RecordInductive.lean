import Ps.Kernel.UnitInductive

/- Bounded record admission: one monomorphic Type family, at least one closed
Type-valued constructor field, no parameters, indices, recursion or dependencies
between fields. Fields are checked in the ORIGINAL environment, before the family
exists. This excludes negative occurrences as well as all recursive occurrences.
The constructor and dependent eliminator types are checked; metadata is derived,
not supplied by the caller. Every traversal/check shares the outer step budget.
Projection and record iota reduction are deliberately not enabled by this module. -/
inductive PsKernelRecordTask where
  | initial
  | familyName (state : PsKernelLookupState)
  | fields (remaining : PsKernelExpr) (reversed : PsKernelList PsKernelExpr) (count : PsKernelNatural)
  | fieldType (remaining : PsKernelExpr) (reversed : PsKernelList PsKernelExpr)
      (count : PsKernelNatural) (state : PsKernelTypeState)
  | result (reversed : PsKernelList PsKernelExpr) (count : PsKernelNatural)
      (tasks : PsKernelList PsKernelOrderTask)
  | constructorType (reversed : PsKernelList PsKernelExpr) (count : PsKernelNatural) (state : PsKernelTypeState)
  | constructorName (reversed : PsKernelList PsKernelExpr) (count : PsKernelNatural) (state : PsKernelLookupState)
  | recursorName (reversed : PsKernelList PsKernelExpr) (count : PsKernelNatural) (state : PsKernelLookupState)
  | arguments (reversed : PsKernelList PsKernelExpr) (count index : PsKernelNatural) (value : PsKernelExpr)
  | minor (remaining fields : PsKernelList PsKernelExpr) (value : PsKernelExpr)
  | recursorType (fields : PsKernelList PsKernelExpr) (type : PsKernelExpr) (state : PsKernelTypeState)

inductive PsKernelRecordState where
  | state (environment : PsKernelList PsKernelDefinition) (declaration : PsKernelUnitDeclaration) (task : PsKernelRecordTask)

inductive PsKernelRecordStep where
  | next (state : PsKernelRecordState)
  | final (result : PsKernelAdmissionResult)

def psKernelRecordNext (env : PsKernelList PsKernelDefinition) (declaration : PsKernelUnitDeclaration)
    (task : PsKernelRecordTask) : PsKernelRecordStep :=
  PsKernelRecordStep.next (PsKernelRecordState.state env declaration task)

def psKernelRecordReject (error : PsKernelCheckError) : PsKernelRecordStep :=
  PsKernelRecordStep.final (PsKernelAdmissionResult.rejected error)

def psKernelRecordMotive (name : PsKernelName) : PsKernelName :=
  PsKernelName.num name PsKernelNatural.zero

def psKernelRecordFamilyEnvironment (env : PsKernelList PsKernelDefinition) (name : PsKernelName) : PsKernelList PsKernelDefinition :=
  PsKernelList.cons (PsKernelDefinition.constant name PsKernelList.nil
    (PsKernelExpr.sortE (PsKernelLevel.succ PsKernelLevel.zero))) env

def psKernelRecordConstructorEnvironment (env : PsKernelList PsKernelDefinition)
    (name ctorName : PsKernelName) (ctorType : PsKernelExpr) : PsKernelList PsKernelDefinition :=
  PsKernelList.cons (PsKernelDefinition.constant ctorName PsKernelList.nil ctorType)
    (psKernelRecordFamilyEnvironment env name)

def psKernelRecordRecursorType (family minor : PsKernelExpr) (motive : PsKernelName) : PsKernelExpr :=
  PsKernelExpr.forallE PsKernelName.anonymous
    (PsKernelExpr.forallE PsKernelName.anonymous family
      (PsKernelExpr.sortE (PsKernelLevel.param motive)) PsKernelBinder.explicit)
    (PsKernelExpr.forallE PsKernelName.anonymous minor
      (PsKernelExpr.forallE PsKernelName.anonymous family
        (PsKernelExpr.app
          (PsKernelExpr.bvar (PsKernelNatural.positive (PsKernelPositive.bit0 PsKernelPositive.one)))
          (PsKernelExpr.bvar PsKernelNatural.zero)) PsKernelBinder.explicit)
      PsKernelBinder.explicit)
    PsKernelBinder.implicit

def psKernelRecordStep (state : PsKernelRecordState) : PsKernelRecordStep :=
  match state with
  | PsKernelRecordState.state env declaration task =>
      match declaration with
      | PsKernelUnitDeclaration.declaration name parameters level ctorName ctorType =>
          match task with
          | PsKernelRecordTask.initial =>
              match name with
              | PsKernelName.anonymous => psKernelRecordReject PsKernelCheckError.invalidName
              | _ =>
                  match ctorName with
                  | PsKernelName.anonymous => psKernelRecordReject PsKernelCheckError.invalidName
                  | _ =>
                      match parameters with
                      | PsKernelList.cons unused rest => psKernelRecordReject PsKernelCheckError.unsupported
                      | PsKernelList.nil =>
                          match level with
                          | PsKernelLevel.succ base =>
                              match base with
                              | PsKernelLevel.zero =>
                                  match ctorType with
                                  | PsKernelExpr.forallE unusedName unusedType unusedBody unusedBinder =>
                                      psKernelRecordNext env declaration (PsKernelRecordTask.familyName (PsKernelLookupState.search name env))
                                  | _ => psKernelRecordReject PsKernelCheckError.unsupported
                              | _ => psKernelRecordReject PsKernelCheckError.unsupported
                          | _ => psKernelRecordReject PsKernelCheckError.unsupported
          | PsKernelRecordTask.familyName current =>
              match psKernelLookupStep current with
              | PsKernelLookupStep.next next => psKernelRecordNext env declaration (PsKernelRecordTask.familyName next)
              | PsKernelLookupStep.found unused => psKernelRecordReject PsKernelCheckError.duplicateName
              | PsKernelLookupStep.missing => psKernelRecordNext env declaration
                  (PsKernelRecordTask.fields ctorType PsKernelList.nil PsKernelNatural.zero)
              | _ => psKernelRecordReject PsKernelCheckError.invalidState
          | PsKernelRecordTask.fields remaining reversed count =>
              match remaining with
              | PsKernelExpr.forallE unusedName field body unusedBinder => psKernelRecordNext env declaration
                  (PsKernelRecordTask.fieldType body (PsKernelList.cons field reversed) (psKernelNaturalSucc count)
                    (psKernelCheckStart env field (PsKernelExpr.sortE (PsKernelLevel.succ PsKernelLevel.zero))))
              | PsKernelExpr.constE resultName resultLevels =>
                  match resultLevels with
                  | PsKernelList.nil => psKernelRecordNext env declaration
                      (PsKernelRecordTask.result reversed count
                        (PsKernelList.cons (PsKernelOrderTask.name resultName name) PsKernelList.nil))
                  | _ => psKernelRecordReject PsKernelCheckError.invalidUniverse
              | _ => psKernelRecordReject PsKernelCheckError.typeMismatch
          | PsKernelRecordTask.fieldType remaining reversed count current =>
              match psKernelTypeStep current with
              | PsKernelTypeStep.next next => psKernelRecordNext env declaration
                  (PsKernelRecordTask.fieldType remaining reversed count next)
              | PsKernelTypeStep.final result =>
                  match result with
                  | PsKernelTypeResult.done unused => psKernelRecordNext env declaration (PsKernelRecordTask.fields remaining reversed count)
                  | PsKernelTypeResult.rejected error => psKernelRecordReject error
                  | _ => psKernelRecordReject PsKernelCheckError.invalidState
          | PsKernelRecordTask.result reversed count current =>
              match psKernelOrderStep current with
              | PsKernelOrderStep.next next => psKernelRecordNext env declaration (PsKernelRecordTask.result reversed count next)
              | PsKernelOrderStep.done order =>
                  match order with
                  | PsKernelOrder.same => psKernelRecordNext env declaration
                      (PsKernelRecordTask.constructorType reversed count
                        (psKernelCheckStart (psKernelRecordFamilyEnvironment env name) ctorType
                          (PsKernelExpr.sortE (PsKernelLevel.succ PsKernelLevel.zero))))
                  | _ => psKernelRecordReject PsKernelCheckError.typeMismatch
              | _ => psKernelRecordReject PsKernelCheckError.invalidState
          | PsKernelRecordTask.constructorType reversed count current =>
              match psKernelTypeStep current with
              | PsKernelTypeStep.next next => psKernelRecordNext env declaration (PsKernelRecordTask.constructorType reversed count next)
              | PsKernelTypeStep.final result =>
                  match result with
                  | PsKernelTypeResult.done unused => psKernelRecordNext env declaration
                      (PsKernelRecordTask.constructorName reversed count (PsKernelLookupState.search ctorName (psKernelRecordFamilyEnvironment env name)))
                  | PsKernelTypeResult.rejected error => psKernelRecordReject error
                  | _ => psKernelRecordReject PsKernelCheckError.invalidState
          | PsKernelRecordTask.constructorName reversed count current =>
              match psKernelLookupStep current with
              | PsKernelLookupStep.next next => psKernelRecordNext env declaration (PsKernelRecordTask.constructorName reversed count next)
              | PsKernelLookupStep.found unused => psKernelRecordReject PsKernelCheckError.duplicateName
              | PsKernelLookupStep.missing => psKernelRecordNext env declaration
                  (PsKernelRecordTask.recursorName reversed count
                    (PsKernelLookupState.search (psKernelUnitRecursorName name) (psKernelRecordConstructorEnvironment env name ctorName ctorType)))
              | _ => psKernelRecordReject PsKernelCheckError.invalidState
          | PsKernelRecordTask.recursorName reversed count current =>
              match psKernelLookupStep current with
              | PsKernelLookupStep.next next => psKernelRecordNext env declaration (PsKernelRecordTask.recursorName reversed count next)
              | PsKernelLookupStep.found unused => psKernelRecordReject PsKernelCheckError.duplicateName
              | PsKernelLookupStep.missing => psKernelRecordNext env declaration
                  (PsKernelRecordTask.arguments reversed count count (PsKernelExpr.constE ctorName PsKernelList.nil))
              | _ => psKernelRecordReject PsKernelCheckError.invalidState
          | PsKernelRecordTask.arguments reversed count index value =>
              match index with
              | PsKernelNatural.zero => psKernelRecordNext env declaration
                  (PsKernelRecordTask.minor reversed PsKernelList.nil (PsKernelExpr.app (PsKernelExpr.bvar count) value))
              | _ =>
                  let next : PsKernelNatural := psKernelNaturalPred index;
                  psKernelRecordNext env declaration
                    (PsKernelRecordTask.arguments reversed count next (PsKernelExpr.app value (PsKernelExpr.bvar next)))
          | PsKernelRecordTask.minor remaining fields value =>
              match remaining with
              | PsKernelList.cons field rest => psKernelRecordNext env declaration
                  (PsKernelRecordTask.minor rest (PsKernelList.cons field fields)
                    (PsKernelExpr.forallE PsKernelName.anonymous field value PsKernelBinder.explicit))
              | PsKernelList.nil =>
                  let recType : PsKernelExpr := psKernelRecordRecursorType (PsKernelExpr.constE name PsKernelList.nil) value (psKernelRecordMotive name);
                  psKernelRecordNext env declaration (PsKernelRecordTask.recursorType fields recType
                    (PsKernelTypeState.state
                      (PsKernelTypingContext.context (psKernelRecordConstructorEnvironment env name ctorName ctorType)
                        (PsKernelList.cons (psKernelRecordMotive name) PsKernelList.nil))
                      (PsKernelList.cons (PsKernelTypeTask.infer PsKernelList.nil recType)
                        (PsKernelList.cons PsKernelTypeTask.reduceTop PsKernelList.nil)) PsKernelList.nil))
          | PsKernelRecordTask.recursorType fields type current =>
              match psKernelTypeStep current with
              | PsKernelTypeStep.next next => psKernelRecordNext env declaration (PsKernelRecordTask.recursorType fields type next)
              | PsKernelTypeStep.final result =>
                  match result with
                  | PsKernelTypeResult.done inferred =>
                      match inferred with
                      | PsKernelExpr.sortE unused => PsKernelRecordStep.final (PsKernelAdmissionResult.admitted
                          (PsKernelList.cons (PsKernelDefinition.recordRecursor (psKernelUnitRecursorName name)
                            (PsKernelList.cons (psKernelRecordMotive name) PsKernelList.nil) type ctorName fields)
                            (PsKernelList.cons (PsKernelDefinition.constant ctorName PsKernelList.nil ctorType)
                              (PsKernelList.cons (PsKernelDefinition.recordFamily name ctorName fields) env))))
                      | _ => psKernelRecordReject PsKernelCheckError.typeExpected
                  | PsKernelTypeResult.rejected error => psKernelRecordReject error
                  | _ => psKernelRecordReject PsKernelCheckError.invalidState

def psKernelRecordStart (env : PsKernelList PsKernelDefinition) (declaration : PsKernelUnitDeclaration) : PsKernelRecordState :=
  PsKernelRecordState.state env declaration PsKernelRecordTask.initial

def psKernelRecordRun (fuel : PsKernelFuel) : PsKernelRecordState -> PsKernelAdmissionResult :=
  match fuel with
  | PsKernelFuel.stop => fun (state : PsKernelRecordState) => PsKernelAdmissionResult.outOfFuel
  | PsKernelFuel.more remaining =>
      fun (state : PsKernelRecordState) =>
        match psKernelRecordStep state with
        | PsKernelRecordStep.final result => result
        | PsKernelRecordStep.next next =>
            let smaller : PsKernelRecordState -> PsKernelAdmissionResult := psKernelRecordRun remaining;
            smaller next
