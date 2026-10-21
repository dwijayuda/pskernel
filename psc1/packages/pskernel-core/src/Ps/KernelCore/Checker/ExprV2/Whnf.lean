import Ps.KernelCore.Checker.ExprV2.Beta
import Ps.KernelCore.Checker.ExprV2.Nat
import Ps.KernelCore.Checker.ExprV2.Projection
import Ps.KernelCore.Checker.ExprV2.Delta
import Ps.KernelCore.Checker.ExprV2.Quot
import Ps.KernelCore.Checker.ExprV2.Recursor

/-
Checked DAG WHNF for terminal/metadata/beta/zeta, inert applications,
constructor projection, Nat, Quot, owned non-K constructor iota and same-batch
admitted definitions.

The operation owns distinct core/public caches in one append-only arena.
Core entry checks fuel and depth before syntax/cache. Public entry keeps
the original terminal/metadata ordering and checks its cache before core.
The public and recursor callbacks remain fixed during structural recursion;
function/result core calls consume the original predecessor budget.

Quot uses the separately owned bounded-recursor callback, with its own
predecessor public-WHNF and recursor budgets, exactly as the reference knot.
K/structure recursor conversion, missing generated-rule owners, absent owning
definition bodies, mixed legacy typed-local contexts and String expansion request
the complete original operation. No recursive expression is imported here.
-/

def psKernelExprV2WhnfCoreFinishMode
    (cheapProj : Bool) (state : PsKernelExprV2WhnfState)
    (source result : Nat) :
    Except String (Prod PsKernelExprV2WhnfState Nat) :=
  if cheapProj then Except.ok (Prod.mk state result)
  else psKernelExprV2WhnfCoreFinish state source result

def psKernelExprV2WhnfFinishAttempt
    (source : Nat) (cheapProj : Bool)
    (attempt : Option (Except String (Prod PsKernelExprV2WhnfState Nat))) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match attempt with
  | Option.none => Option.none
  | Option.some result =>
      match result with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          Option.some
            (psKernelExprV2WhnfCoreFinishMode cheapProj
              (Prod.fst reduced) source (Prod.snd reduced))

