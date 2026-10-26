import Ps.KernelCore.API.DagNestedOverlay
import Ps.KernelCore.API.DagMutualAdmission
import Ps.KernelCore.API.DagOrdinaryAdmission

/- Private transformed nested admission. Original named headers/constructors
   supply only origin IDs for the syntax overlay; every resulting target is
   independently checked by the existing owning ordinary/mutual transaction.
   Auxiliary syntax without an original counterpart uses the generated importer.
   The no-aux dispatch and transformed-error prefix follow the retained nested
   transaction exactly. No V1 checker, original-admission restart, restoration,
   final environment publication or resource-policy bypass occurs here. -/

def psKernelExprV2NestedOriginType
    (name : PsKernelName) (types : List PsKernelDagInductive) : Option PsKernelDagInductive :=
  match types with
  | List.nil => Option.none
  | List.cons first rest =>
      if psKernelNameEq name first.name then Option.some first
      else psKernelExprV2NestedOriginType name rest

def psKernelExprV2NestedOriginConstructor
    (name : PsKernelName) (ctors : List PsKernelDagConstructor) : Option PsKernelDagConstructor :=
  match ctors with
  | List.nil => Option.none
  | List.cons first rest =>
      if psKernelNameEq name first.name then Option.some first
      else psKernelExprV2NestedOriginConstructor name rest

def psKernelExprV2NestedImportConstructorTargets
    (targets : List PsKernelSimpleConstructorDecl) (origins : List PsKernelDagConstructor)
    (state : PsKernelDagGeneratedState) :
    Except String (Prod PsKernelDagGeneratedState (List PsKernelDagConstructor)) :=
  match targets with
  | List.nil => Except.ok (Prod.mk state List.nil)
  | List.cons first rest =>
      let imported :=
        match psKernelExprV2NestedOriginConstructor first.name origins with
        | Option.none => psKernelDagGeneratedImport first.type state
        | Option.some original => psKernelExprV2NestedOverlay first.type original.type state;
      match imported with
      | Except.error error => Except.error error
      | Except.ok current =>
          match psKernelExprV2NestedImportConstructorTargets rest origins (Prod.fst current) with
          | Except.error error => Except.error error
          | Except.ok tail => Except.ok (Prod.mk (Prod.fst tail)
              (List.cons (PsKernelDagConstructor.mk first.name (Prod.snd current)) (Prod.snd tail)))

def psKernelExprV2NestedImportTypeTarget
    (target : PsKernelSimpleMutualTypeDecl) (origins : List PsKernelDagInductive)
    (state : PsKernelDagGeneratedState) :
    Except String (Prod PsKernelDagGeneratedState PsKernelDagInductive) :=
  let original := psKernelExprV2NestedOriginType target.name origins;
  let imported :=
    match original with
    | Option.none => psKernelDagGeneratedImport target.type state
    | Option.some old => psKernelExprV2NestedOverlay target.type old.type state;
  match imported with
  | Except.error error => Except.error error
  | Except.ok header =>
      let constructors := match original with
        | Option.none => List.nil
        | Option.some old => old.ctors;
      match psKernelExprV2NestedImportConstructorTargets target.ctors constructors (Prod.fst header) with
      | Except.error error => Except.error error
      | Except.ok ctors => Except.ok (Prod.mk (Prod.fst ctors)
          (PsKernelDagInductive.mk target.name (Prod.snd header) (Prod.snd ctors)))

def psKernelExprV2NestedImportTypeTargets
    (targets : List PsKernelSimpleMutualTypeDecl) (origins : List PsKernelDagInductive)
    (state : PsKernelDagGeneratedState) :
    Except String (Prod PsKernelDagGeneratedState (List PsKernelDagInductive)) :=
  match targets with
  | List.nil => Except.ok (Prod.mk state List.nil)
  | List.cons first rest =>
      match psKernelExprV2NestedImportTypeTarget first origins state with
      | Except.error error => Except.error error
      | Except.ok current =>
          match psKernelExprV2NestedImportTypeTargets rest origins (Prod.fst current) with
          | Except.error error => Except.error error
          | Except.ok tail => Except.ok (Prod.mk (Prod.fst tail) (List.cons (Prod.snd current) (Prod.snd tail)))

structure PsKernelExprV2NestedPreparedTransformed where
  preprocessed : PsKernelExprV2NestedPreprocessed
  value : PsKernelDagInductiveGroup
  owner : PsKernelDagGeneratedState

def psKernelExprV2NestedPrepareTransformed
    (origins : PsKernelDagInductiveGroup) (plan : PsKernelExprV2NestedPreprocessed) :
    Except String PsKernelExprV2NestedPreparedTransformed :=
  match psKernelExprV2NestedImportTypeTargets plan.processed.types origins.types plan.owner with
  | Except.error error => Except.error error
  | Except.ok imported =>
      let decl := plan.header.original;
      let value := PsKernelDagInductiveGroup.mk decl.levelParams decl.numParams (Prod.snd imported) decl.isUnsafe;
      Except.ok (PsKernelExprV2NestedPreparedTransformed.mk plan value (Prod.fst imported))

