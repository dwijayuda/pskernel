import Ps.KernelCore.Core.ExprV2.Transform

/- Application-spine helpers over one owning canonical arena. -/
def psKernelExprV2TransformAppSpineWithFuel
    (fuel : Nat) :
    PsKernelExprV2PagedArena -> Nat -> List Nat -> Except String (Prod Nat (List Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (_arena : PsKernelExprV2PagedArena) (_root : Nat) (_args : List Nat) =>
        Except.error "PSKERNEL_V2_APP_SPINE_FUEL"
  | Nat.succ remaining =>
      let smaller := psKernelExprV2TransformAppSpineWithFuel remaining;
      fun (arena : PsKernelExprV2PagedArena) (root : Nat) (args : List Nat) =>
        match psKernelExprV2PagedFind arena root with
        | Option.none => Except.error "PSKERNEL_V2_TRANSFORM_BAD_ROOT"
        | Option.some entry =>
            match entry.node with
            | PsKernelExprV2Node.app fn argument => smaller arena fn (List.cons argument args)
            | _ => Except.ok (Prod.mk root args)

def psKernelExprV2TransformAppSpineOnCanonical
    (arena : PsKernelExprV2PagedArena) (root : Nat) : Except String (Prod Nat (List Nat)) :=
  match psKernelExprV2PagedFind arena root with
  | Option.none => Except.error "PSKERNEL_V2_TRANSFORM_BAD_ROOT"
  | Option.some entry =>
      psKernelExprV2TransformAppSpineWithFuel (Nat.succ entry.depth) arena root List.nil

def psKernelExprV2TransformApplyArgsOnCanonical
    (args : List Nat) (arena : PsKernelExprV2PagedArena) (head : Nat) :
    Except String (Prod PsKernelExprV2PagedArena Nat) :=
  match psKernelExprV2PagedFind arena head with
  | Option.none => Except.error "PSKERNEL_V2_TRANSFORM_BAD_ROOT"
  | Option.some _ =>
      match args with
      | List.nil => Except.ok (Prod.mk arena head)
      | List.cons first rest =>
          match psKernelExprV2PagedMkApp arena head first with
          | Except.error error => Except.error error
          | Except.ok result =>
              psKernelExprV2TransformApplyArgsOnCanonical rest (Prod.fst result) (Prod.snd result)

def psKernelExprV2PagedAppSpineChecked
    (source : PsKernelExprV2PagedArena) (root : Nat) : Except String (Prod Nat (List Nat)) :=
  match psKernelExprV2PagedValidate source with
  | Except.error error => Except.error error
  | Except.ok canonical => psKernelExprV2TransformAppSpineOnCanonical canonical root

def psKernelExprV2PagedApplyArgsChecked
    (source : PsKernelExprV2PagedArena) (head : Nat) (args : List Nat) :
    Except String (Prod PsKernelExprV2PagedArena Nat) :=
  match psKernelExprV2PagedValidate source with
  | Except.error error => Except.error error
  | Except.ok canonical =>
      match psKernelExprV2TransformApplyArgsOnCanonical args canonical head with
      | Except.error error => Except.error error
      | Except.ok result =>
          match psKernelExprV2PagedValidate (Prod.fst result) with
          | Except.error error => Except.error error
          | Except.ok verified => Except.ok (Prod.mk verified (Prod.snd result))
