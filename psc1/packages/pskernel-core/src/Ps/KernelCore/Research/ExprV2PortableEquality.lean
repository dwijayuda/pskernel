import Ps.KernelCore.Research.ExprV2PortableHeadMachine

/-
PSKernel-Core Expression V2 / M4 research: portable, memoized equality on
validated, immutable DAG nodes.

Only psKernelExprV2PortableEqChecked validates an external input arena.
The core helpers receive the freshly replayed canonical arena, then use
same-arena node identity as a sufficient success shortcut and the *validated*
structural hash as an inequality shortcut. Equal hashes are NEVER an equality
proof: all remaining structure and children are compared.

Within one comparison, memo entries are keyed by (leftNodeID,rightNodeID).
No result escapes to other environments or arenas. False and true results
are both memoized, so shared subgraphs are not traversed exponentially.
This implements only legacy PsKernelExprEq structural semantics; it is not
definitional equality and is not wired into admission or checker caches.
-/

structure PsKernelExprV2PairMemo where
  left : Nat
  right : Nat
  result : Bool

def psKernelExprV2PairMemoFind
    (entries : List PsKernelExprV2PairMemo)
    (left right : Nat) : Option Bool :=
  match entries with
  | List.nil =>
      Option.none
  | List.cons item rest =>
      if Nat.beq left item.left then
        if Nat.beq right item.right then
          Option.some item.result
        else
          psKernelExprV2PairMemoFind rest left right
      else
        psKernelExprV2PairMemoFind rest left right

def psKernelExprV2PairMemoInsert
    (entries : List PsKernelExprV2PairMemo)
    (left right : Nat) (result : Bool) :
    List PsKernelExprV2PairMemo :=
  List.cons
    { left := left
      right := right
      result := result
    }
    entries

def psKernelExprV2PairCompare2
    (step :
      PsKernelExprV2ChunkedArena ->
      List PsKernelExprV2PairMemo ->
      Nat -> Nat ->
      Except String (Bool × List PsKernelExprV2PairMemo))
    (arena : PsKernelExprV2ChunkedArena)
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

def psKernelExprV2PairCompare3
    (step :
      PsKernelExprV2ChunkedArena ->
      List PsKernelExprV2PairMemo ->
      Nat -> Nat ->
      Except String (Bool × List PsKernelExprV2PairMemo))
    (arena : PsKernelExprV2ChunkedArena)
    (memo : List PsKernelExprV2PairMemo)
    (a b c d e f : Nat) :
    Except String (Bool × List PsKernelExprV2PairMemo) :=
  match psKernelExprV2PairCompare2 step arena memo a b c d with
  | Except.error error =>
      Except.error error
  | Except.ok first =>
      if Prod.fst first then
        step arena (Prod.snd first) e f
      else
        Except.ok (Prod.mk false (Prod.snd first))

