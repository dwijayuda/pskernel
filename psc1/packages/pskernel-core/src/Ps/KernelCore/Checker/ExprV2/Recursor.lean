import Ps.KernelCore.Checker.ExprV2.RecursorK

/-
Iota reduction over an owning canonical DAG and complete checking state.

The live environment supplies recursor and constructor metadata. For K
recursors, conversion runs before the constructor shortcut and uses the
owner's fixed public-WHNF, inference and DefEq callbacks. The returned state
then enters the shared constructor/major-WHNF/Nat/String/structure pipeline.
Cheap flags select only the first non-constructor major reduction. Rule
selection, field sufficiency and universe arity retain their original order.

Rule types/bodies are installed once from complete checked inductive admission
by API.DagGenerated, including ordinary K recursors. They are never supplied
by the untrusted RunDag boundary. Missing owners or unsupported descendants
decline the complete attempt. No recursive expression is traversed or imported
by this reduction stage. The transitional inductive-admission bridge remains.

Callback-limited standalone compatibility helpers retain their prior explicit
K/String/structure boundary. The checked public path supplies the full owner
and every callback; it never substitutes a temporary checker.
-/

def psKernelExprV2RecursorRuleRefFind
    (rules : List PsKernelExprV2RecursorRuleRef) (ctor : PsKernelName) :
    Option PsKernelExprV2RecursorRuleRef :=
  match rules with
  | List.nil => Option.none
  | List.cons first rest =>
      if psKernelNameEq first.ctor ctor then Option.some first
      else psKernelExprV2RecursorRuleRefFind rest ctor

def psKernelExprV2RecursorRuleOwner
    (declarations : List PsKernelExprV2DeclarationRef)
    (recursor : PsKernelRecursorInfo) (rule : PsKernelRecursorRule) :
    Option Nat :=
  match psKernelExprV2DeclarationRefFind declarations recursor.base.name with
  | Option.none => Option.none
  | Option.some owner =>
      if psKernelExprV2DeclarationRefMatches owner
          (PsKernelConstantInfo.recInfo recursor) then
        match owner.kind with
        | PsKernelExprV2DeclarationRefKind.recursorDecl rules =>
            match psKernelExprV2RecursorRuleRefFind rules rule.ctor with
            | Option.none => Option.none
            | Option.some found =>
                if Nat.beq found.nFields rule.nFields then Option.some found.rhs
                else Option.none
        | _ => Option.none
      else Option.none

def psKernelExprV2RecursorApplyRule
    (state : PsKernelExprV2WhnfState) (recursor : PsKernelRecursorInfo)
    (recLevels : List PsKernelLevel) (recArgs majorArgs : List Nat)
    (majorIndex : Nat) (rule : PsKernelRecursorRule) :
    Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))) :=
  if psKernelNatGt rule.nFields (psKernelExprV2TransformNatLength majorArgs) then
    Option.some (Except.ok (Prod.mk state Option.none))
  else if Nat.beq (psKernelLevelListLength recLevels)
      (psKernelNameListLength recursor.base.levelParams) then
    match psKernelExprV2RecursorRuleOwner state.declarations recursor rule with
    | Option.none => Option.none
    | Option.some rhs =>
        let transform : PsKernelExprV2Transform := PsKernelExprV2Transform.levels recursor.base.levelParams recLevels;
        match psKernelExprV2TransformOnCanonical transform state.arena rhs 0 with
        | Except.error error => Option.some (Except.error error)
        | Except.ok substituted =>
            let fixedCount := Nat.add recursor.numParams
              (Nat.add recursor.numMotives recursor.numMinors);
            let fixedArgs := psKernelExprV2RecursorTake fixedCount recArgs;
            match psKernelExprV2TransformApplyArgsOnCanonical
                fixedArgs (Prod.fst substituted) (Prod.snd substituted) with
            | Except.error error => Option.some (Except.error error)
            | Except.ok fixed =>
                let ctorParamCount :=
                  Nat.sub (psKernelExprV2TransformNatLength majorArgs) rule.nFields;
                let fields := psKernelExprV2RecursorTake rule.nFields
                  (psKernelExprV2QuotDrop ctorParamCount majorArgs);
                match psKernelExprV2TransformApplyArgsOnCanonical
                    fields (Prod.fst fixed) (Prod.snd fixed) with
                | Except.error error => Option.some (Except.error error)
                | Except.ok applied =>
                    let trailing := psKernelExprV2QuotDrop (Nat.succ majorIndex) recArgs;
                    match psKernelExprV2TransformApplyArgsOnCanonical
                        trailing (Prod.fst applied) (Prod.snd applied) with
                    | Except.error error => Option.some (Except.error error)
                    | Except.ok result =>
                        Option.some (Except.ok (Prod.mk
                          (psKernelExprV2WhnfStateWithArena state (Prod.fst result))
                          (Option.some (Prod.snd result))))
  else Option.some (Except.ok (Prod.mk state Option.none))

