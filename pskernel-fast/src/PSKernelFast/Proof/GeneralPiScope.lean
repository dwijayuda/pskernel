import PSKernelFast.Spec.ContextScope
import PSKernelFast.Spec.ScopeReflection
import PSKernelFast.GeneralPiFormation

/-!
P1 cross-layer proof: an INDEPENDENT specification of immutable context
scope is preserved by every G4.3b typing rule, including beta-substituted
application and let RESULT types. This proves a consequence NOT explicitly
contained in the constructors of GeneralPiRule.

It is scope/form-parameter safety, not the denotational validity of typed
terms, not a type-preserving substitution theorem, and NOT a model or
conditional consistency proof. Runtime source does not import this module.
-/

namespace PSKernelFast.Proof

open PSKernelFast.Core
open PSKernelFast.Spec

/--
For all six independently specified G4.3b constructors, a context
satisfying the independent ContextScoped model implies BOTH the source
term and inferred result type satisfy the G3 structural validity
judgment, including legal level parameters and binder indices.
-/
theorem generalPiRule_scope (params : List KName)
    {ctx : List KExpr} {expr inferredType : KExpr}
    (rule : GeneralPiRule params ctx expr inferredType) :
    ContextScoped params ctx →
    KExpr.StructurallyValid params ctx.length expr ∧
      KExpr.StructurallyValid params ctx.length inferredType := by
  induction rule with
  | sort ctx u good =>
      intro _
      exact ⟨good, good⟩
  | bound ctx index domain found =>
      intro hCtx
      obtain ⟨hIndex, hDomain⟩ :=
        ContextScoped.lookup_scoped params hCtx index domain found
      have hLift :=
        KExpr.liftBVars_structurallyValid params (index + 1) 0
          (ctx.length - (index + 1)) domain (by omega) hDomain
      have hDepth :
          (ctx.length - (index + 1)) + (index + 1) = ctx.length := by
        omega
      constructor
      · exact hIndex
      · simpa only [hDepth] using hLift
  | pi ctx name domain body style u v hDomain hBody ihDomain ihBody =>
      intro hCtx
      obtain ⟨domainScoped, domainSortScoped⟩ := ihDomain hCtx
      have hExtended : ContextScoped params (domain :: ctx) :=
        .extend hCtx domainScoped
      obtain ⟨bodyScoped, bodySortScoped⟩ := ihBody hExtended
      exact ⟨⟨domainScoped, bodyScoped⟩,
        ⟨domainSortScoped, bodySortScoped⟩⟩
  | lam ctx name domain body style u bodyType hDomain hBody ihDomain ihBody =>
      intro hCtx
      obtain ⟨domainScoped, _⟩ := ihDomain hCtx
      have hExtended : ContextScoped params (domain :: ctx) :=
        .extend hCtx domainScoped
      obtain ⟨bodyScoped, bodyTypeScoped⟩ := ihBody hExtended
      exact ⟨⟨domainScoped, bodyScoped⟩,
        ⟨domainScoped, bodyTypeScoped⟩⟩
  | app ctx fn arg name domain body style hFn hArg ihFn ihArg =>
      intro hCtx
      obtain ⟨fnScoped, functionTypeScoped⟩ := ihFn hCtx
      obtain ⟨argScoped, _⟩ := ihArg hCtx
      have resultScoped :
          KExpr.StructurallyValid params ctx.length
            (body.instantiateBVar arg 0) :=
        KExpr.instantiateBVar_top_scoped params ctx.length arg body
          argScoped functionTypeScoped.2
      exact ⟨⟨fnScoped, argScoped⟩, resultScoped⟩
  | letE ctx name declaredType value body nondep hFlag level bodyType
      hType hValue hBody ihType ihValue ihBody =>
      intro hCtx
      obtain ⟨declaredScoped, _⟩ := ihType hCtx
      obtain ⟨valueScoped, _⟩ := ihValue hCtx
      have hExtended : ContextScoped params (declaredType :: ctx) :=
        .extend hCtx declaredScoped
      obtain ⟨bodyScoped, bodyTypeScoped⟩ := ihBody hExtended
      have resultScoped :
          KExpr.StructurallyValid params ctx.length
            (bodyType.instantiateBVar value 0) :=
        KExpr.instantiateBVar_top_scoped params ctx.length value bodyType
          valueScoped bodyTypeScoped
      exact ⟨⟨⟨declaredScoped, valueScoped⟩, bodyScoped⟩,
        resultScoped⟩

