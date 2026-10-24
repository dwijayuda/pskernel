import Ps.KernelCore.API.DagOrdinaryConstructorTypes
import Ps.KernelCore.API.DagOrdinaryConstructorResult
import Ps.KernelCore.API.DagOrdinaryParameters

/-
Private ordinary recursive-argument analysis over a canonical owning arena.
Only this recursive-argument phase normalizes the candidate type. Constructor
field opening retains its syntactic telescope. Every callback returns the
complete next owner; temporary locals are restored by the field caller.
-/

/- Preserve original-before-reduced occurrence order and short circuiting. -/
def psKernelExprV2OrdinaryAnyRecursiveOccurrence
    (arena : PsKernelExprV2PagedArena) (target : PsKernelName)
    (original reduced : Nat) : Except String Bool :=
  match psKernelExprV2OrdinaryContainsConstOnCanonical arena target original with
  | Except.error error => Except.error error
  | Except.ok found =>
      if found then Except.ok true
      else psKernelExprV2OrdinaryContainsConstOnCanonical arena target reduced

/- This is the existing narrow safe residual-recursor rejection. Unsafe
   declarations retain the original unsupported boundary. Only the reduced
   type and the current environment decide whether its head is a recursor. -/
def psKernelExprV2OrdinaryInvalidRecursorOccurrence
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (target : PsKernelName) (reduced : Nat) : Except String Bool :=
  if psKernelDefinitionSafetyIsUnsafe context.scalar.safety then
    Except.ok false
  else
    match psKernelExprV2OrdinaryContainsConstOnCanonical
        state.whnf.arena target reduced with
    | Except.error error => Except.error error
    | Except.ok found =>
        if found then
          match psKernelExprV2TransformAppSpineOnCanonical
              state.whnf.arena reduced with
          | Except.error error => Except.error error
          | Except.ok spine =>
              match psKernelExprV2PagedRequire state.whnf.arena (Prod.fst spine) with
              | Except.error error => Except.error error
              | Except.ok entry =>
                  match entry.node with
                  | PsKernelExprV2Node.const name _ =>
                      match psKernelEnvironmentFind context.scalar.environment name with
                      | Option.none => Except.ok false
                      | Option.some info =>
                          match info with
                          | PsKernelConstantInfo.recInfo _ => Except.ok true
                          | _ => Except.ok false
                  | _ => Except.ok false
        else
          Except.ok false

def psKernelExprV2OrdinaryRecursiveArgumentTerminal
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (target : PsKernelName) (original reduced : Nat) :
    Except String PsKernelExprV2OrdinaryRecursiveArgumentResult :=
  match psKernelExprV2OrdinaryAnyRecursiveOccurrence
      state.whnf.arena target original reduced with
  | Except.error error => Except.error error
  | Except.ok found =>
      if found then
        match psKernelExprV2OrdinaryInvalidRecursorOccurrence
            context state target reduced with
        | Except.error error => Except.error error
        | Except.ok invalid =>
            if invalid then
              Except.error
                "simple inductive field has an invalid recursor-headed recursive occurrence"
            else
              Except.error
                "simple inductive admission does not yet support nested recursive occurrences"
      else
        Except.ok
          (PsKernelExprV2OrdinaryRecursiveArgumentResult.mk context state Option.none)

def psKernelExprV2OrdinaryRecursiveArgumentSelected
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (target : PsKernelName)
    (revArgs : List PsKernelExprV2OrdinaryOpenBinder) (indices : List Nat) :
    Except String PsKernelExprV2OrdinaryRecursiveArgumentResult :=
  match psKernelExprV2OrdinaryIndicesContainTarget state.whnf.arena target indices with
  | Except.error error => Except.error error
  | Except.ok found =>
      if found then
        Except.error "recursive argument index contains a recursive occurrence"
      else
        Except.ok
          (PsKernelExprV2OrdinaryRecursiveArgumentResult.mk context state
            (Option.some
              (Prod.mk (psKernelExprV2OrdinaryReverseOpenBinders revArgs) indices)))

def psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker
    (fuel : Nat) :
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
    PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
    PsKernelName -> List PsKernelLevel ->
    List PsKernelExprV2OrdinaryOpenBinder -> Nat -> Nat ->
    List PsKernelExprV2OrdinaryOpenBinder ->
    Option (Except String PsKernelExprV2OrdinaryRecursiveArgumentResult) :=
  match fuel with
  | Nat.zero =>
      fun
        (_check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (_whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (_context : PsKernelExprV2CheckContext) (_state : PsKernelExprV2CheckState)
        (_target : PsKernelName) (_levels : List PsKernelLevel)
        (_parameters : List PsKernelExprV2OrdinaryOpenBinder)
        (_numIndices _type : Nat)
        (_revArgs : List PsKernelExprV2OrdinaryOpenBinder) =>
        Option.some
          (Except.error "simple inductive recursive-argument budget exhausted")
  | Nat.succ remaining =>
      let smaller := psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker remaining;
      fun
        (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
        (target : PsKernelName) (levels : List PsKernelLevel)
        (parameters : List PsKernelExprV2OrdinaryOpenBinder)
        (numIndices type : Nat)
        (revArgs : List PsKernelExprV2OrdinaryOpenBinder) =>
        match whnf remaining context state type with
        | Option.none => Option.none
        | Option.some attempted =>
            match attempted with
            | Except.error error => Option.some (Except.error error)
            | Except.ok reducedResult =>
                let next := Prod.fst reducedResult;
                let reduced := Prod.snd reducedResult;
                match psKernelExprV2OrdinaryInductiveAppIndices
                    next.whnf.arena target levels parameters numIndices reduced with
                | Except.error error => Option.some (Except.error error)
                | Except.ok selected =>
                    match selected with
                    | Option.some indices =>
                        Option.some
                          (psKernelExprV2OrdinaryRecursiveArgumentSelected
                            context next target revArgs indices)
                    | Option.none =>
                        match psKernelExprV2PagedRequire next.whnf.arena reduced with
                        | Except.error error => Option.some (Except.error error)
                        | Except.ok entry =>
                            match entry.node with
                            | PsKernelExprV2Node.forallE userName domain body binderInfo =>
                                match whnf remaining context next domain with
                                | Option.none => Option.none
                                | Option.some attemptedDomain =>
                                    match attemptedDomain with
                                    | Except.error error => Option.some (Except.error error)
                                    | Except.ok domainReduced =>
                                        let domainState := Prod.fst domainReduced;
                                        match psKernelExprV2OrdinaryAnyRecursiveOccurrence
                                            domainState.whnf.arena target domain
                                            (Prod.snd domainReduced) with
                                        | Except.error error => Option.some (Except.error error)
                                        | Except.ok negative =>
                                            if negative then
                                              Option.some
                                                (Except.error
                                                  "recursive function argument contains a negative recursive occurrence")
                                            else
                                              match psKernelExprV2OrdinaryOpenHeaderBinderWith
                                                  check whnf remaining context domainState
                                                  userName domain body binderInfo with
                                              | Option.none => Option.none
                                              | Option.some attemptedBinder =>
                                                  match attemptedBinder with
                                                  | Except.error error => Option.some (Except.error error)
                                                  | Except.ok step =>
                                                      let opened := Prod.fst step;
                                                      smaller check whnf opened.context opened.parent
                                                        target levels parameters numIndices opened.body
                                                        (List.cons (Prod.snd step) revArgs)
                            | _ =>
                                Option.some
                                  (psKernelExprV2OrdinaryRecursiveArgumentTerminal
                                    context next target type reduced)

def psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (target : PsKernelName)
    (levels : List PsKernelLevel)
    (parameters : List PsKernelExprV2OrdinaryOpenBinder) (numIndices type : Nat) :
    Option (Except String PsKernelExprV2OrdinaryRecursiveArgumentResult) :=
  psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker (Nat.succ fuel)
    check whnf context state target levels parameters numIndices type List.nil

def psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWithFuel
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (target : PsKernelName)
    (levels : List PsKernelLevel)
    (parameters : List PsKernelExprV2OrdinaryOpenBinder) (numIndices type : Nat) :
    Option (Except String PsKernelExprV2OrdinaryRecursiveArgumentResult) :=
  let check :=
    fun (nextFuel : Nat) (nextContext : PsKernelExprV2CheckContext)
        (nextState : PsKernelExprV2CheckState) (nextRoot : Nat) =>
      psKernelExprV2TryCheckStateWithFuel nextFuel nextContext nextState nextRoot;
  let whnf :=
    fun (nextFuel : Nat) (nextContext : PsKernelExprV2CheckContext)
        (nextState : PsKernelExprV2CheckState) (nextRoot : Nat) =>
      psKernelExprV2TryWhnfCheckStateWithFuel nextFuel nextContext nextState nextRoot;
  psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWith
    check whnf fuel context state target levels parameters numIndices type
