import Lean
import PSCVL.Policy

/-!
In-process Lean parser, elaborator, and kernel-backed preflight for .ps files.
No translated text, temporary source file, sidecar script, or custom typechecker.
-/

open Lean

namespace PSCVL

private def checkFile (path : String) : IO UInt32 := do
  unless path.endsWith ".ps" do
    IO.eprintln "PSCVL expects a .ps source file"
    return 2
  let source ← IO.FS.readFile path
  -- The initial prototype has a frozen prelude. Its sources cannot choose
  -- imports: dependency/capability identity is not implemented yet.
  if (source.splitOn "\n").any (fun line =>
       let l := line.trimAscii.toString
       l.startsWith "import " || l.startsWith "public import ") then
    IO.eprintln "PSCVL: source imports are unsupported; only the pinned PSCVL prelude is available"
    return 2
  initSearchPath (← findSysroot)
  let env ← importModules #[{ module := `PSCVL.Policy }] {} (trustLevel := 0) (loadExts := true)
  -- The gate is injected by the driver, not opt-in source syntax. Append it
  -- only after the user input has been completely parsed/elaborated.
  let checkedSource := source ++ "\n\n#pscv_gate\n"
  let (_, messages) ← Elab.Frontend.process checkedSource env {} (some path)
  for message in messages.markAllReported.reported do
    IO.eprintln (← message.toString)
  if messages.hasErrors then
    IO.eprintln "PSCVL: preflight FAILED; no artifact emitted"
    return 1
  IO.println "PSCVL: Lean elaboration and preliminary policy check passed (UNCERTIFIED)"
  return 0

def cli (args : List String) : IO UInt32 := do
  try
    match args with
    | ["check", path] => checkFile path
    | _ =>
      IO.eprintln "usage: lake exe pscvl check <source.ps>"
      IO.eprintln "No PSCV certified compilation or executable emission exists in this prototype."
      return 2
  catch e =>
    IO.eprintln s!"PSCVL error: {e}"
    return 1

end PSCVL

def main (args : List String) : IO UInt32 := PSCVL.cli args
