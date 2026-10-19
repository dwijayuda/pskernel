import Ps.KernelCore.Admission.Inductive.Common.RecursorValidation

/-
Lean 4.34 inductive elimination restrictions.

This module decides whether an inductive may eliminate into larger universes
and identifies the reflexive/K target. The checks are kept separate from
constructor positivity and recursor construction so the trusted policy is easy
to audit.
-/

def psKernelSimpleExprMember
    (needle : PsKernelExpr)
    (values : List PsKernelExpr) :
    Bool :=
  match values with
  | List.nil =>
      false
  | List.cons item rest =>
      if psKernelExprEq needle item then
        true
      else
        psKernelSimpleExprMember
          needle
          rest

def psKernelSimpleAllExprsMember
    (values : List PsKernelExpr)
    (haystack : List PsKernelExpr) :
    Bool :=
  match values with
  | List.nil =>
      true
  | List.cons item rest =>
      if psKernelSimpleExprMember item haystack then
        psKernelSimpleAllExprsMember
          rest
          haystack
      else
        false

def psKernelSimpleCtorAllowsLargeElimWithFuel
    (fuel : Nat) :
    PsKernelCheckerSession ->
    PsKernelExpr ->
    List PsKernelExpr ->
    Except String Bool :=
  match fuel with
  | Nat.zero =>
      fun
        (_session : PsKernelCheckerSession)
        (_type : PsKernelExpr)
        (_revNonProp : List PsKernelExpr) =>
        Except.error
          "simple inductive elimination budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelSimpleCtorAllowsLargeElimWithFuel remaining;
      fun
        (session : PsKernelCheckerSession)
        (type : PsKernelExpr)
        (revNonProp : List PsKernelExpr) =>
        match
            psKernelSessionWhnf
              remaining
              session
              type with
        | Except.error error =>
            Except.error error
        | Except.ok reduced =>
            match Prod.fst reduced with
            | PsKernelExpr.forallE userName domain body binderInfo =>
                match
                    psKernelSessionCheck
                      remaining
                      (Prod.snd reduced)
                      domain with
                | Except.error error =>
                    Except.error error
                | Except.ok domainType =>
                    match
                        psKernelSessionEnsureSort
                          remaining
                          (Prod.snd domainType)
                          (Prod.fst domainType) with
                    | Except.error error =>
                        Except.error error
                    | Except.ok fieldLevel =>
                        let localDomain :=
                          psKernelExprConsumeTypeAnnotations
                            domain;
                        let localResult :=
                          psKernelSessionWithLocal
                            (Prod.snd fieldLevel)
                            userName
                            localDomain
                            binderInfo;
                        let fresh :=
                          Prod.fst localResult;
                        let nextNonProp :=
                          if
                              psKernelLevelNormalizesToZero
                                (Prod.fst fieldLevel) then
                            revNonProp
                          else
                            List.cons
                              (PsKernelExpr.fvar fresh)
                              revNonProp;
                        smaller
                          (Prod.snd localResult)
                          (psKernelExprInstantiate1
                            body
                            (PsKernelExpr.fvar fresh))
                          nextNonProp
            | _ =>
                let resultArgs :=
                  psKernelExprGetAppArgs
                    (Prod.fst reduced);
                Except.ok
                  (psKernelSimpleAllExprsMember
                    revNonProp
                    resultArgs)

def psKernelSimpleCtorAllowsLargeElim
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (params : List PsKernelOpenBinder)
    (type : PsKernelExpr) :
    Except String Bool :=
  match
      psKernelOpenSimpleConstructorParams
        fuel
        session
        params
        type with
  | Except.error error =>
      Except.error error
  | Except.ok afterParams =>
      psKernelSimpleCtorAllowsLargeElimWithFuel
        (Nat.succ fuel)
        afterParams.session
        afterParams.result
        List.nil

def psKernelSimpleElimOnlyAtZero
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (params : List PsKernelOpenBinder)
    (resultLevel : PsKernelLevel)
    (ctors : List PsKernelSimpleConstructorDecl) :
    Except String Bool :=
  if psKernelLevelIsNotZero resultLevel then
    Except.ok false
  else
    match ctors with
    | List.nil =>
        Except.ok false
    | List.cons ctor rest =>
        match rest with
        | List.nil =>
            match
                psKernelSimpleCtorAllowsLargeElim
                  fuel
                  session
                  params
                  ctor.type with
            | Except.error error =>
                Except.error error
            | Except.ok canLarge =>
                if canLarge then
                  Except.ok false
                else
                  Except.ok true
        | List.cons _ _ =>
            Except.ok true

def psKernelSimpleKTarget
    (resultLevel : PsKernelLevel)
    (shapes : List PsKernelSimpleConstructorShape) :
    Bool :=
  if psKernelLevelNormalizesToZero resultLevel then
    match shapes with
    | List.cons shape rest =>
        match rest with
        | List.nil =>
            match shape.fields with
            | List.nil => true
            | List.cons _ _ => false
        | List.cons _ _ => false
    | List.nil => false
  else
    false
