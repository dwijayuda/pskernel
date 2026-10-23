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

def cliJsonError (error : JsonError) : String :=
  match error with
  | JsonError.invalidUnicode => "invalid-unicode"
  | _ => "invalid-json"

def cliWriteResult (result : Result String JsonError) (output : String) : Io Bool :=
  match result with
  | Result.error error => do
      ioWriteLine (cliJsonError error)
      return false
  | Result.ok transformed => do
      ioWriteUtf8 output transformed
      ioWriteLine "ok"
      return true

def cliProcess (input output : String) : Io Bool := do
  try
    let source : String <- ioReadUtf8 input
    cliWriteResult (cliTransform source) output
  catch error =>
    ioWriteLine (jsonAppend "error:" (cliIoError error))
    return false

def cliCommandRun (command : CliCommand) : Io Bool :=
  match command with
  | CliCommand.help => do
      ioWriteLine "usage: transform INPUT OUTPUT"
      return true
  | CliCommand.transform input output => cliProcess input output

def cliApplication (arguments : String) : Io Bool :=
  match cliArguments arguments with
  | Option.none => do
      ioWriteLine "usage: transform INPUT OUTPUT"
      return false
  | Option.some command => cliCommandRun command
