import Ps.PSCKernel.Core.DefEqBasic
import Ps.PSCKernel.Core.TypeInference

def psCKernelExprIsProposition
    (env : PsCKernelEnvironment)
    (lctx : PsCKernelLocalContext)
    (expr : PsCKernelExpr) : Bool :=
  match psCKernelInfer? env lctx expr with
  | none => false
  | some exprType =>
      match psCKernelExprWhnfBasic env lctx exprType with
      | PsCKernelExpr.sortE level =>
          psCKernelLevelEquivalent level psCKernelLevelZero
      | _ => false

def psCKernelProofIrrelevanceEquivalent
    (env : PsCKernelEnvironment)
    (lctx : PsCKernelLocalContext)
    (left : PsCKernelExpr)
    (right : PsCKernelExpr)
    (isDefEq : PsCKernelExpr -> PsCKernelExpr -> Bool) : Bool :=
  match psCKernelInfer? env lctx left with
  | none => false
  | some leftType =>
      if psCKernelExprIsProposition env lctx leftType then
        match psCKernelInfer? env lctx right with
        | none => false
        | some rightType => isDefEq leftType rightType
      else
        false

def psCKernelEtaExpand?
    (env : PsCKernelEnvironment)
    (lctx : PsCKernelLocalContext)
    (expr : PsCKernelExpr) : Option PsCKernelExpr :=
  match psCKernelInfer? env lctx expr with
  | none => none
  | some exprType =>
      match psCKernelExprWhnfBasic env lctx exprType with
      | PsCKernelExpr.forallE name domain _ binderInfo =>
          some
            (PsCKernelExpr.lam
              name
              domain
              (PsCKernelExpr.app
                (psCKernelExprLiftLooseBVars expr 0 1)
                (PsCKernelExpr.bvar 0))
              binderInfo)
      | _ => none

def psCKernelExprListGet?
    (values : List PsCKernelExpr)
    (index : Nat) : Option PsCKernelExpr :=
  match values, index with
  | [], _ => none
  | value :: _, 0 => some value
  | _ :: rest, Nat.succ next => psCKernelExprListGet? rest next

def psCKernelStructEtaFieldsEqual
    (typeName : PsCKernelName)
    (target : PsCKernelExpr)
    (args : List PsCKernelExpr)
    (parameterCount : Nat)
    (fieldIndex : Nat)
    (remaining : Nat)
    (isDefEq : PsCKernelExpr -> PsCKernelExpr -> Bool) : Bool :=
  match remaining with
  | 0 => true
  | Nat.succ rest =>
      match psCKernelExprListGet? args (Nat.add parameterCount fieldIndex) with
      | none => false
      | some fieldValue =>
          if isDefEq
              (PsCKernelExpr.proj typeName fieldIndex target)
              fieldValue then
            psCKernelStructEtaFieldsEqual
              typeName
              target
              args
              parameterCount
              (Nat.add fieldIndex 1)
              rest
              isDefEq
          else
            false

def psCKernelTryStructEtaCore
    (env : PsCKernelEnvironment)
    (lctx : PsCKernelLocalContext)
    (target : PsCKernelExpr)
    (constructorExpr : PsCKernelExpr)
    (isDefEq : PsCKernelExpr -> PsCKernelExpr -> Bool) : Bool :=
  let head := psCKernelExprGetAppFn constructorExpr
  let args := psCKernelExprGetAppArgs constructorExpr
  match head with
  | PsCKernelExpr.constE ctorName _ =>
      match psCKernelEnvironmentFind? env ctorName with
      | some (PsCKernelConstantInfo.ctorInfo ctorInfo) =>
          if Nat.beq
              args.length
              (Nat.add ctorInfo.numParams ctorInfo.numFields) then
            match psCKernelEnvironmentFind? env ctorInfo.induct with
            | some (PsCKernelConstantInfo.inductInfo inductInfo) =>
                if inductInfo.isRec then
                  false
                else if !Nat.beq inductInfo.numIndices 0 then
                  false
                else if !Nat.beq inductInfo.ctors.length 1 then
                  false
                else
                  match psCKernelInfer? env lctx target with
                  | none => false
                  | some targetType =>
                      match psCKernelInfer? env lctx constructorExpr with
                      | none => false
                      | some constructorType =>
                          if isDefEq targetType constructorType then
                            psCKernelStructEtaFieldsEqual
                              ctorInfo.induct
                              target
                              args
                              ctorInfo.numParams
                              0
                              ctorInfo.numFields
                              isDefEq
                          else
                            false
            | _ => false
          else
            false
      | _ => false
  | _ => false

partial def psCKernelIsDefEq
    (env : PsCKernelEnvironment)
    (lctx : PsCKernelLocalContext)
    (left : PsCKernelExpr)
    (right : PsCKernelExpr) : Bool :=
  if psCKernelIsDefEqBasic env lctx left right then
    true
  else if
      psCKernelProofIrrelevanceEquivalent
        env lctx left right (psCKernelIsDefEq env lctx) then
    true
  else
    match left, right with
    | PsCKernelExpr.lam _ _ _ _, PsCKernelExpr.lam _ _ _ _ => false
    | PsCKernelExpr.lam _ _ _ _, _ =>
        match psCKernelEtaExpand? env lctx right with
        | none => false
        | some expandedRight =>
            psCKernelIsDefEq env lctx left expandedRight
    | _, PsCKernelExpr.lam _ _ _ _ =>
        match psCKernelEtaExpand? env lctx left with
        | none => false
        | some expandedLeft =>
            psCKernelIsDefEq env lctx expandedLeft right
    | _, _ =>
        if
            psCKernelTryStructEtaCore
              env lctx left right (psCKernelIsDefEq env lctx) then
          true
        else
          psCKernelTryStructEtaCore
            env lctx right left (psCKernelIsDefEq env lctx)
