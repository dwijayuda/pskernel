import Ps.KernelCore.Infer
import PSC1Kernel.TypeChecker

partial def psKernelCoreInferTestLevelListEq
    (left right : PsKernelCoreList PsKernelCoreLevel) : Bool :=
  match left, right with
  | PsKernelCoreList.nil, PsKernelCoreList.nil => true
  | PsKernelCoreList.cons lh lt, PsKernelCoreList.cons rh rt =>
      psKernelCoreLevelEq lh rh && psKernelCoreInferTestLevelListEq lt rt
  | _, _ => false

def psKernelCoreInferTestBinderEq
    (left right : PsKernelCoreBinderInfo) : Bool :=
  match left, right with
  | PsKernelCoreBinderInfo.default, PsKernelCoreBinderInfo.default => true
  | PsKernelCoreBinderInfo.implicit, PsKernelCoreBinderInfo.implicit => true
  | PsKernelCoreBinderInfo.strictImplicit, PsKernelCoreBinderInfo.strictImplicit => true
  | PsKernelCoreBinderInfo.instImplicit, PsKernelCoreBinderInfo.instImplicit => true
  | _, _ => false

def psKernelCoreInferTestLiteralEq
    (left right : PsKernelCoreLiteral) : Bool :=
  match left, right with
  | PsKernelCoreLiteral.nat l, PsKernelCoreLiteral.nat r => l == r
  | PsKernelCoreLiteral.str l, PsKernelCoreLiteral.str r => l == r
  | _, _ => false

partial def psKernelCoreInferTestExprEq
    (left right : PsKernelCoreExpr) : Bool :=
  match left, right with
  | PsKernelCoreExpr.bvar l, PsKernelCoreExpr.bvar r => l == r
  | PsKernelCoreExpr.fvar l, PsKernelCoreExpr.fvar r => psKernelCoreNameEq l r
  | PsKernelCoreExpr.mvar l, PsKernelCoreExpr.mvar r => psKernelCoreNameEq l r
  | PsKernelCoreExpr.sort l, PsKernelCoreExpr.sort r => psKernelCoreLevelEq l r
  | PsKernelCoreExpr.const ln ll, PsKernelCoreExpr.const rn rl =>
      psKernelCoreNameEq ln rn && psKernelCoreInferTestLevelListEq ll rl
  | PsKernelCoreExpr.app lf la, PsKernelCoreExpr.app rf ra =>
      psKernelCoreInferTestExprEq lf rf && psKernelCoreInferTestExprEq la ra
  | PsKernelCoreExpr.lam ln lt lb li, PsKernelCoreExpr.lam rn rt rb ri =>
      psKernelCoreNameEq ln rn &&
        psKernelCoreInferTestExprEq lt rt &&
        psKernelCoreInferTestExprEq lb rb &&
        psKernelCoreInferTestBinderEq li ri
  | PsKernelCoreExpr.forallE ln lt lb li, PsKernelCoreExpr.forallE rn rt rb ri =>
      psKernelCoreNameEq ln rn &&
        psKernelCoreInferTestExprEq lt rt &&
        psKernelCoreInferTestExprEq lb rb &&
        psKernelCoreInferTestBinderEq li ri
  | PsKernelCoreExpr.letE ln lt lv lb lnd,
      PsKernelCoreExpr.letE rn rt rv rb rnd =>
      psKernelCoreNameEq ln rn &&
        psKernelCoreInferTestExprEq lt rt &&
        psKernelCoreInferTestExprEq lv rv &&
        psKernelCoreInferTestExprEq lb rb &&
        lnd == rnd
  | PsKernelCoreExpr.lit l, PsKernelCoreExpr.lit r =>
      psKernelCoreInferTestLiteralEq l r
  | PsKernelCoreExpr.mdata lm le, PsKernelCoreExpr.mdata rm re =>
      lm == rm && psKernelCoreInferTestExprEq le re
  | PsKernelCoreExpr.proj ln li le, PsKernelCoreExpr.proj rn ri re =>
      psKernelCoreNameEq ln rn && li == ri && psKernelCoreInferTestExprEq le re
  | _, _ => false

def psKernelCoreInferTestName (value : String) : PsKernelCoreName :=
  PsKernelCoreName.str PsKernelCoreName.anonymous value

def psReferenceInferTestName (value : String) : PSC1Kernel.Name :=
  PSC1Kernel.Name.str PSC1Kernel.Name.anonymous value

partial def psKernelCoreInferNameMatches
    (left : PsKernelCoreName)
    (right : PSC1Kernel.Name) : Bool :=
  match left, right with
  | PsKernelCoreName.anonymous, PSC1Kernel.Name.anonymous => true
  | PsKernelCoreName.str lp ls, PSC1Kernel.Name.str rp rs =>
      psKernelCoreInferNameMatches lp rp && ls == rs
  | PsKernelCoreName.num lp ln, PSC1Kernel.Name.num rp rn =>
      psKernelCoreInferNameMatches lp rp && ln == rn
  | _, _ => false

