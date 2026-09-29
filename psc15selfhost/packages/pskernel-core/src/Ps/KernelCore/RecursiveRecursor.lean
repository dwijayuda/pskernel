import Ps.KernelCore.RecursorCanonical
import Ps.KernelCore.RecursiveInductive

structure PsKernelCoreRecursiveRecursorField where
  value : PsKernelCoreExpr
  isRecursive : Bool

structure PsKernelCoreRecursiveRecursorOpenState where
  ctorResult : PsKernelCoreExpr
  minorResult : PsKernelCoreExpr
  fields : PsKernelCoreList PsKernelCoreRecursiveRecursorField
  nextSeed : Nat

def psKernelCoreRecursiveRecursorOpenDirectFields
    (count : Nat) :
    Nat ->
    PsKernelCoreResourceConfig ->
    PsKernelCoreEnvironment ->
    PsKernelCoreInductiveInfo ->
    PsKernelCoreList PsKernelCoreLevel ->
    PsKernelCoreExpr ->
    PsKernelCoreExpr ->
    Nat ->
    Nat ->
    PsKernelCoreResult String PsKernelCoreRecursiveRecursorOpenState :=
  match count with
  | Nat.zero =>
      fun (_budget : Nat)
          (_resources : PsKernelCoreResourceConfig)
          (_env : PsKernelCoreEnvironment)
          (_family : PsKernelCoreInductiveInfo)
          (_levels : PsKernelCoreList PsKernelCoreLevel)
          (ctorExpr : PsKernelCoreExpr)
          (minorExpr : PsKernelCoreExpr)
          (_binderDepth : Nat)
          (seed : Nat) =>
        PsKernelCoreResult.ok {
          ctorResult := ctorExpr
          minorResult := minorExpr
          fields := PsKernelCoreList.nil
          nextSeed := seed
        }
  | Nat.succ remaining =>
      let openRemaining :=
        psKernelCoreRecursiveRecursorOpenDirectFields remaining;
      fun (budget : Nat)
          (resources : PsKernelCoreResourceConfig)
          (env : PsKernelCoreEnvironment)
          (family : PsKernelCoreInductiveInfo)
          (levels : PsKernelCoreList PsKernelCoreLevel)
          (ctorExpr : PsKernelCoreExpr)
          (minorExpr : PsKernelCoreExpr)
          (binderDepth : Nat)
          (seed : Nat) =>
        match ctorExpr with
        | PsKernelCoreExpr.forallE _ ctorDomain ctorBody _ =>
            match minorExpr with
            | PsKernelCoreExpr.forallE _ minorDomain minorBody _ =>
                if psKernelCoreExprEq ctorDomain minorDomain then
                  match psKernelCoreRecursiveFieldShapeWithResources
                      budget resources env family.base.name levels
                      family.numParams family.numIndices binderDepth ctorDomain with
                  | PsKernelCoreResult.error message =>
                      PsKernelCoreResult.error message
                  | PsKernelCoreResult.ok recursiveShape =>
                      let isRecursiveResult : PsKernelCoreResult String Bool :=
                        match recursiveShape with
                        | PsKernelCoreOption.none =>
                            PsKernelCoreResult.ok false
                        | PsKernelCoreOption.some shape =>
                            if Nat.beq shape.argCount 0 then
                              match shape.indices with
                              | PsKernelCoreList.nil =>
                                  PsKernelCoreResult.ok true
                              | PsKernelCoreList.cons _ _ =>
                                  PsKernelCoreResult.error
                                    "indexed recursive field is not supported in direct recursive recursor slice"
                            else
                              PsKernelCoreResult.error
                                "functional recursive field is not supported in direct recursive recursor slice";
                      match isRecursiveResult with
                      | PsKernelCoreResult.error message =>
                          PsKernelCoreResult.error message
                      | PsKernelCoreResult.ok isRecursive =>
                          let fresh := psKernelCoreRecursorFreshFVar seed;
                          let openedCtor :=
                            psKernelCoreExprInstantiate1 ctorBody fresh;
                          let openedMinor :=
                            psKernelCoreExprInstantiate1 minorBody fresh;
                          match openRemaining
                              budget resources env family levels
                              openedCtor openedMinor
                              (Nat.succ binderDepth) (Nat.succ seed) with
                          | PsKernelCoreResult.error message =>
                              PsKernelCoreResult.error message
                          | PsKernelCoreResult.ok state =>
                              PsKernelCoreResult.ok {
                                ctorResult := state.ctorResult
                                minorResult := state.minorResult
                                fields :=
                                  PsKernelCoreList.cons
                                    { value := fresh, isRecursive := isRecursive }
                                    state.fields
                                nextSeed := state.nextSeed
                              }
                else
                  PsKernelCoreResult.error
                    "recursive recursor minor field domain does not match constructor"
            | _ =>
                PsKernelCoreResult.error
                  "recursive recursor minor has too few constructor fields"
        | _ =>
            PsKernelCoreResult.error
              "recursive recursor constructor has too few fields"