def psKernelExprV2RecursorSelectRule
    (state : PsKernelExprV2WhnfState)
    (recursor : PsKernelRecursorInfo) (recLevels : List PsKernelLevel)
    (recArgs : List Nat) (majorIndex major : Nat) :
    Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))) :=
  match psKernelExprV2TransformAppSpineOnCanonical state.arena major with
  | Except.error error => Option.some (Except.error error)
  | Except.ok spine =>
      match psKernelExprV2PagedRequire state.arena (Prod.fst spine) with
      | Except.error error => Option.some (Except.error error)
      | Except.ok head =>
          match head.node with
          | PsKernelExprV2Node.const ctorName _ =>
              match psKernelFindRecursorRule ctorName recursor.rules with
              | Option.none => Option.some (Except.ok (Prod.mk state Option.none))
              | Option.some rule =>
                  psKernelExprV2RecursorApplyRule state recursor recLevels recArgs
                    (Prod.snd spine) majorIndex rule
          | _ => Option.some (Except.ok (Prod.mk state Option.none))

def psKernelExprV2RecursorNormalizeMajor
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (major : Nat) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match psKernelExprV2PagedRequire state.arena major with
  | Except.error error => Option.some (Except.error error)
  | Except.ok entry =>
      match entry.node with
      | PsKernelExprV2Node.lit literal =>
          match literal with
          | PsKernelLiteral.nat value =>
              Option.some (psKernelExprV2RecursorNatMajor state value)
          | PsKernelLiteral.str _ => Option.none
      | _ =>
          match psKernelExprV2RecursorIsConstructorApp context state.arena major with
          | Except.error error => Option.some (Except.error error)
          | Except.ok found =>
              if found then Option.some (Except.ok (Prod.mk state major))
              else Option.none

