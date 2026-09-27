import Ps.KernelCore.Check

def psKernelCoreAdmissionLevelsHaveMVar
    (levels : PsKernelCoreList PsKernelCoreLevel) : Bool :=
  match levels with
  | PsKernelCoreList.nil => false
  | PsKernelCoreList.cons level rest =>
      if psKernelCoreLevelHasMVar level then
        true
      else
        psKernelCoreAdmissionLevelsHaveMVar rest

def psKernelCoreAdmissionExprHasMVar
    (expr : PsKernelCoreExpr) : Bool :=
  match expr with
  | PsKernelCoreExpr.bvar _ => false
  | PsKernelCoreExpr.fvar _ => false
  | PsKernelCoreExpr.mvar _ => true
  | PsKernelCoreExpr.sort level => psKernelCoreLevelHasMVar level
  | PsKernelCoreExpr.const _ levels =>
      psKernelCoreAdmissionLevelsHaveMVar levels
  | PsKernelCoreExpr.app fn arg =>
      if psKernelCoreAdmissionExprHasMVar fn then
        true
      else
        psKernelCoreAdmissionExprHasMVar arg
  | PsKernelCoreExpr.lam _ type body _ =>
      if psKernelCoreAdmissionExprHasMVar type then
        true
      else
        psKernelCoreAdmissionExprHasMVar body
  | PsKernelCoreExpr.forallE _ type body _ =>
      if psKernelCoreAdmissionExprHasMVar type then
        true
      else
        psKernelCoreAdmissionExprHasMVar body
  | PsKernelCoreExpr.letE _ type value body _ =>
      if psKernelCoreAdmissionExprHasMVar type then
        true
      else if psKernelCoreAdmissionExprHasMVar value then
        true
      else
        psKernelCoreAdmissionExprHasMVar body
  | PsKernelCoreExpr.lit _ => false
  | PsKernelCoreExpr.mdata _ body =>
      psKernelCoreAdmissionExprHasMVar body
  | PsKernelCoreExpr.proj _ _ body =>
      psKernelCoreAdmissionExprHasMVar body

def psKernelCoreAdmissionExprHasFVar
    (expr : PsKernelCoreExpr) : Bool :=
  match expr with
  | PsKernelCoreExpr.bvar _ => false
  | PsKernelCoreExpr.fvar _ => true
  | PsKernelCoreExpr.mvar _ => false
  | PsKernelCoreExpr.sort _ => false
  | PsKernelCoreExpr.const _ _ => false
  | PsKernelCoreExpr.app fn arg =>
      if psKernelCoreAdmissionExprHasFVar fn then
        true
      else
        psKernelCoreAdmissionExprHasFVar arg
  | PsKernelCoreExpr.lam _ type body _ =>
      if psKernelCoreAdmissionExprHasFVar type then
        true
      else
        psKernelCoreAdmissionExprHasFVar body
  | PsKernelCoreExpr.forallE _ type body _ =>
      if psKernelCoreAdmissionExprHasFVar type then
        true
      else
        psKernelCoreAdmissionExprHasFVar body
  | PsKernelCoreExpr.letE _ type value body _ =>
      if psKernelCoreAdmissionExprHasFVar type then
        true
      else if psKernelCoreAdmissionExprHasFVar value then
        true
      else
        psKernelCoreAdmissionExprHasFVar body
  | PsKernelCoreExpr.lit _ => false
  | PsKernelCoreExpr.mdata _ body =>
      psKernelCoreAdmissionExprHasFVar body
  | PsKernelCoreExpr.proj _ _ body =>
      psKernelCoreAdmissionExprHasFVar body