def psKernelExprV2TryWhnfProjectionWith
    (recurse : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (root : Nat) (typeName : PsKernelName) (index structValue : Nat)
    (cheapProj : Bool) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  let majorResult : Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
    if cheapProj then recurse context state structValue
    else publicWhnf context state structValue;
  match majorResult with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          let next := Prod.fst reduced;
          let major := Prod.snd reduced;
          match psKernelExprV2PagedRequire next.arena major with
          | Except.error error => Option.some (Except.error error)
          | Except.ok entry =>
              let needsStringExpansion : Bool :=
                match entry.node with
                | PsKernelExprV2Node.lit literal =>
                    match literal with
                    | PsKernelLiteral.str _ => true
                    | PsKernelLiteral.nat _ => false
                | _ => false;
              if needsStringExpansion then Option.none
              else
                match psKernelExprV2ReduceProjOnCanonical
                    context next.arena typeName index major with
                | Except.error error => Option.some (Except.error error)
                | Except.ok selected =>
                    match selected with
                    | Option.none =>
                        Option.some (psKernelExprV2WhnfCoreFinishMode cheapProj next root root)
                    | Option.some value =>
                        psKernelExprV2WhnfFinishAttempt root cheapProj
                          (recurse context next value)

def psKernelExprV2TryWhnfAppWithReducer
    (recurse : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (reduceRecursor : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (root : Nat) (cheapProj : Bool) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
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
                          | Option.none => Option.some (Except.ok (Prod.mk fnState root))
                          | Option.some plan =>
                              match psKernelExprV2BetaSpineApplyOnCanonical
                                  fnState.arena plan with
                              | Except.error error => Option.some (Except.error error)
                              | Except.ok rebuilt =>
                                  psKernelExprV2WhnfFinishAttempt root cheapProj
                                    (recurse context
                                      (psKernelExprV2WhnfStateWithArena fnState
                                        (Prod.fst rebuilt))
                                      (Prod.snd rebuilt))
                  | _ =>
                      match psKernelExprV2PagedEqOnCanonical
                          fnState.arena fn (Prod.fst spine) with
                      | Except.error error => Option.some (Except.error error)
                      | Except.ok unchanged =>
                          if unchanged then
                            match reduceRecursor context fnState root cheapProj with
                            | Option.none => Option.none
                            | Option.some attemptedReduction =>
                                match attemptedReduction with
                                | Except.error error => Option.some (Except.error error)
                                | Except.ok reduced =>
                                    match Prod.snd reduced with
                                    | Option.none =>
                                        Option.some (Except.ok (Prod.mk (Prod.fst reduced) root))
                                    | Option.some value =>
                                        recurse context (Prod.fst reduced) value
                          else
                            match psKernelExprV2TransformApplyArgsOnCanonical
                                (Prod.snd spine) fnState.arena fn with
                            | Except.error error => Option.some (Except.error error)
                            | Except.ok rebuilt =>
                                psKernelExprV2WhnfFinishAttempt root cheapProj
                                  (recurse context
                                    (psKernelExprV2WhnfStateWithArena fnState
                                      (Prod.fst rebuilt))
                                    (Prod.snd rebuilt))

def psKernelExprV2TryWhnfCompositeWithReducer
    (recurse : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (reduceRecursor : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (root : Nat) (entry : PsKernelExprV2Entry) (cheapProj : Bool) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match entry.node with
  | PsKernelExprV2Node.letE _ _ value body _ =>
      match psKernelExprV2TransformOnCanonical
          (PsKernelExprV2Transform.instantiate 0 (List.cons value List.nil))
          state.arena body 0 with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          psKernelExprV2WhnfFinishAttempt root cheapProj
            (recurse context
              (psKernelExprV2WhnfStateWithArena state (Prod.fst reduced))
              (Prod.snd reduced))
  | PsKernelExprV2Node.proj typeName index structValue =>
      psKernelExprV2TryWhnfProjectionWith
        recurse publicWhnf context state root typeName index structValue cheapProj
  | PsKernelExprV2Node.app _ _ =>
      psKernelExprV2TryWhnfAppWithReducer recurse reduceRecursor context state root cheapProj
  | _ => Option.none

def psKernelExprV2TryWhnfCoreModeWithReducerFuel
    (fuel : Nat) :
    Bool -> (PsKernelName -> Option Nat) ->
    (PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat))) ->
    (PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat)))) ->
    PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (_cheapProj : Bool) (_localValue : PsKernelName -> Option Nat)
          (_publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
          Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (_reduceRecursor : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
            Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))))
          (_context : PsKernelCheckerContext)
          (_state : PsKernelExprV2WhnfState) (_root : Nat) =>
        Option.some (Except.error "kernel reduction budget exhausted")
  | Nat.succ remaining =>
      fun (cheapProj : Bool) (localValue : PsKernelName -> Option Nat)
          (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
          Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (reduceRecursor : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
            Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))))
          (context : PsKernelCheckerContext)
          (state : PsKernelExprV2WhnfState) (root : Nat) =>
        let smaller :=
          fun (nextContext : PsKernelCheckerContext)
              (nextState : PsKernelExprV2WhnfState) (nextRoot : Nat) =>
            let recur := psKernelExprV2TryWhnfCoreModeWithReducerFuel remaining;
            recur cheapProj localValue publicWhnf reduceRecursor nextContext nextState nextRoot;
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
                | PsKernelExprV2Node.const _ _ => Option.some (Except.ok (Prod.mk state root))
                | PsKernelExprV2Node.lam _ _ _ _ => Option.some (Except.ok (Prod.mk state root))
                | PsKernelExprV2Node.lit _ => Option.some (Except.ok (Prod.mk state root))
                | PsKernelExprV2Node.mdata _ body => smaller nextContext state body
                | PsKernelExprV2Node.fvar name =>
                    match localValue name with
                    | Option.some value => smaller nextContext state value
                    | Option.none =>
                        match psKernelLocalContextFind nextContext.localContext name with
                        | Option.none => Option.some (Except.ok (Prod.mk state root))
                        | Option.some declaration =>
                            match psKernelLocalDeclValue declaration with
                            | Option.none => Option.some (Except.ok (Prod.mk state root))
                            | Option.some _ => Option.none
                | _ =>
                    match psKernelExprV2WhnfCacheFind state root entry with
                    | Except.error error => Option.some (Except.error error)
                    | Except.ok cached =>
                        match cached with
                        | Option.some result => Option.some (Except.ok (Prod.mk state result))
                        | Option.none =>
                            psKernelExprV2TryWhnfCompositeWithReducer
                              smaller publicWhnf reduceRecursor nextContext state root entry cheapProj

