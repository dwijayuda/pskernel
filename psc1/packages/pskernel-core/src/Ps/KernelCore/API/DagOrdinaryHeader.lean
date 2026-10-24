import Ps.KernelCore.API.DagTypes
import Ps.KernelCore.API.DagAdmissionGuards
import Ps.KernelCore.API.DagOrdinaryOccurrence
import Ps.KernelCore.API.DagOrdinaryParameters
import Ps.KernelCore.Admission.Inductive.Ordinary.Admission

/-
Private ID-native ordinary-inductive header analysis. The input arena must
already be canonical, and declaration references belong to its checked owner.
The public DAG boundary continues to validate/replay untrusted arenas.

This worker stops before provisional inductive metadata, constructors, recursor
generation and publication. A successful analysis is not an admission receipt;
the existing complete ordinary-admission fallback remains unchanged.
-/

def psKernelExprV2OrdinaryCtorNames
    (ctors : List PsKernelDagConstructor) : List PsKernelName :=
  match ctors with
  | List.nil => List.nil
  | List.cons ctor rest =>
      List.cons ctor.name (psKernelExprV2OrdinaryCtorNames rest)

def psKernelExprV2OrdinaryCtorTypes
    (ctors : List PsKernelDagConstructor) : List Nat :=
  match ctors with
  | List.nil => List.nil
  | List.cons ctor rest =>
      List.cons ctor.type (psKernelExprV2OrdinaryCtorTypes rest)

/- Preserve the ordinary guard order and its original diagnostics. Generic
   declaration-header admission has a different name/universe order and is
   deliberately not used as a substitute here. -/
def psKernelExprV2OrdinaryHeaderGuardsOnCanonical
    (arena : PsKernelExprV2PagedArena)
    (environment : PsKernelEnvironment)
    (levelParams : List PsKernelName) (numParams : Nat)
    (value : PsKernelDagInductive) : Except String Unit :=
  if psKernelNameHasDuplicates levelParams then
    Except.error "duplicate universe parameter"
  else
    let allNames :=
      List.cons value.name
        (List.cons (psKernelSimpleRecName value.name)
          (psKernelExprV2OrdinaryCtorNames value.ctors));
    if psKernelSimpleNameListUnique allNames then
      match psKernelCheckFreshInductiveNames allNames environment with
      | Except.error error => Except.error error
      | Except.ok _ =>
          match psKernelExprV2OrdinaryUniformOccurrences
              (psKernelExprV2OrdinaryCtorTypes value.ctors) arena
              (List.cons value.name List.nil)
              (psKernelLevelParamsToLevels levelParams) numParams with
          | Except.error error => Except.error error
          | Except.ok _ =>
              psKernelExprV2AdmissionStaticOnCanonical
                arena value.type levelParams
    else
      Except.error "duplicate inductive, constructor, or recursor name"

def psKernelExprV2OrdinaryHeaderFinish
    (parameters indices : PsKernelExprV2OrdinaryOpenResult) :
    Except String PsKernelExprV2OrdinaryHeaderAnalysis :=
  match psKernelExprV2PagedRequire indices.state.whnf.arena indices.result with
  | Except.error error => Except.error error
  | Except.ok entry =>
      match entry.node with
      | PsKernelExprV2Node.sort resultLevel =>
          Except.ok
            (PsKernelExprV2OrdinaryHeaderAnalysis.mk parameters indices resultLevel)
      | _ => Except.error "simple inductive result must be a sort"

/- Both callbacks receive the complete current owner and the exact checker
   fuel for their phase. Admission EnsureSort always calls public WHNF. -/
