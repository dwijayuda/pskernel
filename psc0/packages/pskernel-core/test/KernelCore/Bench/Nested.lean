import KernelCore.Bench.Inductive

-- Untimed cache-pressure diagnostics for the fully checked generated rules.
-- Observe the returned state without instrumenting or changing the checker.
def psKernelBenchMapEntries (cache : PsKernelExprMap) : List (Prod PsKernelExpr PsKernelExpr) :=
  let rec entries : PsKernelExprMapIndex → List (Prod PsKernelExpr PsKernelExpr)
    | .empty => []
    | .bucket values => values
    | .branch left right => entries left ++ entries right
  match cache.index with
  | .none => cache.small
  | .some index => entries index

def psKernelBenchProfileRecursorCache
    (label : String) (environment : PsKernelEnvironment) (name : PsKernelName) : IO Unit := do
  let some (.recInfo info) := psKernelEnvironmentFind environment name
    | throw (IO.userError ("profile recursor missing: " ++ label))
  let session := psKernelMkCheckerSession environment info.base.levelParams
    PsKernelDefinitionSafety.safe 0 psKernelLeanNatMaxSizeDefault
  let .ok checked := psKernelSimpleNestedValidateRulesWorker info.rules 65536 session
    | throw (IO.userError ("profile rule validation failed: " ++ label))
  let entries := psKernelBenchMapEntries checked.state.checkedInfer
  let fvars := entries.countP (fun entry => match entry.fst with | .fvar _ => true | _ => false)
  let sorts := entries.countP (fun entry => match entry.fst with | .sort _ => true | _ => false)
  let constants := entries.countP (fun entry => match entry.fst with | .const _ _ => true | _ => false)
  IO.println s!"PSKERNEL_PROFILE {label} entries={entries.length} fvars={fvars} sorts={sorts} constants={constants}"

def psKernelBenchNestedProcess
    (environment : PsKernelEnvironment) :
    Except String PsKernelSimpleNestedProcessQueueResult :=
  psKernelSimpleNestedProcessQueue
    65536
    environment
    psKernelBenchNestedDecl.levelParams
    (psKernelSimpleMutualNames
      psKernelBenchNestedDecl.types)
    List.nil
    psKernelBenchNestedDecl.numParams
    psKernelBenchNestedDecl.types
    List.nil
    (PsKernelSimpleNestedMapState.mk
      List.nil
      1
      List.nil)

