import Ps.KernelCore.Checker.ExprV2.CheckCallbacks
import Ps.KernelCore.Checker.ExprV2.Beta
import Ps.KernelCore.Checker.ExprV2.Nat
import Ps.KernelCore.Checker.ExprV2.Projection
import Ps.KernelCore.Checker.ExprV2.String
import Ps.KernelCore.Checker.ExprV2.Delta

/-
The single full-state DAG WHNF engine. Every callback carries the complete
CheckState and the current typed CheckContext. Fresh names and inference/DefEq
caches stay with their owner; WhnfState remains the sole reduction-cache store.

This module is independent of DefEq and the bounded recursor knot: callers
supply fixed public-WHNF and recursor callbacks. Structural core/public calls
decrease only their own predecessor fuel. The local-value getter uses each
callback's current typed context; compatibility getters may ignore it.

Old WhnfState entry points adapt to this engine in Whnf.lean. Only pure arena
and cache operations are lifted through the nested WhnfState here.
-/

/- Partial cheap reductions must never publish into the full core cache. -/
def psKernelExprV2WhnfCoreCacheDisabled
    (cheapRec cheapProj : Bool) : Bool :=
  if cheapRec then true else cheapProj

def psKernelExprV2WhnfCoreOwnedFinishMode
    (cheapProj : Bool) (state : PsKernelExprV2CheckState)
    (source result : Nat) :
    Except String (Prod PsKernelExprV2CheckState Nat) :=
  if cheapProj then Except.ok (Prod.mk state result)
  else
    match psKernelExprV2WhnfCoreFinish state.whnf source result with
    | Except.error error => Except.error error
    | Except.ok reduced =>
        Except.ok (Prod.mk
          (psKernelExprV2CheckStateWithWhnf state (Prod.fst reduced))
          (Prod.snd reduced))

def psKernelExprV2WhnfPublicOwnedFinish
    (state : PsKernelExprV2CheckState) (source result : Nat) :
    Except String (Prod PsKernelExprV2CheckState Nat) :=
  match psKernelExprV2WhnfPublicFinish state.whnf source result with
  | Except.error error => Except.error error
  | Except.ok reduced =>
      Except.ok (Prod.mk
        (psKernelExprV2CheckStateWithWhnf state (Prod.fst reduced))
        (Prod.snd reduced))

def psKernelExprV2WhnfOwnedFinishAttempt
    (source : Nat) (cheapProj : Bool)
    (attempt : Option (Except String (Prod PsKernelExprV2CheckState Nat))) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match attempt with
  | Option.none => Option.none
  | Option.some result =>
      match result with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          Option.some
            (psKernelExprV2WhnfCoreOwnedFinishMode cheapProj
              (Prod.fst reduced) source (Prod.snd reduced))

