import Ps.KernelCore.Core.ExprScalar

/- Scalar hash helpers shared by both expression representations.
A hash is an index hint; matching values never establish expression equality. -/

def psKernelCacheHashModulus : Nat :=
  65521

def psKernelCacheMix
    (left : Nat)
    (right : Nat) :
    Nat :=
  Nat.mod
    (Nat.add
      (Nat.mul left 31)
      right)
    psKernelCacheHashModulus

/- Data-result iteration keeps the recursor motive out of function space.
The cursor/hash transition is immutable and preserves a finished cursor. -/
def psKernelCacheStringHashStep
    (value : String)
    (state : Prod Nat Nat) : Prod Nat Nat :=
  let position := Prod.fst state;
  if String.Pos.Raw.atEnd value (String.Pos.Raw.mk position) then
    state
  else
    let char := String.Internal.get value (String.Pos.Raw.mk position);
    let next := String.Pos.Raw.byteIdx
      (String.Pos.Raw.next value (String.Pos.Raw.mk position));
    Prod.mk next
      (Nat.mod
        (Nat.add (Nat.mul (Prod.snd state) 31) (Char.toNat char))
        psKernelCacheHashModulus)

/- Count pairs directly so portable structural recursion decreases by one. -/
def psKernelCacheStringHashPairsWithFuel
    (pairs : Nat)
    (value : String)
    (initial : Prod Nat Nat) : Prod Nat Nat :=
  match pairs with
  | Nat.zero => initial
  | Nat.succ remaining =>
      let state := psKernelCacheStringHashPairsWithFuel remaining value initial;
      /- Direct projections keep the intermediate transition a pure expression. -/
      let intermediate :=
        if String.Pos.Raw.atEnd value (String.Pos.Raw.mk (Prod.fst state)) then
          state
        else
          Prod.mk
            (String.Pos.Raw.byteIdx
              (String.Pos.Raw.next value (String.Pos.Raw.mk (Prod.fst state))))
            (Nat.mod
              (Nat.add
                (Nat.mul (Prod.snd state) 31)
                (Char.toNat (String.Internal.get value (String.Pos.Raw.mk (Prod.fst state)))))
              psKernelCacheHashModulus);
      if String.Pos.Raw.atEnd value (String.Pos.Raw.mk (Prod.fst intermediate)) then
        intermediate
      else
        Prod.mk
          (String.Pos.Raw.byteIdx
            (String.Pos.Raw.next value (String.Pos.Raw.mk (Prod.fst intermediate))))
          (Nat.mod
            (Nat.add
              (Nat.mul (Prod.snd intermediate) 31)
              (Char.toNat (String.Internal.get value (String.Pos.Raw.mk (Prod.fst intermediate)))))
            psKernelCacheHashModulus)

