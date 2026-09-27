import Ps.KernelCore.Reduce
import PSC1Kernel.TypeChecker

partial def psKernelCoreReductionNameMatches
    (left : PsKernelCoreName)
    (right : PSC1Kernel.Name) : Bool :=
  match left, right with
  | PsKernelCoreName.anonymous, PSC1Kernel.Name.anonymous => true
  | PsKernelCoreName.str lp ls, PSC1Kernel.Name.str rp rs =>
      psKernelCoreReductionNameMatches lp rp && ls == rs
  | PsKernelCoreName.num lp ln, PSC1Kernel.Name.num rp rn =>
      psKernelCoreReductionNameMatches lp rp && ln == rn
  | _, _ => false

partial def psKernelCoreReductionLevelMatches
    (left : PsKernelCoreLevel)
    (right : PSC1Kernel.Level) : Bool :=
  match left, right with
  | PsKernelCoreLevel.zero, PSC1Kernel.Level.zero => true
  | PsKernelCoreLevel.succ l, PSC1Kernel.Level.succ r =>
      psKernelCoreReductionLevelMatches l r
  | PsKernelCoreLevel.max la lb, PSC1Kernel.Level.max ra rb =>
      psKernelCoreReductionLevelMatches la ra &&
        psKernelCoreReductionLevelMatches lb rb
  | PsKernelCoreLevel.imax la lb, PSC1Kernel.Level.imax ra rb =>
      psKernelCoreReductionLevelMatches la ra &&
        psKernelCoreReductionLevelMatches lb rb
  | PsKernelCoreLevel.param l, PSC1Kernel.Level.param r =>
      psKernelCoreReductionNameMatches l r
  | PsKernelCoreLevel.mvar l, PSC1Kernel.Level.mvar r =>
      psKernelCoreReductionNameMatches l r
  | _, _ => false

partial def psKernelCoreReductionLevelListMatches
    (left : PsKernelCoreList PsKernelCoreLevel)
    (right : List PSC1Kernel.Level) : Bool :=
  match left, right with
  | PsKernelCoreList.nil, [] => true
  | PsKernelCoreList.cons lh lt, rh :: rt =>
      psKernelCoreReductionLevelMatches lh rh &&
        psKernelCoreReductionLevelListMatches lt rt
  | _, _ => false

def psKernelCoreReductionBinderMatches
    (left : PsKernelCoreBinderInfo)
    (right : PSC1Kernel.BinderInfo) : Bool :=
  match left, right with
  | PsKernelCoreBinderInfo.default, PSC1Kernel.BinderInfo.default => true
  | PsKernelCoreBinderInfo.implicit, PSC1Kernel.BinderInfo.implicit => true
  | PsKernelCoreBinderInfo.strictImplicit, PSC1Kernel.BinderInfo.strictImplicit => true
  | PsKernelCoreBinderInfo.instImplicit, PSC1Kernel.BinderInfo.instImplicit => true
  | _, _ => false

def psKernelCoreReductionLiteralMatches
    (left : PsKernelCoreLiteral)
    (right : PSC1Kernel.Literal) : Bool :=
  match left, right with
  | PsKernelCoreLiteral.nat l, PSC1Kernel.Literal.nat r => l == r
  | PsKernelCoreLiteral.str l, PSC1Kernel.Literal.str r => l == r
  | _, _ => false

