import Ps.Kernel.RecordInductive

/- A monomorphic Type-valued family with at least two nullary constructors.
Every constructor must return exactly the fresh family. Names, constructor
judgments and the derived dependent eliminator are checked before any environment
is published. This does not grant parameterized, recursive or arbitrary sum rules.
All traversal and inference is stepped by the caller's single outer budget. -/
inductive PsKernelEnumConstructor where
  | ctor (name : PsKernelName) (type : PsKernelExpr)

inductive PsKernelEnumDeclaration where
  | declaration (name : PsKernelName) (parameters : PsKernelList PsKernelName)
      (level : PsKernelLevel) (constructors : PsKernelList PsKernelEnumConstructor)

inductive PsKernelEnumTask where
  | initial
  | familyName (state : PsKernelLookupState)
  | constructors (pending : PsKernelList PsKernelEnumConstructor)
      (current : PsKernelList PsKernelDefinition) (reversed : PsKernelList PsKernelName) (count : PsKernelNatural)
  | constructorName (pending : PsKernelList PsKernelEnumConstructor)
      (current : PsKernelList PsKernelDefinition) (reversed : PsKernelList PsKernelName)
      (count : PsKernelNatural) (name : PsKernelName) (type : PsKernelExpr) (state : PsKernelLookupState)
  | constructorResult (pending : PsKernelList PsKernelEnumConstructor)
      (current : PsKernelList PsKernelDefinition) (reversed : PsKernelList PsKernelName)
      (count : PsKernelNatural) (name : PsKernelName) (type : PsKernelExpr) (work : PsKernelList PsKernelOrderTask)
  | constructorType (pending : PsKernelList PsKernelEnumConstructor)
      (current : PsKernelList PsKernelDefinition) (reversed : PsKernelList PsKernelName)
      (count : PsKernelNatural) (name : PsKernelName) (type : PsKernelExpr) (state : PsKernelTypeState)
  | recursorName (current : PsKernelList PsKernelDefinition)
      (reversed : PsKernelList PsKernelName) (count : PsKernelNatural) (state : PsKernelLookupState)
  | minors (current : PsKernelList PsKernelDefinition)
      (pending forward : PsKernelList PsKernelName) (count : PsKernelNatural) (body : PsKernelExpr)
  | recursorType (current : PsKernelList PsKernelDefinition)
      (constructors : PsKernelList PsKernelName) (type : PsKernelExpr) (state : PsKernelTypeState)

inductive PsKernelEnumState where
  | state (environment : PsKernelList PsKernelDefinition) (declaration : PsKernelEnumDeclaration) (task : PsKernelEnumTask)

inductive PsKernelEnumStep where
  | next (state : PsKernelEnumState)
  | final (result : PsKernelAdmissionResult)

def psKernelEnumNext (env : PsKernelList PsKernelDefinition) (declaration : PsKernelEnumDeclaration)
    (task : PsKernelEnumTask) : PsKernelEnumStep :=
  PsKernelEnumStep.next (PsKernelEnumState.state env declaration task)

def psKernelEnumReject (error : PsKernelCheckError) : PsKernelEnumStep :=
  PsKernelEnumStep.final (PsKernelAdmissionResult.rejected error)

def psKernelEnumType : PsKernelExpr :=
  PsKernelExpr.sortE (PsKernelLevel.succ PsKernelLevel.zero)

def psKernelEnumRecursorType (name : PsKernelName) (body : PsKernelExpr) : PsKernelExpr :=
  PsKernelExpr.forallE PsKernelName.anonymous
    (PsKernelExpr.forallE PsKernelName.anonymous (PsKernelExpr.constE name PsKernelList.nil)
      (PsKernelExpr.sortE (PsKernelLevel.param (psKernelRecordMotive name))) PsKernelBinder.explicit)
    body PsKernelBinder.implicit

