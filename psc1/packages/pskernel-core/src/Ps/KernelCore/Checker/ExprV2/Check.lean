import Ps.KernelCore.Checker.ExprV2.CheckApplication

/-
DAG-native fully checked Sort/FVar/literal/metadata/lambda/forall inference
and the structural-type-equality branch of dependent application.

The public entry creates one fresh operation and accepts no legacy local
context. Internal binders carry type IDs in their own DAG local context.
Applications requiring general DefEq, constants, lets and projections explicitly
request the complete checker. Unsupported work never publishes a partial
state or a checking receipt.

Fuel zero precedes every operation; cached results still enter recursion depth.
A successful cached judgment is scoped to this operation and local-context
lineage. Child-scope caches are restored when a binder closes.
-/
def psKernelExprV2TryCheckCoreWithFuel
    (fuel : Nat) :
    (PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat))) ->
    PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (_whnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
          Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (_context : PsKernelExprV2CheckContext)
          (_state : PsKernelExprV2CheckState) (_root : Nat) =>
        Option.some (Except.error "kernel inference budget exhausted")
  | Nat.succ remaining =>
      fun (whnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
          Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (context : PsKernelExprV2CheckContext)
          (state : PsKernelExprV2CheckState) (root : Nat) =>
        let smaller :=
          fun (nextContext : PsKernelExprV2CheckContext)
              (nextState : PsKernelExprV2CheckState) (nextRoot : Nat) =>
            let recur := psKernelExprV2TryCheckCoreWithFuel remaining;
            recur whnf nextContext nextState nextRoot;
        match psKernelExprV2PagedRequire state.whnf.arena root with
        | Except.error error => Option.some (Except.error error)
        | Except.ok entry =>
            match psKernelExprV2CheckedInferFind state root entry with
            | Except.error error => Option.some (Except.error error)
            | Except.ok cached =>
                match psKernelExprV2CheckContextEnterRecDepth context with
                | Except.error error => Option.some (Except.error error)
                | Except.ok nextContext =>
                    match cached with
                    | Option.some type =>
                        Option.some (Except.ok (Prod.mk state type))
                    | Option.none =>
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
                                Option.some
                                  (psKernelExprV2CheckedInferFinish state root declaration.type)
                        | PsKernelExprV2Node.sort level =>
                            Option.some
                              (psKernelExprV2CheckedInferBuilt state root
                                (psKernelExprV2PagedMkSort state.whnf.arena
                                  (PsKernelLevel.succ level)))
                        | PsKernelExprV2Node.lit literal =>
                            match literal with
                            | PsKernelLiteral.nat value =>
                                match psKernelCheckNatSize nextContext.scalar.maxNatSize value with
                                | Except.error error => Option.some (Except.error error)
                                | Except.ok _ =>
                                    Option.some
                                      (psKernelExprV2CheckedInferBuilt state root
                                        (psKernelExprV2PagedMkConst state.whnf.arena
                                          psKernelNatName List.nil))
                            | PsKernelLiteral.str _ =>
                                Option.some
                                  (psKernelExprV2CheckedInferBuilt state root
                                    (psKernelExprV2PagedMkConst state.whnf.arena
                                      psKernelStringName List.nil))
                        | PsKernelExprV2Node.mdata _ body =>
                            psKernelExprV2CheckFinishAttempt root
                              (smaller nextContext state body)
                        | PsKernelExprV2Node.lam name domain body binderInfo =>
                            psKernelExprV2CheckBinderWith smaller whnf
                              nextContext state root name domain body binderInfo true
                        | PsKernelExprV2Node.forallE name domain body binderInfo =>
                            psKernelExprV2CheckBinderWith smaller whnf
                              nextContext state root name domain body binderInfo false
                        | PsKernelExprV2Node.app fn arg =>
                            psKernelExprV2CheckApplicationWith smaller whnf
                              nextContext state root fn arg
                        | _ => Option.none

def psKernelExprV2TryCheckWithFuel
    (fuel : Nat) (context : PsKernelCheckerContext)
    (arena : PsKernelExprV2PagedArena) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2PagedArena Nat)) :=
  match context.localContext.decls with
  | List.cons _ _ => Option.none
  | List.nil =>
      let whnf :=
        fun (nextContext : PsKernelCheckerContext)
            (nextState : PsKernelExprV2WhnfState) (nextRoot : Nat) =>
          let worker := psKernelExprV2TryWhnfStateWithFuel fuel;
          worker nextContext nextState nextRoot;
      match psKernelExprV2TryCheckCoreWithFuel fuel whnf
          (psKernelExprV2CheckContextEmpty context)
          (psKernelExprV2CheckStateEmpty arena) root with
      | Option.none => Option.none
      | Option.some attempted =>
          match attempted with
          | Except.error error => Option.some (Except.error error)
          | Except.ok checked =>
              let state := Prod.fst checked;
              Option.some (Except.ok (Prod.mk state.whnf.arena (Prod.snd checked)))
