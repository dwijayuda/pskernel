import Ps.KernelCore
import PSC1Kernel.Inductive
import PSC1Kernel.TypeChecker

partial def psKcRecRedNameEq
    (left : PsKernelCoreName)
    (right : PsKernelCoreName) : Bool :=
  match left, right with
  | PsKernelCoreName.anonymous, PsKernelCoreName.anonymous => true
  | PsKernelCoreName.str lp ls, PsKernelCoreName.str rp rs =>
      psKcRecRedNameEq lp rp && ls == rs
  | PsKernelCoreName.num lp ln, PsKernelCoreName.num rp rn =>
      psKcRecRedNameEq lp rp && ln == rn
  | _, _ => false

partial def psKcRecRedLevelEq
    (left : PsKernelCoreLevel)
    (right : PsKernelCoreLevel) : Bool :=
  match left, right with
  | PsKernelCoreLevel.zero, PsKernelCoreLevel.zero => true
  | PsKernelCoreLevel.succ l, PsKernelCoreLevel.succ r =>
      psKcRecRedLevelEq l r
  | PsKernelCoreLevel.max la lb, PsKernelCoreLevel.max ra rb =>
      psKcRecRedLevelEq la ra && psKcRecRedLevelEq lb rb
  | PsKernelCoreLevel.imax la lb, PsKernelCoreLevel.imax ra rb =>
      psKcRecRedLevelEq la ra && psKcRecRedLevelEq lb rb
  | PsKernelCoreLevel.param l, PsKernelCoreLevel.param r =>
      psKcRecRedNameEq l r
  | PsKernelCoreLevel.mvar l, PsKernelCoreLevel.mvar r =>
      psKcRecRedNameEq l r
  | _, _ => false

partial def psKcRecRedLevelListEq
    (left : PsKernelCoreList PsKernelCoreLevel)
    (right : PsKernelCoreList PsKernelCoreLevel) : Bool :=
  match left, right with
  | PsKernelCoreList.nil, PsKernelCoreList.nil => true
  | PsKernelCoreList.cons lh lt, PsKernelCoreList.cons rh rt =>
      psKcRecRedLevelEq lh rh && psKcRecRedLevelListEq lt rt
  | _, _ => false

partial def psKcRecRedExprEq
    (left : PsKernelCoreExpr)
    (right : PsKernelCoreExpr) : Bool :=
  match left, right with
  | PsKernelCoreExpr.bvar l, PsKernelCoreExpr.bvar r => l == r
  | PsKernelCoreExpr.fvar l, PsKernelCoreExpr.fvar r => psKcRecRedNameEq l r
  | PsKernelCoreExpr.mvar l, PsKernelCoreExpr.mvar r => psKcRecRedNameEq l r
  | PsKernelCoreExpr.sort l, PsKernelCoreExpr.sort r => psKcRecRedLevelEq l r
  | PsKernelCoreExpr.const ln ll, PsKernelCoreExpr.const rn rl =>
      psKcRecRedNameEq ln rn && psKcRecRedLevelListEq ll rl
  | PsKernelCoreExpr.app lf la, PsKernelCoreExpr.app rf ra =>
      psKcRecRedExprEq lf rf && psKcRecRedExprEq la ra
  | PsKernelCoreExpr.lam ln lt lb li, PsKernelCoreExpr.lam rn rt rb ri =>
      psKcRecRedNameEq ln rn && psKcRecRedExprEq lt rt &&
      psKcRecRedExprEq lb rb &&
      match li, ri with
      | PsKernelCoreBinderInfo.default, PsKernelCoreBinderInfo.default => true
      | PsKernelCoreBinderInfo.implicit, PsKernelCoreBinderInfo.implicit => true
      | PsKernelCoreBinderInfo.strictImplicit, PsKernelCoreBinderInfo.strictImplicit => true
      | PsKernelCoreBinderInfo.instImplicit, PsKernelCoreBinderInfo.instImplicit => true
      | _, _ => false
  | PsKernelCoreExpr.forallE ln lt lb li, PsKernelCoreExpr.forallE rn rt rb ri =>
      psKcRecRedNameEq ln rn && psKcRecRedExprEq lt rt &&
      psKcRecRedExprEq lb rb &&
      match li, ri with
      | PsKernelCoreBinderInfo.default, PsKernelCoreBinderInfo.default => true
      | PsKernelCoreBinderInfo.implicit, PsKernelCoreBinderInfo.implicit => true
      | PsKernelCoreBinderInfo.strictImplicit, PsKernelCoreBinderInfo.strictImplicit => true
      | PsKernelCoreBinderInfo.instImplicit, PsKernelCoreBinderInfo.instImplicit => true
      | _, _ => false
  | PsKernelCoreExpr.letE ln lt lv lb lnd, PsKernelCoreExpr.letE rn rt rv rb rnd =>
      psKcRecRedNameEq ln rn && psKcRecRedExprEq lt rt &&
      psKcRecRedExprEq lv rv && psKcRecRedExprEq lb rb && lnd == rnd
  | PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat l),
      PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat r) => l == r
  | PsKernelCoreExpr.lit (PsKernelCoreLiteral.str l),
      PsKernelCoreExpr.lit (PsKernelCoreLiteral.str r) => l == r
  | PsKernelCoreExpr.mdata lm le, PsKernelCoreExpr.mdata rm re =>
      lm == rm && psKcRecRedExprEq le re
  | PsKernelCoreExpr.proj ln li le, PsKernelCoreExpr.proj rn ri re =>
      psKcRecRedNameEq ln rn && li == ri && psKcRecRedExprEq le re
  | _, _ => false

