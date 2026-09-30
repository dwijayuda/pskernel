import Ps.KernelCore.RecursiveRecursor

structure PsKernelCoreIndexedRecursiveRecursorField where
  value : PsKernelCoreExpr
  indices : PsKernelCoreList PsKernelCoreExpr
  isRecursive : Bool

structure PsKernelCoreIndexedRecursiveRecursorFieldClassification where
  indices : PsKernelCoreList PsKernelCoreExpr
  isRecursive : Bool

def psKernelCoreIndexedRecursiveRecursorClassifyField
    (numIndices : Nat)
    (shape : PsKernelCoreOption PsKernelCoreRecursiveFieldShape) :
    PsKernelCoreResult String PsKernelCoreIndexedRecursiveRecursorFieldClassification :=
  match shape with
  | PsKernelCoreOption.none =>
      let classification : PsKernelCoreIndexedRecursiveRecursorFieldClassification := {
        indices := PsKernelCoreList.nil
        isRecursive := false
      };
      PsKernelCoreResult.ok classification
  | PsKernelCoreOption.some recursive =>
      match recursive.argCount with
      | Nat.zero =>
          if Nat.beq (psKernelCoreExprListLength recursive.indices) numIndices then
            let classification : PsKernelCoreIndexedRecursiveRecursorFieldClassification := {
              indices := recursive.indices
              isRecursive := true
            };
            PsKernelCoreResult.ok classification
          else
            PsKernelCoreResult.error
              "indexed recursive field has wrong index arity"
      | Nat.succ _ =>
          PsKernelCoreResult.error
            "functional indexed recursive field is not supported in this phase"

def psKernelCoreIndexedRecursiveRecursorMotiveApp
    (motive : PsKernelCoreExpr)
    (indices : PsKernelCoreList PsKernelCoreExpr)
    (major : PsKernelCoreExpr) : PsKernelCoreExpr :=
  let motiveAtIndices := psKernelCoreRecursorApplyArgs indices motive;
  PsKernelCoreExpr.app motiveAtIndices major

structure PsKernelCoreIndexedRecursiveRecursorOpenState where
  ctorResult : PsKernelCoreExpr
  minorResult : PsKernelCoreExpr
  fields : PsKernelCoreList PsKernelCoreIndexedRecursiveRecursorField
  nextSeed : Nat

def psKernelCoreIndexedRecursiveRecursorOpenFields
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
    PsKernelCoreResult String PsKernelCoreIndexedRecursiveRecursorOpenState :=
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
        let state : PsKernelCoreIndexedRecursiveRecursorOpenState := {
          ctorResult := ctorExpr
          minorResult := minorExpr
          fields := PsKernelCoreList.nil
          nextSeed := seed
        };
        PsKernelCoreResult.ok state
  | Nat.succ remaining =>
      let openRemaining :=
        psKernelCoreIndexedRecursiveRecursorOpenFields remaining;
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
                      match psKernelCoreIndexedRecursiveRecursorClassifyField
                          family.numIndices recursiveShape with
                      | PsKernelCoreResult.error message =>
                          PsKernelCoreResult.error message
                      | PsKernelCoreResult.ok classification =>
                          let fresh := psKernelCoreRecursorFreshFVar seed;
                          let openedCtor :=
                            psKernelCoreExprInstantiate1 ctorBody fresh;
                          let openedMinor :=
                            psKernelCoreExprInstantiate1 minorBody fresh;
                          match openRemaining budget resources env family levels
                              openedCtor openedMinor
                              (Nat.succ binderDepth) (Nat.succ seed) with
                          | PsKernelCoreResult.error message =>
                              PsKernelCoreResult.error message
                          | PsKernelCoreResult.ok state =>
                              let field : PsKernelCoreIndexedRecursiveRecursorField := {
                                value := fresh
                                indices := classification.indices
                                isRecursive := classification.isRecursive
                              };
                              let nextState : PsKernelCoreIndexedRecursiveRecursorOpenState := {
                                ctorResult := state.ctorResult
                                minorResult := state.minorResult
                                fields := PsKernelCoreList.cons field state.fields
                                nextSeed := state.nextSeed
                              };
                              PsKernelCoreResult.ok nextState
                else
                  PsKernelCoreResult.error
                    "indexed recursive recursor minor field domain does not match constructor"
            | _ =>
                PsKernelCoreResult.error
                  "indexed recursive recursor minor has too few constructor fields"
        | _ =>
            PsKernelCoreResult.error
              "indexed recursive recursor constructor has too few fields"

