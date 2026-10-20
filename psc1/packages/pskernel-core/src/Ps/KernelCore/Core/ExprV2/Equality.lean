import Ps.KernelCore.Core.ExprV2.Validation
import Ps.KernelCore.Core.ExprV2.PairMemo

/-
Validated paged DAG structural equality.

The native/PSC1-qualified paged implementation has one owner in production.
Research imports forward here. Binder-name erasure and metadata-tag handling
match PsKernelExprEq. Hashes reject unequal syntax; equality always checks
structure or same-arena identity. An operation owns and discards its pair memo.

The public checked entry reconstructs a canonical immutable arena using
ExprV2PagedValidate before reading metadata. Node IDs are never compared
between different arenas; equal hash values never imply equality. This is
structural equality only, not kernel DefEq or proof admission.
-/

def psKernelExprV2PagedPairCompare2
    (step :
      PsKernelExprV2PagedArena ->
      List PsKernelExprV2PairMemo ->
      Nat -> Nat ->
      Except String (Bool × List PsKernelExprV2PairMemo))
    (arena : PsKernelExprV2PagedArena)
    (memo : List PsKernelExprV2PairMemo)
    (a b c d : Nat) :
    Except String (Bool × List PsKernelExprV2PairMemo) :=
  match step arena memo a b with
  | Except.error error =>
      Except.error error
  | Except.ok first =>
      if Prod.fst first then
        step arena (Prod.snd first) c d
      else
        Except.ok (Prod.mk false (Prod.snd first))

def psKernelExprV2PagedPairCompare3
    (step :
      PsKernelExprV2PagedArena ->
      List PsKernelExprV2PairMemo ->
      Nat -> Nat ->
      Except String (Bool × List PsKernelExprV2PairMemo))
    (arena : PsKernelExprV2PagedArena)
    (memo : List PsKernelExprV2PairMemo)
    (a b c d e f : Nat) :
    Except String (Bool × List PsKernelExprV2PairMemo) :=
  match psKernelExprV2PagedPairCompare2 step arena memo a b c d with
  | Except.error error =>
      Except.error error
  | Except.ok first =>
      if Prod.fst first then
        step arena (Prod.snd first) e f
      else
        Except.ok (Prod.mk false (Prod.snd first))

def psKernelExprV2PagedPairCompareShape
    (step :
      PsKernelExprV2PagedArena ->
      List PsKernelExprV2PairMemo ->
      Nat -> Nat ->
      Except String (Bool × List PsKernelExprV2PairMemo))
    (arena : PsKernelExprV2PagedArena)
    (memo : List PsKernelExprV2PairMemo)
    (left right : PsKernelExprV2Node) :
    Except String (Bool × List PsKernelExprV2PairMemo) :=
  -- PSC1 portable .lean supports single-scrutinee pattern matching.
  match left with
  | PsKernelExprV2Node.bvar x =>
      match right with
      | PsKernelExprV2Node.bvar y =>
          Except.ok (Prod.mk (Nat.beq x y) memo)
      | _ => Except.ok (Prod.mk false memo)
  | PsKernelExprV2Node.fvar x =>
      match right with
      | PsKernelExprV2Node.fvar y =>
          Except.ok (Prod.mk (psKernelNameEq x y) memo)
      | _ => Except.ok (Prod.mk false memo)
  | PsKernelExprV2Node.mvar x =>
      match right with
      | PsKernelExprV2Node.mvar y =>
          Except.ok (Prod.mk (psKernelNameEq x y) memo)
      | _ => Except.ok (Prod.mk false memo)
  | PsKernelExprV2Node.sort x =>
      match right with
      | PsKernelExprV2Node.sort y =>
          Except.ok (Prod.mk (psKernelLevelEq x y) memo)
      | _ => Except.ok (Prod.mk false memo)
  | PsKernelExprV2Node.const x xs =>
      match right with
      | PsKernelExprV2Node.const y ys =>
          if psKernelNameEq x y then
            Except.ok (Prod.mk (psKernelLevelListEq xs ys) memo)
          else
            Except.ok (Prod.mk false memo)
      | _ => Except.ok (Prod.mk false memo)
  | PsKernelExprV2Node.lit x =>
      match right with
      | PsKernelExprV2Node.lit y =>
          Except.ok (Prod.mk (psKernelLiteralEq x y) memo)
      | _ => Except.ok (Prod.mk false memo)
  | PsKernelExprV2Node.app fn arg =>
      match right with
      | PsKernelExprV2Node.app otherFn otherArg =>
          psKernelExprV2PagedPairCompare2 step arena memo
            fn otherFn arg otherArg
      | _ => Except.ok (Prod.mk false memo)
  | PsKernelExprV2Node.lam _ type body _ =>
      match right with
      | PsKernelExprV2Node.lam _ otherType otherBody _ =>
          psKernelExprV2PagedPairCompare2 step arena memo
            type otherType body otherBody
      | _ => Except.ok (Prod.mk false memo)
  | PsKernelExprV2Node.forallE _ type body _ =>
      match right with
      | PsKernelExprV2Node.forallE _ otherType otherBody _ =>
          psKernelExprV2PagedPairCompare2 step arena memo
            type otherType body otherBody
      | _ => Except.ok (Prod.mk false memo)
  | PsKernelExprV2Node.letE _ type value body nondep =>
      match right with
      | PsKernelExprV2Node.letE _ otherType otherValue otherBody otherNondep =>
          if psKernelBoolEq nondep otherNondep then
            psKernelExprV2PagedPairCompare3 step arena memo
              type otherType value otherValue body otherBody
          else
            Except.ok (Prod.mk false memo)
      | _ => Except.ok (Prod.mk false memo)
  | PsKernelExprV2Node.mdata tag body =>
      match right with
      | PsKernelExprV2Node.mdata otherTag otherBody =>
          if Nat.beq tag otherTag then
            step arena memo body otherBody
          else
            Except.ok (Prod.mk false memo)
      | _ => Except.ok (Prod.mk false memo)
  | PsKernelExprV2Node.proj name idx body =>
      match right with
      | PsKernelExprV2Node.proj otherName otherIdx otherBody =>
          if psKernelNameEq name otherName then
            if Nat.beq idx otherIdx then
              step arena memo body otherBody
            else
              Except.ok (Prod.mk false memo)
          else
            Except.ok (Prod.mk false memo)
      | _ => Except.ok (Prod.mk false memo)

