import Ps.Elab.Basic
import Ps.Core.Builtin

abbrev PsOperatorElaborator :=
  PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
    Except PsElabError PsElabTermResult

structure PsElabOperatorOperands where
  context : PsElabContext
  left : PsExpr
  right : PsExpr
  type : PsExpr

def psOperatorIsNatural : PsSyntaxTerm -> Bool
  | .natural _ _ => true
  | _ => false

/-- Both operands are elaborated once. When no result type constrains a leading
literal, a nonliteral right operand can provide its type. This changes constraint
order only: the constructed runtime term retains left-to-right evaluation. -/
def psElabOperatorOperands
    (elaborate : PsOperatorElaborator) (context : PsElabContext)
    (left right : PsSyntaxTerm) (expectedOperand : Option PsExpr) :
    Except PsElabError PsElabOperatorOperands := do
  if expectedOperand.isNone && psOperatorIsNatural left &&
      !psOperatorIsNatural right then
    let r ← elaborate context right none
    let l ← elaborate r.context left (some r.type)
    let metaContext := l.context.metaContext
    return { context := l.context
             left := psMetaInstantiate metaContext l.term
             right := psMetaInstantiate metaContext r.term
             type := psMetaInstantiate metaContext l.type }
  else
    let l ← elaborate context left expectedOperand
    let r ← elaborate l.context right (some l.type)
    let metaContext := r.context.metaContext
    return { context := r.context
             left := psMetaInstantiate metaContext l.term
             right := psMetaInstantiate metaContext r.term
             type := psMetaInstantiate metaContext r.type }

def psOperatorApply (name : PsName) (left right : PsExpr) : PsExpr :=
  .app (.app (.constE name []) left) right

def psOperatorBoolIte (condition yes no : PsExpr) : PsExpr :=
  let boolType := PsExpr.constE psBoolName []
  let trueValue := PsExpr.constE psBoolTrueName []
  let proposition :=
    PsExpr.app (PsExpr.app (PsExpr.app
      (.constE psEqName [PsLevel.succ PsLevel.zero]) boolType) condition) trueValue
  let decider := psOperatorApply psBoolDecEqName condition trueValue
  PsExpr.app (PsExpr.app (PsExpr.app (PsExpr.app (PsExpr.app
    (.constE psIteName [PsLevel.succ PsLevel.zero]) boolType)
    proposition) decider) yes) no

def psOperatorArithmeticName (operator : String) (domain : PsName) : Option PsName :=
  if psNameEq domain psNatName then
    if operator == "+" then some psNatAddName
    else if operator == "-" then some psNatSubName
    else if operator == "*" then some psNatMulName
    else if operator == "/" then some psNatDivName
    else if operator == "%" then some psNatModName
    else none
  else if psNameEq domain psIntName then
    if operator == "+" then some psIntAddName
    else if operator == "-" then some psIntSubName
    else if operator == "*" then some psIntMulName
    else none
  else none

def psElabUnaryOperator
    (elaborate : PsOperatorElaborator) (context : PsElabContext)
    (operator : String) (operand : PsSyntaxTerm) (span : PsSourceSpan)
    (expected : Option PsExpr) : Except PsElabError PsElabTermResult := do
  if operator == "!" then
    let result ← elaborate context
      (.ifE operand (.bool false span) (.bool true span) span)
      (some (.constE psBoolName []))
    psElabFinalizeExpected result expected
  else if operator == "-" then
    let value ← elaborate context operand (some (.constE psIntName []))
    psElabResolvedTerm value.context
      (.app (.constE psIntNegName []) value.term) expected
  else
    throw .unsupportedTerm

def psElabBinaryOperator
    (elaborate : PsOperatorElaborator) (context : PsElabContext)
    (operator : String) (left right : PsSyntaxTerm) (span : PsSourceSpan)
    (expected : Option PsExpr) : Except PsElabError PsElabTermResult := do
  if operator == "&&" || operator == "||" then
    let conditional : PsSyntaxTerm :=
      if operator == "&&" then .ifE left right (.bool false span) span
      else .ifE left (.bool true span) right span
    let result ← elaborate context conditional (some (.constE psBoolName []))
    psElabFinalizeExpected result expected
  else if operator == "<" || operator == "<=" || operator == "≤" ||
      operator == ">" || operator == ">=" || operator == "≥" then
    -- These are propositions in v7.2. Until their logical/decision declarations
    -- are admitted, do not silently substitute Boolean Nat.blt/Nat.ble.
    throw .unsupportedTerm
  else
    let isEquality := operator == "=" || operator == "==" || operator == "!="
    let operands ← psElabOperatorOperands elaborate context left right
      (if isEquality then none else expected)
    if operator == "=" then
      let typeType ← match psInferType operands.context.environment
          operands.context.metaContext operands.context.localContext operands.type with
        | .error error => throw (.infer error)
        | .ok result => pure result
      let level ← match psInferEnsureSort operands.context.environment
          operands.context.metaContext operands.context.localContext typeType with
        | .error error => throw (.infer error)
        | .ok result => pure result
      let term := PsExpr.app (PsExpr.app (PsExpr.app
        (.constE psEqName [level]) operands.type) operands.left) operands.right
      psElabResolvedTerm operands.context term expected
    else
      let domain := psWhnf operands.context.environment operands.context.metaContext
        operands.context.localContext operands.type
      match domain with
      | .constE name _ =>
          if isEquality then
            let equal ←
              if psNameEq name psNatName then
                pure (psOperatorApply psNatBeqName operands.left operands.right)
              else if psNameEq name psBoolName then
                -- Each branch evaluates the right operand once, after the left.
                pure (psOperatorBoolIte operands.left operands.right
                  (psOperatorBoolIte operands.right
                    (.constE psBoolFalseName []) (.constE psBoolTrueName [])))
              else
                throw .unsupportedTerm
            let result :=
              if operator == "!=" then
                psOperatorBoolIte equal (.constE psBoolFalseName []) (.constE psBoolTrueName [])
              else equal
            psElabResolvedTerm operands.context result expected
          else
            match psOperatorArithmeticName operator name with
            | none => throw .unsupportedTerm
            | some operation =>
                psElabResolvedTerm operands.context
                  (psOperatorApply operation operands.left operands.right) expected
      | _ => throw .unsupportedTerm
