import Ps.Core.Expr

def psBinderInfoEq (left : PsBinderInfo) (right : PsBinderInfo) : Bool :=
  match left, right with
  | .explicit, .explicit => true
  | .implicit, .implicit => true
  | .strictImplicit, .strictImplicit => true
  | .instanceImplicit, .instanceImplicit => true
  | _, _ => false

def psLiteralEq (left : PsLiteral) (right : PsLiteral) : Bool :=
  match left, right with
  | .natural leftValue, .natural rightValue => leftValue == rightValue
  | .string leftValue, .string rightValue => leftValue == rightValue
  | _, _ => false

def psLevelStructuralEq (left : PsLevel) (right : PsLevel) : Bool :=
  match left, right with
  | .zero, .zero => true
  | .succ leftValue, .succ rightValue =>
      psLevelStructuralEq leftValue rightValue
  | .max leftA leftB, .max rightA rightB =>
      psLevelStructuralEq leftA rightA && psLevelStructuralEq leftB rightB
  | .imax leftA leftB, .imax rightA rightB =>
      psLevelStructuralEq leftA rightA && psLevelStructuralEq leftB rightB
  | .param leftName, .param rightName => psNameEq leftName rightName
  | .mvar leftId, .mvar rightId => leftId == rightId
  | _, _ => false

def psLevelListEq : List PsLevel -> List PsLevel -> Bool
  | [], [] => true
  | left :: leftRest, right :: rightRest =>
      psLevelStructuralEq left right && psLevelListEq leftRest rightRest
  | _, _ => false

def psExprAlphaEq (left : PsExpr) (right : PsExpr) : Bool :=
  match left, right with
  | .bvar leftIndex, .bvar rightIndex => leftIndex == rightIndex
  | .fvar leftId, .fvar rightId => leftId == rightId
  | .mvar leftId, .mvar rightId => leftId == rightId
  | .sortE leftLevel, .sortE rightLevel =>
      psLevelStructuralEq leftLevel rightLevel
  | .constE leftName leftLevels, .constE rightName rightLevels =>
      psNameEq leftName rightName && psLevelListEq leftLevels rightLevels
  | .app leftFn leftArg, .app rightFn rightArg =>
      psExprAlphaEq leftFn rightFn && psExprAlphaEq leftArg rightArg
  | .lam _ leftType leftBody leftBinder, .lam _ rightType rightBody rightBinder =>
      psBinderInfoEq leftBinder rightBinder
        && psExprAlphaEq leftType rightType
        && psExprAlphaEq leftBody rightBody
  | .forallE _ leftType leftBody leftBinder, .forallE _ rightType rightBody rightBinder =>
      psBinderInfoEq leftBinder rightBinder
        && psExprAlphaEq leftType rightType
        && psExprAlphaEq leftBody rightBody
  | .letE _ leftType leftValue leftBody, .letE _ rightType rightValue rightBody =>
      psExprAlphaEq leftType rightType
        && psExprAlphaEq leftValue rightValue
        && psExprAlphaEq leftBody rightBody
  | .lit leftValue, .lit rightValue => psLiteralEq leftValue rightValue
  | .proj leftType leftIndex leftValue, .proj rightType rightIndex rightValue =>
      psNameEq leftType rightType
        && leftIndex == rightIndex
        && psExprAlphaEq leftValue rightValue
  | _, _ => false