def psKcRecRedApply
    (fn : PsKernelCoreExpr)
    (args : PsKernelCoreList PsKernelCoreExpr) : PsKernelCoreExpr :=
  match args with
  | PsKernelCoreList.nil => fn
  | PsKernelCoreList.cons arg rest =>
      psKcRecRedApply (PsKernelCoreExpr.app fn arg) rest

def psKcRecRedName (value : String) : PsKernelCoreName :=
  PsKernelCoreName.str PsKernelCoreName.anonymous value

def psKcRecRedConst (name : PsKernelCoreName) : PsKernelCoreExpr :=
  PsKernelCoreExpr.const name PsKernelCoreList.nil

def psKcRecRedResultEq
    (result : PsKernelCoreResult String PsKernelCoreExpr)
    (expected : PsKernelCoreExpr) : Bool :=
  match result with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok value => psKcRecRedExprEq value expected

def psKcRecRedResidual
    (result : PsKernelCoreResult String PsKernelCoreExpr)
    (original : PsKernelCoreExpr) : Bool :=
  psKcRecRedResultEq result original

-- Mature-oracle parity: two-constructor non-recursive enum.
def psKcRecRedFlag : PsKernelCoreName := psKcRecRedName "Phase10ReduceFlag"
def psKcRecRedOff : PsKernelCoreName := PsKernelCoreName.str psKcRecRedFlag "off"
def psKcRecRedOn : PsKernelCoreName := PsKernelCoreName.str psKcRecRedFlag "on"
def psKcRecRedFlagRec : PsKernelCoreName := PsKernelCoreName.str psKcRecRedFlag "rec"

def psKcRecRedFlagExpr : PsKernelCoreExpr := psKcRecRedConst psKcRecRedFlag
def psKcRecRedOffExpr : PsKernelCoreExpr := psKcRecRedConst psKcRecRedOff
def psKcRecRedOnExpr : PsKernelCoreExpr := psKcRecRedConst psKcRecRedOn

def psKcRecRedFlagMotiveType : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE PsKernelCoreName.anonymous psKcRecRedFlagExpr
    (PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero))
    PsKernelCoreBinderInfo.default

