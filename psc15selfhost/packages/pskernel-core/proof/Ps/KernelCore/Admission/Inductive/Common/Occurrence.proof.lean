import Ps.KernelCore.Admission.Inductive.Common.Occurrence
import Ps.KernelCore.Metatheory.Inductive

theorem psKernelSimpleUniformParamArgsMatchWorker_nil
    (offset index : Nat) :
    psKernelSimpleUniformParamArgsMatchWorker
        List.nil offset index =
      true := by
  rfl

theorem psKernelSimpleCheckUniformOccurrenceWithFuel_zero
    (declaredNames : List PsKernelName)
    (expectedLevels : List PsKernelLevel)
    (numParams : Nat)
    (expr : PsKernelExpr)
    (offset : Nat) :
    psKernelSimpleCheckUniformOccurrenceWithFuel
        0 declaredNames expectedLevels numParams expr offset =
      Except.error
        "simple inductive uniform-occurrence budget exhausted" := by
  rfl

theorem psKernelExprContainsConst_bvar
    (target : PsKernelName)
    (index : Nat) :
    psKernelExprContainsConst
        target
        (PsKernelExpr.bvar index) =
      false := by
  rfl


theorem psKernelSimpleCheckUniformOccurrenceHead_true_refines
    (declaredNames : List PsKernelName)
    (expectedLevels : List PsKernelLevel)
    (numParams : Nat)
    (expr : PsKernelExpr)
    (offset : Nat)
    (hSuccess :
      psKernelSimpleCheckUniformOccurrenceHead
          declaredNames
          expectedLevels
          numParams
          expr
          offset =
        Except.ok true) :
    PsKernelUniformOccurrenceHeadValid
      declaredNames
      expectedLevels
      numParams
      expr
      offset := by
  cases hFn : psKernelExprGetAppFn expr with
  | const name levels =>
      let args := psKernelExprGetAppArgs expr
      cases hDeclared :
          psKernelSimpleDeclaredNameMember
            name
            declaredNames with
      | false =>
          simp [
            psKernelSimpleCheckUniformOccurrenceHead,
            hFn,
            args,
            hDeclared
          ] at hSuccess
      | true =>
          cases hShort :
              Nat.ble
                (psKernelExprListLength args)
                numParams with
          | false =>
              simp [
                psKernelSimpleCheckUniformOccurrenceHead,
                hFn,
                args,
                hDeclared,
                hShort
              ] at hSuccess
          | true =>
              cases hOffset :
                  psKernelNatGe offset numParams with
              | false =>
                  simp [
                    psKernelSimpleCheckUniformOccurrenceHead,
                    hFn,
                    args,
                    hDeclared,
                    hShort,
                    hOffset
                  ] at hSuccess
              | true =>
                  cases hFull :
                      Nat.beq
                        (psKernelExprListLength args)
                        numParams with
                  | false =>
                      simp [
                        psKernelSimpleCheckUniformOccurrenceHead,
                        hFn,
                        args,
                        hDeclared,
                        hShort,
                        hOffset,
                        hFull
                      ] at hSuccess
                  | true =>
                      cases hLevels :
                          psKernelLevelListEq
                            levels
                            expectedLevels with
                      | false =>
                          simp [
                            psKernelSimpleCheckUniformOccurrenceHead,
                            hFn,
                            args,
                            hDeclared,
                            hShort,
                            hOffset,
                            hFull,
                            hLevels
                          ] at hSuccess
                      | true =>
                          cases hArgs :
                              psKernelSimpleUniformParamArgsMatch
                                offset
                                args
                                0 with
                          | false =>
                              simp [
                                psKernelSimpleCheckUniformOccurrenceHead,
                                hFn,
                                args,
                                hDeclared,
                                hShort,
                                hOffset,
                                hFull,
                                hLevels,
                                hArgs
                              ] at hSuccess
                          | true =>
                              have hLength :
                                  psKernelExprListLength args =
                                    numParams := by
                                simpa using hFull
                              exact
                                ⟨name, levels, args,
                                  hFn, rfl, hDeclared,
                                  hLength, hOffset, hLevels, hArgs⟩
  | bvar index =>
      simp [psKernelSimpleCheckUniformOccurrenceHead, hFn] at hSuccess
  | fvar name =>
      simp [psKernelSimpleCheckUniformOccurrenceHead, hFn] at hSuccess
  | mvar name =>
      simp [psKernelSimpleCheckUniformOccurrenceHead, hFn] at hSuccess
  | sort level =>
      simp [psKernelSimpleCheckUniformOccurrenceHead, hFn] at hSuccess
  | app fn arg =>
      simp [psKernelSimpleCheckUniformOccurrenceHead, hFn] at hSuccess
  | lam name type body binderInfo =>
      simp [psKernelSimpleCheckUniformOccurrenceHead, hFn] at hSuccess
  | forallE name type body binderInfo =>
      simp [psKernelSimpleCheckUniformOccurrenceHead, hFn] at hSuccess
  | letE name type value body nondep =>
      simp [psKernelSimpleCheckUniformOccurrenceHead, hFn] at hSuccess
  | lit literal =>
      simp [psKernelSimpleCheckUniformOccurrenceHead, hFn] at hSuccess
  | mdata metadata body =>
      simp [psKernelSimpleCheckUniformOccurrenceHead, hFn] at hSuccess
  | proj typeName index body =>
      simp [psKernelSimpleCheckUniformOccurrenceHead, hFn] at hSuccess

