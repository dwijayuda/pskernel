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

def psKernelCacheStringHashStateWithFuel
    (fuel : Nat)
    (value : String)
    (initial : Prod Nat Nat) : Prod Nat Nat :=
  match fuel with
  | Nat.zero => initial
  | Nat.succ remaining =>
      /- Keep the byte transition a nonrecursive primitive-only data function,
      so generated iteration does not allocate a byte-step generator. -/
      psKernelCacheStringHashStep value
        (psKernelCacheStringHashStateWithFuel remaining value initial)

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

