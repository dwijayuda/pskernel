import Ps.KernelCore.Checker.ExprV2.CheckHelpers

/-
Fully checked lets retain the fixed top-level DefEq callback even when the
value type and declared type are structurally equal. A successful comparison
precedes fresh-name allocation and the local-scope snapshot, so its permitted
success-cache entries survive closing the let; child-local entries do not.
-/
def psKernelExprV2CheckCloseLet
    (opened : PsKernelExprV2OpenedCheckBinder)
    (state : PsKernelExprV2CheckState) (bodyType _root : Nat)
    (name : PsKernelName) (type value : Nat) (nondep : Bool) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match psKernelExprV2CheapBetaOnCanonical state.whnf.arena bodyType with
  | Except.error error => Option.some (Except.error error)
  | Except.ok cheap =>
      match psKernelExprV2TransformOnCanonical
          (PsKernelExprV2Transform.abstractFVars (List.cons opened.fresh List.nil))
          (Prod.fst cheap) (Prod.snd cheap) 0 with
      | Except.error error => Option.some (Except.error error)
      | Except.ok closed =>
          match psKernelExprV2PagedRequire (Prod.fst closed) (Prod.snd closed) with
          | Except.error error => Option.some (Except.error error)
          | Except.ok entry =>
              let next :=
                psKernelExprV2CheckStateWithArena
                  (psKernelExprV2CheckStateExitLocalScope opened.parent state)
                  (Prod.fst closed);
              if Nat.beq entry.looseRange 0 then
                Option.some
                  (Except.ok (Prod.mk next (Prod.snd cheap)))
              else
                if Nat.beq entry.looseRange 1 then
                  Option.some
                    (psKernelExprV2InferenceBuilt next
                      (psKernelExprV2PagedMkLet next.whnf.arena
                        name type value (Prod.snd closed) nondep))
                else Option.none

def psKernelExprV2CheckLetBodyWith
    (check : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat)
    (name : PsKernelName) (type value body : Nat) (nondep : Bool) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match psKernelExprV2CheckOpenLocal context state name type body
      PsKernelBinderInfo.default (Option.some value) with
  | Except.error error => Option.some (Except.error error)
  | Except.ok opened =>
      match check opened.context opened.parent opened.body with
      | Option.none => Option.none
      | Option.some attemptedBody =>
          match attemptedBody with
          | Except.error error => Option.some (Except.error error)
          | Except.ok bodyResult =>
              psKernelExprV2CheckCloseLet opened
                (Prod.fst bodyResult) (Prod.snd bodyResult) root
                name type value nondep

def psKernelExprV2CheckLetWith
    (check : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat)
    (name : PsKernelName) (type value body : Nat) (nondep inferOnly : Bool) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  if inferOnly then
    psKernelExprV2CheckLetBodyWith check context state root name type value body nondep
  else
    match check context state type with
    | Option.none => Option.none
    | Option.some attemptedType =>
        match attemptedType with
        | Except.error error => Option.some (Except.error error)
        | Except.ok typeResult =>
            match psKernelExprV2CheckEnsureSortWith
                whnf context (Prod.fst typeResult) (Prod.snd typeResult) with
            | Option.none => Option.none
            | Option.some attemptedSort =>
                match attemptedSort with
                | Except.error error => Option.some (Except.error error)
                | Except.ok typeSort =>
                    match check context (Prod.fst typeSort) value with
                    | Option.none => Option.none
                    | Option.some attemptedValue =>
                        match attemptedValue with
                        | Except.error error => Option.some (Except.error error)
                        | Except.ok valueResult =>
                            match defeq context (Prod.fst valueResult)
                                (Prod.snd valueResult) type with
                            | Option.none => Option.none
                            | Option.some attemptedEquality =>
                                match attemptedEquality with
                                | Except.error error => Option.some (Except.error error)
                                | Except.ok equalResult =>
                                    if Prod.snd equalResult then
                                      psKernelExprV2CheckLetBodyWith check context
                                        (Prod.fst equalResult) root
                                        name type value body nondep
                                    else Option.some (Except.error "let value type mismatch")