/- Compatibility wrapper keeps the existing staged core entry and full policy. -/
def psKernelExprV2WhnfPublicFinishAttempt
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
            (psKernelExprV2WhnfPublicFinish
              (Prod.fst reduced) source (Prod.snd reduced))

def psKernelExprV2TryWhnfAfterCoreWith
    (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (original core : Nat) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match psKernelExprV2TryReduceNatWith publicWhnf context state core with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          let next := Prod.fst reduced;
          match Prod.snd reduced with
          | Option.some value =>
              Option.some (psKernelExprV2WhnfPublicFinish next original value)
          | Option.none =>
              match psKernelExprV2TryUnfoldDefinition context next core with
              | Option.none => Option.none
              | Option.some attemptedDelta =>
                  match attemptedDelta with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok unfolded =>
                      let deltaState := Prod.fst unfolded;
                      match Prod.snd unfolded with
                      | Option.none =>
                          Option.some
                            (psKernelExprV2WhnfPublicFinish deltaState original core)
                      | Option.some value =>
                          psKernelExprV2WhnfPublicFinishAttempt original
                            (publicWhnf context deltaState value)

def psKernelExprV2TryWhnfPublicNonterminalWith
    (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (coreWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (root : Nat) (entry : PsKernelExprV2Entry) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match psKernelExprV2WhnfPublicCacheFind state root entry with
  | Except.error error => Option.some (Except.error error)
  | Except.ok cached =>
      match cached with
      | Option.some result => Option.some (Except.ok (Prod.mk state result))
      | Option.none =>
          match coreWhnf context state root with
          | Option.none => Option.none
          | Option.some attempted =>
              match attempted with
              | Except.error error => Option.some (Except.error error)
              | Except.ok reduced =>
                  psKernelExprV2TryWhnfAfterCoreWith
                    publicWhnf context (Prod.fst reduced) root (Prod.snd reduced)

def psKernelExprV2TryWhnfStateWithReducerFuel
    (fuel : Nat) :
    (PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat)))) ->
    (PsKernelName -> Option Nat) ->
    PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (_reduceRecursor : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
            Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))))
          (_localValue : PsKernelName -> Option Nat)
          (_context : PsKernelCheckerContext)
          (_state : PsKernelExprV2WhnfState) (_root : Nat) =>
        Option.some (Except.error "kernel reduction budget exhausted")
  | Nat.succ remaining =>
      fun (reduceRecursor : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
            Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))))
          (localValue : PsKernelName -> Option Nat)
          (context : PsKernelCheckerContext)
          (state : PsKernelExprV2WhnfState) (root : Nat) =>
        let smaller :=
          fun (nextContext : PsKernelCheckerContext)
              (nextState : PsKernelExprV2WhnfState) (nextRoot : Nat) =>
            let recur := psKernelExprV2TryWhnfStateWithReducerFuel remaining;
            recur reduceRecursor localValue nextContext nextState nextRoot;
        let core :=
          fun (nextContext : PsKernelCheckerContext)
              (nextState : PsKernelExprV2WhnfState) (nextRoot : Nat) =>
            let worker := psKernelExprV2TryWhnfCoreModeWithReducerFuel remaining;
            worker false localValue smaller reduceRecursor nextContext nextState nextRoot;
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
                match localValue name with
                | Option.some _ =>
                    psKernelExprV2TryWhnfPublicNonterminalWith
                      smaller core context state root entry
                | Option.none =>
                    match psKernelLocalContextFind context.localContext name with
                    | Option.none => Option.some (Except.ok (Prod.mk state root))
                    | Option.some declaration =>
                        match psKernelLocalDeclValue declaration with
                        | Option.none => Option.some (Except.ok (Prod.mk state root))
                        | Option.some _ => Option.none
            | _ =>
                psKernelExprV2TryWhnfPublicNonterminalWith
                  smaller core context state root entry

/- The recursor callback has its own fixed owner. Structural/public WHNF
   recursion never decrements this callback's budget. Entering this callback
   spends exactly one predecessor before normalizing a Quot major premise. -/
