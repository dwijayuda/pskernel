import Ps.KernelCore
import PSC1Kernel.Quot

def psKcQuotToRefName : PsKernelCoreName → PSC1Kernel.Name
  | PsKernelCoreName.anonymous => PSC1Kernel.Name.anonymous
  | PsKernelCoreName.str parent value =>
      PSC1Kernel.Name.str (psKcQuotToRefName parent) value
  | PsKernelCoreName.num parent value =>
      PSC1Kernel.Name.num (psKcQuotToRefName parent) value

def psKcQuotToRefLevel : PsKernelCoreLevel → PSC1Kernel.Level
  | PsKernelCoreLevel.zero => PSC1Kernel.Level.zero
  | PsKernelCoreLevel.succ level =>
      PSC1Kernel.Level.succ (psKcQuotToRefLevel level)
  | PsKernelCoreLevel.max left right =>
      PSC1Kernel.Level.max
        (psKcQuotToRefLevel left)
        (psKcQuotToRefLevel right)
  | PsKernelCoreLevel.imax left right =>
      PSC1Kernel.Level.imax
        (psKcQuotToRefLevel left)
        (psKcQuotToRefLevel right)
  | PsKernelCoreLevel.param name =>
      PSC1Kernel.Level.param (psKcQuotToRefName name)
  | PsKernelCoreLevel.mvar name =>
      PSC1Kernel.Level.mvar (psKcQuotToRefName name)

def psKcQuotToRefLevels :
    PsKernelCoreList PsKernelCoreLevel → List PSC1Kernel.Level
  | PsKernelCoreList.nil => []
  | PsKernelCoreList.cons head tail =>
      psKcQuotToRefLevel head :: psKcQuotToRefLevels tail

def psKcQuotToRefBinderInfo : PsKernelCoreBinderInfo → PSC1Kernel.BinderInfo
  | PsKernelCoreBinderInfo.default => PSC1Kernel.BinderInfo.default
  | PsKernelCoreBinderInfo.implicit => PSC1Kernel.BinderInfo.implicit
  | PsKernelCoreBinderInfo.strictImplicit => PSC1Kernel.BinderInfo.strictImplicit
  | PsKernelCoreBinderInfo.instImplicit => PSC1Kernel.BinderInfo.instImplicit

def psKcQuotToRefLiteral : PsKernelCoreLiteral → PSC1Kernel.Literal
  | PsKernelCoreLiteral.nat value => PSC1Kernel.Literal.nat value
  | PsKernelCoreLiteral.str value => PSC1Kernel.Literal.str value

partial def psKcQuotToRefExpr : PsKernelCoreExpr → PSC1Kernel.Expr
  | PsKernelCoreExpr.bvar index => PSC1Kernel.Expr.bvar index
  | PsKernelCoreExpr.fvar name =>
      PSC1Kernel.Expr.fvar (psKcQuotToRefName name)
  | PsKernelCoreExpr.mvar name =>
      PSC1Kernel.Expr.mvar (psKcQuotToRefName name)
  | PsKernelCoreExpr.sort level =>
      PSC1Kernel.Expr.sort (psKcQuotToRefLevel level)
  | PsKernelCoreExpr.const name levels =>
      PSC1Kernel.Expr.const
        (psKcQuotToRefName name)
        (psKcQuotToRefLevels levels)
  | PsKernelCoreExpr.app fn arg =>
      PSC1Kernel.Expr.app
        (psKcQuotToRefExpr fn)
        (psKcQuotToRefExpr arg)
  | PsKernelCoreExpr.lam name type body binderInfo =>
      PSC1Kernel.Expr.lam
        (psKcQuotToRefName name)
        (psKcQuotToRefExpr type)
        (psKcQuotToRefExpr body)
        (psKcQuotToRefBinderInfo binderInfo)
  | PsKernelCoreExpr.forallE name type body binderInfo =>
      PSC1Kernel.Expr.forallE
        (psKcQuotToRefName name)
        (psKcQuotToRefExpr type)
        (psKcQuotToRefExpr body)
        (psKcQuotToRefBinderInfo binderInfo)
  | PsKernelCoreExpr.letE name type value body nondep =>
      PSC1Kernel.Expr.letE
        (psKcQuotToRefName name)
        (psKcQuotToRefExpr type)
        (psKcQuotToRefExpr value)
        (psKcQuotToRefExpr body)
        nondep
  | PsKernelCoreExpr.lit value =>
      PSC1Kernel.Expr.lit (psKcQuotToRefLiteral value)
  | PsKernelCoreExpr.mdata metadata expr =>
      PSC1Kernel.Expr.mdata metadata (psKcQuotToRefExpr expr)
  | PsKernelCoreExpr.proj typeName index expr =>
      PSC1Kernel.Expr.proj
        (psKcQuotToRefName typeName)
        index
        (psKcQuotToRefExpr expr)

