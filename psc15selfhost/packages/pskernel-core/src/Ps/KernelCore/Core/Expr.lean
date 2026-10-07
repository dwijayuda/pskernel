import Ps.KernelCore.Core.Level

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
    (left : List PsKernelLevel) :
    List PsKernelLevel -> Bool :=
  match left with
  | List.nil =>
      fun (right : List PsKernelLevel) =>
        match right with
        | List.nil => true
        | List.cons _ _ => false
  | List.cons leftHead leftTail =>
      let smaller :
          List PsKernelLevel -> Bool :=
        psKernelLevelListEq leftTail;
      fun (right : List PsKernelLevel) =>
        match right with
        | List.nil =>
            false
        | List.cons rightHead rightTail =>
            if psKernelLevelEq leftHead rightHead then
              smaller rightTail
            else
              false

def psKernelExprEq
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
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.app rightFn rightArg =>
            if psKernelExprEq leftFn rightFn then
              psKernelExprEq leftArg rightArg
            else false
        | _ => false
  | PsKernelExpr.lam _ leftType leftBody _ =>
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.lam _ rightType rightBody _ =>
            if psKernelExprEq leftType rightType then
              psKernelExprEq leftBody rightBody
            else false
        | _ => false
  | PsKernelExpr.forallE _ leftType leftBody _ =>
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.forallE _ rightType rightBody _ =>
            if psKernelExprEq leftType rightType then
              psKernelExprEq leftBody rightBody
            else false
        | _ => false
  | PsKernelExpr.letE _ leftType leftValue leftBody leftNondep =>
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.letE _ rightType rightValue rightBody rightNondep =>
            if psKernelExprEq leftType rightType then
              if psKernelExprEq leftValue rightValue then
                if psKernelExprEq leftBody rightBody then
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
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.mdata rightMetadata rightExpr =>
            if Nat.beq leftMetadata rightMetadata then
              psKernelExprEq leftExpr rightExpr
            else false
        | _ => false
  | PsKernelExpr.proj leftName leftIndex leftExpr =>
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.proj rightName rightIndex rightExpr =>
            if psKernelNameEq leftName rightName then
              if Nat.beq leftIndex rightIndex then
                psKernelExprEq leftExpr rightExpr
              else false
            else false
        | _ => false

def psKernelExprEqual
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
        psKernelExprEqual leftFn;
      let argEq : PsKernelExpr -> Bool :=
        psKernelExprEqual leftArg;
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.app rightFn rightArg =>
            if fnEq rightFn then argEq rightArg else false
        | _ => false
  | PsKernelExpr.lam leftName leftType leftBody leftInfo =>
      let typeEq : PsKernelExpr -> Bool :=
        psKernelExprEqual leftType;
      let bodyEq : PsKernelExpr -> Bool :=
        psKernelExprEqual leftBody;
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
        psKernelExprEqual leftType;
      let bodyEq : PsKernelExpr -> Bool :=
        psKernelExprEqual leftBody;
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
        psKernelExprEqual leftType;
      let valueEq : PsKernelExpr -> Bool :=
        psKernelExprEqual leftValue;
      let bodyEq : PsKernelExpr -> Bool :=
        psKernelExprEqual leftBody;
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
        psKernelExprEqual leftExpr;
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.mdata rightMetadata rightExpr =>
            if Nat.beq leftMetadata rightMetadata then
              exprEq rightExpr
            else false
        | _ => false
  | PsKernelExpr.proj leftName leftIndex leftExpr =>
      let exprEq : PsKernelExpr -> Bool :=
        psKernelExprEqual leftExpr;
      fun (right : PsKernelExpr) =>
        match right with
        | PsKernelExpr.proj rightName rightIndex rightExpr =>
            if psKernelNameEq leftName rightName then
              if Nat.beq leftIndex rightIndex then
                exprEq rightExpr
              else false
            else false
        | _ => false