partial def psKernelCoreInferLevelMatches
    (left : PsKernelCoreLevel)
    (right : PSC1Kernel.Level) : Bool :=
  match left, right with
  | PsKernelCoreLevel.zero, PSC1Kernel.Level.zero => true
  | PsKernelCoreLevel.succ l, PSC1Kernel.Level.succ r =>
      psKernelCoreInferLevelMatches l r
  | PsKernelCoreLevel.max la lb, PSC1Kernel.Level.max ra rb =>
      psKernelCoreInferLevelMatches la ra && psKernelCoreInferLevelMatches lb rb
  | PsKernelCoreLevel.imax la lb, PSC1Kernel.Level.imax ra rb =>
      psKernelCoreInferLevelMatches la ra && psKernelCoreInferLevelMatches lb rb
  | PsKernelCoreLevel.param l, PSC1Kernel.Level.param r =>
      psKernelCoreInferNameMatches l r
  | PsKernelCoreLevel.mvar l, PSC1Kernel.Level.mvar r =>
      psKernelCoreInferNameMatches l r
  | _, _ => false

partial def psKernelCoreInferLevelListMatches
    (left : PsKernelCoreList PsKernelCoreLevel)
    (right : List PSC1Kernel.Level) : Bool :=
  match left, right with
  | PsKernelCoreList.nil, [] => true
  | PsKernelCoreList.cons lh lt, rh :: rt =>
      psKernelCoreInferLevelMatches lh rh &&
        psKernelCoreInferLevelListMatches lt rt
  | _, _ => false

def psKernelCoreInferBinderMatches
    (left : PsKernelCoreBinderInfo)
    (right : PSC1Kernel.BinderInfo) : Bool :=
  match left, right with
  | PsKernelCoreBinderInfo.default, PSC1Kernel.BinderInfo.default => true
  | PsKernelCoreBinderInfo.implicit, PSC1Kernel.BinderInfo.implicit => true
  | PsKernelCoreBinderInfo.strictImplicit, PSC1Kernel.BinderInfo.strictImplicit => true
  | PsKernelCoreBinderInfo.instImplicit, PSC1Kernel.BinderInfo.instImplicit => true
  | _, _ => false

def psKernelCoreInferLiteralMatches
    (left : PsKernelCoreLiteral)
    (right : PSC1Kernel.Literal) : Bool :=
  match left, right with
  | PsKernelCoreLiteral.nat l, PSC1Kernel.Literal.nat r => l == r
  | PsKernelCoreLiteral.str l, PSC1Kernel.Literal.str r => l == r
  | _, _ => false

partial def psKernelCoreInferExprMatches
    (left : PsKernelCoreExpr)
    (right : PSC1Kernel.Expr) : Bool :=
  match left, right with
  | PsKernelCoreExpr.bvar l, PSC1Kernel.Expr.bvar r => l == r
  | PsKernelCoreExpr.fvar l, PSC1Kernel.Expr.fvar r =>
      psKernelCoreInferNameMatches l r
  | PsKernelCoreExpr.mvar l, PSC1Kernel.Expr.mvar r =>
      psKernelCoreInferNameMatches l r
  | PsKernelCoreExpr.sort l, PSC1Kernel.Expr.sort r =>
      psKernelCoreInferLevelMatches l r
  | PsKernelCoreExpr.const ln ll, PSC1Kernel.Expr.const rn rl =>
      psKernelCoreInferNameMatches ln rn &&
        psKernelCoreInferLevelListMatches ll rl
  | PsKernelCoreExpr.app lf la, PSC1Kernel.Expr.app rf ra =>
      psKernelCoreInferExprMatches lf rf && psKernelCoreInferExprMatches la ra
  | PsKernelCoreExpr.lam ln lt lb li, PSC1Kernel.Expr.lam rn rt rb ri =>
      psKernelCoreInferNameMatches ln rn &&
        psKernelCoreInferExprMatches lt rt &&
        psKernelCoreInferExprMatches lb rb &&
        psKernelCoreInferBinderMatches li ri
  | PsKernelCoreExpr.forallE ln lt lb li, PSC1Kernel.Expr.forallE rn rt rb ri =>
      psKernelCoreInferNameMatches ln rn &&
        psKernelCoreInferExprMatches lt rt &&
        psKernelCoreInferExprMatches lb rb &&
        psKernelCoreInferBinderMatches li ri
  | PsKernelCoreExpr.letE ln lt lv lb lnd,
      PSC1Kernel.Expr.letE rn rt rv rb rnd =>
      psKernelCoreInferNameMatches ln rn &&
        psKernelCoreInferExprMatches lt rt &&
        psKernelCoreInferExprMatches lv rv &&
        psKernelCoreInferExprMatches lb rb &&
        lnd == rnd
  | PsKernelCoreExpr.lit l, PSC1Kernel.Expr.lit r =>
      psKernelCoreInferLiteralMatches l r
  | PsKernelCoreExpr.mdata lm le, PSC1Kernel.Expr.mdata rm re =>
      lm == rm && psKernelCoreInferExprMatches le re
  | PsKernelCoreExpr.proj ln li le, PSC1Kernel.Expr.proj rn ri re =>
      psKernelCoreInferNameMatches ln rn && li == ri &&
        psKernelCoreInferExprMatches le re
  | _, _ => false

