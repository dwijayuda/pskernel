import Ps.KernelCore.Architecture.Work

def main : IO Unit := do
  let checker := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let some initial := psKernelC0ArchitectureBegin checker
    | throw (IO.userError "C0 architecture refused valid empty store")
  let x := PsKernelName.str .anonymous "x"
  let a := PsKernelExpr.const (.str .anonymous "a") []
  let id := PsKernelExpr.lam x (.sort .zero) (.bvar 0) .default
  let first := PsKernelExpr.app id a
  let some staged := psKernelC0ArchitectureStage initial first
    | throw (IO.userError "C0 architecture could not stage first syntax")
  let some repeated := psKernelC0ArchitectureStage staged first
    | throw (IO.userError "C0 architecture could not stage repeated syntax")
  if !psKernelC0ArchitectureWorkValid repeated then
    throw (IO.userError "C0 staged work failed full store replay")
  match psKernelC0ArchitecturePreview 4096 repeated first with
  | .ok (observation, _) =>
      if !observation.agrees || !psKernelExprEqual observation.sourceValue a then
        throw (IO.userError "C0 architecture preview was not source-owned")
  | .error err => throw (IO.userError ("C0 architecture preview failed: " ++ err))
  let some (committed, roots) := psKernelC0ArchitectureCommitSyntax repeated
    | throw (IO.userError "C0 architecture declined valid promotion")
  if !psKernelC0ReplayValidateStore committed ||
      roots.length != 2 ||
      !roots.all (psKernelExprEqual first) then
    throw (IO.userError "C0 architecture lost duplicate roots or canonical syntax")
  if (psKernelC0ArchitectureAbort repeated).nodes.size !=
      psKernelC0StoreEmpty.nodes.size then
    throw (IO.userError "C0 architecture abort changed persistent prefix")
  let forged := { repeated with stagedRoots := [committed.nodes.size + 10] }
  if (psKernelC0ArchitectureCommitSyntax forged).isSome then
    throw (IO.userError "C0 architecture accepted foreign root handle")
  let some untyped := psKernelC0ArchitectureStage initial (.bvar 0)
    | throw (IO.userError "C0 syntax arena should not decide typing")
  if (psKernelC0ArchitectureCommitSyntax untyped).isNone then
    throw (IO.userError "C0 syntax stage incorrectly made a typing decision")
  match psKernelC0ArchitectureCheckWork 4096 untyped (.bvar 0) with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "C0 source checker approved an unbound variable")
  match psKernelC0ArchitectureCheckWork 4096 initial (.sort .zero) with
  | .error err =>
      throw (IO.userError ("C0 source-authoritative check failed: " ++ err))
  | .ok (_, work) =>
      if !psKernelC0ArchitectureWorkValid work then
        throw (IO.userError "C0 checked transaction became invalid")
  -- A checked declaration atomically extends only the checked environment.
  -- Retained scratch syntax stays unaffected; the session cache is rebuilt.
  let aliasName : PsKernelName := .str .anonymous "ArchitectureAlias"
  let alias : PsKernelDefinitionInfo := {
    base := {
      name := aliasName
      levelParams := []
      type := .sort (.succ .zero)
    }
    value := .sort .zero
    hints := .abbrevHint
    safety := .safe
  }
  -- Fresh checking caches after admission must NOT silently reset a
  -- caller-selected reduction policy. The transaction owns both policy and
  -- environment revision; source checking still performs the admission.
  let eagerChecker : PsKernelCheckerSession := {
    initial.checker with
    context := { initial.checker.context with eagerReduce := true }
  }
  let eagerInitial : PsKernelC0ArchitectureWork := {
    initial with checker := eagerChecker
  }
  match psKernelC0ArchitectureAdmit 4096 eagerInitial
      (.definition alias) with
  | .error reason =>
      throw (IO.userError ("checked eager admission failed: " ++ reason))
  | .ok eagerAdmitted =>
      if !eagerAdmitted.checker.context.eagerReduce ||
          !psKernelC0ArchitectureWorkValid eagerAdmitted then
        throw (IO.userError
          "checked admission reset reduction policy or invalidated work")
  match psKernelC0ArchitectureAdmit 4096 initial (.definition alias) with
  | .error err =>
      throw (IO.userError ("C0 source declaration admission failed: " ++ err))
  | .ok admitted =>
      if !psKernelC0ArchitectureWorkValid admitted ||
          !admitted.stagedRoots.isEmpty then
        throw (IO.userError "C0 admission mutated syntax staging")
      -- One validated work boundary must own every *accepting* checked
      -- judgment, not just declarations. None of these methods reads a
      -- candidate as a proof or reuses the pre-admission environment cache.
      match psKernelC0ArchitectureWhnfWork 4096 admitted
          (.const aliasName []) with
      | .error reason =>
          throw (IO.userError ("checked WHNF interface failed: " ++ reason))
      | .ok (value, next) =>
          if !psKernelExprEqual value (.sort .zero) ||
              !psKernelC0ArchitectureWorkValid next then
            throw (IO.userError "checked WHNF changed source semantics")
      match psKernelC0ArchitectureInferWork 4096 admitted (.sort .zero) with
      | .error reason =>
          throw (IO.userError ("checked inference interface failed: " ++ reason))
      | .ok (ty, _) =>
          if !psKernelExprEqual ty (.sort (.succ .zero)) then
            throw (IO.userError "checked inference returned wrong Sort")
      match psKernelC0ArchitectureDefEqWork 4096 admitted
          (.const aliasName []) (.sort .zero) with
      | .error reason =>
          throw (IO.userError ("checked DefEq interface failed: " ++ reason))
      | .ok (same, _) =>
          if !same then
            throw (IO.userError "checked DefEq missed admitted alias")
      match psKernelC0ArchitectureDefEqWork 4096 admitted
          (.sort .zero) (.sort (.succ .zero)) with
      | .error reason =>
          throw (IO.userError ("checked negative DefEq failed: " ++ reason))
      | .ok (same, _) =>
          if same then
            throw (IO.userError "checked DefEq equated different universes")
      match psKernelC0ArchitectureIsPropWork 4096 admitted (.sort .zero) with
      | .error reason =>
          throw (IO.userError ("checked isProp interface failed: " ++ reason))
      | .ok (isProp, _) =>
          if isProp then
            throw (IO.userError "Sort0 was classified as a proposition term")
      match psKernelC0ArchitectureInferWork 4096 forged (.sort .zero) with
      | .error _ => pure ()
      | .ok _ =>
          throw (IO.userError "forged scratch roots authorized checked inference")
      match psKernelC0ArchitectureDefEqWork 4096 forged
          (.sort .zero) (.sort .zero) with
      | .error _ => pure ()
      | .ok _ =>
          throw (IO.userError "forged scratch roots authorized checked equality")
      match psKernelC0ArchitecturePreview 4096 admitted (.const aliasName []) with
      | .error err =>
          throw (IO.userError ("C0 admitted source delta failed: " ++ err))
      | .ok (observation, _) =>
          if observation.agrees ||
              !psKernelExprEqual observation.sourceValue (.sort .zero) then
            throw (IO.userError "C0 candidate cache authorized a delta judgment")
      match psKernelC0ArchitecturePreviewDelta
          4096 admitted (.const aliasName []) with
      | .error err =>
          throw (IO.userError ("C0 delta preview failed: " ++ err))
      | .ok (observation, _) =>
          if !observation.agrees ||
              !psKernelExprEqual observation.sourceValue (.sort .zero) then
            throw (IO.userError
              "C0 environment-aware lazy delta did not match source WHNF")
      match psKernelC0ArchitecturePreviewStructural
          4096 admitted (.const aliasName []) with
      | .error err =>
          throw (IO.userError ("C0 structural preview rejected: " ++ err))
      | .ok (observation, _) =>
          if !observation.agrees ||
              !psKernelExprEqual observation.sourceValue (.sort .zero) then
            throw (IO.userError
              "C0 structural candidate was not source-authoritative")
      -- A preview must never make an ill-typed expression admissible.
      match psKernelC0ArchitectureCheckWork 4096 admitted
          (.app (.sort .zero) (.sort .zero)) with
      | .error _ => pure ()
      | .ok _ =>
          throw (IO.userError
            "C0 structural preview polluted trusted checker admission")
      -- The new shared-fuel demand candidate remains an observation; it
      -- does not rewrite source-session caches or authorize admission.
      let nestedNat : PsKernelExpr :=
        .app (.app (.const psKernelNatAddName [])
          (.lit (.nat 1)))
          (.app (.app (.const psKernelNatMulName [])
            (.lit (.nat 6))) (.lit (.nat 7)))
      match psKernelC0ArchitecturePreviewDemand 4096 admitted nestedNat with
      | .error err =>
          throw (IO.userError ("C0 nested-demand preview rejected: " ++ err))
      | .ok (observation, _) =>
          if !observation.agrees ||
              !psKernelExprEqual observation.sourceValue (.lit (.nat 43)) then
            throw (IO.userError
              "C0 nested demand preview diverged from source WHNF")
      match psKernelC0ArchitectureCheckWork 4096 admitted
          (.app (.sort .zero) (.sort .zero)) with
      | .error _ => pure ()
      | .ok _ =>
          throw (IO.userError
            "C0 nested candidate authorized an invalid application")
      match psKernelC0ArchitecturePreviewDemandMetered
          4096 4096 admitted nestedNat with
      | .error err =>
          throw (IO.userError ("metered checked-work preview failed: " ++ err))
      | .ok (observation, _) =>
          if !observation.agrees ||
              !psKernelExprEqual observation.sourceValue (.lit (.nat 43)) then
            throw (IO.userError "metered preview lost source agreement")
      match psKernelC0ArchitecturePreviewDemandMetered
          4096 1 admitted nestedNat with
      | .error err =>
          throw (IO.userError ("quota decline changed source result: " ++ err))
      | .ok (observation, _) =>
          if observation.candidateValue.isSome ||
              !psKernelExprEqual observation.sourceValue (.lit (.nat 43)) then
            throw (IO.userError
              "metered candidate quota failure altered checked WHNF")
      -- Typed K/eta observation is session-scoped and cannot repurpose a
      -- definition name as recursor metadata or admit a candidate term.
      match psKernelC0ArchitecturePreviewTypedMajor
          4096 admitted aliasName (.sort .zero) with
      | .error _ => pure ()
      | .ok _ =>
          throw (IO.userError
            "typed-major preview accepted non-recursor metadata")
      match psKernelC0ArchitectureCheckWork 4096 admitted
          (.app (.sort .zero) (.sort .zero)) with
      | .error _ => pure ()
      | .ok _ =>
          throw (IO.userError
            "typed-major observation bypassed source checking")
      -- Re-admitting the same name must reject atomically.
      match psKernelC0ArchitectureAdmit 4096 admitted (.definition alias) with
      | .error _ => pure ()
      | .ok _ =>
          throw (IO.userError "C0 architecture admitted duplicate declaration")
  IO.println "C0_ARCHITECTURE atomic_declaration_and_cache_revision=pass"
  IO.println "C0_ARCHITECTURE validated_scratch_transaction=pass"
  IO.println "C0_ARCHITECTURE candidate_does_not_authorize_admission=pass"
  IO.println "C0_ARCHITECTURE unified_source_whnf_infer_defeq_prop=pass"
