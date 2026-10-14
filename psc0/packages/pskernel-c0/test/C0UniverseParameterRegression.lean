import Ps.KernelCore.API.VerifiedProvider
import Ps.KernelCore.Architecture.QualifiedInference

/-!
Lean 4.35 universe-level discipline inside actual C0 FULL type checking.

Infer-only is intentionally allowed to synthesize types containing a
parameter absent from the current session's allowed list. Full checking
must reject that parameter, including nested max/imax and universes applied
to otherwise admitted constants. This matches pinned Lean 4.35
type_checker.cpp::check_level and infer_constant; it does not make
untrusted cache entries or unchecked terms into acceptable proof objects.
-/

def main : IO Unit := do
  let u : PsKernelName := .str .anonymous "declaredU"
  let v : PsKernelName := .str .anonymous "foreignU"
  let unknown : PsKernelExpr := .sort (.param v)
  let nested : PsKernelExpr := .sort (.imax (.succ .zero)
    (.max .zero (.param v)))
  let empty := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let (inferredUnknown, _) ← match psKernelSessionInfer 4096 empty unknown with
    | .ok x => pure x
    | .error _ => throw (IO.userError "infer-only unexpectedly restricted universes")
  if !psKernelExprEqual inferredUnknown (.sort (.succ (.param v))) then
    throw (IO.userError "universe infer-only result changed source rules")
  for expression in [unknown, nested] do
    match psKernelSessionCheck 4096 empty expression with
    | .error error =>
        if error != "invalid reference to undefined universe level parameter" then
          throw (IO.userError ("wrong closed-universe rejection: " ++ error))
    | .ok _ =>
        throw (IO.userError "full source check admitted undeclared universe")
  let some raw := psKernelC0ArchitectureBegin empty
    | throw (IO.userError "universe work genesis failed")
  let some certified := psKernelC0ArchitectureCertifyWork raw
    | throw (IO.userError "universe work certificate failed")
  if (psKernelC0ScalarInferWithFuel 4096 empty.context empty.state unknown
      false).isSome then
    throw (IO.userError "optimized full scalar check bypassed level validation")
  match psKernelC0CertifiedWorkCheckQualifiedOwned 4096 certified unknown with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "qualified checked scalar imported unknown universe")
  let (inferred, _) ← match
      psKernelC0CertifiedWorkInferQualifiedOwned 4096 certified unknown with
    | .ok receipt => pure receipt.val
    | .error _ => throw (IO.userError "infer-only scalar level was rejected")
  if !psKernelExprEqual inferred inferredUnknown then
    throw (IO.userError "optimized infer-only level semantics diverged")

  -- A named declared universe is allowed only in checking contexts that
  -- actually carry the exact name. Syntax equality of levels is not enough.
  let authorized := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [v] .safe 4096 psKernelLeanNatMaxSizeDefault
  let (known, _) ← match psKernelSessionCheck 4096 authorized unknown with
    | .ok value => pure value
    | .error _ => throw (IO.userError "declared universe failed full checking")
  if !psKernelExprEqual known (.sort (.succ (.param v))) then
    throw (IO.userError "full checking changed authorized universe result")

  -- Official Lean first checks constant signatures, safety and universe
  -- arity, then rejects undeclared universe parameters on fully checked
  -- constant use. The infer-only lookup deliberately does not check them.
  let constantName : PsKernelName := .str .anonymous "PolymorphicCheckedConstant"
  let info : PsKernelAxiomInfo := {
    base := {
      name := constantName
      levelParams := [u]
      type := .sort (.param u)
    }
    isUnsafe := false
  }
  let admittedEnv ← match psKernelAddAxiom 4096 psKernelEnvironmentEmpty
      info 4096 psKernelLeanNatMaxSizeDefault with
    | .ok environment => pure environment
    | .error e => throw (IO.userError ("checked poly axiom rejected: " ++ e))
  let closedChecker := psKernelMkCheckerSession admittedEnv []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let admittedConstant : PsKernelExpr := .const constantName [.zero]
  let unknownConstant : PsKernelExpr := .const constantName [.param v]
  let knownType ← match psKernelSessionCheck 4096 closedChecker
      admittedConstant with
    | .ok value => pure value.fst
    | .error e => throw (IO.userError ("checked instantiated constant failed: " ++ e))
  if !psKernelExprEqual knownType (.sort .zero) then
    throw (IO.userError "checked constant substituted wrong universe")
  let (inferredConstant, _) ← match psKernelSessionInfer
      4096 closedChecker unknownConstant with
    | .ok value => pure value
    | .error _ => throw (IO.userError "infer-only constant universe was denied")
  if !psKernelExprEqual inferredConstant (.sort (.param v)) then
    throw (IO.userError "infer-only constant universe substitution changed")
  match psKernelSessionCheck 4096 closedChecker unknownConstant with
  | .error error =>
      if error != "invalid reference to undefined universe level parameter" then
        throw (IO.userError ("wrong checked constant level error: " ++ error))
  | .ok _ => throw (IO.userError "checked constant used undeclared universe")
  match psKernelSessionCheck 4096 closedChecker (.const constantName []) with
  | .error "incorrect number of universe levels" => pure ()
  | _ => throw (IO.userError "constant arity error precedence changed")

  -- Provider checked-genesis has an empty allowed-level list. Even after
  -- explicit source axiom permission, its standalone checked operations
  -- cannot import arbitrary level parameter names.
  let policy : PsKernelResourcePolicy := {
    fuel := 4096
    maxRecDepth := 4096
    maxNatSize := psKernelLeanNatMaxSizeDefault
    cancelled := false
    maxDeclarations := 16
  }
  let first ← match psKernelC0VerifiedProviderBegin
      policy psKernelProviderDefault with
    | .ok value => pure value
    | .error _ => throw (IO.userError "verified universe genesis failed")
  match psKernelC0VerifiedProviderCheck first unknown with
  | .error (.rejectedInvalid _) => pure ()
  | _ => throw (IO.userError "verified provider accepted foreign Sort level")
  let permitted ← match psKernelC0VerifiedProviderChangePolicy
      first [info] [] with
    | .ok value => pure value
    | .error _ => throw (IO.userError "verified exact axiom policy review failed")
  let afterAdmission ← match psKernelC0VerifiedProviderAdmit
      permitted (.axiomDecl info) with
    | .ok value => pure value
    | .error _ => throw (IO.userError "verified poly axiom admission failed")
  match psKernelC0VerifiedProviderCheck afterAdmission unknownConstant with
  | .error (.rejectedInvalid _) => pure ()
  | _ => throw (IO.userError "verified provider accepted foreign constant universe")
  let (checkedConstant, _) ← match psKernelC0VerifiedProviderCheck
      afterAdmission admittedConstant with
    | .ok value => pure value
    | .error _ => throw (IO.userError "verified constant with level zero declined")
  if !psKernelExprEqual checkedConstant (.sort .zero) then
    throw (IO.userError "verified checked constant universe instantiation changed")
  if (psKernelC0HistoryAxiomSignatures
      afterAdmission.verified.sealed.audited.trusted.history).length != 1 then
    throw (IO.userError "universe validation changed signed assumption ledger")

  IO.println "C0_UNIVERSES checked_Sort_Const_undeclared_parameters_rejected=pass"
  IO.println "C0_UNIVERSES infer_only_source_vs_full_check_distinction=pass"
  IO.println "C0_UNIVERSES verified_provider_signed_history_and_levels=pass"
