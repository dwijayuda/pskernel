import Ps.Compiler.Api
import Ps.BackendTs.Compiler


def psPhase13NoninterferenceSource : String :=
  "def answer : Nat := 42"


def psPhase13UnsupportedShadowSource : String :=
  "inductive Box where\n" ++
  "  | mk (value : Nat)\n\n" ++
  "def unbox (box : Box) : Nat :=\n" ++
  "  match box with\n" ++
  "  | Box.mk value => value"


def psPhase13ShadowTsStablePass : Bool :=
  match
      psCompilerTypeScriptSource
        PsCompilerSourceKind.lean
        psPhase13NoninterferenceSource with
  | Except.error _ => false
  | Except.ok before =>
      match
          psCompilerKernelShadowCheckSource
            PsCompilerSourceKind.lean
            psPhase13NoninterferenceSource with
      | Except.error _ => false
      | Except.ok _ =>
          match
              psCompilerTypeScriptSource
                PsCompilerSourceKind.lean
                psPhase13NoninterferenceSource with
          | Except.error _ => false
          | Except.ok after => before == after


def psPhase13ShadowUnsupportedIsNonAuthoritativePass : Bool :=
  match
      psCompilerTypeScriptSource
        PsCompilerSourceKind.lean
        psPhase13UnsupportedShadowSource with
  | Except.error _ => false
  | Except.ok before =>
      match
          psCompilerKernelShadowCheckSource
            PsCompilerSourceKind.lean
            psPhase13UnsupportedShadowSource with
      | Except.ok _ => false
      | Except.error (PsCompilerKernelShadowApiError.compiler _) => false
      | Except.error
          (PsCompilerKernelShadowApiError.shadow
            PsCompilerKernelShadowError.unsupportedDeclaration) =>
          match
              psCompilerTypeScriptSource
                PsCompilerSourceKind.lean
                psPhase13UnsupportedShadowSource with
          | Except.error _ => false
          | Except.ok after => before == after
      | Except.error (PsCompilerKernelShadowApiError.shadow _) => false


def psPhase13ShadowPreparedPurityPass : Bool :=
  match
      psCompilerPrepareSource
        PsCompilerSourceKind.lean
        psPhase13NoninterferenceSource with
  | Except.error _ => false
  | Except.ok prepared =>
      let canonicalBefore := prepared.canonicalAdmissions;
      match psCompilerTypeScriptFromPrepared prepared with
      | Except.error _ => false
      | Except.ok before =>
          match psCompilerKernelShadowCheckPrepared prepared with
          | Except.error _ => false
          | Except.ok _ =>
              match psCompilerTypeScriptFromPrepared prepared with
              | Except.error _ => false
              | Except.ok after =>
                  before == after
                    && canonicalBefore == prepared.canonicalAdmissions


def psPhase13ShadowNoninterferencePass : Bool :=
  psPhase13ShadowTsStablePass
    && psPhase13ShadowUnsupportedIsNonAuthoritativePass
    && psPhase13ShadowPreparedPurityPass


def main : IO Unit := do
  if psPhase13ShadowNoninterferencePass then
    IO.println "PSC2_KERNEL_CORE_PHASE13_SHADOW_NONINTERFERENCE: PASS"
  else
    throw
      (IO.userError
        "PSC2_KERNEL_CORE_PHASE13_SHADOW_NONINTERFERENCE: FAIL")