def psKernelCoreAdmissionFindUndefinedLevelParam
    (level : PsKernelCoreLevel) :
    PsKernelCoreList PsKernelCoreName ->
    PsKernelCoreOption PsKernelCoreName :=
  match level with
  | PsKernelCoreLevel.zero =>
      fun (_allowed : PsKernelCoreList PsKernelCoreName) =>
        PsKernelCoreOption.none
  | PsKernelCoreLevel.mvar _ =>
      fun (_allowed : PsKernelCoreList PsKernelCoreName) =>
        PsKernelCoreOption.none
  | PsKernelCoreLevel.param name =>
      fun (allowed : PsKernelCoreList PsKernelCoreName) =>
        if psKernelCoreNameMember name allowed then
          PsKernelCoreOption.none
        else
          PsKernelCoreOption.some name
  | PsKernelCoreLevel.succ child =>
      let childFind :
          PsKernelCoreList PsKernelCoreName ->
          PsKernelCoreOption PsKernelCoreName :=
        psKernelCoreAdmissionFindUndefinedLevelParam child;
      fun (allowed : PsKernelCoreList PsKernelCoreName) =>
        childFind allowed
  | PsKernelCoreLevel.max left right =>
      let leftFind :
          PsKernelCoreList PsKernelCoreName ->
          PsKernelCoreOption PsKernelCoreName :=
        psKernelCoreAdmissionFindUndefinedLevelParam left;
      let rightFind :
          PsKernelCoreList PsKernelCoreName ->
          PsKernelCoreOption PsKernelCoreName :=
        psKernelCoreAdmissionFindUndefinedLevelParam right;
      fun (allowed : PsKernelCoreList PsKernelCoreName) =>
        match leftFind allowed with
        | PsKernelCoreOption.some name => PsKernelCoreOption.some name
        | PsKernelCoreOption.none => rightFind allowed
  | PsKernelCoreLevel.imax left right =>
      let leftFind :
          PsKernelCoreList PsKernelCoreName ->
          PsKernelCoreOption PsKernelCoreName :=
        psKernelCoreAdmissionFindUndefinedLevelParam left;
      let rightFind :
          PsKernelCoreList PsKernelCoreName ->
          PsKernelCoreOption PsKernelCoreName :=
        psKernelCoreAdmissionFindUndefinedLevelParam right;
      fun (allowed : PsKernelCoreList PsKernelCoreName) =>
        match leftFind allowed with
        | PsKernelCoreOption.some name => PsKernelCoreOption.some name
        | PsKernelCoreOption.none => rightFind allowed

def psKernelCoreAdmissionFindUndefinedLevels
    (levels : PsKernelCoreList PsKernelCoreLevel) :
    PsKernelCoreList PsKernelCoreName ->
    PsKernelCoreOption PsKernelCoreName :=
  match levels with
  | PsKernelCoreList.nil =>
      fun (_allowed : PsKernelCoreList PsKernelCoreName) =>
        PsKernelCoreOption.none
  | PsKernelCoreList.cons level rest =>
      let restFind :
          PsKernelCoreList PsKernelCoreName ->
          PsKernelCoreOption PsKernelCoreName :=
        psKernelCoreAdmissionFindUndefinedLevels rest;
      fun (allowed : PsKernelCoreList PsKernelCoreName) =>
        match psKernelCoreAdmissionFindUndefinedLevelParam level allowed with
        | PsKernelCoreOption.some name => PsKernelCoreOption.some name
        | PsKernelCoreOption.none => restFind allowed

