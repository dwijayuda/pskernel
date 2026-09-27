import Ps.KernelCore.Level

inductive PsKernelCoreBinderInfo where
  | default
  | implicit
  | strictImplicit
  | instImplicit

inductive PsKernelCoreLiteral where
  | nat (value : Nat)
  | str (value : String)

inductive PsKernelCoreExpr where
  | bvar (index : Nat)
  | fvar (name : PsKernelCoreName)
  | mvar (name : PsKernelCoreName)
  | sort (level : PsKernelCoreLevel)
  | const
      (name : PsKernelCoreName)
      (levels : PsKernelCoreList PsKernelCoreLevel)
  | app
      (fn : PsKernelCoreExpr)
      (arg : PsKernelCoreExpr)
  | lam
      (name : PsKernelCoreName)
      (type : PsKernelCoreExpr)
      (body : PsKernelCoreExpr)
      (binderInfo : PsKernelCoreBinderInfo)
  | forallE
      (name : PsKernelCoreName)
      (type : PsKernelCoreExpr)
      (body : PsKernelCoreExpr)
      (binderInfo : PsKernelCoreBinderInfo)
  | letE
      (name : PsKernelCoreName)
      (type : PsKernelCoreExpr)
      (value : PsKernelCoreExpr)
      (body : PsKernelCoreExpr)
      (nondep : Bool)
  | lit (value : PsKernelCoreLiteral)
  | mdata
      (metadata : Nat)
      (expr : PsKernelCoreExpr)
  | proj
      (typeName : PsKernelCoreName)
      (index : Nat)
      (expr : PsKernelCoreExpr)

def psKernelCoreBoolEq
    (left : Bool) : Bool -> Bool :=
  match left with
  | false =>
      fun (right : Bool) =>
        match right with
        | false => true
        | true => false
  | true =>
      fun (right : Bool) =>
        match right with
        | false => false
        | true => true

def psKernelCoreLiteralEq
    (left : PsKernelCoreLiteral) : PsKernelCoreLiteral -> Bool :=
  match left with
  | PsKernelCoreLiteral.nat leftValue =>
      fun (right : PsKernelCoreLiteral) =>
        match right with
        | PsKernelCoreLiteral.nat rightValue => Nat.beq leftValue rightValue
        | _ => false
  | PsKernelCoreLiteral.str leftValue =>
      fun (right : PsKernelCoreLiteral) =>
        match right with
        | PsKernelCoreLiteral.str rightValue =>
            psKernelCoreStringEq leftValue rightValue
        | _ => false

def psKernelCoreLevelListEq
    (left : PsKernelCoreList PsKernelCoreLevel) :
    PsKernelCoreList PsKernelCoreLevel -> Bool :=
  match left with
  | PsKernelCoreList.nil =>
      fun (right : PsKernelCoreList PsKernelCoreLevel) =>
        match right with
        | PsKernelCoreList.nil => true
        | _ => false
  | PsKernelCoreList.cons leftHead leftTail =>
      let tailEq : PsKernelCoreList PsKernelCoreLevel -> Bool :=
        psKernelCoreLevelListEq leftTail;
      fun (right : PsKernelCoreList PsKernelCoreLevel) =>
        match right with
        | PsKernelCoreList.cons rightHead rightTail =>
            if psKernelCoreLevelEq leftHead rightHead then
              tailEq rightTail
            else
              false
        | _ => false