/--
The actual context-formation proof produced by the running checker implies
the INDEPENDENT context-scoping invariant. No unchecked context can mint it.
-/
theorem generalPiContextWF_scoped (params : List KName)
    {ctx : List KExpr} (wf : GeneralPiContextWF params ctx) :
    ContextScoped params ctx := by
  induction wf with
  | empty => exact .empty
  | extend parent domainTyped ih =>
      exact .extend ih (generalPiRule_scope params domainTyped ih).1

/--
A successful actual closed checker run must produce an output type whose
binder indices AND symbolic universe parameters are structurally valid,
whether or not the extra fail-closed output preflight was performed.
This is not a theorem about semantic type inhabitation or kernel admission.
-/
theorem inferClosedGeneralPi_result_scoped (params : List KName)
    (expr inferredType : KExpr)
    (h : inferClosedGeneralPi params expr = .ok inferredType) :
    KExpr.StructurallyValid params 0 inferredType := by
  have hRule := (inferClosedGeneralPi_sound params expr inferredType h).2
  have hBoth := generalPiRule_scope params hRule
    (ContextScoped.empty (params := params))
  exact hBoth.2

/--
Any certified checked source/context output is structurally sound even if
the caller extracts only the returned type and ignores its proof fields.
The statement follows from actual source success, not a caller Boolean.
-/
theorem inferClosedGeneralPi_source_and_result_scoped
    (params : List KName) (expr inferredType : KExpr)
    (h : inferClosedGeneralPi params expr = .ok inferredType) :
    KExpr.StructurallyValid params 0 expr ∧
      KExpr.StructurallyValid params 0 inferredType := by
  have hRule := (inferClosedGeneralPi_sound params expr inferredType h).2
  exact generalPiRule_scope params hRule
    (ContextScoped.empty (params := params))


/--
The redundant runtime output-scope check cannot return
`malformedResult` on ANY source input because the accepted type
already satisfies the independent structural model and G3 preflight
is COMPLETE for that model. Invalid/unsupported inputs may still fail.
-/
theorem certified_ne_malformedResult (params : List KName) (expr : KExpr) :
    inferClosedGeneralPiCertified params expr ≠ .error .malformedResult := by
  intro contradiction
  by_cases hv : expr.closedInput params = true
  · cases hi : inferGeneralPi (params := params) ([] : List KExpr)
      (GeneralPiContextWF.empty (params := params)) expr with
    | none =>
        simp [inferClosedGeneralPiCertified, hv, hi] at contradiction
    | some candidate =>
        have hScope : KExpr.StructurallyValid params 0 candidate.val :=
          (generalPiRule_scope params candidate.property
            (ContextScoped.empty (params := params))).2
        have hChecked := closedInput_complete params candidate.val hScope
        simp [inferClosedGeneralPiCertified, hv, hi, hChecked] at contradiction
  · simp [inferClosedGeneralPiCertified, hv] at contradiction

/--
For every successful value-only inference, the certified entry point also
succeeds with precisely the SAME inferred type. This is not a statement
of full semantic type correctness, just an executable behavior guarantee
following from the separate structural proof.
-/
theorem inferred_success_certifiable (params : List KName)
    (expr ty : KExpr) (h : inferClosedGeneralPi params expr = .ok ty) :
    ∃ certified, inferClosedGeneralPiCertified params expr = .ok certified ∧
      certified.val = ty := by
  by_cases hv : expr.closedInput params = true
  · cases hi : inferGeneralPi (params := params) ([] : List KExpr)
      (GeneralPiContextWF.empty (params := params)) expr with
    | none =>
        simp [inferClosedGeneralPi, hv, hi] at h
    | some candidate =>
        have hSame : candidate.val = ty := by
          simpa [inferClosedGeneralPi, hv, hi] using h
        have hScope : KExpr.StructurallyValid params 0 candidate.val :=
          (generalPiRule_scope params candidate.property
            (ContextScoped.empty (params := params))).2
        have hChecked := closedInput_complete params candidate.val hScope
        refine ⟨⟨candidate.val, ⟨KExpr.closedInput_sound params expr hv,
          hScope, candidate.property⟩⟩, ?_, hSame⟩
        simp [inferClosedGeneralPiCertified, hv, hi, hChecked]
  · simp [inferClosedGeneralPi, hv] at h

#print axioms generalPiRule_scope
#print axioms generalPiContextWF_scoped
#print axioms certified_ne_malformedResult
#print axioms inferred_success_certifiable
#print axioms inferClosedGeneralPi_source_and_result_scoped

end PSKernelFast.Proof
