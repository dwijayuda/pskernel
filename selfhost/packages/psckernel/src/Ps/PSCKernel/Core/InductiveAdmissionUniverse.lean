import Ps.PSCKernel.Core.InductiveAdmission

-- Universe validation is layered on top of the closed basic ordinary-inductive
-- validator. The basic layer still describes its narrower contract; admission
-- code should move upward through these layers as more Lean invariants land.

def psCKernelInductiveUniverseExprLevel?
    (env : PsCKernelEnvironment)
    (lctx : PsCKernelLocalContext)
    (expr : PsCKernelExpr) : Option PsCKernelLevel :=
  match psCKernelCheckBasic? env lctx expr with
  | none => none
  | some exprType =>
      match psCKernelExprWhnfBasic env lctx exprType with
      | PsCKernelExpr.sortE level => some level
      | _ => none


def psCKernelInductiveUniverseFieldAllowed
    (resultLevel fieldLevel : PsCKernelLevel) : Bool :=
  if psCKernelLevelNormalizesToZero resultLevel then
    true
  else
    psCKernelLevelLe fieldLevel resultLevel


partial def psCKernelInductiveUniverseCheckCtorFields?
    (env : PsCKernelEnvironment)
    (resultLevel : PsCKernelLevel)
    (remainingParams : List PsCKernelInductiveOpenParam)
    (cursor : PsCKernelExpr)
    (lctx : PsCKernelLocalContext) : Option Unit :=
  match remainingParams with
  | param :: rest =>
      let reduced := psCKernelExprWhnfBasic env lctx cursor
      match reduced with
      | PsCKernelExpr.forallE _ _ body _ =>
          let nextContext :=
            psCKernelLocalContextMkLocalDecl
              lctx
              param.fvarId
              param.userName
              param.type
              param.binderInfo
              PsCKernelLocalDeclKind.default
          let openedBody :=
            psCKernelExprInstantiate1
              body
              (PsCKernelExpr.fvar param.fvarId)
          psCKernelInductiveUniverseCheckCtorFields?
            env
            resultLevel
            rest
            openedBody
            nextContext
      | _ => none
  | [] =>
      let reduced := psCKernelExprWhnfBasic env lctx cursor
      match reduced with
      | PsCKernelExpr.forallE name domain body binderInfo =>
          match psCKernelInductiveUniverseExprLevel? env lctx domain with
          | none => none
          | some fieldLevel =>
              if
                  !psCKernelInductiveUniverseFieldAllowed
                    resultLevel
                    fieldLevel then
                none
              else
                let fvarId := psCKernelTypeInferenceFreshFVarId lctx
                let nextContext :=
                  psCKernelLocalContextMkLocalDecl
                    lctx
                    fvarId
                    name
                    domain
                    binderInfo
                    PsCKernelLocalDeclKind.default
                let openedBody :=
                  psCKernelExprInstantiate1 body (PsCKernelExpr.fvar fvarId)
                psCKernelInductiveUniverseCheckCtorFields?
                  env
                  resultLevel
                  []
                  openedBody
                  nextContext
      | _ => some ()


partial def psCKernelInductiveUniverseCheckCtors?
    (env : PsCKernelEnvironment)
    (resultLevel : PsCKernelLevel)
    (params : List PsCKernelInductiveOpenParam)
    (ctors : List PsCKernelConstructorDecl) : Option Unit :=
  match ctors with
  | [] => some ()
  | ctor :: rest =>
      match
          psCKernelInductiveUniverseCheckCtorFields?
            env
            resultLevel
            params
            ctor.type
            psCKernelLocalContextEmpty with
      | none => none
      | some _ =>
          psCKernelInductiveUniverseCheckCtors?
            env
            resultLevel
            params
            rest


def psCKernelValidateOrdinaryInductiveUniverse?
    (env : PsCKernelEnvironment)
    (decl : PsCKernelInductiveDecl) :
    Option PsCKernelOrdinaryInductiveBasicValidation :=
  match psCKernelValidateOrdinaryInductiveBasic? env decl with
  | none => none
  | some basicValidation =>
      match decl.types with
      | [typeDecl] =>
          match psCKernelInductiveOpenHeader? env typeDecl.type decl.numParams with
          | none => none
          | some header =>
              let typeInfo :=
                psCKernelInductiveTemporaryTypeInfo
                  decl
                  typeDecl
                  header.numIndices
              match psCKernelEnvironmentTryAdd env typeInfo with
              | none => none
              | some workEnv =>
                  match
                      psCKernelInductiveUniverseCheckCtors?
                        workEnv
                        header.resultLevel
                        header.params
                        typeDecl.ctors with
                  | none => none
                  | some _ => some basicValidation
      | _ => none