def psKernelCoreInferBinderContracts : Bool :=
  let x := psKernelCoreInferTestName "x"
  let y := psKernelCoreInferTestName "y"
  let t := psKernelCoreInferTestName "T"
  let levelZero := PsKernelCoreLevel.zero
  let xVar := PsKernelCoreExpr.fvar x
  let yVar := PsKernelCoreExpr.fvar y
  let leaf := PsKernelCoreExpr.sort levelZero
  let recursiveSurface :=
    PsKernelCoreExpr.app
      (PsKernelCoreExpr.lam
        y
        (PsKernelCoreExpr.app xVar leaf)
        (PsKernelCoreExpr.forallE
          y
          (PsKernelCoreExpr.mdata 7 xVar)
          (PsKernelCoreExpr.letE
            y
            xVar
            (PsKernelCoreExpr.proj t 2 xVar)
            (PsKernelCoreExpr.app yVar xVar)
            false)
          PsKernelCoreBinderInfo.implicit)
        PsKernelCoreBinderInfo.default)
      (PsKernelCoreExpr.const t PsKernelCoreList.nil)
  let nested :=
    PsKernelCoreExpr.lam
      y
      (PsKernelCoreExpr.bvar 0)
      (PsKernelCoreExpr.forallE
        y
        (PsKernelCoreExpr.bvar 1)
        (PsKernelCoreExpr.letE
          y
          (PsKernelCoreExpr.bvar 0)
          xVar
          (PsKernelCoreExpr.app xVar (PsKernelCoreExpr.bvar 2))
          true)
        PsKernelCoreBinderInfo.strictImplicit)
      PsKernelCoreBinderInfo.instImplicit
  let closedAbsent :=
    PsKernelCoreExpr.mdata 9
      (PsKernelCoreExpr.app yVar (PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat 3)))
  let abstractedNested := psKernelCoreExprAbstractFVar nested x
  let roundTrip :=
    psKernelCoreExprInstantiate1 abstractedNested (PsKernelCoreExpr.fvar x)
  let shiftedTop := psKernelCoreExprAbstractFVar (PsKernelCoreExpr.bvar 0) x
  let shiftedUnder :=
    psKernelCoreExprAbstractFVar
      (PsKernelCoreExpr.lam
        y leaf (PsKernelCoreExpr.bvar 0) PsKernelCoreBinderInfo.default)
      x
  psKernelCoreExprHasFVarName recursiveSurface x &&
  (!psKernelCoreExprHasFVarName recursiveSurface (psKernelCoreInferTestName "missing")) &&
  (!psKernelCoreExprHasFVarName (PsKernelCoreExpr.bvar 0) x) &&
  (!psKernelCoreExprHasFVarName (PsKernelCoreExpr.sort levelZero) x) &&
  (!psKernelCoreExprHasFVarName (PsKernelCoreExpr.const t PsKernelCoreList.nil) x) &&
  (!psKernelCoreExprHasFVarName (PsKernelCoreExpr.lit (PsKernelCoreLiteral.str "s")) x) &&
  (!psKernelCoreExprHasFVarName (PsKernelCoreExpr.mvar y) x) &&
  psKernelCoreInferTestExprEq (psKernelCoreExprAbstractFVar xVar x) (PsKernelCoreExpr.bvar 0) &&
  psKernelCoreInferTestExprEq (psKernelCoreExprAbstractFVar yVar x) yVar &&
  psKernelCoreInferTestExprEq roundTrip nested &&
  psKernelCoreInferTestExprEq shiftedTop (PsKernelCoreExpr.bvar 1) &&
  psKernelCoreInferTestExprEq shiftedUnder
    (PsKernelCoreExpr.lam y leaf (PsKernelCoreExpr.bvar 0) PsKernelCoreBinderInfo.default) &&
  psKernelCoreInferTestExprEq (psKernelCoreExprAbstractFVar closedAbsent x) closedAbsent

def psKernelCoreInferNameList1
    (value : PsKernelCoreName) : PsKernelCoreList PsKernelCoreName :=
  PsKernelCoreList.cons value PsKernelCoreList.nil

def psKernelCoreInferLevelList1
    (value : PsKernelCoreLevel) : PsKernelCoreList PsKernelCoreLevel :=
  PsKernelCoreList.cons value PsKernelCoreList.nil