/- Eight immutable transitions share one structural scheduler descent.
The remainder uses the unchanged pair counter, so every fuel is exact. -/
def psKernelCacheStringHashOctetsWithFuel
    (octets : Nat)
    (value : String)
    (initial : Prod Nat Nat) : Prod Nat Nat :=
  match octets with
  | Nat.zero => initial
  | Nat.succ remaining =>
      let state0 := psKernelCacheStringHashOctetsWithFuel remaining value initial;
      let state1 :=
        if String.Pos.Raw.atEnd value (String.Pos.Raw.mk (Prod.fst state0)) then
          state0
        else
          Prod.mk
            (String.Pos.Raw.byteIdx
              (String.Pos.Raw.next value (String.Pos.Raw.mk (Prod.fst state0))))
            (Nat.mod
              (Nat.add
                (Nat.mul (Prod.snd state0) 31)
                (Char.toNat (String.Internal.get value (String.Pos.Raw.mk (Prod.fst state0)))))
              psKernelCacheHashModulus);
      let state2 :=
        if String.Pos.Raw.atEnd value (String.Pos.Raw.mk (Prod.fst state1)) then
          state1
        else
          Prod.mk
            (String.Pos.Raw.byteIdx
              (String.Pos.Raw.next value (String.Pos.Raw.mk (Prod.fst state1))))
            (Nat.mod
              (Nat.add
                (Nat.mul (Prod.snd state1) 31)
                (Char.toNat (String.Internal.get value (String.Pos.Raw.mk (Prod.fst state1)))))
              psKernelCacheHashModulus);
      let state3 :=
        if String.Pos.Raw.atEnd value (String.Pos.Raw.mk (Prod.fst state2)) then
          state2
        else
          Prod.mk
            (String.Pos.Raw.byteIdx
              (String.Pos.Raw.next value (String.Pos.Raw.mk (Prod.fst state2))))
            (Nat.mod
              (Nat.add
                (Nat.mul (Prod.snd state2) 31)
                (Char.toNat (String.Internal.get value (String.Pos.Raw.mk (Prod.fst state2)))))
              psKernelCacheHashModulus);
      let state4 :=
        if String.Pos.Raw.atEnd value (String.Pos.Raw.mk (Prod.fst state3)) then
          state3
        else
          Prod.mk
            (String.Pos.Raw.byteIdx
              (String.Pos.Raw.next value (String.Pos.Raw.mk (Prod.fst state3))))
            (Nat.mod
              (Nat.add
                (Nat.mul (Prod.snd state3) 31)
                (Char.toNat (String.Internal.get value (String.Pos.Raw.mk (Prod.fst state3)))))
              psKernelCacheHashModulus);
      let state5 :=
        if String.Pos.Raw.atEnd value (String.Pos.Raw.mk (Prod.fst state4)) then
          state4
        else
          Prod.mk
            (String.Pos.Raw.byteIdx
              (String.Pos.Raw.next value (String.Pos.Raw.mk (Prod.fst state4))))
            (Nat.mod
              (Nat.add
                (Nat.mul (Prod.snd state4) 31)
                (Char.toNat (String.Internal.get value (String.Pos.Raw.mk (Prod.fst state4)))))
              psKernelCacheHashModulus);
      let state6 :=
        if String.Pos.Raw.atEnd value (String.Pos.Raw.mk (Prod.fst state5)) then
          state5
        else
          Prod.mk
            (String.Pos.Raw.byteIdx
              (String.Pos.Raw.next value (String.Pos.Raw.mk (Prod.fst state5))))
            (Nat.mod
              (Nat.add
                (Nat.mul (Prod.snd state5) 31)
                (Char.toNat (String.Internal.get value (String.Pos.Raw.mk (Prod.fst state5)))))
              psKernelCacheHashModulus);
      let state7 :=
        if String.Pos.Raw.atEnd value (String.Pos.Raw.mk (Prod.fst state6)) then
          state6
        else
          Prod.mk
            (String.Pos.Raw.byteIdx
              (String.Pos.Raw.next value (String.Pos.Raw.mk (Prod.fst state6))))
            (Nat.mod
              (Nat.add
                (Nat.mul (Prod.snd state6) 31)
                (Char.toNat (String.Internal.get value (String.Pos.Raw.mk (Prod.fst state6)))))
              psKernelCacheHashModulus);
      if String.Pos.Raw.atEnd value (String.Pos.Raw.mk (Prod.fst state7)) then
          state7
        else
          Prod.mk
            (String.Pos.Raw.byteIdx
              (String.Pos.Raw.next value (String.Pos.Raw.mk (Prod.fst state7))))
            (Nat.mod
              (Nat.add
                (Nat.mul (Prod.snd state7) 31)
                (Char.toNat (String.Internal.get value (String.Pos.Raw.mk (Prod.fst state7)))))
              psKernelCacheHashModulus)

def psKernelCacheStringHashRemainderWithFuel
    (fuel : Nat)
    (value : String)
    (initial : Prod Nat Nat) : Prod Nat Nat :=
  let paired := psKernelCacheStringHashPairsWithFuel (Nat.div fuel 2) value initial;
  if Nat.beq (Nat.mod fuel 2) 0 then
    paired
  else
    if String.Pos.Raw.atEnd value (String.Pos.Raw.mk (Prod.fst paired)) then
      paired
    else
      Prod.mk
        (String.Pos.Raw.byteIdx
          (String.Pos.Raw.next value (String.Pos.Raw.mk (Prod.fst paired))))
        (Nat.mod
          (Nat.add
            (Nat.mul (Prod.snd paired) 31)
            (Char.toNat (String.Internal.get value (String.Pos.Raw.mk (Prod.fst paired)))))
          psKernelCacheHashModulus)

