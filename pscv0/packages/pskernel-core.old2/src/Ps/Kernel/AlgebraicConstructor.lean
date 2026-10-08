import Ps.Kernel.TypeCheck
import Ps.Kernel.Closing
import Ps.Kernel.Positivity

/- Constructor validation for the uniform Type0 fragment. Raw input is scope
checked before allocating private fvars. A field is checked after closing ONLY
the type parameters, so dependence on earlier term fields cannot be hidden by
opening binders. Covariance and recursive uniformity are checked separately. -/
inductive PsKernelAlgConstructorTask where
  | scope (state : PsKernelBindingState)
  | name (state : PsKernelLookupState)
  | parameters (remaining : PsKernelExpr) (arguments : PsKernelList PsKernelExpr)
  | parameter (arguments : PsKernelList PsKernelExpr) (state : PsKernelBindingState)
  | fields (remaining : PsKernelExpr) (reversed : PsKernelList PsKernelExpr) (nextId : PsKernelNatural)
  | closeField (field body : PsKernelExpr) (reversed : PsKernelList PsKernelExpr)
      (id : PsKernelNatural) (state : PsKernelCloseState)
  | fieldType (field body closed : PsKernelExpr) (reversed : PsKernelList PsKernelExpr)
      (id : PsKernelNatural) (state : PsKernelTypeState)
  | template (field body closed : PsKernelExpr) (reversed : PsKernelList PsKernelExpr)
      (id remaining : PsKernelNatural)
  | positive (body template : PsKernelExpr) (reversed : PsKernelList PsKernelExpr)
      (id : PsKernelNatural) (state : PsKernelPositiveFieldState)
  | fieldBody (reversed : PsKernelList PsKernelExpr) (id : PsKernelNatural) (state : PsKernelBindingState)
  | result (reversed : PsKernelList PsKernelExpr) (state : PsKernelExprEqualState)
  | constructorType (reversed : PsKernelList PsKernelExpr) (state : PsKernelTypeState)
  | reverse (pending fields : PsKernelList PsKernelExpr)

inductive PsKernelAlgConstructorState where
  | state (environment : PsKernelList PsKernelDefinition) (header : PsKernelAlgHeader)
      (input : PsKernelAlgInputConstructor) (task : PsKernelAlgConstructorTask)

inductive PsKernelAlgConstructorStep where
  | next (state : PsKernelAlgConstructorState)
  | accepted (constructor : PsKernelAlgConstructor)
  | rejected (error : PsKernelCheckError)

inductive PsKernelAlgConstructorResult where
  | accepted (constructor : PsKernelAlgConstructor)
  | rejected (error : PsKernelCheckError)
  | outOfFuel

def psKernelAlgConstructorNext (env : PsKernelList PsKernelDefinition) (header : PsKernelAlgHeader)
    (input : PsKernelAlgInputConstructor) (task : PsKernelAlgConstructorTask) : PsKernelAlgConstructorStep :=
  PsKernelAlgConstructorStep.next (PsKernelAlgConstructorState.state env header input task)

