import Ps.KernelCore.API.DagNestedHeader
import Ps.KernelCore.API.DagOrdinaryGenerated

/- Private syntax-only nested discovery/flattening after checked parameters.
   Original terms come from the established boundary table; opened parameter
   IDs are read from its synchronized append-only continuation. The retained
   queue constructs transformed syntax and metadata only and calls no checker.
   Nothing is imported, admitted, restored, validated or published here. The
   next phase must independently check the transformed bundle through owning
   DAG admission and validate every restored type/rule before publication. -/
structure PsKernelExprV2NestedPreprocessed where
  header : PsKernelExprV2NestedHeader
  canonicalParams : List PsKernelOpenBinder
  processed : PsKernelSimpleNestedProcessQueueResult
  owner : PsKernelDagGeneratedState

def psKernelExprV2NestedProcessDecodedParameters
    (fuel : Nat) (environment : PsKernelEnvironment)
    (header : PsKernelExprV2NestedHeader) (owner : PsKernelDagGeneratedState)
    (canonicalParams : List PsKernelOpenBinder) : Except String PsKernelExprV2NestedPreprocessed :=
  let decl := header.original;
  let originalNames := psKernelSimpleMutualNames decl.types;
  let initialState := PsKernelSimpleNestedMapState.mk List.nil 1 List.nil;
  match psKernelSimpleNestedProcessQueue fuel environment decl.levelParams originalNames
      canonicalParams decl.numParams decl.types List.nil initialState with
  | Except.error error =>
      Except.error (String.Internal.append "nested preprocessing: " error)
  | Except.ok processed =>
      Except.ok (PsKernelExprV2NestedPreprocessed.mk header canonicalParams processed owner)

def psKernelExprV2NestedProcessSynchronizedParameters
    (fuel : Nat) (environment : PsKernelEnvironment)
    (header : PsKernelExprV2NestedHeader) (owner : PsKernelDagGeneratedState) :
    Except String PsKernelExprV2NestedPreprocessed :=
  match psKernelExprV2OrdinaryDecodeBinders header.parameters.binders owner.built with
  | Except.error error => Except.error error
  | Except.ok canonicalParams =>
      psKernelExprV2NestedProcessDecodedParameters fuel environment header owner canonicalParams

def psKernelExprV2NestedPreprocessAfterHeader
    (fuel : Nat) (environment : PsKernelEnvironment)
    (built : PsKernelExprV2Decoded) (header : PsKernelExprV2NestedHeader) :
    Except String PsKernelExprV2NestedPreprocessed :=
  match psKernelExprV2OrdinarySynchronizeOwner header.parameters.state built with
  | Except.error error => Except.error error
  | Except.ok owner =>
      psKernelExprV2NestedProcessSynchronizedParameters fuel environment header owner

def psKernelExprV2NestedPreprocessWith
    (check whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (fuel : Nat) (environment : PsKernelEnvironment) (maxRecDepth maxNatSize : Nat)
    (input : PsKernelExprV2Decoded) (owner : PsKernelDagGeneratedState)
    (value : PsKernelDagInductiveGroup) : Option (Except String PsKernelExprV2NestedPreprocessed) :=
  match psKernelExprV2NestedAnalyzeHeaderWith check whnf fuel environment maxRecDepth maxNatSize
      input owner.arena owner.declarations value with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok header =>
          Option.some (psKernelExprV2NestedPreprocessAfterHeader fuel environment owner.built header)

def psKernelExprV2NestedPreprocessWithFuel
    (fuel : Nat) (environment : PsKernelEnvironment) (maxRecDepth maxNatSize : Nat)
    (input : PsKernelExprV2Decoded) (owner : PsKernelDagGeneratedState)
    (value : PsKernelDagInductiveGroup) : Option (Except String PsKernelExprV2NestedPreprocessed) :=
  psKernelExprV2NestedPreprocessWith psKernelExprV2TryCheckStateWithFuel
    psKernelExprV2TryWhnfCheckStateWithFuel fuel environment maxRecDepth maxNatSize input owner value
