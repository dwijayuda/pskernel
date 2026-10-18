/-!
Lean 4.35.0 official-kernel admission endpoint for the PSC0 v7.2
linear-memory WebAssembly build. This is *not* a second kernel implementation.
The imported PsKernelLean decoder/prelude are the live PSC0 modules;
environment.addDeclCore is Lean's checked C++ kernel operation.
-/
import PsKernelLean.Admission

namespace PsKernelLeanWasm

def protocol : String := "pskernel-lean-wasm/2"
def version : String := "4.35.0"
def commit : String := "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"
def profile : String := "pscv0-v7.2"
def provider : String := "lean4-cpp"

def identity : String :=
  "\"protocol\":" ++ PsKernelLean.psJsonQuote protocol ++
  ",\"provider\":" ++ PsKernelLean.psJsonQuote provider ++
  ",\"leanVersion\":" ++ PsKernelLean.psJsonQuote version ++
  ",\"leanCommit\":" ++ PsKernelLean.psJsonQuote commit ++
  ",\"profile\":" ++ PsKernelLean.psJsonQuote profile

def pinned : Bool :=
  Lean.versionString == version && Lean.githash == commit

def rejected (kind message : String) (index : Option Nat := none) : String :=
  "{" ++ identity ++
  ",\"accepted\":false,\"errorKind\":" ++ PsKernelLean.psJsonQuote kind ++
  ",\"message\":" ++ PsKernelLean.psJsonQuote message ++
  (match index with
   | none => ""
   | some value => ",\"declarationIndex\":" ++ toString value) ++ "}"

def check (source : String) : IO String := do
  if !pinned then
    return rejected "toolchain-mismatch" "Lean 4.35.0 source identity mismatch"
  -- Admitted definitions are never inserted unchecked. Both the initial
  -- Standard environment and every submitted declaration go through Lean's
  -- Kernel.Environment.addDeclCore via PsKernelLean.Admission.
  match PsKernelLean.decodeCanonicalAdmissions source with
  | .error error =>
      return rejected error.kind.code error.message error.declarationIndex
  | .ok declarations =>
      match ← PsKernelLean.buildLeanPreludeEnvironment with
      | .error error =>
          return rejected error.kind.code error.message error.declarationIndex
      | .ok prelude =>
          -- A fresh task resets the *C++* kernel heartbeat counter. The
          -- legacy admission helper logs failures to stdout; never call it
          -- directly here because the wire transport requires one JSON line.
          let task ← IO.asTask do
            return PsKernelLean.admitDeclarations prelude declarations
          match ← IO.ofExcept (← IO.wait task) with
          | .ok _ => return "{" ++ identity ++ ",\"accepted\":true}"
          | .error error =>
              return rejected error.kind.code
                (error.message.replace "Lean 4.34" "Lean 4.35")
                error.declarationIndex

def run (args : List String) : IO Unit := do
  match args with
  | ["--health"] =>
      IO.println <| "{" ++ identity ++ ",\"status\":" ++
        (if pinned then "\"ok\"" else "\"toolchain-mismatch\"") ++ "}"
  | ["--check"] =>
      let source ← (← IO.getStdin).readToEnd
      IO.println (← check source)
  | _ =>
      IO.println (rejected "unsupported-command" "expected --health or --check")

end PsKernelLeanWasm

def main (args : List String) : IO Unit :=
  PsKernelLeanWasm.run args