def psKernelExprV2PagedPairCompareWithFuel
    (fuel : Nat) :
    PsKernelExprV2PagedArena ->
    List PsKernelExprV2PairMemo ->
    Nat -> Nat ->
    Except String (Bool × List PsKernelExprV2PairMemo) :=
  match fuel with
  | Nat.zero =>
      fun (_arena : PsKernelExprV2PagedArena) =>
        fun (_memo : List PsKernelExprV2PairMemo) =>
          fun (_left : Nat) =>
            fun (_right : Nat) =>
              Except.error "PSKERNEL_V2_PAIR_COMPARE_FUEL"
  | Nat.succ remaining =>
      let smaller :
          PsKernelExprV2PagedArena ->
          List PsKernelExprV2PairMemo ->
          Nat -> Nat ->
          Except String (Bool × List PsKernelExprV2PairMemo) :=
        psKernelExprV2PagedPairCompareWithFuel remaining;
      fun (arena : PsKernelExprV2PagedArena) =>
        fun (memo : List PsKernelExprV2PairMemo) =>
          fun (left : Nat) =>
            fun (right : Nat) =>
              match psKernelExprV2PagedFind arena left with
              | Option.none =>
                  Except.error "PSKERNEL_V2_PAIR_INVALID_LEFT"
              | Option.some a =>
                  match psKernelExprV2PagedFind arena right with
                  | Option.none =>
                      Except.error "PSKERNEL_V2_PAIR_INVALID_RIGHT"
                  | Option.some b =>
                      if Nat.beq left right then
                        Except.ok (Prod.mk true memo)
                      else
                        match psKernelExprV2PairMemoFind memo left right with
                        | Option.some found =>
                            Except.ok (Prod.mk found memo)
                        | Option.none =>
                            if Nat.beq a.hash b.hash then
                              match psKernelExprV2PagedPairCompareShape
                                  smaller arena memo a.node b.node with
                              | Except.error error =>
                                  Except.error error
                              | Except.ok answer =>
                                  let checked := Prod.fst answer;
                                  let updated :=
                                    psKernelExprV2PairMemoInsert
                                      (Prod.snd answer)
                                      left right checked;
                                  Except.ok (Prod.mk checked updated)
                            else
                              Except.ok (Prod.mk false memo)

/-
Internal entry for a replay-validated canonical arena. Every call starts its
own empty pair memo; callers cannot inject conclusions. The complete checker
uses only true structural results, after independently checking both operands.
False structural results do not imply definitional inequality.
-/
def psKernelExprV2PagedEqOnCanonical
    (canonical : PsKernelExprV2PagedArena)
    (left right : Nat) :
    Except String Bool :=
  match psKernelExprV2PagedFind canonical left with
  | Option.none =>
      Except.error "PSKERNEL_V2_PAIR_CHECK_INVALID_LEFT"
  | Option.some a =>
      match psKernelExprV2PagedFind canonical right with
      | Option.none =>
          Except.error "PSKERNEL_V2_PAIR_CHECK_INVALID_RIGHT"
      | Option.some b =>
          let maxDepth := psKernelExprV2NatMax a.depth b.depth;
          match psKernelExprV2PagedPairCompareWithFuel
              (Nat.succ maxDepth) canonical List.nil left right with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (Prod.fst result)

/- The external equality entry replays raw graph data exactly once. -/
def psKernelExprV2PagedEqChecked
    (source : PsKernelExprV2PagedArena)
    (left right : Nat) :
    Except String Bool :=
  match psKernelExprV2PagedValidate source with
  | Except.error error => Except.error error
  | Except.ok canonical =>
      psKernelExprV2PagedEqOnCanonical canonical left right
