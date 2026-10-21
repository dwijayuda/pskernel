import Ps.KernelCore.Checker.ExprV2.CheckProjection
import Ps.KernelCore.Checker.ExprV2.CheckLet
import Ps.KernelCore.Checker.ExprV2.InferApplication
import Ps.KernelCore.Checker.ExprV2.Constant
import Ps.KernelCore.Checker.ExprV2.DefEq

/-
One syntax-directed DAG inference worker owns both original inference modes.
Its Boolean mode selects the cache and the original argument/domain/value
checking policy. A result is published exactly once at this owning entry.
Helper rules construct types and restore local scopes without publishing a
judgment. Inference-only results never enter the checked-inference cache.

The fixed WHNF and DefEq callbacks retain the top-level budget; recursive
inference uses the predecessor budget. Unsupported rules restart the complete
original operation without publishing partial state.
-/
def psKernelExprV2TryInferCoreWithFuel
    (fuel : Nat) :
    (PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat))) ->
    (PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool))) ->
    PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Bool ->
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (_whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
          Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (_defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Bool)))
          (_context : PsKernelExprV2CheckContext)
          (_state : PsKernelExprV2CheckState) (_root : Nat) (_inferOnly : Bool) =>
        Option.some (Except.error "kernel inference budget exhausted")
  | Nat.succ remaining =>
      fun (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
          Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Bool)))
          (context : PsKernelExprV2CheckContext)
          (state : PsKernelExprV2CheckState) (root : Nat) (inferOnly : Bool) =>
        let smaller :=
          fun (nextContext : PsKernelExprV2CheckContext)
              (nextState : PsKernelExprV2CheckState) (nextRoot : Nat) =>
            let recur := psKernelExprV2TryInferCoreWithFuel remaining;
            recur whnf defeq nextContext nextState nextRoot inferOnly;
        match psKernelExprV2PagedRequire state.whnf.arena root with
        | Except.error error => Option.some (Except.error error)
        | Except.ok entry =>
            match psKernelExprV2InferenceFind state inferOnly root entry with
            | Except.error error => Option.some (Except.error error)
            | Except.ok cached =>
                match psKernelExprV2CheckContextEnterRecDepth context with
                | Except.error error => Option.some (Except.error error)
                | Except.ok nextContext =>
                    match cached with
                    | Option.some type =>
                        Option.some (Except.ok (Prod.mk state type))
                    | Option.none =>
                        let attempt :
                            Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
                          match entry.node with
                          | PsKernelExprV2Node.bvar _ =>
                              Option.some
                                (Except.error "loose bound variable in type checker")
                          | PsKernelExprV2Node.mvar _ =>
                              Option.some
                                (Except.error "kernel type checker does not support metavariables")
                          | PsKernelExprV2Node.fvar name =>
                              match psKernelExprV2CheckLocalFind nextContext.locals name with
                              | Option.none =>
                                  Option.some (Except.error "unknown free variable")
                              | Option.some declaration =>
                                  Option.some (Except.ok (Prod.mk state declaration.type))
                          | PsKernelExprV2Node.sort level =>
                              Option.some
                                (psKernelExprV2InferenceBuilt state
                                  (psKernelExprV2PagedMkSort state.whnf.arena
                                    (PsKernelLevel.succ level)))
                          | PsKernelExprV2Node.const name levels =>
                              match psKernelExprV2TryInferConstantType nextContext.scalar
                                  state.whnf.arena state.whnf.declarations
                                  name levels inferOnly with
                              | Option.none => Option.none
                              | Option.some built =>
                                  Option.some (psKernelExprV2InferenceBuilt state built)
                          | PsKernelExprV2Node.lit literal =>
                              match literal with
                              | PsKernelLiteral.nat value =>
                                  match psKernelCheckNatSize nextContext.scalar.maxNatSize value with
                                  | Except.error error => Option.some (Except.error error)
                                  | Except.ok _ =>
                                      Option.some
                                        (psKernelExprV2InferenceBuilt state
                                          (psKernelExprV2PagedMkConst state.whnf.arena
                                            psKernelNatName List.nil))
                              | PsKernelLiteral.str _ =>
                                  Option.some
                                    (psKernelExprV2InferenceBuilt state
                                      (psKernelExprV2PagedMkConst state.whnf.arena
                                        psKernelStringName List.nil))
                          | PsKernelExprV2Node.mdata _ body =>
                              smaller nextContext state body
                          | PsKernelExprV2Node.lam name domain body binderInfo =>
                              psKernelExprV2CheckBinderWith smaller whnf
                                nextContext state root name domain body binderInfo true inferOnly
                          | PsKernelExprV2Node.forallE name domain body binderInfo =>
                              psKernelExprV2CheckBinderWith smaller whnf
                                nextContext state root name domain body binderInfo false inferOnly
                          | PsKernelExprV2Node.app fn arg =>
                              if inferOnly then
                                psKernelExprV2InferApplicationWith smaller whnf
                                  nextContext state root
                              else
                                psKernelExprV2CheckApplicationWith smaller whnf defeq
                                  nextContext state root fn arg
                          | PsKernelExprV2Node.proj typeName index structValue =>
                              psKernelExprV2CheckProjectionInferWith smaller whnf
                                nextContext state typeName index structValue
                          | PsKernelExprV2Node.letE name type value body nondep =>
                              psKernelExprV2CheckLetWith smaller whnf defeq
                                nextContext state root name type value body nondep inferOnly;
                        psKernelExprV2InferenceFinishAttempt inferOnly root attempt

