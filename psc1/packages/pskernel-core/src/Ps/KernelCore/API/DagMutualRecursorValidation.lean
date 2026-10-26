import Ps.KernelCore.API.DagMutualGenerated

/- Private validation of generated mutual recursors. All generated recursor
   metadata/references are staged together, as in the retained transaction,
   before any type is checked. Staging is syntax construction, not admission.
   Every type uses a fresh checker owner and mandatory public EnsureSort;
   every selected rule uses owning Check and DefEq at unchanged checker fuel.
   Skipped family shapes consume neither a pending rule nor checker fuel.
   No partial environment escapes on error/decline. A successful private
   result still requires the outer public admission/resource boundary. -/
structure PsKernelExprV2MutualRecursorTask where
  info : PsKernelRecursorInfo
  type : Nat
  rules : List PsKernelExprV2RecursorRuleRef

structure PsKernelExprV2MutualStagedRecursors where
  environment : PsKernelEnvironment
  owner : PsKernelDagGeneratedState
  tasks : List PsKernelExprV2MutualRecursorTask

def psKernelExprV2MutualValidateRulesWorker
    (shapes : List PsKernelSimpleMutualConstructorShape) :
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool))) ->
    Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
    PsKernelExprV2Decoded -> PsKernelExprV2MutualRecursorPlan -> Nat ->
    List PsKernelExprV2RecursorRuleRef -> Option (Except String PsKernelExprV2OrdinaryRuleState) :=
  match shapes with
  | List.nil =>
      fun (_check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (_defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Bool)))
        (_fuel : Nat) (_context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
        (built : PsKernelExprV2Decoded) (_plan : PsKernelExprV2MutualRecursorPlan)
        (_owner : Nat) (pending : List PsKernelExprV2RecursorRuleRef) =>
        match pending with
        | List.nil => Option.some (Except.ok (PsKernelExprV2OrdinaryRuleState.mk state built))
        | List.cons _ _ => Option.some (Except.error "mutual recursor rule count mismatch")
  | List.cons shape rest =>
      let smaller := psKernelExprV2MutualValidateRulesWorker rest;
      fun (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Bool)))
        (fuel : Nat) (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
        (built : PsKernelExprV2Decoded) (plan : PsKernelExprV2MutualRecursorPlan)
        (owner : Nat) (pending : List PsKernelExprV2RecursorRuleRef) =>
        if Nat.beq shape.owner owner then
          match pending with
          | List.nil => Option.some (Except.error "mutual recursor rule count mismatch")
          | List.cons rule tail =>
              match check fuel context state rule.rhs with
              | Option.none => Option.none
              | Option.some attemptedCheck =>
                  match attemptedCheck with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok checked =>
                      match psKernelExprV2MutualPrepareExpectedRuleType
                          plan owner shape (Prod.fst checked) built with
                      | Except.error error => Option.some (Except.error error)
                      | Except.ok expected =>
                          match defeq fuel context expected.state (Prod.snd checked) expected.root with
                          | Option.none => Option.none
                          | Option.some attemptedEqual =>
                              match attemptedEqual with
                              | Except.error error => Option.some (Except.error error)
                              | Except.ok equal =>
                                  if Prod.snd equal then
                                    smaller check defeq fuel context (Prod.fst equal)
                                      expected.built plan owner tail
                                  else Option.some (Except.error
                                    "generated mutual recursor rule is not type preserving")
        else smaller check defeq fuel context state built plan owner pending

def psKernelExprV2MutualValidateRulesWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (fuel : Nat) (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (built : PsKernelExprV2Decoded) (plan : PsKernelExprV2MutualRecursorPlan)
    (owner : Nat) (rules : List PsKernelExprV2RecursorRuleRef) :
    Option (Except String PsKernelExprV2OrdinaryRuleState) :=
  let visit := psKernelExprV2MutualValidateRulesWorker plan.data.constructors;
  visit check defeq fuel context state built plan owner rules

def psKernelExprV2MutualStageRecursor
    (environment : PsKernelEnvironment) (owner : PsKernelDagGeneratedState)
    (info : PsKernelRecursorInfo) : Except String PsKernelExprV2MutualStagedRecursors :=
  match psKernelDagGeneratedImport info.base.type owner with
  | Except.error error => Except.error error
  | Except.ok importedType =>
      match psKernelDagGeneratedImportRules info.rules (Prod.fst importedType) with
      | Except.error error => Except.error error
      | Except.ok importedRules =>
          let next := Prod.fst importedRules;
          let rules := Prod.snd importedRules;
          let typeRoot := Prod.snd importedType;
          let reference := PsKernelExprV2DeclarationRef.mk info.base.name
            info.base.levelParams typeRoot Option.none
            (PsKernelExprV2DeclarationRefKind.recursorDecl rules);
          let work := psKernelEnvironmentAddUnchecked environment (PsKernelConstantInfo.recInfo info);
          Except.ok (PsKernelExprV2MutualStagedRecursors.mk work
            (PsKernelDagGeneratedState.mk next.arena next.built (List.cons reference next.declarations))
            (List.cons (PsKernelExprV2MutualRecursorTask.mk info typeRoot rules) List.nil))

def psKernelExprV2MutualRecursorTasksAppend
    (left : List PsKernelExprV2MutualRecursorTask) :
    List PsKernelExprV2MutualRecursorTask -> List PsKernelExprV2MutualRecursorTask :=
  match left with
  | List.nil => fun (right : List PsKernelExprV2MutualRecursorTask) => right
  | List.cons first rest =>
      let smaller := psKernelExprV2MutualRecursorTasksAppend rest;
      fun (right : List PsKernelExprV2MutualRecursorTask) => List.cons first (smaller right)

def psKernelExprV2MutualStageRecursorsWorker
    (infos : List PsKernelRecursorInfo) : PsKernelEnvironment -> PsKernelDagGeneratedState ->
    Except String PsKernelExprV2MutualStagedRecursors :=
  match infos with
  | List.nil => fun (environment : PsKernelEnvironment) (owner : PsKernelDagGeneratedState) =>
      Except.ok (PsKernelExprV2MutualStagedRecursors.mk environment owner List.nil)
  | List.cons first rest =>
      let smaller := psKernelExprV2MutualStageRecursorsWorker rest;
      fun (environment : PsKernelEnvironment) (owner : PsKernelDagGeneratedState) =>
        match psKernelExprV2MutualStageRecursor environment owner first with
        | Except.error error => Except.error error
        | Except.ok staged =>
            match smaller staged.environment staged.owner with
            | Except.error error => Except.error error
            | Except.ok tail => Except.ok (PsKernelExprV2MutualStagedRecursors.mk
                tail.environment tail.owner
                (psKernelExprV2MutualRecursorTasksAppend staged.tasks tail.tasks))

/- Only the checked child's arena/decoded continuation crosses the fresh
   recursor boundary. Original staged references remain authoritative. -/
def psKernelExprV2MutualResumeRecursorOwner
    (references : List PsKernelExprV2DeclarationRef) (checked : PsKernelExprV2OrdinaryRuleState) :
    Except String PsKernelDagGeneratedState :=
  match psKernelExprV2OrdinaryExtendDecoded checked.state.whnf.arena checked.built with
  | Except.error error => Except.error error
  | Except.ok built => Except.ok
      (PsKernelDagGeneratedState.mk checked.state.whnf.arena built references)

def psKernelExprV2MutualCheckRecursorTasksWorker
    (tasks : List PsKernelExprV2MutualRecursorTask) :
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool))) ->
    Nat -> PsKernelEnvironment -> Nat -> Nat -> Bool -> PsKernelExprV2MutualRecursorPlan ->
    PsKernelDagGeneratedState -> Nat -> Option (Except String PsKernelDagGeneratedState) :=
  match tasks with
  | List.nil =>
      fun (_check _whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (_defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Bool)))
        (_fuel : Nat) (_environment : PsKernelEnvironment) (_maxRecDepth _maxNatSize : Nat)
        (_isUnsafe : Bool) (_plan : PsKernelExprV2MutualRecursorPlan)
        (owner : PsKernelDagGeneratedState) (_index : Nat) => Option.some (Except.ok owner)
  | List.cons task rest =>
      let smaller := psKernelExprV2MutualCheckRecursorTasksWorker rest;
      fun (check whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Bool)))
        (fuel : Nat) (environment : PsKernelEnvironment) (maxRecDepth maxNatSize : Nat)
        (isUnsafe : Bool) (plan : PsKernelExprV2MutualRecursorPlan)
        (owner : PsKernelDagGeneratedState) (index : Nat) =>
        let context := psKernelExprV2OrdinaryFreshContext environment plan.recLevelParams
          isUnsafe maxRecDepth maxNatSize;
        let state := psKernelExprV2OrdinaryFreshState owner;
        match check fuel context state task.type with
        | Option.none => Option.none
        | Option.some attempted =>
            match attempted with
            | Except.error error => Option.some (Except.error error)
            | Except.ok checked =>
                match psKernelExprV2AdmissionEnsureSortOwnedWith
                    (whnf fuel) context (Prod.fst checked) (Prod.snd checked) with
                | Option.none => Option.none
                | Option.some attemptedSort =>
                    match attemptedSort with
                    | Except.error error => Option.some (Except.error error)
                    | Except.ok sorted =>
                        match psKernelExprV2MutualValidateRulesWith check defeq fuel context
                            (Prod.fst sorted) owner.built plan index task.rules with
                        | Option.none => Option.none
                        | Option.some attemptedRules =>
                            match attemptedRules with
                            | Except.error error => Option.some (Except.error error)
                            | Except.ok checkedRules =>
                                match psKernelExprV2MutualResumeRecursorOwner owner.declarations checkedRules with
                                | Except.error error => Option.some (Except.error error)
                                | Except.ok next => smaller check whnf defeq fuel environment
                                    maxRecDepth maxNatSize isUnsafe plan next (Nat.succ index)

