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
      fun (right : PsLevel) =>
        match right with
        | .zero => true
        | _ => false
  | .succ leftValue =>
      let smaller : PsLevel -> Bool :=
        psLevelStructuralEq leftValue;
      fun (right : PsLevel) =>
        match right with
        | .succ rightValue =>
            smaller rightValue
        | _ => false
  | .max leftA leftB =>
      let leftEq : PsLevel -> Bool :=
        psLevelStructuralEq leftA;
      let rightEq : PsLevel -> Bool :=
        psLevelStructuralEq leftB;
      fun (right : PsLevel) =>
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
      fun (right : PsLevel) =>
        match right with
        | .imax rightA rightB =>
            if leftEq rightA then
              rightEq rightB
            else
              false
        | _ => false
  | .param leftName =>
      fun (right : PsLevel) =>
        match right with
        | .param rightName => psNameEq leftName rightName
        | _ => false
  | .mvar leftId =>
      fun (right : PsLevel) =>
        match right with
        | .mvar rightId => Nat.beq leftId rightId
        | _ => false

def psLevelListEq
    (left : List PsLevel) : List PsLevel -> Bool :=
  match left with
  | [] =>
      fun (right : List PsLevel) =>
        match right with
        | [] => true
        | _ => false
  | leftValue :: leftRest =>
      let smaller : List PsLevel -> Bool :=
        psLevelListEq leftRest;
      fun (right : List PsLevel) =>
        match right with
        | rightValue :: rightRest =>
            if psLevelStructuralEq leftValue rightValue then
              smaller rightRest
            else
              false
        | _ => false

def psExprAlphaEq (left : PsExpr) : PsExpr -> Bool :=
  match left with
  | .bvar leftIndex =>
      fun (right : PsExpr) =>
        match right with
        | .bvar rightIndex => Nat.beq leftIndex rightIndex
        | _ => false
  | .fvar leftId =>
      fun (right : PsExpr) =>
        match right with
        | .fvar rightId => Nat.beq leftId rightId
        | _ => false
  | .mvar leftId =>
      fun (right : PsExpr) =>
        match right with
        | .mvar rightId => Nat.beq leftId rightId
        | _ => false
  | .sortE leftLevel =>
      fun (right : PsExpr) =>
        match right with
        | .sortE rightLevel =>
            psLevelStructuralEq leftLevel rightLevel
        | _ => false
  | .constE leftName leftLevels =>
      fun (right : PsExpr) =>
        match right with
        | .constE rightName rightLevels =>
            if psNameEq leftName rightName then
              psLevelListEq leftLevels rightLevels
            else
              false
        | _ => false
  | .app leftFn leftArg =>
      let fnEq : PsExpr -> Bool :=
        psExprAlphaEq leftFn;
      let argEq : PsExpr -> Bool :=
        psExprAlphaEq leftArg;
      fun (right : PsExpr) =>
        match right with
        | .app rightFn rightArg =>
            if fnEq rightFn then
              argEq rightArg
            else
              false
        | _ => false
  | .lam _ leftType leftBody leftBinder =>
      let typeEq : PsExpr -> Bool :=
        psExprAlphaEq leftType;
      let bodyEq : PsExpr -> Bool :=
        psExprAlphaEq leftBody;
      fun (right : PsExpr) =>
        match right with
        | .lam _ rightType rightBody rightBinder =>
            if psBinderInfoEq leftBinder rightBinder then
              if typeEq rightType then
                bodyEq rightBody
              else
                false
            else
              false
        | _ => false
  | .forallE _ leftType leftBody leftBinder =>
      let typeEq : PsExpr -> Bool :=
        psExprAlphaEq leftType;
      let bodyEq : PsExpr -> Bool :=
        psExprAlphaEq leftBody;
      fun (right : PsExpr) =>
        match right with
        | .forallE _ rightType rightBody rightBinder =>
            if psBinderInfoEq leftBinder rightBinder then
              if typeEq rightType then
                bodyEq rightBody
              else
                false
            else
              false
        | _ => false
  | .letE _ leftType leftValue leftBody =>
      let typeEq : PsExpr -> Bool :=
        psExprAlphaEq leftType;
      let valueEq : PsExpr -> Bool :=
        psExprAlphaEq leftValue;
      let bodyEq : PsExpr -> Bool :=
        psExprAlphaEq leftBody;
      fun (right : PsExpr) =>
        match right with
        | .letE _ rightType rightValue rightBody =>
            if typeEq rightType then
              if valueEq rightValue then
                bodyEq rightBody
              else
                false
            else
              false
        | _ => false
  | .lit leftValue =>
      fun (right : PsExpr) =>
        match right with
        | .lit rightValue => psLiteralEq leftValue rightValue
        | _ => false
  | .proj leftType leftIndex leftValue =>
      let valueEq : PsExpr -> Bool :=
        psExprAlphaEq leftValue;
      fun (right : PsExpr) =>
        match right with
        | .proj rightType rightIndex rightValue =>
            if psNameEq leftType rightType then
              if Nat.beq leftIndex rightIndex then
                valueEq rightValue
              else
                false
            else
              false
        | _ => false
