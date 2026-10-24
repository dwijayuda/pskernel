import Ps.KernelCore.API.DagOrdinaryConstructorLoop

/- Equations for the private constructor loop and its owner transition.
   The callback equations hold algebraically for the supplied callbacks; they
   do not establish that an arbitrary callback performs kernel checking.

   The production caller must supply a decoded snapshot obtained by checking
   the original boundary arena, containing every original constructor root,
   and preserve that arena as an unchanged prefix of every later owner.
   The installation equations expose exactly which snapshot root is read and
   which root enters the constructor reference. They do not turn a mismatched
   or unvalidated snapshot into a guarantee for untrusted external input.

   A failed or declined tail yields no successful loop result. This pure
   private helper does not publish an environment or establish the complete
   inductive/recursor admission transaction. -/

namespace PsKernelExprV2OrdinaryConstructorLoopProofs

abbrev AnalyzeCallback :=
  Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
  PsKernelName -> List PsKernelLevel ->
  List PsKernelExprV2OrdinaryOpenBinder -> Nat -> PsKernelLevel ->
  PsKernelDagConstructor ->
  Option (Except String PsKernelExprV2OrdinaryConstructorAnalysis)

variable
  (analyze : AnalyzeCallback)
  (built : PsKernelExprV2Decoded)
  (target : PsKernelName) (numParams : Nat) (isUnsafe : Bool)
  (levels : List PsKernelLevel)
  (parameters : List PsKernelExprV2OrdinaryOpenBinder)
  (numIndices : Nat) (resultLevel : PsKernelLevel)
  (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
  (index : Nat)

theorem zero
    (ctors : List PsKernelDagConstructor) :
    psKernelExprV2OrdinaryAddConstructorsWorker 0 analyze built target
      numParams isUnsafe levels parameters numIndices resultLevel
      context state index ctors =
    Option.some (Except.error "simple inductive constructor admission budget exhausted") := by
  rfl

theorem successor_nil
    (remaining : Nat) :
    psKernelExprV2OrdinaryAddConstructorsWorker (Nat.succ remaining)
      analyze built target numParams isUnsafe levels parameters numIndices resultLevel
      context state index List.nil =
    Option.some (Except.ok
      (PsKernelExprV2OrdinaryConstructorsResult.mk context state List.nil)) := by
  rfl

/- Exposes the exact predecessor fuel and evaluation order: analysis, then
   metadata installation, then tail analysis, then source-order shape output. -/
theorem successor_cons_equation
    (remaining : Nat) (ctor : PsKernelDagConstructor)
    (rest : List PsKernelDagConstructor) :
    psKernelExprV2OrdinaryAddConstructorsWorker (Nat.succ remaining)
      analyze built target numParams isUnsafe levels parameters numIndices resultLevel
      context state index (List.cons ctor rest) =
    (match analyze remaining context state target levels parameters
        numIndices resultLevel ctor with
    | Option.none => Option.none
    | Option.some attempted =>
        match attempted with
        | Except.error error => Option.some (Except.error error)
        | Except.ok analyzed =>
            match psKernelExprV2OrdinaryInstallConstructor
                built target numParams isUnsafe index context state ctor analyzed with
            | Except.error error => Option.some (Except.error error)
            | Except.ok installed =>
                match psKernelExprV2OrdinaryAddConstructorsWorker remaining
                    analyze built target numParams isUnsafe levels parameters
                    numIndices resultLevel (Prod.fst installed) (Prod.snd installed)
                    (Nat.succ index) rest with
                | Option.none => Option.none
                | Option.some attemptedTail =>
                    match attemptedTail with
                    | Except.error error => Option.some (Except.error error)
                    | Except.ok tail =>
                        Option.some
                          (Except.ok
                            (PsKernelExprV2OrdinaryConstructorsResult.mk
                              tail.context tail.state
                              (List.cons analyzed.shape tail.shapes)))) := by
  rfl

theorem analysis_decline
    (remaining : Nat) (ctor : PsKernelDagConstructor)
    (rest : List PsKernelDagConstructor)
    (h : analyze remaining context state target levels parameters
      numIndices resultLevel ctor = Option.none) :
    psKernelExprV2OrdinaryAddConstructorsWorker (Nat.succ remaining)
      analyze built target numParams isUnsafe levels parameters numIndices resultLevel
      context state index (List.cons ctor rest) = Option.none := by
  simp only [successor_cons_equation, h]

theorem analysis_error
    (remaining : Nat) (ctor : PsKernelDagConstructor)
    (rest : List PsKernelDagConstructor) (message : String)
    (h : analyze remaining context state target levels parameters
      numIndices resultLevel ctor = Option.some (Except.error message)) :
    psKernelExprV2OrdinaryAddConstructorsWorker (Nat.succ remaining)
      analyze built target numParams isUnsafe levels parameters numIndices resultLevel
      context state index (List.cons ctor rest) =
    Option.some (Except.error message) := by
  simp only [successor_cons_equation, h]

theorem installation_error
    (remaining : Nat) (ctor : PsKernelDagConstructor)
    (rest : List PsKernelDagConstructor)
    (analyzed : PsKernelExprV2OrdinaryConstructorAnalysis) (message : String)
    (ha : analyze remaining context state target levels parameters
      numIndices resultLevel ctor = Option.some (Except.ok analyzed))
    (hi : psKernelExprV2OrdinaryInstallConstructor
      built target numParams isUnsafe index context state ctor analyzed =
        Except.error message) :
    psKernelExprV2OrdinaryAddConstructorsWorker (Nat.succ remaining)
      analyze built target numParams isUnsafe levels parameters numIndices resultLevel
      context state index (List.cons ctor rest) =
    Option.some (Except.error message) := by
  simp only [successor_cons_equation, ha, hi]

theorem tail_decline
    (remaining : Nat) (ctor : PsKernelDagConstructor)
    (rest : List PsKernelDagConstructor)
    (analyzed : PsKernelExprV2OrdinaryConstructorAnalysis)
    (nextContext : PsKernelExprV2CheckContext) (nextState : PsKernelExprV2CheckState)
    (ha : analyze remaining context state target levels parameters
      numIndices resultLevel ctor = Option.some (Except.ok analyzed))
    (hi : psKernelExprV2OrdinaryInstallConstructor
      built target numParams isUnsafe index context state ctor analyzed =
        Except.ok (Prod.mk nextContext nextState))
    (ht : psKernelExprV2OrdinaryAddConstructorsWorker remaining
      analyze built target numParams isUnsafe levels parameters numIndices resultLevel
      nextContext nextState (Nat.succ index) rest = Option.none) :
    psKernelExprV2OrdinaryAddConstructorsWorker (Nat.succ remaining)
      analyze built target numParams isUnsafe levels parameters numIndices resultLevel
      context state index (List.cons ctor rest) = Option.none := by
  simp only [successor_cons_equation, ha, hi, ht]

theorem tail_error
    (remaining : Nat) (ctor : PsKernelDagConstructor)
    (rest : List PsKernelDagConstructor)
    (analyzed : PsKernelExprV2OrdinaryConstructorAnalysis)
    (nextContext : PsKernelExprV2CheckContext) (nextState : PsKernelExprV2CheckState)
    (message : String)
    (ha : analyze remaining context state target levels parameters
      numIndices resultLevel ctor = Option.some (Except.ok analyzed))
    (hi : psKernelExprV2OrdinaryInstallConstructor
      built target numParams isUnsafe index context state ctor analyzed =
        Except.ok (Prod.mk nextContext nextState))
    (ht : psKernelExprV2OrdinaryAddConstructorsWorker remaining
      analyze built target numParams isUnsafe levels parameters numIndices resultLevel
      nextContext nextState (Nat.succ index) rest = Option.some (Except.error message)) :
    psKernelExprV2OrdinaryAddConstructorsWorker (Nat.succ remaining)
      analyze built target numParams isUnsafe levels parameters numIndices resultLevel
      context state index (List.cons ctor rest) =
    Option.some (Except.error message) := by
  simp only [successor_cons_equation, ha, hi, ht]

theorem tail_success_order
    (remaining : Nat) (ctor : PsKernelDagConstructor)
    (rest : List PsKernelDagConstructor)
    (analyzed : PsKernelExprV2OrdinaryConstructorAnalysis)
    (nextContext : PsKernelExprV2CheckContext) (nextState : PsKernelExprV2CheckState)
    (tail : PsKernelExprV2OrdinaryConstructorsResult)
    (ha : analyze remaining context state target levels parameters
      numIndices resultLevel ctor = Option.some (Except.ok analyzed))
    (hi : psKernelExprV2OrdinaryInstallConstructor
      built target numParams isUnsafe index context state ctor analyzed =
        Except.ok (Prod.mk nextContext nextState))
    (ht : psKernelExprV2OrdinaryAddConstructorsWorker remaining
      analyze built target numParams isUnsafe levels parameters numIndices resultLevel
      nextContext nextState (Nat.succ index) rest = Option.some (Except.ok tail)) :
    psKernelExprV2OrdinaryAddConstructorsWorker (Nat.succ remaining)
      analyze built target numParams isUnsafe levels parameters numIndices resultLevel
      context state index (List.cons ctor rest) =
    Option.some (Except.ok
      (PsKernelExprV2OrdinaryConstructorsResult.mk
        tail.context tail.state (List.cons analyzed.shape tail.shapes))) := by
  simp only [successor_cons_equation, ha, hi, ht]

/- Raw fuel is checked before the nil list. Even an artificial callback that
   succeeds at phase fuel zero cannot bypass the final outer-loop fuel gate. -/
theorem fuel_one_tail_exhausted
    (ctor : PsKernelDagConstructor)
    (analyzed : PsKernelExprV2OrdinaryConstructorAnalysis)
    (nextContext : PsKernelExprV2CheckContext) (nextState : PsKernelExprV2CheckState)
    (ha : analyze 0 context state target levels parameters
      numIndices resultLevel ctor = Option.some (Except.ok analyzed))
    (hi : psKernelExprV2OrdinaryInstallConstructor
      built target numParams isUnsafe index context state ctor analyzed =
        Except.ok (Prod.mk nextContext nextState)) :
    psKernelExprV2OrdinaryAddConstructorsWorker 1
      analyze built target numParams isUnsafe levels parameters numIndices resultLevel
      context state index (List.cons ctor List.nil) =
    Option.some (Except.error "simple inductive constructor admission budget exhausted") := by
  simp only [successor_cons_equation, ha, hi, zero]

theorem singleton_success
    (remaining : Nat) (ctor : PsKernelDagConstructor)
    (analyzed : PsKernelExprV2OrdinaryConstructorAnalysis)
    (nextContext : PsKernelExprV2CheckContext) (nextState : PsKernelExprV2CheckState)
    (ha : analyze (Nat.succ remaining) context state target levels parameters
      numIndices resultLevel ctor = Option.some (Except.ok analyzed))
    (hi : psKernelExprV2OrdinaryInstallConstructor
      built target numParams isUnsafe index context state ctor analyzed =
        Except.ok (Prod.mk nextContext nextState)) :
    psKernelExprV2OrdinaryAddConstructorsWorker (Nat.succ (Nat.succ remaining))
      analyze built target numParams isUnsafe levels parameters numIndices resultLevel
      context state index (List.cons ctor List.nil) =
    Option.some (Except.ok
      (PsKernelExprV2OrdinaryConstructorsResult.mk
        nextContext nextState (List.cons analyzed.shape List.nil))) := by
  simp only [successor_cons_equation, ha, hi, successor_nil]

theorem install_lookup_error
    (ctor : PsKernelDagConstructor)
    (analyzed : PsKernelExprV2OrdinaryConstructorAnalysis) (message : String)
    (h : psKernelExprV2DecodedRequire built ctor.type = Except.error message) :
    psKernelExprV2OrdinaryInstallConstructor
      built target numParams isUnsafe index context state ctor analyzed =
    Except.error message := by
  simp only [psKernelExprV2OrdinaryInstallConstructor, h]

/- The decoded metadata comes from exactly ctor.type, and the new DAG
   reference retains that same original root. Only the child's arena survives;
   parent locals, freshness and all seven caches are retained exactly. -/
theorem install_owner_and_original_root
    (ctor : PsKernelDagConstructor)
    (analyzed : PsKernelExprV2OrdinaryConstructorAnalysis) (type : PsKernelExpr)
    (h : psKernelExprV2DecodedRequire built ctor.type = Except.ok type) :
    psKernelExprV2OrdinaryInstallConstructor
      built target numParams isUnsafe index context state ctor analyzed =
    let info := PsKernelConstructorInfo.mk
      (PsKernelConstantBase.mk ctor.name context.scalar.levelParams type)
      target index numParams
      (psKernelExprV2OrdinaryOpenBinderCount analyzed.shape.fields) isUnsafe;
    let work := psKernelEnvironmentAddUnchecked context.scalar.environment
      (PsKernelConstantInfo.ctorInfo info);
    let reference := PsKernelExprV2DeclarationRef.mk
      ctor.name context.scalar.levelParams ctor.type Option.none
      PsKernelExprV2DeclarationRefKind.constructorDecl;
    Except.ok
      (Prod.mk
        (PsKernelExprV2CheckContext.mk
          (psKernelCheckerContextWithEnvironment context.scalar work) context.locals)
        (psKernelExprV2CheckStateWithWhnf state
          (PsKernelExprV2WhnfState.mk
            analyzed.state.whnf.arena state.whnf.coreCache state.whnf.publicCache
            (List.cons reference state.whnf.declarations)))) := by
  simp only [psKernelExprV2OrdinaryInstallConstructor, h]

theorem binder_count_length
    (fields : List PsKernelExprV2OrdinaryOpenBinder) :
    psKernelExprV2OrdinaryOpenBinderCount fields = fields.length := by
  induction fields with
  | nil => rfl
  | cons field rest ih =>
      exact congrArg Nat.succ ih

end PsKernelExprV2OrdinaryConstructorLoopProofs

#print axioms PsKernelExprV2OrdinaryConstructorLoopProofs.zero
#print axioms PsKernelExprV2OrdinaryConstructorLoopProofs.successor_nil
#print axioms PsKernelExprV2OrdinaryConstructorLoopProofs.successor_cons_equation
#print axioms PsKernelExprV2OrdinaryConstructorLoopProofs.analysis_decline
#print axioms PsKernelExprV2OrdinaryConstructorLoopProofs.analysis_error
#print axioms PsKernelExprV2OrdinaryConstructorLoopProofs.installation_error
#print axioms PsKernelExprV2OrdinaryConstructorLoopProofs.tail_decline
#print axioms PsKernelExprV2OrdinaryConstructorLoopProofs.tail_error
#print axioms PsKernelExprV2OrdinaryConstructorLoopProofs.tail_success_order
#print axioms PsKernelExprV2OrdinaryConstructorLoopProofs.fuel_one_tail_exhausted
#print axioms PsKernelExprV2OrdinaryConstructorLoopProofs.singleton_success
#print axioms PsKernelExprV2OrdinaryConstructorLoopProofs.install_lookup_error
#print axioms PsKernelExprV2OrdinaryConstructorLoopProofs.install_owner_and_original_root
#print axioms PsKernelExprV2OrdinaryConstructorLoopProofs.binder_count_length