def psKernelExprV2TryReduceRecursorMajorOwnedWith
    (normalize : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
      PsKernelRecursorInfo -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (majorWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (recursor : PsKernelRecursorInfo) (recLevels : List PsKernelLevel)
    (recArgs : List Nat) (majorIndex major : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState (Option Nat))) :=
  match psKernelExprV2RecursorIsConstructorApp context.scalar state.whnf.arena major with
  | Except.error error => Option.some (Except.error error)
  | Except.ok isConstructor =>
      if isConstructor then
        psKernelExprV2LiftOptionalWhnfAttempt state
          (psKernelExprV2RecursorSelectRule state.whnf recursor recLevels recArgs majorIndex major)
      else
        match majorWhnf context state major with
        | Option.none => Option.none
        | Option.some attempted =>
            match attempted with
            | Except.error error => Option.some (Except.error error)
            | Except.ok reduced =>
                let afterReduction := Prod.fst reduced;
                match normalize context afterReduction recursor (Prod.snd reduced) with
                | Option.none => Option.none
                | Option.some normalizedAttempt =>
                    match normalizedAttempt with
                    | Except.error error => Option.some (Except.error error)
                    | Except.ok normalized =>
                        let afterNormalization := Prod.fst normalized;
                        psKernelExprV2LiftOptionalWhnfAttempt afterNormalization
                          (psKernelExprV2RecursorSelectRule afterNormalization.whnf
                            recursor recLevels recArgs majorIndex (Prod.snd normalized))

def psKernelExprV2TryReduceRecursorMajorWithKOwnedWith
    (publicWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (normalize : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
      PsKernelRecursorInfo -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (majorWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (recursor : PsKernelRecursorInfo) (recLevels : List PsKernelLevel)
    (recArgs : List Nat) (majorIndex major : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState (Option Nat))) :=
  let converted : Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
    if recursor.k then
      psKernelExprV2RecursorKOwnedWith publicWhnf inferType defeq context state recursor major
    else Option.some (Except.ok (Prod.mk state major));
  match converted with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok result =>
          psKernelExprV2TryReduceRecursorMajorOwnedWith normalize majorWhnf
            context (Prod.fst result) recursor recLevels recArgs majorIndex (Prod.snd result)

def psKernelExprV2TryReduceNonKRecursorUsingOwnedWith
    (normalize : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
      PsKernelRecursorInfo -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (majorWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (recursor : PsKernelRecursorInfo) (recLevels : List PsKernelLevel)
    (recArgs : List Nat) (majorIndex major : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState (Option Nat))) :=
  if recursor.k then Option.none
  else psKernelExprV2TryReduceRecursorMajorOwnedWith
    normalize majorWhnf context state recursor recLevels recArgs majorIndex major

def psKernelExprV2TryReduceNonKRecursorOwnedWith
    (majorWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (recursor : PsKernelRecursorInfo) (recLevels : List PsKernelLevel)
    (recArgs : List Nat) (majorIndex major : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState (Option Nat))) :=
  let normalize :=
    fun (nextContext : PsKernelExprV2CheckContext) (nextState : PsKernelExprV2CheckState)
        (_recursor : PsKernelRecursorInfo) (nextMajor : Nat) =>
      psKernelExprV2LiftWhnfAttempt nextState
        (psKernelExprV2RecursorNormalizeMajor nextContext.scalar nextState.whnf nextMajor);
  psKernelExprV2TryReduceNonKRecursorUsingOwnedWith
    normalize majorWhnf context state recursor recLevels recArgs majorIndex major

def psKernelExprV2TryReduceInductiveRecursorUsingOwned
    (reduceMajor : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
      PsKernelRecursorInfo -> List PsKernelLevel -> List Nat -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState (Option Nat))))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState (Option Nat))) :=
  match psKernelExprV2TransformAppSpineOnCanonical state.whnf.arena root with
  | Except.error error => Option.some (Except.error error)
  | Except.ok spine =>
      match psKernelExprV2PagedRequire state.whnf.arena (Prod.fst spine) with
      | Except.error error => Option.some (Except.error error)
      | Except.ok head =>
          match head.node with
          | PsKernelExprV2Node.const name levels =>
              match psKernelEnvironmentFind context.scalar.environment name with
              | Option.none => Option.some (Except.ok (Prod.mk state Option.none))
              | Option.some info =>
                  match info with
                  | PsKernelConstantInfo.recInfo recursor =>
                      let args := Prod.snd spine;
                      let majorIndex := Nat.add recursor.numParams
                        (Nat.add recursor.numMotives
                          (Nat.add recursor.numMinors recursor.numIndices));
                      if Nat.ble (psKernelExprV2TransformNatLength args) majorIndex then
                        Option.some (Except.ok (Prod.mk state Option.none))
                      else
                        match psKernelExprV2TransformNatGet args majorIndex with
                        | Option.none => Option.some (Except.ok (Prod.mk state Option.none))
                        | Option.some major =>
                            reduceMajor context state recursor levels args majorIndex major
                  | _ => Option.some (Except.ok (Prod.mk state Option.none))
          | _ => Option.some (Except.ok (Prod.mk state Option.none))

