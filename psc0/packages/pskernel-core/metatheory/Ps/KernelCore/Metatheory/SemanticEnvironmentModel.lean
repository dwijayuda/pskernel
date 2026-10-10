import Ps.KernelCore.Metatheory.SemanticPublicEntry
import Ps.KernelCore.Metatheory.SemanticReference

/-!
Environment-model currency over PSKernel's real stored declaration history
and accelerated lookup. This is a semantic INVARIANT to establish during
admission, never evidence that unverified acceptance is sound.
Only mathematical SetTheory assumptions are imported from Con Leche.
-/
namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetTheory ConLeche.SetModel AnnotatedExpr
universe u
variable {V : Type u} [SetTheory V]

/-- The reserved name used in the restricted modeled-axiom policy. Normal
Lean-compatible acceptance still permits assumptions and is not certified by
the following policy. -/
def falseConstantName : PsKernelName :=
  PsKernelName.str PsKernelName.anonymous "False"

def CorrectUniverseArity (info : PsKernelConstantInfo)
    (levels : List PsKernelLevel) : Prop :=
  psKernelNameListLength (psKernelConstantInfoLevelParams info) =
    psKernelLevelListLength levels

/-- Fix ONE annotated interpretation for a declaration's source type,
before quantifying over all valid universe instances and valuations. -/
def StoredConstantModeled (M : Reading V) (info : PsKernelConstantInfo) : Prop :=
  ∃ A : AnnotatedExpr, A.erase = psKernelConstantInfoType info ∧
    ∀ levels, CorrectUniverseArity info levels →
      ∀ ρ, M.constants (psKernelConstantInfoName info) (levels.map M.level) ∈ˢ
        interp (M.substLevels (psKernelConstantInfoLevelParams info) levels) ρ A

/-- Actual indexed lookup may not manufacture or misidentify stored records.
Every stored constant must possess a uniform semantic type reading. -/
structure EnvironmentModel (M : Reading V) (env : PsKernelEnvironment) : Prop where
  lookupInHistory : ∀ name info, psKernelEnvironmentFind env name = some info →
    info ∈ env.constants
  lookupName : ∀ name info, psKernelEnvironmentFind env name = some info →
    psKernelConstantInfoName info = name
  stored : ∀ info, info ∈ env.constants → StoredConstantModeled M info
  falsePinned : M.constants falseConstantName [] = (empty : V)

/-- Supply the already-existing constant-inference model premise from this
single environment invariant, for any dependent bound context. -/
theorem EnvironmentModel.constantInstance (M : Reading V)
    (env : PsKernelEnvironment) (Γ : List AnnotatedExpr)
    (name : PsKernelName) (levels : List PsKernelLevel)
    (info : PsKernelConstantInfo) (model : EnvironmentModel M env)
    (found : psKernelEnvironmentFind env name = some info)
    (arity : CorrectUniverseArity info levels) :
    ConstantInstance M Γ name levels info := by
  obtain ⟨A, erased, hMem⟩ :=
    model.stored info (model.lookupInHistory name info found)
  have hName := model.lookupName name info found
  refine ⟨A, erased, ?_⟩
  intro ρ _
  have h := hMem levels arity ρ
  rw [hName] at h
  exact h

theorem environmentEmpty_find (name : PsKernelName) :
    psKernelEnvironmentFind psKernelEnvironmentEmpty name = none := by
  rfl

theorem environmentEmpty_model (M : Reading V)
    (pin : M.constants falseConstantName [] = (empty : V)) :
    EnvironmentModel M psKernelEnvironmentEmpty where
  lookupInHistory := by
    intro name info found
    rw [environmentEmpty_find] at found
    cases found
  lookupName := by
    intro name info found
    rw [environmentEmpty_find] at found
    cases found
  stored := by
    intro info present
    cases present
  falsePinned := pin

/-- An explicitly constructed relative interpretation: no hidden axiom
asserts that a suitable V exists. -/
noncomputable def initialReading (V : Type u) [SetTheory V] : Reading V where
  levelParams := fun _ => 0
  levelMetavariables := fun _ => 0
  freeVars := fun _ => empty
  metavariables := fun _ => empty
  constants := fun _ _ => empty
  literals := fun _ => empty
  projections := fun _ _ _ => empty

theorem initialReading_falsePinned (V : Type u) [SetTheory V] :
    (initialReading V).constants falseConstantName [] = (empty : V) := rfl

theorem initialEnvironment_has_model (V : Type u) [SetTheory V] :
    ∃ M : Reading V, EnvironmentModel M psKernelEnvironmentEmpty :=
  ⟨initialReading V,
    environmentEmpty_model (initialReading V) (initialReading_falsePinned V)⟩

/-- Successful execution of the ACTUAL public constructor starts from the
modeled empty history; arbitrary user-made sessions are not covered. -/
theorem publicEmptySession_has_model (V : Type u) [SetTheory V]
    (resources : PsKernelResourcePolicy) (provider : PsKernelProviderCapability)
    (session : PsKernelKernelSession)
    (run : psKernelKernelSessionEmpty resources provider = .ok session) :
    ∃ M : Reading V, EnvironmentModel M session.environment := by
  rw [PsKernelSemantics.emptyKernelSession_environment
    resources provider session run]
  exact initialEnvironment_has_model V

/-- The actual checker run now establishes the arity premise itself;
the caller supplies only a modeled semantic environment. -/
theorem referenceConstant_from_environmentModel (M : Reading V)
    (Γ : List AnnotatedExpr) (fuel : Nat)
    (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (name : PsKernelName) (levels : List PsKernelLevel)
    (result : PsKernelExpr) (inferOnly : Bool)
    (model : EnvironmentModel M c.environment)
    (run : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
      fuel whnf defeq c s (.const name levels) inferOnly = .ok (result, next)) :
    ∃ A : AnnotatedExpr, A.erase = result ∧ ModelsType M Γ (.const name levels) A := by
  have arity := PsKernelSemantics.Reference.inferCore_const_success_valid_arity
    fuel whnf defeq c s next name levels result inferOnly run
  exact PsKernelSemantics.Reference.const_inference_has_set_model
    M Γ fuel whnf defeq c s next name levels result inferOnly
    (fun info found => EnvironmentModel.constantInstance M c.environment Γ
      name levels info model found (arity info found)) run

end PsKernelSemantics.SetModel
