import Ps.KernelCore.Admission
import PSC1Kernel.Kernel

def psKernelCoreAdmissionName (value : String) : PsKernelCoreName :=
  PsKernelCoreName.str PsKernelCoreName.anonymous value

def psReferenceAdmissionName (value : String) : PSC1Kernel.Name :=
  PSC1Kernel.Name.str PSC1Kernel.Name.anonymous value

def psKernelCoreAdmissionNameList1
    (a : PsKernelCoreName) : PsKernelCoreList PsKernelCoreName :=
  PsKernelCoreList.cons a PsKernelCoreList.nil

def psKernelCoreAdmissionNameList2
    (a b : PsKernelCoreName) : PsKernelCoreList PsKernelCoreName :=
  PsKernelCoreList.cons a (PsKernelCoreList.cons b PsKernelCoreList.nil)

def psKernelCoreAdmissionNameList3
    (a b c : PsKernelCoreName) : PsKernelCoreList PsKernelCoreName :=
  PsKernelCoreList.cons a
    (PsKernelCoreList.cons b (PsKernelCoreList.cons c PsKernelCoreList.nil))

def psKernelCoreAdmissionAxiom
    (name : PsKernelCoreName)
    (levelParams : PsKernelCoreList PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (isUnsafe : Bool) : PsKernelCoreAxiomInfo :=
  { base := { name := name, levelParams := levelParams, type := type }, isUnsafe := isUnsafe }

def psReferenceAdmissionAxiom
    (name : PSC1Kernel.Name)
    (levelParams : List PSC1Kernel.Name)
    (type : PSC1Kernel.Expr)
    (isUnsafe : Bool) : PSC1Kernel.AxiomInfo :=
  { base := { name := name, levelParams := levelParams, type := type }, isUnsafe := isUnsafe }

def psKernelCoreAdmissionDefinition
    (name : PsKernelCoreName)
    (levelParams : PsKernelCoreList PsKernelCoreName)
    (type value : PsKernelCoreExpr)
    (safety : PsKernelCoreDefinitionSafety) : PsKernelCoreDefinitionInfo :=
  {
    base := { name := name, levelParams := levelParams, type := type }
    value := value
    hints := PsKernelCoreReducibilityHints.regular 0
    safety := safety
  }

def psReferenceAdmissionDefinition
    (name : PSC1Kernel.Name)
    (levelParams : List PSC1Kernel.Name)
    (type value : PSC1Kernel.Expr)
    (safety : PSC1Kernel.DefinitionSafety) : PSC1Kernel.DefinitionInfo :=
  {
    base := { name := name, levelParams := levelParams, type := type }
    value := value
    hints := PSC1Kernel.ReducibilityHints.regular 0
    safety := safety
  }

def psKernelCoreAdmissionTheorem
    (name : PsKernelCoreName)
    (levelParams : PsKernelCoreList PsKernelCoreName)
    (type value : PsKernelCoreExpr) : PsKernelCoreTheoremInfo :=
  {
    base := { name := name, levelParams := levelParams, type := type }
    value := value
  }

def psReferenceAdmissionTheorem
    (name : PSC1Kernel.Name)
    (levelParams : List PSC1Kernel.Name)
    (type value : PSC1Kernel.Expr) : PSC1Kernel.TheoremInfo :=
  {
    base := { name := name, levelParams := levelParams, type := type }
    value := value
  }

def psKernelCoreAdmissionOpaque
    (name : PsKernelCoreName)
    (levelParams : PsKernelCoreList PsKernelCoreName)
    (type value : PsKernelCoreExpr)
    (isUnsafe : Bool) : PsKernelCoreOpaqueInfo :=
  {
    base := { name := name, levelParams := levelParams, type := type }
    value := value
    isUnsafe := isUnsafe
  }

def psReferenceAdmissionOpaque
    (name : PSC1Kernel.Name)
    (levelParams : List PSC1Kernel.Name)
    (type value : PSC1Kernel.Expr)
    (isUnsafe : Bool) : PSC1Kernel.OpaqueInfo :=
  {
    base := { name := name, levelParams := levelParams, type := type }
    value := value
    isUnsafe := isUnsafe
  }

def psKernelCoreAdmissionAccepted
    (result : PsKernelCoreResult String PsKernelCoreEnvironment)
    (name : PsKernelCoreName)
    (expectedSize : Nat) : Bool :=
  match result with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok env =>
      psKernelCoreEnvironmentContains env name &&
        Nat.beq (psKernelCoreEnvironmentSize env) expectedSize

def psReferenceAdmissionAccepted
    (result : Except String PSC1Kernel.Environment)
    (name : PSC1Kernel.Name)
    (expectedSize : Nat) : Bool :=
  match result with
  | Except.error _ => false
  | Except.ok env => env.contains name && env.size == expectedSize

def psKernelCoreAdmissionRejected
    (result : PsKernelCoreResult String PsKernelCoreEnvironment) : Bool :=
  match result with
  | PsKernelCoreResult.error _ => true
  | PsKernelCoreResult.ok _ => false

def psReferenceAdmissionRejected
    (result : Except String PSC1Kernel.Environment) : Bool :=
  match result with
  | Except.error _ => true
  | Except.ok _ => false

def psKernelCoreAdmissionExactError
    (result : PsKernelCoreResult String PsKernelCoreEnvironment)
    (expected : String) : Bool :=
  match result with
  | PsKernelCoreResult.error actual => actual == expected
  | PsKernelCoreResult.ok _ => false

def psKernelCoreAdmissionParity : Bool :=
  let budget := 96
  let kn := psKernelCoreAdmissionName
  let rn := psReferenceAdmissionName
  let kz := PsKernelCoreLevel.zero
  let k1 := PsKernelCoreLevel.succ kz
  let rz := PSC1Kernel.Level.zero
  let r1 := PSC1Kernel.Level.succ rz
  let ksort0 := PsKernelCoreExpr.sort kz
  let ksort1 := PsKernelCoreExpr.sort k1
  let rsort0 := PSC1Kernel.Expr.sort rz
  let rsort1 := PSC1Kernel.Expr.sort r1

  let kA := kn "A"
  let kP := kn "P"
  let ka := kn "a"
  let kp := kn "p"
  let ku := kn "u"
  let kv := kn "v"
  let kUnsafeA := kn "unsafeA"
  let kPartialA := kn "partialA"
  let kUnsafeP := kn "unsafeP"
  let rA := rn "A"
  let rP := rn "P"
  let ra := rn "a"
  let rp := rn "p"
  let ru := rn "u"
  let rv := rn "v"
  let rUnsafeA := rn "unsafeA"
  let rPartialA := rn "partialA"
  let rUnsafeP := rn "unsafeP"

  let kcA := PsKernelCoreExpr.const kA PsKernelCoreList.nil
  let kcP := PsKernelCoreExpr.const kP PsKernelCoreList.nil
  let kca := PsKernelCoreExpr.const ka PsKernelCoreList.nil
  let kcp := PsKernelCoreExpr.const kp PsKernelCoreList.nil
  let kUnsafeExpr := PsKernelCoreExpr.const kUnsafeA PsKernelCoreList.nil
  let kPartialExpr := PsKernelCoreExpr.const kPartialA PsKernelCoreList.nil
  let kUnsafePExpr := PsKernelCoreExpr.const kUnsafeP PsKernelCoreList.nil
  let rcA := PSC1Kernel.Expr.const rA []
  let rcP := PSC1Kernel.Expr.const rP []
  let rca := PSC1Kernel.Expr.const ra []
  let rcp := PSC1Kernel.Expr.const rp []
  let rUnsafeExpr := PSC1Kernel.Expr.const rUnsafeA []
  let rPartialExpr := PSC1Kernel.Expr.const rPartialA []
  let rUnsafePExpr := PSC1Kernel.Expr.const rUnsafeP []

  let kenv0 := psKernelCoreEnvironmentEmpty
  let renv0 := PSC1Kernel.Environment.empty
  let kenv1 := psKernelCoreEnvironmentAddUnchecked kenv0
    (PsKernelCoreConstantInfo.axiomInfo
      (psKernelCoreAdmissionAxiom kA PsKernelCoreList.nil ksort1 false))
  let renv1 := PSC1Kernel.Environment.addUnchecked renv0
    (PSC1Kernel.ConstantInfo.axiomInfo
      (psReferenceAdmissionAxiom rA [] rsort1 false))
  let kenv2 := psKernelCoreEnvironmentAddUnchecked kenv1
    (PsKernelCoreConstantInfo.axiomInfo
      (psKernelCoreAdmissionAxiom kP PsKernelCoreList.nil ksort0 false))
  let renv2 := PSC1Kernel.Environment.addUnchecked renv1
    (PSC1Kernel.ConstantInfo.axiomInfo
      (psReferenceAdmissionAxiom rP [] rsort0 false))
  let kenv3 := psKernelCoreEnvironmentAddUnchecked kenv2
    (PsKernelCoreConstantInfo.axiomInfo
      (psKernelCoreAdmissionAxiom ka PsKernelCoreList.nil kcA false))
  let renv3 := PSC1Kernel.Environment.addUnchecked renv2
    (PSC1Kernel.ConstantInfo.axiomInfo
      (psReferenceAdmissionAxiom ra [] rcA false))
  let kenv4 := psKernelCoreEnvironmentAddUnchecked kenv3
    (PsKernelCoreConstantInfo.axiomInfo
      (psKernelCoreAdmissionAxiom kp PsKernelCoreList.nil kcP false))
  let renv4 := PSC1Kernel.Environment.addUnchecked renv3
    (PSC1Kernel.ConstantInfo.axiomInfo
      (psReferenceAdmissionAxiom rp [] rcP false))
  let kenv5 := psKernelCoreEnvironmentAddUnchecked kenv4
    (PsKernelCoreConstantInfo.axiomInfo
      (psKernelCoreAdmissionAxiom kUnsafeA PsKernelCoreList.nil kcA true))
  let renv5 := PSC1Kernel.Environment.addUnchecked renv4
    (PSC1Kernel.ConstantInfo.axiomInfo
      (psReferenceAdmissionAxiom rUnsafeA [] rcA true))
  let kenv6 := psKernelCoreEnvironmentAddUnchecked kenv5
    (PsKernelCoreConstantInfo.defnInfo
      (psKernelCoreAdmissionDefinition kPartialA PsKernelCoreList.nil kcA kca
        PsKernelCoreDefinitionSafety.partialDef))
  let renv6 := PSC1Kernel.Environment.addUnchecked renv5
    (PSC1Kernel.ConstantInfo.defnInfo
      (psReferenceAdmissionDefinition rPartialA [] rcA rca
        PSC1Kernel.DefinitionSafety.partialDef))
  let kenv := psKernelCoreEnvironmentAddUnchecked kenv6
    (PsKernelCoreConstantInfo.axiomInfo
      (psKernelCoreAdmissionAxiom kUnsafeP PsKernelCoreList.nil kcP true))
  let renv := PSC1Kernel.Environment.addUnchecked renv6
    (PSC1Kernel.ConstantInfo.axiomInfo
      (psReferenceAdmissionAxiom rUnsafeP [] rcP true))
  let baseSize := psKernelCoreEnvironmentSize kenv
  let refBaseSize := renv.size

  let kAx := kn "ax"
  let rAx := rn "ax"
  let kUnsafeAx := kn "unsafeAx"
  let rUnsafeAx := rn "unsafeAx"
  let kDef := kn "def"
  let rDef := rn "def"
  let kPolyDef := kn "polyDef"
  let rPolyDef := rn "polyDef"
  let kThm := kn "thm"
  let rThm := rn "thm"
  let kOpaque := kn "opaque"
  let rOpaque := rn "opaque"
  let kSelf := kn "self"
  let rSelf := rn "self"

  let safeAxK := psKernelCoreAddAxiom budget kenv
    (psKernelCoreAdmissionAxiom kAx PsKernelCoreList.nil kcA false)
  let safeAxR := PSC1Kernel.Kernel.addAxiom renv
    (psReferenceAdmissionAxiom rAx [] rcA false)
  let unsafeAxK := psKernelCoreAddAxiom budget kenv
    (psKernelCoreAdmissionAxiom kUnsafeAx PsKernelCoreList.nil kcA true)
  let unsafeAxR := PSC1Kernel.Kernel.addAxiom renv
    (psReferenceAdmissionAxiom rUnsafeAx [] rcA true)
  let safeDefK := psKernelCoreAddDefinition budget kenv
    (psKernelCoreAdmissionDefinition kDef PsKernelCoreList.nil kcA kca
      PsKernelCoreDefinitionSafety.safe)
  let safeDefR := PSC1Kernel.Kernel.addDefinition renv
    (psReferenceAdmissionDefinition rDef [] rcA rca PSC1Kernel.DefinitionSafety.safe)

  let kpolyType := PsKernelCoreExpr.forallE (kn "T")
    (PsKernelCoreExpr.sort (PsKernelCoreLevel.param ku))
    (PsKernelCoreExpr.forallE (kn "x") (PsKernelCoreExpr.bvar 0)
      (PsKernelCoreExpr.bvar 1) PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.implicit
  let rpolyType := PSC1Kernel.Expr.forallE (rn "T")
    (PSC1Kernel.Expr.sort (PSC1Kernel.Level.param ru))
    (PSC1Kernel.Expr.forallE (rn "x") (PSC1Kernel.Expr.bvar 0)
      (PSC1Kernel.Expr.bvar 1) PSC1Kernel.BinderInfo.default)
    PSC1Kernel.BinderInfo.implicit
  let kpolyValue := PsKernelCoreExpr.lam (kn "T")
    (PsKernelCoreExpr.sort (PsKernelCoreLevel.param ku))
    (PsKernelCoreExpr.lam (kn "x") (PsKernelCoreExpr.bvar 0)
      (PsKernelCoreExpr.bvar 0) PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.implicit
  let rpolyValue := PSC1Kernel.Expr.lam (rn "T")
    (PSC1Kernel.Expr.sort (PSC1Kernel.Level.param ru))
    (PSC1Kernel.Expr.lam (rn "x") (PSC1Kernel.Expr.bvar 0)
      (PSC1Kernel.Expr.bvar 0) PSC1Kernel.BinderInfo.default)
    PSC1Kernel.BinderInfo.implicit
  let polyDefK := psKernelCoreAddDefinition budget kenv
    (psKernelCoreAdmissionDefinition kPolyDef (psKernelCoreAdmissionNameList1 ku)
      kpolyType kpolyValue PsKernelCoreDefinitionSafety.safe)
  let polyDefR := PSC1Kernel.Kernel.addDefinition renv
    (psReferenceAdmissionDefinition rPolyDef [ru] rpolyType rpolyValue
      PSC1Kernel.DefinitionSafety.safe)

  let theoremK := psKernelCoreAddTheorem budget kenv
    (psKernelCoreAdmissionTheorem kThm PsKernelCoreList.nil kcP kcp)
  let theoremR := PSC1Kernel.Kernel.addTheorem renv
    (psReferenceAdmissionTheorem rThm [] rcP rcp)
  let opaqueK := psKernelCoreAddOpaque budget kenv
    (psKernelCoreAdmissionOpaque kOpaque PsKernelCoreList.nil kcA kca false)
  let opaqueR := PSC1Kernel.Kernel.addOpaque renv
    (psReferenceAdmissionOpaque rOpaque [] rcA rca false)
  let kselfExpr := PsKernelCoreExpr.const kSelf PsKernelCoreList.nil
  let rselfExpr := PSC1Kernel.Expr.const rSelf []
  let unsafeSelfK := psKernelCoreAddDefinition budget kenv
    (psKernelCoreAdmissionDefinition kSelf PsKernelCoreList.nil kcA kselfExpr
      PsKernelCoreDefinitionSafety.unsafeDef)
  let unsafeSelfR := PSC1Kernel.Kernel.addDefinition renv
    (psReferenceAdmissionDefinition rSelf [] rcA rselfExpr
      PSC1Kernel.DefinitionSafety.unsafeDef)

  let dupK := psKernelCoreAddAxiom budget kenv
    (psKernelCoreAdmissionAxiom kA PsKernelCoreList.nil kcA false)
  let dupR := PSC1Kernel.Kernel.addAxiom renv
    (psReferenceAdmissionAxiom rA [] rcA false)
  let dupParamK := psKernelCoreAddAxiom budget kenv
    (psKernelCoreAdmissionAxiom (kn "dupParam")
      (psKernelCoreAdmissionNameList2 ku ku) ksort1 false)
  let dupParamR := PSC1Kernel.Kernel.addAxiom renv
    (psReferenceAdmissionAxiom (rn "dupParam") [ru, ru] rsort1 false)
  let nonadjK := psKernelCoreAddAxiom budget kenv
    (psKernelCoreAdmissionAxiom (kn "nonadj")
      (psKernelCoreAdmissionNameList3 ku kv ku) ksort1 false)
  let nonadjR := PSC1Kernel.Kernel.addAxiom renv
    (psReferenceAdmissionAxiom (rn "nonadj") [ru, rv, ru] rsort1 false)
  let typeMvarK := psKernelCoreAddAxiom budget kenv
    (psKernelCoreAdmissionAxiom (kn "typeM") PsKernelCoreList.nil
      (PsKernelCoreExpr.mvar (kn "m")) false)
  let typeMvarR := PSC1Kernel.Kernel.addAxiom renv
    (psReferenceAdmissionAxiom (rn "typeM") []
      (PSC1Kernel.Expr.mvar (rn "m")) false)
  let levelMvarK := psKernelCoreAddAxiom budget kenv
    (psKernelCoreAdmissionAxiom (kn "levelM") PsKernelCoreList.nil
      (PsKernelCoreExpr.sort (PsKernelCoreLevel.mvar (kn "lm"))) false)
  let levelMvarR := PSC1Kernel.Kernel.addAxiom renv
    (psReferenceAdmissionAxiom (rn "levelM") []
      (PSC1Kernel.Expr.sort (PSC1Kernel.Level.mvar (rn "lm"))) false)
  let freeTypeK := psKernelCoreAddAxiom budget kenv
    (psKernelCoreAdmissionAxiom (kn "freeType") PsKernelCoreList.nil
      (PsKernelCoreExpr.fvar (kn "free")) false)
  let freeTypeR := PSC1Kernel.Kernel.addAxiom renv
    (psReferenceAdmissionAxiom (rn "freeType") []
      (PSC1Kernel.Expr.fvar (rn "free")) false)
  let undefLevelK := psKernelCoreAddAxiom budget kenv
    (psKernelCoreAdmissionAxiom (kn "undefLevel") PsKernelCoreList.nil
      (PsKernelCoreExpr.sort (PsKernelCoreLevel.param ku)) false)
  let undefLevelR := PSC1Kernel.Kernel.addAxiom renv
    (psReferenceAdmissionAxiom (rn "undefLevel") []
      (PSC1Kernel.Expr.sort (PSC1Kernel.Level.param ru)) false)
  let notTypeK := psKernelCoreAddAxiom budget kenv
    (psKernelCoreAdmissionAxiom (kn "notType") PsKernelCoreList.nil kca false)
  let notTypeR := PSC1Kernel.Kernel.addAxiom renv
    (psReferenceAdmissionAxiom (rn "notType") [] rca false)

  let badDefMvarK := psKernelCoreAddDefinition budget kenv
    (psKernelCoreAdmissionDefinition (kn "badDefM") PsKernelCoreList.nil kcA
      (PsKernelCoreExpr.mvar (kn "m")) PsKernelCoreDefinitionSafety.safe)
  let badDefMvarR := PSC1Kernel.Kernel.addDefinition renv
    (psReferenceAdmissionDefinition (rn "badDefM") [] rcA
      (PSC1Kernel.Expr.mvar (rn "m")) PSC1Kernel.DefinitionSafety.safe)
  let badDefLevelK := psKernelCoreAddDefinition budget kenv
    (psKernelCoreAdmissionDefinition (kn "badDefLevel") PsKernelCoreList.nil ksort1
      (PsKernelCoreExpr.sort (PsKernelCoreLevel.mvar (kn "lm")))
      PsKernelCoreDefinitionSafety.safe)
  let badDefLevelR := PSC1Kernel.Kernel.addDefinition renv
    (psReferenceAdmissionDefinition (rn "badDefLevel") [] rsort1
      (PSC1Kernel.Expr.sort (PSC1Kernel.Level.mvar (rn "lm")))
      PSC1Kernel.DefinitionSafety.safe)
  let badDefFreeK := psKernelCoreAddDefinition budget kenv
    (psKernelCoreAdmissionDefinition (kn "badDefFree") PsKernelCoreList.nil kcA
      (PsKernelCoreExpr.fvar (kn "free")) PsKernelCoreDefinitionSafety.safe)
  let badDefFreeR := PSC1Kernel.Kernel.addDefinition renv
    (psReferenceAdmissionDefinition (rn "badDefFree") [] rcA
      (PSC1Kernel.Expr.fvar (rn "free")) PSC1Kernel.DefinitionSafety.safe)
  let badDefUndefK := psKernelCoreAddDefinition budget kenv
    (psKernelCoreAdmissionDefinition (kn "badDefU") PsKernelCoreList.nil ksort1
      (PsKernelCoreExpr.sort (PsKernelCoreLevel.param ku)) PsKernelCoreDefinitionSafety.safe)
  let badDefUndefR := PSC1Kernel.Kernel.addDefinition renv
    (psReferenceAdmissionDefinition (rn "badDefU") [] rsort1
      (PSC1Kernel.Expr.sort (PSC1Kernel.Level.param ru)) PSC1Kernel.DefinitionSafety.safe)
  let badDefMismatchK := psKernelCoreAddDefinition budget kenv
    (psKernelCoreAdmissionDefinition (kn "badDefMismatch") PsKernelCoreList.nil kcA kcp
      PsKernelCoreDefinitionSafety.safe)
  let badDefMismatchR := PSC1Kernel.Kernel.addDefinition renv
    (psReferenceAdmissionDefinition (rn "badDefMismatch") [] rcA rcp
      PSC1Kernel.DefinitionSafety.safe)
  let badDefUnsafeK := psKernelCoreAddDefinition budget kenv
    (psKernelCoreAdmissionDefinition (kn "badDefUnsafe") PsKernelCoreList.nil kcA kUnsafeExpr
      PsKernelCoreDefinitionSafety.safe)
  let badDefUnsafeR := PSC1Kernel.Kernel.addDefinition renv
    (psReferenceAdmissionDefinition (rn "badDefUnsafe") [] rcA rUnsafeExpr
      PSC1Kernel.DefinitionSafety.safe)
  let badDefPartialK := psKernelCoreAddDefinition budget kenv
    (psKernelCoreAdmissionDefinition (kn "badDefPartial") PsKernelCoreList.nil kcA kPartialExpr
      PsKernelCoreDefinitionSafety.safe)
  let badDefPartialR := PSC1Kernel.Kernel.addDefinition renv
    (psReferenceAdmissionDefinition (rn "badDefPartial") [] rcA rPartialExpr
      PSC1Kernel.DefinitionSafety.safe)
  let malformedSelfK := psKernelCoreAddDefinition budget kenv
    (psKernelCoreAdmissionDefinition (kn "badSelf") PsKernelCoreList.nil kcA
      (PsKernelCoreExpr.app (PsKernelCoreExpr.const (kn "badSelf") PsKernelCoreList.nil) kca)
      PsKernelCoreDefinitionSafety.unsafeDef)
  let malformedSelfR := PSC1Kernel.Kernel.addDefinition renv
    (psReferenceAdmissionDefinition (rn "badSelf") [] rcA
      (PSC1Kernel.Expr.app (PSC1Kernel.Expr.const (rn "badSelf") []) rca)
      PSC1Kernel.DefinitionSafety.unsafeDef)

  let nonPropThmK := psKernelCoreAddTheorem budget kenv
    (psKernelCoreAdmissionTheorem (kn "nonProp") PsKernelCoreList.nil kcA kca)
  let nonPropThmR := PSC1Kernel.Kernel.addTheorem renv
    (psReferenceAdmissionTheorem (rn "nonProp") [] rcA rca)
  let badProofK := psKernelCoreAddTheorem budget kenv
    (psKernelCoreAdmissionTheorem (kn "badProof") PsKernelCoreList.nil kcP kca)
  let badProofR := PSC1Kernel.Kernel.addTheorem renv
    (psReferenceAdmissionTheorem (rn "badProof") [] rcP rca)
  let unsafeProofK := psKernelCoreAddTheorem budget kenv
    (psKernelCoreAdmissionTheorem (kn "unsafeProof") PsKernelCoreList.nil kcP kUnsafePExpr)
  let unsafeProofR := PSC1Kernel.Kernel.addTheorem renv
    (psReferenceAdmissionTheorem (rn "unsafeProof") [] rcP rUnsafePExpr)

  let badOpaqueK := psKernelCoreAddOpaque budget kenv
    (psKernelCoreAdmissionOpaque (kn "badOpaque") PsKernelCoreList.nil kcA kcp false)
  let badOpaqueR := PSC1Kernel.Kernel.addOpaque renv
    (psReferenceAdmissionOpaque (rn "badOpaque") [] rcA rcp false)
  let unsafeOpaqueK := psKernelCoreAddOpaque budget kenv
    (psKernelCoreAdmissionOpaque (kn "unsafeOpaque") PsKernelCoreList.nil kcA kUnsafeExpr true)
  let unsafeOpaqueR := PSC1Kernel.Kernel.addOpaque renv
    (psReferenceAdmissionOpaque (rn "unsafeOpaque") [] rcA rUnsafeExpr true)

  let nestedLevelMvarTypeK := PsKernelCoreExpr.forallE (kn "x") ksort1
    (PsKernelCoreExpr.letE (kn "y") ksort1
      (PsKernelCoreExpr.sort (PsKernelCoreLevel.mvar (kn "nestedM")))
      ksort1 false) PsKernelCoreBinderInfo.default
  let nestedLevelMvarTypeR := PSC1Kernel.Expr.forallE (rn "x") rsort1
    (PSC1Kernel.Expr.letE (rn "y") rsort1
      (PSC1Kernel.Expr.sort (PSC1Kernel.Level.mvar (rn "nestedM")))
      rsort1 false) PSC1Kernel.BinderInfo.default
  let nestedLevelK := psKernelCoreAddAxiom budget kenv
    (psKernelCoreAdmissionAxiom (kn "nestedM") PsKernelCoreList.nil nestedLevelMvarTypeK false)
  let nestedLevelR := PSC1Kernel.Kernel.addAxiom renv
    (psReferenceAdmissionAxiom (rn "nestedM") [] nestedLevelMvarTypeR false)
  let nestedUndefTypeK := PsKernelCoreExpr.app
    (PsKernelCoreExpr.lam (kn "x") ksort1 ksort1 PsKernelCoreBinderInfo.default)
    (PsKernelCoreExpr.sort (PsKernelCoreLevel.param ku))
  let nestedUndefTypeR := PSC1Kernel.Expr.app
    (PSC1Kernel.Expr.lam (rn "x") rsort1 rsort1 PSC1Kernel.BinderInfo.default)
    (PSC1Kernel.Expr.sort (PSC1Kernel.Level.param ru))
  let nestedUndefK := psKernelCoreAddAxiom budget kenv
    (psKernelCoreAdmissionAxiom (kn "nestedU") PsKernelCoreList.nil nestedUndefTypeK false)
  let nestedUndefR := PSC1Kernel.Kernel.addAxiom renv
    (psReferenceAdmissionAxiom (rn "nestedU") [] nestedUndefTypeR false)

  psKernelCoreAdmissionAccepted safeAxK kAx (Nat.succ baseSize) &&
  psReferenceAdmissionAccepted safeAxR rAx (Nat.succ refBaseSize) &&
  psKernelCoreAdmissionAccepted unsafeAxK kUnsafeAx (Nat.succ baseSize) &&
  psReferenceAdmissionAccepted unsafeAxR rUnsafeAx (Nat.succ refBaseSize) &&
  psKernelCoreAdmissionAccepted safeDefK kDef (Nat.succ baseSize) &&
  psReferenceAdmissionAccepted safeDefR rDef (Nat.succ refBaseSize) &&
  psKernelCoreAdmissionAccepted polyDefK kPolyDef (Nat.succ baseSize) &&
  psReferenceAdmissionAccepted polyDefR rPolyDef (Nat.succ refBaseSize) &&
  psKernelCoreAdmissionAccepted theoremK kThm (Nat.succ baseSize) &&
  psReferenceAdmissionAccepted theoremR rThm (Nat.succ refBaseSize) &&
  psKernelCoreAdmissionAccepted opaqueK kOpaque (Nat.succ baseSize) &&
  psReferenceAdmissionAccepted opaqueR rOpaque (Nat.succ refBaseSize) &&
  psKernelCoreAdmissionAccepted unsafeSelfK kSelf (Nat.succ baseSize) &&
  psReferenceAdmissionAccepted unsafeSelfR rSelf (Nat.succ refBaseSize) &&
  psKernelCoreAdmissionExactError dupK "already declared" && psReferenceAdmissionRejected dupR &&
  psKernelCoreAdmissionExactError dupParamK "duplicate universe parameter" && psReferenceAdmissionRejected dupParamR &&
  psKernelCoreAdmissionExactError nonadjK "duplicate universe parameter" && psReferenceAdmissionRejected nonadjR &&
  psKernelCoreAdmissionExactError typeMvarK "declaration has metavariables" && psReferenceAdmissionRejected typeMvarR &&
  psKernelCoreAdmissionExactError levelMvarK "declaration has metavariables" && psReferenceAdmissionRejected levelMvarR &&
  psKernelCoreAdmissionExactError freeTypeK "declaration has free variables" && psReferenceAdmissionRejected freeTypeR &&
  psKernelCoreAdmissionExactError undefLevelK "invalid reference to undefined universe level parameter" && psReferenceAdmissionRejected undefLevelR &&
  psKernelCoreAdmissionRejected notTypeK && psReferenceAdmissionRejected notTypeR &&
  psKernelCoreAdmissionRejected badDefMvarK && psReferenceAdmissionRejected badDefMvarR &&
  psKernelCoreAdmissionRejected badDefLevelK && psReferenceAdmissionRejected badDefLevelR &&
  psKernelCoreAdmissionRejected badDefFreeK && psReferenceAdmissionRejected badDefFreeR &&
  psKernelCoreAdmissionRejected badDefUndefK && psReferenceAdmissionRejected badDefUndefR &&
  psKernelCoreAdmissionExactError badDefMismatchK "definition type mismatch" && psReferenceAdmissionRejected badDefMismatchR &&
  psKernelCoreAdmissionRejected badDefUnsafeK && psReferenceAdmissionRejected badDefUnsafeR &&
  psKernelCoreAdmissionRejected badDefPartialK && psReferenceAdmissionRejected badDefPartialR &&
  psKernelCoreAdmissionRejected malformedSelfK && psReferenceAdmissionRejected malformedSelfR &&
  psKernelCoreAdmissionExactError nonPropThmK "theorem type is not a proposition" && psReferenceAdmissionRejected nonPropThmR &&
  psKernelCoreAdmissionExactError badProofK "theorem proof type mismatch" && psReferenceAdmissionRejected badProofR &&
  psKernelCoreAdmissionRejected unsafeProofK && psReferenceAdmissionRejected unsafeProofR &&
  psKernelCoreAdmissionExactError badOpaqueK "opaque value type mismatch" && psReferenceAdmissionRejected badOpaqueR &&
  psKernelCoreAdmissionRejected unsafeOpaqueK && psReferenceAdmissionRejected unsafeOpaqueR &&
  psKernelCoreAdmissionExactError nestedLevelK "declaration has metavariables" && psReferenceAdmissionRejected nestedLevelR &&
  psKernelCoreAdmissionExactError nestedUndefK "invalid reference to undefined universe level parameter" && psReferenceAdmissionRejected nestedUndefR

def psKernelCoreAdmissionBoundaries : Bool :=
  let kn := psKernelCoreAdmissionName
  let kz := PsKernelCoreLevel.zero
  let k1 := PsKernelCoreLevel.succ kz
  let ksort1 := PsKernelCoreExpr.sort k1
  let kA := kn "A"
  let ka := kn "a"
  let kcA := PsKernelCoreExpr.const kA PsKernelCoreList.nil
  let kca := PsKernelCoreExpr.const ka PsKernelCoreList.nil
  let env0 := psKernelCoreEnvironmentEmpty
  let env1 := psKernelCoreEnvironmentAddUnchecked env0
    (PsKernelCoreConstantInfo.axiomInfo
      (psKernelCoreAdmissionAxiom kA PsKernelCoreList.nil ksort1 false))
  let env2 := psKernelCoreEnvironmentAddUnchecked env1
    (PsKernelCoreConstantInfo.axiomInfo
      (psKernelCoreAdmissionAxiom ka PsKernelCoreList.nil kcA false))
  let env := psKernelCoreEnvironmentMarkQuotInitialized env2
  let target := kn "target"
  let value := psKernelCoreAdmissionDefinition target PsKernelCoreList.nil kcA kca
    PsKernelCoreDefinitionSafety.safe
  let zeroBudget := psKernelCoreAdmissionExactError
    (psKernelCoreAddDefinition 0 env value) "admission budget exhausted"
  let lowBudgetRejects := psKernelCoreAdmissionRejected (psKernelCoreAddDefinition 1 env value)
  let sufficientBudgetAccepts :=
    match psKernelCoreAddDefinition 8 env value with
    | PsKernelCoreResult.error _ => false
    | PsKernelCoreResult.ok out =>
        psKernelCoreEnvironmentContains out target && out.quotInitialized
  let rejected := psKernelCoreAddDefinition 64 env
    (psKernelCoreAdmissionDefinition (kn "bad") PsKernelCoreList.nil kcA
      (PsKernelCoreExpr.mvar (kn "m")) PsKernelCoreDefinitionSafety.safe)
  let originalPreserved :=
    psKernelCoreAdmissionRejected rejected &&
    Nat.beq (psKernelCoreEnvironmentSize env) 2 &&
    psKernelCoreEnvironmentContains env kA &&
    psKernelCoreEnvironmentContains env ka &&
    (!psKernelCoreEnvironmentContains env (kn "bad")) &&
    env.quotInitialized
  zeroBudget && lowBudgetRejects && sufficientBudgetAccepts && originalPreserved

def main : IO Unit := do
  if !psKernelCoreAdmissionParity then
    throw (IO.userError "PSC2_KERNEL_CORE_ADMISSION_PARITY: DIFFERENTIAL FAIL")
  if !psKernelCoreAdmissionBoundaries then
    throw (IO.userError "PSC2_KERNEL_CORE_ADMISSION_PARITY: BOUNDARY FAIL")
  IO.println "PSC2_KERNEL_CORE_ADMISSION_PARITY: PASS"
