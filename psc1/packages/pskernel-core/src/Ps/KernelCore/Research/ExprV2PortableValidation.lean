import Ps.KernelCore.Research.ExprV2ChunkedBuilder

/-
Expression V2 M3: portable fail-closed replay validation.

This uses only PSC1-compatible pure functions and ordinary Except matching.
Source entries are NOT trusted. Every node is replayed through smart
constructors using previously validated children, and metadata is compared
before the new canonical immutable arena is returned.

Returning the fresh arena prevents untrusted payload fields (including
array/chunk layout) from becoming kernel authority. Hash comparison alone
is never used to authorize equality or an admission decision.
-/

def psKernelExprV2PortableSameMetadata
    (left right : PsKernelExprV2Entry) : Bool :=
  if Nat.beq left.hash right.hash then
    if Nat.beq left.looseRange right.looseRange then
      if psKernelBoolEq left.hasFVar right.hasFVar then
        if psKernelBoolEq left.hasExprMVar right.hasExprMVar then
          Nat.beq left.depth right.depth
        else false
      else false
    else false
  else false

def psKernelExprV2PortableReplayNode
    (checked : PsKernelExprV2ChunkedArena)
    (node : PsKernelExprV2Node) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  match node with
  | PsKernelExprV2Node.bvar index =>
      psKernelExprV2ChunkedMkBVar checked index
  | PsKernelExprV2Node.fvar name =>
      psKernelExprV2ChunkedMkFVar checked name
  | PsKernelExprV2Node.mvar name =>
      psKernelExprV2ChunkedMkMVar checked name
  | PsKernelExprV2Node.sort level =>
      psKernelExprV2ChunkedMkSort checked level
  | PsKernelExprV2Node.const name levels =>
      psKernelExprV2ChunkedMkConst checked name levels
  | PsKernelExprV2Node.lit literal =>
      psKernelExprV2ChunkedMkLit checked literal
  | PsKernelExprV2Node.app fn arg =>
      psKernelExprV2ChunkedMkApp checked fn arg
  | PsKernelExprV2Node.lam name type body binderInfo =>
      psKernelExprV2ChunkedMkLam checked name type body binderInfo
  | PsKernelExprV2Node.forallE name type body binderInfo =>
      psKernelExprV2ChunkedMkForall checked name type body binderInfo
  | PsKernelExprV2Node.letE name type value body nondep =>
      psKernelExprV2ChunkedMkLet checked name type value body nondep
  | PsKernelExprV2Node.mdata metadata body =>
      psKernelExprV2ChunkedMkMData checked metadata body
  | PsKernelExprV2Node.proj typeName index body =>
      psKernelExprV2ChunkedMkProj checked typeName index body

def psKernelExprV2PortableValidateAtWithFuel
    (fuel : Nat) :
    PsKernelExprV2ChunkedArena ->
    PsKernelExprV2ChunkedArena ->
    Nat ->
    Except String PsKernelExprV2ChunkedArena :=
  match fuel with
  | Nat.zero =>
      fun (_source : PsKernelExprV2ChunkedArena) =>
        fun (_checked : PsKernelExprV2ChunkedArena) =>
          fun (_id : Nat) =>
            Except.error "PSKERNEL_V2_PORTABLE_VALIDATE_FUEL"
  | Nat.succ remaining =>
      let smaller :
          PsKernelExprV2ChunkedArena ->
          PsKernelExprV2ChunkedArena ->
          Nat ->
          Except String PsKernelExprV2ChunkedArena :=
        psKernelExprV2PortableValidateAtWithFuel remaining;
      fun (source : PsKernelExprV2ChunkedArena) =>
        fun (checked : PsKernelExprV2ChunkedArena) =>
          fun (id : Nat) =>
            if Nat.beq id source.size then
              Except.ok checked
            else
              match psKernelExprV2ChunkedFind source id with
              | Option.none =>
                  Except.error "PSKERNEL_V2_PORTABLE_MISSING_ENTRY"
              | Option.some original =>
                  match
                      psKernelExprV2PortableReplayNode
                        checked original.node with
                  | Except.error error =>
                      Except.error error
                  | Except.ok inserted =>
                      let next : PsKernelExprV2ChunkedArena :=
                        Prod.fst inserted;
                      let nextId : Nat := Prod.snd inserted;
                      if Nat.beq nextId id then
                        match psKernelExprV2ChunkedFind next nextId with
                        | Option.none =>
                            Except.error "PSKERNEL_V2_PORTABLE_REPLAY_MISSING"
                        | Option.some expected =>
                            if psKernelExprV2PortableSameMetadata
                                original expected then
                              smaller source next (Nat.succ id)
                            else
                              Except.error "PSKERNEL_V2_PORTABLE_FORGED_METADATA"
                      else
                        Except.error "PSKERNEL_V2_PORTABLE_REPLAY_ID"

def psKernelExprV2PortableValidate
    (source : PsKernelExprV2ChunkedArena) :
    Except String PsKernelExprV2ChunkedArena :=
  if Nat.beq source.chunkLimit 0 then
    Except.error "PSKERNEL_V2_PORTABLE_INVALID_CHUNK_LIMIT"
  else
    psKernelExprV2PortableValidateAtWithFuel
      (Nat.succ source.size)
      source
      (psKernelExprV2ChunkedEmptyWithLimit source.chunkLimit)
      0