def psKcRecRedFlagRecInfo : PsKernelCoreRecursorInfo := {
  base := {
    name := psKcRecRedFlagRec
    levelParams := PsKernelCoreList.nil
    type := PsKernelCoreExpr.sort PsKernelCoreLevel.zero
  }
  all := PsKernelCoreList.cons psKcRecRedFlag PsKernelCoreList.nil
  numParams := 0
  numIndices := 0
  numMotives := 1
  numMinors := 2
  rules := PsKernelCoreList.cons
    {
      ctor := psKcRecRedOff
      nFields := 0
      rhs := PsKernelCoreExpr.lam PsKernelCoreName.anonymous psKcRecRedFlagMotiveType
        (PsKernelCoreExpr.lam PsKernelCoreName.anonymous psKcRecRedFlagExpr
          (PsKernelCoreExpr.lam PsKernelCoreName.anonymous psKcRecRedFlagExpr
            (PsKernelCoreExpr.bvar 1) PsKernelCoreBinderInfo.default)
          PsKernelCoreBinderInfo.default)
        PsKernelCoreBinderInfo.default
    }
    (PsKernelCoreList.cons
      {
        ctor := psKcRecRedOn
        nFields := 0
        rhs := PsKernelCoreExpr.lam PsKernelCoreName.anonymous psKcRecRedFlagMotiveType
          (PsKernelCoreExpr.lam PsKernelCoreName.anonymous psKcRecRedFlagExpr
            (PsKernelCoreExpr.lam PsKernelCoreName.anonymous psKcRecRedFlagExpr
              (PsKernelCoreExpr.bvar 0) PsKernelCoreBinderInfo.default)
            PsKernelCoreBinderInfo.default)
          PsKernelCoreBinderInfo.default
      }
      PsKernelCoreList.nil)
  k := false
  isUnsafe := false
}

def psKcRecRedFlagEnv : PsKernelCoreEnvironment :=
  let family : PsKernelCoreConstantInfo :=
    PsKernelCoreConstantInfo.inductInfo {
      base := {
        name := psKcRecRedFlag
        levelParams := PsKernelCoreList.nil
        type := PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero)
      }
      numParams := 0
      numIndices := 0
      all := PsKernelCoreList.cons psKcRecRedFlag PsKernelCoreList.nil
      ctors := PsKernelCoreList.cons psKcRecRedOff
        (PsKernelCoreList.cons psKcRecRedOn PsKernelCoreList.nil)
      numNested := 0
      isRec := false
      isReflexive := false
      isUnsafe := false
    }
  let off : PsKernelCoreConstantInfo :=
    PsKernelCoreConstantInfo.ctorInfo {
      base := { name := psKcRecRedOff, levelParams := PsKernelCoreList.nil, type := psKcRecRedFlagExpr }
      induct := psKcRecRedFlag
      cidx := 0
      numParams := 0
      numFields := 0
      isUnsafe := false
    }
  let on : PsKernelCoreConstantInfo :=
    PsKernelCoreConstantInfo.ctorInfo {
      base := { name := psKcRecRedOn, levelParams := PsKernelCoreList.nil, type := psKcRecRedFlagExpr }
      induct := psKcRecRedFlag
      cidx := 1
      numParams := 0
      numFields := 0
      isUnsafe := false
    }
  psKernelCoreEnvironmentAddUnchecked
    (psKernelCoreEnvironmentAddUnchecked
      (psKernelCoreEnvironmentAddUnchecked
        (psKernelCoreEnvironmentAddUnchecked psKernelCoreEnvironmentEmpty family)
        off)
      on)
    (PsKernelCoreConstantInfo.recInfo psKcRecRedFlagRecInfo)

def psKcRecRedMotive : PsKernelCoreExpr :=
  PsKernelCoreExpr.lam PsKernelCoreName.anonymous psKcRecRedFlagExpr
    (PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero))
    PsKernelCoreBinderInfo.default

def psKcRecRedFlagApp (major : PsKernelCoreExpr) : PsKernelCoreExpr :=
  psKcRecRedApply (psKcRecRedConst psKcRecRedFlagRec)
    (PsKernelCoreList.cons psKcRecRedMotive
      (PsKernelCoreList.cons psKcRecRedFlagExpr
        (PsKernelCoreList.cons psKcRecRedFlagExpr
          (PsKernelCoreList.cons major PsKernelCoreList.nil))))

def psKcRecRedDirectKernel : Bool :=
  psKcRecRedResultEq
    (psKernelCoreWhnf 64 psKcRecRedFlagEnv psKernelCoreLocalContextEmpty
      (psKcRecRedFlagApp psKcRecRedOffExpr))
    psKcRecRedFlagExpr