def psKernelAlgConstructorStep (state : PsKernelAlgConstructorState) : PsKernelAlgConstructorStep :=
  match state with
  | PsKernelAlgConstructorState.state env header input task =>
      match header with
      | PsKernelAlgHeader.header family familyType parameters arguments binders uniform =>
          match input with
          | PsKernelAlgInputConstructor.constructor name type =>
              match task with
              | PsKernelAlgConstructorTask.scope current =>
                  match psKernelBindingStep current with
                  | PsKernelBindingStep.next next => psKernelAlgConstructorNext env header input (PsKernelAlgConstructorTask.scope next)
                  | PsKernelBindingStep.final result =>
                      match result with
                      | PsKernelBindingResult.done unused =>
                          match name with
                          | PsKernelName.anonymous => PsKernelAlgConstructorStep.rejected PsKernelCheckError.invalidName
                          | _ => psKernelAlgConstructorNext env header input (PsKernelAlgConstructorTask.name (PsKernelLookupState.search name env))
                      | PsKernelBindingResult.invalidScope => PsKernelAlgConstructorStep.rejected PsKernelCheckError.invalidScope
                      | _ => PsKernelAlgConstructorStep.rejected PsKernelCheckError.invalidState
              | PsKernelAlgConstructorTask.name current =>
                  match psKernelLookupStep current with
                  | PsKernelLookupStep.next next => psKernelAlgConstructorNext env header input (PsKernelAlgConstructorTask.name next)
                  | PsKernelLookupStep.missing => psKernelAlgConstructorNext env header input (PsKernelAlgConstructorTask.parameters type arguments)
                  | PsKernelLookupStep.found unused => PsKernelAlgConstructorStep.rejected PsKernelCheckError.duplicateName
                  | _ => PsKernelAlgConstructorStep.rejected PsKernelCheckError.invalidState
              | PsKernelAlgConstructorTask.parameters remaining pending =>
                  match pending with
                  | PsKernelList.nil => psKernelAlgConstructorNext env header input
                      (PsKernelAlgConstructorTask.fields remaining PsKernelList.nil parameters)
                  | PsKernelList.cons argument rest =>
                      match remaining with
                      | PsKernelExpr.forallE unusedName domain body unusedBinder =>
                          match domain with
                          | PsKernelExpr.sortE level =>
                              match level with
                              | PsKernelLevel.succ inner =>
                                  match inner with
                                  | PsKernelLevel.zero => psKernelAlgConstructorNext env header input
                                      (PsKernelAlgConstructorTask.parameter rest
                                        (psKernelBindingStart (PsKernelBindingMode.instantiate argument) PsKernelNatural.zero body))
                                  | _ => PsKernelAlgConstructorStep.rejected PsKernelCheckError.unsupported
                              | _ => PsKernelAlgConstructorStep.rejected PsKernelCheckError.unsupported
                          | _ => PsKernelAlgConstructorStep.rejected PsKernelCheckError.unsupported
                      | _ => PsKernelAlgConstructorStep.rejected PsKernelCheckError.typeMismatch
              | PsKernelAlgConstructorTask.parameter pending current =>
                  match psKernelBindingStep current with
                  | PsKernelBindingStep.next next => psKernelAlgConstructorNext env header input
                      (PsKernelAlgConstructorTask.parameter pending next)
                  | PsKernelBindingStep.final result =>
                      match result with
                      | PsKernelBindingResult.done remaining => psKernelAlgConstructorNext env header input
                          (PsKernelAlgConstructorTask.parameters remaining pending)
                      | _ => PsKernelAlgConstructorStep.rejected PsKernelCheckError.invalidState
              | PsKernelAlgConstructorTask.fields remaining reversed nextId =>
                  match remaining with
                  | PsKernelExpr.forallE unusedName field body unusedBinder => psKernelAlgConstructorNext env header input
                      (PsKernelAlgConstructorTask.closeField field body reversed nextId
                        (psKernelCloseStart PsKernelCloseMode.lambda binders field))
                  | _ => psKernelAlgConstructorNext env header input
                      (PsKernelAlgConstructorTask.result reversed (psKernelExprEqualStart remaining uniform))
              | PsKernelAlgConstructorTask.closeField field body reversed id current =>
                  match psKernelCloseStep current with
                  | PsKernelCloseStep.next next => psKernelAlgConstructorNext env header input
                      (PsKernelAlgConstructorTask.closeField field body reversed id next)
                  | PsKernelCloseStep.done closed => psKernelAlgConstructorNext env header input
                      (PsKernelAlgConstructorTask.fieldType field body closed reversed id (psKernelCheckStart env closed familyType))
                  | _ => PsKernelAlgConstructorStep.rejected PsKernelCheckError.invalidState
              | PsKernelAlgConstructorTask.fieldType field body closed reversed id current =>
                  match psKernelTypeStep current with
                  | PsKernelTypeStep.next next => psKernelAlgConstructorNext env header input
                      (PsKernelAlgConstructorTask.fieldType field body closed reversed id next)
                  | PsKernelTypeStep.final result =>
                      match result with
                      | PsKernelTypeResult.done unused => psKernelAlgConstructorNext env header input
                          (PsKernelAlgConstructorTask.template field body closed reversed id parameters)
                      | PsKernelTypeResult.rejected error => PsKernelAlgConstructorStep.rejected error
                      | _ => PsKernelAlgConstructorStep.rejected PsKernelCheckError.invalidState
              | PsKernelAlgConstructorTask.template field body closed reversed id remaining =>
                  match remaining with
                  | PsKernelNatural.zero => psKernelAlgConstructorNext env header input
                      (PsKernelAlgConstructorTask.positive body closed reversed id (psKernelPositiveFieldStart env family uniform field))
                  | _ =>
                      match closed with
                      | PsKernelExpr.lam unusedName unusedType inner unusedBinder => psKernelAlgConstructorNext env header input
                          (PsKernelAlgConstructorTask.template field body inner reversed id (psKernelNaturalPred remaining))
                      | _ => PsKernelAlgConstructorStep.rejected PsKernelCheckError.invalidState
              | PsKernelAlgConstructorTask.positive body template reversed id current =>
                  match psKernelPositiveFieldStep current with
                  | PsKernelPositiveFieldStep.next next => psKernelAlgConstructorNext env header input
                      (PsKernelAlgConstructorTask.positive body template reversed id next)
                  | PsKernelPositiveFieldStep.accepted => psKernelAlgConstructorNext env header input
                      (PsKernelAlgConstructorTask.fieldBody (PsKernelList.cons template reversed) (psKernelNaturalSucc id)
                        (psKernelBindingStart (PsKernelBindingMode.instantiate (PsKernelExpr.fvar id)) PsKernelNatural.zero body))
                  | PsKernelPositiveFieldStep.rejected error => PsKernelAlgConstructorStep.rejected error
              | PsKernelAlgConstructorTask.fieldBody reversed id current =>
                  match psKernelBindingStep current with
                  | PsKernelBindingStep.next next => psKernelAlgConstructorNext env header input
                      (PsKernelAlgConstructorTask.fieldBody reversed id next)
                  | PsKernelBindingStep.final result =>
                      match result with
                      | PsKernelBindingResult.done remaining => psKernelAlgConstructorNext env header input
                          (PsKernelAlgConstructorTask.fields remaining reversed id)
                      | _ => PsKernelAlgConstructorStep.rejected PsKernelCheckError.invalidState
              | PsKernelAlgConstructorTask.result reversed current =>
                  match psKernelExprEqualStep current with
                  | PsKernelExprEqualStep.next next => psKernelAlgConstructorNext env header input
                      (PsKernelAlgConstructorTask.result reversed next)
                  | PsKernelExprEqualStep.equal => psKernelAlgConstructorNext env header input
                      (PsKernelAlgConstructorTask.constructorType reversed (psKernelInferStart env type))
                  | PsKernelExprEqualStep.different => PsKernelAlgConstructorStep.rejected PsKernelCheckError.typeMismatch
                  | _ => PsKernelAlgConstructorStep.rejected PsKernelCheckError.invalidState
              | PsKernelAlgConstructorTask.constructorType reversed current =>
                  match psKernelTypeStep current with
                  | PsKernelTypeStep.next next => psKernelAlgConstructorNext env header input
                      (PsKernelAlgConstructorTask.constructorType reversed next)
                  | PsKernelTypeStep.final result =>
                      match result with
                      | PsKernelTypeResult.done kind =>
                          match kind with
                          | PsKernelExpr.sortE unused => psKernelAlgConstructorNext env header input
                              (PsKernelAlgConstructorTask.reverse reversed PsKernelList.nil)
                          | _ => PsKernelAlgConstructorStep.rejected PsKernelCheckError.typeExpected
                      | PsKernelTypeResult.rejected error => PsKernelAlgConstructorStep.rejected error
                      | _ => PsKernelAlgConstructorStep.rejected PsKernelCheckError.invalidState
              | PsKernelAlgConstructorTask.reverse pending fields =>
                  match pending with
                  | PsKernelList.cons field rest => psKernelAlgConstructorNext env header input
                      (PsKernelAlgConstructorTask.reverse rest (PsKernelList.cons field fields))
                  | PsKernelList.nil => PsKernelAlgConstructorStep.accepted (PsKernelAlgConstructor.constructor name type fields)

