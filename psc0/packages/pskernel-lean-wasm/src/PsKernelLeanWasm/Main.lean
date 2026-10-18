import PsKernelLean.Admission

/-!
Lean 4.35.0 official-kernel admission endpoint for the PSC0 v7.2
linear-memory WebAssembly build. This is *not* a second kernel implementation.
The imported PsKernelLean decoder/prelude are the live PSC0 modules;
environment.addDeclCore is Lean's checked C++ kernel operation.
-/

namespace PsKernelLeanWasm

def protocol : String := "pskernel-lean-wasm/2"
def version : String := "4.35.0"
def commit : String := "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"
def profile : String := "pscv0-v7.2"
def provider : String := "lean4-cpp"

def identity : String :=
  "\"protocol\":" ++ psJsonQuote protocol ++
  ",\"provider\":" ++ psJsonQuote provider ++
  ",\"leanVersion\":" ++ psJsonQuote version ++
  ",\"leanCommit\":" ++ psJsonQuote commit ++
  ",\"profile\":" ++ psJsonQuote profile

def pinned : Bool :=
  Lean.versionString == version && Lean.githash == commit

def rejected (kind message : String) (index : Option Nat := none) : String :=
  "{" ++ identity ++
  ",\"accepted\":false,\"errorKind\":" ++ psJsonQuote kind ++
  ",\"message\":" ++ psJsonQuote message ++
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
          -- The C++ kernel heartbeat counter is fresh on a task worker,
          -- but only when this pure checked computation is actually forced
          -- *inside* the worker. Plain IO.pure/return may evaluate eagerly on
          -- the caller thread after the expensive Standard replay, causing
          -- deterministic-timeout even for Nat := 1. Follow the established
          -- PSC0 provider's IO.lazyPure boundary without its stdout audit:
          -- this wire endpoint must produce exactly ONE JSON response.
          -- Admission retains the same finite 2m/20k kernel budgets.
          let task ← IO.asTask do
            let result ← IO.lazyPure (fun _ =>
              PsKernelLean.admitDeclarations prelude declarations)
            return result
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
