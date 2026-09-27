import Ps.KernelCore.Inductive

def psKernelCoreRecursorMajorIndex
    (info : PsKernelCoreRecursorInfo) : Nat :=
  Nat.add
    (Nat.add
      (Nat.add info.numParams info.numMotives)
      info.numMinors)
    info.numIndices

def psKernelCoreFindRecursorRule?
    (ctor : PsKernelCoreName)
    (rules : PsKernelCoreList PsKernelCoreRecursorRule) :
    PsKernelCoreOption PsKernelCoreRecursorRule :=
  match rules with
  | PsKernelCoreList.nil => PsKernelCoreOption.none
  | PsKernelCoreList.cons rule rest =>
      if psKernelCoreNameEq ctor rule.ctor then
        PsKernelCoreOption.some rule
      else
        psKernelCoreFindRecursorRule? ctor rest

def psKernelCoreRecursorNameListLength
    (names : PsKernelCoreList PsKernelCoreName) : Nat :=
  match names with
  | PsKernelCoreList.nil => 0
  | PsKernelCoreList.cons _ rest =>
      Nat.succ (psKernelCoreRecursorNameListLength rest)

def psKernelCoreRecursorRuleListLength
    (rules : PsKernelCoreList PsKernelCoreRecursorRule) : Nat :=
  match rules with
  | PsKernelCoreList.nil => 0
  | PsKernelCoreList.cons _ rest =>
      Nat.succ (psKernelCoreRecursorRuleListLength rest)

def psKernelCoreRecursorTarget?
    (info : PsKernelCoreRecursorInfo) :
    PsKernelCoreOption PsKernelCoreName :=
  match info.all with
  | PsKernelCoreList.nil => PsKernelCoreOption.none
  | PsKernelCoreList.cons target rest =>
      match rest with
      | PsKernelCoreList.nil => PsKernelCoreOption.some target
      | PsKernelCoreList.cons _ _ => PsKernelCoreOption.none

def psKernelCoreRecursorResultArgsMatch
    (args : PsKernelCoreList PsKernelCoreExpr) : Nat -> Bool :=
  match args with
  | PsKernelCoreList.nil =>
      fun (_remainingIndices : Nat) => false
  | PsKernelCoreList.cons head rest =>
      fun (remainingIndices : Nat) =>
        match remainingIndices with
        | Nat.zero =>
            match head with
            | PsKernelCoreExpr.bvar index =>
                if Nat.beq index 0 then
                  match rest with
                  | PsKernelCoreList.nil => true
                  | PsKernelCoreList.cons _ _ => false
                else
                  false
            | _ => false
        | Nat.succ previous =>
            match head with
            | PsKernelCoreExpr.bvar index =>
                if Nat.beq index (Nat.succ previous) then
                  psKernelCoreRecursorResultArgsMatch rest previous
                else
                  false
            | _ => false

def psKernelCoreRecursorCanonicalTypeShapeValid
    (info : PsKernelCoreRecursorInfo) : Bool :=
  let summary := psKernelCoreInductiveSummarizeTelescope info.base.type;
  let expectedBinders :=
    Nat.add
      (Nat.add
        (Nat.add
          (Nat.add info.numParams info.numMotives)
          info.numMinors)
        info.numIndices)
      1;
  if Nat.beq summary.binderCount expectedBinders then
    let head := psKernelCoreExprAppHead summary.result;
    let args := psKernelCoreExprAppArgs summary.result;
    let expectedMotiveIndex :=
      Nat.add (Nat.add info.numMinors info.numIndices) 1;
    match head with
    | PsKernelCoreExpr.bvar motiveIndex =>
        if Nat.beq motiveIndex expectedMotiveIndex then
          psKernelCoreRecursorResultArgsMatch args info.numIndices
        else
          false
    | _ => false
  else
    false

def psKernelCoreRecursorDropForalls
    (expr : PsKernelCoreExpr) : Nat -> PsKernelCoreOption PsKernelCoreExpr :=
  match expr with
  | PsKernelCoreExpr.forallE _ _ body _ =>
      let dropBody := psKernelCoreRecursorDropForalls body;
      fun (count : Nat) =>
        match count with
        | Nat.zero => PsKernelCoreOption.some expr
        | Nat.succ remaining => dropBody remaining
  | _ =>
      fun (count : Nat) =>
        match count with
        | Nat.zero => PsKernelCoreOption.some expr
        | Nat.succ _ => PsKernelCoreOption.none