def psKernelCoreAdmissionFindUndefinedExprLevelParam
    (expr : PsKernelCoreExpr) :
    PsKernelCoreList PsKernelCoreName ->
    PsKernelCoreOption PsKernelCoreName :=
  match expr with
  | PsKernelCoreExpr.bvar _ =>
      fun (_allowed : PsKernelCoreList PsKernelCoreName) =>
        PsKernelCoreOption.none
  | PsKernelCoreExpr.fvar _ =>
      fun (_allowed : PsKernelCoreList PsKernelCoreName) =>
        PsKernelCoreOption.none
  | PsKernelCoreExpr.mvar _ =>
      fun (_allowed : PsKernelCoreList PsKernelCoreName) =>
        PsKernelCoreOption.none
  | PsKernelCoreExpr.lit _ =>
      fun (_allowed : PsKernelCoreList PsKernelCoreName) =>
        PsKernelCoreOption.none
  | PsKernelCoreExpr.sort level =>
      psKernelCoreAdmissionFindUndefinedLevelParam level
  | PsKernelCoreExpr.const _ levels =>
      psKernelCoreAdmissionFindUndefinedLevels levels
  | PsKernelCoreExpr.app fn arg =>
      let fnFind :
          PsKernelCoreList PsKernelCoreName ->
          PsKernelCoreOption PsKernelCoreName :=
        psKernelCoreAdmissionFindUndefinedExprLevelParam fn;
      let argFind :
          PsKernelCoreList PsKernelCoreName ->
          PsKernelCoreOption PsKernelCoreName :=
        psKernelCoreAdmissionFindUndefinedExprLevelParam arg;
      fun (allowed : PsKernelCoreList PsKernelCoreName) =>
        match fnFind allowed with
        | PsKernelCoreOption.some name => PsKernelCoreOption.some name
        | PsKernelCoreOption.none => argFind allowed
  | PsKernelCoreExpr.lam _ type body _ =>
      let typeFind :
          PsKernelCoreList PsKernelCoreName ->
          PsKernelCoreOption PsKernelCoreName :=
        psKernelCoreAdmissionFindUndefinedExprLevelParam type;
      let bodyFind :
          PsKernelCoreList PsKernelCoreName ->
          PsKernelCoreOption PsKernelCoreName :=
        psKernelCoreAdmissionFindUndefinedExprLevelParam body;
      fun (allowed : PsKernelCoreList PsKernelCoreName) =>
        match typeFind allowed with
        | PsKernelCoreOption.some name => PsKernelCoreOption.some name
        | PsKernelCoreOption.none => bodyFind allowed
  | PsKernelCoreExpr.forallE _ type body _ =>
      let typeFind :
          PsKernelCoreList PsKernelCoreName ->
          PsKernelCoreOption PsKernelCoreName :=
        psKernelCoreAdmissionFindUndefinedExprLevelParam type;
      let bodyFind :
          PsKernelCoreList PsKernelCoreName ->
          PsKernelCoreOption PsKernelCoreName :=
        psKernelCoreAdmissionFindUndefinedExprLevelParam body;
      fun (allowed : PsKernelCoreList PsKernelCoreName) =>
        match typeFind allowed with
        | PsKernelCoreOption.some name => PsKernelCoreOption.some name
        | PsKernelCoreOption.none => bodyFind allowed
  | PsKernelCoreExpr.letE _ type value body _ =>
      let typeFind :
          PsKernelCoreList PsKernelCoreName ->
          PsKernelCoreOption PsKernelCoreName :=
        psKernelCoreAdmissionFindUndefinedExprLevelParam type;
      let valueFind :
          PsKernelCoreList PsKernelCoreName ->
          PsKernelCoreOption PsKernelCoreName :=
        psKernelCoreAdmissionFindUndefinedExprLevelParam value;
      let bodyFind :
          PsKernelCoreList PsKernelCoreName ->
          PsKernelCoreOption PsKernelCoreName :=
        psKernelCoreAdmissionFindUndefinedExprLevelParam body;
      fun (allowed : PsKernelCoreList PsKernelCoreName) =>
        match typeFind allowed with
        | PsKernelCoreOption.some name => PsKernelCoreOption.some name
        | PsKernelCoreOption.none =>
            match valueFind allowed with
            | PsKernelCoreOption.some name => PsKernelCoreOption.some name
            | PsKernelCoreOption.none => bodyFind allowed
  | PsKernelCoreExpr.mdata _ body =>
      psKernelCoreAdmissionFindUndefinedExprLevelParam body
  | PsKernelCoreExpr.proj _ _ body =>
      psKernelCoreAdmissionFindUndefinedExprLevelParam body

def psKernelCoreAdmissionCheckClosed
    (expr : PsKernelCoreExpr) : PsKernelCoreResult String Unit :=
  if psKernelCoreAdmissionExprHasMVar expr then
    PsKernelCoreResult.error "declaration has metavariables"
  else if psKernelCoreAdmissionExprHasFVar expr then
    PsKernelCoreResult.error "declaration has free variables"
  else
    PsKernelCoreResult.ok Unit.unit

def psKernelCoreAdmissionCheckLevelParams
    (expr : PsKernelCoreExpr)
    (allowed : PsKernelCoreList PsKernelCoreName) :
    PsKernelCoreResult String Unit :=
  match psKernelCoreAdmissionFindUndefinedExprLevelParam expr allowed with
  | PsKernelCoreOption.some _ =>
      PsKernelCoreResult.error
        "invalid reference to undefined universe level parameter"
  | PsKernelCoreOption.none =>
      PsKernelCoreResult.ok Unit.unit

