import PracticalCli.Args
import PracticalCli.Transform

def cliIoError (error : IoError) : String :=
  match error with
  | IoError.capabilityDenied => "capabilityDenied"
  | IoError.pathDenied => "pathDenied"
  | IoError.notFound => "notFound"
  | IoError.wrongType => "wrongType"
  | IoError.invalidUtf8 => "invalidUtf8"
  | IoError.tooLarge => "tooLarge"
  | IoError.ioFailure => "ioFailure"
  | IoError.protocolError => "protocolError"

def cliProcess (input output : String) : Io Bool := do
  try
    let source : String <- ioReadUtf8 input
    match cliTransform source with
    | Result.error error =>
        match error with
        | JsonError.invalidUnicode => ioWriteLine "invalid-unicode"
        | _ => ioWriteLine "invalid-json"
        return false
    | Result.ok transformed =>
        ioWriteUtf8 output transformed
        ioWriteLine "ok"
        return true
  catch error =>
    ioWriteLine (jsonAppend "error:" (cliIoError error))
    return false

def cliApplication (arguments : String) : Io Bool := do
  match cliArguments arguments with
  | Option.none =>
      ioWriteLine "usage: transform INPUT OUTPUT"
      return false
  | Option.some command =>
      match command with
      | CliCommand.help =>
          ioWriteLine "usage: transform INPUT OUTPUT"
          return true
      | CliCommand.transform input output => cliProcess input output