def psKernelExprV2OrdinaryHeaderPhasesWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (type numParams : Nat) :
    Option (Except String PsKernelExprV2OrdinaryHeaderAnalysis) :=
  match check fuel context state type with
  | Option.none => Option.none
  | Option.some attemptedCheck =>
      match attemptedCheck with
      | Except.error error => Option.some (Except.error error)
      | Except.ok checked =>
          let publicWhnf :=
            fun (nextContext : PsKernelExprV2CheckContext)
                (nextState : PsKernelExprV2CheckState) (nextRoot : Nat) =>
              whnf fuel nextContext nextState nextRoot;
          match psKernelExprV2AdmissionEnsureSortOwnedWith
              publicWhnf context (Prod.fst checked) (Prod.snd checked) with
          | Option.none => Option.none
          | Option.some attemptedSort =>
              match attemptedSort with
              | Except.error error => Option.some (Except.error error)
              | Except.ok sorted =>
                  match psKernelExprV2OrdinaryOpenHeaderParamsWith
                      check whnf fuel context (Prod.fst sorted) type numParams with
                  | Option.none => Option.none
                  | Option.some attemptedParameters =>
                      match attemptedParameters with
                      | Except.error error => Option.some (Except.error error)
                      | Except.ok parameters =>
                          match psKernelExprV2OrdinaryOpenHeaderIndicesWith
                              check whnf fuel parameters.context parameters.state
                              parameters.result with
                          | Option.none => Option.none
                          | Option.some attemptedIndices =>
                              match attemptedIndices with
                              | Except.error error => Option.some (Except.error error)
                              | Except.ok indices =>
                                  Option.some
                                    (psKernelExprV2OrdinaryHeaderFinish parameters indices)

def psKernelExprV2OrdinaryAnalyzeHeaderWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (fuel : Nat) (environment : PsKernelEnvironment)
    (maxRecDepth maxNatSize : Nat) (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef)
    (levelParams : List PsKernelName) (numParams : Nat)
    (value : PsKernelDagInductive) (isUnsafe : Bool) :
    Option (Except String PsKernelExprV2OrdinaryHeaderAnalysis) :=
  match psKernelExprV2OrdinaryHeaderGuardsOnCanonical
      arena environment levelParams numParams value with
  | Except.error error => Option.some (Except.error error)
  | Except.ok _ =>
      let safety :=
        if isUnsafe then PsKernelDefinitionSafety.unsafeDef
        else PsKernelDefinitionSafety.safe;
      let checker := psKernelMkCheckerSession environment levelParams
        safety maxRecDepth maxNatSize;
      let context := psKernelExprV2CheckContextEmpty checker.context;
      let state :=
        psKernelExprV2CheckStateWithWhnf (psKernelExprV2CheckStateEmpty arena)
          (psKernelExprV2WhnfStateForDeclarations arena declarations);
      psKernelExprV2OrdinaryHeaderPhasesWith
        check whnf fuel context state value.type numParams

def psKernelExprV2OrdinaryAnalyzeHeaderWithFuel
    (fuel : Nat) (environment : PsKernelEnvironment)
    (maxRecDepth maxNatSize : Nat) (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef)
    (levelParams : List PsKernelName) (numParams : Nat)
    (value : PsKernelDagInductive) (isUnsafe : Bool) :
    Option (Except String PsKernelExprV2OrdinaryHeaderAnalysis) :=
  let check :=
    fun (nextFuel : Nat) (nextContext : PsKernelExprV2CheckContext)
        (nextState : PsKernelExprV2CheckState) (nextRoot : Nat) =>
      psKernelExprV2TryCheckStateWithFuel
        nextFuel nextContext nextState nextRoot;
  let whnf :=
    fun (nextFuel : Nat) (nextContext : PsKernelExprV2CheckContext)
        (nextState : PsKernelExprV2CheckState) (nextRoot : Nat) =>
      psKernelExprV2TryWhnfCheckStateWithFuel
        nextFuel nextContext nextState nextRoot;
  psKernelExprV2OrdinaryAnalyzeHeaderWith check whnf fuel environment
    maxRecDepth maxNatSize arena declarations levelParams numParams value isUnsafe