/- String expansion preserves the V1 projection sequence: first reduce the
major according to cheapProj, then always invoke the supplied public WHNF on
its exact constructor translation. The complete owner returned by that call
feeds field selection and the final core recursion. -/
def psKernelExprV2WhnfProjectionExpandOwnedWith
    (publicWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (major : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match psKernelExprV2PagedRequire state.whnf.arena major with
  | Except.error error => Option.some (Except.error error)
  | Except.ok entry =>
      match entry.node with
      | PsKernelExprV2Node.lit literal =>
          match literal with
          | PsKernelLiteral.str value =>
              match psKernelExprV2StringLitToConstructorOnCanonical state.whnf.arena value with
              | Except.error error => Option.some (Except.error error)
              | Except.ok expanded =>
                  publicWhnf context
                    (psKernelExprV2CheckStateWithArena state (Prod.fst expanded))
                    (Prod.snd expanded)
          | PsKernelLiteral.nat _ => Option.some (Except.ok (Prod.mk state major))
      | _ => Option.some (Except.ok (Prod.mk state major))

def psKernelExprV2TryWhnfProjectionOwnedModeWith
    (recurse : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (publicWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root : Nat) (typeName : PsKernelName) (index structValue : Nat)
    (cheapRec cheapProj : Bool) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  let cacheDisabled := psKernelExprV2WhnfCoreCacheDisabled cheapRec cheapProj;
  let majorResult : Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
    if cheapProj then recurse context state structValue
    else publicWhnf context state structValue;
  match majorResult with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          match psKernelExprV2WhnfProjectionExpandOwnedWith
              publicWhnf context (Prod.fst reduced) (Prod.snd reduced) with
          | Option.none => Option.none
          | Option.some expandedAttempt =>
              match expandedAttempt with
              | Except.error error => Option.some (Except.error error)
              | Except.ok expanded =>
                  let next := Prod.fst expanded;
                  let major := Prod.snd expanded;
                  match psKernelExprV2ReduceProjOnCanonical
                      context.scalar next.whnf.arena typeName index major with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok selected =>
                      match selected with
                      | Option.none =>
                          Option.some (psKernelExprV2WhnfCoreOwnedFinishMode cacheDisabled next root root)
                      | Option.some value =>
                          psKernelExprV2WhnfOwnedFinishAttempt root cacheDisabled
                            (recurse context next value)

/- Retain the original raw callback ABI; its historical mode is cheapRec=false. -/
def psKernelExprV2TryWhnfProjectionOwnedWith
    (recurse : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (publicWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root : Nat) (typeName : PsKernelName) (index structValue : Nat)
    (cheapProj : Bool) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  psKernelExprV2TryWhnfProjectionOwnedModeWith recurse publicWhnf context state
    root typeName index structValue false cheapProj

def psKernelExprV2TryWhnfAppOwnedWithReducer
    (recurse : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (reduceRecursor : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Bool -> Bool ->
      Option (Except String (Prod PsKernelExprV2CheckState (Option Nat))))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root : Nat) (cheapRec cheapProj : Bool) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match psKernelExprV2TransformAppSpineOnCanonical state.whnf.arena root with
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
              match psKernelExprV2PagedRequire fnState.whnf.arena fn with
              | Except.error error => Option.some (Except.error error)
              | Except.ok fnEntry =>
                  match fnEntry.node with
                  | PsKernelExprV2Node.lam _ _ _ _ =>
                      match psKernelExprV2BetaSpinePlanOnCanonical
                          fnState.whnf.arena fn (Prod.snd spine) with
                      | Except.error error => Option.some (Except.error error)
                      | Except.ok selected =>
                          match selected with
                          | Option.none => Option.some (Except.ok (Prod.mk fnState root))
                          | Option.some plan =>
                              match psKernelExprV2BetaSpineApplyOnCanonical
                                  fnState.whnf.arena plan with
                              | Except.error error => Option.some (Except.error error)
                              | Except.ok rebuilt =>
                                  psKernelExprV2WhnfOwnedFinishAttempt root (psKernelExprV2WhnfCoreCacheDisabled cheapRec cheapProj)
                                    (recurse context
                                      (psKernelExprV2CheckStateWithArena fnState
                                        (Prod.fst rebuilt))
                                      (Prod.snd rebuilt))
                  | _ =>
                      match psKernelExprV2PagedEqOnCanonical
                          fnState.whnf.arena fn (Prod.fst spine) with
                      | Except.error error => Option.some (Except.error error)
                      | Except.ok unchanged =>
                          if unchanged then
                            match reduceRecursor context fnState root cheapRec cheapProj with
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
                                (Prod.snd spine) fnState.whnf.arena fn with
                            | Except.error error => Option.some (Except.error error)
                            | Except.ok rebuilt =>
                                psKernelExprV2WhnfOwnedFinishAttempt root (psKernelExprV2WhnfCoreCacheDisabled cheapRec cheapProj)
                                  (recurse context
                                    (psKernelExprV2CheckStateWithArena fnState
                                      (Prod.fst rebuilt))
                                    (Prod.snd rebuilt))

def psKernelExprV2TryWhnfCompositeOwnedWithReducer
    (recurse : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (publicWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (reduceRecursor : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Bool -> Bool ->
      Option (Except String (Prod PsKernelExprV2CheckState (Option Nat))))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root : Nat) (entry : PsKernelExprV2Entry) (cheapRec cheapProj : Bool) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match entry.node with
  | PsKernelExprV2Node.letE _ _ value body _ =>
      match psKernelExprV2TransformOnCanonical
          (PsKernelExprV2Transform.instantiate 0 (List.cons value List.nil))
          state.whnf.arena body 0 with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          psKernelExprV2WhnfOwnedFinishAttempt root (psKernelExprV2WhnfCoreCacheDisabled cheapRec cheapProj)
            (recurse context
              (psKernelExprV2CheckStateWithArena state (Prod.fst reduced))
              (Prod.snd reduced))
  | PsKernelExprV2Node.proj typeName index structValue =>
      psKernelExprV2TryWhnfProjectionOwnedModeWith
        recurse publicWhnf context state root typeName index structValue cheapRec cheapProj
  | PsKernelExprV2Node.app _ _ =>
      psKernelExprV2TryWhnfAppOwnedWithReducer recurse reduceRecursor context state root cheapRec cheapProj
  | _ => Option.none

def psKernelExprV2TryWhnfCoreOwnedModeWithReducerFuel
    (fuel : Nat) :
    Bool -> Bool -> (PsKernelExprV2CheckContext -> PsKernelName -> Option Nat) ->
    (PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
    (PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Bool -> Bool ->
      Option (Except String (Prod PsKernelExprV2CheckState (Option Nat)))) ->
    PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (_cheapRec _cheapProj : Bool) (_localValue : PsKernelExprV2CheckContext -> PsKernelName -> Option Nat)
          (_publicWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
          (_reduceRecursor : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Bool -> Bool ->
            Option (Except String (Prod PsKernelExprV2CheckState (Option Nat))))
          (_context : PsKernelExprV2CheckContext)
          (_state : PsKernelExprV2CheckState) (_root : Nat) =>
        Option.some (Except.error "kernel reduction budget exhausted")
  | Nat.succ remaining =>
      fun (cheapRec cheapProj : Bool) (localValue : PsKernelExprV2CheckContext -> PsKernelName -> Option Nat)
          (publicWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
          (reduceRecursor : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Bool -> Bool ->
            Option (Except String (Prod PsKernelExprV2CheckState (Option Nat))))
          (context : PsKernelExprV2CheckContext)
          (state : PsKernelExprV2CheckState) (root : Nat) =>
        let smaller :=
          fun (nextContext : PsKernelExprV2CheckContext)
              (nextState : PsKernelExprV2CheckState) (nextRoot : Nat) =>
            let recur := psKernelExprV2TryWhnfCoreOwnedModeWithReducerFuel remaining;
            recur cheapRec cheapProj localValue publicWhnf reduceRecursor nextContext nextState nextRoot;
        match psKernelExprV2CheckContextEnterRecDepth context with
        | Except.error error => Option.some (Except.error error)
        | Except.ok nextContext =>
            match psKernelExprV2PagedRequire state.whnf.arena root with
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
                    match localValue nextContext name with
                    | Option.some value => smaller nextContext state value
                    | Option.none =>
                        match psKernelLocalContextFind nextContext.scalar.localContext name with
                        | Option.none => Option.some (Except.ok (Prod.mk state root))
                        | Option.some declaration =>
                            match psKernelLocalDeclValue declaration with
                            | Option.none => Option.some (Except.ok (Prod.mk state root))
                            | Option.some _ => Option.none
                | _ =>
                    match psKernelExprV2WhnfCacheFind state.whnf root entry with
                    | Except.error error => Option.some (Except.error error)
                    | Except.ok cached =>
                        match cached with
                        | Option.some result => Option.some (Except.ok (Prod.mk state result))
                        | Option.none =>
                            psKernelExprV2TryWhnfCompositeOwnedWithReducer
                              smaller publicWhnf reduceRecursor nextContext state root entry cheapRec cheapProj

def psKernelExprV2WhnfPublicOwnedFinishAttempt
    (source : Nat)
    (attempt : Option (Except String (Prod PsKernelExprV2CheckState Nat))) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match attempt with
  | Option.none => Option.none
  | Option.some result =>
      match result with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          Option.some
            (psKernelExprV2WhnfPublicOwnedFinish
              (Prod.fst reduced) source (Prod.snd reduced))

def psKernelExprV2TryWhnfOwnedAfterCoreWith
    (publicWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (original core : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match psKernelExprV2TryReduceNatOwnedWith publicWhnf context state core with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          let next := Prod.fst reduced;
          match Prod.snd reduced with
          | Option.some value =>
              Option.some (psKernelExprV2WhnfPublicOwnedFinish next original value)
          | Option.none =>
              match psKernelExprV2LiftOptionalWhnfAttempt next
                  (psKernelExprV2TryUnfoldDefinition context.scalar next.whnf core) with
              | Option.none => Option.none
              | Option.some attemptedDelta =>
                  match attemptedDelta with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok unfolded =>
                      let deltaState := Prod.fst unfolded;
                      match Prod.snd unfolded with
                      | Option.none =>
                          Option.some
                            (psKernelExprV2WhnfPublicOwnedFinish deltaState original core)
                      | Option.some value =>
                          psKernelExprV2WhnfPublicOwnedFinishAttempt original
                            (publicWhnf context deltaState value)

def psKernelExprV2TryWhnfPublicOwnedNonterminalWith
    (publicWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root : Nat) (entry : PsKernelExprV2Entry) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match psKernelExprV2WhnfPublicCacheFind state.whnf root entry with
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
                  psKernelExprV2TryWhnfOwnedAfterCoreWith
                    publicWhnf context (Prod.fst reduced) root (Prod.snd reduced)

def psKernelExprV2TryWhnfOwnedWithReducerFuel
    (fuel : Nat) :
    (PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Bool -> Bool ->
      Option (Except String (Prod PsKernelExprV2CheckState (Option Nat)))) ->
    (PsKernelExprV2CheckContext -> PsKernelName -> Option Nat) ->
    PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (_reduceRecursor : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Bool -> Bool ->
            Option (Except String (Prod PsKernelExprV2CheckState (Option Nat))))
          (_localValue : PsKernelExprV2CheckContext -> PsKernelName -> Option Nat)
          (_context : PsKernelExprV2CheckContext)
          (_state : PsKernelExprV2CheckState) (_root : Nat) =>
        Option.some (Except.error "kernel reduction budget exhausted")
  | Nat.succ remaining =>
      fun (reduceRecursor : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Bool -> Bool ->
            Option (Except String (Prod PsKernelExprV2CheckState (Option Nat))))
          (localValue : PsKernelExprV2CheckContext -> PsKernelName -> Option Nat)
          (context : PsKernelExprV2CheckContext)
          (state : PsKernelExprV2CheckState) (root : Nat) =>
        let smaller :=
          fun (nextContext : PsKernelExprV2CheckContext)
              (nextState : PsKernelExprV2CheckState) (nextRoot : Nat) =>
            let recur := psKernelExprV2TryWhnfOwnedWithReducerFuel remaining;
            recur reduceRecursor localValue nextContext nextState nextRoot;
        let core :=
          fun (nextContext : PsKernelExprV2CheckContext)
              (nextState : PsKernelExprV2CheckState) (nextRoot : Nat) =>
            let worker := psKernelExprV2TryWhnfCoreOwnedModeWithReducerFuel remaining;
            worker false false localValue smaller reduceRecursor nextContext nextState nextRoot;
        match psKernelExprV2PagedRequire state.whnf.arena root with
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
                match localValue context name with
                | Option.some _ =>
                    psKernelExprV2TryWhnfPublicOwnedNonterminalWith
                      smaller core context state root entry
                | Option.none =>
                    match psKernelLocalContextFind context.scalar.localContext name with
                    | Option.none => Option.some (Except.ok (Prod.mk state root))
                    | Option.some declaration =>
                        match psKernelLocalDeclValue declaration with
                        | Option.none => Option.some (Except.ok (Prod.mk state root))
                        | Option.some _ => Option.none
            | _ =>
                psKernelExprV2TryWhnfPublicOwnedNonterminalWith
                  smaller core context state root entry


