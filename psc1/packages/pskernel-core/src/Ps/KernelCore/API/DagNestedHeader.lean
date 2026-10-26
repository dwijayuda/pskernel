import Ps.KernelCore.API.DagMutualHeader
import Ps.KernelCore.API.DagDeclaration
import Ps.KernelCore.Admission.Inductive.Nested.Admission

/- Private initial nested-inductive phase only. The caller establishes the
   canonical arena and the original validated boundary-table correspondence.
   Boundary terms supply reserved-name/uniform-occurrence metadata only.
   Checking, mandatory public EnsureSort, and parameter opening use owning DAG
   callbacks at the unchanged entry fuel. In particular, this phase performs
   neither a static precheck nor index opening nor a final-result sort check:
   the retained original nested transaction does those only in later phases.
   No environment is installed and no public admission route changes here. -/
structure PsKernelExprV2NestedHeader where
  original : PsKernelSimpleMutualInductiveDecl
  parameters : PsKernelExprV2OrdinaryOpenResult

def psKernelExprV2NestedInitialPhasesWith
    (check whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (type numParams : Nat) :
    Option (Except String PsKernelExprV2OrdinaryOpenResult) :=
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
                  psKernelExprV2OrdinaryOpenHeaderParamsWith check whnf fuel context
                    (Prod.fst sorted) type numParams

def psKernelExprV2NestedHeaderGuards
    (decl : PsKernelSimpleMutualInductiveDecl) : Except String Unit :=
  match psKernelSimpleNestedCheckReserved decl with
  | Except.error error => Except.error error
  | Except.ok _ =>
      psKernelSimpleCheckUniformOccurrences (psKernelSimpleMutualNames decl.types)
        decl.levelParams decl.numParams (psKernelSimpleMutualCtorTypes decl.types)

def psKernelExprV2NestedHeaderAfterDecodeWith
    (check whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (fuel : Nat) (environment : PsKernelEnvironment) (maxRecDepth maxNatSize : Nat)
    (arena : PsKernelExprV2PagedArena) (declarations : List PsKernelExprV2DeclarationRef)
    (decl : PsKernelSimpleMutualInductiveDecl) (value : PsKernelDagInductiveGroup) :
    Option (Except String PsKernelExprV2NestedHeader) :=
  match psKernelExprV2NestedHeaderGuards decl with
  | Except.error error => Option.some (Except.error error)
  | Except.ok _ =>
      match value.types with
      | List.nil => Option.some (Except.error "empty nested inductive declaration")
      | List.cons first _ =>
          let context := psKernelExprV2MutualClosedContext environment value maxRecDepth maxNatSize;
          let state := psKernelExprV2MutualClosedState arena declarations;
          match psKernelExprV2NestedInitialPhasesWith check whnf fuel context state first.type value.numParams with
          | Option.none => Option.none
          | Option.some attempted =>
              match attempted with
              | Except.error error => Option.some (Except.error error)
              | Except.ok parameters =>
                  Option.some (Except.ok (PsKernelExprV2NestedHeader.mk decl parameters))

def psKernelExprV2NestedAnalyzeHeaderWith
    (check whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (fuel : Nat) (environment : PsKernelEnvironment) (maxRecDepth maxNatSize : Nat)
    (input : PsKernelExprV2Decoded) (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef) (value : PsKernelDagInductiveGroup) :
    Option (Except String PsKernelExprV2NestedHeader) :=
  match psKernelDagDecodeGroup input value with
  | Except.error error => Option.some (Except.error error)
  | Except.ok decl =>
      psKernelExprV2NestedHeaderAfterDecodeWith check whnf fuel environment maxRecDepth maxNatSize
        arena declarations decl value

def psKernelExprV2NestedAnalyzeHeaderWithFuel
    (fuel : Nat) (environment : PsKernelEnvironment) (maxRecDepth maxNatSize : Nat)
    (input : PsKernelExprV2Decoded) (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef) (value : PsKernelDagInductiveGroup) :
    Option (Except String PsKernelExprV2NestedHeader) :=
  psKernelExprV2NestedAnalyzeHeaderWith psKernelExprV2TryCheckStateWithFuel
    psKernelExprV2TryWhnfCheckStateWithFuel fuel environment maxRecDepth maxNatSize
    input arena declarations value