def psKernelEnumStep (state : PsKernelEnumState) : PsKernelEnumStep :=
  match state with
  | PsKernelEnumState.state env declaration task =>
      match declaration with
      | PsKernelEnumDeclaration.declaration name parameters level constructors =>
          match task with
          | PsKernelEnumTask.initial =>
              match name with
              | PsKernelName.anonymous => psKernelEnumReject PsKernelCheckError.invalidName
              | _ =>
                  match parameters with
                  | PsKernelList.cons unused rest => psKernelEnumReject PsKernelCheckError.unsupported
                  | PsKernelList.nil =>
                      match level with
                      | PsKernelLevel.succ base =>
                          match base with
                          | PsKernelLevel.zero =>
                              match constructors with
                              | PsKernelList.cons first tail =>
                                  match tail with
                                  | PsKernelList.cons second rest => psKernelEnumNext env declaration
                                      (PsKernelEnumTask.familyName (PsKernelLookupState.search name env))
                                  | _ => psKernelEnumReject PsKernelCheckError.unsupported
                              | _ => psKernelEnumReject PsKernelCheckError.unsupported
                          | _ => psKernelEnumReject PsKernelCheckError.unsupported
                      | _ => psKernelEnumReject PsKernelCheckError.unsupported
          | PsKernelEnumTask.familyName current =>
              match psKernelLookupStep current with
              | PsKernelLookupStep.next next => psKernelEnumNext env declaration (PsKernelEnumTask.familyName next)
              | PsKernelLookupStep.found unused => psKernelEnumReject PsKernelCheckError.duplicateName
              | PsKernelLookupStep.missing => psKernelEnumNext env declaration
                  (PsKernelEnumTask.constructors constructors (psKernelRecordFamilyEnvironment env name)
                    PsKernelList.nil PsKernelNatural.zero)
              | _ => psKernelEnumReject PsKernelCheckError.invalidState
          | PsKernelEnumTask.constructors pending current reversed count =>
              match pending with
              | PsKernelList.nil => psKernelEnumNext env declaration
                  (PsKernelEnumTask.recursorName current reversed count
                    (PsKernelLookupState.search (psKernelUnitRecursorName name) current))
              | PsKernelList.cons ctor rest =>
                  match ctor with
                  | PsKernelEnumConstructor.ctor ctorName ctorType =>
                      match ctorName with
                      | PsKernelName.anonymous => psKernelEnumReject PsKernelCheckError.invalidName
                      | _ => psKernelEnumNext env declaration
                          (PsKernelEnumTask.constructorName rest current reversed count ctorName ctorType
                            (PsKernelLookupState.search ctorName current))
          | PsKernelEnumTask.constructorName pending current reversed count ctorName ctorType lookup =>
              match psKernelLookupStep lookup with
              | PsKernelLookupStep.next next => psKernelEnumNext env declaration
                  (PsKernelEnumTask.constructorName pending current reversed count ctorName ctorType next)
              | PsKernelLookupStep.found unused => psKernelEnumReject PsKernelCheckError.duplicateName
              | PsKernelLookupStep.invalidState => psKernelEnumReject PsKernelCheckError.invalidState
              | PsKernelLookupStep.missing =>
                  match ctorType with
                  | PsKernelExpr.constE resultName resultLevels =>
                      match resultLevels with
                      | PsKernelList.nil => psKernelEnumNext env declaration
                          (PsKernelEnumTask.constructorResult pending current reversed count ctorName ctorType
                            (PsKernelList.cons (PsKernelOrderTask.name resultName name) PsKernelList.nil))
                      | _ => psKernelEnumReject PsKernelCheckError.invalidUniverse
                  | _ => psKernelEnumReject PsKernelCheckError.unsupported
          | PsKernelEnumTask.constructorResult pending current reversed count ctorName ctorType work =>
              match psKernelOrderStep work with
              | PsKernelOrderStep.next next => psKernelEnumNext env declaration
                  (PsKernelEnumTask.constructorResult pending current reversed count ctorName ctorType next)
              | PsKernelOrderStep.done order =>
                  match order with
                  | PsKernelOrder.same => psKernelEnumNext env declaration
                      (PsKernelEnumTask.constructorType pending current reversed count ctorName ctorType
                        (psKernelCheckStart current ctorType psKernelEnumType))
                  | _ => psKernelEnumReject PsKernelCheckError.typeMismatch
              | _ => psKernelEnumReject PsKernelCheckError.invalidState
          | PsKernelEnumTask.constructorType pending current reversed count ctorName ctorType typing =>
              match psKernelTypeStep typing with
              | PsKernelTypeStep.next next => psKernelEnumNext env declaration
                  (PsKernelEnumTask.constructorType pending current reversed count ctorName ctorType next)
              | PsKernelTypeStep.final result =>
                  match result with
                  | PsKernelTypeResult.done unused => psKernelEnumNext env declaration
                      (PsKernelEnumTask.constructors pending
                        (PsKernelList.cons (PsKernelDefinition.constant ctorName PsKernelList.nil ctorType) current)
                        (PsKernelList.cons ctorName reversed) (psKernelNaturalSucc count))
                  | PsKernelTypeResult.rejected error => psKernelEnumReject error
                  | _ => psKernelEnumReject PsKernelCheckError.invalidState
          | PsKernelEnumTask.recursorName current reversed count lookup =>
              match psKernelLookupStep lookup with
              | PsKernelLookupStep.next next => psKernelEnumNext env declaration
                  (PsKernelEnumTask.recursorName current reversed count next)
              | PsKernelLookupStep.found unused => psKernelEnumReject PsKernelCheckError.duplicateName
              | PsKernelLookupStep.missing => psKernelEnumNext env declaration
                  (PsKernelEnumTask.minors current reversed PsKernelList.nil count
                    (PsKernelExpr.forallE PsKernelName.anonymous (PsKernelExpr.constE name PsKernelList.nil)
                      (PsKernelExpr.app (PsKernelExpr.bvar (psKernelNaturalSucc count))
                        (PsKernelExpr.bvar PsKernelNatural.zero)) PsKernelBinder.explicit))
              | _ => psKernelEnumReject PsKernelCheckError.invalidState
          | PsKernelEnumTask.minors current pending forward count body =>
              match pending with
              | PsKernelList.cons ctorName rest =>
                  match count with
                  | PsKernelNatural.zero => psKernelEnumReject PsKernelCheckError.invalidState
                  | _ =>
                      let next : PsKernelNatural := psKernelNaturalPred count;
                      psKernelEnumNext env declaration
                        (PsKernelEnumTask.minors current rest (PsKernelList.cons ctorName forward) next
                          (PsKernelExpr.forallE PsKernelName.anonymous
                            (PsKernelExpr.app (PsKernelExpr.bvar next) (PsKernelExpr.constE ctorName PsKernelList.nil))
                            body PsKernelBinder.explicit))
              | PsKernelList.nil =>
                  match count with
                  | PsKernelNatural.positive unused => psKernelEnumReject PsKernelCheckError.invalidState
                  | PsKernelNatural.zero =>
                      let recType : PsKernelExpr := psKernelEnumRecursorType name body;
                      psKernelEnumNext env declaration (PsKernelEnumTask.recursorType current forward recType
                        (PsKernelTypeState.state
                          (PsKernelTypingContext.context current (PsKernelList.cons (psKernelRecordMotive name) PsKernelList.nil))
                          (PsKernelList.cons (PsKernelTypeTask.infer PsKernelList.nil recType)
                            (PsKernelList.cons PsKernelTypeTask.reduceTop PsKernelList.nil)) PsKernelList.nil))
          | PsKernelEnumTask.recursorType current ctorNames type typing =>
              match psKernelTypeStep typing with
              | PsKernelTypeStep.next next => psKernelEnumNext env declaration
                  (PsKernelEnumTask.recursorType current ctorNames type next)
              | PsKernelTypeStep.final result =>
                  match result with
                  | PsKernelTypeResult.done inferred =>
                      match inferred with
                      | PsKernelExpr.sortE unused => PsKernelEnumStep.final (PsKernelAdmissionResult.admitted
                          (PsKernelList.cons (PsKernelDefinition.enumRecursor (psKernelUnitRecursorName name)
                            (PsKernelList.cons (psKernelRecordMotive name) PsKernelList.nil) type ctorNames) current))
                      | _ => psKernelEnumReject PsKernelCheckError.typeExpected
                  | PsKernelTypeResult.rejected error => psKernelEnumReject error
                  | _ => psKernelEnumReject PsKernelCheckError.invalidState

def psKernelEnumStart (env : PsKernelList PsKernelDefinition) (declaration : PsKernelEnumDeclaration) : PsKernelEnumState :=
  PsKernelEnumState.state env declaration PsKernelEnumTask.initial

def psKernelEnumRun (fuel : PsKernelFuel) : PsKernelEnumState -> PsKernelAdmissionResult :=
  match fuel with
  | PsKernelFuel.stop => fun (state : PsKernelEnumState) => PsKernelAdmissionResult.outOfFuel
  | PsKernelFuel.more remaining =>
      fun (state : PsKernelEnumState) =>
        match psKernelEnumStep state with
        | PsKernelEnumStep.final result => result
        | PsKernelEnumStep.next next =>
            let smaller : PsKernelEnumState -> PsKernelAdmissionResult := psKernelEnumRun remaining;
            smaller next
