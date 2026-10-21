import Ps.Elab.Basic
import Ps.Core.Builtin

def PsOperatorElaborator : Type :=
  PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
    Except PsElabError PsElabTermResult

structure PsElabOperatorOperands where
  context : PsElabContext
  left : PsExpr
  right : PsExpr
  type : PsExpr

def psOperatorIsNatural (term : PsSyntaxTerm) : Bool :=
  match term with
  | PsSyntaxTerm.natural _ _ => true
  | _ => false

/-- Constraint order may infer a leading literal from its right operand.
The constructed runtime expression still evaluates left before right. -/
def psElabOperatorOperands
    (elaborate : PsOperatorElaborator) (context : PsElabContext)
    (left right : PsSyntaxTerm) (expectedOperand : Option PsExpr) :
    Except PsElabError PsElabOperatorOperands :=
  let noExpected : Bool :=
    match expectedOperand with
    | Option.none => true
    | Option.some _ => false;
  if noExpected && psOperatorIsNatural left && !psOperatorIsNatural right then
    match elaborate context right Option.none with
    | Except.error error => Except.error error
    | Except.ok r =>
        match elaborate r.context left (Option.some r.type) with
        | Except.error error => Except.error error
        | Except.ok l =>
            let metas := l.context.metaContext;
            Except.ok (PsElabOperatorOperands.mk l.context
              (psMetaInstantiate metas l.term) (psMetaInstantiate metas r.term)
              (psMetaInstantiate metas l.type))
  else
    match elaborate context left expectedOperand with
    | Except.error error => Except.error error
    | Except.ok l =>
        match elaborate l.context right (Option.some l.type) with
        | Except.error error => Except.error error
        | Except.ok r =>
            let metas := r.context.metaContext;
            Except.ok (PsElabOperatorOperands.mk r.context
              (psMetaInstantiate metas l.term) (psMetaInstantiate metas r.term)
              (psMetaInstantiate metas r.type))

def psOperatorApply (name : PsName) (left right : PsExpr) : PsExpr :=
  PsExpr.app (PsExpr.app (PsExpr.constE name []) left) right

def psOperatorBoolIte (condition yes no : PsExpr) : PsExpr :=
  let boolType := PsExpr.constE psBoolName [];
  let trueValue := PsExpr.constE psBoolTrueName [];
  let proposition :=
    PsExpr.app (PsExpr.app (PsExpr.app
      (PsExpr.constE psEqName [PsLevel.succ PsLevel.zero]) boolType) condition) trueValue;
  let decider := psOperatorApply psBoolDecEqName condition trueValue;
  PsExpr.app (PsExpr.app (PsExpr.app (PsExpr.app (PsExpr.app
    (PsExpr.constE psIteName [PsLevel.succ PsLevel.zero]) boolType)
    proposition) decider) yes) no

def psOperatorArithmeticName (operator : String) (domain : PsName) : Option PsName :=
  if psNameEq domain psNatName then
    if psStringEq operator "+" then Option.some psNatAddName
    else if psStringEq operator "-" then Option.some psNatSubName
    else if psStringEq operator "*" then Option.some psNatMulName
    else if psStringEq operator "/" then Option.some psNatDivName
    else if psStringEq operator "%" then Option.some psNatModName
    else Option.none
  else if psNameEq domain psIntName then
    if psStringEq operator "+" then Option.some psIntAddName
    else if psStringEq operator "-" then Option.some psIntSubName
    else if psStringEq operator "*" then Option.some psIntMulName
    else Option.none
  else Option.none

def psElabUnaryOperator
    (elaborate : PsOperatorElaborator) (context : PsElabContext)
    (operator : String) (operand : PsSyntaxTerm) (span : PsSourceSpan)
    (expected : Option PsExpr) : Except PsElabError PsElabTermResult :=
  if psStringEq operator "!" then
    match elaborate context
        (PsSyntaxTerm.ifE operand (PsSyntaxTerm.bool false span) (PsSyntaxTerm.bool true span) span)
        (Option.some (PsExpr.constE psBoolName [])) with
    | Except.error error => Except.error error
    | Except.ok result => psElabFinalizeExpected result expected
  else if psStringEq operator "-" then
    match elaborate context operand (Option.some (PsExpr.constE psIntName [])) with
    | Except.error error => Except.error error
    | Except.ok value =>
        psElabResolvedTerm value.context
          (PsExpr.app (PsExpr.constE psIntNegName []) value.term) expected
  else Except.error PsElabError.unsupportedTerm

def psOperatorEqualityTerm (name : PsName) (operands : PsElabOperatorOperands) :
    Except PsElabError PsExpr :=
  if psNameEq name psNatName then
    Except.ok (psOperatorApply psNatBeqName operands.left operands.right)
  else if psNameEq name psBoolName then
    Except.ok (psOperatorBoolIte operands.left operands.right
      (psOperatorBoolIte operands.right
        (PsExpr.constE psBoolFalseName []) (PsExpr.constE psBoolTrueName [])))
  else Except.error PsElabError.unsupportedTerm

def psOperatorOrderName (operator : String) (domain : PsName) : Option PsName :=
  let natural := psNameEq domain psNatName;
  if natural || psNameEq domain psIntName then
    if psStringEq operator "<" then Option.some (if natural then psNatLtName else psIntLtName)
    else if psStringEq operator "<=" || psStringEq operator "≤" then Option.some (if natural then psNatLeName else psIntLeName)
    else if psStringEq operator ">" then Option.some (if natural then psNatGtName else psIntGtName)
    else if psStringEq operator ">=" || psStringEq operator "≥" then Option.some (if natural then psNatGeName else psIntGeName)
    else Option.none
  else Option.none

