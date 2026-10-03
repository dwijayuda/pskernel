import Ps.KernelSelfHost.Level

inductive PsKernelBinderInfo where
  | default
  | implicit
  | strictImplicit
  | instImplicit

inductive PsKernelLiteral where
  | nat (value : Nat)
  | str (value : String)

inductive PsKernelExpr where
  | bvar (index : Nat)
  | fvar (name : PsKernelName)
  | mvar (name : PsKernelName)
  | sort (level : PsKernelLevel)
  | const (name : PsKernelName) (levels : List PsKernelLevel)
  | app (fn : PsKernelExpr) (arg : PsKernelExpr)
  | lam
      (name : PsKernelName)
      (type : PsKernelExpr)
      (body : PsKernelExpr)
      (binderInfo : PsKernelBinderInfo)
  | forallE
      (name : PsKernelName)
      (type : PsKernelExpr)
      (body : PsKernelExpr)
      (binderInfo : PsKernelBinderInfo)
  | letE
      (name : PsKernelName)
      (type : PsKernelExpr)
      (value : PsKernelExpr)
      (body : PsKernelExpr)
      (nondep : Bool)
  | lit (value : PsKernelLiteral)
  | mdata (metadata : Nat) (expr : PsKernelExpr)
  | proj
      (typeName : PsKernelName)
      (index : Nat)
      (expr : PsKernelExpr)

def psKernelBoolEq
    (left : Bool)
    (right : Bool) : Bool :=
  if left then
    right
  else if right then
    false
  else
    true

def psKernelBinderInfoEq
    (left : PsKernelBinderInfo)
    (right : PsKernelBinderInfo) : Bool :=
  match left with
  | PsKernelBinderInfo.default =>
      match right with
      | PsKernelBinderInfo.default => true
      | _ => false
  | PsKernelBinderInfo.implicit =>
      match right with
      | PsKernelBinderInfo.implicit => true
      | _ => false
  | PsKernelBinderInfo.strictImplicit =>
      match right with
      | PsKernelBinderInfo.strictImplicit => true
      | _ => false
  | PsKernelBinderInfo.instImplicit =>
      match right with
      | PsKernelBinderInfo.instImplicit => true
      | _ => false

def psKernelLiteralEq
    (left : PsKernelLiteral)
    (right : PsKernelLiteral) : Bool :=
  match left with
  | PsKernelLiteral.nat leftValue =>
      match right with
      | PsKernelLiteral.nat rightValue =>
          Nat.beq leftValue rightValue
      | _ =>
          false
  | PsKernelLiteral.str leftValue =>
      match right with
      | PsKernelLiteral.str rightValue =>
          psKernelStringEq leftValue rightValue
      | _ =>
          false

def psKernelLevelListEq
    (left : List PsKernelLevel)
    (right : List PsKernelLevel) : Bool :=
  match left with
  | List.nil =>
      match right with
      | List.nil => true
      | List.cons _ _ => false
  | List.cons leftHead leftTail =>
      match right with
      | List.nil =>
          false
      | List.cons rightHead rightTail =>
          if psKernelLevelEq leftHead rightHead then
            psKernelLevelListEq leftTail rightTail
          else
            false

