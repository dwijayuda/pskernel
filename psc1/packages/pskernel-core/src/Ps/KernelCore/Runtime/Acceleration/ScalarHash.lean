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

def psKernelCacheStringHashStateWithFuel
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

/- Pure bounded entry for zero through four pairs. Larger inputs deliberately
   stop after four pairs; the public entry selects this only when pairs <= 4. -/
def psKernelCacheStringHashShortPairs
    (pairs : Nat)
    (value : String)
    (initial : Prod Nat Nat) : Prod Nat Nat :=
  match pairs with
  | Nat.zero => initial
  | Nat.succ afterFirst =>
      let afterTwo := psKernelCacheStringHashStep value
        (psKernelCacheStringHashStep value initial);
      match afterFirst with
      | Nat.zero => afterTwo
      | Nat.succ afterSecond =>
          let afterFour := psKernelCacheStringHashStep value
            (psKernelCacheStringHashStep value afterTwo);
          match afterSecond with
          | Nat.zero => afterFour
          | Nat.succ afterThird =>
              let afterSix := psKernelCacheStringHashStep value
                (psKernelCacheStringHashStep value afterFour);
              match afterThird with
              | Nat.zero => afterSix
              | Nat.succ _afterFourth =>
                  psKernelCacheStringHashStep value
                    (psKernelCacheStringHashStep value afterSix)

def psKernelCacheStringHash
    (value : String) :
    Nat :=
  /- Fuse the public zero-cursor entry; preserve the staged general worker. -/
  let fuel := Nat.succ (String.utf8ByteSize value);
  let pairs := Nat.div fuel 2;
  let paired :=
    if Nat.ble pairs 4 then
      psKernelCacheStringHashShortPairs pairs value (Prod.mk 0 0)
    else
      psKernelCacheStringHashPairsWithFuel pairs value (Prod.mk 0 0);
  let final :=
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
            psKernelCacheHashModulus);
  Prod.snd final

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
  /- Common universe-argument arities avoid constructing a curried worker.
     The worker remains the exact fallback and public staged reference. -/
  match values with
  | List.nil =>
      575
  | List.cons first rest =>
      match rest with
      | List.nil =>
          let firstHash := psKernelCacheLevelHash first;
          let afterFirst := Nat.mod
            (Nat.add (Nat.mul 18 31) firstHash) psKernelCacheHashModulus;
          Nat.mod
            (Nat.add (Nat.mul afterFirst 31) 17) psKernelCacheHashModulus
      | List.cons second tail =>
          match tail with
          | List.nil =>
              let firstHash := psKernelCacheLevelHash first;
              let secondHash := psKernelCacheLevelHash second;
              let afterFirst := Nat.mod
                (Nat.add (Nat.mul 18 31) firstHash) psKernelCacheHashModulus;
              let afterSecond := Nat.mod
                (Nat.add (Nat.mul afterFirst 31) secondHash) psKernelCacheHashModulus;
              Nat.mod
                (Nat.add (Nat.mul afterSecond 31) 17) psKernelCacheHashModulus
          | List.cons _third _remaining =>
              psKernelCacheLevelListHashWorker values 18

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

