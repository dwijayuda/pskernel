import Ps.KernelSelfHost.Quot

structure PsKernelSimpleConstructorDecl where
  name : PsKernelName
  type : PsKernelExpr

structure PsKernelSimpleInductiveDecl where
  levelParams : List PsKernelName
  name : PsKernelName
  type : PsKernelExpr
  ctors : List PsKernelSimpleConstructorDecl
  isUnsafe : Bool
  numParams : Nat

structure PsKernelSimpleRecursiveField where
  field : PsKernelOpenBinder
  args : List PsKernelOpenBinder
  indices : List PsKernelExpr

structure PsKernelSimpleConstructorShape where
  ctor : PsKernelSimpleConstructorDecl
  fields : List PsKernelOpenBinder
  recursiveFields : List PsKernelSimpleRecursiveField
  resultIndices : List PsKernelExpr

structure PsKernelOpenBindersResult where
  session : PsKernelCheckerSession
  binders : List PsKernelOpenBinder
  result : PsKernelExpr

structure PsKernelOpenBinderStepResult where
  session : PsKernelCheckerSession
  binder : PsKernelOpenBinder
  result : PsKernelExpr

structure PsKernelRecursiveArgumentResult where
  session : PsKernelCheckerSession
  recursiveInfo : Option (Prod (List PsKernelOpenBinder) (List PsKernelExpr))

structure PsKernelOpenFieldsResult where
  session : PsKernelCheckerSession
  fields : List PsKernelOpenBinder
  recursiveFields : List PsKernelSimpleRecursiveField
  result : PsKernelExpr

def psKernelSimpleRecName
    (name : PsKernelName) : PsKernelName :=
  PsKernelName.str
    name
    "rec"

def psKernelSimpleInternalName
    (field : String) : PsKernelName :=
  PsKernelName.str
    (PsKernelName.str
      PsKernelName.anonymous
      "_psc1SimpleInd")
    field

def psKernelCloseOpenLambdas
    (binders : List PsKernelOpenBinder) :
    PsKernelExpr -> PsKernelExpr :=
  match binders with
  | List.nil =>
      fun (body : PsKernelExpr) =>
        body
  | List.cons binder rest =>
      let smaller :
          PsKernelExpr -> PsKernelExpr :=
        psKernelCloseOpenLambdas rest;
      fun (body : PsKernelExpr) =>
        let inner :=
          smaller body;
        PsKernelExpr.lam
          binder.userName
          binder.type
          (psKernelExprAbstractFVars
            inner
            (List.cons
              binder.internalName
              List.nil))
          binder.binderInfo

def psKernelSimpleNameListUnique
    (names : List PsKernelName) : Bool :=
  if psKernelNameHasDuplicates names then
    false
  else
    true

def psKernelSimpleElimNameCandidate
    (value : Nat) : PsKernelName :=
  match value with
  | Nat.zero =>
      PsKernelName.str
        PsKernelName.anonymous
        "u"
  | Nat.succ _ =>
      PsKernelName.str
        PsKernelName.anonymous
        (String.Internal.append
          "u_"
          (psKernelNatToString value))

def psKernelSimpleFreshElimNameAux
    (fuel : Nat) :
    List PsKernelName -> Nat -> PsKernelName :=
  match fuel with
  | Nat.zero =>
      fun
        (_levelParams : List PsKernelName)
        (candidate : Nat) =>
        psKernelSimpleElimNameCandidate candidate
  | Nat.succ remaining =>
      let smaller :
          List PsKernelName -> Nat -> PsKernelName :=
        psKernelSimpleFreshElimNameAux remaining;
      fun
        (levelParams : List PsKernelName)
        (candidate : Nat) =>
        let name :=
          psKernelSimpleElimNameCandidate candidate;
        if psKernelNameMember name levelParams then
          smaller
            levelParams
            (Nat.succ candidate)
        else
          name

def psKernelSimpleFreshElimName
    (levelParams : List PsKernelName) :
    PsKernelName :=
  psKernelSimpleFreshElimNameAux
    (Nat.succ (psKernelNameListLength levelParams))
    levelParams
    0

def psKernelSimpleDeclaredNameMember
    (name : PsKernelName)
    (names : List PsKernelName) : Bool :=
  psKernelNameMember name names

def psKernelLevelParamsToLevels
    (names : List PsKernelName) :
    List PsKernelLevel :=
  match names with
  | List.nil =>
      List.nil
  | List.cons name rest =>
      List.cons
        (PsKernelLevel.param name)
        (psKernelLevelParamsToLevels rest)

def psKernelOpenBinderExprs
    (binders : List PsKernelOpenBinder) :
    List PsKernelExpr :=
  match binders with
  | List.nil =>
      List.nil
  | List.cons binder rest =>
      List.cons
        (PsKernelExpr.fvar binder.internalName)
        (psKernelOpenBinderExprs rest)