def psKernelCoreAdmissionCheckBase
    (budget : Nat)
    (env : PsKernelCoreEnvironment)
    (base : PsKernelCoreConstantBase)
    (safety : PsKernelCoreDefinitionSafety) :
    PsKernelCoreResult String Unit :=
  if psKernelCoreEnvironmentContains env base.name then
    PsKernelCoreResult.error "already declared"
  else if psKernelCoreNameHasDuplicates base.levelParams then
    PsKernelCoreResult.error "duplicate universe parameter"
  else
    match psKernelCoreAdmissionCheckClosed base.type with
    | PsKernelCoreResult.error message => PsKernelCoreResult.error message
    | PsKernelCoreResult.ok _ =>
        match psKernelCoreAdmissionCheckLevelParams base.type base.levelParams with
        | PsKernelCoreResult.error message => PsKernelCoreResult.error message
        | PsKernelCoreResult.ok _ =>
            match psKernelCoreCheck
                budget env psKernelCoreLocalContextEmpty safety base.type with
            | PsKernelCoreResult.error message =>
                PsKernelCoreResult.error message
            | PsKernelCoreResult.ok typeType =>
                match psKernelCoreEnsureSort
                    budget env psKernelCoreLocalContextEmpty typeType with
                | PsKernelCoreResult.error message =>
                    PsKernelCoreResult.error message
                | PsKernelCoreResult.ok _ =>
                    PsKernelCoreResult.ok Unit.unit

def psKernelCoreAdmissionCheckDefinitionBody
    (budget : Nat)
    (env : PsKernelCoreEnvironment)
    (value : PsKernelCoreDefinitionInfo)
    (safety : PsKernelCoreDefinitionSafety) :
    PsKernelCoreResult String Unit :=
  match psKernelCoreAdmissionCheckClosed value.value with
  | PsKernelCoreResult.error message => PsKernelCoreResult.error message
  | PsKernelCoreResult.ok _ =>
      match psKernelCoreAdmissionCheckLevelParams
          value.value value.base.levelParams with
      | PsKernelCoreResult.error message => PsKernelCoreResult.error message
      | PsKernelCoreResult.ok _ =>
          match psKernelCoreCheck
              budget env psKernelCoreLocalContextEmpty safety value.value with
          | PsKernelCoreResult.error message =>
              PsKernelCoreResult.error message
          | PsKernelCoreResult.ok valueType =>
              match psKernelCoreIsDefEq
                  budget env psKernelCoreLocalContextEmpty
                  valueType value.base.type with
              | PsKernelCoreResult.error message =>
                  PsKernelCoreResult.error message
              | PsKernelCoreResult.ok equal =>
                  if equal then
                    PsKernelCoreResult.ok Unit.unit
                  else
                    PsKernelCoreResult.error "definition type mismatch"

def psKernelCoreAdmissionIsProp
    (budget : Nat)
    (env : PsKernelCoreEnvironment)
    (expr : PsKernelCoreExpr) :
    PsKernelCoreResult String Bool :=
  match psKernelCoreCheck
      budget env psKernelCoreLocalContextEmpty
      PsKernelCoreDefinitionSafety.safe expr with
  | PsKernelCoreResult.error message =>
      PsKernelCoreResult.error message
  | PsKernelCoreResult.ok inferredType =>
      match psKernelCoreWhnf
          budget env psKernelCoreLocalContextEmpty inferredType with
      | PsKernelCoreResult.error message =>
          PsKernelCoreResult.error message
      | PsKernelCoreResult.ok reduced =>
          match reduced with
          | PsKernelCoreExpr.sort level =>
              PsKernelCoreResult.ok
                (psKernelCoreLevelNormalizesToZero level)
          | _ => PsKernelCoreResult.error "expected sort"

