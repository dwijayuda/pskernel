import Ps.KernelCore
import PSC1Kernel.Inductive
import PSC1Kernel.TypeChecker

def psKcEqRecAnon : PsKernelCoreName := PsKernelCoreName.anonymous

def psKcEqRecEqName : PsKernelCoreName :=
  PsKernelCoreName.str psKcEqRecAnon "Eq"

def psKcEqRecReflName : PsKernelCoreName :=
  PsKernelCoreName.str psKcEqRecEqName "refl"

def psKcEqRecName : PsKernelCoreName :=
  PsKernelCoreName.str psKcEqRecEqName "rec"

def psKcEqRecU : PsKernelCoreName :=
  PsKernelCoreName.str psKcEqRecAnon "u"

def psKcEqRecV : PsKernelCoreName :=
  PsKernelCoreName.str psKcEqRecAnon "v"

def psKcEqRecEqLevels : PsKernelCoreList PsKernelCoreLevel :=
  PsKernelCoreList.cons
    (PsKernelCoreLevel.param psKcEqRecU)
    PsKernelCoreList.nil

def psKcEqRecEqLevelParams : PsKernelCoreList PsKernelCoreName :=
  PsKernelCoreList.cons psKcEqRecU PsKernelCoreList.nil

def psKcEqRecRecLevelParams : PsKernelCoreList PsKernelCoreName :=
  PsKernelCoreList.cons psKcEqRecV
    (PsKernelCoreList.cons psKcEqRecU PsKernelCoreList.nil)

