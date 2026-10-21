import SequencedIo.Program

def run (dispatch : String -> String) : Bool :=
  let observed : Bool := (match ioRun ioApplication dispatch with
    | Result.error _ => false
    | Result.ok value => value);
  let andValue : Bool := !observed && ioTextEq (dispatch "PSC1_SHORT_CIRCUIT_TRAP") "";
  let orValue : Bool := observed || ioTextEq (dispatch "PSC1_SHORT_CIRCUIT_TRAP") "";
  observed && !andValue && orValue