def psKernelCoreAddAxiom
    (budget : Nat) :
    PsKernelCoreEnvironment ->
    PsKernelCoreAxiomInfo ->
    PsKernelCoreResult String PsKernelCoreEnvironment :=
  match budget with
  | Nat.zero =>
      fun (_env : PsKernelCoreEnvironment)
          (_value : PsKernelCoreAxiomInfo) =>
        PsKernelCoreResult.error "admission budget exhausted"
  | Nat.succ remaining =>
      fun (env : PsKernelCoreEnvironment)
          (value : PsKernelCoreAxiomInfo) =>
        let safety :=
          if value.isUnsafe then
            PsKernelCoreDefinitionSafety.unsafeDef
          else
            PsKernelCoreDefinitionSafety.safe;
        match psKernelCoreAdmissionCheckBase
            remaining env value.base safety with
        | PsKernelCoreResult.error message =>
            PsKernelCoreResult.error message
        | PsKernelCoreResult.ok _ =>
            PsKernelCoreResult.ok
              (psKernelCoreEnvironmentAddUnchecked
                env (PsKernelCoreConstantInfo.axiomInfo value))

def psKernelCoreAddDefinition
    (budget : Nat) :
    PsKernelCoreEnvironment ->
    PsKernelCoreDefinitionInfo ->
    PsKernelCoreResult String PsKernelCoreEnvironment :=
  match budget with
  | Nat.zero =>
      fun (_env : PsKernelCoreEnvironment)
          (_value : PsKernelCoreDefinitionInfo) =>
        PsKernelCoreResult.error "admission budget exhausted"
  | Nat.succ remaining =>
      fun (env : PsKernelCoreEnvironment)
          (value : PsKernelCoreDefinitionInfo) =>
        match value.safety with
        | PsKernelCoreDefinitionSafety.unsafeDef =>
            match psKernelCoreAdmissionCheckBase
                remaining env value.base
                PsKernelCoreDefinitionSafety.unsafeDef with
            | PsKernelCoreResult.error message =>
                PsKernelCoreResult.error message
            | PsKernelCoreResult.ok _ =>
                let work :=
                  psKernelCoreEnvironmentAddUnchecked
                    env (PsKernelCoreConstantInfo.defnInfo value);
                match psKernelCoreAdmissionCheckDefinitionBody
                    remaining work value
                    PsKernelCoreDefinitionSafety.unsafeDef with
                | PsKernelCoreResult.error message =>
                    PsKernelCoreResult.error message
                | PsKernelCoreResult.ok _ =>
                    PsKernelCoreResult.ok work
        | PsKernelCoreDefinitionSafety.safe =>
            match psKernelCoreAdmissionCheckBase
                remaining env value.base
                PsKernelCoreDefinitionSafety.safe with
            | PsKernelCoreResult.error message =>
                PsKernelCoreResult.error message
            | PsKernelCoreResult.ok _ =>
                match psKernelCoreAdmissionCheckDefinitionBody
                    remaining env value
                    PsKernelCoreDefinitionSafety.safe with
                | PsKernelCoreResult.error message =>
                    PsKernelCoreResult.error message
                | PsKernelCoreResult.ok _ =>
                    PsKernelCoreResult.ok
                      (psKernelCoreEnvironmentAddUnchecked
                        env (PsKernelCoreConstantInfo.defnInfo value))
        | PsKernelCoreDefinitionSafety.partialDef =>
            match psKernelCoreAdmissionCheckBase
                remaining env value.base
                PsKernelCoreDefinitionSafety.safe with
            | PsKernelCoreResult.error message =>
                PsKernelCoreResult.error message
            | PsKernelCoreResult.ok _ =>
                match psKernelCoreAdmissionCheckDefinitionBody
                    remaining env value
                    PsKernelCoreDefinitionSafety.safe with
                | PsKernelCoreResult.error message =>
                    PsKernelCoreResult.error message
                | PsKernelCoreResult.ok _ =>
                    PsKernelCoreResult.ok
                      (psKernelCoreEnvironmentAddUnchecked
                        env (PsKernelCoreConstantInfo.defnInfo value))

