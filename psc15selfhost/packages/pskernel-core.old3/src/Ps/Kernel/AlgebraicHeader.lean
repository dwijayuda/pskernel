import Ps.Kernel.TypeCheck
import Ps.Kernel.AlgebraicData

/- The family header is checked before any provisional family authority exists.
Only uniformly parameterized Type0 families are in this fragment. -/
def psKernelAlgType : PsKernelExpr := PsKernelExpr.sortE (PsKernelLevel.succ PsKernelLevel.zero)

inductive PsKernelAlgHeaderTask where
  | initial
  | scope (state : PsKernelBindingState)
  | name (state : PsKernelLookupState)
  | type (state : PsKernelTypeState)
  | parameters (remainingType : PsKernelExpr) (remaining nextId : PsKernelNatural)
      (reversed : PsKernelList PsKernelExpr) (binders : PsKernelList PsKernelAlgBinder) (uniform : PsKernelExpr)
  | reverse (pending arguments : PsKernelList PsKernelExpr)
      (binders : PsKernelList PsKernelAlgBinder) (uniform : PsKernelExpr)

inductive PsKernelAlgHeaderState where
  | state (environment : PsKernelList PsKernelDefinition) (declaration : PsKernelAlgDeclaration)
      (task : PsKernelAlgHeaderTask)

inductive PsKernelAlgHeaderStep where
  | next (state : PsKernelAlgHeaderState)
  | accepted (header : PsKernelAlgHeader)
  | rejected (error : PsKernelCheckError)

def psKernelAlgHeaderNext (env : PsKernelList PsKernelDefinition) (declaration : PsKernelAlgDeclaration)
    (task : PsKernelAlgHeaderTask) : PsKernelAlgHeaderStep :=
  PsKernelAlgHeaderStep.next (PsKernelAlgHeaderState.state env declaration task)

def psKernelAlgHeaderStep (state : PsKernelAlgHeaderState) : PsKernelAlgHeaderStep :=
  match state with
  | PsKernelAlgHeaderState.state env declaration task =>
      match declaration with
      | PsKernelAlgDeclaration.declaration name parameters type constructors =>
          match task with
          | PsKernelAlgHeaderTask.initial =>
              match name with
              | PsKernelName.anonymous => PsKernelAlgHeaderStep.rejected PsKernelCheckError.invalidName
              | _ =>
                  match constructors with
                  | PsKernelList.nil => PsKernelAlgHeaderStep.rejected PsKernelCheckError.unsupported
                  | PsKernelList.cons unusedHead unusedTail => psKernelAlgHeaderNext env declaration
                      (PsKernelAlgHeaderTask.scope (psKernelBindingStart PsKernelBindingMode.closed PsKernelNatural.zero type))
          | PsKernelAlgHeaderTask.scope current =>
              match psKernelBindingStep current with
              | PsKernelBindingStep.next next => psKernelAlgHeaderNext env declaration (PsKernelAlgHeaderTask.scope next)
              | PsKernelBindingStep.final result =>
                  match result with
                  | PsKernelBindingResult.done unused => psKernelAlgHeaderNext env declaration
                      (PsKernelAlgHeaderTask.name (PsKernelLookupState.search name env))
                  | PsKernelBindingResult.invalidScope => PsKernelAlgHeaderStep.rejected PsKernelCheckError.invalidScope
                  | _ => PsKernelAlgHeaderStep.rejected PsKernelCheckError.invalidState
          | PsKernelAlgHeaderTask.name current =>
              match psKernelLookupStep current with
              | PsKernelLookupStep.next next => psKernelAlgHeaderNext env declaration (PsKernelAlgHeaderTask.name next)
              | PsKernelLookupStep.missing => psKernelAlgHeaderNext env declaration (PsKernelAlgHeaderTask.type (psKernelInferStart env type))
              | PsKernelLookupStep.found unused => PsKernelAlgHeaderStep.rejected PsKernelCheckError.duplicateName
              | _ => PsKernelAlgHeaderStep.rejected PsKernelCheckError.invalidState
          | PsKernelAlgHeaderTask.type current =>
              match psKernelTypeStep current with
              | PsKernelTypeStep.next next => psKernelAlgHeaderNext env declaration (PsKernelAlgHeaderTask.type next)
              | PsKernelTypeStep.final result =>
                  match result with
                  | PsKernelTypeResult.done kind =>
                      match kind with
                      | PsKernelExpr.sortE unused => psKernelAlgHeaderNext env declaration
                          (PsKernelAlgHeaderTask.parameters type parameters PsKernelNatural.zero PsKernelList.nil PsKernelList.nil
                            (PsKernelExpr.constE name PsKernelList.nil))
                      | _ => PsKernelAlgHeaderStep.rejected PsKernelCheckError.typeExpected
                  | PsKernelTypeResult.rejected error => PsKernelAlgHeaderStep.rejected error
                  | _ => PsKernelAlgHeaderStep.rejected PsKernelCheckError.invalidState
          | PsKernelAlgHeaderTask.parameters remainingType remaining nextId reversed binders uniform =>
              match remaining with
              | PsKernelNatural.zero =>
                  match remainingType with
                  | PsKernelExpr.sortE level =>
                      match level with
                      | PsKernelLevel.succ inner =>
                          match inner with
                          | PsKernelLevel.zero => psKernelAlgHeaderNext env declaration
                              (PsKernelAlgHeaderTask.reverse reversed PsKernelList.nil binders uniform)
                          | _ => PsKernelAlgHeaderStep.rejected PsKernelCheckError.unsupported
                      | _ => PsKernelAlgHeaderStep.rejected PsKernelCheckError.unsupported
                  | _ => PsKernelAlgHeaderStep.rejected PsKernelCheckError.unsupported
              | _ =>
                  match remainingType with
                  | PsKernelExpr.forallE unusedName domain body unusedBinder =>
                      match domain with
                      | PsKernelExpr.sortE level =>
                          match level with
                          | PsKernelLevel.succ inner =>
                              match inner with
                              | PsKernelLevel.zero => psKernelAlgHeaderNext env declaration
                                  (PsKernelAlgHeaderTask.parameters body (psKernelNaturalPred remaining) (psKernelNaturalSucc nextId)
                                    (PsKernelList.cons (PsKernelExpr.fvar nextId) reversed)
                                    (PsKernelList.cons (PsKernelAlgBinder.binder nextId psKernelAlgType PsKernelBinder.implicit) binders)
                                    (PsKernelExpr.app uniform (PsKernelExpr.fvar nextId)))
                              | _ => PsKernelAlgHeaderStep.rejected PsKernelCheckError.unsupported
                          | _ => PsKernelAlgHeaderStep.rejected PsKernelCheckError.unsupported
                      | _ => PsKernelAlgHeaderStep.rejected PsKernelCheckError.unsupported
                  | _ => PsKernelAlgHeaderStep.rejected PsKernelCheckError.typeMismatch
          | PsKernelAlgHeaderTask.reverse pending arguments binders uniform =>
              match pending with
              | PsKernelList.cons argument rest => psKernelAlgHeaderNext env declaration
                  (PsKernelAlgHeaderTask.reverse rest (PsKernelList.cons argument arguments) binders uniform)
              | PsKernelList.nil => PsKernelAlgHeaderStep.accepted
                  (PsKernelAlgHeader.header name type parameters arguments binders uniform)

def psKernelAlgHeaderStart (env : PsKernelList PsKernelDefinition) (declaration : PsKernelAlgDeclaration) : PsKernelAlgHeaderState :=
  PsKernelAlgHeaderState.state env declaration PsKernelAlgHeaderTask.initial
