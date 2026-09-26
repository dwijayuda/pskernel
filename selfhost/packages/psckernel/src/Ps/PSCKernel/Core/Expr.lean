import Ps.PSCKernel.Core.Level

inductive PsCKernelBinderInfo where
  | default
  | implicit
  | strictImplicit
  | instImplicit

structure PsCKernelFVarId where
  name : PsCKernelName

structure PsCKernelMVarId where
  name : PsCKernelName

inductive PsCKernelLiteral where
  | natVal (value : Nat)
  | strVal (value : String)

inductive PsCKernelExpr where
  | bvar (index : Nat)
  | fvar (id : PsCKernelFVarId)
  | mvar (id : PsCKernelMVarId)
  | sortE (level : PsCKernelLevel)
  | constE (name : PsCKernelName) (levels : List PsCKernelLevel)
  | app (fn : PsCKernelExpr) (arg : PsCKernelExpr)
  | lam
      (name : PsCKernelName)
      (type : PsCKernelExpr)
      (body : PsCKernelExpr)
      (binderInfo : PsCKernelBinderInfo)
  | forallE
      (name : PsCKernelName)
      (type : PsCKernelExpr)
      (body : PsCKernelExpr)
      (binderInfo : PsCKernelBinderInfo)
  | letE
      (name : PsCKernelName)
      (type : PsCKernelExpr)
      (value : PsCKernelExpr)
      (body : PsCKernelExpr)
      (nondep : Bool)
  | lit (value : PsCKernelLiteral)
  | proj
      (typeName : PsCKernelName)
      (index : Nat)
      (expr : PsCKernelExpr)

def psCKernelBinderInfoEq
    (left : PsCKernelBinderInfo)
    (right : PsCKernelBinderInfo) : Bool :=
  match left with
  | PsCKernelBinderInfo.default =>
      match right with
      | PsCKernelBinderInfo.default => true
      | _ => false
  | PsCKernelBinderInfo.implicit =>
      match right with
      | PsCKernelBinderInfo.implicit => true
      | _ => false
  | PsCKernelBinderInfo.strictImplicit =>
      match right with
      | PsCKernelBinderInfo.strictImplicit => true
      | _ => false
  | PsCKernelBinderInfo.instImplicit =>
      match right with
      | PsCKernelBinderInfo.instImplicit => true
      | _ => false

def psCKernelBinderInfoIsExplicit (info : PsCKernelBinderInfo) : Bool :=
  match info with
  | PsCKernelBinderInfo.default => true
  | PsCKernelBinderInfo.implicit => false
  | PsCKernelBinderInfo.strictImplicit => false
  | PsCKernelBinderInfo.instImplicit => false

def psCKernelBinderInfoIsInstImplicit (info : PsCKernelBinderInfo) : Bool :=
  match info with
  | PsCKernelBinderInfo.instImplicit => true
  | _ => false

def psCKernelBinderInfoIsImplicit (info : PsCKernelBinderInfo) : Bool :=
  match info with
  | PsCKernelBinderInfo.implicit => true
  | _ => false

def psCKernelBinderInfoIsStrictImplicit (info : PsCKernelBinderInfo) : Bool :=
  match info with
  | PsCKernelBinderInfo.strictImplicit => true
  | _ => false

def psCKernelFVarIdEq
    (left : PsCKernelFVarId)
    (right : PsCKernelFVarId) : Bool :=
  psCKernelNameEq left.name right.name

def psCKernelMVarIdEq
    (left : PsCKernelMVarId)
    (right : PsCKernelMVarId) : Bool :=
  psCKernelNameEq left.name right.name

def psCKernelLiteralEq
    (left : PsCKernelLiteral)
    (right : PsCKernelLiteral) : Bool :=
  match left with
  | PsCKernelLiteral.natVal leftValue =>
      match right with
      | PsCKernelLiteral.natVal rightValue => Nat.beq leftValue rightValue
      | _ => false
  | PsCKernelLiteral.strVal leftValue =>
      match right with
      | PsCKernelLiteral.strVal rightValue => leftValue == rightValue
      | _ => false

