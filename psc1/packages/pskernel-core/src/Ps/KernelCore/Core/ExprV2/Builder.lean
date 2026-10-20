import Ps.KernelCore.Core.ExprV2.Paged

/-
Two-level paged smart constructors for Expression V2.

Every child reference is checked against the owning immutable paged arena
before appending a fresh node. Metadata is computed from prior validated
child entries, not by expanding the legacy expression tree.

These constructors preserve invariants only for empty or replay-validated
input arenas. Require checks reference bounds, not the validity of caller-
supplied metadata. The public checking boundary validates arbitrary arenas.
-/

/-
Low-level append used after a constructor computes an entry. The historical
PushChecked name refers to its uniform Except return shape; it does not
validate arbitrary entry fields. It is not an untrusted-input boundary.
-/
def psKernelExprV2PagedPushChecked
    (arena : PsKernelExprV2PagedArena)
    (entry : PsKernelExprV2Entry) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  Except.ok (psKernelExprV2PagedPush arena entry)

def psKernelExprV2PagedRequire
    (arena : PsKernelExprV2PagedArena)
    (id : Nat) :
    Except String PsKernelExprV2Entry :=
  match psKernelExprV2PagedFind arena id with
  | Option.none =>
      Except.error "PSKERNEL_V2_PAGED_INVALID_CHILD"
  | Option.some entry =>
      Except.ok entry

def psKernelExprV2PagedWith1
    (arena : PsKernelExprV2PagedArena) (child : Nat)
    (make : PsKernelExprV2Entry -> PsKernelExprV2Entry) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  match psKernelExprV2PagedRequire arena child with
  | Except.error error =>
      Except.error error
  | Except.ok first =>
      psKernelExprV2PagedPushChecked arena (make first)

def psKernelExprV2PagedWith2
    (arena : PsKernelExprV2PagedArena) (left right : Nat)
    (make :
      PsKernelExprV2Entry -> PsKernelExprV2Entry ->
      PsKernelExprV2Entry) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  match psKernelExprV2PagedRequire arena left with
  | Except.error error =>
      Except.error error
  | Except.ok first =>
      match psKernelExprV2PagedRequire arena right with
      | Except.error error =>
          Except.error error
      | Except.ok second =>
          psKernelExprV2PagedPushChecked arena (make first second)

def psKernelExprV2PagedWith3
    (arena : PsKernelExprV2PagedArena)
    (first second third : Nat)
    (make :
      PsKernelExprV2Entry -> PsKernelExprV2Entry ->
      PsKernelExprV2Entry -> PsKernelExprV2Entry) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  match psKernelExprV2PagedRequire arena first with
  | Except.error error =>
      Except.error error
  | Except.ok a =>
      match psKernelExprV2PagedRequire arena second with
      | Except.error error =>
          Except.error error
      | Except.ok b =>
          match psKernelExprV2PagedRequire arena third with
          | Except.error error =>
              Except.error error
          | Except.ok c =>
              psKernelExprV2PagedPushChecked arena (make a b c)

def psKernelExprV2PagedMkBVar
    (arena : PsKernelExprV2PagedArena) (index : Nat) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  psKernelExprV2PagedPushChecked arena
    (PsKernelExprV2Entry.mk
      (PsKernelExprV2Node.bvar index)
      (psKernelCacheMix 21 index)
      (Nat.succ index)
      false
      false
      1)

def psKernelExprV2PagedMkFVar
    (arena : PsKernelExprV2PagedArena) (name : PsKernelName) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  psKernelExprV2PagedPushChecked arena
    (PsKernelExprV2Entry.mk
      (PsKernelExprV2Node.fvar name)
      (psKernelCacheMix 22 (psKernelCacheNameHash name))
      0
      true
      false
      1)

def psKernelExprV2PagedMkMVar
    (arena : PsKernelExprV2PagedArena) (name : PsKernelName) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  psKernelExprV2PagedPushChecked arena
    (PsKernelExprV2Entry.mk
      (PsKernelExprV2Node.mvar name)
      (psKernelCacheMix 23 (psKernelCacheNameHash name))
      0
      false
      true
      1)

def psKernelExprV2PagedMkSort
    (arena : PsKernelExprV2PagedArena) (level : PsKernelLevel) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  psKernelExprV2PagedPushChecked arena
    (PsKernelExprV2Entry.mk
      (PsKernelExprV2Node.sort level)
      (psKernelCacheMix 24 (psKernelCacheLevelHash level))
      0
      false
      false
      1)

def psKernelExprV2PagedMkConst
    (arena : PsKernelExprV2PagedArena)
    (name : PsKernelName) (levels : List PsKernelLevel) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  psKernelExprV2PagedPushChecked arena
    (PsKernelExprV2Entry.mk
      (PsKernelExprV2Node.const name levels)
      (psKernelCacheMix
        (psKernelCacheMix 25 (psKernelCacheNameHash name))
        (psKernelCacheLevelListHash levels))
      0
      false
      false
      1)

def psKernelExprV2PagedMkLit
    (arena : PsKernelExprV2PagedArena) (literal : PsKernelLiteral) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  psKernelExprV2PagedPushChecked arena
    (PsKernelExprV2Entry.mk
      (PsKernelExprV2Node.lit literal)
      (psKernelCacheMix 30 (psKernelCacheLiteralHash literal))
      0
      false
      false
      1)

def psKernelExprV2PagedMkApp
    (arena : PsKernelExprV2PagedArena) (fn arg : Nat) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  psKernelExprV2PagedWith2 arena fn arg
    (psKernelExprV2AppEntry fn arg)

def psKernelExprV2PagedMkLam
    (arena : PsKernelExprV2PagedArena)
    (name : PsKernelName) (type body : Nat)
    (binderInfo : PsKernelBinderInfo) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  psKernelExprV2PagedWith2 arena type body
    (psKernelExprV2LamEntry name type body binderInfo)

def psKernelExprV2PagedMkForall
    (arena : PsKernelExprV2PagedArena)
    (name : PsKernelName) (type body : Nat)
    (binderInfo : PsKernelBinderInfo) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  psKernelExprV2PagedWith2 arena type body
    (psKernelExprV2ForallEntry name type body binderInfo)

def psKernelExprV2PagedMkLet
    (arena : PsKernelExprV2PagedArena)
    (name : PsKernelName) (type value body : Nat)
    (nondep : Bool) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  psKernelExprV2PagedWith3 arena type value body
    (psKernelExprV2LetEntry name type value body nondep)

def psKernelExprV2PagedMkMData
    (arena : PsKernelExprV2PagedArena)
    (metadata body : Nat) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  psKernelExprV2PagedWith1 arena body
    (psKernelExprV2MDataEntry metadata body)

def psKernelExprV2PagedMkProj
    (arena : PsKernelExprV2PagedArena)
    (name : PsKernelName) (index body : Nat) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  psKernelExprV2PagedWith1 arena body
    (psKernelExprV2ProjEntry name index body)
