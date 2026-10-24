import Ps.KernelCore.API.DagOrdinaryHeaderTypes
import Ps.KernelCore.Core.ExprV2.TransformSpine

/-
Private structural constructor-result analysis over one canonical owning arena.
The exact target, universe list and existing parameter fvar names are compared
without WHNF or DefEq. Successful results retain the original index IDs.

ContainsConst follows V1 traversal and short-circuit order, including a
projection's type name before its receiver. Its explicit fuel is a structural
traversal bound; the canonical wrapper obtains that bound from checked depth,
independently of checker fuel. None of these helpers publishes a declaration.
-/
def psKernelExprV2OrdinaryConsumeResultParams
    (parameters : List PsKernelExprV2OrdinaryOpenBinder) :
    PsKernelExprV2PagedArena -> List Nat -> Except String (Option (List Nat)) :=
  match parameters with
  | List.nil =>
      fun (_arena : PsKernelExprV2PagedArena) (args : List Nat) =>
        Except.ok (Option.some args)
  | List.cons parameter rest =>
      fun (arena : PsKernelExprV2PagedArena) (args : List Nat) =>
        match args with
        | List.nil => Except.ok Option.none
        | List.cons arg tail =>
            match psKernelExprV2PagedRequire arena arg with
            | Except.error error => Except.error error
            | Except.ok entry =>
                match entry.node with
                | PsKernelExprV2Node.fvar name =>
                    if psKernelNameEq name parameter.internalName then
                      let smaller := psKernelExprV2OrdinaryConsumeResultParams rest;
                      smaller arena tail
                    else
                      Except.ok Option.none
                | _ => Except.ok Option.none

def psKernelExprV2OrdinaryInductiveAppIndices
    (arena : PsKernelExprV2PagedArena) (target : PsKernelName)
    (levels : List PsKernelLevel)
    (parameters : List PsKernelExprV2OrdinaryOpenBinder)
    (numIndices root : Nat) : Except String (Option (List Nat)) :=
  match psKernelExprV2TransformAppSpineOnCanonical arena root with
  | Except.error error => Except.error error
  | Except.ok spine =>
      match psKernelExprV2PagedRequire arena (Prod.fst spine) with
      | Except.error error => Except.error error
      | Except.ok entry =>
          match entry.node with
          | PsKernelExprV2Node.const resultName resultLevels =>
              if psKernelNameEq resultName target then
                if psKernelLevelListEq resultLevels levels then
                  match psKernelExprV2OrdinaryConsumeResultParams
                      parameters arena (Prod.snd spine) with
                  | Except.error error => Except.error error
                  | Except.ok matched =>
                      match matched with
                      | Option.none => Except.ok Option.none
                      | Option.some indices =>
                          if Nat.beq (psKernelExprV2TransformNatLength indices) numIndices then
                            Except.ok (Option.some indices)
                          else
                            Except.ok Option.none
                else
                  Except.ok Option.none
              else
                Except.ok Option.none
          | _ => Except.ok Option.none

def psKernelExprV2OrdinaryContainsConstWithFuel
    (fuel : Nat) :
    PsKernelExprV2PagedArena -> PsKernelName -> Nat -> Except String Bool :=
  match fuel with
  | Nat.zero =>
      fun (_arena : PsKernelExprV2PagedArena) (_target : PsKernelName) (_root : Nat) =>
        Except.error "PSKERNEL_V2_ORDINARY_CONTAINS_CONST_FUEL"
  | Nat.succ remaining =>
      fun (arena : PsKernelExprV2PagedArena) (target : PsKernelName) (root : Nat) =>
        match psKernelExprV2PagedRequire arena root with
        | Except.error error => Except.error error
        | Except.ok entry =>
            let recur := psKernelExprV2OrdinaryContainsConstWithFuel remaining;
            match entry.node with
            | PsKernelExprV2Node.const name _ =>
                Except.ok (psKernelNameEq name target)
            | PsKernelExprV2Node.app fn arg =>
                match recur arena target fn with
                | Except.error error => Except.error error
                | Except.ok found =>
                    if found then Except.ok true
                    else recur arena target arg
            | PsKernelExprV2Node.lam _ type body _ =>
                match recur arena target type with
                | Except.error error => Except.error error
                | Except.ok found =>
                    if found then Except.ok true
                    else recur arena target body
            | PsKernelExprV2Node.forallE _ type body _ =>
                match recur arena target type with
                | Except.error error => Except.error error
                | Except.ok found =>
                    if found then Except.ok true
                    else recur arena target body
            | PsKernelExprV2Node.letE _ type value body _ =>
                match recur arena target type with
                | Except.error error => Except.error error
                | Except.ok typeFound =>
                    if typeFound then Except.ok true
                    else
                      match recur arena target value with
                      | Except.error error => Except.error error
                      | Except.ok valueFound =>
                          if valueFound then Except.ok true
                          else recur arena target body
            | PsKernelExprV2Node.mdata _ body => recur arena target body
            | PsKernelExprV2Node.proj typeName _ body =>
                if psKernelNameEq typeName target then Except.ok true
                else recur arena target body
            | _ => Except.ok false

/- This internal entry requires checked canonical metadata. It does not accept
   a caller-supplied depth certificate or share a checker reduction budget. -/
def psKernelExprV2OrdinaryContainsConstOnCanonical
    (arena : PsKernelExprV2PagedArena) (target : PsKernelName) (root : Nat) :
    Except String Bool :=
  match psKernelExprV2PagedRequire arena root with
  | Except.error error => Except.error error
  | Except.ok entry =>
      psKernelExprV2OrdinaryContainsConstWithFuel
        (Nat.succ entry.depth) arena target root

def psKernelExprV2OrdinaryIndicesContainTarget
    (arena : PsKernelExprV2PagedArena) (target : PsKernelName) (indices : List Nat) :
    Except String Bool :=
  match indices with
  | List.nil => Except.ok false
  | List.cons index rest =>
      match psKernelExprV2OrdinaryContainsConstOnCanonical arena target index with
      | Except.error error => Except.error error
      | Except.ok found =>
          if found then Except.ok true
          else psKernelExprV2OrdinaryIndicesContainTarget arena target rest

def psKernelExprV2OrdinaryValidateConstructorResult
    (arena : PsKernelExprV2PagedArena) (target : PsKernelName)
    (levels : List PsKernelLevel)
    (parameters : List PsKernelExprV2OrdinaryOpenBinder)
    (numIndices root : Nat) : Except String (List Nat) :=
  match psKernelExprV2OrdinaryInductiveAppIndices
      arena target levels parameters numIndices root with
  | Except.error error => Except.error error
  | Except.ok matched =>
      match matched with
      | Option.none =>
          Except.error
            "simple inductive constructor must return the declared datatype with matching parameters and index arity"
      | Option.some indices =>
          match psKernelExprV2OrdinaryIndicesContainTarget arena target indices with
          | Except.error error => Except.error error
          | Except.ok found =>
              if found then
                Except.error
                  "simple inductive constructor return index contains a recursive occurrence"
              else
                Except.ok indices