def psKernelSimpleUniformParamArgsMatchWorker
    (args : List PsKernelExpr) :
    Nat -> Nat -> Bool :=
  match args with
  | List.nil =>
      fun
        (_offset : Nat)
        (_index : Nat) =>
        true
  | List.cons arg rest =>
      let smaller :
          Nat -> Nat -> Bool :=
        psKernelSimpleUniformParamArgsMatchWorker rest;
      fun
        (offset : Nat)
        (index : Nat) =>
        match arg with
        | PsKernelExpr.bvar bvarIndex =>
            let expected :=
              Nat.sub
                (Nat.sub offset 1)
                index;
            if Nat.beq bvarIndex expected then
              smaller
                offset
                (Nat.succ index)
            else
              false
        | _ =>
            false

def psKernelSimpleUniformParamArgsMatch
    (offset : Nat)
    (args : List PsKernelExpr)
    (index : Nat) : Bool :=
  psKernelSimpleUniformParamArgsMatchWorker
    args
    offset
    index

def psKernelSimpleCheckUniformOccurrenceHead
    (declaredNames : List PsKernelName)
    (expectedLevels : List PsKernelLevel)
    (numParams : Nat)
    (expr : PsKernelExpr)
    (offset : Nat) :
    Except String Unit :=
  match psKernelExprGetAppFn expr with
  | PsKernelExpr.const name levels =>
      let args :=
        psKernelExprGetAppArgs expr;
      let declared :=
        psKernelSimpleDeclaredNameMember
          name
          declaredNames;
      let shortEnough :=
        Nat.ble
          (psKernelExprListLength args)
          numParams;
      if declared then
        if shortEnough then
          let enoughOffset :=
            psKernelNatGe offset numParams;
          let fullParams :=
            Nat.beq
              (psKernelExprListLength args)
              numParams;
          let levelsOk :=
            psKernelLevelListEq
              levels
              expectedLevels;
          let argsOk :=
            psKernelSimpleUniformParamArgsMatch
              offset
              args
              0;
          if enoughOffset then
            if fullParams then
              if levelsOk then
                if argsOk then
                  Except.ok ()
                else
                  Except.error
                    "invalid occurrence of datatype being declared: it must be applied to the parameters and universe levels of the mutual declaration"
              else
                Except.error
                  "invalid occurrence of datatype being declared: it must be applied to the parameters and universe levels of the mutual declaration"
            else
              Except.error
                "invalid occurrence of datatype being declared: it must be applied to the parameters and universe levels of the mutual declaration"
          else
            Except.error
              "invalid occurrence of datatype being declared: it must be applied to the parameters and universe levels of the mutual declaration"
        else
          Except.ok ()
      else
        Except.ok ()
  | _ =>
      Except.ok ()

def psKernelSimpleCheckUniformOccurrenceWithFuel
    (fuel : Nat) :
    List PsKernelName ->
    List PsKernelLevel ->
    Nat ->
    PsKernelExpr ->
    Nat ->
    Except String Unit :=
  match fuel with
  | Nat.zero =>
      fun
        (_declaredNames : List PsKernelName)
        (_expectedLevels : List PsKernelLevel)
        (_numParams : Nat)
        (_expr : PsKernelExpr)
        (_offset : Nat) =>
        Except.error
          "simple inductive uniform-occurrence budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelSimpleCheckUniformOccurrenceWithFuel remaining;
      fun
        (declaredNames : List PsKernelName)
        (expectedLevels : List PsKernelLevel)
        (numParams : Nat)
        (expr : PsKernelExpr)
        (offset : Nat) =>
        let checkHead :
            Except String Unit :=
          psKernelSimpleCheckUniformOccurrenceHead
            declaredNames
            expectedLevels
            numParams
            expr
            offset;
        match checkHead with
        | Except.error error =>
            Except.error error
        | Except.ok _ =>
            match expr with
            | PsKernelExpr.app fn arg =>
                match
                    smaller
                      declaredNames
                      expectedLevels
                      numParams
                      fn
                      offset with
                | Except.error error =>
                    Except.error error
                | Except.ok _ =>
                    smaller
                      declaredNames
                      expectedLevels
                      numParams
                      arg
                      offset
            | PsKernelExpr.lam _ type body _ =>
                match
                    smaller
                      declaredNames
                      expectedLevels
                      numParams
                      type
                      offset with
                | Except.error error =>
                    Except.error error
                | Except.ok _ =>
                    smaller
                      declaredNames
                      expectedLevels
                      numParams
                      body
                      (Nat.succ offset)
            | PsKernelExpr.forallE _ type body _ =>
                match
                    smaller
                      declaredNames
                      expectedLevels
                      numParams
                      type
                      offset with
                | Except.error error =>
                    Except.error error
                | Except.ok _ =>
                    smaller
                      declaredNames
                      expectedLevels
                      numParams
                      body
                      (Nat.succ offset)
            | PsKernelExpr.letE _ type value body _ =>
                match
                    smaller
                      declaredNames
                      expectedLevels
                      numParams
                      type
                      offset with
                | Except.error error =>
                    Except.error error
                | Except.ok _ =>
                    match
                        smaller
                          declaredNames
                          expectedLevels
                          numParams
                          value
                          offset with
                    | Except.error error =>
                        Except.error error
                    | Except.ok _ =>
                        smaller
                          declaredNames
                          expectedLevels
                          numParams
                          body
                          (Nat.succ offset)
            | PsKernelExpr.mdata _ body =>
                smaller
                  declaredNames
                  expectedLevels
                  numParams
                  body
                  offset
            | PsKernelExpr.proj _ _ body =>
                smaller
                  declaredNames
                  expectedLevels
                  numParams
                  body
                  offset
            | _ =>
                Except.ok ()