def psKernelCoreRecursiveRecursorConsumeDirectIhs
    (fields : PsKernelCoreList PsKernelCoreRecursiveRecursorField) :
    PsKernelCoreExpr ->
    PsKernelCoreExpr ->
    Nat ->
    PsKernelCoreOption PsKernelCoreExpr :=
  match fields with
  | PsKernelCoreList.nil =>
      fun (minorExpr : PsKernelCoreExpr)
          (_motive : PsKernelCoreExpr)
          (_seed : Nat) =>
        PsKernelCoreOption.some minorExpr
  | PsKernelCoreList.cons field rest =>
      let consumeRest := psKernelCoreRecursiveRecursorConsumeDirectIhs rest;
      fun (minorExpr : PsKernelCoreExpr)
          (motive : PsKernelCoreExpr)
          (seed : Nat) =>
        if field.isRecursive then
          match minorExpr with
          | PsKernelCoreExpr.forallE _ ihDomain ihBody _ =>
              let expectedDomain :=
                PsKernelCoreExpr.app motive field.value;
              if psKernelCoreExprEq ihDomain expectedDomain then
                let fresh := psKernelCoreRecursorFreshFVar seed;
                consumeRest
                  (psKernelCoreExprInstantiate1 ihBody fresh)
                  motive (Nat.succ seed)
              else
                PsKernelCoreOption.none
          | _ => PsKernelCoreOption.none
        else
          consumeRest minorExpr motive seed

def psKernelCoreRecursiveRecursorFieldValues
    (fields : PsKernelCoreList PsKernelCoreRecursiveRecursorField) :
    PsKernelCoreList PsKernelCoreExpr :=
  match fields with
  | PsKernelCoreList.nil => PsKernelCoreList.nil
  | PsKernelCoreList.cons field rest =>
      PsKernelCoreList.cons
        field.value
        (psKernelCoreRecursiveRecursorFieldValues rest)

def psKernelCoreRecursiveRecursorDirectMinorMatchesWithResources
    (budget : Nat)
    (resources : PsKernelCoreResourceConfig)
    (env : PsKernelCoreEnvironment)
    (info : PsKernelCoreRecursorInfo)
    (family : PsKernelCoreInductiveInfo)
    (ctor : PsKernelCoreConstructorInfo)
    (ruleIndex : Nat) : PsKernelCoreResult String Bool :=
  if Nat.beq family.numParams 0 then
    if Nat.beq family.numIndices 0 then
      let prefixCount := Nat.add info.numMotives ruleIndex;
      match psKernelCoreRecursorOpenForalls prefixCount info.base.type 0 with
      | PsKernelCoreOption.none => PsKernelCoreResult.ok false
      | PsKernelCoreOption.some openedPrefix =>
          match psKernelCoreExprListGet openedPrefix.values 0 with
          | PsKernelCoreOption.none => PsKernelCoreResult.ok false
          | PsKernelCoreOption.some motive =>
              match openedPrefix.rest with
              | PsKernelCoreExpr.forallE _ minorType _ _ =>
                  let levels :=
                    psKernelCoreInductiveLevelsFromNames family.base.levelParams;
                  match psKernelCoreRecursiveRecursorOpenDirectFields
                      ctor.numFields budget resources env family levels
                      ctor.base.type minorType 0 openedPrefix.nextSeed with
                  | PsKernelCoreResult.error message =>
                      PsKernelCoreResult.error message
                  | PsKernelCoreResult.ok opened =>
                      match psKernelCoreRecursiveRecursorConsumeDirectIhs
                          opened.fields opened.minorResult motive opened.nextSeed with
                      | PsKernelCoreOption.none => PsKernelCoreResult.ok false
                      | PsKernelCoreOption.some finalMinor =>
                          let resultHead :=
                            psKernelCoreExprAppHead opened.ctorResult;
                          let resultArgs :=
                            psKernelCoreExprAppArgs opened.ctorResult;
                          match resultHead with
                          | PsKernelCoreExpr.const familyName resultLevels =>
                              if psKernelCoreNameEq familyName family.base.name then
                                match resultArgs with
                                | PsKernelCoreList.nil =>
                                    let ctorHead :=
                                      PsKernelCoreExpr.const
                                        ctor.base.name resultLevels;
                                    let major :=
                                      psKernelCoreRecursorApplyArgs
                                        (psKernelCoreRecursiveRecursorFieldValues
                                          opened.fields)
                                        ctorHead;
                                    let expected :=
                                      PsKernelCoreExpr.app motive major;
                                    PsKernelCoreResult.ok
                                      (psKernelCoreExprEq finalMinor expected)
                                | PsKernelCoreList.cons _ _ =>
                                    PsKernelCoreResult.ok false
                              else
                                PsKernelCoreResult.ok false
                          | _ => PsKernelCoreResult.ok false
              | _ => PsKernelCoreResult.ok false
    else
      PsKernelCoreResult.error
        "indexed recursive recursor is not supported in direct recursive recursor slice"
  else
    PsKernelCoreResult.error
      "parameterized recursive recursor is not supported in direct recursive recursor slice"

