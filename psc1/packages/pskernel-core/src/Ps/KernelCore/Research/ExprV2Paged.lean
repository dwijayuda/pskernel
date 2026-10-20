import Ps.KernelCore.Research.ExprV2Chunked

/-
Expression V2 / M4 research: persistent two-level paged arena.

The portable TypeScript/DirectJS backends currently copy an immutable Array
on Array.push. A single growing Array therefore creates O(N^2) total copy
work over N inserts. The 64-node chunked implementation bounds append copy
work, but traverses a List of frozen chunks when reading older nodes.

This design has:
  pages: a directly indexable immutable Array of full completed pages,
  active: an immutable Array of at most pageLimit entries,
  size: total number of entries, and
  pageLimit: page capacity, clamped to >= 1.

Push copies at most pageLimit active entries. Once per page, it appends one
chunk to the immutable outer Array, copying O(number of existing pages)
references. Thus cumulative copying is O(N * pageLimit + (N/pageLimit)^2).
Read addresses a completed page by div/mod and Array.getD, with no linear
list walk. The outer Array still costs more on very large DAGs; performance
must be measured before promotion, particularly for generated JS.

This is an isolated data-structure experiment, not a kernel checking
decision or proof token. All arbitrary external arenas need replay validation
before their metadata is allowed into future checker fast paths.
-/

structure PsKernelExprV2PagedArena where
  pages : Array (Array PsKernelExprV2Entry)
  active : Array PsKernelExprV2Entry
  size : Nat
  pageLimit : Nat

def psKernelExprV2PagedEmptyWithLimit
    (limit : Nat) : PsKernelExprV2PagedArena :=
  let actual : Nat := if Nat.beq limit 0 then 1 else limit;
  {
    pages := Array.emptyWithCapacity 0
    active := Array.emptyWithCapacity 0
    size := 0
    pageLimit := actual
  }

def psKernelExprV2PagedEmpty : PsKernelExprV2PagedArena :=
  psKernelExprV2PagedEmptyWithLimit 64

def psKernelExprV2PagedPush
    (arena : PsKernelExprV2PagedArena)
    (entry : PsKernelExprV2Entry) :
    PsKernelExprV2PagedArena × Nat :=
  let oldId := arena.size;
  if Nat.blt (Array.size arena.active) arena.pageLimit then
    let next : PsKernelExprV2PagedArena := {
      pages := arena.pages
      active := Array.push arena.active entry
      size := Nat.succ oldId
      pageLimit := arena.pageLimit
    };
    Prod.mk next oldId
  else
    let nextActive : Array PsKernelExprV2Entry :=
      Array.push (Array.emptyWithCapacity 0) entry;
    let next : PsKernelExprV2PagedArena := {
      pages := Array.push arena.pages arena.active
      active := nextActive
      size := Nat.succ oldId
      pageLimit := arena.pageLimit
    };
    Prod.mk next oldId

def psKernelExprV2PagedGet
    (chunk : Array PsKernelExprV2Entry)
    (offset : Nat) : Option PsKernelExprV2Entry :=
  if Nat.blt offset (Array.size chunk) then
    Option.some
      (Array.getD chunk offset psKernelExprV2DummyEntry)
  else
    Option.none

def psKernelExprV2PagedFind
    (arena : PsKernelExprV2PagedArena)
    (id : Nat) : Option PsKernelExprV2Entry :=
  if Nat.beq arena.pageLimit 0 then
    Option.none
  else if Nat.blt id arena.size then
    let page := Nat.div id arena.pageLimit;
    let offset := Nat.mod id arena.pageLimit;
    let full := Array.size arena.pages;
    if Nat.blt page full then
      let chunk : Array PsKernelExprV2Entry :=
        Array.getD
          arena.pages
          page
          (Array.emptyWithCapacity 0);
      psKernelExprV2PagedGet chunk offset
    else if Nat.beq page full then
      psKernelExprV2PagedGet arena.active offset
    else
      Option.none
  else
    Option.none
