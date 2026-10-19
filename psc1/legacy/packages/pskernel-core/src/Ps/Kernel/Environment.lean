import Ps.Kernel.Data
import Ps.Kernel.Expr
import Ps.Kernel.Order
import Ps.Kernel.AlgebraicData

/- Internal declarations. A list is NOT a trusted environment merely
because it has this representation. Only fresh replay through Admission checks it. -/
inductive PsKernelDefinitionBody where
  | transparent (value : PsKernelExpr)
  | opaque

/- Sum rules are derived by checked admission, never accepted as wire metadata. -/
inductive PsKernelSumRule where
  | rule (name : PsKernelName) (reversedFields : PsKernelList PsKernelExpr) (fieldCount : PsKernelNatural)

inductive PsKernelDefinition where
  | algebraicFamily (name : PsKernelName) (type : PsKernelExpr) (parameters : PsKernelNatural)
      (constructors : PsKernelList PsKernelAlgConstructor)
  | algebraicRecursor (name : PsKernelName) (levels : PsKernelList PsKernelName) (type : PsKernelExpr)
      (parameters : PsKernelNatural) (rules : PsKernelList PsKernelAlgRule)
  | stringType (name : PsKernelName)
  | definition (name : PsKernelName) (type : PsKernelExpr) (value : PsKernelExpr)
  | polymorphic (name : PsKernelName) (parameters : PsKernelList PsKernelName) (type : PsKernelExpr) (value : PsKernelExpr)
  | constant (name : PsKernelName) (parameters : PsKernelList PsKernelName) (type : PsKernelExpr)
  | unitRecursor (name : PsKernelName) (parameters : PsKernelList PsKernelName) (type : PsKernelExpr) (ctorName : PsKernelName)

  | enumRecursor (name : PsKernelName) (parameters : PsKernelList PsKernelName) (type : PsKernelExpr) (constructors : PsKernelList PsKernelName)
  | sumRecursor (name : PsKernelName) (parameters : PsKernelList PsKernelName) (type : PsKernelExpr) (rules : PsKernelList PsKernelSumRule)
  | recordFamily (name ctorName : PsKernelName) (fields : PsKernelList PsKernelExpr)
  | recordRecursor (name : PsKernelName) (parameters : PsKernelList PsKernelName) (type : PsKernelExpr)
      (ctorName : PsKernelName) (fields : PsKernelList PsKernelExpr)
  | natFamily (name zeroName succName : PsKernelName)
  | natRecursor (name : PsKernelName) (parameters : PsKernelList PsKernelName) (type : PsKernelExpr) (zeroName succName : PsKernelName)

def psKernelDefinitionName (entry : PsKernelDefinition) : PsKernelName :=
  match entry with
  | PsKernelDefinition.definition name unusedType unusedValue => name
  | PsKernelDefinition.polymorphic name unusedParameters unusedType unusedValue => name
  | PsKernelDefinition.constant name parameters type => name
  | PsKernelDefinition.unitRecursor name parameters type unusedConstructor => name
  | PsKernelDefinition.enumRecursor name unusedParameters unusedType unusedConstructors => name
  | PsKernelDefinition.sumRecursor name unusedParameters unusedType unusedRules => name
  | PsKernelDefinition.recordFamily name unusedCtor unusedFields => name
  | PsKernelDefinition.recordRecursor name unusedParameters unusedType unusedCtor unusedFields => name
  | PsKernelDefinition.algebraicFamily name unusedType unusedParameters unusedConstructors => name
  | PsKernelDefinition.algebraicRecursor name unusedLevels unusedType unusedParameters unusedRules => name
  | PsKernelDefinition.stringType name => name
  | PsKernelDefinition.natFamily name unusedZero unusedSucc => name
  | PsKernelDefinition.natRecursor name parameters type unusedZero unusedSucc => name

def psKernelDefinitionParameters (entry : PsKernelDefinition) : PsKernelList PsKernelName :=
  match entry with
  | PsKernelDefinition.definition unusedName unusedType unusedValue => PsKernelList.nil
  | PsKernelDefinition.polymorphic unusedName parameters unusedType unusedValue => parameters
  | PsKernelDefinition.constant name parameters type => parameters
  | PsKernelDefinition.unitRecursor name parameters type unusedConstructor => parameters
  | PsKernelDefinition.enumRecursor unusedName parameters unusedType unusedConstructors => parameters
  | PsKernelDefinition.sumRecursor unusedName parameters unusedType unusedRules => parameters
  | PsKernelDefinition.recordFamily unusedName unusedCtor unusedFields => PsKernelList.nil
  | PsKernelDefinition.recordRecursor unusedName parameters unusedType unusedCtor unusedFields => parameters
  | PsKernelDefinition.algebraicFamily unusedName unusedType unusedParameters unusedConstructors => PsKernelList.nil
  | PsKernelDefinition.algebraicRecursor unusedName levels unusedType unusedParameters unusedRules => levels
  | PsKernelDefinition.stringType unusedName => PsKernelList.nil
  | PsKernelDefinition.natFamily name unusedZero unusedSucc => PsKernelList.nil
  | PsKernelDefinition.natRecursor name parameters type unusedZero unusedSucc => parameters