def psKernelCoreExprEq
    (left : PsKernelCoreExpr) : PsKernelCoreExpr -> Bool :=
  match left with
  | PsKernelCoreExpr.bvar leftIndex =>
      fun (right : PsKernelCoreExpr) =>
        match right with
        | PsKernelCoreExpr.bvar rightIndex => Nat.beq leftIndex rightIndex
        | _ => false
  | PsKernelCoreExpr.fvar leftName =>
      fun (right : PsKernelCoreExpr) =>
        match right with
        | PsKernelCoreExpr.fvar rightName => psKernelCoreNameEq leftName rightName
        | _ => false
  | PsKernelCoreExpr.mvar leftName =>
      fun (right : PsKernelCoreExpr) =>
        match right with
        | PsKernelCoreExpr.mvar rightName => psKernelCoreNameEq leftName rightName
        | _ => false
  | PsKernelCoreExpr.sort leftLevel =>
      fun (right : PsKernelCoreExpr) =>
        match right with
        | PsKernelCoreExpr.sort rightLevel => psKernelCoreLevelEq leftLevel rightLevel
        | _ => false
  | PsKernelCoreExpr.const leftName leftLevels =>
      fun (right : PsKernelCoreExpr) =>
        match right with
        | PsKernelCoreExpr.const rightName rightLevels =>
            if psKernelCoreNameEq leftName rightName then
              psKernelCoreLevelListEq leftLevels rightLevels
            else
              false
        | _ => false
  | PsKernelCoreExpr.app leftFn leftArg =>
      let fnEq : PsKernelCoreExpr -> Bool := psKernelCoreExprEq leftFn;
      let argEq : PsKernelCoreExpr -> Bool := psKernelCoreExprEq leftArg;
      fun (right : PsKernelCoreExpr) =>
        match right with
        | PsKernelCoreExpr.app rightFn rightArg =>
            if fnEq rightFn then argEq rightArg else false
        | _ => false
  | PsKernelCoreExpr.lam _ leftType leftBody _ =>
      let typeEq : PsKernelCoreExpr -> Bool := psKernelCoreExprEq leftType;
      let bodyEq : PsKernelCoreExpr -> Bool := psKernelCoreExprEq leftBody;
      fun (right : PsKernelCoreExpr) =>
        match right with
        | PsKernelCoreExpr.lam _ rightType rightBody _ =>
            if typeEq rightType then bodyEq rightBody else false
        | _ => false
  | PsKernelCoreExpr.forallE _ leftType leftBody _ =>
      let typeEq : PsKernelCoreExpr -> Bool := psKernelCoreExprEq leftType;
      let bodyEq : PsKernelCoreExpr -> Bool := psKernelCoreExprEq leftBody;
      fun (right : PsKernelCoreExpr) =>
        match right with
        | PsKernelCoreExpr.forallE _ rightType rightBody _ =>
            if typeEq rightType then bodyEq rightBody else false
        | _ => false
  | PsKernelCoreExpr.letE _ leftType leftValue leftBody leftNondep =>
      let typeEq : PsKernelCoreExpr -> Bool := psKernelCoreExprEq leftType;
      let valueEq : PsKernelCoreExpr -> Bool := psKernelCoreExprEq leftValue;
      let bodyEq : PsKernelCoreExpr -> Bool := psKernelCoreExprEq leftBody;
      fun (right : PsKernelCoreExpr) =>
        match right with
        | PsKernelCoreExpr.letE _ rightType rightValue rightBody rightNondep =>
            if typeEq rightType then
              if valueEq rightValue then
                if bodyEq rightBody then
                  psKernelCoreBoolEq leftNondep rightNondep
                else
                  false
              else
                false
            else
              false
        | _ => false
  | PsKernelCoreExpr.lit leftLiteral =>
      fun (right : PsKernelCoreExpr) =>
        match right with
        | PsKernelCoreExpr.lit rightLiteral =>
            psKernelCoreLiteralEq leftLiteral rightLiteral
        | _ => false
  | PsKernelCoreExpr.mdata leftMetadata leftExpr =>
      let exprEq : PsKernelCoreExpr -> Bool := psKernelCoreExprEq leftExpr;
      fun (right : PsKernelCoreExpr) =>
        match right with
        | PsKernelCoreExpr.mdata rightMetadata rightExpr =>
            if Nat.beq leftMetadata rightMetadata then exprEq rightExpr else false
        | _ => false
  | PsKernelCoreExpr.proj leftTypeName leftIndex leftExpr =>
      let exprEq : PsKernelCoreExpr -> Bool := psKernelCoreExprEq leftExpr;
      fun (right : PsKernelCoreExpr) =>
        match right with
        | PsKernelCoreExpr.proj rightTypeName rightIndex rightExpr =>
            if psKernelCoreNameEq leftTypeName rightTypeName then
              if Nat.beq leftIndex rightIndex then exprEq rightExpr else false
            else
              false
        | _ => false
