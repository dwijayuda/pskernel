import Ps.KernelCore.Research.ExprV2PortableHeadSequence

/-
Expression V2 M3: validated-once bounded beta/zeta/metadata head machine.

The existing HeadSequence is the deliberately slow reference: each step
replays every arena entry, and instantiation may replay both its input and
output. That turns a long head-reduction sequence into repeated full-arena
scans even when smart constructors already maintain immutable metadata.

This *research-only* machine validates the entire supplied DAG ONCE on
entry. It then works exclusively on that canonical immutable arena and
creates any new expression solely through checked V2 smart constructors.
The completed arena is independently replay-validated ONCE before return.

The OnCanonical functions below are internal computation helpers. They
MUST NOT be wired as public kernel checking/admission APIs: an arbitrary
external arena passed to them has NOT been validated. The only supported
entry point is psKernelExprV2PortableHeadMachineChecked.

No publication, definitional equality or kernel resource policy uses V2.
The limited reductions are direct beta, zeta and metadata only.
-/

/-
M3 instantiation computation on a canonical arena. A previous full replay
of the source is required before calling this helper; each output node is
produced by checked smart constructors, and each output replay is deferred
to the enclosing checked machine.
-/
def psKernelExprV2PortableInstOnCanonical
    (arena : PsKernelExprV2ChunkedArena)
    (root replacement : Nat) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  match psKernelExprV2ChunkedFind arena root with
  | Option.none =>
      Except.error "PSKERNEL_V2_HEAD_MACHINE_INVALID_ROOT"
  | Option.some entry =>
      match psKernelExprV2ChunkedFind arena replacement with
      | Option.none =>
          Except.error "PSKERNEL_V2_HEAD_MACHINE_INVALID_REPLACEMENT"
      | Option.some _ =>
          let initial : PsKernelExprV2PortableInstState := {
            arena := arena
            memo := List.nil
          };
          match
              psKernelExprV2PortableInstWithFuel
                (Nat.succ entry.depth)
                initial
                root
                0
                replacement with
          | Except.error error =>
              Except.error error
          | Except.ok result =>
              Except.ok
                (Prod.mk
                  (Prod.fst result).arena
                  (Prod.snd result))

def psKernelExprV2PortableHeadStepOnCanonical
    (arena : PsKernelExprV2ChunkedArena)
    (root : Nat) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  match psKernelExprV2ChunkedFind arena root with
  | Option.none =>
      Except.error "PSKERNEL_V2_HEAD_MACHINE_INVALID_ROOT"
  | Option.some entry =>
      match entry.node with
      | PsKernelExprV2Node.letE _ _ value body _ =>
          psKernelExprV2PortableInstOnCanonical arena body value
      | PsKernelExprV2Node.app fn arg =>
          match psKernelExprV2ChunkedFind arena fn with
          | Option.none =>
              Except.error "PSKERNEL_V2_HEAD_MACHINE_INVALID_FUNCTION"
          | Option.some fnEntry =>
              match fnEntry.node with
              | PsKernelExprV2Node.lam _ _ body _ =>
                  psKernelExprV2PortableInstOnCanonical arena body arg
              | _ =>
                  Except.ok (Prod.mk arena root)
      | PsKernelExprV2Node.mdata _ body =>
          Except.ok (Prod.mk arena body)
      | _ =>
          Except.ok (Prod.mk arena root)

def psKernelExprV2PortableHeadMachineFuel
    (fuel : Nat) :
    PsKernelExprV2ChunkedArena ->
    Nat ->
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  match fuel with
  | Nat.zero =>
      fun (_arena : PsKernelExprV2ChunkedArena) =>
        fun (_root : Nat) =>
          Except.error "PSKERNEL_V2_HEAD_MACHINE_FUEL"
  | Nat.succ remaining =>
      let smaller :
          PsKernelExprV2ChunkedArena ->
          Nat ->
          Except String (PsKernelExprV2ChunkedArena × Nat) :=
        psKernelExprV2PortableHeadMachineFuel remaining;
      fun (arena : PsKernelExprV2ChunkedArena) =>
        fun (root : Nat) =>
          match psKernelExprV2PortableHeadStepOnCanonical arena root with
          | Except.error error =>
              Except.error error
          | Except.ok step =>
              let next := Prod.snd step;
              if Nat.beq next root then
                Except.ok step
              else
                smaller (Prod.fst step) next

/-
Use ONLY this entry for external/untrusted V2 arenas. Replayed input and
output guarantees the metadata invariants used for loose-bvar pruning and
structural sharing, without O(steps * arenaNodes) repeated replays.
-/
def psKernelExprV2PortableHeadMachineChecked
    (fuel : Nat)
    (source : PsKernelExprV2ChunkedArena)
    (root : Nat) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  match psKernelExprV2PortableValidate source with
  | Except.error error =>
      Except.error error
  | Except.ok canonical =>
      match psKernelExprV2ChunkedFind canonical root with
      | Option.none =>
          Except.error "PSKERNEL_V2_HEAD_MACHINE_INVALID_ROOT"
      | Option.some _ =>
          match psKernelExprV2PortableHeadMachineFuel
              fuel canonical root with
          | Except.error error =>
              Except.error error
          | Except.ok result =>
              match psKernelExprV2PortableValidate (Prod.fst result) with
              | Except.error error =>
                  Except.error error
              | Except.ok verified =>
                  Except.ok (Prod.mk verified (Prod.snd result))