def psKernelCoreIndexedRecursiveRecursorConsumeIhs
    (fields : PsKernelCoreList PsKernelCoreIndexedRecursiveRecursorField) :
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
      let consumeRest := psKernelCoreIndexedRecursiveRecursorConsumeIhs rest;
      fun (minorExpr : PsKernelCoreExpr)
          (motive : PsKernelCoreExpr)
          (seed : Nat) =>
        if field.isRecursive then
          match minorExpr with
          | PsKernelCoreExpr.forallE _ ihDomain ihBody _ =>
              let expectedDomain :=
                psKernelCoreIndexedRecursiveRecursorMotiveApp
                  motive field.indices field.value;
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

def psKernelCoreIndexedRecursiveRecursorFieldValues
    (fields : PsKernelCoreList PsKernelCoreIndexedRecursiveRecursorField) :
    PsKernelCoreList PsKernelCoreExpr :=
  match fields with
  | PsKernelCoreList.nil => PsKernelCoreList.nil
  | PsKernelCoreList.cons field rest =>
      PsKernelCoreList.cons
        field.value
        (psKernelCoreIndexedRecursiveRecursorFieldValues rest)

def psKernelCoreIndexedRecursiveRecursorMinorMatchesWithResources
    (budget : Nat)
    (resources : PsKernelCoreResourceConfig)
    (env : PsKernelCoreEnvironment)
    (info : PsKernelCoreRecursorInfo)
    (family : PsKernelCoreInductiveInfo)
    (ctor : PsKernelCoreConstructorInfo)
    (ruleIndex : Nat) : PsKernelCoreResult String Bool :=
  if Nat.beq family.numParams 0 then
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
                match psKernelCoreIndexedRecursiveRecursorOpenFields
                    ctor.numFields budget resources env family levels
                    ctor.base.type minorType 0 openedPrefix.nextSeed with
                | PsKernelCoreResult.error message =>
                    PsKernelCoreResult.error message
                | PsKernelCoreResult.ok opened =>
                    match psKernelCoreIndexedRecursiveRecursorConsumeIhs
                        opened.fields opened.minorResult motive opened.nextSeed with
                    | PsKernelCoreOption.none => PsKernelCoreResult.ok false
                    | PsKernelCoreOption.some finalMinor =>
                        let resultHead := psKernelCoreExprAppHead opened.ctorResult;
                        let resultArgs := psKernelCoreExprAppArgs opened.ctorResult;
                        match resultHead with
                        | PsKernelCoreExpr.const familyName resultLevels =>
                            if psKernelCoreNameEq familyName family.base.name then
                              if Nat.beq
                                  (psKernelCoreExprListLength resultArgs)
                                  family.numIndices then
                                let ctorHead :=
                                  PsKernelCoreExpr.const ctor.base.name resultLevels;
                                let major :=
                                  psKernelCoreRecursorApplyArgs
                                    (psKernelCoreIndexedRecursiveRecursorFieldValues
                                      opened.fields)
                                    ctorHead;
                                let expected :=
                                  psKernelCoreIndexedRecursiveRecursorMotiveApp
                                    motive resultArgs major;
                                PsKernelCoreResult.ok
                                  (psKernelCoreExprEq finalMinor expected)
                              else
                                PsKernelCoreResult.ok false
                            else
                              PsKernelCoreResult.ok false
                        | _ => PsKernelCoreResult.ok false
            | _ => PsKernelCoreResult.ok false
  else
    PsKernelCoreResult.error
      "parameterized indexed recursive recursor is not supported in this phase"

