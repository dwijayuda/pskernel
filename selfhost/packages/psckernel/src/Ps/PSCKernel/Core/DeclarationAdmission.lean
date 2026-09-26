import Ps.PSCKernel.Core.CheckedInferenceBasic
import Ps.PSCKernel.Core.DefEq

def psCKernelAdmissionNameInList
    (names : List PsCKernelName)
    (target : PsCKernelName) : Bool :=
  match names with
  | [] => false
  | name :: rest =>
      if psCKernelNameEq name target then
        true
      else
        psCKernelAdmissionNameInList rest target

def psCKernelAdmissionUniqueNames (names : List PsCKernelName) : Bool :=
  match names with
  | [] => true
  | name :: rest =>
      if psCKernelAdmissionNameInList rest name then
        false
      else
        psCKernelAdmissionUniqueNames rest

def psCKernelAdmissionLevelAllowed
    (allowedParams : List PsCKernelName)
    (level : PsCKernelLevel) : Bool :=
  match level with
  | PsCKernelLevel.zero => true
  | PsCKernelLevel.succ inner =>
      psCKernelAdmissionLevelAllowed allowedParams inner
  | PsCKernelLevel.max left right =>
      if psCKernelAdmissionLevelAllowed allowedParams left then
        psCKernelAdmissionLevelAllowed allowedParams right
      else
        false
  | PsCKernelLevel.imax left right =>
      if psCKernelAdmissionLevelAllowed allowedParams left then
        psCKernelAdmissionLevelAllowed allowedParams right
      else
        false
  | PsCKernelLevel.param name =>
      psCKernelAdmissionNameInList allowedParams name
  | PsCKernelLevel.mvar _ => false

def psCKernelAdmissionLevelsAllowed
    (allowedParams : List PsCKernelName)
    (levels : List PsCKernelLevel) : Bool :=
  match levels with
  | [] => true
  | level :: rest =>
      if psCKernelAdmissionLevelAllowed allowedParams level then
        psCKernelAdmissionLevelsAllowed allowedParams rest
      else
        false

def psCKernelAdmissionExprClosedAt
    (allowedParams : List PsCKernelName)
    (depth : Nat)
    (expr : PsCKernelExpr) : Bool :=
  match expr with
  | PsCKernelExpr.bvar index => Nat.blt index depth
  | PsCKernelExpr.fvar _ => false
  | PsCKernelExpr.mvar _ => false
  | PsCKernelExpr.sortE level =>
      psCKernelAdmissionLevelAllowed allowedParams level
  | PsCKernelExpr.constE _ levels =>
      psCKernelAdmissionLevelsAllowed allowedParams levels
  | PsCKernelExpr.app fn arg =>
      if psCKernelAdmissionExprClosedAt allowedParams depth fn then
        psCKernelAdmissionExprClosedAt allowedParams depth arg
      else
        false
  | PsCKernelExpr.lam _ domain body _ =>
      if psCKernelAdmissionExprClosedAt allowedParams depth domain then
        psCKernelAdmissionExprClosedAt allowedParams (Nat.succ depth) body
      else
        false
  | PsCKernelExpr.forallE _ domain body _ =>
      if psCKernelAdmissionExprClosedAt allowedParams depth domain then
        psCKernelAdmissionExprClosedAt allowedParams (Nat.succ depth) body
      else
        false
  | PsCKernelExpr.letE _ domain value body _ =>
      if psCKernelAdmissionExprClosedAt allowedParams depth domain then
        if psCKernelAdmissionExprClosedAt allowedParams depth value then
          psCKernelAdmissionExprClosedAt allowedParams (Nat.succ depth) body
        else
          false
      else
        false
  | PsCKernelExpr.lit _ => true
  | PsCKernelExpr.proj _ _ target =>
      psCKernelAdmissionExprClosedAt allowedParams depth target

def psCKernelAdmissionExprClosed
    (allowedParams : List PsCKernelName)
    (expr : PsCKernelExpr) : Bool :=
  psCKernelAdmissionExprClosedAt allowedParams 0 expr

def psCKernelAdmissionTypeIsType
    (env : PsCKernelEnvironment)
    (expr : PsCKernelExpr) : Bool :=
  match psCKernelCheckBasic? env psCKernelLocalContextEmpty expr with
  | none => false
  | some exprType =>
      match psCKernelExprWhnfBasic env psCKernelLocalContextEmpty exprType with
      | PsCKernelExpr.sortE _ => true
      | _ => false

def psCKernelAdmissionTypeIsProp
    (env : PsCKernelEnvironment)
    (expr : PsCKernelExpr) : Bool :=
  match psCKernelCheckBasic? env psCKernelLocalContextEmpty expr with
  | none => false
  | some exprType =>
      match psCKernelExprWhnfBasic env psCKernelLocalContextEmpty exprType with
      | PsCKernelExpr.sortE level =>
          psCKernelLevelEquivalent level psCKernelLevelZero
      | _ => false

def psCKernelAdmissionValueMatches
    (env : PsCKernelEnvironment)
    (value : PsCKernelExpr)
    (expectedType : PsCKernelExpr) : Bool :=
  match psCKernelCheckBasic? env psCKernelLocalContextEmpty value with
  | none => false
  | some valueType =>
      psCKernelIsDefEq
        env
        psCKernelLocalContextEmpty
        valueType
        expectedType

def psCKernelAdmissionCommonValid
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : Bool :=
  let name := psCKernelConstantInfoName info
  let levelParams := psCKernelConstantInfoLevelParams info
  let declType := psCKernelConstantInfoType info
  if psCKernelEnvironmentContains env name then
    false
  else if !psCKernelAdmissionUniqueNames levelParams then
    false
  else if !psCKernelAdmissionExprClosed levelParams declType then
    false
  else
    psCKernelAdmissionTypeIsType env declType

def psCKernelAdmitConstant?
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : Option PsCKernelEnvironment :=
  if !psCKernelAdmissionCommonValid env info then
    none
  else
    let levelParams := psCKernelConstantInfoLevelParams info
    let declType := psCKernelConstantInfoType info
    match info with
    | PsCKernelConstantInfo.axiomInfo _ =>
        psCKernelEnvironmentAdd? env info
    | PsCKernelConstantInfo.defnInfo value =>
        if psCKernelAdmissionExprClosed levelParams value.value then
          if psCKernelAdmissionValueMatches env value.value declType then
            psCKernelEnvironmentAdd? env info
          else
            none
        else
          none
    | PsCKernelConstantInfo.thmInfo value =>
        if psCKernelAdmissionTypeIsProp env declType then
          if psCKernelAdmissionExprClosed levelParams value.value then
            if psCKernelAdmissionValueMatches env value.value declType then
              psCKernelEnvironmentAdd? env info
            else
              none
          else
            none
        else
          none
    | PsCKernelConstantInfo.opaqueInfo value =>
        if psCKernelAdmissionExprClosed levelParams value.value then
          if psCKernelAdmissionValueMatches env value.value declType then
            psCKernelEnvironmentAdd? env info
          else
            none
        else
          none
    | _ => none
