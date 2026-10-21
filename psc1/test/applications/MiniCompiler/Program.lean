import PracticalCli.Args
import MiniCompiler.Syntax

def miniWriteResult (rendered : Result String JsonError) (output : String) : Io Bool :=
  match rendered with
  | Result.error _ => do
      ioWriteLine "render-error"
      return false
  | Result.ok text => do
      ioWriteUtf8 output text
      ioWriteLine "ok"
      return true

def miniCompiledResult (compiled : Result MiniSummary MiniDiagnostic) (output : String) : Io Bool :=
  match compiled with
  | Result.error diagnostic => do
      ioWriteLine (miniDiagnosticText diagnostic)
      return false
  | Result.ok summary => miniWriteResult (miniRender summary) output

def miniProcess (input output : String) : Io Bool := do
  let source : String <- ioReadUtf8 input
  let compiled : Result MiniSummary MiniDiagnostic := miniCompile source
  miniCompiledResult compiled output

def miniCommandRun (command : CliCommand) : Io Bool :=
  match command with
  | CliCommand.help => do
      ioWriteLine "usage: transform INPUT OUTPUT"
      return true
  | CliCommand.transform input output => miniProcess input output

def miniApplication (arguments : String) : Io Bool :=
  match cliArguments arguments with
  | Option.none => do
      ioWriteLine "usage: transform INPUT OUTPUT"
      return false
  | Option.some command => miniCommandRun command