def psRefRecRedDirect : Bool :=
  let family : PSC1Kernel.Name := .str .anonymous "Phase10ReduceFlag"
  let off : PSC1Kernel.Name := .str family "off"
  let on : PSC1Kernel.Name := .str family "on"
  let recName : PSC1Kernel.Name := .str family "rec"
  let familyExpr : PSC1Kernel.Expr := .const family []
  let decl : PSC1Kernel.Kernel.SimpleInductiveDecl := {
    levelParams := []
    name := family
    type := .sort (.succ .zero)
    ctors := [
      { name := off, type := familyExpr },
      { name := on, type := familyExpr }
    ]
    isUnsafe := false
    numParams := 0
  }
  match PSC1Kernel.Kernel.addSimpleInductive PSC1Kernel.Environment.empty decl with
  | .error _ => false
  | .ok env =>
      let motive : PSC1Kernel.Expr :=
        .lam .anonymous familyExpr (.sort (.succ .zero)) .default
      let expr := PSC1Kernel.applyArgs (.const recName [])
        [motive, familyExpr, familyExpr, .const off []]
      match PSC1Kernel.whnf (PSC1Kernel.CheckerContext.empty env) expr with
      | .error _ => false
      | .ok (.const result []) => PSC1Kernel.Name.eq result family
      | .ok _ => false

-- Synthetic shape makes exact reduction argument ordering observable.
def psKcRecRedFamily : PsKernelCoreName := psKcRecRedName "Phase10ReduceSynthetic"
def psKcRecRedCtor : PsKernelCoreName := PsKernelCoreName.str psKcRecRedFamily "ctor"
def psKcRecRedRec : PsKernelCoreName := PsKernelCoreName.str psKcRecRedFamily "rec"
def psKcRecRedRuleFn : PsKernelCoreName := psKcRecRedName "phase10RuleFn"
def psKcRecRedP : PsKernelCoreName := psKcRecRedName "phase10P"
def psKcRecRedM : PsKernelCoreName := psKcRecRedName "phase10M"
def psKcRecRedN : PsKernelCoreName := psKcRecRedName "phase10N"
def psKcRecRedI : PsKernelCoreName := psKcRecRedName "phase10I"
def psKcRecRedX : PsKernelCoreName := psKcRecRedName "phase10X"
def psKcRecRedT : PsKernelCoreName := psKcRecRedName "phase10T"
def psKcRecRedAlias : PsKernelCoreName := psKcRecRedName "phase10MajorAlias"
def psKcRecRedForeignFamily : PsKernelCoreName := psKcRecRedName "Phase10Foreign"
def psKcRecRedForeignCtor : PsKernelCoreName := PsKernelCoreName.str psKcRecRedForeignFamily "ctor"
def psKcRecRedU : PsKernelCoreName := psKcRecRedName "u"

def psKcRecRedSyntheticInfo : PsKernelCoreRecursorInfo := {
  base := {
    name := psKcRecRedRec
    levelParams := PsKernelCoreList.nil
    type := PsKernelCoreExpr.sort PsKernelCoreLevel.zero
  }
  all := PsKernelCoreList.cons psKcRecRedFamily PsKernelCoreList.nil
  numParams := 1
  numIndices := 1
  numMotives := 1
  numMinors := 1
  rules := PsKernelCoreList.cons
    { ctor := psKcRecRedCtor, nFields := 2, rhs := psKcRecRedConst psKcRecRedRuleFn }
    PsKernelCoreList.nil
  k := false
  isUnsafe := false
}

