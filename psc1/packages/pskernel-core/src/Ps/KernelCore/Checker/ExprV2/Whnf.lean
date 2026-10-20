import Ps.KernelCore.Checker.Context
import Ps.KernelCore.Checker.ExprV2.Beta
import Ps.KernelCore.Checker.ExprV2.WhnfState

/-
DAG terminal/metadata/beta/zeta WHNF after complete checking of a canonical
arena. This fragment implements the public operation's cheapRec=false and
cheapProj=false core calls. Every core entry checks depth before inspecting
syntax or its cache; the public terminal and metadata cases retain their
original fuel/depth ordering.

Operation-owned core state preserves cache results from function-position
normalization. Both function and rebuilt-result core calls receive the same
original predecessor budget. Hash collisions and distinct alpha-equivalent
IDs are resolved by the production structural comparator. Cache hits return
the stored result syntax, exactly as the original expression map does.

No local context is extended and no environment declaration changes during
this operation. FVar-containing keys are ineligible. Local let values,
constants, stuck applications, recursors, projections and primitives still
request complete-checker fallback. Successful results cannot trigger the
public Nat/delta pipeline. No cache is returned by the public DAG wrapper.
-/

def psKernelExprV2WhnfFinishAttempt
    (source : Nat)
    (attempt : Option (Except String (Prod PsKernelExprV2WhnfState Nat))) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match attempt with
  | Option.none => Option.none
  | Option.some result =>
      match result with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          Option.some
            (psKernelExprV2WhnfCoreFinish
              (Prod.fst reduced) source (Prod.snd reduced))