def psKernelAlgConstructorStart (env : PsKernelList PsKernelDefinition) (header : PsKernelAlgHeader)
    (input : PsKernelAlgInputConstructor) : PsKernelAlgConstructorState :=
  match input with
  | PsKernelAlgInputConstructor.constructor unusedName type =>
      PsKernelAlgConstructorState.state env header input
        (PsKernelAlgConstructorTask.scope (psKernelBindingStart PsKernelBindingMode.closed PsKernelNatural.zero type))

def psKernelAlgConstructorRun (fuel : PsKernelFuel) : PsKernelAlgConstructorState -> PsKernelAlgConstructorResult :=
  match fuel with
  | PsKernelFuel.stop => fun (state : PsKernelAlgConstructorState) => PsKernelAlgConstructorResult.outOfFuel
  | PsKernelFuel.more remaining =>
      fun (state : PsKernelAlgConstructorState) =>
        match psKernelAlgConstructorStep state with
        | PsKernelAlgConstructorStep.accepted constructor => PsKernelAlgConstructorResult.accepted constructor
        | PsKernelAlgConstructorStep.rejected error => PsKernelAlgConstructorResult.rejected error
        | PsKernelAlgConstructorStep.next next =>
            let smaller : PsKernelAlgConstructorState -> PsKernelAlgConstructorResult := psKernelAlgConstructorRun remaining;
            smaller next
