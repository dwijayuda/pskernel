import Ps.KernelCore.API.DagNestedRestoration

/- Private owning post-restoration checks. Every semantic operation uses the
   DAG callback at the unchanged entry fuel. Fresh legacy sessions correspond
   to fresh checking caches over the retained append-only arena. Option.none
   and hard errors leave no partially validated owner. Internal synchronized
   metadata/source correspondence is a caller premise, not a certificate. -/
def psKernelExprV2NestedValidationAddParams
    (params : List PsKernelExprV2OrdinaryOpenBinder) (context : PsKernelExprV2CheckContext) :
    PsKernelExprV2CheckContext :=
  match params with
  | List.nil => context
  | List.cons first rest =>
      psKernelExprV2NestedValidationAddParams rest
        (psKernelExprV2CheckContextWithLocal context first.internalName first.userName first.type first.binderInfo)

def psKernelExprV2NestedValidationContext
    (environment : PsKernelEnvironment) (levels : List PsKernelName)
    (isUnsafe : Bool) (maxRecDepth maxNatSize : Nat)
    (params : List PsKernelExprV2OrdinaryOpenBinder) : PsKernelExprV2CheckContext :=
  psKernelExprV2NestedValidationAddParams params
    (psKernelExprV2OrdinaryFreshContext environment levels isUnsafe maxRecDepth maxNatSize)

def psKernelExprV2NestedValidationRoot
    (owner : PsKernelDagGeneratedState) (name : PsKernelName) : Except String Nat :=
  match psKernelExprV2DeclarationRefFind owner.declarations name with
  | Option.none => Except.error "PSKERNEL_V2_NESTED_VALIDATION_OWNER_MISSING"
  | Option.some reference => Except.ok reference.type

def psKernelExprV2NestedValidationRules
    (owner : PsKernelDagGeneratedState) (name : PsKernelName) :
    Except String (List PsKernelExprV2RecursorRuleRef) :=
  match psKernelExprV2DeclarationRefFind owner.declarations name with
  | Option.none => Except.error "PSKERNEL_V2_NESTED_VALIDATION_OWNER_MISSING"
  | Option.some reference =>
      match reference.kind with
      | PsKernelExprV2DeclarationRefKind.recursorDecl rules => Except.ok rules
      | _ => Except.error "PSKERNEL_V2_NESTED_VALIDATION_RECURSOR_KIND"

def psKernelExprV2NestedValidateRulesWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (rules : List PsKernelExprV2RecursorRuleRef) (fuel : Nat)
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState) :
    Option (Except String PsKernelExprV2CheckState) :=
  match rules with
  | List.nil => Option.some (Except.ok state)
  | List.cons rule rest =>
      match check fuel context state rule.rhs with
      | Option.none => Option.none
      | Option.some attempted =>
          match attempted with
          | Except.error error => Option.some (Except.error error)
          | Except.ok result => psKernelExprV2NestedValidateRulesWith check rest fuel context (Prod.fst result)

