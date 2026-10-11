import Ps.KernelCore.Admission.Inductive.Types

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
    Except String Bool :=
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
                  Except.ok true
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
          Except.ok false
      else
        Except.ok false
  | _ =>
      Except.ok false

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
            Except String Bool :=
          psKernelSimpleCheckUniformOccurrenceHead
            declaredNames
            expectedLevels
            numParams
            expr
            offset;
        match checkHead with
        | Except.error error =>
            Except.error error
        | Except.ok stop =>
            if stop then
              Except.ok ()
            else
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

