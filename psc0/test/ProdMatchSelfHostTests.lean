import Ps.Bootstrap.SelfHost

def psProdMatchSelfHostSource : String :=
  "def prodFirst (value : Prod Nat Nat) : Nat :=\n" ++
  "  match value with\n" ++
  "  | Prod.mk first second => first\n"

def psTestProdMatchPreparation : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psProdMatchSelfHostSource with
  | Except.error _ => false
  | Except.ok prepared =>
      prepared.declarations.length > 0
        && (psCompilerAdmissionsFromPrepared prepared).isOk

def psTestProdMatchVerifiedIr : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psProdMatchSelfHostSource with
  | Except.error _ => false
  | Except.ok prepared =>
      match psCompilerVerifiedIrFromPrepared prepared with
      | Except.error _ => false
      | Except.ok _ => true

def psTestProdMatchTypeScript : Bool :=
  match
      psCompilerTypeScriptSource
        PsCompilerSourceKind.lean
        psProdMatchSelfHostSource with
  | Except.error _ => false
  | Except.ok _ => true

def main : IO Unit := do
  if psTestProdMatchPreparation then
    IO.println "PSC2_PROD_MATCH_PASS: preparation"
  else
    throw (IO.userError "PSC2_PROD_MATCH_FAIL: preparation")
  if psTestProdMatchVerifiedIr then
    IO.println "PSC2_PROD_MATCH_PASS: VerifiedIR"
  else
    throw (IO.userError "PSC2_PROD_MATCH_FAIL: VerifiedIR")
  if psTestProdMatchTypeScript then
    IO.println "PSC2_PROD_MATCH_PASS: TypeScript"
  else
    throw (IO.userError "PSC2_PROD_MATCH_FAIL: TypeScript")
