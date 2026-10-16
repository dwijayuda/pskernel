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

  -- Official Lean 4.35 type_checker.cpp checks the binary Nat operator
  -- *before* entering reduce_bin_nat_op/WHNF of either argument. A generic
  -- two-argument constant must not trigger Nat operand reduction, since
  -- that previously altered WHNF caches and could cause spurious fuel errors.
  let notNatName : PsKernelName :=
    .str .anonymous "C0.notNatBinary"
  let notNat : PsKernelExpr :=
    .app (.app (.const notNatName []) addition) addition
  let guardContext := psKernelCheckerContextEmpty psKernelEnvironmentEmpty
  let guardState : PsKernelCheckerState := {
    psKernelCheckerStateEmpty with nextFresh := 17
  }
  let forbiddenWhnf :
      PsKernelCheckerContext -> PsKernelCheckerState -> PsKernelExpr ->
        Except String (PsKernelExpr × PsKernelCheckerState) :=
    fun _ _ _ => .error "C0_NAT_FORBIDDEN_OPERAND_WHNF"
  match psKernelReduceNatWith forbiddenWhnf guardContext guardState notNat with
  | .ok (.none, nextState) =>
      if nextState.nextFresh != 17 then
        throw (IO.userError "Non-Nat primitive guard altered checker state")
  | .ok (.some _, _) =>
      throw (IO.userError "Non-Nat primitive guard invented a reduction")
  | .error error =>
      throw (IO.userError ("Non-Nat primitive evaluated an operand: " ++ error))
  -- No weakening of known Nat operation semantics: the same callback is
  -- still required for a recognized Nat.add.
  match psKernelReduceNatWith forbiddenWhnf guardContext guardState addition with
  | .error "C0_NAT_FORBIDDEN_OPERAND_WHNF" => pure ()
  | _ => throw (IO.userError "Nat.add bypassed required operand WHNF")
  -- For a recognized Nat operator, a nonnumeral first WHNF operand
  -- must stop reduction *before* visiting the second operand, exactly
  -- like type_checker.cpp::reduce_bin_nat_op. Retain first-stage cache/state
  -- changes; never synthesize a value from the stuck term.
  let stuckLeft : PsKernelExpr := .const notNatName []
  let stuckAddition : PsKernelExpr :=
    .app (.app (.const psKernelNatAddName []) stuckLeft) three
  let checkFirstOnly :
      PsKernelCheckerContext -> PsKernelCheckerState -> PsKernelExpr ->
        Except String (PsKernelExpr × PsKernelCheckerState) :=
    fun _ current input =>
      if psKernelExprEqual input stuckLeft then
        .ok (input, { current with nextFresh := current.nextFresh + 1 })
      else
        .error "C0_NAT_UNEXPECTED_SECOND_OPERAND"
  match psKernelReduceNatWith checkFirstOnly guardContext guardState
      stuckAddition with
  | .ok (.none, nextState) =>
      if nextState.nextFresh != 18 then
        throw (IO.userError "Stuck Nat first operand lost checker state")
  | .ok (.some _, _) =>
      throw (IO.userError "Stuck Nat first operand invented a reduction")
  | .error why =>
      throw (IO.userError ("Stuck Nat binary visited right: " ++ why))
  IO.println "C0_LEAN435 stuck_nat_left_preserves_state_skips_right=pass"

  -- Even a known Nat name with illegal universe arguments is not reduced.
  let nonemptyLevels : PsKernelExpr :=
    .app (.app (.const psKernelNatAddName [.zero]) two) three
  match psKernelReduceNatWith forbiddenWhnf guardContext guardState
      nonemptyLevels with
  | .ok (.none, nextState) =>
      if nextState.nextFresh != 17 then
        throw (IO.userError "Nonempty Nat universe list altered state")
  | _ => throw (IO.userError "Nonempty Nat universe list evaluated operands")
  -- Guard covers every operation actually implemented in the primitive
  -- reducer, including the bitwise and shift operations.
  let knownNatBinaryNames : List PsKernelName := [
    psKernelNatAddName, psKernelNatSubName, psKernelNatMulName,
    psKernelNatPowName, psKernelNatGcdName, psKernelNatModName,
    psKernelNatDivName, psKernelNatBeqName, psKernelNatBleName,
    psKernelNatLandName, psKernelNatLorName, psKernelNatXorName,
    psKernelNatShiftLeftName, psKernelNatShiftRightName
  ]
  for name in knownNatBinaryNames do
    if !psKernelNatBinaryPrimitiveName name then
      throw (IO.userError "Recognized Nat reducer is missing from dispatch")
  if psKernelNatBinaryPrimitiveName notNatName ||
      psKernelNatBinaryPrimitiveName psKernelStringName then
    throw (IO.userError "Unrecognized reducer entered Nat binary dispatch")
  IO.println "C0_LEAN435 non_nat_binary_avoids_eager_operand_whnf=pass"

  -- Cache policy is Boolean work selection, not theorem admission.
  -- The native candidate bypasses FVar traversal on checked applications,
  -- lambdas, Pi and literals, but equals the unchanged source Boolean.
  let closedApp : PsKernelExpr :=
    .app (.const psKernelNatAddName []) two
  let localFVarName : PsKernelName :=
    .str .anonymous "C0.cacheScopeLocal"
  let scopedApp : PsKernelExpr :=
    .app closedApp (.fvar localFVarName)
  let lambda : PsKernelExpr :=
    .lam localFVarName (.sort .zero) closedApp .default
  let forallType : PsKernelExpr :=
    .forallE localFVarName (.sort .zero) scopedApp .default
  let policyFixtures : List PsKernelExpr := [
    two, closedApp, scopedApp, lambda, forallType,
    .fvar localFVarName, .const psKernelNatAddName [],
    .mdata 17 scopedApp,
    .proj psKernelNatName 0 scopedApp
  ]
  for expr in policyFixtures do
    for inferOnly in [false, true] do
      if psKernelInferCacheEligible inferOnly expr !=
          psKernelC0FastInferCacheEligible inferOnly expr then
        throw (IO.userError "Source-exact inference-cache selector drift")
  for expr in [closedApp, scopedApp, lambda, forallType, two] do
    if psKernelC0FastInferCacheEligible false expr then
      throw (IO.userError "Checked non-cacheable source unexpectedly eligible")
  if !psKernelC0FastInferCacheEligible true closedApp ||
      psKernelC0FastInferCacheEligible true scopedApp then
    throw (IO.userError "Infer-only cache FVar scope guard was altered")
  IO.println "C0_LEAN435 lazy_infer_cache_selector_source_equivalence=pass"

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
    "mutual-recursive-domain-without-target: ",
    "mutual-recursive-domain-without-target-definition: ",
    "mutual-recursive-domain-without-target-inductive: ",
    "mutual-recursive-domain-without-target-local-let: ",
    "mutual-recursive-domain-without-target-other: "
  ]
  for stage in stages do
    match psKernelErrorFromMessage
        ("nested transformed admission: " ++ stage ++
         "kernel reduction budget exhausted") with
    | .resourceExhausted .fuel _ => pure ()
    | _ => throw (IO.userError "C0 lost stage-qualified nested fuel classification")
  IO.println "C0_LEAN435 nested_typed_error_outcomes=pass"

  -- A checked inductive type cannot delta unfold, beta reduce, or trigger
  -- recursor computation at its type head. Only an occurrence-free source
  -- syntax may use the neutral positivity shortcut. Malformed/unknown heads
  -- and target-bearing arguments continue through ordinary checking.
  let existing : PsKernelName :=
    .str .anonymous "NeutralExistingInductive"
  let freshTarget : PsKernelName :=
    .str .anonymous "FreshRecursiveTarget"
  let existingInfo : PsKernelInductiveInfo := {
    base := {
      name := existing
      levelParams := []
      type := .sort (.succ .zero)
    }
    numParams := 0
    numIndices := 0
    all := [existing]
    ctors := []
    numNested := 0
    isRec := false
    isReflexive := false
    isUnsafe := false
  }
  -- This unchecked *test fixture* constructs a semantic environment only to
  -- exercise a syntax classification. It is not a kernel admission verdict.
  let neutralEnv := psKernelEnvironmentAddUnchecked
    psKernelEnvironmentEmpty (.inductInfo existingInfo)
  let neutralSession := psKernelMkCheckerSession neutralEnv []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let neutralDomain : PsKernelExpr :=
    .app (.const existing []) (.sort .zero)
  if !psKernelMutualInductiveNeutralDomain
      neutralSession [freshTarget] neutralDomain then
    throw (IO.userError "C0 failed to recognize stuck inductive type head")
  -- Differential check against the source-owned authoritative WHNF operation.
  match psKernelSessionWhnf 4096 neutralSession neutralDomain with
  | .ok (reduced, _) =>
      if !psKernelExprEqual reduced neutralDomain then
        throw (IO.userError "C0 neutral inductive head was not actually WHNF")
  | .error message =>
      throw (IO.userError ("C0 neutral inductive WHNF failed: " ++ message))
  let recursiveDomain : PsKernelExpr :=
    .app (.const existing []) (.const freshTarget [])
  if psKernelMutualInductiveNeutralDomain
      neutralSession [freshTarget] recursiveDomain ||
      psKernelMutualInductiveNeutralDomain
        neutralSession [freshTarget] (.const freshTarget []) ||
      psKernelMutualInductiveNeutralDomain
        neutralSession [freshTarget] (.const (.str .anonymous "Unknown") []) ||
      psKernelMutualInductiveNeutralDomain
        neutralSession [freshTarget]
        (.app (.const psKernelNatAddName []) (.lit (.nat 2))) then
    throw (IO.userError
      "C0 shortcut permitted target occurrence or unqualified head")
  IO.println "C0_LEAN435 neutral_inductive_positivity_shortcut=pass"

  -- A reducible alias of an inductive type must unfold to that type at WHNF.
  -- This checks the general delta path independently of the 79K-record Init
  -- fixture and prevents a stuck self-alias being mistaken for neutrality.
  let aliasName : PsKernelName :=
    .str .anonymous "NeutralTypeAlias"
  let aliasInfo : PsKernelDefinitionInfo := {
    base := {
      name := aliasName
      levelParams := []
      type := .sort (.succ .zero)
    }
    value := .const existing []
    hints := .abbrevHint
    safety := .safe
  }
  let aliasedEnv := psKernelEnvironmentAddUnchecked neutralEnv
    (.defnInfo aliasInfo)
  let aliasedSession := psKernelMkCheckerSession aliasedEnv []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let aliasDomain : PsKernelExpr :=
    .app (.const aliasName []) (.sort .zero)
  if psKernelMutualInductiveNeutralDomain
      aliasedSession [freshTarget] aliasDomain then
    throw (IO.userError "C0 incorrectly treated a delta alias as neutral")
  match psKernelSessionWhnf 4096 aliasedSession aliasDomain with
  | .ok (value, _) =>
      if !psKernelExprEqual value neutralDomain then
        throw (IO.userError "C0 failed to reduce a checked inductive alias")
  | .error message =>
      throw (IO.userError ("C0 simple delta alias WHNF failed: " ++ message))
  match psKernelMutualNeutralAfterOneDelta
      aliasedSession [freshTarget] aliasDomain with
  | some value =>
      if !psKernelExprEqual value neutralDomain then
        throw (IO.userError "C0 one-delta neutral path altered meaning")
  | none =>
      throw (IO.userError "C0 one-delta neutral shortcut missed checked alias")
  if (psKernelMutualNeutralAfterOneDelta
      aliasedSession [freshTarget] recursiveDomain).isSome then
    throw (IO.userError "C0 one-delta neutral path accepted target-bearing domain")
  if (psKernelMutualNeutralAfterOneDelta
      aliasedSession [freshTarget] (.const freshTarget [])).isSome then
    throw (IO.userError "C0 one-delta path accepted the inductive target")
  let anotherAlias : PsKernelName :=
    .str .anonymous "ChainedAlias"
  let chainInfo : PsKernelDefinitionInfo := {
    base := {
      name := anotherAlias
      levelParams := []
      type := .sort (.succ .zero)
    }
    value := .const aliasName []
    hints := .abbrevHint
    safety := .safe
  }
  let chainEnv := psKernelEnvironmentAddUnchecked aliasedEnv
    (.defnInfo chainInfo)
  let chainSession := psKernelMkCheckerSession chainEnv []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  if (psKernelMutualNeutralAfterOneDelta
      chainSession [freshTarget] (.const anotherAlias [])).isSome then
    throw (IO.userError "C0 one-delta shortcut bypassed remaining alias")
  IO.println "C0_LEAN435 one_delta_to_inductive_neutral=pass"
  IO.println "C0_LEAN435 inductive_alias_delta_whnf=pass"
