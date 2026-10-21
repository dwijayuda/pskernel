import Ps.KernelCore.Core.Expr

/-!
These frozen workers are copied from Core/Expr.lean at
854bdb9e0febf4e01fb5ce4b2cc8ea91f61287e4, with only their recursive names changed.
The theorems prove exact Boolean equality, including the different binder-name
and binder-info policies of ExprEq and ExprEqual, for every pair of expressions.
They do not prove a runtime allocation bound or whole-kernel soundness.
The frozen workers are native test oracles, outside the portable kernel closure.
-/
namespace PsKernelExprEqualityProofs

def beforeExprEq
    (left : PsKernelExpr) :
    PsKernelExpr -> Bool :=
  match left with
  | PsKernelExpr.bvar leftIndex =>
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.bvar rightIndex =>
            Nat.beq leftIndex rightIndex
        | _ => false
  | PsKernelExpr.fvar leftName =>
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.fvar rightName =>
            psKernelNameEq leftName rightName
        | _ => false
  | PsKernelExpr.mvar leftName =>
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.mvar rightName =>
            psKernelNameEq leftName rightName
        | _ => false
  | PsKernelExpr.sort leftLevel =>
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.sort rightLevel =>
            psKernelLevelEq leftLevel rightLevel
        | _ => false
  | PsKernelExpr.const leftName leftLevels =>
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.const rightName rightLevels =>
            if psKernelNameEq leftName rightName then
              psKernelLevelListEq leftLevels rightLevels
            else
              false
        | _ => false
  | PsKernelExpr.app leftFn leftArg =>
      let fnEq : PsKernelExpr -> Bool :=
        beforeExprEq leftFn;
      let argEq : PsKernelExpr -> Bool :=
        beforeExprEq leftArg;
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.app rightFn rightArg =>
            if fnEq rightFn then argEq rightArg else false
        | _ => false
  | PsKernelExpr.lam _ leftType leftBody _ =>
      let typeEq : PsKernelExpr -> Bool :=
        beforeExprEq leftType;
      let bodyEq : PsKernelExpr -> Bool :=
        beforeExprEq leftBody;
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.lam _ rightType rightBody _ =>
            if typeEq rightType then bodyEq rightBody else false
        | _ => false
  | PsKernelExpr.forallE _ leftType leftBody _ =>
      let typeEq : PsKernelExpr -> Bool :=
        beforeExprEq leftType;
      let bodyEq : PsKernelExpr -> Bool :=
        beforeExprEq leftBody;
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.forallE _ rightType rightBody _ =>
            if typeEq rightType then bodyEq rightBody else false
        | _ => false
  | PsKernelExpr.letE _ leftType leftValue leftBody leftNondep =>
      let typeEq : PsKernelExpr -> Bool :=
        beforeExprEq leftType;
      let valueEq : PsKernelExpr -> Bool :=
        beforeExprEq leftValue;
      let bodyEq : PsKernelExpr -> Bool :=
        beforeExprEq leftBody;
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.letE _ rightType rightValue rightBody rightNondep =>
            if typeEq rightType then
              if valueEq rightValue then
                if bodyEq rightBody then
                  psKernelBoolEq leftNondep rightNondep
                else false
              else false
            else false
        | _ => false
  | PsKernelExpr.lit leftValue =>
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.lit rightValue =>
            psKernelLiteralEq leftValue rightValue
        | _ => false
  | PsKernelExpr.mdata leftMetadata leftExpr =>
      let exprEq : PsKernelExpr -> Bool :=
        beforeExprEq leftExpr;
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.mdata rightMetadata rightExpr =>
            if Nat.beq leftMetadata rightMetadata then
              exprEq rightExpr
            else false
        | _ => false
  | PsKernelExpr.proj leftName leftIndex leftExpr =>
      let exprEq : PsKernelExpr -> Bool :=
        beforeExprEq leftExpr;
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.proj rightName rightIndex rightExpr =>
            if psKernelNameEq leftName rightName then
              if Nat.beq leftIndex rightIndex then
                exprEq rightExpr
              else false
            else false
        | _ => false

