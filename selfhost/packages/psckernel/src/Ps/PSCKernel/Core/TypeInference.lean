import Ps.PSCKernel.Core.TypeInferenceBasic
import Ps.PSCKernel.Core.ExprAbstraction

def psCKernelTypeInferenceFreshBaseName : PsCKernelName :=
  psCKernelNameFromDotted "_kernel_fresh"

def psCKernelTypeInferenceFreshCandidate
    (seed : Nat) : PsCKernelFVarId := {
  name := psCKernelNameAppendIndexAfter psCKernelTypeInferenceFreshBaseName seed
}

def psCKernelTypeInferenceFreshFVarIdSearch
    (lctx : PsCKernelLocalContext)
    (seed : Nat)
    (fuel : Nat) : PsCKernelFVarId :=
  let candidate := psCKernelTypeInferenceFreshCandidate seed
  match fuel with
  | 0 => candidate
  | Nat.succ rest =>
      if psCKernelLocalContextContains lctx candidate then
        psCKernelTypeInferenceFreshFVarIdSearch lctx (Nat.add seed 1) rest
      else
        candidate

def psCKernelTypeInferenceFreshFVarId
    (lctx : PsCKernelLocalContext) : PsCKernelFVarId :=
  psCKernelTypeInferenceFreshFVarIdSearch
    lctx
    0
    (Nat.add (psCKernelLocalContextNumIndices lctx) 1)

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

def psCKernelTypeInferenceApplyProjectionParams
    (env : PsCKernelEnvironment)
    (lctx : PsCKernelLocalContext)
    (cursor : PsCKernelExpr)
    (args : List PsCKernelExpr)
    (remaining : Nat) : Option PsCKernelExpr :=
  match remaining, args with
  | 0, _ => some cursor
  | Nat.succ _, [] => none
  | Nat.succ restCount, arg :: restArgs =>
      match psCKernelExprWhnfBasic env lctx cursor with
      | PsCKernelExpr.forallE _ _ body _ =>
          psCKernelTypeInferenceApplyProjectionParams
            env
            lctx
            (psCKernelExprInstantiate1 body arg)
            restArgs
            restCount
      | _ => none

def psCKernelTypeInferenceProjectionField
    (env : PsCKernelEnvironment)
    (lctx : PsCKernelLocalContext)
    (typeName : PsCKernelName)
    (target : PsCKernelExpr)
    (requestedIndex : Nat)
    (fieldIndex : Nat)
    (cursor : PsCKernelExpr) : Option PsCKernelExpr :=
  match psCKernelExprWhnfBasic env lctx cursor, requestedIndex with
  | PsCKernelExpr.forallE _ domain _ _, 0 => some domain
  | PsCKernelExpr.forallE _ _ body _, Nat.succ rest =>
      psCKernelTypeInferenceProjectionField
        env
        lctx
        typeName
        target
        rest
        (Nat.add fieldIndex 1)
        (psCKernelExprInstantiate1
          body
          (PsCKernelExpr.proj typeName fieldIndex target))
  | _, _ => none

def psCKernelTypeInferenceProjectionRaw?
    (env : PsCKernelEnvironment)
    (lctx : PsCKernelLocalContext)
    (targetType : PsCKernelExpr)
    (typeName : PsCKernelName)
    (index : Nat)
    (target : PsCKernelExpr) : Option PsCKernelExpr :=
  let reducedTargetType := psCKernelExprWhnfBasic env lctx targetType
  let head := psCKernelExprGetAppFn reducedTargetType
  let args := psCKernelExprGetAppArgs reducedTargetType
  match head with
  | PsCKernelExpr.constE actualName levels =>
      if psCKernelNameEq actualName typeName then
        match psCKernelEnvironmentFind? env typeName with
        | some info =>
            match info with
            | PsCKernelConstantInfo.inductInfo inductiveInfo =>
                if Nat.beq args.length
                    (Nat.add inductiveInfo.numParams inductiveInfo.numIndices) then
                  match inductiveInfo.ctors with
                  | [ctorName] =>
                      match psCKernelEnvironmentFind? env ctorName with
                      | some ctorInfo =>
                          match ctorInfo with
                          | PsCKernelConstantInfo.ctorInfo constructorInfo =>
                              if Nat.beq constructorInfo.numParams inductiveInfo.numParams then
                                if Nat.blt index constructorInfo.numFields then
                                  if Nat.beq levels.length constructorInfo.base.levelParams.length then
                                    let instantiatedCtorType :=
                                      psCKernelInstantiateExprLevels
                                        constructorInfo.base.declType
                                        constructorInfo.base.levelParams
                                        levels
                                    match
                                        psCKernelTypeInferenceApplyProjectionParams
                                          env
                                          lctx
                                          instantiatedCtorType
                                          args
                                          inductiveInfo.numParams with
                                    | none => none
                                    | some fieldCursor =>
                                        psCKernelTypeInferenceProjectionField
                                          env
                                          lctx
                                          typeName
                                          target
                                          index
                                          0
                                          fieldCursor
                                  else
                                    none
                                else
                                  none
                              else
                                none
                          | _ => none
                      | none => none
                  | _ => none
                else
                  none
            | _ => none
        | none => none
      else
        none
  | _ => none

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
  | PsCKernelExpr.proj typeName index target =>
      match psCKernelInfer? env lctx target with
      | none => none
      | some targetType =>
          match
              psCKernelTypeInferenceProjectionRaw?
                env lctx targetType typeName index target with
          | none => none
          | some fieldType =>
              match psCKernelInfer? env lctx targetType with
              | none => none
              | some targetTypeType =>
                  match psCKernelExprWhnfBasic env lctx targetTypeType with
                  | PsCKernelExpr.sortE targetLevel =>
                      if psCKernelLevelEquivalent targetLevel psCKernelLevelZero then
                        match psCKernelInfer? env lctx fieldType with
                        | none => none
                        | some fieldTypeType =>
                            match psCKernelExprWhnfBasic env lctx fieldTypeType with
                            | PsCKernelExpr.sortE fieldLevel =>
                                if psCKernelLevelEquivalent fieldLevel psCKernelLevelZero then
                                  some fieldType
                                else
                                  none
                            | _ => none
                      else
                        some fieldType
                  | _ => none