def psKernelSimpleCheckUniformOccurrence
    (declaredNames : List PsKernelName)
    (expectedLevels : List PsKernelLevel)
    (numParams : Nat)
    (expr : PsKernelExpr)
    (offset : Nat) :
    Except String Unit :=
  psKernelSimpleCheckUniformOccurrenceWithFuel
    (Nat.succ (psKernelExprNodeCount expr))
    declaredNames
    expectedLevels
    numParams
    expr
    offset

def psKernelSimpleCheckUniformOccurrencesWorker
    (ctorTypes : List PsKernelExpr) :
    List PsKernelName ->
    List PsKernelLevel ->
    Nat ->
    Except String Unit :=
  match ctorTypes with
  | List.nil =>
      fun
        (_declaredNames : List PsKernelName)
        (_expectedLevels : List PsKernelLevel)
        (_numParams : Nat) =>
        Except.ok ()
  | List.cons head tail =>
      let smaller :
          List PsKernelName ->
          List PsKernelLevel ->
          Nat ->
          Except String Unit :=
        psKernelSimpleCheckUniformOccurrencesWorker tail;
      fun
        (declaredNames : List PsKernelName)
        (expectedLevels : List PsKernelLevel)
        (numParams : Nat) =>
        match
            psKernelSimpleCheckUniformOccurrence
              declaredNames
              expectedLevels
              numParams
              head
              0 with
        | Except.error error =>
            Except.error error
        | Except.ok _ =>
            smaller
              declaredNames
              expectedLevels
              numParams

def psKernelSimpleCheckUniformOccurrences
    (declaredNames : List PsKernelName)
    (levelParams : List PsKernelName)
    (numParams : Nat)
    (ctorTypes : List PsKernelExpr) :
    Except String Unit :=
  psKernelSimpleCheckUniformOccurrencesWorker
    ctorTypes
    declaredNames
    (psKernelLevelParamsToLevels levelParams)
    numParams

def psKernelExprContainsConst
    (target : PsKernelName)
    (expr : PsKernelExpr) : Bool :=
  match expr with
  | PsKernelExpr.const name _ =>
      psKernelNameEq name target
  | PsKernelExpr.app fn arg =>
      if psKernelExprContainsConst target fn then
        true
      else
        psKernelExprContainsConst target arg
  | PsKernelExpr.lam _ type body _ =>
      if psKernelExprContainsConst target type then
        true
      else
        psKernelExprContainsConst target body
  | PsKernelExpr.forallE _ type body _ =>
      if psKernelExprContainsConst target type then
        true
      else
        psKernelExprContainsConst target body
  | PsKernelExpr.letE _ type value body _ =>
      if psKernelExprContainsConst target type then
        true
      else if psKernelExprContainsConst target value then
        true
      else
        psKernelExprContainsConst target body
  | PsKernelExpr.mdata _ body =>
      psKernelExprContainsConst target body
  | PsKernelExpr.proj typeName _ body =>
      if psKernelNameEq typeName target then
        true
      else
        psKernelExprContainsConst target body
  | _ =>
      false

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

def psKernelOpenSimpleHeaderParamStep
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (type : PsKernelExpr) :
    Except String PsKernelOpenBinderStepResult :=
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
                    (PsKernelOpenBinderStepResult.mk
                      (Prod.snd localResult)
                      binder
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
        match
            psKernelSessionWhnf
              fuel
              session
              type with
        | Except.error error =>
            Except.error error
        | Except.ok reduced =>
            Except.ok
              (PsKernelOpenBindersResult.mk
                (Prod.snd reduced)
                (List.reverse revParams)
                (Prod.fst reduced))
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
            smaller
              fuel
              step.session
              step.result
              (List.cons step.binder revParams)

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
                Except.ok
                  (PsKernelOpenBindersResult.mk
                    (Prod.snd reduced)
                    (List.reverse revIndices)
                    current)

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