def psKernelExprHasLooseAt
    (expr : PsKernelExpr) :
    Nat -> Bool :=
  match expr with
  | PsKernelExpr.bvar index =>
      fun (offset : Nat) =>
        Nat.ble offset index
  | PsKernelExpr.app fn arg =>
      let fnHas : Nat -> Bool :=
        psKernelExprHasLooseAt fn;
      let argHas : Nat -> Bool :=
        psKernelExprHasLooseAt arg;
      fun (offset : Nat) =>
        if fnHas offset then true else argHas offset
  | PsKernelExpr.lam _ type body _ =>
      let typeHas : Nat -> Bool :=
        psKernelExprHasLooseAt type;
      let bodyHas : Nat -> Bool :=
        psKernelExprHasLooseAt body;
      fun (offset : Nat) =>
        if typeHas offset then true
        else bodyHas (Nat.succ offset)
  | PsKernelExpr.forallE _ type body _ =>
      let typeHas : Nat -> Bool :=
        psKernelExprHasLooseAt type;
      let bodyHas : Nat -> Bool :=
        psKernelExprHasLooseAt body;
      fun (offset : Nat) =>
        if typeHas offset then true
        else bodyHas (Nat.succ offset)
  | PsKernelExpr.letE _ type value body _ =>
      let typeHas : Nat -> Bool :=
        psKernelExprHasLooseAt type;
      let valueHas : Nat -> Bool :=
        psKernelExprHasLooseAt value;
      let bodyHas : Nat -> Bool :=
        psKernelExprHasLooseAt body;
      fun (offset : Nat) =>
        if typeHas offset then true
        else if valueHas offset then true
        else bodyHas (Nat.succ offset)
  | PsKernelExpr.mdata _ body =>
      psKernelExprHasLooseAt body
  | PsKernelExpr.proj _ _ body =>
      psKernelExprHasLooseAt body
  | _ =>
      fun (_offset : Nat) => false

def psKernelExprHasLooseBVar
    (expr : PsKernelExpr) : Bool :=
  psKernelExprHasLooseAt expr 0

def psKernelExprHasLooseBVarAtCore
    (expr : PsKernelExpr) :
    Nat -> Nat -> Bool :=
  match expr with
  | PsKernelExpr.bvar value =>
      fun (index : Nat) (depth : Nat) =>
        Nat.beq value (Nat.add index depth)
  | PsKernelExpr.app fn arg =>
      let fnHas : Nat -> Nat -> Bool :=
        psKernelExprHasLooseBVarAtCore fn;
      let argHas : Nat -> Nat -> Bool :=
        psKernelExprHasLooseBVarAtCore arg;
      fun (index : Nat) (depth : Nat) =>
        if fnHas index depth then true
        else argHas index depth
  | PsKernelExpr.lam _ type body _ =>
      let typeHas : Nat -> Nat -> Bool :=
        psKernelExprHasLooseBVarAtCore type;
      let bodyHas : Nat -> Nat -> Bool :=
        psKernelExprHasLooseBVarAtCore body;
      fun (index : Nat) (depth : Nat) =>
        if typeHas index depth then true
        else bodyHas index (Nat.succ depth)
  | PsKernelExpr.forallE _ type body _ =>
      let typeHas : Nat -> Nat -> Bool :=
        psKernelExprHasLooseBVarAtCore type;
      let bodyHas : Nat -> Nat -> Bool :=
        psKernelExprHasLooseBVarAtCore body;
      fun (index : Nat) (depth : Nat) =>
        if typeHas index depth then true
        else bodyHas index (Nat.succ depth)
  | PsKernelExpr.letE _ type value body _ =>
      let typeHas : Nat -> Nat -> Bool :=
        psKernelExprHasLooseBVarAtCore type;
      let valueHas : Nat -> Nat -> Bool :=
        psKernelExprHasLooseBVarAtCore value;
      let bodyHas : Nat -> Nat -> Bool :=
        psKernelExprHasLooseBVarAtCore body;
      fun (index : Nat) (depth : Nat) =>
        if typeHas index depth then true
        else if valueHas index depth then true
        else bodyHas index (Nat.succ depth)
  | PsKernelExpr.mdata _ body =>
      psKernelExprHasLooseBVarAtCore body
  | PsKernelExpr.proj _ _ body =>
      psKernelExprHasLooseBVarAtCore body
  | _ =>
      fun (_index : Nat) (_depth : Nat) => false

def psKernelExprHasLooseBVarAt
    (expr : PsKernelExpr)
    (index : Nat) : Bool :=
  psKernelExprHasLooseBVarAtCore
    expr
    index
    0

def psKernelExprHasLooseBVarInExplicitDomain
    (expr : PsKernelExpr) :
    Nat -> Bool -> Bool :=
  match expr with
  | PsKernelExpr.forallE _ domain body binderInfo =>
      let smaller : Nat -> Bool -> Bool :=
        psKernelExprHasLooseBVarInExplicitDomain body;
      fun (bvarIndex : Nat) (considerRange : Bool) =>
        let dependency :=
          if psKernelExprHasLooseBVarAt domain bvarIndex then
            if
                psKernelBinderInfoEq
                  binderInfo
                  PsKernelBinderInfo.default then
              true
            else
              smaller 0 considerRange
          else
            false;
        if dependency then
          true
        else
          smaller
            (Nat.succ bvarIndex)
            considerRange
  | _ =>
      fun (bvarIndex : Nat) (considerRange : Bool) =>
        if considerRange then
          psKernelExprHasLooseBVarAt
            expr
            bvarIndex
        else
          false