def psKernelExprV2MutualCheckRecursorsWith
    (check whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (fuel : Nat) (environment : PsKernelEnvironment) (maxRecDepth maxNatSize : Nat)
    (isUnsafe : Bool) (owner : PsKernelDagGeneratedState) (plan : PsKernelExprV2MutualRecursorPlan) :
    Option (Except String PsKernelExprV2OrdinaryAdmissionResult) :=
  let stage := psKernelExprV2MutualStageRecursorsWorker plan.infos;
  match stage environment owner with
  | Except.error error => Option.some (Except.error error)
  | Except.ok staged =>
      let visit := psKernelExprV2MutualCheckRecursorTasksWorker staged.tasks;
      match visit check whnf defeq fuel staged.environment maxRecDepth maxNatSize isUnsafe plan staged.owner 0 with
      | Option.none => Option.none
      | Option.some attempted =>
          match attempted with
          | Except.error error => Option.some (Except.error error)
          | Except.ok checked => Option.some
              (Except.ok (PsKernelExprV2OrdinaryAdmissionResult.mk staged.environment checked))

def psKernelExprV2MutualCheckRecursorsWithFuel
    (fuel : Nat) (environment : PsKernelEnvironment) (maxRecDepth maxNatSize : Nat)
    (isUnsafe : Bool) (owner : PsKernelDagGeneratedState) (plan : PsKernelExprV2MutualRecursorPlan) :
    Option (Except String PsKernelExprV2OrdinaryAdmissionResult) :=
  psKernelExprV2MutualCheckRecursorsWith psKernelExprV2TryCheckStateWithFuel
    psKernelExprV2TryWhnfCheckStateWithFuel psKernelExprV2TryDefEqStateWithFuel
    fuel environment maxRecDepth maxNatSize isUnsafe owner plan
