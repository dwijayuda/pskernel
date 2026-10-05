import Ps.Kernel.AlgebraicHeader
import Ps.Kernel.AlgebraicRecursor

/- Atomic admission of one uniform Type0 family. A provisional ordinary family
constant is private to constructor checking. Covariance metadata and recursive
computation rules become visible only after every constructor, positivity test
and the source-derived dependent eliminator type has checked successfully. -/

inductive PsKernelAlgAdmissionFrame where
  | frame (header : PsKernelAlgHeader) (working : PsKernelList PsKernelDefinition)
      (pending : PsKernelList PsKernelAlgInputConstructor) (reversed : PsKernelList PsKernelAlgConstructor)

inductive PsKernelAlgAdmissionTask where
  | header (state : PsKernelAlgHeaderState)
  | recursorName (header : PsKernelAlgHeader) (state : PsKernelLookupState)
  | constructors (frame : PsKernelAlgAdmissionFrame)
  | constructorName (frame : PsKernelAlgAdmissionFrame) (input : PsKernelAlgInputConstructor)
      (tasks : PsKernelList PsKernelOrderTask)
  | constructor (frame : PsKernelAlgAdmissionFrame) (state : PsKernelAlgConstructorState)
  | reverse (header : PsKernelAlgHeader) (working : PsKernelList PsKernelDefinition)
      (pending constructors : PsKernelList PsKernelAlgConstructor)
  | recursor (header : PsKernelAlgHeader) (working : PsKernelList PsKernelDefinition)
      (constructors : PsKernelList PsKernelAlgConstructor) (state : PsKernelAlgRecursorState)
  | check (header : PsKernelAlgHeader) (constructors : PsKernelList PsKernelAlgConstructor)
      (type : PsKernelExpr) (rules : PsKernelList PsKernelAlgRule) (state : PsKernelTypeState)
  | install (header : PsKernelAlgHeader) (pending : PsKernelList PsKernelAlgConstructor)
      (type : PsKernelExpr) (rules : PsKernelList PsKernelAlgRule) (environment : PsKernelList PsKernelDefinition)

inductive PsKernelAlgAdmissionState where
  | state (environment : PsKernelList PsKernelDefinition) (declaration : PsKernelAlgDeclaration) (task : PsKernelAlgAdmissionTask)

inductive PsKernelAlgAdmissionStep where
  | next (state : PsKernelAlgAdmissionState)
  | final (result : PsKernelAdmissionResult)

def psKernelAlgAdmissionNext (env : PsKernelList PsKernelDefinition) (declaration : PsKernelAlgDeclaration)
    (task : PsKernelAlgAdmissionTask) : PsKernelAlgAdmissionStep :=
  PsKernelAlgAdmissionStep.next (PsKernelAlgAdmissionState.state env declaration task)

def psKernelAlgAdmissionReject (error : PsKernelCheckError) : PsKernelAlgAdmissionStep :=
  PsKernelAlgAdmissionStep.final (PsKernelAdmissionResult.rejected error)