def psKernelCoreAddTheorem
    (budget : Nat) :
    PsKernelCoreEnvironment ->
    PsKernelCoreTheoremInfo ->
    PsKernelCoreResult String PsKernelCoreEnvironment :=
  match budget with
  | Nat.zero =>
      fun (_env : PsKernelCoreEnvironment)
          (_value : PsKernelCoreTheoremInfo) =>
        PsKernelCoreResult.error "admission budget exhausted"
  | Nat.succ remaining =>
      fun (env : PsKernelCoreEnvironment)
          (value : PsKernelCoreTheoremInfo) =>
        match psKernelCoreAdmissionCheckBase
            remaining env value.base PsKernelCoreDefinitionSafety.safe with
        | PsKernelCoreResult.error message =>
            PsKernelCoreResult.error message
        | PsKernelCoreResult.ok _ =>
            match psKernelCoreAdmissionIsProp
                remaining env value.base.type with
            | PsKernelCoreResult.error message =>
                PsKernelCoreResult.error message
            | PsKernelCoreResult.ok isProp =>
                if isProp then
                  match psKernelCoreAdmissionCheckClosed value.value with
                  | PsKernelCoreResult.error message =>
                      PsKernelCoreResult.error message
                  | PsKernelCoreResult.ok _ =>
                      match psKernelCoreAdmissionCheckLevelParams
                          value.value value.base.levelParams with
                      | PsKernelCoreResult.error message =>
                          PsKernelCoreResult.error message
                      | PsKernelCoreResult.ok _ =>
                          match psKernelCoreCheck
                              remaining env psKernelCoreLocalContextEmpty
                              PsKernelCoreDefinitionSafety.safe value.value with
                          | PsKernelCoreResult.error message =>
                              PsKernelCoreResult.error message
                          | PsKernelCoreResult.ok proofType =>
                              match psKernelCoreIsDefEq
                                  remaining env psKernelCoreLocalContextEmpty
                                  proofType value.base.type with
                              | PsKernelCoreResult.error message =>
                                  PsKernelCoreResult.error message
                              | PsKernelCoreResult.ok equal =>
                                  if equal then
                                    PsKernelCoreResult.ok
                                      (psKernelCoreEnvironmentAddUnchecked
                                        env
                                        (PsKernelCoreConstantInfo.thmInfo value))
                                  else
                                    PsKernelCoreResult.error
                                      "theorem proof type mismatch"
                else
                  PsKernelCoreResult.error
                    "theorem type is not a proposition"

def psKernelCoreAddOpaque
    (budget : Nat) :
    PsKernelCoreEnvironment ->
    PsKernelCoreOpaqueInfo ->
    PsKernelCoreResult String PsKernelCoreEnvironment :=
  match budget with
  | Nat.zero =>
      fun (_env : PsKernelCoreEnvironment)
          (_value : PsKernelCoreOpaqueInfo) =>
        PsKernelCoreResult.error "admission budget exhausted"
  | Nat.succ remaining =>
      fun (env : PsKernelCoreEnvironment)
          (value : PsKernelCoreOpaqueInfo) =>
        match psKernelCoreAdmissionCheckBase
            remaining env value.base PsKernelCoreDefinitionSafety.safe with
        | PsKernelCoreResult.error message =>
            PsKernelCoreResult.error message
        | PsKernelCoreResult.ok _ =>
            match psKernelCoreAdmissionCheckClosed value.value with
            | PsKernelCoreResult.error message =>
                PsKernelCoreResult.error message
            | PsKernelCoreResult.ok _ =>
                match psKernelCoreAdmissionCheckLevelParams
                    value.value value.base.levelParams with
                | PsKernelCoreResult.error message =>
                    PsKernelCoreResult.error message
                | PsKernelCoreResult.ok _ =>
                    match psKernelCoreCheck
                        remaining env psKernelCoreLocalContextEmpty
                        PsKernelCoreDefinitionSafety.safe value.value with
                    | PsKernelCoreResult.error message =>
                        PsKernelCoreResult.error message
                    | PsKernelCoreResult.ok valueType =>
                        match psKernelCoreIsDefEq
                            remaining env psKernelCoreLocalContextEmpty
                            valueType value.base.type with
                        | PsKernelCoreResult.error message =>
                            PsKernelCoreResult.error message
                        | PsKernelCoreResult.ok equal =>
                            if equal then
                              PsKernelCoreResult.ok
                                (psKernelCoreEnvironmentAddUnchecked
                                  env
                                  (PsKernelCoreConstantInfo.opaqueInfo value))
                            else
                              PsKernelCoreResult.error
                                "opaque value type mismatch"
