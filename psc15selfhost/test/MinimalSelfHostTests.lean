import Ps.Compiler.SelfHost

def psMinimalSelfHostLeanSource : String :=
  "def answer : Nat := 42"

def psTestMinimalSelfHostPreparation : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostLeanSource with
  | Except.error _ => false
  | Except.ok prepared =>
      prepared.declarations.length > 0
        && prepared.canonicalAdmissions.length > 0

def psTestMinimalSelfHostVerifiedIr : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostLeanSource with
  | Except.error _ => false
  | Except.ok prepared =>
      match psCompilerVerifiedIrFromPrepared prepared with
      | Except.error _ => false
      | Except.ok _ => true

def psTestMinimalSelfHostTypeScript : Bool :=
  match
      psCompilerTypeScriptSource
        PsCompilerSourceKind.lean
        psMinimalSelfHostLeanSource with
  | Except.error _ => false
  | Except.ok output => output.contains "answer"

def main : IO Unit := do
  if psTestMinimalSelfHostPreparation then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: admission-ready boundary"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: admission-ready boundary")
  if psTestMinimalSelfHostVerifiedIr then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: prepared core -> VerifiedIR"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: prepared core -> VerifiedIR")
  if psTestMinimalSelfHostTypeScript then
    IO.println "PSC2_MINIMAL_SELFHOST_PASS: TypeScript bootstrap backend"
  else
    throw
      (IO.userError
        "PSC2_MINIMAL_SELFHOST_FAIL: TypeScript bootstrap backend")