def psCKernelLevelListEqStructural
    (left : List PsCKernelLevel)
    (right : List PsCKernelLevel) : Bool :=
  match left, right with
  | [], [] => true
  | leftHead :: leftTail, rightHead :: rightTail =>
      if psCKernelLevelEqStructural leftHead rightHead then
        psCKernelLevelListEqStructural leftTail rightTail
      else
        false
  | _, _ => false

def psCKernelExprEqStructural
    (left : PsCKernelExpr) : PsCKernelExpr -> Bool :=
  match left with
  | PsCKernelExpr.bvar leftIndex =>
      fun right =>
        match right with
        | PsCKernelExpr.bvar rightIndex => Nat.beq leftIndex rightIndex
        | _ => false
  | PsCKernelExpr.fvar leftId =>
      fun right =>
        match right with
        | PsCKernelExpr.fvar rightId => psCKernelFVarIdEq leftId rightId
        | _ => false
  | PsCKernelExpr.mvar leftId =>
      fun right =>
        match right with
        | PsCKernelExpr.mvar rightId => psCKernelMVarIdEq leftId rightId
        | _ => false
  | PsCKernelExpr.sortE leftLevel =>
      fun right =>
        match right with
        | PsCKernelExpr.sortE rightLevel =>
            psCKernelLevelEqStructural leftLevel rightLevel
        | _ => false
  | PsCKernelExpr.constE leftName leftLevels =>
      fun right =>
        match right with
        | PsCKernelExpr.constE rightName rightLevels =>
            if psCKernelNameEq leftName rightName then
              psCKernelLevelListEqStructural leftLevels rightLevels
            else
              false
        | _ => false
  | PsCKernelExpr.app leftFn leftArg =>
      fun right =>
        match right with
        | PsCKernelExpr.app rightFn rightArg =>
            if psCKernelExprEqStructural leftFn rightFn then
              psCKernelExprEqStructural leftArg rightArg
            else
              false
        | _ => false
  | PsCKernelExpr.lam leftName leftType leftBody leftInfo =>
      fun right =>
        match right with
        | PsCKernelExpr.lam rightName rightType rightBody rightInfo =>
            if psCKernelNameEq leftName rightName then
              if psCKernelBinderInfoEq leftInfo rightInfo then
                if psCKernelExprEqStructural leftType rightType then
                  psCKernelExprEqStructural leftBody rightBody
                else
                  false
              else
                false
            else
              false
        | _ => false
  | PsCKernelExpr.forallE leftName leftType leftBody leftInfo =>
      fun right =>
        match right with
        | PsCKernelExpr.forallE rightName rightType rightBody rightInfo =>
            if psCKernelNameEq leftName rightName then
              if psCKernelBinderInfoEq leftInfo rightInfo then
                if psCKernelExprEqStructural leftType rightType then
                  psCKernelExprEqStructural leftBody rightBody
                else
                  false
              else
                false
            else
              false
        | _ => false
  | PsCKernelExpr.letE leftName leftType leftValue leftBody leftNondep =>
      fun right =>
        match right with
        | PsCKernelExpr.letE rightName rightType rightValue rightBody rightNondep =>
            if psCKernelNameEq leftName rightName then
              if leftNondep == rightNondep then
                if psCKernelExprEqStructural leftType rightType then
                  if psCKernelExprEqStructural leftValue rightValue then
                    psCKernelExprEqStructural leftBody rightBody
                  else
                    false
                else
                  false
              else
                false
            else
              false
        | _ => false
  | PsCKernelExpr.lit leftValue =>
      fun right =>
        match right with
        | PsCKernelExpr.lit rightValue => psCKernelLiteralEq leftValue rightValue
        | _ => false
  | PsCKernelExpr.proj leftTypeName leftIndex leftExpr =>
      fun right =>
        match right with
        | PsCKernelExpr.proj rightTypeName rightIndex rightExpr =>
            if psCKernelNameEq leftTypeName rightTypeName then
              if Nat.beq leftIndex rightIndex then
                psCKernelExprEqStructural leftExpr rightExpr
              else
                false
            else
              false
        | _ => false