def psKernelAlgAdmissionStep (state : PsKernelAlgAdmissionState) : PsKernelAlgAdmissionStep :=
  match state with
  | PsKernelAlgAdmissionState.state env declaration task =>
      match task with
      | PsKernelAlgAdmissionTask.header current =>
          match psKernelAlgHeaderStep current with
          | PsKernelAlgHeaderStep.next next => psKernelAlgAdmissionNext env declaration (PsKernelAlgAdmissionTask.header next)
          | PsKernelAlgHeaderStep.rejected error => psKernelAlgAdmissionReject error
          | PsKernelAlgHeaderStep.accepted header =>
              match header with
              | PsKernelAlgHeader.header name unusedType unusedParameters unusedArguments unusedBinders unusedUniform =>
                  psKernelAlgAdmissionNext env declaration (PsKernelAlgAdmissionTask.recursorName header
                    (PsKernelLookupState.search (psKernelUnitRecursorName name) env))
      | PsKernelAlgAdmissionTask.recursorName header current =>
          match psKernelLookupStep current with
          | PsKernelLookupStep.next next => psKernelAlgAdmissionNext env declaration
              (PsKernelAlgAdmissionTask.recursorName header next)
          | PsKernelLookupStep.found unused => psKernelAlgAdmissionReject PsKernelCheckError.duplicateName
          | PsKernelLookupStep.invalidState => psKernelAlgAdmissionReject PsKernelCheckError.invalidState
          | PsKernelLookupStep.missing =>
              match declaration with
              | PsKernelAlgDeclaration.declaration name unusedParameters type constructors =>
                  match constructors with
                  | PsKernelList.nil => psKernelAlgAdmissionReject PsKernelCheckError.unsupported
                  | _ => psKernelAlgAdmissionNext env declaration (PsKernelAlgAdmissionTask.constructors
                      (PsKernelAlgAdmissionFrame.frame header
                        (PsKernelList.cons (PsKernelDefinition.constant name PsKernelList.nil type) env) constructors PsKernelList.nil))
      | PsKernelAlgAdmissionTask.constructors frame =>
          match frame with
          | PsKernelAlgAdmissionFrame.frame header working pending reversed =>
              match pending with
              | PsKernelList.nil => psKernelAlgAdmissionNext env declaration
                  (PsKernelAlgAdmissionTask.reverse header working reversed PsKernelList.nil)
              | PsKernelList.cons input rest =>
                  match input with
                  | PsKernelAlgInputConstructor.constructor name unusedType =>
                      match header with
                      | PsKernelAlgHeader.header family unusedFamilyType unusedParameters unusedArguments unusedBinders unusedUniform =>
                          psKernelAlgAdmissionNext env declaration
                            (PsKernelAlgAdmissionTask.constructorName
                              (PsKernelAlgAdmissionFrame.frame header working rest reversed) input
                              (PsKernelList.cons (PsKernelOrderTask.name name (psKernelUnitRecursorName family)) PsKernelList.nil))
      | PsKernelAlgAdmissionTask.constructorName frame input current =>
          match psKernelOrderStep current with
          | PsKernelOrderStep.next next => psKernelAlgAdmissionNext env declaration
              (PsKernelAlgAdmissionTask.constructorName frame input next)
          | PsKernelOrderStep.invalidState => psKernelAlgAdmissionReject PsKernelCheckError.invalidState
          | PsKernelOrderStep.done order =>
              match order with
              | PsKernelOrder.same => psKernelAlgAdmissionReject PsKernelCheckError.duplicateName
              | _ =>
                  match frame with
                  | PsKernelAlgAdmissionFrame.frame header working unusedPending unusedReversed =>
                      psKernelAlgAdmissionNext env declaration
                        (PsKernelAlgAdmissionTask.constructor frame (psKernelAlgConstructorStart working header input))
      | PsKernelAlgAdmissionTask.constructor frame current =>
          match psKernelAlgConstructorStep current with
          | PsKernelAlgConstructorStep.next next => psKernelAlgAdmissionNext env declaration
              (PsKernelAlgAdmissionTask.constructor frame next)
          | PsKernelAlgConstructorStep.rejected error => psKernelAlgAdmissionReject error
          | PsKernelAlgConstructorStep.accepted constructor =>
              match frame with
              | PsKernelAlgAdmissionFrame.frame header working pending reversed =>
                  match constructor with
                  | PsKernelAlgConstructor.constructor name type unusedFields => psKernelAlgAdmissionNext env declaration
                      (PsKernelAlgAdmissionTask.constructors (PsKernelAlgAdmissionFrame.frame header
                        (PsKernelList.cons (PsKernelDefinition.constant name PsKernelList.nil type) working)
                        pending (PsKernelList.cons constructor reversed)))
      | PsKernelAlgAdmissionTask.reverse header working pending constructors =>
          match pending with
          | PsKernelList.cons constructor rest => psKernelAlgAdmissionNext env declaration
              (PsKernelAlgAdmissionTask.reverse header working rest (PsKernelList.cons constructor constructors))
          | PsKernelList.nil => psKernelAlgAdmissionNext env declaration
              (PsKernelAlgAdmissionTask.recursor header working constructors (psKernelAlgRecursorStart header constructors))
      | PsKernelAlgAdmissionTask.recursor header working constructors current =>
          match psKernelAlgRecursorStep current with
          | PsKernelAlgRecursorStep.next next => psKernelAlgAdmissionNext env declaration
              (PsKernelAlgAdmissionTask.recursor header working constructors next)
          | PsKernelAlgRecursorStep.rejected error => psKernelAlgAdmissionReject error
          | PsKernelAlgRecursorStep.ready type rules => psKernelAlgAdmissionNext env declaration
              (PsKernelAlgAdmissionTask.check header constructors type rules
                (PsKernelTypeState.state
                  (PsKernelTypingContext.context working (PsKernelList.cons psKernelAlgRecursorLevelName PsKernelList.nil))
                  (PsKernelList.cons (PsKernelTypeTask.infer PsKernelList.nil type) PsKernelList.nil) PsKernelList.nil))
      | PsKernelAlgAdmissionTask.check header constructors type rules current =>
          match psKernelTypeStep current with
          | PsKernelTypeStep.next next => psKernelAlgAdmissionNext env declaration
              (PsKernelAlgAdmissionTask.check header constructors type rules next)
          | PsKernelTypeStep.final result =>
              match result with
              | PsKernelTypeResult.rejected error => psKernelAlgAdmissionReject error
              | PsKernelTypeResult.done kind =>
                  match kind with
                  | PsKernelExpr.sortE unusedLevel =>
                      match header with
                      | PsKernelAlgHeader.header name familyType parameters unusedArguments unusedBinders unusedUniform =>
                          psKernelAlgAdmissionNext env declaration (PsKernelAlgAdmissionTask.install header constructors type rules
                            (PsKernelList.cons (PsKernelDefinition.algebraicFamily name familyType parameters constructors) env))
                  | _ => psKernelAlgAdmissionReject PsKernelCheckError.typeExpected
              | _ => psKernelAlgAdmissionReject PsKernelCheckError.invalidState
      | PsKernelAlgAdmissionTask.install header pending type rules result =>
          match pending with
          | PsKernelList.cons constructor rest =>
              match constructor with
              | PsKernelAlgConstructor.constructor name constructorType unusedFields => psKernelAlgAdmissionNext env declaration
                  (PsKernelAlgAdmissionTask.install header rest type rules
                    (PsKernelList.cons (PsKernelDefinition.constant name PsKernelList.nil constructorType) result))
          | PsKernelList.nil =>
              match header with
              | PsKernelAlgHeader.header name unusedFamilyType parameters unusedArguments unusedBinders unusedUniform =>
                  PsKernelAlgAdmissionStep.final (PsKernelAdmissionResult.admitted
                    (PsKernelList.cons (PsKernelDefinition.algebraicRecursor (psKernelUnitRecursorName name)
                      (PsKernelList.cons psKernelAlgRecursorLevelName PsKernelList.nil) type parameters rules) result))

def psKernelAlgAdmissionStart (env : PsKernelList PsKernelDefinition)
    (declaration : PsKernelAlgDeclaration) : PsKernelAlgAdmissionState :=
  PsKernelAlgAdmissionState.state env declaration (PsKernelAlgAdmissionTask.header (psKernelAlgHeaderStart env declaration))

def psKernelAlgAdmissionRun (fuel : PsKernelFuel) : PsKernelAlgAdmissionState -> PsKernelAdmissionResult :=
  match fuel with
  | PsKernelFuel.stop => fun (state : PsKernelAlgAdmissionState) => PsKernelAdmissionResult.outOfFuel
  | PsKernelFuel.more remaining =>
      fun (state : PsKernelAlgAdmissionState) =>
        match psKernelAlgAdmissionStep state with
        | PsKernelAlgAdmissionStep.final result => result
        | PsKernelAlgAdmissionStep.next next =>
            let smaller : PsKernelAlgAdmissionState -> PsKernelAdmissionResult := psKernelAlgAdmissionRun remaining;
            smaller next
