import Ps.PSCKernel.Core.TypeInference
import Ps.PSCKernel.Core.DefEqBasic

def psCKernelCheckedInferenceIsSort
    (env : PsCKernelEnvironment)
    (lctx : PsCKernelLocalContext)
    (expr : PsCKernelExpr) : Bool :=
  match psCKernelExprWhnfBasic env lctx expr with
  | PsCKernelExpr.sortE _ => true
  | _ => false

partial def psCKernelCheckBasic?
    (env : PsCKernelEnvironment)
    (lctx : PsCKernelLocalContext)
    (expr : PsCKernelExpr) : Option PsCKernelExpr :=
  match expr with
  | PsCKernelExpr.bvar _ => none
  | PsCKernelExpr.mvar _ => none
  | PsCKernelExpr.fvar _ => psCKernelInfer? env lctx expr
  | PsCKernelExpr.sortE _ => psCKernelInfer? env lctx expr
  | PsCKernelExpr.constE _ _ => psCKernelInfer? env lctx expr
  | PsCKernelExpr.lit _ => psCKernelInfer? env lctx expr
  | PsCKernelExpr.app fn arg =>
      match psCKernelCheckBasic? env lctx fn with
      | none => none
      | some fnType =>
          match psCKernelExprWhnfBasic env lctx fnType with
          | PsCKernelExpr.forallE _ domain body _ =>
              match psCKernelCheckBasic? env lctx arg with
              | none => none
              | some argType =>
                  if psCKernelIsDefEqBasic env lctx argType domain then
                    some (psCKernelExprInstantiate1 body arg)
                  else
                    none
          | _ => none
  | PsCKernelExpr.lam name domain body binderInfo =>
      match psCKernelCheckBasic? env lctx domain with
      | none => none
      | some domainType =>
          if psCKernelCheckedInferenceIsSort env lctx domainType then
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
            match psCKernelCheckBasic? env bodyContext openedBody with
            | none => none
            | some bodyType =>
                some
                  (PsCKernelExpr.forallE
                    name
                    domain
                    (psCKernelExprAbstractFVar bodyType fvarId)
                    binderInfo)
          else
            none
  | PsCKernelExpr.forallE name domain body binderInfo =>
      match psCKernelCheckBasic? env lctx domain with
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
              match psCKernelCheckBasic? env bodyContext openedBody with
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
      match psCKernelCheckBasic? env lctx domain with
      | none => none
      | some domainType =>
          if psCKernelCheckedInferenceIsSort env lctx domainType then
            match psCKernelCheckBasic? env lctx value with
            | none => none
            | some valueType =>
                if psCKernelIsDefEqBasic env lctx valueType domain then
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
                  match psCKernelCheckBasic? env bodyContext openedBody with
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
                else
                  none
          else
            none
  | PsCKernelExpr.proj _ _ target =>
      match psCKernelCheckBasic? env lctx target with
      | none => none
      | some _ => psCKernelInfer? env lctx expr