def psKernelCoreRecursorForallDomainAt
    (expr : PsKernelCoreExpr) : Nat -> PsKernelCoreOption PsKernelCoreExpr :=
  match expr with
  | PsKernelCoreExpr.forallE _ domain body _ =>
      let findBody := psKernelCoreRecursorForallDomainAt body;
      fun (index : Nat) =>
        match index with
        | Nat.zero => PsKernelCoreOption.some domain
        | Nat.succ previous => findBody previous
  | _ =>
      fun (_index : Nat) => PsKernelCoreOption.none

def psKernelCoreRecursorClosePrefix
    (expr : PsKernelCoreExpr) :
    Nat -> PsKernelCoreExpr -> PsKernelCoreOption PsKernelCoreExpr :=
  match expr with
  | PsKernelCoreExpr.forallE name domain body binderInfo =>
      let closeBody := psKernelCoreRecursorClosePrefix body;
      fun (count : Nat) (result : PsKernelCoreExpr) =>
        match count with
        | Nat.zero => PsKernelCoreOption.some result
        | Nat.succ remaining =>
            match closeBody remaining result with
            | PsKernelCoreOption.none => PsKernelCoreOption.none
            | PsKernelCoreOption.some closedBody =>
                PsKernelCoreOption.some
                  (PsKernelCoreExpr.forallE name domain closedBody binderInfo)
  | _ =>
      fun (count : Nat) (result : PsKernelCoreExpr) =>
        match count with
        | Nat.zero => PsKernelCoreOption.some result
        | Nat.succ _ => PsKernelCoreOption.none

def psKernelCoreRecursorExpectedRuleType?
    (info : PsKernelCoreRecursorInfo)
    (ruleIndex : Nat) : PsKernelCoreOption PsKernelCoreExpr :=
  let beforeMinors := Nat.add info.numParams info.numMotives;
  match psKernelCoreRecursorDropForalls info.base.type beforeMinors with
  | PsKernelCoreOption.none => PsKernelCoreOption.none
  | PsKernelCoreOption.some minorTelescope =>
      match psKernelCoreRecursorForallDomainAt minorTelescope ruleIndex with
      | PsKernelCoreOption.none => PsKernelCoreOption.none
      | PsKernelCoreOption.some minorDomain =>
          let remainingMinors := Nat.sub info.numMinors ruleIndex;
          let liftedMinor :=
            psKernelCoreExprLiftBVars minorDomain 0 remainingMinors;
          let fixedCount :=
            Nat.add
              (Nat.add info.numParams info.numMotives)
              info.numMinors;
          psKernelCoreRecursorClosePrefix
            info.base.type fixedCount liftedMinor

def psKernelCoreRecursorValidateRuleRhsWithResources
    (budget : Nat)
    (resources : PsKernelCoreResourceConfig)
    (env : PsKernelCoreEnvironment)
    (info : PsKernelCoreRecursorInfo)
    (ruleIndex : Nat)
    (rule : PsKernelCoreRecursorRule) :
    PsKernelCoreResult String Unit :=
  match psKernelCoreAdmissionCheckClosed rule.rhs with
  | PsKernelCoreResult.error message => PsKernelCoreResult.error message
  | PsKernelCoreResult.ok _ =>
      match psKernelCoreAdmissionCheckLevelParams
          rule.rhs info.base.levelParams with
      | PsKernelCoreResult.error message => PsKernelCoreResult.error message
      | PsKernelCoreResult.ok _ =>
          let safety :=
            if info.isUnsafe then
              PsKernelCoreDefinitionSafety.unsafeDef
            else
              PsKernelCoreDefinitionSafety.safe;
          match psKernelCoreCheckWithResources
              budget resources env psKernelCoreLocalContextEmpty
              safety rule.rhs with
          | PsKernelCoreResult.error message =>
              PsKernelCoreResult.error message
          | PsKernelCoreResult.ok ruleType =>
              match psKernelCoreRecursorExpectedRuleType? info ruleIndex with
              | PsKernelCoreOption.none =>
                  PsKernelCoreResult.error "invalid recursor minor telescope"
              | PsKernelCoreOption.some expectedType =>
                  match psKernelCoreIsDefEqWithResources
                      budget resources env psKernelCoreLocalContextEmpty
                      ruleType expectedType with
                  | PsKernelCoreResult.error message =>
                      PsKernelCoreResult.error message
                  | PsKernelCoreResult.ok equal =>
                      if equal then
                        PsKernelCoreResult.ok Unit.unit
                      else
                        PsKernelCoreResult.error
                          "recursor rule type does not match branch"