structure PsKernelCoreIndexedRecursiveRecursorRuleOpenState where
  ctorResult : PsKernelCoreExpr
  ruleBody : PsKernelCoreExpr
  fields : PsKernelCoreList PsKernelCoreIndexedRecursiveRecursorField
  nextSeed : Nat

def psKernelCoreIndexedRecursiveRecursorOpenRuleFields
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
    PsKernelCoreResult String PsKernelCoreIndexedRecursiveRecursorRuleOpenState :=
  match count with
  | Nat.zero =>
      fun (_budget : Nat)
          (_resources : PsKernelCoreResourceConfig)
          (_env : PsKernelCoreEnvironment)
          (_family : PsKernelCoreInductiveInfo)
          (_levels : PsKernelCoreList PsKernelCoreLevel)
          (ctorExpr : PsKernelCoreExpr)
          (ruleExpr : PsKernelCoreExpr)
          (_binderDepth : Nat)
          (seed : Nat) =>
        let state : PsKernelCoreIndexedRecursiveRecursorRuleOpenState := {
          ctorResult := ctorExpr
          ruleBody := ruleExpr
          fields := PsKernelCoreList.nil
          nextSeed := seed
        };
        PsKernelCoreResult.ok state
  | Nat.succ remaining =>
      let openRemaining :=
        psKernelCoreIndexedRecursiveRecursorOpenRuleFields remaining;
      fun (budget : Nat)
          (resources : PsKernelCoreResourceConfig)
          (env : PsKernelCoreEnvironment)
          (family : PsKernelCoreInductiveInfo)
          (levels : PsKernelCoreList PsKernelCoreLevel)
          (ctorExpr : PsKernelCoreExpr)
          (ruleExpr : PsKernelCoreExpr)
          (binderDepth : Nat)
          (seed : Nat) =>
        match ctorExpr with
        | PsKernelCoreExpr.forallE _ ctorDomain ctorBody _ =>
            match ruleExpr with
            | PsKernelCoreExpr.lam _ ruleDomain ruleBody _ =>
                if psKernelCoreExprEq ctorDomain ruleDomain then
                  match psKernelCoreRecursiveFieldShapeWithResources
                      budget resources env family.base.name levels
                      family.numParams family.numIndices binderDepth ctorDomain with
                  | PsKernelCoreResult.error message =>
                      PsKernelCoreResult.error message
                  | PsKernelCoreResult.ok recursiveShape =>
                      match psKernelCoreIndexedRecursiveRecursorClassifyField
                          family.numIndices recursiveShape with
                      | PsKernelCoreResult.error message =>
                          PsKernelCoreResult.error message
                      | PsKernelCoreResult.ok classification =>
                          let fresh := psKernelCoreRecursorFreshFVar seed;
                          let openedCtor :=
                            psKernelCoreExprInstantiate1 ctorBody fresh;
                          let openedRule :=
                            psKernelCoreExprInstantiate1 ruleBody fresh;
                          match openRemaining budget resources env family levels
                              openedCtor openedRule
                              (Nat.succ binderDepth) (Nat.succ seed) with
                          | PsKernelCoreResult.error message =>
                              PsKernelCoreResult.error message
                          | PsKernelCoreResult.ok state =>
                              let field : PsKernelCoreIndexedRecursiveRecursorField := {
                                value := fresh
                                indices := classification.indices
                                isRecursive := classification.isRecursive
                              };
                              let nextState : PsKernelCoreIndexedRecursiveRecursorRuleOpenState := {
                                ctorResult := state.ctorResult
                                ruleBody := state.ruleBody
                                fields := PsKernelCoreList.cons field state.fields
                                nextSeed := state.nextSeed
                              };
                              PsKernelCoreResult.ok nextState
                else
                  PsKernelCoreResult.error
                    "indexed recursive recursor rule field domain does not match constructor"
            | _ =>
                PsKernelCoreResult.error
                  "indexed recursive recursor rule has too few constructor field lambdas"
        | _ =>
            PsKernelCoreResult.error
              "indexed recursive recursor constructor has too few rule fields"

