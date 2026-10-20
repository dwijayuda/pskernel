import Ps.KernelCore.Research.ExprV2Index

/-
Persistent-index smart constructors for the future V2 execution path.

All child references are checked against the *current* immutable indexed
arena before insertion. Metadata is built from verified older nodes rather
than from recursion over an expanded legacy tree.

The source is research-only until the indexed arena and every operation
qualify through both PSC1 source/JS and native kernel checks.
-/

def psKernelExprV2IndexedRequire
    (arena : PsKernelExprV2IndexedArena)
    (id : Nat) :
    Except String PsKernelExprV2Entry :=
  match psKernelExprV2IndexedFind arena id with
  | Option.none =>
      Except.error "PSKERNEL_V2_INDEXED_INVALID_CHILD"
  | Option.some entry =>
      Except.ok entry

def psKernelExprV2IndexedWith1
    (arena : PsKernelExprV2IndexedArena) (child : Nat)
    (make : PsKernelExprV2Entry -> PsKernelExprV2Entry) :
    Except String (PsKernelExprV2IndexedArena × Nat) :=
  match psKernelExprV2IndexedRequire arena child with
  | Except.error error =>
      Except.error error
  | Except.ok first =>
      psKernelExprV2IndexedPush arena (make first)

def psKernelExprV2IndexedWith2
    (arena : PsKernelExprV2IndexedArena) (left right : Nat)
    (make :
      PsKernelExprV2Entry -> PsKernelExprV2Entry ->
      PsKernelExprV2Entry) :
    Except String (PsKernelExprV2IndexedArena × Nat) :=
  match psKernelExprV2IndexedRequire arena left with
  | Except.error error =>
      Except.error error
  | Except.ok first =>
      match psKernelExprV2IndexedRequire arena right with
      | Except.error error =>
          Except.error error
      | Except.ok second =>
          psKernelExprV2IndexedPush arena (make first second)

def psKernelExprV2IndexedWith3
    (arena : PsKernelExprV2IndexedArena)
    (first second third : Nat)
    (make :
      PsKernelExprV2Entry -> PsKernelExprV2Entry ->
      PsKernelExprV2Entry -> PsKernelExprV2Entry) :
    Except String (PsKernelExprV2IndexedArena × Nat) :=
  match psKernelExprV2IndexedRequire arena first with
  | Except.error error =>
      Except.error error
  | Except.ok a =>
      match psKernelExprV2IndexedRequire arena second with
      | Except.error error =>
          Except.error error
      | Except.ok b =>
          match psKernelExprV2IndexedRequire arena third with
          | Except.error error =>
              Except.error error
          | Except.ok c =>
              psKernelExprV2IndexedPush arena (make a b c)

def psKernelExprV2IndexedMkBVar
    (arena : PsKernelExprV2IndexedArena) (index : Nat) :
    Except String (PsKernelExprV2IndexedArena × Nat) :=
  psKernelExprV2IndexedPush arena
    (PsKernelExprV2Entry.mk
      (PsKernelExprV2Node.bvar index)
      (psKernelCacheMix 21 index)
      (Nat.succ index)
      false
      false
      1)

def psKernelExprV2IndexedMkFVar
    (arena : PsKernelExprV2IndexedArena) (name : PsKernelName) :
    Except String (PsKernelExprV2IndexedArena × Nat) :=
  psKernelExprV2IndexedPush arena
    (PsKernelExprV2Entry.mk
      (PsKernelExprV2Node.fvar name)
      (psKernelCacheMix 22 (psKernelCacheNameHash name))
      0
      true
      false
      1)

def psKernelExprV2IndexedMkMVar
    (arena : PsKernelExprV2IndexedArena) (name : PsKernelName) :
    Except String (PsKernelExprV2IndexedArena × Nat) :=
  psKernelExprV2IndexedPush arena
    (PsKernelExprV2Entry.mk
      (PsKernelExprV2Node.mvar name)
      (psKernelCacheMix 23 (psKernelCacheNameHash name))
      0
      false
      true
      1)

def psKernelExprV2IndexedMkSort
    (arena : PsKernelExprV2IndexedArena) (level : PsKernelLevel) :
    Except String (PsKernelExprV2IndexedArena × Nat) :=
  psKernelExprV2IndexedPush arena
    (PsKernelExprV2Entry.mk
      (PsKernelExprV2Node.sort level)
      (psKernelCacheMix 24 (psKernelCacheLevelHash level))
      0
      false
      false
      1)

def psKernelExprV2IndexedMkConst
    (arena : PsKernelExprV2IndexedArena)
    (name : PsKernelName) (levels : List PsKernelLevel) :
    Except String (PsKernelExprV2IndexedArena × Nat) :=
  psKernelExprV2IndexedPush arena
    (PsKernelExprV2Entry.mk
      (PsKernelExprV2Node.const name levels)
      (psKernelCacheMix
        (psKernelCacheMix 25 (psKernelCacheNameHash name))
        (psKernelCacheLevelListHash levels))
      0
      false
      false
      1)

def psKernelExprV2IndexedMkLit
    (arena : PsKernelExprV2IndexedArena) (literal : PsKernelLiteral) :
    Except String (PsKernelExprV2IndexedArena × Nat) :=
  psKernelExprV2IndexedPush arena
    (PsKernelExprV2Entry.mk
      (PsKernelExprV2Node.lit literal)
      (psKernelCacheMix 30 (psKernelCacheLiteralHash literal))
      0
      false
      false
      1)

def psKernelExprV2IndexedMkApp
    (arena : PsKernelExprV2IndexedArena) (fn arg : Nat) :
    Except String (PsKernelExprV2IndexedArena × Nat) :=
  psKernelExprV2IndexedWith2 arena fn arg
    (psKernelExprV2AppEntry fn arg)

def psKernelExprV2IndexedMkLam
    (arena : PsKernelExprV2IndexedArena)
    (name : PsKernelName) (type body : Nat)
    (binderInfo : PsKernelBinderInfo) :
    Except String (PsKernelExprV2IndexedArena × Nat) :=
  psKernelExprV2IndexedWith2 arena type body
    (psKernelExprV2LamEntry name type body binderInfo)

def psKernelExprV2IndexedMkForall
    (arena : PsKernelExprV2IndexedArena)
    (name : PsKernelName) (type body : Nat)
    (binderInfo : PsKernelBinderInfo) :
    Except String (PsKernelExprV2IndexedArena × Nat) :=
  psKernelExprV2IndexedWith2 arena type body
    (psKernelExprV2ForallEntry name type body binderInfo)

def psKernelExprV2IndexedMkLet
    (arena : PsKernelExprV2IndexedArena)
    (name : PsKernelName) (type value body : Nat)
    (nondep : Bool) :
    Except String (PsKernelExprV2IndexedArena × Nat) :=
  psKernelExprV2IndexedWith3 arena type value body
    (psKernelExprV2LetEntry name type value body nondep)

def psKernelExprV2IndexedMkMData
    (arena : PsKernelExprV2IndexedArena)
    (metadata body : Nat) :
    Except String (PsKernelExprV2IndexedArena × Nat) :=
  psKernelExprV2IndexedWith1 arena body
    (psKernelExprV2MDataEntry metadata body)

def psKernelExprV2IndexedMkProj
    (arena : PsKernelExprV2IndexedArena)
    (name : PsKernelName) (index body : Nat) :
    Except String (PsKernelExprV2IndexedArena × Nat) :=
  psKernelExprV2IndexedWith1 arena body
    (psKernelExprV2ProjEntry name index body)