def psKernelCoreRecursiveRecursorFamilySummaryWithResources
    (ctorNames : PsKernelCoreList PsKernelCoreName) :
    Nat ->
    PsKernelCoreResourceConfig ->
    PsKernelCoreEnvironment ->
    PsKernelCoreInductiveInfo ->
    PsKernelCoreList PsKernelCoreLevel ->
    PsKernelCoreRecursiveConstructorSummary ->
    PsKernelCoreResult String PsKernelCoreRecursiveConstructorSummary :=
  match ctorNames with
  | PsKernelCoreList.nil =>
      fun (_budget : Nat)
          (_resources : PsKernelCoreResourceConfig)
          (_env : PsKernelCoreEnvironment)
          (_family : PsKernelCoreInductiveInfo)
          (_levels : PsKernelCoreList PsKernelCoreLevel)
          (summary : PsKernelCoreRecursiveConstructorSummary) =>
        PsKernelCoreResult.ok summary
  | PsKernelCoreList.cons ctorName rest =>
      let summarizeRest :=
        psKernelCoreRecursiveRecursorFamilySummaryWithResources rest;
      fun (budget : Nat)
          (resources : PsKernelCoreResourceConfig)
          (env : PsKernelCoreEnvironment)
          (family : PsKernelCoreInductiveInfo)
          (levels : PsKernelCoreList PsKernelCoreLevel)
          (summary : PsKernelCoreRecursiveConstructorSummary) =>
        match psKernelCoreEnvironmentFind? env ctorName with
        | PsKernelCoreOption.none =>
            PsKernelCoreResult.error
              "recursive recursor constructor is not declared"
        | PsKernelCoreOption.some constant =>
            match constant with
            | PsKernelCoreConstantInfo.ctorInfo ctor =>
                if psKernelCoreNameEq ctor.induct family.base.name then
                  match psKernelCoreAnalyzeRecursiveConstructorWithResources
                      budget resources env family levels ctor with
                  | PsKernelCoreResult.error message =>
                      PsKernelCoreResult.error message
                  | PsKernelCoreResult.ok current =>
                      summarizeRest budget resources env family levels
                        (psKernelCoreRecursiveSummaryMerge summary current)
                else
                  PsKernelCoreResult.error
                    "recursive recursor constructor belongs to another inductive"
            | _ =>
                PsKernelCoreResult.error
                  "recursive recursor constructor metadata is not a constructor"

def psKernelCoreRecursiveRecursorCheckRuleRhsWithResources
    (budget : Nat)
    (resources : PsKernelCoreResourceConfig)
    (env : PsKernelCoreEnvironment)
    (info : PsKernelCoreRecursorInfo)
    (rule : PsKernelCoreRecursorRule) : PsKernelCoreResult String Unit :=
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
              budget resources env psKernelCoreLocalContextEmpty safety rule.rhs with
          | PsKernelCoreResult.error message => PsKernelCoreResult.error message
          | PsKernelCoreResult.ok _ => PsKernelCoreResult.ok Unit.unit