def psCKernelExprEqv
    (left : PsCKernelExpr) : PsCKernelExpr -> Bool :=
  match left with
  | PsCKernelExpr.bvar leftIndex =>
      fun right =>
        match right with
        | PsCKernelExpr.bvar rightIndex => Nat.beq leftIndex rightIndex
        | _ => false
  | PsCKernelExpr.fvar leftId =>
      fun right =>
        match right with
        | PsCKernelExpr.fvar rightId => psCKernelFVarIdEq leftId rightId
        | _ => false
  | PsCKernelExpr.mvar leftId =>
      fun right =>
        match right with
        | PsCKernelExpr.mvar rightId => psCKernelMVarIdEq leftId rightId
        | _ => false
  | PsCKernelExpr.sortE leftLevel =>
      fun right =>
        match right with
        | PsCKernelExpr.sortE rightLevel =>
            psCKernelLevelEqStructural leftLevel rightLevel
        | _ => false
  | PsCKernelExpr.constE leftName leftLevels =>
      fun right =>
        match right with
        | PsCKernelExpr.constE rightName rightLevels =>
            if psCKernelNameEq leftName rightName then
              psCKernelLevelListEqStructural leftLevels rightLevels
            else
              false
        | _ => false
  | PsCKernelExpr.app leftFn leftArg =>
      fun right =>
        match right with
        | PsCKernelExpr.app rightFn rightArg =>
            if psCKernelExprEqv leftFn rightFn then
              psCKernelExprEqv leftArg rightArg
            else
              false
        | _ => false
  | PsCKernelExpr.lam _ leftType leftBody _ =>
      fun right =>
        match right with
        | PsCKernelExpr.lam _ rightType rightBody _ =>
            if psCKernelExprEqv leftType rightType then
              psCKernelExprEqv leftBody rightBody
            else
              false
        | _ => false
  | PsCKernelExpr.forallE _ leftType leftBody _ =>
      fun right =>
        match right with
        | PsCKernelExpr.forallE _ rightType rightBody _ =>
            if psCKernelExprEqv leftType rightType then
              psCKernelExprEqv leftBody rightBody
            else
              false
        | _ => false
  | PsCKernelExpr.letE _ leftType leftValue leftBody leftNondep =>
      fun right =>
        match right with
        | PsCKernelExpr.letE _ rightType rightValue rightBody rightNondep =>
            if leftNondep == rightNondep then
              if psCKernelExprEqv leftType rightType then
                if psCKernelExprEqv leftValue rightValue then
                  psCKernelExprEqv leftBody rightBody
                else
                  false
              else
                false
            else
              false
        | _ => false
  | PsCKernelExpr.lit leftValue =>
      fun right =>
        match right with
        | PsCKernelExpr.lit rightValue => psCKernelLiteralEq leftValue rightValue
        | _ => false
  | PsCKernelExpr.proj leftTypeName leftIndex leftExpr =>
      fun right =>
        match right with
        | PsCKernelExpr.proj rightTypeName rightIndex rightExpr =>
            if psCKernelNameEq leftTypeName rightTypeName then
              if Nat.beq leftIndex rightIndex then
                psCKernelExprEqv leftExpr rightExpr
              else
                false
            else
              false
        | _ => false

def psCKernelExprListEqStructural
    (left : List PsCKernelExpr)
    (right : List PsCKernelExpr) : Bool :=
  match left, right with
  | [], [] => true
  | leftHead :: leftTail, rightHead :: rightTail =>
      if psCKernelExprEqStructural leftHead rightHead then
        psCKernelExprListEqStructural leftTail rightTail
      else
        false
  | _, _ => false

def psCKernelExprMkAppN
    (fn : PsCKernelExpr)
    (args : List PsCKernelExpr) : PsCKernelExpr :=
  match args with
  | [] => fn
  | arg :: rest =>
      psCKernelExprMkAppN (PsCKernelExpr.app fn arg) rest