def psKernelExprEq
    (left : PsKernelExpr)
    (right : PsKernelExpr) : Bool :=
  match left with
  | PsKernelExpr.bvar leftIndex =>
      match right with
      | PsKernelExpr.bvar rightIndex =>
          Nat.beq leftIndex rightIndex
      | _ => false
  | PsKernelExpr.fvar leftName =>
      match right with
      | PsKernelExpr.fvar rightName =>
          psKernelNameEq leftName rightName
      | _ => false
  | PsKernelExpr.mvar leftName =>
      match right with
      | PsKernelExpr.mvar rightName =>
          psKernelNameEq leftName rightName
      | _ => false
  | PsKernelExpr.sort leftLevel =>
      match right with
      | PsKernelExpr.sort rightLevel =>
          psKernelLevelEq leftLevel rightLevel
      | _ => false
  | PsKernelExpr.const leftName leftLevels =>
      match right with
      | PsKernelExpr.const rightName rightLevels =>
          if psKernelNameEq leftName rightName then
            psKernelLevelListEq leftLevels rightLevels
          else
            false
      | _ => false
  | PsKernelExpr.app leftFn leftArg =>
      match right with
      | PsKernelExpr.app rightFn rightArg =>
          if psKernelExprEq leftFn rightFn then
            psKernelExprEq leftArg rightArg
          else
            false
      | _ => false
  | PsKernelExpr.lam _ leftType leftBody _ =>
      match right with
      | PsKernelExpr.lam _ rightType rightBody _ =>
          if psKernelExprEq leftType rightType then
            psKernelExprEq leftBody rightBody
          else
            false
      | _ => false
  | PsKernelExpr.forallE _ leftType leftBody _ =>
      match right with
      | PsKernelExpr.forallE _ rightType rightBody _ =>
          if psKernelExprEq leftType rightType then
            psKernelExprEq leftBody rightBody
          else
            false
      | _ => false
  | PsKernelExpr.letE _ leftType leftValue leftBody leftNondep =>
      match right with
      | PsKernelExpr.letE _ rightType rightValue rightBody rightNondep =>
          if psKernelExprEq leftType rightType then
            if psKernelExprEq leftValue rightValue then
              if psKernelExprEq leftBody rightBody then
                psKernelBoolEq leftNondep rightNondep
              else
                false
            else
              false
          else
            false
      | _ => false
  | PsKernelExpr.lit leftValue =>
      match right with
      | PsKernelExpr.lit rightValue =>
          psKernelLiteralEq leftValue rightValue
      | _ => false
  | PsKernelExpr.mdata leftMetadata leftExpr =>
      match right with
      | PsKernelExpr.mdata rightMetadata rightExpr =>
          if Nat.beq leftMetadata rightMetadata then
            psKernelExprEq leftExpr rightExpr
          else
            false
      | _ => false
  | PsKernelExpr.proj leftName leftIndex leftExpr =>
      match right with
      | PsKernelExpr.proj rightName rightIndex rightExpr =>
          if psKernelNameEq leftName rightName then
            if Nat.beq leftIndex rightIndex then
              psKernelExprEq leftExpr rightExpr
            else
              false
          else
            false
      | _ => false

def psKernelExprEqual
    (left : PsKernelExpr)
    (right : PsKernelExpr) : Bool :=
  match left with
  | PsKernelExpr.bvar leftIndex =>
      match right with
      | PsKernelExpr.bvar rightIndex =>
          Nat.beq leftIndex rightIndex
      | _ => false
  | PsKernelExpr.fvar leftName =>
      match right with
      | PsKernelExpr.fvar rightName =>
          psKernelNameEq leftName rightName
      | _ => false
  | PsKernelExpr.mvar leftName =>
      match right with
      | PsKernelExpr.mvar rightName =>
          psKernelNameEq leftName rightName
      | _ => false
  | PsKernelExpr.sort leftLevel =>
      match right with
      | PsKernelExpr.sort rightLevel =>
          psKernelLevelEq leftLevel rightLevel
      | _ => false
  | PsKernelExpr.const leftName leftLevels =>
      match right with
      | PsKernelExpr.const rightName rightLevels =>
          if psKernelNameEq leftName rightName then
            psKernelLevelListEq leftLevels rightLevels
          else
            false
      | _ => false
  | PsKernelExpr.app leftFn leftArg =>
      match right with
      | PsKernelExpr.app rightFn rightArg =>
          if psKernelExprEqual leftFn rightFn then
            psKernelExprEqual leftArg rightArg
          else
            false
      | _ => false
  | PsKernelExpr.lam leftName leftType leftBody leftInfo =>
      match right with
      | PsKernelExpr.lam rightName rightType rightBody rightInfo =>
          if psKernelNameEq leftName rightName then
            if psKernelExprEqual leftType rightType then
              if psKernelExprEqual leftBody rightBody then
                psKernelBinderInfoEq leftInfo rightInfo
              else
                false
            else
              false
          else
            false
      | _ => false
  | PsKernelExpr.forallE leftName leftType leftBody leftInfo =>
      match right with
      | PsKernelExpr.forallE rightName rightType rightBody rightInfo =>
          if psKernelNameEq leftName rightName then
            if psKernelExprEqual leftType rightType then
              if psKernelExprEqual leftBody rightBody then
                psKernelBinderInfoEq leftInfo rightInfo
              else
                false
            else
              false
          else
            false
      | _ => false
  | PsKernelExpr.letE leftName leftType leftValue leftBody leftNondep =>
      match right with
      | PsKernelExpr.letE rightName rightType rightValue rightBody rightNondep =>
          if psKernelNameEq leftName rightName then
            if psKernelExprEqual leftType rightType then
              if psKernelExprEqual leftValue rightValue then
                if psKernelExprEqual leftBody rightBody then
                  psKernelBoolEq leftNondep rightNondep
                else
                  false
              else
                false
            else
              false
          else
            false
      | _ => false
  | PsKernelExpr.lit leftValue =>
      match right with
      | PsKernelExpr.lit rightValue =>
          psKernelLiteralEq leftValue rightValue
      | _ => false
  | PsKernelExpr.mdata leftMetadata leftExpr =>
      match right with
      | PsKernelExpr.mdata rightMetadata rightExpr =>
          if Nat.beq leftMetadata rightMetadata then
            psKernelExprEqual leftExpr rightExpr
          else
            false
      | _ => false
  | PsKernelExpr.proj leftName leftIndex leftExpr =>
      match right with
      | PsKernelExpr.proj rightName rightIndex rightExpr =>
          if psKernelNameEq leftName rightName then
            if Nat.beq leftIndex rightIndex then
              psKernelExprEqual leftExpr rightExpr
            else
              false
          else
            false
      | _ => false