def beforeExprEqual
    (left : PsKernelExpr) :
    PsKernelExpr -> Bool :=
  match left with
  | PsKernelExpr.bvar leftIndex =>
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.bvar rightIndex =>
            Nat.beq leftIndex rightIndex
        | _ => false
  | PsKernelExpr.fvar leftName =>
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.fvar rightName =>
            psKernelNameEq leftName rightName
        | _ => false
  | PsKernelExpr.mvar leftName =>
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.mvar rightName =>
            psKernelNameEq leftName rightName
        | _ => false
  | PsKernelExpr.sort leftLevel =>
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.sort rightLevel =>
            psKernelLevelEq leftLevel rightLevel
        | _ => false
  | PsKernelExpr.const leftName leftLevels =>
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.const rightName rightLevels =>
            if psKernelNameEq leftName rightName then
              psKernelLevelListEq leftLevels rightLevels
            else false
        | _ => false
  | PsKernelExpr.app leftFn leftArg =>
      let fnEq : PsKernelExpr -> Bool :=
        beforeExprEqual leftFn;
      let argEq : PsKernelExpr -> Bool :=
        beforeExprEqual leftArg;
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.app rightFn rightArg =>
            if fnEq rightFn then argEq rightArg else false
        | _ => false
  | PsKernelExpr.lam leftName leftType leftBody leftInfo =>
      let typeEq : PsKernelExpr -> Bool :=
        beforeExprEqual leftType;
      let bodyEq : PsKernelExpr -> Bool :=
        beforeExprEqual leftBody;
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.lam rightName rightType rightBody rightInfo =>
            if psKernelNameEq leftName rightName then
              if typeEq rightType then
                if bodyEq rightBody then
                  psKernelBinderInfoEq leftInfo rightInfo
                else false
              else false
            else false
        | _ => false
  | PsKernelExpr.forallE leftName leftType leftBody leftInfo =>
      let typeEq : PsKernelExpr -> Bool :=
        beforeExprEqual leftType;
      let bodyEq : PsKernelExpr -> Bool :=
        beforeExprEqual leftBody;
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.forallE rightName rightType rightBody rightInfo =>
            if psKernelNameEq leftName rightName then
              if typeEq rightType then
                if bodyEq rightBody then
                  psKernelBinderInfoEq leftInfo rightInfo
                else false
              else false
            else false
        | _ => false
  | PsKernelExpr.letE leftName leftType leftValue leftBody leftNondep =>
      let typeEq : PsKernelExpr -> Bool :=
        beforeExprEqual leftType;
      let valueEq : PsKernelExpr -> Bool :=
        beforeExprEqual leftValue;
      let bodyEq : PsKernelExpr -> Bool :=
        beforeExprEqual leftBody;
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.letE rightName rightType rightValue rightBody rightNondep =>
            if psKernelNameEq leftName rightName then
              if typeEq rightType then
                if valueEq rightValue then
                  if bodyEq rightBody then
                    psKernelBoolEq leftNondep rightNondep
                  else false
                else false
              else false
            else false
        | _ => false
  | PsKernelExpr.lit leftValue =>
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.lit rightValue =>
            psKernelLiteralEq leftValue rightValue
        | _ => false
  | PsKernelExpr.mdata leftMetadata leftExpr =>
      let exprEq : PsKernelExpr -> Bool :=
        beforeExprEqual leftExpr;
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.mdata rightMetadata rightExpr =>
            if Nat.beq leftMetadata rightMetadata then
              exprEq rightExpr
            else false
        | _ => false
  | PsKernelExpr.proj leftName leftIndex leftExpr =>
      let exprEq : PsKernelExpr -> Bool :=
        beforeExprEqual leftExpr;
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.proj rightName rightIndex rightExpr =>
            if psKernelNameEq leftName rightName then
              if Nat.beq leftIndex rightIndex then
                exprEq rightExpr
              else false
            else false
        | _ => false


theorem exprEq_delayed_recursion_preserves (left : PsKernelExpr) :
    psKernelExprEq left = beforeExprEq left := by
  induction left <;>
    funext right <;>
    cases right <;>
    simp_all only [psKernelExprEq, beforeExprEq]

theorem exprEqual_delayed_recursion_preserves (left : PsKernelExpr) :
    psKernelExprEqual left = beforeExprEqual left := by
  induction left <;>
    funext right <;>
    cases right <;>
    simp_all only [psKernelExprEqual, beforeExprEqual]

theorem exprEq_pointwise_preserves (left right : PsKernelExpr) :
    psKernelExprEq left right = beforeExprEq left right :=
  congrFun (exprEq_delayed_recursion_preserves left) right

