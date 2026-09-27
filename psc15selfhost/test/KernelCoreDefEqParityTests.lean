import Ps.KernelCore.DefEq
import PSC1Kernel.TypeChecker

def psKernelCoreDefEqTestName (value : String) : PsKernelCoreName :=
  PsKernelCoreName.str PsKernelCoreName.anonymous value

def psReferenceDefEqTestName (value : String) : PSC1Kernel.Name :=
  PSC1Kernel.Name.str PSC1Kernel.Name.anonymous value

def psKernelCoreDefEqAxiom
    (name : PsKernelCoreName)
    (levelParams : PsKernelCoreList PsKernelCoreName)
    (type : PsKernelCoreExpr) : PsKernelCoreConstantInfo :=
  PsKernelCoreConstantInfo.axiomInfo {
    base := { name := name, levelParams := levelParams, type := type }
    isUnsafe := false
  }

def psReferenceDefEqAxiom
    (name : PSC1Kernel.Name)
    (levelParams : List PSC1Kernel.Name)
    (type : PSC1Kernel.Expr) : PSC1Kernel.ConstantInfo :=
  PSC1Kernel.ConstantInfo.axiomInfo {
    base := { name := name, levelParams := levelParams, type := type }
    isUnsafe := false
  }

def psKernelCoreDefEqDefinition
    (name : PsKernelCoreName)
    (levelParams : PsKernelCoreList PsKernelCoreName)
    (type value : PsKernelCoreExpr) : PsKernelCoreConstantInfo :=
  PsKernelCoreConstantInfo.defnInfo {
    base := { name := name, levelParams := levelParams, type := type }
    value := value
    hints := PsKernelCoreReducibilityHints.regular 0
    safety := PsKernelCoreDefinitionSafety.safe
  }

def psReferenceDefEqDefinition
    (name : PSC1Kernel.Name)
    (levelParams : List PSC1Kernel.Name)
    (type value : PSC1Kernel.Expr) : PSC1Kernel.ConstantInfo :=
  PSC1Kernel.ConstantInfo.defnInfo {
    base := { name := name, levelParams := levelParams, type := type }
    value := value
    hints := PSC1Kernel.ReducibilityHints.regular 0
    safety := PSC1Kernel.DefinitionSafety.safe
  }

def psKernelCoreDefEqOpaque
    (name : PsKernelCoreName)
    (type value : PsKernelCoreExpr) : PsKernelCoreConstantInfo :=
  PsKernelCoreConstantInfo.opaqueInfo {
    base := { name := name, levelParams := PsKernelCoreList.nil, type := type }
    value := value
    isUnsafe := false
  }

def psReferenceDefEqOpaque
    (name : PSC1Kernel.Name)
    (type value : PSC1Kernel.Expr) : PSC1Kernel.ConstantInfo :=
  PSC1Kernel.ConstantInfo.opaqueInfo {
    base := { name := name, levelParams := [], type := type }
    value := value
    isUnsafe := false
  }

def psKernelCoreDefEqNameList1
    (value : PsKernelCoreName) : PsKernelCoreList PsKernelCoreName :=
  PsKernelCoreList.cons value PsKernelCoreList.nil

def psKernelCoreDefEqLevelList1
    (value : PsKernelCoreLevel) : PsKernelCoreList PsKernelCoreLevel :=
  PsKernelCoreList.cons value PsKernelCoreList.nil

def psKernelCoreDefEqResultMatches
    (kernelResult : PsKernelCoreResult String Bool)
    (referenceResult : Except String Bool) : Bool :=
  match kernelResult, referenceResult with
  | PsKernelCoreResult.error left, Except.error right => left == right
  | PsKernelCoreResult.ok left, Except.ok right => left == right
  | _, _ => false

