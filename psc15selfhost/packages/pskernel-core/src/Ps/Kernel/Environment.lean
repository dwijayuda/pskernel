import Ps.Kernel.Data
import Ps.Kernel.Expr
import Ps.Kernel.Order

/- Internal declarations. A list is NOT a trusted environment merely
because it has this representation. Only fresh replay through Admission checks it. -/
inductive PsKernelDefinitionBody where
  | transparent (value : PsKernelExpr)
  | opaque

inductive PsKernelDefinition where
  | definition (name : PsKernelName) (type : PsKernelExpr) (value : PsKernelExpr)
  | polymorphic (name : PsKernelName) (parameters : PsKernelList PsKernelName) (type : PsKernelExpr) (value : PsKernelExpr)
  | constant (name : PsKernelName) (parameters : PsKernelList PsKernelName) (type : PsKernelExpr)

def psKernelDefinitionName (entry : PsKernelDefinition) : PsKernelName :=
  match entry with
  | PsKernelDefinition.definition name unusedType unusedValue => name
  | PsKernelDefinition.polymorphic name unusedParameters unusedType unusedValue => name
  | PsKernelDefinition.constant name parameters type => name

def psKernelDefinitionParameters (entry : PsKernelDefinition) : PsKernelList PsKernelName :=
  match entry with
  | PsKernelDefinition.definition unusedName unusedType unusedValue => PsKernelList.nil
  | PsKernelDefinition.polymorphic unusedName parameters unusedType unusedValue => parameters
  | PsKernelDefinition.constant name parameters type => parameters

def psKernelDefinitionType (entry : PsKernelDefinition) : PsKernelExpr :=
  match entry with
  | PsKernelDefinition.definition unusedName type unusedValue => type
  | PsKernelDefinition.polymorphic unusedName unusedParameters type unusedValue => type
  | PsKernelDefinition.constant name parameters type => type

def psKernelDefinitionBody (entry : PsKernelDefinition) : PsKernelDefinitionBody :=
  match entry with
  | PsKernelDefinition.definition unusedName unusedType value => PsKernelDefinitionBody.transparent value
  | PsKernelDefinition.polymorphic unusedName unusedParameters unusedType value => PsKernelDefinitionBody.transparent value
  | PsKernelDefinition.constant unusedName unusedParameters unusedType => PsKernelDefinitionBody.opaque


inductive PsKernelTypingContext where
  | context (declarations : PsKernelList PsKernelDefinition) (parameters : PsKernelList PsKernelName)

def psKernelTypingDeclarations (context : PsKernelTypingContext) : PsKernelList PsKernelDefinition :=
  match context with
  | PsKernelTypingContext.context declarations unusedParameters => declarations

def psKernelTypingParameters (context : PsKernelTypingContext) : PsKernelList PsKernelName :=
  match context with
  | PsKernelTypingContext.context unusedDeclarations parameters => parameters

inductive PsKernelCheckError where
  | invalidState
  | invalidScope
  | unknownConstant
  | unsupported
  | typeExpected
  | functionExpected
  | typeMismatch
  | duplicateName
  | invalidName
  | invalidUniverse

inductive PsKernelLookupState where
  | search (name : PsKernelName) (entries : PsKernelList PsKernelDefinition)
  | compare (name : PsKernelName) (entry : PsKernelDefinition)
      (rest : PsKernelList PsKernelDefinition) (tasks : PsKernelList PsKernelOrderTask)

inductive PsKernelLookupStep where
  | next (state : PsKernelLookupState)
  | found (entry : PsKernelDefinition)
  | missing
  | invalidState

def psKernelLookupStep (state : PsKernelLookupState) : PsKernelLookupStep :=
  match state with
  | PsKernelLookupState.search name entries =>
      match entries with
      | PsKernelList.nil => PsKernelLookupStep.missing
      | PsKernelList.cons entry rest =>
          PsKernelLookupStep.next (PsKernelLookupState.compare name entry rest
            (PsKernelList.cons (PsKernelOrderTask.name name (psKernelDefinitionName entry)) PsKernelList.nil))
  | PsKernelLookupState.compare name entry rest tasks =>
      match psKernelOrderStep tasks with
      | PsKernelOrderStep.next next =>
          PsKernelLookupStep.next (PsKernelLookupState.compare name entry rest next)
      | PsKernelOrderStep.invalidState => PsKernelLookupStep.invalidState
      | PsKernelOrderStep.done order =>
          match order with
          | PsKernelOrder.same => PsKernelLookupStep.found entry
          | _ => PsKernelLookupStep.next (PsKernelLookupState.search name rest)