def psKernelCoreIndexedRecursiveRecursorCalls
    (fields : PsKernelCoreList PsKernelCoreIndexedRecursiveRecursorField) :
    PsKernelCoreExpr ->
    PsKernelCoreOption (PsKernelCoreList PsKernelCoreExpr) :=
  match fields with
  | PsKernelCoreList.nil =>
      fun (_recPrefix : PsKernelCoreExpr) =>
        PsKernelCoreOption.some PsKernelCoreList.nil
  | PsKernelCoreList.cons field rest =>
      let buildRest := psKernelCoreIndexedRecursiveRecursorCalls rest;
      fun (recPrefix : PsKernelCoreExpr) =>
        match buildRest recPrefix with
        | PsKernelCoreOption.none => PsKernelCoreOption.none
        | PsKernelCoreOption.some restCalls =>
            if field.isRecursive then
              let recAtIndices :=
                psKernelCoreRecursorApplyArgs field.indices recPrefix;
              let call := PsKernelCoreExpr.app recAtIndices field.value;
              PsKernelCoreOption.some
                (PsKernelCoreList.cons call restCalls)
            else
              PsKernelCoreOption.some restCalls

def psKernelCoreIndexedRecursiveRecursorRuleStructureMatchesWithResources
    (budget : Nat)
    (resources : PsKernelCoreResourceConfig)
    (env : PsKernelCoreEnvironment)
    (info : PsKernelCoreRecursorInfo)
    (family : PsKernelCoreInductiveInfo)
    (ctor : PsKernelCoreConstructorInfo)
    (ruleIndex : Nat)
    (rule : PsKernelCoreRecursorRule) : PsKernelCoreResult String Bool :=
  if Nat.beq family.numParams 0 then
    let fixedCount := Nat.add info.numMotives info.numMinors;
    match psKernelCoreRecursiveRecursorOpenLambdas fixedCount rule.rhs 0 with
    | PsKernelCoreOption.none => PsKernelCoreResult.ok false
    | PsKernelCoreOption.some openedPrefix =>
        match psKernelCoreExprListGet
            openedPrefix.values (Nat.add info.numMotives ruleIndex) with
        | PsKernelCoreOption.none => PsKernelCoreResult.ok false
        | PsKernelCoreOption.some selectedMinor =>
            let familyLevels :=
              psKernelCoreInductiveLevelsFromNames family.base.levelParams;
            match psKernelCoreIndexedRecursiveRecursorOpenRuleFields
                ctor.numFields budget resources env family familyLevels
                ctor.base.type openedPrefix.rest 0 openedPrefix.nextSeed with
            | PsKernelCoreResult.error message =>
                PsKernelCoreResult.error message
            | PsKernelCoreResult.ok opened =>
                let recLevels :=
                  psKernelCoreInductiveLevelsFromNames info.base.levelParams;
                let recHead := PsKernelCoreExpr.const info.base.name recLevels;
                let recPrefix :=
                  psKernelCoreRecursorApplyArgs openedPrefix.values recHead;
                let fieldValues :=
                  psKernelCoreIndexedRecursiveRecursorFieldValues opened.fields;
                match psKernelCoreIndexedRecursiveRecursorCalls
                    opened.fields recPrefix with
                | PsKernelCoreOption.none => PsKernelCoreResult.ok false
                | PsKernelCoreOption.some recursiveCalls =>
                    let branchArgs :=
                      psKernelCoreExprListAppend fieldValues recursiveCalls;
                    let expectedBody :=
                      psKernelCoreRecursorApplyArgs branchArgs selectedMinor;
                    PsKernelCoreResult.ok
                      (psKernelCoreExprEq opened.ruleBody expectedBody)
  else
    PsKernelCoreResult.error
      "parameterized indexed recursive rule validation is not supported in this phase"

