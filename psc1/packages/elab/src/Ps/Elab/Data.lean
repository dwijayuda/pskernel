import Ps.Elab.Basic
import Ps.Core.Abstract
import Ps.Core.Subst
import Ps.Environment.SelfHostProd

def PsDataElaborator : Type :=
  PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
    Except PsElabError PsElabTermResult

def psDataApply (name : PsName) (args : List PsExpr) : PsExpr :=
  psExprApplyMany (PsExpr.constE name []) args

def psDataOptionIf (type condition yes no : PsExpr) : PsExpr :=
  let boolType : PsExpr := PsExpr.constE psBoolName [];
  let trueValue : PsExpr := PsExpr.constE psBoolTrueName [];
  let proposition := psExprApplyMany
    (PsExpr.constE psEqName [PsLevel.succ PsLevel.zero]) [boolType, condition, trueValue];
  let decision := psDataApply psBoolDecEqName [condition, trueValue];
  psExprApplyMany (PsExpr.constE psIteName [PsLevel.succ PsLevel.zero])
    [type, proposition, decision, yes, no]

def psDataArrayExpected (context : PsElabContext) (expected : Option PsExpr) :
    Option PsExpr :=
  match expected with
  | Option.none => Option.none
  | Option.some type =>
      match psWhnf context.environment context.metaContext context.localContext type with
      | PsExpr.app fn element =>
          match fn with
          | PsExpr.constE name _ =>
              if psNameEq name psOptionName then
                Option.some (PsExpr.app (PsExpr.constE psArrayName []) element)
              else Option.none
          | _ => Option.none
      | _ => Option.none

def psDataArrayElement (context : PsElabContext) (type : PsExpr) :
    Except PsElabError PsExpr :=
  match psWhnf context.environment context.metaContext context.localContext type with
  | PsExpr.app fn element =>
      match fn with
      | PsExpr.constE name _ =>
          if psNameEq name psArrayName then Except.ok element
          else Except.error PsElabError.unsupportedTerm
      | _ => Except.error PsElabError.unsupportedTerm
  | _ => Except.error PsElabError.unsupportedTerm

/-- The two Core lets evaluate array then index exactly once.
The checked fold visits the finite array without a runtime fuel bound. -/
def psElabArrayGetOption
    (elaborate : PsDataElaborator) (context : PsElabContext)
    (array index : PsSyntaxTerm) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  let arrayExpected : Option PsExpr := psDataArrayExpected context expected;
  match elaborate context array arrayExpected with
  | Except.error error => Except.error error
  | Except.ok arrayResult =>
      match psDataArrayElement arrayResult.context arrayResult.type with
      | Except.error error => Except.error error
      | Except.ok elementType =>
          let natType : PsExpr := PsExpr.constE psNatName [];
          match elaborate arrayResult.context index (Option.some natType) with
          | Except.error error => Except.error error
          | Except.ok indexResult =>
              let metas := indexResult.context.metaContext;
              let element := psMetaInstantiate metas elementType;
              let arrayType : PsExpr := PsExpr.app (PsExpr.constE psArrayName []) element;
              let optionType := psSelfHostOptionOf element;
              let stateType := psSelfHostProdOf natType optionType;
              let arrayName := PsName.num (psRootName "arrayLookup") 0;
              let indexName := PsName.num (psRootName "arrayLookup") 1;
              let stateName := PsName.num (psRootName "arrayLookup") 2;
              let valueName := PsName.num (psRootName "arrayLookup") 3;
              let arrayBinding := psLocalPushBinding indexResult.context.localContext
                arrayName arrayType PsBinderInfo.explicit;
              let indexBinding := psLocalPushBinding arrayBinding.context indexName natType PsBinderInfo.explicit;
              let stateBinding := psLocalPushBinding indexBinding.context stateName stateType PsBinderInfo.explicit;
              let valueBinding := psLocalPushBinding stateBinding.context valueName element PsBinderInfo.explicit;
              let arrayValue : PsExpr := PsExpr.fvar arrayBinding.id;
              let indexValue : PsExpr := PsExpr.fvar indexBinding.id;
              let stateValue : PsExpr := PsExpr.fvar stateBinding.id;
              let value : PsExpr := PsExpr.fvar valueBinding.id;
              let position : PsExpr := PsExpr.proj psProdName 0 stateValue;
              let previous : PsExpr := PsExpr.proj psProdName 1 stateValue;
              let selected := psDataOptionIf optionType
                (psDataApply psNatBeqName [position, indexValue])
                (psSelfHostOptionSomeOf element value) previous;
              let next := psSelfHostProdMkOf natType optionType
                (psDataApply psNatSuccName [position]) selected;
              let valueLambda := PsExpr.lam valueName element
                (psExprAbstractFVar valueBinding.id next) PsBinderInfo.explicit;
              let step := PsExpr.lam stateName stateType
                (psExprAbstractFVar stateBinding.id valueLambda) PsBinderInfo.explicit;
              let zero : PsExpr := PsExpr.lit (PsLiteral.natural 0);
              let initial := psSelfHostProdMkOf natType optionType zero
                (psSelfHostOptionNoneOf element);
              let folded := psDataApply psArrayFoldlName
                [element, stateType, step, initial, arrayValue, zero,
                  psDataApply psArraySizeName [element, arrayValue]];
              let result : PsExpr := PsExpr.proj psProdName 1 folded;
              let withIndex := PsExpr.letE indexName natType
                (psMetaInstantiate metas indexResult.term)
                (psExprAbstractFVar indexBinding.id result);
              let withArray := PsExpr.letE arrayName arrayType
                (psMetaInstantiate metas arrayResult.term)
                (psExprAbstractFVar arrayBinding.id withIndex);
              psElabResolvedTerm indexResult.context withArray expected

