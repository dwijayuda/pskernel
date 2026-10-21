import ProofScript.System.IO

def ioApplication : Io Bool := do
  let text : String <- ioReadUtf8 "input.txt"
  ioWriteUtf8 "output.txt" (jsonAppend "processed:" text)
  let mut total : Nat := 0
  for value in [1, 2] do
    ioWriteLine "tick"
    total := total + value
  try
    let missing : String <- ioReadUtf8 "missing"
    ioWriteLine "unexpected"
  catch error =>
    ioWriteLine "recovered"
  let line : Option String <- ioReadLine ()
  match line with
  | Option.none => ioWriteLine "EOF"
  | Option.some value => ioWriteLine (jsonAppend "echo:" value)
  return Nat.beq total 3
