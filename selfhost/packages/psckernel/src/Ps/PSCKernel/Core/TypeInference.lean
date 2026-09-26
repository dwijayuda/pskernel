import Ps.PSCKernel.Core.TypeInferenceBasic
import Ps.PSCKernel.Core.ExprAbstraction

def psCKernelTypeInferenceFreshBaseName : PsCKernelName :=
  psCKernelNameFromDotted "_kernel_fresh"

partial def psCKernelTypeInferenceFreshFVarIdFrom
    (lctx : PsCKernelLocalContext)
    (seed : Nat) : PsCKernelFVarId :=
  let candidate : PsCKernelFVarId := {
    name := psCKernelNameAppendIndexAfter
      psCKernelTypeInferenceFreshBaseName
      (Nat.add (psCKernelLocalContextNumIndices lctx) seed)
  }
  if psCKernelLocalContextContains lctx candidate then
    psCKernelTypeInferenceFreshFVarIdFrom lctx (Nat.add seed 1)
  else
    candidate

def psCKernelTypeInferenceFreshFVarId
    (lctx : PsCKernelLocalContext) : PsCKernelFVarId :=
  psCKernelTypeInferenceFreshFVarIdFrom lctx 0

def psCKernelExprContainsFVar
    (expr : PsCKernelExpr)
    (target : PsCKernelFVarId) : Bool :=
  match expr with
  | PsCKernelExpr.fvar id => psCKernelFVarIdEq id target
  | PsCKernelExpr.app fn arg =>
      if psCKernelExprContainsFVar fn target then
        true
      else
        psCKernelExprContainsFVar arg target
  | PsCKernelExpr.lam _ domain body _ =>
      if psCKernelExprContainsFVar domain target then
        true
      else
        psCKernelExprContainsFVar body target
  | PsCKernelExpr.forallE _ domain body _ =>
      if psCKernelExprContainsFVar domain target then
        true
      else
        psCKernelExprContainsFVar body target
  | PsCKernelExpr.letE _ domain value body _ =>
      if psCKernelExprContainsFVar domain target then
        true
      else if psCKernelExprContainsFVar value target then
        true
      else
        psCKernelExprContainsFVar body target
  | PsCKernelExpr.proj _ _ value =>
      psCKernelExprContainsFVar value target
  | _ => false

partial def psCKernelInfer?
    (env : PsCKernelEnvironment)
    (lctx : PsCKernelLocalContext)
    (expr : PsCKernelExpr) : Option PsCKernelExpr :=
  match expr with
  | PsCKernelExpr.bvar _ => none
  | PsCKernelExpr.mvar _ => none
  | PsCKernelExpr.fvar fvarId =>
      match psCKernelLocalContextFind? lctx fvarId with
      | none => none
      | some decl => some (psCKernelLocalDeclType decl)
  | PsCKernelExpr.sortE level =>
      some (PsCKernelExpr.sortE (psCKernelLevelSucc level))
  | PsCKernelExpr.constE name levels =>
      match psCKernelEnvironmentFind? env name with
      | none => none
      | some info =>
          let params := psCKernelConstantInfoLevelParams info
          if Nat.beq levels.length params.length then
            some
              (psCKernelInstantiateExprLevels
                (psCKernelConstantInfoType info)
                params
                levels)
          else
            none
  | PsCKernelExpr.app fn arg =>
      match psCKernelInfer? env lctx fn with
      | none => none
      | some fnType =>
          match psCKernelExprWhnfBasic env lctx fnType with
          | PsCKernelExpr.forallE _ _ body _ =>
              some (psCKernelExprInstantiate1 body arg)
          | _ => none
  | PsCKernelExpr.lam name domain body binderInfo =>
      let fvarId := psCKernelTypeInferenceFreshFVarId lctx
      let openedBody :=
        psCKernelExprInstantiate1 body (PsCKernelExpr.fvar fvarId)
      let bodyContext :=
        psCKernelLocalContextMkLocalDecl
          lctx
          fvarId
          name
          domain
          binderInfo
          PsCKernelLocalDeclKind.default
      match psCKernelInfer? env bodyContext openedBody with
      | none => none
      | some bodyType =>
          some
            (PsCKernelExpr.forallE
              name
              domain
              (psCKernelExprAbstractFVar bodyType fvarId)
              binderInfo)
  | PsCKernelExpr.forallE name domain body binderInfo =>
      match psCKernelInfer? env lctx domain with
      | none => none
      | some domainType =>
          match psCKernelExprWhnfBasic env lctx domainType with
          | PsCKernelExpr.sortE domainLevel =>
              let fvarId := psCKernelTypeInferenceFreshFVarId lctx
              let bodyContext :=
                psCKernelLocalContextMkLocalDecl
                  lctx
                  fvarId
                  name
                  domain
                  binderInfo
                  PsCKernelLocalDeclKind.default
              let openedBody :=
                psCKernelExprInstantiate1 body (PsCKernelExpr.fvar fvarId)
              match psCKernelInfer? env bodyContext openedBody with
              | none => none
              | some bodyType =>
                  match psCKernelExprWhnfBasic env bodyContext bodyType with
                  | PsCKernelExpr.sortE bodyLevel =>
                      some
                        (PsCKernelExpr.sortE
                          (psCKernelLevelMkIMax domainLevel bodyLevel))
                  | _ => none
          | _ => none
  | PsCKernelExpr.letE name domain value body nondep =>
      let fvarId := psCKernelTypeInferenceFreshFVarId lctx
      let bodyContext :=
        psCKernelLocalContextMkLetDecl
          lctx
          fvarId
          name
          domain
          value
          nondep
          PsCKernelLocalDeclKind.default
      let openedBody :=
        psCKernelExprInstantiate1 body (PsCKernelExpr.fvar fvarId)
      match psCKernelInfer? env bodyContext openedBody with
      | none => none
      | some bodyType =>
          if psCKernelExprContainsFVar bodyType fvarId then
            some
              (PsCKernelExpr.letE
                name
                domain
                value
                (psCKernelExprAbstractFVar bodyType fvarId)
                nondep)
          else
            some bodyType
  | PsCKernelExpr.lit literal =>
      match literal with
      | PsCKernelLiteral.natVal _ =>
          some (PsCKernelExpr.constE psCKernelBuiltinNatName [])
      | PsCKernelLiteral.strVal _ =>
          some (PsCKernelExpr.constE psCKernelBuiltinStringName [])
  | PsCKernelExpr.proj _ _ _ => none