def psKernelDefinitionType (entry : PsKernelDefinition) : PsKernelExpr :=
  match entry with
  | PsKernelDefinition.definition unusedName type unusedValue => type
  | PsKernelDefinition.polymorphic unusedName unusedParameters type unusedValue => type
  | PsKernelDefinition.constant name parameters type => type
  | PsKernelDefinition.unitRecursor name parameters type unusedConstructor => type
  | PsKernelDefinition.enumRecursor unusedName unusedParameters type unusedConstructors => type
  | PsKernelDefinition.sumRecursor unusedName unusedParameters type unusedRules => type
  | PsKernelDefinition.recordFamily unusedName unusedCtor unusedFields => PsKernelExpr.sortE (PsKernelLevel.succ PsKernelLevel.zero)
  | PsKernelDefinition.recordRecursor unusedName unusedParameters type unusedCtor unusedFields => type
  | PsKernelDefinition.algebraicFamily unusedName type unusedParameters unusedConstructors => type
  | PsKernelDefinition.algebraicRecursor unusedName unusedLevels type unusedParameters unusedRules => type
  | PsKernelDefinition.stringType unusedName => PsKernelExpr.sortE (PsKernelLevel.succ PsKernelLevel.zero)
  | PsKernelDefinition.natFamily name unusedZero unusedSucc => PsKernelExpr.sortE (PsKernelLevel.succ PsKernelLevel.zero)
  | PsKernelDefinition.natRecursor name parameters type unusedZero unusedSucc => type

def psKernelDefinitionBody (entry : PsKernelDefinition) : PsKernelDefinitionBody :=
  match entry with
  | PsKernelDefinition.definition unusedName unusedType value => PsKernelDefinitionBody.transparent value
  | PsKernelDefinition.polymorphic unusedName unusedParameters unusedType value => PsKernelDefinitionBody.transparent value
  | PsKernelDefinition.constant unusedName unusedParameters unusedType => PsKernelDefinitionBody.opaque
  | PsKernelDefinition.unitRecursor unusedName unusedParameters unusedType unusedConstructor => PsKernelDefinitionBody.opaque

  | PsKernelDefinition.enumRecursor unusedName unusedParameters unusedType unusedConstructors => PsKernelDefinitionBody.opaque
  | PsKernelDefinition.sumRecursor unusedName unusedParameters unusedType unusedRules => PsKernelDefinitionBody.opaque
  | PsKernelDefinition.recordFamily unusedName unusedCtor unusedFields => PsKernelDefinitionBody.opaque
  | PsKernelDefinition.recordRecursor unusedName unusedParameters unusedType unusedCtor unusedFields => PsKernelDefinitionBody.opaque
  | PsKernelDefinition.algebraicFamily unusedName unusedType unusedParameters unusedConstructors => PsKernelDefinitionBody.opaque
  | PsKernelDefinition.algebraicRecursor unusedName unusedLevels unusedType unusedParameters unusedRules => PsKernelDefinitionBody.opaque
  | PsKernelDefinition.stringType unusedName => PsKernelDefinitionBody.opaque
  | PsKernelDefinition.natFamily unusedName unusedZero unusedSucc => PsKernelDefinitionBody.opaque
  | PsKernelDefinition.natRecursor unusedName unusedParameters unusedType unusedZero unusedSucc => PsKernelDefinitionBody.opaque

inductive PsKernelTypingContext where
  | context (declarations : PsKernelList PsKernelDefinition) (parameters : PsKernelList PsKernelName)

def psKernelTypingDeclarations (context : PsKernelTypingContext) : PsKernelList PsKernelDefinition :=
  match context with
  | PsKernelTypingContext.context declarations unusedParameters => declarations

def psKernelTypingParameters (context : PsKernelTypingContext) : PsKernelList PsKernelName :=
  match context with
  | PsKernelTypingContext.context unusedDeclarations parameters => parameters

inductive PsKernelCheckError where
  | invalidText
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