def psKernelExprInferImplicit
    (expr : PsKernelExpr) :
    Nat -> Bool -> PsKernelExpr :=
  match expr with
  | PsKernelExpr.forallE name domain body binderInfo =>
      let smaller : Nat -> Bool -> PsKernelExpr :=
        psKernelExprInferImplicit body;
      fun (numParams : Nat) (considerRange : Bool) =>
        match numParams with
        | Nat.zero =>
            expr
        | Nat.succ remaining =>
            let changedBody :=
              smaller remaining considerRange;
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
      fun (_numParams : Nat) (_considerRange : Bool) =>
        expr

def psKernelExprInferImplicitAll
    (expr : PsKernelExpr) :
    Bool -> PsKernelExpr :=
  match expr with
  | PsKernelExpr.forallE name domain body binderInfo =>
      let smaller : Bool -> PsKernelExpr :=
        psKernelExprInferImplicitAll body;
      fun (considerRange : Bool) =>
        let changedBody :=
          smaller considerRange;
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
      fun (_considerRange : Bool) =>
        expr

def psKernelExprGetAppFnArgsWorker
    (expr : PsKernelExpr) :
    List PsKernelExpr ->
    Prod PsKernelExpr (List PsKernelExpr) :=
  match expr with
  | PsKernelExpr.app fn arg =>
      let smaller :
          List PsKernelExpr ->
          Prod PsKernelExpr (List PsKernelExpr) :=
        psKernelExprGetAppFnArgsWorker fn;
      fun (args : List PsKernelExpr) =>
        smaller
          (List.cons arg args)
  | _ =>
      fun (args : List PsKernelExpr) =>
        Prod.mk expr args

def psKernelExprGetAppFnArgs
    (expr : PsKernelExpr) :
    Prod PsKernelExpr (List PsKernelExpr) :=
  psKernelExprGetAppFnArgsWorker
    expr
    List.nil

def psKernelExprGetAppFn
    (expr : PsKernelExpr) : PsKernelExpr :=
  match expr with
  | PsKernelExpr.app fn _ =>
      psKernelExprGetAppFn fn
  | _ =>
      expr

def psKernelExprGetAppArgsWorker
    (expr : PsKernelExpr) :
    List PsKernelExpr -> List PsKernelExpr :=
  match expr with
  | PsKernelExpr.app fn arg =>
      let smaller :
          List PsKernelExpr -> List PsKernelExpr :=
        psKernelExprGetAppArgsWorker fn;
      fun (args : List PsKernelExpr) =>
        smaller (List.cons arg args)
  | _ =>
      fun (args : List PsKernelExpr) =>
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

def psKernelExprNodeCount
    (expr : PsKernelExpr) : Nat :=
  match expr with
  | PsKernelExpr.app fn arg =>
      Nat.succ
        (Nat.add
          (psKernelExprNodeCount fn)
          (psKernelExprNodeCount arg))
  | PsKernelExpr.lam _ type body _ =>
      Nat.succ
        (Nat.add
          (psKernelExprNodeCount type)
          (psKernelExprNodeCount body))
  | PsKernelExpr.forallE _ type body _ =>
      Nat.succ
        (Nat.add
          (psKernelExprNodeCount type)
          (psKernelExprNodeCount body))
  | PsKernelExpr.letE _ type value body _ =>
      Nat.succ
        (Nat.add
          (psKernelExprNodeCount type)
          (Nat.add
            (psKernelExprNodeCount value)
            (psKernelExprNodeCount body)))
  | PsKernelExpr.mdata _ body =>
      Nat.succ (psKernelExprNodeCount body)
  | PsKernelExpr.proj _ _ body =>
      Nat.succ (psKernelExprNodeCount body)
  | _ =>
      1

def psKernelExprConsumeTypeAnnotationsWithFuel
    (fuel : Nat) :
    PsKernelExpr -> PsKernelExpr :=
  match fuel with
  | Nat.zero =>
      fun (expr : PsKernelExpr) =>
        expr
  | Nat.succ remaining =>
      let smaller : PsKernelExpr -> PsKernelExpr :=
        psKernelExprConsumeTypeAnnotationsWithFuel remaining;
      fun (expr : PsKernelExpr) =>
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
                      smaller first
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
                          smaller first
                        else
                          expr
                    | List.cons _ _ =>
                        expr
            | List.nil =>
                expr
        | _ =>
            expr

