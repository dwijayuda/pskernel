import Ps.KernelCore.Admission.Inductive.Common.Elimination

theorem psKernelSimpleExprMember_nil
    (expr : PsKernelExpr) :
    psKernelSimpleExprMember expr List.nil = false := by
  rfl

theorem psKernelSimpleCtorAllowsLargeElimWithFuel_zero
    (session : PsKernelCheckerSession)
    (type : PsKernelExpr)
    (revNonProp : List PsKernelExpr) :
    psKernelSimpleCtorAllowsLargeElimWithFuel
        0 session type revNonProp =
      Except.error "simple inductive elimination budget exhausted" := by
  rfl


theorem psKernelSimpleKTarget_true_iff
    (resultLevel : PsKernelLevel)
    (shapes : List PsKernelSimpleConstructorShape) :
    psKernelSimpleKTarget resultLevel shapes = true ↔
      psKernelLevelNormalizesToZero resultLevel = true ∧
      ∃ shape : PsKernelSimpleConstructorShape,
        shapes = List.cons shape List.nil ∧
        shape.fields = List.nil := by
  cases hZero :
      psKernelLevelNormalizesToZero resultLevel with
  | false =>
      simp [psKernelSimpleKTarget, hZero]
  | true =>
      cases shapes with
      | nil =>
          simp [psKernelSimpleKTarget, hZero]
      | cons shape rest =>
          cases rest with
          | nil =>
              cases hFields : shape.fields with
              | nil =>
                  simp [
                    psKernelSimpleKTarget,
                    hZero,
                    hFields
                  ]
              | cons field fields =>
                  simp [
                    psKernelSimpleKTarget,
                    hZero,
                    hFields
                  ]
          | cons second tail =>
              simp [psKernelSimpleKTarget, hZero]

theorem psKernelSimpleElimOnlyAtZero_true_semantics
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (params : List PsKernelOpenBinder)
    (resultLevel : PsKernelLevel)
    (ctors : List PsKernelSimpleConstructorDecl)
    (hSuccess :
      psKernelSimpleElimOnlyAtZero
          fuel
          session
          params
          resultLevel
          ctors =
        Except.ok true) :
    psKernelLevelIsNotZero resultLevel = false ∧
      (
        (∃ ctor : PsKernelSimpleConstructorDecl,
          ctors = List.cons ctor List.nil ∧
          psKernelSimpleCtorAllowsLargeElim
              fuel
              session
              params
              ctor.type =
            Except.ok false)
        ∨
        (∃
          (first second : PsKernelSimpleConstructorDecl)
          (rest : List PsKernelSimpleConstructorDecl),
            ctors =
              List.cons
                first
                (List.cons second rest))
      ) := by
  cases hLevel :
      psKernelLevelIsNotZero resultLevel with
  | true =>
      simp [
        psKernelSimpleElimOnlyAtZero,
        hLevel
      ] at hSuccess
  | false =>
      constructor
      · rfl
      · cases ctors with
        | nil =>
            simp [
              psKernelSimpleElimOnlyAtZero,
              hLevel
            ] at hSuccess
        | cons ctor rest =>
            cases rest with
            | nil =>
                cases hLarge :
                    psKernelSimpleCtorAllowsLargeElim
                      fuel
                      session
                      params
                      ctor.type with
                | error error =>
                    simp [
                      psKernelSimpleElimOnlyAtZero,
                      hLevel,
                      hLarge
                    ] at hSuccess
                | ok canLarge =>
                    cases canLarge with
                    | true =>
                        simp [
                          psKernelSimpleElimOnlyAtZero,
                          hLevel,
                          hLarge
                        ] at hSuccess
                    | false =>
                        exact
                          Or.inl
                            ⟨ctor, rfl, hLarge⟩
            | cons second tail =>
                exact
                  Or.inr
                    ⟨ctor, second, tail, rfl⟩