def psKernelExprV2TryReduceRecursorWithLocalValuesFuel
    (fuel : Nat) :
    (PsKernelName -> Option Nat) ->
    PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
    Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))) :=
  match fuel with
  | Nat.zero =>
      fun (_localValue : PsKernelName -> Option Nat)
          (_context : PsKernelCheckerContext) (_state : PsKernelExprV2WhnfState)
          (_root : Nat) (_cheapProj : Bool) =>
        Option.some (Except.error "kernel recursor budget exhausted")
  | Nat.succ remaining =>
      fun (localValue : PsKernelName -> Option Nat)
          (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
          (root : Nat) (_cheapProj : Bool) =>
        let reducer :=
          fun (nextContext : PsKernelCheckerContext) (nextState : PsKernelExprV2WhnfState)
              (nextRoot : Nat) (nextCheapProj : Bool) =>
            let recur := psKernelExprV2TryReduceRecursorWithLocalValuesFuel remaining;
            recur localValue nextContext nextState nextRoot nextCheapProj;
        let publicWhnf :=
          fun (nextContext : PsKernelCheckerContext) (nextState : PsKernelExprV2WhnfState)
              (nextRoot : Nat) =>
            let worker := psKernelExprV2TryWhnfStateWithReducerFuel remaining;
            worker reducer localValue nextContext nextState nextRoot;
        match psKernelExprV2TryReduceQuotWith publicWhnf context state root with
        | Option.none => Option.none
        | Option.some attempted =>
            match attempted with
            | Except.error error => Option.some (Except.error error)
            | Except.ok reduced =>
                match Prod.snd reduced with
                | Option.some _ => Option.some (Except.ok reduced)
                | Option.none =>
                    psKernelExprV2TryReduceInductiveRecursor
                      publicWhnf context (Prod.fst reduced) root

/- Compatibility helpers have no fuel owner argument. They preserve their
   earlier explicit refusal of active reduction and delegate structural work
   to the same implementation used by the owned checker. -/
def psKernelExprV2WhnfInertRecursor
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (root : Nat) (_cheapProj : Bool) :
    Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))) :=
  match psKernelExprV2TransformAppSpineOnCanonical state.arena root with
  | Except.error error => Option.some (Except.error error)
  | Except.ok spine =>
      match psKernelExprV2PagedRequire state.arena (Prod.fst spine) with
      | Except.error error => Option.some (Except.error error)
      | Except.ok head =>
          if psKernelExprV2WhnfRecursorInert context head.node then
            Option.some (Except.ok (Prod.mk state Option.none))
          else Option.none