def psKcRecRedSyntheticEnv : PsKernelCoreEnvironment :=
  let family : PsKernelCoreConstantInfo :=
    PsKernelCoreConstantInfo.inductInfo {
      base := {
        name := psKcRecRedFamily
        levelParams := PsKernelCoreList.nil
        type := PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero)
      }
      numParams := 1
      numIndices := 1
      all := PsKernelCoreList.cons psKcRecRedFamily PsKernelCoreList.nil
      ctors := PsKernelCoreList.cons psKcRecRedCtor PsKernelCoreList.nil
      numNested := 0
      isRec := false
      isReflexive := false
      isUnsafe := false
    }
  let ctor : PsKernelCoreConstantInfo :=
    PsKernelCoreConstantInfo.ctorInfo {
      base := {
        name := psKcRecRedCtor
        levelParams := PsKernelCoreList.nil
        type := PsKernelCoreExpr.sort PsKernelCoreLevel.zero
      }
      induct := psKcRecRedFamily
      cidx := 0
      numParams := 1
      numFields := 2
      isUnsafe := false
    }
  psKernelCoreEnvironmentAddUnchecked
    (psKernelCoreEnvironmentAddUnchecked
      (psKernelCoreEnvironmentAddUnchecked psKernelCoreEnvironmentEmpty family)
      ctor)
    (PsKernelCoreConstantInfo.recInfo psKcRecRedSyntheticInfo)

def psKcRecRedMajor : PsKernelCoreExpr :=
  psKcRecRedApply (psKcRecRedConst psKcRecRedCtor)
    (PsKernelCoreList.cons (psKcRecRedConst psKcRecRedP)
      (PsKernelCoreList.cons (psKcRecRedConst psKcRecRedI)
        (PsKernelCoreList.cons (psKcRecRedConst psKcRecRedX) PsKernelCoreList.nil)))

def psKcRecRedSyntheticAppWith
    (recLevels : PsKernelCoreList PsKernelCoreLevel)
    (major : PsKernelCoreExpr) : PsKernelCoreExpr :=
  psKcRecRedApply (PsKernelCoreExpr.const psKcRecRedRec recLevels)
    (PsKernelCoreList.cons (psKcRecRedConst psKcRecRedP)
      (PsKernelCoreList.cons (psKcRecRedConst psKcRecRedM)
        (PsKernelCoreList.cons (psKcRecRedConst psKcRecRedN)
          (PsKernelCoreList.cons (psKcRecRedConst psKcRecRedI)
            (PsKernelCoreList.cons major
              (PsKernelCoreList.cons (psKcRecRedConst psKcRecRedT)
                PsKernelCoreList.nil))))))

def psKcRecRedSyntheticApp : PsKernelCoreExpr :=
  psKcRecRedSyntheticAppWith PsKernelCoreList.nil psKcRecRedMajor

def psKcRecRedSyntheticExpectedWith
    (fn : PsKernelCoreExpr) : PsKernelCoreExpr :=
  psKcRecRedApply fn
    (PsKernelCoreList.cons (psKcRecRedConst psKcRecRedP)
      (PsKernelCoreList.cons (psKcRecRedConst psKcRecRedM)
        (PsKernelCoreList.cons (psKcRecRedConst psKcRecRedN)
          (PsKernelCoreList.cons (psKcRecRedConst psKcRecRedI)
            (PsKernelCoreList.cons (psKcRecRedConst psKcRecRedX)
              (PsKernelCoreList.cons (psKcRecRedConst psKcRecRedT)
                PsKernelCoreList.nil))))))

def psKcRecRedSyntheticOrdering : Bool :=
  psKcRecRedResultEq
    (psKernelCoreWhnf 64 psKcRecRedSyntheticEnv psKernelCoreLocalContextEmpty
      psKcRecRedSyntheticApp)
    (psKcRecRedSyntheticExpectedWith (psKcRecRedConst psKcRecRedRuleFn))

def psKcRecRedMajorWhnf : Bool :=
  let aliasInfo : PsKernelCoreConstantInfo :=
    PsKernelCoreConstantInfo.defnInfo {
      base := {
        name := psKcRecRedAlias
        levelParams := PsKernelCoreList.nil
        type := PsKernelCoreExpr.sort PsKernelCoreLevel.zero
      }
      value := psKcRecRedMajor
      hints := PsKernelCoreReducibilityHints.regular 0
      safety := PsKernelCoreDefinitionSafety.safe
    }
  let env := psKernelCoreEnvironmentAddUnchecked psKcRecRedSyntheticEnv aliasInfo;
  let expr := psKcRecRedSyntheticAppWith PsKernelCoreList.nil (psKcRecRedConst psKcRecRedAlias);
  psKcRecRedResultEq
    (psKernelCoreWhnf 64 env psKernelCoreLocalContextEmpty expr)
    (psKcRecRedSyntheticExpectedWith (psKcRecRedConst psKcRecRedRuleFn))