def psOperatorOrderDecisionName (relation : PsName) : Option PsName :=
  if psNameEq relation psNatLtName then Option.some psNatDecLtName
  else if psNameEq relation psNatLeName then Option.some psNatDecLeName
  else if psNameEq relation psNatGtName then Option.some psNatDecGtName
  else if psNameEq relation psNatGeName then Option.some psNatDecGeName
  else if psNameEq relation psIntLtName then Option.some psIntDecLtName
  else if psNameEq relation psIntLeName then Option.some psIntDecLeName
  else if psNameEq relation psIntGtName then Option.some psIntDecGtName
  else if psNameEq relation psIntGeName then Option.some psIntDecGeName
  else Option.none

structure PsElabCondition where
  context : PsElabContext
  proposition : PsExpr
  decision : PsExpr

-- Try the established Bool context transactionally; only a checked order Prop
-- selects the second path. Failed speculative assignments cannot escape.
def psElabConditionTerm (elaborate : PsOperatorElaborator)
    (context : PsElabContext) (condition : PsSyntaxTerm) :
    Except PsElabError PsElabCondition :=
  match elaborate context condition (Option.some (PsExpr.constE psBoolName [])) with
  | Except.ok value =>
      let proposition := PsExpr.app (PsExpr.app (PsExpr.app
        (PsExpr.constE psEqName [PsLevel.succ PsLevel.zero])
        (PsExpr.constE psBoolName [])) value.term) (PsExpr.constE psBoolTrueName []);
      Except.ok (PsElabCondition.mk value.context proposition
        (psOperatorApply psBoolDecEqName value.term (PsExpr.constE psBoolTrueName [])))
  | Except.error original =>
      match elaborate context condition (Option.some (PsExpr.sortE PsLevel.zero)) with
      | Except.error _ => Except.error original
      | Except.ok value =>
          let proposition := psWhnfCore value.context.metaContext value.context.localContext value.term;
          match proposition with
          | PsExpr.app fn right =>
              match fn with
              | PsExpr.app head left =>
                  match head with
                  | PsExpr.constE name _ =>
                      match psOperatorOrderDecisionName name with
                      | Option.none => Except.error original
                      | Option.some decider =>
                          Except.ok (PsElabCondition.mk value.context proposition
                            (psOperatorApply decider left right))
                  | _ => Except.error original
              | _ => Except.error original
          | _ => Except.error original

def psElabBinaryOperator
    (elaborate : PsOperatorElaborator) (context : PsElabContext)
    (operator : String) (left right : PsSyntaxTerm) (span : PsSourceSpan)
    (expected : Option PsExpr) : Except PsElabError PsElabTermResult :=
  if psStringEq operator "&&" || psStringEq operator "||" then
    let conditional : PsSyntaxTerm :=
      if psStringEq operator "&&" then
        PsSyntaxTerm.ifE left right (PsSyntaxTerm.bool false span) span
      else PsSyntaxTerm.ifE left (PsSyntaxTerm.bool true span) right span;
    match elaborate context conditional (Option.some (PsExpr.constE psBoolName [])) with
    | Except.error error => Except.error error
    | Except.ok result => psElabFinalizeExpected result expected
  else if psStringEq operator "<" || psStringEq operator "<=" || psStringEq operator "≤" ||
      psStringEq operator ">" || psStringEq operator ">=" || psStringEq operator "≥" then
    match psElabOperatorOperands elaborate context left right Option.none with
    | Except.error error => Except.error error
    | Except.ok operands =>
        let domain := psWhnf operands.context.environment operands.context.metaContext
          operands.context.localContext operands.type;
        match domain with
        | PsExpr.constE name _ =>
            match psOperatorOrderName operator name with
            | Option.none => Except.error PsElabError.unsupportedTerm
            | Option.some relation =>
                psElabResolvedTerm operands.context
                  (psOperatorApply relation operands.left operands.right) expected
        | _ => Except.error PsElabError.unsupportedTerm
  else
    let isEquality : Bool :=
      psStringEq operator "=" || psStringEq operator "==" || psStringEq operator "!=";
    let operandExpected : Option PsExpr := if isEquality then Option.none else expected;
    match psElabOperatorOperands elaborate context left right operandExpected with
    | Except.error error => Except.error error
    | Except.ok operands =>
        if psStringEq operator "=" then
          match psInferType operands.context.environment
              operands.context.metaContext operands.context.localContext operands.type with
          | Except.error error => Except.error (PsElabError.infer error)
          | Except.ok typeType =>
              match psInferEnsureSort operands.context.environment
                  operands.context.metaContext operands.context.localContext typeType with
              | Except.error error => Except.error (PsElabError.infer error)
              | Except.ok level =>
                  let term := PsExpr.app (PsExpr.app (PsExpr.app
                    (PsExpr.constE psEqName [level]) operands.type) operands.left) operands.right;
                  psElabResolvedTerm operands.context term expected
        else
          let domain := psWhnf operands.context.environment operands.context.metaContext
            operands.context.localContext operands.type;
          match domain with
          | PsExpr.constE name _ =>
              if isEquality then
                match psOperatorEqualityTerm name operands with
                | Except.error error => Except.error error
                | Except.ok equal =>
                    let result : PsExpr :=
                      if psStringEq operator "!=" then
                        psOperatorBoolIte equal (PsExpr.constE psBoolFalseName []) (PsExpr.constE psBoolTrueName [])
                      else equal;
                    psElabResolvedTerm operands.context result expected
              else
                match psOperatorArithmeticName operator name with
                | Option.none => Except.error PsElabError.unsupportedTerm
                | Option.some operation =>
                    psElabResolvedTerm operands.context
                      (psOperatorApply operation operands.left operands.right) expected
          | _ => Except.error PsElabError.unsupportedTerm
