import Ps.KernelSelfHost.NestedInductive
import PSC1Kernel.NestedInductive

def psKernelNameToReference
    (name : PsKernelName) : PSC1Kernel.Name :=
  match name with
  | PsKernelName.anonymous =>
      PSC1Kernel.Name.anonymous
  | PsKernelName.str parent value =>
      PSC1Kernel.Name.str
        (psKernelNameToReference parent)
        value
  | PsKernelName.num parent value =>
      PSC1Kernel.Name.num
        (psKernelNameToReference parent)
        value


def psKernelNameFromReference
    (name : PSC1Kernel.Name) : PsKernelName :=
  match name with
  | PSC1Kernel.Name.anonymous =>
      PsKernelName.anonymous
  | PSC1Kernel.Name.str parent value =>
      PsKernelName.str
        (psKernelNameFromReference parent)
        value
  | PSC1Kernel.Name.num parent value =>
      PsKernelName.num
        (psKernelNameFromReference parent)
        value

def psKernelOrderingToReference
    (value : PsKernelOrdering) : Ordering :=
  match value with
  | PsKernelOrdering.lt => Ordering.lt
  | PsKernelOrdering.eq => Ordering.eq
  | PsKernelOrdering.gt => Ordering.gt

def psKernelNameOptionToReference
    (value : Option PsKernelName) :
    Option PSC1Kernel.Name :=
  match value with
  | Option.none =>
      Option.none
  | Option.some name =>
      Option.some (psKernelNameToReference name)

def psKernelReferenceNameOptionEq
    (left right : Option PSC1Kernel.Name) : Bool :=
  match left with
  | Option.none =>
      match right with
      | Option.none => true
      | Option.some _ => false
  | Option.some leftName =>
      match right with
      | Option.none => false
      | Option.some rightName =>
          PSC1Kernel.Name.eq leftName rightName

def psKernelNameDifferentialCase
    (left right : PsKernelName) : Bool :=
  Bool.and
    ((psKernelNameEq left right) ==
      (PSC1Kernel.Name.eq
        (psKernelNameToReference left)
        (psKernelNameToReference right)))
    (psKernelOrderingToReference
      (psKernelNameCmp left right) ==
      PSC1Kernel.Name.cmp
        (psKernelNameToReference left)
        (psKernelNameToReference right))

def psKernelNamePrefixDifferentialCase
    (needle candidate : PsKernelName) : Bool :=
  (psKernelNameIsPrefixOf needle candidate) ==
    (PSC1Kernel.Name.isPrefixOf
      (psKernelNameToReference needle)
      (psKernelNameToReference candidate))

def psKernelNameReplaceDifferentialCase
    (name oldPrefix newPrefix : PsKernelName) : Bool :=
  psKernelReferenceNameOptionEq
    (psKernelNameOptionToReference
      (psKernelNameReplacePrefix
        name
        oldPrefix
        newPrefix))
    (PSC1Kernel.Name.replacePrefix
      (psKernelNameToReference name)
      (psKernelNameToReference oldPrefix)
      (psKernelNameToReference newPrefix))

def psKernelNameTestRoot : PsKernelName :=
  PsKernelName.str
    (PsKernelName.str
      PsKernelName.anonymous
      "PSC1Kernel")
    "Expr"

def psKernelNameTestNested : PsKernelName :=
  PsKernelName.num
    (PsKernelName.str
      psKernelNameTestRoot
      "field")
    3

def psKernelNameTestReplacement : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "Portable"

def psKernelSelfHostNameTests : Bool :=
  Bool.and
    (psKernelNameDifferentialCase
      PsKernelName.anonymous
      PsKernelName.anonymous)
    (Bool.and
      (psKernelNameDifferentialCase
        psKernelNameTestRoot
        psKernelNameTestNested)
      (Bool.and
        (psKernelNamePrefixDifferentialCase
          psKernelNameTestRoot
          psKernelNameTestNested)
        (psKernelNameReplaceDifferentialCase
          psKernelNameTestNested
          psKernelNameTestRoot
          psKernelNameTestReplacement)))

def psKernelLevelToReference
    (level : PsKernelLevel) : PSC1Kernel.Level :=
  match level with
  | PsKernelLevel.zero =>
      PSC1Kernel.Level.zero
  | PsKernelLevel.succ inner =>
      PSC1Kernel.Level.succ
        (psKernelLevelToReference inner)
  | PsKernelLevel.max left right =>
      PSC1Kernel.Level.max
        (psKernelLevelToReference left)
        (psKernelLevelToReference right)
  | PsKernelLevel.imax left right =>
      PSC1Kernel.Level.imax
        (psKernelLevelToReference left)
        (psKernelLevelToReference right)
  | PsKernelLevel.param name =>
      PSC1Kernel.Level.param
        (psKernelNameToReference name)
  | PsKernelLevel.mvar name =>
      PSC1Kernel.Level.mvar
        (psKernelNameToReference name)

def psKernelLevelDifferentialCase
    (left right : PsKernelLevel) : Bool :=
  let referenceLeft :=
    psKernelLevelToReference left
  let referenceRight :=
    psKernelLevelToReference right
  let normalizedPortable :=
    psKernelLevelToReference
      (psKernelLevelNormalize left)
  let normalizedReference :=
    PSC1Kernel.Level.normalize referenceLeft
  Bool.and
    ((psKernelLevelEquivalent left right) ==
      (PSC1Kernel.Level.equivalent
        referenceLeft
        referenceRight))
    (Bool.and
      ((psKernelLevelLe left right) ==
        (PSC1Kernel.Level.le
          referenceLeft
          referenceRight))
      (PSC1Kernel.Level.eq
        normalizedPortable
        normalizedReference))

def psKernelLevelParamU : PsKernelLevel :=
  PsKernelLevel.param
    (PsKernelName.str
      PsKernelName.anonymous
      "u")

def psKernelLevelParamV : PsKernelLevel :=
  PsKernelLevel.param
    (PsKernelName.str
      PsKernelName.anonymous
      "v")

def psKernelSelfHostLevelTests : Bool :=
  let explicitTwo :=
    PsKernelLevel.succ
      (PsKernelLevel.succ
        PsKernelLevel.zero)
  let left :=
    PsKernelLevel.max
      (PsKernelLevel.succ psKernelLevelParamU)
      explicitTwo
  let right :=
    PsKernelLevel.imax
      psKernelLevelParamV
      (PsKernelLevel.succ PsKernelLevel.zero)
  Bool.and
    (psKernelLevelDifferentialCase
      PsKernelLevel.zero
      PsKernelLevel.zero)
    (Bool.and
      (psKernelLevelDifferentialCase
        left
        left)
      (psKernelLevelDifferentialCase
        left
        right))

def psKernelBinderInfoToReference
    (info : PsKernelBinderInfo) : PSC1Kernel.BinderInfo :=
  match info with
  | PsKernelBinderInfo.default => PSC1Kernel.BinderInfo.default
  | PsKernelBinderInfo.implicit => PSC1Kernel.BinderInfo.implicit
  | PsKernelBinderInfo.strictImplicit => PSC1Kernel.BinderInfo.strictImplicit
  | PsKernelBinderInfo.instImplicit => PSC1Kernel.BinderInfo.instImplicit

def psKernelLiteralToReference
    (literal : PsKernelLiteral) : PSC1Kernel.Literal :=
  match literal with
  | PsKernelLiteral.nat value => PSC1Kernel.Literal.nat value
  | PsKernelLiteral.str value => PSC1Kernel.Literal.str value

def psKernelLevelListToReference
    (levels : List PsKernelLevel) : List PSC1Kernel.Level :=
  match levels with
  | List.nil => List.nil
  | List.cons head tail =>
      List.cons
        (psKernelLevelToReference head)
        (psKernelLevelListToReference tail)

def psKernelExprToReference
    (expr : PsKernelExpr) : PSC1Kernel.Expr :=
  match expr with
  | PsKernelExpr.bvar index =>
      PSC1Kernel.Expr.bvar index
  | PsKernelExpr.fvar name =>
      PSC1Kernel.Expr.fvar (psKernelNameToReference name)
  | PsKernelExpr.mvar name =>
      PSC1Kernel.Expr.mvar (psKernelNameToReference name)
  | PsKernelExpr.sort level =>
      PSC1Kernel.Expr.sort (psKernelLevelToReference level)
  | PsKernelExpr.const name levels =>
      PSC1Kernel.Expr.const
        (psKernelNameToReference name)
        (psKernelLevelListToReference levels)
  | PsKernelExpr.app fn arg =>
      PSC1Kernel.Expr.app
        (psKernelExprToReference fn)
        (psKernelExprToReference arg)
  | PsKernelExpr.lam name type body binderInfo =>
      PSC1Kernel.Expr.lam
        (psKernelNameToReference name)
        (psKernelExprToReference type)
        (psKernelExprToReference body)
        (psKernelBinderInfoToReference binderInfo)
  | PsKernelExpr.forallE name type body binderInfo =>
      PSC1Kernel.Expr.forallE
        (psKernelNameToReference name)
        (psKernelExprToReference type)
        (psKernelExprToReference body)
        (psKernelBinderInfoToReference binderInfo)
  | PsKernelExpr.letE name type value body nondep =>
      PSC1Kernel.Expr.letE
        (psKernelNameToReference name)
        (psKernelExprToReference type)
        (psKernelExprToReference value)
        (psKernelExprToReference body)
        nondep
  | PsKernelExpr.lit literal =>
      PSC1Kernel.Expr.lit (psKernelLiteralToReference literal)
  | PsKernelExpr.mdata metadata body =>
      PSC1Kernel.Expr.mdata metadata (psKernelExprToReference body)
  | PsKernelExpr.proj typeName index body =>
      PSC1Kernel.Expr.proj
        (psKernelNameToReference typeName)
        index
        (psKernelExprToReference body)

def psKernelExprDifferentialPair
    (left right : PsKernelExpr) : Bool :=
  let referenceLeft := psKernelExprToReference left
  let referenceRight := psKernelExprToReference right
  Bool.and
    ((psKernelExprEq left right) ==
      PSC1Kernel.Expr.eq referenceLeft referenceRight)
    ((psKernelExprEqual left right) ==
      PSC1Kernel.Expr.equal referenceLeft referenceRight)

def psKernelSelfHostExprTests : Bool :=
  let typeExpr := PsKernelExpr.sort PsKernelLevel.zero
  let alphaName := PsKernelName.str PsKernelName.anonymous "alpha"
  let betaName := PsKernelName.str PsKernelName.anonymous "beta"
  let alphaLam :=
    PsKernelExpr.lam
      alphaName
      typeExpr
      (PsKernelExpr.bvar 0)
      PsKernelBinderInfo.default
  let betaLam :=
    PsKernelExpr.lam
      betaName
      typeExpr
      (PsKernelExpr.bvar 0)
      PsKernelBinderInfo.implicit
  let app :=
    PsKernelExpr.app
      (PsKernelExpr.app
        (PsKernelExpr.const alphaName List.nil)
        (PsKernelExpr.bvar 2))
      (PsKernelExpr.lit (PsKernelLiteral.nat 7))
  Bool.and
    (psKernelExprDifferentialPair alphaLam betaLam)
    (Bool.and
      ((psKernelExprHasLooseAt app 2) ==
        PSC1Kernel.Expr.hasLooseAt
          (psKernelExprToReference app)
          2)
      (Bool.and
        (psKernelExprGetAppNumArgs app ==
          (PSC1Kernel.Expr.getAppArgs
            (psKernelExprToReference app)).length)
        (PSC1Kernel.Expr.eq
          (psKernelExprToReference
            (psKernelExprGetAppFn app))
          (psKernelExprToReference
            (PsKernelExpr.const alphaName List.nil)))))