def psKernelExprV2TryWhnfAppWith
    (recurse : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (root : Nat) (cheapProj : Bool) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  psKernelExprV2TryWhnfAppWithReducer recurse psKernelExprV2WhnfInertRecursor
    context state root cheapProj

def psKernelExprV2TryWhnfCompositeWith
    (recurse : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (root : Nat) (entry : PsKernelExprV2Entry) (cheapProj : Bool) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  psKernelExprV2TryWhnfCompositeWithReducer recurse publicWhnf psKernelExprV2WhnfInertRecursor
    context state root entry cheapProj

def psKernelExprV2TryWhnfCoreModeWithLocalValuesFuel
    (fuel : Nat) :
    Bool -> (PsKernelName -> Option Nat) ->
    (PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat))) ->
    PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (_cheapProj : Bool) (_localValue : PsKernelName -> Option Nat)
          (_publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
          Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (_context : PsKernelCheckerContext)
          (_state : PsKernelExprV2WhnfState) (_root : Nat) =>
        Option.some (Except.error "kernel reduction budget exhausted")
  | Nat.succ remaining =>
    fun (cheapProj : Bool) (localValue : PsKernelName -> Option Nat)
        (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
          Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
        (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState) (root : Nat) =>
      let reducer :=
        fun (nextContext : PsKernelCheckerContext) (nextState : PsKernelExprV2WhnfState)
            (nextRoot : Nat) (nextCheapProj : Bool) =>
          let worker := psKernelExprV2TryReduceRecursorWithLocalValuesFuel (Nat.succ remaining);
          worker localValue nextContext nextState nextRoot nextCheapProj;
      psKernelExprV2TryWhnfCoreModeWithReducerFuel (Nat.succ remaining)
        cheapProj localValue publicWhnf reducer context state root

def psKernelExprV2TryWhnfCoreWithLocalValuesFuel
    (fuel : Nat) :
    (PsKernelName -> Option Nat) ->
    (PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat))) ->
    PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (_localValue : PsKernelName -> Option Nat)
          (_publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
            Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (_context : PsKernelCheckerContext)
          (_state : PsKernelExprV2WhnfState) (_root : Nat) =>
        Option.some (Except.error "kernel reduction budget exhausted")
  | Nat.succ remaining =>
      fun (localValue : PsKernelName -> Option Nat)
          (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
            Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (context : PsKernelCheckerContext)
          (state : PsKernelExprV2WhnfState) (root : Nat) =>
        psKernelExprV2TryWhnfCoreModeWithLocalValuesFuel (Nat.succ remaining)
          false localValue publicWhnf context state root

def psKernelExprV2NoLocalValue
    (_name : PsKernelName) : Option Nat :=
  Option.none

def psKernelExprV2TryWhnfCoreWithPublicFuel
    (fuel : Nat) :
    (PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat))) ->
    PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (_publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
          Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (_context : PsKernelCheckerContext)
          (_state : PsKernelExprV2WhnfState) (_root : Nat) =>
        Option.some (Except.error "kernel reduction budget exhausted")
  | Nat.succ remaining =>
      fun (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
          Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
          (context : PsKernelCheckerContext)
          (state : PsKernelExprV2WhnfState) (root : Nat) =>
        psKernelExprV2TryWhnfCoreWithLocalValuesFuel (Nat.succ remaining)
          psKernelExprV2NoLocalValue publicWhnf context state root

/- Public staged ABI and original entry budget are retained. -/
def psKernelExprV2TryWhnfStateWithLocalValuesFuel
    (fuel : Nat) :
    (PsKernelName -> Option Nat) ->
    PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (_localValue : PsKernelName -> Option Nat)
          (_context : PsKernelCheckerContext)
          (_state : PsKernelExprV2WhnfState) (_root : Nat) =>
        Option.some (Except.error "kernel reduction budget exhausted")
  | Nat.succ remaining =>
    fun (localValue : PsKernelName -> Option Nat)
        (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState) (root : Nat) =>
      let reducer :=
        fun (nextContext : PsKernelCheckerContext) (nextState : PsKernelExprV2WhnfState)
            (nextRoot : Nat) (nextCheapProj : Bool) =>
          let worker := psKernelExprV2TryReduceRecursorWithLocalValuesFuel (Nat.succ remaining);
          worker localValue nextContext nextState nextRoot nextCheapProj;
      psKernelExprV2TryWhnfStateWithReducerFuel (Nat.succ remaining) reducer localValue context state root

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
      fun (context : PsKernelCheckerContext)
          (state : PsKernelExprV2WhnfState) (root : Nat) =>
        psKernelExprV2TryWhnfStateWithLocalValuesFuel (Nat.succ remaining)
          psKernelExprV2NoLocalValue context state root

def psKernelExprV2TryWhnfCoreStateWithFuel
    (fuel : Nat) (context : PsKernelCheckerContext)
    (state : PsKernelExprV2WhnfState) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  let publicWhnf :=
    fun (nextContext : PsKernelCheckerContext)
        (nextState : PsKernelExprV2WhnfState) (nextRoot : Nat) =>
      let worker := psKernelExprV2TryWhnfStateWithFuel fuel;
      worker nextContext nextState nextRoot;
  let core := psKernelExprV2TryWhnfCoreWithPublicFuel fuel;
  core publicWhnf context state root

def psKernelExprV2TryWhnfWithDeclarationsFuel
    (fuel : Nat) (context : PsKernelCheckerContext)
    (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2PagedArena Nat)) :=
  match psKernelExprV2TryWhnfStateWithFuel fuel context
      (psKernelExprV2WhnfStateForDeclarations arena declarations) root with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          let state := Prod.fst reduced;
          Option.some (Except.ok (Prod.mk state.arena (Prod.snd reduced)))

def psKernelExprV2TryWhnfWithFuel
    (fuel : Nat) (context : PsKernelCheckerContext)
    (arena : PsKernelExprV2PagedArena) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2PagedArena Nat)) :=
  psKernelExprV2TryWhnfWithDeclarationsFuel fuel context arena List.nil root
