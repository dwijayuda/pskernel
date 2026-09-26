import Ps.PSCKernel.Core.ReductionBasic
import Ps.PSCKernel.Core.ExprLevelInstantiation
import Ps.PSCKernel.Core.ExprInstantiation

def psCKernelBuiltinNatName : PsCKernelName :=
  psCKernelNameFromDotted "Nat"

def psCKernelBuiltinStringName : PsCKernelName :=
  psCKernelNameFromDotted "String"

partial def psCKernelInferBasic?
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
      match psCKernelInferBasic? env lctx fn with
      | none => none
      | some fnType =>
          match psCKernelExprWhnfBasic env lctx fnType with
          | PsCKernelExpr.forallE _ _ body _ =>
              some (psCKernelExprInstantiate1 body arg)
          | _ => none
  | PsCKernelExpr.letE _ _ value body _ =>
      psCKernelInferBasic?
        env
        lctx
        (psCKernelExprInstantiate1 body value)
  | PsCKernelExpr.lit literal =>
      match literal with
      | PsCKernelLiteral.natVal _ =>
          some (PsCKernelExpr.constE psCKernelBuiltinNatName [])
      | PsCKernelLiteral.strVal _ =>
          some (PsCKernelExpr.constE psCKernelBuiltinStringName [])
  | PsCKernelExpr.lam _ _ _ _ => none
  | PsCKernelExpr.forallE _ _ _ _ => none
  | PsCKernelExpr.proj _ _ _ => none