def psBindingNameSeen (name : PsName) (names : List PsName) : Bool :=
  match names with
  | List.nil => false
  | List.cons first rest =>
      if psNameEq name first then true else psBindingNameSeen name rest

def psElabCheckBindingNamesWorker (sources : List PsSyntaxName) :
    List PsName -> Except PsElabError Unit :=
  match sources with
  | List.nil => fun (seen : List PsName) => Except.ok Unit.unit
  | List.cons source rest =>
      fun (seen : List PsName) =>
        let smaller : List PsName -> Except PsElabError Unit :=
          psElabCheckBindingNamesWorker rest;
        match source.segments with
        | List.nil => Except.error PsElabError.matchPatternUnsupported
        | List.cons text tail =>
            match tail with
            | List.nil =>
                if psStringEq text "_" then Except.error PsElabError.matchPatternUnsupported
                else
                  match psSyntaxNameToName source with
                  | Option.none => Except.error PsElabError.emptyName
                  | Option.some name =>
                      if psBindingNameSeen name seen then Except.error PsElabError.matchPatternUnsupported
                      else smaller (List.cons name seen)
            | _ => Except.error PsElabError.matchPatternUnsupported

def psElabCheckBindingNames (sources : List PsSyntaxName) (seen : List PsName) :
    Except PsElabError Unit :=
  psElabCheckBindingNamesWorker sources seen

def psElabPatternWithLocal
    (next : PsElabContext -> Nat -> Except PsElabError PsElabTermResult)
    (outer : PsElabContext) (name : PsName) (type : PsExpr)
    (value : PsElabTermResult) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  let pushed := psLocalPushLet value.context.localContext name type value.term;
  let bodyContext := psElabContextWithLocal value.context pushed.context;
  match next bodyContext pushed.id with
  | Except.error error => Except.error error
  | Except.ok body =>
      let metas := body.context.metaContext;
      let term := PsExpr.letE name (psMetaInstantiate metas type)
        (psMetaInstantiate metas value.term)
        (psExprAbstractFVar pushed.id (psMetaInstantiate metas body.term));
      psElabResolvedTerm (psElabContextWithMeta outer metas) term expected

def psDataProdFields (context : PsElabContext) (type : PsExpr) :
    Except PsElabError (Prod PsExpr PsExpr) :=
  match psWhnf context.environment context.metaContext context.localContext type with
  | PsExpr.app left beta =>
      match left with
      | PsExpr.app fn alpha =>
          match fn with
          | PsExpr.constE name _ =>
              if psNameEq name psProdName then Except.ok (Prod.mk alpha beta)
              else Except.error PsElabError.matchPatternUnsupported
          | _ => Except.error PsElabError.matchPatternUnsupported
      | _ => Except.error PsElabError.matchPatternUnsupported
  | _ => Except.error PsElabError.matchPatternUnsupported