def psKernelExprListToReference
    (values : List PsKernelExpr) :
    List PSC1Kernel.Expr :=
  match values with
  | List.nil =>
      List.nil
  | List.cons head tail =>
      List.cons
        (psKernelExprToReference head)
        (psKernelExprListToReference tail)

def psKernelNameListToReference
    (values : List PsKernelName) :
    List PSC1Kernel.Name :=
  match values with
  | List.nil =>
      List.nil
  | List.cons head tail =>
      List.cons
        (psKernelNameToReference head)
        (psKernelNameListToReference tail)

def psKernelExprReferenceEq
    (portable : PsKernelExpr)
    (reference : PSC1Kernel.Expr) : Bool :=
  PSC1Kernel.Expr.eq
    (psKernelExprToReference portable)
    reference

def psKernelSelfHostInstantiateTests : Bool :=
  let typeExpr :=
    PsKernelExpr.sort PsKernelLevel.zero
  let alphaName :=
    PsKernelName.str PsKernelName.anonymous "alpha"
  let betaName :=
    PsKernelName.str PsKernelName.anonymous "beta"
  let nested :=
    PsKernelExpr.lam
      alphaName
      typeExpr
      (PsKernelExpr.app
        (PsKernelExpr.bvar 1)
        (PsKernelExpr.bvar 0))
      PsKernelBinderInfo.default
  let lifted :=
    psKernelExprLiftLooseBVars
      nested
      0
      2
  let referenceLifted :=
    PSC1Kernel.Expr.liftLooseBVars
      (psKernelExprToReference nested)
      0
      2
  let replacement :=
    PsKernelExpr.lit (PsKernelLiteral.nat 9)
  let instantiateSource :=
    PsKernelExpr.app
      (PsKernelExpr.bvar 1)
      (PsKernelExpr.bvar 0)
  let subst :=
    List.cons replacement List.nil
  let instantiated :=
    psKernelExprInstantiateAt
      instantiateSource
      0
      subst
      0
  let referenceInstantiated :=
    PSC1Kernel.Expr.instantiateAt
      (psKernelExprToReference instantiateSource)
      0
      (psKernelExprListToReference subst)
      0
  let betaSource :=
    PsKernelExpr.app
      (PsKernelExpr.lam
        alphaName
        typeExpr
        (PsKernelExpr.bvar 0)
        PsKernelBinderInfo.default)
      replacement
  let betaReduced :=
    psKernelExprCheapBetaReduce betaSource
  let referenceBetaReduced :=
    PSC1Kernel.Expr.cheapBetaReduce
      (psKernelExprToReference betaSource)
  let abstractSource :=
    PsKernelExpr.app
      (PsKernelExpr.fvar alphaName)
      (PsKernelExpr.fvar betaName)
  let fvars :=
    List.cons
      alphaName
      (List.cons betaName List.nil)
  let abstracted :=
    psKernelExprAbstractFVars
      abstractSource
      fvars
  let referenceAbstracted :=
    PSC1Kernel.Expr.abstractFVars
      (psKernelExprToReference abstractSource)
      (psKernelNameListToReference fvars)
  Bool.and
    (psKernelExprReferenceEq
      lifted
      referenceLifted)
    (Bool.and
      (psKernelExprReferenceEq
        instantiated
        referenceInstantiated)
      (Bool.and
        (psKernelExprReferenceEq
          betaReduced
          referenceBetaReduced)
        (psKernelExprReferenceEq
          abstracted
          referenceAbstracted)))

def psKernelReferenceExprOptionEq
    (portable : Option PsKernelExpr)
    (reference : Option PSC1Kernel.Expr) : Bool :=
  match portable with
  | Option.none =>
      match reference with
      | Option.none => true
      | Option.some _ => false
  | Option.some portableExpr =>
      match reference with
      | Option.none => false
      | Option.some referenceExpr =>
          psKernelExprReferenceEq
            portableExpr
            referenceExpr

def psKernelNatReductionDifferential
    (portableOp : PsKernelName)
    (referenceOp : PSC1Kernel.Name)
    (left right maxNatSize : Nat) : Bool :=
  match
      psKernelReduceNatBinary
        maxNatSize
        portableOp
        left
        right,
      PSC1Kernel.reduceNatBinary
        maxNatSize
        referenceOp
        left
        right with
  | Except.ok portableResult, Except.ok referenceResult =>
      psKernelReferenceExprOptionEq
        portableResult
        referenceResult
  | Except.error portableError, Except.error referenceError =>
      portableError == referenceError
  | _, _ =>
      false

def psKernelSelfHostPrimitiveNatTests : Bool :=
  let maxSize := psKernelLeanNatMaxSizeDefault
  Bool.and
    (psKernelNatReductionDifferential
      psKernelNatAddName
      PSC1Kernel.kernelNatAddName
      12 30 maxSize)
    (Bool.and
      (psKernelNatReductionDifferential
        psKernelNatSubName
        PSC1Kernel.kernelNatSubName
        3 8 maxSize)
      (Bool.and
        (psKernelNatReductionDifferential
          psKernelNatMulName
          PSC1Kernel.kernelNatMulName
          7 6 maxSize)
        (Bool.and
          (psKernelNatReductionDifferential
            psKernelNatPowName
            PSC1Kernel.kernelNatPowName
            3 5 maxSize)
          (Bool.and
            (psKernelNatReductionDifferential
              psKernelNatGcdName
              PSC1Kernel.kernelNatGcdName
              48 18 maxSize)
            (Bool.and
              (psKernelNatReductionDifferential
                psKernelNatModName
                PSC1Kernel.kernelNatModName
                17 5 maxSize)
              (Bool.and
                (psKernelNatReductionDifferential
                  psKernelNatDivName
                  PSC1Kernel.kernelNatDivName
                  17 5 maxSize)
                (Bool.and
                  (psKernelNatReductionDifferential
                    psKernelNatBeqName
                    PSC1Kernel.kernelNatBeqName
                    5 5 maxSize)
                  (Bool.and
                    (psKernelNatReductionDifferential
                      psKernelNatBleName
                      PSC1Kernel.kernelNatBleName
                      5 7 maxSize)
                    (Bool.and
                      (psKernelNatReductionDifferential
                        psKernelNatLandName
                        PSC1Kernel.kernelNatLandName
                        13 10 maxSize)
                      (Bool.and
                        (psKernelNatReductionDifferential
                          psKernelNatLorName
                          PSC1Kernel.kernelNatLorName
                          13 10 maxSize)
                        (Bool.and
                          (psKernelNatReductionDifferential
                            psKernelNatXorName
                            PSC1Kernel.kernelNatXorName
                            13 10 maxSize)
                          (Bool.and
                            (psKernelNatReductionDifferential
                              psKernelNatShiftLeftName
                              PSC1Kernel.kernelNatShiftLeftName
                              3 4 maxSize)
                            (psKernelNatReductionDifferential
                              psKernelNatShiftRightName
                              PSC1Kernel.kernelNatShiftRightName
                              48 3 maxSize)))))))))))))

def psKernelSelfHostPrimitiveBoundaryTests : Bool :=
  Bool.and
    (psKernelNatSizeInBytes 0 ==
      PSC1Kernel.natSizeInBytes 0)
    (Bool.and
      (psKernelNatSizeInBytes 18446744073709551616 ==
        PSC1Kernel.natSizeInBytes 18446744073709551616)
      (Bool.and
        (psKernelNatReductionDifferential
          psKernelNatShiftLeftName
          PSC1Kernel.kernelNatShiftLeftName
          1
          4294967296
          psKernelLeanNatMaxSizeDefault)
        (psKernelNatReductionDifferential
          psKernelNatPowName
          PSC1Kernel.kernelNatPowName
          2
          64
          8)))

def psKernelSelfHostPrimitiveStringTests : Bool :=
  PSC1Kernel.Expr.eq
    (psKernelExprToReference
      (psKernelStringLitToConstructor "Aλ"))
    (PSC1Kernel.stringLitToConstructor "Aλ")

def psKernelSelfHostPrimitiveTests : Bool :=
  Bool.and
    psKernelSelfHostPrimitiveNatTests
    (Bool.and
      psKernelSelfHostPrimitiveBoundaryTests
      psKernelSelfHostPrimitiveStringTests)

def psKernelWhnfDifferentialCase
    (expr : PsKernelExpr) : Bool :=
  let portableContext :=
    psKernelCheckerContextEmpty
      psKernelEnvironmentEmpty
  let referenceContext :=
    PSC1Kernel.CheckerContext.empty
      PSC1Kernel.Environment.empty
  match
      psKernelWhnfNoRecursor
        256
        portableContext
        psKernelCheckerStateEmpty
        expr,
      PSC1Kernel.whnf
        referenceContext
        (psKernelExprToReference expr) with
  | Except.ok portableResult, Except.ok referenceResult =>
      psKernelExprReferenceEq
        (Prod.fst portableResult)
        referenceResult
  | Except.error portableError, Except.error referenceError =>
      portableError == referenceError
  | _, _ =>
      false

def psKernelWhnfLocalLetDifferential : Bool :=
  let userName :=
    PsKernelName.str
      PsKernelName.anonymous
      "local"
  let type :=
    PsKernelExpr.sort PsKernelLevel.zero
  let value :=
    PsKernelExpr.lit (PsKernelLiteral.nat 11)
  let portableAdded :=
    psKernelCheckerContextWithLet
      (psKernelCheckerContextEmpty
        psKernelEnvironmentEmpty)
      userName
      type
      value
  let portableName :=
    Prod.fst portableAdded
  let portableContext :=
    Prod.snd portableAdded
  let referenceAdded :=
    (PSC1Kernel.CheckerContext.empty
      PSC1Kernel.Environment.empty).withLet
      (psKernelNameToReference userName)
      (psKernelExprToReference type)
      (psKernelExprToReference value)
  let referenceName :=
    Prod.fst referenceAdded
  let referenceContext :=
    Prod.snd referenceAdded
  match
      psKernelWhnfNoRecursor
        256
        portableContext
        psKernelCheckerStateEmpty
        (PsKernelExpr.fvar portableName),
      PSC1Kernel.whnf
        referenceContext
        (PSC1Kernel.Expr.fvar referenceName) with
  | Except.ok portableResult, Except.ok referenceResult =>
      psKernelExprReferenceEq
        (Prod.fst portableResult)
        referenceResult
  | _, _ =>
      false

