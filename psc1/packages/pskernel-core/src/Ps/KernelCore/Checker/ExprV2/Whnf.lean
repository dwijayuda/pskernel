import Ps.KernelCore.Checker.ExprV2.Beta
import Ps.KernelCore.Checker.ExprV2.Nat
import Ps.KernelCore.Checker.ExprV2.Projection

/-
Checked DAG WHNF for terminal/metadata/beta/zeta, inert applications,
constructor projection and the complete Nat post-core pipeline.

The operation owns distinct core/public caches in one append-only arena.
A core entry checks fuel and depth before syntax/cache. A public entry keeps
the original terminal/metadata ordering and checks its cache before core.
The public callback supplied to core remains fixed during core recursion;
both function/result core calls consume the original predecessor budget.

Only admitted environment variants and scalar constructor metadata are read.
Definition unfolding, active recursors/Quot reduction, local let values and
String literal constructor expansion explicitly request original-checker
fallback. No legacy expression is imported by these workers. Public entry
creates empty caches; the public result never exports semantic cache state.
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

def psKernelExprV2TryWhnfProjectionWith
    (recurse : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (root : Nat) (typeName : PsKernelName) (index structValue : Nat) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match publicWhnf context state structValue with
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
                        Option.some (psKernelExprV2WhnfCoreFinish next root root)
                    | Option.some value =>
                        psKernelExprV2WhnfFinishAttempt root
                          (recurse context next value)

def psKernelExprV2TryWhnfAppWith
    (recurse : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (root : Nat) :
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
                                  psKernelExprV2WhnfFinishAttempt root
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
                            if psKernelExprV2WhnfRecursorInert context fnEntry.node then
                              Option.some (Except.ok (Prod.mk fnState root))
                            else Option.none
                          else
                            match psKernelExprV2TransformApplyArgsOnCanonical
                                (Prod.snd spine) fnState.arena fn with
                            | Except.error error => Option.some (Except.error error)
                            | Except.ok rebuilt =>
                                psKernelExprV2WhnfFinishAttempt root
                                  (recurse context
                                    (psKernelExprV2WhnfStateWithArena fnState
                                      (Prod.fst rebuilt))
                                    (Prod.snd rebuilt))

def psKernelExprV2TryWhnfCompositeWith
    (recurse : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
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
  | PsKernelExprV2Node.proj typeName index structValue =>
      psKernelExprV2TryWhnfProjectionWith
        recurse publicWhnf context state root typeName index structValue
  | PsKernelExprV2Node.app _ _ =>
      psKernelExprV2TryWhnfAppWith recurse context state root
  | _ => Option.none

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
        let smaller :=
          fun (nextContext : PsKernelCheckerContext)
              (nextState : PsKernelExprV2WhnfState) (nextRoot : Nat) =>
            let recur := psKernelExprV2TryWhnfCoreWithPublicFuel remaining;
            recur publicWhnf nextContext nextState nextRoot;
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
                            psKernelExprV2TryWhnfCompositeWith
                              smaller publicWhnf nextContext state root entry

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
              match psKernelExprV2WhnfDeltaInertOnCanonical context next.arena core with
              | Except.error error => Option.some (Except.error error)
              | Except.ok inert =>
                  if inert then
                    Option.some (psKernelExprV2WhnfPublicFinish next original core)
                  else Option.none

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
      let core :=
        fun (nextContext : PsKernelCheckerContext)
            (nextState : PsKernelExprV2WhnfState) (nextRoot : Nat) =>
          let worker := psKernelExprV2TryWhnfCoreWithPublicFuel remaining;
          worker smaller nextContext nextState nextRoot;
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
                psKernelExprV2TryWhnfPublicNonterminalWith
                  smaller core context state root entry

/-
The standalone core wrapper uses a public callback with the same fuel, matching
CoreWithRecursorFuel. The public worker above instead passes its predecessor
fuel into both the core worker and the fixed public callback. All parameters
of nonrecursive wrappers are explicit for a stable generated calling convention.
-/
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

def psKernelExprV2TryWhnfWithFuel
    (fuel : Nat) (context : PsKernelCheckerContext)
    (arena : PsKernelExprV2PagedArena) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2PagedArena Nat)) :=
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
