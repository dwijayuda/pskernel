import Ps.KernelCore.API.Kernel

/-!
Lean 4.35.0 native checker regression.

Lean 4.35 removed the special kernel execution of Lean.reduceBool and
Lean.reduceNat (and the old trustCompiler bridge). Arbitrary spelling of
these names must not grant a compiler-execution reduction capability.
-/

def main : IO Unit := do
  if !psKernelStringEq psKernelTargetIdentityV1.contract "KernelContract-v1" ||
      !psKernelStringEq psKernelTargetIdentityV1.leanVersion "4.35.0" ||
      !psKernelStringEq psKernelTargetIdentityV1.leanCommit
        "eb6cafb7290e8bd5f2937522d8d804f58f02bafc" then
    throw (IO.userError "C0 target identity is not stable Lean 4.35.0")
  if !psKernelProviderCompatible psKernelProviderDefault then
    throw (IO.userError "C0 rejected the Lean 4.35 provider")
  let oldProvider : PsKernelProviderCapability := {
    target := {
      contract := "KernelContract-v1"
      leanVersion := "4.34.0"
      leanCommit := "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b"
    }
  }
  if psKernelProviderCompatible oldProvider then
    throw (IO.userError "C0 accepted a stale Lean 4.34 provider")
  IO.println "C0_LEAN435 target_version_and_provider=pass"

  let checker := psKernelMkCheckerSession psKernelEnvironmentEmpty []
    PsKernelDefinitionSafety.safe 4096 psKernelLeanNatMaxSizeDefault
  let leanName := PsKernelName.str PsKernelName.anonymous "Lean"
  let oldBool := PsKernelName.str leanName "reduceBool"
  let oldNat := PsKernelName.str leanName "reduceNat"
  let oldTrust := PsKernelName.str leanName "trustCompiler"
  let target := PsKernelName.str PsKernelName.anonymous "C0.legacyTarget"
  let terms : List PsKernelExpr := [
    .app (.const oldBool []) (.const target []),
    .app (.const oldNat []) (.const target []),
    .const oldTrust []
  ]
  for term in terms do
    match psKernelSessionWhnf 4096 checker term with
    | Except.error error =>
        throw (IO.userError ("C0 legacy-marker WHNF failed: " ++ error))
    | Except.ok (reduced, _) =>
        if !psKernelExprEqual reduced term then
          throw (IO.userError "C0 performed a removed native reduction")
    match psKernelSessionCheck 4096 checker term with
    | Except.error _ => pure ()
    | Except.ok _ =>
        throw (IO.userError "C0 accepted an undeclared legacy native marker")
  IO.println "C0_LEAN435 no_legacy_compiler_native_reduction=pass"

  -- Ordinary Nat primitives remain kernel reductions under Lean 4.35.
  let two : PsKernelExpr := .lit (.nat 2)
  let three : PsKernelExpr := .lit (.nat 3)
  let addition : PsKernelExpr :=
    .app (.app (.const psKernelNatAddName []) two) three
  match psKernelSessionWhnf 4096 checker addition with
  | Except.error error =>
      throw (IO.userError ("C0 ordinary Nat WHNF failed: " ++ error))
  | Except.ok (value, _) =>
      if !psKernelExprEqual value (.lit (.nat 5)) then
        throw (IO.userError "C0 migration broke ordinary Nat.add")
  IO.println "C0_LEAN435 standard_nat_reduction=pass"

  let candidate : PsKernelDefinitionInfo := {
    base := {
      name := target
      levelParams := []
      type := .sort (.succ .zero)
    }
    value := .app (.const oldNat []) (.const target [])
    hints := .abbrevHint
    safety := .safe
  }
  match psKernelAddDefinition 4096 psKernelEnvironmentEmpty candidate
      4096 psKernelLeanNatMaxSizeDefault with
  | Except.error _ => pure ()
  | Except.ok _ =>
      throw (IO.userError "C0 admitted undeclared legacy compiler-native marker")
  IO.println "C0_LEAN435 obsolete_native_admission_rejected=pass"

  -- Lean 4.35 level.cpp::normalize distributes succ offsets over every
  -- max branch. These closed-under-universe-parameter identities matter for
  -- checking fields of real Init.Functor-style inductive declarations.
  let univU : PsKernelLevel :=
    .param (PsKernelName.str PsKernelName.anonymous "u")
  let univV : PsKernelLevel :=
    .param (PsKernelName.str PsKernelName.anonymous "v")
  let sourceLevel : PsKernelLevel :=
    .succ (.max (.succ univU) univV)
  let distributedLevel : PsKernelLevel :=
    .max (.succ (.succ univU)) (.succ univV)
  if !psKernelLevelEquivalent sourceLevel distributedLevel ||
      !psKernelLevelLe sourceLevel distributedLevel ||
      !psKernelLevelLe distributedLevel sourceLevel ||
      !psKernelLevelLe (.succ (.succ univU)) sourceLevel ||
      !psKernelLevelLe (.succ univV) sourceLevel then
    throw (IO.userError
      "C0 did not normalize successor offsets across universe maxima")
  if psKernelLevelLe (.succ (.succ (.succ univU))) sourceLevel ||
      psKernelLevelLe sourceLevel (.succ (.succ univU)) ||
      psKernelLevelLe sourceLevel (.succ univV) then
    throw (IO.userError
      "C0 universe maximum normalization falsely accepted strict inequality")
  IO.println "C0_LEAN435 distributed_max_universe_offsets=pass"

  -- Nested wrappers preserve their full context for diagnostics but must
  -- not erase a known typed resource/invalid/unsupported outcome.
  match psKernelErrorFromMessage
      "nested transformed admission: kernel reduction budget exhausted" with
  | .resourceExhausted .fuel _ => pure ()
  | _ =>
      throw (IO.userError "C0 misclassified nested resource exhaustion")
  match psKernelErrorFromMessage
      "nested transformed admission: simple inductive constructor field universe is too large" with
  | .rejectedInvalid _ => pure ()
  | _ =>
      throw (IO.userError "C0 lost known nested invalid declaration category")
  match psKernelErrorFromMessage
      "nested preprocessing: nested or invalid mutual inductive occurrence is not supported" with
  | .declinedUnsupported _ => pure ()
  | _ =>
      throw (IO.userError "C0 lost nested unsupported classification")
  match psKernelErrorFromMessage
      "nested transformed admission: unrecognized provider error" with
  | .internalError _ => pure ()
  | _ =>
      throw (IO.userError "C0 treated unknown nested error as kernel verdict")
  let stages : List String := [
    "mutual-first-type-check: ",
    "mutual-header-indices: ",
    "mutual-remaining-types: ",
    "mutual-constructor-family: ",
    "mutual-recursor-validation: ",
    "mutual-constructor-type-check: ",
    "mutual-constructor-sort: ",
    "mutual-constructor-parameters: ",
    "mutual-constructor-fields: ",
    "mutual-field-whnf: ",
    "mutual-field-domain-check: ",
    "mutual-field-ensure-sort: ",
    "mutual-field-recursive-analysis: ",
    "mutual-recursive-domain-whnf: ",
    "mutual-recursive-domain-with-target: ",
    "mutual-recursive-domain-without-target: "
  ]
  for stage in stages do
    match psKernelErrorFromMessage
        ("nested transformed admission: " ++ stage ++
         "kernel reduction budget exhausted") with
    | .resourceExhausted .fuel _ => pure ()
    | _ => throw (IO.userError "C0 lost stage-qualified nested fuel classification")
  IO.println "C0_LEAN435 nested_typed_error_outcomes=pass"