def psKernelExprV2NestedTransformedPrefix
    (hasAux : Bool) (attempt : Option (Except String PsKernelExprV2OrdinaryAdmissionResult)) :
    Option (Except String PsKernelExprV2OrdinaryAdmissionResult) :=
  match attempt with
  | Option.none => Option.none
  | Option.some result =>
      match result with
      | Except.ok admitted => Option.some (Except.ok admitted)
      | Except.error error =>
          if hasAux then Option.some (Except.error (String.Internal.append "nested transformed admission: " error))
          else Option.some (Except.error error)

def psKernelExprV2NestedAdmitModeWith
    (ordinary : Nat -> PsKernelEnvironment -> Nat -> Nat -> PsKernelExprV2Decoded ->
      PsKernelDagGeneratedState -> List PsKernelName -> Nat -> PsKernelDagInductive -> Bool ->
      Option (Except String PsKernelExprV2OrdinaryAdmissionResult))
    (admitMutual : Nat -> PsKernelEnvironment -> Nat -> Nat -> PsKernelExprV2Decoded ->
      PsKernelDagGeneratedState -> PsKernelDagInductiveGroup ->
      Option (Except String PsKernelExprV2OrdinaryAdmissionResult))
    (hasAux : Bool) (fuel : Nat) (environment : PsKernelEnvironment) (maxRecDepth maxNatSize : Nat)
    (owner : PsKernelDagGeneratedState) (value : PsKernelDagInductiveGroup) :
    Option (Except String PsKernelExprV2OrdinaryAdmissionResult) :=
  if hasAux then
    psKernelExprV2NestedTransformedPrefix true
      (admitMutual fuel environment maxRecDepth maxNatSize owner.built owner value)
  else
    match value.types with
    | List.nil => Option.some (Except.error "empty nested inductive declaration")
    | List.cons first rest =>
        match rest with
        | List.nil => ordinary fuel environment maxRecDepth maxNatSize owner.built owner
            value.levelParams value.numParams first value.isUnsafe
        | List.cons _ _ => admitMutual fuel environment maxRecDepth maxNatSize owner.built owner value

structure PsKernelExprV2NestedCheckedTransformed where
  preprocessed : PsKernelExprV2NestedPreprocessed
  value : PsKernelDagInductiveGroup
  admitted : PsKernelExprV2OrdinaryAdmissionResult

def psKernelExprV2NestedCheckPreparedWith
    (check whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (fuel : Nat) (environment : PsKernelEnvironment) (maxRecDepth maxNatSize : Nat)
    (prepared : PsKernelExprV2NestedPreparedTransformed) :
    Option (Except String PsKernelExprV2NestedCheckedTransformed) :=
  let hasAux := match prepared.preprocessed.processed.state.aux with
    | List.nil => false
    | List.cons _ _ => true;
  match psKernelExprV2NestedAdmitModeWith
      (psKernelExprV2OrdinaryAdmitWith check whnf defeq)
      (psKernelExprV2MutualAdmitWith check whnf defeq)
      hasAux fuel environment maxRecDepth maxNatSize prepared.owner prepared.value with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok admitted => Option.some (Except.ok
          (PsKernelExprV2NestedCheckedTransformed.mk prepared.preprocessed prepared.value admitted))

def psKernelExprV2NestedTransformedWith
    (check whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (fuel : Nat) (environment : PsKernelEnvironment) (maxRecDepth maxNatSize : Nat)
    (input : PsKernelExprV2Decoded) (owner : PsKernelDagGeneratedState) (value : PsKernelDagInductiveGroup) :
    Option (Except String PsKernelExprV2NestedCheckedTransformed) :=
  match psKernelExprV2NestedPreprocessWith check whnf fuel environment maxRecDepth maxNatSize input owner value with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok plan =>
          match psKernelExprV2NestedPrepareTransformed value plan with
          | Except.error error => Option.some (Except.error error)
          | Except.ok prepared =>
              psKernelExprV2NestedCheckPreparedWith check whnf defeq fuel environment maxRecDepth maxNatSize prepared

def psKernelExprV2NestedTransformedWithFuel
    (fuel : Nat) (environment : PsKernelEnvironment) (maxRecDepth maxNatSize : Nat)
    (input : PsKernelExprV2Decoded) (owner : PsKernelDagGeneratedState) (value : PsKernelDagInductiveGroup) :
    Option (Except String PsKernelExprV2NestedCheckedTransformed) :=
  psKernelExprV2NestedTransformedWith psKernelExprV2TryCheckStateWithFuel
    psKernelExprV2TryWhnfCheckStateWithFuel psKernelExprV2TryDefEqStateWithFuel
    fuel environment maxRecDepth maxNatSize input owner value
