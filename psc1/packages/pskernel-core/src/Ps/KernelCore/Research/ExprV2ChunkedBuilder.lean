import Ps.KernelCore.Research.ExprV2Chunked

/-
Persistent-index smart constructors for the future V2 execution path.

All child references are checked against the *current* immutable indexed
arena before insertion. Metadata is built from verified older nodes rather
than from recursion over an expanded legacy tree.

The source is research-only until the indexed arena and every operation
qualify through both PSC1 source/JS and native kernel checks.
-/

/-
The chunked push is total for valid arena values. Package it in Except to
give all V2 smart constructors a uniform fail-closed API on invalid child IDs.
-/
def psKernelExprV2ChunkedPushChecked
    (arena : PsKernelExprV2ChunkedArena)
    (entry : PsKernelExprV2Entry) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  Except.ok (psKernelExprV2ChunkedPush arena entry)

def psKernelExprV2ChunkedRequire
    (arena : PsKernelExprV2ChunkedArena)
    (id : Nat) :
    Except String PsKernelExprV2Entry :=
  match psKernelExprV2ChunkedFind arena id with
  | Option.none =>
      Except.error "PSKERNEL_V2_CHUNKED_INVALID_CHILD"
  | Option.some entry =>
      Except.ok entry

def psKernelExprV2ChunkedWith1
    (arena : PsKernelExprV2ChunkedArena) (child : Nat)
    (make : PsKernelExprV2Entry -> PsKernelExprV2Entry) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  match psKernelExprV2ChunkedRequire arena child with
  | Except.error error =>
      Except.error error
  | Except.ok first =>
      psKernelExprV2ChunkedPushChecked arena (make first)

def psKernelExprV2ChunkedWith2
    (arena : PsKernelExprV2ChunkedArena) (left right : Nat)
    (make :
      PsKernelExprV2Entry -> PsKernelExprV2Entry ->
      PsKernelExprV2Entry) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  match psKernelExprV2ChunkedRequire arena left with
  | Except.error error =>
      Except.error error
  | Except.ok first =>
      match psKernelExprV2ChunkedRequire arena right with
      | Except.error error =>
          Except.error error
      | Except.ok second =>
          psKernelExprV2ChunkedPushChecked arena (make first second)

def psKernelExprV2ChunkedWith3
    (arena : PsKernelExprV2ChunkedArena)
    (first second third : Nat)
    (make :
      PsKernelExprV2Entry -> PsKernelExprV2Entry ->
      PsKernelExprV2Entry -> PsKernelExprV2Entry) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  match psKernelExprV2ChunkedRequire arena first with
  | Except.error error =>
      Except.error error
  | Except.ok a =>
      match psKernelExprV2ChunkedRequire arena second with
      | Except.error error =>
          Except.error error
      | Except.ok b =>
          match psKernelExprV2ChunkedRequire arena third with
          | Except.error error =>
              Except.error error
          | Except.ok c =>
              psKernelExprV2ChunkedPushChecked arena (make a b c)

def psKernelExprV2ChunkedMkBVar
    (arena : PsKernelExprV2ChunkedArena) (index : Nat) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  psKernelExprV2ChunkedPushChecked arena
    (PsKernelExprV2Entry.mk
      (PsKernelExprV2Node.bvar index)
      (psKernelCacheMix 21 index)
      (Nat.succ index)
      false
      false
      1)

def psKernelExprV2ChunkedMkFVar
    (arena : PsKernelExprV2ChunkedArena) (name : PsKernelName) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  psKernelExprV2ChunkedPushChecked arena
    (PsKernelExprV2Entry.mk
      (PsKernelExprV2Node.fvar name)
      (psKernelCacheMix 22 (psKernelCacheNameHash name))
      0
      true
      false
      1)

def psKernelExprV2ChunkedMkMVar
    (arena : PsKernelExprV2ChunkedArena) (name : PsKernelName) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  psKernelExprV2ChunkedPushChecked arena
    (PsKernelExprV2Entry.mk
      (PsKernelExprV2Node.mvar name)
      (psKernelCacheMix 23 (psKernelCacheNameHash name))
      0
      false
      true
      1)

def psKernelExprV2ChunkedMkSort
    (arena : PsKernelExprV2ChunkedArena) (level : PsKernelLevel) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  psKernelExprV2ChunkedPushChecked arena
    (PsKernelExprV2Entry.mk
      (PsKernelExprV2Node.sort level)
      (psKernelCacheMix 24 (psKernelCacheLevelHash level))
      0
      false
      false
      1)

def psKernelExprV2ChunkedMkConst
    (arena : PsKernelExprV2ChunkedArena)
    (name : PsKernelName) (levels : List PsKernelLevel) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  psKernelExprV2ChunkedPushChecked arena
    (PsKernelExprV2Entry.mk
      (PsKernelExprV2Node.const name levels)
      (psKernelCacheMix
        (psKernelCacheMix 25 (psKernelCacheNameHash name))
        (psKernelCacheLevelListHash levels))
      0
      false
      false
      1)

def psKernelExprV2ChunkedMkLit
    (arena : PsKernelExprV2ChunkedArena) (literal : PsKernelLiteral) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  psKernelExprV2ChunkedPushChecked arena
    (PsKernelExprV2Entry.mk
      (PsKernelExprV2Node.lit literal)
      (psKernelCacheMix 30 (psKernelCacheLiteralHash literal))
      0
      false
      false
      1)

def psKernelExprV2ChunkedMkApp
    (arena : PsKernelExprV2ChunkedArena) (fn arg : Nat) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  psKernelExprV2ChunkedWith2 arena fn arg
    (psKernelExprV2AppEntry fn arg)

def psKernelExprV2ChunkedMkLam
    (arena : PsKernelExprV2ChunkedArena)
    (name : PsKernelName) (type body : Nat)
    (binderInfo : PsKernelBinderInfo) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  psKernelExprV2ChunkedWith2 arena type body
    (psKernelExprV2LamEntry name type body binderInfo)

def psKernelExprV2ChunkedMkForall
    (arena : PsKernelExprV2ChunkedArena)
    (name : PsKernelName) (type body : Nat)
    (binderInfo : PsKernelBinderInfo) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  psKernelExprV2ChunkedWith2 arena type body
    (psKernelExprV2ForallEntry name type body binderInfo)

def psKernelExprV2ChunkedMkLet
    (arena : PsKernelExprV2ChunkedArena)
    (name : PsKernelName) (type value body : Nat)
    (nondep : Bool) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  psKernelExprV2ChunkedWith3 arena type value body
    (psKernelExprV2LetEntry name type value body nondep)

def psKernelExprV2ChunkedMkMData
    (arena : PsKernelExprV2ChunkedArena)
    (metadata body : Nat) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  psKernelExprV2ChunkedWith1 arena body
    (psKernelExprV2MDataEntry metadata body)

def psKernelExprV2ChunkedMkProj
    (arena : PsKernelExprV2ChunkedArena)
    (name : PsKernelName) (index body : Nat) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  psKernelExprV2ChunkedWith1 arena body
    (psKernelExprV2ProjEntry name index body)