def psKernelCoreRecursiveRecursorValidateRulesWithResources
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
            PsKernelCoreResult.error
              "recursive recursor rule count does not match constructors"
  | PsKernelCoreList.cons ctorName ctorRest =>
      let validateRest :=
        psKernelCoreRecursiveRecursorValidateRulesWithResources ctorRest;
      fun (rules : PsKernelCoreList PsKernelCoreRecursorRule)
          (index : Nat)
          (budget : Nat)
          (resources : PsKernelCoreResourceConfig)
          (env : PsKernelCoreEnvironment)
          (info : PsKernelCoreRecursorInfo)
          (family : PsKernelCoreInductiveInfo) =>
        match rules with
        | PsKernelCoreList.nil =>
            PsKernelCoreResult.error
              "recursive recursor rule count does not match constructors"
        | PsKernelCoreList.cons rule ruleRest =>
            if psKernelCoreNameEq rule.ctor ctorName then
              match psKernelCoreEnvironmentFind? env ctorName with
              | PsKernelCoreOption.none =>
                  PsKernelCoreResult.error
                    "recursive recursor constructor is not declared"
              | PsKernelCoreOption.some constant =>
                  match constant with
                  | PsKernelCoreConstantInfo.ctorInfo ctor =>
                      if psKernelCoreNameEq ctor.induct family.base.name then
                        if Nat.beq ctor.cidx index then
                          if Nat.beq rule.nFields ctor.numFields then
                            if psKernelCoreBoolEq ctor.isUnsafe family.isUnsafe then
                              match psKernelCoreRecursiveRecursorDirectMinorMatchesWithResources
                                  budget resources env info family ctor index with
                              | PsKernelCoreResult.error message =>
                                  PsKernelCoreResult.error message
                              | PsKernelCoreResult.ok matches =>
                                  if matches then
                                    match psKernelCoreRecursiveRecursorCheckRuleRhsWithResources
                                        budget resources env info rule with
                                    | PsKernelCoreResult.error message =>
                                        PsKernelCoreResult.error message
                                    | PsKernelCoreResult.ok _ =>
                                        validateRest ruleRest (Nat.succ index)
                                          budget resources env info family
                                  else
                                    PsKernelCoreResult.error
                                      "recursive recursor minor does not match constructor"
                            else
                              PsKernelCoreResult.error
                                "recursive recursor constructor safety mismatch"
                          else
                            PsKernelCoreResult.error
                              "recursive recursor rule field count mismatch"
                        else
                          PsKernelCoreResult.error
                            "recursive recursor constructor index mismatch"
                      else
                        PsKernelCoreResult.error
                          "recursive recursor constructor belongs to another inductive"
                  | _ =>
                      PsKernelCoreResult.error
                        "recursive recursor constructor metadata is not a constructor"
            else
              PsKernelCoreResult.error
                "recursive recursor rule order does not match constructors"

def psKernelCoreValidateDirectRecursiveRecursorWithResources
    (budget : Nat)
    (resources : PsKernelCoreResourceConfig)
    (env : PsKernelCoreEnvironment)
    (info : PsKernelCoreRecursorInfo)
    (family : PsKernelCoreInductiveInfo) : PsKernelCoreResult String Unit :=
  let levels :=
    psKernelCoreInductiveLevelsFromNames family.base.levelParams;
  match psKernelCoreRecursiveRecursorFamilySummaryWithResources
      family.ctors budget resources env family levels
      psKernelCoreRecursiveSummaryEmpty with
  | PsKernelCoreResult.error message => PsKernelCoreResult.error message
  | PsKernelCoreResult.ok summary =>
      if psKernelCoreBoolEq summary.isRec family.isRec then
        if psKernelCoreBoolEq summary.isReflexive family.isReflexive then
          if summary.isRec then
            let provisionalEnv :=
              psKernelCoreEnvironmentAddUnchecked
                env (PsKernelCoreConstantInfo.recInfo info);
            psKernelCoreRecursiveRecursorValidateRulesWithResources
              family.ctors info.rules 0 budget resources
              provisionalEnv info family
          else
            PsKernelCoreResult.error
              "recursive recursor target has no recursive constructor fields"
        else
          PsKernelCoreResult.error
            "recursive recursor reflexive metadata mismatch"
      else
        PsKernelCoreResult.error
          "recursive recursor recursion metadata mismatch"