def psKernelExprHasLooseAt
    (expr : PsKernelExpr)
    (offset : Nat) : Bool :=
  match expr with
  | PsKernelExpr.bvar index =>
      Nat.ble offset index
  | PsKernelExpr.app fn arg =>
      if psKernelExprHasLooseAt fn offset then
        true
      else
        psKernelExprHasLooseAt arg offset
  | PsKernelExpr.lam _ type body _ =>
      if psKernelExprHasLooseAt type offset then
        true
      else
        psKernelExprHasLooseAt body (Nat.succ offset)
  | PsKernelExpr.forallE _ type body _ =>
      if psKernelExprHasLooseAt type offset then
        true
      else
        psKernelExprHasLooseAt body (Nat.succ offset)
  | PsKernelExpr.letE _ type value body _ =>
      if psKernelExprHasLooseAt type offset then
        true
      else if psKernelExprHasLooseAt value offset then
        true
      else
        psKernelExprHasLooseAt body (Nat.succ offset)
  | PsKernelExpr.mdata _ body =>
      psKernelExprHasLooseAt body offset
  | PsKernelExpr.proj _ _ body =>
      psKernelExprHasLooseAt body offset
  | _ =>
      false

def psKernelExprHasLooseBVar
    (expr : PsKernelExpr) : Bool :=
  psKernelExprHasLooseAt expr 0

def psKernelExprHasLooseBVarAtCore
    (expr : PsKernelExpr)
    (index : Nat)
    (depth : Nat) : Bool :=
  match expr with
  | PsKernelExpr.bvar value =>
      Nat.beq value (Nat.add index depth)
  | PsKernelExpr.app fn arg =>
      if
          psKernelExprHasLooseBVarAtCore
            fn
            index
            depth then
        true
      else
        psKernelExprHasLooseBVarAtCore
          arg
          index
          depth
  | PsKernelExpr.lam _ type body _ =>
      if
          psKernelExprHasLooseBVarAtCore
            type
            index
            depth then
        true
      else
        psKernelExprHasLooseBVarAtCore
          body
          index
          (Nat.succ depth)
  | PsKernelExpr.forallE _ type body _ =>
      if
          psKernelExprHasLooseBVarAtCore
            type
            index
            depth then
        true
      else
        psKernelExprHasLooseBVarAtCore
          body
          index
          (Nat.succ depth)
  | PsKernelExpr.letE _ type value body _ =>
      if
          psKernelExprHasLooseBVarAtCore
            type
            index
            depth then
        true
      else if
          psKernelExprHasLooseBVarAtCore
            value
            index
            depth then
        true
      else
        psKernelExprHasLooseBVarAtCore
          body
          index
          (Nat.succ depth)
  | PsKernelExpr.mdata _ body =>
      psKernelExprHasLooseBVarAtCore
        body
        index
        depth
  | PsKernelExpr.proj _ _ body =>
      psKernelExprHasLooseBVarAtCore
        body
        index
        depth
  | _ =>
      false

def psKernelExprHasLooseBVarAt
    (expr : PsKernelExpr)
    (index : Nat) : Bool :=
  psKernelExprHasLooseBVarAtCore
    expr
    index
    0

