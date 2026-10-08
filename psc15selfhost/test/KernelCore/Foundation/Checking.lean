import KernelCore.Foundation.Core

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

def psKernelCorePrimitiveNatTests : Bool :=
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

def psKernelCorePrimitiveBoundaryTests : Bool :=
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

def psKernelCorePrimitiveStringTests : Bool :=
  PSC1Kernel.Expr.eq
    (psKernelExprToReference
      (psKernelStringLitToConstructor "Aλ"))
    (PSC1Kernel.stringLitToConstructor "Aλ")

def psKernelCorePrimitiveTests : Bool :=
  Bool.and
    psKernelCorePrimitiveNatTests
    (Bool.and
      psKernelCorePrimitiveBoundaryTests
      psKernelCorePrimitiveStringTests)

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

def psKernelCoreWhnfTests : Bool :=
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

def psKernelCoreInferTests : Bool :=
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

def psKernelCoreProjectionTests : Bool :=
  Bool.and
    (psKernelProjectionDifferential 0)
    (psKernelProjectionDifferential 1)

def psKernelCoreRecursorTests : Bool :=
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
         -- Semantic caches must exclude fvar-bearing keys.
         | Option.some _ => false
         | Option.none => true)
  | _, _ =>
      false

