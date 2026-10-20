import Ps.KernelCore.Core.ExprV2.Lift

/-
Canonical traversal support. IDs and memo state belong to one immutable arena
lineage. Raw inputs must enter through a Checked function.
-/
def psKernelExprV2TransformChildren
    (node : PsKernelExprV2Node) (depth : Nat) : List (Prod Nat Nat) :=
  match node with
  | PsKernelExprV2Node.app fn arg =>
      List.cons (Prod.mk fn depth) (List.cons (Prod.mk arg depth) List.nil)
  | PsKernelExprV2Node.lam _ type body _ =>
      List.cons (Prod.mk type depth) (List.cons (Prod.mk body (Nat.succ depth)) List.nil)
  | PsKernelExprV2Node.forallE _ type body _ =>
      List.cons (Prod.mk type depth) (List.cons (Prod.mk body (Nat.succ depth)) List.nil)
  | PsKernelExprV2Node.letE _ type value body _ =>
      List.cons (Prod.mk type depth)
        (List.cons (Prod.mk value depth) (List.cons (Prod.mk body (Nat.succ depth)) List.nil))
  | PsKernelExprV2Node.mdata _ body => List.cons (Prod.mk body depth) List.nil
  | PsKernelExprV2Node.proj _ _ body => List.cons (Prod.mk body depth) List.nil
  | _ => List.nil

def psKernelExprV2TransformSameChildren
    (before : List (Prod Nat Nat)) (after : List Nat) : Bool :=
  match before with
  | List.nil =>
      match after with
      | List.nil => true
      | List.cons _ _ => false
  | List.cons first rest =>
      match after with
      | List.nil => false
      | List.cons current tail =>
          if Nat.beq (Prod.fst first) current then psKernelExprV2TransformSameChildren rest tail
          else false

def psKernelExprV2TransformBuildOne
    (arena : PsKernelExprV2PagedArena) (children : List Nat)
    (builder : PsKernelExprV2PagedArena -> Nat -> Except String (PsKernelExprV2PagedArena × Nat)) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  match children with
  | List.nil => Except.error "PSKERNEL_V2_TRANSFORM_CHILDREN"
  | List.cons first rest =>
      match rest with
      | List.nil => builder arena first
      | List.cons _ _ => Except.error "PSKERNEL_V2_TRANSFORM_CHILDREN"

def psKernelExprV2TransformBuildTwo
    (arena : PsKernelExprV2PagedArena) (children : List Nat)
    (builder : PsKernelExprV2PagedArena -> Nat -> Nat -> Except String (PsKernelExprV2PagedArena × Nat)) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  match children with
  | List.nil => Except.error "PSKERNEL_V2_TRANSFORM_CHILDREN"
  | List.cons first rest =>
      match rest with
      | List.nil => Except.error "PSKERNEL_V2_TRANSFORM_CHILDREN"
      | List.cons second tail =>
          match tail with
          | List.nil => builder arena first second
          | List.cons _ _ => Except.error "PSKERNEL_V2_TRANSFORM_CHILDREN"

def psKernelExprV2TransformBuildThree
    (arena : PsKernelExprV2PagedArena) (children : List Nat)
    (builder : PsKernelExprV2PagedArena -> Nat -> Nat -> Nat -> Except String (PsKernelExprV2PagedArena × Nat)) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  match children with
  | List.nil => Except.error "PSKERNEL_V2_TRANSFORM_CHILDREN"
  | List.cons first rest =>
      match rest with
      | List.nil => Except.error "PSKERNEL_V2_TRANSFORM_CHILDREN"
      | List.cons second tail =>
          match tail with
          | List.nil => Except.error "PSKERNEL_V2_TRANSFORM_CHILDREN"
          | List.cons third last =>
              match last with
              | List.nil => builder arena first second third
              | List.cons _ _ => Except.error "PSKERNEL_V2_TRANSFORM_CHILDREN"

def psKernelExprV2TransformBuild
    (arena : PsKernelExprV2PagedArena)
    (node : PsKernelExprV2Node) (children : List Nat) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  match node with
  | PsKernelExprV2Node.app _ _ =>
      psKernelExprV2TransformBuildTwo arena children psKernelExprV2PagedMkApp
  | PsKernelExprV2Node.lam name _ _ info =>
      psKernelExprV2TransformBuildTwo arena children
        (psKernelExprV2PagedLiftMkLam name info)
  | PsKernelExprV2Node.forallE name _ _ info =>
      psKernelExprV2TransformBuildTwo arena children
        (psKernelExprV2PagedLiftMkForall name info)
  | PsKernelExprV2Node.letE name _ _ _ nondep =>
      psKernelExprV2TransformBuildThree arena children
        (psKernelExprV2PagedLiftMkLet name nondep)
  | PsKernelExprV2Node.mdata tag _ =>
      psKernelExprV2TransformBuildOne arena children
        (psKernelExprV2PagedLiftMkMData tag)
  | PsKernelExprV2Node.proj name index _ =>
      psKernelExprV2TransformBuildOne arena children
        (psKernelExprV2PagedLiftMkProj name index)
  | _ => Except.error "PSKERNEL_V2_TRANSFORM_NOT_COMPOSITE"