def psElabBindingPatternFieldsWorker (pattern : PsSyntaxBindingPattern) :
    PsElabContext -> PsExpr -> PsExpr -> Option PsExpr ->
    (PsElabContext -> Except PsElabError PsElabTermResult) ->
    Except PsElabError PsElabTermResult :=
  match pattern with
  | PsSyntaxBindingPattern.wildcard _ =>
      fun (context : PsElabContext) (value : PsExpr) (type : PsExpr)
          (expected : Option PsExpr)
          (next : PsElabContext -> Except PsElabError PsElabTermResult) =>
        next context
  | PsSyntaxBindingPattern.unit _ =>
      fun (context : PsElabContext) (value : PsExpr) (type : PsExpr)
          (expected : Option PsExpr)
          (next : PsElabContext -> Except PsElabError PsElabTermResult) =>
        match psElabResolvedTerm context value (Option.some (PsExpr.constE psUnitName [])) with
        | Except.error error => Except.error error
        | Except.ok checked => next checked.context
  | PsSyntaxBindingPattern.name source =>
      fun (context : PsElabContext) (value : PsExpr) (type : PsExpr)
          (expected : Option PsExpr)
          (next : PsElabContext -> Except PsElabError PsElabTermResult) =>
        match psSyntaxNameToName source with
        | Option.none => Except.error PsElabError.emptyName
        | Option.some name =>
            match psElabResolvedTerm context value (Option.some type) with
            | Except.error error => Except.error error
            | Except.ok checked =>
                psElabPatternWithLocal
                  (fun (bodyContext : PsElabContext) (id : Nat) => next bodyContext)
                  context name checked.type checked expected
  | PsSyntaxBindingPattern.pair first second _ =>
      fun (context : PsElabContext) (value : PsExpr) (type : PsExpr)
          (expected : Option PsExpr)
          (next : PsElabContext -> Except PsElabError PsElabTermResult) =>
        let firstFields : PsElabContext -> PsExpr -> PsExpr -> Option PsExpr ->
            (PsElabContext -> Except PsElabError PsElabTermResult) ->
            Except PsElabError PsElabTermResult := psElabBindingPatternFieldsWorker first;
        let secondFields : PsElabContext -> PsExpr -> PsExpr -> Option PsExpr ->
            (PsElabContext -> Except PsElabError PsElabTermResult) ->
            Except PsElabError PsElabTermResult := psElabBindingPatternFieldsWorker second;
        match psDataProdFields context type with
        | Except.error error => Except.error error
        | Except.ok fields =>
            match psElabResolvedTerm context (PsExpr.proj psProdName 0 value)
                (Option.some fields.fst) with
            | Except.error error => Except.error error
            | Except.ok firstValue =>
                firstFields firstValue.context firstValue.term firstValue.type expected
                  (fun (firstContext : PsElabContext) =>
                    match psElabResolvedTerm firstContext (PsExpr.proj psProdName 1 value)
                        (Option.some (psMetaInstantiate firstContext.metaContext fields.snd)) with
                    | Except.error error => Except.error error
                    | Except.ok secondValue =>
                        secondFields secondValue.context secondValue.term secondValue.type expected next)

def psElabBindingPatternFields
    (pattern : PsSyntaxBindingPattern) (context : PsElabContext)
    (value type : PsExpr) (expected : Option PsExpr)
    (next : PsElabContext -> Except PsElabError PsElabTermResult) :
    Except PsElabError PsElabTermResult :=
  psElabBindingPatternFieldsWorker pattern context value type expected next

/-- Immutable/procedural binding keeps its RHS under a fresh numeric Core name. -/
def psElabLetPattern
    (elaborate : PsDataElaborator) (context : PsElabContext)
    (pattern : PsSyntaxBindingPattern) (annotation : Option PsSyntaxTerm)
    (value : PsSyntaxTerm)
    (next : PsElabContext -> Except PsElabError PsElabTermResult)
    (expected : Option PsExpr) : Except PsElabError PsElabTermResult :=
  match psElabCheckBindingNames (psSyntaxBindingPatternNames pattern) [] with
  | Except.error error => Except.error error
  | Except.ok checkedNames =>
      let valueResult : Except PsElabError PsElabTermResult :=
        match annotation with
        | Option.none => elaborate context value Option.none
        | Option.some sourceType =>
            match elaborate context sourceType Option.none with
            | Except.error error => Except.error error
            | Except.ok typeResult =>
                match psInferEnsureSort typeResult.context.environment
                    typeResult.context.metaContext typeResult.context.localContext typeResult.type with
                | Except.error error => Except.error (PsElabError.infer error)
                | Except.ok _ => elaborate typeResult.context value (Option.some typeResult.term);
      match valueResult with
      | Except.error error => Except.error error
      | Except.ok valueResult =>
          let type := psMetaInstantiate valueResult.context.metaContext valueResult.type;
          let temporary := PsName.num (psRootName "_psc1Pattern") valueResult.context.localContext.nextId;
          psElabPatternWithLocal
            (fun (bodyContext : PsElabContext) (id : Nat) =>
              psElabBindingPatternFields pattern bodyContext (PsExpr.fvar id) type expected next)
            context temporary type valueResult expected
