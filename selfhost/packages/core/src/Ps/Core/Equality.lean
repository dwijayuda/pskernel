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
      | .natural rightValue => Nat.beq leftValue rightValue
      | _ => false
  | .string leftValue =>
      match right with
      | .string rightValue => psStringEq leftValue rightValue
      | _ => false

def psLevelStructuralEq (left : PsLevel) : PsLevel -> Bool :=
  match left with
  | .zero =>
      fun right =>
        match right with
        | .zero => true
        | _ => false
  | .succ leftValue =>
      let smaller : PsLevel -> Bool :=
        psLevelStructuralEq leftValue;
      fun right =>
        match right with
        | .succ rightValue =>
            smaller rightValue
        | _ => false
  | .max leftA leftB =>
      let leftEq : PsLevel -> Bool :=
        psLevelStructuralEq leftA;
      let rightEq : PsLevel -> Bool :=
        psLevelStructuralEq leftB;
      fun right =>
        match right with
        | .max rightA rightB =>
            if leftEq rightA then
              rightEq rightB
            else
              false
        | _ => false
  | .imax leftA leftB =>
      let leftEq : PsLevel -> Bool :=
        psLevelStructuralEq leftA;
      let rightEq : PsLevel -> Bool :=
        psLevelStructuralEq leftB;
      fun right =>
        match right with
        | .imax rightA rightB =>
            if leftEq rightA then
              rightEq rightB
            else
              false
        | _ => false
  | .param leftName =>
      fun right =>
        match right with
        | .param rightName => psNameEq leftName rightName
        | _ => false
  | .mvar leftId =>
      fun right =>
        match right with
        | .mvar rightId => Nat.beq leftId rightId
        | _ => false

def psLevelListEq
    (left : List PsLevel)
    (right : List PsLevel) : Bool :=
  match left with
  | [] =>
      match right with
      | [] => true
      | _ => false
  | leftValue :: leftRest =>
      match right with
      | rightValue :: rightRest =>
          if psLevelStructuralEq leftValue rightValue then
            psLevelListEq leftRest rightRest
          else
            false
      | _ => false

def psExprAlphaEq (left : PsExpr) (right : PsExpr) : Bool :=
  match left with
  | .bvar leftIndex =>
      match right with
      | .bvar rightIndex => Nat.beq leftIndex rightIndex
      | _ => false
  | .fvar leftId =>
      match right with
      | .fvar rightId => Nat.beq leftId rightId
      | _ => false
  | .mvar leftId =>
      match right with
      | .mvar rightId => Nat.beq leftId rightId
      | _ => false
  | .sortE leftLevel =>
      match right with
      | .sortE rightLevel =>
          psLevelStructuralEq leftLevel rightLevel
      | _ => false
  | .constE leftName leftLevels =>
      match right with
      | .constE rightName rightLevels =>
          if psNameEq leftName rightName then
            psLevelListEq leftLevels rightLevels
          else
            false
      | _ => false
  | .app leftFn leftArg =>
      match right with
      | .app rightFn rightArg =>
          if psExprAlphaEq leftFn rightFn then
            psExprAlphaEq leftArg rightArg
          else
            false
      | _ => false
  | .lam _ leftType leftBody leftBinder =>
      match right with
      | .lam _ rightType rightBody rightBinder =>
          if psBinderInfoEq leftBinder rightBinder then
            if psExprAlphaEq leftType rightType then
              psExprAlphaEq leftBody rightBody
            else
              false
          else
            false
      | _ => false
  | .forallE _ leftType leftBody leftBinder =>
      match right with
      | .forallE _ rightType rightBody rightBinder =>
          if psBinderInfoEq leftBinder rightBinder then
            if psExprAlphaEq leftType rightType then
              psExprAlphaEq leftBody rightBody
            else
              false
          else
            false
      | _ => false
  | .letE _ leftType leftValue leftBody =>
      match right with
      | .letE _ rightType rightValue rightBody =>
          if psExprAlphaEq leftType rightType then
            if psExprAlphaEq leftValue rightValue then
              psExprAlphaEq leftBody rightBody
            else
              false
          else
            false
      | _ => false
  | .lit leftValue =>
      match right with
      | .lit rightValue => psLiteralEq leftValue rightValue
      | _ => false
  | .proj leftType leftIndex leftValue =>
      match right with
      | .proj rightType rightIndex rightValue =>
          if psNameEq leftType rightType then
            if Nat.beq leftIndex rightIndex then
              psExprAlphaEq leftValue rightValue
            else
              false
          else
            false
      | _ => false
