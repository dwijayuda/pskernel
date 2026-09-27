import Ps.KernelCore.Check
import PSC1Kernel.TypeChecker

def psKernelCoreCheckTestName (value : String) : PsKernelCoreName :=
  PsKernelCoreName.str PsKernelCoreName.anonymous value

def psReferenceCheckTestName (value : String) : PSC1Kernel.Name :=
  PSC1Kernel.Name.str PSC1Kernel.Name.anonymous value

def psKernelCoreCheckNameList1
    (value : PsKernelCoreName) : PsKernelCoreList PsKernelCoreName :=
  PsKernelCoreList.cons value PsKernelCoreList.nil

def psKernelCoreCheckLevelList1
    (value : PsKernelCoreLevel) : PsKernelCoreList PsKernelCoreLevel :=
  PsKernelCoreList.cons value PsKernelCoreList.nil

def psKernelCoreCheckAxiom
    (name : PsKernelCoreName)
    (levelParams : PsKernelCoreList PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (isUnsafe : Bool) : PsKernelCoreConstantInfo :=
  PsKernelCoreConstantInfo.axiomInfo {
    base := { name := name, levelParams := levelParams, type := type }
    isUnsafe := isUnsafe
  }

def psReferenceCheckAxiom
    (name : PSC1Kernel.Name)
    (levelParams : List PSC1Kernel.Name)
    (type : PSC1Kernel.Expr)
    (isUnsafe : Bool) : PSC1Kernel.ConstantInfo :=
  PSC1Kernel.ConstantInfo.axiomInfo {
    base := { name := name, levelParams := levelParams, type := type }
    isUnsafe := isUnsafe
  }

def psKernelCoreCheckDefinition
    (name : PsKernelCoreName)
    (type value : PsKernelCoreExpr)
    (safety : PsKernelCoreDefinitionSafety) : PsKernelCoreConstantInfo :=
  PsKernelCoreConstantInfo.defnInfo {
    base := { name := name, levelParams := PsKernelCoreList.nil, type := type }
    value := value
    hints := PsKernelCoreReducibilityHints.regular 0
    safety := safety
  }

def psReferenceCheckDefinition
    (name : PSC1Kernel.Name)
    (type value : PSC1Kernel.Expr)
    (safety : PSC1Kernel.DefinitionSafety) : PSC1Kernel.ConstantInfo :=
  PSC1Kernel.ConstantInfo.defnInfo {
    base := { name := name, levelParams := [], type := type }
    value := value
    hints := PSC1Kernel.ReducibilityHints.regular 0
    safety := safety
  }

def psKernelCoreCheckOkType
    (result : PsKernelCoreResult String PsKernelCoreExpr)
    (expected : PsKernelCoreExpr) : Bool :=
  match result with
  | PsKernelCoreResult.ok actual => psKernelCoreExprEq actual expected
  | PsKernelCoreResult.error _ => false

def psReferenceCheckOkType
    (result : Except String PSC1Kernel.Expr)
    (expected : PSC1Kernel.Expr) : Bool :=
  match result with
  | Except.ok actual => PSC1Kernel.Expr.eq actual expected
  | Except.error _ => false

def psKernelCoreCheckRejected
    (result : PsKernelCoreResult String PsKernelCoreExpr) : Bool :=
  match result with
  | PsKernelCoreResult.error _ => true
  | PsKernelCoreResult.ok _ => false

def psReferenceCheckRejected
    (result : Except String PSC1Kernel.Expr) : Bool :=
  match result with
  | Except.error _ => true
  | Except.ok _ => false

def psKernelCoreCheckExactError
    (result : PsKernelCoreResult String PsKernelCoreExpr)
    (expected : String) : Bool :=
  match result with
  | PsKernelCoreResult.error actual => actual == expected
  | PsKernelCoreResult.ok _ => false

def psKernelCoreCheckRun
    (budget : Nat)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (safety : PsKernelCoreDefinitionSafety)
    (expr : PsKernelCoreExpr) : PsKernelCoreResult String PsKernelCoreExpr :=
  psKernelCoreCheck budget env lctx safety expr

def psReferenceCheckRun
    (env : PSC1Kernel.Environment)
    (lctx : PSC1Kernel.LocalContext)
    (safety : PSC1Kernel.DefinitionSafety)
    (expr : PSC1Kernel.Expr) : Except String PSC1Kernel.Expr :=
  PSC1Kernel.check {
    PSC1Kernel.CheckerContext.empty env with
    lctx := lctx
    safety := safety
  } expr

def psKernelCoreCheckParity : Bool :=
  let budget := 64
  let kn := psKernelCoreCheckTestName
  let rn := psReferenceCheckTestName
  let kzero := PsKernelCoreLevel.zero
  let kone := PsKernelCoreLevel.succ kzero
  let ktwo := PsKernelCoreLevel.succ kone
  let rzero := PSC1Kernel.Level.zero
  let rone := PSC1Kernel.Level.succ rzero
  let rtwo := PSC1Kernel.Level.succ rone
  let ksort0 := PsKernelCoreExpr.sort kzero
  let ksort1 := PsKernelCoreExpr.sort kone
  let ksort2 := PsKernelCoreExpr.sort ktwo
  let rsort0 := PSC1Kernel.Expr.sort rzero
  let rsort1 := PSC1Kernel.Expr.sort rone
  let rsort2 := PSC1Kernel.Expr.sort rtwo

  let kA := kn "A"
  let kP := kn "P"
  let kNat := kn "Nat"
  let kString := kn "String"
  let ka := kn "a"
  let kp := kn "p"
  let kfun := kn "fun"
  let kdep := kn "dep"
  let kpoly := kn "poly"
  let ku := kn "u"
  let kunsafe := kn "unsafeC"
  let kpartial := kn "partialC"
  let kslow := kn "slowFun"
  let kx := kn "x"
  let kT := kn "T"
  let kmissing := kn "missing"
  let kprojType := kn "S"
  let kcProj := kn "cProj"
  let kgProj := kn "gProj"

  let rA := rn "A"
  let rP := rn "P"
  let rNat := rn "Nat"
  let rString := rn "String"
  let ra := rn "a"
  let rp := rn "p"
  let rfun := rn "fun"
  let rdep := rn "dep"
  let rpoly := rn "poly"
  let ru := rn "u"
  let runsafe := rn "unsafeC"
  let rpartial := rn "partialC"
  let rslow := rn "slowFun"
  let rx := rn "x"
  let rT := rn "T"
  let rmissing := rn "missing"

  let kcA := PsKernelCoreExpr.const kA PsKernelCoreList.nil
  let kcP := PsKernelCoreExpr.const kP PsKernelCoreList.nil
  let kca := PsKernelCoreExpr.const ka PsKernelCoreList.nil
  let kcp := PsKernelCoreExpr.const kp PsKernelCoreList.nil
  let rcA := PSC1Kernel.Expr.const rA []
  let rcP := PSC1Kernel.Expr.const rP []
  let rca := PSC1Kernel.Expr.const ra []
  let rcp := PSC1Kernel.Expr.const rp []

  let kfunType :=
    PsKernelCoreExpr.forallE kx kcA kcA PsKernelCoreBinderInfo.default
  let rfunType :=
    PSC1Kernel.Expr.forallE rx rcA rcA PSC1Kernel.BinderInfo.default
  let kdepType :=
    PsKernelCoreExpr.forallE kT ksort1
      (PsKernelCoreExpr.forallE kx (PsKernelCoreExpr.bvar 0)
        (PsKernelCoreExpr.bvar 1) PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.implicit
  let rdepType :=
    PSC1Kernel.Expr.forallE rT rsort1
      (PSC1Kernel.Expr.forallE rx (PSC1Kernel.Expr.bvar 0)
        (PSC1Kernel.Expr.bvar 1) PSC1Kernel.BinderInfo.default)
      PSC1Kernel.BinderInfo.implicit

  let kempty := psKernelCoreEnvironmentEmpty
  let rempty := PSC1Kernel.Environment.empty
  let kenv1 := psKernelCoreEnvironmentAddUnchecked kempty
    (psKernelCoreCheckAxiom kA PsKernelCoreList.nil ksort1 false)
  let renv1 := PSC1Kernel.Environment.addUnchecked rempty
    (psReferenceCheckAxiom rA [] rsort1 false)
  let kenv2 := psKernelCoreEnvironmentAddUnchecked kenv1
    (psKernelCoreCheckAxiom kP PsKernelCoreList.nil ksort0 false)
  let renv2 := PSC1Kernel.Environment.addUnchecked renv1
    (psReferenceCheckAxiom rP [] rsort0 false)
  let kenv3 := psKernelCoreEnvironmentAddUnchecked kenv2
    (psKernelCoreCheckAxiom kNat PsKernelCoreList.nil ksort1 false)
  let renv3 := PSC1Kernel.Environment.addUnchecked renv2
    (psReferenceCheckAxiom rNat [] rsort1 false)
  let kenv4 := psKernelCoreEnvironmentAddUnchecked kenv3
    (psKernelCoreCheckAxiom kString PsKernelCoreList.nil ksort1 false)
  let renv4 := PSC1Kernel.Environment.addUnchecked renv3
    (psReferenceCheckAxiom rString [] rsort1 false)
  let kenv5 := psKernelCoreEnvironmentAddUnchecked kenv4
    (psKernelCoreCheckAxiom ka PsKernelCoreList.nil kcA false)
  let renv5 := PSC1Kernel.Environment.addUnchecked renv4
    (psReferenceCheckAxiom ra [] rcA false)
  let kenv6 := psKernelCoreEnvironmentAddUnchecked kenv5
    (psKernelCoreCheckAxiom kp PsKernelCoreList.nil kcP false)
  let renv6 := PSC1Kernel.Environment.addUnchecked renv5
    (psReferenceCheckAxiom rp [] rcP false)
  let kenv7 := psKernelCoreEnvironmentAddUnchecked kenv6
    (psKernelCoreCheckAxiom kfun PsKernelCoreList.nil kfunType false)
  let renv7 := PSC1Kernel.Environment.addUnchecked renv6
    (psReferenceCheckAxiom rfun [] rfunType false)
  let kenv8 := psKernelCoreEnvironmentAddUnchecked kenv7
    (psKernelCoreCheckAxiom kdep PsKernelCoreList.nil kdepType false)
  let renv8 := PSC1Kernel.Environment.addUnchecked renv7
    (psReferenceCheckAxiom rdep [] rdepType false)
  let kenv9 := psKernelCoreEnvironmentAddUnchecked kenv8
    (psKernelCoreCheckAxiom kpoly (psKernelCoreCheckNameList1 ku)
      (PsKernelCoreExpr.sort (PsKernelCoreLevel.param ku)) false)
  let renv9 := PSC1Kernel.Environment.addUnchecked renv8
    (psReferenceCheckAxiom rpoly [ru]
      (PSC1Kernel.Expr.sort (PSC1Kernel.Level.param ru)) false)
  let kenv10 := psKernelCoreEnvironmentAddUnchecked kenv9
    (psKernelCoreCheckAxiom kunsafe PsKernelCoreList.nil kcA true)
  let renv10 := PSC1Kernel.Environment.addUnchecked renv9
    (psReferenceCheckAxiom runsafe [] rcA true)
  let kenv11 := psKernelCoreEnvironmentAddUnchecked kenv10
    (psKernelCoreCheckDefinition kpartial kcA kca PsKernelCoreDefinitionSafety.partialDef)
  let renv11 := PSC1Kernel.Environment.addUnchecked renv10
    (psReferenceCheckDefinition rpartial rcA rca PSC1Kernel.DefinitionSafety.partialDef)
  let kslowType := PsKernelCoreExpr.mdata 9 kfunType
  let rslowType := PSC1Kernel.Expr.mdata 9 rfunType
  let kenv := psKernelCoreEnvironmentAddUnchecked kenv11
    (psKernelCoreCheckAxiom kslow PsKernelCoreList.nil kslowType false)
  let renv := PSC1Kernel.Environment.addUnchecked renv11
    (psReferenceCheckAxiom rslow [] rslowType false)

  let klctx := psKernelCoreLocalContextAddLocal
    psKernelCoreLocalContextEmpty kx kx kcA PsKernelCoreBinderInfo.default
  let rlctx := PSC1Kernel.LocalContext.addLocal
    PSC1Kernel.LocalContext.empty rx rx rcA PSC1Kernel.BinderInfo.default

  let ksortCase := psKernelCoreCheckRun budget kenv klctx PsKernelCoreDefinitionSafety.safe ksort0
  let rsortCase := psReferenceCheckRun renv rlctx PSC1Kernel.DefinitionSafety.safe rsort0
  let localCaseK := psKernelCoreCheckRun budget kenv klctx PsKernelCoreDefinitionSafety.safe (PsKernelCoreExpr.fvar kx)
  let localCaseR := psReferenceCheckRun renv rlctx PSC1Kernel.DefinitionSafety.safe (PSC1Kernel.Expr.fvar rx)
  let monoCaseK := psKernelCoreCheckRun budget kenv klctx PsKernelCoreDefinitionSafety.safe kca
  let monoCaseR := psReferenceCheckRun renv rlctx PSC1Kernel.DefinitionSafety.safe rca
  let kpolyUse := PsKernelCoreExpr.const kpoly (psKernelCoreCheckLevelList1 kone)
  let rpolyUse := PSC1Kernel.Expr.const rpoly [rone]
  let polyCaseK := psKernelCoreCheckRun budget kenv klctx PsKernelCoreDefinitionSafety.safe kpolyUse
  let polyCaseR := psReferenceCheckRun renv rlctx PSC1Kernel.DefinitionSafety.safe rpolyUse
  let knat := PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat 7)
  let rnat := PSC1Kernel.Expr.lit (PSC1Kernel.Literal.nat 7)
  let kstr := PsKernelCoreExpr.lit (PsKernelCoreLiteral.str "abc")
  let rstr := PSC1Kernel.Expr.lit (PSC1Kernel.Literal.str "abc")
  let natCaseK := psKernelCoreCheckRun budget kenv klctx PsKernelCoreDefinitionSafety.safe knat
  let natCaseR := psReferenceCheckRun renv rlctx PSC1Kernel.DefinitionSafety.safe rnat
  let strCaseK := psKernelCoreCheckRun budget kenv klctx PsKernelCoreDefinitionSafety.safe kstr
  let strCaseR := psReferenceCheckRun renv rlctx PSC1Kernel.DefinitionSafety.safe rstr
  let metaCaseK := psKernelCoreCheckRun budget kenv klctx PsKernelCoreDefinitionSafety.safe (PsKernelCoreExpr.mdata 3 kca)
  let metaCaseR := psReferenceCheckRun renv rlctx PSC1Kernel.DefinitionSafety.safe (PSC1Kernel.Expr.mdata 3 rca)

  let kapp := PsKernelCoreExpr.app (PsKernelCoreExpr.const kfun PsKernelCoreList.nil) kca
  let rapp := PSC1Kernel.Expr.app (PSC1Kernel.Expr.const rfun []) rca
  let appCaseK := psKernelCoreCheckRun budget kenv klctx PsKernelCoreDefinitionSafety.safe kapp
  let appCaseR := psReferenceCheckRun renv rlctx PSC1Kernel.DefinitionSafety.safe rapp
  let kdepApp := PsKernelCoreExpr.app
    (PsKernelCoreExpr.app (PsKernelCoreExpr.const kdep PsKernelCoreList.nil) kcA) kca
  let rdepApp := PSC1Kernel.Expr.app
    (PSC1Kernel.Expr.app (PSC1Kernel.Expr.const rdep []) rcA) rca
  let depAppCaseK := psKernelCoreCheckRun budget kenv klctx PsKernelCoreDefinitionSafety.safe kdepApp
  let depAppCaseR := psReferenceCheckRun renv rlctx PSC1Kernel.DefinitionSafety.safe rdepApp

  let klam := PsKernelCoreExpr.lam kx kcA (PsKernelCoreExpr.bvar 0) PsKernelCoreBinderInfo.default
  let rlam := PSC1Kernel.Expr.lam rx rcA (PSC1Kernel.Expr.bvar 0) PSC1Kernel.BinderInfo.default
  let klamType := PsKernelCoreExpr.forallE kx kcA kcA PsKernelCoreBinderInfo.default
  let rlamType := PSC1Kernel.Expr.forallE rx rcA rcA PSC1Kernel.BinderInfo.default
  let lamCaseK := psKernelCoreCheckRun budget kenv psKernelCoreLocalContextEmpty PsKernelCoreDefinitionSafety.safe klam
  let lamCaseR := psReferenceCheckRun renv PSC1Kernel.LocalContext.empty PSC1Kernel.DefinitionSafety.safe rlam
  let kdepLam := PsKernelCoreExpr.lam kT ksort1
    (PsKernelCoreExpr.lam kx (PsKernelCoreExpr.bvar 0)
      (PsKernelCoreExpr.bvar 0) PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.implicit
  let rdepLam := PSC1Kernel.Expr.lam rT rsort1
    (PSC1Kernel.Expr.lam rx (PSC1Kernel.Expr.bvar 0)
      (PSC1Kernel.Expr.bvar 0) PSC1Kernel.BinderInfo.default)
    PSC1Kernel.BinderInfo.implicit
  let kdepLamType := PsKernelCoreExpr.forallE kT ksort1
    (PsKernelCoreExpr.forallE kx (PsKernelCoreExpr.bvar 0)
      (PsKernelCoreExpr.bvar 1) PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.implicit
  let rdepLamType := PSC1Kernel.Expr.forallE rT rsort1
    (PSC1Kernel.Expr.forallE rx (PSC1Kernel.Expr.bvar 0)
      (PSC1Kernel.Expr.bvar 1) PSC1Kernel.BinderInfo.default)
    PSC1Kernel.BinderInfo.implicit
  let depLamCaseK := psKernelCoreCheckRun budget kenv psKernelCoreLocalContextEmpty PsKernelCoreDefinitionSafety.safe kdepLam
  let depLamCaseR := psReferenceCheckRun renv PSC1Kernel.LocalContext.empty PSC1Kernel.DefinitionSafety.safe rdepLam

  let kforall := PsKernelCoreExpr.forallE kx kcA kcA PsKernelCoreBinderInfo.default
  let rforall := PSC1Kernel.Expr.forallE rx rcA rcA PSC1Kernel.BinderInfo.default
  let forallCaseK := psKernelCoreCheckRun budget kenv psKernelCoreLocalContextEmpty PsKernelCoreDefinitionSafety.safe kforall
  let forallCaseR := psReferenceCheckRun renv PSC1Kernel.LocalContext.empty PSC1Kernel.DefinitionSafety.safe rforall
  let klet := PsKernelCoreExpr.letE kx kcA kca (PsKernelCoreExpr.bvar 0) false
  let rlet := PSC1Kernel.Expr.letE rx rcA rca (PSC1Kernel.Expr.bvar 0) false
  let letCaseK := psKernelCoreCheckRun budget kenv psKernelCoreLocalContextEmpty PsKernelCoreDefinitionSafety.safe klet
  let letCaseR := psReferenceCheckRun renv PSC1Kernel.LocalContext.empty PSC1Kernel.DefinitionSafety.safe rlet
  let kdepLet := PsKernelCoreExpr.letE kT ksort1 kcA
    (PsKernelCoreExpr.lam kx (PsKernelCoreExpr.bvar 0)
      (PsKernelCoreExpr.bvar 0) PsKernelCoreBinderInfo.default) true
  let rdepLet := PSC1Kernel.Expr.letE rT rsort1 rcA
    (PSC1Kernel.Expr.lam rx (PSC1Kernel.Expr.bvar 0)
      (PSC1Kernel.Expr.bvar 0) PSC1Kernel.BinderInfo.default) true
  let kdepLetType := PsKernelCoreExpr.letE kT ksort1 kcA
    (PsKernelCoreExpr.forallE kx (PsKernelCoreExpr.bvar 0)
      (PsKernelCoreExpr.bvar 1) PsKernelCoreBinderInfo.default) true
  let rdepLetType := PSC1Kernel.Expr.letE rT rsort1 rcA
    (PSC1Kernel.Expr.forallE rx (PSC1Kernel.Expr.bvar 0)
      (PSC1Kernel.Expr.bvar 1) PSC1Kernel.BinderInfo.default) true
  let depLetCaseK := psKernelCoreCheckRun budget kenv psKernelCoreLocalContextEmpty PsKernelCoreDefinitionSafety.safe kdepLet
  let depLetCaseR := psReferenceCheckRun renv PSC1Kernel.LocalContext.empty PSC1Kernel.DefinitionSafety.safe rdepLet

  let unsafeExprK := PsKernelCoreExpr.const kunsafe PsKernelCoreList.nil
  let unsafeExprR := PSC1Kernel.Expr.const runsafe []
  let partialExprK := PsKernelCoreExpr.const kpartial PsKernelCoreList.nil
  let partialExprR := PSC1Kernel.Expr.const rpartial []
  let unsafeAllowedK := psKernelCoreCheckRun budget kenv klctx PsKernelCoreDefinitionSafety.unsafeDef unsafeExprK
  let unsafeAllowedR := psReferenceCheckRun renv rlctx PSC1Kernel.DefinitionSafety.unsafeDef unsafeExprR
  let partialAllowedK := psKernelCoreCheckRun budget kenv klctx PsKernelCoreDefinitionSafety.partialDef partialExprK
  let partialAllowedR := psReferenceCheckRun renv rlctx PSC1Kernel.DefinitionSafety.partialDef partialExprR
  let partialUnsafeK := psKernelCoreCheckRun budget kenv klctx PsKernelCoreDefinitionSafety.unsafeDef partialExprK
  let partialUnsafeR := psReferenceCheckRun renv rlctx PSC1Kernel.DefinitionSafety.unsafeDef partialExprR

  let looseK := psKernelCoreCheckRun budget kenv klctx PsKernelCoreDefinitionSafety.safe (PsKernelCoreExpr.bvar 0)
  let looseR := psReferenceCheckRun renv rlctx PSC1Kernel.DefinitionSafety.safe (PSC1Kernel.Expr.bvar 0)
  let mvarK := psKernelCoreCheckRun budget kenv klctx PsKernelCoreDefinitionSafety.safe (PsKernelCoreExpr.mvar (kn "m"))
  let mvarR := psReferenceCheckRun renv rlctx PSC1Kernel.DefinitionSafety.safe (PSC1Kernel.Expr.mvar (rn "m"))
  let unknownFvarK := psKernelCoreCheckRun budget kenv klctx PsKernelCoreDefinitionSafety.safe (PsKernelCoreExpr.fvar kmissing)
  let unknownFvarR := psReferenceCheckRun renv rlctx PSC1Kernel.DefinitionSafety.safe (PSC1Kernel.Expr.fvar rmissing)
  let unknownConstK := psKernelCoreCheckRun budget kenv klctx PsKernelCoreDefinitionSafety.safe (PsKernelCoreExpr.const kmissing PsKernelCoreList.nil)
  let unknownConstR := psReferenceCheckRun renv rlctx PSC1Kernel.DefinitionSafety.safe (PSC1Kernel.Expr.const rmissing [])
  let badArityK := psKernelCoreCheckRun budget kenv klctx PsKernelCoreDefinitionSafety.safe (PsKernelCoreExpr.const kpoly PsKernelCoreList.nil)
  let badArityR := psReferenceCheckRun renv rlctx PSC1Kernel.DefinitionSafety.safe (PSC1Kernel.Expr.const rpoly [])
  let unsafeSafeK := psKernelCoreCheckRun budget kenv klctx PsKernelCoreDefinitionSafety.safe unsafeExprK
  let unsafeSafeR := psReferenceCheckRun renv rlctx PSC1Kernel.DefinitionSafety.safe unsafeExprR
  let unsafePartialK := psKernelCoreCheckRun budget kenv klctx PsKernelCoreDefinitionSafety.partialDef unsafeExprK
  let unsafePartialR := psReferenceCheckRun renv rlctx PSC1Kernel.DefinitionSafety.partialDef unsafeExprR
  let partialSafeK := psKernelCoreCheckRun budget kenv klctx PsKernelCoreDefinitionSafety.safe partialExprK
  let partialSafeR := psReferenceCheckRun renv rlctx PSC1Kernel.DefinitionSafety.safe partialExprR

  let badAppK := PsKernelCoreExpr.app (PsKernelCoreExpr.const kfun PsKernelCoreList.nil) kcp
  let badAppR := PSC1Kernel.Expr.app (PSC1Kernel.Expr.const rfun []) rcp
  let badAppResultK := psKernelCoreCheckRun budget kenv klctx PsKernelCoreDefinitionSafety.safe badAppK
  let badAppResultR := psReferenceCheckRun renv rlctx PSC1Kernel.DefinitionSafety.safe badAppR
  let badLamK := PsKernelCoreExpr.lam kx kca kca PsKernelCoreBinderInfo.default
  let badLamR := PSC1Kernel.Expr.lam rx rca rca PSC1Kernel.BinderInfo.default
  let badLamResultK := psKernelCoreCheckRun budget kenv psKernelCoreLocalContextEmpty PsKernelCoreDefinitionSafety.safe badLamK
  let badLamResultR := psReferenceCheckRun renv PSC1Kernel.LocalContext.empty PSC1Kernel.DefinitionSafety.safe badLamR
  let badForallDomainK := PsKernelCoreExpr.forallE kx kca kcA PsKernelCoreBinderInfo.default
  let badForallDomainR := PSC1Kernel.Expr.forallE rx rca rcA PSC1Kernel.BinderInfo.default
  let badForallDomainResultK := psKernelCoreCheckRun budget kenv psKernelCoreLocalContextEmpty PsKernelCoreDefinitionSafety.safe badForallDomainK
  let badForallDomainResultR := psReferenceCheckRun renv PSC1Kernel.LocalContext.empty PSC1Kernel.DefinitionSafety.safe badForallDomainR
  let badForallCodomainK := PsKernelCoreExpr.forallE kx kcA kca PsKernelCoreBinderInfo.default
  let badForallCodomainR := PSC1Kernel.Expr.forallE rx rcA rca PSC1Kernel.BinderInfo.default
  let badForallCodomainResultK := psKernelCoreCheckRun budget kenv psKernelCoreLocalContextEmpty PsKernelCoreDefinitionSafety.safe badForallCodomainK
  let badForallCodomainResultR := psReferenceCheckRun renv PSC1Kernel.LocalContext.empty PSC1Kernel.DefinitionSafety.safe badForallCodomainR
  let badLetTypeK := PsKernelCoreExpr.letE kx kca kca (PsKernelCoreExpr.bvar 0) false
  let badLetTypeR := PSC1Kernel.Expr.letE rx rca rca (PSC1Kernel.Expr.bvar 0) false
  let badLetTypeResultK := psKernelCoreCheckRun budget kenv psKernelCoreLocalContextEmpty PsKernelCoreDefinitionSafety.safe badLetTypeK
  let badLetTypeResultR := psReferenceCheckRun renv PSC1Kernel.LocalContext.empty PSC1Kernel.DefinitionSafety.safe badLetTypeR
  let badLetValueK := PsKernelCoreExpr.letE kx kcA kcp (PsKernelCoreExpr.bvar 0) false
  let badLetValueR := PSC1Kernel.Expr.letE rx rcA rcp (PSC1Kernel.Expr.bvar 0) false
  let badLetValueResultK := psKernelCoreCheckRun budget kenv psKernelCoreLocalContextEmpty PsKernelCoreDefinitionSafety.safe badLetValueK
  let badLetValueResultR := psReferenceCheckRun renv PSC1Kernel.LocalContext.empty PSC1Kernel.DefinitionSafety.safe badLetValueR
  let nonFnK := PsKernelCoreExpr.app kca kca
  let nonFnR := PSC1Kernel.Expr.app rca rca
  let nonFnResultK := psKernelCoreCheckRun budget kenv klctx PsKernelCoreDefinitionSafety.safe nonFnK
  let nonFnResultR := psReferenceCheckRun renv rlctx PSC1Kernel.DefinitionSafety.safe nonFnR
  let projK := PsKernelCoreExpr.proj kA 0 kca
  let projResultK := psKernelCoreCheckRun budget kenv klctx PsKernelCoreDefinitionSafety.safe projK

  psKernelCoreCheckOkType ksortCase ksort1 &&
  psReferenceCheckOkType rsortCase rsort1 &&
  psKernelCoreCheckOkType localCaseK kcA && psReferenceCheckOkType localCaseR rcA &&
  psKernelCoreCheckOkType monoCaseK kcA && psReferenceCheckOkType monoCaseR rcA &&
  psKernelCoreCheckOkType polyCaseK ksort1 && psReferenceCheckOkType polyCaseR rsort1 &&
  psKernelCoreCheckOkType natCaseK (PsKernelCoreExpr.const kNat PsKernelCoreList.nil) &&
  psReferenceCheckOkType natCaseR (PSC1Kernel.Expr.const rNat []) &&
  psKernelCoreCheckOkType strCaseK (PsKernelCoreExpr.const kString PsKernelCoreList.nil) &&
  psReferenceCheckOkType strCaseR (PSC1Kernel.Expr.const rString []) &&
  psKernelCoreCheckOkType metaCaseK kcA && psReferenceCheckOkType metaCaseR rcA &&
  psKernelCoreCheckOkType appCaseK kcA && psReferenceCheckOkType appCaseR rcA &&
  psKernelCoreCheckOkType depAppCaseK kcA && psReferenceCheckOkType depAppCaseR rcA &&
  psKernelCoreCheckOkType lamCaseK klamType && psReferenceCheckOkType lamCaseR rlamType &&
  psKernelCoreCheckOkType depLamCaseK kdepLamType && psReferenceCheckOkType depLamCaseR rdepLamType &&
  psKernelCoreCheckOkType forallCaseK ksort1 && psReferenceCheckOkType forallCaseR rsort1 &&
  psKernelCoreCheckOkType letCaseK kcA && psReferenceCheckOkType letCaseR rcA &&
  psKernelCoreCheckOkType depLetCaseK kdepLetType && psReferenceCheckOkType depLetCaseR rdepLetType &&
  psKernelCoreCheckOkType unsafeAllowedK kcA && psReferenceCheckOkType unsafeAllowedR rcA &&
  psKernelCoreCheckOkType partialAllowedK kcA && psReferenceCheckOkType partialAllowedR rcA &&
  psKernelCoreCheckOkType partialUnsafeK kcA && psReferenceCheckOkType partialUnsafeR rcA &&
  psKernelCoreCheckRejected looseK && psReferenceCheckRejected looseR &&
  psKernelCoreCheckRejected mvarK && psReferenceCheckRejected mvarR &&
  psKernelCoreCheckRejected unknownFvarK && psReferenceCheckRejected unknownFvarR &&
  psKernelCoreCheckRejected unknownConstK && psReferenceCheckRejected unknownConstR &&
  psKernelCoreCheckRejected badArityK && psReferenceCheckRejected badArityR &&
  psKernelCoreCheckExactError unsafeSafeK "safe declaration uses unsafe constant" && psReferenceCheckRejected unsafeSafeR &&
  psKernelCoreCheckExactError unsafePartialK "safe declaration uses unsafe constant" && psReferenceCheckRejected unsafePartialR &&
  psKernelCoreCheckExactError partialSafeK "safe declaration uses partial constant" && psReferenceCheckRejected partialSafeR &&
  psKernelCoreCheckExactError badAppResultK "application type mismatch" && psReferenceCheckRejected badAppResultR &&
  psKernelCoreCheckRejected badLamResultK && psReferenceCheckRejected badLamResultR &&
  psKernelCoreCheckRejected badForallDomainResultK && psReferenceCheckRejected badForallDomainResultR &&
  psKernelCoreCheckRejected badForallCodomainResultK && psReferenceCheckRejected badForallCodomainResultR &&
  psKernelCoreCheckRejected badLetTypeResultK && psReferenceCheckRejected badLetTypeResultR &&
  psKernelCoreCheckExactError badLetValueResultK "let value type mismatch" && psReferenceCheckRejected badLetValueResultR &&
  psKernelCoreCheckRejected nonFnResultK && psReferenceCheckRejected nonFnResultR &&
  psKernelCoreCheckExactError projResultK "projection checking unavailable before inductive metadata"

def psKernelCoreCheckBoundaries : Bool :=
  let kn := psKernelCoreCheckTestName
  let kzero := PsKernelCoreLevel.zero
  let kone := PsKernelCoreLevel.succ kzero
  let ksort0 := PsKernelCoreExpr.sort kzero
  let ksort1 := PsKernelCoreExpr.sort kone
  let kA := kn "A"
  let ka := kn "a"
  let kfun := kn "fun"
  let kslow := kn "slowFun"
  let kS := kn "S"
  let kcProj := kn "cProj"
  let kgProj := kn "gProj"
  let kcA := PsKernelCoreExpr.const kA PsKernelCoreList.nil
  let kca := PsKernelCoreExpr.const ka PsKernelCoreList.nil
  let kfunType := PsKernelCoreExpr.forallE (kn "x") kcA kcA PsKernelCoreBinderInfo.default
  let env0 := psKernelCoreEnvironmentEmpty
  let env1 := psKernelCoreEnvironmentAddUnchecked env0
    (psKernelCoreCheckAxiom kA PsKernelCoreList.nil ksort1 false)
  let env2 := psKernelCoreEnvironmentAddUnchecked env1
    (psKernelCoreCheckAxiom ka PsKernelCoreList.nil kcA false)
  let env3 := psKernelCoreEnvironmentAddUnchecked env2
    (psKernelCoreCheckAxiom kfun PsKernelCoreList.nil kfunType false)
  let env4 := psKernelCoreEnvironmentAddUnchecked env3
    (psKernelCoreCheckAxiom kslow PsKernelCoreList.nil (PsKernelCoreExpr.mdata 9 kfunType) false)
  let proj0 := PsKernelCoreExpr.proj kS 0 kca
  let proj1 := PsKernelCoreExpr.proj kS 1 kca
  let env5 := psKernelCoreEnvironmentAddUnchecked env4
    (psKernelCoreCheckAxiom kcProj PsKernelCoreList.nil proj0 false)
  let env := psKernelCoreEnvironmentAddUnchecked env5
    (psKernelCoreCheckAxiom kgProj PsKernelCoreList.nil
      (PsKernelCoreExpr.forallE (kn "x") proj1 kcA PsKernelCoreBinderInfo.default) false)
  let zeroBudget := psKernelCoreCheckExactError
    (psKernelCoreCheck 0 env psKernelCoreLocalContextEmpty PsKernelCoreDefinitionSafety.safe ksort0)
    "check budget exhausted"
  let threshold :=
    psKernelCoreCheckOkType
      (psKernelCoreCheck 1 env psKernelCoreLocalContextEmpty PsKernelCoreDefinitionSafety.safe ksort0)
      ksort1
  let whnfPropagation := psKernelCoreCheckExactError
    (psKernelCoreCheck 2 env psKernelCoreLocalContextEmpty PsKernelCoreDefinitionSafety.safe
      (PsKernelCoreExpr.app (PsKernelCoreExpr.const kslow PsKernelCoreList.nil) kca))
    "reduction budget exhausted"
  let defEqPropagation := psKernelCoreCheckExactError
    (psKernelCoreCheck 64 env psKernelCoreLocalContextEmpty PsKernelCoreDefinitionSafety.safe
      (PsKernelCoreExpr.app (PsKernelCoreExpr.const kgProj PsKernelCoreList.nil)
        (PsKernelCoreExpr.const kcProj PsKernelCoreList.nil)))
    "projection definitional equality unavailable before inductive metadata"
  zeroBudget && threshold && whnfPropagation && defEqPropagation

def main : IO Unit := do
  if !psKernelCoreCheckParity then
    throw (IO.userError "PSC2_KERNEL_CORE_CHECK_PARITY: DIFFERENTIAL FAIL")
  if !psKernelCoreCheckBoundaries then
    throw (IO.userError "PSC2_KERNEL_CORE_CHECK_PARITY: BOUNDARY FAIL")
  IO.println "PSC2_KERNEL_CORE_CHECK_PARITY: PASS"