def psKernelExprConsumeTypeAnnotations
    (expr : PsKernelExpr) : PsKernelExpr :=
  psKernelExprConsumeTypeAnnotationsWithFuel
    (Nat.succ (psKernelExprNodeCount expr))
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
    (levels : List PsKernelLevel) :
    List PsKernelName ->
    List PsKernelLevel ->
    List PsKernelLevel :=
  match levels with
  | List.nil =>
      fun
        (_params : List PsKernelName)
        (_values : List PsKernelLevel) =>
        List.nil
  | List.cons level rest =>
      let smaller :
          List PsKernelName ->
          List PsKernelLevel ->
          List PsKernelLevel :=
        psKernelInstantiateLevelList rest;
      fun
        (params : List PsKernelName)
        (values : List PsKernelLevel) =>
        List.cons
          (psKernelLevelInstantiateParams
            level
            params
            values)
          (smaller params values)

def psKernelExprInstantiateLevelParams
    (expr : PsKernelExpr) :
    List PsKernelName ->
    List PsKernelLevel ->
    PsKernelExpr :=
  match expr with
  | PsKernelExpr.sort level =>
      fun
        (params : List PsKernelName)
        (values : List PsKernelLevel) =>
        PsKernelExpr.sort
          (psKernelLevelInstantiateParams
            level
            params
            values)
  | PsKernelExpr.const name levels =>
      fun
        (params : List PsKernelName)
        (values : List PsKernelLevel) =>
        PsKernelExpr.const
          name
          (psKernelInstantiateLevelList
            levels
            params
            values)
  | PsKernelExpr.app fn arg =>
      let instantiateFn :
          List PsKernelName ->
          List PsKernelLevel ->
          PsKernelExpr :=
        psKernelExprInstantiateLevelParams fn;
      let instantiateArg :
          List PsKernelName ->
          List PsKernelLevel ->
          PsKernelExpr :=
        psKernelExprInstantiateLevelParams arg;
      fun
        (params : List PsKernelName)
        (values : List PsKernelLevel) =>
        PsKernelExpr.app
          (instantiateFn params values)
          (instantiateArg params values)
  | PsKernelExpr.lam name type body binderInfo =>
      let instantiateType :
          List PsKernelName ->
          List PsKernelLevel ->
          PsKernelExpr :=
        psKernelExprInstantiateLevelParams type;
      let instantiateBody :
          List PsKernelName ->
          List PsKernelLevel ->
          PsKernelExpr :=
        psKernelExprInstantiateLevelParams body;
      fun
        (params : List PsKernelName)
        (values : List PsKernelLevel) =>
        PsKernelExpr.lam
          name
          (instantiateType params values)
          (instantiateBody params values)
          binderInfo
  | PsKernelExpr.forallE name type body binderInfo =>
      let instantiateType :
          List PsKernelName ->
          List PsKernelLevel ->
          PsKernelExpr :=
        psKernelExprInstantiateLevelParams type;
      let instantiateBody :
          List PsKernelName ->
          List PsKernelLevel ->
          PsKernelExpr :=
        psKernelExprInstantiateLevelParams body;
      fun
        (params : List PsKernelName)
        (values : List PsKernelLevel) =>
        PsKernelExpr.forallE
          name
          (instantiateType params values)
          (instantiateBody params values)
          binderInfo
  | PsKernelExpr.letE name type value body nondep =>
      let instantiateType :
          List PsKernelName ->
          List PsKernelLevel ->
          PsKernelExpr :=
        psKernelExprInstantiateLevelParams type;
      let instantiateValue :
          List PsKernelName ->
          List PsKernelLevel ->
          PsKernelExpr :=
        psKernelExprInstantiateLevelParams value;
      let instantiateBody :
          List PsKernelName ->
          List PsKernelLevel ->
          PsKernelExpr :=
        psKernelExprInstantiateLevelParams body;
      fun
        (params : List PsKernelName)
        (values : List PsKernelLevel) =>
        PsKernelExpr.letE
          name
          (instantiateType params values)
          (instantiateValue params values)
          (instantiateBody params values)
          nondep
  | PsKernelExpr.mdata metadata body =>
      let instantiateBody :
          List PsKernelName ->
          List PsKernelLevel ->
          PsKernelExpr :=
        psKernelExprInstantiateLevelParams body;
      fun
        (params : List PsKernelName)
        (values : List PsKernelLevel) =>
        PsKernelExpr.mdata
          metadata
          (instantiateBody params values)
  | PsKernelExpr.proj typeName index body =>
      let instantiateBody :
          List PsKernelName ->
          List PsKernelLevel ->
          PsKernelExpr :=
        psKernelExprInstantiateLevelParams body;
      fun
        (params : List PsKernelName)
        (values : List PsKernelLevel) =>
        PsKernelExpr.proj
          typeName
          index
          (instantiateBody params values)
  | _ =>
      fun
        (_params : List PsKernelName)
        (_values : List PsKernelLevel) =>
        expr

