import SequencedIo.Program
def run (dispatch : String -> String) : Bool :=
  match ioRun ioApplication dispatch with
  | Result.error _ => false
  | Result.ok value => value
