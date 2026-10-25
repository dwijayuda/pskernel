import Ps.KernelCore.API.DagQuotAdmission
import PsKernelOrdinaryOccurrenceProofs

/- Local structural correspondence and atomic installation refinement.
   ArenaModel is the existing internal owning-arena invariant. The separately
   qualified replay/decoder bridge establishes it at the public boundary.
   These theorems are not global checker soundness or backend preservation. -/
namespace PsKernelQuotAdmissionProofs
open PsKernelOrdinaryOccurrenceProofs

inductive BootstrapShape : PsKernelExpr -> Prop where
  | bvar (index : Nat) : BootstrapShape (.bvar index)
  | sort (level : PsKernelLevel) : BootstrapShape (.sort level)
  | const (name : PsKernelName) (levels : List PsKernelLevel) :
      BootstrapShape (.const name levels)
  | app {fn arg : PsKernelExpr} :
      BootstrapShape fn -> BootstrapShape arg -> BootstrapShape (.app fn arg)
  | forallE (name : PsKernelName) (info : PsKernelBinderInfo)
      {domain body : PsKernelExpr} :
      BootstrapShape domain -> BootstrapShape body ->
      BootstrapShape (.forallE name domain body info)

theorem match_shape_correspondence
    (arena : PsKernelExprV2PagedArena) (meaning : Nat -> PsKernelExpr)
    (model : ArenaModel arena meaning)
    (expected : PsKernelExpr) (supported : BootstrapShape expected) :
    forall root, validId arena root ->
      psKernelDagQuotMatchShape expected arena root =
        Option.some (psKernelExprEq (meaning root) expected) := by
  induction supported with
  | bvar index =>
      intro root valid
      rcases valid with ⟨entry, found⟩
      have shape := model.shape root entry found
      cases node : entry.node <;>
        simp [psKernelDagQuotMatchShape, found, shape, node, nodeExpr, psKernelExprEq]
  | sort level =>
      intro root valid
      rcases valid with ⟨entry, found⟩
      have shape := model.shape root entry found
      cases node : entry.node <;>
        simp [psKernelDagQuotMatchShape, found, shape, node, nodeExpr, psKernelExprEq]
  | const name levels =>
      intro root valid
      rcases valid with ⟨entry, found⟩
      have shape := model.shape root entry found
      cases node : entry.node <;>
        simp [psKernelDagQuotMatchShape, found, shape, node, nodeExpr, psKernelExprEq]
  | @app fn arg _ _ ihFn ihArg =>
      intro root valid
      rcases valid with ⟨entry, found⟩
      have shape := model.shape root entry found
      have children := model.children root entry found
      cases node : entry.node
      case app actualFn actualArg =>
        have fnValid : validId arena actualFn :=
          children actualFn (by simp [childIds, node, psKernelExprV2TransformChildren])
        have argValid : validId arena actualArg :=
          children actualArg (by simp [childIds, node, psKernelExprV2TransformChildren])
        have first := ihFn actualFn fnValid
        have second := ihArg actualArg argValid
        simp only [psKernelDagQuotMatchShape, found, node, first, second,
          shape, nodeExpr, psKernelExprEq]
        cases psKernelExprEq (meaning actualFn) fn <;> rfl
      all_goals
        simp [psKernelDagQuotMatchShape, found, shape, node, nodeExpr, psKernelExprEq]
  | @forallE name info domain body _ _ ihDomain ihBody =>
      intro root valid
      rcases valid with ⟨entry, found⟩
      have shape := model.shape root entry found
      have children := model.children root entry found
      cases node : entry.node
      case forallE actualName actualDomain actualBody actualInfo =>
        have domainValid : validId arena actualDomain :=
          children actualDomain (by simp [childIds, node, psKernelExprV2TransformChildren])
        have bodyValid : validId arena actualBody :=
          children actualBody (by simp [childIds, node, psKernelExprV2TransformChildren])
        have first := ihDomain actualDomain domainValid
        have second := ihBody actualBody bodyValid
        simp only [psKernelDagQuotMatchShape, found, node, first, second,
          shape, nodeExpr, psKernelExprEq]
        cases psKernelExprEq (meaning actualDomain) domain <;> rfl
      all_goals
        simp [psKernelDagQuotMatchShape, found, shape, node, nodeExpr, psKernelExprEq]