def psKernelExprV2PairCompareShape
    (step :
      PsKernelExprV2ChunkedArena ->
      List PsKernelExprV2PairMemo ->
      Nat -> Nat ->
      Except String (Bool × List PsKernelExprV2PairMemo))
    (arena : PsKernelExprV2ChunkedArena)
    (memo : List PsKernelExprV2PairMemo)
    (left right : PsKernelExprV2Node) :
    Except String (Bool × List PsKernelExprV2PairMemo) :=
  match left,right with
  | PsKernelExprV2Node.bvar x, PsKernelExprV2Node.bvar y =>
      Except.ok (Prod.mk (Nat.beq x y) memo)
  | PsKernelExprV2Node.fvar x, PsKernelExprV2Node.fvar y =>
      Except.ok (Prod.mk (psKernelNameEq x y) memo)
  | PsKernelExprV2Node.mvar x, PsKernelExprV2Node.mvar y =>
      Except.ok (Prod.mk (psKernelNameEq x y) memo)
  | PsKernelExprV2Node.sort x, PsKernelExprV2Node.sort y =>
      Except.ok (Prod.mk (psKernelLevelEq x y) memo)
  | PsKernelExprV2Node.const x xs, PsKernelExprV2Node.const y ys =>
      if psKernelNameEq x y then
        Except.ok (Prod.mk (psKernelLevelListEq xs ys) memo)
      else
        Except.ok (Prod.mk false memo)
  | PsKernelExprV2Node.lit x, PsKernelExprV2Node.lit y =>
      Except.ok (Prod.mk (psKernelLiteralEq x y) memo)
  | PsKernelExprV2Node.app lf la, PsKernelExprV2Node.app rf ra =>
      psKernelExprV2PairCompare2 step arena memo lf rf la ra
  | PsKernelExprV2Node.lam _ lt lb _, PsKernelExprV2Node.lam _ rt rb _ =>
      psKernelExprV2PairCompare2 step arena memo lt rt lb rb
  | PsKernelExprV2Node.forallE _ lt lb _, PsKernelExprV2Node.forallE _ rt rb _ =>
      psKernelExprV2PairCompare2 step arena memo lt rt lb rb
  | PsKernelExprV2Node.letE _ lt lv lb ld,
      PsKernelExprV2Node.letE _ rt rv rb rd =>
      if psKernelBoolEq ld rd then
        psKernelExprV2PairCompare3 step arena memo
          lt rt lv rv lb rb
      else
        Except.ok (Prod.mk false memo)
  | PsKernelExprV2Node.mdata lt lb, PsKernelExprV2Node.mdata rt rb =>
      if Nat.beq lt rt then
        step arena memo lb rb
      else
        Except.ok (Prod.mk false memo)
  | PsKernelExprV2Node.proj ln li lb, PsKernelExprV2Node.proj rn ri rb =>
      if psKernelNameEq ln rn then
        if Nat.beq li ri then
          step arena memo lb rb
        else
          Except.ok (Prod.mk false memo)
      else
        Except.ok (Prod.mk false memo)
  | _,_ =>
      Except.ok (Prod.mk false memo)

def psKernelExprV2PairCompareWithFuel
    (fuel : Nat) :
    PsKernelExprV2ChunkedArena ->
    List PsKernelExprV2PairMemo ->
    Nat -> Nat ->
    Except String (Bool × List PsKernelExprV2PairMemo) :=
  match fuel with
  | Nat.zero =>
      fun (_arena : PsKernelExprV2ChunkedArena) =>
        fun (_memo : List PsKernelExprV2PairMemo) =>
          fun (_left : Nat) =>
            fun (_right : Nat) =>
              Except.error "PSKERNEL_V2_PAIR_COMPARE_FUEL"
  | Nat.succ remaining =>
      let smaller :
          PsKernelExprV2ChunkedArena ->
          List PsKernelExprV2PairMemo ->
          Nat -> Nat ->
          Except String (Bool × List PsKernelExprV2PairMemo) :=
        psKernelExprV2PairCompareWithFuel remaining;
      fun (arena : PsKernelExprV2ChunkedArena) =>
        fun (memo : List PsKernelExprV2PairMemo) =>
          fun (left : Nat) =>
            fun (right : Nat) =>
              match psKernelExprV2ChunkedFind arena left with
              | Option.none =>
                  Except.error "PSKERNEL_V2_PAIR_INVALID_LEFT"
              | Option.some a =>
                  match psKernelExprV2ChunkedFind arena right with
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
                              match psKernelExprV2PairCompareShape
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
External entrypoint validates the entire source graph exactly once.
Checked constructor invariants and node IDs are scoped to this one arena.
The returned Bool is structural equality only, NOT kernel DefEq.
-/
def psKernelExprV2PortableEqChecked
    (source : PsKernelExprV2ChunkedArena)
    (left right : Nat) :
    Except String Bool :=
  match psKernelExprV2PortableValidate source with
  | Except.error error =>
      Except.error error
  | Except.ok canonical =>
      match psKernelExprV2ChunkedFind canonical left with
      | Option.none =>
          Except.error "PSKERNEL_V2_PAIR_CHECK_INVALID_LEFT"
      | Option.some a =>
          match psKernelExprV2ChunkedFind canonical right with
          | Option.none =>
              Except.error "PSKERNEL_V2_PAIR_CHECK_INVALID_RIGHT"
          | Option.some b =>
              let maxDepth := Nat.max a.depth b.depth;
              match
                  psKernelExprV2PairCompareWithFuel
                    (Nat.succ maxDepth)
                    canonical
                    List.nil
                    left right with
              | Except.error error =>
                  Except.error error
              | Except.ok result =>
                  Except.ok (Prod.fst result)