def psKernelExprV2TryReduceInductiveRecursorOwned
    (majorWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState (Option Nat))) :=
  let reduceMajor :=
    fun (nextContext : PsKernelExprV2CheckContext) (nextState : PsKernelExprV2CheckState)
        (recursor : PsKernelRecursorInfo) (levels : List PsKernelLevel)
        (args : List Nat) (majorIndex major : Nat) =>
      psKernelExprV2TryReduceNonKRecursorOwnedWith
        majorWhnf nextContext nextState recursor levels args majorIndex major;
  psKernelExprV2TryReduceInductiveRecursorUsingOwned reduceMajor context state root

/- The bounded owner supplies four fixed callbacks in the V1 order. K,
   structure and String normalization retain the same complete owner. -/
def psKernelExprV2TryReduceRecursorOwnedWith
    (publicWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Bool -> Bool ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root : Nat) (cheapRec cheapProj : Bool) :
    Option (Except String (Prod PsKernelExprV2CheckState (Option Nat))) :=
  match psKernelExprV2TryReduceQuotOwnedWith publicWhnf context state root with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          match Prod.snd reduced with
          | Option.some _ => Option.some (Except.ok reduced)
          | Option.none =>
              let majorWhnf :=
                fun (nextContext : PsKernelExprV2CheckContext)
                    (nextState : PsKernelExprV2CheckState) (nextRoot : Nat) =>
                  if cheapRec then
                    coreWhnf nextContext nextState nextRoot cheapRec cheapProj
                  else publicWhnf nextContext nextState nextRoot;
              let normalize :=
                fun (nextContext : PsKernelExprV2CheckContext)
                    (nextState : PsKernelExprV2CheckState)
                    (recursor : PsKernelRecursorInfo) (major : Nat) =>
                  psKernelExprV2RecursorNormalizeMajorOwnedWith
                    publicWhnf inferType nextContext nextState recursor major;
              let reduceMajor :=
                fun (nextContext : PsKernelExprV2CheckContext)
                    (nextState : PsKernelExprV2CheckState)
                    (recursor : PsKernelRecursorInfo) (levels : List PsKernelLevel)
                    (args : List Nat) (majorIndex major : Nat) =>
                  psKernelExprV2TryReduceRecursorMajorWithKOwnedWith
                    publicWhnf inferType defeq normalize majorWhnf
                    nextContext nextState recursor levels args majorIndex major;
              psKernelExprV2TryReduceInductiveRecursorUsingOwned
                reduceMajor context (Prod.fst reduced) root

/- Standalone old-ABI helpers select their original public-WHNF major callback.
   Their full-state initialization/lowering does not occur on the owned path. -/

def psKernelExprV2TryReduceNonKRecursorWith
    (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (recursor : PsKernelRecursorInfo) (recLevels : List PsKernelLevel)
    (recArgs : List Nat) (majorIndex major : Nat) :
    Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))) :=
  psKernelExprV2LowerOptionalWhnfAttempt
    (psKernelExprV2TryReduceNonKRecursorOwnedWith (psKernelExprV2LiftScalarWhnf publicWhnf)
      (psKernelExprV2CheckContextEmpty context)
      (psKernelExprV2CheckStateFromWhnf state) recursor recLevels recArgs majorIndex major)

def psKernelExprV2TryReduceInductiveRecursor
    (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (root : Nat) :
    Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))) :=
  psKernelExprV2LowerOptionalWhnfAttempt
    (psKernelExprV2TryReduceInductiveRecursorOwned (psKernelExprV2LiftScalarWhnf publicWhnf)
      (psKernelExprV2CheckContextEmpty context)
      (psKernelExprV2CheckStateFromWhnf state) root)