theorem expected_eq_supported (universeName : PsKernelName) :
    BootstrapShape (psKernelExpectedEqType universeName) := by
  have same : psKernelNameEq (psKernelQuotInternalName "eq.alpha")
      (psKernelQuotInternalName "eq.alpha") = true := by decide
  simp [psKernelExpectedEqType, psKernelCloseOpenBinders, psKernelMkArrow,
    psKernelExprAbstractFVars, psKernelExprAbstractFVarsAt,
    psKernelExprAbstractFVarsAtChanged, psKernelExprAbstractFVarsAtChangedWithFuel,
    psKernelExprNodeCount, psKernelNameLastIndex, psKernelNameLastIndexWorker,
    psKernelNameListLength, psKernelApplyArgs, same]
  repeat constructor

theorem expected_refl_supported (universeName : PsKernelName) :
    BootstrapShape (psKernelExpectedEqReflType universeName) := by
  have aa : psKernelNameEq (psKernelQuotInternalName "eqRefl.alpha")
      (psKernelQuotInternalName "eqRefl.alpha") = true := by decide
  have av : psKernelNameEq (psKernelQuotInternalName "eqRefl.alpha")
      (psKernelQuotInternalName "eqRefl.a") = false := by decide
  have va : psKernelNameEq (psKernelQuotInternalName "eqRefl.a")
      (psKernelQuotInternalName "eqRefl.alpha") = false := by decide
  have vv : psKernelNameEq (psKernelQuotInternalName "eqRefl.a")
      (psKernelQuotInternalName "eqRefl.a") = true := by decide
  simp [psKernelExpectedEqReflType, psKernelCloseOpenBinders, psKernelMkArrow,
    psKernelExprAbstractFVars, psKernelExprAbstractFVarsAt,
    psKernelExprAbstractFVarsAtChanged, psKernelExprAbstractFVarsAtChangedWithFuel,
    psKernelExprNodeCount, psKernelNameLastIndex, psKernelNameLastIndexWorker,
    psKernelNameListLength, psKernelApplyArgs, aa, av, va, vv]
  repeat constructor

theorem eq_shape_correspondence
    (arena : PsKernelExprV2PagedArena) (meaning : Nat -> PsKernelExpr)
    (model : ArenaModel arena meaning) (root : Nat) (valid : validId arena root)
    (universeName : PsKernelName) :
    psKernelDagQuotMatchShape (psKernelExpectedEqType universeName) arena root =
      Option.some (psKernelExprEq (meaning root) (psKernelExpectedEqType universeName)) :=
  match_shape_correspondence arena meaning model _ (expected_eq_supported universeName) root valid

theorem refl_shape_correspondence
    (arena : PsKernelExprV2PagedArena) (meaning : Nat -> PsKernelExpr)
    (model : ArenaModel arena meaning) (root : Nat) (valid : validId arena root)
    (universeName : PsKernelName) :
    psKernelDagQuotMatchShape (psKernelExpectedEqReflType universeName) arena root =
      Option.some (psKernelExprEq (meaning root) (psKernelExpectedEqReflType universeName)) :=
  match_shape_correspondence arena meaning model _ (expected_refl_supported universeName) root valid

theorem initialized_returns_exact_environment
    (environment : PsKernelEnvironment) (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef)
    (initialized : environment.quotInitialized = true) :
    psKernelDagTryAdmitQuot environment arena declarations =
      Option.some (Except.ok environment) := by
  simp only [psKernelDagTryAdmitQuot, initialized, ite_true]

theorem declined_check_does_not_install
    (environment : PsKernelEnvironment) (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef)
    (uninitialized : environment.quotInitialized = false)
    (declined : psKernelDagCheckEqForQuot environment arena declarations = Option.none) :
    psKernelDagTryAdmitQuot environment arena declarations = Option.none := by
  simp only [psKernelDagTryAdmitQuot, uninitialized, Bool.false_eq_true, ite_false, declined]

theorem failed_check_does_not_install
    (environment : PsKernelEnvironment) (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef) (error : String)
    (uninitialized : environment.quotInitialized = false)
    (failed : psKernelDagCheckEqForQuot environment arena declarations =
      Option.some (Except.error error)) :
    psKernelDagTryAdmitQuot environment arena declarations =
      Option.some (Except.error error) := by
  simp only [psKernelDagTryAdmitQuot, uninitialized, Bool.false_eq_true, ite_false, failed]

