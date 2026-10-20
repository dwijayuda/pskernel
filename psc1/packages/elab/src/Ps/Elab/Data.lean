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

private def psBindingNameSeen (name : PsName) : List PsName -> Bool
  | [] => false
  | first :: rest => if psNameEq name first then true else psBindingNameSeen name rest

private def psElabCheckBindingNames :
    List PsSyntaxName -> List PsName -> Except PsElabError Unit
  | [], _ => .ok ()
  | source :: rest, seen =>
      match source.segments with
      | [text] =>
          if psStringEq text "_" then .error .matchPatternUnsupported
          else
            match psSyntaxNameToName source with
            | none => .error .emptyName
            | some name =>
                if psBindingNameSeen name seen then .error .matchPatternUnsupported
                else psElabCheckBindingNames rest (name :: seen)
      | _ => .error .matchPatternUnsupported

/-- Close a checked Core let while retaining the RHS even if its local is unused.
The fresh local id, rather than a source spelling, establishes binding identity. -/
private def psElabPatternWithLocal
    (next : PsElabContext -> Nat -> Except PsElabError PsElabTermResult)
    (outer : PsElabContext) (name : PsName) (type : PsExpr)
    (value : PsElabTermResult) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult := do
  let pushed := psLocalPushLet value.context.localContext name type value.term
  let bodyContext := psElabContextWithLocal value.context pushed.context
  let body ← next bodyContext pushed.id
  let metas := body.context.metaContext
  let term := PsExpr.letE name (psMetaInstantiate metas type)
    (psMetaInstantiate metas value.term)
    (psExprAbstractFVar pushed.id (psMetaInstantiate metas body.term))
  psElabResolvedTerm (psElabContextWithMeta outer metas) term expected

private def psElabBindingPatternFields
    (pattern : PsSyntaxBindingPattern) (context : PsElabContext)
    (value type : PsExpr) (expected : Option PsExpr)
    (next : PsElabContext -> Except PsElabError PsElabTermResult) :
    Except PsElabError PsElabTermResult := do
  match pattern with
  | .wildcard _ => next context
  | .unit _ =>
      let checked ← psElabResolvedTerm context value (some (.constE psUnitName []))
      next checked.context
  | .name source =>
      let name ← match psSyntaxNameToName source with
        | none => throw .emptyName
        | some name => pure name
      let checked ← psElabResolvedTerm context value (some type)
      psElabPatternWithLocal (fun bodyContext _ => next bodyContext)
        context name checked.type checked expected
  | .pair first second _ =>
      let fields ←
        match psWhnf context.environment context.metaContext context.localContext type with
        | .app (.app (.constE name _) alpha) beta =>
            if psNameEq name psProdName then pure (alpha, beta)
            else throw .matchPatternUnsupported
        | _ => throw .matchPatternUnsupported
      let firstValue ← psElabResolvedTerm context (.proj psProdName 0 value)
        (some fields.fst)
      psElabBindingPatternFields first firstValue.context firstValue.term firstValue.type
        expected (fun firstContext => do
          let secondValue ← psElabResolvedTerm firstContext (.proj psProdName 1 value)
            (some (psMetaInstantiate firstContext.metaContext fields.snd))
          psElabBindingPatternFields second secondValue.context
            secondValue.term secondValue.type expected next)

/-- Immutable ordinary and procedural bindings share this typed lowering. Only
the continuation determines the controller; pattern binding adds no effect or ABI.
The unspellable numeric Core name prevents user names from capturing the RHS. -/
def psElabLetPattern
    (elaborate : PsDataElaborator) (context : PsElabContext)
    (pattern : PsSyntaxBindingPattern) (annotation : Option PsSyntaxTerm)
    (value : PsSyntaxTerm)
    (next : PsElabContext -> Except PsElabError PsElabTermResult)
    (expected : Option PsExpr) : Except PsElabError PsElabTermResult := do
  psElabCheckBindingNames (psSyntaxBindingPatternNames pattern) []
  let valueResult ←
    match annotation with
    | none => elaborate context value none
    | some sourceType => do
        let typeResult ← elaborate context sourceType none
        match psInferEnsureSort typeResult.context.environment
            typeResult.context.metaContext typeResult.context.localContext typeResult.type with
        | .error error => throw (.infer error)
        | .ok _ => elaborate typeResult.context value (some typeResult.term)
  let type := psMetaInstantiate valueResult.context.metaContext valueResult.type
  let temporary := PsName.num (psRootName "_psc1Pattern") valueResult.context.localContext.nextId
  psElabPatternWithLocal
    (fun bodyContext id =>
      psElabBindingPatternFields pattern bodyContext (.fvar id) type expected next)
    context temporary type valueResult expected