def psKernelExprV2TryWhnfCompositeWith
    (recurse : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (root : Nat) (entry : PsKernelExprV2Entry) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match entry.node with
  | PsKernelExprV2Node.letE _ _ value body _ =>
      match psKernelExprV2TransformOnCanonical
          (PsKernelExprV2Transform.instantiate 0 (List.cons value List.nil))
          state.arena body 0 with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          psKernelExprV2WhnfFinishAttempt root
            (recurse context
              (psKernelExprV2WhnfStateWithArena state (Prod.fst reduced))
              (Prod.snd reduced))
  | PsKernelExprV2Node.app _ _ =>
      match psKernelExprV2TransformAppSpineOnCanonical state.arena root with
      | Except.error error => Option.some (Except.error error)
      | Except.ok spine =>
          match recurse context state (Prod.fst spine) with
          | Option.none => Option.none
          | Option.some attemptedFn =>
              match attemptedFn with
              | Except.error error => Option.some (Except.error error)
              | Except.ok fnResult =>
                  let fnState := Prod.fst fnResult;
                  let fn := Prod.snd fnResult;
                  match psKernelExprV2PagedRequire fnState.arena fn with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok fnEntry =>
                      match fnEntry.node with
                      | PsKernelExprV2Node.lam _ _ _ _ =>
                          match psKernelExprV2BetaSpinePlanOnCanonical
                              fnState.arena fn (Prod.snd spine) with
                          | Except.error error => Option.some (Except.error error)
                          | Except.ok selected =>
                              match selected with
                              | Option.none => Option.none
                              | Option.some plan =>
                                  match psKernelExprV2BetaSpineApplyOnCanonical
                                      fnState.arena plan with
                                  | Except.error error => Option.some (Except.error error)
                                  | Except.ok rebuilt =>
                                      psKernelExprV2WhnfFinishAttempt root
                                        (recurse context
                                          (psKernelExprV2WhnfStateWithArena fnState
                                            (Prod.fst rebuilt))
                                          (Prod.snd rebuilt))
                      | _ => Option.none
  | _ => Option.none

def psKernelExprV2TryWhnfCoreStateWithFuel
    (fuel : Nat) :
    PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (_context : PsKernelCheckerContext)
          (_state : PsKernelExprV2WhnfState) (_root : Nat) =>
        Option.some (Except.error "kernel reduction budget exhausted")
  | Nat.succ remaining =>
      let smaller :=
        fun (nextContext : PsKernelCheckerContext)
            (nextState : PsKernelExprV2WhnfState) (nextRoot : Nat) =>
          let recur := psKernelExprV2TryWhnfCoreStateWithFuel remaining;
          recur nextContext nextState nextRoot;
      fun (context : PsKernelCheckerContext)
          (state : PsKernelExprV2WhnfState) (root : Nat) =>
        match psKernelCheckerContextEnterRecDepth context with
        | Except.error error => Option.some (Except.error error)
        | Except.ok nextContext =>
            match psKernelExprV2PagedRequire state.arena root with
            | Except.error error => Option.some (Except.error error)
            | Except.ok entry =>
                match entry.node with
                | PsKernelExprV2Node.bvar _ => Option.some (Except.ok (Prod.mk state root))
                | PsKernelExprV2Node.mvar _ => Option.some (Except.ok (Prod.mk state root))
                | PsKernelExprV2Node.sort _ => Option.some (Except.ok (Prod.mk state root))
                | PsKernelExprV2Node.forallE _ _ _ _ => Option.some (Except.ok (Prod.mk state root))
                | PsKernelExprV2Node.lam _ _ _ _ => Option.some (Except.ok (Prod.mk state root))
                | PsKernelExprV2Node.lit _ => Option.some (Except.ok (Prod.mk state root))
                | PsKernelExprV2Node.mdata _ body => smaller nextContext state body
                | PsKernelExprV2Node.fvar name =>
                    match psKernelLocalContextFind nextContext.localContext name with
                    | Option.none => Option.some (Except.ok (Prod.mk state root))
                    | Option.some declaration =>
                        match psKernelLocalDeclValue declaration with
                        | Option.none => Option.some (Except.ok (Prod.mk state root))
                        | Option.some _ => Option.none
                | PsKernelExprV2Node.const _ _ => Option.none
                | _ =>
                    match psKernelExprV2WhnfCacheFind state root entry with
                    | Except.error error => Option.some (Except.error error)
                    | Except.ok cached =>
                        match cached with
                        | Option.some result => Option.some (Except.ok (Prod.mk state result))
                        | Option.none =>
                            psKernelExprV2TryWhnfCompositeWith
                              smaller nextContext state root entry

def psKernelExprV2TryWhnfStateWithFuel
    (fuel : Nat) :
    PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (_context : PsKernelCheckerContext)
          (_state : PsKernelExprV2WhnfState) (_root : Nat) =>
        Option.some (Except.error "kernel reduction budget exhausted")
  | Nat.succ remaining =>
      let smaller :=
        fun (nextContext : PsKernelCheckerContext)
            (nextState : PsKernelExprV2WhnfState) (nextRoot : Nat) =>
          let recur := psKernelExprV2TryWhnfStateWithFuel remaining;
          recur nextContext nextState nextRoot;
      fun (context : PsKernelCheckerContext)
          (state : PsKernelExprV2WhnfState) (root : Nat) =>
        match psKernelExprV2PagedRequire state.arena root with
        | Except.error error => Option.some (Except.error error)
        | Except.ok entry =>
            match entry.node with
            | PsKernelExprV2Node.bvar _ => Option.some (Except.ok (Prod.mk state root))
            | PsKernelExprV2Node.mvar _ => Option.some (Except.ok (Prod.mk state root))
            | PsKernelExprV2Node.sort _ => Option.some (Except.ok (Prod.mk state root))
            | PsKernelExprV2Node.forallE _ _ _ _ => Option.some (Except.ok (Prod.mk state root))
            | PsKernelExprV2Node.lit _ => Option.some (Except.ok (Prod.mk state root))
            | PsKernelExprV2Node.mdata _ body => smaller context state body
            | PsKernelExprV2Node.fvar name =>
                match psKernelLocalContextFind context.localContext name with
                | Option.none => Option.some (Except.ok (Prod.mk state root))
                | Option.some declaration =>
                    match psKernelLocalDeclValue declaration with
                    | Option.none => Option.some (Except.ok (Prod.mk state root))
                    | Option.some _ => Option.none
            | _ =>
                psKernelExprV2TryWhnfCoreStateWithFuel remaining context state root

def psKernelExprV2TryWhnfWithFuel
    (fuel : Nat) :
    PsKernelCheckerContext -> PsKernelExprV2PagedArena -> Nat ->
    Option (Except String (Prod PsKernelExprV2PagedArena Nat)) :=
  fun (context : PsKernelCheckerContext)
      (arena : PsKernelExprV2PagedArena) (root : Nat) =>
    match psKernelExprV2TryWhnfStateWithFuel fuel context
        (psKernelExprV2WhnfStateEmpty arena) root with
    | Option.none => Option.none
    | Option.some attempted =>
        match attempted with
        | Except.error error => Option.some (Except.error error)
        | Except.ok reduced =>
            let state := Prod.fst reduced;
            Option.some (Except.ok (Prod.mk state.arena (Prod.snd reduced)))

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
