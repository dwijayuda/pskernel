import Ps.KernelCore.API.DagQuotAdmission
import PsKernelOrdinaryOccurrenceProofs

/- Local all-pattern structural correspondence over the actual owning-arena
   model. The qualified replay/decoder bridge establishes that model separately.
   This proves neither global checker soundness nor backend preservation. -/
namespace PsKernelQuotAdmissionProofs
open PsKernelOrdinaryOccurrenceProofs

theorem match_shape_correspondence
    (arena : PsKernelExprV2PagedArena) (meaning : Nat -> PsKernelExpr)
    (model : ArenaModel arena meaning) (expected : PsKernelExpr) :
    forall root, validId arena root ->
      psKernelDagQuotMatchShape expected arena root =
        Option.some (psKernelExprEq (meaning root) expected) := by
  induction expected with
  | bvar index =>
      intro root valid
      rcases valid with ⟨entry, found⟩
      have shape := model.shape root entry found
      cases node : entry.node <;>
        simp [psKernelDagQuotMatchShape, found, shape, node, nodeExpr, psKernelExprEq]
  | fvar name =>
      intro root valid
      rcases valid with ⟨entry, found⟩
      have shape := model.shape root entry found
      cases node : entry.node <;>
        simp [psKernelDagQuotMatchShape, found, shape, node, nodeExpr, psKernelExprEq]
  | mvar name =>
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
  | lit value =>
      intro root valid
      rcases valid with ⟨entry, found⟩
      have shape := model.shape root entry found
      cases node : entry.node <;>
        simp [psKernelDagQuotMatchShape, found, shape, node, nodeExpr, psKernelExprEq]
  | app fn arg ihFn ihArg =>
      intro root valid
      rcases valid with ⟨entry, found⟩
      have shape := model.shape root entry found
      have children := model.children root entry found
      cases node : entry.node
      case app actualFn actualArg =>
        have leftValid : validId arena actualFn :=
          children actualFn (by simp [childIds, node, psKernelExprV2TransformChildren])
        have rightValid : validId arena actualArg :=
          children actualArg (by simp [childIds, node, psKernelExprV2TransformChildren])
        have first := ihFn actualFn leftValid
        have second := ihArg actualArg rightValid
        simp only [psKernelDagQuotMatchShape, found, node, first, second,
          shape, nodeExpr, psKernelExprEq]
        cases psKernelExprEq (meaning actualFn) fn <;> rfl
      all_goals
        simp [psKernelDagQuotMatchShape, found, shape, node, nodeExpr, psKernelExprEq]
  | lam name domain body info ihDomain ihBody =>
      intro root valid
      rcases valid with ⟨entry, found⟩
      have shape := model.shape root entry found
      have children := model.children root entry found
      cases node : entry.node
      case lam actualName actualDomain actualBody actualInfo =>
        have leftValid : validId arena actualDomain :=
          children actualDomain (by simp [childIds, node, psKernelExprV2TransformChildren])
        have rightValid : validId arena actualBody :=
          children actualBody (by simp [childIds, node, psKernelExprV2TransformChildren])
        have first := ihDomain actualDomain leftValid
        have second := ihBody actualBody rightValid
        simp only [psKernelDagQuotMatchShape, found, node, first, second,
          shape, nodeExpr, psKernelExprEq]
        cases psKernelExprEq (meaning actualDomain) domain <;> rfl
      all_goals
        simp [psKernelDagQuotMatchShape, found, shape, node, nodeExpr, psKernelExprEq]
  | forallE name domain body info ihDomain ihBody =>
      intro root valid
      rcases valid with ⟨entry, found⟩
      have shape := model.shape root entry found
      have children := model.children root entry found
      cases node : entry.node
      case forallE actualName actualDomain actualBody actualInfo =>
        have leftValid : validId arena actualDomain :=
          children actualDomain (by simp [childIds, node, psKernelExprV2TransformChildren])
        have rightValid : validId arena actualBody :=
          children actualBody (by simp [childIds, node, psKernelExprV2TransformChildren])
        have first := ihDomain actualDomain leftValid
        have second := ihBody actualBody rightValid
        simp only [psKernelDagQuotMatchShape, found, node, first, second,
          shape, nodeExpr, psKernelExprEq]
        cases psKernelExprEq (meaning actualDomain) domain <;> rfl
      all_goals
        simp [psKernelDagQuotMatchShape, found, shape, node, nodeExpr, psKernelExprEq]
  | letE name type value body nondep ihType ihValue ihBody =>
      intro root valid
      rcases valid with ⟨entry, found⟩
      have shape := model.shape root entry found
      have children := model.children root entry found
      cases node : entry.node
      case letE actualName actualType actualValue actualBody actualNondep =>
        have typeValid : validId arena actualType :=
          children actualType (by simp [childIds, node, psKernelExprV2TransformChildren])
        have valueValid : validId arena actualValue :=
          children actualValue (by simp [childIds, node, psKernelExprV2TransformChildren])
        have bodyValid : validId arena actualBody :=
          children actualBody (by simp [childIds, node, psKernelExprV2TransformChildren])
        have ht := ihType actualType typeValid
        have hv := ihValue actualValue valueValid
        have hb := ihBody actualBody bodyValid
        simp only [psKernelDagQuotMatchShape, found, node, ht, hv, hb,
          shape, nodeExpr, psKernelExprEq]
        cases psKernelExprEq (meaning actualType) type <;>
          cases psKernelExprEq (meaning actualValue) value <;>
          cases psKernelExprEq (meaning actualBody) body <;> rfl
      all_goals
        simp [psKernelDagQuotMatchShape, found, shape, node, nodeExpr, psKernelExprEq]
  | mdata tag body ihBody =>
      intro root valid
      rcases valid with ⟨entry, found⟩
      have shape := model.shape root entry found
      have children := model.children root entry found
      cases node : entry.node
      case mdata actualTag actualBody =>
        have bodyValid : validId arena actualBody :=
          children actualBody (by simp [childIds, node, psKernelExprV2TransformChildren])
        have next := ihBody actualBody bodyValid
        simp only [psKernelDagQuotMatchShape, found, node, next, shape, nodeExpr, psKernelExprEq]
        cases Nat.beq actualTag tag <;> rfl
      all_goals
        simp [psKernelDagQuotMatchShape, found, shape, node, nodeExpr, psKernelExprEq]
  | proj name index body ihBody =>
      intro root valid
      rcases valid with ⟨entry, found⟩
      have shape := model.shape root entry found
      have children := model.children root entry found
      cases node : entry.node
      case proj actualName actualIndex actualBody =>
        have bodyValid : validId arena actualBody :=
          children actualBody (by simp [childIds, node, psKernelExprV2TransformChildren])
        have next := ihBody actualBody bodyValid
        simp only [psKernelDagQuotMatchShape, found, node, next, shape, nodeExpr, psKernelExprEq]
        cases psKernelNameEq actualName name <;> cases Nat.beq actualIndex index <;> rfl
      all_goals
        simp [psKernelDagQuotMatchShape, found, shape, node, nodeExpr, psKernelExprEq]