private def frozenAddQuot
    (environment : PsKernelEnvironment) :
    Except String PsKernelEnvironment :=
  if environment.quotInitialized then
    Except.ok environment
  else
    match psKernelCheckEqForQuot environment with
    | Except.error error =>
        Except.error error
    | Except.ok _ =>
        let reserved :=
          List.cons
            psKernelQuotName
            (List.cons
              psKernelQuotMkName
              (List.cons
                psKernelQuotLiftName
                (List.cons
                  psKernelQuotIndName
                  List.nil)));
        match
            psKernelCheckQuotReservedNames
              environment
              reserved with
        | Except.error error =>
            Except.error error
        | Except.ok _ =>
            let universeName :=
              PsKernelName.str
                PsKernelName.anonymous
                "u";
            let resultUniverseName :=
              PsKernelName.str
                PsKernelName.anonymous
                "v";
            let quotTypeBase :=
              PsKernelConstantBase.mk
                psKernelQuotName
                (List.cons
                  universeName
                  List.nil)
                (psKernelMakeQuotType
                  universeName);
            let quotTypeInfo :=
              PsKernelQuotInfo.mk
                quotTypeBase
                PsKernelQuotKind.typeQ;
            let env1 :=
              psKernelEnvironmentAddUnchecked
                environment
                (PsKernelConstantInfo.quotInfo
                  quotTypeInfo);
            let quotMkBase :=
              PsKernelConstantBase.mk
                psKernelQuotMkName
                (List.cons
                  universeName
                  List.nil)
                (psKernelMakeQuotMkType
                  universeName);
            let quotMkInfo :=
              PsKernelQuotInfo.mk
                quotMkBase
                PsKernelQuotKind.ctorQ;
            let env2 :=
              psKernelEnvironmentAddUnchecked
                env1
                (PsKernelConstantInfo.quotInfo
                  quotMkInfo);
            let quotLiftBase :=
              PsKernelConstantBase.mk
                psKernelQuotLiftName
                (List.cons
                  universeName
                  (List.cons
                    resultUniverseName
                    List.nil))
                (psKernelMakeQuotLiftType
                  universeName
                  resultUniverseName);
            let quotLiftInfo :=
              PsKernelQuotInfo.mk
                quotLiftBase
                PsKernelQuotKind.liftQ;
            let env3 :=
              psKernelEnvironmentAddUnchecked
                env2
                (PsKernelConstantInfo.quotInfo
                  quotLiftInfo);
            let quotIndBase :=
              PsKernelConstantBase.mk
                psKernelQuotIndName
                (List.cons
                  universeName
                  List.nil)
                (psKernelMakeQuotIndType
                  universeName);
            let quotIndInfo :=
              PsKernelQuotInfo.mk
                quotIndBase
                PsKernelQuotKind.indQ;
            let env4 :=
              psKernelEnvironmentAddUnchecked
                env3
                (PsKernelConstantInfo.quotInfo
                  quotIndInfo);
            Except.ok
              (psKernelEnvironmentMarkQuotInitialized
                env4)

theorem shared_install_preserves_frozen_admission (environment : PsKernelEnvironment) :
    psKernelAddQuot environment = frozenAddQuot environment := by
  rfl

end PsKernelQuotAdmissionProofs

#print axioms PsKernelQuotAdmissionProofs.match_shape_correspondence
#print axioms PsKernelQuotAdmissionProofs.expected_eq_supported
#print axioms PsKernelQuotAdmissionProofs.expected_refl_supported
#print axioms PsKernelQuotAdmissionProofs.eq_shape_correspondence
#print axioms PsKernelQuotAdmissionProofs.refl_shape_correspondence
#print axioms PsKernelQuotAdmissionProofs.initialized_returns_exact_environment
#print axioms PsKernelQuotAdmissionProofs.declined_check_does_not_install
#print axioms PsKernelQuotAdmissionProofs.failed_check_does_not_install
#print axioms PsKernelQuotAdmissionProofs.shared_install_preserves_frozen_admission
