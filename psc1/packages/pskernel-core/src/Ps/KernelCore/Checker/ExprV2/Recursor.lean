import Ps.KernelCore.Checker.ExprV2.Quot
import Ps.KernelCore.Checker.Recursor.Analysis

/-
First ordinary iota slice over an owning canonical DAG.

The live environment identifies the recursor and constructor metadata.
A syntactic constructor major takes the reference's two constructor shortcuts
without invoking callbacks. Other non-K majors first use the recursor owner's
fixed predecessor public-WHNF callback; only then may a constructor or Nat
literal reduce. Literal expansion never skips that callback's resource guards.
Rule selection, field sufficiency and universe arity retain their original
order before consulting the private generated-rule owner.

Rule types/bodies are installed once from complete checked inductive admission
by API.DagGenerated. They are never supplied by the untrusted RunDag boundary.
Missing, inconsistent or unsupported owners request the complete original
operation. K conversion, String expansion and residual non-constructor majors
needing structure conversion remain explicit fallback. No recursive expression
is traversed or imported by this reduction stage.
-/

def psKernelExprV2RecursorTake
    (count : Nat) (values : List Nat) : List Nat :=
  match count with
  | Nat.zero => List.nil
  | Nat.succ remaining =>
      match values with
      | List.nil => List.nil
      | List.cons first rest =>
          List.cons first (psKernelExprV2RecursorTake remaining rest)

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

def psKernelExprV2RecursorIsConstructorApp
    (context : PsKernelCheckerContext) (arena : PsKernelExprV2PagedArena) (root : Nat) :
    Except String Bool :=
  match psKernelExprV2TransformAppSpineOnCanonical arena root with
  | Except.error error => Except.error error
  | Except.ok spine =>
      match psKernelExprV2PagedRequire arena (Prod.fst spine) with
      | Except.error error => Except.error error
      | Except.ok head =>
          match head.node with
          | PsKernelExprV2Node.const name _ =>
              match psKernelEnvironmentFind context.environment name with
              | Option.some info =>
                  match info with
                  | PsKernelConstantInfo.ctorInfo _ => Except.ok true
                  | _ => Except.ok false
              | Option.none => Except.ok false
          | _ => Except.ok false

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

def psKernelExprV2RecursorNatMajor
    (state : PsKernelExprV2WhnfState) (value : Nat) :
    Except String (Prod PsKernelExprV2WhnfState Nat) :=
  match value with
  | Nat.zero =>
      match psKernelExprV2PagedMkConst state.arena psKernelNatZeroName List.nil with
      | Except.error error => Except.error error
      | Except.ok result =>
          Except.ok (Prod.mk
            (psKernelExprV2WhnfStateWithArena state (Prod.fst result)) (Prod.snd result))
  | Nat.succ predecessor =>
      match psKernelExprV2PagedMkConst state.arena psKernelNatSuccName List.nil with
      | Except.error error => Except.error error
      | Except.ok head =>
          match psKernelExprV2PagedMkLit (Prod.fst head) (PsKernelLiteral.nat predecessor) with
          | Except.error error => Except.error error
          | Except.ok arg =>
              match psKernelExprV2PagedMkApp (Prod.fst arg) (Prod.snd head) (Prod.snd arg) with
              | Except.error error => Except.error error
              | Except.ok result =>
                  Except.ok (Prod.mk
                    (psKernelExprV2WhnfStateWithArena state (Prod.fst result))
                    (Prod.snd result))

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

def psKernelExprV2TryReduceNonKRecursorWith
    (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (recursor : PsKernelRecursorInfo) (recLevels : List PsKernelLevel)
    (recArgs : List Nat) (majorIndex major : Nat) :
    Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))) :=
  if recursor.k then Option.none
  else
    match psKernelExprV2RecursorIsConstructorApp context state.arena major with
    | Except.error error => Option.some (Except.error error)
    | Except.ok isConstructor =>
        if isConstructor then
          psKernelExprV2RecursorSelectRule state recursor recLevels recArgs majorIndex major
        else
          match publicWhnf context state major with
          | Option.none => Option.none
          | Option.some attempted =>
              match attempted with
              | Except.error error => Option.some (Except.error error)
              | Except.ok reduced =>
                  match psKernelExprV2RecursorNormalizeMajor
                      context (Prod.fst reduced) (Prod.snd reduced) with
                  | Option.none => Option.none
                  | Option.some normalizedAttempt =>
                      match normalizedAttempt with
                      | Except.error error => Option.some (Except.error error)
                      | Except.ok normalized =>
                          psKernelExprV2RecursorSelectRule (Prod.fst normalized)
                            recursor recLevels recArgs majorIndex (Prod.snd normalized)

def psKernelExprV2TryReduceInductiveRecursor
    (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (root : Nat) :
    Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))) :=
  match psKernelExprV2TransformAppSpineOnCanonical state.arena root with
  | Except.error error => Option.some (Except.error error)
  | Except.ok spine =>
      match psKernelExprV2PagedRequire state.arena (Prod.fst spine) with
      | Except.error error => Option.some (Except.error error)
      | Except.ok head =>
          match head.node with
          | PsKernelExprV2Node.const name levels =>
              match psKernelEnvironmentFind context.environment name with
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
                            psKernelExprV2TryReduceNonKRecursorWith
                              publicWhnf context state recursor levels args majorIndex major
                  | _ => Option.some (Except.ok (Prod.mk state Option.none))
          | _ => Option.some (Except.ok (Prod.mk state Option.none))