theorem eq_shape_correspondence
    (arena : PsKernelExprV2PagedArena) (meaning : Nat -> PsKernelExpr)
    (model : ArenaModel arena meaning) (root : Nat) (valid : validId arena root)
    (universeName : PsKernelName) :
    psKernelDagQuotMatchShape (psKernelExpectedEqType universeName) arena root =
      Option.some (psKernelExprEq (meaning root) (psKernelExpectedEqType universeName)) :=
  match_shape_correspondence arena meaning model _ root valid

theorem refl_shape_correspondence
    (arena : PsKernelExprV2PagedArena) (meaning : Nat -> PsKernelExpr)
    (model : ArenaModel arena meaning) (root : Nat) (valid : validId arena root)
    (universeName : PsKernelName) :
    psKernelDagQuotMatchShape (psKernelExpectedEqReflType universeName) arena root =
      Option.some (psKernelExprEq (meaning root) (psKernelExpectedEqReflType universeName)) :=
  match_shape_correspondence arena meaning model _ root valid

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

theorem missing_owner_declines
    (arena : PsKernelExprV2PagedArena) (declarations : List PsKernelExprV2DeclarationRef)
    (info : PsKernelConstantInfo) (expected : PsKernelExpr)
    (missing : psKernelExprV2DeclarationRefFind declarations (psKernelConstantInfoName info) = none) :
    psKernelDagQuotMatchInfo arena declarations info expected = none := by
  simp only [psKernelDagQuotMatchInfo, missing]

theorem wrong_owner_declines
    (arena : PsKernelExprV2PagedArena) (declarations : List PsKernelExprV2DeclarationRef)
    (info : PsKernelConstantInfo) (expected : PsKernelExpr) (owner : PsKernelExprV2DeclarationRef)
    (found : psKernelExprV2DeclarationRefFind declarations (psKernelConstantInfoName info) = some owner)
    (wrong : psKernelExprV2DeclarationRefMatches owner info = false) :
    psKernelDagQuotMatchInfo arena declarations info expected = none := by
  simp only [psKernelDagQuotMatchInfo, found, wrong, Bool.false_eq_true, ite_false]

end PsKernelQuotAdmissionProofs

#print axioms PsKernelQuotAdmissionProofs.match_shape_correspondence
#print axioms PsKernelQuotAdmissionProofs.eq_shape_correspondence
#print axioms PsKernelQuotAdmissionProofs.refl_shape_correspondence
#print axioms PsKernelQuotAdmissionProofs.initialized_returns_exact_environment
#print axioms PsKernelQuotAdmissionProofs.declined_check_does_not_install
#print axioms PsKernelQuotAdmissionProofs.failed_check_does_not_install
#print axioms PsKernelQuotAdmissionProofs.shared_install_preserves_frozen_admission
#print axioms PsKernelQuotAdmissionProofs.missing_owner_declines
#print axioms PsKernelQuotAdmissionProofs.wrong_owner_declines
