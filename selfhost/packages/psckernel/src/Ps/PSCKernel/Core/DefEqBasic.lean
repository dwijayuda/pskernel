import Ps.PSCKernel.Core.ReductionBasic

def psCKernelLevelListEquivalent
    (left : List PsCKernelLevel)
    (right : List PsCKernelLevel) : Bool :=
  match left, right with
  | [], [] => true
  | leftHead :: leftTail, rightHead :: rightTail =>
      if psCKernelLevelEquivalent leftHead rightHead then
        psCKernelLevelListEquivalent leftTail rightTail
      else
        false
  | _, _ => false

partial def psCKernelIsDefEqBasic
    (env : PsCKernelEnvironment)
    (lctx : PsCKernelLocalContext)
    (leftInput : PsCKernelExpr)
    (rightInput : PsCKernelExpr) : Bool :=
  if psCKernelExprEqv leftInput rightInput then
    true
  else
    let left := psCKernelExprWhnfBasic env lctx leftInput
    let right := psCKernelExprWhnfBasic env lctx rightInput
    match left, right with
    | PsCKernelExpr.bvar leftIndex, PsCKernelExpr.bvar rightIndex =>
        Nat.beq leftIndex rightIndex
    | PsCKernelExpr.fvar leftId, PsCKernelExpr.fvar rightId =>
        psCKernelFVarIdEq leftId rightId
    | PsCKernelExpr.mvar leftId, PsCKernelExpr.mvar rightId =>
        psCKernelMVarIdEq leftId rightId
    | PsCKernelExpr.sortE leftLevel, PsCKernelExpr.sortE rightLevel =>
        psCKernelLevelEquivalent leftLevel rightLevel
    | PsCKernelExpr.constE leftName leftLevels,
        PsCKernelExpr.constE rightName rightLevels =>
        if psCKernelNameEq leftName rightName then
          psCKernelLevelListEquivalent leftLevels rightLevels
        else
          false
    | PsCKernelExpr.app leftFn leftArg, PsCKernelExpr.app rightFn rightArg =>
        if psCKernelIsDefEqBasic env lctx leftFn rightFn then
          psCKernelIsDefEqBasic env lctx leftArg rightArg
        else
          false
    | PsCKernelExpr.lam _ leftType leftBody _,
        PsCKernelExpr.lam _ rightType rightBody _ =>
        if psCKernelIsDefEqBasic env lctx leftType rightType then
          psCKernelIsDefEqBasic env lctx leftBody rightBody
        else
          false
    | PsCKernelExpr.forallE _ leftType leftBody _,
        PsCKernelExpr.forallE _ rightType rightBody _ =>
        if psCKernelIsDefEqBasic env lctx leftType rightType then
          psCKernelIsDefEqBasic env lctx leftBody rightBody
        else
          false
    | PsCKernelExpr.letE _ leftType leftValue leftBody leftNondep,
        PsCKernelExpr.letE _ rightType rightValue rightBody rightNondep =>
        if leftNondep == rightNondep then
          if psCKernelIsDefEqBasic env lctx leftType rightType then
            if psCKernelIsDefEqBasic env lctx leftValue rightValue then
              psCKernelIsDefEqBasic env lctx leftBody rightBody
            else
              false
          else
            false
        else
          false
    | PsCKernelExpr.lit leftLiteral, PsCKernelExpr.lit rightLiteral =>
        psCKernelLiteralEq leftLiteral rightLiteral
    | PsCKernelExpr.proj leftTypeName leftIndex leftExpr,
        PsCKernelExpr.proj rightTypeName rightIndex rightExpr =>
        if psCKernelNameEq leftTypeName rightTypeName then
          if Nat.beq leftIndex rightIndex then
            psCKernelIsDefEqBasic env lctx leftExpr rightExpr
          else
            false
        else
          false
    | _, _ => false