def psKcRecRedUnderapplied : Bool :=
  let expr := psKcRecRedApply (psKcRecRedConst psKcRecRedRec)
    (PsKernelCoreList.cons (psKcRecRedConst psKcRecRedP)
      (PsKernelCoreList.cons (psKcRecRedConst psKcRecRedM)
        (PsKernelCoreList.cons (psKcRecRedConst psKcRecRedN)
          (PsKernelCoreList.cons (psKcRecRedConst psKcRecRedI) PsKernelCoreList.nil))))
  psKcRecRedResidual
    (psKernelCoreWhnf 64 psKcRecRedSyntheticEnv psKernelCoreLocalContextEmpty expr)
    expr

def psKcRecRedWrongMajor : Bool :=
  let expr := psKcRecRedSyntheticAppWith PsKernelCoreList.nil (psKcRecRedConst psKcRecRedFamily);
  psKcRecRedResidual
    (psKernelCoreWhnf 64 psKcRecRedSyntheticEnv psKernelCoreLocalContextEmpty expr)
    expr

def psKcRecRedForeignMajor : Bool :=
  let foreignCtorInfo : PsKernelCoreConstantInfo :=
    PsKernelCoreConstantInfo.ctorInfo {
      base := {
        name := psKcRecRedForeignCtor
        levelParams := PsKernelCoreList.nil
        type := PsKernelCoreExpr.sort PsKernelCoreLevel.zero
      }
      induct := psKcRecRedForeignFamily
      cidx := 0
      numParams := 1
      numFields := 2
      isUnsafe := false
    }
  let foreignRule : PsKernelCoreRecursorRule := {
    ctor := psKcRecRedForeignCtor
    nFields := 2
    rhs := psKcRecRedConst psKcRecRedRuleFn
  }
  let foreignRec : PsKernelCoreRecursorInfo := {
    psKcRecRedSyntheticInfo with
    rules := PsKernelCoreList.cons foreignRule PsKernelCoreList.nil
  }
  let env0 := psKernelCoreEnvironmentAddUnchecked psKcRecRedSyntheticEnv foreignCtorInfo;
  let env := psKernelCoreEnvironmentReplaceUnchecked env0 (PsKernelCoreConstantInfo.recInfo foreignRec);
  let major := psKcRecRedApply (psKcRecRedConst psKcRecRedForeignCtor)
    (PsKernelCoreList.cons (psKcRecRedConst psKcRecRedP)
      (PsKernelCoreList.cons (psKcRecRedConst psKcRecRedI)
        (PsKernelCoreList.cons (psKcRecRedConst psKcRecRedX) PsKernelCoreList.nil)));
  let expr := psKcRecRedSyntheticAppWith PsKernelCoreList.nil major;
  psKcRecRedResidual
    (psKernelCoreWhnf 64 env psKernelCoreLocalContextEmpty expr)
    expr

def psKcRecRedMissingRule : Bool :=
  let noRules : PsKernelCoreRecursorInfo := {
    psKcRecRedSyntheticInfo with rules := PsKernelCoreList.nil
  }
  let env := psKernelCoreEnvironmentReplaceUnchecked psKcRecRedSyntheticEnv
    (PsKernelCoreConstantInfo.recInfo noRules);
  psKcRecRedResidual
    (psKernelCoreWhnf 64 env psKernelCoreLocalContextEmpty psKcRecRedSyntheticApp)
    psKcRecRedSyntheticApp

def psKcRecRedShortConstructor : Bool :=
  let shortMajor := psKcRecRedApply (psKcRecRedConst psKcRecRedCtor)
    (PsKernelCoreList.cons (psKcRecRedConst psKcRecRedP) PsKernelCoreList.nil);
  let expr := psKcRecRedSyntheticAppWith PsKernelCoreList.nil shortMajor;
  psKcRecRedResidual
    (psKernelCoreWhnf 64 psKcRecRedSyntheticEnv psKernelCoreLocalContextEmpty expr)
    expr