def psKcQuotNameParamsMatchRef :
    PsKernelCoreList PsKernelCoreName → List PSC1Kernel.Name → Bool
  | PsKernelCoreList.nil, [] => true
  | PsKernelCoreList.cons kcHead kcTail, refHead :: refTail =>
      PSC1Kernel.Name.eq (psKcQuotToRefName kcHead) refHead &&
        psKcQuotNameParamsMatchRef kcTail refTail
  | _, _ => false

def psKcQuotKindMatchesRef
    (kc : PsKernelCoreQuotKind)
    (ref : PSC1Kernel.QuotKind) : Bool :=
  match kc, ref with
  | PsKernelCoreQuotKind.typeQ, PSC1Kernel.QuotKind.typeQ => true
  | PsKernelCoreQuotKind.ctorQ, PSC1Kernel.QuotKind.ctorQ => true
  | PsKernelCoreQuotKind.liftQ, PSC1Kernel.QuotKind.liftQ => true
  | PsKernelCoreQuotKind.indQ, PSC1Kernel.QuotKind.indQ => true
  | _, _ => false

def psKcQuotAnon : PsKernelCoreName := PsKernelCoreName.anonymous

def psKcQuotEqName : PsKernelCoreName :=
  PsKernelCoreName.str psKcQuotAnon "Eq"

def psKcQuotEqReflName : PsKernelCoreName :=
  PsKernelCoreName.str psKcQuotEqName "refl"

def psKcQuotU : PsKernelCoreName :=
  PsKernelCoreName.str psKcQuotAnon "u"

def psKcQuotEqLevels : PsKernelCoreList PsKernelCoreLevel :=
  PsKernelCoreList.cons
    (PsKernelCoreLevel.param psKcQuotU)
    PsKernelCoreList.nil

def psKcQuotEqLevelParams : PsKernelCoreList PsKernelCoreName :=
  PsKernelCoreList.cons psKcQuotU PsKernelCoreList.nil