def psKernelCoreDefEqRunMatches
    (budget : Nat)
    (kernelEnv : PsKernelCoreEnvironment)
    (kernelLctx : PsKernelCoreLocalContext)
    (kernelLeft kernelRight : PsKernelCoreExpr)
    (referenceEnv : PSC1Kernel.Environment)
    (referenceLctx : PSC1Kernel.LocalContext)
    (referenceLeft referenceRight : PSC1Kernel.Expr) : Bool :=
  let referenceCtx := {
    PSC1Kernel.CheckerContext.empty referenceEnv with
    lctx := referenceLctx
  }
  psKernelCoreDefEqResultMatches
    (psKernelCoreIsDefEq budget kernelEnv kernelLctx kernelLeft kernelRight)
    (PSC1Kernel.isDefEq referenceCtx referenceLeft referenceRight)

def psKernelCoreDefEqParity : Bool :=
  let budget := 64
  let kn := psKernelCoreDefEqTestName
  let rn := psReferenceDefEqTestName
  let kA := kn "A"
  let kB := kn "B"
  let kP := kn "P"
  let kQ := kn "Q"
  let kNat := kn "Nat"
  let kString := kn "String"
  let kPoly := kn "Poly"
  let ku := kn "u"
  let kAliasA := kn "AliasA"
  let kAliasP := kn "AliasP"
  let kC1 := kn "C1"
  let kC2 := kn "C2"
  let kO1 := kn "O1"
  let kO2 := kn "O2"
  let kx := kn "x"
  let ky := kn "y"
  let ka := kn "a"
  let kb := kn "b"
  let kf := kn "f"
  let kp1 := kn "p1"
  let kp2 := kn "p2"
  let kq := kn "q"
  let km := kn "m"

  let rA := rn "A"
  let rB := rn "B"
  let rP := rn "P"
  let rQ := rn "Q"
  let rNat := rn "Nat"
  let rString := rn "String"
  let rPoly := rn "Poly"
  let ru := rn "u"
  let rAliasA := rn "AliasA"
  let rAliasP := rn "AliasP"
  let rC1 := rn "C1"
  let rC2 := rn "C2"
  let rO1 := rn "O1"
  let rO2 := rn "O2"
  let rx := rn "x"
  let ry := rn "y"
  let ra := rn "a"
  let rb := rn "b"
  let rf := rn "f"
  let rp1 := rn "p1"
  let rp2 := rn "p2"
  let rq := rn "q"
  let rm := rn "m"

  let kz := PsKernelCoreLevel.zero
  let k1 := PsKernelCoreLevel.succ kz
  let kEq1 := PsKernelCoreLevel.max k1 kz
  let k2 := PsKernelCoreLevel.succ k1
  let rz := PSC1Kernel.Level.zero
  let r1 := PSC1Kernel.Level.succ rz
  let rEq1 := PSC1Kernel.Level.max r1 rz
  let r2 := PSC1Kernel.Level.succ r1

  let ksort0 := PsKernelCoreExpr.sort kz
  let ksort1 := PsKernelCoreExpr.sort k1
  let rsort0 := PSC1Kernel.Expr.sort rz
  let rsort1 := PSC1Kernel.Expr.sort r1
  let kcA := PsKernelCoreExpr.const kA PsKernelCoreList.nil
  let kcB := PsKernelCoreExpr.const kB PsKernelCoreList.nil
  let kcP := PsKernelCoreExpr.const kP PsKernelCoreList.nil
  let kcQ := PsKernelCoreExpr.const kQ PsKernelCoreList.nil
  let rcA := PSC1Kernel.Expr.const rA []
  let rcB := PSC1Kernel.Expr.const rB []
  let rcP := PSC1Kernel.Expr.const rP []
  let rcQ := PSC1Kernel.Expr.const rQ []

  let kempty := psKernelCoreEnvironmentEmpty
  let rempty := PSC1Kernel.Environment.empty
  let kenv1 := psKernelCoreEnvironmentAddUnchecked kempty (psKernelCoreDefEqAxiom kA PsKernelCoreList.nil ksort1)
  let renv1 := PSC1Kernel.Environment.addUnchecked rempty (psReferenceDefEqAxiom rA [] rsort1)
  let kenv2 := psKernelCoreEnvironmentAddUnchecked kenv1 (psKernelCoreDefEqAxiom kB PsKernelCoreList.nil ksort1)
  let renv2 := PSC1Kernel.Environment.addUnchecked renv1 (psReferenceDefEqAxiom rB [] rsort1)
  let kenv3 := psKernelCoreEnvironmentAddUnchecked kenv2 (psKernelCoreDefEqAxiom kP PsKernelCoreList.nil ksort0)
  let renv3 := PSC1Kernel.Environment.addUnchecked renv2 (psReferenceDefEqAxiom rP [] rsort0)
  let kenv4 := psKernelCoreEnvironmentAddUnchecked kenv3 (psKernelCoreDefEqAxiom kQ PsKernelCoreList.nil ksort0)
  let renv4 := PSC1Kernel.Environment.addUnchecked renv3 (psReferenceDefEqAxiom rQ [] rsort0)
  let kenv5 := psKernelCoreEnvironmentAddUnchecked kenv4 (psKernelCoreDefEqAxiom kNat PsKernelCoreList.nil ksort1)
  let renv5 := PSC1Kernel.Environment.addUnchecked renv4 (psReferenceDefEqAxiom rNat [] rsort1)
  let kenv6 := psKernelCoreEnvironmentAddUnchecked kenv5 (psKernelCoreDefEqAxiom kString PsKernelCoreList.nil ksort1)
  let renv6 := PSC1Kernel.Environment.addUnchecked renv5 (psReferenceDefEqAxiom rString [] rsort1)
  let kenv7 := psKernelCoreEnvironmentAddUnchecked kenv6
    (psKernelCoreDefEqAxiom kPoly (psKernelCoreDefEqNameList1 ku) ksort1)
  let renv7 := PSC1Kernel.Environment.addUnchecked renv6
    (psReferenceDefEqAxiom rPoly [ru] rsort1)
  let kenv8 := psKernelCoreEnvironmentAddUnchecked kenv7
    (psKernelCoreDefEqDefinition kAliasA PsKernelCoreList.nil ksort1 kcA)
  let renv8 := PSC1Kernel.Environment.addUnchecked renv7
    (psReferenceDefEqDefinition rAliasA [] rsort1 rcA)
  let kenv9 := psKernelCoreEnvironmentAddUnchecked kenv8
    (psKernelCoreDefEqDefinition kAliasP PsKernelCoreList.nil ksort0 kcP)
  let renv9 := PSC1Kernel.Environment.addUnchecked renv8
    (psReferenceDefEqDefinition rAliasP [] rsort0 rcP)
  let kenv10 := psKernelCoreEnvironmentAddUnchecked kenv9
    (psKernelCoreDefEqAxiom kC1 PsKernelCoreList.nil kcA)
  let renv10 := PSC1Kernel.Environment.addUnchecked renv9
    (psReferenceDefEqAxiom rC1 [] rcA)
  let kenv11 := psKernelCoreEnvironmentAddUnchecked kenv10
    (psKernelCoreDefEqAxiom kC2 PsKernelCoreList.nil kcB)
  let renv11 := PSC1Kernel.Environment.addUnchecked renv10
    (psReferenceDefEqAxiom rC2 [] rcB)
  let kenv12 := psKernelCoreEnvironmentAddUnchecked kenv11
    (psKernelCoreDefEqOpaque kO1 kcA (PsKernelCoreExpr.fvar ka))
  let renv12 := PSC1Kernel.Environment.addUnchecked renv11
    (psReferenceDefEqOpaque rO1 rcA (PSC1Kernel.Expr.fvar ra))
  let kenv := psKernelCoreEnvironmentAddUnchecked kenv12
    (psKernelCoreDefEqOpaque kO2 kcA (PsKernelCoreExpr.fvar kb))
  let renv := PSC1Kernel.Environment.addUnchecked renv12
    (psReferenceDefEqOpaque rO2 rcA (PSC1Kernel.Expr.fvar rb))

  let kl0 := psKernelCoreLocalContextEmpty
  let rl0 := PSC1Kernel.LocalContext.empty
  let kl1 := psKernelCoreLocalContextAddLocal kl0 ka ka kcA PsKernelCoreBinderInfo.default
  let rl1 := PSC1Kernel.LocalContext.addLocal rl0 ra ra rcA PSC1Kernel.BinderInfo.default
  let kl2 := psKernelCoreLocalContextAddLocal kl1 kb kb kcA PsKernelCoreBinderInfo.default
  let rl2 := PSC1Kernel.LocalContext.addLocal rl1 rb rb rcA PSC1Kernel.BinderInfo.default
  let kfunType := PsKernelCoreExpr.forallE kx kcA kcA PsKernelCoreBinderInfo.default
  let rfunType := PSC1Kernel.Expr.forallE rx rcA rcA PSC1Kernel.BinderInfo.default
  let kl3 := psKernelCoreLocalContextAddLocal kl2 kf kf kfunType PsKernelCoreBinderInfo.default
  let rl3 := PSC1Kernel.LocalContext.addLocal rl2 rf rf rfunType PSC1Kernel.BinderInfo.default
  let kl4 := psKernelCoreLocalContextAddLocal kl3 kp1 kp1 kcP PsKernelCoreBinderInfo.default
  let rl4 := PSC1Kernel.LocalContext.addLocal rl3 rp1 rp1 rcP PSC1Kernel.BinderInfo.default
  let kl5 := psKernelCoreLocalContextAddLocal kl4 kp2 kp2 kcP PsKernelCoreBinderInfo.default
  let rl5 := PSC1Kernel.LocalContext.addLocal rl4 rp2 rp2 rcP PSC1Kernel.BinderInfo.default
  let kl6 := psKernelCoreLocalContextAddLocal kl5 kq kq kcQ PsKernelCoreBinderInfo.default
  let rl6 := PSC1Kernel.LocalContext.addLocal rl5 rq rq rcQ PSC1Kernel.BinderInfo.default
  let kaliasPExpr := PsKernelCoreExpr.const kAliasP PsKernelCoreList.nil
  let raliasPExpr := PSC1Kernel.Expr.const rAliasP []
  let kpa := kn "pAlias"
  let rpa := rn "pAlias"
  let kl := psKernelCoreLocalContextAddLocal kl6 kpa kpa kaliasPExpr PsKernelCoreBinderInfo.default
  let rl := PSC1Kernel.LocalContext.addLocal rl6 rpa rpa raliasPExpr PSC1Kernel.BinderInfo.default

  let kfa := PsKernelCoreExpr.fvar ka
  let kfb := PsKernelCoreExpr.fvar kb
  let kff := PsKernelCoreExpr.fvar kf
  let kfp1 := PsKernelCoreExpr.fvar kp1
  let kfp2 := PsKernelCoreExpr.fvar kp2
  let kfq := PsKernelCoreExpr.fvar kq
  let kfpa := PsKernelCoreExpr.fvar kpa
  let rfa := PSC1Kernel.Expr.fvar ra
  let rfb := PSC1Kernel.Expr.fvar rb
  let rff := PSC1Kernel.Expr.fvar rf
  let rfp1 := PSC1Kernel.Expr.fvar rp1
  let rfp2 := PSC1Kernel.Expr.fvar rp2
  let rfq := PSC1Kernel.Expr.fvar rq
  let rfpa := PSC1Kernel.Expr.fvar rpa

  let kIdLam := PsKernelCoreExpr.lam kx kcA (PsKernelCoreExpr.bvar 0) PsKernelCoreBinderInfo.default
  let rIdLam := PSC1Kernel.Expr.lam rx rcA (PSC1Kernel.Expr.bvar 0) PSC1Kernel.BinderInfo.default
  let kIdLamY := PsKernelCoreExpr.lam ky kcA (PsKernelCoreExpr.bvar 0) PsKernelCoreBinderInfo.implicit
  let rIdLamY := PSC1Kernel.Expr.lam ry rcA (PSC1Kernel.Expr.bvar 0) PSC1Kernel.BinderInfo.implicit
  let kForallX := PsKernelCoreExpr.forallE kx kcA kcA PsKernelCoreBinderInfo.default
  let rForallX := PSC1Kernel.Expr.forallE rx rcA rcA PSC1Kernel.BinderInfo.default
  let kForallY := PsKernelCoreExpr.forallE ky kcA kcA PsKernelCoreBinderInfo.instImplicit
  let rForallY := PSC1Kernel.Expr.forallE ry rcA rcA PSC1Kernel.BinderInfo.instImplicit
  let kDepLam := PsKernelCoreExpr.lam kx kcA
    (PsKernelCoreExpr.lam ky (PsKernelCoreExpr.bvar 0) (PsKernelCoreExpr.bvar 0) PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.default
  let rDepLam := PSC1Kernel.Expr.lam rx rcA
    (PSC1Kernel.Expr.lam ry (PSC1Kernel.Expr.bvar 0) (PSC1Kernel.Expr.bvar 0) PSC1Kernel.BinderInfo.default)
    PSC1Kernel.BinderInfo.default
  let kDepForall := PsKernelCoreExpr.forallE kx kcA
    (PsKernelCoreExpr.forallE ky (PsKernelCoreExpr.bvar 0) (PsKernelCoreExpr.bvar 1) PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.default
  let rDepForall := PSC1Kernel.Expr.forallE rx rcA
    (PSC1Kernel.Expr.forallE ry (PSC1Kernel.Expr.bvar 0) (PSC1Kernel.Expr.bvar 1) PSC1Kernel.BinderInfo.default)
    PSC1Kernel.BinderInfo.default

  let kBeta := PsKernelCoreExpr.app kIdLam kfa
  let rBeta := PSC1Kernel.Expr.app rIdLam rfa
  let kZeta := PsKernelCoreExpr.letE kx kcA kfa (PsKernelCoreExpr.bvar 0) false
  let rZeta := PSC1Kernel.Expr.letE rx rcA rfa (PSC1Kernel.Expr.bvar 0) false
  let kLetName := kn "lv"
  let rLetName := rn "lv"
  let klLet := psKernelCoreLocalContextAddLet kl kLetName kLetName kcA kfa
  let rlLet := PSC1Kernel.LocalContext.addLet rl rLetName rLetName rcA rfa
  let kLocalLet := PsKernelCoreExpr.fvar kLetName
  let rLocalLet := PSC1Kernel.Expr.fvar rLetName
  let kAliasAExpr := PsKernelCoreExpr.const kAliasA PsKernelCoreList.nil
  let rAliasAExpr := PSC1Kernel.Expr.const rAliasA []
  let kAppA := PsKernelCoreExpr.app kff kfa
  let rAppA := PSC1Kernel.Expr.app rff rfa
  let kEta := PsKernelCoreExpr.lam kx kcA
    (PsKernelCoreExpr.app kff (PsKernelCoreExpr.bvar 0))
    PsKernelCoreBinderInfo.default
  let rEta := PSC1Kernel.Expr.lam rx rcA
    (PSC1Kernel.Expr.app rff (PSC1Kernel.Expr.bvar 0))
    PSC1Kernel.BinderInfo.default

  let direct :=
    psKernelCoreDefEqRunMatches budget kenv kl kfa kfa renv rl rfa rfa &&
    psKernelCoreDefEqRunMatches budget kenv kl (PsKernelCoreExpr.mdata 3 kfa) kfa renv rl (PSC1Kernel.Expr.mdata 3 rfa) rfa &&
    psKernelCoreDefEqRunMatches budget kenv kl (PsKernelCoreExpr.sort kEq1) (PsKernelCoreExpr.sort k1) renv rl (PSC1Kernel.Expr.sort rEq1) (PSC1Kernel.Expr.sort r1) &&
    psKernelCoreDefEqRunMatches budget kenv kl
      (PsKernelCoreExpr.const kPoly (psKernelCoreDefEqLevelList1 kEq1))
      (PsKernelCoreExpr.const kPoly (psKernelCoreDefEqLevelList1 k1))
      renv rl (PSC1Kernel.Expr.const rPoly [rEq1]) (PSC1Kernel.Expr.const rPoly [r1]) &&
    psKernelCoreDefEqRunMatches budget kenv kl kfa kfa renv rl rfa rfa &&
    psKernelCoreDefEqRunMatches budget kenv kl
      (PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat 7))
      (PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat 7))
      renv rl (PSC1Kernel.Expr.lit (PSC1Kernel.Literal.nat 7)) (PSC1Kernel.Expr.lit (PSC1Kernel.Literal.nat 7)) &&
    psKernelCoreDefEqRunMatches budget kenv kl
      (PsKernelCoreExpr.lit (PsKernelCoreLiteral.str "λ日本"))
      (PsKernelCoreExpr.lit (PsKernelCoreLiteral.str "λ日本"))
      renv rl (PSC1Kernel.Expr.lit (PSC1Kernel.Literal.str "λ日本")) (PSC1Kernel.Expr.lit (PSC1Kernel.Literal.str "λ日本")) &&
    psKernelCoreDefEqRunMatches budget kenv kl kBeta kfa renv rl rBeta rfa &&
    psKernelCoreDefEqRunMatches budget kenv kl kZeta kfa renv rl rZeta rfa &&
    psKernelCoreDefEqRunMatches budget kenv klLet kLocalLet kfa renv rlLet rLocalLet rfa &&
    psKernelCoreDefEqRunMatches budget kenv kl kAliasAExpr kcA renv rl rAliasAExpr rcA &&
    psKernelCoreDefEqRunMatches budget kenv kl kAppA kAppA renv rl rAppA rAppA &&
    psKernelCoreDefEqRunMatches budget kenv kl kIdLam kIdLam renv rl rIdLam rIdLam &&
    psKernelCoreDefEqRunMatches budget kenv kl kIdLam kIdLamY renv rl rIdLam rIdLamY &&
    psKernelCoreDefEqRunMatches budget kenv kl kForallX kForallX renv rl rForallX rForallX &&
    psKernelCoreDefEqRunMatches budget kenv kl kForallX kForallY renv rl rForallX rForallY &&
    psKernelCoreDefEqRunMatches budget kenv kl kDepLam kDepLam renv rl rDepLam rDepLam &&
    psKernelCoreDefEqRunMatches budget kenv kl kDepForall kDepForall renv rl rDepForall rDepForall &&
    psKernelCoreDefEqRunMatches budget kenv kl kfp1 kfp2 renv rl rfp1 rfp2 &&
    psKernelCoreDefEqRunMatches budget kenv kl kfpa kfp1 renv rl rfpa rfp1 &&
    psKernelCoreDefEqRunMatches budget kenv kl kEta kff renv rl rEta rff &&
    psKernelCoreDefEqRunMatches budget kenv kl kff kEta renv rl rff rEta &&
    psKernelCoreDefEqRunMatches budget kenv kl
      (PsKernelCoreExpr.const kC1 PsKernelCoreList.nil)
      (PsKernelCoreExpr.const kC2 PsKernelCoreList.nil)
      renv rl (PSC1Kernel.Expr.const rC1 []) (PSC1Kernel.Expr.const rC2 []) &&
    psKernelCoreDefEqRunMatches budget kenv kl
      (PsKernelCoreExpr.const kPoly (psKernelCoreDefEqLevelList1 k1))
      (PsKernelCoreExpr.const kPoly (psKernelCoreDefEqLevelList1 k2))
      renv rl (PSC1Kernel.Expr.const rPoly [r1]) (PSC1Kernel.Expr.const rPoly [r2]) &&
    psKernelCoreDefEqRunMatches budget kenv kl kfa kfb renv rl rfa rfb &&
    psKernelCoreDefEqRunMatches budget kenv kl
      (PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat 7))
      (PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat 8))
      renv rl (PSC1Kernel.Expr.lit (PSC1Kernel.Literal.nat 7)) (PSC1Kernel.Expr.lit (PSC1Kernel.Literal.nat 8)) &&
    psKernelCoreDefEqRunMatches budget kenv kl
      (PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat 7))
      (PsKernelCoreExpr.lit (PsKernelCoreLiteral.str "7"))
      renv rl (PSC1Kernel.Expr.lit (PSC1Kernel.Literal.nat 7)) (PSC1Kernel.Expr.lit (PSC1Kernel.Literal.str "7")) &&
    psKernelCoreDefEqRunMatches budget kenv kl
      (PsKernelCoreExpr.app kff kfa) (PsKernelCoreExpr.app kff kfb)
      renv rl (PSC1Kernel.Expr.app rff rfa) (PSC1Kernel.Expr.app rff rfb) &&
    psKernelCoreDefEqRunMatches budget kenv kl
      kIdLam (PsKernelCoreExpr.lam ky kcB (PsKernelCoreExpr.bvar 0) PsKernelCoreBinderInfo.default)
      renv rl rIdLam (PSC1Kernel.Expr.lam ry rcB (PSC1Kernel.Expr.bvar 0) PSC1Kernel.BinderInfo.default) &&
    psKernelCoreDefEqRunMatches budget kenv kl
      kForallX (PsKernelCoreExpr.forallE ky kcB kcA PsKernelCoreBinderInfo.default)
      renv rl rForallX (PSC1Kernel.Expr.forallE ry rcB rcA PSC1Kernel.BinderInfo.default) &&
    psKernelCoreDefEqRunMatches budget kenv kl kfp1 kfq renv rl rfp1 rfq &&
    psKernelCoreDefEqRunMatches budget kenv kl kIdLam kfa renv rl rIdLam rfa &&
    psKernelCoreDefEqRunMatches budget kenv kl
      (PsKernelCoreExpr.const kO1 PsKernelCoreList.nil)
      (PsKernelCoreExpr.const kO2 PsKernelCoreList.nil)
      renv rl (PSC1Kernel.Expr.const rO1 []) (PSC1Kernel.Expr.const rO2 [])

  let kMvar := PsKernelCoreExpr.mvar km
  let rMvar := PSC1Kernel.Expr.mvar rm
  let proofError :=
    psKernelCoreDefEqResultMatches
      (psKernelCoreIsDefEq budget kenv kl kMvar kfa)
      (PSC1Kernel.isDefEq { PSC1Kernel.CheckerContext.empty renv with lctx := rl } rMvar rfa)
  let etaErrorLeft :=
    PsKernelCoreExpr.lam kx kcA (PsKernelCoreExpr.bvar 0) PsKernelCoreBinderInfo.default
  let etaErrorRefLeft :=
    PSC1Kernel.Expr.lam rx rcA (PSC1Kernel.Expr.bvar 0) PSC1Kernel.BinderInfo.default
  let etaError :=
    psKernelCoreDefEqResultMatches
      (psKernelCoreIsDefEq budget kenv kl etaErrorLeft kMvar)
      (PSC1Kernel.isDefEq { PSC1Kernel.CheckerContext.empty renv with lctx := rl } etaErrorRefLeft rMvar)
  let budgetZero :=
    match psKernelCoreIsDefEq 0 kenv kl kfa kfa with
    | PsKernelCoreResult.error message => message == "defeq budget exhausted"
    | _ => false
  let budgetOne :=
    match psKernelCoreIsDefEq 1 kenv kl kfa kfa with
    | PsKernelCoreResult.ok value => value
    | _ => false
  let kProjSame := PsKernelCoreExpr.proj kA 0 kfa
  let projectionStructural :=
    match psKernelCoreIsDefEq budget kenv kl kProjSame kProjSame with
    | PsKernelCoreResult.ok value => value
    | _ => false
  let projectionDeferred :=
    match psKernelCoreIsDefEq budget kenv kl
      (PsKernelCoreExpr.proj kA 0 kfa)
      (PsKernelCoreExpr.proj kA 0 kfb) with
    | PsKernelCoreResult.error message =>
        message == "projection definitional equality unavailable before inductive metadata"
    | _ => false

  direct && proofError && etaError && budgetZero && budgetOne &&
    projectionStructural && projectionDeferred

def main : IO Unit := do
  if psKernelCoreDefEqParity then
    IO.println "PSC2_KERNEL_CORE_DEFEQ_PARITY: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_DEFEQ_PARITY: FAIL")