def psKcRecRedUniverseInstantiation : Bool :=
  let levelInfo : PsKernelCoreRecursorInfo := {
    psKcRecRedSyntheticInfo with
    base := {
      psKcRecRedSyntheticInfo.base with
      levelParams := PsKernelCoreList.cons psKcRecRedU PsKernelCoreList.nil
    }
    rules := PsKernelCoreList.cons
      {
        ctor := psKcRecRedCtor
        nFields := 2
        rhs := PsKernelCoreExpr.const psKcRecRedRuleFn
          (PsKernelCoreList.cons (PsKernelCoreLevel.param psKcRecRedU) PsKernelCoreList.nil)
      }
      PsKernelCoreList.nil
  }
  let env := psKernelCoreEnvironmentReplaceUnchecked psKcRecRedSyntheticEnv
    (PsKernelCoreConstantInfo.recInfo levelInfo);
  let level := PsKernelCoreLevel.succ PsKernelCoreLevel.zero;
  let expr := psKcRecRedSyntheticAppWith
    (PsKernelCoreList.cons level PsKernelCoreList.nil) psKcRecRedMajor;
  let expectedFn := PsKernelCoreExpr.const psKcRecRedRuleFn
    (PsKernelCoreList.cons level PsKernelCoreList.nil);
  psKcRecRedResultEq
    (psKernelCoreWhnf 64 env psKernelCoreLocalContextEmpty expr)
    (psKcRecRedSyntheticExpectedWith expectedFn)

def psKcRecRedUniverseMismatch : Bool :=
  let levelInfo : PsKernelCoreRecursorInfo := {
    psKcRecRedSyntheticInfo with
    base := {
      psKcRecRedSyntheticInfo.base with
      levelParams := PsKernelCoreList.cons psKcRecRedU PsKernelCoreList.nil
    }
  }
  let env := psKernelCoreEnvironmentReplaceUnchecked psKcRecRedSyntheticEnv
    (PsKernelCoreConstantInfo.recInfo levelInfo);
  let expr := psKcRecRedSyntheticAppWith PsKernelCoreList.nil psKcRecRedMajor;
  psKcRecRedResidual
    (psKernelCoreWhnf 64 env psKernelCoreLocalContextEmpty expr)
    expr

def psKcRecRedConfiguredResources : Bool :=
  let resources : PsKernelCoreResourceConfig := { maxNatSize := 1 };
  psKcRecRedResultEq
    (psKernelCoreWhnfWithResources 64 resources
      psKcRecRedSyntheticEnv psKernelCoreLocalContextEmpty psKcRecRedSyntheticApp)
    (psKcRecRedSyntheticExpectedWith (psKcRecRedConst psKcRecRedRuleFn))

def psKcRecRedBudget : Bool :=
  match psKernelCoreWhnfWithResources 0 psKernelCoreResourceConfigDefault
      psKcRecRedSyntheticEnv psKernelCoreLocalContextEmpty psKcRecRedSyntheticApp with
  | PsKernelCoreResult.error message => message == "reduction budget exhausted"
  | PsKernelCoreResult.ok _ => false

def psKcRecursorReductionParity : Bool :=
  psKcRecRedDirectKernel &&
  psRefRecRedDirect &&
  psKcRecRedSyntheticOrdering &&
  psKcRecRedMajorWhnf &&
  psKcRecRedUnderapplied &&
  psKcRecRedWrongMajor &&
  psKcRecRedForeignMajor &&
  psKcRecRedMissingRule &&
  psKcRecRedShortConstructor &&
  psKcRecRedUniverseInstantiation &&
  psKcRecRedUniverseMismatch &&
  psKcRecRedConfiguredResources &&
  psKcRecRedBudget

def main : IO Unit := do
  if psKcRecursorReductionParity then
    IO.println "PSC2_KERNEL_CORE_RECURSOR_REDUCTION_PARITY: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_RECURSOR_REDUCTION_PARITY: FAIL")