def psKernelCacheStringHashStateWithFuel
    (fuel : Nat)
    (value : String)
    (initial : Prod Nat Nat) : Prod Nat Nat :=
  let complete := psKernelCacheStringHashOctetsWithFuel (Nat.div fuel 8) value initial;
  psKernelCacheStringHashRemainderWithFuel (Nat.mod fuel 8) value complete

def psKernelCacheStringHashScan
    (fuel : Nat)
    (value : String)
    (position : Nat)
    (hash : Nat) : Nat :=
  Prod.snd
    (psKernelCacheStringHashStateWithFuel fuel value (Prod.mk position hash))

/- Preserve every public partial-application stage and exact hash value. -/
def psKernelCacheStringHashWorker
    (fuel : Nat) :
    String -> Nat -> Nat -> Nat :=
  match fuel with
  | Nat.zero =>
      fun (_value : String) (_position : Nat) (hash : Nat) => hash
  | Nat.succ remaining =>
      fun (value : String) (position : Nat) (hash : Nat) =>
        psKernelCacheStringHashScan (Nat.succ remaining) value position hash

def psKernelCacheStringHash
    (value : String) :
    Nat :=
  psKernelCacheStringHashScan
    (Nat.succ
      (String.utf8ByteSize value))
    value
    0
    0

def psKernelCacheNameHash
    (name : PsKernelName) :
    Nat :=
  match name with
  | PsKernelName.anonymous =>
      1
  | PsKernelName.str parent value =>
      psKernelCacheMix
        (psKernelCacheMix
          2
          (psKernelCacheNameHash parent))
        (psKernelCacheStringHash value)
  | PsKernelName.num parent value =>
      psKernelCacheMix
        (psKernelCacheMix
          3
          (psKernelCacheNameHash parent))
        value

def psKernelCacheLevelHash
    (level : PsKernelLevel) :
    Nat :=
  match level with
  | PsKernelLevel.zero =>
      11
  | PsKernelLevel.succ inner =>
      psKernelCacheMix
        12
        (psKernelCacheLevelHash inner)
  | PsKernelLevel.max left right =>
      psKernelCacheMix
        (psKernelCacheMix
          13
          (psKernelCacheLevelHash left))
        (psKernelCacheLevelHash right)
  | PsKernelLevel.imax left right =>
      psKernelCacheMix
        (psKernelCacheMix
          14
          (psKernelCacheLevelHash left))
        (psKernelCacheLevelHash right)
  | PsKernelLevel.param name =>
      psKernelCacheMix
        15
        (psKernelCacheNameHash name)
  | PsKernelLevel.mvar name =>
      psKernelCacheMix
        16
        (psKernelCacheNameHash name)

def psKernelCacheLevelListHashWorker
    (values : List PsKernelLevel) :
    Nat -> Nat :=
  match values with
  | List.nil =>
      fun (hash : Nat) =>
        psKernelCacheMix hash 17
  | List.cons head tail =>
      let smaller : Nat -> Nat :=
        psKernelCacheLevelListHashWorker tail;
      fun (hash : Nat) =>
        smaller
          (psKernelCacheMix
            hash
            (psKernelCacheLevelHash head))

def psKernelCacheLevelListHash
    (values : List PsKernelLevel) :
    Nat :=
  psKernelCacheLevelListHashWorker
    values
    18

def psKernelCacheLiteralHash
    (literal : PsKernelLiteral) :
    Nat :=
  match literal with
  | PsKernelLiteral.nat value =>
      psKernelCacheMix 19 value
  | PsKernelLiteral.str value =>
      psKernelCacheMix
        20
        (psKernelCacheStringHash value)