def psKernelExprHasLooseBVarInExplicitDomain
    (expr : PsKernelExpr)
    (bvarIndex : Nat)
    (considerRange : Bool) : Bool :=
  match expr with
  | PsKernelExpr.forallE _ domain body binderInfo =>
      let dependency :=
        if psKernelExprHasLooseBVarAt domain bvarIndex then
          if
              psKernelBinderInfoEq
                binderInfo
                PsKernelBinderInfo.default then
            true
          else
            psKernelExprHasLooseBVarInExplicitDomain
              body
              0
              considerRange
        else
          false;
      if dependency then
        true
      else
        psKernelExprHasLooseBVarInExplicitDomain
          body
          (Nat.succ bvarIndex)
          considerRange
  | _ =>
      if considerRange then
        psKernelExprHasLooseBVarAt
          expr
          bvarIndex
      else
        false

def psKernelExprInferImplicit
    (expr : PsKernelExpr)
    (numParams : Nat)
    (considerRange : Bool) : PsKernelExpr :=
  match expr with
  | PsKernelExpr.forallE name domain body binderInfo =>
      match numParams with
      | Nat.zero =>
          expr
      | Nat.succ remaining =>
          let changedBody :=
            psKernelExprInferImplicit
              body
              remaining
              considerRange;
          let changedInfo :=
            if
                psKernelBinderInfoEq
                  binderInfo
                  PsKernelBinderInfo.default then
              if
                  psKernelExprHasLooseBVarInExplicitDomain
                    changedBody
                    0
                    considerRange then
                PsKernelBinderInfo.implicit
              else
                binderInfo
            else
              binderInfo;
          PsKernelExpr.forallE
            name
            domain
            changedBody
            changedInfo
  | _ =>
      expr

def psKernelExprInferImplicitAll
    (expr : PsKernelExpr)
    (considerRange : Bool) : PsKernelExpr :=
  match expr with
  | PsKernelExpr.forallE name domain body binderInfo =>
      let changedBody :=
        psKernelExprInferImplicitAll
          body
          considerRange;
      let changedInfo :=
        if
            psKernelBinderInfoEq
              binderInfo
              PsKernelBinderInfo.default then
          if
              psKernelExprHasLooseBVarInExplicitDomain
                changedBody
                0
                considerRange then
            PsKernelBinderInfo.implicit
          else
            binderInfo
        else
          binderInfo;
      PsKernelExpr.forallE
        name
        domain
        changedBody
        changedInfo
  | _ =>
      expr

def psKernelExprGetAppFn
    (expr : PsKernelExpr) : PsKernelExpr :=
  match expr with
  | PsKernelExpr.app fn _ =>
      psKernelExprGetAppFn fn
  | _ =>
      expr

def psKernelExprGetAppArgsWorker
    (expr : PsKernelExpr)
    (args : List PsKernelExpr) :
    List PsKernelExpr :=
  match expr with
  | PsKernelExpr.app fn arg =>
      psKernelExprGetAppArgsWorker
        fn
        (List.cons arg args)
  | _ =>
      args

def psKernelExprGetAppArgs
    (expr : PsKernelExpr) :
    List PsKernelExpr :=
  psKernelExprGetAppArgsWorker
    expr
    List.nil

def psKernelExprListLength
    (values : List PsKernelExpr) : Nat :=
  match values with
  | List.nil =>
      0
  | List.cons _ rest =>
      Nat.succ (psKernelExprListLength rest)

def psKernelExprGetAppNumArgs
    (expr : PsKernelExpr) : Nat :=
  psKernelExprListLength
    (psKernelExprGetAppArgs expr)

def psKernelTypeAnnotationOutParamName : PsKernelName :=
  PsKernelName.str PsKernelName.anonymous "outParam"

def psKernelTypeAnnotationSemiOutParamName : PsKernelName :=
  PsKernelName.str PsKernelName.anonymous "semiOutParam"

def psKernelTypeAnnotationOptParamName : PsKernelName :=
  PsKernelName.str PsKernelName.anonymous "optParam"

def psKernelTypeAnnotationAutoParamName : PsKernelName :=
  PsKernelName.str PsKernelName.anonymous "autoParam"