theorem psKernelSimpleCheckUniformOccurrenceWithFuel_success_refines
    (fuel : Nat)
    (declaredNames : List PsKernelName)
    (expectedLevels : List PsKernelLevel)
    (numParams : Nat)
    (expr : PsKernelExpr)
    (offset : Nat)
    (hSuccess :
      psKernelSimpleCheckUniformOccurrenceWithFuel
          fuel
          declaredNames
          expectedLevels
          numParams
          expr
          offset =
        Except.ok Unit.unit) :
    PsKernelUniformOccurrenceSafe
      declaredNames
      expectedLevels
      numParams
      expr
      offset := by
  induction fuel generalizing expr offset with
  | zero =>
      simp [
        psKernelSimpleCheckUniformOccurrenceWithFuel
      ] at hSuccess
  | succ remaining ih =>
      cases hHead :
          psKernelSimpleCheckUniformOccurrenceHead
            declaredNames
            expectedLevels
            numParams
            expr
            offset with
      | error error =>
          simp [
            psKernelSimpleCheckUniformOccurrenceWithFuel,
            hHead
          ] at hSuccess
      | ok stop =>
          cases stop with
          | true =>
              unfold PsKernelUniformOccurrenceSafe
              rw [hHead]
              exact
                psKernelSimpleCheckUniformOccurrenceHead_true_refines
                  declaredNames
                  expectedLevels
                  numParams
                  expr
                  offset
                  hHead
          | false =>
              cases expr with
              | app fn arg =>
                  cases hFn :
                      psKernelSimpleCheckUniformOccurrenceWithFuel
                        remaining
                        declaredNames
                        expectedLevels
                        numParams
                        fn
                        offset with
                  | error error =>
                      simp [
                        psKernelSimpleCheckUniformOccurrenceWithFuel,
                        hHead,
                        hFn
                      ] at hSuccess
                  | ok fnUnit =>
                      cases fnUnit
                      have hArg :
                          psKernelSimpleCheckUniformOccurrenceWithFuel
                              remaining
                              declaredNames
                              expectedLevels
                              numParams
                              arg
                              offset =
                            Except.ok Unit.unit := by
                        simpa [
                          psKernelSimpleCheckUniformOccurrenceWithFuel,
                          hHead,
                          hFn
                        ] using hSuccess
                      simp [
                        PsKernelUniformOccurrenceSafe,
                        hHead
                      ]
                      exact
                        ⟨
                          ih fn offset hFn,
                          ih arg offset hArg
                        ⟩
              | lam name type body binderInfo =>
                  cases hType :
                      psKernelSimpleCheckUniformOccurrenceWithFuel
                        remaining
                        declaredNames
                        expectedLevels
                        numParams
                        type
                        offset with
                  | error error =>
                      simp [
                        psKernelSimpleCheckUniformOccurrenceWithFuel,
                        hHead,
                        hType
                      ] at hSuccess
                  | ok typeUnit =>
                      cases typeUnit
                      have hBody :
                          psKernelSimpleCheckUniformOccurrenceWithFuel
                              remaining
                              declaredNames
                              expectedLevels
                              numParams
                              body
                              (Nat.succ offset) =
                            Except.ok Unit.unit := by
                        simpa [
                          psKernelSimpleCheckUniformOccurrenceWithFuel,
                          hHead,
                          hType
                        ] using hSuccess
                      simp [
                        PsKernelUniformOccurrenceSafe,
                        hHead
                      ]
                      exact
                        ⟨
                          ih type offset hType,
                          ih body (Nat.succ offset) hBody
                        ⟩
              | forallE name type body binderInfo =>
                  cases hType :
                      psKernelSimpleCheckUniformOccurrenceWithFuel
                        remaining
                        declaredNames
                        expectedLevels
                        numParams
                        type
                        offset with
                  | error error =>
                      simp [
                        psKernelSimpleCheckUniformOccurrenceWithFuel,
                        hHead,
                        hType
                      ] at hSuccess
                  | ok typeUnit =>
                      cases typeUnit
                      have hBody :
                          psKernelSimpleCheckUniformOccurrenceWithFuel
                              remaining
                              declaredNames
                              expectedLevels
                              numParams
                              body
                              (Nat.succ offset) =
                            Except.ok Unit.unit := by
                        simpa [
                          psKernelSimpleCheckUniformOccurrenceWithFuel,
                          hHead,
                          hType
                        ] using hSuccess
                      simp [
                        PsKernelUniformOccurrenceSafe,
                        hHead
                      ]
                      exact
                        ⟨
                          ih type offset hType,
                          ih body (Nat.succ offset) hBody
                        ⟩
              | letE name type value body nondep =>
                  cases hType :
                      psKernelSimpleCheckUniformOccurrenceWithFuel
                        remaining
                        declaredNames
                        expectedLevels
                        numParams
                        type
                        offset with
                  | error error =>
                      simp [
                        psKernelSimpleCheckUniformOccurrenceWithFuel,
                        hHead,
                        hType
                      ] at hSuccess
                  | ok typeUnit =>
                      cases typeUnit
                      cases hValue :
                          psKernelSimpleCheckUniformOccurrenceWithFuel
                            remaining
                            declaredNames
                            expectedLevels
                            numParams
                            value
                            offset with
                      | error error =>
                          simp [
                            psKernelSimpleCheckUniformOccurrenceWithFuel,
                            hHead,
                            hType,
                            hValue
                          ] at hSuccess
                      | ok valueUnit =>
                          cases valueUnit
                          have hBody :
                              psKernelSimpleCheckUniformOccurrenceWithFuel
                                  remaining
                                  declaredNames
                                  expectedLevels
                                  numParams
                                  body
                                  (Nat.succ offset) =
                                Except.ok Unit.unit := by
                            simpa [
                              psKernelSimpleCheckUniformOccurrenceWithFuel,
                              hHead,
                              hType,
                              hValue
                            ] using hSuccess
                          simp [
                            PsKernelUniformOccurrenceSafe,
                            hHead
                          ]
                          exact
                            ⟨
                              ih type offset hType,
                              ih value offset hValue,
                              ih body (Nat.succ offset) hBody
                            ⟩
              | mdata metadata body =>
                  have hBody :
                      psKernelSimpleCheckUniformOccurrenceWithFuel
                          remaining
                          declaredNames
                          expectedLevels
                          numParams
                          body
                          offset =
                        Except.ok Unit.unit := by
                    simpa [
                      psKernelSimpleCheckUniformOccurrenceWithFuel,
                      hHead
                    ] using hSuccess
                  simpa [
                    PsKernelUniformOccurrenceSafe,
                    hHead
                  ] using ih body offset hBody
              | proj typeName index body =>
                  have hBody :
                      psKernelSimpleCheckUniformOccurrenceWithFuel
                          remaining
                          declaredNames
                          expectedLevels
                          numParams
                          body
                          offset =
                        Except.ok Unit.unit := by
                    simpa [
                      psKernelSimpleCheckUniformOccurrenceWithFuel,
                      hHead
                    ] using hSuccess
                  simpa [
                    PsKernelUniformOccurrenceSafe,
                    hHead
                  ] using ih body offset hBody
              | bvar index =>
                  simp [
                    PsKernelUniformOccurrenceSafe,
                    hHead
                  ]
              | fvar name =>
                  simp [
                    PsKernelUniformOccurrenceSafe,
                    hHead
                  ]
              | mvar name =>
                  simp [
                    PsKernelUniformOccurrenceSafe,
                    hHead
                  ]
              | sort level =>
                  simp [
                    PsKernelUniformOccurrenceSafe,
                    hHead
                  ]
              | const name levels =>
                  simp [
                    PsKernelUniformOccurrenceSafe,
                    hHead
                  ]
              | lit literal =>
                  simp [
                    PsKernelUniformOccurrenceSafe,
                    hHead
                  ]

theorem psKernelSimpleCheckUniformOccurrence_success_refines
    (declaredNames : List PsKernelName)
    (expectedLevels : List PsKernelLevel)
    (numParams : Nat)
    (expr : PsKernelExpr)
    (offset : Nat)
    (hSuccess :
      psKernelSimpleCheckUniformOccurrence
          declaredNames
          expectedLevels
          numParams
          expr
          offset =
        Except.ok Unit.unit) :
    PsKernelUniformOccurrenceSafe
      declaredNames
      expectedLevels
      numParams
      expr
      offset := by
  exact
    psKernelSimpleCheckUniformOccurrenceWithFuel_success_refines
      (Nat.succ (psKernelExprNodeCount expr))
      declaredNames
      expectedLevels
      numParams
      expr
      offset
      hSuccess