theorem exprEqual_pointwise_preserves (left right : PsKernelExpr) :
    psKernelExprEqual left right = beforeExprEqual left right :=
  congrFun (exprEqual_delayed_recursion_preserves left) right

#print axioms exprEq_delayed_recursion_preserves
#print axioms exprEqual_delayed_recursion_preserves
#print axioms exprEq_pointwise_preserves
#print axioms exprEqual_pointwise_preserves

private def require (label : String) (ok : Bool) : IO Unit := do
  if !ok then throw (IO.userError ("PSKERNEL_EXPR_EQUALITY_FAILED " ++ label))

private def shared (depth : Nat) : PsKernelExpr :=
  match depth with
  | 0 => .bvar 0
  | depth + 1 =>
      let child := shared depth
      .app child child

private def nativeRegression : IO Unit := do
  let x := PsKernelName.str .anonymous "x"
  let y := PsKernelName.str .anonymous "y"
  let s0 := PsKernelExpr.sort .zero
  let s1 := PsKernelExpr.sort (.succ .zero)
  let b0 := PsKernelExpr.bvar 0
  let b1 := PsKernelExpr.bvar 1
  let samples : List PsKernelExpr := [
    b0, b1, .fvar x, .mvar x, s0, s1, .const x [],
    .const x [.zero], .app b0 b1, .lam x s0 b0 .default,
    .lam y s0 b0 .default, .lam x s0 b0 .implicit,
    .forallE x s0 b0 .default, .forallE y s0 b0 .instImplicit,
    .letE x s0 b0 b1 false, .letE y s0 b0 b1 true,
    .lit (.nat 0), .lit (.str "x"), .mdata 7 b0, .proj x 0 b0]
  let mut comparisons : Nat := 0
  for left in samples do
    for right in samples do
      require "frozen-exprEq"
        (psKernelExprEq left right == beforeExprEq left right)
      require "frozen-exprEqual"
        (psKernelExprEqual left right == beforeExprEqual left right)
      comparisons := comparisons + 2
  require "complete-native-matrix" (comparisons == 800)
  require "alpha-ignores-binder-name-and-info"
    (psKernelExprEq (.lam x s0 b0 .default) (.lam y s0 b0 .implicit))
  require "exact-preserves-binder-name"
    (!(psKernelExprEqual (.lam x s0 b0 .default) (.lam y s0 b0 .default)))
  require "exact-preserves-binder-info"
    (!(psKernelExprEqual (.lam x s0 b0 .default) (.lam x s0 b0 .implicit)))
  -- Only 65 allocated expression nodes, but an exponentially large unfolded
  -- tree. A different outer tag or earlier unequal field must avoid the rest.
  -- Never run the eager frozen oracle on this hostile shared expression.
  let deep := shared 64
  let hostile : List (String × PsKernelExpr × PsKernelExpr) := [
    ("outer-tag", deep, s0),
    ("app-first-child", .app s0 deep, .app s1 deep),
    ("lam-type", .lam x s0 deep .default, .lam x s1 deep .default),
    ("forall-type", .forallE x s0 deep .default, .forallE x s1 deep .default),
    ("let-type", .letE x s0 deep deep false, .letE x s1 deep deep false),
    ("let-value", .letE x s0 s0 deep false, .letE x s0 s1 deep false),
    ("mdata-tag", .mdata 7 deep, .mdata 8 deep),
    ("projection-name", .proj x 0 deep, .proj y 0 deep),
    ("projection-index", .proj x 0 deep, .proj x 1 deep)]
  for (label, left, right) in hostile do
    require (label ++ "-exprEq") (!(psKernelExprEq left right))
    require (label ++ "-exprEqual") (!(psKernelExprEqual left right))
  require "exact-lam-name-before-children"
    (!(psKernelExprEqual (.lam x deep deep .default) (.lam y deep deep .default)))
  require "exact-forall-name-before-children"
    (!(psKernelExprEqual (.forallE x deep deep .default) (.forallE y deep deep .default)))
  require "exact-let-name-before-children"
    (!(psKernelExprEqual (.letE x deep deep deep false) (.letE y deep deep deep false)))
  IO.println s!"PSKERNEL_EXPR_EQUALITY_NATIVE: PASS comparisons={comparisons} hostile=21 sharedDepth=64"

#eval nativeRegression

end PsKernelExprEqualityProofs