def psKernelNativeReductionDifferential : Bool :=
  let natTarget :=
    PsKernelName.str
      PsKernelName.anonymous
      "NativeNat"
  let boolTarget :=
    PsKernelName.str
      PsKernelName.anonymous
      "NativeBool"
  let referenceNatTarget :=
    psKernelNameToReference natTarget
  let referenceBoolTarget :=
    psKernelNameToReference boolTarget
  let portableProvider : PsKernelNativeEvaluator := {
    evalBool := fun name =>
      if psKernelNameEq name boolTarget then
        Except.ok (Option.some true)
      else
        Except.ok Option.none
    evalNat := fun name =>
      if psKernelNameEq name natTarget then
        Except.ok (Option.some 42)
      else
        Except.ok Option.none
  }
  let referenceProvider : PSC1Kernel.NativeEvaluator := {
    evalBool := fun name =>
      if PSC1Kernel.Name.eq name referenceBoolTarget then
        Except.ok (Option.some true)
      else
        Except.ok Option.none
    evalNat := fun name =>
      if PSC1Kernel.Name.eq name referenceNatTarget then
        Except.ok (Option.some 42)
      else
        Except.ok Option.none
  }
  let portableEnvironment :=
    psKernelEnvironmentWithNativeEvaluator
      psKernelEnvironmentEmpty
      (Option.some portableProvider)
  let portableContext :=
    psKernelCheckerContextEmpty
      portableEnvironment
  let referenceBase :=
    PSC1Kernel.CheckerContext.empty
      PSC1Kernel.Environment.empty
  let referenceContext : PSC1Kernel.CheckerContext :=
    {
      referenceBase with
      nativeEvaluator := Option.some referenceProvider
    }
  let portableNat :=
    PsKernelExpr.app
      (PsKernelExpr.const
        psKernelReduceNatName
        List.nil)
      (PsKernelExpr.const
        natTarget
        List.nil)
  let referenceNat :=
    PSC1Kernel.Expr.app
      (PSC1Kernel.Expr.const
        PSC1Kernel.kernelReduceNatName
        List.nil)
      (PSC1Kernel.Expr.const
        referenceNatTarget
        List.nil)
  let portableBool :=
    PsKernelExpr.app
      (PsKernelExpr.const
        psKernelReduceBoolName
        List.nil)
      (PsKernelExpr.const
        boolTarget
        List.nil)
  let referenceBool :=
    PSC1Kernel.Expr.app
      (PSC1Kernel.Expr.const
        PSC1Kernel.kernelReduceBoolName
        List.nil)
      (PSC1Kernel.Expr.const
        referenceBoolTarget
        List.nil)
  match
      psKernelWhnfNoRecursor
        256
        portableContext
        psKernelCheckerStateEmpty
        portableNat,
      PSC1Kernel.whnf
        referenceContext
        referenceNat with
  | Except.ok portableNatResult, Except.ok referenceNatResult =>
      if
          psKernelExprReferenceEq
            (Prod.fst portableNatResult)
            referenceNatResult then
        match
            psKernelWhnfNoRecursor
              256
              portableContext
              (Prod.snd portableNatResult)
              portableBool,
            PSC1Kernel.whnf
              referenceContext
              referenceBool with
        | Except.ok portableBoolResult, Except.ok referenceBoolResult =>
            psKernelExprReferenceEq
              (Prod.fst portableBoolResult)
              referenceBoolResult
        | _, _ =>
            false
      else
        false
  | _, _ =>
      false

def psKernelWhnfCacheTest : Bool :=
  let expr :=
    PsKernelExpr.app
      (PsKernelExpr.lam
        PsKernelName.anonymous
        (PsKernelExpr.sort PsKernelLevel.zero)
        (PsKernelExpr.bvar 0)
        PsKernelBinderInfo.default)
      (PsKernelExpr.lit
        (PsKernelLiteral.nat 7))
  match
      psKernelWhnfNoRecursor
        256
        (psKernelCheckerContextEmpty
          psKernelEnvironmentEmpty)
        psKernelCheckerStateEmpty
        expr with
  | Except.error _ =>
      false
  | Except.ok result =>
      let state :=
        Prod.snd result
      match
          psKernelExprMapGet
            state.whnf
            expr with
      | Option.none => false
      | Option.some cached =>
          psKernelExprEq
            cached
            (Prod.fst result)

def psKernelWhnfFuelExhaustionTest : Bool :=
  match
      psKernelWhnfNoRecursor
        0
        (psKernelCheckerContextEmpty
          psKernelEnvironmentEmpty)
        psKernelCheckerStateEmpty
        (PsKernelExpr.bvar 0) with
  | Except.error _ => true
  | Except.ok _ => false

def psKernelSelfHostWhnfTests : Bool :=
  let type :=
    PsKernelExpr.sort PsKernelLevel.zero
  let beta :=
    PsKernelExpr.app
      (PsKernelExpr.lam
        PsKernelName.anonymous
        type
        (PsKernelExpr.bvar 0)
        PsKernelBinderInfo.default)
      (PsKernelExpr.lit
        (PsKernelLiteral.nat 42))
  let zeta :=
    PsKernelExpr.letE
      PsKernelName.anonymous
      type
      (PsKernelExpr.lit
        (PsKernelLiteral.nat 9))
      (PsKernelExpr.bvar 0)
      false
  let natSucc :=
    PsKernelExpr.app
      (PsKernelExpr.const
        psKernelNatSuccName
        List.nil)
      (PsKernelExpr.lit
        (PsKernelLiteral.nat 5))
  let natAdd :=
    PsKernelExpr.app
      (PsKernelExpr.app
        (PsKernelExpr.const
          psKernelNatAddName
          List.nil)
        (PsKernelExpr.lit
          (PsKernelLiteral.nat 4)))
      (PsKernelExpr.lit
        (PsKernelLiteral.nat 9))
  Bool.and
    (psKernelWhnfDifferentialCase beta)
    (Bool.and
      (psKernelWhnfDifferentialCase zeta)
      (Bool.and
        (psKernelWhnfDifferentialCase natSucc)
        (Bool.and
          (psKernelWhnfDifferentialCase natAdd)
          (Bool.and
            psKernelWhnfLocalLetDifferential
            (Bool.and
              psKernelNativeReductionDifferential
              (Bool.and
                psKernelWhnfCacheTest
                psKernelWhnfFuelExhaustionTest))))))

def psKernelInferenceWhnf
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  psKernelWhnfNoRecursor
    512
    context
    state
    expr

