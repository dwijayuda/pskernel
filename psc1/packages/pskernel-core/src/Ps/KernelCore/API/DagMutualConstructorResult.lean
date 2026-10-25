import Ps.KernelCore.API.DagMutualHeader
import Ps.KernelCore.API.DagOrdinaryConstructorResult

/- Private cross-family structural application recognition. No reduction,
   input decoding or declaration publication occurs here. All parameters and
   returned indices are IDs in the same checked canonical append-only arena.
   The complete family name set, including projection type names, is used in
   occurrence checks; hashes never establish a target or parameter match. -/

structure PsKernelExprV2MutualAppInfo where
  target : Nat
  indices : List Nat

def psKernelExprV2MutualContainsConstWithFuel
    (fuel : Nat) :
    PsKernelExprV2PagedArena -> List PsKernelName -> Nat -> Except String Bool :=
  match fuel with
  | Nat.zero =>
      fun (_arena : PsKernelExprV2PagedArena) (_targets : List PsKernelName) (_root : Nat) =>
        Except.error "PSKERNEL_V2_MUTUAL_CONTAINS_CONST_FUEL"
  | Nat.succ remaining =>
      fun (arena : PsKernelExprV2PagedArena) (targets : List PsKernelName) (root : Nat) =>
        match psKernelExprV2PagedRequire arena root with
        | Except.error error => Except.error error
        | Except.ok entry =>
            let recur := psKernelExprV2MutualContainsConstWithFuel remaining;
            match entry.node with
            | PsKernelExprV2Node.const name _ =>
                Except.ok (psKernelNameMember name targets)
            | PsKernelExprV2Node.app fn arg =>
                match recur arena targets fn with
                | Except.error error => Except.error error
                | Except.ok found =>
                    if found then Except.ok true
                    else recur arena targets arg
            | PsKernelExprV2Node.lam _ type body _ =>
                match recur arena targets type with
                | Except.error error => Except.error error
                | Except.ok found =>
                    if found then Except.ok true
                    else recur arena targets body
            | PsKernelExprV2Node.forallE _ type body _ =>
                match recur arena targets type with
                | Except.error error => Except.error error
                | Except.ok found =>
                    if found then Except.ok true
                    else recur arena targets body
            | PsKernelExprV2Node.letE _ type value body _ =>
                match recur arena targets type with
                | Except.error error => Except.error error
                | Except.ok typeFound =>
                    if typeFound then Except.ok true
                    else
                      match recur arena targets value with
                      | Except.error error => Except.error error
                      | Except.ok valueFound =>
                          if valueFound then Except.ok true
                          else recur arena targets body
            | PsKernelExprV2Node.mdata _ body => recur arena targets body
            | PsKernelExprV2Node.proj typeName _ body =>
                if psKernelNameMember typeName targets then Except.ok true
                else recur arena targets body
            | _ => Except.ok false

/- This internal entry requires checked canonical metadata. It does not accept
   a caller-supplied depth certificate or share a checker reduction budget. -/
def psKernelExprV2MutualContainsConstOnCanonical
    (arena : PsKernelExprV2PagedArena) (targets : List PsKernelName) (root : Nat) :
    Except String Bool :=
  match psKernelExprV2PagedRequire arena root with
  | Except.error error => Except.error error
  | Except.ok entry =>
      psKernelExprV2MutualContainsConstWithFuel
        (Nat.succ entry.depth) arena targets root

def psKernelExprV2MutualIndicesContainTarget
    (arena : PsKernelExprV2PagedArena) (targets : List PsKernelName) (indices : List Nat) :
    Except String Bool :=
  match indices with
  | List.nil => Except.ok false
  | List.cons index rest =>
      match psKernelExprV2MutualContainsConstOnCanonical arena targets index with
      | Except.error error => Except.error error
      | Except.ok found =>
          if found then Except.ok true
          else psKernelExprV2MutualIndicesContainTarget arena targets rest

def psKernelExprV2MutualFindTargetHeader
    (types : List PsKernelExprV2MutualTypeHeader) :
    PsKernelName -> Nat -> Option (Prod Nat PsKernelExprV2MutualTypeHeader) :=
  match types with
  | List.nil =>
      fun (_name : PsKernelName) (_index : Nat) => Option.none
  | List.cons first rest =>
      let smaller := psKernelExprV2MutualFindTargetHeader rest;
      fun (name : PsKernelName) (index : Nat) =>
        if psKernelNameEq name first.declaration.name then
          Option.some (Prod.mk index first)
        else smaller name (Nat.succ index)

def psKernelExprV2MutualOpenBinderCount
    (binders : List PsKernelExprV2OrdinaryOpenBinder) : Nat :=
  match binders with
  | List.nil => 0
  | List.cons _ rest => Nat.succ (psKernelExprV2MutualOpenBinderCount rest)

/- Preserve the V1 test order: constant head, universe list, family selector,
   exact parameter fvars, target-specific index arity, all-family occurrences.
   The selector returns the same first matching header/index pair atomically. -/
def psKernelExprV2MutualAppInfoOnCanonical
    (arena : PsKernelExprV2PagedArena) (targets : List PsKernelName)
    (types : List PsKernelExprV2MutualTypeHeader) (levels : List PsKernelLevel)
    (parameters : List PsKernelExprV2OrdinaryOpenBinder) (root : Nat) :
    Except String (Option PsKernelExprV2MutualAppInfo) :=
  match psKernelExprV2TransformAppSpineOnCanonical arena root with
  | Except.error error => Except.error error
  | Except.ok spine =>
      match psKernelExprV2PagedRequire arena (Prod.fst spine) with
      | Except.error error => Except.error error
      | Except.ok entry =>
          match entry.node with
          | PsKernelExprV2Node.const name foundLevels =>
              if psKernelLevelListEq foundLevels levels then
                match psKernelExprV2MutualFindTargetHeader types name 0 with
                | Option.none => Except.ok Option.none
                | Option.some selected =>
                    match psKernelExprV2OrdinaryConsumeResultParams
                        parameters arena (Prod.snd spine) with
                    | Except.error error => Except.error error
                    | Except.ok attempted =>
                        match attempted with
                        | Option.none => Except.ok Option.none
                        | Option.some indices =>
                            if Nat.beq (psKernelExprV2TransformNatLength indices)
                                (psKernelExprV2MutualOpenBinderCount (Prod.snd selected).indices.binders) then
                              match psKernelExprV2MutualIndicesContainTarget arena targets indices with
                              | Except.error error => Except.error error
                              | Except.ok recursive =>
                                  if recursive then Except.ok Option.none
                                  else Except.ok (Option.some
                                    (PsKernelExprV2MutualAppInfo.mk (Prod.fst selected) indices))
                            else Except.ok Option.none
              else Except.ok Option.none
          | _ => Except.ok Option.none