def psKernelCoreInferAxiom
    (name : PsKernelCoreName)
    (levelParams : PsKernelCoreList PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (isUnsafe : Bool) : PsKernelCoreConstantInfo :=
  PsKernelCoreConstantInfo.axiomInfo {
    base := { name := name, levelParams := levelParams, type := type }
    isUnsafe := isUnsafe
  }

def psReferenceInferAxiom
    (name : PSC1Kernel.Name)
    (levelParams : List PSC1Kernel.Name)
    (type : PSC1Kernel.Expr)
    (isUnsafe : Bool) : PSC1Kernel.ConstantInfo :=
  PSC1Kernel.ConstantInfo.axiomInfo {
    base := { name := name, levelParams := levelParams, type := type }
    isUnsafe := isUnsafe
  }

def psKernelCoreInferDefinition
    (name : PsKernelCoreName)
    (levelParams : PsKernelCoreList PsKernelCoreName)
    (type value : PsKernelCoreExpr)
    (safety : PsKernelCoreDefinitionSafety) : PsKernelCoreConstantInfo :=
  PsKernelCoreConstantInfo.defnInfo {
    base := { name := name, levelParams := levelParams, type := type }
    value := value
    hints := PsKernelCoreReducibilityHints.regular 0
    safety := safety
  }

def psReferenceInferDefinition
    (name : PSC1Kernel.Name)
    (levelParams : List PSC1Kernel.Name)
    (type value : PSC1Kernel.Expr)
    (safety : PSC1Kernel.DefinitionSafety) : PSC1Kernel.ConstantInfo :=
  PSC1Kernel.ConstantInfo.defnInfo {
    base := { name := name, levelParams := levelParams, type := type }
    value := value
    hints := PSC1Kernel.ReducibilityHints.regular 0
    safety := safety
  }

def psKernelCoreInferResultMatches
    (kernelResult : PsKernelCoreResult String PsKernelCoreExpr)
    (referenceResult : Except String PSC1Kernel.Expr) : Bool :=
  match kernelResult, referenceResult with
  | PsKernelCoreResult.error left, Except.error right => left == right
  | PsKernelCoreResult.ok left, Except.ok right =>
      psKernelCoreInferExprMatches left right
  | _, _ => false

def psKernelCoreInferRunMatches
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
  psKernelCoreInferResultMatches
    (psKernelCoreInfer budget kernelEnv kernelLctx kernelExpr)
    (PSC1Kernel.infer referenceCtx referenceExpr)

def psKernelCoreInferParity : Bool :=
  let budget := 64
  let kempty := psKernelCoreEnvironmentEmpty
  let rempty := PSC1Kernel.Environment.empty
  let klctxEmpty := psKernelCoreLocalContextEmpty
  let rlctxEmpty := PSC1Kernel.LocalContext.empty
  let kx := psKernelCoreInferTestName "x"
  let ky := psKernelCoreInferTestName "y"
  let kA := psKernelCoreInferTestName "A"
  let ku := psKernelCoreInferTestName "u"
  let kmono := psKernelCoreInferTestName "mono"
  let kpoly := psKernelCoreInferTestName "poly"
  let kfun := psKernelCoreInferTestName "fun"
  let kmulti := psKernelCoreInferTestName "multi"
  let kalias := psKernelCoreInferTestName "Alias"
  let khidden := psKernelCoreInferTestName "hidden"
  let kunsafe := psKernelCoreInferTestName "unsafeC"
  let kpartial := psKernelCoreInferTestName "partialC"
  let kmissing := psKernelCoreInferTestName "missing"
  let kpre := PsKernelCoreName.num kx 0
  let rx := psReferenceInferTestName "x"
  let ry := psReferenceInferTestName "y"
  let rA := psReferenceInferTestName "A"
  let ru := psReferenceInferTestName "u"
  let rmono := psReferenceInferTestName "mono"
  let rpoly := psReferenceInferTestName "poly"
  let rfun := psReferenceInferTestName "fun"
  let rmulti := psReferenceInferTestName "multi"
  let ralias := psReferenceInferTestName "Alias"
  let rhidden := psReferenceInferTestName "hidden"
  let runsafe := psReferenceInferTestName "unsafeC"
  let rpartial := psReferenceInferTestName "partialC"
  let rmissing := psReferenceInferTestName "missing"
  let rpre := PSC1Kernel.Name.num rx 0
  let kzero := PsKernelCoreLevel.zero
  let kone := PsKernelCoreLevel.succ kzero
  let rzero := PSC1Kernel.Level.zero
  let rone := PSC1Kernel.Level.succ rzero
  let ksort0 := PsKernelCoreExpr.sort kzero
  let ksort1 := PsKernelCoreExpr.sort kone
  let rsort0 := PSC1Kernel.Expr.sort rzero
  let rsort1 := PSC1Kernel.Expr.sort rone
  let knatLit := PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat 7)
  let rnatLit := PSC1Kernel.Expr.lit (PSC1Kernel.Literal.nat 7)
  let kstrLit := PsKernelCoreExpr.lit (PsKernelCoreLiteral.str "abc")
  let rstrLit := PSC1Kernel.Expr.lit (PSC1Kernel.Literal.str "abc")

  let klctxLocal :=
    psKernelCoreLocalContextAddLocal klctxEmpty kx kx ksort0 PsKernelCoreBinderInfo.default
  let rlctxLocal :=
    PSC1Kernel.LocalContext.addLocal rlctxEmpty rx rx rsort0 PSC1Kernel.BinderInfo.default
  let klctxLet := psKernelCoreLocalContextAddLet klctxEmpty kx kx ksort1 ksort0
  let rlctxLet := PSC1Kernel.LocalContext.addLet rlctxEmpty rx rx rsort1 rsort0

  let kmonoInfo := psKernelCoreInferAxiom kmono PsKernelCoreList.nil ksort0 false
  let rmonoInfo := psReferenceInferAxiom rmono [] rsort0 false
  let kenvMono := psKernelCoreEnvironmentAddUnchecked kempty kmonoInfo
  let renvMono := PSC1Kernel.Environment.addUnchecked rempty rmonoInfo

  let kpolyType :=
    PsKernelCoreExpr.lam kx
      (PsKernelCoreExpr.sort (PsKernelCoreLevel.param ku))
      (PsKernelCoreExpr.forallE ky
        (PsKernelCoreExpr.const kmono
          (psKernelCoreInferLevelList1 (PsKernelCoreLevel.param ku)))
        (PsKernelCoreExpr.letE kA
          (PsKernelCoreExpr.sort (PsKernelCoreLevel.param ku))
          (PsKernelCoreExpr.sort (PsKernelCoreLevel.param ku))
          (PsKernelCoreExpr.mdata 4
            (PsKernelCoreExpr.proj kmono 0
              (PsKernelCoreExpr.sort (PsKernelCoreLevel.param ku))))
          false)
        PsKernelCoreBinderInfo.implicit)
      PsKernelCoreBinderInfo.default
  let rpolyType :=
    PSC1Kernel.Expr.lam rx
      (PSC1Kernel.Expr.sort (PSC1Kernel.Level.param ru))
      (PSC1Kernel.Expr.forallE ry
        (PSC1Kernel.Expr.const rmono [PSC1Kernel.Level.param ru])
        (PSC1Kernel.Expr.letE rA
          (PSC1Kernel.Expr.sort (PSC1Kernel.Level.param ru))
          (PSC1Kernel.Expr.sort (PSC1Kernel.Level.param ru))
          (PSC1Kernel.Expr.mdata 4
            (PSC1Kernel.Expr.proj rmono 0
              (PSC1Kernel.Expr.sort (PSC1Kernel.Level.param ru))))
          false)
        PSC1Kernel.BinderInfo.implicit)
      PSC1Kernel.BinderInfo.default
  let kpolyInfo :=
    psKernelCoreInferAxiom kpoly (psKernelCoreInferNameList1 ku) kpolyType false
  let rpolyInfo := psReferenceInferAxiom rpoly [ru] rpolyType false
  let kenvPoly := psKernelCoreEnvironmentAddUnchecked kenvMono kpolyInfo
  let renvPoly := PSC1Kernel.Environment.addUnchecked renvMono rpolyInfo
  let kpolyUse := PsKernelCoreExpr.const kpoly (psKernelCoreInferLevelList1 kone)
  let rpolyUse := PSC1Kernel.Expr.const rpoly [rone]

  let kfunType :=
    PsKernelCoreExpr.forallE kx ksort0 ksort0 PsKernelCoreBinderInfo.default
  let rfunType :=
    PSC1Kernel.Expr.forallE rx rsort0 rsort0 PSC1Kernel.BinderInfo.default
  let kfunInfo := psKernelCoreInferAxiom kfun PsKernelCoreList.nil kfunType false
  let rfunInfo := psReferenceInferAxiom rfun [] rfunType false
  let kenvFun := psKernelCoreEnvironmentAddUnchecked kempty kfunInfo
  let renvFun := PSC1Kernel.Environment.addUnchecked rempty rfunInfo

  let kmultiType :=
    PsKernelCoreExpr.forallE kA ksort1
      (PsKernelCoreExpr.forallE kx (PsKernelCoreExpr.bvar 0)
        (PsKernelCoreExpr.bvar 1) PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.implicit
  let rmultiType :=
    PSC1Kernel.Expr.forallE rA rsort1
      (PSC1Kernel.Expr.forallE rx (PSC1Kernel.Expr.bvar 0)
        (PSC1Kernel.Expr.bvar 1) PSC1Kernel.BinderInfo.default)
      PSC1Kernel.BinderInfo.implicit
  let kmultiInfo := psKernelCoreInferAxiom kmulti PsKernelCoreList.nil kmultiType false
  let rmultiInfo := psReferenceInferAxiom rmulti [] rmultiType false
  let kenvMulti := psKernelCoreEnvironmentAddUnchecked kempty kmultiInfo
  let renvMulti := PSC1Kernel.Environment.addUnchecked rempty rmultiInfo

  let kaliasInfo :=
    psKernelCoreInferDefinition kalias PsKernelCoreList.nil ksort1 kfunType PsKernelCoreDefinitionSafety.safe
  let raliasInfo :=
    psReferenceInferDefinition ralias [] rsort1 rfunType PSC1Kernel.DefinitionSafety.safe
  let khiddenInfo :=
    psKernelCoreInferAxiom khidden PsKernelCoreList.nil
      (PsKernelCoreExpr.const kalias PsKernelCoreList.nil) false
  let rhiddenInfo :=
    psReferenceInferAxiom rhidden [] (PSC1Kernel.Expr.const ralias []) false
  let kenvHidden :=
    psKernelCoreEnvironmentAddUnchecked
      (psKernelCoreEnvironmentAddUnchecked kempty kaliasInfo) khiddenInfo
  let renvHidden :=
    PSC1Kernel.Environment.addUnchecked
      (PSC1Kernel.Environment.addUnchecked rempty raliasInfo) rhiddenInfo

  let kunsafeInfo := psKernelCoreInferAxiom kunsafe PsKernelCoreList.nil ksort0 true
  let runsafeInfo := psReferenceInferAxiom runsafe [] rsort0 true
  let kenvUnsafe := psKernelCoreEnvironmentAddUnchecked kempty kunsafeInfo
  let renvUnsafe := PSC1Kernel.Environment.addUnchecked rempty runsafeInfo
  let kpartialInfo :=
    psKernelCoreInferDefinition kpartial PsKernelCoreList.nil ksort0 ksort0
      PsKernelCoreDefinitionSafety.partialDef
  let rpartialInfo :=
    psReferenceInferDefinition rpartial [] rsort0 rsort0 PSC1Kernel.DefinitionSafety.partialDef
  let kenvPartial := psKernelCoreEnvironmentAddUnchecked kempty kpartialInfo
  let renvPartial := PSC1Kernel.Environment.addUnchecked rempty rpartialInfo

  let klambda :=
    PsKernelCoreExpr.lam kx ksort0 (PsKernelCoreExpr.bvar 0) PsKernelCoreBinderInfo.default
  let rlambda :=
    PSC1Kernel.Expr.lam rx rsort0 (PSC1Kernel.Expr.bvar 0) PSC1Kernel.BinderInfo.default
  let kdepLambda :=
    PsKernelCoreExpr.lam kA ksort1
      (PsKernelCoreExpr.lam kx (PsKernelCoreExpr.bvar 0)
        (PsKernelCoreExpr.bvar 0) PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.implicit
  let rdepLambda :=
    PSC1Kernel.Expr.lam rA rsort1
      (PSC1Kernel.Expr.lam rx (PSC1Kernel.Expr.bvar 0)
        (PSC1Kernel.Expr.bvar 0) PSC1Kernel.BinderInfo.default)
      PSC1Kernel.BinderInfo.implicit
  let kforall :=
    PsKernelCoreExpr.forallE kx ksort0 ksort0 PsKernelCoreBinderInfo.default
  let rforall :=
    PSC1Kernel.Expr.forallE rx rsort0 rsort0 PSC1Kernel.BinderInfo.default
  let knestedForall :=
    PsKernelCoreExpr.forallE kA ksort1
      (PsKernelCoreExpr.forallE kx (PsKernelCoreExpr.bvar 0) ksort0
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.implicit
  let rnestedForall :=
    PSC1Kernel.Expr.forallE rA rsort1
      (PSC1Kernel.Expr.forallE rx (PSC1Kernel.Expr.bvar 0) rsort0
        PSC1Kernel.BinderInfo.default)
      PSC1Kernel.BinderInfo.implicit
  let knondepLet :=
    PsKernelCoreExpr.letE kx ksort1 ksort0 ksort0 false
  let rnondepLet := PSC1Kernel.Expr.letE rx rsort1 rsort0 rsort0 false
  let kdepLet :=
    PsKernelCoreExpr.letE kA ksort1 ksort0
      (PsKernelCoreExpr.lam kx (PsKernelCoreExpr.bvar 0)
        (PsKernelCoreExpr.bvar 0) PsKernelCoreBinderInfo.default)
      true
  let rdepLet :=
    PSC1Kernel.Expr.letE rA rsort1 rsort0
      (PSC1Kernel.Expr.lam rx (PSC1Kernel.Expr.bvar 0)
        (PSC1Kernel.Expr.bvar 0) PSC1Kernel.BinderInfo.default)
      true
  let kapp :=
    PsKernelCoreExpr.app (PsKernelCoreExpr.const kfun PsKernelCoreList.nil) knatLit
  let rapp := PSC1Kernel.Expr.app (PSC1Kernel.Expr.const rfun []) rnatLit
  let kbadArg := PsKernelCoreExpr.mvar (psKernelCoreInferTestName "argM")
  let rbadArg := PSC1Kernel.Expr.mvar (psReferenceInferTestName "argM")
  let kappBadArg :=
    PsKernelCoreExpr.app (PsKernelCoreExpr.const kfun PsKernelCoreList.nil) kbadArg
  let rappBadArg := PSC1Kernel.Expr.app (PSC1Kernel.Expr.const rfun []) rbadArg
  let kmultiApp :=
    PsKernelCoreExpr.app
      (PsKernelCoreExpr.app (PsKernelCoreExpr.const kmulti PsKernelCoreList.nil) ksort0)
      kbadArg
  let rmultiApp :=
    PSC1Kernel.Expr.app
      (PSC1Kernel.Expr.app (PSC1Kernel.Expr.const rmulti []) rsort0)
      rbadArg
  let khiddenApp :=
    PsKernelCoreExpr.app (PsKernelCoreExpr.const khidden PsKernelCoreList.nil) knatLit
  let rhiddenApp := PSC1Kernel.Expr.app (PSC1Kernel.Expr.const rhidden []) rnatLit
  let kinvalidDomainLambda :=
    PsKernelCoreExpr.lam kx
      (PsKernelCoreExpr.mvar (psKernelCoreInferTestName "domainM"))
      ksort0 PsKernelCoreBinderInfo.default
  let rinvalidDomainLambda :=
    PSC1Kernel.Expr.lam rx
      (PSC1Kernel.Expr.mvar (psReferenceInferTestName "domainM"))
      rsort0 PSC1Kernel.BinderInfo.default
  let kinvalidLet :=
    PsKernelCoreExpr.letE kx
      (PsKernelCoreExpr.mvar (psKernelCoreInferTestName "typeM"))
      (PsKernelCoreExpr.mvar (psKernelCoreInferTestName "valueM"))
      ksort0 false
  let rinvalidLet :=
    PSC1Kernel.Expr.letE rx
      (PSC1Kernel.Expr.mvar (psReferenceInferTestName "typeM"))
      (PSC1Kernel.Expr.mvar (psReferenceInferTestName "valueM"))
      rsort0 false
  let klctxPre :=
    psKernelCoreLocalContextAddLocal klctxEmpty kpre kpre ksort0 PsKernelCoreBinderInfo.default
  let rlctxPre :=
    PSC1Kernel.LocalContext.addLocal rlctxEmpty rpre rpre rsort0 PSC1Kernel.BinderInfo.default
  let kfreshFixture :=
    PsKernelCoreExpr.lam kx ksort0 (PsKernelCoreExpr.fvar kpre) PsKernelCoreBinderInfo.default
  let rfreshFixture :=
    PSC1Kernel.Expr.lam rx rsort0 (PSC1Kernel.Expr.fvar rpre) PSC1Kernel.BinderInfo.default

  let kbadForall :=
    PsKernelCoreExpr.forallE kx knatLit ksort0 PsKernelCoreBinderInfo.default
  let rbadForall := PSC1Kernel.Expr.forallE rx rnatLit rsort0 PSC1Kernel.BinderInfo.default
  let kbadFnInfo := psKernelCoreInferAxiom kmono PsKernelCoreList.nil ksort0 false
  let rbadFnInfo := psReferenceInferAxiom rmono [] rsort0 false
  let kenvBadFn := psKernelCoreEnvironmentAddUnchecked kempty kbadFnInfo
  let renvBadFn := PSC1Kernel.Environment.addUnchecked rempty rbadFnInfo
  let kbadApp :=
    PsKernelCoreExpr.app (PsKernelCoreExpr.const kmono PsKernelCoreList.nil) knatLit
  let rbadApp := PSC1Kernel.Expr.app (PSC1Kernel.Expr.const rmono []) rnatLit

  psKernelCoreInferRunMatches budget kempty klctxEmpty ksort0 rempty rlctxEmpty rsort0 &&
  psKernelCoreInferRunMatches budget kempty klctxLocal (PsKernelCoreExpr.fvar kx) rempty rlctxLocal (PSC1Kernel.Expr.fvar rx) &&
  psKernelCoreInferRunMatches budget kempty klctxLet (PsKernelCoreExpr.fvar kx) rempty rlctxLet (PSC1Kernel.Expr.fvar rx) &&
  psKernelCoreInferRunMatches budget kenvMono klctxEmpty (PsKernelCoreExpr.const kmono PsKernelCoreList.nil) renvMono rlctxEmpty (PSC1Kernel.Expr.const rmono []) &&
  psKernelCoreInferRunMatches budget kenvPoly klctxEmpty kpolyUse renvPoly rlctxEmpty rpolyUse &&
  psKernelCoreInferRunMatches budget kempty klctxEmpty knatLit rempty rlctxEmpty rnatLit &&
  psKernelCoreInferRunMatches budget kempty klctxEmpty kstrLit rempty rlctxEmpty rstrLit &&
  psKernelCoreInferRunMatches budget kempty klctxEmpty (PsKernelCoreExpr.mdata 3 ksort0) rempty rlctxEmpty (PSC1Kernel.Expr.mdata 3 rsort0) &&
  psKernelCoreInferRunMatches budget kempty klctxEmpty klambda rempty rlctxEmpty rlambda &&
  psKernelCoreInferRunMatches budget kempty klctxEmpty kdepLambda rempty rlctxEmpty rdepLambda &&
  psKernelCoreInferRunMatches budget kempty klctxEmpty kforall rempty rlctxEmpty rforall &&
  psKernelCoreInferRunMatches budget kempty klctxEmpty knestedForall rempty rlctxEmpty rnestedForall &&
  psKernelCoreInferRunMatches budget kempty klctxEmpty knondepLet rempty rlctxEmpty rnondepLet &&
  psKernelCoreInferRunMatches budget kempty klctxEmpty kdepLet rempty rlctxEmpty rdepLet &&
  psKernelCoreInferRunMatches budget kenvFun klctxEmpty kapp renvFun rlctxEmpty rapp &&
  psKernelCoreInferRunMatches budget kenvMulti klctxEmpty kmultiApp renvMulti rlctxEmpty rmultiApp &&
  psKernelCoreInferRunMatches budget kenvHidden klctxEmpty khiddenApp renvHidden rlctxEmpty rhiddenApp &&
  psKernelCoreInferRunMatches budget kenvFun klctxEmpty kappBadArg renvFun rlctxEmpty rappBadArg &&
  psKernelCoreInferRunMatches budget kempty klctxEmpty kinvalidDomainLambda rempty rlctxEmpty rinvalidDomainLambda &&
  psKernelCoreInferRunMatches budget kempty klctxEmpty kinvalidLet rempty rlctxEmpty rinvalidLet &&
  psKernelCoreInferRunMatches budget kenvUnsafe klctxEmpty (PsKernelCoreExpr.const kunsafe PsKernelCoreList.nil) renvUnsafe rlctxEmpty (PSC1Kernel.Expr.const runsafe []) &&
  psKernelCoreInferRunMatches budget kenvPartial klctxEmpty (PsKernelCoreExpr.const kpartial PsKernelCoreList.nil) renvPartial rlctxEmpty (PSC1Kernel.Expr.const rpartial []) &&
  psKernelCoreInferRunMatches budget kempty klctxPre kfreshFixture rempty rlctxPre rfreshFixture &&
  psKernelCoreInferRunMatches budget kempty klctxEmpty (PsKernelCoreExpr.bvar 0) rempty rlctxEmpty (PSC1Kernel.Expr.bvar 0) &&
  psKernelCoreInferRunMatches budget kempty klctxEmpty (PsKernelCoreExpr.mvar kmissing) rempty rlctxEmpty (PSC1Kernel.Expr.mvar rmissing) &&
  psKernelCoreInferRunMatches budget kempty klctxEmpty (PsKernelCoreExpr.fvar kmissing) rempty rlctxEmpty (PSC1Kernel.Expr.fvar rmissing) &&
  psKernelCoreInferRunMatches budget kempty klctxEmpty (PsKernelCoreExpr.const kmissing PsKernelCoreList.nil) rempty rlctxEmpty (PSC1Kernel.Expr.const rmissing []) &&
  psKernelCoreInferRunMatches budget kenvPoly klctxEmpty (PsKernelCoreExpr.const kpoly PsKernelCoreList.nil) renvPoly rlctxEmpty (PSC1Kernel.Expr.const rpoly []) &&
  psKernelCoreInferRunMatches budget kempty klctxEmpty kbadForall rempty rlctxEmpty rbadForall &&
  psKernelCoreInferRunMatches budget kenvBadFn klctxEmpty kbadApp renvBadFn rlctxEmpty rbadApp

def psKernelCoreInferPhase4Boundaries : Bool :=
  let kempty := psKernelCoreEnvironmentEmpty
  let klctx := psKernelCoreLocalContextEmpty
  let ksort0 := PsKernelCoreExpr.sort PsKernelCoreLevel.zero
  let kproj :=
    PsKernelCoreExpr.proj
      (psKernelCoreInferTestName "Deferred") 0 ksort0
  let zeroBudget :=
    match psKernelCoreInfer 0 kempty klctx ksort0 with
    | PsKernelCoreResult.error message => message == "inference budget exhausted"
    | PsKernelCoreResult.ok _ => false
  let oneBudget :=
    match psKernelCoreInfer 1 kempty klctx ksort0 with
    | PsKernelCoreResult.ok (PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero)) => true
    | _ => false
  let projectionDeferred :=
    match psKernelCoreInfer 8 kempty klctx kproj with
    | PsKernelCoreResult.error message =>
        message == "projection inference unavailable before inductive metadata"
    | PsKernelCoreResult.ok _ => false
  zeroBudget && oneBudget && projectionDeferred

def main : IO Unit := do
  if !psKernelCoreInferBinderContracts then
    throw (IO.userError "PSC2_KERNEL_CORE_INFER_BINDERS: FAIL")
  if !psKernelCoreInferParity then
    throw (IO.userError "PSC2_KERNEL_CORE_INFER_PARITY: DIFFERENTIAL FAIL")
  if !psKernelCoreInferPhase4Boundaries then
    throw (IO.userError "PSC2_KERNEL_CORE_INFER_PARITY: BOUNDARY FAIL")
  IO.println "PSC2_KERNEL_CORE_INFER_PARITY: PASS"