def psKernelExprV2NestedValidateTypeWith
    (check whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (fuel : Nat) (context : PsKernelExprV2CheckContext) (owner : PsKernelDagGeneratedState)
    (root : Nat) (sortRequired : Bool) (rules : List PsKernelExprV2RecursorRuleRef) :
    Option (Except String PsKernelDagGeneratedState) :=
  match check fuel context (psKernelExprV2OrdinaryFreshState owner) root with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok checked =>
          let sorted :=
            if sortRequired then
              match psKernelExprV2AdmissionEnsureSortOwnedWith (whnf fuel) context (Prod.fst checked) (Prod.snd checked) with
              | Option.none => Option.none
              | Option.some attemptedSort =>
                  match attemptedSort with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok result => Option.some (Except.ok (Prod.fst result))
            else Option.some (Except.ok (Prod.fst checked));
          match sorted with
          | Option.none => Option.none
          | Option.some attemptedSort =>
              match attemptedSort with
              | Except.error error => Option.some (Except.error error)
              | Except.ok result =>
                  match psKernelExprV2NestedValidateRulesWith check rules fuel context result with
                  | Option.none => Option.none
                  | Option.some attemptedRules =>
                      match attemptedRules with
                      | Except.error error => Option.some (Except.error error)
                      | Except.ok state => Option.some (psKernelExprV2OrdinarySynchronizeOwner state owner.built)

def psKernelExprV2NestedValidateTemplatesWith
    (check whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (families : List PsKernelSimpleNestedAuxFamily) (fuel : Nat)
    (context : PsKernelExprV2CheckContext) (owner : PsKernelDagGeneratedState) :
    Option (Except String PsKernelDagGeneratedState) :=
  match families with
  | List.nil => Option.some (Except.ok owner)
  | List.cons family rest =>
      match psKernelDagGeneratedImport family.nestedTemplate owner with
      | Except.error error => Option.some (Except.error error)
      | Except.ok imported =>
          match psKernelExprV2NestedValidateTypeWith check whnf fuel context
              (Prod.fst imported) (Prod.snd imported) false List.nil with
          | Option.none => Option.none
          | Option.some attempted =>
              match attempted with
              | Except.error error => Option.some (Except.error error)
              | Except.ok next => psKernelExprV2NestedValidateTemplatesWith check whnf rest fuel context next

def psKernelExprV2NestedValidateConstructorsWith
    (check whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (names : List PsKernelName) (fuel : Nat) (environment : PsKernelEnvironment)
    (context : PsKernelExprV2CheckContext) (owner : PsKernelDagGeneratedState) :
    Option (Except String PsKernelDagGeneratedState) :=
  match names with
  | List.nil => Option.some (Except.ok owner)
  | List.cons name rest =>
      match psKernelEnvironmentFind environment name with
      | Option.none => Option.some (Except.error "restored constructor missing during validation")
      | Option.some info =>
          match info with
          | PsKernelConstantInfo.ctorInfo _ =>
              match psKernelExprV2NestedValidationRoot owner name with
              | Except.error error => Option.some (Except.error error)
              | Except.ok root =>
                  match psKernelExprV2NestedValidateTypeWith check whnf fuel context owner root false List.nil with
                  | Option.none => Option.none
                  | Option.some attempted =>
                      match attempted with
                      | Except.error error => Option.some (Except.error error)
                      | Except.ok next =>
                          psKernelExprV2NestedValidateConstructorsWith check whnf rest fuel environment context next
          | _ => Option.some (Except.error "restored constructor missing during validation")

def psKernelExprV2NestedValidateOriginalsWith
    (check whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (types : List PsKernelSimpleMutualTypeDecl) (fuel : Nat) (environment : PsKernelEnvironment)
    (levels : List PsKernelName) (isUnsafe : Bool) (maxRecDepth maxNatSize : Nat)
    (owner : PsKernelDagGeneratedState) : Option (Except String PsKernelDagGeneratedState) :=
  match types with
  | List.nil => Option.some (Except.ok owner)
  | List.cons type rest =>
      match psKernelEnvironmentFind environment type.name with
      | Option.none => Option.some (Except.error "restored inductive missing during validation")
      | Option.some info =>
          match info with
          | PsKernelConstantInfo.inductInfo inductiveInfo =>
              let context := psKernelExprV2OrdinaryFreshContext environment levels isUnsafe maxRecDepth maxNatSize;
              match psKernelExprV2NestedValidateConstructorsWith check whnf inductiveInfo.ctors fuel environment context owner with
              | Option.none => Option.none
              | Option.some attemptedConstructors =>
                  match attemptedConstructors with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok next =>
                      let name := psKernelSimpleRecName type.name;
                      match psKernelEnvironmentFind environment name with
                      | Option.none => Option.some (Except.error "restored recursor missing during validation")
                      | Option.some recursor =>
                          match recursor with
                          | PsKernelConstantInfo.recInfo value =>
                              match psKernelExprV2NestedValidationRoot next name with
                              | Except.error error => Option.some (Except.error error)
                              | Except.ok root =>
                                  match psKernelExprV2NestedValidationRules next name with
                                  | Except.error error => Option.some (Except.error error)
                                  | Except.ok rules =>
                                      let recContext := psKernelExprV2OrdinaryFreshContext environment
                                        value.base.levelParams isUnsafe maxRecDepth maxNatSize;
                                      match psKernelExprV2NestedValidateTypeWith check whnf fuel recContext next root true rules with
                                      | Option.none => Option.none
                                      | Option.some attemptedRecursor =>
                                          match attemptedRecursor with
                                          | Except.error error => Option.some (Except.error error)
                                          | Except.ok checked => psKernelExprV2NestedValidateOriginalsWith check whnf rest fuel
                                              environment levels isUnsafe maxRecDepth maxNatSize checked
                          | _ => Option.some (Except.error "restored recursor missing during validation")
          | _ => Option.some (Except.error "restored inductive missing during validation")

def psKernelExprV2NestedCompareRulesWith
    (infer check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (oldRules : List PsKernelExprV2RecursorRuleRef) (newRules : List PsKernelExprV2RecursorRuleRef)
    (fuel : Nat) (oldContext newContext : PsKernelExprV2CheckContext)
    (oldOwner : PsKernelDagGeneratedState) (newOwner : PsKernelDagGeneratedState)
    (plan : PsKernelExprV2NestedPreprocessed) (renames : List (Prod PsKernelName PsKernelName)) :
    Option (Except String PsKernelDagGeneratedState) :=
  match oldRules with
  | List.nil =>
      match newRules with
      | List.nil => Option.some (Except.ok newOwner)
      | List.cons _ _ => Option.some (Except.error "restored nested recursor rule count mismatch")
  | List.cons oldRule oldRest =>
      match newRules with
      | List.nil => Option.some (Except.error "restored nested recursor rule count mismatch")
      | List.cons newRule newRest =>
          match infer fuel oldContext (psKernelExprV2OrdinaryFreshState oldOwner) oldRule.rhs with
          | Option.none => Option.none
          | Option.some attemptedOld =>
              match attemptedOld with
              | Except.error error => Option.some (Except.error error)
              | Except.ok oldType =>
                  let inferredState := Prod.fst oldType;
                  match psKernelExprV2OrdinaryExtendDecoded inferredState.whnf.arena oldOwner.built with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok decoded =>
                      match psKernelExprV2DecodedRequire decoded (Prod.snd oldType) with
                      | Except.error error => Option.some (Except.error error)
                      | Except.ok expression =>
                          match psKernelSimpleNestedRestoreExpr plan.processed.state.aux renames
                              plan.canonicalParams plan.header.original.numParams expression with
                          | Except.error error => Option.some (Except.error error)
                          | Except.ok expected =>
                              match check fuel newContext (psKernelExprV2OrdinaryFreshState newOwner) newRule.rhs with
                              | Option.none => Option.none
                              | Option.some attemptedNew =>
                                  match attemptedNew with
                                  | Except.error error => Option.some (Except.error error)
                                  | Except.ok newType =>
                                      match psKernelExprV2OrdinaryImportGenerated expected (Prod.fst newType) newOwner.built with
                                      | Except.error error => Option.some (Except.error error)
                                      | Except.ok imported =>
                                          match defeq fuel newContext imported.state (Prod.snd newType) imported.root with
                                          | Option.none => Option.none
                                          | Option.some attemptedEquality =>
                                              match attemptedEquality with
                                              | Except.error error => Option.some (Except.error error)
                                              | Except.ok equal =>
                                                  if Prod.snd equal then
                                                    match psKernelExprV2OrdinarySynchronizeOwner (Prod.fst equal) imported.built with
                                                    | Except.error error => Option.some (Except.error error)
                                                    | Except.ok next => psKernelExprV2NestedCompareRulesWith infer check defeq
                                                        oldRest newRest fuel oldContext newContext oldOwner next plan renames
                                                  else Option.some (Except.error "restored nested recursor rule is not type preserving")

def psKernelExprV2NestedValidateAuxWith
    (infer check whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (families : List PsKernelSimpleNestedAuxFamily) (fuel : Nat)
    (transformed environment : PsKernelEnvironment) (isUnsafe : Bool) (maxRecDepth maxNatSize : Nat)
    (oldOwner owner : PsKernelDagGeneratedState) (plan : PsKernelExprV2NestedPreprocessed)
    (renames : List (Prod PsKernelName PsKernelName)) : Option (Except String PsKernelDagGeneratedState) :=
  match families with
  | List.nil => Option.some (Except.ok owner)
  | List.cons family rest =>
      let oldName := psKernelSimpleRecName family.auxName;
      match psKernelSimpleNestedFindRename oldName renames with
      | Option.none => Option.some (Except.error "nested auxiliary recursor rename missing during validation")
      | Option.some newName =>
          match psKernelEnvironmentFind transformed oldName with
          | Option.none => Option.some (Except.error "transformed nested auxiliary recursor missing")
          | Option.some oldInfo =>
              match oldInfo with
              | PsKernelConstantInfo.recInfo oldValue =>
                  match psKernelEnvironmentFind environment newName with
                  | Option.none => Option.some (Except.error "restored nested auxiliary recursor missing")
                  | Option.some newInfo =>
                      match newInfo with
                      | PsKernelConstantInfo.recInfo newValue =>
                          match psKernelExprV2NestedValidationRules oldOwner oldName with
                          | Except.error error => Option.some (Except.error error)
                          | Except.ok oldRules =>
                              match psKernelExprV2NestedValidationRules owner newName with
                              | Except.error error => Option.some (Except.error error)
                              | Except.ok newRules =>
                                  let oldContext := psKernelExprV2OrdinaryFreshContext transformed
                                    oldValue.base.levelParams isUnsafe maxRecDepth maxNatSize;
                                  let newContext := psKernelExprV2OrdinaryFreshContext environment
                                    newValue.base.levelParams isUnsafe maxRecDepth maxNatSize;
                                  match psKernelExprV2NestedCompareRulesWith infer check defeq oldRules newRules fuel
                                      oldContext newContext oldOwner owner plan renames with
                                  | Option.none => Option.none
                                  | Option.some attemptedRules =>
                                      match attemptedRules with
                                      | Except.error error => Option.some (Except.error error)
                                      | Except.ok next =>
                                          match psKernelExprV2NestedValidationRoot next newName with
                                          | Except.error error => Option.some (Except.error error)
                                          | Except.ok root =>
                                              match psKernelExprV2NestedValidateTypeWith check whnf fuel newContext next root true List.nil with
                                              | Option.none => Option.none
                                              | Option.some attemptedType =>
                                                  match attemptedType with
                                                  | Except.error error => Option.some (Except.error error)
                                                  | Except.ok checked => psKernelExprV2NestedValidateAuxWith infer check whnf defeq
                                                      rest fuel transformed environment isUnsafe maxRecDepth maxNatSize
                                                      oldOwner checked plan renames
                      | _ => Option.some (Except.error "restored nested auxiliary recursor missing")
              | _ => Option.some (Except.error "transformed nested auxiliary recursor missing")

def psKernelExprV2NestedValidateRestoredWith
    (infer check whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (fuel maxRecDepth maxNatSize : Nat) (restored : PsKernelExprV2NestedRestored) :
    Option (Except String PsKernelDagGeneratedState) :=
  let plan := restored.checked.preprocessed;
  let decl := plan.header.original;
  match plan.processed.state.aux with
  | List.nil => Option.some (Except.ok restored.owner)
  | List.cons _ _ =>
      let templateContext := psKernelExprV2NestedValidationContext restored.environment decl.levelParams
        decl.isUnsafe maxRecDepth maxNatSize plan.header.parameters.binders;
      match psKernelExprV2NestedValidateTemplatesWith check whnf plan.processed.state.aux fuel templateContext restored.owner with
      | Option.none => Option.none
      | Option.some attemptedTemplates =>
          match attemptedTemplates with
          | Except.error error => Option.some (Except.error error)
          | Except.ok next =>
              match psKernelExprV2NestedValidateOriginalsWith check whnf decl.types fuel restored.environment
                  decl.levelParams decl.isUnsafe maxRecDepth maxNatSize next with
              | Option.none => Option.none
              | Option.some attemptedOriginals =>
                  match attemptedOriginals with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok checked =>
                      psKernelExprV2NestedValidateAuxWith infer check whnf defeq plan.processed.state.aux fuel
                        restored.checked.admitted.environment restored.environment decl.isUnsafe maxRecDepth maxNatSize
                        restored.checked.admitted.owner checked plan restored.renames

def psKernelExprV2NestedValidateRestoredWithFuel
    (fuel maxRecDepth maxNatSize : Nat) (restored : PsKernelExprV2NestedRestored) :
    Option (Except String PsKernelDagGeneratedState) :=
  psKernelExprV2NestedValidateRestoredWith psKernelExprV2TryInferStateWithFuel
    psKernelExprV2TryCheckStateWithFuel psKernelExprV2TryWhnfCheckStateWithFuel
    psKernelExprV2TryDefEqStateWithFuel fuel maxRecDepth maxNatSize restored
