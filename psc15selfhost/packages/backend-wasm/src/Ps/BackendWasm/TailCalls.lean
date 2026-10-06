import Ps.BackendWasm.Model
import Ps.Foundation.List

/- Walk the flat structured body backwards. Each end saves whether its whole
   conditional is in tail position; else restores that state for the then arm.
   No call across an intervening computation, cast, store, or drop is promoted.
   This preserves the existing stack/result typing and argument evaluation. -/
def psWasmTailCallsWorker (reversed : List PsWasmInstruction) :
    Bool -> List Bool -> List PsWasmInstruction -> List PsWasmInstruction :=
  match reversed with
  | List.nil =>
      fun (_tail : Bool) (_joins : List Bool) (output : List PsWasmInstruction) => output
  | List.cons instruction rest =>
      let smaller : Bool -> List Bool -> List PsWasmInstruction -> List PsWasmInstruction :=
        psWasmTailCallsWorker rest;
      fun (tail : Bool) (joins : List Bool) (output : List PsWasmInstruction) =>
        match instruction with
        | PsWasmInstruction.end_ =>
            smaller tail (List.cons tail joins) (List.cons instruction output)
        | PsWasmInstruction.else_ =>
            match joins with
            | List.nil => smaller false joins (List.cons instruction output)
            | List.cons join _ => smaller join joins (List.cons instruction output)
        | PsWasmInstruction.ifStart _ =>
            match joins with
            | List.nil => smaller false List.nil (List.cons instruction output)
            | List.cons _ outer => smaller false outer (List.cons instruction output)
        | PsWasmInstruction.return_ =>
            smaller true joins (List.cons instruction output)
        | PsWasmInstruction.call name =>
            if tail then
              smaller false joins (List.cons (PsWasmInstruction.returnCall name) output)
            else smaller false joins (List.cons instruction output)
        | PsWasmInstruction.callRef name =>
            if tail then
              smaller false joins (List.cons (PsWasmInstruction.returnCallRef name) output)
            else smaller false joins (List.cons instruction output)
        | _ => smaller false joins (List.cons instruction output)

def psWasmTailCalls (body : List PsWasmInstruction) : List PsWasmInstruction :=
  psWasmTailCallsWorker (psListReverse body) true List.nil List.nil

def psWasmTailCallFunction (value : PsWasmFunction) : PsWasmFunction :=
  PsWasmFunction.mk value.name value.typeName value.parameters value.results
    value.locals (psWasmTailCalls value.body)

def psWasmTailCallFunctions (values : List PsWasmFunction) : List PsWasmFunction :=
  psListMap psWasmTailCallFunction values