partial def psKernelCoreReductionExprMatches
    (left : PsKernelCoreExpr)
    (right : PSC1Kernel.Expr) : Bool :=
  match left, right with
  | PsKernelCoreExpr.bvar l, PSC1Kernel.Expr.bvar r => l == r
  | PsKernelCoreExpr.fvar l, PSC1Kernel.Expr.fvar r =>
      psKernelCoreReductionNameMatches l r
  | PsKernelCoreExpr.mvar l, PSC1Kernel.Expr.mvar r =>
      psKernelCoreReductionNameMatches l r
  | PsKernelCoreExpr.sort l, PSC1Kernel.Expr.sort r =>
      psKernelCoreReductionLevelMatches l r
  | PsKernelCoreExpr.const ln ll, PSC1Kernel.Expr.const rn rl =>
      psKernelCoreReductionNameMatches ln rn &&
        psKernelCoreReductionLevelListMatches ll rl
  | PsKernelCoreExpr.app lf la, PSC1Kernel.Expr.app rf ra =>
      psKernelCoreReductionExprMatches lf rf &&
        psKernelCoreReductionExprMatches la ra
  | PsKernelCoreExpr.lam ln lt lb li, PSC1Kernel.Expr.lam rn rt rb ri =>
      psKernelCoreReductionNameMatches ln rn &&
        psKernelCoreReductionExprMatches lt rt &&
        psKernelCoreReductionExprMatches lb rb &&
        psKernelCoreReductionBinderMatches li ri
  | PsKernelCoreExpr.forallE ln lt lb li, PSC1Kernel.Expr.forallE rn rt rb ri =>
      psKernelCoreReductionNameMatches ln rn &&
        psKernelCoreReductionExprMatches lt rt &&
        psKernelCoreReductionExprMatches lb rb &&
        psKernelCoreReductionBinderMatches li ri
  | PsKernelCoreExpr.letE ln lt lv lb lnd,
      PSC1Kernel.Expr.letE rn rt rv rb rnd =>
      psKernelCoreReductionNameMatches ln rn &&
        psKernelCoreReductionExprMatches lt rt &&
        psKernelCoreReductionExprMatches lv rv &&
        psKernelCoreReductionExprMatches lb rb &&
        lnd == rnd
  | PsKernelCoreExpr.lit l, PSC1Kernel.Expr.lit r =>
      psKernelCoreReductionLiteralMatches l r
  | PsKernelCoreExpr.mdata lm le, PSC1Kernel.Expr.mdata rm re =>
      lm == rm && psKernelCoreReductionExprMatches le re
  | PsKernelCoreExpr.proj ln li le, PSC1Kernel.Expr.proj rn ri re =>
      psKernelCoreReductionNameMatches ln rn && li == ri &&
        psKernelCoreReductionExprMatches le re
  | _, _ => false

def psKernelCoreReductionName (value : String) : PsKernelCoreName :=
  PsKernelCoreName.str PsKernelCoreName.anonymous value

def psReferenceReductionName (value : String) : PSC1Kernel.Name :=
  PSC1Kernel.Name.str PSC1Kernel.Name.anonymous value

def psKernelCoreReductionLevelList1
    (value : PsKernelCoreLevel) : PsKernelCoreList PsKernelCoreLevel :=
  PsKernelCoreList.cons value PsKernelCoreList.nil

def psKernelCoreReductionNameList1
    (value : PsKernelCoreName) : PsKernelCoreList PsKernelCoreName :=
  PsKernelCoreList.cons value PsKernelCoreList.nil

def psKernelCoreReductionDefinition
    (name : PsKernelCoreName)
    (levelParams : PsKernelCoreList PsKernelCoreName)
    (value : PsKernelCoreExpr) : PsKernelCoreConstantInfo :=
  PsKernelCoreConstantInfo.defnInfo {
    base := {
      name := name
      levelParams := levelParams
      type := PsKernelCoreExpr.sort PsKernelCoreLevel.zero
    }
    value := value
    hints := PsKernelCoreReducibilityHints.regular 0
    safety := PsKernelCoreDefinitionSafety.safe
  }

def psReferenceReductionDefinition
    (name : PSC1Kernel.Name)
    (levelParams : List PSC1Kernel.Name)
    (value : PSC1Kernel.Expr) : PSC1Kernel.ConstantInfo :=
  PSC1Kernel.ConstantInfo.defnInfo {
    base := {
      name := name
      levelParams := levelParams
      type := PSC1Kernel.Expr.sort PSC1Kernel.Level.zero
    }
    value := value
    hints := PSC1Kernel.ReducibilityHints.regular 0
    safety := PSC1Kernel.DefinitionSafety.safe
  }

