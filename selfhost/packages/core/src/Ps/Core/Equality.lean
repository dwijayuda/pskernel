import Ps.Core.Expr

def psBinderInfoEq (left : PsBinderInfo) (right : PsBinderInfo) : Bool :=
  match left with
  | .explicit =>
      match right with
      | .explicit => true
      | _ => false
  | .implicit =>
      match right with
      | .implicit => true
      | _ => false
  | .strictImplicit =>
      match right with
      | .strictImplicit => true
      | _ => false
  | .instanceImplicit =>
      match right with
      | .instanceImplicit => true
      | _ => false

def psLiteralEq (left : PsLiteral) (right : PsLiteral) : Bool :=
  match left with
  | .natural leftValue =>
      match right with
      | .natural rightValue => leftValue == rightValue
      | _ => false
  | .string leftValue =>
      match right with
      | .string rightValue => leftValue == rightValue
      | _ => false

def psLevelStructuralEq (left : PsLevel) (right : PsLevel) : Bool :=
  match left with
  | .zero =>
      match right with
      | .zero => true
      | _ => false
  | .succ leftValue =>
      match right with
      | .succ rightValue =>
          psLevelStructuralEq leftValue rightValue
      | _ => false
  | .max leftA leftB =>
      match right with
      | .max rightA rightB =>
          psLevelStructuralEq leftA rightA && psLevelStructuralEq leftB rightB
      | _ => false
  | .imax leftA leftB =>
      match right with
      | .imax rightA rightB =>
          psLevelStructuralEq leftA rightA && psLevelStructuralEq leftB rightB
      | _ => false
  | .param leftName =>
      match right with
      | .param rightName => psNameEq leftName rightName
      | _ => false
  | .mvar leftId =>
      match right with
      | .mvar rightId => leftId == rightId
      | _ => false

def psLevelListEq : List PsLevel -> List PsLevel -> Bool
  | [], right =>
      match right with
      | [] => true
      | _ => false
  | left :: leftRest, right =>
      match right with
      | rightValue :: rightRest =>
          psLevelStructuralEq left rightValue
            && psLevelListEq leftRest rightRest
      | _ => false

def psExprAlphaEq (left : PsExpr) (right : PsExpr) : Bool :=
  match left with
  | .bvar leftIndex =>
      match right with
      | .bvar rightIndex => leftIndex == rightIndex
      | _ => false
  | .fvar leftId =>
      match right with
      | .fvar rightId => leftId == rightId
      | _ => false
  | .mvar leftId =>
      match right with
      | .mvar rightId => leftId == rightId
      | _ => false
  | .sortE leftLevel =>
      match right with
      | .sortE rightLevel =>
          psLevelStructuralEq leftLevel rightLevel
      | _ => false
  | .constE leftName leftLevels =>
      match right with
      | .constE rightName rightLevels =>
          psNameEq leftName rightName
            && psLevelListEq leftLevels rightLevels
      | _ => false
  | .app leftFn leftArg =>
      match right with
      | .app rightFn rightArg =>
          psExprAlphaEq leftFn rightFn
            && psExprAlphaEq leftArg rightArg
      | _ => false
  | .lam _ leftType leftBody leftBinder =>
      match right with
      | .lam _ rightType rightBody rightBinder =>
          psBinderInfoEq leftBinder rightBinder
            && psExprAlphaEq leftType rightType
            && psExprAlphaEq leftBody rightBody
      | _ => false
  | .forallE _ leftType leftBody leftBinder =>
      match right with
      | .forallE _ rightType rightBody rightBinder =>
          psBinderInfoEq leftBinder rightBinder
            && psExprAlphaEq leftType rightType
            && psExprAlphaEq leftBody rightBody
      | _ => false
  | .letE _ leftType leftValue leftBody =>
      match right with
      | .letE _ rightType rightValue rightBody =>
          psExprAlphaEq leftType rightType
            && psExprAlphaEq leftValue rightValue
            && psExprAlphaEq leftBody rightBody
      | _ => false
  | .lit leftValue =>
      match right with
      | .lit rightValue => psLiteralEq leftValue rightValue
      | _ => false
  | .proj leftType leftIndex leftValue =>
      match right with
      | .proj rightType rightIndex rightValue =>
          psNameEq leftType rightType
            && leftIndex == rightIndex
            && psExprAlphaEq leftValue rightValue
      | _ => false
