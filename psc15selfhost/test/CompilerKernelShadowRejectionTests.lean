import Ps.Compiler.Api


def psPhase13ShadowRootName (value : String) : PsName :=
  PsName.str PsName.anonymous value


def psPhase13ShadowNatType : PsExpr :=
  PsExpr.constE (psPhase13ShadowRootName "Nat") []


def psPhase13ShadowSimpleType : PsExpr :=
  PsExpr.sortE (PsLevel.succ PsLevel.zero)


def psPhase13ShadowIsUnsupported
    (declaration : PsDeclaration) : Bool :=
  match psCompilerKernelShadowCheckDeclarations [declaration] with
  | Except.error PsCompilerKernelShadowError.unsupportedDeclaration => true
  | _ => false


def psPhase13ShadowPreparedIntegrityPass : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        "def answer : Nat := 42" with
  | Except.error _ => false
  | Except.ok prepared =>
      let forged : PsCompilerAdmissionReadyModule :=
        { prepared with canonicalAdmissions := "forged" };
      match psCompilerKernelShadowCheckPrepared forged with
      | Except.error
          (PsCompilerKernelShadowApiError.compiler
            PsCompilerError.preparedAdmissionMismatch) => true
      | _ => false


def psPhase13ShadowFreeVariablePass : Bool :=
  let declaration :=
    PsDeclaration.definitionDecl
      (psPhase13ShadowRootName "badFree")
      []
      psPhase13ShadowNatType
      (PsExpr.fvar 0);
  match psCompilerKernelShadowCheckDeclarations [declaration] with
  | Except.error PsCompilerKernelShadowError.freeVariable => true
  | _ => false


def psPhase13ShadowExpressionMetavariablePass : Bool :=
  let declaration :=
    PsDeclaration.definitionDecl
      (psPhase13ShadowRootName "badMeta")
      []
      psPhase13ShadowNatType
      (PsExpr.mvar 0);
  match psCompilerKernelShadowCheckDeclarations [declaration] with
  | Except.error PsCompilerKernelShadowError.expressionMetavariable => true
  | _ => false


def psPhase13ShadowUniverseMetavariablePass : Bool :=
  let declaration :=
    PsDeclaration.definitionDecl
      (psPhase13ShadowRootName "badUniverse")
      []
      (PsExpr.sortE (PsLevel.mvar 0))
      (PsExpr.sortE PsLevel.zero);
  match psCompilerKernelShadowCheckDeclarations [declaration] with
  | Except.error PsCompilerKernelShadowError.universeMetavariable => true
  | _ => false


def psPhase13ShadowDuplicateAssumptionPass : Bool :=
  let name := psPhase13ShadowRootName "Duplicate";
  let first := PsDeclaration.axiomDecl name [] psPhase13ShadowSimpleType;
  let second := PsDeclaration.axiomDecl name [] psPhase13ShadowSimpleType;
  match psCompilerKernelShadowAssumptionEnvironment [first, second] with
  | Except.error PsCompilerKernelShadowError.duplicatePreludeAssumption => true
  | _ => false


def psPhase13ShadowUnsupportedAxiomPass : Bool :=
  psPhase13ShadowIsUnsupported
    (PsDeclaration.axiomDecl
      (psPhase13ShadowRootName "shadowAxiom")
      []
      psPhase13ShadowSimpleType)


def psPhase13ShadowUnsupportedPartialPass : Bool :=
  psPhase13ShadowIsUnsupported
    (PsDeclaration.partialDecl
      (psPhase13ShadowRootName "shadowPartial")
      []
      psPhase13ShadowNatType
      (PsExpr.lit (PsLiteral.natural 0)))


def psPhase13ShadowUnsupportedOpaquePass : Bool :=
  psPhase13ShadowIsUnsupported
    (PsDeclaration.opaqueDecl
      (psPhase13ShadowRootName "shadowOpaque")
      []
      psPhase13ShadowNatType
      (PsExpr.lit (PsLiteral.natural 0)))


def psPhase13ShadowUnsupportedInductivePass : Bool :=
  let name := psPhase13ShadowRootName "ShadowInd";
  let info : PsInductiveInfo := {
    name := name
    levelParams := []
    type := psPhase13ShadowSimpleType
    numParams := 0
    numIndices := 0
    constructors := []
    isStructure := false
  };
  psPhase13ShadowIsUnsupported (PsDeclaration.inductiveDecl info)


def psPhase13ShadowUnsupportedConstructorPass : Bool :=
  let inductiveName := psPhase13ShadowRootName "ShadowInd";
  let info : PsConstructorInfo := {
    name := psPhase13ShadowRootName "ShadowInd.mk"
    levelParams := []
    type := PsExpr.constE inductiveName []
    inductiveName := inductiveName
    constructorIndex := 0
    numParams := 0
    numFields := 0
    recursiveFields := []
  };
  psPhase13ShadowIsUnsupported (PsDeclaration.constructorDecl info)


