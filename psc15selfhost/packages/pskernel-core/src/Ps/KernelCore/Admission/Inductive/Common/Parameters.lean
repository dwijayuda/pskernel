import Ps.KernelCore.Admission.Inductive.Common.Occurrence

def psKernelSessionWithLocal
    (session : PsKernelCheckerSession)
    (userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    Prod PsKernelName PsKernelCheckerSession :=
  let opened :=
    psKernelCheckerContextWithLocal
      session.context
      userName
      type
      binderInfo;
  let nextSession :=
    PsKernelCheckerSession.mk
      (Prod.snd opened)
      session.state;
  Prod.mk
    (Prod.fst opened)
    nextSession

def psKernelReverseOpenBindersWorker
    (values : List PsKernelOpenBinder) :
    List PsKernelOpenBinder -> List PsKernelOpenBinder :=
  match values with
  | List.nil =>
      fun
        (acc : List PsKernelOpenBinder) =>
        acc
  | List.cons head tail =>
      let smaller :
          List PsKernelOpenBinder ->
          List PsKernelOpenBinder :=
        psKernelReverseOpenBindersWorker tail;
      fun
        (acc : List PsKernelOpenBinder) =>
        smaller
          (List.cons head acc)

def psKernelReverseOpenBinders
    (values : List PsKernelOpenBinder) :
    List PsKernelOpenBinder :=
  psKernelReverseOpenBindersWorker
    values
    List.nil

def psKernelOpenBindersResult
    (session : PsKernelCheckerSession)
    (revBinders : List PsKernelOpenBinder)
    (result : PsKernelExpr) :
    Except String PsKernelOpenBindersResult :=
  Except.ok
    (PsKernelOpenBindersResult.mk
      session
      (psKernelReverseOpenBinders revBinders)
      result)

def psKernelFinishOpenBindersWithWhnf
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (type : PsKernelExpr)
    (revBinders : List PsKernelOpenBinder) :
    Except String PsKernelOpenBindersResult :=
  match
      psKernelSessionWhnf
        fuel
        session
        type with
  | Except.error error =>
      Except.error error
  | Except.ok reduced =>
      psKernelOpenBindersResult
        (Prod.snd reduced)
        revBinders
        (Prod.fst reduced)

def psKernelOpenSimpleHeaderParamStep
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (type : PsKernelExpr) :
    Except String
      (Prod
        (Prod PsKernelCheckerSession PsKernelOpenBinder)
        PsKernelExpr) :=
  match
      psKernelSessionWhnf
        fuel
        session
        type with
  | Except.error error =>
      Except.error error
  | Except.ok reduced =>
      match Prod.fst reduced with
      | PsKernelExpr.forallE userName domain body binderInfo =>
          match
              psKernelSessionCheck
                fuel
                (Prod.snd reduced)
                domain with
          | Except.error error =>
              Except.error error
          | Except.ok domainType =>
              match
                  psKernelSessionEnsureSort
                    fuel
                    (Prod.snd domainType)
                    (Prod.fst domainType) with
              | Except.error error =>
                  Except.error error
              | Except.ok sortResult =>
                  let localDomain :=
                    psKernelExprConsumeTypeAnnotations
                      domain;
                  let localResult :=
                    psKernelSessionWithLocal
                      (Prod.snd sortResult)
                      userName
                      localDomain
                      binderInfo;
                  let fresh :=
                    Prod.fst localResult;
                  let binder :=
                    PsKernelOpenBinder.mk
                      fresh
                      userName
                      localDomain
                      binderInfo;
                  Except.ok
                    (Prod.mk
                      (Prod.mk
                        (Prod.snd localResult)
                        binder)
                      (psKernelExprInstantiate1
                        body
                        (PsKernelExpr.fvar fresh)))
      | _ =>
          Except.error
            "simple inductive declaration has fewer parameters than declared"

def psKernelOpenSimpleHeaderParamsWorker
    (remainingParams : Nat) :
    Nat ->
    PsKernelCheckerSession ->
    PsKernelExpr ->
    List PsKernelOpenBinder ->
    Except String PsKernelOpenBindersResult :=
  match remainingParams with
  | Nat.zero =>
      fun
        (fuel : Nat)
        (session : PsKernelCheckerSession)
        (type : PsKernelExpr)
        (revParams : List PsKernelOpenBinder) =>
        psKernelFinishOpenBindersWithWhnf
          fuel
          session
          type
          revParams
  | Nat.succ remaining =>
      let smaller :
          Nat ->
          PsKernelCheckerSession ->
          PsKernelExpr ->
          List PsKernelOpenBinder ->
          Except String PsKernelOpenBindersResult :=
        psKernelOpenSimpleHeaderParamsWorker remaining;
      fun
        (fuel : Nat)
        (session : PsKernelCheckerSession)
        (type : PsKernelExpr)
        (revParams : List PsKernelOpenBinder) =>
        match
            psKernelOpenSimpleHeaderParamStep
              fuel
              session
              type with
        | Except.error error =>
            Except.error error
        | Except.ok step =>
            let pair :=
              Prod.fst step;
            let nextSession :=
              Prod.fst pair;
            let binder :=
              Prod.snd pair;
            let nextType :=
              Prod.snd step;
            smaller
              fuel
              nextSession
              nextType
              (List.cons binder revParams)

def psKernelOpenSimpleHeaderParams
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (type : PsKernelExpr)
    (numParams : Nat) :
    Except String PsKernelOpenBindersResult :=
  psKernelOpenSimpleHeaderParamsWorker
    numParams
    fuel
    session
    type
    List.nil

def psKernelOpenSimpleHeaderIndicesWithFuel
    (fuel : Nat) :
    PsKernelCheckerSession ->
    PsKernelExpr ->
    List PsKernelOpenBinder ->
    Except String PsKernelOpenBindersResult :=
  match fuel with
  | Nat.zero =>
      fun
        (_session : PsKernelCheckerSession)
        (_type : PsKernelExpr)
        (_revIndices : List PsKernelOpenBinder) =>
        Except.error
          "simple inductive index budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelOpenSimpleHeaderIndicesWithFuel remaining;
      fun
        (session : PsKernelCheckerSession)
        (type : PsKernelExpr)
        (revIndices : List PsKernelOpenBinder) =>
        match
            psKernelSessionWhnf
              remaining
              session
              type with
        | Except.error error =>
            Except.error error
        | Except.ok reduced =>
            let current :=
              Prod.fst reduced;
            match current with
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
                    | Except.ok sortResult =>
                        let localDomain :=
                          psKernelExprConsumeTypeAnnotations
                            domain;
                        let localResult :=
                          psKernelSessionWithLocal
                            (Prod.snd sortResult)
                            userName
                            localDomain
                            binderInfo;
                        let fresh :=
                          Prod.fst localResult;
                        let binder :=
                          PsKernelOpenBinder.mk
                            fresh
                            userName
                            localDomain
                            binderInfo;
                        smaller
                          (Prod.snd localResult)
                          (psKernelExprInstantiate1
                            body
                            (PsKernelExpr.fvar fresh))
                          (List.cons binder revIndices)
            | _ =>
                psKernelOpenBindersResult
                  (Prod.snd reduced)
                  revIndices
                  current

def psKernelOpenSimpleHeaderIndices
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (type : PsKernelExpr) :
    Except String PsKernelOpenBindersResult :=
  psKernelOpenSimpleHeaderIndicesWithFuel
    (Nat.succ fuel)
    session
    type
    List.nil