def psKcEqRecEqType : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psKcEqRecAnon
    (PsKernelCoreExpr.sort (PsKernelCoreLevel.param psKcEqRecU))
    (PsKernelCoreExpr.forallE psKcEqRecAnon
      (PsKernelCoreExpr.bvar 0)
      (PsKernelCoreExpr.forallE psKcEqRecAnon
        (PsKernelCoreExpr.bvar 1)
        (PsKernelCoreExpr.sort PsKernelCoreLevel.zero)
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.implicit

def psKcEqRecReflResult : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app
      (PsKernelCoreExpr.app
        (PsKernelCoreExpr.const psKcEqRecEqName psKcEqRecEqLevels)
        (PsKernelCoreExpr.bvar 1))
      (PsKernelCoreExpr.bvar 0))
    (PsKernelCoreExpr.bvar 0)

def psKcEqRecReflType : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psKcEqRecAnon
    (PsKernelCoreExpr.sort (PsKernelCoreLevel.param psKcEqRecU))
    (PsKernelCoreExpr.forallE psKcEqRecAnon
      (PsKernelCoreExpr.bvar 0)
      psKcEqRecReflResult
      PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.implicit

def psKcEqRecEqInfo : PsKernelCoreInductiveInfo := {
  base := {
    name := psKcEqRecEqName
    levelParams := psKcEqRecEqLevelParams
    type := psKcEqRecEqType
  }
  numParams := 1
  numIndices := 2
  all := PsKernelCoreList.cons psKcEqRecEqName PsKernelCoreList.nil
  ctors := PsKernelCoreList.cons psKcEqRecReflName PsKernelCoreList.nil
  numNested := 0
  isRec := false
  isReflexive := false
  isUnsafe := false
}

def psKcEqRecReflInfo : PsKernelCoreConstructorInfo := {
  base := {
    name := psKcEqRecReflName
    levelParams := psKcEqRecEqLevelParams
    type := psKcEqRecReflType
  }
  induct := psKcEqRecEqName
  cidx := 0
  numParams := 1
  numFields := 1
  isUnsafe := false
}

def psKcEqRecAlphaI : PsKernelCoreName :=
  PsKernelCoreName.str psKcEqRecAnon "_phase10EqAlpha"

def psKcEqRecLeftI : PsKernelCoreName :=
  PsKernelCoreName.str psKcEqRecAnon "_phase10EqLeft"

def psKcEqRecRightI : PsKernelCoreName :=
  PsKernelCoreName.str psKcEqRecAnon "_phase10EqRight"

def psKcEqRecMotiveI : PsKernelCoreName :=
  PsKernelCoreName.str psKcEqRecAnon "_phase10EqMotive"

def psKcEqRecMinorI : PsKernelCoreName :=
  PsKernelCoreName.str psKcEqRecAnon "_phase10EqMinor"

def psKcEqRecMajorI : PsKernelCoreName :=
  PsKernelCoreName.str psKcEqRecAnon "_phase10EqMajor"

def psKcEqRecFieldI : PsKernelCoreName :=
  PsKernelCoreName.str psKcEqRecAnon "_phase10EqField"

def psKcEqRecAlpha : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psKcEqRecAlphaI

def psKcEqRecLeft : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psKcEqRecLeftI

def psKcEqRecRight : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psKcEqRecRightI

def psKcEqRecMotive : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psKcEqRecMotiveI

def psKcEqRecMinor : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psKcEqRecMinorI

def psKcEqRecMajor : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psKcEqRecMajorI

def psKcEqRecField : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psKcEqRecFieldI

def psKcEqRecApp2
    (fn : PsKernelCoreExpr)
    (a : PsKernelCoreExpr)
    (b : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.app (PsKernelCoreExpr.app fn a) b

def psKcEqRecApp3
    (fn : PsKernelCoreExpr)
    (a : PsKernelCoreExpr)
    (b : PsKernelCoreExpr)
    (c : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.app (psKcEqRecApp2 fn a b) c

def psKcEqRecCloseForall
    (internalName : PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (body : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psKcEqRecAnon type
    (psKernelCoreExprAbstractFVar body internalName)
    PsKernelCoreBinderInfo.default

def psKcEqRecCloseLam
    (internalName : PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (body : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.lam psKcEqRecAnon type
    (psKernelCoreExprAbstractFVar body internalName)
    PsKernelCoreBinderInfo.default

def psKcEqRecOpenEq
    (left : PsKernelCoreExpr)
    (right : PsKernelCoreExpr) : PsKernelCoreExpr :=
  psKcEqRecApp3
    (PsKernelCoreExpr.const psKcEqRecEqName psKcEqRecEqLevels)
    psKcEqRecAlpha left right

def psKcEqRecOpenRefl (value : PsKernelCoreExpr) : PsKernelCoreExpr :=
  psKcEqRecApp2
    (PsKernelCoreExpr.const psKcEqRecReflName psKcEqRecEqLevels)
    psKcEqRecAlpha value

def psKcEqRecMotiveType : PsKernelCoreExpr :=
  psKcEqRecCloseForall psKcEqRecLeftI psKcEqRecAlpha
    (psKcEqRecCloseForall psKcEqRecRightI psKcEqRecAlpha
      (psKcEqRecCloseForall psKcEqRecMajorI
        (psKcEqRecOpenEq psKcEqRecLeft psKcEqRecRight)
        (PsKernelCoreExpr.sort (PsKernelCoreLevel.param psKcEqRecV))))

def psKcEqRecMinorType : PsKernelCoreExpr :=
  psKcEqRecCloseForall psKcEqRecFieldI psKcEqRecAlpha
    (psKcEqRecApp3 psKcEqRecMotive psKcEqRecField psKcEqRecField
      (psKcEqRecOpenRefl psKcEqRecField))

def psKcEqRecType : PsKernelCoreExpr :=
  psKcEqRecCloseForall psKcEqRecAlphaI
    (PsKernelCoreExpr.sort (PsKernelCoreLevel.param psKcEqRecU))
    (psKcEqRecCloseForall psKcEqRecMotiveI psKcEqRecMotiveType
      (psKcEqRecCloseForall psKcEqRecMinorI psKcEqRecMinorType
        (psKcEqRecCloseForall psKcEqRecLeftI psKcEqRecAlpha
          (psKcEqRecCloseForall psKcEqRecRightI psKcEqRecAlpha
            (psKcEqRecCloseForall psKcEqRecMajorI
              (psKcEqRecOpenEq psKcEqRecLeft psKcEqRecRight)
              (psKcEqRecApp3 psKcEqRecMotive
                psKcEqRecLeft psKcEqRecRight psKcEqRecMajor))))))

def psKcEqRecRuleRhs : PsKernelCoreExpr :=
  psKcEqRecCloseLam psKcEqRecAlphaI
    (PsKernelCoreExpr.sort (PsKernelCoreLevel.param psKcEqRecU))
    (psKcEqRecCloseLam psKcEqRecMotiveI psKcEqRecMotiveType
      (psKcEqRecCloseLam psKcEqRecMinorI psKcEqRecMinorType
        (psKcEqRecCloseLam psKcEqRecFieldI psKcEqRecAlpha
          (PsKernelCoreExpr.app psKcEqRecMinor psKcEqRecField))))

def psKcEqRecInfo : PsKernelCoreRecursorInfo := {
  base := {
    name := psKcEqRecName
    levelParams := psKcEqRecRecLevelParams
    type := psKcEqRecType
  }
  all := PsKernelCoreList.cons psKcEqRecEqName PsKernelCoreList.nil
  numParams := 1
  numIndices := 2
  numMotives := 1
  numMinors := 1
  rules := PsKernelCoreList.cons
    { ctor := psKcEqRecReflName, nFields := 1, rhs := psKcEqRecRuleRhs }
    PsKernelCoreList.nil
  k := false
  isUnsafe := false
}

def psKcEqRecAlphaArgName : PsKernelCoreName :=
  PsKernelCoreName.str psKcEqRecAnon "phase10EqAlphaArg"

def psKcEqRecValueArgName : PsKernelCoreName :=
  PsKernelCoreName.str psKcEqRecAnon "phase10EqValueArg"

def psKcEqRecMotiveArgName : PsKernelCoreName :=
  PsKernelCoreName.str psKcEqRecAnon "phase10EqMotiveArg"

def psKcEqRecMinorArgName : PsKernelCoreName :=
  PsKernelCoreName.str psKcEqRecAnon "phase10EqMinorArg"

def psKcEqRecProofArgName : PsKernelCoreName :=
  PsKernelCoreName.str psKcEqRecAnon "phase10EqProofArg"

def psKcEqRecAlphaArg : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psKcEqRecAlphaArgName PsKernelCoreList.nil

def psKcEqRecValueArg : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psKcEqRecValueArgName PsKernelCoreList.nil

def psKcEqRecMotiveArg : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psKcEqRecMotiveArgName PsKernelCoreList.nil

def psKcEqRecMinorArg : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psKcEqRecMinorArgName PsKernelCoreList.nil

def psKcEqRecProofArg : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psKcEqRecProofArgName PsKernelCoreList.nil

def psKcEqRecConcreteU : PsKernelCoreLevel :=
  PsKernelCoreLevel.succ PsKernelCoreLevel.zero

def psKcEqRecConcreteV : PsKernelCoreLevel :=
  PsKernelCoreLevel.succ PsKernelCoreLevel.zero

def psKcEqRecConcreteEqLevels : PsKernelCoreList PsKernelCoreLevel :=
  PsKernelCoreList.cons psKcEqRecConcreteU PsKernelCoreList.nil

def psKcEqRecConcreteRecLevels : PsKernelCoreList PsKernelCoreLevel :=
  PsKernelCoreList.cons psKcEqRecConcreteV
    (PsKernelCoreList.cons psKcEqRecConcreteU PsKernelCoreList.nil)

def psKcEqRecApplyList
    (fn : PsKernelCoreExpr)
    (args : PsKernelCoreList PsKernelCoreExpr) : PsKernelCoreExpr :=
  match args with
  | PsKernelCoreList.nil => fn
  | PsKernelCoreList.cons arg rest =>
      psKcEqRecApplyList (PsKernelCoreExpr.app fn arg) rest

def psKcEqRecMajorRefl : PsKernelCoreExpr :=
  psKcEqRecApplyList
    (PsKernelCoreExpr.const psKcEqRecReflName psKcEqRecConcreteEqLevels)
    (PsKernelCoreList.cons psKcEqRecAlphaArg
      (PsKernelCoreList.cons psKcEqRecValueArg PsKernelCoreList.nil))

def psKcEqRecApplicationWith (major : PsKernelCoreExpr) : PsKernelCoreExpr :=
  psKcEqRecApplyList
    (PsKernelCoreExpr.const psKcEqRecName psKcEqRecConcreteRecLevels)
    (PsKernelCoreList.cons psKcEqRecAlphaArg
      (PsKernelCoreList.cons psKcEqRecMotiveArg
        (PsKernelCoreList.cons psKcEqRecMinorArg
          (PsKernelCoreList.cons psKcEqRecValueArg
            (PsKernelCoreList.cons psKcEqRecValueArg
              (PsKernelCoreList.cons major PsKernelCoreList.nil))))))

def psKcEqRecExpected : PsKernelCoreExpr :=
  PsKernelCoreExpr.app psKcEqRecMinorArg psKcEqRecValueArg

def psKcEqRecAdmittedEnv? : PsKernelCoreOption PsKernelCoreEnvironment :=
  let ctors :=
    PsKernelCoreList.cons psKcEqRecReflInfo PsKernelCoreList.nil;
  match psKernelCoreAddNonRecursiveInductive
      256 psKernelCoreEnvironmentEmpty psKcEqRecEqInfo ctors with
  | PsKernelCoreResult.error _ => PsKernelCoreOption.none
  | PsKernelCoreResult.ok familyEnv =>
      match psKernelCoreAddRecursorWithResources
          256 psKernelCoreResourceConfigDefault familyEnv psKcEqRecInfo with
      | PsKernelCoreResult.error _ => PsKernelCoreOption.none
      | PsKernelCoreResult.ok env => PsKernelCoreOption.some env

def psKcEqRecDirectIota : Bool :=
  match psKcEqRecAdmittedEnv? with
  | PsKernelCoreOption.none => false
  | PsKernelCoreOption.some env =>
      match psKernelCoreWhnf 128 env psKernelCoreLocalContextEmpty
          (psKcEqRecApplicationWith psKcEqRecMajorRefl) with
      | PsKernelCoreResult.error _ => false
      | PsKernelCoreResult.ok value =>
          psKernelCoreExprEq value psKcEqRecExpected

def psKcEqRecNonConstructorResidual : Bool :=
  match psKcEqRecAdmittedEnv? with
  | PsKernelCoreOption.none => false
  | PsKernelCoreOption.some env =>
      let expr := psKcEqRecApplicationWith psKcEqRecProofArg;
      match psKernelCoreWhnf 128 env psKernelCoreLocalContextEmpty expr with
      | PsKernelCoreResult.error _ => false
      | PsKernelCoreResult.ok value => psKernelCoreExprEq value expr

def psRefEqRecDirectIota : Bool :=
  let eqName : PSC1Kernel.Name := .str .anonymous "Eq"
  let reflName : PSC1Kernel.Name := .str eqName "refl"
  let recName : PSC1Kernel.Name := .str eqName "rec"
  let u : PSC1Kernel.Name := .str .anonymous "u"
  let eqLevels : List PSC1Kernel.Level := [.param u]
  let eqType : PSC1Kernel.Expr :=
    .forallE .anonymous (.sort (.param u))
      (.forallE .anonymous (.bvar 0)
        (.forallE .anonymous (.bvar 1) (.sort .zero) .default)
        .default)
      .implicit
  let reflResult : PSC1Kernel.Expr :=
    PSC1Kernel.applyArgs (.const eqName eqLevels)
      [.bvar 1, .bvar 0, .bvar 0]
  let reflType : PSC1Kernel.Expr :=
    .forallE .anonymous (.sort (.param u))
      (.forallE .anonymous (.bvar 0) reflResult .default)
      .implicit
  let decl : PSC1Kernel.Kernel.SimpleInductiveDecl := {
    levelParams := [u]
    name := eqName
    type := eqType
    ctors := [{ name := reflName, type := reflType }]
    isUnsafe := false
    numParams := 1
  }
  match PSC1Kernel.Kernel.addSimpleInductive PSC1Kernel.Environment.empty decl with
  | .error _ => false
  | .ok env =>
      let alphaName : PSC1Kernel.Name := .str .anonymous "phase10EqAlphaArg"
      let valueName : PSC1Kernel.Name := .str .anonymous "phase10EqValueArg"
      let motiveName : PSC1Kernel.Name := .str .anonymous "phase10EqMotiveArg"
      let minorName : PSC1Kernel.Name := .str .anonymous "phase10EqMinorArg"
      let alpha : PSC1Kernel.Expr := .const alphaName []
      let value : PSC1Kernel.Expr := .const valueName []
      let motive : PSC1Kernel.Expr := .const motiveName []
      let minor : PSC1Kernel.Expr := .const minorName []
      let level : PSC1Kernel.Level := .succ .zero
      let major :=
        PSC1Kernel.applyArgs (.const reflName [level]) [alpha, value]
      let expr :=
        PSC1Kernel.applyArgs (.const recName [level, level])
          [alpha, motive, minor, value, value, major]
      let expected := PSC1Kernel.Expr.app minor value
      match PSC1Kernel.whnf (PSC1Kernel.CheckerContext.empty env) expr with
      | .error _ => false
      | .ok result => PSC1Kernel.Expr.eq result expected

def psKernelCoreEqRecursorCompatibility : Bool :=
  psKcEqRecDirectIota &&
  psRefEqRecDirectIota &&
  psKcEqRecNonConstructorResidual

def main : IO Unit := do
  if psKernelCoreEqRecursorCompatibility then
    IO.println "PSC2_KERNEL_CORE_EQ_RECURSOR_COMPATIBILITY: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_EQ_RECURSOR_COMPATIBILITY: FAIL")