def psKernelInferenceStructuralDefEq
    (_context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Except String
      (Prod Bool PsKernelCheckerState) :=
  Except.ok
    (Prod.mk
      (psKernelExprEq left right)
      state)

def psKernelInferDifferentialCase
    (expr : PsKernelExpr) : Bool :=
  let portableContext :=
    psKernelCheckerContextEmpty
      psKernelEnvironmentEmpty;
  let referenceContext :=
    PSC1Kernel.CheckerContext.empty
      PSC1Kernel.Environment.empty;
  match
      psKernelInferWithFuel
        512
        psKernelInferenceWhnf
        psKernelInferenceStructuralDefEq
        portableContext
        psKernelCheckerStateEmpty
        expr,
      PSC1Kernel.infer
        referenceContext
        (psKernelExprToReference expr) with
  | Except.ok portableResult, Except.ok referenceResult =>
      psKernelExprReferenceEq
        (Prod.fst portableResult)
        referenceResult
  | Except.error portableError, Except.error referenceError =>
      portableError == referenceError
  | _, _ =>
      false

def psKernelSelfHostInferTests : Bool :=
  let propSort :=
    PsKernelExpr.sort
      PsKernelLevel.zero;
  let typeSort :=
    PsKernelExpr.sort
      (PsKernelLevel.succ PsKernelLevel.zero);
  let binderName :=
    PsKernelName.str
      PsKernelName.anonymous
      "x";
  let innerName :=
    PsKernelName.str
      PsKernelName.anonymous
      "y";
  let identity :=
    PsKernelExpr.lam
      binderName
      propSort
      (PsKernelExpr.bvar 0)
      PsKernelBinderInfo.default;
  let nested :=
    PsKernelExpr.lam
      binderName
      typeSort
      (PsKernelExpr.lam
        innerName
        (PsKernelExpr.bvar 0)
        (PsKernelExpr.bvar 0)
        PsKernelBinderInfo.default)
      PsKernelBinderInfo.default;
  let forallExpr :=
    PsKernelExpr.forallE
      binderName
      propSort
      propSort
      PsKernelBinderInfo.default;
  let letExpr :=
    PsKernelExpr.letE
      binderName
      propSort
      propSort
      (PsKernelExpr.bvar 0)
      false;
  let appliedNested :=
    PsKernelExpr.app
      nested
      propSort;
  Bool.and
    (psKernelInferDifferentialCase propSort)
    (Bool.and
      (psKernelInferDifferentialCase
        (PsKernelExpr.lit
          (PsKernelLiteral.nat 17)))
      (Bool.and
        (psKernelInferDifferentialCase
          (PsKernelExpr.lit
            (PsKernelLiteral.str "λ")))
        (Bool.and
          (psKernelInferDifferentialCase identity)
          (Bool.and
            (psKernelInferDifferentialCase nested)
            (Bool.and
              (psKernelInferDifferentialCase forallExpr)
              (Bool.and
                (psKernelInferDifferentialCase letExpr)
                (psKernelInferDifferentialCase appliedNested)))))))

def psKernelProjectionBoxName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "PortableProjectionBox"

def psKernelProjectionCtorName : PsKernelName :=
  PsKernelName.str
    psKernelProjectionBoxName
    "mk"

def psKernelProjectionBoxExpr : PsKernelExpr :=
  PsKernelExpr.const
    psKernelProjectionBoxName
    List.nil

def psKernelProjectionCtorType : PsKernelExpr :=
  let firstName :=
    PsKernelName.str
      PsKernelName.anonymous
      "first";
  let secondName :=
    PsKernelName.str
      PsKernelName.anonymous
      "second";
  PsKernelExpr.forallE
    firstName
    (PsKernelExpr.sort PsKernelLevel.zero)
    (PsKernelExpr.forallE
      secondName
      (PsKernelExpr.bvar 0)
      psKernelProjectionBoxExpr
      PsKernelBinderInfo.default)
    PsKernelBinderInfo.default

def psKernelProjectionEnvironment : PsKernelEnvironment :=
  let inductBase : PsKernelConstantBase :=
    {
      name := psKernelProjectionBoxName
      levelParams := List.nil
      type :=
        PsKernelExpr.sort
          (PsKernelLevel.succ PsKernelLevel.zero)
    };
  let inductInfo : PsKernelInductiveInfo :=
    {
      base := inductBase
      numParams := 0
      numIndices := 0
      all :=
        List.cons
          psKernelProjectionBoxName
          List.nil
      ctors :=
        List.cons
          psKernelProjectionCtorName
          List.nil
      numNested := 0
      isRec := false
      isReflexive := false
      isUnsafe := false
    };
  let ctorBase : PsKernelConstantBase :=
    {
      name := psKernelProjectionCtorName
      levelParams := List.nil
      type := psKernelProjectionCtorType
    };
  let ctorInfo : PsKernelConstructorInfo :=
    {
      base := ctorBase
      induct := psKernelProjectionBoxName
      cidx := 0
      numParams := 0
      numFields := 2
      isUnsafe := false
    };
  psKernelEnvironmentAddUnchecked
    (psKernelEnvironmentAddUnchecked
      psKernelEnvironmentEmpty
      (PsKernelConstantInfo.inductInfo
        inductInfo))
    (PsKernelConstantInfo.ctorInfo
      ctorInfo)

def psKernelProjectionReferenceEnvironment :
    PSC1Kernel.Environment :=
  let boxName :=
    psKernelNameToReference
      psKernelProjectionBoxName;
  let ctorName :=
    psKernelNameToReference
      psKernelProjectionCtorName;
  let inductBase : PSC1Kernel.ConstantBase :=
    {
      name := boxName
      levelParams := List.nil
      type :=
        psKernelExprToReference
          (PsKernelExpr.sort
            (PsKernelLevel.succ
              PsKernelLevel.zero))
    };
  let inductInfo : PSC1Kernel.InductiveInfo :=
    {
      base := inductBase
      numParams := 0
      numIndices := 0
      all := List.cons boxName List.nil
      ctors := List.cons ctorName List.nil
      numNested := 0
      isRec := false
      isReflexive := false
      isUnsafe := false
    };
  let ctorBase : PSC1Kernel.ConstantBase :=
    {
      name := ctorName
      levelParams := List.nil
      type :=
        psKernelExprToReference
          psKernelProjectionCtorType
    };
  let ctorInfo : PSC1Kernel.ConstructorInfo :=
    {
      base := ctorBase
      induct := boxName
      cidx := 0
      numParams := 0
      numFields := 2
      isUnsafe := false
    };
  (PSC1Kernel.Environment.empty.addUnchecked
    (PSC1Kernel.ConstantInfo.inductInfo
      inductInfo)).addUnchecked
        (PSC1Kernel.ConstantInfo.ctorInfo
          ctorInfo)

def psKernelProjectionDifferential
    (index : Nat) : Bool :=
  let userName :=
    PsKernelName.str
      PsKernelName.anonymous
      "boxValue";
  let portableAdded :=
    psKernelCheckerContextWithLocal
      (psKernelCheckerContextEmpty
        psKernelProjectionEnvironment)
      userName
      psKernelProjectionBoxExpr
      PsKernelBinderInfo.default;
  let portableName :=
    Prod.fst portableAdded;
  let portableContext :=
    Prod.snd portableAdded;
  let referenceAdded :=
    (PSC1Kernel.CheckerContext.empty
      psKernelProjectionReferenceEnvironment).withLocal
        (psKernelNameToReference userName)
        (psKernelExprToReference
          psKernelProjectionBoxExpr)
        PSC1Kernel.BinderInfo.default;
  let referenceName :=
    Prod.fst referenceAdded;
  let referenceContext :=
    Prod.snd referenceAdded;
  let portableExpr :=
    PsKernelExpr.proj
      psKernelProjectionBoxName
      index
      (PsKernelExpr.fvar portableName);
  let referenceExpr :=
    PSC1Kernel.Expr.proj
      (psKernelNameToReference
        psKernelProjectionBoxName)
      index
      (PSC1Kernel.Expr.fvar
        referenceName);
  match
      psKernelInferWithFuel
        512
        psKernelInferenceWhnf
        psKernelInferenceStructuralDefEq
        portableContext
        psKernelCheckerStateEmpty
        portableExpr,
      PSC1Kernel.infer
        referenceContext
        referenceExpr with
  | Except.ok portableResult, Except.ok referenceResult =>
      psKernelExprReferenceEq
        (Prod.fst portableResult)
        referenceResult
  | Except.error portableError, Except.error referenceError =>
      portableError == referenceError
  | _, _ =>
      false

def psKernelSelfHostProjectionTests : Bool :=
  Bool.and
    (psKernelProjectionDifferential 0)
    (psKernelProjectionDifferential 1)

def psKernelSelfHostRecursorTests : Bool :=
  let inductName :=
    PsKernelName.str
      PsKernelName.anonymous
      "RecI";
  let ctorName :=
    PsKernelName.str
      inductName
      "mk";
  let recName :=
    PsKernelName.str
      inductName
      "rec";
  let majorName :=
    PsKernelName.str
      PsKernelName.anonymous
      "h";
  let inductType :=
    PsKernelExpr.sort
      (PsKernelLevel.succ PsKernelLevel.zero);
  let inductExpr :=
    PsKernelExpr.const
      inductName
      List.nil;
  let portableEnv0 :=
    psKernelEnvironmentAddUnchecked
      psKernelEnvironmentEmpty
      (PsKernelConstantInfo.inductInfo {
        base := {
          name := inductName
          levelParams := List.nil
          type := inductType
        }
        numParams := 0
        numIndices := 0
        all := List.cons inductName List.nil
        ctors := List.cons ctorName List.nil
        numNested := 0
        isRec := false
        isReflexive := true
        isUnsafe := false
      });
  let portableEnv1 :=
    psKernelEnvironmentAddUnchecked
      portableEnv0
      (PsKernelConstantInfo.ctorInfo {
        base := {
          name := ctorName
          levelParams := List.nil
          type := inductExpr
        }
        induct := inductName
        cidx := 0
        numParams := 0
        numFields := 0
        isUnsafe := false
      });
  let portableEnv :=
    psKernelEnvironmentAddUnchecked
      portableEnv1
      (PsKernelConstantInfo.recInfo {
        base := {
          name := recName
          levelParams := List.nil
          type :=
            PsKernelExpr.forallE
              majorName
              inductExpr
              (PsKernelExpr.sort
                (PsKernelLevel.succ PsKernelLevel.zero))
              PsKernelBinderInfo.default
        }
        all := List.cons inductName List.nil
        numParams := 0
        numIndices := 0
        numMotives := 0
        numMinors := 0
        rules :=
          List.cons
            {
              ctor := ctorName
              nFields := 0
              rhs := PsKernelExpr.sort PsKernelLevel.zero
            }
            List.nil
        k := true
        isUnsafe := false
      });
  let portableLocal :=
    psKernelLocalContextAddLocal
      psKernelLocalContextEmpty
      majorName
      majorName
      inductExpr
      PsKernelBinderInfo.default;
  let portableContext :=
    psKernelCheckerContextWithLocalContext
      (psKernelCheckerContextEmpty portableEnv)
      portableLocal;
  let portableMajor :=
    PsKernelExpr.fvar majorName;
  let portableInput :=
    PsKernelExpr.app
      (PsKernelExpr.const recName List.nil)
      portableMajor;
  let referenceInductName :=
    psKernelNameToReference inductName;
  let referenceCtorName :=
    psKernelNameToReference ctorName;
  let referenceRecName :=
    psKernelNameToReference recName;
  let referenceMajorName :=
    psKernelNameToReference majorName;
  let referenceInductType :=
    psKernelExprToReference inductType;
  let referenceInductExpr :=
    psKernelExprToReference inductExpr;
  let referenceEnv0 :=
    PSC1Kernel.Environment.empty.addUnchecked
      (PSC1Kernel.ConstantInfo.inductInfo {
        base := {
          name := referenceInductName
          levelParams := List.nil
          type := referenceInductType
        }
        numParams := 0
        numIndices := 0
        all := List.cons referenceInductName List.nil
        ctors := List.cons referenceCtorName List.nil
        numNested := 0
        isRec := false
        isReflexive := true
        isUnsafe := false
      });
  let referenceEnv1 :=
    referenceEnv0.addUnchecked
      (PSC1Kernel.ConstantInfo.ctorInfo {
        base := {
          name := referenceCtorName
          levelParams := List.nil
          type := referenceInductExpr
        }
        induct := referenceInductName
        cidx := 0
        numParams := 0
        numFields := 0
        isUnsafe := false
      });
  let referenceEnv :=
    referenceEnv1.addUnchecked
      (PSC1Kernel.ConstantInfo.recInfo {
        base := {
          name := referenceRecName
          levelParams := List.nil
          type :=
            PSC1Kernel.Expr.forallE
              referenceMajorName
              referenceInductExpr
              (PSC1Kernel.Expr.sort
                (PSC1Kernel.Level.succ PSC1Kernel.Level.zero))
              PSC1Kernel.BinderInfo.default
        }
        all := List.cons referenceInductName List.nil
        numParams := 0
        numIndices := 0
        numMotives := 0
        numMinors := 0
        rules :=
          List.cons
            {
              ctor := referenceCtorName
              nFields := 0
              rhs := PSC1Kernel.Expr.sort PSC1Kernel.Level.zero
            }
            List.nil
        k := true
        isUnsafe := false
      });
  let referenceLocal :=
    PSC1Kernel.LocalContext.empty.addLocal
      referenceMajorName
      referenceMajorName
      referenceInductExpr
      PSC1Kernel.BinderInfo.default;
  let referenceContext :=
    {
      PSC1Kernel.CheckerContext.empty referenceEnv with
      lctx := referenceLocal
    };
  let referenceInput :=
    PSC1Kernel.Expr.app
      (PSC1Kernel.Expr.const referenceRecName List.nil)
      (PSC1Kernel.Expr.fvar referenceMajorName);
  match
      psKernelWhnfWithRecursorFuel
        512
        psKernelInferenceStructuralDefEq
        portableContext
        psKernelCheckerStateEmpty
        portableInput,
      PSC1Kernel.whnf
        referenceContext
        referenceInput with
  | Except.ok portableResult, Except.ok referenceResult =>
      Bool.and
        (psKernelExprReferenceEq
          (Prod.fst portableResult)
          referenceResult)
        (match
            psKernelExprMapGet
              (Prod.snd portableResult).inferOnly
              portableMajor with
         | Option.some _ => true
         | Option.none => false)
  | _, _ =>
      false

def psKernelDefEqConstName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "defeqValue"

def psKernelDefEqPropName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "DefEqProp"

def psKernelDefEqEnvironment : PsKernelEnvironment :=
  let natBase : PsKernelConstantBase :=
    {
      name := psKernelNatName
      levelParams := List.nil
      type :=
        PsKernelExpr.sort
          (PsKernelLevel.succ PsKernelLevel.zero)
    };
  let propBase : PsKernelConstantBase :=
    {
      name := psKernelDefEqPropName
      levelParams := List.nil
      type :=
        PsKernelExpr.sort PsKernelLevel.zero
    };
  let defBase : PsKernelConstantBase :=
    {
      name := psKernelDefEqConstName
      levelParams := List.nil
      type :=
        PsKernelExpr.const
          psKernelNatName
          List.nil
    };
  let env1 :=
    psKernelEnvironmentAddUnchecked
      psKernelEnvironmentEmpty
      (PsKernelConstantInfo.axiomInfo {
        base := natBase
        isUnsafe := false
      });
  let env2 :=
    psKernelEnvironmentAddUnchecked
      env1
      (PsKernelConstantInfo.axiomInfo {
        base := propBase
        isUnsafe := false
      });
  psKernelEnvironmentAddUnchecked
    env2
    (PsKernelConstantInfo.defnInfo {
      base := defBase
      value :=
        PsKernelExpr.lit
          (PsKernelLiteral.nat 7)
      hints := PsKernelReducibilityHints.regular 0
      safety := PsKernelDefinitionSafety.safe
    })

def psKernelDefEqReferenceEnvironment :
    PSC1Kernel.Environment :=
  let natBase : PSC1Kernel.ConstantBase :=
    {
      name := PSC1Kernel.kernelNatName
      levelParams := List.nil
      type :=
        PSC1Kernel.Expr.sort
          (PSC1Kernel.Level.succ
            PSC1Kernel.Level.zero)
    };
  let propName :=
    psKernelNameToReference
      psKernelDefEqPropName;
  let propBase : PSC1Kernel.ConstantBase :=
    {
      name := propName
      levelParams := List.nil
      type :=
        PSC1Kernel.Expr.sort
          PSC1Kernel.Level.zero
    };
  let defBase : PSC1Kernel.ConstantBase :=
    {
      name :=
        psKernelNameToReference
          psKernelDefEqConstName
      levelParams := List.nil
      type :=
        PSC1Kernel.Expr.const
          PSC1Kernel.kernelNatName
          List.nil
    };
  let env1 :=
    PSC1Kernel.Environment.empty.addUnchecked
      (PSC1Kernel.ConstantInfo.axiomInfo {
        base := natBase
        isUnsafe := false
      });
  let env2 :=
    env1.addUnchecked
      (PSC1Kernel.ConstantInfo.axiomInfo {
        base := propBase
        isUnsafe := false
      });
  env2.addUnchecked
    (PSC1Kernel.ConstantInfo.defnInfo {
      base := defBase
      value :=
        PSC1Kernel.Expr.lit
          (PSC1Kernel.Literal.nat 7)
      hints := PSC1Kernel.ReducibilityHints.regular 0
      safety := PSC1Kernel.DefinitionSafety.safe
    })

def psKernelDefEqDifferential
    (portableContext : PsKernelCheckerContext)
    (referenceContext : PSC1Kernel.CheckerContext)
    (left right : PsKernelExpr) : Bool :=
  match
      psKernelIsDefEq
        2048
        portableContext
        psKernelCheckerStateEmpty
        left
        right,
      PSC1Kernel.isDefEq
        referenceContext
        (psKernelExprToReference left)
        (psKernelExprToReference right) with
  | Except.ok portableResult, Except.ok referenceResult =>
      Bool.and
        ((Prod.fst portableResult) == referenceResult)
        (if Prod.fst portableResult then
          psKernelExprPairSetContains
            (Prod.snd portableResult).success
            left
            right
         else
          true)
  | Except.error portableError, Except.error referenceError =>
      portableError == referenceError
  | _, _ =>
      false

def psKernelSelfHostDefEqTests : Bool :=
  let portableBase :=
    psKernelCheckerContextEmpty
      psKernelDefEqEnvironment;
  let referenceBase :=
    PSC1Kernel.CheckerContext.empty
      psKernelDefEqReferenceEnvironment;
  let natType :=
    PsKernelExpr.const
      psKernelNatName
      List.nil;
  let betaLeft :=
    PsKernelExpr.app
      (PsKernelExpr.lam
        PsKernelName.anonymous
        natType
        (PsKernelExpr.bvar 0)
        PsKernelBinderInfo.default)
      (PsKernelExpr.lit
        (PsKernelLiteral.nat 9));
  let betaRight :=
    PsKernelExpr.lit
      (PsKernelLiteral.nat 9);
  let deltaLeft :=
    PsKernelExpr.const
      psKernelDefEqConstName
      List.nil;
  let deltaRight :=
    PsKernelExpr.lit
      (PsKernelLiteral.nat 7);
  let proofLeftName :=
    PsKernelName.str
      PsKernelName.anonymous
      "proofLeft";
  let proofRightName :=
    PsKernelName.str
      PsKernelName.anonymous
      "proofRight";
  let propType :=
    PsKernelExpr.const
      psKernelDefEqPropName
      List.nil;
  let portableProofLctx1 :=
    psKernelLocalContextAddLocal
      portableBase.localContext
      proofLeftName
      proofLeftName
      propType
      PsKernelBinderInfo.default;
  let portableProofLctx :=
    psKernelLocalContextAddLocal
      portableProofLctx1
      proofRightName
      proofRightName
      propType
      PsKernelBinderInfo.default;
  let portableProofContext :=
    psKernelCheckerContextWithLocalContext
      portableBase
      portableProofLctx;
  let referenceProofLeftName :=
    psKernelNameToReference proofLeftName;
  let referenceProofRightName :=
    psKernelNameToReference proofRightName;
  let referencePropType :=
    psKernelExprToReference propType;
  let referenceProofLctx1 :=
    referenceBase.lctx.addLocal
      referenceProofLeftName
      referenceProofLeftName
      referencePropType
      PSC1Kernel.BinderInfo.default;
  let referenceProofLctx :=
    referenceProofLctx1.addLocal
      referenceProofRightName
      referenceProofRightName
      referencePropType
      PSC1Kernel.BinderInfo.default;
  let referenceProofContext :=
    {
      referenceBase with
      lctx := referenceProofLctx
    };
  let functionName :=
    PsKernelName.str
      PsKernelName.anonymous
      "function";
  let functionType :=
    PsKernelExpr.forallE
      PsKernelName.anonymous
      natType
      natType
      PsKernelBinderInfo.default;
  let portableEtaAdded :=
    psKernelCheckerContextWithLocal
      portableBase
      functionName
      functionType
      PsKernelBinderInfo.default;
  let portableFunctionName :=
    Prod.fst portableEtaAdded;
  let portableEtaContext :=
    Prod.snd portableEtaAdded;
  let referenceEtaAdded :=
    referenceBase.withLocal
      (psKernelNameToReference functionName)
      (psKernelExprToReference functionType)
      PSC1Kernel.BinderInfo.default;
  let referenceFunctionName :=
    Prod.fst referenceEtaAdded;
  let referenceEtaContext :=
    Prod.snd referenceEtaAdded;
  let etaLeft :=
    PsKernelExpr.lam
      PsKernelName.anonymous
      natType
      (PsKernelExpr.app
        (PsKernelExpr.fvar portableFunctionName)
        (PsKernelExpr.bvar 0))
      PsKernelBinderInfo.default;
  let etaRight :=
    PsKernelExpr.fvar portableFunctionName;
  let referenceEtaLeft :=
    PSC1Kernel.Expr.lam
      PSC1Kernel.Name.anonymous
      (psKernelExprToReference natType)
      (PSC1Kernel.Expr.app
        (PSC1Kernel.Expr.fvar referenceFunctionName)
        (PSC1Kernel.Expr.bvar 0))
      PSC1Kernel.BinderInfo.default;
  let referenceEtaRight :=
    PSC1Kernel.Expr.fvar referenceFunctionName;
  let etaDifferential :=
    match
        psKernelIsDefEq
          2048
          portableEtaContext
          psKernelCheckerStateEmpty
          etaLeft
          etaRight,
        PSC1Kernel.isDefEq
          referenceEtaContext
          referenceEtaLeft
          referenceEtaRight with
    | Except.ok portableResult, Except.ok referenceResult =>
        (Prod.fst portableResult) == referenceResult
    | _, _ =>
        false;
  Bool.and
    (psKernelDefEqDifferential
      portableBase
      referenceBase
      betaLeft
      betaRight)
    (Bool.and
      (psKernelDefEqDifferential
        portableBase
        referenceBase
        deltaLeft
        deltaRight)
      (Bool.and
        (psKernelDefEqDifferential
          portableProofContext
          referenceProofContext
          (PsKernelExpr.fvar proofLeftName)
          (PsKernelExpr.fvar proofRightName))
        etaDifferential))


def psKernelConstantListUsesNestedPrefix
    (values : List PsKernelConstantInfo) : Bool :=
  match values with
  | List.nil =>
      false
  | List.cons info rest =>
      if
          psKernelNameIsPrefixOf
            psKernelSimpleNestedPrefix
            (psKernelConstantInfoName info) then
        true
      else
        psKernelConstantListUsesNestedPrefix rest

def psKernelSelfHostNestedTests : Bool :=
  let type1 :=
    PsKernelExpr.sort
      (PsKernelLevel.succ
        PsKernelLevel.zero)
  let boxName :=
    PsKernelName.str
      PsKernelName.anonymous
      "PortableNestedBox"
  let boxMkName :=
    PsKernelName.str
      boxName
      "mk"
  let alphaName :=
    PsKernelName.str
      PsKernelName.anonymous
      "alpha"
  let valueName :=
    PsKernelName.str
      PsKernelName.anonymous
      "value"
  let boxType :=
    PsKernelExpr.forallE
      alphaName
      type1
      type1
      PsKernelBinderInfo.default
  let boxCtorType :=
    PsKernelExpr.forallE
      alphaName
      type1
      (PsKernelExpr.forallE
        valueName
        (PsKernelExpr.bvar 0)
        (PsKernelExpr.app
          (PsKernelExpr.const
            boxName
            List.nil)
          (PsKernelExpr.bvar 1))
        PsKernelBinderInfo.default)
      PsKernelBinderInfo.default
  let treeName :=
    PsKernelName.str
      PsKernelName.anonymous
      "PortableNestedTree"
  let leafName :=
    PsKernelName.str
      treeName
      "leaf"
  let nodeName :=
    PsKernelName.str
      treeName
      "node"
  let recName :=
    psKernelSimpleRecName
      treeName
  let recAuxName :=
    psKernelNameAppendIndexAfter
      recName
      1
  let treeType :=
    PsKernelExpr.const
      treeName
      List.nil
  let boxTreeType :=
    PsKernelExpr.app
      (PsKernelExpr.const
        boxName
        List.nil)
      treeType
  let nodeType :=
    PsKernelExpr.forallE
      (PsKernelName.str
        PsKernelName.anonymous
        "children")
      boxTreeType
      treeType
      PsKernelBinderInfo.default
  let portableBox :=
    psKernelAddSimpleInductive
      4096
      psKernelEnvironmentEmpty
      (PsKernelSimpleInductiveDecl.mk
        List.nil
        boxName
        boxType
        (List.cons
          (PsKernelSimpleConstructorDecl.mk
            boxMkName
            boxCtorType)
          List.nil)
        false
        1)
      0
      psKernelLeanNatMaxSizeDefault
  let portableNested :=
    match portableBox with
    | Except.error _ =>
        Except.error "outer box admission failed"
    | Except.ok environment =>
        psKernelAddSimpleNestedInductive
          4096
          environment
          (PsKernelSimpleMutualInductiveDecl.mk
            List.nil
            0
            (List.cons
              (PsKernelSimpleMutualTypeDecl.mk
                treeName
                type1
                (List.cons
                  (PsKernelSimpleConstructorDecl.mk
                    leafName
                    treeType)
                  (List.cons
                    (PsKernelSimpleConstructorDecl.mk
                      nodeName
                      nodeType)
                    List.nil)))
              List.nil)
            false)
          0
          psKernelLeanNatMaxSizeDefault
  let referenceBoxName :=
    psKernelNameToReference boxName
  let referenceBoxMkName :=
    psKernelNameToReference boxMkName
  let referenceTreeName :=
    psKernelNameToReference treeName
  let referenceLeafName :=
    psKernelNameToReference leafName
  let referenceNodeName :=
    psKernelNameToReference nodeName
  let referenceRecName :=
    psKernelNameToReference recName
  let referenceRecAuxName :=
    psKernelNameToReference recAuxName
  let referenceBox :=
    PSC1Kernel.Kernel.addSimpleInductive
      PSC1Kernel.Environment.empty
      {
        levelParams := []
        name := referenceBoxName
        type := psKernelExprToReference boxType
        ctors := [{
          name := referenceBoxMkName
          type := psKernelExprToReference boxCtorType
        }]
        isUnsafe := false
        numParams := 1
      }
  let referenceNested :=
    match referenceBox with
    | Except.error error =>
        Except.error error
    | Except.ok environment =>
        PSC1Kernel.Kernel.addSimpleNestedInductive
          environment
          {
            levelParams := []
            numParams := 0
            types := [{
              name := referenceTreeName
              type := psKernelExprToReference type1
              ctors := [
                {
                  name := referenceLeafName
                  type := psKernelExprToReference treeType
                },
                {
                  name := referenceNodeName
                  type := psKernelExprToReference nodeType
                }
              ]
            }]
            isUnsafe := false
          }
  match portableNested, referenceNested with
  | Except.ok portable, Except.ok reference =>
      match
          psKernelEnvironmentFind
            portable
            treeName,
          reference.find?
            referenceTreeName with
      | Option.some
          (PsKernelConstantInfo.inductInfo portableTree),
        Option.some
          (PSC1Kernel.ConstantInfo.inductInfo referenceTree) =>
          if
              !(Nat.beq portableTree.numNested
                referenceTree.numNested) then
            false
          else
            match
                psKernelEnvironmentFind
                  portable
                  recName,
                reference.find?
                  referenceRecName with
            | Option.some
                (PsKernelConstantInfo.recInfo portableRec),
              Option.some
                (PSC1Kernel.ConstantInfo.recInfo referenceRec) =>
                if
                    !(Nat.beq
                      portableRec.numMotives
                      referenceRec.numMotives) then
                  false
                else if
                    !(Nat.beq
                      portableRec.numMinors
                      referenceRec.numMinors) then
                  false
                else
                  match
                      psKernelEnvironmentFind
                        portable
                        recAuxName,
                      reference.find?
                        referenceRecAuxName with
                  | Option.some
                      (PsKernelConstantInfo.recInfo portableAux),
                    Option.some
                      (PSC1Kernel.ConstantInfo.recInfo referenceAux) =>
                      if
                          !(Nat.beq
                            portableAux.numMotives
                            referenceAux.numMotives) then
                        false
                      else if
                          psKernelConstantListUsesNestedPrefix
                            portable.constants then
                        false
                      else
                        match portableAux.rules,
                            referenceAux.rules with
                        | List.cons portableRule List.nil,
                          List.cons referenceRule List.nil =>
                            psKernelNameEq
                              portableRule.ctor
                              (psKernelNameFromReference
                                referenceRule.ctor)
                        | _, _ =>
                            false
                  | _, _ =>
                      false
            | _, _ =>
                false
      | _, _ =>
          false
  | _, _ =>
      false

def psKernelDefEqSpecialRuleTests : Bool :=
  let type1 :=
    PsKernelExpr.sort
      (PsKernelLevel.succ PsKernelLevel.zero)
  let portableStringEnv :=
    psKernelEnvironmentAddUnchecked
      psKernelEnvironmentEmpty
      (PsKernelConstantInfo.axiomInfo {
        base := {
          name := psKernelStringName
          levelParams := List.nil
          type := type1
        }
        isUnsafe := false
      })
  let referenceStringEnv :=
    PSC1Kernel.Environment.empty.addUnchecked
      (PSC1Kernel.ConstantInfo.axiomInfo {
        base := {
          name := PSC1Kernel.kernelStringName
          levelParams := List.nil
          type :=
            PSC1Kernel.Expr.sort
              (PSC1Kernel.Level.succ
                PSC1Kernel.Level.zero)
        }
        isUnsafe := false
      })
  let literal :=
    PsKernelExpr.lit
      (PsKernelLiteral.str "Aλ")
  let expanded :=
    psKernelStringLitToConstructor "Aλ"
  let stringParity :=
    match
        psKernelIsDefEq
          4096
          (psKernelCheckerContextEmpty
            portableStringEnv)
          psKernelCheckerStateEmpty
          literal
          expanded,
        PSC1Kernel.isDefEq
          (PSC1Kernel.CheckerContext.empty
            referenceStringEnv)
          (psKernelExprToReference literal)
          (psKernelExprToReference expanded) with
    | Except.ok portableResult, Except.ok referenceResult =>
        Bool.and
          (Prod.fst portableResult)
          referenceResult
    | _, _ =>
        false
  let unitName :=
    PsKernelName.str
      PsKernelName.anonymous
      "ConformanceUnit"
  let unitCtorName :=
    PsKernelName.str
      unitName
      "mk"
  let unitType :=
    PsKernelExpr.const
      unitName
      List.nil
  let portableUnitEnv0 :=
    psKernelEnvironmentAddUnchecked
      psKernelEnvironmentEmpty
      (PsKernelConstantInfo.inductInfo {
        base := {
          name := unitName
          levelParams := List.nil
          type := type1
        }
        numParams := 0
        numIndices := 0
        all := List.cons unitName List.nil
        ctors := List.cons unitCtorName List.nil
        numNested := 0
        isRec := false
        isReflexive := false
        isUnsafe := false
      })
  let portableUnitEnv :=
    psKernelEnvironmentAddUnchecked
      portableUnitEnv0
      (PsKernelConstantInfo.ctorInfo {
        base := {
          name := unitCtorName
          levelParams := List.nil
          type := unitType
        }
        induct := unitName
        cidx := 0
        numParams := 0
        numFields := 0
        isUnsafe := false
      })
  let referenceUnitName :=
    psKernelNameToReference unitName
  let referenceUnitCtorName :=
    psKernelNameToReference unitCtorName
  let referenceUnitType :=
    PSC1Kernel.Expr.const
      referenceUnitName
      List.nil
  let referenceUnitEnv0 :=
    PSC1Kernel.Environment.empty.addUnchecked
      (PSC1Kernel.ConstantInfo.inductInfo {
        base := {
          name := referenceUnitName
          levelParams := List.nil
          type :=
            PSC1Kernel.Expr.sort
              (PSC1Kernel.Level.succ
                PSC1Kernel.Level.zero)
        }
        numParams := 0
        numIndices := 0
        all := List.cons referenceUnitName List.nil
        ctors := List.cons referenceUnitCtorName List.nil
        numNested := 0
        isRec := false
        isReflexive := false
        isUnsafe := false
      })
  let referenceUnitEnv :=
    referenceUnitEnv0.addUnchecked
      (PSC1Kernel.ConstantInfo.ctorInfo {
        base := {
          name := referenceUnitCtorName
          levelParams := List.nil
          type := referenceUnitType
        }
        induct := referenceUnitName
        cidx := 0
        numParams := 0
        numFields := 0
        isUnsafe := false
      })
  let leftName :=
    PsKernelName.str
      PsKernelName.anonymous
      "unitLeft"
  let rightName :=
    PsKernelName.str
      PsKernelName.anonymous
      "unitRight"
  let portableLeft :=
    psKernelCheckerContextWithLocal
      (psKernelCheckerContextEmpty
        portableUnitEnv)
      leftName
      unitType
      PsKernelBinderInfo.default
  let portableRight :=
    psKernelCheckerContextWithLocal
      (Prod.snd portableLeft)
      rightName
      unitType
      PsKernelBinderInfo.default
  let referenceLeft :=
    (PSC1Kernel.CheckerContext.empty
      referenceUnitEnv).withLocal
      (psKernelNameToReference leftName)
      referenceUnitType
      PSC1Kernel.BinderInfo.default
  let referenceRight :=
    PSC1Kernel.CheckerContext.withLocal
      (Prod.snd referenceLeft)
      (psKernelNameToReference rightName)
      referenceUnitType
      PSC1Kernel.BinderInfo.default
  let unitParity :=
    match
        psKernelIsDefEq
          4096
          (Prod.snd portableRight)
          psKernelCheckerStateEmpty
          (PsKernelExpr.fvar
            (Prod.fst portableLeft))
          (PsKernelExpr.fvar
            (Prod.fst portableRight)),
        PSC1Kernel.isDefEq
          (Prod.snd referenceRight)
          (PSC1Kernel.Expr.fvar
            (Prod.fst referenceLeft))
          (PSC1Kernel.Expr.fvar
            (Prod.fst referenceRight)) with
    | Except.ok portableResult, Except.ok referenceResult =>
        Bool.and
          (Prod.fst portableResult)
          referenceResult
    | _, _ =>
        false
  Bool.and stringParity unitParity

def psKernelPortableQuotBaseEnvironment :
    PsKernelEnvironment :=
  let universeName :=
    PsKernelName.str
      PsKernelName.anonymous
      "quotConformanceU"
  let reflName :=
    PsKernelName.str
      psKernelEqName
      "refl"
  let env0 :=
    psKernelEnvironmentAddUnchecked
      psKernelEnvironmentEmpty
      (PsKernelConstantInfo.inductInfo {
        base := {
          name := psKernelEqName
          levelParams :=
            List.cons universeName List.nil
          type :=
            psKernelExpectedEqType
              universeName
        }
        numParams := 2
        numIndices := 1
        all :=
          List.cons psKernelEqName List.nil
        ctors :=
          List.cons reflName List.nil
        numNested := 0
        isRec := false
        isReflexive := true
        isUnsafe := false
      })
  psKernelEnvironmentAddUnchecked
    env0
    (PsKernelConstantInfo.ctorInfo {
      base := {
        name := reflName
        levelParams :=
          List.cons universeName List.nil
        type :=
          psKernelExpectedEqReflType
            universeName
      }
      induct := psKernelEqName
      cidx := 0
      numParams := 2
      numFields := 0
      isUnsafe := false
    })

def psKernelReferenceQuotBaseEnvironment :
    PSC1Kernel.Environment :=
  let universeName :=
    PSC1Kernel.Name.str
      PSC1Kernel.Name.anonymous
      "quotConformanceU"
  let reflName :=
    PSC1Kernel.Name.str
      PSC1Kernel.Kernel.kernelEqName
      "refl"
  let env0 :=
    PSC1Kernel.Environment.empty.addUnchecked
      (PSC1Kernel.ConstantInfo.inductInfo {
        base := {
          name := PSC1Kernel.Kernel.kernelEqName
          levelParams :=
            List.cons universeName List.nil
          type :=
            PSC1Kernel.Kernel.expectedEqType
              universeName
        }
        numParams := 2
        numIndices := 1
        all :=
          List.cons
            PSC1Kernel.Kernel.kernelEqName
            List.nil
        ctors :=
          List.cons reflName List.nil
        numNested := 0
        isRec := false
        isReflexive := true
        isUnsafe := false
      })
  env0.addUnchecked
    (PSC1Kernel.ConstantInfo.ctorInfo {
      base := {
        name := reflName
        levelParams :=
          List.cons universeName List.nil
        type :=
          PSC1Kernel.Kernel.expectedEqReflType
            universeName
      }
      induct := PSC1Kernel.Kernel.kernelEqName
      cidx := 0
      numParams := 2
      numFields := 0
      isUnsafe := false
    })

def psKernelQuotPrimitiveTypesMatch
    (portable : PsKernelEnvironment)
    (reference : PSC1Kernel.Environment)
    (names : List PsKernelName) :
    Bool :=
  match names with
  | List.nil =>
      true
  | List.cons name rest =>
      match
          psKernelEnvironmentFind
            portable
            name,
          reference.find?
            (psKernelNameToReference name) with
      | Option.some portableInfo,
        Option.some referenceInfo =>
          if
              psKernelExprReferenceEq
                (psKernelConstantInfoType
                  portableInfo)
                referenceInfo.type then
            psKernelQuotPrimitiveTypesMatch
              portable
              reference
              rest
          else
            false
      | _, _ =>
          false

def psKernelSelfHostQuotTests : Bool :=
  match
      psKernelAddQuot
        psKernelPortableQuotBaseEnvironment,
      PSC1Kernel.Kernel.addQuot
        psKernelReferenceQuotBaseEnvironment with
  | Except.ok portableEnv,
    Except.ok referenceEnv =>
      let names :=
        List.cons
          psKernelQuotName
          (List.cons
            psKernelQuotMkName
            (List.cons
              psKernelQuotLiftName
              (List.cons
                psKernelQuotIndName
                List.nil)))
      let admissionParity :=
        Bool.and
          portableEnv.quotInitialized
          (Bool.and
            referenceEnv.quotInitialized
            (psKernelQuotPrimitiveTypesMatch
              portableEnv
              referenceEnv
              names))
      let x :=
        PsKernelName.str
          PsKernelName.anonymous
          "quot_x"
      let dummy :=
        PsKernelExpr.sort
          PsKernelLevel.zero
      let representative :=
        PsKernelExpr.lit
          (PsKernelLiteral.nat 37)
      let fn :=
        PsKernelExpr.lam
          x
          dummy
          (PsKernelExpr.bvar 0)
          PsKernelBinderInfo.default
      let quotMk :=
        psKernelApplyArgs
          (PsKernelExpr.const
            psKernelQuotMkName
            List.nil)
          (List.cons
            dummy
            (List.cons
              dummy
              (List.cons
                representative
                List.nil)))
      let liftArgs5 :=
        List.cons quotMk List.nil
      let liftArgs4 :=
        List.cons dummy liftArgs5
      let liftArgs3 :=
        List.cons fn liftArgs4
      let liftArgs2 :=
        List.cons dummy liftArgs3
      let liftArgs1 :=
        List.cons dummy liftArgs2
      let liftArgs :=
        List.cons dummy liftArgs1
      let liftExpr :=
        psKernelApplyArgs
          (PsKernelExpr.const
            psKernelQuotLiftName
            List.nil)
          liftArgs
      let indArgs4 :=
        List.cons quotMk List.nil
      let indArgs3 :=
        List.cons fn indArgs4
      let indArgs2 :=
        List.cons dummy indArgs3
      let indArgs1 :=
        List.cons dummy indArgs2
      let indArgs :=
        List.cons dummy indArgs1
      let indExpr :=
        psKernelApplyArgs
          (PsKernelExpr.const
            psKernelQuotIndName
            List.nil)
          indArgs
      let portableSession :=
        psKernelMkCheckerSession
          portableEnv
          List.nil
          PsKernelDefinitionSafety.safe
          0
          psKernelLeanNatMaxSizeDefault
      let referenceContext :=
        PSC1Kernel.CheckerContext.empty
          referenceEnv
      let liftParity :=
        match
            psKernelSessionWhnf
              4096
              portableSession
              liftExpr,
            PSC1Kernel.whnf
              referenceContext
              (psKernelExprToReference
                liftExpr) with
        | Except.ok portableResult,
          Except.ok referenceResult =>
            Bool.and
              (psKernelExprEq
                (Prod.fst portableResult)
                representative)
              (psKernelExprReferenceEq
                (Prod.fst portableResult)
                referenceResult)
        | _, _ =>
            false
      let indParity :=
        match
            psKernelSessionWhnf
              4096
              portableSession
              indExpr,
            PSC1Kernel.whnf
              referenceContext
              (psKernelExprToReference
                indExpr) with
        | Except.ok portableResult,
          Except.ok referenceResult =>
            Bool.and
              (psKernelExprEq
                (Prod.fst portableResult)
                representative)
              (psKernelExprReferenceEq
                (Prod.fst portableResult)
                referenceResult)
        | _, _ =>
            false
      Bool.and
        admissionParity
        (Bool.and liftParity indParity)
  | _, _ =>
      false

def psKernelAdmissionConformanceTests : Bool :=
  let fuel := 4096
  let maxNatSize := psKernelLeanNatMaxSizeDefault
  let natBase : PsKernelConstantBase := {
    name := psKernelNatName
    levelParams := List.nil
    type :=
      PsKernelExpr.sort
        (PsKernelLevel.succ PsKernelLevel.zero)
  }
  let referenceNatBase : PSC1Kernel.ConstantBase := {
    name := PSC1Kernel.kernelNatName
    levelParams := List.nil
    type :=
      PSC1Kernel.Expr.sort
        (PSC1Kernel.Level.succ PSC1Kernel.Level.zero)
  }
  match
      psKernelAddAxiom
        fuel
        psKernelEnvironmentEmpty
        {
          base := natBase
          isUnsafe := false
        }
        0
        maxNatSize,
      PSC1Kernel.Kernel.addAxiom
        PSC1Kernel.Environment.empty
        {
          base := referenceNatBase
          isUnsafe := false
        }
        0
        PSC1Kernel.leanNatMaxSizeDefault
        Option.none with
  | Except.ok portableNatEnv, Except.ok referenceNatEnv =>
      let duplicatePortable :=
        psKernelAddAxiom
          fuel
          portableNatEnv
          {
            base := natBase
            isUnsafe := false
          }
          0
          maxNatSize
      let duplicateReference :=
        PSC1Kernel.Kernel.addAxiom
          referenceNatEnv
          {
            base := referenceNatBase
            isUnsafe := false
          }
          0
          PSC1Kernel.leanNatMaxSizeDefault
          Option.none
      let duplicateParity :=
        match duplicatePortable, duplicateReference with
        | Except.error _, Except.error _ => true
        | _, _ => false
      let defName :=
        PsKernelName.str
          PsKernelName.anonymous
          "AdmissionDef"
      let referenceDefName :=
        psKernelNameToReference defName
      let defInfo : PsKernelDefinitionInfo := {
        base := {
          name := defName
          levelParams := List.nil
          type :=
            PsKernelExpr.const
              psKernelNatName
              List.nil
        }
        value :=
          PsKernelExpr.lit
            (PsKernelLiteral.nat 3)
        hints := PsKernelReducibilityHints.regular 0
        safety := PsKernelDefinitionSafety.safe
      }
      let referenceDefInfo : PSC1Kernel.DefinitionInfo := {
        base := {
          name := referenceDefName
          levelParams := List.nil
          type :=
            PSC1Kernel.Expr.const
              PSC1Kernel.kernelNatName
              List.nil
        }
        value :=
          PSC1Kernel.Expr.lit
            (PSC1Kernel.Literal.nat 3)
        hints := PSC1Kernel.ReducibilityHints.regular 0
        safety := PSC1Kernel.DefinitionSafety.safe
      }
      match
          psKernelAddDefinition
            fuel
            portableNatEnv
            defInfo
            0
            maxNatSize,
          PSC1Kernel.Kernel.addDefinition
            referenceNatEnv
            referenceDefInfo
            0
            PSC1Kernel.leanNatMaxSizeDefault
            Option.none with
      | Except.ok portableDefEnv, Except.ok referenceDefEnv =>
          let propName :=
            PsKernelName.str
              PsKernelName.anonymous
              "AdmissionProp"
          let proofName :=
            PsKernelName.str
              PsKernelName.anonymous
              "AdmissionProof"
          let theoremName :=
            PsKernelName.str
              PsKernelName.anonymous
              "AdmissionTheorem"
          let referencePropName :=
            psKernelNameToReference propName
          let referenceProofName :=
            psKernelNameToReference proofName
          let referenceTheoremName :=
            psKernelNameToReference theoremName
          let propBase : PsKernelConstantBase := {
            name := propName
            levelParams := List.nil
            type := PsKernelExpr.sort PsKernelLevel.zero
          }
          let referencePropBase : PSC1Kernel.ConstantBase := {
            name := referencePropName
            levelParams := List.nil
            type := PSC1Kernel.Expr.sort PSC1Kernel.Level.zero
          }
          match
              psKernelAddAxiom
                fuel
                portableDefEnv
                {
                  base := propBase
                  isUnsafe := false
                }
                0
                maxNatSize,
              PSC1Kernel.Kernel.addAxiom
                referenceDefEnv
                {
                  base := referencePropBase
                  isUnsafe := false
                }
                0
                PSC1Kernel.leanNatMaxSizeDefault
                Option.none with
          | Except.ok portablePropEnv, Except.ok referencePropEnv =>
              let proofBase : PsKernelConstantBase := {
                name := proofName
                levelParams := List.nil
                type :=
                  PsKernelExpr.const
                    propName
                    List.nil
              }
              let referenceProofBase : PSC1Kernel.ConstantBase := {
                name := referenceProofName
                levelParams := List.nil
                type :=
                  PSC1Kernel.Expr.const
                    referencePropName
                    List.nil
              }
              match
                  psKernelAddAxiom
                    fuel
                    portablePropEnv
                    {
                      base := proofBase
                      isUnsafe := false
                    }
                    0
                    maxNatSize,
                  PSC1Kernel.Kernel.addAxiom
                    referencePropEnv
                    {
                      base := referenceProofBase
                      isUnsafe := false
                    }
                    0
                    PSC1Kernel.leanNatMaxSizeDefault
                    Option.none with
              | Except.ok portableProofEnv, Except.ok referenceProofEnv =>
                  let theoremInfo : PsKernelTheoremInfo := {
                    base := {
                      name := theoremName
                      levelParams := List.nil
                      type :=
                        PsKernelExpr.const
                          propName
                          List.nil
                    }
                    value :=
                      PsKernelExpr.const
                        proofName
                        List.nil
                  }
                  let referenceTheoremInfo : PSC1Kernel.TheoremInfo := {
                    base := {
                      name := referenceTheoremName
                      levelParams := List.nil
                      type :=
                        PSC1Kernel.Expr.const
                          referencePropName
                          List.nil
                    }
                    value :=
                      PSC1Kernel.Expr.const
                        referenceProofName
                        List.nil
                  }
                  match
                      psKernelAddTheorem
                        fuel
                        portableProofEnv
                        theoremInfo
                        0
                        maxNatSize,
                      PSC1Kernel.Kernel.addTheorem
                        referenceProofEnv
                        referenceTheoremInfo
                        0
                        PSC1Kernel.leanNatMaxSizeDefault
                        Option.none with
                  | Except.ok portableTheoremEnv, Except.ok referenceTheoremEnv =>
                      let opaqueName :=
                        PsKernelName.str
                          PsKernelName.anonymous
                          "AdmissionOpaque"
                      let referenceOpaqueName :=
                        psKernelNameToReference opaqueName
                      let opaqueInfo : PsKernelOpaqueInfo := {
                        base := {
                          name := opaqueName
                          levelParams := List.nil
                          type :=
                            PsKernelExpr.const
                              psKernelNatName
                              List.nil
                        }
                        value :=
                          PsKernelExpr.lit
                            (PsKernelLiteral.nat 5)
                        isUnsafe := false
                      }
                      let referenceOpaqueInfo : PSC1Kernel.OpaqueInfo := {
                        base := {
                          name := referenceOpaqueName
                          levelParams := List.nil
                          type :=
                            PSC1Kernel.Expr.const
                              PSC1Kernel.kernelNatName
                              List.nil
                        }
                        value :=
                          PSC1Kernel.Expr.lit
                            (PSC1Kernel.Literal.nat 5)
                        isUnsafe := false
                      }
                      match
                          psKernelAddOpaque
                            fuel
                            portableTheoremEnv
                            opaqueInfo
                            0
                            maxNatSize,
                          PSC1Kernel.Kernel.addOpaque
                            referenceTheoremEnv
                            referenceOpaqueInfo
                            0
                            PSC1Kernel.leanNatMaxSizeDefault
                            Option.none with
                      | Except.ok portableOpaqueEnv, Except.ok referenceOpaqueEnv =>
                          let firstMutualName :=
                            PsKernelName.str
                              PsKernelName.anonymous
                              "AdmissionMutualA"
                          let secondMutualName :=
                            PsKernelName.str
                              PsKernelName.anonymous
                              "AdmissionMutualB"
                          let referenceFirstMutualName :=
                            psKernelNameToReference firstMutualName
                          let referenceSecondMutualName :=
                            psKernelNameToReference secondMutualName
                          let firstMutual : PsKernelDefinitionInfo := {
                            base := {
                              name := firstMutualName
                              levelParams := List.nil
                              type :=
                                PsKernelExpr.const
                                  psKernelNatName
                                  List.nil
                            }
                            value :=
                              PsKernelExpr.lit
                                (PsKernelLiteral.nat 1)
                            hints := PsKernelReducibilityHints.regular 0
                            safety := PsKernelDefinitionSafety.unsafeDef
                          }
                          let secondMutual : PsKernelDefinitionInfo := {
                            base := {
                              name := secondMutualName
                              levelParams := List.nil
                              type :=
                                PsKernelExpr.const
                                  psKernelNatName
                                  List.nil
                            }
                            value :=
                              PsKernelExpr.lit
                                (PsKernelLiteral.nat 2)
                            hints := PsKernelReducibilityHints.regular 0
                            safety := PsKernelDefinitionSafety.unsafeDef
                          }
                          let referenceFirstMutual : PSC1Kernel.DefinitionInfo := {
                            base := {
                              name := referenceFirstMutualName
                              levelParams := List.nil
                              type :=
                                PSC1Kernel.Expr.const
                                  PSC1Kernel.kernelNatName
                                  List.nil
                            }
                            value :=
                              PSC1Kernel.Expr.lit
                                (PSC1Kernel.Literal.nat 1)
                            hints := PSC1Kernel.ReducibilityHints.regular 0
                            safety := PSC1Kernel.DefinitionSafety.unsafeDef
                          }
                          let referenceSecondMutual : PSC1Kernel.DefinitionInfo := {
                            base := {
                              name := referenceSecondMutualName
                              levelParams := List.nil
                              type :=
                                PSC1Kernel.Expr.const
                                  PSC1Kernel.kernelNatName
                                  List.nil
                            }
                            value :=
                              PSC1Kernel.Expr.lit
                                (PSC1Kernel.Literal.nat 2)
                            hints := PSC1Kernel.ReducibilityHints.regular 0
                            safety := PSC1Kernel.DefinitionSafety.unsafeDef
                          }
                          match
                              psKernelAddMutualDefinitions
                                fuel
                                portableOpaqueEnv
                                (List.cons
                                  firstMutual
                                  (List.cons secondMutual List.nil))
                                0
                                maxNatSize,
                              PSC1Kernel.Kernel.addMutualDefinitions
                                referenceOpaqueEnv
                                (List.cons
                                  referenceFirstMutual
                                  (List.cons referenceSecondMutual List.nil))
                                0
                                PSC1Kernel.leanNatMaxSizeDefault
                                Option.none with
                          | Except.ok portableFinal, Except.ok referenceFinal =>
                              duplicateParity &&
                                psKernelEnvironmentContains
                                  portableFinal
                                  defName &&
                                referenceFinal.contains
                                  referenceDefName &&
                                psKernelEnvironmentContains
                                  portableFinal
                                  theoremName &&
                                referenceFinal.contains
                                  referenceTheoremName &&
                                psKernelEnvironmentContains
                                  portableFinal
                                  opaqueName &&
                                referenceFinal.contains
                                  referenceOpaqueName &&
                                psKernelEnvironmentContains
                                  portableFinal
                                  firstMutualName &&
                                psKernelEnvironmentContains
                                  portableFinal
                                  secondMutualName &&
                                referenceFinal.contains
                                  referenceFirstMutualName &&
                                referenceFinal.contains
                                  referenceSecondMutualName
                          | _, _ =>
                              false
                      | _, _ =>
                          false
                  | _, _ =>
                      false
              | _, _ =>
                  false
          | _, _ =>
              false
      | _, _ =>
          false
  | _, _ =>
      false

def psKernelRuntimeCacheKey
    (index : Nat) :
    PsKernelExpr :=
  PsKernelExpr.const
    (PsKernelName.num
      (PsKernelName.str
        PsKernelName.anonymous
        "runtimeCache")
      index)
    List.nil

def psKernelRuntimeCacheValue
    (index : Nat) :
    PsKernelExpr :=
  PsKernelExpr.lit
    (PsKernelLiteral.nat index)

def psKernelRuntimeBuildExprMap
    (count : Nat) :
    PsKernelExprMap :=
  match count with
  | Nat.zero =>
      psKernelExprMapEmpty
  | Nat.succ rest =>
      psKernelExprMapInsert
        (psKernelRuntimeBuildExprMap rest)
        (psKernelRuntimeCacheKey rest)
        (psKernelRuntimeCacheValue rest)

def psKernelRuntimeBuildPairSet
    (count : Nat) :
    PsKernelExprPairSet :=
  match count with
  | Nat.zero =>
      psKernelExprPairSetEmpty
  | Nat.succ rest =>
      psKernelExprPairSetInsert
        (psKernelRuntimeBuildPairSet rest)
        (psKernelRuntimeCacheKey rest)
        (psKernelRuntimeCacheValue rest)

def psKernelRuntimeCachePromotionTests : Bool :=
  let map8 :=
    psKernelRuntimeBuildExprMap 8
  let map9 :=
    psKernelRuntimeBuildExprMap 9
  let pair8 :=
    psKernelRuntimeBuildPairSet 8
  let pair9 :=
    psKernelRuntimeBuildPairSet 9
  let map8Small :=
    match map8.index with
    | Option.none => true
    | Option.some _ => false
  let map9Indexed :=
    match map9.index with
    | Option.none => false
    | Option.some _ => true
  let pair8Small :=
    match pair8.index with
    | Option.none => true
    | Option.some _ => false
  let pair9Indexed :=
    match pair9.index with
    | Option.none => false
    | Option.some _ => true
  Bool.and
    map8Small
    (Bool.and
      map9Indexed
      (Bool.and
        pair8Small
        (Bool.and
          pair9Indexed
          (Bool.and
            (match
                psKernelExprMapGet
                  map9
                  (psKernelRuntimeCacheKey 0) with
            | Option.some value =>
                psKernelExprEq
                  value
                  (psKernelRuntimeCacheValue 0)
            | Option.none =>
                false)
            (psKernelExprPairSetContains
              pair9
              (psKernelRuntimeCacheValue 0)
              (psKernelRuntimeCacheKey 0))))))

def psKernelRuntimeCacheInvariantTests : Bool :=
  let nameA :=
    PsKernelName.str
      PsKernelName.anonymous
      "cacheA"
  let nameB :=
    PsKernelName.str
      PsKernelName.anonymous
      "cacheB"
  let type :=
    PsKernelExpr.sort PsKernelLevel.zero
  let body :=
    PsKernelExpr.bvar 0
  let left :=
    PsKernelExpr.lam
      nameA
      type
      body
      PsKernelBinderInfo.default
  let equalByCacheSemantics :=
    PsKernelExpr.lam
      nameB
      type
      body
      PsKernelBinderInfo.implicit
  let value :=
    PsKernelExpr.lit
      (PsKernelLiteral.nat 99)
  let cache :=
    psKernelExprMapInsert
      psKernelExprMapEmpty
      left
      value
  let pairSet :=
    psKernelExprPairSetInsert
      psKernelExprPairSetEmpty
      left
      value
  Bool.and
    (psKernelExprEq
      left
      equalByCacheSemantics)
    (Bool.and
      (Nat.beq
        (psKernelExprHash left)
        (psKernelExprHash equalByCacheSemantics))
      (Bool.and
        (match
            psKernelExprMapGet
              cache
              equalByCacheSemantics with
        | Option.some cached =>
            psKernelExprEq cached value
        | Option.none =>
            false)
        (Bool.and
          (Nat.beq
            (psKernelExprPairHash left value)
            (psKernelExprPairHash value left))
          (psKernelExprPairSetContains
            pairSet
            value
            equalByCacheSemantics))))

def psKernelRuntimeEnvironmentInfo
    (index : Nat) :
    PsKernelConstantInfo :=
  PsKernelConstantInfo.axiomInfo {
    base := {
      name :=
        PsKernelName.num
          PsKernelName.anonymous
          index
      levelParams := List.nil
      type := PsKernelExpr.sort PsKernelLevel.zero
    }
    isUnsafe := false
  }

def psKernelRuntimeBuildEnvironment
    (count : Nat) :
    PsKernelEnvironment :=
  match count with
  | Nat.zero =>
      psKernelEnvironmentEmpty
  | Nat.succ rest =>
      psKernelEnvironmentAddUnchecked
        (psKernelRuntimeBuildEnvironment rest)
        (psKernelRuntimeEnvironmentInfo rest)

def psKernelRuntimeEnvironmentPromotionTests : Bool :=
  let environment8 :=
    psKernelRuntimeBuildEnvironment 8
  let environment9 :=
    psKernelRuntimeBuildEnvironment 9
  let environment8Small :=
    match environment8.index with
    | PsKernelEnvironmentIndex.small _ =>
        true
    | _ =>
        false
  let environment9Indexed :=
    match environment9.index with
    | PsKernelEnvironmentIndex.branch _ _ =>
        true
    | PsKernelEnvironmentIndex.bucket _ =>
        true
    | _ =>
        false
  let target :=
    PsKernelName.num
      PsKernelName.anonymous
      0
  Bool.and
    environment8Small
    (Bool.and
      environment9Indexed
      (match
          psKernelEnvironmentFind
            environment9
            target,
          psKernelFindConstantInList
            target
            environment9.constants with
      | Option.some indexed,
        Option.some authoritative =>
          psKernelExprEq
            (psKernelConstantInfoType indexed)
            (psKernelConstantInfoType authoritative)
      | _, _ =>
          false))

def psKernelRuntimeEnvironmentIndexInvariantTests : Bool :=
  let firstName :=
    PsKernelName.num
      PsKernelName.anonymous
      1
  let collisionName :=
    PsKernelName.num
      PsKernelName.anonymous
      65522
  let firstType :=
    PsKernelExpr.sort PsKernelLevel.zero
  let collisionType :=
    PsKernelExpr.sort
      (PsKernelLevel.succ PsKernelLevel.zero)
  let replacementType :=
    PsKernelExpr.sort
      (PsKernelLevel.succ
        (PsKernelLevel.succ PsKernelLevel.zero))
  let firstInfo :=
    PsKernelConstantInfo.axiomInfo {
      base := {
        name := firstName
        levelParams := List.nil
        type := firstType
      }
      isUnsafe := false
    }
  let collisionInfo :=
    PsKernelConstantInfo.axiomInfo {
      base := {
        name := collisionName
        levelParams := List.nil
        type := collisionType
      }
      isUnsafe := false
    }
  let replacement :=
    PsKernelConstantInfo.axiomInfo {
      base := {
        name := firstName
        levelParams := List.nil
        type := replacementType
      }
      isUnsafe := false
    }
  let environment0 :=
    psKernelEnvironmentAddUnchecked
      psKernelEnvironmentEmpty
      firstInfo
  let environment1 :=
    psKernelEnvironmentAddUnchecked
      environment0
      collisionInfo
  let environment2 :=
    psKernelEnvironmentReplaceUnchecked
      environment1
      replacement
  Bool.and
    (Nat.beq
      (psKernelEnvironmentNameHash firstName)
      (psKernelEnvironmentNameHash collisionName))
    (Bool.and
      (match
          psKernelEnvironmentFind
            environment1
            firstName,
          psKernelFindConstantInList
            firstName
            environment1.constants with
      | Option.some indexed,
        Option.some authoritative =>
          psKernelExprEq
            (psKernelConstantInfoType indexed)
            (psKernelConstantInfoType authoritative)
      | _, _ =>
          false)
      (Bool.and
        (match
            psKernelEnvironmentFind
              environment1
              collisionName,
            psKernelFindConstantInList
              collisionName
              environment1.constants with
        | Option.some indexed,
          Option.some authoritative =>
            psKernelExprEq
              (psKernelConstantInfoType indexed)
              (psKernelConstantInfoType authoritative)
        | _, _ =>
            false)
        (match
            psKernelEnvironmentFind
              environment2
              firstName with
        | Option.some indexed =>
            psKernelExprEq
              (psKernelConstantInfoType indexed)
              replacementType
        | Option.none =>
            false)))

def psKernelRuntimeInvariantTests : Bool :=
  Bool.and
    psKernelRuntimeCacheInvariantTests
    (Bool.and
      psKernelRuntimeCachePromotionTests
      (Bool.and
        psKernelRuntimeEnvironmentPromotionTests
        psKernelRuntimeEnvironmentIndexInvariantTests))

def main : IO Unit :=
  if !psKernelSelfHostNameTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_NAME_DIFFERENTIAL: FAIL")
  else if !psKernelSelfHostLevelTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_LEVEL_DIFFERENTIAL: FAIL")
  else if !psKernelSelfHostExprTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_EXPR_DIFFERENTIAL: FAIL")
  else if !psKernelSelfHostInstantiateTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_INSTANTIATE_DIFFERENTIAL: FAIL")
  else if !psKernelSelfHostPrimitiveTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_PRIMITIVE_DIFFERENTIAL: FAIL")
  else if !psKernelDefEqSpecialRuleTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_DEFEQ_SPECIAL_CONFORMANCE: FAIL")
  else if !psKernelSelfHostQuotTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_QUOT_CONFORMANCE: FAIL")
  else if !psKernelAdmissionConformanceTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_ADMISSION_CONFORMANCE: FAIL")
  else if !psKernelRuntimeInvariantTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_RUNTIME_INVARIANT: FAIL")
  else if !psKernelSelfHostWhnfTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_WHNF_DIFFERENTIAL: FAIL")
  else if !psKernelSelfHostInferTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_INFER_DIFFERENTIAL: FAIL")
  else if !psKernelSelfHostProjectionTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_PROJECTION_DIFFERENTIAL: FAIL")
  else if !psKernelSelfHostRecursorTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_RECURSOR_DIFFERENTIAL: FAIL")
  else if !psKernelSelfHostDefEqTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_DEFEQ_DIFFERENTIAL: FAIL")
  else if !psKernelSelfHostNestedTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_NESTED_DIFFERENTIAL: FAIL")
  else
    IO.println
      "PSC1_KERNEL_SELFHOST_FOUNDATION_DIFFERENTIAL: PASS"