def psKernelExprV2TransformNatGet (values : List Nat) (index : Nat) : Option Nat :=
  match values with
  | List.nil => Option.none
  | List.cons first rest =>
      match index with
      | Nat.zero => Option.some first
      | Nat.succ remaining => psKernelExprV2TransformNatGet rest remaining

def psKernelExprV2TransformNatLength (values : List Nat) : Nat :=
  match values with
  | List.nil => 0
  | List.cons _ rest => Nat.succ (psKernelExprV2TransformNatLength rest)

def psKernelExprV2TransformNatReverse (values : List Nat) (acc : List Nat) : List Nat :=
  match values with
  | List.nil => acc
  | List.cons first rest => psKernelExprV2TransformNatReverse rest (List.cons first acc)

def psKernelExprV2TransformRequireIds
    (arena : PsKernelExprV2PagedArena) (ids : List Nat) : Except String Unit :=
  match ids with
  | List.nil => Except.ok ()
  | List.cons first rest =>
      match psKernelExprV2PagedFind arena first with
      | Option.none => Except.error "PSKERNEL_V2_TRANSFORM_BAD_REFERENCE"
      | Option.some _ => psKernelExprV2TransformRequireIds arena rest

/- Exact expanded occurrence count, computed once per unique node. -/
structure PsKernelExprV2TransformCountMemo where
  source : Nat
  count : Nat

def psKernelExprV2TransformCountFind
    (memo : List PsKernelExprV2TransformCountMemo) (source : Nat) : Option Nat :=
  match memo with
  | List.nil => Option.none
  | List.cons first rest =>
      if Nat.beq first.source source then Option.some first.count
      else psKernelExprV2TransformCountFind rest source

def psKernelExprV2TransformCountChildren
    (children : List (Prod Nat Nat))
    (recurse : List PsKernelExprV2TransformCountMemo -> Nat ->
      Except String (Prod (List PsKernelExprV2TransformCountMemo) Nat))
    (memo : List PsKernelExprV2TransformCountMemo) :
    Except String (Prod (List PsKernelExprV2TransformCountMemo) Nat) :=
  match children with
  | List.nil => Except.ok (Prod.mk memo 0)
  | List.cons child rest =>
      match recurse memo (Prod.fst child) with
      | Except.error error => Except.error error
      | Except.ok first =>
          match psKernelExprV2TransformCountChildren rest recurse (Prod.fst first) with
          | Except.error error => Except.error error
          | Except.ok tail =>
              Except.ok (Prod.mk (Prod.fst tail) (Nat.add (Prod.snd first) (Prod.snd tail)))

def psKernelExprV2TransformCountWithFuel
    (fuel : Nat) :
    PsKernelExprV2PagedArena -> List PsKernelExprV2TransformCountMemo -> Nat ->
    Except String (Prod (List PsKernelExprV2TransformCountMemo) Nat) :=
  match fuel with
  | Nat.zero =>
      fun (_arena : PsKernelExprV2PagedArena)
          (_memo : List PsKernelExprV2TransformCountMemo) (_root : Nat) =>
        Except.error "PSKERNEL_V2_TRANSFORM_COUNT_FUEL"
  | Nat.succ remaining =>
      let smaller := psKernelExprV2TransformCountWithFuel remaining;
      fun (arena : PsKernelExprV2PagedArena)
          (memo : List PsKernelExprV2TransformCountMemo) (root : Nat) =>
        match psKernelExprV2TransformCountFind memo root with
        | Option.some count => Except.ok (Prod.mk memo count)
        | Option.none =>
            match psKernelExprV2PagedFind arena root with
            | Option.none => Except.error "PSKERNEL_V2_TRANSFORM_BAD_ROOT"
            | Option.some entry =>
                match psKernelExprV2TransformCountChildren
                    (psKernelExprV2TransformChildren entry.node 0) (smaller arena) memo with
                | Except.error error => Except.error error
                | Except.ok result =>
                    let count := Nat.succ (Prod.snd result);
                    Except.ok (Prod.mk
                      (List.cons (PsKernelExprV2TransformCountMemo.mk root count) (Prod.fst result)) count)

def psKernelExprV2TransformCountOnCanonical
    (arena : PsKernelExprV2PagedArena) (root : Nat) : Except String Nat :=
  match psKernelExprV2PagedFind arena root with
  | Option.none => Except.error "PSKERNEL_V2_TRANSFORM_BAD_ROOT"
  | Option.some entry =>
      match psKernelExprV2TransformCountWithFuel (Nat.succ entry.depth) arena List.nil root with
      | Except.error error => Except.error error
      | Except.ok result => Except.ok (Prod.snd result)