def psKernelCoreReductionAxiom
    (name : PsKernelCoreName) : PsKernelCoreConstantInfo :=
  PsKernelCoreConstantInfo.axiomInfo {
    base := {
      name := name
      levelParams := PsKernelCoreList.nil
      type := PsKernelCoreExpr.sort PsKernelCoreLevel.zero
    }
    isUnsafe := false
  }

def psReferenceReductionAxiom
    (name : PSC1Kernel.Name) : PSC1Kernel.ConstantInfo :=
  PSC1Kernel.ConstantInfo.axiomInfo {
    base := {
      name := name
      levelParams := []
      type := PSC1Kernel.Expr.sort PSC1Kernel.Level.zero
    }
    isUnsafe := false
  }

def psKernelCoreReductionTheorem
    (name : PsKernelCoreName)
    (value : PsKernelCoreExpr) : PsKernelCoreConstantInfo :=
  PsKernelCoreConstantInfo.thmInfo {
    base := {
      name := name
      levelParams := PsKernelCoreList.nil
      type := PsKernelCoreExpr.sort PsKernelCoreLevel.zero
    }
    value := value
  }

def psReferenceReductionTheorem
    (name : PSC1Kernel.Name)
    (value : PSC1Kernel.Expr) : PSC1Kernel.ConstantInfo :=
  PSC1Kernel.ConstantInfo.thmInfo {
    base := {
      name := name
      levelParams := []
      type := PSC1Kernel.Expr.sort PSC1Kernel.Level.zero
    }
    value := value
  }

def psKernelCoreReductionOpaque
    (name : PsKernelCoreName)
    (value : PsKernelCoreExpr) : PsKernelCoreConstantInfo :=
  PsKernelCoreConstantInfo.opaqueInfo {
    base := {
      name := name
      levelParams := PsKernelCoreList.nil
      type := PsKernelCoreExpr.sort PsKernelCoreLevel.zero
    }
    value := value
    isUnsafe := false
  }

def psReferenceReductionOpaque
    (name : PSC1Kernel.Name)
    (value : PSC1Kernel.Expr) : PSC1Kernel.ConstantInfo :=
  PSC1Kernel.ConstantInfo.opaqueInfo {
    base := {
      name := name
      levelParams := []
      type := PSC1Kernel.Expr.sort PSC1Kernel.Level.zero
    }
    value := value
    isUnsafe := false
  }

def psKernelCoreReductionResultMatches
    (kernelResult : PsKernelCoreResult String PsKernelCoreExpr)
    (referenceResult : Except String PSC1Kernel.Expr) : Bool :=
  match kernelResult, referenceResult with
  | PsKernelCoreResult.error left, Except.error right => left == right
  | PsKernelCoreResult.ok left, Except.ok right =>
      psKernelCoreReductionExprMatches left right
  | _, _ => false

def psKernelCoreReductionRunMatches
    (budget : Nat)
    (kernelEnv : PsKernelCoreEnvironment)
    (kernelLctx : PsKernelCoreLocalContext)
    (kernelExpr : PsKernelCoreExpr)
    (referenceEnv : PSC1Kernel.Environment)
    (referenceLctx : PSC1Kernel.LocalContext)
    (referenceExpr : PSC1Kernel.Expr) : Bool :=
  let referenceCtx := {
    PSC1Kernel.CheckerContext.empty referenceEnv with
    lctx := referenceLctx
  }
  psKernelCoreReductionResultMatches
    (psKernelCoreWhnf budget kernelEnv kernelLctx kernelExpr)
    (PSC1Kernel.whnf referenceCtx referenceExpr)

