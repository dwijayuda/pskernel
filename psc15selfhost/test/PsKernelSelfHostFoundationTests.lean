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