def psKernelBenchNestedTransform
    (environment : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    Except String PsKernelEnvironment :=
  psKernelAddSimpleMutualInductive
    65536
    environment
    (PsKernelSimpleMutualInductiveDecl.mk
      psKernelBenchNestedDecl.levelParams
      psKernelBenchNestedDecl.numParams
      processed.types
      psKernelBenchNestedDecl.isUnsafe)
    0
    psKernelLeanNatMaxSizeDefault

def psKernelBenchNestedRenames
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    List (Prod PsKernelName PsKernelName) :=
  psKernelSimpleNestedMakeRenames
    psKernelBenchNestedTreeRecName
    processed.state.aux

def psKernelBenchNestedRestore
    (base : PsKernelEnvironment)
    (transformed : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    Except String PsKernelEnvironment :=
  let renames :=
    psKernelBenchNestedRenames processed;
  match
      psKernelSimpleNestedAddOriginals
        transformed
        base
        psKernelBenchNestedDecl
        List.nil
        processed.state.aux
        renames with
  | Except.error error =>
      Except.error error
  | Except.ok restoredOriginals =>
      psKernelSimpleNestedAddAuxRecursors
        transformed
        restoredOriginals
        (psKernelSimpleMutualNames
          psKernelBenchNestedDecl.types)
        List.nil
        psKernelBenchNestedDecl.numParams
        processed.state.aux
        renames

def psKernelBenchNestedValidate
    (transformed : PsKernelEnvironment)
    (finalEnvironment : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    Except String Unit :=
  psKernelSimpleNestedValidateRestored
    65536
    transformed
    finalEnvironment
    psKernelBenchNestedDecl
    List.nil
    processed.state.aux
    (psKernelBenchNestedRenames processed)
    0
    psKernelLeanNatMaxSizeDefault


def psKernelBenchNestedValidateTemplates
    (finalEnvironment : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    Except String Unit :=
  psKernelSimpleNestedValidateTemplates
    65536
    finalEnvironment
    psKernelBenchNestedDecl.levelParams
    PsKernelDefinitionSafety.safe
    List.nil
    0
    psKernelLeanNatMaxSizeDefault
    processed.state.aux

def psKernelBenchNestedValidateOriginals
    (finalEnvironment : PsKernelEnvironment) :
    Except String Unit :=
  psKernelSimpleNestedValidateOriginals
    65536
    finalEnvironment
    psKernelBenchNestedDecl
    PsKernelDefinitionSafety.safe
    0
    psKernelLeanNatMaxSizeDefault
    psKernelBenchNestedDecl.types

def psKernelBenchNestedValidateAux
    (transformed : PsKernelEnvironment)
    (finalEnvironment : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    Except String Unit :=
  psKernelSimpleNestedValidateAux
    65536
    transformed
    finalEnvironment
    psKernelBenchNestedDecl
    PsKernelDefinitionSafety.safe
    List.nil
    0
    psKernelLeanNatMaxSizeDefault
    processed.state.aux
    (psKernelBenchNestedRenames processed)
    processed.state.aux


def psKernelBenchNestedValidateOriginalConstructors
    (finalEnvironment : PsKernelEnvironment) :
    Except String Unit :=
  match
      psKernelEnvironmentFind
        finalEnvironment
        psKernelBenchNestedTreeName with
  | Option.none =>
      Except.error
        "PSKERNEL_BENCH restored nested inductive missing"
  | Option.some value =>
      match value with
      | PsKernelConstantInfo.inductInfo info =>
          psKernelSimpleNestedValidateConstructorTypes
            65536
            finalEnvironment
            psKernelBenchNestedDecl.levelParams
            PsKernelDefinitionSafety.safe
            0
            psKernelLeanNatMaxSizeDefault
            info.ctors
      | _ =>
          Except.error
            "PSKERNEL_BENCH restored nested inductive malformed"

def psKernelBenchNestedValidateOriginalRecursor
    (finalEnvironment : PsKernelEnvironment) :
    Except String Unit :=
  match
      psKernelEnvironmentFind
        finalEnvironment
        psKernelBenchNestedTreeRecName with
  | Option.none =>
      Except.error
        "PSKERNEL_BENCH restored nested recursor missing"
  | Option.some value =>
      match value with
      | PsKernelConstantInfo.recInfo recInfo =>
          let session :=
            psKernelMkCheckerSession
              finalEnvironment
              recInfo.base.levelParams
              PsKernelDefinitionSafety.safe
              0
              psKernelLeanNatMaxSizeDefault;
          match
              psKernelSessionCheck
                65536
                session
                recInfo.base.type with
          | Except.error error =>
              Except.error error
          | Except.ok typeType =>
              match
                  psKernelSessionEnsureSort
                    65536
                    (Prod.snd typeType)
                    (Prod.fst typeType) with
              | Except.error error =>
                  Except.error error
              | Except.ok sorted =>
                  psKernelSimpleNestedValidateRules
                    65536
                    (Prod.snd sorted)
                    recInfo.rules
      | _ =>
          Except.error
            "PSKERNEL_BENCH restored nested recursor malformed"

def psKernelBenchNestedValidateAuxRules
    (transformed : PsKernelEnvironment)
    (finalEnvironment : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    Except String Unit :=
  let renames :=
    psKernelBenchNestedRenames processed;
  match processed.state.aux with
  | List.nil =>
      Except.error
        "PSKERNEL_BENCH nested auxiliary family missing"
  | List.cons family _ =>
      let oldName :=
        psKernelSimpleRecName
          family.auxName;
      match
          psKernelSimpleNestedFindRename
            oldName
            renames with
      | Option.none =>
          Except.error
            "PSKERNEL_BENCH nested auxiliary rename missing"
      | Option.some newName =>
          match
              psKernelEnvironmentFind
                transformed
                oldName with
          | Option.none =>
              Except.error
                "PSKERNEL_BENCH transformed auxiliary recursor missing"
          | Option.some oldValue =>
              match oldValue with
              | PsKernelConstantInfo.recInfo oldInfo =>
                  match
                      psKernelEnvironmentFind
                        finalEnvironment
                        newName with
                  | Option.none =>
                      Except.error
                        "PSKERNEL_BENCH restored auxiliary recursor missing"
                  | Option.some newValue =>
                      match newValue with
                      | PsKernelConstantInfo.recInfo newInfo =>
                          psKernelSimpleNestedCompareValidatedRuleTypes
                            65536
                            transformed
                            finalEnvironment
                            PsKernelDefinitionSafety.safe
                            0
                            psKernelLeanNatMaxSizeDefault
                            processed.state.aux
                            renames
                            List.nil
                            psKernelBenchNestedDecl.numParams
                            oldInfo.base.levelParams
                            newInfo.base.levelParams
                            oldInfo.rules
                            newInfo.rules
                      | _ =>
                          Except.error
                            "PSKERNEL_BENCH restored auxiliary recursor malformed"
              | _ =>
                  Except.error
                    "PSKERNEL_BENCH transformed auxiliary recursor malformed"

def psKernelBenchNestedValidateAuxRecursor
    (finalEnvironment : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    Except String Unit :=
  let renames :=
    psKernelBenchNestedRenames processed;
  match processed.state.aux with
  | List.nil =>
      Except.error
        "PSKERNEL_BENCH nested auxiliary family missing"
  | List.cons family _ =>
      let oldName :=
        psKernelSimpleRecName
          family.auxName;
      match
          psKernelSimpleNestedFindRename
            oldName
            renames with
      | Option.none =>
          Except.error
            "PSKERNEL_BENCH nested auxiliary rename missing"
      | Option.some newName =>
          match
              psKernelEnvironmentFind
                finalEnvironment
                newName with
          | Option.none =>
              Except.error
                "PSKERNEL_BENCH restored auxiliary recursor missing"
          | Option.some value =>
              match value with
              | PsKernelConstantInfo.recInfo recInfo =>
                  let session :=
                    psKernelMkCheckerSession
                      finalEnvironment
                      recInfo.base.levelParams
                      PsKernelDefinitionSafety.safe
                      0
                      psKernelLeanNatMaxSizeDefault;
                  match
                      psKernelSessionCheck
                        65536
                        session
                        recInfo.base.type with
                  | Except.error error =>
                      Except.error error
                  | Except.ok typeType =>
                      match
                          psKernelSessionEnsureSort
                            65536
                            (Prod.snd typeType)
                            (Prod.fst typeType) with
                      | Except.error error =>
                          Except.error error
                      | Except.ok _ =>
                          Except.ok ()
              | _ =>
                  Except.error
                    "PSKERNEL_BENCH restored auxiliary recursor malformed"


def psKernelBenchNestedValidateOriginalRecursorType
    (finalEnvironment : PsKernelEnvironment) :
    Except String Unit :=
  match
      psKernelEnvironmentFind
        finalEnvironment
        psKernelBenchNestedTreeRecName with
  | Option.none =>
      Except.error
        "PSKERNEL_BENCH restored nested recursor missing"
  | Option.some value =>
      match value with
      | PsKernelConstantInfo.recInfo recInfo =>
          let session :=
            psKernelMkCheckerSession
              finalEnvironment
              recInfo.base.levelParams
              PsKernelDefinitionSafety.safe
              0
              psKernelLeanNatMaxSizeDefault;
          match
              psKernelSessionCheck
                65536
                session
                recInfo.base.type with
          | Except.error error =>
              Except.error error
          | Except.ok typeType =>
              match
                  psKernelSessionEnsureSort
                    65536
                    (Prod.snd typeType)
                    (Prod.fst typeType) with
              | Except.error error =>
                  Except.error error
              | Except.ok _ =>
                  Except.ok ()
      | _ =>
          Except.error
            "PSKERNEL_BENCH restored nested recursor malformed"

def psKernelBenchNestedValidateOriginalRules
    (finalEnvironment : PsKernelEnvironment) :
    Except String Unit :=
  match
      psKernelEnvironmentFind
        finalEnvironment
        psKernelBenchNestedTreeRecName with
  | Option.none =>
      Except.error
        "PSKERNEL_BENCH restored nested recursor missing"
  | Option.some value =>
      match value with
      | PsKernelConstantInfo.recInfo recInfo =>
          psKernelSimpleNestedValidateRules
            65536
            (psKernelMkCheckerSession
              finalEnvironment
              recInfo.base.levelParams
              PsKernelDefinitionSafety.safe
              0
              psKernelLeanNatMaxSizeDefault)
            recInfo.rules
      | _ =>
          Except.error
            "PSKERNEL_BENCH restored nested recursor malformed"

def psKernelBenchNestedValidateAuxOldRules
    (transformed : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    Except String Unit :=
  match processed.state.aux with
  | List.nil =>
      Except.error
        "PSKERNEL_BENCH nested auxiliary family missing"
  | List.cons family _ =>
      let oldName :=
        psKernelSimpleRecName
          family.auxName;
      match
          psKernelEnvironmentFind
            transformed
            oldName with
      | Option.none =>
          Except.error
            "PSKERNEL_BENCH transformed auxiliary recursor missing"
      | Option.some value =>
          match value with
          | PsKernelConstantInfo.recInfo recInfo =>
              psKernelSimpleNestedValidateRules
                65536
                (psKernelMkCheckerSession
                  transformed
                  recInfo.base.levelParams
                  PsKernelDefinitionSafety.safe
                  0
                  psKernelLeanNatMaxSizeDefault)
                recInfo.rules
          | _ =>
              Except.error
                "PSKERNEL_BENCH transformed auxiliary recursor malformed"

def psKernelBenchNestedValidateAuxNewRules
    (finalEnvironment : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    Except String Unit :=
  let renames :=
    psKernelBenchNestedRenames processed;
  match processed.state.aux with
  | List.nil =>
      Except.error
        "PSKERNEL_BENCH nested auxiliary family missing"
  | List.cons family _ =>
      let oldName :=
        psKernelSimpleRecName
          family.auxName;
      match
          psKernelSimpleNestedFindRename
            oldName
            renames with
      | Option.none =>
          Except.error
            "PSKERNEL_BENCH nested auxiliary rename missing"
      | Option.some newName =>
          match
              psKernelEnvironmentFind
                finalEnvironment
                newName with
          | Option.none =>
              Except.error
                "PSKERNEL_BENCH restored auxiliary recursor missing"
          | Option.some value =>
              match value with
              | PsKernelConstantInfo.recInfo recInfo =>
                  psKernelSimpleNestedValidateRules
                    65536
                    (psKernelMkCheckerSession
                      finalEnvironment
                      recInfo.base.levelParams
                      PsKernelDefinitionSafety.safe
                      0
                      psKernelLeanNatMaxSizeDefault)
                    recInfo.rules
              | _ =>
                  Except.error
                    "PSKERNEL_BENCH restored auxiliary recursor malformed"

def psKernelBenchNestedInferRules
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (rules : List PsKernelRecursorRule) :
    Except String Unit :=
  match rules with
  | List.nil =>
      Except.ok ()
  | List.cons rule rest =>
      match
          psKernelSessionInfer
            fuel
            session
            rule.rhs with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          psKernelBenchNestedInferRules
            fuel
            session
            rest

def psKernelBenchNestedInferOriginalRules
    (finalEnvironment : PsKernelEnvironment) :
    Except String Unit :=
  match
      psKernelEnvironmentFind
        finalEnvironment
        psKernelBenchNestedTreeRecName with
  | Option.none =>
      Except.error
        "PSKERNEL_BENCH restored nested recursor missing"
  | Option.some value =>
      match value with
      | PsKernelConstantInfo.recInfo recInfo =>
          psKernelBenchNestedInferRules
            65536
            (psKernelMkCheckerSession
              finalEnvironment
              recInfo.base.levelParams
              PsKernelDefinitionSafety.safe
              0
              psKernelLeanNatMaxSizeDefault)
            recInfo.rules
      | _ =>
          Except.error
            "PSKERNEL_BENCH restored nested recursor malformed"

def psKernelBenchNestedInferAuxOldRules
    (transformed : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    Except String Unit :=
  match processed.state.aux with
  | List.nil =>
      Except.error
        "PSKERNEL_BENCH nested auxiliary family missing"
  | List.cons family _ =>
      let oldName :=
        psKernelSimpleRecName
          family.auxName;
      match
          psKernelEnvironmentFind
            transformed
            oldName with
      | Option.none =>
          Except.error
            "PSKERNEL_BENCH transformed auxiliary recursor missing"
      | Option.some value =>
          match value with
          | PsKernelConstantInfo.recInfo recInfo =>
              psKernelBenchNestedInferRules
                65536
                (psKernelMkCheckerSession
                  transformed
                  recInfo.base.levelParams
                  PsKernelDefinitionSafety.safe
                  0
                  psKernelLeanNatMaxSizeDefault)
                recInfo.rules
          | _ =>
              Except.error
                "PSKERNEL_BENCH transformed auxiliary recursor malformed"

def psKernelBenchNestedInferAuxNewRules
    (finalEnvironment : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    Except String Unit :=
  let renames :=
    psKernelBenchNestedRenames processed;
  match processed.state.aux with
  | List.nil =>
      Except.error
        "PSKERNEL_BENCH nested auxiliary family missing"
  | List.cons family _ =>
      let oldName :=
        psKernelSimpleRecName
          family.auxName;
      match
          psKernelSimpleNestedFindRename
            oldName
            renames with
      | Option.none =>
          Except.error
            "PSKERNEL_BENCH nested auxiliary rename missing"
      | Option.some newName =>
          match
              psKernelEnvironmentFind
                finalEnvironment
                newName with
          | Option.none =>
              Except.error
                "PSKERNEL_BENCH restored auxiliary recursor missing"
          | Option.some value =>
              match value with
              | PsKernelConstantInfo.recInfo recInfo =>
                  psKernelBenchNestedInferRules
                    65536
                    (psKernelMkCheckerSession
                      finalEnvironment
                      recInfo.base.levelParams
                      PsKernelDefinitionSafety.safe
                      0
                      psKernelLeanNatMaxSizeDefault)
                    recInfo.rules
              | _ =>
                  Except.error
                    "PSKERNEL_BENCH restored auxiliary recursor malformed"

partial def psKernelBenchNestedAdmissionLoop
    (iterations : Nat)
    (environment : PsKernelEnvironment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedAdmissionLoop
          rest
          environment
      match
          psKernelAddSimpleNestedInductive
            65536
            environment
            psKernelBenchNestedDecl
            0
            psKernelLeanNatMaxSizeDefault with
      | Except.ok next =>
          match
              psKernelEnvironmentFind
                next
                psKernelBenchNestedTreeName with
          | Option.some
              (PsKernelConstantInfo.inductInfo _) =>
              if
                  psKernelEnvironmentContains
                    next
                    psKernelBenchNestedTreeRecName then
                pure (Nat.succ tail)
              else
                pure tail
          | _ =>
              pure tail
      | Except.error _ =>
          pure tail

partial def psKernelBenchLeanNestedAdmissionLoop
    (iterations : Nat)
    (environment : Lean.Environment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchLeanNestedAdmissionLoop
          rest
          environment
      match
          Lean.Kernel.Environment.addDecl
            environment.toKernelEnv
            {}
            psKernelBenchLeanNestedDecl with
      | .ok next =>
          match
              next.find?
                psKernelBenchLeanNestedTreeName,
              next.find?
                psKernelBenchLeanNestedTreeRecName with
          | some (.inductInfo _), some (.recInfo _) =>
              pure (Nat.succ tail)
          | _, _ =>
              pure tail
      | .error _ =>
          pure tail


def psKernelBenchNestedWideProcess
    (environment : PsKernelEnvironment) :
    Except String PsKernelSimpleNestedProcessQueueResult :=
  psKernelSimpleNestedProcessQueue
    65536
    environment
    psKernelBenchNestedWideDecl.levelParams
    (psKernelSimpleMutualNames
      psKernelBenchNestedWideDecl.types)
    List.nil
    psKernelBenchNestedWideDecl.numParams
    psKernelBenchNestedWideDecl.types
    List.nil
    (PsKernelSimpleNestedMapState.mk
      List.nil
      1
      List.nil)

def psKernelBenchNestedWideTransform
    (environment : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    Except String PsKernelEnvironment :=
  psKernelAddSimpleMutualInductive
    65536
    environment
    (PsKernelSimpleMutualInductiveDecl.mk
      psKernelBenchNestedWideDecl.levelParams
      psKernelBenchNestedWideDecl.numParams
      processed.types
      psKernelBenchNestedWideDecl.isUnsafe)
    0
    psKernelLeanNatMaxSizeDefault

def psKernelBenchNestedWideRenames
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    List (Prod PsKernelName PsKernelName) :=
  psKernelSimpleNestedMakeRenames
    psKernelBenchNestedWideRecName
    processed.state.aux

def psKernelBenchNestedWideRestore
    (base : PsKernelEnvironment)
    (transformed : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    Except String PsKernelEnvironment :=
  let renames :=
    psKernelBenchNestedWideRenames processed;
  match
      psKernelSimpleNestedAddOriginals
        transformed
        base
        psKernelBenchNestedWideDecl
        List.nil
        processed.state.aux
        renames with
  | Except.error error =>
      Except.error error
  | Except.ok restoredOriginals =>
      psKernelSimpleNestedAddAuxRecursors
        transformed
        restoredOriginals
        (psKernelSimpleMutualNames
          psKernelBenchNestedWideDecl.types)
        List.nil
        psKernelBenchNestedWideDecl.numParams
        processed.state.aux
        renames


def psKernelBenchNestedWideValidate
    (transformed : PsKernelEnvironment)
    (finalEnvironment : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    Except String Unit :=
  psKernelSimpleNestedValidateRestored
    65536
    transformed
    finalEnvironment
    psKernelBenchNestedWideDecl
    List.nil
    processed.state.aux
    (psKernelBenchNestedWideRenames processed)
    0
    psKernelLeanNatMaxSizeDefault

def psKernelBenchNestedValidateRulesThreadedWorker
    (rules : List PsKernelRecursorRule) :
    Nat ->
    PsKernelCheckerSession ->
    Except String PsKernelCheckerSession :=
  match rules with
  | List.nil =>
      fun
        (_fuel : Nat)
        (session : PsKernelCheckerSession) =>
        Except.ok session
  | List.cons rule rest =>
      let smaller :=
        psKernelBenchNestedValidateRulesThreadedWorker
          rest;
      fun
        (fuel : Nat)
        (session : PsKernelCheckerSession) =>
        match
            psKernelSessionCheck
              fuel
              session
              rule.rhs with
        | Except.error error =>
            Except.error error
        | Except.ok checked =>
            smaller
              fuel
              (Prod.snd checked)

def psKernelBenchNestedWideMainRulesCurrent
    (finalEnvironment : PsKernelEnvironment) :
    Except String Unit :=
  match
      psKernelEnvironmentFind
        finalEnvironment
        psKernelBenchNestedWideRecName with
  | Option.none =>
      Except.error
        "PSKERNEL_BENCH wide main recursor missing"
  | Option.some value =>
      match value with
      | PsKernelConstantInfo.recInfo recInfo =>
          psKernelSimpleNestedValidateRules
            65536
            (psKernelMkCheckerSession
              finalEnvironment
              recInfo.base.levelParams
              PsKernelDefinitionSafety.safe
              0
              psKernelLeanNatMaxSizeDefault)
            recInfo.rules
      | _ =>
          Except.error
            "PSKERNEL_BENCH wide main recursor malformed"

def psKernelBenchNestedWideMainRulesThreaded
    (finalEnvironment : PsKernelEnvironment) :
    Except String Unit :=
  match
      psKernelEnvironmentFind
        finalEnvironment
        psKernelBenchNestedWideRecName with
  | Option.none =>
      Except.error
        "PSKERNEL_BENCH wide main recursor missing"
  | Option.some value =>
      match value with
      | PsKernelConstantInfo.recInfo recInfo =>
          match
              psKernelBenchNestedValidateRulesThreadedWorker
                recInfo.rules
                65536
                (psKernelMkCheckerSession
                  finalEnvironment
                  recInfo.base.levelParams
                  PsKernelDefinitionSafety.safe
                  0
                  psKernelLeanNatMaxSizeDefault) with
          | Except.error error =>
              Except.error error
          | Except.ok _ =>
              Except.ok ()
      | _ =>
          Except.error
            "PSKERNEL_BENCH wide main recursor malformed"

partial def psKernelBenchNestedWideMainRulesCurrentLoop
    (iterations : Nat)
    (finalEnvironment : PsKernelEnvironment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedWideMainRulesCurrentLoop
          rest
          finalEnvironment
      match
          psKernelBenchNestedWideMainRulesCurrent
            finalEnvironment with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchNestedWideMainRulesThreadedLoop
    (iterations : Nat)
    (finalEnvironment : PsKernelEnvironment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedWideMainRulesThreadedLoop
          rest
          finalEnvironment
      match
          psKernelBenchNestedWideMainRulesThreaded
            finalEnvironment with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchNestedWidePreprocessLoop
    (iterations : Nat)
    (environment : PsKernelEnvironment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedWidePreprocessLoop
          rest
          environment
      match psKernelBenchNestedWideProcess environment with
      | Except.ok processed =>
          match processed.state.aux with
          | List.cons _ _ =>
              pure (Nat.succ tail)
          | List.nil =>
              pure tail
      | Except.error _ =>
          pure tail

partial def psKernelBenchNestedWideTransformLoop
    (iterations : Nat)
    (environment : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedWideTransformLoop
          rest
          environment
          processed
      match
          psKernelBenchNestedWideTransform
            environment
            processed with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchNestedWideRestoreLoop
    (iterations : Nat)
    (base : PsKernelEnvironment)
    (transformed : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedWideRestoreLoop
          rest
          base
          transformed
          processed
      match
          psKernelBenchNestedWideRestore
            base
            transformed
            processed with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchNestedWideValidateLoop
    (iterations : Nat)
    (transformed : PsKernelEnvironment)
    (finalEnvironment : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedWideValidateLoop
          rest
          transformed
          finalEnvironment
          processed
      match
          psKernelBenchNestedWideValidate
            transformed
            finalEnvironment
            processed with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchNestedWideValidateTemplatesLoop
    (iterations : Nat)
    (finalEnvironment : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedWideValidateTemplatesLoop
          rest
          finalEnvironment
          processed
      match
          psKernelSimpleNestedValidateTemplates
            65536
            finalEnvironment
            psKernelBenchNestedWideDecl.levelParams
            PsKernelDefinitionSafety.safe
            List.nil
            0
            psKernelLeanNatMaxSizeDefault
            processed.state.aux with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchNestedWideValidateOriginalsLoop
    (iterations : Nat)
    (finalEnvironment : PsKernelEnvironment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedWideValidateOriginalsLoop
          rest
          finalEnvironment
      match
          psKernelSimpleNestedValidateOriginals
            65536
            finalEnvironment
            psKernelBenchNestedWideDecl
            PsKernelDefinitionSafety.safe
            0
            psKernelLeanNatMaxSizeDefault
            psKernelBenchNestedWideDecl.types with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchNestedWideValidateAuxLoop
    (iterations : Nat)
    (transformed : PsKernelEnvironment)
    (finalEnvironment : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedWideValidateAuxLoop
          rest
          transformed
          finalEnvironment
          processed
      match
          psKernelSimpleNestedValidateAux
            65536
            transformed
            finalEnvironment
            psKernelBenchNestedWideDecl
            PsKernelDefinitionSafety.safe
            List.nil
            0
            psKernelLeanNatMaxSizeDefault
            processed.state.aux
            (psKernelBenchNestedWideRenames
              processed)
            processed.state.aux with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchNestedWideAdmissionLoop
    (iterations : Nat)
    (environment : PsKernelEnvironment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedWideAdmissionLoop
          rest
          environment
      match
          psKernelAddSimpleNestedInductive
            65536
            environment
            psKernelBenchNestedWideDecl
            0
            psKernelLeanNatMaxSizeDefault with
      | Except.ok next =>
          match
              psKernelEnvironmentFind
                next
                psKernelBenchNestedWideTreeName with
          | Option.some
              (PsKernelConstantInfo.inductInfo _) =>
              if
                  psKernelEnvironmentContains
                    next
                    psKernelBenchNestedWideRecName then
                pure (Nat.succ tail)
              else
                pure tail
          | _ =>
              pure tail
      | Except.error _ =>
          pure tail

partial def psKernelBenchLeanNestedWideAdmissionLoop
    (iterations : Nat)
    (environment : Lean.Environment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchLeanNestedWideAdmissionLoop
          rest
          environment
      match
          Lean.Kernel.Environment.addDecl
            environment.toKernelEnv
            {}
            psKernelBenchLeanNestedWideDecl with
      | .ok next =>
          match
              next.find?
                psKernelBenchLeanNestedWideTreeName,
              next.find?
                psKernelBenchLeanNestedWideRecName with
          | some (.inductInfo _), some (.recInfo _) =>
              pure (Nat.succ tail)
          | _, _ =>
              pure tail
      | .error _ =>
          pure tail

partial def psKernelBenchNestedPreprocessLoop
    (iterations : Nat)
    (environment : PsKernelEnvironment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedPreprocessLoop
          rest
          environment
      match psKernelBenchNestedProcess environment with
      | Except.ok processed =>
          match processed.state.aux with
          | List.cons _ _ =>
              pure (Nat.succ tail)
          | List.nil =>
              pure tail
      | Except.error _ =>
          pure tail

partial def psKernelBenchNestedTransformLoop
    (iterations : Nat)
    (environment : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedTransformLoop
          rest
          environment
          processed
      match
          psKernelBenchNestedTransform
            environment
            processed with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchNestedRestoreLoop
    (iterations : Nat)
    (base : PsKernelEnvironment)
    (transformed : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedRestoreLoop
          rest
          base
          transformed
          processed
      match
          psKernelBenchNestedRestore
            base
            transformed
            processed with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchNestedValidateLoop
    (iterations : Nat)
    (transformed : PsKernelEnvironment)
    (finalEnvironment : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedValidateLoop
          rest
          transformed
          finalEnvironment
          processed
      match
          psKernelBenchNestedValidate
            transformed
            finalEnvironment
            processed with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail


partial def psKernelBenchNestedValidateTemplatesLoop
    (iterations : Nat)
    (finalEnvironment : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedValidateTemplatesLoop
          rest
          finalEnvironment
          processed
      match
          psKernelBenchNestedValidateTemplates
            finalEnvironment
            processed with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchNestedValidateOriginalsLoop
    (iterations : Nat)
    (finalEnvironment : PsKernelEnvironment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedValidateOriginalsLoop
          rest
          finalEnvironment
      match
          psKernelBenchNestedValidateOriginals
            finalEnvironment with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchNestedValidateAuxLoop
    (iterations : Nat)
    (transformed : PsKernelEnvironment)
    (finalEnvironment : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedValidateAuxLoop
          rest
          transformed
          finalEnvironment
          processed
      match
          psKernelBenchNestedValidateAux
            transformed
            finalEnvironment
            processed with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail


partial def psKernelBenchNestedValidateOriginalConstructorsLoop
    (iterations : Nat)
    (finalEnvironment : PsKernelEnvironment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedValidateOriginalConstructorsLoop
          rest
          finalEnvironment
      match
          psKernelBenchNestedValidateOriginalConstructors
            finalEnvironment with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchNestedValidateOriginalRecursorLoop
    (iterations : Nat)
    (finalEnvironment : PsKernelEnvironment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedValidateOriginalRecursorLoop
          rest
          finalEnvironment
      match
          psKernelBenchNestedValidateOriginalRecursor
            finalEnvironment with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchNestedValidateAuxRulesLoop
    (iterations : Nat)
    (transformed : PsKernelEnvironment)
    (finalEnvironment : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedValidateAuxRulesLoop
          rest
          transformed
          finalEnvironment
          processed
      match
          psKernelBenchNestedValidateAuxRules
            transformed
            finalEnvironment
            processed with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchNestedValidateAuxRecursorLoop
    (iterations : Nat)
    (finalEnvironment : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedValidateAuxRecursorLoop
          rest
          finalEnvironment
          processed
      match
          psKernelBenchNestedValidateAuxRecursor
            finalEnvironment
            processed with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail


partial def psKernelBenchNestedValidateOriginalRecursorTypeLoop
    (iterations : Nat)
    (finalEnvironment : PsKernelEnvironment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedValidateOriginalRecursorTypeLoop
          rest
          finalEnvironment
      match
          psKernelBenchNestedValidateOriginalRecursorType
            finalEnvironment with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchNestedValidateOriginalRulesLoop
    (iterations : Nat)
    (finalEnvironment : PsKernelEnvironment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedValidateOriginalRulesLoop
          rest
          finalEnvironment
      match
          psKernelBenchNestedValidateOriginalRules
            finalEnvironment with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchNestedValidateAuxOldRulesLoop
    (iterations : Nat)
    (transformed : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedValidateAuxOldRulesLoop
          rest
          transformed
          processed
      match
          psKernelBenchNestedValidateAuxOldRules
            transformed
            processed with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchNestedValidateAuxNewRulesLoop
    (iterations : Nat)
    (finalEnvironment : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedValidateAuxNewRulesLoop
          rest
          finalEnvironment
          processed
      match
          psKernelBenchNestedValidateAuxNewRules
            finalEnvironment
            processed with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchNestedInferOriginalRulesLoop
    (iterations : Nat)
    (finalEnvironment : PsKernelEnvironment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedInferOriginalRulesLoop
          rest
          finalEnvironment
      match
          psKernelBenchNestedInferOriginalRules
            finalEnvironment with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchNestedInferAuxOldRulesLoop
    (iterations : Nat)
    (transformed : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedInferAuxOldRulesLoop
          rest
          transformed
          processed
      match
          psKernelBenchNestedInferAuxOldRules
            transformed
            processed with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchNestedInferAuxNewRulesLoop
    (iterations : Nat)
    (finalEnvironment : PsKernelEnvironment)
    (processed : PsKernelSimpleNestedProcessQueueResult) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedInferAuxNewRulesLoop
          rest
          finalEnvironment
          processed
      match
          psKernelBenchNestedInferAuxNewRules
            finalEnvironment
            processed with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail
