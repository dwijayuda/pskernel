import Ps.KernelSelfHost.TypeCheckerInfer
import PSC1Kernel.TypeChecker

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
            PsKernelExpr
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
              psKernelWhnfCacheTest
              psKernelWhnfFuelExhaustionTest)))))

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
  else if !psKernelSelfHostWhnfTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_WHNF_DIFFERENTIAL: FAIL")
  else if !psKernelSelfHostInferTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_INFER_DIFFERENTIAL: FAIL")
  else
    IO.println
      "PSC1_KERNEL_SELFHOST_FOUNDATION_DIFFERENTIAL: PASS"