def psKernelExprConsumeTypeAnnotations
    (expr : PsKernelExpr) : PsKernelExpr :=
  let fn := psKernelExprGetAppFn expr;
  let args := psKernelExprGetAppArgs expr;
  match fn with
  | PsKernelExpr.const name _ =>
      match args with
      | List.cons first rest =>
          match rest with
          | List.nil =>
              if
                  if psKernelNameEq
                      name
                      psKernelTypeAnnotationOutParamName then
                    true
                  else
                    psKernelNameEq
                      name
                      psKernelTypeAnnotationSemiOutParamName then
                psKernelExprConsumeTypeAnnotations first
              else
                expr
          | List.cons _ secondRest =>
              match secondRest with
              | List.nil =>
                  if
                      if psKernelNameEq
                          name
                          psKernelTypeAnnotationOptParamName then
                        true
                      else
                        psKernelNameEq
                          name
                          psKernelTypeAnnotationAutoParamName then
                    psKernelExprConsumeTypeAnnotations first
                  else
                    expr
              | List.cons _ _ =>
                  expr
      | List.nil =>
          expr
  | _ =>
      expr

def psKernelExprHasFVar
    (expr : PsKernelExpr) : Bool :=
  match expr with
  | PsKernelExpr.fvar _ =>
      true
  | PsKernelExpr.app fn arg =>
      if psKernelExprHasFVar fn then
        true
      else
        psKernelExprHasFVar arg
  | PsKernelExpr.lam _ type body _ =>
      if psKernelExprHasFVar type then
        true
      else
        psKernelExprHasFVar body
  | PsKernelExpr.forallE _ type body _ =>
      if psKernelExprHasFVar type then
        true
      else
        psKernelExprHasFVar body
  | PsKernelExpr.letE _ type value body _ =>
      if psKernelExprHasFVar type then
        true
      else if psKernelExprHasFVar value then
        true
      else
        psKernelExprHasFVar body
  | PsKernelExpr.mdata _ body =>
      psKernelExprHasFVar body
  | PsKernelExpr.proj _ _ body =>
      psKernelExprHasFVar body
  | _ =>
      false

def psKernelInstantiateLevelList
    (levels : List PsKernelLevel)
    (params : List PsKernelName)
    (values : List PsKernelLevel) :
    List PsKernelLevel :=
  match levels with
  | List.nil =>
      List.nil
  | List.cons level rest =>
      List.cons
        (psKernelLevelInstantiateParams
          level
          params
          values)
        (psKernelInstantiateLevelList
          rest
          params
          values)

def psKernelExprInstantiateLevelParams
    (expr : PsKernelExpr)
    (params : List PsKernelName)
    (values : List PsKernelLevel) :
    PsKernelExpr :=
  match expr with
  | PsKernelExpr.sort level =>
      PsKernelExpr.sort
        (psKernelLevelInstantiateParams
          level
          params
          values)
  | PsKernelExpr.const name levels =>
      PsKernelExpr.const
        name
        (psKernelInstantiateLevelList
          levels
          params
          values)
  | PsKernelExpr.app fn arg =>
      PsKernelExpr.app
        (psKernelExprInstantiateLevelParams
          fn
          params
          values)
        (psKernelExprInstantiateLevelParams
          arg
          params
          values)
  | PsKernelExpr.lam name type body binderInfo =>
      PsKernelExpr.lam
        name
        (psKernelExprInstantiateLevelParams
          type
          params
          values)
        (psKernelExprInstantiateLevelParams
          body
          params
          values)
        binderInfo
  | PsKernelExpr.forallE name type body binderInfo =>
      PsKernelExpr.forallE
        name
        (psKernelExprInstantiateLevelParams
          type
          params
          values)
        (psKernelExprInstantiateLevelParams
          body
          params
          values)
        binderInfo
  | PsKernelExpr.letE name type value body nondep =>
      PsKernelExpr.letE
        name
        (psKernelExprInstantiateLevelParams
          type
          params
          values)
        (psKernelExprInstantiateLevelParams
          value
          params
          values)
        (psKernelExprInstantiateLevelParams
          body
          params
          values)
        nondep
  | PsKernelExpr.mdata metadata body =>
      PsKernelExpr.mdata
        metadata
        (psKernelExprInstantiateLevelParams
          body
          params
          values)
  | PsKernelExpr.proj typeName index body =>
      PsKernelExpr.proj
        typeName
        index
        (psKernelExprInstantiateLevelParams
          body
          params
          values)
  | _ =>
      expr