def psCKernelExprGetAppFn (expr : PsCKernelExpr) : PsCKernelExpr :=
  match expr with
  | PsCKernelExpr.app fn _ => psCKernelExprGetAppFn fn
  | _ => expr

def psCKernelExprGetAppArgsGo
    (expr : PsCKernelExpr)
    (args : List PsCKernelExpr) : List PsCKernelExpr :=
  match expr with
  | PsCKernelExpr.app fn arg =>
      psCKernelExprGetAppArgsGo fn (arg :: args)
  | _ => args

def psCKernelExprGetAppArgs (expr : PsCKernelExpr) : List PsCKernelExpr :=
  psCKernelExprGetAppArgsGo expr []

def psCKernelExprHasFVar (expr : PsCKernelExpr) : Bool :=
  match expr with
  | PsCKernelExpr.fvar _ => true
  | PsCKernelExpr.app fn arg =>
      if psCKernelExprHasFVar fn then true else psCKernelExprHasFVar arg
  | PsCKernelExpr.lam _ type body _ =>
      if psCKernelExprHasFVar type then true else psCKernelExprHasFVar body
  | PsCKernelExpr.forallE _ type body _ =>
      if psCKernelExprHasFVar type then true else psCKernelExprHasFVar body
  | PsCKernelExpr.letE _ type value body _ =>
      if psCKernelExprHasFVar type then
        true
      else if psCKernelExprHasFVar value then
        true
      else
        psCKernelExprHasFVar body
  | PsCKernelExpr.proj _ _ value => psCKernelExprHasFVar value
  | _ => false

def psCKernelExprHasExprMVar (expr : PsCKernelExpr) : Bool :=
  match expr with
  | PsCKernelExpr.mvar _ => true
  | PsCKernelExpr.app fn arg =>
      if psCKernelExprHasExprMVar fn then true else psCKernelExprHasExprMVar arg
  | PsCKernelExpr.lam _ type body _ =>
      if psCKernelExprHasExprMVar type then true else psCKernelExprHasExprMVar body
  | PsCKernelExpr.forallE _ type body _ =>
      if psCKernelExprHasExprMVar type then true else psCKernelExprHasExprMVar body
  | PsCKernelExpr.letE _ type value body _ =>
      if psCKernelExprHasExprMVar type then
        true
      else if psCKernelExprHasExprMVar value then
        true
      else
        psCKernelExprHasExprMVar body
  | PsCKernelExpr.proj _ _ value => psCKernelExprHasExprMVar value
  | _ => false

def psCKernelLevelListHasMVar (levels : List PsCKernelLevel) : Bool :=
  match levels with
  | [] => false
  | level :: rest =>
      if psCKernelLevelHasMVar level then true else psCKernelLevelListHasMVar rest

def psCKernelExprHasLevelMVar (expr : PsCKernelExpr) : Bool :=
  match expr with
  | PsCKernelExpr.sortE level => psCKernelLevelHasMVar level
  | PsCKernelExpr.constE _ levels => psCKernelLevelListHasMVar levels
  | PsCKernelExpr.app fn arg =>
      if psCKernelExprHasLevelMVar fn then true else psCKernelExprHasLevelMVar arg
  | PsCKernelExpr.lam _ type body _ =>
      if psCKernelExprHasLevelMVar type then true else psCKernelExprHasLevelMVar body
  | PsCKernelExpr.forallE _ type body _ =>
      if psCKernelExprHasLevelMVar type then true else psCKernelExprHasLevelMVar body
  | PsCKernelExpr.letE _ type value body _ =>
      if psCKernelExprHasLevelMVar type then
        true
      else if psCKernelExprHasLevelMVar value then
        true
      else
        psCKernelExprHasLevelMVar body
  | PsCKernelExpr.proj _ _ value => psCKernelExprHasLevelMVar value
  | _ => false

def psCKernelExprHasMVar (expr : PsCKernelExpr) : Bool :=
  if psCKernelExprHasExprMVar expr then true else psCKernelExprHasLevelMVar expr
