import Ps.KernelCore.Checker.Reduction.PrimitiveNat
import Ps.KernelCore.Checker.ExprV2.WhnfState
import Ps.KernelCore.Core.ExprV2.Builder

/-
Nat post-core reduction over the owning canonical arena. Arithmetic and resource
checks are shared with the original checker through scalar primitive results.
No recursive expression is imported or decoded here.

The two-argument branch deliberately normalizes both operands before recognizing
a primitive or examining their numeral shapes. Its cache effects and possible
resource errors are part of the existing public WHNF contract, even for a
non-Nat constant. An outer none requests complete-checker fallback; an inner
none means the supported pipeline performed no Nat reduction.
-/

def psKernelExprV2NatLiteralValue
    (arena : PsKernelExprV2PagedArena) (root : Nat) :
    Except String (Option Nat) :=
  match psKernelExprV2PagedRequire arena root with
  | Except.error error => Except.error error
  | Except.ok entry =>
      match entry.node with
      | PsKernelExprV2Node.lit literal =>
          match literal with
          | PsKernelLiteral.nat value => Except.ok (Option.some value)
          | PsKernelLiteral.str _ => Except.ok Option.none
      | PsKernelExprV2Node.const name levels =>
          match levels with
          | List.nil =>
              if psKernelNameEq name psKernelNatZeroName then
                Except.ok (Option.some 0)
              else Except.ok Option.none
          | List.cons _ _ => Except.ok Option.none
      | _ => Except.ok Option.none

def psKernelExprV2NatPublish
    (state : PsKernelExprV2WhnfState) (value : PsKernelNatReductionValue) :
    Except String (Prod PsKernelExprV2WhnfState (Option Nat)) :=
  let built : Except String (Prod PsKernelExprV2PagedArena Nat) :=
    match value with
    | PsKernelNatReductionValue.nat number =>
        psKernelExprV2PagedMkLit state.arena (PsKernelLiteral.nat number)
    | PsKernelNatReductionValue.bool boolean =>
        psKernelExprV2PagedMkConst state.arena
          (if boolean then psKernelBoolTrueName else psKernelBoolFalseName)
          List.nil;
  match built with
  | Except.error error => Except.error error
  | Except.ok result =>
      Except.ok
        (Prod.mk
          (psKernelExprV2WhnfStateWithArena state (Prod.fst result))
          (Option.some (Prod.snd result)))

def psKernelExprV2TryReduceNatSuccWith
    (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (argument : Nat) :
    Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))) :=
  match publicWhnf context state argument with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          let next := Prod.fst reduced;
          match psKernelExprV2NatLiteralValue next.arena (Prod.snd reduced) with
          | Except.error error => Option.some (Except.error error)
          | Except.ok number =>
              match number with
              | Option.none => Option.some (Except.ok (Prod.mk next Option.none))
              | Option.some value =>
                  let result := Nat.succ value;
                  match psKernelCheckNatSize context.maxNatSize result with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok _ =>
                      Option.some
                        (psKernelExprV2NatPublish next
                          (PsKernelNatReductionValue.nat result))

def psKernelExprV2NatBinaryFinish
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (name : PsKernelName) (left right : Nat) :
    Except String (Prod PsKernelExprV2WhnfState (Option Nat)) :=
  match psKernelExprV2NatLiteralValue state.arena left with
  | Except.error error => Except.error error
  | Except.ok first =>
      match first with
      | Option.none => Except.ok (Prod.mk state Option.none)
      | Option.some leftValue =>
          match psKernelExprV2NatLiteralValue state.arena right with
          | Except.error error => Except.error error
          | Except.ok second =>
              match second with
              | Option.none => Except.ok (Prod.mk state Option.none)
              | Option.some rightValue =>
                  match psKernelReduceNatBinaryValue context.maxNatSize
                      name leftValue rightValue with
                  | Except.error error => Except.error error
                  | Except.ok result =>
                      match result with
                      | Option.none => Except.ok (Prod.mk state Option.none)
                      | Option.some value => psKernelExprV2NatPublish state value

def psKernelExprV2TryReduceNatBinaryWith
    (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (name : PsKernelName) (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))) :=
  match publicWhnf context state left with
  | Option.none => Option.none
  | Option.some attemptedLeft =>
      match attemptedLeft with
      | Except.error error => Option.some (Except.error error)
      | Except.ok first =>
          match publicWhnf context (Prod.fst first) right with
          | Option.none => Option.none
          | Option.some attemptedRight =>
              match attemptedRight with
              | Except.error error => Option.some (Except.error error)
              | Except.ok second =>
                  Option.some
                    (psKernelExprV2NatBinaryFinish context (Prod.fst second)
                      name (Prod.snd first) (Prod.snd second))

def psKernelExprV2TryReduceNatWith
    (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (root : Nat) :
    Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))) :=
  match psKernelExprV2PagedRequire state.arena root with
  | Except.error error => Option.some (Except.error error)
  | Except.ok entry =>
      match entry.node with
      | PsKernelExprV2Node.app fn right =>
          match psKernelExprV2PagedRequire state.arena fn with
          | Except.error error => Option.some (Except.error error)
          | Except.ok fnEntry =>
              match fnEntry.node with
              | PsKernelExprV2Node.const name levels =>
                  match levels with
                  | List.nil =>
                      if psKernelNameEq name psKernelNatSuccName then
                        psKernelExprV2TryReduceNatSuccWith publicWhnf context state right
                      else Option.some (Except.ok (Prod.mk state Option.none))
                  | List.cons _ _ => Option.some (Except.ok (Prod.mk state Option.none))
              | PsKernelExprV2Node.app binaryHead left =>
                  match psKernelExprV2PagedRequire state.arena binaryHead with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok binaryEntry =>
                      match binaryEntry.node with
                      | PsKernelExprV2Node.const name levels =>
                          match levels with
                          | List.nil =>
                              psKernelExprV2TryReduceNatBinaryWith publicWhnf context
                                state name left right
                          | List.cons _ _ => Option.some (Except.ok (Prod.mk state Option.none))
                      | _ => Option.some (Except.ok (Prod.mk state Option.none))
              | _ => Option.some (Except.ok (Prod.mk state Option.none))
      | _ => Option.some (Except.ok (Prod.mk state Option.none))