def psKernelCoreIndexedRecursiveRecursorValidateRulesWithResources
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
              "indexed recursive recursor rule count does not match constructors"
  | PsKernelCoreList.cons ctorName ctorRest =>
      let validateRest :=
        psKernelCoreIndexedRecursiveRecursorValidateRulesWithResources ctorRest;
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
              "indexed recursive recursor rule count does not match constructors"
        | PsKernelCoreList.cons rule ruleRest =>
            if psKernelCoreNameEq rule.ctor ctorName then
              match psKernelCoreEnvironmentFind? env ctorName with
              | PsKernelCoreOption.none =>
                  PsKernelCoreResult.error
                    "indexed recursive recursor constructor is not declared"
              | PsKernelCoreOption.some constant =>
                  match constant with
                  | PsKernelCoreConstantInfo.ctorInfo ctor =>
                      if psKernelCoreNameEq ctor.induct family.base.name then
                        if Nat.beq ctor.cidx index then
                          if Nat.beq ctor.numParams family.numParams then
                            if Nat.beq rule.nFields ctor.numFields then
                              if psKernelCoreBoolEq ctor.isUnsafe family.isUnsafe then
                                match psKernelCoreIndexedRecursiveRecursorMinorMatchesWithResources
                                    budget resources env info family ctor index with
                                | PsKernelCoreResult.error message =>
                                    PsKernelCoreResult.error message
                                | PsKernelCoreResult.ok minorMatches =>
                                    if minorMatches then
                                      match psKernelCoreIndexedRecursiveRecursorRuleStructureMatchesWithResources
                                          budget resources env info family ctor index rule with
                                      | PsKernelCoreResult.error message =>
                                          PsKernelCoreResult.error message
                                      | PsKernelCoreResult.ok structureMatches =>
                                          if structureMatches then
                                            match psKernelCoreRecursiveRecursorCheckRuleRhsWithResources
                                                budget resources env info rule with
                                            | PsKernelCoreResult.error message =>
                                                PsKernelCoreResult.error message
                                            | PsKernelCoreResult.ok _ =>
                                                validateRest ruleRest (Nat.succ index)
                                                  budget resources env info family
                                          else
                                            PsKernelCoreResult.error
                                              "indexed recursive recursor rule body is not canonical"
                                    else
                                      PsKernelCoreResult.error
                                        "indexed recursive recursor minor does not match constructor"
                              else
                                PsKernelCoreResult.error
                                  "indexed recursive recursor constructor safety mismatch"
                            else
                              PsKernelCoreResult.error
                                "indexed recursive recursor rule field count mismatch"
                          else
                            PsKernelCoreResult.error
                              "indexed recursive recursor constructor parameter count mismatch"
                        else
                          PsKernelCoreResult.error
                            "indexed recursive recursor constructor index mismatch"
                      else
                        PsKernelCoreResult.error
                          "indexed recursive recursor constructor belongs to another inductive"
                  | _ =>
                      PsKernelCoreResult.error
                        "indexed recursive recursor constructor metadata is not a constructor"
            else
              PsKernelCoreResult.error
                "indexed recursive recursor rule order does not match constructors"

def psKernelCoreValidateIndexedRecursiveRecursorWithResources
    (budget : Nat)
    (resources : PsKernelCoreResourceConfig)
    (env : PsKernelCoreEnvironment)
    (info : PsKernelCoreRecursorInfo)
    (family : PsKernelCoreInductiveInfo) : PsKernelCoreResult String Unit :=
  if Nat.beq family.numParams 0 then
    match family.numIndices with
    | Nat.zero =>
        PsKernelCoreResult.error
          "indexed recursive recursor requires at least one index"
    | Nat.succ _ =>
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
                  psKernelCoreIndexedRecursiveRecursorValidateRulesWithResources
                    family.ctors info.rules 0 budget resources
                    provisionalEnv info family
                else
                  PsKernelCoreResult.error
                    "indexed recursive recursor target has no recursive constructor fields"
              else
                PsKernelCoreResult.error
                  "indexed recursive recursor reflexive metadata mismatch"
            else
              PsKernelCoreResult.error
                "indexed recursive recursor recursion metadata mismatch"
  else
    PsKernelCoreResult.error
      "parameterized indexed recursive recursor is not supported in this phase"
