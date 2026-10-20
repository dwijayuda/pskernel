import Ps.KernelCore.Checker.Context
import Ps.KernelCore.Checker.ExprV2.Beta

/-
DAG terminal/metadata/zeta/syntactic-lambda-beta WHNF, called after complete checking on a canonical
arena. Public metadata recursion does not enter the depth guard. Every core
entry does, and consumes its own original core budget. Zeta substitution uses
its original sufficient transformation budget, independently of checker fuel.

Every handled application has a syntactic lambda head. Its function-core
visit is terminal and publishes no cache; the result-core visit continues
the reduction path. Both visits retain the original predecessor fuel and
depth. Other function heads request fallback because their normalization can
publish caches needed by later low-fuel operations. Terminal results cannot
trigger Nat or definition unfolding. Unsupported forms return none and the
complete checker restarts with the original expression and resources.
-/
def psKernelExprV2TryWhnfCoreWithFuel
    (fuel : Nat) :
    PsKernelCheckerContext -> PsKernelExprV2PagedArena -> Nat ->
    Option (Except String (PsKernelExprV2PagedArena × Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (_context : PsKernelCheckerContext)
          (_arena : PsKernelExprV2PagedArena) (_root : Nat) =>
        Option.some (Except.error "kernel reduction budget exhausted")
  | Nat.succ remaining =>
      let smaller :=
        fun (nextContext : PsKernelCheckerContext)
            (nextArena : PsKernelExprV2PagedArena) (nextRoot : Nat) =>
          let recur := psKernelExprV2TryWhnfCoreWithFuel remaining;
          recur nextContext nextArena nextRoot;
      fun (context : PsKernelCheckerContext)
          (arena : PsKernelExprV2PagedArena) (root : Nat) =>
        match psKernelCheckerContextEnterRecDepth context with
        | Except.error error => Option.some (Except.error error)
        | Except.ok nextContext =>
            match psKernelExprV2PagedRequire arena root with
            | Except.error error => Option.some (Except.error error)
            | Except.ok entry =>
                match entry.node with
                | PsKernelExprV2Node.bvar _ => Option.some (Except.ok (Prod.mk arena root))
                | PsKernelExprV2Node.mvar _ => Option.some (Except.ok (Prod.mk arena root))
                | PsKernelExprV2Node.sort _ => Option.some (Except.ok (Prod.mk arena root))
                | PsKernelExprV2Node.forallE _ _ _ _ => Option.some (Except.ok (Prod.mk arena root))
                | PsKernelExprV2Node.lam _ _ _ _ => Option.some (Except.ok (Prod.mk arena root))
                | PsKernelExprV2Node.lit _ => Option.some (Except.ok (Prod.mk arena root))
                | PsKernelExprV2Node.mdata _ body => smaller nextContext arena body
                | PsKernelExprV2Node.letE _ _ value body _ =>
                    match psKernelExprV2TransformOnCanonical
                        (PsKernelExprV2Transform.instantiate 0 (List.cons value List.nil))
                        arena body 0 with
                    | Except.error error => Option.some (Except.error error)
                    | Except.ok reduced =>
                        smaller nextContext (Prod.fst reduced) (Prod.snd reduced)
                | PsKernelExprV2Node.app _ _ =>
                    match psKernelExprV2TransformAppSpineOnCanonical arena root with
                    | Except.error error => Option.some (Except.error error)
                    | Except.ok spine =>
                        let head := Prod.fst spine;
                        match psKernelExprV2PagedRequire arena head with
                        | Except.error error => Option.some (Except.error error)
                        | Except.ok headEntry =>
                            match headEntry.node with
                            | PsKernelExprV2Node.lam _ _ _ _ =>
                                match smaller nextContext arena head with
                                | Option.none => Option.none
                                | Option.some attempted =>
                                    match attempted with
                                    | Except.error error => Option.some (Except.error error)
                                    | Except.ok fnResult =>
                                        match psKernelExprV2BetaSpinePlanOnCanonical
                                            (Prod.fst fnResult) (Prod.snd fnResult)
                                            (Prod.snd spine) with
                                        | Except.error error => Option.some (Except.error error)
                                        | Except.ok planned =>
                                            match planned with
                                            | Option.none => Option.none
                                            | Option.some plan =>
                                                match psKernelExprV2BetaSpineApplyOnCanonical
                                                    (Prod.fst fnResult) plan with
                                                | Except.error error => Option.some (Except.error error)
                                                | Except.ok rebuilt =>
                                                    smaller nextContext
                                                      (Prod.fst rebuilt) (Prod.snd rebuilt)
                            | _ => Option.none
                | _ => Option.none

def psKernelExprV2TryWhnfWithFuel
    (fuel : Nat) :
    PsKernelCheckerContext -> PsKernelExprV2PagedArena -> Nat ->
    Option (Except String (PsKernelExprV2PagedArena × Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (_context : PsKernelCheckerContext)
          (_arena : PsKernelExprV2PagedArena) (_root : Nat) =>
        Option.some (Except.error "kernel reduction budget exhausted")
  | Nat.succ remaining =>
      let smaller :=
        fun (nextContext : PsKernelCheckerContext)
            (nextArena : PsKernelExprV2PagedArena) (nextRoot : Nat) =>
          let recur := psKernelExprV2TryWhnfWithFuel remaining;
          recur nextContext nextArena nextRoot;
      fun (context : PsKernelCheckerContext)
          (arena : PsKernelExprV2PagedArena) (root : Nat) =>
        match psKernelExprV2PagedRequire arena root with
        | Except.error error => Option.some (Except.error error)
        | Except.ok entry =>
            match entry.node with
            | PsKernelExprV2Node.bvar _ => Option.some (Except.ok (Prod.mk arena root))
            | PsKernelExprV2Node.mvar _ => Option.some (Except.ok (Prod.mk arena root))
            | PsKernelExprV2Node.sort _ => Option.some (Except.ok (Prod.mk arena root))
            | PsKernelExprV2Node.forallE _ _ _ _ => Option.some (Except.ok (Prod.mk arena root))
            | PsKernelExprV2Node.lit _ => Option.some (Except.ok (Prod.mk arena root))
            | PsKernelExprV2Node.mdata _ body => smaller context arena body
            | PsKernelExprV2Node.fvar _ => Option.none
            | _ => psKernelExprV2TryWhnfCoreWithFuel remaining context arena root

/-
The same-arena identity shortcut runs only after both full public checks.
It retains IsDefEqWithFuel's entry fuel and recursion-depth checks. Its
discarded fresh cache state cannot authorize a different operation.
-/
def psKernelExprV2CheckedIdentity
    (fuel : Nat) (context : PsKernelCheckerContext) :
    Except String Bool :=
  if Nat.beq fuel 0 then
    Except.error "kernel definitional equality budget exhausted"
  else
    match psKernelCheckerContextEnterRecDepth context with
    | Except.error error => Except.error error
    | Except.ok _ => Except.ok true