def psKernelCoreRecursorValidateRulesWithResources
    (ctorNames : PsKernelCoreList PsKernelCoreName) :
    PsKernelCoreList PsKernelCoreRecursorRule ->
    Nat ->
    Nat ->
    PsKernelCoreResourceConfig ->
    PsKernelCoreEnvironment ->
    PsKernelCoreRecursorInfo ->
    PsKernelCoreInductiveInfo ->
    PsKernelCoreResult String Unit :=
  match ctorNames with
  | PsKernelCoreList.nil =>
      fun (rules : PsKernelCoreList PsKernelCoreRecursorRule)
          (_index : Nat)
          (_budget : Nat)
          (_resources : PsKernelCoreResourceConfig)
          (_env : PsKernelCoreEnvironment)
          (_info : PsKernelCoreRecursorInfo)
          (_family : PsKernelCoreInductiveInfo) =>
        match rules with
        | PsKernelCoreList.nil => PsKernelCoreResult.ok Unit.unit
        | PsKernelCoreList.cons _ _ =>
            PsKernelCoreResult.error "recursor rule count does not match constructors"
  | PsKernelCoreList.cons ctorName ctorRest =>
      let validateRest := psKernelCoreRecursorValidateRulesWithResources ctorRest;
      fun (rules : PsKernelCoreList PsKernelCoreRecursorRule)
          (index : Nat)
          (budget : Nat)
          (resources : PsKernelCoreResourceConfig)
          (env : PsKernelCoreEnvironment)
          (info : PsKernelCoreRecursorInfo)
          (family : PsKernelCoreInductiveInfo) =>
        match rules with
        | PsKernelCoreList.nil =>
            PsKernelCoreResult.error "recursor rule count does not match constructors"
        | PsKernelCoreList.cons rule ruleRest =>
            if psKernelCoreNameEq rule.ctor ctorName then
              match psKernelCoreEnvironmentFind? env ctorName with
              | PsKernelCoreOption.none =>
                  PsKernelCoreResult.error "recursor constructor is not declared"
              | PsKernelCoreOption.some ctorConstant =>
                  match ctorConstant with
                  | PsKernelCoreConstantInfo.ctorInfo ctor =>
                      if psKernelCoreNameEq ctor.induct family.base.name then
                        if Nat.beq ctor.cidx index then
                          if Nat.beq ctor.numParams family.numParams then
                            if Nat.beq rule.nFields ctor.numFields then
                              if psKernelCoreBoolEq ctor.isUnsafe family.isUnsafe then
                                match psKernelCoreRecursorValidateRuleRhsWithResources
                                    budget resources env info index rule with
                                | PsKernelCoreResult.error message =>
                                    PsKernelCoreResult.error message
                                | PsKernelCoreResult.ok _ =>
                                    validateRest ruleRest (Nat.succ index)
                                      budget resources env info family
                              else
                                PsKernelCoreResult.error
                                  "recursor constructor safety does not match inductive"
                            else
                              PsKernelCoreResult.error
                                "recursor rule field count does not match constructor"
                          else
                            PsKernelCoreResult.error
                              "recursor constructor parameter count does not match inductive"
                        else
                          PsKernelCoreResult.error
                            "recursor constructor index does not match order"
                      else
                        PsKernelCoreResult.error
                          "recursor constructor belongs to another inductive"
                  | _ =>
                      PsKernelCoreResult.error
                        "recursor constructor metadata is not a constructor"
            else
              PsKernelCoreResult.error "recursor rule order does not match constructors"

