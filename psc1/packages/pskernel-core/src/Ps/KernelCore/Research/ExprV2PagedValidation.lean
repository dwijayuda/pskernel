import Ps.KernelCore.Research.ExprV2PagedBuilder
import Ps.KernelCore.Research.ExprV2PortableValidation

/-
V2 M4 independent portable fail-closed paged arena validator.

A public paged graph may have arbitrary layout and metadata. This verifier:
  * rejects zero page capacity, incomplete/oversized frozen pages, and size
    inconsistent with the completed-page table and active page;
  * replays each source DAG node in increasing node-ID order using canonical
    paged smart constructors, so forward edges and cycles fail closed;
  * checks *every* cached hash, loose bvar range, FVar/MVar flag, and depth
    against independently rebuilt metadata;
  * returns only the newly rebuilt canonical arena, never the unvalidated
    original payload.

The trusted production checker does NOT consume paged expressions. This
research validation has not been mechanically proved sound.
-/

def psKernelExprV2PagedFullPagesFuel
    (fuel : Nat) :
    Array (Array PsKernelExprV2Entry) -> Nat -> Nat -> Bool :=
  match fuel with
  | Nat.zero =>
      fun (_pages : Array (Array PsKernelExprV2Entry)) =>
        fun (_capacity : Nat) =>
          fun (_index : Nat) => false
  | Nat.succ remaining =>
      let smaller :
          Array (Array PsKernelExprV2Entry) -> Nat -> Nat -> Bool :=
        psKernelExprV2PagedFullPagesFuel remaining;
      fun (pages : Array (Array PsKernelExprV2Entry)) =>
        fun (capacity : Nat) =>
          fun (index : Nat) =>
            if Nat.beq index (Array.size pages) then
              true
            else
              let chunk : Array PsKernelExprV2Entry :=
                Array.getD pages index (Array.emptyWithCapacity 0);
              if Nat.beq (Array.size chunk) capacity then
                smaller pages capacity (Nat.succ index)
              else
                false

def psKernelExprV2PagedShapeValid
    (source : PsKernelExprV2PagedArena) : Bool :=
  if Nat.beq source.pageLimit 0 then
    false
  else
    if Nat.ble (Array.size source.active) source.pageLimit then
      if Nat.beq source.size
          (Nat.add
            (Nat.mul (Array.size source.pages) source.pageLimit)
            (Array.size source.active)) then
        psKernelExprV2PagedFullPagesFuel
          (Nat.succ (Array.size source.pages))
          source.pages source.pageLimit 0
      else
        false
    else
      false

def psKernelExprV2PagedReplayNode
    (canonical : PsKernelExprV2PagedArena)
    (node : PsKernelExprV2Node) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  match node with
  | PsKernelExprV2Node.bvar index =>
      psKernelExprV2PagedMkBVar canonical index
  | PsKernelExprV2Node.fvar name =>
      psKernelExprV2PagedMkFVar canonical name
  | PsKernelExprV2Node.mvar name =>
      psKernelExprV2PagedMkMVar canonical name
  | PsKernelExprV2Node.sort level =>
      psKernelExprV2PagedMkSort canonical level
  | PsKernelExprV2Node.const name levels =>
      psKernelExprV2PagedMkConst canonical name levels
  | PsKernelExprV2Node.lit literal =>
      psKernelExprV2PagedMkLit canonical literal
  | PsKernelExprV2Node.app fn arg =>
      psKernelExprV2PagedMkApp canonical fn arg
  | PsKernelExprV2Node.lam name type body binderInfo =>
      psKernelExprV2PagedMkLam canonical name type body binderInfo
  | PsKernelExprV2Node.forallE name type body binderInfo =>
      psKernelExprV2PagedMkForall canonical name type body binderInfo
  | PsKernelExprV2Node.letE name type value body nondep =>
      psKernelExprV2PagedMkLet canonical name type value body nondep
  | PsKernelExprV2Node.mdata tag body =>
      psKernelExprV2PagedMkMData canonical tag body
  | PsKernelExprV2Node.proj name index body =>
      psKernelExprV2PagedMkProj canonical name index body

def psKernelExprV2PagedValidateFuel
    (fuel : Nat) :
    PsKernelExprV2PagedArena ->
    PsKernelExprV2PagedArena ->
    Nat ->
    Except String PsKernelExprV2PagedArena :=
  match fuel with
  | Nat.zero =>
      fun (_source : PsKernelExprV2PagedArena) =>
        fun (_canonical : PsKernelExprV2PagedArena) =>
          fun (_id : Nat) =>
            Except.error "PSKERNEL_V2_PAGED_VALIDATE_FUEL"
  | Nat.succ remaining =>
      let smaller :
          PsKernelExprV2PagedArena ->
          PsKernelExprV2PagedArena ->
          Nat ->
          Except String PsKernelExprV2PagedArena :=
        psKernelExprV2PagedValidateFuel remaining;
      fun (source : PsKernelExprV2PagedArena) =>
        fun (canonical : PsKernelExprV2PagedArena) =>
          fun (id : Nat) =>
            if Nat.beq id source.size then
              Except.ok canonical
            else
              match psKernelExprV2PagedFind source id with
              | Option.none =>
                  Except.error "PSKERNEL_V2_PAGED_MISSING_SOURCE_NODE"
              | Option.some original =>
                  match psKernelExprV2PagedReplayNode
                      canonical original.node with
                  | Except.error error =>
                      Except.error error
                  | Except.ok inserted =>
                      let next := Prod.fst inserted;
                      let nextId := Prod.snd inserted;
                      if Nat.beq nextId id then
                        match psKernelExprV2PagedFind next nextId with
                        | Option.none =>
                            Except.error "PSKERNEL_V2_PAGED_REPLAY_MISSING"
                        | Option.some computed =>
                            if psKernelExprV2PortableSameMetadata
                                original computed then
                              smaller source next (Nat.succ id)
                            else
                              Except.error "PSKERNEL_V2_PAGED_METADATA_MISMATCH"
                      else
                        Except.error "PSKERNEL_V2_PAGED_ID_MISMATCH"

def psKernelExprV2PagedValidate
    (source : PsKernelExprV2PagedArena) :
    Except String PsKernelExprV2PagedArena :=
  if psKernelExprV2PagedShapeValid source then
    psKernelExprV2PagedValidateFuel
      (Nat.succ source.size)
      source
      (psKernelExprV2PagedEmptyWithLimit source.pageLimit)
      0
  else
    Except.error "PSKERNEL_V2_PAGED_MALFORMED_LAYOUT"