def psKernelCoreReductionParity : Bool :=
  let kx := psKernelCoreReductionName "x"
  let ky := psKernelCoreReductionName "y"
  let ka := psKernelCoreReductionName "a"
  let ku := psKernelCoreReductionName "u"
  let kid := psKernelCoreReductionName "id"
  let kpoly := psKernelCoreReductionName "poly"
  let knested := psKernelCoreReductionName "nested"
  let kthm := psKernelCoreReductionName "thm"
  let kopq := psKernelCoreReductionName "opq"
  let kax := psKernelCoreReductionName "ax"
  let kmissing := psKernelCoreReductionName "missing"
  let kf := psKernelCoreReductionName "f"
  let kc := psKernelCoreReductionName "C"
  let kd := psKernelCoreReductionName "D"
  let kp := psKernelCoreReductionName "P"
  let rz := psReferenceReductionName "x"
  let ry := psReferenceReductionName "y"
  let ra := psReferenceReductionName "a"
  let ru := psReferenceReductionName "u"
  let rid := psReferenceReductionName "id"
  let rpoly := psReferenceReductionName "poly"
  let rnested := psReferenceReductionName "nested"
  let rthm := psReferenceReductionName "thm"
  let ropq := psReferenceReductionName "opq"
  let rax := psReferenceReductionName "ax"
  let rmissing := psReferenceReductionName "missing"
  let rf := psReferenceReductionName "f"
  let rc := psReferenceReductionName "C"
  let rd := psReferenceReductionName "D"
  let rp := psReferenceReductionName "P"
  let ksort0 := PsKernelCoreExpr.sort PsKernelCoreLevel.zero
  let rsort0 := PSC1Kernel.Expr.sort PSC1Kernel.Level.zero
  let klit7 := PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat 7)
  let rlit7 := PSC1Kernel.Expr.lit (PSC1Kernel.Literal.nat 7)
  let kempty := psKernelCoreEnvironmentEmpty
  let rempty := PSC1Kernel.Environment.empty
  let klctxEmpty := psKernelCoreLocalContextEmpty
  let rlctxEmpty := PSC1Kernel.LocalContext.empty
  let budget := 64

  let keasy := ksort0
  let reasy := rsort0
  let kmdata := PsKernelCoreExpr.mdata 5 ksort0
  let rmdata := PSC1Kernel.Expr.mdata 5 rsort0
  let klet := PsKernelCoreExpr.letE kx ksort0 klit7 (PsKernelCoreExpr.bvar 0) false
  let rlet := PSC1Kernel.Expr.letE rz rsort0 rlit7 (PSC1Kernel.Expr.bvar 0) false
  let kidLam := PsKernelCoreExpr.lam kx ksort0 (PsKernelCoreExpr.bvar 0) PsKernelCoreBinderInfo.default
  let ridLam := PSC1Kernel.Expr.lam rz rsort0 (PSC1Kernel.Expr.bvar 0) PSC1Kernel.BinderInfo.default
  let kbeta := PsKernelCoreExpr.app kidLam klit7
  let rbeta := PSC1Kernel.Expr.app ridLam rlit7
  let kouter :=
    PsKernelCoreExpr.lam kx ksort0
      (PsKernelCoreExpr.lam ky ksort0 (PsKernelCoreExpr.bvar 1) PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default
  let router :=
    PSC1Kernel.Expr.lam rz rsort0
      (PSC1Kernel.Expr.lam ry rsort0 (PSC1Kernel.Expr.bvar 1) PSC1Kernel.BinderInfo.default)
      PSC1Kernel.BinderInfo.default
  let knestedBeta := PsKernelCoreExpr.app (PsKernelCoreExpr.app kouter klit7) (PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat 8))
  let rnestedBeta := PSC1Kernel.Expr.app (PSC1Kernel.Expr.app router rlit7) (PSC1Kernel.Expr.lit (PSC1Kernel.Literal.nat 8))
  let kcapture := PsKernelCoreExpr.app kouter klit7
  let rcapture := PSC1Kernel.Expr.app router rlit7
  let klazyArg := PsKernelCoreExpr.mdata 99 klit7
  let rlazyArg := PSC1Kernel.Expr.mdata 99 rlit7
  let klazy := PsKernelCoreExpr.app (PsKernelCoreExpr.const kmissing PsKernelCoreList.nil) klazyArg
  let rlazy := PSC1Kernel.Expr.app (PSC1Kernel.Expr.const rmissing []) rlazyArg

  let klctxLet := psKernelCoreLocalContextAddLet klctxEmpty kx kx ksort0 klit7
  let rlctxLet := PSC1Kernel.LocalContext.addLet rlctxEmpty rz rz rsort0 rlit7
  let klctxLocal := psKernelCoreLocalContextAddLocal klctxEmpty kx kx ksort0 PsKernelCoreBinderInfo.default
  let rlctxLocal := PSC1Kernel.LocalContext.addLocal rlctxEmpty rz rz rsort0 PSC1Kernel.BinderInfo.default

  let kdefSeven := psKernelCoreReductionDefinition ka PsKernelCoreList.nil klit7
  let rdefSeven := psReferenceReductionDefinition ra [] rlit7
  let kenvDef := psKernelCoreEnvironmentAddUnchecked kempty kdefSeven
  let renvDef := PSC1Kernel.Environment.addUnchecked rempty rdefSeven
  let kdelta := PsKernelCoreExpr.const ka PsKernelCoreList.nil
  let rdelta := PSC1Kernel.Expr.const ra []

  let kdefId := psKernelCoreReductionDefinition kid PsKernelCoreList.nil kidLam
  let rdefId := psReferenceReductionDefinition rid [] ridLam
  let kenvId := psKernelCoreEnvironmentAddUnchecked kempty kdefId
  let renvId := PSC1Kernel.Environment.addUnchecked rempty rdefId
  let kdeltaBeta := PsKernelCoreExpr.app (PsKernelCoreExpr.const kid PsKernelCoreList.nil) klit7
  let rdeltaBeta := PSC1Kernel.Expr.app (PSC1Kernel.Expr.const rid []) rlit7

  let kpolyValue := PsKernelCoreExpr.sort (PsKernelCoreLevel.param ku)
  let rpolyValue := PSC1Kernel.Expr.sort (PSC1Kernel.Level.param ru)
  let kdefPoly := psKernelCoreReductionDefinition kpoly (psKernelCoreReductionNameList1 ku) kpolyValue
  let rdefPoly := psReferenceReductionDefinition rpoly [ru] rpolyValue
  let kenvPoly := psKernelCoreEnvironmentAddUnchecked kempty kdefPoly
  let renvPoly := PSC1Kernel.Environment.addUnchecked rempty rdefPoly
  let klevel1 := PsKernelCoreLevel.succ PsKernelCoreLevel.zero
  let rlevel1 := PSC1Kernel.Level.succ PSC1Kernel.Level.zero
  let kpolyUse := PsKernelCoreExpr.const kpoly (psKernelCoreReductionLevelList1 klevel1)
  let rpolyUse := PSC1Kernel.Expr.const rpoly [rlevel1]
  let kpolyMismatch := PsKernelCoreExpr.const kpoly PsKernelCoreList.nil
  let rpolyMismatch := PSC1Kernel.Expr.const rpoly []

  let knestedValue :=
    PsKernelCoreExpr.lam kx (PsKernelCoreExpr.sort (PsKernelCoreLevel.param ku))
      (PsKernelCoreExpr.forallE ky
        (PsKernelCoreExpr.const kc (psKernelCoreReductionLevelList1 (PsKernelCoreLevel.param ku)))
        (PsKernelCoreExpr.letE ka
          (PsKernelCoreExpr.sort (PsKernelCoreLevel.param ku))
          (PsKernelCoreExpr.const kd (psKernelCoreReductionLevelList1 (PsKernelCoreLevel.param ku)))
          (PsKernelCoreExpr.mdata 9
            (PsKernelCoreExpr.proj kp 1
              (PsKernelCoreExpr.app
                (PsKernelCoreExpr.const kf (psKernelCoreReductionLevelList1 (PsKernelCoreLevel.param ku)))
                (PsKernelCoreExpr.sort (PsKernelCoreLevel.param ku)))))
          false)
        PsKernelCoreBinderInfo.implicit)
      PsKernelCoreBinderInfo.default
  let rnestedValue :=
    PSC1Kernel.Expr.lam rz (PSC1Kernel.Expr.sort (PSC1Kernel.Level.param ru))
      (PSC1Kernel.Expr.forallE ry
        (PSC1Kernel.Expr.const rc [PSC1Kernel.Level.param ru])
        (PSC1Kernel.Expr.letE ra
          (PSC1Kernel.Expr.sort (PSC1Kernel.Level.param ru))
          (PSC1Kernel.Expr.const rd [PSC1Kernel.Level.param ru])
          (PSC1Kernel.Expr.mdata 9
            (PSC1Kernel.Expr.proj rp 1
              (PSC1Kernel.Expr.app
                (PSC1Kernel.Expr.const rf [PSC1Kernel.Level.param ru])
                (PSC1Kernel.Expr.sort (PSC1Kernel.Level.param ru)))))
          false)
        PSC1Kernel.BinderInfo.implicit)
      PSC1Kernel.BinderInfo.default
  let kdefNested := psKernelCoreReductionDefinition knested (psKernelCoreReductionNameList1 ku) knestedValue
  let rdefNested := psReferenceReductionDefinition rnested [ru] rnestedValue
  let kenvNested := psKernelCoreEnvironmentAddUnchecked kempty kdefNested
  let renvNested := PSC1Kernel.Environment.addUnchecked rempty rdefNested
  let knestedUse := PsKernelCoreExpr.const knested (psKernelCoreReductionLevelList1 klevel1)
  let rnestedUse := PSC1Kernel.Expr.const rnested [rlevel1]

  let kthmInfo := psKernelCoreReductionTheorem kthm klit7
  let rthmInfo := psReferenceReductionTheorem rthm rlit7
  let kenvThm := psKernelCoreEnvironmentAddUnchecked kempty kthmInfo
  let renvThm := PSC1Kernel.Environment.addUnchecked rempty rthmInfo
  let kopqInfo := psKernelCoreReductionOpaque kopq klit7
  let ropqInfo := psReferenceReductionOpaque ropq rlit7
  let kenvOpq := psKernelCoreEnvironmentAddUnchecked kempty kopqInfo
  let renvOpq := PSC1Kernel.Environment.addUnchecked rempty ropqInfo
  let kaxInfo := psKernelCoreReductionAxiom kax
  let raxInfo := psReferenceReductionAxiom rax
  let kenvAx := psKernelCoreEnvironmentAddUnchecked kempty kaxInfo
  let renvAx := PSC1Kernel.Environment.addUnchecked rempty raxInfo

  let kproj := PsKernelCoreExpr.proj kp 0 klet
  let rproj := PSC1Kernel.Expr.proj rp 0 rlet

  psKernelCoreReductionRunMatches budget kempty klctxEmpty keasy rempty rlctxEmpty reasy &&
  psKernelCoreReductionRunMatches budget kempty klctxEmpty kmdata rempty rlctxEmpty rmdata &&
  psKernelCoreReductionRunMatches budget kempty klctxEmpty klet rempty rlctxEmpty rlet &&
  psKernelCoreReductionRunMatches budget kempty klctxEmpty kbeta rempty rlctxEmpty rbeta &&
  psKernelCoreReductionRunMatches budget kempty klctxEmpty knestedBeta rempty rlctxEmpty rnestedBeta &&
  psKernelCoreReductionRunMatches budget kempty klctxEmpty kcapture rempty rlctxEmpty rcapture &&
  psKernelCoreReductionRunMatches budget kempty klctxEmpty klazy rempty rlctxEmpty rlazy &&
  psKernelCoreReductionRunMatches budget kempty klctxLet (PsKernelCoreExpr.fvar kx) rempty rlctxLet (PSC1Kernel.Expr.fvar rz) &&
  psKernelCoreReductionRunMatches budget kempty klctxLocal (PsKernelCoreExpr.fvar kx) rempty rlctxLocal (PSC1Kernel.Expr.fvar rz) &&
  psKernelCoreReductionRunMatches budget kenvDef klctxEmpty kdelta renvDef rlctxEmpty rdelta &&
  psKernelCoreReductionRunMatches budget kenvId klctxEmpty kdeltaBeta renvId rlctxEmpty rdeltaBeta &&
  psKernelCoreReductionRunMatches budget kenvPoly klctxEmpty kpolyUse renvPoly rlctxEmpty rpolyUse &&
  psKernelCoreReductionRunMatches budget kenvNested klctxEmpty knestedUse renvNested rlctxEmpty rnestedUse &&
  psKernelCoreReductionRunMatches budget kenvPoly klctxEmpty kpolyMismatch renvPoly rlctxEmpty rpolyMismatch &&
  psKernelCoreReductionRunMatches budget kenvThm klctxEmpty (PsKernelCoreExpr.const kthm PsKernelCoreList.nil) renvThm rlctxEmpty (PSC1Kernel.Expr.const rthm []) &&
  psKernelCoreReductionRunMatches budget kenvOpq klctxEmpty (PsKernelCoreExpr.const kopq PsKernelCoreList.nil) renvOpq rlctxEmpty (PSC1Kernel.Expr.const ropq []) &&
  psKernelCoreReductionRunMatches budget kenvAx klctxEmpty (PsKernelCoreExpr.const kax PsKernelCoreList.nil) renvAx rlctxEmpty (PSC1Kernel.Expr.const rax []) &&
  psKernelCoreReductionRunMatches budget kempty klctxEmpty (PsKernelCoreExpr.const kmissing PsKernelCoreList.nil) rempty rlctxEmpty (PSC1Kernel.Expr.const rmissing []) &&
  psKernelCoreReductionRunMatches budget kempty klctxEmpty kproj rempty rlctxEmpty rproj

