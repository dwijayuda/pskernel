import Ps.KernelCore.Research.ExprV2

/-
Expression V2 immutable chunked-arena experiment.

Generated PSC1 TypeScript/DirectJS lower Array.push to a full array copy.
Copying an entire growing V2 arena per node is quadratic in node count;
using a persistent binary trie was also too slow in a 256-insertion JS
experiment because each insertion traverses generator/BigInt index code.

Here only a small *active* chunk is copied on append. Earlier chunks are
retained in a structurally shared List. The active chunk's maximum size
is configurable in the research API. Appending N nodes copies at most
N * chunkLimit references, independent of N (for constant chunkLimit).
Lookup of older nodes is linear in the number of frozen chunks.

Neither arena nor its metadata is currently trusted by the kernel. This
is a storage/representation benchmark, not a checking/admission provider.
-/

structure PsKernelExprV2ChunkedArena where
  active : Array PsKernelExprV2Entry
  frozen : List (Array PsKernelExprV2Entry)
  size : Nat
  chunkLimit : Nat

def psKernelExprV2ChunkedEmptyWithLimit
    (limit : Nat) : PsKernelExprV2ChunkedArena :=
  let actual := if Nat.beq limit 0 then 1 else limit;
  {
    active := Array.emptyWithCapacity 0
    frozen := List.nil
    size := 0
    chunkLimit := actual
  }

/- Research default selected by guarded Node22/TS7 insertion-and-readback CI
   39382668149; remains configurable and is not a whole-kernel speed claim. -/
def psKernelExprV2ChunkedEmpty : PsKernelExprV2ChunkedArena :=
  psKernelExprV2ChunkedEmptyWithLimit 64

def psKernelExprV2ChunkedPush
    (arena : PsKernelExprV2ChunkedArena)
    (entry : PsKernelExprV2Entry) :
    PsKernelExprV2ChunkedArena × Nat :=
  let oldSize := arena.size;
  if Nat.blt (Array.size arena.active) arena.chunkLimit then
    let next : PsKernelExprV2ChunkedArena := {
      active := Array.push arena.active entry
      frozen := arena.frozen
      size := Nat.succ oldSize
      chunkLimit := arena.chunkLimit
    };
    Prod.mk next oldSize
  else
    let newChunk : Array PsKernelExprV2Entry :=
      Array.push (Array.emptyWithCapacity 0) entry;
    let next : PsKernelExprV2ChunkedArena := {
      active := newChunk
      frozen := List.cons arena.active arena.frozen
      size := Nat.succ oldSize
      chunkLimit := arena.chunkLimit
    };
    Prod.mk next oldSize

def psKernelExprV2ChunkedLookupFrozen
    (chunks : List (Array PsKernelExprV2Entry)) :
    Nat -> Option PsKernelExprV2Entry :=
  match chunks with
  | List.nil =>
      fun (_distance : Nat) => Option.none
  | List.cons chunk rest =>
      let smaller : Nat -> Option PsKernelExprV2Entry :=
        psKernelExprV2ChunkedLookupFrozen rest;
      fun (distance : Nat) =>
        let count := Array.size chunk;
        if Nat.blt distance count then
          let index := Nat.sub (Nat.sub count 1) distance;
          Option.some
            (Array.getD chunk index psKernelExprV2DummyEntry)
        else
          smaller (Nat.sub distance count)

def psKernelExprV2ChunkedFind
    (arena : PsKernelExprV2ChunkedArena)
    (id : Nat) : Option PsKernelExprV2Entry :=
  if Nat.blt id arena.size then
    let reverseIndex :=
      Nat.sub (Nat.sub arena.size 1) id;
    let activeSize := Array.size arena.active;
    if Nat.blt reverseIndex activeSize then
      let index := Nat.sub (Nat.sub activeSize 1) reverseIndex;
      Option.some
        (Array.getD arena.active index psKernelExprV2DummyEntry)
    else
      psKernelExprV2ChunkedLookupFrozen
        arena.frozen
        (Nat.sub reverseIndex activeSize)
  else
    Option.none