def psKernelCoreValidateRecursorWithResources
    (budget : Nat)
    (resources : PsKernelCoreResourceConfig)
    (env : PsKernelCoreEnvironment)
    (info : PsKernelCoreRecursorInfo) :
    PsKernelCoreResult String Unit :=
  match budget with
  | Nat.zero => PsKernelCoreResult.error "admission budget exhausted"
  | Nat.succ remaining =>
      match psKernelCoreRecursorTarget? info with
      | PsKernelCoreOption.none =>
          PsKernelCoreResult.error "recursor must target exactly one inductive"
      | PsKernelCoreOption.some target =>
          match psKernelCoreEnvironmentFind? env target with
          | PsKernelCoreOption.none =>
              PsKernelCoreResult.error "recursor target inductive is not declared"
          | PsKernelCoreOption.some targetConstant =>
              match targetConstant with
              | PsKernelCoreConstantInfo.inductInfo family =>
                  if psKernelCoreNameEq family.base.name target then
                    if psKernelCoreInductiveSingleFamilyMetadataValid family then
                      if Nat.beq info.numParams family.numParams then
                        if Nat.beq info.numIndices family.numIndices then
                          if Nat.beq info.numMotives 1 then
                            let ctorCount :=
                              psKernelCoreRecursorNameListLength family.ctors;
                            if Nat.beq info.numMinors ctorCount then
                              if Nat.beq
                                  (psKernelCoreRecursorRuleListLength info.rules)
                                  ctorCount then
                                if info.k then
                                  PsKernelCoreResult.error
                                    "K recursors are not supported in this phase"
                                else if psKernelCoreBoolEq info.isUnsafe family.isUnsafe then
                                  if psKernelCoreRecursorCanonicalTypeShapeValid info then
                                    let safety :=
                                      if info.isUnsafe then
                                        PsKernelCoreDefinitionSafety.unsafeDef
                                      else
                                        PsKernelCoreDefinitionSafety.safe;
                                    match psKernelCoreAdmissionCheckBaseWithResources
                                        remaining resources env info.base safety with
                                    | PsKernelCoreResult.error message =>
                                        PsKernelCoreResult.error message
                                    | PsKernelCoreResult.ok _ =>
                                        psKernelCoreRecursorValidateRulesWithResources
                                          family.ctors info.rules 0 remaining resources
                                          env info family
                                  else
                                    PsKernelCoreResult.error
                                      "invalid recursor type shape"
                                else
                                  PsKernelCoreResult.error
                                    "recursor safety does not match inductive"
                              else
                                PsKernelCoreResult.error
                                  "recursor rule count does not match constructors"
                            else
                              PsKernelCoreResult.error
                                "recursor minor count does not match constructors"
                          else
                            PsKernelCoreResult.error
                              "recursor must have exactly one motive"
                        else
                          PsKernelCoreResult.error
                            "recursor index count does not match inductive"
                      else
                        PsKernelCoreResult.error
                          "recursor parameter count does not match inductive"
                    else
                      PsKernelCoreResult.error "unsupported recursor target inductive"
                  else
                    PsKernelCoreResult.error "recursor target metadata name mismatch"
              | _ =>
                  PsKernelCoreResult.error "recursor target is not an inductive"

def psKernelCoreAddRecursorWithResources
    (budget : Nat)
    (resources : PsKernelCoreResourceConfig)
    (env : PsKernelCoreEnvironment)
    (info : PsKernelCoreRecursorInfo) :
    PsKernelCoreResult String PsKernelCoreEnvironment :=
  match psKernelCoreValidateRecursorWithResources budget resources env info with
  | PsKernelCoreResult.error message => PsKernelCoreResult.error message
  | PsKernelCoreResult.ok _ =>
      PsKernelCoreResult.ok
        (psKernelCoreEnvironmentAddUnchecked
          env (PsKernelCoreConstantInfo.recInfo info))

def psKernelCoreAddRecursor
    (budget : Nat)
    (env : PsKernelCoreEnvironment)
    (info : PsKernelCoreRecursorInfo) :
    PsKernelCoreResult String PsKernelCoreEnvironment :=
  psKernelCoreAddRecursorWithResources
    budget psKernelCoreResourceConfigDefault env info