def psKernelCoreReductionBudgetParity : Bool :=
  let emptyEnv := psKernelCoreEnvironmentEmpty
  let emptyLctx := psKernelCoreLocalContextEmpty
  let value := PsKernelCoreExpr.sort PsKernelCoreLevel.zero
  let expr := PsKernelCoreExpr.mdata 1 value
  let zeroFails :=
    match psKernelCoreWhnf 0 emptyEnv emptyLctx value with
    | PsKernelCoreResult.error message => message == "reduction budget exhausted"
    | PsKernelCoreResult.ok _ => false
  let oneFails :=
    match psKernelCoreWhnf 1 emptyEnv emptyLctx expr with
    | PsKernelCoreResult.error message => message == "reduction budget exhausted"
    | PsKernelCoreResult.ok _ => false
  let twoSucceeds :=
    match psKernelCoreWhnf 2 emptyEnv emptyLctx expr with
    | PsKernelCoreResult.error _ => false
    | PsKernelCoreResult.ok reduced =>
        psKernelCoreReductionExprMatches reduced (PSC1Kernel.Expr.sort PSC1Kernel.Level.zero)
  zeroFails && oneFails && twoSucceeds

def main : IO Unit := do
  if !psKernelCoreReductionParity then
    throw (IO.userError "PSC2_KERNEL_CORE_REDUCTION_PARITY: DIFFERENTIAL FAIL")
  if !psKernelCoreReductionBudgetParity then
    throw (IO.userError "PSC2_KERNEL_CORE_REDUCTION_PARITY: BUDGET FAIL")
  IO.println "PSC2_KERNEL_CORE_REDUCTION_PARITY: PASS"