def psPhase13ShadowUnsupportedRecursorPass : Bool :=
  let inductiveName := psPhase13ShadowRootName "ShadowInd";
  let info : PsRecursorInfo := {
    name := psPhase13ShadowRootName "ShadowInd.rec"
    levelParams := []
    type := psPhase13ShadowNatType
    inductiveNames := [inductiveName]
    numParams := 0
    numIndices := 0
    numMotives := 1
    numMinors := 0
  };
  psPhase13ShadowIsUnsupported (PsDeclaration.recursorDecl info)


def psPhase13ShadowTypeMismatchPass : Bool :=
  let declaration :=
    PsDeclaration.definitionDecl
      (psPhase13ShadowRootName "badType")
      []
      psPhase13ShadowNatType
      (PsExpr.lit (PsLiteral.string "notNat"));
  match psCompilerKernelShadowCheckDeclarations [declaration] with
  | Except.error (PsCompilerKernelShadowError.kernelRejected _) => true
  | _ => false


def psPhase13ShadowUnknownConstantPass : Bool :=
  let declaration :=
    PsDeclaration.definitionDecl
      (psPhase13ShadowRootName "badUnknown")
      []
      psPhase13ShadowNatType
      (PsExpr.constE (psPhase13ShadowRootName "MissingConstant") []);
  match psCompilerKernelShadowCheckDeclarations [declaration] with
  | Except.error (PsCompilerKernelShadowError.kernelRejected message) =>
      message.contains "unknown constant"
  | _ => false


def psPhase13ShadowDuplicateModulePass : Bool :=
  let name := psPhase13ShadowRootName "duplicateModule";
  let first :=
    PsDeclaration.definitionDecl
      name [] psPhase13ShadowNatType
      (PsExpr.lit (PsLiteral.natural 1));
  let second :=
    PsDeclaration.definitionDecl
      name [] psPhase13ShadowNatType
      (PsExpr.lit (PsLiteral.natural 2));
  match psCompilerKernelShadowCheckDeclarations [first, second] with
  | Except.error (PsCompilerKernelShadowError.kernelRejected message) =>
      message.contains "already declared"
  | _ => false


def psPhase13ShadowProjectionKernelRejectionPass : Bool :=
  let declaration :=
    PsDeclaration.definitionDecl
      (psPhase13ShadowRootName "badProjection")
      []
      psPhase13ShadowNatType
      (PsExpr.proj
        (psPhase13ShadowRootName "Nat")
        0
        (PsExpr.lit (PsLiteral.natural 0)));
  match psCompilerKernelShadowCheckDeclarations [declaration] with
  | Except.error (PsCompilerKernelShadowError.kernelRejected _) => true
  | _ => false


def psPhase13ShadowMissingPriorDeclarationPass : Bool :=
  let declaration :=
    PsDeclaration.definitionDecl
      (psPhase13ShadowRootName "second")
      []
      psPhase13ShadowNatType
      (PsExpr.constE (psPhase13ShadowRootName "first") []);
  match psCompilerKernelShadowCheckDeclarations [declaration] with
  | Except.error (PsCompilerKernelShadowError.kernelRejected message) =>
      message.contains "unknown constant"
  | _ => false


def psPhase13ShadowRejectionPass : Bool :=
  psPhase13ShadowPreparedIntegrityPass
    && psPhase13ShadowFreeVariablePass
    && psPhase13ShadowExpressionMetavariablePass
    && psPhase13ShadowUniverseMetavariablePass
    && psPhase13ShadowDuplicateAssumptionPass
    && psPhase13ShadowUnsupportedAxiomPass
    && psPhase13ShadowUnsupportedPartialPass
    && psPhase13ShadowUnsupportedOpaquePass
    && psPhase13ShadowUnsupportedInductivePass
    && psPhase13ShadowUnsupportedConstructorPass
    && psPhase13ShadowUnsupportedRecursorPass
    && psPhase13ShadowTypeMismatchPass
    && psPhase13ShadowUnknownConstantPass
    && psPhase13ShadowDuplicateModulePass
    && psPhase13ShadowProjectionKernelRejectionPass
    && psPhase13ShadowMissingPriorDeclarationPass


def main : IO Unit := do
  if psPhase13ShadowRejectionPass then
    IO.println "PSC2_KERNEL_CORE_PHASE13_SHADOW_REJECTION: PASS"
  else
    throw
      (IO.userError
        "PSC2_KERNEL_CORE_PHASE13_SHADOW_REJECTION: FAIL")
