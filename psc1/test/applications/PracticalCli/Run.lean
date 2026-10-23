import PracticalCli.Program

def run (arguments : String) (dispatch : String -> String) : Bool :=
  match ioRun (cliApplication arguments) dispatch with
  | Result.ok success => success
  | Result.error _ => false
