import Ps.KernelCore.Core.ExprV2.TransformSupport

/- Expanded-tree size over an immutable canonical arena, with a private memo
   keyed by owning IDs. Shared children contribute once per syntactic edge,
   while an already visited source ID is not traversed again. The public
   internal-canonical entry starts empty and never accepts caller memo facts.
   This supplies the exact V1 structural budget without decoding input terms. -/

structure PsKernelExprV2SizeMemo where
  source : Nat
  count : Nat

def psKernelExprV2ExpandedSizeChildIds
    (node : PsKernelExprV2Node) : List Nat :=
  match node with
  | PsKernelExprV2Node.app fn arg => List.cons fn (List.cons arg List.nil)
  | PsKernelExprV2Node.lam _ type body _ => List.cons type (List.cons body List.nil)
  | PsKernelExprV2Node.forallE _ type body _ => List.cons type (List.cons body List.nil)
  | PsKernelExprV2Node.letE _ type value body _ =>
      List.cons type (List.cons value (List.cons body List.nil))
  | PsKernelExprV2Node.mdata _ body => List.cons body List.nil
  | PsKernelExprV2Node.proj _ _ body => List.cons body List.nil
  | _ => List.nil

def psKernelExprV2SizeMemoFind
    (entries : List PsKernelExprV2SizeMemo) (source : Nat) : Option Nat :=
  match entries with
  | List.nil => Option.none
  | List.cons first rest =>
      if Nat.beq first.source source then Option.some first.count
      else psKernelExprV2SizeMemoFind rest source

def psKernelExprV2ExpandedSizeChildren
    (children : List Nat) :
    (Nat -> List PsKernelExprV2SizeMemo ->
      Except String (Prod (List PsKernelExprV2SizeMemo) Nat)) ->
    List PsKernelExprV2SizeMemo ->
    Except String (Prod (List PsKernelExprV2SizeMemo) Nat) :=
  match children with
  | List.nil =>
      fun
        (_visit : Nat -> List PsKernelExprV2SizeMemo ->
          Except String (Prod (List PsKernelExprV2SizeMemo) Nat))
        (memo : List PsKernelExprV2SizeMemo) => Except.ok (Prod.mk memo 0)
  | List.cons first rest =>
      let smaller := psKernelExprV2ExpandedSizeChildren rest;
      fun
        (visit : Nat -> List PsKernelExprV2SizeMemo ->
          Except String (Prod (List PsKernelExprV2SizeMemo) Nat))
        (memo : List PsKernelExprV2SizeMemo) =>
        match visit first memo with
        | Except.error error => Except.error error
        | Except.ok head =>
            match smaller visit (Prod.fst head) with
            | Except.error error => Except.error error
            | Except.ok tail =>
                Except.ok (Prod.mk (Prod.fst tail) (Nat.add (Prod.snd head) (Prod.snd tail)))

def psKernelExprV2ExpandedSizeWithFuel
    (fuel : Nat) :
    PsKernelExprV2PagedArena -> Nat -> List PsKernelExprV2SizeMemo ->
    Except String (Prod (List PsKernelExprV2SizeMemo) Nat) :=
  match fuel with
  | Nat.zero =>
      fun (_arena : PsKernelExprV2PagedArena) (_root : Nat)
          (_memo : List PsKernelExprV2SizeMemo) =>
        Except.error "PSKERNEL_V2_EXPANDED_SIZE_FUEL"
  | Nat.succ remaining =>
      let smaller := psKernelExprV2ExpandedSizeWithFuel remaining;
      fun (arena : PsKernelExprV2PagedArena) (root : Nat)
          (memo : List PsKernelExprV2SizeMemo) =>
        match psKernelExprV2SizeMemoFind memo root with
        | Option.some count => Except.ok (Prod.mk memo count)
        | Option.none =>
            match psKernelExprV2PagedRequire arena root with
            | Except.error error => Except.error error
            | Except.ok entry =>
                let children := psKernelExprV2ExpandedSizeChildIds entry.node;
                let visit := fun (child : Nat) (entries : List PsKernelExprV2SizeMemo) =>
                  smaller arena child entries;
                match psKernelExprV2ExpandedSizeChildren children visit memo with
                | Except.error error => Except.error error
                | Except.ok result =>
                    let count := Nat.succ (Prod.snd result);
                    Except.ok (Prod.mk
                      (List.cons (PsKernelExprV2SizeMemo.mk root count) (Prod.fst result)) count)

def psKernelExprV2ExpandedSizeOnCanonical
    (arena : PsKernelExprV2PagedArena) (root : Nat) : Except String Nat :=
  match psKernelExprV2PagedRequire arena root with
  | Except.error error => Except.error error
  | Except.ok entry =>
      match psKernelExprV2ExpandedSizeWithFuel
          (Nat.succ entry.depth) arena root List.nil with
      | Except.error error => Except.error error
      | Except.ok result => Except.ok (Prod.snd result)
