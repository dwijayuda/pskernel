import Ps.DriverTs.Compiler
import PsKernelLean.Admission

-- Host-only integration. No import from the portable bootstrap closure.
-- Acceptance concerns these exact declarations under the provider-owned prelude;
-- it is not a proof of erasure or backend semantic preservation.
def psHostLeanCheckPrepared
    (prepared : PsCompilerAdmissionReadyModule) : IO (Except String String) := do
  match psCompilerAdmissionsFromPrepared prepared with
  | .error _ => pure (.error "PSC2_CHECKED_PREPARED_INTEGRITY_FAILED")
  | .ok admissions =>
      match ← PsKernelLean.admitCanonicalAdmissions admissions with
      | .error error => pure (.error ("PSC2_KERNEL_REJECTED: " ++ error.message))
      | .ok _ => pure (.ok admissions)

def psHostLeanEmitPrepared
    (prepared : PsCompilerAdmissionReadyModule) : IO (Except String (String × String)) := do
  match ← psHostLeanCheckPrepared prepared with
  | .error error => pure (.error error)
  | .ok admissions =>
      -- Lean values are immutable. Erase the very same prepared value, without
      -- filesystem rereads or re-elaboration after kernel acceptance.
      match psCompilerTypeScriptFromPrepared prepared with
      | .error _ => pure (.error "PSC2_CHECKED_EMISSION_FAILED")
      | .ok output => pure (.ok (admissions, output))