def psKcQuotEqType : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psKcQuotAnon
    (PsKernelCoreExpr.sort (PsKernelCoreLevel.param psKcQuotU))
    (PsKernelCoreExpr.forallE psKcQuotAnon
      (PsKernelCoreExpr.bvar 0)
      (PsKernelCoreExpr.forallE psKcQuotAnon
        (PsKernelCoreExpr.bvar 1)
        (PsKernelCoreExpr.sort PsKernelCoreLevel.zero)
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.implicit

def psKcQuotEqReflResult : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app
      (PsKernelCoreExpr.app
        (PsKernelCoreExpr.const psKcQuotEqName psKcQuotEqLevels)
        (PsKernelCoreExpr.bvar 1))
      (PsKernelCoreExpr.bvar 0))
    (PsKernelCoreExpr.bvar 0)

def psKcQuotEqReflType : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psKcQuotAnon
    (PsKernelCoreExpr.sort (PsKernelCoreLevel.param psKcQuotU))
    (PsKernelCoreExpr.forallE psKcQuotAnon
      (PsKernelCoreExpr.bvar 0)
      psKcQuotEqReflResult
      PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.implicit

def psKcQuotEqInfo : PsKernelCoreInductiveInfo := {
  base := {
    name := psKcQuotEqName
    levelParams := psKcQuotEqLevelParams
    type := psKcQuotEqType
  }
  numParams := 1
  numIndices := 2
  all := PsKernelCoreList.cons psKcQuotEqName PsKernelCoreList.nil
  ctors := PsKernelCoreList.cons psKcQuotEqReflName PsKernelCoreList.nil
  numNested := 0
  isRec := false
  isReflexive := false
  isUnsafe := false
}

def psKcQuotEqReflInfo : PsKernelCoreConstructorInfo := {
  base := {
    name := psKcQuotEqReflName
    levelParams := psKcQuotEqLevelParams
    type := psKcQuotEqReflType
  }
  induct := psKcQuotEqName
  cidx := 0
  numParams := 1
  numFields := 1
  isUnsafe := false
}

def psKcQuotKeepName : PsKernelCoreName :=
  PsKernelCoreName.str psKcQuotAnon "QuotKeep"

def psKcQuotKeepInfo : PsKernelCoreConstantInfo :=
  PsKernelCoreConstantInfo.axiomInfo {
    base := {
      name := psKcQuotKeepName
      levelParams := PsKernelCoreList.nil
      type := PsKernelCoreExpr.sort PsKernelCoreLevel.zero
    }
    isUnsafe := false
  }

def psKcQuotBaseEnvironment :
    PsKernelCoreResult String PsKernelCoreEnvironment :=
  let env0 :=
    psKernelCoreEnvironmentAddUnchecked
      psKernelCoreEnvironmentEmpty
      psKcQuotKeepInfo
  let ctors :=
    PsKernelCoreList.cons psKcQuotEqReflInfo PsKernelCoreList.nil
  psKernelCoreAddNonRecursiveInductive
    128 env0 psKcQuotEqInfo ctors

def psRefQuotKeepName : PSC1Kernel.Name :=
  PSC1Kernel.Name.str PSC1Kernel.Name.anonymous "QuotKeep"

def psRefQuotEqEnvironment : PSC1Kernel.Environment :=
  let u : PSC1Kernel.Name := PSC1Kernel.Name.str PSC1Kernel.Name.anonymous "u"
  let eqName := PSC1Kernel.Kernel.kernelEqName
  let reflName : PSC1Kernel.Name := PSC1Kernel.Name.str eqName "refl"
  let env0 := PSC1Kernel.Environment.empty.addUnchecked
    (PSC1Kernel.ConstantInfo.axiomInfo {
      base := {
        name := psRefQuotKeepName
        levelParams := []
        type := PSC1Kernel.Expr.sort PSC1Kernel.Level.zero
      }
      isUnsafe := false
    })
  let env1 := env0.addUnchecked
    (PSC1Kernel.ConstantInfo.inductInfo {
      base := {
        name := eqName
        levelParams := [u]
        type := PSC1Kernel.Kernel.expectedEqType u
      }
      numParams := 1
      numIndices := 2
      all := [eqName]
      ctors := [reflName]
      numNested := 0
      isRec := false
      isReflexive := false
      isUnsafe := false
    })
  env1.addUnchecked
    (PSC1Kernel.ConstantInfo.ctorInfo {
      base := {
        name := reflName
        levelParams := [u]
        type := PSC1Kernel.Kernel.expectedEqReflType u
      }
      induct := eqName
      cidx := 0
      numParams := 1
      numFields := 1
      isUnsafe := false
    })

def psKcQuotInfoMatchesRef
    (kcEnv : PsKernelCoreEnvironment)
    (refEnv : PSC1Kernel.Environment)
    (kcName : PsKernelCoreName)
    (refName : PSC1Kernel.Name) : Bool :=
  match psKernelCoreEnvironmentFind? kcEnv kcName, refEnv.find? refName with
  | PsKernelCoreOption.some (PsKernelCoreConstantInfo.quotInfo kcInfo),
      some (PSC1Kernel.ConstantInfo.quotInfo refInfo) =>
      PSC1Kernel.Name.eq
          (psKcQuotToRefName kcInfo.base.name)
          refInfo.base.name &&
      psKcQuotNameParamsMatchRef
          kcInfo.base.levelParams
          refInfo.base.levelParams &&
      PSC1Kernel.Kernel.quotExprEqv
          (psKcQuotToRefExpr kcInfo.base.type)
          refInfo.base.type &&
      psKcQuotKindMatchesRef kcInfo.kind refInfo.kind
  | _, _ => false

def psKernelCoreQuotAdmissionParity : Bool :=
  match psKcQuotBaseEnvironment with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok kcBase =>
      match PSC1Kernel.Kernel.addQuot psRefQuotEqEnvironment with
      | Except.error _ => false
      | Except.ok refAdmitted =>
          match psKernelCoreAddQuot kcBase with
          | PsKernelCoreResult.error _ => false
          | PsKernelCoreResult.ok kcAdmitted =>
              let kcSizeOk := psKernelCoreEnvironmentSize kcAdmitted == 7
              let refSizeOk := refAdmitted.size == 7
              let kcKeepOk :=
                match psKernelCoreEnvironmentFind? kcAdmitted psKcQuotKeepName with
                | PsKernelCoreOption.some _ => true
                | PsKernelCoreOption.none => false
              let refKeepOk := refAdmitted.contains psRefQuotKeepName
              let quotTypeOk :=
                psKcQuotInfoMatchesRef
                  kcAdmitted refAdmitted
                  psKernelCoreQuotName
                  PSC1Kernel.kernelQuotName
              let quotMkOk :=
                psKcQuotInfoMatchesRef
                  kcAdmitted refAdmitted
                  psKernelCoreQuotMkName
                  PSC1Kernel.kernelQuotMkName
              let quotLiftOk :=
                psKcQuotInfoMatchesRef
                  kcAdmitted refAdmitted
                  psKernelCoreQuotLiftName
                  PSC1Kernel.kernelQuotLiftName
              let quotIndOk :=
                psKcQuotInfoMatchesRef
                  kcAdmitted refAdmitted
                  psKernelCoreQuotIndName
                  PSC1Kernel.kernelQuotIndName
              let secondRef := PSC1Kernel.Kernel.addQuot refAdmitted
              match psKernelCoreAddQuot kcAdmitted, secondRef with
              | PsKernelCoreResult.ok kcAgain, Except.ok refAgain =>
                  kcSizeOk && refSizeOk &&
                  kcAdmitted.quotInitialized && refAdmitted.quotInitialized &&
                  kcKeepOk && refKeepOk &&
                  quotTypeOk && quotMkOk && quotLiftOk && quotIndOk &&
                  (psKernelCoreEnvironmentSize kcAgain == 7) &&
                  (refAgain.size == 7) &&
                  kcAgain.quotInitialized && refAgain.quotInitialized
              | _, _ => false

def main : IO Unit := do
  if psKernelCoreQuotAdmissionParity then
    IO.println "PSC2_KERNEL_CORE_QUOT_ADMISSION_PARITY: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_QUOT_ADMISSION_PARITY: FAIL")