/- Compatibility entry preserves the prior staged root-fuel ABI. -/
def psKernelExprV2TryCheckCoreWithFuel
    (fuel : Nat) :
    (PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat))) ->
    (PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool))) ->
    PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (_whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
          Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (_defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Bool)))
          (_context : PsKernelExprV2CheckContext)
          (_state : PsKernelExprV2CheckState) (_root : Nat) =>
        Option.some (Except.error "kernel inference budget exhausted")
  | Nat.succ remaining =>
      fun (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
          Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Bool)))
          (context : PsKernelExprV2CheckContext)
          (state : PsKernelExprV2CheckState) (root : Nat) =>
        psKernelExprV2TryInferCoreWithFuel (Nat.succ remaining)
          whnf defeq context state root false

def psKernelExprV2TryInferenceStateWithFuel
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat) (inferOnly : Bool) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  let whnf :=
    fun (nextContext : PsKernelExprV2CheckContext)
        (nextState : PsKernelExprV2WhnfState) (nextRoot : Nat) =>
      psKernelExprV2CheckWhnfWithFuel fuel nextContext nextState nextRoot;
  let defeq :=
    fun (nextContext : PsKernelExprV2CheckContext)
        (nextState : PsKernelExprV2CheckState) (left right : Nat) =>
      let worker := psKernelExprV2TryDefEqStateWithFuel fuel;
      worker nextContext nextState left right;
  psKernelExprV2TryInferCoreWithFuel fuel whnf defeq context state root inferOnly

def psKernelExprV2TryCheckStateWithFuel
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  psKernelExprV2TryInferenceStateWithFuel fuel context state root false

def psKernelExprV2TryInferStateWithFuel
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  psKernelExprV2TryInferenceStateWithFuel fuel context state root true

def psKernelExprV2TryCheckWithDeclarationsFuel
    (fuel : Nat) (context : PsKernelCheckerContext)
    (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2PagedArena Nat)) :=
  match context.localContext.decls with
  | List.cons _ _ => Option.none
  | List.nil =>
      let initial :=
        psKernelExprV2CheckStateWithWhnf (psKernelExprV2CheckStateEmpty arena)
          (psKernelExprV2WhnfStateForDeclarations arena declarations);
      match psKernelExprV2TryCheckStateWithFuel fuel
          (psKernelExprV2CheckContextEmpty context) initial root with
      | Option.none => Option.none
      | Option.some attempted =>
          match attempted with
          | Except.error error => Option.some (Except.error error)
          | Except.ok checked =>
              let state := Prod.fst checked;
              Option.some (Except.ok (Prod.mk state.whnf.arena (Prod.snd checked)))

def psKernelExprV2TryCheckWithFuel
    (fuel : Nat) (context : PsKernelCheckerContext)
    (arena : PsKernelExprV2PagedArena) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2PagedArena Nat)) :=
  psKernelExprV2TryCheckWithDeclarationsFuel fuel context arena List.nil root
