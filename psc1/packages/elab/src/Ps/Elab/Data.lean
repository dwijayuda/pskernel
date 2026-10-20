import Ps.Elab.Basic
import Ps.Core.Abstract
import Ps.Core.Subst
import Ps.Environment.SelfHostProd

abbrev PsDataElaborator :=
  PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
    Except PsElabError PsElabTermResult

private def psDataApply (name : PsName) (args : List PsExpr) : PsExpr :=
  psExprApplyMany (.constE name []) args

private def psDataOptionIf (type condition yes no : PsExpr) : PsExpr :=
  let boolType : PsExpr := .constE psBoolName []
  let trueValue : PsExpr := .constE psBoolTrueName []
  let proposition := psExprApplyMany
    (.constE psEqName [.succ .zero]) [boolType, condition, trueValue]
  let decision := psDataApply psBoolDecEqName [condition, trueValue]
  psExprApplyMany (.constE psIteName [.succ .zero])
    [type, proposition, decision, yes, no]

/-- Optional lookup is a total checked fold, independent of element inhabitation.
The two outer Core lets evaluate the array and index exactly once in source order.
The fold traverses the array from zero to size, with no runtime fuel bound. -/
def psElabArrayGetOption
    (elaborate : PsDataElaborator) (context : PsElabContext)
    (array index : PsSyntaxTerm) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult := do
  let arrayExpected : Option PsExpr :=
    match expected with
    | none => none
    | some type =>
        match psWhnf context.environment context.metaContext context.localContext type with
        | .app (.constE name _) element =>
            if psNameEq name psOptionName then
              some (.app (.constE psArrayName []) element)
            else none
        | _ => none
  let arrayResult ← elaborate context array arrayExpected
  let elementType ←
    match psWhnf arrayResult.context.environment arrayResult.context.metaContext
        arrayResult.context.localContext arrayResult.type with
    | .app (.constE name _) element =>
        if psNameEq name psArrayName then pure element
        else throw .unsupportedTerm
    | _ => throw .unsupportedTerm
  let natType : PsExpr := .constE psNatName []
  let indexResult ← elaborate arrayResult.context index (some natType)
  let metas := indexResult.context.metaContext
  let element := psMetaInstantiate metas elementType
  let arrayType : PsExpr := .app (.constE psArrayName []) element
  let optionType := psSelfHostOptionOf element
  let stateType := psSelfHostProdOf natType optionType
  let arrayName := PsName.num (psRootName "arrayLookup") 0
  let indexName := PsName.num (psRootName "arrayLookup") 1
  let stateName := PsName.num (psRootName "arrayLookup") 2
  let valueName := PsName.num (psRootName "arrayLookup") 3
  let arrayBinding := psLocalPushBinding indexResult.context.localContext
    arrayName arrayType .explicit
  let indexBinding := psLocalPushBinding arrayBinding.context indexName natType .explicit
  let stateBinding := psLocalPushBinding indexBinding.context stateName stateType .explicit
  let valueBinding := psLocalPushBinding stateBinding.context valueName element .explicit
  let arrayValue : PsExpr := .fvar arrayBinding.id
  let indexValue : PsExpr := .fvar indexBinding.id
  let stateValue : PsExpr := .fvar stateBinding.id
  let value : PsExpr := .fvar valueBinding.id
  let position : PsExpr := .proj psProdName 0 stateValue
  let previous : PsExpr := .proj psProdName 1 stateValue
  let selected := psDataOptionIf optionType
    (psDataApply psNatBeqName [position, indexValue])
    (psSelfHostOptionSomeOf element value) previous
  let next := psSelfHostProdMkOf natType optionType
    (psDataApply psNatSuccName [position]) selected
  let valueLambda := PsExpr.lam valueName element
    (psExprAbstractFVar valueBinding.id next) .explicit
  let step := PsExpr.lam stateName stateType
    (psExprAbstractFVar stateBinding.id valueLambda) .explicit
  let zero : PsExpr := .lit (.natural 0)
  let initial := psSelfHostProdMkOf natType optionType zero
    (psSelfHostOptionNoneOf element)
  let folded := psDataApply psArrayFoldlName
    [element, stateType, step, initial, arrayValue, zero,
      psDataApply psArraySizeName [element, arrayValue]]
  let result : PsExpr := .proj psProdName 1 folded
  let withIndex := PsExpr.letE indexName natType
    (psMetaInstantiate metas indexResult.term)
    (psExprAbstractFVar indexBinding.id result)
  let withArray := PsExpr.letE arrayName arrayType
    (psMetaInstantiate metas arrayResult.term)
    (psExprAbstractFVar arrayBinding.id withIndex)
  psElabResolvedTerm indexResult.context withArray expected
